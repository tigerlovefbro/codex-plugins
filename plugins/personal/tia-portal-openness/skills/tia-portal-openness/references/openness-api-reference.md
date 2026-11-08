# Openness API 补充细节

## 加载顺序（已实测）
- 一次性 `Add-Type -Path` 加载 `PublicAPI\V21\net48\` 全部 14 个 `Siemens.Engineering*.dll`，核心类型可用。
- dll 清单（V21 net48）：Siemens.Engineering.AddIn.Base / AddIn.Permissions / AddIn.Safety / AddIn.Step7 / AddIn.Utilities / Base / Safety / SafetyValidation / Startdrive / Step7 / TeamcenterGateway / WinCC / WinCC.Extension / WinCCUnified。

## TiaPortal 静态方法
- `GetProcesses()` -> IList<TiaPortalProcess>
- `GetProcess(Int32, Int32)` / `GetProcess(Int32, TimeSpan)` -> TiaPortalProcess

## 常用操作（C# Openness 对应，PowerShell 可译）
- 打开项目：`tia.Projects.Open(new FileInfo(path))`
- 枚举设备：`project.Devices`
- PLC 块导出：`plcBlock.Export(new FileInfo(dir), ExportOptions.WithDefaults)`
- 编译：`plcSoftware.Compile()`
- 关闭：`project.Close()`、`tia.Dispose()`

## 本机实测环境
- TIA Portal V21：C:\Program Files\Siemens\Automation\Portal V21\
- PowerShell 5.1.19041.6033，.NET Framework 4.0.30319.42000（=4.8），管理员权限
- 相关服务：SiemensTiaAdminV3 Running / SiemensTiaAdmin Stopped / s7oiehsx64 Running
- 主程序：Bin\Siemens.Automation.Portal.exe（直接启动后立即退出）
