param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
    [switch]$Push
)

$ErrorActionPreference = 'Stop'
$outDir = Join-Path $RepoRoot 'personal\mcp'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Find-Codex {
    if ($env:CODEX_EXE -and (Test-Path $env:CODEX_EXE)) { return $env:CODEX_EXE }
    $cmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $p = Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    if ($p) { return $p }
    throw 'codex.exe not found (set CODEX_EXE)'
}

function Protect-Env($envObj) {
    $result = [ordered]@{}
    foreach ($prop in $envObj.PSObject.Properties) {
        $k = $prop.Name
        $v = [string]$prop.Value
        if ($k -match '(?i)TOKEN|SECRET|PASSWORD|KEY|PAT' -or $v -match '^(sk-|ghp_|github_pat_)') {
            $result[$k] = '***REDACTED***'
        } else {
            $result[$k] = $v
        }
    }
    return $result
}

$codex = Find-Codex
$servers = & $codex mcp list --json 2>&1 | Out-String | ConvertFrom-Json
$index = @()

foreach ($s in $servers) {
    $t = $s.transport
    $transport = [ordered]@{ type = $t.type }
    if ($t.type -eq 'stdio') {
        $transport.command = $t.command
        $transport.args = @($t.args)
        if ($t.env) { $transport.env = Protect-Env $t.env } else { $transport.env = $null }
        $transport.env_vars = @($t.env_vars)
        $transport.cwd = $t.cwd
    } else {
        $transport.url = $t.url
        $transport.bearer_token_env_var = $t.bearer_token_env_var
        $transport.http_headers = $t.http_headers
        $transport.env_http_headers = $t.env_http_headers
    }

    $doc = [ordered]@{
        schema = 1
        name = $s.name
        enabled = $s.enabled
        transport = $transport
        startup_timeout_sec = $s.startup_timeout_sec
        tool_timeout_sec = $s.tool_timeout_sec
        source = 'codex'
        exported_at = (Get-Date).ToUniversalTime().ToString('o')
    }
    $file = Join-Path $outDir ($s.name + '.json')
    $doc | ConvertTo-Json -Depth 20 | Set-Content -Path $file -Encoding UTF8
    $index += [ordered]@{
        name = $s.name
        transport = $t.type
        enabled = $s.enabled
        file = ('personal/mcp/' + $s.name + '.json')
    }
}

$index | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $outDir 'index.json') -Encoding UTF8
"exported $($servers.Count) MCP servers -> $outDir"

if ($Push) {
    git -C $RepoRoot add personal/mcp 2>&1 | Out-Null
    $staged = git -C $RepoRoot diff --cached --name-only
    if ($staged) {
        git -C $RepoRoot -c user.name='tigerlovefbro' -c user.email='tigerlovefbro@gmail.com' commit -m 'sync MCP configs' 2>&1 | Out-Null
        git -C $RepoRoot push origin main 2>&1 | Out-Null
        "pushed: $($staged -join ', ')"
    } else {
        'no changes to push'
    }
}
