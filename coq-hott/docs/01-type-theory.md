# 01 类型论原理

> 对应示例：`examples/01_type_theory.v`（编译验证通过）

本章是全教程的地基。如果你以前用过 Coq / Agda / Lean，请特别留意第 1.4 节——
HoTT 对"相等"的处理和你熟悉的那套**不是一回事**，后面所有新现象都由它长出。

## 1.1 命题即类型

Martin-Löf 类型论最核心的一句口号是：**命题即类型，证明即程序**。
逻辑运算符不是什么特殊的原始概念，它们就是普通的类型构造器：

| 逻辑 | 类型 | HoTT 库里的名字 |
|---|---|---|
| 真 ⊤ | 单元素类型 | `Unit` |
| 假 ⊥ | 空类型 | `Empty` |
| 合取 A ∧ B | 乘积 | `prod`（记号 `A * B`） |
| 析取 A ∨ B | 和类型 | `sum`（记号 `A + B`） |
| 蕴含 A → B | 函数类型 | `A -> B` |
| 全称 ∀x. P x | 依赖函数（Π） | `forall x : A, P x` |
| 存在 ∃x. P x | 依赖对（Σ） | `{x : A & P x}` |
| 否定 ¬A | 到空类型的函数 | `A -> Empty` |

用 `Check` 逐个确认：

```coq
Check Unit.                        (* 真：只有一个居民 *)
Check Empty.                       (* 假：没有居民 *)
Check prod.                        (* 合取 *)
Check sum.                         (* 析取 *)
Check (fun A B : Type => (A -> B)). (* 蕴含 *)
Check sig.                         (* 存在 *)
```

实测输出（抽取自 `build/out/01.sec1`，本教程所有 ```text 块同此来源）：

```text
Unit
     : Type0
Empty
     : Type0
prod
     : Type -> Type -> Type
sum
     : Type -> Type -> Type
(->)
     : Type -> Type -> Type
sig
     : (?A -> Type) -> Type
where
?A : [ |- Type]
```

`(?A -> Type) -> Type` 里的 `?A` 是一个尚未确定的隐式参数——`sig` 的类型是
`forall A : Type, (A -> Type) -> Type`，只是 `A` 被标成了隐式。

全称量词与否定可以自己定义出来（示例里之所以要自己写，是因为在 `-noinit`
下直接 `Check (fun (A : Type) (P : A -> Type) => forall x : A, P x)` 会语法错，
必须绑定成常量名）：

```coq
Definition PiType (A : Type) (P : A -> Type) : Type := forall x : A, P x.
Definition Not (A : Type) : Type := A -> Empty.
```

```text
PiType
     : forall A : Type, (A -> Type) -> Type
Not
     : Type -> Type
```

### 引入与消除规则就是构造子与投影

"逻辑常量有居民"这句话是有内容的：每条引入规则对应一个构造子，
每条消除规则对应一个函数。

```coq
Check tt.                          (* Unit 的唯一居民 *)
Check (@inl : forall A B : Type, A -> A + B).  (* 左注入 = 析取引入 *)
Check (@inr : forall A B : Type, B -> A + B).  (* 右注入 *)
Check (@fst : forall A B : Type, A * B -> A).  (* 合取消除 *)
Check (@snd : forall A B : Type, A * B -> B).
```

```text
@inl : forall A B : Type, A -> A + B
     : forall A B : Type, A -> A + B
@inr : forall A B : Type, B -> A + B
     : forall A B : Type, B -> A + B
@fst : forall A B : Type, A * B -> A
     : forall A B : Type, A * B -> A
@snd : forall A B : Type, A * B -> B
     : forall A B : Type, A * B -> B
```

注意这里一律写的是 `@inl` / `@fst` 而不是 `inl` / `fst`——
不带 `@` 时它们的第一个类型参数默认是隐式的，直接 `Check` 会拿到
`Type -> Type + ?B` 这种意外结果（坑位 3）。

## 1.2 证明即程序

写"定理"和写"函数"是**同一件事**：结论是要造出的类型，假设是参数。
下面每一条都只是 `Definition`，但读起来是逻辑定律：

```coq
Definition law_identity (A : Type) : A -> A := fun x => x.
Definition law_and_elim_l (A B : Type) : A * B -> A := fst.
Definition law_or_intro_l (A B : Type) : A -> A + B := inl.
Definition law_modus_ponens (A B : Type) : A -> (A -> B) -> B
  := fun a f => f a.
Definition law_not_elim (A : Type) : A -> (A -> Empty) -> Empty
  := fun a na => na a.
Definition law_exists_intro (A : Type) (P : A -> Type) (a : A) (p : P a)
  : { x : A & P x }
  := (a; p).
```

```text
law_identity
     : forall A : Type, A -> A
law_modus_ponens
     : forall A B : Type, A -> (A -> B) -> B
law_exists_intro
     : forall (A : Type) (P : A -> Type) (a : A), P a -> {x : A & P x}
```

证明项是可以**求值**的程序：

```coq
Compute law_modus_ponens Bool Bool true (fun b => b).
Compute (@fst Bool nat (true, 3%nat)).
```

```text
     = true
     : Bool
     = true
     : Bool
```

### 【坑】数字字面量默认不是 nat

这是本库最劝退的细节，也是本章必须记住的第一件事：

```coq
Check (0%nat : nat).
Check (0 : trunc_index).
Check (1 : (0%nat) = 0%nat).
```

```text
0 : nat
     : nat
0 : trunc_index
     : trunc_index
1 : 0%nat = 0%nat
     : 0%nat = 0%nat
```

`0` 落在 `trunc_scope`（截断层级 -2 的表示），`1` 落在 `path_scope`
（`idpath`）。想写自然数就必须 `%nat`。整数是 `%int`，截断层级是 `%trunc`。

## 1.3 依赖类型：谓词就是 `A -> Type`

依赖函数（Π）与依赖对（Σ）是普通函数 / 乘积的"终点随起点变化"的版本，
逻辑上正对应全称与存在。

```coq
Definition IsZero (n : nat) : Type := n = 0%nat.

Check IsZero.                      (* nat -> Type：一个谓词 *)
Check IsZero 0%nat.                (* 一个具体的命题 *)
Check (idpath : IsZero 0%nat).     (* 它有居民：0 = 0 *)
```

```text
IsZero
     : nat -> Type
IsZero 0
     : Type
1 : IsZero 0
     : IsZero 0
```

Σ 类型的居民是"见证 + 证据"，取分量用 `.1` / `.2`
（`fibration_scope` 的记号）或 `pr1` / `pr2`：

```coq
Definition witness_zero : { n : nat & IsZero n } := (0%nat; idpath).
Compute (witness_zero).1.
Compute (witness_zero).2.
```

```text
witness_zero
     : {n : nat & IsZero n}
     = 0%nat
     : nat
     = 1
     : IsZero witness_zero.1
```

`{x : A & P x}` 与 `{x : A | P x}` 是两个记号：前者第二分量是数据
（对应"存在"），后者第二分量是 h-prop（对应"存在唯一"意义上的命题）。
本章只用前者。

## 1.4 相等的特殊地位

在 HoTT 里 `x = y` **不是**布尔值，而是一个类型。`paths` 是一个归纳类型族，
只有一个构造子 `idpath`：

```coq
Check paths.
Check idpath.
Print paths.
```

```text
Inductive paths@{u} (A : Type) (a : A) : A -> Type :=  idpath : a = a.

Arguments paths {A}%_type_scope a _
Arguments idpath {A}%_type_scope {a}, [_] _
```

`A` 与 `a` 是**参数**，终点是**索引**。这个区分在第 02 章的
`-indices-matter` 里会再出现。

因为 `x = y` 是类型，它就有居民；那些居民叫**路径**。而且
——关键来了——同一个相等命题可以有**多个不同**的居民。

记号上，`1` 是 `idpath`，`p @ q` 是拼接，`p^` 是取逆，
都与标准 Coq 的习惯不同：

```coq
Check (1 : (3%nat) = 3%nat).
Check (@concat Bool true true true).
Check (@inverse Bool true false).
```

```text
1 : 3%nat = 3%nat
     : 3%nat = 3%nat
concat
     : true = true -> true = true -> true = true
inverse
     : true = false -> false = true
```

## 1.5 类型即空间：三层词典

HoTT 的完整词典有四层（可以继续往上）：

| 类型论 | 同伦论 |
|---|---|
| 类型 `A` | 空间 |
| 项 `x : A` | 点 |
| 路径 `p : x = y` | 从 x 到 y 的连续道路 |
| 2-路径 `r : p = q` | 两条道路之间的同伦 |

同一条相等命题的不同证明，就是不同的道路；证明之间的相等，就是同伦：

```coq
Definition two_paths_to_true : true = true := 1.
Definition path_of_paths : (1 : true = true) = (1 @ 1 : true = true)
  := (concat_1p 1)^.
```

```text
two_paths_to_true
     : true = true
path_of_paths
     : 1 = 1 @ 1
```

"所有路径都相同"是很强的性质，叫 **h-set**（0-型）；
允许非平凡环路的类型（圆）就不是集合。

```coq
Check (fun A : Type => IsHSet A).
Check (fun A : Type => IsHProp A).
Check (fun A : Type => Contr A).
Check (fun (n : trunc_index) (A : Type) => IsTrunc n A).
Check trunc_index.
Check minus_two.
```

```text
fun A : Type => IsHSet A
     : Type -> Type
fun A : Type => IsHProp A
     : Type -> Type
fun A : Type => Contr A
     : Type -> Type
fun (n : trunc_index) (A : Type) => IsTrunc n A
     : trunc_index -> Type -> Type
trunc_index
     : Type0
(-2)%trunc
     : trunc_index
```

三者都是 `IsTrunc n A` 的记号：`Contr` = -2 层，`IsHProp` = -1 层，
`IsHSet` = 0 层。第 09 章展开这条链。

## 本章坑位清单

1. **数字字面量默认不是 `nat`**：`0` 是 `trunc_index`，`1` 是 `idpath`。
   自然数一律写 `%nat`，整数写 `%int`，截断层级写 `%trunc`。
2. **`-noinit` 下没有 string 记号**：`idtac "文本"` 会报
   `No interpretation for string`。本教程改用 `Check` 打印哨兵常量来分节。
3. **`inl` / `inr` / `fst` / `snd` 的首个类型参数是隐式的**：
   裸写 `Check (inl : forall A B, A -> A + B)` 会得到
   `Type -> Type + ?B`；要写 `@inl` / `@fst`。
4. **注释紧贴 `.)` 会被当成限定名后缀**：
   `Check (fun A B => (A -> B)).(* 注释 *)` 报
   `Syntax error: '@' or [global] expected after '.('`，点号后要留空格。
5. **`Check` 裸写 `Notation` / `Abbreviation` 会报
   `Abbreviation is not applied enough`**：`IsHSet`、`Contr`、
   `IsEquiv`、`IsTrunc`、`IsEmbedding` 都必须带参数，写
   `Check (fun A : Type => IsHSet A)`。
6. **`{x : A & P x}` 与 `{x : A | P x}` 不是一个东西**：
   前者第二分量是数据，后者要求第二分量是 h-prop。
7. **`1` 在不同 scope 里含义不同**：`path_scope` 里是 `idpath`，
   `equiv_scope` 里是 `equiv_idmap`，`nat_scope` 里是自然数 1。
   混开 scope 时务必用 `%` 定界。
8. **`paths` 的参数/索引区分**：`A` 与起点 `a` 是参数，终点是索引。
   这决定了路径归纳的形状，也决定了 `-indices-matter` 为什么必须开。
9. **不要指望 UIP**：HoTT 里不能证 `forall p q : x = y, p = q`。
   能证的类型叫 h-set，必须显式拿到 `IsHSet` 实例。
10. **`reflexivity` 在 HoTT 里被重定向到 `idpath`**：
    所以"对 `p` 做 `destruct` 再 `reflexivity`"就是路径归纳，
    和标准 Coq 的那套写法是同一回事。
11. **`Compute` 需要具体实例**：`Compute fst (true, 3)` 报类型不符，
    要写 `Compute (@fst Bool nat (true, 3%nat))`。
12. **`sig` 的 `A` 是隐式参数**：`Check sig` 输出里带 `?A`，
    说明它还没被确定，不是错误。

---

**下一章**：[02 工具链 —— `-noinit`、`-indices-matter` 与公理追踪](docs/02-toolchain.md)
