param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "本脚本为无 BOM UTF-8 源文件，必须用 pwsh 7+ 运行（Windows PowerShell 5.1 会把中文按 ANSI 误读）。"
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$fbcExe = "G:\scoop\apps\freebasic\current\fbc.exe"
if (-not (Test-Path -LiteralPath $fbcExe)) { throw "未找到 fbc.exe：$fbcExe" }

# 控制台统一 UTF-8：PS 自身读子进程输出 + 子进程（fbc 与示例）继承控制台 CP。
# 示例源码全部无 BOM：字面量按字节透传，65001 下中文输出即正确（带 BOM 会走 GBK+宽字符，见 02 章）。
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$null = & cmd /c "chcp 65001 >nul"
if ($LASTEXITCODE -ne 0) { throw "chcp 65001 失败" }

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# 编译：-w all 下要求零诊断（fbc 的警告/错误都走 stderr，成功时静默）
function Invoke-Fbc {
    param([string[]]$ArgList, [string]$Label)
    $diag = (& $fbcExe @ArgList 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw "编译失败($Label)：`n$diag" }
    if ($diag -ne "") { throw "编译器有诊断输出($Label)：`n$diag" }
}

# 运行 + 四条判定：退出码 0 / stderr 空 / stdout 非空 / 含 [OK] 标记
function Invoke-RunJudged {
    param([string]$ExePath, [string]$WorkDir, [string]$Label)
    $so = Join-Path $env:TEMP "fb_out.txt"
    $se = Join-Path $env:TEMP "fb_err.txt"
    Remove-Item $so, $se -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath $ExePath -WorkingDirectory $WorkDir `
        -NoNewWindow -PassThru -RedirectStandardOutput $so -RedirectStandardError $se
    if (-not $p.WaitForExit(60000)) {
        $p.Kill()
        throw "示例超时未退出($Label)：$ExePath"
    }
    $out = ""
    $err = ""
    if (Test-Path $so) { $out = (Get-Content $so -Raw -Encoding UTF8) ?? "" }
    if (Test-Path $se) { $err = (Get-Content $se -Raw -Encoding UTF8) ?? "" }
    if ($p.ExitCode -ne 0) { throw "运行失败($Label)，退出码 $($p.ExitCode)：`n$err" }
    if ($err.Trim().Length -gt 0) { throw "stderr 非空($Label)：`n$err" }
    if ([string]::IsNullOrWhiteSpace($out)) { throw "stdout 为空($Label)" }
    if ($out -notmatch "\[OK\]") { throw "stdout 缺少 [OK] 结束标记($Label)：`n$out" }
    Write-Host "    [$Label] OK" -ForegroundColor Green
}

# 常规示例：双层验证（-exx 断言+边界检查 → 发布形态）
# 源集 = 目录下全部 .bas（排序后第一个为主模块），legacy_qb.bas 除外（属 22 章 qb 通道）
function Test-PlainExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    $sources = Get-ChildItem -LiteralPath $Dir -Filter "*.bas" |
        Where-Object { $_.Name -ne "legacy_qb.bas" } |
        Sort-Object Name | ForEach-Object { $_.FullName }
    if ($sources.Count -eq 0) { throw "示例目录没有 .bas：$Dir" }
    foreach ($layer in @("-exx", "")) {
        $flags = @("-w", "all")
        if ($layer -ne "") { $flags += $layer }
        $exe = Join-Path $buildDir "$name.exe"
        Invoke-Fbc -ArgList ($flags + $sources + @("-x", $exe)) -Label "$name $layer"
        Invoke-RunJudged -ExePath $exe -WorkDir $Dir -Label "$name $layer"
    }
}

# 22_langs：常规双层 + -lang qb 第三通道
function Test-LangsExample {
    param([string]$Dir)
    Test-PlainExample $Dir
    $name = "22_langs"
    $qbSrc = Join-Path $Dir "legacy_qb.bas"
    $exe = Join-Path $buildDir "22_langs_qb.exe"
    Invoke-Fbc -ArgList @("-lang", "qb", "-w", "none", $qbSrc, "-x", $exe) -Label "$name -lang qb"
    Invoke-RunJudged -ExePath $exe -WorkDir $Dir -Label "$name -lang qb"
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "22_langs" { Test-LangsExample $Dir }
        default    { Test-PlainExample $Dir }
    }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $dir
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name | ForEach-Object {
        Test-One $_.FullName
    }
    Write-Host "`n[Done] 全部示例验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                 验证 examples 下全部示例（双层 × 四条判定）"
Write-Host "  .\build.ps1 -Example 18_gfx      验证单个示例"
Write-Host "  .\build.ps1 -Clean               清理 build 目录"
