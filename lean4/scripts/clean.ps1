# ============================================================
# 清理构建产物
# ============================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "清理构建产物..." -ForegroundColor Yellow
lake clean
Write-Host "清理完成" -ForegroundColor Green
