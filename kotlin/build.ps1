#requires -Version 7.0
<#
kotlin/build.ps1 —— Windows / macOS / Linux 通用验证入口（与 run-all.sh 等价，两条通道结论必须一致）

四层验证：
  L1  kotlinc -Werror 编译：退出码 0 且编译日志为空（零告警）
  L2  kotlin.test 测试（TestsKt）退出码 0
  L3  MainKt 运行：退出码 0 + stderr 为空 + stdout 非空 + 无多余控制字符
  L4  stdout 与 expected.txt 逐行一致（CRLF 归一化 + 去掉尾部空行）

用法：
  pwsh ./build.ps1 -All                      验证 examples 下全部示例
  pwsh ./build.ps1 12_lambdas                验证单个示例（位置参数）
  pwsh ./build.ps1 -Example 12_lambdas -Update   用实际输出刷新 expected.txt
  pwsh ./build.ps1 -Clean                     清理全部 build/.gradle 目录
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$All,
    [string]$Example,
    [switch]$Update,
    [switch]$Clean,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest   # 位置参数当示例名
)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---- 平台判定 ----
# $IsWindows 在所有平台都是只读自动变量，且变量名不分大小写 → 不能自己定义同名变量
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$sep       = if ($onWindows) { ';' } else { ':' }          # classpath 分隔符
$pathSep   = if ($onWindows) { ';' } else { ':' }          # PATH 分隔符
$exe       = if ($onWindows) { '.exe' } else { '' }
$bat       = if ($onWindows) { '.bat' } else { '' }

if ($Rest -and -not $Example) { $Example = $Rest[0] }

# ---- 工具链探测：环境变量 → 平台常见位置 → PATH ----
function Resolve-KotlinHome {
    if ($env:KOTLIN_HOME -and (Test-Path -LiteralPath (Join-Path $env:KOTLIN_HOME "bin/kotlinc-jvm$bat"))) { return $env:KOTLIN_HOME }
    $cands = @()
    if ($onWindows) {
        if ($env:USERPROFILE) { $cands += (Join-Path $env:USERPROFILE 'scoop/apps/kotlin/current') }
        $cands += 'G:\scoop\apps\kotlin\current'
    } else {
        $cands += '/opt/local/share/java/kotlin', '/usr/local/share/java/kotlin',
                  '/opt/homebrew/share/java/kotlin', (Join-Path $HOME '.local/share/kotlin')
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c "bin/kotlinc-jvm$bat"))) { return $c }
    }
    $cmd = Get-Command "kotlinc-jvm$bat" -ErrorAction SilentlyContinue
    if ($cmd) { return (Split-Path (Split-Path $cmd.Source -Parent) -Parent) }
    return $null
}

function Get-JdkMajor {
    # java 大版本号（"1.8.0_x" → 8；"21.0.12" → 21）；探测失败返回 0
    param([string]$JdkPath)
    try {
        $out = & (Join-Path $JdkPath "bin/java$exe") -version 2>&1 | Out-String
        if ($out -match 'version "(\d+)(?:\.(\d+))?') {
            if ([int]$Matches[1] -eq 1 -and $Matches[2]) { return [int]$Matches[2] }
            return [int]$Matches[1]
        }
    } catch { }
    return 0
}

function Resolve-JavaHome {
    # 教程钉 JDK 21（konanc 在 JDK ≥ 24 会崩；Gradle 的 jvmToolchain(21) 也要真 JDK 21）。
    # JAVA_HOME 指向非 21（如 scoop openjdk 27）时跳过它找真 21；实在没有才回退（此时 25 章 native 会挂）
    if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME "bin/java$exe"))) {
        if ((Get-JdkMajor $env:JAVA_HOME) -eq 21) { return $env:JAVA_HOME }
    }
    if (-not $onWindows) {
        $jh = '/usr/libexec/java_home'
        if (Test-Path -LiteralPath $jh) {
            $h = & $jh -v 21 2>$null
            if ($LASTEXITCODE -eq 0 -and $h) { return "$h".Trim() }
            $h = & $jh 2>$null
            if ($h) { return "$h".Trim() }
        }
    } else {
        if ($env:USERPROFILE) { $c = @((Join-Path $env:USERPROFILE 'scoop/apps/oraclejdk-lts/current'),
                                      (Join-Path $env:USERPROFILE 'scoop/apps/microsoft-jdk/current')) }
        else { $c = @() }
        foreach ($p in @($c + @('G:\scoop\apps\oraclejdk-lts\current', 'G:\scoop\apps\microsoft-jdk\current'))) {
            if ($p -and (Test-Path -LiteralPath (Join-Path $p "bin/java.exe")) -and (Get-JdkMajor $p) -eq 21) { return $p }
        }
    }
    if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME "bin/java$exe"))) { return $env:JAVA_HOME }
    $j = Get-Command 'java' -ErrorAction SilentlyContinue
    if ($j) { return (Split-Path (Split-Path $j.Source -Parent) -Parent) }
    return $null
}

function Resolve-Tool {
    param([string]$Name, [string[]]$WindowsPaths = @())
    if ($onWindows) {
        foreach ($p in $WindowsPaths) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
    }
    $c = Get-Command $Name -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    return $null
}

$kotlinHome = Resolve-KotlinHome
if (-not $kotlinHome) { throw "未找到 kotlinc-jvm$bat（设 `$env:KOTLIN_HOME 或安装 Kotlin 2.4.20）" }
$javaHome = Resolve-JavaHome
if (-not $javaHome) { throw "未找到 java（设 `$env:JAVA_HOME 或安装 JDK 21）" }
$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome/bin$pathSep$kotlinHome/bin$pathSep$env:PATH"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$kotlinc    = Join-Path $kotlinHome "bin/kotlinc-jvm$bat"
$kotlincJs  = Join-Path $kotlinHome "bin/kotlinc-js$bat"
$kotlincWasm = Join-Path $kotlinHome "bin/kotlinc-wasm$bat"
$java       = Join-Path $javaHome   "bin/java$exe"
$javac      = Join-Path $javaHome   "bin/javac$exe"
$libDir     = Join-Path $kotlinHome 'lib'
$cpTest     = @(
    (Join-Path $libDir 'kotlin-stdlib.jar'),
    (Join-Path $libDir 'kotlin-test.jar'),
    (Join-Path $libDir 'kotlinx-coroutines-core-jvm.jar'),
    (Join-Path $libDir 'kotlin-reflect.jar')   # 27 章反射要用；不存在则自动略过
) | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object { $_ }
$cpTest     = $cpTest -join $sep
$gradle = Resolve-Tool -Name 'gradle' -WindowsPaths @('G:\scoop\apps\gradle\current\bin\gradle.bat')
$node   = Resolve-Tool -Name 'node'
$konanc = Resolve-Tool -Name 'konanc' -WindowsPaths @('G:\scoop\apps\kotlin-native\current\bin\konanc.bat')

Write-Host "工具链：kotlinc = $kotlinc"
Write-Host "        java    = $java"
Write-Host "        gradle  = $(if ($gradle) { $gradle } else { '（无，17 章将跳过）' })"
Write-Host "        node    = $(if ($node) { $node } else { '（无，25 章 web 目标将跳过）' })"
Write-Host "        konanc  = $(if ($konanc) { $konanc } else { '（无，25 章 native 目标将跳过）' })"

$buildDir    = Join-Path $projectRoot 'build'
$examplesDir = Join-Path $projectRoot 'examples'

$script:Pass = 0; $script:Fail = 0; $script:Skip = 0
$script:FailedNames = @(); $script:SkippedNames = @()

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Get-ChildItem -LiteralPath $examplesDir -Directory | ForEach-Object {
        foreach ($sub in @('build', '.gradle')) {
            $t = Join-Path $_.FullName $sub
            if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
        }
    }
    Write-Host "[Clean] 已清理全部 build/.gradle 目录。" -ForegroundColor Yellow
    exit 0
}

# ---- 判定函数 ----
function Test-HasCtrlBytes {
    # 按字节判，绕开 PowerShell 正则里控制字符转义的坑（0..31 除 TAB/LF/CR）
    param([string]$Path)
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Get-NormalizedText {
    param([string]$Path)
    $t = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    if ($null -eq $t) { return '' }
    return (($t -replace "`r`n", "`n").TrimEnd())
}

function Compare-Golden {
    param([string]$Expected, [string]$ActualPath)
    $want = Get-NormalizedText -Path $Expected
    $got  = Get-NormalizedText -Path $ActualPath
    # 必须用 -cne（区分大小写）：PowerShell 的 -ne 大小写不敏感，
    # 只差大小写的输出会被判成"一致"——反向验证就是这么抓到它的
    if ($want -cne $got) {
        $w = $want -split "`n"; $g = $got -split "`n"
        for ($i = 0; $i -lt [Math]::Max($w.Count, $g.Count); $i++) {
            $a = if ($i -lt $w.Count) { $w[$i] } else { '<缺少>' }
            $b = if ($i -lt $g.Count) { $g[$i] } else { '<缺少>' }
            if ($a -cne $b) { Write-Host "  第 $($i+1) 行不一致:`n    期望: $a`n    实际: $b" -ForegroundColor Red; break }
        }
        return $false
    }
    return $true
}

function Invoke-Kotlinc {
    # L1：-Werror 编译。退出码 0 且编译器零输出（日志非空 = 有告警或多余输出）
    param([string[]]$Sources, [string]$OutDir, [string]$ExtraCp = '')
    $cp = if ($ExtraCp) { "$ExtraCp$sep$cpTest" } else { $cpTest }
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $argsFile = Join-Path (Split-Path $OutDir -Parent) 'kotlinc.args'
    @('-Werror') + @('-cp', $cp, '-d', $OutDir) + $Sources | Set-Content -LiteralPath $argsFile -Encoding utf8
    $log = & $kotlinc "@$argsFile" 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { $log | Write-Host; return 1 }
    if (@($log).Count -gt 0) { $log | Write-Host; return 2 }   # 编译日志非空
    return 0
}

function Invoke-JavaMain {
    # L3：退出码 0 + stderr 空 + stdout 非空 + 无控制字符。stdout/stderr 分别落盘
    param([string]$MainClass, [string]$ClassesDir, [string]$ExtraCp = '', [string]$OutFile, [string]$ErrFile)
    $cp = (@($ClassesDir, $ExtraCp, $cpTest) | Where-Object { $_ }) -join $sep
    & $java '-Dfile.encoding=UTF-8' '-Dstdout.encoding=UTF-8' '-Dstderr.encoding=UTF-8' -cp $cp $MainClass `
        > $OutFile 2> $ErrFile
    if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $ErrFile | Select-Object -First 20 | Write-Host; return 1 }
    if ((Get-Item -LiteralPath $ErrFile).Length -gt 0) {
        Write-Host "    stderr 非空:"; Get-Content -LiteralPath $ErrFile | Select-Object -First 20 | Write-Host; return 2
    }
    if ((Get-Item -LiteralPath $OutFile).Length -eq 0) { Write-Host '    stdout 为空（进程可能没执行到业务代码）'; return 3 }
    if (Test-HasCtrlBytes -Path $OutFile) { Write-Host '    stdout 含多余控制字符'; return 4 }
    return 0
}

function Invoke-Capture {
    # 非 JVM 目标（node / 原生二进制）的运行捕获，判定同上
    param([string]$Exe, [string[]]$ExeArgs = @(), [string]$OutFile, [string]$ErrFile, [string]$Filter = '')
    & $Exe @ExeArgs > $OutFile 2> $ErrFile
    if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $ErrFile | Select-Object -First 20 | Write-Host; return 1 }
    # node 跑 wasm-wasi 会往 stderr 打 ExperimentalWarning —— 宿主噪声，白名单滤掉（与 run-all.sh 一致）
    # 注意：清空文件要用 Clear-Content —— Set-Content -Value '' 会写进一个换行符，长度就不是 0 了
    if ($Filter -and (Get-Item -LiteralPath $ErrFile).Length -gt 0) {
        $kept = @(Get-Content -LiteralPath $ErrFile | Where-Object { $_ -notmatch $Filter })
        if ($kept.Count -eq 0) { Write-Host "    （已滤除宿主噪声：$Filter）"; Clear-Content -LiteralPath $ErrFile }
    }
    if ((Get-Item -LiteralPath $ErrFile).Length -gt 0) {
        Write-Host "    stderr 非空:"; Get-Content -LiteralPath $ErrFile | Select-Object -First 20 | Write-Host; return 2
    }
    if ((Get-Item -LiteralPath $OutFile).Length -eq 0) { Write-Host '    stdout 为空'; return 3 }
    if (Test-HasCtrlBytes -Path $OutFile) { Write-Host '    stdout 含多余控制字符'; return 4 }
    return 0
}

function Write-Fail { param([string]$Name, [string]$Why)
    $script:Fail++; $script:FailedNames += "$Name（$Why）"
    Write-Host "[FAIL] $Name —— $Why" -ForegroundColor Red
}
function Write-Ok { param([string]$Name)
    $script:Pass++; Write-Host "[OK]   $Name" -ForegroundColor Green
}
function Write-Skip { param([string]$Name, [string]$Why)
    $script:Skip++; $script:SkippedNames += "$Name（$Why）"
    Write-Host "[SKIP] $Name —— $Why" -ForegroundColor Yellow
}
function Test-Fresh {
    # 产物新鲜度：存在 **且** 比本轮的时间戳新。
    # 只判"存在"不够：产物目录动辄 50+ 文件，删除可能被环境策略静默拦下，
    # 旧产物残留会让这条判定变成假阳性（编译其实失败了，却拿上一轮的产物去跑）。
    param([string]$Path, [datetime]$Stamp)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return ((Get-Item -LiteralPath $Path).LastWriteTime -gt $Stamp)
}

function Get-RunReason { param([int]$Code)
    switch ($Code) { 1 { '退出码非 0' } 2 { 'stderr 非空' } 3 { 'stdout 为空' } 4 { 'stdout 含控制字符' } default { "rc=$Code" } }
}

# ---- 常规 kotlinc 示例 ----
function Test-StdExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $classes = Join-Path $Dir 'build/classes'
    $logDir  = Join-Path $Dir 'build'
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    if (Test-Path -LiteralPath $classes) { Remove-Item -LiteralPath $classes -Recurse -Force }

    $sources = @(Get-ChildItem -LiteralPath (Join-Path $Dir 'src') -Filter '*.kt' -Recurse | ForEach-Object FullName) +
               @(Get-ChildItem -LiteralPath (Join-Path $Dir 'test') -Filter '*.kt' -Recurse | ForEach-Object FullName)
    $rc = Invoke-Kotlinc -Sources $sources -OutDir $classes
    if ($rc -ne 0) {
        if ($rc -eq 2) { Write-Fail $name 'L1 编译日志非空（有告警或多余输出）' } else { Write-Fail $name 'L1 编译失败' }
        return
    }
    Write-Host '  [L1] 编译通过（-Werror，日志为空）'

    $outFile = Join-Path $logDir 'stdout.txt'; $errFile = Join-Path $logDir 'stderr.txt'
    Push-Location $Dir   # 运行期工作目录 = 示例目录（19/24 章在 build/ 下读写相对路径文件）
    try {
        $rc = Invoke-JavaMain -MainClass 'TestsKt' -ClassesDir $classes -OutFile $outFile -ErrFile $errFile
        if ($rc -ne 0) { Write-Fail $name "L2 测试失败（$(Get-RunReason $rc)）"; return }
        Write-Host '  [L2] 测试通过'

        $rc = Invoke-JavaMain -MainClass 'MainKt' -ClassesDir $classes -OutFile $outFile -ErrFile $errFile
        if ($rc -ne 0) { Write-Fail $name "L3 运行失败（$(Get-RunReason $rc)）"; return }
        Write-Host '  [L3] 运行通过（exit 0 / stderr 空 / stdout 非空且无控制字符）'
    } finally { Pop-Location }

    $golden = Join-Path $Dir 'expected.txt'
    if ($Update) {
        Copy-Item -LiteralPath $outFile -Destination $golden -Force
        Write-Host "  [L4] 已刷新 expected.txt（$((Get-Content -LiteralPath $golden).Count) 行）" -ForegroundColor Yellow
    } else {
        if (-not (Test-Path -LiteralPath $golden)) { Write-Fail $name 'L4 缺少 expected.txt'; return }
        if (-not (Compare-Golden -Expected $golden -ActualPath $outFile)) { Write-Fail $name 'L4 输出快照不一致'; return }
        Write-Host '  [L4] 输出快照一致'
    }
    Write-Ok $name
}

# ---- 18_javainterop：javac(纯 Java) → kotlinc(Api) → javac(Caller) → kotlinc(Main+Tests) ----
function Test-JavaInteropExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $classes = Join-Path $Dir 'build/classes'
    New-Item -ItemType Directory -Force -Path (Join-Path $Dir 'build') | Out-Null
    if (Test-Path -LiteralPath $classes) { Remove-Item -LiteralPath $classes -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $classes | Out-Null
    $anno = Join-Path $libDir 'annotations-13.0.jar'

    & $javac '-encoding' 'UTF-8' '-cp' $anno '-d' $classes (Join-Path $Dir 'src/main/java/Lib.java') 2>&1 | ForEach-Object { "$_" } | Write-Host
    if ($LASTEXITCODE -ne 0) { Write-Fail $name 'L1 javac(Lib.java) 失败'; return }

    $api = @(Get-ChildItem -LiteralPath (Join-Path $Dir 'src/main/kotlin') -Filter '*.kt' |
             Where-Object { $_.Name -ne 'Main.kt' } | ForEach-Object FullName)
    if ((Invoke-Kotlinc -Sources $api -OutDir $classes -ExtraCp "$classes$sep$anno") -ne 0) { Write-Fail $name 'L1 kotlinc(Api.kt) 失败'; return }

    & $javac '-encoding' 'UTF-8' '-cp' "$classes$sep$(Join-Path $libDir 'kotlin-stdlib.jar')" '-d' $classes `
        (Join-Path $Dir 'src/main/java/Caller.java') 2>&1 | ForEach-Object { "$_" } | Write-Host
    if ($LASTEXITCODE -ne 0) { Write-Fail $name 'L1 javac(Caller.java) 失败'; return }

    $rest = @((Join-Path $Dir 'src/main/kotlin/Main.kt')) +
            @(Get-ChildItem -LiteralPath (Join-Path $Dir 'test') -Filter '*.kt' -Recurse | ForEach-Object FullName)
    if ((Invoke-Kotlinc -Sources $rest -OutDir $classes -ExtraCp "$classes$sep$anno") -ne 0) { Write-Fail $name 'L1 kotlinc(Main+Tests) 失败'; return }
    Write-Host '  [L1] 四步混编通过（javac → kotlinc → javac → kotlinc）'

    $outFile = Join-Path $Dir 'build/stdout.txt'; $errFile = Join-Path $Dir 'build/stderr.txt'
    $extraCp = "$classes$sep$anno"
    $rc = Invoke-JavaMain -MainClass 'TestsKt' -ClassesDir $classes -ExtraCp $extraCp -OutFile $outFile -ErrFile $errFile
    if ($rc -ne 0) { Write-Fail $name "L2 测试失败（$(Get-RunReason $rc)）"; return }
    Write-Host '  [L2] 测试通过'
    $rc = Invoke-JavaMain -MainClass 'MainKt' -ClassesDir $classes -ExtraCp $extraCp -OutFile $outFile -ErrFile $errFile
    if ($rc -ne 0) { Write-Fail $name "L3 运行失败（$(Get-RunReason $rc)）"; return }
    Write-Host '  [L3] 运行通过'

    $golden = Join-Path $Dir 'expected.txt'
    if ($Update) { Copy-Item -LiteralPath $outFile -Destination $golden -Force; Write-Host '  [L4] 已刷新 expected.txt' -ForegroundColor Yellow }
    else {
        if (-not (Test-Path -LiteralPath $golden)) { Write-Fail $name 'L4 缺少 expected.txt'; return }
        if (-not (Compare-Golden -Expected $golden -ActualPath $outFile)) { Write-Fail $name 'L4 输出快照不一致'; return }
        Write-Host '  [L4] 输出快照一致'
    }
    Write-Ok $name
}

# ---- 17_gradle：Gradle 多模块工程（含 JUnit5）+ fat jar 运行 + 快照 ----
function Test-GradleExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    if (-not $gradle) { Write-Skip $name '本机无 gradle'; return }

    New-Item -ItemType Directory -Force -Path (Join-Path $Dir 'build') | Out-Null
    $logFile = Join-Path $Dir 'build/gradle.log'
    Push-Location $Dir
    try {
        # jvmToolchain(21) 要 Gradle 真找到 JDK 21 → 显式告知安装位置，换机器自动适配
        & $gradle '--no-daemon' '--console=plain' 'clean' 'build' "-Porg.gradle.java.installations.paths=$javaHome" `
            > $logFile 2>&1
        if ($LASTEXITCODE -ne 0) {
            Get-Content -LiteralPath $logFile | Select-Object -Last 25 | Write-Host
            Write-Fail $name 'L1/L2 Gradle build 失败（含 test 任务）'; return
        }
        Write-Host '  [L1+L2] Gradle 编译 + JUnit5 测试通过'
    } finally { Pop-Location }

    $jar = Join-Path $Dir 'app/build/libs/app-all.jar'
    if (-not (Test-Path -LiteralPath $jar)) { Write-Fail $name "缺少 fat jar: $jar"; return }
    $outFile = Join-Path $Dir 'build/stdout.txt'; $errFile = Join-Path $Dir 'build/stderr.txt'
    & $java '-Dfile.encoding=UTF-8' '-Dstdout.encoding=UTF-8' '-Dstderr.encoding=UTF-8' '-jar' $jar > $outFile 2> $errFile
    if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $errFile | Select-Object -First 20 | Write-Host; Write-Fail $name 'L3 fat jar 运行失败'; return }
    if ((Get-Item -LiteralPath $errFile).Length -gt 0) { Write-Host '    stderr 非空:'; Get-Content -LiteralPath $errFile | Select-Object -First 20 | Write-Host; Write-Fail $name 'L3 stderr 非空'; return }
    if ((Get-Item -LiteralPath $outFile).Length -eq 0) { Write-Fail $name 'L3 stdout 为空'; return }
    if (Test-HasCtrlBytes -Path $outFile) { Write-Fail $name 'L3 stdout 含控制字符'; return }
    Write-Host '  [L3] fat jar 运行通过'

    $golden = Join-Path $Dir 'expected.txt'
    if ($Update) { Copy-Item -LiteralPath $outFile -Destination $golden -Force; Write-Host '  [L4] 已刷新 expected.txt' -ForegroundColor Yellow }
    else {
        if (-not (Test-Path -LiteralPath $golden)) { Write-Fail $name 'L4 缺少 expected.txt'; return }
        if (-not (Compare-Golden -Expected $golden -ActualPath $outFile)) { Write-Fail $name 'L4 输出快照不一致'; return }
        Write-Host '  [L4] 输出快照一致'
    }
    Write-Ok $name
}

# ---- 25_multiplatform：四目标各「编译 → 运行 exit 0 → expected-<目标>.txt 快照」 ----
function Test-MultiplatformExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    # 三条实测防御（详见 docs/25-multiplatform.md 坑位清单）：
    #   1. web 链接步（-Xir-produce-js + -Xinclude）exit code=1 但产物正确（zip-fs dispose 的 NPE 假阳性）→ 按产物判定
    #   2. "advanced option ... obsolete form" 警告是 2.4.20 web CLI 参数序列化假警报 → 白名单放行
    #   3. konanc 不自建输出目录（先 New-Item）；必须 JDK 21——JDK ≥ 24 时 konanc 引号解析会崩
    $noise = 'advanced option value is passed in an obsolete form'
    $common = '-Xcommon-sources=src/Common.kt'
    $subfail = $false

    Push-Location $Dir
    try {
        foreach ($t in @(
            @{ id = 'js';     golden = 'expected-js.txt' },
            @{ id = 'wasmjs'; golden = 'expected-wasmjs.txt' },
            @{ id = 'wasi';   golden = 'expected-wasi.txt' },
            @{ id = 'native'; golden = 'expected-native.txt' }
        )) {
            $id = $t.id
            $outDir = Join-Path $Dir "build/$id"
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
            # 同理只删本次要重新生成的产物，避免"旧产物残留 → 产物存在判定假阳性"
            foreach ($f in @('probe.klib', 'probe.js', 'probe.mjs', 'probe.wasm', 'probe.kexe', 'probe.exe')) {
                $p = Join-Path $outDir $f
                if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
            }
            $logFile = Join-Path $Dir "build/$id.log"
            $outFile = Join-Path $outDir 'stdout.txt'; $errFile = Join-Path $outDir 'stderr.txt'
            $stamp = Get-Date      # 产物新鲜度基准：下面判定"产物必须是本轮生成的"

            if ($id -eq 'native') {
                if (-not $konanc) { Write-Skip "$name/$id" '本机无 konanc（Kotlin/Native 未安装）'; continue }
                & $konanc '-Werror' '-Xmulti-platform' '-Xseparate-kmp-compilation' $common `
                    '-o' "build/$id/probe" 'src/Common.kt' 'native/Native.kt' > $logFile 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Get-Content -LiteralPath $logFile | Select-Object -Last 20 | Write-Host
                    Write-Fail "$name/$id" 'konanc 编译失败'; $subfail = $true; continue
                }
                $exe = Join-Path $outDir 'probe.kexe'
                if (-not (Test-Fresh -Path $exe -Stamp $stamp)) { $exe = Join-Path $outDir 'probe.exe' }
                if (-not (Test-Fresh -Path $exe -Stamp $stamp)) { Write-Fail "$name/$id" '缺少产物 probe.kexe'; $subfail = $true; continue }
                $rc = Invoke-Capture -Exe $exe -OutFile $outFile -ErrFile $errFile
            } else {
                switch ($id) {
                    'js'     { $compiler = $kotlincJs;   $klib = Join-Path $libDir 'kotlin-stdlib-js.klib';       $srcFile = 'js/Js.kt';         $wasmTarget = @() }
                    'wasmjs' { $compiler = $kotlincWasm; $klib = Join-Path $libDir 'kotlin-stdlib-wasm-js.klib';  $srcFile = 'wasmjs/WasmJs.kt'; $wasmTarget = @('-Xwasm-target=wasm-js') }
                    'wasi'   { $compiler = $kotlincWasm; $klib = Join-Path $libDir 'kotlin-stdlib-wasm-wasi.klib'; $srcFile = 'wasi/WasmWasi.kt'; $wasmTarget = @('-Xwasm-target=wasm-wasi') }
                }
                if (-not $node) { Write-Skip "$name/$id" '本机无 node'; continue }
                $base = @('-Werror', '-libraries', $klib, '-Xmulti-platform', '-Xseparate-kmp-compilation', $common) + $wasmTarget +
                        @('-Xir-module-name=probe', '-ir-output-name=probe', "-ir-output-dir=build/$id", 'src/Common.kt', $srcFile)
                # 第一步：klib（此步退出码可信）
                & $compiler @base > $logFile 2>&1
                if ($LASTEXITCODE -ne 0 -or -not (Test-Fresh -Path (Join-Path $outDir 'probe.klib') -Stamp $stamp)) {
                    Get-Content -LiteralPath $logFile | Select-Object -Last 20 | Write-Host
                    Write-Fail "$name/$id" 'klib 编译失败'; $subfail = $true; continue
                }
                $realWarn = @(Get-Content -LiteralPath $logFile | Where-Object { $_ -match 'warning:' -and $_ -notmatch $noise })
                if ($realWarn.Count -gt 0) { $realWarn | Write-Host; Write-Fail "$name/$id" '编译有警告（非白名单）'; $subfail = $true; continue }
                # 第二步：链接成程序——退出码 1 是 dispose 假阳性，只认产物
                $klibArg = "-Xinclude=build/$id/probe.klib"
                & $compiler (@($base) + @('-Xir-produce-js', $klibArg)) > $logFile 2>&1
                $runner = if ($id -eq 'js') { Join-Path $outDir 'probe.js' } else { Join-Path $outDir 'probe.mjs' }
                if (-not (Test-Fresh -Path $runner -Stamp $stamp)) {
                    Get-Content -LiteralPath $logFile | Select-Object -Last 20 | Write-Host
                    Write-Fail "$name/$id" "缺少产物 $(Split-Path -Leaf $runner)"; $subfail = $true; continue
                }
                $filt = if ($id -eq 'wasi') { 'ExperimentalWarning|trace-warnings' } else { '' }
                $rc = Invoke-Capture -Exe $node -ExeArgs @($runner) -OutFile $outFile -ErrFile $errFile -Filter $filt
            }
            if ($rc -ne 0) { Write-Fail "$name/$id" "运行失败（$(Get-RunReason $rc)）"; $subfail = $true; continue }
            Write-Host "  [$id] 运行 exit 0"

            $golden = Join-Path $Dir $t.golden
            if ($Update) {
                Copy-Item -LiteralPath $outFile -Destination $golden -Force
                Write-Host "  [L4] 已刷新 $($t.golden)" -ForegroundColor Yellow; continue
            }
            if (-not (Test-Path -LiteralPath $golden)) { Write-Fail "$name/$id" "缺少 $($t.golden)"; $subfail = $true; continue }
            if (-not (Compare-Golden -Expected $golden -ActualPath $outFile)) { Write-Fail "$name/$id" '快照不一致'; $subfail = $true; continue }
            Write-Host "  [L4] $($t.golden) 快照一致"
        }
    } finally { Pop-Location }

    if (-not $subfail) { Write-Ok $name }
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
} elseif ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory |
        Where-Object { $_.Name -match '^\d\d' } |
        Sort-Object Name |
        ForEach-Object { Test-One $_.Name }
} else {
    Write-Host '用法:' -ForegroundColor Yellow
    Write-Host '  pwsh ./build.ps1 -All                     验证 examples 下全部示例'
    Write-Host '  pwsh ./build.ps1 12_lambdas               验证单个示例'
    Write-Host '  pwsh ./build.ps1 -Example 12_lambdas -Update  用实际输出刷新 expected.txt'
    Write-Host '  pwsh ./build.ps1 -Clean                   清理全部 build/.gradle 目录'
    exit 0
}

Write-Host "`n================ 汇总 ================"
Write-Host "通过 $script:Pass   失败 $script:Fail   跳过 $script:Skip"
if ($script:FailedNames.Count -gt 0) { Write-Host "失败项: $($script:FailedNames -join ', ')" -ForegroundColor Red }
if ($script:SkippedNames.Count -gt 0) { Write-Host "跳过项: $($script:SkippedNames -join ', ')" -ForegroundColor Yellow }
if ($script:Fail -gt 0) { exit 1 }
Write-Host '四层验证通过（编译 -Werror / 测试 / 运行 / 快照）。' -ForegroundColor Green
