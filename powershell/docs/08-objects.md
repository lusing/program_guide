# 08 对象——数据的另一个名称

> 本章对应原书第 8 章"对象：数据的另一个名称"。原书作者自称试遍各种讲法后找到的这套"表"类比，是全书理解 PowerShell 的地基章——管道里流动的到底是什么、为什么屏幕上永远只看到一小部分、以及第二重要的命令 `Get-Member`。

## 8.1 把对象想象成一张内存中的表

运行 `Get-Process`，屏幕上是一张七八列的表格。但这只是**冰山一角**：进程对象有六十多个属性——机器名、主窗口句柄、最大工作集、退出代码、处理器掩码……PowerShell 在内存里构建的是一张**完整的表**，每行一个进程、每列一个属性；屏幕上显示哪些列，是微软的配置文件替你挑的"最常用八列"（第 10 章讲谁在挑、怎么改）。

想看全表？第 06 章的招数直接复用：`Get-Process | ConvertTo-Html | Out-File p.html`——**转换命令不受屏幕配置约束**，全部列都在文件里。

于是术语可以这样翻译（原书的四件套，困惑时随时回来查）：

| 日常说法 | PowerShell 术语 | 例子 |
|---|---|---|
| 表的一行 | **对象**（object） | 一个进程、一个服务 |
| 表的一列 | **属性**（property） | 进程名、CPU 时间、服务状态 |
| 这行数据能做的事 | **方法**（method） | 杀掉进程、启动服务、刷新数据 |
| 整张表 | **集合**（collection） | 全部进程对象的集合 |

后文一律用这套词汇。**对象 = 属性打包 + 方法附带**：属性是"它是什么"，方法是"它能做什么"。

## 8.2 为什么 PowerShell 用对象而不用文本

假设 PowerShell 输出的是纯文本表格（像很多 Shell 那样），你只想对 `conhost` 进程做点事，流程会是这样：先用 grep"保留第 58~64 列包含 conhost 的行"（**按列位置切文本**），再用 awk"取第 52~56 列的字符当进程 ID"，然后把 ID 列表交给杀死进程的命令。三个问题立刻浮出来：

1. **你的时间花在解析文本上，而不是任务上**——列位置、分隔符、正则成了主业；
2. **输出格式一变全链报废**——某天 `ProcessName` 列挪到第一列，你所有按位置切的脚本全部重写；
3. **你得成为文本解析专家**——grep/awk/sed/Perl 的学习成本，与"我想杀个进程"这件事毫不相干。

对象把这三笔账全免了：**数据在内存表里永远按"列名"存取**，`$_.ProcessName` 就是进程名，不管屏幕上它显示在第几列、显示不显示。Windows 本身就是面向对象的操作系统（重 API、重对象模型），PowerShell 用对象与之对接是顺水推舟——这也是为什么文本 Shell 在 Unix 世界天经地义（Unix 是文本哲学的操作系统），而在 Windows 上用对象才是原生姿势。

一个心理定位：**"屏幕输出"只是对象在你眼前的投影**。投影可以被裁剪、重排、格式化，对象本身不动。这个认知在下一章（管道绑定）和第 10 章（格式化）会反复兑现。

## 8.3 探索对象的第二重要命令：Get-Member

帮助系统讲**命令怎么用**，不讲**输出对象长什么样**。看对象要用 `Get-Member`（别名 `gm`，值得形成肌肉记忆）——把它接在任何产生输出的命令后面：

```powershell
Get-Process | Get-Member
```

输出是一张**成员清单**，开头一行最关键：

```
   TypeName: System.Diagnostics.Process
```

这一行是对象的**类型全名**（.NET 类型），值得专门记住它的三个用途：

1. 它是"这对象是什么"的权威答案——搜索文档、查 .NET API、给别人描述问题时，报 TypeName 比截图准确；
2. 它解释了 CSV 首行的 `# TYPE` 头（第 06 章）从哪来——就是它；
3. 它是第 10 章"格式化配置按类型生效"的钥匙。

清单主体逐行列出成员，`MemberType` 列标注每个成员的出身：

| MemberType | 含义 | 例子 |
|---|---|---|
| `Property` | 真实属性（.NET 对象自带） | `Name`、`Id` |
| `ScriptProperty` | **脚本属性**：由 PowerShell 挂上去的计算值 | `ProcessName` 背后是代码 |
| `NoteProperty` | **附加属性**：动态贴上的标签 | 远程结果对象上的 `PSComputerName` |
| `Method` | 方法 | `Kill()`、`Refresh()` |
| `PropertySet` | 属性的组合视图 | `DefaultDisplayPropertySet`——**就是它决定了屏幕只显示八列** |

日常 90% 的场景只用 Property 和 Method 两类；看到 `DefaultDisplayPropertySet` 时可以会心一笑：屏幕摘要的"挑列名单"原来藏在这里。

两个实用技巧：只看某类成员 `Get-Process | gm -MemberType Property`（清单立刻清爽）；只看静态成员 `gm -Static`（下一节讲静态）。

## 8.4 选取与降维：Select-Object

`Select-Object` 是"从表里取子表"的命令，两个方向要分清：

**取子集（仍是对象）**：`-Property` 挑列，产出的是**只有这些列的新对象**：

```powershell
Get-Process | Select-Object -Property Name, Id, CPU
```

**降维取值（变成裸值）**：`-ExpandProperty` 把某一列抽出来，产出的直接是那一列的值（比如一组字符串）：

```powershell
Get-Service | Select-Object -ExpandProperty Name      # 输出：一列服务名
```

区别的分量在下一章：**喂参数时要"值"，管道绑定要"对象"**——`-ExpandProperty` 制造的裸值数组可以喂给 `-ComputerName`；`-Property` 制造的小对象可以按属性名绑定（第 09 章展开）。现在先记住：**要列用 Property，要值用 ExpandProperty**。

`Select-Object` 还兼职"取前 N 行"：`-First 5`、`-Last 3`、`-Skip 10`、`-Unique`（去重）。`-First` 有个隐藏福利：配合流式管道会**提前终止上游**（第 06 章 6.7 节演示过）。另外集合本身支持索引和切片：`(Get-Process)[0]` 取第一个、`$p[-1]` 取最后一个（负索引，第 20 章细讲数组）。

## 8.5 计算属性：现做一列出来

想看的列不存在？**现算一列**。语法是一个哈希表字面量（第 20 章正式学），两个键：`n`（name，新列名）和 `e`（expression，怎么算）：

```powershell
Get-Process |
    Select-Object Name,
        @{ n = 'WS_MB'; e = { [math]::Round($_.WS / 1MB, 0) } } |
    Sort-Object WS_MB -Descending |
    Select-Object -First 5
```

逐段读：`$_` 是"当前流经的对象"（管道占位符，全教程出镜率最高的符号）；`$_.WS` 是进程工作集字节数，除以 `1MB`（PowerShell 内置的数值后缀常量，还有 `1KB/1GB/1TB`）换成兆；`[math]::Round(…, 0)` 四舍五入取整；新列叫 `WS_MB`，之后**就像原生属性一样**能排序、能比较。这条命令的完整语义："列出吃内存最多的五个进程，以兆为单位"。

计算属性是 PowerShell 数据加工的万能胶：单位换算、字符串拼接、条件标记（`e = { if ($_.CPU -gt 100) {'高'} else {'低'} }`）、从嵌套对象里取深层字段，全是这一招。它还能用在 `Sort-Object`、`Format-Table`（第 10 章）、`Group-Object` 上，语法通用。

## 8.6 排序：Sort-Object

```powershell
Get-Service | Sort-Object Status, Name -Descending
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
```

要点：**多键排序**逗号分隔（先按 Status 再按 Name）；`-Descending` 作用于**所有**键，想让部分升序部分降序，用哈希表逐键指定：`Sort-Object @{e='CPU';Descending=$true}, Name`。还有 `-Unique`（排序兼去重）。注意 `Sort-Object` 是第 06 章说过的**缓冲型**命令——必须收完所有对象才能排，超大集合接在它前面要有心理预期。

## 8.7 方法与静态成员：`.` 与 `::`

**实例方法**用点号调用，作用在"这一个对象"上：

```powershell
'powerShell'.ToUpper()               # POWERSHELL —— 字符串对象的方法
(Get-Date).AddDays(7)                # 一周后的此刻 —— 日期对象的方法
$proc.Kill()                         # 杀掉这个进程 —— 慎用
```

调用必须带圆括号——**有括号是"执行"，没括号是"引用"**：`$p.Kill` 只是拿到方法本身（能当值传递，第 25 章会用），`$p.Kill()` 才是真杀。传参也走括号：`.Substring(0, 5)`。

**静态成员**属于类型本身而不属于某个对象，用双冒号 `::` 访问：

```powershell
[math]::Round(3.14159, 2)            # 3.14
[math]::Sqrt(144)                    # 12
[datetime]::Parse('2026-10-06')      # 字符串转日期
[string]::Join('-', 'a', 'b', 'c')   # a-b-c
```

`[math]`、`[datetime]`、`[string]` 这类**类型字面量**（方括号包类型名）是通往整个 .NET 类库的门票——你不需要学 C#，只是在借用一个装了几万个工具的车库。常用的入口：`[math]`（数学）、`[datetime]`（日期）、`[string]`/`[char]`（文本）、`[io.file]`/`[io.path]`（文件系统底层）、`[guid]`、`[regex]`（第 28 章主角）。

分清两个符号：**`.` 找对象身上的（实例成员），`::` 找类型身上的（静态成员）**。用 `Get-Member -Static` 可以列出某类型的全部静态成员：`[math] | Get-Member -Static`。

## 8.8 活对象与快照对象

一个容易被忽略的细节：**你手里的对象是"活的"还是"照片"？** `Get-Process` 返回的 `Process` 对象是**活对象**——它内部仍连着操作系统那个真实的进程，属性值是取值瞬间的快照，但你可以调用 `$p.Refresh()` 重新读数、调用 `$p.WaitForExit()` 等待真实事件。而 `Get-Service` 的 `ServiceController`、`Get-CimInstance` 的输出则偏"半活"，更多对象（如 `Import-Csv` 读回的行、`Select-Object` 产出的子对象）是纯**快照**——数据到此为止，方法寥寥。

这个区分在两处产生实际后果：一是**对快照对象调用方法会失败或无意义**（CSV 里读出的"进程"不能 `.Kill()`——要杀得重新 `Get-Process` 拿活对象）；二是**长脚本里别过早取数**——开头取的快照到脚本结尾已经过时，需要时再取。判断方法还是老一套：`| Get-Member` 看它有没有那几个方法。

## 8.9 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| `.Kill` 或 `.Refresh` 没反应 | 没带括号，只是引用了方法没执行 | 方法调用必须 `()` |
| 改了对象属性，屏幕没变化 | 屏幕是投影；部分对象属性只读 | 用 `Set-Service` 等"动词命令"做变更，别直接改属性 |
| `Select-Object Name` 后再 `.CPU` 取不到 | 子对象只带挑出来的列 | 一次挑够列，或先取完整对象最后再 Select |
| 计算属性里 `$_` 用错层 | 嵌套管道里 `$_` 指内层当前对象 | 内层用 `$PSItem` 同义但易读；或先存变量 |
| 对 `Import-Csv` 的行调方法报错 | CSV 行是快照 PSCustomObject | 方法类操作先还原成活对象 |
| `$p.Length` 报错 | 单个对象没有 Length（那是集合/字符串的） | 集合计数用 `@($x).Count`（第 20 章单元素陷阱） |

最后一条先埋个种子：**`@(...)` 包裹再 `.Count`** 是 PowerShell 里最稳的计数姿势，原因第 20 章揭晓。

## 8.10 本章要点

- 对象 = 内存表的一行：**属性是列、方法是行为、集合是整表**；屏幕输出只是投影（`DefaultDisplayPropertySet` 在挑列）。
- 文本 Shell 的解析地狱（按列位置切字符）是 PowerShell 用对象消灭的第一目标；`$_.列名` 永远有效，与显示格式无关。
- **`Get-Member` 是第二重要命令**：`TypeName` 行是对象的身份证；日常只认 `Property`/`Method` 两类成员。
- `Select-Object`：`-Property` 取子对象、`-ExpandProperty` 取裸值（下一章绑定的关键）、`-First/-Last/-Skip/-Unique` 截取。
- **计算属性** `@{n=;e=}` 现算新列，排序/格式化通用；`Sort-Object` 多键+哈希表逐键控方向。
- `.` 调实例成员，`::` 调静态成员；有括号才是执行；`[math]`/`[datetime]` 等类型字面量是 .NET 车库的钥匙。

## 8.10 延伸：三张常用类型速查

对象探索做多了会发现高频类型就那几个，提前混个脸熟（`gm` 的 TypeName 列会反复见到它们）：

| 类型 | 出处 | 常用属性/方法 |
|---|---|---|
| `System.Diagnostics.Process` | Get-Process | Name、Id、WS、CPU、Kill()、Refresh() |
| `System.ServiceProcess.ServiceController` | Get-Service | Name、Status、StartType、Start()、Stop() |
| `System.IO.FileInfo` / `DirectoryInfo` | Get-ChildItem / Get-Item | Name、Length、FullName、LastWriteTime、CopyTo() |
| `System.String` | 一切文本 | Length、ToUpper()、Split()、Replace()、Substring() |
| `System.DateTime` | Get-Date | Year/Month/Day、AddDays()、ToString('格式') |
| `System.Management.ManagementObject`（衍生） | Get-CimInstance | CIM 属性（Caption、Version…）+ 方法（第 14 章） |
| `System.Management.Automation.PSCustomObject` | Import-Csv、Select-Object、哈希表转换 | 动态属性（列名即属性名），NoteProperty 形态 |

最后一行的 `PSCustomObject` 值得多说一句：它是"你自己造的行对象"的标准形态——CSV 每行、计算属性产出、`[pscustomobject]@{}` 字面量（第 20 章）都是它。它没有方法只有属性，是纯数据载体；第 31 章讲 JSON 往返时它还是主角。认得它的 TypeName，半数"这对象哪来的"问题当场有答案。

**动手实验**：① `Get-Service | gm` 找到 TypeName 行，再用 `-MemberType Property` 只看属性；② `Get-Process | gm` 数数 Property 与 Method 各多少个；③ 用 `-ExpandProperty` 取出全部服务名，数数有几个以 W 开头；④ 用计算属性把 `Get-Process` 的 WS 换算成 MB 排序取前 5；⑤ `'PowerShell'` 这个字符串有哪些方法？（`'x' | gm`）调 `.ToUpper()`、`.Length`（注意 Length 是属性不是方法，不用括号）；⑥ `[datetime]::Parse('2026-10-06').DayOfWeek` 算算那天是星期几。

实验参考：①`System.ServiceProcess.ServiceController`；③`(Get-Service | Select-Object -ExpandProperty Name | Where-Object { $_ -like 'W*' }).Count`；④即 8.5 节示例原句；⑤还有 `Substring/Replace/Split/Trim/StartsWith/Contains` 等，第 29 章字符串专题；⑥`[System.DayOfWeek]::Tuesday` 枚举值——枚举类型第 31 章正式讲。

对应示例（可选）：`examples/08_objects/`——TypeName 与成员类型断言、Select 两种取法的类型差异、计算属性值验证、多键排序、实例/静态方法调用。

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [07 模块生态](./07-modules-usage.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)


补充阅读：本章所有断言都可以在本教程示例库 examples/08_objects/ 里双引擎复现。

---

本篇导航：[06 管道](./06-pipeline-first.md) · [07 模块](./07-modules-usage.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)
