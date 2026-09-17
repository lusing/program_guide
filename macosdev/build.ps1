# ============================================================================
# macOS 应用开发教程（macosdev）—— PowerShell 入口
#
#   pwsh ./build.ps1 -All          跑全部示例
#   pwsh ./build.ps1 -Only 07,08   只跑编号 07、08
#   pwsh ./build.ps1 -Clean        清空 build/
#
# 与 run-all.sh 完全等价：同样的六条判定、同样的双工具链通道比对、同样的
# XIB 静态检查。两条入口的存在意义是互证 —— 同一份示例在两条脚本下结论一致，
# 才能说明判定的不是脚本自己的 bug。
#
# 六条判定：
#   1) 编译日志为空（零告警，含 ibtool）
#   2) 退出码为 0
#   3) stderr 为空
#   4) stdout 非空
#   5) stdout 无多余控制字符（0..31 除 TAB/LF/CR）
#   6) stdout 有结束标记 "==== NN 结束 ===="
# ============================================================================
[CmdletBinding()]
param(
    [switch]$All,
    [string[]]$Only = @(),
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

# 坑：用 pwsh -File 调脚本时，命令行上的 "01,04" 是**一个字符串**而不是数组
# （只有 -Command 才会把它当数组字面量）。这里统一按逗号拆开，两种写法都能用。
if ($Only) { $Only = @($Only | ForEach-Object { ($_ -split ',') | Where-Object { $_ -ne '' } }) }

$TOP = Split-Path -Parent $MyInvocation.MyCommand.Path
$EXAMPLES = Join-Path $TOP 'examples'
$BUILD = Join-Path $TOP 'build'
$TOOLS = Join-Path $TOP 'tools'

$HOST_ARCH = (& uname -m).Trim()
$DEPLOY_TARGET = "$HOST_ARCH-apple-macos12.0"

$CLT_SDK = '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk'
$XCODE_ROOT = '/Applications/Xcode.app/Contents/Developer'
$XCODE_XT = Join-Path $XCODE_ROOT 'Toolchains/XcodeDefault.xctoolchain'
$XCODE_SDK = Join-Path $XCODE_ROOT 'Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'

$IBTOOL = Join-Path $XCODE_ROOT 'usr/bin/ibtool'
$IBTOOL_TIMEOUT = 180
$RUN_TIMEOUT = 60

# ------------------------------------------------------------------ 工具函数 --
function Write-Line([string]$s) { Write-Output $s }

function Get-LaneSdk([string]$lane) {
    if ($lane -eq 'xcode') { return $XCODE_SDK } else { return $CLT_SDK }
}
function Get-LaneSwiftc([string]$lane) {
    if ($lane -eq 'xcode') { return (Join-Path $XCODE_XT 'usr/bin/swiftc') } else { return '/usr/bin/swiftc' }
}
function Get-LaneClang([string]$lane) {
    if ($lane -eq 'xcode') { return (Join-Path $XCODE_XT 'usr/bin/clang') } else { return '/usr/bin/clang' }
}

$LANES = @()
if ((Test-Path (Get-LaneSwiftc 'clt')) -and (Test-Path (Get-LaneClang 'clt')) -and (Test-Path (Get-LaneSdk 'clt'))) {
    $LANES += 'clt'
}
if ((Test-Path (Get-LaneSwiftc 'xcode')) -and (Test-Path (Get-LaneClang 'xcode')) -and (Test-Path (Get-LaneSdk 'xcode'))) {
    $LANES += 'xcode'
}
if ($LANES.Count -eq 0) {
    Write-Line '错误：没有找到任何可用的 Swift 工具链'
    exit 1
}

function Test-HasCtrl([string]$path) {
    if (-not (Test-Path $path)) { return $true }
    $text = Get-Content -Raw -Encoding UTF8 $path
    if ($null -eq $text) { return $false }
    foreach ($ch in $text.ToCharArray()) {
        $code = [int]$ch
        if ($code -lt 32 -and $code -ne 9 -and $code -ne 10 -and $code -ne 13) { return $true }
    }
    return $false
}

function Test-Marker([string]$path, [string]$marker) {
    if (-not (Test-Path $path)) { return $false }
    $text = Get-Content -Raw -Encoding UTF8 $path
    if ($null -eq $text) { return $false }
    return $text.Contains($marker)
}

# gtimeout 未必存在（coreutils 装在 /opt/local/bin 下）
$TIMEOUT_BIN = $null
foreach ($candidate in @('/opt/local/bin/gtimeout', '/usr/local/bin/gtimeout', '/usr/bin/timeout')) {
    if (Test-Path $candidate) { $TIMEOUT_BIN = $candidate; break }
}

function Invoke-Run([string]$workDir, [string]$exe, [string]$outFile, [string]$errFile) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = '--selftest'
    $psi.WorkingDirectory = $workDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    # 自己实现超时：WaitForExit(int) 之后强杀
    if (-not $proc.WaitForExit($RUN_TIMEOUT * 1000)) {
        try { $proc.Kill() } catch { }
        $proc.WaitForExit(5000) | Out-Null
    }
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    [System.IO.File]::WriteAllText($outFile, $stdout)
    [System.IO.File]::WriteAllText($errFile, $stderr)
    return $proc.ExitCode
}

function Invoke-Tool([string[]]$argv, [string]$workDir, [string]$logFile) {
    # argv[0] 是程序，其余是参数；返回退出码，输出写进 logFile
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $argv[0]
    $psi.WorkingDirectory = $workDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    for ($i = 1; $i -lt $argv.Count; $i++) {
        $psi.ArgumentList.Add($argv[$i])
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    $timeoutMs = ($IBTOOL_TIMEOUT * 1000)
    if (-not $proc.WaitForExit($timeoutMs)) {
        try { $proc.Kill() } catch { }
        $proc.WaitForExit(5000) | Out-Null
    }
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $combined = ($stdout + $stderr)
    if ($logFile) { [System.IO.File]::WriteAllText($logFile, $combined) }
    return $proc.ExitCode
}

# --------------------------------------------------------------------- 主流程 --
if ($Clean) {
    if (Test-Path $BUILD) { Remove-Item -Recurse -Force (Join-Path $BUILD '*') -ErrorAction SilentlyContinue }
    Write-Line "已清空 $BUILD"
    exit 0
}

$names = @()
# 坑：Get-ChildItem 的 -Filter 用的是文件系统提供程序的通配语法，
# 它**不支持** [0-9] 这种字符区间，写 '[0-9][0-9]_*' 会一个都匹配不到
# （症状就是脚本一路走到「没有匹配到示例」）。要用 -match 正则筛。
Get-ChildItem -Path $EXAMPLES -Directory | Where-Object { $_.Name -match '^\d\d_' } | Sort-Object Name | ForEach-Object {
    $d = $_.Name
    $keep = $true
    if ($Only.Count -gt 0) {
        $keep = $false
        foreach ($want in $Only) {
            if ($d -like "${want}_*" -or $d -eq $want) { $keep = $true }
        }
    }
    if ($keep) { $names += $d }
}
if ($names.Count -eq 0) {
    Write-Line '没有匹配到示例'
    exit 1
}

# --- XIB 静态一致性检查 ---
$checkXib = Join-Path $TOOLS 'check_xib.py'
if (Test-Path $checkXib) {
    Write-Line '=== XIB 静态一致性检查 ==='
    $py = 'python3'
    $rc = Invoke-Tool -argv @($py, $checkXib, $EXAMPLES) -workDir $TOP -logFile (Join-Path $TOP 'xibcheck.log')
    Get-Content (Join-Path $TOP 'xibcheck.log') | ForEach-Object { Write-Line $_ }
    Remove-Item (Join-Path $TOP 'xibcheck.log') -ErrorAction SilentlyContinue
    if ($rc -ne 0) { exit 1 }
    Write-Line ''
}

Write-Line '=== 工具链 ==='
foreach ($lane in $LANES) {
    Write-Line "  $lane : swiftc=$(Get-LaneSwiftc $lane)"
    Write-Line "          clang =$(Get-LaneClang $lane)"
    Write-Line "          sdk   =$(Get-LaneSdk $lane)"
}
Write-Line "  部署目标 = $DEPLOY_TARGET"
Write-Line ''

$script:PASS = 0
$script:FAIL = 0
$script:DIFF = 0
$failureLines = @()

foreach ($name in $names) {
    $nn = ($name -split '_')[0]
    $marker = "==== $nn 结束 ===="
    $dir = Join-Path $EXAMPLES $name
    $outdir = Join-Path $BUILD $name
    if (-not (Test-Path $outdir)) { New-Item -ItemType Directory -Path $outdir -Force | Out-Null }
    Write-Line "[$name]"

    # --- XIB 编译 ---
    $xibFailed = $false
    Get-ChildItem -Path $dir -Filter '*.xib' -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
        $xib = $_.FullName
        $base = [System.IO.Path]::GetFileNameWithoutExtension($xib)
        $nibOut = Join-Path $outdir "$base.nib"
        Write-Line "        [ibtool] $($_.Name) -> $base.nib"
        $env:DEVELOPER_DIR = $XCODE_ROOT
        $log = Join-Path $outdir "ibtool.$base.log"
        $rc = Invoke-Tool -argv @($IBTOOL, '--compile', $nibOut, $xib) -workDir $outdir -logFile $log
        if ($rc -ne 0) {
            Write-Line "        ibtool 编译失败（退出码 $rc）：$log"
            $script:FAIL++
            $failureLines += "失败: $name XIB 编译阶段失败"
            $xibFailed = $true
        } elseif ((Get-Item $log).Length -gt 0) {
            Write-Line "        ibtool 有告警（日志非空）：$log"
            $script:FAIL++
            $failureLines += "失败: $name ibtool 告警"
            $xibFailed = $true
        }
    }
    if ($xibFailed) { continue }

    $mod = $name.Substring($name.IndexOf('_') + 1)

    foreach ($lane in $LANES) {
        $swiftc = Get-LaneSwiftc $lane
        $clang = Get-LaneClang $lane
        $sdk = Get-LaneSdk $lane
        $log = Join-Path $outdir "build.$lane.log"
        Set-Content -Path $log -Value '' -Encoding UTF8

        $swiftFiles = @(Get-ChildItem -Path $dir -Filter '*.swift' -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.FullName })
        $mFiles = @(Get-ChildItem -Path $dir -Filter '*.m' -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.FullName })

        $frameworks = @()
        $fwFile = Join-Path $dir 'Frameworks'
        if (Test-Path $fwFile) {
            foreach ($raw in (Get-Content $fwFile)) {
                $line = ($raw -split '#')[0] -replace '\s', ''
                if ($line -ne '') { $frameworks += @('-framework', $line) }
            }
        }

        $bridge = $null
        foreach ($candidate in @((Join-Path $dir 'Bridging.h'), (Join-Path $dir 'bridging.h'))) {
            if (Test-Path $candidate) { $bridge = $candidate }
        }

        $bin = Join-Path $outdir "$name.$lane"
        $built = $false

        if ($mFiles.Count -eq 0) {
            # 纯 Swift
            $argv = @($swiftc, '-O', '-sdk', $sdk, '-target', $DEPLOY_TARGET, '-module-name', $mod)
            $argv += $swiftFiles
            $argv += @('-o', $bin, '-framework', 'Foundation', '-framework', 'AppKit')
            $argv += $frameworks
            $rc = Invoke-Tool -argv $argv -workDir $outdir -logFile $log
            $built = ($rc -eq 0)
        } elseif ($swiftFiles.Count -eq 0) {
            # 纯 Objective-C
            $argv = @($clang, '-O2', '-std=gnu11', '-fobjc-arc', '-fmodules',
                      '-Wall', '-Wextra', '-Wno-unused-parameter', '-isysroot', $sdk,
                      '-target', $DEPLOY_TARGET, '-I', $dir)
            $argv += $mFiles
            $argv += @('-o', $bin, '-framework', 'Foundation', '-framework', 'AppKit')
            $argv += $frameworks
            $rc = Invoke-Tool -argv $argv -workDir $outdir -logFile $log
            $built = ($rc -eq 0)
        } else {
            # Swift + Objective-C 混编：先编 Swift（顺带生成 Swift 头文件）
            $needHeader = Test-Path (Join-Path $dir 'Needs-Swift-Header')
            $argv = @($swiftc, '-c', '-sdk', $sdk, '-target', $DEPLOY_TARGET, '-module-name', $mod)
            if ($bridge) { $argv += @('-import-objc-header', $bridge) }
            if ($needHeader) { $argv += @('-emit-objc-header-path', (Join-Path $outdir 'SwiftBridge-Swift.h')) }
            $argv += $swiftFiles
            # 坑：swiftc -c 把 .o 写在当前目录，所以工作目录必须是 $outdir
            $rc = Invoke-Tool -argv $argv -workDir $outdir -logFile $log
            if ($rc -ne 0) {
                $built = $false
            } else {
                $swiftObjs = @($swiftFiles | ForEach-Object {
                    Join-Path $outdir ([System.IO.Path]::GetFileNameWithoutExtension($_) + '.o')
                })
                $cObjs = @()
                foreach ($m in $mFiles) {
                    $obase = [System.IO.Path]::GetFileNameWithoutExtension($m)
                    $objOut = Join-Path $outdir "$obase.$lane.o"
                    $cargv = @($clang, '-c', '-O2', '-std=gnu11', '-fobjc-arc', '-fmodules',
                               '-Wall', '-Wextra', '-Wno-unused-parameter', '-isysroot', $sdk,
                               '-target', $DEPLOY_TARGET, '-I', $dir, '-I', $outdir, $m, '-o', $objOut)
                    $crc = Invoke-Tool -argv $cargv -workDir $outdir -logFile (Join-Path $outdir "cc.$obase.$lane.log")
                    if ($crc -ne 0) { $built = $false; break }
                    $cObjs += $objOut
                }
                if ($cObjs.Count -eq $mFiles.Count) {
                    $largv = @($swiftc, '-sdk', $sdk, '-target', $DEPLOY_TARGET)
                    $largv += $swiftObjs
                    $largv += $cObjs
                    $largv += @('-o', $bin, '-framework', 'Foundation', '-framework', 'AppKit')
                    $largv += $frameworks
                    $lrc = Invoke-Tool -argv $largv -workDir $outdir -logFile (Join-Path $outdir "link.$lane.log")
                    $built = ($lrc -eq 0)
                }
            }
        }

        if (-not $built) {
            Write-Line "      [$lane] 构建失败"
            Get-Content $log -ErrorAction SilentlyContinue | Select-Object -First 25 | ForEach-Object { Write-Line "        $_" }
            $script:FAIL++
            $failureLines += "失败: $name [$lane] 构建失败"
            continue
        }

        # 合并所有编译日志，统一判「有没有告警」
        $allLogs = @($log) + @(Get-ChildItem -Path $outdir -Filter "cc.*.$lane.log" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        $allLogs += @(Get-ChildItem -Path $outdir -Filter "link.$lane.log" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        $logNonEmpty = $false
        foreach ($l in $allLogs) {
            if ((Test-Path $l) -and ((Get-Item $l).Length -gt 0)) { $logNonEmpty = $true }
        }

        $outFile = Join-Path $outdir "stdout.$lane.txt"
        $errFile = Join-Path $outdir "stderr.$lane.txt"
        $code = Invoke-Run -workDir $outdir -exe $bin -outFile $outFile -errFile $errFile
        Set-Content -Path (Join-Path $outdir "exit.$lane") -Value "$code" -Encoding UTF8

        $why = @()
        if ($logNonEmpty) { $why += '编译日志非空（有告警）' }
        if ($code -ne 0) { $why += "退出码 $code" }
        $errText = Get-Content -Raw -Encoding UTF8 $errFile
        if ($errText -and $errText.Trim().Length -gt 0) { $why += 'stderr 非空' }
        if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -eq 0) { $why += 'stdout 为空' }
        if (Test-HasCtrl $outFile) { $why += '输出含多余控制字符' }
        if (-not (Test-Marker $outFile $marker)) { $why += '缺少结束标记' }

        if ($why.Count -eq 0) {
            Write-Line "      [$lane] PASS"
            $script:PASS++
        } else {
            Write-Line "      [$lane] FAIL —— $($why -join '、')"
            $script:FAIL++
            $failureLines += "失败: $name [$lane] $($why -join '、')"
        }
    }

    # --- 双通道输出逐字节比对 ---
    if ($LANES.Count -eq 2) {
        $a = Join-Path $outdir 'stdout.clt.txt'
        $b = Join-Path $outdir 'stdout.xcode.txt'
        if ((Test-Path $a) -and (Test-Path $b)) {
            $ha = (Get-FileHash $a -Algorithm SHA256).Hash
            $hb = (Get-FileHash $b -Algorithm SHA256).Hash
            if ($ha -eq $hb) {
                Write-Line '      [cmp] 双工具链输出逐字节一致'
            } else {
                Write-Line '      [cmp] DIFF —— 两套工具链输出不一样'
                $script:DIFF++
                $failureLines += "差异: $name 两套工具链输出不一致"
            }
        }
    }
}

Write-Line ''
Write-Line '=========================================================='
Write-Line " 通过 $script:PASS   失败 $script:FAIL   输出差异 $script:DIFF   示例 $($names.Count)   通道 $($LANES.Count)"
foreach ($line in $failureLines) { Write-Line "  $line" }
Write-Line '=========================================================='
if ($script:FAIL -ne 0 -or $script:DIFF -ne 0) { exit 1 }
exit 0
