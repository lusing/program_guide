# 24 · 综合实战：成绩 CSV 分析与报告

> 对应示例：`examples/22-project.sml`


前 23 章全是零件。这一章把它们装成一台机器：**读一个 CSV、算出统计、排个名、做个线性拟合、写一份报告、再验证报告写对了、最后把临时文件删干净。**

这不是玩具。它涉及的所有环节 —— 文件读写、字符串切分、缺失值、错误处理、排序与并列、数值计算、输出格式化、清理 —— **在真实数据处理任务里一个都不会少**。

## 24.1 数据模型：缺失值用 `option`

```sml
type student = { name : string, math : int option, english : int option }
```

**`int option` 是这个项目的核心设计决定。** 缺考就是 `NONE`，有成绩就是 `SOME 90`。

换一个方案对比一下就清楚为什么：

| 方案 | 缺考表示 | 问题 |
|---|---|---|
| `int`，用 `-1` 表示缺考 | `~1` | **和真实分数无法区分**；算平均时会混进去 |
| `int`，用 `0` | `0` | 会把均分拉低；0 分和缺考完全不同 |
| **`int option`** | `NONE` | **不可能忘掉**：想取值必须先 `case`/`mapPartial` |

**用类型把「缺失」编码进去，编译器就会帮你查所有需要处理缺失的地方。** 这是 SML 处理脏数据最重要的手法。

## 24.2 第一步：生成 CSV 并落盘

```sml
val csvText =
    "name,math,english\n"
    ^ "alice,90,85\n"
    ^ "bob,72,\n"
    ^ "carol,88,91\n"
    ^ "dave,,78\n"
    ^ "erin,60,65\n"

val _ = writeText (csvPath, csvText)
```

```
1) wrote sml-report-input.csv (70 chars, header + 5 data lines)
```

**数据是内嵌在源码里的字符串**，不依赖任何外部文件。这样示例才可能「在任何机器上跑出完全一样的输出」。

**注意 `bob,72,` 和 `dave,,78`**：一个是英语缺考，一个是数学缺考。**两种缺失位置都覆盖了**，不留死角。

**两行中间空的那一列**，用 `String.fields` 切会得到空字符串（第 21 章讲的），`Int.fromString ""` 返回 `NONE` —— 于是空字段自然变成 `NONE`。**整条链路不需要任何「特判空字段」的代码**：

```sml
{ name = n, math = Int.fromString m, english = Int.fromString e }
```

`Int.fromString ""` → `NONE`，就这么简单。**这是「选对基础函数」带来的优雅**（21.6 那节讲 `tokens` vs `fields` 的回报）。

## 24.3 切行：`fields` 保留空行，所以要滤掉

```sml
fun splitLines (text : string) =
    List.filter (fn l => l <> "") (String.fields (fn c => c = #"\n") text)
```

**为什么用 `fields` 而不是 `tokens`？** 因为文本以 `\n` 结尾，`fields` 会在末尾多切出一个空串（`"a\nb\n"` → `["a","b",""]`），而 `tokens` 会把它丢掉 —— 这里两种都能用，示例选了 `fields` + 显式 `filter`，**因为这样意图更明确**：「我知道会多出空行，我主动滤掉它」。

**但要小心：`filter (fn l => l <> "")` 会连「正文里的空行」一起删掉。** 对 CSV 来说没问题（空行不是数据），但如果是需要保留空行的格式（markdown 原文、代码），这个滤法就错了。**更严谨的写法是只去掉末尾那一个空串**：

```sml
fun splitLines (text : string) =
    case String.fields (fn c => c = #"\n") text of
        [] => []
      | ls => if List.last ls = "" then List.take (ls, length ls - 1) else ls
```

示例选了简单的版本，注释说明了理由 —— **这是可接受的取舍，但要意识到取舍的存在。**

## 24.4 解析一行：三个字段，两种错误

```sml
fun parseStudent (line : string) =
    let
        val fs = String.fields (fn c => c = #",") line
    in
        case fs of
            [n, m, e] =>
                if n = "" then raise Fail "empty name in first field"
                else { name = n, math = Int.fromString m, english = Int.fromString e }
          | _ => raise Fail ("expected 3 fields but got " ^ Int.toString (length fs))
    end
```

**`case fs of [n, m, e] => ... | _ => ...` 这个模式值得单独看。**

`[n, m, e]` 是**列表模式**，它同时隐含了「恰好三个元素」这个条件。**如果字段数是 2 或 4，这个分支就不匹配**，落到 `_` 分支。**用模式匹配代替「先判 `length fs = 3` 再取下标」**，这是 SML 的招牌写法 —— 不需要 `if`，不需要 `hd`/`nth`，不可能越界。

```sml
val _ = say ("3) malformed \"zoe,80\"        -> " ^ tryParse "zoe,80")
val _ = say ("   malformed \",90,80\"        -> " ^ tryParse ",90,80")
val _ = say ("   malformed \"x,90,80,extra\"  -> " ^ tryParse "x,90,80,extra")
```

```
3) malformed "zoe,80"        -> raised Fail / expected 3 fields but got 2
   malformed ",90,80"        -> raised Fail / empty name in first field
   malformed "x,90,80,extra"  -> raised Fail / expected 3 fields but got 4
```

**三种坏行，两条错误消息：**

| 输入 | 字段数 | 错误 |
|---|---|---|
| `zoe,80` | 2 | 字段数不对 |
| `,90,80` | 3 | **字段数对，但名字为空** |
| `x,90,80,extra` | 4 | 字段数不对 |

**第二种是最容易被漏掉的**：字段数正好三个，但第一个是空串。**如果没有那句 `if n = ""`，这条数据会以「名字为空的合法学生」混进结果**，排名里会出现一个空名字的行。

**「字段数对但内容是坏的」是数据清洗里最常见的一类脏数据。** 校验分两层：**结构层**（字段数、类型）和**语义层**（非空、取值范围、业务规则）。示例里两层都做了。

**错误处理用 `raise Fail`，调用方 `handle`：**

```sml
fun tryParse (line : string) =
    (let
         val s : student = parseStudent line
     in
         "ok / name = " ^ #name s
     end)
    handle Fail msg => "raised Fail / " ^ msg
```

**注意 `(let ... end)` 外面那对括号。** `handle` 的左侧是一个表达式，而 `let ... end` **不需要括号就能当表达式**——但加上括号让「`handle` 接的是整个 `let`」这件事更明显，也避免了 `handle` 顶格的新行引发语法问题（第 3 章的规则）。

**`val s : student = parseStudent line` 这个标注也不是装饰。** 它让 `#name s` 里的 `#name` 有确定的记录类型可查。**没有它，`#name` 是个「弹性记录选择子」**，编译器不知道 `s` 有哪些字段，会报 `unresolved flex record`。**这是 SML 记录访问的一个已知痛点**（第 6 章讲过），`type` 别名 + 标注是标准解法。

## 24.5 逐科统计：`mapPartial` 一步完成「取值 + 丢 NONE」

```sml
fun valuesOf (sel : student -> int option) (ss : student list) =
    List.mapPartial sel ss

fun meanOfInts (vs : int list) =
    if null vs then 0.0
    else Real.fromInt (List.foldl (op +) 0 vs) / Real.fromInt (length vs)

fun subjectLine (label, vs) =
    if null vs then label ^ " n=0 (all missing)"
    else StringCvt.padRight #" " 8 label
         ^ " n=" ^ Int.toString (length vs)
         ^ " min=" ^ Int.toString (List.foldl Int.min (hd vs) vs)
         ^ " max=" ^ Int.toString (List.foldl Int.max (hd vs) vs)
         ^ " mean=" ^ Real.fmt (StringCvt.FIX (SOME 4)) (meanOfInts vs)
```

```
4) per-subject (missing values excluded)
   math     n=4 min=60 max=90 mean=77.5000
   english  n=4 min=65 max=91 mean=79.7500
```

**`List.mapPartial` 是这一节的关键工具。** 它的签名是 `('a -> 'b option) -> 'a list -> 'b list`：**对每个元素求值，是 `SOME` 就留下，是 `NONE` 就丢掉。**

```sml
fun valuesOf (sel : student -> int option) (ss : student list) = List.mapPartial sel ss

val mathVs = valuesOf (fn (s : student) => #math s) students
val engVs  = valuesOf (fn (s : student) => #english s) students
```

**一行就完成了「把每人的数学成绩取出来，缺考的去掉」。** 换成 `filter` + `map` 要写两遍遍历：

```sml
(* 等价但啰嗦的写法 *)
val mathVs = List.map valOf (List.filter (fn s => Option.isSome (#math s)) students)
```

`mapPartial` 一次遍历，而且**不需要 `valOf`**（`valOf` 是部分函数，用错了会抛 `Option` 异常）。**「过滤 + 解包」的组合一律优先用 `mapPartial`。**

**统计的四个数：**

- **`n=4`（不是 5）** —— 缺考的被 `mapPartial` 丢掉了。这就是「缺失值不参与统计」的实现方式。
- **`min`/`max` 用 `foldl Int.min (hd vs) vs`** —— 第 19 章的老手法，初值取第一个元素。**这里 `vs` 非空是 `if null vs` 分支保证的**，所以 `hd` 安全。
- **`mean` 用 `Real.fmt (FIX (SOME 4))`** —— 第 20 章讲过，FIX ≤ 16 位是可移植的。这里用 4 位，输出 `77.5000`。
- **`padRight #" " 8` 对齐标签** —— 第 22 章讲过，`math` 和 `english` 都补到 8 宽，后面的数字列自然对齐。

**`meanOfInts` 的 `if null vs then 0.0`** 是个防御分支。数学上「空集的平均」是未定义的，返回 0.0 是个约定。**更好的设计是返回 `real option`**，让调用方决定怎么显示 —— `subjectLine` 里那个 `if null vs then label ^ " n=0 (all missing)"` 分支其实就是这么用的，所以这里返回 0.0 也行。**注意 `0.0` 而不是 `0`** —— 显式写小数点，因为返回类型是 `real`，写 `0` 会类型错。

## 24.6 排名：缺考不拉低均分，并列按姓名

```sml
fun subjectsOf (s : student) =
    (case #math s of NONE => [] | SOME v => [v])
    @ (case #english s of NONE => [] | SOME v => [v])

fun scoreOf (s : student) =
    let
        val vs = subjectsOf s
    in
        if null vs then 0.0 else meanOfInts vs
    end
```

**`scoreOf` 是「有效科目均分」**：有成绩的科目才进平均。所以：

- **dave** 只有英语 78 → 均分 **78.0**（不是 `(0+78)/2 = 39`）
- **bob** 只有数学 72 → 均分 **72.0**

**这就是「缺考不算零分」的语义。** 如果用 `int` + 0 表示缺考，dave 会被算成 39 分，排名完全错掉。**数据模型的正确性直接决定了业务逻辑的正确性。**

`subjectsOf` 用 `case ... @ case ...` 把两个 `option` 转成列表再拼接。**每个 `case` 的两个分支都返回 `int list`**（`[]` 或 `[v]`），所以 `@` 的类型没问题。

**`case` 表达式加括号是必要的**：`(case ... end) @ (case ... end)` —— 不加括号的话 `@` 会被解析进 `case` 的分支里。

排序：

```sml
fun rank (ss : student list) =
    let
        fun better (a : student, b : student) =
            if scoreOf a > scoreOf b then true
            else if scoreOf a < scoreOf b then false
            else #name a < #name b

        fun ins (x, []) = [x]
          | ins (x, y :: ys) = if better (x, y) then x :: y :: ys else y :: ins (x, ys)
    in
        List.foldl (fn (x, acc) => ins (x, acc)) [] ss
    end
```

**`better` 是个严格弱序**，所以插入排序能给出确定的结果：

1. 先比均分，高的在前
2. **均分相同就比姓名，字典序小的在前**

**第二条是关键。** 如果没有它，相同均分的两个学生顺序就取决于输入顺序，而输入顺序又取决于…… 幸好这里是写死的，但**并列打破规则（tie-breaking）是排序里必须明确的事**。示例的注释直接写明了：「ties by name」。

**`#name a < #name b` 是字符串比较**（字典序）。这里类型是确定的（`#name` 从 `student` 记录取，是 `string`），所以不会有 `polyEqual` 问题。

```
5) ranking by average of available subjects (ties by name)
   1. carol  89.5000  (math 88, english 91)
   2. alice  87.5000  (math 90, english 85)
   3. dave   78.0000  (math -, english 78)
   4. bob    72.0000  (math 72, english -)
   5. erin   62.5000  (math 60, english 65)
```

**结果可以手工核对**：

| 名次 | 姓名 | 均分 | 计算 |
|---|---|---|---|
| 1 | carol | 89.5000 | (88+91)/2 |
| 2 | alice | 87.5000 | (90+85)/2 |
| 3 | dave | 78.0000 | 78/1（只有英语） |
| 4 | bob | 72.0000 | 72/1（只有数学） |
| 5 | erin | 62.5000 | (60+65)/2 |

**缺考的两位排在中间而不是垫底** —— 因为 78 和 72 本来就比 erin 的 62.5 高。这正是「缺考不算零分」的语义带来的结果。

**注意 `-` 表示缺考**：

```sml
fun optStr NONE = "-"
  | optStr (SOME v) = Int.toString v
```

**两个子句，`NONE` 先匹配。** 输出 `(math -, english 78)` 一眼能看出谁缺了什么。

`numberFrom` 给行编号：

```sml
fun numberFrom (i, []) = []
  | numberFrom (i, s :: rest) = rankLine (i, s) :: numberFrom (i + 1, rest)
```

**给列表编号的标准手法：把序号作为递归参数传下去**，而不是 `map` 加个 `ref` 计数器，也不是 `List.mapi`（SML 没有 `mapi`）。

## 24.7 最小二乘拟合：只用两科齐全的行

```sml
fun completePairs (ss : student list) =
    List.mapPartial
        (fn (s : student) =>
            case (#math s, #english s) of
                (SOME m, SOME e) => SOME (Real.fromInt m, Real.fromInt e)
              | _ => NONE)
        ss
```

**又是一次 `mapPartial`。** 这次是把 `student list` 变成 `(real * real) list`，**只保留两科都有的人**。

**注意 `case (#math s, #english s) of (SOME m, SOME e) => ...`** —— **两个 `option` 组成一个元组，然后一个 `case` 同时解包两个**。这是 SML 里处理多个「可能失败」的值最简洁的写法。`-` 分支把它变成 `NONE`，于是 `mapPartial` 丢掉它。

```sml
fun linearFit (pts : (real * real) list) =
    let
        val mx = meanOfReals (map (fn (x, _) => x) pts)
        val my = meanOfReals (map (fn (_, y) => y) pts)
        val sxx = List.foldl (fn ((x, _), acc) => acc + (x - mx) * (x - mx)) 0.0 pts
        val sxy = List.foldl (fn ((x, y), acc) => acc + (x - mx) * (y - my)) 0.0 pts
        val m = sxy / sxx
    in
        (m, my - m * mx)
    end
```

**这是最小二乘的标准公式**（用均值中心化的形式，数值上比原始公式稳定得多）：

$$m = \frac{\sum (x - \bar x)(y - \bar y)}{\sum (x - \bar x)^2}, \qquad b = \bar y - m\bar x$$

**注意 `fn (x, _) => x` 里那个 `_`**：取第一个分量，忽略第二个。这是「记录选择子 `#1` 的替代品」—— 第 16 章踩过 `map #1 xs` 报 `unresolved flex record` 的坑，**写成 `fn (x, _) => x` 就没事**。

```
6) linear fit on the 3 complete rows
   english = 0.7796 * math + 18.4834
```

**「3 complete rows」**：5 个学生里只有 alice / carol / erin 两科都有。**拟合只用这 3 行** —— 这是 `completePairs` 的直接结果，也是数据处理里必须明确的规则：「缺失值不参与拟合，不补零、不插值」。

`meanOfReals` 和 `meanOfInts` 是两个不同的函数（一个吃 `real list`，一个吃 `int list`），**SML 没有隐式转换**，所以得写两遍。这是 SML 数值代码的常态 —— 换来的是「每一处精度转换都看得见」。

## 24.8 组装报告、写文件、再读回来验证

```sml
val reportLines =
    ["student report",
     "-- per-subject (missing values excluded) --",
     subjectLine ("math", mathVs),
     subjectLine ("english", engVs),
     "-- ranking by average of available subjects --"]
    @ rankLines
    @ ["-- linear fit on complete rows --",
       "english = " ^ fx slope ^ " * math + " ^ fx intercept,
       "based on " ^ Int.toString (length pairs) ^ " students with both scores"]

val reportOut = TextIO.openOut reportPath
val _ = List.app (fn l => TextIO.output (reportOut, l ^ "\n")) reportLines
val _ = TextIO.closeOut reportOut

val back = splitLines (readText reportPath)
```

**报告是「先构造一个 `string list`，再一次性写出去」。** 这比「边算边写」好得多，因为：

1. **报告内容可以在内存里检查**（比如算行数）
2. **写文件只有一处**，不会漏掉 `closeOut`
3. **可以重复写**（写两次得到两个文件）

**`List.app (fn l => output (out, l ^ "\n")) reportLines`** 是「把列表逐行写出」的惯用法。`List.app` 就是 `map` 的 `unit` 版本 —— 丢弃返回值，只为副作用。

**然后是关键的一步：把文件读回来验证。**

```sml
val _ = say ("   written " ^ Int.toString (length reportLines)
             ^ " lines, re-read " ^ Int.toString (length back)
             ^ ", identical = " ^ Bool.toString (back = reportLines))
val _ = say ("   first line preserved = " ^ Bool.toString (hd back = hd reportLines))
```

```
   written 13 lines, re-read 13, identical = true
   first line preserved = true
```

**`back = reportLines` 是列表相等性比较** —— SML 的 `=` 对列表做**结构相等**（逐元素递归比较），所以这一行真的在验证「写出的内容读回来完全一样」。

**这是「写入即验证」的经典手法（round-trip test）**：写文件 → 读回来 → 和内存里的原件比对。它一次能抓到一堆问题：编码不对、换行符处理错、少写了最后一行、多写了空行、`openOut` 没真的截断……

**`first line preserved` 这一行是额外的**：单独确认第一行没被吃掉。为什么需要？因为「总行数对」不代表「内容对」（虽然上面的 `identical` 已经更强了）。**这是示例在演示「断言要具体」** —— 失败时要能立刻定位到是哪一行出问题。

**注意 `"identical = true"` 里没有用 `if` 决定是否报错。** 报告写错了也照样打印 `false`，然后示例继续跑完。**为什么？** 因为示例的任务是「演示流程」，而判定交给验证脚本（`identical = false` 这种输出在三通道下仍然是一致的，所以不会让比对失败）。**在真实项目里，这里应该抛异常或者设退出码。**

## 24.9 清理：`build/` 里不留痕

```sml
val _ = OS.FileSys.remove csvPath
val _ = OS.FileSys.remove reportPath
val _ = say ("8) cleanup -> input exists = " ^ Bool.toString (OS.FileSys.access (csvPath, []))
             ^ ", report exists = " ^ Bool.toString (OS.FileSys.access (reportPath, [])))
```

```
8) cleanup -> input exists = false, report exists = false
```

**和 22.10 一样的规矩**：删掉自己造的所有文件，然后**把删除结果打印出来当断言**。

**为什么示例非要自己删自己的输入文件？** 因为这个 CSV 是示例自己生成的 —— **它是临时文件，不是用户数据**。区分这两者很重要：

| 类型 | 处理 |
|---|---|
| 示例自己生成的临时文件（`sml-report-input.csv`） | 必须删 |
| 用户提供的输入 | 绝对不能删 |
| 系统路径（`/tmp` 之外的） | 绝对不能碰 |

**这条边界在多通道验证下尤其重要**：`run-all.sh` 会把工作目录切到 `build/`，29 个示例 × 3 个通道 = 87 次运行。任何一个示例漏删文件，`build/` 就会积累垃圾，而且会影响其他示例的行为（目录遍历、同名文件覆盖）。

## 24.10 这个项目用到了哪些章的东西

值得回头数一遍 —— 如果前 23 章的每一块都能在这里找到位置，说明这些零件确实是真实需要的：

| 用到的章 | 在这个项目里的位置 |
|---|---|
| 第 3–6 章（声明/类型/表达式/记录） | `type student`、记录选择子、`#name s` 的类型标注 |
| 第 7 章（模式匹配） | `case fs of [n,m,e] => ...`、`NONE`/`SOME` 分支 |
| 第 8 章（列表） | `map`、`filter`、`foldl`、`mapPartial`、`List.app` |
| 第 9 章（datatype） | `option` 的使用（`int option` 表示缺失） |
| 第 10 章（字符串） | `String.fields` 切 CSV、`StringCvt.padRight` 对齐、`^` 拼接 |
| 第 11 章（递归） | `numberFrom` 的带序号递归 |
| 第 12 章（异常） | `raise Fail` + `handle` 接住坏行 |
| 第 13 章（高阶函数） | `fn (s : student) => #math s`、`List.mapPartial sel` |
| 第 18 章（可变状态） | （本节没用，但 `writeText` 里的 `let` 顺序执行是同一机制） |
| 第 19 章（算法） | 插入排序做排名、`foldl` 求 min/max/sum |
| 第 20 章（数值） | `Real.fromInt`、`Real.fmt (FIX (SOME 4))`、最小二乘 |
| 第 21 章（解析） | `fields` vs `tokens`、`Int.fromString` 接受空串/前缀 |
| 第 22 章（I/O） | `openOut`/`output`/`closeOut`、`readAll`、`splitLines`、`OS.FileSys` |

**没有一块是多余的。** 这就是为什么教程的章节顺序是这么排的：每一章解决一类问题，而综合项目按需取用。

## 24.11 如果要做成生产工具，还差什么

示例刻意停在「能跑、能对、能验证」的位置。要变成真正能用的命令行工具，至少还得加：

**（1）命令行参数。** SML 有 `CommandLine.arguments ()`，返回 `string list`。可以读输入文件路径、输出路径。

**（2）退出码。** 用 `OS.Process.exit` 区分「成功」「输入格式错」「I/O 错」。注意 22.9 讲的：`status` 是抽象类型，只能 `isSuccess`；退出码的正确设定方式是让最外层（MLton 编译出的可执行文件）通过 `exit` 返回。

**（3）真正的错误处理。** 现在是 `raise Fail` + `handle` 打印。生产代码应该：

```sml
datatype err = BadRow of int * string | IoError of string

fun run () =
    ...
in
    (run (); OS.Process.success)
    handle
        BadRow (n, msg) => (TextIO.output (TextIO.stdErr, "line " ^ Int.toString n ^ ": " ^ msg ^ "\n"); OS.Process.failure)
      | IoError msg => (TextIO.output (TextIO.stdErr, msg ^ "\n"); OS.Process.failure)
```

**用自定义 `datatype` 而不是 `Fail` 的字符串**，这样错误可以携带结构化信息（行号、原始行内容），而且**不会被任意 `handle` 误捕**。

**（4）大文件支持。** 现在是 `inputAll` 整个读进来。生产工具应该用 `inputLine` 流式处理，逐行解析逐行统计。

**（5）SML/NJ 的可执行文件。** SML/NJ 是交互式系统，`use` 一个文件就跑了。要做出独立的可执行文件，得用 `SMLofNJ.exportFn`：

```sml
val _ = SMLofNJ.exportFn ("myapp", main)
```

或者用 MLton 编译（**这是 MLton 的主要用途**）：

```bash
mlton -output myapp myapp.sml
./myapp
```

**MLton 生成的是真正的原生可执行文件**，不依赖 SML 运行时（静态链接）。**这就是三套实现的另一个分工：SML/NJ 适合交互开发和调试，MLton 适合发布独立二进制，Poly/ML 适合嵌入到别的程序里当脚本引擎。**

**（6）单元测试。** 用第 23 章的模式，把 `parseStudent`、`scoreOf`、`linearFit` 都测一遍。

**本书到此为止的所有内容，加上这六条，就是一套完整的 SML 工程能力。**
