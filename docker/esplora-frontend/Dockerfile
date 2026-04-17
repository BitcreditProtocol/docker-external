# ---- builder ----
ARG NODE_VERSION=20-bookworm-slim
FROM node:${NODE_VERSION} AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates git python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG REPO=https://github.com/Blockstream/esplora.git
ARG REF=master
ARG FLAVORS="bitcoin-mainnet bitcoin-testnet bitcoin-testnet4 bitcoin-signet bitcoin-regtest"

RUN git clone --filter=blob:none "${REPO}" . \
 && git fetch origin "${REF}" \
 && git checkout "${REF}"

RUN npm install \
 && mkdir -p /out \
 && for flavor in ${FLAVORS}; do \
      DEST="/out/${flavor}" npm run dist -- "${flavor}"; \
    done

# ---- runtime ----
FROM nginx:1.28-alpine

COPY --from=builder /out /srv/esplora/static
COPY docker/esplora-frontend/docker-entrypoint.sh /usr/local/bin/esplora-frontend-entrypoint

RUN chmod +x /usr/local/bin/esplora-frontend-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/esplora-frontend-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
