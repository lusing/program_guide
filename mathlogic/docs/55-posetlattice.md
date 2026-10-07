# 第 55 章 偏序与格

> 对书：Jongsma ch7（§7.1–7.2）。本章通道：C（`examples/49_posetlattice/ex55_posetlattice.v`）/
> L（`examples/49_posetlattice/ex55_posetlattice.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `divides` 三律 + `not_conn` | 整除偏序：自反/传递/反对称（乘法消去）+ 不连通（书例 7.1.3a） | C/L |
| `islub`/`isglb` + `lub_unique`/`glb_unique` | meet/join 的唯一性（书 Defn 7.2.1 前注 + Ex 7.2.1） | C/L |
| `mmax`/`mmin` + 特征引理四条 | (ℕ,≤) 全序格：max 是 join、min 是 meet（书 Defn 7.2.1 的现场） | C/L |
| `mmax_islub`/`mmin_isglb` + 代数律全家 | 交换/幂等/吸收/分配（书 Prop 7.2.2 + §7.2.3） | C/L |
| `dle`/`djn`/`dmt` 三律 + 规格件 | 五点菱形：非分配格的机器反例（书例 7.2.2a） | C/L |
| `Compute`/`#eval` gcd·lcm | divisor 格现场（书例 7.2.1a：6∧20=2、6∨20=60） | C/L |

第 54 章的等价关系把「相等」压缩成类；这一章的偏序把「相等」松开成
「可以比较」。同一套三律框架（自反/对称/传递）只改一处——对称性换成
反对称性——就得到一个方向性的世界：元素分层、有的可比有的不可比。
Jongsma 第 7 章沿这条线走到 Boole 代数：偏序 → 格（meet/join）→
分配律 → 有界/有补 → Boole 格。本章覆盖前半（§7.1–7.2），把「格的
代数律」与「非分配反例」做成机器件；Boole 格之后的公理化留给第 56 章。

## 一、偏序：把对称性松开

偏序是自反、反对称、传递的三元组（书 Defn 7.1.1）。反对称说
x ≤ y 且 y ≤ x 时 x = y——比较是单向的，两个方向同时成立就退回相等。
若还要求任两元素可比（连通），得到全序。书例 7.1.3a 给出本章的头号
现场：**自然数上的整除关系是偏序但不是全序**。三律直译：

```lean
def divides (a b : Nat) : Prop := ∃ k, b = a * k

theorem dvd_refl : ∀ n, divides n n := fun n => ⟨1, by omega⟩

theorem dvd_trans : ∀ a b c, divides a b → divides b c → divides a c := by
  intro a b c ⟨k1, h1⟩ ⟨k2, h2⟩
  exact ⟨k1 * k2, by rw [h2, h1]; simp [Nat.mul_assoc]⟩
```

反对称是三律里唯一要动真格的：b = a·k₁ 且 a = b·k₂ 代入得
a = a·(k₁·k₂)，问题变成**从 nat 的乘法中消去 a**。Coq 侧一步
`Nat.mul_cancel_l`（iff 引理，`proj1` 解包，非零因子在第三参——51 章
的老坑）加 `nia` 收尾。Lean 侧没有 nia，消去后的「k₁·k₂ = 1 推出
k₁ = k₂ = 1」要自己铺，核心链是：

```lean
have hS : (a'+1) * 1 = (a'+1) * ((k1'+1) * (k2'+1)) :=
  (Nat.mul_one (a'+1)).trans e0
have hP : 1 = (k1'+1) * (k2'+1) :=
  Nat.mul_left_cancel (Nat.succ_pos a') hS
have e2 : (k1'+1) * (k2'+1) = k1' * (k2'+1) + (k2'+1) :=
  Nat.succ_mul k1' (k2'+1)
have hLin : 1 = k1' * (k2'+1) + (k2'+1) := hP.trans e2
have hT1 : k1' * (k2'+1) = 0 := by omega
have hT2 : k2' = 0 := by omega
```

`hS` 把「a = a·S」整理成「a·1 = a·S」的标准消去形状，`hP` 消去
正因子 a'+1 得 S = (k₁'+1)·(k₂'+1) = 1。接下来是本章最重要的一个
教训：**不能把这个等式直接丢给 omega**——omega 只认带字面量因子的
乘积（51 章 `k1*k2` 这类原子被原样接受），而 `(k1'+1)*(k2'+1)`
两个因子都是复合项，omega 会**静默丢弃整条假设**，然后在残缺的
约束上宣布「可能不可证」。处方是先用纯等式链把它蒸馏成线性等式：
`e2` 用 `Nat.succ_mul` 展开（注意它产出 `.succ` 拼法，与 `+1` 不
语法相等——`have` 显式类型把拼法钉住），`hLin` 是两者拼接的产物，
到这一步 omega 才接得手。k₁' = 0 后回代 `h1 : b = (a'+1)*(0+1)`，
一条 `Nat.zero_add` + `Nat.mul_one` 改写链合拢 b = a。

不连通（书例 7.1.3a：2 与 3 互不整除）是 `not_conn`：对见证 k 做
四段 match，每段 omega——「2 = 3·k」在 k = 0,1,2 与 k ≥ 3 全部
矛盾。这一件虽小，却是「偏序 ≠ 全序」的机器证词。

## 二、Hasse 图与极值元素

偏序的图示是 **Hasse 图**（书 §7.1.1）：元素作点、可比关系作边、
小的在下；由传递性可推出的边一律省略。书例 7.1.4 并排画了 36 的
因子整除偏序与 P({0,1,2}) 的包含偏序——两张图形状相同不是巧合：
36 = 2²·3²，每个因子由每个素数的幂次（0/1/2）决定，正对应子集的
三维立方体。60 = 2²·3·5 的因子图（书例 7.1.7a）就是三维立方体
本身。「因子图的维度 = 互异素因子个数」是书习题 7.1.6 的主题。

极值元素（书 Defn 7.1.8）要分两对：**极大/极小**（没有元素严格在
其上/下）与**最大/最小**（在所有元素之上/之下）。前者可以有很多个，
后者若存在则唯一。书例 7.1.7b 的 {b,d}：两个元素既各自极大又各自
极小，但集合既无最大也无最小——「极大 ≠ 最大」的最小反例。这一
区分马上要用：meet/join 的定义说的是**最大**的下界、**最小**的上界，
而不是任何「极」界。

## 三、meet/join：定义与唯一性

书 Defn 7.2.1：x ∧ y（meet）是 {x,y} 的最大下界，x ∨ y（join）是
最小上界；Defn 7.2.2：每对元素都有 meet 与 join 的偏序叫**格**。
定义能这样写，前提是 lub/glb **唯一**（否则记号不良定）——书正文
一笔带过「unique when they exist (Exercise 1)」，本章把它做成正式
机器件。定义与唯一性定理：

```lean
def islub (R : Nat → Nat → Prop) (u x y : Nat) : Prop :=
  R x u ∧ R y u ∧ ∀ z, R x z → R y z → R u z

def isglb (R : Nat → Nat → Prop) (l x y : Nat) : Prop :=
  R l x ∧ R l y ∧ ∀ z, R z x → R z y → R z l

theorem lub_unique' : ∀ R x y u1 u2,
    (∀ a b, R a b → R b a → a = b) →
    islub R u1 x y → islub R u2 x y → u1 = u2 := by
  intro R x y u1 u2 hanti h1 h2
  have hu12 : R u1 u2 := h1.2.2 u2 h2.1 h2.2.1
  have hu21 : R u2 u1 := h2.2.2 u1 h1.1 h1.2.1
  exact hanti u1 u2 hu12 hu21
```

证明读出来正好是数学证明的骨架：u₂ 是上界而 u₁ 是**最小**上界，
故 u₁ ≤ u₂；对称地 u₂ ≤ u₁；反对称合拢相等。注意唯一性把反对称
作为**参数**传入——`lub_unique'` 对任意二元关系 R 成立，反对称是
租来的引擎。`glb_unique'` 是它的对偶（方向全反转）。对偶性从这里
开始成为本章主旋律：每个关于 ≤/∧/∨ 的定理都自动有一个 ≥/∨/∧ 的
镜像（书 Ex 7.1.21、7.2.11），第 56 章的对偶原理是它的收官。

## 四、(ℕ,≤)：第一个具体的格

全序集里任何两元可比，min 与 max 直接充当 meet 与 join——格定义的
最朴素现场。两通道都把 max/min 定义为条件表达式：

```coq
Definition mmax (x y : nat) : nat := if Nat.leb x y then y else x.
Definition mmin (x y : nat) : nat := if Nat.leb x y then x else y.
```

```lean
def mmax (x y : Nat) : Nat := if x ≤ y then y else x
def mmin (x y : Nat) : Nat := if x ≤ y then x else y
```

Coq 用布尔函数 `Nat.leb` 配 `Nat.leb_le` 改写；Lean 这个裸 core
版本**没有** `Nat.leb`（也不再有 `Nat.decide`），改用 Prop 级
`if x ≤ y`——由 `Decidable` 实例（`Nat.decLe`）驱动，配套的改写
件是通用的 `if_pos`/`if_neg`。

接着是本章的**方法论核心：特征引理装配**。直接对 mmax 的定义做
destruct，嵌套的 if/match 会把后续化简搅成一团（Coq 侧实测：暴力
destruct 后 lia 对着残余目标无能为力）。出路是先证四条「特征引理」
——按两元大小直接给出 mmax/mmin 的值——之后所有代数律都退化为
「按大小分情况、查表改写」：

```coq
Lemma mmax_big : forall x y, x <= y -> mmax x y = y.
Proof.
  intros x y H. unfold mmax.
  apply Nat.leb_le in H. rewrite H. reflexivity.
Qed.
```

```lean
theorem mmax_sml : ∀ x y, y ≤ x → mmax x y = x := by
  intro x y h
  show (if x ≤ y then y else x) = x
  match Nat.lt_trichotomy x y with
  | .inl hlt => omega
  | .inr (Or.inl heq) => rw [if_pos (by omega)]; exact heq.symm
  | .inr (Or.inr hgt) => rw [if_neg (by omega)]
```

`mmax_big`（x ≤ y 时取 y）走 `if_pos` 一行；`mmax_sml`（y ≤ x 时
取 x）有个易踩的坑：从 y ≤ x **推不出** ¬(x ≤ y)（x = y 时两者都
真），所以 `if_neg` 的侧条件必须先做三叉分类——等号支走 `if_pos`
再对称，严格小于支才轮到 `if_neg`。Lean 版起初直接
`rw [if_neg (by omega)]`，omega 当场拒绝（约束里 y ≤ x 与 x < y
相容），就是这个原因。

有四条特征引理在手，islub 的装配是流水线：先证上下界
（`mmax_ub`），再对每个候选上界 z 用特征引理改写后交给线性算术：

```lean
theorem mmax_islub : ∀ x y, islub Nat.le (mmax x y) x y := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      have hb : mmax x y = y := mmax_big x y (Nat.le_of_lt hlt)
      exact ⟨by rw [hb]; exact Nat.le_of_lt hlt,
             by rw [hb]; exact Nat.le_refl y,
             fun z hz1 hz2 => by rw [hb]; omega⟩
  | .inr hge => ...
```

代数律全家（书 Prop 7.2.2：交换/结合/幂等/吸收）全部照此装配。
幂等律一行（`mmax_idem := mmax_big x x (Nat.le_refl x)`）；吸收律
两分支：

```lean
theorem mmin_absorb : ∀ x y, mmin x (mmax x y) = x := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      rw [mmax_big x y (Nat.le_of_lt hlt), mmin_sml x y (Nat.le_of_lt hlt)]
  | .inr hge =>
      rw [mmax_sml x y hge, mmin_idem x]
```

结合律四分支、分配律 `mmin_over_mmax` 三叉嵌套八分支——每支都是
「改写—对齐—rfl/omega」的重复劳动，分支结构全部由 `Nat.lt_trichotomy`
或 `Nat.lt_or_ge` 提供。这正是书例 7.2.2 后注说的：检查格恒等式
没有巧劲，只有穷举——「给计算机编程来查，才是拉平差距之道」。
全序格必分配（书 Ex 7.2.19），所以 (ℕ,≤) 的分配律成立；但「必分配」
是全序的特权，下一节给出反例。

## 五、分配律会失败：五点菱形

书 §7.2.3 的警告：**不是所有格都分配**。书例 7.2.2 给出两个五点
反例——菱形（0 底、1 顶、a/b/c 中间互不可比）与五边形 N5——并
断言（不含证明）每个非分配格都藏着二者之一。菱形的 nat 化编码：

```lean
def dle (x y : Nat) : Prop :=
  x = y ∨ (x = 0 ∧ y ≠ 0) ∨ (y = 4 ∧ x ≠ 4)

def djn (x y : Nat) : Nat :=
  match x, y with
  | 0, w => w
  | w, 0 => w
  | 4, _ => 4
  | _, 4 => 4
  | w1, w2 => if w1 == w2 then w1 else 4
```

`dle` 的三个析取支分别是「相等」「底在下面」「顶在上面」；中间
三点 1/2/3 之间只有相等支可命中，正好互不可比。`djn` 是 join 的
表计算：遇底取对方、遇顶取顶、中间相同取自身、不同取顶。`dmt`
（meet）完全对偶：遇底取底、遇顶取对方、中间不同取**底**。

`dle` 确是偏序（`dle_refl`/`dle_antisym`/`dle_trans` 三件），
传递性是九分支的组合：相等支用改写传递，四个矛盾支销掉（Lean 侧
统一 `(by omega : False).elim`——见坑位），一个构造支照 p.1 的
见证拼出新析取：

```lean
theorem dle_trans : ∀ x y z, dle x y → dle y z → dle x z := by
  intro x y z h1 h2
  match h1, h2 with
  | Or.inl e, _ => rw [e]; exact h2
  | _, Or.inl e => rw [← e]; exact h1
  | Or.inr (Or.inl p), Or.inr (Or.inl q) => exact (by omega : False).elim
  | Or.inr (Or.inl p), Or.inr (Or.inr q) =>
      exact Or.inr (Or.inl ⟨p.1, by omega⟩)
  | ...
```

表计算不是自封的 join：`djn_islub_12` 验证 djn 1 2 = 4 真的是
1 与 2 的最小上界——上界两支直给（1 ≤ 4、2 ≤ 4 命中「顶」支），
最小性对任意候选 z 反推：z 若是 1、2 的公共上界而 z ≠ 4，则
z = 1 与 z = 2 同时成立，矛盾；故 z = 4。`dmt_isglb_12` 对偶。
最后是反例本身：

```lean
theorem diamond_nondist :
    dmt 1 (djn 2 3) ≠ djn (dmt 1 2) (dmt 1 3) := by
  show (1 : Nat) ≠ 0
  intro h
  simp at h
```

读数：a ∧ (b ∨ c) = 1 ∧ 4 = 1，而 (a ∧ b) ∨ (a ∧ c) = 0 ∨ 0
= 0——与书例 7.2.2a 的手算逐字对应。`show` 一步把两侧的字面量
match 全部化简（`djn 2 3` → 4、`dmt 1 4` → 1、`dmt 1 2` → 0），
剩下 1 ≠ 0。分配律之死，一行见证。

## 六、divisor 格：gcd 与 lcm

书例 7.2.1a 的第二个现场：n 的全体因子配上整除偏序是格，
**meet 是 gcd、join 是 lcm**——6 ∧ 20 = gcd(6,20) = 2，
6 ∨ 20 = lcm(6,20) = 60。机器面用标准库件演示数值面：

```coq
Compute (Nat.gcd 6 20).   (* 2 = 6 ∧ 20 *)
Compute (Nat.lcm 6 20).   (* 60 = 6 ∨ 20 *)
Compute (Nat.gcd 12 (Nat.lcm 12 20)).  (* 吸收律数值面：12 *)
```

第三个 Compute 是吸收律的数值面：x ∧ (x ∨ y) = x。完整的一般性
证明（对任意 x y 证 gcd x (lcm x y) = x）已在第 51 章以
`gcd_lcm_product`（乘积见证式）与 Bézout 件铺过，此处不重复造轮子。
Lean 侧同样的三个 `#eval` 输出 2/60/12。因子格是连接两章的桥：
51 章把 gcd/lcm 当**数论对象**处理（存在性、唯一性、Bézout），
本章把它们读作**格运算**——同一对函数的序论身份。

## 七、向前看：有界、有补、Boole 格

书 §7.2.4–7.2.5 为第 56 章搭好最后一级台阶，本教程按「文档级」
讲解：**有界格**有最小元 0 与最大元 1（书 Defn 7.2.4），极端元
与运算的互动是 0 ∨ x = x、1 ∧ x = x、0 ∧ x = 0、1 ∨ x = 1
（书 Prop 7.2.3）。有界才有资格谈**补**：x ∧ z = 0 且 x ∨ z = 1
（书 Defn 7.2.5），但补未必存在、存在也未必唯一——菱形里 a/b/c
互为补（三个补！）。加上**分配律**后补唯一（书 Prop 7.2.4），
其证明是吸收律的精彩连击：若 x̄ 与 z 都是 x 的补，则
z = 1 ∧ z = (x ∨ x̄) ∧ z = (x ∧ z) ∨ (x̄ ∧ z) = (x ∧ z) ∨ 0
= (x ∧ z) ∨ (x ∧ x̄) = x ∧ (z ∨ x̄) = x ∧ 1 = x。**有补分配格
即 Boole 格**（书 Defn 7.2.7），De Morgan 律在其中成立
（书 Prop 7.2.5），且基数只能是 2 的幂（书例 7.2.4：五点以内只有
1、2、4 点格是 Boole 格——1,2,4,…这个序列就是 2ⁿ）。第 56 章从
Boole 格走向 Boole 代数的公理系（§7.3），再落到逻辑门与真值表
（§7.4–7.6）。

## 坑位速记（本章实测）

- **数学先于战术**：`2*2 ≤ (k1'+1)*(k2'+1)` 这条「显然」路线根本
  不真（k₁'=k₂'=0 时右边是 1）——消去后的正确目标是乘积**等于 1**，
  再 succ_mul 展开。写证明前先验算目标。
- **Lean（本版裸 core）：`Nat.leb`/`Nat.leb_le`/`Nat.decide` 不
  存在**——布尔比较改走 Prop 级 `if x ≤ y` + 通用 `if_pos`/`if_neg`
  （`Decidable` 实例 `Nat.decLe` 自动就位）。
- **Lean：`if_neg` 的侧条件要从三叉来**——y ≤ x 推不出 ¬(x ≤ y)
  （等号双真）；等号支走 `if_pos` 再取对称。
- **Lean：omega 静默丢弃无字面量因子的乘积假设**——`(k1'+1)*(k2'+1)`
  整条被扔，约束残缺还报「可能不可证」；先用 `Nat.succ_mul` +
  `Eq.trans` 蒸馏成线性等式（`hLin`）再交 omega。
- **Lean：`Nat.succ_mul` 产出 `.succ` 拼法**——与 `+1` 不语法相等，
  `Eq.trans` 拒接；`have e2 : (k1'+1)*... := Nat.succ_mul ...` 用
  显式类型钉住拼法。
- **Lean：omega 直证合取目标拉 `Classical.choice`**——`A ∧ B :=
  by omega` 必中招；拆成单目标（`have h1 : A := by omega` 分别证）。
- **Lean：omega 面对非算术目标也拉 `Classical.choice`**——矛盾臂
  处方 `(by omega : False).elim`：先让 omega 出 False（安全），再
  `False.elim` 进任意目标。
- **Lean：term 级 match 的臂是项不是 tactic**——`fun z hz1 hz2 =>
  match ... | ... => omega` 非法（omega 不是项）；改 tactic 模式
  `intro` 后再 match。另：变量等式 `x = 0` 不能 `rfl`，用见证
  `p.1` 提供证明项。
- **Coq：min/max 的 match/if 定义暴力 destruct 后化简失灵**——
  特征引理装配范式（四条 big/sml 引理 + assert + rewrite）是正解；
  `le_lt_dec` 右支是 `<` 而特征引理要 `≤`，统一 `ltac:(lia)` 作实参。

## 小结

偏序把等价关系的对称性换成反对称，得到一个分层的方向世界；格
在其中补上 meet/join 两个运算，且二者唯一（反对称作引擎）。(ℕ,≤)
与 divisor 格给出两个具体现场——前者靠特征引理装配出全套代数律，
后者把 51 章的 gcd/lcm 接上序论身份。五点菱形击碎「格必分配」的
幻想，也把「有补」与「分配」逼成 Boole 格的两根支柱。下一章把
Boole 格抽象成公理系（Boole 代数），再看它如何长出逻辑门、真值表
与最小项展开——数理逻辑与数字电路在这里合流。

---

上一章：[54 函数与等价关系](docs/54-funequiv.md) · 下一章：[56 Boole 代数与逻辑电路](docs/56-boole.md)
