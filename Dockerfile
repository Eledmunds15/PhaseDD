# Build command
# docker build -t phasedd:latest .

# Build command for debug (with log file)
# docker build -t phasedd:latest . > build.log 2>&1

# Build command for debug (removing cache and log file)
# docker build --no-cache -t phasedd:latest . > build.log 2>&1

# Run command
# docker run --rm -it --gpus all phasedd:latest

# Identify base image
FROM nvidia/cuda:12.5.1-devel-ubuntu24.04 AS builder

# Set environment variables for non-interactive installs.
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install necessary build dependencies.
# This includes cmake, g++, openmpi, and python3 tools.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gfortran \
    git \
    wget \
    curl \
    python3 \
    python3-dev \
    python3-pip \
    python3-numpy \
    python3-scipy \
    libopenmpi-dev \
    openmpi-bin \
    libhdf5-dev \
    libblas-dev \
    liblapack-dev \
    libfftw3-dev \
    libboost-all-dev \
    libhypre-dev \
    libtirpc-dev \
    flex \
    bison \
    cuda-toolkit \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory for the source code.
WORKDIR /app

# Copy Externals
COPY /external /app/external

# Install OpenDis
WORKDIR /app/external/opendis

RUN rm -rf build/; ./configure.sh -DSYS=ubuntu && \
    cmake --build build -j $(nproc); cmake --build build --target install

# Install MOOSE dependencies
WORKDIR /app/external/moose/scripts
RUN ./update_and_rebuild_petsc.sh
RUN ./update_and_rebuild_libmesh.sh

# Install system packages needed for venv
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-venv \
        python3-pip \
        python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the virtual environment
RUN python3 -m venv /opt/venv

# Install Python packages inside the venv
RUN /opt/venv/bin/pip install --no-cache-dir pyyaml packaging

# Add venv to PATH for all future steps
ENV PATH="/opt/venv/bin:$PATH"

RUN ./update_and_rebuild_wasp.sh

# Install MOOSE
WORKDIR /app/external/moose/test

RUN make -j 6

RUN /opt/venv/bin/pip install --no-cache-dir numpy pandas

RUN ./run_tests -j 6

