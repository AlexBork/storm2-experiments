# Experimental evaluation for: "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

Experimental evaluation for the tool paper "The Probabilistic Model Checker Storm: Lightning Strikes Twice". This artifact reproduces the figures 6, 7, 8, and 9.

All experiments are meant to be run in the docker container provided. This README contains instructions for loading this container, and running a smoke, representative and full experiment set. The descriptions of how all experiments can be configured and run individually, and of how to build the container, are in [experiments/README.md](experiments/README.md). Lastly, this README details how to build this artifact.

## License

Storm is licensed under the license located at `storm/LICENSE`, stormpy under the license located at `stormpy/LICENSE`, and the notebooks under the license located at `notebooks/LICENSE` (all GPL-3.0).
The Modest Toolset is licensed under the license located at `Modest/License.txt` in the zips in `experiments/docker/modest/`.
All other contents are licensed under the [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) license, see `LICENSE`.

## Host requirements
This artifact was built for both x86 (amd64) and ARM (arm64) based Linux and macOS hosts. However, **Storm 1.6.2 is not supported on ARM based CPUs**, so its runs end with an error on these hosts and show up as errors in the results. We tested the artifact on amd64 hosts running Linux (Debian forky/sid with Linux 6.18 and Docker 29.4 with the containerd image store); arm64 and macOS hosts were not tested.

The hardware needed and the running time depend on the experiment set. Every run gets a fixed number of physical cores and a memory limit, and one more physical core and 1 GiB of memory stay free for the system. By default, all runs are done one after the other. With the option `-p`, the scripts run as many at the same time as fit into the machine; see [Parallel execution](#parallel-execution) for the hardware this needs.

| Experiment set | Script | Per run | Hardware needed | Estimated time | Estimated time with 4 runs at a time ([Parallel execution](#parallel-execution)) |
| --- | --- | --- | --- | --- | --- |
| Smoke test | `scripts/2_smoke.sh` | 4 cores, 16 GiB, 60 s | 5 cores, 17 GiB | 8 minutes | 3 minutes (17 cores, 65 GiB) |
| Representative | `scripts/3_representative.sh` | 4 cores, 16 GiB, 90 s | 5 cores, 17 GiB | x hours | y hours (17 cores, 65 GiB) |
| Minimal | `scripts/3_minimal.sh` | 2 cores, 8 GiB, 90 s | 3 cores, 9 GiB | x hours | y hours (9 cores, 33 GiB) |
| Full | `scripts/3_full.sh` | 4 cores, 32 GiB, 900 s | 5 cores, 33 GiB | 70 hours | 18 hours (17 cores, 129 GiB) |

The cores are physical cores; the second hardware thread of a core (hyperthreading) is not used. The memory is the total memory that Linux reports in `/proc/meminfo`, which is somewhat less than the installed memory. On macOS and Windows, the cores and memory are those given to the virtual machine of Docker Desktop, which can be set under Settings → Resources. The container also needs **50 GB of free disk space** when loaded into docker. No network access is needed to run the experiments.

To achieve fully stable experimental results additional configurations on the host machine need to be done as detailed in [Additional setup](experiments/README.md#additional-setup).

## Loading the container
- Install [Docker](https://docs.docker.com/get-started/get-docker/).
- In the Docker settings, ensure that the `Use containerd for pulling and storing images` option is enabled. This is necessary to support the provided [multi-platform image](https://docs.docker.com/build/building/multi-platform/).
- Download the file `storm2-experiments-artifact.zip` from [Zenodo](https://doi.org/10.5281/zenodo.23668956) and unzip it at a convenient location. Throughout this document, `$ARTIFACT_DIR` refers to the path leading to the unzipped directory, i.e., a copy of this Readme is located at `$ARTIFACT_DIR/README.md`.
- Execute `$ARTIFACT_DIR/scripts/1_load.sh`. This will load the docker file.

We run the docker with additional options `--privileged --cap-drop=all`. These let the experiment runner pin experiments to cores and enforce memory limits. All other privileges are dropped.

## Running the smoke test
- Execute `$ARTIFACT_DIR/scripts/2_smoke.sh`. This should take around 8 minutes, and around 3 minutes with `scripts/2_smoke.sh -p` on a machine that fits 4 runs at a time (see [Parallel execution](#parallel-execution)).
- Check that the output ends with `== all results checked`, followed by where the results are. If a run gave an incorrect result or none at all, it ends with `== results with problems in:` and the experiments concerned instead, and the problems are listed above it.
- A pdf `smoke.pdf`, containing the figures and the results with logs in `smoke/` are placed in the current directory.
- Inspect the produced `smoke.pdf` in your current directory. It should contain the 4 figures from the paper, with only one point in each scatter plot and the curves of one model in Figure 9.

If you encounter issues with the smoke test please provide a zip of the pdf and the results directory together with a description of your issues.

We provide a pdf and the results of a sample run in the folder `$ARTIFACT_DIR/results/artifact/smoke/`.

The smoketest will run every configuration of every experiment on one small benchmark with a time limit of 60 seconds. Then it follows the normal post processing and plot generation procedures as the representative and full experiments.

## Running the representative experiments
- Execute `$ARTIFACT_DIR/scripts/3_representative.sh`. This should take x minutes, and y minutes with `scripts/3_representative.sh -p` on a machine that fits 4 runs at a time (see [Parallel execution](#parallel-execution)).
- Figures 6, 7, 8, and 9 will be given in `representative.pdf` in your current directory.
- The data and logs can be inspected in the folder `representative/` in your current directory.

We provide a pdf and the results of a sample run in the folder `$ARTIFACT_DIR/results/artifact/representative/`.

The representative experiments contain a subset of the benchmarks and have lower resource requirements. The benchmarks were chosen such that the results produced are representative for the full benchmark set with the full hardware requirements.

The minimal experiments, `$ARTIFACT_DIR/scripts/3_minimal.sh`, run the same benchmarks with 2 instead of 4 physical cores and 8 instead of 16 GiB of memory per run, for machines that are too small for the representative experiments (see [Host requirements](#host-requirements)). They give the figures in `minimal.pdf` and the data and logs in `minimal/` in your current directory. Storm's symbolic engines then use 2 instead of 4 threads, PRISM gets 8 GiB for Java, and the decision diagram libraries of both (Sylvan and CUDD) get 4 instead of 8 GiB, so more runs time out or run out of memory and the results deviate more from the paper.

## Running the full experiments
- Execute `$ARTIFACT_DIR/scripts/3_full.sh`. This should take around 70 hours (requiring 33 GiB of memory), and around 18 hours with `scripts/3_full.sh -p` on a machine that fits 4 runs at a time (requiring 17 physical cores and 129 GiB of memory, see [Parallel execution](#parallel-execution)).
- Figures 6, 7, 8, and 9 will be given in `full.pdf` in your current directory.
- The data and logs can be inspected in the folder `full/` in your current directory.

We provide the logs, results and figure data of the runs shown in the paper in the folder `$ARTIFACT_DIR/results/paper/`, see [results/paper/README.md](results/paper/README.md).

The full experiments run every configuration of every experiment on all benchmarks with a time limit of 900 seconds and a memory limit of 32 GiB per run, as in the paper. These are 1759 runs: 957 of `mdp`, 156 of `imdp` and 646 of `pomdp`. The estimated running times are the sum of the runtimes of the runs in the paper; if every run timed out, it would take 440 hours on the minimum requirements.

The container runs in the background, so the experiments go on when the terminal is closed. Executing `scripts/3_full.sh` again in the same directory waits for them to finish and then copies the results. To abort the experiments, execute `docker rm -f storm2-full`, which also removes the logs of the finished runs; there is no resuming. The same holds for the smoke test and the representative experiments, with the containers `storm2-smoke` and `storm2-representative`.

## Difference storm 2.0 and storm used for included paper.
*Fill in*

## The artifact
### Contents

| Path | Description |
| --- | --- |
| `scripts/` | The scripts to run, in the order of this README: `1_load.sh` loads the image, `2_smoke.sh`, `3_representative.sh`, `3_minimal.sh` and `3_full.sh` run the experiment sets in a container (all four through `experiments/docker/run_in_container.sh`), and `5_create_artifact.sh` creates the artifact |
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
With the option `-p`, `scripts/2_smoke.sh`, `scripts/3_representative.sh`, `scripts/3_minimal.sh` and `scripts/3_full.sh` run as many runs at the same time as fit into the machine, e.g. `scripts/3_representative.sh -p`. Every run is still pinned to its own physical cores and limited in memory, and one physical core and 1 GiB of memory stay free for the system. At the start of every experiment, the output shows how many runs fit (`fitting jobs: ...`) and how many run at a time (`jobs: ...`).

Running several at the same time needs the cores and memory per run of the experiment set (see the table in [Host requirements](#host-requirements)) for every run, plus one physical core and 1 GiB:

| Runs at a time | Smoke, representative | Minimal | Full |
| --- | --- | --- | --- |
| 1 | 5 cores, 17 GiB | 3 cores, 9 GiB | 5 cores, 33 GiB |
| 2 | 9 cores, 33 GiB | 5 cores, 17 GiB | 9 cores, 65 GiB |
| 3 | 13 cores, 49 GiB | 7 cores, 25 GiB | 13 cores, 97 GiB |
| 4 | 17 cores, 65 GiB | 9 cores, 33 GiB | 17 cores, 129 GiB |

and so on, with the cores and memory of one more run for every further run.

Runs at the same time share the memory bandwidth and caches of the CPU, so they can take somewhat longer than when run one at a time. For timings that are as stable as possible, run without `-p` and follow [Additional setup](experiments/README.md#additional-setup).
