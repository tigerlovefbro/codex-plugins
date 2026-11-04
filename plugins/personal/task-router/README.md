# Task Router

跨 AI 的任务调度技能：先判断任务类型，再调用对应插件/Skill，并强制执行复核、守卫、MCP 导出等步骤。

## Codex

codex plugin add task-router@awesome-codex-plugins

## Claude Code / DSH

.\tools\install-skill.ps1 -SkillPath "plugins/personal/task-router/skills/task-router/SKILL.md" -Target claude
.\tools\install-skill.ps1 -SkillPath "plugins/personal/task-router/skills/task-router/SKILL.md" -Target dsh

## 可选：全局强化

在 %USERPROFILE%\.codex\AGENTS.md 加一行：

- 多步骤/工具型任务先按 task-router 技能路由，并在最终回复里说明用了哪些工具。
