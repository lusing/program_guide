# 12 相等类型与 J：内涵相等的手工课

> 对应读本：Nordström 第 8 章（相等性集合：内涵与外延）。
> 代码：`examples/12_identity/`——三家各自**从零手推**等式的
> 四件套（sym / trans / cong / transport），全部只依赖 refl 与 J。

## 12.1 Id 类型：refl 加一条规则

Nordström 第 8 章给出相等集合 `Id(A, a, b)`——现代写法
`a = b`（Agda 里 `a ≡ b`）。构造子只有一个：

```text
refl : Id(A, a, a)
```

消去规则——**J 规则**（也叫「基于 refl 的归纳」或 path induction）：

```text
P : (x:A) → Id(a,x) → Set      p : P(a, refl)
───────────────────────────────────────────────
J : (y:A) → (e : Id(a,y)) → P(y, e)
```

直觉：要证明「对一切 y、一切 a=y 的证据 e，P(y,e) 成立」，
只需处理 **y 恰好是 a、e 恰好是 refl** 的情形——其余情形
由 J 代劳。

三家文件各自把这个最小实现造了一遍：

```lean
inductive MyEq {α : Sort u} (a : α) : α → Sort (max 1 u) where
  | refl : MyEq a a

def myJ {α : Sort u} {a : α}
    (P : ∀ x, MyEq a x → Sort v) (h : P a MyEq.refl)
    {y : α} (e : MyEq a y) : P y e :=
  match e with
  | .refl => h
```

```coq
Print eq.       (* Inductive eq (A:Type) (x:A) : A -> Prop := eq_refl : x = x *)
Print eq_ind.   (* ……J 的 Coq 原生形态 *)
```

```agda
sym' : ∀ {A : Set} {a b : A} → a ≡ b → b ≡ a
sym' refl = refl        -- 对 refl 的模式匹配 == 应用 J
```

Agda 的表达最赤裸：**J 没有独立语法，模式匹配 refl 就是 J**。

## 12.2 四件套手推实录

用 J 造等式的经典动作（三家文件逐条机器验证）：

| 定理 | J 的动机（族）选法 | 基础情形 |
|---|---|---|
| `sym : a=b → b=a` | `P x _ := x = a` | `refl` |
| `trans : a=b → b=c → a=c` | 归纳第二条：`P x _ := a=b → a=x` | 恒等函数 |
| `cong f : a=b → fa=fb` | `P x _ := f a = f x` | `refl` |
| `transport : a=b → P a → P b` | `P x _ := P x`（本体） | 给定的 `P a` |

Coq 版用 `eq_ind` 直接拼（`apply (eq_ind x (fun z => z = x) eq_refl y H)`），
Lean 版手写 `myJ` 后照表实现，Agda 版每个两行。**同一张表，
三种拼法**——这是「消去子够用」的第一手体验。

## 12.3 内涵 vs 外延：J 的能力边界

Nordström 8.2 讨论外延相等。关键的元事实：**函数外延性
（funext）不可由 J 推出**——`∀x, f x = g x` 推不出 `f = g`。
J 的模式匹配只认 refl，而 `f ≡ g` 不是定义相等。三家实测：

- **Lean**：`funext` 是核心定理，但 `#print axioms funext`
  显示它依赖 `[propext, Quot.sound]`——**不是 J 推的**；
- **Coq**：`Require FunctionalExtensionality` 后
  `Print Assumptions funext_demo` 显示依赖
  `functional_extensionality` 公理；
- **Agda**：内涵理论里同样不可证（文件里留了不可写的洞），
  出路是公理或同伦路线。

同一条边界线还站着 **K 规则**（refl 的唯一性）与
**UIP**（证明唯一）。Agda 的 `--without-K`、Coq 的
`Program.Equality` 世界、Lean 的 `Eq`——各家对这条线的处理
是 19 章以后（HoTT）的主线剧情。本章先把边界画清楚。

## 12.4 定义相等的方向（方向学三连的收官）

`transport` 是「命题相等 → 定义结构搬运」的官方通道。
07 章的 `Vec α (n+1)`、01 章的 `n+0` 方向学，在这里汇合成
一个动作：**当类型检查器拒绝免费折叠时，造一条等式再 transport**。
Lean 文件的实测：

```lean
example (h : MyEq (1 + 1) 2) (v : Vec Nat 2) : Vec Nat (1 + 1) :=
  myTransport (Vec Nat) (mySymm h) v
```

（`1+1` 在 Lean 定义折叠为 2，所以这里 refl 就有；换成
`n+0` 方向就必须走归纳引理——同一台 transport 机器。）

> **坑位速记**
> ① Lean 自造等式类型要用 `Sort (max 1 u)`——裸 `Sort u`
> 在 u=0 时撞「宇宙多态结果类型不能是 Prop」的墙；
> ② Lean 的 `rw` 看不见 **iota 折叠之下**的子项——`add (s n) m`
> 里的 `add n m` 要 `simp only [add]` 先暴露（13 章三连踩）；
> ③ Agda 的 `inductive`/`coinductive` 是保留字，**模块名里
> 连 `_inductive` 后缀都不许出现**（实测 `foo_inductive` 都
> 报 InvalidFileName）——目录/文件命名要避开；
> ④ funext 在三家都不是 J 的推论：Lean 靠 Quot.sound（定理）、
> Coq 可选公理、Agda 要么公理要么换路线。

---

上一章：[11 Π 与枚举](11-enums.md) · 下一章：[13 归纳族](13-indfam.md)
