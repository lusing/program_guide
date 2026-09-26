# 23 · 测试与断言

> 对应示例：`examples/21-testing.sml`


SML 没有内置测试框架。没有 `assert`，没有 `unittest`，没有任何东西。但**三十行就能写一个够用的** —— 而且写出来的东西恰好展示了 SML 最擅长的两件事：**记录聚合**和**闭包封状态**。

## 23.1 断言器：一个记录，里面全是闭包

```sml
type checker = {
    checkInt : string * int * int -> unit,
    checkList : string * int list * int list -> unit,
    checkTrue : string * bool -> unit,
    checkRaises : string * (unit -> unit) * string -> unit,
    summary : unit -> string
}

fun makeChecker () : checker =
    let
        val passed = ref 0
        val failed = ref 0

        fun ok name = (passed := !passed + 1; say ("  ok   " ^ name))
        fun no name = (failed := !failed + 1; say ("  FAIL " ^ name))

        fun checkInt (name, actual, expected) =
            if actual = expected then ok (name ^ " = " ^ Int.toString expected)
            else no (name ^ " expected " ^ Int.toString expected
                     ^ " but got " ^ Int.toString actual)
        ...
    in
        { checkInt = checkInt, checkList = checkList,
          checkTrue = checkTrue, checkRaises = checkRaises, summary = summary }
    end
```

**这就是「对象」在 SML 里的标准写法**（第 18 章已经示范过一次）：**一个记录，字段是函数，共享一份私有状态**。

拆解：

- **`type checker` 是个记录类型**，五个字段全是函数类型。
- **`makeChecker ()` 是构造函数**（带 `unit` 参数表示「每次调用造一个新的」）。
- **`passed`/`failed` 两个 `ref` 声明在 `let` 里**，外面看不见 —— **这就是私有状态**。
- **`ok`/`no` 是私有的辅助函数**，不在返回记录里。
- 返回的记录只有五个公开动作。

**调用方拿不到计数器，只能通过 `summary ()` 读统计。** 这就是封装。

**这个模式的好处可以量化**：示例里造了**两个**断言器：

```sml
val C = makeChecker ()          (* 真实测试 *)
val bad = makeChecker ()        (* 故意失败的演示 *)
```

**两个的计数器互不干扰。** 如果用全局变量（`val passed = ref 0` 放在顶层），就没法做到这一点 —— 第 4 节的演示会污染第 5 节的总计。

**最后一个字段 `summary : unit -> string` 而不是 `summary : string`**，这是刻意的：**`string` 是值，会在记录构造时被求值**；`unit -> string` 是函数，**每次调用都重新读一遍计数器**。写成 `summary = Int.toString (!passed + !failed) ^ ...` 的话，返回的记录里那个字符串永远是 `"0 checks / 0 passed / 0 failed"`。

**这条规则是 SML 里封装的通用要点：想暴露「会变的值」，就暴露一个函数。**

## 23.2 那个必须写的类型标注

```sml
(* 返回值一定要标注成 : checker。
   只写 fun makeChecker () = {...} 的话，checkRaises 那个字段会被推成
     string * (unit -> 'a) * string -> unit
   带着一个自由类型变量；而 type 别名本身**不是**约束，
   于是 C 的类型里留着这个变量，后面 #checkRaises C 就会报
   "operator and operand do not agree"。标注之后 'a 被钉成 unit。 *)
fun makeChecker () : checker =
```

**这是本示例里最有价值的一个坑，值得完整展开。**

`checkRaises` 的实现是：

```sml
fun checkRaises (name, thunk, expected) =
    let
        val got = (thunk (); "no exception")
                  handle e => exnName e
    in
        if got = expected then ok (name ^ " raises " ^ expected)
        else no (name ^ " expected " ^ expected ^ " but got " ^ got)
    end
```

`thunk ()` 的返回值**被丢掉了**（表达式 `(thunk (); "no exception")` 的值是 `"no exception"`，左边那个 `thunk ()` 的结果没用）。所以编译器推断出的类型是：

```
val checkRaises : string * (unit -> 'a) * string -> unit
```

**注意那个 `'a`** —— 因为 `thunk` 的返回值从不被使用，任何类型都行，所以它是**自由的类型变量**（多态的）。

**问题在于 `type checker` 里的声明是 `(unit -> unit)`：**

```sml
type checker = {
    ...
    checkRaises : string * (unit -> unit) * string -> unit,
    ...
}
```

**`type` 别名不是约束。** 第 4 章讲过：`type` 只是给一个类型取名字，它**不做任何检查**。SML 不是「猜出一个类型，再拿去和别名里的类型对比」，而是「`type` 就是右半边那个类型本身」。

所以 `makeChecker ()` 的推断结果是：

```sml
val makeChecker : unit -> {
    checkInt : string * int * int -> unit,
    ...
    checkRaises : string * (unit -> 'a) * string -> unit,      (* 'a 还在！ *)
    summary : unit -> string
}
```

`'a` **没被消掉**，它留在了返回类型里。于是 `C` 的类型里有一个自由类型变量。之后：

```sml
val _ = #checkRaises C ("safeDiv (7, 0)", fn () => (safeDiv (7, 0); ()), "BadDivisor")
```

报错：

```
Error: operator and operand do not agree [tycon mismatch]
  operator domain: string * (unit -> 'a) * string -> unit
  operand:         string * (unit -> unit) * string -> unit
```

因为 `#checkRaises C` 是一个**多态函数**，每次用它都要重新实例化 `'a`；但 `C` 本身是个**值**（不是函数调用），它的类型里那个 `'a` 一旦被某个用法固定，其他用法就不匹配了。这是 SML 的**值限制**（value restriction）的体现。

**修法就是标注返回类型：**

```sml
fun makeChecker () : checker =
```

标注之后，编译器知道返回值必须是 `checker` 类型，于是 `checkRaises` 里的 `'a` 被**钉成 `unit`**，`fn () => (safeDiv (7, 0); ())` 恰好返回 `unit`，对上了。

**通用规则：凡是「构造函数返回一个记录、记录里有函数字段」的地方，都该给返回值加类型标注。** 因为函数字段的类型往往带着自由变量，而 `type` 别名不会帮你消掉它。

**这个坑在三套实现上的表现还不一样**（见第 33 章）：**Poly/ML 会用注解里的期望类型反推**，所以它能通过；**SML/NJ 和 MLton 默认按 `int` 解析重载运算符**，于是失败。**这是「无约束重载运算符的解析」差异的一个实例** —— 同一个根因（类型信息不足时各家策略不同），在 functor 的签名参数里也出现过。

## 23.3 四种断言

```sml
fun checkInt (name, actual, expected) = ...
fun checkList (name, actual, expected) = ...
fun checkTrue (name, cond) = if cond then ok name else no name
fun checkRaises (name, thunk, expected) = ...
```

**每种断言都用「期望值 + 实际值」的形式，失败时两个都打出来。** 这是好断言的基本要求。看输出：

```
  ok   isort [3,1,2] = [1,2,3]
  FAIL isort [3,1,2] expected [1,3,2] but got [1,2,3]
```

失败那行直接告诉你「期望什么、实际什么」，不需要去看代码。

**`checkRaises` 的第二个参数是 `unit -> unit`（一个 thunk）**，不是「值」。这是**必须这么写的**：如果要检查的是「表达式会抛异常」，那这个表达式**必须延迟到断言内部才求值**。写成 `checkRaises (name, expr, expected)` 的话，`expr` 会在**调用 `checkRaises` 之前**就被求值 —— 异常在参数求值时就抛出来了，根本进不了断言。

**这就是「按值调用」语言里处理异常的通用手法：把会抛异常的代码包进 `fn () => ...`。** 示例里到处是这种包装：

```sml
val _ = #checkRaises C ("safeDiv (7, 0)", fn () => (safeDiv (7, 0); ()), "BadDivisor")
val _ = #checkRaises C ("7 div 0", fn () => (7 div !zeroCell; ()), "Div")
val _ = #checkRaises C ("hd []", fn () => (hd []; ()), "Empty")
```

**注意 `fn () => (safeDiv (7, 0); ())` 里那对括号和末尾的 `()`。** `thunk` 的类型是 `unit -> unit`，所以函数体必须是 `unit`。`safeDiv (7, 0)` 返回 `int`，要把它「扔掉」变成 `unit`，就得 `(expr; ())` —— **分号后面跟一个空元组**。这是 SML 里「丢弃一个值」的标准写法。

**这又是「分号 + 括号」模式**，第 19、20、22 章都出现过。**如果你只从这本书记住一件事，记住这个：分号串联表达式时必须加括号。**

## 23.4 异常断言用 `exnName`，不用 `exnMessage`

```sml
fun checkRaises (name, thunk, expected) =
    let
        val got = (thunk (); "no exception")
                  handle e => exnName e
    in
        if got = expected then ok (name ^ " raises " ^ expected)
        else no (name ^ " expected " ^ expected ^ " but got " ^ got)
    end
```

**这里的关键设计：把「异常」和「没抛异常」统一成字符串比较。**

- `(thunk (); "no exception")` —— 正常结束就得到 `"no exception"`
- `handle e => exnName e` —— 抛异常就得到异常名字

**`exnName` 是可移植的，`exnMessage` 不是。** 实测：

| 表达式 | SML/NJ | Poly/ML | MLton |
|---|---|---|---|
| `exnName Div` | `Div` | `Div` | `Div` |
| `exnMessage Div` | `divide by zero` | `Div` | — |

**`exnName` 返回构造子的名字**：`Div`、`Subscript`、`Empty`、`BadDivisor`。**这个字符串在 SML'97 里是被标准规定的，三套实现完全一致**，所以可以拿来做断言、做跨实现比对。

**`exnMessage` 返回「给人类看的描述」，各家自己乱写。** Poly/ML 干脆就返回 `"Div"`，SML/NJ 返回 `"divide by zero"`。**拿它做断言，换个实现就红。**

**通用规则：程序的逻辑分支永远不要依赖 `exnMessage`。** 要区分异常种类就用 `case ... of` 模式匹配构造子，或者用 `exnName`。

示例里的断言：

```sml
val _ = #checkRaises C ("safeDiv (7, 0)", fn () => (safeDiv (7, 0); ()), "BadDivisor")
val _ = #checkRaises C ("safeDiv (7, 2)", fn () => (safeDiv (7, 2); ()), "no exception")
val _ = #checkRaises C ("7 div 0", fn () => (7 div !zeroCell; ()), "Div")
val _ = #checkRaises C ("hd []", fn () => (hd []; ()), "Empty")
val _ = #checkRaises C ("Array.sub out of range",
                        fn () => (Array.sub (Array.array (2, 0), 5); ()), "Subscript")
```

```
2) exceptions: check the constructor name, not the message
  ok   safeDiv (7, 0) raises BadDivisor
  ok   safeDiv (7, 2) raises no exception
  ok   7 div 0 raises Div
  ok   hd [] raises Empty
  ok   Array.sub out of range raises Subscript
```

**第二个断言检查「不抛异常」，这很重要。** 只测「该抛的时候抛了」不够，还要测「不该抛的时候没抛」 —— 否则一个「无条件抛异常」的实现在前一个断言下也能通过。

**注意 `7 div !zeroCell` 那个 `!`。** 示例注释解释了：

```sml
(* 另外 7 div 0 要通过 ref 读出来，防止编译器在编译期就把它折叠掉。 *)
```

**MLton 是整体优化编译器**，看到 `7 div 0` 这种常量表达式可能会在编译期就算出来（然后报错或者直接让程序崩），而不是等到运行时抛 `Div`。**通过 `ref` 读一个变量，编译器就不知道值是多少了**，只能在运行时算 —— 于是异常在正确的地方抛出。

**这个技巧在写「测试编译器行为」的代码时经常需要。** 类似的手段还有：把值藏在 `fn` 后面、用 `Array.sub` 从一个运行时构造的数组里读，等等。**MLton 上尤其要注意**，因为它的常量折叠和部分求值很激进。

## 23.5 属性测试：固定输入集，绝不用随机数

```sml
val cases = [[], [1], [2, 1], [5, 4, 3, 2, 1], [1, 2, 3], [3, 1, 4, 1, 5, 9, 2, 6]]

val _ = List.app
    (fn xs =>
        (#checkTrue C ("length preserved for " ^ showL xs, length (isort xs) = length xs);
         #checkTrue C ("sorted result for " ^ showL xs, isSorted (isort xs));
         #checkTrue C ("isort is idempotent on " ^ showL xs, isort (isort xs) = isort xs)))
    cases
```

**三条性质（property）：**

1. **长度不变** —— 排序不增删元素
2. **结果有序** —— `isSorted` 检查
3. **幂等** —— 排两次和排一次一样

**这三条对任意列表都成立**，所以是真正的「性质测试」，而不是「抽查几个具体答案」。**性质测试比逐例断言的覆盖率高得多** —— 你不需要事先知道正确答案，只需要知道「什么性质必须成立」。

**输入集写死，不用随机数。** 示例注释：

```sml
(* 输入是写死的，不用随机数——随机数发生器换实现就换序列，
   那样三通道的逐字节比对立刻失效。 *)
```

**SML 的 `Random` 结构在不同实现上产生的序列不同**（种子算法、位宽都可能不一样）。用了随机数，三通道输出必然不同，比对就废了。**这是「可验证性」对「测试强度」的一次让步**：牺牲随机化，换来可复现。

**要两者兼得，可以用「写死的伪随机序列」**：

```sml
(* 线性同余，参数写死，跨实现完全可复现 *)
fun lcg seed = (1103515245 * seed + 12345) mod 2147483648
```

这样既有「大量看似随机的输入」，又完全确定。**这是测试里值得掌握的一招。**

**还有个写法要点：`fn xs => (e1; e2; e3)` 必须加括号。** 示例注释：

```sml
(* 注意 fn 的函数体里要用分号串联多个表达式，必须写成 (e1; e2; e3)，
   光写 fn xs => e1; e2 会把分号当成分号——那是声明层的语法。 *)
```

不包的话，`;` 在 `fn` 体里会把函数定义**截断**。MLton 上的报错是 `Undefined variable: xs` —— 因为第二个表达式被当成了独立声明，看不见 `xs`。**又是「分号 + 括号」**，这是本章第三次出现。

```
3) properties over a fixed input set
  ok   length preserved for []
  ok   sorted result for []
  ok   isort is idempotent on []
  ...
  ok   isort is idempotent on [3,1,4,1,5,9,2,6]
```

**18 条断言**（6 个输入 × 3 条性质），一眼看下去能确认覆盖度。

## 23.6 失败长什么样：刻意造一个失败的断言器

```sml
(* 4) 失败长什么样：另造一个断言器，故意给错期望 ----
   用独立的 checker，这样第 5 节的总计仍然是全绿。 *)
val bad = makeChecker ()

val _ = say "4) what a failure looks like (intentional, isolated checker)"
val _ = #checkInt bad ("2 + 2", 2 + 2, 5)
val _ = #checkList bad ("isort [3,1,2]", isort [3, 1, 2], [1, 3, 2])
val _ = #checkRaises bad ("safeDiv (7, 2)", fn () => (safeDiv (7, 2); ()), "BadDivisor")
val _ = say ("   this isolated checker reports " ^ #summary bad ())
```

```
4) what a failure looks like (intentional, isolated checker)
  FAIL 2 + 2 expected 5 but got 4
  FAIL isort [3,1,2] expected [1,3,2] but got [1,2,3]
  FAIL safeDiv (7, 2) expected BadDivisor but got no exception
   this isolated checker reports 3 checks / 0 passed / 3 failed
```

**为什么示例要故意制造失败？**

1. **证明失败检测本身是有效的。** 一个「从来不会报错」的测试框架比没有框架更危险 —— 它会给你虚假的安全感。**这一节就是「测试测试本身」**（meta-test）。
2. **展示失败长什么样。** 真看到红色输出的时候不至于慌。
3. **也是多通道比对里的一个「差异检测自证」**：这个输出在三通道下完全一致，说明「失败路径」也是可复现的。

**独立 checker 的设计在这里发挥作用**：`bad` 的失败不影响 `C` 的计数。

```
5) real test tally
   29 checks / 29 passed / 0 failed
```

**总计 29 条断言全绿。**

## 23.7 这个测试框架为什么够用

在三十行里，它提供了：

| 功能 | 实现方式 |
|---|---|
| 断言 | 记录里的四个函数 |
| 隔离 | 每次 `makeChecker ()` 一份私有计数器 |
| 统计 | `summary : unit -> string` |
| 输出 | 每条断言立刻打印 `ok`/`FAIL` |
| 失败信息 | 期望值 + 实际值都打出来 |
| 多实例 | 闭包封状态 |

**它没有的**：跳过、分组、setup/teardown、超时、并行、报告格式。**但对于示例和中小项目，这些都不必要。**

**你可以用这个模式扩展出任何想要的东西**：

```sml
type suite = { name : string, tests : (string * (unit -> unit)) list }

fun runSuite (s : suite) =
    let
        val c = makeChecker ()
        val _ = say ("== " ^ #name s)
        val _ = List.app (fn (_, f) => f ()) (#tests s)
    in
        #summary c ()
    end
```

**因为「测试」在 SML 里就是一个 `unit -> unit` 的函数**，任何聚合结构（列表、记录、树）都能拿来组织测试。这就是函数式语言写测试框架的便利之处 —— **测试和被测代码是同一类东西**。

---
