param(
    [Parameter(Mandatory = $true)][string]$SkillPath,
    [ValidateSet('claude', 'dsh')][string]$Target = 'claude',
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$src = Join-Path $RepoRoot $SkillPath
if (-not (Test-Path $src)) { throw "Skill not found: $src" }
$skillDir = Split-Path $src -Parent
$name = Split-Path $skillDir -Leaf

$destRoot = if ($Target -eq 'claude') {
    Join-Path $env:USERPROFILE '.claude\skills'
} else {
    Join-Path $env:USERPROFILE '.agents\skills'
}
New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
$dest = Join-Path $destRoot $name
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Copy-Item $skillDir $dest -Recurse -Force
"Installed $name -> $dest"
