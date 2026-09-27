# OpenCL Windows 教程统一构建脚本
# 用法：pwsh build.ps1 -All          编译并运行全部示例
#       pwsh build.ps1 -Chapter 03   只构建某一章（补零两位，如 03/16/29）
#       pwsh build.ps1 -List         列出全部示例
#       pwsh build.ps1 -Clean        清理 build 目录
# 须 PowerShell 7（pwsh）。示例判定通过 = 退出码 0 且输出含 PASS、不含 FAIL。

param(
    [switch]$All,
    [string]$Chapter,
    [switch]$List,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

# ---------------- 本机工具链路径（按需调整） ----------------
$vcvars   = 'G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat'
$clInclude = 'G:\cuda\v13.3\include'          # CUDA 自带 OpenCL 3.0 头文件
$clLibDir  = 'G:\cuda\v13.3\lib\x64'          # OpenCL.lib（ICD loader 导入库）
$msysClang = 'G:\scoop\apps\msys2\current\ucrt64\bin\clang.exe'  # 16 章 .cl -> SPIR-V

foreach ($p in @($vcvars)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "工具链路径不存在：$p（请编辑脚本顶部变量）" }
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot
$buildDir = Join-Path $projectRoot 'build'
$logDir   = Join-Path $buildDir 'logs'
$examplesDir = Join-Path $projectRoot 'examples'

# 某些示例需要额外链接的库（按章号前缀）
$extraLink = @{
    '29' = 'd3d11.lib dxgi.lib'
}

# ---------------- 工具函数 ----------------

function Get-Targets {
    Get-ChildItem $examplesDir -Directory |
        Where-Object { $_.Name -match '^(\d{2})_' -and $_.Name -ne 'common' } |
        Sort-Object Name
}

function Invoke-CompileOne {
    param([Parameter(Mandatory)][string]$DirName, [Parameter(Mandatory)][string]$SourcePath)

    $num = $DirName.Substring(0, 2)
    $ext = [System.IO.Path]::GetExtension($SourcePath).ToLowerInvariant()
    $outExe = Join-Path $buildDir "$DirName.exe"
    $objOut = Join-Path $buildDir "$DirName.obj"

    if ($ext -eq '.c') {
        $flags = '/TC /utf-8 /DCL_TARGET_OPENCL_VERSION=300 /W3'
        # cl_utils.h 放在 common 下
        $inc = "/I`"$clInclude`" /I`"$examplesDir\common`""
    } else {
        $flags = '/TP /utf-8 /std:c++17 /EHsc /DCL_TARGET_OPENCL_VERSION=300 /W3'
        $inc = "/I`"$clInclude`" /I`"$examplesDir\common`""
    }
    $libs = 'OpenCL.lib'
    if ($extraLink.ContainsKey($num)) { $libs += ' ' + $extraLink[$num] }

    $cmd = 'call "{0}" >nul 2>&1 && cl /nologo {1} {2} /Fo:"{3}" /Fe:"{4}" "{5}" /link /LIBPATH:"{6}" {7}' -f `
        $vcvars, $flags, $inc, $objOut, $outExe, $SourcePath, $clLibDir, $libs
    $compileOut = & $env:ComSpec /c $cmd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host $compileOut -ForegroundColor Red
        throw "编译失败：$DirName"
    }
}

function Invoke-PreSteps {
    param([Parameter(Mandatory)][string]$DirName)

    $num = $DirName.Substring(0, 2)
    if ($num -eq '16') {
        # 16 章：用 MSYS2 clang 把 kernel_spirv.cl 预编译成 SPIR-V（Intel CPU 平台消费）
        $dir = Join-Path $examplesDir $DirName
        $src = Join-Path $dir 'kernel_spirv.cl'
        $dst = Join-Path $dir 'kernel_spirv.spv'
        if (Test-Path -LiteralPath $msysClang) {
            Write-Host "  [pre] clang -> kernel_spirv.spv" -ForegroundColor DarkCyan
            & $msysClang '-cl-std=CL1.2' -target spirv64 -c $src -o $dst
            if ($LASTEXITCODE -ne 0) { throw "16 章 SPIR-V 预编译失败" }
        } else {
            Write-Host "  [pre] 未找到 MSYS2 clang，跳过 SPIR-V 预编译（示例会走 SKIP 分支）" -ForegroundColor DarkYellow
        }
    }
}

function Invoke-RunOne {
    param([Parameter(Mandatory)][string]$DirName)

    $num = $DirName.Substring(0, 2)
    $dir = Join-Path $examplesDir $DirName
    $exe = Join-Path $buildDir "$DirName.exe"
    $logFile = Join-Path $logDir "$DirName.txt"

    # 工作目录设为示例目录：示例内的文件读写一律用相对路径
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $exe
    $psi.WorkingDirectory = $dir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false

    $p = [System.Diagnostics.Process]::new()
    $p.StartInfo = $psi
    [void]$p.Start()
    $tOut = $p.StandardOutput.ReadToEndAsync()
    $tErr = $p.StandardError.ReadToEndAsync()

    if (-not $p.WaitForExit(300000)) {
        try { $p.Kill($true) } catch { $p.Kill() }
        throw "运行超时（300s）：$DirName"
    }
    $out = $tOut.Result
    $err = $tErr.Result
    [System.IO.File]::WriteAllText($logFile, $out + "`n--- stderr ---`n" + $err, [System.Text.Encoding]::UTF8)

    Write-Host $out.TrimEnd() -ForegroundColor Gray
    if ($err.Trim()) { Write-Host "[stderr] $($err.Trim())" -ForegroundColor DarkYellow }

    if ($p.ExitCode -ne 0) { throw "退出码非 0（$($p.ExitCode)）：$DirName" }
    if ($out -notmatch '\bPASS\b') { throw "输出未包含 PASS：$DirName" }
    if ($out -match '(?m)^\s*FAIL') { throw "输出包含 FAIL：$DirName" }
}

function Invoke-BuildChapter {
    param([Parameter(Mandatory)][string]$DirName)

    $dir = Join-Path $examplesDir $DirName
    $main = $null
    foreach ($cand in @('main.c', 'main.cpp')) {
        $p = Join-Path $dir $cand
        if (Test-Path -LiteralPath $p) { $main = $p; break }
    }
    if (-not $main) { throw "示例目录缺少 main.c/main.cpp：$DirName" }

    Write-Host "==== $DirName ====" -ForegroundColor Cyan
    Invoke-PreSteps -DirName $DirName
    Write-Host "  [build] $([System.IO.Path]::GetFileName($main))" -ForegroundColor DarkCyan
    Invoke-CompileOne -DirName $DirName -SourcePath $main
    Invoke-RunOne -DirName $DirName
    Write-Host "==== $DirName ok ====" -ForegroundColor Green
}

# ---------------- 入口 ----------------

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force -Confirm:$false
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在。" -ForegroundColor Yellow
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir, $logDir | Out-Null

$targets = Get-Targets

if ($List) {
    $targets | ForEach-Object { Write-Host $_.Name }
    exit 0
}

if ($Chapter) {
    $norm = $Chapter.PadLeft(2, '0')
    $match = $targets | Where-Object { $_.Name.StartsWith($norm) }
    if (-not $match) { throw "没有章号为 $norm 的示例目录" }
    $match | ForEach-Object { Invoke-BuildChapter $_.Name }
    Write-Host "[Done] 章节 $norm 构建验证完成。" -ForegroundColor Green
    exit 0
}

if ($All) {
    $fail = @()
    foreach ($t in $targets) {
        try {
            Invoke-BuildChapter $t.Name
        } catch {
            Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
            $fail += $t.Name
        }
    }
    if ($fail.Count -gt 0) {
        Write-Host "`n失败示例：$($fail -join ', ')（日志在 build/logs/）" -ForegroundColor Red
        exit 1
    }
    Write-Host "`n[Done] 全部 $($targets.Count) 个示例构建运行通过。" -ForegroundColor Green
    exit 0
}

Write-Host '用法：pwsh build.ps1 -All | -Chapter NN | -List | -Clean' -ForegroundColor Yellow
