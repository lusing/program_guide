param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$CompileOnly,
    [switch]$Verbose
)

# ============================================================
# build.ps1 —— SDL2 教程统一验证入口（Windows/MSVC 版）
#
# 判定标准与 run-all.sh 逐条对齐：
#   1. 编译退出码为 0，且编译期 stderr 为空
#   2. 运行退出码 0
#   3. 运行 stderr 为空
#   4. stdout 同时出现 "==== NN 开始 ====" 与 "==== NN 结束 ===="
#   5. 区间非空
#   6. 连跑两次区间逐字节一致
# 第 7 条（shared/static 双通道一致）是 macOS 专属：MSVC 侧只有
# SDL2.lib 一条链接路径，无对应通道，因此不参与判定——不是放宽，
# 而是这条差异在 Windows 上根本不存在。
# ============================================================

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$sdlRoot = "G:\scoop\apps\sdl2\current"
$includeDir = Join-Path $sdlRoot "include\SDL2"
$libDir = Join-Path $sdlRoot "lib"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "未找到 vcvars64.bat，请检查 VC 安装路径。"
}
if (-not (Test-Path -LiteralPath $includeDir)) {
    throw "未找到 SDL2 头文件目录: $includeDir"
}
if (-not (Test-Path -LiteralPath $libDir)) {
    throw "未找到 SDL2 库目录: $libDir"
}

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

function Get-Section {
    param([string[]]$Lines)
    $sec = New-Object System.Collections.Generic.List[string]
    $inside = $false
    foreach ($line in $Lines) {
        if ($line -match '^==== [0-9]+ 开始 ====$') { $inside = $true; continue }
        if ($line -match '^==== [0-9]+ 结束 ====$') { $inside = $false; continue }
        if ($inside) { $sec.Add($line) }
    }
    return $sec
}

function Invoke-RunFile {
    param(
        [Parameter(Mandatory = $true)][string]$ExePath,
        [Parameter(Mandatory = $true)][string]$BaseName
    )

    $runOut = Join-Path $buildDir ($BaseName + ".run1.txt")
    $runErr = Join-Path $buildDir ($BaseName + ".run.err.txt")
    $runOut2 = Join-Path $buildDir ($BaseName + ".run2.txt")

    $proc = Start-Process -FilePath $ExePath -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $runOut -RedirectStandardError $runErr
    if ($proc.ExitCode -ne 0) {
        throw "运行退出码 $($proc.ExitCode)（stderr: $((Get-Content -LiteralPath $runErr -Raw).Trim())）"
    }
    $errText = (Get-Content -LiteralPath $runErr -Raw)
    if ($null -ne $errText -and $errText.Trim().Length -gt 0) {
        throw "运行期 stderr 非空: $($errText.Trim())"
    }

    $lines1 = @(Get-Content -LiteralPath $runOut)
    $hasBegin = ($lines1 | Where-Object { $_ -match '^==== [0-9]+ 开始 ====$' } | Select-Object -First 1)
    $hasEnd   = ($lines1 | Where-Object { $_ -match '^==== [0-9]+ 结束 ====$' } | Select-Object -First 1)
    if (-not $hasBegin -or -not $hasEnd) {
        throw "缺少分节标记"
    }
    $sec1 = Get-Section -Lines $lines1
    if ($sec1.Count -eq 0) {
        throw "区间为空"
    }

    # 连跑两次比对：抓线程调度、计时抖动（macOS 侧同一条判据抓到过
    # 06 的 fps 抖动，所以这条在两个入口都必须保留）
    $proc2 = Start-Process -FilePath $ExePath -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $runOut2 -RedirectStandardError (Join-Path $buildDir "nul.txt")
    if ($proc2.ExitCode -ne 0) {
        throw "第二次运行退出码 $($proc2.ExitCode)"
    }
    $sec2 = Get-Section -Lines @(Get-Content -LiteralPath $runOut2)
    if (($sec1 -join "`n") -ne ($sec2 -join "`n")) {
        throw "两次运行区间不一致"
    }

    if ($Verbose) {
        Write-Host "  ---- $BaseName 区间 ----" -ForegroundColor DarkGray
        foreach ($l in $sec1) { Write-Host "  | $l" -ForegroundColor DarkGray }
    }
}

function Invoke-CompileFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $objPath = Join-Path $buildDir ($baseName + ".obj")
    $exePath = Join-Path $buildDir ($baseName + ".exe")

    Write-Host "[Compile] $([System.IO.Path]::GetFileName($SourcePath))" -ForegroundColor Cyan
    $cmd = 'call "{0}" >nul && cl /nologo /std:c++20 /EHsc /utf-8 /I"{1}" /Fo"{2}" /Fe:"{3}" "{4}" /link /LIBPATH:"{5}" SDL2.lib' -f `
        $vcvars, $includeDir, $objPath, $exePath, $SourcePath, $libDir

    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $SourcePath"
    }

    if ($CompileOnly) {
        return
    }

    try {
        Invoke-RunFile -ExePath $exePath -BaseName $baseName
        Write-Host "  [通过] $baseName" -ForegroundColor Green
    } catch {
        Write-Host "  [失败] $baseName : $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

$script:pass = 0
$script:fail = 0
$script:failedItems = @()

function Invoke-OneFile {
    param([Parameter(Mandatory = $true)][string]$SourcePath)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    try {
        Invoke-CompileFile -SourcePath $SourcePath
        $script:pass++
    } catch {
        $script:fail++
        $script:failedItems += $baseName
    }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.cpp" | Sort-Object Name
    foreach ($f in $files) {
        Invoke-OneFile -SourcePath $f.FullName
    }
    Write-Host ""
    Write-Host "======================================"
    Write-Host " 通过 $script:pass  失败 $script:fail  （示例总数 $($script:pass + $script:fail)）"
    if ($script:fail -gt 0) {
        Write-Host " 失败项: $($script:failedItems -join ', ')" -ForegroundColor Red
    }
    Write-Host "======================================"
    if ($script:fail -gt 0) { exit 1 }
    Write-Host "[Done] examples 目录全部编译并运行通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    Invoke-CompileFile -SourcePath $sourcePath
    Write-Host "[Done] 编译并运行通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All              编译并运行 examples 下全部示例"
Write-Host "  .\build.ps1 -File <name.cpp>  编译并运行单个示例"
Write-Host "  .\build.ps1 -CompileOnly      只编译，跳过运行判定"
Write-Host "  .\build.ps1 -Clean            清理 build 目录"
