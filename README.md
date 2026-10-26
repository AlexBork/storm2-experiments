# Artifact for: "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

This artifact contains Storm 2.0 and stormpy 2.0, all benchmarks and scripts of the experiments of Sec. 8 of the tool paper "The Probabilistic Model Checker Storm: Lightning Strikes Twice", and the logs and results of the runs shown in the paper. It reproduces Figures 6, 7, 8, and 9. All tools and experiments run in the provided Docker images, so nothing has to be compiled or installed apart from Docker.

- [What can I run on what kind of machine?](#host-requirements)
- [How do I install?](#loading-the-container)
- [How do I replicate (a subset of) the experiments?](#running-the-smoke-test), starting with the [smoke test](#running-the-smoke-test), then [comparing to the paper](#comparing-to-the-paper)
- [How can I try my own experiments?](#playing-with-storm-and-stormpy), either by [playing with Storm and stormpy](#playing-with-storm-and-stormpy) or by [running the benchmark scripts on your own models](#running-your-own-benchmarks)

## Host requirements

| Experiment set | Command | Needs at least | Takes about | With `-p` and 4 runs at a time ([Parallel execution](#parallel-execution)) |
| --- | --- | --- | --- | --- |
| [Smoke test](#running-the-smoke-test) | `scripts/2_smoke.sh` | 5 cores, 17 GiB | 8 minutes | 3 minutes (17 cores, 65 GiB) |
| [Minimal](#running-the-minimal-experiments) | `scripts/3_minimal.sh` | 3 cores, 9 GiB | x hours | y hours (9 cores, 33 GiB) |
| [Representative](#running-the-representative-experiments) | `scripts/3_representative.sh` | 5 cores, 17 GiB | x hours | y hours (17 cores, 65 GiB) |
| [Full](#running-the-full-experiments) | `scripts/3_full.sh` | 5 cores, 33 GiB | 70 hours | 18 hours (17 cores, 129 GiB) |

The minimal and representative experiments reproduce the figures on a subset of the benchmarks and using lower hardware requirements. The full exeperiments replicate the exact experiments from the paper

All cores are counted in physical cores. On a larger machine, add `-p` to run several benchmarks at the same time, e.g. `scripts/3_representative.sh -p`; see [Parallel execution](#parallel-execution) for what this needs. Every machine additionally needs Docker and **50 GB of free disk space**; no network access is needed to run the experiments.

The artifact runs on Linux and macOS, on x86 (amd64) and ARM (arm64) CPUs. On ARM, the comparison with the previous version **Storm 1.6.2 is left out**, as Storm 1.6.2 only exists for x86. We tested the artifact on amd64 hosts running Linux (Debian forky/sid with Linux 6.18 and Docker 29.4 with the containerd image store); arm64 and macOS hosts were not tested. On macOS, the cores and memory are those given to the virtual machine of Docker Desktop, which can be set under Settings → Resources.

## Loading the container
1. Install [Docker](https://docs.docker.com/get-started/get-docker/).
2. On macOS (Docker Desktop), enable `Use containerd for pulling and storing images` in the Docker settings, which the provided [multi-platform image](https://docs.docker.com/build/building/multi-platform/) needs. On Linux this is usually not needed. The script will warn you if you need to change this.
3. Download `storm2-experiments-artifact.zip` from [Zenodo](https://doi.org/10.5281/zenodo.23668956) and unzip it at a convenient location. Throughout this document, `$ARTIFACT_DIR` refers to the unzipped directory, i.e., this README is `$ARTIFACT_DIR/README.md`.
4. Load the Docker image:[^privileged]
   ```bash
   $ARTIFACT_DIR/scripts/1_load.sh
   ```

[^privileged]: The scripts start the container with the options `--privileged --cap-drop=all`. These let the experiment runner pin every run to its own cores and enforce its memory limit; all other privileges are dropped.

## Running the smoke test
```bash
$ARTIFACT_DIR/scripts/2_smoke.sh
```

This runs every tool configuration of every experiment on one small benchmark with a time limit of 60 seconds, and then post-processes the results and builds the figures, like the larger experiment sets. It takes about 8 minutes.

What to check:
- The output shows the three experiments one after the other (`== ...: running experiment 1/3: mdp`, then `imdp` and `pomdp`), with a line `[done ...] CONFIGURATION BENCHMARK ... ok (...)` for every run. All runs of `mdp` and `imdp` should be `ok`. In `pomdp`, a few runs with the largest size limits (`cut30000000` and up) end with `timeout`, which is expected with the short time limit. On ARM, the runs of Storm 1.6.2 (`storm-old-sound`, `storm-old-exact`) end with `error`, which is expected as well.
- The output ends with `== all results checked`, followed by where the results are. If a run gave an incorrect result or none at all, it ends with `== results with problems in:` and the experiments concerned instead, and the problems are listed above it.
- `smoke.pdf` in your current directory contains Figures 6, 7, 8 and 9 of the paper, with only one point in each scatter plot and the curves of one model (refuel) in Figure 9. The logs and results are in `smoke/`.
- Compare with the sample run in `$ARTIFACT_DIR/results/artifact/smoke/`, which has the same output.

If you encounter issues with the smoke test, please provide a zip of `smoke.pdf` and `smoke/` together with a description of your issues.

## Comparing to the paper
The minimal, representative and full experiments reproduce Figures 6 to 9 of the paper:
- **Figure 6**: the MDP model checking performance of Storm compared with mcsta, PRISM and the previous version Storm 1.6.2, and of the configurations of Storm compared with each other (experiment `mdp`).
- **Figure 7**: bisimulation minimisation in Storm (experiment `mdp`).
- **Figure 8**: Storm, PRISM and IntervalMDP.jl on interval MDPs (experiment `imdp`).
- **Figure 9**: the belief exploration of Storm for POMDPs with different size limits (experiment `pomdp`).

Each experiment set writes the figures to `SET.pdf` and the logs and results to `SET/` in the current directory, e.g. `representative.pdf` and `representative/`. The absolute runtimes depend on the machine, so compare the shape of the figures: which tools and configurations solve how many benchmarks within a given time, and which is faster on which benchmarks. **On ARM, Storm 1.6.2 is missing** from Figure 6: its lines in the quantile plots are empty, and the scatter plot against it shows only n/a.

The container keeps running in the background, so the experiments go on when the terminal is closed. Executing the same script again in the same directory waits for them to finish and then copies the results. To abort them, execute `docker rm -f storm2-SET`, e.g. `docker rm -f storm2-representative`, which also removes the logs of the finished runs; there is no resuming.

### Running the minimal experiments
```bash
$ARTIFACT_DIR/scripts/3_minimal.sh
```

This runs the benchmarks of the [representative experiments](#running-the-representative-experiments) with a time limit of 90 seconds, but with 2 instead of 4 physical cores and 8 instead of 16 GiB of memory per run, so that it fits a smaller machine. It takes about x hours, and gives the figures in `minimal.pdf` and the logs and results in `minimal/`.

With fewer cores and less memory, Storm's symbolic engines use 2 instead of 4 threads, PRISM gets 8 GiB for Java, and the decision diagram libraries of both (Sylvan and CUDD) get 4 instead of 8 GiB. More runs therefore time out or run out of memory, in particular those of the symbolic engines of Storm and of PRISM, and the figures deviate more from those of the paper than the representative ones. Use the representative experiments if your machine has the cores and memory for them.

### Running the representative experiments
```bash
$ARTIFACT_DIR/scripts/3_representative.sh
```

This takes about x hours, and gives the figures in `representative.pdf` and the logs and results in `representative/`.

The representative experiments run all tool configurations on a subset of the benchmarks (53 of the 98 MDPs, 16 of the 52 interval MDPs and 8 of the 19 POMDPs, covering all models of the first two) with a time limit of 90 seconds and 16 GiB of memory per run, instead of 900 seconds and 32 GiB. The benchmarks were chosen such that, judged by the runtimes in the paper, about the same share of the runs times out at 90 seconds as in the paper at 900 seconds, so that the figures have the same shape as those of the paper. Runs that need more than 16 GiB run out of memory instead. The quantile plots of Figure 6 keep the axis label "out of 98" of the paper.

We provide the figures and results of a sample run in `$ARTIFACT_DIR/results/artifact/representative/`.

### Running the full experiments
```bash
$ARTIFACT_DIR/scripts/3_full.sh
```

This runs every configuration on all benchmarks with a time limit of 900 seconds and 32 GiB of memory per run, as in the paper: 1759 runs, 957 of `mdp`, 156 of `imdp` and 646 of `pomdp`. It takes about 70 hours, the sum of the runtimes in the paper (if every run timed out, 440 hours), and gives the figures in `full.pdf` and the logs and results in `full/`.

We provide the logs, results and figure data of the runs shown in the paper in `$ARTIFACT_DIR/results/paper/`, which also describes how to build the figures of the paper from them; see [results/paper/README.md](results/paper/README.md). Compare `full.pdf` with these figures and `full/` with these results.

## Playing with Storm and stormpy
[TOOLS.md](TOOLS.md) describes Storm and stormpy briefly and shows how to try them in their official Docker images: Storm on the robot vacuum example of the paper (Sec. 7) in `examples/vacuum/` and on the benchmarks of the experiments in `examples/`, the stormpy code of Fig. 4 of the paper, and the Jupyter notebooks of the Storm tutorial in `notebooks/`.

## Running your own benchmarks
The scripts of the experiments can also run all tool configurations of the MDP experiment on your own models, and check and compare their results and runtimes; see [Running your own benchmarks](experiments/README.md#running-your-own-benchmarks) in the README of the experiments. That README also describes how the experiments can be configured and run individually, and how to set up the host for stable timings.

## Difference storm 2.0 and storm used for included paper.
*Fill in*

## License
Storm is licensed under the license located at `storm/LICENSE`, stormpy under the license located at `stormpy/LICENSE`, and the notebooks under the license located at `notebooks/LICENSE` (all GPL-3.0).
The Modest Toolset is licensed under the license located at `Modest/License.txt` in the zips in `experiments/docker/modest/`.
All other contents are licensed under the [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) license, see `LICENSE`.

## The artifact
### Contents

| Path | Description |
| --- | --- |
| `scripts/` | The scripts to run, in the order of this README: `1_load.sh` loads the image, `2_smoke.sh`, `3_minimal.sh`, `3_representative.sh` and `3_full.sh` run the experiment sets in a container (all four through `experiments/docker/run_in_container.sh`), and `5_create_artifact.sh` creates the artifact |
| `examples/` | Example files: `vacuum/` the robot vacuum example of the paper (Sec. 7), and `mdp_benchmarks/` and `pomdp_benchmarks/` the models and properties of the MDP and POMDP benchmarks of the experiments; see [TOOLS.md](TOOLS.md) |
| `TOOLS.md` | A short description of Storm and stormpy and how to play with them on the examples |
| `notebooks/` | Jupyter notebooks of the Storm tutorial on the Orchard game for stormpy 2.0, a copy of `tutorial_orchard/` of the [stormpyter repository](https://github.com/volkm/stormpyter/tree/stormpy2) (branch `stormpy2`, commit `c47a454`) |
| `storm/` | The source code of Storm 2.0.0, a submodule of the [Storm repository](https://github.com/stormchecker/storm) at its tag `2.0.0` |
| `stormpy/` | The source code of stormpy 2.0.0, a submodule of the [stormpy repository](https://github.com/stormchecker/stormpy) at its tag `2.0.0` |
| `experiments/` | The experiments and the Docker image they run in; see [experiments/README.md](experiments/README.md) |
| `results/` | `paper/` the logs, results and figure data of the runs in the paper (see [results/paper/README.md](results/paper/README.md)), and `artifact/` the pdf, logs and results of sample runs of `scripts/2_smoke.sh` and `scripts/3_representative.sh` |
| `experiments/storm2-experiments.tar.gz` | The saved Docker image, for amd64 and arm64, loaded by `scripts/1_load.sh` |
| `LICENSE` | The license of the artifact (CC-BY 4.0) |

### Building the artifact
The artifact building is based on the git repository it is build in. Thus, it assumes the artifact is a git repository, with the submodules `storm/` and `stormpy/` checked out (`git clone --recurse-submodules`, or `git submodule update --init` in an existing clone).

- Commit all changes, as the artifact only contains the committed files of the repository and its submodules.
- Build and save the image with `experiments/build_docker.sh` (see [experiments/README.md](experiments/README.md#building-the-docker)), after the last commit. It writes the image to `experiments/storm2-experiments.tar.gz`.
- Update the sample runs in `results/artifact/` with this image: load it with `scripts/1_load.sh`, move the old sample runs away, execute `../../scripts/2_smoke.sh` and `../../scripts/3_representative.sh` in `results/artifact/`, and commit the new ones. `results/` is not part of the image, so this does not require rebuilding it.
- Execute `scripts/5_create_artifact.sh`. This writes `storm2-experiments-artifact.zip` to the current directory (or the file given as its argument), with the committed files of the repository and of `storm/` and `stormpy/`, the saved image, the zips of the Modest Toolset and `experiments/imdp/benchmarks.tar.xz`, all below `storm2-experiments/`.

`scripts/5_create_artifact.sh` refuses to create the artifact when there are uncommitted changes, when a submodule is not checked out at its committed commit, when one of these files is missing, or when the saved image is older than the last commit that changed `experiments/` or `examples/`.

## Parallel execution
With the option `-p`, `scripts/2_smoke.sh`, `scripts/3_minimal.sh`, `scripts/3_representative.sh` and `scripts/3_full.sh` run as many runs at the same time as fit into the machine, e.g. `scripts/3_representative.sh -p`. Every run is still pinned to its own physical cores and limited in memory, and one physical core and 1 GiB of memory stay free for the system. At the start of every experiment, the output shows how many runs fit (`fitting jobs: ...`) and how many run at a time (`jobs: ...`).

Every run gets 4 physical cores and 16 GiB of memory in the smoke test, 2 physical cores and 8 GiB in the minimal experiments, 4 physical cores and 16 GiB in the representative experiments, and 4 physical cores and 32 GiB in the full experiments. Running several at the same time needs these for every run, plus one physical core and 1 GiB:

| Runs at a time | Smoke test | Minimal | Representative | Full |
| --- | --- | --- | --- | --- |
| 1 | 5 cores, 17 GiB | 3 cores, 9 GiB | 5 cores, 17 GiB | 5 cores, 33 GiB |
| 2 | 9 cores, 33 GiB | 5 cores, 17 GiB | 9 cores, 33 GiB | 9 cores, 65 GiB |
| 3 | 13 cores, 49 GiB | 7 cores, 25 GiB | 13 cores, 49 GiB | 13 cores, 97 GiB |
| 4 | 17 cores, 65 GiB | 9 cores, 33 GiB | 17 cores, 65 GiB | 17 cores, 129 GiB |

and so on, with the cores and memory of one more run for every further run. Only physical cores count: the second hardware thread of a core (hyperthreading) stays idle. The memory is the total memory that Linux reports in `/proc/meminfo`, which is somewhat less than the installed memory; on macOS, the cores and memory are those given to the virtual machine of Docker Desktop.

For timings that are as stable as possible follow [Additional setup](experiments/README.md#additional-setup).
