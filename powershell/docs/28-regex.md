# 28 正则表达式——解析文本的最后手段

> 本章对应原书第 24 章"使用正则表达式解析文本文件"。原书开篇的期望管理值得先抄下来：**在 PowerShell 里你会很少需要正则**——因为数据大多是对象（第 08 章的世界），根本轮不到"解析文本"。但日志文件、老系统导出、协议报文这些纯文本场景终究存在——正则是那里的原住民语言。

## 28.1 正则是什么：文本的"模式描述语言"

正则表达式用一套符号**描述文本模式**："一到三位数字、一个点、一到三位数字……"描述 IPv4 的样子。两点期望管理（原书的立场，值得全盘接受）：

1. **模式匹配 ≠ 数据校验**。`\d{1,3}(\.\d{1,3}){3}` 能匹配 `999.999.999.999`——它描述"长相"不判断"合法"。要校验数值范围，匹配出来再算术判断；
2. **够用就好**。正则自成体系可以很深，本章给"直接能干活"的子集 + 自学方向（`help about_Regular_Expressions`）。

## 28.2 语法速成：一张表 + 四个例子

| 符号 | 含义 | 例 |
|---|---|---|
| `\w` / `\W` | 字母数字下划线 / 反之 | `\won` 匹配 Don、Ron |
| `\d` / `\D` | 数字 / 非数字 | `\d{3}` 三个数字 |
| `\s` / `\S` | 空白 / 非空白 | |
| `.` | 任意单字符 | `d.n` 匹配 don、dan |
| `[aeiou]` / `[^aeiou]` | 集合内 / 集合外 | `d[aeiou]n` 匹配 don 不匹配 doon |
| `[a-z]` | 范围 | `[a-fA-F0-9]` 十六进制字符 |
| `?` | 前面元素 0 或 1 次 | `colou?r` 匹配 color/colour |
| `*` | 前面元素 ≥0 次 | `do*n` 匹配 dn/doon |
| `+` | 前面元素 ≥1 次 | `d[aeiou]+n` 匹配 dooon |
| `{2}` / `{2,}` / `{1,3}` | 精确 / 至少 / 区间次数 | `\d{1,3}` |
| `^` / `$` | 串首 / 串尾锚 | `^Error` 只认行首 |
| `(...)` | **分组捕获** | 见 28.4 |
| `\` | 转义 | `\.` 匹配句号本身 |

四个上手例（照着读一遍，语法就通了）：

```
IPv4 长相：    \d{1,3}(\.\d{1,3}){3}
UNC 路径：     \\\\[\w.]+\\[\w.]+        （PowerShell 单引号串里写 '\\\\'，四个反斜杠见 28.5 的坑）
公司邮箱：     \w+\.\w+@company\.com
日志时间戳：   \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}
```

## 28.3 -match 与 $matches：检测与捕获

`-match`（默认不区分大小写；`-cmatch` 敏感）回答"是否匹配"，**成功时顺手把捕获装进 `$matches` 自动变量**：

```powershell
'don' -match 'd[aeiou]n'            # True
'dooon' -match 'd[aeiou]n'          # False（一个元音吃不下 oo）
'dooon' -match 'd[aeiou]+n'         # True（+ 允许多个）

'2026-10-06 INFO boot' -match '^(\d{4})-(\d{2})-(\d{2})\s+(\w+)'
$matches[0]        # '2026-10-06 INFO' —— 整个匹配
$matches[1]        # '2026' —— 第一个分组
$matches[3]        # '06'
$matches[4]        # 'INFO'
```

分组的编号按左括号顺序（0 恒为整体）；**命名分组**更好用——`(?<year>\d{4})-(?<month>\d{2})` 之后 `$matches['year']` 按名字取（脚本可读性质变）。

两个必须知道的脾气：**`$matches` 会被每一次成功的 -match 覆盖**（用完立刻取走，别隔着别的匹配再用）；**左边是数组时 -match 变过滤器**（返回匹配的元素——第 11 章数组比较特性的又一成员，`@('a1','b2') -match '\d'` 给 `a1, b2` 都在）。

## 28.4 -replace 与 -split：变形与切分

```powershell
'Don Jones' -replace '(\w+) (\w+)', '$2, $1'     # Jones, Don —— 分组在替换里用 $1/$2 引用
'2026-10-06' -replace '-', '/'                    # 2026/10/06（简单形态：字符串替换）
'a,b,,c' -split ','                                # a b (空) c —— 正则切分
'one1two2three' -split '\d'                        # one two three
```

三条纪律：**替换模式用单引号**（`'$2, $1'`——双引号会把 `$2` 当 PowerShell 变量展开成空，悄无声息出 bug，本章第一大坑）；`-replace` 是**运算符**不是方法（与 `.Replace()` 的区别：运算符吃正则、方法吃字面）；`-split` 的模式也是正则（按点切要 `'\.'`）。

## 28.5 Select-String：文件与流的扫描器

对**文件/管道文本流**做正则检索（grep 的 PowerShell 形态）：

```powershell
Select-String -Path C:\Logs\app.log -Pattern 'ERROR 5\d\d'
Get-ChildItem C:\Src -Recurse -Filter *.ps1 | Select-String -Pattern 'Write-Host'   # 扫源码
Select-String -Path app.log -Pattern 'WARN|ERROR' -AllMatches
```

返回 **MatchInfo 对象**（不是裸字符串）——`Line`（命中行）、`LineNumber`、`Path`、`Matches`——于是 grep 之后的统计、排序、导出全是普通管道活：

```powershell
Select-String -Path app.log -Pattern 'ERROR' |
    Group-Object { $_.Matches[0].Value } | Sort-Object Count -Descending
```

常用参数：`-Pattern`（正则，多个即"或"）、`-SimpleMatch`（关掉正则按字面找——找 `1+1` 这类含特殊字符的串时必用）、`-AllMatches`（一行内多次命中都要）、`-Context 2,3`（带前后文，看日志神器）。

## 28.6 实战：日志行变对象

正则在 PowerShell 的终极用法——把非结构化文本**解析成对象**，重新接回对象世界：

```powershell
$lines = Get-Content app.log
$pattern = '^(?<time>\S+ \S+) (?<level>\w+) (?<msg>.*)$'
$parsed = foreach ($line in $lines) {
    if ($line -match $pattern) {
        [pscustomobject]@{
            Time   = [datetime]$Matches['time']
            Level  = $Matches['level']
            Message = $Matches['msg']
        }
    }
}
$parsed | Where-Object Level -eq 'ERROR' | Sort-Object Time
```

套路四步：**定模式（命名分组）→ 逐行 -match → 命中行造 pscustomobject → 回对象管道**。从此日志可以被过滤、统计、导出——第 12 章的全部武器对它生效。这是"文本世界 → 对象世界"的传送门，也是本章的价值上限。

## 28.7 .NET Regex 类：需要更控制时的后门

运算符不够用时（超时控制、预编译、多行模式），直接用 .NET 的 `[regex]` 类（第 08 章静态成员）：

```powershell
[regex]::IsMatch('abc', '^a')               # True
[regex]::Matches('a1 b22 c333', '\d+') | ForEach-Object { $_.Value }   # 1 22 333
[regex]::Escape('C:\Temp\(x)\')             # 转义用户输入再当模式用（防注入习惯）
[regex]::new('\d+').Match('abc123').Value   # 实例形态（可预编译复用）
```

`[regex]::Escape` 值得记：把用户输入的**字面串**安全转成模式（文件名里的 `\`、`(` 都会被转义）——"拿变量当模式"前先 Escape 是好习惯。

## 28.8 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| `-replace` 的 `$1` 没生效 | 替换串用了双引号，`$1` 被 PowerShell 抢先展开 | 替换模式**单引号** |
| 模式里的 `\\` 数不对 | 正则转义 × PowerShell 字符串转义双重叠加 | 用单引号字符串（只有一层转义）；UNC 用 here-string |
| 匹配了意外的子串 | 模式没加 `^$` 锚，正则"允许两端多余" | 身份匹配要锚定首尾 |
| 找 `1+1` 找出乱七八糟 | `+` 是量词 | `-SimpleMatch` 或 `[regex]::Escape` |
| `$matches` 拿到上次的结果 | 被后续成功匹配覆盖 | -match 后立刻消费 |
| 贪婪匹配吃太多 | `.*` 默认贪婪 | 惰性 `.*?`；或收紧字符类 |
| 多行文本 `^$` 不生效 | 默认按单行匹配 | `(?m)` 多行模式或逐行处理 |

## 28.8.1 模式速查库与调测工作流

写正则的效率取决于**调测工作流**，推荐三步（比"改一次跑一次全量"快十倍）：

```powershell
# 第 1 步：小样本上单测模式（立即看到匹配与捕获）
'target line here' -match '(\w+) (\w+)' ; $Matches

# 第 2 步：把候选样本堆进数组，批量验证（对/错例都要有）
样本 = @('2026-10-06 INFO ok', 'bad line', '2026-10-06  WARN x')
$样本 | ForEach-Object { [pscustomobject]@{ Line = $_; Hit = ($_ -match $pattern) } }

# 第 3 步：上真数据前用 Select-String -Pattern 数命中量（量级合理才继续）
```

**错例（不该匹配的样本）是模式质量的裁判**——只拿正例调出来的正则会"见什么匹配什么"。

常用模式库（拿去即用，锚定与转义按 28.8 的坑自检）：

| 用途 | 模式 |
|---|---|
| IPv4 长相 | `^\d{1,3}(\.\d{1,3}){3}$` |
| 邮箱（宽松） | `^[\w.+-]+@[\w-]+\.[\w.]+$` |
| 日期时间 | `^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2})?$` |
| 十六进制色值 | `^#[0-9a-fA-F]{6}$` |
| Windows 盘符路径 | `^[A-Za-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*$` |
| 空行 | `^\s*$` |
| GUID | `^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$` |

这张表的正确用法是**起点不是终点**——落到具体日志格式时，回到调测工作流按样本修正（尤其边界：行首行尾、可选段、分隔符变体）。

## 28.9 本章要点

- 心法：**对象世界轮不到正则**；日志/导出/报文等纯文本场景才是主场；模式≠校验。
- 语法一表够用：`\w \d \s . [..] ? * + {n,m} ^ $ () \`；IPv4/UNC/邮箱/时间戳四个样例读通。
- **`-match` 布尔 + `$matches` 捕获**（命名分组可读性最佳）；数组在左变过滤器。
- `-replace '$2, $1'` 单引号纪律；`Select-String` 返回 MatchInfo（可续管道，`-SimpleMatch`/`-Context`）。
- 终极套路：**日志行 → 命名分组 → pscustomobject** 回对象世界；后门 `[regex]` 类 + `Escape` 防注入。

**动手实验**：① 把 28.2 四个样例逐个对号入座（拿本机 IP、`\\server\share`、邮箱、时间戳文本试匹配）；② 给时间戳模式改成命名分组，`$matches['year']` 取值；③ `'Don Jones' -replace '(\w+) (\w+)', '$2, $1'` 用单/双引号替换串各跑一次看差异；④ `Select-String` 扫本教程 docs 目录里的 '本章要点'，`Group-Object Path` 数每章几处；⑤ 用 28.6 套路解析一段自造日志（三五行即可），统计各级别条数；⑥ `[regex]::Escape('C:\Temp\1+1')` 看输出。

实验参考：③双引号版输出 `Don Jones`（`$2`、`$1` 展开为空再拼接，实际上会输出逗号加原文的怪样）；⑤解析后 `Group-Object Level` 两三行统计——文本进对象世界的完整闭环。

对应示例（可选）：`examples/28_regex/`——语法断言（字符类/量词/锚）、$matches 命名捕获、-replace 分组、-split、Select-String 的 MatchInfo 与 AllMatches、日志解析成对象、Escape 防注入。

---

本篇（五 工具制作）其余各章：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

---

本篇（五 工具制作）导航：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

实验参考：③双引号替换串的输出是"空+逗号+空"拼出来的怪样——单引号纪律的实锤；⑥Escaped 串里 \ 与 \+ 都已翻倍。

调测工作流（28.8.1）的三步比模式库更值得带走——模式会忘，工作流不会。
