# 冒烟测试：把每个示例 exe 拉起 3 秒——不退出即视为窗体正常显示（wpf 教程同款判据）。
# 覆盖三语言产物：
#   csharp/fsharp: examples/NN_*/{csharp,fsharp}/bin/Release/net10.0-windows/*.exe
#   cpp:           examples/NN_*/cpp/host/bin/x64/Release/net10.0-windows/*.exe（混合模式 DLL 的托管启动器）
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$exes = Get-ChildItem -LiteralPath (Join-Path $root "examples") -Recurse -Filter *.exe -File |
    Where-Object {
        $_.FullName -match 'bin\\(x64\\)?Release\\net10\.0-windows' -and
        $_.Name -notmatch '^(apphost|testhost)'
    }

if ($exes.Count -eq 0) { Write-Output "没有找到任何 exe——先运行 build.ps1"; exit 1 }

$failed = 0
foreach ($exe in $exes) {
    $rel = $exe.FullName.Substring($root.Length + 1)
    $p = Start-Process -FilePath $exe.FullName -PassThru
    Start-Sleep -Seconds 3
    if ($p.HasExited) {
        Write-Output ("FAIL  {0} (exit {1})" -f $rel, $p.ExitCode)
        $failed++
    } else {
        Write-Output ("OK    {0}" -f $rel)
        Stop-Process -Id $p.Id -Force
        Start-Sleep -Milliseconds 250
    }
}
Write-Output ("---- {0} exes, {1} failed" -f $exes.Count, $failed)
exit $failed
