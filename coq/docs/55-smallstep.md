# 55 · 小步语义：执行即关系

对应示例：`../examples/55_smallstep.v`（`Module Ex55Smallstep`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

53 章的 `ceval` 是**大步**语义：一条规则直接说"这串命令从这个状态跑到那个状态"，中间过程
整个被吞掉。54 章的燃料求值器把"跑"变成了函数，但也是一口气跑完。两者都回答不了这样
的问题：

- 程序跑到第 7 步时**停在哪里**？（调试器、单步执行）
- 两个程序**交错**执行时怎么描述？（并发、调度）
- "执行了一步"本身能不能成为一个**可归纳的数据结构**？

本章引入**小步语义**（small-step semantics）：把"执行"切成原子动作，定义一个一步关系
`step`，一个配置（命令 + 状态）走一步变成另一个配置。整段执行就是 `step` 的**自反传递
闭包**——也就是 51 章 `star` 的用武之地。然后我们证明本章的主定理：

> `st =[ c ]=> st'` **当且仅当** `(c, st)` 多步走到 `(skip, st')`。

大步和小步**是同一种语义的两种写法**。这个等价性不是显然的：一个方向要把一棵大推导树
摊平成一串小步，另一个方向要把一串小步重新折叠成推导树。证明完它，53 章对 `loop`
发散的证明直接免费搬运到小步世界上。

最后我们把 `multi`（本章用的闭包）和 51 章的 `star` 证明等价，前后章节在这里会合。

### 55.1 语言与大步语义的副本（同 38/54 章）

示例文件自包含，语言层与 38/54 章逐字相同。文件头（本章**不需要** `Lia`，54 章的单调性
引理不在本章）：

```coq
(* 40 小步语义：执行即关系 —— step / multi / 与大步语义 ceval 的等价 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex55Smallstep.

(* ---------- 55.1 语言与大步语义的副本（同 38/54 章） ---------- *)

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

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.

Declare Custom Entry com.
Declare Scope com_scope.
```

三条抬进记号与表达式记号，照抄 53.3：

```coq
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

`Open Scope com_scope.` 依旧放在第一次使用 `<{ }>` 之前（54 章坑清单第 1 条）。命令语法、
`loop`、`ceval` 七条规则：

```coq
Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).

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
  (in custom com at level 90, right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.

Definition loop : com :=
  <{ while true do
       skip
     end }>.
```

```coq
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

repl 会打印：

```
ceval is defined
ceval_ind is defined
ceval_sind is defined
```

再带上 53.10 手推过的那个例子——55.7 我们要让**同一段推导**直接变成一条小步运行轨迹：

```coq
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

### 55.2 配置与一步关系 step

小步语义的基本对象不是"命令"，而是**配置**（configuration）：**还没跑完的命令 + 当前
状态**。执行一步，就是把配置改写一次：

```coq
(* ---------- 55.2 配置与一步关系 step ---------- *)

Definition config := (com * state)%type.
```

注意 `(com * state)%type` 这个写法。我一开始写的是 `Definition config := com * state.`，
编译器报：

```
Error: The term "com" has type "Set" while it is expected to have type "nat".
```

原因不是 `com_scope`——53 章那批 `+ - *` 记号只声明在自定义条目 `com` **内部**，不会
跑到全局。真凶是 **nat_scope 的 `Nat.mul` 抢了 type_scope 的 `prod`**：文件开头
`Require Import Arith` 打开了 nat_scope（比 type_scope 晚入栈，优先级更高），于是 `*`
在类型位置也被解释成 `Nat.mul`，Coq 开始要求两个操作数是 `nat`。用一个最小实验验证
（与 com 完全无关）：

```
From Stdlib Require Import Arith.
Definition A := nat * nat.
```

报的正是同款错误：

```
Error: The term "nat" has type "Set" while it is expected to have type "nat".
```

`%type` 把这个子式的记号解析切回 `type_scope`，`*` 重新解释成 `prod`。坑清单第 1 条。

一步关系 `step`，六条规则：

```coq
Reserved Notation "p '-->' q" (at level 40).

Inductive step : config -> config -> Prop :=
  | ST_Ass : forall st x a,
      (<{ x := a }>, st) --> (<{ skip }>, (x !-> aeval st a ; st))
  | ST_SkipSeq : forall st c2,
      (<{ skip ; c2 }>, st) --> (c2, st)
  | ST_SeqStep : forall c1 c1' c2 st st',
      (c1, st) --> (c1', st') ->
      (<{ c1 ; c2 }>, st) --> (<{ c1' ; c2 }>, st')
  | ST_IfTrue : forall b st c1 c2,
      beval st b = true ->
      (<{ if b then c1 else c2 end }>, st) --> (c1, st)
  | ST_IfFalse : forall b st c1 c2,
      beval st b = false ->
      (<{ if b then c1 else c2 end }>, st) --> (c2, st)
  | ST_While : forall b c st,
      (<{ while b do c end }>, st)
      --> (<{ if b then (c ; while b do c end) else skip end }>, st)

  where "p --> q" := (step p q).
```

repl 打印：

```
step is defined
step_ind is defined
```

逐条读这六条规则，注意它们和大步版本的**分工差异**：

- **`ST_Ass`**：赋值一步完成——求值 `a`、更新状态、命令变成 `skip`。注意**命令不会消失**，
  而是变成 `skip` 表示"这段已经跑完了"。这是小步语义的标准处理：终止配置是
  `(skip, 最终状态)`，程序"停机"的标志是命令变成 skip。表达式 `a` 这里一步算完
  （`aeval st a`）；把表达式也拆成小步是原书 PLF 卷 Smallstep 章的路线，本章聚焦命令层，
  62 章在 λ 演算里再遇到"表达式也要小步"的情形。
- **`ST_SkipSeq`**：`skip` 在序列开头是"胶水"，一步把它扔掉。
- **`ST_SeqStep`**：序列的第一段走一步，第二段**原地不动**。这条是并发交错语义的入口——
  想让两个线程交错，只需在两边的 `ST_SeqStep` 之间做选择。
- **`ST_IfTrue` / `ST_IfFalse`**：条件一步选中分支，`if` 外壳消失。
- **`ST_While`**：循环**不动**，一步展开成 `if`。真正的迭代发生在展开后的 `if` 选中
  `c ; while ...` 之后。这条规则是纯语法改写（连状态都不看），它让 `while` 的行为完全由
  `if` 和 `;` 组合出来——小步语义的一个美学优点：**规则更少、更正交**。

对比大步 `ceval` 的七条：`E_WhileTrue` 里有递归（要求"剩余循环也跑完"），而 `ST_While`
没有任何递归——所有"跑完"的结构都推给了闭包。

### 55.3 三个单步示例

（其实是四个。）每条规则都配一个 `reflexivity`-级验证：

```coq
(* ---------- 55.3 三个单步示例 ---------- *)

Example step_ass_example :
  (<{ X := X + 1 }>, empty_st) --> (<{ skip }>, X !-> 1).
Proof. apply ST_Ass. Qed.

Example step_seq_skip :
  (<{ skip ; X := 1 }>, empty_st) --> (<{ X := 1 }>, empty_st).
Proof. apply ST_SkipSeq. Qed.

Example step_if_example :
  (<{ if X <= 1 then Y := 3 else Z := 4 end }>, X !-> 5)
  --> (<{ Z := 4 }>, X !-> 5).
Proof. apply ST_IfFalse. reflexivity. Qed.

Example step_while_unfold :
  (<{ while X <> 0 do X := X - 1 end }>, X !-> 3)
  --> (<{ if X <> 0 then (X := X - 1 ;
                          while X <> 0 do X := X - 1 end)
                    else skip end }>, X !-> 3).
Proof. apply ST_While. Qed.
```

- `step_ass_example`：`aeval empty_st <{X + 1}>` 算出 `0 + 1 = 1`，目标里的 `X !-> 1`
  靠转换检查过关——这里 RHS 的表达式**在证明时被求值**，和 54 章燃料例子里"必须写全
  历史"是同一个机制。
- `step_seq_skip`：skip 被扔掉，状态不动。
- `step_if_example`：先 `apply ST_IfFalse` 留下子目标 `beval (X !-> 5) <{X <= 1}> = false`，
  `5 <=? 1` 规约为 `false`，`reflexivity` 过。
- `step_while_unfold`：`ST_While` 的结论和目标**逐字符**对应（注意目标里循环体
  `(X := X - 1 ; while ...)` 要加括号——`;` 是右结合，不加括号会解析错）。`apply` 直接过，
  连子目标都没有。

### 55.4 multi：从一步到多步

单步关系本身描述不了"跑完"。我们需要 `step` 的**自反传递闭包**。本章用"步数累积"式的
定义（PLF 卷的标准写法）：

```coq
(* ---------- 55.4 multi：从一步到多步 ---------- *)

Inductive multi {X : Type} (R : X -> X -> Prop) : X -> X -> Prop :=
  | multi_refl : forall (x : X), multi R x x
  | multi_step : forall (x y z : X),
      R x y ->
      multi R y z ->
      multi R x z.
```

两条构造子的含义：

- `multi_refl`：零步也算——闭包是**自反**的。
- `multi_step`：走一步 `R x y`，再从 `y` 多步到 `z`。**递归在第二个前提上**，所以
  `multi R x z` 的推导树天然按"第一步在最外面"组织，写"运行轨迹"时从左往右读就是
  执行顺序。

它对任意关系 `R` 都成立（`{X} (R : X -> X -> Prop)` 是参数），本章拿来实例化成
`multi step`，并配一个记号：

```coq
Notation "p '-->*' q" := (multi step p q) (at level 40).
```

手工跑一遍两条赋值的序列，体会"轨迹"怎么写：

```coq
Example multi_seq_manual :
  (<{ X := 1 ; Y := 2 }>, empty_st)
  -->* (<{ skip }>, (Y !-> 2 ; X !-> 1)).
Proof.
  eapply multi_step.
  - apply ST_SeqStep. apply ST_Ass.
  - eapply multi_step.
    + apply ST_SkipSeq.
    + eapply multi_step.
      * apply ST_Ass.
      * apply multi_refl.
Qed.
```

读这个证明树：四步动作依次是

1. `ST_SeqStep` + `ST_Ass`：第一段 `X := 1` 完成，配置变成
   `(<{ skip ; Y := 2 }>, X !-> 1)`；
2. `ST_SkipSeq`：扔掉 skip，变成 `(<{ Y := 2 }>, X !-> 1)`；
3. `ST_Ass`：完成 `Y := 2`，变成 `(<{ skip }>, Y !-> 2 ; X !-> 1)`；
4. `multi_refl`：停机配置就是目标，收工。

`eapply multi_step` 只提供一个端点，另一个留成 evar 由下一步统一——这是写 multi 链的
标准姿势。

### 55.5 两条 multi 引理：传递与同态

等价性证明要两条基础设施。第一条：闭包的传递性（`multi` 拼接）。

```coq
(* ---------- 55.5 两条 multi 引理：传递与同态 ---------- *)

Lemma multi_trans : forall (X : Type) (R : X -> X -> Prop) x y z,
  multi R x y ->
  multi R y z ->
  multi R x z.
Proof.
  intros X R x y z Hxy. revert z.
  induction Hxy as [ x | x y' z' Hxy' Hyz IH ]; intros z Hz.
  - exact Hz.
  - eapply multi_step.
    + exact Hxy'.
    + apply IH. exact Hz.
Qed.
```

结构：`revert z` 让 IH 对任意终点成立（不然 IH 钉死在 `z'` 上，第二步接不上去）；归纳
两种情况分别是"零步：直接用第二段"和"一步：第一步放外面，尾巴交给 IH"。这和 51 章
`rsc_trans` 的证明同构。

第二条是**序列同态**：如果 `c1` 能多步跑完（到 skip），那么 `c1 ; c2` 能多步跑到
`skip ; c2` 的下一步 `c2`。

```coq
Lemma seq_multi : forall p q c2,
  multi step p q ->
  multi step (<{ (fst p) ; c2 }>, snd p) (<{ (fst q) ; c2 }>, snd q).
Proof.
  intros p q c2 H. induction H as [ x | x y z Hxy Hyz IH ].
  - apply multi_refl.
  - destruct x as [c st]. destruct y as [c' st']. destruct z as [c'' st''].
    eapply multi_step.
    + apply ST_SeqStep. exact Hxy.
    + exact IH.
Qed.
```

**为什么陈述写成 `forall p q` + `fst/snd`，而不是直观的 `forall c1 c1' st st'`？** 我第一版
就是直观写法：

```coq
Lemma seq_multi : forall c1 c1' st st' c2,
  multi step (c1, st) (c1', st') ->
  multi step (<{ c1 ; c2 }>, st) (<{ c1' ; c2 }>, st').
```

对假设 `multi step (c1, st) (c1', st')` 做 `induction` 时，它的两个索引是**复合项**
`(c1, st)`——Coq 不会自动把 `c1`、`st` 抽象成归纳变量，于是归纳分支里它们被钉死，
`multi_refl` 分支的目标变成"证明 `(<{c1;c2}>, st)` 多步到 `(<{c1';c2}>, st')`"，编译器
报：

```
Unable to unify "(<{c1'; c2}>, st')" with "(<{c1; c2}>, st)".
```

把端点写成**裸变量** `p q`（pair 整体是变量，可以被归纳抽象），分支里再 `destruct`
拆出 `c st` 等分量，归纳立刻顺畅。这是"对索引归纳前先想清楚什么能被抽象"的又一次
实战——和 54.8 的 `generalize dependent` 三连、54.9 的"先归纳后 intro"同属一个家族。
坑清单第 2 条。

证明体读法：

- `multi_refl` 分支：`p = q`，两端相同，`multi_refl` 收尾。
- `multi_step` 分支：`destruct` 把三个配置拆成 `(c, st)`、`(c', st')`、`(c'', st'')`，
  `ST_SeqStep` 把 `Hxy` 这一步**抬进序列**，剩下的多步交给 IH——IH 的形状现在和目标
  完全一致（因为我们陈述时用了 `p q`），`exact IH` 直接命中。

### 55.6 step 的确定性

一步关系是不是确定的？——同一配置会不会有两条不同的下一步？直观上会担心 `ST_IfTrue`
和 `ST_IfFalse` 打架，其实 `beval` 的值保证了互斥。

```coq
(* ---------- 55.6 step 的确定性 ---------- *)

Theorem step_deterministic : forall p p1 p2,
  p --> p1 ->
  p --> p2 ->
  p1 = p2.
Proof.
  intros p p1 p2 H1. revert p2.
  induction H1 as [ st x a
                 | st c2
                 | c1 c1' c2 st st' Hs IH
                 | b st c1 c2 Hb
                 | b st c1 c2 Hb
                 | b c st ];
    intros p2 H2; inversion H2; subst; try congruence.
  - (* ST_SkipSeq 对 ST_SeqStep：skip 没有下一步 *)
    match goal with H : step (CSkip, _) _ |- _ => inversion H end.
  - (* ST_SeqStep 对 ST_SkipSeq：skip 没有下一步 *)
    inversion Hs.
  - (* ST_SeqStep 对 ST_SeqStep：用 IH *)
    match goal with
    | H : step _ _ |- _ =>
        assert (E := IH _ H); injection E as E1 E2; subst; reflexivity
    end.
Qed.
```

同样用裸变量 `p p1 p2` 的陈述（不然 `induction` 又会被 pair 索引卡住）。骨架是熟悉的
"对第一条推导归纳、对第二条反演"。六条构造子两两组合，绝大多数被
`inversion H2; subst; try congruence` 一行吃掉——`congruence` 负责那些"两边推出的
配置字面相同"（如 `ST_Ass` 对 `ST_Ass`）和"条件值矛盾"（`ST_IfTrue` 对 `ST_IfFalse`：
一边 `beval st b = true` 一边 `= false`，congruence 直接发现矛盾）。**实测**（`Show` 探针）
只剩 3 个目标：

1. `ST_SkipSeq`（第一条）对 `ST_SeqStep`（第二条）：反演第二条会得到"skip 还能再走
   一步"的假设。反演产生的假设名不稳定（这次叫 `H4`），所以用
   `match goal with H : step (CSkip, _) _ |- _ => inversion H end`——按**形状**找"源配置
   是 skip 的一步"，反演它直接零分支（六条构造子的源都不是纯 skip），目标关闭。
2. 反过来的组合：这里用 `inversion Hs`——`Hs` 是**我们自己起的**归纳模式名（第一条推导
   的内层一步），名字稳定，直接反演。
3. `ST_SeqStep` 对 `ST_SeqStep`：两条内层一步同源，用 IH 合并。注意**不能**先
   `f_equal`——IH 证明的是**配置**相等 `(c1', st') = p2`，`f_equal` 把目标拆成 com/state
   两个分量等式后 IH 就对不上号了（实测报 `Unable to unify "(c1', st') = ?p2" with
   "<{c1'; c2}> = c2"`）。正确做法是先把 IH 应用到第二条内层一步上得到配置等式，再
   `injection` 拆出两个分量等式 `subst` 掉。

这段证明的两个教训（inversion 名字不稳定 → match by shape；f_equal 与 IH 的类型错配）
都进了坑清单（第 4、5 条）。

### 55.7 大步到小步：ceval__multi

现在证主定理的第一个方向：**大步推导树可以摊平成小步轨迹**。

```coq
(* ---------- 55.7 大步到小步：ceval__multi ---------- *)

Theorem ceval__multi : forall c st st',
  st =[ c ]=> st' ->
  multi step (c, st) (<{ skip }>, st').
Proof.
  intros c st st' Hce. induction Hce.
  - (* E_Skip *)
    apply multi_refl.
  - (* E_Asgn *)
    eapply multi_step.
    + apply ST_Ass.
    + rewrite H. apply multi_refl.
  - (* E_Seq *)
    eapply multi_trans.
    + apply (seq_multi (c1, st) (<{ skip }>, st') c2). exact IHHce1.
    + eapply multi_step.
      * apply ST_SkipSeq.
      * exact IHHce2.
  - (* E_IfTrue *)
    eapply multi_step.
    + apply ST_IfTrue. exact H.
    + exact IHHce.
  - (* E_IfFalse *)
    eapply multi_step.
    + apply ST_IfFalse. exact H.
    + exact IHHce.
  - (* E_WhileFalse *)
    eapply multi_step.
    + apply ST_While.
    + eapply multi_step.
      * apply ST_IfFalse. exact H.
      * apply multi_refl.
  - (* E_WhileTrue *)
    eapply multi_step.
    + apply ST_While.
    + eapply multi_step.
      * apply ST_IfTrue. exact H.
      * eapply multi_trans.
        -- apply (seq_multi (c, st) (<{ skip }>, st')
                     <{ while b do c end }>). exact IHHce1.
        -- eapply multi_step.
           ++ apply ST_SkipSeq.
           ++ exact IHHce2.
Qed.
```

逐分支读，每个分支就是"把大步规则翻译成一小段轨迹"：

- `E_Skip`：本来就停着，零步。
- `E_Asgn`：一步 `ST_Ass` 到 `(skip, x!->n;st)`。**注意 `rewrite H`**：`ST_Ass` 给出的
  状态是 `x !-> aeval st a ; st`，而目标里是 `x !-> n ; st`（`n` 是 E_Asgn 规则里的
  变量，`H : aeval st a = n`）。和 54.10 的 `E_Asgn` 完全同一个坑——`reflexivity` 不会
  自己用假设，先 `rewrite H` 把表达式换成值。
- `E_Seq`：三段拼起来——`seq_multi` 把第一段的轨迹抬进 `c1 ; c2`（抬完到达
  `(<{skip ; c2}>, st')`），再一步 `ST_SkipSeq` 到 `(c2, st')`，再接第二段的轨迹
  `IHHce2`。两段之间的粘合用 `multi_trans`。
- `E_IfTrue`/`E_IfFalse`：一步选中分支，接分支的轨迹。
- `E_WhileFalse`：两步——先 `ST_While` 展开成 if，再 `ST_IfFalse` 选中 skip，零步停机。
- `E_WhileTrue`：`ST_While` 展开、`ST_IfTrue` 选中 `c ; while ...`，然后**完全复用
  E_Seq 的模式**：`seq_multi` 抬体、`ST_SkipSeq`、接"剩余循环"的轨迹 `IHHce2`。

注意 `induction Hce` 在这里**不**需要 revert 任何东西：ceval 的索引（c、st、st'）都是
裸变量（关系的参数本来就是三个独立参数，不像 step 那样是 pair 索引），这就是为什么
53 章的 ceval 证明从来没有碰到 55.5 那种钉死问题。

定理立刻有回报——53 章手推的推导直接变成运行轨迹：

```coq
Example multi_example1 :
  (<{ X := 2;
      if (X <= 1)
        then Y := 3
        else Z := 4
      end }>, empty_st)
  -->* (<{ skip }>, (Z !-> 4 ; X !-> 2)).
Proof.
  apply ceval__multi. apply ceval_example1.
Qed.
```

两行：`ceval_example1`（55.1 里那棵手推树）+ `ceval__multi`。大步世界的证明**自动**变成
小步世界的运行。

### 55.8 小步到大步：step__ceval 与 multi__ceval

反方向更难：要把一串小步**折叠**回一棵推导树。分两层做。

**第一层：单步可吸收**。如果走了一步 `(c, st) --> (c', st')`，而剩下的部分从
`(c', st')` 大步跑完，那么原来从 `(c, st)` 就能大步跑完：

```coq
(* ---------- 55.8 小步到大步：step__ceval 与 multi__ceval ---------- *)

Lemma step__ceval : forall p p' st'',
  p --> p' ->
  snd p' =[ fst p' ]=> st'' ->
  snd p  =[ fst p  ]=> st''.
Proof.
  intros p p' st'' Hs. revert st''.
  induction Hs as [ st x a
                  | st c2
                  | c1 c1' c2 st st' Hs IH
                  | b st c1 c2 Hb
                  | b st c1 c2 Hb
                  | b c st ];
    intros st'' Hce.
  - (* ST_Ass：Hce 的命令是 skip，反演只有 E_Skip 一种 *)
    inversion Hce; subst. apply E_Asgn. reflexivity.
  - (* ST_SkipSeq：直接用 E_Seq 拼接，不反演 Hce *)
    apply E_Seq with st.
    + apply E_Skip.
    + exact Hce.
  - (* ST_SeqStep：Hce 的命令是 c1' ; c2，反演只有 E_Seq 一种 *)
    inversion Hce; subst.
    eapply E_Seq.
    + apply IH. eassumption.
    + eassumption.
  - (* ST_IfTrue *)
    apply E_IfTrue.
    + exact Hb.
    + exact Hce.
  - (* ST_IfFalse *)
    apply E_IfFalse.
    + exact Hb.
    + exact Hce.
  - (* ST_While：Hce 的命令是 if ...，反演出真假两种 *)
    inversion Hce; subst.
    + (* E_IfTrue：剥开 c ; while 后用 E_WhileTrue *)
      match goal with
      | H : ceval (CSeq _ _) _ _ |- _ => inversion H; subst
      end.
      eapply E_WhileTrue; eassumption.
    + (* E_IfFalse：剥开 skip 后用 E_WhileFalse *)
      match goal with
      | H : ceval CSkip _ _ |- _ => inversion H; subst
      end.
      eapply E_WhileFalse; eassumption.
Qed.
```

这份证明踩过的坑值得逐条讲，因为它们是**所有**"对小步关系归纳"的通用陷阱：

- **陈述又是 `p p'` + `fst/snd`**。原因同 55.5：`step` 的索引是 pair。差别是这次结论里
  命令和状态分处 `fst`/`snd` 之下——`apply`、`eassumption` 都能透过 `fst (c1, st)` ≡ `c1`
  的转换等价工作，所以不影响战术。
- **反演要看命令是不是具体构造子**。我最初的写法是对每个分支统一
  `inversion Hce; subst`，结果在 repl 里数出 **25 个目标**——因为像 `ST_SkipSeq` 分支里
  `Hce : st =[c2]=> st''` 的命令 `c2` 是**变量**，`inversion` 无法排除任何构造子，一下
  炸出 7 种情况；每个分支再来一次，目标总数爆炸。原则：

  - 命令**具体**（`ST_Ass` 的 skip、`ST_SeqStep` 的 `c1' ; c2`、`ST_While` 的 if）→ 反演
    只有一种构造子，安全；
  - 命令**抽象**（`ST_SkipSeq` 的 c2、`ST_IfTrue` 的 c1）→ **不要反演**，直接用目标规则
    拼接：`apply E_Seq with st. apply E_Skip. exact Hce.`（把 Hce 原封不动当第二段），
    或 `apply E_IfTrue. exact Hb. exact Hce.`。
- **`ST_While` 分支的两层反演**。第一层 `inversion Hce` 看到 `if` 外壳，分真假两种；
  第二层要再剥开剩余推导——真分支里是 `st =[c ; while ...]=> st''`（CSeq），假分支里是
  `st =[skip]=> st''`（CSkip）。这两层的假设名都来自 inversion（不稳定），所以用
  `match goal with H : ceval (CSeq _ _) _ _ |- _ => inversion H; subst end` 按形状定位。
  **注意 ceval 的参数顺序是（命令, 初态, 终态）**——我第一版把 `(CSeq _ _)` 写到了第二个
  参数位（状态位），match 永远失配，报 `No matching clauses for match`，坑清单第 6 条。
- 反演剥完后，`eapply E_WhileTrue; eassumption` 三连收尾：三个子目标（条件真、体跑完、
  剩余循环跑完）恰好对应上下文里三条假设，`eassumption` 按形状各取所需，完全不用管
  假设叫什么名字。

**第二层：对 multi 归纳**。把"单步可吸收"沿整条轨迹传播：

```coq
Theorem multi__ceval : forall q st',
  multi step q (<{ skip }>, st') ->
  snd q =[ fst q ]=> st'.
Proof.
  intros q st' H.
  remember (<{ skip }>, st') as r eqn:Hr.
  revert st' Hr.
  induction H as [ x | x y z Hxy Hyz IH ]; intros st' Hr.
  - (* multi_refl *)
    destruct x as [c st]. inversion Hr; subst. apply E_Skip.
  - (* multi_step *)
    destruct x as [c st]. destruct y as [c1 st1].
    apply (step__ceval (c, st) (c1, st1) st').
    + exact Hxy.
    + apply IH. exact Hr.
Qed.
```

- `remember` + `revert st' Hr`：终点 `(<{skip}>, st')` 在归纳里必须能变成任意中间配置，
  所以先把它抽象成 `r` 再把等式一起 revert——这是 53.12 `loop_never_stops` 里
  `remember ... eqn:` 手法的多目标版。
- `multi_refl` 分支：`x` 既是要跑的配置又是终点，`inversion Hr` 强制
  `x = (skip, st')`，`apply E_Skip` 收尾。
- `multi_step` 分支：一步 `Hxy` 把 `x=(c,st)` 带到 `y=(c1,st1)`，`step__ceval` 把"从
  `(c1,st1)` 大步跑完"（由 IH 对 `Hr` 提供）吸收成"从 `(c,st)` 大步跑完"。注意 IH 用了
  `apply IH. exact Hr.`——IH 的前提是 `z = (<{skip}>, st')`，正是 `Hr`。

### 55.9 等价定理：两种语义是一回事

两个方向合体：

```coq
(* ---------- 55.9 等价定理：两种语义是一回事 ---------- *)

Theorem ceval_iff_multi : forall c st st',
  st =[ c ]=> st'
  <-> multi step (c, st) (<{ skip }>, st').
Proof.
  intros c st st'. split.
  - apply ceval__multi.
  - intros H. apply (multi__ceval (c, st) st'). exact H.
Qed.
```

右方向要**显式**给 `multi__ceval` 提供配置 `(c, st)`——它的结论是 `snd q =[fst q]=> st'`
形状，让 `apply` 自己从目标 `st =[c]=> st'` 反解出 `q` 需要高阶模式匹配，会失败；
显式实例化 `(c, st)` 后转换检查负责对齐。

在文件末尾我们验证了它的公理依赖：

```coq
Print Assumptions ceval_iff_multi.
```

repl 输出：

```
Closed under the global context
```

零公理——等价性不依赖函数外延或经典逻辑。

这个定理的读法：**"程序停机"有一个不依赖语义风格的定义**——大步的"存在推导树"和小步的
"多步到达 skip 配置"互相蕴含。之后任何一种语义下证的性质，都可以 0 成本搬到另一种。

### 55.10 loop 的小步发散

53.12 证明了 `loop` 对大步语义发散（推导归纳 + remember 手法）。那个证明原样搬来：

```coq
(* ---------- 55.10 loop 的小步发散 ---------- *)

Theorem loop_never_stops : forall st st',
  ~(st =[ loop ]=> st').
Proof.
  intros st st' contra. unfold loop in contra.
  remember <{ while true do skip end }> as loopdef
           eqn:Heqloopdef.
  induction contra; inversion Heqloopdef.
  - rewrite H1 in H. discriminate H.
  - apply IHcontra2. rewrite H1, H2. reflexivity.
Qed.
```

（细节回顾：`remember` 把循环体冻结成 `loopdef`，`induction contra` 对推导归纳；
`E_WhileTrue` 分支的 IH 说"剩余循环不终止"，用它关闭；`E_WhileFalse` 分支与
`beval st true = false` 矛盾，`discriminate`。完整讲解在 53.12。）

然后是本章的回报时刻——**小步发散免费得到**：

```coq
Theorem loop_never_halts : forall st st',
  ~ multi step (loop, st) (<{ skip }>, st').
Proof.
  intros st st' H.
  apply multi__ceval in H.
  apply (loop_never_stops st st'). exact H.
Qed.
```

三行：假设 `loop` 能多步跑到停机配置，`multi__ceval` 把它折叠成大步推导，正好撞上
`loop_never_stops`。**不需要**对小步轨迹做任何归纳——等价定理已经把两个世界焊接好了。

直观上，`(loop, st)` 的唯一一步是 `ST_While` 展开成 `if true then (skip ; loop) else
skip end`，`ST_IfTrue` 选中 `skip ; loop`，`ST_SkipSeq` 又回到 `(loop, st)`——轨迹在
三个配置之间无限循环，永远到不了 skip。现在这个直观被定理封死。

### 55.11 与 51 章 star 的会合

本章的 `multi` 是自反传递闭包的一种写法；51 章的 `star` 是另一种（多一个"单步直达"
构造子 `oner`）。它们理应等价。先抄回 51 章的 `star`：

```coq
(* ---------- 55.11 与 51 章 star 的会合 ---------- *)

Inductive star {A : Type} (R : A -> A -> Prop) : A -> A -> Prop :=
  | nilr : forall x : A, star R x x
  | oner : forall x y : A, R x y -> star R x y
  | comp : forall x y z : A,
      star R x y -> star R y z -> star R x z.
```

两个方向：

```coq
Lemma star__multi : forall (A : Type) (R : A -> A -> Prop) x y,
  star R x y ->
  multi R x y.
Proof.
  intros A R x y H.
  induction H as [ x | x y Hxy | x y z H1 IH1 H2 IH2 ].
  - apply multi_refl.
  - eapply multi_step.
    + exact Hxy.
    + apply multi_refl.
  - eapply multi_trans.
    + exact IH1.
    + exact IH2.
Qed.
```

`nilr` ↔ `multi_refl` 直接对应；`oner`（一步直达）在 multi 里是"一步 + 零步"
（`multi_step` + `multi_refl`）；`comp` ↔ `multi_trans`。

```coq
Lemma multi__star : forall (A : Type) (R : A -> A -> Prop) x y,
  multi R x y ->
  star R x y.
Proof.
  intros A R x y H.
  induction H as [ x | x y z Hxy Hyz IH ].
  - apply nilr.
  - eapply comp.
    + apply oner. exact Hxy.
    + exact IH.
Qed.
```

反方向更有意思：`multi_step` 的"一步 + 多步"翻译成 star 的"一步直达 + 拼接"
（`oner` + `comp`）。合体：

```coq
Theorem multi_iff_star : forall (A : Type) (R : A -> A -> Prop) x y,
  multi R x y <-> star R x y.
Proof.
  intros A R x y. split.
  - apply multi__star.
  - apply star__multi.
Qed.
```

于是本章的主定理也可以念成：`st =[c]=> st'` 当且仅当 `star step (c, st) (skip, st')`
——51 章的闭包理论在这里精确落位。

```coq
Print Assumptions ceval_iff_multi.

End Ex55Smallstep.
```

### 55.12 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **类型乘积要写 `(com * state)%type`**（55.2）：`Definition config := com * state.` 报
   `The term "com" has type "Set" while it is expected to have type "nat"`。原因是
   nat_scope 的 `*`（`Nat.mul`，`Require Import Arith` 时打开）压过了 type_scope 的
   `*`（`prod`）——最小复现 `Definition A := nat * nat.`（无 com 参与）报同款错误。53 章
   的 com 记号只活在自定义条目内部，与此无关；但同文件混写时，`+ - *` 在 nat_scope
   和别的 scope 之间的争抢值得逐个想清楚。
2. **pair 索引的归纳要给裸变量**（55.5、55.8）：`multi step (c1, st) (c1', st')` 的索引是
   复合项，`induction` 不会抽象 `c1/st`，分支里被钉死（报
   `Unable to unify "(<{c1'; c2}>, st')" with "(<{c1; c2}>, st)"`）。陈述写成
   `forall p q` 或 `fst/snd` 形式，分支里再 `destruct`。
3. **对命令是变量的 ceval 假设反演会爆炸**（55.8）：`inversion Hce`（`Hce : st =[c2]=> st''`，
   `c2` 是变量）一次裂出 7 个构造子分支，六个 step 分支统一反演实测** 25 个目标**。
   命令具体才反演；命令抽象时改用目标规则直接拼接（`apply E_Seq with st` /
   `apply E_IfTrue` + `exact Hce`）。
4. **inversion 的假设名不稳定**（55.6、55.8）：同一段代码里反演产出的名字（H4、H5…）
   依赖上下文，重排战术就会变。按名字引用要么改用
   `match goal with H : <形状> |- _ => ... end`，要么用 `eassumption` 按形状取用。
5. **`match goal` 里注意参数顺序**（55.8）：`ceval` 的参数是（命令, 初态, 终态）。我把
   `(CSeq _ _)` 写在第二个参数位（状态位），match 永远失配，报
   `No matching clauses for match`。怀疑 match 失配时，先用 `idtac` 探针确认假设的真实
   形状。
6. **`f_equal` 会拆散 IH 需要的形状**（55.6）：IH 证配置相等 `(c1', st') = p2`；对目标
   （pair 相等）先 `f_equal` 拆成分量等式后，`apply IH` 报
   `Unable to unify "(c1', st') = ?p2" with "<{c1'; c2}> = c2"`。先
   `assert (E := IH _ H); injection E as E1 E2; subst` 再收尾。
7. **`E_Asgn` 的值要靠 `rewrite H` 对齐**（55.7）：和 54 章坑 4 同源——`ST_Ass` 产生
   `x !-> aeval st a ; st`，目标写的是 `x !-> n ; st`。`reflexivity` 不使用假设，先
   `rewrite H`（本例方向是 `H : aeval st a = n`，从左往右 rewrite 正好把表达式换成值）。
8. **`apply` 反解 `fst/snd` 目标会失败**（55.9）：`multi__ceval` 的结论是
   `snd q =[fst q]=> st'`，让它从目标 `st =[c]=> st'` 倒推 `q` 需要高阶统一，会失败。
   显式写 `apply (multi__ceval (c, st) st')`，转换检查负责其余。
9. **`ST_While` 展开式里循环体要加括号**（55.3）：`if b then (c ; while ...) else skip`
   中的 `(c ; while ...)`——`;` 右结合且 level 90 高于 if 分支位，不括号会整体解析错，
   且错误信息只说 unification 失败，不提示括号问题。
10. **`Print Assumptions` 是等价性定理的最后一道关**（55.9）：`Closed under the global
    context` 确认没偷偷用 `functional_extensionality`（配置相等走的是 pair 的单射性，
    不需要函数外延）。
11. **`congruence` 能吃掉的目标比想象多**（55.6）：`ST_Ass` 对 `ST_Ass` 的平凡情形、
    `ST_IfTrue` 对 `ST_IfFalse` 的条件矛盾情形全被
    `inversion H2; subst; try congruence` 一次吃完，实测只剩 3 个目标需要手写。先用
    `Show` 探针看剩余目标再写 bullet，别按"6×6=36 种组合"脑补。
12. **repl 是反演爆炸的第一现场**（55.8）：`rocq repl -q < ex_40_smallstep.v` 里数目标
    （`25 goals`）比在编译报错里猜快得多。本章 3 号坑就是数出来的。

---
上一章：[54 · 燃料求值器：把关系变回函数](54-fuel-evaluation.md) ｜ 下一章：[56 · 行为等价：程序何时相同](56-equiv.md) ｜ 返回：[README](../README.md)
