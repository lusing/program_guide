# 21 · 自动化工具箱

> 对应示例：[`examples/21_automation/21_automation.sml`](../examples/21_automation/21_automation.sml)

HOL4 里有四台"能自己把活干完"的机器：求值器、Presburger 算术判定、
命题判定、一阶判定。这一章逐个看它们各自能干什么、在哪一步收手，
以及"把它们接起来"的标准手法。

## 21.1 四台机器

```text
求值器      EVAL            —— 把闭项算成值
算术判定    DECIDE_TAC      —— Presburger 算术（加减、常数乘法、不等号）
命题判定    TAUT_PROVE      —— 命题演算（含 bool 变量）
一阶判定    metis_tac       —— 一阶逻辑 + 等词

它们的关系不是「谁更强」，而是「谁认识哪些符号」：
  EVAL 只认可执行的方程，DECIDE 只认算术符号，
  TAUT 只认命题连接词，metis 认全称量词和等词但不认算术。
```

```sml
val _ = out ("求值器      EVAL            —— 把闭项算成值")
val _ = out ("算术判定    DECIDE_TAC      —— Presburger 算术（加减、常数乘法、不等号）")
```

把它们记成"四台机器"而不是"四个强度等级"，是关键。
它们不是包含关系，而是**各认一套符号**：

| 机器 | 认识的符号 | 不认识的 |
|---|---|---|
| `EVAL` | 可执行的方程（递归定义） | 变量、量词、任何推理 |
| `DECIDE_TAC` | `+` `-` `<` `≤` 常量倍 | 量词、两变量乘法 |
| `TAUT_PROVE` | `∧` `∨` `⇒` `¬` | 量词内部、等词（当原子看） |
| `metis_tac` | `∀` `∃`（实例化）、等词 | 定义展开、归纳、算术 |

## 21.2 求值器

```text
⊢ fact 6 = 720
⊢ REVERSE [1; 2; 3] = [3; 2; 1]
有变量时它一步都走不动：
  ⊢ LENGTH l = LENGTH l
（结果是 `⊢ LENGTH l = LENGTH l` —— 一个重言式，不是化简。）
```

```sml
Definition fact_def:
  (fact 0 = 1) /\ (fact (SUC n) = SUC n * fact n)
End
val _ = out (thm_to_string (EVAL ``fact 6``))
val _ = out ("  " ^ thm_to_string (EVAL ``LENGTH (l : num list)``))
```

`EVAL` 把**闭项**（没有自由变量）按定义一路算成值。
`fact 6 = 720`、`REVERSE [1;2;3] = [3;2;1]` 都是它的活。

第三行是它的边界：`LENGTH l` 里有自由变量 `l`，它一步都走不动，
返回的定理是 `⊢ LENGTH l = LENGTH l` —— **一个重言式，不是化简**。

> 这个特性可以反过来用：**`EVAL` 是找反例最快的工具。**
> 怀疑某个 `num` 恒等式时，先拿几个具体数字 `EVAL` 一遍
> （12.3 节用 `(3 - 5) + 5 = 5` 反驳了 `n - m + m = n`）。

注意 `fact` 定义里用的是 `SUC n` 而不是 `n + 1`：
`EVAL \`fact 6\`` 能算出 `720`，是因为求值器会把 numeral 和
`SUC` 之间抹平（06.4 节那个 `fib` 原地踏步是**化简器**的行为，
跟求值器不是一回事）。

## 21.3 DECIDE_TAC / ARITH_CONV

```text
DECIDE_TAC 直接证：⊢ x < x + 1
不等号链：⊢ x ≤ y ⇒ y < z ⇒ x < z
numLib.ARITH_CONV 把命题化成 T/F：
  ⊢ x < x + 1 ⇔ T
  （要用 numLib.ARITH_CONV，裸 ARITH_CONV 在本版本没有绑定。）

它不认识量词 —— 带量词的目标直接上 DECIDE_TAC：
DECIDE 带量词   : <tactic failed>
量词拆掉、witness 给上之后就行：
  ⊢ ∀n. ∃m. m > n
它也不认识乘法里的两个变量（那就不是 Presburger 了）：
DECIDE 两变量乘 : <tactic failed>
所以 `∀n. n ≤ n * n` 得靠归纳 + 化简，DECIDE_TAC 单独上不行：
  ⊢ ∀n. n ≤ n * n
```

```sml
val _ = out ("DECIDE_TAC 直接证：" ^ p ``(x : num) < x + 1`` DECIDE_TAC)
val _ = out ("numLib.ARITH_CONV 把命题化成 T/F：")
val _ = out ("  " ^ thm_to_string (numLib.ARITH_CONV ``(x : num) < x + 1``))
val _ = show "DECIDE 带量词  " DECIDE_TAC ``!n : num. ?m. m > n``
```

两个入口，同一套判定过程：

| 入口 | 类型 | 返回 |
|---|---|---|
| `DECIDE` | `term -> thm` | 直接给定理（不带 `⇔ T`） |
| `DECIDE_TAC` | `tactic` | 在目标上用 |
| `numLib.ARITH_CONV` | `conv` | 把命题化成 `⊢ p ⇔ T` |

> **必须写 `numLib.ARITH_CONV`**：本版本里裸的 `ARITH_CONV` 没有绑定
> （报 unbound），这一点在 12 章和 11 章也提到过。

三条硬边界（都用 `show` 直接调战术拿到的，这样才能看出"战术失败了"）：

1. **带量词的目标直接失败** —— 拆掉量词、给出 witness 之后就行；
2. **两个变量相乘失败** —— 那就不是 Presburger 了；
3. 于是 `∀n. n ≤ n * n` 只能靠 `Induct_on >> rw [MULT_CLAUSES]`。

> 演示"过不了"时一定要用 `show` 这类"直接调战术"的辅助函数，
> 不能用 `prove` —— 后者在战术失败时会打印一大块失败横幅然后 abort，
> 你反而看不出"战术失败了"这件事本身。

## 21.4 TAUT_PROVE

```text
参数是**项**不是引号：tautLib.TAUT_PROVE ``…``
  ⊢ a ∧ b ⇒ b
  ⊢ (a ⇒ b) ⇒ (b ⇒ c) ⇒ a ⇒ c
  ⊢ a ∨ ¬a
带量词的它其实也能过，那是因为量词被当成了原子命题：
  ⊢ ∀x. x ∨ ¬x
```

```sml
val _ = out ("  " ^ thm_to_string (tautLib.TAUT_PROVE ``(a : bool) /\ b ==> b``))
val _ = out ("  " ^ thm_to_string (tautLib.TAUT_PROVE ``(a : bool) \/ ~a``))
```

`tautLib.TAUT_PROVE` 接的是**项**（`` ``…`` ``），返回**定理**。
它不是战术，所以**不能**放进 `prove` 的第二个参数里。

最后一行是个容易误读的地方：`⊢ ∀x. x ∨ ¬x` 看起来"能处理量词"，
其实是因为**整个 `∀x. …` 被当成了一个原子命题**，
而它恰好和 `x ∨ ¬x` 是同一个重言式模板。别指望它真的做量化推理。

## 21.5 metis_tac

```text
等词是对称的：⊢ f x = f y ⇔ f y = f x
把已有定理喂给它，它替你做 Modus Ponens：
  已知：⊢ ∀l x. MEM x l ⇒ LENGTH l > 0
  求证：⊢ MEM 1 l ⇒ LENGTH l > 0

但那条「已知」本身 metis 证不出来 —— 它不会分构造子：
metis 直上     : <tactic failed>
真正的分工长这样：
  ⊢ ∀l x. MEM x l ⇒ LENGTH l > 0
  Induct 负责拆结构、rw 负责展开定义 —— metis 只在最后拼逻辑。
```

```sml
val _ = out ("等词是对称的：" ^ p ``(f (x : num) = f y) = (f y = f x)``
                (metis_tac []))
val mem_pos = prove(``!l : num list. !x. MEM x l ==> LENGTH l > 0``,
                    Induct_on `l` >> rw [])
val _ = out ("  求证：" ^ p ``MEM (1 : num) l ==> LENGTH l > 0``
                            (metis_tac [mem_pos]))
val _ = show "metis 直上    " (metis_tac [])
             ``!l : num list. !x. MEM x l ==> LENGTH l > 0``
```

`metis_tac` 是四台机器里最"像推理"的一台。三件事它做得很好：

1. **等词是对称的** —— `f x = f y ⇔ f y = f x` 它一句话证掉；
2. **自动实例化量词** —— 已知 `∀l x. MEM x l ⇒ LENGTH l > 0`，
   目标 `MEM 1 l ⇒ LENGTH l > 0` 它自己把 `x` 实例化成 `1` 并做 MP；
3. **找矛盾** —— 一阶反证。

但下面那行 `metis 直上 : <tactic failed>` 才是要紧的：
**`mem_pos` 这条引理本身，`metis` 证不出来** —— 它需要分列表的构造子
（`[]` / `h::t`）并展开 `MEM`，而 `metis` 两样都不会。

真实脚本里的分工因此是：

```
Induct / Cases  ── 拆结构
rw / simp       ── 展开定义、化简
metis_tac       ── 最后拼逻辑（只在"这一步显然"时上）
```

## 21.6 两个便宜的替代品

```text
PROVE_TAC 是「只用假设里的命题逻辑」：
  ⊢ a ∧ b ⇒ b ∧ a
RES_TAC 把假设里的蕴含反复套用，直到没新东西：
  ⊢ (a ⇒ b) ⇒ a ⇒ b
这两个都比 metis_tac 便宜，能用就用。
```

```sml
val _ = out ("  " ^ p ``(a : bool) /\ b ==> b /\ a`` (PROVE_TAC []))
val _ = out ("  " ^ p ``((a : bool) ==> b) ==> a ==> b`` (strip_tac >> RES_TAC))
```

`metis_tac` 是重武器，它的搜索开销不小。两个便宜的替代：

| 战术 | 做什么 | 什么时候用 |
|---|---|---|
| `PROVE_TAC thms` | 只用假设和 `thms` 里的**命题逻辑** | 目标是纯命题组合 |
| `RES_TAC` | 把假设里的蕴含反复套用，直到没有新结论 | 假设里有一串 `⇒` |

`RES_TAC` 尤其好用：它会自动做 `A ⇒ B` + `A` ⟹ `B` 的闭包，
比手写一串 `imp_res_tac` 省事。

> 实践顺序：`simp` → `RES_TAC` → `PROVE_TAC` → `metis_tac`。
> 越靠前的越便宜、也越好懂。

## 21.7 接起来的顺序

```text
1) 先看是不是闭项            → EVAL
2) 再看是不是纯算术          → DECIDE_TAC / ARITH_CONV
3) 再看是不是纯命题          → TAUT_PROVE / PROVE_TAC
4) 剩下的：先用 rw/simp 把结构拆开、把定义展开，
   再让 DECIDE_TAC 或 metis_tac 收尾。
一个四步都过不了、必须人手工的例子：带累加器的反转。
  直接归纳：
  只用 rw     : revacc l [] = REVERSE l ⊢ revacc l [h] = REVERSE l ⧺ [h]
  归纳假设是 revacc t [] = REVERSE t，而目标里 acc 变成了 [h]，
  套不上 —— 这正是 13.6 说的「归纳假设的方向」问题。
  把结论推广（让 acc 也变成全称量词）就能过：
  ⊢ ∀l acc. revacc l acc = REVERSE l ⧺ acc
  （推广归纳假设这一步，四台机器都替你做不了。）
```

```sml
Definition revacc_def:
  (revacc [] acc = acc) /\
  (revacc (h::t) acc = revacc t (h::acc))
End
val _ = show "  只用 rw    " (Induct_on `l` >> rw [revacc_def])
             ``!l : num list. revacc l [] = REVERSE l``
val _ = out ("  " ^ p ``!l acc : num list. revacc l acc = REVERSE l ++ acc``
                     (Induct_on `l` >> rw [revacc_def]))
```

最后这一节给出"四台机器都救不了你"的那个经典场景。

`revacc`（带累加器的反转）的**直接**归纳必然卡住：

- 归纳假设：`revacc t [] = REVERSE t`（`acc` 被钉成 `[]`）；
- 目标：`revacc t [h] = REVERSE t ⧺ [h]`（`acc` 变成了 `[h]`）；
- 归纳假设套不上。

输出里 `show` 打印的残余目标正是这个状态：
`revacc l [] = REVERSE l ⊢ revacc l [h] = REVERSE l ⧺ [h]`。

解法是**把结论推广**，让 `acc` 也变成全称量词：
`∀l acc. revacc l acc = REVERSE l ⧺ acc`，
这样归纳假设就是 `∀acc. revacc t acc = REVERSE t ⧺ acc`，
`acc = [h]` 时正好能用上。

**"推广归纳假设"这一步，四台机器都替你做不了** ——
它需要的不是更强的搜索，而是换一个命题。这正是人的价值所在，
也是 13.5 / 13.6 反复强调的那条路。

## 21.8 代价

```text
1) metis_tac 不会告诉你「差在哪」，只说 no solution found；
2) 喂给它的定理越多越慢，而且**方向不对称的定理会让它不终止**；
3) 自动证明出来的项可能很长，人读不懂，也就没法维护；
4) 一条自动证明今天能过，明天库里某个定理改名就过不了。
所以教程里的做法是：能写清楚的步骤自己写，
只在「这一步显然」的地方交给机器。
```

四条代价：

1. **`metis` 不解释失败原因**，只说 `no solution found`；
2. **定理喂得越多越慢**，而且**方向不对称的定理会让它不终止**
   （`RTC_TRANS` 就是典型，见 16.3 节）；
3. **自动证明可能很长**，人读不懂就谈不上维护；
4. **脆弱**：库里某个定理一改名，今天能过的证明明天就过不了。

所以本教程的立场是：**能写清楚的步骤自己写，只在"这一步显然"的地方交给机器。**
这条原则同时也决定了验证脚本必须加看门狗 —— 见 23 章。

## 21.9 坑位清单

1. **`numLib.ARITH_CONV` 不能写成裸 `ARITH_CONV`** → 后者在本版本没有绑定。
2. **`tautLib.TAUT_PROVE` 接项返回定理** → 它**不是**战术，别放进 `prove` 的第二个参数。
3. **`TAUT_PROVE` 把量词当原子命题** → 它不做量化推理。
4. **`metis_tac` 不展开定义、不分构造子** → 引理本身常常得人先证。
5. **`EVAL` 对自由变量一步都走不动** → 返回的是重言式；可反过来用它找反例。
6. **`DECIDE_TAC` 处理不了量词和两变量乘法** → 拆量词 / 用归纳。
7. **演示"过不了"要用 `show` 而不是 `prove`** → 后者会打横幅 abort。
8. **`metis` 喂得越多越慢，方向不对称的定理会让它不终止** → 只喂需要的那几条。
9. **`RES_TAC` / `PROVE_TAC` 比 `metis_tac` 便宜** → 能用的先用它们。
10. **"推广归纳假设"四台机器都做不了** → 卡住时换个命题，不是换台机器。

---

上一章：[20 · 化简器与 simpset](20-simpset.md) ·
下一章：[22 · 理论与数据库](22-theories.md)
