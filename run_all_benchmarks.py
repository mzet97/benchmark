#!/usr/bin/env python3
"""Retired. Use scripts/run-benchmark-suite.py.

This script produced every number in BENCHMARK_RESULTS_K3S.md, and none of
them are defensible:

  * One 5-second measurement per implementation per scenario, with a 2-second
    warm-up. The documented methodology called for 5 repetitions of 60 s with
    a 30 s warm-up. A single sample has no error bar.
  * Alphabetical order, so thermal and temporal drift accumulated against
    whoever sorted last rather than being spread across the set.
  * The wrk Job ran inside the same single-node cluster as the subject, capped
    at 1 CPU, competing with it for the same 8 cores. It measured the
    generator as much as the server.
  * A hardcoded list of 23 implementations out of 37, with no record of which
    ones were left out or why.
  * No parity gate: implementations serving different payloads -- different
    item counts, different field sets, some with 1000 random UUIDs per request
    -- were ranked against each other.

The replacement runs the generator on the workstation against a NodePort,
follows docs/BENCHMARK_METHODOLOGY.md, records the randomization seed, and
refuses to measure an implementation that fails the payload contract.

    python scripts/run-benchmark-suite.py --host 192.168.1.51 --user k8s1

The original is in git history (before 2026-08-02) if it is ever needed to
reproduce how the invalid results were generated.
"""

import sys

sys.exit(__doc__)
