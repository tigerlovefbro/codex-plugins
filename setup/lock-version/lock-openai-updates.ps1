# ============================================================
#  锁定 OpenAI / Codex 更新(维持当前版本)
#  当前锁定版本: Codex 桌面端 26.707.71524 / CLI 0.144.2(2026-11-01)
#  方式: hosts 屏蔽更新域名(幂等,可重复运行)
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

# --- 需要屏蔽的更新域名 ---
$blockDomains = @('cdn.openai.com', 'updates.openai.com', 'persistent.oaistatic.com')

$lines = Get-Content $hostsFile -ErrorAction SilentlyContinue
$changed = $false
foreach ($d in $blockDomains) {
    if ($lines -match [regex]::Escape($d)) {
        Write-Host "[已锁定,跳过] $d" -ForegroundColor Yellow
    } else {
        $lines += "0.0.0.0 $d"
        Write-Host "[已锁定] $d" -ForegroundColor Green
        $changed = $true
    }
}
# 一次性写回,避免多次打开 hosts 文件
if ($changed) { $lines | Set-Content -Path $hostsFile -Encoding ASCII }

# --- 刷新 DNS 缓存,立即生效 ---
ipconfig /flushdns | Out-Null
Write-Host "DNS 缓存已刷新" -ForegroundColor Cyan

Write-Host "`n当前 hosts 活跃条目:" -ForegroundColor White
Get-Content $hostsFile | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }

Write-Host "`n版本已锁定: Codex 26.707.71524 / CLI 0.144.2" -ForegroundColor Green
if ($args -notcontains '-NoWait') { Read-Host "`n按回车退出" }