# FIX-CHROME-PLUGIN.ps1
# Re-applies the community patch to openai-bundled browser-client.mjs.
# Fixes "TypeError: Cannot redefine property: process" (Codex Desktop 26.707.71524).
# Idempotent: already-patched files are skipped. Runs in <1s.

$ErrorActionPreference = 'Stop'
$Base = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'

$Targets = @(
  (Join-Path $Base 'plugins\cache\openai-bundled\chrome\26.707.71524\scripts\browser-client.mjs'),
  (Join-Path $Base 'plugins\cache\openai-bundled\browser\26.707.71524\scripts\browser-client.mjs'),
  (Join-Path $Base '.tmp\bundled-marketplaces\openai-bundled\plugins\chrome\scripts\browser-client.mjs'),
  (Join-Path $Base '.tmp\bundled-marketplaces\openai-bundled\plugins\browser\scripts\browser-client.mjs'),
  (Join-Path $Base 'marketplaces\openai-bundled-local\plugins\chrome\scripts\browser-client.mjs'),
  (Join-Path $Base 'marketplaces\openai-bundled-local\plugins\browser\scripts\browser-client.mjs')
)

$PatchedMarker = 'Object.defineProperty(global, "process"'

function Test-Patched([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  $text = [System.IO.File]::ReadAllText($path)
  return $text.Contains($PatchedMarker)
}

function Apply-Patch([string]$path) {
  $text = [System.IO.File]::ReadAllText($path)
  $before = $text
  $text = $text.Replace('globalThis.process = processShim;', 'const process = processShim;')
  $text = $text.Replace('globalThis.global = globalThis.global ?? globalThis;', 'const global = Object.create(globalThis);')
  $text = $text.Replace('globalThis.global.process = processShim;', 'Object.defineProperty(global, "process", { value: processShim });')
  if ($text -ne $before) {
    [System.IO.File]::WriteAllText($path, $text)
    return $true
  }
  return $false
}

$changed = 0; $skipped = 0; $missing = 0
foreach ($t in $Targets) {
  $isP = Test-Patched $t
  if ($null -eq $isP) { $missing++; Write-Output ("MISSING: " + $t); continue }
  if ($isP) { $skipped++; continue }
  if (Apply-Patch $t) { $changed++; Write-Output ("PATCHED: " + $t) }
  else { Write-Output ("UNRECOGNIZED: " + $t) }
}
Write-Output ("SUMMARY changed=" + $changed + " skipped=" + $skipped + " missing=" + $missing)
