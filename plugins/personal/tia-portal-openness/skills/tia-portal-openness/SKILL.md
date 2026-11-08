---
name: tia-portal-openness
description: Siemens TIA Portal V21 automation via the Openness API (PowerShell/.NET Framework 4.8) - open projects, enumerate devices/PLC blocks, export/compile PLC software, read/write tag tables. Use for TIA Portal (博途) project (.ap21) AI access, PLC engineering automation, block source export and compile diagnostics.
---

# TIA Portal Openness 自动化

通过 Siemens Openness API 在 PowerShell 中自动化 TIA Portal V21：打开项目、枚举设备与 PLC 块、导出块源码、编译、读写 tag table 等。无需 .NET SDK（Windows 内置 .NET Framework 4.8 + PowerShell 5.1 即可）。

## 前置条件
- 本机安装 TIA Portal V21（默认 `C:\Program Files\Siemens\Automation\Portal V21\`）。
- Openness API dll 位于 `PublicAPI\V21\net48\`（14 个 `Siemens.Engineering*.dll`，.NET Framework 4.8）。
- x64 PowerShell 5.1（Windows 自带），无需安装 .NET SDK。
- **TIA Portal 必须有有效许可证且能正常启动**（Openness 依赖 TIA Portal 实例进程）。

## 接入方法（PowerShell）
```powershell
$dir = "C:\Program Files\Siemens\Automation\Portal V21\PublicAPI\V21\net48"
$dlls = @(Get-ChildItem $dir -Filter "*.dll" | ForEach-Object { $_.FullName })
Add-Type -Path $dlls 2>$null   # LoaderExceptions 是噪声，可忽略
$tia = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
$project = $tia.Projects.Open([System.IO.FileInfo]"C:\path\to\项目.ap21")
foreach ($dev in $project.Devices) { $dev.Name }   # 枚举设备
$project.Close(); $tia.Dispose()
```

## 关键 API
- `TiaPortalMode` 枚举：`WithoutUserInterface` / `WithUserInterface`
- `TiaPortal` 构造：`.ctor(TiaPortalMode)`
- `TiaPortal` 属性：`Projects`(ProjectComposition)、`GlobalLibraries`、`HardwareCatalog`、`LocalSessions`、`ProjectServers`、`SettingsFolders`
- `Project`：`Name`、`Devices`；`Device`：`Name`、`TypeIdentifier`、`DeviceItems`

## 已实测的坑（重要）
1. **Add-Type 的 LoaderExceptions 是无害噪声**：`Add-Type -Path` 一次加载 14 个 dll 会报 `ReflectionTypeLoadException`（"无法加载一个或多个请求的类型"），但核心 `Siemens.Engineering.dll` 已加载成功，`[Siemens.Engineering.TiaPortal]` 可直接引用。用 `2>$null` 抑制即可。
2. **不要用 AppDomain.AssemblyResolve 处理器**加载依赖 —— 会 `StackOverflowException`（程序集循环依赖导致递归）。直接 `Add-Type -Path` 数组一次加载即可。
3. **不要用 `[System.Type]::GetType("Siemens.Engineering.TiaPortal, Siemens.Engineering")`** —— 返回 NULL（assembly 限定名不匹配）。直接用 `[Siemens.Engineering.TiaPortal]` 类型字面量。
4. **`New-Object TiaPortal(...)` 报 "Connection to TiaPortal failed."**（MethodInvocationException，inner 相同）—— 根因是 TIA Portal 实例无法启动：本机 `Bin\Siemens.Automation.Portal.exe` 启动后立即退出（无 Portal 进程存活）。排查方向：①Automation License Manager 许可证是否激活/未过期；②应通过 TIA Admin / SienStart 启动而非直接运行 exe；③Openness 后端 `Bin\Siemens.Automation.Portal.LocalServer.exe` 是否可用。

## 进阶：MCP server
- `Czarnak/tia-portal-mcp`（GitHub，MIT）：专为 TIA Portal V21 Openness 的 MCP server，9 read-only / 21 read-write 工具（PLC block 导出导入 / tag table / WinCC HMI / VCI / 库 / 交叉引用 / 编译诊断）。需 .NET 10 SDK（本机若无，`dotnet --version` 报 "No .NET SDKs were found"）。
- 官方 `siemens/tia-portal-openness-code-snippets`（C# 代码片段）。

## 参考
- `references/openness-api-reference.md`：Openness API 补充细节。
- `scripts/open_portal.ps1`：可运行模板（加载 dll + Open + 枚举设备 + 输出日志）。
