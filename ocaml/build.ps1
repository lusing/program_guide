param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$Native,   # 追加 ocamlopt 原生通道
    [switch]$Interp,   # 追加顶层解释器通道（ocaml X.ml）
    [switch]$NoRun     # 只编译不运行
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$lexExampleDir = Join-Path $examplesDir "26_ocamllex"

# 跨平台判定：$IsWindows 是只读自动变量，且 PowerShell 变量名不区分大小写，
# 给它赋值会直接报错，所以只读一次并落到自己的变量上。
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }

# ----------------------------------------------------------------------
# 工具链发现：环境变量 → PATH → 常见安装目录
# ----------------------------------------------------------------------
function Find-OcamlTool {
    param([Parameter(Mandatory = $true)][string]$Name)

    $envVar = Get-Content "Env:$Name" -ErrorAction SilentlyContinue
    if ($envVar -and (Test-Path -LiteralPath $envVar)) { return $envVar }

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @()
    if ($onWindows) {
        $candidates = @(
            "C:\msys64\ucrt64\bin\$Name.exe",
            "C:\msys64\mingw64\bin\$Name.exe",
            "D:\msys64\ucrt64\bin\$Name.exe",
            "$env:USERPROFILE\scoop\apps\msys2\current\ucrt64\bin\$Name.exe",
            "G:\scoop\apps\msys2\current\ucrt64\bin\$Name.exe"
        )
    } else {
        $candidates = @(
            "/opt/local/bin/$Name",
            "/opt/homebrew/bin/$Name",
            "/usr/local/bin/$Name",
            "/usr/bin/$Name"
        )
    }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    return $null
}

$ocamlc = Find-OcamlTool "ocamlc"
if (-not $ocamlc) {
    throw "未找到 ocamlc。请把 OCaml 的 bin 目录加入 PATH，或设置环境变量 OCAMLC。"
}
$toolDir = Split-Path -Parent $ocamlc

function Resolve-Sibling {
    param([string]$Name)
    $found = Find-OcamlTool $Name
    if ($found) { return $found }
    $cand = Join-Path $toolDir $Name
    if (Test-Path -LiteralPath $cand) { return $cand }
    return $null
}
$ocamlopt = Resolve-Sibling "ocamlopt"
$ocamlBin = Resolve-Sibling "ocaml"
$ocamllexBin = Resolve-Sibling "ocamllex"

# Windows（MSYS2/MinGW 版 OCaml）从原生 shell 调用时不会自己定位标准库，
# 症状是 ocaml/ocamlc 报 "Error: Unbound module Stdlib"。
if (-not $env:OCAMLLIB) {
    $ocamlWhere = (& $ocamlc -where 2>$null) -join ""
    if ($ocamlWhere -and (Test-Path -LiteralPath $ocamlWhere)) {
        $env:OCAMLLIB = $ocamlWhere
    } elseif ($onWindows) {
        $derived = Join-Path (Split-Path -Parent (Split-Path -Parent $ocamlc)) "lib\ocaml"
        if (Test-Path -LiteralPath $derived) { $env:OCAMLLIB = $derived }
    }
}
# 字节码可执行文件运行时依赖 ocamlrun，必须让它在 PATH 里
if ($onWindows -and (($env:Path -split ';') -notcontains $toolDir)) {
    $env:Path = "$toolDir;$env:Path"
}

# 用到 Unix 模块的示例需要显式 -I +unix（OCaml 5 起不写会吐
# Alert ocaml_deprecated_auto_include，那是告警，会被「编译日志为空」判失败）
$unixExamples = @("15_algorithms", "18_io", "21_streams_seq", "22_project", "25_domains_effects")

function Test-NeedsUnix {
    param([string]$BaseName)
    return ($unixExamples -contains $BaseName)
}

# ----------------------------------------------------------------------
# 判定辅助：控制字符按字节判（绕开 PowerShell 正则里的转义坑）
# ----------------------------------------------------------------------
function Test-HasControlChar {
    param([Parameter(Mandatory = $true)][string]$Path)
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Test-HasMarker {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    # 按字节读再按 UTF-8 解码：非法字节变成替换字符，不会像 tr 那样中途截断
    $text = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($Path))
    return $text.Contains($Marker)
}

function Test-FileEmpty {
    param([Parameter(Mandatory = $true)][string]$Path)
    return ((Get-Item -LiteralPath $Path).Length -eq 0)
}

# ----------------------------------------------------------------------
# 六条判定。返回值只有 $true/$false，明细全部走 Write-Host
# ----------------------------------------------------------------------
function Invoke-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [string]$LogFile = "",     # 为空 = 本通道没有编译阶段（解释器）
        [switch]$CompileOnly       # -NoRun：只判编译两条
    )

    $why = @()
    if ($ExitCode -ne 0) { $why += "退出码 $ExitCode" }
    if ($LogFile -and -not (Test-FileEmpty $LogFile)) { $why += "编译有告警（日志非空）" }
    if (-not $CompileOnly) {
        if (-not (Test-FileEmpty $ErrFile)) { $why += "stderr 非空" }
        if (Test-FileEmpty $OutFile) { $why += "stdout 为空" }
        if (Test-HasControlChar $OutFile) { $why += "stdout 含控制字符" }
        if (-not (Test-HasMarker $OutFile $Marker)) { $why += "缺结束标记 [$Marker]" }
    }

    if ($why.Count -eq 0) {
        Write-Host ("  [OK] " + $Tag) -ForegroundColor Green
        return $true
    }

    Write-Host ("  [FAIL] " + $Tag + " —— " + ($why -join "；")) -ForegroundColor Red
    if ($LogFile -and -not (Test-FileEmpty $LogFile)) {
        Get-Content -LiteralPath $LogFile -TotalCount 8 | ForEach-Object { Write-Host ("        compile: " + $_) }
    }
    if (-not (Test-FileEmpty $ErrFile)) {
        Get-Content -LiteralPath $ErrFile -TotalCount 5 | ForEach-Object { Write-Host ("        stderr: " + $_) }
    }
    if (-not (Test-HasMarker $OutFile $Marker)) {
        Write-Host "        stdout 末尾 5 行："
        Get-Content -LiteralPath $OutFile -Tail 5 | ForEach-Object { Write-Host ("        " + $_) }
    }
    return $false
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

if (-not (Test-Path -LiteralPath $examplesDir)) { throw "找不到 examples 目录: $examplesDir" }
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

Write-Host "[Info] ocamlc:   $ocamlc" -ForegroundColor Gray
Write-Host "[Info] ocamlopt: $ocamlopt" -ForegroundColor Gray
Write-Host "[Info] OCAMLLIB: $env:OCAMLLIB" -ForegroundColor Gray

# ----------------------------------------------------------------------
# 单示例单通道。先把源码复制一份到 build/ 再编译：
# ocamlc/ocamlopt 把 .cmi/.cmo/.cmx/.o 放在**源文件旁边**，
# 直接编译 examples/NN.ml 会在源码目录里掉一堆中间产物。
# ----------------------------------------------------------------------
function Invoke-BuildExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][ValidateSet("byte", "native", "interp")][string]$Channel
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $num = ($baseName -split '_')[0]
    $marker = "==== $num jieshu ===="
    $tag = "$Channel $baseName"

    $logFile = Join-Path $buildDir "$baseName.$Channel.compile"
    $outFile = Join-Path $buildDir "$baseName.$Channel.out"
    $errFile = Join-Path $buildDir "$baseName.$Channel.err"
    foreach ($f in @($logFile, $outFile, $errFile)) { New-Item -ItemType File -Force -Path $f | Out-Null }

    $needsUnix = Test-NeedsUnix $baseName

    # ---- 顶层解释器通道：不编译，直接解释执行 ----
    if ($Channel -eq "interp") {
        if (-not $ocamlBin) {
            Write-Host "  [FAIL] $tag —— 找不到 ocaml（顶层解释器）" -ForegroundColor Red
            return $false
        }
        $iargs = @("-w", "-24")
        if ($needsUnix) { $iargs += @("-I", "+unix", "unix.cma") }
        $iargs += $SourcePath
        Push-Location $buildDir
        & $ocamlBin @iargs >$outFile 2>$errFile
        $rc = $LASTEXITCODE
        Pop-Location
        return (Invoke-Check -Tag $tag -Marker $marker -OutFile $outFile -ErrFile $errFile -ExitCode $rc)
    }

    $compiler = if ($Channel -eq "native") { $ocamlopt } else { $ocamlc }
    if (-not $compiler) {
        $want = if ($Channel -eq "native") { "ocamlopt" } else { "ocamlc" }
        Write-Host "  [FAIL] $tag —— 找不到 $want" -ForegroundColor Red
        return $false
    }
    $outName = if ($Channel -eq "native") { "${baseName}_opt" } else { $baseName }

    Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $buildDir "$baseName.ml") -Force
    $cargs = @("-w", "-24")
    if ($needsUnix) {
        $cargs += @("-I", "+unix", $(if ($Channel -eq "native") { "unix.cmxa" } else { "unix.cma" }))
    }
    $cargs += @("-o", $outName, "$baseName.ml")

    Write-Host "[Compile] $baseName ($Channel)" -ForegroundColor Cyan
    Push-Location $buildDir
    & $compiler @cargs >$logFile 2>&1
    $compileRc = $LASTEXITCODE
    Pop-Location

    if ($compileRc -ne 0 -or $NoRun) {
        $co = if ($NoRun) { @{ CompileOnly = $true } } else { @{} }
        return (Invoke-Check -Tag $tag -Marker $marker -OutFile $outFile -ErrFile $errFile `
                             -ExitCode $compileRc -LogFile $logFile @co)
    }

    Push-Location $buildDir
    if ($onWindows) { & ".\$outName.exe" >$outFile 2>$errFile } else { & "./$outName" >$outFile 2>$errFile }
    $rc = $LASTEXITCODE
    Pop-Location

    return (Invoke-Check -Tag $tag -Marker $marker -OutFile $outFile -ErrFile $errFile `
                         -ExitCode $rc -LogFile $logFile)
}

# ocamllex 两段式：先生成 .ml，再与 main.ml 一起编译（byte + native）
function Invoke-BuildLexExample {
    param([Parameter(Mandatory = $true)][ValidateSet("byte", "native")][string]$Channel)

    $baseName = "26_ocamllex"
    $marker = "==== 26 jieshu ===="
    $tag = "$Channel $baseName"

    $genMl = Join-Path $buildDir "ocamllex_expr.ml"
    $mainMl = Join-Path $buildDir "ocamllex_main.ml"
    Copy-Item -LiteralPath (Join-Path $lexExampleDir "main.ml") -Destination $mainMl -Force

    $genLog = Join-Path $buildDir "$baseName.lex.generate"
    New-Item -ItemType File -Force -Path $genLog | Out-Null
    if (-not $ocamllexBin) {
        Write-Host "  [FAIL] $tag —— 找不到 ocamllex" -ForegroundColor Red
        return $false
    }
    & $ocamllexBin -q -o $genMl (Join-Path $lexExampleDir "ocamllex_expr.mll") >$genLog 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [FAIL] $tag —— ocamllex 退出码 $LASTEXITCODE" -ForegroundColor Red
        Get-Content -LiteralPath $genLog -TotalCount 5 | ForEach-Object { Write-Host ("        " + $_) }
        return $false
    }

    $compiler = if ($Channel -eq "native") { $ocamlopt } else { $ocamlc }
    if (-not $compiler) {
        $want = if ($Channel -eq "native") { "ocamlopt" } else { "ocamlc" }
        Write-Host "  [FAIL] $tag —— 找不到 $want" -ForegroundColor Red
        return $false
    }
    $outName = if ($Channel -eq "native") { "${baseName}_opt" } else { $baseName }

    $logFile = Join-Path $buildDir "$baseName.$Channel.compile"
    $outFile = Join-Path $buildDir "$baseName.$Channel.out"
    $errFile = Join-Path $buildDir "$baseName.$Channel.err"
    foreach ($f in @($logFile, $outFile, $errFile)) { New-Item -ItemType File -Force -Path $f | Out-Null }

    $lib = if ($Channel -eq "native") { "unix.cmxa" } else { "unix.cma" }
    Write-Host "[Compile] $baseName ($Channel)" -ForegroundColor Cyan
    Push-Location $buildDir
    & $compiler -w -24 -I +unix $lib -o $outName "ocamllex_expr.ml" "ocamllex_main.ml" >$logFile 2>&1
    $compileRc = $LASTEXITCODE
    Pop-Location

    if ($compileRc -ne 0 -or $NoRun) {
        $co = if ($NoRun) { @{ CompileOnly = $true } } else { @{} }
        return (Invoke-Check -Tag $tag -Marker $marker -OutFile $outFile -ErrFile $errFile `
                             -ExitCode $compileRc -LogFile $logFile @co)
    }

    Push-Location $buildDir
    if ($onWindows) { & ".\$outName.exe" >$outFile 2>$errFile } else { & "./$outName" >$outFile 2>$errFile }
    $rc = $LASTEXITCODE
    Pop-Location

    return (Invoke-Check -Tag $tag -Marker $marker -OutFile $outFile -ErrFile $errFile `
                         -ExitCode $rc -LogFile $logFile)
}

# ----------------------------------------------------------------------
# 主流程
# ----------------------------------------------------------------------
$script:passCount = 0
$script:failCount = 0
$script:failedList = @()

function Add-Result {
    param([bool]$Ok, [string]$Tag)
    if ($Ok) { $script:passCount++ } else { $script:failCount++; $script:failedList += $Tag }
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.ml" | Sort-Object Name
    if ($files.Count -eq 0) { throw "examples 目录下没有 .ml 示例文件。" }

    foreach ($f in $files) {
        Write-Host "==== $($f.Name) ===="
        Add-Result (Invoke-BuildExample -SourcePath $f.FullName -Channel byte) "byte $($f.Name)"
        if ($Native) { Add-Result (Invoke-BuildExample -SourcePath $f.FullName -Channel native) "native $($f.Name)" }
        if ($Interp) { Add-Result (Invoke-BuildExample -SourcePath $f.FullName -Channel interp) "interp $($f.Name)" }
    }

    if (Test-Path -LiteralPath $lexExampleDir) {
        Write-Host "==== 26_ocamllex ===="
        Add-Result (Invoke-BuildLexExample -Channel byte) "byte 26_ocamllex"
        if ($Native) { Add-Result (Invoke-BuildLexExample -Channel native) "native 26_ocamllex" }
    }

    Write-Host ""
    $color = if ($script:failCount -eq 0) { "Green" } else { "Red" }
    Write-Host "[Done] 通过 $($script:passCount)，失败 $($script:failCount)。" -ForegroundColor $color
    if ($script:failedList.Count -gt 0) {
        Write-Host "失败项: $($script:failedList -join ', ')" -ForegroundColor Red
        exit 1
    }
    exit 0
}

if ($File) {
    if ($File -match '^26$|^26_ocamllex$') {
        $ok = Invoke-BuildLexExample -Channel byte
        if ($Native) { $ok = (Invoke-BuildLexExample -Channel native) -and $ok }
        if (-not $ok) { exit 1 }
        Write-Host "[Done] 编译并验证通过: 26_ocamllex" -ForegroundColor Green
        exit 0
    }

    if ($File -match '^\d+$') {
        $padded = $File.PadLeft(2, '0')
        $m = Get-ChildItem -LiteralPath $examplesDir -Filter "${padded}_*.ml" | Sort-Object Name
        if ($m.Count -eq 0) { throw "找不到编号为 $File 的示例文件。" }
        $sourcePath = $m[0].FullName
    } else {
        if (-not $File.EndsWith('.ml')) { $File = $File + '.ml' }
        $sourcePath = Join-Path $examplesDir $File
        if (-not (Test-Path -LiteralPath $sourcePath)) { throw "找不到示例文件: $sourcePath" }
    }

    $ok = Invoke-BuildExample -SourcePath $sourcePath -Channel byte
    if ($Native) { $ok = (Invoke-BuildExample -SourcePath $sourcePath -Channel native) -and $ok }
    if ($Interp) { $ok = (Invoke-BuildExample -SourcePath $sourcePath -Channel interp) -and $ok }
    if (-not $ok) { exit 1 }
    Write-Host "[Done] 编译并验证通过: $([System.IO.Path]::GetFileName($sourcePath))" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All             编译并运行 examples 下全部示例（字节码）"
Write-Host "  .\build.ps1 -All -Native     追加 ocamlopt 原生通道"
Write-Host "  .\build.ps1 -All -Interp     追加顶层解释器通道（ocaml X.ml）"
Write-Host "  .\build.ps1 -File <name.ml>  编译单个示例（只写编号也可以，如 01）"
Write-Host "  .\build.ps1 -File 15 -Native"
Write-Host "  .\build.ps1 -All -NoRun      只编译不运行"
Write-Host "  .\build.ps1 -Clean           清理 build 目录"
Write-Host ""
Write-Host "判定标准（与 run-all.sh 完全一致）：编译退出码 0 + 编译日志为空（零告警）"
Write-Host "  + 运行退出码 0 + stderr 为空 + stdout 非空且无多余控制字符 + 结束标记"
