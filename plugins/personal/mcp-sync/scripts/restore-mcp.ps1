param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
    [string]$Name = '',
    [ValidateSet('codex', 'json')][string]$Target = 'codex'
)

$ErrorActionPreference = 'Stop'
$mcpDir = Join-Path $RepoRoot 'personal\mcp'
if (-not (Test-Path $mcpDir)) { throw "MCP dir not found: $mcpDir" }

$files = Get-ChildItem $mcpDir -Filter '*.json' | Where-Object { $_.Name -ne 'index.json' }
if ($Name) { $files = $files | Where-Object { $_.BaseName -eq $Name } }

if ($Target -eq 'json') {
    $all = [ordered]@{ mcpServers = [ordered]@{} }
    foreach ($f in $files) {
        $d = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $all.mcpServers[$d.name] = $d.transport
    }
    $all | ConvertTo-Json -Depth 20
    return
}

function Find-Codex {
    if ($env:CODEX_EXE -and (Test-Path $env:CODEX_EXE)) { return $env:CODEX_EXE }
    $cmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $p = Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    if ($p) { return $p }
    throw 'codex.exe not found'
}

$codex = Find-Codex
foreach ($f in $files) {
    $d = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $t = $d.transport
    & $codex mcp remove $d.name 2>&1 | Out-Null
    if ($t.type -eq 'stdio') {
        $args = @('mcp', 'add', $d.name)
        if ($t.env) {
            foreach ($k in $t.env.PSObject.Properties.Name) {
                $v = [string]$t.env.$k
                if ($v -eq '***REDACTED***') { continue }
                $args += @('--env', ($k + '=' + $v))
            }
        }
        $args += '--'
        $args += $t.command
        foreach ($a in @($t.args)) { $args += $a }
        & $codex @args 2>&1 | Out-Null
    } else {
        $args = @('mcp', 'add', $d.name, '--url', $t.url)
        if ($t.bearer_token_env_var) { $args += @('--bearer-token-env-var', $t.bearer_token_env_var) }
        & $codex @args 2>&1 | Out-Null
    }
    "restored $($d.name)"
}
& $codex mcp list 2>&1 | Out-String
