# 14 全域与类型层级

> 对应读本：Nordström 第 14 章（小集合之集合 U）+ Girard 悖论；
> 《现代类型论的发展与应用》2.4（类型空间）。
> 代码：`examples/14_universes/`——三家宇宙机制对照。

## 14.1 为什么要宇宙

「类型的类型」若是一个类型 `Type : Type`，Girard（1972）证明可以
在 System U 里复刻 Russell 悖论——系统不一致。解法是**层级塔**：

```text
Prop = Sort 0     Type 0 = Sort 1     Type 1 = Sort 2     …
Type u : Type (u+1)          ——只许上楼，不许自环
```

Nordström 第 14 章的「第一全域 U」是同一思想的直谓版：把小集合
（Π、Σ、枚举、ℕ…的封闭）收进一个类型 U，U 本身住上层。现代
三家把它做成语法内建：

| | 宇宙语法 | 事实速览 |
|---|---|---|
| Coq | `Set` / `Type@{i}` / `Prop` | `Set ⊂ Type`（有 Cumulativity） |
| Lean | `Sort u`，`Prop = Sort 0` | **无** Cumulativity，`ULift` 升层 |
| Agda | `Set ℓ` + `Level` 代数 | 无 Cumulativity，`Lift` 升层，`ℓ ⊔ m` 上确界 |

Lean/Agda 没有 Cumulativity 是**实测**出来的（本章文件）：

```lean
#check (Nat : Type 5)
-- Type mismatch: Nat has type Type ... expected Type 5
#check (ULift.{1, 0} Nat : Type 1)   -- 官方升层器才行
```

Coq 则一路绿灯：`Check (nat : Type).`（Set 自动进 Type）。

## 14.2 宇宙多态：一份代码全层复用

没有宇宙多态的话，`id : A → A` 要给每层写一份。三家的解法：

```lean
def myId.{u} {α : Sort u} (a : α) : α := a        -- Lean：隐式宇宙参数
```
```coq
Definition myId@{u} {A : Type@{u}} (a : A) : A := a.   -- Coq 8.20
```
```agda
myId : ∀ {ℓ} {A : Set ℓ} → A → A                   -- Agda：Level 参数
myId a = a
```

Agda 的 `Level` 是**代数**：双参数类型构造器住在
`Set (ℓ ⊔ m)`（上确界）——`Prod2` 一类的记录在文件里照此定型。
`Set₀` 上的东西要进 `Set₁`，用 `Lift`（Agda）/`ULift`（Lean）。

## 14.3 「类型 + 居留项」：宇宙账单的实践

装下「一个类型和它的一个元素」是最小的宇宙敏感结构：

```lean
structure TyAndTerm : Type 1 where
  A   : Type        -- A : Type 0 ⇒ 外层必须 Type 1
  val : A
def natEx : TyAndTerm := ⟨Nat, (3 : Nat)⟩
```

Coq 的 Record 同型；Agda 的版本必须显式 `Set₁`。**宇宙的实践
课**：自反结构（解释器、语法高阶抽象）天然吃层级；三家的
`Sort u`/`Type@{i}`/`Set ℓ` 都为此服务。

> **坑位速记**
> ① Lean 无 Cumulativity：`Nat : Type 5` 直接报错，升层用
> `ULift`；Agda 同理用 `Lift`——写跨层代码前先想清楚；
> ② Lean 匿名构造器里第二字段类型由第一字段定时，数字要
> 手工标注 `(3 : Nat)`（OfNat 对投影类型 `natEx.A` 失明）；
> ③ Agda `field x : A` 后接**缩进续行**会 ParseError——多字段
> 用块形式（`field` 独占一行）或分号；
> ④ Agda 的 `Level.suc`/`Data.Nat.suc` 同名——import 时
> `renaming (suc to lsuc)`，且 `using` 与 `renaming` 不能
> 同时圈住同一个名字；
> ⑤ Lean 的 doc 注释 `/-- -/` 挂在文件尾（后面无声明）会
> 让整个文件报 unexpected end of input。

---

上一章：[13 归纳族](13-indfam.md) · 下一章：[15 W 类型](15-wtypes.md)
