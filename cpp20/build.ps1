<#
  build.ps1 —— 编译 + 运行 + 自检 examples 下的全部示例（PowerShell 入口）

    pwsh ./build.ps1 -All                 全量：逐示例编译（零告警）+ 运行自检
    pwsh ./build.ps1 -Example 06_compound 单示例
    pwsh ./build.ps1 18 22                按编号跑（位置参数）
    pwsh ./build.ps1 -All -ShowOutput     附带打印每个示例的运行输出
    pwsh ./build.ps1 -Clean               清理 build 目录

  两条通道（与 ./run-all.sh 完全等价，两个入口的结论必须一致）：

    Windows : MSVC cl（经 vcvars64 进环境）—— 教程原本的主线
    macOS   : clang++ 23 + clang 自带的 libc++（主）+ g++ 15 + libstdc++（对照）
    Linux   : 同上（clang 走系统 libstdc++/libc++）

  判定标准（六条，缺一不可）：
    1) 退出码为 0
    2) stderr 为空（编译期的警告也算失败 —— MSVC 的 /W4 对应 -Wall -Wextra）
    3) stdout 非空（防"进程根本没跑到业务代码，退出码却是 0"这类假阳性）
    4) stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
    5) stdout 里有结束标记 "自检通过"
    6) 编译日志干净（clang/gcc 为空；MSVC 不含 warning/error）
       —— 编译命令把 stderr 并进了日志文件，所以第 2 条盖不住编译期告警

  结束标记用示例自己最后一行打印的 "自检通过"，不用 "==== NN 结束 ===="：
  docs/ 下 24 章正文里嵌了示例的完整输出，改一行文案就要同步 24 篇文档；
  "自检通过"本来就承担了这个语义。
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean,
    [switch]$ShowOutput,
    # 位置参数当"示例编号"用：./build.ps1 18 22
    # 必须同时有 CmdletBinding(PositionalBinding=$false) 和下面这一行，
    # 少一个就会报 "A positional parameter cannot be found"
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Select
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 跨平台判定。注意 pwsh 在**所有平台**都有只读自动变量 $IsWindows，
# 而 PowerShell 变量名不区分大小写 —— 自己写 $isWindows = ... 会直接报
# "Cannot overwrite variable IsWindows"。下面这行的后半段兼容 Windows
# PowerShell 5.1（它没有 $IsWindows）。
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }

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

# build/tmp 是给示例运行时用的 TMPDIR。清一遍防"外来垃圾"：编译被信号打断、
# 手工在 build/ 下敲过编译器、或别的工具用了这个 TMPDIR 时都会在这里留下中间产物。
foreach ($pat in @('*.s', '*.o', '*.d', '*.ii')) {
    Get-ChildItem -LiteralPath $tmpDir -Filter $pat -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------
# 工具链定位：环境变量优先 → MacPorts 路径 → PATH
#   CXX_CLANG / CXX_GCC
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

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$msvc = ""
if ($onWindows) {
    if ($env:VCVARS) {
        $vcvars = $env:VCVARS
    } elseif (-not (Test-Path -LiteralPath $vcvars)) {
        # VS 装在别处时退回到 vswhere 问一下
        $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path -LiteralPath $vswhere) {
            $hit = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
                              -property installationPath 2>$null | Select-Object -First 1
            if ($hit) { $vcvars = Join-Path $hit "VC\Auxiliary\Build\vcvars64.bat" }
        }
    }
    if (Test-Path -LiteralPath $vcvars) { $msvc = $vcvars }
}

$clangxx = Resolve-Tool "CXX_CLANG" @("/opt/local/bin/clang++-mp-23", "clang++-mp-23", "clang++-mp-devel", "clang++")
$gccxx   = Resolve-Tool "CXX_GCC"   @("/opt/local/bin/g++-mp-15", "g++-mp-15", "g++")

# ---------------------------------------------------------------
# clang 通道的参数。macOS 上最大的一个坑：clang 自带的 libc++ 与系统 libc++
# 不是同一套 —— 头文件里带着 Apple 的 availability 注解（描述"苹果自家 libc++
# 什么时候有这个符号"），本机 macOS 12.7 上等于给 std::to_chars(浮点) 打上
# "13.3 才可用"，<print> 只要格式化浮点数就编译失败；而 clang 自带的那套
# libc++ 的 .dylib 又不在默认库搜索路径里。三件一起做才对：
#   -D_LIBCPP_DISABLE_AVAILABILITY  关掉注解（libc++ 官方的逃生口）
#   -L/-rpath + -lc++               链接 clang 自带的 libc++
#   -fexperimental-library          打开 libc++ 默认关着的特性（<execution> 的
#                                   std::execution::par 就挂在这个开关后面）
# ---------------------------------------------------------------
$clangCflags = @()
$clangLdflags = @()
$libcxxDir = ""
if ($clangxx) {
    # 别用 Split-Path 猜安装根：MacPorts 的 /opt/local/bin/clang++-mp-23 是个
    # shell 包装脚本而不是符号链接，猜出来是 /opt/local。问编译器自己最稳。
    $resourceDir = (& $clangxx -print-resource-dir 2>$null | Select-Object -First 1)
    if ($resourceDir) {
        $mpRoot = $resourceDir -replace '/lib/clang/.*$', ''
        $cand = Join-Path $mpRoot "lib/libc++"
        if (Test-Path -LiteralPath (Join-Path $cand "libc++.dylib")) {
            $libcxxDir = $cand
            $clangCflags  += "-D_LIBCPP_DISABLE_AVAILABILITY"
            $clangLdflags += @("-L$cand", "-Wl,-rpath,$cand", "-lc++")
            $unwind = Join-Path $mpRoot "lib/libunwind"
            if (Test-Path -LiteralPath $unwind) {
                $clangLdflags += @("-L$unwind", "-Wl,-rpath,$unwind")
            }
        }
    }
    if (-not $libcxxDir) {
        # 非 MacPorts 布局（系统 clang / Linux 的 clang）
        $clangCflags  += "-stdlib=libc++"
        $clangLdflags += @("-stdlib=libc++", "-lc++abi")
    }
    $clangCflags += "-fexperimental-library"
}
$gccCflags  = @("-pthread")
$gccLdflags = @("-pthread")

$commonFlags = @("-std=c++23", "-Wall", "-Wextra", "-O2")

# 计数口径与 ./run-all.sh 对齐：按「每个示例 × 每条通道」计，不是按示例计，
# 这样两个入口最后打出来的数字可以直接对照。
$script:passCount = 0
$script:failCount = 0

function Get-Channels {
    $list = @()
    if ($onWindows -and $msvc) { $list += "msvc" }
    if ($clangxx) { $list += "clang" }
    if ($gccxx)   { $list += "gcc" }
    return $list
}

# ---------------------------------------------------------------
# 已知的跨工具链差异（原因写清楚，免得后人以为是回归）
# 纪律：能修的一律修。这里面的 08 是示例**故意**演示"实参求值顺序未指定"；
# 19/20/24 是"线程调度/并行度由实现决定"；21/22/23 是标准库缺头文件
# （示例里已用 __has_include 显式跳过并打出一行说明）。
# ---------------------------------------------------------------
function Get-DiffReason {
    param([string]$Name)
    switch ($Name) {
        "08_classes"    { return "示例故意演示实参求值顺序未指定（MSVC/GCC 从右往左、clang 从左往右）" }
        "19_threads"    { return "多线程按完成顺序打印，调度不同则行序不同" }
        "20_atomic"     { return "并行算法把工作拆给几个线程由实现决定" }
        "21_coroutines" { return "libc++ 无 <generator>，clang 通道跳过 21.3 并说明" }
        "22_textfiles"  { return "libstdc++ 15 无 <mdspan>，gcc 通道跳过 22.4 并说明" }
        "23_tooling"    { return "两套库都没有 <stacktrace>，各通道都跳过 23.3 并说明" }
        "24_minigrep"   { return "多线程搜索的命中行顺序随调度变化" }
        default         { return "" }
    }
}

# ---------------------------------------------------------------
# 进程捕获：按**字节**重定向 stdout/stderr
#
# 不要用 Start-Process -RedirectStandardOutput：它会把输出里的空行吞掉
# （"A\n\nB\n" 落盘变成 "A\nB\n"），而本教程的示例里有 std::println("")
# 这种真空行 —— 结果是两条入口的输出对不上，还很难看出为什么。
# 用 .NET 直接开进程 + 流拷贝，逐字节落地。
# 注意 ReadToEnd/CopyTo 之后要等异步任务结束再 Dispose，否则会丢尾部输出。
# ---------------------------------------------------------------
function Invoke-Capture {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkDir = $projectRoot,
        [int]$TimeoutMs = 300000
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Exe
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.WorkingDirectory       = $WorkDir
    $psi.EnvironmentVariables["TMPDIR"] = $tmpDir   # 让 22_textfiles 打出的临时路径可复现

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        foreach ($a in $Args) { $psi.ArgumentList.Add($a) }
    } else {
        # PS 5.1 只能传一个命令行串，按 CommandLineToArgvW 的规则转义
        $quoted = foreach ($a in $Args) {
            if ($a -match '[\s"]') { '"' + ($a -replace '"', '\"') + '"' } else { $a }
        }
        $psi.Arguments = ($quoted -join ' ')
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

# 走 cmd.exe 跑一段批处理（MSVC 需要先 call vcvars64.bat 才认得 cl）
function Invoke-Batch {
    param(
        [Parameter(Mandatory = $true)][string]$CommandLine,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkDir = $projectRoot
    )
    return Invoke-Capture -Exe $env:ComSpec -Args @("/c", $CommandLine) `
                          -OutFile $OutFile -ErrFile $ErrFile -WorkDir $WorkDir
}

function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    # Get-Content -Raw 读空文件返回 $null，必须兜底
    $text = [string](Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue)
    if ($null -eq $text) { $text = "" }
    return $text
}

# 输出里是否混进了「不该出现」的控制字符（TAB/LF/CR 除外）。
# 按字节判，不碰正则 —— PowerShell 正则里 "" `0-`10"" 会被拆成 \x00 + "1" + "0"，
# 字符类范围变成 \x00-\x31，把等号也吃掉，标记就永远找不到了。
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
    # MSVC 的回显走 stdout → .build。两个都要看，漏一个就等于没判"零告警"
    # （反向验证时故意写了个 "int unused = 42;" 的样例，一开始正是这里漏掉的）。
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
    if ($onWindows -and ($Channel -eq "msvc")) { $bin = Join-Path $buildDir "$Name.exe" }
    $outPath = Join-Path $buildDir "$Name.$Channel.out"
    $errPath = Join-Path $buildDir "$Name.$Channel.err"
    $bldLog  = Join-Path $buildDir "$Name.$Channel.build"
    $bldErr  = Join-Path $buildDir "$Name.$Channel.builderr"

    $cflags  = @()
    $ldflags = @()
    $exe     = ""
    switch ($Channel) {
        "clang" { $exe = $clangxx; $cflags = $clangCflags;  $ldflags = $clangLdflags }
        "gcc"   { $exe = $gccxx;   $cflags = $gccCflags;    $ldflags = $gccLdflags }
        "msvc"  { $exe = "cl" }
    }

    if ($Channel -eq "msvc") {
        # ---- MSVC：接口单元 → .cpp → 链接（沿用教程原来的三步）----
        $refArgs = @(); $modObjs = @(); $objs = @()
        $ixxFiles = @(Get-ChildItem -LiteralPath $Dir -Filter "*.ixx" | Sort-Object Name)
        foreach ($m in $ixxFiles) {
            $obj = Join-Path $buildDir ($Name + "_" + $m.BaseName + ".obj")
            $ifc = [System.IO.Path]::ChangeExtension($obj, ".ifc")
            $r = Invoke-Batch -CommandLine ('call "{0}" >nul && cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4 /interface /c /Fo"{1}" /ifcOutput"{2}" "{3}"' -f $vcvars, $obj, $ifc, $m.FullName) `
                              -OutFile $bldLog -ErrFile $bldErr
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
            # /reference 必须空格分隔："/reference name=file"（冒号形式会被当成分区报 C5213）
            $refArgs += @("/reference", "$($m.BaseName)=`"$ifc`"")
            $modObjs += "`"$obj`""
        }
        foreach ($c in @(Get-ChildItem -LiteralPath $Dir -Filter "*.cpp" | Sort-Object Name)) {
            $obj = Join-Path $buildDir ($Name + "_" + $c.BaseName + ".obj")
            $argStr = (@("/nologo", "/std:c++latest", "/EHsc", "/utf-8", "/permissive-", "/Zc:__cplusplus", "/W4",
                         "/c", "/Fo`"$obj`"", "`"$($c.FullName)`"") + $refArgs) -join ' '
            $r = Invoke-Batch -CommandLine ('call "{0}" >nul && cl {1}' -f $vcvars, $argStr) `
                              -OutFile $bldLog -ErrFile $bldErr
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
            $objs += "`"$obj`""
        }
        $argStr = (@("/nologo", "/std:c++latest", "/EHsc", "/utf-8", "/permissive-", "/Zc:__cplusplus", "/W4",
                     "/Fe`"$bin`"") + $objs + $modObjs) -join ' '
        $r = Invoke-Batch -CommandLine ('call "{0}" >nul && cl {1}' -f $vcvars, $argStr) `
                          -OutFile $bldLog -ErrFile $bldErr
        if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
    }
    elseif ($Name -eq "18_modules") {
        # ---- 模块：接口单元必须先编成"已编译模块接口" ----
        #   clang: --precompile 出 .pcm，import 方用 -fmodule-file=math=math.pcm
        #   gcc  : -fmodules-ts 编 .ixx 时把 math.gcm 落进 ./gcm.cache
        $wd = Join-Path $buildDir "mod/$Channel"
        New-Item -ItemType Directory -Force -Path $wd | Out-Null
        Get-ChildItem -LiteralPath $wd -File -ErrorAction SilentlyContinue | Remove-Item -Force
        Copy-Item -Path (Join-Path $Dir "*") -Destination $wd -Force
        $ixx = (Get-ChildItem -LiteralPath $wd -Filter "*.ixx" | Select-Object -First 1)
        if (-not $ixx) { throw "18_modules 缺 .ixx 模块接口文件" }
        $mod = [System.IO.Path]::GetFileNameWithoutExtension($ixx.Name)  # math.ixx → math

        if ($Channel -eq "clang") {
            $r = Invoke-Capture -Exe $exe -Args (@($commonFlags) + $cflags + @("-x", "c++-module", $ixx.Name, "--precompile", "-o", "$mod.pcm")) `
                                -OutFile $bldLog -ErrFile $bldErr -WorkDir $wd
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
            $r = Invoke-Capture -Exe $exe -Args (@($commonFlags) + $cflags + @("-fmodule-file=$mod=$mod.pcm", "-c", "main.cpp", "-o", "main.o")) `
                                -OutFile $bldLog -ErrFile $bldErr -WorkDir $wd
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
            $r = Invoke-Capture -Exe $exe -Args (@($commonFlags) + $cflags + @("$mod.pcm", "main.o", "-o", $bin) + $ldflags) `
                                -OutFile $bldLog -ErrFile $bldErr -WorkDir $wd
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
        } else {
            $r = Invoke-Capture -Exe $exe -Args (@($commonFlags) + $cflags + @("-fmodules-ts", "-c", $ixx.Name, "-o", "$mod.o")) `
                                -OutFile $bldLog -ErrFile $bldErr -WorkDir $wd
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
            $r = Invoke-Capture -Exe $exe -Args (@($commonFlags) + $cflags + @("-fmodules-ts", "-c", "main.cpp", "-o", "main.o")) `
                                -OutFile $bldLog -ErrFile $bldErr -WorkDir $wd
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
            $r = Invoke-Capture -Exe $exe -Args (@($commonFlags) + $cflags + @("$mod.o", "main.o", "-o", $bin) + $ldflags) `
                                -OutFile $bldLog -ErrFile $bldErr -WorkDir $wd
            if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
        }
    }
    else {
        # ---- 普通示例：目录里所有 .cpp 一次编出来 ----
        $srcs = @(Get-ChildItem -LiteralPath $Dir -Filter "*.cpp" | Sort-Object Name |
                    ForEach-Object { $_.FullName })
        if ($srcs.Count -eq 0) { throw "示例目录里没有 .cpp：$Dir" }
        $args_ = @($commonFlags) + $cflags + @("-I$Dir") + $srcs + @("-o", $bin) + $ldflags
        $r = Invoke-Capture -Exe $exe -Args $args_ -OutFile $bldLog -ErrFile $bldErr -WorkDir $projectRoot
        if ($r.ExitCode -ne 0) { return @{ Ok = $false; Result = $r } }
    }

    # 示例里有相对路径读写、还会写临时文件：统一在 build/ 下跑
    $run = Invoke-Capture -Exe $bin -Args @() -OutFile $outPath -ErrFile $errPath -WorkDir $buildDir
    return @{ Ok = $true; Result = $run }
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

    # ---- 两条通道的输出应当逐字节一致 ----
    $chans = Get-Channels
    if ($chans.Count -ge 2) {
        $a = Join-Path $buildDir "$name.$($chans[0]).out"
        $b = Join-Path $buildDir "$name.$($chans[1]).out"
        if ((Test-Path -LiteralPath $a) -and (Test-Path -LiteralPath $b)) {
            $ba = [System.IO.File]::ReadAllBytes($a)
            $bb = [System.IO.File]::ReadAllBytes($b)
            $same = ($ba.Length -eq $bb.Length)
            if ($same) {
                for ($i = 0; $i -lt $ba.Length; $i++) { if ($ba[$i] -ne $bb[$i]) { $same = $false; break } }
            }
            if ($ba.Length -gt 0 -and $bb.Length -gt 0) {
                if ($same) {
                    Write-Host "  [same] 两工具链输出逐字节一致" -ForegroundColor DarkGray
                } else {
                    $reason = Get-DiffReason $name
                    if ($reason -ne "") {
                        Write-Host ("  [diff] 已知差异：{0}" -f $reason) -ForegroundColor DarkYellow
                    } else {
                        Write-Host "  [DIFF] 两工具链输出不一致（意外差异，见 build/$name.*.out）" -ForegroundColor Red
                        $allOk = $false
                    }
                }
            }
        }
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
    if ($dirs.Count -eq 0) { throw "examples 目录下没有匹配的示例目录。" }

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
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  ./build.ps1 -All                 全量：逐示例编译（零告警）+ 运行自检"
Write-Host "  ./build.ps1 -Example 06_compound 单示例编译+运行"
Write-Host "  ./build.ps1 18 22                按编号跑"
Write-Host "  ./build.ps1 -All -ShowOutput     附带打印运行输出"
Write-Host "  ./build.ps1 -Clean               清理 build 目录"
Write-Host ""
Write-Host "判定标准：退出码 0 + stderr 为空 + stdout 非空 + 无多余控制字符 + 有 '$marker'"
Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 与按编号筛选）。"
