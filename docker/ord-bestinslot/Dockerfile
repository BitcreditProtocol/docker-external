# ---- builder ----
ARG RUST_VERSION=1.85.0
FROM rust:${RUST_VERSION}-bookworm AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      git \
      libssl-dev \
      pkg-config \
      clang \
      cmake \
      protobuf-compiler \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/OPI
ARG REPO=https://github.com/bestinslot-xyz/OPI.git
# v2.0.10
ARG REF=bf44112

RUN git clone --filter=blob:none --sparse "${REPO}" . \
 && (git fetch --depth=1 origin "${REF}" && git checkout --detach FETCH_HEAD || git checkout --detach "${REF}") \
 && git sparse-checkout set ord

WORKDIR /usr/src/OPI/ord
RUN cargo build --locked --bin ord --release

# ---- runtime ----
FROM debian:bookworm-slim

ARG ORD_UID=10001
ARG ORD_GID=10001

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libssl3 \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid "${ORD_GID}" ord \
 && useradd --system \
      --uid "${ORD_UID}" \
      --gid "${ORD_GID}" \
      --home-dir /data \
      --shell /usr/sbin/nologin \
      ord \
 && mkdir -p /data/ord \
 && chown -R "${ORD_UID}:${ORD_GID}" /data

COPY --from=builder /usr/src/OPI/ord/target/release/ord /usr/local/bin/ord

USER ${ORD_UID}:${ORD_GID}
WORKDIR /data

ENV RUST_BACKTRACE=1
ENV RUST_LOG=info

EXPOSE 11030

ENTRYPOINT ["/usr/local/bin/ord"]
CMD []
