param(
    [switch]$All,
    [string]$Example,   # 示例目录名，如 12_lambdas
    [switch]$Update,    # 配合 -Example：用实际运行输出刷新 expected.txt
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---- 工具链定位：scoop 的 Kotlin 2.4.20 + oraclejdk-lts 21，回退 PATH ----
$kotlinHome = "G:\scoop\apps\kotlin\current"
if (-not (Test-Path -LiteralPath (Join-Path $kotlinHome "bin\kotlinc-jvm.bat"))) {
    $cmd = Get-Command kotlinc-jvm.bat -ErrorAction SilentlyContinue
    if (-not $cmd) { throw "未找到 kotlinc-jvm.bat（期望 $kotlinHome）" }
    $kotlinHome = Split-Path (Split-Path $cmd.Source -Parent) -Parent
}
$javaHome = "G:\scoop\apps\oraclejdk-lts\current"   # LTS 21：PATH 上的 java 是 8，必须显式指定
if (-not (Test-Path -LiteralPath (Join-Path $javaHome "bin\java.exe"))) {
    $javaHome = Split-Path (Split-Path (Get-Command java).Source -Parent) -Parent
}
$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;$kotlinHome\bin;$env:PATH"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$kotlinc = Join-Path $kotlinHome "bin\kotlinc-jvm.bat"
$java    = Join-Path $javaHome "bin\java.exe"
$libDir  = Join-Path $kotlinHome "lib"
$cpTest  = @(
    (Join-Path $libDir "kotlin-stdlib.jar"),
    (Join-Path $libDir "kotlin-test.jar"),
    (Join-Path $libDir "kotlinx-coroutines-core-jvm.jar")
) -join ';'

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Get-ChildItem -LiteralPath $examplesDir -Directory | ForEach-Object {
        $t = Join-Path $_.FullName "build"
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
        $g = Join-Path $_.FullName ".gradle"
        if (Test-Path -LiteralPath $g) { Remove-Item -LiteralPath $g -Recurse -Force }
    }
    Write-Host "[Clean] 已清理全部 build/.gradle 目录。" -ForegroundColor Yellow
    exit 0
}

# ---- 四层验证：kotlinc -Werror 编译 → kotlin.test 测试 → main 运行 → expected.txt 快照比对 ----
function Invoke-Kotlinc {
    param([string[]]$Sources, [string]$OutDir, [string]$ExtraCp = "", [string[]]$ExtraFlags = @())
    $cp = if ($ExtraCp) { "$ExtraCp;$cpTest" } else { $cpTest }
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $argsFile = Join-Path $OutDir "kotlinc.args"
    # 空格安全：源码路径全部走 @args 文件
    @('-Werror') + $ExtraFlags + @('-cp'; $cp; '-d'; $OutDir; $Sources) | Set-Content -LiteralPath $argsFile -Encoding utf8
    & $kotlinc "@$argsFile" 2>&1 | ForEach-Object { "$_" } | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "kotlinc 编译失败（exit $LASTEXITCODE）" }
}

function Invoke-JavaMain {
    param([string]$MainClass, [string]$ClassesDir, [string]$ExtraCp = "")
    $cp = (@($ClassesDir, $ExtraCp, $cpTest) | Where-Object { $_ }) -join ';'
    $out = & $java "-Dfile.encoding=UTF-8" "-Dstdout.encoding=UTF-8" "-Dstderr.encoding=UTF-8" -cp $cp $MainClass 2>&1
    if ($LASTEXITCODE -ne 0) {
        $out | ForEach-Object { "$_" } | Write-Host
        throw "$MainClass 运行失败（exit $LASTEXITCODE）"
    }
    return ($out -join "`n")
}

function Compare-Golden {
    param([string]$Expected, [string]$Actual)
    $want = ((Get-Content -LiteralPath $Expected -Raw -Encoding utf8) -replace "`r`n", "`n").TrimEnd()
    $got = ($Actual -replace "`r`n", "`n").TrimEnd()
    if ($want -ne $got) {
        $w = $want -split "`n"; $g = $got -split "`n"
        for ($i = 0; $i -lt [Math]::Max($w.Count, $g.Count); $i++) {
            $a = if ($i -lt $w.Count) { $w[$i] } else { "<缺少>" }
            $b = if ($i -lt $g.Count) { $g[$i] } else { "<缺少>" }
            if ($a -ne $b) { Write-Host "  第 $($i+1) 行不一致:`n    期望: $a`n    实际: $b" -ForegroundColor Red; break }
        }
        throw "输出快照与 expected.txt 不一致"
    }
}

function Test-StdExample {
    # 常规 kotlinc 示例：src/*.kt + test/Tests.kt + expected.txt
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Push-Location $Dir   # 运行期工作目录 = 示例目录（19/24 章在 build/ 下读写相对路径文件）
    try {
    $classes = Join-Path $Dir "build\classes"
    if (Test-Path -LiteralPath $classes) { Remove-Item -LiteralPath $classes -Recurse -Force }

    $sources = @(Get-ChildItem -LiteralPath (Join-Path $Dir "src") -Filter '*.kt' -Recurse | ForEach-Object FullName) +
               @(Get-ChildItem -LiteralPath (Join-Path $Dir "test") -Filter '*.kt' -Recurse | ForEach-Object FullName)
    Invoke-Kotlinc -Sources $sources -OutDir $classes

    Invoke-JavaMain -MainClass 'TestsKt' -ClassesDir $classes | Out-Null
    Write-Host "  [L2] 测试通过"

    $out = Invoke-JavaMain -MainClass 'MainKt' -ClassesDir $classes
    $golden = Join-Path $Dir "expected.txt"
    if ($Update) {
        $out | Set-Content -LiteralPath $golden -Encoding utf8
        Write-Host "  [L4] 已刷新 expected.txt（$((($out -split "`n").Count)) 行）"
    } else {
        if (-not (Test-Path -LiteralPath $golden)) { throw "缺少 expected.txt（先 -Update 生成并人工核对）" }
        Compare-Golden -Expected $golden -Actual $out
        Write-Host "  [L4] 输出快照一致"
    }
    Write-Host "[OK] $name" -ForegroundColor Green
    }
    finally { Pop-Location }
}

function Test-JavaInteropExample {
    # 18_javainterop：双向互调有循环依赖（Api.kt↔Caller.java），kotlinc 单编译器解决不了——
    # 两遍法：javac(纯 Java 库) → kotlinc(Api.kt) → javac(Caller.java 调 Kotlin) → kotlinc(Main+Tests)
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $classes = Join-Path $Dir "build\classes"
    if (Test-Path -LiteralPath $classes) { Remove-Item -LiteralPath $classes -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $classes | Out-Null
    $javac = Join-Path $javaHome "bin\javac.exe"
    $anno = Join-Path $libDir "annotations-13.0.jar"

    # 1. 纯 Java 库（不依赖 Kotlin）
    & $javac "-encoding" "UTF-8" "-cp" $anno "-d" $classes (Join-Path $Dir "src\main\java\Lib.java")
    if ($LASTEXITCODE -ne 0) { throw "javac 编译 Lib.java 失败" }

    # 2. Kotlin API（Main/Tests 还没编译——它们要引用 Caller）
    $api = Get-ChildItem -LiteralPath (Join-Path $Dir "src\main\kotlin") -Filter '*.kt' |
        Where-Object { $_.Name -ne 'Main.kt' } | ForEach-Object FullName
    Invoke-Kotlinc -Sources $api -OutDir $classes -ExtraCp "$classes;$anno"

    # 3. Java 消费者（引用上一步的 Kotlin 类）
    & $javac "-encoding" "UTF-8" "-cp" "$classes;$(Join-Path $libDir 'kotlin-stdlib.jar')" "-d" $classes (Join-Path $Dir "src\main\java\Caller.java")
    if ($LASTEXITCODE -ne 0) { throw "javac 编译 Caller.java 失败" }

    # 4. Kotlin 入口与测试（此刻 Caller 已存在）
    $rest = @((Join-Path $Dir "src\main\kotlin\Main.kt")) +
            @(Get-ChildItem -LiteralPath (Join-Path $Dir "test") -Filter '*.kt' -Recurse | ForEach-Object FullName)
    Invoke-Kotlinc -Sources $rest -OutDir $classes -ExtraCp "$classes;$anno"

    $extraCp = "$classes;$anno"
    Invoke-JavaMain -MainClass 'TestsKt' -ClassesDir $classes -ExtraCp $extraCp | Out-Null
    Write-Host "  [L2] 测试通过"

    $out = Invoke-JavaMain -MainClass 'MainKt' -ClassesDir $classes -ExtraCp $extraCp
    $golden = Join-Path $Dir "expected.txt"
    if ($Update) {
        $out | Set-Content -LiteralPath $golden -Encoding utf8
        Write-Host "  [L4] 已刷新 expected.txt"
    } else {
        Compare-Golden -Expected $golden -Actual $out
        Write-Host "  [L4] 输出快照一致"
    }
    Write-Host "[OK] $name" -ForegroundColor Green
}

function Test-GradleExample {
    # 17_gradle：Gradle 多模块工程（build 含 JUnit5 测试），fat jar 运行 + 快照比对
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $gradle = "G:\scoop\apps\gradle\current\bin\gradle.bat"
    if (-not (Test-Path -LiteralPath $gradle)) { throw "未找到 gradle.bat（期望 $gradle）" }

    Push-Location $Dir
    try {
        & $gradle "--no-daemon" "--console=plain" "clean" "build" 2>&1 | ForEach-Object { "$_" } | Write-Host
        if ($LASTEXITCODE -ne 0) { throw "gradle build 失败（含 test 任务）" }
        Write-Host "  [L1+L2] Gradle 编译 + JUnit5 测试通过"

        $out = & $java "-Dfile.encoding=UTF-8" "-Dstdout.encoding=UTF-8" "-Dstderr.encoding=UTF-8" "-jar" (Join-Path $Dir "app\build\libs\app-all.jar") 2>&1
        if ($LASTEXITCODE -ne 0) { $out | ForEach-Object { "$_" } | Write-Host; throw "app-all.jar 运行失败" }
        $outText = $out -join "`n"
    }
    finally { Pop-Location }

    $golden = Join-Path $Dir "expected.txt"
    if ($Update) {
        $outText | Set-Content -LiteralPath $golden -Encoding utf8
        Write-Host "  [L4] 已刷新 expected.txt"
    } else {
        if (-not (Test-Path -LiteralPath $golden)) { throw "缺少 expected.txt（先 -Update 生成并人工核对）" }
        Compare-Golden -Expected $golden -Actual $outText
        Write-Host "  [L4] 输出快照一致"
    }
    Write-Host "[OK] $name" -ForegroundColor Green
}

function Test-MultiplatformExample {
    # 25_multiplatform：common（expect 声明）+ 各目标 actual，编到 4 个目标：
    #   js / wasm-js / wasm-wasi / native——每目标：编译(-Werror) → 运行 exit 0 → expected-<目标>.txt 快照。
    # 三条实测防御（详见 docs/25-multiplatform.md 坑位清单）：
    #   1. web 链接步（-Xir-produce-js + -Xinclude）exit code=1 但产物正确（zip-fs dispose 的 NPE 假阳性）→ 按产物判定，不按退出码
    #   2. "advanced option ... obsolete form" 警告是 2.4.20 web CLI 参数序列化假警报（= 写法也报）→ 白名单放行
    #   3. konanc 不自建输出目录（先 New-Item）；必须 JDK 21——JDK ≥ 24 时 konanc.bat 引号解析直接崩
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan

    $node = (Get-Command node -ErrorAction SilentlyContinue).Source
    if (-not $node) { throw "未找到 node（js/wasm 目标的运行宿主）" }
    $knHome = "G:\scoop\apps\kotlin-native\current"
    if (-not (Test-Path -LiteralPath (Join-Path $knHome "bin\konanc.bat"))) {
        $c = Get-Command konanc.bat -ErrorAction SilentlyContinue
        if (-not $c) { throw "未找到 konanc.bat（期望 $knHome）" }
        $knHome = Split-Path (Split-Path $c.Source -Parent) -Parent
    }

    $kotlincJs   = Join-Path $kotlinHome "bin\kotlinc-js.bat"
    $kotlincWasm = Join-Path $kotlinHome "bin\kotlinc-wasm.bat"
    $konanc      = Join-Path $knHome "bin\konanc.bat"
    $commonArg   = "-Xcommon-sources=src/Common.kt"
    $noise       = "advanced option value is passed in an obsolete form"

    # web 编译器（kotlinc-js / kotlinc-wasm）统一封装：真警告即失败，产物缺失即失败
    function Invoke-WebCompile {
        param([string]$Compiler, [string[]]$CmdArgs, [string[]]$Artifacts, [switch]$StrictExit)
        $out = & $Compiler @CmdArgs 2>&1 | ForEach-Object { "$_" }
        $real = @($out | Where-Object { $_ -match "warning:" -and $_ -notmatch $noise })
        if ($real.Count -gt 0) { $real | Write-Host; throw "编译警告（非白名单）" }
        if ($StrictExit -and $LASTEXITCODE -ne 0) { $out | Write-Host; throw "编译失败（exit $LASTEXITCODE）" }
        foreach ($a in $Artifacts) {
            if (-not (Test-Path -LiteralPath $a)) { $out | Select-Object -First 12 | Write-Host; throw "缺少编译产物：$a" }
        }
    }

    # 运行捕获：退出码必须 0；wasi 经 node 内置 WASI 会打实验性警告——比对前滤掉
    function Invoke-RunCapture {
        param([string]$Exe, [string[]]$ExeArgs = @(), [string[]]$Filter = @())
        $out = & $Exe @ExeArgs 2>&1 | ForEach-Object { "$_" }
        if ($LASTEXITCODE -ne 0) { $out | Write-Host; throw "$Exe 运行失败（exit $LASTEXITCODE）" }
        $kept = $out | Where-Object { $line = "$_"; -not ($Filter | Where-Object { $line -match $_ }) }
        return ($kept -join "`n")
    }

    Push-Location $Dir
    try {
    $targets = @(
        @{ id = 'js';      golden = 'expected-js.txt' },
        @{ id = 'wasmjs';  golden = 'expected-wasmjs.txt' },
        @{ id = 'wasi';    golden = 'expected-wasi.txt' },
        @{ id = 'native';  golden = 'expected-native.txt' }
    )
    foreach ($t in $targets) {
        $id = $t.id
        $outDir = Join-Path $Dir "build\$id"
        if (Test-Path -LiteralPath $outDir) { Remove-Item -LiteralPath $outDir -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null

        if ($id -eq 'native') {
            # Native：konanc 一次出 .exe（expect/actual 由 -Xmulti-platform + -Xcommon-sources 放行）
            & $konanc '-Werror' '-Xmulti-platform' '-Xseparate-kmp-compilation' $commonArg '-o' "build\$id\probe" 'src/Common.kt' "native/Native.kt" 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch $noise } | Write-Host
            if ($LASTEXITCODE -ne 0) { throw "konanc 编译失败（exit $LASTEXITCODE）" }
            $exe = Join-Path $outDir "probe.exe"
            if (-not (Test-Path -LiteralPath $exe)) { throw "缺少编译产物：$exe" }
            $out = Invoke-RunCapture -Exe $exe
        } else {
            # web 目标：stdlib klib + 目标专属源
            $map = @{ js = 'kotlin-stdlib-js.klib'; wasmjs = 'kotlin-stdlib-wasm-js.klib'; wasi = 'kotlin-stdlib-wasm-wasi.klib' }
            $compiler = if ($id -eq 'js') { $kotlincJs } else { $kotlincWasm }
            $klib = Join-Path $libDir $map[$id]
            $srcFile = if ($id -eq 'js') { 'js/Js.kt' } elseif ($id -eq 'wasmjs') { 'wasmjs/WasmJs.kt' } else { 'wasi/WasmWasi.kt' }
            $wasmTarget = if ($id -eq 'wasmjs') { @('-Xwasm-target=wasm-js') } elseif ($id -eq 'wasi') { @('-Xwasm-target=wasm-wasi') } else { @() }
            $base = @('-Werror', '-libraries', $klib, '-Xmulti-platform', '-Xseparate-kmp-compilation', $commonArg) + $wasmTarget +
                    @('-Xir-module-name=probe', '-ir-output-name=probe', "-ir-output-dir=build/$id", 'src/Common.kt', $srcFile)
            # 第一步：klib（此步退出码可信）
            Invoke-WebCompile -Compiler $compiler -CmdArgs $base -Artifacts @((Join-Path $outDir 'probe.klib')) -StrictExit
            # 第二步：链接成程序——退出码 1 是 dispose 假阳性，只认产物
            $klibAbs = (Join-Path $outDir 'probe.klib').Replace('\', '/')
            $artifacts = if ($id -eq 'js') { @((Join-Path $outDir 'probe.js')) } else { @((Join-Path $outDir 'probe.mjs'), (Join-Path $outDir 'probe.wasm')) }
            Invoke-WebCompile -Compiler $compiler -CmdArgs ($base + @('-Xir-produce-js', "-Xinclude=$klibAbs")) -Artifacts $artifacts
            $runner = if ($id -eq 'js') { (Join-Path $outDir 'probe.js') } else { (Join-Path $outDir 'probe.mjs') }
            $filter = if ($id -eq 'wasi') { @('ExperimentalWarning', 'trace-warnings') } else { @() }
            $out = Invoke-RunCapture -Exe $node -ExeArgs @($runner) -Filter $filter
        }
        Write-Host "  [$id] 运行 exit 0"
        $golden = Join-Path $Dir $t.golden
        if ($Update) {
            $out | Set-Content -LiteralPath $golden -Encoding utf8
            Write-Host "  [L4] 已刷新 $($t.golden)（$((($out -split "`n").Count)) 行）"
        } else {
            if (-not (Test-Path -LiteralPath $golden)) { throw "缺少 $($t.golden)（先 -Update 生成并人工核对）" }
            Compare-Golden -Expected $golden -Actual $out
            Write-Host "  [L4] $($t.golden) 快照一致"
        }
    }
    Write-Host "[OK] $name" -ForegroundColor Green
    }
    finally { Pop-Location }
}

function Test-One {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    if ($Name -eq '17_gradle') { Test-GradleExample $dir }
    elseif ($Name -eq '18_javainterop') { Test-JavaInteropExample $dir }
    elseif ($Name -eq '25_multiplatform') { Test-MultiplatformExample $dir }
    else { Test-StdExample $dir }
}

if ($Example) {
    Test-One $Example
    Write-Host "`n[Done] $Example 四层验证通过（编译 -Werror / 测试 / 运行 / 快照）。" -ForegroundColor Green
    exit 0
}

if ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory |
        Where-Object { $_.Name -match '^\d\d' } |
        Sort-Object Name |
        ForEach-Object { Test-One $_.Name }
    Write-Host "`n[Done] 全部 24 个示例四层验证通过（编译 -Werror / 测试 / 运行 / 快照）。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                     验证 examples 下全部 24 个示例"
Write-Host "  .\build.ps1 -Example 12_lambdas      验证单个示例"
Write-Host "  .\build.ps1 -Example 12_lambdas -Update  用实际输出刷新 expected.txt"
Write-Host "  .\build.ps1 -Clean                   清理全部 build/.gradle 目录"
