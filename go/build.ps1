param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$goRoot = "G:\scoop\apps\go\current"
$goExe = Join-Path $goRoot "bin\go.exe"
$gofmtExe = Join-Path $goRoot "bin\gofmt.exe"
if (-not (Test-Path -LiteralPath $goExe)) { throw "未找到 go.exe：$goExe" }
if (-not (Test-Path -LiteralPath $gofmtExe)) { throw "未找到 gofmt.exe：$gofmtExe" }
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Go {
    param([string]$WorkingDir, [string[]]$ArgList)
    Push-Location $WorkingDir
    try {
        & $goExe @ArgList
        if ($LASTEXITCODE -ne 0) { throw "命令失败: go $($ArgList -join ' ') (cwd=$WorkingDir)" }
    } finally { Pop-Location }
}

function Invoke-Native {
    param([string]$ExePath, [string]$WorkingDir, [string[]]$RunArgs = @())
    Push-Location $WorkingDir
    try {
        & $ExePath @RunArgs
        if ($LASTEXITCODE -ne 0) { throw "运行失败(退出码 $LASTEXITCODE): $ExePath $($RunArgs -join ' ')" }
    } finally { Pop-Location }
}

# gofmt -l 列出“待格式化”的文件；gofmt 退出码恒为 0，必须看输出是否为空
function Test-Gofmt {
    param([string]$Dir)
    Push-Location $Dir
    try {
        $pending = & $gofmtExe -l .
        if ($pending) { throw "gofmt 未通过（以下文件需格式化）: $($pending -join ', ')" }
    } finally { Pop-Location }
}

# 普通示例四层验证：gofmt 检查 → vet → test → build 到 build/ 并运行
# Race 开关（16/17/18 并发章）用竞态检测器跑测试（本机有 gcc，可用 cgo）
function Test-PlainExample {
    param([string]$Dir, [switch]$Race)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Test-Gofmt $Dir
    Invoke-Go $Dir @("vet", ".")
    if ($Race) {
        Invoke-Go $Dir @("test", "-race", ".")
    } else {
        Invoke-Go $Dir @("test", ".")
    }
    $exe = Join-Path $buildDir "$name.exe"
    Invoke-Go $Dir @("build", "-o", $exe, ".")
    Invoke-Native $exe $Dir
}

# go.mod 工程（14_module/24_minigrep）：自有 go.mod，多包布局
# 四层：gofmt 检查 → vet ./... → test ./... → build 指定目标并运行
function Test-ProjectExample {
    param([string]$Dir, [string]$BuildTarget, [string[]]$RunArgs = @())
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (go.mod 工程)" -ForegroundColor Cyan
    Test-Gofmt $Dir
    Invoke-Go $Dir @("vet", "./...")
    Invoke-Go $Dir @("test", "./...")
    $exe = Join-Path $buildDir "$name.exe"
    Invoke-Go $Dir (@("build", "-o", $exe) + $BuildTarget)
    Invoke-Native -ExePath $exe -WorkingDir $Dir -RunArgs $RunArgs
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "14_module" { Test-ProjectExample $Dir "./cmd/app" }
        "24_minigrep" { Test-ProjectExample $Dir "." @("func", "main.go") }
        "16_goroutines" { Test-PlainExample $Dir -Race }
        "17_channels" { Test-PlainExample $Dir -Race }
        "18_sync" { Test-PlainExample $Dir -Race }
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
    Write-Host "`n[Done] 全部示例四层验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                    验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 12_collections  验证单个示例"
Write-Host "  .\build.ps1 -Clean                 清理 build 目录"
