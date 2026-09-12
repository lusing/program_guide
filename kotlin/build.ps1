param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$kotlinHome = $null
$kotlinCandidates = Get-ChildItem -LiteralPath "G:\scoop\apps\kotlin" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName "bin\kotlinc.bat" }
foreach ($candidate in $kotlinCandidates) {
    if (Test-Path -LiteralPath $candidate) {
        $kotlinHome = Split-Path (Split-Path $candidate -Parent) -Parent
        $kotlinc = $candidate
        break
    }
}
if (-not $kotlinc) {
    throw "未找到 kotlinc.bat，请检查 G:\scoop\apps\kotlin 安装。"
}

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

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

$kotlincJvm = Join-Path $kotlinHome "bin\kotlinc-jvm.bat"
if (-not (Test-Path -LiteralPath $kotlincJvm)) {
    throw "未找到 kotlinc-jvm.bat。"
}

$stdlib = Join-Path $kotlinHome "lib\kotlin-stdlib.jar"
$reflect = Join-Path $kotlinHome "lib\kotlin-reflect.jar"
$coroutines = Join-Path $kotlinHome "lib\kotlinx-coroutines-core-jvm.jar"
$classpath = @($stdlib, $reflect, $coroutines) -join ';'

function Invoke-CompileScript {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $display = $SourcePath.Substring($projectRoot.Length + 1)
    Write-Host "[Compile] $display" -ForegroundColor Cyan
    $outJar = Join-Path $buildDir ([System.IO.Path]::GetFileNameWithoutExtension($SourcePath) + '.jar')
    $argsFile = Join-Path $buildDir ([System.IO.Path]::GetFileNameWithoutExtension($SourcePath) + '.args')
    @(
        '-cp'
        $classpath
        '-include-runtime'
        '-d'
        $outJar
        $SourcePath
    ) | Set-Content -LiteralPath $argsFile -Encoding UTF8
    try {
        & $kotlincJvm "@$argsFile"
        if ($LASTEXITCODE -ne 0) {
            throw "编译失败: $SourcePath"
        }
    }
    finally {
        if (Test-Path -LiteralPath $argsFile) {
            Remove-Item -LiteralPath $argsFile -Force
        }
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter '*.kt' | Sort-Object FullName
    foreach ($fileInfo in $files) {
        Invoke-CompileScript -SourcePath $fileInfo.FullName
    }
    Write-Host "[Done] Kotlin 示例编译验证完成。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    Invoke-CompileScript -SourcePath $sourcePath
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All               编译 examples 下可验证的 Kotlin 示例"
Write-Host "  .\build.ps1 -File <path>       编译单个示例，相对 examples 目录"
Write-Host "  .\build.ps1 -Clean             清理 build 目录"
Write-Host ""
Write-Host "默认跳过 JavaFX 与 Kotlin/JS 章节，因为当前环境未准备对应平台工具链。"
