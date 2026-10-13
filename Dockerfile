# Dockerfile for the Storm 2 experiments
#########################################
# Based on the stormpy image, which contains Storm and stormpy in the virtual
# environment /opt/venv. The Docker image can be built by executing:
# docker build -t storm2-experiments .
# A different stormpy base image can be set from the commandline with:
# --build-arg STORMPY_BASE=<new_base_image>
# See the README for how to run the experiments in the container.

# Set stormpy base image
ARG STORMPY_BASE=movesrwth/stormpy:1.14.0
FROM $STORMPY_BASE


# Configuration arguments
#########################
# The arguments can be set from the commandline with:
# --build-arg <arg_name>=<value>

# Versions of the other tools
ARG prism_version=4.10.1
ARG julia_version=1.13.0
ARG modest_version=v3.1.314-g51abd2d6a


# Install dependencies
######################
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
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
RUN curl -fsSL -o modest.zip https://www.modestchecker.net/downloads/Modest-Toolset-$modest_version-linux-x64.zip \
    && unzip -q modest.zip && rm modest.zip


# Set-up the experiments
########################
WORKDIR /opt/storm2-experiments
COPY . .
RUN pip install -r requirements.txt

# Link the tools to where the experiments expect them. The Storm release images
# install Storm in /usr/local, an image built from Storm's Dockerfile in /opt/storm.
RUN storm=$(command -v storm || echo /opt/storm/build/bin/storm) \
    && for experiment in comparison_tools_bisim imdps; do \
        mkdir -p $experiment/bin \
        && ln -s $storm /opt/prism/bin/prism $experiment/bin/; \
    done \
    && ln -s /opt/Modest/modest comparison_tools_bisim/bin/modest \
    && ln -s /opt/julia/bin/julia imdps/bin/julia

# Install IntervalMDP.jl and build its sysimage. With Julia 1.13, PackageCompiler
# compiles it for the CPU targets of Julia's own sysimage rather than for the CPU
# of the machine building the image, so that the image runs on other machines too.
# The packages go to a depot outside of $HOME, as BenchExec runs every invocation
# with a fresh $HOME; the trailing colon keeps Julia's bundled depots.
ENV JULIA_DEPOT_PATH=/opt/julia-depot:
WORKDIR /opt/storm2-experiments/imdps
RUN bin/julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()' \
    && bin/julia julia/build_sysimage.jl

# Set up cgroups for BenchExec (run.py --jobs), see docker/init.sh
WORKDIR /opt/storm2-experiments
ENTRYPOINT ["/opt/storm2-experiments/docker/init.sh"]
CMD ["bash"]
