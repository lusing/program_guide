param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

# LLVM 教程统一验证脚本（须 PowerShell 7 / pwsh 运行；本文件无 BOM）
# 工具链：MSYS2 UCRT64 的完整 LLVM（opt/lli/llc/llvm-config + g++）
# 分层判定：每步退出码 0；可运行产物还必须打印自己的结束标记（==== NN ok ====）

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ---------- 工具链发现 ----------
$ucrt64Candidates = @(
    "G:\scoop\apps\msys2\current\ucrt64",
    "C:\msys64\ucrt64"
)
$ucrt64 = $null
foreach ($c in $ucrt64Candidates) {
    if ((Test-Path "$c\bin\opt.exe") -and (Test-Path "$c\bin\llvm-config.exe") -and (Test-Path "$c\bin\g++.exe")) {
        $ucrt64 = $c; break
    }
}
if (-not $ucrt64) {
    throw "未找到 MSYS2 UCRT64 完整 LLVM（需要 opt.exe / llvm-config.exe / g++.exe）。候选路径: $($ucrt64Candidates -join ' ; ')。修复：scoop install msys2 后在 MSYS2 UCRT64 shell 里 pacman -S mingw-w64-ucrt-x86_64-llvm mingw-w64-ucrt-x86_64-llvm-tools mingw-w64-ucrt-x86_64-llvm-libs"
}

$ubin       = "$ucrt64\bin"
$opt        = "$ubin\opt.exe"
$lli        = "$ubin\lli.exe"
$llc        = "$ubin\llc.exe"
$llvmAs     = "$ubin\llvm-as.exe"
$llvmDis    = "$ubin\llvm-dis.exe"
$FileCheck  = "$ubin\FileCheck.exe"
$clang      = "$ubin\clang.exe"
$gxx        = "$ubin\g++.exe"
$llvmConfig = "$ubin\llvm-config.exe"

# 运行期依赖 libLLVM-22.dll 等都在 ucrt64\bin，必须前置 PATH
$env:PATH = "$ubin;$env:PATH"

$buildDir    = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

# ---------- 公共函数 ----------
function Invoke-Tool {
    param([string]$Name, [string]$Exe, [string[]]$ArgList)
    & $Exe @ArgList
    if ($LASTEXITCODE -ne 0) { throw "$Name 失败(退出码 $LASTEXITCODE): $Exe $($ArgList -join ' ')" }
}

# 运行并校验：退出码 0 + stdout 出现结束标记
function Invoke-Run {
    param([string]$Name, [string]$Exe, [string[]]$ArgList, [string]$Marker)
    $out = & $Exe @ArgList 2>&1
    $text = ($out | ForEach-Object { "$_" }) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "$Name 运行失败(退出码 $LASTEXITCODE): $Exe $($ArgList -join ' ')`n---输出---`n$text" }
    if ($Marker -and ($text -notmatch [regex]::Escape($Marker))) { throw "$Name 未打印结束标记 '$Marker'`n---输出---`n$text" }
    return $text
}

# 供后续章节使用：llvm-config 取编译旗标（Windows 风格路径，pwsh 直调 g++ 可用）
function Get-LlvmConfig {
    param([string[]]$Flags)
    $out = & $llvmConfig @Flags
    if ($LASTEXITCODE -ne 0) { throw "llvm-config $($Flags -join ' ') 失败" }
    return ($out -join ' ').Trim()
}

# 供后续章节使用：编译并链接一个依赖 LLVM 库的 C++ 程序（共享链接 libLLVM-22.dll）
# 组件列表取实测有效的全集；--link-shared 下它们都映射到同一个 -lLLVM-22
function Build-LlvmCpp {
    param([string]$Src, [string]$OutExe)
    $rm = [System.StringSplitOptions]::RemoveEmptyEntries
    $cxxflags = (Get-LlvmConfig @('--cxxflags')).Split(' ', $rm)
    $linkflags = (Get-LlvmConfig @('--ldflags', '--link-shared', '--libs',
        'core', 'support', 'executionengine', 'orcjit', 'irreader',
        'asmparser', 'analysis', 'passes', 'transformutils')).Split(' ', $rm)
    & $gxx $cxxflags $Src -o $OutExe $linkflags
    if ($LASTEXITCODE -ne 0) { throw "g++ 编译失败: $Src" }
}

# ---------- 各示例验证 ----------
function Get-BuildOut {
    param([string]$Name)
    $d = Join-Path $buildDir $Name
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    return $d
}

# 01：clang -S -emit-llvm 产 IR → 汇编/反汇编往返 → lli 跑 IR → 对照原生编译运行
function Test-ClangIrExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (clang 产 IR + lli 执行)" -ForegroundColor Cyan
    $out = Get-BuildOut $name
    Invoke-Tool "clang -emit-llvm" $clang @('-S', '-emit-llvm', '-O1', '-target', 'x86_64-pc-windows-gnu', "$Dir\hello.c", '-o', "$out\hello.ll")
    Invoke-Tool "llvm-as" $llvmAs @("$out\hello.ll", '-o', "$out\hello.bc")
    Invoke-Tool "llvm-dis" $llvmDis @("$out\hello.bc", '-o', "$out\hello.roundtrip.ll")
    Invoke-Run "lli(hello.ll)" $lli @("$out\hello.ll") '==== 01 ok ====' | Out-Null
    Invoke-Tool "clang native" $clang @("$Dir\hello.c", '-o', "$out\hello_native.exe")
    Invoke-Run "hello_native" "$out\hello_native.exe" @() '==== 01 ok ====' | Out-Null
}

# 通用 .ll：llvm-as → llvm-dis 往返 → lli 运行（带标记）
function Test-LlFile {
    param([string]$Dir, [string]$File, [string]$Marker)
    $name = Split-Path -Leaf $Dir
    $out = Get-BuildOut $name
    $src = Join-Path $Dir $File
    $bc = Join-Path $out ([IO.Path]::GetFileNameWithoutExtension($File) + '.bc')
    Invoke-Tool "llvm-as($File)" $llvmAs @($src, '-o', $bc)
    Invoke-Tool "llvm-dis($File)" $llvmDis @($bc, '-o', "$bc.dis.ll")
    Invoke-Run "lli($File)" $lli @($src) $Marker | Out-Null
}

# 02：手写 IR 基础
function Test-FirstIrExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (手写 IR + 位码往返)" -ForegroundColor Cyan
    Test-LlFile $Dir 'add.ll' '==== 02 ok ===='
}

# 03：类型与聚合数据
function Test-IrTypesExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (类型系统)" -ForegroundColor Cyan
    Test-LlFile $Dir 'types.ll' '==== 03 ok ===='
}

# 04：phi vs alloca 两种风格 + mem2reg 提升验证
function Test-SsaPhiExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (SSA/phi + mem2reg)" -ForegroundColor Cyan
    Test-LlFile $Dir 'phi.ll' '==== 04 ok ===='
    Test-LlFile $Dir 'allocastyle.ll' '==== 04 ok ===='
    # mem2reg 把 alloca 风格提升回 phi 风格
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Invoke-Tool "opt mem2reg" $opt @('-passes=mem2reg', "$Dir\allocastyle.ll", '-S', '-o', "$out\allocastyle.mem2reg.ll")
    $text = Get-Content "$out\allocastyle.mem2reg.ll" -Raw
    if ($text -notmatch '\bphi\b') { throw "mem2reg 输出中没有 phi——提升未发生？" }
    Invoke-Run "lli(mem2reg 后)" $lli @("$out\allocastyle.mem2reg.ll") '==== 04 ok ====' | Out-Null
}

# 05：O0..O3 管线——四级输出都要能跑且结果一致
function Test-OptPipelineExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (优化管线 O0-O3)" -ForegroundColor Cyan
    Test-LlFile $Dir 'naive.ll' '==== 05 ok ===='
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    foreach ($o in 0..3) {
        Invoke-Tool "opt -O$o" $opt @("-O$o", "$Dir\naive.ll", '-S', '-o', "$out\naive.O$o.ll")
        Invoke-Run "lli(-O$o 产物)" $lli @("$out\naive.O$o.ll") '==== 05 ok ====' | Out-Null
    }
}

# ---------- Pass 插件类（06/07）----------
function Build-LlvmPlugin {
    param([string]$Src, [string]$OutDll, [string[]]$Components)
    $rm = [System.StringSplitOptions]::RemoveEmptyEntries
    $cxx = (Get-LlvmConfig @('--cxxflags')).Split(' ', $rm)
    $lnk = (Get-LlvmConfig (@('--ldflags', '--link-shared', '--libs') + $Components)).Split(' ', $rm)
    & $gxx -shared $cxx $Src -o $OutDll $lnk
    if ($LASTEXITCODE -ne 0) { throw "g++ 插件编译失败: $Src" }
}

# 06：插件构建 → opt 加载点名执行（stderr 出报告）→ 产物仍可运行
function Test-HelloPassExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (pass 插件)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Build-LlvmPlugin "$Dir\HelloPass.cpp" "$out\HelloPass.dll" @('core')
    $text = Invoke-Run 'opt(hello-pass)' $opt @("-load-pass-plugin=$out\HelloPass.dll", '-passes=hello-pass', "$Dir\test.ll", '-S', '-o', "$out\after.ll") $null
    if ($text -notmatch 'hello-pass: square') { throw "hello-pass 未打印 square 报告`n$text" }
    Invoke-Run 'lli(after.ll)' $lli @("$out\after.ll") '==== 06 ok ====' | Out-Null
}

# 07：分析插件三种触发（点名 / -O2 EP 自动 / -O1 不触发）
function Test-PassAnalysisExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (自定义 Analysis + EP)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Build-LlvmPlugin "$Dir\InstStats.cpp" "$out\InstStats.dll" @('core', 'analysis')
    $text = Invoke-Run 'opt(inst-stats,mem-stats)' $opt @("-load-pass-plugin=$out\InstStats.dll", '-passes=inst-stats,mem-stats', "$Dir\test.ll", '-disable-output') $null
    if ($text -notmatch 'mem-stats: sum_to load=3 store=4 alloca=2') { throw "点名模式输出不符`n$text" }
    $text2 = Invoke-Run 'opt(-O2 EP)' $opt @("-load-pass-plugin=$out\InstStats.dll", '-O2', "$Dir\test.ll", '-S', '-o', "$out\after.O2.ll") $null
    if ($text2 -notmatch 'mem-stats: sum_to load=0') { throw "EP 未在 -O2 触发（优化后应归零）`n$text2" }
    $text3 = Invoke-Run 'opt(-O1 对照)' $opt @("-load-pass-plugin=$out\InstStats.dll", '-O1', "$Dir\test.ll", '-S', '-o', "$out\after.O1.ll") $null
    if ($text3 -match 'mem-stats:') { throw "-O1 不应触发 EP`n$text3" }
    Invoke-Run 'lli(after.O2)' $lli @("$out\after.O2.ll") '==== 07 ok ====' | Out-Null
}

# ---------- C++ 工具类（08/09/11）----------
function Test-IrBuilderExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (IRBuilder 生成 IR)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Build-LlvmCpp "$Dir\gen_fib.cpp" "$out\gen_fib.exe"
    Invoke-Run 'gen_fib' "$out\gen_fib.exe" @("$out\fib.ll") $null | Out-Null
    Invoke-Run 'lli(fib.ll)' $lli @("$out\fib.ll") '==== 08 ok ====' | Out-Null
}

function Test-ValueModelExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (Value/Use + RAUW)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Build-LlvmCpp "$Dir\walker.cpp" "$out\walker.exe"
    $text = Invoke-Run 'walker' "$out\walker.exe" @("$Dir\walk.ll", "$out\after.ll") $null
    if ($text -notmatch 'binary:mul x1') { throw "直方图输出不符（悬垂 StringRef 又回来了？）`n$text" }
    if ($text -notmatch 'after RAUW: uses of @square = 0') { throw "RAUW 后仍有使用`n$text" }
    Invoke-Run 'lli(after.ll)' $lli @("$out\after.ll") '==== 09 ok ====' | Out-Null
}

function Test-JitExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (ORC JIT)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Build-LlvmCpp "$Dir\jit_demo.cpp" "$out\jit_demo.exe"
    Invoke-Run 'jit_demo' "$out\jit_demo.exe" @() '==== 11 ok ====' | Out-Null
}

# ---------- MiniLang 渐进系列（12-20）----------
# 每章一份独立完整的 minilang.cpp（前章代码 + 本章增量），测试文件各异
$MinilangLibs = @('core', 'support', 'orcjit', 'executionengine', 'passes', 'analysis')

function Build-Minilang {
    param([string]$Dir, [string[]]$ExtraLibs = @())
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    $rm = [System.StringSplitOptions]::RemoveEmptyEntries
    $cxx = (Get-LlvmConfig @('--cxxflags')).Split(' ', $rm)
    $lnk = (Get-LlvmConfig (@('--ldflags', '--link-shared', '--libs') + $MinilangLibs + $ExtraLibs)).Split(' ', $rm)
    & $gxx $cxx "$Dir\minilang.cpp" -o "$out\minilang.exe" $lnk
    if ($LASTEXITCODE -ne 0) { throw "minilang 编译失败: $Dir" }
    return "$out\minilang.exe"
}

function Test-MinilangFrontExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (前端: 词法+解析+AST)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    & $gxx -std=c++17 "$Dir\minilang.cpp" -o "$out\minilang.exe"
    if ($LASTEXITCODE -ne 0) { throw "minilang(v0.1) 编译失败" }
    $text = Invoke-Run 'minilang --ast' "$out\minilang.exe" @('--ast', "$Dir\test.mini") '==== 12 ok ===='
    if ($text -notmatch '\(binary - \(binary \+ 1 \(binary \* 2 3\)\) \(binary / 4 2\)\)') { throw "优先级解析结果不符`n$text" }
}

function Test-MinilangIrExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (AST→IR + lli 执行)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    $exe = Build-Minilang $Dir
    Invoke-Run 'minilang --ir' $exe @('--ir', "$Dir\test.mini", "$out\test.ll") '==== 13 ok ====' | Out-Null
    $text = Invoke-Run 'lli(test.ll)' $lli @("$out\test.ll") $null
    foreach ($expected in @('55\.0+', '5050\.0+', '7\.0+', '10\.0+', '25\.0+', '0\.0+')) {
        if ($text -notmatch $expected) { throw "lli 输出缺少预期值 $expected`n$text" }
    }
}

function Test-MinilangFuncsExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (JIT + 增量重定义)" -ForegroundColor Cyan
    $exe = Build-Minilang $Dir
    $t1 = Invoke-Run 'jit(test)' $exe @('--jit', "$Dir\test.mini") '==== 14 ok ===='
    if ($t1 -notmatch '6\.765000e\+03') { throw "fib(20) 结果不符`n$t1" }
    $t2 = Invoke-Run 'jit(redefine)' $exe @('--jit', "$Dir\redefine.mini") '==== 14 ok ===='
    if ($t2 -notmatch '2\.000000e\+01' -or $t2 -notmatch '4\.000000e\+01') { throw "重定义结果不符`n$t2" }
}

function Test-MinilangVarsExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (var/赋值/alloca)" -ForegroundColor Cyan
    $exe = Build-Minilang $Dir
    $t = Invoke-Run 'jit(vars)' $exe @('--jit', "$Dir\test.mini") '==== 15 ok ===='
    if ($t -notmatch '8\.320400e\+05') { throw "fibi(30) 结果不符`n$t" }
    # alloca→phi 还原的量化验证
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Invoke-Run 'minilang --ir' $exe @('--ir', "$Dir\test.mini", "$out\test.ll") $null | Out-Null
    Invoke-Tool 'opt mem2reg' $opt @('-passes=mem2reg', "$out\test.ll", '-S', '-o', "$out\test.mem2reg.ll")
    $raw = (Select-String -Path "$out\test.ll" -Pattern 'alloca').Count
    $phi = (Select-String -Path "$out\test.mem2reg.ll" -Pattern '\bphi\b').Count
    if ($raw -lt 5 -or $phi -lt 3) { throw "mem2reg 前后对比异常：alloca=$raw phi=$phi" }
}

function Test-MinilangOpsExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (自定义运算符)" -ForegroundColor Cyan
    $exe = Build-Minilang $Dir
    $t = Invoke-Run 'jit(ops)' $exe @('--jit', "$Dir\test.mini") '==== 16 ok ===='
    foreach ($expected in @('7\.200000e\+02', '7\.000000e\+00', '6\.000000e\+00', '-2\.400000e\+01', '5\.500000e\+01')) {
        if ($t -notmatch $expected) { throw "运算符结果不符（缺 $expected）`n$t" }
    }
}

function Test-MinilangOptExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (优化层)" -ForegroundColor Cyan
    $exe = Build-Minilang $Dir
    $t1 = Invoke-Run 'jit(-O2)' $exe @('--jit', "$Dir\test.mini") '==== 17 ok ===='
    $t2 = Invoke-Run 'jit0(无优化)' $exe @('--jit0', "$Dir\test.mini") '==== 17 ok ===='
    if ($t1 -notmatch '6\.765000e\+03' -or $t2 -notmatch '6\.765000e\+03') { throw "两模式结果应一致`n$t1`n$t2" }
    # 折叠演示：自产 IR 过 -O2 后出现内联痕迹（.i 后缀块）
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Invoke-Run 'minilang --ir' $exe @('--ir', "$Dir\foldcheck.mini", "$out\foldcheck.ll") $null | Out-Null
    Invoke-Tool 'opt -O2' $opt @('-O2', "$out\foldcheck.ll", '-S', '-o', "$out\foldcheck.O2.ll")
    $o2 = Get-Content "$out\foldcheck.O2.ll" -Raw
    if ($o2 -notmatch '\.i:') { throw "-O2 输出无内联痕迹（.i 块）" }
}

function Test-MinilangCfExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (while/短路)" -ForegroundColor Cyan
    $exe = Build-Minilang $Dir
    $t = Invoke-Run 'jit(cf)' $exe @('--jit', "$Dir\test.mini") '==== 18 ok ===='
    if ($t -notmatch '1\.024000e\+03') { throw "power(2,10) 结果不符`n$t" }
    if ($t -notmatch '=> 0\.000000e\+00\r?\n=> 1') { throw "短路序输出不符`n$t" }
}

function Test-MinilangPassExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (进程内统计 pass)" -ForegroundColor Cyan
    $exe = Build-Minilang $Dir
    $t = Invoke-Run 'minilang --stats' $exe @('--stats', "$Dir\test.mini") '==== 19 ok ===='
    if ($t -notmatch 'sum_to bb=\d+ insts=\d+ alloca=\d+') { throw "stats 输出不符`n$t" }
    if ($t -notmatch 'ml-stats: sum_to bb=\d+ insts=\d+ alloca=0 load=0 store=0') { throw "mem2reg 后未清零`n$t" }
}

function Test-MinilangNativeExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (.o → 原生 exe)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    $exe = Build-Minilang $Dir @('codegen', 'target', 'native', 'mc')
    Invoke-Run 'minilang --obj' $exe @('--obj', "$Dir\test.mini", "$out\test.o") '==== 20 ok ====' | Out-Null
    Invoke-Tool 'clang link' $clang @("$out\test.o", '-o', "$out\test.exe")
    $t = Invoke-Run 'test.exe' "$out\test.exe" @() $null
    foreach ($expected in @('610\.0+', '125250\.0+', '-55\.0+')) {
        if ($t -notmatch $expected) { throw "exe 输出缺少 $expected`n$t" }
    }
}
# ---------- 代码生成类（10）----------
function Test-CodeGenExample {
    param([string]$Dir)
    Write-Host "`n[Example] $(Split-Path -Leaf $Dir) (llc 本机+交叉)" -ForegroundColor Cyan
    $out = Get-BuildOut (Split-Path -Leaf $Dir)
    Invoke-Tool 'llc .s' $llc @("$Dir\demo.ll", '-o', "$out\demo.s")
    Invoke-Tool 'llc .o' $llc @("$Dir\demo.ll", '-filetype=obj', '-o', "$out\demo.o")
    Invoke-Tool 'clang link' $clang @("$out\demo.o", '-o', "$out\demo.exe")
    Invoke-Run 'demo.exe' "$out\demo.exe" @() '==== 10 ok ====' | Out-Null
    Invoke-Tool 'llc aarch64' $llc @('--mtriple=aarch64-linux-gnu', "$Dir\demo.ll", '-o', "$out\demo.aarch64.s")
    $s = Get-Content "$out\demo.s" -Raw
    if ($s -notmatch 'imul') { throw "本机汇编未见 imul" }
    $cross = Get-Content "$out\demo.aarch64.s" -Raw
    if ($cross -notmatch '\bmul\b') { throw "aarch64 汇编未见 mul" }
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        '01_overview'       { Test-ClangIrExample $Dir }
        '02_first_ir'       { Test-FirstIrExample $Dir }
        '03_ir_types'       { Test-IrTypesExample $Dir }
        '04_ssa_phi'        { Test-SsaPhiExample $Dir }
        '05_opt_pipeline'   { Test-OptPipelineExample $Dir }
        '06_hello_pass'     { Test-HelloPassExample $Dir }
        '07_pass_analysis'  { Test-PassAnalysisExample $Dir }
        '08_irbuilder'      { Test-IrBuilderExample $Dir }
        '09_value_model'    { Test-ValueModelExample $Dir }
        '10_codegen'        { Test-CodeGenExample $Dir }
        '11_orc_jit'        { Test-JitExample $Dir }
        '12_minilang_front' { Test-MinilangFrontExample $Dir }
        '13_minilang_ir'    { Test-MinilangIrExample $Dir }
        '14_minilang_funcs' { Test-MinilangFuncsExample $Dir }
        '15_minilang_vars'  { Test-MinilangVarsExample $Dir }
        '16_minilang_ops'   { Test-MinilangOpsExample $Dir }
        '17_minilang_opt'   { Test-MinilangOptExample $Dir }
        '18_minilang_cf'    { Test-MinilangCfExample $Dir }
        '19_minilang_pass'  { Test-MinilangPassExample $Dir }
        '20_minilang_native'{ Test-MinilangNativeExample $Dir }
        default { throw "未登记的示例目录: $(Split-Path -Leaf $Dir)（请在 build.ps1 Test-One 里补分派）" }
    }
}

# ---------- 入口 ----------
if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $dir
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    $passed = 0
    Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name | ForEach-Object {
        Test-One $_.FullName
        $passed++
    }
    Write-Host "`n[Done] 全部 $passed 个示例验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                    验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 02_first_ir    验证单个示例"
Write-Host "  .\build.ps1 -Clean                  清理 build 目录"
