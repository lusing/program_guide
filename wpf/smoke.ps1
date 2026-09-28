# 冒烟测试：每个示例 exe 拉起 3 秒不退出即通过（能抓运行期 XAML/资源/类型初始化错误）。
# 覆盖三种语言的产物布局：
#   csharp/fsharp: examples/NN/xxx/bin/Release/net10.0-windows/*.exe
#   cpp:           examples/NN/xxx/cpp/host/bin/x64/Release/net10.0-windows/*.exe
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$exes = Get-ChildItem -LiteralPath (Join-Path $root "examples") -Recurse -Filter *.exe |
    Where-Object { $_.FullName -match 'bin\\(x64\\)?Release\\net10\.0-windows' -and $_.Name -notmatch '^(apphost|testhost|createdump)' }

$failed = 0
foreach ($exe in $exes) {
    $name = ($exe.FullName -replace [regex]::Escape($root + '\'), '')
    $p = Start-Process -FilePath $exe.FullName -PassThru
    Start-Sleep -Seconds 3
    if ($p.HasExited) {
        Write-Output ("FAIL  {0} (exit {1})" -f $name, $p.ExitCode)
        $failed++
    } else {
        Write-Output ("OK    {0}" -f $name)
        Stop-Process -Id $p.Id -Force
        Start-Sleep -Milliseconds 300
    }
}
Write-Output ("---- {0} exes, {1} failed" -f $exes.Count, $failed)
exit $failed
