# 29 提示、技巧与技术——效率工具箱

> 本章对应原书第 25 章"额外的提示、技巧以及技术"，是原书收官前送出的"杂物间宝藏"。内容按"自定义环境 → 字符串兵器 → 调用三兄弟 → 效率杂技"组织，每条都值得上手一次。

## 29.1 Profile 深潜：四个文件与加载顺序

第 02 章认识了 `$PROFILE`；这里把全貌补齐。宿主启动时按固定顺序找**四个** profile（找到几个跑几个，缺了就跳过）：

| 顺序 | 文件 | 作用域 |
|---|---|---|
| 1 | `$PSHome\profile.ps1` | 所有用户 × 所有宿主（机器级） |
| 2 | `$PSHome\Microsoft.PowerShell_profile.ps1` | 所有用户 × 控制台宿主 |
| 3 | `文档目录\PowerShell\profile.ps1` | 当前用户 × 所有宿主 |
| 4 | `文档目录\PowerShell\Microsoft.PowerShell_profile.ps1` | **当前用户 × 控制台宿主（`$PROFILE` 默认指它）** |

`$PROFILE` 是"最常用那个"的快捷方式，但**四个位置都合法**——想在控制台和 VS Code 里都生效就写进第 3 个（所有宿主通吃）。两个实测要点：profile 也是脚本，**受执行策略管**（Restricted 下静默不跑——"我 profile 里明明写了"的第一嫌疑）；双引擎各有各的 profile 目录（第 02 章），想两个引擎共享一份就互相 `. 引用` 同一个文件。

profile 里放什么：常用模块的 `Import-Module`（想要 AD: 盘这类"启动即就位"的收益）、`Set-Location` 到工作目录、自定义函数（第 24 章）、别名、PSReadLine 选项（第 02 章）。原书作者 Don 的三行 profile（载 AD 模块、载 SQL snapin、cd C:\）就是好模板——**只放"每天必用"的，启动速度也是成本**。

## 29.2 自定义提示符：Prompt 函数

你看到的 `PS C:\>` 不是死的——它是名为 **`Prompt` 的内置函数**的返回值。重定义它就改了提示符（profile 里定义即永久）：

```powershell
function Prompt {
    $loc = (Get-Location).Path
    $time = Get-Date -Format 'HH:mm'
    "[$time] $loc> "        # 返回值就是新提示符
}
# 效果：[14:32] G:\code\guide>
```

实用变体：管理员会话标红 `ADMIN:`前缀（`( [Security.Principal.WindowsPrincipal]… ).IsInRole(...)` 判断）；提示符里带 **git 分支**（读 `.git/HEAD`——一行函数让终端含金量翻倍）。默认 Prompt 函数会处理调试态 `[DBG]:` 与嵌套 `>>` 前缀，自定义时想保留就抄默认函数改（`(Get-Command Prompt).Definition` 看默认实现）。

## 29.3 字符串兵器谱：方法、运算符与 -f

三套工具按场景选型：

**.NET 方法**（点调用，精确控制）：

```powershell
$path = 'C:\Logs\App-2026.log'
$path.ToUpper(); $path.Split('-'); $path.TrimStart('C:\')
$path.Substring(2, 4); $path.Replace('-', '_'); $path.EndsWith('.log')
$path.Contains('App'); $path.IndexOf('-'); $path.PadLeft(20, '.')
```

**运算符族**（PowerShell 原生，左右皆可变量）：

```powershell
$a, $b, $c -join '-'                    # a-b-c（拼接）
'a,b,,c' -split ','                     # 切分
'2026-10-06' -replace '-', '/'          # 替换（正则！）
```

**格式化运算符 `-f`**（第 10 章 FormatString 的自由形态）：

```powershell
'{0} 于 {1:yyyy-MM-dd} 完成，成功率 {2:P1}' -f '巡检', (Get-Date), 0.987
# 巡检 于 2026-10-06 完成，成功率 98.7%
```

`{索引:格式串}` 与 .NET 格式化同源：`d2` 补零、`N0` 千分位、`P1` 百分比、`yyyy-MM-dd` 日期。三套的选型口诀：**单个字符串的精活用方法；两个值之间用运算符；模板化输出用 -f**。pwsh 7 新增 `Join-String`（管道直拼：`1..3 | Join-String -Separator ','`）可作为第四件小工具。

## 29.4 子表达式：字符串里的 $( )

双引号里的 `$( )` 不只放属性（第 20 章）——**任何表达式与命令都行**：

```powershell
"当前目录：$((Get-Location).Path)"
"服务总数：$(@(Get-Service).Count)"
"结果：$(if ($x -gt 5) { '大' } else { '小' })"
"今天是 $((Get-Date).DayOfWeek)，本周第 $([int](Get-Date).DayOfWeek + 1) 天"
```

规则一条：**子表达式输出会自动"拍平成字符串"**（数组变空格连接的单行）——要保结构得先 `-join` 或格式化。滥用警告：一行双引号里塞三个 `$( )` 的可读性悬崖——超过两个就该拆成先算变量再插值。

## 29.5 调用三兄弟：`.`、`&` 与 `::`

三个"执行/访问"符号的完整分野（散在各章，这里收拢）：

| 符号 | 对象 | 作用 | 例 |
|---|---|---|---|
| `.` | 脚本文件 | **点源**：在当前作用域执行（定义入会话） | `. .\lib.ps1` |
| `.` | 对象 | 成员访问 | `$svc.Name` |
| `&` | 命令（路径/变量里的命令名/脚本块） | **调用操作符**：把值当命令跑 | `& $exe 参数`、`& { 1+1 }` |
| `::` | 类型 | **静态成员访问** | `[math]::Round(3.14)` |

`&` 的两个高频场景值得记：**命令名在变量里**（`$tool = 'Get-Service'; & $tool`）；**执行脚本块**（`& { … }` 立即跑，`$block = { … }` 先存后跑——脚本块是值，第 20 章）。

## 29.6 效率杂技

**Measure-Command**（计时，第 06 章介绍过的进阶用法）：

```powershell
(Measure-Command { Get-ChildItem -Recurse }).TotalMilliseconds
```

**默认参数值 `$PSDefaultParameterValues**——给一类命令统一塞默认参数：

```powershell
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Get-*:Verbose'] = $false
```

键的格式 `'命令:参数'`（通配符可用），作用域内一切匹配命令自动带上——**"我所有的导出都要 UTF-8"一行搞定**，是编码洁癖者的福音（也是大坑：忘了设过默认值会困惑"怎么参数没给却生效了"，排错时先查它）。

**Start-Transcript / Stop-Transcript**：会话录制（第 17/22 章已见，此处归档为"效率工具"——做演示、留审计、复盘"我刚才敲了什么"三合一）。

**New-Object 与 `::new()`**：造 .NET 对象的新旧两式：

```powershell
$obj = New-Object -TypeName System.Random        # 老式（5.1 与 7 都可）
$obj = [System.Random]::new()                    # 新式（5.0+；更短、类型检查更早）
```

新式优先；老式在"类型名在变量里"时仍有一席之地（`New-Object -TypeName $typeName`）。

**Get-Random** 的确定性小抄：`Get-Random -Maximum 10 -SetSeed 42`（固定种子可复现）；`Get-Random -InputObject $arr -Count 3`（抽样不重复）。

## 29.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| profile 写了却不生效 | 执行策略挡 / 文件放错四件套之一 / 引擎不对 | 17 章查策略；四件套位置核对；双引擎各自目录 |
| 自定义 Prompt 后调试提示符没了 | 默认的 [DBG]: 逻辑没保留 | 抄默认函数改，别从零写 |
| `$PSDefaultParameterValues` 造成玄学 | 全局默认参数悄悄生效 | 想不起来就查它；不用时 `$PSDefaultParameterValues.Clear()` |
| 子表达式输出数组变一行 | 字符串化拍平 | 先 `-join` 再插值 |
| `New-Object` 与 `::new()` 混用风格不齐 | 历史演进 | 团队统一新式 |
| `-replace` 把 `.` 当通配 | 它是正则替换 | 字面替换用 `.Replace()` 方法或转义 |

## 29.7.1 一行流：十个值得收藏的单行

一行流（one-liner）是"技巧章"的灵魂——每个都用到了本章或前面某章的知识点，值得逐条读懂（读懂=能改）：

```powershell
# 1. 找出最大的 10 个文件（递归、按 MB）
Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending | Select-Object -First 10 FullName, @{n='MB';e={[math]::Round($_.Length/1MB)}}

# 2. 统计某目录各扩展名的文件数
Get-ChildItem -Recurse -File | Group-Object Extension | Sort-Object Count -Descending | Select-Object Count, Name

# 3. 筛选近 24 小时改过的文件
Get-ChildItem -Recurse -File | Where-Object LastWriteTime -gt (Get-Date).AddDays(-1)

# 4. 一行 HTTP 状态检查
('api.example.com','example.com') | ForEach-Object { [pscustomobject]@{ Host=$_; Code=(Invoke-WebRequest "https://$_" -Method Head -UseBasicParsing).StatusCode } }

# 5. 快速造测试数据
1..100 | ForEach-Object { "user$_`t$_`@example.com" } | Set-Content users.tsv

# 6. 文本去重保序
Get-Content names.txt | Select-Object -Unique

# 7. 两个清单的差异（谁加了谁删了）
Compare-Object (Get-Content old.txt) (Get-Content new.txt)

# 8. 服务启动模式审计
Get-Service | Where-Object StartType -eq 'Automatic' | Group-Object Status

# 9. 倒计时提醒（走开泡茶前）
1..3 | ForEach-Object { Start-Sleep 60; "$_ 分钟到" }

# 10. 把任何输出钉成日志
Get-Process | Tee-Object -FilePath proc-$(Get-Date -Format HHmm).log
```

第 4 条的 `-UseBasicParsing`、第 5 条的 `` `t ``（Tab 转义，第 20 章）、第 10 条的子表达式文件名（第 22 章）——每条一行流都是几章知识的合金。**收藏不如改写**：把主机名、路径、阈值换成你的真实环境，它们立刻从教具变成工具。

## 29.8 本章要点

- Profile 四件套与顺序；受执行策略管；双引擎分目录；只放每天必用的。
- **Prompt 是函数**：重定义即自定义提示符（抄默认改，保留调试前缀）。
- 字符串三套：**方法（精活）/ 运算符（值之间）/ -f（模板）**；`$( )` 可装任意表达式但别超两个。
- 调用三兄弟 `.`（点源/成员）、`&`（调值）、`::`（静态）一表分清。
- 杂技：`Measure-Command`、**`$PSDefaultParameterValues`**（全局默认参数）、Transcript、`::new()`、`Get-Random -SetSeed`。

**动手实验**：① 在 profile（当前用户×控制台）写 `Write-Host 'profile 已加载'` 与一个 `Prompt` 函数，重开终端看效果；② 给 Prompt 加时间戳与管理员标记；③ 三套字符串工具各做一题（路径拆分、列表拼接、带日期的模板）；④ `$PSDefaultParameterValues['Out-File:Encoding']='utf8'` 后导一个文件查编码；⑤ `(Get-Command Prompt).Definition` 读默认实现找 `[DBG]` 逻辑；⑥ `[System.Random]::new(42)` 两次会话各取两个数（同种子同序列的确定性）。

实验参考：④编码用记事本另存查看或 `Format-Hex` 头部字节（UTF-8 无 BOM 的 EF BB BF…有 BOM 时）；⑥同一种子两个进程产生**相同序列**——这也是本教程示例库敢断言随机相关输出的原理。

对应示例（可选）：`examples/29_tips/`——字符串三套工具、子表达式、调用三兄弟、默认参数值、`::new()` 与 SetSeed 确定性、Measure-Command 形态断言。

---

本篇（五 工具制作）其余各章：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [30 他人脚本](./30-others-scripts.md)

---

本篇（五 工具制作）导航：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

实验参考：②管理员标记需要窗口以管理员身份启动才可见；⑥同种子同序列是示例库可断言随机输出的原理。

一行流（29.7.1）的十条例子里藏了七种章节知识，改写进自己的环境就是现成工具。
