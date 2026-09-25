# 05 Transport —— 沿路径搬运纤维

> 对应示例：`examples/05_transport.v`（编译验证通过）

如果说路径归纳是引擎，那 `transport` 就是方向盘。
它是"依赖类型"这件事的必然产物：既然 `P x` 与 `P y` 是**不同类型**，
那么沿 `p : x = y` 把 `u : P x` 变成 `P y` 的元素就需要一个操作。

## 5.1 `transport` 是什么

```coq
Check transport.
Print transport.
```

```text
transport
     : forall (P : ?A -> Type) (x y : ?A), x = y -> P x -> P y
where
?A : [ |- Type]
transport@{u u0} =
fun (A : Type) (P : A -> Type) (x y : A) (p : x = y) (u : P x) =>
match p in _ = a return P a with
| 1 => u
end
     : forall {A : Type} (P : A -> Type) {x y : A}, x = y -> P x -> P y

Arguments transport {A}%_type_scope P%_function_scope 
  {x y} p%_path_scope u : simpl nomatch
```

给定 `P : A -> Type`、`p : x = y`、`u : P x`，得到
`transport P p u : P y`。直觉：把 `u` 沿着 `p` **平行移动**到 `y` 上方的纤维里。

它的定义就是路径归纳——`p` 是 `1` 时什么都不做。
注意 `Arguments` 里的 `simpl nomatch`：`simpl` 时不会把它展开成 `match`。

## 5.2 沿常值族搬运：什么都没发生

```coq
Check transport_const.
```

```text
transport_const
     : forall (p : ?x1 = ?x2) (y : ?B), transport (fun _ : ?A => ?B) p y = y
where
?A : [ |- Type]
?B : [ |- Type]
?x1 : [ |- ?A]
?x2 : [ |- ?A]
```

当 `P` 不依赖底空间时，搬运只是一条路径 `y = y'`：

```coq
Definition transport_const_example (p : true = false) (u : nat)
  : transport (fun _ : Bool => nat) p u = u
  := transport_const p u.
```

```text
transport_const_example
     : forall (p : true = false) (u : nat),
       transport (fun _ : Bool => nat) p u = u
```

## 5.3 搬运的函子性：拼接、逆

```coq
Check transport_pp.      (* 先后搬运 = 一次性搬运 *)
Check transport_pV.      (* 沿 p 再沿 p^ 回到原处 *)
Check transport_Vp.
Check transport_pVp.
Check transport_VpV.
Check transport_compose.
Check transport2.
```

```text
transport_pp
     : forall (P : ?A -> Type) (x y z : ?A) (p : x = y) 
       (q : y = z) (u : P x),
       transport P (p @ q) u = transport P q (transport P p u)
where
?A : [ |- Type]
transport_pV
     : forall (P : ?A -> Type) (x y : ?A) (p : x = y) 
       (z : P y), transport P p (transport P p^ z) = z
where
?A : [ |- Type]
transport_compose
     : forall (P : ?B -> Type) (f : ?A -> ?B) (p : ?x = ?y) 
       (z : P (f ?x)),
       transport (fun x : ?A => P (f x)) p z = transport P (ap f p) z
where
?A : [ |- Type]
?B : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

`transport_compose` 是本教程最常用的一条：它把
"沿复合族 `P ∘ f` 搬运"改写成"沿 `ap f p` 在 `P` 里搬运"。
第 13 章与第 24 章的覆叠证明全靠它打头。

`transport2` 说的是"搬运只依赖路径本身"：

```text
transport2
     : forall (P : ?A -> Type) (x y : ?A) (p q : x = y),
       p = q -> forall z : P x, transport P p z = transport P q z
```

## 5.4 `apD` 就是"依赖函数的搬运"

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
```

`apD f p : transport B p (f x) = f y`，而普通 `ap f p : f x = f y`；
常值族下两者通过 `transport_const` 联系在一起：

```coq
Check apD_const.
```

```text
apD_const
     : forall (f : ?A -> ?B) (p : ?x = ?y),
       apD f p = transport_const p (f ?x) @ ap f p
where
?A : [ |- Type]
?B : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

即 `apD = transport_const @ ap`：先（平凡地）搬运，再作用 `ap`。

## 5.5 用 transport 证明不等：经典的 `true ≠ false`

构造一个族：`true` 上是 `Unit`，`false` 上是 `Empty`。

```coq
Definition bool_code (b : Bool) : Type := if b then Unit else Empty.
Compute bool_code true.
Compute bool_code false.
```

```text
     = Unit
     : Type
     = Empty
     : Type
```

若 `true = false`，则 `Unit` 的居民 `tt` 会被搬到 `Empty` 里——
矛盾：

```coq
Definition true_ne_false_by_transport (p : true = false) : Empty
  := transport bool_code p tt.

Definition my_true_ne_false : true <> false := true_ne_false_by_transport.
Check true_ne_false.
```

```text
true_ne_false_by_transport
     : true = false -> Empty
my_true_ne_false
     : true <> false
true_ne_false
     : true <> false
```

> **这个套路要记牢**：造一个"两端纤维不同构"的族，
> 用 `transport` 把一端的居民搬到另一端，矛盾就出来了。
> 第 13 章证明 `loop ≠ 1`、第 24 章证明环路非平凡，用的都是它。

## 5.6 依赖路径与 `transport_paths_*` 家族

当纤维本身是一个**路径类型**时，"搬运后的路径"可以显式算出来。
这是 HoTT 里最常用也最容易算错的一组引理。
命名规则：`l` 左端点变、`r` 右端点变、`F` 端点上还套着函数。

```coq
Check transport_paths_l.
Check transport_paths_r.
Check transport_paths_lr.
Check transport_paths_Fl.
Check transport_paths_Fr.
Check transport_paths_FlFr.
```

```text
transport_paths_l
     : forall (p : ?x1 = ?x2) (q : ?x1 = ?y),
       transport (fun x : ?A => x = ?y) p q = p^ @ q
where
?A : [ |- Type]
?x1 : [ |- ?A]
?x2 : [ |- ?A]
?y : [ |- ?A]
transport_paths_r
     : forall (p : ?y1 = ?y2) (q : ?x = ?y1),
       transport (fun y : ?A => ?x = y) p q = q @ p
where
?A : [ |- Type]
?x : [ |- ?A]
?y1 : [ |- ?A]
?y2 : [ |- ?A]
transport_paths_lr
     : forall (p : ?x1 = ?x2) (q : ?x1 = ?x1),
       transport (fun x : ?A => x = x) p q = (p^ @ q) @ p
where
?A : [ |- Type]
?x1 : [ |- ?A]
?x2 : [ |- ?A]
transport_paths_FlFr
     : forall (p : ?x1 = ?x2) (q : ?f ?x1 = ?g ?x1),
       transport (fun x : ?A => ?f x = ?g x) p q = ((ap ?f p)^ @ q) @ ap ?g p
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?g : [ |- ?A -> ?B]
?x1 : [ |- ?A]
?x2 : [ |- ?A]
```

口诀：**左端变就左乘 `p^`，右端变就右乘 `p`，端点上套了函数就再 `ap` 一下。**

### 移项术 `moveR` / `moveL`

与之配套的是"移项"引理，把 `transport P p u = v` 与
`u = transport P p^ v` 等价起来：

```coq
Check moveR_transport_p.
Check moveL_transport_V.
Check moveR_transport_V.
Check moveL_transport_p.
```

```text
moveR_transport_p
     : forall (P : ?A -> Type) (x y : ?A) (p : x = y) 
       (u : P x) (v : P y), u = transport P p^ v -> transport P p u = v
where
?A : [ |- Type]
moveL_transport_V
     : forall (P : ?A -> Type) (x y : ?A) (p : x = y) 
       (u : P x) (v : P y), transport P p u = v -> u = transport P p^ v
where
?A : [ |- Type]
```

### 一个具体使用：`pr1` 在 Σ 类型路径上的行为

```coq
Check pr1_path.
Check transport_pr1_path_sigma.
```

```text
pr1_path
     : ?u = ?v -> ?u.1 = ?v.1
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
?u : [ |- {x : _ & ?P x}]
?v : [ |- {x : _ & ?P x}]
transport_pr1_path_sigma
     : forall (p : ?u.1 = ?v.1) (q : transport ?P p ?u.2 = ?v.2)
       (Q : ?A -> Type),
       transport (fun x : {x : _ & ?P x} => Q x.1) (path_sigma ?P ?u ?v p q) =
       transport Q p
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
?u : [ |- {x : _ & ?P x}]
?v : [ |- {x : _ & ?P x}]
```

最后一条是这个家族里最"贵"的：它说"沿 Σ 上的一条路径搬运一个只依赖
第一分量的东西，等于沿底空间那条路径搬运"。Σ 的路径结构详见第 14 章。

## 本章坑位清单

1. **`transport` 的 `A`、`x`、`y` 都是隐式参数**，只写 `transport P p u`；
   要显式给时按 `transport (A := ...) P ...` 的形式。
2. **不要指望 `simpl` 展开 `transport`**：它的 `Arguments` 带
   `simpl nomatch`，`p` 不是具体路径时 `simpl` 不动它。
3. **`transport_const` 只在族真的不依赖底空间时可用**：
   族里出现 `x` 就不能用，别硬套。
4. **`transport_pp` 的右端是"先 p 后 q"的嵌套**，
   写反了会得到类型不符而不是报错提示。
5. **证明不等的标准套路是"造族 + transport"**，
   不是 `discriminate`（HoTT 里没有这个 tactic 的等价物）。
6. **`transport_paths_*` 家族命名有规律**：`l` / `r` / `lr` 指哪个端点变，
   `F` 指端点上套了函数。记不住就 `Check` 一遍。
7. **`moveR` / `moveL` 的方向极易搞反**：`moveR_*` 的结论是
   `transport P p u = v`，`moveL_*` 的结论是 `u = transport P p^ v`。
8. **`apD_const` 说明 `apD = transport_const @ ap`**：
   在常值族下两者只差一条平凡路径。
9. **`transport_compose` 是覆叠类证明的起手式**：
   第 13、24 章的 `transport (Circle_rec ...) loop` 全靠它拆开。
10. **`bool_code` 这种"if 分叉族"是最省事的判别族**：
    想证 `a ≠ b` 就造一个 `a` 上为 `Unit`、`b` 上为 `Empty` 的族。
11. **`transport2` 说的是搬运对路径本身的函子性**，
    即 `p = q` 蕴含 `transport P p z = transport P q z`。
12. **`x <> y` 只是 `x = y -> Empty` 的记号**，
    所以 `intro h; apply true_ne_false` 这种写法是把目标换成 `true = false`。

---

**上一章**：[04 恒等类型与路径归纳](docs/04-identity-types.md)
**下一章**：[06 路径代数 —— 群胚律与移项术](docs/06-path-algebra.md)
