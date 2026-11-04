param(
    [ValidateSet('codex', 'claude')][string]$Target = 'codex'
)
$src = Join-Path $PSScriptRoot '..\personal\AGENTS.global.md'
$src = (Resolve-Path $src).Path
if (-not (Test-Path $src)) { throw "Template not found: $src" }
$dest = if ($Target -eq 'codex') {
    Join-Path $env:USERPROFILE '.codex\AGENTS.md'
} else {
    Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
}
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
if (Test-Path $dest) { Copy-Item $dest ($dest + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force }
Copy-Item $src $dest -Force
"installed $Target rules -> $dest"
