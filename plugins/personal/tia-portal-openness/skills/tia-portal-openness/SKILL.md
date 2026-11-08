---
name: tia-portal-openness
description: Siemens TIA Portal V21 automation via the Openness API. Primary path: 小文老师博途 MCP (node server.js + tia-service.ps1, 30 tools) which wraps the official Openness API and is verified working on cracked V21. Fallback: raw PowerShell Openness API. Use for TIA Portal (博途) project (.ap21) AI access, PLC engineering automation, block/FC/FB/tag creation, LAD Main generation, SCL import.
---

# TIA Portal Openness 自动化

通过 Siemens Openness API 自动化 TIA Portal V21。**首选方法（已实测可用）是「小文老师博途 MCP」（node 版），它封装了官方 Openness API，且在破解版 V21 上 connect/create/save 全部验证通过**；裸 PowerShell Openness API 作为备选参考。

## 方法一（推荐）：小文老师博途 MCP（node 版）

- 包位置：`D:\云契·小白虎\v21 MCP\小文老师MCP\博图MCP\小文老师博途-20251101-v2.1.6\`（目录 + zip 备份齐全）
- 依赖：**零 npm / 零 Python**，只需 Windows 自带 PowerShell 5.1 + Node.js
- 形态：`server.js`（stdio MCP，JSON-RPC over stdin/stdout）+ `tia-service.ps1`（持久 PowerShell worker，实际调用 Openness）
- 30 个工具：`tia_status` `tia_diagnose` `project_list/open/create/save/close` `device_add/list` `catalog_search` `blocks_list/delete/export/rename` `fc_create` `fb_create` `scl_import` `tags_list/create/import` `compile_status` `lad_main_import` `udt_create` `db_fb_create` `password_scan` `stacker_db_deploy/homework` `homework_check` `xiaowen_templates` `xiaowen_deploy`

### 接入方式（stdio MCP）

```json
{
  "serverName": "tia-portal",
  "transport": "stdio",
  "command": "C:\\Program Files\\node-v24.22.2-win-x64\\node.exe",
  "args": ["D:\\云契·小白虎\\v21 MCP\\小文老师MCP\\博图MCP\\小文老师博途-20251101-v2.1.6\\server.js"]
}
```

DSH 侧已配好（`~/.dsh/profiles/desktop/cordis.patch.yml` 的 `- insert:` 块，`toolCallTimeoutMs: 900000`，因 TIA 操作可能阻塞）。其他客户端手动加一条 stdio 服务器 `node "…\server.js"` 即可。

### 前置条件（本机已满足）

1. 本地组 `Siemens TIA Openness` 存在，当前用户 `Administrator` 已是成员（`enable-tia-openness.ps1` 做的是把当前用户加进该组；首次加入后需注销重登一次，令牌才生效）。
2. 完整路径 `C:\Program Files\Siemens\Automation` 存在。

### 首次授权（人工，关键）

**第一次连接博途会弹「Openness 访问」授权窗口，必须人工选「是，全部接受」并确认 UAC，不可自动点击**（建议勾选「不再显示」）。这一步任何脚本都替代不了，也是裸 API 连接报 `Connection to TiaPortal failed.` 的最常见根因。

### 已实测的坑（重要）

1. **首次授权弹窗**：见上。headless/脚本测试点不了这个弹窗，会误判为「破解版连不上」。
2. **必须等 TIA Portal 主窗口完全就绪再连**：Portal 启动过程中调用会阻塞（实测曾卡 4 分钟）；无项目时标题就是 `Siemens`，不代表还在启动。
3. **「Portal 在运行但 Openness 看不到」**（`GetProcesses()=0` 但 `Get-Process` 有 Portal）→ 解法是**彻底关掉 Portal 重开**（崩过之后 Openness 会失联）。
4. 块导入/导出挂起 → 那个块正开在编辑器里，先关掉块编辑器。
5. 报「不是成员」→ 权限脚本没跑或没注销重登。

### 能力边界

- `create_device_from_hardware_catalog=false`、`device_templates` 目录为空 → **无法自动加 PLC**，需人工在 TIA 里加好设备后 MCP 才能读取/组态。
- V21 Openness **没有编译接口**，编译必须人工右键 `PLC_1` → 编译 → 软件（全部编译）。
- Openness 同一时刻只允许一套连接 TIA：多客户端（DSH / WorkBuddy / Codex）别同时连。

---

## 方法二（备选）：裸 Openness API（PowerShell）

```powershell
$dir = "C:\Program Files\Siemens\Automation\Portal V21\PublicAPI\V21\net48"
$dlls = @(Get-ChildItem $dir -Filter "*.dll" | ForEach-Object { $_.FullName })
Add-Type -Path $dlls 2>$null   # LoaderExceptions 是噪声，可忽略
$tia = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
$project = $tia.Projects.Open([System.IO.FileInfo]"C:\path\to\项目.ap21")
foreach ($dev in $project.Devices) { $dev.Name }   # 枚举设备
$project.Close(); $tia.Dispose()
```

### 关键 API
- `TiaPortalMode` 枚举：`WithoutUserInterface` / `WithUserInterface`
- `TiaPortal` 构造：`.ctor(TiaPortalMode)`
- `TiaPortal` 属性：`Projects`(ProjectComposition)、`GlobalLibraries`、`HardwareCatalog`、`LocalSessions`、`ProjectServers`、`SettingsFolders`
- `Project`：`Name`、`Devices`；`Device`：`Name`、`TypeIdentifier`、`DeviceItems`

### 裸 API 的坑（与 MCP 版相通）
1. `Add-Type -Path` 一次加载 14 个 dll 报 `ReflectionTypeLoadException` 是无害噪声，核心 `Siemens.Engineering.dll` 已加载，`[Siemens.Engineering.TiaPortal]` 可直接引用。
2. 不要用 `AppDomain.AssemblyResolve` 处理器加载依赖 → `StackOverflowException`（循环依赖递归），直接 `Add-Type -Path` 数组一次加载。
3. 不要用 `[System.Type]::GetType("Siemens.Engineering.TiaPortal, Siemens.Engineering")` → 返回 NULL，直接用类型字面量。
4. `Connection to TiaPortal failed.` 的**真实**根因（不是许可证！）：①首次 Openness 授权弹窗没人工点「是，全部接受」+UAC；②Portal 还在启动（没等到主窗口就绪）；③Portal 崩过后 Openness 失联（`GetProcesses()=0`），彻底关掉重开即可。

## 参考
- `references/openness-api-reference.md`：Openness API 补充细节。
- `scripts/open_portal.ps1`：可运行模板（加载 dll + Open + 枚举设备 + 输出日志）。
