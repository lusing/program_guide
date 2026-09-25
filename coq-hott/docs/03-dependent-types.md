# 03 依赖类型 —— Π、Σ 与基础类型构造器

> 对应示例：`examples/03_dependent_types.v`（编译验证通过）

本章把第 01 章提到的那张"逻辑 ↔ 类型"对照表落实到具体代码上。
HoTT 库里这些类型的名字和 Stdlib 相同，但**定义是它自己的**。

## 3.1 `Unit`：只有一个居民的类型

```coq
Check Unit.
Check tt.
Print Unit.
```

```text
Unit
     : Type0
tt
     : Unit
Inductive Unit@{} : Type0 :=  tt : Unit.
```

`Unit` 上的 η 性质：任何 `u : Unit` 都等于 `tt`。
这里的证明就是对 `u` 做 `destruct`（即路径归纳），
而 `reflexivity` 在 HoTT 里被重定向到 `idpath`：

```coq
Definition unit_eta (u : Unit) : u = tt.
Proof.
  destruct u; reflexivity.
Defined.
```

```text
unit_eta
     : forall u : Unit, u = tt
```

## 3.2 `Empty`：没有居民的类型，以及"爆炸原理"

```coq
Check Empty.
```

```text
Empty
     : Type0
```

空类型可以消去到任意类型——这就是"假命题蕴涵一切"：

```coq
Definition exfalso (A : Type) (e : Empty) : A := match e with end.
```

```text
exfalso
     : forall A : Type, Empty -> A
```

由 `Empty` 的居民可以造出任何"命题"的证明，包括矛盾。
这是第 05 章 `true ≠ false` 的标准做法（先造一个族，再 transport）：

```coq
Definition not_true_ne_false_via_empty (p : true = false) : Empty
  := transport (fun b => match b with true => Unit | false => Empty end) p tt.
Check true_ne_false.
```

```text
not_true_ne_false_via_empty
     : true = false -> Empty
true_ne_false
     : true <> false
```

`x <> y` 就是 `x = y -> Empty` 的记号。

## 3.3 `Bool`：两元素类型与 `if`

```coq
Check Bool.
Check true.
Check false.

Definition bool_not (b : Bool) : Bool := if b then false else true.
Compute bool_not true.
Compute bool_not false.
```

```text
Bool
     : Type0
true
     : Bool
false
     : Bool
     = false
     : Bool
     = true
     : Bool
```

库里自带的取反叫 `negb`：

```coq
Check negb.
Compute negb true.
```

```text
negb
     : Bool -> Bool
     = false
     : Bool
```

`Bool` 可以编码"可判定命题"，而 `true ≠ false` 是本库最常用的反例来源
（第 05、13、24 章都要用它证明环路非平凡）。

## 3.4 和类型 `A + B`（析取）

```coq
Check sum.
Check (fun A B : Type => A + B).
```

```text
sum
     : Type -> Type -> Type
fun A B : Type => A + B
     : Type -> Type -> Type
```

和类型的消去是"分情况讨论"，在 Coq 里就是 `match`：

```coq
Definition sum_swap {A B : Type} (z : A + B) : B + A
  := match z with inl a => inr a | inr b => inl b end.
Check sum_swap.
Compute sum_swap (inl 1%nat : nat + Bool).
```

```text
sum_swap
     : ?A + ?B -> ?B + ?A
where
?A : [ |- Type]
?B : [ |- Type]
     = inr 1%nat
     : Bool + nat
```

## 3.5 Σ 类型（依赖对 / 存在量词）

```coq
Check sig.
Check (fun (A : Type) (P : A -> Type) => { x : A & P x }).
Check (fun (A : Type) (P : A -> Type) => { x : A | P x }).
```

```text
sig
     : (?A -> Type) -> Type
where
?A : [ |- Type]
fun (A : Type) (P : A -> Type) => {x : A & P x}
     : forall A : Type, (A -> Type) -> Type
fun (A : Type) (P : A -> Type) => {x : A & P x}
     : forall A : Type, (A -> Type) -> Type
```

注意 `{x : A | P x}` 打印出来和 `{x : A & P x}` 一样——
差别在于第二分量被要求是 h-prop（类型类约束，不显示在类型里）。

取分量用 `pr1` / `pr2`，或记号 `.1` / `.2`（`fibration_scope`）：

```coq
Definition pair_nat : { n : nat & n = n } := (3%nat; 1).
Check pair_nat.
Compute (pair_nat).1.
Compute pr1 pair_nat.
```

```text
pair_nat
     : {n : nat & n = n}
     = 3%nat
     : nat
     = 3%nat
     : nat
```

Σ 的 η 性质同样成立：

```coq
Check eta_sigma.
```

```text
eta_sigma
     : forall u : {x : _ & ?P x}, (u.1; u.2) = u
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
```

## 3.6 Π 类型（依赖函数 / 全称量词）

依赖函数的"相等"是**逐点相等**，记作 `f == g`：

```coq
Check (fun (A : Type) (P : A -> Type) => forall x : A, P x).
Check pointwise_paths.
Locate "==".
```

```text
fun (A : Type) (P : A -> Type) => forall x : A, P x
     : forall A : Type, (A -> Type) -> Type
pointwise_paths
     : (forall x : ?A, ?P x) -> (forall x : ?A, ?P x) -> Type
where
?A : [ |- Type]
?P : [ |- ?A -> Type]
Notation "f == g" := (pointwise_paths f g)
  (* f in scope _function_scope, g in scope _function_scope *) : type_scope
  (default interpretation) (from HoTT.Basics.Overture)
```

### 【坑】`+` 在 `type_scope` 里是和类型

```coq
Definition double_all : forall n : nat, nat := fun n => (n + n)%nat.
Compute double_all 3%nat.
Check nat_add.
```

```text
     = 6%nat
     : nat
nat_add
     : nat -> nat -> nat
double_all
     : nat -> nat
```

### 两个方向的桥

逐点相等 `f == g` 与相等 `f = g` 是**两个不同强度**的命题：

```coq
Check ap10.
Check apD10.
```

```text
ap10
     : ?f = ?g -> ?f == ?g
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?g : [ |- ?A -> ?B]
apD10
     : ?f = ?g -> ?f == ?g
where
?A : [ |- Type]
?B : [ |- ?A -> Type]
?f : [ |- forall x : ?A, ?B x]
?g : [ |- forall x : ?A, ?B x]
```

`f = g -> f == g` 永远成立（就是 `ap10` / `apD10`），
反方向需要**函数外延**（第 10 章）。

## 3.7 `option`：可能失败的返回值

```coq
Check option.
Check Some.
Check None.

Definition safe_pred (n : nat) : option nat
  := match n with 0%nat => None | S m => Some m end.
Compute safe_pred 0%nat.
Compute safe_pred 5%nat.
```

```text
option
     : Type -> Type
Some
     : ?A -> option ?A
where
?A : [ |- Type]
None
     : option ?A
where
?A : [ |- Type]
     = None
     : option nat
     = Some 4%nat
     : option nat
```

## 本章坑位清单

1. **`+` 在 `type_scope` 里是和类型**，自然数加法必须 `%nat` 或用 `nat_add`。
2. **`{x : A | P x}` 与 `{x : A & P x}` 打印结果一样**，
   但前者要求第二分量是 h-prop；选错会在类型类搜索时才报错。
3. **`match e with end` 是 `Empty` 的唯一消去式**，别指望 `destruct` 后
   还有什么分支要处理。
4. **`negb` 不是 `not`**：`not` 是逻辑否定（`A -> Empty`），
   `negb` 是布尔取反（`Bool -> Bool`）。
5. **`(a; b)` 是 Σ 的构造子记号**，而 `(a, b)` 是乘积；混用会报类型不符。
6. **`.1` / `.2` 属于 `fibration_scope`**：在没打开该 scope 的文件里，
   写 `u.1` 可能被解析成别的东西（比如数字 1）。
7. **`Compute` 的输出行以 `= ` 开头**，不带名字——本教程的 ```text 块里
   形如 `= 3%nat` 的行都是 `Compute` 的结果。
8. **`Some` / `None` 的类型参数是隐式的**：单独 `Check None` 会得到
   `option ?A`，这是正常的。
9. **和类型的 `match` 分支顺序不影响语义**，但漏分支会报"非穷尽"。
10. **`if b then ... else ...` 必须用 `Bool`**，不是 `bool`——
    HoTT 库里的大写 `Bool` 是它自己定义的。
11. **`nat` 上的 `match` 只有 `O` 与 `S`**：写 `0%nat` 作为模式会报
    "不是构造子"（要用 `O`）。
12. **`safe_pred 5` 要写 `5%nat`**，否则 5 被解析成别的东西。

---

**上一章**：[02 工具链](docs/02-toolchain.md)
**下一章**：[04 恒等类型与路径归纳](docs/04-identity-types.md)
