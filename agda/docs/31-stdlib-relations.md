# 31 · stdlib 关系产业：Definitions / Structures / Bundles / Construct

14 章的推理链、18 章的抽象代数、27 章的关系读取——都挂在 `Relation.Binary`
这片土地上。这一章把"关系"本身当产业拆：`Definitions` 给你一阶性质，
`Structures` 把它们封装成 `IsPreorder`/`IsPartialOrder`/`IsEquivalence`，
`Bundles` 再带上 `Carrier` 变成 `Preorder`/`Poset`/`DecTotalOrder` 整包，
而 `Construct` 教你**不用手搓也能转换关系族**（严格序 ↔ 非严格序）。照样
先查源码，行号均实测于 `/Volumes/mac004/lang/agda-stdlib/src`。

对应示例：`../examples/Ex31_stdlib-relations.agda`

## 31.1 Definitions：关系的"零件性质"

`Relation/Binary/Definitions.agda` 放性质别名，实测行号：

```text
41:Reflexive  : Rel A ℓ → Set _
42:Reflexive _∼_ = ∀ {x} → x ∼ x
51:Symmetric  : Rel A ℓ → Set _
52:Symmetric _∼_ = Sym _∼_ _∼_
72:Transitive : Rel A ℓ → Set _
73:Transitive _∼_ = Trans _∼_ _∼_ _∼_
82:Antisymmetric : Rel A ℓ₁ → Rel A ℓ₂ → Set _
83:Antisymmetric _≈_ _≤_ = Antisym _≤_ _≤_ _≈_
87:Irreflexive : REL A B ℓ₁ → REL A B ℓ₂ → Set _
88:Irreflexive _≈_ _<_ = ∀ {x y} → x ≈ y → ¬ (x < y)
119:Trichotomous : Rel A ℓ₁ → Rel A ℓ₂ → Set _
235:_Respects₂_ : Rel A ℓ₁ → Rel A ℓ₂ → Set _
```

注意 `_Respects₂_` 在 **3.0 左右分量对调**了（`CHANGELOG.md` 3.0 高亮第 112–117
行）——网上旧教程写的 `x respects₂ y` 方向若照搬会 `Type mismatch`，这是升级
实踩的一个隐蔽坑。

## 31.2 Structures：把零件拼成 `IsXxx`

`Relation/Binary/Structures.agda`，模块参数是 `{a ℓ} {A} (_≈_ : Rel A ℓ)`。
实测记录与字段：

| 记录 | 行号 | 字段 |
|---|---|---|
| `IsEquivalence` | 48 | `refl` / `sym` / `trans` |
| `IsDecEquivalence` | 64 | `isEquivalence` + `_≈?_`（3.0 起，旧字段名 `_≟_` 保留为 `_≈?_` 的别名） |
| `IsPreorder` | 82 | `isEquivalence`（对 `_≈_`）/ `reflexive`（`_≈_ ⇒ _≲_`）/ `trans` |
| `IsPartialOrder` | 155 | `isPreorder` + `antisym`（`Antisymmetric _≈_ _≤_`） |
| `IsStrictPartialOrder` | 191 | `isEquivalence` / `irrefl` / `trans` / `<-resp-≈` |
| `IsTotalOrder` | 239 | `isPartialOrder` + `total` |
| `IsDecTotalOrder` | 253 | `isTotalOrder` + `_≈?_` + `_≤?_` |
| `IsStrictTotalOrder` | 281 | `isStrictPartialOrder` + `compare : Trichotomous _≈_ _<_` |

**嵌套是关键心智**：`IsPartialOrder` 的 `isPreorder` 字段里再嵌一个
`IsPreorder`，`IsPreorder` 里又嵌 `IsEquivalence`。给一个关系配"它是偏序"的
证据，就是层层往下填这棵记录树。3.0 里 `Transitive`/`Antisym` 的**隐式绑定名
修正**过（`CHANGELOG.md` 第 119–122 行），改名字段名报错时去追 `Renaming`。

## 31.3 Bundles：整包带上 Carrier

`Relation/Binary/Bundles.agda` 实测记录：`Setoid`(40)、`DecSetoid`(59)、
`Preorder`(81)、`Poset`(166)、`DecPoset`(195)、`StrictPartialOrder`(223)、
`TotalOrder`(285)、`DecTotalOrder`(310)、`StrictTotalOrder`(345)
`DenseLinearOrder`(375)、`ApartnessRelation`(399)。

示例（`Poset`，第 166 行）：字段 `Carrier` / `_≈_` / `_≤_` / `isPartialOrder`。
`Data.Nat.Properties` 已有现货：

```text
≤-poset : Poset _ _ _          -- 具体是个偏序整包
≤-decTotalOrder : DecTotalOrder _ _ _   -- 判定版，27 章 Ex27 件 8 用过
```

## 31.4 Construct：关系之间的"变形金刚"

`Relation/Binary/Construct/StrictToNonStrict.agda` 让你从严格序自动长出非
严格序：

实测：

```text
40:_≤_ : Rel A _
41:x ≤ y = (x < y) ⊎ (x ≈ y)
131:isPartialOrder : IsStrictPartialOrder _≈_ _<_ → IsPartialOrder _≈_ _≤_
138:isTotalOrder : IsStrictTotalOrder _≈_ _<_ → IsTotalOrder _≈_ _≤_
145:isDecTotalOrder : IsStrictTotalOrder _≈_ _<_ → IsDecTotalOrder _≈_ _≤_
```

"小于或相等"这个直觉，库作者用 `(x < y) ⊎ (x ≈ y)` 一个字不差地定义了，并且
把整棵 Structure/Bundle 树**免费送**给你——你只要给出严格序，非严格序的
`IsTotalOrder`/`IsDecTotalOrder` 全都推导出来。写高频关系时这种 transform
省掉一整个镜像族。

## 31.5 Reasoning 怎么挂到这些关系上

每个 bundle 都有配套 reasoning 模块（同级 `Relation/Binary/Reasoning/`）：
`Setoid`、`Preorder`、`PartialOrder`、`StrictPartialOrder`、`PartialSetoid`、
`MultiSetoid`、`Apartness`。打开方式（示例）：

```agda
open import Relation.Binary.Reasoning.PartialOrder ≤-poset using (begin_; _≤⟨_⟩_; _∎)
```

`PartialOrder.Reasoning` 底下是 `Base.Triple`（≡/≤/< 三轨），所以你能在一
条链里混 `≡⟨ ⟩` 与 `≤⟨ ⟩`——这正是 14 章结尾预告的"多轨推理"的工业实现。

## 坑位清单

1. **`_Respects₂_` 3.0 左右对调**：旧方向照抄会 `Type mismatch`，认准新字段
   顺序（`_≤_ Respects₂ _≈_`）。
2. **`IsDecEquivalence` 的判定字段 3.0 改叫 `_≈?_`**：`_≟_` 保留但废弃。
3. **`IsStrictTotalOrder` 不必手填 `_≈?_`/`_<?_`**：给 `compare : Trichotomous
   _≈_ _<_` 即可派生（Structures 第 281–297 行）。
4. **嵌套记录不能省**：`IsPartialOrder` 必须要 `IsPreorder`，`IsPreorder` 要
   `IsEquivalence`——"我只要偏序"的手感会漏掉底层等价结构，报错会一路拖到
   `refl` 找不到。
5. **`Transitive`/`Antisym` 隐式绑定名 3.0 修过**：用旧字段名解构会出现
   `did you mean`，去 `CHANGELOG.md` 看 `Renaming`。

---
上一章：[30 · stdlib 判定性体系](30-stdlib-decidable.md) ｜ 下一章：[32 · stdlib 函数论与类型运算](32-stdlib-functions.md) ｜ 返回：[README](../README.md)