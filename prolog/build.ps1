param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$Verbose
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---------------------------------------------------------------
# 工具链定位：环境变量优先，其次 macports 路径，最后退回 PATH
#   SWIPL / GPROLOG / GPLC
# ---------------------------------------------------------------
function Resolve-Tool {
    param([string]$EnvVar, [string]$DefaultPath, [string]$Fallback)

    $candidate = ""
    if ($EnvVar) { $candidate = [Environment]::GetEnvironmentVariable($EnvVar) }
    if (-not $candidate -and (Test-Path -LiteralPath $DefaultPath)) { $candidate = $DefaultPath }
    if (-not $candidate) {
        $cmd = Get-Command $Fallback -ErrorAction SilentlyContinue
        if ($cmd) { $candidate = $cmd.Source }
    }
    if (-not $candidate) { $candidate = $Fallback }
    return $candidate
}

$swipl   = Resolve-Tool "SWIPL"   "/opt/local/bin/swipl"   "swipl"
$gprolog = Resolve-Tool "GPROLOG" "/opt/local/bin/gprolog" "gprolog"
$gplc    = Resolve-Tool "GPLC"    "/opt/local/bin/gplc"    "gplc"

$haveSwipl   = [bool](Get-Command $swipl   -ErrorAction SilentlyContinue)
$haveGprolog = [bool](Get-Command $gprolog -ErrorAction SilentlyContinue)
$haveGplc    = [bool](Get-Command $gplc    -ErrorAction SilentlyContinue)

if (-not $haveSwipl -and -not $haveGprolog) {
    throw "未找到 swipl 或 gprolog，请检查安装路径或设置环境变量 SWIPL / GPROLOG。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"

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

# ---------------------------------------------------------------
# 读文件用的小工具：Get-Content -Raw 读空文件会返回 $null，必须兜底
# ---------------------------------------------------------------
function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $text = [string](Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue)
    if ($null -eq $text) { $text = "" }
    return $text
}

# ---------------------------------------------------------------
# 进程启动助手
#
#   1) 必须重定向 stdin，否则 gprolog 跑完会停在 toplevel 等键盘输入，
#      整个脚本就挂死了（shell 版里是 </dev/null 起的作用）。
#   2) 必须带超时兜底：示例里万一写了无限递归，不至于把 CI 卡死。
# ---------------------------------------------------------------
$stdinFile = Join-Path $buildDir "_empty.stdin"
if (-not (Test-Path -LiteralPath $stdinFile)) {
    Set-Content -LiteralPath $stdinFile -Value "" -Encoding ASCII
}

function Invoke-PrologProc {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [int]$TimeoutMs = 60000
    )

    # 注意：-ArgumentList 不能传空数组，会直接报错，得分两种情况调
    if ($Args.Count -gt 0) {
        $proc = Start-Process -FilePath $Exe -ArgumentList $Args `
                              -RedirectStandardInput $stdinFile `
                              -RedirectStandardOutput $OutFile `
                              -RedirectStandardError $ErrFile `
                              -NoNewWindow -PassThru
    } else {
        $proc = Start-Process -FilePath $Exe `
                              -RedirectStandardInput $stdinFile `
                              -RedirectStandardOutput $OutFile `
                              -RedirectStandardError $ErrFile `
                              -NoNewWindow -PassThru
    }
    if (-not $proc.WaitForExit($TimeoutMs)) {
        $proc.Kill()
        $proc.WaitForExit(5000) | Out-Null
        return @{ ExitCode = 124; TimedOut = $true }
    }
    return @{ ExitCode = $proc.ExitCode; TimedOut = $false }
}

# ---------------------------------------------------------------
# 判定标准（三条通道共用）：
#   1) 退出码为 0
#   2) stderr 为空
#   3) stdout 里出现 "==== NN 结束 ====" 结束标记
#       —— 保证程序真的跑到了最后一行，而不是中途失败被 halt(0) 掩盖
# ---------------------------------------------------------------
function Test-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$Marker,
        [switch]$TimedOut
    )

    $errText = Read-TextFile $ErrPath
    $logText = Read-TextFile $LogPath

    $reasons = @()
    if ($TimedOut) { $reasons += "超过 60 秒未结束（多半是死循环或没 halt）" }
    if ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }
    if ($errText.Trim() -ne "") {
        $first = ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "stderr 有输出：$($first.Trim())"
    }
    if ($logText -notlike "*$Marker*") { $reasons += "stdout 缺少结束标记 $Marker" }

    if ($reasons.Count -eq 0) {
        Write-Host ("  [OK]   {0}" -f $Tag) -ForegroundColor Green
        return $true
    }

    Write-Host ("  [FAIL] {0} —— {1}" -f $Tag, ($reasons -join "；")) -ForegroundColor Red
    return $false
}

# ---------------------------------------------------------------
# 跑一个示例的三条通道
# ---------------------------------------------------------------
function Invoke-Example {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$FileInfo)

    $base   = [System.IO.Path]::GetFileNameWithoutExtension($FileInfo.Name)
    $num    = ($base -split "-")[0]
    $marker = "==== $num 结束 ===="

    Write-Host "==== $base ====" -ForegroundColor Cyan
    $allOk = $true

    # ---- 通道 1：SWI-Prolog 解释执行 ----
    if ($haveSwipl) {
        $log = Join-Path $buildDir "$base.swi.log"
        $err = Join-Path $buildDir "$base.swi.err"
        $r = Invoke-PrologProc -Exe $swipl -Args @("-q", "-f", $FileInfo.FullName, "-g", "main", "-t", "halt") `
                               -OutFile $log -ErrFile $err
        if (-not (Test-Result -Tag "swipl   $base" -LogPath $log -ErrPath $err -ExitCode $r.ExitCode -Marker $marker -TimedOut:$r.TimedOut)) { $allOk = $false }
    }

    # ---- 通道 2：GNU Prolog 解释执行 ----
    if ($haveGprolog) {
        $log = Join-Path $buildDir "$base.gnu.log"
        $err = Join-Path $buildDir "$base.gnu.err"
        $r = Invoke-PrologProc -Exe $gprolog -Args @("--consult-file", $FileInfo.FullName, "--entry-goal", "main") `
                               -OutFile $log -ErrFile $err
        if (-not (Test-Result -Tag "gprolog $base" -LogPath $log -ErrPath $err -ExitCode $r.ExitCode -Marker $marker -TimedOut:$r.TimedOut)) { $allOk = $false }
    }

    # ---- 通道 3：gplc 编译成本地可执行文件再跑 ----
    # gplc 只在当前目录可靠工作，所以先把源码拼一份到 build/ 再编。
    # 拼的时候在头部补一行 :- initialization(main). 让它有入口。
    if ($haveGplc) {
        $combined = Join-Path $buildDir "$base.pl"
        $bin      = Join-Path $buildDir "$base.bin"
        $log      = Join-Path $buildDir "$base.gplc.log"
        $err      = Join-Path $buildDir "$base.gplc.err"
        # 注意：Start-Process 不允许 stdout 和 stderr 重定向到同一个文件
        $buildLog = Join-Path $buildDir "$base.gplc.build"
        $buildErr = Join-Path $buildDir "$base.gplc.builderr"

        $header = ":- initialization(main)."
        $body   = Get-Content -Raw -LiteralPath $FileInfo.FullName
        if ($null -eq $body) { $body = "" }
        Set-Content -LiteralPath $combined -Value ($header + "`n" + $body) -Encoding UTF8

        # gplc 必须在 build 目录里运行
        Push-Location $buildDir
        try {
            $bp = Invoke-PrologProc -Exe $gplc -Args @("$base.pl", "-o", "$base.bin") `
                                    -OutFile $buildLog -ErrFile $buildErr -TimeoutMs 120000
            $buildOk = ($bp.ExitCode -eq 0)
        } finally {
            Pop-Location
        }

        if (-not $buildOk) {
            $msg = (Read-TextFile $buildLog) + (Read-TextFile $buildErr)
            Set-Content -LiteralPath $err -Value $msg -Encoding UTF8
            Write-Host "  [FAIL] gplc    $base —— 编译失败" -ForegroundColor Red
            $first = ($msg -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 2) -join " / "
            if ($first) { Write-Host "         $first" -ForegroundColor Red }
            $allOk = $false
        } else {
            $p = Invoke-PrologProc -Exe $bin -Args @() -OutFile $log -ErrFile $err
            if (-not (Test-Result -Tag "gplc    $base" -LogPath $log -ErrPath $err -ExitCode $p.ExitCode -Marker $marker -TimedOut:$p.TimedOut)) { $allOk = $false }
        }
    }

    if ($Verbose -and (Test-Path -LiteralPath (Join-Path $buildDir "$base.swi.log"))) {
        Get-Content -LiteralPath (Join-Path $buildDir "$base.swi.log") | ForEach-Object { Write-Host "        $_" }
    }

    return $allOk
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.pl" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .pl 示例文件。"
    }

    $pass = 0
    $fail = 0
    $failedList = @()
    foreach ($f in $files) {
        if (Invoke-Example -FileInfo $f) { $pass++ } else { $fail++; $failedList += $f.Name }
    }

    Write-Host "--------------------------------" -ForegroundColor DarkGray
    Write-Host "通过 $pass   失败 $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
    if ($fail -ne 0) {
        Write-Host "失败项：" -ForegroundColor Red
        $failedList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "[Done] 全部示例在三套通道下验证通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $sourcePath = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "找不到示例文件: $sourcePath"
    }
    $item = Get-Item -LiteralPath $sourcePath
    if (-not (Invoke-Example -FileInfo $item)) { exit 1 }
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                运行并验证 examples 下全部示例（三条通道）"
Write-Host "  .\build.ps1 -File <name>        运行并验证单个示例（如 04-arithmetic.pl）"
Write-Host "  .\build.ps1 -All -Verbose       附带打印每个示例的 SWI 输出"
Write-Host "  .\build.ps1 -Clean              清理 build 目录"
Write-Host ""
Write-Host "三条通道：swipl（解释） / gprolog（解释） / gplc（编译成本地可执行文件）"
Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 与按编号筛选）。"
