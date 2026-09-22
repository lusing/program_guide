$p = Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'MSBuild|CL\.exe|link\.exe|CppWinRT|midl|XamlCompiler' }
$p | Select-Object ProcessId, ParentProcessId, Name, CreationDate |
    Sort-Object CreationDate | Format-Table -AutoSize | Out-String
Get-Process MSBuild -ErrorAction SilentlyContinue |
    Select-Object Id, @{n='CPU_s';e={[math]::Round($_.CPU,1)}}, @{n='WS_MB';e={[math]::Round($_.WorkingSet64/1MB)}} |
    Format-Table -AutoSize | Out-String
