param(
    [string]$Tag = 'assets-20261104',
    [string]$Dest = 'D:\CodexAssets',
    [string[]]$Name = @()
)

$repo = 'tigerlovefbro/codex-plugins'
$rel = Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/$repo/releases/tags/$Tag" -Headers @{'User-Agent'='dsh'}
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
foreach ($a in $rel.assets) {
    if ($Name.Count -gt 0 -and $Name -notcontains $a.name) { continue }
    $out = Join-Path $Dest $a.name
    if (Test-Path $out) { "skip existing: $($a.name)"; continue }
    "downloading $($a.name) ($([math]::Round($a.size/1MB,1)) MB)"
    Invoke-WebRequest -UseBasicParsing -Uri $a.browser_download_url -OutFile $out
}
"done -> $Dest"
