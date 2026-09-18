param(
    [switch]$All,
    [string]$Example,   # 示例目录名，如 12_traits
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---- 工具链定位：Windows 用 scoop 路径，其它平台回退到 PATH ----
# 注意：非 Windows 上 Join-Path 遇到 "G:\..." 会抛 "Cannot find drive"，
# 所以盘符路径必须先判平台再拼，不能靠 Test-Path 返回 $false 来跳过。
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$cargoExe = if ($onWindows) { "cargo.exe" } else { "cargo" }

$cargoDir = ""
if ($onWindows) {
    $scoopDir = "G:\scoop\apps\rust\current\bin"
    if (Test-Path -LiteralPath (Join-Path $scoopDir $cargoExe)) { $cargoDir = $scoopDir }
}
if (-not $cargoDir) {
    $cmd = Get-Command cargo -ErrorAction SilentlyContinue
    if ($cmd) { $cargoDir = Split-Path -Parent $cmd.Source }
    else { throw "未找到 cargo，请确认 Rust 已安装并在 PATH 中" }
}
$env:PATH = if ($onWindows) { "$cargoDir;$env:PATH" } else { "${cargoDir}:$env:PATH" }
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch { }

$buildTargets = Join-Path $projectRoot "target"
$buildDir     = Join-Path $projectRoot "build"
$examplesDir  = Join-Path $projectRoot "examples"
# 自带 [workspace] 的独立工程（根 Cargo.toml 的 exclude），单独进入验证
$standalone = @("17_cargo", "24_minigrep")
# 故意往 stderr 写内容的示例 —— 判定「stderr 为空」对它们不适用：
#   02_hello   演示 eprintln!（就是教你区分 stdout / stderr）
#   22_threads 演示锁中毒，必须真的 panic 一次
$stderrAllow = @("02_hello", "22_threads")
if (-not (Test-Path -LiteralPath $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

if ($Clean) {
    foreach ($t in @($buildTargets) + ($standalone | ForEach-Object { Join-Path $examplesDir "$_\target" })) {
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
    }
    Write-Host "[Clean] 已清理全部 target 目录。" -ForegroundColor Yellow
    exit 0
}

# ---- 运行期断言：与 run-all.sh 完全一致，两条通道结论必须相同 ----
function Test-HasControlChar {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    # 按字节判，别碰正则：PowerShell 正则里 \xNN 的字符类范围一写错就把 '=' 也吃掉
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# ---- 四层验证：fmt --check → clippy(-D warnings) → test → run(exit 0) ----
function Test-Example {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $out    = Join-Path $buildDir "$name.out"
    $err    = Join-Path $buildDir "$name.err"
    $runOut = Join-Path $buildDir "$name.run.out"
    # 截断而不是删除：受限环境里 Remove-Item 可能被静默拦掉，截断一定生效
    [System.IO.File]::WriteAllText($out, "")
    [System.IO.File]::WriteAllText($err, "")

    $reasons = @()
    Push-Location $Dir
    try {
        # 注意：cargo 的 stdout 必须重定向走。PowerShell 里函数的返回值 = 它往
        # 管道写的所有东西，若不重定向，Test-Example 返回的就是
        # @(cargo 的一堆输出行, $true)，-not 一个非空数组恒为 $false
        # → 失败的示例也会被算成「通过」。
        & cargo fmt --check >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "fmt 未通过" }

        & cargo clippy --quiet --all-targets -- -D warnings >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "clippy 有告警" }

        & cargo test --quiet >>$out 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "测试未通过" }

        & cargo run --quiet >$runOut 2>>$err
        if ($LASTEXITCODE -ne 0) { $reasons += "运行退出码 $LASTEXITCODE" }
    }
    finally { Pop-Location }

    # stderr 为空（抓链接告警这类只在 stderr 露头的毛病；例外见 $stderrAllow）
    if ($stderrAllow -notcontains $name) {
        $errLen = (Get-Item -LiteralPath $err).Length
        if ($errLen -gt 0) { $reasons += "stderr 非空（有告警）" }
    }
    # stdout 非空 + 无多余控制字符（抓「没真跑起来」和「吐了原始字节」）
    $runItem = Get-Item -LiteralPath $runOut -ErrorAction SilentlyContinue
    $runLen = if ($runItem) { $runItem.Length } else { 0 }
    if ($runLen -eq 0) { $reasons += "stdout 为空（没真跑起来）" }
    elseif (Test-HasControlChar $runOut) { $reasons += "stdout 含控制字符" }

    # 示例输出照常打出来（教程用法：改代码 → 重跑 → 看输出）
    if ($runLen -gt 0) { Write-Host ([System.IO.File]::ReadAllText($runOut)) -NoNewline }

    if ($reasons.Count -gt 0) {
        Write-Host "[FAIL] ${name}：$($reasons -join '; ')" -ForegroundColor Red
        if ($errLen -gt 0) {
            Write-Host "---- $name 的 stderr ----" -ForegroundColor Yellow
            Write-Host ((Get-Content -LiteralPath $err -TotalCount 20) -join [Environment]::NewLine)
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

if ($All) {
    # 根 workspace 先做一次全量 fmt 兜底（增量，很快）
    & cargo fmt --check 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "根 workspace fmt 未通过（在 rust/ 跑 cargo fmt）" }

    $pass = 0; $fail = 0; $failNames = @()
    Get-ChildItem -LiteralPath $examplesDir -Directory |
        Where-Object { $_.Name -match '^\d\d' } |
        Sort-Object Name |
        ForEach-Object {
            if (Test-Example $_.FullName) { $pass++ }
            else { $fail++; $failNames += $_.Name }
        }

    Write-Host ""
    Write-Host "通过 $pass   失败 $fail   共 $($pass + $fail)"
    if ($fail -ne 0) {
        Write-Host "失败项：$($failNames -join ', ')" -ForegroundColor Red
        exit 1
    }
    Write-Host "[Done] 全部示例四层验证通过（fmt + clippy + test + run）。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All               验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 12_traits 验证单个示例"
Write-Host "  .\build.ps1 -Clean             清理全部 target 目录"
Write-Host ""
Write-Host "等价的 shell 入口（macOS / Linux）：" -ForegroundColor Yellow
Write-Host "  ./run-all.sh              全部"
Write-Host "  ./run-all.sh 12_traits    单个"
Write-Host "  ./run-all.sh --clean      清理"
