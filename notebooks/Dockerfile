# Jupyter environment for the notebooks, based on the official Stormpy 2.0 image,
# which also contains the command-line tools of Storm 2.0. The artifact ships it
# prebuilt as storm2-tools, see scripts/4_build_docker.sh. Build with
# docker build -t storm2-tools .
# Run with
# docker run -it -p 8888:8888 storm2-tools

FROM movesrwth/stormpy:2.0.0

# Install graphviz for plotting decision trees with PAYNT
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter and the Python libraries from requirements.txt into the virtual
# environment of Stormpy, which already has Stormpy 2.0.0
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir jupyterlab==4.6.4 --requirement /tmp/requirements.txt

WORKDIR /opt/notebooks
COPY . .
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
