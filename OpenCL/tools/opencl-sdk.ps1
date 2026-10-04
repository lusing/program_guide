# Shared environment discovery for every build script in this tutorial.
# Dot-sourced by OpenCL/build.ps1, OpenCL/build-spirv.ps1 and tools/*/build.ps1
# so the SDK search order lives in exactly one place.
#
# Pure ASCII on purpose: Windows PowerShell 5.1 decodes a BOM-less .ps1 as the
# OEM code page (cp936 here), and a Chinese string literal then dies with
# "string is missing the terminator". Keep this file ASCII and it parses anywhere.

# Locate vcvars64.bat through vswhere, the same way WinUI3/build.ps1 finds MSBuild.
function Find-VcVars64 {
    $vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $installPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null |
            Select-Object -First 1
        if ($installPath) {
            $candidate = Join-Path $installPath 'VC\Auxiliary\Build\vcvars64.bat'
            if (Test-Path $candidate) { return $candidate }
        }
    }
    throw 'vcvars64.bat not found; install Visual Studio with the "Desktop development with C++" workload.'
}

# Find an OpenCL SDK: a directory holding both include\CL\cl.h and an OpenCL.lib.
#
# The candidate order matters. D:\cuda\13.3 is tried first because it is the only
# SDK on this machine that ships the C++ bindings header <CL/cl.hpp>; the oneAPI
# compiler ships no OpenCL C++ header at all (verified 2026-09-17), so chapter 07
# and examples/08-cpp-bindings can only build against the CUDA one.
#
# Note the two different lib layouts: CUDA puts the import library in lib\x64,
# oneAPI puts it directly in lib. Both are probed.
function Find-OpenCLSDK {
    $roots = @()
    if ($env:OPENCL_ROOT) { $roots += $env:OPENCL_ROOT }
    $roots += 'D:\cuda\13.3'
    if ($env:CUDA_PATH) { $roots += $env:CUDA_PATH }
    $roots += 'D:\oneAPI\compiler\latest'

    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path $root)) { continue }
        $include = Join-Path $root 'include'
        if (-not (Test-Path (Join-Path $include 'CL\cl.h'))) { continue }
        foreach ($libRel in @('lib\x64', 'lib')) {
            $lib = Join-Path $root $libRel
            if (Test-Path (Join-Path $lib 'OpenCL.lib')) {
                return [pscustomobject]@{ Root = $root; Include = $include; Lib = $lib }
            }
        }
    }

    $msg = @(
        'No OpenCL SDK found. Probed these roots for include\CL\cl.h + OpenCL.lib:'
        ($roots | ForEach-Object { "  - $_" })
        'Set $env:OPENCL_ROOT to an SDK root, or install the CUDA Toolkit / Intel oneAPI.'
    ) -join "`n"
    throw $msg
}

# Find the oneAPI clang used for offline SPIR-V compilation.
function Find-SpirvClang {
    $candidates = @(
        'D:\oneAPI\compiler\latest\bin\compiler\clang.exe',
        'D:\oneAPI\compiler\latest\bin\clang.exe'
    )
    if ($env:CMPLR_ROOT) { $candidates = @(Join-Path $env:CMPLR_ROOT 'bin\compiler\clang.exe') + $candidates }
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    return $null
}

# Run cl.exe with the MSVC environment loaded.
#
# Everything is assembled into ONE command string and handed to cmd.exe, because
# Windows PowerShell 5.1 splits a native argument AT ITS FIRST DOT: -cl-std=CL1.2
# reaches the child process as "-cl-std=CL1" plus a stray ".2" file argument. The
# equals sign stays with the left fragment; the dot is the trigger, not the "=".
# Measured with clang as an argv oracle over five inline literals - =1.2 splits,
# =12 does not, =x.y splits, =xy does not, =1.2.3 splits at the first dot. Quoting
# the token keeps it whole, and pwsh 7.6 has the identical bug, so upgrading the
# shell is not a fix. A single cmd string sidesteps the question entirely.
#
# Callers pass switches UNQUOTED ("/I$($sdk.Include)", "/Fe:$exe"); this function
# adds quotes where cmd needs them. Pre-quoting at the call site produces literal
# backslashes in the final string and cl.exe misparses it.
#
# Returns cl.exe's exit code. Never nest bash -> powershell -> cmd around this;
# two levels (powershell -> cmd) is what has been verified to preserve quoting.
function Invoke-ClCompile {
    param(
        [Parameter(Mandatory)][string]$VcVars64,
        [Parameter(Mandatory)][string[]]$Arguments,
        # Return the compiler's output as data instead of streaming it to the host.
        # Needed by tools/cpp-header-probe, whose whole job is to collect and count
        # error text; the default streaming behaviour is right for every other caller.
        [switch]$Capture
    )
    $escaped = foreach ($a in $Arguments) {
        if ($a -match '[\s&|<>^]') { '"' + $a + '"' } else { $a }
    }
    $line = 'call "' + $VcVars64 + '" >nul 2>&1 && cl ' + ($escaped -join ' ')

    # Capture, then read the exit code, then echo. Anything emitted to the pipeline
    # becomes part of a PowerShell function's return value, so letting cmd's stdout
    # stream straight through makes this function return @(<cl output...>, $code)
    # and callers see "$code -ne 0" as the string "clinfo-probe.c 0".
    $output = & cmd.exe /c $line 2>&1
    $code = $LASTEXITCODE
    if ($Capture) {
        return [pscustomobject]@{ Code = $code; Output = @($output | ForEach-Object { "$_" }) }
    }
    foreach ($l in $output) { Write-Host $l }
    return $code
}

# Standard compile flags for every host program in this tutorial.
#
# CL_TARGET_OPENCL_VERSION=300 is deliberate and must not be lowered to 120:
# at 120 the headers hide every 2.x entry point, so clCreateCommandQueueWithProperties
# and clCreateProgramWithIL fail to compile (measured: exit 2). C++ sources must
# additionally define CL_HPP_TARGET_OPENCL_VERSION to the SAME value: cl.hpp does not
# raise CL_TARGET_OPENCL_VERSION, it only warns (cl.hpp:452-461), so a 120 C target
# under a 300 C++ target leaves 42 identifiers undefined, the first being
# CL_DEVICE_QUEUE_ON_HOST_PROPERTIES. tools/cpp-header-probe variants 3 and 4 show
# the macro NAME enabling exceptions makes no difference to that outcome.
#
# CL_HPP_MINIMUM_OPENCL_VERSION must be 200, not 120, whenever the target is 300 -
# 120 is the one value where cl.hpp calls detail::getContextPlatformVersion without
# defining it. See cpp-header-probe variants 7, 11 and 12.
$script:ClCommonFlags = @(
    '/nologo', '/utf-8', '/W3', '/EHsc',
    '/D_CRT_SECURE_NO_WARNINGS',
    '/DCL_TARGET_OPENCL_VERSION=300'
)
