# 20 范畴论 —— 为什么要"预范畴"

> 本章代码：[`examples/20_categories.v`](../examples/20_categories.v)

HoTT 里的范畴论有一处与教科书根本不同。教科书说"一个范畴由对象的**集合**和态射的**集合**组成"；
但在 HoTT 里，`Type` 不是集合（第 11 章），我们希望"所有集合构成的范畴"
这样的东西存在，它的对象显然不构成集合。于是定义必须重新设计。
这一章解释库里的 `PreCategory` 为什么长成那个样子（尤其是那些看起来多余的字段），
手造一个范畴，然后讲"预"范畴和真正的范畴之间差了什么——
那个差别正是泛等公理在范畴层面的回声。

范畴论模块不在 `HoTT` 的默认导出里：

```coq
Require Import HoTT.Categories.
```

## 20.1 `PreCategory` 的结构

```coq
Record PreCategory := Build_PreCategory'
  { object   : Type;
    morphism : object -> object -> Type;
    identity : forall x, morphism x x;
    compose  : forall s d d', morphism d d' -> morphism s d -> morphism s d';
    associativity     : forall x1 x2 x3 x4 (m1 : morphism x1 x2) (m2 : morphism x2 x3) (m3 : morphism x3 x4),
                        compose (compose m3 m2) m1 = compose m3 (compose m2 m1);
    associativity_sym : (* 同上，方向相反 *) ...;
    left_identity     : forall a b (f : morphism a b), compose (identity b) f = f;
    right_identity    : forall a b (f : morphism a b), compose f (identity a) = f;
    identity_identity : forall x, compose (identity x) (identity x) = identity x;
    trunc_morphism    : forall s d, IsHSet (morphism s d) }.
```

十个字段，三组：

| 组 | 字段 | 说明 |
|---|---|---|
| 数据 | `object`、`morphism`、`identity`、`compose` | 通常意义的范畴数据 |
| 定律 | `associativity`、`associativity_sym`、`left_identity`、`right_identity`、`identity_identity` | 范畴公理 |
| 截断 | `trunc_morphism` | **态射必须构成集合** |

两处值得停下来想。

### 为什么态射必须是集合，对象却不必

范畴公理是关于态射的等式。如果态射类型不是集合，"结合律"就不是一个性质而是一份数据——
需要选一条特定的路径，而且还要讨论这些路径之间的相容性（五边形、三角形……），
那就成了 2-范畴、∞-范畴。要求态射是集合，正好让范畴公理退化为命题，
这是"1-范畴"的精确含义。

对象则不必是集合。"所有集合的范畴"的对象是 `HSet`，它是 1-型；
这正是允许它存在的地方。

### 为什么结合律要存两遍

`associativity` 和 `associativity_sym` 互为逆路径，逻辑上存一条就够。
存两条是工程考虑：从一个范畴构造另一个（取反范畴、切片范畴、函子范畴）时，
常常只能自然地算出反方向的那条；如果只存一条，就得插一步取逆，
而取逆会在后续证明里留下 `inverse` 需要化简。存两条，构造时直接各取所需。
`identity_identity` 同理——它能从 `left_identity` 推出，但存着省一次改写。
（因为态射是集合，这些冗余字段之间的相容性自动成立。）

## 20.2 动手造一个：离散范畴

对象是一个集合 `A`，态射 `a -> b` 就是路径 `a = b`。这是"类型即群胚"
（第 06 章）这一观点的直接体现——每个集合都是一个范畴，态射是它的路径。

```coq
Definition discrete_category (A : Type) `{IsHSet A} : PreCategory :=
  {| object := A ;
     morphism := (fun a b : A => a = b) ;
     identity := (fun a : A => 1) ;
     compose := (fun (s d d' : A) (q : d = d') (p : s = d) => p @ q) ;
     associativity := (fun x1 x2 x3 x4 m1 m2 m3 => concat_p_pp m1 m2 m3) ;
     associativity_sym := (fun x1 x2 x3 x4 m1 m2 m3 => concat_pp_p m1 m2 m3) ;
     left_identity := (fun a b f => concat_p1 f) ;
     right_identity := (fun a b f => concat_1p f) ;
     identity_identity := (fun x : A => 1) ;
     trunc_morphism := (fun s d : A => _) |}.
```

逐条对账：

- `identity` 是恒等路径；`compose` 是路径复合——注意 `compose` 的参数顺序是先
  `morphism d d'` 后 `morphism s d`（数学里 `g ∘ f` 的顺序），所以 `q` 在前 `p` 在后，
  结果是 `p @ q`；
- 两条结合律正是第 06 章的 `concat_p_pp` 与 `concat_pp_p`；
- 两条单位律是 `concat_p1` 与 `concat_1p`；
- `trunc_morphism` 留 `_`，让类型类从 `IsHSet A` 推出 `IsHSet (a = b)`。

路径群胚的全部结构正好填满范畴的全部字段，没有一个多余。

```coq
Compute (@morphism (discrete_category Bool) true false).   (* = true = false *)
```

## 20.3 函子

```coq
Check Build_Functor.
(* forall (C D : PreCategory) (object_of : C -> D)
     (morphism_of : forall s d, morphism C s d -> morphism D (object_of s) (object_of d)),
     (保复合) -> (保恒等) -> Functor C D *)
```

四份数据：对象映射、态射映射、保复合、保恒等。后两条是等式，因为态射是集合，
所以它们是命题——函子之间的相等只看前两份数据。

## 20.4 "预"范畴与范畴

`PreCategory` 前面的"预"字是什么意思？

在任何预范畴里，对象之间有两个"一样"的概念：**相等** `x = y`（对象类型里的路径）
和**同构** `x ≅ y`（有逆的态射）。从相等总能造出同构——路径归纳，`idtoiso : x = y -> x ≅ y`。
但反过来不一定。

```coq
Print Category.
(* Record Category := { precategory_of_category : PreCategory;
                        iscategory_precategory_of_category : IsCategory ... } *)
```

`IsCategory C` 说：对所有 `x y`，`idtoiso : (x = y) -> (x ≅ y)` 是**等价**。
满足它的预范畴叫**范畴**（HoTT 书里也叫"单叶范畴"，univalent category）。

这和泛等公理的形状一模一样：泛等说 `equiv_path : (A = B) -> (A ≃ B)` 是等价。
事实上"所有集合的范畴是单叶的"就是泛等的推论。单叶性是**泛等在范畴层面的回声**：
对象的同构就是对象的相等。

为什么这个条件好？

- 在单叶范畴里，"同构的对象有相同的性质"自动成立（沿 `idtoiso⁻¹` 搬运）；
- 两个范畴等价（有拟逆函子）当且仅当它们相等（需要泛等）；
- 对象类型的层级受控：单叶范畴的对象是 1-型。

集合论范畴论里这些都不成立或没有意义（比如"两个范畴相等"在 ZFC 里几乎总是假的），
所以经典范畴论要不断说"在等价意义下"。HoTT 把它变成了字面意思。

## 20.5 实际使用

范畴论模块相当庞大。入门记住三点：

1. **证态射相等用 `hset_path2` 或 `path_ishprop`**：态射是集合，任意两条平行路径相等。
2. **教科书写"相等"的地方，这里常是"同构"**；只有在单叶范畴里两者才一致。
3. **要"范畴等价即相等"，需要 `Univalence`**。

库还并行维护一套 **WildCat**（野范畴）：去掉 `trunc_morphism`，允许态射是任意类型，
保留高阶结构。它用于处理 `Type` 本身这样的"∞-范畴"（对象是类型，态射是函数，
2-态射是同伦……）。选择哪一套取决于要不要高阶同伦信息。

## 小结

- `PreCategory`：对象任意类型，态射必须是集合；范畴公理因此是命题。
- 结合律存两遍、`identity_identity` 单独存，都是为了构造时省去改写。
- 每个集合是一个离散范畴，态射是路径；路径群胚的结构正好填满范畴的字段。
- 范畴 = 预范畴 + 单叶性（`idtoiso` 是等价）；单叶性是泛等在范畴层面的对应物。
- 单叶范畴里"同构即相等"，经典的"在等价意义下"成为字面意思。

## 常见误区

1. **以为范畴的对象也要是集合**。不要求；"所有集合的范畴"的对象是 `HSet`，它不是集合。
2. **把 `compose` 的参数顺序想成 `f` 在前**。它先接 `morphism d d'`（后作用的那个），
   与数学里 `g ∘ f` 一致。
3. **觉得 `associativity_sym` 多余就不填**。它是必填字段；用具名字段语法 `{| ... |}` 避免错位。
4. **把 `1%morphism` 和 `1%path` 混淆**。范畴记号上下文里 `1` 是恒等态射。

## 练习

1. 定义一个有两个对象、唯一一个非恒等态射的范畴（"箭头范畴" `0 → 1`）。
2. 证明 `discrete_category A` 是单叶的（提示：对集合，`x ≅ y` 与 `x = y` 都是命题，
   且互相蕴含）。
3. 思考：为什么"所有预范畴的范畴"不是一个预范畴？（提示：函子之间的态射是什么？它们构成集合吗？）

---

**上一章**：[19 余极限](19-colimits.md)
**下一章**：[21 点化类型](21-pointed.md)
