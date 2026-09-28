param()
# 37-media-library functional smoke: SQLite persistence across launches.
#   window: self-positioned 1080x620 logical @ (30,30) -> 1890x1085 physical @ (53,53)
#   measured on this 175% machine:
#     "Add Item" (accent)      (640,205)
#     first ListView row       (500,300)
#     "Delete Selected"        (800,205)
#   status line is the smoke anchor (top row).
$exe = 'G:\code\guide\WinUI3\examples\37-media-library\x64\Debug\MediaLibrary\MediaLibrary.exe'
$tap = 'G:\code\guide\WinUI3\tools\ui-smoke\tap.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\37-media-library\'

# 1) insert: tap "Add Item" -> "inserted row N | N items (persisted)"
& $tap -Exe $exe -OutDir ($out + 'add') -Taps '640,205' -Attempts 6 | Select-Object -Last 1

# 2) persistence proof: relaunch must show the persisted count in the status line
& $tap -Exe $exe -OutDir ($out + 'relaunch') -Taps ';' -Attempts 2 | Select-Object -Last 1

# 3) delete: select the first row, then "Delete Selected"; verify on next relaunch
& $tap -Exe $exe -OutDir ($out + 'delete') -Taps '500,300;800,205' -Attempts 8 | Select-Object -Last 1
& $tap -Exe $exe -OutDir ($out + 'delete-verify') -Taps ';' -Attempts 2 | Select-Object -Last 1
