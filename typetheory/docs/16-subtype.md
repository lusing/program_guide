# 16 子集类型与强制子类型

> 对应读本：Nordström 第二部分第 17–18 章（子集合理论）；
> 《现代类型论的发展与应用》2.5（包含式/强制性子类型）。
> 代码：`examples/16_subtype/`——子集类型三家同构 +
> Coercion/Coe/函数 三种强制观。

## 16.1 子集类型：证据随值走

Nordström 第二部分问：MLTT 全是「全函数」，怎么表达**部分性**
（只对正数有定义的除法、只对非空表有意义的 head）？答案：
**子集类型**——值与证据打包：

```text
{ x : A | P x }  =  Σ(x : A). P x 的命题版
```

三家写法：

```lean
def Pos : Type := {n : Nat // n > 0}
def three : {n : Nat // n > 0} := ⟨3, by omega⟩
def safeDiv (n : Nat) (d : {d : Nat // d > 0}) : Nat := n / d.val
```
```coq
Definition Pos : Type := {n : nat | n > 0}.
Definition pone : Pos.  Proof. exists 1. lia. Defined.
```
```agda
PosSet = Σ[ n ∈ ℕ ] n > 0
one = 1 , s≤s z≤n
```

子集类型把「定义域约束」从文档搬进类型：`safeDiv` 的类型就是
它的前置条件——调用方必须出示 `d > 0` 的证据。反过来，
**前驱函数只能返回裸 Nat**（`pred 1 = 0` 不再正——子集类型
逼你正视定义域塌缩）：Lean 文件里 `posPred : Pos → Nat` 的
返回类型变化就是教学点。

## 16.2 extrinsic vs intrinsic：两种证明哲学

同一个「非空表」约束有两条实现路线：

| | 写法 | 约束在哪 | 代表 |
|---|---|---|---|
| **extrinsic** | `{l : List α // l.length > 0}` | 谓词（事后证明） | Coq/Lean 的 sig/Subtype 文化 |
| **intrinsic** | `Vec α (n+1)`（索引族） | 索引（语法即规格） | Agda 文化、07 章 |

二者表达力相当（可互译），工程取向不同：extrinsic 改动小
（换包装）、证明量大；intrinsic 类型即真相、改规格要动骨架。
「非法状态不可表示」在 intrinsic 下是语法事实，在 extrinsic
下是随身证据的检查。真实项目两者混用（Lean 的 Mathlib 里
`Subtype` 与 `Fin`/`Vec` 并存）。

## 16.3 强制子类型（Luo）：不是包含，是记法

《现代类型论的发展与应用》2.5 区分两条线：

1. **包含式子类型**（`A ⊆ B`）：改变语义——集合论的进路，
   类型论里问题成堆（与类型抽象、宇宙冲突）；
2. **强制子类型**（`A ⇒ B`，coercive subtyping，Luo 1999）：
   只是**缩写机制**——`c : A ⇒ B` 是一个函数，在需要 B 的地方
   看到 A 时自动插入，**展开后无痕**（不改变类型论本体）。

工程落点三家三态：

```coq
Record Boxed := mkBoxed { unbox : nat }.
Coercion unbox : Boxed >-> nat.
Compute boxed3 + 1.        (* 4：+ 的 nat 位自动解箱 *)
```
```lean
structure Boxed where unbox : Nat
instance : CoeOut Boxed Nat := ⟨Boxed.unbox⟩
#eval (boxed3 : Nat) + 1   -- ascription 触发 Coe
```
```agda
-- Agda：没有语言级强制。要「把 Boxed 当 ℕ 用」，手写 unbox。
_ = unbox boxed3 + 1
```

Coq 的 `Coercion` 最顺手（还能把记录字段注册成投影强制，
`Coercion px : Point3 >-> nat`）；Lean 的 Coe 家族挂在
instance 机制上、常要显式 ascription 触发；Agda 干脆不做
——「读到的就是写下的」，代价是啰嗦、收益是零隐式插入。

> **坑位速记**
> ① Coq 8.20 的 `ltac:(lia)` 在**项位置**系统性失灵
> （"Cannot find witness"）——子集类型的证据走证明模式
> （`Proof. exists 1. lia. Defined.`）；
> ② Lean 的 Σ（`(a : A) × B`）两分量必须是 **Type**——
> Prop 谓词要用 Subtype 记法 `{x // P x}`；
> ③ Lean 的 class 字段访问符带 instance 隐参——当普通函数
> 用（如塞进 CoeOut）时把 class 改 structure；
> ④ 子集类型上的「部分函数」要检查**值域还在子集里**：
> `pred : Pos → Pos` 对 1 处崩——要么改返回裸值，要么
> 换定义（succPos）；
> ⑤ Agda 里「重建证据比搬运证据省事」：模式匹配出
> `suc k` 后 `s≤s z≤n` 直接居留（2 * suc k 定义展开即
> suc 打头）。
