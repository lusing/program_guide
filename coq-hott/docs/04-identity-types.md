# 04 恒等类型与路径归纳

> 对应示例：`examples/04_identity_types.v`（编译验证通过）

这一章是整个 HoTT 的引擎室。**路径归纳（J 消去子）是唯一的武器**，
后面所有关于路径的结论——拼接、逆、`ap`、`transport`——都由它派生。

## 4.1 `paths` 的真身

```coq
Print paths.
Check idpath.
Check paths_ind.
Check paths_rec.
```

```text
Inductive paths@{u} (A : Type) (a : A) : A -> Type :=  idpath : a = a.

Arguments paths {A}%_type_scope a _
Arguments idpath {A}%_type_scope {a}, [_] _
1
     : ?a = ?a
where
?A : [ |- Type]
?a : [ |- ?A]
paths_ind
     : forall (A : Type) (a : A) (P : forall a0 : A, a = a0 -> Type),
       P a 1 -> forall (y : A) (p : a = y), P y p
paths_rec
     : forall (A : Type) (a : A) (P : A -> Type),
       P a -> forall y : A, a = y -> P y
```

`paths` 是一个**索引**归纳族：参数 `A : Type` 与 `a : A`，索引是终点。
只有一个构造子 `idpath : a = a`，因此：

> 要证 `forall (y : A) (p : a = y), P y p`，只需证 `P a 1`。

这就是 `paths_ind`（J）。非依赖版本 `paths_rec` 更简单：
要证 `forall y, a = y -> P y`，只需证 `P a`。

## 4.2 路径归纳（J）能干什么

所有"对所有路径成立"的命题，都只要证 `1` 的情形。
反向、拼接、`ap` 全部由它派生。自己实现一次逆路径：

```coq
Definition my_inverse {A : Type} {x y : A} (p : x = y) : y = x.
Proof.
  destruct p; reflexivity.
Defined.
```

自己实现一次拼接：

```coq
Definition my_concat {A : Type} {x y z : A} (p : x = y) (q : y = z) : x = z.
Proof.
  destruct p, q; reflexivity.
Defined.
```

```text
my_inverse
     : ?x = ?y -> ?y = ?x
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
my_concat
     : ?x = ?y -> ?y = ?z -> ?x = ?z
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
```

库里的版本与自己写的在 `1` 上行为一致：

```coq
Definition my_inverse_is_inverse {A : Type} {x y : A} (p : x = y)
  : my_inverse p = p^.
Proof.
  destruct p; reflexivity.
Defined.
```

```text
my_inverse_is_inverse
     : forall p : ?x = ?y, my_inverse p = p^
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

> **证明节奏**：HoTT 里绝大多数关于路径的证明都是
> `destruct p; ...; reflexivity`。这行代码就是"路径归纳"这四个字。

## 4.3 `ap`：函数作用在路径上

```coq
Check ap.
Print ap.
```

```text
ap
     : forall (f : ?A -> ?B) (x y : ?A), x = y -> f x = f y
where
?A : [ |- Type]
?B : [ |- Type]
ap@{u u0} =
fun (A B : Type) (f : A -> B) (x y : A) (p : x = y) =>
match p in _ = a return f x = f a with
| 1 => 1
end
     : forall {A B : Type} (f : A -> B) {x y : A}, x = y -> f x = f y

Arguments ap {A B}%_type_scope f%_function_scope {x y}
  p%_path_scope : simpl nomatch
```

看清楚定义体：它就是一个 `match p`，所以 `ap` 也是路径归纳的产物。

`ap` 的函子性——保持单位元、拼接、逆、复合：

```coq
Check ap_idpath.   (* ap f 1 = 1 *)
Check ap_1.
Check ap_pp.       (* ap f (p @ q) = ap f p @ ap f q *)
Check ap_V.        (* ap f p^ = (ap f p)^ *)
Check ap_compose.  (* ap (g o f) p = ap g (ap f p) *)
Check ap_idmap.    (* ap idmap p = p *)
Check ap_const.    (* ap (fun _ => z) p = 1 *)
```

```text
ap_pp
     : forall (f : ?A -> ?B) (x y z : ?A) (p : x = y) 
       (q : y = z), ap f (p @ q) = ap f p @ ap f q
where
?A : [ |- Type]
?B : [ |- Type]
```

一个具体例子：`ap S` 把 `2 = 2` 送到 `3 = 3`。

```coq
Check (ap S (1 : (2%nat) = 2%nat)).
Compute (ap S (1 : (2%nat) = 2%nat)).
```

```text
ap S (1 : 2%nat = 2%nat)
     : 3%nat = 3%nat
     = 1
     : 3%nat = 3%nat
```

## 4.4 `apD`：依赖函数的情形

```coq
Check apD.
Print apD.
```

```text
apD
     : forall (f : forall a : ?A, ?B a) (x y : ?A) 
       (p : x = y), transport ?B p (f x) = f y
where
?A : [ |- Type]
?B : [ |- ?A -> Type]
apD@{u u0} =
fun (A : Type) (B : A -> Type) (f : forall a : A, B a) (x y : A) (p : x = y) =>
match p as p0 in _ = a return transport B p0 (f x) = f a with
| 1 => 1
end
     : forall {A : Type} {B : A -> Type} (f : forall a : A, B a) 
       {x y : A} (p : x = y), transport B p (f x) = f y

Arguments apD {A}%_type_scope {B} f%_function_scope 
  {x y} p%_path_scope : simpl nomatch
```

依赖函数 `f : forall x, B x` 作用在 `p : x = y` 上得到的是
`transport B p (f x) = f y`，**而不是**简单的 `f x = f y`——
因为两边的类型不同，必须先把左边搬到右边所在的纤维里。

`transport` 是第 05 章的主角，这里先认识它的存在。

## 4.5 路径归纳的几个标准推论

单位元律：

```coq
Check concat_p1.   (* p @ 1 = p *)
Check concat_1p.   (* 1 @ p = p *)
```

抵消律：

```coq
Check concat_pV.   (* p @ p^ = 1 *)
Check concat_Vp.   (* p^ @ p = 1 *)
Check concat_pV_p.
Check concat_V_pp. (* p^ @ (p @ q) = q *)
Check concat_pp_V.
```

逆的运算律：

```coq
Check inv_pp.      (* (p @ q)^ = q^ @ p^ *)
Check inv_V.       (* (p^)^ = p *)
Check inv_VV.
```

自己证一次 `p @ 1 = p`，体会"只剩 `1` 的情形"：

```coq
Definition my_concat_p1 {A : Type} {x y : A} (p : x = y) : p @ 1 = p.
Proof.
  destruct p; reflexivity.
Defined.

Definition my_concat_p1_matches {A : Type} {x y : A} (p : x = y)
  : my_concat_p1 p = concat_p1 p.
Proof.
  destruct p; reflexivity.
Defined.
```

```text
my_concat_p1
     : forall p : ?x = ?y, p @ 1 = p
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
my_concat_p1_matches
     : forall p : ?x = ?y, my_concat_p1 p = concat_p1 p
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

`destruct p` 之后目标变成 `1 @ 1 = 1`，`reflexivity` 直接关掉——
两者都归约到 `1`，所以第二条也成立。

## 4.6 恒等类型不是布尔值

标准 Coq 有 UIP（同一等式的两个证明必相等），HoTT 里**没有**。
能证 UIP 的类型叫 h-set（第 09 章），而 `Type` 本身甚至不是集合
（第 11 章会看到 `not_hset_Type`）。

我们**不能**证明 `forall (p q : x = y), p = q`，只能把它当作假设：

```coq
Definition UIP_statement (A : Type) : Type := forall x y : A, IsHProp (x = y).
Check UIP_statement.
```

对 `Unit` 这种可缩类型，它成立：

```coq
Definition uip_unit : UIP_statement Unit.
Proof.
  intros x y; destruct x, y; exact _.
Defined.
```

```text
UIP_statement
     : Type -> Type
uip_unit
     : UIP_statement Unit
```

`exact _` 让类型类搜索去找 `IsHProp (tt = tt)`——
`Unit` 是集合，所以能找到。

## 本章坑位清单

1. **不要指望 UIP**：`forall p q : x = y, p = q` 在 HoTT 里不可证，
   只能作为 `IsHSet` 假设引入。
2. **`destruct p` 就是路径归纳**：`destruct p; reflexivity` 是最高频的两行。
3. **`ap` 与 `apD` 的类型不同**：`ap` 给 `f x = f y`，
   `apD` 给 `transport B p (f x) = f y`。依赖函数必须用后者。
4. **`concat_p1` 与 `concat_1p` 是两条不同的引理**，
   方向相反，别记混（前者是 `p @ 1 = p`）。
5. **`inv_pp` 的反方向是 `inv_VV` 而不是再写一遍 `inv_pp`**：
   `(p @ q)^ = q^ @ p^` 取逆要用 `inv_VV`。
6. **`Check (ap S (1 : (2%nat) = 2%nat))` 里的类型标注不能省**，
   否则 `1` 会被解析成 `nat` 或 `equiv_idmap`。
7. **`reflexivity` 在本库里被重定向到 `idpath`**，
   所以它的行为和标准 Coq 略有不同（不会尝试 `eq_refl`）。
8. **`paths_ind` 与 `paths_rec` 的参数顺序不同**：
   `paths_ind` 要一个依赖到路径的谓词，`paths_rec` 只依赖终点。
9. **`exact _` 依赖类型类搜索**：`uip_unit` 里靠它找 `IsHProp`，
   若目标不是 h-prop 就会失败并给出很晦涩的报错。
10. **`ap_const` 说的是"常值函数把任何路径送到 `1`"**：
    这是证明"某条路径平凡"的常用手段。
11. **`ap` 的参数 `x y` 是隐式的**：`ap f p` 就够，
    写全参数时要按 `ap (f := ...) p` 的形式。
12. **本文件 `Local Open Scope path_scope`**：
    不开这个 scope，`@` 与 `^` 就不是路径拼接与取逆。

---

**上一章**：[03 依赖类型](docs/03-dependent-types.md)
**下一章**：[05 Transport —— 沿路径搬运纤维](docs/05-transport.md)
