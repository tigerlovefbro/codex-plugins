# Refresh the unpacked copy after the MSIX package updates.
# Close ChatGPT first; robocopy will fail on files in use.
$pkg = Get-AppxPackage OpenAI.Codex
if (-not $pkg) { throw "OpenAI.Codex package not found" }
$src = Join-Path $pkg.InstallLocation 'app'
$dst = 'D:\data\ChatGPT-unpacked\app'
robocopy $src $dst /E /R:1 /W:1 /NFL /NDL /NP
"Updated from: $src"
