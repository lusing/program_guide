#Requires -Version 5.1
# 示例 31：类与结构化数据——class/继承/enum、JSON 深度与往返、-AsHashtable 分岔
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) class：构造、静态、方法 ——
class MachineInfo {
    [string]$Name
    [int]$Score = 0
    static [int]$Created = 0
    MachineInfo([string]$name) { $this.Name = $name; [MachineInfo]::Created++ }
    MachineInfo([string]$name, [int]$score) { $this.Name = $name; $this.Score = $score; [MachineInfo]::Created++ }
    [string] Describe() { return "$($this.Name):$($this.Score)" }
    [void] AddScore([int]$d) { $this.Score += $d }
}
$m = [MachineInfo]::new('srv1', 80)
Check ($m.Describe() -eq 'srv1:80') 'class 构造与方法'
$m.AddScore(5)
Check ($m.Score -eq 85) '方法修改实例状态'
Check ([MachineInfo]::Created -ge 1) '静态成员经类名访问'
$badType = $false
try { $m.Score = 'abc' } catch { $badType = $true }
Check ($badType) '属性类型编译期把关（赋值即报错）'

# —— 2) 继承与方法覆盖 ——
class ScoredMachine : MachineInfo {
    [string]$Owner
    ScoredMachine([string]$name, [int]$score, [string]$owner) : base($name, $score) { $this.Owner = $owner }
    [string] Describe() { return "$($this.Name)@$($this.Owner):$($this.Score)" }
}
$sm = [ScoredMachine]::new('srv2', 90, 'ops')
Check ($sm.Describe() -eq 'srv2@ops:90') '继承+构造转发+方法覆盖'
Check ($sm -is [MachineInfo]) '子类 -is 基类'

# —— 3) enum：取值域与 switch ——
enum EnvKind { Development; Test; Production }
function Get-EnvRank {
    param([EnvKind]$Environment)
    switch ($Environment) {
        'Development' { 1 }
        'Test' { 2 }
        'Production' { 3 }
    }
}
Check ((Get-EnvRank -Environment Production) -eq 3) 'enum 参数+switch 分支'
Check ((Get-EnvRank -Environment 'prod') -eq 3) 'enum 绑定接受前缀缩写（prod→Production，与参数名缩写同理）'
$badEnum = $false
try { Get-EnvRank -Environment 'zzz非法' } catch { $badEnum = $true }
Check ($badEnum) 'enum 真非法值门口拦截'
Check ([int][EnvKind]::Production -eq 2) 'enum 底层整数值'

# —— 4) JSON：深度截断与往返保真 ——
$deep = @{ A = @{ B = @{ C = @{ D = '贵重数据' } } } }
$truncWarn = $null
$trunc = & { $deep | ConvertTo-Json } 3>&1
$truncText = (@($trunc | Where-Object { $_ -is [string] }) -join "`n")
$warnText = (@($trunc | Where-Object { $_ -isnot [string] }) -join ' ')
Check ($truncText -notmatch '贵重数据') '默认 Depth=2 截断四层嵌套（坑一实证）'
if ($PSVersionTable.PSVersion.Major -ge 6) {
    Check ($warnText -match '截断|depth') 'pwsh 7 截断伴随警告流（第 3 流） [ch7-only]'
}
else {
    Skip '5.1 截断连警告都没有（纯静默，更危险） [ch7-only]'
}
$full = $deep | ConvertTo-Json -Depth 5
$back = $full | ConvertFrom-Json
Check ($back.A.B.C.D -eq '贵重数据') '显式 Depth 保真并可读回'
$flat = [pscustomobject]@{ Name = 'svc'; Port = 9100 }
$rt = ($flat | ConvertTo-Json -Depth 5) | ConvertFrom-Json
Check ($rt.Name -eq $flat.Name -and $rt.Port -eq $flat.Port) 'JSON 往返保真（标量与数字）'
$comp = $flat | ConvertTo-Json -Compress
Check ($comp -notmatch "`n" -and $comp.Length -lt 40) '-Compress 单行压缩'

# —— 5) -AsHashtable：pwsh 7 独有 ——
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('AsHashtable')) {
    $h = '{ "a": 1 }' | ConvertFrom-Json -AsHashtable
    $h['b'] = 2
    Check ($h['b'] -eq 2) '-AsHashtable 产出可变哈希表 [ch7-only]'
}
else {
    Skip '5.1 无 -AsHashtable（读回 pscustomobject 不可随意加键） [ch7-only]'
}

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
