param()
# 09-scratchpad functional smoke: four real flows, tap.ps1 (touch injection)
# everywhere. Coordinates are window-relative on the natural 1750x1155 window
# (1000x660 logical at 175% DPI); tap.ps1 never moves the window.
#   editor body  (500,400)
#   first tab close X  (~240,135)  - calibrated from the before.png layout
#   dialog Save button (~875,700)  - centered ContentDialog primary button
$exe = 'G:\code\guide\WinUI3\examples\09-scratchpad\x64\Debug\ScratchPad\ScratchPad.exe'
$tap = 'G:\code\guide\WinUI3\tools\ui-smoke\tap.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\09-scratchpad\'

$store = Join-Path $env:LOCALAPPDATA 'ScratchPad'
New-Item -ItemType Directory -Force -Path $store | Out-Null
Remove-Item -Path (Join-Path $store '*.txt') -Force -ErrorAction SilentlyContinue

# 1) save: type into the editor, Ctrl+S -> file on disk with the exact text
& $tap -Exe $exe -OutDir ($out + 'save') -Taps '500,400' -TypeText 'hello scratchpad' -KeysAfter 'ctrl,s' -Attempts 10 | Select-Object -Last 1

# 2) bold: type, Ctrl+A (select all), Ctrl+B (bold), Ctrl+S -> bold glyphs saved
& $tap -Exe $exe -OutDir ($out + 'bold') -Taps '500,400' -TypeText 'bold me now' -KeysAfter 'ctrl,a,ctrl,b,ctrl,s' -Attempts 10 | Select-Object -Last 1

# 3) find: type, Ctrl+F (expander opens, find box focused), type "a" -> match count
& $tap -Exe $exe -OutDir ($out + 'find') -Taps '500,400' -TypeText 'find apple and apricot' -KeysAfter 'ctrl,f,a' -Attempts 10 | Select-Object -Last 1

# 4) close-confirm: type (dirty), tap the tab close X -> ContentDialog, tap Save
& $tap -Exe $exe -OutDir ($out + 'close') -Taps '500,400' -TypeText 'unsaved work' -TapsAfter '240,135;875,700' -Attempts 10 | Select-Object -Last 1
