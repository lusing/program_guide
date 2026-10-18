# 06 函子

> 对书：贺伟《范畴论》1.2（函子）/《高级范畴论》4.1–4.3（函子、多元
> 函子、hom-函子）/ Simmons 3.1–3.3（幂集函子、从积来的函子、comma）。
> 代码：`examples/05_functors/`。

## 5.1 范畴之间的态射

有了范畴，下一个问题自然浮现：**范畴之间怎么映射？** 答案是保结构：

```coq
Record Functor@{u v u' v'} (C : Category@{u v}) (D : Category@{u' v'}) : Type := mkFun {
  FObj : Obj C -> Obj D;
  FHom : forall {a b}, Hom C a b -> Hom D (FObj a) (FObj b);
  Fid : forall a, FHom (idn C a) = idn D (FObj a);
  Fcomp : forall {a b c} (f : Hom C a b) (g : Hom C b c),
            FHom (comp C f g) = comp D (FHom f) (FHom g)
}.
```

两条定律（保恒等、保复合）是**函数级等式**——这是本章一切技术难点的
根源：函数级等式要用外延公理从点级等式升级，三家在这里分岔
（04 章的老问题，规模升级）。

## 5.2 一批例子

| 函子 | 定义 | 定律 |
|---|---|---|
| `idFun` | 恒等 | rfl 白送 |
| `constFun` | 常值到 catOne | rfl 白送 |
| `listFun` | `A ↦ list A`，`f ↦ map f` | map 律（归纳 + funext） |
| `homFun` | `b ↦ Hom C a b`，`f ↦ 后复合` | **范畴定律的点式版** |

**List 函子**的定律就是熟悉的函数式编程引理：

```text
map id      = id          （map_id）
map (g ∘ f) = map g ∘ map f （map_comp）
```

点式证明都是两行归纳；「点式 → 函数级」由 funext 桥接
（Coq 公理、Agda postulate、Lean 核心定理——记账见章末）。

**hom-函子** `Hom(a, -) : C → Set` 是全书最重要的函子：

```coq
Fid   : funext (fun g => idR C g)            (* g;id = g 点式 *)
Fcomp : funext (fun h => eq_sym (assoc C h f g))  (* (h;f);g = h;(f;g) 点式 *)
```

函子定律逐条就是范畴定律的点式版——**这不是巧合，是 Yoneda 引理
（09 章）一切免费性的根源**。

**逆变函子** = 反范畴上的协变函子：`Hom(-, b) : C^op → Set`。
03 章的对偶构造在这里兑现了第一笔红利。

## 5.3 函子保交换图

函子定律的直接推论：C 里交换的方块，搬进 D 依然交换：

```coq
Lemma F_preserves_square : ...
    comp C f h = comp C g k ->
    comp D (FHom F f) (FHom F h) = comp D (FHom F g) (FHom F k).
Proof.
  intros. rewrite <- (Fcomp F f h), <- (Fcomp F g k), H. reflexivity.
Qed.
```

`Print Assumptions`：**零公理**——图形追着函子走，是纯粹的复合搬运。
Simmons 3.x 的每个「diagram chasing」习题背后都是这个引理。

## 5.4 三家的宇宙账

- Coq：跨两个范畴的 record 必须**真宇宙多态**——默认 flags 下
  `Record Foo@{u v}` 只是命名全局宇宙（单态）！跨范畴实例化会
  报 "Universe instance length"——正解是 `Set Universe Polymorphism.`
  + `Set Implicit Arguments.`（本章起的标配开头）。
- Agda：`record Functor {o ℓ o′ ℓ′}` 四层变量，宇宙账从本章起
  要精打细算（homFun 的源范畴钉 `Category 0ℓ 0ℓ` 对齐 TyCat）。
- Lean：`structure FunctorC (C : Category.{u,v}) (D : ...)` 原生
  支持——但撞核心库 `Functor`（typeclass）的名字，改名 `FunctorC`。

## 5.5 三个幂集函子（Simmons 3.3.1）

幂集不只「是」一个构造——它是**三个函子的舞台**。对每个函数
`f : A → B`，幂集上自然长出三种箭头行为：

| 记号 | 名字 | `b ∈ ?(f)(X)` 的判据 | 复合方向 |
|---|---|---|---|
| `∃(f)` | 直接像 | `∃a, X a ∧ f a = b` | `∃(g∘f) = ∃(g)∘∃(f)` |
| `I(f)` | 逆像 | `f a ∈ Y`（即 `Y (f a)`） | `I(g∘f) = I(f)∘I(g)` **反变** |
| `∀(f)` | 对偶像 | `f⁻¹{b} ⊆ X`（纤维整个落进 X） | `∀(g∘f) = ∀(g)∘∀(f)` |

`I` 就是通常的 `f⁻¹`——**复合律是定义性的**（两侧展开是同一个
项）；`∃` 与 `∀` 的复合律要真算。记号不是巧合：`∃(f)` 把
「存在原像」打包、`∀(f)` 把「对所有纤维成员」打包——**量词是
幂集上的函子行为**。这一观察在 25 章兑现成伴随串
`∃(f) ⊣ I(f) ⊣ ∀(f)`（量词的左伴随/右伴随身份）。

机器版在二元素集上把三条复合律全部穷尽验证（Coq 128 格）：

```coq
Definition pex (f : bool -> bool) (X : PSet) : PSet :=
  fun b => orb (andb (X false) (eqb (f false) b))
               (andb (X true)  (eqb (f true)  b)).

Lemma pex_comp : forall (f g : bool -> bool),
  pex (fun x => g (f x)) = fun X => pex g (pex f X).
Proof.
  intros f g. apply funext. intros X. apply funext. intros b. unfold pex.
  destruct (f false), (f true), (g false), (g true),
           (X false), (X true), b; reflexivity.
Qed.
```

注意 destruct 清单是「并集」：左式要 `g (f x)` 的值、右式要
`g` 的原值，两组都得拆开。同款引理 `pall_comp` 对 `∀` 成立；
`pimg_comp`（逆像）则是 `reflexivity`——**定义即函子**的机器
版（Agda 版一行 `refl`）。再加一条「单点截面」（3.5.7 的种子）：

```coq
Lemma eta_ex : forall (f : bool -> bool) (a b : bool),
  pex f (fun x => eqb x a) b = eqb (f a) b.
```

单点集的直接像恰是单点的像——`η∃ : Id ⇒ ∃` 的组件，25 章
两套完备化的第一个组件。

## 5.6 从积来的函子与「换装」函子（Simmons 3.3.3 / 3.3.5）

**二元积是函子**：`−×− : C×C → C` 在箭头上的行为
`(f₁,f₂) ↦ f₁×f₂` 由积的泛性质**唯一**确定（先经投影回到分量、
再经中介映射回去）。`f₁×f₂` 的函子性（`(g₁∘f₁)×(g₂∘f₂) =
(g₁×g₂)∘(f₁×f₂)`）不是靠计算、而是靠**中介箭头的唯一性**——
两个候选都满足定义同一组方程，故相等。「唯一性代替计算」
是泛性质技术的第一次完整亮相，11 章将把它做成机器。

固定一头得 `−×R`（右乘函子）。Simmons 3.3.5 再给三个「换装」
样本：

- **阿贝尔化** `δ : Grp → Grp`：`δA` = 交换子子群；任何群同态
  限制到交换子群上给出唯一的 `δ(f)`——函子性又是唯一性；
  商掉 δA 得到 `A → A/δA`，阿贝尔群世界在 Grp 里的反射（18 章）；
- **幺半群换装**：幺半群态射 `φ : S → R` 把任何 R-集变成 S-集
  （`a ⋆ s := a·φ(s)`）——`Mon → CAT` 的作用，26 章两个伴随的
  原材料；
- **Pfn ≃ Set⊥** 的翻译 `L/M`（1.2.7 的构造）其实都是函子——
  08 章的等价因此是**范畴同构**级别的强命题。

## 坑位速记

1. Coq 字段值 binder 计数在 Functor 上重现：`FHom := fun _ _ f => ...`
   （3 个）、`Fcomp := fun _ _ _ f g => ...`（5 个）。
2. Coq 宇宙实例分隔符是**空格**不是逗号：`Category@{Set Set}`；
   代数层（`Set+1`）在实例位置不被接受。
3. Coq 具体范畴做源/靶时，字段提供项的期望类型带元变量——
   `FObj := fun A : Obj catTy => (list A : Obj catTy)` 式注解救场。
4. funext 在项位置（Coq）推不出隐式 B 时，把等式两侧函数写全：
   `@funext _ _ (fun g => ...) (fun x => x) (fun g => idR C g)`。
5. Agda 的 where 块**看不见外层子句的隐式参数**——点式引理提为
   顶层；`Fid = λ a → funext map-id-pointwise` 直接喂点式引理
   比函数级引理稳（函数级留 meta）。
6. Lean 的 `F.FHom f` 点号访问投影；`funext map_id_pointwise`
   一行升级点式归纳——三家最省心的一条通道。

---

上一章：[05 图与交换图](04-diagrams.md) · 下一章：[07 自然变换与函子范畴](06-natural.md)
