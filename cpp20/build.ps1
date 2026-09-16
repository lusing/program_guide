param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "未找到 vcvars64.bat，请检查 VC 安装路径。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$commonFlags = "/nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4"

function Invoke-Cl {
    param([string[]]$ClArgs)
    $cmd = ('call "{0}" >nul && cl {1}' -f $vcvars, ($ClArgs -join ' '))
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: cl $($ClArgs -join ' ')"
    }
}

function Invoke-Example {
    param([Parameter(Mandatory = $true)][string]$DirPath)

    $name = Split-Path -Leaf $DirPath
    $mainCpp = Join-Path $DirPath "main.cpp"
    if (-not (Test-Path -LiteralPath $mainCpp)) {
        throw "示例缺 main.cpp: $DirPath"
    }

    Write-Host "===== $name =====" -ForegroundColor Magenta

    # 编译 ①：模块接口（.ixx → .obj + .ifc）
    $refArgs = @()     # /reference name=ifc：import 方编译时需要
    $moduleObjs = @()  # 模块目标文件：链接时需要
    $ixxFiles = @(Get-ChildItem -LiteralPath $DirPath -Filter "*.ixx" | Sort-Object Name)
    foreach ($m in $ixxFiles) {
        $module = $m.BaseName
        $obj = Join-Path $buildDir ($name + "_" + $module + ".obj")
        $ifc = [System.IO.Path]::ChangeExtension($obj, ".ifc")
        Write-Host "[Module] $($m.Name)" -ForegroundColor Cyan
        Invoke-Cl @($commonFlags, "/interface", "/c", "/Fo`"$obj`"", "/ifcOutput`"$ifc`"", "`"$($m.FullName)`"")
        # /reference 必须空格分隔："/reference name=file"（冒号形式会触发 C5213 被当作分区）
        $refArgs += "/reference"
        $refArgs += "$module=`"$ifc`""
        $moduleObjs += "`"$obj`""
    }

    # 编译 ②：目录内全部 .cpp（多文件示例逐个编译，支持模块 import）
    Write-Host "[Compile] $name" -ForegroundColor Cyan
    $objs = @()
    $cppFiles = @(Get-ChildItem -LiteralPath $DirPath -Filter "*.cpp" | Sort-Object Name)
    foreach ($c in $cppFiles) {
        $obj = Join-Path $buildDir ($name + "_" + $c.BaseName + ".obj")
        Invoke-Cl (@($commonFlags, "/c", "/Fo`"$obj`"", "`"$($c.FullName)`"") + $refArgs)
        $objs += "`"$obj`""
    }

    # 编译 ③：链接（.cpp 的 obj + 模块的 obj）
    $exe = Join-Path $buildDir ($name + ".exe")
    Invoke-Cl (@($commonFlags, "/Fe`"$exe`"") + $objs + $moduleObjs)

    # 运行：退出码 0 即通过（示例内置 assert 自检）
    Write-Host "[Run] $name" -ForegroundColor Cyan
    & $exe
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败（退出码 $LASTEXITCODE）：$name"
    }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) {
        throw "找不到示例目录: $dir"
    }
    Invoke-Example -DirPath $dir
    Write-Host "[Done] 验证通过: $Example" -ForegroundColor Green
    exit 0
}

if ($All) {
    $dirs = @(Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name)
    if ($dirs.Count -eq 0) {
        throw "examples 目录下没有示例目录。"
    }
    foreach ($d in $dirs) {
        Invoke-Example -DirPath $d.FullName
    }
    Write-Host "[Done] 全部 $($dirs.Count) 个示例编译+运行通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                 全量：逐示例编译（零告警）+ 运行自检"
Write-Host "  .\build.ps1 -Example 06_compound 单示例编译+运行"
Write-Host "  .\build.ps1 -Clean               清理 build 目录"
