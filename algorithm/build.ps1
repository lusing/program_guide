<#
  build.ps1 —— 编译 + 运行 + 自检 examples 下的全部示例（PowerShell 入口）

    pwsh ./build.ps1 -All                 全量：逐示例编译（零告警）+ 运行自检 + 文档五关
    pwsh ./build.ps1 -Example 02_getting_started   单示例
    pwsh ./build.ps1 18 22                按编号跑（位置参数）
    pwsh ./build.ps1 -All -ShowOutput     附带打印每个示例的运行输出
    pwsh ./build.ps1 -Docs                只跑文档五关（tools/check_docs.py）
    pwsh ./build.ps1 -Clean               清理 build 目录

  三条通道（本教程在 Windows 上验证；非 Windows 见 run-all.sh 的声明式跳过）：

    msvc  : MSVC cl（经 vcvars64 进环境）—— 主线，/std:c++23（探针不合格时退 c++latest）
    clang : scoop clang++ 23（x86_64-pc-windows-msvc，共享 MSVC STL、独立前端）
            —— 交叉核对通道：与 msvc 输出逐字节比对，不一致几乎必是 UB
    gcc   : scoop MinGW g++ 15（独立 libstdc++）—— 机会型通道，两级探针资格制：
            已知坑（2026-09-28 实测，见 designpattern/build.ps1 注释）：MinGW libstdc++
            缺 std::__open_terminal 符号，一链接 <print> 必挂。仅此一挂时通道带
            -DALGO_NO_PRINT 继续（示例顶部的 8 行 IO 垫片兜底，docs/01 有讲解）；
            再挂 -DALGO_NO_GENERATOR；全挂才禁用该通道。

  判定标准（六条，缺一不可）：
    1) 退出码为 0
    2) stderr 为空（编译期的警告也算失败 —— MSVC 的 /W4 对应 -Wall -Wextra）
    3) stdout 非空（防"进程根本没跑到业务代码，退出码却是 0"这类假阳性）
    4) stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
    5) stdout 里有结束标记 "自检通过"
    6) 编译日志干净（clang/gcc 为空；MSVC 不含 warning/error）
       —— 编译命令把 stderr 并进了日志文件，所以第 2 条盖不住编译期告警

  另有两道附加关（全量模式下）：
    A) 跨通道对账：msvc↔clang、msvc↔gcc 的 stdout 逐字节一致
       （已知差异走 Get-DiffReason 豁免并注明原因）
    B) 文档五关：-All 全绿后自动调 tools/check_docs.py（可单独 -Docs）
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean,
    [switch]$ShowOutput,
    [switch]$Docs,
    # 位置参数当"示例编号"用：./build.ps1 18 22
    # 必须同时有 CmdletBinding(PositionalBinding=$false) 和下面这一行，
    # 少一个就会报 "A positional parameter cannot be found"
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Select
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
if (-not $onWindows) {
    throw "本教程在 Windows 上验证（MSVC 主线）。非 Windows 平台请看 run-all.sh 的声明式跳过说明。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"
$tmpDir      = Join-Path $buildDir "tmp"
$marker      = "自检通过"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $tmpDir    | Out-Null

# ---------------------------------------------------------------
# 工具链定位：环境变量优先 → scoop 常见路径 → PATH
#   CXX_CLANG / CXX_GCC / VCVARS
# ---------------------------------------------------------------
function Resolve-Tool {
    param([string]$EnvVar, [string[]]$Candidates)
    $candidate = ""
    if ($EnvVar) { $candidate = [Environment]::GetEnvironmentVariable($EnvVar) }
    if ($candidate -and -not (Test-Path -LiteralPath $candidate)) { $candidate = "" }
    if (-not $candidate) {
        foreach ($c in $Candidates) {
            if (Test-Path -LiteralPath $c) { $candidate = $c; break }
        }
    }
    if (-not $candidate) {
        foreach ($c in $Candidates) {
            $cmd = Get-Command $c -ErrorAction SilentlyContinue
            if ($cmd) { $candidate = $cmd.Source; break }
        }
    }
    return $candidate
}

# MSVC：优先 $env:VCVARS，其次 vswhere 问一下（不硬编码盘符）
$vcvars = ""
if ($env:VCVARS) {
    $vcvars = $env:VCVARS
} else {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path -LiteralPath $vswhere) {
        $hit = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
                          -property installationPath 2>$null | Select-Object -First 1
        if ($hit) { $vcvars = Join-Path $hit "VC\Auxiliary\Build\vcvars64.bat" }
    }
}
$msvc = ""
if ($vcvars -and (Test-Path -LiteralPath $vcvars)) { $msvc = $vcvars }

$clangxx = Resolve-Tool "CXX_CLANG" @("D:\scoop\apps\llvm\current\bin\clang++.exe", "clang++")
$gccxx   = Resolve-Tool "CXX_GCC"   @("D:\scoop\apps\gcc\current\bin\g++.exe", "g++")

# Windows 原生 clang（scoop LLVM，x86_64-pc-windows-msvc）自动探测 MSVC 的 STL
# 与链接库，什么 -stdlib/-lc++ 都不要加 —— 加了反而链接失败（cpp20 实测）。
$clangCflags  = @()
$clangLdflags = @()
$gccCflags    = @("-pthread")
$gccLdflags   = @("-pthread")

$commonFlags = @("-std=c++23", "-Wall", "-Wextra", "-O2")

# MSVC 的语言档：/std:c++23 为准（本教程定位就是 C++23，顺带挡住 C++26 特性
# 误用）；探针不过再退 /std:c++latest。
$msvcStd = "/std:c++23"

# 计数口径：按「每个示例 × 每条通道」计。
$script:passCount = 0
$script:failCount = 0

function Get-Channels {
    $list = @()
    if ($msvc)   { $list += "msvc" }
    if ($clangxx) { $list += "clang" }
    if ($gccxx)   { $list += "gcc" }
    return $list
}

# ---------------------------------------------------------------
# 已知的跨工具链差异（原因写清楚，免得后人以为是回归）。
# 纪律：能修的一律修，修不了的在这里登记并写明根因。
# ---------------------------------------------------------------
function Get-DiffReason {
    param([string]$Name)
    switch ($Name) {
        "28_parallel" { return "多线程调度导致的输出行序差异（结果按索引回收仍可能因进度行交错）" }
        default       { return "" }
    }
}

# ---------------------------------------------------------------
# 进程捕获：按**字节**重定向 stdout/stderr
#
# 不要用 Start-Process -RedirectStandardOutput：它会把输出里的空行吞掉
# （"A\n\nB\n" 落盘变成 "A\nB\n"）。用 .NET 直接开进程 + 流拷贝，逐字节落地。
# ---------------------------------------------------------------
function Invoke-Capture {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkDir = $projectRoot,
        [int]$TimeoutMs = 300000,
        # 非空时把整个字符串原样作为命令行尾巴（不再逐参数转义）。
        # 只给 cmd.exe 的批处理入口用：pwsh 7.6/.NET 9 起 ArgumentList 会把
        # 内嵌引号转义成 \"，cmd 的 /c 引号规则一搅和，vcvars64.bat 就变成了
        # 带字面反斜杠引号的"未知命令"（designpattern 2026-09-28 实测回归）。
        [string]$RawArgs = ""
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Exe
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.WorkingDirectory       = $WorkDir
    $psi.EnvironmentVariables["TMPDIR"] = $tmpDir

    if ($RawArgs -ne "") {
        $psi.Arguments = $RawArgs
    } else {
        foreach ($a in $Args) { $psi.ArgumentList.Add($a) }
    }

    $outFs = [System.IO.File]::Create($OutFile)
    $errFs = [System.IO.File]::Create($ErrFile)
    $timedOut = $false
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $outTask = $p.StandardOutput.BaseStream.CopyToAsync($outFs)
        $errTask = $p.StandardError.BaseStream.CopyToAsync($errFs)
        if (-not $p.WaitForExit($TimeoutMs)) {
            $p.Kill()
            $p.WaitForExit(5000) | Out-Null
            $timedOut = $true
        }
        try { $outTask.GetAwaiter().GetResult() | Out-Null } catch {}
        try { $errTask.GetAwaiter().GetResult() | Out-Null } catch {}
        $code = $p.ExitCode
    } finally {
        $outFs.Dispose()
        $errFs.Dispose()
    }
    return @{ ExitCode = $code; TimedOut = $timedOut }
}

# 走 cmd.exe 跑一段批处理（MSVC 需要先 call vcvars64.bat 才认得 cl）。
function Invoke-Batch {
    param(
        [Parameter(Mandatory = $true)][string]$CommandLine,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkDir = $projectRoot
    )
    return Invoke-Capture -Exe $env:ComSpec -RawArgs ("/c " + $CommandLine) `
                          -OutFile $OutFile -ErrFile $ErrFile -WorkDir $WorkDir
}

# ---------------------------------------------------------------
# 通道体检（两级探针）。探针源码本身就用示例同款的 8 行 IO 垫片，
# 编译 + 链接 + 运行三关都过才算资格；clang/gcc 按
#   级 0（无宏）→ 级 1（-DALGO_NO_PRINT）→ 级 2（再 -DALGO_NO_GENERATOR）
# 逐级降级；MSVC 只验 /std:c++23 档位（不过则退 /std:c++latest）。
# ---------------------------------------------------------------
$probeSrc = Join-Path $buildDir "_probe_$PID.cpp"
Set-Content -LiteralPath $probeSrc -Encoding utf8 -Value @'
#include <ranges>
#include <utility>
#include <vector>
#ifdef ALGO_NO_PRINT
#include <cstdio>
#include <format>
template <class... A> void println(std::format_string<A...> f, A&&... a) {
    std::printf("%s\n", std::format(f, std::forward<A>(a)...).c_str());
}
#else
#include <print>
using std::println;
#endif
#ifndef ALGO_NO_GENERATOR
#include <generator>
#endif
int main() {
    std::vector<int> v{1, 2, 3};
    auto zipped = std::views::zip(v, v) | std::ranges::to<std::vector>();
    int total = 0;
    for (auto&& [a, b] : zipped) { total += a + b; }
    for (auto&& chunk : v | std::views::chunk_by([](int, int y) { return y != 3; })) {
        total += static_cast<int>(chunk.size());
    }
#ifndef ALGO_NO_GENERATOR
    auto gen = []() -> std::generator<int> { co_yield 42; };
    for (int x : gen()) { total += x; }
#endif
    println("probe {}", total);
    return 0;
}
'@

if ($msvc) {
    # MSVC 探针：/std:c++23 不认就退 /std:c++latest
    $probeExe = Join-Path $buildDir "_probe_msvc_$PID.exe"
    $bld = Join-Path $buildDir "_probe_msvc_$PID.build"
    $bldErr = Join-Path $buildDir "_probe_msvc_$PID.builderr"
    $foArg = '/Fo"{0}\_probe_msvc_{1}_"' -f $buildDir, $PID
    $feArg = '/Fe"{0}"' -f $probeExe
    $srcArg = '"{0}"' -f $probeSrc
    $argStr = (@("/nologo", $msvcStd, "/EHsc", "/utf-8", "/permissive-", "/Zc:__cplusplus", "/W4",
                 $foArg, $feArg, $srcArg) -join ' ')
    $r = Invoke-Batch -CommandLine ('call "{0}" >nul && cl {1}' -f $vcvars, $argStr) `
                      -OutFile $bld -ErrFile $bldErr -WorkDir $buildDir
    if ($r.ExitCode -ne 0 -and $msvcStd -eq "/std:c++23") {
        $msvcStd = "/std:c++latest"
        $argStr = (@("/nologo", $msvcStd, "/EHsc", "/utf-8", "/permissive-", "/Zc:__cplusplus", "/W4",
                     $foArg, $feArg, $srcArg) -join ' ')
        $r = Invoke-Batch -CommandLine ('call "{0}" >nul && cl {1}' -f $vcvars, $argStr) `
                          -OutFile $bld -ErrFile $bldErr -WorkDir $buildDir
    }
    if ($r.ExitCode -ne 0) {
        Write-Host "[skip] msvc 通道探针失败，本机禁用（详见 build/_probe_msvc_$PID.builderr）" -ForegroundColor DarkYellow
        $msvc = ""
    }
}

# clang/gcc 的降级阶梯：每级一组额外宏
$probeLevels = @(
    @{ Defines = @();                                                    Note = "全量特性" }
    @{ Defines = @("-DALGO_NO_PRINT");                                   Note = "<print> 降级（IO 垫片）" }
    @{ Defines = @("-DALGO_NO_PRINT", "-DALGO_NO_GENERATOR");            Note = "<print>+<generator> 双降级" }
)
foreach ($pair in @(@("clang", "clangxx", "clangCflags", "clangLdflags"),
                    @("gcc",   "gccxx",   "gccCflags",   "gccLdflags"))) {
    $chan, $toolVar, $cfVar, $lfVar = $pair
    if (-not (Get-Variable -Name $toolVar -ValueOnly)) { continue }
    $tool = Get-Variable -Name $toolVar -ValueOnly
    $cf   = @(Get-Variable -Name $cfVar -ValueOnly)
    $lf   = @(Get-Variable -Name $lfVar -ValueOnly)
    $passed = $false
    foreach ($lvl in $probeLevels) {
        $probeExe = Join-Path $buildDir "_probe_${chan}_$PID.exe"
        $r = Invoke-Capture -Exe $tool `
                -Args (@($commonFlags) + $lvl.Defines + $cf + @($probeSrc, "-o", $probeExe) + $lf) `
                -OutFile (Join-Path $buildDir "_probe_${chan}_$PID.build") `
                -ErrFile (Join-Path $buildDir "_probe_${chan}_$PID.builderr") -WorkDir $buildDir
        $ok = ($r.ExitCode -eq 0)
        if ($ok) {
            $r2 = Invoke-Capture -Exe $probeExe -Args @() `
                    -OutFile (Join-Path $buildDir "_probe_${chan}_$PID.out") `
                    -ErrFile (Join-Path $buildDir "_probe_${chan}_$PID.err") -WorkDir $buildDir
            $ok = ($r2.ExitCode -eq 0)
        }
        if ($ok) {
            if ($lvl.Defines.Count -gt 0) {
                Write-Host ("[probe] {0} 通道以 {1} 通过：{2}" -f $chan, ($lvl.Defines -join " "), $lvl.Note) -ForegroundColor DarkYellow
                Set-Variable -Name $cfVar -Value (@($cf) + @($lvl.Defines))
            }
            $passed = $true
            break
        }
    }
    if (-not $passed) {
        Write-Host ("[skip] {0} 通道探针全级失败，本机禁用（详见 build/_probe_{1}_$PID.builderr）" -f $chan, $chan) -ForegroundColor DarkYellow
        Set-Variable -Name $toolVar -Value ""
        Set-Variable -Name $cfVar   -Value @()
        Set-Variable -Name $lfVar   -Value @()
    }
}

function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    # Get-Content -Raw 读空文件返回 $null，必须兜底
    $text = [string](Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue)
    if ($null -eq $text) { $text = "" }
    return $text
}

# 输出里是否混进了「不该出现」的控制字符（TAB/LF/CR 除外）。按字节判，不碰正则。
function Test-HasCtrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# 编译日志是否"干净"：clang/gcc 成功时一个字都不打；
# MSVC 即使成功也会回显源文件名，所以只在它出现 warning/error 时判失败。
function Test-BuildClean {
    param([string]$Channel, [string]$LogText)
    if ($Channel -eq "msvc") {
        return -not ($LogText -match "(?i)\b(warning|error)\b")
    }
    return ($LogText.Trim() -eq "")
}

function Test-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$BuildLog,
        [Parameter(Mandatory = $true)][string]$BuildErr,
        [Parameter(Mandatory = $true)][string]$Channel,
        [switch]$TimedOut
    )

    $reasons = @()
    if ($TimedOut) { $reasons += "超过 300 秒未结束（多半是死循环）" }
    if ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }

    $errText = Read-TextFile $ErrPath
    if ($errText.Trim() -ne "") {
        $first = ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "stderr 非空（警告也算失败）：$($first.Trim())"
    }
    if (-not (Test-Path -LiteralPath $OutPath) -or (Get-Item -LiteralPath $OutPath).Length -eq 0) {
        $reasons += "stdout 为空（进程没跑到业务代码）"
    }
    if (Test-HasCtrl $OutPath) { $reasons += "stdout 含多余控制字符" }
    if ((Read-TextFile $OutPath) -notlike "*$marker*") { $reasons += "缺少结束标记 $marker" }

    # 编译诊断可能落在两个文件里：clang/gcc 的告警走 stderr → .builderr，
    # MSVC 的回显走 stdout → .build。两个都要看，漏一个就等于没判"零告警"。
    $bldText = (Read-TextFile $BuildLog) + (Read-TextFile $BuildErr)
    if (-not (Test-BuildClean -Channel $Channel -LogText $bldText)) {
        $first = ($bldText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "编译有告警/错误：$($first.Trim())"
    }

    if ($reasons.Count -eq 0) {
        Write-Host ("  [OK]   {0}" -f $Tag) -ForegroundColor Green
        return $true
    }
    Write-Host ("  [FAIL] {0} —— {1}" -f $Tag, ($reasons -join "；")) -ForegroundColor Red
    return $false
}

# ---------------------------------------------------------------
# 一个示例的一轮编译+运行（单通道）
# ---------------------------------------------------------------
function Invoke-OneChannel {
    param(
        [Parameter(Mandatory = $true)][string]$Channel,
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $bin     = Join-Path $buildDir "$Name.$Channel"
    if ($Channel -eq "msvc") { $bin = Join-Path $buildDir "$Name.exe" }
    $outPath = Join-Path $buildDir "$Name.$Channel.out"
    $errPath = Join-Path $buildDir "$Name.$Channel.err"
    $bldLog  = Join-Path $buildDir "$Name.$Channel.build"
    $bldErr  = Join-Path $buildDir "$Name.$Channel.builderr"

    if ($Channel -eq "msvc") {
        # ---- MSVC：目录里所有 .cpp 一次编译+链接（本教程无模块章，不需要三步）----
        $srcs = @(Get-ChildItem -LiteralPath $Dir -Filter "*.cpp" | Sort-Object Name |
                    ForEach-Object { "`"$($_.FullName)`"" })
        if ($srcs.Count -eq 0) { throw "示例目录里没有 .cpp：$Dir" }
        $argStr = (@("/nologo", $msvcStd, "/EHsc", "/utf-8", "/permissive-", "/Zc:__cplusplus", "/W4", "/O2",
                     ('/Fo"{0}\{1}_"' -f $buildDir, $Name), ('/Fe"{0}"' -f $bin)) + $srcs) -join ' '
        $r = Invoke-Batch -CommandLine ('call "{0}" >nul && cl {1}' -f $vcvars, $argStr) `
                          -OutFile $bldLog -ErrFile $bldErr -WorkDir $buildDir
        if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
    }
    else {
        # ---- clang / gcc：目录里所有 .cpp 一次编出来 ----
        $exe = if ($Channel -eq "clang") { $clangxx } else { $gccxx }
        $cflags = if ($Channel -eq "clang") { $clangCflags } else { $gccCflags }
        $ldflags = if ($Channel -eq "clang") { $clangLdflags } else { $gccLdflags }
        $srcPaths = @(Get-ChildItem -LiteralPath $Dir -Filter "*.cpp" | Sort-Object Name |
                        ForEach-Object { $_.FullName })
        if ($srcPaths.Count -eq 0) { throw "示例目录里没有 .cpp：$Dir" }
        $args_ = @($commonFlags) + $cflags + @("-I$Dir") + $srcPaths + @("-o", $bin) + $ldflags
        $r = Invoke-Capture -Exe $exe -Args $args_ -OutFile $bldLog -ErrFile $bldErr -WorkDir $projectRoot
        if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
    }

    # 示例统一在 build/ 下跑（写临时文件走 TMPDIR）
    $run = Invoke-Capture -Exe $bin -Args @() -OutFile $outPath -ErrFile $errPath -WorkDir $buildDir
    return @{ Ok = $true; Result = $run }
}

function Compare-Outputs {
    param([string]$Name, [string[]]$Chans)
    # 主线 msvc 与其余每条通道两两比对（基准 = msvc 的产物）
    $base = Join-Path $buildDir "$Name.msvc.out"
    if (-not (Test-Path -LiteralPath $base)) { return $true }
    $okAll = $true
    foreach ($other in ($Chans | Where-Object { $_ -ne "msvc" })) {
        $b = Join-Path $buildDir "$Name.$other.out"
        if (-not (Test-Path -LiteralPath $b)) { continue }
        $ba = [System.IO.File]::ReadAllBytes($base)
        $bb = [System.IO.File]::ReadAllBytes($b)
        $same = ($ba.Length -eq $bb.Length)
        if ($same) {
            for ($i = 0; $i -lt $ba.Length; $i++) { if ($ba[$i] -ne $bb[$i]) { $same = $false; break } }
        }
        if ($ba.Length -gt 0 -and $bb.Length -gt 0) {
            if ($same) {
                Write-Host "  [same] msvc ↔ $other 输出逐字节一致" -ForegroundColor DarkGray
            } else {
                $reason = Get-DiffReason $Name
                if ($reason -ne "") {
                    Write-Host ("  [diff] msvc ↔ {0} 已知差异：{1}" -f $other, $reason) -ForegroundColor DarkYellow
                } else {
                    Write-Host "  [DIFF] msvc ↔ $other 输出不一致（意外差异，见 build/$Name.*.out）" -ForegroundColor Red
                    $okAll = $false
                }
            }
        }
    }
    return $okAll
}

function Invoke-Example {
    param([Parameter(Mandatory = $true)][string]$Dir)

    $name = Split-Path -Leaf $Dir
    Write-Host "==== $name ====" -ForegroundColor Cyan
    $allOk = $true

    foreach ($channel in (Get-Channels)) {
        $r = Invoke-OneChannel -Channel $channel -Dir $Dir -Name $name
        if (-not $r.Ok) {
            # 编译失败：把编译日志清成 stdout/stderr 内容，让判定函数统一报出来
            $outPath = Join-Path $buildDir "$name.$channel.out"
            $errPath = Join-Path $buildDir "$name.$channel.err"
            [System.IO.File]::WriteAllBytes($outPath, @())
            $msg = (Read-TextFile (Join-Path $buildDir "$name.$channel.build")) +
                   (Read-TextFile (Join-Path $buildDir "$name.$channel.builderr"))
            [System.IO.File]::WriteAllText($errPath, "编译失败`n$msg")
            $first = ($msg -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 3)
            Write-Host ("  [FAIL] {0,-8} {1} —— 编译失败" -f $channel, $name) -ForegroundColor Red
            $first | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
            $script:failCount++
            $allOk = $false
            continue
        }
        if (Test-Result -Tag ("{0,-8} {1}" -f $channel, $name) `
                    -OutPath (Join-Path $buildDir "$name.$channel.out") `
                    -ErrPath (Join-Path $buildDir "$name.$channel.err") `
                    -ExitCode $r.Result.ExitCode -BuildLog (Join-Path $buildDir "$name.$channel.build") `
                    -BuildErr (Join-Path $buildDir "$name.$channel.builderr") `
                    -Channel $channel -TimedOut:$r.Result.TimedOut) {
            $script:passCount++
        } else {
            $script:failCount++
            $allOk = $false
        }
        if ($ShowOutput) {
            Get-Content -LiteralPath (Join-Path $buildDir "$name.$channel.out") -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Host "        $_" }
        }
    }

    # ---- 跨通道对账：msvc 与每条启用通道逐字节一致 ----
    $chans = Get-Channels
    if ($chans.Count -ge 2) {
        if (-not (Compare-Outputs -Name $name -Chans $chans)) { $allOk = $false }
    }

    return $allOk
}

function Get-ExampleDirs {
    param([string[]]$Numbers)
    $dirs = @(Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name)
    if ($Numbers -and $Numbers.Count -gt 0) {
        $dirs = @($dirs | Where-Object { $Numbers -contains ($_.Name -split "_")[0] })
    }
    return $dirs
}

function Invoke-DocsCheck {
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) {
        Write-Host "[Docs] 找不到 python，跳过文档五关（不判失败）" -ForegroundColor DarkYellow
        return $true
    }
    Write-Host "==== 文档五关（tools/check_docs.py） ====" -ForegroundColor Cyan
    # python 的 stdout/stderr 一律经 pwsh 转发（某些重定向层级下原样透传会丢行）
    & $py.Source (Join-Path $projectRoot "tools\check_docs.py") 2>&1 | ForEach-Object { Write-Host $_ }
    return ($LASTEXITCODE -eq 0)
}

if ($Docs) {
    if (-not (Invoke-DocsCheck)) { exit 1 }
    exit 0
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    if (-not (Invoke-Example -Dir $dir)) { exit 1 }
    Write-Host "[Done] 验证通过: $Example" -ForegroundColor Green
    exit 0
}

# 只有位置编号（-All 可省）
if ($Select -and $Select.Count -gt 0) { $All = $true }

if ($All) {
    $dirs = Get-ExampleDirs -Numbers $Select
    if ($dirs.Count -eq 0) {
        # 骨架阶段的空转：examples 还没有示例不算失败
        Write-Host "[All] examples 下暂无示例 —— 骨架空转通过（文档五关照跑）" -ForegroundColor Yellow
        if (-not (Invoke-DocsCheck)) { exit 1 }
        exit 0
    }

    $failedList = @()
    foreach ($d in $dirs) {
        if (-not (Invoke-Example -Dir $d.FullName)) { $failedList += $d.Name }
    }

    $nchan = (Get-Channels).Count
    Write-Host "--------------------------------" -ForegroundColor DarkGray
    Write-Host ("通过 {0}   失败 {1}   （{2} 个示例 × {3} 条通道）" -f `
                $script:passCount, $script:failCount, $dirs.Count, $nchan) `
               -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })
    if ($script:failCount -ne 0) {
        Write-Host "失败项：" -ForegroundColor Red
        $failedList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "[Done] 全部 $($dirs.Count) 个示例编译+运行通过。" -ForegroundColor Green
    if (-not (Invoke-DocsCheck)) { exit 1 }
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  ./build.ps1 -All                 全量：逐示例编译（零告警）+ 运行自检 + 文档五关"
Write-Host "  ./build.ps1 -Example 02_getting_started   单示例编译+运行"
Write-Host "  ./build.ps1 18 22                按编号跑"
Write-Host "  ./build.ps1 -All -ShowOutput     附带打印运行输出"
Write-Host "  ./build.ps1 -Docs                只跑文档五关"
Write-Host "  ./build.ps1 -Clean               清理 build 目录"
Write-Host ""
Write-Host "判定标准：退出码 0 + stderr 为空 + stdout 非空 + 无多余控制字符 + 有 '$marker'"
Write-Host "提示：Windows 上也可用 ./run-all.sh（转发到本脚本）。"
