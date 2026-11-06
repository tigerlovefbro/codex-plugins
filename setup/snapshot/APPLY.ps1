# 把 setup/snapshot 写回本机 Codex 配置
# 用法:
#   ./APPLY.ps1                 # 写配置(自动备份旧文件)
#   ./APPLY.ps1 -FixPaths       # 同时把快照里的旧用户名/解包路径改成当前机器
#   ./APPLY.ps1 -AskSecrets     # 提示输入 MAOAPI_TOKEN / GITHUB_PAT_TOKEN 并写入用户环境变量
# 不会打印任何密钥内容。

param(
    [switch]$FixPaths,
    [switch]$AskSecrets,
    [string]$UnpackedDir = 'D:\data\ChatGPT-unpacked'
)

$ErrorActionPreference = 'Stop'
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$codex = Join-Path $env:USERPROFILE '.codex'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Ensure-Dir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Backup-File([string]$p) {
    if (Test-Path $p) {
        $bak = "$p.bak-$stamp"
        Copy-Item $p $bak -Force
        Write-Host "[备份] $bak" -ForegroundColor DarkGray
    }
}

Write-Host "== 1. 目录准备 ==" -ForegroundColor Cyan
Ensure-Dir $codex
Ensure-Dir (Join-Path $codex 'prompts')

Write-Host "== 2. 写回配置文件 ==" -ForegroundColor Cyan
Backup-File (Join-Path $codex 'config.toml')
Backup-File (Join-Path $codex 'AGENTS.md')
Backup-File (Join-Path $codex 'prompts\system-prompt.md')

$cfg = Get-Content (Join-Path $here 'codex\config.toml') -Raw -Encoding UTF8
if ($FixPaths) {
    $oldHome = 'C:\Users\Administrator'
    $newHome = $env:USERPROFILE
    $cfg = $cfg.Replace($oldHome, $newHome)
    $cfg = $cfg.Replace('D:\data\ChatGPT-unpacked', $UnpackedDir.TrimEnd('\'))
    Write-Host "[路径] 已替换 $oldHome -> $newHome ; 解包目录 -> $UnpackedDir" -ForegroundColor Yellow
}
[System.IO.File]::WriteAllText((Join-Path $codex 'config.toml'), $cfg, (New-Object System.Text.UTF8Encoding $false))

Copy-Item (Join-Path $here 'codex\AGENTS.md') (Join-Path $codex 'AGENTS.md') -Force
$prmSrc = Join-Path $here 'codex\prompts\system-prompt.md'
if (Test-Path $prmSrc) {
    Copy-Item $prmSrc (Join-Path $codex 'prompts\system-prompt.md') -Force
    Write-Host "config.toml / AGENTS.md / prompts\system-prompt.md 已写入 $codex" -ForegroundColor Green
} else {
    Write-Host "config.toml / AGENTS.md 已写入 $codex" -ForegroundColor Green
    Write-Host "[跳过] 公开仓库不含 system-prompt.md，现有提示词未改动；需要时用私有仓库 codex-private 的 APPLY-PRIVATE.ps1" -ForegroundColor Yellow
    if ($cfg -match 'YOUR-RELAY-HOST') {
        Write-Host "[注意] config.toml 里 base_url 仍是占位符，跑 APPLY-PRIVATE.ps1 或手动替换后再用" -ForegroundColor Yellow
    }
}

Write-Host "== 3. Chrome 原生消息宿主清单 ==" -ForegroundColor Cyan
$extDir = Join-Path $env:LOCALAPPDATA 'OpenAI\extension'
Ensure-Dir $extDir
Copy-Item (Join-Path $here 'extension\com.openai.codexextension.json') (Join-Path $extDir 'com.openai.codexextension.json') -Force
Write-Host "已写入 $extDir" -ForegroundColor Green

Write-Host "== 4. 环境变量（密钥） ==" -ForegroundColor Cyan
foreach ($n in @('MAOAPI_TOKEN','GITHUB_PAT_TOKEN')) {
    if ([Environment]::GetEnvironmentVariable($n,'User')) {
        Write-Host "[已存在] $n" -ForegroundColor DarkGray
        continue
    }
    if ($AskSecrets) {
        $sec = Read-Host -AsSecureString "请输入 $n (留空跳过)"
        $val = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
        if ($val) { [Environment]::SetEnvironmentVariable($n, $val, 'User'); Write-Host "[已设置] $n" -ForegroundColor Green }
        else { Write-Host "[跳过] $n" -ForegroundColor Yellow }
    } else {
        Write-Host "[缺少] $n —— 重跑并加 -AskSecrets，或手动 SetEnvironmentVariable" -ForegroundColor Yellow
    }
}

Write-Host "== 5. 版本核对 ==" -ForegroundColor Cyan
$pkg = Get-AppxPackage -Name OpenAI.Codex
if ($pkg) {
    Write-Host ("已安装: " + $pkg.Version) -ForegroundColor Green
    if ($pkg.Version.ToString() -ne '26.707.9564.0') {
        Write-Host "警告: 快照锁定 26.707.9564.0，当前不是该版本（升级后配置多半仍可用，但 UI/插件行为可能变）" -ForegroundColor Yellow
    }
} else {
    Write-Host "未检测到 OpenAI.Codex 包。先跑 setup/releases/download-assets.ps1 装锁定版本。" -ForegroundColor Red
}

Write-Host "== 6. 后续手动步骤 ==" -ForegroundColor Cyan
Write-Host @"
1) 登录 ChatGPT 账号:        codex login           (走中转链路必须登录)
2) 绑定插件市场:             codex plugin marketplace add https://github.com/tigerlovefbro/codex-plugins.git --ref main --sparse '.agents/plugins' --sparse 'plugins'
3) 锁定版本(需管理员):        powershell -File ..\lock-version\lock-openai-updates.ps1
4) 校验:                     ./CHECK.ps1
5) 重启桌面端(配置在启动时读取)
"@ -ForegroundColor White
