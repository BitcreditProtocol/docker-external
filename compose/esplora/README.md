# esplora compose config

## images

- bitcoin/bitcoin ( https://github.com/willcl-ark/bitcoin-core-docker)
- ghcr.io/bitcreditprotocol/electrs-blockstream
- blockstream/esplora
- nginx:alpine

## networks

- mainnet
- testnet
- regtest

## running the compose config

configure .env file

### mainnet
docker compose up -d

### regtest
docker compose -f compose.yaml -f regtest.yaml  up -d

### testnet
docker compose -f compose.yaml -f testnet.yaml up -d

