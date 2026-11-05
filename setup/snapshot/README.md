# 本机 Codex 桌面端快照（2026-11-05）

这个目录把 **当前正在用的 Codex / ChatGPT 桌面端** 完整固化进仓库：版本、配置、提示词、插件市场、启动器。
换电脑或重装后，按 `../NEW-MACHINE.md` 走一遍即可还原成同一套环境。

## 目录内容

| 路径 | 说明 |
|---|---|
| `VERSION.json` | 版本指纹：MSIX 版本、CLI 版本、模型/中转配置、插件清单、文件哈希 |
| `codex/config.toml` | 主配置逐字节副本（含中转 provider、18 个插件、MCP、桌面端设置、主题） |
| `codex/prompts/system-prompt.md` | **不在公开仓库** —— 自定义系统提示词放在私有仓库 `tigerlovefbro/codex-private`（`model_instructions_file` 指向它） |
| `codex/AGENTS.md` | Codex 全局规则 |
| `launchers/` | 提权启动器、解包副本更新脚本、清理脚本、桌面快捷方式 |
| `extension/com.openai.codexextension.json` | Chrome 原生消息宿主清单 |
| `APPLY.ps1` | 把快照写回 `%USERPROFILE%\.codex`（带备份、路径修正、env 变量检查） |
| `CHECK.ps1` | 逐项校验：版本 / hosts / env / 配置哈希 / 插件数 / 登录 / exec |

## 刻意不入库的东西

| 内容 | 原因 | 还原方式 |
|---|---|---|
| `auth.json`（ChatGPT 登录令牌） | 是账号凭据，会过期 | 新机 `codex login` 重新登录 |
| 系统提示词原文、中转地址真值 | 内容敏感，公开仓库不适合承载 | 私有仓库 [`tigerlovefbro/codex-private`](https://github.com/tigerlovefbro/codex-private) |
| `MAOAPI_TOKEN` / `GITHUB_PAT_TOKEN` | 是密钥 | 由你重新填，`APPLY.ps1 -AskSecrets` 会提示 |
| `logs_2.sqlite`(177 MB) / `sessions/`(100 MB) / 缓存 | 体积大、无还原价值 | 登录后自动重建 |
| 会话列表 / 对话正文 | 服务端保存，凭账号同步 | 登录后自动出现 |
| MSIX 安装包（671–975 MB） | 超 GitHub 单文件限制 | GitHub Releases 附件 `assets-20261104` |

## 还原顺序（最短路径）

~~~powershell
# 1. 装锁定版本（26.707.9564.0），不要升级
./setup/releases/download-assets.ps1 -Name "OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0.Msix"
# 2. 写回配置（中转地址是占位符，见第 2.5 步）
./setup/snapshot/APPLY.ps1 -FixPaths -AskSecrets
# 2.5 敏感部分：系统提示词 + 真实中转地址（私有仓库）
git clone https://github.com/tigerlovefbro/codex-private
./codex-private/APPLY-PRIVATE.ps1 -FixPaths
# 3. 登录 ChatGPT 账号（中转链路靠这个令牌）
codex login
# 4. 校验
./setup/snapshot/CHECK.ps1
~~~

## 注意

- `prompts/system-prompt.md`（含 NSFW/R18 放行条款）与中转地址真值已移到私有仓库 `tigerlovefbro/codex-private`。公开的 `config.toml` 里 `base_url` 是占位符 `https://YOUR-RELAY-HOST`，跑 `APPLY.ps1` 之后必须再跑私有仓库的 `APPLY-PRIVATE.ps1` 覆盖成真实值。
- `config.toml` 里写死了 `C:\Users\Administrator` 和 `D:\data\ChatGPT-unpacked` 路径；换机请用 `APPLY.ps1 -FixPaths`，或手改这几处：
  `model_instructions_file`、`notify`、`mcp_servers.node_repl` 的 command/env。
- 提权副本（`D:\data\ChatGPT-unpacked`）不是必须的：只在需要管理员权限跑桌面端时才要。做法是把 MSIX 安装目录 `app\` 整个 robocopy 出来，再放上 `launchers/` 里的启动器。
- 更新锁定靠 hosts 屏蔽 3 个域名，脚本在 `../lock-version/`。
