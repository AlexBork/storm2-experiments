# check=skip=FromPlatformFlagConstDisallowed
# Dockerfile for the Storm 2 experiments
#########################################
# Build with: docker build -t storm2-experiments .
# See the README for the build arguments and how to run the experiments.

# Set the base images
ARG STORM_BASE=movesrwth/storm:2.0.0
ARG STORMPY_BASE=movesrwth/stormpy:1.14.0
ARG STORM_OLD_BASE=movesrwth/storm:1.6.2


# Collect an old Storm to compare with
######################################
# The binary and its libraries, run by docker/storm-old; Storm 1.6.2 only exists
# for amd64, so arm64 images cannot run it
FROM --platform=linux/amd64 $STORM_OLD_BASE AS storm-old
RUN mkdir -p /opt/storm-old/lib \
    && cp /opt/storm/build/bin/storm /opt/storm-old/ \
    && ldd /opt/storm-old/storm | awk '$2 == "=>" && $3 ~ /^\// {print $3}' \
        | grep -vE '/(libc|libm|libdl|libpthread|librt|libstdc\+\+|libgcc_s)\.so' \
        | xargs -I{} cp -L {} /opt/storm-old/lib/ \
    && /opt/storm-old/storm --version | head -1


# Generate the interval MDPs of imdps
#####################################
# Only the missing ones, which takes hours for all of them, once on the building
# machine for all architectures; models not in its index.json are dropped
FROM --platform=$BUILDPLATFORM $STORMPY_BASE AS imdps-models
# Models generated in parallel; the largest need tens of GB of memory each
ARG generate_workers=2
WORKDIR /opt/storm2-experiments
COPY mdp_benchmarks mdp_benchmarks
COPY experiments/comparison_tools_bisim/benchmarks experiments/comparison_tools_bisim/benchmarks
COPY experiments/imdps/generate experiments/imdps/generate
COPY experiments/imdps/benchmarks experiments/imdps/benchmarks
RUN cd experiments/imdps && python3 generate/generate_explicit_benchmarks.py \
        --skip-existing --workers $generate_workers --no-keep-going \
    && python3 -c 'import json, pathlib; \
root = pathlib.Path("benchmarks"); \
keep = {f for b in json.load(open(root / "index.json")).values() for f in root.glob(b["bundle"] + ".*")}; \
[f.unlink() for f in root.glob("*/*") if f not in keep]'


FROM $STORM_BASE


# Configuration arguments
#########################
ARG prism_version=4.10.1
ARG julia_version=1.13.0
# Set by BuildKit, e.g. amd64 or arm64
ARG TARGETARCH


# Install dependencies
######################
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    default-jre-headless \
    curl \
    unzip \
    latexmk \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-pictures


# Install the other tools
#########################
# The Modest Toolset comes from docker/modest/, see its README
WORKDIR /opt
RUN arch=$([ "$TARGETARCH" = arm64 ] && echo arm || echo x86) \
    && curl -fsSL https://www.prismmodelchecker.org/dl/prism-$prism_version-linux64-$arch.tar.gz | tar xz \
    && mv prism-$prism_version-linux64-$arch prism \
    && cd prism && ./install.sh
RUN set -- $([ "$TARGETARCH" = arm64 ] && echo aarch64 aarch64 || echo x64 x86_64) \
    && curl -fsSL https://julialang-s3.julialang.net/bin/linux/$1/${julia_version%.*}/julia-$julia_version-linux-$2.tar.gz | tar xz \
    && mv julia-$julia_version julia
COPY docker/modest/$TARGETARCH/Modest /opt/Modest
COPY --from=storm-old /opt/storm-old /opt/storm-old

# IntervalMDP.jl and its sysimage, before the rest of the repository so that it is
# rarely rebuilt; the depot is outside $HOME, which BenchExec replaces
ENV JULIA_DEPOT_PATH=/opt/julia-depot:
WORKDIR /opt/storm2-experiments/experiments/imdps
COPY experiments/imdps/julia julia
RUN /opt/julia/bin/julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()' \
    && /opt/julia/bin/julia julia/build_sysimage.jl


# Set-up the experiments
########################
# The scripts need BenchExec; the interval MDPs are copied before the repository,
# so that a change in it does not export their gigabytes again
WORKDIR /opt/storm2-experiments
ENV PATH=/opt/venv/bin:$PATH
COPY requirements.txt .
RUN python3 -m venv /opt/venv && pip install -r requirements.txt
COPY --from=imdps-models /opt/storm2-experiments/experiments/imdps/benchmarks experiments/imdps/benchmarks
COPY --exclude=experiments/imdps/benchmarks --exclude=docker/modest . .

# Link the tools into the bin/ directories of the experiments; release images have
# Storm in /usr/local, images built from Storm's Dockerfile in /opt/storm
RUN storm=$(command -v storm || echo /opt/storm/build/bin/storm) \
    && cd experiments \
    && for experiment in comparison_tools_bisim imdps; do \
        mkdir -p $experiment/bin \
        && ln -s $storm /opt/prism/bin/prism $experiment/bin/; \
    done \
    && ln -s /opt/Modest/modest comparison_tools_bisim/bin/modest \
    && ln -s /opt/storm2-experiments/docker/storm-old comparison_tools_bisim/bin/storm-old \
    && ln -s /opt/julia/bin/julia imdps/bin/julia \
    && mkdir -p pomdp/bin && ln -s $(dirname $storm)/storm-pomdp pomdp/bin/

# Sets up the cgroups for BenchExec, see docker/init.sh
ENTRYPOINT ["/opt/storm2-experiments/docker/init.sh"]
CMD ["bash"]
