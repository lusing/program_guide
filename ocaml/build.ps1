param(
    [switch]$All,
    [string]$File,
    [switch]$Clean,
    [switch]$Native,   # 额外用 ocamlopt 做原生编译并运行
    [switch]$NoRun     # 只编译不运行
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

# ----------------------------------------------------------------------
# 工具链发现：Windows（MSYS2 UCRT64/MINGW64、scoop 的 msys2）+ macOS/Linux
# ----------------------------------------------------------------------
function Find-Ocamlc {
    # 1) PATH 里直接能找到
    $cmd = Get-Command ocamlc -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2) 常见安装位置（Windows 的 MSYS2 系；macOS/Linux 的 brew/macports/系统）
    $candidates = @()
    if ($IsWindows) {
        $candidates = @(
            "C:\msys64\ucrt64\bin\ocamlc.exe",
            "C:\msys64\mingw64\bin\ocamlc.exe",
            "D:\msys64\ucrt64\bin\ocamlc.exe",
            "$env:USERPROFILE\scoop\apps\msys2\current\ucrt64\bin\ocamlc.exe",
            "G:\scoop\apps\msys2\current\ucrt64\bin\ocamlc.exe"
        )
    } else {
        $candidates = @(
            "/usr/local/bin/ocamlc",
            "/opt/homebrew/bin/ocamlc",
            "/opt/local/bin/ocamlc",
            "/usr/bin/ocamlc"
        )
    }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    return $null
}

$ocamlc = Find-Ocamlc
if (-not $ocamlc) {
    throw "未找到 ocamlc。请把 OCaml 的 bin 目录加入 PATH，或在 build.ps1 的 Find-Ocamlc 候选列表里补上你的安装路径。"
}
$toolDir = Split-Path -Parent $ocamlc

# Windows（MSYS2/MinGW 版 OCaml）从原生 shell 调用时不会自己定位标准库，
# 症状是 ocaml/ocamlc 报 "Error: Unbound module Stdlib"。
# 优先用 ocamlc -where；MSYS2 版的 -where 打印 MSYS 根的 POSIX 路径
# （如 /ucrt64/lib/ocaml），原生 Windows 下不存在，此时从编译器位置推导。
if (-not $env:OCAMLLIB) {
    $ocamlWhere = (& $ocamlc -where 2>$null) -join ""
    if ($ocamlWhere -and (Test-Path -LiteralPath $ocamlWhere)) {
        $env:OCAMLLIB = $ocamlWhere
    } elseif ($IsWindows) {
        $derived = Join-Path (Split-Path -Parent (Split-Path -Parent $ocamlc)) "lib\ocaml"
        if (Test-Path -LiteralPath $derived) { $env:OCAMLLIB = $derived }
    }
}
# 字节码可执行文件运行时依赖 ocamlrun，必须让它在 PATH 里
if ($IsWindows -and (($env:Path -split ';') -notcontains $toolDir)) {
    $env:Path = "$toolDir;$env:Path"
}

# 依赖表：用到 Unix 模块的示例需要链接 unix
$unixExamples = @("15_algorithms", "18_io", "21_streams_seq", "22_project", "25_domains_effects")
$stdlibDir = $env:OCAMLLIB
$unixDir = if ($stdlibDir) { Join-Path $stdlibDir "unix" } else { $null }

# ocamllex 示例：examples/26_ocamllex/ 下的 ocamllex_expr.mll + main.ml
# （.mll 生成的模块名来自文件名，不能用数字开头，所以放子目录用合法名）
$lexExampleDir = Join-Path $examplesDir "26_ocamllex"

# 输出文件名：Windows 上 PowerShell 的 & 不肯执行无后缀 PE，统一加 .exe
$exeSuffix = if ($IsWindows) { ".exe" } else { "" }

Write-Host "[Info] 编译器:       $ocamlc" -ForegroundColor Gray
Write-Host "[Info] OCAMLLIB:    $env:OCAMLLIB" -ForegroundColor Gray

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

# 编译并运行单个示例。返回 $true/$false，并输出判定明细。
function Invoke-BuildExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [switch]$Native
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $fileName = [System.IO.Path]::GetFileName($SourcePath)
    $num = ($baseName -split '_')[0]
    # 原生编译产物加 _opt 后缀，避免覆盖同名字节码可执行文件
    $outName = if ($Native) { $baseName + "_opt" + $exeSuffix } else { $baseName + $exeSuffix }
    $outputPath = Join-Path $buildDir $outName

    # 选择编译器：默认 ocamlc 字节码；-Native 时用同目录的 ocamlopt
    $compiler = $ocamlc
    if ($Native) {
        $optCandidate = Join-Path $toolDir ((Split-Path -Leaf $ocamlc) -replace 'ocamlc', 'ocamlopt')
        if (Test-Path -LiteralPath $optCandidate) {
            $compiler = $optCandidate
        } else {
            $cmdOpt = Get-Command ocamlopt -ErrorAction SilentlyContinue
            if ($cmdOpt) { $compiler = $cmdOpt.Source }
            else {
                Write-Host "[FAIL]    ${fileName}: 找不到 ocamlopt（原生编译需要；MSYS2 下确认已安装 ocaml 包与 flexdll）" -ForegroundColor Red
                return $false
            }
        }
    }

    # 链接参数：用到 Unix 模块的示例加 -I <unixdir> unix.cma/unix.cmxa
    $linkArgs = @()
    if ($unixExamples -contains $baseName) {
        $libExt = if ($Native) { "unix.cmxa" } else { "unix.cma" }
        $libPath = Join-Path $unixDir $libExt
        if (-not (Test-Path -LiteralPath $libPath)) {
            Write-Host "[FAIL]    ${fileName}: 需要 unix 库但找不到 $libPath" -ForegroundColor Red
            return $false
        }
        $linkArgs = @("-I", $unixDir, $libExt)
    }

    Write-Host "[Compile] $fileName$(if ($Native) { ' (native)' })" -ForegroundColor Cyan
    & $compiler -w -24 @linkArgs -o $outputPath $SourcePath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL]    ${fileName}: 编译失败" -ForegroundColor Red
        return $false
    }
    # ocamlc/ocamlopt 把 .cmi/.cmo/.cmx/.o 放在源文件旁边，链接完即清扫
    Remove-Item (Join-Path $examplesDir ($baseName + ".cm*")) -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $examplesDir ($baseName + ".o")) -ErrorAction SilentlyContinue

    if ($NoRun) {
        Write-Host "[OK]      $fileName -> build/$(Split-Path -Leaf $outputPath)" -ForegroundColor Green
        return $true
    }

    $out = & $outputPath 2>&1
    $runExit = $LASTEXITCODE
    if ($runExit -ne 0) {
        Write-Host "[FAIL]    ${fileName}: 运行退出码 $runExit" -ForegroundColor Red
        $out | Select-Object -Last 5 | ForEach-Object { Write-Host "          $_" -ForegroundColor DarkGray }
        return $false
    }
    $marker = $out | Select-String -SimpleMatch "==== $num jieshu ====" -Quiet
    if (-not $marker) {
        Write-Host "[FAIL]    ${fileName}: 未找到结束标记 '==== $num jieshu ===='" -ForegroundColor Red
        $out | Select-Object -Last 5 | ForEach-Object { Write-Host "          $_" -ForegroundColor DarkGray }
        return $false
    }

    Write-Host "[OK]      $fileName -> build/$(Split-Path -Leaf $outputPath) (run + marker)" -ForegroundColor Green
    return $true
}

# ocamllex 两段式构建：先用 ocamllex 生成 .ml，再与 main.ml 一起编译链接
function Invoke-BuildLexExample {
    $outName = "26_ocamllex$exeSuffix"
    $outputPath = Join-Path $buildDir $outName
    $mll = Join-Path $lexExampleDir "ocamllex_expr.mll"
    $mainMl = Join-Path $lexExampleDir "main.ml"
    $genMl = Join-Path $buildDir "ocamllex_expr.ml"

    Write-Host "[Compile] ocamllex_expr.mll + main.ml" -ForegroundColor Cyan
    $ocamllexBin = Join-Path $toolDir $(if ($IsWindows) { "ocamllex.exe" } else { "ocamllex" })
    & $ocamllexBin -o $genMl $mll 2>&1 | Write-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL]    ocamllex 生成失败" -ForegroundColor Red
        return $false
    }
    & $ocamlc -w -24 -I $buildDir -o $outputPath $genMl $mainMl
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL]    26_ocamllex 编译失败" -ForegroundColor Red
        return $false
    }
    # 清扫编译中间产物（ocamlc 把 .cmi/.cmo 放在源文件旁边）
    Remove-Item (Join-Path $lexExampleDir "main.cm*") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $buildDir "ocamllex_expr.cm*") -ErrorAction SilentlyContinue

    if ($NoRun) {
        Write-Host "[OK]      26_ocamllex -> build/$outName" -ForegroundColor Green
        return $true
    }

    $out = & $outputPath 2>&1
    $runExit = $LASTEXITCODE
    if ($runExit -ne 0) {
        Write-Host "[FAIL]    26_ocamllex: 运行退出码 $runExit" -ForegroundColor Red
        $out | Select-Object -Last 5 | ForEach-Object { Write-Host "          $_" -ForegroundColor DarkGray }
        return $false
    }
    $marker = $out | Select-String -SimpleMatch "==== 26 jieshu ====" -Quiet
    if (-not $marker) {
        Write-Host "[FAIL]    26_ocamllex: 未找到结束标记" -ForegroundColor Red
        return $false
    }
    Write-Host "[OK]      26_ocamllex -> build/$outName (run + marker)" -ForegroundColor Green
    return $true
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.ml" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .ml 示例文件。"
    }

    $pass = 0
    $fail = 0
    $failedFiles = @()

    foreach ($f in $files) {
        $ok = Invoke-BuildExample -SourcePath $f.FullName
        if ($ok) { $pass++ } else { $fail++; $failedFiles += $f.Name }
        if ($Native) {
            $okN = Invoke-BuildExample -SourcePath $f.FullName -Native
            if ($okN) { $pass++ } else { $fail++; $failedFiles += "$($f.Name) [native]" }
        }
    }

    # ocamllex 组合示例
    if (Test-Path -LiteralPath $lexExampleDir) {
        $ok = Invoke-BuildLexExample
        if ($ok) { $pass++ } else { $fail++; $failedFiles += "26_ocamllex" }
    }

    $totalEntries = $files.Count + $(if (Test-Path -LiteralPath $lexExampleDir) { 1 } else { 0 })
    Write-Host ""
    Write-Host "[Done] 总计 $totalEntries 个条目$(if ($Native) { ' x2 (byte+native)' }): 通过 $pass，失败 $fail。" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })

    if ($failedFiles.Count -gt 0) {
        Write-Host "失败文件: $($failedFiles -join ', ')" -ForegroundColor Red
        exit 1
    }
    exit 0
}

if ($File) {
    # ocamllex 组合示例单独处理（没有顶层 26_*.ml）
    if ($File -match '^26$|^26_ocamllex$') {
        $ok = Invoke-BuildLexExample
        if (-not $ok) { exit 1 }
        Write-Host "[Done] 编译并验证通过: 26_ocamllex" -ForegroundColor Green
        exit 0
    }

    # 支持只写编号，自动补全前缀和后缀
    if ($File -match '^\d+$') {
        $padded = $File.PadLeft(2, '0')
        $matches = Get-ChildItem -LiteralPath $examplesDir -Filter "${padded}_*.ml" | Sort-Object Name
        if ($matches.Count -eq 0) {
            throw "找不到编号为 $File 的示例文件。"
        }
        $sourcePath = $matches[0].FullName
    } else {
        if (-not $File.EndsWith('.ml')) {
            $File = $File + '.ml'
        }
        $sourcePath = Join-Path $examplesDir $File
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "找不到示例文件: $sourcePath"
        }
    }

    $ok = Invoke-BuildExample -SourcePath $sourcePath
    if ($Native) {
        $okN = Invoke-BuildExample -SourcePath $sourcePath -Native
        $ok = $ok -and $okN
    }
    if (-not $ok) { exit 1 }
    Write-Host "[Done] 编译并验证通过: $([System.IO.Path]::GetFileName($sourcePath))" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All            编译并运行 examples 下全部示例（字节码）"
Write-Host "  .\build.ps1 -All -Native    同时做 ocamlopt 原生编译与运行"
Write-Host "  .\build.ps1 -File <name.ml> 编译单个示例（只写编号也可以，如 01）"
Write-Host "  .\build.ps1 -File 15 -Native"
Write-Host "  .\build.ps1 -All -NoRun     只编译不运行"
Write-Host "  .\build.ps1 -Clean          清理 build 目录"
