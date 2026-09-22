$z = Get-CimInstance Win32_Process -Filter "ProcessId=17360 OR ProcessId=14720" -ErrorAction SilentlyContinue
$z | Select-Object ProcessId, ParentProcessId, Name, CommandLine, ExecutablePath |
    Format-List | Out-String
