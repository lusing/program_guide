<#
.SYNOPSIS
    Intel x86-64 汇编编程指南 - MASM 版构建入口
.DESCRIPTION
    把 examples-masm/ 下的 ml64 语法示例「汇编(ml64) -> 链接(link) -> 运行」。
    与 NASM 版 build.ps1 平行：同一批示例的第二套语法镜像（Win64 ABI 不变）。
.EXAMPLE
    .\build-masm.ps1 -All
    .\build-masm.ps1 -Category 01_data_movement
    .\build-masm.ps1 -Clean
#>
param(
    [string]$Category,
    [switch]$All,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot
$buildDir = Join-Path $projectRoot "build-masm"
$examplesDir = Join-Path $projectRoot "examples-masm"

# ---- 定位 MSVC 工具链（与 scripts/common.ps1 相同的探测逻辑）----
function Resolve-VSRoot {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $installs = & $vswhere -all -products * -property installationPath 2>$null
        foreach ($install in $installs) {
            if ($install -and (Test-Path (Join-Path $install "VC\Tools\MSVC"))) {
                return $install.Trim()
            }
        }
    }
    $roots = @("$env:ProgramFiles\Microsoft Visual Studio",
               "${env:ProgramFiles(x86)}\Microsoft Visual Studio",
               "D:\Program Files\Microsoft Visual Studio",
               "G:\Program Files\Microsoft Visual Studio")
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $editions = Get-Child-Item -Path $root -Directory -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending
        foreach ($edition in $editions) {
            if (Test-Path (Join-Path $edition.FullName "VC\Tools\MSVC")) {
                return $edition.FullName
            }
        }
    }
    return $null
}

$vsRoot = Resolve-VSRoot
if (-not $vsRoot) {
    Write-Host "错误: 未找到 Visual Studio 的 VC 工具链。" -ForegroundColor Red
    exit 1
}
$msvcDirs = Get-ChildItem "$vsRoot\VC\Tools\MSVC" -Directory | Sort-Object Name -Descending
$msvcVer  = $msvcDirs[0].Name
$ml64     = "$vsRoot\VC\Tools\MSVC\$msvcVer\bin\Hostx64\x64\ml64.exe"
$linkExe  = "$vsRoot\VC\Tools\MSVC\$msvcVer\bin\Hostx64\x64\link.exe"
$vcLib    = "$vsRoot\VC\Tools\MSVC\$msvcVer\lib\x64"
$winSDK   = "C:\Program Files (x86)\Windows Kits\10"
$sdkDirs  = Get-ChildItem "$winSDK\Lib" -Directory | Where-Object { $_.Name -match '^\d' } | Sort-Object Name -Descending
$sdkVer   = $sdkDirs[0].Name
$ucrtLib  = "$winSDK\Lib\$sdkVer\ucrt\x64"
$umLib    = "$winSDK\Lib\$sdkVer\um\x64"

# Intel MKL（11_calculus_mkl 用，与 scripts/common.ps1 相同的探测顺序）
$mklBase = $null
if ($env:ONEAPI_ROOT -and (Test-Path (Join-Path $env:ONEAPI_ROOT "mkl\latest\lib\mkl_rt.lib"))) {
    $mklBase = Join-Path $env:ONEAPI_ROOT "mkl\latest"
}
if (-not $mklBase) {
    foreach ($c in @("G:\Intel\OneAPI\mkl\latest", "D:\Intel\oneAPI\mkl\latest",
                     "C:\Program Files (x86)\Intel\oneAPI\mkl\latest",
                     "C:\Program Files\Intel\oneAPI\mkl\latest")) {
        if (Test-Path (Join-Path $c "lib\mkl_rt.lib")) { $mklBase = $c; break }
    }
}

function Invoke-BuildMasm {
    param([string]$FilePath)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $obj  = Join-Path $buildDir "$name.obj"
    $exe  = Join-Path $buildDir "$name.exe"

    Write-Host ""
    Write-Host "---------- 构建: $name ----------" -ForegroundColor Cyan

    # 汇编 (ml64)
    $asmOut = & $ml64 /c /nologo /Fo $obj $FilePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [失败] ml64 错误:" -ForegroundColor Red
        $asmOut | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        return $false
    }

    # 链接 (link.exe)
    $linkArgs = @("/nologo", "/subsystem:console", "/entry:main", "/out:$exe",
                  $obj, "ucrt.lib", "msvcrt.lib", "legacy_stdio_definitions.lib", "kernel32.lib",
                  "/libpath:$vcLib", "/libpath:$ucrtLib", "/libpath:$umLib")
    if ($FilePath -match "11_calculus_mkl") {
        if (-not $mklBase) {
            Write-Host "  [失败] 该示例需要 Intel MKL，但未检测到 mkl_rt.lib。" -ForegroundColor Red
            return $false
        }
        $linkArgs += @("mkl_rt.lib", "/libpath:$mklBase\lib", "/LARGEADDRESSAWARE:NO")
        $env:PATH = "$mklBase\bin;" + $env:PATH
        $env:MKL_THREADING_LAYER = "SEQUENTIAL"
    }
    $linkOut = & $linkExe @linkArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [失败] 链接错误:" -ForegroundColor Red
        $linkOut | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        return $false
    }

    # 运行
    $runOut = & $exe 2>&1
    $code = $LASTEXITCODE
    if ($runOut) { $runOut | ForEach-Object { Write-Host $_ } }
    Write-Host "  [完成] $name 运行退出码: $code" -ForegroundColor Green
    return $true
}

if ($Clean) {
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    Write-Host "已清理 build-masm/" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

if ($Category) {
    $files = Get-ChildItem (Join-Path $examplesDir $Category) -Filter *.asm
    $ok = 0; $bad = 0
    foreach ($f in $files) { if (Invoke-BuildMasm $f.FullName) { $ok++ } else { $bad++ } }
    Write-Host "汇总: $ok 成功 / $bad 失败" -ForegroundColor Cyan
} elseif ($All) {
    $files = Get-ChildItem $examplesDir -Recurse -Filter *.asm | Sort-Object FullName
    $ok = 0; $bad = 0
    foreach ($f in $files) { if (Invoke-BuildMasm $f.FullName) { $ok++ } else { $bad++ } }
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  MASM 构建汇总: 总计 $($files.Count) 个, 成功 $ok 个, 失败 $bad 个" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    if ($bad -gt 0) { exit 1 }
} else {
    Write-Host "用法: .\build-masm.ps1 -All | -Category <name> | -Clean" -ForegroundColor Yellow
    Write-Host "示例目录: examples-masm/（与 examples/ 同构的 14 类）"
}
