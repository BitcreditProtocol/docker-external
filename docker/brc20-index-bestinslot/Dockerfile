# ---- builder ----
ARG RUST_VERSION=1.96.0
FROM rust:${RUST_VERSION}-trixie AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential libssl-dev ca-certificates clang pkg-config git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG REPO=https://github.com/bestinslot-xyz/OPI.git

ARG REF=v2.0.10

RUN git clone "${REPO}" . \
 && git fetch origin "${REF}" \
 && git checkout "${REF}"

RUN cargo build --locked --release --manifest-path modules/brc20_index/Cargo.toml --target-dir /src/target


# ---- runtime ----
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -r -d /var/lib/brc20index -s /usr/sbin/nologin brc20index \
 && mkdir -p /data && chown -R brc20index:brc20index /data

COPY --from=builder /src/target/release/brc20-index /usr/local/bin/brc20-index

USER brc20index
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/brc20-index"]
