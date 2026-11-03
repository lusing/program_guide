# 10 积与余积

> 对书：贺伟《范畴论》2.3（积和余积）/《高级范畴论》3.2 /
> Simmons 2.5（Products and coproducts）。
> 代码：`examples/10_products/`。

## 10.1 泛性质：存在 + 唯一

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

## 10.2 TyCat 里积 = 笛卡尔积

中介函数逐点造：`h x = (f x, g x)`。唯一性在三家的分岔很有趣：

| | 满配对的机器形态 |
|---|---|
| Coq | `destruct (h' x)` + `assert ... by exact (f_equal ...)` 逐点提取 |
| Agda | Σ 的 η 是**定义性的**——`h' x ≡ (proj₁ (h' x), proj₂ (h' x))` 免拆 |
| Lean | 结构 η：`rw [← hx1, ← hx2]` 后 `(p.1, p.2) = p` 是 rfl |

三家都只用 funext（点级 → 函数级）。

## 10.3 旗舰：积唯一到同构

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

## 10.4 「乘法表」的范畴语义

- 贺伟 2.3 用积讲群作用的「坐标乘法」；Simmons 2.5 的习题矩阵
  （Pfn 里的积 = 部分函数图对）留给读者；
- 积在 FinCat = 基数相乘（fin (m×n) ≅ fin m × fin n）——
  可作练习（机器化需要基数同构，超出本章范围）；
- 10 章的 IsProduct 在 15 章被 Hom 函子「免费吃掉」、
  在 18 章被右伴随「免费吃掉」——**泛性质是可以搬运的结构**。

## 10.5 余积的化身与积的乘法表（Simmons 2.5）

**Set 的余积 = 不交并**。机器版（三语言同构）：

```coq
Definition sumCop (A B : Set) : IsCoproduct catTy A B (sum A B)
  (inl (A:=A)) (inr (A:=B)).
Proof.
  intros c f g. exists (fun x => match x with
                               | inl a => g a | inr b => f b end).
  (* 两条腿 rfl；唯一性按 sum 分派即定 *)
```

注意腿的方向：余积的中介**从** sum 出发（对偶于积的中介**到**
乘积去）。`Set` 之外的清点：**Grp 的余积 = 自由积**（不交换！）、
**Ab 的余积 = 直和**、**Top 的余积 = 不交并拓扑**、**Pos 的
余积 = 不交并序**——「余积比积野蛮」是结构集范畴的普遍规律：
积可以逐点装修（13 章），余积往往要造自由结构。

**乘法表**：积的泛性质立即给出典范同构（全部零公理，唯一性
当武器，与 10.3 旗舰同一招式）：

| 同构 | 内容 |
|---|---|
| `A×B ≅ B×A` | 交换律（swap 中介） |
| `(A×B)×C ≅ A×(B×C)` | 结合律 |
| `A×1 ≅ A` | 单位（1 是终对象） |

同理余积有 `A+B ≅ B+A`、`(A+B)+C ≅ A+(B+C)`、`A+0 ≅ A`。
**代数的公理在范畴里降级为典范同构**——「同构」是范畴论正确
的「相等」粒度，这组表是第一次系统演练。书的 2.5 还有两个
提醒：**无穷乘积**（∏ 全体指标）与**空积**（= 终对象 1）；
**选择函数**（selection）只是投影的别名，但「每个元素恰被
某条投影选中」的直觉对理解泛性质很有用。

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

上一章：[09 逗号范畴：切片、箭头范畴与万有箭头的老家](09-comma.md) · 下一章：[11 等化子与拉回](11-pullbacks.md)
