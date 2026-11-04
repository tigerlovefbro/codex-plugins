# codex-plugins

Cross-AI plugin hub: Codex marketplace + portable Skills + MCP index. Keep it usable from any machine.

## Commands

- python scripts/ensure_personal_plugin.py
- python scripts/dedupe_marketplace.py
- python scripts/prune_unlisted.py --apply
- python scripts/build_catalog.py
- powershell -ExecutionPolicy Bypass -File plugins/personal/mcp-sync/scripts/export-mcp.ps1 -Push

## Rules

- Keep personal plugins (personal-toolkit, mcp-sync, task-router) registered in the marketplace.
- Never commit MSIX/Chrome binaries; put them in GitHub Releases.
- After plugin/content changes: ensure, dedupe, prune, build catalog, commit, push.
- Do not rename the marketplace name awesome-codex-plugins; plugin IDs depend on it.
- Keep catalog/ and marketplace.json in sync.
