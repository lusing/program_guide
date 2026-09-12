param(
    [switch]$All,
    [switch]$Test,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$dartExe = $null
$dartCandidates = Get-ChildItem -LiteralPath "G:\scoop\apps\dart" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName "bin\dart.exe" }
foreach ($candidate in $dartCandidates) {
    if (Test-Path -LiteralPath $candidate) {
        $dartExe = $candidate
        break
    }
}
if (-not (Test-Path -LiteralPath $dartExe)) {
    throw "未找到 Dart 可执行文件，请检查 G:\scoop\apps\dart 安装。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

& $dartExe pub get
if ($LASTEXITCODE -ne 0) {
    throw "dart pub get 执行失败。"
}

if ($Test) {
    & $dartExe test
    if ($LASTEXITCODE -ne 0) {
        throw "dart test 执行失败。"
    }
    if (-not $All -and -not $File) {
        Write-Host "[Done] 测试通过。" -ForegroundColor Green
        exit 0
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.dart" | Sort-Object Name
    foreach ($fileInfo in $files) {
        $sourcePath = $fileInfo.FullName
        $outputPath = Join-Path $buildDir ($fileInfo.BaseName + ".exe")
        Write-Host "[Compile] $($fileInfo.Name) -> build/$($fileInfo.BaseName).exe" -ForegroundColor Cyan
        & $dartExe compile exe $sourcePath -o $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "编译失败: $($fileInfo.Name)"
        }
    }
    Write-Host "[Done] 所有示例编译完成。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File)
    $outputPath = Join-Path $buildDir ($baseName + ".exe")
    & $dartExe compile exe $sourcePath -o $outputPath
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $File"
    }
    Write-Host "[Done] 编译成功: build/$baseName.exe" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译 examples 下全部示例"
Write-Host "  .\build.ps1 -File 03_functions.dart 编译单个示例"
Write-Host "  .\build.ps1 -Test                 运行测试"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
