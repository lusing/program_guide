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

$msvcVersion = (Get-ChildItem -Path 'G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC' -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
$msvcInclude = Join-Path $msvcVersion 'include'

$windowsSdkRoot = 'C:\Program Files (x86)\Windows Kits\10\Include'
$windowsSdkVersion = (Get-ChildItem -Path $windowsSdkRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
$windowsSdkInclude = Join-Path $windowsSdkRoot $windowsSdkVersion
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

    # 输出按示例目录命名（所有示例源文件都叫 main.cpp，用文件名会互相覆盖）
    $sourceName = Split-Path -Leaf (Split-Path -Parent $SourcePath)
    $objPath = Join-Path $buildDir ($sourceName + ".obj")
    $exePath = Join-Path $buildDir ($sourceName + ".exe")

    # 定义 wmain 的示例为控制台程序，用 CONSOLE 子系统；其余为 GUI（wWinMain）
    $sourceContent = Get-Content -LiteralPath $SourcePath -Raw
    if ($sourceContent -match 'int\s+wmain\s*\(') {
        $subsystem = "CONSOLE"
    } else {
        $subsystem = "WINDOWS"
    }

    $includeFlags = @(
        "/I`"$msvcInclude`"",
        "/I`"$windowsSdkUmInclude`"",
        "/I`"$windowsSdkSharedInclude`"",
        "/I`"$windowsSdkUcrtInclude`""
    ) -join " "

    $cmd = @(
        'call "{0}" >nul && cl /nologo /std:c++20 /EHsc /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00 /utf-8 /c "{1}" /Fo"{2}" {3} && link /nologo /MACHINE:X64 /OUT:"{4}" /SUBSYSTEM:{6} "{5}" user32.lib gdi32.lib kernel32.lib shell32.lib comctl32.lib psapi.lib comdlg32.lib dwmapi.lib ole32.lib oleaut32.lib uuid.lib advapi32.lib d2d1.lib dwrite.lib'
    ) -f $vcvars, $SourcePath, $objPath, $includeFlags, $exePath, $objPath, $subsystem

    Write-Host "[Compile] $([System.IO.Path]::GetFileName($SourcePath))" -ForegroundColor Cyan
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

if ($All) {
    # 按示例目录遍历：目录自带 build.ps1（多目标工程）则委托，否则编译单 main.cpp
    $dirs = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    foreach ($d in $dirs) {
        $child = Join-Path $d.FullName "build.ps1"
        $main  = Join-Path $d.FullName "main.cpp"
        if (Test-Path -LiteralPath $child) {
            Write-Host "[Delegate] $($d.Name)" -ForegroundColor Magenta
            & $child
            if ($LASTEXITCODE -ne 0) { throw "委托构建失败: $($d.Name)" }
        } elseif (Test-Path -LiteralPath $main) {
            Invoke-CompileExample -SourcePath $main
        } else {
            throw "示例目录既无 build.ps1 也无 main.cpp: $($d.Name)"
        }
    }
    Write-Host "[Done] examples 目录全部构建通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    $dir = Split-Path -Parent $sourcePath
    $child = Join-Path $dir "build.ps1"
    if (Test-Path -LiteralPath $child) {
        Write-Host "[Delegate] $($dir)" -ForegroundColor Magenta
        & $child
        if ($LASTEXITCODE -ne 0) { throw "委托构建失败: $child" }
    } else {
        Invoke-CompileExample -SourcePath $sourcePath
    }
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                编译 examples 下全部示例"
Write-Host "  .\build.ps1 -File <path.cpp>    编译单个示例"
Write-Host "  .\build.ps1 -Clean              清理 build 目录"
