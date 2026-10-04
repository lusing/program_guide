# Build and run every example in this tutorial, then judge each one.
#
#   .\build.ps1                           everything: build if stale, then run
#   .\build.ps1 -Examples 02-vector-add   one example, by directory name or prefix
#   .\build.ps1 -Chapter 03               legacy alias: every chapter-03 example
#   .\build.ps1 -SkipRun                  compile only
#   .\build.ps1 -Rebuild                  recompile even when the exe is fresh
#   .\build.ps1 -List                     list targets
#   .\build.ps1 -Clean                    delete the build directory
#
# Covers both example generations living in examples\:
#   01-device-query .. 11-ocl3-features   current tutorial (dash names)
#   02_envcheck .. 31_autotune            legacy chapters (underscore names)
#
# Toolchain discovery (vcvars64, OpenCL SDK, SPIR-V clang) is NOT hardcoded
# here: it lives in tools\opencl-sdk.ps1, dot-sourced below, so the search
# order is written in exactly one place. The previous version of this script
# hardcoded G:\cuda\v13.3 and an MSYS2 clang path; both rotted when the
# toolchain moved to D:\cuda\13.3 / oneAPI and every compile died with
# fatal error C1083 (CL/cl.h not found).
#
# Incremental by default: an example is recompiled only when its exe is
# missing or older than its sources (main.c/.cpp, *.h/*.hpp in the example
# directory, and the shared headers in examples\common). Kernels (*.cl) are
# compiled by the device at run time, so editing one does not need -Rebuild.
#
# Judging rule, one rule for every example (examples\common\ocl_util.h):
# exit code 0 AND the output contains PASS AND no explicit "[RESULT] FAIL".
# Per-device diagnostic lines are NOT failures: 11-ocl3-features prints an
# indented "[FAIL] subgroup: ..." line for the NVIDIA device on purpose -
# reporting that a device lacks a feature is the subject of that example -
# and still ends "[RESULT] PASS". The verdict contract is the exit code plus
# the final [RESULT] line, not the absence of the substring FAIL.
# A final "[RESULT] SKIP" (09-spirv-il without any .spv on the machine) is
# accepted as green, not failed: build-spirv.ps1 and this script deliberately
# stay independent. Logs land in build\logs\<example>.txt.
#
# Pure ASCII: Windows PowerShell 5.1 parses a BOM-less .ps1 as the OEM code
# page and a Chinese string literal then dies with "string is missing the
# terminator" (docs/02-environment-setup.md section 2.10.1). Runs on both
# powershell.exe 5.1 and pwsh 7.
param(
    [switch]$All,       # legacy no-op: building everything is already the default
    [string]$Examples,  # one example by directory name or prefix
    [string]$Chapter,   # legacy two-digit chapter number, e.g. 03
    [switch]$List,
    [switch]$Clean,
    [switch]$SkipRun,
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$buildDir    = Join-Path $projectRoot 'build'
$logDir      = Join-Path $buildDir 'logs'
$examplesDir = Join-Path $projectRoot 'examples'
$commonDir   = Join-Path $examplesDir 'common'

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force -Confirm:$false
        Write-Host '[Clean] build directory removed.' -ForegroundColor Yellow
    } else {
        Write-Host '[Clean] build directory does not exist.' -ForegroundColor Yellow
    }
    exit 0
}

. (Join-Path $projectRoot 'tools\opencl-sdk.ps1')

$vcvars = Find-VcVars64
$sdk    = Find-OpenCLSDK
Write-Host "vcvars64   : $vcvars"
Write-Host "OpenCL SDK : $($sdk.Root)"
Write-Host "  include  : $($sdk.Include)"
Write-Host "  lib      : $($sdk.Lib)"

# Legacy chapter 16 precompiles kernel_spirv.cl with an offline SPIR-V clang.
# The CURRENT generation's SPIR-V needs are deliberately NOT handled here:
# build-spirv.ps1 owns examples\09-spirv-il and stays independent, so a
# machine without any SPIR-V toolchain still gets a green run.
$spirvClang = Find-SpirvClang

# Extra link libraries per chapter-number prefix.
$extraLink = @{ '29' = 'd3d11.lib dxgi.lib' }

# C++ sources must define the cl.hpp macro pair alongside CL_TARGET_OPENCL_VERSION,
# and the two MUST agree. CL_HPP_MINIMUM_OPENCL_VERSION must be 200, not 120: 120
# is the single value where cl.hpp calls detail::getContextPlatformVersion without
# defining it (12 errors, C2039/C3861). See docs/02-environment-setup.md 2.6.3,
# measured by tools/cpp-header-probe variants 3, 4, 11 and 12.
$cppExtra = @(
    '/DCL_HPP_ENABLE_EXCEPTIONS',
    '/DCL_HPP_TARGET_OPENCL_VERSION=300',
    '/DCL_HPP_MINIMUM_OPENCL_VERSION=200'
)

function Get-Targets {
    Get-ChildItem $examplesDir -Directory |
        Where-Object { $_.Name -match '^\d{2}[-_]' -and $_.Name -ne 'common' } |
        Sort-Object Name
}

# True when the exe is missing or older than any source it is built from.
function Test-ExeStale {
    param([string]$Exe, [string]$Dir)
    if (-not (Test-Path -LiteralPath $Exe)) { return $true }
    $exeTime = (Get-Item -LiteralPath $Exe).LastWriteTimeUtc
    $watch = @(Get-ChildItem -LiteralPath $Dir -Recurse -File |
        Where-Object { $_.Extension -in '.c', '.cpp', '.h', '.hpp' })
    $watch += @(Get-ChildItem -LiteralPath $commonDir -Recurse -File |
        Where-Object { $_.Extension -in '.h', '.hpp' })
    foreach ($f in $watch) {
        if ($f.LastWriteTimeUtc -gt $exeTime) { return $true }
    }
    return $false
}

function Invoke-PreSteps {
    param([string]$Name)
    if ($Name -ne '16_binary_spirv') { return }
    $dir = Join-Path $examplesDir $Name
    $src = Join-Path $dir 'kernel_spirv.cl'
    $dst = Join-Path $dir 'kernel_spirv.spv'
    if ($spirvClang) {
        Write-Host '  [pre] clang -> kernel_spirv.spv' -ForegroundColor DarkCyan
        # Each argument is a single-quoted literal: PowerShell (5.1 AND 7.x)
        # splits a native argument at its first dot, so '-cl-std=CL1.2' must
        # arrive quoted to stay one token.
        & $spirvClang '-cl-std=CL1.2' '-target' 'spirv64' '-c' $src '-o' $dst
        if ($LASTEXITCODE -ne 0) { throw 'chapter 16 SPIR-V precompile failed' }
    } else {
        Write-Host '  [pre] no SPIR-V clang found, precompile skipped (example takes its SKIP branch)' -ForegroundColor DarkYellow
    }
}

function Invoke-BuildOne {
    param([string]$Name, [string]$MainPath)

    $exe = Join-Path $buildDir "$Name.exe"
    $obj = Join-Path $buildDir "$Name.obj"
    $num = $Name.Substring(0, 2)

    if (-not $Rebuild -and -not (Test-ExeStale -Exe $exe -Dir (Split-Path -Parent $MainPath))) {
        Write-Host '  [skip] exe is up to date (-Rebuild to force)' -ForegroundColor DarkGray
        return
    }
    if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }

    $ext = [System.IO.Path]::GetExtension($MainPath).ToLowerInvariant()
    if ($ext -eq '.c') {
        $lang = @('/TC')
    } else {
        $lang = @('/TP', '/std:c++17') + $cppExtra
    }
    $libs = 'OpenCL.lib'
    if ($extraLink.ContainsKey($num)) { $libs = $libs + ' ' + $extraLink[$num] }

    # Switches are passed UNQUOTED; Invoke-ClCompile adds quotes where the
    # cmd.exe line needs them. Pre-quoting here leaves literal backslashes
    # in the final string and cl.exe misparses it.
    $clArgs = @($script:ClCommonFlags) + $lang + @(
        "/I$($sdk.Include)",
        "/I$commonDir",
        $MainPath,
        "/Fo:$obj",
        "/Fe:$exe",
        '/link',
        "/LIBPATH:$($sdk.Lib)",
        $libs
    )
    $code = Invoke-ClCompile -VcVars64 $vcvars -Arguments $clArgs
    if ($code -ne 0 -or -not (Test-Path -LiteralPath $exe)) {
        throw "compile failed (cl.exe exit $code): $Name"
    }
}

# Runs one example from its own directory (kernels and data files are relative
# paths) and applies the judging rule. Throws on failure; otherwise returns
# 'OK' or 'OK (SKIP)'.
function Invoke-RunOne {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    $exe = Join-Path $buildDir "$Name.exe"
    $logFile = Join-Path $logDir "$Name.txt"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.WorkingDirectory = $dir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $tOut = $p.StandardOutput.ReadToEndAsync()
    $tErr = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit(300000)) {
        try { $p.Kill($true) } catch { $p.Kill() }
        throw "run timeout (300s): $Name"
    }
    $out = $tOut.Result
    $err = $tErr.Result
    [System.IO.File]::WriteAllText($logFile, $out + "`n--- stderr ---`n" + $err, [System.Text.Encoding]::UTF8)
    Write-Host $out.TrimEnd() -ForegroundColor Gray
    if ($err.Trim()) { Write-Host "[stderr] $($err.Trim())" -ForegroundColor DarkYellow }

    if ($p.ExitCode -ne 0) { throw "exit code $($p.ExitCode): $Name" }
    if ($out -match '(?m)^\s*\[RESULT\]\s*SKIP\s*$') { return 'OK (SKIP)' }
    if ($out -notmatch '\bPASS\b') { throw "output contains no PASS: $Name" }
    if ($out -match '\[RESULT\]\s*FAIL') { throw "explicit [RESULT] FAIL: $Name" }
    return 'OK'
}

# ---------------- entry ----------------

New-Item -ItemType Directory -Force -Path $buildDir, $logDir | Out-Null

$targets = @(Get-Targets)
if ($List) {
    $targets | ForEach-Object { Write-Host $_.Name }
    exit 0
}

$sel = $targets
if ($Examples) {
    $sel = @($sel | Where-Object { $_.Name -eq $Examples -or $_.Name.StartsWith($Examples) })
}
if ($Chapter) {
    $norm = $Chapter.PadLeft(2, '0')
    $sel = @($sel | Where-Object { $_.Name.StartsWith($norm) })
}
if (-not $sel -or $sel.Count -eq 0) { throw "no example directory matches -Examples '$Examples' / -Chapter '$Chapter'" }

$results = @()
$failed = @()
foreach ($t in $sel) {
    $name = $t.Name
    $dir = $t.FullName
    $main = $null
    foreach ($cand in @('main.c', 'main.cpp')) {
        $p2 = Join-Path $dir $cand
        if (Test-Path -LiteralPath $p2) { $main = $p2; break }
    }
    Write-Host "`n==== $name ====" -ForegroundColor Cyan
    if (-not $main) {
        Write-Host '[FAIL] no main.c/main.cpp in the example directory' -ForegroundColor Red
        $results += [pscustomobject]@{ Example = $name; Status = 'FAIL'; Seconds = 0 }
        $failed += $name
        continue
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 'OK'
    try {
        Invoke-PreSteps -Name $name
        Invoke-BuildOne -Name $name -MainPath $main
        if (-not $SkipRun) {
            $runStatus = Invoke-RunOne -Name $name
            $status = $runStatus
        } else {
            $status = 'OK (build only)'
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $status = 'FAIL'
        $failed += $name
    }
    $sw.Stop()
    $results += [pscustomobject]@{
        Example = $name
        Status  = $status
        Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    }
    if ($status -ne 'FAIL') { Write-Host "==== $name ok ====" -ForegroundColor Green }
}

Write-Host "`n==== summary ===="
$results | Format-Table -AutoSize | Out-String -Width 120 | ForEach-Object { Write-Host $_.TrimEnd() }

if ($failed.Count -gt 0) {
    Write-Host "failed: $($failed -join ', ')  (logs: build\logs\)" -ForegroundColor Red
    exit 1
}
$verb = 'built and ran'
if ($SkipRun) { $verb = 'built' }
Write-Host "[Done] $verb $($results.Count) example(s), no failures." -ForegroundColor Green
exit 0
