<#
.SYNOPSIS
    清理构建产物
.DESCRIPTION
    删除 build/ 目录下所有 .obj 和 .exe 文件。
.EXAMPLE
    .\scripts\clean.ps1
#>

# 项目根目录（scripts 的上一级）
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDir    = Join-Path $projectRoot "build"

Write-Host "开始清理构建产物..." -ForegroundColor Cyan

# build 目录不存在则无需清理
if (-not (Test-Path $buildDir)) {
    Write-Host "build 目录不存在，无需清理。" -ForegroundColor Yellow
    return
}

# 收集所有 .obj 和 .exe 文件
$objFiles = @(Get-ChildItem -Path $buildDir -Filter *.obj -File -ErrorAction SilentlyContinue)
$exeFiles = @(Get-ChildItem -Path $buildDir -Filter *.exe -File -ErrorAction SilentlyContinue)
$files    = @($objFiles) + @($exeFiles)

if ($files.Count -eq 0) {
    Write-Host "build 目录中没有需要清理的 .obj / .exe 文件。" -ForegroundColor Yellow
    return
}

# 逐个删除并报告
$removed = 0
foreach ($f in $files) {
    Remove-Item -Path $f.FullName -Force
    Write-Host "  [已删除] $($f.Name)" -ForegroundColor Green
    $removed++
}

Write-Host ""
Write-Host "清理完成: 共删除 $removed 个文件 (.obj + .exe)" -ForegroundColor Cyan
