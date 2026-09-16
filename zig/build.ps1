param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$zigExe = "G:\scoop\apps\zig\current\zig.exe"
if (-not (Test-Path -LiteralPath $zigExe)) { throw "未找到 zig.exe：$zigExe" }
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Zig {
    param([string]$WorkingDir, [string[]]$ArgList)
    Push-Location $WorkingDir
    try {
        & $zigExe @ArgList
        if ($LASTEXITCODE -ne 0) { throw "命令失败: zig $($ArgList -join ' ') (cwd=$WorkingDir)" }
    } finally { Pop-Location }
}

function Invoke-Native {
    param([string]$ExePath)
    & $ExePath
    if ($LASTEXITCODE -ne 0) { throw "运行失败(退出码 $LASTEXITCODE): $ExePath" }
}

# 普通示例三层验证：fmt --check → test → build-exe → 运行
# ExtraArgs（如 -lc）只传给 test 与 build-exe，fmt 不接受链接参数
function Test-PlainExample {
    param([string]$Dir, [string[]]$ExtraArgs = @())
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Invoke-Zig $Dir @("fmt", "--check", ".")
    Invoke-Zig $Dir (@("test", "main.zig") + $ExtraArgs)
    $exe = Join-Path $buildDir "$name.exe"
    Invoke-Zig $Dir (@("build-exe", "main.zig", "-femit-bin=$exe") + $ExtraArgs)
    Invoke-Native $exe
    Get-ChildItem -LiteralPath $Dir -Filter "*.pdb" -ErrorAction SilentlyContinue |
        Move-Item -Destination $buildDir -Force -ErrorAction SilentlyContinue
}

# build.zig 工程：fmt --check . → build test → build run
function Test-ProjectExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (build.zig 工程)" -ForegroundColor Cyan
    Invoke-Zig $Dir @("fmt", "--check", ".")
    Invoke-Zig $Dir @("build", "test")
    Invoke-Zig $Dir @("build", "run")
}

# 18_cross：本机三层 + 三目标交叉编译（编译即验证）+ zig cc 编 C
function Test-CrossExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (交叉编译)" -ForegroundColor Cyan
    Invoke-Zig $Dir @("fmt", "--check", ".")
    Invoke-Zig $Dir @("test", "main.zig")
    $exe = Join-Path $buildDir "$name.exe"
    Invoke-Zig $Dir @("build-exe", "main.zig", "-femit-bin=$exe")
    Invoke-Native $exe
    Invoke-Zig $Dir @("build-exe", "main.zig", "-target", "aarch64-linux",
        "-femit-bin=$(Join-Path $buildDir "$name`_aarch64-linux")")
    Invoke-Zig $Dir @("build-lib", "wasm_lib.zig", "-target", "wasm32-freestanding",
        "-femit-bin=$(Join-Path $buildDir "$name`.wasm")")
    Invoke-Zig $Dir @("cc", "hello.c", "-o", (Join-Path $buildDir "$name`_hello_c.exe"))
    Invoke-Native (Join-Path $buildDir "$name`_hello_c.exe")
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "16_build" { Test-ProjectExample $Dir }
        "24_minigrep" { Test-ProjectExample $Dir }
        "17_cinterop" { Test-PlainExample $Dir @("-lc") }
        "18_cross" { Test-CrossExample $Dir }
        default { Test-PlainExample $Dir }
    }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $dir
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name | ForEach-Object {
        Test-One $_.FullName
    }
    Write-Host "`n[Done] 全部示例三层验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 12_collections   验证单个示例"
Write-Host "  .\build.ps1 -Clean               清理 build 目录"
