# 15 截断操作 —— `Tr`、`merely` 与连通性

> 对应示例：`examples/15_truncations.v`（编译验证通过）

第 09 章讲的是"判断一个类型落在第几层"，本章讲的是**操作**：
把一个任意类型压成 n-型。这是构造数学里"存在"的标准实现方式。

## 15.1 截断：把任意类型压成 n-型

```coq
Check Tr.
Check tr.
Check Trunc_rec.
Check Trunc_rec_tr.
```

```text
Tr
     : trunc_index -> Modality
tr
     : ?A -> Trunc ?n ?A
where
?n : [ |- trunc_index]
?A : [ |- Type]
Trunc_rec
     : (?A -> ?X) -> Trunc ?n ?A -> ?X
where
?n : [ |- trunc_index]
?A : [ |- Type]
?X : [ |- Type]
?IsTrunc0 : [ |- IsTrunc ?n ?X]
Trunc_rec_tr
     : forall (n : trunc_index) (A : Type), Trunc_rec tr == idmap
```

`Tr n A` 是 `A` 的"n-型化"：它保留 `A` 的 n-层以下的信息，
把更高层的路径统统压平。`tr : A -> Tr n A` 是它的引入。

> 注意 `Tr` 的类型是 `trunc_index -> Modality`——本库把截断统一实现为
> **模态**（modality），这是较新版本库的设计；`Trunc n A` 是它作用在
> `A` 上的结果。

截断后的类型确实落在第 n 层（`In (Tr n)` 与 `IsTrunc n` 是同一件事的两面）：

```coq
Check istrunc_inO_tr.
Check inO_tr_istrunc.
Check trunc_iff_isequiv_truncation.
```

```text
istrunc_inO_tr
     : forall A : Type, In (Tr ?n) A -> IsTrunc ?n A
where
?n : [ |- trunc_index]
inO_tr_istrunc
     : forall A : Type, IsTrunc ?n A -> In (Tr ?n) A
where
?n : [ |- trunc_index]
trunc_iff_isequiv_truncation
     : forall (n : trunc_index) (A : Type), IsTrunc n A <-> IsEquiv tr
```

若 `A` 本来就是 n-型，则 `tr : A -> Tr n A` 本身是等价：

```coq
Check isequiv_tr.
Check equiv_tr.
Check untrunc_istrunc.
```

```text
isequiv_tr
     : forall (n : trunc_index) (A : Type), IsTrunc n A -> IsEquiv tr
equiv_tr
     : forall (n : trunc_index) (A : Type), IsTrunc n A -> A <~> Tr n A
untrunc_istrunc
     : forall (n : trunc_index) (A : Type), IsTrunc n A -> Tr n A -> A
```

## 15.2 `merely`：命题化的存在

```coq
Check merely.
Check hexists.
Check hor.
Locate "\/".
```

```text
merely
     : Type -> HProp
hexists
     : (?X -> Type) -> HProp
where
?X : [ |- Type]
hor
     : Type -> Type -> HProp
Notation "A \/ B" := (hor A B)
  (* A in scope _type_scope, B in scope _type_scope *) : hprop_scope
  (from HoTT.Truncations.Core)
Notation "X \/ Y" := (Wedge X Y) : pointed_scope (default interpretation)
  (from HoTT.Homotopy.Wedge)
```

`merely A` 是 `A` 的 (-1)-截断：它只记得"A 是否有居民"，
忘了是哪一个居民。这是构造数学里"存在"的标准形式。

```coq
Definition merely_of {A : Type} (a : A) : merely A := tr a.
Check merely_of.
```

```text
merely_of
     : ?A -> merely ?A
where
?A : [ |- Type]
```

`merely A` 是一个 `HProp`，所以它的两个居民自动相等：

```coq
Definition merely_unique {A : Type} (x y : merely A) : x = y
  := path_ishprop x y.
```

```text
merely_unique
     : forall x y : merely ?A, x = y
where
?A : [ |- Type]
```

> 注意 `\/` 有两个版本：`hprop_scope` 里的 `hor`（命题化析取）
> 与 `pointed_scope` 里的 `Wedge`（点化的楔和）。别混。

## 15.3 截断递归：从 `Tr n A` 出去的唯一方式

要定义 `Tr n A -> X`，只要定义 `A -> X`，前提是 `X` 本身是 n-型。
——这正是"截断"这个词的全部含义：它把信息压到 n 层，
所以只能被 n-型的目标接收。

```coq
Check Trunc_rec.
```

```text
Trunc_rec
     : (?A -> ?X) -> Trunc ?n ?A -> ?X
where
?n : [ |- trunc_index]
?A : [ |- Type]
?X : [ |- Type]
?IsTrunc0 : [ |- IsTrunc ?n ?X]
```

例子：从 `merely A` 出发只能得到 h-prop 级别的结论。

```coq
Definition merely_to_hprop {A : Type} (P : Type) `{IsHProp P} (f : A -> P)
  : merely A -> P
  := Trunc_rec f.
```

```text
merely_to_hprop
     : forall P : Type, IsHProp P -> (?A -> P) -> merely ?A -> P
where
?A : [ |- Type]
```

> **坑**：目标不是 n-型时，`Trunc_rec` 会要求你给出 `IsTrunc n X` 的实例，
> 类型类搜索失败的错误信息往往很晦涩。

## 15.4 处理"存在"的 tactic：`strip_truncations`

证明目标是 h-prop 时，可以先把 `merely` 的居民"剥掉"当成真的居民用，
剩下的目标由 `IsHProp` 保证唯一。

```coq
Definition merely_inhabited_implies_ishprop {A P : Type} `{IsHProp P}
  : (A -> P) -> merely A -> P
  := fun f => Trunc_rec f.
```

```text
merely_inhabited_implies_ishprop
     : (?A -> ?P) -> merely ?A -> ?P
where
?A : [ |- Type]
?P : [ |- Type]
?IsHProp0 : [ |- IsHProp ?P]
```

这就是"存在消去"在 HoTT 里的形式：**目标必须是命题**。

## 15.5 连通性与满射

```coq
Check IsConnected.
Check IsSurjection.
Check BuildIsSurjection.
Check issurj_retr.
```

```text
IsConnected
     : ReflectiveSubuniverse -> Type -> Type
IsConnMap (Tr (-1))
     : (?A -> ?B) -> Type
where
?A : [ |- Type]
?B : [ |- Type]
BuildIsSurjection
     : forall f : ?A -> ?B,
       (forall b : ?B, merely (hfiber f b)) -> IsConnMap (Tr (-1)) f
where
?A : [ |- Type]
?B : [ |- Type]
issurj_retr
     : forall s : ?Y -> ?X,
       (forall y : ?Y, ?r (s y) = y) -> IsConnMap (Tr (-1)) ?r
where
?X : [ |- Type]
?Y : [ |- Type]
?r : [ |- ?X -> ?Y]
```

满射 = "每个纤维都被 merely 地命中"：
`IsSurjection f := IsConnMap (Tr (-1)) f`。

```coq
Check (fun (A B : Type) (f : A -> B) => IsSurjection f).
```

```text
fun (A B : Type) (f : A -> B) => IsConnMap (Tr (-1)) f
     : forall A B : Type, (A -> B) -> Type
```

注意打印结果里 **`IsSurjection` 被展开成了 `IsConnMap (Tr (-1))`** ——
它是记号（Notation）而不是定义名，`Check` 显示的是展开后的项。

连通的例子：圆是 0-连通的。

```coq
Check isconnected_Circle.
```

```text
isconnected_Circle
     : IsConnected (Tr 0) Circle
where
?H : [ |- Univalence]
```

## 15.6 满射 + 嵌入 = 等价

```coq
Check isequiv_surj_emb.
Check isembedding_precompose_surjection_hset.
```

```text
isequiv_surj_emb
     : forall f : ?A -> ?B,
       IsConnMap (Tr (-1)) f -> IsEmbedding f -> IsEquiv f
where
?A : [ |- Type]
?B : [ |- Type]
```

这条分解是 HoTT 里"任何映射都能分解成满射接嵌入"的基础，
在范畴论（第 20 章）与像分解里反复出现。

```coq
Check image.
Check himage.
```

```text
image
     : forall (O : Modality) (A B : Type) (f : A -> B),
       Factorization (@IsConnMap O) (@MapIn O) f
himage
     : forall f : ?X -> ?Y,
       Factorization (@IsConnMap (Tr (-1))) (@MapIn (Tr (-1))) f
where
?X : [ |- Type]
?Y : [ |- Type]
```

## 本章坑位清单

1. **`Tr` 的类型是 `trunc_index -> Modality`**，
   不是 `trunc_index -> Type -> Type`；`Trunc n A` 才是类型。
2. **`Trunc_rec` 要求目标是 n-型**：否则类型类搜索失败，
   报错信息很晦涩。
3. **`tr` 是构造子**，把 `a : A` 送进 `Tr n A`；
   `Trunc_rec` 是它唯一的消去方式。
4. **`merely A` 是 `HProp` 而不是 `Type`**：
   所以 `merely A` 的两个居民自动相等（`merely_unique`）。
5. **`\/` 有两个版本**：`hprop_scope` 的 `hor` 与
   `pointed_scope` 的 `Wedge`。
6. **存在消去要求目标是命题**：`merely A -> P` 需要 `IsHProp P`。
7. **`IsSurjection f` 展开是 `IsConnMap (Tr (-1)) f`**，
   所以 `Print` 里看到的是后者。
8. **`(-1)` 要写 `(-1)%trunc`** 或被推断为 `trunc_index`；
   在 `Tr (-1)` 里由 `Tr` 的参数类型推断。
9. **`isconnected_Circle` 需要 `Univalence`**：
   因为它依赖圆的基本群计算。
10. **`image` 是一般模态的像分解，`himage` 是 (-1)-截断的特例**。
11. **`strip_truncations` 这个 tactic 存在但本示例没演示**：
    它的原理就是 `Trunc_rec` + 目标是 h-prop。
12. **`equiv_tr` 说的是"已经是 n-型时截断是等价"**，
    这条在需要把 `Tr n A` 的元素搬回 `A` 时是关键的。

---

**上一章**：[14 类型构造器的路径与等价](docs/14-type-formers.md)
**下一章**：[16 集合层面的数学与商类型](docs/16-sets-quotient.md)
