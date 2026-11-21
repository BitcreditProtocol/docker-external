BestInSlot `ord` image built from the `ord` directory of `bestinslot-xyz/OPI`.

Source repository:
- https://github.com/bestinslot-xyz/OPI/tree/main/ord

The default source remains the v2.0.10 Ord commit
`bf441125d2649776d6fa9ed0985fd591a9e735c9`. Image `0.1.1` adds the local
[`0001-validate-reorg-backups.patch`](patches/0001-validate-reorg-backups.patch)
before compilation. The build runs `git apply --check` first and fails if an
overridden source ref no longer accepts the patch.

### Reorg checkpoint recovery

Upstream always restores the oldest retained RocksDB backup. After a reorg,
that backup can belong to an abandoned branch even when a newer backup is on
Bitcoin Core's active chain. Repeatedly restoring it then repeats the same
reorg detection and full database restore.

The patch tries backups from newest to oldest, restores a candidate into a
staging directory, and reads its actual highest indexed block header. It only
promotes the restored database when Bitcoin Core's `getblockhash` at that
height matches the checkpoint's hash. It does not infer checkpoint height from
the backup ID, block count, reorg detection height, or `LastSavepointHeight`.

Checkpoint tips are remembered in `backup/checkpoint-tips.json`, bound to a
SHA-256 hash of each RocksDB backup manifest. Every recovery attempt rechecks
the remembered tip against Core, so a known orphan can be skipped without
another full restore, including after process restart. Hints cannot authorize
promotion: the restored database's actual tip is checked again. Malformed or
stale hints are rebuilt by probing the backup. Existing backups without hints
are supported and may each need one full restore to discover their tip.

If no retained checkpoint matches, recovery exits with an explicit error and
preserves the active index and backup repository. RPC errors also abort without
replacing the active index. A Core node behind the checkpoint does not cause
the backup to be deleted; a later attempt checks it again. Recovery beyond the
retained checkpoint history still requires operator intervention.

New checkpoints flush all column families before backup because Ord disables
the write-ahead log. Retention runs after a new backup has been created and its
tip recorded, preserving the configured maximum number of snapshots.

Recovery needs free disk space for one additional full checkpoint while the
active index remains in place. Under the Ord index directory,
`index.db.reorg-restore` and `index.db.reorg-previous` are reserved for recovery.
Startup repairs an interrupted directory swap and removes leftover staging
data before opening the primary database. A small persistent RocksDB at
`reorg.lock` provides an exclusive OS lock across indexing and recovery; it is
released automatically when the process exits. Run one Ord process per data
directory. Older, unpatched binaries do not honor this additional lock and
must not share a live data directory with the patched image.

Run the recovery regression suite on Linux:

```sh
docker build --target recovery-tests docker/ord-bestinslot
```

The suite creates real RocksDB backups and exercises stale and valid fork
checkpoints, Bitcoin RPC validation through `mockcore`, non-header column family
contents, cached rejection after restart, transient RPC failure, checkpoint
height handling, hint replacement, interrupted swaps, and lock contention.
The `ord-recovery` workflow runs this target on pull requests; the normal
`docker-ci` workflow builds the release image. This repository change does not
deploy or modify any running service.

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
