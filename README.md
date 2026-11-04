# codex-plugins — 跨 AI 插件仓库

一个仓库，三种用法：Codex 插件市场、可移植 Agent Skills、MCP 配置索引。

## 内容统计

- **369** 个插件包
- **333** 个包含可移植 Skill（共 **2914** 个 SKILL.md）
- **136** 个包含 MCP server 配置
- 20 个为 Codex 专用（无 Skill / MCP）

## 目录

~~~
.agents/plugins/marketplace.json   Codex 市场清单
plugins/                           插件包本体（Codex 格式）
catalog/plugins.json               通用索引（能力、路径、工具支持）
catalog/skills.json                2914 个 Skill 的路径索引
catalog/mcp.json                   136 个 MCP 配置索引
tools/install-skill.ps1            把 Skill 安装到 Claude Code / DSH
.github/workflows/sync-upstream.yml 每天从上游同步并重建索引
~~~

## Codex

~~~
codex plugin marketplace add https://github.com/tigerlovefbro/codex-plugins.git --ref main --sparse .agents/plugins --sparse plugins
~~~

然后在 Codex 的插件页安装。

## Claude Code（Skills）

~~~
.\tools\install-skill.ps1 -SkillPath "plugins/.../skills/<name>/SKILL.md" -Target claude
~~~

会复制到 %USERPROFILE%\.claude\skills\<name>。

## DSH（Skills）

~~~
.\tools\install-skill.ps1 -SkillPath "plugins/.../skills/<name>/SKILL.md" -Target dsh
~~~

会复制到 %USERPROFILE%\.agents\skills\<name>。

> Codex 插件包不是 DSH 插件包；跨工具复用的是 Skill（SKILL.md），不是插件清单。

## MCP

catalog/mcp.json 记录每个插件的 MCP server 名称和配置文件路径（如 plugins/.../.mcp.json）。
按你使用的客户端格式自行引用；配置里若有 token/占位符，需要替换成自己的。

## 更新

- 云端：GitHub Actions 每天 03:00 UTC 从上游同步插件并重建 catalog；
- 本机：运行 Sync-CodexPlugins.ps1（或在 Codex 里刷新市场）。

## 注意

- 插件为第三方代码，安装前请阅读其 README；
- Skill 可跨 Claude Code / DSH / Codex 复用，但依赖的脚本/资源要一起复制；
- 20 个 Codex 专用插件没有 Skill/MCP，不能直接用于其他工具。
