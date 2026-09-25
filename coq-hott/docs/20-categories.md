# 20 范畴论 —— PreCategory、Category、Functor

> 对应示例：`examples/20_categories.v`（编译验证通过）

HoTT 里的范畴论有一处与教科书根本不同：
**"两个范畴相等"这句话本身不成立**（`Type` 不是集合，见第 11 章）。
因此整个库从一开始就把"相等"换成"等价/同构"，
这套对称性的管理正是 `PreCategory` 里那些看似多余的字段（`associativity_sym`
等）存在的原因。

本章先把 `PreCategory` 拆开看清楚，再手造一个离散范畴，最后谈为什么叫"预"范畴。

## 20.1 `PreCategory` 的结构

范畴论**不在** `HoTT.v` 的默认导出里，需要单独引入：

```coq
Require Import HoTT.
Set Warnings "-notation-overridden".
Require Import HoTT.Categories.
Local Open Scope path_scope.
```

> 引入 `HoTT.Categories` 会覆盖 `path_scope` 里的 `/` 记号
> （范畴论用它表示商范畴），Rocq 会往 **stderr** 打一条
> `[notation-overridden]` 警告。本教程的验证要求 stderr 为空，
> 所以显式用 `Set Warnings "-notation-overridden"` 关掉这一类。
> 若你自己写代码不关心 stderr，可以不加这行 —— 但它会污染 `run-all.sh` 的判据。

```coq
Print PreCategory.
Check object.
Check morphism.
Check identity.
Check Build_PreCategory'.
```

实测输出（`build/out/20.sec1`，以下同）：

```text
Record PreCategory@{u u0} : Type := Build_PreCategory'
  { object : Type;
    morphism : object -> object -> Type;
    identity : forall x : object, morphism x x;
    compose : forall s d d' : object,
              morphism d d' -> morphism s d -> morphism s d';
    associativity : forall (x1 x2 x3 x4 : object)
                    (m1 : morphism x1 x2) (m2 : morphism x2 x3)
                    (m3 : morphism x3 x4),
                    compose x1 x2 x4 (compose x2 x3 x4 m3 m2) m1 =
                    compose x1 x3 x4 m3 (compose x1 x2 x3 m2 m1);
    associativity_sym : forall (x1 x2 x3 x4 : object)
                        (m1 : morphism x1 x2) (m2 : morphism x2 x3)
                        (m3 : morphism x3 x4),
                        compose x1 x3 x4 m3 (compose x1 x2 x3 m2 m1) =
                        compose x1 x2 x4 (compose x2 x3 x4 m3 m2) m1;
    left_identity : forall (a b : object) (f : morphism a b),
                    compose a b b (identity b) f = f;
    right_identity : forall (a b : object) (f : morphism a b),
                     compose a a b f (identity a) = f;
    identity_identity : forall x : object,
                        compose x x x (identity x) (identity x) = identity x;
    trunc_morphism : forall s d : object, IsHSet (morphism s d) }.
```

十个字段，分成三组：

| 组 | 字段 | 说明 |
|---|---|---|
| 数据 | `object`、`morphism`、`identity`、`compose` | 通常意义的范畴数据 |
| 定律 | `associativity`、`associativity_sym`、`left_identity`、`right_identity`、`identity_identity` | 为何结合律要存**两次**见下 |
| 截断 | `trunc_morphism` | 态射必须构成集合 |

**为什么 `associativity` 与 `associativity_sym` 都保存？**
在 HoTT 里，` PreCategory` 的范畴公理本身是**数据**，不是性质。
如果只存一个方向，那么从一个范畴构造另一个范畴时（例如取反范畴、切片范畴）
常常只能算出反向的那条，而去找一条路径证明它等于正向的是多余工作。
存正反两条，构造时就不需要额外证明它们的相容性。

`identity_identity` 也是如此：它的目的是保证 `1 o 1 = 1`，
否则就要从 `left_identity` 演绎，那会引入一次不必要的改写。

`trunc_morphism` 是关键的一条：**态射必须是集合**。
它保证了"证明两个态射相等"不会产生高阶同伦的麻烦，
这正是 HoTT 里"1-范畴"的正确定义。

投影可通过 `Arguments` 以 `.` 语法访问（`PreCategory` 用了
**原始投影** `primitive projections with eta conversion`）：

```text
object
     : PreCategory -> Type
morphism
     : forall C : PreCategory, C -> C -> Type
identity
     : forall x : ?C, morphism ?C x x
where
?C : [ |- PreCategory]
```

注意这里的类型 —— 由于开了 coercion，`PreCategory` 可以直接当它的对象类型用，
所以 `morphism` 打印成 `C -> C -> Type`（对象层的 coercion 被插入了）。

## 20.2 动手造一个：离散范畴

对象是一个集合 `A`，态射 `a -> b` 就是 `a = b`。
这是最简单的范畴，也是"类型即群胚"这一观点的直接体现。

**用 Record 的具名字段语法写，字段顺序就不会搞错：**

```coq
Definition discrete_category (A : Type) `{IsHSet A} : PreCategory :=
  {| object := A ;
     morphism := (fun a b : A => a = b) ;
     identity := (fun a : A => 1) ;
     compose := (fun (s d d' : A) (q : d = d') (p : s = d) => p @ q) ;
     associativity := (fun x1 x2 x3 x4 (m1 : x1 = x2) (m2 : x2 = x3) (m3 : x3 = x4)
                       => concat_p_pp m1 m2 m3) ;
     associativity_sym := (fun x1 x2 x3 x4 (m1 : x1 = x2) (m2 : x2 = x3) (m3 : x3 = x4)
                           => concat_pp_p m1 m2 m3) ;
     left_identity := (fun a b (f : a = b) => concat_p1 f) ;
     right_identity := (fun a b (f : a = b) => concat_1p f) ;
     identity_identity := (fun x : A => 1) ;
     trunc_morphism := (fun s d : A => _) |}.
Check discrete_category.
```

```text
discrete_category
     : forall A : Type, IsHSet A -> PreCategory
```

逐条对账：

- `identity` 给 `1`（`idpath`）；
- `compose` 的参数顺序是 `morphism d d'` **在先**、`morphism s d` **在后**
  （见上面的 `Print`），所以先拿到的 `q : d = d'` 在后、`p : s = d` 在前，结果为 `p @ q`；
- 两条结合律正好对应第 06 章的 `concat_p_pp` 与 `concat_pp_p`；
- 两条单位律是 `concat_p1` 与 `concat_1p`；
- `trunc_morphism` 用 `_` 占位，让 Coq 从 `{IsHSet A}` 实例推出 `IsHSet (a = b)`。

试试它：

```coq
Compute (@morphism (discrete_category Bool) true false).
Check (@identity (discrete_category Bool) true).
```

```text
     = true = false
     : Type
1%morphism
     : morphism (discrete_category Bool) true true
```

第一行说明：`morphism (discrete_category Bool) true false` 计算出来就是
`true = false`，这也印证了离散范畴的态射确实是相等类型；
第二行出现了 **`1%morphism`**，这是 `morphism_scope` 里的 `1` 记号 ——
在范畴记号的上下文里 `1` 表示恒等态射而非 `idpath`。

## 20.3 函子

```coq
Check Functor.
Check Build_Functor.
Check object_of.
Check morphism_of.
```

```text
Functor
     : PreCategory -> PreCategory -> Type
Build_Functor
     : forall (C D : PreCategory) (object_of : C -> D)
       (morphism_of : forall s d : C,
                      morphism C s d ->
                      morphism D (object_of s) (object_of d)),
       (forall (s d d' : C) (m1 : morphism C s d)
        (m2 : morphism C d d'),
        morphism_of s d' (m2 o m1)%morphism =
        (morphism_of d d' m2 o morphism_of s d m1)%morphism) ->
       (forall x : C, morphism_of x x 1%morphism = 1%morphism) -> Functor C D
object_of
     : Functor ?C ?D -> ?C -> ?D
morphism_of
     : forall (C D : PreCategory) (F : Functor C D)
       (s d : C),
       morphism C s d -> morphism D (F _0 s)%object (F _0 d)%object
```

与 `PreCategory` 的对比：

- `Build_Functor` 只有**四条**显式数据（object_of、morphism_of、
  保复合、保恒等），远少于 `Build_PreCategory'`；
- 打印里的 `(m2 o m1)%morphism` 是受 scope 键限定的复合记号，
  打印形式与源码写法（`∘` 记号的展开）可能不同；
- `morphism_of` 的结果里出现 `F _0 s`：`_0` 是 `object_of F` 的 coercion 记号。

## 20.4 为什么叫"预"范畴

```coq
Check Category.
Print Category.
```

```text
Category
     : Type
Record Category@{u u0} : Type := Build_Category
  { precategory_of_category : PreCategory;
    iscategory_precategory_of_category : IsCategory precategory_of_category }.
```

`Category` 只是在 `PreCategory` 上**多包一层 `IsCategory`**。
`IsCategory` 的内容是：`idtoiso : x = y -> x ≅ y` 本身是**等价**。
也就是说 ——

> **`PreCategory` 只要求态射是集合；
> `Category` 额外要求"对象类型与同构关系相容"**。

这个额外的要求是让"范畴等价 = 范畴相等"得以成立的关键。
在集合论范畴论里这条自动成立（因为对象层面还在 Set 里），
而在 HoTT 里 `Type` 不是集合，必须显式加条件 —— 正是泛等精神在范畴论里的体现。

## 20.5 范畴论里的"相等"一律换成"等价"

在 HoTT 里说"两个范畴相同"是没有意义的（`Type` 不是集合），
要说"它们等价"。同理，两个对象的"同构"取代了"相等"。

```coq
Check (fun (C : PreCategory) => @morphism C).
```

```text
fun C : PreCategory => morphism C
     : forall C : PreCategory, C -> C -> Type
```

此外：本库还并行发展了一套 **WildCat**（野范畴）：它们放松了
`trunc_morphism`，保留高阶结构。选择哪一套取决于你要不要"高阶同伦信息"：

```coq
Check (fun (A : Type) => A).   (* WildCat 的对象就是类型，态射可以不是集合 *)
```

```text
idmap
     : Type -> Type
```

（注意 `Check` 把 `fun (A : Type) => A` 化简打印成了 `idmap`。）

## 20.6 实际使用建议

范畴论模块相当庞大（代数、伴随、极限都在里面）。
入门时只需记住三件事：

1. `PreCategory` 的态射是集合，所以证态射相等可以用 `hset_path2`；
2. 凡是教科书里写"相等"的地方，这里通常要换成"同构/等价"；
3. 需要 `Univalence` 才能把范畴等价升级为范畴相等。

```coq
Check hset_path2.
```

```text
hset_path2
     : forall p q : ?x = ?y, p = q
where
?x : [ |- ordinal_carrier ?o]
?y : [ |- ordinal_carrier ?o]
?o : [ |- Ordinal]
```

> **⚠ 这条输出的意外之处**：`?x` 的类型打印成了 `ordinal_carrier ?o`，
> 而不是你预期的任意 `A`。原因是 `hset_path2` 带一个 `IsHSet` 实例参数，
> 而我们没有给出具体的 `A`，Rocq 在解决这个实例时**随便挑了一个最容易匹配的
> `IsHSet` 实例**（序数载体），于是把 `A` 统一到了 `ordinal_carrier ?o`。
>
> **这就是"隐式实例可能在缺信息时被任意统一"的典型症状**。
> 单独 `Check` 一个带 typeclass 参数的引理时，看到奇怪的名字不要慌，
> 给它一个具体的类型参数就会正常：
> `Check (fun (A : Type) `{IsHSet A} (x y : A) (p q : x = y) => hset_path2 p q).`

## 本章坑位清单

1. **范畴论不在 `HoTT.v` 的默认导出里**，必须 `Require Import HoTT.Categories`。
2. **引入 `HoTT.Categories` 会触发 `[notation-overridden]` 警告**（打在 stderr），
   追求 stderr 为空要 `Set Warnings "-notation-overridden"`。
3. **`compose` 的参数顺序是 `morphism d d'` 在前、`morphism s d` 在后**，
   与手写复合的直觉顺序相反。
4. **`associativity` 与 `associativity_sym` 是两个字段**：都得填，不能省略一个。
5. **`identity_identity` 也是必需的**（`1 o 1 = 1`），不能靠别的定律推导。
6. **`trunc_morphism` 要求态射是集合**：这是 HoTT 里"1-范畴"的定义要件。
7. **用 `{| object := ... ; morphism := ... |}` 的具名字段语法**：
   位置语法极易错位，且错位时报的是无关的不合一错误。
8. **`Print PreCategory` 里的 `Arguments` 可以看到 coercion**：
   `morphism` 打印成 `C -> C -> Type` 是因为对象层被 coercion 了。
9. **`1%morphism` 是恒等态射**（`morphism_scope` 的记号），
   与 `path_scope` 的 `1`（`idpath`）同名不同义。
10. **`Check (fun A : Type => A)` 会被化简打印成 `idmap`**：
    别以为引用了一个不存在的名字。
11. **`Check hset_path2` 会把类型变量统一到 `ordinal_carrier ?o`**：
    typeclass 缺信息时的任意统一；给具体类型即可恢复正常。
12. **`Category = PreCategory + IsCategory`**：
    要"等价=相等"时上 `Category`，否则 `PreCategory` 够用。

---

**上一章**：[19 余极限 —— Pushout、Coequalizer、Suspension](docs/19-colimits.md)
**下一章**：[21 点化类型与环路空间](docs/21-pointed.md)
