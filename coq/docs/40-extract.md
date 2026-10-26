# 40 · 抽取：把验证代码变成 OCaml

对应示例：`../examples/40_extract.v`（`Module Ex40Extract`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

第 32 章的收尾处我们第一次用了 `Recursive Extraction`：一行命令，把验证过的优化器打印成 OCaml。当时它像个黑盒。第 39 章又验证了一个完整的二叉搜索树——但验证完的程序还住在 Rocq 里，跑不进真实工程。本章把这条「最后一公里」走通，并拆开黑盒回答四个问题：

1. **抽取为什么是对的**——凭什么抹掉证明不破坏程序？（40.1）
2. **抽出来的代码长什么样**——`Recursive Extraction` 的产物怎么读，怎么让它贴着 OCaml 原生类型走？（40.2）
3. **数系怎么办**——`nat` 抽出来是一元符号数，性能不可接受；VFA《Extract》章的「轻量 int 抽象」如何用四条假设把键换成 OCaml 的 `int`？（40.3）
4. **验证过的 BST 抽出来是什么**——第 39 章风格的树结构完整导出成 `.ml`/`.mli` 文件、在 OCaml 编译器下真跑测速，公理与 Module 抽象层在产物里如何处理？（40.4–40.6）

素材取自 VFA（*Verified Functional Algorithms*）的 `Extract` 章，示例自包含：本章抽取的每一个函数都在 `40_extract.v` 里现场定义、现场验证。

### 40.1 证明被抹掉：抽取的第一原理

Rocq 的项住在两个世界里（第 49 章会系统展开）：`Prop` 大类的**证明**，与 `Set`/`Type` 大类的**计算**。抽取（extraction）的合法性建立在一条定理上：把 `Prop` 部分从任何项里抹掉，不改变这个项作为程序的行为——证明只是**伴随计算出现的凭证**，运行时用不到。所以抽取器做的事就是：**沿着依赖走，保留计算，抹掉证明**。

本章全部代码包在与各章一致的模块里：

```coq
(* 40 抽取：把验证代码变成 OCaml —— 证明擦除、Recursive Extraction、
   轻量 int 抽象、39 章风格 BST 的导出与 Module 抽象层的处理 *)

From Stdlib Require Import Arith Lia Bool List ZArith Extraction.
Import ListNotations.

Module Ex40Extract.
```

一行 `Require` 拉进六个库、一行 `Import` 打开记号，各有用途：`Extraction` 提供抽取命令本体（32 章实测过：裸写 `Recursive Extraction` 报非法命令）；`Arith` 提供 40.1/40.2 要用的 `Nat` 比较函数与引理；`Bool` 提供 40.3 要用的 `iff_reflect`；`ZArith` 提供 `Z`；`List` 加 `Import ListNotations` 服务 40.2 的排序与 40.4 的 `elements`（`[]`/`::` 记号）；`Lia` 服务全部算术证明。

第一个观察对象是一个「证明携带函数」（第 26 章的强规范风格）：

```coq
(* ---------- 40.1 证明被抹掉：抽取的第一原理 ---------- *)

(* 证明携带函数一：左边是 sigma（Set），右边是 Prop，整体是 sumor *)
Definition zero_or_succ (n : nat) : {m : nat | n = S m} + {n = 0}.
Proof. destruct n as [|m].
- right; reflexivity.
- left; exists m; reflexivity.
Defined.

Extraction zero_or_succ.
```

类型读法：左边 `{m : nat | n = S m}` 是 sigma 类型（携带证明的值），右边 `{n = 0}` 是纯命题，所以整体落在 `sumor`（Type + Prop 的和）上——第 26 章讲过这套「或携带或不携带」的谱系。函数体用证明脚本写（`destruct` 分情况、`exists` 交出见证），**以 `Defined.` 收尾**——证明携带函数必须透明（原因见 40.7 坑位 1）。

`Extraction` 命令打印**这一个常量**的 OCaml 翻译。rocq 9.3.0 的真实输出：

```text
(** val zero_or_succ : nat -> nat sumor **)

let zero_or_succ = function
| O -> Inright
| S n0 -> Inleft n0
```

读三件事：① `n = 0` 那份**证明整个消失了**——`Inright` 不携带任何参数，它只是一个标签；② 左边的 sigma 塌缩成裸 `nat`——`Inleft n0` 带的是见证值 `n0`，而「`n = S n0`」这份证明没了；③ 证明脚本 `destruct`/`exists`/`reflexivity` 的**分情况结构**留下了（`O`/`S` 两个分支），这正是「计算保留、证明抹掉」。

但上面不是完整程序：`sumor` 这个类型本身没定义，`nat` 也没定义。`Recursive Extraction` 才会把依赖闭包全部抽出来：

```coq
Recursive Extraction zero_or_succ.
```

真实输出：

```text
type nat =
| O
| S of nat

type 'a sig0 = 'a
  (* singleton inductive, whose constructor was exist *)

type 'a sumor =
| Inleft of 'a
| Inright

module Ex40Extract =
 struct
  (** val zero_or_succ : nat -> nat sumor **)

  let zero_or_succ = function
  | O -> Inright
  | S n0 -> Inleft n0
 end
```

四个观察，每个都会在本章反复出现：

- **sigma 类型抽成类型别名**：`type 'a sig0 = 'a`，Rocq 还自动注释了原因——`sig` 是单构造子归纳（`exist`），构造子只在做证明，抹掉后只剩载体；
- **`nat` 被复刻**成 `O | S of nat`——一元自然数，40.2 会专门讨论它的代价；
- **sumor 抽成两个构造子的变体**，`Inright` 不带数据（Prop 分支零载荷）；
- **本章的包裹层 `Module Ex40Extract.` 变成了 OCaml 的 `module Ex40Extract = struct ... end`**——模块边界被忠实翻译，40.6 专门讨论。

再看对照组——一条普通的 `Qed` 定理：

```coq
(* 对照组：一条普通定理（Qed 收尾）抽出来是什么 *)
Theorem erased_theorem : forall n : nat, n + 0 = n.
Proof. intros n. lia. Qed.

Extraction erased_theorem.
```

真实输出：

```text
(** val erased_theorem : __ **)

let erased_theorem =
  __
```

**类型和值都成了占位符 `__`**。整条定理住在 `Prop` 里，没有任何可保留的计算——抽取器连函数体都懒得给。这就是「证明是开发期的脚手架，运行期零开销」的字面意思：定理抽出来是空气，定理**引用的函数**抽出来才是程序。

第二个证明携带函数把「保留」的那一半看得更清楚：

```coq
(* 证明携带函数二：sumbool——判决过程保留，携带的证明被抹掉 *)
Definition leb_dec (n m : nat) : {n <= m} + {m < n}.
Proof.
  destruct (Nat.leb_spec0 n m) as [H | H].
  - left. exact H.
  - right. lia.
Defined.

Extraction leb_dec.
```

真实输出：

```text
(** val leb_dec : nat -> nat -> sumbool **)

let leb_dec n m =
  let r = Nat.leb_spec0 n m in
  (match r with
   | ReflectT -> Left
   | ReflectF -> Right)
```

注意 `Nat.leb_spec0` **被保留了**：判决 `n <=? m` 的过程是真实的计算（要递归下降比较两个一元数），抹掉它函数就没法跑了；被抹掉的是每个分支携带的证明 `H`——OCaml 里 `Left`/`ReflectT` 都是裸标签。`sumbool` 默认抽成 `Left | Right` 变体而非 OCaml 的 `bool`，想要原生 `bool` 得自己加映射（VFA 及 CompCert 的惯用写法，在 /tmp 实测有效）：

```coq
Extract Inductive sumbool => "bool" [ "true" "false" ].
```

映射后 `leb_dec` 的类型变成 `nat -> nat -> bool`，`match r with ReflectT -> true | ReflectF -> false`。这行没写进示例文件——它会让后续所有抽取产物的 `sumbool` 都变成 `bool`，属于「要不要全局生效」的工程决策。

Coq 里函数行为没变，做个冒烟测试：

```coq
Compute (match zero_or_succ 5 with inleft _ => 111 | inright _ => 222 end).
```

真实输出：

```text
     = 111
     : nat
```

`zero_or_succ 5` 算出 `inleft 4`（见证是 4，证明是 `eq_refl`），match 走 `111` 分支。顺带一个容易踩的小坑：`sumor` 的构造子是**小写**的 `inleft`/`inright`（`sumbool` 才是 `left`/`right`），想当然写 `Inleft` 会报 `Unknown constructor: Inleft`（实测）。

最后一块拼图：凭什么 `leb_dec` 里对 `Nat.leb_spec0` 的 `destruct` 能产生可保留的计算？打印 `reflect` 的定义：

```coq
(* 为什么 leb_dec 里的判决没被抹掉：9.3 的 reflect 已经是 Set 大类 *)
Print reflect.
```

真实输出：

```text
Inductive reflect (P : Prop) : bool -> Set :=
    ReflectT : P -> reflect P true | ReflectF : ~ P -> reflect P false.

Arguments reflect P%_type_scope _%_bool_scope
Arguments ReflectT P%_type_scope _
Arguments ReflectF P%_type_scope _
```

第一行是重点：在 rocq 9.3 + stdlib 9.2.0 里，`reflect` 的排序是 **`bool -> Set`**——它本身是计算物！老资料里 `reflect` 是 `Prop` 大类、`destruct` 受消去限制的日子已经过去了（这正是第 31 章自反证明能「用计算代替推理」的底层许可：reflect 值可以出现在任何位置）。所以抽取器把它抽成 `type reflect = ReflectT | ReflectF` 的裸变体，第 31 章的桥定理们也就都能安全落地成代码。

### 40.2 Recursive Extraction：第一个完整程序

40.1 的 `zero_or_succ` 是玩具。本节走一遍 VFA《Extract》章的标准例子——插入排序（第 23 章验证过它的正确性，这里只要定义，自包含）：

```coq
(* ---------- 40.2 Recursive Extraction：第一个完整程序 ---------- *)

(* 自包含的插入排序（VFA《Extract》章的例子） *)
Fixpoint ins (i : nat) (l : list nat) :=
  match l with
  | [] => [i]
  | h :: t => if i <=? h then i :: h :: t else h :: ins i t
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | h :: t => ins h (sort t)
  end.

Compute (sort [3; 1; 2]).
```

`Compute` 确认程序在 Coq 里能跑：

```text
     = [1; 2; 3]
     : list nat
```

单抽一个常量：

```coq
Extraction sort.
```

真实输出：

```text
(** val sort : nat list -> nat list **)

let rec sort = function
| Nil -> Nil
| Cons (h, t) -> ins h (sort t)
```

**这不是完整程序**：`ins`、`Nil`、`Cons` 都被引用但没有定义，贴进 OCaml 工程编译不过。`Extraction` 只翻一层皮。要整个依赖闭包：

```coq
Recursive Extraction sort.
```

真实输出（完整）：

```text
type bool =
| True
| False

type nat =
| O
| S of nat

type 'a list =
| Nil
| Cons of 'a * 'a list

module Nat =
 struct
  (** val leb : nat -> nat -> bool **)

  let rec leb n m =
    match n with
    | O -> True
    | S n' -> (match m with
               | O -> False
               | S m' => leb n' m')
 end

module Ex40Extract =
 struct
  (** val ins : nat -> nat list -> nat list **)

  let rec ins i = function
  | Nil -> Cons (i, Nil)
  | Cons (h, t) ->
    (match Nat.leb i h with
     | True -> Cons (i, (Cons (h, t)))
     | False -> Cons (h, (ins i t)))

  (** val sort : nat -> nat list -> nat list **)

  let rec sort = function
  | Nil -> Nil
  | Cons (h, t) -> ins h (sort t)
 end
```

读这份产物的四个要点：

1. **Rocq 自己的 `bool`/`list` 被复刻了一遍**——`type bool = True | False`、`type 'a list = Nil | Cons ...`。它们与 OCaml 原生的 `bool`/`list` 同构但**不同类型**：抽出来的函数没法直接吃 OCaml 工程里的普通列表，得手工搬运；
2. **`if i <=? h` 变成了 `match Nat.leb i h with True -> ... | False -> ...`**——Coq 的 `if` 只是 `bool` 上 match 的语法糖，产物里 sugar 被剥掉（除非映射成原生 `bool`，见下）；
3. **标准库的 `Nat` 模块成了 OCaml 的 `module Nat`**，只带用到的 `leb`；
4. **排序的 `<=?` 在一元数上工作**：`Nat.leb` 每步剥一层 `S`，比较两个数要花与较大者成正比的时间——VFA 的原话是，7 这个数在 OCaml 里是真的七层指针深。性能敏感的抽取目标必须规划数系（32.7 坑位 4 提过），40.3 给出方案。

前两条有一个官方解法：`Extract Inductive` 把 Rocq 的归纳类型**映射**到 OCaml 已有的类型上，构造子逐个对号：

```coq
(* 让抽取产物直接用 OCaml 原生的 bool 和 list *)
Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "(::)" ].

Recursive Extraction sort.
```

两条指令分别声明：`bool` 抽成 `bool`（构造子 `true`/`false`）、`list` 抽成 `'a list`（构造子 `[]` 与 `::`）。再抽一次，真实输出：

```text
type nat =
| O
| S of nat

module Nat =
 struct
  (** val leb : nat -> nat -> bool **)

  let rec leb n m =
    match n with
    | O -> true
    | S n' -> (match m with
               | O -> false
               | S m' => leb n' m')
 end

module Ex40Extract =
 struct
  (** val ins : nat -> nat list -> nat list **)

  let rec ins i = function
  | [] -> i::[]
  | h::t -> if Nat.leb i h then i::(h::t) else h::(ins i t)

  (** val sort : nat -> nat list -> nat list **)

  let rec sort = function
  | [] -> []
  | h::t -> ins h (sort t)
 end
```

变化立竿见影：`bool`/`list` 的类型定义消失了，`Nat.leb` 返回原生 `true`/`false`，于是 `if Nat.leb i h then ... else ...` 恢复成真正的 OCaml `if`——这份代码可以直接和任何 OCaml 列表代码互操作。唯一原封不动的是一元 `nat`。

### 40.3 轻量 int 抽象：Parameter + Extract Inlined Constant

数系的选项 VFA 列了四种：直接抽 `nat`（一元，慢）；换 `Z`（二进制，但对数时间且产物带一套 `Z` 的运载代码）；`Int63`（忠实建模 63 位循环算术，抽取到 OCaml 的 `int`，但用起来痛苦）；以及本节的主角——**轻量抽象**：在 Coq 里假设一个 `int` 类型，抽取时直接映射到 OCaml 的 `int`，比较运算映射到 OCaml 的原生比较。CompCert 的 `Int32`/`Float` 等外部世界类型都是这条路。

```coq
(* ---------- 40.3 轻量 int 抽象：Parameter + Extract Inlined Constant ---------- *)

Open Scope Z_scope.

Parameter int : Type.
Extract Inlined Constant int => "int".
```

`Open Scope Z_scope` 放在这里有讲究：它会让 `<=?`、`<` 等记号**默认按 `Z` 解读**，所以必须放在 40.2 的 `nat` 排序代码**之后**（实测：放开头会让 `if i <=? h` 直接报「`n` 的类型是 `nat`，却被期望为 `Z`」，报错原文见 40.7 坑位 5）。`Parameter int : Type.` 假设一个类型（第 18 章的 `Module Type` 里用过同款机制——接口里「有个类型 t」就是这么说的），`Extract Inlined Constant int => "int".` 声明它抽取成 OCaml 的 `int`——`Inlined` 的意思是把映射串**内联贴到每个出现点**，而不是生成一个同名 OCaml 值。

接下来是这座桥的诚实性设计。`int` 的语义靠一条到 `Z` 的抽象函数和四条假设钉死：

```coq
Parameter Abs : int -> Z.
Axiom Abs_inj : forall (n m : int), Abs n = Abs m -> n = m.

Parameter ltb : int -> int -> bool.
Extract Inlined Constant ltb => "( < )".
Axiom ltb_lt : forall (n m : int), ltb n m = true <-> Abs n < Abs m.
```

四行两两成对：

- `Abs` 把每个 OCaml `int` 送进 `Z`（单方向——`Z` 无限，`int` 只有 2^63 个）；`Abs_inj` 说这个映射是单射：`Abs` 相等则 `int` 相等。它**只在证明里用**，没有抽取映射——抽取器永远不会为它生成代码；
- `ltb` 是假设的比较函数，抽取成 OCaml 的 `<`（算子节写法 `( < )`）；`ltb_lt` 把「`ltb` 算出 `true`」与「`Abs` 意义下的小于」焊在一起。同样只有 `ltb` 有映射。

这套设计的危险之处必须说透（VFA 的原例）：**公理若不忠实于 OCaml，所有证明作废**。比如想把 `+` 也这样接上：

```coq
Parameter ocaml_plus : int -> int -> int.
Extract Inlined Constant ocaml_plus => "( + )".
Axiom ocaml_plus_plus : forall a b c : int,
  ocaml_plus a b = c <-> Abs a + Abs b = Abs c.
```

前两行没问题——OCaml 真有 `+`，类型也对。但 `ocaml_plus_plus` **不健全**：由它能证 `Abs max_int + Abs max_int = Abs (ocaml_plus max_int max_int)`，而 OCaml 里 `max_int + max_int` 溢出回绕，等式不成立。`ltb_lt` 之所以健全，是因为 OCaml 的 `<` 在全部 `int` 上与 `Z` 的比较一致；`+` 的溢出打破了这一点。**给每个想映射的运算单独审查公理的忠实性**，是轻量抽取的纪律。

假设立好了，先备两条证明零件。第一条是把 `ltb_lt` 包装成 `reflect`（第 31 章的桥定理模式）：

```coq
(* 反映桥：把公理包装成 reflect，主证明里就能 destruct 出 Abs 事实 *)
Lemma int_ltb_reflect : forall x y, reflect (Abs x < Abs y) (ltb x y).
Proof.
  intros x y. apply iff_reflect. symmetry. apply ltb_lt.
Qed.
```

`iff_reflect` 把 `iff` 折成 `reflect`（`symmetry` 是因为方向要倒过来）。有了它，主证明里一句 `destruct (int_ltb_reflect x y) as [H | H]` 同时做三件事：把目标里的 `if ltb x y` 拆掉、正分支白送 `Abs x < Abs y`、负分支白送 `~ Abs x < Abs y`——布尔世界与 `Z` 世界一次对齐。40.1 已经看到 9.3 的 `reflect` 是 `Set` 大类，destruct 毫无限制。

第二条零件是自反性：

```coq
Lemma ltb_irrefl : forall x, ltb x x = false.
Proof.
  intros x. destruct (ltb x x) eqn:E.
  - exfalso. assert (Hlt := proj1 (ltb_lt x x) E). lia.
  - reflexivity.
Qed.
```

套路：对 `ltb x x` 分情况，`true` 分支用 `ltb_lt` 的正向读出 `Abs x < Abs x`，`lia` 引爆（`Abs x` 是 `Z` 原子，`lia` 把它当变量处理——这就是抽象到 `Z` 的全部红利：算术自动化直接可用）；`false` 分支正是要证的。

### 40.4 39 章风格 BST：int 键，验证后待抽取

现在把第 39 章验证过的二叉搜索树换个键类型重做一遍：结构（`E`/`T`、`lookup`/`insert`/`elements`）与 39 章同源，键从 `nat` 换成 40.3 的抽象 `int`——抽取出来就直接是 OCaml `int` 键的树。

```coq
(* ---------- 40.4 39 章风格 BST：int 键，验证后待抽取 ---------- *)

Definition key := int.

Inductive tree (V : Type) : Type :=
  | E : tree V
  | T : tree V -> key -> V -> tree V -> tree V.

Arguments E {V}.
Arguments T {V}.

Definition empty_tree {V : Type} : tree V := E.
```

`tree V` 是值类型参数化的 BST 形状：叶 `E` 不存值，节点 `T 左 键 值 右`。两行 `Arguments` 把 `V` 设为隐式（写 `T E x v E` 不必显式给 `V`）。`empty_tree` 就是 `E`。

```coq
Fixpoint lookup {V : Type} (default : V) (x : key) (t : tree V) : V :=
  match t with
  | E => default
  | T l k v r => if ltb x k then lookup default x l
                else if ltb k x then lookup default x r
                     else v
  end.

Fixpoint insert {V : Type} (x : key) (v : V) (t : tree V) : tree V :=
  match t with
  | E => T E x v E
  | T l y v' r => if ltb x y then T (insert x v l) y v' r
                 else if ltb y x then T l y v' (insert x v r)
                      else T l x v r
  end.
```

`lookup` 查不到返回默认值（弱规范，第 26 章）；三个分支对应「键小于根去左 / 大于根去右 / 等于根命中」。`insert` 同款三分支：小的往左插、大的往右插、等于则**替换值**。

```coq
Fixpoint elements_aux {V : Type}
         (t : tree V) (acc : list (key * V)) : list (key * V) :=
  match t with
  | E => acc
  | T l k v r => elements_aux l ((k, v) :: elements_aux r acc)
  end.

Definition elements {V : Type} (t : tree V) : list (key * V) :=
  elements_aux t [].
```

`elements` 把树摊平成键值对列表：累加器版本保证线性时间，右子树先摊、`(k, v)` cons 到前面、再摊左子树——出来的恰好是按键**升序**的列表（这是 39 章证明过的核心性质，本章不再重复，只抽取）。

三条定理（前两条 VFA 原书留作练习，这里证全）：

```coq
Theorem lookup_empty : forall (V : Type) (default : V) (k : key),
    lookup default k empty_tree = default.
Proof. auto. Qed.
```

空树处处返回默认值，`auto` 一步（`empty_tree` 展开成 `E`，`lookup` 化简即得）。

```coq
Theorem lookup_insert_eq :
  forall (V : Type) (default : V) (t : tree V) (k : key) (v : V),
    lookup default k (insert k v t) = v.
Proof.
  intros V default t. induction t as [| l IHl y v' r IHr]; intros k v; simpl.
  - rewrite !ltb_irrefl. reflexivity.
  - (* simpl 后再 destruct reflect：一次拆掉 insert 与 lookup 里的同一个 if *)
    destruct (int_ltb_reflect k y) as [Hk | Hk]; simpl.
    + destruct (int_ltb_reflect k y) as [Hk2 | Hk2].
      * apply IHl.
      * exfalso; lia.
    + destruct (int_ltb_reflect y k) as [Hy | Hy]; simpl.
      * destruct (int_ltb_reflect k y) as [Hk2 | Hk2].
        -- exfalso; lia.
        -- destruct (int_ltb_reflect y k) as [Hy2 | Hy2].
           ++ apply IHr.
           ++ exfalso; lia.
      * rewrite !ltb_irrefl. reflexivity.
Qed.
```

「插入后查同一个键得到新值」。叶分支：插入生成单节点树，两个 `if ltb k k` 都被 `ltb_irrefl` 消成 `false`，露出 `v`。节点分支的形状值得慢读——这里藏着本章最大的证明坑（40.7 坑位 3）：

- 第一次 `destruct (int_ltb_reflect k y)` 拆的是**此刻**目标里的 `if ltb k y`（insert 里的那个）。可随后的 `simpl` 把 `lookup` 在暴露出的 `T` 节点上展开，又**从函数体里长出新的** `if ltb k y`——所以同一对键要 destruct **第二次**；
- 「不可能」的分支（如 `Hk : Abs k < Abs y` 与 `Hk2 : ~ Abs k < Abs y` 并存）用 `exfalso; lia` 收割——`lia` 看得懂 `~ (a < b)`；
- 两个方向都不小于对方时（最后的 `*` 分支），`Abs k = Abs y` 由 `lia` 从两条 `~` 里读出。

这个「simpl 复活 if、于是再 destruct」的循环正是 VFA 把自动化写成 `repeat (simpl; bdestruct_guard; try lia; auto)` 的原因——`bdall` 就是这个循环的战术化。

```coq
Theorem lookup_insert_neq :
  forall (V : Type) (default : V) (t : tree V) (k k' : key) (v : V),
    k <> k' -> lookup default k' (insert k v t) = lookup default k' t.
Proof.
  intros V default t. induction t as [| l IHl y v' r IHr];
    intros k k' v Hne; simpl.
  - (* 空树：k' 与 k 比大小，相等的那条路被 Hne 堵死 *)
    destruct (int_ltb_reflect k' k) as [H1 | H1].
    + reflexivity.
    + destruct (int_ltb_reflect k k') as [H2 | H2].
      * reflexivity.
      * exfalso. apply Hne. apply Abs_inj. lia.
  - destruct (int_ltb_reflect k y) as [Hk | Hk].
    + simpl. destruct (int_ltb_reflect k' y) as [H1 | H1].
      * apply IHl. exact Hne.
      * reflexivity.
    + destruct (int_ltb_reflect y k) as [Hy | Hy].
      * simpl. destruct (int_ltb_reflect k' y) as [H1 | H1].
        -- reflexivity.
        -- destruct (int_ltb_reflect y k') as [H2 | H2].
           ++ apply IHr. exact Hne.
           ++ reflexivity.
      * (* 两侧都不小于对方：Abs k = Abs y，即 k = y，只剩值不同 *)
        assert (Hky : k = y) by (apply Abs_inj; lia).
        subst y. simpl. destruct (int_ltb_reflect k' k) as [H1 | H1].
        -- reflexivity.
        -- destruct (int_ltb_reflect k k') as [H2 | H2].
           ++ reflexivity.
           ++ exfalso. apply Hne. apply Abs_inj. lia.
Qed.
```

「插入 `k` 不影响查别的键 `k'`」。骨架与上一条同构，三个新看点：

- 空树分支里**两个方向**的 `if`（`ltb k' k` 与 `ltb k k'`）都要拆，两条路都通向 `default`，只有「`k'` 等于 `k`」的死路由 `Hne` 引爆——注意 `apply Abs_inj` 后 `lia` 从 `H1`/`H2` 两条否定里读出 `Abs k' = Abs k`，反推 `k' = k` 与 `Hne` 矛盾；
- `Hk` 分支（insert 走左）里，若 `k'` 也往左，两边都下到左子树，用 `IHl`；若 `k'` 不往左，**两边目标语法相同**，`reflexivity` 直接收——不需要真正拆 `y` 与 `k'` 的比较；
- 最后的 `Hy` 假分支是本证明的智力高点：`~Abs k < Abs y` 与 `~Abs y < Abs k` 合起来给 `Abs k = Abs y`，`Abs_inj` 换成 `k = y`，`subst` 之后两棵树只差节点上的值（`v` 对 `v'`），而 `k' <> k` 保证查找永远到不了根——两次 destruct 把路堵死，两个分支都是 `reflexivity`。

最后查一下账——这条定理的证明用了哪些假设：

```coq
(* 证明依赖公理；40.5 的抽取产物里却一条都看不到 *)
Print Assumptions lookup_insert_eq.
```

真实输出：

```text
Axioms:
ltb_lt : forall n m : int, ltb n m = true <-> Abs n < Abs m
ltb : int -> int -> bool
int : Type
Abs : int -> Z
```

四条：三个 `Parameter`（`int`、`ltb`、`Abs`——`Abs` 只在 `ltb_lt` 的陈述里出现，也算依赖）加一条 `Axiom`（`ltb_lt`；`Abs_inj` 这条定理恰好没用到，所以不在列）。**证明站在假设上，天经地义**——下一节的好戏是：抽取产物里这四条一个都不剩。

### 40.5 落地：抽取成 .ml 文件

BST 验证完毕，导出。先给积类型也加上原生映射——`elements` 返回 `(key * V)` 列表，不映射的话 Rocq 的 `prod` 会抽成一个带 `Pair` 构造子的独立类型，用不了 OCaml 的 `(k, v)` 语法：

```coq
(* ---------- 40.5 落地：抽取成 .ml 文件 ---------- *)

(* 落 OCaml 原生积类型：键值对抽成 (k, v) 而非 fst/snd 记录 *)
Extract Inductive prod => "( * )" [ "( , )" ].

Recursive Extraction empty_tree insert lookup elements.
```

真实输出——本章的主产物，值得逐行精读：

```text
module Ex40Extract =
 struct
  type key = int

  type 'v tree =
  | E
  | T of 'v tree * key * 'v * 'v tree

  (** val empty_tree : 'a1 tree **)

  let empty_tree =
    E

  (** val lookup : 'a1 -> key -> 'a1 tree -> 'a1 **)

  let rec lookup default x = function
  | E -> default
  | T (l, k, v, r) ->
    if ( < ) x k
    then lookup default x l
    else if ( < ) k x then lookup default x r else v

  (** val insert : key -> 'a1 -> 'a1 tree -> 'a1 tree **)

  let rec insert x v = function
  | E -> T (E, x, v, E)
  | T (l, y, v', r) ->
    if ( < ) x y
    then T ((insert x v l), y, v', r)
    else if ( < ) y x then T (l, y, v', (insert x v r)) else T (l, x, v, r)

  (** val elements_aux : 'a1 tree -> (key * 'a1) list -> (key * 'a1) list **)

  let rec elements_aux t acc =
    match t with
    | E -> acc
    | T (l, k, v, r) -> elements_aux l ((k , v)::(elements_aux r acc))

  (** val elements : 'a1 tree -> (key * 'a1) list **)

  let elements t =
    elements_aux t []
 end
```

对照 40.4 的 Coq 源码，逐项对账：

- **`type key = int`**：抽象的 `int` 落成 OCaml 的 `int`，`Extract Inlined Constant` 生效；
- **`ltb` 的每次调用变成 `( < ) x k`**：内联映射把字符串贴到调用点，产物是算子节（operator section）语法——合法的 OCaml（等价于 `<` 当普通函数用），只是不如中缀好看；
- **`(k , v)::(elements_aux r acc)`**：`prod` 映射生效，键值对是真正的 OCaml 元组，列表是真正的 `::`；
- **`lookup_insert_eq`、`lookup_insert_neq`、`lookup_empty`、`int_ltb_reflect`、`ltb_irrefl` 全部消失**：它们是 `Prop`，抽取器根本不看；
- **40.4 末尾那四条假设也全部消失**：`int` 与 `ltb` 被映射吃掉，`Abs` 与 `ltb_lt` 只活在证明里——**证明依赖公理，程序零公理**，这就是「验证后抽取」的分工。

一个必须理解的边界：如果假设（`Parameter`/`Axiom`）出现在**计算位置**而没有给映射，抽取器不会假装没事。在 /tmp 里实测的最小例子：

```coq
Parameter magic : nat -> nat.

Definition use_magic (n : nat) : nat := magic n + 1.

Recursive Extraction use_magic.
```

rocq 9.3.0 的真实反应——先给警告，再给一个**运行时炸弹**：

```text
Warning: The following axiom must be realized in the extracted code:
 magic.
 [extraction-axiom-to-realize,extraction,default]

(** val magic : nat -> nat **)

let magic =
  failwith "AXIOM TO BE REALIZED (t7.magic)"
```

`failwith` 意味着这段代码一跑到 `magic` 就抛异常——抽取器把「没兑现的假设」显式钉在产物里。所以轻量抽象的铁律是：**每个假设要么有 `Extract ... Constant` 映射，要么保证只出现在证明里**。

接着把产物写成文件（而不是打印到 stdout）：

```coq
Set Extraction Output Directory ".".

Extraction "searchtree40.ml" empty_tree insert lookup elements.
```

`Extraction "文件名" 常量列表` 把闭包写进 `.ml`，同时生成配套的 `.mli` 接口。`Set Extraction Output Directory "."` 这行在 rocq 9.3 不是装饰——不写它，编译时先吃一条警告（实测原文，路径是当时的编译目录）：

```text
Warning: Setting extraction output directory by default to
"/private/tmp/ex40". Use "Set Extraction Output Directory" or command line
option "-output-directory" to set a different directory for extracted files
to appear in. [extraction-default-directory,extraction,default]
```

编译后 `build/examples/` 下真实生成的 `searchtree40.mli`（全文）：

```text
module Ex40Extract :
 sig
  type key = int

  type 'v tree =
  | E
  | T of 'v tree * key * 'v * 'v tree

  val empty_tree : 'a1 tree

  val lookup : 'a1 -> key -> 'a1 tree -> 'a1

  val insert : key -> 'a1 -> 'a1 tree -> 'a1 tree

  val elements_aux : 'a1 tree -> (key * 'a1) list -> (key * 'a1) list

  val elements : 'a1 tree -> (key * 'a1) list
 end
```

`.mli` 就是产物类型的清单：类型、四个函数，外加模块包装。`.ml` 内容与上面的 `Recursive Extraction` 输出完全一致。注意它**没有隐藏任何东西**——内部辅助函数 `elements_aux` 也赫然在列，接口裁剪要自己做（40.6 再谈）。

这份代码能真跑。用 `ocamlopt`（OCaml 5.4.1）原生编译 `searchtree40.mli` + `searchtree40.ml`，再配一个测试驱动（测试文件不入库，在 /tmp 实测）：

```ocaml
open Searchtree40.Ex40Extract

let () =
  let t = List.fold_left (fun t k -> insert k (k * 10) t) empty_tree [3; 1; 4; 1; 5] in
  assert (lookup 0 3 t = 30);
  assert (lookup 0 4 t = 40);
  assert (lookup (-1) 9 t = -1);
  let ks = List.map fst (elements t) in
  assert (ks = [1; 3; 4; 5]);
  print_endline "smoke ok: lookup/elements 与定理一致"

let random_list n =
  let rec go i acc = if i < n then go (i + 1) (Random.int 1_000_000 :: acc) else acc in
  go 0 []

let timed name keys =
  let t0 = Sys.time () in
  let t = List.fold_left (fun t k -> insert k k t) empty_tree keys in
  List.iter (fun k -> assert (lookup 0 k t = k)) keys;
  Printf.printf "%s: %.3f s (CPU)\n" name (Sys.time () -. t0)

let () =
  Random.init 97_423;
  timed "insert+lookup 100000 随机整数" (random_list 100_000);
  timed "insert+lookup 20000 连续整数" (List.init 20_000 Fun.id)
```

驱动分两部分：**冒烟测试**把 40.4 的定理当验收单——`lookup 0 3 t = 30` 是 `lookup_insert_eq`（插入 3 映射 30，查 3 必得 30）；`lookup (-1) 9 t = -1` 是 `lookup_empty` 的默认值行为；`ks = [1; 3; 4; 5]` 是 39 章证过的「elements 升序、去重」。**压测**部分复刻 VFA 的实验设计：随机整数 vs 连续整数。本机一次运行的真实输出：

```text
smoke ok: lookup/elements 与定理一致
insert+lookup 100000 随机整数: 0.276 s (CPU)
insert+lookup 20000 连续整数: 11.817 s (CPU)
```

数字会随机器浮动，但量级关系稳定：连续键的数目只有随机键的五分之一，耗时却反超**四十多倍**（11.8s 对 0.276s）。随机插入的树接近平衡，操作对数时间；连续插入把 BST 铺成一条链，每个操作线性时间——这正是未平衡 BST 的最坏情形，也正是第 41 章（红黑树）存在的理由。VFA 用同一实验引出 Redblack 章，我们原样继承这个衔接。

### 40.6 Module 抽象层：签名密封挡不住抽取

从 40.1 起，每份产物都包在 `module Ex40Extract = struct ... end` 里——Coq 模块**透明地**翻成 OCaml 模块。值得专门实验的是另一个方向：`Module Type` 签名（第 18 章用过的抽象层工具）在抽取里扮演什么角色？直觉上，`Module M : SIG` 把实现细节藏起来，调用方只能看接口——抽取器会尊重这层封装吗？

```coq
(* ---------- 40.6 Module 抽象层：签名密封挡不住抽取 ---------- *)

Module Type KEYSIG.
  Parameter t : Type.
  Parameter ltb : t -> t -> bool.
End KEYSIG.

Module NatKeySealed : KEYSIG.
  Definition t := nat.
  Definition ltb := Nat.ltb.
End NatKeySealed.

Recursive Extraction NatKeySealed.ltb.
```

`KEYSIG` 是最小键接口：一个类型加一个小于比较（第 18 章的栈接口同款写法）。`NatKeySealed` 用 `nat` 实现它，并且**用签名密封**（`: KEYSIG`）。抽取密封模块的真实输出：

```text
type nat =
| O
| S of nat

module Nat =
 struct
  (** val leb : nat -> nat -> bool **)

  let rec leb n m =
    match n with
    | O -> true
    | S n' -> (match m with
               | O -> false
               | S m' => leb n' m')

  (** val ltb : nat -> nat -> bool **)

  let ltb n m =
    leb (S n) m
 end

module Ex40Extract =
 struct
  module type KEYSIG =
   sig
    type t

    val ltb : t -> t -> bool
   end

  module NatKeySealed =
   struct
    type t = nat

    (** val ltb : nat -> nat -> bool **)

    let ltb =
      Nat.ltb
   end
 end
```

三个事实，全都和「封装」的直觉相反：

1. **密封被完全穿透**：`type t = nat`、`let ltb = Nat.ltb`——实现原原本本躺在产物里。签名密封是**证明期的抽象**（限制后续代码能用什么），而抽取器直接从内核层面的定义工作，看得见一切；
2. **`Module Type` 自己也被翻译**成 OCaml 的 `module type KEYSIG = sig ... end`——产物甚至保留了接口的形状，只是它不再约束任何人；
3. 对照实验：不密封的 `NatKeyOpen` 抽出来，`module Nat` 与 `type t = nat`、`let ltb = Nat.ltb` **逐字符一致**；唯一的差别反而是——密封版多出那份 `module type KEYSIG = ...`（密封引用了它，它才进依赖闭包），不密封的版本里它压根不出现：

```coq
Module NatKeyOpen.
  Definition t := nat.
  Definition ltb := Nat.ltb.
End NatKeyOpen.

Recursive Extraction NatKeyOpen.ltb.
```

真实输出与密封版的差别：`module Nat` 及 `NatKeyOpen` 体内容逐字符相同，只是没有那份 `module type KEYSIG`——密封换来的唯一「产物差异」是一段谁也不约束的接口定义，抽象边界在产物里不存在。

结论是一条务实的设计守则：**签名密封不能当产物边界的抽象用**。想要「只暴露接口、隐藏实现」的 `.ml`/`.mli`，要么在 `Extraction "f.ml"` 时只列公开常量（但 40.5 看到，辅助函数还是会进 `.mli`——那就手改 `.mli`，OCaml 侧的 `.mli` 才是真正的可见性控制），要么把实现模块整个藏起来、只抽一个薄薄的门面（facade）模块。Coq 的抽象层服务于证明组织（第 18 章），OCaml 的抽象层服务于 API 卫生——**两层各自工作，谁也别替谁值班**。

顺带把 40.5 留下的问题收尾：本章所有产物都包在 `module Ex40Extract` 里，OCaml 调用方要写 `Searchtree40.Ex40Extract.insert`（40.5 的驱动 `open Searchtree40.Ex40Extract` 就是这么开的）。包裹层不产生任何运行时开销（OCaml 模块编译期就消解了），只是命名空间多一层——这是本教程「每章一个 `Module`」约定在抽取产物里的投影。

```coq
End Ex40Extract.
```

### 40.7 本章坑位清单（实测）

1. **证明携带函数以 `Qed` 收尾会吃警告**：9.3 的抽取器默认 bypass opacity，`Qed` 的函数**仍能**抽出来，但编译日志给 `Warning: The extraction is currently set to bypass opacity, the following opaque constant bodies have been accessed : zero_or_succ_qed. [extraction-opaque-accessed,...]`（/tmp 实测）。要干净的产物，证明携带函数一律 `Defined`；
2. **`induction` 的 `as` 模式别重绑类型参数**：`induction t as [V | ...]` 直接报 `Error: V is already used.`——参数化类型（`tree V`）的参数已在上下文里，`as` 只该列构造子的参数（本章用 `as [| l IHl y v' r IHr]`）；
3. **`simpl` 会把 if「复活」**：destruct reflect 拆掉目标里的 `if ltb k y` 后，下一步 `simpl` 展开 `lookup` 又从函数体里长出新的同名 `if`——同一对键要 destruct 两次（40.4 两证明的骨架）。VFA 的 `bdall := repeat (simpl; bdestruct_guard; ...)` 就是这个循环的战术化；
4. **`sumor` 构造子是小写**：`inleft`/`inright`，而 `sumbool` 是 `left`/`right`——想当然写 `Inleft` 报 `Unknown constructor: Inleft`（实测）；
5. **`Open Scope Z_scope` 的位置**：必须放在所有 `nat` 代码之后——放开头会让 `<=?` 默认按 `Z` 解读，`nat` 排序直接报「The term "n" has type "nat" while it is expected to have type "Z"」（实测）；
6. **`Extraction "f.ml"` 前不设输出目录有警告**：rocq 9.3 报 `extraction-default-directory` 警告（40.5 引了原文）。示例里 `Set Extraction Output Directory "."` 一劳永逸；
7. **没映射的计算位公理是运行时炸弹**：产物里生成 `let magic = failwith "AXIOM TO BE REALIZED (t7.magic)"` 并伴随 `extraction-axiom-to-realize` 警告（实测原文在 40.5）。轻量抽象的每条假设：要么有 `Extract ... Constant` 映射，要么只在证明里出现；
8. **轻量公理必须逐条审查忠实性**：`ltb_lt` 健全（OCaml `<` 与 `Z` 比较全程一致），`ocaml_plus_plus` 不健全（`max_int + max_int` 溢出回绕）。公理不忠实，证明全废——这不是编译器能查的，是设计者的责任；
9. **`Compute` 在不透明证明上会卡住**：对 `Qed` 引理参与的判决函数求值，得到的是数百行的巨型 stuck 项（实测开头三行是 `= match`、`match`、`match iff_sym (Nat.leb_le 2 5) with`，缩进逐层加深）；抽取不受影响（抽取器 bypass opacity 重算骨架），但交互式求值别指望它；
10. **`( < )` 不是中缀**：`Extract Inlined Constant` 把映射串原样贴到调用点，产物里是 `( < ) x k` 算子节——合法但不美观，介意的话在 OCaml 侧包一层，或接受它；
11. **抽取产物里 `nat` 仍是一元**：`type nat = O | S of nat`（40.2 两轮实测），32 章的结论在本章复现——数系规划要趁早（40.3 的轻量 int 是方案之一），别等抽完才发现慢。

---
上一章：[39 · 二叉搜索树的验证](39-searchtree.md) ｜ 下一章：[41 · 红黑树](41-redblack.md) ｜ 返回：[README](../README.md)
