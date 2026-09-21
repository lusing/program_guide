param(
    [string]$Name,
    [int]$Seconds = 3
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $buildDir)) {
    throw "找不到 build 目录，请先运行 .\build.ps1 -All"
}

if ($Name) {
    $exes = @(Get-ChildItem -LiteralPath $buildDir -Filter ($Name + "*.exe") | Sort-Object Name)
} else {
    $exes = @(Get-ChildItem -LiteralPath $buildDir -Filter "*.exe" | Sort-Object Name)
}

if ($exes.Count -eq 0) {
    throw "没有找到可冒烟的 exe。"
}

$alive = 0
$failed = 0
foreach ($exe in $exes) {
    try {
        $p = Start-Process -FilePath $exe.FullName -PassThru -ErrorAction Stop
    } catch {
        Write-Host ("[FAIL] {0} 启动失败: {1}" -f $exe.Name, $_.Exception.Message) -ForegroundColor Red
        $failed++
        continue
    }
    Start-Sleep -Seconds $Seconds
    if ($p.HasExited) {
        Write-Host ("[CRASH] {0} 提前退出（退出码 {1}）" -f $exe.Name, $p.ExitCode) -ForegroundColor Red
        $failed++
    } else {
        Write-Host ("[ALIVE] {0}" -f $exe.Name) -ForegroundColor Green
        $alive++
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ("[Done] 存活 {0} / 失败 {1}" -f $alive, $failed) -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
