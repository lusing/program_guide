param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

# ============================================================
#  Forth 教程构建入口（gforth 跑在 wsl -d Debian 里）
#
#  Windows 路径自动翻译成 /mnt/<盘>/...；gforth 的 stderr 在
#  WSL 内部落到临时文件再取回——wsl.exe 自己的 NAT 提示噪音
#  不混进判定。
# ============================================================

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$distro = "Debian"

function Convert-ToLinuxPath {
    param([Parameter(Mandatory = $true)][string]$WinPath)
    $full = [System.IO.Path]::GetFullPath($WinPath)
    if ($full -match '^([A-Za-z]):[\\/](.*)$') {
        $drive = $Matches[1].ToLower()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive/$rest"
    }
    throw "无法把路径翻译成 WSL 路径: $WinPath"
}

if (-not (wsl -l -q | Select-String -SimpleMatch $distro)) {
    throw "未找到 WSL 发行版 $distro。请安装或在脚本顶部改 `$distro。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Forth 特有的三条判定标准：退出码 0、stderr 为空、结束时数据栈为空（<0>）
# 注意：gforth 脚本报错后退出码也可能是 0——所以 stderr 与 <0> 两关才是硬门槛。
function Invoke-ValidateFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileName($SourcePath)
    $linuxPath = Convert-ToLinuxPath $SourcePath
    $logPath = Join-Path $buildDir ($name + ".log")
    $errPath = Join-Path $buildDir ($name + ".err")

    Write-Host "[Run] $name" -ForegroundColor Cyan

    # 在 WSL 内把 stdout / stderr 分开，用哨兵行带回 stderr 内容
    $inner = "gforth '$linuxPath' 2>/tmp/gforth-ps-err; rc=`$?; echo '===STDERR==='; cat /tmp/gforth-ps-err; rm -f /tmp/gforth-ps-err; exit `$rc"
    $raw = (& wsl -d $distro -- bash -c $inner 2>$null) -join "`n"
    $code = $LASTEXITCODE

    $stdoutText = ""
    $stderrText = ""
    if ($raw -match '(?s)^(.*)===STDERR===\r?\n?(.*)$') {
        $stdoutText = $Matches[1]
        $stderrText = $Matches[2]
    } else {
        $stdoutText = $raw
    }

    [System.IO.File]::WriteAllText($logPath, $stdoutText)
    [System.IO.File]::WriteAllText($errPath, $stderrText)

    $lines = @($stdoutText -split "`n" | Where-Object { $_.Trim() -ne "" })
    $last = ""
    if ($lines.Count -gt 0) { $last = $lines[$lines.Count - 1] }

    $reasons = @()
    if ($code -ne 0) { $reasons += "退出码 $code" }
    if ($stderrText.Trim() -ne "") { $reasons += "stderr 有输出" }
    if ($last -notlike "*<0>*") { $reasons += "结束时栈非空（$last）" }

    if ($reasons.Count -eq 0) {
        Write-Host "  [OK] $last" -ForegroundColor Green
        return $true
    }

    Write-Host "  [FAIL] $($reasons -join '；')" -ForegroundColor Red
    return $false
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.fs" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .fs 示例文件。"
    }

    $pass = 0
    $fail = 0
    foreach ($f in $files) {
        if (Invoke-ValidateFile -SourcePath $f.FullName) { $pass++ } else { $fail++ }
    }

    Write-Host "--------------------------------" -ForegroundColor DarkGray
    Write-Host "通过 $pass   失败 $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
    if ($fail -ne 0) { exit 1 }
    Write-Host "[Done] examples 目录全部验证通过（gforth @ wsl -d $distro）。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    if (-not (Invoke-ValidateFile -SourcePath $sourcePath)) { exit 1 }
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                运行并验证 examples 下全部示例（经 wsl -d $distro）"
Write-Host "  .\build.ps1 -File <name>        运行并验证单个示例（如 04-control-flow.fs）"
Write-Host "  .\build.ps1 -Clean              清理 build 目录"
Write-Host ""
Write-Host "提示：也可直接在 WSL 里 ./run-all.sh（含 -v 显示完整输出、按编号前缀筛选）。"
