# INSTALL-FIX-CHROME-PLUGIN.ps1
# Installs the self-healing patch for the openai-bundled Chrome/Browser plugins.
# Fixes "TypeError: Cannot redefine property: process" on Codex Desktop 26.707.71524.
#
# Codex Desktop re-extracts the bundled plugins from a read-only WindowsApps source
# on every startup, reverting any patch. This installer copies the patch script to
# %USERPROFILE%\.codex\fix-chrome-plugin.ps1 and registers a scheduled task that
# re-applies the patch every 2 minutes, so the fix survives restarts.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\INSTALL-FIX-CHROME-PLUGIN.ps1

$ErrorActionPreference = 'Stop'

$TaskName = 'CodexChromePluginFix'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Patch    = Join-Path $ScriptDir 'FIX-CHROME-PLUGIN.ps1'
$Dest     = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex\fix-chrome-plugin.ps1'

# 1. Copy the idempotent patch script next to the .codex dir.
if (-not (Test-Path -LiteralPath $Patch)) { throw "Patch script not found: $Patch" }
Copy-Item -LiteralPath $Patch -Destination $Dest -Force
Write-Output ('[1/3] patch copied -> ' + $Dest)

# 2. Register (or refresh) the scheduled task that re-applies every 2 minutes.
$Action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $Dest + '"')
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2)
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 72) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force | Out-Null
Write-Output ("[2/3] scheduled task '" + $TaskName + "' registered (every 2 min)")

# 3. Apply the patch once immediately.
& $Dest
Write-Output '[3/3] patch applied now'
