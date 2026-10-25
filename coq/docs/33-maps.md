# 33 · 映射：把函数当数据结构

对应示例：`../examples/33_maps.v`

### 33.1 一个反直觉的决定：映射就是一个函数

从这一章开始，教程进入「语言理论」部分：我们要一步步造出一门小语言 Imp，定义它的求值语义、证明它的性质。而这一切的地基是一个数据结构——**映射**（map，也叫字典、关联数组、环境）。变量表是映射，类型上下文是映射，内存状态是映射。

映射只有两个操作：

- **查找** `find m x`：给出键 `x`，返回对应的值（或者「没有」）；
- **更新** `update m x v`：给出键 `x` 和值 `v`，返回一个「在 `x` 处等于 `v`、其余处处与 `m` 相同」的新映射。

21 章求值器里我们用 `string -> nat` 的函数直接当环境，那是顺手为之。本章要把它变成一个**正式的、带定律的数据结构**，并且回答一个关键问题：**用函数来表示映射，是不是在耍花招？**

答案是不但不耍花招，反而是最好的选择。理由只有一句话：

> 查找就是函数应用。

于是「映射」这个数据结构在 Rocq 里根本不需要新造类型——它已经是 `Type` 里的一等公民。更妙的是**相等性**：两个映射如果对所有键的回答都相同，它们在函数表示下就是**同一个对象**（借助函数外延公理），于是证明里可以直接 `rewrite`，不必先证「结构等价」再搬运。这一点在 33.4 会实测到。

代价也要说清楚：函数是**不透明**的，你无法「遍历」一个函数映射，也无法判断它有多少个键。所以函数表示适合**语义建模**（我们只需要查找与更新），不适合**真实实现**（需要枚举键时用 33.8 的列表版或搜索树）。

示例文件开头：

```coq
(* 33 映射：把函数当数据结构 —— total_map、partial_map 与它们的定律 *)

From Stdlib Require Import Arith Bool List.
From Stdlib Require Export Strings.String.
From Stdlib Require Import FunctionalExtensionality.
Import ListNotations.

Module Ex33Maps.
```

四行导入各有用途，值得逐行看：

| 导入 | 为什么需要 |
|---|---|
| `Arith Bool List` | 算术与布尔运算；33.8 的列表版映射要 `list` |
| `Strings.String` | 键类型 `string` 与 `String.eqb`。用 `Require Export` 而非 `Import`：让下游文件 `Require` 本文件时**自动**也拿到 `String`（映射的使用者一定要用字符串） |
| `FunctionalExtensionality` | 函数外延公理。33.5 的四条定律里有三条**必须**用它，`Print Assumptions` 会实测出来 |
| `Import ListNotations` | 打开 `[a; b]`、`[]`、`::` 记号。不写这行，33.8 里 `[("a"%string, 2); ...]` 直接语法报错 |

整章包在 `Module Ex33Maps.` 里，与本教程其它示例一致：模块把记号、`Hint`、定义都关在一个命名空间内，避免和别的章撞名（33.10 会实测到 `Hint` 的作用域坑）。

### 33.2 键类型：`string` 与它的四条等式事实

映射要有键。键类型必须**可判定相等**——因为 `t_update` 要在运行期比较「被查的键」和「被更新的键」。Rocq 标准库的 `string` 就是为此准备的：它是归纳类型（`EmptyString | String ascii string`），并且带一个可计算的比较函数。

先用 `Locate` 看看 `=?` 这个记号到底指向谁（02 章教过的问询四件套之一）：

```coq
(* ---------- 33.1 键类型：string 与它的四条等式事实 ---------- *)

Locate "=?".
```

`rocq compile` 的真实输出（本章所有输出都是本机 rocq 9.3.0 + stdlib 9.2.0 实测）：

```text
Notation "x =? y" := (Nat.eqb x y)
  (* x in scope _nat_scope, y in scope _nat_scope *) : nat_scope
  (default interpretation)
  (defined in library Stdlib.Arith.PeanoNat, line 1340, characters 6-10)
  (reserved in library Stdlib.Strings.String, line 55, characters 6-10)
Notation "x =? y" := (eqb x y)
  (* x in scope _string_scope, y in scope _string_scope *) : string_scope
  (defined in library Stdlib.Strings.String, line 55, characters 6-10)
  (reserved in library Stdlib.Arith.PeanoNat, line 1340, characters 6-10)
```

**同一个记号有两处定义**，靠作用域（scope）区分：`nat_scope` 里是自然数比较，`string_scope` 里是字符串比较。`(default interpretation)` 标在 nat 那条上——意思是**不加标注时 `=?` 默认按 nat 解读**。这就是为什么后面每条定理里都写成 `(x =? x)%string`：`%string` 是显式作用域标注（24 章讲过的 `%Z` 是同一机制）。忘了标注，`"a" =? "b"` 会去尝试 nat 解读然后报「No interpretation for string」。

再看 `String` 模块提供的四件事。第一件是函数本身：

```coq
Check String.eqb : string -> string -> bool.
```

输出（注意 Rocq 会把 `Check` 的断言也回显一遍，两行分别是「实际类型」与「你断言的类型」）：

```text
eqb : string -> string -> bool
     : string -> string -> bool
```

第二到第四件是三条**关于它的定理**，外加一条 `reflect` 形态的桥：

```coq
Check String.eqb_refl :
  forall x : string, (x =? x)%string = true.

Check String.eqb_eq :
  forall n m : string, (n =? m)%string = true <-> n = m.

Check String.eqb_neq :
  forall n m : string, (n =? m)%string = false <-> n <> m.

Check String.eqb_spec :
  forall x y : string, reflect (x = y) (String.eqb x y).
```

实测回显（`eqb_spec` 那条 Rocq 自己把 `String.eqb x y` 打印成了 `(x =? y)%string`，两者是同一个东西）：

```text
eqb_spec : forall x y : string, reflect (x = y) (x =? y)%string
```

四条的分工：

| 定理 | 形态 | 什么时候用 |
|---|---|---|
| `eqb_refl` | `x =? x = true` | `rewrite` 掉自反比较（33.5 的 `t_update_eq`） |
| `eqb_eq` | `= true <-> =` | bool 世界与 Prop 世界互相搬证据 |
| `eqb_neq` | `= false <-> <>` | 同上，否定方向 |
| `eqb_spec` | `reflect (x = y) (x =? y)` | **一步同时**做 bool 分情况 + 拿到等式/不等式假设 |

`eqb_spec` 是主力。15 章讲过 `reflect P b` 把「b 算出 true」和「P 成立」焊在一起；对字符串比较，它的威力在于：`destruct (String.eqb_spec x y)` 一条命令就把 `if x =? y then A else B` 拆成两个子目标，且**每个子目标里 `if` 已经被消掉**，还白送一条 `x = y` 或 `x <> y` 的假设。33.5 的六条定律全靠它。

两条 `Example` 验证比较函数确实能算：

```coq
Example eqb_demo : String.eqb "foo" "foo" = true.
Proof. reflexivity. Qed.

Example eqb_demo_neq : String.eqb "foo" "bar" = false.
Proof. reflexivity. Qed.
```

`reflexivity` 能过，说明 `String.eqb "foo" "foo"` 是**可计算**的——Rocq 真的把它算成了 `true`。这正是「函数表示」的底气：键是具体字符串时，一切查找都能算出来，不需要任何引理。

### 33.3 全映射 `total_map`：三个定义就是全部

**全映射**（total map）：每个键都有值，查不到的键返回一个「默认值」。

```coq
(* ---------- 33.2 全映射：就是一个函数 ---------- *)

Definition total_map (A : Type) := string -> A.
```

一行。`total_map A` 就是「从字符串到 `A` 的函数」的类型别名。注意它是 `Definition` 而不是 `Inductive`——没有新构造子，没有新模式匹配，`total_map A` 与 `string -> A` 在 Rocq 眼里**完全同一个类型**（可互相转换）。

空映射：给一个默认值，处处返回它。

```coq
Definition t_empty {A : Type} (v : A) : total_map A :=
  (fun _ => v).
```

`{A : Type}` 是隐式参数（04 章）：写 `t_empty false` 时 `A` 由 `false : bool` 反推出来，不必写 `t_empty bool false`。

更新：这是全章最精妙的一行。

```coq
Definition t_update {A : Type} (m : total_map A)
                    (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.
```

读法：`t_update m x v` 返回**一个新函数**。这个新函数拿到查询键 `x'` 时先问「`x'` 是不是我要更新的那个 `x`？」——是就返回新值 `v`，不是就**转交给旧映射 `m`**。

这叫**高阶编程**（higher-order programming）：函数被当作数据传进来（`m`），又被包在新函数里返回。16 章的 `map`/`filter` 是把函数当参数，这里是把函数当**被包装的对象**。

参数顺序有个坑：`t_update` 的参数序是 `(m, x, v)`——映射在前；但记号会把它写成 `x !-> v ; m`——映射在后。33.4 会讲到这个「读法与调用法相反」带来的实际麻烦。

造一个具体映射：`"foo"` 和 `"bar"` 映射到 `true`，其余全是 `false`。

```coq
Definition examplemap :=
  t_update (t_update (t_empty false) "foo" true)
           "bar" true.

Check (examplemap : string -> bool).
```

实测输出：

```text
examplemap : string -> bool
     : string -> bool
```

类型就是 `string -> bool`——`total_map bool` 被 Rocq 打印成了它的真身。这提醒我们：`total_map` 只是**别名**，不是新类型，所以 `Print`/`Check` 看到的永远是函数类型。

查找就是应用，而且**能算**：

```coq
Example lookup_present : examplemap "foo" = true.
Proof. reflexivity. Qed.

Example lookup_absent : examplemap "baz" = false.
Proof. reflexivity. Qed.
```

两条都是 `reflexivity` 一步过。第二条尤其值得体会：`"baz"` 从来没被 `t_update` 过，但它**有值**（`false`，来自 `t_empty false`）。这就是「全」映射的含义——不存在「查不到」，只存在「查到默认值」。

### 33.4 记号工程：`__ !-> v` 与 `x !-> v ; m`

嵌套调用 `t_update (t_update (t_empty false) "foo" true) "bar" true` 读起来是反的：最内层是最早的绑定，最外层是最后的绑定，而人读映射的习惯是「从上往下、后写的覆盖先写的」。两条记号把书写顺序掰正：

```coq
(* ---------- 33.3 记号：__ !-> v 与 x !-> v ; m ---------- *)

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Example example_empty := (__ !-> false).

Check example_empty : total_map bool.
```

`'__'` 用单引号包起来，表示它是一个**字面 token**（关键字），不是变量。`__ !-> false` 读作「默认值为 false 的空映射」。实测 `Check` 输出：

```text
example_empty : total_map bool
```

这里 `total_map bool` 被原样打印（因为 `Example ... := ...` 的类型是从记号展开后的 `t_empty false` 推出来的，Rocq 保留了别名）。

接着是更新记号：

```coq
Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).
```

三个设置各有讲究（37 章会系统讲记号，这里先会用）：

- `at level 100`：优先级最低的一档，保证 `x !-> v ; m` 整体作为一个「项」被外层吃掉，而不是和算术运算符抢结合；
- `v constr at level 100`：值 `v` 这个位置也按 level 100 解析，于是 `v` 里可以再写一个 `!->`（右结合的来源）；
- `right associativity`：`a !-> 1 ; b !-> 2 ; m` 解析成 `a !-> 1 ; (b !-> 2 ; m)`，即**先处理 b 再处理 a**，正好对应「后写的覆盖先写的」。

注意 `:= (t_update m x v)` 里参数顺序被**调换**了：记号读作 `x !-> v ; m`，调用却是 `t_update m x v`。这是记号的本职工作——把「人话顺序」翻译成「函数顺序」。

现在同一个映射可以写成自然的样子：

```coq
Definition examplemap' :=
  ( "bar" !-> true;
    "foo" !-> true;
    __    !-> false
  ).
```

它和 33.3 的 `examplemap` 是**同一个映射**。但「同一个」在 Rocq 里要说清楚是哪种同一个：语法上它们是两个不同的项，所以不能 `reflexivity`，要用函数外延公理：

```coq
Example notation_same_as_nested : examplemap = examplemap'.
Proof.
  apply functional_extensionality. intro s.
  destruct (String.eqb_spec "bar" s);
  destruct (String.eqb_spec "foo" s);
  reflexivity.
Qed.
```

证明思路：`functional_extensionality` 把「两个函数相等」降级为「对每个输入 `s`，输出相等」；然后对 `"bar"` 是否等于 `s`、`"foo"` 是否等于 `s` 各分一次情况（`;` 让两个 `destruct` 串起来，作用于所有子目标），四种组合下两边都算成同一个值，`reflexivity` 收尾。

**这就是函数表示的核心红利**：两个写法不同的映射，相等性是一个可以用 `rewrite` 搬运的**命题等式** `=`，而不需要另造一个「映射等价」关系再证它自反/对称/传递。33.8 的列表版对照会让你看清这个红利有多大。

最后用 `Print` 看 Rocq 怎么回显这个定义：

```coq
Print examplemap'.
```

实测输出：

```text
examplemap' =
"bar" !-> true; "foo" !-> true; __ !-> false
     : string -> bool

Arguments examplemap' x'%_string_scope
```

两点信息：① Rocq **用我们定义的记号打印**（记号是双向的，既管解析也管打印）；② `Arguments examplemap' x'%_string_scope` 是 Rocq 自动推断的作用域标注——它在提醒「这个函数的参数应当按 string 作用域解读」，这正是 33.8 那个「No interpretation for string」报错的解药。

**一个必须实测的语法坑**：`!->` 记号**强制要求尾巴**。下面这行（在 /tmp 副本里实测，未写进示例文件，因为它会让整个文件解析失败）：

```coq
Definition no_tail := ("a" !-> true).
```

rocq 9.3.0 的真实报错：

```text
Error: Syntax error: ';' expected after [term level 100] (in [term]).
```

原因：我们只声明了 `x '!->' v ';' m`（三段式）和 `'__' '!->' v`（空映射），**没有**声明两段的 `x '!->' v`。所以 `"a" !-> true` 解析到 `true` 之后还在等一个 `;`。偏映射那边（33.6）专门补了一条两段的 `x '|->' v`，全映射这边没有——这是原书的设计，记住即可：**全映射的尾巴不可省，偏映射可省**。

### 33.5 全映射的六条定律

映射的行为由六条定律刻画。后面 38–44 章的几乎所有证明都会反复 `rewrite` 它们，所以**即使不亲手证，也要把六条的陈述背下来**。

```coq
(* ---------- 33.4 全映射的六条定律 ---------- *)

Lemma t_apply_empty : forall (A : Type) (x : string) (v : A),
  (__ !-> v) x = v.
Proof. reflexivity. Qed.
```

**定律一：空映射处处返回默认值。** `reflexivity` 直接过——`(__ !-> v) x` 展开是 `(fun _ => v) x`，β-归约就是 `v`，两边**可转换**（convertible），不需要任何公理。

```coq
Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.
```

**定律二：更新后查同一个键，得到新值。** 证明里有个容易踩的细节：必须先 `intros` 再 `unfold`。如果反过来——先 `unfold t_update` 再 `rewrite String.eqb_refl`——会失败，因为此时目标还套在 `forall` 里，`rewrite` 够不到量词内部的 `x =? x`。实测的失败信息是：

```text
Error: Found no subterm matching "(?M1082 =? ?M1082)%string"
in the current goal.
```

`intros` 之后 `unfold t_update`，目标变成 `(if (x =? x)%string then v else m x) = v`，`rewrite String.eqb_refl` 把 `x =? x` 换成 `true`，`if true then v else m x` 化简为 `v`，`reflexivity` 收尾。

顺手查一下这条定律用了哪些公理（25 章教过的 `Print Assumptions`）：

```coq
Print Assumptions t_update_eq.
```

实测输出：

```text
Closed under the global context
```

「封闭于全局上下文」= **没有用任何公理**。这条定律是纯计算的。

```coq
Theorem t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.
```

**定律三：更新一个键，不影响别的键。** `unfold t_update` 之后的真实目标（repl 实测）：

```text
1 goal

  A : Type
  m : total_map A
  x1, x2 : string
  v : A
  Hneq : x1 <> x2
  ============================
  (if (x1 =? x2)%string then v else m x2) = m x2
```

`destruct (String.eqb_spec x1 x2)` 一刀切下去，`if` 消失，变成两个子目标（repl 实测）：

```text
2 goals

goal 1 is:
 v = m x2

goal 2 is:
 m x2 = m x2

  A : Type
  m : total_map A
  x1, x2 : string
  v : A
  Hneq : x1 <> x2
  e : x1 = x2
  ============================
  v = m x2
```

注意 `reflect` 的威力：goal 1 里 `if` 已经**算成了 then 分支**（所以左边只剩 `v`），同时白送假设 `e : x1 = x2`。这个分支与 `Hneq : x1 <> x2` 矛盾——`subst x2` 把 `x2` 替换成 `x1`，`Hneq` 变成 `x1 <> x1`，`contradiction` 引爆。goal 2 里 `if` 算成 else 分支，两边都是 `m x2`，`reflexivity`。

```coq
Lemma t_update_shadow : forall (A : Type) (m : total_map A) x v1 v2,
  (x !-> v2 ; x !-> v1 ; m) = (x !-> v2 ; m).
Proof.
  intros A m x v1 v2.
  Fail exact eq_refl.
  apply functional_extensionality. intro x'.
  unfold t_update.
  destruct (String.eqb_spec x x').
  - reflexivity.
  - reflexivity.
Qed.
```

**定律四：遮蔽（shadowing）——同一个键更新两次，只有最后一次算数。**

这条定律的证明里我故意留了一行 `Fail exact eq_refl.`。`Fail` 的语义是「断言这个 tactic **会失败**」（03 章）；如果它居然成功了，编译反而报错。这里它确实失败，rocq 9.3.0 的真实信息（repl 实测）：

```text
The term "eq_refl" has type
 "(x !-> v2; x !-> v1; m) = (x !-> v2; x !-> v1; m)"
while it is expected to have type "(x !-> v2; x !-> v1; m) = (x !-> v2; m)"
(cannot unify "x !-> v2; x !-> v1; m" and "x !-> v2; m").
```

**这条报错就是「为什么需要函数外延公理」的最直观证据**：两边语法不同（左边多一层 `x !-> v1`），Rocq 的转换规则（β/ι/δ）算不出它们相等——因为 `if x =? x' then v2 else (if x =? x' then v1 else m x')` 与 `if x =? x' then v2 else m x'` 里的 `x'` 是**自由变量**，不代入具体值就没法化简。

所以必须先 `apply functional_extensionality` 引入任意的 `x'`，把「函数相等」变成「逐点相等」，这时 `x'` 成了可以被 `destruct (String.eqb_spec x x')` 分情况的对象，两个分支都 `reflexivity`。

查公理：

```coq
Print Assumptions t_update_shadow.
```

实测输出：

```text
Axioms:
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
  (forall x : A, f x = g x) -> f = g
```

**确实用了一条公理**。`functional_extensionality` 是 `functional_extensionality_dep` 的特例（`B` 取常函数）。这条公理在 Rocq 里不是内置可证的——它是「函数表示映射」这个选择的全部代价。16 章讲高阶函数时提过它，这里是它第一次真正** indispensable **（不可或缺）。

```coq
Theorem t_update_same : forall (A : Type) (m : total_map A) x,
  (x !-> m x ; m) = m.
Proof.
  intros A m x. apply functional_extensionality. intro x'.
  unfold t_update.
  destruct (String.eqb_spec x x') as [Heq | Hne].
  - subst x'. reflexivity.
  - reflexivity.
Qed.
```

**定律五：用同一个值更新，等于没更新。** 同样需要外延公理。`as [Heq | Hne]` 给两个分支的假设命名（`reflect` 的两个构造子）。正分支拿到 `Heq : x = x'`，`subst x'` 把目标里的 `x'` 换成 `x`，于是 `m x = m x`，`reflexivity`。

这里有个**实测踩过的坑**：如果写成 `destruct (String.eqb_spec x x').` 不给名字，正分支的假设叫 `e`，但目标里 `x'` 还在，`reflexivity` 会失败并报：

```text
Error:
In environment
A : Type
m : total_map A
x, x' : string
e : x = x'
Unable to unify "m x'" with "m x".
```

`reflexivity` 只做**转换**（conversion），不做**重写**（rewrite）；`m x` 与 `m x'` 在 `x ≠ x'`（语法上）时不可转换。必须先 `subst` 或 `rewrite`。

```coq
Theorem t_update_permute : forall (A : Type) (m : total_map A)
                                  v1 v2 x1 x2,
  x2 <> x1 ->
  (x1 !-> v1 ; x2 !-> v2 ; m)
  =
  (x2 !-> v2 ; x1 !-> v1 ; m).
Proof.
  intros A m v1 v2 x1 x2 Hne.
  apply functional_extensionality. intro x'.
  unfold t_update. unfold t_update.
  destruct (String.eqb_spec x1 x') as [Heq1 | Hne1].
  - destruct (String.eqb_spec x2 x') as [Heq2 | Hne2].
    + exfalso. apply Hne. rewrite Heq1. exact Heq2.
    + reflexivity.
  - reflexivity.
Qed.
```

**定律六：更新两个不同的键，顺序无关。** 六条里最绕的一条，值得把目标结构摊开看。`unfold t_update` 两次之后（两个 `unfold` 各消一层），目标是：

```text
(if (x1 =? x') then v1 else (if (x2 =? x') then v2 else m x'))
=
(if (x2 =? x') then v2 else (if (x1 =? x') then v1 else m x'))
```

外层对 `x1 =? x'` 分情况：

- **`x1 = x'`**（拿到 `Heq1`）：左边化简成 `v1`；右边还剩 `if x2 =? x'`，必须再分一次：
  - `x2 = x'`（拿到 `Heq2`）：右边化简成 `v2`，目标 `v1 = v2`——**这是不可能的**，但它与前提矛盾：`Heq1 : x1 = x'`、`Heq2 : x2 = x'` 推出 `x2 = x1`，与 `Hne : x2 <> x1` 冲突。`exfalso` 把目标换成 `False`，`apply Hne` 把目标换成 `x2 = x1`，`rewrite Heq1` 变成 `x2 = x'`，`exact Heq2` 收尾；
  - `x2 <> x'`：右边化简成 `if x1 =? x' then v1 else m x'`，而 `x1 = x'` 让它变成 `v1`，两边都是 `v1`，`reflexivity`。
- **`x1 <> x'`**：左边变成 `if x2 =? x' then v2 else m x'`；右边的内层 `if x1 =? x'` 因为 `x1 <> x'` 直接化简成 `m x'`，于是右边也是 `if x2 =? x' then v2 else m x'`——**两边语法完全相同**，一个 `reflexivity` 解决，不必再对 `x2` 分情况。

前提 `x2 <> x1` 不是摆设。实测反例：

```coq
(* 前提 x2 <> x1 不可省：同一个键更新两次，顺序真的会改变结果 *)
Example permute_needs_distinct :
  ("a" !-> 1 ; "a" !-> 2 ; __ !-> 0) "a" = 1 /\
  ("a" !-> 2 ; "a" !-> 1 ; __ !-> 0) "a" = 2.
Proof. split; reflexivity. Qed.
```

同一个键 `"a"`，两种顺序查出两个不同的值（`1` 与 `2`）。`split; reflexivity` 能过，再次说明**键是具体字符串时一切都可计算**。

六条定律汇总：

| 定律 | 陈述 | 需要外延公理 |
|---|---|---|
| `t_apply_empty` | `(__ !-> v) x = v` | 否（`reflexivity`） |
| `t_update_eq` | `(x !-> v ; m) x = v` | 否（实测 `Closed under the global context`） |
| `t_update_neq` | `x1 <> x2 -> (x1 !-> v ; m) x2 = m x2` | 否（逐点等式，不是映射等式） |
| `t_update_shadow` | `(x !-> v2 ; x !-> v1 ; m) = (x !-> v2 ; m)` | **是** |
| `t_update_same` | `(x !-> m x ; m) = m` | **是** |
| `t_update_permute` | `x2 <> x1 -> (x1 !-> v1 ; x2 !-> v2 ; m) = (x2 !-> v2 ; x1 !-> v1 ; m)` | **是** |

规律一眼可见：**结论是「映射 = 映射」的需要外延公理，结论是「值 = 值」的不需要**。因为前者要比较两个函数对象，后者只是逐点计算。

### 33.6 偏映射 `partial_map`：全映射的一层薄包装

**偏映射**（partial map）：键可以不存在，查找返回 `option`。这是变量表、类型上下文真正需要的形态——「这个变量没定义」必须能被表达。

关键设计：**偏映射不是新造的归纳类型，而是全映射的特例**。

```coq
(* ---------- 33.5 偏映射：全映射的特例 ---------- *)

Definition partial_map (A : Type) := total_map (option A).

Definition empty {A : Type} : partial_map A :=
  t_empty None.

Definition update {A : Type} (m : partial_map A)
           (x : string) (v : A) :=
  (x !-> Some v ; m).
```

三行读完就懂：`partial_map A` 就是「值类型为 `option A` 的全映射」；空映射的默认值是 `None`（所以查不到的键返回 `None`）；更新就是把值包成 `Some v` 再调用全映射的 `t_update`。

**所有六条定律自动继承**——这是这个设计的最大红利，33.6 后半会看到每条提升只要两三行。

记号用 `|->`（区别于全映射的 `!->`）：

```coq
Notation "x '|->' v ';' m" := (update m x v)
  (at level 0, x constr, v at level 200, right associativity).

Notation "x '|->' v" := (update empty x v)
  (at level 0, x constr, v at level 200).
```

第二条是「省略空尾巴」的便利记号：`"Church" |-> true` 等价于 `"Church" |-> true ; empty`。全映射那边没有这条（33.4 的语法坑）。

编译时这两行会各产生一条**警告**（rocq 9.3.0 实测原文）：

```text
Warning: Notations at level 0 should be closed (first and last symbols should
be terminal symbols). [level-0-notation-not-closed,parsing,default]
```

意思：level 0（最低优先级）的记号，首尾应当是**字面 token**（像 `'__'`、`';'` 那样带单引号的），而 `x '|->' v` 的首是变量 `x`、尾是变量 `v`。Rocq 担心它会和别的 level-0 记号产生解析歧义。这是**原书自带的记号**在 9.3 下的真实反应——警告不影响编译（退出码仍是 0），但要知道它在那里、知道为什么。37 章会系统讲 level 与「闭合」的要求。

造一个偏映射并查两次：

```coq
Definition examplepmap :=
  ("Church" |-> true ; "Turing" |-> false).

Example pmap_hit : examplepmap "Church" = Some true.
Proof. reflexivity. Qed.

Example pmap_miss : examplepmap "Godel" = None.
Proof. reflexivity. Qed.
```

`pmap_miss` 是偏映射与全映射的分水岭：查 `"Godel"` 得到 `None`——**「没有」被明确表达出来了**，而不是混进某个默认值里。两条都 `reflexivity`，因为键是具体字符串。

现在把六条定律提升到偏映射。第一条：

```coq
Lemma apply_empty : forall (A : Type) (x : string),
  @empty A x = None.
Proof.
  intros. unfold empty. rewrite t_apply_empty.
  reflexivity.
Qed.
```

`@empty A` 的 `@` 关掉隐式参数（04 章）：这里必须显式给出 `A`，因为目标 `@empty A x = None` 里 `A` 无法从别处反推。`unfold empty` 露出 `t_empty None`，`rewrite t_apply_empty` 套定律一。

第二条，也是**用得最多**的一条：

```coq
Lemma update_eq : forall (A : Type) (m : partial_map A) x v,
  (x |-> v ; m) x = Some v.
Proof.
  intros. Fail rewrite t_update_eq. unfold update. rewrite t_update_eq.
  reflexivity.
Qed.
```

这里又埋了一个 `Fail`，而且是**全章最实用的一个坑**。不 `unfold update` 直接 `rewrite t_update_eq` 会失败，rocq 9.3.0 真实信息（repl 实测）：

```text
Found no subterm matching "(?M1084 !-> ?M1085; ?M1083) ?M1084"
in the current goal.
```

读懂这条报错：`t_update_eq` 的结论是 `(x !-> v ; m) x = v`，Rocq 要找的是「**`!->` 记号**形状的子项」。但目标里写的是 `|->`（偏映射记号），它展开后是 `update m x v`，而 `update` 是个 `Definition`——`rewrite` 做匹配时**不会自动展开定义**（它只在转换层面比较，匹配是语法层面的）。所以必须先 `unfold update`，把 `|->` 还原成 `!->` 形状，`rewrite` 才认得。

**记住这条规则：`rewrite` 认形状，不认含义。** 隔着一层 `Definition` 就认不出来，`unfold` 是万能钥匙。

`update_eq` 太常用了，把它注册进 `auto` 的提示数据库：

```coq
#[global] Hint Resolve update_eq : core.

Example auto_finds_the_hint :
  forall (A : Type) (m : partial_map A) x v, (x |-> v ; m) x = Some v.
Proof. auto. Qed.
```

`auto` 一步解决了和 `update_eq` 一模一样的目标——因为它在 `core` 数据库里找到了这条引理并 `apply` 上去。`#[global]` 属性是 Rocq 8.14+ 的要求：在模块/文件里注册全局 hint 必须显式声明，否则会有「hint 只在本模块可见」的警告。43 章会系统讲 hint 数据库；这里先体会「一条 `Hint Resolve` 换来后续无数证明少写三行」。

剩下四条提升，全是「`unfold update` + 套全映射定律」的机械操作：

```coq
Theorem update_neq : forall (A : Type) (m : partial_map A) x1 x2 v,
  x2 <> x1 ->
  (x2 |-> v ; m) x1 = m x1.
Proof.
  intros A m x1 x2 v H.
  unfold update. rewrite t_update_neq.
  - reflexivity.
  - apply H.
Qed.
```

`rewrite t_update_neq` 之后冒出**两个**子目标：主目标 `(x2 !-> Some v ; m) x1` 被改写成 `m x1`，于是 `reflexivity`；副作用目标是前提 `x2 <> x1`，由假设 `H` 直接 `apply`。这是 `rewrite` 一条「带前提的定理」时的标准形态——前提变成新的子目标。

```coq
Lemma update_shadow : forall (A : Type) (m : partial_map A) x v1 v2,
  (x |-> v2 ; x |-> v1 ; m) = (x |-> v2 ; m).
Proof.
  intros A m x v1 v2. unfold update. rewrite t_update_shadow.
  reflexivity.
Qed.

Print Assumptions update_shadow.
```

遮蔽律提升。注意这里**没有**再出现外延公理的证明步骤——因为 `t_update_shadow` 已经把公理用掉了，提升只是套结论。但公理仍然在依赖链里，实测 `Print Assumptions update_shadow.` 输出与全映射版一字不差：

```text
Axioms:
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
  (forall x : A, f x = g x) -> f = g
```

```coq
Theorem update_same : forall (A : Type) (m : partial_map A) x v,
  m x = Some v ->
  (x |-> v ; m) = m.
Proof.
  intros A m x v H. unfold update. rewrite <- H.
  apply t_update_same.
Qed.
```

「用同值更新等于没更新」的提升。这条的陈述与全映射版**形状不同**：全映射版是 `(x !-> m x ; m) = m`（值直接写成 `m x`），偏映射版多了一个前提 `m x = Some v`，结论是 `(x |-> v ; m) = m`。原因是 `|->` 记号会自动把 `v` 包成 `Some v`，所以「同值」这件事要先用 `H` 把 `Some v` 换回 `m x`。`rewrite <- H` 是**反向**重写（13 章）：把目标里的 `Some v` 换成 `m x`，于是 `update` 展开后正好是 `x !-> m x ; m` 的形状，`apply t_update_same` 收尾。

```coq
Theorem update_permute : forall (A : Type) (m : partial_map A)
                                x1 x2 v1 v2,
  x2 <> x1 ->
  (x1 |-> v1 ; x2 |-> v2 ; m) = (x2 |-> v2 ; x1 |-> v1 ; m).
Proof.
  intros A m x1 x2 v1 v2. unfold update.
  apply t_update_permute.
Qed.

Print update_permute.
```

交换律提升。这条证明短得可疑——`intros` 只引入了六个量词，**没有**引入前提 `x2 <> x1`，目标此刻还是 `x2 <> x1 -> (x1 |-> v1 ; ...) = (...)`；然后一句 `apply t_update_permute` 就 `Qed` 了，没有任何子目标残留。为什么前提不用证？

`Print update_permute.` 给出答案（实测输出）：

```text
update_permute =
fun (A : Type) (m : partial_map A) (x1 x2 : string) (v1 v2 : A) =>
t_update_permute (option A) m (Some v1) (Some v2) x1 x2
:
x2 <> x1 -> (x1) |-> v1; (x2) |-> v2; m = (x2) |-> v2; (x1) |-> v1; m
     : forall (A : Type) (m : partial_map A) (x1 x2 : string) (v1 v2 : A),
       x2 <> x1 -> (x1) |-> v1; (x2) |-> v2; m = (x2) |-> v2; (x1) |-> v1; m

Arguments update_permute A%_type_scope m (x1 x2)%_string_scope v1 v2 _
```

证明项就是 `t_update_permute (option A) m (Some v1) (Some v2) x1 x2`——**一个还没吃掉前提的函数**。它的类型 `x2 <> x1 -> ...` 与目标的类型 `x2 <> x1 -> ...` 完全一致，于是 `apply` 把**整条箭头**（前提 + 结论一起）统一掉了，直接产出零个子目标。

这里能统一成功的关键是 `unfold update`：它把 `|->` 记号还原成 `!->` 形状，`apply` 才认得（同 33.6 的 `rewrite` 坑）。前提 `x2 <> x1` 则**原封不动地留在类型里**，等最终使用者去提供——这正是我们想要的：引理不该替调用者假设键互异。

**对照**：`update_neq` 那条为什么就多了一个子目标？因为它的 `intros` 把前提 `x2 <> x1` 引进成了假设 `H`，目标只剩等式本身；`apply`/`rewrite` 只匹配等式，于是前提作为副作用目标冒出来，由 `H` 填上。**同一组定律，`intros` 引到哪一步，决定了前提是自己证还是留给调用者**——这是写引理时要有意识的选择。

### 33.7 `includedin`：映射之间的包含关系

偏映射之间有一个常用的关系：「`m` 的所有绑定在 `m'` 里也都成立」。

```coq
(* ---------- 33.6 includedin：一个映射包含另一个 ---------- *)

Definition includedin {A : Type} (m m' : partial_map A) :=
  forall x v, m x = Some v -> m' x = Some v.
```

注意它是 `Definition` 而不是 `Inductive`——一个映射到 `Prop` 的**函数**（15 章的谓词可以是函数式的）。读法：对任意键 `x` 和值 `v`，只要 `m` 在 `x` 处查到 `Some v`，`m'` 在 `x` 处也查到同一个 `Some v`。`m'` 可以有更多绑定，但**不能改动** `m` 已有的绑定。

这个关系在「带变量绑定的语言」里极其有用：44 章的 STLC 用它表达「子上下文」，38 章的 Imp 用它表达「状态扩展」。

最重要的性质：**更新同一个键，保持包含关系。**

```coq
Lemma includedin_update : forall (A : Type) (m m' : partial_map A)
                                 (x : string) (vx : A),
  includedin m m' ->
  includedin (x |-> vx ; m) (x |-> vx ; m').
Proof.
  unfold includedin.
  intros A m m' x vx H.
  intros y vy.
  destruct (String.eqb_spec x y) as [Hxy | Hxy].
  - rewrite Hxy.
    rewrite update_eq. rewrite update_eq. intro H1. apply H1.
  - rewrite update_neq.
    + rewrite update_neq.
      * apply H.
      * apply Hxy.
    + apply Hxy.
Qed.
```

证明结构值得逐层拆：

1. `unfold includedin` 把定义展开成 `forall y vy, ... -> ...`（先展开再 `intros`，否则 `intros` 只能引入到 `includedin` 这层 opaque 名字为止——其实 `intros` 能穿过透明定义，但显式 `unfold` 让目标可读）；
2. 引入要查的键 `y` 和值 `vy`，目标变成 `(x |-> vx ; m) y = Some vy -> (x |-> vx ; m') y = Some vy`；
3. `destruct (String.eqb_spec x y)`：分「`y` 就是被更新的 `x`」与「不是」两种；
4. **正分支**（`Hxy : x = y`）：`rewrite Hxy` 把 `y` 换成 `x`，两边都变成「更新后查同一个键」，各 `rewrite update_eq` 得到 `Some vx = Some vx` 形状，`intro H1. apply H1` 收尾；
5. **负分支**（`Hxy : x <> y`）：两边都 `rewrite update_neq`（用 `Hxy` 填前提），目标退化成 `m y = Some vy -> m' y = Some vy`，正是假设 `H : includedin m m'`。

两个基础引理，一个自反、一个「空映射包含于任何映射」：

```coq
Lemma includedin_refl : forall (A : Type) (m : partial_map A),
  includedin m m.
Proof.
  intros A m x v H. exact H.
Qed.

Lemma includedin_empty : forall (A : Type) (m : partial_map A),
  includedin empty m.
Proof.
  intros A m x v H. unfold empty in H. rewrite t_apply_empty in H.
  discriminate H.
Qed.
```

`includedin_empty` 的证明是个漂亮的小推理：`empty` 就是 `t_empty None`，所以 `H : empty x = Some v` 经 `unfold empty` + `rewrite t_apply_empty` 变成 `H : None = Some v`——`None` 与 `Some v` 是**不同构造子**，`discriminate` 直接引爆（13 章）。也就是说前提恒假，蕴含式恒真。

两条合起来，可以一步证出一个具体例子：

```coq
Example included_example :
  includedin ("Church" |-> true)
             ("Church" |-> true ; "Turing" |-> false).
Proof.
  apply includedin_update. apply includedin_empty.
Qed.
```

读法：右边 = `("Church" |-> true ; ("Turing" |-> false))` = `update ("Turing"|->false) "Church" true`，左边 = `update empty "Church" true`。`includedin_update` 说「只要 `includedin empty ("Turing"|->false)`，就有结论」，而这正是 `includedin_empty`。**两行 `apply` 替代了原本要分情况讨论的十几行**——这就是把性质封装成引理的回报。

### 33.8 对照实验：列表版映射为什么不好用

为了看清函数表示到底赚了多少，我们手写一个**列表版**映射（关联列表，association list）做对照。

```coq
(* ---------- 33.7 对照：列表版映射为什么不好用 ---------- *)

Definition alist := list (string * nat).

Fixpoint alookup (l : alist) (x : string) : option nat :=
  match l with
  | [] => None
  | (k, v) :: l' => if String.eqb k x then Some v else alookup l' x
  end.

Definition aupdate (l : alist) (x : string) (v : nat) : alist :=
  (x, v) :: l.
```

`alist` 是「键值对列表」；`alookup` 从头扫，命中就返回，扫完返回 `None`；`aupdate` 直接把新对**cons 到表头**（不删旧的——删旧的要先 filter，更慢）。

这个实现有两个立即可见的后果。第一，**遮蔽的旧绑定还留在列表里**：

```coq
Example alist_shadow_keeps_both :
  aupdate (aupdate [] "a" 1) "a" 2
  = ("a"%string, 2) :: ("a"%string, 1) :: [].
Proof. reflexivity. Qed.
```

两个 `("a", ...)` 都在。查找时靠「从头扫、先命中先返回」保证拿到最新的：

```coq
Example alist_lookup_hits_newest :
  alookup (aupdate (aupdate [] "a" 1) "a" 2) "a" = Some 2.
Proof. reflexivity. Qed.
```

**行为是对的，但表示是冗余的。** 于是问题来了：`[("a",2);("a",1)]` 和 `[("a",2)]` 在「映射」的意义上是同一个映射，但作为**列表它们不相等**（长度都不同）。要表达「两个列表版映射等价」，你必须**另造一个等价关系**：

```text
m ≅ m'  :=  forall x, alookup m x = alookup m' x
```

然后证明 `≅` 自反、对称、传递，证明它被 `aupdate` 保持（congruence），并且**所有**关于映射的定理都要改用 `≅` 而不是 `=` 来陈述。`rewrite` 一个 `≅` 还需要先 `setoid_rewrite` 并注册 morphism 实例——这是一整套额外机器。

函数表示把这一整套机器**全部省掉**：等价关系就是 Leibniz 等号 `=`，`rewrite` 直接可用，自反/对称/传递由 `eq` 自带。代价只是一条 `functional_extensionality` 公理（33.5 实测）。

顺带记录一个**实测到的作用域坑**：上面 `alist_shadow_keeps_both` 里我写的是 `("a"%string, 2)`。最初写成 `("a", 2)`，rocq 9.3.0 报错：

```text
Error: No interpretation for string "a".
```

原因：在 `("a", 2)` 这个**积类型**里，Rocq 无法从上下文推断 `"a"` 该按哪个作用域解读（积的两个分量类型此刻还没被期望类型约束住），而 33.2 的 `Locate` 已经告诉我们 `=?`/字符串字面量的默认解读是 nat。加 `%string` 显式标注即可。同样的坑在 `aupdate [] "a" 1` 里**不会**出现——因为那里 `"a"` 处在 `x : string` 的参数位，期望类型已知。

**规则：字符串字面量出现在「类型未知」的位置（积、列表元素、`@` 显式参数）时，补 `%string`。**

### 33.9 预演：Imp 的 `state` 就是 `total_map nat`

最后把本章的成果接到 38 章。Imp 语言的**状态**（state）就是「变量名 → 当前值」的映射。变量总有值（未赋值的变量约定为 0），所以用**全**映射，默认值 0：

```coq
(* ---------- 33.8 预演：Imp 的 state 就是 total_map nat ---------- *)

Definition state := total_map nat.

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

Definition empty_st : state := __ !-> 0.
```

`X`/`Y`/`Z` 是三个变量名（38 章会用更多）。`empty_st` 是初始状态：所有变量都是 0。

赋值语句 `X := 2` 的语义就是 `X !-> 2 ; st`。四条性质实测：

```coq
Example state_assign : (X !-> 2 ; empty_st) X = 2.
Proof. apply t_update_eq. Qed.
```

赋完值查同一个变量，得到新值——定律二。这里用 `apply` 而不是 `reflexivity`：因为 `X` 是个 `Definition`（`"X"`），`reflexivity` 也能过（展开后是可计算的），但 `apply t_update_eq` 表明「这一步走的是定律，不是计算」——38 章的语义证明里键往往是**变量**而非具体字符串，那时只有定律可用。

```coq
Example state_other : (X !-> 2 ; empty_st) Y = 0.
Proof. reflexivity. Qed.
```

查别的变量，得到默认值 0。键是具体字符串，`reflexivity` 直接算出来。

```coq
Example state_other_via_lemma : forall st : state, (X !-> 2 ; st) Y = st Y.
Proof. intros st. apply t_update_neq. unfold X, Y. discriminate. Qed.
```

**这才是 38 章真正会用的形态**：状态 `st` 是**任意的**（不是具体的 `empty_st`），所以不能计算，只能靠定律三。前提 `X <> Y` 的证明：`unfold X, Y` 把两个定义展开成 `"X" <> "Y"`，`discriminate` 识别出是两个不同的字符串构造子链，直接证伪。

注意 `unfold X, Y` 这一步不可省：`discriminate` 需要看到**构造子**层面的差异，而 `X`/`Y` 作为 `Definition` 名字挡住了它。

```coq
Example state_shadow : (X !-> 5 ; X !-> 2 ; empty_st) X = 5.
Proof. apply t_update_eq. Qed.

Example state_shadow_gone : (X !-> 5 ; X !-> 2 ; empty_st) Y = 0.
Proof. reflexivity. Qed.
```

连续赋值同一个变量，只有最后一次算数（定律四的效果，但这里键具体所以 `t_update_eq` 就够）；而被遮蔽的旧值对别的变量毫无影响。

```coq
End Ex33Maps.
```

### 33.10 本章坑位清单（实测）

1. **`=?` 默认按 nat 解读**（33.2）：`Locate "=?"` 实测显示 `(default interpretation)` 标在 `Nat.eqb` 上。写字符串比较的定理时**必须**加 `%string`，否则报「No interpretation for string」。
2. **先 `intros` 再 `unfold`/`rewrite`**（33.5）：`rewrite` 够不到 `forall` 量词内部的子项，实测报错 `Found no subterm matching "(?M =? ?M)%string"`。顺序反了就白跑一趟。
3. **`reflexivity` 不做重写**（33.5）：`m x` 与 `m x'` 在 `e : x = x'` 存在时仍不可转换，实测 `Unable to unify "m x'" with "m x"`。先 `subst` 或 `rewrite e`，再 `reflexivity`。
4. **「映射 = 映射」必须上外延公理**（33.5）：`Fail exact eq_refl` 实测报错 `cannot unify "x !-> v2; x !-> v1; m" and "x !-> v2; m"`。`Print Assumptions t_update_shadow` 实测列出 `functional_extensionality_dep`——这条公理是函数表示的全部代价，写进论文/报告时要声明。
5. **`rewrite` 认形状不认含义**（33.6）：隔着 `Definition update` 一层，`rewrite t_update_eq` 实测失败 `Found no subterm matching "(?M !-> ?M; ?M) ?M"`。先 `unfold update`。**这是偏映射证明里最高频的卡点。**
6. **全映射的 `!->` 尾巴不可省**（33.4）：`("a" !-> true)` 实测语法报错 `';' expected after [term level 100]`。偏映射有专门的 `x '|->' v` 两段式记号，全映射没有。
7. **level-0 记号应当闭合**（33.6）：`x '|->' v` 首尾是变量，rocq 9.3.0 实测警告 `Notations at level 0 should be closed`。警告不阻断编译，但提示可能有解析歧义；37 章详解。
8. **字符串字面量在积/列表里要补 `%string`**（33.8）：`("a", 2)` 实测报 `No interpretation for string "a"`；在已知参数类型的位置（`aupdate [] "a" 1`）则不用。
9. **`Hint` 注册要写 `#[global]`**（33.6）：`#[global] Hint Resolve update_eq : core.` 之后 `auto` 实测能一步解决同款目标。漏掉 `#[global]`，hint 的作用域会受限（43 章系统讲）。
10. **列表版映射要另造等价关系**（33.8）：`[("a",2);("a",1)]` 与 `[("a",2)]` 是同一个映射但不相等的列表。除非你需要遍历键，否则**一律用函数表示**。

---
上一章：[32 · 综合实战：表达式解释器与优化器](32-project.md) ｜ 下一章：[34 · 证明即项：Curry–Howard 落地](34-proof-terms.md) ｜ 返回：[README](../README.md)
