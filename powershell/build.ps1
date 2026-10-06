# build.ps1 — PowerShell 教程验证器（在 pwsh 7 下运行本脚本）
# 用法: pwsh -File build.ps1 [-Only 通配符] [-Engines pwsh,powershell]
# 通道：pwsh = PowerShell 7（主线），powershell = Windows PowerShell 5.1（仅 Windows 有，差异通道）。
#       非 Windows 平台上 5.1 不存在，会自动降级为单引擎并跳过对账（不视为失败）。
[CmdletBinding()]
param(
    [string]$Only = '*',
    [string[]]$Engines = @('pwsh', 'powershell')
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$root = $PSScriptRoot
$examplesRoot = Join-Path $root 'examples'
$reportDir = Join-Path $root 'build/reports'
$logDir = Join-Path $root 'build/logs'
foreach ($d in $reportDir, $logDir) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# 0) BOM 自检：examples/ 与 tools/ 下 .ps1/.psd1/.psm1 必须 UTF-8 BOM（5.1 硬要求），缺则自动补
foreach ($f in Get-ChildItem -Path $examplesRoot, (Join-Path $root 'tools') -Recurse -Include *.ps1, *.psd1, *.psm1 -File -ErrorAction SilentlyContinue) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { continue }
    [System.IO.File]::WriteAllBytes($f.FullName, [byte[]](0xEF, 0xBB, 0xBF) + $bytes)
    Write-Host "BOM fixed: $($f.FullName.Substring($root.Length + 1))"
}

# 1) 解析引擎
# 引擎缺失不是致命错误：Windows PowerShell 5.1 只存在于 Windows，
# macOS/Linux 上只有 pwsh 7。此时降级为单引擎运行并在汇总里明说，
# 而不是 throw——否则 macOS 上整个验证入口直接不可用。
$engineMap = @{}
$missing = @()
foreach ($name in $Engines) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) { $missing += $name; continue }
    $engineMap[$name] = $cmd.Source
}
if ($engineMap.Count -eq 0) {
    throw "引擎全缺：$($Engines -join ', ')。至少需要 pwsh（PowerShell 7）。"
}
if ($missing.Count -gt 0) {
    Write-Host "引擎缺失已跳过：$($missing -join ', ')（该引擎不在本平台存在）" -ForegroundColor Yellow
}
$Engines = @($engineMap.Keys)

# 2) 跑每个示例 × 每个引擎
$dirs = @(if (Test-Path $examplesRoot) { Get-ChildItem $examplesRoot -Directory | Where-Object Name -Like $Only | Sort-Object Name })
$results = [System.Collections.Generic.List[object]]::new()
foreach ($dir in $dirs) {
    $row = [ordered]@{ Example = $dir.Name }
    $reportByEngine = @{}
    foreach ($name in $Engines) {
        $exe = $engineMap[$name]
        $logFile = Join-Path $logDir "$($dir.Name).$name.log"
        # 让子引擎使用自身默认模块搜索路径（父进程 pwsh 的 PSModulePath 会盖掉 5.1 的用户模块目录）
        $savedModulePath = $env:PSModulePath
        Remove-Item Env:\PSModulePath -ErrorAction SilentlyContinue
        & $exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $dir.FullName 'run.ps1') *> $logFile
        $code = $LASTEXITCODE
        if ($null -ne $savedModulePath) { $env:PSModulePath = $savedModulePath }
        $reportFile = Join-Path $dir.FullName 'report.txt'
        $reportText = if (Test-Path $reportFile) { ([System.IO.File]::ReadAllText($reportFile) -replace "`r`n", "`n").Trim() } else { '' }
        # 剥离通道专属行（[ch7-only]/[ch51-only]/[platform]）与环境依赖行（[env]）后存档对账
        $normalized = (@($reportText -split "`n") | Where-Object { $_ -notmatch '\[(ch7-only|ch51-only|platform|env)\]\s*$' }) -join "`n"
        [System.IO.File]::WriteAllText((Join-Path $reportDir "$($dir.Name).$name.txt"), $normalized)
        $hasFail = @(@($reportText -split "`n") | Where-Object { $_ -like 'FAIL:*' }).Count -gt 0
        if ($code -ne 0 -or $hasFail) { $row[$name] = 'FAIL' }
        elseif ($reportText -eq '') { $row[$name] = 'FAIL(no-report)' }
        else { $row[$name] = 'PASS' }
        $reportByEngine[$name] = $normalized
    }
    # 3) 双通道对账（剥离通道专属行后逐字节一致）
    # 注意：单引擎时 Select-Object -Unique 对一个值恒为 1，Diff 会**假装**全 same。
    # 所以只有引擎数 ≥2 时才判 Diff，单引擎显式标 n/a——避免"假绿"。
    $row['Diff'] = if ($Engines.Count -ge 2) {
        if (@($reportByEngine.Values | Select-Object -Unique).Count -eq 1) { 'same' } else { 'DIFF' }
    }
    else { 'n/a(单引擎)' }
    $results.Add([pscustomobject]$row)
}

# 4) 汇总
$results | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
$bad = @($results | Where-Object { @($_.PSObject.Properties | Where-Object { $_.Value -in 'FAIL', 'FAIL(no-report)', 'DIFF' }).Count -gt 0 })
if ($bad.Count -gt 0) { Write-Host "结果: $($bad.Count) 个示例未通过" -ForegroundColor Red; exit 1 }
Write-Host "结果: $($results.Count) 个示例全绿 ($($Engines -join '+'))" -ForegroundColor Green
exit 0
