param([int]$Count = 3)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000} -MaxEvents $Count |
    ForEach-Object {
        '{0} {1} code={2} offset={3} module={4}' -f $_.TimeCreated,
            $_.Properties[0].Value, $_.Properties[6].Value,
            $_.Properties[7].Value, $_.Properties[4].Value
    }
