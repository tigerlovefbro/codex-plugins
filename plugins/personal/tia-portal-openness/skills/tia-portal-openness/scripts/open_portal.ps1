# TIA Portal V21 Openness 可运行模板
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File open_portal.ps1
# 作用：加载 Openness dll -> 打开 TIA Portal -> 打开项目 -> 枚举设备 -> 输出日志
param(
  [string]$ProjectPath = "C:\Users\Administrator\Documents\Automation\项目1\项目1.ap21"
)
$dir = "C:\Program Files\Siemens\Automation\Portal V21\PublicAPI\V21\net48"
$dlls = @(Get-ChildItem $dir -Filter "*.dll" | ForEach-Object { $_.FullName })
Add-Type -Path $dlls 2>$null

$log = Join-Path $PSScriptRoot "open_portal.log"
$sb = New-Object System.Text.StringBuilder
function w($s) { $null = $sb.AppendLine([string]$s) }

try {
  w "Open TIA Portal (WithoutUserInterface)..."
  $tia = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
  w "TiaPortal ok"
  try {
    $project = $tia.Projects.Open([System.IO.FileInfo]$ProjectPath)
    w ("project name=" + $project.Name)
    w ("devices=" + $project.Devices.Count)
    foreach ($dev in $project.Devices) {
      w ("  dev=" + $dev.Name + " [" + $dev.TypeIdentifier + "]")
      foreach ($item in $dev.DeviceItems) { w ("    item=" + $item.Name) }
    }
    $project.Close()
    w "project closed"
  } catch {
    w ("project open FAIL: " + $_.Exception.Message)
  }
  $tia.Dispose()
  w "tia disposed"
} catch {
  w ("tia open FAIL: " + $_.Exception.Message)
  if ($_.Exception.InnerException) { w ("inner: " + $_.Exception.InnerException.Message) }
}
[System.IO.File]::WriteAllText($log, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host $sb.ToString()
