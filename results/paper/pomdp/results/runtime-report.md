# Runtime overview

Sources: `experiments/logs`.

**Cumulative runtime: 5h 54m 46s** (21,285.64 seconds; 5.913 hours).

Recorded 665 of 665 expected runs across 19 instances; 0 runs missing.

Runtime is the sum of recorded per-run wall-clock times, including failures and timeout overruns. It is not the elapsed duration of a parallel batch. Derived best-configuration results are excluded to avoid double-counting.

Successful runs: 3h 11m 28s; unsuccessful runs: 2h 43m 17s (46.0% of total runtime).

## Outcomes

| Outcome | Runs | Runtime | Share |
| --- | ---: | ---: | ---: |
| successful | 623 | 3h 11m 28s | 54.0% |
| timeout | 3 | 0h 45m 05s | 12.7% |
| killed | 39 | 1h 58m 12s | 33.3% |
| memout | 0 | 0h 00m 00s | 0.0% |
| failed | 0 | 0h 00m 00s | 0.0% |

`killed` means return code -9 (SIGKILL) without a recorded timeout. These logs do not establish the cause; a kill alone is not proof of a memory-out. `memout` denotes a memory error identified by the parser.

## Configuration families

| Group | Runs | Success | Timeout | Killed | Memory-out | Other failed | Missing | Runtime | Share |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `cutoff` | 608 | 566 | 3 | 39 | 0 | 0 | 0 | 5h 48m 20s | 98.2% |
| `discretisation` | 38 | 38 | 0 | 0 | 0 | 0 | 0 | 0h 06m 22s | 1.8% |
| `MDP` | 19 | 19 | 0 | 0 | 0 | 0 | 0 | 0h 00m 03s | 0.0% |

## Instances

| Group | Runs | Success | Timeout | Killed | Memory-out | Other failed | Missing | Runtime | Share |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `network-priorities3_rewmax_T8-K20` | 35 | 32 | 3 | 0 | 0 | 0 | 0 | 1h 20m 54s | 22.8% |
| `drone_prbmax_N6-R3` | 35 | 32 | 0 | 3 | 0 | 0 | 0 | 0h 28m 37s | 8.1% |
| `lanes-100_rewmin` | 35 | 31 | 0 | 4 | 0 | 0 | 0 | 0h 27m 28s | 7.7% |
| `drone_prbmax_N4-R1` | 35 | 32 | 0 | 3 | 0 | 0 | 0 | 0h 20m 51s | 5.9% |
| `drone_prbmax_N5-R3` | 35 | 32 | 0 | 3 | 0 | 0 | 0 | 0h 19m 36s | 5.5% |
| `drone_prbmax_N4-R2` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 17m 16s | 4.9% |
| `maze2_rewmin_sl0.1` | 35 | 32 | 0 | 3 | 0 | 0 | 0 | 0h 16m 14s | 4.6% |
| `network3_rewmin_T8-K20` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 15m 20s | 4.3% |
| `samplerocks_rewmin_N12` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 14m 15s | 4.0% |
| `grid_rewmin_sl0.3` | 35 | 32 | 0 | 3 | 0 | 0 | 0 | 0h 14m 10s | 4.0% |
| `refuel_prbmax_N08` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 14m 08s | 4.0% |
| `grid_rewmin_sl0.1` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 14m 05s | 4.0% |
| `samplerocks_rewmin_N16` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 13m 29s | 3.8% |
| `maze2_rewmin_sl0.3` | 35 | 32 | 0 | 3 | 0 | 0 | 0 | 0h 13m 21s | 3.8% |
| `grid-avoid_prbmax_sl0.1` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 13m 10s | 3.7% |
| `grid-large-30-5_rewmin` | 35 | 33 | 0 | 2 | 0 | 0 | 0 | 0h 12m 19s | 3.5% |
| `refuel_prbmax_N06` | 35 | 34 | 0 | 1 | 0 | 0 | 0 | 0h 12m 19s | 3.5% |
| `network-priorities2_rewmax_T8-K20` | 35 | 35 | 0 | 0 | 0 | 0 | 0 | 0h 06m 14s | 1.8% |
| `network2_rewmin_T8-K20` | 35 | 35 | 0 | 0 | 0 | 0 | 0 | 0h 01m 01s | 0.3% |

Exact runtimes and counts are exported as tab-separated `runtime-by-family.csv`, `runtime-by-instance.csv`, `runtime-by-configuration.csv`, and `runtime-runs.csv`.
