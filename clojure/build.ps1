#Requires -Version 7
# ============================================================================
# build.ps1 - Clojure 教程 Windows 构建入口（需要 pwsh 7+，文件必须无 BOM）
#
# 工具链：Leiningen（project.clj 声明依赖）+ java（JDK 16+），
#         示例脚本统一由 `java -cp <classpath> clojure.main <file>` 执行。
#         （macOS/Linux 侧用 build.sh + Clojure CLI，两边依赖声明一致）
#
# 用法：
#   ./build.ps1 -All              # 运行全部 24 个示例 + lein-lab 全链路
#   ./build.ps1 -File 01          # 运行单个示例（编号 / 文件名均可）
#   ./build.ps1 -File 01_hello.clj
#   ./build.ps1 -Lab              # 只跑 lein-lab（test/run/uberjar/java -jar）
#   ./build.ps1 -Clean            # 清理 build/ 与 target/
#
# 判定标准（三层）：
#   1. 进程退出码为 0
#   2. stdout 出现结束标记 ==== NN jieshu ==== / ==== LAB jieshu ====
#   3. build/ 目录生成对应 .log 日志
# ============================================================================
[CmdletBinding()]
param(
    [switch]$All,
    [string]$File,
    [switch]$Lab,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot
$ExamplesDir = Join-Path $ProjectRoot 'examples'
$BuildDir    = Join-Path $ProjectRoot 'build'
$LabDir      = Join-Path $ProjectRoot 'lein-lab'

# ----------------------------------------------------------------------------
# 1) 探测工具链：Leiningen + JDK 16+（lein 2.13 的启动器会传
#    --enable-native-access=ALL-UNNAMED，Java 8/11 不认识会直接崩）
# ----------------------------------------------------------------------------
function Resolve-Java {
    $candidates = @()
    if ($env:JAVA_CMD) { $candidates += $env:JAVA_CMD }
    $candidates += @(
        'G:\scoop\apps\openjdk\current\bin\java.exe',
        'G:\scoop\apps\microsoft-jdk\current\bin\java.exe',
        'G:\scoop\apps\openjdk17\current\bin\java.exe',
        "$env:JAVA_HOME\bin\java.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($java in $candidates) {
        $verOut = & $java '-version' 2>&1 | Select-Object -First 1
        if ($verOut -match 'version "(\d+)') {
            if ([int]$Matches[1] -ge 16) { return $java }
            Write-Host "[skip] $java 是 JDK $($Matches[1])（需要 16+）"
        }
    }
    throw "找不到 JDK 16+。请设置 `$env:JAVA_CMD 指向新 JDK（当前 PATH 里的 java 可能是 8）。"
}

if ($Clean) {
    foreach ($d in @($BuildDir, (Join-Path $ProjectRoot 'target'), (Join-Path $LabDir 'target'))) {
        if (Test-Path $d) { Remove-Item -Recurse -Force $d; Write-Host "[Clean] $d" }
    }
    exit 0
}

if (-not ($All -or $File -or $Lab)) {
    Write-Host "用法: ./build.ps1 -All | -File <01|01_hello.clj> | -Lab | -Clean"
    exit 0
}

$Java = Resolve-Java
$env:JAVA_CMD = $Java
Write-Host "[Toolchain] java   = $Java"
if (-not (Get-Command lein -ErrorAction SilentlyContinue)) {
    throw "未找到 lein。本教程按 Leiningen 2.13 验证（scoop: G:\scoop\apps\leiningen\current）。"
}
Write-Host "[Toolchain] lein   = $((Get-Command lein).Source)"

New-Item -ItemType Directory -Force $BuildDir | Out-Null
$script:Failures = 0

# ----------------------------------------------------------------------------
# 2) 依赖与 classpath（lein deps 幂等；classpath 只取一次，之后直接用 java）
# ----------------------------------------------------------------------------
Push-Location $ProjectRoot
try {
    Write-Host '[Deps] lein deps ...'
    lein deps | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'lein deps 失败（检查网络 / Maven Central / Clojars 可达性）' }
    $Classpath = (lein classpath | Select-Object -First 1)
    if (-not $Classpath) { throw 'lein classpath 返回为空' }
} finally { Pop-Location }

function Invoke-Example {
    param([string]$Path)
    $name = Split-Path $Path -Leaf
    $log  = Join-Path $BuildDir ($name -replace '\.clj$', '.log')
    Write-Host "`n[Run] $name"
    # 注意：-cp 等参数必须逐个成串传递（PS 会把 -Dxxx=yyy 拆散，实测坑）
    $out = & $Java '-Dfile.encoding=UTF-8' '-cp' $Classpath 'clojure.main' $Path 2>&1
    $code = $LASTEXITCODE
    $out | Tee-Object -FilePath $log
    $marker = $out | Select-String '==== \d+ jieshu ====' | Select-Object -First 1
    if ($code -eq 0 -and $marker) {
        Write-Host "[OK] $name  $($marker.Matches.Value)"
    } else {
        $script:Failures++
        Write-Host "[FAIL] $name  (exit=$code, marker=$($null -ne $marker))" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------------------
# 3) 示例（examples/*.clj，按文件名排序 01-24）
# ----------------------------------------------------------------------------
if ($File) {
    $orig = $File
    if ($File -notmatch '\.clj$') { $File = "$File.clj" }
    $target = Get-ChildItem $ExamplesDir -Filter $File -ErrorAction SilentlyContinue
    if (-not $target) {
        # 只给编号也行：01 -> 01_hello.clj
        $target = Get-ChildItem $ExamplesDir -Filter "$orig*" | Select-Object -First 1
    }
    if (-not $target) { throw "找不到示例: $File" }
    Invoke-Example $target.FullName
    exit $(if ($script:Failures -eq 0) { 0 } else { 1 })
}

if ($All) {
    foreach ($f in (Get-ChildItem $ExamplesDir -Filter '*.clj' | Sort-Object Name)) {
        Invoke-Example $f.FullName
    }
}

# ----------------------------------------------------------------------------
# 4) lein-lab 全链路：lein test -> lein run -> lein uberjar -> java -jar
# ----------------------------------------------------------------------------
function Invoke-Lein {
    param([string]$Dir, [string[]]$LeinArgs)
    Push-Location $Dir
    try {
        $out = lein @LeinArgs 2>&1
        [pscustomobject]@{ Out = $out; Code = $LASTEXITCODE }
    } finally { Pop-Location }
}

function Invoke-Lab {
    Write-Host "`n[Lab] lein test"
    $t = Invoke-Lein $LabDir @('test')
    $t.Out | Tee-Object (Join-Path $BuildDir 'lab-test.log') | Select-Object -Last 5
    $testOk = ($t.Code -eq 0) -and ($null -ne ($t.Out | Select-String '0 failures, 0 errors'))
    Write-Host $(if ($testOk) { '[OK] lein test' } else { '[FAIL] lein test' })

    Write-Host "`n[Lab] lein run"
    $r = Invoke-Lein $LabDir @('run')
    $r.Out | Tee-Object (Join-Path $BuildDir 'lab-run.log') | Select-Object -Last 3
    $runOk = ($r.Code -eq 0) -and ($null -ne ($r.Out | Select-String '==== LAB jieshu ===='))
    Write-Host $(if ($runOk) { '[OK] lein run' } else { '[FAIL] lein run' })

    Write-Host "`n[Lab] lein uberjar + java -jar"
    $u = Invoke-Lein $LabDir @('uberjar')
    $u.Out | Tee-Object (Join-Path $BuildDir 'lab-uberjar.log') | Select-Object -Last 2
    $jarOk = $u.Code -eq 0
    $jar = Get-ChildItem (Join-Path $LabDir 'target') -Filter '*standalone.jar' |
           Select-Object -First 1
    $jarRunOk = $false
    if ($jarOk -and $jar) {
        Write-Host "[Lab] java -jar $($jar.Name)"
        $j = & $Java '-jar' $jar.FullName 2>&1
        $j | Tee-Object (Join-Path $BuildDir 'lab-jar.log') | Select-Object -Last 3
        $jarRunOk = ($LASTEXITCODE -eq 0) -and ($null -ne ($j | Select-String '==== LAB jieshu ===='))
    }
    Write-Host $(if ($jarOk -and $jarRunOk) { '[OK] uberjar + java -jar' } else { '[FAIL] uberjar / java -jar' })

    if (-not ($testOk -and $runOk -and $jarOk -and $jarRunOk)) { $script:Failures++ }
}

if ($All -or $Lab) { Invoke-Lab }

# ----------------------------------------------------------------------------
# 5) 汇总
# ----------------------------------------------------------------------------
$total = 0
if ($All) { $total = (Get-ChildItem $ExamplesDir -Filter '*.clj').Count + 1 }
elseif ($Lab) { $total = 1 }
elseif ($File) { $total = 1 }
if ($script:Failures -eq 0) {
    Write-Host "`n[Done] 全部 $total 个验证单元通过。"
    exit 0
} else {
    Write-Host "`n[Done] $script:Failures 个验证单元失败。" -ForegroundColor Red
    exit 1
}
