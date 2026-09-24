param()
# 17-data-explorer functional smoke: four flows on the self-positioned
# 1750x1085 window (origin 53,53; tap.ps1 uses live-rect math anyway).
#   TreeView Images node   (85,278)   - child row estimate, rows are big targets
#   filter TextBox         (420,80)
#   Cards toggle           (600,80)
#   table row 0            (500,225)
#   FlipView next arrow    (1465,995)
$exe = 'G:\code\guide\WinUI3\examples\17-data-explorer\x64\Debug\DataExplorer\DataExplorer.exe'
$tap = 'G:\code\guide\WinUI3\tools\ui-smoke\tap.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\17-data-explorer\'

# 1) tree filter: tap the Images category -> count line "3 items · Images"
& $tap -Exe $exe -OutDir ($out + 'tree') -Taps '85,278' -Attempts 6 | Select-Object -Last 1
# 2) text filter: focus the box, type "jpg" -> "1 items · All · 'jpg'"
& $tap -Exe $exe -OutDir ($out + 'filter') -Taps '420,80' -TypeText 'jpg' -Attempts 6 | Select-Object -Last 1
# 3) cards view: toggle Cards -> GridView of cards replaces the table
& $tap -Exe $exe -OutDir ($out + 'cards') -Taps '600,80' -Attempts 6 | Select-Object -Last 1
# 4) details: tap row 0 (report-q3.docx) -> FlipView shows it, then tap the
#    next arrow -> details advance to notes.txt
& $tap -Exe $exe -OutDir ($out + 'flip') -Taps '500,225;1465,995' -Attempts 6 | Select-Object -Last 1
