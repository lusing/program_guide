param()
# 26-theme-lab functional smoke: two flows on the self-positioned 1750x1085
# window (origin 53,53).
#   preset list rows (ListBox, 56px pitch): item1 Morning Mist (100,228),
#   item2 Ink Stone (100,284), item3 Sunset (100,340), item4 Forest (100,396)
#   ColorPicker spectrum (~350,940)
$exe = 'G:\code\guide\WinUI3\examples\26-theme-lab\x64\Debug\ThemeLab\ThemeLab.exe'
$tap = 'G:\code\guide\WinUI3\tools\ui-smoke\tap.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\26-theme-lab\'

# 1) preset: tap Sunset -> dark shell + red accent (bars turn red)
& $tap -Exe $exe -OutDir ($out + 'preset') -Taps '100,340' -Attempts 6 | Select-Object -Last 1
# 2) colorpicker: tap the spectrum -> accent changes live, status text updates
& $tap -Exe $exe -OutDir ($out + 'picker') -Taps '350,940' -Attempts 6 | Select-Object -Last 1
