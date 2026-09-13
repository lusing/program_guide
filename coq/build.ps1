param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$coqc = "G:\scoop\apps\coq\current\bin\coqc.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$buildExamplesDir = Join-Path $buildDir "examples"

if (-not (Test-Path -LiteralPath $coqc)) {
    throw "未找到 coqc.exe，请检查 Coq 安装路径。"
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
    & $coqc "-q" $SourcePath
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
