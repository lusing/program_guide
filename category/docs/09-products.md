# 09 积与余积

> 对书：贺伟《范畴论》2.3（积和余积）/《高级范畴论》3.2 /
> Simmons 2.5（Products and coproducts）。
> 代码：`examples/09_products/`。

## 9.1 泛性质：存在 + 唯一

积不再是「有序对」，而是**带着泛性质的图表**：

```coq
Definition IsProduct (C : Category) (a b p : Obj C)
  (p1 : Hom C p a) (p2 : Hom C p b) : Type :=
  forall c (f : Hom C c a) (g : Hom C c b),
    { h : Hom C c p | comp C h p1 = f /\ comp C h p2 = g /\
        forall h' (e1 : comp C h' p1 = f) (e2 : comp C h' p2 = g), h' = h }.
```

读法：任何「双出」对象 c 恰好一条中介态射 h 使两三角交换。
「恰好」= 存在 + 唯一——两半都要。

余积一行对偶：`IsCoproduct C a b q i1 i2 := IsProduct (opposite C) b a q i2 i1`
——02 章的反范畴在这里开始批量生产定义（注意对象次序掉头）。

## 9.2 TyCat 里积 = 笛卡尔积

中介函数逐点造：`h x = (f x, g x)`。唯一性在三家的分岔很有趣：

| | 满配对的机器形态 |
|---|---|
| Coq | `destruct (h' x)` + `assert ... by exact (f_equal ...)` 逐点提取 |
| Agda | Σ 的 η 是**定义性的**——`h' x ≡ (proj₁ (h' x), proj₂ (h' x))` 免拆 |
| Lean | 结构 η：`rw [← hx1, ← hx2]` 后 `(p.1, p.2) = p` 是 rfl |

三家都只用 funext（点级 → 函数级）。

## 9.3 旗舰：积唯一到同构

**两个积之间有典范同构**——证明完全不看元素，只用唯一性：

```text
k : P→Q（把 P 的投影喂给 Q 的泛性质）
h : Q→P（对称）
k;h 与 id_P 都满足 P 自己的双出 → 唯一性逼 k;h = id_P
```

机器骨架（Coq 版 `product_unique_iso`，零公理）：
对每个泛性质「取样两次」——m/n 的存在性，再把 k;h 与 id
喂给同一个唯一性判据。**「泛性质自动给同构」的标准套路**，
后续章节（伴随的唯一性、极限的唯一性）反复重演。

Agda 版把同一证明写成 let-模式 + trans 链；Lean 版用
`obtain + congr` 结构化——三家的证明形状对照是本章练习的重点。

## 9.4 「乘法表」的范畴语义

- 贺伟 2.3 用积讲群作用的「坐标乘法」；Simmons 2.5 的习题矩阵
  （Pfn 里的积 = 部分函数图对）留给读者；
- 积在 FinCat = 基数相乘（fin (m×n) ≅ fin m × fin n）——
  可作练习（机器化需要基数同构，超出本章范围）；
- 09 章的 IsProduct 在 12 章被 Hom 函子「免费吃掉」、
  在 15 章被右伴随「免费吃掉」——**泛性质是可以搬运的结构**。

## 坑位速记

1. Coq 的 `*` 记号默认解析到 nat 乘法（nat_scope 打开）——
   类型位置写 `prod A B` 或进 type_scope；`(A * B) : Obj catTy`
   的注解救过 tyProduct 两次。
2. Coq sig 里带 IsoArrow（Type 值）要用 sigT（`{h : Hom P Q & ...}`）
   ——sig 只收 Prop。
3. Lean 的方程对用 `∧`（Prop）而非 `×`（Prod 是 Type 值）；
   Σ' 混居时外层也要 ∧。
4. Agda where 块不能用模式绑定——`k , (k1 , k2) , kuniq = ...`
   要搬进 let（let 支持模式）。
5. 「唯一性」子句是三参数量词（h' + 两条方程）——三家解构时
   注意嵌套层数。

---

上一章：[08 Yoneda 引理与可表函子](08-yoneda.md) · 下一章：[10 等化子与拉回](10-pullbacks.md)
