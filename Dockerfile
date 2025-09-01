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
    petsc-dev \
    libmesh-dev \
    cuda-toolkit \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory for the source code.
WORKDIR /app

# Opendis Installation
COPY . .
