# Build spirv-route-probe and run it against every SPIR-V module on the machine.
#
#   .\build.ps1                compile the probe, run the four safe cases, report
#   .\build.ps1 -Destructive   also run the case that is known to abort the driver
#
# This probe has no separate build and test phase for the same reason
# cpp-header-probe does not: running it IS the experiment. Case 2 is expected to FAIL
# at launch and case 3 is the control expected to PASS, so a probe that reported
# success for every case would prove nothing about which toolchain route the iGPU
# driver can actually consume. Each case therefore carries a required output
# signature, so a failure has to happen for the documented reason rather than an
# unrelated one.
#
# The modules come from OpenCL/build-spirv.ps1. Run that first; this script says so
# and stops rather than silently testing nothing.
#
# Pure ASCII: see tools/opencl-sdk.ps1 for why.
param(
    [switch]$Destructive
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $here)
. (Join-Path $repoRoot 'tools\opencl-sdk.ps1')

$vcvars = Find-VcVars64
$sdk = Find-OpenCLSDK
Write-Host "vcvars64  : $vcvars"
Write-Host "OpenCL SDK: $($sdk.Root)"

$spvDir = Join-Path $repoRoot 'examples\09-spirv-il\spv'
$backend = Join-Path $spvDir 'vector_add.spv'
$translator = Join-Path $spvDir 'vector_add_translator.spv'
$cppModule = Join-Path $spvDir 'vector_add_cpp.spv'

if (-not (Test-Path $backend)) {
    Write-Host @'
No SPIR-V modules to probe. Run this first:

    cd OpenCL
    .\build-spirv.ps1

build-spirv.ps1 needs a SPIR-V compiler (Intel oneAPI ships one). If this machine
has none, examples/09-spirv-il reports SKIP and this probe has nothing to say.
'@
    exit 0
}

$outDir = Join-Path $here 'out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$exe = Join-Path $outDir 'spirv-route-probe.exe'

# ---------------------------------------------------------------------------
# Case 3's module: the intervention that turns correlation into causation.
#
# Cases 1 and 2 differ in MANY ways - SPIR-V version, generator, size, bound, and
# the shape of the entry point. Observing that case 2 reports twice the argument
# count does not by itself say which of those differences causes it. So case 3
# changes exactly one of them: it takes the translator's own module, repoints
# OpEntryPoint at the working function and deletes the forwarding thunk. Version,
# generator and every instruction body stay as llvm-spirv emitted them.
#
# If the doubled count survives that edit, the thunk was not the cause. It does not
# survive: numargs drops from 8 to 4.
#
# Requires SPIRV-Tools, which on this machine is shipped by the Vulkan SDK rather
# than by oneAPI. When it is absent the case is reported NOT TESTED and is counted
# as neither a pass nor a failure - a missing measurement is stated as missing
# rather than quietly promoted into evidence for the claim it was meant to support.
# ---------------------------------------------------------------------------
$spirvDis = Get-Command spirv-dis -ErrorAction SilentlyContinue
$spirvAs = Get-Command spirv-as -ErrorAction SilentlyContinue
$spirvVal = Get-Command spirv-val -ErrorAction SilentlyContinue
$deThunked = Join-Path $outDir 'vector_add_dethunked.spv'
$deThunkOk = $false

if (Test-Path $deThunked) { Remove-Item $deThunked -Force }

if (-not (Test-Path $translator)) {
    Write-Host "translator module absent; cases 2 and 3 cannot run"
} elseif (-not $spirvDis -or -not $spirvAs) {
    Write-Host "spirv-dis / spirv-as not on PATH: the de-thunked control (case 3) will be NOT TESTED"
} else {
    Write-Host "spirv-dis : $($spirvDis.Source)"
    Write-Host "spirv-as  : $($spirvAs.Source)"

    $disFile = Join-Path $outDir 'translator.sptxt'
    $edited = Join-Path $outDir 'translator_dethunked.sptxt'
    & $spirvDis.Source $translator | Set-Content -Path $disFile -Encoding Ascii
    $lines = Get-Content -Path $disFile

    # Which ids belong to the thunk? It is the function OpEntryPoint names, so the
    # ids are read out of the disassembly rather than hardcoded: a future
    # llvm-spirv will number them differently and a hardcoded list would then edit
    # the wrong function, or nothing.
    $entryLine = $lines | Where-Object { $_ -match '^\s*OpEntryPoint\s+Kernel\s+(\S+)' } | Select-Object -First 1
    $thunkId = if ($entryLine -and $entryLine -match 'OpEntryPoint\s+Kernel\s+(\S+)') { $Matches[1] } else { $null }

    if (-not $thunkId) {
        Write-Host "could not find an OpEntryPoint line; case 3 will be NOT TESTED"
    } elseif ($thunkId -match '^%[A-Za-z_]') {
        # The entry point is already a named function, i.e. there is no thunk to
        # remove. That is the backend module's shape, not the translator's, and it
        # would mean build-spirv.ps1 produced something unexpected.
        Write-Host "entry point is $thunkId (already named); nothing to de-thunk, case 3 NOT TESTED"
    } else {
        Write-Host "thunk entry point id: $thunkId"

        # Collect every id the thunk defines, so its decorations go with it. A
        # decoration naming a deleted id makes spirv-as reject the module.
        $own = New-Object 'System.Collections.Generic.HashSet[string]'
        [void]$own.Add($thunkId)
        $inThunk = $false
        foreach ($l in $lines) {
            $t = $l.Trim()
            if ($t -match ('^' + [regex]::Escape($thunkId) + '\s*=\s*OpFunction\b')) { $inThunk = $true }
            if ($inThunk -and $t -match '^(%\S+)\s*=') { [void]$own.Add($Matches[1]) }
            if ($inThunk -and $t -eq 'OpFunctionEnd') { $inThunk = $false }
        }
        Write-Host "ids owned by the thunk: $($own -join ' ')"

        $out = New-Object System.Collections.Generic.List[string]
        $inThunk = $false
        foreach ($l in $lines) {
            $t = $l.Trim()
            if ($t -match ('^' + [regex]::Escape($thunkId) + '\s*=\s*OpFunction\b')) { $inThunk = $true }
            if ($inThunk) {
                # OpReturn and OpFunctionEnd name no id, so they have to be dropped by
                # position rather than by id match. Leaving them behind produces a
                # module spirv-val rejects with "Return must appear in a block" -
                # which is how the first version of this edit was caught.
                if ($t -eq 'OpFunctionEnd') { $inThunk = $false }
                continue
            }
            if ($t -match '^OpEntryPoint\s+Kernel\s+' -or $t -match '^OpExecutionMode\s+') {
                $out.Add(($l -replace [regex]::Escape($thunkId), '%vector_add'))
                continue
            }
            # Drop decorations that name a deleted id.
            $toks = $t -split '\s+'
            $dead = $false
            foreach ($tk in $toks) { if ($own.Contains($tk)) { $dead = $true; break } }
            if ($dead) { continue }
            $out.Add($l)
        }

        # The function being promoted to entry point must lose its Export linkage:
        # spirv-val rejects LinkageAttributes on anything OpEntryPoint targets. NEO
        # accepts it anyway, which is its own finding, but the control is only clean
        # if the validator agrees the module is well formed.
        $final = $out | Where-Object { $_ -notmatch 'LinkageAttributes "vector_add" Export' }
        Set-Content -Path $edited -Value $final -Encoding Ascii
        Write-Host "disassembly $($lines.Count) lines -> $($final.Count) lines"

        & $spirvAs.Source $edited '-o' $deThunked 2>&1 | ForEach-Object { Write-Host "    spirv-as: $_" }
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $deThunked)) {
            Write-Host "spirv-as failed; case 3 will be NOT TESTED"
        } else {
            if ($spirvVal) {
                $vout = & $spirvVal.Source $deThunked 2>&1
                $vcode = $LASTEXITCODE
                foreach ($l in $vout) { Write-Host "    spirv-val: $l" }
                Write-Host "    spirv-val exit $vcode"
                if ($vcode -ne 0) {
                    Write-Host "de-thunked module is NOT validator-clean; case 3 will be NOT TESTED"
                    Remove-Item $deThunked -Force
                } else { $deThunkOk = $true }
            } else {
                Write-Host "    spirv-val absent: assembled but unvalidated"
                $deThunkOk = $true
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Compile the probe.
# ---------------------------------------------------------------------------
$source = Join-Path $here 'spirv-route-probe.c'
$clArgs = @($script:ClCommonFlags) + @(
    '/TC',
    "/I$($sdk.Include)",
    $source,
    "/Fe:$exe",
    "/Fo:$outDir\spirv-route-probe.obj",
    '/link',
    "/LIBPATH:$($sdk.Lib)",
    'OpenCL.lib'
)
Write-Host "`n=== compiling spirv-route-probe ==="
$code = Invoke-ClCompile -VcVars64 $vcvars -Arguments $clArgs
if ($code -ne 0 -or -not (Test-Path $exe)) {
    Write-Host "[RESULT] FAIL (probe did not compile)"
    exit 1
}

# ---------------------------------------------------------------------------
# Expectation table.
#
#   Require  every one of these strings must appear in the probe's output
#   Forbid   none of these may appear
#
# Arity is 4 because examples/09's kernel is vector_add(a, b, c, n) - the same
# file examples/02 compiles from source, byte for byte.
#
# The nvidia row is a Forbid rather than a Require wherever the machine may not
# have an NVIDIA card. What is asserted positively is that a device with no IL
# support returns a clean -59 CL_INVALID_OPERATION from clCreateProgramWithIL
# instead of crashing; that string appears only if such a device is present.
# ---------------------------------------------------------------------------
$cases = @(
    @{ Id = 1; Module = $backend;    Arity = 4; BindAll = $false; Run = $true
       Require = @('key=uhd create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024',
                   'key=intelcpu create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024',
                   'SPIR-V 1.4')
       Forbid = @('numargs=8')
       What = 'backend route: the entry point IS the kernel' }

    @{ Id = 2; Module = $translator; Arity = 4; BindAll = $false; Run = (Test-Path $translator)
       Require = @('key=uhd create=0 build=0 kernel=0 numargs=8 launch=-52(CL_INVALID_KERNEL_ARGS) verify=-1/1024',
                   'key=intelcpu create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024',
                   'SPIR-V 1.0')
       Forbid = @()
       What = 'translator route: thunk entry point doubles the count on the iGPU only' }

    @{ Id = 3; Module = $deThunked;  Arity = 4; BindAll = $false; Run = $deThunkOk
       Require = @('key=uhd create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024')
       Forbid = @('numargs=8')
       What = 'CONTROL: same translator module, thunk removed, nothing else changed' }

    # The device-side half of build-spirv.ps1's cpp route. That script proves the
    # C++ source generates the same instructions as the C source; this proves the
    # resulting module actually runs. Both halves are needed, because "it compiled"
    # and "the driver accepted it" have already come apart once in this chapter.
    @{ Id = 4; Module = $cppModule;  Arity = 4; BindAll = $false; Run = (Test-Path $cppModule)
       Require = @('key=uhd create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024',
                   'key=intelcpu create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024',
                   'SPIR-V 1.4')
       Forbid = @('numargs=8')
       What = 'cpp route: templated OpenCL C++ source, -cl-std=CLC++' }

    @{ Id = 5; Module = $translator; Arity = 4; BindAll = $true; Run = $Destructive.IsPresent
       Require = @('[setarg] key=uhd index=3 ->')
       Forbid = @()
       What = 'DESTRUCTIVE: bind all 8 advertised slots; the iGPU driver aborts' }
)

$results = @()
$bad = 0

foreach ($c in $cases) {
    Write-Host "`n=== CASE $($c.Id): $($c.What) ==="
    if (-not $c.Run) {
        if ($c.Id -eq 3) {
            Write-Host "    NOT TESTED (spirv-dis / spirv-as unavailable, or the edit did not validate)"
            $results += [pscustomobject]@{ Id = $c.Id; Verdict = 'NOT TESTED'; What = $c.What }
        } else {
            Write-Host "    SKIPPED"
            $results += [pscustomobject]@{ Id = $c.Id; Verdict = 'SKIPPED'; What = $c.What }
        }
        continue
    }
    if (-not (Test-Path $c.Module)) {
        Write-Host "    module missing: $($c.Module)"
        $results += [pscustomobject]@{ Id = $c.Id; Verdict = 'MISMATCH'; What = 'module missing' }
        $bad++
        continue
    }

    $probeArgs = @($c.Module, 'vector_add', "$($c.Arity)")
    if ($c.BindAll) { $probeArgs += '-bind-all' }
    $out = & $exe @probeArgs 2>&1
    $runCode = $LASTEXITCODE
    foreach ($l in $out) { Write-Host "    $l" }
    Write-Host "    (exit $runCode)"

    $text = ($out -join "`n")
    $verdict = 'MATCH'
    $reason = ''

    foreach ($sig in $c.Require) {
        if ($verdict -ne 'MATCH') { break }
        if ($text.IndexOf($sig, [System.StringComparison]::Ordinal) -lt 0) {
            $verdict = 'MISMATCH'
            $reason = "missing expected output: $sig"
        }
    }
    foreach ($sig in $c.Forbid) {
        if ($verdict -ne 'MATCH') { break }
        if ($text.IndexOf($sig, [System.StringComparison]::Ordinal) -ge 0) {
            $verdict = 'MISMATCH'
            $reason = "output contained forbidden: $sig"
        }
    }

    # Case 5 is expected to die, and to die WITHOUT reaching a [probe] summary line.
    # Every other case must exit 0: a probe that crashed would report its missing
    # output as a mismatch and bury the real reason.
    if ($c.BindAll) {
        if ($runCode -eq 0) {
            $verdict = 'MISMATCH'
            $reason = 'expected the driver to abort the process, but it exited 0'
        }
        if ($text.IndexOf('[probe] key=uhd', [System.StringComparison]::Ordinal) -ge 0) {
            $verdict = 'MISMATCH'
            $reason = 'the uhd trial completed; the abort did not happen'
        }
    } elseif ($runCode -ne 0) {
        $verdict = 'MISMATCH'
        $reason = "probe exited $runCode"
    }

    if ($reason) { Write-Host "    MISMATCH: $reason" } else { Write-Host "    MATCH" }
    if ($verdict -ne 'MATCH') { $bad++ }

    $results += [pscustomobject]@{ Id = $c.Id; Verdict = $verdict; What = $c.What }
}

Write-Host "`n=== summary ==="
Write-Host ("{0,-10} {1,-4} {2}" -f 'VERDICT', 'ID', 'CASE')
foreach ($r in $results) {
    Write-Host ("{0,-10} {1,-4} {2}" -f $r.Verdict, $r.Id, $r.What)
}

$tested = @($results | Where-Object { $_.Verdict -ne 'NOT TESTED' -and $_.Verdict -ne 'SKIPPED' }).Count
$notTested = @($results | Where-Object { $_.Verdict -eq 'NOT TESTED' -or $_.Verdict -eq 'SKIPPED' }).Count
Write-Host "`n$tested case(s) tested, $notTested not tested, $bad unexpected"
if ($bad -gt 0) {
    Write-Host "[RESULT] FAIL"
    exit 1
}
Write-Host "[RESULT] PASS"
if ($notTested -gt 0) {
    Write-Host "Note: $notTested case(s) were not tested. PASS here means every case that ran"
    Write-Host "      matched; it does not mean the whole table was exercised."
}
