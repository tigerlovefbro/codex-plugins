# ============================================================
#  恢复 OpenAI / Codex 更新(解除版本锁定)
#  方式: 从 hosts 中移除 3 个 OpenAI 更新域名的屏蔽行
#  使用: 双击同名 .bat 运行,或右键本文件 -> 使用 PowerShell 运行
# ============================================================
$ErrorActionPreference = 'Stop'

# --- 自动以管理员身份重新运行 ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    exit
}

$hostsFile = 'C:\Windows\System32\drivers\etc\hosts'
$scriptDir = Split-Path -Parent $PSCommandPath

# --- 备份当前 hosts 到脚本目录 ---
$bak = Join-Path $scriptDir ('hosts.backup.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
Copy-Item $hostsFile $bak -Force
Write-Host "已备份 hosts -> $bak" -ForegroundColor Cyan

# --- 要解除屏蔽的域名 ---
$unblockDomains = @('cdn\.openai\.com', 'updates\.openai\.com', 'persistent\.oaistatic\.com')

$content = Get-Content $hostsFile -ErrorAction SilentlyContinue
$before = $content.Count
foreach ($r in $unblockDomains) {
    $content = $content | Where-Object { $_ -notmatch $r }
}
# 写回(保留 hosts 中其他所有内容)
$content | Set-Content -Path $hostsFile -Encoding ASCII
$removed = $before - $content.Count

# --- 刷新 DNS 缓存,立即生效 ---
ipconfig /flushdns | Out-Null
Write-Host "DNS 缓存已刷新,共移除 $removed 条屏蔽" -ForegroundColor Cyan

Write-Host "`n当前 hosts 活跃条目:" -ForegroundColor White
Get-Content $hostsFile | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }

Write-Host "`n已恢复更新通道(OpenAI 应用下次启动时自动检查更新)" -ForegroundColor Green
if ($args -notcontains '-NoWait') { Read-Host "`n按回车退出" }