BestInSlot `ord` image built from the `ord` directory of `bestinslot-xyz/OPI`.

Source repository:
- https://github.com/bestinslot-xyz/OPI/tree/main/ord


The pinned ref uses Rust edition 2024 in `ord/db_reader`, so this image uses
Rust `1.85.0` even though the upstream Dockerfile still lists Rust `1.81.0`.

About `db_reader`:
- `db_reader` is BestInSlot/OPI-specific code located at `OPI/ord/db_reader`.
- It is not part of the original upstream `ordinals/ord` project.
- This fork wires `db_reader` into the `ord` binary as a local Rust dependency.
- It exposes a JSON-RPC reader API over the ord RocksDB index for OPI services,
  including BRC-20, bitmap, SNS, inscription, UTXO, and block metadata lookups.
- Set `DB_READER_API_URL=0.0.0.0:11030` at runtime when other Compose services
  need to reach the embedded reader API.

Build the pinned ref:

`docker build -t ord-bestinslot docker/ord-bestinslot`

Build a specific branch, tag, or commit:

`docker build --build-arg REF=<branch-tag-or-commit> -t ord-bestinslot docker/ord-bestinslot`

Run:

`docker run --rm ord-bestinslot --help`

Compose notes from `ord --help`:
- Put global options before the command.
- Use `--data-dir` for persistent ord index data.
- Prefer the documented `--data-dir` spelling; some ord examples use
  `--datadir`, but this build documents `--data-dir`.
- The runtime container runs as the unprivileged `ord` user with fixed UID/GID
  `10001:10001` and `/data` as its working directory; mount persistent Compose
  data under `/data/ord`.
- Use `--bitcoin-rpc-url`, `--bitcoin-rpc-username`, and
  `--bitcoin-rpc-password` for Bitcoin Core RPC credentials, or use
  `--cookie-file` instead when sharing the Bitcoin Core cookie.
- Mainnet is the default, but set `--chain=mainnet` explicitly in Compose so the
  intended network is easy to review later.
- Select another network with `--chain=<network>`, `--regtest`, `--signet`,
  `--testnet`, or `--testnet4`.
- This pinned BestInSlot build exposes `ord index update`; `ord index run` is
  accepted as an alias, but `update` is the canonical subcommand name.

Runtime user and bind mounts:
- The image creates the `ord` user and group with deterministic UID/GID
  `10001:10001`. The build args `ORD_UID` and `ORD_GID` only apply when
  building the image; they change the default user baked into that image.
- Compose does not need a `user:` override because the Dockerfile already sets
  `USER 10001:10001`. For production, prefer omitting `user:` or keep it
  explicit with `user: "10001:10001"` so server ownership stays predictable.
- For local development with host bind mounts, a runtime Compose override can
  match your host user instead:

```yaml
user: "${UID}:${GID}"
```

Set `UID` and `GID` in the Compose environment or `.env` file to the numeric
host IDs that own the mounted directory. This is useful for local/dev and simple
single-host setups, but fixed `10001:10001` is easier to operate consistently in
production.
- For host bind mounts, the host directory must be owned by the same UID/GID:

```sh
sudo mkdir -p /var/lib/ord-bestinslot
sudo chown -R 10001:10001 /var/lib/ord-bestinslot
sudo chmod -R 750 /var/lib/ord-bestinslot
```

Healthcheck:
- The sample healthcheck uses the embedded `db_reader` JSON-RPC API and checks
  that it returns a JSON result. This verifies that the HTTP reader is serving
  responses; it does not prove that indexing is fully caught up.
- The image includes `curl` for this healthcheck. The command uses only `curl`
  and `grep` to keep the runtime image small.

Example Compose command shape:

```yaml
user: "10001:10001"
command:
  - --data-dir
  - /data/ord
  - --chain=mainnet
  - --bitcoin-rpc-url
  - ${BTC_RPC_URL}
  - --bitcoin-rpc-username
  - ${BTC_RPC_USER}
  - --bitcoin-rpc-password
  - ${BTC_RPC_PASSWORD}
  - index
  - update
environment:
  DB_READER_API_URL: 0.0.0.0:11030
volumes:
  - ord-data:/data/ord
healthcheck:
  test:
    - CMD-SHELL
    - >-
      curl -fsS --max-time 5 -H 'content-type: application/json'
      --data '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockHeight","params":[]}'
      http://127.0.0.1:11030 | grep -q '"result"'
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 120s
```
