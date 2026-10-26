# Experimental evaluation for: "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

Experimental evaluation for the tool paper "The Probabilistic Model Checker Storm: Lightning Strikes Twice". This artifact reproduces the figures 6, 7, 8, and 9.

All experiments are meant to be run in the docker container provided. This README contains instructions for loading this container, and running a smoke, representative and full experiment set. Furthermore, it contains descriptions of how all experiments can be configured and run individually. Lastly, it details how to build the container and this artifact.

## Host requirements
This artifact was built for both x86 (amd64) and ARM (arm64) based Linux and macOS hosts. However, **Storm 1.6.2 is not supported on ARM based CPUs**, so its runs end with an error on these hosts and show up as errors in the results. We tested the artifact on amd64 hosts running Linux (Debian forky/sid with Linux 6.18 and Docker 29.4 with the containerd image store); arm64 and macOS hosts were not tested.

At least **5 physical CPU** cores are needed and at least **17GiB of memory** for the smoke and representative experiments (the full experiments need 33 GiB of memory). On macOS and Windows, these are the cores and memory given to the virtual machine of Docker Desktop, which can be set under Settings → Resources. The container also needs **50 GB of free disk space** when loaded into docker. No network access is needed to run the experiments. 

When running with the minimum requirements all experiments will be done sequentially. For every additional 4 physical cores and 16GiB (32GiB for the full experiments) of memory an additional parallel runner will be used.

If your machine does not meet these requirements, you can run the representative experiments on a minimal machine with `3_minimal.sh` instead (see [Running the representative experiments](#running-the-representative-experiments)). This gives every run **2 physical cores** and **8 GiB of memory** instead of 4 cores and 16 GiB, and needs at least **3 physical CPU cores** and **9 GiB of memory**. For every additional 2 physical cores and 8 GiB of memory an additional parallel runner will be used. As Storm's symbolic engines and PRISM then have fewer cores and less memory, more runs time out or run out of memory, so the results deviate more from the paper.

To achieve fully stable experimental results additional configurations on the host machine need to be done as detailed in [Additional Setup](#additional-setup).

## License

The Modest Toolset is licensed under the license located at `docker/modest/License.txt`.
Storm is licensed under the license located at `docker/storm/LICENSE.txt`.
All other contents are licensed under the [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) license.

## Loading the container
- Install [Docker](https://docs.docker.com/get-started/get-docker/).
- In the Docker settings, ensure that the `Use containerd for pulling and storing images` option is enabled. This is necessary to support the provided [multi-platform image](https://docs.docker.com/build/building/multi-platform/).
- Download the file `storm2-experiments-artifact.zip` from [Zenodo](https://doi.org/10.5281/zenodo.23668956) and unzip it at a convenient location. Throughout this document, `$ARTIFACT_DIR` refers to the path leading to the unzipped directory, i.e., a copy of this Readme is located at `$ARTIFACT_DIR/README.md`.
- Execute `$ARTIFACT_DIR/1_load.sh`. This will load the docker file.

We run the docker with additional options `--privileged --cap-drop=all`. These let the experiment runner pin experiments to cores and enforce memory limits. All other privileges are dropped.

## Running the smoke test
- Execute `$ARTIFACT_DIR/2_smoke.sh`. This should take around 8 minutes on the minimum setup and 3 minutes when doing 4 runs in parallel.
- Check that the output ends with `== all results checked`, followed by where the results are. If a run gave an incorrect result or none at all, it ends with `== results with problems in:` and the experiments concerned instead, and the problems are listed above it.
- A pdf `smoke.pdf`, containing the figures and the results with logs in `smoke/` are placed in the current directory.
- Inspect the produced `smoke.pdf` in your current directory. It should contain the 4 figures from the paper, with only one point in each scatter plot and the curves of one model in Figure 9.

If you encounter issues with the smoke test please provide a zip of the pdf and the results directory together with a description of your issues.

We provide a pdf and the results of a sample run in the folder `$ARTIFACT_DIR/artifact-results/smoke/`.

The smoketest will run every configuration of every experiment on one small benchmark with a time limit of 60 seconds. Then it follows the normal post processing and plot generation procedures as the representative and full experiments.

## Running the representative experiments
- Execute `$ARTIFACT_DIR/3_representative.sh`. This should take x minutes on the minimum requirements and y minutes with 4 runners.
- Figures 6, 7, 8, and 9 will be given in `representative.pdf` in your current directory.
- The data and logs can be inspected in the folder `representative/` in your current directory.

We provide a pdf and the results of a sample run in the folder `$ARTIFACT_DIR/artifact-results/representative/`.

On a minimal machine (see [Host requirements](#host-requirements)), execute `$ARTIFACT_DIR/3_minimal.sh` instead. It runs the same benchmarks with 2 physical cores and 8 GiB of memory per run, and gives the figures in `minimal.pdf` and the data and logs in `minimal/` in your current directory. Storm's symbolic engines then use 2 instead of 4 threads, PRISM gets 8 GiB for Java, and the decision diagram libraries of both (Sylvan and CUDD) get 4 instead of 8 GiB.

The representative experiments contain a subset of the benchmarks and have lower resource requirements. The benchmarks were chosen such that the results produced are representative for the full benchmark set with the full hardware requirements.

## Running the full experiments
- Execute `$ARTIFACT_DIR/4_full.sh`. This should take around 70 hours on the minimum requirements (requiring 33 GiB of memory) and 18 hours with 4 runners (Requiring 129GiB of memory).
- Figures 6, 7, 8, and 9 will be given in `full.pdf` in your current directory.
- The data and logs can be inspected in the folder `full/` in your current directory.

We provide the logs, results and figure data of the runs shown in the paper in the folder `$ARTIFACT_DIR/paper_results/`, see [paper_results/README.md](paper_results/README.md).

The full experiments run every configuration of every experiment on all benchmarks with a time limit of 900 seconds and a memory limit of 32 GiB per run, as in the paper. These are 1759 runs: 957 of `comparison_tools_bisim`, 156 of `imdps` and 646 of `pomdp`. The estimated running times are the sum of the runtimes of the runs in the paper; if every run timed out, it would take 440 hours on the minimum requirements.

The container runs in the background, so the experiments go on when the terminal is closed. Executing `4_full.sh` again in the same directory waits for them to finish and then copies the results. To abort the experiments, execute `docker rm -f storm2-full`, which also removes the logs of the finished runs; there is no resuming. The same holds for the smoke test and the representative experiments, with the containers `storm2-smoke` and `storm2-representative`.

## Difference storm 2.0 and storm used for included paper.
*Fill in*

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
- Go to the directory of the experiment, e.g. `cd experiments/comparison_tools_bisim`, and run the four steps below.
```bash
python3 ../../scripts/common/generate_invocations.py --out inv.json --logdir experiments/logs
python3 ../../scripts/common/run.py inv.json
python3 ../../scripts/common/postprocess.py experiments/logs experiments/results
../../scripts/build_figures.sh
```
- Copy the results out of the container from another terminal, e.g. `docker cp storm2:/opt/storm2-experiments/experiments/comparison_tools_bisim/experiments bisim` and `docker cp storm2:/opt/storm2-experiments/plots/latex/main.pdf .`.

For `imdps`, post-process with `postprocess.py --agreement --absolute`, as there are no exact results for interval MDPs and the configurations have to agree on them instead. `build_figures.sh` builds the figures of all experiments with results in `plots/latex/main.pdf`, and writes the csv files they are made from to `plots/latex/data/`.

The scripts in `scripts/common/` describe all their options with `--help`. The most important ones:
- `generate_invocations.py`: `--configs` and `--benchmarks` select configurations and benchmarks by their names in `scripts/configurations.json` and `benchmarks/index.json` of the experiment, `--index index-smoke.json` another set of benchmarks, `--timelimit` the time limit in seconds (default: 900), and `--repetitions` repeats every run.
- `run.py`: `--memlimit` sets the memory limit in GiB (default: 32), `--jobs N` the number of runs in parallel instead of as many as fit, `--cores-per-run` the physical cores of every run (default: 4), and `--ddmem` the memory of the decision diagram libraries in GiB (default: 8). The tools get these through the placeholders `%memlimit`, `%cores`, `%ddmem` and `%ddmem-mb` of `configurations.json`: PRISM's `-javamaxmem` is the memory limit and its `-cuddmaxmem` the decision diagram memory, and Storm's symbolic engines get the cores as `--sylvan:threads` and the decision diagram memory as `--sylvan:maxmem`. With `--sequential`, the runs are done one after the other without BenchExec, so without pinning and memory limit and without `--privileged`. Results measured with different `--cores-per-run` are not comparable.
- `check_results.py experiments/results` lists the runs with an incorrect result or none at all, and for `pomdp` bounds that contradict each other.

`run.py` writes one log per run to `experiments/logs/`, and `postprocess.py` writes `results.json` with the status, runtime and result of every run, and `table/index.html`, a table of all runs linking to their logs, to `experiments/results/`; `pomdp` has its own post-processing, see [experiments/pomdp/README.md](experiments/pomdp/README.md).

Every run gets 4 physical cores because some configurations use several threads: Storm's symbolic engines (`storm-hybrid-sound`, `storm-sound-ddbisim`) run Sylvan with 4 threads, and Java, which runs PRISM, chooses a single-threaded garbage collector when it sees only one core.

## The artifact
### Contents

| Path | Description |
| --- | --- |
| `storm2-experiments.tar.gz` | The saved Docker image, for amd64 and arm64, loaded by `1_load.sh` |
| `1_load.sh` ... `6_create_artifact.sh` | The scripts to run outside the container, in the order of this README: `1_load.sh` loads the image, `2_smoke.sh`, `3_representative.sh`, `3_minimal.sh` and `4_full.sh` run the experiment sets in a container (all four through `docker/run_in_container.sh`), `5_build.sh` builds the image and `6_create_artifact.sh` creates the artifact |
| `docker/` | `run_in_container.sh` runs an experiment set in a container and copies its results out, `init.sh` is the entrypoint of the image, `storm-old` runs Storm 1.6.2, and `modest/` and `storm/` hold the licenses and, for `modest/`, the zips of the Modest Toolset |
| `Dockerfile` | The Docker image with all tools: Storm 2.0.0, Storm 1.6.2, PRISM 4.10.1, the Modest Toolset v3.1.315, Julia 1.13.0 with IntervalMDP.jl, LaTeX, BenchExec, and this repository in `/opt/storm2-experiments` |
| `experiments/comparison_tools_bisim/` | Comparison of Storm, mcsta and PRISM, with and without bisimulation minimisation (Figures 6 and 7) |
| `experiments/imdps/` | Comparison of Storm, PRISM and IntervalMDP.jl on interval MDPs derived from `mdp_benchmarks/` (Figure 8); see [experiments/imdps/README.md](experiments/imdps/README.md) |
| `experiments/pomdp/` | Belief exploration of storm-pomdp with cut-offs on POMDPs (Figure 9); see [experiments/pomdp/README.md](experiments/pomdp/README.md) |
| `experiments/imdps/benchmarks.tar.xz` | The generated interval MDPs of `imdps`, which `5_build.sh` unpacks |
| `mdp_benchmarks/` | The model and property files of the MDP benchmarks |
| `scripts/` | `run_smoke.sh`, `run_representative.sh`, `run_minimal.sh` and `run_all.sh` run the experiment sets inside the container (all four through `common/run_set.sh`) and `build_figures.sh` builds the figures |
| `scripts/common/` | The scripts to generate, run, post-process and check the runs, shared by all experiments |
| `plots/latex/` | The source for the figure in paper, built by `scripts/build_figures.sh` |
| `artifact-results/` | The pdf, logs and results of sample runs of `2_smoke.sh` and `3_representative.sh` |
| `paper_results/` | The logs, results and figure data of the runs in the paper; see [paper_results/README.md](paper_results/README.md) |
Every experiment directory has the same layout: `scripts/configurations.json` lists the configurations, `bin/` holds the tools, `benchmarks/index.json` describes the benchmarks, and `experiments/` receives the logs and results. Next to `index.json`, `index-representative.json` and `index-smoke.json` hold the benchmarks of the representative experiments (also used by `3_minimal.sh`) and the smoke test.

### Building the docker
- Execute `$ARTIFACT_DIR/5_build.sh`. This builds the image `storm2-experiments` for amd64 and arm64 and saves it to `storm2-experiments.tar.gz` in the current directory (`-o FILE` for another file).
- With `PLATFORMS=linux/amd64 ./5_build.sh`, the image is built for one architecture only. Other options are passed on to `docker buildx build`.
- Building for an architecture other than that of the machine needs QEMU (`docker run --privileged --rm tonistiigi/binfmt --install arm64`) and takes much longer, mostly for the Julia sysimage.

The build needs about 100 GB of free disk space for Docker, plus the space of the saved file. The interval MDPs of `imdps` come with the artifact in `experiments/imdps/benchmarks.tar.xz`, which `5_build.sh` unpacks; the build only generates those that are missing, which takes a few hours and tens of GB of memory for the largest models (`--build-arg generate_workers=N` sets how many are generated at once, default: 2). The Modest Toolset website only offers its latest version, so the zips of the version used are kept in `docker/modest/` and checked against `docker/modest/SHA256SUMS`.

Build arguments select other versions of the tools: `STORM_BASE` another Storm image (default: `movesrwth/storm:2.0.0`), `STORM_OLD_BASE` the old Storm to compare with (default: `movesrwth/storm:1.6.2`), `STORMPY_BASE` the stormpy that generates the interval MDPs, and `prism_version` and `julia_version`. To run a Storm of your own, build it with Storm's Dockerfile and pass it as `STORM_BASE`:

```bash
docker build -t storm:local --build-arg no_threads=8 ../storm
./5_build.sh --build-arg STORM_BASE=storm:local
```

The Julia sysimage of IntervalMDP.jl is compiled for the CPU targets of Julia itself, so the image runs on other CPUs than the one that built it.

### Building the artifact
The artifact building is based on the git repository it is build in. Thus, it assumes the artifact is a git repository.

- Commit all changes, as the artifact only contains the committed files of the repository.
- Build and save the image with `5_build.sh` (see above), after the last commit.
- Execute `6_create_artifact.sh`. This writes `storm2-experiments-artifact.zip` to the current directory (or the file given as its argument), with the committed files, the saved image, the zips of the Modest Toolset and `experiments/imdps/benchmarks.tar.xz`, all below `storm2-experiments/`.

`6_create_artifact.sh` refuses to create the artifact when there are uncommitted changes, when one of these files is missing, or when the saved image is older than the last commit. To update the sample runs in `artifact-results/`, execute `../2_smoke.sh` and `../3_representative.sh` in `artifact-results/` (after moving the old ones away) with the new image loaded, and commit them before building the image that goes into the artifact.