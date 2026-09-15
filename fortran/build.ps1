param(
    [switch]$All,
    [switch]$Clean,
    [string]$File,
    [switch]$Verbose
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---------------------------------------------------------------
# 工具链定位：环境变量优先，其次 MacPorts 路径，最后退回 PATH
#   FLANG / GFORTRAN
# ---------------------------------------------------------------
function Resolve-Tool {
    param([string]$EnvVar, [string[]]$Candidates)

    $candidate = ""
    if ($EnvVar) { $candidate = [Environment]::GetEnvironmentVariable($EnvVar) }
    if ($candidate -and -not (Test-Path -LiteralPath $candidate)) { $candidate = "" }

    if (-not $candidate) {
        foreach ($c in $Candidates) {
            if (Test-Path -LiteralPath $c) {
                $candidate = $c
                break
            }
        }
    }
    if (-not $candidate) {
        foreach ($c in $Candidates) {
            $cmd = Get-Command $c -ErrorAction SilentlyContinue
            if ($cmd) { $candidate = $cmd.Source; break }
        }
    }
    return $candidate
}

$flang    = Resolve-Tool "FLANG"    @("/opt/local/bin/flang-mp-23", "flang", "flang-new")
$gfortran = Resolve-Tool "GFORTRAN" @("/opt/local/bin/gfortran-mp-15", "gfortran")

# Windows 上 LLVM 版 flang 的运行时库引用了 128 位转换例程（__floattidf 等），
# 链接时必须补上 compiler-rt builtins。这个文件只在 Windows 的 LLVM 发行版里
# 存在，macOS/Linux 探测不到就自动跳过。
$flangRtLib = ""
if ($flang) {
    $flangDir = Split-Path -Parent $flang
    $hit = Get-ChildItem -Path (Join-Path $flangDir "..\lib\clang\*\lib\windows\clang_rt.builtins-x86_64.lib") `
                        -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $flangRtLib = $hit.FullName }
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

if (-not $flang)    { Write-Host "未找到 flang（可设 FLANG=/path/to/flang）" -ForegroundColor Yellow }
if (-not $gfortran) { Write-Host "未找到 gfortran（可设 GFORTRAN=/path/to/gfortran）" -ForegroundColor Yellow }
if (-not $flang -and -not $gfortran) { throw "两个编译器都没有，无法继续。" }

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
foreach ($ch in @("flang", "gfortran")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "mod/$ch") | Out-Null
}

Write-Host ("flang    : {0}" -f $(if ($flang) { $flang } else { "<缺失>" }))
Write-Host ("gfortran : {0}" -f $(if ($gfortran) { $gfortran } else { "<缺失>" }))
Write-Host ""

# ---------------------------------------------------------------
# 已知的跨编译器差异（原因写清楚，免得后人以为是回归）
# ---------------------------------------------------------------
function Get-DiffReason {
    param([string]$Base)
    switch ($Base) {
        "02-kinds"         { return "flang 23 无四倍精度（real128 = -1），gfortran 有" }
        "08-formatted-io"  { return "namelist 写出的排版由编译器决定" }
        "09-files"         { return "flang 的 Windows 运行时 inquire(size=) 恒为 -1 且 close(status='delete') 失效" }
        "15-algorithms"    { return "洗牌用了 random_number，两个发生器不同" }
        "16-numeric"       { return "Richardson 外推的末位浮点差异（FMA 收缩与否随编译器/平台不同）" }
        "17-random"        { return "随机数发生器与种子长度都不同" }
        "20-parallel"      { return "含墙钟计时，线程调度也不保证一致" }
        "21-errors-testing" { return "flang 的 Windows 运行时 inquire(size=) 恒为 -1" }
        default            { return "" }
    }
}

# 读文件用的小工具：Get-Content -Raw 读空文件会返回 $null，必须兜底
function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $text = [string](Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue)
    if ($null -eq $text) { $text = "" }
    return $text
}

# ---------------------------------------------------------------
# 进程启动助手：重定向三个流，并带超时兜底
# ---------------------------------------------------------------
function Invoke-Proc {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkDir = $projectRoot,
        [int]$TimeoutMs = 120000
    )

    # 注意：-ArgumentList 不能传空数组，会直接报错，得分两种情况调
    if ($Args.Count -gt 0) {
        $proc = Start-Process -FilePath $Exe -ArgumentList $Args `
                              -WorkingDirectory $WorkDir `
                              -RedirectStandardOutput $OutFile `
                              -RedirectStandardError $ErrFile `
                              -NoNewWindow -PassThru
    } else {
        $proc = Start-Process -FilePath $Exe `
                              -WorkingDirectory $WorkDir `
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

# 输出里是否混进了「不该出现」的控制字符（制表符、换行、回车除外）。
# 出现这种情况几乎只有一个原因：写语句的格式描述符个数少于数据项个数，
# 触发了「格式重现」——多出来的整数被 (a) 描述符当成字符，原始字节直接落盘。
# 正整数的低字节后面通常跟着三个 NUL，所以最常见的表现就是 NUL 字节。
function Test-HasCtrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------
# 判定标准（两条通道共用）：
#   1) 退出码为 0
#   2) stderr 为空
#   3) stdout 里没有多余控制字符
#      —— 格式描述符写少了会触发格式重现，把整数原始字节吐进 stdout
#   4) stdout 里出现 "==== NN 结束 ====" 结束标记
#      —— 保证程序真的跑到了最后一行
# ---------------------------------------------------------------
function Test-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$BuildLog,
        [switch]$TimedOut
    )

    $errText = Read-TextFile $ErrPath
    $logText = Read-TextFile $OutPath
    $bldText = Read-TextFile $BuildLog

    $reasons = @()
    if ($TimedOut) { $reasons += "超过 120 秒未结束（多半是死循环）" }
    if ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }
    if ($errText.Trim() -ne "") {
        $first = ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "stderr 有输出：$($first.Trim())"
    }
    if (Test-HasCtrl $OutPath) {
        $reasons += "stdout 含多余控制字符：格式描述符少于数据项，触发了格式重现"
    }
    # 找结束标记时先把控制字符（含 NUL）去掉，免得二进制内容干扰匹配。
    # 用 \xNN 写正则，别用 PowerShell 的反引号转义——"`10" 会被拆成 "1"+"0"，
    # 拼出来的字符类会把等号一起吃掉，标记就永远找不到了。
    $logClean = [regex]::Replace($logText, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
    if ($logClean -notlike "*$Marker*") {
        $reasons += "stdout 缺少结束标记 $Marker"
    }
    if ($bldText.Trim() -ne "") {
        $first = ($bldText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "编译/链接有输出：$($first.Trim())"
    }

    if ($reasons.Count -eq 0) {
        Write-Host ("  [OK]   {0}" -f $Tag) -ForegroundColor Green
        return $true
    }

    Write-Host ("  [FAIL] {0} —— {1}" -f $Tag, ($reasons -join "；")) -ForegroundColor Red
    return $false
}

# ---------------------------------------------------------------
# 跑一个示例的两个通道 + 输出一致性比对
# ---------------------------------------------------------------
function Invoke-Example {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$FileInfo)

    $base   = [System.IO.Path]::GetFileNameWithoutExtension($FileInfo.Name)
    $num    = ($base -split "-")[0]
    $marker = "==== $num 结束 ===="

    Write-Host "==== $base ====" -ForegroundColor Cyan
    $allOk = $true

    # 用到 OpenMP 的示例自动补 -fopenmp
    $srcText = Read-TextFile $FileInfo.FullName
    $needOpenMP = $srcText.Contains('!$omp')
    # .f 是固定格式的老代码；.f90 才是现代自由格式。老代码不开 -pedantic：
    # 老特性本来就是标准的「已删/已过时」集合，用现代标准去挑毛病没意义。
    # -std 的选择还要看编译器：gfortran 用 -std=legacy 压掉「已删特性」警告；
    # flang 23 不认 -std=legacy（只接受 -std=f2018），它不加 -std 时本来就
    # 接受固定格式 —— 这本身就是一个跨编译器差异。
    foreach ($channel in @("flang", "gfortran")) {
        $cc = if ($channel -eq "flang") { $flang } else { $gfortran }
        if (-not $cc) { continue }

        if ($FileInfo.Extension -eq ".f") {
            $commonFlags = @("-O2")
            if ($channel -eq "gfortran") { $commonFlags += "-std=legacy" }
        } else {
            $commonFlags = @("-std=f2018", "-pedantic", "-O2")
        }
        if ($needOpenMP) { $commonFlags += "-fopenmp" }

        $modDir   = Join-Path $buildDir "mod/$channel"
        $bin      = Join-Path $buildDir "$base.$channel"
        $outPath  = Join-Path $buildDir "$base.$channel.out"
        $errPath  = Join-Path $buildDir "$base.$channel.err"
        $bldLog   = Join-Path $buildDir "$base.$channel.build"
        $bldErr   = Join-Path $buildDir "$base.$channel.builderr"
        $stdinNul = Join-Path $buildDir "_empty.stdin"

        if (-not (Test-Path -LiteralPath $stdinNul)) {
            Set-Content -LiteralPath $stdinNul -Value "" -Encoding ASCII
        }

        $compileArgs = $commonFlags + @("-J", $modDir, $FileInfo.FullName, "-o", $bin)
        # Windows 上 LLVM 版 flang 需要补链接 compiler-rt builtins
        if ($channel -eq "flang" -and $flangRtLib) { $compileArgs += $flangRtLib }
        $c = Invoke-Proc -Exe $cc -Args $compileArgs -OutFile $bldLog -ErrFile $bldErr `
                         -WorkDir $projectRoot -TimeoutMs 120000

        if ($c.ExitCode -ne 0) {
            Set-Content -LiteralPath $outPath -Value "" -Encoding UTF8
            Set-Content -LiteralPath $errPath -Value "编译失败" -Encoding UTF8
            $msg = (Read-TextFile $bldLog) + (Read-TextFile $bldErr)
            Write-Host ("  [FAIL] {0,-8} {1} —— 编译失败" -f $channel, $base) -ForegroundColor Red
            ($msg -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 3) |
                ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
            $allOk = $false
            continue
        }
        # 编译有诊断输出（即便退出码 0）也算问题：-pedantic 下不该有警告
        if ((Read-TextFile $bldErr).Trim() -ne "" -or (Read-TextFile $bldLog).Trim() -ne "") {
            $allOk = $false
        }

        # 示例里有相对路径读写，统一在 build/ 下运行
        $r = Invoke-Proc -Exe $bin -Args @() -OutFile $outPath -ErrFile $errPath `
                         -WorkDir $buildDir -TimeoutMs 120000
        if (-not (Test-Result -Tag ("{0,-8} {1}" -f $channel, $base) `
                    -OutPath $outPath -ErrPath $errPath -ExitCode $r.ExitCode `
                    -Marker $marker -BuildLog $bldLog -TimedOut:$r.TimedOut)) {
            $allOk = $false
        }

        if ($Verbose) {
            Get-Content -LiteralPath $outPath -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Host "        $_" }
        }
    }

    # ---- 输出一致性比对 ----
    # 先比输出：一致就是 [same]，不一致再看是不是已知差异。
    # 已知差异的条目在 macOS 上往往是一致的，所以先比对才不会误报。
    $fOut = Join-Path $buildDir "$base.flang.out"
    $gOut = Join-Path $buildDir "$base.gfortran.out"
    if ($flang -and $gfortran -and (Test-Path -LiteralPath $fOut) -and (Test-Path -LiteralPath $gOut)) {
        $fText = Read-TextFile $fOut
        $gText = Read-TextFile $gOut
        if ($fText -ne "" -and $gText -ne "") {
            if ($fText -ceq $gText) {
                Write-Host "  [same] 两编译器输出逐字节一致" -ForegroundColor DarkGray
            } else {
                $reason = Get-DiffReason $base
                if ($reason -ne "") {
                    Write-Host ("  [diff] 已知差异：{0}" -f $reason) -ForegroundColor DarkYellow
                } else {
                    Write-Host "  [DIFF] 两编译器输出不一致（意外差异，见 build/$base.*.out）" -ForegroundColor Red
                    $allOk = $false
                }
            }
        }
    }

    return $allOk
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

if ($All) {
    # *.f* 一把抓（.f 与 .f90），再按扩展名精确过滤——避免 *.f 的 8.3 短文件名
    # 匹配怪癖把 .f90 也捞进来
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.f*" |
                 Where-Object { $_.Extension -in ".f", ".f90" } |
                 Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .f90 / .f 示例文件。"
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
    Write-Host "[Done] 全部示例在 flang 与 gfortran 下验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                编译并运行 examples 下全部示例（两条通道）"
Write-Host "  .\build.ps1 -File <name>        只跑单个示例（如 12-derived-types.f90）"
Write-Host "  .\build.ps1 -All -Verbose       附带打印每个示例的运行输出"
Write-Host "  .\build.ps1 -Clean              清理 build 目录"
Write-Host ""
Write-Host "两条通道：flang-mp-23（主） / gfortran-mp-15（对照）"
Write-Host "判定标准：退出码 0 + stderr 为空 + 输出无多余控制字符 + 有 '==== NN 结束 ===='"
Write-Host "自动加分项：源码含 !`$omp 的示例自动加 -fopenmp"
Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 与按编号筛选）。"
