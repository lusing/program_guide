# 07 等价 —— `A <~> B`

> 对应示例：`examples/07_equivalences.v`（编译验证通过）

在 HoTT 里"两个类型一样"的正确含义**不是**同构，而是**等价**
（有双-sided 逆的映射）。等价是这本教材的中心概念：
泛等公理说的就是"等价 = 相等"。

## 7.1 `IsEquiv` 与 `Equiv` 的结构

```coq
Print IsEquiv.
Print Equiv.
Locate "<~>".
```

```text
Record IsEquiv@{u u0} (A B : Type) (f : A -> B) : Type := Build_IsEquiv
  { equiv_inv : B -> A;
    eisretr : f o equiv_inv == idmap;
    eissect : equiv_inv o f == idmap;
    eisadj : forall x : A, eisretr (f x) = ap f (eissect x) }.

IsEquiv has primitive projections with eta conversion.
Arguments IsEquiv {A B}%_type_scope f%_function_scope
Arguments Build_IsEquiv (A B)%_type_scope (f equiv_inv)%_function_scope
  eisretr eissect eisadj%_function_scope
Arguments equiv_inv {A B}%_type_scope {f}%_function_scope {IsEquiv} _
Arguments eisretr {A B}%_type_scope f%_function_scope {IsEquiv} x
Arguments eissect {A B}%_type_scope f%_function_scope {IsEquiv} x
Arguments eisadj {A B}%_type_scope f%_function_scope {IsEquiv} x
Record Equiv@{u u0} (A B : Type) : Type := Build_Equiv
  { equiv_fun : A -> B;  equiv_isequiv : IsEquiv equiv_fun }.

Equiv has primitive projections with eta conversion.
Notation "A <~> B" := (Equiv A B)
  (* A in scope _type_scope, B in scope _type_scope *) : type_scope
  (default interpretation) (from HoTT.Basics.Overture)
```

`IsEquiv f` 是一个类型类，装了四份数据：

| 字段 | 含义 |
|---|---|
| `equiv_inv` | 反函数 `B -> A` |
| `eisretr` | `f o f^-1 == idmap`（右逆 / section 方向） |
| `eissect` | `f^-1 o f == idmap`（左逆 / retraction 方向） |
| `eisadj` | 两者相容（伴随律） |

最后一条让"半等价"升级为**伴随等价**（adjoint equivalence），
这是本库采用的定义——它比"只是有左右逆"更强，但性质更好。

```coq
Check equiv_inv.
Check eisretr.
Check eissect.
Check eisadj.
```

```text
?f^-1%function
     : ?B -> ?A
where
?A : [ |- Type]
?B : [ |- Type]
?IsEquiv : [ |- IsEquiv ?f]
eisretr
     : forall (f : ?A -> ?B) (IsEquiv : Overture.IsEquiv f),
       (fun x : ?B => f (f^-1%function x)) == idmap
where
?A : [ |- Type]
?B : [ |- Type]
eissect
     : forall (f : ?A -> ?B) (IsEquiv : Overture.IsEquiv f),
       (fun x : ?A => f^-1%function (f x)) == idmap
where
?A : [ |- Type]
?B : [ |- Type]
```

`Equiv A B` 把函数与它的 `IsEquiv` 证据打包，可强制转换为函数：

```coq
Check equiv_fun.
Check (fun (A B : Type) (e : A <~> B) => e : A -> B).
```

```text
equiv_fun
     : ?A <~> ?B -> ?A -> ?B
where
?A : [ |- Type]
?B : [ |- Type]
fun (A B : Type) (e : A <~> B) => e : A -> B
     : forall A B : Type, A <~> B -> A -> B
```

## 7.2 由左右逆构造等价：伴随化

```coq
Check isequiv_adjointify.
Check equiv_adjointify.
```

```text
isequiv_adjointify
     : forall (f : ?A -> ?B) (g : ?B -> ?A),
       (fun x : ?B => f (g x)) == idmap ->
       (fun x : ?A => g (f x)) == idmap -> IsEquiv f
where
?A : [ |- Type]
?B : [ |- Type]
equiv_adjointify
     : forall (f : ?A -> ?B) (g : ?B -> ?A),
       (fun x : ?B => f (g x)) == idmap ->
       (fun x : ?A => g (f x)) == idmap -> ?A <~> ?B
where
?A : [ |- Type]
?B : [ |- Type]
```

只需要给两个同伦（左右逆），伴随律由 `isequiv_adjointify` 自动补上。
经典例子——布尔取反：

```coq
Definition equiv_bool_neg : Bool <~> Bool.
Proof.
  refine (equiv_adjointify negb negb _ _).
  - intro b; destruct b; reflexivity.
  - intro b; destruct b; reflexivity.
Defined.
Check equiv_bool_neg.
Compute equiv_bool_neg true.
Compute equiv_bool_neg false.
Compute equiv_bool_neg^-1 true.
```

```text
equiv_bool_neg
     : Bool <~> Bool
     = false
     : Bool
     = true
     : Bool
     = false
     : Bool
```

反函数用 `^-1` 取（`function_scope` 里的记号）。

> **`make_equiv` 这个 tactic**能自动收拾"给反函数 + 两个同伦"的证明，
> 见 7.5。

## 7.3 等价构成一个群胚

```coq
Check equiv_idmap.
Check equiv_compose.
Check equiv_inverse.
Locate "oE".
```

```text
1%equiv
     : ?A <~> ?A
where
?A : [ |- Type]
equiv_compose
     : forall (g : ?B -> ?C) (f : ?A -> ?B),
       IsEquiv g -> IsEquiv f -> ?A <~> ?C
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
equiv_inverse
     : ?A <~> ?B -> ?B <~> ?A
where
?A : [ |- Type]
?B : [ |- Type]
```

复合与取逆都是等价：

```coq
Check (equiv_compose' equiv_bool_neg equiv_bool_neg).
Compute (equiv_compose' equiv_bool_neg equiv_bool_neg) true.
```

```text
equiv_bool_neg oE equiv_bool_neg
     : Bool <~> Bool
     = true
     : Bool
```

取反两次是恒等，所以结果是 `true` ✓。

等价的逆的逆是自己（在 `==` 的意义下）：

```coq
Check equiv_inverse_compose.
```

```text
equiv_inverse_compose
     : forall (f : ?A <~> ?B) (g : ?B <~> ?C), (g oE f)^-1 == f^-1 oE g^-1
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
```

## 7.4 `ap` 保持等价

```coq
Check isequiv_ap.
Check equiv_ap.
```

```text
isequiv_ap
     : forall x y : ?A, IsEquiv (ap ?f)
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?H : [ |- IsEquiv ?f]
equiv_ap
     : forall f : ?A -> ?B, IsEquiv f -> forall x y : ?A, x = y <~> f x = f y
where
?A : [ |- Type]
?B : [ |- Type]
```

若 `f` 是等价，则 `ap f : (x = y) -> (f x = f y)` 也是等价。
这条在编码-解码证明（第 13 章）里反复用到。

## 7.5 手写几个常见等价

积的交换。`make_equiv` 这个 tactic 能自动把"给出反函数 + 两个同伦"
的证明收拾干净：

```coq
Definition my_prod_symm (A B : Type) : A * B <~> B * A.
Proof.
  make_equiv.
Defined.
Check my_prod_symm.
Compute (my_prod_symm Bool nat (true, 3%nat)).
```

```text
my_prod_symm
     : forall A B : Type, A * B <~> B * A
     = (3%nat, true)
     : nat * Bool
```

库里的现成版本与函子版本：

```coq
Check equiv_prod_symm.
Check equiv_sigma_symm.
Check equiv_functor_sigma.
Check equiv_functor_prod.
Check equiv_functor_sum.
```

```text
equiv_functor_sigma
     : forall f : ?A -> ?B,
       IsEquiv f ->
       forall g : forall a : ?A, ?P a -> ?Q (f a),
       (forall a : ?A, IsEquiv (g a)) -> {x : _ & ?P x} <~> {x : _ & ?Q x}
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
?B : [ |- Type]
?Q : [ |- ?B -> Type]
```

> "等价可以穿过类型构造器"这件事是第 14 章与第 18 章的支柱。

## 7.6 等价 vs 可缩纤维

`f : A -> B` 是等价，**当且仅当**它的每个同伦纤维 `hfiber f b` 可缩。
这是判定等价最常用的手段，详见第 08 章。

```coq
Check hfiber.
Check contr_map_isequiv.
```

```text
hfiber
     : (?A -> ?B) -> ?B -> Type
where
?A : [ |- Type]
?B : [ |- Type]
contr_map_isequiv
     : forall f : ?A -> ?B, IsEquiv f -> IsTruncMap (-2) f
where
?A : [ |- Type]
?B : [ |- Type]
```

## 7.7 `equiv_ind`：像做归纳一样消掉一个等价

```coq
Check equiv_ind.
Check equiv_ind_comp.
```

```text
equiv_ind
     : forall f : ?A -> ?B,
       IsEquiv f ->
       forall P : ?B -> Type, (forall x : ?A, P (f x)) -> forall y : ?B, P y
where
?A : [ |- Type]
?B : [ |- Type]
equiv_ind_comp
     : forall (P : ?B -> Type) (df : forall x : ?A, P (?f x)) 
       (x : ?A), equiv_ind ?f P df (?f x) = df x
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?H : [ |- IsEquiv ?f]
```

等价归纳说：要证 `forall b, P b`，只需证 `forall a, P (f a)`。
配合泛等（第 11 章），它就变成真正的路径归纳
（那时叫 `equiv_induction`）。

## 本章坑位清单

1. **`IsEquiv` 有四份数据，不是两份**：只给左右逆不构成 `IsEquiv`，
   要用 `isequiv_adjointify` 补上 `eisadj`。
2. **`equiv_adjointify` 的两个同伦顺序**：先"右逆"
   （`f (g x) == x`，`x : B`），再"左逆"（`g (f x) == x`，`x : A`）。
3. **`^-1` 有两个版本**：`function_scope` 里是 `equiv_inv`（反函数），
   `equiv_scope` 里是 `equiv_inverse`（逆等价）。
4. **`make_equiv` 不是万能的**：目标形状稍微复杂它就搜不出来，
   那时改用 `refine (equiv_adjointify ... _ _)`。
5. **`Equiv` 可以强制转换成函数**，但反过来不行——
   `Check (e : A -> B)` 可以，`Check (f : A <~> B)` 不行。
6. **`equiv_compose` 与 `equiv_compose'` 参数顺序相反**：
   `equiv_compose g f` 里 `g` 在前（数学的 `g ∘ f`），
   `equiv_compose' g f` 同上但接受 `IsEquiv` 作为类型类。
7. **`1` 在 `equiv_scope` 里是 `equiv_idmap`**：
   打开了 `equiv_scope` 的文件里想写 `idpath` 要显式写 `idpath`。
8. **`isequiv_ap` 需要 `IsEquiv f` 作为类型类实例**，
   若没有实例，错误信息会是"Unable to satisfy the following constraints"。
9. **`hfiber` 的两个类型参数是隐式的**：`Check hfiber` 只显示
   `(?A -> ?B) -> ?B -> Type`。
10. **`equiv_ind` 的 `P` 只依赖 `B` 不依赖 `f`**：
    它是"沿等价做归纳"的最简形式。
11. **`Locate "equiv_intros"` 输出 `Unknown notation`**：
    本版本库里没有这个 tactic 记号，别照抄旧教程。
12. **不要把等价和"同构"混为一谈**：HoTT 里没有同构这个原始概念，
    一律用 `A <~> B`。

---

**上一章**：[06 路径代数](docs/06-path-algebra.md)
**下一章**：[08 同伦纤维与可缩性](docs/08-fibers.md)
