<#
.SYNOPSIS
    共享构建逻辑（供 build_all.ps1 与 build_category.ps1 复用）
.DESCRIPTION
    定义项目路径常量与单个 .asm 文件的"汇编-链接-运行"流程。
    使用前需 dot-source 本文件。
#>

# 项目根目录（scripts 的上一级）
$script:ProjectRoot  = Split-Path -Parent $PSScriptRoot
$script:BuildDir     = Join-Path $script:ProjectRoot "build"
$script:ExamplesDir  = Join-Path $script:ProjectRoot "examples"

# ----------------------------------------------------------------------------
# MSVC 工具链路径（使用 link.exe 替代 gcc 进行链接）
# ----------------------------------------------------------------------------
$script:VCBasePath = "G:\Program Files\Microsoft Visual Studio\18\Community\VC"
# 自动查找最新 MSVC 版本目录
$msvcVerDirs = Get-ChildItem "$script:VCBasePath\Tools\MSVC" -Directory -ErrorAction SilentlyContinue
if (-not $msvcVerDirs) {
    Write-Host "错误: 未找到 MSVC 工具链目录: $script:VCBasePath\Tools\MSVC" -ForegroundColor Red
    exit 1
}
$script:MSVCVersion = ($msvcVerDirs | Sort-Object Name -Descending | Select-Object -First 1).Name
$script:LinkExe   = "$script:VCBasePath\Tools\MSVC\$script:MSVCVersion\bin\Hostx64\x64\link.exe"
$script:VCLibPath = "$script:VCBasePath\Tools\MSVC\$script:MSVCVersion\lib\x64"

# Windows SDK 路径（ucrt / um 库）
$script:WinSDKBase = "C:\Program Files (x86)\Windows Kits\10"
$sdkVerDirs = Get-ChildItem "$script:WinSDKBase\Lib" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d' }
if (-not $sdkVerDirs) {
    Write-Host "错误: 未找到 Windows SDK Lib 目录: $script:WinSDKBase\Lib" -ForegroundColor Red
    exit 1
}
$script:WinSDKVersion = ($sdkVerDirs | Sort-Object Name -Descending | Select-Object -First 1).Name
$script:UCRTLibPath = "$script:WinSDKBase\Lib\$script:WinSDKVersion\ucrt\x64"
$script:UMLibPath   = "$script:WinSDKBase\Lib\$script:WinSDKVersion\um\x64"

# ----------------------------------------------------------------------------
# Intel MKL 路径 (用于 11_calculus_mkl 类别)
# ----------------------------------------------------------------------------
$script:MKLBasePath = "G:\Intel\OneAPI\mkl\latest"
$script:MKLLibPath  = Join-Path $script:MKLBasePath "lib"
$script:MKLBinPath  = Join-Path $script:MKLBasePath "bin"

# 确保 build 目录存在
function Ensure-BuildDir {
    if (-not (Test-Path $script:BuildDir)) {
        New-Item -ItemType Directory -Force -Path $script:BuildDir | Out-Null
    }
}

<#
.SYNOPSIS
    构建并运行单个 .asm 文件
.OUTPUTS
    $true  表示汇编+链接成功
    $false 表示构建失败
#>
function Invoke-BuildFile {
    param([string]$FilePath)

    $name    = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $objPath = Join-Path $script:BuildDir "$name.obj"
    $exePath = Join-Path $script:BuildDir "$name.exe"

    Write-Host ""
    Write-Host "---------- 构建: $name ----------" -ForegroundColor Cyan

    # 第一步：汇编 (nasm -f win64)
    Write-Host "[1/3] 汇编 (nasm -f win64)..." -ForegroundColor Yellow
    $asmOutput = & nasm -f win64 $FilePath -o $objPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [失败] 汇编错误:" -ForegroundColor Red
        $asmOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        return $false
    }
    Write-Host "  [成功] 生成 $name.obj" -ForegroundColor Green

    # 第二步：链接 (MSVC link.exe)
    Write-Host "[2/3] 链接 (link.exe)..." -ForegroundColor Yellow
    # 检测是否为MKL示例文件，追加MKL库
    $isMKL = $FilePath -match "11_calculus_mkl"
    $linkArgs = @("/nologo", "/subsystem:console", "/entry:main", "/out:$exePath",
                  $objPath, "ucrt.lib", "msvcrt.lib", "legacy_stdio_definitions.lib", "kernel32.lib",
                  "/libpath:$script:VCLibPath", "/libpath:$script:UCRTLibPath", "/libpath:$script:UMLibPath")
    if ($isMKL) {
        $linkArgs += @("mkl_rt.lib", "/libpath:$script:MKLLibPath", "/LARGEADDRESSAWARE:NO")
        Write-Host "  [MKL] 链接 mkl_rt.lib (运行时CPU调度)" -ForegroundColor DarkYellow
    }
    $linkOutput = & $script:LinkExe @linkArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [失败] 链接错误:" -ForegroundColor Red
        $linkOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        return $false
    }
    Write-Host "  [成功] 生成 $name.exe" -ForegroundColor Green

    # 第三步：运行并显示输出（捕获后回显，确保在重定向宿主中也能显示）
    Write-Host "[3/3] 运行..." -ForegroundColor Yellow
    # MKL示例需要将DLL路径加入PATH
    if ($isMKL) {
        $env:PATH = "$script:MKLBinPath;" + $env:PATH
        $env:MKL_THREADING_LAYER = "SEQUENTIAL"
    }
    $runOutput = & $exePath 2>&1
    $runCode = $LASTEXITCODE
    if ($runOutput) {
        $runOutput | ForEach-Object { Write-Host $_ }
    }
    Write-Host "  [完成] $name 运行退出码: $runCode" -ForegroundColor Green

    return $true
}

<#
.SYNOPSIS
    打印构建汇总信息
#>
function Write-BuildSummary {
    param([int]$Total, [int]$Success, [int]$Fail)
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  构建汇总: 总计 $Total 个, 成功 $Success 个, 失败 $Fail 个" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
}
