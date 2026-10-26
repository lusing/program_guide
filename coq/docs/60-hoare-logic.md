# 60 · 霍尔逻辑作为逻辑

对应示例：`../examples/60_hoare_logic.v`（`Module Ex60HoareLogic`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

58 章的霍尔逻辑是**模型论**式的：`{{P}} c {{Q}}` 的意义来自"程序怎么执行"——
`valid_hoare_triple` 直接谈状态和求值，七条推理规则是**关于**这个语义的**定理**，
证明程序正确就是把这些定理组合起来。

本章换一副眼镜——**证明论**：忘掉状态和求值，把霍尔逻辑当成一套**独立的公理
系统**。三元组是没有内在意义的语法对象，"证明"是一棵**推导树**（derivation）——
本章把它定义成一个**归纳类型**，规则成为构造子，推导树成为数据。然后问逻辑学的
标准问题：

- **可靠性（soundness）**：推得出的三元组都有效吗？（推导 ⟹ 语义）
- **完备性（completeness）**：有效的三元组都推得出吗？（语义 ⟹ 推导）

答案是**双向都成立**——霍尔逻辑恰好刻画了它自己的语义。完备性方向的证明需要
发明一个强大得惊人的工具：**最弱前置条件** `wp`——给定命令 c 和后置 Q，
`wp c Q` 是"恰好够用"的前置条件；对 while，它直接给出循环不变量，**不变量的
寻找从艺术变成计算**。59 章的装饰程序法是 wp 思想的工程化，本章是它的理论基础。

49 章（证明即项）在这里回响：58 章的规则是 `Theorem`（证明项藏在 Qed 后面），
本章的规则是 `Inductive` 的构造子（推导树是**可以拿在手里的数据**）——同一套
规则，Curry–Howard 的两面。

### 60.1 从有效性到七条规则：58 章的装备副本

本章自包含，先把 58 章的语言层、断言层与七条规则全部搬来（讲解全部在 58 章，
此处引用原文并不重复展开，但每一行都在下面——60.2 起它们是推导系统的"公理"）。
文件头与 Imp 语言副本：

```coq
(* 45 霍尔逻辑作为逻辑 —— derivable 推导树、可靠性、最弱前置条件与完备性 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex60HoareLogic.

(* ---------- 60.1 从有效性到七条规则：58 章的装备副本 ---------- *)

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

断言层（Assertion、蕴含与等价记号）：

```coq
(* ---------- 60.1b 断言：把"程序状态"变成"逻辑命题" ---------- *)

Definition Assertion := state -> Prop.

Definition assertion1 : Assertion := fun st => st X <= st Y.
Definition assertion2 : Assertion := fun st => True.
Definition assertion3 : Assertion := fun st => False.

Definition assert_implies (P Q : Assertion) : Prop :=
  forall st, P st -> Q st.

Declare Scope hoare_scope.
Open Scope hoare_scope.

Notation "P ->> Q" := (assert_implies P Q)
  (at level 80) : hoare_scope.

Notation "P <<->> Q" := ((P ->> Q) /\ (Q ->> P))
  (at level 80) : hoare_scope.

Example assert_implies_example :
  (fun st => st X = 3) <<->> (fun st => 2 < st X /\ st X < 4).
Proof.
  split; unfold assert_implies; intros st H.
  - split; lia.
  - lia.
Qed.
```

三元组与两条"空洞正确"定理：

```coq
(* ---------- 60.1c 霍尔三元组：偏正确性的形式化 ---------- *)

Definition valid_hoare_triple
           (P : Assertion) (c : com) (Q : Assertion) : Prop :=
  forall st st',
     st =[ c ]=> st' ->
     P st ->
     Q st'.

Notation "{{ P }} c {{ Q }}" :=
  (valid_hoare_triple P c Q)
    (at level 92, P at level 90, Q at level 90) : hoare_scope.

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

skip/序列规则、替换与赋值规则、三条结论规则：

```coq
(* ---------- 60.1d skip 与顺序复合规则 ---------- *)

Theorem hoare_skip : forall P,
  {{P}} <{ skip }> {{P}}.
Proof.
  intros P st st' H HP. inversion H; subst. assumption.
Qed.

Theorem hoare_seq : forall P Q R c1 c2,
  {{Q}} c2 {{R}} ->
  {{P}} c1 {{Q}} ->
  {{P}} <{ c1 ; c2 }> {{R}}.
Proof.
  intros P Q R c1 c2 H1 H2 st st' H12 Pre.
  inversion H12; subst.
  eapply H1; eauto.
Qed.

(* ---------- 60.1e 赋值规则：从后置条件倒推前置条件 ---------- *)

Definition assertion_sub (X : string) (a : aexp) (P : Assertion) : Assertion :=
  fun st => P (X !-> aeval st a ; st).

Notation "P [ X |-> a ]" := (assertion_sub X a P)
  (at level 10, X at next level).

Example sub_example :
  (fun st => st X <= 5) [ X |-> <{ 3 }> ] = (fun st => 3 <= 5).
Proof. reflexivity. Qed.

Theorem hoare_asgn : forall Q X (a : aexp),
  {{Q [ X |-> a ]}} <{ X := a }> {{Q}}.
Proof.
  intros Q X a st st' HE HQ.
  inversion HE; subst.
  unfold assertion_sub in HQ. simpl in HQ. assumption.
Qed.

Example assertion_sub_example :
  {{(fun st => st X < 5) [ X |-> <{ X + 1 }> ]}}
    <{ X := X + 1 }>
  {{fun st => st X < 5}}.
Proof. apply hoare_asgn. Qed.

(* ---------- 60.1f 结论规则：搬动前置/后置条件 ---------- *)

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

bassertion、if 规则与 while 规则：

```coq
(* ---------- 60.1g 条件规则：把 bexp 抬成断言 ---------- *)

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

(* ---------- 60.1h 循环规则：不变量 ---------- *)

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

while_example 是"从后往前配不变量"的完整实战（不变量 `X <= 3` + 退出条件推出
`X = 3`，布尔翻译走 `Nat.leb_le / Nat.leb_gt`）；always_loop_hoare 是偏正确性的
戏剧时刻——死循环满足任何规格（58.8 详解）。以上每一件的完整讲解见 58 章；
从这里开始，它们的身份变了——不再是"关于语义的事实"，而是推导系统的**公理**。

### 60.2 derivable：推导树本身成为数据

```coq
(* ---------- 60.2 derivable：推导树本身成为数据 ---------- *)

Inductive derivable : Assertion -> com -> Assertion -> Type :=
  | H_Skip : forall P,
      derivable P <{ skip }> P
  | H_Asgn : forall Q V a,
      derivable (assertion_sub V a Q) <{ V := a }> Q
  | H_Seq : forall P c Q d R,
      derivable Q d R -> derivable P c Q -> derivable P <{ c ; d }> R
  | H_If : forall P Q b c1 c2,
    derivable (fun st => P st /\ bassertion b st) c1 Q ->
    derivable (fun st => P st /\ ~ (bassertion b st)) c2 Q ->
    derivable P <{ if b then c1 else c2 end }> Q
  | H_While : forall P b c,
    derivable (fun st => P st /\ bassertion b st) c P ->
    derivable P <{ while b do c end }>
             (fun st => P st /\ ~ (bassertion b st))
  | H_Consequence : forall (P Q P' Q' : Assertion) c,
    derivable P' c Q' ->
    (forall st, P st -> P' st) ->
    (forall st, Q' st -> Q st) ->
    derivable P c Q.
```

六个构造子对应 58 章的六条规则——把它们**并排**读一遍，差异只有三处：

1. **类型是 `Type` 不是 `Prop`**！60.1 的 hoare_skip 等是命题（只能被证明），
   `derivable` 的推导树是**数据**——可以 `match`、可以函数处理、可以被检查。
   repl 因此生成了三条消除原则：`derivable_ind is defined`、`derivable_rec is
   defined`、`derivable_sind is defined`——`_rec` 的出现正是 Type 值归纳的标志
   （Prop 归纳没有 `_rec`，因为没有计算内容可提取）。
2. 结论规则的**前提顺序**不同：58 章的 `hoare_consequence` 把两条蕴含放在推导
   之后，这里 `H_Consequence` 是"子推导、前置蕴含、后置蕴含"。
3. 蕴含写成了裸的 `forall st, P st -> P' st`（58 章 `->>` 记号的展开形）——
   公理系统里只放逻辑最小件。

由此立刻派生两条单向版本（58 章 `hoare_consequence_pre/post` 的镜像）：

```coq
Lemma H_Consequence_pre : forall (P Q P' : Assertion) c,
    derivable P' c Q ->
    (forall st, P st -> P' st) ->
    derivable P c Q.
Proof. eauto using H_Consequence. Qed.

Lemma H_Consequence_post : forall (P Q Q' : Assertion) c,
    derivable P c Q' ->
    (forall st, Q' st -> Q st) ->
    derivable P c Q.
Proof. eauto using H_Consequence. Qed.
```

`eauto using H_Consequence` 让搜索机自己补上恒真的另一半蕴含。手植第一棵
推导树：

```coq
Example sample_proof :
  derivable
    ((fun st : state => st X = 3) [X |-> <{ X + 2 }>] [X |-> <{ X + 1 }>])
    <{ X := X + 1; X := X + 2 }>
    (fun st : state => st X = 3).
Proof.
  eapply H_Seq.
  - apply H_Asgn.
  - apply H_Asgn.
Qed.
```

目标的三元组读法：给 `X := X+1; X := X+2` 配前置条件，**从后往前**把 X=3
代换两次（先换 X+2、再换 X+1——替换记号左结合，`Q [X|->a] [X|->b]` 是
`(Q [X|->a]) [X|->b]`）。证明脚本就是推导树的形状：根是 H_Seq，两片叶子各是
一条 H_Asgn。**注意 H_Seq 的前提顺序是"第二条命令在前"**（和 58 章的 hoare_seq
一样）——第一个 bullet 处理的是 `X := X + 2`。

### 60.3 两个派生练习：True 后置与 False 前置

```coq
(* ---------- 60.3 两个派生练习：True 后置与 False 前置 ---------- *)

Theorem provable_true_post : forall c P,
    derivable P c (fun _ => True).
Proof.
  induction c; intros P.
  - eapply H_Consequence_pre.
    + apply H_Skip.
    + intros st HP. exact I.
  - eapply H_Consequence_pre.
    + apply H_Asgn.
    + intros st HP. exact I.
  - eapply H_Seq.
    + apply IHc2.
    + apply IHc1.
  - eapply H_If.
    + apply IHc1.
    + apply IHc2.
  - eapply H_Consequence.
    + eapply H_While.
      * apply IHc.
    + intros st HP. exact I.
    + intros st _. exact I.
Qed.

Theorem provable_false_pre : forall c Q,
    derivable (fun _ => False) c Q.
Proof.
  induction c; intros Q.
  - eapply H_Consequence_post.
    + apply H_Skip.
    + intros st HF. destruct HF.
  - eapply H_Consequence_pre.
    + apply H_Asgn.
    + intros st HF. destruct HF.
  - eapply H_Seq.
    + apply IHc2.
    + apply IHc1.
  - eapply H_If.
    + eapply H_Consequence_pre.
      * apply IHc1.
      * intros st [HF _]. exact HF.
    + eapply H_Consequence_pre.
      * apply IHc2.
      * intros st [HF _]. exact HF.
  - eapply H_Consequence.
    + eapply H_While.
      * eapply H_Consequence_pre.
        -- apply IHc.
        -- intros st [HF _]. exact HF.
    + intros st HF. exact HF.
    + intros st [HF _]. destruct HF.
Qed.
```

原书各留三星练习，这里证完。两个定理说：**后置恒真的三元组总能推出**（随便什么
前置、什么命令）、**前置恒假的三元组总能推出**（60.1 的 `hoare_post_true`/
`hoare_pre_false` 是它们的语义版影子）。五个分支的战术要点：

- skip/赋值两个分支**不能**直接 `apply H_Skip/H_Asgn`——P 是全称变量，与目标
  的 `fun _ => True` / 替换形前置统一不上；都要套一层 `H_Consequence_pre`（或
  post），把"多出来的前提差距"用 `exact I` / `destruct HF` 填平。
- while 分支的诀窍是**选不变量**：True 后置取 `I := fun _ => True`——`H_While`
  的体前提变成"derivable (True/\b) c True"，正是 IH 的形状，一步到位。False
  前置取 `I := fun _ => False`——体前提 (False/\b) 与 IH 的前置 False 之间再垫
  一层 H_Consequence_pre（合取消解：`intros st [HF _]`）。
- 两个 False 分支的收尾 `destruct HF`：`False st` 定义上就是 `False`，毁灭一切
  目标。

### 60.4 可靠性：能推出的都有效

```coq
(* ---------- 60.4 可靠性：能推出的都有效 ---------- *)

Theorem hoare_sound : forall P c Q,
  derivable P c Q -> valid_hoare_triple P c Q.
Proof.
  intros P c Q H.
  induction H.
  - apply hoare_skip.
  - apply hoare_asgn.
  - eapply hoare_seq; eassumption.
  - eapply hoare_if; eassumption.
  - apply hoare_while. assumption.
  - eapply hoare_consequence; eassumption.
Qed.
```

**六行证完六条**——这正是"两套表述互为影子"的红利：60.1 的每条定理恰好是
对应构造子的语义版，对推导树归纳、逐条 apply 即可。`induction H` 在这里对
Type 值的归纳关系照常工作（用的是 derivable_ind）。

### 60.5 最弱前置条件 wp

完备性（有效 ⟹ 可推导）难得多：给一个有效的 `{{P}} c {{Q}}`，推导树从哪来？
关键工具：

```coq
(* ---------- 60.5 最弱前置条件 wp ---------- *)

Definition wp (c : com) (Q : Assertion) : Assertion :=
  fun s => forall s', s =[ c ]=> s' -> Q s'.

Theorem wp_is_precondition : forall c Q,
  valid_hoare_triple (wp c Q) c Q.
Proof.
  intros c Q. unfold valid_hoare_triple. intros st st' Hce Hwp.
  unfold wp in Hwp.
  apply (Hwp st').
  exact Hce.
Qed.

Theorem wp_is_weakest : forall c Q P',
    valid_hoare_triple P' c Q ->
    assert_implies P' (wp c Q).
Proof.
  intros c Q P' H.
  unfold assert_implies. intros st HP.
  unfold wp. intros s'' Hce.
  apply (H st s'' Hce HP).
Qed.

Lemma wp_seq : forall P Q c1 c2,
    derivable P c1 (wp c2 Q) ->
    derivable (wp c2 Q) c2 Q ->
    derivable P <{ c1; c2 }> Q.
Proof.
  intros P Q c1 c2 H1 H2.
  apply H_Seq with (Q := wp c2 Q).
  - exact H2.
  - exact H1.
Qed.
```

**`wp c Q`（weakest precondition）**：站在状态 s，"从 s 出发跑 c，**所有可能**
的终点都满足 Q"。两条性质把它钉死在"最弱"的位置上：

- `wp_is_precondition`：`{{wp c Q}} c {{Q}}` 有效——它**够用**（自己就是前置）。
- `wp_is_weakest`：任何别的前置 P' 若也够用，则 P' 蕴含 wp c Q——它**最弱**
  （任何够用的前提都被它涵盖，"弱"= 容易满足 = 涵盖面大）。

两条证明各三行，全部是把定义展开后的一次应用。**注意一个要紧的细节**：wp 的
量词是"对所有可能的终点"——Imp 的 ceval 是确定性的，所以它看起来像"对唯一的
终点"；但定义本身对非确定性语言同样成立（那时 wp 自动要求**每个**终点满足 Q），
这是 wp 比手工找不变量更强壮的原因。`wp_seq` 展示它的第一个用途：**序列的中间
断言不用猜**——`wp c2 Q` 就是标准答案。

### 60.6 wp 给出循环不变量，完备性收口

```coq
(* ---------- 60.6 wp 给出循环不变量，完备性收口 ---------- *)

Lemma wp_invariant : forall b c Q,
    valid_hoare_triple
      (fun st => wp <{ while b do c end }> Q st /\ bassertion b st)
      c
      (wp <{ while b do c end }> Q).
Proof.
  intros b c Q st st' Hce [Hwp Hb].
  unfold wp in *.
  intros s'' Hwhile'.
  apply (Hwp s'').
  apply E_WhileTrue with (st' := st').
  - apply Hb.
  - apply Hce.
  - apply Hwhile'.
Qed.
```

**全章最漂亮的引理**：对任何循环 `while b do c end` 和任何后置 Q，
"**wp(循环, Q) ∧ b**"自动是循环体的不变量。读它的证明：要证体跑一步后
仍满足 wp——即"任何后续循环终点 s'' 都满足 Q"；而原来的 wp 假设加上
`E_WhileTrue`（体这一步 + 剩余循环）恰好能到达 s''，Q 得证。**不变量不是找
出来的，是"从后往前跑一遍语义"算出来的**。59 章装饰程序法里"从后置条件倒推
中间断言"的每一步，本质都是取 wp。

```coq
Theorem hoare_complete : forall P c Q,
  valid_hoare_triple P c Q -> derivable P c Q.
Proof.
  unfold valid_hoare_triple. intros P c.
  generalize dependent P.
  induction c; intros P Q HT.
  - (* skip *)
    eapply H_Consequence.
    + apply H_Skip.
    + intros st HP. exact HP.
    + intros st HP.
      apply (HT st st).
      * apply E_Skip.
      * exact HP.
  - (* := *)
    eapply H_Consequence.
    + apply H_Asgn.
    + intros st HP. unfold assertion_sub.
      apply (HT st (x !-> aeval st a ; st)).
      * apply E_Asgn. reflexivity.
      * exact HP.
    + intros st HQ. exact HQ.
  - (* ; *)
    eapply H_Seq with (Q := wp c2 Q).
    + apply IHc2. apply wp_is_precondition.
    + apply IHc1. unfold wp. intros st st' H1 HP s'' H2.
      apply (HT st s'').
      * apply E_Seq with st'.
        -- exact H1.
        -- exact H2.
      * exact HP.
  - (* if *)
    eapply H_If.
    + apply IHc1. intros st st' H1 [HP Hb].
      apply (HT st st').
      * apply E_IfTrue.
        -- exact Hb.
        -- exact H1.
      * exact HP.
    + apply IHc2. intros st st' H1 [HP Hb].
      apply (HT st st').
      * apply E_IfFalse.
        -- apply not_true_is_false. exact Hb.
        -- exact H1.
      * exact HP.
  - (* while *)
    eapply H_Consequence.
    + eapply H_While.
      * apply IHc. apply wp_invariant.
    + intros st HP. unfold wp. intros s'' Hwhile.
      apply (HT st s'').
      * exact Hwhile.
      * exact HP.
    + intros st [HP Hnb].
      apply (HP st).
      apply E_WhileFalse.
      apply not_true_is_false. exact Hnb.
Qed.
```

**完备性定理**：有效的三元组都可推导。对**命令**归纳（不是对推导——它还不存在），
五个分支就是五棵小推导树：

- **skip**：H_Skip 给出 `{{P}} skip {{P}}`；出口侧用 HT（skip 的终态=初态，
  E_Skip）把 P 换成 Q。**H_Consequence 两条蕴含的次序**：第一条是入口侧
  （P→P'），第二条是出口侧（Q'→Q）。
- **赋值**：H_Asgn 的前置是 `Q [x|->a]`——入口侧的蕴含 `P → Q[x|->a]` 由 HT
  直接给出（赋值的终态恰是替换语义，`unfold assertion_sub` 对齐形状后一次
  apply）。
- **序列**：中间断言取 `wp c2 Q`（wp_seq 的实战版）：第二段用 IHc2 +
  `wp_is_precondition`（wp 本身够用）；第一段的"入口蕴含"要证 `P → wp c2 Q`——
  展开 wp 是"对任何 c1 终点 st'、任何 c2 后续终点 s''，Q s''"——HT 加 E_Seq
  恰好拼出整条路径。
- **if**：两个分支的入口断言各带 `∧b / ∧~b`，用 HT + E_IfTrue/E_IfFalse 重建
  整个 if 的求值；`~ bassertion b st` 到 `beval st b = false` 的翻译用
  `not_true_is_false`（60.1g 的自写小引理——标准库同名引理在 58 章踩过方向坑）。
- **while**：不变量取 `wp W Q`——`wp_invariant` + IHc 一步给出体推导；入口侧
  `P → wp W Q` 就是 HT 本身（wp 的定义）；出口侧 `(wp W Q ∧ ~b) → Q`：~b 让
  循环当场终止（E_WhileFalse，终态=初态），wp 立刻兑现 Q。

至此闭环：60.4 + 60.6 =

> `derivable P c Q  ⟺  valid_hoare_triple P c Q`

公理系统不多证（可靠）、也不漏证（完备）——霍尔逻辑的证明论与模型论**严丝合缝**。

```coq
Print Assumptions hoare_sound.
Print Assumptions hoare_complete.
```

repl 输出（各一行）：

```
Closed under the global context
Closed under the global context
```

**双双零公理**——连完备性都没有付出函数外延的代价（wp 是"点到点"的构造，从不
需要证明两张状态表相等）。对照：62 章 preservation 的 `functional_extensionality_dep`、
56 章 t_update_same 的同款——每个定理的公理账本各查各的。

```coq
End Ex60HoareLogic.
```

### 60.7 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **H_Seq 与 H_Consequence 的前提顺序与直觉相反**（60.2/60.3/60.6）：H_Seq 的
   第一个前提是**第二条命令**的推导；H_Consequence 的第一个前提是子推导、入口
   蕴含在后。写证明按 bullet 顺序对号入座，实测写反报
   `Unable to unify "derivable ?P c1 ?Q" with "derivable (wp c2 Q) c2 Q"`。
2. **skip/赋值分支不能直接 apply 构造子**（60.3）：`apply H_Skip` 试图把全称
   变量 P 统一成 `fun _ => True`，报 `Unable to unify "True" with "P s"`。这类
   "规则前提形状与目标差一层"的情况都是垫 `H_Consequence_pre/post` 的信号。
3. **derivable 是 Type 值归纳**（60.2）：repl 生成 `_ind/_rec/_sind` 三件套
   （Prop 归纳只有 `_ind/_sind`）。`_rec` 的存在意味着推导树可以**计算地**消费
   ——做验证条件生成器、证明检查器时这就是接口。
4. **替换记号左结合**（60.2 sample_proof）：`Q [X|->a] [X|->b]` 是先替换 a 再
   替换 b（外层是 b）——与"从后往前配前置"的顺序一致；手写嵌套 `assertion_sub`
   时两层顺序极易装反（实测报两端替换式无法统一）。
5. **`~ bassertion b st` 与 `beval st b = false` 之间要过桥**（60.6）：E_IfFalse/
   E_WhileFalse 的前提是布尔等式；标准库 `not_true_iff_false` 用 apply-in 会挑
   反方向（58 章坑 5），本章沿用 58 章自写的 `not_true_is_false`。
6. **wp 的量词形态挡住 intros**（60.5/60.6）：`wp c Q st` 是一个定义，`intros
   s'' Hce` 之前必须 `unfold wp`（intro 不做 delta 展开）。漏 unfold 报
   "No such hypothesis / Unexpected name"。
7. **两章的三元组记号同名不同域**（60.1）：58 章 `{{P}} c {{Q}}` 在 hoare_scope、
   52 章 assn 条目里也有 `{{ }}`（assertion_scope）。本章只用前者；混用时
   Locate 先查归属（52 章坑 9 的同族）。
8. **eauto 能证的别手写**（60.2）：H_Consequence_pre/post 的证明体就是一行
   `eauto using H_Consequence`——恒真蕴含（`fun st => Q' st -> Q' st`）搜索机
   自己补。先手写后简化成 eauto 是好习惯，反过来的诱惑（eauto 不行就以为证不了）
   要警惕。

---
上一章：[59 · 装饰程序：不变量的寻找法](59-decorated.md) ｜ 下一章：[61 · 自动化工程：evar 搜索与 hint 数据库](61-automation.md) ｜ 返回：[README](../README.md)
