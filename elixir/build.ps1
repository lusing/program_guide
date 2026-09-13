param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

$elixircCandidates = @(
    "G:\scoop\apps\elixir\current\bin\elixirc.bat",
    "G:\scoop\apps\elixir\current\bin\elixirc"
)

$elixirc = $elixircCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $elixirc) {
    throw "未找到 elixirc，请检查 Elixir 安装路径。"
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

function Invoke-CompileFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    Write-Host "[Compile] $([System.IO.Path]::GetFileName($SourcePath))" -ForegroundColor Cyan
    & $elixirc "--ignore-module-conflict" "-o" $buildDir $SourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.ex" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .ex 示例文件。"
    }

    foreach ($f in $files) {
        Invoke-CompileFile -SourcePath $f.FullName
    }

    Write-Host "[Done] examples 目录全部编译通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    Invoke-CompileFile -SourcePath $sourcePath
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All            编译 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name.ex> 编译单个示例"
Write-Host "  .\build.ps1 -Clean          清理 build 目录"

