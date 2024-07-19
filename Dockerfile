FROM rust:1.79-slim-bookworm AS builder

RUN apt-get update -qqy && \
    apt-get upgrade -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
    protobuf-compiler && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /build
COPY ./chamberlain .
RUN rustup toolchain install stable
RUN cargo +stable install --locked --path .

FROM debian:bookworm-slim AS final

RUN apt-get update -qqy && \
    apt-get upgrade -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
    bash \
    ca-certificates \
    certbot \
    curl \
    gettext \
    jq \
    netcat-openbsd \
    nginx \
    python3-certbot-nginx \
    tini \
    wireguard-tools && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*

ARG ARCH
ARG PLATFORM
RUN curl -sLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${PLATFORM} && chmod +x /usr/local/bin/yq

COPY --from=builder /usr/local/cargo/bin/chamberlain /bin/chamberlain
COPY --from=builder /usr/local/cargo/bin/chamberlaind /bin/chamberlaind

ADD conf/nginx.conf.template /etc/nginx/nginx.conf.template
ADD conf/certbot_nginx.conf.template /etc/nginx/certbot_nginx.conf.template
ADD conf/wg0.conf.template /etc/wireguard/wg0.conf.template

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD ./check_http.sh /usr/local/bin/check_http.sh
RUN chmod a+x /usr/local/bin/check_http.sh
ADD ./check_rpc.sh /usr/local/bin/check_rpc.sh
RUN chmod a+x /usr/local/bin/check_rpc.sh

WORKDIR /root/data

EXPOSE 80
EXPOSE 443
EXPOSE 3338
EXPOSE 3339
EXPOSE 43339

STOPSIGNAL SIGINT

ENTRYPOINT ["docker_entrypoint.sh"]
