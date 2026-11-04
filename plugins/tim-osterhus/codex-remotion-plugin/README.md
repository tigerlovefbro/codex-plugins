# Remotion Plugin For Codex

This is a standalone Codex plugin bundle for Remotion work. It packages:

- a Remotion-focused Codex skill
- a Millrace launch-video reference distilled from your three planning docs
- a plugin-local MCP manifest for the official Remotion documentation server
- a slash command for scaffolding or refactoring Remotion video projects

GitHub repository:

- [tim-osterhus/codex-remotion-plugin](https://github.com/tim-osterhus/codex-remotion-plugin)

## Bundle Layout

```text
codex-remotion-plugin/
  .codex-plugin/plugin.json
  .mcp.json
  agents/openai.yaml
  commands/build-video.md
  skills/remotion-video-builder/
    SKILL.md
    references/
      remotion-core.md
      millrace-launch-video.md
```

## Sources

Official Remotion sources:

- [Agent Skills](https://www.remotion.dev/docs/ai/skills)
- [Remotion MCP](https://www.remotion.dev/docs/ai/mcp)
- [System Prompt For LLMs](https://www.remotion.dev/docs/ai/system-prompt)
- [calculateMetadata()](https://www.remotion.dev/docs/calculate-metadata)
- [The fundamentals](https://www.remotion.dev/docs/the-fundamentals)

## MCP Setup

If you want the Remotion docs MCP available immediately in Codex, add it with:

```bash
codex mcp add remotion-documentation -- npx @remotion/mcp@latest
```

You can verify it with:

```bash
codex mcp list
```

## Optional Official Skills

Remotion also publishes official agent skills. If you want those globally in Codex as well, install them with:

```bash
npx skills add remotion-dev/skills
```

## Plugin Install Note

This machine's Codex CLI exposes MCP management directly, but not a first-party CLI command for installing plugin bundles. Because of that, this repo is prepared as a plugin bundle, but plugin registration still depends on the Codex app or your local plugin registry workflow.

Use it in one of these ways:

1. Add it through the Codex app plugin flow if you want it treated as a plugin bundle.
2. Copy or vendor the contents into your local plugin registry repo if you maintain one.
3. Reuse the skill files directly if you only need the behavior and not the plugin wrapper.

## Intended Usage

After installation, use the plugin for tasks like:

- scaffold a new Remotion project
- add `zod` schemas and `calculateMetadata`
- build landscape and vertical launch-video compositions
- add terminal replay and event-driven overlays
- turn structured run metadata into renderable video outputs

If the task is specifically about Millrace, the skill points Codex at the bundled Millrace reference first.
