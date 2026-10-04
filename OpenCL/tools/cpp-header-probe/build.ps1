# Build cpp-header-probe and run its seventeen macro variants.
#
#   .\build.ps1                  compile every variant, classify, report
#   .\build.ps1 -DumpVariant 3   one variant, complete untruncated compiler output
#
# -DumpVariant exists because the normal run deliberately shows only the first few
# errors: enough to classify a variant, not enough to quote an exact count or an
# identifier list in chapter 07. Reproducing that by hand means rebuilding the whole
# cl.exe command line, which is precisely what this script already knows how to do.
#
# This probe has no separate build and test phase, because for a header-only
# binding the compile step is the entire experiment. Seven of the seventeen variants
# are expected to FAIL. A probe that reported success for all seventeen would prove
# nothing about which macros are load-bearing, so each failing variant also carries
# a required signature: the failure has to happen for the documented reason, not for
# an unrelated one. That distinction is what makes "it exploded" into evidence.
#
# Pure ASCII: see tools/opencl-sdk.ps1 for why.
param(
    [int]$DumpVariant = 0
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here '..\opencl-sdk.ps1')

$vcvars = Find-VcVars64
$sdk = Find-OpenCLSDK
Write-Host "vcvars64  : $vcvars"
Write-Host "OpenCL SDK: $($sdk.Root)"
Write-Host "  cl.hpp  : $(if (Test-Path (Join-Path $sdk.Include 'CL\cl.hpp')) { 'present' } else { 'MISSING' })"

$outDir = Join-Path $here 'out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$source = Join-Path $here 'cpp-header-probe.cpp'
$exe = Join-Path $outDir 'cpp-header-probe.exe'
$obj = Join-Path $outDir 'cpp-header-probe.obj'

# ClCommonFlags pins CL_TARGET_OPENCL_VERSION=300, which is precisely the macro this
# probe varies. Letting the /D and the source's own #define coexist produces C4005
# "macro redefined" noise on four variants and obscures the errors under test, so
# that one flag is filtered out. Deriving the list from ClCommonFlags rather than
# retyping it keeps the two in step when the shared flags change.
$baseFlags = @($script:ClCommonFlags | Where-Object { $_ -notmatch 'CL_TARGET_OPENCL_VERSION' }) + '/std:c++17'

# Expect columns:
#   Exit      0 = must compile, 1 = must fail
#   MinErrors variant must produce at least this many "error C" lines
#   Require   every one of these strings must appear in the compiler output
#   Forbid    none of these may appear
#
# The Require/Forbid lists are the point of the exercise. V3 and V4 differ only in
# which macro NAME enables exceptions, and both must fail with the same
# version-mismatch pragma and the same missing-token errors; that pairing is what
# retires the widespread belief that __CL_ENABLE_EXCEPTIONS is itself broken.
#
# V7, V13, V14 and V15 form a two-by-two over the single warning a clean build of
# examples/08 emits. Both causes are necessary: MINIMUM <= 220 makes cl.hpp:496-498
# define CL_USE_DEPRECATED_OPENCL_2_2_APIS and so compile the setReleaseCallback
# wrapper at cl.hpp:6840, and including <CL/cl.h> first makes cl_platform.h:128
# freeze the deprecation marker ON before cl.hpp can define that macro - the header
# guard at cl_platform.h:17 means the decision is not revisited. V14 has both causes
# and must warn. V7 (cl.hpp first) and V13/V15 (MINIMUM=300) each remove one, and
# must not. Asserting the warning in only one direction would leave the include
# order, which is what examples/08 actually gets wrong, unmeasured.
#
# MinErrors for V3/V4 is 30 against a measured 42. It is a floor, not a target:
# MSVC's cascade length depends on how far the parser gets, and a future cl.hpp
# could reasonably produce more or fewer. The bound exists to catch "failed for one
# unrelated reason", which a bare exit-code check would happily accept.
$variants = @(
    @{ Id = 1;  Exit = 0; MinErrors = 0;  Require = @();
       Forbid = @();
       What = 'all four macros agree on 1.2' }

    @{ Id = 2;  Exit = 0; MinErrors = 0;  Require = @('__CL_ENABLE_EXCEPTIONS is deprecated');
       Forbid = @();
       What = 'old macro name, target 300 -> honoured' }

    @{ Id = 3;  Exit = 1; MinErrors = 30; Require = @('__CL_ENABLE_EXCEPTIONS is deprecated',
                                                       'is already defined as is lower than',
                                                       'CL_DEVICE_SVM_CAPABILITIES');
       Forbid = @();
       What = 'old macro name, target 120 -> mismatch' }

    @{ Id = 4;  Exit = 1; MinErrors = 30; Require = @('is already defined as is lower than',
                                                       'CL_DEVICE_SVM_CAPABILITIES');
       Forbid = @('__CL_ENABLE_EXCEPTIONS is deprecated');
       What = 'new macro name, target 120 -> same mismatch' }

    @{ Id = 5;  Exit = 1; MinErrors = 1;  Require = @('C1083', 'cl2.hpp');
       Forbid = @();
       What = '<CL/cl2.hpp> does not exist here' }

    @{ Id = 6;  Exit = 1; MinErrors = 1;  Require = @('C1083', 'opencl.hpp');
       Forbid = @();
       What = '<CL/opencl.hpp> does not exist here' }

    @{ Id = 7;  Exit = 0; MinErrors = 0;  Require = @();
       Forbid = @('is already defined as is lower than', 'getContextPlatformVersion', 'C4996');
       What = 'the setting OpenCL/build.ps1 uses' }

    @{ Id = 8;  Exit = 1; MinErrors = 1;  Require = @('CL_HPP_MINIMUM_OPENCL_VERSION must not be greater');
       Forbid = @();
       What = 'minimum above target is a hard #error' }

    @{ Id = 9;  Exit = 1; MinErrors = 1;  Require = @('C2039', 'C2065', 'Error');
       Forbid = @('getContextPlatformVersion');
       What = 'catch(cl::Error) with exceptions off' }

    @{ Id = 10; Exit = 0; MinErrors = 0;  Require = @();
       Forbid = @('C2065', 'getContextPlatformVersion');
       What = 'exceptions off, error-code style body' }

    @{ Id = 11; Exit = 1; MinErrors = 10; Require = @('getContextPlatformVersion', 'C2039', 'C3861');
       Forbid = @('is already defined as is lower than');
       What = 'minimum 120 + target 300: cl.hpp guard gap' }

    @{ Id = 12; Exit = 0; MinErrors = 0;  Require = @();
       Forbid = @('getContextPlatformVersion');
       What = 'minimum 110 + target 300: both guards agree' }

    @{ Id = 13; Exit = 0; MinErrors = 0;  Require = @();
       Forbid = @('getContextPlatformVersion', 'C4996');
       What = 'minimum 300, cl.hpp first: no deprecated wrappers' }

    @{ Id = 14; Exit = 0; MinErrors = 0;  Require = @('C4996', 'clSetProgramReleaseCallback');
       Forbid = @('getContextPlatformVersion');
       What = 'minimum 200, cl.h FIRST: the examples/08 warning' }

    @{ Id = 15; Exit = 0; MinErrors = 0;  Require = @();
       Forbid = @('getContextPlatformVersion', 'C4996');
       What = 'minimum 300, cl.h first: silent anyway' }

    # V16/V17 settle a claim chapter 07 RETRACTS - that clSetEventCallback is
    # deprecated under OpenCL 3.0 - and they settle the stronger half of it, which
    # reading cl.h cannot: that the C4996 in a cl.h-first build is cl.hpp's own
    # wrapper and not the user's callback call. Both variants compile the identical
    # setCallback invocation; only the include order differs. V16 must be silent.
    # V17 must warn, must name clSetProgramReleaseCallback, and must NOT name
    # clSetEventCallback - the Forbid is what makes "the warning is not yours" a
    # tested statement rather than an assertion in prose.
    #
    # Both also require CL_CALLBACK to expand to __stdcall. It looks like include
    # order should decide that (cl.hpp:561-563 defines it empty, cl_platform.h:33-35
    # defines it __stdcall) and it does not, because cl.hpp includes <CL/opencl.h> at
    # line 525, before its own fallback. Requiring the same expansion from both orders
    # is what turns that from a comment into a measurement.
    @{ Id = 16; Exit = 0; MinErrors = 0;  Require = @('CL_CALLBACK = __stdcall');
       Forbid = @('getContextPlatformVersion', 'C4996');
       What = 'setCallback lambda, cl.hpp first: no deprecation anywhere' }

    @{ Id = 17; Exit = 0; MinErrors = 0;  Require = @('C4996', 'clSetProgramReleaseCallback',
                                                       'CL_CALLBACK = __stdcall');
       Forbid = @('getContextPlatformVersion', 'clSetEventCallback');
       What = 'same call, cl.h first: the warning names cl.hpp, not you' }
)

if ($DumpVariant -ne 0) {
    $variants = @($variants | Where-Object { $_.Id -eq $DumpVariant })
    if ($variants.Count -eq 0) { throw "no such variant: $DumpVariant (valid ids are 1..17)" }
}

$results = @()

foreach ($v in $variants) {
    Write-Host "`n=== VARIANT $($v.Id): $($v.What) ==="
    if (Test-Path $exe) { Remove-Item $exe -Force }
    if (Test-Path $obj) { Remove-Item $obj -Force }

    $clArgs = @($baseFlags) + @(
        '/TP',
        "/DVARIANT=$($v.Id)",
        "/I$($sdk.Include)",
        $source,
        "/Fe:$exe",
        "/Fo:$obj",
        '/link',
        "/LIBPATH:$($sdk.Lib)",
        'OpenCL.lib'
    )
    $r = Invoke-ClCompile -VcVars64 $vcvars -Arguments $clArgs -Capture
    $text = ($r.Output -join "`n")
    $errCount = ([regex]::Matches($text, 'error C\d{4}')).Count
    $compiled = ($r.Code -eq 0) -and (Test-Path $exe)

    if ($DumpVariant -ne 0) {
        # Everything, in stream order, with no filtering. This is the form to quote
        # from: the classified run truncates, and a truncated cascade cannot support
        # a claim about how many identifiers went missing.
        Write-Host "--- complete compiler output ---"
        foreach ($l in $r.Output) { Write-Host $l }
        Write-Host "--- end: cl.exe exit $($r.Code), $errCount 'error C' lines ---"
        return
    }

    # Show WHY it failed in two groups rather than one filtered slice.
    #
    # A #pragma message emits only its string argument, so searching the output for
    # the words "pragma message" finds nothing - which is how cl.hpp's own three
    # diagnostics went missing from an earlier version of this display even though
    # the Require checks below were matching them. Splitting the groups also avoids
    # depending on stream order: pragmas go to stdout, errors to stderr, and
    # PowerShell's 2>&1 merge does not promise to interleave them faithfully.
    $diag = $r.Output | Where-Object { $_ -match 'opencl\.hpp:|CL_TARGET_OPENCL_VERSION is already|CL_CALLBACK = ' }
    foreach ($l in $diag) { Write-Host "    $l" }
    $errs = $r.Output | Where-Object { $_ -match 'error C\d{4}|fatal error' } | Select-Object -First 5
    foreach ($l in $errs) { Write-Host "    $l" }
    if ($errCount -gt 0) { Write-Host "    ($errCount 'error C' lines total)" }
    # Warnings get their own group for the same reason: V14 and V17 require a C4996
    # while V7, V13, V15 and V16 forbid one, and V17 additionally forbids that
    # warning from naming clSetEventCallback. An assertion whose evidence never
    # reaches the screen is an assertion a reader cannot check.
    $warns = $r.Output | Where-Object { $_ -match 'warning C\d{4}' } | Select-Object -First 3
    foreach ($l in $warns) { Write-Host "    $l" }

    $verdict = 'MATCH'
    $reason = ''

    if ($compiled -ne ($v.Exit -eq 0)) {
        $verdict = 'MISMATCH'
        $reason = "expected exit $($v.Exit), got compile=$(if ($compiled) {'ok'} else {'fail'})"
    }
    if ($verdict -eq 'MATCH' -and $errCount -lt $v.MinErrors) {
        $verdict = 'MISMATCH'
        $reason = "expected >= $($v.MinErrors) errors, saw $errCount"
    }
    foreach ($sig in $v.Require) {
        if ($verdict -ne 'MATCH') { break }
        if ($text -notmatch [regex]::Escape($sig)) {
            $verdict = 'MISMATCH'
            $reason = "missing expected output: $sig"
        }
    }
    foreach ($sig in $v.Forbid) {
        if ($verdict -ne 'MATCH') { break }
        if ($text -match [regex]::Escape($sig)) {
            $verdict = 'MISMATCH'
            $reason = "output contained forbidden: $sig"
        }
    }

    # A variant that compiled must also RUN: linking against OpenCL.lib and
    # enumerating platforms is what separates "the header parsed" from "the
    # bindings are usable".
    $runNote = ''
    if ($compiled) {
        $runOut = & $exe 2>&1
        $runCode = $LASTEXITCODE
        foreach ($l in $runOut) { Write-Host "    $l" }
        if ($runCode -ne 0) {
            $verdict = 'MISMATCH'
            $reason = "compiled but the binary exited $runCode"
        }
        $runNote = "ran, exit $runCode"
    }

    if ($reason) { Write-Host "    MISMATCH: $reason" } else { Write-Host "    MATCH" }

    $results += [pscustomobject]@{
        Id      = $v.Id
        What    = $v.What
        Errors  = $errCount
        Expect  = if ($v.Exit -eq 0) { 'compile' } else { 'fail' }
        Actual  = if ($compiled) { $runNote } else { "fail ($errCount err)" }
        Verdict = $verdict
    }
}

Write-Host "`n=== summary ==="
Write-Host ("{0,-9} {1,-4} {2,-8} {3,-16} {4}" -f 'VERDICT', 'V', 'ERRORS', 'EXPECTED', 'VARIANT')
$bad = 0
foreach ($r in $results) {
    Write-Host ("{0,-9} {1,-4} {2,-8} {3,-16} {4}" -f $r.Verdict, $r.Id, $r.Errors, $r.Expect, $r.What)
    if ($r.Verdict -ne 'MATCH') { $bad++ }
}
Write-Host "`n$($results.Count) variants: $($results.Count - $bad) as documented, $bad unexpected"
if ($bad -gt 0) {
    Write-Host "[RESULT] FAIL"
    exit 1
}
Write-Host "[RESULT] PASS"
