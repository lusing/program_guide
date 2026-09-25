# 32 · stdlib 函数论与类型运算

17 章用 `_↔_` 讲同构。这一章把 `Function` 整片当成"函数本身的理论"掀开：
`Function.Base` 的组合子工具箱、`Function.Bundles` 的 `Func`/`Injection`/
`Inverse`/`Bijection` 整包、`Function.Related` 的蕴含阶梯，以及外延公理到底
住哪。**重点纠一个版本错位**：网上很多教程写 `Function.Extensionality`，在
3.0 里这个模块**不存在**，外延公理在 `Axiom.Extensionality.Propositional`。
行号均实测于 `/Volumes/mac004/lang/agda-stdlib/src`。

对应示例：`../examples/Ex32_stdlib-functions.agda`

## 32.1 Function.Base：组合子工具箱

`Function/Base.agda` 实测一组你几乎每次都会用到的组合子：

```text
29:id : A → A
32:const : A → B → A
77:_$_ : ((x : A) → B x) → ((x : A) → B x)      -- 应用
93:_ˢ_   -- S 组合子：f ˢ g = λ x → f x (g x)
138:_∘′_ : (B → C) → (A → B) → (A → C)          -- 非依赖组合
249:_on_ : (B → B → C) → (A → B) → (A → A → C)  -- 双参数"都先经过去"：compare on price
```

`_∘_` 是真依赖组合（往后你在依赖场景几乎离不开它）：

```text
52:_∘_ : ∀ {A : Set a} {B : A → Set b} {C : {x : A} → B x → Set c}
53:     → (∀ {x} (y : B x) → C y) → (g : (x : A) → B x) → ((x : A) → C (g x))
```

`Function.Base` 里特别提两个容器约定：`_∋_`（`A ∋ a = a`）和 `it`（typeclass
式实例），它们是"临时给类型名让位"和"看名字找实例"的惯用法。

## 32.2 Function.Bundles：函数当作对象（record）

`Function/Bundles.agda` 把"是一个同构/单射/满射"定义成**记录**。实测：

| 记录 | 行号 | 字段 |
|---|---|---|
| `Func` | 54 | `to` + `cong`（`Congruent`） |
| `Injection` | 70 | `to` + `cong` + `injective` |
| `Surjection` | 92 | `to` + `cong` + `surjective` |
| `Bijection` | 136 | `to` + `cong` + `bijective` |
| `Equivalence` | 192 | `to`/`from`/`to-cong`/`from-cong` |
| `Inverse` | 315 | `to`/`from`/`to-cong`/`from-cong`/`inverse` |

带 `≡.setoid` 的特化记号（第 460–486 行）：

```text
_⟶_ : Set a → Set b → Set _      -- 全函数
_↠_ : Set a → Set b → Set _      -- 满射 Surjection
_⇔_ : Set a → Set b → Set _      -- Equivalence
_↔_ : Set a → Set b → Set _      -- Inverse（同构）
```

`mk↔`（第 559 行）构造一个 `_↔_`。

**关键教训**：`Equivalence` 和 `Inverse` 字段**都**有 `to`/`from`，但
`Inverse` 多一个 `inverse`——这是"双向映照"，`Equivalence` 只是"互寄且
都尊重等式"。别拿 `_↔_` 当 `_⇔_`，更别把 `_⇔_` 当等价类。

## 32.3 Function.Related：蕴含阶梯

`Function/Related.agda` 标 v2.0 弃用，**用 `Function.Related.Propositional`**
（实测 `Kind` 与 `_∼[_]_` 在那个模块第 38–68 行）。`Kind` 是一串梯级：

```text
implication / reverseImplication / equivalence / injection / reverseInjection /
leftInverse / surjection / bijection
```

`_∼[ k ]_ : Set a → Kind → Set b → Set _` 把每个 kind 对应到上面某个 bundle：

```text
A ∼[ equivalence ] B = A ⇔ B
A ∼[ surjection   ] B = A ↠ B
A ∼[ bijection    ] B = A ↔ B
```

一句话：`A ∼[ bijection ] B` 就是 `A ↔ B`。**阶梯的意义**：你可以在文档里表达
"这两类型之间至少有某种强度以上的关系"，而且 `Kind` 之间有蕴含序——存在
`bijection` 就蕴含存在 `equivalence`。写"类型等价强度谱"时这是现成刻度。

## 32.4 外延公理：住在 Axiom，不在 Function

网上教程常说 `Function.Extensionality.funext`。**3.0 没有 `Function.
Extensionality` 这个模块**（实测 `find` 零命中）。外延公理原子在：

```text
Axiom/Extensionality/Propositional.agda
Axiom/Extensionality/Heterogeneous.agda
```

```agda
open import Axiom.Extensionality.Propositional using (Extensionality)
funext : Extensionality _ _
```

`Extensionality a b` 就是"逐点相等 → 函数相等"的公理类型。它是**可选公理**
（import 即声明你接受它、放弃某种计算性），跟 22/24 章的 cubical 是两条路。
需要用就直连 `Axiom` 树，别在 `Function` 下找。

## 坑位清单

1. **`_∘_` 是依赖组合**，`_∘′_` 才是简单版：非依赖场合混用会得到更强的签名，
   报错难读；是依赖场景才敢用 `_∘_`。
2. **`_↔_` 是 `Inverse`，`_⇔_` 是 `Equivalence`**，字段差一个 `inverse`；拿
   `_↔_` 当 `_⇔_` 类型不匹配。
3. **`Function.Extensionality` 不存在**：外延公理在 `Axiom.Extensionality.*`，
   找错模块是 3.0 升级最常见的 `No such module` 之一。
4. **`Function.Related` 弃用**：新代码 `open import Function.Related.Propositional`。
5. **`Surjection.to⁻` 3.0 弃用**（`Function/Bundles.agda` 第 123–133 行标注），
   改 `Function.Structures.IsSurjection.from`。
6. **`_↝[_]_` 的 kind 与 bundle 一一对应**，引用文档时别把 `bijection` 写成
   `equivalence`——那是"至少"关系，不是同值。

---
上一章：[31 · stdlib 关系产业](31-stdlib-relations.md) ｜ 下一章：[33 · stdlib 数据结构系统](33-stdlib-data.md) ｜ 返回：[README](../README.md)