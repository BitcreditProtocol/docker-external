# ---- dependencies ----
FROM node:22-bookworm-slim AS deps

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG REPO=https://github.com/bestinslot-xyz/OPI.git
ARG REF=v2.0.10

RUN git clone --filter=blob:none --sparse "${REPO}" . \
 && (git fetch --depth=1 origin "${REF}" && git checkout --detach FETCH_HEAD || git checkout --detach "${REF}") \
 && git sparse-checkout set modules/brc20_api

WORKDIR /src/modules/brc20_api
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi \
 && npm cache clean --force


# ---- runtime ----
FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -d /app -s /usr/sbin/nologin brc20api

WORKDIR /app
COPY --from=deps --chown=brc20api:brc20api /src/modules/brc20_api /app

USER brc20api

ENV NODE_ENV=production
ENV API_HOST=0.0.0.0
ENV API_PORT=8000

EXPOSE 8000

CMD ["node", "api.js"]
