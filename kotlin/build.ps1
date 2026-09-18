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

function Test-One {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    if ($Name -eq '17_gradle') { Test-GradleExample $dir }
    elseif ($Name -eq '18_javainterop') { Test-JavaInteropExample $dir }
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
    Write-Host "`n[Done] 全部 23 个示例四层验证通过（编译 -Werror / 测试 / 运行 / 快照）。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                     验证 examples 下全部 23 个示例"
Write-Host "  .\build.ps1 -Example 12_lambdas      验证单个示例"
Write-Host "  .\build.ps1 -Example 12_lambdas -Update  用实际输出刷新 expected.txt"
Write-Host "  .\build.ps1 -Clean                   清理全部 build/.gradle 目录"
