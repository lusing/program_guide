param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$juliaExe = "G:\scoop\apps\julia\current\bin\julia.exe"
if (-not (Test-Path -LiteralPath $juliaExe)) { throw "未找到 julia.exe：$juliaExe" }
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

# 运行层附加参数与附加旗标（按示例名特判）
$runArgsMap = @{
    "02_hello" = @("Julia", "1.13")
}
$extraFlagsMap = @{
    "21_threads" = @("-t", "4")
    "24_minigrep" = @("-t", "4")
}

function Invoke-JuliaScript {
    param([string]$Script, [string[]]$ScriptArgs = @(), [string[]]$ExtraFlags = @(), [string]$Project = "")
    $argList = @("--startup-file=no", "--history-file=no", "--check-bounds=yes") + $ExtraFlags
    if ($Project) { $argList += @("--project=$Project") }
    $argList += $Script
    $argList += $ScriptArgs
    $output = & $juliaExe @argList 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    $text = ($output | ForEach-Object { "$_" }) -join "`n"
    Write-Host $text
    if (-not $ok) { throw "命令失败(退出码 $LASTEXITCODE): julia $($argList -join ' ')" }
    return $text
}

# 普通示例三层验证之运行层：跑 main.jl → exit 0 + 结束标记（幂等，因为 -e include 也会触发 @main）
function Test-RunLayer {
    param([string]$Dir, [string]$Name)
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $scriptArgs = if ($runArgsMap.ContainsKey($Name)) { $runArgsMap[$Name] } else { @() }
    $extraFlags = if ($extraFlagsMap.ContainsKey($Name)) { $extraFlagsMap[$Name] } else { @() }
    $text = Invoke-JuliaScript -Script (Join-Path $Dir "main.jl") -ScriptArgs $scriptArgs -ExtraFlags $extraFlags
    $num = ($Name -split "_")[0]
    if ($text -notmatch "==== $num 结束 ====") {
        throw "结束标记缺失: 期望 '==== $num 结束 ====' (stdout 末尾)。检查示例是否完整执行并 flush。"
    }
}

# 测试层：runtests.jl 的 @testset 全过（Test stdlib 失败即 exit 1）
function Test-TestLayer {
    param([string]$Dir, [string]$Name, [string]$Project = "")
    $extraFlags = if ($extraFlagsMap.ContainsKey($Name)) { $extraFlagsMap[$Name] } else { @() }
    Invoke-JuliaScript -Script (Join-Path $Dir "runtests.jl") -ExtraFlags $extraFlags -Project $Project | Out-Null
}

function Test-PlainExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Test-RunLayer -Dir $Dir -Name $name
    Test-TestLayer -Dir $Dir -Name $name
}

# 包工程（17/24）：先 instantiate 环境，再在 --project 下跑 main 与 runtests
function Test-PkgExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    $envDir = Join-Path $Dir "env"
    if (-not (Test-Path -LiteralPath (Join-Path $envDir "Project.toml"))) {
        throw "缺少环境: $envDir\Project.toml"
    }
    Write-Host "`n[Example] $name (Pkg 工程)" -ForegroundColor Cyan
    $extraFlags = if ($extraFlagsMap.ContainsKey($Name)) { $extraFlagsMap[$Name] } else { @() }
    # 第 0 层：离线 instantiate（幂等）
    $output = & $juliaExe --startup-file=no --project=$envDir -e "using Pkg; Pkg.instantiate(); Pkg.status()" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $output | ForEach-Object { Write-Host "$_" }
        throw "instantiate 失败: $name"
    }
    $output | ForEach-Object { Write-Host "$_" }
    # 运行层 + 测试层（在环境内）
    $text = Invoke-JuliaScript -Script (Join-Path $Dir "main.jl") -ExtraFlags $extraFlags -Project $envDir
    $num = ($name -split "_")[0]
    if ($text -notmatch "==== $num 结束 ====") { throw "结束标记缺失: $name" }
    Invoke-JuliaScript -Script (Join-Path $Dir "runtests.jl") -ExtraFlags $extraFlags -Project $envDir | Out-Null
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "17_pkgenv" { Test-PkgExample $Dir }
        "24_minigrep" { Test-PkgExample $Dir }
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
    $dirs = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    if ($dirs.Count -eq 0) { throw "examples 目录下没有示例目录。" }
    foreach ($d in $dirs) { Test-One $d.FullName }
    Write-Host "`n[Done] 全部 $($dirs.Count) 个示例三层验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                 验证 examples 下全部示例（运行层+测试层）"
Write-Host "  .\build.ps1 -Example 09_arrays   验证单个示例"
Write-Host "  .\build.ps1 -Clean               清理 build 目录"
