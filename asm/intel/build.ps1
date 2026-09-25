<#
.SYNOPSIS
    Intel x86-64 汇编编程指南 - 主入口构建脚本
.DESCRIPTION
    简单封装脚本，根据传入参数调用 scripts 目录下的子脚本。
.PARAMETER Category
    指定要构建的单个类别名称（例如 01_data_movement）。
.PARAMETER All
    构建全部示例。
.PARAMETER Clean
    清理 build 目录下的所有编译产物。
.EXAMPLE
    .\build.ps1 -All
.EXAMPLE
    .\build.ps1 -Category 01_data_movement
.EXAMPLE
    .\build.ps1 -Clean
#>
param(
    [string]$Category,
    [switch]$All,
    [switch]$Clean
)

# 脚本所在目录作为项目根目录
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# scripts 目录下的子脚本路径
$buildAllScript     = Join-Path $projectRoot "scripts\build_all.ps1"
$buildCategoryScript = Join-Path $projectRoot "scripts\build_category.ps1"
$cleanScript        = Join-Path $projectRoot "scripts\clean.ps1"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Intel x86-64 汇编编程指南 - 构建系统" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 根据参数分发到对应子脚本
if ($Clean) {
    Write-Host "[操作] 清理构建产物..." -ForegroundColor Yellow
    & $cleanScript
}
elseif ($All) {
    Write-Host "[操作] 构建全部示例..." -ForegroundColor Yellow
    & $buildAllScript
}
elseif ($Category) {
    Write-Host "[操作] 构建类别: $Category ..." -ForegroundColor Yellow
    & $buildCategoryScript -Category $Category
}
else {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -All                      构建全部示例"
    Write-Host "  .\build.ps1 -Category <name>          构建指定类别"
    Write-Host "  .\build.ps1 -Clean                     清理构建产物"
    Write-Host ""
    Write-Host "可用类别:" -ForegroundColor Yellow
    Write-Host "  01_data_movement, 02_arithmetic, 03_logic_bitwise, 04_comparison,"
    Write-Host "  05_control_flow, 06_string_ops, 07_stack_ops, 08_system_misc,"
    Write-Host "  09_fpu, 10_sse_simd, 11_calculus_mkl, 12_data_repr,"
    Write-Host "  13_exceptions, 14_threads_sync"
    Write-Host ""
    Write-Host "引导链示例（实模式/保护模式/分页/长模式，需 qemu-system-x86_64）:"
    Write-Host "  cd boot; ./build-boot.sh [01|02|03|04|all]"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  构建系统执行完毕" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
