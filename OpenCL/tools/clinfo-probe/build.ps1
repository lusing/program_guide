# Build clinfo-probe and run it to print this machine's OpenCL capability baseline.
#
#   .\build.ps1              build + run
#   .\build.ps1 -SkipRun     build only
#
# Pure ASCII: see the note at the top of tools/opencl-sdk.ps1 for why a Chinese
# string literal in a BOM-less .ps1 breaks Windows PowerShell 5.1.
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
Write-Host "  include : $($sdk.Include)"
Write-Host "  lib     : $($sdk.Lib)"

$source = Join-Path $here 'clinfo-probe.c'
$exe = Join-Path $here 'clinfo-probe.exe'
if (Test-Path $exe) { Remove-Item $exe -Force }

Write-Host "`n--- compiling clinfo-probe"
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

Write-Host "`n--- running clinfo-probe"
Push-Location $here
& $exe
$runCode = $LASTEXITCODE
Pop-Location
if ($runCode -ne 0) { throw "clinfo-probe exited with $runCode" }
