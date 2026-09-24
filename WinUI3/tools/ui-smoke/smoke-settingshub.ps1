param()
# 07-settings-hub functional smoke: four real flows.
#
# Hard-won calibration notes (full story in the smoke-testing chapter notes and
# memory/winui3-input-injection.md):
#   * NEVER move or resize the app window - any SetWindowPos after the XAML
#     island settles corrupts its input transform. tap.ps1 leaves the window at
#     its cascade position and computes screen points from the live rect.
#   * Mouse-event clicks never complete a ButtonBase Click on this 175% DPI
#     box; touch injection (tap.ps1) walks the real pointer stack and works.
#     Whether a launch accepts injected input at all is a lottery, so every
#     flow retries with a fresh process until the last frame differs.
#   * NavigationView pane (natural window, 1.75x): nav A=(140,243) N=(140,315)
#     P=(140,387) after the AutoSuggestBox slot; page content: Dark radio
#     (987,314), master switch (460,296), Save button (538,666).
$exe = 'G:\code\guide\WinUI3\examples\07-settings-hub\x64\Debug\SettingsHub\SettingsHub.exe'
$tap = 'G:\code\guide\WinUI3\tools\ui-smoke\tap.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\07-settings-hub\'

# The Notifications page auto-opens its TeachingTip on the first visit ever and
# the tip sits on top of the channels we want to verify; seed seenTip=true so the
# run behaves like a returning user (the tip itself is covered by the chapter).
$store = Join-Path $env:LOCALAPPDATA 'SettingsHub'
New-Item -ItemType Directory -Force -Path $store | Out-Null
Set-Content -Path (Join-Path $store 'settings.json') -Value '{"seenTip":"true"}' -NoNewline

# 1) theme: tap Dark radio on the startup page -> whole window re-skins
& $tap -Exe $exe -OutDir ($out + 'theme') -Taps '987,314' -Attempts 4 | Select-Object -Last 1
# 2) master switch: nav Notifications -> flip master off -> channels disabled
& $tap -Exe $exe -OutDir ($out + 'master') -Taps '140,315;460,296' -Attempts 4 | Select-Object -Last 1
# 3) save flow: nav Preferences -> Save -> progress fills + InfoBar
& $tap -Exe $exe -OutDir ($out + 'save') -Taps '140,387;538,666' -Attempts 4 | Select-Object -Last 1
# 4) search: tap the pane AutoSuggestBox, type "Pref", pick the suggestion
#    (down + enter) -> SuggestionChosen really navigates to Preferences
& $tap -Exe $exe -OutDir ($out + 'search') -Taps '140,175' -TypeText 'Pref' -KeysAfter 'down,enter' -Attempts 4 | Select-Object -Last 1
