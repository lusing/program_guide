<#
.SYNOPSIS
    Elixir 教程统一验证脚本（Windows 入口，须 PowerShell 7 / pwsh 运行）

.DESCRIPTION
    与 run-all.sh 完全等价的五层验证，两条入口必须给出同样的结论：
      1) mix format --check-formatted       格式
      2) mix compile --warnings-as-errors   编译零告警
      3) mix test                           ExUnit 测试全绿
      4) mix run --no-compile run.exs       运行 + 四条判定
      5) ERL_FLAGS="+S 1:1" 重跑            stdout 与通道 A 逐字节一致

    第 4 层的四条判定：退出码 0 / stderr 为空 / stdout 非空且无控制字符 /
    stdout 含结束标记「==== NN 结束 ===="。

.PARAMETER All
    验证 examples 下全部示例。

.PARAMETER Example
    只验证单个示例目录名，例如 12_processes。

.PARAMETER Clean
    清理 build/ 下全部产物。

.EXAMPLE
    pwsh -ExecutionPolicy Bypass -File build.ps1 -All
    pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 15_gen_server
#>
[CmdletBinding()]
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

$BuildDir = Join-Path $ProjectRoot 'build'
$ExamplesDir = Join-Path $ProjectRoot 'examples'

# ---- 控制台编码：中文输出必须 UTF-8，否则 PowerShell 7 会按 OEM 码页乱码 ----
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch { }

# ---- 故意往 stderr 写内容的示例（与 run-all.sh 的 STDERR_ALLOW 保持一致）----
$StderrAllow = @('11_errors')
# ---- 允许双通道输出不一致的示例（默认空，与 DETERMINISM_ALLOW 一致）----
$DeterminismAllow = @()

# ---- 工具链定位：ELIXIR_MIX 环境变量 → scoop 固定路径 → PATH ----
function Resolve-Mix {
    if ($env:ELIXIR_MIX) { return $env:ELIXIR_MIX }
    $candidates = @(
        "$env:USERPROFILE\scoop\shims\mix.ps1",
        "$env:USERPROFILE\scoop\shims\mix.cmd",
        'G:\scoop\apps\elixir\current\bin\mix.ps1',
        'G:\scoop\apps\elixir\current\bin\mix.bat'
    )
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
    $found = Get-Command mix -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    throw '未找到 mix：请安装 Elixir（本教程按 1.20.2 / OTP 29 实测），或设 $env:ELIXIR_MIX 指向 mix 可执行文件。'
}

$Mix = Resolve-Mix

if ($Clean) {
    if (Test-Path -LiteralPath $BuildDir) {
        Get-ChildItem -LiteralPath $BuildDir -Force | Remove-Item -Recurse -Force
        Write-Host '[Clean] 已清理 build/ 下全部产物。' -ForegroundColor Yellow
    } else {
        Write-Host '[Clean] build/ 不存在，无需清理。' -ForegroundColor Yellow
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$script:Pass = 0
$script:Fail = 0
$script:FailedNames = @()

function Invoke-Mix {
    param([string]$WorkDir, [string[]]$MixArgs, [string]$StdoutPath, [string]$StderrPath, [string]$ErlFlags = '')

    Push-Location $WorkDir
    try {
        $prevErl = $env:ERL_FLAGS
        if ($ErlFlags) { $env:ERL_FLAGS = $ErlFlags } else { Remove-Item Env:\ERL_FLAGS -ErrorAction SilentlyContinue }
        & $Mix @MixArgs 1>>$StdoutPath 2>>$StderrPath
        $code = $LASTEXITCODE
        if ($null -ne $prevErl) { $env:ERL_FLAGS = $prevErl } else { Remove-Item Env:\ERL_FLAGS -ErrorAction SilentlyContinue }
        return $code
    } finally {
        Pop-Location
    }
}

function Test-HasControlChars {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    foreach ($b in $bytes) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Compare-RunOutput {
    param([string]$A, [string]$B)
    if (-not (Test-Path -LiteralPath $A) -or -not (Test-Path -LiteralPath $B)) { return $false }
    $ha = (Get-FileHash -LiteralPath $A -Algorithm SHA256).Hash
    $hb = (Get-FileHash -LiteralPath $B -Algorithm SHA256).Hash
    return $ha -eq $hb
}

function Test-Example {
    param([string]$Dir)

    $Name = Split-Path -Path $Dir -Leaf
    $NN = ($Name -split '_')[0]
    $Marker = "==== $NN 结束 ===="

    $CompileOut = Join-Path $BuildDir "$Name.compile.out"
    $TestOut = Join-Path $BuildDir "$Name.test.out"
    $Err = Join-Path $BuildDir "$Name.err"
    $RunOut = Join-Path $BuildDir "$Name.run.out"
    $RunOut2 = Join-Path $BuildDir "$Name.run.S1.out"
    foreach ($f in @($CompileOut, $TestOut, $Err, $RunOut, $RunOut2)) {
        Set-Content -LiteralPath $f -Value '' -NoNewline -Encoding utf8NoBOM
    }

    Write-Host ''
    Write-Host "[Example] $Name" -ForegroundColor Cyan

    # 产物集中到 build/<示例名>/，示例目录保持干净
    $env:MIX_BUILD_ROOT = Join-Path $BuildDir $Name
    $env:MIX_ENV = 'dev'

    $reasons = @()

    # 第 1 层：格式
    $code = Invoke-Mix -WorkDir $Dir -MixArgs @('format', '--check-formatted') -StdoutPath $CompileOut -StderrPath $Err
    if ($code -ne 0) { $reasons += 'format 未通过' }

    # 第 2 层：编译零告警
    $code = Invoke-Mix -WorkDir $Dir -MixArgs @('compile', '--warnings-as-errors', '--force') -StdoutPath $CompileOut -StderrPath $Err
    if ($code -ne 0) { $reasons += '编译有告警' }

    # 第 3 层：测试
    $code = Invoke-Mix -WorkDir $Dir -MixArgs @('test', '--color') -StdoutPath $TestOut -StderrPath $Err
    if ($code -ne 0) { $reasons += '测试未通过' }

    # 第 4 层：运行 + 四条判定（通道 A）
    $code = Invoke-Mix -WorkDir $Dir -MixArgs @('run', '--no-compile', 'run.exs') -StdoutPath $RunOut -StderrPath $Err
    if ($code -ne 0) { $reasons += "运行退出码 $code" }

    $errText = (Get-Content -LiteralPath $Err -Raw -ErrorAction SilentlyContinue)
    if (($StderrAllow -notcontains $Name) -and $errText -and $errText.Trim().Length -gt 0) {
        $reasons += 'stderr 非空（有告警）'
    }
    $runText = (Get-Content -LiteralPath $RunOut -Raw -ErrorAction SilentlyContinue)
    if (-not $runText -or $runText.Trim().Length -eq 0) { $reasons += 'stdout 为空（没真跑起来）' }
    if (Test-HasControlChars -Path $RunOut) { $reasons += 'stdout 含控制字符' }
    if (-not $runText -or -not $runText.Contains($Marker)) { $reasons += "缺结束标记「$Marker」" }

    # 第 5 层：单调度器重跑，stdout 必须逐字节一致（通道 B）
    $code = Invoke-Mix -WorkDir $Dir -MixArgs @('run', '--no-compile', 'run.exs') -StdoutPath $RunOut2 -StderrPath $Err -ErlFlags '+S 1:1'
    if ($DeterminismAllow -notcontains $Name) {
        if (-not (Compare-RunOutput -A $RunOut -B $RunOut2)) { $reasons += '双通道输出不一致（+S 1:1）' }
    }

    Remove-Item Env:\MIX_BUILD_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:\MIX_ENV -ErrorAction SilentlyContinue

    # 示例输出照常打出来（教程用法：读讲解 → 跑示例 → 改代码再跑）
    if ($runText) { Write-Host $runText }

    if ($reasons.Count -gt 0) {
        Write-Host "[FAIL] $Name：$($reasons -join '; ')" -ForegroundColor Red
        if ($errText -and $errText.Trim().Length -gt 0) {
            Write-Host "---- $Name 的 stderr ----" -ForegroundColor DarkGray
            ($errText -split "`n" | Select-Object -First 30) | ForEach-Object { Write-Host $_ }
            Write-Host '----------------------' -ForegroundColor DarkGray
        }
        $script:Fail++
        $script:FailedNames += $Name
        return $false
    }
    Write-Host "[OK] $Name 五层验证通过" -ForegroundColor Green
    $script:Pass++
    return $true
}

if ($Example) {
    $dir = Join-Path $ExamplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-Example -Dir $dir | Out-Null
    Write-Host ''
    if ($script:Fail -eq 0) { Write-Host "[Done] $Example 五层验证通过。" -ForegroundColor Green; exit 0 }
    Write-Host "[Done] $Example 验证失败。" -ForegroundColor Red; exit 1
}

if ($All) {
    $dirs = Get-ChildItem -LiteralPath $ExamplesDir -Directory |
        Where-Object { $_.Name -match '^\d\d' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'mix.exs')) } |
        Sort-Object Name
    if ($dirs.Count -eq 0) { throw 'examples 下没有 mix 工程示例。' }
    foreach ($d in $dirs) { Test-Example -Dir $d.FullName | Out-Null }

    Write-Host ''
    $total = $script:Pass + $script:Fail
    Write-Host "通过 $($script:Pass)   失败 $($script:Fail)   共 $total"
    if ($script:Fail -ne 0) {
        Write-Host "失败项：$($script:FailedNames -join ' ')" -ForegroundColor Red
        exit 1
    }
    Write-Host '[Done] 全部示例五层验证通过（format + 零告警 + test + 运行 + 双通道一致）。' -ForegroundColor Green
    exit 0
}

Write-Host '用法:' -ForegroundColor Yellow
Write-Host '  pwsh -File build.ps1 -All                    验证 examples 下全部示例'
Write-Host '  pwsh -File build.ps1 -Example 12_processes   验证单个示例'
Write-Host '  pwsh -File build.ps1 -Clean                  清理 build/ 产物'
