# 45 范畴论：预范畴、Yoneda 与结构同一性

> 对应读本：HoTT 书第 9 章全部（预范畴与范畴、函子与变换、
> 伴随、范畴的等价、**Yoneda 引理**、严格范畴、†-范畴、
> **SIP 结构同一性原理**、Rezk 完备化）。代码：`examples/
> 45_category/ex45_category.agda`（cubical：PreCat/Iso/Functor/
> NatTrans 的机器定义、hom 合成的自然性样本、monoid 的
> 保结构映射——SIP 的第一代数实例）。

范畴论在集合论世界有个百年暗病：**「同构的对象」与「相等的
对象」是两回事**——一切「图表只在同构下有意义」的口头禅，
其实是被迫的（相等太死、同构太松）。HoTT 用泛等把这两半
焊回去：**好的范畴（饱和的）里 iso 就是 eq**——范畴论由此
获得「无 evil」的版本。

## 45.1 预范畴：hom 是集合（书 9.1）

机器定义（cubical 文件）：

```agda
record PreCat where
  field
    Ob     : Set
    Hom    : Ob → Ob → Set
    homSet : ∀ x y → isSet (Hom x y)    -- 关键限定
    idm, comp, assoc, idL, idR           -- 老三样
```

**homSet 是 HoTT 的第一道纪律**：不加它，「hom 里的高维路」
会污染一切图表（associator 的五边形会在高维晃动）。加了它，
hom 层是 0-截断的——1-范畴论的图表追踪合法。对比三家文化：
Lean/Coq 的 Category 类把 hom 放在 Type/Prop（UIP 世界，
homSet 自动），Agda stdlib 显式 isSet——HoTT 把它升为**定理
化的对象**（isSet 是结构而非预设）。

## 45.2 iso ≠ eq 的病理（书 9.1 后半）

预范畴里同构不等于相等：书 9.1 的反例（范畴的骨架错觉）说明
「同构的对象可以不等的证据」在任意 precategory 中**可构造**
（除非 ob 是 set 且 iso→eq——后者叫**饱和**/**范畴性**）。

> **定义**：precategory C 是 **category**（饱和），若
> idtoiso : (x ≡ y) → Iso x y 是等价。

「范畴 = 饱和的预范畴」不是挑剔：**Set 自身饱和**（泛等！
——函数的 iso 即类型的相等），而「人为构造的骨架范畴」常常
不饱和。范畴论的「好对象」在 HoTT 里是定理化的条件，不是
集合论的默认。

## 45.3 函子、自然变换与范畴的等价（书 9.2/9.4）

机器定义两件套（`Functor`/`NatTrans`——cubical 文件）：
F₀ 映对象、F₁ 映 hom、两条定律；η 逐点、自然性方块。注意
自然性方块在 hom-set 里是**唯一的**（homSet ⇒ isProp）——
「图表可换」在 1-范畴里无需担心换法。

**范畴的等价**（9.4）：F 是等价 ⟺ F₀「fully faithful 且
essentially surjective」（eso：每对象 merely 同构于像）——
经典定义照搬，但**证明它是等价**用的是 37 章的机械（biinv
或 contrFib）。范畴论的「等价」与类型论的「等价」在饱和
条件下重合——两层语义在此咬合。

## 45.4 Yoneda 引理（书 9.5）

一切范畴论的发电机：

> **Yoneda**：对任意 F : C^op → Set 与 c : C，
> Nat(hom(–, c), F) ≃ F c——自然变换与元素一一对应。

机器件给的是**胚**：hom 的合成自然性（`hom-naturality` 与
`post-comp-is-natural`）——「后合成是自然的」这一行正是
Yoneda 嵌入的构造核心。完整引理的 cubical 版需要预函子
范畴（函子间的 PreCat）与反范畴的装配——本仓库 coq-hott
教程与范畴论教程（本仓库姊妹篇）有 Coq/Agda/Lean 三家的
完整机器版，本指南以接口对照引用。**Yoneda 的类型论读法**
（41 章 5.8 的回收）：恒等族 (a₀ = –) 是 a₀ 处的自由表示
函子——Yoneda 引理即「路径归纳」的范畴化重述（书 5.8 的
原话），41 章与本章在此握手。

## 45.5 SIP：结构同一性原理（书 9.8）

数学的日常：「同构的群是同一个群」「同胚的空间不必区分」。
HoTT 把它变成定理（9.8.1 的推导骨架）：

1. **结构函子**：σ : Type → Type 把「裸类型」送到「带结构
   的类型」（Σ(B). 结构 B——36.7 的形态）；
2. **同构条件**：σ 的「同构映射」（保结构的双射）在泛等下
   与 σ 的「相等」互推；
3. **SIP 定理**：iso(σA, σB) ≃ eq(σA, σB)——**结构化类型
   的同构即相等**。

机器件的种子（cubical 文件）：`Mono`（幺半群结构）与 `Homo`
（保结构映射：hOp/hUnit 两律）——「monoid 的同构即 monoid
的相等」是 SIP 的第一个代数实例。推导的引擎是 38 章三段式
（造等价 → ua 成路 → transport 搬结构）+ 36.7 的 Σ 路径
分量式。**SIP 是泛等公理的「应用层总开关」**：从此「结构
同一」不再靠哲学，靠机器。

## 45.6 严格范畴、†-范畴与 Rezk 完备化（书 9.6/9.7/9.9）

三个补丁方向：

- **严格范畴**（9.6）：Ob 是 0-类型（set）的预范畴——「对象
  是集合」的经典化身。适合建模「已知的集合论范畴」（群、
  环……），但 Set 自身不严格（宇宙是群胚）——严格性是限制
  而非默认；
- **†-范畴**（9.7）：带 involution（† : C^op ≃ C）的范畴——
  Hilbert 空间与共轭线性映射的代数框架（书为量子力学预备）；
- **Rezk 完备化**（9.9）：**任何预范畴都可以完备化**为范畴
  （饱和化）——构造「对象为 C 的范畴对象上的 Yoneda 像」的
  子预范畴，它饱和且等价于原范畴。**Rezk 完备化的存在定理**
  （9.9.7）是本章的技术终点：范畴论不必预先假设饱和——
  「好范畴」可以从任何粗糙起点补造。与 38 章「泛等的私人
  账本」互读：饱和化是「iso→eq 的公理」的**构造性替代**。

## 45.7 机器面导读

`ex45_category.agda`（cubical）四段：PreCat（homSet 纪律 +
老三样）与 Iso（走回 id 的两侧律）；Functor/NatTrans；hom
合成的自然性样本（Yoneda 胚）+ 预函子范畴的装配说明；Mono/
Homo（SIP 的第一代数实例 + 三段式推导的引路注释）。

> **坑位速记**
> ① record 内部引用**本 record 的字段**（Iso 用 PreCat 的
>   comp/idm）要用 `comp C …` 实参形——裸 comp 不在辖域
>   （open PreCat 在 record 定义后才生效）；
> ② Iso 的两侧律写成 comp fwd bwd ≡ idm x——注意 comp 的
>   签名 (f : Hom x y)(g : Hom y z)，合成顺序与书的 ∘ 记法
>   相反时类型会「调头」（x≠y 报错是端点锚定）；
> ③ homSet 使自然性方块 isProp——「图表唯一可换」是纪律
>   的红利，SIP 推导中反复收割。

---

上一章：[44 同伦论进阶](44-homotopy.md) · 下一章：[46 集合论](46-settheory.md)
