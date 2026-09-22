param()
$exe = 'G:\code\guide\WinUI3\examples\21-controls-shell\x64\Debug\ShellGallery\ShellGallery.exe'
$ui  = 'G:\code\guide\WinUI3\tools\ui-smoke\ui-smoke.ps1'
$specs = @(
    @{ Tag = 'tabview';        Clicks = '150,310;490,152' }
    @{ Tag = 'navigationview'; Clicks = '150,382;520,165' }
    @{ Tag = 'commandbar';     Clicks = '150,454;440,165' }
    @{ Tag = 'dialogs';        Clicks = '150,526;440,150;450,540' }
    @{ Tag = 'overlays';       Clicks = '150,598;470,152;450,300' }
)
foreach ($s in $specs) {
    & $ui -Exe $exe -OutDir ("G:\code\guide\WinUI3\.smoke\21-controls-shell\" + $s.Tag) `
        -WindowW 900 -WindowH 1100 -Clicks $s.Clicks | Select-Object -Last 1
}
