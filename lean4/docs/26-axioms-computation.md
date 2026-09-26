# 26 · 公理与计算

**对标**: *Theorem Proving in Lean 4* 第12章；*Reference* 第8章。

## 26.1 三大标准公理

Lean 的逻辑大厦只建立在三条公理上：`propext`（外延相等的命题可互换）、
`Classical.choice`（经典选择，排中律的来源）、`Quot.sound`（商类型Sound性）：

```lean
#check @Quot.sound
-- Quot.sound : ∀ {α : Sort u_1} {r : α → α → Prop}, (∀ (a b : α), r a b → Quot r a = Quot r b)
#check @propext
#check @Classical.choice

theorem emExample (p : Prop) : p ∨ ¬p := Classical.em p
#print axioms emExample
-- 'emExample' depends on axioms: [propext, Classical.choice, Quot.sound]
```

## 26.2 #print axioms：证明审计

`#print axioms` 列出一条定理传递依赖的全部公理——这是审计"有没有引入可疑假设"的最快手段。
结构性/计算性证明完全不依赖公理：

```lean
structure P where
  x : Nat

theorem etaEx (p : P) : P.mk p.x = p := rfl
#print axioms etaEx        -- 'etaEx' does not depend on any axioms
#print axioms Nat.add_comm -- 'Nat.add_comm' does not depend on any axioms
```

## 26.3 自定义 axiom：方便但危险

`axiom` 直接引入假设而不给证明。仅用于占位开发；正式代码里遗留的 axiom 会让"证明"失去意义：

```lean
axiom tutorialAssumption : ∀ (n : Nat), n ≥ 0
#print axioms tutorialAssumption
-- 'tutorialAssumption' depends on axioms: [tutorialAssumption]
```

## 26.4 可判定性与 decide

含 `Nat`/`Bool` 等可判定类型的命题可用 `rfl` 或 `decide` 逐字检查：

```lean
theorem twoPlusTwo : 2 + 2 = 4 := rfl
theorem sumTen : (List.range 10).sum = 45 := by decide
```

---

> 上一章：[25 · 依赖类型编程实战](25-dependent-types.md) ｜ 下一章：[27 · 强制转换、记法与宏](27-coe-notation-macros.md) ｜ 返回：[README](../README.md)
