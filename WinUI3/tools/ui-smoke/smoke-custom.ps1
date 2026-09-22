param()
$exe = 'G:\code\guide\WinUI3\examples\26-customization\x64\Debug\CustomGallery\CustomGallery.exe'
$ui  = 'G:\code\guide\WinUI3\tools\ui-smoke\ui-smoke.ps1'
$specs = @(
    @{ Tag = 'styles';        Clicks = '150,310;460,150' }
    @{ Tag = 'customcontrol'; Clicks = '150,382;450,265' }
    @{ Tag = 'vsm';           Clicks = '150,454;450,150' }
    @{ Tag = 'animation';     Clicks = '150,526;450,165' }
    @{ Tag = 'drawing';       Clicks = '150,598;500,230' }
)
foreach ($s in $specs) {
    & $ui -Exe $exe -OutDir ("G:\code\guide\WinUI3\.smoke\26-customization\" + $s.Tag) `
        -WindowW 900 -WindowH 1100 -Clicks $s.Clicks | Select-Object -Last 1
}
