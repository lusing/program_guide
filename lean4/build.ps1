param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$UpdateDeps,
    [switch]$LegacyAll,
    [switch]$WithMathlib
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$examplesDir = Join-Path $projectRoot "examples"
$validatedDir = Join-Path $examplesDir "00_verified"

$lakeCandidates = @(
    "g:\lean\bin\lake.exe",
    "G:\scoop\apps\elan\current\bin\lake.exe"
)
$lakeFromPath = (Get-Command lake -ErrorAction SilentlyContinue)
if ($lakeFromPath) {
    $lakeCandidates += $lakeFromPath.Source
}

$lake = $lakeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $lake) {
    throw "未找到 lake.exe，请先安装 Lean 工具链（elan/lake）。"
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}
if (-not (Test-Path -LiteralPath $validatedDir)) {
    throw "找不到已验证示例目录: $validatedDir"
}

if ($Clean) {
    Write-Host "[Clean] 执行 lake clean..." -ForegroundColor Yellow
    & $lake clean
    if ($LASTEXITCODE -ne 0) {
        throw "lake clean 执行失败。"
    }
    Write-Host "[Done] 清理完成。" -ForegroundColor Green
    exit 0
}

if ($All) {
    if ($UpdateDeps) {
        Write-Host "[Deps] 更新依赖（mathlib）..." -ForegroundColor Cyan
        & $lake update
        if ($LASTEXITCODE -ne 0) {
            throw "lake update 失败，请检查网络或依赖配置。"
        }
    }

    if ($LegacyAll) {
        # 全量扫描（含历史遗留文件，可能较慢且有失效文件）
        $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.lean" -Recurse -File | Sort-Object FullName
    } else {
        # 默认验证集 = 00_verified + 教程章节同步文件（与教程 docs/ 各章及 lean4-mathlib4-tutorial.md 对应）
        $chapterFiles = @(
            "01_basics\basics.lean",
            "02_inductive_types\universes.lean",
            "02_inductive_types\inductive_types.lean",
            "03_pattern_matching\pattern_matching.lean",
            "04_typeclasses\typeclasses.lean",
            "05_propositions\propositions.lean",
            "06_tactics\tactics.lean",
            "07_structures\structures.lean",
            "08_modules_projects\modules.lean",
            "09_mathlib_algebra\algebra.lean",
            "10_mathlib_number_theory\number_theory.lean",
            "11_mathlib_analysis\analysis.lean",
            "12_mathlib_topology\topology.lean",
            "13_mathlib_linear_algebra\linear_algebra.lean",
            "14_mathlib_combinatorics\combinatorics.lean",
            "15_mathlib_measure_probability\measure_probability.lean",
            "16_advanced_tactics\advanced_tactics.lean",
            "17_workflow\workflow.lean"
        )
        $files = @(Get-ChildItem -LiteralPath $validatedDir -Filter "*.lean" -Recurse -File | Sort-Object FullName)
        if (-not $WithMathlib) {
            # 不含 Mathlib 时：00_verified 跳过 mathlib 文件，章节文件只保留纯 Lean 部分（第 2-10 章）
            $files = @($files | Where-Object { $_.Name -notmatch '^(09|10)_mathlib_' })
            $chapterFiles = $chapterFiles[0..8]
        }
        foreach ($c in $chapterFiles) {
            $p = Join-Path $examplesDir $c
            if (Test-Path -LiteralPath $p) {
                $files += Get-Item -LiteralPath $p
            } else {
                throw "章节示例文件缺失: $c"
            }
        }
    }
    if ($files.Count -eq 0) {
        throw "未找到可校验的 .lean 示例文件。"
    }

    foreach ($f in $files) {
        $rel = $f.FullName
        if ($rel.StartsWith($projectRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $rel = $rel.Substring($projectRoot.Length).TrimStart('\', '/')
        }
        Write-Host "[Check] $rel" -ForegroundColor Cyan
        & $lake env lean $f.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "校验失败: $rel"
        }
    }

    Write-Host "[Done] examples 目录全部校验通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $target = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $target)) {
        throw "找不到示例文件: $target"
    }

    if ($UpdateDeps) {
        Write-Host "[Deps] 更新依赖（mathlib）..." -ForegroundColor Cyan
        & $lake update
        if ($LASTEXITCODE -ne 0) {
            throw "lake update 失败，请检查网络或依赖配置。"
        }
    }

    Write-Host "[Check] $File" -ForegroundColor Cyan
    & $lake env lean $target
    if ($LASTEXITCODE -ne 0) {
        throw "校验失败: $File"
    }

    Write-Host "[Done] 校验通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                校验 00_verified + 教程章节示例（纯 Lean 部分）"
Write-Host "  .\build.ps1 -All -WithMathlib   含 Mathlib 的章节示例也一并校验（需依赖已就绪）"
Write-Host "  .\build.ps1 -All -LegacyAll     扫描 examples 下全部文件（含历史遗留，可能失败）"
Write-Host "  .\build.ps1 -File <path.lean>   校验单个示例（相对 examples）"
Write-Host "  .\build.ps1 -Clean              清理 lake 构建产物"
Write-Host "  .\build.ps1 -All -UpdateDeps    先更新依赖再校验"
