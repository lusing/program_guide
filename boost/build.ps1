<#
  build.ps1 —— Boost 教程统一构建/验证入口（MSVC + Boost 1.92 DLL）

    pwsh ./build.ps1 -All                        全量：逐示例编译（零告警）+ 运行 + 六条判定
    pwsh ./build.ps1 -Chapter 03                 只跑某一章（编号或目录名均可）
    pwsh ./build.ps1 -File 03_smartptr/smart_ptr.cpp   单示例（相对 examples 的路径）
    pwsh ./build.ps1 -All -ShowOutput            附带打印每个示例的运行输出
    pwsh ./build.ps1 -Clean                      清理 build 目录

  单通道：本教程绑定本机 MSVC（VS 18, cl 19.51, /std:c++latest）+
          Boost 1.92（scoop, DLL 版预编译库 vc145）。

  判定标准（六条，缺一不可）：
    1) 编译退出码 0
    2) 编译日志干净（不含 warning/error——示例代码 /W4；Boost 头用
       /external:I + /external:W0 压掉，教训：不加 /external 的话
       /W4 会被 Boost 头自己的告警淹没，"零告警"形同虚设）
    3) 运行退出码 0
    4) stdout 非空、无控制字符（TAB/LF/CR 除外）
    5) stderr 为空
    6) stdout 里有结束标记 "自检通过"

  结束标记沿用仓库惯例：docs/ 各章正文里嵌了示例的完整输出，示例自己
  最后一行打印 "自检通过"，改文案要同步文档——它本来就承担这个语义。

  目录约定：
    examples/NN_章名/库.cpp      —— 每个库一个自包含例程，编成同名 exe
    examples/NN_章名/plugin_*.cpp —— 编成 DLL（/LD），只编译不运行
                                      （供 dll 章节的宿主例程加载）

  Boost DLL 约定：
    本机 scoop 只装了 DLL 版（mt/mt-gd），没有静态库 —— 必须
      /MD                    动态运行时（默认 /MT 会报
                             "Mixing a dll boost library with a static runtime"）
      /D BOOST_ALL_DYN_LINK  dllimport 生效 + 自动链接选 mt 变体
      /LIBPATH:<boost>\lib   自动链接在此找 boost_*-vc145-mt-x64-1_92.lib
      运行时 PATH 前置 <boost>\lib（否则找不到 DLL，进程起不来）
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$All,
    [string]$Chapter,
    [string]$File,
    [switch]$Clean,
    [switch]$ShowOutput,
    # 位置参数当"章节编号"用：./build.ps1 03 15
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Select
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8（示例侧 /utf-8 编译，两侧编码必须一致）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"
$tmpDir      = Join-Path $buildDir "tmp"
$marker      = "自检通过"

# ---------------------------------------------------------------
# 工具链与依赖定位
# ---------------------------------------------------------------
$vcvars   = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$boostRoot = "G:\scoop\apps\boost\current"      # scoop 符号链接 → 1.92.0
$boostLib  = Join-Path $boostRoot "lib"
$cudaInc   = "G:\cuda\v13.3\include"            # compute 章用的 OpenCL 头
$cudaLib   = "G:\cuda\v13.3\lib\x64"            # OpenCL.lib（ICD 加载器）

if ($env:VCVARS)     { $vcvars = $env:VCVARS }
if ($env:BOOST_ROOT) { $boostRoot = $env:BOOST_ROOT; $boostLib = Join-Path $boostRoot "lib" }

foreach ($p in @($vcvars, $boostRoot)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "路径不存在: $p（可用 VCVARS / BOOST_ROOT 环境变量覆盖）" }
}

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $tmpDir    | Out-Null

# ---------------------------------------------------------------
# 章节配置表：额外链接库 / 额外 include / 额外宏。
# 键 = 章节编号（目录名前缀）。随章节落地逐步补齐。
# ---------------------------------------------------------------
$chapterConfig = @{
    # '16_coroutines' = @{ libs = @() }   —— 示例：无额外依赖的章不用列
    '13'  = @{ libs = @('Shell32.lib') }                              # nowide: CommandLineToArgvW
    '17'  = @{ libs = @('dbghelp.lib') }                              # stacktrace
    '25'  = @{ libs = @('OpenCL.lib'); libpaths = @($cudaLib);
               includes = @($cudaInc) }                               # compute
    '28'  = @{ libs = @('ws2_32.lib') }                               # asio/beast
    '32'  = @{ defines = @('BOOST_TEST_DYN_LINK') }                   # test
}

# 公共编译参数
$commonArgs = @(
    '/nologo', '/std:c++latest', '/EHsc', '/MD', '/utf-8',
    '/permissive-', '/Zc:__cplusplus', '/W4',
    '/D', 'BOOST_ALL_DYN_LINK',
    '/D', '_WIN32_WINNT=0x0A00',
    '/external:I', "`"$boostRoot`"",
    '/external:W0'
)

$script:passCount = 0
$script:failCount = 0

# ---------------------------------------------------------------
# 进程捕获：按字节重定向 stdout/stderr
#   不要用 Start-Process -RedirectStandardOutput：它会把输出里的空行吞掉
#   （"A\n\nB\n" 落盘变成 "A\nB\n"），示例里有 std::println("") 这种真空行。
#   运行期把 Boost DLL 目录前置进 PATH，找得到 boost_*-vc145-*.dll。
# ---------------------------------------------------------------
function Invoke-Capture {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkDir = $projectRoot,
        [int]$TimeoutMs = 60000,
        # 整条命令行原样透传（cmd /c 批处理必须走这个：ArgumentList 会把
        # 参数里的 " 转义成 \"，cmd 收到的引号全废，cl 的 /Fe"..." 全断——
        # 实测 echo 探针确认；直接跑 exe 的场景没有裸引号，走 $Args 即可）
        [string]$RawCommandLine = ""
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Exe
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.WorkingDirectory       = $WorkDir
    $psi.EnvironmentVariables["TMPDIR"] = $tmpDir
    $psi.EnvironmentVariables["PATH"]   = "$boostLib;" + $psi.EnvironmentVariables["PATH"]

    if ($RawCommandLine -ne "") {
        $psi.Arguments = $RawCommandLine
    } elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        foreach ($a in $Args) { $psi.ArgumentList.Add($a) }
    } else {
        $quoted = foreach ($a in $Args) {
            if ($a -match '[\s"]') { '"' + ($a -replace '"', '\"') + '"' } else { $a }
        }
        $psi.Arguments = ($quoted -join ' ')
    }

    $outFs = [System.IO.File]::Create($OutFile)
    $errFs = [System.IO.File]::Create($ErrFile)
    $timedOut = $false
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $outTask = $p.StandardOutput.BaseStream.CopyToAsync($outFs)
        $errTask = $p.StandardError.BaseStream.CopyToAsync($errFs)
        if (-not $p.WaitForExit($TimeoutMs)) {
            $p.Kill()
            $p.WaitForExit(5000) | Out-Null
            $timedOut = $true
        }
        try { $outTask.GetAwaiter().GetResult() | Out-Null } catch {}
        try { $errTask.GetAwaiter().GetResult() | Out-Null } catch {}
        $code = $p.ExitCode
    } finally {
        $outFs.Dispose()
        $errFs.Dispose()
    }
    return @{ ExitCode = $code; TimedOut = $timedOut }
}

# 走 cmd.exe 跑一段批处理（cl 要先 call vcvars64.bat 才认得）
function Invoke-Batch {
    param(
        [Parameter(Mandatory = $true)][string]$CommandLine,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile
    )
    return Invoke-Capture -Exe $env:ComSpec -RawCommandLine ("/c " + $CommandLine) `
                          -OutFile $OutFile -ErrFile $ErrFile
}

function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $text = [string](Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue)
    if ($null -eq $text) { $text = "" }
    return $text
}

# 输出里是否混进了「不该出现」的控制字符（TAB/LF/CR 除外）。按字节判。
function Test-HasCtrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# 编译日志是否"干净"：MSVC 成功时也回显源文件名，只在出现 warning/error 时判失败。
# 诊断可能落两个文件（cl 的回显走 stdout → .build，致命错误走 stderr → .builderr）。
function Test-BuildClean {
    param([string]$LogText)
    return -not ($LogText -match "(?i)\b(warning|error)\b")
}

function Test-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$BuildLog,
        [Parameter(Mandatory = $true)][string]$BuildErr,
        [switch]$TimedOut
    )

    $reasons = @()
    if ($TimedOut) { $reasons += "超过 60 秒未结束（多半是死循环/死等）" }
    if ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }

    $errText = Read-TextFile $ErrPath
    if ($errText.Trim() -ne "") {
        $first = ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "stderr 非空（警告也算失败）：$($first.Trim())"
    }
    if (-not (Test-Path -LiteralPath $OutPath) -or (Get-Item -LiteralPath $OutPath).Length -eq 0) {
        $reasons += "stdout 为空（进程没跑到业务代码）"
    }
    if (Test-HasCtrl $OutPath) { $reasons += "stdout 含多余控制字符" }
    if ((Read-TextFile $OutPath) -notlike "*$marker*") { $reasons += "缺少结束标记 $marker" }

    $bldText = (Read-TextFile $BuildLog) + (Read-TextFile $BuildErr)
    if (-not (Test-BuildClean -LogText $bldText)) {
        $first = ($bldText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "编译有告警/错误：$($first.Trim())"
    }

    if ($reasons.Count -eq 0) {
        Write-Host ("  [OK]   {0}" -f $Tag) -ForegroundColor Green
        return $true
    }
    Write-Host ("  [FAIL] {0} —— {1}" -f $Tag, ($reasons -join "；")) -ForegroundColor Red
    return $false
}

# ---------------------------------------------------------------
# 一个示例文件的一轮编译+运行
# ---------------------------------------------------------------
function Invoke-Sample {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$Source,
        [Parameter(Mandatory = $true)][string]$ChapterNum
    )

    $base   = $Source.BaseName
    $isDll  = $base -like 'plugin_*'
    $exePath = Join-Path $buildDir "$base.exe"
    $dllPath = Join-Path $buildDir "$base.dll"
    $objPath = Join-Path $buildDir "$base.obj"
    $outPath = Join-Path $buildDir "$base.out"
    $errPath = Join-Path $buildDir "$base.err"
    $bldLog  = Join-Path $buildDir "$base.build"
    $bldErr  = Join-Path $buildDir "$base.builderr"
    $tag     = $Source.Directory.Name + "/" + $Source.Name

    # 章节附加配置
    $extraLibs    = @()
    $extraLibPaths = @()
    $extraIncludes = @()
    $extraDefines = @()
    if ($chapterConfig.ContainsKey($ChapterNum)) {
        $cfg = $chapterConfig[$ChapterNum]
        if ($cfg.libs)     { $extraLibs     = @($cfg.libs) }
        if ($cfg.libpaths) { $extraLibPaths = @($cfg.libpaths) }
        if ($cfg.includes) { $extraIncludes = @($cfg.includes) }
        if ($cfg.defines)  { $extraDefines  = @($cfg.defines) }
    }

    $clArgs = @($commonArgs)
    foreach ($d in $extraDefines)  { $clArgs += @('/D', $d) }
    foreach ($i in $extraIncludes) { $clArgs += @('/I', "`"$i`"") }
    if ($isDll) { $clArgs += '/LD' }
    $clArgs += @("/Fo`"$objPath`"", "`"$($Source.FullName)`"", "/Fe`"$($isDll ? $dllPath : $exePath)`"", '/link', "`"/LIBPATH:$boostLib`"")
    foreach ($lp in $extraLibPaths) { $clArgs += "`"/LIBPATH:$lp`"" }
    $clArgs += $extraLibs

    $r = Invoke-Batch -CommandLine ('call "{0}" >nul 2>nul && cl {1}' -f $vcvars, ($clArgs -join ' ')) `
                      -OutFile $bldLog -ErrFile $bldErr
    if ($r.ExitCode -ne 0) {
        [System.IO.File]::WriteAllBytes($outPath, @())
        $msg = (Read-TextFile $bldLog) + (Read-TextFile $bldErr)
        [System.IO.File]::WriteAllText($errPath, "编译失败`n$msg")
        $first = ($msg -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 3)
        Write-Host ("  [FAIL] {0} —— 编译失败" -f $tag) -ForegroundColor Red
        $first | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
        $script:failCount++
        return $false
    }

    # plugin_* 只编译不运行：宿主例程负责加载并自检
    if ($isDll) {
        Write-Host ("  [OK]   {0} （DLL 已产出）" -f $tag) -ForegroundColor Green
        $script:passCount++
        return $true
    }

    # 示例统一在 build/ 下跑（相对路径读写、临时文件都落这里）
    $run = Invoke-Capture -Exe $exePath -Args @() -OutFile $outPath -ErrFile $errPath -WorkDir $buildDir

    $ok = Test-Result -Tag $tag -OutPath $outPath -ErrPath $errPath `
                      -ExitCode $run.ExitCode -BuildLog $bldLog -BuildErr $bldErr `
                      -TimedOut:$run.TimedOut
    if ($ok) { $script:passCount++ } else { $script:failCount++ }

    if ($ShowOutput) {
        Get-Content -LiteralPath $outPath -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Host "        $_" }
    }
    return $ok
}

function Get-ChapterDirs {
    param([string[]]$Numbers, [string]$NamePrefix)
    $dirs = @(Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name)
    if ($NamePrefix) {
        $dirs = @($dirs | Where-Object { $_.Name -eq $NamePrefix -or ($_.Name -split '_')[0] -eq $NamePrefix })
    }
    if ($Numbers -and $Numbers.Count -gt 0) {
        $dirs = @($dirs | Where-Object { $Numbers -contains ($_.Name -split '_')[0] })
    }
    return $dirs
}

if ($File) {
    $src = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $src)) { throw "找不到示例文件: $src" }
    $fi = Get-Item -LiteralPath $src
    $chNum = ($fi.Directory.Name -split '_')[0]
    if (-not (Invoke-Sample -Source $fi -ChapterNum $chNum)) { exit 1 }
    Write-Host "[Done] 验证通过: $File" -ForegroundColor Green
    exit 0
}

if ($Chapter) {
    $dirs = Get-ChapterDirs -NamePrefix $Chapter
    if ($dirs.Count -eq 0) { throw "没有匹配的章节目录: $Chapter" }
} elseif ($Select -and $Select.Count -gt 0) {
    $All = $true
    $dirs = Get-ChapterDirs -Numbers $Select
    if ($dirs.Count -eq 0) { throw "examples 目录下没有匹配的章节目录。" }
} elseif ($All) {
    $dirs = Get-ChapterDirs
    if ($dirs.Count -eq 0) { throw "examples 目录下没有章节目录。" }
} else {
    $dirs = @()
}

if ($dirs.Count -gt 0) {
    $failedList = @()
    foreach ($d in $dirs) {
        $chNum = ($d.Name -split '_')[0]
        Write-Host "==== $($d.Name) ====" -ForegroundColor Cyan
        foreach ($f in @(Get-ChildItem -LiteralPath $d.FullName -Filter '*.cpp' | Sort-Object Name)) {
            if (-not (Invoke-Sample -Source $f -ChapterNum $chNum)) { $failedList += "$($d.Name)/$($f.Name)" }
        }
    }

    Write-Host "--------------------------------" -ForegroundColor DarkGray
    Write-Host ("通过 {0}   失败 {1}" -f $script:passCount, $script:failCount) `
        -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })
    if ($script:failCount -ne 0) {
        Write-Host "失败项：" -ForegroundColor Red
        $failedList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "[Done] 全部 $($script:passCount) 个示例编译+运行通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  ./build.ps1 -All                       全量：逐示例编译（零告警）+ 运行自检"
Write-Host "  ./build.ps1 -Chapter 03                整章验证（编号或目录名）"
Write-Host "  ./build.ps1 -File 03_smartptr/smart_ptr.cpp   单示例"
Write-Host "  ./build.ps1 -All -ShowOutput           附带打印运行输出"
Write-Host "  ./build.ps1 -Clean                     清理 build 目录"
Write-Host ""
Write-Host "判定标准：编译零告警 + 退出码 0 + stderr 空 + stdout 非空无控制字符 + 有 '$marker'"
