# 07 · 原型：克隆、槽与 proto 链

> 对应示例：[`examples/07_prototypes/07_prototypes.io`](../examples/07_prototypes/07_prototypes.io)

Io 没有类。对象由**克隆**已有对象产生，行为存在**槽**里，名字查找沿 **proto 链**
向上走，写入落在最近的那个副本上。这一章把三件事钉死：克隆的两个变体、
三个槽操作符的分工、以及「读走链、写本地」带来的遮蔽语义。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 7.1 从 Object clone 出一个对象

```text
-- 7.1 从 Object clone 出一个对象
Dog name = 未命名
Dog speak = 汪汪，未命名
d1 name = 阿黄
Dog name 不受影响 = 未命名
```

```io
Dog := Object clone
Dog name := "未命名"
Dog speak := method("汪汪，" .. name)
show("Dog name", Dog name)
show("Dog speak", Dog speak)
d1 := Dog clone
d1 name = "阿黄"
show("d1 name", d1 name)
show("Dog name 不受影响", Dog name)
chk("写副本不污染原型", Dog name, "未命名")
chk("副本读得到原型的方法", d1 speak, "汪汪，阿黄")
```

结论：造对象就是 `Object clone`，加行为就是往副本上放槽：

- `Dog := Object clone`：得到一个原型对象，命名为 `Dog`。
- `Dog name := "未命名"`：`:=` 定义槽。
- `Dog speak := method("汪汪，" .. name)`：方法里直接写 `name`，它会**先在
  `self`（接收者）上找**——所以 `d1 speak` 用的是 `d1` 的 `name`。
- `d1 := Dog clone`：克隆得到**独立的槽空间**。`d1 name = "阿黄"` 只改 `d1`
  自己（注意这里用的是 `=`，因为 `name` 已经能从链上找到），`Dog name` 仍是 `未命名`。

> **为什么重要**：克隆 = 浅拷贝 + 各自独立的顶层槽表。原型能当「模板」用，
> 是因为副本的写入不会回流到原型——这正是类-实例关系在原型语言里的替代品。

## 7.2 三种槽操作符

```text
-- 7.2 三种槽操作符
:= 定义后 o x = 1
= 更新后 o x = 2
::= 生成的 setter 名单 = list("setY")
setY 之后 o y = 9
newSlot("z", 3) 之后 = list(3, true)
```

```io
o := Object clone
o x := 1
show(":= 定义后 o x", o x)
o x = 2
show("= 更新后 o x", o x)
o y ::= 0
show("::= 生成的 setter 名单", o slotNames select(name, name beginsWithSeq("set")) sort)
o setY(9)
show("setY 之后 o y", o y)
o newSlot("z", 3)
show("newSlot(\"z\", 3) 之后", list(o z, o hasSlot("setZ")) asString)
```

结论：三个操作符分工明确，另外还有一个显式 API：

| 写法 | 语义 | 槽不存在时 | 配 setter 吗 |
|---|---|---|---|
| `o x := v` | **定义**槽 `x`（并赋初值） | 允许，凭空造 | **不配** |
| `o x = v` | **更新**槽 `x` | 报 `Slot x not found...` | — |
| `o y ::= v` | 定义槽 `y` | 允许 | **配**，生成 `setY` |
| `o newSlot("z", 3)` | 显式造槽，返回对象本身（可链式） | 允许 | **也配**，生成 `setZ` |

**这里有个容易记反的地方：`newSlot` 是配 setter 的**，只有 `:=` 不配。
Io 自己的 `libs/iovm/io/Object.io` 第 339 行的注释把这条写得很明白：

```text
newSlot("foo", 1) would create slot named foo with the value 1
as well as a setter method setFoo().
```

实测（`examples/07_prototypes/07_prototypes.io` 的 7.2 节）：

```text
newSlot("z", 3) 之后 = list(3, true)     ← 第二个 true 就是 hasSlot("setZ")
setZ(77) 之后 o z = 77                   ← 配出来的 setter 真能写
:= 定义过的 x 有 setter 吗 = false        ← 只有 := 不配
```

注意示例里查 setter 名字的写法：`slotNames select(name, name beginsWithSeq("set"))`，
先过滤再 `sort`。直接打印 `slotNames` 是不行的（哈希序 + 可能混进系统槽，见 7.7）。

> **为什么重要**：`:=` 与 `=` 的分工是 Io 里最像「变量声明 vs 变量赋值」的一对，
> 但它是**运行时**的：`=` 失败是个异常，不是编译错误。用 `=` 更新一个打错字的槽名，
> 会得到一条清晰的 `Slot xxx not found`，这是好事——别把它当噪声。
> 至于「要不要 setter」：**要写入口就 `::=` 或 `newSlot`，要纯数据槽就 `:=`**，
> 别指望 `:=` 顺手给你一个。

## 7.3 陷阱：= 不能凭空造槽

```text
-- 7.3 陷阱：= 不能凭空造槽
try(o w = 1) 的异常消息 = Slot w not found. Must define slot using := operator before updating.
Child name = 小白
Dog name = 未命名
```

```io
e := try(o w = 1)
show("try(o w = 1) 的异常消息", e error)
chk("未定义的槽不能用 = 赋值", e error, "Slot w not found. Must define slot using := operator before updating.")
Child := Dog clone
Child name = "小白"
show("Child name", Child name)
show("Dog name", Dog name)
chk("= 写在自己的副本上", Dog name, "未命名")
```

结论：`=` 只在**整条 proto 链上已经有这个名字**时才合法，否则抛
`Slot w not found. Must define slot using := operator before updating.`。

反过来，链上存在（继承来的）时，`=` 会**在接收者自己身上**创建一个遮蔽副本：
`Child := Dog clone` 后 `Child name = "小白"`，`Child name` 变成 `小白`，
而 `Dog name` 还是 `未命名`。

> **为什么重要**：这条规则把「继承」和「覆盖」统一成了同一件事——覆盖就是
> 「在链的更近处放一个同名槽」。理解了它，`resend` / `super`（[6.8](06-messages.md)）
> 与「为什么子对象改属性不会影响父对象」就都不需要额外解释了。

## 7.4 proto 链：读向左、写在本地

```text
-- 7.4 proto 链：读向左、写在本地
B v（继承） = 1
B hasLocalSlot("v") = false
B hasSlot("v") = true
B isKindOf(A) = true
A isKindOf(B) = false
B protos size（proto 链的第一个环节） = 1
```

```io
A := Object clone
A v := 1
B := A clone
show("B v（继承）", B v)
show("B hasLocalSlot(\"v\")", B hasLocalSlot("v"))
show("B hasSlot(\"v\")", B hasSlot("v"))
show("B isKindOf(A)", B isKindOf(A))
show("A isKindOf(B)", A isKindOf(B))
show("B protos size（proto 链的第一个环节）", B protos size)
```

结论：`B := A clone` 之后，`B` 的 proto 是 `A`：

- **读走链**：`B v` 在 `B` 上没有，沿链找到 `A v`，得到 `1`。
- **`hasLocalSlot` vs `hasSlot`**：`B hasLocalSlot("v")` 是 `false`
  （自己身上没有），`B hasSlot("v")` 是 `true`（链上找得到）。
  这两个 API 的差别就是「本地」与「可见」的差别。
- **`isKindOf` 有方向**：`B isKindOf(A)` 为真，`A isKindOf(B)` 为假。
- **`protos` 是列表、`proto` 是第一个**：`B protos size` 是 1（本例是单继承）。
  注意 `B protos` 直接打印会带对象地址（`list(A_0x...)`），只能取长度或等价性，
  不能进输出。

> **为什么重要**：`hasLocalSlot` 是调试「为什么改了没生效 / 为什么不影响别人」的
> 第一把扳手：它是判断「槽到底长在谁身上」的唯一可靠手段。
> 「读走链、写本地」这一句背下来，第七章剩下的内容都是推论。

## 7.5 clone 会自动跑 init —— 不想跑就用 cloneWithoutInit

```text
-- 7.5 clone 会自动跑 init —— 不想跑就用 cloneWithoutInit
Counter n（原型自己） = 0
c1 n / c2 n = list(1, 1)
c3 n（cloneWithoutInit，没跑 init） = 0
c3 hasLocalSlot("n") = false
```

```io
Counter := Object clone
Counter n := 0
Counter init := method(n = n + 1)
c1 := Counter clone
c2 := Counter clone
c3 := Counter cloneWithoutInit
show("Counter n（原型自己）", Counter n)
show("c1 n / c2 n", list(c1 n, c2 n) asString)
show("c3 n（cloneWithoutInit，没跑 init）", c3 n)
show("c3 hasLocalSlot(\"n\")", c3 hasLocalSlot("n"))
chk("clone 会调用 init", c1 n, 1)
chk("每次 clone 各自跑一次", c2 n, 1)
chk("cloneWithoutInit 不跑 init", c3 hasLocalSlot("n"), false)
```

结论：`clone` 在复制完之后会**自动调用副本上的 `init`**（如果存在）：

- `c1 := Counter clone` 触发 `init`，`n = n + 1` 写的是**副本自己**，于是 `c1 n` 是 1。
- `c2` 再 clone 一次，同样得到 1（不是 2）——每次克隆各自跑一遍、各自写自己的槽，
  `Counter n` 本身始终是 0。
- `c3 := Counter cloneWithoutInit` 跳过 `init`，所以 `c3 hasLocalSlot("n")` 是 `false`：
  `c3 n` 打印出的 0 是**沿链读到原型**的值，不是副本自己的。

> **为什么重要**：`clone` 带 `init` 是 Io 里最接近「构造函数」的东西，但它**不是**：
> 它只是「克隆后自动发一条 `init` 消息」。想造一个「还没初始化」的副本
> （做原型模板、做序列化中转、做测试夹具）就用 `cloneWithoutInit`。

## 7.6 self 与 do：do 临时把 self 换成接收者

```text
-- 7.6 self 与 do：do 临时把 self 换成接收者
Box describe（方法里的 v 走 self） = v = 10
do 之后 Box slotNames 含 u = true
Box u = 99
Other u 仍是自己的 1 = 1
```

```io
Box := Object clone
Box v := 10
Box describe := method("v = " .. v asString)
show("Box describe（方法里的 v 走 self）", Box describe)
Box do(u := 99)
show("do 之后 Box slotNames 含 u", Box slotNames contains("u"))
show("Box u", Box u)
chk("do 里的赋值落在对象上", Box u, 99)
Other := Object clone
Other u := 1
show("Other u 仍是自己的 1", Other u)
chk("do 不是可有可无的糖", Other u, 1)
```

结论：方法体里的自由名字**在 `self` 上解析**：`Box describe` 里的 `v` 走的是
`Box v`，所以打印 `v = 10`。

`do(块)` 的作用是**把这段代码的 `self` 临时换成接收者**，于是块里的
`u := 99` 落在 `Box` 身上（`Box slotNames` 里出现了 `u`，`Box u` 是 99）。
不写 `do` 时，同样的 `u := 99` 落在**当前上下文**（`Lobby`）上，跟 `Box` 无关——
`Other u` 依然是它自己的 1。

> **为什么重要**：`do` 不是「块语法的括号」，它是**换 `self` 的作用域算子**。
> 初始化对象、往对象上批量装槽、在别人的上下文里执行代码，靠的都是它。
> 记住：`o do(...)` 里写的 `:=` 落点是 `o`。

## 7.7 removeSlot / slotNames 排序

```text
-- 7.7 removeSlot / slotNames 排序
槽名（排序后） = list("a", "b", "c")
removeSlot("b") 之后 = list("a", "c")
hasSlot("b") = false
```

```io
t := Object clone
t a := 1
t b := 2
t c := 3
show("槽名（排序后）", t slotNames sort)
t removeSlot("b")
show("removeSlot(\"b\") 之后", t slotNames sort)
show("hasSlot(\"b\")", t hasSlot("b"))
chk("槽名顺序在 Io 里是哈希序，比较前必须 sort", t slotNames sort asString, "list(\"a\", \"c\")")
```

结论：`slotNames` 返回**本对象的槽名列表**，顺序是哈希序（每次运行都可能不同），
所以**比较之前必须 `sort`**——示例里连断言都带着 `sort`。
`removeSlot("b")` 删掉本地槽，之后 `hasSlot("b")` 为 `false`（链上也没人定义它）。

单独实测还有一个容易踩的细节：**用大写名字接收一个对象时，Io 会自动给它一个
`type` 槽**：

```text
T  := Object clone            → T slotNames  = list("type")   ，T type  = "T"
tt := Object clone            → tt slotNames = list()        ，tt type = "Object"
T2 := Object clone do(m := 1) → T2 slotNames = list("m", "type")
```

也就是说「槽名列表」里可能混着这个自动生成的 `type`。示例里的 `t` 是小写名，
所以列表干净；一旦你在自己的代码里用大写名当「类」，过滤槽名时要留意它。

> **为什么重要**：`slotNames` 是反射的第一入口（`hasSlot`、`removeSlot`、
> `slotNames` 三件套），但它既不排序也不隔离系统槽。任何「打印全部槽名」
> 的调试输出都要先 `sort`、必要时先过滤，否则会破坏确定性纪律。

## 7.8 asString 覆盖：让对象能安全地拼进字符串

```text
-- 7.8 asString 覆盖：让对象能安全地拼进字符串
pt 直接拼 = pt = (3,4)
未覆盖 asString 的对象拼出来含地址 = true
所以只要输出要进判定区间，就必须覆盖 asString 或改用显式 asString
```

```io
pt := Object clone
pt x := 3
pt y := 4
pt asString := method("(" .. x asString .. "," .. y asString .. ")")
show("pt 直接拼", "pt = " .. pt)
show("未覆盖 asString 的对象拼出来含地址", (Object clone) asString containsSeq("0x"))
writeln("所以只要输出要进判定区间，就必须覆盖 asString 或改用显式 asString")
chk("覆盖 asString 后 .. 得到可控文本", "pt = " .. pt, "pt = (3,4)")
chk("未覆盖时 asString 里是地址", (Object clone) asString containsSeq("0x"), true)
```

结论：`..`、`join`、`writeln` 的多参数、`interpolate` 都会对值调 `asString`。
没有覆盖 `asString` 的对象给的是「槽位摘要 + 地址」（含 `0x`，每次运行都不同），
所以它**绝不能出现在要求逐字节稳定的输出里**。

覆盖它只需要一行：`pt asString := method(...)`，之后 `"pt = " .. pt` 就得到
完全可控的 `pt = (3,4)`。

> **为什么重要**：这是把「确定性纪律」落实到类型设计上的手段。
> 要进输出的自定义对象，第一件事就是给它写一个稳定的 `asString`——
> 这比事后在每处拼接点加 `asString` 调用可靠得多。

## 7.9 陷阱：do(...) 里的槽定义不能用逗号分隔

```text
-- 7.9 陷阱：do(...) 里的槽定义不能用逗号分隔
do(m := 1, n := 2) 的解析树 = do(setSlot("m", 1), setSlot("n", 2))
用逗号：Bad 有 m = true
用逗号：Bad 有 n = false
用分号：Good 有 m = true
用分号：Good 有 n = true
第二个实参里的副作用发生了吗 = false
```

```io
show("do(m := 1, n := 2) 的解析树", Message fromString("do(m := 1, n := 2)"))
Bad := Object clone do(m := 1, n := 2)
Good := Object clone do(m := 1; n := 2)
show("用逗号：Bad 有 m", Bad hasSlot("m"))
show("用逗号：Bad 有 n", Bad hasSlot("n"))
show("用分号：Good 有 m", Good hasSlot("m"))
show("用分号：Good 有 n", Good hasSlot("n"))
Lobby removeSlot("dummyProbe")
Side := Object clone do(k := 1, Lobby dummyProbe := 5)
show("第二个实参里的副作用发生了吗", Lobby hasLocalSlot("dummyProbe"))
chk("逗号版本丢了一个槽", Bad hasSlot("n"), false)
chk("分号版本两个都在", Good hasSlot("n"), true)
chk("多出来的实参连求值都不会发生", Lobby hasLocalSlot("dummyProbe"), false)
```

结论：`do(...)` 对**逗号**和**分号**的处理完全不同，第一行的解析树就是全部原因：

- **逗号**：`do(m := 1, n := 2)` 被解析成 `do(setSlot("m", 1), setSlot("n", 2))`，
  也就是「给 `do` 传了**两个实参**」。而 `do` 只求值第一个实参——VM 注册 `Object do`
  时把它标成了「惰性实参」（`IoState.c` 里的 `IoState_markSlotLazyArgs_`），
  第二个起的实参**连求值都不会发生**。
  所以 `n` 既没落在 `Bad` 上、也没落在调用者上下文里：示例里那个
  `Lobby dummyProbe := 5` 塞在第二个实参位置上，跑完 `Lobby` 里**没有**这个槽
  （最后一行 `false`）。直接引用 `n` 则会报 `Object does not respond to 'n'`。
- **分号**：`do(m := 1; n := 2)` 是「一条消息里有两个表达式」，两个都执行，
  于是两个槽都在。

所以「丢槽」不是「槽跑到别处去了」，而是**那句话从来没被执行过**。

> **为什么重要**：这是「多传实参不报错」这一家族里最阴的一种：
> 不报错、不留痕、副作用也不跑。凡是往 `do(...)`、`method(...)` 里塞东西，
> 一律用 `;` 或换行分隔；看到「槽少了一个」，先数逗号，再看解析树。

## 7.10 陷阱：do 只接得到 Lobby 的槽，看不到本方法的局部槽

7.6 说 `do` 会「把 `self` 换成接收者」，这句话还差一半。`do` 同时也会
**换掉作用域链的起点**：块里的裸名字先在接收者身上找，然后沿它的 proto 链走到
`Object`，再到 `Lobby`——但它**不会**回到定义它的那个方法的局部槽。

```text
-- 7.10 陷阱：do 只接得到 Lobby 的槽，看不到本方法的局部槽
do 里读 Lobby 槽 = 9
do 里读方法局部槽的异常 = Object does not respond to 'localProbe'
lexicalDo 里读方法局部槽 = 8
显式 setSlot 也读得到局部槽 = 7
```

```io
Lobby globalProbe := 9
probeFactory := method(
    localProbe := 8
    r := Object clone
    fromDo := Object clone do(p := globalProbe)
    r setSlot("doSawGlobal", fromDo p)
    e := try(Object clone do(p := localProbe))
    r setSlot("doLocalError", e error)
    fromLexical := Object clone lexicalDo(p := localProbe)
    r setSlot("lexicalSawLocal", fromLexical p)
    r
)
```

结论做成一张表：

| 在什么里读 | `do(...)` | `lexicalDo(...)` |
|---|---|---|
| 接收者自己的槽 | 可见 | 可见 |
| `Lobby` 的槽 | **可见** | 可见 |
| 定义它的方法的局部槽 | **看不见**（`Object does not respond to 'x'`） | **可见** |

`do` 之所以在标准库里用得那么多，是因为标准库的代码要么只读 `Lobby` 上的原型
（`List`、`Map`、`Iterator`…），要么只用字面量。一旦你的工厂方法需要把
**自己的局部变量**塞进新对象，`do` 就会在运行时炸给你看。

三个可行写法，按推荐程度排：

```io
// 1) 词法环境里求值 —— 最贴近「工厂方法」的直觉
Object clone lexicalDo(p := localProbe)

// 2) 先造对象，再用消息把值送进去 —— 最显式，没有任何作用域魔法
o := Object clone
o setSlot("p", localProbe)

// 3) 值先用字面量占位，再赋值
o := Object clone do(p := 0)
o p = localProbe
```

> **为什么重要**：`do` 与 `lexicalDo` 的差别是 Io 里「动态作用域 vs 词法作用域」
> 的分界线。凡是「在方法里造对象、并把局部量塞进去」的代码，
> 用 `do` 都是错的——而且错得**很晚**：只有当那个方法真的被调用时才炸。

## 7.11 坑位清单

1. **把 `:=` / `=` / `::=` / `newSlot` 当成一回事** → `=` 只能**更新已存在**的槽（否则 `Slot x not found. Must define slot using := operator before updating.`）；`:=` 只造槽、**不配 setter**；而 `::=` 和 `newSlot` **都会**顺手生成 `setX`（`newSlot` 会配 setter 这点最容易记反，07.2 有实测）。
2. **以为 `=` 会修改原型上的槽** → 它在接收者自己身上建遮蔽副本，原型不受影响。
3. **用 `hasSlot` 判断「槽长在谁身上」** → 它沿链查找，判本地要用 `hasLocalSlot`。
4. **把 `isKindOf` 当双向判断** → 它有方向：`B isKindOf(A)` 真而 `A isKindOf(B)` 假。
5. **直接打印 `protos`** → 里面是对象，会打出地址；只取 `size` 或做等价比较。
6. **以为 `clone` 只是复制** → 它还会自动调用副本上的 `init`，要跳过就用 `cloneWithoutInit`。
7. **以为 `do(...)` 只是语法括号** → 它既换 `self`（块里的 `:=` 落在接收者上），也换作用域起点；要读方法局部槽得用 `lexicalDo`。
8. **直接比较 `slotNames`** → 顺序是哈希序，且大写命名的对象还会多出 `type` 槽，先 `sort` 再比。
9. **在 `do(...)` 里用逗号分隔多个槽定义** → 多出的实参不求值，槽静默消失，用 `;` 或换行。
10. **让未覆盖 `asString` 的对象进输出** → 拼出的是带 `0x` 地址的摘要，先写一个稳定的 `asString`。

---

上一章：[06 · 消息：三种形状与优先级](06-messages.md) · 下一章：[08 · 方法：参数、作用域与 return](08-methods.md)
