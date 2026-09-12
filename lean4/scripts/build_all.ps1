# ============================================================
# 构建所有示例 - 详细输出版本
# ============================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$modules = @(
    # Lean 4 基础
    "Lean4Tutorial.Examples.Basics.BasicTypes",
    "Lean4Tutorial.Examples.Basics.Functions",
    "Lean4Tutorial.Examples.Basics.Polymorphism",
    "Lean4Tutorial.Examples.Basics.Strings",
    "Lean4Tutorial.Examples.InductiveTypes.Enums",
    "Lean4Tutorial.Examples.InductiveTypes.OptionType",
    "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes",
    "Lean4Tutorial.Examples.InductiveTypes.DependentTypes",
    "Lean4Tutorial.Examples.PatternMatching.MatchBasics",
    "Lean4Tutorial.Examples.PatternMatching.EquationCompiler",
    "Lean4Tutorial.Examples.PatternMatching.ListRecursion",
    "Lean4Tutorial.Examples.PatternMatching.WellFounded",
    "Lean4Tutorial.Examples.PatternMatching.TreeRecursion",
    "Lean4Tutorial.Examples.Typeclasses.TypeclassBasics",
    "Lean4Tutorial.Examples.Typeclasses.OperatorOverloading",
    "Lean4Tutorial.Examples.Typeclasses.TypeclassInheritance",
    "Lean4Tutorial.Examples.Propositions.LogicConnectives",
    "Lean4Tutorial.Examples.Propositions.Quantifiers",
    "Lean4Tutorial.Examples.Propositions.Equality",
    "Lean4Tutorial.Examples.Propositions.CalcProofs",
    "Lean4Tutorial.Examples.Tactics.BasicTactics",
    "Lean4Tutorial.Examples.Tactics.Induction",
    "Lean4Tutorial.Examples.Tactics.Cases",
    "Lean4Tutorial.Examples.Tactics.SimpNormNum",
    "Lean4Tutorial.Examples.Structures.BasicStructures",
    "Lean4Tutorial.Examples.Structures.StructureUpdate",
    "Lean4Tutorial.Examples.Structures.PatternMatchingStruct",
    "Lean4Tutorial.Examples.ModulesProjects.Namespaces",
    "Lean4Tutorial.Examples.ModulesProjects.SectionsVariables",
    # Mathlib4
    "Lean4Tutorial.Examples.MathlibAlgebra.Semigroups",
    "Lean4Tutorial.Examples.MathlibAlgebra.Monoids",
    "Lean4Tutorial.Examples.MathlibAlgebra.Groups",
    "Lean4Tutorial.Examples.MathlibAlgebra.Rings",
    "Lean4Tutorial.Examples.MathlibAlgebra.Fields",
    "Lean4Tutorial.Examples.MathlibNumberTheory.Divisibility",
    "Lean4Tutorial.Examples.MathlibNumberTheory.Gcd",
    "Lean4Tutorial.Examples.MathlibNumberTheory.Primes",
    "Lean4Tutorial.Examples.MathlibNumberTheory.ModEq",
    "Lean4Tutorial.Examples.MathlibNumberTheory.FermatLittle",
    "Lean4Tutorial.Examples.MathlibAnalysis.RealNumbers",
    "Lean4Tutorial.Examples.MathlibAnalysis.AbsoluteValue",
    "Lean4Tutorial.Examples.MathlibAnalysis.Limits",
    "Lean4Tutorial.Examples.MathlibAnalysis.Continuity",
    "Lean4Tutorial.Examples.MathlibAnalysis.Derivatives",
    "Lean4Tutorial.Examples.MathlibTopology.TopologicalSpaces",
    "Lean4Tutorial.Examples.MathlibTopology.MetricSpaces",
    "Lean4Tutorial.Examples.MathlibTopology.Compactness",
    "Lean4Tutorial.Examples.MathlibLinearAlgebra.Modules",
    "Lean4Tutorial.Examples.MathlibLinearAlgebra.LinearMaps",
    "Lean4Tutorial.Examples.MathlibLinearAlgebra.Matrices",
    "Lean4Tutorial.Examples.MathlibLinearAlgebra.Determinant",
    "Lean4Tutorial.Examples.MathlibCombinatorics.Finsets",
    "Lean4Tutorial.Examples.MathlibCombinatorics.BigOperators",
    "Lean4Tutorial.Examples.MathlibCombinatorics.Binomial",
    "Lean4Tutorial.Examples.MathlibCombinatorics.Pigeonhole",
    "Lean4Tutorial.Examples.MathlibMeasureProbability.MeasurableSpaces",
    "Lean4Tutorial.Examples.MathlibMeasureProbability.Measures",
    "Lean4Tutorial.Examples.MathlibMeasureProbability.Probability",
    "Lean4Tutorial.Examples.AdvancedTactics.RingTactic",
    "Lean4Tutorial.Examples.AdvancedTactics.LinarithTactic",
    "Lean4Tutorial.Examples.AdvancedTactics.NormNumTactic",
    "Lean4Tutorial.Examples.AdvancedTactics.AesopTactic",
    "Lean4Tutorial.Examples.AdvancedTactics.OmegaTactic",
    "Lean4Tutorial.Examples.AdvancedTactics.PositivityTactic",
    "Lean4Tutorial.Examples.AdvancedTactics.NlinarithTactic"
)

$total = $modules.Count
$passed = 0
$failed = 0
$failedList = @()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 构建全部 $total 个示例模块" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$i = 0
foreach ($mod in $modules) {
    $i++
    Write-Host "[$i/$total] 构建 $mod ..." -ForegroundColor Yellow -NoNewline

    $output = lake build $mod 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        $failed++
        $failedList += $mod
        Write-Host $output -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 构建结果" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "总计: $total"
Write-Host "通过: $passed" -ForegroundColor Green
Write-Host "失败: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failedList.Count -gt 0) {
    Write-Host ""
    Write-Host "失败模块列表:" -ForegroundColor Red
    foreach ($m in $failedList) {
        Write-Host "  - $m" -ForegroundColor Red
    }
}

Write-Host ""
exit $failed
