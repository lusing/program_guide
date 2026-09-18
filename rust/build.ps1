param(
    [switch]$All,
    [string]$Example,   # 示例目录名，如 12_traits
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---- 工具链定位：scoop 安装的 Rust，回退到 PATH ----
$cargoDir = "G:\scoop\apps\rust\current\bin"
if (-not (Test-Path -LiteralPath (Join-Path $cargoDir "cargo.exe"))) {
    $cmd = Get-Command cargo -ErrorAction SilentlyContinue
    if ($cmd) { $cargoDir = Split-Path $cmd.Source }
    else { throw "未找到 cargo，请确认 Rust 安装（期望 $cargoDir）" }
}
$env:PATH = "$cargoDir;$env:PATH"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$buildTargets = Join-Path $projectRoot "target"
$examplesDir = Join-Path $projectRoot "examples"
# 自带 [workspace] 的独立工程（根 Cargo.toml 的 exclude），单独进入验证
$standalone = @("17_cargo", "24_minigrep")

if ($Clean) {
    foreach ($t in @($buildTargets) + ($standalone | ForEach-Object { Join-Path $examplesDir "$_\target" })) {
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
    }
    Write-Host "[Clean] 已清理全部 target 目录。" -ForegroundColor Yellow
    exit 0
}

# ---- 四层验证：fmt --check → clippy(-D warnings) → test → run(exit 0) ----
function Test-Example {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Push-Location $Dir
    try {
        & cargo fmt --check 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "cargo fmt --check 未通过: $name（先在该目录跑 cargo fmt）" }

        & cargo clippy --quiet --all-targets -- -D warnings
        if ($LASTEXITCODE -ne 0) { throw "clippy 未通过: $name" }

        & cargo test --quiet
        if ($LASTEXITCODE -ne 0) { throw "cargo test 未通过: $name" }

        & cargo run --quiet
        if ($LASTEXITCODE -ne 0) { throw "cargo run 退出码 ${LASTEXITCODE}: $name" }
    }
    finally { Pop-Location }
    Write-Host "[OK] $name 四层验证通过" -ForegroundColor Green
}

function Test-One {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-Example $dir
}

if ($Example) {
    Test-One $Example
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    # 根 workspace 先做一次全量 fmt/clippy 兜底（增量，很快）
    & cargo fmt --check 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "根 workspace fmt 未通过（在 rust/ 跑 cargo fmt）" }

    Get-ChildItem -LiteralPath $examplesDir -Directory |
        Where-Object { $_.Name -match '^\d\d' } |
        Sort-Object Name |
        ForEach-Object { Test-Example $_.FullName }

    Write-Host "`n[Done] 全部 23 个示例四层验证通过（fmt + clippy + test + run）。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All               验证 examples 下全部 23 个示例"
Write-Host "  .\build.ps1 -Example 12_traits 验证单个示例"
Write-Host "  .\build.ps1 -Clean             清理全部 target 目录"
