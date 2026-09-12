param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "未找到 vcvars64.bat，请检查 VC 安装路径。"
}

$includeDir = "G:\cuda\v13.3\include"
$libDir = "G:\cuda\v13.3\lib\x64"
$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

$targets = @(
    "OpenCL_历史和版本\002_OpenCL_历史和版本_如何检查_OpenCL_版本.c",
    "第一个_OpenCL_程序\007_第一个_OpenCL_程序_section.c",
    "OpenCL_C++_详细内容\026_OpenCL_C++_详细内容_1._上下文_Context.cpp",
    "OpenCL_C++_完整示例\035_OpenCL_C++_完整示例_section.cpp"
)

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

function Invoke-Compile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $ext = [System.IO.Path]::GetExtension($SourcePath).ToLowerInvariant()
    $base = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $outExe = Join-Path $buildDir ($base + ".exe")
    $objOut = Join-Path $buildDir ($base + ".obj")

    if ($ext -eq '.c') {
        $flags = '/TC /utf-8 /DCL_TARGET_OPENCL_VERSION=120'
    } else {
        $flags = '/TP /utf-8 /std:c++17 /EHsc /DCL_HPP_TARGET_OPENCL_VERSION=120 /DCL_HPP_MINIMUM_OPENCL_VERSION=120 /DCL_TARGET_OPENCL_VERSION=120'
    }

    Write-Host "[Compile] $([System.IO.Path]::GetRelativePath($projectRoot, $SourcePath))" -ForegroundColor Cyan
    $cmd = 'call "{0}" >nul && cl /nologo /I"{1}" /Fo"{2}" /Fe:"{3}" {4} "{5}" /link /LIBPATH:"{6}" OpenCL.lib' -f `
        $vcvars, $includeDir, $objOut, $outExe, $flags, $SourcePath, $libDir
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }
}

if ($All) {
    foreach ($rel in $targets) {
        $source = Join-Path $examplesDir $rel
        Invoke-Compile -SourcePath $source
    }
    Write-Host "[Done] OpenCL 示例编译验证完成。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $source = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $source)) {
        throw "找不到示例文件: $source"
    }
    Invoke-Compile -SourcePath $source
    Write-Host "[Done] 编译通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All             编译可验证的 OpenCL 示例"
Write-Host "  .\build.ps1 -File <path>     编译单个示例，相对 examples 目录"
Write-Host "  .\build.ps1 -Clean           清理 build 目录"
