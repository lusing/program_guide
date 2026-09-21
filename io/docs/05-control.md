# 05 · 控制流：没有 if，只有消息

> 对应示例：[`examples/05_control/05_control.io`](../examples/05_control/05_control.io)

Io 里 `if` / `while` / `for` / `and` / `or` **都不是语法关键字，而是方法**。
它们之所以看起来像语法，是因为消息的参数本身就是**消息树**：`if` 拿到的是两棵
没求值的树，于是可以选择只求值其中一棵——短路、少算分支、`break`/`continue`
全都由这个机制支撑。这一章把真值、分支、循环、返回值的规则一次讲清。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 5.1 真值：只有 nil 和 false 是假

```text
-- 5.1 真值：只有 nil 和 false 是假
if(nil,   "真", "假") = 假
if(false, "真", "假") = 假
if(0,     "真", "假") = 真
if("",    "真", "假") = 真
if(空list,"真", "假") = 真
```

```io
show("if(nil,   \"真\", \"假\")", if(nil, "真", "假"))
show("if(false, \"真\", \"假\")", if(false, "真", "假"))
show("if(0,     \"真\", \"假\")", if(0, "真", "假"))
show("if(\"\",    \"真\", \"假\")", if("", "真", "假"))
show("if(空list,\"真\", \"假\")", if(list(), "真", "假"))
chk("0 是真值（C 程序员头号坑）", if(0, "真", "假"), "真")
chk("空串也是真值", if("", "真", "假"), "真")
```

结论：假值**只有两个**——`nil` 和 `false`。`0`、`""`、空列表、空映射
全都是**真值**。判定规则是「必须是 `nil` 或 `false` 才算假」，而不是 C 的「非零即真」。

> **为什么重要**：这条规则让 Io 的判定逻辑变得极端可预测（不需要记住每个类型的
> 空值语义），代价是从 C / Python / JavaScript 过来的人会写出
> `if(nums size, ...)` 这种「以为空集合是假」的代码。数值、串、集合的空判定
> 一律要**显式**写：`if(x size == 0, ...)`。

## 5.2 if 的三种写法

```text
-- 5.2 if 的三种写法
两臂式：x > 5
then/else 式：大
单臂式没有 else 也合法：ok
if(cond, a, b) 是表达式 = yes
if(true,  "yes") = yes
if(false, "yes") = false
if(nil,   "yes") = false
```

```io
x := 7
if(x > 5, writeln("两臂式：x > 5"), writeln("两臂式：x <= 5"))
if(x > 5) then(writeln("then/else 式：大")) else(writeln("then/else 式：小"))
writeln("单臂式没有 else 也合法：", if(x > 5, "ok"))
show("if(cond, a, b) 是表达式", if(x > 5, "yes", "no"))
show("if(true,  \"yes\")", if(true, "yes"))
show("if(false, \"yes\")", if(false, "yes"))
show("if(nil,   \"yes\")", if(nil, "yes"))
chk("if 有返回值", if(x > 5, 1, 2), 1)
chk("两参 if 为假时返回假值本身，不是 nil", if(false, "yes"), false)
```

结论：`if` 有三种形态，都合法：

1. 两臂式：`if(cond, thenMsg, elseMsg)`——两个分支都是消息，只求值一个。
2. then/else 式：`if(cond) then(a) else(b)`——同一条消息链，读起来更像语句。
3. 单臂式：`if(cond, thenMsg)`——没有 else。

关键是**返回值**：`if` 是被选中的那个分支的值，所以能当三元运算符用
（`if(x > 5, "yes", "no")` 得 `"yes"`）。而单臂式等价于 `cond and(thenMsg)`，
为假时返回的是**那个假值本身**：`if(false, "yes")` 给 `false`，`if(nil, "yes")`
也给 `false`（不是 `nil`，因为 `nil and(...)` 走的是 `Nil` 上那个值为 `false` 的槽，
见 5.4）。所以单臂式的返回值只适合「真则用结果、假则当假值用」的场合。

> **为什么重要**：`if` 有返回值意味着「语句」和「表达式」在这里没有分界。
> 但别把它的返回值当成可靠的布尔：`if(false, x)` 拿到的是 `false`，
> `if(nil, x)` 拿到的也是 `false`——两个不同的假值被归一化成了 `false`。

## 5.3 if 只求值被选中的分支

```text
-- 5.3 if 只求值被选中的分支
下面只会打印被选中那一边的『求值了':
  求值了 then 分支
  求值了 唯一被调用的
```

```io
side := method(tag, writeln("  求值了 ", tag); tag)
writeln("下面只会打印被选中那一边的『求值了':")
if(true, side("then 分支"), side("else 分支"))
chk("未选中的分支不求值", side("唯一被调用的"), "唯一被调用的")
```

结论：`if(true, side("then 分支"), side("else 分支"))` 只打印了 `then 分支` 一行。
未被选中的那一支**完全没有被求值**（连消息都没发出去），所以它可以包含
副作用、甚至包含会报错的表达式。这就是「控制流是方法但还能短路」的全部秘密：
参数以**消息树**的形式传进来，谁求值、求值几次，由方法自己决定。

注意输出第三行 `求值了 唯一被调用的` 是 `chk` 的参数求值产生的，不是 `if` 干的。

> **为什么重要**：理解「参数是消息树，不是值」之后，`if`、`while`、`and`、
> `&&`、`try` 全都变成同一类东西（选择性求值的消息接收者）。
> 这也是 Io 能完全没有语法关键字的原因。

## 5.4 and / or 短路，not 是槽不是方法

```text
-- 5.4 and / or 短路，not 是槽不是方法
true and false = false
true or false = true
true not = false
nil not = true
Object not（普通对象取反给 nil） = nil
false and(true) = false
false and(noSuchSlot) = false
true or(noSuchSlot) = true
```

```io
show("true and false", true and false)
show("true or false", true or false)
show("true not", true not)
show("nil not", nil not)
show("Object not（普通对象取反给 nil）", Object clone not)
show("false and(true)", false and(true))
show("false and(noSuchSlot)", false and(noSuchSlot))
show("true or(noSuchSlot)", true or(noSuchSlot))
chk("and 短路，右边不存在的槽不会报错", false and(noSuchSlot), false)
chk("or 短路", true or(noSuchSlot), true)
```

结论：`and` / `or` 都在 `OperatorTable` 里（优先级 10 和 11），也都能写成
`and(消息)` 的形式。短路是真的短路：`false and(noSuchSlot)` 里那个不存在的槽
**根本不会被求值**，所以不报错、直接给 `false`。

短路是怎么做到的？把槽挖出来看就明白了（下面这组是单独 dump 出来的定义，不在
示例的判定区间内）：

```text
false getSlot("and")   → false          （False 上的值槽，实参消息永不求值）
nil  getSlot("and")    → false          （Nil 上同理）
Object getSlot("or")   → true           （⚠️ 也是值槽，不是方法！见下）
Object getSlot("and")  → method(v, v isTrue)      # Object.io:206
true  getSlot("or")    → true           （True 上同样是值槽）
```

也就是说**假值一侧压根不靠求值短路，而是靠「值槽 + 惰性实参」短路**：
接收者上有一个值为 `false` 的 `and` 槽，发消息时命中的是非可激活的值，
于是实参消息连求值的机会都没有。只有落到 `Object` 的 `and` 上（比如 `5 and(true)`）
才走真正的 `method(v, v isTrue)` 实现。

**这里有个反直觉的不对称，值得单独记一笔。** `Object` 的 `or` 槽在
`libs/iovm/io/Object.io` 里是这么写的（第 203 行）：

```io
//doc Object or(arg) Returns true.
setSlot("or", true)
```

`setSlot("or", true)` ——它是个**值槽**，值就是布尔 `true`，压根不是方法。
后果是：**对非假值对象发 `or`，实参连求值都不会发生，结果恒为 `true`。**
实测（单独 dump，不在示例判定区间内）：

```text
Object getSlot("or") = true    type=true          ← 值槽，不是 Block
probe or(side := side + 1) = true                 ← 结果恒 true
副作用发生了吗（side） = 0                          ← 表达式根本没跑
probe and(side := side + 1) = true                ← 换成 and 就会跑
这次 side = 1
```

`and` 是方法（`method(v, v isTrue)`），所以它必须求值实参；`or` 是值槽，
所以它不求值。**两者都「短路」，但短路的方式不是一回事**——
一个靠「值槽 + 惰性实参」，一个靠「进了方法体才求值」。

`not` 则是一个**普通槽**（不在 `OperatorTable` 里，也没有 `not(...)` 的写法）：
`True not` 是 `false`、`False not` 是 `true`、`Nil not` 是 `true`，
而 `Object getSlot("not")` 的值是 `nil`——所以**任意普通对象取反得到的是 `nil`**，
不是 `false`。别拿它当布尔运算的收尾。

> **为什么重要**：`x not` 只在布尔/`nil` 上有意义。要写「某对象为假」的判断，
> 用 `if(x, ...)` 或 `x == nil`，不要写 `not`——它给 `nil` 而不是 `false`，
> 会继续往上传一层脏数据。
> 同理，**`or` 的右边只该放「求值无副作用的表达式」**：在真值对象上它永远不会跑，
> 你写的那句初始化/累加会静默消失。

## 5.5 ifTrue / ifFalse / ifNil / ifNilEval

```text
-- 5.5 ifTrue / ifFalse / ifNil / ifNilEval
(1 > 0) ifTrue("是") = true
(1 < 0) ifTrue("是") = false
(1 < 0) ifFalse("否") = false
nil ifNil("d") = nil
nil ifNilEval("d") = d
5 ifNilEval("d") = 5
5 ifNonNilEval("d") = d
nil ifNonNilEval("d") = nil
v ifNilEval(v = ...) 之后 = 补上的默认值
```

```io
show("(1 > 0) ifTrue(\"是\")", (1 > 0) ifTrue("是"))
show("(1 < 0) ifTrue(\"是\")", (1 < 0) ifTrue("是"))
show("(1 < 0) ifFalse(\"否\")", (1 < 0) ifFalse("否"))
show("nil ifNil(\"d\")", nil ifNil("d"))
show("nil ifNilEval(\"d\")", nil ifNilEval("d"))
show("5 ifNilEval(\"d\")", 5 ifNilEval("d"))
show("5 ifNonNilEval(\"d\")", 5 ifNonNilEval("d"))
show("nil ifNonNilEval(\"d\")", nil ifNonNilEval("d"))
v := nil
v ifNilEval(v = "补上的默认值")
show("v ifNilEval(v = ...) 之后", v)
```

结论：这一族方法的名字起得让人误判，必须逐个记：

| 写法 | 返回值 | 实参会不会被求值 |
|---|---|---|
| `bool ifTrue(x)` / `bool ifFalse(x)` | **接收者本身**（那个布尔） | 条件成立时求值 |
| `nil ifNil(x)` / `5 ifNonNil(x)` | **接收者本身** | 触发时求值 |
| `nil ifNilEval(x)` | `x` 的值（`d`） | 是 |
| `5 ifNilEval(x)` | 接收者（`5`） | 否 |
| `5 ifNonNilEval(x)` | `x` 的值（`d`，反直觉！） | 是 |
| `nil ifNonNilEval(x)` | 接收者（`nil`） | 否 |

三条要点：

1. `ifTrue` / `ifFalse` **返回的是接收者，不是分支结果**：`(1 > 0) ifTrue("是")` 是
   `true`，不是 `"是"`。而且它们只长在 `true` / `false` 上——不能为了拿默认值去用
   `nil ifNil` 的亲戚 `nil ifTrue`（那会直接
   `Exception: nil does not respond to 'ifTrue'`）。要「条件成立时取一个值」，用
   `if`、`and` / `or`，或者下面这对 `...Eval`。
2. `ifNil` **只负责触发/不触发，返回值恒是接收者**：`nil ifNil("d")` 给 `nil`。
   想要默认值，必须用 **`ifNilEval`**：`nil ifNilEval("d")` 给 `"d"`，
   而 `5 ifNilEval("d")` 里那个 `"d"` **连求值都没有**（惰性），直接返回 `5`。
   第 9 行是标准用法：`v ifNilEval(v = "补上的默认值")`，只在 `v` 是 `nil` 时赋值。
3. `ifNonNilEval` **是非对称的**：非 `nil` 时它返回**实参的值**（`5 ifNonNilEval("d")`
   给 `"d"`），而不是接收者。当「有就走一段逻辑、结果由那段逻辑决定」用时它是方便的，
   但当「有就用它自己」用时它是错的——那种场合老老实实写 `if(x != nil, x, ...)`。

> **为什么重要**：`ifNil` 与 `ifNilEval` 这一字之差，是本仓库最早踩到的坑之一
> （「明明写了默认值，结果还是 `nil`」）。记住口诀：**带 `Eval` 的才求值并返回实参，
> 不带 `Eval` 的一律返回接收者。**

## 5.6 while / for / loop

```text
-- 5.6 while / for / loop
012  ← while 循环体写成一条消息链，多条语句用 ;
1 2 3   ← for(j, 1, 3) 打了 3 次
loop1 loop2   ← loop 是无条件循环，靠 break 出来
```

```io
i := 0
while(i < 3, write(i); i = i + 1)
writeln("  ← while 循环体写成一条消息链，多条语句用 ;")
for(j, 1, 3, write(j, " "))
writeln("  ← for(j, 1, 3) 打了 3 次")
k := 0
loop(k = k + 1; if(k >= 3, break); write("loop", k, " "))
writeln("  ← loop 是无条件循环，靠 break 出来")
chk("while 打到条件不成立", i, 3)
chk("for 上界闭区间，共 3 次", k, 3)
```

结论：三个循环各有一条必须记住的规矩：

- `while(cond, body)`——`body` 是**一条消息链**，多条语句用 `;` 分隔。
- `for(j, 1, 3, body)`——上界是**闭区间**：这一句打 `1 2 3` 共三次，不是 C 的
  `j < 3`。
- `loop(body)`——无条件循环，只能靠 `break` 出来。

> **为什么重要**：`for` 的闭区间是 Io 与 C 系最大的语法性差异之一。
> 凡是「用别人的循环上界」写出来的下标运算，都要先用 `1..3` 这种小例子验一遍
> 到底是几次。

## 5.7 for 的四参形式与 break / continue

```text
-- 5.7 for 的四参形式与 break / continue
0 2 4 6 8   ← for(j, 起点, 终点, 步长)
跳过 2、遇到 4 就停 = list(0, 1, 3)
```

```io
for(j, 0, 9, 2, write(j, " "))
writeln("  ← for(j, 起点, 终点, 步长)")
acc := List clone
for(j, 0, 5, if(j == 2, continue); if(j == 4, break); acc append(j))
show("跳过 2、遇到 4 就停", acc)
chk("continue / break 都不求值剩余部分", acc asString, "list(0, 1, 3)")
```

结论：`for` 有**四参形式** `for(i, start, end, step, body)`——注意步长插在 body 前面。
`continue` 与 `break` 都是消息，作用范围是**当前循环体**：`if(j == 2, continue)`
之后的语句不再执行（所以 2 没进 `acc`），`if(j == 4, break)` 直接结束整个循环
（所以 4、5 都没进）。

结果 `list(0, 1, 3)` 正好是「跳过了 2、在 4 停下」的证据。

> **为什么重要**：`break` / `continue` 能让剩余语句「不求值」，靠的还是 5.3 的
> 消息树机制。理解这点之后，「为什么不用 `return` 也能跳出本次迭代」就不再是魔法。

## 5.8 return 与循环的返回值

```text
-- 5.8 return 与循环的返回值
findFirst(list(5,6,7), 6) = 1
findFirst(list(5,6,7), 99) = -1
方法返回值 = 最后一个表达式 = list(1, 2, 3)
```

```io
findFirst := method(items, target,
    items foreach(ix, v, if(v == target, return ix))
    -1
)
show("findFirst(list(5,6,7), 6)", findFirst(list(5, 6, 7), 6))
show("findFirst(list(5,6,7), 99)", findFirst(list(5, 6, 7), 99))
last := method(list(1, 2, 3))
show("方法返回值 = 最后一个表达式", last)
chk("return 从方法里跳出", findFirst(list(5, 6, 7), 6), 1)
```

结论：`return` 是**方法级**的跳转：写在 `foreach` 的块里也能直接穿出整个方法
（`findFirst` 找到就返回下标，没找到才走到最后一行 `-1`）。
没有 `return` 时，**方法体的最后一个表达式就是返回值**——`last` 的定义体只有
`list(1, 2, 3)` 一项，返回的就是这个列表本身。

> **为什么重要**：「最后一个表达式即返回值」让 Io 的方法天然是表达式风格，
> 也解释了为什么示例里的 `chk` / `show` 都敢直接用返回值。
> 需要提前退出时才用 `return`，其余场合别写多余的 `return`。

## 5.9 switch：接收者为键的查表控制流

```text
-- 5.9 switch：接收者为键的查表控制流
code switch(...) = 香蕉
```

```io
code := "b"
result := code switch(
    "a", "苹果",
    "b", "香蕉",
    "c", "樱桃",
    "未知"
)
show("code switch(...)", result)
chk("switch 命中分支", result, "香蕉")
chk("switch 落空返回兜底值", "z" switch("a", "苹果", "兜底"), "兜底")
```

结论：`switch` 是**接收者为键、实参成对给出**的查表式分支：键在前、值在后，
**最后一个落单的实参是兜底值**。`"b" switch("a", "苹果", "b", "香蕉", ..., "未知")`
命中 `"b"` 给 `"香蕉"`；键都不匹配时给兜底值（`"z" switch("a", "苹果", "兜底")`
给 `"兜底"`）。

它的比较是**相等**语义，所以键可以是字符串、数字、符号等任何可比较的值——
比一长串 `if/else if` 更好读。

> **为什么重要**：`switch` 的实参个数是**奇数**（成对 + 兜底）——这是它与
> 「成对参数」的所有其他消息最不一样的地方。忘了兜底值，落空时返回值就不可控了。

## 5.10 ?消息：能响应才发

```text
-- 5.10 ?消息：能响应才发
o ?greet = 你好
o ?noSuchSlot = nil
```

```io
o := Object clone do(greet := method("你好"))
show("o ?greet", o ?greet)
show("o ?noSuchSlot", o ?noSuchSlot)
chk("? 对不存在的槽返回 nil，不报错", o ?noSuchSlot, nil)
chk("? 对存在的槽照常调用", o ?greet, "你好")
```

结论：`?消息` 是「对象没有这个槽就返回 `nil`，不抛异常」。它的实现只有几行
（单独 dump 出来的定义，不在示例的判定区间内）：

```text
?  = method(
        setSlot("m", call argAt(0)) ;
        if(m isNil, return(nil)) ;
        if(self getSlot(m name) != (nil),
            call relayStopStatus(m doInContext(self, call sender)),
            nil)
     )
```

把它读一遍，行为就全透明了：先把**实参当消息对象**抓下来（`call argAt(0)`，
这正是「参数是消息树」的又一次体现），取出它的名字 `m name`，用 `getSlot`
在接收者上查一遍；**查得到（且值不是 `nil`）就在接收者上下文里重新发一次**，
查不到就返回 `nil`。所以 `?` 既不是 `try/catch` 也不是类型判断，
而是「**先探测再发送**」，且探测走的是同一条 proto 链查找。

> **为什么重要**：`?` 是 Io 里唯一「安全发送」；它和 `hasSlot` 一起
> 组成了本语言的可选调用风格（没有 `respondsTo` 这种东西，用 `hasSlot`）。
> 用它替代 `try(o noSuchSlot)`，既便宜又不会吞掉真正的异常。

## 5.11 坑位清单

1. **把 `0` 当假** → 假值只有 `nil` 和 `false`，`0`、`""`、空列表全为真。
2. **以为 `if(false, x)` 返回 `nil`** → 单臂式等价于 `cond and(x)`，返回假值本身 `false`；`nil` 那支也归一成 `false`。
3. **给 `if` 的分支里放必炸的表达式** → 未选中的分支不会被求值，可以放心放副作用。
4. **写 `nil ifTrue(x)` 求默认值** → `ifTrue` / `ifFalse` 只长在布尔上，`nil` 调用直接报不响应。
5. **`ifTrue` / `ifNonNilEval` 的返回值方向和直觉相反** → `ifTrue` 返回接收者（那个布尔），要结果用 `if` 或 `and`；`ifNonNilEval` 在非 nil 时返回的是**实参的值**（方向与 `ifNilEval` 相反）。
6. **用 `ifNil` 取默认值** → `ifNil` 只返回接收者，取默认值必须用 `ifNilEval`。
7. **把 `for(j, 1, 3)` 当 C 的 `j < 3`** → 上界是闭区间，会循环 3 次。
8. **用 `loop` 却没写 `break`** → 无条件循环不会自己停，示例必须包着超时跑。
9. **以为 `and` 和 `or` 结构对称** → `and` 是方法（必须求值实参），`or` 在非假值对象上是**值槽** `true`（`setSlot("or", true)`），实参连求值都不发生、结果恒 `true`；`or` 右边只放无副作用的表达式。
10. **拿 `x not` 判断「对象为假」** → `not` 是值槽，`Object` 上那份是 `nil`，普通对象取反给 `nil` 而不是 `false`；要判断用 `if(x, ...)` 或 `x == nil`。

---

上一章：[04 · 序列：字节串、码点串与不可变字面量](04-sequences.md) · 下一章：[06 · 消息：三种形状与优先级](06-messages.md)
