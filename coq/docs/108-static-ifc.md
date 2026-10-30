# 108. 静态信息流控制：显式流、隐式流与终止通道

对应示例：`../examples/108_static_ifc.v`。本章用一个只依赖 Stdlib 的自包含开发，从 Imp 大步语义一直证明到三套静态系统的安全定理。标签 `public` 表示可公开观察，`secret` 表示秘密；`pub_equiv` 表示两个状态在所有公开变量上相同。

三种“安全”必须区分：

- **显式流**是秘密值直接流向公开变量，例如 `X := Y`，其中 `Y` 秘密、`X` 公开。
- **隐式流**是秘密条件影响公开变量，例如 `if Y = 0 then X := 0 else X := 1 end`。即使两个分支各自只写常量，执行哪个分支仍泄漏 `Y`。
- **终止通道**是秘密条件决定程序是否终止。TINI（termination-insensitive noninterference）只比较已经终止的两次运行，TSNI（termination-sensitive noninterference）还要求一次运行终止时，公开等价的另一次运行也终止。

本章的层次是 `cf_wt ⇒ ts_wt(public pc) ⇒ ni_wt`。CF 禁止秘密分支，最强也最容易证明；NI 用 `pc` 标签允许秘密分支但禁止其中的公开写入；TS 在 NI 基础上限制循环，使公开 `pc` 下的推导同时蕴含 TINI 与等终止性，从而蕴含 TSNI。

---

## 108.1 全映射、状态与 Imp 表达式

示例只导入算术、布尔和字符串库。模块避免名字污染，`Set Default Goal Selector "!"` 要求证明脚本明确聚焦目标。

```coq
(* 108 静态信息流控制：显式流、隐式流与终止通道 *)
(* 自包含形式化：只使用 Stdlib，不导入 SECF。 *)

From Stdlib Require Import Arith.Arith Bool.Bool Strings.String.
From Stdlib Require Import Arith.EqNat. Import Nat.

Module Ex108StaticIFC.
Set Default Goal Selector "!".
```

### 全映射与状态

状态是从变量名到自然数的全映射，而不是有限关联表。这样任何变量都有默认值，更新也只是函数：`t_update m x v` 在 `x` 处返回 `v`，其他位置保持 `m`。两条引理分别证明更新后读取同一变量和不同变量的结果；`String.eqb_spec` 把布尔字符串比较反射为相等或不等命题。

```coq
(* ---------- 108.1 全映射、状态与 Imp 表达式 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).
Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Lemma t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst. contradiction.
  - reflexivity.
Qed.

Definition state := total_map nat.
```

### 表达式语法与求值

算术表达式有常量、变量、加、减、乘；布尔表达式有常量、比较、否定和合取。`X`、`Y`、`Z` 是后文反复使用的变量名。 coercion 让字符串和自然数可直接出现在表达式中，自定义 `com` 条目及 `<{ ... }>` 记号则让 Imp 程序保持通常的书写形式。

```coq
Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BNeq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BGt (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

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
   f constr at level 0, x constr at level 1, y constr at level 1).
Notation "x + y" := (APlus x y)
  (in custom com at level 50, left associativity).
Notation "x - y" := (AMinus x y)
  (in custom com at level 50, left associativity).
Notation "x * y" := (AMult x y)
  (in custom com at level 40, left associativity).
Notation "'true'" := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).
Notation "x <= y" := (BLe x y)
  (in custom com at level 70, no associativity).
Notation "x > y" := (BGt x y)
  (in custom com at level 70, no associativity).
Notation "x = y" := (BEq x y)
  (in custom com at level 70, no associativity).
Notation "x <> y" := (BNeq x y)
  (in custom com at level 70, no associativity).
Notation "x && y" := (BAnd x y)
  (in custom com at level 80, left associativity).
Notation "'~' b" := (BNot b)
  (in custom com at level 75, right associativity).
Open Scope com_scope.
```

`aeval` 和 `beval` 都是结构递归函数。比较操作最终落到 Stdlib 的自然数布尔比较；`BNeq` 与 `BGt` 分别是否定相等和小于等于。表达式求值总终止，真正需要关系语义的是带循环的命令。

```coq
Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | <{ a1 + a2 }> => aeval st a1 + aeval st a2
  | <{ a1 - a2 }> => aeval st a1 - aeval st a2
  | <{ a1 * a2 }> => aeval st a1 * aeval st a2
  end.

Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | <{ true }> => true
  | <{ false }> => false
  | <{ a1 = a2 }> => aeval st a1 =? aeval st a2
  | <{ a1 <> a2 }> => negb (aeval st a1 =? aeval st a2)
  | <{ a1 <= a2 }> => aeval st a1 <=? aeval st a2
  | <{ a1 > a2 }> => negb (aeval st a1 <=? aeval st a2)
  | <{ ~ b1 }> => negb (beval st b1)
  | <{ b1 && b2 }> => andb (beval st b1) (beval st b2)
  end.
```

---

## 108.2 命令、大步语义与确定性

命令包括空操作、赋值、顺序、条件和循环。大步关系 `st =[ c ]=> st'` 表示从 `st` 执行 `c` 可终止于 `st'`；不终止的循环没有任何推导。这一点正是 TINI 会忽略不终止运行的原因。

```coq
(* ---------- 108.2 命令、大步语义与确定性 ---------- *)

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'" := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y" := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85,
   no associativity, format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity,
   format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
   format "'[v' 'if' x 'then' '/ ' y '/' 'else' '/ ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
   format "'[v' 'while' x 'do' '/ ' y '/' 'end' ']'") : com_scope.

Reserved Notation "st0 '=[' c ']=>' st1"
  (at level 40, c custom com at level 99,
   st0 constr, st1 constr at next level).

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      st =[ skip ]=> st
  | E_Asgn : forall st a n x,
      aeval st a = n ->
      st =[ x := a ]=> (x !-> n ; st)
  | E_Seq : forall c1 c2 st st' st'',
      st =[ c1 ]=> st' ->
      st' =[ c2 ]=> st'' ->
      st =[ c1 ; c2 ]=> st''
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
      st =[ c ]=> st' ->
      st' =[ while b do c end ]=> st'' ->
      st =[ while b do c end ]=> st''

where "st0 =[ c ]=> st1" := (ceval c st0 st1).
```

确定性证明对第一条求值推导归纳，再反演第二条。赋值中表达式是确定函数；顺序和真循环用归纳假设先识别中间状态，再识别最终状态；真假规则冲突时，同一个布尔值不可能既为 `true` 又为 `false`。该引理稍后用于证明 TSNI 的两个等价表述。

```coq
Theorem ceval_deterministic : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2. generalize dependent st2.
  induction E1; intros st2 E2; inversion E2; subst.
  - reflexivity.
  - reflexivity.
  - rewrite (IHE1_1 st'0 H1) in *. apply IHE1_2. assumption.
  - apply IHE1. assumption.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - apply IHE1. assumption.
  - reflexivity.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *. apply IHE1_2. assumption.
Qed.
```

---

## 108.3 标签、公开等价、TINI 与 TSNI

安全标签只有两级。`label_eqb` 是可计算的相等测试，`label_eqb_eq`、`label_eqb_neq` 和反射引理把它与命题层相等连接，供布尔类型检查器的可靠性和完备性证明使用。

```coq
(* ---------- 108.3 标签、公开等价、TINI 与 TSNI ---------- *)

Inductive label : Type :=
  | public
  | secret.

Definition label_map := total_map label.

Definition label_eqb (l1 l2 : label) : bool :=
  match l1, l2 with
  | public, public | secret, secret => true
  | _, _ => false
  end.

Declare Scope label_scope.
Infix "=?" := label_eqb : label_scope.
Delimit Scope label_scope with label.
Open Scope label_scope.

Lemma label_eqb_eq : forall {l1 l2 : label},
  (l1 =? l2) = true <-> l1 = l2.
Proof.
  intros [|] [|]; split; intros H; try reflexivity; discriminate H.
Qed.

Lemma label_eqb_spec : forall l1 l2 : label,
  reflect (l1 = l2) (l1 =? l2).
Proof.
  intros [|] [|]; constructor; (reflexivity || discriminate).
Qed.

Lemma label_eqb_neq : forall {l1 l2 : label},
  (l1 =? l2) = false <-> l1 <> l2.
Proof.
  intros l1 l2. destruct (label_eqb_spec l1 l2) as [Heq | Hneq].
  - split.
    + intros H. discriminate H.
    + intros H. exfalso. apply H. apply Heq.
  - split.
    + intros _. apply Hneq.
    + intros _. reflexivity.
Qed.
```

`pub_equiv L s1 s2` 只要求公开变量一致，秘密变量可任意不同。自反、对称、传递三条小引理让后面的证明可以像使用等价关系一样拼接公开等价。

```coq
Definition pub_equiv (L : label_map) (s1 s2 : state) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall (L : label_map) (s : state),
  pub_equiv L s s.
Proof. intros L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall (L : label_map) (s1 s2 : state),
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof. unfold pub_equiv. intros L s1 s2 H x Px. rewrite H; auto. Qed.

Lemma pub_equiv_trans : forall (L : label_map) (s1 s2 s3 : state),
  pub_equiv L s1 s2 ->
  pub_equiv L s2 s3 ->
  pub_equiv L s1 s3.
Proof.
  unfold pub_equiv. intros L s1 s2 s3 H12 H23 x Px.
  rewrite H12; try rewrite H23; auto.
Qed.
```

TINI 对两次**都已给出终止推导**的运行作结论，因此秘密决定是否终止不在其观测范围内。TSNI 则采用单向形式：给定左边一次终止运行和公开等价的右初态，必须存在右边一次终止运行且终态公开等价。由于定义对任意 `s1`、`s2` 对称量化，这个单向形式已经包含另一方向。

```coq
Definition noninterferent_com (L : label_map) (c : com) :=
  forall s1 s2 s1' s2',
    pub_equiv L s1 s2 ->
    s1 =[ c ]=> s1' ->
    s2 =[ c ]=> s2' ->
    pub_equiv L s1' s2'.

Definition tsni_com_R (R : com -> state -> state -> Prop) L c :=
  forall s1 s2 s1',
    R c s1 s1' ->
    pub_equiv L s1 s2 ->
    exists s2', R c s2 s2' /\ pub_equiv L s1' s2'.

Definition tsni_com := tsni_com_R ceval.
```

---

## 108.4 `join` 与表达式标签

### 标签半格

`join` 取两个标签的上界：只要一个输入秘密，结果就是秘密；`public` 是单位元。交换律、结合律、幂等律及单位/吸收引理都通过有限的标签分情况证明。最重要的是 `join_public_iff`：复合表达式要公开，两个组成部分必须都公开。

```coq
(* ---------- 108.4 join 与表达式标签 ---------- *)

Definition join (l1 l2 : label) : label :=
  match l1 with
  | public => l2
  | secret => secret
  end.

Lemma join_public_iff : forall {l1 l2},
  join l1 l2 = public <-> l1 = public /\ l2 = public.
Proof.
  intros [|] [|]; split; intros H; try discriminate H;
    try destruct H; auto.
Qed.

Lemma join_commutative : forall {l1 l2},
  join l1 l2 = join l2 l1.
Proof. intros l1 l2. destruct l1; destruct l2; reflexivity. Qed.

Lemma join_assoc : forall {l1 l2 l3},
  join l1 (join l2 l3) = join (join l1 l2) l3.
Proof. intros l1 l2 l3. destruct l1; reflexivity. Qed.

Lemma join_idem : forall {l}, join l l = l.
Proof. intros [|]; reflexivity. Qed.

Lemma join_public : forall {l1 l2},
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros l1 l2 H. apply join_public_iff. apply H. Qed.

Lemma join_public_l : forall {l}, join public l = l.
Proof. reflexivity. Qed.

Lemma join_public_r : forall {l}, join l public = l.
Proof. intros l. rewrite join_commutative. reflexivity. Qed.

Lemma join_secret_l : forall {l}, join secret l = secret.
Proof. reflexivity. Qed.

Lemma join_secret_r : forall {l}, join l secret = secret.
Proof. intros l. rewrite join_commutative. reflexivity. Qed.
```

### 算术表达式标签与显式信息流基础

常量公开，变量继承标签，二元运算取 `join`。`label_of_aexp` 是同一规则的递归计算版本。可靠性说明计算结果确实可推导，唯一性说明任何推导的标签都等于计算结果，因此以后可以在关系推导和布尔检查之间转换。

```coq
Reserved Notation "L '|-a-' a \in l" (at level 40).

Inductive aexp_has_label (L : label_map) : aexp -> label -> Prop :=
  | T_Num : forall n,
      L |-a- ANum n \in public
  | T_Id : forall x,
      L |-a- AId x \in L x
  | T_Plus : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-a- <{ a1 + a2 }> \in join l1 l2
  | T_Minus : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-a- <{ a1 - a2 }> \in join l1 l2
  | T_Mult : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-a- <{ a1 * a2 }> \in join l1 l2

where "L '|-a-' a '\in' l" := (aexp_has_label L a l).

Fixpoint label_of_aexp (L : label_map) (a : aexp) : label :=
  match a with
  | ANum n => public
  | AId x => L x
  | <{ a1 + a2 }>
  | <{ a1 - a2 }>
  | <{ a1 * a2 }> => join (label_of_aexp L a1) (label_of_aexp L a2)
  end.

Lemma label_of_aexp_sound : forall L a,
  L |-a- a \in label_of_aexp L a.
Proof. intros L a. induction a; constructor; eauto. Qed.

Lemma label_of_aexp_unique : forall L a l,
  L |-a- a \in l ->
  l = label_of_aexp L a.
Proof.
  intros L a l H. induction H; simpl in *; subst; auto.
Qed.
```

`noninterferent_exp` 是表达式层的非干涉：公开表达式在公开等价状态下求值相同。证明对标签推导归纳。变量情形直接使用公开等价；运算情形由 `join ... = public` 得到两个子表达式均公开，再用归纳假设重写。若表达式含秘密变量，其标签必为秘密，故该定理不承诺其值相同。

```coq
Theorem noninterferent_exp : forall {L s1 s2 a},
  pub_equiv L s1 s2 ->
  L |-a- a \in public ->
  aeval s1 a = aeval s2 a.
Proof.
  intros L s1 s2 a Heq Ht. remember public as l.
  induction Ht; simpl.
  - reflexivity.
  - apply Heq. apply Heql.
  - destruct (join_public Heql) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public Heql) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public Heql) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
Qed.
```

### 布尔表达式标签与非干涉

布尔标签沿用同样思想：比较合并两个算术表达式标签，否定保持标签，合取取上界。唯一性证明显式列出七种推导形状，并利用算术标签唯一性完成比较分支。

```coq
Reserved Notation "L '|-b-' b \in l" (at level 40).

Inductive bexp_has_label (L : label_map) : bexp -> label -> Prop :=
  | T_True : L |-b- <{ true }> \in public
  | T_False : L |-b- <{ false }> \in public
  | T_Eq : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 = a2 }> \in join l1 l2
  | T_Neq : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 <> a2 }> \in join l1 l2
  | T_Le : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 <= a2 }> \in join l1 l2
  | T_Gt : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 > a2 }> \in join l1 l2
  | T_Not : forall b l,
      L |-b- b \in l ->
      L |-b- <{ ~ b }> \in l
  | T_And : forall b1 l1 b2 l2,
      L |-b- b1 \in l1 ->
      L |-b- b2 \in l2 ->
      L |-b- <{ b1 && b2 }> \in join l1 l2

where "L '|-b-' b '\in' l" := (bexp_has_label L b l).

Fixpoint label_of_bexp (L : label_map) (b : bexp) : label :=
  match b with
  | <{ true }> | <{ false }> => public
  | <{ a1 = a2 }>
  | <{ a1 <> a2 }>
  | <{ a1 <= a2 }>
  | <{ a1 > a2 }> => join (label_of_aexp L a1) (label_of_aexp L a2)
  | <{ ~ b1 }> => label_of_bexp L b1
  | <{ b1 && b2 }> => join (label_of_bexp L b1) (label_of_bexp L b2)
  end.

Lemma label_of_bexp_sound : forall L b,
  L |-b- b \in label_of_bexp L b.
Proof.
  intros L b. induction b; constructor;
    eauto using label_of_aexp_sound.
Qed.

Lemma label_of_bexp_unique : forall L b l,
  L |-b- b \in l ->
  l = label_of_bexp L b.
Proof.
  intros L a l H.
  induction H as [ | | a1 l1 a2 l2 H1 H2
                     | a1 l1 a2 l2 H1 H2
                     | a1 l1 a2 l2 H1 H2
                     | a1 l1 a2 l2 H1 H2
                     | b l H1
                     | b1 l1 b2 l2 H1 H2];
    try apply label_of_aexp_unique in H1;
    try apply label_of_aexp_unique in H2; subst; reflexivity.
Qed.
```

公开布尔表达式同样在公开等价状态下同值。四种比较直接调用 `noninterferent_exp`；否定用归纳假设；合取先由公开 `join` 拆成两个公开前提。这个引理是后续证明“公开条件下两次运行走同一分支”的关键。

```coq
Theorem noninterferent_bexp : forall {L s1 s2 b},
  pub_equiv L s1 s2 ->
  L |-b- b \in public ->
  beval s1 b = beval s2 b.
Proof.
  intros L s1 s2 b Heq Ht. remember public as l.
  induction Ht; simpl; try reflexivity;
    try (destruct (join_public Heql) as [H1 H2];
         rewrite H1 in *; rewrite H2 in *).
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (IHHt Heql). reflexivity.
  - rewrite (IHHt1 Logic.eq_refl).
    rewrite (IHHt2 Logic.eq_refl). reflexivity.
Qed.
```

---

## 108.5 `can_flow` 与禁止秘密分支的 CF 系统

`can_flow la lx` 表示信息能否从源标签 `la` 流向目标标签 `lx`。唯一禁止的是 `secret → public`；秘密写入秘密、公开写入公开以及公开写入秘密都允许。`can_flow_true_iff` 给出逻辑刻画，`can_flow_secret_l` 则说秘密上下文若能流动，目标必为秘密。

```coq
(* ---------- 108.5 can_flow 与禁止秘密分支的 CF 系统 ---------- *)

Definition can_flow (la lx : label) : bool :=
  match la, lx with
  | secret, public => false
  | _, _ => true
  end.

Lemma can_flow_true_iff : forall {l1 l2},
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2.
      * discriminate H.
      * reflexivity.
  - intros [H | H]; subst.
    + reflexivity.
    + destruct l1; reflexivity.
Qed.

Lemma can_flow_secret_l : forall {l},
  can_flow secret l = true -> l = secret.
Proof.
  intros l H. destruct l.
  - discriminate H.
  - reflexivity.
Qed.

Lemma can_flow_refl : forall {l}, can_flow l l = true.
Proof. intros [|]; reflexivity. Qed.

Lemma can_flow_trans : forall {l1 l2 l3},
  can_flow l1 l2 = true ->
  can_flow l2 l3 = true ->
  can_flow l1 l3 = true.
Proof.
  intros l1 l2 l3 H12 H23.
  destruct l1; destruct l2; simpl in *; auto. discriminate H12.
Qed.
```

CF（control-flow）系统是最保守的一层：赋值检查显式流，而 `if`、`while` 的条件必须公开。因此秘密条件根本不能包围任何分支体，即使分支体只写秘密变量也会被拒绝。递归检查器用 `&&` 组合子检查结果，与推导规则一一对应。

```coq
Reserved Notation "L '|-cf-' c" (at level 40).

Inductive cf_well_typed (L : label_map) : com -> Prop :=
  | CFWT_Com : L |-cf- <{ skip }>
  | CFWT_Asgn : forall x a la,
      L |-a- a \in la ->
      can_flow la (L x) = true ->
      L |-cf- <{ x := a }>
  | CFWT_Seq : forall c1 c2,
      L |-cf- c1 ->
      L |-cf- c2 ->
      L |-cf- <{ c1 ; c2 }>
  | CFWT_If : forall b c1 c2,
      L |-b- b \in public ->
      L |-cf- c1 ->
      L |-cf- c2 ->
      L |-cf- <{ if b then c1 else c2 end }>
  | CFWT_While : forall b c1,
      L |-b- b \in public ->
      L |-cf- c1 ->
      L |-cf- <{ while b do c1 end }>

where "L '|-cf-' c" := (cf_well_typed L c).

Fixpoint cf_type_checker (L : label_map) (c : com) : bool :=
  match c with
  | <{ skip }> => true
  | <{ x := a }> => can_flow (label_of_aexp L a) (L x)
  | <{ c1 ; c2 }> => cf_type_checker L c1 && cf_type_checker L c2
  | <{ if b then c1 else c2 end }> =>
      (label_of_bexp L b =? public) &&
      cf_type_checker L c1 && cf_type_checker L c2
  | <{ while b do c1 end }> =>
      (label_of_bexp L b =? public) && cf_type_checker L c1
  end.
```

可靠性把 `true` 转成推导：拆解 `andb_true_iff`，用标签计算的可靠性补足表达式前提。完备性采取逆否形式：若检查器为 `false`，假设存在推导并归纳它，必与某个失败的检查矛盾；表达式标签唯一性排除了“同一表达式另有标签”的可能。两条合起来说明检查器精确实现了这套静态规则，而不是只给出了一个可靠但不完整的测试。

```coq
Lemma cf_type_checker_sound : forall L c,
  cf_type_checker L c = true ->
  L |-cf- c.
Proof.
  intros L c. induction c; simpl in *; econstructor;
    try rewrite andb_true_iff in *; try tauto;
    eauto using label_of_aexp_sound, label_of_bexp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; try tauto.
    destruct H1 as [H11 H12]. apply label_eqb_eq in H11.
    rewrite <- H11. apply label_of_bexp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; tauto.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. apply label_of_bexp_sound.
Qed.

Lemma cf_type_checker_complete : forall L c,
  cf_type_checker L c = false ->
  ~(L |-cf- c).
Proof.
  intros L c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *;
    try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; eauto. rewrite andb_false_iff in H.
    destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_bexp_unique in H0. congruence.
  - destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_bexp_unique in H0. congruence.
Qed.
```

---

## 108.6 状态更新引理与 CF 的 TINI 主定理

公开等价在赋值后的保持分三种情况：两边写入同一个公开值，公开等价保持；仅一侧秘密更新，公开变量不受影响；两侧写不同秘密值，公开等价仍保持。证明通过变量名是否等于更新位置来化简 `t_update`。

```coq
(* ---------- 108.6 状态更新引理与 CF 的 TINI 主定理 ---------- *)

Lemma pub_equiv_update_same : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  pub_equiv L (x !-> v ; s1) (x !-> v ; s2).
Proof.
  intros L s1 s2 x v Heq y Hy. unfold t_update.
  rewrite (Heq y Hy). reflexivity.
Qed.

Lemma pub_equiv_update_secret_l : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L (x !-> v ; s1) s2.
Proof.
  intros L s1 s2 x v Heq Hx y Hy.
  assert (Hxy : x <> y).
  { intro Hc. subst. rewrite Hy in Hx. discriminate Hx. }
  rewrite (t_update_neq _ _ _ _ _ Hxy). apply Heq. apply Hy.
Qed.

Lemma pub_equiv_update_secret_r : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L s1 (x !-> v ; s2).
Proof.
  intros L s1 s2 x v Heq Hx. apply pub_equiv_sym.
  apply pub_equiv_update_secret_l.
  - apply pub_equiv_sym. apply Heq.
  - apply Hx.
Qed.

Lemma pub_equiv_update_secret : forall L s1 s2 x v1 v2,
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L (x !-> v1 ; s1) (x !-> v2 ; s2).
Proof.
  intros L s1 s2 x v1 v2 Heq Hx.
  apply pub_equiv_update_secret_l.
  - apply pub_equiv_update_secret_r.
    + apply Heq.
    + apply Hx.
  - apply Hx.
Qed.
```

CF 的 TINI 对左侧求值归纳，同时反演右侧求值和 CF 推导。赋值时，若表达式公开，则两个右值相同；若目标秘密，则公开等价与写入值无关。顺序用归纳假设传递中间状态的公开等价。由于所有条件和循环条件公开，两侧不可能走不同真假分支；冲突情形都由 `noninterferent_bexp` 排除，合法情形直接调用归纳假设。

```coq
Theorem cf_well_typed_noninterferent : forall L c,
  L |-cf- c ->
  noninterferent_com L c.
Proof.
  intros L c Hwt s1 s2 s1' s2' Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  induction Heval1; intros s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - assumption.
  - apply can_flow_true_iff in H8.
    destruct H8 as [Hla | Hx].
    + rewrite Hla in H7. rewrite (noninterferent_exp Heq H7).
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - eapply IHHeval1_2; try eassumption.
    eapply IHHeval1_1; eassumption.
  - eapply IHHeval1; eassumption.
  - rewrite (noninterferent_bexp Heq H10) in H.
    rewrite H in H5. discriminate H5.
  - rewrite (noninterferent_bexp Heq H10) in H.
    rewrite H in H5. discriminate H5.
  - eapply IHHeval1; eassumption.
  - assumption.
  - rewrite (noninterferent_bexp Heq H9) in H.
    rewrite H in H2. discriminate H2.
  - rewrite (noninterferent_bexp Heq H7) in H.
    rewrite H in H4. discriminate H4.
  - eapply IHHeval1_2; try eassumption.
    eapply IHHeval1_1; eassumption.
Qed.
```

---

## 108.7 静态过近似：安全程序也会被拒绝

`LXP` 只把 `X` 标成公开，其他变量（包括 `Y`、`Z`）都是秘密。`LXP_public` 证明公开变量名只能是 `X`，所以之后证明 TINI 时只需关注 `X`。

```coq
(* ---------- 108.7 静态过近似：安全程序也会被拒绝 ---------- *)

Definition LXP : label_map := (X !-> public ; __ !-> secret).

Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  unfold LXP. intros x Hx.
  destruct (String.eqb_spec x X).
  - subst. reflexivity.
  - rewrite t_update_neq in Hx.
    + simpl in Hx. discriminate.
    + intro contra. subst. contradiction.
Qed.
```

下面程序有秘密条件，且真分支还有 `secret → public` 的显式流，但它在语义上安全：若 `Y=0`，真分支把 `Y`（也就是 0）写入 `X`；否则写入常量 0。因此两条路径终态的 `X` 都是 0。`secure_despite_flows_X_zero` 反演求值并把 `Nat.eqb` 的 `true` 转为数值等式；TINI 随后立即成立。

```coq
Definition secure_despite_flows : com :=
  <{ if Y = 0 then X := Y else X := 0 end }>.

Lemma secure_despite_flows_X_zero : forall s s',
  s =[ secure_despite_flows ]=> s' -> s' X = 0.
Proof.
  unfold secure_despite_flows. intros s s' H.
  inversion H; subst; clear H.
  - inversion H6; subst. simpl. rewrite t_update_eq.
    simpl in H5. apply Nat.eqb_eq in H5. apply H5.
  - inversion H6; subst. simpl. rewrite t_update_eq. reflexivity.
Qed.

Example secure_despite_flows_noninterferent :
  noninterferent_com LXP secure_despite_flows.
Proof.
  unfold noninterferent_com, pub_equiv.
  intros s1 s2 s1' s2' H H1 H2 x Hx.
  apply LXP_public in Hx. subst.
  apply secure_despite_flows_X_zero in H1. rewrite H1.
  apply secure_despite_flows_X_zero in H2. rewrite H2.
  reflexivity.
Qed.
```

尽管如此，CF 检查器计算为 `false`，由完备性可知绝无 CF 推导。这不是检查器实现失误，而是静态过近似的必然表现：规则只看语法和标签，不做“秘密值在该分支必为 0”的值分析。可靠静态分析宁可拒绝安全程序，也不能接受不安全程序。

```coq
Example secure_despite_flows_not_cf :
  ~(LXP |-cf- secure_despite_flows).
Proof. apply cf_type_checker_complete. reflexivity. Qed.
```

---

## 108.8 `pc` 标签与 NI 系统

### 用 `pc` 阻止隐式流

NI 给每条命令推导增加程序计数器标签 `pc`，表示当前控制流上下文是否依赖秘密。赋值不只检查表达式标签 `la`，而检查 `join pc la`：若 `pc=secret`，即使右值公开，也只能写秘密变量。进入 `if` 或 `while` 的分支体时，`pc` 提升为 `join pc l`。

顺序组合的两个子命令使用原来的 `pc`，不是把前一段的 `pc` 一路带下去。这体现控制流汇合：秘密 `if` 结束后，后续命令不再处于该分支上下文，可重新写公开变量。

```coq
(* ---------- 108.8 pc 标签与 NI 系统 ---------- *)

Reserved Notation "L ';;' pc '|-ni-' c" (at level 40).

Inductive ni_well_typed (L : label_map) : label -> com -> Prop :=
  | NIWT_Com : forall pc,
      L ;; pc |-ni- <{ skip }>
  | NIWT_Asgn : forall pc x a la,
      L |-a- a \in la ->
      can_flow (join pc la) (L x) = true ->
      L ;; pc |-ni- <{ x := a }>
  | NIWT_Seq : forall pc c1 c2,
      L ;; pc |-ni- c1 ->
      L ;; pc |-ni- c2 ->
      L ;; pc |-ni- <{ c1 ; c2 }>
  | NIWT_If : forall pc b l c1 c2,
      L |-b- b \in l ->
      L ;; join pc l |-ni- c1 ->
      L ;; join pc l |-ni- c2 ->
      L ;; pc |-ni- <{ if b then c1 else c2 end }>
  | NIWT_While : forall pc b l c1,
      L |-b- b \in l ->
      L ;; join pc l |-ni- c1 ->
      L ;; pc |-ni- <{ while b do c1 end }>

where "L ';;' pc '|-ni-' c" := (ni_well_typed L pc c).
```

NI 检查器与规则结构相同，无需单独检查条件公开；条件标签只用于提升分支的 `pc`。可靠性由 `andb_true_iff` 和表达式标签可靠性完成，完备性仍按假定推导归纳并用标签唯一性制造矛盾。

```coq
Fixpoint ni_type_checker (L : label_map) (pc : label) (c : com) : bool :=
  match c with
  | <{ skip }> => true
  | <{ x := a }> => can_flow (join pc (label_of_aexp L a)) (L x)
  | <{ c1 ; c2 }> => ni_type_checker L pc c1 && ni_type_checker L pc c2
  | <{ if b then c1 else c2 end }> =>
      ni_type_checker L (join pc (label_of_bexp L b)) c1 &&
      ni_type_checker L (join pc (label_of_bexp L b)) c2
  | <{ while b do c1 end }> =>
      ni_type_checker L (join pc (label_of_bexp L b)) c1
  end.

Lemma ni_type_checker_sound : forall L pc c,
  ni_type_checker L pc c = true ->
  L ;; pc |-ni- c.
Proof.
  intros L pc c. generalize dependent pc.
  induction c; intros pc H; simpl in *; econstructor;
    try rewrite andb_true_iff in *;
    try destruct H; try tauto;
    eauto using label_of_aexp_sound, label_of_bexp_sound.
Qed.

Lemma ni_type_checker_complete : forall L pc c,
  ni_type_checker L pc c = false ->
  ~(L ;; pc |-ni- c).
Proof.
  intros L pc c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *; try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
Qed.
```

### 秘密上下文运行不改变公开状态

`secret_run` 是 NI 主证明的核心：秘密 `pc` 下的任何终止执行，初态与终态公开等价。赋值规则中 `join secret la=secret`，可流动目标必为秘密；其他构造由归纳假设和公开等价传递完成。于是，即使秘密条件让两侧执行不同代码，两次运行也都只改变秘密状态，可以用 `different_code` 拼接终态公开等价。

```coq
Lemma secret_run : forall L c s s',
  L ;; secret |-ni- c ->
  s =[ c ]=> s' ->
  pub_equiv L s s'.
Proof.
  intros L c s s' Hwt Heval. induction Heval; inversion Hwt;
    subst; eauto using pub_equiv_trans, pub_equiv_refl.
  - apply pub_equiv_update_secret_r.
    + apply pub_equiv_refl.
    + rewrite join_secret_l in H4. apply can_flow_secret_l. apply H4.
Qed.

Corollary different_code : forall L c1 c2 s1 s2 s1' s2',
  L ;; secret |-ni- c1 ->
  L ;; secret |-ni- c2 ->
  pub_equiv L s1 s2 ->
  s1 =[ c1 ]=> s1' ->
  s2 =[ c2 ]=> s2' ->
  pub_equiv L s1' s2'.
Proof.
  intros L c1 c2 s1 s2 s1' s2' Hwt1 Hwt2 Hequiv Heval1 Heval2.
  eapply secret_run in Hwt1; [| eassumption].
  eapply secret_run in Hwt2; [| eassumption].
  apply pub_equiv_sym in Hwt1.
  eapply pub_equiv_trans; try eassumption.
  eapply pub_equiv_trans; eassumption.
Qed.
```

NI 的 TINI 与 CF 证明相似，但多了秘密条件下的不同步情况：条件公开时仍用表达式非干涉排除真假冲突；条件秘密时两个分支的 `pc` 都是秘密，调用 `different_code`，无需两侧执行同一分支。循环一侧零次、另一侧至少一次时，也分别把执行看作 `skip` 和 `c ; while ...`，再用 `different_code`。这正说明 `pc` 为什么能阻止隐式流：分支选择可以不同，但秘密上下文中公开观测不能改变。

```coq
Theorem ni_well_typed_noninterferent : forall L pc c,
  L ;; pc |-ni- c ->
  noninterferent_com L c.
Proof.
  intros L pc c Hwt s1 s2 s1' s2' Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent pc.
  induction Heval1; intros pc Hwt s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - assumption.
  - apply can_flow_true_iff in H9. destruct H9 as [Hla | Hx].
    + apply join_public in Hla. destruct Hla as [_ Hla]. subst.
      rewrite (noninterferent_exp Heq H8).
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
  - eapply IHHeval1; eassumption.
  - destruct l.
    + rewrite (noninterferent_bexp Heq H11) in H.
      rewrite H in H5. discriminate H5.
    + repeat rewrite join_secret_r in *.
      eapply different_code with (c1 := c1) (c2 := c2); eassumption.
  - destruct l.
    + rewrite (noninterferent_bexp Heq H11) in H.
      rewrite H in H5. discriminate H5.
    + repeat rewrite join_secret_r in *.
      eapply different_code with (c1 := c2) (c2 := c1); eassumption.
  - eapply IHHeval1; eassumption.
  - assumption.
  - destruct l.
    + rewrite (noninterferent_bexp Heq H10) in H.
      rewrite H in H2. discriminate H2.
    + repeat rewrite join_secret_r in *.
      eapply different_code
        with (c1 := <{ skip }>) (c2 := <{ c ; while b do c end }>);
        repeat (try eassumption; try econstructor).
  - destruct l.
    + rewrite (noninterferent_bexp Heq H8) in H.
      rewrite H in H4. discriminate H4.
    + repeat rewrite join_secret_r in *.
      eapply different_code
        with (c1 := <{ c ; while b do c end }>) (c2 := <{ skip }>);
        repeat (try eassumption; try econstructor).
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
Qed.
```

汇合示例中，秘密条件控制秘密变量 `Z`，随后公开变量 `X` 被写成常量 42。NI 接受它，CF 因秘密 `if` 拒绝它。顺序规则恢复公开 `pc` 很重要：若把秘密 `pc` 永久泄漏到后续命令，连最后这条安全的 `X := 42` 也会被误拒绝。

```coq
Definition pc_rejoin_secure : com :=
  <{ if Y = 0 then Z := 0 else skip end ; X := 42 }>.

Example pc_rejoin_secure_ni :
  LXP ;; public |-ni- pc_rejoin_secure.
Proof. apply ni_type_checker_sound. reflexivity. Qed.

Example pc_rejoin_secure_not_cf :
  ~(LXP |-cf- pc_rejoin_secure).
Proof. apply cf_type_checker_complete. reflexivity. Qed.
```

---

## 108.9 TS 系统、等终止与 TSNI 主定理

### 把 TSNI 拆成 TINI 与等终止性

`pub_equiv_equiterminating` 表示：给定一次终止运行，任何公开等价的初态也存在一次终止运行；它暂不要求终态等价。`tsni_alt` 把这个性质与 TINI 合取。

两个 TSNI 表述等价。正方向从 TSNI 得到右侧运行，TINI 部分再用确定性识别给定右终态与存在性构造的右终态；反方向先由等终止性找到右运行，再由 TINI 得到终态公开等价。

```coq
(* ---------- 108.9 TS 系统、等终止与 TSNI 主定理 ---------- *)

Definition pub_equiv_equiterminating (L : label_map) (c : com) :=
  forall s1 s1',
    s1 =[ c ]=> s1' ->
    forall s2, pub_equiv L s1 s2 ->
    exists s2', s2 =[ c ]=> s2'.

Definition tsni_alt (L : label_map) (c : com) :=
  noninterferent_com L c /\ pub_equiv_equiterminating L c.

Lemma tsni_com_tsni_alt_same : forall L c,
  tsni_com L c <-> tsni_alt L c.
Proof.
  unfold tsni_com, tsni_com_R, tsni_alt. split.
  - intros H. split.
    + unfold noninterferent_com.
      intros s1 s2 s1' s2' PEQ E1 E2.
      eapply H in E1; eauto. destruct E1 as [s2'' [E2' PEQ']].
      eapply ceval_deterministic in E2; eauto. subst. eauto.
    + unfold pub_equiv_equiterminating. intros s1 s1' E1 s2 PEQ1.
      eapply H in E1; eauto. destruct E1 as [s2' [E2 PEQ2]].
      eexists. eassumption.
  - intros [NI EQT] s1 s2 s1' E1 PEQ.
    specialize (EQT s1 s1' E1 s2 PEQ). destruct EQT as [s2' E].
    specialize (NI s1 s2 s1' s2' PEQ E1 E).
    exists s2'. split; auto.
Qed.
```

### TS 规则与检查器

TS 的赋值、顺序、条件规则与 NI 相同，唯一实质变化在循环：循环只能在公开 `pc` 下推导，循环条件必须公开，循环体也在公开 `pc` 下检查。因此秘密 `if` 中不能出现循环，秘密条件也不能直接控制循环。

这正对应公开 `pc` 与终止敏感性的关系。仅有 NI 时，秘密上下文虽不能写公开变量，却能选择是否进入不终止循环；TINI 看不出差别，TSNI 能看出。TS 排除这种结构，并保证公开条件在公开等价状态下同值，从而让两侧循环同步。

```coq
Reserved Notation "L ';;' pc '|-ts-' c" (at level 40).

Inductive ts_well_typed (L : label_map) : label -> com -> Prop :=
  | TSWT_Com : forall pc,
      L ;; pc |-ts- <{ skip }>
  | TSWT_Asgn : forall pc x a la,
      L |-a- a \in la ->
      can_flow (join pc la) (L x) = true ->
      L ;; pc |-ts- <{ x := a }>
  | TSWT_Seq : forall pc c1 c2,
      L ;; pc |-ts- c1 ->
      L ;; pc |-ts- c2 ->
      L ;; pc |-ts- <{ c1 ; c2 }>
  | TSWT_If : forall pc b l c1 c2,
      L |-b- b \in l ->
      L ;; join pc l |-ts- c1 ->
      L ;; join pc l |-ts- c2 ->
      L ;; pc |-ts- <{ if b then c1 else c2 end }>
  | TSWT_While : forall b c1,
      L |-b- b \in public ->
      L ;; public |-ts- c1 ->
      L ;; public |-ts- <{ while b do c1 end }>

where "L ';;' pc '|-ts-' c" := (ts_well_typed L pc c).

Fixpoint ts_type_checker (L : label_map) (pc : label) (c : com) : bool :=
  match c with
  | <{ skip }> => true
  | <{ x := a }> => can_flow (join pc (label_of_aexp L a)) (L x)
  | <{ c1 ; c2 }> => ts_type_checker L pc c1 && ts_type_checker L pc c2
  | <{ if b then c1 else c2 end }> =>
      ts_type_checker L (join pc (label_of_bexp L b)) c1 &&
      ts_type_checker L (join pc (label_of_bexp L b)) c2
  | <{ while b do c1 end }> =>
      match pc with
      | public => (label_of_bexp L b =? public) && ts_type_checker L public c1
      | secret => false
      end
  end.
```

TS 检查器可靠性中，循环先分解 `pc`：秘密情形的 `false` 不可能等于 `true`；公开情形拆出公开条件与可检查的循环体。完备性中，循环检查失败要么是条件不公开，与推导的唯一标签矛盾，要么是循环体失败，与归纳假设矛盾。因此这套额外终止限制也被检查器完整实现。

```coq
Lemma ts_type_checker_sound : forall L pc c,
  ts_type_checker L pc c = true ->
  L ;; pc |-ts- c.
Proof.
  intros L pc c. generalize dependent pc.
  induction c; intros pc H; simpl in H.
  - constructor.
  - econstructor; eauto using label_of_aexp_sound.
  - rewrite andb_true_iff in H. destruct H as [H1 H2].
    econstructor; eauto.
  - rewrite andb_true_iff in H. destruct H as [H1 H2].
    econstructor; eauto using label_of_bexp_sound.
  - destruct pc; simpl in H; [| discriminate].
    rewrite andb_true_iff in H. destruct H as [Hb Hc].
    apply label_eqb_eq in Hb. econstructor.
    + rewrite <- Hb. apply label_of_bexp_sound.
    + eauto.
Qed.

Lemma ts_type_checker_complete : forall L pc c,
  ts_type_checker L pc c = false ->
  ~(L ;; pc |-ts- c).
Proof.
  intros L pc c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *; try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
  - destruct H as [Hb | Hbody].
    + rewrite label_eqb_neq in Hb.
      apply label_of_bexp_unique in H0. congruence.
    + eauto.
Qed.
```

TS 推导逐规则映射到 NI 推导，循环的公开条件也是合法的 NI 条件，且 `join public public=public`。所以 TS 立即继承 NI 的 TINI；这里只需公开顶层 `pc` 是定理陈述的使用方式，实际蕴含证明对任意相同 `pc` 都成立。

```coq
Theorem ts_well_typed_ni_well_typed : forall L c pc,
  L ;; pc |-ts- c ->
  L ;; pc |-ni- c.
Proof.
  intros L c pc H. induction H; econstructor; eassumption.
Qed.

Theorem ts_well_typed_noninterferent : forall L c,
  L ;; public |-ts- c ->
  noninterferent_com L c.
Proof.
  intros L c H. apply ts_well_typed_ni_well_typed in H.
  apply ni_well_typed_noninterferent in H. apply H.
Qed.
```

### 秘密 TS 上下文必然终止

在秘密 `pc` 下，TS 根本没有循环规则可用，而其余构造都终止：赋值直接构造求值，顺序拼接两个归纳结果，秘密 `if` 根据当前状态的条件值选择已经构造出的相应分支。这里不需要求左右状态等价；引理对每个单独状态成立。它补上了 NI 所缺的终止保证。

```coq
Lemma ts_secret_run_terminating : forall L c s,
  L ;; secret |-ts- c ->
  exists s', s =[ c ]=> s'.
Proof.
  intros L c s Hwt. remember secret as l.
  generalize dependent s. induction Hwt; intro s.
  - eexists. econstructor.
  - eexists. econstructor. reflexivity.
  - destruct (IHHwt1 Heql s) as [s' IH1].
    destruct (IHHwt2 Heql s') as [s'' IH2].
    eexists. econstructor; eassumption.
  - rewrite Heql in *. rewrite join_secret_l in *.
    destruct (IHHwt1 Logic.eq_refl s) as [s1 IH1].
    destruct (IHHwt2 Logic.eq_refl s) as [s2 IH2].
    destruct (beval s b) eqn:Heq; eexists; econstructor; eassumption.
  - discriminate Heql.
Qed.
```

等终止主定理对左侧求值归纳。顺序与真循环中，先为第一个子运行找到右侧运行，再用已经证明的 TINI 得到中间状态公开等价，最后应用第二个归纳假设。公开 `if` 两侧条件同值，走同一分支；秘密 `if` 用 `ts_secret_run_terminating` 为右状态实际执行的分支构造终止推导。公开 `while` 的零次情形由条件非干涉保证右侧也立即退出，真循环则同步执行一轮并继续。

```coq
Theorem ts_wt_pub_equiv_equiterminating : forall L c,
  L ;; public |-ts- c ->
  pub_equiv_equiterminating L c.
Proof.
  intros L C Hwt s1 s1' Heval.
  induction Heval; intros s2 Heq; inversion Hwt; subst.
  - eexists. constructor.
  - eexists. econstructor. reflexivity.
  - destruct (IHHeval1 H2 _ Heq) as [s2' IH1].
    assert (Heq' : pub_equiv L st' s2').
    { eapply ts_well_typed_noninterferent;
        [| eassumption | eassumption | eassumption]. assumption. }
    destruct (IHHeval2 H3 _ Heq') as [s2'' IH2].
    eexists. econstructor; eassumption.
  - rewrite join_public_l in *. destruct l.
    + destruct (IHHeval H5 _ Heq) as [s2' IH1].
      eexists. apply E_IfTrue; [| eassumption].
      * eapply noninterferent_bexp in Heq; [| eassumption]. congruence.
    + eapply ts_secret_run_terminating in H5. destruct H5 as [s1' H5].
      eapply ts_secret_run_terminating in H6. destruct H6 as [s2' H6].
      destruct (beval s2 b) eqn:Heq2; eexists; econstructor; eassumption.
  - rewrite join_public_l in *. destruct l.
    + destruct (IHHeval H6 _ Heq) as [s2' IH1].
      eexists. apply E_IfFalse; [| eassumption].
      * eapply noninterferent_bexp in Heq; [| eassumption]. congruence.
    + eapply ts_secret_run_terminating in H5. destruct H5 as [s1' H5].
      eapply ts_secret_run_terminating in H6. destruct H6 as [s2' H6].
      destruct (beval s2 b) eqn:Heq2; eexists; econstructor; eassumption.
  - eapply noninterferent_bexp in Heq; [| eassumption].
    eexists. apply E_WhileFalse. congruence.
  - destruct (IHHeval1 H3 _ Heq) as [s2' IH1].
    assert (Heq' : pub_equiv L st' s2').
    { eapply ts_well_typed_noninterferent;
        [| eassumption | eassumption | eassumption]. assumption. }
    destruct (IHHeval2 Hwt _ Heq') as [s2'' IH2].
    eapply noninterferent_bexp in Heq; [| eassumption].
    eexists. eapply E_WhileTrue; try congruence; eassumption.
Qed.
```

最后把 TINI 与等终止性打包，再由 `tsni_com_tsni_alt_same` 转回单一 TSNI 定义。这个主定理同时覆盖终态公开值与“是否终止”的观测。

```coq
Corollary ts_well_typed_tsni : forall L c,
  L ;; public |-ts- c ->
  tsni_com L c.
Proof.
  intros L c Hwt. apply tsni_com_tsni_alt_same. split.
  - apply ts_well_typed_noninterferent. assumption.
  - eapply ts_wt_pub_equiv_equiterminating. assumption.
Qed.
```

---

## 108.10 CF ⇒ TS(public) ⇒ NI 与终止通道

CF 推导可直接嵌入公开 `pc` 的 TS：CF 条件和循环条件都公开，所以提升后的 `pc` 仍是公开；其余规则逐构造成立。结合上节即得 CF 程序也满足 TSNI。第二个箭头 `ts_wt(public pc) ⇒ ni_wt` 已由 `ts_well_typed_ni_well_typed` 给出，因此三层关系完整闭合。

```coq
(* ---------- 108.10 CF ⇒ TS(public) ⇒ NI 与终止通道 ---------- *)

Theorem cf_well_typed_ts_well_typed : forall L c,
  L |-cf- c ->
  L ;; public |-ts- c.
Proof.
  intros L c H. induction H; econstructor; eassumption.
Qed.

Corollary cf_well_typed_tsni : forall L c,
  L |-cf- c ->
  tsni_com L c.
Proof.
  intros L c H. apply ts_well_typed_tsni.
  apply cf_well_typed_ts_well_typed. assumption.
Qed.
```

终止泄漏程序在 `Y=0` 时进入死循环，否则立即终止。NI 接受它：两个分支在秘密 `pc` 下都不写公开变量，所以 TINI 成立；但一旦左边给出 `else skip` 的终止运行，右边若 `Y=0` 就没有任何终止推导，故它不是 TSNI。TS 检查器因秘密分支中出现 `while` 而返回 `false`，由完备性可知 TS 拒绝它。

这说明 NI 与 TS 的差别不是重复限制显式/隐式赋值，而是专门关闭终止通道；也说明为什么 TS 主定理必须以公开顶层 `pc` 为核心，并要求秘密上下文无循环。

```coq
Definition termination_leak : com :=
  <{ if Y = 0 then while true do skip end else skip end }>.

Example termination_leak_ni :
  LXP ;; public |-ni- termination_leak.
Proof. apply ni_type_checker_sound. reflexivity. Qed.

Example termination_leak_not_ts :
  ~(LXP ;; public |-ts- termination_leak).
Proof. apply ts_type_checker_complete. reflexivity. Qed.

End Ex108StaticIFC.
```

至此，示例没有借助任何未证公理：状态、Imp、标签、公开等价、TINI、TSNI 全部自包含；CF、NI、TS 的检查器可靠/完备及三套安全证明均形成闭合证明链。最关键的设计取舍也均有形式化反例支撑：CF 的过近似、NI 对隐式流的 `pc` 防护，以及 TS 对终止通道的额外限制。
