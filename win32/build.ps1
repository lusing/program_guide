param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$msvcInclude = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\include"
$windowsSdkInclude = "C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0"
$windowsSdkUmInclude = Join-Path $windowsSdkInclude "um"
$windowsSdkSharedInclude = Join-Path $windowsSdkInclude "shared"
$windowsSdkUcrtInclude = Join-Path $windowsSdkInclude "ucrt"

if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "未找到 vcvars64.bat，请检查 VC 安装路径。"
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
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

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-CompileExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $objPath = Join-Path $buildDir ($sourceName + ".obj")
    $exePath = Join-Path $buildDir ($sourceName + ".exe")

    $includeFlags = @(
        "/I`"$msvcInclude`"",
        "/I`"$windowsSdkUmInclude`"",
        "/I`"$windowsSdkSharedInclude`"",
        "/I`"$windowsSdkUcrtInclude`""
    ) -join " "

    $cmd = @(
        'call "{0}" >nul && cl /nologo /std:c++20 /EHsc /DUNICODE /D_UNICODE /utf-8 /c "{1}" /Fo"{2}" {3} && link /nologo /MACHINE:X64 /OUT:"{4}" /SUBSYSTEM:WINDOWS "{5}" user32.lib gdi32.lib kernel32.lib shell32.lib comctl32.lib'
    ) -f $vcvars, $SourcePath, $objPath, $includeFlags, $exePath, $objPath

    Write-Host "[Compile] $([System.IO.Path]::GetFileName($SourcePath))" -ForegroundColor Cyan
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter "*.cpp" | Sort-Object FullName
    foreach ($f in $files) {
        Invoke-CompileExample -SourcePath $f.FullName
    }
    Write-Host "[Done] examples 目录全部编译通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    Invoke-CompileExample -SourcePath $sourcePath
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                编译 examples 下全部示例"
Write-Host "  .\build.ps1 -File <path.cpp>    编译单个示例"
Write-Host "  .\build.ps1 -Clean              清理 build 目录"
