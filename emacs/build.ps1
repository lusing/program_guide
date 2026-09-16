<#
.SYNOPSIS
    Emacs Lisp 示例批量验证入口（Windows / PowerShell 版）。
    与 run-all.sh 等价，判定标准完全一致。

.DESCRIPTION
    判定标准（四条，缺一不可）：
      1. 字节编译退出码为 0
      2. 编译时 stderr 为空（字节编译的警告也走 stderr，所以此条等价于「零警告」）
      3. 运行退出码为 0，且运行 stderr 为空
      4. stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外），
         且有结束标记 "==== NN 结束 ===="（NN 与文件名前缀一致）

.EXAMPLE
    .\build.ps1 -All
    验证 examples 下全部示例。

.EXAMPLE
    .\build.ps1 -File 07-lists
    只验证一个示例（可省略 .el）。

.EXAMPLE
    .\build.ps1 -All -Keep
    验证但保留 build 目录里的产物，便于人工检查输出。

.EXAMPLE
    .\build.ps1 -Clean
    清理 build 目录。
#>
param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$Keep,
    [string]$Emacs
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$examplesDir = Join-Path $projectRoot 'examples'
$buildDir    = Join-Path $projectRoot 'build'

# ---------------------------------------------------------------
# 跨平台判定。注意 pwsh 在**所有平台**都有只读自动变量 $IsWindows，
# 而 PowerShell 变量名不区分大小写，所以绝不能自己定义 $isWindows
# （会报 "Cannot overwrite variable IsWindows"）。
# ---------------------------------------------------------------
$onWindows = if (Test-Path Variable:\IsWindows) {
    [bool]$IsWindows
} else {
    $env:OS -eq 'Windows_NT'
}

# ---------------------------------------------------------------
# 找 emacs 可执行文件
# ---------------------------------------------------------------
function Resolve-Emacs {
    param([string]$Explicit)

    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return (Resolve-Path -LiteralPath $Explicit).Path }
        throw "指定的 Emacs 不存在：$Explicit"
    }
    if ($env:EMACS) {
        if (Test-Path -LiteralPath $env:EMACS) { return (Resolve-Path -LiteralPath $env:EMACS).Path }
        throw "环境变量 EMACS 指向的文件不存在：$($env:EMACS)"
    }

    $candidates = @()
    if ($onWindows) {
        $candidates = @(
            "$env:USERPROFILE\scoop\apps\emacs\current\bin\emacs.exe",
            'C:\Program Files\Emacs\bin\emacs.exe',
            'C:\emacs\bin\emacs.exe'
        )
    } else {
        $candidates = @(
            '/opt/local/bin/emacs',
            '/usr/local/bin/emacs',
            '/Applications/Emacs.app/Contents/MacOS/Emacs',
            '/usr/bin/emacs'
        )
    }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }

    # 最后退到 PATH
    $cmdName = if ($onWindows) { 'emacs.exe' } else { 'emacs' }
    $found = Get-Command $cmdName -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }

    throw "找不到 emacs 可执行文件。可用 -Emacs <path> 或环境变量 EMACS 指定。"
}

# ---------------------------------------------------------------
# 用 .NET Process 分别捕获 stdout / stderr。
# 不用 Start-Process：它把 ArgumentList 拼成单个命令行，参数里带空格
# 和引号的 --eval 表达式会被拆坏。
# ---------------------------------------------------------------
function Invoke-EmacsCaptured {
    param(
        [string]$Exe,
        [string[]]$Arguments,
        [string]$OutPath,
        [string]$ErrPath,
        [string]$WorkingDirectory
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Exe
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.CreateNoWindow         = $true
    # 必须和 run-all.sh 一样在 build 目录里跑：示例里的相对路径是按
    # default-directory 解析的（见指南 12.1），工作目录错了结果就不一样。
    if ($WorkingDirectory) { $psi.WorkingDirectory = $WorkingDirectory }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # pwsh 7 / .NET Core：可以逐个传参，不用自己处理引号转义
        foreach ($a in $Arguments) { $psi.ArgumentList.Add($a) }
    } else {
        # Windows PowerShell 5.1 / .NET Framework：只能传一个命令行字符串，
        # 需要按 CommandLineToArgvW 的规则给含空格/引号的参数加引号，
        # 并把参数内部的 " 转义成 \"
        $parts = foreach ($a in $Arguments) {
            if ($a -match '[\s"]') {
                $escaped = $a -replace '(\\*)"', '$1$1\"'
                '"' + $escaped + '"'
            } else {
                $a
            }
        }
        $psi.Arguments = ($parts -join ' ')
    }

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    [System.IO.File]::WriteAllText($OutPath, $stdout, (New-Object System.Text.UTF8Encoding($false)))
    [System.IO.File]::WriteAllText($ErrPath, $stderr, (New-Object System.Text.UTF8Encoding($false)))

    return $proc.ExitCode
}

function Test-FileHasContent {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return (Get-Item -LiteralPath $Path).Length -gt 0
}

# ---------------------------------------------------------------
# 控制字符检查：按**字节**判断，完全不碰正则。
# 0..31 中除 TAB(9) / LF(10) / CR(13) 之外都算脏。
# ---------------------------------------------------------------
function Test-HasControlChar {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    foreach ($b in $bytes) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# 结束标记：只匹配 ASCII 前缀 "==== NN "，避免依赖终端/编码对中文的支持
function Test-MarkerPresent {
    param([string]$Path, [string]$Number)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return $text.Contains("==== $Number ")
}

function Show-FirstLines {
    param([string]$Path, [int]$Count = 12, [string]$Prefix = '      ')
    if (-not (Test-Path -LiteralPath $Path)) { return }
    Get-Content -LiteralPath $Path -TotalCount $Count -Encoding UTF8 |
        ForEach-Object { Write-Host ($Prefix + $_) -ForegroundColor DarkGray }
}

# ---------------------------------------------------------------
# 单个示例的完整验证
# ---------------------------------------------------------------
function Test-EmacsExample {
    param([string]$SourcePath)

    $fileName = [System.IO.Path]::GetFileName($SourcePath)
    $base     = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $nn       = ($base -split '-')[0]

    Write-Host ('{0,-28}' -f $base) -NoNewline

    $copyPath  = Join-Path $buildDir $fileName
    $elcPath   = Join-Path $buildDir ($base + '.elc')
    $outPath   = Join-Path $buildDir ($base + '.out')
    $errPath   = Join-Path $buildDir ($base + '.err')
    $cOutPath  = Join-Path $buildDir ($base + '.compile.out')
    $cErrPath  = Join-Path $buildDir ($base + '.compile.err')

    Copy-Item -LiteralPath $SourcePath -Destination $copyPath -Force

    # --- 1) 字节编译 ---
    $rc = Invoke-EmacsCaptured -Exe $emacs -OutPath $cOutPath -ErrPath $cErrPath `
        -WorkingDirectory $buildDir `
        -Arguments @('-Q', '--batch', '--eval', "(byte-compile-file `"$fileName`")")
    # 上面用的是 PowerShell 双引号串，`" 是转义后的字面引号

    if ($rc -ne 0) {
        Write-Host 'FAIL 编译退出码 ' -NoNewline -ForegroundColor Red
        Write-Host $rc
        Show-FirstLines -Path $cErrPath
        return $false
    }
    if (Test-FileHasContent -Path $cErrPath) {
        Write-Host 'FAIL 编译产生警告（stderr 非空）' -ForegroundColor Red
        Show-FirstLines -Path $cErrPath
        return $false
    }
    if (Test-Path -LiteralPath $elcPath) { Remove-Item -LiteralPath $elcPath -Force }

    # --- 2) 运行 ---
    $rc = Invoke-EmacsCaptured -Exe $emacs -OutPath $outPath -ErrPath $errPath `
        -WorkingDirectory $buildDir `
        -Arguments @('-Q', '--batch', '-l', $fileName)

    if ($rc -ne 0) {
        Write-Host 'FAIL 运行退出码 ' -NoNewline -ForegroundColor Red
        Write-Host $rc
        Show-FirstLines -Path $errPath
        return $false
    }
    if (Test-FileHasContent -Path $errPath) {
        Write-Host 'FAIL 运行 stderr 非空' -ForegroundColor Red
        Show-FirstLines -Path $errPath
        return $false
    }
    if (Test-HasControlChar -Path $outPath) {
        Write-Host 'FAIL 输出含多余控制字符' -ForegroundColor Red
        return $false
    }
    if (-not (Test-MarkerPresent -Path $outPath -Number $nn)) {
        Write-Host "FAIL 缺少结束标记 '==== $nn 结束 ===='" -ForegroundColor Red
        Show-FirstLines -Path $outPath -Count 3 -Prefix '      | '
        return $false
    }

    $lines = @(Get-Content -LiteralPath $outPath -Encoding UTF8).Count
    Write-Host ('OK   ({0} 行输出)' -f $lines) -ForegroundColor Green
    return $true
}

# ---------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已删除 $buildDir" -ForegroundColor Yellow
    } else {
        Write-Host '[Clean] build 目录不存在，无需清理。' -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录：$examplesDir"
}

if (-not $All -and -not $File) {
    Write-Host '用法:' -ForegroundColor Yellow
    Write-Host '  .\build.ps1 -All             验证 examples 下全部示例'
    Write-Host '  .\build.ps1 -File 07-lists   验证单个示例（可省略 .el）'
    Write-Host '  .\build.ps1 -All -Keep       验证并保留 build 产物'
    Write-Host '  .\build.ps1 -Clean           清理 build 目录'
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$emacs = Resolve-Emacs -Explicit $Emacs

if ($All) {
    $targets = Get-ChildItem -LiteralPath $examplesDir -Filter '*.el' |
        Where-Object { $_.Name -match '^\d\d-' } |
        Sort-Object Name
} else {
    $name = if ($File -like '*.el') { $File } else { "$File.el" }
    $targets = @(Get-Item -LiteralPath (Join-Path $examplesDir $name))
}

if ($targets.Count -eq 0) {
    throw 'examples 目录下没有 NN-*.el 示例文件。'
}

Write-Host "Emacs : $emacs"
Write-Host "示例数: $($targets.Count)"
Write-Host ('-' * 60)

$pass = 0
$fail = 0
foreach ($t in $targets) {
    if (Test-EmacsExample -SourcePath $t.FullName) { $pass++ } else { $fail++ }
}

Write-Host ('-' * 60)

if (-not $Keep) {
    Get-ChildItem -LiteralPath $buildDir -File |
        Where-Object { $_.Extension -in @('.out', '.err', '.el', '.elc') } |
        Remove-Item -Force
}

Write-Host ("通过 $pass   失败 $fail")
if ($fail -ne 0) { exit 1 }
exit 0
