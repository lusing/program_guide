# 58 · Hoare 逻辑

对应示例：`../examples/58_hoare.v`（`Module Ex58Hoare`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

53 章问了"这段程序怎么跑"（大步语义），54 章让它能算（燃料），55 章拆开看每一步。
本章换一个问题：**这段程序跑完之后，什么东西一定是对的？**

这就是**霍尔逻辑**（Hoare Logic，1969）：给程序配上**前置条件**和**后置条件**，写成
三元组

```
{{ P }} c {{ Q }}
```

读作："如果 `c` 从满足断言 P 的状态开始执行，**并且它终止**，那么终止状态满足断言
Q。"注意"并且终止"这个限定——霍尔逻辑是**偏正确性**（partial correctness）：它不管
程序会不会死循环（58.8 的 `always_loop_hoare` 会把这一点推到极致：不终止的循环可以
证明出**任何**后置条件）。

本章的主线是给 Imp 的每条命令配一条**推理规则**——skip、赋值、顺序、条件、循环，外加
两条"结论"规则搬动前后置条件。规则凑齐之后，**程序的结构就是证明的结构**：
`while_example_add`（58.9）里我们用一个不变量证明一个把 X 的值搬到 Y 的循环，整个
证明的形状和程序的形状严丝合缝。

### 58.1 语言与大步语义的副本（同 38/54/55 章）

示例自包含。文件头——本章需要 `Lia`（断言之间的算术蕴含全靠它）：

```coq
(* 42 Hoare 逻辑：{{P}} c {{Q}} —— 从"求值"到"证明程序正确" *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex58Hoare.

(* ---------- 58.1 语言与大步语义的副本（同 38/54/55 章） ---------- *)

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

三条抬进记号与表达式记号照抄 53.3：

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

Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).
```

命令语法与五条记号、`ceval` 七条规则：

```coq
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

### 58.2 断言：把"程序状态"变成"逻辑命题"

**断言**（assertion）就是关于状态的一元谓词——`state -> Prop`：

```coq
(* ---------- 58.2 断言：把"程序状态"变成"逻辑命题" ---------- *)

Definition Assertion := state -> Prop.

Definition assertion1 : Assertion := fun st => st X <= st Y.
Definition assertion2 : Assertion := fun st => True.
Definition assertion3 : Assertion := fun st => False.
```

读法：`assertion1` 在"X 的值不超过 Y"的状态上成立；`assertion2` 处处成立；
`assertion3` 处处不成立。注意 `st X <= st Y` 里的 `<=` 是 **nat_scope 的 Nat.le**——
53 章那批 `<= > = <>` 记号只活在自定义条目 `com` **内部**，不会劫持外面的 nat 比较
（对比：`+ - *` 的问题出在 nat_scope 和 type_scope 抢 `*`，55 章坑 1 讲过）。

断言之间的**蕴含**是一元谓词上的逐点蕴含：

```coq
Definition assert_implies (P Q : Assertion) : Prop :=
  forall st, P st -> Q st.

Declare Scope hoare_scope.
Open Scope hoare_scope.

Notation "P ->> Q" := (assert_implies P Q)
  (at level 80) : hoare_scope.

Notation "P <<->> Q" := ((P ->> Q) /\ (Q ->> P))
  (at level 80) : hoare_scope.
```

`->>` 读"断言蕴含"，`<<->>` 读"断言等价"。注意 RHS 里的括号：`(P ->> Q) /\ (Q ->> P)`——
两个记号同为 level 80，不加括号解析器会报 "tolerating this expression at a higher
level"（实测警告），坑清单第 3 条。

一个双方向的例子（`<<->>` 要分别证两个方向）：

```coq
Example assert_implies_example :
  (fun st => st X = 3) <<->> (fun st => 2 < st X /\ st X < 4).
Proof.
  split; unfold assert_implies; intros st H.
  - split; lia.
  - lia.
Qed.
```

`split` 把 `P ->> Q /\ Q ->> P` 拆成两个蕴含，每个 `unfold assert_implies; intros st H`
之后就是普通的自然数算术，`lia` 收尾。

### 58.3 霍尔三元组：偏正确性的形式化

核心定义只有一行：

```coq
(* ---------- 58.3 霍尔三元组：偏正确性的形式化 ---------- *)

Definition valid_hoare_triple
           (P : Assertion) (c : com) (Q : Assertion) : Prop :=
  forall st st',
     st =[ c ]=> st' ->
     P st ->
     Q st'.
```

把它念出声："对任意初态 st 和终态 st'，**如果** st 执行 c 终止于 st'，**且** P 在 st
成立，**那么** Q 在 st' 成立。" `st =[ c ]=> st'` 本身就要求 c 终止——死循环的程序
 premises 自动为假，这就是"偏正确性"的精确来源。

配记号：

```coq
Notation "{{ P }} c {{ Q }}" :=
  (valid_hoare_triple P c Q)
    (at level 92, P at level 90, Q at level 90) : hoare_scope.
```

原书（PLF 卷）为 P 和 Q 也造了一套自定义记号条目，能写 `{{ X <= 3 }}` 这种不带
`fun st =>` 的漂亮形式；那套机制和 53 章的 `com` 条目同构，本章不再重复一遍，断言一律
写成 `fun st => ...` 的显式形式——多打几个字，换来每一步都能 `unfold` 看清。c 的位置
直接用 `<{ }>` 抬进（53.3 的机制）。

两个"退化"定理把定义的边界摸清楚（原书各留作一星练习，这里直接证掉）：

```coq
Theorem hoare_post_true : forall (P Q : Assertion) c,
  (forall st, Q st) ->
  {{P}} c {{Q}}.
Proof.
  intros P Q c H st st' HE HP. apply H.
Qed.

Theorem hoare_pre_false : forall (P Q : Assertion) c,
  (forall st, ~ (P st)) ->
  {{P}} c {{Q}}.
Proof.
  intros P Q c H st st' HE HP. destruct (H st HP).
Qed.
```

- `hoare_post_true`：后置条件永真，三元组自动成立——根本不用管 c 是什么。
- `hoare_pre_false`：前置条件处处为假，三元组也自动成立。`destruct (H st HP)` 用
  `H st : ~ P st` 吃掉 `HP : P st` 得到 `False`，`destruct` 一个 `False` 证明直接
  关闭任意目标。**这两个定理是"空洞正确"的两个出口**，58.8 的 `always_loop_hoare`
  会组合它们证出"死循环满足任何规格"。

### 58.4 skip 与顺序复合规则

```coq
(* ---------- 58.4 skip 与顺序复合规则 ---------- *)

Theorem hoare_skip : forall P,
  {{P}} <{ skip }> {{P}}.
Proof.
  intros P st st' H HP. inversion H; subst. assumption.
Qed.
```

skip 不改状态（反演 `E_Skip` 得 `st' = st`），任何断言 P 原样穿过。

```coq
Theorem hoare_seq : forall P Q R c1 c2,
  {{Q}} c2 {{R}} ->
  {{P}} c1 {{Q}} ->
  {{P}} <{ c1 ; c2 }> {{R}}.
Proof.
  intros P Q R c1 c2 H1 H2 st st' H12 Pre.
  inversion H12; subst.
  eapply H1; eauto.
Qed.
```

读法（注意前提顺序是 c2 在前——这不是笔误）：如果 c1 把 P 状态带到 Q 状态，c2 把 Q
状态带到 R 状态，那么 `c1 ; c2` 把 P 带到 R。**前提倒排**正好匹配实际使用的方向：拿到
目标后置条件 R，先给 c2 配中间断言 Q，再往前推 c1 的前置。证明体：反演 `E_Seq` 拿到
中间状态，`eapply H1; eauto` 让 eauto 自己把 `H2`（c1 的三元组）套上去补出中间断言。

### 58.5 赋值规则：从后置条件倒推前置条件

赋值规则是整个霍尔逻辑最精妙的一条。问：`{{ ??? }} X := X + 1 {{ X < 5 }}` 的前置
条件是什么？答：把后置条件里的 X 全部换成 `X + 1`——`X + 1 < 5`。**这条规则是"倒着"
的**：从后置条件出发构造前置条件。

"把断言 P 里的 X 换成表达式 a"怎么定义？P 是任意 Rocq 谓词，没法"编辑它的文本"。诀窍
是**在更新过的状态里求值 P**：

```coq
(* ---------- 58.5 赋值规则：从后置条件倒推前置条件 ---------- *)

Definition assertion_sub (X : string) (a : aexp) (P : Assertion) : Assertion :=
  fun st => P (X !-> aeval st a ; st).

Notation "P [ X |-> a ]" := (assertion_sub X a P)
  (at level 10, X at next level).
```

`P [X |-> a]` 在状态 st 上的值 = P 在"把 X 改成 a 的值"的状态上的值。它**行为上**等价
于文本替换——用 `reflexivity` 就能验证一个具体例子：

```coq
Example sub_example :
  (fun st => st X <= 5) [ X |-> <{ 3 }> ] = (fun st => 3 <= 5).
Proof. reflexivity. Qed.
```

注意两点：aexp 要用 `<{ 3 }>` 抬进来（裸 `3` 会被当成 nat）；这里的 `=` 是**函数相等**，
两边经 β/ι/δ 规约后是同一个项，所以 `reflexivity` 过——不需要函数外延公理。

赋值规则本体：

```coq
Theorem hoare_asgn : forall Q X (a : aexp),
  {{Q [ X |-> a ]}} <{ X := a }> {{Q}}.
Proof.
  intros Q X a st st' HE HQ.
  inversion HE; subst.
  unfold assertion_sub in HQ. simpl in HQ. assumption.
Qed.
```

证明就是展开定义：赋值后的状态恰好是 `X !-> aeval st a ; st`，正是 `assertion_sub`
里那个状态。规则本身几乎是定义的重言式——**威力全在"选哪个 Q"**。

一个直接套规则的例子：

```coq
Example assertion_sub_example :
  {{(fun st => st X < 5) [ X |-> <{ X + 1 }> ]}}
    <{ X := X + 1 }>
  {{fun st => st X < 5}}.
Proof. apply hoare_asgn. Qed.
```

前置条件 `(X < 5) [X |-> X+1]` 逐点等于 `fun st => st X + 1 < 5`。可我们真正想证的
是更好看的 `{{X < 4}} X := X + 1 {{X < 5}}`——两个前置条件**逻辑等价但不字面相同**，
`hoare_asgn` 直接 apply 不上。这正是下一节结论规则存在的理由。

### 58.6 结论规则：搬动前置/后置条件

```coq
(* ---------- 58.6 结论规则：搬动前置/后置条件 ---------- *)

Theorem hoare_consequence_pre : forall (P P' Q : Assertion) c,
  {{P'}} c {{Q}} ->
  P ->> P' ->
  {{P}} c {{Q}}.
Proof.
  unfold valid_hoare_triple, assert_implies.
  intros P P' Q c Hhoare Himp st st' Heval Hpre.
  apply Hhoare with (st := st).
  - assumption.
  - apply Himp. assumption.
Qed.

Theorem hoare_consequence_post : forall (P Q Q' : Assertion) c,
  {{P}} c {{Q'}} ->
  Q' ->> Q ->
  {{P}} c {{Q}}.
Proof.
  unfold valid_hoare_triple, assert_implies.
  intros P Q Q' c Hhoare Himp st st' Heval Hpre.
  apply Himp.
  apply Hhoare with (st := st).
  - assumption.
  - assumption.
Qed.
```

- **pre 规则**：把前置条件**加强**成 P'（P 蕴含 P'，所以从 P 出发也能用 P' 的规格）。
- **post 规则**：把后置条件**减弱**（Q' 蕴含 Q，证出更强的 Q' 就免费得到 Q）。
- 两条的证明都是 `unfold` 之后一步 `apply ... with (st := st)`：`apply` 一条
  `forall st st', ...` 的三元组时**必须显式给 st**，否则它会把 st' 也统一掉。
  坑清单第 4 条。

两条合一的双向版本：

```coq
Theorem hoare_consequence : forall (P P' Q Q' : Assertion) c,
  {{P'}} c {{Q'}} ->
  P ->> P' ->
  Q' ->> Q ->
  {{P}} c {{Q}}.
Proof.
  intros P P' Q Q' c Hhoare Hpre Hpost st st' Heval HP.
  apply Hpost. apply Hhoare with (st := st).
  - assumption.
  - apply Hpre. assumption.
Qed.
```

现在可以回到 58.5 结尾的悬案：

```coq
Example hoare_asgn_example1 :
  {{fun st => True}} <{ X := 1 }> {{fun st => st X = 1}}.
Proof.
  eapply hoare_consequence_pre.
  - apply hoare_asgn.
  - unfold assert_implies, assertion_sub, t_update.
    simpl. intros st _. reflexivity.
Qed.

Example assertion_sub_example2 :
  {{fun st => st X < 4}}
    <{ X := X + 1 }>
  {{fun st => st X < 5}}.
Proof.
  eapply hoare_consequence_pre.
  - apply hoare_asgn.
  - unfold assert_implies, assertion_sub, t_update.
    simpl. intros st H. lia.
Qed.
```

固定套路 `eapply hoare_consequence_pre. - apply hoare_asgn. - <算术>`：第一个子目标
让 `hoare_asgn` 造出 `Q [X |-> a]` 形状的前置条件，第二个子目标证"我们想要的前置蕴含
它"。第二个子目标的证明永远是同一套三板斧：`unfold assert_implies, assertion_sub,
t_update` → `simpl` → `lia`（或 `reflexivity`）。`unfold` 名单里 **`t_update` 不能漏**——
状态更新是个 `if String.eqb ...`，不展开的话 `simpl` 之后目标里还挂着
`if X =? X then ... else ...`，`lia` 看不懂（坑清单第 2 条）。

### 58.7 条件规则：把 bexp 抬成断言

朴素版条件规则"两个分支都用同一个 P、证到同一个 Q"太弱（原书用
`{{True}} if X = 0 then Y := 2 else Y := X + 1 end {{X <= Y}}` 说明这点）。关键改进：
**把条件的信息喂给两个分支**——then 分支里知道 b 为真，else 分支里知道 b 为假。

bexp 是布尔表达式、断言是谓词，两者不同类型，需要"抬升"：

```coq
(* ---------- 58.7 条件规则：把 bexp 抬成断言 ---------- *)

Definition bassertion (b : bexp) : Assertion :=
  fun st => (beval st b = true).

Lemma bexp_eval_false : forall b st,
  beval st b = false -> ~ ((bassertion b) st).
Proof. congruence. Qed.

Lemma not_true_is_false : forall b : bool, ~ (b = true) -> b = false.
Proof.
  intros [] H.
  - exfalso. apply H. reflexivity.
  - reflexivity.
Qed.
```

`bassertion b` 是"b 在此状态求值为真"这个断言。两条小引理是后面反复用的"布尔翻译"：
`bexp_eval_false` 由"求值为假"得到"断言不成立"（`congruence` 一步）；`not_true_is_false`
把 `~(b = true)` 翻成 `b = false`——第二条我本来想用标准库的
`not_true_iff_false`，但 `apply not_true_iff_false in H` 会挑**反方向**（实测报
`Unable to apply lemma ... on hypothesis of type "False"`，还留下一堆残局），不如自己
两条 `intros []` 分情况写清楚（坑清单第 5 条）。

条件规则：

```coq
Theorem hoare_if : forall P Q (b:bexp) c1 c2,
  {{fun st => P st /\ bassertion b st}} c1 {{Q}} ->
  {{fun st => P st /\ ~ (bassertion b st)}} c2 {{Q}} ->
  {{P}} <{ if b then c1 else c2 end }> {{Q}}.
Proof.
  intros P Q b c1 c2 HTrue HFalse st st' HE HP.
  inversion HE; subst.
  - apply HTrue with (st := st).
    + assumption.
    + split; assumption.
  - apply HFalse with (st := st).
    + assumption.
    + split.
      * assumption.
      * apply bexp_eval_false. assumption.
Qed.
```

then 分支：反演 `E_IfTrue` 拿到 `beval st b = true` 和分支的求值；套 `HTrue` 时第二个
前提是 `P st /\ bassertion b st`——`split; assumption` 里第二个 `assumption` 靠
**转换等价**吃下 `beval st b = true`（`bassertion b st` δ-展开就是它）。else 分支的
`~ bassertion b st` 不是任何现成假设的形状，用 `bexp_eval_false` 造出来。

动机例子：

```coq
Example if_example :
  {{fun st => True}}
    <{ if (X = 0) then Y := 2 else Y := X + 1 end }>
  {{fun st => st X <= st Y}}.
Proof.
  apply hoare_if.
  - eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + unfold assert_implies, assertion_sub, t_update, bassertion.
      simpl. intros st [_ H]. apply Nat.eqb_eq in H.
      rewrite H. lia.
  - eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + unfold assert_implies, assertion_sub, t_update, bassertion.
      simpl. intros st _. lia.
Qed.
```

- then 分支：`Y := 2` 后要 `X <= Y`，赋值规则给出前置 `(X <= Y)[Y |-> 2]`，即
  `X <= 2`。从"分支条件"那半边（`[_ H]` 里的 H）推出：`X = 0` 作为 bexp 求值为真，
  `simpl` 之后是 `(st X =? 0) = true`，`Nat.eqb_eq` 翻成 `st X = 0`，`rewrite` 进目标
  `st X <= 2` 变 `0 <= 2`，`lia`。
- else 分支：前置 `(X <= Y)[Y |-> X + 1]` 即 `X <= X + 1`，`lia` 无需条件。
- 两个分支都**无视**前提里没用的那一半（`[_ H]`、`_`）——断言里的合取分量按需取用。

### 58.8 循环规则：不变量

先想一个天真的规则：`{{P}} c {{P}}` 蕴含 `{{P}} while b do c end {{P}}`。它对，但
浪费了两条信息：循环**退出**时 b 为假（后置可以加 `~b`）；循环**进入体内**时 b 为真
（体内的前置可以加 `b`）。补全后：

```coq
(* ---------- 58.8 循环规则：不变量 ---------- *)

Theorem hoare_while : forall P (b:bexp) c,
  {{fun st => P st /\ bassertion b st}} c {{P}} ->
  {{P}} <{ while b do c end }>
  {{fun st => P st /\ ~ (bassertion b st)}}.
Proof.
  intros P b c Hhoare st st' Heval HP.
  remember <{ while b do c end }> as original_command eqn:Horig.
  induction Heval;
    try (inversion Horig; subst; clear Horig).
  - (* E_WhileFalse：循环退出，P 保持，且 b 为假 *)
    split.
    + assumption.
    + apply bexp_eval_false. assumption.
  - (* E_WhileTrue：先用归纳假设拿"剩余循环"的结论，
       再用体规则从 P st 重建 P st' *)
    apply IHHeval2.
    + reflexivity.
    + apply Hhoare with (st := st).
      * assumption.
      * split; assumption.
Qed.
```

P 叫**循环不变量**（loop invariant）：进循环体时成立，出循环体时还成立——中间可以
暂时被打破，但每轮末尾必须恢复。

证明的骨架值得细读，因为它综合了 53 章以来的全部手法：

- `remember <{ while b do c end }> as original_command`：**冻结整个循环**。不然
  `induction Heval` 之后，E_WhileTrue 分支的归纳假设只谈"子命令"，而我们要的结论是
  关于整个循环的（53.12 `loop_never_stops` 同款手法）。
- `try (inversion Horig; subst; clear Horig)`：七个 ceval 构造子里，命令形状对不上
  `while` 的（skip、赋值、seq、if）被 `inversion Horig` 一次性清掉，只剩两条 while
  规则——**用命令形状过滤归纳分支**。
- E_WhileFalse：`split` 出"P 保持"（HP 直接用）和"b 为假"（`bexp_eval_false`）。
- E_WhileTrue：归纳假设 `IHHeval2` 是关于**剩余循环**的（形式上多了一个前提
  `<{while ...}> = <{while ...}>`，由 remember 产生，`reflexivity` 消掉）；体内一段用
  `Hhoare` 从 `P st` 重建出 `P st'`，正好喂给 IH。

一个完整的循环证明：

```coq
Example while_example :
  {{fun st => st X <= 3}}
    <{ while (X <= 2) do
         X := X + 1
       end }>
  {{fun st => st X = 3}}.
Proof.
  eapply hoare_consequence_post.
  - apply hoare_while.
    eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + unfold assert_implies, assertion_sub, t_update, bassertion.
      simpl. intros st [Hinv Hguard].
      apply Nat.leb_le in Hguard.
      lia.
  - unfold assert_implies, assertion_sub, t_update, bassertion.
    simpl. intros st [Hinv Hguard].
    apply not_true_is_false in Hguard.
    apply Nat.leb_gt in Hguard.
    lia.
Qed.
```

设计过程比证明脚本更重要，按"从后往前"的顺序走一遍：

1. 后置想要 `X = 3`。`hoare_while` 天然给出的后置是 `P /\ ~b`，取**不变量**
   `P := fun st => st X <= 3`：退出时 `~(X <= 2)` 即 `X > 2`，配合 P 得 `X = 3`——
   这就是外层 `hoare_consequence_post` 干的事。
2. 体内 `X := X + 1` 要保持 P。赋值规则给出前置 `P [X |-> X+1]` 即 `X + 1 <= 3`；
   而体内的实际前置是 `P /\ b`，即 `X <= 3` 且 `X <= 2`——蕴含成立。这就是内层
   `hoare_consequence_pre`。
3. 两个"断言翻译"：`Nat.leb_le` 把 `(st X <=? 2) = true` 翻成 `st X <= 2`（体内用）；
   `not_true_is_false` + `Nat.leb_gt` 把 `~((st X <=? 2) = true)` 翻成 `2 < st X`
   （退出侧用）。**`lia` 不认 `<=? = true` 这种布尔等式**（实测 `Cannot find witness`），
   必须先用引理翻译，坑清单第 1 条。

最后是偏正确性的"戏剧时刻"——死循环满足任何规格：

```coq
Theorem always_loop_hoare : forall Q,
  {{fun st => True}} <{ while true do skip end }> {{Q}}.
Proof.
  intros Q.
  eapply hoare_consequence_post.
  - apply hoare_while. apply hoare_post_true. auto.
  - unfold assert_implies, bassertion. simpl.
    intros st [Hinv Hguard]. congruence.
Qed.
```

- 体内 `skip`：取不变量 `P := fun st => True`，体内三元组
  `{{True /\ bassertion true}} skip {{True}}` 直接由 `hoare_post_true`（58.3）给出。
- 退出侧要证 `True /\ ~ bassertion true ->> Q`：`bassertion true` 求值就是 `true = true`，
  它的否定是矛盾——`congruence` 发现 `Hguard : ~ (true = true)` 和事实冲突，关闭任意
  目标。

这条定理**不是悖论**：`while true do skip end` 永不终止，三元组的前提
`st =[ c ]=> st'` 永远为假，所以任何 Q 都"成立"。它精确刻画了偏正确性证明的盲区：
想要"终止 + 正确"（全正确性），得另外提供变体函数/良基递减证据，那是原书 PLF 卷
后续章节的话题。

### 58.9 综合例子：给循环找一个不变量

把全部规则串起来证一个真正的两变量循环：`while X <> 0 do Y := Y + 1; X := X - 1 end`
把 X 的值搬到 Y（X 每次 -1、Y 每次 +1，X + Y 保持）：

```coq
(* ---------- 58.9 综合例子：给循环找一个不变量 ---------- *)

Example while_example_add :
  {{fun st => st X + st Y = 5}}
    <{ while X <> 0 do
         Y := Y + 1;
         X := X - 1
       end }>
  {{fun st => st X + st Y = 5 /\ st X = 0}}.
Proof.
  eapply hoare_consequence_post.
  - apply hoare_while.
    apply hoare_seq with (fun st => st X - 1 + st Y = 5).
    + eapply hoare_consequence_pre.
      * apply hoare_asgn.
      * unfold assert_implies, assertion_sub, t_update.
        simpl. intros st H. lia.
    + eapply hoare_consequence_pre.
      * apply hoare_asgn.
      * unfold assert_implies, assertion_sub, t_update, bassertion.
        simpl. intros st [Hinv Hguard].
        rewrite negb_true_iff in Hguard.
        apply Nat.eqb_neq in Hguard.
        lia.
  - unfold assert_implies, bassertion.
    simpl. intros st [Hinv Hguard].
    apply not_true_is_false in Hguard.
    rewrite negb_false_iff in Hguard.
    apply Nat.eqb_eq in Hguard.
    lia.
Qed.
```

逐层拆开，证明的**结构**就是程序的**结构**：

- **最外层**（`hoare_consequence_post`）：`hoare_while` 给出 `P /\ ~b`，取不变量
  `P := fun st => st X + st Y = 5`。退出侧把 `~(X <> 0)` 翻成 `st X = 0`：
  `not_true_is_false`（`~(negb … = true)` → `negb … = false`）→ `negb_false_iff`
  （→ `st X =? 0 = true`）→ `Nat.eqb_eq`（→ `st X = 0`），`lia` 收尾。
- **体**（`hoare_seq`）：体内是 `Y := Y + 1 ; X := X - 1`，需要中间断言——取
  `fun st => st X - 1 + st Y = 5`（"X 减掉之后加 Y 还是 5"）。注意 `hoare_seq` 的前提
  **c2 在前**，所以第一个 `+` 处理的是 `X := X - 1`：赋值规则前置
  `P [X |-> X-1]` 逐点等于中间断言本身，`lia` 直接过关。第二个 `+` 处理
  `Y := Y + 1`：前置是 `(X - 1 + Y)[Y |-> Y+1]` 即 `X - 1 + (Y + 1) = 5`；从
  `X + Y = 5` 和"X ≠ 0"（`negb_true_iff` + `Nat.eqb_neq` 翻译）推出——这里用到
  **nat 减法的截断性质**：X ≥ 1 时 `X - 1 + Y + 1 = X + Y`，`lia` 自动处理。

不变量怎么找？拿"每轮前后保持的量"当 P：X 少 1、Y 多 1，`X + Y` 不动。然后把想要的
最终答案（`Y = 5`）拆成"不变量 + 退出条件"（`X + Y = 5` 且 `X = 0`）。这是霍尔逻辑
证明循环的通用心法：**规格里的乘法（循环）对应证明里的加法（不变量 + 守卫）**。

```coq
Print Assumptions while_example_add.
```

repl 输出：

```
Closed under the global context
```

零公理——整个证明只用了 53 章的语言层和本章七条规则。

```coq
End Ex58Hoare.
```

### 58.10 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`lia` 不认 `<=? = true` 这类布尔等式**（58.8）：体内蕴含里我直接 `lia`，报
   `Cannot find witness`——它把 `(st X <=? 2) = true` 当不透明布尔等式，从 `X <= 3`
   推不出 `X + 1 <= 3`。必须先 `Nat.leb_le / Nat.leb_gt / Nat.eqb_eq / Nat.eqb_neq`
   把布尔翻成算术。配套的 `~(b = true)` → `b = false` 用自写的
   `not_true_is_false`。
2. **`unfold t_update` 不能漏**（58.6 起）：断言替换的三板斧
   `unfold assert_implies, assertion_sub, t_update` → `simpl` → `lia`。少了
   `t_update`，`simpl` 后目标里留着 `if X =? X then ... else ...`（`String.eqb` 的
   if），`lia` 失败。
3. **两个 level-80 记号叠用要加括号**（58.2）：`P <<->> Q` 的 RHS 写成
   `P ->> Q /\ Q ->> P` 会触发
   `Warning: In term, tolerating this expression at a higher level ...`；写成
   `(P ->> Q) /\ (Q ->> P)` 消除。
4. **`apply` 三元组要显式 `with (st := st)`**（58.6、58.7、58.8）：`valid_hoare_triple`
   的量词是 `forall st st', st =[c]=> st' -> P st -> Q st'`，直接 `apply Hhoare` 会把
   两个状态都往目标上碰运气，失败时统一显式给初态。
5. **`apply <iff引理> in H` 会挑反方向**（58.7）：`not_true_iff_false : b <> true <->
   b = false`，对 `H : b <> true` 做 `apply ... in H` 实测走了 `b = false -> b <> true`
   那半边（留下 `H : False` 残局并新开 `(st X <=? 2) = false` 目标）。要正向用 iff 的
   `proj1`，或者像本章一样写一个方向明确的小引理。
6. **断言里的 aexp 必须 `<{ }>` 抬进**（58.5）：`P [ X |-> X + 1 ]` 里的 `X + 1` 是
   aexp，裸写会被解析成 `Nat.add X 1`（X 是 string）直接报类型错。`<{ X + 1 }>` 才走
   com 条目。
7. **nat 比较不受 com 记号影响，类型乘积却会**（58.2 vs 55 章坑 1）：`st X <= st Y` 安全，
   因为 `<= > = <>` 只声明在自定义条目 `com` 内部；而 `+ - *` 在 nat_scope 与
   type_scope 之间的冲突（55 章的 `(com * state)%type`）依然存在。同文件混写命令和
   断言时，对每个中缀操作符想一遍"它现在归谁管"。
8. **`hoare_seq` 的前提是倒序的**（58.4、58.9）：`{{Q}} c2 {{R}} -> {{P}} c1 {{Q}} ->
   ...`。写证明时第一个子目标永远是**后半段**命令——58.9 我第一版把两个 `+` 分支写反，
   编译器报 `Unexpected name (no introduction patterns were expected in the branch)`
   （一侧的假设是合取、另一侧是单条，intro 模式对不上）。看到这种"模式对不上"，先检查
   分支是不是装反了。
9. **`remember` 之后归纳假设带等式前提**（58.8）：`IHHeval2 : <{while...}> = <{while...}>
   -> ...`，先 `reflexivity` 消掉再用。这是 remember 冻结命令的固定代价。
10. **规则齐了就不要再 `unfold valid_hoare_triple`**（58.5 之后）：本章设计的意义就是
    用七条规则**组合**推理、不再碰求值语义。除了规则本身的证明（58.3–58.8 各一次
    `unfold`），所有 Example 的脚本里只有规则名 + 断言翻译 + `lia`。

---
上一章：[57 · 词法与语法解析](57-parsing.md) ｜ 下一章：[59 · 装饰程序：不变量的寻找法](59-decorated.md) ｜ 返回：[README](../README.md)
