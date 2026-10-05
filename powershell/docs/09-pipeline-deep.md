# 09 深入管道——参数绑定的两种方式

> 本章对应原书第 9 章"深入理解管道"，是全书的枢纽章。第 06 章说"同名词命令可以直连"是经验法则，本章给出法则背后的完整判据：**管道参数绑定（pipeline parameter binding）**——引擎怎么决定把命令 A 的输出交给命令 B 的哪个参数。掌握它，你能在一行命令里完成过去要写几十行脚本的工作。

## 9.1 引擎面临的那个问题

```powershell
CommandA | CommandB
```

A 的输出要成为 B 的输入，但 B 有很多参数——引擎必须决定**交给哪个参数**。这个决定过程就叫管道参数绑定，且它严格按**两种方案先后尝试**：先试 **ByValue**（按值），失败再试 **ByPropertyName**（按属性名）。两条都走不通，管道就"空绑"——B 什么也收不到。

判定不靠猜，靠两份档案：

- **A 的输出是什么**：`CommandA | Get-Member`，看 TypeName 和属性清单；
- **B 想要什么**：`help CommandB -Full`，看每个参数的"是否接受管道输入?"（Accept pipeline input?）一行，上面标着 ByValue、ByPropertyName、False 或组合。

这两份档案对照着查，是本章反复使用的**两查动作**，先形成习惯。

## 9.2 方案 A：ByValue——整对象按类型交接

规则：**A 输出的对象类型，恰好是 B 某参数声明的类型**，则整个对象绑给那个参数。**一次只允许一个参数以 ByValue 接收**。

正面例子（第 06 章经验法则的原理）：

```powershell
Get-Process -Name note* | Stop-Process
```

`Get-Process | gm` 显示输出类型是 `System.Diagnostics.Process`；`help Stop-Process -Full` 里 `-InputObject` 参数标注"接受管道输入 true (ByValue)，类型 Process[]"——严丝合缝，每个进程对象整只交给 `-InputObject`，`Stop-Process` 逐个处理。**同名词命令天然同类型，所以"同名词可直连"**。

但 ByValue 有个阴险的失败形态——**绑得上、语义错**。原书的经典事故：

```powershell
Get-Content .\computers.txt | Get-Service
```

`Get-Content` 输出 String，`Get-Service -Name` 恰好按 ByValue 接收 String——绑定成功了！但文本文件里装的是**计算机名**，`-Name` 把它们当成了**服务名**。结果：引擎满世界找名叫 SERVER2、WIN8 的服务，报一串"找不到服务"。**类型对得上只说明语法通了，值的意思对不对引擎不管**——这是管道排错时必须警觉的一类"成功的技术、错误的语义"。

再看真正的失败：`Get-Service | Stop-Process`。A 输出 `ServiceController`，而 `Stop-Process` 没有任何参数按 ByValue 接收 ServiceController——方案 A 失败，引擎转向方案 B。

## 9.3 方案 B：ByPropertyName——属性名对参数名

规则简单到一句话：**A 输出对象的属性名，与 B 的参数名同名，就把属性值绑给该参数**。与 ByValue 的"独占一个参数"不同，ByPropertyName 可以**多个属性同时各绑各的**。

原书的招牌案例值得亲手做一遍。造一个 CSV（列名故意起成 New-Alias 的参数名）：

```powershell
@'
Name,Value
d,Get-ChildItem
sel,Select-Object
go,Invoke-Command
'@ | Set-Content aliases.csv
Import-Csv .\aliases.csv | New-Alias
Get-Alias d, sel, go
```

`Import-Csv` 的输出是 PSCustomObject，**CSV 的每一列变成一个属性**——所以这些对象有 `Name` 和 `Value` 两个属性，恰好对上 `New-Alias` 的 `-Name`/`-Value` 两个参数（帮助里两者都标注"接受 ByPropertyName"）。一条管道，两列同时绑定，三个别名入库。（做完记得收拾：`Remove-Item Alias:\d, Alias:\sel, Alias:\go`。）

这个案例揭示了 ByPropertyName 的设计意图：**它是给"数据源"准备的接口**——CSV、数据库查询、AD 对象、任何"行结构"的数据，把列名对齐参数名就能整批灌入命令。你甚至可以反向利用：想知道某命令"吃什么"，看它哪些参数接受 ByPropertyName，那就是它开给数据世界的嘴。

一个实测发现值得插在这里：**参数的别名也参与 ByPropertyName 匹配**。`Get-Service -Name` 参数有个官方别名 `ServiceName`（服务行业的行话），于是 `[pscustomobject]@{ServiceName='winmgmt'} | Get-Service` 也能绑上——属性名对上了参数的**别名**。反过来说，绑定彻底失败（属性名既不是参数名也不是任何别名）时，B 会以空参数面对管道对象，产出错误或拿不到你要的目标——"悄悄绑不上"比"报错绑不上"更值得警惕，因为你可能拿到了一个**看起来正常但内容不对**的结果。查参数别名的办法：`(Get-Command Get-Service).Parameters['Name'].Aliases`。

方案 B 也有失败形态——**名字对、值域错**。`Get-Service | Stop-Process`：A 的 `Name` 属性对上 B 的 `-Name`（接受 ByPropertyName），绑定成功——但服务名（`Spooler`、`W32Time`）不是进程名（`svchost`、`pwsh`），于是又是一屏"找不到进程"。两次教训合起来是本章最重要的一句总结：

> **绑定只看"类型"和"名字"，永远不看"值是什么意思"。语义对齐是写命令的人的责任。**

## 9.4 数据不对齐时：改名桥接

真实数据不会总是恰好长成参数的样子。比如手头对象有个 `ServiceName` 属性（名字不叫 `Name`），要接给 `Get-Service -Name`——用第 08 章的计算属性**现场改名**：

```powershell
$stuff | Select-Object @{ n = 'Name'; e = { $_.ServiceName } } | Get-Service
```

`Select-Object` 产出的新对象带着 `Name` 属性，ByPropertyName 通道立刻打通。改名桥接 + ByPropertyName 是"任意数据 → 任意命令"的通用转接件，这一招在第 12 章的综合实战里会挑大梁。

## 9.5 绑定走不通时：圆括号强制喂参

有些命令的参数压根不接受管道输入（`help` 里那行写着 False）。例如查 BIOS 信息时（原书用当时主流的 `Get-WmiObject` 举例，这个命令已在 pwsh 7 移除、由第 14 章的 CIM 命令接替，但教学结构不变）：

```powershell
Get-Content .\computers.txt | Get-WmiObject -Class Win32_Bios     # 走不通
Get-WmiObject -Class Win32_Bios -ComputerName (Get-Content .\computers.txt)   # 走得通
```

第二条的机关是**圆括号 = 先执行**（第 03 章的老规则）：括号里的 `Get-Content` 先跑完，产出的 String 数组作为**值**直接赋给 `-ComputerName` 参数——完全绕开绑定机制。括号方案的优势是不依赖任何绑定标注、总能强喂；劣势是**一次性**——括号在命令执行前求值一次，不像管道能流式逐个处理，数据源巨大时先全量取完再开工。

**括号 vs 管道的选择**：参数支持管道绑定时优先管道（流式、可组合）；不支持或绑定语义不对时用括号。

顺带一个重要的**双引擎差异**（实测）：`Get-Service` 的 `-ComputerName` 参数**只在 5.1 存在**——它依赖 .NET 的服务控制管理器远程，pwsh 7 把它移除了（`(Get-Command Get-Service).Parameters.ContainsKey('ComputerName')` 一查便知，5.1 是 True、7 是 False）。原书时代"文本文件喂 -ComputerName 查多机服务"的经典模式，在 7 下的正确替代是 `Invoke-Command`（第 13 章）或 CIM 会话（第 14 章）。老脚本迁到 pwsh 7 时，"参数不存在"这类红字先想到版本差异。

## 9.6 开盒取物：-ExpandProperty 的绑定学意义

第 08 章教过 `-Property`（选盒子）与 `-ExpandProperty`（开盒取内容）的取值差异，现在补上绑定学意义。原书的盒子比喻值得原样保留：

> `-Property Name` 是**选中有 Name 盒子的那个包裹**（你拿到的还是包裹）；`-ExpandProperty Name` 是**打开盒子倒出内容、扔掉包装**（你拿到的是裸值）。

场景：域里的计算机对象（`ADComputer` 类型）要喂给 `Get-Service -ComputerName`（要 String）：

```powershell
# ✗ 包裹喂不进去：ADComputer 对象 ≠ String
Get-Service -ComputerName (Get-ADComputer -Filter *)

# ✗ 还是包裹：Select -Property 产出的仍是 PSCustomObject
Get-Service -ComputerName (Get-ADComputer -Filter * | Select-Object -Property Name)

# ✓ 开盒：Expand 产出裸 String，参数收下
Get-Service -ComputerName (Get-ADComputer -Filter * | Select-Object -ExpandProperty Name)
```

没有域环境也不影响掌握——把 `Get-ADComputer` 换成任何"输出带 Name 属性的对象"的命令（比如 `Get-Process`），规律分毫不差。**判断题永远只有两问：我手里是什么（gm 查）？它要什么（help 查）？** 中间的桥（改名、开盒、括号）按需架设。

## 9.7 三步判定法（本章收束）

把全章压缩成一张随身卡片。面对 `A | B` 要不要能接、怎么接：

1. **查 A**：`A | Get-Member`——记下 TypeName 与属性名清单；
2. **查 B**：`help B -Full`——找"接受管道输入"行，记录哪些参数接受 ByValue/ByPropertyName 及其类型；
3. **对齐**：
   - 类型吻合 → ByValue 直连（同名词命令基本属于此类）；
   - 属性名=参数名 → ByPropertyName 直连（数据源灌入属于此类）；
   - 差一个名字 → `Select-Object` 改名桥接；
   - 是包裹不是裸值 → `-ExpandProperty` 开盒；
   - B 不收管道 → 圆括号强喂；
   - 都不行 → 别硬接，中间写一小段 `ForEach-Object`（第 16 章）或函数（第 25 章）。

原书配套的思维练习（自包含重述，建议先自己判再看答案）：设 `Get-ADComputer -Filter *` 输出 ADComputer 对象（有 Name 属性），判断三段命令谁能取出所有机器的补丁清单——

- `Get-HotFix -ComputerName (Get-ADComputer -Filter * | Select-Object -ExpandProperty Name)` → **能**：开盒产出 String[] 喂参数；
- `Get-ADComputer -Filter * | Get-HotFix` → **不能**：ADComputer 不是 String，`Get-HotFix` 的参数也不接受 ByPropertyName 绑 ADComputer 的任何属性（Name 属性名没对上它的参数名）；
- `Get-ADComputer -Filter * | Select-Object -Property Name | Get-HotFix` → **不能**：还是包裹（PSCustomObject），既不匹配 ByValue 类型，属性名 Name 也不是 Get-HotFix 的参数名。

三题全对，本章就毕业了。

再加三道更贴近日常的判定练习（都能在本机验证）：

**练习 4**：`'localhost' | Get-Service` 能否拿到本机服务清单？
判定：String 按 ByValue 找接收 String 的参数——`-Name` 接收。**绑得上，但把机器名当服务名**，结果是"找不到服务"错误。语法正确、语义全错的第一类事故的标准形态。

**练习 5**：`Get-Process -Id $PID | Get-Service` 呢？
判定：A 输出 `Process` 对象；`Get-Service` 没有任何参数按 ByValue 接收 Process；属性对参数名——Process 有 `Name` 属性，`-Name` 接受 ByPropertyName——于是**名字对上了**：你拿到的是"名字恰好等于当前进程名（pwsh/powershell）的服务"，多半也是"找不到"。名字对、值域错的第二类事故。

**练习 6**：`Get-ChildItem *.csv | Remove-Item`？
判定：A 输出 `FileInfo`；`Remove-Item` 的 `-LiteralPath`/`-Path`（经别名 `PSPath`）都接受管道。FileInfo 有 `PSPath`（NoteProperty，提供程序贴上去的），于是经别名绑定到路径——**删的就是这些文件**。这条能跑通，而且揭示了提供程序对象的 `PSPath`/`PSParentPath` 附加属性（第 05 章）在绑定层的实际用途。

练习 6 的答案可以亲手验证（在一个只放了两个临时 CSV 的目录里跑），练习 4、5 验证时会看到真实的错误输出——**看着红字说出"这是第几类事故"，是本章最好的自测**。

## 9.8 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 管道接上了但报"找不到 XXX" | 绑定成功但语义错（值域不匹配） | 两查动作核对"值的含义"，别只看语法通没通 |
| `A \| B` 没报错也没输出 | 绑定双失败，B 以空参面对输入 | `help B -Full` 查绑定标注；gm 查 A 的类型 |
| 明明属性名"差不多"却绑上了/没绑上 | 参数别名参与匹配（如 ServiceName→-Name） | 查 `Parameters['名'].Aliases` |
| 喂参数报"无法转换 PSCustomObject" | 给了包裹没开盒 | `-ExpandProperty` 取裸值 |
| 属性名差一点绑不上 | 名字不完全相等 | 计算属性改名 `@{n='参数名';e={$_.属性}}` |
| 括号里命令慢、内存高 | 圆括号一次性全量求值，非流式 | 大数据源优先管道绑定 |
| 老脚本报"找不到参数 ComputerName" | pwsh 7 移除了部分 5.1 参数（Get-Service 等） | 改用 Invoke-Command/CIM（13/14 章） |

## 9.9 本章要点

- 绑定两方案按序尝试：**ByValue（类型吻合，独占一参）→ ByPropertyName（名字相同，多参并行）**；两查动作（`gm` 查 A、`help -Full` 查 B）是判定基础。
- 绑定只认类型与名字，**不认语义**——"成功的技术、错误的语义"是管道第一大坑。
- 数据源接口：CSV 列名 = 参数名，ByPropertyName 整批灌入（`Import-Csv | New-Alias`）。
- 三座桥：**改名**（计算属性）、**开盒**（`-ExpandProperty`）、**强喂**（圆括号，一次性非流式）。
- 三步判定法 + "我手里是什么/它要什么"两问，是全教程最值得背下来的方法论。

**动手实验**：① 做 9.3 的 aliases.csv 实验并清理；② `'winmgmt' | Get-Service` 验证 String→-Name 的 ByValue；③ `[pscustomobject]@{ServiceName='winmgmt'} | Get-Service`（观察它经参数别名绑定成功），再换 `SvcName` 属性观察真正空绑；④ `Get-Service -Name (Get-Content names.txt)`（文件里写 winmgmt）验证括号；⑤ 对 9.7 的三道判定题与练习 4–6 先自己作答再对答案。

实验参考：③换 `SvcName` 后什么都拿不到——没有服务叫这个名字，也没有任何绑定发生；⑤练习 4 在两个引擎里报错形态一致（找不到服务），而 `Get-Service -ComputerName` 的存在性两引擎不同（参数级差异，见 9.5 的差异标注）。

## 9.10 绑定规则速查卡（打印版）

```
A | B 时引擎的决策树：

1. B 有参数按 ByValue 接收 A 的输出类型吗？
   有 → 整对象绑给该参数（唯一），结束
   无 → 2
2. A 输出的属性名（含参数别名匹配）== B 的参数名吗？
   有（且该参数接受 ByPropertyName）→ 每个匹配各绑各的，结束
   无 → 空绑：B 以空参数面对管道

搭桥手段（按侵入性从低到高）：
· 改名：  Select-Object @{n='参数名';e={$_.属性}}
· 开盒：  Select-Object -ExpandProperty 属性
· 强喂：  B -参数 (A)          ← 一次性全量，非流式
· 自定义：ForrEach-Object { B -参数 $_.属性 }   ← 第 16 章
```

对照速查（本教程涉及的常见可直连管道）：

| 上游 → 下游 | 绑定方式 | 语义 |
|---|---|---|
| `Get-Process → Stop-Process` | ByValue（Process） | 杀这些进程 ✓ |
| `String → Get-Service` | ByValue（-Name） | 当心：字符串得是服务名 |
| `Import-Csv → New-Alias` | ByPropertyName（Name/Value） | 列名=参数名即可灌入 |
| `Get-ChildItem → Remove-Item` | ByPropertyName（PSPath→路径） | 删除这些文件 ✓ |
| `Get-Service → Stop-Process` | ByPropertyName（Name） | 名对值域错，报错 ✗ |

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [07 模块生态](./07-modules-usage.md) · [08 对象](./08-objects.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)


补充阅读：本章所有断言都可以在本教程示例库 examples/09_pipeline_deep/ 里双引擎复现。

---

本篇导航：[06 管道](./06-pipeline-first.md) · [07 模块](./07-modules-usage.md) · [08 对象](./08-objects.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)
