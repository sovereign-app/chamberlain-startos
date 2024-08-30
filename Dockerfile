FROM rust:1.79-slim-bookworm AS rust-builder

RUN apt-get update -qqy && \
    apt-get upgrade -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
    protobuf-compiler && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /build
COPY ./chamberlain .
RUN rustup toolchain install stable
RUN cargo +stable install --locked --path .

FROM golang:1.21-bookworm AS go-builder
WORKDIR /build
COPY ./nws .
RUN go build -o nws cmd/nws/*.go

FROM debian:bookworm-slim AS final

RUN apt-get update -qqy && \
    apt-get upgrade -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    gettext \
    jq \
    netcat-openbsd \
    nginx \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*

ARG ARCH
ARG PLATFORM
RUN curl -sLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${PLATFORM} && chmod +x /usr/local/bin/yq

COPY --from=rust-builder /usr/local/cargo/bin/chamberlain /bin/chamberlain
COPY --from=rust-builder /usr/local/cargo/bin/chamberlaind /bin/chamberlaind
COPY --from=go-builder /build/nws /bin/nws

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD ./check_http.sh /usr/local/bin/check_http.sh
RUN chmod a+x /usr/local/bin/check_http.sh
ADD ./check_rpc.sh /usr/local/bin/check_rpc.sh
RUN chmod a+x /usr/local/bin/check_rpc.sh

WORKDIR /root/data

EXPOSE 3338
EXPOSE 3339

STOPSIGNAL SIGINT

ENTRYPOINT ["docker_entrypoint.sh"]
