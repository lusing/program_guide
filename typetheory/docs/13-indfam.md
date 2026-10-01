# 13 归纳类型族：ℕ、列表、Σ、不交和

> 对应读本：Nordström 第 9–13 章（自然数 / 列表 / 笛氏积 /
> 不交和 / 集合族的不交和）。
> 代码：`examples/13_indfam/`——三家**全部自造**（不用库里现成的
> nat/list）：N、加法交换律、列表结合律、Σ、不交和。

## 13.1 四个构造器，一套语法

Nordström 第 9 章起进入「归纳定义的集合」。四个基本构造器
（连同前面的 Π 与枚举）撑起了 MLTT 的全部数据世界：

```text
ℕ      构造子 z、s               归纳原理 = 数学归纳法
List A 构造子 []、::             归纳原理 = 列表归纳
Σ A B  构造子 (a, b)             投影 fst/snd（一对一定型）
A + B  构造子 inl、inr           分情况（不交和）
```

三家文件并排给出同一组定义。以 ℕ 为例：

```lean
inductive N where
  | z : N
  | s : N → N

def add : N → N → N
  | .z, m => m                    -- 递归在第一参数
  | .s n, m => .s (add n m)
```
```coq
Inductive N : Set := Nz | Ns : N -> N.
Fixpoint add (n m : N) : N :=
  match n with Nz => m | Ns n' => Ns (add n' m) end.
```
```agda
data N : Set where
  z : N
  s : N → N

add : N → N → N
add z     m = m
add (s n) m = s (add n m)
```

**声明即三件套**：每个归纳定义自动生成——构造子（怎么造）、
消去子（怎么用）、归纳原理（怎么证）。Coq 打印得最直白：
`Print N_ind`（Prop 版）与 `Print N_rect`（Type 版「大消去」）；
Lean 里两者是 `N.rec`/`N.recOn`/`N.casesOn` 家族；Agda 里没有
独立的归纳原理名字——**模式匹配的完备性检查就是归纳原理**。

## 13.2 加法交换律：Peano 三步走

同一个定理三家的完整证明（文件里逐行可跑）：

```lean
theorem add_comm (n m : N) : add n m = add m n := by
  induction n with
  | z => rw [add_z]; rfl
  | s n ih => rw [add_s m n, ← ih]; rfl
```
```coq
Theorem add_comm : forall n m, add n m = add m n.
Proof.
  induction n as [| n IH]; intros m; simpl.
  - rewrite add_z. reflexivity.
  - rewrite add_s, IH. reflexivity.
Qed.
```
```agda
add-comm : ∀ n m → add n m ≡ add m n
add-comm z     m = sym (add-z m)
add-comm (s n) m = trans (cong s (add-comm n m)) (sym (add-s m n))
```

**为什么需要两条辅助引理**（`add_z`、`add_s`）：加法定义递归在
第一参数，于是「另一侧」的两个等式（`n+0=n`、`n+Sm=S(n+m)`）
不定义成立、必须归纳证明——12 章的方向学在归纳数据上重演。
三家写法差异全在表层：Lean/Coq 的 tactic 对「隐藏在 iota 折叠
之下的子项」需要 `simp only [add]` 或 `simpl` 先行暴露（rw 只看
语法），Agda 的 `cong` 写法天然没有这个问题。

## 13.3 Σ 与不交和：逻辑的合取/析取/存在

依赖对与不交和是 Σ/Π 世界的另一半：

```lean
structure Sig2 (α : Type) (β : α → Type) where
  fst : α
  snd : β fst

inductive Sum2 (α β : Type) where
  | inl : α → Sum2 α β
  | inr : β → Sum2 α β
```

Curry–Howard 读法直接兑现（05 章对应表的依赖部分）：

| 类型 | 逻辑 |
|---|---|
| `Σ (x:A). B x` | 存在量词 ∃x. B（见证 + 证据） |
| `A + B` | 析取 A ∨ B |
| `Π (x:A). B x` | 全称（07 章已见） |
| `Σ` 的投影 | ∃-消去的见证提取 |
| `+` 的 elim2 | ∨-消去的分情况 |

注意 Σ 的**类型依赖第一分量**（`snd : β fst`）——这是 07 章
依赖类型的「数据版」，与 `Vec α n`（索引版）是同一枚硬币的
两面：**结构依赖（Σ）与索引依赖（族）**。Agda/Lean 里两者
常可互换（16 章子集类型处再对照），Coq 的 `sig`/`sigT` 与
`vec` 分野更明显。

## 13.4 到此为止的完整版图

把 10–13 章的构造器叠起来，MLTT 的「集合宇宙」已经成型：

```text
枚举（⊥ ⊤ Bool）+ Π + Σ + 不交和 + ℕ + List + Id + W(15 章)
= 直觉主义类型论的完整数据世界
```

Nordström 第二部分（17–18 章的子集理论）与第三部分
（小集合的全域 U）分别在 16、14 章对应。还差的最后一块
基本拼图是「归纳定义的一般形式」——W 类型（15 章）。

> **坑位速记**
> ① Lean `rw`/`rewrite` 匹配的是**语法**层面——`add (s n) m`
> 内部（iota 折叠后）的 `add n m` 要 `simp only [add]` 暴露后
> 才可重写（本章 add_z/add_s/app_nil_r/app_assoc 四连踩）；
> ② 交换律的归纳分支里辅助引理的**方向**要选对：Lean 用
> `rw [add_s m n, ← ih]`（先改 RHS 再反向用 IH），Coq/Agda
> 各有惯用朝向；
> ③ Agda 保留字 `inductive` 连累文件名/目录名（12 章坑位③），
> 本章目录从 13_inductive 改名 13_indfam 才过；
> ④ Coq 自造 Record 的字段访问要带参数（`sfst N (fun _ => Lst N)`
> 式的完全应用），或 `Arguments sfst {A B}` 后简写。
