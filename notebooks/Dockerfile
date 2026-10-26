# Build with 
# docker build -t tutorial .
# Run with
# docker run -it -p 8888:8888 tutorial

FROM quay.io/jupyter/minimal-notebook:ubuntu-26.04

# Install graphviz for plotting decision trees with PAYNT
USER root
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    graphviz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
USER ${NB_UID}

# Install Python libraries from requirements.txt
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/
RUN pip install --no-cache-dir --requirement /tmp/requirements.txt && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

COPY --chown=${NB_UID}:${NB_GID} . .
