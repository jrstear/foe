# Use SchedMD Slurm Worker as base (back to Ubuntu 24.04 for better dependency parity)
FROM ghcr.io/slinkyproject/slurmd:25.11-ubuntu24.04

USER root

# Install Flux Framework Build Dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libzmq3-dev \
    libczmq-dev \
    libjansson-dev \
    libmunge-dev \
    libssl-dev \
    lua5.2 \
    liblua5.2-dev \
    lua-posix \
    lua-posix-dev \
    libsqlite3-dev \
    libhwloc-dev \
    libarchive-dev \
    libsodium-dev \
    libdbus-1-dev \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-yaml \
    python3-jsonschema \
    python3-cffi \
    python3-six \
    && rm -rf /var/lib/apt/lists/*

# Build and Install flux-security
RUN git clone https://github.com/flux-framework/flux-security.git /tmp/flux-security && \
    cd /tmp/flux-security && \
    ./autogen.sh && \
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/flux-security

# Build and Install flux-core
RUN git clone https://github.com/flux-framework/flux-core.git /tmp/flux-core && \
    cd /tmp/flux-core && \
    ./autogen.sh && \
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/flux-core

# Add a marker so we know Flux is here
RUN echo "Flux Framework integrated with Slinky Slurm (Built from source)" > /etc/hpc-flavor
