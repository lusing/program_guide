param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$dmdExe = "G:\scoop\apps\dmd\current\windows\bin64\dmd.exe"
if (-not (Test-Path -LiteralPath $dmdExe)) { throw "未找到 dmd.exe：$dmdExe" }
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Get-ChildItem -LiteralPath $examplesDir -Directory | ForEach-Object {
        Get-ChildItem $_.FullName -Filter "*.obj" -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[Clean] 已清理 build 目录与散落的 .obj。" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Dmd {
    param([string]$WorkingDir, [string[]]$ArgList)
    Push-Location $WorkingDir
    try {
        # 注意：-of/-od 这类"flag+值"参数在 PowerShell 里必须整体加引号传，
        # 否则会被解析器吞掉基名（产出空名 .exe 且静默成功——大坑）
        & $dmdExe @ArgList
        if ($LASTEXITCODE -ne 0) { throw "命令失败: dmd $($ArgList -join ' ') (cwd=$WorkingDir)" }
    } finally { Pop-Location }
}

function Invoke-Native {
    param([string]$ExePath)
    & $ExePath
    if ($LASTEXITCODE -ne 0) { throw "运行失败(退出码 $LASTEXITCODE): $ExePath" }
}

# 普通示例两层验证：
#   1) dmd -w -unittest -run  → 警告当错误 + 跑全部 unittest（注意：此模式不执行 main！）
#   2) dmd -w 编译出 exe 再运行 → 验证 main 路径
function Test-PlainExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Invoke-Dmd $Dir @("-w", "-unittest", "-run", "main.d")
    Invoke-Dmd $Dir @("-w", "main.d", "-of$buildDir\$name.exe", "-od$buildDir")
    # 运行时 Push-Location 到示例目录：18/24 等示例按相对路径读自己的测试数据
    Push-Location $Dir
    try { Invoke-Native (Join-Path $buildDir "$name.exe") }
    finally { Pop-Location }
}

# 22_cinterop：常规两层 + betterC 产物
function Test-CInteropExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name（含 -betterC）" -ForegroundColor Cyan
    Invoke-Dmd $Dir @("-w", "-unittest", "-run", "main.d")
    Invoke-Dmd $Dir @("-w", "main.d", "-of$buildDir\$name.exe", "-od$buildDir")
    Push-Location $Dir
    try {
        Invoke-Native (Join-Path $buildDir "$name.exe")
        Invoke-Dmd $Dir @("-w", "-betterC", "betterc.d", "-of$buildDir\22_betterc.exe")
        Invoke-Native (Join-Path $buildDir "22_betterc.exe")
    } finally { Pop-Location }
}

# DUB 工程（21/24）：dub test + dub build + 运行（产物在工程 bin/ 下）
function Test-DubExample {
    param([string]$Dir, [string]$ExeRelPath)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (DUB 工程)" -ForegroundColor Cyan
    foreach ($sub in @(@("dub", "test"), @("dub", "build"))) {
        Push-Location $Dir
        try {
            & $sub[0] $sub[1]
            if ($LASTEXITCODE -ne 0) { throw "命令失败: $($sub -join ' ') (cwd=$Dir)" }
        } finally { Pop-Location }
    }
    Push-Location $Dir
    try { Invoke-Native (Join-Path $Dir $ExeRelPath) }
    finally { Pop-Location }
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "21_dub"       { Test-DubExample $Dir "bin\dguide_dub.exe" }
        "24_minigrep"  { Test-DubExample $Dir "bin\minigrep.exe" }
        "22_cinterop"  { Test-CInteropExample $Dir }
        default        { Test-PlainExample $Dir }
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
    Write-Host "`n[Done] 全部示例验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 13_ranges    验证单个示例"
Write-Host "  .\build.ps1 -Clean                清理 build 目录与 .obj"
