#Requires -Version 5.1
# 示例 06：管道初步——导出/导入往返、基线比对、HTML、Out 终点、变更类管道
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$work = Join-Path $PSScriptRoot 'tmp-pipe'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# —— 1) 固定样例数据（机器无关） ——
$sample = [pscustomobject]@{ Name = 'alpha'; Kind = 'tool' },
[pscustomobject]@{ Name = 'beta'; Kind = 'tool' },
[pscustomobject]@{ Name = 'gamma'; Kind = 'game' }

# —— 2) CSV 往返守恒 ——
$csv = Join-Path $work 'items.csv'
$sample | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$back = Import-Csv -Path $csv
Check (@($back).Count -eq 3) 'CSV 导入导出行数守恒'
Check ($back[0].Name -eq 'alpha' -and $back[2].Kind -eq 'game') 'CSV 字段值保真'
Check (@($sample).Count -eq 3 -and $sample[1].Name -eq 'beta') '原对象在管道外未被破坏'

# —— 3) Clixml 序列化与基线比对 ——
$base = Join-Path $work 'baseline.xml'
$sample | Export-Clixml -Path $base
$ref = Import-Clixml -Path $base
Check (@($ref).Count -eq 3) 'Clixml 往返守恒'
$changed = [pscustomobject]@{ Name = 'alpha'; Kind = 'tool' },
[pscustomobject]@{ Name = 'beta'; Kind = 'tool' },
[pscustomobject]@{ Name = 'delta'; Kind = 'tool' }
$diff = Compare-Object -ReferenceObject $ref -DifferenceObject $changed -Property Name
$marks = @($diff | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.SideIndicator)" }) -join ';'
Check ($marks -eq 'delta==>;gamma=<=' ) 'Compare-Object 方向断言（<= 缺失 / => 新增）'

# —— 4) ConvertTo 只转换、Out 落盘 ——
$html = $sample | ConvertTo-Html -Property Name, Kind
Check ("$html" -match '<html' -and "$html" -match 'alpha') 'ConvertTo-Html 只产出内容'
$htmlFile = Join-Path $work 'items.html'
$html | Out-File -FilePath $htmlFile -Encoding utf8
Check ((Get-Item $htmlFile).Length -gt 100) 'Out-File 负责落盘'

# —— 5) > 与 Out-File 等价 ——
$f1 = Join-Path $work 'redir.txt'
$f2 = Join-Path $work 'pipefile.txt'
Get-ChildItem $work -Filter '*.csv' > $f1
Get-ChildItem $work -Filter '*.csv' | Out-File -FilePath $f2
Check ((Get-Content $f1).Count -eq (Get-Content $f2).Count) '重定向符与 Out-File 行数等价'

# —— 6) 变更类管道：拉起自己的子进程再经管道停止（自演自净） ——
$kid = Start-Process -FilePath pwsh -ArgumentList '-NoProfile', '-Command', 'Start-Sleep', '-Seconds', '60' -WindowStyle Hidden -PassThru
$alive = Get-Process -Id $kid.Id
$alive | Stop-Process
$kid.WaitForExit(5000) | Out-Null
Check ($kid.HasExited) 'Get-Process | Stop-Process 管道闭环'

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
