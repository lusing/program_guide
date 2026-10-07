# 第 47 章 无穷集合与停机问题

> 对书：Jongsma ch5（§5.1–5.3）。本章通道：C（`examples/47_infinity/ex47_infinity.v`）/
> L（`examples/47_infinity/ex47_infinity.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `galileo` | 偶数与自然数等势（书例 5.1.1：真子集与全集等势的 Galileo 悖论） | C/L |
| `pair_inj` | ℕ×ℕ ↪ ℕ：2^a·3^b 单射（书 §5.1.8 可数性骨架的引件） | C/L |
| `cantor_prop` / `cantor_bool` | Cantor 对角线（书 Thm 5.2.1 的谓词版与位串版） | C/L |
| `cantor_general` | \|P(S)\| > \|S\|（书 Thm 5.2.3，任意类型版） | C/L |
| `russell` | Russell 悖论构造版（书 Thm 5.3.1，参数化成员关系） | C/L |
| `no_halting_checker` | 停机问题不可判定（书 §5.3.13，公理记账版） | C/L |

Cantor 在 1874 年迈出的那一步——把「无穷」当作可以比较、可以运算的完成对象——
是本章的背景。Jongsma 用一整章讲三件事：**可数**（哪些集合能与 ℕ 一一对应）、
**对角线**（为什么有些集合不可数、为什么幂集总比原集大）、**悖论与公理化**
（为什么朴素集合论会自爆，Zermelo 如何用分离公理止血），最后把对角线技术
带到计算机科学的开山问题——停机问题。本章的机器件按这条线布局，且有一个
贯穿的暗线：**对角线论证是直觉主义的**——不需要排中律，`A ↔ ¬A` 的矛盾
在构造性里照样爆炸。

## 一、Galileo：真子集与全集等势

书例 5.1.1 复述了 Galileo 在十七世纪注意到的「悖论」：正整数与完全平方数
一一对应（n ↦ n²），但平方数只是正整数的真子集——「整体大于部分」在无穷
处失效。机器版用最朴素的实例（偶数）把这个现象变成两条引理：

```coq
Definition isEven (n : nat) : Prop := exists k, n = 2 * k.

Theorem galileo : exists f : nat -> nat,
  (forall x y, f x = f y -> x = y) /\ (forall y, isEven y -> exists x, f x = y).
```

f = 2n：单射是乘法消去（`cancel_mul_l`），满射到偶数需要一个手写的除二函数
`halfE` 及其规格 `halfE (2*k) = k`。这里的 `galileo` 命题故意写成「单射 + 到达集
的每点有原像」的展开形态，而不是引入一般的双射概念——书 Defn 5.1.1 的
等势 S ∼ T 需要函数外延性的配合，展开形态让两通道都零负担。

## 二、ℕ×ℕ ↪ ℕ：素数编码

书 Thm 5.1.9（ℕ×ℕ 可数）用对角线遍历；书 Thm 5.1.1（Schröder-Bernstein）
自己也承认「不在此证明」。本章机器化走第三条路——**素数编码**：

```lean
theorem pair_inj : ∀ a b c d,
    pow 2 a * pow 3 b = pow 2 c * pow 3 d → a = c ∧ b = d
```

数对 (a,b) 编码为 2^a·3^b。单射性的证明是两遍奇偶分析：若 a < c，把差值
拆出来（c = a + j+1），等式两边消去 2^a，左边是 3^b（奇），右边是
2·2^j·3^d（偶）——奇=偶矛盾；对称得 a > c 也矛盾，故 a = c，再消去 2^a
用 3 的幂单射得 b = d。三件工具件（`pow2_pos`、`pow3_odd`、`pow2_inj`/`pow3_inj`）
各自是短归纳。这条路线的好处：完全在 ℕ 内、不需要遍历函数、也不需要
Schröder-Bernstein——「ℕ×ℕ 至多可数」直接拿到；反方向（ℕ ↪ ℕ×ℕ，n ↦ (n,0)）
平凡，两条单射合起来在**文档级**陈述书 Thm 5.1.9 的等势（SB 定理按书的
处理记为文档级引理）。

值得一提的机器坑：`pow2_inj` 的归纳步里，`pow 2 (j+1) = 2 * pow 2 j` 的展开
要靠 `cbn [pow]` 白名单（Lean 侧 `show` + `rfl`），而且差值拆分必须显式拆成
「j+1」的后继形式——差值 `y - x` 直接喂给 `pow` 会卡在减法上（43 章的老朋友）。

## 三、Cantor 对角线：三个化身

书 Thm 5.2.1 证明 (0,1) 不可数用的是十进制小数的对角线。实数小数在类型论里
不便操作，本章机器化对角线的三个「离散化身」，每一个都是同一个二行证明：

**化身一（谓词版）**——ℕ 的谓词不可枚举：

```lean
theorem cantor_prop : ¬ ∃ e : Nat → Nat → Prop,
    ∀ P : Nat → Prop, ∃ n : Nat, ∀ x : Nat, e n x ↔ P x := by
  intro he
  match he with
  | ⟨e, h⟩ =>
    match h (fun x => ¬ e x x) with
    | ⟨n, hn⟩ =>
      specialize hn n
      have d1 : e n n := hn.mpr (fun hev => (hn.mp hev) hev)
      exact (hn.mp d1) d1
```

假设枚举 e 存在，问它枚举谓词 P := fun x => ¬ e x x——第 n 个枚举项 e n
要与 P 逐点等价；在 x := n 处得到 e n n ↔ ¬ e n n。注意收尾的两步构造：
先从「若 e n n 则矛盾」造出 d1 : e n n（这正是 ¬¬ 消去？不——是利用 iff 的
反向：hn.mpr 需要 ¬ e n n，而 ¬ e n n 由「e n n 蕴含自相矛盾」给出），再
正向引爆。整个过程**零公理**（`does not depend on any axioms`）——对角线
矛盾是直觉主义事实，与 04 章「经典账本」形成对照。

**化身二（位串版）**——布尔函数不可枚举：把 Prop 换成 Bool、iff 换成点态等式，
对角函数 g := fun x => !e x x，在 n 处得 e n n = !e n n，按位分情况即矛盾。
点态等式（∀ x, e n x = g x）的设计避开了函数外延性。

**化身三（一般 Cantor 定理，书 Thm 5.2.3）**——任意类型 A 上无满射
A → (A → Prop)：

```lean
theorem cantor_general (A : Type) (F : A → A → Prop) :
    ¬ (∀ P : A → Prop, ∃ a : A, ∀ x : A, F a x ↔ P x)
```

把 F 看作「a 的像」，结论即 |P(S)| > |S|：没有函数能把 A 的全部元素推满
A 的全部谓词。证明与化身一逐字相同——**幂集定理是对角线的直接推论**。
这与书 5.2.3 的表述（对任意集合 S，S ≺ P(S)）在「谓词 = 集合」的读法下
同构；(0,1) 的不可数性由「实数 ↪ ℕ → Bool 的对角线」在文档级衔接。

## 四、Russell 悖论：纯逻辑事实

书 §5.3.2 讲 Russell 1901 年的发现：把 Cantor 定理用到「万有之集」上出问题，
追究下去得到 N = {X : X ∉ X} 的自反矛盾。书 Thm 5.3.1 的构造版是：

```coq
Theorem russell : forall (A : Type) (R : A -> A -> Prop),
  ~ exists N, forall x, R x N <-> ~ R x x.
```

注意机器版的参数化：A 是任意类型、R 是任意二元关系——**不涉及任何集合论
公理**。这正是书 §5.3.5 的观点：Russell 悖论的推理只用 FOL（代入 + CP），
出问题的不是逻辑而是「任何条件都定义集合」这条朴素公设。Zermelo 的
分离公理（书 Axiom 5.3.2：{x ∈ U : P(x)} 必须从已存在的 U 里分离）把
N 的构造判为非法——ZFC 公理表（外延/分离/空集/并/配对/幂集/无穷/基础/
替换，书 §5.3.4–5.3.12）逐条在文档级讲解，机器不重复。

## 五、停机问题：对角线的计算化身

书 §5.3.13 的收尾论证（Turing 1936）：假设有万能停机判定器，构造对角程序
D「在 i 上停机当且仅当判定器说 i 在 i 上不停」，把 D 自己喂给判定器即矛盾。
书明说这是 informal 的（程序与编码未形式化）。机器版把两个构造作为
**显式公理**如实记账：

```coq
Axiom prog : Type.
Axiom halts_on : prog -> prog -> Prop.
Axiom H : prog -> prog -> bool.
Axiom H_sound_true  : forall p i, H p i = true  -> halts_on p i.
Axiom H_sound_false : forall p i, H p i = false -> ~ halts_on p i.
Axiom D : prog.
Axiom D_spec : forall i, halts_on D i <-> (H i i = false).

Theorem no_halting_checker : False.
```

六个公理两组：prog/halts_on/H/H_sound_* 是「停机判定器」的规范式描述
（判定器的正确性），D/D_spec 是对角程序的存在性（这是 Turing 论证里
真正需要的「程序自指」成分）。定理陈述是 **False**——即「这组公理不相容」：
不存在正确的停机判定器。证明六行：按 H D D 的返回值分情况，两个方向
都撞死在 D_spec 上。`Print Assumptions` 如实列出全部六条（Lean 版还带
propext 基线）——**账本透明**：机器没有假装证明了 Turing 定理，它证明的是
「判定器规范 + 对角构造 ⟹ 矛盾」，这正是书中 informal 论证的忠实形式化。

## 五点五、等势关系的代数（文档级补遗）

书 §5.1.3 定义的三层关系（S ≺ T 真小于、S ∼ T 等势、S ⪯ T 至多等势）
构成无穷世界的「序结构」：∼ 是等价关系（恒等映射、反函数、复合三引理，
书 Ex 5.1.6），⪯ 在 SB 定理下成为反对称的偏序。本章机器化取其中可在
类型论内零负担落地的片段：等势写成「单射 + 满射到达达集」的展开式
（`galileo`），至多等势写成单射（`pair_inj` + 平凡的 n ↦ (n,0)）。完整的
「等势类」论述需要商类型或函数外延性的配合，与 Schröder-Bernstein 一起
记为文档级，指向 26 章收官清单。

另一个值得记录的对位：书 Thm 5.1.2–5.1.4（可数集的真子集可数、删有限仍
可数、并有限仍可数）在机器上各有 nat 版本的轻松化身——`filter` 保可枚举、
`drop`/`append` 保枚举——它们的完整证明与第 46 章的列表计数工具共享引理池，
本教程不重复铺开。

## 坑位速记（本章实测）

- **Coq：`Nat.mul_cancel_l/r` 是 iff 不是蕴含**——`apply Nat.mul_cancel_r`
  会把目标变成 iff 无法收；自造 `cancel_mul_l/r`（包装 proj1）一步到位；
  注意参数序：`Nat.mul_cancel_l n m p (p≠0) : p*n = p*m ↔ n = m`，
  非零因子是**第三个**显式参数。
- **Coq：`lia` 不能直接造存在见证**——`assert (∃ j, y = x + S j) by lia`
  报错；要 `by (exists (y-x-1); lia)` 先给见证再让 lia 证等式。
- **Coq：`intro [e H]` 的方括号模式**在 `~ exists` 目标上是语法错——
  一律 `intros [e H]`（带 s）。
- **Lean：裸 core 无 `ring`**——交换半环恒等式全部走 AC-simp 八件套
  （45 章配方的再次应验）；跨等式搬运用 `(Nat.mul_assoc a b c).symm.trans h`
  项式构造，比 `rw [Nat.mul_assoc]` 方向可控。
- **Lean：`∃`/`∀` 的绑定体要显式类型**——`∀ P, ∃ n, ∀ x, e n x ↔ P x`
  会导致 P 的类型 metavariable 悬空（"Function expected at P"）；
  `∀ P : Nat → Prop` 一写就消。
- **Lean：`Iff` 假设的矛盾要两步走**——`hn : A ↔ ¬A` 的爆炸是
  `have d1 : A := hn.mpr (fun hev => (hn.mp hev) hev); exact (hn.mp d1) d1`；
  `absurd`/`fun hne => hne hn` 的直觉套用全部类型不合。
- **两通道：`pow` 的归纳步要 `cbn [pow]`/`show` 白名单展开**——`simpl`
  会把 2*x 展开成 x+(x+0) 之类的形状灾难（45 章 cbn 教训复现）；
  差值必须显式拆成「j+1」后继形再进 pow，`pow (y-x)` 的裸减法会卡死。

## 小结

三个化身共享同一根对角线：Cantor 的不可数、幂集定理、Russell 悖论、
停机问题——四件相隔半世纪的工作在机器上是同六个节目的变奏
（假设满射 → 取对角否定 → 自指 → 爆炸），而且全部直觉主义成立（零公理
账本为证）。ZFC 的九条公理作为文档级地图收尾，分离公理与 Russell 的
对位关系讲清。至此 Jongsma 的集合论线走完；下一章回到代数结构：
函数、等价关系与 ℤₙ——第 46 章的谓词集合和第 45 章的整除理论在那里会师。

---

上一章：[46 集合、幂集与计数](46-setscount.md) · 下一章：[48 函数与等价关系](48-funequiv.md)
