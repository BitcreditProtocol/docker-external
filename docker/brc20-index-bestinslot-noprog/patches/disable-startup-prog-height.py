from pathlib import Path

path = Path("modules/brc20_index/src/indexer/brc20_indexer.rs")
src = path.read_text()

old = """        tracing::info!(
            "Prog Block Height: {}",
            parse_hex_number(&self.brc20_prog_client.eth_block_number().await?)?
        );
"""

new = """        if self.config.brc20_prog_enabled {
            tracing::info!(
                "Prog Block Height: {}",
                parse_hex_number(&self.brc20_prog_client.eth_block_number().await?)?
            );
        }
"""

if old not in src:
    raise SystemExit("Could not find upstream startup Prog Block Height snippet to patch")

path.write_text(src.replace(old, new, 1))
