# Building the Docker images and the artifact

This file describes how the Docker images and the artifact itself are made. Running the artifact does not need any of this; see the [README](README.md).

## Building the docker
- Execute `scripts/4_build_docker.sh`. This builds the image `storm2-experiments` of `experiments/Dockerfile` and the image `storm2-tools` of `notebooks/Dockerfile` (see [TOOLS.md](TOOLS.md)) for amd64 and arm64, loads them into Docker and saves both to `experiments/storm2-experiments.tar.gz` (`-o FILE` for another file).
- With `PLATFORMS=linux/amd64 scripts/4_build_docker.sh`, the images are built for one architecture only. Other options are passed on to `docker buildx build` of `storm2-experiments`.
- Building for an architecture other than that of the machine needs QEMU (`docker run --privileged --rm tonistiigi/binfmt --install arm64`) and takes much longer, mostly for the Julia sysimage.

The build needs network access and about 100 GB of free disk space for Docker, plus the space of the saved file. The interval MDPs of the `imdp` experiment come with the artifact in `experiments/imdp/benchmarks.tar.xz`, which `scripts/4_build_docker.sh` unpacks; the build only generates those that are missing, which takes a few hours and tens of GB of memory for the largest models (`--build-arg generate_workers=N` sets how many are generated at once, default: 2). The Modest Toolset website only offers its latest version, so the zips of the version used are kept in `experiments/docker/modest/` and checked against `experiments/docker/modest/SHA256SUMS`.

Build arguments select other versions of the tools: `STORM_BASE` another Storm image (default: `movesrwth/storm:2.0.0`), `STORM_OLD_BASE` the old Storm to compare with (default: `movesrwth/storm:1.6.2`), `STORMPY_BASE` the Stormpy that generates the interval MDPs (default: `movesrwth/stormpy:2.0.0`), and `prism_version` and `julia_version`. To run a Storm of your own in the experiments, e.g. that of `storm/`, build it with Storm's Dockerfile and pass it as `STORM_BASE`:

```bash
docker build -t storm:local --build-arg no_threads=8 storm
scripts/4_build_docker.sh --build-arg STORM_BASE=storm:local
```

The Julia sysimage of IntervalMDP.jl is compiled for the CPU targets of Julia itself, so the image runs on other CPUs than the one that built it.

## Building the artifact
Building the artifact needs the git repository it is built from, [github.com/lukovdm/storm2-experiments](https://github.com/lukovdm/storm2-experiments), with the submodules `storm/` and `stormpy/` checked out:

```bash
git clone --recurse-submodules https://github.com/lukovdm/storm2-experiments.git
```

or `git submodule update --init` in an existing clone.

- Commit all changes, as the artifact only contains the committed files of the repository and its submodules.
- Build, load and save the images with `scripts/4_build_docker.sh` (see [Building the docker](#building-the-docker)), after the last commit. It writes both images to `experiments/storm2-experiments.tar.gz`.
- Update the sample runs in `results/artifact/` with these images: move the old sample runs away, execute `../../scripts/2_smoke.sh minimal`, `../../scripts/2_smoke.sh representative`, `../../scripts/2_smoke.sh full`, `../../scripts/3_minimal.sh`, `../../scripts/3_representative.sh` and `../../scripts/3_full.sh` in `results/artifact/`, and commit the new ones. `results/` is not part of the images, so this does not require rebuilding them.
- Execute `scripts/5_create_artifact.sh`. This writes `storm2-artifact.zip` to the current directory (or the file given as its argument), with the committed files of the repository and of `storm/` and `stormpy/`, the saved images, the zips of the Modest Toolset and `experiments/imdp/benchmarks.tar.xz`, all below `storm2-artifact/`.

`scripts/5_create_artifact.sh` refuses to create the artifact when there are uncommitted changes, when a submodule is not checked out at its committed commit, when one of these files is missing, or when the saved images are older than the last commit that changed `experiments/`, `examples/` or `notebooks/`.
