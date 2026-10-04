# Build cl-build-probe, then run it against a fixture set that proves the probe
# distinguishes a broken kernel from a working one.
#
#   .\build.ps1              build + run the fixture expectations
#   .\build.ps1 -SkipRun     build only
#
# The fixture expectations are the reason this script exists rather than just
# compiling: a probe that reports "BUILD OK" for everything is worthless, so the
# smoke test deliberately includes kernels that MUST fail. If a "expect fail" case
# starts passing, something about the toolchain changed and the tutorial's claims
# need re-checking.
#
# Pure ASCII: see tools/opencl-sdk.ps1 for why.
param(
    [switch]$SkipRun
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here '..\opencl-sdk.ps1')

$vcvars = Find-VcVars64
$sdk = Find-OpenCLSDK
Write-Host "vcvars64 : $vcvars"
Write-Host "OpenCL SDK: $($sdk.Root)"

$source = Join-Path $here 'cl-build-probe.c'
$exe = Join-Path $here 'cl-build-probe.exe'
if (Test-Path $exe) { Remove-Item $exe -Force }

Write-Host "`n--- compiling cl-build-probe"
$clArgs = @($script:ClCommonFlags) + @(
    '/TC',
    "/I$($sdk.Include)",
    $source,
    "/Fe:$exe",
    '/link',
    "/LIBPATH:$($sdk.Lib)",
    'OpenCL.lib'
)
$code = Invoke-ClCompile -VcVars64 $vcvars -Arguments $clArgs
if ($code -ne 0) { throw "cl.exe failed with exit code $code" }
if (-not (Test-Path $exe)) { throw "compile reported success but $exe was not produced" }
Write-Host "OK: $exe"

if ($SkipRun) { return }

# fixture, kernelName, deviceHint, buildOptions, expected exit code
# exit 0 = built, 1 = build failed, 2 = usage/no device
#
# These rows encode three measured lessons rather than just "does it compile":
#   1. The macro that gates OpenCL C builtins is __OPENCL_C_VERSION__, and its
#      default is chosen by the vendor, not by CL_DEVICE_OPENCL_C_VERSION. Rows 3
#      and 4 are the same source on the same device; only -cl-std differs, and the
#      outcome flips. Rows 4 and 5 are the same source at the same -cl-std on two
#      devices whose CL_DEVICE_OPENCL_C_VERSION strings differ (1.2 vs 3.0) and yet
#      both build it. Anyone who reads the version string as "the language level in
#      effect" gets both of those wrong. See docs/06-kernel-programming.md 6.2.2.
#   2. Subgroup support is an EXTENSION question, not a version question. Rows 6-8
#      are one source across three devices: the Intel iGPU lists cl_khr_subgroups,
#      the Intel CPU lists cl_intel_subgroups alone, and both build it; NVIDIA lists
#      neither and fails at ptxas. Which extension name you get is per-device, so
#      gate on CL_DEVICE_OPENCL_C_FEATURES / __opencl_c_subgroups rather than on any
#      single extension string.
#   3. "The device cannot compile X" and "X cannot run on the device" are different
#      claims. Rows 9-10 feed the device front end the two kernels from examples/09.
#      Row 10 is a template, and this device rejects it - yet the module that offline
#      clang built from that very file runs on this very device at 1024/1024, because
#      clCreateProgramWithIL leaves the driver no front end. See docs/08-spirv.md
#      8.8.5, and tools/spirv-route-probe case 4 for the run.
$expectations = @(
    # The original tutorial's matmul used __const, which is not OpenCL C. Must fail.
    @{ Fixture = 'matmul_bad.cl';     Kernel = '';               Device = 'UHD';     Options = '';             Expect = 1;
       Note = '__const is not an address space' }
    # The same kernel with __global const. Must build.
    @{ Fixture = 'matmul_good.cl';    Kernel = 'matrix_mul';     Device = 'UHD';     Options = '';             Expect = 0;
       Note = 'corrected to __global const' }
    # No -cl-std: the compiler defaults to the device's advertised OpenCL C 1.2,
    # where to_global does not exist. This is the failure that is easy to misread
    # as a device limitation.
    @{ Fixture = 'generic_addr.cl';   Kernel = 'generic_addr';   Device = 'UHD';     Options = '';             Expect = 1;
       Note = 'no -cl-std => defaults to advertised 1.2' }
    # Same source, same device, but asking for 2.0. Builds and runs correctly
    # (256/256), which disproves "OpenCL C 1.2 devices cannot do OpenCL 2.0".
    @{ Fixture = 'generic_addr.cl';   Kernel = 'generic_addr';   Device = 'UHD';     Options = '-cl-std=CL2.0'; Expect = 0;
       Note = 'iGPU honours 2.0 when asked' }
    # The CPU device advertises OpenCL C 3.0, so 2.0 is comfortably in range.
    @{ Fixture = 'generic_addr.cl';   Kernel = 'generic_addr';   Device = 'i7-9700'; Options = '-cl-std=CL2.0'; Expect = 0;
       Note = 'CPU device is OpenCL C 3.0' }
    # Subgroups: both Intel devices expose the extension and build it.
    @{ Fixture = 'subgroup_bcast.cl'; Kernel = 'subgroup_bcast'; Device = 'UHD';     Options = '-cl-std=CL2.0'; Expect = 0;
       Note = 'Intel iGPU has cl_khr_subgroups (sg=16)' }
    @{ Fixture = 'subgroup_bcast.cl'; Kernel = 'subgroup_bcast'; Device = 'i7-9700'; Options = '-cl-std=CL2.0'; Expect = 0;
       Note = 'Intel CPU has cl_intel_subgroups (sg=8)' }
    # NVIDIA exposes no subgroup extension, so the same source fails there even
    # though it accepted to_global. Version level does not predict this.
    @{ Fixture = 'subgroup_bcast.cl'; Kernel = 'subgroup_bcast'; Device = 'RTX 2060'; Options = '-cl-std=CL2.0'; Expect = 1;
       Note = 'NVIDIA has no subgroup extension' }

    # Rows 9-10 are the device-compiler half of docs/08-spirv.md 8.8.5.
    #
    # These two point OUTSIDE fixtures/, at the real kernel files examples/09 uses.
    # That is deliberate: copying them here would let the two diverge, and the claim
    # being tested is precisely that the SAME file is rejected by the device compiler
    # and accepted by offline clang. A copy would make the claim unfalsifiable.
    #
    # Row 9 is the control. It proves the relative path resolves and that this device
    # builds ordinary OpenCL C, so row 10's failure cannot be blamed on either.
    #
    # Three levels up, not two: fixture paths are joined onto fixtures/, so the chain
    # is fixtures -> cl-build-probe -> tools -> OpenCL. Guessing this wrong is caught
    # by the Test-Path below instead of by a confusing compile error, which is part of
    # what the control row is for.
    @{ Fixture = '..\..\..\examples\09-spirv-il\kernels\vector_add.cl'; Kernel = 'vector_add'; Device = 'UHD'; Options = ''; Expect = 0;
       Note = 'CONTROL: plain OpenCL C from the same directory builds' }
    # Row 10: the templated OpenCL C++ kernel. build-spirv.ps1 compiles this exact
    # file with -cl-std=CLC++ and tools/spirv-route-probe case 4 then RUNS the result
    # on this same device at 1024/1024. Here the device's own front end rejects it.
    # Both are true, because clCreateProgramWithIL leaves the driver no front end.
    @{ Fixture = '..\..\..\examples\09-spirv-il\kernels\vector_add_cpp.cl'; Kernel = 'vector_add'; Device = 'UHD'; Options = ''; Expect = 1;
       Note = 'device front end rejects template; the offline SPIR-V route runs it' }
)

$mismatched = New-Object System.Collections.ArrayList
for ($idx = 0; $idx -lt $expectations.Count; $idx++) {
    $e = $expectations[$idx]
    # GetFullPath rather than Resolve-Path: the file must not exist for this to work,
    # because a row can legitimately point at a path that has gone missing, and the
    # error below is clearer than Resolve-Path's. Rows 9-10 escape fixtures/ with
    # '..\..\..', so without normalizing the probe would print that chain as its
    # source path and the failure message would be unreadable.
    $path = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $here 'fixtures') $e.Fixture))
    if (-not (Test-Path $path)) { throw "missing fixture: $path" }

    Write-Host "`n=== $($e.Fixture) on '$($e.Device)' $($e.Options) -> expect exit $($e.Expect)"
    Write-Host "    why this case is here: $($e.Note)"

    # An empty kernel name is passed as '' rather than a placeholder like '-',
    # because cl-build-probe tests *kernName and would otherwise call
    # clCreateKernel with the literal name "-".
    $probeArgs = @($path, $e.Kernel, $e.Device)
    if ($e.Options) { $probeArgs += $e.Options }

    Push-Location $here
    & $exe @probeArgs
    $actual = $LASTEXITCODE
    Pop-Location

    if ($actual -eq $e.Expect) {
        Write-Host "    MATCH (exit $actual)"
    } else {
        Write-Host "    MISMATCH: expected exit $($e.Expect), got $actual"
        [void]$mismatched.Add($idx)
    }
}

Write-Host "`n=== summary ==="
for ($idx = 0; $idx -lt $expectations.Count; $idx++) {
    $e = $expectations[$idx]
    $verdict = if ($mismatched -contains $idx) { 'MISMATCH' } else { 'MATCH' }
    Write-Host ("{0,-9} {1,-20} {2,-10} {3}" -f $verdict, $e.Fixture, $e.Device, $e.Note)
}
if ($mismatched.Count -gt 0) {
    Write-Host "`n$($mismatched.Count) expectation(s) did not hold - re-check the tutorial's claims."
    Write-Host '[RESULT] FAIL'
    exit 1
}
Write-Host "`nAll fixture expectations held."
Write-Host "[RESULT] PASS ($($expectations.Count)/$($expectations.Count) expectations held)"
exit 0
