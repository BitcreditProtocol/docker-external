Esplora frontend image that builds the upstream `Blockstream/esplora` static SPA and serves it with nginx.

The container only serves the frontend and proxies browser API requests to a configurable electrs HTTP endpoint.

Source repository:
- https://github.com/Blockstream/esplora

Default runtime configuration:
- `ESPLORA_FLAVOR=bitcoin-mainnet`
- `ELECTRS_HTTP_URL=http://electrs:3000`

Supported `ESPLORA_FLAVOR` values in this image:
- `bitcoin-mainnet`
- `bitcoin-testnet`
- `bitcoin-testnet4`
- `bitcoin-signet`
- `bitcoin-regtest`

Optional runtime configuration:
- `ESPLORA_BASE_HREF` to override the default UI prefix for the selected flavor
- `ESPLORA_SERVER_NAME` to set the nginx `server_name`

Default `ESPLORA_BASE_HREF` values:
- `bitcoin-mainnet` -> `/`
- `bitcoin-testnet` -> `/testnet/`
- `bitcoin-testnet4` -> `/testnet4/`
- `bitcoin-signet` -> `/signet/`
- `bitcoin-regtest` -> `/regtest/`

Examples:

Electrs in the same Docker network:

`docker run -d --name esplora-frontend-testnet --network esplora_default -p 8080:80 -e ESPLORA_FLAVOR=bitcoin-testnet -e ELECTRS_HTTP_URL=http://electrs:3000 ghcr.io/bitcreditprotocol/esplora-frontend:latest`

Electrs running on the Docker host machine:

`docker run -d --name esplora-frontend-testnet -p 8080:80 -e ESPLORA_FLAVOR=bitcoin-testnet -e ELECTRS_HTTP_URL=http://host.docker.internal:3000 ghcr.io/bitcreditprotocol/esplora-frontend:latest`
