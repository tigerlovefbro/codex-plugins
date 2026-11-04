# 换电脑恢复说明书（交给 AI 执行）

> 你是我的电脑迁移助手。请严格按本文档一步步执行。
> 标了 **【需要你操作】** 的步骤，停下来告诉我做什么，等我完成后继续。
> 不要擅自升级版本，不要把模型切到官方 OpenAI，不要删除个人插件。

---

## 0. 目标与硬性约束

- Codex 桌面端锁定：**26.707.9564.0**
- Codex CLI 锁定：**0.144.2**
- 模型必须走中转：**https://maoapi.org**，模型 **gpt-5.6-sol**
- 保留：17 个插件、6 个 MCP、全局 AGENTS 规则、task-router / mcp-sync
- 不提交任何 token、密钥到 Git

---

## 1. 先问我要三样东西

**【需要你操作】** 请先问用户要：

1. 中转 token（形如 sk-...）
2. ChatGPT 账号（用于插件页登录）
3. 是否需要 GitHub MCP（需要 PAT）

拿到之前不要猜，也不要把 token 写进仓库。

---

## 2. 安装 Codex（不要升级）

从 Release 下载当前锁定版：

~~~powershell
./setup/releases/download-assets.ps1 -Name "OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0.Msix"
~~~

**【需要你操作】** 双击下载的 MSIX 完成安装。

验证：

~~~powershell
Get-AppxPackage -Name OpenAI.Codex | Select-Object Name,Version
~~~

必须显示 **26.707.9564.0**。如果 Windows 提示更新，先不要更新。

---

## 3. 拉仓库、装插件

~~~powershell
git clone https://github.com/tigerlovefbro/codex-plugins.git D:/data/CodexMarketplaces/codex-plugins
cd D:/data/CodexMarketplaces/codex-plugins
~~~

绑定市场：

~~~powershell
codex plugin marketplace add https://github.com/tigerlovefbro/codex-plugins.git --ref main --sparse '.agents/plugins' --sparse 'plugins'
~~~

安装插件（缺哪个装哪个）：

~~~powershell
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
codex plugin add skill-sync-publisher@awesome-codex-plugins
codex plugin add mcp-sync@awesome-codex-plugins
codex plugin add task-router@awesome-codex-plugins
~~~

安装全局规则：

~~~powershell
./tools/install-global-agents.ps1 -Target codex
~~~

---

## 4. 恢复 config.toml

先备份：

~~~powershell
Copy-Item "$env:USERPROFILE/.codex/config.toml" "$env:USERPROFILE/.codex/config.toml.bak-before-restore" -Force -ErrorAction SilentlyContinue
~~~

把中转 token 放进用户环境变量：

**【需要你操作】** 把 token 交给 AI，由 AI 执行下面命令（不要打印 token）：

~~~powershell
[Environment]::SetEnvironmentVariable('MAOAPI_TOKEN','<中转TOKEN>','User')
~~~

然后合并以下配置到 %USERPROFILE%/.codex/config.toml（保留已有 marketplaces、plugins、desktop 段）：

~~~toml
model_provider = "custom"
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
model_reasoning_summary = "detailed"
model_verbosity = "high"
show_raw_agent_reasoning = true
hide_agent_reasoning = false
model_context_window = 500000
model_auto_compact_token_limit = 500000
personality = "pragmatic"
approval_policy = "never"
sandbox_mode = "danger-full-access"
web_search = "live"
tool_output_token_limit = 100000

[model_providers.custom]
name = "custom"
base_url = "https://maoapi.org"
wire_api = "responses"
requires_openai_auth = true
env_key = "MAOAPI_TOKEN"

[windows]
sandbox = "unelevated"

[features]
js_repl = true
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

[shell_environment_policy]
inherit = "all"
ignore_default_excludes = true

[sandbox_workspace_write]
network_access = true

[analytics]
enabled = false
~~~

### 绝对不能做

- 不要设置 windows.sandbox = "elevated"（会让 codex exec 卡死）
- 不要把 provider 改成官方 openai
- 不要写 experimental_bearer_token（token 只走环境变量）
- 不要升级版本

---

## 5. 登录 ChatGPT（插件页需要）

**【需要你操作】** 在终端或桌面端登录 ChatGPT。

命令行方式：

~~~powershell
codex login
~~~

浏览器完成后验证：

~~~powershell
codex login status
~~~

必须显示 **Logged in using ChatGPT**。

---

## 6. 恢复 MCP

~~~powershell
./plugins/personal/mcp-sync/scripts/restore-mcp.ps1
~~~

恢复后检查：

~~~powershell
codex mcp list --json
~~~

注意：

- node_repl 的路径是旧电脑的，换机后大概率无效，跳过或删除它
- win10-bridge 需要旧电脑的 Python 环境路径，按新机实际路径修改
- github 需要环境变量 GITHUB_PAT_TOKEN，没有就跳过

保留至少 github、chrome-devtools、local-mcp 即可。

---

## 7. 验收

依次执行：

~~~powershell
codex login status
codex plugin list --json
codex mcp list --json
codex exec --skip-git-repo-check "Say OK"
~~~

通过标准：

- 登录：Logged in using ChatGPT
- 插件：17 个，全部 enabled
- MCP：至少 3 个
- exec：返回 OK，不超时

然后打开桌面端“插件”页，确认不再提示“未能加载插件连接”。

---

## 8. 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 未能加载插件连接 | 没登录 ChatGPT | codex login |
| codex exec 卡 120 秒 | windows.sandbox = elevated | 改成 unelevated |
| 技能预算 2% 警告 | 插件技能太多，官方硬编码 | 忽略，或减少技能型插件 |
| 模型元数据缺失警告 | 中转 /models 格式不同 | 忽略，不影响调用 |
| 插件页一直加载 | 插件多、图标渲染慢 | 等 10 秒，或重启桌面端 |
| 模型 401 | MAOAPI_TOKEN 没设置/过期 | 重新设置用户环境变量 |

---

## 9. 完成后的汇报格式

执行完请回复：

1. 版本号
2. 登录状态
3. 插件数量
4. MCP 列表
5. exec 测试结果
6. 哪些【需要你操作】还没做

不要把 token 写进汇报。
