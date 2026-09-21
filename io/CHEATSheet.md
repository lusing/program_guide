# Io 语法速查表

语法速查 + 全部 **240 条实测坑位**索引。详细讲解见对应章（表中 `N.M` = 第 N 章 M 节）。

> 本机 Io 是**从源码编译**的（CMake + `build.sh`），两条通道 `io`（动态库）与 `io_static`（静态）。
> 表中所有结论都在**两条通道上跑过、逐字节一致**，不是从文档抄来的。
> 凡是标「实测」的数字，都是本机跑出来的，不是猜的。

---

## 1. 命令速查

```bash
io script.io args...          # 跑脚本（io / io_static 两条通道）
io -e 'writeln("hi")'         # 一行代码（注意：-e 的代码里不能有换行）
io                            # 无参进入 REPL
io -h                         # 帮助

# 本机安装位置
/Users/xulun/.workbuddy/binaries/io/bin/io
/Users/xulun/.workbuddy/binaries/io/bin/io_static

# 环境变量
IO_BIN=/path/to/io_static     # 回归脚本优先读它

# 超时（macOS 没自带 timeout；MacPorts 的 gtimeout 才是对的）
gtimeout --foreground -s KILL 10 io script.io
#   ^^^^^^^^^^^^ 不带 --foreground 会连自己的进程组一起杀，父进程 stderr 多出 "Killed: 9"
```

验证入口（等价两份，判定逐条一致）：

```bash
bash run-all.sh              # shell 入口，跑全部示例
bash run-all.sh 07 13 24     # 只跑指定章
pwsh -File build.ps1         # PowerShell 入口
pwsh -File build.ps1 -Example 07
```

判定七条：退出码 0 / stderr 为空 / 起止标记齐 / 区间非空且无控制字符 / 无溃逃痕迹 /
**跨通道区间逐字节一致** / 同通道连跑两次一致。另有观察项（`observe_*.io`）只要求跑到结束标记，不参与字节比对。

---

## 2. 心智模型（01）

```io
1 + 2                    // 不是语法，是「把消息 + 发给 1」
1 + 2 * 3                // = 7     二元运算符左结合、同优先级
"abc" size               // = 3     一元消息优先级最高
list(1,2,3) at(0)        // = 1     关键字消息其次
if / while / for / return // 全是普通方法，不是关键字
```

| 三条模型 | 含义 |
|---|---|
| 一切皆对象 | 数字、字符串、方法、`nil`、消息本身都是对象 |
| 一切皆消息 | `for(i,1,3,…)` 是三个关键字实参，不是语法结构 |
| 消息可构造 | `Message fromString("1 + 2")` 可动态拼消息再发出去 |

消息形状与优先级（**与 Smalltalk 相反**）：一元 > 关键字（带参）> 二元运算符。

| 坑 | 解法 |
|---|---|
| 按 Smalltalk 的直觉写 `1 + 2 max(3)` | 先算 `1 + (2 max(3))`；要别的次序就加括号（06.2） |

---

## 3. 数值（03）

```io
7 / 2                    // 3.5    —— / 永远给浮点，整除要 floor
7 % 3                    // 1
(-7) % 3                 // -1     —— 余数跟被除数同号（C 的 %）
7 % (-3)                 // 1
2 ** 10                  // 1024   —— ** 是幂，不是异或
2.5 round                // 3      —— .5 一律远离零，不是银行家舍入
(-2.5) round             // -3
2.5 floor / 2.5 ceil     // 2 / 3
1 / 0                    // inf
0 / 0                    // nan
"abc" asNumber           // nan    —— 不是 0！
"abc" asNumber isNan     // true
255 toBase(16)           // "ff"
"ff" toBase(16)          // 0      —— toBase 是「把数转成串」，方向反了
255 asHex                // "ff"
Number constants         // pi / e / inf / nan 的对象

7 abs                    // 7
(-4) abs                 // 4
3 max(5) / 3 min(5)      // 5 / 3
```

| 坑 | 解法 |
|---|---|
| 以为 `7 / 2` 是 `3` | 整除写 `(7 / 2) floor`（03.1） |
| 以为 `round` 是银行家舍入 | `.5` 一律远离零：`2.5 round` = 3、`-2.5 round` = -3（03.7） |
| 用 `==` 检测 `nan` | 恒 false，用 `x isNan`（03.5） |
| 用 `==` 比较浮点 | `0.1 + 0.2` 打印与 `0.3` 相同却不相等（03.5） |
| 用 `toBase(16)` 拼定宽十六进制 | 方向是数→串，补零要自己写（03.7） |

---

## 4. 序列与文本（04 / 16）

```io
"hello" size              // 5      —— 码点个数
"中文" size               // 2      —— 码点
"中文" sizeInBytes        // 6      —— 内部字节
"中文" asUTF8 size        // 6      —— 落盘字节（UTF-8）
"中文" encoding           // "ucs4"
"中文" itemType           // "uint32"
"abc" encoding            // "ascii"
"abc" isMutable           // false  —— 字面量不可变；type 都是 Sequence
"abc" asMutable strip     // 就地方法必须先 asMutable
"abc" asMutable appendSeq("d")   // "abcd"

"hello" exSlice(0, 5)     // "hello"  —— [0,5)
"hello" slice(0, 5)       // 可用但打弃用警告 → 用 exSlice
"hello" findSeq("llo")    // 2
"hello" findSeq("zzz")    // nil      —— 不是 -1！
"hello" reverseFindSeq("l")       // 9
"hello" asUppercase       // "HELLO"
"ABC" asLowercase         // "abc"
"a b c" split(" ")        // list("a","b","c")
"a,b,,c" split(",")       // list("a","b","","c")   —— 空字段保留
list(1,2,3) join(",")     // "1,2,3"
"abcdef" at(1)            // 98      —— 是码点 Number
"abcdef" at(1) asCharacter// "b"
Sequence clone appendSeq("ab")   // 可变空串，累积用这个
```

**跨宽度比较是 16 章最容易上当的地方**：`type` 对两者都报 `Sequence`，
`encoding` / `itemType` 才看得出差别。两种宽度的序列做 `containsSeq` / `==` **不报错，只给错答案**。

| 坑 | 解法 |
|---|---|
| 在字面量上调 `strip`/`replaceSeq`/`appendSeq` | 抛 `'x' cannot be called on an immutable Sequence`，先 `asMutable`（04.2 / 16.1） |
| 拿 `size` 当字节数 | `size` 数码点、`sizeInBytes` 数内部字节、`asUTF8 size` 才是落盘字节（16.2） |
| 对含中文的字面量用 `#{}` 插值 | `"中文#{1+2}"` → `中文1`；带括号直接段错误 rc=139（16.5） |
| 无参 `split` 解析外部文本 | **按字节**扫空白：`"上" split` 得 `list("")`（低字节 0x0A）；一律写 `split(" ")`（16.4） |
| 用 `slice` | 打弃用警告污染 stderr，改 `exSlice`（04.4） |
| 以为 `findSeq` 找不到给 `-1` | 给 `nil`（04.6） |

---

## 5. 控制流（05）

```io
if(true, "a", "b")            // "a"
if(false, "a", "b")           // "b"
if(nil, "a", "b")             // "b"    —— nil 是假
if(false, "a")                // false  —— 不是 nil！
if(0, "t", "f")               // "t"    —— 只有 false 和 nil 是假

true  ifTrue("x") ifFalse("y")       // "x"
nil   ifNil("d")                     // "d"
nil   ifNilEval("d")                 // "d"
5     ifNonNilEval(9)                // 9      —— 方向与 ifNilEval 相反
3 switch(1,"one", 3,"three", "other")  // "three"
9 switch(1,"one", "other")             // "other"

s := 0; for(i, 1, 3, s = s + i)         // 6      —— 闭区间，循环 3 次
for(i, 1, 5, if(i == 3, continue); …)   // continue 跳过本轮
for(i, 1, 5, if(i == 3, break); …)      // break 退出循环
while(i < 3, i = i + 1; n = n + 1)
loop(break)                              // 无条件循环 + 出口
nil  and(true)   // false
nil  or(true)    // true
false and(true)  // false
false or(true)   // true
5 and(true)      // true     —— 落到 Object 上，走 method(v, v isTrue)
(Object clone) or(false)     // true  —— 普通对象 isTrue 是 true
(Object clone) not           // nil  —— 不是 false！
true not / nil not           // false / true
```

短路机制：`false` / `nil` 上的 `and` 是**值槽**（值为 `false`），实参消息**连求值都不会发生**；
落到 `Object` 才走真正的 `method(v, v isTrue)`。

| 坑 | 解法 |
|---|---|
| 把 `0` 当假 | 只有 `false` 和 `nil` 是假（05.1） |
| 以为 `if(false, x)` 返回 `nil` | 返回 `false`（05.3） |
| 给 `if` 的分支里放必炸的表达式 | 两个分支都会求值（不是短路），要惰性用块（05.4） |
| 写 `nil ifTrue(x)` 求默认值 | 只有 `True`/`False` 有 `ifTrue`，`nil` 上没有；用 `ifNil`（05.2） |
| 把 `for(j,1,3)` 当 C 的 `j < 3` | 上界是闭区间，循环 3 次（05.6） |
| 用 `loop` 却没写 `break` | 不会自己停，示例必须包超时（05.7） |
| 拿 `x not` 判断「对象为假」 | 普通对象取反给 `nil` 不给 `false`（05.10） |
| 以为 `and`/`or` 结构对称 | `nil and(x)` = false、`nil or(x)` = true，一侧是值槽一侧是方法（05.9） |

---

## 6. 消息与运算符（06）

```io
Message fromString("1 + 2 * 3")     // 看一段源码的解析树，调试利器
Message fromString("1 + 2 * 3") op  // 运算符名
"abc" print                          // 打接收者 "abc"
"abc" println                        // 打接收者 + 换行
writeln("a", 1 + 2)                  // 打参数，可多参 —— 输出统一用它
write("x")                           // 打参数不换行

OperatorTable addOperator("**", 11)  // 注册新运算符（只对新编译单元生效）
resend                               // 调父实现
super(MsgName)                       // 按名字调父实现
call message name                    // 被调用时的名字
call argCount                        // 实参个数（不是形参个数！）
call evalArgAt(0)                    // 逐个取实参（惰性）
call target / call sender
```

**优先级表**：一元 → `**`(11) → `*` `/` `%`(12) → `..`(12) → `+` `-`(13) → 比较(14~) → `and` → `or` → 赋值。
`..` 是**字符串拼接**，优先级与 `*` 同级（12），比 `+` 高。

| 坑 | 解法 |
|---|---|
| 以为 `1 + 2 max(3)` 是 `3` | Io 里一元/关键字优先级**高于**二元，先算 `2 max(3)`（06.1） |
| 把 `+` 当编译器内建 | 是 `Number` 上的普通方法，可覆盖（06.4） |
| 忘了 `..` 优先级是 12 | `"a" .. 1 + 2` 拼出 `"a3"`，不是 `"a12"`（06.5） |
| 写了 `addOperator` 就在同文件里用 | 只对**新编译单元**生效，同文件里会走样（06.6） |
| 以为 `call argCount` 是形参个数 | 是**实参**个数，形参要 `getSlot("f") argumentNames`（06.7） |
| 拿 `..` 拼未覆盖 `asString` 的对象 | 得到带 `0x` 地址的摘要（06.9） |

---

## 7. 原型与槽（07）

```io
o := Object clone
o x := 1                 // 定义：不存在也允许
o x = 2                  // 更新：不存在则抛 Slot x not found
o y ::= 0                // 定义 + 自动生成 setY
o setY(9)
o newSlot("z", 3)        // 显式造槽（也会生成 setZ），返回自身可链式
o removeSlot("z")

P := Object clone do(n := 7; twice := method(n * 2))
Q := P clone             // clone 复制槽、自动调 init（不想调用 cloneWithoutInit）
Q twice                  // 14
Q hasLocalSlot("n")      // false —— 槽长在 P 上
Q hasSlot("n")           // true  —— 沿 proto 链找得到
Q isKindOf(P)            // true
Q appendProto(Other)     // 追加 proto
Q setProto(Other)        // ⚠️ 替换，不是追加
Q protos                 // 打印会带地址，输出前先 map 成 name
Q slotNames sort         // ⚠️ 哈希序，断言前必须 sort
Q getSlot("twice")       // 绕过激活，拿方法本体（type = Block）
Object clone do(k := 1; m := 2)    // 多条槽定义用 ; 或换行
```

**`do(...)` 的作用域链只到「接收者 + Lobby」**，看不到定义它的那个方法的局部槽——
要读局部槽得用 `lexicalDo`。

| 坑 | 解法 |
|---|---|
| 把 `:=` / `=` / `::=` / `newSlot` 当成一回事 | 见上表，`=` 只更新、`::=`/`newSlot` 会配 setter（07.2） |
| 以为 `=` 会修改原型上的槽 | 更新只作用在最内层已有的槽上（07.3） |
| 用 `hasSlot` 判断「槽长在谁身上」 | 用 `hasLocalSlot`（07.3） |
| 以为 `clone` 只是复制 | 它还会调 `init`（07.6） |
| 直接打印 `slotNames` / `protos` | 哈希序 + 带地址；先 `sort` / 先 `map`（07.7） |
| 在 `do(...)` 里用逗号分隔多个槽定义 | **只有第一个实参被求值**，后面的静默丢掉（07.9） |
| 在 `do(...)` 里用外层方法的局部变量 | 报 `Object does not respond to 'x'`，改用 `lexicalDo`（07.10） |

---

## 8. 方法与块（08 / 11）

```io
f := method(a, b, a + b)
f(1, 2)                       // 3
(getSlot("f")) call(3, 4)     // 7      —— 拿本体再调
(getSlot("f")) argumentNames  // list("a", "b")   —— 是方法本体的槽
(method(a, a + 1)) call(41)   // 42     —— 内联方法必须显式 .call

var := method(call argCount)  // 变参：多出来的实参仍在 call 里
var(1, 2, 3)                  // 3

b := block(a, a + 1)          // block(...) 造的块 isActivatable = false
b call(1)                     // 2

mk := method(n, st := Object clone; st n := n; b := block(n * 2);
             b setScope(st); b)          // 闭包要自己 setScope
```

**`method` 与 `block` 的唯一差别**：`method(...)` 造的块 `isActivatable = true`，
**落进任何槽（包括形参）就立刻零参调用**；`block(...)` 造的不会。
所以「把一个函数当数据传」必须用 `block(...)`，或先装进 `List` / 用 `getSlot` 取。

| 坑 | 解法 |
|---|---|
| 调用时少传参数就以为会报错 | 缺的形参是 `nil`，不报错（08.1） |
| 写 `(method(...))(x)` 当立即调用 | 那是**两个相邻括号组**，方法被丢掉，结果是 `x` 自己；要 `.call(x)`（08.2） |
| 用 `method(a, b := 10, …)` 当默认参数 | `:=` 被当成第二个**形参名** `setSlot`；自己判 `nil`（08.3） |
| 想写变参却找不到 `*args` | `call argCount` / `call evalArgAt(i)`（08.5） |
| 在块里 `return` 以为只结束本次迭代 | `return` 直接离开**整个方法**，循环要用 `break`（08.7） |
| 直接把方法名当值传 | 读到就激活；要本体用 `getSlot("名字")`（08.8） |
| 把块存进槽后想「读出来看看」 | 读槽就是零参调用（11.3.1） |
| 在 `maker` 里 `n := 0` 再 `method(n = n + 1)` 造计数器 | 块的作用域是调用处的 Lobby，要先 `setScope`（11.6） |

---

## 9. 集合：List / Map / 迭代（09 / 10 / 12）

```io
l := list(3, 1, 2)
l sort / l reverse          // list(1,2,3) / list(3,2,1)
l map(v, v * 2)             // list(6,2,4)  —— 1 参形式：v 是元素
l map(i, v, i)              // list(0,1,2)  —— 2 参形式：先下标后值！
l select(v, v > 1)          // 筛选
l detect(v, v > 1)          // 2（首个命中）；找不到给 nil
l reduce(+)                 // 求和
l indexOf(2)                // 1；找不到给 nil
l slice(1, 3)               // 取一片
l at(-1)                    // 2 —— 支持负下标
l at(99)                    // nil —— 越界不报错
l append(4) / l appendSeq(list(...)) / l removeAt(0) / l pop
list(list(1,2), list(3)) flatten       // list(1,2,3)
list(1,2,3) sortBy(block(a, b, a > b))  // 两参排序必须 block(...)
list(...) foreach(v, …) / foreach(i, v, …)

m := Map clone
m atPut("a", 1)
m at("a")                   // 1
m at("zz")                  // nil —— 缺键不抛异常
m hasKey("zz")              // false
m keys sort / m values
m size / m removeAt("a")
m atIfAbsentPut("a", 99)    // 不覆盖已有值
m map(k, v, k .. "=" .. v)  // Map 的 map 是 3 参（键、值、体）
```

| 坑 | 解法 |
|---|---|
| 用 `at` 读越界下标还等着报错 | 给 `nil`；要报错自己判（09.3） |
| 以为 `indexOf`/`detect` 找不到给 `-1`/`false` | 都给 `nil`（09.4） |
| 以为 `List` 有 `reject` | 没有，用 `select` 写反条件（09.6） |
| 把 `sortBy` 写成 3 参形式 | 必须 `sortBy(block(a, b, …))`（09.5） |
| `reduce` 四参形式把初值写在最前面 | 是带初值，但 2 参形式不是（09.7） |
| 以为 `m x := 1` 往表里塞条目 | `Map` 的 `:=` 是普通槽定义，条目要 `atPut`（10.1） |
| 直接打印 `m keys` / 拿它做断言 | 哈希序，先 `sort`（10.4） |
| 依赖 `foreach` 的输出顺序 | `Map` 迭代序不是插入序（10.5） |
| `foreach(v, …)` 里把 `v` 当下标用 | 2 参时 `v` 是元素值；要下标写 3 参 `foreach(i, v, …)`（12.1） |
| `map`/`select`/`detect` 体里给外层变量赋值 | 体跑在临时 context 上，赋值出不去；攒值用 `foreach` 或 `append`（12.3） |
| 在 `map` 的体里 `continue` | 那一格以 `nil` 留在结果表里，不会消失（12.8） |

---

## 10. 异常（13）

```io
e := try(1 + nil)              // e 是异常对象；成功时 e 是 nil
try(1 + 1)                     // nil    —— ⚠️ 成功也返回 nil，拿不到成功值
res := nil
e2 := try(res = 1 + 1)         // 要值就写进外层槽

MyErr := Exception clone       // 自定义异常（不要从 Error clone！）
me := try(MyErr raise("消息")) // me type 就是 MyErr
me error                       // "消息"
me isKindOf(MyErr)             // true
me coroutine showStack         // ⚠️ 带地址，不能进回归输出
me originalCall                // 普通运算错误里是 nil

try(MyErr raise("x")) catch(MyErr, handleIt)   // 命中：handler 按副作用求值，返回 nil
try(MyErr raise("x")) catch(Other, handleIt)   // 没命中：把异常原样返回，链式接力
try(...) catch(A, …) catch(B, …) pass          // 接力到最后 pass 再抛
Exception raise("外层", innerException)         // 第二参数才是嵌套原因

withHandler(MyErr, block(exc, resume, 修正值), MyErr signal("轻微"))  // 可恢复
```

**`try` 的实现只有 7 行**（`Exception.io`）：克隆一个 Coroutine 跑参数消息，
最后 `if(coro exception, coro exception, nil)`——所以成功必然给 `nil`。

| 坑 | 解法 |
|---|---|
| 以为 `try(expr)` 会返回表达式的值 | 只回「异常对象或 nil」；要值 `try(res := expr)`（13.1） |
| 以为未捕获异常会让退出码非零 | 横幅打 **stdout**、脚本中断、`rc` 仍是 0（13.3） |
| 用 `catch` 的返回值当处理结果 | 命中返回 `nil`、没命中返回异常本身（13.5） |
| 忘了 `pass` | 没接住的异常变成普通值被静默吞掉（13.6） |
| 「先组装异常再 raise」 | `raise` 立刻离场，且总用自己的实参覆盖 `error`/`nestedException`（13.7） |
| 自定义异常从 `Error clone` 出发 | `Error` 不在 Exception 家族、没有 `raise`（13.8） |
| 用 `method(...)` 造 `withHandler` 的处理器 | `method` 的 `isActivatable = true`，一进形参就被零参调用；必须 `block(...)`（13.9） |
| 把 `e showStack` 打进输出 | 带地址和行号，逐字节比对必挂（13.2） |
| `try` 里跑会挂死的代码 | `try` 只接异常、不接「不返回」（13.10） |

---

## 11. 文件与目录（14）

```io
f := File with("/tmp/x.txt")
f setContents("hello\n")             // 写（覆盖）
f setContents("中文" asUTF8)          // ⚠️ 含非 ASCII 必须先 asUTF8
f contents                           // 读（返回 uint8 字节序列）
f size / f stat size                 // ⚠️ size 是缓存值，连写两次读到旧值
f appendToFile("more\n")             // 追加
f exists / f remove / f name / f path
f openForReading / openForAppending / openForUpdating   // ⚠️ 没有 openForWriting
f readLine / f write("x") / f close
f create                              // 创建空文件

d := Directory with("/tmp/d")         // ⚠️ 不会真的建目录
d exists                              // false
d create                              // 显式建
d fileNames sort                      // 只名字，字典序
d files                               // 对象列表，默认 asString 带地址
d items                               // ⚠️ 混着 "." 和 ".."
d fileNames map(n, Directory with("/tmp/d") fileNamed(n) contents)
```

| 坑 | 解法 |
|---|---|
| `setContents(s)` 写的是字符串的内部表示 | 含非 ASCII 内部是 UCS4（每码点 4 字节），必须 `setContents(s asUTF8)`（14.2） |
| 读回来以为还是原串 | `itemType` 是 `uint8`、`size` 数字节，`== 原串` 是 false（14.3） |
| `File` 没有 `openForWriting` | 写用 `setContents`、追加用 `appendToFile`（14.4） |
| 同一个 `File` 对象的 `size` 是缓存旧值 | 新建 `File clone setPath(p)` 或读 `stat size`（14.5） |
| `File temporaryFile` 给的是不存在的 File | 自己拼 `Path with(TMPDIR, 名字)`（14.6） |
| `files` / `items` 给的是对象不是字符串 | 输出前先 `map(a, a name)`（14.7） |
| 依赖 `files` 的 readdir 顺序 | 与字典序无关，展示或断言前一律 `sort`（14.8） |
| `items` 里混着 `.` 和 `..` | 用 `fileNames` / `directories`，或按 `+2` 记账（14.9） |
| `contents` 读目录会往 stderr 吐 C 级消息 | 别在示例里读目录（14.10） |

---

## 12. 系统与进程（15）

```io
System platform            // "Darwin"
System version             // 构建号
System args                // List，C 风格 argv（含脚本名与解释器）
System launchScript        // ⚠️ 命令行原样（相对路径调用时就不是绝对路径）
System launchPath          // 已被规范化成绝对路径
System ioPath              // 库目录
System installPrefix       // 安装前缀

System getEnvironmentVariable("HOME")          // 不存在给 nil
System setEnvironmentVariable("K", "v")        // ⚠️ 值给 nil 直接段错误 rc=139
System system("exit 3")                        // 3   —— 是退出码不是 wait status
System exit(3)                                 // ⚠️ 真的杀掉当前进程

r := System runCommand("echo hello")
r stdout / r stderr / r exitStatus / r succeeded
System runCommand("echo 中文" asUTF8)           // ⚠️ 非 ASCII 命令串必须 asUTF8
System runCommand("/bin/sh -c 'echo O; echo E 1>&2'")   // 要精确分离两个流就这么写
```

| 坑 | 解法 |
|---|---|
| `System exit(n)` 会真的杀掉当前进程 | 要验退出码就写临时子脚本 + `runCommand` 看 `exitStatus`（15.1） |
| `setEnvironmentVariable(name, nil)` 直接段错误 | rc=139；想清掉只能置空串（15.2） |
| `System system(cmd)` 给的是退出码不是 wait status | `exit 3` 得 `3` 不是 `768`（15.3） |
| 命令串里多条命令时只有最后一条进 `runCommand` 字段 | 显式写 `/bin/sh -c "…"`（15.4） |
| `runCommand` 结果的 `stdout` 是那一块字符串本身 | `escape`/`strip` 会改掉字段，先 `clone`（15.5） |
| 第二个参数会改变 `succeeded` 的语义 | `runCommand("exit 0", 7)` 的 `succeeded` 是 false，只用单参形式（15.5） |
| `launchScript` 是命令行原样 | 「是不是绝对路径」取决于**怎么调用**；能断言的只有「逐字等于 argv[0]」（15.6.1） |
| `runCommand` 两侧的编码都要管 | 命令串含非 ASCII 先 `asUTF8`；`stdout` 是 uint8 字节串，与 UCS4 字面量 `containsSeq` **静默给 false**（15.6.1） |
| `platformVersion` 里塞着内核版本与构建日期 | 只断言非空 / 前缀，不打内容（15.8） |
| 子进程 stderr 会漏到父进程 | 命令必须干净，否则示例 stderr 非空直接判失败（15.8） |

---

## 13. 元编程内省（17）

```io
P getSlot("name")             // 取槽本体，不激活
P setSlot("name", v)          // 放槽
P hasSlot("x") / hasLocalSlot("x")   // 沿 proto 链 / 只看本层
P removeSlot("x")
P slotNames sort              // 所有可见槽名
P protos                      // proto 列表
P appendProto(O) / setProto(O) / removeAllProtos
P uniqueId                    // 地址，别进输出
P isKindOf(X)

Message fromString("1 + 2")   // 构造消息
msg doInContext(P)            // 在指定上下文求值
Lobby doString("x := 1")      // 动态求值（⚠️ 源码必须纯 ASCII）
Object clone do(...)          // 批量定义
Object clone lexicalDo(...)   // 用词法环境求值，读得到外层局部
```

| 坑 | 解法 |
|---|---|
| `slotNames` 是哈希序 | 断言前必须 `sort`（17.1） |
| `hasSlot` 沿 proto 链找、`hasLocalSlot` 只看本层 | 判断「是不是继承来的」用后者（17.2） |
| 槽里的 Block 一读出来就激活 | 要本体必须 `getSlot("名字")`（17.4） |
| `getSlot` 对不存在的槽给 `nil` 不报错 | 它不会替你发现拼错的名字（17.5） |
| `setProto` 是替换不是追加 | 想保留原来的用 `appendProto`（17.6） |
| `removeAllProtos` 会把 `Object` 一起摘掉 | 之后连 `hasSlot` 都发不出去（17.7） |
| `do(...)` 里看不到外层方法的形参 | 改 `lexicalDo`（17.8） |
| `doString` 的源码混进非 ASCII | UCS4 被按字节读取而错位，可能静默执行成别的东西（17.9） |
| `OperatorTable addOperator` 只对新编译单元生效 | 要现注册现用就走 `Lobby doString` 或 `Message fromString`（17.10） |

---

## 14. 协程与并发（18 / 19）

```io
Coroutine currentCoroutine
c := Coroutine clone
c setRunTarget(self) / setRunMessage(Message fromString("..."))
c setLabel("x")               // ⚠️ 实际标签是 "x_" + uniqueId
c run / c yield / c resume    // run 是 Coroutine 的槽，Object 上没有
c isCurrent / c isYielding
Coroutine yieldingCoros       // 队列
Scheduler waitForCorosToComplete    // 确定性的「等所有协程跑完」

Object yield / Object pause / Object wait    // 在 Object 上
System sleep(0.001)                          // sleep 在 System 上，不在 Object 上
obj actorRun                                  // Object 上的 actor 入口
obj @ (futureSend) / obj @@ (asyncSend)       // 别名
obj futureSend / obj asyncSend
Addon exists("Actor")         // 本机 false
```

| 坑 | 解法 |
|---|---|
| `coroDo` 是「立刻切过去跑」不是「注册」 | 会跑到子协程第一个 `yield` 才返回（18.1） |
| `coroDo` 会把创建者留在 `yieldingCoros` 里 | 先 `Coroutine yieldingCoros remove(...)`（18.2） |
| 空队列上 `yield` 什么都不做、`pause` 却抛异常 | `pause` 是未捕获异常，脚本中断（18.3） |
| 队列里只剩自己时 `yield` 立刻返回 | `loop(yield)` 是 100% CPU 死循环，必须子进程 + 超时（18.4） |
| 访问没人 `setResult` 的 `FutureProxy` 会挂起 | 空队列时变成未捕获异常，退出码仍是 0（假阳性）（18.5） |
| Io 没有 `Coroutine status` | 用 `isCurrent` / `isYielding` 问（18.6） |
| `Coroutine label` 默认带 `uniqueId`（地址） | 打进输出会破坏可复现性（18.7） |
| `@` / `@@` 不是协程字面量 | 是 `Object` 上的二元运算符（`futureSend` / `asyncSend`）（18.8） |
| `Future` 没有 `result` / `setValue` | 生产者写 `setResult`，它会让 proxy 直接 `become` 成结果（18.9） |
| `Actor` 这个 proto 本机不存在 | 别写 `Actor clone`；能力挂在 `Object` 上（19.1） |
| `run`/`main` 是 `Coroutine` 的槽 | `Object clone run` 报 `does not respond to 'run'`（19.9） |
| 子进程超时必须带 `--foreground -s KILL` | 否则父进程 stderr 多出 `Killed: 9`（19.10） |

---

## 15. 测试（20）

```io
MyTests := UnitTest clone do(
    testAdd := method(assertEquals(1 + 1, 2))
    testSub := method(assertEquals(3 - 1, 2))
)
MyTests run                     // 返回失败列表，空表 = 全过
System exit((MyTests run) size) // ⚠️ run 失败也退出 0，CI 要自己设退出码
UnitTest testSlotNames          // list("testSlotNames") —— 只看 test 前缀
```

`UnitTest` 自带断言：`assertEquals` `assertNotEquals` `assertTrue` `assertFalse`
`assertNil` `assertNotNil` `assertSame` `assertNotSame` `assertRaisesException`
`assertEqualsWithinDelta`。

| 坑 | 解法 |
|---|---|
| `run` 失败也退出 0 | 自己写 `System exit(<run> size)`，或改用示例自带 `chk`（20.1） |
| `UnitTest` 输出含墙钟耗时与对象地址 | 别把 `run` 的 stdout 当基准（20.2） |
| 匿名 `UnitTest clone do(…)` | 必须绑到一个**具名全局槽**才能跑（20.3） |
| 收集规则只看 `test` 前缀 | 别给测试对象起 `test*` 名字（20.4） |
| `chk` 比 `asString`，浮点误差被舍入抹掉 | 浮点只做范围断言（20.6） |
| `chk` 的返回值反直觉 | 通过 `false`、失败 `nil`，别拿返回值判断（20.7） |
| 把块存进槽再读 = 激活它 | 断言工具收块时用 `getSlot("blk") call`（20.10） |

---

## 16. 序列化（21）

```io
obj serialized                       // 入口（⚠️ 没有叫 Serialize 的对象）
obj serializedSlotsWithNames(list("x"), stream)   // 白名单式序列化
SerializationStream clone
list(1,2,3) serialized               // "list(1, 2, 3);"
Map with("a",1) serialized           // "Map clone do(atPut("a", 1););"
block(v, v + 1) serialized           // "block(v, v +(1))"
"hi" serialized                      // "\"hi\""
Lobby doString(产物)                  // 回读（⚠️ 等于 eval）
```

| 坑 | 解法 |
|---|---|
| 找 `Serialize` 对象 | 入口只有 `obj serialized`（21.1） |
| 有本地槽的对象 `serialized` 直接爆栈 | 用 `serializedSlotsWithNames` 列白名单（21.4） |
| proto 是回读时按名字重新求值 | 改名或重绑定后拿到新对象，跨版本要自带版本号（21.3） |
| 没有循环引用检测 | 自引用 List/Map 一律 `Stack overflow`（21.5） |
| `File serialized` 静默丢掉 path | 要持久化的是路径字符串而不是对象（21.5） |
| `Block serialized` 只写代码不带作用域 | 回读后丢掉闭包捕获（21.2） |
| `asString` 不可逆、`Map asString` 还带地址 | 持久化只用 `serialized` 或自定义格式（21.7） |
| 回读等于 `eval` | 不可信来源的序列化数据别直接回读（21.8） |

---

## 17. 性能（22）

```io
// 攒字符串：O(n²) vs O(n)，本质量差 10 倍以上
for(i, 0, 999, s = s .. i asString)              // ❌ 每次都复制
parts := List clone
for(i, 0, 999, parts append(i asString))
parts join("")                                    // ✅

// 调用：直接调 vs getSlot(...) call(..)，差 4~8 倍
f(x)                                              // ✅
getSlot("f") call(x)                              // ❌ 热循环里别这么写

// 查找：按位置 vs 按键，差 250 倍以上
l indexOf(x)     // ❌ 线性
m at(k)          // ✅ 哈希

// 变参 vs 定参，差 2.5 倍左右
f := method(a, b, a + b)                          // ✅
f := method(call evalArgAt(0) + call evalArgAt(1))  // ❌
```

| 坑 | 解法 |
|---|---|
| 循环里 `s = s .. x` 是 O(n²) | 先收集到 `List` 再 `join`（22.2） |
| 热循环里 `getSlot("f") call(x)` | 直接调用；要用块就先 `getSlot` 一次放进 `List`（22.3） |
| 用 `List indexOf` 按名字查找 | 按键查用 `Map at`（22.4） |
| 指望 Io 做尾调用优化省栈 | 没有 TCO，帧深硬上限 10000（22.6） |
| 在示例里跑无界递归 | 不是抛异常而是彻底卡死，一律子进程 + `gtimeout`（22.6） |
| 用 `Profiler` 找热点 | 本构建 `timedObjects` 永远空表，改用两段对照（22.7） |
| 拿单次计时下结论 | 比值在 0.93~1.58 乱跳，只有量级差 ≥5 倍才敢断言（22.8） |
| 把计数器（如 `recycledObjectCount`）打进输出 | 值随分配历史变，只能断言类型（22.8） |

---

## 18. FFI（23）

```io
lib := DynLib clone setPath("/usr/lib/libm.dylib")
lib open
lib isOpen
lib call("labs", -7)          // 7     —— 整数签名没问题
lib call("pow", 2, 10)        // ❌ 不是 1024！（浮点签名过不去）
lib close

// 可用/不可用（本机实测）
DynLib slotNames  // call, callPluginInit, close, freeFuncName, init, initFuncName,
                  // isOpen, open, path, setFreeFuncName, setInitFuncName, setPath, voidCall
setArgumentTypes / setReturnType     // false —— 没有自定义编组
Pointer / CString / Buffer           // false —— 没有这些类型
Addon exists("Actor") / ("IoServer") // false —— 一个 addon 都没装
Sandbox setMessageCount              // 设得进读得出，但对执行无效
```

| 坑 | 解法 |
|---|---|
| 用 `DynLib` 调浮点签名的 C 函数 | 返回值不是数学结果；让 C 侧封成整数接口（23.4） |
| 把浮点调用的返回值打进输出 | 那是整数寄存器残留，连跑三次值都不同（23.4） |
| 用 `File exists` 预判库能不能 `dlopen` | 现代 macOS 系统库在 dyld 共享缓存里，唯一判据是 `try(... open)`（23.3） |
| `open` 之前就 `call`，或函数名打错 | 都报 `Error resolving call '名字'.`（23.3） |
| 一次给 `call` 传超过 8 个参数 | 硬上限 8 个（23.6） |
| 把原始槽（如 `List_size()`）取进变量再引用 | 按新接收者执行，抛类型不匹配（23.6） |
| 指望 `setArgumentTypes` / `setReturnType` / `Pointer` | 本机构建里全是 false（23.7） |
| 拿 `Sandbox setMessageCount` 兜失控代码 | 设得进但对执行无效（23.7） |
| 让用户可控的字符串决定 `setPath` 或符号名 | 等于把进程地址空间交出去（23.8） |

---

## 19. 综合实战骨架（24）

```io
// 解析器：显式写分隔符、asNumber 后必须范围校验、坏行不中断整批
Record := Object clone do(
    parse := method(line,
        f := line split(" ")
        if(f size != 5, Exception raise("字段数不对（" .. f size asString .. "），期望 5"))
        st := f at(3) asNumber
        if(st < 100 or(st > 599), Exception raise("状态码不成样子：" .. f at(3)))
        r := Record clone
        r status = st
        r
    )
)

// 批量：try 成功也返回 nil，判据是 e != nil
parseAll := method(lines,
    good := List clone; bad := List clone
    lines foreach(line,
        e := try(good append(Record parse(line)))
        if(e != nil, bad append(list(line, e error)))
    )
    Object clone lexicalDo(good := good; bad := bad)   // ⚠️ lexicalDo 不是 do
)

// 表格：map(i, v, 体) 先下标后值
tableRow := method(cols, widths,
    cols map(i, v, v asString alignLeft(widths at(i))) join(""))
```

| 坑 | 解法 |
|---|---|
| 用 `do(...)` 把方法局部变量塞进新对象 | 用 `lexicalDo`（24.2） |
| `try` 的结果当返回值用 | 判据是 `e != nil`，要值就写进外层槽（24.2） |
| `List` 两参迭代写成 `map(v, i, 体)` | 绑定顺序「先下标后值」（24.3） |
| 不传分隔符的 `split` | 一律 `split(" ")`（24.1） |
| `asNumber` 的结果不校验 | `"abc" asNumber` 给 `nan`，`nan` 与任何数比较恒走同一边（24.1） |
| `Map at` 缺键给 `nil` | 计数要 `hasKey` 分支（24.2） |
| 直接打印 `Map` | 带 `0x` 地址的摘要（24.2） |
| `sortBy` 收的不是两参块 | 必须 `sortBy(block(a, b, …))`（24.4） |
| `File setContents` 忘了 `asUTF8` | 落盘变成 4 字节一码点的垃圾（24.5） |
| 累积变量在块里用 `:=` | 那是造了个临时槽，外层永远初值（24.5） |

---

## 20. 240 条坑位总索引

每章正好 10 条，24 章合计 **240 条**。格式：`N.M` 指回第 N 章 M 节。

### 第 01 章 · 01 · 全景：Io 是什么，为什么值得学

1. **带着 C++/Python 的类模型读 Io** — 没有类、没有关键字、没有函数调用，只有「对象 + 消息 + 槽」；先装 01.1 的三条心智模型再看后面。
2. **以为 `=` 和 `:=` 可以互换** — `=` 只能更新**已存在**的槽，凭空造槽报 `Slot x not found. Must define slot using := operator before updating.`（07.3）。
3. **把 `String` 当成一个实在的类型** — 字符串字面量的 `type` 是 `Sequence`，不可变只是一个**对象标志**；`ImmutableSequence` 是空壳 proto，`isKindOf` 也是 `false`（04.1）。
4. **拿 `size` 当字节数** — `size` 数码点、`sizeInBytes` 数**内部**字节、`asUTF8 size` 才是落盘字节；三个数在中文上能差好几倍（04.2）。
5. **跨编码宽度比较字符串** — 字节串（`ascii`/`uint8`）与含中文字面量（`ucs4`/`uint32`）的 `type` 都报 `Sequence`，但 `containsSeq` **不报错、只给错答案 `false`**；比较前两边都 `asUTF8`（16.2、15.6.1）。
6. **以为未捕获异常会让退出码非 0** — 横幅打到 **stdout**、脚本中断、**退出码仍是 0**；所以验证必须靠「结束标记」而不能靠退出码（13.3）。
7. **以为 `try` 会返回成功时的值** — `try` 成功也返回 `nil`，唯一判据是 `e != nil`；要值就自己写进外层槽（13.1）。
8. **以为 `do(...)` 里能用逗号分隔多个槽定义** — 逗号是实参分隔符，`do` 只求值第一个实参，**第二个连求值都不会发生**（07.9）；`do` 的作用域也只到接收者和 `Lobby`，看不到本方法的局部槽，要用 `lexicalDo`（07.10）。
9. **对非 ASCII 文本用光秃秃的 `split`** — 无参 `split` 按**字节**扫空白，码位低字节是 `0x0A`/`0x0D`/`0x20` 的汉字会被劈开（`"上" split` 得 `list("")`）；外部文本一律写 `split(" ")`（16.4）。
10. **以为 `and` 和 `or` 结构对称** — `and` 是方法（必须求值实参），`or` 在非假值对象上是**值槽** `true`（`setSlot("or", true)`），实参连求值都不发生、结果恒 `true`（05.4）。


### 第 02 章 · 02 · 第一行输出与最小心智模型

1. **`obj println(x)` 里的 x 被丢弃** — `println` 写的是接收者，要打印 x 就用 `writeln(x)` 或 `x println`。
2. **以为字符串会自动插值** — `#{...}` 只是普通文本，必须显式接 `interpolate`。
3. **把三引号当模板串** — 三引号只是多行字面量，里面的 `#{}` 同样不会展开。
4. **写 `"\x41"` 想得到 `A`** — 本构建没有 `\xNN` 转义，结果串是 `x41`。
5. **用逗号分隔语句** — 逗号是参数分隔符，多余实参被静默丢掉，语句分隔一律用 `;` 或换行。
6. **拿 `size` 当字节数** — `size` 数的是码点；内部字节看 `sizeInBytes`，UTF-8 字节看 `asUTF8 size`。
7. **对中文串用 `interpolate`** — 非 ASCII 上会错位甚至段错误，改用 `writeln` 多参数或 `..`。
8. **把 `0`、`""`、空列表当真值之外的东西** — 它们全是真值；只有 `nil` 和 `false` 为假（[5.1](05-control.md)）。
9. **在输出里打路径、地址、时间、进程号** — 这些值每次运行都不同，会毁掉逐字节比对；只打 `basename`。
10. **靠退出码判断脚本是否跑完** — 未捕获异常会中断脚本却仍退出 0，必须同时检查结束标记。


### 第 03 章 · 03 · 数字：只有一种 Number

1. **以为 `7 / 2` 是 3** — `/` 永远是真除法，整数商要显式 `floor`。
2. **`1.0 asString` 与 `1 asString` 分不清** — 两者都是 `"1"`，要保形状得自己格式化。
3. **把 `** — ` 当右结合** → Io 的 `**` 左结合，`2 ** 3 ** 2` 是 64，幂塔要加括号。
4. **`-4 abs` 得到 4** — 一元负号绑定松，先算 `4 abs`，要正确结果写 `(-4) abs`。
5. **用 `==` 比较浮点结果** — `(0.1 + 0.2) == 0.3` 是 false，改比误差。
6. **用 `==` 检测 NaN** — `nan == nan` 是 false，检测一律用 `isNan`。
7. **假设 `round` 是银行家舍入** — 实测是四舍五入（远离零），`2.5 round` 给 3。
8. **用 `toBase(16)` 拼定宽十六进制** — 它不补零，定宽要改用 `asHex`。
9. **记不存在的方法名 `bitwiseNot`** — 取反是 `bitwiseComplement`，结果是 `-7` 这类负数。
10. **拿 `Number integerMax` 当溢出边界** — 它只是 32 位常量，`+ 1` 不会回绕。


### 第 04 章 · 04 · 序列：字节串、码点串与不可变字面量

1. **在字面量上调 `strip` / `replaceSeq` / `appendSeq`** — 抛 `cannot be called on an immutable Sequence`，先 `asMutable` 或 `Sequence clone`。
2. **以为字面量的 proto 是 `ImmutableSequence`** — 它的 `type` 就是 `Sequence`，只读是因为带不可变标志（问 `isMutable`，别问 `type`），`isKindOf(ImmutableSequence)` 为 false。
3. **把 `size` 当字节数** — `size` 数码点，内部字节看 `sizeInBytes`，UTF-8 字节看 `asUTF8 size`。
4. **用 `sizeInBytes` 算文件长度** — 含中文时它是「每码点 4 字节」，写文件要用 `asUTF8 size`。
5. **`at(i)` 当字符用** — 它给的是码点数值，要字符得再 `asCharacter`。
6. **把 `exSlice` 的右边界当闭区间** — 它是左闭右开，`exSlice(0, s size)` 才是整串。
7. **调用旧名 `slice`** — 会往 stdout 打废弃警告污染判定区间，改用 `exSlice`。
8. **用 `split` 解析 CSV 后抱怨多出空字段** — `split` 保留空段，去空段要用 `splitNoEmpties`。
9. **以为 `findSeq` 找不到时给 -1** — 它给 `nil`，当下标用之前先判空。
10. **对含中文的文案用 `interpolate`** — 会错位、抛异常甚至段错误，改用 `writeln` 多参数或 `..`。


### 第 05 章 · 05 · 控制流：没有 if，只有消息

1. **把 `0` 当假** — 假值只有 `nil` 和 `false`，`0`、`""`、空列表全为真。
2. **以为 `if(false, x)` 返回 `nil`** — 单臂式等价于 `cond and(x)`，返回假值本身 `false`；`nil` 那支也归一成 `false`。
3. **给 `if` 的分支里放必炸的表达式** — 未选中的分支不会被求值，可以放心放副作用。
4. **写 `nil ifTrue(x)` 求默认值** — `ifTrue` / `ifFalse` 只长在布尔上，`nil` 调用直接报不响应。
5. **`ifTrue` / `ifNonNilEval` 的返回值方向和直觉相反** — `ifTrue` 返回接收者（那个布尔），要结果用 `if` 或 `and`；`ifNonNilEval` 在非 nil 时返回的是**实参的值**（方向与 `ifNilEval` 相反）。
6. **用 `ifNil` 取默认值** — `ifNil` 只返回接收者，取默认值必须用 `ifNilEval`。
7. **把 `for(j, 1, 3)` 当 C 的 `j < 3`** — 上界是闭区间，会循环 3 次。
8. **用 `loop` 却没写 `break`** — 无条件循环不会自己停，示例必须包着超时跑。
9. **以为 `and` 和 `or` 结构对称** — `and` 是方法（必须求值实参），`or` 在非假值对象上是**值槽** `true`（`setSlot("or", true)`），实参连求值都不发生、结果恒 `true`；`or` 右边只放无副作用的表达式。
10. **拿 `x not` 判断「对象为假」** — `not` 是值槽，`Object` 上那份是 `nil`，普通对象取反给 `nil` 而不是 `false`；要判断用 `if(x, ...)` 或 `x == nil`。


### 第 06 章 · 06 · 消息：三种形状与优先级

1. **以为 `1 + 2 max(3)` 是 3** — 带参消息比二元操作符绑得紧，结果是 4，要改顺序得加括号。
2. **按 Smalltalk 的优先级直觉写代码** — Io 的顺序是一元 > 关键字 > 二元，与 Smalltalk 相反。
3. **链式调用中途断链** — 只返回值的最后一环必须返回 `self`，否则后续消息发不到对象上。
4. **把 `+` 当编译器内建** — 它就是消息，`2 perform("+", 3)` 与 `2 + 3` 完全等价。
5. **忘了 `..` 优先级是 12** — 它比 `and`/`or` 还松，长表达式拼接要加括号。
6. **写了 `addOperator` 就在同文件里用** — 一个文件是一次性解析的，注册只对之后的编译单元生效。
7. **以为 `call argCount` 是形参个数** — 它给的是实参个数，变参实现全靠这个。
8. **手工造消息拼错名字** — `Message clone setName` 造的是空参数消息，参数要用 `setArguments` 或直接 `fromString`。
9. **拿 `..` 拼未覆盖 `asString` 的对象** — 得到带地址的槽位摘要，输出不再逐字节稳定。
10. **覆盖方法后忘了怎么调父实现** — 用 `resend`（同名字）或 `super(名字)`（显式指定）。


### 第 07 章 · 07 · 原型：克隆、槽与 proto 链

1. **把 `:=` / `=` / `::=` / `newSlot` 当成一回事** — `=` 只能**更新已存在**的槽（否则 `Slot x not found. Must define slot using := operator before updating.`）；`:=` 只造槽、**不配 setter**；而 `::=` 和 `newSlot` **都会**顺手生成 `setX`（`newSlot` 会配 setter 这点最容易记反，07.2 有实测）。
2. **以为 `=` 会修改原型上的槽** — 它在接收者自己身上建遮蔽副本，原型不受影响。
3. **用 `hasSlot` 判断「槽长在谁身上」** — 它沿链查找，判本地要用 `hasLocalSlot`。
4. **把 `isKindOf` 当双向判断** — 它有方向：`B isKindOf(A)` 真而 `A isKindOf(B)` 假。
5. **直接打印 `protos`** — 里面是对象，会打出地址；只取 `size` 或做等价比较。
6. **以为 `clone` 只是复制** — 它还会自动调用副本上的 `init`，要跳过就用 `cloneWithoutInit`。
7. **以为 `do(...)` 只是语法括号** — 它既换 `self`（块里的 `:=` 落在接收者上），也换作用域起点；要读方法局部槽得用 `lexicalDo`。
8. **直接比较 `slotNames`** — 顺序是哈希序，且大写命名的对象还会多出 `type` 槽，先 `sort` 再比。
9. **在 `do(...)` 里用逗号分隔多个槽定义** — 多出的实参不求值，槽静默消失，用 `;` 或换行。
10. **让未覆盖 `asString` 的对象进输出** — 拼出的是带 `0x` 地址的摘要，先写一个稳定的 `asString`。


### 第 08 章 · 08 · 方法：参数、作用域与 return

1. **调用时少传参数就以为会报错** — 形参拿到 `nil`，直到被用到才炸，报错信息里只有下游痕迹。
2. **写 `(method(...))(x)` 当立即调用** — 那是两个相邻括号组，方法被丢弃，结果是 `x`。
3. **用 `method(a, b := 10, ...)` 当默认参数** — `:=` 解析成 `setSlot` 消息，`b` 不是形参，改成判 `nil` 后赋值。
4. **以为 `argumentNames` 里只有你写的形参** — 假默认参数会让它变成 `list("a", "setSlot")`。
5. **想写变参却找不到 `*args`** — 形参表留空，用 `call argCount` 与 `call evalArgAt(i)` 现场取。
6. **忘了多出来的实参仍在 `call` 里** — 声明形参后，从下标 1 起就是多余实参，静默可用。
7. **在块里 `return` 以为只结束本次迭代** — `return` 是方法级跳转，会穿出整个方法。
8. **直接把方法名当值传** — 读槽即调用，要本体必须 `getSlot("名字")`。
9. **用逗号分隔方法体里的多条语句** — 逗号进的是形参表，语句分隔一律用 `;` 或换行。
10. **想知道某段代码被解析成什么却不打印消息树** — `show(Message fromString("..."))`，它是最便宜的取证手段。


### 第 09 章 · 09 · 列表

1. **以为 `List slice` 会打废弃警告** — 警告只出在 `Sequence slice`（Io 方法）上；`List slice` 是 CFunction 原语、不警告，两者区间语义都是左闭右开。
2. **以为 `removeAt` / `pop` 也返回自身** — 它们返回被删掉的元素，接着链式调用会炸；只有 append / prepend / push / atPut / swapIndices / atInsert 返回自身。
3. **用 `at` 读越界下标还等着报错** — `at` 越界给 nil（负索引同理），只有写操作 atPut / atInsert / insertAt 才抛 `index out of bounds`。
4. **以为 `indexOf` 找不到给 -1、`detect` 找不到给 false** — 两者都给 nil；`if(a indexOf(x))` 还会把合法的下标 0 当假值。
5. **把 `sortBy` 当「取键」用，只写一个形参** — 不报错但排序结果是错的（实测 `list(5, 3, 9)` 得到 `list(3, 9, 5)`）；键排用 `sortByKey(消息)`，比较器写 `block(x, y, ...)`。
6. **以为 `List` 有 `reject`** — 这版 List 没有，调用得到 `List does not respond to 'reject'`；用 `select(v, (条件) not)`。
7. **`reduce` 四参形式把初值写在最前面** — 顺序是 `(名字A, 名字B, 表达式, 初值)`，初值在末位，写成 `reduce(100, ...)` 会去求值 `x + y` 而炸。
8. **把嵌套 List 直接 `asString` 打进输出** — 内层走 `asSimpleString`，所有元素都被加引号；要确定性就自己 `map` + `join` 或先 `flatten`。
9. **把方法先存进局部槽、之后再调** — 读槽会以零参激活它（`nil does not respond to '*'`）；要么取出来立刻 `call`，要么用 `getSlot` 拿本体。
10. **用点号写消息链（`a.asString`）** — 点号会被并进消息名，得到 `Object does not respond to 'a.asString'`；Io 的链条靠空格：`a asString`。


### 第 10 章 · 10 · 映射

1. **以为 `m x := 1` 往表里塞了个条目** — `:=` 建的是普通槽，`size` / `hasKey` 都看不见它；条目必须用 `atPut`。
2. **拿数字或别的非 Sequence 当键** — `atPut` 直接抛 `argument 0 to method 'atPut' must be a Sequence, not a 'Number'`，键要先 `asString`。
3. **把 `Map` 本身打印出来** — 默认 `asString` 是 `Map_0x...`（地址）；用 `keys sort` 自己拼确定性字符串。
4. **直接打印 `m keys` / `m values` 或拿它做断言** — 顺序不做承诺（实测换插入顺序就变）；一律先 `sort`。
5. **依赖 `foreach` 的输出顺序** — 它的顺序跟着 `keys` 走；求和、计数这类顺序无关的可以放心用，落盘输出要先 `sort`。
6. **以为 `at` 缺键会抛异常** — 缺键给 nil，不报错；只有键的类型不对才抛异常。
7. **以为 Map 的 `removeAt` 返回被删掉的值** — 它返回表自身（List 的 `removeAt` 才返回元素），删不存在的键也不报错。
8. **以为 `atIfAbsentPut` 会覆盖已有值** — 已存在时返回老值且不写入；返回的始终是「当前的值」。
9. **记混 `select` / `map` / `detect` 的返回形状** — `select` 给 Map、`map` 只收值给 List、`detect` 给 `list(key, value)`。
10. **把 `groupBy` 的键当数字用** — 键是表达式 `asString` 出来的字符串，取法要 `g at("0")`，写 `g at(0)` 取不到。


### 第 11 章 · 11 · 块与闭包

1. **把 `{ ... }` 当块字面量写** — 本构建里它只会变成没人实现的 `curlyBrackets(...)` 消息，块一律写 `method(...)`。
2. **把块存进槽后想「读出来看看」** — 读槽就是零参调用，要本体用 `getSlot("名字")`。
3. **把块当数据传给别的函数** — `method(...)` 造的块 `isActivatable` 是 `true`，一进形参（形参就是槽）就被调用；要传的块一律用 `block(...)` 造（11.3.1）。典型受害者：`sortBy` 的比较器、`withHandler` 的处理器。
4. **以为闭包把外层的值拷了一份** — 捕获的是上下文对象，外层 `n = 5` 之后块里读到的就是 5。
5. **以为块里的名字按调用处解析** — 按定义处解析；调用帧里的同名局部完全不算数。
6. **在块里用 `:=` 想改外层变量** — `:=` 只造当前帧的局部，改外层要用 `=`。
7. **在 maker 里 `n := 0` 再 `method(n = n + 1)` 造计数器** — maker 一返回局部槽就没了，报 `Object does not respond to 'n'`；用 `setScope` 钉到持久对象上，或把状态放进对象槽。
8. **在 `show` / `chk` 里反复引用一个可激活的槽** — 实参是消息，每引用一次再调一次，断言会把计数器推着走；先取快照。
9. **写 `and(false, bump)` 忘了接收者** — 成了发给 Lobby 的消息，短路失效、`bump` 照样被求值；`and` / `or` 必须发在真值上。
10. **以为少传实参会报参数缺失** — 少传的形参是 `nil`（用到才炸），多传的被静默忽略但 `call argCount` 仍看得见。


### 第 12 章 · 12 · 迭代与集合遍历

1. **`foreach(v, ...)` 里把 `v` 当下标用** — 2 参时 `v` 是元素值，要下标写 3 参的 `foreach(i, v, ...)`。
2. **`foreach(体)` 里给外层变量赋值以为能看见** — 1 参形式的体跑在临时 context 上，赋值出不去；要 `foreach(v, 体)` 才绑进调用帧。
3. **在 `map` / `select` / `detect` / `reduce` 的体里写 `acc = acc + x` 攒值** — 这些体也跑在临时 context 上，外层 `acc` 不变；攒值请用 `foreach` 或往容器里 `append`。
4. **把 `map` 的结果当成一次普通映射** — 体里若有对外层变量的赋值，会因为 context 内部共享而变成累加和，别依赖。
5. **以为 `reduce(0, +)` 是「带初值的 reduce」** — 2 参形式会在调用者上下文里求值最后一个参数，`reduce(0, +)` 直接抛 `Object does not respond to '+'`；任意二元运算写 `reduce(a, b, 体)`。
6. **以为 `detect` 没命中会报错** — 返回 `nil`（空表同样），要自己判 `isNil`。
7. **想用 `reject` 取反** — `List` 上没有 `reject`，会抛 `List does not respond to 'reject'`，用 `select` 写反条件。
8. **在 `map` 的体里 `continue`** — 那一格会以 `nil` 的形式留在结果表里，不会从结果里消失。
9. **在 `foreach` 里 `removeAt` 当前元素** — 下标错位、后面的元素被静默跳过；想安全删除就先收集下标、循环结束后再删。
10. **在 `foreach` 里 `append`** — 这一轮循环看得见新元素，表会一直长，必须自己写 `break` 护栏。


### 第 13 章 · 13 · 异常与错误处理

1. **以为 `try(expr)` 会返回表达式的值** — 它只回「异常对象或 `nil`」，成功值拿不到；要值就 `try(result := expr)`。
2. **以为未捕获异常会让退出码非零** — 横幅打 stdout、脚本中断、`rc` 仍是 0；判定必须靠结束标记。
3. **`catch` 的返回值和调用位置搞错** — handler 按**副作用**求值：命中时 `catch` 返回 `nil`、没命中把异常**原样返回**（链式分派就靠这条）；语法是先 `e := try(...)`，再 `e catch(类型, 动作)`，不是把 `catch` 写进 `try`。
4. **忘了 `pass`** — 没接住的异常会变成一个普通值被外层静默吞掉，`try` 只给你 `nil`。
5. **`raise(...) setNestedException(...)` 或者「先组装异常再 `raise`」** — `raise` 是立刻离场的，链在它后面的语句永不执行；而且 `raise` 总用自己的实参覆盖 `error`/`nestedException`。嵌套原因只能走 `raise` 的第二个参数。
6. **自定义异常从 `Error clone` 出发** — `Error` 不在 `Exception` 家族、没有 `raise`，会得到「`Error does not respond to 'raise'`」这种误导性报错。
7. **指望 `e originalCall` 做堆栈回溯** — 普通运算错误里它是 `nil`；回溯要用 `e coroutine showStack`，而它带地址，不能进回归输出。
8. **把 `e showStack` 打进示例输出** — 里面有地址和源文件行号，逐字节比对必挂；要取证就断言 `hasSlot("showStack")`。
9. **`try` 里跑会挂死的代码** — `try` 只接异常、不接「不返回」，挂死的代码在 `try` 里照样挂死，必须用子进程 + 超时兜住。
10. **用 `method(...)` 造 `withHandler` 的处理器** — `method` 造的块 `isActivatable = true`，一进形参（形参就是槽）就被**零参调用**，异常对象传不进去，报错还跟着处理器返回值变（返回 `42` 就报 `Number does not respond to 'call'`）；处理器一律用 `block(exc, resume, …)`（11.3.1）。


### 第 14 章 · 14 · 文件与目录

1. **`setContents(s)` 写的是字符串的内部表示** — 含非 ASCII 的串内部是 UCS4（每码点 4 字节），必须 `setContents(s asUTF8)`。
2. **读回来只是字节串** — `itemType` 是 `uint8`、`size` 数字节：14 码点的中文串读回来是 18，且 `== 原串` 为 false。
3. **`File` 没有 `openForWriting`** — 报 `File does not respond to 'openForWriting'`，写文件用 `setContents`、追加用 `openForAppending`。
4. **同一个 `File` 对象的 `size` 是缓存旧值** — 连着写两次，第二次读到的还是上一次的字节数；新建 `File clone setPath(p)` 或读 `stat size`。
5. **`File temporaryFile` 给的是 path 为空、不存在的 File** — 写它静默无效，自己拼 `Path with(TMPDIR, 名字)`。
6. **`files` / `items` 给的是对象而不是字符串** — 默认 `asString` 带地址，输出前先 `map(a, a name)`。
7. **`files` 的 readdir 顺序与字典序无关** — 实测 `z.txt, m.txt, b.txt, a.txt, note.io`，展示或断言前一律 `sort`。
8. **`items` 里混着 `.` 和 `..`** — 只要真实条目就用 `fileNames` / `directories`，或按 `+2` 记账。
9. **`Directory remove` 对不存在的目录抛异常，`File remove` 不抛** — 目录删除要么先 `exists` 判断，要么 `try(...)` 包住。
10. **失败消息里带绝对路径** — 只打前缀或 `basename`；另外 `contents` 读目录会往 stderr 吐 C 级消息，别在示例里用。


### 第 15 章 · 15 · 系统、进程与环境

1. **`System exit(n)` 会真的杀掉当前进程** — 要验证退出码就写临时子脚本 + `runCommand` 看 `exitStatus`。
2. **`setEnvironmentVariable(name, nil)` 直接段错误** — rc=139，两个二进制都一样；想「清掉」只能置空串，读回来是 `""` 不是 `nil`。
3. **`System system(cmd)` 给的是退出码不是 wait status** — `exit 3` 得到 `3` 而不是 `768`，别拿它当 C 的 `system()`。
4. **命令串里多条命令时只有最后一条的输出进 `runCommand` 的字段** — 要精确分离 stdout/stderr 就显式写 `/bin/sh -c "…"`。
5. **`runCommand` 结果的 `stdout` 是那一块字符串本身** — `escape`/`strip` 这类就地方法会改掉字段，先 `clone`。
6. **第二个参数会改变 `succeeded` 的语义** — `runCommand("exit 0", 7)` 的 `succeeded` 是 false，只用单参数形式。
7. **`System symbols size` 会随脚本自己定义的符号涨** — 同一脚本内稳定、改一行代码就变，别把具体数字写进断言。
8. **`platformVersion` 里塞着内核版本与构建日期** — 只断言非空 / 以 `platform` 开头，不打内容。
9. **`launchPath` 是规范化的绝对路径、`launchScript` 是命令行原样** — 「`launchScript` 是不是绝对路径」取决于**你怎么调用它**，写进示例就是非确定性输出；能断言的是 `launchScript == args at(0)`，差异交给观察项 `observe_15_relpath.io`。
10. **`runCommand` 两侧的编码都要管** — 命令串含非 ASCII 必须先 `asUTF8`（否则 UCS4 交给 shell，报 `sh: e: command not found`、`stdout` 是 `nil`、错误还漏到父进程 stderr）；拿回来的 `stdout` 是 `ascii`/`uint8`（按字节），与源码里含中文的 `ucs4`/`uint32` 字面量（按码点）**不是同一种序列**，`type` 都叫 `Sequence` 却宽窄不同，`containsSeq` 会**静默给 false**，两边都 `asUTF8` 才比得对。


### 第 16 章 · 16 · 文本处理

1. **字面量不可变** — `strip`/`lstrip`/`rstrip`/`replaceSeq`/`uppercase`/`escape` 都是就地方法，抛 `'xxx' cannot be called on an immutable Sequence`，先 `asMutable`。
2. **没有 `asImmutable`，也没有 `findLastSeq` / `replaceSeqInPlace`** — 反向查找用 `reverseFindSeq`，替换直接用 `replaceSeq`（它本身就就地）。
3. **编码按内容自动升级，跨宽度比较会静默出错** — 纯 ASCII 是 `uint8`、含中文是 `uint32`；`size` 数码点、`sizeInBytes` 数字节、`asUTF8 size` 才是 UTF-8 字节数。**两种宽度的序列做 `containsSeq`/`==` 不报错，只给错答案**（详见 16.2 末段与第 15 章 15.6.1）。
4. **`at(i)` 给的是码点 Number** — `20013` 而不是字符，要 `asCharacter`；对 `asUTF8` 的结果取下标拿到的才是一个字节。
5. **`interpolate` 在非 ASCII 前缀上丢尾巴** — `"中文#{1 + 2}"` 得到 `中文1`、长度只有 3，中文文案改用 `..` 拼接或纯 ASCII 模板。
6. **`interpolate` 表达式带括号 + 非 ASCII 前缀直接段错误** — `"中文#{(1 + 2)}"` 是 rc=139 且无任何输出，永远不要在中文串上用 `#{}`。
7. **`interpolate` 表达式里出现标识符** — `#{list(1,2) size}` 报 `Object does not respond to 'l'`，只能放最简表达式。
8. **不传分隔符的 `split`** — 按**字节**扫空白，码位低字节是 `0x0A`/`0x0D`/`0x20` 的汉字会被劈开（`"上" split` 得 `list("")`）；外部文本一律用 `split(" ")` 这样的显式分隔符。顺带：`split` 保留空段（`"a,b,,c"` 给 4 段），不想要空段就 `splitNoEmpties`。
9. **去空白 / 大小写的名字不是想当然的那些** — 用 `strip`/`lstrip`/`rstrip`、`asUppercase`/`asLowercase`，没有 `stripLeft`/`stripRight`/`upper`/`lower`。
10. **中文比较与排序按 Unicode 码点** — `"中" > "啊"` 为 false，要拼音序只能自己建映射表。


### 第 17 章 · 17 · 元编程与反射

1. **`slotNames` 是哈希序** — 拿它做断言前必须先 `sort`，否则两个内容相同的对象比不过。
2. **`hasSlot` 沿 proto 链找，`hasLocalSlot` 只看本层** — 判断「是不是继承来的」要用后者。
3. **`clone` 出来的对象不共享槽** — `q := p clone; q x := 1` 之后 `p hasSlot("x")` 仍是 false。
4. **槽里的 Block 一读出来就激活** — 要拿方法本体必须 `getSlot("名字")`，否则等于零参调用。
5. **`getSlot` 对不存在的槽给 `nil` 不报错** — 它不会替你发现拼错的名字，别把 `nil` 当「槽存在」。
6. **`setProto` 是替换不是追加** — 想保留原来的 proto 要用 `appendProto`。
7. **`removeAllProtos` 会把 `Object` 一起摘掉** — 之后连 `hasSlot` 都发不出去，报 `'X' does not respond to message 'hasSlot'`。
8. **`do(...)` 里看不到外层方法的形参** — `Object clone do(x := v)` 在方法体内会报 `Object does not respond to 'v'`；改成先 `clone` 再 `setSlot`。
9. **`doString` 的源码必须纯 ASCII** — 混进非 ASCII 会因 UCS4 内部表示被按字节读取而错位，可能抛异常也可能静默执行成别的东西。
10. **`OperatorTable addOperator` 只对新编译单元生效** — 同一文件里注册完立刻用会走样（实测返回的是接收者）；要现注册现用就走 `Lobby doString` 或 `Message fromString`。


### 第 18 章 · 18 · 协程与 Future

1. **`coroDo` 是「立刻切过去跑」不是「注册」** — 它会跑到子协程第一个 `yield` 才返回。
2. **`coroDo` 会把创建者留在 `yieldingCoros` 里** — 之后再排队别的协程，`yield` 可能先轮到自己，那个协程永远不动；先 `Coroutine yieldingCoros remove(Coroutine currentCoroutine)`。
3. **`coroDo` 的 `runLocals` 是 `call sender`** — 子协程和创建者共用 locals，改一个看得见另一个；要隔离就用 `Coroutine clone` 自己给 `runLocals`。
4. **空队列上 `yield` 什么都不做，`pause` 却会抛异常** — `pause` 报 `Scheduler: nothing left to resume so we are exiting`，且它是未捕获异常（脚本中断、退出码仍 0）。
5. **队列里只剩自己时 `yield` 立刻返回** — `loop(yield)` 是 100% CPU 死循环，只能被外部强杀（退出码 137）；这类调用必须放进子进程 + 超时。
6. **访问没人 `setResult` 的 `FutureProxy` 会挂起当前协程** — 空队列时变成未捕获异常并中断脚本，子进程退出码是 0，属假阳性。
7. **Io 没有 `Coroutine status` 这个槽** — 状态拆成 `isCurrent` / `isYielding` 问，存在性用 `hasSlot` 先确认。
8. **`Coroutine label` 默认是 `uniqueId`（地址）** — `setLabel("x")` 也只是拼成 `"x_" + uniqueId`，整条打进输出会破坏可复现性。
9. **`@` / `@@` 不是协程字面量** — 它们是 `Object` 上的二元运算符（`futureSend` / `asyncSend` 的别名），只有 Actor 语境里才有意义。
10. **`Future` 没有 `result` / `setValue`** — 生产者写 `setResult`；`setResult` 会让 `FutureProxy` 直接 `become` 成结果，读出来类型都变了。


### 第 19 章 · 19 · Actor 与并发

1. **`Actor` 这个 proto 本机不存在** — 别写 `Actor clone`；actor 能力挂在 `Object` 上，入口是 `actorRun` / `@` / `@@`。
2. **本机一个 addon 都没装** — `Addon exists("Actor")` / `("IoServer")` / `("IoClient")` 全是 false，分布式那部分本章不覆盖。
3. **`@` 返回的是 `FutureProxy` 不是结果** — 结果要靠 `Scheduler waitForCorosToComplete` 抽干队列后再读接收者，「派发完 total 还是 0」是正常的。
4. **`@@` 返回 `nil`** — 两者功能相同，只差「要不要那个 proxy」；`futureSend` 是 `@` 的别名，`asyncSend` 是 `@@` 的别名。
5. **`actorQueue` / `actorCoroutine` 要等第一次 `actorRun` 才出现** — 之前 `hasLocalSlot` 是 false，直接读会拿到 `nil`。
6. **actor 里的异常默认会 `e showStack` 打到 stdout** — 想干净就覆盖 `handleActorException`，否则一条异常横幅就能毁掉示例的可复现性。
7. **`yield` / `pause` / `wait` 在 `Object` 上，`sleep` 在 `System` 上** — `Object clone sleep(0.001)` 会报 `Object does not respond to 'sleep'`。
8. **别用 `System sleep` 当同步手段** — 用 `Scheduler waitForCorosToComplete`，它是确定性的；时间既不能进逻辑也不能进输出。
9. **`run` / `main` 是 `Coroutine` 的槽，不是对象的** — `Object clone run` 报 `Object does not respond to 'run'`。
10. **子进程超时必须带 `--foreground -s KILL`** — 不带 `--foreground` 时 gtimeout 会连自己的进程组一起杀，父进程 stderr 会多出 `Killed: 9` 一行。


### 第 20 章 · 20 · 单元测试

1. **`run` 失败也退出 0** — CI 里必须自己写 `System exit(<run> size)`，或改用示例自带 `chk`。
2. **`UnitTest` 输出含墙钟耗时与对象地址** — 别把 `run` 的 stdout 直接当基准，只断言它的固定子串。
3. **匿名 `UnitTest clone do(…)` 跑到本体上** — `run` 拿 `type` 回 Lobby 找对象，测试对象必须绑到一个具名全局槽。
4. **收集规则只看 `test` 前缀** — `UnitTest testSlotNames` 自己返回 `list("testSlotNames")`，给测试对象起名时别撞 `test*`。
5. **`assertEqualsWithinDelta` 的消息没插值** — 打出来是 `#{expected} expected, …` 模板原文，别看消息猜算法。
6. **`chk` 比 `asString`，浮点误差被舍入抹掉** — `0.1 + 0.2` 与 `0.3` 打印相同却不相等，浮点只做范围断言。
7. **`chk` 的返回值反直觉** — （通过 `false`、失败 `nil`）→ 别用返回值做判断，状态只看 `fails` 计数器。
8. **`Error` 上没有 `raise`** — 自定义异常必须 `MyErr := Exception clone`，`Error clone` 会报 `does not respond to 'raise'`。
9. **`catch` 命中返回 `nil` 且丢掉块的返回值** — 不命中才返回异常自己；要靠链式 `.catch(A,…) catch(B,…) pass` 接力。
10. **把块存进槽再读 = 激活它** — 断言工具收块时用 `getSlot("blk") call`，否则读槽那一刻就跑了。


### 第 21 章 · 21 · 序列化与持久化

1. **没有 `Serialize` 对象** — 序列化入口只有 `obj serialized`（配 `SerializationStream`），`toString`/`toObject` 一律不存在。
2. **有本地槽的对象 `serialized` 直接爆栈** — 用 `serializedSlotsWithNames(list("x"), stream)` 自己列白名单（21.4）。
3. **proto 是回读时按名字重新求值** — 改名或重绑定后拿到的是新对象，跨版本必须自己带版本号（21.3）。
4. **没有循环引用检测** — `SerializationStream` 的 `seen` 是死代码，自引用 List/Map 一律 `Stack overflow`（21.5）。
5. **`File serialized` 静默丢掉 path** — 产物是 `File clone do()`，句柄类对象要持久化的是路径字符串而不是对象（21.5）。
6. **`Block serialized` 只写代码不带作用域** — 产物 `block(v, v +(1))` 回读后丢掉了闭包捕获，别指望它能恢复上下文（21.2）。
7. **嵌套 List 的产物带内层分号** — `list(list(1, 2);, 3);`，Io 能容忍但这不是合法惯用式，跨语言读写要自己控格式（21.2）。
8. **`asString` 不可逆、`Map asString` 还带地址** — 持久化只用 `serialized` 或自定义格式，`asString` 只给人看（21.7）。
9. **`setContents` 写内部表示** — 含中文的串必须先 `asUTF8`，否则每码点 4 字节（实测 `"中文"` 写出 8 字节） （21.6）。
10. **回读等于 `eval`** — `Lobby doString(产物)` 会执行源码，不可信来源的序列化数据别直接回读（21.8）。


### 第 22 章 · 22 · 性能陷阱与基准

1. **循环里 `s = s .. x` 是 O(n²)** — 先收集到 `List` 再 `join`，或用 `Sequence clone appendSeq`（22.2，本质量差 10 倍以上）。
2. **热循环里 `getSlot("f") call(x)`** — 直接调用；方法要当值传就先 `getSlot` 一次、放进 `List` 而不是槽（22.3，差 4~8 倍）。
3. **用 `List indexOf` 按名字查找** — 按键查用 `Map at`，按位置取才用 `List at`（22.4，差 250 倍以上）。
4. **热路径用变参 `call evalArgAt`** — 声明形参，变参留给工具方法（22.5，差 2.5 倍左右）。
5. **指望 Io 做尾调用优化省栈** — 没有 TCO，帧深硬上限 10000，`return rec(...)` 照样爆（22.6）。
6. **在示例里跑无界递归** — 不是抛异常而是彻底卡死（实测 `rc=124`，stdout 只有 IOVM 信号横幅），一律子进程 + `gtimeout`（22.6）。
7. **用 `Profiler` 找热点** — 本构建 `timedObjects` 永远是空表，只会输出 `sample size to small`，改用两段对照（22.7）。
8. **拿单次计时下结论** — Lobby 污染的实测比值在 0.93~1.58 乱跳；只有量级差 ≥5 倍的对照才敢断言（22.8）。
9. **把 `hasSlot(...)` 直接当 `list(...)` 的实参** — VM 收信号并挂住（实测 `rc=124`），先存变量再 `list`（22.8）。
10. **把 `recycledObjectCount` 之类的计数器打进输出** — 值随分配历史变，只能断言类型，不能进逐字节比对（22.8）。


### 第 23 章 · 23 · 外部函数接口

1. **用 `DynLib` 调 `pow` / `sqrt` 这类浮点签名的 C 函数** — 返回值不是数学结果（实测 `pow(2,10) != 1024`）；让 C 侧封成整数接口，或返回放大后的整数（23.4 / 23.5）。
2. **把浮点调用的返回值打进输出** — 它是整数寄存器的残留值，连跑三次给出 `128` / `-1878456768` / `-1869594008`，逐字节比对必挂；只断言布尔结论（23.4）。
3. **用 `File ... exists` 预判库能不能 `dlopen`** — 现代 macOS 系统库在 dyld 共享缓存里，`exists` 是 `false` 但 `open` 照样成功；唯一判据是 `try(... open)`（23.1）。
4. **`open` 之前就 `call`，或用 `forward` 打错函数名** — 都报 `Error resolving call '名字'.`（是"解析不到符号"而非"库没打开"）；先 `open`、并优先用显式 `d call("名字", …)`（23.3 / 23.6）。
5. **一次给 `call` 传超过 8 个参数** — 硬上限 8 个（`Error, too many arguments (9) to call 'abs'.`），而且符号解析排在这条检查之前（23.6）。
6. **把原始槽（如 `List_size()`）取进变量或槽再引用** — 按新接收者执行，直接抛 `CFunction defined for type List but called on type Object`；只能在原接收者上就地用（23.7）。
7. **指望 `setArgumentTypes` / `setReturnType` / `Pointer` / `CString` / `Buffer`** — 本机构建里实测全是 `false`，没有自定义编组的余地（23.7）。
8. **拿 `Sandbox setMessageCount` / `setTimeLimit` 兜失控代码** — 设得进读得出但对执行无效（上限 3 条消息照样跑完 100 次迭代；时间上限挡不住 `while(true, nil)`，离线实测 `rc=124`）（23.8）。
9. **把 `hasSlot(...)` 直接当 `list(...)` 的实参** — VM 卡死在 C 里、只能靠外部超时打断（第 22 章也踩过），先存变量再 `list`（23.7）。
10. **让用户可控的字符串决定 `setPath` 或符号名** — 等于把进程地址空间交出去；路径与符号名必须是代码里的常量白名单，不可信代码用子进程 + 超时隔离（23.8）。


### 第 24 章 · 24 · 实战：一个完整的 Io 程序

1. **用 `do(...)` 把方法局部变量塞进新对象** — `do` 的作用域只到接收者和 `Lobby`，报 `Object does not respond to 'x'`；工厂方法要用 `lexicalDo`，或对空对象 `setSlot`。
2. **`try` 的结果当返回值用** — `try` 成功也返回 `nil`，唯一判据是 `e != nil`，要值就把结果写进外层槽。
3. **`List` 两参迭代写成 `map(v, i, 体)`** — 绑定顺序是「先下标后值」，`map(i, v, 体)` 才对；写反的报错是 `at` 的参数类型不对，离出错点很远。
4. **不传分隔符的 `split`** — 按字节扫空白，中文日志行会被莫名其妙切开；一律写 `split(" ")`。
5. **`asNumber` 的结果不校验** — `"abc" asNumber` 给 `nan`（不是 `0`），而 `nan` 与任何数比较恒走同一边；只写单边 `if(st > 599)` 拦不住它，必须双边兜范围。
6. **`Map at` 缺键给 `nil`** — 计数循环要 `hasKey` 分支，否则 `nil + 1` 直接抛异常。
7. **直接打印 `Map`** — `Map asString` 是带 `0x` 地址的摘要；要输出就 `keys sort` 后自己拼。
8. **`sortBy` 收的不是两参块** — 必须 `sortBy(block(a, b, …))`；写 `sortBy(a, b, 体)` 会报 `Object does not respond to 'a'`。**为什么一定是 `block` 而不是 `method`**：`method` 造的块 `isActivatable = true`，一进形参（形参就是槽）就被零参调用（11.3.1）。
9. **`File setContents` 忘了 `asUTF8`** — 含非 ASCII 的串内部是 UCS4，落盘变成 4 字节一码点的垃圾，读回来全错。
10. **累积变量在块里用 `:=`** — 那是在块里造了个临时槽，外层永远是初值；要改外层必须 `=`。

---

**合计 240 条**（24 章 × 每章 10 条）。
