# Storm 2 paper experiments

Benchmarks, scripts and results for the experimental evaluation accompanying the
Storm 2 paper. The experiments are meant to be run in the Docker image built from
this repository, which contains all tools in the versions used.

## Contents

| Path | Description |
| --- | --- |
| `comparison_tools_bisim/` | Comparison of Storm, mcsta and PRISM, with and without bisimulation minimisation |
| `imdps/` | Comparison of Storm, PRISM and IntervalMDP.jl on interval MDPs derived from `benchmarks/`; see [imdps/README.md](imdps/README.md) |
| `pomdp/` | Benchmarks of storm-pomdp's belief exploration (cut-offs and discretisation) on POMDPs; see [pomdp/README.md](pomdp/README.md) |
| `benchmarks/` | The model and property files of the MDP benchmarks, plus `index.json` describing every benchmark |
| `common/` | Scripts to generate, run and post-process the experiments, shared by all of them |
| `latex/` | The figures of all experiments, built from their post-processed results by `build_figures.sh` |
| `run_all.sh` | Runs and post-processes all experiments, and builds the figures |
| `Dockerfile`, `docker/` | The Docker image with all tools |
| `docs/` | The results of the recorded runs as browsable html tables |

Every experiment directory has the same layout: `benchmarks/index.json` lists its
benchmarks, `scripts/configurations.json` the configurations, `bin/` holds the
tools, and `experiments/` receives the logs and results. The scripts in `common/`
are run from the experiment directory.

| Experiment | Runs | Estimated running time | Worst case at 900 s per run |
| --- | --- | --- | --- |
| `comparison_tools_bisim` | 761 | 30 hours or more | 190 hours |
| `imdps` | 156 | 15 hours | 39 hours |
| `pomdp` | 665 | 7 hours | 166 hours |
| all | 1582 | 52 hours or more | 395 hours |

The estimated running times are those of the recorded runs, one run at a time;
they depend on the machine. The recorded runs of `comparison_tools_bisim` do not
include its 18 newest benchmarks, which add to its 30 hours. Runs in parallel (`--jobs`) divide these times
accordingly. As every run may use 32 GiB, the memory of the machine usually
bounds the number of runs in parallel rather than its cores: for example, a
machine with 503 GiB of memory and 24 physical cores runs `--jobs 15` (15 × 32 GiB
= 480 GiB for the runs, 23 GiB for the system), and all experiments then take
about 4 hours or more: 2 hours or more for `comparison_tools_bisim`, 1 hour for
`imdps` and 30 minutes for `pomdp`. Runs in parallel share the memory bandwidth and caches of the CPU, so
they can take somewhat longer than when run one at a time.

## Setting up the host

- **Linux on x86-64 with Docker.** The image is built for x86-64; the host needs
  cgroups v2, which every current distribution uses.
- **Memory.** Every run is limited to 32 GiB, so the host needs 32 GiB per run in
  parallel plus a few GiB for the system: at least 40 GiB for one run at a time,
  about 100 GiB for `--jobs 3`.
- **Disk.** The image takes about 50 GB, most of it the generated interval MDPs
  of `imdps`, plus the space of the saved file while loading it.
- **Stable timings.** Set the frequency governor of the host to `performance`
  and disable boost (turbo) before running, and do not run other workloads at
  the same time. With boost, the frequency of a core depends on the temperature
  and on how many other cores are busy, so the runtimes depend on the runs next
  to it. This needs root and `cpupower`, which comes with the package
  `linux-cpupower` on Debian, `linux-tools-common` and `linux-tools-$(uname -r)`
  on Ubuntu, `kernel-tools` on Fedora, and `cpupower` on Arch. The settings are
  lost on a reboot.

  ```bash
  sudo cpupower frequency-set -g performance
  sudo cpupower set --turbo-boost 0
  cpupower frequency-info --policy    # check the governor
  cpupower frequency-info | grep -A2 boost    # check boost
  ```

  Older versions of `cpupower` lack `--turbo-boost`; then disable boost with
  `echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost`, or on Intel with
  `echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo`.

## Loading the image

The image is distributed as a saved file (see [Building the image](#building-the-image)
for how to make it). Load it on the machine running the experiments:

```bash
docker load -i storm2-experiments.tar.gz
```

It contains Storm and stormpy 1.14.0, PRISM 4.10.1, the Modest Toolset (mcsta),
Julia 1.13.0 with IntervalMDP.jl and a precompiled sysimage, LaTeX, BenchExec, and
this repository in `/opt/storm2-experiments`, including the generated interval
MDPs of `imdps`.

## Running the experiments

Start the container with the options that BenchExec needs to pin every run to
its own cores and enforce the memory limit:

```bash
docker run -it --privileged --cap-drop=all --name storm2 storm2-experiments
```

`--privileged` gives the container access to the cgroups of the host; the
entrypoint `docker/init.sh` uses it only to set up the cgroups for BenchExec, and
`--cap-drop=all` drops the other privileges. Without these options, everything
except `run.py --jobs` works as well.

### All experiments at once

`run_all.sh` runs all experiments one after the other, post-processes them, and
builds the figures; its options are passed on to `run.py`. As this takes days,
start it in a container of its own that keeps running in the background:

```bash
docker run -d --privileged --cap-drop=all --name storm2 storm2-experiments \
    ./run_all.sh --jobs 2
docker logs -f storm2    # follow the progress
```

Once the container has stopped, copy the figures and results out of it as
described below; `docker cp` also works for a stopped container.

### Each experiment separately

Inside the container, every experiment is run from its directory in the same four
steps: list the invocations, run them, post-process the logs, and build the
figures. For the tool comparison:

```bash
cd /opt/storm2-experiments/comparison_tools_bisim
python3 ../common/generate_invocations.py --out inv.json --logdir experiments/logs
python3 ../common/run.py inv.json --jobs 2
python3 ../common/postprocess.py experiments/logs experiments/results
```

For the interval MDPs, whose models are generated when building the image (see
[imdps/README.md](imdps/README.md)), let the configurations agree on the results,
as there are no exact ones:

```bash
cd /opt/storm2-experiments/imdps
python3 ../common/generate_invocations.py --out inv.json --logdir experiments/logs
python3 ../common/run.py inv.json --jobs 2
python3 ../common/postprocess.py --agreement --absolute experiments/logs experiments/results
```

For the POMDPs (see [pomdp/README.md](pomdp/README.md)):

```bash
cd /opt/storm2-experiments/pomdp
python3 ../common/generate_invocations.py --out inv.json --logdir experiments/logs
python3 ../common/run.py inv.json --jobs 2
python3 ../common/postprocess.py experiments/logs experiments/results
```

Finally, build the figures of all experiments with results in `latex/main.pdf`,
and copy them and the results out of the container:

```bash
/opt/storm2-experiments/build_figures.sh
```

```bash
# on the host
docker cp storm2:/opt/storm2-experiments/latex/main.pdf .
docker cp storm2:/opt/storm2-experiments/latex/data .
docker cp storm2:/opt/storm2-experiments/comparison_tools_bisim/experiments bisim
docker cp storm2:/opt/storm2-experiments/imdps/experiments imdps
docker cp storm2:/opt/storm2-experiments/pomdp/experiments pomdp
```

`latex/data/` holds the csv files the figures are made from, in the layout the
figures of the paper expect: those of `comparison_tools_bisim` directly in it,
those of `imdps` in `data/imdp/`. To update the figures of the paper, replace its
`data/` directory with this one; `latex/plots.tex` and `latex/main.tex` are the
same macros and figures as in the paper. The `experiments/` directories hold the
logs and all results of every experiment, including the csv files and plot
commands of `pomdp` in `pomdp/experiments/results/`, which are not part of
`latex/main.pdf` yet.

The runs have a time limit of 900 seconds (`generate_invocations.py --timelimit`)
and a memory limit of 32 GiB (`run.py --memlimit`), which PRISM is also told
with `-javamaxmem 32g` in its configurations. Choose `--jobs` such that the
runs fit into the memory of the host. A run that exceeds its time limit counts as
a timeout, one that exceeds its memory limit as a memout. `run.py` prints the
cores and frequency governor of every worker, and warns if boost is enabled.

To check the setup quickly, run a few benchmarks with a short time limit first,
e.g. `--benchmarks consensus.4-4.c2,tireworld.17.goal --timelimit 60` for
`generate_invocations.py` in `comparison_tools_bisim`.

## Building the image

The image can be built on any x86-64 machine with Docker, e.g. a different one
than the one running the experiments, and saved to a file to move it there:

```bash
docker build -t storm2-experiments .
docker save storm2-experiments | gzip > storm2-experiments.tar.gz
```

The build generates the 52 interval MDPs of `imdps` (44 GB), which takes a few
hours and, for the largest models, tens of GB of memory per model generated in
parallel; `--build-arg generate_workers=N` sets how many are generated at once
(default: 2). Docker caches this step, so it is only repeated when
`imdps/generate/` or `benchmarks/` change. The build needs about 100 GB of disk
space for Docker, plus the saved file.

The image is based on the stormpy image `movesrwth/stormpy:1.14.0`. Build
arguments select other versions: `STORMPY_BASE` another Storm and stormpy (e.g.
`movesrwth/stormpy:ci`, or an image built with the Dockerfiles of a local Storm and
stormpy), and `prism_version`, `julia_version` and `modest_version` the other
tools. The Modest Toolset website only offers its latest version, so the image may
contain a newer mcsta than the one in the recorded logs. The Julia sysimage is
compiled for generic CPU targets, so the image runs on other CPUs than the one
that built it.

## The scripts

- `generate_invocations.py` writes one invocation per configuration, benchmark
  and repetition, and skips combinations that cannot be run, for example a PRISM
  invocation for a benchmark that only has a JANI model. `--configs` and
  `--benchmarks` select a part, `--repetitions` repeats every run.
- `run.py` runs every invocation in its own temporary directory and writes its
  log. With `--jobs N`, N runs take place at the same time, each run by
  BenchExec's RunExecutor and pinned to its own physical core (`--cores-per-run`
  for more); the second hardware thread of that core stays idle. `--cores`
  restricts the CPUs used, e.g. to spread the runs over the L3 caches of the CPU,
  which BenchExec fills one after the other. Without `--jobs`, the runs take place
  one after the other without pinning and without a memory limit. `--entry I`
  runs a single invocation, e.g. to distribute the work over a cluster.
- `postprocess.py` writes `results.json` (status, runtime, result and difference
  to the reference result of every run), `scatter.csv` and `quantile.csv` for the
  figures, and `table/index.html`, a sortable table linking to the logs of every
  run. An experiment whose results need their own processing has a
  `scripts/postprocess.py`, which `postprocess.py` calls instead, like `pomdp`.

All scripts describe their options with `--help`. Pinning does not separate the
memory bandwidth and the L3 cache shared by the cores, so check how much the times
of a sample of invocations change compared to `--jobs 1` before running many jobs
at once.

## Running without Docker

The experiments also run on a host with the tools installed. Link them into the
`bin/` directory of every experiment: `storm`, `modest` and `prism` for
`comparison_tools_bisim`, `storm`, `prism` and `julia` for `imdps` (see its
README for IntervalMDP.jl), and `storm-pomdp` for `pomdp`. Link the launcher
scripts of mcsta and PRISM rather than their jar files. Storm has to be 1.13 or
newer, PRISM 4.10.1 or newer.

`run.py --jobs` needs BenchExec in a virtual environment and cgroups delegated to
the user, and is started in its own systemd scope:

```bash
python3 -m venv .venv    # or: uv venv .venv
.venv/bin/pip install -r requirements.txt

# once per machine, as root: delegate all cgroups to the users
sudo systemctl edit user@.service    # add: [Service] Delegate=yes

cd comparison_tools_bisim
systemd-run --user --scope --slice=benchexec -p Delegate=yes \
    ../.venv/bin/python ../common/run.py inv.json --jobs 2
```

BenchExec runs every invocation with a fresh, empty `$HOME`; for IntervalMDP.jl,
set `JULIA_DEPOT_PATH=$HOME/.julia:` before starting `run.py`. Building the
figures needs pdflatex with pgfplots and the `colorblind` package.

## License

The contents of this repository are licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); see [LICENSE](LICENSE).

This does not extend to the tools in the `bin/` directories of the experiments,
which are not part of this repository.
