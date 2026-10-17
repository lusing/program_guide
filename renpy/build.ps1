<#
    一键编译并静态校验 examples/ 下的全部 Ren'Py 示例工程（Windows）。

    注意：本脚本是本书自带的便捷工具，不是 Ren'Py 官方文档里的东西。
    官方对构建的标准入口只有启动器 Build 页与 `renpy.exe launcher distribute`。

    用法:
      .\build.ps1                       编译 + lint 校验 examples 下的全部示例
      .\build.ps1 -Project 02_images_and_stage
                                        只校验单个示例
      .\build.ps1 -CompileOnly          只做编译，不跑 lint
      .\build.ps1 -Clean                清理各示例的编译缓存、存档与运行日志
      .\build.ps1 -RenpyPath "C:\path\to\renpy-8.5.x-sdk\renpy.exe"
                                        显式指定 Ren'Py 可执行文件

    若未指定 -RenpyPath，脚本会依次尝试常见安装位置。
#>
param(
    [switch]$All,
    [string]$Project,
    [switch]$CompileOnly,
    [switch]$Clean,
    [string]$RenpyPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$examplesDir = Join-Path $projectRoot "examples"

function Find-Renpy {
    param([string]$Explicit)

    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return (Resolve-Path -LiteralPath $Explicit).Path }
        throw "指定的 Ren'Py 可执行文件不存在：$Explicit"
    }

    $candidates = @(
        (Join-Path $projectRoot "renpy.exe"),
        (Join-Path $projectRoot "renpy.sh"),
        "$env:USERPROFILE\scoop\apps\renpy\current\renpy.exe",
        "$env:USERPROFILE\renpy-8.5.4-sdk\renpy.exe",
        "C:\renpy\renpy.exe",
        "C:\Program Files\RenPy\renpy.exe"
    )

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path }
    }

    $cmd = Get-Command renpy.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    throw "找不到 Ren'Py SDK。请用 -RenpyPath 指定 renpy.exe 的完整路径。"
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录：$examplesDir"
}

# ------------------------------------------------------------------ 清理模式
function Invoke-Clean {
    $count = 0
    foreach ($entry in Get-ChildItem -LiteralPath $examplesDir -Directory) {
        foreach ($relative in @("game\cache", "game\saves", "log.txt", "errors.txt", "traceback.txt")) {
            $target = Join-Path $entry.FullName $relative
            if (Test-Path -LiteralPath $target) {
                Remove-Item -LiteralPath $target -Recurse -Force
            }
        }
        Get-ChildItem -LiteralPath $entry.FullName -Filter *.rpyc -Recurse |
            Remove-Item -Force
        $count++
    }
    Write-Host "[Clean] 已清理 $count 个示例的 cache / saves / *.rpyc / log.txt。" -ForegroundColor Yellow
}

if ($Clean) {
    Invoke-Clean
    exit 0
}

$renpy = Find-Renpy -Explicit $RenpyPath

# ------------------------------------------------------------ 单个工程校验
function Invoke-VerifyProject {
    param([Parameter(Mandatory = $true)][string]$ExampleDir)

    $exampleName = Split-Path -Leaf $ExampleDir

    Write-Host "[Compile] $exampleName" -ForegroundColor Cyan
    & $renpy $ExampleDir compile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] 编译失败：$exampleName" -ForegroundColor Red
        return $false
    }

    if (-not $CompileOnly) {
        # lint --error-code：发现问题时退出码非 0
        & $renpy $ExampleDir lint --error-code
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[FAIL] lint 未通过：$exampleName" -ForegroundColor Red
            return $false
        }
    }

    Write-Host "[OK] $exampleName" -ForegroundColor Green
    return $true
}

# ---------------------------------------------------------------- 主流程
$total = 0
$failed = 0
$skipped = 0

if ($Project) {
    $exampleDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $exampleDir)) {
        throw "找不到示例工程：$exampleDir"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $exampleDir "game\script.rpy"))) {
        throw "$Project 缺少 game/script.rpy"
    }
    $total = 1
    if (-not (Invoke-VerifyProject -ExampleDir $exampleDir)) { $failed = 1 }
}
else {
    foreach ($entry in Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name) {
        $scriptFile = Join-Path $entry.FullName "game\script.rpy"
        if (-not (Test-Path -LiteralPath $scriptFile)) {
            Write-Host "[Skip] $($entry.Name)：没有 game/script.rpy，跳过" -ForegroundColor DarkGray
            $skipped++
            continue
        }
        $total++
        if (-not (Invoke-VerifyProject -ExampleDir $entry.FullName)) { $failed++ }
    }
}

$note = ""
if ($skipped -gt 0) { $note = "，跳过 $skipped 个空目录" }

Write-Host ""
if ($failed -eq 0) {
    Write-Host "[Done] 全部通过（共 $total 个示例$note）。" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[Done] 有 $failed 个示例未通过，共 $total 个$note。" -ForegroundColor Red
    exit 1
}
