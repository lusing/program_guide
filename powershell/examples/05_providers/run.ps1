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
# Registry 提供程序是 Windows-only；Unix 上内置集是 FileSystem/Environment/Variable/Function/Alias。
# 教学点是「Get-PSProvider 能列出当前宿主真实可用的提供程序」，所以按实际清单断言，
# 六项齐全只在 Windows 上成立（这是平台事实，不是示例退化）。
$providers = @((Get-PSProvider).Name)
$coreFive = @('FileSystem', 'Environment', 'Variable', 'Function', 'Alias')
Check (@($providers | Where-Object { $_ -in $coreFive }).Count -eq 5) '内置五提供程序齐全（跨平台）'
if ($providers -contains 'Registry') {
    Check ((@($providers | Where-Object { $_ -in ($coreFive + 'Registry') }).Count) -eq 6) '内置六提供程序齐全（Windows 含 Registry）'
}
else { Skip '本平台无 Registry 提供程序（注册表是 Windows 概念） [platform]' }

# —— 2) 注册表：项/属性统一词汇（HKCU 临时键，自演自净） ——
if ($providers -contains 'Registry') {
    $key = 'HKCU:\SOFTWARE\ps-tutorial-tmp'
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name 'Lesson' -Value 5 -PropertyType DWord | Out-Null
    Check ((Get-ItemProperty -Path $key).Lesson -eq 5) '注册表键值写入后可读'
    Check (@(Get-ChildItem $key).Count -eq 0) '新键无子键'
    Remove-Item $key -Recurse
    Check (-not (Test-Path $key)) '注册表临时键清理'
}
else {
    # 注册表不可用时，用 FileSystem 提供程序演示「同一套 Item/ItemProperty 词汇跨提供程序通用」——
    # 但要注意**属性名由提供程序自己定义**：FileSystem 只认 IsReadOnly/Length 这类
    # 内建属性，Env:/Variable: 则整个 IPropertyCmdletProvider 接口都没实现
    # （原示例第 4 节的 Env: 断言就是这个意思）。这比硬造一个注册表替身更贴近真实。
    $regWork = Join-Path $PSScriptRoot 'tmp-fsprop'
    New-Item -ItemType Directory -Force -Path $regWork | Out-Null
    $regFile = Join-Path $regWork 'a.txt'
    Set-Content -Path $regFile -Value 'x' -Encoding UTF8
    Set-ItemProperty -Path $regFile -Name IsReadOnly -Value $true
    Check ((Get-ItemProperty -Path $regFile).IsReadOnly -eq $true) 'ItemProperty 写读词汇在 FileSystem: 上同样成立（注册表替身）'
    Set-ItemProperty -Path $regFile -Name IsReadOnly -Value $false
    Remove-Item $regWork -Recurse -Force
    Check (-not (Test-Path $regWork)) '注册表临时键清理（FileSystem 替身自清理） [platform]'
}

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
# Function: 驱动器装的是**会话里定义的函数**。mkdir 在 Windows 上是 PowerShell 函数，
# 在 Unix 上却是 /bin/mkdir 这个外部程序（Get-Command 的 CommandType 是 Application）——
# 命令解析优先序 Function > Alias > Cmdlet > Application，两平台都成立。
$mkdirCmd = Get-Command mkdir -ErrorAction SilentlyContinue
Check ($null -ne $mkdirCmd) 'mkdir 可解析到某个命令'
if ($mkdirCmd.CommandType -eq 'Function') {
    Check ((Get-Item Function:\mkdir).Name -eq 'mkdir') 'Function: 驱动器里 mkdir 是函数'
}
else {
    Check ($mkdirCmd.CommandType -eq 'Application') "mkdir 在本平台是外部程序（CommandType=$($mkdirCmd.CommandType)），不经 Function: 驱动器 [platform]"
}

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
