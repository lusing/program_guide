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
                # 取数层按平台分两条路，但**对外吐出的对象形状完全一致**
                # （Machine/Drive/FreeRatio/Low），调用方与 12 章的流水线无需改动：
                #   Windows 有 CIM → Win32_LogicalDisk（Size / FreeSpace 独立字段）
                #   Unix/macOS 无 CIM/WMI → Get-PSDrive（只有 Free，总量自己 Used+Free 算）
                $hasCim = [bool](Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                if (-not $hasCim -and $computer -ne 'localhost') {
                    throw '本平台无 CIM/WMI 栈，只支持本机（localhost）查询'
                }
                if ($hasCim) {
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
                else {
                    Get-PSDrive -PSProvider FileSystem -ErrorAction Stop |
                        Where-Object { $null -ne $_.Used -and ($_.Used + $_.Free) -gt 0 } |
                        ForEach-Object {
                            $total = $_.Used + $_.Free
                            $freeRatio = if ($total -gt 0) { [math]::Round($_.Free / $total * 100, 0) } else { 0 }
                            [pscustomobject]@{
                                Machine   = $computer
                                Drive     = $_.Name
                                FreeRatio = $freeRatio
                                Low       = ($freeRatio -lt $MinFreePct)
                            }
                        }
                }
            }
            catch {
                Write-Warning "无法查询 ${computer}：$($_.Exception.Message)"
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
