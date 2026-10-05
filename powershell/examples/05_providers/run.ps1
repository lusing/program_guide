#Requires -Version 5.1
# 示例 05：提供程序——注册表/环境变量/自造 PSDrive 的统一 Item 操作（自演自净）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 提供程序清单 ——
$providers = (Get-PSProvider).Name
Check (@($providers | Where-Object { $_ -in 'FileSystem', 'Registry', 'Environment', 'Variable', 'Function', 'Alias' }).Count -eq 6) '内置六提供程序齐全'

# —— 2) 注册表：项/属性统一词汇（HKCU 临时键，自演自净） ——
$key = 'HKCU:\SOFTWARE\ps-tutorial-tmp'
New-Item -Path $key -Force | Out-Null
New-ItemProperty -Path $key -Name 'Lesson' -Value 5 -PropertyType DWord | Out-Null
Check ((Get-ItemProperty -Path $key).Lesson -eq 5) '注册表键值写入后可读'
Check (@(Get-ChildItem $key).Count -eq 0) '新键无子键'
Remove-Item $key -Recurse
Check (-not (Test-Path $key)) '注册表临时键清理'

# —— 3) Env: 项视角与 $env: 快通道 ——
$env:PSTUTORIAL = 'demo'
Check ((Get-Item Env:\PSTUTORIAL).Value -eq 'demo') 'Env: 按项访问取值'
Check ($env:PSTUTORIAL -eq 'demo') '$env: 快通道取值'
Remove-Item Env:\PSTUTORIAL
Check ($null -eq (Get-Item Env:\PSTUTORIAL -ErrorAction SilentlyContinue)) '环境变量删除'
$propErr = $null
try { Get-ItemProperty -Path Env:\USERNAME -ErrorAction Stop | Out-Null } catch { $propErr = $_ }
Check ($null -ne $propErr) 'Env: 提供程序不支持 Get-ItemProperty（能力差异实证）'

# —— 4) Variable: 与 Function: 提供程序 ——
Check ($null -ne (Get-Item Variable:\PSVersionTable)) 'Variable: 驱动器可访问变量'
Check ((Get-Item Function:\mkdir).Name -eq 'mkdir') 'Function: 驱动器里 mkdir 是函数'

# —— 5) 自造 PSDrive（会话级，自清理） ——
$dir = Join-Path $PSScriptRoot 'tmp-drive'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
New-PSDrive -Name Tut -PSProvider FileSystem -Root $dir | Out-Null
Set-Content -Path 'Tut:\note.txt' -Value 'hi' -Encoding UTF8
Check (Test-Path 'Tut:\note.txt') 'PSDrive 上建文件'
Check (@(Get-ChildItem Tut:).Count -eq 1) 'PSDrive 遍历子项'
Remove-PSDrive -Name Tut
$leak = $false
try { Get-ChildItem Tut: -ErrorAction Stop | Out-Null } catch { $leak = $true }
Check ($leak) 'Remove-PSDrive 后盘符消失'
Remove-Item $dir -Recurse -Force

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
