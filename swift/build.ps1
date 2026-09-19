# Swift 教程统一验证脚本（须 PowerShell 7 / pwsh 运行）
# 四层验证：swift-format lint --strict → swift build --target → swift test --filter → swift run
# 环境配方（实测结论见 docs/superpowers/specs/2026-09-20-swift-tutorial-rewrite-design.md §4）：
#   scoop 的 6.4.0 包缺 Runtimes\usr\bin（运行时 DLL 全无），钉死 6.3.3 完整包；
#   SDKROOT 必须覆盖（scoop 用户级指向 current=6.4.0，不覆盖则 6.3.3/6.4 混编报错）。
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ── 工具链常量（升级时只改这三行 + PATH 前缀）──────────────────────────────
$swiftRoot = "G:\scoop\apps\swift\6.3.3"
$swiftBin = Join-Path $swiftRoot "Toolchains\6.3.3+NoAsserts\usr\bin"
$swiftExe = Join-Path $swiftBin "swift.exe"
if (-not (Test-Path -LiteralPath $swiftExe)) { throw "未找到 swift.exe：$swiftExe" }

$env:SDKROOT = Join-Path $swiftRoot "Platforms\Windows.platform\Developer\SDKs\Windows.sdk"
$env:PATH = (@(
    (Join-Path $swiftRoot "Runtimes\usr\bin"),                          # 运行时 DLL
    $swiftBin,                                                          # 编译器
    (Join-Path $swiftRoot "Toolchains\usr\lib\swift\pm\ManifestAPI")    # 清单 exe 的 PackageDescription.dll
) -join ";") + ";" + $env:PATH

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
& cmd /c "chcp 65001 >nul"

$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath (Join-Path $projectRoot ".build")) {
        Remove-Item -LiteralPath (Join-Path $projectRoot ".build") -Recurse -Force
    }
    Get-ChildItem -LiteralPath $examplesDir -Directory -Filter ".build" -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[Clean] 已清理 .build 目录。" -ForegroundColor Yellow
    exit 0
}

# 章号 → 目标名映射（新增示例章时在此登记）
$targetMap = @{
    "02_hello" = "Ch02Hello"
    "03_basics" = "Ch03Basics"
    "04_control" = "Ch04Control"
    "05_functions" = "Ch05Functions"
}

# 独立包示例（嵌套 Package.swift，不在根包）
$standalone = @("22_spm", "24_minigrep")

function Invoke-Swift {
    param([string[]]$ArgList, [string]$WorkingDir = $projectRoot)
    Push-Location $WorkingDir
    try {
        $lines = & $swiftExe @ArgList 2>&1 | ForEach-Object { "$_" }
        if ($LASTEXITCODE -ne 0) {
            $lines | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            throw "命令失败: swift $($ArgList -join ' ') (cwd=$WorkingDir)"
        }
        return $lines
    } finally { Pop-Location }
}

# 普通示例四层验证：lint --strict → build --target → test --filter → run
function Test-PlainExample {
    param([string]$Name)
    $target = $targetMap[$Name]
    if (-not $target) { throw "目标名未登记：$Name（请在 build.ps1 的 `$targetMap 登记）" }
    $dir = Join-Path $examplesDir $Name
    Write-Host "`n[Example] $Name（四层验证）" -ForegroundColor Cyan

    Write-Host "  [1/4] swift-format lint --strict" -ForegroundColor DarkCyan
    Invoke-Swift @("format", "lint", "--configuration", ".swift-format", "--strict", "--recursive", $dir)

    Write-Host "  [2/4] swift build --target $target" -ForegroundColor DarkCyan
    Invoke-Swift @("build", "--target", $target)

    Write-Host "  [3/4] swift test --filter $target`Tests" -ForegroundColor DarkCyan
    $testOut = Invoke-Swift @("test", "--filter", "$target`Tests")
    # 防假绿：filter 不匹配时 0 用例也算 exit 0，必须确认真的跑到了用例
    $match = ($testOut -join "`n") | Select-String -Pattern "Test run with (\d+) test"
    if (-not $match -or [int]$match.Matches[0].Groups[1].Value -lt 1) {
        throw "测试层未跑到任何用例（filter=$target`Tests 不匹配？）"
    }
    Write-Host "  $($match.Line.Trim())" -ForegroundColor Green

    Write-Host "  [4/4] swift run $target（exit 0 + 结束标记）" -ForegroundColor DarkCyan
    $output = & $swiftExe run $target 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "运行失败(退出码 $LASTEXITCODE)：$target" }
    $text = $output -join "`n"
    $marker = "==== $($Name.Split('_')[0]) 结束 ===="
    if ($text -notmatch [regex]::Escape($marker)) { throw "输出缺少结束标记：$marker" }
    Write-Host "  $marker" -ForegroundColor Green
}

# 独立包示例：cd 子目录 build → test → run（24 有测试，22 无）
function Test-StandaloneExample {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    Write-Host "`n[Example] $Name（独立包）" -ForegroundColor Cyan
    Invoke-Swift @("build") $dir
    if (Test-Path -LiteralPath (Join-Path $dir "Tests")) {
        Invoke-Swift @("test") $dir
    }
    # 运行验证由各独立包自己的约定执行（24 章 minigrep 对 TestFixtures 跑）
    Write-Host "  [OK] $Name 独立包构建/测试通过" -ForegroundColor Green
}

function Test-One {
    param([string]$Name)
    if ($standalone -contains $Name) { Test-StandaloneExample $Name }
    else { Test-PlainExample $Name }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $Example
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name | ForEach-Object {
        Test-One $_.Name
    }
    Write-Host "`n[Done] 全部示例验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                 验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 02_hello    验证单个示例"
Write-Host "  .\build.ps1 -Clean               清理 .build 目录"
