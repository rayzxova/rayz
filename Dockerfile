# OS dipilih lewat BASE_IMAGE (bot kirim dari config VPS_OS). Bawaan: Ubuntu 22.04.
ARG BASE_IMAGE=ubuntu:22.04
FROM node:20-bookworm AS nodesrc
FROM ${BASE_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive
# Node 20 + npm disalin dari image resmi node, jadi nggak perlu curl|bash dari luar
COPY --from=nodesrc /usr/local/ /usr/local/
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-server ca-certificates curl git unzip zip nano sudo python3 procps xz-utils \
    && npm i -g pm2 \
    && mkdir -p /run/sshd \
    && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
COPY apikey-check.sh /apikey-check.sh
RUN chmod +x /entrypoint.sh /apikey-check.sh
EXPOSE 22
CMD ["/entrypoint.sh"]
