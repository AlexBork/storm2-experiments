# Artifact for: "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

This artifact contains sources and precompiled binaries of **Storm 2.0** and **stormpy 2.0**, all benchmarks and scripts of the experiments of Sec. 8 of the tool paper "The Probabilistic Model Checker Storm: Lightning Strikes Twice", and the logs and results of the runs shown in the paper. 
It reproduces Figures 6, 7, 8, and 9. 
All tools and experiments run in the provided Docker images.

We apply for the Available, Functional and Reusable badges.

## Getting started
Check the [requirements](#requirements), then follow the steps in this order:

1. [Load the Docker images](#step-1-load-the-docker-images) (at most 10 minutes).
2. [Run the smoke test](#step-2-run-the-smoke-test) of the experiment set you want to run (at most 5 minutes).
3. [Run the experiment set](#step-3-run-an-experiment-set) (hours to days, depending on the bechmark set and set-up).
4. [Create the figures from the logs](#step-4-create-the-figures-from-logs), of your run or of the runs of the paper (at most a few minutes).
5. Optionally, [play with Storm and stormpy](#step-5-play-with-storm-and-stormpy).

## Overview
The artifact consists of three parts:
- **Storm 2.0**, the probabilistic model checker presented in the paper: its source code in `storm/`, and in the Docker images `storm2-experiments` and `storm2-tools`.
- **stormpy 2.0**, the Python API of Storm (Sec. 7 of the paper): its source code in `stormpy/`, with the robot vacuum example of the paper in `examples/vacuum/`. We additionally provide an updated version the Jupyter notebooks of the Storm tutorial given at FM '26 in `notebooks/`.
- **The experiments** of Sec. 8 of the paper, which compare Storm with other tools on MDPs and interval MDPs, and showcase its POMDP functionality: the scripts to run them in `scripts/`, the experiments and their Docker image in `experiments/`, the benchmarks in `examples/`, and the logs and results of the runs in the paper and of sample runs of all experiment sets with this artifact in `results/`.

[TOOLS.md](TOOLS.md) describes how you can try out Storm and stormpy yourself.

Section [Contents](#contents) near the end of this README lists all folders.

## Requirements
We provide three experiment sets for reproducing (subsets of) the experiments in the paper, described in [The experiment sets](#the-experiment-sets). 
Run the largest one that fits your hardware and time constraints; the times are generous estimates based on our runs, so we expect most runs to be faster.

| Experiment set   | Needs at least  | Takes about | With `-p`, 4 parallel runs   |
| ---------------- | --------------- | ----------- | ---------------------------- |
| [Minimal]        | 3 cores, 9 GiB  | 7 hours     | 2 hours (9 cores, 33 GiB)    |
| [Representative] | 5 cores, 17 GiB | 7 hours     | 2 hours (17 cores, 65 GiB)   |
| [Full]           | 5 cores, 33 GiB | 85 hours    | 22 hours (17 cores, 129 GiB) |

[Minimal]: #minimal
[Representative]: #representative
[Full]: #full

All cores are counted in **physical cores**. 
On a larger machine, option `-p` allows running several benchmarks in parallel; see [Parallel execution](#parallel-execution). 
Every machine additionally requires **Docker** and **90 GB of free disk space**: about 60 GB for the loaded images, and the rest for the downloaded and unpacked artifact (about 12 GB each). 
No network access is needed.

The artifact runs on Linux and macOS, on x86 (amd64) and ARM (arm64) CPUs. 
On ARM, the comparison with the previous version **Storm 1.6.2 is left out**, as Storm 1.6.2 only exists for x86.
On macOS, the cores and memory are those given to the virtual machine of Docker Desktop, which can be set under Settings → Resources.

We tested the artifact on amd64 hosts running Linux (Debian forky/sid with Linux 6.18 and Docker 29.4, with both the containerd and the classic image store) and on a MacBook Pro (13-inch, M1, 2020) (ARM processor) running macOS 26.6.2 with Docker Desktop 4.97.0. 

## Step 1: Load the Docker images
1. Install [Docker](https://docs.docker.com/get-started/get-docker/).
2. Download `storm2-artifact.zip` from [Zenodo](https://doi.org/10.5281/zenodo.23668956) and unzip it at a convenient location. Throughout this document, `$ARTIFACT_DIR` refers to the unzipped directory `storm2-artifact/`, which contains this README as `README.md`.
3. Load the Docker images, `storm2-experiments` for the experiments and `storm2-tools` for [playing with Storm and Stormpy](#step-5-play-with-storm-and-stormpy):[^privileged]
   ```bash
   $ARTIFACT_DIR/scripts/1_load.sh
   ```
   This takes up to 10 minutes, and shows the progress of every layer of the images. The saved images are [multi-platform images](https://docs.docker.com/build/building/multi-platform/) for amd64 and arm64. Docker keeps the one suitable for your machine. 
   
   If loading fails, enable the *containerd* image store and try again:
    - Docker Desktop: Settings → General → enable "Use containerd for pulling and storing images",
    - Docker Engine: set `"features": {"containerd-snapshotter": true}` in `/etc/docker/daemon.json` restart Docker.

[^privileged]: The scripts start the container with the options `--privileged --cap-drop=all`. These let the experiment runner pin every run to its own cores and enforce its memory limit; all other privileges are dropped.

## Step 2: Run the smoke test
After loading the images, run the smoke test of the experiment set you want to run, `minimal`, `representative` or `full`, e.g.

```bash
$ARTIFACT_DIR/scripts/2_smoke.sh representative
```

This runs every tool configuration of the MDP and interval MDP experiments, and one cut-off and one discretisation of the POMDP experiment, on one small benchmark each with a time limit of 60 seconds, but with the cores and memory per run of the given set. Then it post-processes the results and builds the figures, like the experiment set. It checks that everything works and that your machine can run the set: if the machine is too small for it, the smoke test stops right away with `not enough cores or memory for a single run`. It takes at most 5 minutes; on our machine it took about a minute.

What to check:
- Every run ends with `ok` in its line `[done ...] CONFIGURATION BENCHMARK ... ok (...)`. On ARM, the runs of Storm 1.6.2 (`storm-old-sound`, `storm-old-exact`) are `skipped` instead.
- The output ends with a summary of the three experiments and `== all results checked`. If a run gave an incorrect result or none at all, the summary marks its experiment, the output ends with `== results with problems in:` and the experiments concerned, and the runs with problems are listed in the output of that experiment, below its line `checked ... runs`.
- `smoke-SET.pdf` in your current directory, e.g. `smoke-representative.pdf`, contains Figures 6, 7, 8 and 9 of the paper, with only one point in each scatter plot and in each panel of Figure 9.

The logs and results are in `smoke-SET/`. If you encounter issues with the smoke test, please provide a zip of `smoke-SET.pdf` and `smoke-SET/` with a description of your issues.

## Step 3: Run an experiment set
Run the experiment set, `minimal`, `representative` or `full`, e.g.

```bash
$ARTIFACT_DIR/scripts/3_run.sh representative
```

or with `-p` to run as many benchmarks at the same time as fit into your machine, e.g. `scripts/3_run.sh representative -p` (see [Parallel execution](#parallel-execution)). The run writes the figures to `SET.pdf` and the logs and results to `SET/` in the current directory, e.g. `representative.pdf` and `representative/`. Like the smoke test, it should end with `== all results checked`; some runs end with `timeout` or `memout`, which is expected.

What to compare with the paper:
- The absolute runtimes depend on the machine, so compare the shape of the figures with those of the paper: which tools and configurations solve how many benchmarks within a given time, and which is faster on which benchmarks.
- [The experiment sets](#the-experiment-sets) describes how the minimal and representative sets differ from the full experiments of the paper, and which deviations to expect.
- **On ARM, Storm 1.6.2 is missing** from Figure 6: its lines in the quantile plots are empty, and the scatter plot against it shows only n/a.
- Sample runs of all three sets with this artifact are in `$ARTIFACT_DIR/results/artifact/`, e.g. `representative.pdf` and `representative/`.

The experiments run in a container in the background, so they go on when the script or the terminal is closed. Executing the same command again in the same directory waits for them to finish and then copies the results. To abort them, execute `docker rm -f storm2-SET`, e.g. `docker rm -f storm2-representative`, which also removes the logs of the finished runs. A run that was aborted, or stopped by a restart of Docker or the machine, cannot be resumed.

## Step 4: Create the figures from logs
Create Figures 6 to 9 from the logs of any run with

```bash
$ARTIFACT_DIR/scripts/4_figures.sh DIR
```

where `DIR` is a folder of logs in the layout of the runs, e.g. `representative/` of your own run in Step 3, `$ARTIFACT_DIR/results/artifact/full/` of the sample run of the full experiments, or `$ARTIFACT_DIR/results/paper/` of the runs of the paper. This post-processes the logs of every experiment in the container, like the experiment sets, and writes the figures to `NAME-figures.pdf` in the current directory, e.g. `paper-figures.pdf`. It takes at most a few minutes.

[results/paper/README.md](results/paper/README.md) describes the logs and results of the paper. The figures and results of sample runs of the minimal, representative and full experiments and of their smoke tests with this artifact are in `$ARTIFACT_DIR/results/artifact/`.

## Step 5: Play with Storm and Stormpy
[TOOLS.md](TOOLS.md) describes Storm and Stormpy briefly and shows how to try them in the Docker image `storm2-tools` of the artifact: Storm on the robot vacuum example of the paper (Sec. 7) in `examples/vacuum/` and on the benchmarks of the experiments in `examples/`, the Stormpy code of Fig. 4 of the paper, and the Jupyter notebooks of the Storm tutorial in `notebooks/`.

## The experiment sets
All three experiment sets run all experiments on different benchmark sets with different amount of cores and memory. They all produce Figures 6 to 9 of the paper:
- **Figure 6**: the MDP model checking performance of Storm compared with mcsta, PRISM and the previous version Storm 1.6.2, and of the configurations of Storm compared with each other (experiment `mdp`).
- **Figure 7**: bisimulation minimisation in Storm (experiment `mdp`).
- **Figure 8**: Storm, PRISM and IntervalMDP.jl on interval MDPs (experiment `imdp`).
- **Figure 9**: the belief exploration of Storm for POMDPs with different size limits (experiment `pomdp`).

### Full
The full experiments run every configuration on all benchmarks with a time limit of 900 seconds and 4 physical cores and 32 GiB of memory per run, as in the paper: 1759 runs, 957 of `mdp`, 156 of `imdp` and 646 of `pomdp`. They take up to 85 hours with one run at a time; the runtimes of our run with this artifact add up to about 71 hours. Compare `full.pdf` with the figures of the paper ([Step 4](#step-4-create-the-figures-from-logs) creates them from `$ARTIFACT_DIR/results/paper/`), and `full/` with their results in `$ARTIFACT_DIR/results/paper/`.

### Representative
The representative experiments run all tool configurations on a subset of the benchmarks (53 of the 98 MDPs, 32 of the 52 interval MDPs and 8 of the 19 POMDPs, covering all models of the first two), 885 runs, with a time limit of 90 seconds and 16 GiB of memory per run instead of 900 seconds and 32 GiB. The benchmarks were chosen such that they show the same trends as the paper. With the shorter time limit, more runs time out than in the paper.

### Minimal
The minimal experiments run the benchmarks of the representative experiments with a time limit of 90 seconds, but with 2 instead of 4 physical cores and 8 instead of 16 GiB of memory per run, so that they fit a smaller machine. Storm's symbolic engines then use 2 instead of 4 threads, PRISM gets 8 GiB for Java, and the decision diagram libraries of both (Sylvan and CUDD) get 4 instead of 8 GiB. More runs therefore time out or run out of memory, in particular those of the symbolic engines of Storm and of PRISM, and the figures deviate more from those of the paper than the representative ones. Use the representative experiments if your machine has the cores and memory for them.

### Running your own benchmarks
The scripts of the experiments can also run all tool configurations of the MDP experiment on your own models, and check and compare their results and runtimes; see [Running your own benchmarks](experiments/README.md#running-your-own-benchmarks) in the README of the experiments. That README also describes how the experiments can be configured and run individually, and how to set up the host for stable timings.

## Parallel execution
With the option `-p`, `scripts/2_smoke.sh` and `scripts/3_run.sh` run as many runs at the same time as fit into the machine, e.g. `scripts/3_run.sh representative -p`. Every run is still pinned to its own physical cores and limited in memory, and one physical core and 1 GiB of memory stay free for the system. At the start of every experiment, the output shows how many runs fit (`fitting jobs: ...`) and how many run at a time (`jobs: ...`).

Every run gets 2 physical cores and 8 GiB of memory in the minimal experiments, 4 physical cores and 16 GiB in the representative experiments, and 4 physical cores and 32 GiB in the full experiments; the smoke test for a set uses the same. Running several at the same time needs these for every run, plus one physical core and 1 GiB:

| Runs at a time | Minimal         | Representative   | Full              |
| -------------- | --------------- | ---------------- | ----------------- |
| 1              | 3 cores, 9 GiB  | 5 cores, 17 GiB  | 5 cores, 33 GiB   |
| 2              | 5 cores, 17 GiB | 9 cores, 33 GiB  | 9 cores, 65 GiB   |
| 3              | 7 cores, 25 GiB | 13 cores, 49 GiB | 13 cores, 97 GiB  |
| 4              | 9 cores, 33 GiB | 17 cores, 65 GiB | 17 cores, 129 GiB |

and so on, with the cores and memory of one more run for every further run. Only physical cores count: the second hardware thread of a core (hyperthreading) stays idle. The memory is the total memory that Linux reports in `/proc/meminfo`, which is somewhat less than the installed memory; on macOS, the cores and memory are those given to the virtual machine of Docker Desktop.

For timings that are as stable as possible follow [Additional setup](experiments/README.md#additional-setup).

## Differences between Storm 2.0 and the Storm used for the paper
The experiments in the submitted paper were done on a beta version of Storm 2.0, commit [`276d4fe0a5`](https://github.com/stormchecker/storm/commit/276d4fe0a56ee61952e4d5e04ce5f69c19f216eb) of the Storm repository (13 October 2026), which reports itself as version `1.14.0 (dev)` in the logs. In this artifact we provide the stable release of Storm and Stormpy 2.0. None of the changes between the beta and the stable release affects performance significantly. The results of the full experiments with the stable release are in `$ARTIFACT_DIR/results/artifact/full/`, with their figures in `$ARTIFACT_DIR/results/artifact/full.pdf`, and we will replace all figures in the paper with these results.

## License
Storm is licensed under the license located at `storm/LICENSE`, Stormpy under the license located at `stormpy/LICENSE`, and the notebooks under the license located at `notebooks/LICENSE` (all GPL-3.0).
The Modest Toolset is licensed under the license located at `experiments/docker/modest/License.txt` (also `Modest/License.txt` in the zips in that folder), which permits its redistribution as part of this artifact.
All other contents are licensed under the [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) license, see `LICENSE`.

## The artifact
### Contents

| Path | Description |
| --- | --- |
| `scripts/` | The scripts of the steps of this README: `1_load.sh` loads the images, `2_smoke.sh SET` runs the smoke test for a set and `3_run.sh SET` the set itself, both in a container through `experiments/docker/run_in_container.sh`, and `4_figures.sh DIR` creates the figures from the logs in `DIR`; `5_build_docker.sh` builds and saves the images, and `6_create_artifact.sh` creates the artifact |
| `results/` | `paper/` the logs, results and figure data of the runs in the paper (see [results/paper/README.md](results/paper/README.md)), and `artifact/` the pdf, logs and results of sample runs of the smoke tests of all three sets and of `scripts/3_run.sh` for all three sets |
| `experiments/` | The experiments and the Docker image they run in; see [experiments/README.md](experiments/README.md) |
| `experiments/storm2-experiments.tar.gz` | The saved Docker images `storm2-experiments` and `storm2-tools`, for amd64 and arm64, loaded by `scripts/1_load.sh` |
| `examples/` | Example files: `vacuum/` the robot vacuum example of the paper (Sec. 7), and `mdp_benchmarks/` and `pomdp_benchmarks/` the models and properties of the MDP and POMDP benchmarks of the experiments; see [TOOLS.md](TOOLS.md) |
| `TOOLS.md` | A short description of Storm and Stormpy and how to play with them on the examples |
| `ARTIFACT.md` | How to build the Docker images and the artifact |
| `notebooks/` | Jupyter notebooks of the Storm tutorial on the Orchard game for Stormpy 2.0, a copy of `tutorial_orchard/` of the [stormpyter repository](https://github.com/stormchecker/stormpyter/tree/306df8b/tutorial_orchard) (commit `306df8b` of `master`), whose `Dockerfile` is changed to build the image `storm2-tools` on the Stormpy 2.0 image |
| `storm/` | The source code of Storm 2.0.0, a submodule of the [Storm repository](https://github.com/stormchecker/storm) at its tag `2.0.0` |
| `stormpy/` | The source code of Stormpy 2.0.0, a submodule of the [Stormpy repository](https://github.com/stormchecker/stormpy) at its tag `2.0.0` |
| `LICENSE` | The license of the artifact (CC-BY 4.0) |

### Building the Docker images and the artifact
[ARTIFACT.md](ARTIFACT.md) describes how to build the Docker images with `scripts/5_build_docker.sh`, also with other versions of the tools such as a Storm of your own, and how to create the artifact with `scripts/6_create_artifact.sh`.
