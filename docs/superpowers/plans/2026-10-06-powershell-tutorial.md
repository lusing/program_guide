# PowerShell 教程实现计划（34 章，8 批次）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `G:\code\guide\powershell\` 落地一份 34 章、自包含、双通道（pwsh 7 + Windows PowerShell 5.1）全绿验证的 PowerShell 开发指南。

**Architecture:** 以《Windows PowerShell 实战指南（第3版）》28 章为纲（书文本提取入 `materials/book/`），重组为 34 章六篇（27 教学章 + 7 现代扩充章 + 备忘清单收官）；每章一份 `docs/NN-slug.md`（讲解为主、文字多于代码）+ 一个 `examples/NN_slug/run.ps1`（自校验、写 `report.txt`）；`build.ps1` 双引擎跑全部示例并对账。

**Tech Stack:** PowerShell 7.6（pwsh，主通道）、Windows PowerShell 5.1（powershell.exe，副通道）、epub 文本提取（.NET ZipFile + 正则，无 OCR）。

**Spec:** `docs/superpowers/specs/2026-10-06-powershell-tutorial-design.md`

## Global Constraints（所有任务默认遵守）

- 正文以 **pwsh 7 为基准**；5.1 行为不同处显式标注差异（如 `Get-WmiObject` 仅 5.1、无 BOM 脚本 5.1 按 ANSI 解析）。
- 章文档 `docs/NN-slug.md`：**每章 ≥200 行、文字篇幅多于代码**；每段代码前有"为什么"、后有"在做什么+关键点"；`对应示例：examples/NN_slug/` 指路放章末且标注可选。
- **自包含**：正文可提原书名与作者，但所有概念、案例、清单必须在正文讲清；严禁"参见原书第 N 章"。
- 示例 `.ps1`/`.psd1` 一律 **UTF-8 带 BOM**（build.ps1 自动补并报告）；正文 `.md` 不带 BOM。
- 示例**协议**：`run.ps1` 自校验，报告行只写 `OK: <标签>` / `SKIP: <理由>` / `FAIL: <标签>`；报告经 `Out-File -Encoding utf8` 写入本目录 `report.txt`；有 FAIL 或断言失败 `exit 1`，否则 `exit 0`。
- **确定性**：`report.txt` 不得含版本号、机器名、路径、时间戳、随机值、机器相关集合计数；通道专属行以 ` [ch7-only]` / ` [ch51-only]` 结尾（对账前剥离）。
- **不改变系统状态**：远程章（13/18/19）先探针后演示，不通则 `SKIP:`；绝不 Enable-PSRemoting、绝不改 TrustedHosts、绝不写 HKLM。变更类演示一律自演自净（临时目录/键/进程建删成对）。
- 每批验收 = `pwsh -File build.ps1` 全绿后 commit，信息经 `-F` 文件提交（防安全层误判中文斜杠），结尾加 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 写某章前先读对应 `materials/book/chNN.txt`（**编号映射：N.xhtml = 第 N+1 章，提取时已重命名为 chNN.txt**），提炼要点；正文示例代码自己重写，不复制书的控制台截图文本。

## File Structure

```
powershell/
  build.ps1                  # 双通道验证器（Task 0 建成，全批共用）
  README.md                  # 分章导航+验证状态（Task 7）
  CHEATSheet.md              # 实测坑位汇总（各批滚动收录，Task 7 定稿）
  tools/extract-epub.ps1     # 书→txt 提取脚本（Task 0，一次性+可复现）
  tools/smoke.ps1            # 编码/协议冒烟（Task 0）
  materials/
    README.md                # 取材说明与章节映射
    book/ch01.txt ... ch28.txt
  docs/01-why-powershell.md ... 34-cheatsheet.md
  examples/01_why_powershell/run.ps1 ... 34_cheatsheet/run.ps1
  build/                     # 构建产物（git 忽略）
```

每个 `run.ps1` 的公共骨架（后续所有示例任务直接复用此模板，函数名/行为不得改）：

```powershell
#Requires -Version 5.1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }
# ……演示与断言……
$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
```

---

### Task 0: 骨架与双通道基建

**Files:**
- Create: `powershell/build.ps1`、`powershell/tools/extract-epub.ps1`、`powershell/tools/smoke.ps1`
- Create: `powershell/materials/README.md`、`powershell/materials/book/ch01..28.txt`
- Create: `powershell/.gitignore`（内容：`build/`、`examples/*/report.txt`）

**Interfaces:**
- Produces: `build.ps1`（用法 `pwsh -File build.ps1 [-Only 通配符]`，退出码 0=全绿）；报告协议（见 Global Constraints）；`tools/smoke.ps1`（冒烟）。

- [ ] **Step 1: 写 `tools/extract-epub.ps1` 并提取书文本**

```powershell
# extract-epub.ps1 — epub → materials/book/chNN.txt（N.xhtml = 第 N+1 章）
[CmdletBinding()] param([string]$Epub = 'G:\book\计算机\powershell\Windows PowerShell实战指南（第3版）.epub')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$outDir = Join-Path $PSScriptRoot '..\materials\book'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$zip = [System.IO.Compression.ZipFile]::OpenRead($Epub)
try {
    foreach ($entry in $zip.Entries | Where-Object { $_.FullName -match '^EPUB/(\d+)\.xhtml$' }) {
        $n = [int]$Matches[1] + 1                      # N.xhtml = 第 N+1 章
        $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
        $t = $reader.ReadToEnd(); $reader.Close()
        $t = $t -replace '<(pre|div|h[1-6]|p|li|tr)[^>]*>', "`n" -replace '<[^>]+>', ''
        Add-Type -AssemblyName System.Web
        $t = [System.Web.HttpUtility]::HtmlDecode($t) -replace "`r", '' -replace "`n{3,}", "`n`n"
        [System.IO.File]::WriteAllText((Join-Path $outDir ('ch{0:d2}.txt' -f $n)), $t)
        Write-Host ("ch{0:d2}.txt  {1} 字符" -f $n, $t.Length)
    }
} finally { $zip.Dispose() }
```

Run: `pwsh -File powershell/tools/extract-epub.ps1`
Expected: 打印 ch01..ch28 共 28 行字符数。

- [ ] **Step 2: 写 `materials/README.md`**

内容要点：取材书名/作者/版次；epub 文本层完好无 OCR；映射规则 N.xhtml=第 N+1 章；本目录仅写作查证用，正文自包含不引用。

- [ ] **Step 3: 写 `build.ps1`（完整代码如下，逐字采用）**

```powershell
# build.ps1 — PowerShell 教程双通道验证器（pwsh 7 下运行本脚本）
# 用法: pwsh -File build.ps1 [-Only 通配符] [-Engines pwsh,powershell]
[CmdletBinding()]
param(
    [string]$Only = '*',
    [string[]]$Engines = @('pwsh', 'powershell')
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$root = $PSScriptRoot
$examplesRoot = Join-Path $root 'examples'
$reportDir = Join-Path $root 'build\reports'
$logDir = Join-Path $root 'build\logs'
foreach ($d in $reportDir, $logDir) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# 0) BOM 自检：examples/ 与 tools/ 下 .ps1/.psd1 必须 UTF-8 BOM（5.1 硬要求），缺则自动补
foreach ($f in Get-ChildItem -Path $examplesRoot, (Join-Path $root 'tools') -Recurse -Include *.ps1, *.psd1 -File -ErrorAction SilentlyContinue) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { continue }
    [System.IO.File]::WriteAllBytes($f.FullName, [byte[]](0xEF, 0xBB, 0xBF) + $bytes)
    Write-Host "BOM fixed: $($f.FullName.Substring($root.Length + 1))"
}

# 1) 解析引擎
$engineMap = @{}
foreach ($name in $Engines) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) { throw "引擎未找到: $name" }
    $engineMap[$name] = $cmd.Source
}

# 2) 跑每个示例 × 每个引擎
$dirs = @(if (Test-Path $examplesRoot) { Get-ChildItem $examplesRoot -Directory | Where-Object Name -Like $Only | Sort-Object Name })
$results = [System.Collections.Generic.List[object]]::new()
foreach ($dir in $dirs) {
    $row = [ordered]@{ Example = $dir.Name }
    $reportByEngine = @{}
    foreach ($name in $Engines) {
        $logFile = Join-Path $logDir "$($dir.Name).$name.log"
        & $engineMap[$name] -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $dir.FullName 'run.ps1') *> $logFile
        $code = $LASTEXITCODE
        $reportFile = Join-Path $dir.FullName 'report.txt'
        $reportText = if (Test-Path $reportFile) { ([System.IO.File]::ReadAllText($reportFile) -replace "`r`n", "`n").Trim() } else { '' }
        $normalized = (@($reportText -split "`n") | Where-Object { $_ -notmatch '\[(ch7-only|ch51-only)\]?$' }) -join "`n"
        [System.IO.File]::WriteAllText((Join-Path $reportDir "$($dir.Name).$name.txt"), $normalized)
        $hasFail = @(@($reportText -split "`n") | Where-Object { $_ -like 'FAIL:*' }).Count -gt 0
        if ($code -ne 0 -or $hasFail) { $row[$name] = 'FAIL' }
        elseif ($reportText -eq '') { $row[$name] = 'FAIL(no-report)' }
        else { $row[$name] = 'PASS' }
        $reportByEngine[$name] = $normalized
    }
    # 3) 双通道对账（剥离通道专属行后逐字节一致）
    $row['Diff'] = if (@($reportByEngine.Values | Select-Object -Unique).Count -eq 1) { 'same' } else { 'DIFF' }
    $results.Add([pscustomobject]$row)
}

# 4) 汇总
$results | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
$bad = @($results | Where-Object { @($_.PSObject.Properties | Where-Object { $_.Value -in 'FAIL', 'FAIL(no-report)', 'DIFF' }).Count -gt 0 })
if ($bad.Count -gt 0) { Write-Host "结果: $($bad.Count) 个示例未通过" -ForegroundColor Red; exit 1 }
Write-Host "结果: $($results.Count) 个示例全绿 ($($Engines -join '+'))" -ForegroundColor Green
exit 0
```

- [ ] **Step 4: 写 `tools/smoke.ps1`（公共骨架 + 三断言）**

在公共骨架的"演示与断言"区填入：

```powershell
Check ((1..5 | Measure-Object).Count -eq 5) '管道计数'
Check ([int]'42' + 1 -eq 43) '类型转换'
Check (@{ a = 1; b = 2 }.Count -eq 2) '哈希表'
$dir = Join-Path $PSScriptRoot 'tmp-smoke'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Set-Content -Path (Join-Path $dir '清单.txt') -Value '中文内容' -Encoding UTF8
Check ((Get-ChildItem $dir).Count -eq 1) '临时目录与中文文件名'
Remove-Item $dir -Force -Recurse
Write-Host '日志通道：中文字符串可读性检查'
```

（smoke 的 report.txt 写到 `$PSScriptRoot`（tools/ 下），两次运行互相覆盖属预期；对账由下一批的 build.ps1 正式接管。）

- [ ] **Step 5: 双引擎跑 smoke 并对账**

```bash
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File powershell/tools/smoke.ps1
pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File powershell/tools/smoke.ps1
```

Expected: 两次退出码 0；`report.txt` 内容一致（4 行 OK）。（smoke.ps1 写 report.txt 到 `$PSScriptRoot`，即 tools/ 下，两次运行互相覆盖，检查最后一行即可；对账由下一批的 build.ps1 正式接管。）

- [ ] **Step 6: 提交**

```bash
git add powershell/build.ps1 powershell/tools powershell/materials powershell/.gitignore
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次零——骨架与双通道基建

build.ps1 双引擎对账验证器、epub 提取（28 章入 materials）、smoke 冒烟。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 1: 批次一——入门篇 docs 01–05 + examples

**Files:**
- Create: `powershell/docs/01-why-powershell.md` … `05-providers.md`
- Create: `powershell/examples/01_why_powershell/run.ps1` … `05_providers/run.ps1`

**Interfaces:**
- Consumes: build.ps1、报告协议、公共骨架。
- Produces: 章节文档写作范式（后续批次照此标准）。

每章先读对应 `materials/book/chNN.txt`（01←ch01, 02←ch02, 03←ch03, 04←ch04, 05←ch05），按"动机→机制→演示→坑→章末可选示例指路"成文。

- [ ] **Step 1: 写 docs/01-why-powershell.md（书 ch1）**

必讲：GUI 的三个死穴（不可自动化、一致性差、不可组合）vs Shell 的任务一致性；"Shell 用户→管理员→工具作者"三层成长路径（贯穿全教程主线）；PowerShell = 对象 Shell 而非文本 Shell（对比 bash 管道）；cmdlet 发音与 "Verb-Noun"；Windows PowerShell 与 PowerShell 7 的产品史（2006 v1 → 5.1 → 2016 开源跨平台 7.x，版本即 .NET 代际）。示例设计：`01_why_powershell` 演示"同一任务跑两遍结果一致"——`1..3 | ForEach-Object { New-Item -ItemType Directory "site$_" }` 于临时目录、统计计数、成对清理；`Check` 目录数与重跑一致性。坑位：中文系统控制台代码页 GBK、脚本无 BOM 之 5.1 ANSI 解析。

- [ ] **Step 2: 写 docs/02-meet-powershell.md（书 ch2）**

必讲：宿主=壳的实现（console host、VS Code、旧 ISE 已停更）；`$PSVersionTable` 逐字段（PSVersion/edition/PSEdition Desktop vs Core/OS/GitCommitId）；pwsh vs powershell 两个可执行文件与并存关系；64 位 vs 32 位（System32/SysWOW64 路径坑）；profile 四种作用域与路径差异（`$PROFILE` 单/双引号不展开陷阱）；`Exit`/CLS 快捷操作、F7 历史窗（console host）；PSReadLine 补全/历史搜索。示例 `02_meet_powershell`：断言 `$PSVersionTable` 必含 PSVersion/PSEdition/OS 字段、`$PSVersionTable.PSVersion.Major -ge 5`、`$Host.Name -eq 'ConsoleHost'`、`$PROFILE` 以 `profile.ps1` 结尾且 `Test-Path $PROFILE` 不抛错；版本具体数字不进 report。

- [ ] **Step 3: 写 docs/03-help-system.md（书 ch3）**

必讲：**帮助是离线的、可更新的、第一手文档**——"学会查帮助 = 学会 PowerShell"；Get-Help vs Help（分页）；`Get-Help Get-Service -Examples/-Detailed/-Full/-Parameter Name/-Online`；语法记号解读（`[-Name] <string[]>` 方括号=可选、尖括号=类型占位、位置参数）；Update-Help 需管理员+网络（正文讲清，示例不执行）；Save-Help 离线场景；About_ 主题（`Get-Help about_*`）。示例 `03_help_system`：断言 `Get-Help Get-Service` 非空、`(Get-Command Get-Service -Syntax)` 非空且含 `-Name`、`Get-Help Get-Service -Parameter Name` 非空、`Get-Help about_Variables` 非空；不断言本地化文案。

- [ ] **Step 4: 写 docs/04-running-commands.md（书 ch4）**

必讲：cmdlet=Verb-Noun 批准动词集（Get-Verb，Unused 动词警告的意义）；`Get-Command -Name/-Verb/-Noun/- CommandType`；三类参数（位置、命名、开关/布尔 `-Force:$false`）；别名机制与风险（`gal`、`%`/`?`，脚本里禁用别名规范）；`Show-Command` GUI 探索（Windows）；Tab 补全；`-WhatIf/-Confirm` 安全网预演。示例 `04_running_commands`：断言 `Get-Command -Verb Get` 计数>0、`(Get-Command Get-ChildItem).Parameters.ContainsKey('Path')`、`Get-Alias gal` 解析到 Get-Alias、位置绑定 `Get-ChildItem $env:TEMP` 非空、`-WhatIf` 输出含 WhatIf 字样（`Remove-Item tmp -WhatIf` 于临时文件）；不打印具体计数数值。

- [ ] **Step 5: 写 docs/05-providers.md（书 ch5）**

必讲：提供程序=可挂载的数据存储统一树；`Get-PSProvider` 内置家族（FileSystem/Registry/Environment/Variable/Function/Alias/Certificate）；PSDrive 与 `New-PSDrive/Remove-PSDrive`；`HKLM:/HKCU:` 直达；动态参数（如 FileSystem 的 `-File/-Directory` 就是提供程序给的）；`Get-ChildItem` 跨存储同构性=学习复用；注册表 vs regedit、Env: vs set、Variable: 调试价值。示例 `05_providers`：断言 `Get-PSProvider` 含 FileSystem/Registry/Environment/Variable 四名；HKCU 临时键 `New-Item -Path 'HKCU:\SOFTWARE\ps-tutorial-tmp'` 写值读值删键成对；`Env:` 设临时变量后 `$env:PSTUTORIAL` 读到再删；`New-PSDrive`（FileSystem 类型指临时目录）后在该盘符下建删文件成对。

- [ ] **Step 6: 全量构建验收**

Run: `pwsh -File powershell/build.ps1`
Expected: 5 个示例 PASS×2 通道、Diff=same。

- [ ] **Step 7: 提交**

```bash
git add powershell/docs powershell/examples
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次一——入门篇 01–05 章

心智模型、宿主与版本、帮助系统、Cmdlet 语法、提供程序；5 示例双通道全绿。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 2: 批次二——对象与管道篇 docs 06–12 + examples

**Files:**
- Create: `powershell/docs/06-pipeline-first.md` … `12-integration.md`
- Create: `powershell/examples/06_pipeline_first/run.ps1` … `12_integration/run.ps1`

（章↔书映射：06←ch6，07←ch7，08←ch8，09←ch9，10←ch10，11←ch11，12←ch12）

- [ ] **Step 1: docs/06-pipeline-first.md**（书 ch6）

必讲：管道让"一个命令一个职责"组合成任务流；文本 Shell 逐行 vs 对象 Shell 逐对象整包传递；`Get-Service | Sort-Object Status | Format-Table` 三段各自职责；管道的惰性与流式（内存友好）；`Measure-Object` 数、`Select-Object -First` 提前终止。示例：服务链路计数==原始计数；`1..1000 | Select-Object -First 3` 只产出 3；`Sort-Object` 后对象仍是对象（Get-Member 验证类型不变）。

- [ ] **Step 2: docs/07-modules-usage.md**（书 ch7 现代化）

必讲：模块=命令的发布单元；`Get-Module -ListAvailable`、自动加载（pwsh 7 无需显式 Import）；`$env:PSModulePath` 搜索顺序（双引擎路径差异）；PSGallery 与 `Find-Module/Install-Module/Save-Module`、`Install-Module -Scope CurrentUser`；PSSnapin 已死（历史名词）；模块清单/版本/依赖的生态视角。示例：断言 `Get-Module -ListAvailable` 计数>0、`$env:PSModulePath -split ';'` 行数≥2 且含 PowerShell 目录字样（不断言完整路径）、`Get-Command -Module Microsoft.PowerShell.Utility` 计数>0；PSGallery 网络查询不自动执行（正文演示命令+说明）。

- [ ] **Step 3: docs/08-objects.md**（书 ch8）

必讲：一切输出皆 .NET 对象；`Get-Member` 是第二重要命令；属性 vs 方法 vs ScriptProperty/NoteProperty 成员类型速览；`Select-Object -Property` 取子集仍是对象、`-ExpandProperty` 降维取值；`Sort-Object -Property` 多键；计算属性 `@{n='MB';e={[math]::Round($_.WS/1MB,0)}}`；`.NET` 方法直调（`.ToUpper()`、`[math]::Round`）；`Get-Member -Static` 与 `::` 静态成员；ConvertTo-Type 的常见坑（字符串数字比较）。示例：`'abc' | Get-Member` 含 ToUpper 方法；`(Get-Process -Id $PID).Name` 非空但具体名不进 report（断言 `-match '\S'`）；计算属性排序后首元素值域断言。

- [ ] **Step 4: docs/09-pipeline-deep.md（书 ch9，全书枢纽章）**

必讲：管道两问——"能否绑定？按值还是按属性名？"；`Get-Help -Full` 的 accept pipeline input 行读法；ByValue：整对象类型==参数类型（`'spooler' | Get-Service`）；ByPropertyName：对象属性名==参数名（`[pscustomobject]@{Name='winmgmt'} | Get-Service`）；绑定失败=参数为空=错误；"先 `Get-Member` 看属性名，再对参数名"的三步法；`Select-Object` 改名桥接（`Select-Object @{n='Name';e={$_.ServiceName}}`）打通绑定；"括号子表达式先行执行"语法。示例：字符串→Get-Service ByValue 状态非空；pscustomobject ByPropertyName 同理；改名桥接案例；绑定不匹配时 `-ErrorAction Stop` 进 catch 的演示。

- [ ] **Step 5: docs/10-formatting.md**（书 ch10）

必讲：Format-* 是"显示指令"不是数据变换——格式化后对象变格式行，离管道终点一步之遥；**右到左解析**：`Format-Table | Sort-Object` 悄悄失效的机制（`Get-Service | Sort Status | FT` 对，`FT | Sort` 错）；Format-Table/List/Wide/Custom 四件套取舍；`Format-Table -AutoSize/-Wrap`；`Out-String -Width` 截断坑；`Out-File/Out-GridView/Set-Content` 终点命令家族；默认 4 列与 format.ps1xml 机制一瞥（点到即止）。示例：格式化后 `Get-Member` 类型名含 FormatEntries/Formatting（断言 `$_.GetType().Name -match 'Format'`）；`Format-List` 输出行数>Table；Out-String 宽度截断演示（固定输入断言截断发生）。

- [ ] **Step 6: docs/11-filtering.md**（书 ch11）

必讲：比较运算符全家（-eq/-ne/-gt/-lt/-ge/-le/-like/-notlike/-match/-notmatch/-in/-notin/-contains/-notcontains/-replace）与**大小写变体前缀 c**（-ceq）；布尔与逻辑 -and/-or/-not/-xor；`Where-Object` 三种形态（简化属性式、脚本块、老式 `$_.`）；通配符 vs 正则分界；**左过滤原则**：能 `-Filter`/参数过滤就不要 `Where-Object`（服务端 vs 客户端量级差异）；`-Filter` 方言是 WQL/LDAP 不是 PowerShell（引号陷阱）。示例：`Get-CimInstance Win32_Process -Filter "Name='explorer.exe'"` 计数与 `| Where-Object` 过滤计数一致（断言相等，不打印值）；`-in/-contains` 方向性；-match 后 `$matches[0]` 存在。

- [ ] **Step 7: docs/12-integration.md（书 ch12，学以致用）**

必讲：把 06–11 串成一个真实任务——磁盘库存清单：取数据（Get-CimInstance）→过滤（DriveType=3）→加工（空闲百分比计算属性）→排序→呈现（表格/CSV/HTML/屏幕）；`Export-Csv -NoTypeInformation`（5.1 必加、pwsh7 默认）与 `Import-Csv` 回读往返；`ConvertTo-Html -Property`；每一步为什么这样选（复盘全书决策树）；"先看类型再选命令"工作法总结。示例：本地磁盘行数>0；CSV 往返行数守恒；HTML 含 `<table>`；百分比计算属性值域 [0,100]（机器无关的结构断言）。

- [ ] **Step 8: 构建验收 + 提交**

Run: `pwsh -File powershell/build.ps1` → 12/12 全绿后：

```bash
git add powershell/docs powershell/examples
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次二——对象与管道篇 06–12 章

管道初步、模块生态、对象、参数绑定、格式化、过滤、库存实战；7 示例双通道全绿。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 3: 批次三——远程与批量篇 docs 13–19 + examples

**Files:**
- Create: `powershell/docs/13-remoting.md` … `19-advanced-remoting.md`
- Create: `powershell/examples/13_remoting/run.ps1` … `19_advanced_remoting/run.ps1`

（章↔书映射：13←ch13，14←ch14，15←ch15，16←ch16，17←ch17，18←ch20，19←ch23）

**通道注意：** 本章群大量内容以探针门控——统一模式：

```powershell
$wsmanOk = $false
try { $null = Test-WSMan -ErrorAction Stop; $wsmanOk = $true } catch { }
if ($wsmanOk) {
    # 真实演示断言……
} else {
    Skip 'WinRM loopback 不可用，远程演示跳过'
}
```

- [ ] **Step 1: docs/13-remoting.md**（书 ch13）

必讲：为什么要有 Remoting（-ComputerName 参数是少数派，WinRM 是通用通道）；WS-MAN/WinRM 协议栈（HTTP(S) 5985/5986）；**一对一 Enter-PSSession**（交互式，类似 SSH）与 **一对多 Invoke-Command**（扇出，`-ComputerName a,b,c`、`-ScriptBlock`、`-ThrottleLimit`）；`Enable-PSRemoting` 做了什么（正文讲清：起服务+防火墙规则+端点注册，本教程不执行）；返回对象自动带 `PSComputerName`/`RunspaceId` 属性；第二次跳变（second hop）问题一瞥；pwsh 7 下 SSH 远程选项预告（19 章展开）。示例：Test-WSMan 探针不通全 SKIP；通则断言 `Invoke-Command localhost {1+1}` 结果 2、双目标计数 2、结果含 PSComputerName 属性。

- [ ] **Step 2: docs/14-cim.md**（书 ch14 现代化）

必讲：WMI 是什么（存储管理数据的仓库+提供者模型）；**CIM cmdlet 取代 WMI cmdlet 的历史**（Get-WmiObject 5.1 有、pwsh 7 移除——差异标注样板）；`Get-CimInstance -ClassName Win32_OperatingSystem`；本地直连 COM vs 远程 WSMan 的协议选择（**无 -ComputerName 走本地 COM，不需要 WinRM**——本机演示全可跑的原因）；WQL `-Filter`（属性名=值、AND、LIKE）；`-Query` vs `-Filter`；`Get-CimClass` 看类定义（属性/方法/限定符）；CimSession 复用连接（对 18 章 PSSession 的镜像）；WMI 方法调用 `Invoke-CimMethod`（对比老 `_.Delete()`）。示例：本地 Win32_OperatingSystem 属性 Caption/Caption 非空、LastBootUpTime 是 DateTime 类型（CIM 的 DMTF→DateTime 转换是对比 WMI 的改进点，断言类型）；WQL DriveType=3 行数与 Where-Object 相等；`Get-CimClass Win32_Process` 方法表含 GetOwner；`Get-WmiObject` 仅 5.1 `[ch51-only]` 一行演示+pwsh7 通道 SKIP。

- [ ] **Step 3: docs/15-jobs.md**（书 ch15 + ThreadJob）

必讲：为什么要后台（长任务不阻塞控制台）；`Start-Job -ScriptBlock` 返回 Job 对象、`Get-Job` 状态机（NotStarted/Running/Completed/Failed/Stopped/Blocked）；`Receive-Job -Keep`（收完还在 vs 拿走就没——经典坑）；`Wait-Job/Stop-Job/Remove-Job` 生命周期；`ChildJobs`；`$using:` 作用域桥（本地变量进作业）；作业类型：BackgroundJob（新进程，慢~1s 启动）vs **ThreadJob（pwsh7 内置模块，线程级，快）**`Start-ThreadJob`；pwsh 7 还有 `ForEach-Object -Parallel`（16 章展开）。示例：Start-Job 算术 Receive 结果 2、状态 Completed、`-Keep` 二次仍可收、`$using:` 传值成功、Remove-Job 后 Get-Job 查无；ThreadJob `[ch7-only]`（5.1 无模块时 SKIP 行）。

- [ ] **Step 4: docs/16-multiple-objects.md**（书 ch16 + -Parallel）

必讲：书的三条路——①批处理 cmdlet（`Remove-Item -Path $files` 一次吃数组、`Get-Service -Name a,b`）；②对象方法/Invoke-CimMethod 批量（对每个对象做事）；③枚举：`ForEach-Object`（管道式）vs `foreach` 语句（先收集后迭代）的语义与适用；"能批量绝不 foreach"的性能阶梯（参数数组>Where/ForEach 管道>foreach>方法逐个）；变更安全：`-WhatIf`/`-Confirm` 批量前预演；pwsh 7 `ForEach-Object -Parallel -ThrottleLimit`（runspace 池、`$using:`、**输出顺序不保序**——排序后再断言）。示例：临时目录造 5 文件→`Remove-Item -Path (数组)` 批删→查无；foreach 与 ForEach-Object 对同一数组计数一致；`-Parallel` `[ch7-only]` 每路输出固定值→`Sort-Object` 后顺序确定→与预期集合相等。

- [ ] **Step 5: docs/17-security.md**（书 ch17）

必讲：PowerShell 安全观三原则（不提权、不绕权、防误触不防故意）；**执行策略不是安全边界**（它是防误跑开关，官方文档原话级澄清）；六作用域优先级（MachinePolicy>UserPolicy>Process>CurrentUser>LocalMachine>默认 Restricted）；`Get-ExecutionPolicy -List` 表格读法；`Set-ExecutionPolicy -Scope Process Bypass`（本进程、安全、自清理）；AllSigned 与代码签名概念（Get-AuthenticodeSignature 一瞥，30 章呼应）；脚本被"下载标记"Zone.Identifier 与 MOTW；AMSIScriptBlock Scanning 一瞥；组策略管控；Linux/macOS 无执行策略（Unrestricted 默认）。示例：`Get-ExecutionPolicy -List` 含全部作用域行（断言行名集合而非值）；Process 作用域设 Bypass 后读回==Bypass（子进程自演，不污染父）；`.ps1` 下载标记模拟（Alternate Data Stream `Zone.Identifier` 写读删成对于临时文件）`[ch51-only]`?（pwsh7 也可用 ADS，两通道都跑）。

- [ ] **Step 6: docs/18-sessions.md**（书 ch20）

必讲：13 章 Invoke-Command 每次新建连接的浪费；**PSSession=持久连接**：`New-PSSession` 创建、`Get-PSSession` 清点、`Invoke-Command -Session` 复用；**状态持久性演示**：同一 Session 两次 Invoke `$x=1` 后 `$x` 仍在（对比无 Session 的无状态）；`Enter-PSSession -Session`；断开重连 `Disconnect-PSSession/Connect-PSSession`（后台任务化）；`Remove-PSSession` 资源纪律（不用就删）；"computername 参数族 vs session 族"心智模型。示例：WinRM 探针门控；通则断言：Session 中 `$x=1` 后第二次 `$x` 读回 1；无 Session 两次 Invoke 变量消失（对比组）；Remove 后 Get-PSSession 查无（本进程域）。

- [ ] **Step 7: docs/19-advanced-remoting.md**（书 ch23 + SSH）

必讲：端点/会话配置是什么（`Get-PSSessionConfiguration`，Microsoft.PowerShell 默认端点、32/64 位双端点）；自定义端点与 RunAs、启动脚本、受限端点（概念+落地流程正文讲清，**不执行注册**）；非域环境：`TrustedHosts` 机制与 `Set-Item WSMan:\localhost\Client\TrustedHosts`（正文演示，示例不执行）；`Enter-PSSession -Credential (Get-Credential)`；多机凭据与 `PSSessionOption`（超时/加密）；**pwsh 7 SSH Remoting**：`New-PSSession -HostName -UserName`（免 WinRM、跨平台、密钥认证），WinRM 与 SSH 双通道选择表；JEA 一瞥（点到即止）。示例：`Get-Command ssh` 探针（无则 SKIP SSH 段）；`Get-PSSessionConfiguration` 在 WinRM 不通时 SKIP；WinRM 通则断言端点清单含默认端点名；TrustedHosts 读路径在 WinRM 关闭时的行为断言（SKIP 带理由）。

- [ ] **Step 8: 构建验收 + 提交**

Run: `pwsh -File powershell/build.ps1` → 19 个示例全绿（含带理由 SKIP）后：

```bash
git add powershell/docs powershell/examples
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次三——远程与批量篇 13–19 章

远程处理、CIM、后台作业、多对象、安全执行策略、会话、高级远程+SSH；7 示例双通道全绿（远程门控）。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 4: 批次四——语言核心篇 docs 20–23 + examples

**Files:**
- Create: `powershell/docs/20-variables.md` … `23-parameterized.md`
- Create: `powershell/examples/20_variables/run.ps1` … `23_parameterized/run.ps1`

（章↔书映射：20←ch18，21←ch19，22←ch21，23←ch22）

- [ ] **Step 1: docs/20-variables.md**（书 ch18）

必讲：`$` 命名与 `${}` 复杂名；单引号字面 vs 双引号展开（`$name` 与 `` ` `` 转义、`$(...)` 子表达式、`@(...)` 数组子表达式）；变量本质可装任何对象与类型推断/强转 `[int]$n`；数组：`@(1,2,3)`、`+` 拼接、索引/负索引/切片、`$arr.Count`、单元素陷阱（`@(,$x)` 包裹）；范围 `1..10` 与字符范围；哈希表 `@{}`：键访问两种语法 `$h.k` vs `$h['k']`（键含特殊字符/变量键时只有后者）、有序 `[ordered]@{}`、遍历；`$null` 判断与陷阱（`$null -eq $x` 顺序）；引号嵌套与 here-string `@"..."@`（收尾 `@` 顶格规则）；`Set-StrictMode` 对未定义变量的保护。示例：引号展开断言、切片断言、单元素数组陷阱断言（Count==1 且类型数组）、哈希表两种键访问、ordered 键序断言、here-string 多行含变量展开。

- [ ] **Step 2: docs/21-io-streams.md**（书 ch19）

必讲：**六条流**模型（1 输出/2 错误/3 警告/4 详细/5 调试/6 信息）与重定向语法 `2>&1`、`3>&1`、`*>`；`Write-Output`（进管道）vs `Write-Host`（不进管道、信息流 6，5.1+ 行为）vs `Write-Verbose/Warning/Debug`；`-Verbose/-Debug` 开关如何点亮流；`Write-Debug` 的确认暂停与 `$DebugPreference`；偏好变量家族（`$VerbosePreference` 等）；`Read-Host`/`-Prompt` 与密码 `-AsSecureString`（交互式——本教程示例不跑交互，正文讲清）；`Out-Host/-GridView` 终端家族；`Tee-Object` 双写。示例：`3>&1 { Write-Warning 'w' }` 合并后能捕获警告文本；Write-Host 进信息流（`6>&1` 捕获）`[ch7-only]`?（5.1 也支持 6>&1——两通道都跑，断言文案非空）；`Write-Verbose` 默认沉默、`-Verbose:$true` 后可见；Tee 写文件且管道有值。

- [ ] **Step 3: docs/22-first-script.md**（书 ch21）

必讲：命令行→脚本文件=复制粘贴的历史（脚本是"命令的存档"）；.ps1 的运行路径规则（`.\script.ps1` 必须带 `./`，防劫持设计）；执行策略门槛（呼应 17 章）；`param()` 开门块与调用传参（位置/命名/splatting `@params`）；`$args` 兜底；`#Requires -Version`；脚本作用域：脚本内变量默认脚本级、跑完即弃、`&` 调用 vs `.` 点源于当前作用域（变量可见性差异——重要坑）；退出码 `exit N` 与 `$LASTEXITCODE`；脚本 = 函数的前身（为 24 章铺垫）。示例：写辅助脚本 `lib.ps1`（param 带 mandatory 默认值）由 run.ps1 调用三种方式：`&` 后变量不可见、`.` 点源后可见、exit 码传递；断言三者行为差异。

- [ ] **Step 4: docs/23-parameterized.md**（书 ch22）

必讲：从"能跑"到"可交给别人"：`[CmdletBinding()]` 让脚本变高级函数行为（-Verbose/-Debug/-ErrorAction 免费获得）；`[Parameter(Mandatory)]/[Parameter(Position=0)]`；类型约束 `[string[]]$Name`；验证属性全家：`[ValidateSet]/[ValidateRange]/[ValidatePattern]/[ValidateNotNullOrEmpty]/[ValidateScript]`；默认值与 `[AllowNull()]`；**注释型帮助**：`.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE` 三段头语法（`#` 或 `<# #>` 块）、`Get-Help ./script.ps1` 离线可用；`$PSBoundParameters`；`[OutputType()]`；`exit`/`return`/`throw` 语义对比。示例：被测脚本 `tools-demo.ps1`（CmdletBinding+ValidateSet+注释帮助）；断言：`Get-Help` 能取到 SYNOPSIS 文本、ValidateSet 外值触发异常进 catch、-Verbose 点亮详细输出、`$PSBoundParameters.ContainsKey` 断言、Mandatory 缺参在 NonInteractive 下抛错可捕获。

- [ ] **Step 5: 构建验收 + 提交**

Run: `pwsh -File powershell/build.ps1` → 23 个示例全绿后：

```bash
git add powershell/docs powershell/examples
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次四——语言核心篇 20–23 章

变量与数据结构、输入输出六流、从命令到脚本、参数化脚本；4 示例双通道全绿。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 5: 批次五——工具制作篇 docs 24–30 + examples

**Files:**
- Create: `powershell/docs/24-functions.md` … `30-others-scripts.md`
- Create: `powershell/examples/24_functions/run.ps1` … `30_others_scripts/run.ps1`

（章↔书映射：28←ch24，29←ch25，30←ch26；24/25/26/27 为扩充章，取材书 ch27 的指路清单展开）

- [ ] **Step 1: docs/24-functions.md**（扩充；书 ch21 函数+ch27 指路）

必讲：函数=带名字的脚本块（`function Get-Square { param($n) $n*$n }`）；命名遵循 Verb-Noun（`Get-Verb` 批准集，非批准动词会有警告）；参数三要素（默认值/类型/开关参数 `[switch]`）；返回值真相：**函数输出一切进入管道的东西**，`return` 只是"输出+退出"（`Write-Host` 污染案例）；管道输入函数的初级形态；作用域链：local→script→global 查找方向、`$script:`/`$global:`/`$local:` 修饰符、函数内赋值**遮蔽**不穿透（经典坑：函数里改 `$x` 外面不变）、`$using:` 回顾；函数库组织：点源 `. .\lib.ps1` vs 模块（27 章正解）；profile 放常用函数。示例：定义函数断言输出；遮蔽实验（函数内改值外不变、`$script:` 修饰后变）；switch 参数断言；"return 之前 Write-Output 也算输出"的双输出计数断言。

- [ ] **Step 2: docs/25-advanced-functions.md**（扩充；高级函数全解）

必讲：`[CmdletBinding()]` 进阶：`SupportsShouldProcess`（免费获得 -WhatIf/-Confirm）、`DefaultParameterSetName`、`ConfirmImpact`；**管道三段体**：`begin{一次}/process{每对象}/end{收尾}` 执行模型（逐对象流式、与先收集后处理的对比）；`[Parameter(ValueFromPipeline)]/[Parameter(ValueFromPipelineByPropertyName)]` 让函数像 cmdlet 一样吃管道；`$PSItem`/`$_`；`$PSCmdlet.ShouldProcess/ShouldContinue` 的交互与 -WhatIf 联动；`[OutputType]` 与 Get-Help/补全收益；高级函数=写 cmdlet 的 PowerShell 原生方式（对比 C# 编译 cmdlet 一瞥）；设计准则："要么全管道流式，要么别假装"。示例：写 `Get-TopN`（ValueFromPipeline + begin/process/end 计数）喂 5 个对象断言 process 执行 5 次；ShouldProcess 函数 `-WhatIf` 时输出含 WhatIf 且未变更、无 -WhatIf 时真变更（临时文件自演自净）；ByPropertyName 桥接断言。

- [ ] **Step 3: docs/26-error-handling.md**（扩充；错误处理全解）

必讲：错误双形态：**非终止错误**（默认一路继续，进 2 号流）vs **终止错误**（异常，炸穿）；try/catch **只抓终止错误**；把非终止升级：`-ErrorAction Stop`（cmdlet 参数）与 `$ErrorActionPreference`（作用域）；`finally` 必执行语义；`throw` 抛的是异常（可抛字符串/异常对象）；`$Error[0]` 错误记录解剖（Exception/CategoryInfo/FullyQualifiedErrorId/InvocationInfo——**InvocationInfo 是定位脚本错误的金矿**）；`-ErrorVariable ev` 旁路收集（注意 `ev` 不带 `$`、追加 `+ev`）；`Write-Error`（产生非终止错误）；`exit` vs `throw` vs `return` 在脚本/函数/工具里的选择；错误记录 vs 异常对象（`$_.Exception`）；`trap` 语句（遗留，认得即可）；错误视图 `$ErrorView`/`$FormatEnumerationLimit` 一瞥。示例：非终止错误默认继续（后续语句仍执行断言）；-EA Stop 进 catch 断言；finally 计数断言；-ErrorVariable 收到且主流程继续；`$_.Exception.Message` 非空、FullyQualifiedErrorId 断言；throw 字符串 catch 后类型断言。

- [ ] **Step 4: docs/27-modules-dev.md**（扩充；模块开发）

必讲：从"函数库脚本"到模块的动机（自动加载、封装、版本、发布）；**脚本模块** `.psm1`；**模块清单** `New-ModuleManifest` 与 `.psd1` 字段解剖（ModuleVersion/GUID/RootModule/FunctionsToExport/RequiredModules/PSData）；`Export-ModuleMember -Function` 显式导出（不导=私有）；`Import-Module 路径`（开发期直载）vs 放入 `$env:PSModulePath`（自动加载）；`Get-Module/Remove-Module`（改了代码必须先 Remove 再 Import——开发循环经典坑）；`FunctionsToExport='*'` 反模式（清单明确列举利于补全与性能）；`RequiredModules` 依赖；PSGallery 发布流程（`Publish-Module -NuGetApiKey`，正文讲流程，示例不执行）；模块 vs 管理单元 vs 清单模块三形态。示例：临时目录造 `PsTut.psm1`（两个函数只导一个）+ `New-ModuleManifest` 生成清单；Import 后断言导出函数可调、未导出函数 Get-Command 查无；改 .psm1 后 Remove+再 Import 生效断言；`Get-Module PsTut` 的 Version 与清单一致；清理临时目录。

- [ ] **Step 5: docs/28-regex.md**（书 ch24）

必讲：正则在 PowerShell 的两个层（运算符层 `-match/-replace/-split` 与 .NET `[regex]` 类）；`-match` 布尔+`$matches` 自动变量（编号组/命名组 `(?<name>)`）；`-replace 'a(b+)c','$1'` 替换引用（单引号防展开）；贪婪 vs 懒惰 `.*?`；锚点 `^$`、字符类 `\d\w\s`、量词、交替；大小写 `-cmatch`；`Select-String -Path -Pattern`（文件/流级检索，`-AllMatches`、返回 MatchInfo 的 Line/LineNumber/Path 属性）；正则解析文本文件实战（日志行→对象：`[regex]::Groups` 捕获转 pscustomobject）；常见坑：`-match` 吃的是字符串数组时逐元素过滤、多行模式 `(?m)`、`.` 不匹配换行。示例：固定样本文本（内嵌字符串数组）断言匹配数、`$matches['year']` 值、-replace 结果、`Select-String -AllMatches` 每行多命中计数、日志解析对象行数与字段值断言（全确定性）。

- [ ] **Step 6: docs/29-tips.md**（书 ch25）

必讲：字符串兵器谱：`.Trim/.Split/.Replace/.ToLower/.Contains/.StartsWith`（.NET 直调）与 `-join/-split/-replace/-f` 操作符层的分工；**格式化操作符 `-f`**（`{0:d2}`/`{1:N2}`/`{2:P1}` 索引与格式串）；`[string]::Join/Format` 静态对应；子表达式 `$()` 在字符串里的求值（"$(Get-Date)" 与对象插值调用 ToString 的坑）；数组技巧：切片、`-contains`/`-in`、`Compare-Object` 差集、`Select-Object -Unique/-Index`；`Join-String`（pwsh7 新）`[ch7-only]`；调用操作符 `& '路径.exe' 参数` 与 `. ` 点源分野；`::` 静态成员；`[System.Math]` 常用；`Measure-Command` 性能测量（值不进对账区）；`Tee-Object`；`New-Object` vs `::new()`（后者类型推断好）；`Select-String` 快速 grep；默认参数 `$PSDefaultParameterValues` 一瞥。示例：格式化 `-f` 断言（d2/N2/P1 固定输入输出）、字符串方法链断言、数组切片/差集断言、`&` 调用 pwsh 子进程 `-Command '1+1'` 返回 2（自演自净）、`[math]::Round` 断言、Join-String `[ch7-only]`。

- [ ] **Step 7: docs/30-others-scripts.md**（书 ch26 案例改编）

必讲：**读陌生脚本的方法论**（先整体后局部五步：1 帮助/注释头→2 param 块看输入→3 主流程骨架（忽略分支细节）→4 集中找 Get-/Set-/New-/Invoke- 动词与管道→5 再回头啃分支）；原书两个案例的核心问题蒸馏自包含重讲（IIS 依赖改为通用化改编版）：**案例A**（参数过度设计+硬编码路径+无错误处理的三病脚本）与**案例B**（未知命令依赖+作用域混乱）；遇到没学过的语法怎么办（Get-Help about_*、Get-Command、拆开逐段跑）；`-WhatIf` 干跑审读；下载脚本的安全审计清单（来源、签名 `Get-AuthenticodeSignature`、ADS 标记、先读后跑、沙箱）；PoshCode/微软 Gallery 生态；把别人的脚本改造成自己工具的路径（加 param→加 CmdletBinding→拆函数→22/25 章回炉）。示例：提供改编后的"三病脚本" `sample-buggy.ps1`（内嵌中文注释讲病史）；run.ps1 以五步法审读并断言：能列出其 param 名集合、`-WhatIf` 干跑不产生变更、修复版 `sample-fixed.ps1` 输出与病版意图一致、`Get-AuthenticodeSignature` 对未签名脚本 Status 值断言（NotSigned——确定性）。

- [ ] **Step 8: 构建验收 + 提交**

Run: `pwsh -File powershell/build.ps1` → 30 个示例全绿后：

```bash
git add powershell/docs powershell/examples
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次五——工具制作篇 24–30 章

函数与作用域、高级函数、错误处理、模块开发、正则、技巧、他人脚本剖析；7 示例双通道全绿。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 6: 批次六——进阶收官篇 docs 31–34 + CHEATSheet

**Files:**
- Create: `powershell/docs/31-classes.md` … `34-cheatsheet.md`
- Create: `powershell/examples/31_classes/run.ps1` … `34_cheatsheet/run.ps1`
- Create: `powershell/CHEATSheet.md`

（31/32/33 为扩充章；33 取材书 ch27 Toolmaking；34 取材书 ch28）

- [ ] **Step 1: docs/31-classes.md**（扩充；类与结构化数据）

必讲：什么时候需要 class（状态+行为的数据结构，超出哈希表表达力时）；`class` 语法：属性带类型、构造函数（可重载）、方法、`static` 成员、`[Foo]::new()`；继承 `: base` 与方法重载；class vs pscustomobject vs hashtable 选型表；**enum**（`enum MediaType { Unknown; CD; DVD }`）与 `[ValidateSet]` 对比（enum 是真类型、可 `[MediaType]::CD` 取值与位标志）；类在 DSC/高级函数参数中的角色一瞥；`using module`；JSON 深水：`ConvertTo-Json -Depth`（默认 2 截断静默坑）、`-Compress`、`ConvertFrom-Json` 返回 PSCustomObject、嵌套数组单元素坑（5.1 无 `-AsHashtable`，pwsh7 有——差异标注样板）、往返保真度断言法。示例：定义类+构造+方法断言、继承断言、enum 验证参数与 ToString 断言、`ConvertTo-Json -Depth 2` 截断演示（深对象丢层断言）、往返 `ConvertFrom-Json | ConvertTo-Json` 一致断言、`-AsHashtable` `[ch7-only]`。

- [ ] **Step 2: docs/32-testing.md**（扩充；Pester 与 ScriptAnalyzer）

必讲：测试是工具质量的底线；**Pester v5** 语法：`Describe/Context/It/Should -Be/-BeOfType/-Throw/-Contain`、`BeforeAll/BeforeEach`（v5 必须先 `BeforeAll { . $PSCommandPath }` 导入被测函数——v3 无此要求，差异讲清）、`Invoke-Pester -PassThru` 取结果对象；Windows 内置 Pester 3.4 老版本陷阱（Should 语法 `Should Be` vs `Should -Be`）；安装/升级 `Install-Module Pester -Force -SkipPublisherCheck`；断言函数的三类样例（纯函数/管道函数/异常路径）；**ScriptAnalyzer**：`Invoke-ScriptAnalyzer -Path`、规则输出（RuleName/Severity/Line）、常见规则（PSAvoidUsingPlainTextForPassword/PSUseShouldProcessForStateChangingFunctions/PSAvoidUsingWriteHost）、配置 .PSScriptAnalyzerSettings.psd1、CI 集成一瞥。示例：`Get-Module -ListAvailable Pester` 探针（版本≥5 才跑，否则 SKIP 带理由；两通道独立探测）；被测函数文件 `math.ps1`+`math.Tests.ps1`（含 -Throw 用例）跑 `Invoke-Pester -PassThru` 断言 FailedCount==0；ScriptAnalyzer 探针同法，对"干净代码"断言 0 警告、对"脏代码"（Write-Host）断言命中 PSAvoidUsingWriteHost。

- [ ] **Step 3: docs/33-toolmaking.md**（扩充+书 ch27；收官综合项目）

必讲：Toolmaking 心法（书 ch27 蒸馏）：**工具=函数+帮助+参数验证+错误处理+管道+模块打包**，给别人的不是脚本而是"命令"；综合项目 **Get-MachineInventory**（前 33 章总装）：需求分解→CIM 取数（14）→计算属性（08）→过滤（11）→高级函数+ShouldProcess（25）→try/catch+ErrorAction（26）→注释帮助+ValidateSet（23）→模块打包+FunctionsToExport（27）→CSV/JSON 双输出（12/31）→Pester 冒烟（32）→ScriptAnalyzer 干净通过；开发节奏（先一个命令跑通→固化函数→固化模块→补测试）；工具的分发（复制目录/PSGallery/组策略）；书 ch27 的后续学习地图自包含重述（进一步主题：DSC、JEA、工作流已弃用声明、PSFramework 等社区生态）。示例：`InventoryModule/`（psm1+psd1+Tests）在临时目录构建；run.ps1：Import→`Get-MachineInventory -Format Csv` 输出文件存在且行数>0、`-WhatIf` 不产文件、参数验证触发异常、Pester 探针通过则 FailedCount==0、全流程自演自净。

- [ ] **Step 4: docs/34-cheatsheet.md**（书 ch28 转化）

必讲（全表化、正文自包含）：标点符号总表（`` ` `` 转义/`~` 家目录/`()` 强制优先+方法实参/`$()` 子表达式/`@()` 数组/`@{}` 哈希表/`$(@{})` /`[]` 类型与索引/`.` 属性方法与点源/`&` 调用/`::` 静态/`|` 管道/`%` 与 `?` 别名/`-` 参数/`--%` 停止解析（Windows）/`;` 分隔/`{}` 脚本块）；运算符速查（比较/逻辑/替换/类型 `-is`/格式 `-f`/范围 `..`）；常用任务速查（查命令/查帮助/看成员/管道过滤/排序选择/CSV/JSON/HTML/远程/作业/错误处理）；**入门者十大高频坑**（自本教程各章坑位收束：`./` 前缀、双引号展开、单元素数组、`Format-*` 后不能再管道、`-Filter` 方言、`-eq` 大小写不敏感、`return` 真相、作用域遮蔽、无 BOM 乱码、执行策略误当安全边界）。示例 `34_cheatsheet`：每个标点/运算符一条确定性断言（如 `` `a`b `` 转义后含反引号、`@('a').Count -eq 1`、`'a' -is [string]`、`--%` 在 pwsh7 非门控跳过？——`--%` 仅 Windows 且行为引擎差异大，正文讲+示例 SKIP 双通道均不跑）。

- [ ] **Step 5: 写 powershell/CHEATSheet.md**

汇总全教程**实测坑位**（写作过程中各批滚动记录）：编码三件套（BOM/GBK 控制台/Out-File 编码差异）、报告协议、双引擎差异表（5.1 vs 7 的行为差异清单——每章标注过的差异集中成表）、工具坑（build.ps1 对账剥离规则）等。格式参照仓库其他教程 CHEATSheet（表格+现象/原因/对策三列）。

- [ ] **Step 6: 构建验收 + 提交**

Run: `pwsh -File powershell/build.ps1` → 34 个示例全绿后：

```bash
git add powershell/docs powershell/examples powershell/CHEATSheet.md
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次六——进阶收官篇 31–34 章

类与枚举与 JSON、Pester 与 ScriptAnalyzer、工具制作收官项目、备忘清单；CHEATSheet 定稿。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

---

### Task 7: 批次七——README 导航、根登记与终验

**Files:**
- Create: `powershell/README.md`
- Modify: `G:\code\guide\README.md`（"已整理并验证的教程"列表加 powershell 条目，按目录字母序插入）

- [ ] **Step 1: 写 powershell/README.md**

要素：教程定位（书为纲+34 章结构表：篇/章/主题/书章源）；双通道验证说明（`pwsh -File build.ps1`，34/34 全绿徽章式声明）；docs 分章导航列表（链接每章）；CHEATSheet 链接；materials 说明（原书取材、自包含声明）。

- [ ] **Step 2: 根 README.md 登记 powershell 条目**

条目格式对齐邻居条目（一句话定位 + 章数/示例数 + 双通道验证状态 + 详见 powershell/README.md 链接）。

- [ ] **Step 3: 全量终验（清洁环境）**

```bash
rm -rf powershell/build
pwsh -File powershell/build.ps1
```

Expected: `结果: 34 个示例全绿 (pwsh+powershell)`，退出码 0。再抽查 3 个 report（12/19/32）人工目检 SKIP 理由合理。

- [ ] **Step 4: 提交 + 记忆沉淀**

```bash
git add powershell/README.md README.md
cat > /tmp/msg.txt <<'EOF'
feat(powershell): 批次七——README 定稿与全量终验

34 章双通道全绿收官，根 README 登记。

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
git commit -F /tmp/msg.txt
```

写记忆文件 `powershell-tutorial-build.md`（项目级：结构/批次/实测坑位/CHEATSheet 指针），更新 `MEMORY.md` 索引。

---

## Self-Review 记录

1. **Spec 覆盖**：spec 的 34 章表 ↔ Task 1–6 全部章 slug 一致；双通道/BOM/门控/自演自净/CHEATSheet/根 README 均有对应任务；批次验收数与章数对齐（5/7/7/4/7/4+CHEATSheet）。
2. **占位符扫描**：无 TBD/TODO；每章有必讲要点+示例断言设计；build.ps1/骨架/smoke/探针模式均为完整代码。
3. **一致性**：报告协议（OK/SKIP/FAIL 前缀、`[ch7-only]/[ch51-only]` 后缀、report.txt、exit 码）在 Global Constraints、Task 0 build.ps1、骨架模板三处一致；slug 命名 docs 连字符/examples 下划线全书一致；书章映射每批开头显式给出。
