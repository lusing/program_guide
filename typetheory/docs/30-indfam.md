# 30 归纳类型族：ℕ、列表、Σ、不交和

> 对应读本：Nordström 第 9–13 章（自然数 / 列表 / 两个集合的
> 笛氏积 / 集合族的笛氏积 / 集合族的不交和）。
> 代码：`examples/30_indfam/`——三家**全部自造**（不用库里现成的
> nat/list）：N、加法交换律、前驱与 Peano 第三公设、列表结合律、
> Σ、不交和。

## 30.1 四个构造器，一套语法

Nordström 第 9 章起进入「归纳定义的集合」。四个基本构造器
（连同前面的 Π 与枚举）撑起了 MLTT 的全部数据世界：

```text
ℕ      构造子 0、succ            归纳原理 = 数学归纳法
List A 构造子 nil、cons          归纳原理 = 列表归纳
Σ A B  构造子 ⟨a,b⟩              投影 split（一对一定型）
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
消去子（怎么用）、归纳原理（怎么证）。书里的原始选取子
`natrec(a,d,e)`（自然数）、`listrec(l,c,e)`（列表）、
`split(p,e)`（积）、`when(c,d,e)`（和）各有两步计算规则
（27.4 节的 lazy 协议）——三家的 match/模式匹配就是这些
选取子的现代化身。Coq 打印得最直白：`Print N_ind`（Prop 版）
与 `Print N_rect`（Type 版「大消去」）；Lean 里两者是
`N.rec`/`N.recOn`/`N.casesOn` 家族；Agda 里没有独立的
归纳原理名字——**模式匹配的完备性检查就是归纳原理**。

## 30.2 natrec：原始递归与它的消去论证

书 9 章的 natrec 规则组值得完整看一遍——它是「原始递归定义
函数」的类型论化身：

```text
N-消去    a ∈ ℕ,  C(v) set[v∈ℕ],  d ∈ C(0),
          e(x,y) ∈ C(succ(x))[x∈ℕ, y∈C(x)]
          ⟹ natrec(a,d,e) ∈ C(a)
N-相等1   natrec(0,d,e) = d ∈ C(0)
N-相等2   natrec(succ(a),d,e) = e(a, natrec(a,d,e))
```

加法与乘法是 natrec 的两次嵌入：

```text
x ⊕ y ≜ natrec(x, y, (u,v)succ(v))
x ⊗ y ≜ natrec(x, 0, (u,v)⊕(y,v))
```

**消去规则的语义论证**（书 9 章示范）是全书论证法的典型：
若 a 的值为 0，natrec 的值得 d 的值，由前提是 C(0) 的典则元，
由族外延性 C(a)=C(0)，收官；若 a 的值为 succ(b)，则值为
`e(b, natrec(b,d,e))`——**对 natrec(b,d,e) 的义务递归地重复
这个论证**。「此方法将终止，这是因为所有自然数是由后继函数
作用有穷多次于 0 而得」——**良基性不是规则给的，是引入规则
（典则元的形状）给的**。Peano 第五公设（归纳法）正是把这条
消去规则命题化的产物：

```text
a ∈ ℕ, C(v) prop[v∈ℕ], C(0) true, C(succ(x)) true[C(x) true]
⟹ C(a) true
```

## 30.3 Peano 公设的三副面孔

书 9 章用前驱函数证 Peano 第三公设，并留下第四公设的悬念——
三条公设在类型论里的地位各不相同，值得排成一表：

| 公设 | 内容 | 类型论身份 |
|---|---|---|
| 第三 | succ(m)=succ(n) ⟹ m=n | **前驱函数可导**：pred ≜ (x)natrec(x,0,(u,v)u)，对 succ 等式两侧替代 + N-相等 2 折叠 pred(succ(m))=m |
| 第四 | 0 ≠ succ(n) | **需要全域 U 才能证**（31 章完整证明；Smith 1988 证明无全域时不可导） |
| 第五 | 归纳原理 | **就是 N-消去规则**的命题化（30.2） |

第三公设还有「两种表述」的教学点（书 9 章例）：作为**导出
规则**（判断层的 `succ(m)=succ(n) ∈ ℕ ⟹ m=n ∈ ℕ`）与作为
**命题**（`Πx,y:ℕ. Id(ℕ,succ x,succ y) ⊃ Id(ℕ,x,y)`）——
推导同构（都用 pred + 替代），但一个是判断、一个是集合，
本质不同。Agda 件里机器化的是命题版：

```agda
pred : N → N
pred z     = z
pred (s n) = n

peano3 : ∀ m n → Id N (s m) (s n) → Id N m n
peano3 m n refl = refl          -- 模式匹配后 succ 单射由构造显现
```

——Agda 的版本甚至不需要 pred：**对 refl 匹配直接把 m、n
统一成同一项**，单射性是模式匹配语法的赠品。这与书里用
pred + 替代规则的推导形成「语法已吸收语义」的对照。

## 30.4 列表：append 的定义等式与结合律

书 10 章的 listrec 与 natrec 同构，新增的只有「负载」——
cons 带 A 的元素。append 的定义与两条定义等式：

```text
l₁ @ l₂ ≜ listrec(l₁, l₂, (x,y,z)x·z)
nil @ l₂  = l₂                （List-相等 1）
(a·l₁) @ l₂ = a·(l₁ @ l₂)    （List-相等 2）
```

结合律 `p@(q@r) = (p@q)@r` 的证明对 p 归纳：nil 处定义折叠、
cons 处两条定义等式 + 归纳假设收尾——**归纳方向由递归侧
决定**（@ 递归在第一参数，归纳就跟第一参数）。三家件里
`app_assoc` 的完整证明各走一遍（Agda 的三行版最短）。

## 30.5 Σ 与不交和：逻辑的合取/析取/存在

依赖对与不交和是 Σ/Π 世界的另一半（书 11–13 章：两个集合的
笛氏积 × 是 Σ 的非依赖特例、集合族的笛氏积 Σ、集合族的不交和）：

```lean
structure Sig2 (α : Type) (β : α → Type) where
  fst : α
  snd : β fst

inductive Sum2 (α β : Type) where
  | inl : α → Sum2 α β
  | inr : β → Sum2 α β
```

Curry–Howard 读法直接兑现（08 章对应表的依赖部分）：

| 类型 | 逻辑 |
|---|---|
| `Σ (x:A). B x` | 存在量词 ∃x. B（见证 + 证据） |
| `A + B` | 析取 A ∨ B |
| `A × B` | 合取 A ∧ B（书 11.1：`& ≜ ×`） |
| `Σ` 的投影 | ∃-消去的见证提取 |
| `+` 的 elim2 | ∨-消去的分情况 |

注意 Σ 的**类型依赖第一分量**（`snd : β fst`）——这是 19 章
依赖类型的「数据版」，与 `Vec α n`（索引版）是同一枚硬币的
两面：**结构依赖（Σ）与索引依赖（族）**。Agda/Lean 里两者
常可互换（33 章子集类型处再对照），Coq 的 `sig`/`sigT` 与
`vec` 分野更明显。

## 30.6 到此为止的完整版图

把 27–30 章的构造器叠起来，MLTT 的「集合宇宙」已经成型：

```text
枚举（⊥ ⊤ Bool）+ Π + Σ + 不交和 + ℕ + List + Id + W(32 章)
= 直觉主义类型论的完整数据世界
```

Nordström 第二部分（17–18 章的子集理论）在 33 章对应、
小集合的全域 U 在 31 章。还差的最后一块基本拼图是
「归纳定义的一般形式」——W 类型（32 章）。

> **坑位速记**
> ① Lean `rw`/`rewrite` 匹配的是**语法**层面——`add (s n) m`
>   内部（iota 折叠后）的 `add n m` 要 `simp only [add]` 暴露后
>   才可重写（本章 add_z/add_s/app_nil_r/app_assoc 四连踩）；
> ② 交换律的归纳分支里辅助引理的**方向**要选对：Lean 用
>   `rw [add_s m n, ← ih]`（先改 RHS 再反向用 IH），Coq/Agda
>   各有惯用朝向；
> ③ Agda 保留字 `inductive` 连累文件名/目录名（29 章坑位③），
>   本章目录从 13_inductive 改名 30_indfam 才过；
> ④ Coq 自造 Record 的字段访问要带参数（`sfst N (fun _ => Lst N)`
>   式的完全应用），或 `Arguments sfst {A B}` 后简写；
> ⑤ Agda 证 Peano 第三公设不必走前驱函数——对 refl 匹配即把
>   两侧统一，succ 单射是模式匹配的赠品（书里的 pred+替代
>   推导是「语法未吸收语义」时代的写法）。

---

上一章：[29 相等与 J](29-identity.md) · 下一章：[31 全域](31-universes.md)
