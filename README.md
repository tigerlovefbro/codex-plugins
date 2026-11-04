# codex-plugins — 跨 AI 插件仓库

一个仓库，三种用法：Codex 插件市场、可移植 Agent Skills、MCP 配置索引。

## 内容统计

- **371** 个插件包
- **335** 个包含可移植 Skill（共 **2980** 个 SKILL.md）
- **135** 个包含 MCP server 配置
- 20 个为 Codex 专用（无 Skill / MCP）

## 个人插件

- personal-toolkit：vmctl 技能（VMware 虚拟机控制）
- mcp-sync：MCP 定义导出/恢复（跨电脑同步）
- task-router：任务路由（选工具、强制复核/守卫）

## 目录

~~~
.agents/plugins/marketplace.json   Codex 市场清单
plugins/                           插件包本体（Codex 格式）
catalog/plugins.json               通用索引（能力、路径、工具支持）
catalog/skills.json                2980 个 Skill 的路径索引
catalog/mcp.json                   135 个 MCP 配置索引
tools/install-skill.ps1            把 Skill 安装到 Claude Code / DSH
tools/install-global-agents.ps1    安装全局 AGENTS 规则
setup/lock-version/                锁定/恢复 OpenAI 更新
setup/installers/                  安装包清单 + SHA256
setup/releases/                    大文件分发与下载脚本
.github/workflows/sync-upstream.yml 每天同步、去重、清理、重建索引
~~~

## Codex

~~~
codex plugin marketplace add https://github.com/tigerlovefbro/codex-plugins.git --ref main --sparse .agents/plugins --sparse plugins
~~~

然后在 Codex 的插件页安装。

## Claude Code / DSH（Skills）

~~~
.	oolsinstall-skill.ps1 -SkillPath "plugins/.../skills/<name>/SKILL.md" -Target claude
.	oolsinstall-skill.ps1 -SkillPath "plugins/.../skills/<name>/SKILL.md" -Target dsh
~~~

分别复制到 %USERPROFILE%\.claude\skills\<name> 与 %USERPROFILE%\.agents\skills\<name>。

> Codex 插件包不是 DSH 插件包；跨工具复用的是 Skill（SKILL.md）。

## MCP

catalog/mcp.json 记录每个插件的 MCP server 名称和配置文件路径。按你使用的客户端格式引用；token/占位符需替换成自己的。

## 大文件（Release）

安装包与 Chrome 组件不在 Git，放在 Release：

https://github.com/tigerlovefbro/codex-plugins/releases/tag/assets-20261104

- OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0.Msix
- chrome-mcp-lite.zip / chrome-mcp-full.zip

## 换电脑

见 setup/NEW-MACHINE.md（含版本锁定、中转 token、插件/MCP 恢复、验收清单）。

## 更新

- 云端：GitHub Actions 每天 03:00 UTC 从上游同步、补个人插件、去重、清理未列目录、重建 catalog；
- 本机：运行 Sync-CodexPlugins.ps1，或在 Codex 里刷新市场。

## 注意

- 插件为第三方代码，安装前请阅读其 README；
- Skill 可跨 Claude Code / DSH / Codex 复用，但依赖的脚本/资源要一起复制；
- 20 个 Codex 专用插件没有 Skill/MCP，不能直接用于其他工具。
