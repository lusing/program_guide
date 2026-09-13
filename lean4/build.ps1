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

    $scanDir = if ($LegacyAll) { $examplesDir } else { $validatedDir }
    $files = Get-ChildItem -LiteralPath $scanDir -Filter "*.lean" -Recurse -File | Sort-Object FullName
    if (-not $WithMathlib -and -not $LegacyAll) {
        $files = $files | Where-Object { $_.Name -notmatch '^(09|10)_mathlib_' }
    }
    if ($files.Count -eq 0) {
        throw "未找到可校验的 .lean 示例文件。"
    }

    foreach ($f in $files) {
        $rel = [System.IO.Path]::GetRelativePath($projectRoot, $f.FullName)
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
Write-Host "  .\build.ps1 -All                校验 examples\\00_verified 下全部 .lean 示例"
Write-Host "  .\build.ps1 -All -WithMathlib   校验包含 Mathlib 的示例（需依赖已就绪）"
Write-Host "  .\build.ps1 -All -LegacyAll     校验 examples 下全部历史 + 新示例（可能较慢）"
Write-Host "  .\build.ps1 -File <path.lean>   校验单个示例（相对 examples）"
Write-Host "  .\build.ps1 -Clean              清理 lake 构建产物"
Write-Host "  .\build.ps1 -All -UpdateDeps    先更新依赖再校验"
