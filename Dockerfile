# Use CUDA 11.8 base image which is compatible with PyTorch 2.1.0
# Specify platform to avoid building an ARM container on mac hosts
#FROM --platform=linux/amd64 pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime
FROM --platform=linux/amd64 pytorch/pytorch:2.4.1-cuda12.4-cudnn9-devel AS base
# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends  \
      git  \
#     clang \
#     build-essential \
#     python3-dev \
#     make \
#     cmake \
&& rm -rf /var/lib/apt/lists/*

#  RUN git clone --recurse-submodules https://github.com/dmlc/dgl.git
#  WORKDIR dgl
#  ENV DGL_HOME=$PWD
#  RUN script/build_dgl.sh -g
#  
#  WORKDIR python
#  RUN python setup.py install
#  # Build Cython extension
#  RUN python setup.py build_ext --inplace

COPY --from=ghcr.io/astral-sh/uv:0.6.9 /uv /uvx /bin/
RUN uv --version

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Install the project's dependencies using the lockfile and settings
COPY pyproject.toml ./

RUN uv venv --system-site-packages

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
ADD . .
RUN uv sync


RUN uv pip install dgl -f https://data.dgl.ai/wheels/torch-2.4/cu124/repo.html
# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

