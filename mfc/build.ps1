param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$msvcRoot = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231"
$windowsSdkRoot = "C:\Program Files (x86)\Windows Kits\10"
$windowsSdkVersion = "10.0.26100.0"

# rc.exe 的 include 搜索路径（afxres.h 在 atlmfc，winres 相关在 SDK）
$rcIncludeFlags = @(
    (Join-Path $msvcRoot "atlmfc\include"),
    (Join-Path $windowsSdkRoot "Include\$windowsSdkVersion\um"),
    (Join-Path $windowsSdkRoot "Include\$windowsSdkVersion\shared")
) | ForEach-Object { "/I`"$_`"" }
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

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

function Build-Example {
    param(
        [Parameter(Mandatory = $true)][string]$ExamplePath
    )

    $name = Split-Path -Leaf $ExamplePath
    $objDir = Join-Path $buildDir "obj\$name"
    New-Item -ItemType Directory -Force -Path $objDir | Out-Null
    $exePath = Join-Path $buildDir ($name + ".exe")

    $cpps = @(Get-ChildItem -LiteralPath $ExamplePath -Filter "*.cpp" | Sort-Object Name)
    $rcs = @(Get-ChildItem -LiteralPath $ExamplePath -Filter "*.rc")

    if ($cpps.Count -eq 0) {
        Write-Host "[Skip] $name (没有 .cpp 文件)" -ForegroundColor Yellow
        return
    }

    Write-Host "[Build] $name" -ForegroundColor Cyan

    $steps = @('call "{0}" >nul' -f $vcvars)

    foreach ($cpp in $cpps) {
        $objPath = Join-Path $objDir ($cpp.BaseName + ".obj")
        $steps += ('cl /nologo /std:c++20 /EHsc /W3 /DUNICODE /D_UNICODE /D_AFXDLL /MD /utf-8 /D_WIN32_WINNT=0x0A00 /c "{0}" /Fo"{1}"' -f $cpp.FullName, $objPath)
    }

    foreach ($rc in $rcs) {
        $resPath = Join-Path $objDir ($rc.BaseName + ".res")
        $steps += ('rc /nologo /c65001 {0} /Fo"{1}" "{2}"' -f ($rcIncludeFlags -join " "), $resPath, $rc.FullName)
    }

    $objList = ($cpps | ForEach-Object { Join-Path $objDir ($_.BaseName + ".obj") }) -join " "
    $resList = ""
    if ($rcs.Count -gt 0) {
        $resList = " " + (($rcs | ForEach-Object { Join-Path $objDir ($_.BaseName + ".res") }) -join " ")
    }
    # Unicode MFC 的入口是 wWinMain（由 mfc140u.dll 提供），必须显式指定
    $steps += ('cl /nologo {0}{1} /Fe"{2}" /link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup' -f $objList, $resList, $exePath)

    $cmd = $steps -join " && "
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "构建失败: $name"
    }
    Write-Host "[OK] $name -> $exePath" -ForegroundColor Green
}

if ($All) {
    $dirs = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    foreach ($d in $dirs) {
        Build-Example -ExamplePath $d.FullName
    }
    Write-Host "[Done] examples 目录全部构建完成。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $target = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $target)) {
        throw "找不到示例目录: $target"
    }
    Build-Example -ExamplePath $target
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All              构建全部示例（编译资源 + 链接 exe）"
Write-Host "  .\build.ps1 -File <示例目录>   构建单个示例"
Write-Host "  .\build.ps1 -Clean            清理 build 目录"
