# Personal MCP

这些是“配置片段”，不是自动生效的插件。使用时合并到：

%USERPROFILE%\.codex\config.toml

## github.toml

HTTP MCP，需要环境变量 GITHUB_PAT_TOKEN（不要把 token 写进仓库）。

## win10-bridge.toml

把 <USERNAME> 换成实际用户名；依赖本机已安装的 Win10ComputerBridgeMCP 与 bridge_config.json。

## Chrome

Chrome MCP 需要 286 MB 的扩展与 node_repl 组件，因体积与版本锁定原因未放入 Git。
本机原始目录：

D:\云契·小白虎\codex\配置步骤\MCP\Chrome

换电脑时优先使用目标机器 Codex 自带的组件；不要直接混用不同 Codex 版本。

## 完整安装包

工业自动化 MCP 服务器完整安装包（iFA / Inoproshop / 博途）原样保存在 `packages/`，见 `packages/README.md`。
