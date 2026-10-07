# 第 52 章 集合、幂集与计数

> 对书：Jongsma ch4（§4.1–4.5）。本章通道：C（`examples/46_setscount/ex52_setscount.v`）/
> L（`examples/46_setscount/ex52_setscount.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `inter_comm` 等 | 谓词集合运算律：交并的交换/结合/分配 + De Morgan（书 Prop 4.1.5–4.1.10） | C/L |
| `powl` / `powl_len` | 幂集的列表实现：\|P(S)\| = 2^\|S\|（书例 4.2.6） | C/L |
| `prodl` / `prodl_len` / `prodl_in` | 笛卡尔积：\|S×T\| = \|S\|·\|T\|（乘法计数原理，书 Prop 4.3.1a） | C/L |
| `choose` / `sumchoose_pow` | 组合数与 Σ C(n,k) = 2^n（书 Prop 4.4.1 的对账版） | C/L |
| `incexc2` / `incexc3` | 容斥原理二/三集合版（书 Prop 4.5.2 与 Thm 4.5.1） | C/L |

第 50 章把「数」公理化，这一章把「数的集合」搬上机器。Jongsma 的第 4 章从集合的
相等与包含讲起，经过交并补的运算律，抵达组合计数的三大原理（乘法、加法、容斥）。
这条线的漂亮之处在于：**集合运算律就是命题逻辑的替换规则换了一身衣服**——
S∩T 的成员条件是 x∈S ∧ x∈T，分配律就是 ∧ 对 ∨ 的分配，De Morgan 就是
¬(A∧B) ↔ ¬A∨¬B。本章第一节让这个对应精确到机器，后面几节则把计数原理
变成可以 Compute 验证的列表程序。

## 一、集合运算律：命题逻辑的化身

集合用谓词表示（`pset := nat -> Prop`），包含、交、并、补全部按书定义翻译：

```coq
Definition pset := nat -> Prop.
Definition sub (S T : pset) := forall x, S x -> T x.
Definition inter (S T : pset) : pset := fun x => S x /\ T x.
Definition union (S T : pset) : pset := fun x => S x \/ T x.
Definition compl (U S : pset) : pset := fun x => U x /\ ~ S x.
```

运算律**全部写成逐点 iff**而不是集合等式：命题外延（P ↔ Q 蕴含 P = Q）在 Coq
里是一条独立公理，逐点 iff 让每条定律保持零公理。交换律、结合律、分配律每条
都是一行 `tauto`——第 3 章自然演绎的规则在这里以命题演算的形式回收。

值得专门驻足的是 **De Morgan**：补(交) = 并(补) 的「→」方向本质上是经典命题
¬(A∧B) ⊢ ¬A∨¬B——直觉主义逻辑不承认它！书上的证明用的正是经典 PL 的 DeM
替换规则；机器上如实记账：

```coq
Theorem demorgan_inter : forall (U S T : pset) x,
  compl U (inter S T) x <-> union (compl U S) (compl U T) x.
Proof.
  intros U S T x. unfold compl, inter, union.
  destruct (classic (S x)); destruct (classic (T x)); tauto.
Qed.
```

`classic` 是 Coa 的排中律实例，`Print Assumptions` 会如实报告。Lean 侧用
`by_cases`（内部走 Classical.choice）。反向（补(并) = 交(补)）是直觉主义成立的，
不需要记账。这与第 4 章「语义层天生经典」的账本一脉相承：**经典性不在集合论里，
而在 De Morgan 的一个方向里**。

外延性（书 Defn 4.1.1：S = T ⟺ ∀x(x∈S ↔ x∈T)）在谓词表示下就是
`ext_eq`：互相包含 ⟹ 逐点双蕴含，构造性成立（书 Prop 4.1.1）。

## 二、幂集：每个元素的两个选择

幂集没有谓词版（P(S) 的成员是集合），改用**列表实现**：

```lean
def powl : List Nat → List (List Nat)
  | [] => [[]]
  | a :: t => (powl t).map (fun x => a :: x) ++ powl t
```

每个元素面临二选一：进子集（`map (a::)`）或不进（原样保留）。两条定理：

- **计数**：`powl_len : length (powl l) = 2 ^ length l`——归纳一步是
  长度翻倍（map 贡献一半、原表一半），与 2 的幂的递推严丝合缝。
  这是书例 4.2.6（{1,2,3} 的 8 个子集）的一般化，Compute 打印出的
  `[[1;2;3];[1;2];[1;3];[1];[2;3];[2];[3];[]]` 与书的手写列表逐项一致。
- **可靠性**：`powl_sound`：列出的每个候选确实是子列表（成员都在原表里）。

幂集的**完全性**（每个子列表都出现）对带重复元素的列表会失真（重复元素产生
重复候选），所以本章只机器化「列表版」的这两条；「幂集 = 所有子集的集合」
的集合论表述留给第 53 章的一般集合论讨论。

## 三、笛卡尔积与乘法计数原理

书 Prop 4.3.1a：|S×T| = |S|·|T|。列表实现与幂集同款：

```lean
def prodl : List Nat → List Nat → List (Nat × Nat)
  | [], _ => []
  | a :: s', t => (t.map (fun b => (a, b))) ++ prodl s' t
```

`prodl_len` 是一次归纳：每添一个首元素贡献 `|t|` 个对。成员刻画 `prodl_in`：
(x,y) ∈ S×T ⟺ x∈S ∧ y∈T——证明是对 «map 的成员» 与 «append 的成员» 两个
标准引理的组装。冒烟演示对上书例 4.3.2a：|{1,2,3,5}×{1,3,4}| = 12。

书 Corollary 4.3.1.1（乘法计数原理：m 种 × n 种 = m·n 种）就是这条长度等式的
事件化表述；推广形式（书 Cor 4.3.1.2）与二进制字节（书例 4.3.4 的 2⁸ = 256）
由 `powl_len` 的 2^n 一并覆盖。

## 四、组合数：Σ C(n,k) = 2^n

组合数按 Pascal 递归定义（书 Prop 4.4.4 的同行版）：

```coq
Fixpoint choose (n k : nat) : nat :=
  match n, k with
  | 0, 0 => 1
  | 0, S _ => 0
  | S n', 0 => 1
  | S n', S k' => choose n' k' + choose n' (S k')
  end.
```

注意 Coq 的多模式 match 必须穷尽——`(0, S _) => 0` 这一行（出界组合数为零）
不能省。**Σ_{k≤n} C(n,k) = 2^n** 是幂集定理的计数对账：n 元集合的子集按大小
分桶，大小为 k 的桶恰有 C(n,k) 个。证明分两步：

- `choose_gt`：k > n 时 C(n,k) = 0（对 n 归纳，出界清零）；
- `sumchoose_shift`：Σ_{k≤n+1} C(n+1,k) = Σ_{k≤n} C(n,k) + Σ_{k≤n+1} C(n,k)
  ——对桶数归纳，每项按 Pascal 展开后对消。

最后一步的形状值得看一眼：

```lean
theorem sumchoose_pow : ∀ n, sumchoose n n = 2 ^ n := by
  intro n
  induction n with
  | zero => rfl
  | succ n' ih =>
    rw [sumchoose_shift, ih]
    have h1 : sumchoose n' (n'+1) = sumchoose n' n' + choose n' (n'+1) := rfl
    have h2 : choose n' (n'+1) = 0 := choose_gt n' (n'+1) (by omega)
    have h3 : 2 ^ (n' + 1) = 2 ^ n' + 2 ^ n' := by
      rw [Nat.pow_succ]
      omega
    omega
```

`h3` 把 2^(n+1) 拆成两个 2^n 的和——「复制一份」正是幂集递推的算术影子。
Compute 演示：Σ_{k≤10} C(10,k) = 1024 = 2¹⁰；C(12,5) = 792。

书 Prop 4.4.1 的阶乘公式 C(n,k)·k!·(n−k)! = n! 机器化需要带边界情形分类的
双层归纳（外层 n、内层 k，在 k = n 处要单独用出界清零），按「诚实止步」记为
文档级定理，思路如上；数值验证 C(6,2)·2!·4! = 720 = 6! 由 Compute 承担。
（顺带一个 Coq 冷知识：nat 是一进制的，直接 `Compute (12!)` 会栈溢出——
479001600 个 S 构造子；数值验证要用小规模。）

## 五、容斥：把「重复计数」写成等式

书 Prop 4.5.2：|S∪T| = |S| + |T| − |S∩T|。nat 的减法在等式里不方便，
改写成**全加法形态**：

```coq
Theorem incexc2 : forall (P Q : nat -> bool) l,
  length (filter (fun x => P x || Q x) l)
  + length (filter (fun x => P x && Q x) l)
  = length (filter P l) + length (filter Q l).
```

把「有限集合」实现为列表加布尔谓词，并/交就成了 filter。证明是对列表的
一次归纳，归纳步按 (P a, Q a) 的四种取值分类——每类里等式两边各长多少一目
了然，`lia` 收尾。三集合版（书 Thm 4.5.1 的 n=3 情形）同款：

```coq
Theorem incexc3 : forall (P Q R : nat -> bool) l,
  length (filter (fun x => (P x || Q x) || R x) l)
  + length (filter (fun x => P x && Q x) l)
  + length (filter (fun x => P x && R x) l)
  + length (filter (fun x => Q x && R x) l)
  = length (filter P l) + length (filter Q l) + length (filter R l)
    + length (filter (fun x => (P x && Q x) && R x) l).
```

八个 case、每个纯算术。书 Thm 4.5.1 的一般形式（n 个集合的交错和）依赖
「每个元素被数恰好一次」的组合恒等式 Σ(−1)^{k+1} C(m,k) = 1，与本章的
sumchoose 一族衔接，完整机器化是后续工作（清单在 58 章收官）。

## 坑位速记（本章实测）

- **Coq：多模式 match 必须穷尽**——`match n, k with` 的 (0, S _) 分支漏写
  直接报「Non exhaustive」；这恰好逼你显式给出「出界组合数为零」这条语义。
- **Coq：`simpl` 在含 `(fun b => (a,b))` 的高阶 map/ filter 上会爆栈**——
  换 `cbn [filter length orb andb]` 白名单展开；白名单里忘了 `orb`/`andb`
  会留下 `if true || true then …` 卡住 lia。
- **Coq：`Nat.factorial` 与一进制 nat**——大数 Compute 栈溢出（12! ≈ 4.8 亿
  个构造子）；数值验证用小规模等式（C(6,2)·2!·4! = 6!）。
- **Coq：谓词集合的相等**——命题外延（P↔Q ⇒ P=Q）是公理；运算律改写成
  逐点 iff 保持零公理；De Morgan 的经典方向如实引入 `classic` 记账。
- **Coq：`induction` 前先 `intros` 谓词**——对 `∀P Q l` 的目标直接
  `induction l` 会把 P Q 也一起通用化（49 章坑的镜像：这里反而要先固定）。
- **Lean：`List.Mem` 不是 `Or`**——`x ∈ a :: l` 的拆装走 `List.mem_cons.mp/mpr`
  与 `List.mem_append.mp`；直接对成员关系做 Or 模式匹配会解析失败。
  构造方向 `mem_cons_of`、`Mem.tail` 在裸 core 里名字对不上时，一律走 iff 引理。
- **Lean：`(x, y).1` 的改写陷阱**——改写 `.1` 不会触及匿名对 `(x, y)` 本身；
  含点取的命题先用 `.1`/`.2` 展开陈述（本章 prodl_in 干脆改成
  `∀ x y, (x, y) ∈ …` 的点式形态，绕开投影）。
- **Lean：`choose n 0` 对变量 n 不归约**——match 在 n 上卡住；先证
  `choose_n0 : ∀ n, choose n 0 = 1`（对 n 分类各 rfl）再交给 omega。
- **Lean：`Nat.factorial` 不在裸 core**——自造 `nfact`。

## 小结

集合语言在两个通道上落地：谓词版承载运算律（与命题逻辑的同构被 tauto 一行行
回收，经典账本只记在 De Morgan 的一个方向上），列表版承载计数（幂集翻倍、
笛卡尔积相乘、组合数分桶求和、容斥交错）。四件计数定理——2^n、|S|·|T|、
Σ C(n,k) = 2^n、容斥——构成一个闭环：它们数的是同一个对象（子集、对、
组合、并集），方法则是第 50 章归纳法的算术应用。下一章把「无穷」搬上机器：
可数、对角线、Cantor。

---

上一章：[51 整除性与初等数论](docs/51-divisibility.md) · 下一章：[53 无穷集合与停机问题](docs/53-infinity.md)
