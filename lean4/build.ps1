# ============================================================
# 构建脚本 - Lean 4 & Mathlib4 教程示例
# ============================================================

param(
    [string]$Target = "all",
    [switch]$Clean = $false
)

# 项目根目录
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Lean 4 & Mathlib4 教程示例 - 构建脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 lean-toolchain
if (Test-Path "lean-toolchain") {
    $toolchain = Get-Content "lean-toolchain" -Raw
    Write-Host "工具链版本: $toolchain" -ForegroundColor Green
} else {
    Write-Host "警告: 未找到 lean-toolchain 文件" -ForegroundColor Yellow
}
Write-Host ""

# 清理
if ($Clean) {
    Write-Host "清理构建产物..." -ForegroundColor Yellow
    lake clean
    Write-Host "清理完成" -ForegroundColor Green
    exit 0
}

# 构建目标
switch ($Target) {
    "all" {
        Write-Host "构建全部示例..." -ForegroundColor Yellow
        Write-Host ""
        lake build
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "构建成功！" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "构建失败，错误码: $LASTEXITCODE" -ForegroundColor Red
        }
    }
    "basics" {
        Write-Host "构建基础类型示例..." -ForegroundColor Yellow
        lake build Lean4Tutorial.Examples.Basics.BasicTypes
        lake build Lean4Tutorial.Examples.Basics.Functions
        lake build Lean4Tutorial.Examples.Basics.Polymorphism
        lake build Lean4Tutorial.Examples.Basics.Strings
        Write-Host "完成" -ForegroundColor Green
    }
    "inductive" {
        Write-Host "构建归纳类型示例..." -ForegroundColor Yellow
        lake build Lean4Tutorial.Examples.InductiveTypes.Enums
        lake build Lean4Tutorial.Examples.InductiveTypes.OptionType
        lake build Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes
        lake build Lean4Tutorial.Examples.InductiveTypes.DependentTypes
        Write-Host "完成" -ForegroundColor Green
    }
    "algebra" {
        Write-Host "构建代数结构示例..." -ForegroundColor Yellow
        lake build Lean4Tutorial.Examples.MathlibAlgebra.Semigroups
        lake build Lean4Tutorial.Examples.MathlibAlgebra.Monoids
        lake build Lean4Tutorial.Examples.MathlibAlgebra.Groups
        lake build Lean4Tutorial.Examples.MathlibAlgebra.Rings
        lake build Lean4Tutorial.Examples.MathlibAlgebra.Fields
        Write-Host "完成" -ForegroundColor Green
    }
    "tactics" {
        Write-Host "构建高级战术示例..." -ForegroundColor Yellow
        lake build Lean4Tutorial.Examples.AdvancedTactics.RingTactic
        lake build Lean4Tutorial.Examples.AdvancedTactics.LinarithTactic
        lake build Lean4Tutorial.Examples.AdvancedTactics.NormNumTactic
        lake build Lean4Tutorial.Examples.AdvancedTactics.AesopTactic
        lake build Lean4Tutorial.Examples.AdvancedTactics.OmegaTactic
        lake build Lean4Tutorial.Examples.AdvancedTactics.PositivityTactic
        lake build Lean4Tutorial.Examples.AdvancedTactics.NlinarithTactic
        Write-Host "完成" -ForegroundColor Green
    }
    default {
        Write-Host "构建指定模块: $Target" -ForegroundColor Yellow
        lake build $Target
        if ($LASTEXITCODE -eq 0) {
            Write-Host "构建成功" -ForegroundColor Green
        } else {
            Write-Host "构建失败" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "使用示例:" -ForegroundColor Cyan
Write-Host "  .\build.ps1                 # 构建全部"
Write-Host "  .\build.ps1 -Target basics  # 构建基础类型"
Write-Host "  .\build.ps1 -Target algebra # 构建代数结构"
Write-Host "  .\build.ps1 -Clean          # 清理构建"
Write-Host "  .\build.ps1 Lean4Tutorial.Examples.Tactics.BasicTactics  # 构建指定模块"
