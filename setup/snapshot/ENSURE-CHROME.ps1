# ENSURE-CHROME.ps1
# Auto-launch Chrome so the Codex ChatGPT extension can connect.
# Launches Chrome only when it is not running AND the Codex desktop
# (ChatGPT.exe) is running, unless -Force is given.
param([switch]$Force)
$ErrorActionPreference = 'SilentlyContinue'
$chrome = Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'
if (-not (Test-Path -LiteralPath $chrome)) {
  Write-Output ('SUMMARY chrome=missing path=' + $chrome)
  exit 1
}
$chromeCount = @(Get-Process chrome -ErrorAction SilentlyContinue).Count
if ($chromeCount -gt 0) {
  Write-Output 'SUMMARY chrome=running (no action)'
  exit 0
}
$codexCount = @(Get-Process ChatGPT -ErrorAction SilentlyContinue).Count
if ((-not $Force) -and ($codexCount -le 0)) {
  Write-Output 'SUMMARY chrome=stopped codex=stopped (skip, use -Force to override)'
  exit 0
}
Start-Process -FilePath $chrome
$started = $false
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Milliseconds 500
  if (@(Get-Process chrome -ErrorAction SilentlyContinue).Count -gt 0) { $started = $true; break }
}
$hostCount = @(Get-Process extension-host -ErrorAction SilentlyContinue).Count
if ($started) {
  Write-Output ('SUMMARY chrome=started extension-host=' + $hostCount)
} else {
  Write-Output 'SUMMARY chrome=failed'
}
