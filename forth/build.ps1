param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# gforth 路径：优先用环境变量 GFORTH，其次用本机 macports 路径，最后退回 PATH
$gforth = $env:GFORTH
if (-not $gforth) { $gforth = "/opt/local/bin/gforth" }
if (-not (Get-Command $gforth -ErrorAction SilentlyContinue)) {
    $gforth = "gforth"
}
if (-not (Get-Command $gforth -ErrorAction SilentlyContinue)) {
    throw "未找到 gforth 可执行文件，请检查安装路径或设置环境变量 GFORTH。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Forth 特有的三条判定标准：退出码 0、stderr 为空、结束时数据栈为空（<0>）
function Invoke-ValidateFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $name = [System.IO.Path]::GetFileName($SourcePath)
    $logPath = Join-Path $buildDir ($name + ".log")
    $errPath = Join-Path $buildDir ($name + ".err")

    Write-Host "[Run] $name" -ForegroundColor Cyan
    & $gforth $SourcePath > $logPath 2> $errPath
    $code = $LASTEXITCODE

    # 注意：Get-Content -Raw 读空文件会返回 $null，必须兜底
    $errText = ""
    if (Test-Path -LiteralPath $errPath) {
        $errText = [string](Get-Content -Raw -LiteralPath $errPath -ErrorAction SilentlyContinue)
    }
    if ($null -eq $errText) { $errText = "" }

    $lines = @()
    if (Test-Path -LiteralPath $logPath) {
        $lines = @(Get-Content -LiteralPath $logPath | Where-Object { $_.Trim() -ne "" })
    }
    $last = ""
    if ($lines.Count -gt 0) { $last = $lines[$lines.Count - 1] }

    $reasons = @()
    if ($code -ne 0) { $reasons += "退出码 $code" }
    if ($errText.Trim() -ne "") { $reasons += "stderr 有输出" }
    if ($last -notlike "*<0>*") { $reasons += "结束时栈非空（$last）" }

    if ($reasons.Count -eq 0) {
        Write-Host "  [OK] $last" -ForegroundColor Green
        return $true
    }

    Write-Host "  [FAIL] $($reasons -join '；')" -ForegroundColor Red
    return $false
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.fs" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .fs 示例文件。"
    }

    $pass = 0
    $fail = 0
    foreach ($f in $files) {
        if (Invoke-ValidateFile -SourcePath $f.FullName) { $pass++ } else { $fail++ }
    }

    Write-Host "--------------------------------" -ForegroundColor DarkGray
    Write-Host "通过 $pass   失败 $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
    if ($fail -ne 0) { exit 1 }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }

    if (-not (Invoke-ValidateFile -SourcePath $sourcePath)) { exit 1 }
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                运行并验证 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name>        运行并验证单个示例（如 04-control-flow.fs）"
Write-Host "  .\build.ps1 -Clean              清理 build 目录"
Write-Host ""
Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 显示完整输出、按编号前缀筛选）。"
