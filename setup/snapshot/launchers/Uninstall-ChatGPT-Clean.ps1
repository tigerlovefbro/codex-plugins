#Requires -Version 5.1
<#
    ChatGPT / Codex 彻底卸载清理（含自动解除版本锁）
    ------------------------------------------------------------
    运行（会自动请求管理员权限）：
        powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Administrator\Desktop\Uninstall-ChatGPT-Clean.ps1"

    只看不动（预览，不需要管理员）：
        powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Administrator\Desktop\Uninstall-ChatGPT-Clean.ps1" -DryRun

    需要先备份配置（默认不备份）：
        追加 -Backup
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Backup
)

$ErrorActionPreference = 'SilentlyContinue'
$desktop = [Environment]::GetFolderPath('Desktop')
$logPath = Join-Path $desktop 'chatgpt-uninstall-log.txt'

function Say {
    param([string]$Message, [string]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
    if (-not $DryRun) {
        Add-Content -Path $logPath -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message) -Encoding UTF8
    }
}

function Remove-Target {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $size = 0
    if ((Get-Item -LiteralPath $Path).PSIsContainer) {
        $size = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force | Measure-Object Length -Sum).Sum
    } else {
        $size = (Get-Item -LiteralPath $Path).Length
    }
    $mb = [math]::Round($size / 1MB, 1)
    if ($DryRun) {
        Say ("  [预览] {0}  ({1} MB)  -> {2}" -f $Label, $mb, $Path) 'DarkYellow'
    } else {
        Remove-Item -LiteralPath $Path -Recurse -Force
        if (Test-Path -LiteralPath $Path) {
            Say ("  [!] 未能完全删除：{0}" -f $Path) 'Red'
        } else {
            Say ("  [√] {0}  ({1} MB)" -f $Label, $mb) 'Green'
        }
    }
    return $size
}

function Test-ChatGptPin {
    $list = winget pin list 2>&1 | Out-String
    return ($list -match 'OpenAI\.ChatGPT')
}

# ---------------- 提权 ----------------
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $DryRun) {
    Write-Host '需要管理员权限，正在请求提权（请在弹窗中点“是”）...' -ForegroundColor Yellow
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath) `
        -Verb RunAs
    return
}

Say ''
Say '====================================================' 'Cyan'
Say $(if ($DryRun) { '  ChatGPT / Codex 清理（预览模式，不会删除任何东西）' } else { '  ChatGPT / Codex 彻底清理' }) 'Cyan'
Say '====================================================' 'Cyan'
Say ''

$totalFreed = 0

# ---------------- 1. 备份（可选） ----------------
Say '[1/8] 个人配置备份' 'White'
$codexHome = Join-Path $env:USERPROFILE '.codex'
if (-not $Backup) {
    Say '  [i] 已跳过（需要备份请加 -Backup 参数）' 'DarkGray'
} else {
    $backupDir = Join-Path $desktop 'chatgpt-uninstall-backup'
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    foreach ($item in @('config.toml', '.codex-global-state.json', 'memories_1.sqlite')) {
        $src = Join-Path $codexHome $item
        if (Test-Path -LiteralPath $src) {
            if ($DryRun) {
                Say ("  [预览] 备份 {0}" -f $item) 'DarkYellow'
            } else {
                Copy-Item -LiteralPath $src -Destination $backupDir -Force
                Say ("  [√] 备份 {0}" -f $item) 'Green'
            }
        }
    }
    $skillsSrc = Join-Path $codexHome 'skills'
    if (Test-Path -LiteralPath $skillsSrc) {
        if ($DryRun) {
            Say '  [预览] 备份 skills 目录' 'DarkYellow'
        } else {
            Copy-Item -LiteralPath $skillsSrc -Destination $backupDir -Recurse -Force
            Say '  [√] 备份 skills 目录' 'Green'
        }
    }
    Say ("  备份位置：{0}" -f $backupDir) 'DarkGray'
}
Say ''

# ---------------- 2. 结束进程 ----------------
Say '[2/8] 结束相关进程' 'White'
foreach ($n in @('ChatGPT', 'codex', 'codex-code-mode-host', 'codex-command-runner', 'codex-windows-sandbox-setup')) {
    $p = Get-Process -Name $n -ErrorAction SilentlyContinue
    if ($p) {
        if ($DryRun) {
            Say ("  [预览] 结束 {0} ({1} 个进程)" -f $n, $p.Count) 'DarkYellow'
        } else {
            $p | Stop-Process -Force
            Say ("  [√] 结束 {0}" -f $n) 'Green'
        }
    }
}
if (-not $DryRun) { Start-Sleep -Seconds 2 }
Say ''

# ---------------- 3. 解除 winget 版本锁（必须在卸载包之前） ----------------
Say '[3/8] 解除 winget 版本锁（否则重装/升级会被拦）' 'White'
if ($DryRun) {
    Say '  [预览] winget pin remove --id OpenAI.ChatGPT（失败则 pin reset，再失败清理 pinning.db）' 'DarkYellow'
} else {
    if (-not (Test-ChatGptPin)) {
        Say '  [i] 没有版本锁，无需解除' 'DarkGray'
    } else {
        winget pin remove --id OpenAI.ChatGPT --accept-source-agreements --disable-interactivity | Out-Null
        if (-not (Test-ChatGptPin)) {
            Say '  [√] 版本锁已解除' 'Green'
        } else {
            Say '  [!] 单独移除失败（常见于网络/源不可用），改用 winget pin reset' 'Yellow'
            winget pin reset --force --disable-interactivity | Out-Null
            if (-not (Test-ChatGptPin)) {
                Say '  [√] 版本锁已解除（通过 reset）' 'Green'
            } else {
                Say '  [!] 仍失败，直接清理本地 pinning.db' 'Yellow'
                $pinDb = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\pinning.db'
                if (Test-Path -LiteralPath $pinDb) {
                    Copy-Item -LiteralPath $pinDb -Destination ($pinDb + '.bak') -Force
                    $py = Get-Command python -ErrorAction SilentlyContinue
                    if ($py) {
                        $pyScript = Join-Path $env:TEMP 'wg-pin-del.py'
                        @'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1], timeout=10)
con.execute("delete from pin where package_id = ?", ("OpenAI.ChatGPT",))
con.commit()
con.close()
'@ | Set-Content -Path $pyScript -Encoding ASCII
                        & $py.Source $pyScript $pinDb | Out-Null
                    } else {
                        Remove-Item -LiteralPath $pinDb -Force
                    }
                }
                if (Test-ChatGptPin) {
                    Say '  [×] 仍未解除，请手动运行 winget pin list 检查' 'Red'
                } else {
                    Say '  [√] 版本锁已解除（本地库）' 'Green'
                }
            }
        }
    }
}
Say ''

# ---------------- 4. 卸载 MSIX 包 ----------------
Say '[4/8] 卸载 MSIX 应用包' 'White'
$pkg = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue
if ($pkg) {
    if ($DryRun) {
        Say ("  [预览] Remove-AppxPackage {0}" -f $pkg.PackageFullName) 'DarkYellow'
    } else {
        $pkg | Remove-AppxPackage
        Say '  [√] 已卸载 OpenAI.Codex' 'Green'
    }
} else {
    Say '  [i] 未安装（已卸载过）' 'DarkGray'
}
Say ''

# ---------------- 5. 删除计划任务 ----------------
Say '[5/8] 删除计划任务' 'White'
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -match 'codex|chatgpt|openai' }
if ($tasks) {
    foreach ($t in $tasks) {
        if ($DryRun) {
            Say ("  [预览] 删除任务 {0}" -f $t.TaskName) 'DarkYellow'
        } else {
            Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false
            Say ("  [√] 删除任务 {0}" -f $t.TaskName) 'Green'
        }
    }
} else {
    Say '  [i] 无' 'DarkGray'
}
Say ''

# ---------------- 6. 删除沙箱账户与配置文件 ----------------
Say '[6/8] 删除沙箱账户及其用户配置文件' 'White'
foreach ($u in @('CodexSandboxOffline', 'CodexSandboxOnline')) {
    if (Get-LocalUser -Name $u -ErrorAction SilentlyContinue) {
        if ($DryRun) {
            Say ("  [预览] 删除本地账户 {0}" -f $u) 'DarkYellow'
        } else {
            Remove-LocalUser -Name $u
            Say ("  [√] 删除本地账户 {0}" -f $u) 'Green'
        }
    }
}
foreach ($prof in (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -match 'CodexSandbox' })) {
    if ($DryRun) {
        Say ("  [预览] 删除用户配置文件 {0}" -f $prof.LocalPath) 'DarkYellow'
    } else {
        Remove-CimInstance -InputObject $prof
        Say ("  [√] 删除配置文件 {0}" -f $prof.LocalPath) 'Green'
    }
}
foreach ($dir in @('C:\Users\CodexSandboxOffline', 'C:\Users\CodexSandboxOnline')) {
    if (Test-Path -LiteralPath $dir) {
        if ($DryRun) { Say ("  [预览] 删除残留目录 {0}" -f $dir) 'DarkYellow' }
        else { Remove-Item -LiteralPath $dir -Recurse -Force; Say ("  [√] 删除残留目录 {0}" -f $dir) 'Green' }
    }
}
Say ''

# ---------------- 7. 删除数据目录 ----------------
Say '[7/8] 删除数据目录' 'White'
$dirs = @(
    @{ Path = (Join-Path $env:LOCALAPPDATA 'OpenAI');                              Label = 'Codex 运行时 (LocalAppData\OpenAI)' },
    @{ Path = (Join-Path $env:USERPROFILE '.codex');                               Label = 'Codex 配置与数据 (.codex)' },
    @{ Path = (Join-Path $env:USERPROFILE '.cache\codex-runtimes');                Label = '运行时缓存 (.cache\codex-runtimes)' },
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Packages\OpenAI.Codex_2p2nqsd0c76g0'); Label = '应用数据包 (Packages\OpenAI.Codex)' },
    @{ Path = (Join-Path $env:LOCALAPPDATA 'Programs\ChatGPT');                    Label = '程序目录 (Programs\ChatGPT)' },
    @{ Path = (Join-Path $env:APPDATA 'OpenAI');                                   Label = '漫游数据 (Roaming\OpenAI)' }
)
foreach ($d in $dirs) { $totalFreed += (Remove-Target -Path $d.Path -Label $d.Label) }
Say ''

# ---------------- 8. 注册表与快捷方式 ----------------
Say '[8/8] 清理注册表项与快捷方式' 'White'
foreach ($k in @(
    'HKCU:\Software\Classes\codex',
    'HKCU:\Software\Classes\.skill',
    'HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.openai.codexextension'
)) {
    if (Test-Path $k) {
        if ($DryRun) {
            Say ("  [预览] 删除注册表 {0}" -f $k) 'DarkYellow'
        } else {
            Remove-Item -LiteralPath $k -Recurse -Force
            Say ("  [√] 删除注册表 {0}" -f $k) 'Green'
        }
    }
}
foreach ($l in @(
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\ChatGPT.lnk'),
    (Join-Path $desktop 'ChatGPT.lnk')
)) {
    if (Test-Path -LiteralPath $l) {
        if ($DryRun) { Say ("  [预览] 删除快捷方式 {0}" -f $l) 'DarkYellow' }
        else { Remove-Item -LiteralPath $l -Force; Say ("  [√] 删除快捷方式 {0}" -f $l) 'Green' }
    }
}
Say ''

# ---------------- 结果 ----------------
Say '====================================================' 'Cyan'
if ($DryRun) {
    Say '  预览完成，未做任何修改。去掉 -DryRun 参数即可真正执行。' 'Yellow'
} else {
    Say ("  清理完成，释放约 {0} MB" -f [math]::Round($totalFreed / 1MB, 1)) 'Green'
    if ($Backup) { Say ("  配置备份保留在：{0}" -f (Join-Path $desktop 'chatgpt-uninstall-backup')) 'Green' }
    Say '  版本锁已自动解除，可直接重装。' 'Green'
    Say ("  日志：{0}" -f $logPath) 'DarkGray'
}
Say '====================================================' 'Cyan'
Say ''
if (-not $DryRun) {
    Read-Host '按回车键退出'
}
