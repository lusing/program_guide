param(
    [switch]$All,
    [string]$Example,   # 示例目录名，如 02_egui_hello
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---- 工具链定位：Windows 优先 scoop 路径，其它平台/找不到时回退 PATH ----
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$cargoExe = if ($onWindows) { "cargo.exe" } else { "cargo" }
$cargoDir = ""
if ($onWindows) {
    foreach ($p in @("G:\scoop\apps\rust\current\bin", "G:\scoop\apps\rustup\current\.cargo\bin")) {
        if (Test-Path -LiteralPath (Join-Path $p $cargoExe)) { $cargoDir = $p; break }
    }
}
if (-not $cargoDir) {
    $cmd = Get-Command cargo -ErrorAction SilentlyContinue
    if ($cmd) { $cargoDir = Split-Path -Parent $cmd.Source }
    else { throw "未找到 cargo，请确认 Rust 已安装并在 PATH 中" }
}
$env:PATH = if ($onWindows) { "$cargoDir;$env:PATH" } else { "${cargoDir}:$env:PATH" }
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch { }

# ---- GTK4（第四部分 24–30 章）：gvsbuild 栈自动注入 ----
# gtk4 crate 的 system-deps 经 pkg-config（--msvc-syntax）找 GTK；编译出的
# 二进制运行期还要 GTK 的 DLL 在 PATH。按 24 章步骤解压到 G:\gtk（或
# C:\gtk）的机器在此自动生效；装在别处或 Linux/macOS 的读者按 24 章设好
# PKG_CONFIG_PATH / PATH 即可，本守卫找不到就什么都不做。
if ($onWindows) {
    foreach ($g in @("G:\gtk", "C:\gtk")) {
        if (Test-Path -LiteralPath (Join-Path $g "lib\pkgconfig\gtk4.pc")) {
            $env:PATH = "$g\bin;$env:PATH"
            if ($env:PKG_CONFIG_PATH) { $env:PKG_CONFIG_PATH = "$g\lib\pkgconfig;$env:PKG_CONFIG_PATH" }
            else { $env:PKG_CONFIG_PATH = "$g\lib\pkgconfig" }
            break
        }
    }
}

$buildDir     = Join-Path $projectRoot "build"
$examplesDir  = Join-Path $projectRoot "examples"
$targetDir    = Join-Path $projectRoot "target"
$SELFTEST_TIMEOUT_MS = 60000
# 故意往 stderr 写内容的示例（目前无；有例外时在此登记并注明原因）
$stderrAllow = @()

if (-not (Test-Path -LiteralPath $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

if ($Clean) {
    foreach ($t in @($targetDir)) {
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
    }
    Write-Host "[Clean] 已清理 target 目录。" -ForegroundColor Yellow
    exit 0
}

# ---- 运行期断言辅助 ----
function Test-HasControlChar {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    # 按字节判，别碰正则：\xNN 的字符类范围一写错就把 '=' 也吃掉
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# 带超时运行示例二进制：GUI 框架的 selftest 一旦失控（弹真窗、死循环）
# 不能拖垮整个 -All，60 秒强杀进程树。
function Invoke-Selftest {
    param([string]$ExePath, [string]$OutFile, [string]$ErrFile)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $ExePath
    $psi.Arguments = "--selftest"
    $psi.WorkingDirectory = $projectRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.UTF8Encoding]::new()
    $psi.StandardErrorEncoding = [System.Text.UTF8Encoding]::new()
    $p = [System.Diagnostics.Process]::new()
    $p.StartInfo = $psi
    $null = $p.Start()
    # 先挂异步读再等待，避免管道写满导致死锁
    $so = $p.StandardOutput.ReadToEndAsync()
    $se = $p.StandardError.ReadToEndAsync()
    $timedOut = -not $p.WaitForExit($SELFTEST_TIMEOUT_MS)
    if ($timedOut) {
        try { $p.Kill($true) } catch { try { $p.Kill() } catch { } }
    }
    $p.WaitForExit()
    [System.IO.File]::WriteAllText($OutFile, $so.Result)
    [System.IO.File]::WriteAllText($ErrFile, $se.Result)
    return @{ Code = $p.ExitCode; TimedOut = $timedOut }
}

# ---- 四层验证：fmt --check → clippy(-D warnings) → test → build+selftest ----
function Test-Example {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    $pkgName = ($name -replace '^\d+_?', '')   # 02_egui_hello → egui_hello
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $out    = Join-Path $buildDir "$name.out"
    $err    = Join-Path $buildDir "$name.err"
    $runOut = Join-Path $buildDir "$name.run.out"
    $runOut2 = Join-Path $buildDir "$name.run2.out"
    $runErr = Join-Path $buildDir "$name.run.err"
    # 截断而不是删除：受限环境里 Remove-Item 可能被静默拦掉
    foreach ($f in @($out, $err, $runOut, $runOut2, $runErr)) {
        [System.IO.File]::WriteAllText($f, "")
    }

    $reasons = @()
    Push-Location $Dir
    try {
        # 注意：cargo 的 stdout 必须重定向走。PowerShell 里函数的返回值 = 它往
        # 管道写的所有东西，若不重定向，Test-Example 返回的就是 @(cargo 输出, $true)
        & cargo fmt --check >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "fmt 未通过" }

        & cargo clippy --quiet --all-targets -- -D warnings >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "clippy 有告警" }

        & cargo test --quiet >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "测试未通过" }

        & cargo build --quiet >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "构建失败" }
    }
    finally { Pop-Location }

    # 第 4 层：直接驱动示例二进制的 --selftest（超时保护 + 两跑一致）
    $exeName = if ($onWindows) { "$pkgName.exe" } else { $pkgName }
    $exe = Join-Path $targetDir "debug\$exeName"
    if ($reasons.Count -eq 0 -and (Test-Path -LiteralPath $exe)) {
        $r1 = Invoke-Selftest $exe $runOut $runErr
        if ($r1.TimedOut) { $reasons += "selftest 超时（${SELFTEST_TIMEOUT_MS}ms）" }
        elseif ($r1.Code -ne 0) { $reasons += "selftest 退出码 $($r1.Code)" }
        else {
            $r2 = Invoke-Selftest $exe $runOut2 $runErr
            if ($r2.Code -ne 0) { $reasons += "selftest 第二跑退出码 $($r2.Code)" }
            else {
                # Compare-Object 无差异时输出为空；有输出即两跑不一致
                # （时间戳/随机数混进 selftest 的典型症状）
                $diff = Compare-Object (Get-Content $runOut) (Get-Content $runOut2)
                if ($null -ne $diff -and @($diff).Count -gt 0) {
                    $reasons += "两跑 stdout 不一致"
                }
            }
        }
        # selftest 的 stderr 并入总 stderr 判定（上面 >>$err 的 cargo stderr 之外）
        if ((Test-Path -LiteralPath $runErr) -and (Get-Item $runErr).Length -gt 0) {
            [System.IO.File]::AppendAllText($err, [System.IO.File]::ReadAllText($runErr))
        }
    }
    elseif ($reasons.Count -eq 0) {
        $reasons += "找不到示例二进制：$exe"
    }

    # ---- 三条运行期断言 ----
    if ($stderrAllow -notcontains $name) {
        $errLen = (Get-Item -LiteralPath $err).Length
        if ($errLen -gt 0) { $reasons += "stderr 非空（有告警）" }
    }
    $runLen = if (Test-Path -LiteralPath $runOut) { (Get-Item $runOut).Length } else { 0 }
    if ($runLen -eq 0) { $reasons += "stdout 为空（没真跑起来）" }
    else {
        $runText = [System.IO.File]::ReadAllText($runOut)
        if ($runText -notmatch '==== \d{2} ') { $reasons += "stdout 缺开始标记（==== NN ）" }
        if ($runText -notmatch '结束 ====') { $reasons += "stdout 缺结束标记（结束 ====）" }
        if (Test-HasControlChar $runOut) { $reasons += "stdout 含控制字符" }
    }

    # 示例输出照常打出来（教程用法：改代码 → 重跑 → 看输出）
    if ($runLen -gt 0) { Write-Host ([System.IO.File]::ReadAllText($runOut)) -NoNewline }

    if ($reasons.Count -gt 0) {
        Write-Host "[FAIL] ${name}：$($reasons -join '; ')" -ForegroundColor Red
        if ((Test-Path -LiteralPath $err) -and (Get-Item $err).Length -gt 0) {
            Write-Host "---- $name 的 stderr ----" -ForegroundColor Yellow
            Write-Host ((Get-Content -LiteralPath $err -TotalCount 30) -join [Environment]::NewLine)
            Write-Host "-------------------------" -ForegroundColor Yellow
        }
        return $false
    }
    Write-Host "[OK] $name 四层验证通过" -ForegroundColor Green
    return $true
}

function Test-One {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    return (Test-Example $dir)
}

if ($Example) {
    if (-not (Test-One $Example)) {
        Write-Host "`n[Done] $Example 验证失败。" -ForegroundColor Red
        exit 1
    }
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if (-not $All) {
    Write-Host "用法：build.ps1 -All（全部示例） | -Example 02_egui_hello（单个） | -Clean"
    exit 0
}

$dirs = Get-ChildItem $examplesDir -Directory | Sort-Object Name
$fail = 0; $pass = 0
foreach ($d in $dirs) {
    if (Test-Example $d.FullName) { $pass++ } else { $fail++ }
}

# ---- 文档五关核查（-All 末尾自动跑；全绿才算过）----
$py = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
    Write-Host "`n[Docs] 五关机器核查" -ForegroundColor Cyan
    & python (Join-Path $projectRoot "tools\check_docs.py") 2>&1 | Tee-Object -Variable docsOut | Write-Host
    if ($LASTEXITCODE -ne 0) { $fail++ }
}
else {
    Write-Host "[Docs] 未找到 python，跳过五关核查" -ForegroundColor Yellow
}

Write-Host "`n[Summary] 通过 $pass 失败 $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
exit ($(if ($fail -gt 0) { 1 } else { 0 }))
