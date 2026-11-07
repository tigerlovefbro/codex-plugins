# INSTALL-ENSURE-CHROME.ps1
# Installs the auto-launch watchdog for Chrome, so the Codex ChatGPT
# extension always has a browser to connect to.
#
# - Copies ENSURE-CHROME.ps1 to %USERPROFILE%\.codex\ensure-chrome.ps1
# - Registers scheduled task CodexEnsureChrome (at logon + every 2 min)
# - Runs it once immediately
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\INSTALL-ENSURE-CHROME.ps1

$ErrorActionPreference = 'Stop'
$TaskName = 'CodexEnsureChrome'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Patch    = Join-Path $ScriptDir 'ENSURE-CHROME.ps1'
$Dest     = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex\ensure-chrome.ps1'

if (-not (Test-Path -LiteralPath $Patch)) { throw "Patch script not found: $Patch" }
Copy-Item -LiteralPath $Patch -Destination $Dest -Force
Write-Output ('[1/3] ensure-chrome copied -> ' + $Dest)

$Action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $Dest + '"')
$T1 = New-ScheduledTaskTrigger -AtLogOn
$T2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2)
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 72) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($T1,$T2) -Settings $Settings -Force | Out-Null
Write-Output ("[2/3] scheduled task '" + $TaskName + "' registered (logon + every 2 min)")

& $Dest
Write-Output '[3/3] ran once now'
