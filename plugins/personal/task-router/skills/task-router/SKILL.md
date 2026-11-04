---
name: task-router
description: Route multi-step or tool-heavy tasks to the right installed plugins and skills, announce the route, enforce review/guard steps, and report which tools were used. Use for coding, debugging, research, browser automation, local app control, long-running jobs, and MCP/skill changes. Skip for trivial one-step requests.
---

# Task Router

A portable routing skill for Codex, Claude Code, and DSH. It does not add tools; it decides which installed tools to use and in what order.

## Procedure

1. Classify the task into one or more routes from the table.
2. Announce the route in one short line before acting.
3. Use only the mapped tools; do not force unrelated plugins.
4. Run the required self-check for that route.
5. In the final answer, state which route and tools were used.

## Routes

| Task type | Use | Self-check |
|---|---|---|
| Write or change code | implement, then codex-reviewer for a second pass | stop-that-shit: no scope creep, no unneeded hashes/checks |
| Debug a failure | reproduce, isolate, fix, then codex-reviewer | no unrelated refactors |
| Architecture or trade-off decision | claude-octopus for multi-model opinions | list disagreements and choose |
| Research / papers / citations | research-agent-skills | cite sources, separate facts from inference |
| Web search or scraping | firecrawl; browser control via chrome-devtools | verify key facts from at least two sources |
| Local Windows apps / Office / Mail | local-mcp | confirm account/permissions before writes |
| Long or rate-limited jobs | codex-auto-resume | preserve task state before resuming |
| Cost or token questions | codex-usage-tracker | report measured numbers, not guesses |
| Cross-session memory | codex-mem | store only durable facts |
| New or changed MCP | mcp-sync: run export-mcp.ps1 -Push | confirm personal/mcp/index.json updated and pushed |
| Skill publishing | skill-sync-publisher | validate and dry-run before publishing |

## Rules

- Simple tasks do not need routing; answer directly.
- Never claim a plugin was used if it was not.
- For code changes, codex-reviewer is required unless the user explicitly skips it.
- For any MCP change, exporting to the repository is mandatory.
- If a route fails, report the failure and fall back to direct implementation.
