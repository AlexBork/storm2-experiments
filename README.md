# Storm 2 paper experiments

Benchmarks, scripts and results for the experimental evaluation accompanying the
Storm 2 paper.

## Contents

| Path | Description |
| --- | --- |
| `benchmarks/` | The model and property files, plus `index.json` describing every benchmark |
| `common/` | Scripts to generate, run and post-process the experiments, shared by all of them |
| `comparison_tools_bisim/` | Comparison of Storm, mcsta and PRISM, with and without bisimulation minimisation |
| `comparison_tools_bisim/benchmarks/` | A link to `benchmarks/` |
| `comparison_tools_bisim/scripts/` | The configurations compared, in `configurations.json` |
| `comparison_tools_bisim/experiments/` | The logs of the recorded run and the results derived from them |
| `imdps/` | Comparison of Storm, PRISM and IntervalMDP.jl on interval MDPs derived from `benchmarks/`; see [imdps/README.md](imdps/README.md) |
| `latex/` | The figures of all experiments, built with pgfplots from their post-processed data by `build_figures.sh` |
| `Dockerfile`, `docker/` | A Docker image with all tools, see [below](#docker) |

Every experiment directory has the same layout: `benchmarks/index.json` lists its
benchmarks, `scripts/configurations.json` the configurations, and `bin/` holds the
tools. The scripts in `common/` are run from the experiment directory.

## Running the experiments

The tools are expected in `comparison_tools_bisim/bin/` as `storm`, `modest` and
`prism`. This directory is not part of the repository; link the executables of an
existing installation into it, for example

```bash
cd comparison_tools_bisim
mkdir -p bin
ln -s /path/to/storm/build/bin/storm bin/storm
ln -s /path/to/Modest/modest bin/modest
ln -s /path/to/prism/bin/prism bin/prism

# each of these should now print a version
bin/storm --version && bin/modest --version && bin/prism -version
```

Link the launcher scripts of mcsta and PRISM rather than the jar files, so that
they find the rest of their installation. The configurations to compare are
defined in `scripts/configurations.json`.

```bash
cd comparison_tools_bisim

# 1. build the list of invocations (configuration x benchmark x repetition)
python3 ../common/generate_invocations.py --out inv.json --timelimit 900 \
    --logdir experiments/logs

# 2. run them; each invocation gets its own temporary directory and log file
python3 ../common/run.py inv.json

# 3. turn the logs into results.json, scatter.csv, quantile.csv and an html table
python3 ../common/postprocess.py experiments/logs experiments/results

# 4. build the figures of all experiments with results in latex/main.pdf
../build_figures.sh
```

`generate_invocations.py` skips configuration/benchmark combinations that cannot
be run, for example a PRISM invocation for a benchmark that only has a JANI
model. `run.py` takes `--entry I` to run a single invocation, which is useful for
distributing the work over a cluster. Both scripts describe their remaining
options with `--help`.

### Running invocations in parallel

`run.py --jobs N` runs N invocations at the same time. Every run is pinned to its
own physical core (`--cores-per-run C` for more), and the second hardware thread
of that core stays idle. `--cores` restricts the CPUs used, e.g. to leave the
first core to the operating system, or to spread the runs over the L3 caches
(the CCDs of a Ryzen), which BenchExec fills one after the other.
`--memlimit GB` limits the memory of each run.
The runs are executed by [BenchExec](https://github.com/sosy-lab/benchexec)'s
RunExecutor, which needs a virtual environment and cgroups delegated to the user:

```bash
python3 -m venv .venv    # or: uv venv .venv
.venv/bin/pip install -r requirements.txt

# once per machine, as root: delegate all cgroups to the users
sudo systemctl edit user@.service    # add: [Service] Delegate=yes
sudo cpupower frequency-set -g performance

cd comparison_tools_bisim
systemd-run --user --scope --slice=benchexec -p Delegate=yes \
    ../.venv/bin/python ../common/run.py inv.json --jobs 4 --memlimit 20
```

`run.py` prints the cores and the frequency governor of every worker, and how to
set the `performance` governor if it is not used. BenchExec runs every invocation
with a fresh, empty `$HOME`, so a tool must not rely on files there; for
IntervalMDP.jl, set `JULIA_DEPOT_PATH=$HOME/.julia:` before starting `run.py`. Pinning does
not separate memory bandwidth and the L3 cache of a CCD, so check how much the
times of a sample of invocations change compared to a run with `--jobs 1`.

### Docker

The `Dockerfile` builds an image with all tools set up as above: Storm and
stormpy 1.14.0, PRISM 4.10.1, the Modest Toolset, Julia 1.13.0 with IntervalMDP.jl
and its sysimage, and BenchExec. It is based on the stormpy image and takes
another one as build argument, e.g. one built with the Dockerfiles
of a local Storm and stormpy:

```bash
docker build -t storm2-experiments .
# or with another Storm and stormpy
docker build -t storm2-experiments --build-arg STORMPY_BASE=movesrwth/stormpy:ci .
```

The Modest Toolset website only offers its latest version, so the image may
contain a newer mcsta than the one in the recorded logs; `--build-arg
modest_version=...` selects another one.

Start the container with the options BenchExec needs for `run.py --jobs`, and
mount a directory for the generated interval models, which take tens of GB:

```bash
docker run -it --privileged --cap-drop=all \
    -v /path/with/space:/opt/storm2-experiments/imdps/benchmarks \
    --name storm2 storm2-experiments
```

Inside the container, the experiments run as described above, without
`systemd-run`, e.g.

```bash
cd imdps
python3 generate/generate_explicit_benchmarks.py --workers 4
python3 ../common/generate_invocations.py --out inv.json --timelimit 900 --logdir experiments/logs
python3 ../common/run.py inv.json --jobs 4 --memlimit 20
python3 ../common/postprocess.py --agreement --absolute experiments/logs experiments/results
```

and `../build_figures.sh` builds the figures of all experiments in `latex/main.pdf`.
`docker cp storm2:/opt/storm2-experiments/latex/main.pdf .` copies them out, and
`docker cp storm2:/opt/storm2-experiments/imdps/experiments .` the results.

`--privileged` gives the container full access to the host; the image's entrypoint `docker/init.sh` uses it only to set up the cgroups for
BenchExec, and `--cap-drop=all` drops the other privileges. Without these
options, everything except `--jobs` works as well.

## Results

`postprocess.py` writes

- `results.json` — status, runtime, model checking result and the relative
  difference to the reference result, per configuration, benchmark and repetition,
- `scatter.csv` — median runtime per benchmark and configuration, with failures
  mapped to sentinel values so that pgfplots can plot them,
- `quantile.csv` — the sorted median runtimes of each configuration,
- `table/index.html` — a sortable table linking to the logs of every run.

## License

The contents of this repository are licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); see [LICENSE](LICENSE).

This does not extend to the tools in the `bin/` directories of the experiments,
which are not part of this repository.
