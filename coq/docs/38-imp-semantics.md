# 38 · Imp：状态、命令与大步语义

对应示例：`../examples/38_imp_semantics.v`（`Module Ex38ImpSemantics`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

前面 21 章我们造过一个**没有变量**的算术表达式求值器，32 章把它扩成了一个带
优化 pass 的完整小项目。那一套东西能算 `1 + 2 * 3`，但算不了任何**依赖内存**的
程序——它没有变量，没有赋值，没有循环。本章把语言补完：加上**状态**（变量表）、
**变量**、**命令**（赋值 / 顺序 / 分支 / 循环），然后撞上一个硬钉子——`while`
可能不结束，于是**求值不能写成函数**。绕过钉子的办法是把"求值"从函数换成
**归纳定义的关系**，即所谓的**大步语义**（big-step / natural-semantics）。

本章的三段主线：

1. **语法层**（38.1–38.5）：`state`、带变量的 `aexp`/`bexp`、`com`，以及把
   `X := X + 2` 这种写法接进 Rocq 的三样机制——`Coercion`、`Declare Custom Entry`、
   `com_scope`。
2. **语义层**（38.6–38.12）：先证明函数式求值此路不通，再用 `aevalR` 演示
   "函数改写成关系"的标准手法，最后落到 `ceval` 的七条推理规则，证明
   **确定性**（`ceval` 确实是个偏函数）和 `loop` **永不停止**。
3. **应用层**（38.13）：一台栈机 + `aexp` 编译器，并证明编译正确性——这是全书
   第一个"程序变换保语义"的完整定理。

39 章接着讲怎么把 `ceval` 强行变回可计算的函数（燃料），40 章换成小步语义，
43 章用 Hoare 逻辑系统地推理命令。

### 38.1 状态：33 章全映射的最小自包含副本

示例文件开头：

```coq
(* 38 Imp：状态、命令与大步语义 —— 从 state 到 <{ }>，从函数式求值失败到 ceval 关系 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex38ImpSemantics.

(* ---------- 38.1 状态：33 章全映射的最小自包含副本 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).
```

四个名字和两条记号都来自 33 章，这里**逐字复制**而不是 `Require Import`，是因为
本教程每个示例文件都要求能独立编译（见 README 的验证命令）；代价就是这一小段重复。

33 章反复强调过、这里再钉一遍的心智模型：**赋值不是改内存，是造一个新函数。**

```coq
t_update st x v  =  fun x' => if String.eqb x x' then v else st x'
```

`x'` 等于 `x` 就回答 `v`，否则把问题转交给老状态。所以 `X := 5` 之后的状态和
之前的状态是**两个不同的函数对象**，只是其中一个点上的回答变了。这个表示法唯一
的真正代价是：你无法"遍历"一个状态（函数不透明），也无法问"它有几个变量"。
语义建模只需要查找和更新，所以够；要做真实实现才需要 33.8 的列表版或 28 章的搜索树。

往下要用的只有两条定律（33 章的六条里，命令层只会反复撞到这两条）：

```coq
Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

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

`t_update_eq` 说"更新过的键读出更新的值"，38.10 的 `plus2_spec` 最后一步就是它。
`t_update_neq` 说"更新 `x1` 不影响 `x2`"，凡是"这条赋值只动了 `X`，`Y` 还是老样子"
的推理都用它。两条都**没有**用到函数外延公理（`Print Assumptions` 在 33 章实测过是
`Closed under the global context`）——因为它们的结论是**点上的等式**，不是"两个映射
相等"。一旦结论变成 `m1 = m2`（如 33 章的 `t_update_shadow`），就必须上外延公理了。

有了这两条，状态就正式定义出来：

```coq
Definition state := total_map nat.
```

一句话：**Imp 的内存 = 从字符串到自然数的函数**。默认值是 `0`，所以任何没赋过值的
变量读出 `0`——这个选择后面 38.4 的 `aexp2` 会真的被用到。

### 38.2 表达式语法：带变量的 aexp 与 bexp

```coq
(* ---------- 38.2 表达式语法：带变量的 aexp 与 bexp ---------- *)

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BNeq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BGt (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).
```

和 21 章的 `aexp` 相比只多了一个构造子：`AId (x : string)`——**变量名本身不是
变量**，它是一个 `string`，装进 `AId` 才成为表达式。这是 AST 建模里最容易搞错的
一点：`AId "X"` 是"读取名为 X 的格子"这个**动作**，而 `"X"` 只是格子的标签。

`W/X/Y/Z` 四条 `Definition` 纯粹为了让例子可读：写 `X` 比写 `"X"%string` 省事，
而且它们是**可展开的透明定义**（`unfold X` 就能变回 `"X"`），不会引入任何新机制。
注意它们和类型变量惯例（`A`、`B`……）撞了大写；本章不用多态类型变量，所以无害。

`bexp` 相比 21 章补全了四个比较（`=`、`<>`、`<=`、`>`）而不是只有 `<=`——因为
Imp 程序里 `Z <> 0` 这种循环条件实在太常见了，缺它会让每个循环例子都要绕路。
`BAnd` 保留了短路语义**没有**实现（`andb` 是全价的），这是刻意的：本章关心的
是命令的收敛性，不是求值顺序。

### 38.3 三条抬进机制：Coercion / 自定义条目 / com_scope

这一节是本教程里"语法工程"密度最高的一节。目标只有一个：让我们能在 Rocq 源文件里
直接写 `<{ X := X + 2 }>`。为此需要三样东西**同时**成立。

```coq
(* ---------- 38.3 三条抬进机制：Coercion / 自定义条目 / com_scope ---------- *)
```

**(1) Coercion：让类型系统替你套上构造子。**

```coq
Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.
```

箭头 `string >-> aexp` 读作"当需要一个 `aexp` 而你给了 `string`，就自动套 `AId`"。
于是 `APlus (AId X) (ANum 2)` 可以写成 `APlus X 2`，再写成 `<{ X + 2 }>`。

三个必须知道的边界：

- 插入是**类型导向**的，只在"期望类型已知"处发生。`Check X` 仍然给你 `string`，
  因为那里没有任何地方要求 `aexp`。
- 默认**打印时隐藏**，所以 `Print fact_in_coq` 看不到 `AId`——38.6 用
  `Set Printing Coercions` 把它们显出来。
- 一条 `Coercion` 只对**一个方向**有效。`nat >-> aexp` 不会让你把 `aexp` 当 `nat` 用。

**(2) Declare Custom Entry：另开一套语法。**

```coq
Declare Custom Entry com.
Declare Scope com_scope.
```

`Custom Entry` 是 Rocq 语法的"分频道"机制：默认语法（术语层）和 `com` 频道**各自有
一整套记号表**。之后凡是写 `in custom com` 的记号，**只在 `com` 频道里生效**。这正
是本章能安全复用 `:=`、`;`、`=`、`<>`、`~`、`&&` 的原因——它们在 `com` 频道里的含义
和在默认语法里的含义互不干扰：`;` 在策略语言里是"顺序执行策略"，在 `list_scope` 里
是列表分隔符，在 `com` 频道里才是 `CSeq`。

**(3) `<{ }>`：两个频道之间唯一的桥。**

```coq
Notation "<{ e }>" := e
  (e custom com, format "'[hv' <{ '/  ' '[v' e ']' '/' }> ']'") : com_scope.
```

拆开看：

- `:= e`——桥是**恒等**的，`<{ a }>` 就是 `a`，不产生任何语法树节点。所以
  `example_aexp` 的类型是 `aexp`，`fact_in_coq` 的类型是 `com`，中间没有任何包装。
- `e custom com`——`<{` 和 `}>` 之间的字符串用 `com` 频道解析。
- 尾部 `: com_scope`——这条记号本身住在 `com_scope` 里，**必须先 `Open Scope com_scope`
  才认得 `<{ }>`**。这不是可选项：实测删掉 `Open Scope com_scope.` 这一行，文件立刻报错

  ```
  Error: Unknown interpretation for notation "<{ _ }>".
  This notation is available in com_scope.
  ```

  这句报错把作用域机制讲得比任何文档都直白：记号"存在但不在作用域里"。
- 那串 `format` 只管打印换行，与语义无关，见到当成噪音即可。

**(4) 三条"抬进条目"记号：没有它们，`com` 频道里什么都写不出来。**

```coq
Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).

Notation "f x .. y" := (.. (f x) .. y)
                  (in custom com at level 0, only parsing,
                  f constr at level 0, x constr at level 1,
                      y constr at level 1).
```

`com` 频道刚开出来时是**空的**：它连一个标识符、一对括号都解析不了。这三条就是把
默认语法的东西"抬"进 `com` 频道的斜坡：

| 记号 | 作用 | 少了它会怎样 |
|---|---|---|
| `( x )` | `com` 频道里认括号，`x` 取 level 99（最松，括号里可放任何东西） | `<{ 3 + (X * 2) }>` 里的括号报错 |
| `x`（`x constr`） | 任何默认语法里的项（`X`、`5`、`subtract_slowly_body`）可直接出现在 `com` 里 | 连一个变量名都写不出来 |
| `f x .. y` | 多参数应用（`APlus a b`、`aeval st a`）能出现在 `com` 里；`only parsing` 表示只为打印/解析服务，不反向匹配 | `Print` 出来的东西无法读回 |

`only parsing` 值得单独说一句：它声明这条记号**不参与"把项匹配回记号"的反向过程**，
只参与打印。少了它，`x y` 这种形状会被当成一条通用记号去匹配大量项，证明里的
`rewrite`／`unification` 会莫名其妙地慢甚至错。

**(5) 表达式记号与 level 阶梯。**

```coq
Notation "x + y"   := (APlus x y) (in custom com at level 50, left associativity).
Notation "x - y"   := (AMinus x y) (in custom com at level 50, left associativity).
Notation "x * y"   := (AMult x y) (in custom com at level 40, left associativity).

Notation "'true'"  := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).

Notation "x <= y"  := (BLe x y) (in custom com at level 70, no associativity).
Notation "x > y"   := (BGt x y) (in custom com at level 70, no associativity).
Notation "x = y"   := (BEq x y) (in custom com at level 70, no associativity).
Notation "x <> y"  := (BNeq x y) (in custom com at level 70, no associativity).
Notation "x && y"  := (BAnd x y) (in custom com at level 80, left associativity).
Notation "'~' b"   := (BNot b) (in custom com at level 75, right associativity).

Open Scope com_scope.
```

level 越小**结合越紧**。所以这条阶梯给出的优先级正好是我们要的：

```
40  *          ← 最紧
50  +  -
70  <= >  =  <>   (no associativity：X <= 1 <= 2 直接判语法错误)
75  ~          (right)
80  &&         (left)
```

`no associativity` 是最容易被忽略也最有价值的一档：它不是"默认左结合"，是
**禁止同层级连用**。比较运算连写本来就没有意义，让它报语法错比默默给个括号好。

这里要交代一处和原书（以及网上大量转录稿）的**差异**。LF 的 `Imp.v` 在
`'true' := BTrue (in custom com ...)` 之前还写了两条：

```coq
Notation "'true'"  := true (at level 1).
Notation "'false'" := false (at level 1).
```

这两条是在**默认语法**里把 `true` 记号重新指回 `Datatypes.true`，属于历史遗留。
本机 rocq 9.3.0 实测：把这两行**整段删掉，示例照样编译通过（退出码 0）**，而且顺带少掉
两条警告——它们正是 `closed-notation-not-level-0` 警告的来源（一个以终端符号
`'true'` 开头结尾的"闭合"记号，却被放在 level 1 而不是 level 0）。所以本章不抄它们。

顺带把实测到的警告列全，方便你看到时不必惊慌：

```
Warning: Notations at level 0 should be closed (first and last symbols should
be terminal symbols). [level-0-notation-not-closed,parsing,default]      ← 2 处
Warning: Closed notations (i.e. starting and ending and ending with a terminal
symbol) should usually be at level 0 (default). [closed-notation-not-level-0]  ← 2 处
```

第一条来自 38.5 的 `x := y`（level 0 但首尾是变量，不是终端符号），第二条来自
`'if' ... 'end'` 和 `'while' ... 'end'`（明明闭合了却放在 level 89）。**都是警告，
不阻断编译**；要消除只能改 level，改了就会破坏优先级阶梯，得不偿失。37 章系统讲
level 与警告的取舍。

**(6) 验证效果。**

```coq
Definition example_aexp : aexp := <{ 3 + (X * 2) }>.
Definition example_bexp : bexp := <{ true && ~(X <= 4) }>.

Print example_aexp.
```

`Print example_aexp.` 的实测输出：

```
example_aexp = <{3 + X * 2}>
     : aexp
```

三点值得注意：

1. 类型是 `aexp`，不是别的包装类型——印证了 `<{ }>` 是恒等桥。
2. 输入里的 `3` 和 `2` 是 `nat` 字面量，靠 `Coercion ANum` 变成 `ANum 3`／`ANum 2`；
   `X` 靠 `Coercion AId` 变成 `AId X`。打印时两个 coercion 都被藏掉了，所以看起来
   就像原样回显。
3. **括号消失了**：`<{ 3 + (X * 2) }>` 打印成 `<{3 + X * 2}>`。因为 `*`（level 40）
   比 `+`（level 50）结合更紧，打印器按 level 判断括号是多余的。括号的信息量完全在
   level 数字里，这就是记号必须仔细配 level 的原因。

### 38.4 求值：`aeval` / `beval` 都要吃一个 state

```coq
(* ---------- 38.4 求值：aeval / beval 都要吃一个 state ---------- *)

Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | <{a1 + a2}> => (aeval st a1) + (aeval st a2)
  | <{a1 - a2}> => (aeval st a1) - (aeval st a2)
  | <{a1 * a2}> => (aeval st a1) * (aeval st a2)
  end.

Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | <{true}>      => true
  | <{false}>     => false
  | <{a1 = a2}>   => (aeval st a1) =? (aeval st a2)
  | <{a1 <> a2}>  => negb ((aeval st a1) =? (aeval st a2))
  | <{a1 <= a2}>  => (aeval st a1) <=? (aeval st a2)
  | <{a1 > a2}>   => negb ((aeval st a1) <=? (aeval st a2))
  | <{~ b1}>      => negb (beval st b1)
  | <{b1 && b2}>  => andb (beval st b1) (beval st b2)
  end.
```

和 21 章比，两处变化：

- `state` 成了**第一个参数**。这个位置选择不是风格问题：38.8 的关系版本
  `aevalR st e n` 也把 `st` 放第一，两条线的形状一致，引理才好互搬。
- 算术规则 `| ANum n => n` 和 `| AId x => st x` 写的是**裸构造子**，布尔的八条却写成
  `<{true}>`、`<{a1 = a2}>` 这种**记号模式**。这不是随手，是必需：`com` 频道里给
  `BTrue` 配了 `'true'` 记号，所以模式 `<{true}>` 能匹配；而 `ANum`、`AId` 在 `com`
  频道里**没有反向记号**（`f x .. y` 是 `only parsing`，`'true'`/`'false'` 只覆盖零参
  构造子），模式位置用不了记号，只能老老实实写构造子名。记住这条经验：
  **模式里能用记号的前提是该记号不是 `only parsing`。**

再看状态相关的两条：

```coq
Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).
```

`empty_st` 就是"处处回答 0 的函数"。第二条记号是 33 章 `x !-> v ; m` 的**单键特例**
（尾巴固定成 `empty_st`），让例子能写成 `X !-> 5` 而不是 `X !-> 5 ; __ !-> 0`。
它和 33 章偏映射的 `x '|->' v` 是两个不同记号，别混：这里 `!->` 左边是**全映射**，
读未赋值的变量得到 `0` 而不是 `None`。

三个例子（都只有 `reflexivity`，因为它们是真计算）：

```coq
Example aexp1 : aeval (X !-> 5) <{ 3 + (X * 2) }> = 13.
Proof. reflexivity. Qed.

Example aexp2 : aeval (X !-> 5 ; Y !-> 4) <{ Z + (X * Y) }> = 20.
Proof. reflexivity. Qed.

Example bexp1 : beval (X !-> 5) <{ true && ~(X <= 4) }> = true.
Proof. reflexivity. Qed.
```

`aexp2` 是这章第一个"状态语义"测验：状态里只绑了 `X = 5`、`Y = 4`，`Z` 没绑。
于是 `aeval st (AId Z) = st Z = empty_st Z = 0`，结果 `0 + 5*4 = 20`。**未赋值的
变量读出默认值 0**——这个"全映射自带默认值"的设计，正是 33 章先做 `total_map`
再做 `partial_map` 而不是反过来做的回报。

`reflexivity` 能一步过，说明整条计算链（`aeval`、`beval`、`st`、`String.eqb`）在
类型检查期就完全归约到位。这是 Rocq 和普通语言的一个重要区别：**计算是证明的一部分**，
`reflexivity` 会自己做规范化。

### 38.5 命令语法：`com` 与五条命令记号

```coq
(* ---------- 38.5 命令语法：com 与五条命令记号 ---------- *)

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).
```

注意 `CAsgn` 的第一个参数是 `string` 而**不是** `aexp`——赋值左侧必须是个名字，
不允许 `X + 1 := 3` 这种"左值表达式"。用类型把语法约束写死，比事后证明"左值合法"
便宜得多。这也是 `Coercion AId` 帮不上忙的位置：期望类型是 `string`，`X` 正好就是
`string`，一切自然。

五条命令记号：

```coq
Notation "'skip'"  := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y"  := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85, no associativity,
    format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.
```

这四条 `: com_scope` 后缀（连 `skip` 那条一起）是因为记号的**左端**要能被
`<{ }>` 之外的地方引用；而参数全声明 `in custom com`，所以它们**不会**污染默认语法
——`a ; b` 在 `com` 频道外仍然是列表或策略。

level 阶梯在命令层的读法：

- `x := y` 的右端取 **level 85**：只允许比 85 更紧的东西，也就是表达式（≤80），
  不允许一条 `if`（89）或一串 `;`（90）。于是 `X := Y := 1` 报语法错，而不是被
  解析成某种奇怪的东西。左端 `x constr at level 0` 最紧，只收名字/字面量。
- `if`/`while` 在 **89**，`;` 在 **90**：89 < 90 意味着 `if ... end ; c` 解析成
  `(if ... end) ; c`，正如预期。
- `;` 是 **right associativity**：`c1 ; c2 ; c3` = `CSeq c1 (CSeq c2 c3)`。
  注意这个选择和"语义上等价"是两件事——33 章 `t_update_permute` 告诉我们**不同键**的
  更新顺序无关，但同一个键的更新顺序有关，所以结合性必须钉死一种。
- `if`/`while` 的守卫和体取 **level 99**（最松）：因为 `end` 是终端符号，靠它就能
  收尾，里面可以放任何完整命令。

一批示例程序：

```coq
Definition plus2 : com :=
  <{ X := X + 2 }>.

Definition XtimesYinZ : com :=
  <{ Z := X * Y }>.

Definition subtract_slowly_body : com :=
  <{ Z := Z - 1 ;
     X := X - 1 }>.

Definition subtract_slowly : com :=
  <{ while X <> 0 do
       subtract_slowly_body
     end }>.

Definition subtract_3_from_5_slowly : com :=
  <{ X := 3 ;
     Z := 5 ;
     subtract_slowly }>.

Definition loop : com :=
  <{ while true do
       skip
     end }>.

Definition fact_in_coq : com :=
  <{ Z := X;
     Y := 1;
     while Z <> 0 do
       Y := Y * Z;
       Z := Z - 1
     end }>.

Print fact_in_coq.
```

`subtract_3_from_5_slowly` 这一行是本章语法工程的小高潮：`subtract_slowly` 是一个
`Definition`，类型 `com`，它被直接写进另一段 `<{ ... }>` 里当一条命令用。靠的就是
38.3 那条 `Notation "x" := x (in custom com at level 0, x constr at level 0)`——
任何默认语法里的项都能抬进 `com` 频道。于是我们有了一个**宏/子程序**机制，而它的
实现只有三行记号声明。

`loop` 是全书第一个**故意不收敛**的程序，38.12 要为它证明"没有任何终止状态"。

`fact_in_coq` 的实机输出（`Printing Notations` 开着、`Printing Coercions` 关着，即默认）：

```
fact_in_coq =
<{Z := X;
  Y := 1;
  while Z <> 0 do
    Y := Y * Z;
    Z := Z - 1
  end}>
     : com
```

排版是 `format` 字符串控制的，和我们手写输入的换行几乎一致——这说明记号表配得对。

### 38.6 脱糖三件套与 Locate

记号 + coercion 用多了，一个绕不开的问题：**屏幕上的字面，到底是哪棵语法树？**
Rocq 给了三个开关，方向相反、可以组合。

```coq
(* ---------- 38.6 脱糖三件套与 Locate ---------- *)

Unset Printing Notations.
Print fact_in_coq.
Print example_bexp.
Set Printing Notations.

Print example_bexp.
Set Printing Coercions.
Print example_bexp.
Print fact_in_coq.
Unset Printing Coercions.

Set Printing All.
Print example_bexp.
Unset Printing All.
```

开关含义：

| 开关 | 默认 | 作用 |
|---|---|---|
| `Unset/Set Printing Notations` | 开 | 关掉后按**裸构造子**打印 |
| `Set/Unset Printing Coercions` | 关 | 打开后把隐式插入的 `AId`／`ANum` 显出来 |
| `Set Printing All` | — | 一把全开（记号关 + coercion 开 + 其它），`Unset Printing All` 还原 |

本机实测输出，逐条对着看：

```
fact_in_coq =
CSeq (CAsgn Z X)
  (CSeq (CAsgn Y 1)
     (CWhile (BNeq Z 0) (CSeq (CAsgn Y (AMult Y Z)) (CAsgn Z (AMinus Z 1)))))
     : com
```

这就是 `fact_in_coq` 的真身。三件事立刻清楚了：

1. `;` 确实右结合（`CSeq Y:=1 (CSeq ...)` 而不是左套）。
2. **没有 `AId`、没有 `ANum`**——`CAsgn Y 1` 里的 `1` 是 `nat` 字面量糖，`ANum 1`
   这个 coercion 插入被藏掉了；`CAsgn Z X` 里的 `X` 同理是 `AId X` 被藏掉。
3. `Z <> 0` 是 `BNeq`，不是 `BNot (BEq ...)`——原书语法里 `<>` 是独立的构造子。

```
example_bexp = BAnd BTrue (BNot (BLe X 4))
     : bexp
```

关掉记号后 `<{ true && ~(X <= 4) }>` 露出 `BAnd BTrue (BNot (BLe X 4))`：
`true` 是 `BTrue` 而**不是** `Datatypes.true`。这一条只能靠脱糖打印才能确认，
是"看字面猜语义"必然踩的坑。

```
example_bexp = <{true && ~ X <= 4}>
     : bexp
```

记号开、coercion 关（= 默认）。

```
example_bexp = <{true && ~ (AId X) <= (ANum 4)}>
     : bexp
```

`Set Printing Coercions.` 之后，`AId X` 和 `ANum 4` 现身，而且**各自被括号包住**——
打印器认为 `AId X` 不是原子，需要括号。注意 `true` 没有括号也没 coercion：
它就是 `BTrue` 的记号。

```
fact_in_coq =
<{
  Z := (AId X);
  Y := (ANum 1);
  while (AId Z) <> (ANum 0) do
    Y := (AId Y) * (AId Z);
    Z := (AId Z) - (ANum 1)
  end
}>
     : com
```

同一开关下的整段 factorail。现在你知道每次写 `X := X + 1`，Rocq 内部真的存了
`CAsgn X (APlus (AId X) (ANum 1))`。

```
example_bexp =
BAnd BTrue (BNot (BLe (AId X) (ANum (S (S (S (S O)))))))
     : bexp
```

`Set Printing All.` 的终极形态：记号关 + coercion 开。最有信息量的是最后一层
——`ANum 4` 打印成 `ANum (S (S (S (S O))))`，因为 `nat` 的本相就是 Peano 一元表示，
`4` 只是 numeral 记号糖。38.11 的证明里 `simpl` 会把东西展成这个样子，看到
`S (S ...)` 不用意外。

第四个工具不是开关而是查询：`Locate`。

```coq
Locate aexp.
Locate "&&".
Locate ";".
Locate "while".
```

`Locate` 有两种用法：**给标识符**（查同名对象的全路径，用来定位"到底用了哪个"）和
**给字符串**（查一条记号的所有解释，用来回答"`;` 在这里是谁"）。实测输出：

```
Inductive ex_38_imp_semantics.Ex38ImpSemantics.aexp
```

一条：`aexp` 只有一份，路径是「库名.模块名.名字」。前缀里的 `ex_` 是本教程
`build.sh` 复制文件时加的安全前缀（`38_imp_semantics` 以数字开头，不是合法的库标识符）；
你自己的项目里前缀会换成实际的库名。这一行告诉你：`Locate` 是排查**重名遮蔽**的第一工具。

```
Notation "x && y" := (BAnd x y) (default interpretation)
  (defined in library ex_38_imp_semantics, line 97, characters 9-17)
Notation "x && y" := (andb x y)
  (* x in scope _bool_scope, y in scope _bool_scope *) : bool_scope
  (default interpretation)
  (defined in library Corelib.Init.Datatypes, line 89, characters 6-10)
  (reserved in library Corelib.Init.Notations, line 56, characters 18-26)
```

两条解释，各自标出**定义所在库与行号**——这比任何文档都准。我们的 `&&` 在 `com`
频道，`andb` 的在 `bool_scope`，互不冲突；输出里"两条都写着 `default interpretation`"
是因为我们 `Open Scope com_scope` 了，所以 com 频道那条也被当默认解释。**记号同名
不一定是 bug，作用域/频道不同就是两回事**。最后一行的 `reserved in ...` 说明
`&&` 在 `Corelib.Init.Notations` 里被**预留**过——预留的用途是让多条记号能共享优先级
而不互相抢占。

```
Notation "x ; y" := (CSeq x y) : com_scope (default interpretation)
  (defined in library ex_38_imp_semantics, line 158, characters 9-16)
Notation "x '!->' v ';' m" := (t_update m x v) (* x in scope _string_scope *)
  (default interpretation)
  (defined in library ex_38_imp_semantics, line 21, characters 9-26)
Notation "[ x ; y ; .. ; z ]" := (cons x (cons y .. (cons z nil) ..))
  : list_scope (default interpretation)
  (defined in library Stdlib.Lists.List, line 33, characters 9-29)
```

`;` 的三种解释同时活在我们的环境里：`CSeq`（com 频道）、`t_update`（映射记号的中间
符号）、`cons`（列表）。它们能共存，正是 38.3 那句"凡是写 `in custom com` 的记号只在
com 频道生效"的实际效果——**如果 `x ; y := CSeq x y` 漏写了 `in custom com`，它会和
列表记号直接抢，`[1; 2]` 就可能解析失败**。这是本章最重要的一个坑，38.14 再列一次。

```
Notation "'while' x 'do' y 'end'" :=
    (CWhile x y) : com_scope
  (default interpretation)
```

`while` 只有一条，就是我们定义的。

### 38.7 函数式求值的失败尝试

现在到了本章的核心问题。先按"普通语言"的直觉写一个命令求值函数：

```coq
(* ---------- 38.7 函数式求值的失败尝试 ---------- *)

Fixpoint ceval_fun_no_while (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ x := a }> => (x !-> aeval st a ; st)
  | <{ c1 ; c2 }> =>
      let st' := ceval_fun_no_while st c1 in
      ceval_fun_no_while st' c2
  | <{ if b then c1 else c2 end }> =>
      if (beval st b)
        then ceval_fun_no_while st c1
        else ceval_fun_no_while st c2
  | <{ while b do c end }> => st
  end.
```

Rocq **接受**了这个定义。它打印的确认信息（repl 实测）是：

```
ceval_fun_no_while is recursively defined (guarded on 2nd argument)
```

`guarded on 2nd argument`——递归调用只允许在 `c`（第二个参数）的结构变小时发生。
这也解释了这个定义为什么能被接受：`while` 那条分支**根本没有递归**，它直接
`=> st`。这是个假语义。而且它假得非常安静：

```coq
Example ceval_fun_no_while_bogus :
  ceval_fun_no_while empty_st loop = empty_st.
Proof. reflexivity. Qed.
```

我们能**证明**死循环执行完回到原状态。类型检查一切正常，没有任何警告。这就是
"用函数建模语义"在 Coq/Rocq 里的真实风险：**不收敛的函数写不出来，于是模型会
悄悄丢掉收敛性。**

那按 OCaml/Haskell 的写法把 `while` 补全呢？

```coq
Fail Fixpoint ceval_fun_bad (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ x := a }> => (x !-> aeval st a ; st)
  | <{ c1 ; c2 }> =>
      ceval_fun_bad (ceval_fun_bad st c1) c2
  | <{ if b then c1 else c2 end }> =>
      if (beval st b)
        then ceval_fun_bad st c1
        else ceval_fun_bad st c2
  | <{ while b do c end }> =>
      if (beval st b)
        then ceval_fun_bad st <{ c ; while b do c end }>
        else st
  end.
```

repl 实测：

```
The command has indeed failed with message:
Cannot guess decreasing argument of fix.
```

失败原因精确：唯一的递归调用是 `ceval_fun_bad st <{ c ; while b do c end }>`，它的
第二个参数是 `CSeq c (CWhile b c)`——比 `CWhile b c` **更大**，不是子项。守卫检查
只看结构，不看"直觉上循环次数在减少"，所以无法猜出递减参数。

必须把这件事说透，因为它是很多人心智模型的分水岭：
** Rocq 的 `Fixpoint` 不是"会检测死循环"，而是"只允许结构递归，其它一概拒绝"。**
它拒绝的不是错误定义，而是**任何可能不终止的计算**——因为在构造演算里，函数就是
证明项，一个不终止的函数等价于一个能证明 `False` 的项，整个逻辑会崩。
所以这不是工具的限制，是**可靠性的代价**。

出路有三条，本书三条都会走：

- **本章**：把求值从函数换成**归纳定义的关系**（`ceval`）。关系可以只描述"收敛时
  发生什么"，不收敛的程序就没有推导，天然回避了终止性。
- **39 章**：加**燃料**（fuel），强行造一个全函数 `ceval_step`，再证明它和 `ceval`
  在燃料足够时一致。
- **40 章**：换成**小步语义**，把"一步"作为基本单位，收敛性变成"是否存在无限步序列"
  的问题。

### 38.8 `aevalR`：把求值函数改写成关系的第一个例子

`ceval` 是本章最大的一个关系，直接上它容易看不清"关系化"到底改了什么。先用
`aevalR`（算术表达式求值的关系版）走一遍完整流程——它的规则少、结论强，最适合
学手法。

```coq
(* ---------- 38.8 aevalR：把求值函数改写成关系 ---------- *)

Reserved Notation "st '|-' e '==>' n" (at level 90, no associativity).

Inductive aevalR : state -> aexp -> nat -> Prop :=
  | E_ANum : forall (st : state) (n : nat),
      st |- (ANum n) ==> n
  | E_AId : forall (st : state) (x : string),
      st |- (AId x) ==> st x
  | E_APlus : forall (st : state) (e1 e2 : aexp) (n1 n2 : nat),
      st |- e1 ==> n1 ->
      st |- e2 ==> n2 ->
      st |- (APlus e1 e2) ==> (n1 + n2)
  | E_AMinus : forall (st : state) (e1 e2 : aexp) (n1 n2 : nat),
      st |- e1 ==> n1 ->
      st |- e2 ==> n2 ->
      st |- (AMinus e1 e2) ==> (n1 - n2)
  | E_AMult : forall (st : state) (e1 e2 : aexp) (n1 n2 : nat),
      st |- e1 ==> n1 ->
      st |- e2 ==> n2 ->
      st |- (AMult e1 e2) ==> (n1 * n2)

  where "st |- e ==> n" := (aevalR st e n).
```

**关系化翻译手册**（三步，机械）：

1. `Fixpoint f : A -> B`（返回 `B`）改成 `Inductive fR : A -> B -> Prop`
   ——**返回类型变最后一层参数**，`-> Prop` 收尾。
2. `match` 的每一条分支变成一个构造子；分支体里的"递归调用结果"变成构造子的
   **前提**。
3. `=> 右边`变成结论里 `==>` 右边的值。

对照 `E_APlus`：函数版是 `| a1 + a2 => aeval st a1 + aeval st a2`；关系版把两个
`aeval st a1`、`aeval st a2` 拆成**抽象出来的 `n1`、`n2` 加两条前提**
`st |- e1 ==> n1`、`st |- e2 ==> n2`，结论用 `n1 + n2`。**"先算出子式"这个动作，
在关系版里变成"存在 n1、n2 使得子式能推到它们"。**

`Reserved Notation ... where ...` 这一对是**必须**的技巧：记号 `st |- e ==> n` 的
定义体里要引用 `aevalR`，而 `aevalR` 正在定义中。`Reserved Notation` 先把形状和
level 挂上（此时不需要含义），`where` 子句在 `Inductive` 结束后补上含义。少了这一对
就会得到"未知记号"的报错。

`no associativity`（level 90）让 `st |- a ==> n ==> m` 这种写不出来的东西被明确拒绝。

读法约定：这类定义叫**推理规则**。上面的 `E_APlus` 习惯写成

```
        st |- e1 ==> n1      st |- e2 ==> n2
      -----------------------------------------  (E_APlus)
              st |- e1 + e2 ==> n1 + n2
```

横线（及其上方每个换行）就是 `->`，右侧是构造子名，所有出现的名字（`st`、`e1`、`n1`
……）在最外层被 `forall` 量化。所谓"推理规则"没有任何神秘内容，**它就是构造子**。
"最小关系闭包"这句话对应 `Inductive`：只有能用这五条规则搭出来的推导才是合法的。

`aevalR` 的"最小性"很值得体会：它不是"所有可能的 (st, e, n) 三元组"，也不是
"函数算不出来的那些"，而是**恰好**函数能算出的那些。这一点由下面的定理说死。

第一次动手构造推导（证明树自底向上）：

```coq
Example aevalR_demo :
  (X !-> 5) |- <{ 3 + (X * 2) }> ==> 13.
Proof.
  apply E_APlus with (n1 := 3) (n2 := 10).
  - apply E_ANum.
  - apply E_AMult with (n1 := 5) (n2 := 2).
    + apply E_AId.
    + apply E_ANum.
Qed.
```

这个证明的形状就是推导树：最外层 `E_APlus`，两个子式分别是 `E_ANum` 和 `E_AMult`。
关键手法是 `apply ... with (n1 := 3) (n2 := 10)`：`apply` 只能把结论与目标统一，
而 `n1`、`n2` 是构造子**开头的 `forall`**，不在结论里出现，`apply` 猜不出来，必须用
`with (名字 := 值)` 显式提供。`E_AId` 则不需要——它的结论右边直接是 `st x`，一统一
就定了。

最后是把"函数版"和"关系版"钉在一起：

```coq
Theorem aevalR_iff_aeval : forall st a n,
  (st |- a ==> n) <-> aeval st a = n.
Proof.
  split.
  - intros H. induction H; simpl.
    + reflexivity.
    + reflexivity.
    + rewrite IHaevalR1. rewrite IHaevalR2. reflexivity.
    + rewrite IHaevalR1. rewrite IHaevalR2. reflexivity.
    + rewrite IHaevalR1. rewrite IHaevalR2. reflexivity.
  - generalize dependent n.
    induction a; simpl; intros; subst.
    + apply E_ANum.
    + apply E_AId.
    + apply E_APlus.
      * apply IHa1. reflexivity.
      * apply IHa2. reflexivity.
    + apply E_AMinus.
      * apply IHa1. reflexivity.
      * apply IHa2. reflexivity.
    + apply E_AMult.
      * apply IHa1. reflexivity.
      * apply IHa2. reflexivity.
Qed.
```

两个方向用的是**两种完全不同的归纳**，这才是这个定理的教学价值：

- **→（对推导归纳）**：`induction H` 对归纳谓词 `H : st |- a ==> n` 做归纳，得到
  **五个目标，一个构造子一个**。每个目标里前提变成假设加对应的 IH，命名规则是
  `IHaevalR1`/`IHaevalR2`（按前提顺序）。这就是 52 章坑清单里说的
  **"对推导归纳 = 按构造子分情况"**。三个 `rewrite` 分支的形状完全一样，`simpl`
  把 `aeval st (APlus ...)` 展成 `aeval st a1 + aeval st a2`，两条 IH 重写掉，
  `reflexivity` 收工。
- **←（对语法归纳）**：`induction a` 对表达式结构归纳，五个构造子一个目标。
  每个分支就是"套对应的构造子，再对子式用 IH"。这里出现两个细节：
  - `generalize dependent n` **必须**在 `induction a` 之前。`n` 是目标里的自由变量，
    若不先量化进去，`induction a` 会把 `n` 固定住，IH 就变成
    `st |- a1 ==> n -> ...`（对**同一个** `n`），而我们真正需要
    `forall n, st |- a1 ==> n -> ...`——因为 `APlus` 的两个子式求出的值本来就不一样。
    这是"对归纳谓词之外的变量做归纳"时最经典的一脚空，52 章有专条。
  - `reflexivity` 在 `apply IHa1` 后面出现，是因为 IH 的前提是 `aeval st a1 = ?n`
    这种"等式当输入"的形状；`apply` 之后剩下的就是 `aeval st a1 = aeval st a1`，
    `reflexivity` 一步解决。

这个 `iff` 说明：对**一定收敛**的算术表达式，关系版和函数版一模一样；但
`aevalR` 不逼我们承诺收敛性——**这就是关系化真正的红利**。命令层的 `ceval`
用的正是同一套手法。

### 38.9 `ceval`：大步语义的七条规则

```coq
(* ---------- 38.9 ceval：大步语义的七条规则 ---------- *)

Reserved Notation
  "st0 '=[' c ']=>' st1"
  (at level 40, c custom com at level 99,
   st0 constr, st1 constr at next level,
   format "'[hv' st0  =[ '/  ' '[' c ']' '/' ]=>  st1 ']'").

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      st =[ skip ]=> st
  | E_Asgn : forall st a n x,
      aeval st a = n ->
      st =[ x := a ]=> (x !-> n ; st)
  | E_Seq : forall c1 c2 st st' st'',
      st  =[ c1 ]=> st'  ->
      st' =[ c2 ]=> st'' ->
      st  =[ c1 ; c2 ]=> st''
  | E_IfTrue : forall st st' b c1 c2,
      beval st b = true ->
      st =[ c1 ]=> st' ->
      st =[ if b then c1 else c2 end ]=> st'
  | E_IfFalse : forall st st' b c1 c2,
      beval st b = false ->
      st =[ c2 ]=> st' ->
      st =[ if b then c1 else c2 end ]=> st'
  | E_WhileFalse : forall b st c,
      beval st b = false ->
      st =[ while b do c end ]=> st
  | E_WhileTrue : forall st st' st'' b c,
      beval st b = true ->
      st  =[ c ]=> st' ->
      st' =[ while b do c end ]=> st'' ->
      st  =[ while b do c end ]=> st''

  where "st0 =[ c ]=> st1" := (ceval c st0 st1).
```

先把 `ceval : com -> state -> state -> Prop` 的**参数顺序**看牢：命令在**第一位**。
`where` 子句 `(ceval c st0 st1)` 正是这个顺序；而记号里 `st0` 写在左边，是因为
`'=['` 和 `']=>'` 把 `c` 夹在两个状态中间。这种"参数序和书写序不一致"在
Coq/Rocq 的语义定义里非常常见，读别人的定义时先看 `where` 那行最省力。

记号声明里有两个新面孔：

- `c custom com at level 99`——`=[ ... ]=>` 中间的命令**用 com 频道解析**。所以我们
  能直接写 `st =[ X := 2; Y := 3 ]=> st'`，而不用把命令提到外面先 `Definition`。
- `st1 constr at next level`——`at next level` 是"跟前面那个 level 相邻的下一档"，
  用来让 `st0`、`st1` 两个状态参数的结合性自动匹配。这是官方文档里的一个特例，
  记成"写 `at next level` 免得手工对齐"即可。

七条规则的读法（对应"大步"这个说法）：

| 规则 | 说什么 |
|---|---|
| `E_Skip` | `skip` 从任何状态出发，原地结束 |
| `E_Asgn` | `x := a`：先**用函数 `aeval` 算出** `n`，结束状态是 `x !-> n ; st` |
| `E_Seq` | `c1 ; c2`：存在**中间状态** `st'`，`c1` 到 `st'`、`c2` 从 `st'` 到 `st''` |
| `E_IfTrue` / `E_IfFalse` | 分支：条件用函数 `beval` 判定，走对的那支 |
| `E_WhileFalse` | 条件为假：循环体一次不执行，原地结束 |
| `E_WhileTrue` | 条件为真：跑一遍体到 `st'`，然后 **`st'` 上再跑整个 while** 到 `st''` |

两个要点。

**其一：表达式仍是函数，命令才变成关系。** `E_Asgn` 的前提是 `aeval st a = n`
（一个等式，不是 `aevalR`），`E_If*` 用 `beval st b = true`。这是**正确的设计**：
算术表达式保证收敛，用函数最省事（`reflexivity` 就能算）；只有可能不收敛的
**命令**才需要关系化。混用两层，是 LF 这条路线里最实用的一手，也让本章的证明
不至于全变成构造子堆砌。

**其二：`E_WhileTrue` 里没有"更少迭代"的说明，但它合法。** 结论
`st =[ while b do c end ]=> st''` 的一个前提是
`st' =[ while b do c end ]=> st''`——**同一条命令**再次出现。这在函数定义里会被
守卫检查拒（38.7），但在 `Inductive ... : Prop` 里完全没问题：**归纳定义不是
递归计算，它定义的是"最小不动点"**，即"能被这七条搭出来的三元组集合"。
所以循环的展开次数不固定这件事，在关系表示里是天然表达的。

这也是"大步"的准确含义：`ceval` 一步跳到**最终状态**，中间只留下 `E_Seq` 和
`E_WhileTrue` 需要的**那些**中间状态。40 章的小步语义会改成"每次只走一小步，
状态对状态"。

顺手确认第一条规则的类型（也验证记号确实通了）：

```coq
Check E_Skip : forall st : state, st =[ skip ]=> st.
```

实测输出：

```
E_Skip : forall st : state, st =[skip]=> st
     : forall st : state, st =[skip]=> st
```

两行分别是"这个项自身叫什么类型"和"我们要求它叫什么类型"，一致即通过。注意打印
成 `st =[skip]=> st`：`[skip]` 中间没有空格，是 `format` 之外的默认打印，
不要误读成"命令是 `[skip]`"。

**代价必须说清楚。** 函数版求值，你只要 `Compute ceval_fun st c` 就有答案；
关系版里，"这个程序跑到这个状态"是一个**命题**，你必须**构造证明**。下一节就做这件事。

### 38.10 推导树即证明

```coq
(* ---------- 38.10 推导树即证明 ---------- *)

Example ceval_example1 :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  apply E_Seq with (X !-> 2).
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.
```

程序是"先 `X := 2`，再根据 `X <= 1` 选一支"。因为 `X` 已经是 2，走 else，
所以最终状态只有 `X` 和 `Z` 被改：`(Z !-> 4 ; X !-> 2)`。

证明就是自底向上搭树，四步：

1. `apply E_Seq with (X !-> 2)`——`E_Seq` 的结论是
   `st =[ c1 ; c2 ]=> st''`，两个前提共享一个**中间状态 `st'`**。`st'` 是
   `E_Seq` 开头的 `forall` 变量，不在结论里，`apply` 猜不出来，必须用
   `with (X !-> 2)` 提供。这一步把目标切成两个子目标：
   `empty_st =[ X := 2 ]=> (X !-> 2)` 和
   `(X !-> 2) =[ if ... end ]=> (Z !-> 4 ; X !-> 2)`。
2. `apply E_Asgn` 剩下前提 `aeval (X !-> 2) <{2}> = ?n`——一个**计算等式**，
   `reflexivity` 直接算掉。这就是 38.9 "表达式保持函数"带来的实惠。
3. `apply E_IfFalse` 剩下 `beval (X !-> 2) <{X <= 1}> = false` 和
   `(X !-> 2) =[ Z := 4 ]=> (Z !-> 4 ; X !-> 2)`。前者又是一个计算，`reflexivity`。
4. 最后又是一条赋值。

也就是说：**这个例子里"语义"的全部非计算内容，就是一次 `E_Seq with`。**

第二个例子练同样的手法，重点是"三个串联赋值要提供两个中间状态"：

```coq
Example ceval_example2 :
  empty_st =[
    X := 0;
    Y := 1;
    Z := 2
  ]=> (Z !-> 2 ; Y !-> 1 ; X !-> 0).
Proof.
  apply E_Seq with (X !-> 0).
  - apply E_Asgn. reflexivity.
  - apply E_Seq with (Y !-> 1 ; X !-> 0).
    + apply E_Asgn. reflexivity.
    + apply E_Asgn. reflexivity.
Qed.
```

`X := 0; Y := 1; Z := 2` 因为 `;` 右结合，语法上是
`CSeq (X:=0) (CSeq (Y:=1) (Z:=2))`，所以第一层 `E_Seq` 的中间状态是 `X !-> 0`
（等价于 `X !-> 0 ; empty_st`），第二层的中间状态是 `Y !-> 1 ; X !-> 0`
（即 `Y !-> 1 ; (X !-> 0 ; empty_st)`）。目标里写成 `Z !-> 2 ; Y !-> 1 ; X !-> 0`
是同一棵树换个数，右结合读法一致。

两个 spec 定理，示范"从推导反推"：

```coq
Theorem plus2_spec : forall st n st',
  st X = n ->
  st =[ plus2 ]=> st' ->
  st' X = n + 2.
Proof.
  intros st n st' HX Heval.
  inversion Heval. subst. clear Heval.
  simpl. apply t_update_eq.
Qed.

Theorem XtimesYinZ_spec : forall st n m st',
  st X = n ->
  st Y = m ->
  st =[ XtimesYinZ ]=> st' ->
  st' Z = n * m.
Proof.
  intros st n m st' HX HY Heval.
  inversion Heval. subst. clear Heval.
  simpl. apply t_update_eq.
Qed.
```

这两条读法相同，`plus2_spec` 说：任何满足 `st X = n` 的初始状态、任何使
`st =[ plus2 ]=> st'` 成立的结束状态，必有 `st' X = n + 2`。注意
`XtimesYinZ_spec` 是原书留的练习，这里补齐——它和 `plus2_spec` 的差别只有两个前提。

`inversion Heval` 是关系式语义的另一半工具，值得讲清：它的功能是"**如果这个推导
成立，只能是用哪个构造子、参数得是什么**"。`plus2` 是 `CAsgn X <{X+2}>`，七条规则里
只有 `E_Asgn` 的头能匹配，于是 `inversion` 生成：

```
Heval : st =[plus2]=> (X !-> aeval st <{X + 2}>; st)
```

（实测到的形态，`inversion` 后）它把结论"拆"成唯一可能的构造方式，并把
`st'` 表达成 `(X !-> aeval st <{X+2}>; st)`。

接下来的 `subst` 有一个**容易踩的反直觉**点，值得实测给你看。假设 `HX : st X = n`
在环境里；直觉是"最后 `rewrite HX`"。但 `subst` 会看到 `HX` 是"某变量 `n` = 一个不含
`n` 的项"，于是**把 `n` 换成 `st X` 并删掉 `HX`**——方向和你打算的正好相反。实测
`subst` 后的目标是

```
  st : string -> nat
  Heval : st =[plus2]=> (X !-> aeval st <{X + 2}>; st)
  ============================
  (X !-> aeval st <{X + 2}>; st) X = st X + 2
```

`n` 已经没了，`HX` 也没了。所以正确的收尾**不是** `rewrite HX`（会报
`The variable HX was not found in the current environment.`——本例第一版就是这么
写、就报错、然后改过来的），而是让 `simpl` 把两边都归约到同一形状后
`apply t_update_eq`：

```
  st : string -> nat
  ============================
  (X !-> st X + 2; st) X = st X + 2
```

`(x !-> v ; m) x = v` 与这条目标精确匹配。`clear Heval` 只是卫生（把已经用完的
推导假设删掉，免得后面 tactic 误用），不影响证明。

这一处给出一条通用经验：**`inversion` + `subst` 之后，先 `Show` 一眼目标再选收尾
tactic**，不要凭"我原本想怎么用那条假设"来写。

### 38.11 确定性：`ceval` 是偏函数

把语义从函数换成关系，就欠下一个必须还的债：关系可能**多值**。也就是说
——从同一个状态出发跑同一个程序，会不会跑出两个不同的结束状态？如果会，
这套语义就不能当我们后面的推理基础。答案是不会：

```coq
(* ---------- 38.11 确定性：ceval 是偏函数 ---------- *)

Theorem ceval_deterministic : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
```

"偏函数"的准确意思就是这两件事：**存在性**不保证（`loop` 就不存在结束状态，
见 38.12），但**唯一性**保证。这条定理证的是后者。

```coq
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2; inversion E2; subst.
```

三步起手，每一步都有必要：

1. `intros c st st1 st2 E1 E2` 把定理开头的 `forall` 和**第一条**前提引入，
   留下 `E2` 的目标。
2. `generalize dependent st2`——必须把已经引入的 `st2` **重新量化回目标**。
   为什么？因为接下来 `induction E1`：`E1 : st =[ c ]=> st1`，它的**索引**是 `c`
   和 `st1`，而 `st2` 出现在目标里、`st2` 本身与 `E1` 无关——但只要环境里还有
   和 `E1` 索引"看着有关系"的东西，归纳假设就会弱得没法用。更实用的判断标准是：
   **凡是你希望归纳假设能"对任意值"成立的变量，归纳前必须 generalize。**
   这里我们希望 IH 是"对任意 `st2`，`st =[ c ]=> st2 -> st1 = st2`"，所以
   `st2` 必须回到目标里。这和 38.8 的 `generalize dependent n` 是同一个手法。
3. `induction E1; intros st2 E2; ...`——对推导 `E1` 归纳（= 按七个构造子分情况，
   和 `aevalR_iff_aeval` 第一方向同一手法），归纳造出的每个目标里
   `st2` 和 `E2` 又被赶出去了，所以用 `; intros st2 E2` 一把全部重新引入。
   这是"对推导归纳"的标准三连。

`inversion E2; subst` 是消去另一半推导。直觉：`E1` 已经告诉我们这个命令是哪种形状
（`skip`？赋值？序列？），那 `E2` 只能用**同一条构造子**，`inversion` 就把它拆成
那个构造子的前提。

```coq
  - reflexivity.
  - reflexivity.
  - rewrite (IHE1_1 st'0 H1) in *.
    apply IHE1_2. assumption.
  - apply IHE1. assumption.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - apply IHE1. assumption.
  - reflexivity.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *.
    apply IHE1_2. assumption.
Qed.
```

**十一个 bullet 对七个构造子**——这个不对称是本证明最值得看懂的地方。
`inversion E2` 会把"同一构造子但条件互斥"的情况切成多个子情况。逐一对应：

| bullet | 来自 | 说明 |
|---|---|---|
| 1 | `E_Skip` | `inversion E2` 只能也是 `E_Skip`，两边 `st1 = st = st2`，`reflexivity` |
| 2 | `E_Asgn` | 同上；`st1`、`st2` 都是 `(x !-> n ; st)`，`subst` 后已合一 |
| 3 | `E_Seq` | 两个中间状态：`st'`（来自 `E1`）与 `st'0`（`E2` 造的） |
| 4–5 | `E_IfTrue` | `b` 为真（走 IH）/ `b` 为假（矛盾） |
| 6–7 | `E_IfFalse` | 反过来 |
| 8 | `E_WhileFalse` | 条件假，原地结束，`reflexivity` |
| 9 | `E_WhileFalse` | `E2` 却是 `E_WhileTrue`，条件矛盾 |
| 10–11 | `E_WhileTrue` | 条件假（矛盾）/ 条件真（两个 IH） |

关键在 `E_Seq` 和 `E_WhileTrue` 这两个"两层递归"的情况。以 `E_Seq` 为例：

```coq
  - rewrite (IHE1_1 st'0 H1) in *.
    apply IHE1_2. assumption.
```

命名规律：`IHE1_1`、`IHE1_2` 是 `E1` 的第 1、第 2 条前提对应的 IH（单前提的构造子
就叫 `IHE1`）。此时环境大致是：

- `IHE1_1 : forall st'0, st =[ c1 ]=> st'0 -> st1 = st'0`（对 `c1` 的 IH）
- `H1 : st =[ c1 ]=> st'0`（来自 `inversion E2`，`E2` 的第一段）
- `IHE1_2 : forall st2, st' =[ c2 ]=> st2 -> st1 = st2`（对 `c2` 的 IH）
- 目标 `st1 = st''` 之类

`rewrite (IHE1_1 st'0 H1) in *` 用"`c1` 的结果唯一"把 `E2` 里那个 `st'0` 换成本人
`st'`——这一步是整条证明的核心动作：**先统一中间状态，两段推导就变成同一个起点**。
之后 `apply IHE1_2. assumption.` 用第二个 IH 对已经变成 `st'` 的那条前提收口。

`E_WhileTrue` 那两条一模一样的写法（`rewrite (IHE1_1 st'0 H3) in *.` 然后
`apply IHE1_2. assumption.`），只是前提的名字变成 `H3`——**同一手法在不同构造子上
复用**，这正是关系式语义可推理的体现。

至于 `rewrite H in H5. discriminate.`：`H` 是 `E1` 里"条件求值 = true"的等式，
`H5` 是 `inversion E2` 造出的"同一个条件求值 = false"，重写后变成
`false = false` 之外的形状（`true = false`），`discriminate` 一击解决。这类
"两个构造子的条件前提互斥"分支占了一半篇幅——它正是 `E_IfTrue`/`E_IfFalse`、
`E_WhileFalse`/`E_WhileTrue` **各自拆成两条规则**（而不是合成一条带 `if` 的规则）
换来的可推理性。

最后确认它没有偷用公理：

```coq
Print Assumptions ceval_deterministic.
```

实测：

```
Closed under the global context
```

**无公理**。对比 33 章的 `t_update_shadow` 需要 `functional_extensionality_dep`：
本定理的结论是 `st1 = st2`，而 `subst` 之后两边**语法上就是同一个项**，所以
`reflexivity` 够用，压根不需要外延性。**这是一个很实用的信号**：如果你的状态等式
证明明明只是"两边被同一堆赋值更新"，却要动用外延公理，通常是中间步骤走岔了。

### 38.12 `loop` 永不停止：对推导归纳

确定性说的是"最多一个结果"。本节补上另一半：有些程序**一个结果都没有**。

```coq
(* ---------- 38.12 loop 永不停止：对推导归纳 ---------- *)

Theorem loop_never_stops : forall st st',
  ~(st =[ loop ]=> st').
```

`~ P` 就是 `P -> False`，所以引入假设后目标是 `False`：手上有一条 `loop` 的推导，
要推出矛盾。这是**关系式语义的标准否定证明**——你无法"计算"出一个非终止，只能证明
"任何声称终止的推导都不存在"，方法是**对那条推导本身做归纳**，说明七条规则里没有
一条能搭出它。

```coq
Proof.
  intros st st' contra. unfold loop in contra.
  remember <{ while true do skip end }> as loopdef
           eqn:Heqloopdef.
  induction contra; inversion Heqloopdef.
  - rewrite H1 in H. discriminate H.
  - apply IHcontra2. rewrite H1, H2. reflexivity.
Qed.
```

逐行说。

`intros st st' contra.` 之后实测的环境与目标：

```
  st, st' : state
  contra : st =[loop]=> st'
  ============================
  False
```

`unfold loop in contra.` 把 `contra` 变成 `st =[while true do skip end]=> st'`。
这一步不能省：直接 `induction contra` 会被一个具体命令索引卡住（见下）。

`remember <{ ... }> as loopdef eqn:Heqloopdef.` 是本证明的枢纽。它的效果是把
`contra` 里那个**具体的命令**换成一个**变量** `loopdef`，并留下一条等式假设。
实测后的环境：

```
  st, st' : state
  loopdef : com
  Heqloopdef : loopdef = <{while true do skip end}>
  contra : st =[loopdef]=> st'
  ============================
  False
```

为什么要绕这一下？因为 `induction contra` 要对索引做抽象；索引如果是一个具体项
（`while true do skip end`），抽象出来的归纳性质会形状很差甚至报"Abstracting over
the terms ... leads to an ill-typed term"。`remember` 是 Coq/Rocq 里对付这事的
标准武器——**它就是把"具体值"换成"变量 + 等式"的那一步 generalize**，和 38.8
的 `generalize dependent` 属于同一族，只是对象是子项而非整个变量。

`induction contra; inversion Heqloopdef.`：前者按七个构造子分情况，后者用等式把
`Heqloopdef` 拆穿——七条里只有 `E_WhileFalse`、`E_WhileTrue` 的结论形状是 `CWhile`，
其余五条被 `inversion` **当场判定不可能**（例如 `E_Skip` 情况下会出现
`<{while true do skip end}> = CSkip`）。实测剩两个目标：

```coq
  - rewrite H1 in H. discriminate H.
```

第一个是 `E_WhileFalse`。此时环境（实测节选）：

```
  b : bexp
  c : com
  Heqloopdef : <{while b do c end}> = <{while true do skip end}>
  st : state
  H : beval st b = false
  H1 : b = <{true}>
  H2 : c = <{skip}>
  ============================
  False
```

`inversion Heqloopdef` 把 `b`、`c` 的具体值作为 `H1`、`H2` 留下。`discriminate H`
**直接对 `H` 用会失败**（实测 `Error: Not a discriminable equality.`）——因为
`H : beval st b = false` 里的 `b` 还是个变量，`beval st b` 归约不动。必须先
`rewrite H1 in H` 把 `b` 换成 `<{true}>`，`H` 变成 `true = false` 才 `discriminate`。
**"先重写再 discriminate"是这类矛盾分支的固定套路**，52 章有专条。

第二个是 `E_WhileTrue`。目标形状（实测节选）：

```
  b : bexp
  c : com
  Heqloopdef : <{while b do c end}> = <{while true do skip end}>
  st, st', st'' : state
  H : beval st b = true
  contra1 : st =[c]=> st'
  contra2 : st' =[while b do c end]=> st''
  IHcontra1 : c = <{while true do skip end}> -> False
  IHcontra2 : <{while b do c end}> = <{while true do skip end}> -> False
  H1 : b = <{true}>
  H2 : c = <{skip}>
  ============================
  False
```

`IHcontra2` 的形状很意外（它的前提是个**等式**而不是推导），值得解释清楚，因为
`induction` 自动生成 IH 这件事必须能被预判。原因：`Heqloopdef : loopdef = <{...}>`
提到了索引 `loopdef`，所以 `induction contra` 会**自动把依赖索引的假设 revert 进
目标**。于是归纳性质变成

```
fun c st0 st1 => c = <{while true do skip end}> -> False
```

——这正是我们看到的 IH 形状。**结论：`remember` 之后 IH 会带上那条等式作为前提，
这是 revert 的必然结果，不是 bug。**

有了这个形状，收尾就很直白：`apply IHcontra2.` 把目标变成
`<{while b do c end}> = <{while true do skip end}>`，`rewrite H1, H2. reflexivity.`
用 `inversion` 给的 `b = <{true}>`、`c = <{skip}>` 把左右写成一样。注意
`contra2` 全程没被用到——不需要，因为 IH 要的是"这条命令就是 loop"。

这条定理和 38.11 的合起来说清了 `ceval` 的准确身份：**部分函数**。
`plus2` 有唯一结果，`loop` 没有结果，任何命令至多一个结果。

### 38.13 栈机：一个能跑的编译目标

本章收官给一个完整的应用：把 `aexp` 编译到一台**栈机**上，并证明编译保语义。
（原书把这一节留作练习，这里把实现和正确性一并写全。）

```coq
(* ---------- 38.13 栈机：一个能跑的编译目标 ---------- *)

Inductive sinstr : Type :=
  | SPush (n : nat)
  | SLoad (x : string)
  | SPlus
  | SMinus
  | SMult.
```

五条指令的约定：`SPush n` 压常数；`SLoad x` 压 `st x`；`SPlus`/`SMinus`/`SMult`
弹出栈顶两个数、把运算结果压回。`SMinus` 的方向后面用一条实测例子钉死。

**先处理"指令怎么用"这件事。** 原书的练习里让 `s_execute` 直接在 `Fixpoint` 里对
`prog` 和 `stack` 双重匹配；那种写法正确性证明会卡在"栈不够深怎么办"上。这里改
成一个更干净的分解：**一条指令的作用是一个纯函数**，`s_execute` 只负责"依次施加"。

```coq
Definition s_step (st : state) (stack : list nat) (i : sinstr) : list nat :=
  match i, stack with
  | SPush n, _            => n :: stack
  | SLoad x, _            => st x :: stack
  | SPlus,  n :: m :: s'  => (m + n) :: s'
  | SMinus, n :: m :: s'  => (m - n) :: s'
  | SMult,  n :: m :: s'  => (m * n) :: s'
  | _, _                  => stack
  end.
```

`match i, stack with` 是**多重匹配**：一次对两个参数做情形分析，模式用逗号分隔。
比嵌套 `match` 少一层缩进、也少一堆重复的分支收尾。

两条约定要看准：

- 弹两个数时模式写成 `n :: m :: s'` 而结果写 `m + n`。`n` 是**栈顶**（最后算出的
  那个），`m` 是**次栈顶**（先算出的那个）。所以 `SMinus` 算的是 `m - n` =
  "先算的减后算的"。编译器要保证减法的正确顺序，靠的就是这条约定。
- 最后一行 `| _, _ => stack` 兜住"栈不足两个元素"的畸形情形——**跳过该指令**。
  这不是敷衍：正确性证明只对合法编译产物说话，但把非法情形定义成"不改变栈"能让
  `s_execute` 是全函数、并且让下面的组合律在任何栈上都成立（这一点在证明里省掉了
  全部栈深度的推理）。

```coq
Fixpoint s_execute (st : state) (stack : list nat)
                   (prog : list sinstr) : list nat :=
  match prog with
  | [] => stack
  | i :: prog' => s_execute st (s_step st stack i) prog'
  end.
```

递归只发生在 `prog` 的尾上，repl 实测确认信息
`s_execute is recursively defined (guarded on 3rd argument)`。注意和 38.7 的对比：
这里**没有**"把两条指令拼起来再递归"之类的动作，所以守卫检查一眼就过。
`stack` 是**累加器**，`st` 全程不变（栈机只求表达式，不改内存）。

两条自检测试：

```coq
Example s_execute1 :
  s_execute empty_st [] [SPush 5; SPush 3; SPush 1; SMinus] = [2; 5].
Proof. reflexivity. Qed.

Example s_execute2 :
  s_execute (X !-> 3) [3;4] [SPush 4; SLoad X; SMult; SPlus] = [15; 4].
Proof. reflexivity. Qed.
```

`s_execute1` 把减法方向说死了：栈依次变成
`[] → [5] → [3;5] → [1;3;5]`，`SMinus` 拿 `n=1`、`m=3` 得 `3-1=2`，结果 `[2;5]`。

`s_execute2` 同时测了 `SLoad`、`SMult`、`SPlus`，初值栈 `[3;4]` 故意和结果里的
`4` 撞车，防止你误判：`[3;4] →SPush 4 [4;3;4] →SLoad X [3;4;3;4]`（`st X = 3`）
`→SMult` 拿 `n=3,m=4` 得 `12`，`[12;3;4]`；`→SPlus` 拿 `n=12,m=3` 得 `15`，
`[15;4]`。两条都是 `reflexivity` 直接算出来——机器码解释器不需要证明，跑就是了。

**编译器**把表达式翻译成"先算左、再算右、再合并"的后序序列：

```coq
Fixpoint s_compile (e : aexp) : list sinstr :=
  match e with
  | ANum n => [SPush n]
  | AId x => [SLoad x]
  | <{a1 + a2}> => s_compile a1 ++ s_compile a2 ++ [SPlus]
  | <{a1 - a2}> => s_compile a1 ++ s_compile a2 ++ [SMinus]
  | <{a1 * a2}> => s_compile a1 ++ s_compile a2 ++ [SMult]
  end.
```

`++` 右结合（List 的记号是右结合），所以 `s_compile a1 ++ s_compile a2 ++ [SPlus]`
是 `s_compile a1 ++ (s_compile a2 ++ [SPlus])`。这个事实下面证明里要用到。
模式里 `ANum n`/`AId x` 是裸构造子、三条运算是 `<{ }>` 记号模式，理由和 38.4 一样。

```coq
Example s_compile1 :
  s_compile <{ X - (2 * Y) }>
  = [SLoad X; SPush 2; SLoad Y; SMult; SMinus].
Proof. reflexivity. Qed.
```

`X - (2*Y)` 编成 `SLoad X; SPush 2; SLoad Y; SMult; SMinus`，正是后序
`X 2 Y * -`。跑一遍核对：`[] → [3] → [3;X]`（设 `X=3`、`Y=4`：`[3] → [2;3] →
[4;2;3] →SMult [8;3] →SMinus` 拿 `n=8,m=3` 得 `3-8`……在 `nat` 里是 `0`，而
`aeval (X !-> 3 ; Y !-> 4) <{X - 2*Y}> = 3 - 8 = 0`。**两边都受 `nat` 截断的同一个
坑**，所以编译仍然正确——这是 24 章"nat 减法截断"在编译器语境下的回声。

正确性分三步。先证**执行可分段**：

```coq
Theorem execute_app : forall st p1 p2 stack,
  s_execute st stack (p1 ++ p2)
  = s_execute st (s_execute st stack p1) p2.
Proof.
  intros st p1. induction p1 as [| i p1' IH]; intros p2 stack; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.
```

这条证明之所以只有四行，全靠 `s_step` 那层分解：`s_execute` 的递归只跟 `prog` 走，
`stack` 是纯累加器，于是"分段"就是列表归纳一步到位。归纳的 `-` 分支里，目标左端是
`s_execute st (s_step st stack i) (p1' ++ p2)`，右端是
`s_execute st (s_execute st (s_step st stack i) p1') p2`——
恰好是 `IH` 在 `stack := s_step st stack i` 处的实例，`rewrite IH` 之后两边字面相同，
`reflexivity` 收尾。

注意 `induction p1 as [| i p1' IH]; intros p2 stack`：**先归纳再引入** `p2`、`stack`。
如果顺序反过来把 `p2`、`stack` 提前引入成固定值，IH 就无法在任何中间栈上实例化，
这条定理证不出来。这是 `generalize dependent` 家族（38.8、38.11）的又一个具体形状。

再证**编译保值**（引理化成"任意初始栈"的强命题）：

```coq
Lemma s_compile_correct_aux : forall st e stack,
  s_execute st stack (s_compile e) = aeval st e :: stack.
Proof.
  intros st e. induction e as [| | a1 IHa1 a2 IHa2 | a1 IHa1 a2 IHa2
                                                   | a1 IHa1 a2 IHa2];
    intros stack; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite execute_app. rewrite execute_app.
    rewrite IHa1. rewrite IHa2. simpl. reflexivity.
  - rewrite execute_app. rewrite execute_app.
    rewrite IHa1. rewrite IHa2. simpl. reflexivity.
  - rewrite execute_app. rewrite execute_app.
    rewrite IHa1. rewrite IHa2. simpl. reflexivity.
Qed.
```

引理陈述比定理更**强**（对任意 `stack` 而非 `[]`），这是归纳证明的经典手法：
弱命题的 IH 不够用，把自由的部分固定化才能归纳。这里必须如此——编译产物最后一条
`SPlus` 会**读走**初始栈顶，若 `stack` 固定成 `[]`，IH 根本对不上。

`induction e as [...]` 的 `as` 列表逐一对应五个构造子：`ANum`（1 个名字位）、
`AId`（1 位）、`APlus`/`AMinus`/`AMult`（各 3 位：子式 + 两个 IH）。空位 `|` 表示
该构造子不绑定任何变量。写 `as` 的价值在于**名字可预判**，不写就得靠
`Show` 猜 `IHa`/`IHa0` 之类的自动生成名。

`+` 分支的四步重写值得逐步跟踪（`-`、`*` 完全同形）：

1. 目标左端 `s_execute st stack (s_compile a1 ++ (s_compile a2 ++ [SPlus]))`。
2. 第一个 `rewrite execute_app` 匹配最外层 `p1 ++ p2`（`p1 = s_compile a1 ++ ...`），
   把左端变成 `s_execute st (s_execute st stack (s_compile a1 ++ s_compile a2)) [SPlus]`。
3. 第二个 `rewrite execute_app` 匹配内层那个 `... (s_compile a1 ++ s_compile a2)`
   （外层已经不是 `++` 形状，匹配不到），于是变成
   `s_execute st (s_execute st (s_execute st stack (s_compile a1)) (s_compile a2)) [SPlus]`。
4. `rewrite IHa1`（作用于最内层，栈是 `stack`）、`rewrite IHa2`（栈变成
   `aeval st a1 :: stack`）之后，左端是
   `s_execute st (aeval st a2 :: aeval st a1 :: stack) [SPlus]`。
5. 再来一次 `simpl`：执行 `[SPlus]` = `s_step st (aeval st a2 :: aeval st a1 :: stack) SPlus`
   = `(aeval st a1 + aeval st a2) :: stack`。右端经 `simpl` 也是
   `aeval st (a1 + a2) :: stack` 归约到 `aeval st a1 + aeval st a2 :: stack`。
   `reflexivity` 成。

最后一步能对上，全靠 `s_step` 里那条 `m + n` 的方向约定和第 4 步"先算的在深处"
的次序一致。**栈机编译器的正确性，本质上就是这个次序一致性**——把这两个事实写反
其中任何一个，第 5 步就会差一个加减号顺序，而 `nat` 截断甚至会让反例只在个别输入
上出现（正是 `s_compile1` 那个 `3 - 8` 的教训）。

主定理就是一条 `apply`：

```coq
Theorem s_compile_correct : forall (st : state) (e : aexp),
  s_execute st [] (s_compile e) = [ aeval st e ].
Proof.
  intros st e. apply s_compile_correct_aux.
Qed.

Print Assumptions s_compile_correct.
```

`apply` 一步过，因为引理的结论
`s_execute st stack (s_compile e) = aeval st e :: stack` 与目标统一时，
`stack` 被定为 `[]`，右边 `aeval st e :: []` 与 `[ aeval st e ]` 是**同一个项**
（`[x]` 的语法糖就展开成 `x :: []`）。

`Print Assumptions s_compile_correct.` 实测同样是
`Closed under the global context`——**无公理**。

这条定理的形态值得单独记住，它是全书第一个真正的"程序变换保语义"：

```
执行(编译(e), 空栈) = [求值(e)]
```

左边是**语法操作**（`s_compile` 把 AST 变成指令列表），右边是**语义操作**
（`aeval` 把 AST 变成数），定理说这两个交换图可交换。32 章的优化器证明的是
`aeval (optimize a) = aeval a`（同层变换保语义），这里证的是跨层变换保语义。
后面 43 章 Hoare 逻辑、47 章类型一致性，走的都是这个骨架。

```coq
End Ex38ImpSemantics.
```

### 38.14 本章坑位清单（实测）

1. **`<{ }>` 必须先 `Open Scope com_scope`**（38.3）：删掉这一行实测报
   `Unknown interpretation for notation "<{ _ }>". This notation is available in com_scope.`
   记号"存在但不在作用域"是本章第一道坎；报错文本直接给了出路。
2. **命令记号漏写 `in custom com` 会抢默认语法**（38.5）：`x ; y := CSeq x y` 若没有
   `in custom com`，会和 `list_scope` 的 `[x; y]` 直接冲突。`Locate ";"` 实测列出三种
   解释（`CSeq`／`t_update`／`cons`），它们能共存**完全靠频道隔离**。新增记号时先想清楚
   它该住在哪个频道/作用域。
3. **`Coercion` 默认打印时藏掉**（38.6）：`Print fact_in_coq` 给你 `CAsgn Z X`，实际项是
   `CAsgn Z (AId X)`。调试语义定义时**务必** `Set Printing Coercions`；`Set Printing All`
   还能顺手看到 `nat` 的一元真身（实测 `ANum (S (S (S (S O))))`）。
4. **模式里能否用记号，取决于记号是否 `only parsing`**（38.4）：`aeval` 里 `APlus` 能写成
   `<{a1 + a2}>`，`ANum`/`AId` 必须写裸构造子——com 频道里没有它们的反向记号。
   另外 `Notation "f x .. y"` 的 `only parsing` 不能省，否则打印匹配会大面积误命中。
5. **`in custom com at level 0, x constr at level 0` 两条 level 都要写**（38.3）：
   只写 `x constr at level 0`（漏掉条目侧的 `at level 0`）实测报
   `Need an explicit level.` 原书这两条 level 不是冗余。
6. **level 相关的两条警告是预期内的，不要为了消警告改 level**（38.3、38.5）：
   `level-0-notation-not-closed` 来自 `x := y`，`closed-notation-not-level-0` 来自
   `'if' ... 'end'`/`'while' ... 'end'`。改掉就会破坏 40/50/70/75/80/85/89/90/99 的优先级阶梯。
7. **`Fixpoint` 拒绝的不是死循环，是"不保证终止"**（38.7）：`ceval_fun_no_while` 因为
   `while` 分支**不递归**而被接受（`guarded on 2nd argument`），却给出错误语义——我们甚至能
   `reflexivity` 证明 `ceval_fun_no_while empty_st loop = empty_st`。真正带递归的版本实测报
   `Cannot guess decreasing argument of fix.`。教训：**能编译的语义定义未必是对的语义定义**，
   必须有一条"不收敛程序无推导"的定理（`loop_never_stops`）来兜底。
8. **LF 那两条 `Notation "'true'" := true (at level 1)` 在 rocq 9.3 冗余**（38.3）：
   实测整段删掉示例仍 EXIT=0，并少掉两条 `closed-notation-not-level-0` 警告。
   抄旧稿代码前先 `Fail Check` / 直接删掉试一次，别把历史包袱当必需。
9. **`generalize dependent` 不是可选装饰**（38.8、38.11、38.13）：
   `aevalR_iff_aeval` 反方向缺 `generalize dependent n`，IH 会被钉死在同一个 `n` 上；
   `ceval_deterministic` 缺 `generalize dependent st2`，IH 弱到无法使用；
   `execute_app` 缺"先归纳再 `intros p2 stack`"，IH 无法在中间栈上实例化。
   **判断标准：IH 需要"对任意 X"成立，就把 X 留在目标里。**
10. **`inversion` 后的 `subst` 可能反向消费你的假设**（38.10）：`plus2_spec` 里
   `HX : st X = n` 被 `subst` 变成"把 `n` 换成 `st X`"并删除，之后再
   `rewrite HX` 实测报 `The variable HX was not found in the current environment.`
   正确收尾是 `simpl. apply t_update_eq.`。**`subst` 之后先 `Show` 目标再选 tactic。**
11. **`discriminate` 前常常要先 `rewrite`**（38.12）：`H : beval st b = false` 里 `b`
   是变量时实测报 `Not a discriminable equality.`；`rewrite H1 in H` 换成 `<{true}>`
   再 `discriminate` 才通。
12. **`remember` 会把 IH 变成带等式前提的形状**（38.12）：因为 `Heqloopdef` 提到了
    `ceval` 的索引 `loopdef`，`induction contra` 自动 revert 它，IH 就成了
    `... = <{while true do skip end}> -> False`。看到 IH 形状和预期不符，先想
    "哪条假设依赖了索引"。
13. **`nat` 减法截断会掩盖编译器的方向错误**（38.13）：`X - 2*Y` 在 `X=3,Y=4` 下
    `aeval` 和栈机都算 `0`，即使 `SMinus` 的 `m - n` 写反了也可能一时测不出来。
    自检测试要选**两边结果不同**的输入。
14. **`s_step` 的兜底分支让组合律无条件成立**（38.13）：`| _, _ => stack`（栈太浅就
    跳过指令）把畸形输入定义成"不变"，`execute_app` 才能对任意 `stack` 一句话证完。
    定义解释器时，**非法情形怎么定义会直接决定证明难度**。

---
上一章：[37 · 自定义记号与语法](37-notation.md) ｜ 下一章：[39 · 燃料求值器：把关系变回函数](39-fuel-evaluation.md) ｜ 返回：[README](../README.md)
