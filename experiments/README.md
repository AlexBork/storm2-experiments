# The experiments of "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

This folder holds the experiments of the artifact and the Docker image they run in; the results of the paper are in [`../results/paper/`](../results/paper/README.md). How to load the image and run the smoke test, the representative and the full experiments is described in the [README of the artifact](../README.md). This README describes how to set up the host for stable timings, how the experiments can be configured and run individually, and how to build the image.

## Additional setup
### Stable timings (Only for linux)
Set the frequency governor of the host to `performance`
and disable boost (turbo) before running, and do not run other workloads at
the same time. With boost, the frequency of a core depends on the temperature
and on how many other cores are busy, so the runtimes depend on the runs next
to it. This needs root and `cpupower`, which comes with the package
`linux-cpupower` on Debian, `linux-tools-common` and `linux-tools-$(uname -r)`
on Ubuntu, `kernel-tools` on Fedora, and `cpupower` on Arch. The settings are
lost on a reboot.

```bash
sudo cpupower frequency-set -g performance # set the governor
sudo cpupower set --turbo-boost 0          # turn off boost
cpupower frequency-info --policy           # check the governor
cpupower frequency-info | grep -A2 boost   # check boost
```

Older versions of `cpupower` lack `--turbo-boost`; then disable boost with
`echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost`, or on Intel with
`echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo`.

## Running individual experiments
- Start an interactive container with `docker run -it --privileged --cap-drop=all --name storm2 storm2-experiments`.
- Go to the directory of the experiment, e.g. `cd mdp`, and run the four steps below.
```bash
python3 ../docker/common/generate_invocations.py --out inv.json --logdir experiments/logs
python3 ../docker/common/run.py inv.json
python3 ../docker/common/postprocess.py experiments/logs experiments/results
../docker/build_figures.sh
```
- Copy the results out of the container from another terminal, e.g. `docker cp storm2:/opt/storm2-experiments/mdp/experiments mdp` and `docker cp storm2:/opt/storm2-experiments/docker/plots/latex/main.pdf .`.

The image contains this folder in `/opt/storm2-experiments`. For `imdp`, post-process with `postprocess.py --agreement --absolute`, as there are no exact results for interval MDPs and the configurations have to agree on them instead. `build_figures.sh` builds the figures of all experiments with results in `docker/plots/latex/main.pdf`, and writes the csv files they are made from to `docker/plots/latex/data/`.

The scripts in `docker/common/` describe all their options with `--help`. The most important ones:
- `generate_invocations.py`: `--configs` and `--benchmarks` select configurations and benchmarks by their names in `scripts/configurations.json` and `benchmarks/index.json` of the experiment, `--index index-smoke.json` another set of benchmarks, `--timelimit` the time limit in seconds (default: 900), and `--repetitions` repeats every run.
- `run.py`: `--memlimit` sets the memory limit in GiB (default: 32), `--jobs N` the number of runs in parallel instead of as many as fit, `--cores-per-run` the physical cores of every run (default: 4), and `--ddmem` the memory of the decision diagram libraries in GiB (default: 8). The tools get these through the placeholders `%memlimit`, `%cores`, `%ddmem` and `%ddmem-mb` of `configurations.json`: PRISM's `-javamaxmem` is the memory limit and its `-cuddmaxmem` the decision diagram memory, and Storm's symbolic engines get the cores as `--sylvan:threads` and the decision diagram memory as `--sylvan:maxmem`. With `--sequential`, the runs are done one after the other without BenchExec, so without pinning and memory limit and without `--privileged`. Results measured with different `--cores-per-run` are not comparable.
- `check_results.py experiments/results` lists the runs with an incorrect result or none at all, and for `pomdp` bounds that contradict each other.

`run.py` writes one log per run to `experiments/logs/`, and `postprocess.py` writes `results.json` with the status, runtime and result of every run, and `table/index.html`, a table of all runs linking to their logs, to `experiments/results/`; `pomdp` has its own post-processing, see [pomdp/README.md](pomdp/README.md).

Every run gets 4 physical cores because some configurations use several threads: Storm's symbolic engines (`storm-hybrid-sound`, `storm-sound-ddbisim`) run Sylvan with 4 threads, and Java, which runs PRISM, chooses a single-threaded garbage collector when it sees only one core.

## Contents

| Path | Description |
| --- | --- |
| `storm2-experiments.tar.gz` | The saved Docker image, for amd64 and arm64, loaded by `scripts/1_load.sh` of the artifact |
| `build_docker.sh` | Builds the image and saves it to `storm2-experiments.tar.gz` |
| `docker/` | `run_in_container.sh` runs an experiment set in a container and copies its results out; inside the container, `run_smoke.sh`, `run_representative.sh`, `run_minimal.sh` and `run_all.sh` run the experiment sets (all four through `common/run_set.sh`) and `build_figures.sh` builds the figures; `init.sh` is the entrypoint of the image, `storm-old` runs Storm 1.6.2, and `modest/` and `storm/` hold the licenses and, for `modest/`, the zips of the Modest Toolset |
| `Dockerfile` | The Docker image with all tools: Storm 2.0.0, Storm 1.6.2, PRISM 4.10.1, the Modest Toolset v3.1.315, Julia 1.13.0 with IntervalMDP.jl, LaTeX, BenchExec, and this folder in `/opt/storm2-experiments` |
| `mdp/` | Comparison of Storm, mcsta and PRISM, with and without bisimulation minimisation (Figures 6 and 7) |
| `imdp/` | Comparison of Storm, PRISM and IntervalMDP.jl on interval MDPs derived from the MDP benchmarks of `mdp` (Figure 8); see [imdp/README.md](imdp/README.md) |
| `pomdp/` | Belief exploration of storm-pomdp with cut-offs on POMDPs (Figure 9); see [pomdp/README.md](pomdp/README.md) |
| `imdp/benchmarks.tar.xz` | The generated interval MDPs of `imdp`, which `build_docker.sh` unpacks |
| `mdp/benchmarks/models/`, `pomdp/benchmarks/models/` | Links to the model and property files of the MDP and POMDP benchmarks in `examples/mdp_benchmarks/` and `examples/pomdp_benchmarks/` of the artifact; `build_docker.sh` passes these to the build as the named build contexts `mdp_benchmarks` and `pomdp_benchmarks` |
| `docker/common/` | The scripts to generate, run, post-process and check the runs, shared by all experiments |
| `docker/plots/latex/` | The source for the figure in paper, built by `docker/build_figures.sh` |

Every experiment directory has the same layout: `scripts/configurations.json` lists the configurations, `bin/` holds the tools, `benchmarks/index.json` describes the benchmarks, and `experiments/` receives the logs and results. The model paths in an index are relative to its directory: those of `mdp` and `pomdp` point to `benchmarks/models/`, a link to the MDP or POMDP benchmarks in `examples/` of the artifact, and those of `imdp` to its generated models. Next to `index.json`, `index-representative.json` and `index-smoke.json` hold the benchmarks of the representative experiments (also used by `scripts/3_minimal.sh`) and the smoke test.

## Building the docker
- Execute `build_docker.sh` in this folder. This builds the image `storm2-experiments` for amd64 and arm64 and saves it to `storm2-experiments.tar.gz` next to it (`-o FILE` for another file).
- With `PLATFORMS=linux/amd64 ./build_docker.sh`, the image is built for one architecture only. Other options are passed on to `docker buildx build`.
- Building for an architecture other than that of the machine needs QEMU (`docker run --privileged --rm tonistiigi/binfmt --install arm64`) and takes much longer, mostly for the Julia sysimage.

The build needs about 100 GB of free disk space for Docker, plus the space of the saved file. The interval MDPs of `imdp` come with the artifact in `imdp/benchmarks.tar.xz`, which `build_docker.sh` unpacks; the build only generates those that are missing, which takes a few hours and tens of GB of memory for the largest models (`--build-arg generate_workers=N` sets how many are generated at once, default: 2). The Modest Toolset website only offers its latest version, so the zips of the version used are kept in `docker/modest/` and checked against `docker/modest/SHA256SUMS`.

Build arguments select other versions of the tools: `STORM_BASE` another Storm image (default: `movesrwth/storm:2.0.0`), `STORM_OLD_BASE` the old Storm to compare with (default: `movesrwth/storm:1.6.2`), `STORMPY_BASE` the stormpy that generates the interval MDPs, and `prism_version` and `julia_version`. To run a Storm of your own, e.g. that of `storm/` of the artifact, build it with Storm's Dockerfile and pass it as `STORM_BASE`:

```bash
docker build -t storm:local --build-arg no_threads=8 ../storm
./build_docker.sh --build-arg STORM_BASE=storm:local
```

The Julia sysimage of IntervalMDP.jl is compiled for the CPU targets of Julia itself, so the image runs on other CPUs than the one that built it.
