#!/usr/bin/env python3
"""
Purge hardcoded credentials from the repository (Fase 1 do plano de acao).

Replaces every hardcoded credential fallback with fail-fast behaviour: if the
environment variable is missing, the process must abort with a clear message
instead of silently connecting with a baked-in password.

Usage:
    python scripts/purge-credentials.py --dry-run
    python scripts/purge-credentials.py --apply

Idempotent: running it twice is a no-op.
"""

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# The literal credential being purged. Kept in one place so the file itself
# does not need to be edited when the value rotates.
SECRET = "Admin" + "@" + "123"

SKIP_DIRS = {".git", "node_modules", "target", "bin", "obj", "dist", ".venv"}

# Files that document the remediation itself must keep their explanatory text.
ALLOWLIST = {
    "docs/SECURITY_REMEDIATION.md",
    "scripts/purge-credentials.py",
    ".trufflehog-exclude.txt",
}


def rx(pattern: str, flags: int = 0) -> re.Pattern:
    return re.compile(pattern.replace("SECRET", re.escape(SECRET)), flags)


# ---------------------------------------------------------------------------
# Per-language rules: (compiled regex, replacement)
# ---------------------------------------------------------------------------

JS_RULES = [
    # process.env.X || "<creds>"   ->   fail-fast IIFE
    (rx(r"""(process\.env\.(\w+))\s*\|\|\s*(['"])[^'"]*SECRET[^'"]*\3"""),
     r"""\1 || (() => { throw new Error('\2 is required'); })()"""),
    # Deno.env.get("X") || "<creds>"
    (rx(r"""(Deno\.env\.get\((['"])(\w+)\2\))\s*\|\|\s*(['"])[^'"]*SECRET[^'"]*\4"""),
     r"""\1 || (() => { throw new Error('\3 is required'); })()"""),
]

PY_RULES = [
    # os.getenv("X", "<creds>")   ->   os.environ["X"]  (KeyError = fail-fast)
    # \s* after "(" so the multi-line form is matched too.
    (rx(r"""os\.getenv\(\s*(['"])(\w+)\1\s*,\s*(['"])[^'"]*SECRET[^'"]*\3\s*,?\s*\)"""),
     r"""os.environ["\2"]"""),
    (rx(r"""os\.environ\.get\(\s*(['"])(\w+)\1\s*,\s*(['"])[^'"]*SECRET[^'"]*\3\s*,?\s*\)"""),
     r"""os.environ["\2"]"""),
    # PASSWORD = "<creds>"  in the SSH helper scripts
    (rx(r"""^(\s*)(\w*PASSWORD\w*)\s*=\s*(['"])[^'"]*SECRET[^'"]*\3""", re.M),
     r"""\1\2 = os.environ["K3S_SSH_PASSWORD"]"""),
    # Rust source embedded in the one-off fix_*.py generators
    (rx(r"""env::var\((['"])(\w+)\1\)\s*\n?\s*\.unwrap_or_else\(\s*\|_\|\s*(['"])[^'"]*SECRET[^'"]*\3\s*\.to_string\(\)\s*\)"""),
     r"""env::var("\2").expect("\2 is required")"""),
    # docstring / comment mentions
    (rx(r"""password:\s*SECRET"""), """password: <from $K3S_SSH_PASSWORD>"""),
    # bare literal passed positionally or as a keyword argument
    (rx(r"""(['"])SECRET\1"""), r"""os.environ["K3S_SSH_PASSWORD"]"""),
]

RS_RULES = [
    # std::env::var("X").unwrap_or_else(|_| "<creds>".to_string())
    (rx(r"""(?:std::)?env::var\((['"])(\w+)\1\)\s*\.?\s*\n?\s*\.unwrap_or_else\(\s*\|_\|\s*(['"])[^'"]*SECRET[^'"]*\3\s*\.to_string\(\)\s*\)"""),
     r"""env::var("\2").expect("\2 is required")"""),
]

KT_RULES = [
    # System.getenv("X") ?: "<creds>"
    (rx(r"""(System\.getenv\((['"])(\w+)\2\))\s*\?:\s*(['"])[^'"]*SECRET[^'"]*\4"""),
     r"""\1 ?: error("\3 is required")"""),
]

DQ = '"'  # kept separate: a raw string cannot end in a lone backslash-quote

SH_RULES = [
    # export X=${X:-"<creds>"}   ->   ${X:?X is required}
    (rx(r"""\$\{(\w+):-\s*(['"])?[^'"\n]*SECRET[^'"\n]*\2?\s*\}"""),
     r"""${\1:?\1 is required}"""),
    # docker run -e X="<creds>"
    (rx(r"""(-e\s+)(\w+)=(['"])[^'"\n]*SECRET[^'"\n]*\3"""),
     r"""\1\2=""" + DQ + r"""${\2:?\2 is required}""" + DQ),
    # plain `export X="<creds>"` used as an in-script default
    (rx(r"""^(\s*)export\s+(\w+)=(['"])[^'"\n]*SECRET[^'"\n]*\3""", re.M),
     r"""\1: """ + DQ + r"""${\2:?\2 is required}""" + DQ),
]

PROPS_RULES = [
    # ${VAR:<default with creds>}  ->  ${VAR}   (no default)
    (rx(r"""\$\{(\w+):[^}\n]*SECRET[^}\n]*\}"""), r"""${\1}"""),
    # key=<creds>  ->  key=${DB_PASSWORD}
    (rx(r"""^([\w.%]*redis[\w.%]*password)\s*=\s*[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1=${REDIS_PASSWORD}"""),
    (rx(r"""^([\w.%]*password)\s*=\s*[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1=${DB_PASSWORD}"""),
    (rx(r"""^([\w.%]*url)\s*=\s*[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1=${DATABASE_URL}"""),
]

YAML_RULES = [
    # GitHub Actions: ${{ secrets.X || '<creds>' }}  ->  ${{ secrets.X }}
    (rx(r"""(\$\{\{\s*secrets\.\w+)\s*\|\|\s*(['"])[^'"]*SECRET[^'"]*\2(\s*\}\})"""),
     r"""\1\3"""),
    # Spring/Micronaut placeholder default: ${VAR:<creds>}  ->  ${VAR}
    (rx(r"""\$\{(\w+):[^}\n]*SECRET[^}\n]*\}"""), r"""${\1}"""),
    # docker-compose env list:  - DATABASE_URL=postgresql://app:<creds>@host
    (rx(r"""^(\s*-?\s*[\w.-]*[Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]_?[Uu][Rr][Ll]\s*[:=]\s*)[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1${DATABASE_URL}"""),
    (rx(r"""^(\s*-?\s*[\w.-]*[Rr][Ee][Dd][Ii][Ss]_?[Uu][Rr][Ll]\s*[:=]\s*)[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1${REDIS_URL}"""),
    # any remaining key whose name mentions password
    (rx(r"""^(\s*#?\s*-?\s*[\w.-]*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]\w*\s*[:=]\s*)[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1${DB_PASSWORD}"""),
    # connection strings embedded in arbitrary values
    (rx(r"""postgresql://(\w+):SECRET@"""), r"""postgresql://\1:${DB_PASSWORD}@"""),
    (rx(r"""redis://:SECRET@"""), r"""redis://:${REDIS_PASSWORD}@"""),
    (rx(r"""[Pp]assword=SECRET"""), """Password=${DB_PASSWORD}"""),
    (rx(r"""password=SECRET"""), """password=${REDIS_PASSWORD}"""),
    (rx(r"""SECRET"""), """${DB_PASSWORD}"""),
]

# appsettings.json: blank the value so the ASPNETCORE env override is mandatory
JSON_RULES = [
    (rx(r"""(:\s*)(['"])[^'"]*SECRET[^'"]*\2"""), r"\1" + DQ + DQ),
]

MAKE_RULES = [
    (rx(r"""^(\s*\w*DATABASE_URL\w*=)[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1"$(DATABASE_URL)" \\"""),
    (rx(r"""^(\s*\w*REDIS\w*=)[^\n]*SECRET[^\n]*$""", re.M),
     r"""\1"$(REDIS_URL)" \\"""),
]

# Documentation / templates: a placeholder is the correct content.
DOC_RULES = [
    (rx(r"""postgresql://(\w+):SECRET@"""), r"""postgresql://\1:${DB_PASSWORD}@"""),
    (rx(r"""redis://:SECRET@"""), r"""redis://:${REDIS_PASSWORD}@"""),
    (rx(r"""[Pp]assword=SECRET"""), """Password=${DB_PASSWORD}"""),
    (rx(r"""password=SECRET"""), """password=${REDIS_PASSWORD}"""),
    (rx(r"""SECRET"""), """<REDACTED>"""),
]

ENV_EXAMPLE_RULES = [
    (rx(r"""postgresql://(\w+):SECRET@"""), r"""postgresql://\1:CHANGE_ME@"""),
    (rx(r"""redis://:SECRET@"""), """redis://:CHANGE_ME@"""),
    (rx(r"""SECRET"""), """CHANGE_ME"""),
]

RULES_BY_SUFFIX = {
    ".js": JS_RULES,
    ".ts": JS_RULES,
    ".py": PY_RULES,
    ".rs": RS_RULES,
    ".kt": KT_RULES,
    ".sh": SH_RULES,
    ".properties": PROPS_RULES,
    ".md": DOC_RULES,
    ".example": ENV_EXAMPLE_RULES,
    ".yaml": YAML_RULES,
    ".yml": YAML_RULES,
    ".json": JSON_RULES,
}


def rules_for(path: Path):
    if path.name.endswith(".env.example") or path.suffix == ".example":
        return ENV_EXAMPLE_RULES
    if path.name == "Makefile":
        return MAKE_RULES
    return RULES_BY_SUFFIX.get(path.suffix)


def iter_files():
    for path in REPO.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        rel = path.relative_to(REPO).as_posix()
        if rel in ALLOWLIST:
            continue
        yield path, rel


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write changes to disk")
    ap.add_argument("--dry-run", action="store_true", help="report only (default)")
    args = ap.parse_args()
    apply = args.apply and not args.dry_run

    changed, residual = [], []

    for path, rel in iter_files():
        try:
            original = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, PermissionError):
            continue
        if SECRET not in original:
            continue

        rules = rules_for(path)
        text = original
        if rules:
            for pattern, replacement in rules:
                text = pattern.sub(replacement, text)

        # Rewritten Python now depends on `os`; make sure it is imported.
        if path.suffix == ".py" and "os.environ[" in text and text != original:
            if not re.search(r"^\s*import os\b", text, re.M):
                lines = text.split("\n")
                insert_at = 0
                for i, line in enumerate(lines[:40]):
                    if line.startswith(("import ", "from ")):
                        insert_at = i
                        break
                    if line.startswith(('"""', "'''")) or line.startswith("#"):
                        insert_at = i + 1
                lines.insert(insert_at, "import os")
                text = "\n".join(lines)

        if text != original:
            changed.append(rel)
            if apply:
                path.write_text(text, encoding="utf-8")
        if SECRET in text:
            residual.append(rel)

    mode = "APPLIED" if apply else "DRY-RUN"
    print(f"=== purge-credentials [{mode}] ===")
    print(f"rewritten : {len(changed)}")
    for rel in sorted(changed):
        print(f"  ~ {rel}")
    print(f"\nresidual (needs manual fix): {len(residual)}")
    for rel in sorted(residual):
        print(f"  ! {rel}")
    return 1 if (apply and residual) else 0


if __name__ == "__main__":
    sys.exit(main())
