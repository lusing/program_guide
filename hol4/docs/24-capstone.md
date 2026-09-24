# 24 · 综合练习：一个表达式编译器

> 对应示例：[`examples/24_capstone/24_capstone.sml`](../examples/24_capstone/24_capstone.sml)

把前 23 章的东西凑成一个能站得住的小工程：
**定义一门语言 → 写它的语义 → 写一台机器 → 写编译器 → 证明编译器对**，
最后再加一个"保持语义的优化"作为收尾。

这是编译原理里最小的那个完整闭环，也是"验证"这件事最典型的形态。

## 24.1 语法

```text
<<HOL message: Defined type: "expr">>
四个赠品里的穷举：⊢ ∀ee. (∃n. ee = Cst n) ∨ (∃e e0. ee = Add e e0) ∨ ∃e e0. ee = Mul e e0
区分性：⊢ (∀a1 a0 a. Cst a ≠ Add a0 a1) ∧ (∀a1 a0 a. Cst a ≠ Mul a0 a1) ∧
  ∀a1' a1 a0' a0. Add a0 a1 ≠ Mul a0' a1'
归纳原理：⊢ ∀P. (∀n. P (Cst n)) ∧ (∀e e0. P e ∧ P e0 ⇒ P (Add e e0)) ∧
      (∀e e0. P e ∧ P e0 ⇒ P (Mul e e0)) ⇒
      ∀e. P e
```

```sml
val _ = Datatype `expr = Cst num | Add expr expr | Mul expr expr`
val _ = out ("归纳原理：" ^ thm_to_string (DB.fetch "Tut24" "expr_induction"))
```

一门算术表达式语言，三个构造子。`Datatype` 照例送四条定理（05 章），
这里拿了三条出来看：

- `expr_nchotomy` —— **穷举**：任何表达式都是 `Cst` / `Add` / `Mul` 之一；
- `expr_distinct` —— **区分性**：不同构造子造出来的东西不相等；
- `expr_induction` —— **归纳原理**：证 `∀e. P e` 只需证三个构造子的情况，
  其中 `Add`/`Mul` 各带**两个**归纳假设。

第三条是这一章全部证明的发动机。

## 24.2 语义

```text
⊢ (∀n. eval (Cst n) = n) ∧ (∀e1 e2. eval (Add e1 e2) = eval e1 + eval e2) ∧
  ∀e1 e2. eval (Mul e1 e2) = eval e1 * eval e2
求值：eval (Add (Cst 2) (Mul (Cst 3) (Cst 4))) = 14
```

```sml
Definition eval_def:
  (eval (Cst n) = n) /\
  (eval (Add e1 e2) = eval e1 + eval e2) /\
  (eval (Mul e1 e2) = eval e1 * eval e2)
End
val _ = out ("求值：" ^ ev ``eval (Add (Cst 2) (Mul (Cst 3) (Cst 4)))``)
```

`eval` 是**指称语义**：直接把表达式翻译成一个 `num`。
它是可执行的，所以 `EVAL` 能算出 `2 + 3 * 4 = 14`。

## 24.3 栈机

```text
<<HOL message: Defined type: "instr">>
<<HOL warning: Context.snapshot: ambient context read while a proof was running (in Tut24)>>
⊢ (∀st. run [] st = st) ∧ (∀st n is. run (Push n::is) st = run is (n::st)) ∧
  (∀st is. run (IAdd::is) st = run is (HD st + HD (TL st)::TL (TL st))) ∧
  ∀st is. run (IMul::is) st = run is (HD st * HD (TL st)::TL (TL st))
跑一段：run [Push 2; Push 3; IAdd] [] = [5]
```

```sml
val _ = Datatype `instr = Push num | IAdd | IMul`
Definition run_def:
  (run ([] : instr list) st = st) /\
  (run (Push n :: is) st = run is (n :: st)) /\
  (run (IAdd :: is) st = run is (HD st + HD (TL st) :: TL (TL st))) /\
  (run (IMul :: is) st = run is (HD st * HD (TL st) :: TL (TL st)))
End
```

一台栈机：三条指令，状态是一个 `num list`（栈）。
`IAdd` 弹出栈顶两个元素相加再压回去，`IMul` 同理。

两处说明：

- **栈不够时怎么办？** `HD []` / `TL []` 在 HOL 里不是错误，
  它们返回"某个 `num`"（未指定的值）。本章只跑**合法程序**
  （编译器生成的指令序列一定不会下溢），所以这个行为不影响结论。
  想严格处理就得给 `HD`/`TL` 加前提，那会让每条定理都多一堆簿记 ——
  工程上常见的取舍是先约定"只讨论良构输入"。
- 输出里那条 `Context.snapshot` 警告跟 16.5 节同源，是良性的。

## 24.4 编译器

```text
⊢ (∀n. compile (Cst n) = [Push n]) ∧
  (∀e1 e2. compile (Add e1 e2) = compile e1 ⧺ compile e2 ⧺ [IAdd]) ∧
  ∀e1 e2. compile (Mul e1 e2) = compile e1 ⧺ compile e2 ⧺ [IMul]
编译：compile (Add (Cst 2) (Mul (Cst 3) (Cst 4))) =
[Push 2; Push 3; Push 4; IMul; IAdd]
先跑一遍确认没错：
  run (compile (Add (Cst 2) (Mul (Cst 3) (Cst 4)))) [] = [14]
```

```sml
Definition compile_def:
  (compile (Cst n) = [Push n]) /\
  (compile (Add e1 e2) = compile e1 ++ compile e2 ++ [IAdd]) /\
  (compile (Mul e1 e2) = compile e1 ++ compile e2 ++ [IMul])
End
```

标准的中缀转后缀：先编译左子树、再编译右子树、最后放运算符。

最后两行是**求值校核**：编译出来的指令跑一遍，得到 `[14]`，
跟 24.2 的 `eval` 结果一致。**先跑一遍再证** —— 这是性价比最高的一步，
能在写证明之前抓出定义里的低级错误。

## 24.5 拼接引理

```text
主定理要处理 compile e1 ++ compile e2 ++ [IAdd]，
所以先要一条「两段指令接起来跑」的引理。
它对 is1 做归纳，同时**把 st 泛化**（否则归纳假设不够用）：
  ⊢ ∀is1 is2 st. run (is1 ⧺ is2) st = run is2 (run is1 st)
```

```sml
val run_append = store_thm ("run_append",
  ``!is1 is2 st. run (is1 ++ is2) st = run is2 (run is1 st)``,
  Induct >> rw [run_def] >> Cases_on `h` >> rw [run_def])
```

这是本章**最关键的一步**，也是 13.5 / 13.6 那条路的完整重演。

主定理在处理 `compile (Add e1 e2)` 时会碰到
`run (compile e1 ⧺ compile e2 ⧺ [IAdd]) st`
—— 一整串拼接起来的指令。要让归纳走得动，必须先有一条
"**两段指令接起来跑 = 先跑第一段、再拿结果跑第二段**"的引理。

写法上有两个讲究：

1. **`st` 必须是全称量词**（`!is1 is2 st.`）。
   如果只写 `!is1 is2. run (is1 ++ is2) [] = ...`，
   归纳假设就被钉在 `st = []` 上，归纳步骤里 `st` 会变成非空栈，套不上。
   这正是 21.7 节 `revacc` 那个例子的同一件事。
2. **`Cases_on \`h\``** —— 归纳到 `is1 = h::t` 时，`h` 是 `instr`，
   必须再分 `Push n` / `IAdd` / `IMul` 三种情况才能把 `run` 展开。

## 24.6 编译器正确

```text
形式：对任意表达式和任意初始栈，编译后跑出来的栈 = 原栈前面
压上 eval 的结果。写成带 st 的形式，归纳才做得动。
  ⊢ ∀e st. run (compile e) st = eval e::st

证明只有三行，但每一行的分量：
  Induct         —— 用 expr_induction，st 自动被泛化；
  rw [...]      —— 展开 compile / eval / run，用 run_append 把
                   `compile e1 ++ compile e2 ++ [IAdd]` 拆开，
                   最后一步的 `eval e2 + eval e1 = eval e1 + eval e2`
                   由 rw 自带的算术归一化解决。
```

```sml
val compile_correct = store_thm ("compile_correct",
  ``!e st. run (compile e) st = eval e :: st``,
  Induct
  >> rw [compile_def, eval_def, run_def, run_append])
```

主定理：**编译后跑出来的栈 = 原栈前面压上 `eval` 的结果。**

注意它写成 `∀e st. …`（带任意初始栈 `st`），而不是 `∀e. run (compile e) [] = [eval e]`。
理由跟 24.5 一样 —— **归纳假设必须足够强**。带 `st` 的版本归纳时
`st` 会自动被泛化，不带 `st` 的版本会在归纳步骤卡住。

证明本身只有三行，但每一行的分量：

- **`Induct`** —— 用 24.1 的 `expr_induction`，`st` 自动泛化；
- **`rw [compile_def, eval_def, run_def, run_append]`** ——
  展开全部定义，用 24.5 的 `run_append` 把拼接的指令拆开，
  最后落到 `eval e2 + eval e1 = eval e1 + eval e2` 这类交换律上，
  由 `rw` 自带的算术归一化解决。

> **这里有个实测过的坑**：最后那步交换律**不要**手动加 `ADD_COMM` / `MULT_COMM`。
> 把它们当重写规则喂给 `rw` 会让化简器来回翻，实测**跑不完**（被看门狗 KILL）。
> `rw` 自带的算术归一化已经能处理这类目标 —— 12.4 节和 23 章都提到过。

## 24.7 常量折叠

```text
⊢ (∀n. opt (Cst n) = Cst n) ∧
  (∀e1 e2. opt (Add e1 e2) = opt_add (opt e1) (opt e2)) ∧
  ∀e1 e2. opt (Mul e1 e2) = opt_mul (opt e1) (opt e2)
跑一下：
  opt (Add (Cst 2) (Mul (Cst 3) (Cst 4))) = Cst 14
它产生的指令更少：
  compile (opt (Add (Cst 2) (Mul (Cst 3) (Cst 4)))) = [Push 14]
```

```sml
Definition opt_add_def:
  (opt_add (Cst m) (Cst n)   = Cst (m + n)) /\
  (opt_add (Cst m) (Add a b) = Add (Cst m) (Add a b)) /\
  ...
End
Definition opt_def:
  (opt (Cst n) = Cst n) /\
  (opt (Add e1 e2) = opt_add (opt e1) (opt e2)) /\
  (opt (Mul e1 e2) = opt_mul (opt e1) (opt e2))
End
```

一个"常量折叠"优化：把 `2 + 3 * 4` 直接算成 `14`。
效果很直观 —— 编译出来的指令从 5 条缩到 1 条。

写法上有个**非平凡**的取舍，值得单独讲：

```sml
(* 想写这样是很自然的，但它会卡住化简器： *)
opt (Add e1 e2) = case (opt e1, opt e2) of (Cst m, Cst n) => Cst (m + n) | ...
```

问题在于：化简器**没法对一个非常量的 scrutinee 做 case 分裂**。
`(opt e1, opt e2)` 是运行时才能算出来的东西，`rw` 拆不开它。

解法就是上面代码里的做法：**把"两边都是常量"的判断拆成一个独立的二元函数**
`opt_add` / `opt_mul`。它们的模式全是常量构造子（`Cst m` / `Add a b` / `Mul a b`），
于是两个 `Cases` 就能把 3×3 = 9 种情况分干净。

> **套路**：当 `rw` 卡在一个 `case` 上时，看看 scrutinee 是不是常量。
> 不是就想办法把它变成某个独立函数的参数 —— 模式变成常量，才能被分裂。

## 24.8 引理先行

```text
先给两个辅助函数各自的引理 —— 它们的模式都是常量，
两个 Cases 就能分干净：
  ⊢ ∀a b. eval (opt_add a b) = eval a + eval b
  ⊢ ∀a b. eval (opt_mul a b) = eval a * eval b
有了这两条，主定理就只剩一层归纳：
  ⊢ ∀e. eval (opt e) = eval e
```

```sml
val opt_add_sound = store_thm ("opt_add_sound",
  ``!a b. eval (opt_add a b) = eval a + eval b``,
  Cases >> Cases >> rw [opt_add_def, eval_def])
val opt_sound = store_thm ("opt_sound", ``!e. eval (opt e) = eval e``,
  Induct >> rw [opt_def, eval_def, opt_add_sound, opt_mul_sound])
```

又一次"**引理先行**"（13.5 节的同一条路）：

1. 先给两个辅助函数各自的可靠性引理。`opt_add` / `opt_mul` 的模式是常量，
   所以 **`Cases >> Cases` 分 9 种情况**，`rw` 全部收掉。
2. 有了这两条，主定理 `opt_sound` 就只剩**一层归纳**：
   `Induct >> rw [opt_def, eval_def, opt_add_sound, opt_mul_sound]`。

对比一下：如果当初把折叠逻辑写进 `opt` 内部的 `case`，
这里就得在归纳的同时处理非常量 scrutinee，几乎必然卡住。
**24.7 那个取舍是在为这一步铺路。**

## 24.9 两个定理合起来

```text
把 opt_sound 和 compile_correct 拼起来，就得到
「优化后的程序跑出来的值不变」：
  ⊢ ∀e st. run (compile (opt e)) st = eval e::st

这正是本教程想给的东西：机器只负责执行，
人负责把「为什么对」讲清楚，而 HOL 负责检查你讲得对不对。
```

```sml
val _ = out ("  " ^ p ``!e st. run (compile (opt e)) st = eval e :: st``
                (rw [compile_correct, opt_sound]))
```

最后一行把两条定理拼起来，得到端到端的结论：

```
优化不改变程序的行为。
```

它只有一行，因为前面两步已经把难的部分各自解决了：
`compile_correct` 说"编译是对的"，`opt_sound` 说"优化不改变语义"，
`rw` 拿它们当重写规则一路替换就完事。

**这就是模块化证明的价值** —— 两个定理各自独立、可复用、可单独测试，
拼起来的时候一行就够了。

## 24.10 这一路用到的东西

```text
05 章  Datatype 的赠品（nchotomy / distinct / induction）
06 章  递归定义与终止性检查
07 章  归纳假设不够强时怎么泛化（run_append 的 st）
08 章  化简器把定义展开
13 章  列表上的 APPEND / HD / TL
12 章  最后一步的线性算术
22 章  store_thm 把引理存进理论，供后面 fetch
23 章  让上面这一切能被别人复现的脚本纪律
```

这一章把前面 23 章的主要工具都用了一遍。回头看，最要紧的三条是：

1. **归纳假设必须足够强**（07 / 13.5 / 21.7 / 24.5 / 24.6）——
   卡住时先想"要不要泛化"，而不是换更强的自动化；
2. **引理先行**（13.5 / 24.5 / 24.8）——
   把"能单独说清楚的部分"拆成独立定理，主定理就只剩一层归纳；
3. **让机器的活和人的活分开**（21 / 23）——
   机器负责执行和检查，人负责把"为什么对"讲清楚。

## 24.11 坑位清单

1. **`run_append` 的 `st` 必须全称量化** → 只写 `[]` 会让归纳假设套不上。
2. **`compile_correct` 同样要带 `st`** → 归纳假设才够强。
3. **别把 `ADD_COMM` / `MULT_COMM` 喂给 `rw`** → 交换律当重写规则会绕圈跑不完。
4. **`case (opt e1, opt e2) of …` 拆不开** → scrutinee 不是常量；拆成独立的二元函数。
5. **`opt_add` / `opt_mul` 要 `Cases >> Cases`** → 3×3 共 9 种情况。
6. **`HD []` / `TL []` 不是错误** → 它们返回未指定的值；本章靠"只跑合法程序"规避。
7. **`Datatype` 的定理要 `DB.fetch`** → 它不给 ML 绑定。
8. **先 `EVAL` 求值校核再写证明** → 能提前抓出定义里的低级错误。
9. **`Context.snapshot` 警告是良性的** → 与 16.5 节同源，三条通道里一致出现。
10. **模块化证明让最后一步只剩一行** → `compile_correct` + `opt_sound` 各自独立可复用。

---

上一章：[23 · 脚本工程](23-engineering.md)
