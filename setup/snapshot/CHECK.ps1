# 校验本机是否与快照一致
# 用法: ./CHECK.ps1 [-RunExec]
param([switch]$RunExec)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$codex = Join-Path $env:USERPROFILE '.codex'
$ver = Get-Content (Join-Path $here 'VERSION.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$rows = @()

function Add-Row([string]$name, [string]$got, [string]$want, [bool]$ok) {
    $script:rows += [pscustomobject]@{ 检查=$name; 当前=$got; 期望=$want; 结果=($(if($ok){'PASS'}else{'DIFF'})) }
}

# 1. 应用版本
$pkg = Get-AppxPackage -Name OpenAI.Codex
$gotVer = if ($pkg) { $pkg.Version.ToString() } else { '未安装' }
Add-Row '桌面端版本' $gotVer $ver.desktop_app.appx_version ($gotVer -eq $ver.desktop_app.appx_version)

# 2. CLI
$cli = $null
try { $cli = (& codex --version 2>$null) } catch { }
if (-not $cli) { $p = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin\3135b80b111fd431\codex.exe'; if (Test-Path $p) { $cli = (& $p --version 2>$null) } }
$cliStr = if ($cli) { ($cli -join ' ').Trim() } else { '未找到' }
Add-Row 'CLI 版本' $cliStr $ver.cli.version ($cliStr -like "*$($ver.cli.version -replace 'codex-cli ','')*")

# 3. 配置项
$cfgPath = Join-Path $codex 'config.toml'
$cfg = if (Test-Path $cfgPath) { Get-Content $cfgPath -Raw } else { '' }
$modelOk = $cfg -match 'model\s*=\s*"gpt-5\.6-sol"'
$baseOk  = $cfg -match 'base_url\s*=\s*"https?://[^"]+"'
$provOk  = $cfg -match 'model_provider\s*=\s*"custom"'
Add-Row '模型/中转' ("model=" + [bool]$modelOk + " base=" + [bool]$baseOk + " provider=" + [bool]$provOk) 'gpt-5.6-sol + 中转地址(真值/占位符) + custom' ($modelOk -and $baseOk -and $provOk)

# 4. 插件数量
$pluginCount = ([regex]::Matches($cfg, '(?m)^\[plugins\."')).Count
Add-Row '插件数量' $pluginCount $ver.plugins.count ($pluginCount -eq $ver.plugins.count)

# 5. 市场
foreach ($m in $ver.plugins.marketplaces.PSObject.Properties.Name | Select-Object -First 3) {
    Add-Row ("市场 " + $m) ([bool]($cfg -match [regex]::Escape("[marketplaces." + $m + "]"))) '存在' ([bool]($cfg -match [regex]::Escape("[marketplaces." + $m + "]")))
}

# 6. hosts 锁定
$hosts = Get-Content 'C:\Windows\System32\drivers\etc\hosts' -ErrorAction SilentlyContinue
$hostsOk = $true
foreach ($d in $ver.hosts_locked) { if (-not ($hosts -match [regex]::Escape($d))) { $hostsOk = $false } }
Add-Row 'hosts 更新屏蔽' ($(if($hostsOk){'3/3'}else{'缺失'})) 'cdn / updates / persistent.oaistatic' $hostsOk

# 7. 密钥环境变量（只看是否存在）
foreach ($s in $ver.secrets_required) {
    $has = [bool][Environment]::GetEnvironmentVariable($s.name,'User')
    Add-Row ("env " + $s.name) ($(if($has){'已设置'}else{'缺失'})) '已设置' $has
}

# 8. 登录状态
$login = ''
$codexExe = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin\3135b80b111fd431\codex.exe'
try { $login = (& $codexExe login status 2>&1 | Out-String) } catch { }
$loginOk = $login -match 'Logged in'
Add-Row 'ChatGPT 登录' ($(if($loginOk){'已登录'}else{'未登录'})) 'Logged in' $loginOk

# 9. exec 冒烟
if ($RunExec) {
    Write-Host '跑 codex exec 冒烟测试(最多 120 秒)...' -ForegroundColor DarkGray
    $o = & codex exec --skip-git-repo-check 'Say OK' 2>&1 | Out-String
    $execOk = $o -match 'OK'
    Add-Row 'exec 冒烟' ($(if($execOk){'OK'}else{'失败'})) 'OK' $execOk
}

$rows | Format-Table -AutoSize
$fail = ($rows | Where-Object { $_.结果 -ne 'PASS' }).Count
if ($fail -eq 0) { Write-Host "全部通过" -ForegroundColor Green } else { Write-Host "$fail 项不一致，见上表" -ForegroundColor Yellow }
