param()
# 07-settings-hub functional smoke: three real flows, all plain mouse clicks.
#
# Hard-won calibration notes (full story in the smoke-testing chapter):
#   * nav item centres A=(140,166) N=(140,238) P=(140,310) - 72px pitch.
#   * Dark radio (681,347), master switch (460,296), Save button (538,666) -
#     all pixel-measured with find-blob.ps1 (vision reads of grid overlays
#     proved unreliable).
#   * THE pit: pages wrapped in a ScrollViewer swallow injected clicks for
#     ButtonBase controls (the press lands, the click never completes) while
#     nav rows, ToggleSwitch and Slider keep working. AppearancePage therefore
#     uses a plain StackPanel; keep it that way or the theme flow dies.
#   * WinUI dark background is rgb(43,43,43) here, not #202020.
$exe = 'G:\code\guide\WinUI3\examples\07-settings-hub\x64\Debug\SettingsHub\SettingsHub.exe'
$ui  = 'G:\code\guide\WinUI3\tools\ui-smoke\ui-smoke.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\07-settings-hub\'

# The Notifications page auto-opens its TeachingTip on the first visit ever and
# the tip sits on top of the channels we want to verify; seed seenTip=true so the
# run behaves like a returning user (the tip itself is covered by the chapter).
$store = Join-Path $env:LOCALAPPDATA 'SettingsHub'
New-Item -ItemType Directory -Force -Path $store | Out-Null
Set-Content -Path (Join-Path $store 'settings.json') -Value '{"seenTip":"true"}' -NoNewline

# Zombie SettingsHub processes from earlier runs leave a hidden window parked at
# (100,100) that silently swallows injected clicks aimed at the fresh instance.
# Kill every survivor before launching the next one.
function Clear-Zombies {
    Get-Process SettingsHub -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 600
}

# 1) theme: click Dark radio on the startup page -> whole window re-skins
Clear-Zombies
& $ui -Exe $exe -OutDir ($out + 'theme') -WindowW 1080 -WindowH 800 -ParkX 120 -Clicks '681,347' | Select-Object -Last 1
# 2) master switch: nav Notifications -> flip master off -> channels disabled
Clear-Zombies
& $ui -Exe $exe -OutDir ($out + 'master') -WindowW 1080 -WindowH 800 -ParkX 320 -Clicks '140,238;460,296' | Select-Object -Last 1
# 3) save flow: nav Preferences -> Save -> progress fills + InfoBar
Clear-Zombies
& $ui -Exe $exe -OutDir ($out + 'save') -WindowW 1080 -WindowH 800 -ParkX 520 -Clicks '140,310;538,666' | Select-Object -Last 1
Clear-Zombies
