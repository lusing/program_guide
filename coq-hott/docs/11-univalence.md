# 11 泛等公理 —— 等价就是相等

> 对应示例：`examples/11_univalence.v`（编译验证通过）

这是 HoTT 的心脏。泛等公理（univalence axiom）说：

> `(A ≃ B) ≃ (A = B)`

即"两个类型等价"与"两个类型相等"是同一件事。
本章把这条公理的用法、行为律、以及它带来的后果讲清楚。

## 11.1 `Univalence` 也是一个"空类型"

```coq
Print Univalence.
Check equiv_path.
Check isequiv_equiv_path.
```

```text
*** [ Univalence : Type0 ]
equiv_path
     : forall A B : Type, A = B -> A <~> B
isequiv_equiv_path
     : forall A B : Type, IsEquiv (equiv_path A B)
where
?H : [ |- Univalence]
```

和 `Funext` 一样，`Univalence` 是空的占位类型，
需要它的定理写成 `Context `{Univalence}`，这样公理用量可被追踪。

## 11.2 `equiv_path`：从相等到等价（不需要公理）

```coq
Check equiv_path.
Print Assumptions equiv_path.
```

```text
equiv_path
     : forall A B : Type, A = B -> A <~> B
Closed under the global context
```

相等必然给出等价——把元素沿路径搬运过去。这一步是**纯定义的**，
零公理。反方向才是公理。

## 11.3 `path_universe`：从等价到相等（需要泛等）

```coq
Section UnivalenceDemo.
  Context `{Univalence}.

  Check path_universe.
  Check path_universe_uncurried.
  Check equiv_path_universe.
  Check equiv_equiv_path.
End UnivalenceDemo.
```

```text
path_universe
     : forall f : ?A -> ?B, IsEquiv f -> ?A = ?B
where
?A : [H : Univalence |- Type]
?B : [H : Univalence |- Type]
path_universe_uncurried
     : ?A <~> ?B -> ?A = ?B
where
?A : [H : Univalence |- Type]
?B : [H : Univalence |- Type]
equiv_path_universe
     : forall A B : Type, (A <~> B) <~> A = B
equiv_equiv_path
     : forall A B : Type, A = B <~> (A <~> B)
```

布尔取反这个自等价，给出一条 `Bool = Bool` 的路径：

```coq
Definition negb_path : Bool = Bool
  := path_universe (equiv_adjointify negb negb
      (fun b => match b with true => idpath | false => idpath end)
      (fun b => match b with true => idpath | false => idpath end)).
Check negb_path.
```

```text
negb_path
     : Bool = Bool
```

> **坑**：这里必须写 `idpath` 而不是 `1`——本文件打开了 `path_scope`，
> 但若在同时打开 `equiv_scope` 的文件里，`1` 会被解析成 `equiv_idmap`。
> 保险起见一律写 `idpath`。

沿这条路径搬运，等于把等价作用在元素上（这是泛等唯一的"计算律"）：

```coq
Check transport_path_universe.
Check transport_path_universe_V.
```

```text
transport_path_universe
     : forall (f : ?A -> ?B) (feq : IsEquiv f) (z : ?A),
       transport idmap (path_universe f) z = f z
where
?A : [H : Univalence |- Type]
?B : [H : Univalence |- Type]
transport_path_universe_V
     : forall (f : ?A -> ?B) (feq : IsEquiv f) (z : ?B),
       transport idmap (path_universe f)^ z = f^-1 z
where
?A : [H : Univalence |- Type]
?B : [H : Univalence |- Type]
```

**这两条是泛等唯一的"计算规则"**——泛等本身不可计算，
所以库里所有关于 `path_universe` 的推理最终都要化到这两条上。

出了 Section，`negb_path` 带着 `Univalence` 假设：

```coq
Check negb_path.
Print Assumptions negb_path.
```

```text
negb_path
     : Bool = Bool
where
?H : [ |- Univalence]
Axioms:
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
Univalence : Type0
```

## 11.4 导入公理，然后把世界撬起来

```coq
Require Import HoTT.Axioms.Univalence.
Check univalence_axiom.
```

```text
univalence_axiom
     : Univalence
```

### `Type` 不是集合

先看一条著名结论：`Type` 本身**不是**集合——因为它有非平凡的自等价。

```coq
Check not_hset_Type.
```

```text
not_hset_Type
     : ~ IsHSet Type
```

我们自己证一遍，思路是：若 `Type` 是集合，则 `Bool = Bool` 的任意两条路径
相等；但恒等等价与取反等价给出的两条路径并不相等。

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition negb_path' : Bool = Bool := path_universe negb_equiv.

Definition negb_path_neq_1 : negb_path' <> 1.
Proof.
  intro h.
  apply true_ne_false.
  exact ((1 @ (ap (fun p : Bool = Bool => transport idmap p true) h)^)
           @ transport_path_universe negb_equiv true).
Defined.
```

```text
negb_path_neq_1
     : negb_path' <> 1
Axioms:
univalence_axiom : Univalence
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
Univalence : Type0
```

拆解这个证明：

- `h : negb_path' = 1`；
- `ap (fun p => transport idmap p true) h` 给出
  `transport idmap negb_path' true = transport idmap 1 true`，
  右边就是 `true`；
- 取逆后与 `transport_path_universe negb_equiv true`
  （左边 = `negb_equiv true` = `false`）拼接，
  得到 `false = true`；
- `apply true_ne_false` 把目标换成 `true = false`，正好对上。

> **坑**：`@` 不是左结合的，连写三个要显式加括号，
> 否则 Rocq 9 会给出 `[level-tolerance]` 警告——它出现在 stderr 上，
> 会让本教程的验证失败。

## 11.5 泛等的行为律

```coq
Check eta_path_universe.          (* path_universe (equiv_path p) = p *)
Check equiv_path_path_universe.   (* equiv_path (path_universe f) = f *)
Check path_universe_1.            (* path_universe (1 : A <~> A) = 1 *)
Check path_universe_V.            (* path_universe (f^-1) = (path_universe f)^ *)
Check path_universe_compose.      (* path_universe (g oE f) = ... *)
```

```text
eta_path_universe
     : forall p : ?A = ?B, path_universe (equiv_path ?A ?B p) = p
where
?A : [ |- Type]
?B : [ |- Type]
equiv_path_path_universe
     : forall f : ?A <~> ?B, equiv_path ?A ?B (path_universe f) = f
where
?A : [ |- Type]
?B : [ |- Type]
path_universe_compose
     : forall (f : ?A <~> ?B) (g : ?B <~> ?C),
       path_universe (fun x : ?A => g (f x)) =
       path_universe f @ path_universe g
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
```

前两条合起来说：`equiv_path` 与 `path_universe` 互逆——
这就是"等价 ≃ 相等"的精确形式。

等价归纳（等价版的路径归纳）：

```coq
Check equiv_induction.
Check equiv_induction'.
```

```text
equiv_induction
     : forall P : forall V : Type, ?U <~> V -> Type,
       P ?U 1%equiv -> forall (V : Type) (w : ?U <~> V), P V w
where
?U : [ |- Type]
equiv_induction'
     : forall P : forall U V : Type, U <~> V -> Type,
       (forall T : Type, P T T 1%equiv) ->
       forall (U V : Type) (w : U <~> V), P U V w
```

## 11.6 泛等能做什么：结构沿等价自动搬运

任何定义在类型上的结构都能沿等价搬过去。
比如把 `Bool` 上的取反搬到任何一个与之等价的两元素类型上。

```coq
Check univalent_transport.
Check univalent_transport_idequiv.
```

```text
univalent_transport
     : forall (S : Type -> Type) (X Y : Type), X <~> Y -> S X -> S Y
univalent_transport_idequiv
     : forall (S : Type -> Type) (X : Type), univalent_transport S 1 == idmap
```

更常见的是"两个等价的类型，一个满足某性质则另一个也满足"：

```coq
Check istrunc_equiv_istrunc.
```

```text
istrunc_equiv_istrunc
     : forall A B : Type,
       A <~> B -> forall n : trunc_index, IsTrunc n A -> IsTrunc n B
```

## 本章坑位清单

1. **`equiv_path` 不需要公理，`path_universe` 需要**：
   判断依据是 `Print Assumptions`。
2. **`Require Import HoTT` 不给 `Univalence` 实例**，
   要 `Require Import HoTT.Axioms.Univalence`。
3. **`1` 在 `equiv_scope` 里是 `equiv_idmap`**：
   打开了 `equiv_scope` 的文件里写 `idpath` 更安全。
4. **三个 `@` 连写会触发 `[level-tolerance]` 警告**：
   显式加括号 `((1 @ a) @ b)`。
5. **`transport_path_universe` 是泛等唯一的计算律**，
   `simpl` 对 `path_universe` 无能为力。
6. **`not_hset_Type` 说明 `Type` 不是集合**：
   所以"两个类型相等"这件事有非平凡的结构。
7. **`path_universe` 的第一个参数是函数，不是等价**：
   `path_universe f` 里 `f : A -> B`，`IsEquiv f` 作为类型类实例被搜索；
   想传 `A <~> B` 要用 `path_universe_uncurried`。
8. **`eta_path_universe` 与 `equiv_path_path_universe` 合起来才是
   "互逆"**：单独一条只说明一个方向。
9. **`negb_path_neq_1` 的证明里 `apply true_ne_false` 会把目标换成
   `true = false`**：这是 `<>` 展开后的标准操作。
10. **`equiv_induction` 的 `P` 依赖 `V` 与 `w`**，
    比第 07 章的 `equiv_ind` 强（那个只依赖 `B` 不依赖等价本身）。
11. **`univalent_transport` 需要 `S : Type -> Type`**：
    它是"结构不变性原理"（SIP）的雏形，第 18 章展开。
12. **`path_universe_compose` 的右端是
    `path_universe f @ path_universe g`**，
    复合的顺序与路径拼接的顺序一致。

---

**上一章**：[10 函数外延](docs/10-funext.md)
**下一章**：[12 高阶归纳类型入门 —— 区间](docs/12-hit-interval.md)
