#!/usr/bin/env python3
"""Flag implementations whose response size diverges from the rest of the field.

Why this exists
---------------
The payload of every scenario is fixed by contract (contracts/rest/
canonical-payloads.md), so for a given scenario `bytes_per_sec / requests_per_sec`
has to be the same number for all 100 implementations. When it is not, the
implementation is not answering the question that was asked -- and because it
usually answers it with a well-formed 200, neither the load generator's non_2xx
counter nor a key-set parity check notices.

This is how rust-rest-actix-web came to lead /db/complex at 32,777 rps across
five consecutive runs: a driver-level bind failure was mapped to an empty Vec
behind a 200, so it emitted 220 bytes per response where every other
implementation emitted ~11,000. The ratio exposed it without reading a line of
code, which is the point -- it works the same way for the other ten
environments. See docs/ACTION_PLAN.md, invariante 9 and Fase 9.6.

A divergence is not automatically a defect. Legitimate causes exist: a
Content-Length vs chunked framing difference, a header set that is genuinely
larger, gzip. Those move the ratio by a few percent. Missing rows move it by an
order of magnitude. The threshold separates the two, and every hit is meant to
be explained, not silently accepted.

Usage
-----
    python scripts/audit-response-bytes.py                    # newest run
    python scripts/audit-response-bytes.py results/run-*.json # explicit
    python scripts/audit-response-bytes.py --tolerance 0.10   # looser
    python scripts/audit-response-bytes.py --quiet             # only divergences

Exit status is 1 if any divergence was found, so it can gate a pipeline.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import statistics
import sys

DEFAULT_TOLERANCE = 0.05


def bytes_per_response(samples: list[dict]) -> float | None:
    """Mean bytes per response across a scenario's repetitions.

    Averaged per repetition rather than over the pooled totals so one long
    repetition cannot dominate.
    """
    ratios = []
    for s in samples:
        rps = s.get("requests_per_sec")
        bps = s.get("bytes_per_sec")
        if rps and bps and rps > 0:
            ratios.append(bps / rps)
    return statistics.mean(ratios) if ratios else None


def mean_rps(samples: list[dict]) -> float | None:
    values = [s["requests_per_sec"] for s in samples
              if s.get("requests_per_sec")]
    return statistics.mean(values) if values else None


def collect(run: dict) -> dict[str, dict[str, tuple[float, float]]]:
    """{scenario: {impl: (bytes_per_response, mean_rps)}}"""
    by_scenario: dict[str, dict[str, tuple[float, float]]] = {}
    for impl, body in (run.get("implementations") or {}).items():
        for scenario, sc in (body.get("scenarios") or {}).items():
            samples = sc.get("samples") or []
            bpr = bytes_per_response(samples)
            rps = mean_rps(samples)
            if bpr is None or rps is None:
                continue
            by_scenario.setdefault(scenario, {})[impl] = (bpr, rps)
    return by_scenario


def audit(path: str, tolerance: float, quiet: bool) -> int:
    with open(path, encoding="utf-8") as fh:
        run = json.load(fh)

    print(f"=== {os.path.basename(path)} ===")
    params = run.get("parameters") or {}
    if params:
        print(f"    {params.get('repetitions')} rep x {params.get('duration_s')}s, "
              f"{params.get('connections')} conns, "
              f"generator={params.get('generator')} @ "
              f"{params.get('generator_location')}")

    by_scenario = collect(run)
    if not by_scenario:
        print("    no scenario carried both bytes_per_sec and requests_per_sec")
        return 0

    divergences = 0

    for scenario in sorted(by_scenario):
        impls = by_scenario[scenario]
        if len(impls) < 3:
            # A median over one or two implementations is not a reference.
            print(f"\n  {scenario}: only {len(impls)} implementation(s), skipped")
            continue

        median = statistics.median(bpr for bpr, _ in impls.values())
        offenders = []
        for impl, (bpr, rps) in impls.items():
            deviation = (bpr - median) / median
            if abs(deviation) > tolerance:
                offenders.append((abs(deviation), deviation, impl, bpr, rps))

        header = (f"\n  {scenario}: median {median:,.0f} B/response "
                  f"across {len(impls)} implementations")
        if not offenders:
            if not quiet:
                print(header + "  -- all within tolerance")
            continue

        print(header)
        divergences += len(offenders)
        for _, deviation, impl, bpr, rps in sorted(offenders, reverse=True):
            arrow = "under" if deviation < 0 else "over"
            print(f"      {impl:<34} {bpr:>10,.0f} B  "
                  f"{deviation:+7.1%} ({arrow})  at {rps:,.0f} rps")
            # An implementation that is both far below the median payload and
            # far above the median throughput is the signature of a silently
            # empty response, which is the case worth looking at first.
            if deviation < -0.5:
                median_rps = statistics.median(r for _, r in impls.values())
                if rps > median_rps * 2:
                    print(f"      {'':<34} ^ {rps / median_rps:.0f}x the median "
                          f"rps on a fraction of the payload: likely an error "
                          f"swallowed behind a 200 (invariante 8)")

    print()
    if divergences:
        print(f"{divergences} divergence(s) beyond +/-{tolerance:.0%}. "
              f"Each one needs a documented cause before the run is citable.")
    else:
        print(f"No response-size divergence beyond +/-{tolerance:.0%}.")
    return 1 if divergences else 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Flag implementations whose bytes/response diverges from the field.")
    ap.add_argument("runs", nargs="*",
                    help="result JSON files (default: the newest results/run-*.json)")
    ap.add_argument("--tolerance", type=float, default=DEFAULT_TOLERANCE,
                    help=f"relative deviation from the median that is acceptable "
                         f"(default: {DEFAULT_TOLERANCE:.0%})")
    ap.add_argument("--quiet", action="store_true",
                    help="print only scenarios that have a divergence")
    args = ap.parse_args()

    paths = args.runs
    if not paths:
        here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        candidates = sorted(glob.glob(os.path.join(here, "results", "run-*.json")))
        if not candidates:
            print("no results/run-*.json found", file=sys.stderr)
            return 2
        paths = [candidates[-1]]

    status = 0
    for path in paths:
        status |= audit(path, args.tolerance, args.quiet)
    return status


if __name__ == "__main__":
    sys.exit(main())
