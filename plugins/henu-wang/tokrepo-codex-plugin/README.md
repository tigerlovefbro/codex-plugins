# TokRepo Codex Plugin

Codex plugin for searching and installing AI assets from TokRepo.

This plugin bundles:
- a `tokrepo-search` skill for Codex
- a TokRepo MCP server configuration

With it, Codex can discover installable:
- skills
- prompts
- MCP configs
- workflows

## Install

Add this plugin from GitHub once your Codex plugin marketplace or repo-local plugin config points to this repository.

## What it uses

- MCP server: `npx tokrepo-mcp-server`
- CLI:

```bash
npx tokrepo search "<query>"
npx tokrepo install <uuid-or-name>
```

## Repository

- Website: https://tokrepo.com
- GitHub: https://github.com/henu-wang/tokrepo-codex-plugin
- MCP package: https://www.npmjs.com/package/tokrepo-mcp-server
- CLI package: https://www.npmjs.com/package/tokrepo
