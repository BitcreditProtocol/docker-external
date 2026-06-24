# BRC20 index stack

## Production

Full production example including Bitcoin Core, ord, BRC20 DB, indexer, prog, and API:

```sh
docker compose --env-file dotenv -f compose.yaml up -d
```

This full example starts a mainnet Bitcoin Core node with `txindex=1` and an ord indexer, so a fresh deployment must sync Bitcoin Core and ord before BRC20 indexing can be useful.

Production compose with an existing synced BestInSlot ord DB reader:

```sh
docker compose --env-file dotenv -f compose.external-ord.yaml up -d
```

Before running production, replace the placeholder secrets and Bitcoin Core RPC values in `dotenv`.

For `compose.external-ord.yaml`, set:

```env
OPI_DB_URL=http://<existing-synced-ord-db-reader-host>:11030
BTC_RPC_URL=http://<rpcuser>:<rpcpassword>@<synced-bitcoin-core-host>:8332
BRC20_DB_PASSWD=<strong-secret>
BRC20_PROG_RPC_USER=<strong-user>
BRC20_PROG_RPC_PASSWORD=<strong-secret>
```

`BRC20_PROG_VERSION` is the Docker image tag without a leading `v`; `BRC20_PROG_REF` is the upstream Git tag and keeps the leading `v`.

## Local Tests

Local no-prog patch image build/test compose without BRC20 prog or Bitcoin RPC:

```sh
docker compose --env-file dotenv.local -f brc20-local-noprog-patch.compose.yml build
docker compose --env-file dotenv.local -f brc20-local-noprog-patch.compose.yml up
```

Local full prog image build/test compose with an external mainnet Bitcoin RPC:

```sh
docker compose \
  --env-file dotenv.local \
  --env-file dotenv.local.external-rpc \
  -f brc20-local.compose.yml \
  build

docker compose \
  --env-file dotenv.local \
  --env-file dotenv.local.external-rpc \
  -f brc20-local.compose.yml \
  up
```

Before running local tests, update `dotenv.local` so `OPI_DB_URL` points to your existing BestInSlot ord DB reader. For full-prog local tests, also update `dotenv.local.external-rpc` so `BTC_RPC_URL` points to a synced mainnet Bitcoin Core RPC.

The local compose files have fallback Postgres credentials and local endpoint defaults so local tooling can render them even if `dotenv.local` is not loaded. Production compose intentionally requires explicit secrets.

For the no-prog patch local compose, prog and Bitcoin RPC settings are omitted and the indexer uses `brc20-index-bestinslot-noprog`, a patched image that skips the upstream startup `eth_blockNumber` call when prog is disabled.

Use mainnet RPC when `OPI_DB_URL` points to a mainnet BestInSlot ord DB reader. Testnet Bitcoin RPC will not match mainnet ord/index data. Do not use an unsynced local mainnet node for full-prog testing.

Useful local checks:

```sh
curl http://127.0.0.1:18000/v1/brc20/db_version
curl http://127.0.0.1:18000/v1/brc20/block_height
docker logs -f brc20-index-bestinslot-local
docker logs -f brc20-prog-local
```
