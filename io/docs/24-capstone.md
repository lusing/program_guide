# 24 · 实战：一个完整的 Io 程序

> 对应示例：[`examples/24_capstone/24_capstone.io`](../examples/24_capstone/24_capstone.io)

前面 23 章都是「一个知识点 + 一个最小示例」。这一章换一种方式：**不引入任何新语法**，
拿全部旧零件装一个能用的东西——一个访问日志分析器。

它要处理的东西覆盖了 Io 日常写代码的全部动作：

| 动作 | 用到哪一章 |
|---|---|
| 定义一份可克隆的记录模板 | 07 原型 / 08 方法 |
| 按空白切字段、对齐渲染表格 | 04 序列 / 16 文本处理 |
| 用 `Map` 计数、用 `List` 排序 | 09 / 10 / 12 |
| 把「怎么算」当参数传进去 | 11 块 |
| 一条坏行不许毁掉整批 | 13 异常 |
| 报告落盘 + 序列化往返校验 | 14 文件 / 21 序列化 |
| `System args` 分派子命令 | 15 系统 |
| 结尾的自检 | 20 测试 |

日志样本内嵌在源码里，不依赖任何外部文件：

```text
2026-09-21T10:00:01 GET /index 200 12
…（共 12 行，其中 3 行是坏的）
```

## 24.1 解析：一条记录就是一个 clone 出来的原型

```text
-- 24.1 解析：一条记录就是一个 clone 出来的原型
第一条记录 = GET /index -> 200
one type = Record
one path = /index
one status = 200
one ms = 12
覆盖过 asString 的拼接 = 记录：GET /index -> 200
"abc" asNumber = nan
-- 它 isNan 吗 = true
-- nan < 100 = true
-- nan > 599 = false
-- nan >= 100 and(nan <= 599) = false
坏行 1 的消息 = 字段数不对（1），期望 5
坏行 2 的消息 = 状态码不成样子：abc
坏行 3 的消息 = 状态码不成样子：999
```

```io
Record := Object clone do(
    ts := ""
    verb := ""
    path := ""
    status := 0
    ms := 0
    parse := method(line,
        f := line split(" ")
        if(f size != 5, Exception raise("字段数不对（" .. f size asString .. "），期望 5"))
        st := f at(3) asNumber
        if(st < 100 or(st > 599), Exception raise("状态码不成样子：" .. f at(3)))
        r := Record clone
        r ts = f at(0)
        r verb = f at(1)
        r path = f at(2)
        r status = st
        r ms = f at(4) asNumber
        r
    )
    asString := method(verb .. " " .. path .. " -> " .. status asString)
)
```

四个设计决定，每一个都能在前面的章节里找到出处：

- **槽名避开 Io 的核心消息名**：不叫 `method`、不叫 `time`、不叫 `at`。
  在 Io 里槽名就是消息名，用 `method` 当槽名会把创建方法的消息遮住。
- **`parse` 是「工厂」而不是构造函数**：Io 没有构造函数，`Record clone` 之后
  逐个 `=` 赋值，最后把对象自己返回出来（方法体最后一个表达式的值就是返回值）。
- **`split(" ")` 必须显式写分隔符**：不传分隔符的 `split` 是按字节扫空白的，
  非 ASCII 码位只要低位字节撞上 `0x0A`/`0x0D`/`0x20` 就会被切开（第 16 章 16.4）。
  这个项目里全是中文日志行，不写分隔符必炸。
- **`asNumber` 转不动给的是 `nan`，不是 `0`**：`"abc" asNumber` 得 `nan`
  （`isNan` 为真），而 `nan` 参与比较永远走同一边——实测 `nan < 100` 是 `true`、
  `nan > 599` 是 `false`。所以**两边都要判**：写成 `st < 100 or(st > 599)`
  时坏数据被 `nan < 100` 拦住；如果偷懒只写单边 `if(st > 599, 报错)`，
  `nan > 599` 是 `false`，「状态码 abc」就会一声不响地混进统计。

> **为什么重要**：Io 里没有「类」，`Record` 只是一份能被克隆的模板。
> 所以「数据模型」和「工具函数」可以放在同一个对象里——`parse` 就挂在 `Record`
> 自己身上，调用点是 `Record parse(line)`，读起来和普通类方法一样。

## 24.2 批量解析：坏行进「拒收单」，好行进结果集

```text
-- 24.2 批量解析：坏行进「拒收单」，好行进结果集
总行数 = 12
收下的行数 = 9
拒收的行数 = 3
拒收的第 1 条原因 = 字段数不对（1），期望 5
拒收的第 2 条原因 = 状态码不成样子：abc
拒收的第 3 条原因 = 状态码不成样子：999
```

```io
parseAll := method(lines,
    good := List clone
    bad := List clone
    lines foreach(line,
        e := try(good append(Record parse(line)))
        if(e != nil, bad append(list(line, e error)))
    )
    Object clone lexicalDo(records := good; rejected := bad)
)
```

这一段把 13 章和 07 章的坑同时踩到了两处：

- **判据只能是 `e != nil`**：`try` 成功时返回 `nil`、失败时返回异常对象，
  它**永远不返回表达式的值**。所以不能写「值不为 nil 就说明成功」。
- **收尾必须用 `lexicalDo` 而不是 `do`**：`do(...)` 的作用域链只到接收者和
  `Lobby`，**看不到本方法的局部槽** `good` / `bad`，会直接报
  `Object does not respond to 'good'`。这一条在 07 章 7.10 里专门拆开讲过。

坏行不是被丢弃，而是带着**原因**进了拒收单（`list(原始行, 错误消息)`）。
这在真实工具里很重要：用户需要知道哪一行坏了、坏在哪。

## 24.3 聚合：Map 计数，但顺序不可依赖

```text
-- 24.3 聚合：Map 计数，但顺序不可依赖
不同路径数 = 5
不同状态码数 = 5
路径计数（排序后） = /about=1 /index=4 /item=1 /login=2 /missing=1
状态码计数（排序后） = 200=5 302=1 403=1 404=1 500=1
Map 默认 asString 会带地址，所以永远不直接打它 = true
路径排行 = /index(4) /login(2) /about(1) /item(1) /missing(1)
状态码排行 = 200(5) 302(1) 403(1) 404(1) 500(1)
```

```io
countBy := method(records, keyBlock,
    m := Map clone
    records foreach(r,
        k := keyBlock call(r)
        if(m hasKey(k), m atPut(k, m at(k) + 1), m atPut(k, 1))
    )
    m
)
byPath := countBy(parsed records, block(r, r path))

rank := method(m,
    pairs := m keys sort map(k, list(k, m at(k)))
    pairs sortBy(block(x, y,
        if(x at(1) != y at(1), x at(1) > y at(1), x at(0) < y at(0))
    )
)
)
```

三条纪律：

1. **计数用 `hasKey` 判断再 `atPut`**：`Map at` 缺键不报错而是给 `nil`，
   直接 `m atPut(k, m at(k) + 1)` 会变成 `nil + 1`。
2. **`keys` 的顺序不可依赖**：打印前一律 `sort`。而且「排行」这种有序需求
   要自己写比较器——`sortBy` 收的是**一个两参块**（写成 `sortBy(a, b, 体)`
   会报 `Object does not respond to 'a'`）。
3. **比较器要写全序**：先比计数（降序），计数相同再比键（升序）。
   只比计数的话，`/about` 和 `/login` 都是 2 次，谁在前就成了不确定行为。
   这一条同时保证了输出**逐字节稳定**——本仓库的回归脚本会连跑两遍比对。

> **为什么重要**：`Map` 的迭代顺序在 Io 里没有任何承诺。
> 「打印一张统计表」这种看似无害的操作，只要忘了 `sort`，就会变成
> 一个偶发失败、在别人机器上复现不了的 bug。

## 24.4 渲染：用对齐拼出确定性表格

```text
  路径                  次数    
  --------------------------
  /index              4     
  /login              2     
  /about              1     
  /item               1     
  /missing            1     
表格行数（表头 + 分隔线 + 5 行数据） = 7
```

```io
// 两参形式的绑定顺序是「先下标、后值」：map(i, v, 体) —— 和大多数语言相反！
tableRow := method(cols, widths,
    cols map(i, v, v asString alignLeft(widths at(i))) join("")
)
pathTable := method(m,
    header := tableRow(list("路径", "次数"), list(20, 6))
    rule := "-" repeated(26)
    body := rank(m) map(p, tableRow(list(p at(0), p at(1)), list(20, 6)))
    lines := list(header, rule)
    body foreach(l, lines append(l))
    lines
)
```

这一节的坑全在参数绑定上。Io 的 `List` 迭代方法有**两种形状**：

| 写法 | 名字绑到 |
|---|---|
| `map(v, 体)` | `v` = **元素值** |
| `map(i, v, 体)` | `i` = **下标**，`v` = **元素值** |

**两参形式是「先下标后值」，和 Python / Ruby / JS 的习惯相反。** 写反了不会
当场报错，只会在后面用 `at(i)` 的时候炸成
`argument 0 to method 'at' must be a Number, not a 'Sequence'`——
报错点离出错点很远。`foreach`、`select`、`detect`、`map` 全部遵守这个约定。

另外 `alignLeft(n)` 是**按码点**补齐的，所以中文列宽靠码点算（`路径` 算 2 格）。
这正是想要的表格效果，但如果你的终端把汉字渲染成两倍宽，对不齐是终端的事，
不是 `alignLeft` 的事。

> **为什么重要**：Io 的集合协议把「下标」放在参数表的**第一位**。
> 记住这一条，能少踩一大类「报错信息完全指错方向」的坑。

## 24.5 汇总指标：算平均数与最大值

```text
-- 24.5 汇总指标：算平均数与最大值
总耗时（ms） = 484
平均耗时（ms，整数） = 53
最慢的一条（ms） = 240
最慢的那条是谁 = /index
耗时 ≥ 90ms 的条数 = 2
4xx/5xx 条数 = 3
```

```io
totalMs := 0
maxMs := 0
maxMsPath := ""
parsed records foreach(r,
    totalMs = totalMs + r ms
    if(r ms > maxMs, maxMs = r ms; maxMsPath = r path)
)
slowCount := parsed records select(r, r ms >= 90) size
errorCount := parsed records select(r, r status >= 400) size
show("平均耗时（ms，整数）", (totalMs / parsed records size) floor)
```

两个细节：

- **累积要用 `=` 不能 `:=`**：`totalMs = totalMs + r ms` 改的是外层真正的那个槽
  （写在 11.5 里）。用 `:=` 会在块里造一个同名临时槽，外面的 `totalMs` 永远是 0。
- **`(totalMs / n) floor` 的括号不能省**：`totalMs / parsed records size floor`
  会被解析成 `totalMs / ((parsed records) size floor)`，也就是除以 9，
  得到 `53.7777777777777786` 而不是 `53`。Io 的二元运算符优先级只有一张小表，
  想清楚结合顺序就别怕多打括号。

## 24.6 持久化：serialized 落盘、读回来、往返校验

```text
-- 24.6 持久化：serialized 落盘、读回来、往返校验
落盘字节数 > 0 = true
落盘文件里有地址吗 = false
读回来的 type = Map
读回来的 total = 9
读回来的 ranking = list("/index", "/login", "/about", "/item", "/missing")
临时文件已经删掉 = true
```

```io
reportPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch24_report.io")
reportFile := File with(reportPath)
reportFile remove
// 又一次 asUTF8：setContents 写的是字符串的内部表示，含非 ASCII 会变 4 字节一码点
reportFile setContents(report serialized asUTF8)
loaded := doString(reportFile contents)
```

- **`serialized` 出来的是可回读的 Io 源码**：`Map clone do(atPut("total", 9);…)`，
  里面**不含地址**，所以可以放心进日志、进 diff。配合 `doString` 就完成了往返。
- **`asUTF8` 不是可选的**：`File setContents` 倒的是字符串的**内部表示**，
  含中文的串内部是 UCS4，直接写出来是每码点 4 字节的垃圾（14.2 有 `od -c` 证据）。
- **读回来的是新的 `Map`**，值相等但对象不同；嵌套的 `Map` / `List` 也一并还原。

> **为什么重要**：Io 的序列化格式就是 Io 源码，这带来一个很实用的后果——
> 落盘的数据可以直接被人阅读和手改，也可以用 `doString` 在**受限**场景下当配置用。
> （注意是「受限」：`doString` 会执行任意代码，别拿它读不可信的输入。）

## 24.7 命令行入口：System args 与子命令分派

```text
-- 24.7 命令行入口：System args 与子命令分派
System args size = 1
args[0] 是脚本自己 = true
System launchScript 就是 args[0] = true
子命令 analyze 的 total = 9
子命令 reject 的结果 = 3
子命令 status 的结果 = 200,302,403,404,500
未知子命令的报错 = 未知子命令：nope
```

```io
show("System args size", System args size)
show("args[0] 是脚本自己", System args at(0) endsWithSeq("24_capstone.io"))

runCommand := method(name, lines,
    if(name == "analyze", return analyze(lines))
    if(name == "reject", return analyze(lines) rejected)
    if(name == "status", return analyze(lines) byStatus keys sort join(","))
    Exception raise("未知子命令：" .. name)
)
```

- **`System args` 是 C 风格 argv**：`args[0]` 是脚本路径（和 `System launchScript`
  同一个值），用户参数从 `args[1]` 开始。所以「有没有子命令」要判 `size > 1`。
- **分派就是一串 `if` + 提前 `return`**：Io 没有 `case`/`switch` 语句，
  `if` 是方法、`return` 是消息（08.7）。
- **未知子命令要抛异常而不是打印用法后静默返回**：因为 Io 的退出码默认是 0，
  静默返回会让 shell 层的调用者以为成功了（13.3）。真要做 CLI，
  未知参数的分支末尾应该 `System exit(2)`。

## 24.8 端到端：一份完整报告

```text
== 访问日志速览 ==
收下 9 行，拒收 3 行
  HTTP 200  5 次
  HTTP 302  1 次
  HTTP 403  1 次
  HTTP 404  1 次
  HTTP 500  1 次
```

```io
emitReport := method(lines, title,
    p := parseAll(lines)
    out := List clone
    out append("== " .. title .. " ==")
    out append("收下 " .. p records size asString .. " 行，拒收 " .. p rejected size asString .. " 行")
    byS := countBy(p records, block(r, r status asString))
    rank(byS) foreach(item,
        out append("  HTTP " .. item at(0) .. "  " .. item at(1) asString .. " 次")
    )
    out
)
```

把整个流程串起来之后，这个程序就只剩四步：**解析 → 聚合 → 排序 → 渲染**。
每一步都是纯函数（输入一个 `List`，输出一个 `List` 或 `Map`），
所以每一步都能单独断言——这正是 24 章末尾那 40 多条 `chk` 在做的事。

## 24.9 坑位清单

1. **用 `do(...)` 把方法局部变量塞进新对象** → `do` 的作用域只到接收者和 `Lobby`，报 `Object does not respond to 'x'`；工厂方法要用 `lexicalDo`，或对空对象 `setSlot`。
2. **`try` 的结果当返回值用** → `try` 成功也返回 `nil`，唯一判据是 `e != nil`，要值就把结果写进外层槽。
3. **`List` 两参迭代写成 `map(v, i, 体)`** → 绑定顺序是「先下标后值」，`map(i, v, 体)` 才对；写反的报错是 `at` 的参数类型不对，离出错点很远。
4. **不传分隔符的 `split`** → 按字节扫空白，中文日志行会被莫名其妙切开；一律写 `split(" ")`。
5. **`asNumber` 的结果不校验** → `"abc" asNumber` 给 `nan`（不是 `0`），而 `nan` 与任何数比较恒走同一边；只写单边 `if(st > 599)` 拦不住它，必须双边兜范围。
6. **`Map at` 缺键给 `nil`** → 计数循环要 `hasKey` 分支，否则 `nil + 1` 直接抛异常。
7. **直接打印 `Map`** → `Map asString` 是带 `0x` 地址的摘要；要输出就 `keys sort` 后自己拼。
8. **`sortBy` 收的不是两参块** → 必须 `sortBy(block(a, b, …))`；写 `sortBy(a, b, 体)` 会报 `Object does not respond to 'a'`。**为什么一定是 `block` 而不是 `method`**：`method` 造的块 `isActivatable = true`，一进形参（形参就是槽）就被零参调用（11.3.1）。
9. **`File setContents` 忘了 `asUTF8`** → 含非 ASCII 的串内部是 UCS4，落盘变成 4 字节一码点的垃圾，读回来全错。
10. **累积变量在块里用 `:=`** → 那是在块里造了个临时槽，外层永远是初值；要改外层必须 `=`。
---

上一章：[23 · 外部函数接口](23-ffi.md)
