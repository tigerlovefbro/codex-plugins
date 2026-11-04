# MCP Sync

把 Codex 的 MCP 定义导出到 codex-plugins 仓库，换电脑或用别的 AI 客户端时恢复。

## 导出

powershell -ExecutionPolicy Bypass -File scripts\export-mcp.ps1 -Push

- 输出：personal/mcp/<name>.json + personal/mcp/index.json
- 自动脱敏：TOKEN/SECRET/PASSWORD/KEY 等值替换为 ***REDACTED***
- 自动 commit + push

## 恢复

Codex：

powershell -ExecutionPolicy Bypass -File scripts\restore-mcp.ps1

其他客户端（输出 mcpServers JSON）：

powershell -ExecutionPolicy Bypass -File scripts\restore-mcp.ps1 -Target json

## 说明

- 通用格式为 JSON：name、transport、env、args、url。
- 机器相关路径会原样导出，恢复前检查。
- 密钥永远不进仓库。
