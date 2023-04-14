FROM linuxserver/code-server:latest
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="tim@chaubet.be"
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"
RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    vim \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
  mkdir -m 0755 -p /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && \
  apt-get install -y \
    docker-ce-cli 2>&1 && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
  usermod -aG docker abc 2>/dev/null && \
  usermod -aG sudo abc 2>/dev/null
EXPOSE 8443
VOLUME ["/config"]
