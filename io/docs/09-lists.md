# 09 · 列表

> 对应示例：[`examples/09_lists/09_lists.io`](../examples/09_lists/09_lists.io)

## 9.1 list(...) 与 List clone：造出来的是同一种可变 List

一句话：Io 里只有一种表，`list(a, b, c)` 是语法糖，`List clone` 是显式克隆原型，造出来的 `type` 和 `proto` 都一样，而且都是**可变**的。

```text
-- 9.1 list(...) 与 List clone：造出来的是同一种可变 List
list(3, 1, 2) 的 type = List
List clone 的 type = List
List clone 的 size = 0
list() 的 size = 0
两者的 proto 都是 = List
b appendSeq(a) 之后 b = list(3, 1, 2)
b 是 a 本身吗 = false
再给 a append(9) 之后 a = list(3, 1, 2, 9)
b 有没有跟着变 = list(3, 1, 2)
```

```io
a := list(3, 1, 2)
b := List clone
b appendSeq(a)
a append(9)          // 只改 a；b 是另一张表
```

`List clone` 给的是空表（`size` 是 0），要装内容得自己 `appendSeq`；用 `list(...)` 更省事。两张表之间没有任何共享，改一张不会动另一张。

> **为什么重要**：`List clone` 是「空表」，不是「等长的表」。写 `b := a` 会得到同一张表的第二个名字（`isIdenticalTo` 为 true），要独立副本必须 `clone` 或 `List clone appendSeq(a)`。

## 9.2 就地修改：改造型返回自身，删除型返回被删掉的元素

一句话：List 的方法分两拨，返回值不一样，这直接决定链式调用安不安全。

```text
-- 9.2 就地修改：改造型返回自身，删除型返回被删掉的元素
x append(3) 返回的就是 x 本身吗 = true
x prepend(0) 返回的就是 x 本身吗 = true
x atPut(0, 9) 返回的就是 x 本身吗 = true
x push(7) 返回的就是 x 本身吗 = true
现在 x = list(9, 1, 2, 3, 7)
x removeAt(0) 返回的是被删掉的元素 = 9
x pop 返回的是被删掉的元素 = 7
删完之后的 x = list(1, 2, 3)
链式 append 是安全的 = list(1, 2, 3)
拿 removeAt 的结果接着调 prepend 的异常消息 = Number does not respond to 'prepend'
```

```io
x := list(1, 2)
x append(3)                  // 返回 x 本身 → 可以接着 .append(...)
x removeAt(0)                // 返回被删掉的 9，不是表
// (list(1, 2) removeAt(0)) prepend(9)   ← 会炸
```

改造型（`append` / `prepend` / `push` / `atPut` / `swapIndices` / `atInsert` / `appendSeq`）返回**自身**，链式写没问题；删除型（`removeAt` / `pop` / `removeFirst` / `removeLast`）返回**被删掉的那个元素**，返回值上不能接着发表消息。

> **为什么重要**：Io 里没有「返回值是 void 的变异方法」这个概念，所有方法都有返回值。判断能不能链式，就看它返回的是不是 `self`——本机可以用 `isIdenticalTo` 一行测出来。

## 9.3 下标：at 支持负索引，越界返回 nil 而不是报错

一句话：读越界是 `nil`，写越界才抛异常。

```text
-- 9.3 下标：at 支持负索引，越界返回 nil 而不是报错
a size = 3
a at(0) = 10
a at(-1)（最后一个） = 30
a at(-3)（第一个） = 10
a at(99) 是 nil 吗 = true
a at(-99) 是 nil 吗 = true
first / last / second = 10 / 30 / 20
atPut 越界的内容是那句 index out of bounds 吗 = true
它尾巴上还带一个换行，size 是 = 20
atInsert 越界也一样吗 = true
atInsert 异常消息的 size 也是 = 20
```

```io
a := list(10, 20, 30)
a at(-1)          // 30，负索引从尾部数
a at(99)          // nil，不报错
try(a atPut(99, 1)) error   // "index out of bounds\n"
```

`at` 的负索引是「倒数第 N 个」，`first` / `last` / `second` 是它的甜点。写操作（`atPut` / `atInsert` / `insertAt`）越界会抛 `index out of bounds`，而且**消息尾巴上多一个换行**：`(e error) size` 是 20，而字面量只有 19 个字符。

> **为什么重要**：`at` 越界给 nil，就意味着「读到的 nil」既可能是越界，也可能是表里真的存了 nil。要区分就必须先 `a size` 判断，或者干脆改用 `indexOf` / `contains`。

## 9.4 slice 与 exSlice：区间语义一样，差别只有那条废弃警告

一句话：`slice` 在 **Sequence** 上是废弃方法、会往 stdout 打一行警告；在 **List** 上是原语、不警告，两者都是左闭右开。

```text
-- 9.4 slice 与 exSlice：区间语义一样，差别只有那条废弃警告
a slice(1, 3) = list(2, 3)
a exSlice(1, 3) = list(2, 3)
a exSlice(0, 0)（右端等于左端就是空表） = list()
a slice(-2, -1) = list(4)
a exSlice(3, 99)（右端越界会截断） = list(4, 5)
List getSlot("slice") 的 type = CFunction
Sequence getSlot("slice") 的 type = Block
Warning in doString: 'slice' is deprecated.  Use 'exSlice' instead.
在 doString 里对字符串调 slice，返回值是 = el
```

```io
a := list(1, 2, 3, 4, 5)
a slice(1, 3)      // 不警告，list(2, 3)
a exSlice(1, 3)    // list(2, 3)，一样
// "hello" slice(1, 3)  → stdout 多一行 deprecated 警告
```

超范围的两端行为要记牢：右端超出会被截断到表尾（`exSlice(3, 99)` 给 `list(4, 5)`），左端大于右端给空表，负索引按「倒数」解释。警告的原文是 `Warning in <调用点>: 'slice' is deprecated.  Use 'exSlice' instead.`——里面那段 `<调用点>` 是「调用发生在哪个文件」，所以在脚本里直接写就会带上脚本路径；示例里用 `doString` 触发，位置部分才是确定的 `doString`。

> **为什么重要**：`deprecatedWarning` 拼的是 `call sender call message label`，也就是「谁调的我、在哪个文件」。这行警告是**给你看的定位信息**，不是给程序读的——所以任何「把它当数据解析」的写法都是错的。

## 9.5 查找：indexOf / contains / detect，找不到给 nil 或 false

一句话：三个查找方法都不抛异常，找不到分别给 `nil` / `false` / `nil`。

```text
-- 9.5 查找：indexOf / contains / detect，找不到给 nil 或 false
a indexOf(20) = 1
a indexOf(99) 是 nil 吗 = true
a contains(30) = true
a contains(99) = false
a detect(v, v > 15) = 20
a detect(v, v > 999) 是 nil 吗 = true
a detect(i, v, i == 2) = 30
```

```io
a := list(10, 20, 30)
a indexOf(20)              // 1（下标）
a indexOf(99)              // nil，不是 -1
a contains(99)             // false
a detect(v, v > 999)       // nil，不是 false
a detect(i, v, i == 2)     // 30，detect 也可以带下标
```

注意 `indexOf` 找不到给的是 `nil` 而不是 C 风格的 `-1`，`detect` 找不到给的是 `nil` 而不是 `false`——两个都别直接塞进算术里。

> **为什么重要**：`if(a indexOf(x), ...)` 在 Io 里是危险的：`0` 是合法下标却是假值。判断「有没有」请用 `contains`，要下标再 `indexOf` 并显式比 `nil`。

## 9.6 排序：sort 返回新表，sortInPlace 就地，sortBy 收的是「比较器」

一句话：`sort` / `sortBy` 给新表，`sortInPlace` / `sortInPlaceBy` 就地；`sortBy` 要的是**两参比较器**，`sortByKey` 才是「按某个键排」。

```text
-- 9.6 排序：sort 返回新表，sortInPlace 就地，sortBy 收的是「比较器」
a sort 的返回值 = list(1, 2, 3)
原表 a 有没有被改 = list(3, 1, 2)
返回值是同一张表吗 = false
a sortInPlace 之后 a = list(1, 2, 3)
sortInPlace 返回的是 a 本身吗 = true
字符串按码点序排 = list("C", "a", "b")
数字按大小排（不是字符串序） = list(1, 2, 10)
sortBy(block(x, y, x < y)) 升序 = list(1, 2, 3)
sortBy(block(x, y, x > y)) 降序 = list(3, 2, 1)
sortBy 之后原表还是 = list(1, 2, 3)
两个形参才是比较器：降序 = list(9, 5, 3)
只写一个形参、把 0 - v 当「键」 = list(3, 9, 5)
键换成常量字符串，结果一模一样 = list(3, 9, 5)
按第 0 位排序 = a,b
sortByKey(at(0)) 之后取每个键 = a,b
sortBy(v, 0 - v) 的异常消息 = Object does not respond to 'v'
```

```io
a := list(3, 1, 2)
b := a sort                     // 新表，a 不动
a sortInPlace                   // 就地，返回 a 本身
a sortBy(block(x, y, x > y))    // 降序：比较器要两个形参
list(list("b", 2), list("a", 1)) sortByKey(at(0))   // 按第 0 位排
```

默认比较是「元素自身的自然序」：数字按大小（`list(2, 10, 1) sort` 给 `list(1, 2, 10)`），字符串按**码点**（大写 `"C"` 排在小写 `"a"` 前面）。`sortBy` 只接受一个 block 实参，而且这个 block 必须是 `block(x, y, ...)` 形态的比较器；只写一个形参（想当「取键」用）**不会报错，但结果是错的**——实测 `list(5, 3, 9) sortBy(block(v, 0 - v))` 和 `sortBy(block(v, "zzz"))` 都给出 `list(3, 9, 5)`，键根本没被看过。按「键」排要用 `sortByKey(消息)`。

> **为什么重要**：`sortBy` 静默给错结果，比抛异常危险得多。规律是：**Io 的方法激活不检查实参个数**，形参对不上时多余实参直接丢掉、缺的补 nil，于是「一个形参的 block」被当成比较器用时，比较器只看到第一个元素，排序结果就成了垃圾。

## 9.7 变换：map / select / reduce / unique / reverse / flatten / join

一句话：这一族都是「读表、给新表」的纯函数，`reduce` 有两种形状，`reject` 在这版 List 上**不存在**。

```text
-- 9.7 变换：map / select / reduce / unique / reverse / flatten / join
a map(v, v * 2) = list(2, 4, 6, 8)
a map(i, v, i * 100 + v) = list(1, 102, 203, 304)
a select(v, v % 2 == 0) = list(2, 4)
a select(i, v, i > 0) = list(2, 3, 4)
a reject(...) 的异常消息 = List does not respond to 'reject'
用 select + not 顶替 reject = list(1, 3)
a reduce(+) = 10
a reduce(x, y, x + y) = 10
a reduce(x, y, x + y, 100)（末位是初值） = 110
a reverse join("-") = 4-3-2-1
a sum / a average = 10 / 2.5
list(1, 2, 2, 3, 1) unique = list(1, 2, 3)
嵌套表 flatten 之后 join = 1-2-3-4-5
list(1, 2, 3) join("-") = 1-2-3
list() join("-") 打出来是 = []
```

```io
a := list(1, 2, 3, 4)
a map(v, v * 2)                       // 新表
a map(i, v, i * 100 + v)              // 带下标
a select(i, v, i > 0)                 // 要下标就多写一个形参名
a select(v, (v % 2 == 0) not)         // 顶替 reject
a reduce(+)                           // 10，符号当作方法名
a reduce(x, y, x + y)                 // 10
a reduce(x, y, x + y, 100)            // 110，初值在最后一个位置
a reverse join("-")                   // 只读，a 不变
n flatten join("-")                   // flatten 会递归压平
```

`map` / `select` / `reverse` 都返回**新表**（`isIdenticalTo` 是 false）。`reduce` 三参形式是 `(名字A, 名字B, 表达式)`，四参形式是 `(名字A, 名字B, 表达式, 初值)`——初值在**最后**，不要写成 `reduce(100, ...)`。`join` 的空表结果是空串。

> **为什么重要**：这一族是 Io 里最像「函数式」的部分，但它的参数约定很不整齐：带下标就要多写一个形参名（`map(i, v, ...)`），`reduce` 的初值在末位。写之前先 `List slotNames` 看看有没有这个方法——本机的 `List` 就**没有** `reject`。

## 9.8 嵌套表的打印陷阱，以及把方法装进列表

一句话：嵌套 List 的默认 `asString` 会把内层元素全部引号化，而方法放进表里「取出来必须立刻调」。

```text
-- 9.8 嵌套表的打印陷阱，以及把方法装进列表
nested at(0) 单独打印 = list(1, "a")
nested 整体打印 = list(list("1", "\"a\""), list("2", "\"b\""))
整体打印里出现了转义引号吗 = true
所以嵌套表要自己拼 = [1,a] [2,b]
fns size = 2
取出来立刻 call 才行 = 20,11
想把方法先读进局部槽再用的异常消息 = nil does not respond to '*'
```

```io
nested := list(list(1, "a"), list(2, "b"))
nested at(0)                              // list(1, "a")，正常
nested                                    // 内层被 asSimpleString 渲染，全加引号
nested map(p, "[" .. (p at(0) asString) .. "," .. (p at(1)) .. "]") join(" ")

fns := list(getSlot("double"), getSlot("inc"))
fns at(0) call(10)                        // 20：取出来立刻 call
// fns map(f, f type)                     ← 会把 double 以零参激活，炸
```

同一个内层表，单独打印是 `list(1, "a")`，被外层裹着打印就变成 `list("1", "\"a\"")`——因为 List 的 `asString` 对嵌套的 List 会改用 `asSimpleString` 递归渲染，内层每个元素都当成字符串加引号。要对齐格式就自己 `map` + `join`。

> **为什么重要**：这两件事其实是同一条规则的两面——**Io 的槽在「被读」时会激活**。`f` 这个局部槽里装的是 Method，读 `f` 就是调用它（形参 nil），所以方法必须先 `call`、块必须先 `call`/`do`，不能先存进变量再想「稍后调」。

## 9.9 坑位清单

1. **以为 `List slice` 会打废弃警告** → 警告只出在 `Sequence slice`（Io 方法）上；`List slice` 是 CFunction 原语、不警告，两者区间语义都是左闭右开。
2. **以为 `removeAt` / `pop` 也返回自身** → 它们返回被删掉的元素，接着链式调用会炸；只有 append / prepend / push / atPut / swapIndices / atInsert 返回自身。
3. **用 `at` 读越界下标还等着报错** → `at` 越界给 nil（负索引同理），只有写操作 atPut / atInsert / insertAt 才抛 `index out of bounds`。
4. **以为 `indexOf` 找不到给 -1、`detect` 找不到给 false** → 两者都给 nil；`if(a indexOf(x))` 还会把合法的下标 0 当假值。
5. **把 `sortBy` 当「取键」用，只写一个形参** → 不报错但排序结果是错的（实测 `list(5, 3, 9)` 得到 `list(3, 9, 5)`）；键排用 `sortByKey(消息)`，比较器写 `block(x, y, ...)`。
6. **以为 `List` 有 `reject`** → 这版 List 没有，调用得到 `List does not respond to 'reject'`；用 `select(v, (条件) not)`。
7. **`reduce` 四参形式把初值写在最前面** → 顺序是 `(名字A, 名字B, 表达式, 初值)`，初值在末位，写成 `reduce(100, ...)` 会去求值 `x + y` 而炸。
8. **把嵌套 List 直接 `asString` 打进输出** → 内层走 `asSimpleString`，所有元素都被加引号；要确定性就自己 `map` + `join` 或先 `flatten`。
9. **把方法先存进局部槽、之后再调** → 读槽会以零参激活它（`nil does not respond to '*'`）；要么取出来立刻 `call`，要么用 `getSlot` 拿本体。
10. **用点号写消息链（`a.asString`）** → 点号会被并进消息名，得到 `Object does not respond to 'a.asString'`；Io 的链条靠空格：`a asString`。

---

上一章：[08 · 方法](08-methods.md) · 下一章：[10 · 映射](10-maps.md)
