# 10 MLTT：判断形式与一般规则

> 对应读本：Nordström《Martin-Löf 类型论程序设计导论》第 3–5 章。
> 代码：`examples/10_judgments/`——三家把四种判断与四条一般规则
> 逐条机器化。

## 10.1 从表达式到判断

Martin-Löf 类型论（MLTT）不再区分「项的演算」与「规则的元语言」，
而是把一切放进**判断（judgment）**。Nordström 第 3 章先造表达式
（作用、抽象、组合、选取），第 4 章给出四种基本判断：

```text
A type            （A 是一个类型）
A ≡ B             （A 与 B 定义相等）
a : A             （a 是 A 的居留项）
a ≡ b : A         （A 中 a 与 b 定义相等）
```

「定义相等」（definitional equality / convertibility）是 MLTT 的
灵魂：它**不可证明、只可判定**——沿定义展开（β/δ/ι）比出相同
即得。三家机器里它是：

| | 判断 a ≡ b : A 的机器面 |
|---|---|
| Coq | `eq_refl` 能过 = 定义相等（`reflexivity` 战术探测） |
| Lean | `rfl` 能过 = 定义相等 |
| Agda | `refl` 能居留 = 定义相等 |

三家示例都演示了「定义相等 ≠ 命题相等」的界碑：`0 + n ≡ n` 是
定义（Coq/Agda 的加法递归侧），而 `n + 0 = n` 在 Coq/Agda 里
**需要归纳证明**；Lean 正相反（`n + 0` 折叠、`0 + n` 要证）——
01 章的方向学在这里兑现为完整定理。

## 10.2 一般规则：等式的公理动作

Nordström 第 5 章的「一般规则」对所有集合成立：

```text
前提        Γ, a:A ⊢ a : A            ——假设即上下文条目
对称        a = b ⊢ b = a
传递        a = b, b = c ⊢ a = c
替换/同余   a = b, P a ⊢ P b（= f a = f b 的总纲）
命题即集合  P a 是集合（判断资格的封闭）
```

三家的对应物一览（文件里逐条可跑）：

```lean
theorem symRule (a b : Nat) (h : a = b) : b = a := h.symm
theorem substRule (a b : Nat) (h : a = b) (P : Nat → Prop) (pa : P a) : P b := h ▸ pa
```
```coq
Theorem subst_rule : forall a b, a = b -> forall P, P a -> P b.
Proof. intros a b H P Ha. apply (eq_ind a P Ha b H). Qed.
```
```agda
subst-rule : ∀ {A : Set} (P : A → Set) {a b} → a ≡ b → P a → P b
subst-rule P refl pa = pa
```

注意 Agda 版的形态：**对 refl 做模式匹配就是应用 J 规则**——
第 12 章把这句话展开成一门手工课。

## 10.3 上下文：判断永远在语境里

`Γ ⊢ J` 的 Γ 在三家叫法不同但机制同构：Coq 的 `Section`/
`Context`、Lean 的局部假设与 `variable`（**用到才收**——本章
`inCtx` 定理里 `h` 必须写在语句里才进泛化，这是实测踩到的
第一课）、Agda 的 telescope（`(P : ℕ → Set) (n : ℕ) → ...`
的参数列本身就是 Γ）。

> **坑位速记**
> ① Lean `variable` 声明的假设若只在证明里用、不出现在语句，
> 泛化时被丢弃 → `h.symm` 变 unknown identifier——假设写进语句；
> ② Agda 顶层量词裸写 `∀ a b → ...` 会留未解元（a b 的类型是
> meta）——量词要带类型 `∀ (a b : ℕ) → ...`；
> ③ Lean 核心已占 `Empty`/`Unit`——自定义要换名（Empty2 等）；
> ④ Coq 无构造子的归纳默认落 Prop，**不能消去到 Type**——
> 空类型声明成 `Set`（`: Set := .`）才能当爆炸原理用。

---

# （附）本章与全书的地图

至此读者手里已有：λ 演算（02）、简单类型（03–05）、立方体
（06–08）、定义（09）与 MLTT 的判断框架（本章）。接下来按
Nordström 的次序进集合构造子：枚举（11）、等式（12）、归纳族
（13）、全域（14）、W 类型（15）、子集（16）——每一章都是
「Nordström 的形式规则 × 三家的日常语法」的对照阅读。

---

上一章：[09 定义 λD](09-definitions.md) · 下一章：[11 Π 与枚举](11-enums.md)
