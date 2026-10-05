# InventoryModule.psm1 —— 收官项目模块（33 章）：取数 + 导出，全部按 23/25/26 章规范
function Get-InvMachineInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$ComputerName,

        [ValidateRange(1, 100)]
        [int]$MinFreePct = 10
    )
    process {
        foreach ($computer in $ComputerName) {
            try {
                Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop |
                    ForEach-Object {
                        $freeRatio = if ($_.Size -gt 0) { [math]::Round($_.FreeSpace / $_.Size * 100, 0) } else { 0 }
                        [pscustomobject]@{
                            Machine   = $computer
                            Drive     = $_.DeviceID
                            FreeRatio = $freeRatio
                            Low       = ($freeRatio -lt $MinFreePct)
                        }
                    }
            }
            catch {
                Write-Warning "无法查询 $computer：$($_.Exception.Message)"
            }
        }
    }
}

function Export-InvReport {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject[]]$InputObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateSet('Csv', 'Json')]
        [string]$Format = 'Csv'
    )
    begin { $collected = @() }
    process { $collected += $InputObject }
    end {
        if ($PSCmdlet.ShouldProcess($Path, "导出 $($collected.Count) 条（$Format）")) {
            if ($Format -eq 'Csv') {
                $collected | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            }
            else {
                $collected | ConvertTo-Json -Depth 4 | Set-Content -Path $Path -Encoding UTF8
            }
            Get-Item -Path $Path
        }
    }
}
Export-ModuleMember -Function Get-InvMachineInfo, Export-InvReport
