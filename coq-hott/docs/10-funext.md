# 10 函数外延 —— 逐点相等与相等

> 对应示例：`examples/10_funext.v`（编译验证通过）

"两个函数在每个点上都相等，所以它们相等"——这句话在 Martin-Löf 类型论里
**证不出来**，它是公理。本章讲这条公理在 HoTT 库里是怎么被管理的。

## 10.1 `Funext` 是一个"空类型"

```coq
Print Funext.
Check isequiv_apD10.
Check apD10.
Check ap10.
Locate "==".
```

```text
*** [ Funext : Type0 ]
isequiv_apD10
     : forall (A : Type) (P : A -> Type) (f g : forall x : A, P x),
       IsEquiv apD10
where
?H : [ |- Funext]
apD10
     : ?f = ?g -> ?f == ?g
where
?A : [ |- Type]
?B : [ |- ?A -> Type]
?f : [ |- forall x : ?A, ?B x]
?g : [ |- forall x : ?A, ?B x]
ap10
     : ?f = ?g -> ?f == ?g
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?g : [ |- ?A -> ?B]
```

`Print Funext` 只输出一行 `*** [ Funext : Type0 ]`——
它是一个**没有任何构造子**的 `Monomorphic Axiom` 声明加类型类。
本库刻意*不*把函数外延当成无条件成立的公理，而是把它作为类型类假设
（`{Funext}`），这样每个定理用到哪些公理都能被 `Print Assumptions` 查出来。

## 10.2 两个方向的桥

`f = g -> f == g` 永远成立（不需要任何公理），它就是 `ap10`（依赖版 `apD10`）：

```coq
Definition eq_to_pointwise {A B : Type} (f g : A -> B) : f = g -> f == g
  := ap10.
Check eq_to_pointwise.
Print Assumptions eq_to_pointwise.
```

```text
eq_to_pointwise
     : forall f g : ?A -> ?B, f = g -> f == g
where
?A : [ |- Type]
?B : [ |- Type]
Closed under the global context
```

反方向 `f == g -> f = g` 就是函数外延，需要 `Funext`：

```coq
Check path_forall.
Check path_arrow.
```

```text
path_forall
     : forall f g : forall x : ?A, ?P x, f == g -> f = g
where
?H : [ |- Funext]
?A : [ |- Type]
?P : [ |- ?A -> Type]
path_arrow
     : forall f g : ?A -> ?B, f == g -> f = g
where
?H : [ |- Funext]
?A : [ |- Type]
?B : [ |- Type]
```

看清楚：两者的类型里都带着 `?H : [ |- Funext]`——
一个未解决的隐式参数，意思是"调用方需要提供"。

## 10.3 在 `Section` 里假设 `Funext`

```coq
Section FunextDemo.
  Context `{Funext}.

  Definition twice_eq {A B : Type} (f g : A -> B) (h : forall x, f x = g x)
    : f = g := path_forall f g h.
  Check twice_eq.

  Definition add_zero_l : (fun n : nat => (0 + n)%nat) = (fun n : nat => n).
  Proof.
    apply path_forall; intro n; destruct n; reflexivity.
  Defined.
  Check add_zero_l.
End FunextDemo.
```

```text
twice_eq
     : forall f g : ?A -> ?B, (forall x : ?A, f x = g x) -> f = g
where
?A : [H : Funext |- Type]
?B : [H : Funext |- Type]
add_zero_l
     : (fun n : nat => (0 + n)%nat) = idmap
```

出了 Section，`twice_eq` 的类型里带着 `Funext` 假设：

```coq
Check twice_eq.
Print Assumptions twice_eq.
```

```text
twice_eq
     : forall f g : ?A -> ?B, (forall x : ?A, f x = g x) -> f = g
where
?H : [ |- Funext]
?A : [ |- Type]
?B : [ |- Type]
Axioms:
isequiv_apD10 :
  Funext ->
  forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
Funext : Type0
```

注意上下文里的 `[H : Funext |- Type]` 变成了全局的 `?H : [ |- Funext]`——
这就是"假设被泛化"的痕迹。

## 10.4 没有实例时 `path_forall` 用不了

此刻文件里还没有 `Funext` 的全局实例，类型类搜索会失败：

```coq
Fail Definition bad_pointwise : (fun n : nat => n) = (fun n : nat => n)
  := path_forall _ _ (fun n => 1).
```

错误信息是"Unable to satisfy the following constraints: ?H : Funext"。

## 10.5 显式假设 vs 导入公理

想在全文件范围内无条件使用，就导入公理文件：

```coq
Require Import HoTT.Axioms.Funext.
Check funext_axiom.
```

```text
funext_axiom
     : Funext
```

现在 `path_forall` 可以直接用，不用再写 `Context `{Funext}`：

```coq
Definition add_zero_r : (fun n : nat => (n + 0)%nat) = (fun n : nat => n).
Proof.
  apply path_forall; intro n; induction n as [|n IH]; simpl.
  - reflexivity.
  - exact (ap S IH).
Defined.
Check add_zero_r.
Print Assumptions add_zero_r.
```

```text
add_zero_r
     : (fun n : nat => (n + 0)%nat) = idmap
Axioms:
isequiv_apD10 :
  Funext ->
  forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
funext_axiom : Funext
Funext : Type0
```

`Print Assumptions` 现在会列出 `funext_axiom`——
这就是"显式假设"这套机制的价值：**公理用量一目了然**。

## 10.6 函数外延的常用推论

前后复合保持等价（需要 `Funext`）：

```coq
Check isequiv_precompose.
Check isequiv_postcompose.
Check equiv_precompose.
Check equiv_postcompose.
```

```text
isequiv_precompose
     : forall f : ?A -> ?B,
       IsEquiv f -> IsEquiv (fun (g : ?B -> ?C) (x : ?A) => g (f x))
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
equiv_precompose
     : forall f : ?A -> ?B, IsEquiv f -> (?B -> ?C) <~> (?A -> ?C)
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
```

逐点路径的"based homotopy"类型是可缩的：

```coq
Check contr_basedhomotopy.
```

```text
contr_basedhomotopy
     : forall f : forall x : ?A, ?B x,
       Contr {g : forall x : ?A, ?B x & f == g}
where
?A : [ |- Type]
?B : [ |- ?A -> Type]
```

等价之间的相等可以逐点判断：

```coq
Check path_equiv.
Check equiv_path_equiv.
```

```text
path_equiv
     : ?e1 = ?e2 -> ?e1 = ?e2
where
?A : [ |- Type]
?B : [ |- Type]
?e1 : [ |- ?A <~> ?B]
?e2 : [ |- ?A <~> ?B]
equiv_path_equiv
     : forall e1 e2 : ?A <~> ?B, e1 = e2 <~> e1 = e2
where
?A : [ |- Type]
?B : [ |- Type]
```

（`path_equiv` 的打印两侧看起来一样，是因为左边是"逐点相等"的
`==` 记号的展开形式；`equiv_path_equiv` 是它打包成的等价。）

## 本章坑位清单

1. **`Require Import HoTT` 不给 `Funext` 实例**：
   必须 `Context `{Funext}` 或 `Require Import HoTT.Axioms.Funext`。
2. **`path_forall` 与 `path_arrow` 是两个名字**：
   前者用于依赖函数，后者用于普通函数；非依赖时两者都可以用。
3. **`Print Funext` 只输出 `*** [ Funext : Type0 ]`**：
   它没有任何构造子，是"空类型 + 类型类"。
4. **`apply path_forall` 之后要先 `intro`**：
   目标是 `f == g`，展开就是 `forall x, f x = g x`。
5. **`(fun n : nat => n)` 会被打印成 `idmap`**：
   这是 pretty-printer 的化简，不是你的定义变了。
6. **`Fail` 在 `-q` 下静默**：调试类型类失败时别加 `-q`。
7. **`0 + n = n` 是定义性的，`n + 0 = n` 要归纳**：
   因为 `nat_add` 递归在第一个参数上。
8. **`contr_basedhomotopy` 说的是"与 f 同伦的函数构成可缩类型"**，
   这是函数外延的直接推论。
9. **`isequiv_apD10` 才是真正的公理**：
   `Funext` 只是它的载体，`Print Assumptions` 里两者都会列出来。
10. **`ap10` 不需要任何公理**，`path_arrow`（反方向）才需要。
11. **`equiv_path_equiv` 的打印两侧看似相同**，
    左边其实是逐点相等的展开；不要以为它是恒等定理。
12. **函数外延可以由区间 HIT 证明**（第 12 章），
    那时 `Print Assumptions` 里出现的是 `seg` 而不是 `Funext`。

---

**上一章**：[09 截断层级](docs/09-truncation.md)
**下一章**：[11 泛等公理 —— 等价就是相等](docs/11-univalence.md)
