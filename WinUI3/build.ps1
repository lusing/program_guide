<#
.SYNOPSIS
    Builds every WinUI 3 example project under examples/.

.DESCRIPTION
    One entry point for "does the tutorial still compile": discovers each
    examples/*/*.vcxproj, restores its PackageReference packages, and builds it with the
    same MSBuild the IDE uses. Prints a per-example pass/fail line and exits non-zero if
    any example failed, so it can gate a CI job or a pre-commit check.

.EXAMPLE
    ./build.ps1                      # build all examples, Debug|x64
    ./build.ps1 -Examples 01-first-app -Rebuild
#>
param(
    [string]$Configuration = 'Debug',
    [string]$Platform = 'x64',
    # Folder names under examples/ to build; defaults to all of them.
    [string[]]$Examples,
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-MSBuild {
    $vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $installPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null | Select-Object -First 1
        if ($installPath) {
            $candidate = Join-Path $installPath 'MSBuild\Current\Bin\MSBuild.exe'
            if (Test-Path $candidate) { return $candidate }
        }
    }
    throw 'MSBuild.exe not found; install Visual Studio with the C++ workload.'
}

$msbuild = Find-MSBuild

$projects = Get-ChildItem -Path (Join-Path $repoRoot 'examples') -Filter *.vcxproj -Recurse -Depth 1 |
    Sort-Object FullName
if ($Examples -and $Examples.Count -gt 0) {
    $projects = $projects | Where-Object { $Examples -contains $_.Directory.Name }
}
if (-not $projects) { throw 'no example projects matched' }

$target = if ($Rebuild) { 'Rebuild' } else { 'Build' }
$failed = @()

foreach ($project in $projects) {
    $name = $project.Directory.Name
    "`n=== $name ($target $Configuration|$Platform) ==="
    & $msbuild $project.FullName `
        -restore `
        -t:$target `
        -p:Configuration=$Configuration `
        -p:Platform=$Platform `
        -m `
        -nr:false `
        -nologo `
        -v:m
    if ($LASTEXITCODE -eq 0) {
        "PASS : $name"
    }
    else {
        "FAIL : $name (msbuild exit $LASTEXITCODE)"
        $failed += $name
    }
}

"`n=== summary ==="
foreach ($project in $projects) {
    $name = $project.Directory.Name
    $verdict = if ($failed -contains $name) { 'FAIL' } else { 'PASS' }
    "$verdict  $name"
}
if ($failed) { exit 1 }
