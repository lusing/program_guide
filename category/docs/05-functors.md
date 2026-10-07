# 05 函子

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
（03 章的老问题，规模升级）。

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
（08 章）一切免费性的根源**。

**逆变函子** = 反范畴上的协变函子：`Hom(-, b) : C^op → Set`。
02 章的对偶构造在这里兑现了第一笔红利。

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

上一章：[04 图与交换图](04-diagrams.md) · 下一章：[06 自然变换与函子范畴](06-natural.md)
