# ---- builder ----
ARG RUST_VERSION=1.88
FROM rust:${RUST_VERSION}-slim-bookworm AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates clang git libssl-dev pkg-config \
 && rm -rf /var/lib/apt/lists/*

ARG REPO=https://github.com/bestinslot-xyz/brc20-programmable-module.git
ARG REF=v0.15.13

RUN cargo install --locked \
      --git "${REPO}" \
      brc20-prog \
      --tag "${REF}"


# ---- runtime ----
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libssl3 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -d /var/lib/brc20-prog -s /usr/sbin/nologin brc20prog \
 && mkdir -p /var/lib/brc20-prog/data \
 && chown -R brc20prog:brc20prog /var/lib/brc20-prog

COPY --from=builder /usr/local/cargo/bin/brc20-prog /usr/local/bin/brc20-prog

USER brc20prog
WORKDIR /var/lib/brc20-prog

EXPOSE 18545

ENTRYPOINT ["brc20-prog"]
CMD ["-l", "info"]
