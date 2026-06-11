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
- The runtime container runs as the unprivileged `ord` user with `/data` as its
  working directory; mount persistent Compose data under `/data/ord`.
- Use `--bitcoin-rpc-url`, `--bitcoin-rpc-username`, and
  `--bitcoin-rpc-password` for Bitcoin Core RPC credentials, or use
  `--cookie-file` instead when sharing the Bitcoin Core cookie.
- Mainnet is the default, but set `--chain=mainnet` explicitly in Compose so the
  intended network is easy to review later.
- Select another network with `--chain=<network>`, `--regtest`, `--signet`,
  `--testnet`, or `--testnet4`.
- This pinned BestInSlot build exposes `ord index update`; it does not expose
  `ord index run`.

Example Compose command shape:

```yaml
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
```
