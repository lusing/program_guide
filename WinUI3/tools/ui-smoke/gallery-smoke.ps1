<#
.SYNOPSIS
    Drives ui-smoke.ps1 through a gallery app's scenario table, one page at a time.

.DESCRIPTION
    A gallery project is one exe with a NavigationView shell and one Page per tutorial
    chapter. Verifying "every page" means: launch the app, click the nav item for that
    page, screenshot, optionally click/type inside the page, screenshot again. This
    driver re-launches the app fresh for each scenario (deterministic state; ~8 s
    startup each) and writes evidence to .smoke\<galleryDir>\<page>\.

    Coordinates are WINDOW coordinates (the same space as the saved screenshots:
    0,0 = window top-left including the title bar) at the gallery's parked window size.
    Calibrate by gridding a before.png and reading item rows off it; see the README
    verification section for the method.

.EXAMPLE
    ./gallery-smoke.ps1 -Gallery 07                # every scenario registered for 07
    ./gallery-smoke.ps1 -Gallery 07 -Page button   # one scenario
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('07', '17', '21', '26', '31', '35')][string]$Gallery,
    [string]$Page
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiSmoke = Join-Path $here 'ui-smoke.ps1'
$repoRoot = Split-Path -Parent (Split-Path -Parent $here)

# Nav row geometry at 150% DPI (physical px, measured): first menu item centre y=238,
# row pitch 72, pane item centre x=150. Calibrate per gallery if the shell changes.
function Nav-Y([int]$index) { 238 + 72 * $index }

$galleries = @{
    '07' = @{
        Dir  = '07-controls-basic'
        Exe  = 'examples\07-controls-basic\x64\Debug\BasicGallery\BasicGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{
            # tag       nav item y-index (0=Home), optional in-page click / typed text
            home    = @{ Nav = 0 }
            button  = @{ Nav = 1; Act = '475,147' }   # Click me -> StatusText "clicked 1"
            textblock = @{ Nav = 2; Act = '475,250' } # Cycle trim -> "trim = CharacterEllipsis" + ellipsis appears
            textbox  = @{ Nav = 3; Act = '568,560' }  # Read text -> status shows rich text content
        }
    }
    '17' = @{
        Dir  = '17-controls-collections'
        Exe  = 'examples\17-controls-collections\x64\Debug\CollectionsGallery\CollectionsGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{ home = @{ Nav = 0 } }
    }
    '21' = @{
        Dir  = '21-controls-shell'
        Exe  = 'examples\21-controls-shell\x64\Debug\ShellGallery\ShellGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{ home = @{ Nav = 0 } }
    }
    '26' = @{
        Dir  = '26-customization'
        Exe  = 'examples\26-customization\x64\Debug\CustomGallery\CustomGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{ home = @{ Nav = 0 } }
    }
    '31' = @{
        Dir  = '31-window-shell'
        Exe  = 'examples\31-window-shell\x64\Debug\WindowShellApp\WindowShellApp.exe'
        Size = @(900, 800)
        Pages = [ordered]@{ home = @{ Act = '480,300' } }
    }
    '35' = @{
        Dir  = '35-taskflow'
        Exe  = 'examples\35-taskflow\x64\Debug\TaskFlow\TaskFlow.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{ home = @{ Nav = 0 } }
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
    if ($null -ne $sc.Nav)   { $clickSeq += "150,$(Nav-Y ([int]$sc.Nav))" }
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
