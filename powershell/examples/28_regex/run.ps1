#Requires -Version 5.1
# 示例 28：正则——语法、$matches、-replace、-split、Select-String、日志解析、Escape
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 基础语法 ——
Check ('don' -match 'd[aeiou]n') '字符类匹配'
Check (('dooon' -match 'd[aeiou]n') -eq $false) '单字符类吃不下 oo'
Check ('dooon' -match 'd[aeiou]+n') '量词 + 允许多次'
Check ('Don' -match '^d.n$') '锚定 ^ 与 $'
Check ('2026-10-06 09:30:00' -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') '时间戳模式'
Check ('192.168.1.10' -match '^\d{1,3}(\.\d{1,3}){3}$') 'IPv4 长相模式'

# —— 2) $matches 与命名分组 ——
'2026-10-06 INFO boot ok' -match '^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})\s+(?<level>\w+)\s+(?<msg>.*)$' | Out-Null
Check ($Matches['year'] -eq '2026' -and $Matches['level'] -eq 'INFO') '命名分组按名取值'
Check ($Matches[0] -match '^2026') '$matches[0] 是整体匹配'
Check (@(@('a1', 'b2', 'c') -match '\d').Count -eq 2) '数组在左：-match 变过滤器'

# —— 3) -replace 与 -split ——
Check (('Don Jones' -replace '(\w+) (\w+)', '$2, $1') -eq 'Jones, Don') '-replace 分组引用（单引号）'
Check (('2026-10-06' -replace '-', '/') -eq '2026/10/06') '-replace 简单形态'
Check ((('one1two2three' -split '\d') -join '|') -eq 'one|two|three') '-split 正则切分'

# —— 4) Select-String 与 MatchInfo ——
$work = Join-Path $PSScriptRoot 'tmp-re'
New-Item -ItemType Directory -Force -Path $work | Out-Null
@'
2026-10-06 09:00:01 INFO start
2026-10-06 09:00:02 WARN slow-query
2026-10-06 09:00:03 ERROR disk-full
2026-10-06 09:00:04 ERROR timeout
'@ | Set-Content -Path (Join-Path $work 'app.log') -Encoding UTF8
$hits = @(Select-String -Path (Join-Path $work 'app.log') -Pattern 'ERROR')
Check ($hits.Count -eq 2) 'Select-String 命中计数'
Check ($hits[0].Line -match 'disk-full' -and $hits[0].LineNumber -eq 3) 'MatchInfo 携带行号与内容'
Check (@(Select-String -Path (Join-Path $work 'app.log') -Pattern 'slow' -SimpleMatch).Count -eq 1) '-SimpleMatch 字面匹配'

# —— 5) 日志解析成对象（文本进对象世界） ——
$parsed = foreach ($line in (Get-Content (Join-Path $work 'app.log'))) {
    if ($line -match '^(?<t>\S+ \S+) (?<lv>\w+) (?<msg>.*)$') {
        [pscustomobject]@{ Time = $Matches['t']; Level = $Matches['lv']; Message = $Matches['msg'] }
    }
}
Check (@($parsed).Count -eq 4) '日志全部解析成对象'
Check (@($parsed | Where-Object Level -eq 'ERROR').Count -eq 2) '解析结果可按级别过滤'
Remove-Item $work -Recurse -Force

# —— 6) .NET Regex 后门 ——
Check ([regex]::IsMatch('abc', '^a')) '[regex]::IsMatch'
Check ((@([regex]::Matches('a1 b22 c333', '\d+') | ForEach-Object { $_.Value }) -join ',') -eq '1,22,333') '[regex]::Matches 多命中'
Check ([regex]::Escape('C:\Temp\1+1') -match '\\\+') 'Escape 转义特殊字符'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
