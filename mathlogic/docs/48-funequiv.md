# 第 48 章 函数与等价关系

> 对书：Jongsma ch6（§6.1–6.4）。本章通道：C（`examples/48_funequiv/ex48_funequiv.v`）/
> L（`examples/48_funequiv/ex48_funequiv.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `inj`/`surj` + 复合 | 单射/满射/双射（书 Defn 6.1.4）+ 复合保持（书 Prop 6.2.1） | C/L |
| `surj_right_inv` / `inj_left_inv` | 满射⇒右逆、单射⇒左逆（书 Thm 6.2.2 部件，搜索构造） | C/L |
| `congN` + `congN_eqrel` | 同余 mod n 是等价关系（书 Defn 6.4.5 + Ex 6.4.27a） | C/L |
| `congN_add_wd` / `congN_mul_wd` | 加法/乘法 mod n 良定义（书 Prop 6.4.6/6.4.7） | C/L |
| `rem` / `rmod` | 余数函数与正确性（45 章 dm2 的单品版） | C/L |

第 46 章给了集合的语言，第 47 章给了无穷的分野，这一章把两支汇合：函数是
「带结构的对应」，等价关系是「被压缩的相等」，而 ℤ 与 ℤₙ 是等价关系造出的
新数系。Jongsma 的第 6 章沿这条线走：单射满射双射 → 复合与逆 → 等价关系
与划分互构 → 整数的差对构造 → 模算术。机器化的重心放在两处：**逆函数的
构造性存在**（书 Thm 6.2.2 在朴素集合论里是「像集上的逆」，在类型论里变成
可计算的搜索）与**良定义性**（商运算不依赖代表元的机器验证——这是构造 ℤ 与
ℤₙ 时真正的数学内容）。

## 一、单射、满射与复合

书 Defn 6.1.4 的两个性质直译：

```lean
def inj (f : Nat → Nat) : Prop := ∀ x y, f x = f y → x = y
def surj (f : Nat → Nat) : Prop := ∀ y, ∃ x, f x = y
```

书 Prop 6.2.1 的两条复合保持各四行。开场的老朋友是 `succ_not_surj`：
后继函数不满（0 没有原像）——这是书 Ex 6.1 的经典对照，也是对角线
方法的最小前驱（一个被系统性遗漏的点）。

双射定义为单射+满射的合取（`bij`），与第 47 章 `galileo` 用的展开形态
一致。域限制在 nat→nat：一般类型的函数性质在两通道的 dependent type
支持下并不更难，但固定 nat 让「搜索」件可以落地。

## 二、左逆与右逆：搜索构造

书 Thm 6.2.2 说：f 可逆 ⟺ f 双射，且逆唯一。朴素集合论里的证明用
「对每个 y 取唯一的原像」——这在构造性类型论里**不能直接照抄**：从
∀y ∃x 出发提取函数需要选择公理。机器版的路线是把「取原像」变成
**可计算的搜索**：

```lean
def searchPre : (Nat → Nat) → Nat → Nat → Option Nat
  | _, _, 0 => none
  | f, n, k'+1 => if f k' == n then some k' else searchPre f n k'
```

`searchPre f n d` 在 [0, d) 里自上而下找第一个映到 n 的点。两个方向：

- **满射 ⇒ 右逆**（`surj_right_inv`）：任取 y 的原像见证 x，取搜索深度
  d := x+1。关键引理 `searchPre_notNone`：若 f x = y 且 x < d，则深度 d
  的搜索不会空手而归——对 d 归纳，命中层用「f x = y」判定。于是
  `pinvB f y (x+1)` 找到的 x' 满足 f x' = y。注意陈述是
  **∃ b, f (pinvB f y b) = y**——深度 b 是见证的一部分。这是 nat 上的
  诚实形态：任意满射的原像可能远大于 y，固定深度 S y 的「伪逆」对
  深度不够的原像会失效（本教程第一版在这里翻过车，见坑位）。

- **单射 ⇒ 左逆**（`inj_left_inv`）：深度 x+1 的搜索必命中（x 自己就是
  f x 的原像），命中的 y' 满足 f y' = f x，单射给出 y' = x。

书 Thm 6.2.2 的「双射 ⇒ 逆存在」由两件合取直接装配；逆的唯一性需要
函数外延性，按惯例记文档级。

## 三、等价关系与划分

书 Defn 6.3.1–6.3.3 的三元组（自反/对称/传递）与划分定义（两两不交 +
覆盖全集）在文档级讲解；书 Thm 6.3.1 的互构（等价关系诱导划分、划分
诱导等价关系）的完整机器化需要 no-dup 列表的大量簿记，本教程按
「诚实止步」记文档级，机器面给两个具体现场：本章的 congN 与下一章的
Boole 格。等价关系的定义件：

```lean
def eqrel (R : Nat → Nat → Prop) : Prop :=
  (∀ x, R x x) ∧ (∀ x y, R x y → R y x) ∧ (∀ x y z, R x y → R y z → R x z)
```

## 四、同余 mod n：全加形态的胜利

书 Defn 6.4.5 定义 m ≡ₙ r ⟺ n ∣ (m − r)——这个「差被 n 整除」的形态
在 nat 上有一个著名的坑：m − r 是截断减法。机器版采用**全加形态**：

```lean
def congN (n a b : Nat) : Prop :=
  ∃ k, a + k * n = b ∨ b + k * n = a
```

「a 与 b 相差 n 的某个倍数」写成两个方向的析取——不出现减法，
在 nat 上与书的 ℤ 版定义逐点等价。围绕它有两个机器件：

**正规形引理**（`congN_normal`）：

```lean
theorem congN_normal : ∀ n a b,
    congN n a b ↔ ∃ k1 k2, a + k1 * n = b + k2 * n
```

双侧平移等式是这个等价关系的「规范型」：单向析取的两个方向统一成
一个对称的等式，代价是引入两个（而不是一个）倍数参数。反向的构造
要按 k1、k2 的大小分三种情况，每种用 `Nat.add_mul` 展开后交给 lia/omega。

**等价关系**（`congN_eqrel`）：自反与对称各一行；传递性是全章最重的
组合现场。直接拼单向形态会在混合方向（x ≤ y、y ≥ z）处卡住——书上的
证明暗中用了 ℤ 的减法。机器版把传递性拆成四象限：同向两支直接拼
见证（k+j），混合两支走正规形——而正规形对 mixed case 又要用
`Nat.mul_le_mul` 显式提供 k1·n ≤ k2·n 这类**乘法单调性事实**，
lia/omega 自己推不出（它们把 k1·n、k2·n 当作不透明原子）。

```lean
| ⟨k, Or.inl h1⟩ =>
  match hz with
  | ⟨j, Or.inl h2⟩ =>
    clear hy hz
    refine ⟨k + j, Or.inl ?_⟩
    have e0 : (k + j) * n = k * n + j * n := Nat.add_mul k j n
    omega
```

见证 k+j 的展开 `Nat.add_mul` 是每个同向分支的固定件——没有它，
(k+j)·n 与 k·n + j·n 是两个互不相干的原子。

## 五、良定义：商运算的机器验证

书 Prop 6.4.6（加法 mod n 良定义）与 Prop 6.4.7（乘法）是「等价类上
定义运算」的标准范式：定义 [a] + [b] := [a+b] 之前必须验证换代表元
不改变结果。机器版用正规形一举拿下两个方向：

```lean
theorem congN_add_wd : ∀ n a b a' b',
    congN n a a' → congN n b b' → congN n (a + b) (a' + b')
```

证明：把两个同余都化成双侧平移等式 a + j₁n = a' + j₂n、b + j₃n = b' + j₄n，
目标见证取 j₁+j₃、j₂+j₄，加法结合交换后线性可解。乘法版是书的
「缩放再相加」的忠实复刻：用 `congrArg (· * b)` 把第一条等式缩放 b 倍、
`congrArg (a' * ·)` 把第二条缩放 a' 倍，两个缩放等式相加恰好拼出
ab 与 a'b' 的双侧平移——见证是 j₁b + j₃a'（左侧）与 j₂b + j₄a'（右侧）。

这一节与第 44 章的 ℤ 构造（书 §6.4.2 的差对模型 (a,b) ≡ (a',b') ⟺
a+b' = a'+b）共享同一个数学心脏：**新数系 = 旧数系上的等价类**。
差对模型的良定义机器化（加法 Prop 6.4.1 的四步）与 congN 同构，
本教程不重复铺开，指向 44 章的 sadd 交换律装配与本章正规形引理。

`rem`（余数函数）复用 45 章 dm2 的思路以单品形式提供——
rmod 是「反复减 n 直到不够减」的燃料版，`rem a n := rmod (a+n) a n`
取燃料 a+n 保证永远够。Compute 演示：rem 17 5 = 2、rem 12 7 = 5。

## 坑位速记（本章实测）

- **「伪逆」的深度陷阱**：固定深度 S y 的搜索对原像 > y 的满射失效
  （反例：f 把大数映到小数）。诚实陈述是 ∃b, f (pinvB f y b) = y——
  深度作为见证的一部分；左逆的深度取 S x 恰好（x 自己是原像）。
- **Coq：`Nat.mul_cancel_l/r` 是 iff**——与 45 章同坑；注意参数序
  `mul_cancel_l n m p (p≠0) : p*n = p*m ↔ n = m`，非零因子在第三位。
- **Coq：`Nat.mul_sub_distr_r`**（不是 `mul_sub_distrib_r`）——
  (n−m)*p = n*p − m*p 的名字少一个 i；传递性正规形反向全靠它
  加 `Nat.mul_le_mono` 的显式单调事实。
- **Coq：`injection H as ->` 在 0.5 环境不稳定**——统一用
  `injection H as Hx; subst x`；`simpl` 后的 `discriminate H` 目标
  形状要先对齐。
- **Lean：match 保留 scrutinee**——`match h with | ⟨k, hk⟩ => ...`
  之后原假设 h（含 ∃！）仍在上下文；**omega 见 ∃ 拉 Classical.choice**
  （43 章坑的完整形态）。处方：每个臂的第一行 `clear h`。congN 三定理
  的账本从 [Classical.choice] 修到仅基线全靠这一招。
- **Lean：`rw [searchPre] at hd` 报「Failed to rewrite using equation
  theorems」**——模式匹配定义的方程引理不直接可用；处方：
  `have h2 : (if f d' == y then some d' else searchPre f y d') = none := hd`
  的**have 型强转**（defeq 直达），再 `split at h2`。
- **Lean：`simp only [searchPre]` 同病**——「no progress」假象；
  同样走 have 强转。
- **Lean：`(k+j)*n` 与 `k*n + j*n` 是不同原子**——omega 不做分配；
  每个组合见证都要 `have e0 := Nat.add_mul k j n` 预展开。
- **Lean：`at s1, s2 ⊢` 逗号语法不存在**——`at s1 s2 ⊢`（空格分隔）。

## 小结

函数性质与等价关系在 nat 上落地：复合保持是四行装配；逆的存在从
选择公理改写成搜索计算（右逆带深度见证、左逆取自身深度）；同余的
全加形态避开截断减法，正规形引理把等价关系与良定义统一成「双侧
平移等式」的线性代数。良定义一节是下一章的直接热身：Boole 代数里
的对偶原理同样是「换代表不改变结果」的验证。下一章：偏序、格与
Boole 代数——46 章的集合运算律将在那里获得代数身份。

---

上一章：[47 无穷集合与停机问题](47-infinity.md) · 下一章：[49 偏序与格](49-posetlattice.md)
