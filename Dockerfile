# CI Runner Image for Gitea Actions
# Pre-installed: Docker CLI, Compose, SOPS, Ansible, Python3
FROM debian:bookworm-slim

# Versions
ARG DOCKER_VERSION=25.0.3
ARG COMPOSE_VERSION=2.24.5
ARG SOPS_VERSION=3.8.1

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN ARCH=$(uname -m) && \
    case $ARCH in \
        x86_64) DOCKER_ARCH="x86_64" ;; \
        aarch64) DOCKER_ARCH="aarch64" ;; \
    esac && \
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" | tar xz -C /tmp && \
    mv /tmp/docker/docker /usr/local/bin/docker && \
    chmod +x /usr/local/bin/docker && \
    rm -rf /tmp/docker

# Install Docker Compose plugin
RUN ARCH=$(uname -m) && \
    case $ARCH in \
        x86_64) COMPOSE_ARCH="x86_64" ;; \
        aarch64) COMPOSE_ARCH="aarch64" ;; \
    esac && \
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -fsSL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install SOPS
RUN ARCH=$(dpkg --print-architecture) && \
    curl -Lo /usr/local/bin/sops \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" && \
    chmod +x /usr/local/bin/sops

# Install Ansible
RUN pip install --break-system-packages ansible

# Verify installations
RUN docker --version && \
    docker compose version && \
    sops --version && \
    ansible --version && \
    git --version

# Default command
CMD ["/bin/bash"]
