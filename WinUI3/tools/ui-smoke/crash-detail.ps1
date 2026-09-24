param([int]$Index = 1)
$e = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000} -MaxEvents $Index | Select-Object -First 1
$i = 0
$e.Properties | ForEach-Object { $i++; "[$i] $($_.Value)" } | Select-Object -First 22
