<#
.SYNOPSIS
    Drives ui-smoke.ps1 through a gallery app's scenario table, one page at a time.

.DESCRIPTION
    A gallery project is one exe with a NavigationView shell and one Page per tutorial
    chapter. Verifying "every page" means: launch the app, click the nav item for that
    page, screenshot, optionally click/type inside the page, screenshot again. This
    driver re-launches the app fresh for each scenario (deterministic state; ~8 s
    startup each) and writes evidence to .smoke\<galleryDir>\<page>\.

    The four control-gallery projects (07/17/21/26) were replaced by the functional
    apps - their flows live in smoke-settingshub.ps1 / smoke-scratchpad.ps1 /
    smoke-dataexplorer.ps1 / smoke-themelab.ps1, all driven through tap.ps1
    (touch injection), because injected mouse clicks never complete a ButtonBase
    Click on this machine (see README's smoke-testing notes).

    Coordinates are WINDOW coordinates (the same space as the saved screenshots:
    0,0 = window top-left including the title bar) at the gallery's parked window size.
    Calibrate by gridding a before.png and reading item rows off it; see the README
    verification section for the method.

.EXAMPLE
    ./gallery-smoke.ps1 -Gallery 07                # every scenario registered for 07
    ./gallery-smoke.ps1 -Gallery 07 -Page button   # one scenario
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('31', '35')][string]$Gallery,
    [string]$Page
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiSmoke = Join-Path $here 'ui-smoke.ps1'
$repoRoot = Split-Path -Parent (Split-Path -Parent $here)

# Nav-row pitch is NOT constant: NavigationView tightens item spacing as the menu grows
# (measured: ~72 px pitch with 6 items, ~56 px with 7+). So scenario tables store
# measured window coordinates for both the nav click and the in-page action; calibrate
# each page with zoom-grid.ps1 when it is registered.

$galleries = @{
    '31' = @{
        Dir  = '31-window-shell'
        Exe  = 'examples\31-window-shell\x64\Debug\WindowShellApp\WindowShellApp.exe'
        Size = @(900, 640)
        Pages = [ordered]@{
            # no nav shell: direct interactions (acrylic switch + new window)
            home = @{ Act = '615,190;450,270' }  # Acrylic -> material change; New window -> "second window opened"
        }
    }
    '35' = @{
        Dir  = '35-taskflow'
        Exe  = 'examples\35-taskflow\x64\Debug\TaskFlow\TaskFlow.exe'
        Size = @(1000, 800)
        Pages = [ordered]@{
            # seed %LOCALAPPDATA%\TaskFlow\tasks.json with ["buy milk","walk dog"] first
            load    = @{ Act = '480,180' }  # Add task -> dialog opens; list already Loaded 2 tasks
            toggle  = @{ Act = '470,270' }  # first row checkbox -> "finished a task" + saved
            persist = @{}                   # relaunch -> Loaded 2 tasks again (round trip)
        }
    }
}

if (-not $galleries.Contains($Gallery)) { throw "unknown gallery '$Gallery'" }
$g = $galleries[$Gallery]
$names = @($g.Pages.Keys)
if ($Page) {
    if ($names -notcontains $Page) { throw "gallery '$Gallery' has no page '$Page' (has: $($names -join ', '))" }
    $names = @($Page)
}

$exe = Join-Path $repoRoot $g.Exe
if (-not (Test-Path $exe)) { throw "exe not built: $exe (run build.ps1 -Examples $($g.Dir) first)" }

$failed = @()
foreach ($name in $names) {
    $sc = $g.Pages[$name]
    $outDir = Join-Path $repoRoot (Join-Path '.smoke' (Join-Path $g.Dir $name))
    "`n=== $($g.Dir) / $name ==="

    $clickSeq = @()
    if ($sc.Nav)             { $clickSeq += $sc.Nav }
    if ($sc.Act)             { $clickSeq += $sc.Act }

    $psi = @{ Exe = $exe; OutDir = $outDir; WindowW = $g.Size[0]; WindowH = $g.Size[1] }
    if ($clickSeq.Count -gt 0) { $psi['Clicks'] = ($clickSeq -join ';') }
    if ($sc.Type)             { $psi['TypeText'] = $sc.Type }
    if ($clickSeq.Count -eq 0) { $psi['NoClick'] = $true }

    try {
        & $uiSmoke @psi
        "PASS   : $name"
    }
    catch {
        "FAIL   : $name ($($_.Exception.Message))"
        $failed += $name
    }
}

"`n=== summary ($($names.Count) scenario(s)) ==="
foreach ($name in $names) {
    $verdict = if ($failed -contains $name) { 'FAIL' } else { 'PASS' }
    "$verdict  $name"
}
if ($failed) { exit 1 }
