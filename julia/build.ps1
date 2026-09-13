param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$julia = "G:\scoop\apps\julia\current\bin\julia.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $julia)) {
    throw "未找到 julia.exe，请检查 Julia 安装路径。"
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

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-ValidateFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileName($SourcePath)
    Write-Host "[Run] $name" -ForegroundColor Cyan
    & $julia "--startup-file=no" "--history-file=no" $SourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "验证失败: $SourcePath"
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.jl" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .jl 示例文件。"
    }
    foreach ($f in $files) {
        Invoke-ValidateFile -SourcePath $f.FullName
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    Invoke-ValidateFile -SourcePath $sourcePath
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All           运行并验证 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name>   运行并验证单个示例（如 01_hello.jl）"
Write-Host "  .\build.ps1 -Clean         清理 build 目录"

