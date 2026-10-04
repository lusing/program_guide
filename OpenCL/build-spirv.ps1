# Compile the OpenCL C kernels to SPIR-V OFFLINE, ahead of any device.
#
#   .\build-spirv.ps1                 produce every module, validate, report
#   .\build-spirv.ps1 -SkipValidate   do not look for spirv-val
#   .\build-spirv.ps1 -Route backend  only the clang SPIR-V backend
#   .\build-spirv.ps1 -Route cpp      only the OpenCL C++ source
#
# OpenCL/build.ps1 does NOT call this. examples/09-spirv-il prints "[RESULT] SKIP"
# when no .spv is present, so the two scripts stay independent: a reader without a
# SPIR-V toolchain still gets a green build of every other example.
#
# Three modules are produced from two source files, because the routes are NOT
# equivalent and chapter 08 would be guessing if it said otherwise:
#
#   backend     clang -c -target spirv64-unknown-unknown      -> SPIR-V 1.4
#   translator  clang -c -emit-llvm ... | llvm-spirv           -> SPIR-V 1.0
#   cpp         clang -c -target spirv64 ... -cl-std=CLC++     -> SPIR-V 1.4
#
# backend and translator compile the SAME file, kernels\vector_add.cl, so every
# difference between their modules comes from the toolchain. cpp compiles
# kernels\vector_add_cpp.cl, which expresses the same computation through a template
# and a static member function, so the difference between its module and the backend
# module comes from the SOURCE language - and this script measures that difference
# instruction by instruction rather than assuming it away.
#
# Same kernel, same machine, and on the Intel iGPU only the backend and cpp modules
# run. See tools/spirv-route-probe for the measurement and docs/08-spirv.md for the
# reason.
#
# The version is READ BACK from each produced file rather than reported from the
# command line. That is deliberate: the backend route has no flag that lowers its
# output version - the driver rejects --spirv-max-version, and so do -Xclang and
# -mllvm - so the only honest statement about what it produced is the one taken
# from the file's own header word.
#
# Pure ASCII: see tools/opencl-sdk.ps1 for why.
param(
    [ValidateSet('all', 'backend', 'translator', 'cpp')]
    [string]$Route = 'all',
    [switch]$SkipValidate
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $repoRoot 'tools\opencl-sdk.ps1')

$clang = Find-SpirvClang
if (-not $clang) {
    Write-Host @'
No SPIR-V compiler found. Probed:
  D:\oneAPI\compiler\latest\bin\compiler\clang.exe
  D:\oneAPI\compiler\latest\bin\clang.exe
  $env:CMPLR_ROOT\bin\compiler\clang.exe

Install Intel oneAPI, or set $env:CMPLR_ROOT to the compiler root. This is NOT a
build failure for the rest of the tutorial: examples/09-spirv-il reports SKIP when
no .spv exists, and every other example compiles from source at run time.
'@
    exit 0
}

$clangDir = Split-Path -Parent $clang
$llvmSpirv = Join-Path $clangDir 'llvm-spirv.exe'

Write-Host "clang      : $clang"
$verLine = (& $clang --version 2>&1 | Select-Object -First 1)
Write-Host "  version  : $verLine"
Write-Host "llvm-spirv : $(if (Test-Path $llvmSpirv) { $llvmSpirv } else { 'MISSING (translator route unavailable)' })"

# spirv-val and spirv-dis come from SPIRV-Tools, which on this machine is shipped by
# the Vulkan SDK rather than by oneAPI. Both are OPTIONAL: a module that cannot be
# validated is still produced and still loaded by the driver, so their absence is
# reported as a gap in the evidence, never as a failure.
$spirvVal = $null
$spirvDis = $null
if (-not $SkipValidate) {
    $c = Get-Command spirv-val -ErrorAction SilentlyContinue
    if ($c) { $spirvVal = $c.Source }
    $c = Get-Command spirv-dis -ErrorAction SilentlyContinue
    if ($c) { $spirvDis = $c.Source }
}
Write-Host "spirv-val  : $(if ($spirvVal) { $spirvVal } else { 'not on PATH (validation skipped)' })"
Write-Host "spirv-dis  : $(if ($spirvDis) { $spirvDis } else { 'not on PATH' })"

# Read a little-endian uint32 at a byte offset out of a produced module.
function Get-SpvWord([string]$path, [int]$offset) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    return [System.BitConverter]::ToUInt32($bytes, $offset)
}

# Decode the five-word SPIR-V header into something a reader can check against
# spirv-dis. Word 1 is major<<16 | minor<<8; word 2 is toolVersion<<16 | toolId.
# The tool id is what separates the two routes at a glance: 21 is the LLVM SPIR-V
# backend, 14 is the Khronos LLVM/SPIR-V Translator.
$toolNames = @{ 21 = 'LLVM SPIR-V Backend'; 14 = 'LLVM/SPIR-V Translator'; 6 = 'LLVM/SPIR-V Translator' }
function Get-SpvHeader([string]$path) {
    $magic = Get-SpvWord $path 0
    $ver = Get-SpvWord $path 4
    $gen = Get-SpvWord $path 8
    $bound = Get-SpvWord $path 12
    $tool = $gen -band 0xFFFF
    $name = if ($toolNames.ContainsKey([int]$tool)) { $toolNames[[int]$tool] } else { "tool $tool" }
    return [pscustomobject]@{
        MagicOk = ('0x{0:X8}' -f $magic) -eq '0x07230203'
        Version = '{0}.{1}' -f (($ver -shr 16) -band 0xFFFF), (($ver -shr 8) -band 0xFF)
        Tool    = $name
        Bound   = $bound
        Bytes   = (Get-Item $path).Length
    }
}

# Invoke clang. Every argument carrying a dot is quoted, including '-cl-std=CL1.2':
# PowerShell splits a native argument at its first dot, handing clang "-cl-std=CL1"
# plus a stray ".2" filename. Quoting is sufficient and is verified on both Windows
# PowerShell 5.1 and pwsh 7.6, which share the bug - so upgrading the shell is not
# the fix, and shelling out to cmd.exe is unnecessary here.
function Invoke-Clang {
    param([string[]]$Arguments)
    $out = & $clang @Arguments 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Output = @($out | ForEach-Object { "$_" }) }
}

# Decode, validate and record one produced module. Every route ends here, so the
# header is read the same way each time and a route that skips validation shows up
# as a gap in the summary instead of a silent difference from the other two.
function Publish-Module {
    param(
        [Parameter(Mandatory)][string]$RouteName,
        [Parameter(Mandatory)][string]$Path
    )
    $h = Get-SpvHeader $Path
    Write-Host ("    {0} bytes | SPIR-V {1} | {2} | bound {3} | magic {4}" -f `
        $h.Bytes, $h.Version, $h.Tool, $h.Bound, $(if ($h.MagicOk) { 'ok' } else { 'BAD' }))
    $status = if ($h.MagicOk) { 'OK' } else { 'FAIL' }
    if (-not $h.MagicOk) { $script:failed++ }

    if ($spirvVal) {
        $v = & $spirvVal $Path 2>&1
        $vc = $LASTEXITCODE
        foreach ($l in $v) { Write-Host "    spirv-val: $l" }
        Write-Host "    spirv-val exit $vc"
        if ($vc -ne 0) { $status = 'FAIL'; $script:failed++ }
    } else {
        Write-Host "    spirv-val: unavailable, module NOT validated"
        $status = "$status (unvalidated)"
    }

    $rel = $Path.Substring($repoRoot.Length + 1)
    $script:results += [pscustomobject]@{
        Route  = $RouteName
        Status = $status
        File   = "$rel ($($h.Bytes) B, SPIR-V $($h.Version))"
    }
}

$exDir = Join-Path $repoRoot 'examples\09-spirv-il'
$kernel = Join-Path $exDir 'kernels\vector_add.cl'
$kernelCpp = Join-Path $exDir 'kernels\vector_add_cpp.cl'
$spvDir = Join-Path $exDir 'spv'
if (-not (Test-Path $spvDir)) { New-Item -ItemType Directory -Path $spvDir | Out-Null }

if (-not (Test-Path $kernel)) { throw "kernel not found: $kernel" }

# The language level is pinned to CL1.2 even though the backend route would happily
# accept CL2.0 and CL3.0. The iGPU this tutorial targets reports OpenCL C 1.2, so a
# module built from 2.0 source could use a construct the device cannot run, and the
# failure would arrive as an opaque clBuildProgram error rather than a compile
# diagnostic. Compiling at the level the device actually supports moves that check
# to the point where it can be explained.
$std = '-cl-std=CL1.2'
$triple = 'spirv64-unknown-unknown'

$results = @()
$failed = 0

# ---------------------------------------------------------------- backend route
if ($Route -in @('all', 'backend')) {
    $out = Join-Path $spvDir 'vector_add.spv'
    Write-Host "`n=== backend: clang SPIR-V backend ==="
    if (Test-Path $out) { Remove-Item $out -Force }
    $r = Invoke-Clang @('-c', '-target', $triple, $std, $kernel, '-o', $out)
    foreach ($l in $r.Output) { Write-Host "    $l" }
    Write-Host "    clang exit $($r.Code)"

    if ($r.Code -ne 0 -or -not (Test-Path $out)) {
        Write-Host "    FAIL: no module produced"
        $failed++
        $results += [pscustomobject]@{ Route = 'backend'; Status = 'FAIL'; File = '-' }
    } else {
        Publish-Module -RouteName 'backend' -Path $out
    }
}

# ------------------------------------------------------------- translator route
if ($Route -in @('all', 'translator')) {
    if (-not (Test-Path $llvmSpirv)) {
        Write-Host "`n=== translator: SKIPPED, llvm-spirv.exe not beside clang ==="
    } else {
        $bc = Join-Path $spvDir 'vector_add.bc'
        $out = Join-Path $spvDir 'vector_add_translator.spv'
        Write-Host "`n=== translator: clang -emit-llvm | llvm-spirv ==="
        if (Test-Path $out) { Remove-Item $out -Force }

        $r = Invoke-Clang @('-c', '-emit-llvm', '-target', $triple, $std, $kernel, '-o', $bc)
        foreach ($l in $r.Output) { Write-Host "    $l" }
        Write-Host "    clang exit $($r.Code)"
        if ($r.Code -ne 0 -or -not (Test-Path $bc)) {
            Write-Host "    FAIL: no LLVM IR produced"
            $failed++
            $results += [pscustomobject]@{ Route = 'translator'; Status = 'FAIL'; File = '-' }
        } else {
            # Quoted for the same dot reason: --spirv-max-version=1.2 splits at the dot.
            $o2 = & $llvmSpirv '--spirv-max-version=1.2' $bc '-o' $out 2>&1
            $c2 = $LASTEXITCODE
            foreach ($l in $o2) { Write-Host "    $l" }
            Write-Host "    llvm-spirv exit $c2"
            if ($c2 -ne 0 -or -not (Test-Path $out)) {
                Write-Host "    FAIL: no module produced"
                $failed++
                $results += [pscustomobject]@{ Route = 'translator'; Status = 'FAIL'; File = '-' }
            } else {
                Publish-Module -RouteName 'translator' -Path $out
            }
        }
    }
}

# --------------------------------------------------------------------- cpp route
# The source chapter claims OpenCL C++ kernels "can be compiled directly to SPIR-V"
# and gives the command "clang++ -cl-std=c++". The value is wrong - clang rejects
# 'c++' with "invalid value 'c++' in '-cl-std=c++'" - and the spelling that works is
# CLC++. This route uses the working spelling so the claim can be checked rather
# than repeated.
if ($Route -in @('all', 'cpp')) {
    $out = Join-Path $spvDir 'vector_add_cpp.spv'
    Write-Host "`n=== cpp: OpenCL C++ source, -cl-std=CLC++ ==="
    if (-not (Test-Path $kernelCpp)) {
        Write-Host "    SKIPPED, no $kernelCpp"
    } else {
        if (Test-Path $out) { Remove-Item $out -Force }
        $r = Invoke-Clang @('-c', '-target', $triple, '-cl-std=CLC++', $kernelCpp, '-o', $out)
        foreach ($l in $r.Output) { Write-Host "    $l" }
        Write-Host "    clang exit $($r.Code)"

        if ($r.Code -ne 0 -or -not (Test-Path $out)) {
            Write-Host "    FAIL: no module produced"
            $failed++
            $results += [pscustomobject]@{ Route = 'cpp'; Status = 'FAIL'; File = '-' }
        } else {
            Publish-Module -RouteName 'cpp' -Path $out

            # The comparison this route exists for. A template and a static member
            # function are C++-only constructs - under -cl-std=CL1.2 clang stops at
            # "unknown type name 'template'" - so if a module was produced at all, the
            # language level moved. The open question is what that cost, and the answer
            # comes from diffing the two disassemblies rather than from asserting it.
            #
            # Expected: exactly one differing instruction, OpSource, which is where a
            # SPIR-V module records the language level of the source it came from.
            # Anything else means the C++ source generated different code, and the
            # statement in docs/08 would then be describing a measurement that no
            # longer holds.
            $backendSpv = Join-Path $spvDir 'vector_add.spv'
            if (-not $spirvDis) {
                Write-Host "    spirv-dis not on PATH: the C-vs-C++ diff was NOT performed"
            } elseif (-not (Test-Path $backendSpv)) {
                Write-Host "    backend module absent: the C-vs-C++ diff was NOT performed"
                Write-Host "    (run without -Route, or with -Route all, to produce both)"
            } else {
                $disC = & $spirvDis $backendSpv 2>&1 | ForEach-Object { "$_" }
                $disCpp = & $spirvDis $out 2>&1 | ForEach-Object { "$_" }
                $diff = @(Compare-Object -ReferenceObject $disC -DifferenceObject $disCpp)
                Write-Host "    disassembly: $($disC.Count) lines (C) vs $($disCpp.Count) lines (C++)"
                foreach ($d in $diff) {
                    $side = if ($d.SideIndicator -eq '<=') { 'C  ' } else { 'C++' }
                    Write-Host "      [$side] $($d.InputObject.Trim())"
                }
                $onlySource = ($diff.Count -eq 2) -and
                    (@($diff | Where-Object { $_.InputObject -notmatch '^\s*OpSource\s' }).Count -eq 0)
                if ($onlySource) {
                    Write-Host "    differs only in OpSource: the C++ abstraction generated identical code"
                } else {
                    Write-Host "    FAIL: expected exactly one differing instruction (OpSource), got $($diff.Count)"
                    Write-Host "          docs/08-spirv.md describes this comparison and must be re-measured"
                    $failed++
                }
            }
        }
    }
}

Write-Host "`n=== summary ==="
Write-Host ("{0,-12} {1,-18} {2}" -f 'ROUTE', 'STATUS', 'MODULE')
foreach ($r in $results) {
    Write-Host ("{0,-12} {1,-18} {2}" -f $r.Route, $r.Status, $r.File)
}

# Only the backend route is allowed to fail the script. The translator route exists
# to be compared against, and chapter 08 documents that it does not run on the Intel
# iGPU - a module that is produced, validated and then rejected by the driver is
# exactly the evidence the chapter needs, so its presence is a success here.
if ($failed -gt 0) {
    Write-Host "`n[RESULT] FAIL ($failed problem(s))"
    exit 1
}
Write-Host "`n[RESULT] PASS"
Write-Host "Next: .\build.ps1 -Examples 09-spirv-il"
