param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 编译器解析顺序：PATH 中的 rocq -> ROCQ_COQC 环境变量 -> 硬编码 Platform 路径
$coqc = $null
$coqcArgs = @()
$rocqCmd = Get-Command rocq -ErrorAction SilentlyContinue
if ($rocqCmd) {
    $coqc = $rocqCmd.Source
    $coqcArgs = @("compile", "-q")
} elseif ($env:ROCQ_COQC -and (Test-Path -LiteralPath $env:ROCQ_COQC)) {
    $coqc = $env:ROCQ_COQC
    $coqcArgs = @("-q")
} else {
    $coqc = "G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe"
    $coqcArgs = @("-q")
    Write-Host "[提示] PATH 中未找到 rocq，回退到 $coqc，请按你的 Platform 安装路径调整（或把 rocq 加入 PATH / 设置 ROCQ_COQC 环境变量）。" -ForegroundColor Yellow
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$buildExamplesDir = Join-Path $buildDir "examples"

if (-not (Test-Path -LiteralPath $coqc)) {
    throw "未找到编译器 $coqc，请检查 Coq/Rocq 安装路径。"
}

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildExamplesDir | Out-Null
$sourceFiles = Get-ChildItem -Path $examplesDir -Filter "*.v" -File | Sort-Object Name
if ($sourceFiles.Count -eq 0) {
    throw "examples 目录下没有 .v 示例文件。"
}

$compiledFiles = @()
foreach ($src in $sourceFiles) {
    $targetName = "ex_" + $src.Name
    $targetPath = Join-Path $buildExamplesDir $targetName
    Copy-Item -LiteralPath $src.FullName -Destination $targetPath -Force
    $compiledFiles += [PSCustomObject]@{
        OriginalName = $src.Name
        CompiledPath = $targetPath
    }
}

function Invoke-CoqCompile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    Write-Host "[Compile] $([System.IO.Path]::GetFileName($SourcePath))" -ForegroundColor Cyan
    & $coqc @coqcArgs $SourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

if ($All) {
    foreach ($f in $compiledFiles) {
        Invoke-CoqCompile -SourcePath $f.CompiledPath
    }
    Write-Host "[Done] examples 目录全部编译通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $entry = $compiledFiles | Where-Object { $_.OriginalName -eq $File } | Select-Object -First 1
    if (-not $entry) {
        throw "找不到示例文件: $File"
    }
    Invoke-CoqCompile -SourcePath $entry.CompiledPath
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All          编译 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name>  编译单个示例（如 01_basics.v）"
Write-Host "  .\build.ps1 -Clean        清理 build 目录"
