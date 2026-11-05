# Global agent rules

## Routing
- Multi-step or tool-heavy task: use the task-router skill, then state which plugins/skills were used.
- Simple one-step task: answer directly; do not force the workflow.

## Scope
- Read relevant files before editing; keep diffs minimal and scoped.
- Do not refactor, rename, or reformat unrelated code.
- stop-that-shit: reject unneeded hashes, checksums, retries, or scope creep.

## Verification
- After code changes, run the project's tests/lint/build when available.
- codex-reviewer second pass is required unless the user says skip.
- Never claim a check passed without running it.

## MCP and skills
- Any MCP add/change: run mcp-sync export-mcp.ps1 -Push and confirm personal/mcp/index.json is updated and pushed.
- Skill publishing: use skill-sync-publisher.

## Safety and repository
- Never commit tokens, keys, installers, or large binaries; redact secrets and use Releases.

## Reporting
- Final answer: what changed, commands run, results, and residual risks.
