# esplora compose config

## components
- bitcoin/bitcoin ( https://github.com/willcl-ark/bitcoin-core-docker https://hub.docker.com/r/bitcoin/bitcoin)
- ghcr.io/bitcreditprotocol/electrs-blockstream
- ghcr.io/bitcreditprotocol/esplora-frontend

## networks

- mainnet
- testnet
- regtest

The `esplora` service is frontend-only and proxies browser API requests to `ELECTRS_HTTP_URL`.
By default it points to the local `electrs` service at `http://electrs:3000`, but you can override it
to use an external electrs HTTP API without rebuilding the frontend image.

## running the compose config

### configure .env

```
cp .env.example .env
```

### mainnet
```
docker compose up -d
```

### regtest
```
docker compose -f compose.yaml -f regtest.yaml  up -d
```

### testnet
```
docker compose -f compose.yaml -f testnet.yaml up -d
```
