FROM rust:1.78-slim-bookworm AS builder

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
    curl \
    tini \
    netcat-openbsd \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG ARCH
ARG PLATFORM
RUN curl -sLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${PLATFORM} && chmod +x /usr/local/bin/yq

COPY --from=builder /usr/local/cargo/bin/chamberlain /bin/chamberlain

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD ./check_http.sh /usr/local/bin/check_http.sh
RUN chmod a+x /usr/local/bin/check_http.sh
ADD ./check_rpc.sh /usr/local/bin/check_rpc.sh
RUN chmod a+x /usr/local/bin/check_rpc.sh

WORKDIR /data

EXPOSE 3338
EXPOSE 3339

STOPSIGNAL SIGINT

ENTRYPOINT ["docker_entrypoint.sh"]