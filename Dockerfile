# File: Dockerfile
# Author: Tim Chaubet

ARG LS_TAG=latest
FROM linuxserver/code-server:${LS_TAG}

ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io fork version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="tim@chaubet.be"

ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

COPY ./requirements.txt requirements.txt

# Step 1: Core OS Utilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        vim ca-certificates curl gnupg lsb-release build-essential libgraphviz-dev jq

# Step 2: Setup External Repositories (Upgraded to Node 24)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -

# Step 3: Main Package Installation
RUN apt-get update && \
    apt-get install -y \
        docker-ce-cli nodejs python3 python3-pip python3-venv git php composer \
        php-codesniffer golang gcc g++ mypy tree python3-mypy && \
    apt-get autoremove -y && apt-get autoclean -y && apt-get clean -y && \
    rm -rf /config/* /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Step 4: Application Logic & Vulnerability Patching
RUN npm install -g npm@11.1.0 && \
    if [ -d "/app/code-server/lib/vscode" ]; then \
        cd /app/code-server/lib/vscode && \
        jq '.overrides.uuid = "^14.0.0"' package.json > package.json.tmp && mv package.json.tmp package.json && \
        rm -f package-lock.json && \
        npm install --force --unsafe-perm --engine-strict=false && \
        npm audit fix --force; \
    fi

# Step 5: Final Permissions
RUN usermod -aG sudo abc

EXPOSE 8443
VOLUME ["/config"]