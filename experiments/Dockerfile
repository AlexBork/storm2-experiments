# check=skip=FromPlatformFlagConstDisallowed
# Dockerfile for the Storm 2 experiments
#########################################
# Build with ../scripts/5_build_docker.sh, or with
#   docker buildx build --build-context mdp_benchmarks=../examples/mdp_benchmarks \
#       --build-context pomdp_benchmarks=../examples/pomdp_benchmarks -t storm2-experiments .
# The models of mdp and pomdp, benchmarks/models/ of each, are
# links to ../examples/, which is outside of the build context, so they are passed
# as named build contexts.
# See the README for the build arguments and how to run the experiments.

# Set the base images
ARG STORM_BASE=movesrwth/storm:2.0.0
ARG STORMPY_BASE=movesrwth/stormpy:2.0.0
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


# Generate the interval MDPs of imdp
#####################################
# Only the missing ones, which takes hours for all of them, once on the building
# machine for all architectures; models not in its index.json are dropped
FROM --platform=$BUILDPLATFORM $STORMPY_BASE AS imdp-models
# Models generated in parallel; the largest need tens of GB of memory each
ARG generate_workers=2
WORKDIR /opt/storm2-experiments
COPY --exclude=models mdp/benchmarks mdp/benchmarks
COPY --from=mdp_benchmarks . mdp/benchmarks/models
COPY imdp/generate imdp/generate
COPY imdp/benchmarks imdp/benchmarks
RUN cd imdp && python3 generate/generate_explicit_benchmarks.py \
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
WORKDIR /opt/storm2-experiments/imdp
COPY imdp/julia julia
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
COPY --from=imdp-models /opt/storm2-experiments/imdp/benchmarks imdp/benchmarks
COPY --from=mdp_benchmarks . mdp/benchmarks/models
COPY --from=pomdp_benchmarks . pomdp/benchmarks/models
COPY --exclude=imdp/benchmarks --exclude=docker/modest \
     --exclude=mdp/benchmarks/models \
     --exclude=pomdp/benchmarks/models . .

# Link the tools into the bin/ directories of the experiments; release images have
# Storm in /usr/local, images built from Storm's Dockerfile in /opt/storm
RUN storm=$(command -v storm || echo /opt/storm/build/bin/storm) \
    && for experiment in mdp imdp; do \
        mkdir -p $experiment/bin \
        && ln -s $storm /opt/prism/bin/prism $experiment/bin/; \
    done \
    && ln -s /opt/Modest/modest mdp/bin/modest \
    && ln -s /opt/storm2-experiments/docker/storm-old mdp/bin/storm-old \
    && ln -s /opt/julia/bin/julia imdp/bin/julia \
    && mkdir -p pomdp/bin && ln -s $(dirname $storm)/storm-pomdp pomdp/bin/

# Sets up the cgroups for BenchExec, see docker/init.sh
ENTRYPOINT ["/opt/storm2-experiments/docker/init.sh"]
CMD ["bash"]
