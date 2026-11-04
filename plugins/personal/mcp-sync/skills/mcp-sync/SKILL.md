# MCP Sync

Keep MCP server definitions in the codex-plugins GitHub repository so any computer can restore them.

## When you create or modify an MCP

1. Register it with the CLI and verify:
   - codex mcp add ...
   - codex mcp list --json
2. Export it to the repo:
   - powershell -ExecutionPolicy Bypass -File plugins\personal\mcp-sync\scripts\export-mcp.ps1 -Push
3. Confirm:
   - personal/mcp/index.json contains the server
   - the change is committed and pushed
4. Report the commit and the restore command.

If any step is missing, the task is not complete.

## Rules

- Never commit tokens or API keys; exported secrets are replaced with ***REDACTED***.
- Machine-specific paths are exported as-is; review before restoring on another computer.
- Do not delete personal/mcp/index.json.

## Restore on a new computer

Codex:
- powershell -ExecutionPolicy Bypass -File plugins\personal\mcp-sync\scripts\restore-mcp.ps1

Other MCP clients (Claude Code, DSH, ...):
- powershell -ExecutionPolicy Bypass -File plugins\personal\mcp-sync\scripts\restore-mcp.ps1 -Target json
- merge the printed mcpServers JSON into that client's config.
