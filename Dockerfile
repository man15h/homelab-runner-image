# Job-container image for Gitea/Forgejo Actions runners
# Pre-installed: SOPS, Ansible, Python 3 (with venv), git, OpenSSH client, jq

FROM debian:bookworm-slim

# Versions
ARG SOPS_VERSION=3.13.3
ARG UV_VERSION=0.12.7
# Ceiling is the base image's Python, not upstream's latest: bookworm ships
# 3.11 and every ansible above 12.3.0 requires >=3.12. Moving the base image
# is what unblocks a newer line here.
ARG ANSIBLE_VERSION=12.3.0

# openssh-client: Ansible's SSH transport to managed hosts
# python3-venv: jobs that build a throwaway venv for tests
# jq: jobs that parse API responses or scan output
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    python3 \
    python3-venv \
    openssh-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install SOPS
RUN ARCH=$(dpkg --print-architecture) && \
    curl -Lo /usr/local/bin/sops \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" && \
    chmod +x /usr/local/bin/sops

# Install uv
# uv's release assets are named for `uname -m` verbatim, so no arch mapping.
# Upstream publishes a .sha256 next to each tarball; unlike the curls above we
# can verify this one, so we do.
RUN ARCH=$(uname -m) && \
    cd /tmp && \
    curl -fsSLO "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${ARCH}-unknown-linux-gnu.tar.gz" && \
    curl -fsSLO "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${ARCH}-unknown-linux-gnu.tar.gz.sha256" && \
    sha256sum -c "uv-${ARCH}-unknown-linux-gnu.tar.gz.sha256" && \
    tar xzf "uv-${ARCH}-unknown-linux-gnu.tar.gz" && \
    install -m 0755 "uv-${ARCH}-unknown-linux-gnu/uv" /usr/local/bin/uv && \
    rm -rf /tmp/uv-${ARCH}-unknown-linux-gnu*

# Install Ansible
# uv rather than pip: the arm64 leg of the build is QEMU-emulated, which
# punishes pip's interpreter-bound work hardest. uv's package step there takes
# about 18s against pip's ~5 minutes.
#
# No --compile-bytecode, deliberately. Eagerly compiling ~16,000 files costs
# minutes of emulated build time; an ansible-playbook run imports a few hundred
# of them and compiles those lazily in well under a second.
RUN uv pip install --system --break-system-packages "ansible==${ANSIBLE_VERSION}"

# Verify installations
RUN sops --version && \
    uv --version && \
    ansible --version && \
    git --version && \
    ssh -V && \
    jq --version

# Default command
CMD ["/bin/bash"]