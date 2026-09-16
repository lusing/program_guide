# ============================================================
# sbcl/build.ps1 — PowerShell 入口（Windows / macOS / Linux 通用）
#
# 运行本目录的 SBCL 示例，并按四条标准判定：
#   1. 退出码为 0
#   2. stderr 为空
#   3. stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
#   4. stdout 里有结束标记 ==== NN 结束 ====
#
# 用法：
#   pwsh ./build.ps1 -All              跑全部
#   pwsh ./build.ps1 -File 09-file-io.lisp
#   pwsh ./build.ps1 -Clean            清理 build/
# ============================================================
param(
    [switch]$All,
    [switch]$Clean,
    [string]$File
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $projectRoot 'build'

# ---------- 工具链解析：环境变量 → 各平台常见位置 → PATH ----------
function Resolve-Sbcl {
    if ($env:SBCL -and (Test-Path -LiteralPath $env:SBCL)) { return $env:SBCL }

    # 跨平台判断要避开只读自动变量 $IsWindows（Windows PowerShell 5.1 上没有）
    $onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }

    $candidates = @()
    if ($onWindows) {
        $candidates += (Join-Path $env:USERPROFILE 'scoop\apps\sbcl\current\sbcl.exe')
        $candidates += 'C:\Program Files\Steel Bank Common Lisp\sbcl.exe'
    } else {
        $candidates += '/opt/local/bin/sbcl'        # MacPorts
        $candidates += '/opt/homebrew/bin/sbcl'     # Homebrew (Apple Silicon)
        $candidates += '/usr/local/bin/sbcl'
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    $cmd = Get-Command sbcl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$sbcl = Resolve-Sbcl
if (-not $sbcl) {
    Write-Host '找不到 sbcl。请安装，或用环境变量指定，例如：' -ForegroundColor Yellow
    Write-Host '  $env:SBCL = "/opt/local/bin/sbcl"; pwsh ./build.ps1 -All'
    exit 1
}

# ---------- 判定辅助 ----------
# 第 3 条：按**字节**判断，绕开 PowerShell 的编码差异
function Test-HasCtrlChar {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# 第 4 条：读 UTF-8 文本后匹配字面量；控制字符一律写 \xNN，不要用反引号转义
function Test-HasMarker {
    param([string]$Path, [string]$Nn)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $text = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($Path))
    $text = [regex]::Replace($text, '\x00', '')
    return $text.Contains("==== $Nn 结束 ====")
}

function Get-ExampleFiles {
    Get-ChildItem -Path $projectRoot -File |
        Where-Object { $_.Name -match '^\d{2}-.*\.lisp$' } |
        Sort-Object Name
}

function Invoke-Example {
    param([System.IO.FileInfo]$Item)

    $name = $Item.Name
    $nn   = $name.Substring(0, 2)
    $dir  = Join-Path $buildDir ($name -replace '\.lisp$', '')
    $out  = Join-Path $dir 'stdout.txt'
    $err  = Join-Path $dir 'stderr.txt'

    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    # Start-Process 的 stdout/stderr 不能重定向到同一个文件，必须分开
    # --script 与 --non-interactive 不能连用：那样写文件名会被当成运行时参数，
    # 示例根本不会执行（只打一行 banner 就退出）。
    $lispArgs = "--noinform --non-interactive --no-userinit --load `"$($Item.FullName)`""
    $proc = Start-Process -FilePath $sbcl -ArgumentList $lispArgs `
        -WorkingDirectory $dir -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err

    $rc = $proc.ExitCode
    $reason = ''
    if ($rc -ne 0) {
        $reason = "退出码 $rc"
    } elseif ((Get-Item -LiteralPath $err).Length -gt 0) {
        $reason = "stderr 非空（$((Get-Item -LiteralPath $err).Length) 字节）"
    } elseif (Test-HasCtrlChar -Path $out) {
        $reason = 'stdout 含控制字符'
    } elseif (-not (Test-HasMarker -Path $out -Nn $nn)) {
        $reason = "缺少结束标记 ==== $nn 结束 ===="
    }

    if ($reason -eq '') {
        Write-Host '通过' -ForegroundColor Green
        return $true
    }

    Write-Host "失败 — $reason" -ForegroundColor Red
    $tailFile = if ((Get-Item -LiteralPath $err).Length -gt 0) { $err } else { $out }
    if ((Get-Item -LiteralPath $tailFile).Length -gt 0) {
        [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($tailFile)) `
            -split "`n" | Select-Object -Last 12 | ForEach-Object { Write-Host "      $_" }
    }
    return $false
}

# ---------- 主流程 ----------
if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Get-ChildItem -Path $projectRoot -Filter '*.fasl' -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
    Write-Host '[Clean] 已清理 build 目录与 FASL 产物。' -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$targets = if ($File) {
    $p = if ([System.IO.Path]::IsPathRooted($File)) { $File } else { Join-Path $projectRoot $File }
    if (-not (Test-Path -LiteralPath $p)) { throw "找不到示例文件: $p" }
    @(Get-Item -LiteralPath $p)
} elseif ($All) {
    @(Get-ExampleFiles)
} else {
    Write-Host '用法:' -ForegroundColor Yellow
    Write-Host '  pwsh ./build.ps1 -All                  跑全部示例'
    Write-Host '  pwsh ./build.ps1 -File 09-file-io.lisp 跑单个示例'
    Write-Host '  pwsh ./build.ps1 -Clean                清理产物'
    exit 0
}

Write-Host "SBCL: $sbcl  ($((& $sbcl --version 2>$null) -join ''))"
Write-Host "工作目录: $buildDir"
Write-Host ''

$total = 0; $passed = 0; $failed = 0; $failedList = @()
foreach ($item in $targets) {
    $total++
    Write-Host ('[{0,2}] {1,-34} ' -f $total, $item.Name) -NoNewline
    if (Invoke-Example -Item $item) { $passed++ } else { $failed++; $failedList += $item.Name }
}

Write-Host ''
Write-Host "通过 $passed   失败 $failed   共 $total"
if ($failed -gt 0) {
    Write-Host "失败项: $($failedList -join ' ')"
    exit 1
}

# 示例应当自己清理临时文件
$leftovers = Get-ChildItem -Path $buildDir -Recurse -File |
    Where-Object { $_.Name -ne 'stdout.txt' -and $_.Name -ne 'stderr.txt' }
if ($leftovers) {
    Write-Host ''
    Write-Host '提示：build/ 下有示例留下的临时文件（示例本应自己清理）：' -ForegroundColor Yellow
    $leftovers | ForEach-Object { Write-Host "  $($_.FullName)" }
}

exit 0
