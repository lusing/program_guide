$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$exes = Get-ChildItem -Path (Join-Path $root "examples") -Recurse -Filter *.exe |
    Where-Object { $_.FullName -like "*bin\Debug\net10.0-windows*" -and $_.Name -notlike "apphost*" }

$failed = 0
foreach ($exe in $exes) {
    $name = $exe.Directory.Parent.Parent.Name
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
Write-Output ("---- {0} projects, {1} failed" -f $exes.Count, $failed)
exit $failed
