FROM debian:bullseye

ARG NETDATA_VERSION=1.47.5

# Install Netdata using static binary
RUN export DEBIAN_FRONTEND=noninteractive && \
    echo "Installing Netdata v${NETDATA_VERSION}" && \
    apt-get update && \
    apt-get install -y wget ca-certificates && \
    cd /tmp && \
    wget --no-verbose \
        -O netdata-installer.sh \
        "https://github.com/netdata/netdata/releases/download/v${NETDATA_VERSION}/netdata-x86_64-v${NETDATA_VERSION}.gz.run" && \
    chmod +x netdata-installer.sh && \
    ./netdata-installer.sh --accept && \
    rm -f netdata-installer.sh && \
    apt-get install -y msmtp msmtp-mta apcupsd fping \
        python3 python3-mysqldb python3-yaml && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy and setup run script
COPY scripts/run.sh /run.sh
RUN chmod +x /run.sh

# Setup logging to stdout/stderr
RUN mkdir -p /var/log/netdata && \
    ln -sf /dev/stdout /var/log/netdata/access.log && \
    ln -sf /dev/stdout /var/log/netdata/debug.log && \
    ln -sf /dev/stderr /var/log/netdata/error.log

# Environment variables
ENV NETDATA_PORT=19999 \
    SMTP_TLS=on \
    SMTP_STARTTLS=on \
    SMTP_SERVER=smtp.gmail.com \
    SMTP_PORT=587 \
    SMTP_FROM=localhost

WORKDIR /
EXPOSE ${NETDATA_PORT}
VOLUME /etc/netdata/override

ENTRYPOINT ["/run.sh"]