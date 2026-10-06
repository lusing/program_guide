# 34 备忘清单——标点、运算符与速查总表

> 本章对应原书第 28 章"PowerShell 备忘清单"（全书最后一章）：遇到问题时"先翻这里"的速查页。全部条目自包含，标注语法含义与本教程首次详解的章。

## 34.1 标点符号总表

| 符号 | 名称 | 含义 | 详解 |
|---|---|---|---|
| `` ` `` | 反引号 | **转义符**（`` `$ `` 字面美元、`` `n `` 换行、`` `t `` Tab、行尾=续行） | 20 |
| `~` | 波浪号 | 路径开头时=用户主目录（`$HOME`） | 05 |
| `()` | 圆括号 | ① 强制先执行 `(Get-Content f)`；② 方法实参 `.ToUpper()`；③ 表达式分组 | 03/08 |
| `$( )` | 子表达式 | 双引号内求值任意表达式（属性/命令都行） | 20/29 |
| `@( )` | 数组子表达式 | **保证数组**（单元素/空也保形）——计数的唯一可靠姿势 | 20 |
| `@{ }` | 哈希表字面量 | 键值对容器；`[ordered]@{}` 保序；`[pscustomobject]@{}` 造对象 | 20 |
| `@'…'@` / `@"…"@` | here-string | 多行文本（字面/展开）；**收尾标记顶格** | 20 |
| `[ ]` | 方括号 | ① 类型字面量 `[int]`；② 类型约束 `[int]$x`；③ 索引/切片 `$a[0]`、`$a[-1]`、`$a[1..3]` | 08/20 |
| `.` | 点 | ① 成员访问 `$x.Name`；② **点源** `. .\lib.ps1`（定义入当前作用域） | 08/22/29 |
| `&` | 调用操作符 | 把值当命令执行：`& $exe`、`& { 脚本块 }` | 04/29 |
| `::` | 双冒号 | 静态成员：`[math]::Round(…)`、`[Foo]::new()`、`[Foo]::静态属性` | 08 |
| `\|` | 管道 | 对象流：`A \| B`（B 的参数绑定按 ByValue→ByPropertyName） | 06/09 |
| `%` | 别名 | `ForEach-Object`（**脚本里禁用别名**） | 16 |
| `?` | 别名 | `Where-Object`（同上） | 11 |
| `-` | 短横线 | 参数前缀 `-Name`；负号；区间 `1..10` 无它 | 03 |
| `--%` | 停止解析 | 之后的原文交 cmd（仅 Windows；其后**变量不展开**） | 04 |
| `;` | 分号 | 语句分隔（同一行两条命令） | 04 |
| `{ }` | 脚本块 | 代码作为值：`{ … }`，`$_` 管道占位 | 11/24 |
| `,` | 逗号 | 数组构造符（引号外）`'a','b'`；参数分隔 | 03/20 |
| `+=` | 复合赋值 | 数组追加=全量复制（循环里慎用） | 20 |
| `>` / `>>` | 重定向 | `>`=Out-File 糖；`N>&1` 流合并；`*>` 全收 | 06/21 |
| `#` / `<# #>` | 注释 | 行注释 / 块注释（后者承载**注释帮助**，必须文件首行） | 23 |

## 34.2 运算符总表

| 族 | 运算符 | 速记 | 详解 |
|---|---|---|---|
| 比较 | `-eq -ne -gt -lt -ge -le` | **默认不区分大小写**；`c` 前缀变敏感 | 11 |
| 通配 | `-like -notlike` | `*` 与 `?` | 11 |
| 正则 | `-match -notmatch` | 命中填 `$matches`；`c` 前缀敏感 | 28 |
| 成员 | `-in -notin` / `-contains -notcontains` | 值在集 / 集含值（**左单右集看运算符**） | 11 |
| 类型 | `-is -isnot` / `-as` | 判型 / 温和转型（失败给 `$null`） | 11/20 |
| 逻辑 | `-and -or -not`(`!`) `-xor` | 子条件加括号 | 11 |
| 替换 | `-replace`（正则）/ `.Replace()`（字面） | 分组引用 `'$1'`（单引号！） | 28 |
| 切拼 | `-split` / `-join` | 正则切 / 拼接 | 28/29 |
| 格式 | `-f` | `'{0:N1}' -f 1.5` | 29 |
| 范围 | `..` | `1..10`、`'a'..'c'` | 20 |
| 位移 | `-band -bor -bxor -bnot -shl -shr` | 位运算（低频） | 11 |

## 34.3 任务速查：高频动作一行流

| 想做什么 | 命令骨架 | 详解 |
|---|---|---|
| 查命令 | `help *关键词*`；`Get-Command -Noun X` | 03 |
| 看类型/属性 | `命令 \| gm` | 08 |
| 过滤 | `命令 \| Where 属性 -eq 值`（能 `-Filter` 先参数） | 11 |
| 排序挑列 | `\| Sort 属性 \| Select 列1,列2` | 08 |
| 现算一列 | `Select @{n='名';e={ 表达式 }}` | 08 |
| 出表/存档 | `\| Format-Table -Auto`（屏幕）；`\| Export-Csv -NoTypeInformation`（数据） | 06/10 |
| 出 HTML | `\| ConvertTo-Html \| Out-File` | 06 |
| 比对两份快照 | `Export-Clixml` 基线 → `Compare-Object -Property 身份列` | 06 |
| 查系统信息 | `Get-CimInstance -ClassName Win32_*` | 14 |
| 多机扇出 | `Invoke-Command -ComputerName 清单 {}` | 13 |
| 后台跑 | `Start-Job {}` / `Invoke-Command -AsJob` | 15 |
| 读配置 | `'f.json' \| ConvertFrom-Json`（注意 -Depth） | 31 |
| 测一段耗时 | `Measure-Command { … }` | 06/29 |
| 临时放行策略 | `-ExecutionPolicy Bypass`（进程级） | 17 |
| 跑别人脚本前 | 读全文 → `-WhatIf` → 签名/来源检查 | 30 |

## 34.3.1 环境探针一行流

写跨环境脚本前先"体检环境"的探针家族（本教程验证器的同款思路，全部只读）：

```powershell
# 引擎与版本（02 章）
$PSVersionTable.PSVersion; $PSVersionTable.PSEdition
# 平台（7+ 有专用变量；5.1 用环境变量兜底）
if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'Windows' }
# 命令/参数能力探测（09/14 章差异的标准判别法）
(Get-Command Get-WmiObject -ErrorAction SilentlyContinue) -ne $null
(Get-Command Get-Service).Parameters.ContainsKey('ComputerName')
# 模块可用性（15/32 章）
Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
# 远程通道连通（13 章）
Test-WSMan -ErrorAction SilentlyContinue; Get-Command ssh -ErrorAction SilentlyContinue
# 管理员身份（17/19 章的操作前置检查）
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

探针的纪律：**先探后用、不通绕行（SKIP 带理由）、绝不顺手"修"环境**——本教程全部远程/模块示例都是这条纪律的活样本。

## 34.4 入门者十大高频坑（全教程收束）

每条都是各章"本章高频坑位"的冠军条目，值得贴在显示器上：

1. **`./` 前缀**：运行当前目录脚本必须 `.\s.ps1`（防劫持设计）——22 章；
2. **双引号展开**：单引号字面、双引号才展开 `$`；属性要 `$()`——20 章；
3. **单元素陷阱**：计数恒用 `@($x).Count`；管道可能给标量——20 章；
4. **Format 之后无世界**：`Format-*` 后再接 Sort/Where/Export 全部失效（右到左）——10 章；
5. **`-Filter` 是方言**：WQL 用 `=` 不认 `-eq`；外双引号内单引号——11/14 章；
6. **`-eq` 不分大小写**；且**数组在左变过滤**——11 章；
7. **`return` 的真相**：函数输出一切进管道的东西；不要的显式 `$null =`——24 章；
8. **作用域遮蔽**：函数里赋值不穿透外层（要穿透用 `$script:`）——24 章；
9. **无 BOM 之殇**：含中文的 .ps1 必须存 **UTF-8 带 BOM**，否则 5.1 按 ANSI 解析出鬼（本教程构建器实测踩过：中文串吞掉引号、报"意外的标记"）——17 章；
10. **执行策略不是安全边界**：它是防误触开关；自动化用进程级 `Bypass`——17 章。

## 34.5 双引擎速查（本教程差异总表）

| 差异点 | 5.1 | pwsh 7+ | 详解 |
|---|---|---|---|
| 身份 | `PSEdition=Desktop` | `Core` | 02 |
| `Get-WmiObject` | 有 | **移除**（用 CIM） | 14 |
| `Get-Service -ComputerName` | 有 | **移除**（用 Invoke-Command） | 09 |
| `-Parallel` / `&&` / 三元 `? :` | 无 | 有 | 16 |
| `New-PSSession -HostName`（SSH） | 无 | 有 | 19 |
| 后台作业初始目录 | 用户 Documents | 继承当前目录 | 15 |
| `ConvertFrom-Json -AsHashtable` | 无 | 有 | 31 |
| JSON 截断警告（-Depth） | 无（纯静默） | 有（警告流） | 31 |
| 默认文件编码 | ANSI/UTF-16 | UTF-8 | 17 |
| `Update-Help` 范围 | AllUsers（管理员） | CurrentUser | 03 |
| 模块目录 | `…\WindowsPowerShell\` | `…\PowerShell\` | 07 |
| Pester 内置 | 3.4（v3 语法） | 不内置（自装 v5+） | 32 |
| enum 前缀缩写绑定 | 接受 | 接受（相同） | 31 |

## 34.6 帮助主题速查：about_* 的索引

34.3 查"怎么做"，`about_*` 主题查"为什么/全部规则"——按主题归队的常用索引（`help about_X` 直达）：

| 主题 | 讲什么 |
|---|---|
| `about_Comparison_Operators` | 34.2 全表 + 位运算 |
| `about_Operators` | 一切运算符的总入口（含 `??`、三元等 7+ 新成员） |
| `about_Quoting_Rules` | 引号/转义/here-string 全规则 |
| `about_Arrays` / `about_Hash_Tables` / `about_Assignment_Operators` | 容器与赋值 |
| `about_Scopes` / `about_Automatic_Variables` | 作用域与 `$_`、`$args`、`$null` 们 |
| `about_Parameters` / `about_Functions_Advanced` / `about_Functions_CmdletBindingAttribute` | 参数与高级函数 |
| `about_Pipelines` / `about_Command_Precedence` | 管道与命令优先级 |
| `about_Redirection` / `about_Streams` | 六条流与重定向 |
| `about_Execution_Policies` / `about_Signing` | 执行策略与签名 |
| `about_Remoting*` 系列（FAQ/Troubleshooting/Requirements） | 远程全家桶 |
| `about_Modules` / `about_Module_Manifests` / `about_Requires` | 模块、打包与 `#Requires` 声明 |
| `about_Classes` / `about_Enum` / `about_Join` | 类型系统与拼接 |
| `about_Comment_Based_Help` / `about_Profiles` / `about_PowerShell_Config` | 帮助注释、profile 与配置 |

记不住名字时：`help about_*` 全列表 + 关键词通配（`help about_*array*`）。**"手册在 Shell 里"** 是 PowerShell 生态最被低估的福利——本教程 34 章教的所有内容，官方都有对应 about 主题做深水区。

> **主题名对不上就查 `Get-Help`**：官方主题名多为**单数**（`about_Join` 不是 `about_Joins`）、目录类用**复数**（`about_Module_Manifests`）。写错名字时 `Get-Help` 只会提示 "Searching Help for..." 而不报错，容易以为主题不存在。转录（transcript）本身**没有**独立 about 主题，规则在 `about_Redirection` 与 `Start-Transcript`/`Stop-Transcript` 的帮助里。

## 34.7 键盘与效率速查

每天敲几千行的手值得一张效率表（PSReadLine，02 章的浓缩版）：

| 按键 | 动作 |
|---|---|
| `Tab` / `Shift+Tab` | 补全 / 反向（命令、路径、参数、枚举值四场景） |
| `↑` `↓` / `Ctrl+R` | 历史 / 历史搜索 |
| `→`（有灰建议时） | 采纳预测 |
| `Alt+.` | 取上条命令的**最后一个参数** |
| `Ctrl+C` | 打断当前命令回提示符（不是复制！） |
| `Esc` | 清行 |
| `F7`（控制台宿主） | 历史弹窗 |
| `Ctrl+Space` | 补全菜单 |

三条敲命令的省字习惯（都不违反"脚本里写全名"的纪律）：**参数名缩到唯一**（`-comp`）；**开关参数配 Tab**（敲前缀再 Tab）；**机器清单进文本文件**再 `(Get-Content f.txt)` 喂参数（第 03/09 章的模式）——三招叠加，日常命令能省三分之一击键。

## 34.8 本章要点

- 六张速查表（标点 34.1／运算符 34.2／任务一行流 34.3／双引擎差异 34.5／about 主题 34.6／键盘效率 34.7）是"先翻这里"的第一站；每条标注详解章，顺藤摸瓜。
- 十大坑=全教程教训的浓缩版；**双引擎表**是迁移与排错的对照词典。
- 本教程 34 章至此收官：**使用者（1–19）→ 语言核心（20–23）→ 工具作者（24–33）→ 速查（34）**——需要更深时，33.6 的下一站地图指路。

**动手实验**：① 把 34.1 表里每个符号都在命令行敲一遍验证含义（约 15 分钟，值得）；② 用 34.3 的一行流拼一个"本机巡检三件套"（磁盘/服务/补丁各一行）；③ 给 34.4 的十条各想一个"症状复现"命令；④ 把 34.5 表与你的工作环境对照，标出会影响你的三行。

对应示例（可选）：`examples/34_cheatsheet/`——把速查表里**可确定性验证的那部分**做成了断言，实测 macOS / pwsh 7.6.6 上 **28 条全过**（Windows 侧另有一条 `[ch7-only]` 的 `PSEdition` 断言，属引擎差异行）：标点区 13 条（转义、数组/哈希字面量、here-string、成员与静态访问、切片与子表达式）、运算符区 7 条（`-eq`/`-ceq` 大小写、`-replace`、数组 `-match` 过滤、`-in`/`-contains` 方向、`-as`、`-f`、管道排序）、坑区 8 条症状复现（挑的是坑 2/3/7/8/11 等有确定可测行为的，不是十条全做）。34.1 表里 `;` `,` `#` 这类"没有独立可测行为"的符号，以及 34.6/34.7 两张偏查阅性质的表，**未做断言**——动手实验①的"每个符号敲一遍"正是补这部分。

---

本篇（六 进阶收官）其余各章：[31 类与 JSON](./31-classes.md) · [32 测试](./32-testing.md) · [33 工具制作收官](./33-toolmaking.md)

---

本篇（六 进阶收官）导航：[31 类与 JSON](./31-classes.md) · [32 测试](./32-testing.md) · [33 工具制作收官](./33-toolmaking.md) · [34 备忘清单](./34-cheatsheet.md)

全教程六篇 34 章至此完结；实测坑位汇总见仓库根 [CHEATSheet.md](../CHEATSheet.md)。
