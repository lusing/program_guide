# 37 · 自定义记号与语法

对应示例：`../examples/37_notation.v`（`Module Ex37Notation`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

38 章我们要写 `X := X + 2` 这样的 Imp 程序，但 Rocq 的世界里有的是 `CAsgn "X"
(APlus (AId "X") (ANum 2))`。把两者接起来的，是三样常被当成"魔法"的机制：

1. **Coercion（强制转换）**：让 `X`（一个 string）在需要 `aexp` 的位置自动变成
   `AId X`；
2. **Notation + Scope（记号与作用域）**：让 `+` 在不同上下文里指向不同函数，且互不打架；
3. **Custom Entry（自定义语法条目）**：开一块"语法特区"，在里面重新定义整套运算符
   优先级，再用 `<{ }>` 抬回主语法。

本章按"最小实验 → 完整工程 → 再造一遍"的顺序解剖它们：37.2 用一个两行记号做对照
实验，37.3–37.4 搭起 38 章用的整套 `com` 条目，37.7 把同一套机制**再造一遍**——给霍尔
逻辑的断言（43.7 的 `bassertion` 世界）造一个 `assn` 条目，让你能写
`{{ X = 3 \/ X <= Y }}`。最后一节 37.8 是反例集：类型串了、level 错了、作用域没开，
各报什么错（全部 `Fail` 实测）。

这套东西的完整工程版在 38 章（Imp 语言）里首次投入实战；43 章为省篇幅用了 `fun st =>`
的显式断言形式，本章 37.7 补上它的"漂亮记号"版本，两个世界互为对照。

### 37.1 为什么需要 Coercion：string / nat 怎么变成 aexp

先铺一块最小的语言地基（与 33/38 章同源）：全映射状态、算术与布尔表达式：

```coq
(* 37 自定义记号与语法 —— Coercion、Notation、Custom Entry、level 阶梯与 assn 再造 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex37Notation.

(* ---------- 37.1 为什么需要 Coercion：string / nat 怎么变成 aexp ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Definition state := total_map nat.

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

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

没有 coercion 时的世界是这样的：

```coq
Definition raw_aexp : aexp := APlus (AId X) (ANum 2).

Fail Definition no_coercion : aexp := X.

Fail Definition no_coercion_pair : aexp := APlus X 2.
```

两条 `Fail` 在 repl 里的真实报错（`rocq compile` 对 `Fail` 静默，这是 2 章的老坑）：

```
The command has indeed failed with message:
The term "X" has type "string" while it is expected to have type "aexp".
```

`X` 是 string，`aexp` 要的是构造子。两条命令声明 coercion：

```coq
Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.
```

repl 各打印一行 `AId is now a coercion` / `ANum is now a coercion`。从此：

```coq
Definition sugar_aexp : aexp := APlus X 2.

Check X.

Fail Definition wrong_way : nat := AId X.

Set Printing Coercions.
Print sugar_aexp.
Unset Printing Coercions.
```

读这五行的三个要点（输出均为 repl 实测）：

- `sugar_aexp` 合法了：`APlus X 2` 里 `X` 被自动抬成 `AId X`、`2` 抬成 `ANum 2`。
- `Check X.` 仍打印 `X : string`——**coercion 不改变 X 的类型**，它只在"期望 aexp、
  实际 string"的位置插一个 `AId`。同一个 `X`，出现在 `APlus X 2` 里是 aexp，单独
  `Check` 是 string。
- coercion 是**单向**的：`wrong_way` 想把 `AId X` 变回 nat，实测报
  `The term "AId X" has type "aexp" while it is expected to have type "nat".`
  要双向各声明一条，且要真的存在那个函数。
- `Set Printing Coercions. Print sugar_aexp.` 显式显示被插入的转换：
  `sugar_aexp = APlus (AId X) (ANum 2)`。脱糖三件套的完整版在 37.6。

### 37.2 Notation 的基本形态与 scope：一个最小对照实验

在搭大工程之前，用一个两行的记号把 Notation 的全部要素看清。先定义一个真函数
（记号只是**语法**，必须有语义目标）：

```coq
(* ---------- 37.2 Notation 的基本形态与 scope：一个最小对照实验 ---------- *)

Definition addmul (a b : nat) : nat := a + a * b.

Declare Scope n_demo_scope.
Delimit Scope n_demo_scope with nd.

Notation "a '+*' b" := (addmul a b)
  (at level 40, left associativity) : n_demo_scope.
```

四件事：`Declare Scope` 开一个新作用域；`Delimit ... with nd` 给它一个 `%nd` 限定符；
`Notation` 把记号 `a +* b` 绑到 `addmul a b`，指定 level 40、左结合，并**注册进**
`n_demo_scope`。三个使用姿势：

```coq
Check ((1 +* 2))%nd.

Example nd_left_assoc : ((1 +* 2 +* 3))%nd = 12.
Proof. reflexivity. Qed.

Open Scope n_demo_scope.

Check 1 +* 2 +* 3.

Close Scope n_demo_scope.

Fail Check (1 +* 2).
```

repl 实测输出：

```
(1 +* 2)%nd
     : nat
...
1 +* 2 +* 3
     : nat
...
The command has indeed failed with message:
Unknown interpretation for notation "_ +* _".
This notation is available in n_demo_scope.
```

- `%nd` 限定符：一次性把整个子表达式放进作用域——`((1 +* 2))%nd`。
- `Open Scope` 之后裸写 `1 +* 2 +* 3`；`Example` 验证左结合：`1 +* 2 +* 3` 解析为
  `(1 +* 2) +* 3 = addmul (addmul 1 2) 3 = 3 + 3*3 = 12`（`reflexivity` 直接算）。
- `Close Scope` 之后再裸写，报 `Unknown interpretation ... This notation is available
  in n_demo_scope`——**报错信息会告诉你记号在哪个作用域里**，这是排错的第一线索
  （坑清单第 3 条）。

顺手做 40 章会撞上的那个"作用域抢符"实验：

```coq
Fail Check nat * nat.

Check (nat * nat)%type.
```

repl 实测：

```
The command has indeed failed with message:
The term "nat" has type "Set" while it is expected to have type "nat".

(nat * nat)%type
     : Set
```

`nat_scope` 的 `*`（`Nat.mul`，`Require Import Arith` 时打开）在类型位置也生效，把
两个类型当数字乘；`%type` 把解析切回 `type_scope`，`*` 恢复成 `prod`。这不是
com_scope 干的——我们的 com 记号还没定义——纯粹是两个标准作用域打架（40 章坑 1 的
最小复现）。

### 37.3 自定义条目 com 与三层抬进记号

主战场。`Declare Custom Entry com` 开一块**语法特区**：特区内可以重新定义 `+ - *`
等运算符的归属与优先级，不影响外面。先声明条目和作用域，再放**四层**记号：

```coq
(* ---------- 37.3 自定义条目 com 与三层抬进记号 ---------- *)

Declare Custom Entry com.
Declare Scope com_scope.

Notation "<{ e }>" := e
  (e custom com, format "'[hv' <{ '/  ' '[v' e ']' '/' }> ']'") : com_scope.

Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).

Notation "f x .. y" := (.. (f x) .. y)
                  (in custom com at level 0, only parsing,
                  f constr at level 0, x constr at level 1,
                      y constr at level 1).

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

Definition example_aexp : aexp := <{ 3 + (X * 2) }>.
Definition example_bexp : bexp := <{ true && ~(X <= 4) }>.

Print example_aexp.
```

逐层拆这四层为什么缺一不可：

1. **抬进层** `<{ e }>`：`(e custom com, ...)` 声明 e 用 com 条目解析——这是特区和
   外部世界的唯一通道。`format` 子串控制**打印**时的换行排版。
2. **括号层** `( x )` at level 99：特区里的圆括号，允许用户手动改变优先级。
3. **裸变量层** `"x" := x (in custom com at level 0, x constr at level 0)`：没有它，
   `<{ X }>` 里的 `X` 无法被解析——特区不知道"一个标识符"长什么样。`x constr at
   level 0` 表示该位置按**主语法的 constr** 解析再抬进来（所以 37.1 的 coercion 和
   `!->` 记号在这里仍然可用）。
4. **应用抬进层** `"f x .. y"`：允许写 `<{ subtract_slowly_body }>`（38 章）这种
   **标识符应用到中缀表达式**的混合形式——`f` 是主语法的 constr，参数用特区记号。
   `only parsing` 表示不定义打印规则。

`Open Scope com_scope.` 之后，`Print example_aexp.` 实测输出：

```
example_aexp = <{3 + X * 2}>
     : aexp
```

注意打印时 3+(X*2) 被规整成 `3 + X * 2`——优先级（`*` 40 低于 `+` 50）让括号
冗余，printer 据此省略。**level 就是特区内的优先级表**，完整阶梯在 37.4。

### 37.4 命令记号与 level 阶梯：85 / 89 / 90 / 99

命令语法（38 章的 com）与五条命令记号：

```coq
(* ---------- 37.4 命令记号与 level 阶梯：85 / 89 / 90 / 99 ---------- *)

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'"  := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y"  := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85, no associativity,
    format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90,
    right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.
```

整张优先级表（数字越小结合越紧）：

| level | 记号 | 结合性 | 备注 |
|---|---|---|---|
| 0 | `skip` / `x := y` 的 x | — | 赋值整体在 level 0 但 RHS 在 85 |
| 40 | `*` | 左 | 乘最紧 |
| 50 | `+ -` | 左 | 加减 |
| 70 | `= <> <= >` | 无 | 比较——无结合！`a = b = c` 解析不了 |
| 75 | `~` | 右 | 非 |
| 80 | `&&` | 左 | 与 |
| 85 | 赋值右端 | — | 允许 RHS 是 70–80 的任何布尔/算术 |
| 89 | `if ... end` / `while ... end` | — | 语句级 |
| 90 | `;` | 右 | 序列最松——`c1; c2; c3` 右折 |
| 99 | 括号层 `( x )` / if·while 的子位 | — | 守卫与分支体 |

为什么 `:=` 的右端是 85 而不是 99？因为 90 的 `;` 要能把 `X := X - 1` 整个当左操作数
（`y at level 85` < 90 ✓），而 85 又高于比较 70——赋值右边可以放完整条件表达式。这个
数字不是拍脑袋，是把"谁能包含谁"倒过来编码。

repl 会为每条关键字记号打印 `Identifier 'if' now a keyword` 等——**这些词从此在全局
语法里被保留**（38 章坑清单里 `end` 的保留就是这里来的）。

两个"链"验证优先级设计：

```coq
Definition left_chain : aexp := <{ X - Y - Z }>.
Definition right_chain : com := <{ X := 1; Y := 2; Z := 3 }>.

Unset Printing Notations.
Print left_chain.
Print right_chain.
Set Printing Notations.
```

repl 实测（脱糖视图）：

```
left_chain = AMinus (AMinus X Y) Z
     : aexp

right_chain = CSeq (CAsgn X 1) (CSeq (CAsgn Y 2) (CAsgn Z 3))
     : com
```

`-` 左结合（`(X-Y)-Z`），`;` 右结合（`X := (1; Y := (2; Z := 3))` 的嵌套形状）。
**先设计 AST，再用 level + 结合性把语法钉进表**——读别人的记号工程时反过来：从
`Print` 的脱糖结果读出结合性。

两个真实程序（38 章还会见到）：

```coq
Definition subtract_slowly_body : com :=
  <{ Z := Z - 1 ;
     X := X - 1 }>.

Definition subtract_slowly : com :=
  <{ while X <> 0 do
       subtract_slowly_body
     end }>.
```

注意第二个：循环体是一个**标识符** `subtract_slowly_body`——这就是 37.3 第四层
`"f x .. y"` 记号的用武之地（整个 while 独占 89，体位在 99，标识符经应用抬进层进入）。

```coq
Definition fact_in_coq : com :=
  <{ Z := X;
     Y := 1;
     while Z <> 0 do
       Y := Y * Z;
       Z := Z - 1
     end }>.

Print fact_in_coq.
```

`Print` 实测（默认记号视图，`format` 的 `'v'` 控制竖排）：

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

### 37.5 语义小验：aeval / beval 与 reflexivity

记号只是皮，配上求值函数才能自检。与 38 章相同的两个 Fixpoint：

```coq
(* ---------- 37.5 语义小验：aeval / beval 与 reflexivity ---------- *)

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

Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).

Example aexp_demo : aeval (X !-> 5) <{ 3 + (X * 2) }> = 13.
Proof. reflexivity. Qed.

Example bexp_demo : beval (X !-> 5) <{ true && ~(X <= 4) }> = true.
Proof. reflexivity. Qed.
```

**match 的模式里可以直接写 `<{a1 + a2}>`**——记号在解析期展开成 `APlus a1 a2`，
对 match 来说和裸构造子模式等价。两个 Example 用 `reflexivity` 一行验证记号 +
coercion + 语义三层协同无误（`X !-> 5` 是 33 章的 `t_update` 记号在**主语法**里，
`<{ ... }>` 在特区里，两层记号在同一行混用）。

### 37.6 Locate 与脱糖三件套

读记号工程的三个工具。**脱糖三件套**（逐层剥开打印）：

```coq
(* ---------- 37.6 Locate 与脱糖三件套 ---------- *)

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

对 `example_bexp := <{ true && ~(X <= 4) }>`，四层视图的实测输出：

| 开关 | 输出 | 看到什么 |
|---|---|---|
| 默认 | `<{true && ~ X <= 4}>` | 用户语法 |
| `Unset Printing Notations` | `BAnd BTrue (BNot (BLe X 4))` | 纯构造子（但 X、4 仍是脱糖的） |
| `+ Set Printing Coercions` | `<{true && ~ (AId X) <= (ANum 4)}>` | coercion 显形 |
| `Set Printing All` | `BAnd BTrue (BNot (BLe (AId X) (ANum (S (S (S (S O)))))))` | 全脱——连 `4` 都展开成 `S (S (S (S O)))` |

`fact_in_coq` 在 coercion 视图下同样把每个变量和字面量标出 `(AId X)`/`(ANum 1)`。
**调试记号问题时按这个顺序剥**：默认 → 去记号 → 去 coercion → All。

**Locate**：问"这个记号/标识符是谁"：

```coq
Locate aexp.
Locate "+*".
Locate "&&".
Locate ";".
Locate "while".
Locate "true".
```

实测输出（节选）：

```
Inductive Top.Ex37Notation.aexp

Notation "a '+*' b" := (addmul a b)
  (* a in scope _nat_scope, b in scope _nat_scope *) : n_demo_scope

Notation "x && y" := (BAnd x y) (default interpretation)
Notation "x && y" := (andb x y)
  (* x in scope _bool_scope, y in scope _bool_scope *) : bool_scope

Notation "x ; y" := (CSeq x y) : com_scope (default interpretation)
Notation "x '!->' v ';' m" := (t_update m x v) ...
Notation "[ x ; y ; .. ; z ]" := (cons x ...) : list_scope

Notation "'while' x 'do' y 'end'" := (CWhile x y) : com_scope

Notation "'true'" := BTrue (default interpretation)
```

信息量很大：`&&` 有**两条**解释（特区内是 BAnd、主语法 bool_scope 里是 andb），
`;` 有三条（CSeq、t_update、cons）。`(default interpretation)` 标出当前作用域栈下
裸写会命中哪条。**记住：记号查找按作用域栈从顶到底，Locate 是唯一权威**。

### 37.7 assn 自定义条目：把同一套机制再造一遍

最有说服力的练习：换一个语义域（霍尔逻辑的断言），把 37.3–37.4 的机制**完整再造**。
目标是写 `{{ X = 3 \/ X <= Y }}` 这样"点式"的断言——它的本体是一个
`state -> Prop` 函数。

基础类型与三个 coercion（比 37.1 的难：要把 `Prop`、`nat`、`aexp` 都抬成函数）：

```coq
(* ---------- 37.7 assn 自定义条目：把同一套机制再造一遍 ---------- *)

Definition Assertion := state -> Prop.
Definition Aexp := state -> nat.

Definition assert_of_Prop (P : Prop) : Assertion := fun _ => P.
Definition Aexp_of_nat (n : nat) : Aexp := fun _ => n.
Definition Aexp_of_aexp (a : aexp) : Aexp := fun st => aeval st a.

Coercion assert_of_Prop : Sortclass >-> Assertion.
Coercion Aexp_of_nat : nat >-> Aexp.
Coercion Aexp_of_aexp : aexp >-> Aexp.

Arguments assert_of_Prop /.
Arguments Aexp_of_nat /.
Arguments Aexp_of_aexp /.
```

三行 `Arguments ... /.` 让 coercion **不可展开地透传**（打印时保持 `True` 而不是
`assert_of_Prop True`）——没有这三行，后面的 `Print` 会满屏包装函数。

然后是 `assn` 条目本体。注意三处与 com 条目的**设计差异**：

```coq
Declare Custom Entry assn.
Declare Scope assertion_scope.
Bind Scope assertion_scope with Assertion.
Bind Scope assertion_scope with Aexp.
Delimit Scope assertion_scope with assertion.

Notation "# f x .. y" := (fun st => (.. (f ((x:Aexp) st)) .. ((y:Aexp) st)))
                  (in custom assn at level 2,
                  f constr at level 0, x custom assn at level 1,
                  y custom assn at level 1) : assertion_scope.
```

1. **`Bind Scope ... with 类型`**：把作用域绑到类型上——凡是 `Assertion`/`Aexp` 类型的
   位置，解析器自动进入 assertion_scope。com 条目没这么做（它靠 `<{ }>` 显式抬进）。
2. `# f x .. y`：把主语法的**函数** `f` 应用到特区内的 `Aexp` 序列，整体点式化——
   这就是 `{{ #Nat.add X Y > #max Y X }}` 的来源。
3. level 阶梯重排：断言世界里 `= <= <` 是 70、`\/` 85、`/\` 80、`->` 99——照搬
   Coq 主语法的优先级习惯，让断言读起来像普通命题。

```coq
Notation "P -> Q" := (fun st => (P:Assertion) st -> (Q:Assertion) st) (in custom assn at level 99, right associativity) : assertion_scope.
Notation "P <-> Q" := (fun st => (P:Assertion) st <-> (Q:Assertion) st) (in custom assn at level 95) : assertion_scope.
Notation "P \/ Q" := (fun st => (P:Assertion) st \/ (Q:Assertion) st) (in custom assn at level 85, right associativity) : assertion_scope.
Notation "P /\ Q" := (fun st => (P:Assertion) st /\ (Q:Assertion) st) (in custom assn at level 80, right associativity) : assertion_scope.
Notation "~ P" := (fun st => ~ ((P:Assertion) st)) (in custom assn at level 75, right associativity) : assertion_scope.
Notation "a = b" := (fun st => (a:Aexp) st = (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a <> b" := (fun st => (a:Aexp) st <> (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a <= b" := (fun st => (a:Aexp) st <= (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a < b" := (fun st => (a:Aexp) st < (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a >= b" := (fun st => (a:Aexp) st >= (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "a > b" := (fun st => (a:Aexp) st > (b:Aexp) st) (in custom assn at level 70) : assertion_scope.
Notation "'True'" := (fun st => True) (in custom assn at level 0) : assertion_scope.
Notation "'False'" := (fun st => False) (in custom assn at level 0) : assertion_scope.

Notation "a + b" := (fun st => (a:Aexp) st + (b:Aexp) st) (in custom assn at level 50, left associativity) : assertion_scope.
Notation "a - b" := (fun st => (a:Aexp) st - (b:Aexp) st) (in custom assn at level 50, left associativity) : assertion_scope.
Notation "a * b" := (fun st => (a:Aexp) st * (b:Aexp) st) (in custom assn at level 40, left associativity) : assertion_scope.

Notation "( x )" := x (in custom assn at level 0, x at level 99) : assertion_scope.

Notation "$ f" := f (in custom assn at level 0, f constr at level 0) : assertion_scope.
Notation "x" := x (in custom assn at level 0, x constr at level 0) : assertion_scope.
```

每个 RHS 都是 `fun st => ...`——**记号的展开结果就是断言函数本身**，`(a:Aexp)` 的
类型标注在解析时触发 coercion。`$ f` 是"逃逸舱"：让任意主语法项（比如带量词的
复杂谓词）直接进入断言位置。抬进层换成了双花括号：

```coq
Declare Scope hoare_spec_scope.
Open Scope hoare_spec_scope.

Notation "{{ e }}" := e (at level 2, e custom assn at level 99) : assertion_scope.
Open Scope assertion_scope.
```

`{{ e }}` 与 com 条目的 `<{ e }>` 完全同构——**这就是"再造一遍"的意思**：同一个模式，
换 token、换条目、换类型。十条断言验证表达力（从平凡到量词）：

```coq
Definition assertion1 : Assertion := {{ X = 3 }}.
Definition assertion2 : Assertion := {{ True }}.
Definition assertion3 : Assertion := {{ False }}.
Definition assertion4 : Assertion := {{ True \/ False }}.
Definition assertion5 : Assertion := {{ X <= Y }}.
Definition assertion6 : Assertion := {{ X = 3 \/ X <= Y }}.
Definition assertion7 : Assertion := {{ Z = (#max X Y) }}.
Definition assertion8 : Assertion := {{ Z * Z <= X
                                        /\  ~ (((#S Z) * (#S Z)) <= X) }}.
Definition assertion9 : Assertion := {{ #Nat.add X Y > #max Y X }}.
Definition assertion10 : Assertion := {{ $(fun st => forall w, st w = st w) }}.

Print assertion8.
Print assertion10.
```

`Print assertion8.` 实测：

```
assertion8 = {{Z * Z <= X /\ ~ # S Z * # S Z <= X}}
     : Assertion
```

括号被优先级吸收、`#S Z` 保持应用抬进形。`Print assertion10.` 则显示 `$` 逃逸舱
原样透传：

```
assertion10 =
fun st : state => forall w : string, st w = st w
     : Assertion
```

最后是 43 章的三件语义装备在漂亮记号下的样子：

```coq
Definition assert_implies (P Q : Assertion) : Prop :=
  forall st, P st -> Q st.

Notation "P ->> Q" := (assert_implies P Q)
                        (at level 80) : hoare_spec_scope.

Notation "P <<->> Q" := ((P ->> Q) /\ (Q ->> P))
                          (at level 80) : hoare_spec_scope.
```

注意 `<<->>` 的 RHS 写成了 `(P ->> Q) /\ (Q ->> P)`——两个记号同为 level 80，不加
括号会触发解析容忍警告（实测 `Warning: In term, tolerating this expression at a
higher level than expected ...`，43 章坑 3 的同款；本文件的第一版就踩过，修正后
收进坑清单第 6 条）。

```coq
Definition assertion_sub X (a : aexp) (P : Assertion) : Assertion :=
  fun (st : state) => P (X !-> (aeval st a); st).

Notation "P [ X |-> a ]" := (assertion_sub X a P)
                              (in custom assn at level 10, left associativity,
                               P custom assn, X global, a custom com)
                          : assertion_scope.

Example equivalent_assertion1 :
  {{ (X <= 5) [X |-> 3] }} <<->> {{ 3 <= 5 }}.
Proof.
  split; unfold assert_implies, assertion_sub; intros st H;
  simpl in *; apply H.
Qed.

Example equivalent_assertion2 :
  {{ (X <= 5) [X |-> X + 1] }} <<->> {{ (X + 1) <= 5 }}.
Proof.
  split; unfold assert_implies, assertion_sub; intros st H;
  simpl in *; apply H.
Qed.
```

`P [ X |-> a ]` 是**跨条目记号**：P 用 assn 条目、a 用 com 条目、X 是主语法全局
（`X global`）——一个记号里三个语法域协同。两个等价性例子把 43.5 的
`assertion_sub` 语义（"在更新过的状态里求值 P"）与直觉的文本替换对上：两边都是
`split; unfold ...; intros; simpl; apply H` 一气呵成。

### 37.8 反例集：Fail 抓得住的四类错

```coq
(* ---------- 37.8 反例集：Fail 抓得住的四类错 ---------- *)

Fail Definition mix_type : aexp := <{ true }>.
Fail Definition mix_level : com := <{ X + 1 }>.
Fail Definition bad_subst : Assertion := {{ (X <= 5) [X |-> true] }}.
```

repl 实测的三条报错：

```
The command has indeed failed with message:
The term "<{true}>" has type "bexp" while it is expected to have type "aexp".

The command has indeed failed with message:
The term "<{X + 1}>" has type "aexp" while it is expected to have type "com".

The command has indeed failed with message:
The term "<{true}>" has type "bexp" while it is expected to have type "aexp".
```

- `mix_type`：特区里 `true` 造出 bexp，塞不进 aexp——**类型域由类型标注决定**，
  记号不越权。
- `mix_level`：`X + 1` 是 aexp；哪怕你"觉得"它像个命令，com 要 CSkip/CAsgn/…。
  level 只管**怎么折**，不管**是什么**。
- `bad_subst`：替换的目标位 `a` 用 com 条目解析（`a custom com`），`true` 在 com 里
  是 BTrue（bexp）——而 `assertion_sub` 的 a 位要 aexp。跨条目记号每个位置的类型
  都要喂对。

第四类：作用域。`Close Scope com_scope.` 之后再写 `<{ }>`：

```coq
Close Scope com_scope.
Fail Definition scope_needed : aexp := <{ X + 1 }>.
Open Scope com_scope.
```

实测报错：

```
The command has indeed failed with message:
Unknown interpretation for notation "<{ _ }>".
This notation is available in com_scope.
```

与 37.2 的 `+*` 同款——**记号定义在作用域里，作用域不开就找不到**。39 章坑 1
（`Open Scope` 放错位置导致 `aeval` 里的 `<{a1 + a2}>` 解析失败）就是这一类错误的
实战版。

```coq
End Ex37Notation.
```

### 37.9 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到（报错文本来自
`rocq repl -q < build/examples/ex_37_notation.v`）。

1. **coercion 是单向、且不改原类型**（37.1）：`Check X.` 仍打印 `X : string`；反向
   `Fail Definition wrong_way : nat := AId X.` 报
   `The term "AId X" has type "aexp" while it is expected to have type "nat".`
   要反向再声明一条 `Coercion f : aexp >-> nat`（且真的有那个函数）。
2. **两条 coercion 声明的顺序无关，但生效要早于使用**（37.1）：`no_coercion_pair` 在
   声明前 `Fail`，声明后 `sugar_aexp` 直接合法——coercion 是全局注册表，插入发生在
   elaboration 时。
3. **自定义记号必须在作用域里，且报错会告诉你作用域名**（37.2/37.8）：
   `Unknown interpretation for notation "_ +* _". This notation is available in
   n_demo_scope.`——看到这句就 `Open Scope` 或加 `%nd` 限定，别去改记号定义。
4. **`nat * nat` 在类型位置被解析成 Nat.mul**（37.2）：nat_scope 的 `*` 压过
   type_scope 的 `prod`，报
   `The term "nat" has type "Set" while it is expected to have type "nat".`
   类型乘积写 `(A * B)%type`。与 com_scope 无关（做该实验时 com 记号尚未定义）。
5. **level 只管折叠、不管类型**（37.8）：`X + 1` 写得再像命令也只是 aexp；
   `<{ true }>` 塞进 aexp 位直接类型错。三层（aexp/bexp/com）各管各的记号。
6. **同 level 记号嵌套要加括号**（37.7）：`P <<->> Q` 的 RHS 不加括号触发
   `Warning: In term, tolerating this expression at a higher level than expected
   by the notation continuing on the right`——写成 `(P ->> Q) /\ (Q ->> P)` 消除
   （本文件第一版实测踩过）。
7. **关键字被记号永久保留**（37.4）：repl 逐条打印 `Identifier 'if' now a keyword`、
   `'end' now a keyword` 等——之后全局都不能再用这些词当标识符（38 章起 `end` 的
   保留贯穿全书）。
8. **`Arguments ... /.` 是断言打印可读性的命门**（37.7）：没有它，`{{ True }}` 打印成
   `{{assert_of_Prop True}}` 满屏包装。自定义 coercion 配套的透传声明别忘。
9. **`Bind Scope` 与 `Open Scope` 的分工**（37.7）：`Bind Scope assertion_scope with
   Assertion` 让类型驱动的位置自动进作用域；但写裸断言（不在类型标注下）仍要
   `Open Scope assertion_scope`。com 条目只用 `<{ }>` 抬进而没 Bind——两种设计都
   成立，选一种并保持一致。
10. **跨条目记号的每个位置各归各的语法域**（37.7）：`P [ X |-> a ]` 里 P 走 assn、
    a 走 com、X 是主语法全局——`Fail` 的 `bad_subst`（把 bexp 塞进 a 位）就是喂错
    域的实例。写跨条目记号时给每个位置标 `custom 条目` 或 `constr`，别留默认。
11. **警告家族要认脸**（全书）：`level-0-notation-not-closed`（`x := y`，level 0 但
    首尾非终结符）、`closed-notation-not-level-0`（`if ... end`、`{{ }}` 首尾终结但
    不在 level 0）是**这类 DSL 记号的固有代价**，全文件 7 条 Warning 属常态，不是
    待修 bug。
12. **`Fail` 的文本只活在 repl**（37.8）：本章引用的全部报错都在
    `rocq repl -q < ex_37_notation.v` 里抓取；`rocq compile` 对通过/失败的 `Fail`
    都只字不提。

---
上一章：[36 · 关系、闭包与确定性](36-relations.md) ｜ 下一章：[38 · Imp：状态、命令与大步语义](38-imp-semantics.md) ｜ 返回：[README](../README.md)
