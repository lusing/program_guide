# 02 工具链 —— `-noinit`、`-indices-matter` 与公理追踪

> 对应示例：`examples/02_toolchain.v`（编译验证通过）

HoTT 库不是"装在 Coq 上的一个插件"，它**替换**了 Coq 的 prelude。
因此它的编译命令行与标准 Coq 项目不同，漏一个开关就会得到一堆莫名其妙的错。

## 2.1 `-noinit`：HoTT 自带一套 prelude

Rocq 默认会加载 Stdlib 的 Prelude（`nat`、`list`、`+` 等）。HoTT 要重新定义
`paths`、`prod`、`sum`、`nat` 等，所以必须 `-noinit` 把 Stdlib 挡在外面，
再用自己的库充当 prelude。

```coq
Fail Require Import Stdlib.Lists.List.   (* Stdlib 取不到 *)

Check nat.
Check Bool.
Check list.
Check prod.
Check sum.
```

```text
nat
     : Type0
Bool
     : Type0
list
     : Type -> Type
prod
     : Type -> Type -> Type
sum
     : Type -> Type -> Type
```

关键差别：`paths` 是 HoTT 自己的归纳族，`1` 是 `idpath`：

```coq
Print paths.
Check (1 : Bool = Bool).
```

```text
Inductive paths@{u} (A : Type) (a : A) : A -> Type :=  idpath : a = a.

Arguments paths {A}%_type_scope a _
Arguments idpath {A}%_type_scope {a}, [_] _
1 : Bool = Bool
     : Bool = Bool
```

## 2.2 问询四件套：`Check` / `About` / `Print` / `Locate`

这四条命令的用法：

| 命令 | 用途 | 代价 |
|---|---|---|
| `Check t` | 看项的类型 | 最小，本教程全靠它 |
| `About c` | 完整信息：多态性、`Arguments`、scope | 中等 |
| `Print c` | 展开定义体 | 大 |
| `Locate "记号"` | 反查记号定义在哪、属于哪个 scope | 小 |

```coq
Check concat_p1.
About concat_p1.
Print concat_p1.
Locate "@".
Locate "<~>".
Locate "->".
```

```text
concat_p1
     : forall p : ?x = ?y, p @ 1 = p
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
concat_p1@{u} : forall {A : Type} {x y : A} (p : x = y), p @ 1 = p

concat_p1 is universe polymorphic
Arguments concat_p1 {A}%_type_scope {x y} p%_path_scope
concat_p1 is transparent
Expands to: Constant HoTT.Basics.PathGroupoids.concat_p1
Declared in library HoTT.Basics.PathGroupoids, line 85, characters 11-20
concat_p1@{u} =
fun (A : Type) (x y : A) (p : x = y) =>
match p as p0 in _ = a return p0 @ 1 = p0 with
| 1 => 1
end
     : forall {A : Type} {x y : A} (p : x = y), p @ 1 = p

Arguments concat_p1 {A}%_type_scope {x y} p%_path_scope
```

`Locate "->"` 的输出最能说明"记号冲突"这件事：

```text
Notation "p @ q" := (concat p q)
  (* p in scope path_scope, q in scope path_scope *) : path_scope
  (default interpretation) (from HoTT.Basics.Overture)
Notation "A <~> B" := (Equiv A B)
  (* A in scope _type_scope, B in scope _type_scope *) : type_scope
  (default interpretation) (from HoTT.Basics.Overture)
Notation "x -> y" := (implb x y)
  (* x in scope _bool_scope, y in scope _bool_scope *) : bool_scope
  (from HoTT.Types.Bool)
Notation "x -> y" := (dimpl x y)
  (* x in scope _dprop_scope, y in scope _dprop_scope *) : dprop_scope
  (from HoTT.Universes.DProp)
Notation "A -> B" := (forall _ : A, B)
  (* A in scope _type_scope, B in scope _type_scope *) : type_scope
  (default interpretation) (from HoTT.Basics.Overture)
```

同一个 `->` 在四个 scope 里有四种含义——这就是 scope 坑的根源。

`Search` 在 `-noinit` 下仍可用（它是 Rocq 内核自带的查询命令）。
查询要写得窄，否则会刷出上百条：

```coq
Search (IsEquiv) (@inverse Bool true false).
```

## 2.3 `Print Assumptions`：追踪用到了哪些公理

HoTT 库刻意把**泛等**与**函数外延**做成"空类型 + 类型类"，
这样每个定理用到哪些公理都能被机器查出来。这是本库最重要的工程约定。

```coq
Print Assumptions concat_p1.      (* 纯路径代数：不依赖任何公理 *)
```

```text
Closed under the global context
```

```coq
Print Assumptions path_forall.    (* 函数外延：需要 Funext *)
Check isequiv_apD10.
```

```text
Axioms:
isequiv_apD10 :
  Funext ->
  forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
Funext : Type0
```

```coq
Check path_universe.
Check equiv_path.
Print Assumptions isequiv_equiv_path.
```

```text
path_universe
     : forall f : ?A -> ?B, IsEquiv f -> ?A = ?B
where
?H : [ |- Univalence]
?A : [ |- Type]
?B : [ |- Type]
equiv_path
     : forall A B : Type, A = B -> A <~> B
Axioms:
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
Univalence : Type0
```

### `Require Import HoTT` 不给你公理实例

这一点极易误解：导入 `HoTT` 只是导入**定义**，公理（的实例）要单独导入。

```coq
Fail Check HoTT.Axioms.Univalence.univalence_axiom.
Fail Check HoTT.Axioms.Funext.funext_axiom.
```

所以看到 `path_universe` 的类型里带着 `?H : [ |- Univalence]`
（一个未解决的隐式参数）时，那正是"这条定理需要你提供泛等"的意思。
两种做法：写成 `Context `{Univalence}`（第 11 章），
或者 `Require Import HoTT.Axioms.Univalence`（第 13 章起）。

## 2.4 `-indices-matter`

这个开关让归纳类型的**索引**（而不仅是参数）参与"类型是否相同"的判断。
HoTT 依赖它来保证 `paths` 这类索引归纳族的等价判定符合预期。

命令行必须传；写进 `_CoqProject` 时是两行：

```plain
-arg -noinit
-arg -indices-matter
```

本教程所有示例统一用这条命令编译：

```bash
coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_NN_xxx.v
```

其中 `-R ... HoTT` 把库根映射成 `HoTT` 命名空间，
`-q` 是安静模式（`Check` / `Compute` 的输出仍然会打印）。

> 注意：Coq 模块名不能以数字开头，所以示例 `01_type_theory.v`
> 在验证时会被复制成 `ex_01_type_theory.v` 再编译。

## 2.5 Unicode 与记号 scope

库里大量使用 Unicode 记号，并定义了多个专用 scope：

| scope | 记号 | 含义 |
|---|---|---|
| `path_scope` | `1`、`@`、`^` | `idpath`、`concat`、`inverse` |
| `equiv_scope` | `1`、`oE`、`^-1` | `equiv_idmap`、复合、取逆 |
| `trunc_scope` | `-2`、`.+1` | 截断层级 |
| `nat_scope` | `+`、`*`、`-`、`<` | 自然数算术 |
| `fibration_scope` | `.1`、`.2` | Σ 的投影 |
| `pointed_scope` | `->*`、`->**` | 保点映射 |

混用时最容易踩的坑就是数字与 `@` 被别的 scope 抢走：

```coq
Check (1 : nat = nat).
Check (0%nat : nat).
Check (-2)%trunc.
Check (equiv_idmap Bool).
Locate "oE".
Locate "^-1".
```

```text
1 : nat = nat
     : nat = nat
0 : nat
     : nat
(-2)%trunc
     : trunc_index
1%equiv
     : Bool <~> Bool
Notation "g 'oE' f" := (equiv_compose' g f)
  (* g in scope equiv_scope, f in scope equiv_scope *) : equiv_scope
  (default interpretation) (from HoTT.Basics.Equivalences)
Notation "e ^-1" := (equiv_inverse e) (* e in scope _equiv_scope *)
  : equiv_scope (from HoTT.Basics.Equivalences)
Notation "f ^-1" := equiv_inv (* f in scope _function_scope *)
  : function_scope (default interpretation) (from HoTT.Basics.Overture)
```

注意最后两条：`^-1` 在 `function_scope` 里是"反函数"（`equiv_inv`），
在 `equiv_scope` 里是"逆等价"（`equiv_inverse`）。两者经常可以互换使用，
但类型不同。

## 本章坑位清单

1. **少了 `-noinit` 或 `-indices-matter` 中的任一个，本库都无法正确编译。**
   这两个开关不是"可选优化"。
2. **`Require Import HoTT` 不给你 `Univalence` / `Funext` 的实例**，
   必须 `Context `{Univalence}` 或 `Require Import HoTT.Axioms.*`。
3. **`Fail` 在 `-q` 下静默**：调试 `Fail` 时看不到失败原因，别加 `-q`。
4. **Coq 模块名不能以数字开头**：`coqc -o 01_type_theory.v` 报
   `Invalid character '0' at beginning of identifier`；加 `ex_` 前缀。
5. **`-noinit` 下没有 string 记号**：`idtac "文本"` 报
   `No interpretation for string`。
6. **`Search` 查询里不能出现未绑定的变量**：`Search (x = y -> y = x)` 报
   `The reference x was not found`；要写成 `Search (...) (@inverse Bool true false)`。
7. **`About` 比 `Check` 信息全**：排查"为什么这个项被解析成了别的东西"
   时用 `About` 能看到 `Arguments` 与 scope。
8. **`^-1` 有两个版本**：`function_scope` 的 `equiv_inv` 与
   `equiv_scope` 的 `equiv_inverse`。
9. **`Print Assumptions` 只列公理，不列定义里的假设**：
   若你的定理本身带着 `Context `{Funext}`，它会出现在类型里而不是 Axioms 里。
10. **Unicode 记号要靠 `Locate` 反查**：记不住 `oE` 属于哪个 scope 时，
    `Locate "oE"` 一行就能看清。
11. **`Closed under the global context` 是"零公理"的意思**，
    看到它说明这条定理是纯构造性的。
12. **`HoTT.v` 加载约 1 秒**：不要因为"库很大"就回避 `Require Import HoTT`。

---

**上一章**：[01 类型论原理](docs/01-type-theory.md)
**下一章**：[03 依赖类型 —— Π、Σ 与基础类型构造器](docs/03-dependent-types.md)
