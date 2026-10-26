# POMDPs

Benchmarks of `storm-pomdp` for the tool paper: **19 POMDP instances and 34
configurations (646 runs)**: 32 belief-exploration size limits (cut-offs) from
10,000 to 50,000,000 and static belief discretisation at resolutions 4 and 5.

| Path | Description |
| --- | --- |
| `benchmarks/` | The PRISM models and properties, plus `index.json` describing every instance |
| `scripts/configurations.json` | The configurations: the method `family` of each, and the `size-threshold` of the cut-offs |
| `scripts/postprocess.py` | The POMDP-specific post-processing, called by `common/postprocess.py` |
| `scripts/plots.py`, `scripts/html_results.py` | The figure data and the html table, written by the post-processing |
| `scripts/benchmarks.py`, `storm.py`, `tools.py` | The instances, configurations and the parsing of the output of Storm |

## Running the experiments

The steps are those of the other experiments, see the [README](../README.md) of
the experiments. The tool is expected as `bin/storm-pomdp`:

```bash
cd pomdp
mkdir -p bin
ln -s /path/to/storm/build/bin/storm-pomdp bin/storm-pomdp

python3 scripts/benchmarks.py    # checks the model and property files
python3 ../docker/common/generate_invocations.py --out inv.json --timelimit 900 \
    --logdir experiments/logs
python3 ../docker/common/run.py inv.json
python3 ../docker/common/postprocess.py experiments/logs experiments/results
```

As in the other experiments, the time limit is **900 seconds**; the worst-case
runtime of the suite is then 161 hours 30 minutes plus overhead, run one at a
time. `--configs` and `--benchmarks` of `generate_invocations.py` select a part,
e.g. `--configs discr004s,discr005s`. Partial experiments are supported;
unavailable runs and bound references appear as missing data. Record the Storm
revision and machine specifications with new results.

## Instances

The instances are listed in `benchmarks/index.json`, the configurations in
`scripts/configurations.json`. Every instance is checked with the same 32
cut-offs: 10,000 to 90,000, 100,000 to 900,000 and 1,000,000 to 9,000,000 in
steps of the first value, and 10,000,000 to 50,000,000 in steps of 10,000,000.

| Plot label | Benchmark ID | Objective |
| --- | --- | --- |
| Grid-4-0.1 | `grid_grid_rewmin_sl0.1` | Minimise expected reward |
| Grid-4-0.3 | `grid_grid_rewmin_sl0.3` | Minimise expected reward |
| Grid-av-4-0.1 | `grid-avoid_grid-avoid_prbmax_sl0.1` | Maximise reachability probability |
| Rocks-12 | `samplerocks_samplerocks_rewmin_N12` | Minimise expected reward |
| Rocks-16 | `samplerocks_samplerocks_rewmin_N16` | Minimise expected reward |
| Drone-4-1 | `drone_drone_prbmax_N4-R1` | Maximise reachability probability |
| Drone-4-2 | `drone_drone_prbmax_N4-R2` | Maximise reachability probability |
| Drone-5-3 | `drone_drone_prbmax_N5-R3` | Maximise reachability probability |
| Drone-6-3 | `drone_drone_prbmax_N6-R3` | Maximise reachability probability |
| Lanes+ | `lanes-100_lanes-100_rewmin_` | Minimise expected reward |
| Grid-large-30-5 | `grid-large-30-5_grid-large-30-5_rewmin_` | Minimise expected reward |
| Netw-2-8-20 | `network2_network2_rewmin_T8-K20` | Minimise expected reward |
| Netw-3-8-20 | `network3_network3_rewmin_T8-K20` | Minimise expected reward |
| Netw-p-2-8-20 | `network-priorities2_network-priorities2_rewmax_T8-K20` | Maximise expected reward |
| Netw-p-3-8-20 | `network-priorities3_network-priorities3_rewmax_T8-K20` | Maximise expected reward |
| Maze2-0.1 | `maze2_maze2_rewmin_sl0.1` | Minimise expected reward |
| Maze2-0.3 | `maze2_maze2_rewmin_sl0.3` | Minimise expected reward |
| Refuel-06 | `refuel_refuel_prbmax_N06` | Maximise reachability probability |
| Refuel-08 | `refuel_refuel_prbmax_N08` | Maximise reachability probability |

## Postprocessing

`common/postprocess.py` hands the logs to `scripts/postprocess.py`, which reads
them without modifying them and writes to the results directory:

- `html/index.html`: an offline results table with links to a page per run,
  with its invocation, metadata and log. Share the entire `html/` directory.
- `plots/`: the audit CSV `plot-data.csv`, the figure data `plot-series.csv`
  and `plot-curves.csv`, and the TeX commands of the figure in
  `aggregate-plots.tex` and `paper-figure.tex`. `docker/build_figures.sh` of the
  experiments puts the figure data into the figures of the paper.
- `execution-data.json` and `benchmark-data.json`: the parsed runs and
  instances, which `common/check_results.py` checks.

The figure has three panels, which cover all included instances together, with
the size limit on the x-axis and a point per run: the runtime, and the gaps to
the best successful under- and over-approximation of every instance,
100 · |bound − best| / max(|bound|, |best|). The over-approximation reference
uses only the discretisations at resolutions 4 and 5. Runs that ran out of time
or memory are drawn on separate TO and MO lines; killed runs count as MO.

`python3 scripts/postprocess.py LOGDIR... --output-dir DIR` processes several log
directories at once; `--compile` also builds `plots/runtime-comparison.pdf` and
`.png` of the figure, which needs LuaLaTeX with the `standalone` and `llncs`
classes and `pdftoppm` (Poppler).
