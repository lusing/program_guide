# 12 · 迭代与集合遍历

> 对应示例：[`examples/12_iteration/12_iteration.io`](../examples/12_iteration/12_iteration.io)

遍历在 Io 里同样只是「给集合发一条消息」。集合收到 `foreach(...)` 之后，
**按实参个数**决定那几个名字怎么绑——这就是 Io 的迭代协议，没有 `Iterator` 接口。
本章还有一条实测出来的大坑：`foreach` 的体能改外层变量，`map` / `select` 的体不能。

## 12.1 `foreach` 的三种形状：名字绑的是值还是下标

```text
-- 12.1 foreach 的三种形状：名字绑的是值还是下标
  foreach(v, ...) 的 v = 10
  foreach(v, ...) 的 v = 20
  foreach(v, ...) 的 v = 30
  foreach(i, v, ...) 的 i / v = 0 / 10
  foreach(i, v, ...) 的 i / v = 1 / 20
  foreach(i, v, ...) 的 i / v = 2 / 30
foreach(只有体) 触发次数 = 3
map(v, v) = list(10, 20, 30)
map(i, v, i) = list(0, 1, 2)
map(i, v, v) = list(10, 20, 30)
list(...) foreach 的返回值 = nil
```

```io
list(10, 20, 30) foreach(v, show("  foreach(v, ...) 的 v", v))
list(10, 20, 30) foreach(i, v, show("  foreach(i, v, ...) 的 i / v", i asString .. " / " .. v asString))

tick := List clone
list(10, 20, 30) foreach(tick append("t"))     // 只有体：跑 3 次，不绑名字
show("foreach(只有体) 触发次数", tick size)

show("map(v, v)", list(10, 20, 30) map(v, v) asString)       // list(10, 20, 30)
show("map(i, v, i)", list(10, 20, 30) map(i, v, i) asString) // list(0, 1, 2)
```

**单名形式的那个名字绑的是「值」，不是下标。** 三种形状的分工是：

| 实参个数 | 形状 | 名字 |
|---|---|---|
| 1 | `foreach(体)` | 不绑名字，只提供体 |
| 2 | `foreach(v, 体)` | 第一个名字 = 元素值 |
| 3 | `foreach(i, v, 体)` | 第一个 = 下标，第二个 = 元素值 |

集合是**数实参个数**来区分的，跟名字叫什么无关——`map(i, v, v)` 仍然拿到值。
另外 `foreach` 自己不返回值（`nil`），它是语句不是表达式；要有结果得用 `map` / `select`。

> **为什么重要**：Io 没有重载、没有可选参数，多态全靠「进来的东西长什么样」。
> `foreach` 的三个形状用的是同一套机制（`call argCount` + `call argAt(i) name`），
> 你自己写的集合也要照这套走，才能和标准库互换。

## 12.2 `while` / `for` / `loop` 与 `break` / `continue`

```text
-- 12.2 while / for / loop 与 break / continue
  while i = 0
  while i = 1
  while i = 2
  for j = 0
  for j = 1
  for j = 2
  for 带步长 j = 0
  for 带步长 j = 2
  for 带步长 j = 4
  for 带步长 j = 6
  loop k = 1
  loop k = 2
  continue 跳过了 3，m = 1
  continue 跳过了 3，m = 2
  continue 跳过了 3，m = 4
  continue 跳过了 3，m = 5
foreach + break 收到 = list(1, 2)
foreach + continue 收到 = list(1, 3, 4)
Break / Continue 的 type = Break / Continue
Break hasSlot("isBreak") = true
Continue hasSlot("isContinue") = true
while 返回最后一轮体的值 = 7
for 不带步长时返回 = nil
```

```io
i := 0
while(i < 3, writeln("  while i = ", i); i = i + 1)

for(j, 0, 2, writeln("  for j = ", j))          // 闭区间 0..2
for(j, 0, 6, 2, writeln("  for 带步长 j = ", j)) // 带步长 0,2,4,6

k := 0
loop(                                            // 死循环 + break
    k = k + 1
    if(k >= 3, break)
    writeln("  loop k = ", k)
)

m := 0
while(m < 5,
    m = m + 1
    if(m == 3, continue)                         // 跳过这一轮
    writeln("  continue 跳过了 3，m = ", m)
)

broken := List clone
list(1, 2, 3, 4) foreach(v, if(v == 3, break); broken append(v))       // list(1, 2)
skipped := List clone
list(1, 2, 3, 4) foreach(v, if(v == 2, continue); skipped append(v))   // list(1, 3, 4)
```

`while(条件, 体)` / `for(变量, 起, 止[, 步长], 体)` / `loop(体)` 都是普通方法，
条件与体都是消息（所以 `while` 每轮重新求值条件）。
`break` 和 `continue` **不是关键字**：`Break` / `Continue` 是 `Core` 里的两个对象，
`break` / `continue` 是返回它们的消息，`break` / `continue` 在 `foreach`（一个 C 原语）里也照用不误。

- `while` 返回最后一轮体的值（例子里的 `7`），`for` 返回 `nil`。
- `for` 的区间是**闭区间**，`for(j, 0, 2, ...)` 会跑 0、1、2。
- 别在循环外裸调 `continue`：本机上 `c := continue; c type` 会打出 Importer 对象的内部结构、`continue type` 直接段错误。

> **为什么重要**：`loop` + `break` 是 Io 里唯一「想退出时退出」的结构；
> 而 `break` / `continue` 之所以能穿过 `foreach` 这种 C 原语，是因为它们只是对象，
> C 原语只要检查返回对象里有没有 `isBreak` / `isContinue` 就够了。

## 12.3 `map` / `select` / `detect` / `reduce`：语义与返回类型

```text
-- 12.3 map / select / detect / reduce：语义与返回类型
src = list(1, 2, 3, 4)
map(v, v * 2) = list(2, 4, 6, 8)
select(v, v % 2 == 0) = list(2, 4)
detect(v, v > 2) = 3
detect(v, v > 9) = nil
reduce(+) = 10
reduce(a, b, a - b) = -8
reduce(a, b, a .. b) = xyz
reverseReduce(a, b, a - b) = -2
调用一圈之后 src 还是 = list(1, 2, 3, 4)
空表 map = list()
空表 select = list()
空表 detect = nil
空表 reduce(+) = nil
```

```io
src := list(1, 2, 3, 4)
show("map(v, v * 2)", src map(v, v * 2) asString)              // list(2, 4, 6, 8)
show("select(v, v % 2 == 0)", src select(v, v % 2 == 0) asString) // list(2, 4)
show("detect(v, v > 2)", src detect(v, v > 2))                 // 3
show("detect(v, v > 9)", src detect(v, v > 9) asString)        // nil
show("reduce(+)", src reduce(+))                               // 10
show("reduce(a, b, a - b)", src reduce(a, b, a - b))           // -8
show("reduce(a, b, a .. b)", list("x", "y", "z") reduce(a, b, a .. b) asString)  // xyz
show("reverseReduce(a, b, a - b)", src reverseReduce(a, b, a - b))              // -2
show("调用一圈之后 src 还是", src asString)                     // list(1, 2, 3, 4)
```

| 方法 | 返回 | 空表时 |
|---|---|---|
| `map(v, 体)` | **新 `List`**（等长） | `list()` |
| `select(v, 体)` | **新 `List`**（命中的） | `list()` |
| `detect(v, 体)` | 命中的**那个元素**（不是表） | `nil` |
| `reduce(二元运算)` / `reduce(a, b, 体)` | 一个标量 | `nil` |
| `reduce` 无初值 | 用第一个元素当累加器，从第二个折起 | — |

几个容易记错的点：`detect` 返回元素本身，没命中给 `nil`（不报错）；
`reduce(+)` 里那个 `+` 是**方法名**，所以可以换成任意一元二元方法；
`reduce(a, b, 体)` 才是任意二元运算的通用写法（例子里的 `-8` 是
`((1-2)-3)-4`）；`reverseReduce` 就是 `reverse` 之后 `reduce`（`-2` 是 `((4-3)-2)-1`）。
这些方法**都不改原表**，要就地改有 `selectInPlace` / `mapInPlace` / `sortInPlace`。

顺带记住：**`List` 上没有 `reject`**，`list(1,2) reject(v, v > 1)` 会抛
`List does not respond to 'reject'`，取反条件交给 `select` 就行。

> **为什么重要**：Io 的集合方法统一走「返回新表 / 就地版本带 InPlace 后缀」这一对；
> 知道这个命名法，`sort` / `select` / `map` / `reverse` 的语义不用背，
> 看一眼有没有 `InPlace` 就知道会不会动原表（`sort` 返回新表、`sortInPlace` 就地）。

## 12.4 大坑：`foreach` 的体改得了外层变量，`map` 的体改不了

```text
-- 12.4 大坑：foreach 的体改得了外层变量，map 的体改不了
foreach 跑完之后 sa = 60
map 跑完之后 sb = 0
而 map 的结果本身是 = list(10, 30, 60)
select 跑完之后 sc = 0
连 1 参的 foreach(体) 也一样看不见 = 0
```

```io
sa := 0
list(10, 20, 30) foreach(v, sa = sa + v)
show("foreach 跑完之后 sa", sa)                 // 60

sb := 0
folded := list(10, 20, 30) map(v, sb = sb + v)
show("map 跑完之后 sb", sb)                     // 0 —— 外面那个 sb 没动
show("而 map 的结果本身是", folded asString)     // list(10, 30, 60)

sc := 0
list(10, 20, 30) select(v, sc = sc + v; true)
show("select 跑完之后 sc", sc)                  // 0

sd := 0
list(10, 20, 30) foreach(sd = sd + 1)
show("连 1 参的 foreach(体) 也一样看不见", sd)     // 0
```

这是本章最值钱的一节。Io 的实现里：

- `foreach(v, 体)` / `foreach(i, v, 体)` 把体放在**你的调用帧**里跑，所以 `sa = sa + v` 真的改到了外层的 `sa`。
- `map` / `select` / `detect` / `reduce`（还有 **1 参的 `foreach(体)`**）会先造一个
  `context := Object clone prependProto(call sender)`，把体放在这个**临时 context** 上跑。
  `sb = sb + v` 于是只是在这个临时对象上建/改了一个 `sb`，你的 `sb` 从头到尾是 0。
- 那个临时 context 在一次 `map` 内部是**共享的**：三个元素依次 `+10 +20 +30`，
  所以 `map` 的结果本身就是累加和 `list(10, 30, 60)`——看起来像个 `reduce`，
  但这纯属副作用，不该依赖。

想借遍历做事（累加、计数、往另一个表里塞东西），两条路：用 `foreach`，
或者往一个**容器对象**里塞（`out append(v)` 是对对象发消息，不受 context 影响）。

> **为什么重要**：这条决定了你在 Io 里写「边遍历边攒」的代码时该选哪个消息。
> 把 `map` 当 `foreach` 用是可以的（你只是想借循环），但**别指望体能写回外层**；
> 把 `foreach` 当 `map` 用则完全不行（它不返回结果）。

## 12.5 遍历时改集合会怎样

```text
-- 12.5 遍历时改集合会怎样
删掉 3 之后 l = list(1, 2, 4, 5)
这一轮实际访问到的元素 = list(1, 2, 3, 5)
一边遍历一边 append 之后的 grow = list(1, 2, 3, 101, 102, 103, 201, 202, 203, 301, 302)
迭代了多少次 = 9
```

```io
l := list(1, 2, 3, 4, 5)
seen := List clone
l foreach(i, v,
    seen append(v)
    if(v == 3, l removeAt(i))        // 遍历中删除
)
show("删掉 3 之后 l", l asString)            // list(1, 2, 4, 5)
show("这一轮实际访问到的元素", seen asString)  // list(1, 2, 3, 5) —— 4 被跳过了

grow := list(1, 2, 3)
steps := 0
grow foreach(v,
    steps = steps + 1
    if(steps > 8, break)             // 必须自己加护栏
    grow append(v + 100)             // 遍历中追加
)
show("一边遍历一边 append 之后的 grow", grow asString)
show("迭代了多少次", steps)                    // 9
```

- **遍历中删除**：`foreach` 按下标推进，删掉当前元素之后后面的元素整体前移一格，
  于是下一个元素被跳过（例子里的 `4` 从头到尾没被访问过）。不报错、不崩，只是静默漏掉。
- **遍历中追加**：这一轮循环**看得见**新加的元素（`foreach` 每轮重新读长度），
  于是表会一直长、停不下来。这类循环一定要自己写 `break` 护栏。
- 想安全删除：先收集下标，循环结束后统一 `removeAt`；或者用 `select` / `reject` 式的「造新表」。

> **为什么重要**：Io 的 `foreach` 是**活的**游标，不是快照。
> 有语言会在遍历时复制或者直接报错，Io 两样都不做——它只保证「不崩」，
> 剩下的正确性归你。

## 12.6 造序列：`List with` / `Number repeat` / 游标

```text
-- 12.6 造序列：List with / Number repeat / 游标
List with(1, 2, 3) = list(1, 2, 3)
List hasSlot("range") = false
List 上带生成意味的槽 = list("with")
Number 上带生成意味的槽 = list("repeat")
  3 repeat i = 0
  3 repeat i = 1
  3 repeat i = 2
5 repeat 之后 total = 10
cursor type = ListCursor
一开始 cur value = 10
next 一次之后 cur value = 20
再 next 一次之后 cur value = 30
走到头的 next = false
```

```io
show("List with(1, 2, 3)", List with(1, 2, 3) asString)      // list(1, 2, 3)
show("List hasSlot(\"range\")", List hasSlot("range"))         // false —— 没有 range

3 repeat(i, writeln("  3 repeat i = ", i))                    // 0, 1, 2
total := 0
5 repeat(i, total = total + i)                                // 0+1+2+3+4
show("5 repeat 之后 total", total)                             // 10

cur := list(10, 20, 30) cursor
show("cursor type", cur type)                                 // ListCursor
show("一开始 cur value", cur value)                            // 10
show("next 一次之后 cur value", (cur next; cur value))          // 20
show("再 next 一次之后 cur value", (cur next; cur value))       // 30
show("走到头的 next", cur next)                                // false
```

生成序列在这里只有两块砖：`List with(...)` 直接列出来，`Number repeat(i, 体)` 按次数循环。
**`List` 上没有 `range`**（`List hasSlot("range")` 是 `false`，`Number` 上也没有 `to`）；
要 0..n 就 `n repeat(i, ...)` 或 `n repeat(i, out append(i))`。

想「一遍走一遍自己决定下一步」，用游标 `List cursor`：
`ListCursor` 的槽是 `collection / index / value / next / previous / insert / remove`。
游标造出来就停在第一个元素上（`value` 直接可读），`next` 往前走，
**走不动了返回 `false`**（不抛异常），所以它天生适合 `while(cur next, ...)` 这种写法。
另外 `List` 上还有 `foreach` / `reverseForeach` 这类按方向的遍历，没有 `nextWhile` 这个名字。

> **为什么重要**：Io 没有 Python 那样的生成器语法，要「惰性」得靠游标或协程（12.8 结尾）。
> 先用 `repeat` + 容器把序列造出来，是这一章里最省事的做法。

## 12.7 `Sequence` 的遍历：`split` 拿到什么，`foreach` 给的是什么

```text
-- 12.7 Sequence 的遍历：split 拿到什么，foreach 给的是什么
split 的返回类型 = List
split(",") 的结果 = list("a", "b", "c")
  一个 part = a
  一个 part = b
  一个 part = c
"a,,c" split(",") = list("a", "", "c")
"a,,c" splitNoEmpties(",") = list("a", "c")
逐个遍历 "abc" 收到的东西 = list(97, 98, 99)
它们的 type = Number
要字符得自己转 = a
```

```io
parts := "a,b,c" split(",")
show("split 的返回类型", parts type)          // List
show("split(\",\") 的结果", parts asString)    // list("a", "b", "c")
parts foreach(p, show("  一个 part", p))

show("\"a,,c\" split(\",\")", "a,,c" split(",") asString)               // list("a", "", "c")
show("\"a,,c\" splitNoEmpties(\",\")", "a,,c" splitNoEmpties(",") asString)  // list("a", "c")

chars := List clone
"abc" foreach(i, c, chars append(c))
show("逐个遍历 \"abc\" 收到的东西", chars asString)   // list(97, 98, 99) —— 是码点，不是字符
show("它们的 type", (chars at(0)) type)              // Number
show("要字符得自己转", (chars at(0)) asCharacter)     // a
```

- `Sequence split(sep)` 返回 **`List`**，里面装的是切出来的子串，空段**保留**
  （`"a,,c"` → `list("a", "", "c")`）；要丢掉空段用 `splitNoEmpties`。
- `Sequence` 自己的 `foreach` 交出来的是**元素/码点**，不是「字符对象」：
  `"abc"` 是 `uint8` 序列，所以拿到 `97, 98, 99`；`c asCharacter` 才是 `a`。
  这和第 04 章讲的「字符串其实是数字序列」是同一件事。
- 想按行读文件是另一套：`File` 上有 `foreachLine`（见第 14 章）。

> **为什么重要**：`split` 之后你拿到的已经是普通 `List`，后面 12.1–12.5 的所有规矩
> 全部适用；但如果你直接对字符串 `foreach`，拿到的是字节/码点——
> 这两条路的元素类型不一样，混用是文本处理章节（16 章）最常见的错误来源。

## 12.8 自定义可迭代对象：协议靠消息，不靠接口

```text
-- 12.8 自定义可迭代对象：协议靠消息，不靠接口
bag size = 3
bag foreach(v, ...) 收到 = list("甲", "乙", "丙")
list(...) foreach(v, ...) 收到 = list("甲", "乙", "丙")
bag foreach(i, v, ...) 收到 = list("0:甲", "1:乙", "2:丙")
bag foreach(只有体) 触发次数 = 3
在自定义 foreach 里给外层变量赋值之后 acc = 0
换成 List foreach 同样写法之后 acc = 2
Coroutine hasSlot("yield") = true
File hasSlot("foreachLine")（逐行读，见第 14 章） = true
```

```io
Bag := Object clone do(
    items := nil
    init := method(items = List clone; self)
    add := method(x, items append(x); self)
    size := method(items size)
    foreach := method(
        n := call argCount                     // 数实参个数，照 12.1 的表分发
        ctx := Object clone prependProto(call sender)   // 体的外围作用域
        if(n == 1,
            body := call argAt(0)
            items foreach(x, ctx doMessage(body))
        ,
            if(n == 2,
                eName := call argAt(0) name
                body := call argAt(1)
                items foreach(x, ctx setSlot(eName, x); ctx doMessage(body))
            ,
                iName := call argAt(0) name
                eName := call argAt(1) name
                body := call argAt(2)
                idx := -1
                items foreach(x,
                    idx = idx + 1
                    ctx setSlot(iName, idx)
                    ctx setSlot(eName, x)
                    ctx doMessage(body)
                )
            )
        )
        self
    )
)

bag := Bag clone init
bag add("甲"); bag add("乙"); bag add("丙")

bagOut := List clone
bag foreach(v, bagOut append(v))
listOut := List clone
list("甲", "乙", "丙") foreach(v, listOut append(v))
show("bag foreach(v, ...) 收到", bagOut asString)      // 和下一行一样
show("list(...) foreach(v, ...) 收到", listOut asString)

idxOut := List clone
bag foreach(i, v, idxOut append(i asString .. ":" .. v asString))   // list("0:甲", "1:乙", "2:丙")

tick := List clone
bag foreach(tick append("tick"))
show("bag foreach(只有体) 触发次数", tick size)          // 3
```

`Bag` 没有继承 `List`，也没实现任何接口，只是**回得了 `foreach` 这个形状的消息**，
于是同一个 `foreach(v, ...)` 在它和 `List` 上给出同样的结果。
这就是「协议靠消息，不靠接口」：Io 里没有 `Interface` / trait 这套东西，
一个对象能不能被遍历，取决于你问它的时候它回不回得了。

两个要写在旁边看的注记：

1. **手写的 Io 级 `foreach` 和 `map` 一样**：体跑在临时 context 上，
   所以例子最后 `acc = acc + 1` 在自定义 `foreach` 里是 0，换到 `List foreach`
   才是 2。想做到和 `List foreach` 完全一致的写入语义，就不能用 context 方案。
   这是 Io 级实现和 C 原语实现的实际差别。
2. **同一条消息对象不要一会儿发给自定义对象、一会儿发给 `List`。** 实测：写一个
   `eachOf := method(c, c foreach(v, ...))` 的包装方法，先 `eachOf(bag)` 再
   `eachOf(list(...))`，第二次会报 `Object does not respond to 'v'`；
   拆成两个方法，或者每次用 `Message fromString(...)` 现造一条消息，就正常。
   可以理解为「一条消息的分派结果是挂在消息对象上的」。

最后是一句预告：本章所有遍历都是「走一步、停一步」的同步循环。
真正要做惰性序列（无限表、流式读）要靠协程——`Coroutine hasSlot("yield")` 是 `true`，
`yield` 能让出一个值之后再原地接着跑，第 18 章展开。

> **为什么重要**：在 Io 里「可迭代」不是一个类型，而是一条消息的形状。
> 你写库的时候只需要把 `foreach(体)` / `foreach(v, 体)` / `foreach(i, v, 体)`
> 这三个形状都接住，别人写的泛型代码就能直接吃你的对象——
> 代价是没有编译期检查，形状接错只有跑到那里才知道。

## 12.9 坑位清单

1. **`foreach(v, ...)` 里把 `v` 当下标用** → 2 参时 `v` 是元素值，要下标写 3 参的 `foreach(i, v, ...)`。
2. **`foreach(体)` 里给外层变量赋值以为能看见** → 1 参形式的体跑在临时 context 上，赋值出不去；要 `foreach(v, 体)` 才绑进调用帧。
3. **在 `map` / `select` / `detect` / `reduce` 的体里写 `acc = acc + x` 攒值** → 这些体也跑在临时 context 上，外层 `acc` 不变；攒值请用 `foreach` 或往容器里 `append`。
4. **把 `map` 的结果当成一次普通映射** → 体里若有对外层变量的赋值，会因为 context 内部共享而变成累加和，别依赖。
5. **以为 `reduce(0, +)` 是「带初值的 reduce」** → 2 参形式会在调用者上下文里求值最后一个参数，`reduce(0, +)` 直接抛 `Object does not respond to '+'`；任意二元运算写 `reduce(a, b, 体)`。
6. **以为 `detect` 没命中会报错** → 返回 `nil`（空表同样），要自己判 `isNil`。
7. **想用 `reject` 取反** → `List` 上没有 `reject`，会抛 `List does not respond to 'reject'`，用 `select` 写反条件。
8. **在 `map` 的体里 `continue`** → 那一格会以 `nil` 的形式留在结果表里，不会从结果里消失。
9. **在 `foreach` 里 `removeAt` 当前元素** → 下标错位、后面的元素被静默跳过；想安全删除就先收集下标、循环结束后再删。
10. **在 `foreach` 里 `append`** → 这一轮循环看得见新元素，表会一直长，必须自己写 `break` 护栏。

---

上一章：[11 · 块与闭包](11-blocks.md) · 下一章：[13 · 异常与错误处理](13-exceptions.md)
