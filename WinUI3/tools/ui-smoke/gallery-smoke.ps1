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

# Nav-row pitch is NOT constant: NavigationView tightens item spacing as the menu grows
# (measured: ~72 px pitch with 6 items, ~56 px with 7+). So scenario tables store
# measured window coordinates for both the nav click and the in-page action; calibrate
# each page with zoom-grid.ps1 when it is registered.

$galleries = @{
    '07' = @{
        Dir  = '07-controls-basic'
        Exe  = 'examples\07-controls-basic\x64\Debug\BasicGallery\BasicGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{
            # tag        nav item centre (measured)  in-page action point (measured)
            # 11 items at 50px pitch: 228,278,328,378,428,478,528,578,628,678,728 (measured;
            # cross-checked against 4 independently-hit anchors)
            home      = @{ Nav = '150,228' }
            button    = @{ Nav = '150,278'; Act = '475,147' }  # Click me -> "clicked 1"
            textblock = @{ Nav = '150,328'; Act = '475,250' }  # Cycle trim -> "trim = CharacterEllipsis"
            textbox   = @{ Nav = '150,378'; Act = '568,560' }  # Read text -> rich text content
            checkbox  = @{ Nav = '150,428'; Act = '502,180' }  # 3-state checkbox -> "notifications = off"
            toggle    = @{ Nav = '150,478'; Act = '420,172' }  # switch body -> "autosave off"
            slider    = @{ Nav = '150,528'; Act = '600,196;535,315;535,315' } # track; 2x busy -> "ring idle"
            numberbox = @{ Nav = '150,578'; Act = '460,270' }  # Double it -> "quantity = 2"
            combobox  = @{ Nav = '150,628'; Act = '460,345' }  # Select Dark -> "theme = Dark"
            autosuggest = @{ Nav = '150,678'; Act = '450,150'; Type = 'ap' } # suggestions apple/apricot
            datetime  = @{ Nav = '150,728'; Act = '460,345' }  # Set to today -> "date ticks = ..."
        }
    }
    '17' = @{
        Dir  = '17-controls-collections'
        Exe  = 'examples\17-controls-collections\x64\Debug\CollectionsGallery\CollectionsGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{
            # 5 items, ~72px pitch (measured: home 238, listview 310, gridview 382, treeview 454, table 526)
            home    = @{ Nav = '150,238' }
            listview  = @{ Nav = '150,310'; Act = '450,205' }  # banana item -> "selected = banana"
            gridview  = @{ Nav = '150,382'; Act = '722,457' }  # Next -> "flip page = 2"
            treeview  = @{ Nav = '150,454'; Act = '460,470' }  # Expand all -> "expanded 9 nodes"
            table     = @{ Nav = '150,526'; Act = '450,175' }  # first row -> "row = write guide"
        }
    }
    '21' = @{
        Dir  = '21-controls-shell'
        Exe  = 'examples\21-controls-shell\x64\Debug\ShellGallery\ShellGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{
            # 6 items, ~72px pitch (measured)
            home          = @{ Nav = '150,238' }
            tabview        = @{ Nav = '150,310'; Act = '490,152' }  # second tab -> "tab = notes.md"
            navigationview = @{ Nav = '150,382'; Act = '520,165' }  # Compact -> "pane mode = LeftCompact"
            commandbar     = @{ Nav = '150,454'; Act = '440,165' }  # Add -> "command: add"
            dialogs        = @{ Nav = '150,526'; Act = '440,150;450,540' } # dialog + Remove -> "primary: removed"
            overlays       = @{ Nav = '150,598'; Act = '470,152;450,300' } # tip + severity -> "severity = success"
        }
    }
    '26' = @{
        Dir  = '26-customization'
        Exe  = 'examples\26-customization\x64\Debug\CustomGallery\CustomGallery.exe'
        Size = @(900, 1100)
        Pages = [ordered]@{
            # 6 items, ~72px pitch (measured)
            home          = @{ Nav = '150,238' }
            styles        = @{ Nav = '150,310'; Act = '460,150' }  # implicit styled -> "styled button works"
            customcontrol = @{ Nav = '150,382'; Act = '450,265' }  # Bump value -> "value = 1"
            vsm           = @{ Nav = '150,454'; Act = '450,150' }  # Force narrow -> "state = narrow (manual)"
            animation     = @{ Nav = '150,526'; Act = '450,165' }  # Animate -> rect 40->320 + "animated, shots = 1"
            drawing       = @{ Nav = '150,598'; Act = '500,230' }  # color picker -> "color = R,G,B" + dot recolor
        }
    }
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
