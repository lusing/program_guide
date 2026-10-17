# 29 相等类型与 J：内涵相等的手工课

> 对应读本：Nordström 第 8 章（相等性集合：内涵 Id 与外延 Eq
> + Π-元素的 η-相等性）。
> 代码：`examples/29_identity/`——三家各自**从零手推**等式的
> 四件套（sym / trans / cong / transport），全部只依赖 refl
> 与 J；外加 Eq 强消去与 η 的三家 defeq 对照实验。

## 29.1 Id 类型：refl 加一条规则

Nordström 第 8 章给出相等集合 `Id(A, a, b)`——现代写法
`a = b`（Agda 里 `a ≡ b`）。为什么要它：**判断相等性不能
用于构造命题**——`a = b ∈ A` 是判断、不是集合，要把它变成
能居留、能量化的对象，必须有一个集合形成运算。构造子只有
一个：

```text
refl : Id(A, a, a)          （书里记作 id(a) ∈ Id(A,a,a)）
```

外加一条**导出引入规则**：`a = b ∈ A ⟹ id(a) ∈ Id(A,a,b)`
——判断相等总能升级为命题相等（反之不然，见 29.3）。消去
规则——**J 规则**（书中记作 idpeel）：

```text
Id-消去    a,b ∈ A,  c ∈ Id(A,a,b),
           C(x,y,z) set[x,y∈A, z∈Id(A,x,y)],
           d(x) ∈ C(x,x,id(x))[x∈A]
           ⟹ idpeel(c,d) ∈ C(a,b,c)
Id-相等性  idpeel(id(a),d) = d(a) ∈ C(a,a,id(a))
```

直觉：要构造「对一切 y、一切 a=y 的证据 e，C(y,e) 的元素」，
只需处理 **y 恰好是 a、e 恰好是 refl** 的情形——其余情形由
idpeel 代劳。三家文件各自把这个最小实现造了一遍：

```lean
inductive MyEq {α : Sort u} (a : α) : α → Sort (max 1 u) where
  | refl : MyEq a a

def myJ {α : Sort u} {a : α}
    (P : ∀ x, MyEq a x → Sort v) (h : P a MyEq.refl)
    {y : α} (e : MyEq a y) : P y e :=
  match e with
  | .refl => h
```
```agda
sym' : ∀ {A : Set} {a b : A} → a ≡ b → b ≡ a
sym' refl = refl        -- 对 refl 的模式匹配 == 应用 J
```

Agda 的表达最赤裸：**J 没有独立语法，模式匹配 refl 就是 J**。

## 29.2 四件套手推实录（书 8.1 三例的现代对照）

书里用 idpeel 直接给出三个导出规则，每条都附**精确的构造
项**——这是「消去子直用」的最佳示范：

```text
对称    symm(d)  ≜ idpeel(d, id)
        （族取 C(x,y,z) = Id(A,y,x)，基例 d(x) = id(x)）
传递    trans(d,e) ≜ apply(idpeel(d, (x)λy.y), e)
        （族取 C(x,y,z) = Id(A,y,c) → Id(A,x,c)，基例恒等）
替代    subst(c,p) ≜ apply(idpeel(c, (x)λx.x), p)
        （族取 C(x,y,z) = P(x) → P(y)，基例恒等）
```

对照三家机器件的四件套表：

| 定理 | J 的动机（族）选法 | 基础情形 |
|---|---|---|
| `sym : a=b → b=a` | `P x _ := x = a` | `refl` |
| `trans : a=b → b=c → a=c` | 归纳第二条：`P x _ := a=b → a=x` | 恒等函数 |
| `cong f : a=b → fa=fb` | `P x _ := f a = f x` | `refl` |
| `transport : a=b → P a → P b` | `P x _ := P x`（本体） | 给定的 `P a` |

Coq 版用 `eq_ind` 直接拼，Lean 版手写 `myJ` 后照表实现，
Agda 版每个两行。**同一张表，三种拼法**——「消去子够用」的
第一手体验。书的第四例（条件表达式的相等性）值得补做：

```agda
if-const : {A : Set} (b : Bool) (c : A) → if b then c else c ≡ c
if-const true  c = refl
if-const false c = refl
```

——对 b 分情形后两侧都折叠到 c，`refl` 收官。命题等式的
证明 = case 分析 + 定义相等核对，这正是书里证明
`Id(A, if b then c else c, c)` 非空的两步（Bool-相等性规则
给出判断相等，再 Id-引入升格）。

## 29.3 Eq：外延相等与「可判定性」的失守

书 8.2 引入第二个相等集合 **Eq(A,a,b)**（外延相等，来自
Martin-Löf 1979/1982 版 [69,70]）。三处与 Id 不同：

```text
Eq-引入     a = b ∈ A ⟹ eq ∈ Eq(A,a,b)     （eq 是相关度 0 的
                                            常元，不依赖 a！）
强 Eq-消去  c ∈ Eq(A,a,b) ⟹ a = b ∈ A      （命题 → 判断的反转！）
Eq-消去 2   c ∈ Eq(A,a,b) ⟹ c = eq ∈ Eq(A,a,b)   （证明唯一）
```

**强消去是全书唯一不成「结构归纳」形状的消去规则**：它把
命题层的证据直接兑换成判断层的等式。代价立刻显形（书 8.2
末的元理论注记）：

- **没有 Eq 时**：若 `a = b ∈ A` 可导（空前提），则 a 与 b
  可转换（对推导长度归纳可证——把计算规则看作组合逻辑的
  化归规则）；同理 `c ∈ Id(A,a,b)` 可导 ⟹ a、b 可转换。这
  就是「Id 称为**内涵的**」的原因：它的证据不带来超出计算
  的信息。
- **有 Eq 时**：判断相等不再可判定——可以先用归纳证明
  `Eq(A,a(x),b(x))[x∈N]`，再用强消去得到 `a(x) = b(x) ∈ A`。
  **命题层的推理渗入判断层**，定义相等性变成证明搜索。

书的态度是工程式的：Eq「仅在良序和一般树几章必须用，有
可能的话就避免」。这条路线分叉在版本史上反复出现（34 章）：
1979 版（Nuprl 同源）以 Eq 为纲、类型检查不可判定；本书主体
与 Agda/Coq 一道选择 Id、保住可判定性。8.2 还证明 Eq 的
Id 形归纳规则可由两条消去推出——两套相等的外延对照件。

## 29.4 η 的地位：可证的命题、非判断

书 8.3 处理一个微妙问题：**判断层没有 η 规则**——表达式
`λ((x)apply(f,x))` 与 `f` 不定义相等。但对应**命题**可以证：

```text
funsplit(f, (y)id(λ(y))) ∈ Id(Π(A,B), λ((x)apply(f,x)), f)  [f∈Π(A,B)]
```

推导用 Π-消去 2（funsplt）对 f 的典则形分派：典则形 λ(y)
处两侧 β-折叠相同，Id-引入收尾。**η 是可证命题、不是判断
等式**——这个精确表述是「内涵 vs 外延」的分水岭：把 η
升格为判断规则（或更强地加 funext），就走上了外延道路。

三家的现代化选择在这里分道（件里的三个实验）：

- **Agda**：defeq **含 η**——`η-defeq : f ≡ (λ x → f x)` 用
  `refl` 直接过；
- **Lean 4**：defeq 同样含 η——`rfl` 直接过；
- **Coq**：defeq **不含 η**——命题层同样要公理（件内实验
  `Print Assumptions` 见证依赖）：

Lean 与 Coq 的件内实验各两行：

```lean
example (f : Nat → Nat) : (fun x => f x) = f := rfl   -- 直接过
```
```coq
Definition eta_prop (f : nat -> nat) : (fun x => f x) = f.
Proof. apply functional_extensionality. reflexivity. Qed.
Print Assumptions eta_prop.   (* 依赖 functional_extensionality *)
```

书里的多型系统站在 Coq 一边（判断层无 η），但 η 作为命题
可证——比 Coq 更强一点（Coq 里该命题也要公理）。原因：书
的 funsplit 是结构归纳原理版消去子，η 的推导正是 funsplit
的一次应用；Coq 的 match 不提供这一步。

同一条边界线还站着 **K 规则**（refl 的唯一性）与
**UIP**（证明唯一）。Agda 的 `--without-K`、Coq 的
`Program.Equality` 世界、Lean 的 `Eq`——各家对这条线的处理
是 63 章以后（HoTT）的主线剧情。本章先把边界画清楚。

## 29.5 定义相等的方向（方向学三连的收官）

`transport` 是「命题相等 → 定义结构搬运」的官方通道。
19 章的 `Vec α (n+1)`、01 章的 `n+0` 方向学，在这里汇合成
一个动作：**当类型检查器拒绝免费折叠时，造一条等式再
transport**。Lean 文件的实测：

```lean
example (h : MyEq (1 + 1) 2) (v : Vec Nat 2) : Vec Nat (1 + 1) :=
  myTransport (Vec Nat) (mySymm h) v
```

（`1+1` 在 Lean 定义折叠为 2，所以这里 refl 就有；换成
`n+0` 方向就必须走归纳引理——同一台 transport 机器。）

Eq 的 Id 形归纳规则（8.2 末的推导）也值得留档：由
强消去得 a=b∈A、由替代得 d(a)∈C(a,a,eq)、再由 Eq-消去 2
（c=eq）与替代搬进 C(a,b,c)——**两步替代一步强消去**，恰好
是 Id-消去规则的形状。这说明 Id 的 J 与 Eq 的「强消去+唯一
性」互为镜像：外延论者把「反转为判断」当第一性、内涵论者
把「归纳原理」当第一性。

现代三家的 Id 家族对照（件内全部可验证）：Coq 的 `eq`
即 Id（J 是 eq_ind）；Lean 的 `Eq` 同构但 defeq 含 η 与
proof irrelevance 的 Sort 分层；Agda 的 `_≡_` 最贴书——
`--without-K` 旗标正是「Id 的证据可能有高维结构」的开关
（67 章起 cubical 线的主场）。K/UIP 的开关史：Coq 内建 UIP
（可推导）、Lean 的 Eq UIP 成立（Quot 之下）、Agda 默认允许
K、cubical 禁 K——同一 Id 规则、四种工程立场。

> **坑位速记**
> ① Lean 自造等式类型要用 `Sort (max 1 u)`——裸 `Sort u`
>   在 u=0 时撞「宇宙多态结果类型不能是 Prop」的墙；
> ② Lean 的 `rw` 看不见 **iota 折叠之下**的子项——`add (s n) m`
>   里的 `add n m` 要 `simp only [add]` 先暴露（30 章三连踩）；
> ③ Agda 的 `inductive`/`coinductive` 是保留字，**模块名里
>   连 `_inductive` 后缀都不许出现**（实测 `foo_inductive` 都
>   报 InvalidFileName）——目录/文件命名要避开；
> ④ funext 在三家都不是 J 的推论：Lean 靠 Quot.sound（定理）、
>   Coq 可选公理、Agda 要么公理要么换路线；
> ⑤ η 的 defeq 三家两票一票：Agda/Lean 判 `f ≡ λx→f x` 成立
>   （refl/rfl 直接过）、Coq 不判（命题层也要公理）——书的多
>   型系统判**命题层可证**（funsplt 推导），恰在两者之间。

---

上一章：[28 Π 与枚举](28-enums.md) · 下一章：[30 归纳族](30-indfam.md)
