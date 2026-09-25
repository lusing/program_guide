# 18 泛等的应用 —— 结构沿等价搬运

> 对应示例：`examples/18_univalence_apps.v`（编译验证通过）

第 11 章确立了泛等公理本身：**`A <~> B` ⟹ `A = B`**。
本章回答"那又怎样"——一旦能写出这条路径，
所有**只依赖类型的性质与结构**都能沿等价自动搬运过去。
这是 HoTT 相对传统"集合论数学"最省力的一环：
不用再手写"同构保持性质"的一百个证明。

本章需要额外打开泛等公理（`HoTT.v` 默认**不**导出它）：

```coq
Require Import HoTT.
Require Import HoTT.Axioms.Univalence.
Local Open Scope path_scope.
```

## 18.1 第一原则：性质沿等价保持

任何"对类型封闭的谓词" `P : Type -> Type`，
若 `A ≃ B`，则由泛等得到 `A = B`，于是 `transport P` 把 `P A` 搬到 `P B`。
库里有一条专门 device 封装这件事：

```coq
Check univalent_transport.
Check univalent_transport_idequiv.
Check transport_path_universe.
```

实测输出（`build/out/18.sec1`，以下同）：

```text
univalent_transport
     : forall (S : Type -> Type) (X Y : Type), X <~> Y -> S X -> S Y
univalent_transport_idequiv
     : forall (S : Type -> Type) (X : Type), univalent_transport S 1 == idmap
transport_path_universe
     : forall (f : ?A -> ?B) (feq : IsEquiv f) (z : ?A),
       transport idmap (path_universe f) z = f z
where
?A : [ |- Type]
?B : [ |- Type]
```

三条的关系要分清：

- `univalent_transport S e : S X -> S Y` 是**搬运本身**（输入等价，输出函数）；
- `univalent_transport_idequiv` 说搬运恒等等价就是恒等函数（**同伦**意义，`==`）；
- `transport_path_universe` 是**计算规则**：在 `S := fun X => X` 时，
  搬运恰好落在底层函数 `f` 上。

最终端的应用是截断层级：

```coq
Check istrunc_equiv_istrunc.
Check istrunc_isequiv_istrunc.
```

```text
istrunc_equiv_istrunc
     : forall A B : Type,
       A <~> B -> forall n : trunc_index, IsTrunc n A -> IsTrunc n B
istrunc_isequiv_istrunc
     : forall (A B : Type) (f : A -> B) (n : trunc_index),
       IsTrunc n A -> IsEquiv f -> IsTrunc n B
```

注意参数顺序：前者**先给 `A B` 再给等价**（`A` 是显式参数），
后者先给 `f`。我们封装一个最常用的特例：

```coq
Definition hset_preserved {A B : Type} (e : A <~> B) `{IsHSet A} : IsHSet B
  := istrunc_equiv_istrunc (n := 0) A e.
Check hset_preserved.
```

```text
hset_preserved
     : ?A <~> ?B -> IsHSet ?A -> IsHSet ?B
where
?A : [ |- Type]
?B : [ |- Type]
```

即"集合性"是不变量：两个等价的类型，一个是集合则另一个也是。

## 18.2 `ap` 作用在泛等路径上

泛等路径 `path_universe f : A = B` 本身可以被任意类型函子搬运。
把 `ap` 作用在它上面会发生什么？库里备好了乘积与等价两条：

```coq
Check ap_prod_l_path_universe.
Check ap_prod_r_path_universe.
Check ap_equiv_path_universe.
```

```text
ap_prod_l_path_universe
     : forall (A B C : Type) (f : B <~> C),
       equiv_path (A * B) (A * C) (ap (prod A) (path_universe f)) =
       equiv_functor_prod_l f
ap_prod_r_path_universe
     : forall (A B C : Type) (f : B <~> C),
       equiv_path (B * A) (C * A)
         (ap (fun Z : Type => Z * A) (path_universe f)) =
       equiv_functor_prod_r f
ap_equiv_path_universe
     : forall (A B C : Type) (f : B <~> C),
       equiv_path (A <~> B) (A <~> C) (ap (Equiv A) (path_universe f)) =
       equiv_functor_equiv 1 f
```

读法：左边是"**先把等价变成路径，再用 `ap` 挪到乘积上，最后用 `equiv_path` 变回等价**"；
右边是我们手工构造的函子。引理断言两者相等。
这类引理在搬运代数结构时必不可少——它们把" `ap` 对路径的自然性"
翻译成了"函子对等价的自然性"。

`ap_equiv_path_universe` 里的 `1` 出现在 `equiv_functor_equiv 1 f`，
这里的 `1` 是**等价的恒等**（`equiv_idmap`），因为它处在 `<~>` 的上下文里；
这跟你在 18.3 节看到的 `1` 是同一个东西，不要联想到 `nat`。

## 18.3 把 `Bool` 的自等价搬到任意两元素类型上

先造 `Bool` 上的取反等价。两个方向的自反复合是 `idmap`，
同伦证明直接按构造器给 `idpath`：

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).
```

给定任意 `X` 与等价 `e : Bool <~> X`，把取反搬过去（`e ∘ negb ∘ e⁻¹`）：

```coq
Definition transported_negb (X : Type) (e : Bool <~> X) : X <~> X
  := (e oE negb_equiv) oE (equiv_inverse e).
Check transported_negb.
```

```text
transported_negb
     : forall X : Type, Bool <~> X -> X <~> X
```

它确实"就是"取反——取 `X = Bool`、`e = 1` 会退化回原函数：

```coq
Definition transported_negb_on_bool : Bool -> Bool
  := transported_negb Bool (equiv_idmap Bool).
Compute transported_negb_on_bool true.
Compute transported_negb_on_bool false.
```

```text
     = false
     : Bool
     = true
     : Bool
```

（`true` 映到 `false`、`false` 映到 `true`。）

> **为什么这里能 `Compute`？** 因为 `transported_negb` 的定义里**没有**
> `path_universe`——它是直接用 `oE` 复合出来的函数。
> 一旦中间真的经过 `path_universe`（如 18.1 的 `univalent_transport`），
> `Compute` 就卡住了，见 18.6。

## 18.4 结构不变性：以二元运算为例

"结构不变性原理"（structure identity principle）的一般形式是：
若 `A` 上有一套结构，`e : A ≃ B`，则在 `B` 上有唯一对应的结构使 `e` 成为同构。
下面用 `Bool` 上的合取演示搬运：

```coq
Definition andb_transported (X : Type) (e : Bool <~> X) : X -> X -> X
  := fun x y => e (andb (e^-1 x) (e^-1 y)).
Check andb_transported.
```

```text
andb_transported
     : forall X : Type, Bool <~> X -> X -> X -> X
```

在 `X = Bool`、`e = 1` 时它就是 `andb`：

```coq
Compute andb_transported Bool (equiv_idmap Bool) true false.
```

```text
     = false
     : Bool
```

注意定义里写的 `e^-1`：这是**等价的逆**的记号，
它的展开依赖 `Equiv` 记录的第四个字段 `equiv_inv`；
写成 `e^-1 x` 而不是 `e^-1 (x)` 也没问题（左结合）。

> 真正的 SIP 还要证明"搬运后的结构满足同一组代数定律"。
> 那需要先把定律本身也做成类型谓词（例如 `Associative op`），
> 再用 `transport` 搬过去。这里是同一手法的简化版。

## 18.5 泛等给出的"相等"是真能用来重写的

若 `P : Type -> Type` 且 `e : A <~> B`，则
`transport P (path_universe e) : P A -> P B`。
对 `P := fun X => X` 就是 `e` 本身：

```coq
Definition transport_id_is_e {A B : Type} (e : A <~> B) (a : A)
  : transport (fun X : Type => X) (path_universe e) a = e a
  := transport_path_universe e a.
Check transport_id_is_e.
```

```text
transport_id_is_e
     : forall (e : ?A <~> ?B) (a : ?A),
       transport idmap (path_universe e) a = e a
where
?A : [ |- Type]
?B : [ |- Type]
```

注意目标类型里写的是 `transport (fun X : Type => X)`，
而 Coq 打印回来是 `transport idmap`——两者是同一回事
（`idmap` 在此被提升到 `Type -> Type`）。

对 `P := fun X => X -> A`（自映射到固定类型），搬运是**预复合逆**，
即共轭：

```coq
Check transport_arrow_toconst_path_universe.
```

```text
transport_arrow_toconst_path_universe
     : forall (w : ?U <~> ?V) (f : ?U -> ?A),
       transport (fun E : Type => E -> ?A) (path_universe w) f =
       (fun x : ?V => f (w^-1 x))
where
?A : [ |- Type]
?U : [ |- Type]
?V : [ |- Type]
```

这条正是 18.3 里 `transported_negb` 共轭结构的一般化。

## 18.6 泛等不是万能的：计算性问题

**泛等是公理**，`path_universe` 不可计算。
因此 `transport (fun X => X) (path_universe e) a` 只能靠
`transport_path_universe` 这条引理手工化开，`simpl` / `cbn` 对它无能为力。

这也是为什么库里为同一个事实准备了那么多别名：

```coq
Check path_universe_transport_idmap.
Check transport_idmap_path_universe.
Check eta_path_universe.
```

```text
path_universe_transport_idmap
     : forall p : ?A = ?B, path_universe (transport idmap p) = p
where
?A : [ |- Type]
?B : [ |- Type]
transport_idmap_path_universe
     : forall f : ?A <~> ?B, transport idmap (path_universe f) = f
where
?A : [ |- Type]
?B : [ |- Type]
eta_path_universe
     : forall p : ?A = ?B, path_universe (equiv_path ?A ?B p) = p
where
?A : [ |- Type]
?B : [ |- Type]
```

三条读法：

| 引理 | 内容 | 方向 |
|---|---|---|
| `transport_idmap_path_universe` | 路径→等价→路径 得到原函数 | `path_universe` 后接 `transport` |
| `path_universe_transport_idmap` | 等价→路径→等价 得到原路径 | 反向往返 |
| `eta_path_universe` | `path_universe (equiv_path p) = p` | `eta` 律 |

这三条合起来说明：在无公理的方向（`equiv_path`：**相等 ⟹ 等价**）
两侧互逆关系完全是计算性的；只有 `path_universe` 方向是公理性的，
所以它单独需要一个"计算补丁"。这也是本章最主要的工程结论：

> **凡是卡到 `path_universe` 的表达式，`simpl` 都救不了你。
> 先想清楚要在哪一层化开，然后找名字带 `_path_universe` 的引理。**

## 本章坑位清单

1. **`HoTT.v` 不导出泛等**：`path_universe` / `univalent_transport` 都在
   `HoTT.Axioms.Univalence` 里，必须单独 `Require Import`。
2. **`univalent_transport` 的参数顺序是 `S X Y e`**，
   类型 `S` 在最前，两个类型参数在中间，容易记反。
3. **`istrunc_equiv_istrunc` 的第一个参数是 `A`（显式）**，
   写成 `istrunc_equiv_istrunc A e` 才能通过类型检查。
4. **`istrunc_isequiv_istrunc` 与前者参数顺序不同**：它先要函数 `f`。
5. **`e^-1` 是等价的逆**，不是数的逆；它只在 `<~>` 的上下文里可用。
6. **`transport_path_universe` 的打印类型是 `transport idmap`**：
   自己写目标时不必照抄这个形式，`fun X : Type => X` 也可以。
7. **`ap_prod_r_path_universe` 里出现 `ap (fun Z : Type => Z * A)`**：
   不能直接写 `ap (fun Z => Z * A)`，`Z` 的类型要显式标注，否则 Coq 无法推断宇宙。
8. **`ap_equiv_path_universe` 结果里的 `1` 是 `equiv_idmap`**，
   在 `path_scope` 打开时 `1` 也可能表示路径常量——看上下文判定。
9. **`path_universe` 不可计算**：`Compute` 会卡在原表达式上，
   必须先用 `_path_universe` 系列引理改写。
10. **`transport_arrow_toconst_path_universe` 名字里的 `toconst`**
    指目标箭头右侧**固定**为常数类型 `A`；双侧都变的情形要另外找引理。
11. **泛等路径参与的 `rewrite` 会在目标里留下 `transport`**：
    若 `P` 是常值则会简化，否则必须显式处理。
12. **`univalent_transport_idequiv` 的结论是同伦 `==` 而不是逐点等号**：
    需要逐点等号时用 `ap10` 转（见第 10 章）。

---

**上一章**：[17 截断映射与嵌入](docs/17-trunc-maps.md)
**下一章**：[19 余极限 —— Pushout、Coequalizer、Suspension](docs/19-colimits.md)
