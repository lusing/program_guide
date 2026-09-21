param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$gnatmake = "G:\scoop\apps\msys2\current\ucrt64\bin\gnatmake.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$objDir = Join-Path $buildDir "obj"

if (-not (Test-Path -LiteralPath $gnatmake)) {
    throw "未找到 gnatmake.exe，请检查 MSYS2 UCRT64 安装路径。"
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

New-Item -ItemType Directory -Force -Path $objDir | Out-Null

$mainUnits = @(
    "ch02_hello.adb",
    "ch03_types.adb",
    "ch04_control.adb",
    "ch05_subprograms.adb",
    "ch06_arrays.adb",
    "ch07_records.adb",
    "ch08_packages.adb",
    "ch09_exceptions.adb",
    "ch10_generics.adb",
    "ch11_oop.adb",
    "ch12_tasking.adb",
    "ch13_fileio.adb",
    "ch14_c_interop.adb",
    "ch15_containers.adb",
    "ch16_protected.adb",
    "ch17_contracts.adb",
    "ch18_spark.adb"
)

function Invoke-AdaCompile {
    param(
        [Parameter(Mandatory = $true)][string]$SourceFile
    )

    $sourcePath = Join-Path $examplesDir $SourceFile
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    $exeName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile) + ".exe"
    $exePath = Join-Path $buildDir $exeName

    Write-Host "[Compile] $SourceFile" -ForegroundColor Cyan
    Push-Location $buildDir
    try {
        & $gnatmake "-D" $objDir ("-aI" + $examplesDir) ("-aO" + $objDir) "-o" $exePath $sourcePath
    } finally {
        Pop-Location
    }
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $sourcePath"
    }
}

if ($All) {
    foreach ($unit in $mainUnits) {
        Invoke-AdaCompile -SourceFile $unit
    }
    Write-Host "[Done] examples 目录全部编译通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    Invoke-AdaCompile -SourceFile $File
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All              编译 examples 下全部主示例"
Write-Host "  .\build.ps1 -File <name.adb>  编译单个示例（如 ch02_hello.adb）"
Write-Host "  .\build.ps1 -Clean            清理 build 目录"
