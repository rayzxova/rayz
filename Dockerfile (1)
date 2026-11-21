FROM node:20-bookworm
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-server ca-certificates curl git unzip zip nano sudo python3 procps \
    && npm i -g pm2 \
    && mkdir -p /run/sshd \
    && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 22
CMD ["/entrypoint.sh"]
