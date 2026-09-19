# Algol 68 Genie 教程统一验证脚本（Windows / pwsh 7），与 run-all.sh 等价：
#   每个示例双通道 × 四条判定 + 输出逐字节比对
#     check   通道：a68g --warnings --notices  解释器（全运行时检查 + 告警 + notice）
#     release 通道：a68g -O2                   编译到 C 后端（优化，真实出货形态）
#   四条判定：运行退出码 0 / stderr 空 / stdout 无控制字符 / 含结束标记 ==== NN 结束 ====
#   跨通道：check 与 release 两通道 stdout 逐字节一致（解释器与编译后端语义必须吻合）
# 用法：
#   pwsh -File build.ps1                 # 全部示例
#   pwsh -File build.ps1 -Example 03     # 单个示例（03 / 03_modes 皆可）
#   pwsh -File build.ps1 -Clean          # 清理 build/
#   pwsh -File build.ps1 -Verbose2       # 附带每个示例完整输出
#
# 说明：a68g 既是解释器也是编译器——一条命令即「编译（如需）+ 运行」，没有独立的
#   编译步骤；编译期告警与运行期错误都走同一个 stderr，一并判定。
#   macOS 上 a68g -O2 的链接步骤缺 -syslibroot，需要 run-all.sh 里的 ld 垫片修复；
#   Windows 的 a68g 自带后端，不需要垫片，本脚本不涉及。
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

# ── 工具链解析：环境变量 A68G → 固定路径 → PATH ──
function Resolve-A68g {
    if ($env:A68G -and (Test-Path $env:A68G)) { return $env:A68G }
    foreach ($p in @(
        "$env:USERPROFILE\scoop\apps\algol68genie\current\bin\a68g.exe",
        'C:\a68g\bin\a68g.exe',
        'C:\Program Files\a68g\bin\a68g.exe',
        '/opt/local/bin/a68g',
        '/usr/local/bin/a68g',
        '/usr/bin/a68g')) {
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command a68g -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

if ($Clean) {
    if (Test-Path $Build) { Remove-Item -Recurse -Force $Build }
    Write-Host '[Clean] 已清理 build/'
    exit 0
}

$A68G = Resolve-A68g
if (-not $A68G) { Write-Error '未找到 a68g（可设 A68G=C:\path\to\a68g.exe）'; exit 2 }
if (-not (Test-Path $Examples)) { Write-Error "找不到 examples 目录：$Examples"; exit 2 }

$A68_VER = (& $A68G --version 2>$null | Select-Object -First 1)
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
    if ($runrc -ne 0) { $why = "运行退出码 $runrc（运行时错误或断言失败）" }
    if ((Test-Path $err) -and ((Get-Item $err).Length -gt 0)) {
        if ($why) { $why += '；' }; $why += 'stderr 非空（告警/FAIL/运行时错误）'
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
    $entry  = Join-Path $dir "$name.a68"
    if (-not (Test-Path $entry)) { Write-Error "$entry 不存在"; exit 2 }

    foreach ($channel in @('check', 'release')) {
        $flags = if ($channel -eq 'check') { @('--warnings', '--notices') } else { @('-O2') }
        $outdir = Join-Path $Build $channel
        New-Item -ItemType Directory -Force -Path $outdir > $null

        # 幂等：a68g 用 establish 建新文件，若同名数据文件已存在会报 "file exists" 中止，
        # 且 erase 删不掉遗留文件——故每次运行前清掉 outdir 里的数据文件（与 run-all.sh 一致）。
        Get-ChildItem -Path $outdir -Include '*.txt', '*.dat' -File -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue

        $outFile = Join-Path $outdir "$name.out"
        $errFile = Join-Path $outdir "$name.err"

        Write-Host "[Run] $channel $name ($($flags -join ' '))"
        # 在 outdir 里运行：-O2 产物与文件类示例的数据文件都落在 build\，Clean 一并清掉，
        # 不污染 examples\。
        Push-Location $outdir
        & $A68G @flags $entry 1>$outFile 2>$errFile
        $runrc = $LASTEXITCODE
        Pop-Location

        # 清掉 release 通道残留的编译产物，保持 build\ 干净
        foreach ($ext in @('.c', '.o', '.so', '.exe', '.dll', '.a')) {
            $art = Join-Path $outdir "$name$ext"
            if (Test-Path $art) { Remove-Item -Force $art -ErrorAction SilentlyContinue }
        }

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

Write-Host "工具链：a68g=$A68G"
Write-Host "版本：  $A68_VER"
Write-Host ''

$dirs = @()
if ($Example) {
    $d = Find-Dir $Example
    if (-not $d) { Write-Error "找不到示例: $Example"; exit 2 }
    $dirs = @($d)
} else {
    $dirs = Get-ChildItem -Path $Examples -Directory | Where-Object { $_.Name -match '^[0-9]' } |
            Sort-Object Name | ForEach-Object { $_.FullName }
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
