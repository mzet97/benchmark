# Archive

These documents are preserved for forensic traceability. They are **INVALID — DO NOT CITE**.

## Why they are here

The results in these files were produced by `run_all_benchmarks.py`, which:
- ran a single 5-second sample (not the methodology's 5×60s)
- had the load generator inside the same single-node cluster as the SUT
- measured non-comparable payloads (45% byte difference on `/json`)
- used unequal worker counts and three conflicting resource profiles

The full forensic record of what went wrong is in `docs/ACTION_PLAN.md`, Anexo A.
The remediation plan is in `docs/EXECUTION_PLAN_REMAINING.md`.

These files will not be regenerated. New results will be in `docs/RESULTS_<date>.md`
once Fase 6.13 completes.
