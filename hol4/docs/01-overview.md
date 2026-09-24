# 01 · 开场：HOL4 的心智模型与环境自检

> 对应示例：[`examples/01_env/01_env.sml`](../examples/01_env/01_env.sml)

本章不引入新语法，只回答三个问题：**这台机器上的 HOL4 是不是真的能跑**、
**"定理"在 HOL4 里到底是个什么值**、**一条完整的「定义 → 证明 → 求值」闭环
长什么样**。后面 23 章全部建立在这三件事之上。

> 与仓库里其它语言教程不同，本教程的第 1 章也有可运行的示例目录 ——
> HOL4 的"环境自检"本身就是值得跑的东西（内核版本、当前理论、库是否齐全），
> 把它写成脚本才能让别人复现。

## 01.1 环境自检：内核版本与当前理论

任何一门语言，第一步都该确认"这台机器上的工具是哪个版本"。
HOL4 的版本号在 `Globals.version`，当前理论名在 `Theory.current_theory ()`：

```text
Globals.version = 2
current_theory  = Tut01
```

```sml
val _ = out ("Globals.version = " ^ Int.toString Globals.version)
val _ = out ("current_theory  = " ^ Theory.current_theory ())
```

> `Globals.version` 是 `int`，直接跟字符串拼接会报 "can't unify string with int"。
> 本教程里每个"看起来该是字符串"的值都过一遍 `Int.toString` / `Bool.toString`。

"当前理论"是 HOL4 特有的概念：一个脚本不是"跑一遍就完"的程序，
它是一份**理论** —— 跑完会把所有定义和定理写进一张带名字的表。
这里是 `Tut01`，因为脚本开头调了 `new_theory "Tut01"`。

## 01.2 定理是一个 ML 值

HOL4 的元语言是 Standard ML。项、类型、定理、战术**都是普通的 ML 值**，
可以绑定、可以传参、可以放进列表。这条是理解后面一切的钥匙：

```text
⊢ 1 = 1
假设个数 = 0
结论     = 1 = 1
```

```sml
val th = REFL ``1 : num``
val (asms, concl) = dest_thm th
```

`dest_thm` 把一个定理拆成 `(假设列表, 结论)`。打印时 `⊢` 左边方括号里的点
代表假设：

<!-- 示意 -->
```text
 [.] ⊢ p        ← 一条假设
 [..] ⊢ p ⇒ r   ← 两条假设
```

一个点一个假设 —— 这个记法后面 24 章会一直出现。

## 01.3 最小闭环：prove

`prove` 把**一个项（命题）**和**一个战术**变成一条定理。
这是 HOL4 里最高频的一个函数：

```text
⊢ ∀n. n + 0 = n
```

```sml
val th1 = prove(``!n : num. n + 0 = n``, Induct_on `n` >> simp [])
```

注意参数的位置：先是**引号里的项**，再是**一个 tactic 值**。
`>>` 是 tactic 的顺序组合（10 章详述）。

> `prove` 返回的是定理，不是"证明成功"这个信号。
> 证不出来它抛异常，脚本会中断 —— 这正是我们想要的（见 23 章）。

## 01.4 求值：EVAL

和 `prove` 并列的另一台机器是 `EVAL`：它不构造证明，而是**把闭项算成值**，
返回的仍然是一条等式定理：

```text
⊢ 1 + 2 * 3 = 7
⊢ LENGTH [1; 2; 3] = 3
```

```sml
val _ = out (thm_to_string (EVAL ``1 + 2 * 3``))
val _ = out (thm_to_string (EVAL ``LENGTH [1; 2; 3]``))
```

> 区分：`prove` 是"讲道理"，`EVAL` 是"拨算盘"。
> `EVAL` 走的是内核里的计算规则，对**含变量的项**一步都走不动（21 章）。

## 01.5 库自检

本教程会用到 `arithmeticTheory`、`listTheory`、`pred_setTheory`、
`relationTheory` 等。先把关键常量的类型打出来，确认它们在堆镜像里：

```text
LENGTH : :α list -> num
UNION  : :(α -> bool) -> (α -> bool) -> α -> bool
RTC    : :(α -> α -> bool) -> α -> α -> bool
```

```sml
val _ = out ("LENGTH : " ^ (type_of ``LENGTH`` |> type_to_string))
val _ = out ("UNION  : " ^ (type_of ``$UNION`` |> type_to_string))
val _ = out ("RTC    : " ^ (type_of ``RTC`` |> type_to_string))
```

`UNION` 前面的 `$` 不是装饰：它是保留词，写成项时必须加前缀（02.6 节）。

## 01.6 反例：凭空断言不被接受

HOL4 的可靠性来自"小内核"：所有定理最终都由少数几条原始规则造出来。
所以一个新建的理论里，定理数是 0 —— 什么都没证出来之前，什么都拿不到：

```text
定理总数（本理论内）= 0
```

```sml
val _ = out ("定理总数（本理论内）= " ^
             Int.toString (length (DB.theorems "Tut01")))
```

> 用 `mk_thm` 可以凭空造出"定理"，但它会被打上 oracle 标记，
> 任何下游定理都会继承这个标记（04.8 节）。这是 HOL4 的"诚实指针"：
> 你可以撒谎，但谎话会被一路标出来。

## 01.7 坑位清单

1. **`Globals.version` 是 int，不是 string** → 拼接前要 `Int.toString`，否则报 "can't unify string with int"。
2. **`open` 写在 `val _ =` 里会解析失败** → `open` 必须在顶层单独一行，不能写成 `val _ = open arithmeticTheory`。
3. **`it` 在脚本里不存在** → `it` 只有交互式 REPL 才有；脚本里每个值都要自己起名字。
4. **`UNION` / `INSERT` / `SUBSET` 写成项要加 `$`** → 它们是保留词，裸写报 "No rule for [UNION]"。
5. **数字默认是 `num` 不是 `int`** → `1` 在项里是自然数；SML 里的 `1` 是 `int`。两套数不要混。
6. **`prove` 证不出来会抛异常而不是返回空** → 想"试一下"要自己 `handle`（见 08 章的 `try_tac`）。
7. **`EVAL` 只算闭项** → `EVAL ``LENGTH l``` 得到的是 `⊢ LENGTH l = LENGTH l`，一个重言式。
8. **新建理论的定理数是 0** → 别指望 `DB.theorems "Tut01"` 里有任何东西，全是自己证的。
9. **`⊢` 左边方括号里的点代表假设个数** → `[.]` 一条、`[..]` 两条；不是输出噪声。
10. **脚本里不能依赖上一次运行留下的状态** → Holmake 会缓存，第二次跑的时候环境是干净的（23.7 节）。

---

下一章：[02 · 项、类型与引号](02-terms.md)
