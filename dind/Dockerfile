FROM ubuntu:22.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_HOME=/home/runner
ENV DOCKER_TLS_CERTDIR=/certs

# Build arguments from .env file
ARG RUNNER_VERSION=2.325.0
ARG RUNNER_HASH=""

# Set as environment variable for runtime
ENV RUNNER_VERSION=${RUNNER_VERSION}

# Install required packages including Docker
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    sudo \
    ca-certificates \
    apt-transport-https \
    gnupg \
    lsb-release \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-pip \
    iptables \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash \
    && mv /root/.bun /usr/local/bun \
    && ln -s /usr/local/bun/bin/bun /usr/local/bin/bun

# Create runner user with docker group
RUN useradd -m -s /bin/bash runner \
    && usermod -aG docker runner

# Set working directory
WORKDIR ${RUNNER_HOME}

# Download and configure GitHub Actions Runner
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        RUNNER_ARCH="arm64"; \
    else \
        RUNNER_ARCH="x64"; \
    fi && \
    curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L \
        https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && if [ -n "${RUNNER_HASH}" ]; then \
        echo "Validating downloaded file with hash: ${RUNNER_HASH}"; \
        echo "${RUNNER_HASH}  actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" | sha256sum -c; \
       else \
        echo "WARNING: No hash provided, skipping validation"; \
       fi \
    && tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && chown -R runner:runner ${RUNNER_HOME}

# Install dependencies
RUN ./bin/installdependencies.sh

# Create supervisor config
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Volume for docker certs
VOLUME /certs

# Switch to runner user for runner operations
USER runner

ENTRYPOINT ["/entrypoint.sh"]