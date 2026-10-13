# Dockerfile for the Storm 2 experiments
#########################################
# The experiments run the Storm of a Storm image, e.g. one built from a local Storm
# with its own Dockerfile. Only the generation of the interval MDPs of imdps needs
# stormpy, and is done in a stage based on the stormpy image. The Docker image can
# be built by executing:
# docker build -t storm:local ../storm
# docker build -t storm2-experiments .
# Different base images can be set from the commandline with:
# --build-arg STORM_BASE=<storm_image> --build-arg STORMPY_BASE=<stormpy_image>
# See the README for how to run the experiments in the container.

# Set the base images
ARG STORM_BASE=storm:local
ARG STORMPY_BASE=movesrwth/stormpy:1.14.0


# Generate the interval MDPs of imdps
#####################################
# In a stage of their own, which only copies the generator, the MDP benchmarks it
# reads and the models already generated in imdps/benchmarks/. Only the missing
# models are generated, which takes hours for all of them; the generation stops at
# the first benchmark that fails, so that no model is missing from the image.
# Models in imdps/benchmarks/ that are not in its index.json are left out.
FROM $STORMPY_BASE AS imdps-models
# Number of interval MDPs generated in parallel; the largest ones need tens of GB
# of memory each
ARG generate_workers=2
WORKDIR /opt/storm2-experiments
COPY benchmarks benchmarks
COPY imdps/generate imdps/generate
COPY imdps/benchmarks imdps/benchmarks
RUN cd imdps && python3 generate/generate_explicit_benchmarks.py \
        --skip-existing --workers $generate_workers --no-keep-going \
    && python3 -c 'import json, pathlib; \
root = pathlib.Path("benchmarks"); \
keep = {f for b in json.load(open(root / "index.json")).values() for f in root.glob(b["bundle"] + ".*")}; \
[f.unlink() for f in root.glob("*/*") if f not in keep]'


FROM $STORM_BASE


# Configuration arguments
#########################
# The arguments can be set from the commandline with:
# --build-arg <arg_name>=<value>

# Versions of the other tools
ARG prism_version=4.10.1
ARG julia_version=1.13.0
# The Modest Toolset website only offers its latest version, which is used when
# modest_version is empty; set it to e.g. v3.1.315-g0a0763b35 for a specific one
ARG modest_version=""


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
WORKDIR /opt
RUN curl -fsSL https://www.prismmodelchecker.org/dl/prism-$prism_version-linux64-x86.tar.gz | tar xz \
    && mv prism-$prism_version-linux64-x86 prism \
    && cd prism && ./install.sh
RUN curl -fsSL https://julialang-s3.julialang.net/bin/linux/x64/${julia_version%.*}/julia-$julia_version-linux-x86_64.tar.gz | tar xz \
    && mv julia-$julia_version julia
RUN downloads=https://www.modestchecker.net/downloads/ \
    && zip=${modest_version:+Modest-Toolset-$modest_version-linux-x64.zip} \
    && zip=${zip:-$(curl -fsSL $downloads | grep -oE 'Modest-Toolset-[^"]*-linux-x64\.zip' | head -1)} \
    && echo "Modest Toolset: $zip" \
    && curl -fsSL -o modest.zip $downloads$zip \
    && unzip -q modest.zip && rm modest.zip

# Install IntervalMDP.jl and build its sysimage. With Julia 1.13, PackageCompiler
# compiles it for the CPU targets of Julia's own sysimage rather than for the CPU
# of the machine building the image, so that the image runs on other machines too.
# The packages go to a depot outside of $HOME, as BenchExec runs every invocation
# with a fresh $HOME; the trailing colon keeps Julia's bundled depots. Only the
# Julia environment is copied here, so that changes elsewhere in the repository do
# not rebuild the sysimage.
ENV JULIA_DEPOT_PATH=/opt/julia-depot:
WORKDIR /opt/storm2-experiments/imdps
COPY imdps/julia julia
RUN /opt/julia/bin/julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()' \
    && /opt/julia/bin/julia julia/build_sysimage.jl


# Set-up the experiments
########################
WORKDIR /opt/storm2-experiments
# The scripts only need BenchExec besides Python itself
ENV PATH=/opt/venv/bin:$PATH
COPY requirements.txt .
RUN python3 -m venv /opt/venv && pip install -r requirements.txt
# The interval MDPs come from the stage above, together with their index.json.
COPY --exclude=imdps/benchmarks . .
COPY --from=imdps-models /opt/storm2-experiments/imdps/benchmarks imdps/benchmarks

# Link the tools to where the experiments expect them. The Storm release images
# install Storm in /usr/local, an image built from Storm's Dockerfile in /opt/storm.
RUN storm=$(command -v storm || echo /opt/storm/build/bin/storm) \
    && for experiment in comparison_tools_bisim imdps; do \
        mkdir -p $experiment/bin \
        && ln -s $storm /opt/prism/bin/prism $experiment/bin/; \
    done \
    && ln -s /opt/Modest/modest comparison_tools_bisim/bin/modest \
    && ln -s /opt/julia/bin/julia imdps/bin/julia \
    && mkdir -p pomdp/bin && ln -s $(dirname $storm)/storm-pomdp pomdp/bin/

# Set up cgroups for BenchExec (run.py --jobs), see docker/init.sh
ENTRYPOINT ["/opt/storm2-experiments/docker/init.sh"]
CMD ["bash"]
