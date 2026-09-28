param()
# 40-webview-host functional smoke: webview core init + local page + message round-trip.
#   window: self-positioned 1080x620 logical @ (30,30) -> 1890x1085 physical @ (53,53)
#   measured on this 175% machine:
#     "Get title"    (705,205)     "Post to page"   (880,205)
$exe = 'G:\code\guide\WinUI3\examples\40-webview-host\x64\Debug\WebViewHost\WebViewHost.exe'
$tap = 'G:\code\guide\WinUI3\tools\ui-smoke\tap.ps1'
$out = 'G:\code\guide\WinUI3\.smoke\40-webview-host\'

# 1) launch alone: status "webview2 ready -> local page" + rendered page
& $tap -Exe $exe -OutDir ($out + 'launch') -Taps ';' -Attempts 2 | Select-Object -Last 1

# 2) script + post: ExecuteScriptAsync returns the title; PostWebMessageAsJson lands
#    in the page's message listener ("host says: {...}")
& $tap -Exe $exe -OutDir ($out + 'roundtrip') -Taps '705,205;880,205' -Attempts 8 | Select-Object -Last 1
