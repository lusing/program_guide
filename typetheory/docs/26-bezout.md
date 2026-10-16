# 26 从 Peano 到 Bézout：公理化算术

> 对应读本：TTAFP 第 14 章全部 + 第 15 章全部 + 附录 B/C（Peano
> 公理与整数构造、整数算术律、整除与证明无关性；Bézout 引理的
> 完整形式化、九个洞、极小元定理、除法定理）。
> 代码：`examples/26_bezout/`——**Coq 主场**（公理化 Peano 记账、
> 除法定理与 Bézout 的 stdlib 收官、九个洞的假设化身、极小元
> 定理）；**Lean 对照**（整数 = 对之商的 Automath 式构造、Nat
> 除法定理、燃料版扩展欧几里得与见证机检）。

这是全书的压轴技术章：作者用两章篇幅（约 90 页）把「数」从
零开始盖起来——先是自然数（公理化而非编码化），再是整数
（从 ℕ 构造），一路到 Bézout 引理的完整形式化证明。它是 λD
的「全负载测试」：前面 21–25 章的全部机械（编码、定义环境、
旗式、等式、描述子、子集）在此各就各位。

## 26.1 为什么不用 Church 数（书 14.1）

Church 数（02/18 章的老朋友）看起来是现成的 ℕ——书给出四条
反对意见，每条都有分量：

1. **归纳推不出来**：Geuvers 2001 证明多态 Church 数上归纳在
   λ2/λP2/λD 里都不可导出——必须外加公理；
2. **前驱编码不自然**：Church 数擅长迭代，不擅长原始递归；
3. **装不下整数**：负数要另起炉灶；
4. **数学家的习惯**：Peano 格式更被接受。

结论：走 Peano 路线——但注意路线的**形态**：ℕ、0、s 是三件
**原始定义**（⊥⊥），公理跟在后面：

> **ax-nat1** : ∀x:ℕ. s(x) ≠ 0（链条不回头之一）
> **ax-nat2** : ∀x y:ℕ. s(x) = s(y) ⇒ x = y（s 单射）
> **ax-ind** : ∀P:ℕ→∗p. P 0 ⇒ (∀x. P x ⇒ P(s x)) ⇒ ∀x. P x

对比 30 章（MLTT 归纳族）：那里 ℕ 是**归纳类型**、归纳原理
是**免费定理**、两条公理是**构造子判别性**——同一套 Peano
直觉，两种供给方式（公理买 vs 构造送）。Coq 侧的第一段把这个
对照做成账本：

```coq
Parameter PeanoN : Type.
Parameter pzero : PeanoN.
Parameter psucc : PeanoN -> PeanoN.
Axiom ax_nat1 : forall x, psucc x <> pzero.
Axiom ax_nat2 : forall x y, psucc x = psucc y -> x = y.
Axiom ax_ind  : forall P, P pzero -> (forall x, P x -> P (psucc x)) ->
                forall x, P x.
Print Assumptions succ_injective.  (* -> ax_nat2：把归纳当公理的账单 *)
```

## 26.2 整数：对之商（书 14.2–14.9）

整数不是新的原始材料——从 ℕ **构造**：序对 (a,b) 表示差 a−b，
等价关系 (a,b) ≡ (c,d) ⟺ a+d = b+c。书 14.2–14.3 耗整个
小节验证这个等价关系与新 ℕ 的和谐；14.4 起在其上搭算术：加法
（点态）、乘法（分配律展开）、减法（补律）、相反数（交换
分量）、序（按差的符号）——每条算术律（结合/交换/分配/消去）
都是一整段形式化推导（图 14.12–14.27 的二十几张旗图）。Lean
侧把这个构造做成最小可运行版：

```lean
private def ZR (p q : Nat × Nat) : Prop := p.1 + q.2 = p.2 + q.1
def IntQ : Type := Quotient zSetoid          -- 整数 = 对之商
def addQ : IntQ → IntQ → IntQ := Quotient.lift₂ (· + · 点态) …
theorem twoMinusOne : intQ 2 0 + negQ (intQ 1 0) = 1 := …
```

`2 + (-1) = 1` 不再是公理或内置计算，而是**一句 Quot.sound**
——差的两种表示在商里相等。这就是 Automath 血统的「构造式
整数」：Lean 核心的 `Int` 本身（`Nat × Nat` 的商）正是它的
工业直系。

书 14.13 的**证明无关性**（irrelevance of proof——de Bruijn
1970 年代的术语）值得记：子集 `{x:S | P x}` 的元素若携带
见证，算术律的证明会被见证的形状绑架；书选择**不加**证明
无关性为一般原则（有人想要对象依赖证明的场景）——这与 38 章
截断层级的动机一线相牵。

## 26.3 整除、互素与 Bézout（书 14.12 + 15.1–15.5）

d | x := ∃k. x = d·k（书 14.12）；互素 = 无 >1 公因子。Bézout
受限版（书 15.1，Figure 8.6 的证明重述）：

> m, n ∈ ℕ⁺ 互素 ⇒ ∃x y ∈ ℤ. mx + ny = 1

证明的骨架（书 15.2–15.5 用 48 行旗图 a1–a44 形式化）：
S = {mx+ny | x,y∈ℤ}（25 章的子集即谓词！）；S⁺ = S ∩ ℕ⁺ 有
最小元 d（极小元定理）；d = mx₀+ny₀；m 除以 d 得 q,r，余项
r ∈ S 且 r < d 矛盾 ⇒ r = 0 ⇒ d|m；同理 d|n；互素 ⇒ d = 1
⇒ 1 ∈ S。**25 章的全部道具在此集合**：子集交（Cap）、∈ 即
应用、Least（12.6）、除法定理、Leibniz 等式的替换性。

## 26.4 九个洞（书 15.6）——诚实的教科书

形式化不是全绿通过：书 15.6 老老实实列出**九个洞**（hole）——
形式化过程中跳过的证明对象，从「ℤ 是偏序」到「m = m·1 + n·0」
不一而足，每个都不难但都真实存在。这是本书最值得学的态度之一：
**洞是形式化的常态，工程的艺术在于登记它们、然后逐个补**。
Coq 侧把三个代表洞做成**假设**（旗式常数的工程化身）：

```coq
Hypothesis hole1 : (Z,≤) 是偏序.
Hypothesis hole2 : m = m * 1 + n * 0.
Hypothesis hole5 : r = m*(1-q*x0) - n*(q*y0) -> r ∈ S.
Theorem bezout_skeleton : …  (* 三个洞拼出 d|m 的主骨架 *)
Lemma hole2_filled : forall m n, m = m*1 + n*0.
Proof. intros; lia. Qed.                     (* 洞 2 的补法 *)
```

补洞的 stdlib 对应：洞 1 = Z.le 三性质（lia 全权代理）、洞 2 =
单位律（单行）、洞 5 = 环整理。真正的收官件是 stdlib 的
`Z.gcd_bezout`（gcd g ⇒ ∃a b. a·m+b·n = g）加一段「互素 ⟺
gcd=1」（`gcd_eq1_of_coprime`）——Bézout 受限版三行收官。

## 26.5 极小元定理与除法定理（书 15.7–15.8）

两个「欠账」的补齐：

**极小元定理**（15.7）：ℕ 的非空子集有最小元——书用 ℕ 的
良建归纳从零向上找（附录 C.2 给完整版）。Coq 的 stdlib
（Wf_nat）有现成的 `dec_inh_nat_subset_has_unique_least_element`
——本章的 minimum_theorem 直接收官，且 `Print Assumptions`
显示**零公理**（构造性的）——对照 25 章 ι 的 choice 账单，
两章连起来是一份「公理开销对比表」。

**除法定理**（15.8）：∀a b:ℤ, b>0 ⇒ ∃q r. a = q·b+r ∧ 0≤r<b
——Bézout 证明里反复用的分拆引擎。Coq 版走 `Z.div_mod` +
`Z.mod_pos_bound`；Lean 版在 ℕ 上**手工归纳**（divExist），
完整写出「余数满 b 就进位」的两分支——书本证明的机器直译。

## 26.6 扩展欧几里得：构造性的见证（机器面新增）

书的 Bézout 证明是**经典式**的（存在性论证），而「找 x,y」的
构造性程序是欧几里得算法（书 15.1 的注记）。Lean 侧补上这
一块——燃料版扩展欧几里得，每层递归回代一步：

```lean
def eea : Nat → Nat → Nat → Nat × Int × Int
  | 0, _, _ => (0, 0, 0)
  | fuel + 1, m, n =>
      if _hn : n = 0 then (m, 1, 0)
      else
        let r := m % n
        if _hr : r = 0 then (n, 0, 1)
        else
          let (g, x', y') := eea fuel n r
          (g, y', x' - ((m / n : Int) * y'))   -- 回代：g = y'·m + (x'−q·y')·n
```

见证机检（native_decide）：gcd(15,4) = 1 且 15·(−1)+4·4 = 1；
gcd(221,91) = 13 且 221·(−39)+91·95 = 13——**系数是算出来的，
不是证出来的存在性**。eea 一般规格（g ∣ m、g ∣ n、互素 ⇒ g=1）
的归纳链在 Lean 侧留白（诚实清单），一般收官由 Coq 侧 stdlib
承担——两章机器面的分工：**Lean 看构造、Coq 看收官**。

## 26.7 学到了什么（书 15.9 + 16 的回望）

书 15.9 的结论：形式化一个「教科书一页」的定理需要一整章——
这不是失败而是**测量**：形式数学的密度远高于散文数学，而回报
是机器可查、零含糊。16 章的收尾展望（证明助手生态、未来方向）
与本指南 34 章（四家对照）相接。

> **坑位速记**
> ① Coq 8.20 的 Bézout 在 **Z 模块**（Z.gcd_bezout：
>   Z.gcd n m = p ⇒ ∃a b, a*n+b*m = p——注意 n/m 与 a/b 的
>   配对顺序！），不在 Znumtheory（该模块此版本不存在）；
> ② `d | m` 中缀记号在定理声明里解析不稳——写 `Z.divide d m`；
> ③ lia 不做非线性：x*m 与 m*x 是两个原子——先 `Z.mul_comm`
>   对齐再收；涉及 m*b 的目标把等式拆到 omega 能看的形状；
> ④ `Z.mod_pos_bound` 只对 **b>0** 给界（书里的除法定理本来
>   就是 d>0 版——负除数的 floor 语义余数可为负）；
> ⑤ Coq `<=` 在 `Open Scope Z_scope` 下默认读 Z——Nat 目标
>   要 `(n <= y)%nat`；
> ⑥ Lean Quotient 的良定义证明里目标是 `≈` 不是裸 ZR——
>   `show ZR _ _` 先转；Setoid 记得 `instance`；
> ⑦ Lean 递归函数的嵌套 let + if 用 rfl 求值会卡——数据断言
>   用 native_decide（项是封闭的，原生求值最稳）；
> ⑧ if-then-else 绑定的条件名在未用时会告警——`_hn`/`_hr`
>   命名或显式使用。

---

上一章：[25 λD 中的数学：等式、序与描述子](25-ldmath.md) · 下一章：[27 MLTT：判断形式与一般规则](27-judgments.md)
