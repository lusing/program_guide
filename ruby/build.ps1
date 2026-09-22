param(
    [switch]$All,
    [string]$Example,
    [string]$Ruby,
    [switch]$ShowOutput
)

# ============================================================
# build.ps1 —— 用 Ruby 跑遍所有示例（PowerShell 版，等价于 run-all.sh）
#
#   pwsh ./build.ps1 -All                  全部示例（运行层 + 测试层）
#   pwsh ./build.ps1 -Example 09_arrays    单个示例
#   pwsh ./build.ps1 -All -ShowOutput      附带每个示例的完整输出
#
# 判定标准（六条 + 测试层，与 run-all.sh 逐条一致）：
#   1. 退出码为 0
#   2. stderr 为空（Ruby 的 warning/异常回溯都走 stderr，这一条等价于「零告警」；
#      示例若故意触发诊断，由示例自己用 Warning[...] / $VERBOSE 圈起来，
#      判定标准不为任何示例放宽）
#   3. stdout 非空
#   4. stdout 里没有多余控制字符（TAB/LF/CR 除外）
#   5. stdout 里有结束标记 "==== NN 结束 ===="
#   6. stdout 里没有 Ruby 的诊断字样（行首 error/warning/Traceback、独词 Error）
#   7. 测试层：ruby runtests.rb（minitest）退出码为 0
#
# 工具链定位不硬编码任何一台机器的路径：
#   -Ruby 参数 → 环境变量 RUBY → PATH 上的 ruby → 常见安装位置
# ============================================================

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
if ($onWindows) { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 }

# ------------------------------------------------------------
# 工具链定位
# ------------------------------------------------------------
$Candidates = @()
if ($Ruby) { $Candidates += $Ruby }
if ($env:RUBY) { $Candidates += $env:RUBY }
$Candidates += 'ruby4.0'
$Candidates += 'ruby'
if ($onWindows) {
    $Candidates += "$env:LOCALAPPDATA\Programs\Ruby*\bin\ruby.exe"
    $Candidates += "C:\Ruby*\bin\ruby.exe"
} else {
    $Candidates += '/opt/local/bin/ruby4.0'      # MacPorts（本机）
    $Candidates += '/opt/local/bin/ruby'
    $Candidates += '/opt/homebrew/bin/ruby'
    $Candidates += '/usr/local/bin/ruby'
}

$RubyExe = $null
foreach ($c in $Candidates) {
    if ($c -match '[*\/\\]') {
        $found = Get-Item $c -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $RubyExe = $found.FullName; break }
    } elseif (Get-Command $c -ErrorAction SilentlyContinue) {
        $RubyExe = (Get-Command $c).Source; break
    }
}
if (-not $RubyExe) {
    Write-Host "未找到 ruby（可 -Ruby /path/to/ruby，或确认它在 PATH 上）"
    exit 1
}
Write-Host "ruby     : $RubyExe"
& $RubyExe --version
Write-Host ""

# ------------------------------------------------------------
# 判定函数（与 run-all.sh 逐条一致）
# ------------------------------------------------------------
function Test-CtrlChars([string]$Path) {
    # 排除 TAB(0x09)/LF(0x0A)/CR(0x0D) 后还有控制字符
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    foreach ($b in $bytes) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Test-DiagWords([string]$Path) {
    # 行首 error/warning/Traceback，或「独词 Error」（前后非字母数字下划线）
    $lines = [System.IO.File]::ReadAllLines($Path)
    foreach ($line in $lines) {
        if ($line -match '^(error|warning|Traceback)') { return $true }
        if ($line -match '(^|[^A-Za-z0-9_])Error([^A-Za-z0-9_]|$)') { return $true }
    }
    return $false
}

# ------------------------------------------------------------
# 主循环
# ------------------------------------------------------------
$BuildDir = Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$allDirs = Get-ChildItem -Path (Join-Path $projectRoot 'examples') -Directory |
    Where-Object { $_.Name -match '^\d\d_' } |
    Sort-Object Name

$selected = @()
if ($Example) {
    $hit = $allDirs | Where-Object { $_.Name -eq $Example -or $_.Name -match "^$($Example)_"}
    if (-not $hit) { Write-Host "没有匹配「$Example」的示例目录"; exit 1 }
    $selected = @($hit)
} else {
    $selected = $allDirs
}

$pass = 0; $fail = 0; $failedList = @()
foreach ($dir in $selected) {
    $nn = ($dir.Name -split '_')[0]
    $out = Join-Path $BuildDir "$nn.out"
    $err = Join-Path $BuildDir "$nn.err"
    $tst = Join-Path $BuildDir "$nn.test"

    & $RubyExe (Join-Path $dir.FullName 'main.rb')    1> $out 2> $err
    $rcOut  = $LASTEXITCODE
    & $RubyExe (Join-Path $dir.FullName 'runtests.rb') 1> $tst 2> "$err.test"
    $rcTest = $LASTEXITCODE

    $reasons = ""
    if ($rcOut  -ne 0) { $reasons += " 退出码=$rcOut" }
    if ((Get-Item $err -ErrorAction SilentlyContinue).Length -gt 0) { $reasons += " stderr非空" }
    if ((Get-Item $out -ErrorAction SilentlyContinue).Length -eq 0) { $reasons += " stdout空" }
    if (Test-CtrlChars $out) { $reasons += " 控制字符" }
    $endMark = "==== $nn 结束 ===="
    if (-not (Select-String -Path $out -Pattern $endMark -SimpleMatch -Quiet)) { $reasons += " 缺结束标记" }
    if (Test-DiagWords $out) { $reasons += " 诊断字样" }
    if ($rcTest -ne 0) { $reasons += " 测试层rc=$rcTest" }

    if ($reasons -eq "") {
        $pass++
        Write-Host ("  ✓ {0}" -f $dir.Name)
        if ($ShowOutput) { Get-Content $out }
    } else {
        $fail++
        $failedList += "$($dir.Name):$reasons"
        Write-Host ("  ✗ {0} —{1}" -f $dir.Name, $reasons)
        if ($ShowOutput) {
            Write-Host '--- stdout ---'; Get-Content $out
            Write-Host '--- stderr ---'; Get-Content $err
        }
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "通过 $pass / $($pass + $fail)"
if ($fail -gt 0) {
    Write-Host "失败清单："
    foreach ($f in $failedList) { Write-Host "  $f" }
    exit 1
}
exit 0
