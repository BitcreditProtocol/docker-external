# ---- builder ----
ARG RUST_VERSION=1.92.0
FROM rust:${RUST_VERSION}-trixie AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates clang cmake curl g++ git libclang-dev make pkg-config \
 && apt-get install -y --no-install-recommends \
      libbz2-dev liblz4-dev libsnappy-dev libzstd-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG REPO=https://github.com/blockstream/electrs.git
#ARG REF=new-index
# pin latest commit of branch new-index
ARG REF=5b3ff8f7c150ebd9953b50a79b07bd8651d7fd94

RUN git clone --filter=blob:none "${REPO}" . \
 && git fetch origin "${REF}" \
 && git checkout "${REF}"

# Build options: FEATURES="electrum-discovery,liquid"
#   electrum-discovery       -> discovery support
#   liquid                   -> Elements/Liquid support
ARG FEATURES=electrum-discovery
RUN cargo build --locked --release --bin electrs --features "${FEATURES}"

# ---- runtime ----
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libstdc++6 curl \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -r -d /var/lib/electrs -s /usr/sbin/nologin electrs \
 && mkdir -p /data && chown -R electrs:electrs /data

COPY --from=builder /src/target/release/electrs /usr/local/bin/electrs

USER electrs
VOLUME ["/data"]

# Electrum RPC and HTTP API
EXPOSE 50001 3000

ENTRYPOINT ["/usr/local/bin/electrs"]
CMD ["--db-dir","/data","--electrum-rpc-addr","0.0.0.0:50001","--http-addr","0.0.0.0:3000"]