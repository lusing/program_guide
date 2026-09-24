# 12 · 算术

> 对应示例：[`examples/12_arith/12_arith.sml`](../examples/12_arith/12_arith.sml)

`num` 是 Peano 自然数，**不是**机器整数：没有负数，减法在 0 处截断。
大部分"算术证明写不出来"的挫败感，都来自把 C 语言的直觉搬了过来。
本章把这套算术的规则、决策过程和它咬人的地方过一遍。

## 12.1 Peano 与自然数字面量

```text
字面量 3        : 3
SUC(SUC(SUC 0)) : SUC (SUC (SUC 0))
两者能证相等    : ⊢ SUC (SUC (SUC 0)) = 3
类型            : :num
num 没有负数：  1 − 2 = 0
```

```sml
val _ = out ("字面量 3        : " ^ term_to_string ``3 : num``)
val _ = out ("SUC(SUC(SUC 0)) : " ^ term_to_string ``SUC (SUC (SUC 0))``)
val _ = out ("两者能证相等    : " ^ p ``SUC (SUC (SUC 0)) = (3 : num)`` (rw []))
val _ = out ("num 没有负数：  " ^
             (EVAL ``(1 : num) - 2`` |> concl |> term_to_string))
```

这是全套教程里最要紧的一条**项结构**事实：

- 字面量 `3` 打印出来就是 `3`，它在 `numeralTheory` 里是**二进制 numeral** 结构
  （`BIT1`/`BIT2`/`ZERO` 那一套），不是 `SUC` 链；
- `SUC (SUC (SUC 0))` 打印出来还带着 `SUC`；
- 两者**能证相等**（第三行），但**不是同一个项**。

所以按 `SUC (SUC n)` 写模式匹配的函数，喂进字面量时不会化简 ——
这就是 06.4 节 `fib` 原地踏步的根源。反过来，用 `n + 1` / `n - 1`
写递归（匹配 numeral 的算术）才跑得动。

最后一行：`1 - 2` 求值得到 `0`。`num` 上没有负数，减法被"削平"在 0。

## 12.2 基本定理

```text
⊢ ∀m. m + 0 = m
⊢ ∀m n. m + n = n + m
⊢ ∀m n. m * n = n * m
⊢ ∀m n p. m + (n + p) = m + n + p
⊢ ∀m n. m + n = n + m
```

```sml
val _ = out (thm_to_string ADD_0)
val _ = out (thm_to_string ADD_COMM)
val _ = out (thm_to_string MULT_COMM)
val _ = out (thm_to_string ADD_ASSOC)
val _ = out (thm_to_string (DB.fetch "arithmetic" "ADD_SYM"))
```

这些都是 `arithmeticTheory` 里的常备定理，`open arithmeticTheory` 后直接可见。
最后一行的 `ADD_SYM` 是 `ADD_COMM` 的另一个名字（打印出来完全一样），
说明**同名定理在不同理论里可能有多个入口** —— 找不到时先用 `DB.find`（22 章）。

常用的一批：`ADD_0` `ADD_ASSOC` `ADD_COMM` `MULT_0` `MULT_1` `MULT_ASSOC`
`MULT_COMM` `LEFT_ADD_DISTRIB` `RIGHT_ADD_DISTRIB` `LESS_TRANS` `LESS_EQ_TRANS`。

## 12.3 截断减法

```text
3 − 5 = 0
n - m + m ≠ n ：3 − 5 + 5 = 5
加上前提才行   ：⊢ ∀n m. m ≤ n ⇒ n − m + m = n
减法自己的定理 ：⊢ ∀m n. n ≤ m ⇒ m − n + n = m
```

```sml
val _ = out ((EVAL ``(3 : num) - 5`` |> concl |> term_to_string))
val _ = out ("n - m + m ≠ n ：" ^
             (EVAL ``((3 : num) - 5) + 5`` |> concl |> term_to_string))
val _ = out ("加上前提才行   ：" ^ p ``!n m : num. m <= n ==> n - m + m = n`` (rw []))
val _ = out ("减法自己的定理 ：" ^ thm_to_string SUB_ADD)
```

整数上的 `(n - m) + m = n` 是恒等式，`num` 上**不是**。
第二行是反例：`(3 - 5) + 5 = 0 + 5 = 5`，而 `n` 是 `3`。
这个例子也是 21 章"`EVAL` 找反例"的标准用法 —— 怀疑一个 `num` 恒等式时，
先拿几个具体数字 `EVAL` 一遍，比读证明快得多。

正确的版本必须带前提 `m ≤ n`，也就是第四行的 `SUB_ADD`
（注意它把变量名写成 `∀m n. n ≤ m ⇒ m − n + n = m`，量词顺序跟
"被减数/减数"的直觉是反的，用的时候看清楚）。

## 12.4 Presburger 算术决策过程

```text
DECIDE 线性     : ⊢ ∀n. n < n + 1
DECIDE 常数倍   : ⊢ 3 * x < 3 * x + 1
（乘常数还是 Presburger —— `3 * x` 只是 x+x+x。）

两条硬边界（用 show 直接调战术，不会触发 prove 的失败横幅）：
DECIDE 量词交替 : <tactic failed>
DECIDE 两变量乘 : <tactic failed>
第二条要自己分情况：
  ⊢ ∀n m. n * m = 0 ⇒ n = 0 ∨ m = 0

rw 比 DECIDE 强的地方：它会**分构造子情况**再化简。
rw 线性         : <closed>
rw 缺前提的减法 : n − m + m = n
rw 带前提的减法 : <closed>
```

```sml
val _ = out ("DECIDE 线性     : " ^ thm_to_string (DECIDE ``!n : num. n < n + 1``))
val _ = show "DECIDE 量词交替" DECIDE_TAC ``!n : num. ?m. m > n``
val _ = show "DECIDE 两变量乘" DECIDE_TAC ``!n m : num. n * m = 0 ==> n = 0 \/ m = 0``
val _ = out ("  " ^ p ``!n m : num. n * m = 0 ==> n = 0 \/ m = 0``
               (Cases_on `n` >> rw [] >> Cases_on `m` >> rw [] >> DECIDE_TAC))
```

`DECIDE : term -> thm` 直接给定理，`DECIDE_TAC : tactic` 在目标上用。
它实现的是 **Presburger 算术**（加法 + 序 + 常数量词），这是可判定的。
两条硬边界：

1. **量词交替**（`!n. ?m. …`）不在 Presburger 的可判定范围内；
2. **两个变量相乘**（`n * m`）是**非线性**，同样超出范围。

第二条的解法就在代码里：`Cases_on` 把 `n`、`m` 拆成 `0` / `SUC _` 四种情况，
每种情况下乘法都退化成常量倍或 0，剩下的交给 `DECIDE_TAC`。
**"归纳/分情况 + 决策过程"是处理非线性算术的标准手法。**

最后三行给出 `rw` 的位置：

- 线性目标 `rw` 能过（它内部就调了算术化简）；
- `n - m + m = n` 缺前提，`rw` **过不了**，原样留下目标
  （这一行打印的是 `n − m + m = n`，也就是"没证出来"）；
- 加上 `m ≤ n` 就过了。

> **这里有个演示上的讲究**：上面失败的两行是用 `show` 直接调战术拿到的。
> 如果改用 `prove (t, tac)`，`prove` 在战术失败时会打印一整块"失败横幅"
> 然后 abort，看不出"战术失败了"这一事实本身。要演示"过不了"，用 `show`。

另外提醒一句（24.6 节有血的教训）：别急着把 `ADD_COMM` / `MULT_COMM`
塞进 `rw` 的列表里帮它。交换律当重写规则喂给化简器容易让它绕圈，
`rw` 自带的算术归一化已经能处理 `eval e2 + eval e1 = eval e1 + eval e2` 这类目标。

## 12.5 序与 SUC

```text
n < SUC n : ⊢ ∀n. n < SUC n
SUC 单调   : ⊢ ∀n m. n < m ⇒ SUC n < SUC m
反方向     : ⊢ ∀n m. SUC n < SUC m ⇒ n < m
```

```sml
val _ = out ("n < SUC n : " ^ p ``!n : num. n < SUC n`` (rw []))
val _ = out ("SUC 单调   : " ^ p ``!n m : num. n < m ==> SUC n < SUC m`` (rw []))
val _ = out ("反方向     : " ^ p ``!n m : num. SUC n < SUC m ==> n < m`` (rw []))
```

`SUC` 对 `<` 是双向单调的，两条方向 `rw` 都能一步吃掉。
但注意这里的前提里出现了 `SUC`：在 `num` 上写归纳证明时，
归纳步骤里的 `SUC n` 常常会跟 numeral 字面量打架
（`SUC n` 和 `n + 1` 可证相等但不同项），需要 `rw` 或 `simp` 来抹平。

## 12.6 除法与取模

```text
7 DIV 3    : 7 DIV 3 = 2
7 MOD 3    : 7 MOD 3 = 1
除法算法   : ⊢ ∀n. 0 < n ⇒ ∀k. k = k DIV n * n + k MOD n ∧ k MOD n < n
MOD 有界   : ⊢ ∀m n. 0 < n ⇒ m MOD n < n
```

```sml
val _ = out ("7 DIV 3    : " ^ (EVAL ``(7 : num) DIV 3`` |> concl |> term_to_string))
val _ = out ("除法算法   : " ^ thm_to_string DIVISION)
val _ = out ("MOD 有界   : " ^ thm_to_string MOD_LESS)
```

`DIV` / `MOD` 是**可计算的**：`EVAL` 能直接算出来。
但它们的定理几乎全都带 `0 < n` 的前提 —— 除以 0 的行为在
`num` 上虽然有定义（`x DIV 0 = 0`），可所有好用的定理都绕开它。

`DIVISION` 是"带余除法"的标准陈述，一眼看去有点绕：
`k = k DIV n * n + k MOD n ∧ k MOD n < n`，量词顺序是 `∀n. 0 < n ⇒ ∀k. …`
（除数在前、被除数在后）。

## 12.7 归纳与算术配合

```text
⊢ ∀n. n ≤ sumto n
⊢ ∀n. sumto (SUC n) = sumto n + SUC n
求值校核   : sumto 10 = 55
```

```sml
Definition sumto_def:
  (sumto 0 = 0) /\
  (sumto (SUC n) = sumto n + SUC n)
End
val _ = out (thm_to_string (prove(``!n : num. n <= sumto n``,
                                  Induct_on `n` >> rw [sumto_def])))
val _ = out ("求值校核   : " ^ (EVAL ``sumto 10`` |> concl |> term_to_string))
```

这里把定义写成匹配 `SUC n` 的形式，是为了让 `Induct_on` 的步骤直接对上。
`rw [sumto_def]` 一件事做三件：展开 `sumto`、把 `SUC n` 与 numeral 抹平、
把归纳假设当重写规则用掉。

`sumto 10 = 55` 是**求值校核**：定义能不能跑，跑出来的数对不对，
用 `EVAL` 一句话就能确认，比证明省事得多。写任何递归定义后先求个值。

> 想证真正的求和公式 `2 * sumto n = n * (n + 1)` 需要归纳 + 环/半环工具
> （`ring`/`numring`），单纯的 `DECIDE` 处理不了二次的等式。

## 12.8 坑位清单

1. **字面量 `3` 不是 `SUC (SUC (SUC 0))`** → 按 SUC 写模式匹配的函数算不动（06.4）。
2. **`num` 上没有负数** → `1 - 2 = 0`。
3. **`(n - m) + m = n` 不成立** → 必须带前提 `m ≤ n`（`SUB_ADD`）。
4. **`SUB_ADD` 的量词顺序是反的** → `∀m n. n ≤ m ⇒ m − n + n = m`，别照变量名字读。
5. **`DECIDE` 处理不了量词交替** → `!n. ?m. …` 直接失败。
6. **`DECIDE` 处理不了两个变量相乘** → 用 `Cases_on` 拆成常量倍再交给它。
7. **`rw` 缺前提时静默留下目标** → 它不像 `prove` 会横幅报警；演示"过不了"要用 `show`。
8. **别把 `ADD_COMM` / `MULT_COMM` 塞进 `rw`** → 交换律当重写规则会让化简器绕圈（24.6）。
9. **`DIVISION` 的量词是"除数在前"** → `∀n. 0 < n ⇒ ∀k. …`。
10. **`DIV`/`MOD` 定理几乎都带 `0 < n`** → 除数为 0 的情形要单独处理。

---

上一章：[11 · 转换](11-conv.md) ·
下一章：[13 · 列表](13-lists.md)
