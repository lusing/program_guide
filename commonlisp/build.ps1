# ============================================================
# commonlisp/build.ps1 — PowerShell 入口（双实现通道）
#
# 逐个运行 examples/NN_topic/main.lisp，通道按示例头部声明：
#   ;; channel: both  → SBCL 与 CLISP 各跑一遍，且两个通道的
#                       stdout 必须**逐字节一致**（可移植性证明）
#   ;; channel: sbcl  → 仅 SBCL（SBCL 专属扩展章）
#
# 每个通道按四条标准判定：
#   1. 退出码为 0
#   2. stderr 为空
#   3. stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
#   4. stdout 里有结束标记 ==== NN 结束 ====
# both 通道加第 5 条：SBCL 与 CLISP 的 stdout 逐字节一致。
#
# 用法：
#   pwsh ./build.ps1 -All                    跑全部
#   pwsh ./build.ps1 -Example 12_control     跑单个示例（目录名或编号）
#   pwsh ./build.ps1 -Clean                  清理 build/
#
# 环境变量 SBCL / CLISP 可指定解释器路径。
# 两个入口（run-all.sh / build.ps1）不要并行跑：共用 build/ 产物目录。
# ============================================================
param(
    [switch]$All,
    [switch]$Clean,
    [string]$Example
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $projectRoot 'build'

# ---------- 工具链解析：环境变量 → 常见安装位置 → PATH ----------
function Resolve-Lisp {
    param([string]$Name, [string[]]$Candidates, [string]$EnvVar)

    if ($EnvVar -and (Test-Path -LiteralPath $EnvVar)) { return $EnvVar }
    foreach ($c in $Candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

# 跨平台判断要避开只读自动变量 $IsWindows（Windows PowerShell 5.1 上没有）
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$unixExtra = if ($onWindows) { @() } else { @('/opt/local/bin', '/opt/homebrew/bin', '/usr/local/bin') }

$sbcl = Resolve-Lisp 'sbcl' (@(
    $(if ($onWindows) { Join-Path $env:USERPROFILE 'scoop\apps\sbcl\current\sbcl.exe' } else { $null }),
    'C:\Program Files\Steel Bank Common Lisp\sbcl.exe'
) + $unixExtra | Where-Object { $_ }) $env:SBCL

$clisp = Resolve-Lisp 'clisp' (@(
    $(if ($onWindows) { Join-Path $env:USERPROFILE 'scoop\apps\clisp\current\clisp.exe' } else { $null })
) + $unixExtra | Where-Object { $_ }) $env:CLISP

# ---------- 判定辅助 ----------
function Test-HasCtrlChar {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Test-HasMarker {
    param([string]$Path, [string]$Nn)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $text = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($Path))
    $text = [regex]::Replace($text, '\x00', '')
    return $text.Contains("==== $Nn 结束 ====")
}

function Test-SameBytes {
    param([string]$A, [string]$B)
    if (-not ((Test-Path -LiteralPath $A) -and (Test-Path -LiteralPath $B))) { return $false }
    $xa = [System.IO.File]::ReadAllBytes($A)
    $xb = [System.IO.File]::ReadAllBytes($B)
    if ($xa.Length -ne $xb.Length) { return $false }
    for ($i = 0; $i -lt $xa.Length; $i++) {
        if ($xa[$i] -ne $xb[$i]) { return $false }
    }
    return $true
}

function Get-Channel {
    param([string]$Src)
    $line = Select-String -LiteralPath $Src -Pattern '^;; *channel:' | Select-Object -First 1
    if (-not $line) { return 'both' }
    # 行内可带注释，取第一个词
    return ($line.Line -replace '^;; *channel: *', '' -replace '[\s()].*$', '').Trim()
}

# ---------- 主流程 ----------
if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host '[Clean] 已清理 build 目录。' -ForegroundColor Yellow
    exit 0
}

$exampleDirs = Get-ChildItem -Path (Join-Path $projectRoot 'examples') -Directory |
    Where-Object { $_.Name -match '^\d{2}_' -and (Test-Path (Join-Path $_.FullName 'main.lisp')) } |
    Sort-Object Name

if ($Example) {
    $exampleDirs = $exampleDirs | Where-Object { $_.Name -like "$Example*" }
    if (-not $exampleDirs) { throw "没有匹配 '$Example' 的示例" }
} elseif (-not $All) {
    Write-Host '用法:' -ForegroundColor Yellow
    Write-Host '  pwsh ./build.ps1 -All                  跑全部示例（双通道）'
    Write-Host '  pwsh ./build.ps1 -Example 12_control   跑单个示例（目录名或编号）'
    Write-Host '  pwsh ./build.ps1 -Clean                清理产物'
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

Write-Host "SBCL : $(if ($sbcl) { $sbcl } else { '未找到' })"
Write-Host "CLISP: $(if ($clisp) { $clisp } else { '未找到' })"
Write-Host "工作目录: $buildDir"
Write-Host ''

# 在 build/<示例>.<通道>/ 下运行，四条判定，打印 通过/失败
function Invoke-Channel {
    param([string]$Name, [string]$Nn, [string]$Ch)

    $src = Join-Path $projectRoot "examples/$Name/main.lisp"
    $dir = Join-Path $buildDir "$Name.$Ch"
    $out = Join-Path $dir 'stdout.txt'
    $err = Join-Path $dir 'stderr.txt'
    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    # 工作目录切到产物目录：示例里的相对路径读写都落在这里。
    # CLISP 必须显式 -E UTF-8：默认编码跟 locale，ASCII 终端下中文直接报错
    $lispArgs = if ($Ch -eq 'sbcl') {
        "--noinform --non-interactive --no-userinit --load `"$src`""
    } else {
        "-q -q -norc -E UTF-8 `"$src`""
    }
    $bin = if ($Ch -eq 'sbcl') { $sbcl } else { $clisp }

    $proc = Start-Process -FilePath $bin -ArgumentList $lispArgs `
        -WorkingDirectory $dir -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err
    $rc = $proc.ExitCode

    if ($rc -ne 0) {
        Write-Host "失败 — 退出码 $rc" -ForegroundColor Red
        if ((Get-Item -LiteralPath $err).Length -gt 0) {
            [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($err)) -split "`n" |
                Select-Object -Last 8 | ForEach-Object { Write-Host "      $_" }
        }
        return $false
    }
    if ((Get-Item -LiteralPath $err).Length -gt 0) {
        Write-Host '失败 — stderr 非空' -ForegroundColor Red
        [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($err)) -split "`n" |
            Select-Object -Last 8 | ForEach-Object { Write-Host "      $_" }
        return $false
    }
    if (Test-HasCtrlChar -Path $out) {
        Write-Host '失败 — stdout 含控制字符' -ForegroundColor Red
        return $false
    }
    if (-not (Test-HasMarker -Path $out -Nn $Nn)) {
        Write-Host "失败 — 缺少结束标记 ==== $Nn 结束 ====" -ForegroundColor Red
        return $false
    }
    Write-Host '通过' -ForegroundColor Green
    return $true
}

$total = 0; $passed = 0; $failed = 0
$failedList = @()

foreach ($dir in $exampleDirs) {
    $name = $dir.Name
    $nn = $name.Substring(0, 2)
    $channel = Get-Channel -Src (Join-Path $dir.FullName 'main.lisp')
    $chans = if ($channel -eq 'sbcl') { @('sbcl') } else { @('sbcl', 'clisp') }

    foreach ($ch in $chans) {
        $bin = if ($ch -eq 'sbcl') { $sbcl } else { $clisp }
        if (-not $bin) {
            Write-Host "[--] $name.$ch 跳过（未找到 $ch）" -ForegroundColor Yellow
            $failed++; $failedList += "$name.$ch"; continue
        }
        $total++
        Write-Host ('[{0,2}] {1,-30} ' -f $total, "$name.$ch") -NoNewline
        if (Invoke-Channel -Name $name -Nn $nn -Ch $ch) { $passed++ }
        else { $failed++; $failedList += "$name.$ch" }
    }

    # 第 5 条（仅 both）：两通道 stdout 逐字节一致
    if ($channel -ne 'sbcl' -and $sbcl -and $clisp) {
        $a = Join-Path $buildDir "$name.sbcl/stdout.txt"
        $b = Join-Path $buildDir "$name.clisp/stdout.txt"
        if ((Test-Path -LiteralPath $a) -and (Test-Path -LiteralPath $b)) {
            $total++
            if (Test-SameBytes -A $a -B $b) { $passed++ }
            else {
                $failed++; $failedList += "$name.xdiff"
                Write-Host '     × 跨通道输出不一致' -ForegroundColor Red
            }
        }
    }
}

Write-Host ''
Write-Host "通过 $passed   失败 $failed   共 $total"
if ($failed -gt 0) {
    Write-Host "失败项: $($failedList -join ' ')"
    exit 1
}

# 示例应当自己清理临时文件；这里有残留就提示一下
$leftovers = Get-ChildItem -Path $buildDir -Recurse -File |
    Where-Object { $_.Name -ne 'stdout.txt' -and $_.Name -ne 'stderr.txt' }
if ($leftovers) {
    Write-Host ''
    Write-Host '提示：build/ 下有示例留下的临时文件（示例本应自己清理）：' -ForegroundColor Yellow
    $leftovers | ForEach-Object { Write-Host "  $($_.FullName)" }
}

exit 0
