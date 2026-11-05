# 换电脑恢复说明书（交给 AI 执行）

> 你是我的电脑迁移助手。请严格按本文档一步步执行。
> 标了 **【需要你操作】** 的步骤，停下来告诉我做什么，等我完成后继续。
> 不要擅自升级版本，不要把模型切到官方 OpenAI，不要删除个人插件。
>
> 快照文件在 `setup/snapshot/`（2026-11-05 采集）。本文与快照冲突时，以 `setup/snapshot/VERSION.json` 为准。
> 敏感部分（自定义系统提示词、中转地址真值）在私有仓库 tigerlovefbro/codex-private；公开仓库只有占位符，最后要跑一次那边的 `APPLY-PRIVATE.ps1`。

---

## 0. 目标与硬性约束

- Codex 桌面端锁定：**26.707.9564.0**（应用内 build 26.707.71524，Chromium 150.0.7871.115）
- Codex CLI 锁定：**0.144.2**
- 模型必须走中转：地址见私有仓库 **codex-private**（公开仓库里是占位符 `https://YOUR-RELAY-HOST`），模型 **gpt-5.6-sol**，reasoning **xhigh**，上下文 500k
- 登录方式：**ChatGPT 账号登录**（`auth_mode=chatgpt`），令牌随请求发往中转；另有用户环境变量 **MAOAPI_TOKEN**
- 保留：**18 个插件**、**3 个 config 内 MCP**（node_repl / github / win10-bridge）+ `personal/mcp` 里 6 份备份、全局 AGENTS 规则、桌面端主题与偏好
- 更新通道：hosts 屏蔽 `cdn.openai.com`、`updates.openai.com`、`persistent.oaistatic.com`
- 不提交任何 token、密钥到 Git

---

## 1. 先问我要三样东西

**【需要你操作】** 请先问用户要：

1. 中转 token（填进 `MAOAPI_TOKEN` 用户环境变量）
2. ChatGPT 账号（用于 `codex login`，中转链路靠这个账号令牌）
3. 是否需要 GitHub MCP（需要 `GITHUB_PAT_TOKEN`）

拿到之前不要猜，也不要把 token 写进仓库或写进 `config.toml`。

---

## 2. 安装 Codex（不要升级）

从 Release 下载锁定版：

~~~powershell
./setup/releases/download-assets.ps1 -Name "OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0.Msix"
~~~

**【需要你操作】** 双击下载的 MSIX 完成安装。

验证：

~~~powershell
Get-AppxPackage -Name OpenAI.Codex | Select-Object Name,Version
~~~

必须显示 **26.707.9564.0**。如果 Windows 提示更新，先不要更新。

> 装完后先做第 8 步（hosts 锁更新），否则商店会在后台把它升走。

---

## 3. 拉仓库、绑市场、装插件

~~~powershell
git clone https://github.com/tigerlovefbro/codex-plugins.git D:/data/CodexMarketplaces/codex-plugins
cd D:/data/CodexMarketplaces/codex-plugins
~~~

绑定市场（3 个，其中 awesome-codex-plugins 就是本仓库的 fork）：

~~~powershell
codex plugin marketplace add https://github.com/tigerlovefbro/codex-plugins.git --ref main --sparse '.agents/plugins' --sparse 'plugins'
codex plugin marketplace add https://github.com/zhongjingyun/codex-plugins.git --ref main --sparse '.agents/plugins' --sparse 'plugins'
~~~

安装 18 个插件（缺哪个装哪个）：

~~~powershell
codex plugin add visualize@openai-bundled
codex plugin add computer-use@openai-bundled
codex plugin add latex@openai-bundled
codex plugin add chrome@openai-bundled
codex plugin add stop-that-shit@awesome-codex-plugins
codex plugin add claude-octopus@awesome-codex-plugins
codex plugin add research-agent-skills@awesome-codex-plugins
codex plugin add firecrawl@awesome-codex-plugins
codex plugin add codex-mem@awesome-codex-plugins
codex plugin add codex-reviewer@awesome-codex-plugins
codex plugin add chrome-devtools@awesome-codex-plugins
codex plugin add local-mcp@awesome-codex-plugins
codex plugin add codex-usage-tracker@awesome-codex-plugins
codex plugin add codex-auto-resume@awesome-codex-plugins
codex plugin add mcp-sync@awesome-codex-plugins
codex plugin add skill-sync-publisher@awesome-codex-plugins
codex plugin add task-router@awesome-codex-plugins
codex plugin add agency-continuity-audit@awesome-codex-plugins
~~~

安装全局规则：

~~~powershell
./tools/install-global-agents.ps1 -Target codex
~~~

---

## 4. 恢复 config.toml / AGENTS / 系统提示词

**推荐：直接用快照脚本**（会自动备份旧文件）：

~~~powershell
./setup/snapshot/APPLY.ps1 -FixPaths -AskSecrets
~~~

- `-FixPaths`：把快照里写死的 `C:\Users\Administrator` 换成当前用户名，把 `D:\data\ChatGPT-unpacked` 换成你的解包目录（默认同路径）
- `-AskSecrets`：交互式读入 `MAOAPI_TOKEN` / `GITHUB_PAT_TOKEN`，写入用户环境变量，不回显

**敏感部分不在公开仓库**（系统提示词、真实中转地址）：

~~~powershell
git clone https://github.com/tigerlovefbro/codex-private
./codex-private/APPLY-PRIVATE.ps1 -FixPaths
~~~

不跑脚本时，手工要点：

~~~powershell
[Environment]::SetEnvironmentVariable('MAOAPI_TOKEN','<中转TOKEN>','User')
[Environment]::SetEnvironmentVariable('GITHUB_PAT_TOKEN','<PAT>','User')
Copy-Item setup/snapshot/codex/config.toml "$env:USERPROFILE/.codex/config.toml"
Copy-Item setup/snapshot/codex/AGENTS.md "$env:USERPROFILE/.codex/AGENTS.md"
# 系统提示词与真实 base_url 在私有仓库: codex-private/prompts/system-prompt.md
# 拷到 %USERPROFILE%\.codex\prompts\ 并把 config.toml 的 base_url 换成真实中转地址
~~~

### 必须存在的关键段（快照已包含，核对用）

~~~toml
model_provider = "custom"
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
model_reasoning_summary = "detailed"
model_verbosity = "high"
model_context_window = 500000
model_auto_compact_token_limit = 500000
model_instructions_file = 'C:\Users\<你>\.codex\prompts\system-prompt.md'
personality = "pragmatic"
approval_policy = "never"
sandbox_mode = "danger-full-access"
web_search = "live"
show_raw_agent_reasoning = true

[model_providers.custom]
name = "custom"
base_url = "https://YOUR-RELAY-HOST"   # 真值见私有仓库 codex-private
wire_api = "responses"
requires_openai_auth = true
env_key = "MAOAPI_TOKEN"

[windows]
sandbox = "unelevated"

[features]
js_repl = false
hooks = true
unified_exec = true
shell_snapshot = true
multi_agent = true
memories = true
undo = true
codex_git_commit = true

[agents]
max_threads = 8

[tools]
web_search = { context_size = "high" }
view_image = true

[history]
persistence = "save-all"

[sandbox_workspace_write]
network_access = true

[analytics]
enabled = false
~~~

桌面端偏好也都在 config 的 `[desktop]` 段（深色 + github 代码主题 + 14/12 号字 + 外链走系统浏览器 + 下载目录 `D:\data\gpt data`），无需单独设置。

### 绝对不能做

- 不要设置 `windows.sandbox = "elevated"`（会让 codex exec 卡死）
- 不要把 provider 改成官方 openai
- 不要写 `experimental_bearer_token`（token 只走环境变量）
- 不要升级版本
- 不要把 `auth.json` 或任何 token 提交进仓库

---

## 5. 登录 ChatGPT（中转链路必需）

**【需要你操作】** 在桌面端登录，或在终端执行：

~~~powershell
codex login
~~~

浏览器授权完成后验证：

~~~powershell
codex login status
~~~

必须显示 **Logged in using ChatGPT**。

原理：`requires_openai_auth = true` + `model_providers.custom.base_url = <中转地址>`，登录拿到的 ChatGPT 访问令牌会随请求发到中转站；环境变量 `MAOAPI_TOKEN` 供中转鉴权/备用密钥。`auth.json` 不随仓库走，换机后重新登录即可，旧令牌本来也会过期。

---

## 6. 恢复 MCP

~~~powershell
./plugins/personal/mcp-sync/scripts/restore-mcp.ps1
~~~

恢复后：

~~~powershell
codex mcp list --json
~~~

注意：

- `node_repl` 指向解包副本里的 node（`D:\data\ChatGPT-unpacked\app\resources\cua_node`），没做解包副本就删掉这段
- `win10-bridge` 需要 `C:\Users\Administrator\AppData\Local\Win10ComputerBridgeMCP\venv313\Scripts\python.exe` 与 `C:\Users\Administrator\Win10_ComputerBridge\bridge_config.json`，路径变了要改
- `github` 需要 `GITHUB_PAT_TOKEN`，没有就跳过
- 最低要求：`github` + `chrome-devtools` + `local-mcp` 三个能用

---

## 7. 可选：提权用的解包副本

MSIX 包本身不能以管理员身份运行。需要管理员模式时：

1. 把安装目录 `C:\Program Files\WindowsApps\OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0\app\` 整个 robocopy 到 `D:\data\ChatGPT-unpacked\app\`
2. 拷 `setup/snapshot/launchers/` 里的 4 个文件到 `D:\data\ChatGPT-unpacked\`
3. 桌面快捷方式 `ChatGPT (Admin).lnk` 的目标是 `wscript.exe "D:\data\ChatGPT-unpacked\Launch-ChatGPT-Elevated.vbs"`
4. 版本更新后（万一解锁了更新）跑 `Update-ChatGPT-Unpacked.ps1` 重新同步

不需要提权就跳过这步。

---

## 8. 锁定版本（hosts 屏蔽更新）

需要管理员，双击或：

~~~powershell
powershell -ExecutionPolicy Bypass -File ./setup/lock-version/lock-openai-updates.ps1
~~~

会备份 hosts，并写入 3 行：

~~~
0.0.0.0 cdn.openai.com
0.0.0.0 updates.openai.com
0.0.0.0 persistent.oaistatic.com
~~~

想恢复更新跑 `restore-openai-updates.ps1`。

---

## 9. 验收

~~~powershell
./setup/snapshot/CHECK.ps1 -RunExec
~~~

会逐项对比：桌面端版本 / CLI 版本 / 模型与中转 / 插件数 18 / 3 个市场 / hosts 3 条 / 两个 env 变量存在性 / 登录状态 / exec 冒烟。

通过标准：

- 桌面端 26.707.9564.0
- CLI 0.144.2
- 登录 Logged in using ChatGPT
- 插件 18 个全部 enabled
- MCP 至少 3 个
- `codex exec "Say OK"` 返回 OK 且不超时

再打开桌面端“插件”页，确认不再提示“未能加载插件连接”。

---

## 10. 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 未能加载插件连接 | 没登录 ChatGPT | `codex login` |
| codex exec 卡 120 秒 | `windows.sandbox = elevated` | 改成 `unelevated` |
| 技能预算 2% 警告 | 插件技能太多，官方硬编码 | 忽略，或减少技能型插件 |
| 模型元数据缺失警告 | 中转 `/models` 格式不同 | 忽略，不影响调用 |
| 插件页一直加载 | 插件多、图标渲染慢 | 等 10 秒或重启桌面端 |
| 模型 401 | MAOAPI_TOKEN 没设置/过期 | 重新设置用户环境变量 |
| 设置后不生效 | 桌面端只在启动时读 config | 完全退出再启动 |
| 提示更新 | hosts 锁被移除/商店强更 | 重跑 lock 脚本；必要时装回锁定版 MSIX |
| 用户名不是 Administrator | config 里路径写死 | `APPLY.ps1 -FixPaths` |

---

## 11. 完成后的汇报格式

执行完请回复：

1. 版本号（桌面端 / CLI）
2. 登录状态
3. 插件数量
4. MCP 列表
5. exec 测试结果
6. 哪些【需要你操作】还没做

不要把 token 写进汇报。
