#!/usr/bin/env python3
"""
Parity gate for REST implementations (Fase 3.3 do plano de acao).

Enforces contracts/rest/canonical-payloads.md: every implementation must
return the same payload for the same scenario. Before this gate, /json
returned a different object in every language -- 154 B/item with a CSPRNG in
Go, 106 B/item without one in Node -- which made the /json ranking compare
different workloads over different amounts of wire.

Usage:
    # print the reference payload and its hash
    python scripts/validate-parity.py --reference --n 2

    # validate a running implementation
    python scripts/validate-parity.py --url http://192.168.1.51:30081

    # validate many at once
    python scripts/validate-parity.py --url http://host:30081 --url http://host:30082

Exit code is non-zero if any check fails, so it can gate `make smoke`.
Stdlib only: runs anywhere Python 3.8+ runs, no pip install.
"""

import argparse
import hashlib
import json
import sys
import urllib.error
import urllib.request

TIMEOUT = 15
CREATED_AT = "2026-01-01T00:00:00Z"
JSON_SIZES = (10, 100, 1000)

# Fields whose value legitimately varies between runs (clock, database, Redis)
# and must not take part in the parity hash.
VOLATILE = {"timestamp", "version"}


# ---------------------------------------------------------------------------
# Canonical payload (the reference every implementation is compared against)
# ---------------------------------------------------------------------------

def canonical_item(i: int) -> dict:
    """Item content is a pure function of its index. No randomness, no clock."""
    return {
        "id": i,
        "uuid": "00000000-0000-0000-0000-%012d" % i,
        "name": "Item %d" % i,
        "email": "item%d@benchmark.local" % i,
        "createdAt": CREATED_AT,
        "isActive": i % 2 == 0,
    }


def canonical_items(n: int) -> list:
    return [canonical_item(i) for i in range(n)]


def normalize(obj) -> str:
    """
    Canonical JSON: recursively sorted keys, compact separators.

    Comparing normalized JSON rather than raw bytes is deliberate. Requiring
    byte-identical serialization across 11 languages would fail on key order
    and float formatting, which are not the divergences this gate is for.
    """
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def digest(obj) -> str:
    return hashlib.sha256(normalize(obj).encode("utf-8")).hexdigest()


def strip_volatile(obj):
    if isinstance(obj, dict):
        return {k: strip_volatile(v) for k, v in obj.items() if k not in VOLATILE}
    if isinstance(obj, list):
        return [strip_volatile(v) for v in obj]
    return obj


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

class Result:
    def __init__(self):
        self.failures = []
        self.checks = 0

    def check(self, ok: bool, label: str, detail: str = "") -> bool:
        self.checks += 1
        if ok:
            print(f"    [ok]   {label}")
        else:
            print(f"    [FAIL] {label}")
            if detail:
                for line in detail.splitlines():
                    print(f"           {line}")
            self.failures.append(label)
        return ok


def fetch(url: str):
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        raw = resp.read()
        return resp.status, raw


def check_json_scenario(base: str, res: Result) -> None:
    for n in JSON_SIZES:
        url = f"{base}/json?n={n}"
        label = f"/json?n={n} payload matches canonical"
        try:
            status, raw = fetch(url)
        except (urllib.error.URLError, urllib.error.HTTPError, OSError) as exc:
            res.check(False, label, f"request failed: {exc}")
            continue

        if status != 200:
            res.check(False, label, f"HTTP {status}")
            continue

        try:
            body = json.loads(raw)
        except json.JSONDecodeError as exc:
            res.check(False, label, f"invalid JSON: {exc}")
            continue

        if not isinstance(body, dict) or "items" not in body:
            res.check(False, label, "envelope must be an object with an 'items' array")
            continue

        items = body["items"]
        if len(items) != n:
            res.check(False, label, f"expected {n} items, got {len(items)}")
            continue

        actual = digest(items)
        expected = digest(canonical_items(n))
        if actual == expected:
            res.check(True, label)
            continue

        # Point at the first divergent item so the fix is obvious.
        detail = [f"sha256 expected {expected}", f"sha256 actual   {actual}"]
        ref = canonical_items(n)
        for i, (got, want) in enumerate(zip(items, ref)):
            if normalize(got) != normalize(want):
                detail.append(f"first divergence at item[{i}]:")
                detail.append(f"  expected {normalize(want)}")
                detail.append(f"  actual   {normalize(got)}")
                break
        res.check(False, label, "\n".join(detail))

        # Byte size drives the network ceiling; report it once.
        per_item = len(raw) / max(len(items), 1)
        print(f"           observed {per_item:.0f} B/item "
              f"(canonical is ~160 B/item)")


EXPECTED_KEYS = {
    "/health": {"status", "version", "timestamp", "database", "cache"},
    "/db/simple": {"id", "email", "firstName", "lastName", "age", "createdAt"},
    "/db/complex?days=30": {"periodDays", "totalUsers", "data"},
    "/cache?key=benchmark": {"key", "value", "cached", "ttl", "timestamp"},
}


def check_key_sets(base: str, res: Result) -> None:
    for path, expected in EXPECTED_KEYS.items():
        # For /db/simple, probe a few IDs: the seed's SERIAL may not start at 1
        # if the table was seeded more than once.
        paths_to_try = [path]
        if path == "/db/simple":
            paths_to_try = [f"/db/simple?id={i}" for i in (1, 2, 3, 5, 10)]
        label = f"{path} key set matches contract"
        last_detail = ""
        for actual_path in paths_to_try:
            try:
                status, raw = fetch(f"{base}{actual_path}")
            except (urllib.error.URLError, urllib.error.HTTPError, OSError) as exc:
                last_detail = f"request failed: {exc}"
                continue
            if status != 200:
                last_detail = f"HTTP {status} for {actual_path}"
                continue
            try:
                body = json.loads(raw)
            except json.JSONDecodeError as exc:
                last_detail = f"invalid JSON: {exc}"
                continue
            if not isinstance(body, dict):
                last_detail = "expected a JSON object"
                continue

            actual_keys = set(body.keys())
            if actual_keys == expected:
                res.check(True, label)
                break
            else:
                detail = []
                missing = expected - actual_keys
                extra = actual_keys - expected
                if missing:
                    detail.append(f"missing: {sorted(missing)}")
                if extra:
                    detail.append(f"unexpected: {sorted(extra)}")
                last_detail = "\n".join(detail)
        else:
            res.check(False, label, last_detail)


def validate(base: str) -> Result:
    base = base.rstrip("/")
    print(f"\n=== {base} ===")
    res = Result()
    check_json_scenario(base, res)
    check_key_sets(base, res)
    return res


# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", action="append", default=[],
                    help="base URL of a running implementation (repeatable)")
    ap.add_argument("--reference", action="store_true",
                    help="print the canonical payload instead of validating")
    ap.add_argument("--n", type=int, default=2,
                    help="item count for --reference (default: 2)")
    args = ap.parse_args()

    if args.reference:
        items = canonical_items(args.n)
        envelope = {"items": items, "count": args.n,
                    "timestamp": "<RFC3339 at request time>"}
        print(json.dumps(envelope, separators=(",", ":")))
        print(f"\nitems sha256 : {digest(items)}")
        print(f"bytes/item   : {len(normalize(items)) / max(args.n, 1):.0f}")
        return 0

    if not args.url:
        ap.error("provide at least one --url, or use --reference")

    total_failures = 0
    for url in args.url:
        res = validate(url)
        total_failures += len(res.failures)

    print()
    if total_failures:
        print(f"PARITY FAILED: {total_failures} check(s) failed")
        print("See contracts/rest/canonical-payloads.md for the normative payload.")
        return 1
    print("PARITY OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
