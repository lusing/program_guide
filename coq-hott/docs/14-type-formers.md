# 14 类型构造器的路径与等价

> 对应示例：`examples/14_type_formers.v`（编译验证通过）

"两个元素相等是什么意思？"这个问题的答案**依赖于它们所在的类型构造器**。
本章逐个走一遍：乘积、Σ、和、函数类型。

## 14.1 乘积里的路径 = 分量的路径对

```coq
Check path_prod.
Check path_prod_uncurried.
Check equiv_path_prod.
```

```text
path_prod
     : forall z z' : ?A * ?B, fst z = fst z' -> snd z = snd z' -> z = z'
where
?A : [ |- Type]
?B : [ |- Type]
path_prod_uncurried
     : forall z z' : ?A * ?B, (fst z = fst z') * (snd z = snd z') -> z = z'
where
?A : [ |- Type]
?B : [ |- Type]
equiv_path_prod
     : forall z z' : ?A * ?B, (fst z = fst z') * (snd z = snd z') <~> z = z'
where
?A : [ |- Type]
?B : [ |- Type]
```

`(a,b) = (a',b') ≃ (a = a') × (b = b')`。

```coq
Definition my_path_prod {A B : Type} (x y : A * B)
  : (fst x = fst y) * (snd x = snd y) -> x = y
  := equiv_path_prod x y.

Definition prod_path_example : (true, 3%nat) = (true, 3%nat)
  := path_prod _ _ 1 1.
```

```text
my_path_prod
     : forall x y : ?A * ?B, (fst x = fst y) * (snd x = snd y) -> x = y
where
?A : [ |- Type]
?B : [ |- Type]
prod_path_example
     : (true, 3%nat) = (true, 3%nat)
```

## 14.2 Σ 类型里的路径 = 底分量路径 + 依赖分量路径

```coq
Check path_sigma.
Check path_sigma_uncurried.
Check equiv_path_sigma.
```

```text
path_sigma
     : forall (P : ?A -> Type) (u v : {x : _ & P x}) 
       (p : u.1 = v.1), transport P p u.2 = v.2 -> u = v
where
?A : [ |- Type]
path_sigma_uncurried
     : forall (P : ?A -> Type) (u v : {x : _ & P x}),
       {p : u.1 = v.1 & transport P p u.2 = v.2} -> u = v
where
?A : [ |- Type]
equiv_path_sigma
     : forall (P : ?A -> Type) (u v : {x : _ & P x}),
       {p : u.1 = v.1 & transport P p u.2 = v.2} <~> u = v
where
?A : [ |- Type]
?B : [ |- Type]
```

这里第二分量必须是一条**依赖**路径（先 `transport` 再相等），
这正是 Σ 与普通乘积的区别。

配套的分解与 η 律：

```coq
Check pr1_path.
Check pr2_path.
Check eta_path_sigma.
```

```text
pr1_path
     : ?u = ?v -> ?u.1 = ?v.1
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
?u : [ |- {x : _ & ?P x}]
?v : [ |- {x : _ & ?P x}]
pr2_path
     : forall p : ?u = ?v, transport ?P p ..1 ?u.2 = ?v.2
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
?u : [ |- {x : _ & ?P x}]
?v : [ |- {x : _ & ?P x}]
eta_path_sigma
     : forall p : ?u = ?v, path_sigma ?P ?u ?v p ..1 p ..2 = p
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
?u : [ |- {x : _ & ?P x}]
?v : [ |- {x : _ & ?P x}]
```

`eta_path_sigma` 说：把路径拆成两部分再用 `path_sigma` 拼回去，等于原路径。

## 14.3 和类型里的路径 = 同侧且分量相等

```coq
Check path_sum.
Check path_sum_inl.
Check path_sum_inr.
Check equiv_path_sum.
Check inl_ne_inr.
Check inr_ne_inl.
```

```text
path_sum
     : code_sum ?z ?z' -> ?z = ?z'
where
?A : [ |- Type]
?B : [ |- Type]
?z : [ |- ?A + ?B]
?z' : [ |- ?A + ?B]
path_sum_inl
     : forall (B : Type) (x x' : ?A), inl x = inl x' -> x = x'
where
?A : [ |- Type]
inl_ne_inr
     : forall (a : ?A) (b : ?B), inl a <> inr b
where
?A : [ |- Type]
?B : [ |- Type]
```

`inl a ≠ inr b`：两侧之间没有任何路径。这是 `transport` 的经典用法，
思路见第 05 章。

> **坑**：`path_sum_inl` 的方向是"从 `inl x = inl x'` 拿回 `x = x'`"，
> 是**消去**方向。造路径要用 `ap inl` 或 `path_sum`：

```coq
Definition sum_path_example {A B : Type} (a a' : A) (p : a = a')
  : (inl a : A + B) = inl a'
  := ap (fun x : A => (inl x : A + B)) p.
```

```text
sum_path_example
     : forall a a' : ?A, a = a' -> inl a = inl a'
where
?A : [ |- Type]
?B : [ |- Type]
```

## 14.4 函数类型里的路径 = 逐点路径（需要 `Funext`）

```coq
Check path_arrow.
Check equiv_path_arrow.
Check ap10_path_arrow.
```

```text
path_arrow
     : forall f g : ?A -> ?B, f == g -> f = g
where
?H : [ |- Funext]
?A : [ |- Type]
?B : [ |- Type]
equiv_path_arrow
     : forall f g : ?A -> ?B, f == g <~> f = g
where
?H : [ |- Funext]
?A : [ |- Type]
?B : [ |- Type]
ap10_path_arrow
     : forall (f g : ?A -> ?B) (h : f == g), ap10 (path_arrow f g h) == h
where
?H : [ |- Funext]
?A : [ |- Type]
?B : [ |- Type]
```

不需要 `Funext` 就能用的方向（逐点化，`ap10`）与需要 `Funext` 的方向
在这里对称地摆着——详见第 10 章。

## 14.5 类型构造器都是"等价函子"

`equiv_functor_*` 系列：等价可以穿过类型构造器。

```coq
Check equiv_functor_sigma.
Check equiv_functor_prod.
Check equiv_functor_prod'.
Check equiv_functor_sum.
Check equiv_functor_arrow.
```

```text
equiv_functor_prod'
     : ?A <~> ?A' -> ?B <~> ?B' -> ?A * ?B <~> ?A' * ?B'
where
?A : [ |- Type]
?A' : [ |- Type]
?B : [ |- Type]
?B' : [ |- Type]
equiv_functor_arrow
     : (?A -> ?C) <~> (?B -> ?D)
where
?H : [ |- Funext]
?B : [ |- Type]
?A : [ |- Type]
?f : [ |- ?B -> ?A]
?H0 : [ |- IsEquiv ?f]
?C : [ |- Type]
?D : [ |- Type]
?g : [ |- ?C -> ?D]
?H1 : [ |- IsEquiv ?g]
```

例子：若 `A ≃ A'`、`B ≃ B'`，则 `A * B ≃ A' * B'`。
这里取 `Bool` 上的取反作为两端：

```coq
Definition prod_equiv_example : (Bool * Bool) <~> (Bool * Bool)
  := equiv_functor_prod' negb_equiv negb_equiv.
Check prod_equiv_example.
Compute prod_equiv_example (true, false).
```

```text
prod_equiv_example
     : Bool * Bool <~> Bool * Bool
     = (false, true)
     : Bool * Bool
```

## 14.6 一个完整的练习：Σ 与乘积的互换

常值纤维的 Σ 就是乘积：`{ _ : A & B } ≃ A * B`。

```coq
Check equiv_sigma_prod.
Check equiv_sigma_contr.
Check equiv_pr1.
```

```text
equiv_sigma_prod
     : forall Q : ?A * ?B -> Type,
       {a : ?A & {b : ?B & Q (a, b)}} <~> {x : _ & Q x}
where
?A : [ |- Type]
?B : [ |- Type]
equiv_sigma_contr
     : forall P : ?A -> Type,
       (forall a : ?A, Contr (P a)) -> {x : _ & P x} <~> ?A
where
?A : [ |- Type]
equiv_pr1
     : forall P : ?A -> Type,
       (forall x : ?A, Contr (P x)) -> {x : ?A & P x} <~> ?A
where
?A : [ |- Type]
```

练习：证明 `A * Unit ≃ A`。

```coq
Definition prod_unit_r (A : Type) : A * Unit <~> A.
Proof.
  make_equiv.
Defined.
Check prod_unit_r.
Compute prod_unit_r Bool (true, tt).
```

```text
prod_unit_r
     : forall A : Type, A * Unit <~> A
     = true
     : Bool
```

## 本章坑位清单

1. **`path_sum_inl` 是消去方向不是构造方向**：
   造路径要写 `ap (fun x => (inl x : A + B)) p`。
2. **`path_sigma` 的第二参数必须是依赖路径** `transport P p u.2 = v.2`，
   不是 `u.2 = v.2`。
3. **`path_prod` 的两个参数顺序**：先 `fst` 后 `snd`。
4. **`equiv_functor_prod` 与 `equiv_functor_prod'` 不同**：
   前者接受"函数 + IsEquiv"，后者接受两个 `A <~> B`。
5. **`equiv_functor_arrow` 需要 `Funext`**，
   而且是**逆变**的：`(A -> C) ≃ (B -> D)` 需要 `B <~> A` 与 `C <~> D`。
6. **`make_equiv` 对简单目标很好用**，复杂目标会搜不出来。
7. **`pr2_path` 的打印里有 `..1` 与 `..2`**，
   这是 pretty-printer 对隐式参数的省略，等价于 `.1` / `.2`。
8. **`inl_ne_inr` 与 `inr_ne_inl` 是两条独立的定理**，
   因为 `<>` 不对称（其实可互换，但库都给了）。
9. **`equiv_path_sum` 用的是 `code_sum`** 而不是"同侧 + 相等"的朴素形式：
   `code_sum` 是编码函数，跨侧时给出 `Empty`。
10. **`eta_path_sigma` 是 Σ 的 η 律**，
   证明"两条 Σ 上的路径相等"时常用它把路径拆开。
11. **`path_arrow` 需要 `Funext` 实例**，
    本章示例没有导入公理，所以只 `Check` 不构造。
12. **`Compute` 对等价的应用**：`Compute prod_equiv_example (true, false)`
    给出 `(false, true)`——两个分量都被取反了。

---

**上一章**：[13 圆 S¹ 与编码-解码](docs/13-circle.md)
**下一章**：[15 截断操作 —— `Tr`、`merely` 与连通性](docs/15-truncations.md)
