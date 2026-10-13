# POMDPs

Benchmarks of `storm-pomdp` for the tool paper. The experiment suite contains
**19 instances and 35 configurations (665 runs)**: 32 explicit cut-offs from
10,000 to 50,000,000, static discretisation at resolutions 4 and 5, and the fully
observable MDP reference.

| Path | Description |
| --- | --- |
| `benchmarks/` | The PRISM models and properties, plus `index.json` describing every instance |
| `scripts/configurations.json` | The configurations: the method `family` of each, and the `size-threshold` of the cut-offs |
| `scripts/postprocess.py` | The POMDP-specific post-processing, called by `common/postprocess.py` |
| `scripts/` (other files) | Modules and plot utilities used by the post-processing, see below |

## Running the experiments

The steps are those of the other experiments, see the [README](../README.md) in
the root of this repository. The tool is expected as `bin/storm-pomdp`:

```bash
cd pomdp
mkdir -p bin
ln -s /path/to/storm/build/bin/storm-pomdp bin/storm-pomdp

python3 scripts/benchmarks.py    # checks the model and property files
python3 ../common/generate_invocations.py --out inv.json --timelimit 900 \
    --logdir experiments/logs
python3 ../common/run.py inv.json
python3 ../common/postprocess.py experiments/logs experiments/results
```

As in the other experiments, the time limit is **900 seconds**; the worst-case
runtime of the suite is then 166 hours 15 minutes plus overhead, run one at a
time. A previous full run with a time limit of 600 seconds took about 6.6 hours.
`--configs` and `--benchmarks` of `generate_invocations.py`
select a part, e.g. `--configs discr004s,discr005s,mdp`. Record the Storm
revision, CPU, RAM, and external resource limits with the results.

## Benchmark configuration

The instances are listed in `benchmarks/index.json`, the configurations in
`scripts/configurations.json`. Every instance is checked with the same 32
cut-offs:

| Range | Tested thresholds |
| --- | --- |
| Ten thousands | 10,000, 20,000, …, 90,000 |
| Hundred thousands | 100,000, 200,000, …, 900,000 |
| Millions | 1,000,000, 2,000,000, …, 9,000,000 |
| Ten millions | 10,000,000, 20,000,000, 30,000,000, 40,000,000, 50,000,000 |

The instance families are grid, grid-avoid, samplerocks, drone, lanes,
grid-large, network, network-priorities, maze2, and refuel. The suite includes
14 of the 15 instances in Tables 1 and 2 of the
[TACAS 2022 paper](https://doi.org/10.1007/978-3-030-99527-0_2), plus five
additional instances. Grid-avoid/sl0 is excluded; the additional instances
are Drone N5-R3, Drone N6-R3, lanes-100, grid-large-30-5, and maze2/sl0.3.

## Postprocessing

`common/postprocess.py` hands the logs to `scripts/postprocess.py`, which reads
them without modifying them and writes to the results directory:

- `execution-data.json` and `benchmark-data.json`: parsed results and
  model statistics.
- `runtime-report.md` and `runtime-*.csv`: cumulative runtimes, outcomes,
  and per-run audits.
- `html/index.html`: an offline sortable/filterable table, with links
  to per-run commands, metadata, and logs. Share the entire `html/`
  directory to include its styles, script, and log pages.
- Shared CSV data, reusable TeX commands, and a per-instance plot preview.

Failures remain in the exports. A non-timeout SIGKILL is reported as
`killed`, which does not establish its cause. Runtime totals include failed
runs; derived best configurations are excluded from totals and the HTML
table. Bounds are compared separately for cut-offs and over-approximation
references, respecting minimisation/maximisation and breaking ties by runtime.
The audit CSV files are tab-separated; plotting CSVs use commas.

`python3 scripts/postprocess.py LOGDIR... --output-dir DIR` processes several log
directories at once, and `--legacy-outputs` also writes the historical
dissertation outputs. The HTML table can be regenerated from existing exports
with `python3 scripts/html_results.py`, and `python3 scripts/compare_logs.py`
compares two log directories.

## Plot utilities

The per-instance plots use `cutoff-threshold-plot-data.csv` and
`pomdp-instance-plots.tex` of the results directory:

```tex
% Document preamble:
\input{experiments/results/pomdp-instance-plots.tex}
\StormPOMDPLoadData{experiments/results/cutoff-threshold-plot-data.csv}
% Document body:
\StormPOMDPValuePlot{drone_drone_prbmax_N6-R3}
\StormPOMDPRuntimePlot[width=7cm,height=5cm]{drone_drone_prbmax_N6-R3}
```

Compile the generated instance preview from the results directory:

```sh
cd experiments/results
lualatex --interaction=nonstopmode --halt-on-error cutoff-threshold-preview.tex
```

The exploratory summary plots are separate from the post-processing:

```sh
python3 scripts/toolpaper_plots.py --compile
```

They use the audited exports and successful source logs, producing CSV-backed
commands and a combined preview under
`experiments/results/general-plots/pomdp-tool-paper/`. That directory's
generated README documents the commands and metrics. Their plot design is still
being reconsidered. LuaLaTeX and `pdftoppm` are optional requirements for
PDF/PNG generation.
