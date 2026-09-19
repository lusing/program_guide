# GNU COBOL 教程统一验证脚本（Windows / pwsh 7），与 run-all.sh 等价：
#   每个示例双通道（check: -Wall / release: -O2）× 四条判定 + 输出逐字节比对
#   四条判定：退出码 0 / stderr 空 / stdout 无控制字符 / 含结束标记 ==== NN 结束 ====
# 用法：
#   pwsh -File build.ps1                 # 全部示例
#   pwsh -File build.ps1 -Example 03     # 单个示例（03 / 03_data 皆可）
#   pwsh -File build.ps1 -Clean          # 清理 build/
#   pwsh -File build.ps1 -Verbose2       # 附带每个示例完整输出
[CmdletBinding()]
param(
    [string]$Example,
    [switch]$Clean,
    [switch]$Verbose2
)

$ErrorActionPreference = 'Stop'
$Root      = $PSScriptRoot
$Examples  = Join-Path $Root 'examples'
$Build     = Join-Path $Root 'build'

# ── 工具链解析：环境变量 COBC → 固定路径 → PATH（固定路径优先，见 README 坑位）──
function Resolve-Cobc {
    if ($env:COBC -and (Test-Path $env:COBC)) { return $env:COBC }
    foreach ($p in @(
        "$env:USERPROFILE\scoop\apps\gnucobol\current\bin\cobc.exe",
        'C:\GnuCOBOL\bin\cobc.exe',
        'C:\Program Files\GnuCOBOL\bin\cobc.exe')) {
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command cobc -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

if ($Clean) {
    if (Test-Path $Build) { Remove-Item -Recurse -Force $Build }
    Write-Host '[Clean] 已清理 build/'
    exit 0
}

$COBC = Resolve-Cobc
if (-not $COBC) { Write-Error '未找到 cobc（可设 COBC=C:\path\to\cobc.exe）'; exit 2 }
if (-not (Test-Path $Examples)) { Write-Error "找不到 examples 目录：$Examples"; exit 2 }

# Windows 上的 GnuCOBOL 自带 MinGW gcc 后端，不会有 macOS clang 的 source-encoding 告警，
# 故无需设置 COB_CFLAGS（macOS 侧的抑制逻辑见 run-all.sh）。

$COB_VER = (& $COBC --version | Select-Object -First 1)
$script:Pass = 0; $script:Fail = 0; $script:Diff = 0; $script:Failed = @()

# 控制台切 65001：保证中文输出按 UTF-8 字节捕获（与 run-all.sh 同款纪律）
try { chcp 65001 > $null } catch {}

function Test-Ctrl([string]$path) {
    # TAB(09)/LF(0A)/CR(0D) 之外的 0x00-0x1F 视为控制字符
    if (-not (Test-Path $path)) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    foreach ($b in $bytes) {
        if ($b -lt 0x20 -and $b -ne 0x09 -and $b -ne 0x0A -and $b -ne 0x0D) { return $true }
    }
    return $false
}

function Check4([string]$tag, [string]$out, [string]$err, [string]$marker, [int]$runrc) {
    $why = ''
    if ($runrc -ne 0) { $why = "运行退出码 $runrc（断言未过）" }
    if ((Test-Path $err) -and ((Get-Item $err).Length -gt 0)) {
        if ($why) { $why += '；' }; $why += 'stderr 非空'
    }
    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 0)) {
        if (Test-Ctrl $out) { if ($why) { $why += '；' }; $why += '输出含控制字符' }
        if (-not (Select-String -Path $out -SimpleMatch -Pattern $marker -Quiet)) {
            if ($why) { $why += '；' }; $why += "缺结束标记 $marker"
        }
    } else {
        if ($why) { $why += '；' }; $why += 'stdout 为空'
    }
    if ($why) {
        $script:Fail++
        $script:Failed += "  - $tag（$why）"
        Write-Host "  [FAIL] $tag —— $why" -ForegroundColor Red
        if ((Test-Path $err) -and ((Get-Item $err).Length -gt 0)) {
            Get-Content $err -TotalCount 5 | ForEach-Object { Write-Host "        stderr: $_" }
        }
    } else {
        $script:Pass++
        Write-Host "  [OK] $tag" -ForegroundColor Green
        if ($Verbose2) { Get-Content $out | ForEach-Object { Write-Host "      | $_" } }
    }
}

function Run-Example([string]$dir) {
    $name   = Split-Path $dir -Leaf
    $num    = ($name -split '[-_]')[0]
    $marker = "==== $num 结束 ===="
    $entry  = Join-Path $dir "$name.cob"
    if (-not (Test-Path $entry)) { Write-Error "$entry 不存在"; exit 2 }

    # 入口 = 与目录同名的 .cob；其余兄弟 .cob 与 .c（C 互操作）一并交给 cobc
    $srcs = @($entry)
    Get-ChildItem -Path $dir -Filter '*.cob' | Where-Object { $_.FullName -ne $entry } |
        ForEach-Object { $srcs += $_.FullName }
    Get-ChildItem -Path $dir -Filter '*.c' -ErrorAction SilentlyContinue |
        ForEach-Object { $srcs += $_.FullName }

    foreach ($channel in @('check', 'release')) {
        $flags = if ($channel -eq 'check') { @('-x', '-Wall', '-std=default') } else { @('-x', '-O2') }
        $outdir = Join-Path $Build $channel
        New-Item -ItemType Directory -Force -Path $outdir > $null
        $exe = Join-Path $outdir "$name.exe"
        if (Test-Path $exe) { Remove-Item -Force $exe }

        Write-Host "[Compile] $channel $name"
        $buildErr = Join-Path $outdir "$name.build.err"
        $buildLog = Join-Path $outdir "$name.build.log"
        # -I $dir：让 COPY 能找到与源文件同目录的 copybook（cobc 默认不搜源文件目录）
        & $COBC @flags -I $dir -o $exe @srcs 1>$buildLog 2>$buildErr
        $rc = $LASTEXITCODE
        if ($rc -ne 0 -or -not (Test-Path $exe)) {
            Write-Host "编译失败 [exit $rc]，见 $buildLog" -ForegroundColor Red
            Get-Content $buildLog, $buildErr -ErrorAction SilentlyContinue | Select-Object -Last 10 |
                ForEach-Object { Write-Host "        $_" }
            $script:Fail++
            $script:Failed += "  - $channel $name（编译失败）"
            continue
        }

        Write-Host "[Run] $channel $name"
        $outFile = Join-Path $outdir "$name.out"
        $errFile = Join-Path $outdir "$name.err"
        # 在 outdir 里运行：文件类示例的相对路径数据文件落在 build\，Clean 一并清掉，
        # 不污染 examples\（否则 rel.dat/idx.dat/seqdemo.txt 会散在源码目录）
        Push-Location $outdir
        & $exe 1>$outFile 2>$errFile
        $runrc = $LASTEXITCODE
        Pop-Location
        # 编译期告警并入运行 stderr 一起判（check 通道开 -Wall，零告警是纪律）
        Add-Content -Path $errFile -Value (Get-Content $buildErr -Raw -ErrorAction SilentlyContinue)
        Check4 "$channel $name" $outFile $errFile $marker $runrc
    }

    $a = Join-Path $Build "check\$name.out"
    $b = Join-Path $Build "release\$name.out"
    if ((Test-Path $a) -and (Test-Path $b) -and ((Get-Item $a).Length -gt 0) -and ((Get-Item $b).Length -gt 0)) {
        $ha = (Get-FileHash $a -Algorithm SHA256).Hash
        $hb = (Get-FileHash $b -Algorithm SHA256).Hash
        if ($ha -eq $hb) { Write-Host '  [same] 双通道输出逐字节一致' }
        else {
            $script:Diff++
            Write-Host "  [DIFF] 双通道输出不一致（见 build\{check,release}\$name.out）" -ForegroundColor Yellow
        }
    }
}

function Find-Dir([string]$want) {
    $direct = Join-Path $Examples $want
    if (Test-Path $direct -PathType Container) { return $direct }
    foreach ($d in Get-ChildItem -Path $Examples -Directory) {
        if ($d.Name -eq $want -or $d.Name -like "${want}_*" -or $d.Name -like "${want}-*") { return $d.FullName }
    }
    return $null
}

Write-Host "工具链：cobc=$COBC"
Write-Host "版本：  $COB_VER"
Write-Host ''

$dirs = @()
if ($Example) {
    $d = Find-Dir $Example
    if (-not $d) { Write-Error "找不到示例: $Example"; exit 2 }
    $dirs = @($d)
} else {
    $dirs = Get-ChildItem -Path $Examples -Directory | Where-Object { $_.Name -match '^[0-9]' } |
            ForEach-Object { $_.FullName }
}

foreach ($d in $dirs) {
    Write-Host "==== $(Split-Path $d -Leaf) ===="
    Run-Example $d
}

Write-Host ''
Write-Host "通过 $($script:Pass)   失败 $($script:Fail)   输出差异 $($script:Diff)"
if ($script:Fail -eq 0) {
    Write-Host '[Done] 全部验证通过。' -ForegroundColor Green
    if ($script:Diff -gt 0) { Write-Host "（有 $($script:Diff) 项双通道输出不同，请人工确认）" }
    exit 0
} else {
    Write-Host '失败项：' -ForegroundColor Red
    $script:Failed | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}
