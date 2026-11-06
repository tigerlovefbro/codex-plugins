# FIX-MARKETPLACE.ps1
# One-click repair for Codex marketplace "marketplace root does not contain a supported manifest".
# Root cause: background Git marketplace refresh (sparse-checkout) drops .agents/plugins/marketplace.json
# from the snapshot dir under %USERPROFILE%\.codex\.tmp\marketplaces\<name>.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File FIX-MARKETPLACE.ps1            # detect + repair + verify
#   powershell -NoProfile -ExecutionPolicy Bypass -File FIX-MARKETPLACE.ps1 -CheckOnly # detect only
#   powershell -NoProfile -ExecutionPolicy Bypass -File FIX-MARKETPLACE.ps1 -BackupCfg  # also back up config.toml first

param(
    [switch]$CheckOnly,
    [switch]$BackupCfg
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$codex = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin\3135b80b111fd431\codex.exe'
$tmpRoot = Join-Path $env:USERPROFILE '.codex\.tmp\marketplaces'
$cfgPath = Join-Path $env:USERPROFILE '.codex\config.toml'

# Marketplace name -> local repo root that contains a good .agents/plugins/marketplace.json
$markets = [ordered]@{
    'awesome-codex-plugins' = 'D:\data\CodexMarketplaces\codex-plugins'
}

# Optional backup of config.toml (best practice before any config writes)
if ($BackupCfg -and (Test-Path $cfgPath)) {
    $bakDir = Join-Path $env:USERPROFILE '.codex\backups\config'
    New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $bak = Join-Path $bakDir ("config.toml." + $stamp + ".marketplace-fix.bak")
    Copy-Item -LiteralPath $cfgPath -Destination $bak -Force
    Write-Host "[backup] config.toml -> $bak" -ForegroundColor DarkGray
}

function Get-ManifestPath([string]$mkt) {
    Join-Path $tmpRoot "$mkt\.agents\plugins\marketplace.json"
}

function Test-Manifest([string]$mkt) {
    return (Test-Path (Get-ManifestPath $mkt))
}

function Repair-Manifest([string]$mkt, [string]$srcRepo) {
    $dst = Join-Path $tmpRoot "$mkt\.agents\plugins"
    $src = Join-Path $srcRepo '.agents\plugins\marketplace.json'
    if (-not (Test-Path $src)) {
        Write-Host "  [FAIL] source manifest missing: $src" -ForegroundColor Red
        return $false
    }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -LiteralPath $src -Destination (Join-Path $dst 'marketplace.json') -Force
    $sz = (Get-Item (Join-Path $dst 'marketplace.json')).Length
    Write-Host "  [OK] restored marketplace.json ($sz bytes) -> $dst" -ForegroundColor Green
    return $true
}

$broken = @()
$repaired = @()

Write-Host '== Detect =='
foreach ($mkt in $markets.Keys) {
    if (Test-Manifest $mkt) {
        Write-Host "[OK]   $mkt : manifest present" -ForegroundColor Green
    } else {
        Write-Host "[BROKEN] $mkt : manifest MISSING" -ForegroundColor Yellow
        $broken += $mkt
    }
}

if ($broken.Count -eq 0) {
    Write-Host "All marketplaces OK, nothing to repair." -ForegroundColor Green
} elseif ($CheckOnly) {
    Write-Host "Broken marketplaces: $($broken -join ', ')" -ForegroundColor Yellow
    Write-Host "Run without -CheckOnly to repair." -ForegroundColor Yellow
} else {
    Write-Host ''
    Write-Host '== Repair =='
    foreach ($mkt in $broken) {
        if (Repair-Manifest $mkt $markets[$mkt]) { $repaired += $mkt }
    }
    Write-Host ''
    Write-Host '== Verify (codex plugin list) =='
    if (-not (Test-Path $codex)) {
        Write-Host "[WARN] codex.exe not found at $codex - skip verify" -ForegroundColor Yellow
    } else {
        $list = & $codex plugin list 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $list -match 'PLUGIN') {
            Write-Host '[OK] codex plugin list exit 0 - marketplace repaired successfully' -ForegroundColor Green
        } else {
            Write-Host '[FAIL] codex plugin list still failing:' -ForegroundColor Red
            $list | Write-Host
        }
    }
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Cyan
