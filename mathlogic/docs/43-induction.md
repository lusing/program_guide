# 第 43 章 数学归纳与递归：PMI 三位一体

> 对书：Jongsma《Discrete Mathematics via Logic and Proof》§3.1–3.2。
> 本章通道：C（`examples/43_induction/ex43_induction.v`）/ L（`examples/43_induction/ex43_induction.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `gauss` / `oddsum_sq` | Gauss 求和与奇数和=平方的 PMI 机器化 | C/L |
| `hanoi_pow` | Hanoi 塔递推 m_n + 1 = 2^n | C/L |
| `nat3_fact` | Mod PMI：n³ < n!（6 ≤ n） | C/L |
| `strong_ind` | 强归纳从弱归纳推出（零公理） | C/L |
| `bounded_dec` + `prime_divisor` | 素因子存在（Euclid VII.31）构造性证明 | C/L |
| `firstUp` / `wop_bool` / `wop_classic` | 良序原理：构造面与经典面 | C/L |
| `no_sqrt2` | 无穷下降：√2 无理性 | C/L |
| `fib_triple` / `fib_3n` | Fibonacci F₃ₙ 偶：加强归纳命题 | C/L |

Jongsma 把数学归纳放在逻辑两章之后不是偶然：前两章给的是「怎么推理」的规则，
这一章回答「数学里这些规则第一次大规模用在哪里」。归纳法是离散数学的发动机，
而证明助手恰好把归纳法的三种形态（弱归纳、强归纳、良序）变成**同一条机器流水线
上的三个可互换部件**——这正是本章要展示的。全书此后的每个主题（Peano 算术、整除、
集合、图论）都靠这台发动机驱动。

一个先行的约定差异：Jongsma 的计数数从 1 开始，机器的 `nat` 从 0 开始。求和类命题
两边同值（0 白加）；基点类命题则体现为本章的 Mod PMI。书中 P(1) 起步的命题在机器里
或改写成 P(0) 起步，或保留正基点——两种处理都会现场见到。

## 一、PMI 三步与两件求和法宝

数学归纳法（Proof by Mathematical Induction）的三步骨架：

1. **基例**：证 P(1)；
2. **归纳步**：对任意 k，假设 P(k)（归纳假设），证 P(k+1)；
3. **结论**：断言 ∀n P(n)。

多米诺骨牌是它的标准图像：推倒第一张（基例），每张能推倒下一张（归纳步），
则全部倒下（结论）。缺任何一步都会出假命题——书里「同种鸟」悖论（练习 3.1.13）
就是归纳步偷换集合的著名反例。

第一件法宝是 Gauss 求和：1+2+⋯+n = n(n+1)/2。书的证法一是少年 Gauss 的配对技巧
（正序倒序各写一遍，首尾配对得 n 个 n+1），漂亮但不严格——省略号掩盖了「每项都
配上了」这个归纳事实。PMI 的机器化把严格性变成义务。Coq 版（`ex43_induction.v`）：

```coq
Fixpoint sumn (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => sumn k + S k
  end.

Lemma gauss : forall n, 2 * sumn n = n * S n.
Proof.
  induction n as [|k IH]; simpl; lia.
Qed.
```

注意两处机器化改写：其一，和式先要**递归定义**（`sumn`），这本身就是书里
「有限级数的递归定义」（例 3.1.6）的形态；其二，等式两边同乘 2 避免除法——
`2 * sumn n = n * (n+1)` 与 n(n+1)/2 是一回事，但 nat 上没有好用的除法。
`induction n` 展开后 `simpl` 把 `sumn (S k)` 归约成 `sumn k + (k+1)`，
剩下的纯线性算术交给 `lia`。归纳假设 IH 自动出现在上下文里——这就是
「第 2 步假设 P(k)」的机器形态。

第二件法宝是 Galileo 级数：前 n 个奇数之和等于 n²。Lean 版（`ex43_induction.lean`）
多了一点手工：

```lean
def oddsum : Nat → Nat
  | 0 => 0
  | (k+1) => oddsum k + (2*k+1)

theorem oddsum_sq : ∀ n, oddsum n = n * n := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih =>
    simp only [oddsum]
    have e : (k+1) * (k+1) = k*k + 2*k + 1 := by
      have s1 := Nat.add_mul k 1 (k+1)
      have s2 := Nat.mul_add k (k+1) 1
      have s2b := Nat.mul_add k k 1
      have s3 := Nat.mul_one k
      have s4 := Nat.one_mul (k+1)
      omega
    rw [e]
    omega
```

为什么不 `simp only [oddsum]; omega` 一行收工？因为目标里的 `(k+1)*(k+1)` 是
**非线性**项：`omega`/`lia` 把 `k*k` 这样的积当作不透明原子，`(k+1)*(k+1)` 与
`k*k` 是两个互不相干的原子，线性算术连不起来。必须先用 `Nat.add_mul`、
`Nat.mul_add` 这组分配律引理把平方**展开成原子的线性组合**（s1–s4 四条等式），
`omega` 才能在「原子 + 系数」的世界里完成归纳步。这个「非线性先展开、再原子化」
的手续是本章反复出现的主题，坑位速记里有它的完整清单。

## 二、递归定义与递归定理：Hanoi 塔

书 §3.1.3 的递归定理（引 Henkin 1960）说：给一条基点条款和一条递推条款，
概念就被唯一确定。证明它需要集合论工具（第 47 章会回来），但**使用**它不需要。
类型论里它化身为人人天天写的东西——`Fixpoint` 的**结构性终止检查**：

```coq
Fixpoint hanoi (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => 2 * hanoi k + 1
  end.
```

「每次递归调用必须作用在严格子结构上」就是递归定理的机器版：Coq/Lean 检查通过
的 `Fixpoint`/递归 `def` 自动良定义，不需要再证存在唯一性。河内塔的最少搬动数
满足 m₁=1、m_{n+1}=2m_n+1，闭式是 m_n = 2ⁿ−1。nat 上写 2ⁿ−1 要用减法，
而 nat 的减法在证明里几乎总是坏消息；改写成 **+1 = 2ⁿ** 形态：

```coq
Lemma hanoi_pow : forall n, hanoi n + 1 = pow2 n.
Proof.
  induction n as [|k IH]; simpl; lia.
Qed.
```

`pow2` 是自带的 2 的幂（基 1、翻倍）。归纳步是 `2·hanoi k + 1 + 1 = 2·pow2 k`，
由 IH `hanoi k + 1 = pow2 k` 线性推出——`lia` 一行。这个「减法改加法」的小手法
值得记住：nat 上凡见 a−b，考虑把命题改写成等价的 +b 形态。

## 三、Mod PMI：n³ < n!

基例不必从 0 或 1 开始。书例 3.2.1 是 n³ < n!（n ≥ 6）：6³=216 < 720=6! 成立，
而 n=5 时 125 > 120 反向——基点 6 是紧的。归纳步的数学骨架：

(k+1)³ = (k+1)·(k+1)² ≤ (k+1)·k³ < (k+1)·k! = (k+1)!，

其中用了辅助不等式 (k+1)² ≤ k³（k ≥ 3 即可）。机器化时这个链条有两处要手工装配。
先看辅助不等式（Coq 版）：

```coq
Lemma sq_le_cube : forall k, 3 <= k -> (S k) * (S k) <= k * k * k.
Proof.
  intros k Hk.
  assert (H3 : 3 * k <= k * k) by (apply Nat.mul_le_mono_r; lia).
  assert (H2 : k * k * 2 <= k * k * k) by (apply Nat.mul_le_mono_l; lia).
  assert (Hexp : (S k) * (S k) = k * k + 2 * k + 1) by ring.
  lia.
Qed.
```

读法：H3 与 H2 是两条**乘法单调性**（3 ≤ k 两侧乘 k；2 ≤ k 两侧乘 k²），
Hexp 是平方展开（`ring` 处理纯恒等式），最后一行 `lia` 在原子 {k, k², k³} 的
线性世界里拼出结论——它看得见 k²+2k+1 ≤ k²+k² ≤ k³。注意 H2 的形状
`k*k*2 ≤ k*k*k`：乘法单调引理对**因子的左右位置敏感**，`(k*k)*2` 配
`Nat.mul_le_mono_l`（右边乘公共因子），形状对不上就换个方向或换个引理。

主定理里「(k+1)·k³ < (k+1)·k!」这一步（不等式两侧乘正数 k+1 保持严格），
Coq 侧用 `nia`（非线性版 lia）一行；Lean 侧裸 core 没有现成的严格乘法右单调，
干脆自造一个（对乘子归纳）：

```lean
theorem mul_lt_pos (a b : Nat) (h : a < b) : ∀ c, 0 < c → a * c < b * c := by
  intro c
  induction c with
  | zero => intro hc; omega
  | succ j ih =>
    intro _
    rw [Nat.mul_succ, Nat.mul_succ]
    match j with
    | 0 => rw [Nat.mul_zero, Nat.mul_zero]; omega
    | j'+1 => have hprev := ih (by omega); omega
```

基例 c=0 与假设矛盾；c=j+1 时展开 `a*(j+1) = a*j + a`，j=0 退化为 h 本身，
j>0 用归纳假设。最后 n=6 的基例，Lean 侧 `subst k; decide` 让内核直接算
216 < 720。

## 四、强归纳与素因子存在

弱归纳的归纳假设只有 P(k) 一条；当 P(k+1) 与紧前驱关系不大、却与**所有更小**
的值有关时，需要强归纳（Strong PMI）。典型例子是 Euclid《几何原本》VII.31：
**每个 ≥2 的数都有素因子**。若 n 不是素数，n = a·b 且 2 ≤ a < n——归约到 a，
而不是 n−1。书的证法一说「n 要么素、要么不素」——这一步是排中律！
本章机器化走一条**完全构造性**的替代路线，经典账本留给良序原理那节。

强归纳本身可以从弱归纳推出来，零公理（Coq 版）：

```coq
Theorem strong_ind : forall P : nat -> Prop,
  (forall n, (forall m, m < n -> P m) -> P n) -> forall n, P n.
Proof.
  intros P H n.
  assert (Hall : forall k m, m <= k -> P m).
  { induction k as [|k IHk]; intros m Hm; apply H; intros j Hj.
    - lia.
    - apply IHk. lia. }
  apply (Hall n). lia.
Qed.
```

诀窍是**辅助命题** `∀k m, m ≤ k → P m`：它对 k 做弱归纳。k=0 时 m ≤ 0，
「所有 j < m」是空集条件（`lia` 从 j < m ≤ 0 矛盾关门）；k+1 时 j < m ≤ k+1
分界出 j ≤ k，用内层归纳假设。「强归纳可用弱归纳导出」这件事在教材里通常一笔
带过，机器化让它变成看得见的六行。

构造性素因子证明的另一半是**有界排中**：bool 谓词在 [0,n] 上，「存在真」与
「全部假」二择一可以**归纳构造**出来，不需要排中律——bool 的情形是可判定的：

```coq
Lemma bounded_dec : forall (p : nat -> bool) n,
  (exists d, d <= n /\ p d = true) \/
  (forall d, d <= n -> p d = false).
```

（对 n 归纳，每步 `destruct (p (S k))` 拿到 Bool 的两朵花瓣——Bool 上分类
是计算，不是逻辑假设。）把 p 取成「d 是 n 的真因子」：`2 ≤ d ∧ 2d ≤ n ∧ d∣n`
（整除测试 `dvb` 是在乘法表 [0,n] 里的可判定搜索，Coq 用 `existsb`+`seq`，
Lean 用自写递归 `dvbAux`）。二择一的两支分别给出：

- **有真因子 d**：则 d < n，对 d 用强归纳假设拿到素因子 p ∣ d，传递性 p ∣ n；
- **无真因子**：n 自己就是素数——任何因子 d 配上分解 n = d·k，k ≥ 2 会造出
  真因子（与无真因子矛盾），k ≤ 1 迫使 d = 1 或 d = n。

```coq
Theorem prime_divisor : forall n, 2 <= n -> exists p, prime p /\ divides p n.
```

两个通道各自约 60 行完成，`Print Assumptions` 确认零公理。对照书：同样的定理，
书用「素或非素」的 LEM 分叉 + 强归纳；机器版把 LEM 换成有界排中——**当分叉
谓词可判定时，排中律是免费的**。这是本章第一个「账本文化」现场。

## 五、良序原理：构造面与经典面

良序原理（WOP）：自然数的任意非空子集有最小元。书 §3.2.4 的证明是反证法：
反设 S 无最小元，考虑补集 P，强归纳证明一切自然数都在 P 里（若 <k 全在 P 而
k ∈ S，k 就是最小元，矛盾），于是 S 空——与非空矛盾。

这份证明有两张机器面孔。**可判定版**（bool 谓词）完全构造：线性搜索找第一个真元，

```lean
def firstUp (p : Nat → Bool) : Nat → Option Nat
  | 0 => match p 0 with
         | true => some 0
         | false => none
  | (k+1) =>
    match firstUp p k with
    | some m => some m
    | none => match p (k+1) with
              | true => some (k+1)
              | false => none
```

规格引理 `firstUp_spec` 一并给出两件事：搜到的 m 确实为真、m 之下全假
（这正是「最小」）；搜不到则 [0,n] 全假。`wop_bool` 立即得到「非空可判定集有
最小元」——零公理。60 的最小素因子、91 的最小素因子（Some 2、Some 7）
是文件尾的 Compute 演示：良序原理的**计算面**就是一次线性搜索。

**任意 Prop 版**则忠实复刻书的论证（Lean）：

```lean
open Classical in
theorem wop_classic {S : Nat → Prop} (hne : ∃ n, S n) :
    ∃ m, S m ∧ ∀ k, S k → m ≤ k := by
  refine Classical.byContradiction (fun hcon => ?_)
  have hall : ∀ j, ¬ S j := by
    apply strong_ind (P := fun j => ¬ S j)
    intro j IHj HjS
    apply hcon
    refine ⟨j, HjS, fun k Hk => ?_⟩
    refine Classical.byContradiction (fun hnk => ?_)
    exact IHj k (by omega) Hk
  cases hne with
  | intro n Hn => exact hall n Hn
```

先反设无最小元（**这一步是经典**），然后强归纳证明 ∀j ¬S j——「j 是最小元」
的论证只用强归纳假设，构造性成立——最后与非空矛盾。`#print axioms wop_classic`
如实记下 `[Classical.choice, propext, Quot.sound]`；Coq 侧同名定理记下
`classic`。同一原理的两副面孔：可判定时免费，任意命题时按经典记账——
这与第 04 章「语义层天生经典」的账本文化一脉相承。

## 六、无穷下降与 √2

书 §3.2.4 末尾介绍 Fermat 的**无穷下降**：若某命题对 n 成立则对某个更小的
m 成立，重复下去得到无穷递减的自然数列——不可能（这就是 WOP）。√2 无理性
是它的招牌应用：假设 p² = 2q²（q ≠ 0），则 p 偶（p=2r）、q 偶（q=2s），
代回得 r² = 2s² 且 s < q——**同一个矛盾在更小的分母上重演**。强归纳吞下这个
论证：归纳假设断言「更小的 q 都不行」，下降一步直接撞进假设。

```coq
Theorem no_sqrt2 : forall q p, q <> 0 -> p * p <> 2 * q * q.
Proof.
  apply (strong_ind (fun q => forall p, q <> 0 -> p * p <> 2 * q * q)).
  intros q IH p0 Hq0 Hbad.
  destruct (Nat.Even_or_Odd p0) as [[r Hr]|[r Hr]].
  - rewrite Hr in Hbad.
    replace ((2 * r) * (2 * r)) with (4 * (r * r)) in Hbad by ring.
    destruct (Nat.Even_or_Odd q) as [[s Hs]|[s Hs]].
    + rewrite Hs in Hbad.
      replace (2 * (2 * s) * (2 * s)) with (8 * (s * s)) in Hbad by ring.
      exfalso. apply (IH s ltac:(lia) r ltac:(lia)).
      replace (2 * s * s) with (2 * (s * s)) by ring. lia.
    + exfalso.
      rewrite Hs in Hbad.
      replace (2 * (2 * s + 1) * (2 * s + 1))
        with (2 * (2 * (2 * s * s + 2 * s) + 1)) in Hbad by ring.
      lia.
  - exfalso. rewrite Hr in Hbad.
    replace ((2 * r + 1) * (2 * r + 1))
      with (2 * (2 * r * r + 2 * r) + 1) in Hbad by ring.
    lia.
Qed.
```

四个分叉：p 偶 q 偶（下降）、p 偶 q 奇（偶=2·奇² 的奇偶矛盾）、p 奇（奇²=偶的
奇偶矛盾）。每个分叉的关键一步都是把 `(2r+1)²` 这类非线性项**换成 ring 展开的
规范形**（如 2(2r²+2r)+1），`lia` 再在原子层面做奇偶判断。两处细节值得点名：
命题必须排除 q=0（否则 p=q=0 是 nat 上的合法解——有理数世界的「非零分母」
约定在 nat 上的化身）；Lean 侧 `(2*r)*(2*r)` 与 `2*(2*(r*r))` 这类「同一个
单项式的不同嵌套」会被 omega 当作**不同原子**，需要 `two_sq`/`odd_sq` 两个
规范形引理先行对齐。

## 七、Fibonacci 与「机器要求更强的归纳命题」

Fibonacci 递归是「修改版递归定义」的样板：基例要给**两个**值。书例 3.2.7 证明
每第三个 Fibonacci 数是偶数（2 ∣ F₃ₙ）：F₃ₖ₊₃ = F₃ₖ₊₂ + F₃ₖ₊₁ = 2F₃ₖ₊₁ + F₃ₖ，
最后一步把 F₃ₖ₊₂ 展开成 F₃ₖ₊₁+F₃ₖ，于是偶+偶=偶。书上只需要 F₃ₙ 的偶性一条
归纳假设；机器直接照抄却过不去——因为归纳步要**同时产出** F₃ₖ₊₄、F₃ₖ₊₅ 的
奇偶性（下一轮的输入），而命题里没有它们的存货。正解是把命题加强成三合一：

```lean
theorem fib_triple : ∀ n,
    (∃ a, fib (3 * n) = 2 * a)
    ∧ (∃ b, fib (3 * n + 1) = 2 * b + 1)
    ∧ (∃ c, fib (3 * n + 2) = 2 * c + 1) := by
```

归纳步里三个分量互相喂数：F₃ₖ₊₃ = 奇+奇 = 偶（He3）、F₃ₖ₊₊₄ = 偶+奇 = 奇（Ho4）、
F₃ₖ₊₅ = 奇+偶 = 奇（Ho5）。要的定理（`fib_3n`）从三分量里读出第一个即可。
这是「**机器证明经常需要比书上更强的归纳命题**」的教科书现场——书作者可以
在正文里隐式借用「显然相邻两项奇偶如下」的现成知识，机器必须把它写进命题里
才能进入归纳假设。第 28 章（饥饿路径的状态机递推）见过同款现象。

## 坑位速记（本章实测）

- **Lean：omega 见 ∃ 即拉经典**。上下文里只要有一条 ∃ 假设（哪怕与目标无关），
  `omega` 的证明就会依赖 `Classical.choice`——`#print axioms` 现场抓获。
  处方：纯形状等式（如 fib 平移引理）**提到顶层**再证（`fib_shift2`），
  或者先把 ∃ destruct 掉再调 omega。
- **Lean：omega 关非算术门也拉经典**。目标形如 `P j`（抽象 Prop）时靠
  `j < 0` 类矛盾关门，omega 内部走经典路径；换成显式
  `absurd (Nat.lt_of_lt_of_le hj hm) (Nat.not_lt_zero j)` 即零公理。
- **Lean：`Nat.beq_refl` 不在裸 core**，而 `beq (a+1) (a+1)` 又不等价于
  `beq a a`（加法展开卡在 a+0）。处方：整除测试全用
  `decide (d * k = n)` + `decide_eq_true`/`of_decide_eq_true` 全家桶，
  彻底绕开 `==`。
- **Lean：单项式的嵌套即原子**。`k*(k*k)` 与 `(k*k)*k` 是 omega 眼里两个原子；
  `Nat.mul_assoc : n*m*k = n*(m*k)`（左结合侧在左边！）方向反了 rw 不命中。
- **Lean**：`Option.some.inj : some a = some b → a = b`，从 `some 0 = some m`
  提取用 `have hm : 0 = m := Option.some.inj h` 再 `subst`。
- **Lean**：`exact ⟨p, hpr, ?_⟩` 不收占位——`?_` 要用 `refine` 留。
- **Coq/Rocq 9.1**：`Fixpoint` 的嵌套模式 `| S (S k) => fib (S k) + fib k`
  被结构检查**拒绝**（主参 `S k` 不是绑定变量）；改成嵌套 match、递归调用
  写外层绑定名 `fib m + fib k` 即过。
- **Coq**：`apply strong_ind` 触发高阶合一的**退化解**（P 取常量函数），
  IH 变成 ∀n 版；处方：`apply (strong_ind (fun n => …))` 显式给动机。
- **Coq**：`destruct (firstUp p k) eqn:Ef` 会把 IH 里的同款项**一并改写**，
  后续 `specialize (IH1 e Ef)` 变成 `specialize (IH1 e eq_refl)`。
- **Coq**：`Nat.mul_lt_mono_pos_r` 是 iff/合取形状，`apply` 直吃会报「unify
  出合取」；这一步用 `nia` 或手工 mul_le/lt 单调链。
- **Coq/Lean 通用**：非线性不等式两侧乘正变量的「跨原子」推理 lia 做不了
  （原子间无关系），要么 `nia`（Coq），要么手工单调引理装配（Lean 的
  `mul_lt_pos` 自造）。
- **Coq**：基例 k=5 时 `6³ < 6!` 让 lia 现算 nfact 是无理的——`subst` 后
  `simpl` 全量求值再 lia。

## 小结

归纳法的三张面孔在机器上合为一体：弱归纳是 `induction` 原语；强归纳是六行
辅助命题；良序是搜索函数加规格引理。三者互相推导的路线图（弱→强→构造良序，
良序+经典→任意良序）全部零公理或显式记账。下一章把这台发动机对准它的
第一个正式数学对象：Peano 算术——把「自然数」本身当作公理化理论来审视。

---

上一章：[42 合成与形式语义](42-synthsem.md) · 下一章：[44 递推、结构归纳与 Peano 算术](44-pa.md)
