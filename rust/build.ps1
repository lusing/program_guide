param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$rustc = "G:\scoop\apps\rust\current\bin\rustc.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $rustc)) {
    throw "未找到 rustc.exe，请检查 Rust 安装路径。"
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

function Invoke-RustExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $displayName = [System.IO.Path]::GetFileName($SourcePath)
    $outputExe = Join-Path $buildDir ($name + ".exe")

    Write-Host "[Build] $displayName" -ForegroundColor Cyan
    & $rustc "--edition=2021" $SourcePath "-o" $outputExe
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }

    Write-Host "[Run] $displayName" -ForegroundColor DarkCyan
    & $outputExe
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $SourcePath"
    }

    if ($name -eq "19_tests_style") {
        $testExe = Join-Path $buildDir ($name + "_tests.exe")
        Write-Host "[TestBuild] $displayName" -ForegroundColor Magenta
        & $rustc "--edition=2021" "--test" $SourcePath "-o" $testExe
        if ($LASTEXITCODE -ne 0) {
            throw "测试编译失败: $SourcePath"
        }

        Write-Host "[TestRun] $displayName" -ForegroundColor DarkMagenta
        & $testExe "--nocapture"
        if ($LASTEXITCODE -ne 0) {
            throw "测试运行失败: $SourcePath"
        }
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.rs" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .rs 示例文件。"
    }

    foreach ($f in $files) {
        Invoke-RustExample -SourcePath $f.FullName
    }

    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    Invoke-RustExample -SourcePath $sourcePath
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All           编译并运行 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name>   编译并运行单个示例（如 01_hello.rs）"
Write-Host "  .\build.ps1 -Clean         清理 build 目录"

