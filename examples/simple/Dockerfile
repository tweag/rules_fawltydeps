FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    fd-find \
    git \
    python3 \
    python3-pip \
    ripgrep \
    sudo \
    unzip \
    neovim \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk
RUN curl -Lo /usr/local/bin/bazelisk https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
    && chmod +x /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

# Switch to non-root user
USER ubuntu
WORKDIR /workspace

# Default shell
SHELL ["/bin/bash", "-c"]

# Default command
CMD ["bash"]
