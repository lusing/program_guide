# 107　Imp 程序的非干扰：TINI、TSNI 与安全多执行

本章研究一个关系性质：**只改变秘密输入，能否改变攻击者可观察的结果？** 我们将完全从零定义状态、Imp 语法和语义，不依赖 SECF，也不依赖本教程其他示例。所有证明均在 `examples/107_imp_noninterference.v` 中由 Rocq 检查。

攻击者的能力需要先固定。每个变量被标成 `public` 或 `secret`；攻击者知道程序，能选择两个公开输入相同的初态，能读取终态中的所有公开变量，但不能直接读秘密变量。后面还会区分攻击者是否能观察“程序没有终止”：TINI 不把这个现象当作观察，TSNI 则把它纳入安全要求。

证明路线依次是：先处理无循环程序的函数式执行器，并证明它与关系语义等价；再用两次执行定义安全多执行（SME），证明安全性与透明性；随后给出 TINI、TSNI 及两者的蕴含关系；最后用具体反例说明 SME 能保证 TINI，却不能保证 TSNI。

## 107.1 全映射、变量标签与公开等价

示例只从 Stdlib 引入算术、布尔值、字符串、`lia` 和函数外延性。函数外延性用于证明“两个逐变量相等的状态是同一个函数”。模块避免名字泄漏到全局命名空间。

```coq
(* 107 Imp 程序的非干扰：TINI、TSNI 与安全多执行 *)

From Stdlib Require Import Arith Bool Strings.String Lia FunctionalExtensionality.

Module Ex107ImpNoninterference.
```

### 状态与更新

全映射对每个字符串都有值，因此读取未初始化变量不需要 `option`。`t_empty v` 是常量映射；`t_update` 只在一个键处改值。两条更新引理分别处理读到同一键和不同键的情况：前者用字符串自反性，后者用 `String.eqb_spec` 做可判定相等性分析。`state` 是自然数值的全映射，单更新记号默认以全零状态为底。

```coq
(* ---------- 107.1 全映射、变量标签与公开等价 ---------- *)

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
  - subst x2. contradiction.
  - reflexivity.
Qed.

Definition state := total_map nat.
Definition empty_st : state := (__ !-> 0).
Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).
```

### 标签与攻击者观察

`LXP` 把 `X` 设为公开，把其余所有变量设为秘密。`LXP_public` 是这个标签图的完整刻画：若某变量公开，它就只能是 `X`。公开等价 `pub_equiv L s1 s2` 表示两个状态在攻击者能读取的每个位置完全相同；秘密位置可以任意不同。对称性在 SME 证明中会反复使用。

```coq
Inductive label : Type :=
  | public
  | secret.
Definition label_map := total_map label.

Definition X : string := "X".
Definition Y : string := "Y".

Definition LXP : label_map := (X !-> public ; __ !-> secret).

Lemma LXPX : LXP X = public.
Proof. reflexivity. Qed.

Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  unfold LXP. intros x Hx.
  destruct (String.eqb_spec x X).
  - subst. reflexivity.
  - rewrite t_update_neq in Hx.
    + discriminate Hx.
    + intro contra. subst. contradiction.
Qed.

Definition pub_equiv (L : label_map) (s1 s2 : state) : Prop :=
  forall x, L x = public -> s1 x = s2 x.

Lemma pub_equiv_sym : forall L s1 s2,
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros L s1 s2 H x Hx.
  symmetry. apply H. exact Hx.
Qed.
```

### 分离与合并状态

`split_state s L public` 保留公开变量并把秘密变量清零，这就是 SME 的“公开运行”输入；传入 `secret` 则做对偶分离。`merge_states ps ss L` 从 `ps` 取公开结果、从 `ss` 取秘密结果。下面的等价定理把“逐公开变量相等”改写成“整个公开投影相等”，后者可通过函数外延性一次性重写。

`pub_equiv_split_state` 说明公开投影没有改动公开观察；`pub_equiv_merge_states` 说明只要两次合并使用同一个公开结果，秘密结果无论如何都不会影响公开观察；`merge_state_pub_equiv` 则说明若公开结果与原秘密运行的公开部分一致，合并会完整还原秘密运行结果。最后两条计算引理直接描述公开投影的逐点行为。

```coq
Definition split_state (s : state) (L : label_map) (l : label) : state :=
  fun x => match L x, l with
           | public, public | secret, secret => s x
           | _, _ => 0
           end.

Definition merge_states (ps ss : state) (L : label_map) : state :=
  fun x => match L x with public => ps x | secret => ss x end.

Definition pub_equiv_split (L : label_map) (s1 s2 : state) : Prop :=
  forall x, split_state s1 L public x = split_state s2 L public x.

Theorem pub_equiv_split_iff : forall L s1 s2,
  pub_equiv L s1 s2 <-> pub_equiv_split L s1 s2.
Proof.
  unfold pub_equiv, pub_equiv_split, split_state.
  intros L s1 s2. split.
  - intros H x. destruct (L x) eqn:Hx.
    + apply H. exact Hx.
    + reflexivity.
  - intros H x Hx. specialize (H x).
    rewrite Hx in H. exact H.
Qed.

Lemma pub_equiv_split_state : forall L s,
  pub_equiv L (split_state s L public) s.
Proof.
  unfold pub_equiv, split_state. intros L s x Hx.
  rewrite Hx. reflexivity.
Qed.

Theorem pub_equiv_merge_states : forall L ps ss1 ss2,
  pub_equiv L (merge_states ps ss1 L) (merge_states ps ss2 L).
Proof.
  unfold pub_equiv, merge_states. intros L ps ss1 ss2 x Hx.
  rewrite Hx. reflexivity.
Qed.

Lemma merge_state_pub_equiv : forall L ss ps,
  pub_equiv L ps ss -> merge_states ps ss L = ss.
Proof.
  unfold pub_equiv, merge_states. intros L ss ps H.
  apply functional_extensionality. intros x.
  destruct (L x) eqn:Hx.
  - apply H. exact Hx.
  - reflexivity.
Qed.

Lemma split_state_public_id : forall s L x,
  L x = public -> split_state s L public x = s x.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.

Lemma split_state_secret_zero : forall s L x,
  L x = secret -> split_state s L public x = 0.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.
```

## 107.2 自包含 Imp：表达式、命令与大步语义

### 抽象语法与记号

算术表达式支持常量、变量、加、截断减和乘；布尔表达式只需要本章用到的常量、相等、否定与合取。命令有空操作、赋值、顺序、条件和循环。两条 coercion 让字符串和数字可直接出现在表达式中；自定义 `com` 条目让 `<{ ... }>` 内的 `:=`、`;`、`if`、`while` 等记号解析成 AST 构造器，而不是 Rocq 自身的运算。

```coq
(* ---------- 107.2 自包含 Imp：表达式、命令与大步语义 ---------- *)

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
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.
Declare Custom Entry com.
Declare Scope com_scope.
Notation "<{ e }>" := e (e custom com) : com_scope.
Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).
Notation "x + y" := (APlus x y)
  (in custom com at level 50, left associativity).
Notation "x - y" := (AMinus x y)
  (in custom com at level 50, left associativity).
Notation "x * y" := (AMult x y)
  (in custom com at level 40, left associativity).
Notation "'true'" := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).
Notation "x = y" := (BEq x y)
  (in custom com at level 70, no associativity).
Notation "'~' b" := (BNot b)
  (in custom com at level 75, right associativity).
Notation "x && y" := (BAnd x y)
  (in custom com at level 80, left associativity).
Notation "'skip'" := CSkip (in custom com at level 0) : com_scope.
Notation "x := y" := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85,
   no associativity) : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity) : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99) : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99) : com_scope.
Open Scope com_scope.
```

### 表达式求值与七条大步规则

`aeval`、`beval` 都是结构递归总函数。命令可能不终止，所以 `ceval c st st'` 是“从 `st` 执行 `c` 能够终止于 `st'`”的归纳关系，而不是一个总求值函数。赋值记录表达式结果；顺序规则用中间状态连接两次求值；条件规则按布尔值选支；循环规则分别处理立即退出和“执行一次循环体后继续循环”。

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
  | <{ a1 = a2 }> => Nat.eqb (aeval st a1) (aeval st a2)
  | <{ ~ b1 }> => negb (beval st b1)
  | <{ b1 && b2 }> => andb (beval st b1) (beval st b2)
  end.

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

### 确定性与永不终止

确定性定理对第一份求值推导归纳，再反演第二份推导。条件/循环两个方向的规则若同时可用，会产生 `true = false` 的矛盾；顺序和真循环分支则用归纳假设统一中间状态。该定理是 SME 安全证明中识别两次“公开运行”的关键。

`loop` 永远执行 `skip`。若它有终止推导，对推导归纳：假守卫分支与 `beval true = true` 矛盾；真守卫分支把同样的不可能性交给剩余循环的归纳假设。

```coq
Theorem ceval_deterministic : forall c st st1 st2,
  st =[ c ]=> st1 -> st =[ c ]=> st2 -> st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2; inversion E2; subst.
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

Definition loop : com := <{ while true do skip end }>.

Theorem loop_never_stops : forall st st', ~ st =[ loop ]=> st'.
Proof.
  intros st st' contra. unfold loop in contra.
  remember <{ while true do skip end }> as loopdef eqn:Heqloopdef.
  induction contra; inversion Heqloopdef.
  - rewrite H1 in H. discriminate H.
  - apply IHcontra2. rewrite H1, H2. reflexivity.
Qed.
```

## 107.3 无循环执行器及其与 `ceval` 的语义等价

### 为什么循环分支只是占位

下面的执行器对命令结构递归，因此 Rocq 能接受它为总函数。它准确实现 `skip`、赋值、顺序和条件，但 `while` 分支直接返回原状态，**不是循环语义**。只有额外假设 `no_whiles c = true` 排除了所有循环后，才能使用这个执行器推理程序行为。

```coq
(* ---------- 107.3 无循环执行器及其与 ceval 的语义等价 ---------- *)

Fixpoint ceval_fun_no_while (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ x := a }> => (x !-> aeval st a ; st)
  | <{ c1 ; c2 }> =>
      let st' := ceval_fun_no_while st c1 in
      ceval_fun_no_while st' c2
  | <{ if b then c1 else c2 end }> =>
      if beval st b then ceval_fun_no_while st c1
      else ceval_fun_no_while st c2
  | <{ while b do c end }> => st
  end.

Fixpoint no_whiles (c : com) : bool :=
  match c with
  | <{ skip }> | <{ _ := _ }> => true
  | <{ c1 ; c2 }> => andb (no_whiles c1) (no_whiles c2)
  | <{ if _ then c1 else c2 end }> => andb (no_whiles c1) (no_whiles c2)
  | <{ while _ do _ end }> => false
  end.
```

### 双向等价与全终止

可靠性方向对 AST 归纳，构造一条大步求值推导；复合命令先把 `andb` 假设拆成两部分，条件命令再按守卫值选规则。完备性方向对求值推导归纳，证明任何终态都恰好是执行器结果；两个循环情形都被 `no_whiles` 的 `false = true` 假设排除。`ceval_fun_no_while_iff` 把两个方向合成等价，`no_whiles_terminating` 则直接由可靠性得到：无循环程序在每个初态上都有终态。

```coq
Theorem ceval_fun_no_while_sound : forall c st,
  no_whiles c = true -> st =[ c ]=> ceval_fun_no_while st c.
Proof.
  induction c as [| x a | c1 IH1 c2 IH2 | b c1 IH1 c2 IH2 | b c IH];
    intros st Hnw; simpl in Hnw; simpl.
  - apply E_Skip.
  - apply E_Asgn. reflexivity.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    eapply E_Seq.
    + apply IH1. exact H1.
    + apply IH2. exact H2.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    destruct (beval st b) eqn:Hb.
    + apply E_IfTrue; [exact Hb | apply IH1; exact H1].
    + apply E_IfFalse; [exact Hb | apply IH2; exact H2].
  - discriminate Hnw.
Qed.

Theorem ceval_fun_no_while_complete : forall c st st',
  st =[ c ]=> st' -> no_whiles c = true ->
  st' = ceval_fun_no_while st c.
Proof.
  intros c st st' Heval.
  induction Heval; intros Hnw; simpl in Hnw; simpl.
  - reflexivity.
  - rewrite H. reflexivity.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    rewrite IHHeval2 by exact H2.
    rewrite IHHeval1 by exact H1. reflexivity.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    rewrite H. apply IHHeval. exact H1.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    rewrite H. apply IHHeval. exact H2.
  - discriminate Hnw.
  - discriminate Hnw.
Qed.

Theorem ceval_fun_no_while_iff : forall c st st',
  no_whiles c = true ->
  (st =[ c ]=> st' <-> st' = ceval_fun_no_while st c).
Proof.
  intros c st st' Hnw. split.
  - intro H. apply ceval_fun_no_while_complete; assumption.
  - intros H. subst st'. apply ceval_fun_no_while_sound. exact Hnw.
Qed.

Theorem no_whiles_terminating : forall c,
  no_whiles c = true -> forall st, exists st', st =[ c ]=> st'.
Proof.
  intros c Hnw st. exists (ceval_fun_no_while st c).
  apply ceval_fun_no_while_sound. exact Hnw.
Qed.
```

### 两种非干扰定义的桥梁

`cinterp` 仅交换执行器参数顺序，使命令可以先给出。函数版非干扰要求公开等价的输入被映成公开等价的输出；关系版 `noninterferent_com` 只量化两份**已经存在**的终止推导。后者就是 TINI。对无循环命令，两个定义通过刚才的可靠性与完备性互相推出：函数到关系时替换两个终态，关系到函数时用可靠性构造所需的两份推导。

```coq
Definition flip {A B C : Type} (f : A -> B -> C) := fun b a => f a b.
Definition cinterp : com -> state -> state := flip ceval_fun_no_while.

Definition noninterferent_no_while (L : label_map) (c : com) : Prop :=
  forall s1 s2, pub_equiv L s1 s2 ->
                pub_equiv L (cinterp c s1) (cinterp c s2).

Definition noninterferent_com (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2',
    pub_equiv L s1 s2 ->
    s1 =[ c ]=> s1' -> s2 =[ c ]=> s2' ->
    pub_equiv L s1' s2'.

Theorem noninterferent_no_while_iff : forall L c,
  no_whiles c = true ->
  (noninterferent_no_while L c <-> noninterferent_com L c).
Proof.
  intros L c Hnw. split.
  - intros H s1 s2 s1' s2' Heq H1 H2.
    pose proof (ceval_fun_no_while_complete _ _ _ H1 Hnw) as H1'.
    pose proof (ceval_fun_no_while_complete _ _ _ H2 Hnw) as H2'.
    unfold noninterferent_no_while, cinterp, flip in H.
    subst s1'. subst s2'. apply H. exact Heq.
  - intros H s1 s2 Heq.
    unfold noninterferent_com in H.
    apply H with (s1 := s1) (s2 := s2); try exact Heq;
      apply ceval_fun_no_while_sound; exact Hnw.
Qed.
```

### 标准练习：安全程序、显式流与隐式流

`secure_ex1` 先改秘密 `Y`，再把公开 `X` 置为常数 `1`，所以公开输出与初态无关。证明展开计算后，由 `LXP_public` 把待检查变量化为 `X`，两边直接相等。

`insecure_com_explicit` 把 `Y * X` 写入 `X`，是秘密到公开的**显式流**。反例取两个初态：公开 `X` 都为 `1`，秘密 `Y` 分别为 `0` 和 `1`，所得公开结果分别为 `0` 和 `1`。这与假定的非干扰矛盾。

`insecure_com_implicit` 没有直接复制秘密，却根据 `Y = 42` 决定是否减少 `X`，属于经控制流泄露的**隐式流**。取 `Y=42` 与 `Y=0`，公开初值都为 `1`，终值分别为 `0` 和 `1`。`insecure_com2` 也是秘密守卫的示例，留到自组合一节。

```coq
Definition secure_ex1 : com := <{ Y := Y - 1 ; X := 1 }>.

Lemma noninterferent_secure_ex1 : noninterferent_no_while LXP secure_ex1.
Proof.
  unfold noninterferent_no_while, secure_ex1, cinterp, flip.
  intros s1 s2 Heq x Hx. apply LXP_public in Hx. subst x.
  reflexivity.
Qed.

Definition insecure_com_explicit : com := <{ X := Y * X ; Y := Y - 1 }>.

Lemma interferent_insecure_com_explicit :
  ~ noninterferent_no_while LXP insecure_com_explicit.
Proof.
  unfold noninterferent_no_while, insecure_com_explicit, cinterp, flip.
  intro Hc.
  set (s1 := (X !-> 1 ; Y !-> 0)).
  set (s2 := (X !-> 1 ; Y !-> 1)).
  assert (Heq : pub_equiv LXP s1 s2).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  specialize (Hc s1 s2 Heq X LXPX).
  unfold s1, s2, t_update in Hc. simpl in Hc.
  discriminate Hc.
Qed.

Definition insecure_com2 : com :=
  <{ if Y = 0 then Y := 42 else X := X + 1 end }>.

Definition insecure_com_implicit : com :=
  <{ if Y = 42 then X := X - 1 else Y := 2 * Y end }>.

Lemma interferent_insecure_com_implicit :
  ~ noninterferent_no_while LXP insecure_com_implicit.
Proof.
  unfold noninterferent_no_while, insecure_com_implicit, cinterp, flip.
  intro Hc.
  set (s1 := (X !-> 1 ; Y !-> 42)).
  set (s2 := (X !-> 1 ; Y !-> 0)).
  assert (Heq : pub_equiv LXP s1 s2).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  specialize (Hc s1 s2 Heq X LXPX).
  unfold s1, s2, t_update in Hc. simpl in Hc.
  discriminate Hc.
Qed.
```

## 107.4 状态变换器 SME 与自组合

### 两次执行与合并

安全多执行（secure multi-execution，SME）对同一个 `f` 运行两次：公开运行只拿到清零秘密后的状态，秘密运行拿到原状态；最终公开变量取公开运行，秘密变量取秘密运行。这样，公开输出从机制上就不可能读取真实秘密。

安全性证明只需注意：两个公开等价的输入具有完全相同的公开投影，所以两个公开运行的结果相同；随后 `pub_equiv_merge_states` 完成证明。透明性表示若 `f` 原本已经非干扰，SME 不改变行为：公开运行与秘密运行的公开结果公开等价，因此合并后恰好还原 `f s`。

```coq
(* ---------- 107.4 状态变换器 SME 与自组合 ---------- *)

Definition sme_state (f : state -> state) (L : label_map) : state -> state :=
  fun s => merge_states (f (split_state s L public)) (f s) L.

Theorem noninterferent_sme_state : forall L f s1 s2,
  pub_equiv L s1 s2 ->
  pub_equiv L (sme_state f L s1) (sme_state f L s2).
Proof.
  unfold sme_state. intros L f s1 s2 Heq.
  apply pub_equiv_split_iff in Heq.
  unfold pub_equiv_split in Heq.
  apply functional_extensionality in Heq. rewrite Heq.
  apply pub_equiv_merge_states.
Qed.

Theorem transparent_sme_state : forall f L,
  (forall s1 s2, pub_equiv L s1 s2 -> pub_equiv L (f s1) (f s2)) ->
  forall s, f s = sme_state f L s.
Proof.
  intros f L Hni s. unfold sme_state. symmetry.
  apply merge_state_pub_equiv. apply Hni. apply pub_equiv_split_state.
Qed.
```

把 `cinterp c` 代入即可得到无循环 Imp 命令的 SME。结果仍是状态变换器，不必是一个新的 Imp 程序。安全性和透明性不再需要逐命令归纳，因为一般状态变换器定理已经完成全部工作。

```coq
Definition sme_no_while (c : com) (L : label_map) : state -> state :=
  sme_state (cinterp c) L.

Theorem noninterferent_sme_no_while : forall c L s1 s2,
  pub_equiv L s1 s2 ->
  pub_equiv L (sme_no_while c L s1) (sme_no_while c L s2).
Proof. intros c L. apply noninterferent_sme_state. Qed.

Theorem transparent_sme_no_while : forall c L,
  noninterferent_no_while L c ->
  forall s, cinterp c s = sme_no_while c L s.
Proof. intros c L Hni. apply transparent_sme_state. exact Hni. Qed.
```

### 合并与更新的计算引理

四条基本引理把更新推到合并之外：公开变量在第一参数上的更新会保留，在第二参数上的更新被丢弃；秘密变量恰好相反。最后一个引理处理两次运行都更新同一秘密变量的情况，保留秘密运行写入的 `v2`。证明都使用函数外延性，再按查询变量是否等于更新变量分情况。

```coq
Lemma merge_states_update_pub_fst : forall L x v s1 s2,
  L x = public ->
  merge_states (x !-> v ; s1) s2 L = (x !-> v ; merge_states s1 s2 L).
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. repeat rewrite t_update_eq. reflexivity.
  - repeat rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_pub_snd : forall L x v s1 s2,
  L x = public ->
  merge_states s1 (x !-> v ; s2) L = merge_states s1 s2 L.
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. reflexivity.
  - rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_sec_fst : forall L x v s1 s2,
  L x = secret ->
  merge_states (x !-> v ; s1) s2 L = merge_states s1 s2 L.
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. reflexivity.
  - rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_sec_snd : forall L x v s1 s2,
  L x = secret ->
  merge_states s1 (x !-> v ; s2) L = (x !-> v ; merge_states s1 s2 L).
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. repeat rewrite t_update_eq. reflexivity.
  - repeat rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_sec : forall L x v1 v2 s1 s2,
  L x = secret ->
  merge_states (x !-> v1 ; s1) (x !-> v2 ; s2) L =
  (x !-> v2 ; merge_states s1 s2 L).
Proof.
  intros L x v1 v2 s1 s2 Hx.
  rewrite merge_states_update_sec_fst by assumption.
  rewrite merge_states_update_sec_snd by assumption. reflexivity.
Qed.
```

### 用自组合写出两次运行

SME 的状态变换器定义不是语法变换，但可以用**自组合**直观表示：把一个程序与自身放进同一个更大的程序，用带 `p` 前缀的变量保存公开运行的副本。

`secure_com2` 的步骤是：先保存公开 `X` 到 `pX`；在原变量上执行 `insecure_com2`，模拟秘密运行；令秘密副本 `pY=0`，在副本上执行同一程序，模拟公开运行；最后 `X:=pX` 只把公开运行的公开结果合并回来。公开运行的 `pY` 必为零，所以它走 `then` 分支，不会执行 `pX:=pX+1`。因此原程序中由秘密条件控制的 `X` 增量被消除。辅助变量无法恢复原值，所以 `psecret` 把 `pX`、`pY` 标为秘密，最终只要求其他变量公开等价。

证明先计算左侧：若原 `Y=0`，秘密运行把 `Y` 改为 `42`；否则合并丢弃公开运行对秘密 `Y` 的修改以及秘密运行对公开 `X` 的修改，得到原状态。再把右侧自组合程序逐步化简，排除公开的辅助变量，按 `Y=0`、变量是否为 `X`/`Y` 分情况即可逐点相等。

```coq
Definition pX : string := "pX".
Definition pY : string := "pY".

Definition secure_com2 : com :=
  <{ pX := X ;
     if Y = 0 then Y := 42 else X := X + 1 end ;
     pY := 0 ;
     if pY = 0 then pY := 42 else pX := pX + 1 end ;
     X := pX }>.

Definition psecret : label_map :=
  (pX !-> secret ; pY !-> secret ; __ !-> public).

Lemma sme_insecure_com2 : forall st,
  pub_equiv psecret (sme_no_while insecure_com2 LXP st)
                    (cinterp secure_com2 st).
Proof.
  intros st.
  assert (HL : sme_no_while insecure_com2 LXP st =
               if Nat.eqb (st Y) 0 then (Y !-> 42 ; st) else st).
  { unfold sme_no_while, sme_state, insecure_com2, cinterp, flip. simpl.
    destruct (Nat.eqb (st Y) 0).
    - rewrite merge_states_update_sec by reflexivity.
      rewrite merge_state_pub_equiv.
      + reflexivity.
      + apply pub_equiv_split_state.
    - rewrite merge_states_update_sec_fst by reflexivity.
      rewrite merge_states_update_pub_snd by reflexivity.
      rewrite merge_state_pub_equiv.
      + reflexivity.
      + apply pub_equiv_split_state. }
  rewrite HL. unfold pub_equiv. intros x Hsec.
  assert (HpXY : x <> pX /\ x <> pY).
  { unfold psecret in Hsec.
    destruct (String.eqb x pX) eqn:HpX.
    - apply String.eqb_eq in HpX. subst x.
      rewrite t_update_eq in Hsec. discriminate.
    - destruct (String.eqb x pY) eqn:HpY.
      + apply String.eqb_eq in HpY. subst x.
        rewrite t_update_neq in Hsec by discriminate.
        rewrite t_update_eq in Hsec. discriminate.
      + apply String.eqb_neq in HpX. apply String.eqb_neq in HpY.
        auto. }
  destruct HpXY as [HpX HpY].
  unfold secure_com2, cinterp, flip. simpl.
  assert (HcY : (pX !-> st X ; st) Y = st Y).
  { apply t_update_neq. discriminate. }
  rewrite HcY.
  destruct (Nat.eqb (st Y) 0); destruct (String.eqb_spec x X);
    destruct (String.eqb_spec x Y); subst;
    repeat rewrite t_update_eq;
    repeat rewrite t_update_neq by congruence;
    reflexivity.
Qed.
```

## 107.5 TINI、关系版 SME 与弱透明性

### TINI 的两个基本练习

对 `X:=X+1`，两次赋值推导的终态公开值分别是两个初值的 `X+1`；初态公开等价使它们相同。对 `X:=Y`，显式构造两份赋值推导，初态只在秘密 `Y` 上分别为 `0`、`1`，终态公开 `X` 因而不同。这再次说明 TINI 是两次执行之间的关系性质，而非单次执行的性质。

```coq
(* ---------- 107.5 TINI、关系版 SME 与弱透明性 ---------- *)

Lemma noninterferent_incX : noninterferent_com LXP <{ X := X + 1 }>.
Proof.
  unfold noninterferent_com, pub_equiv.
  intros s1 s2 s1' s2' Heq H1 H2 x Hx.
  apply LXP_public in Hx. subst x.
  inversion H1; subst. inversion H2; subst. simpl.
  rewrite (Heq X LXPX). reflexivity.
Qed.

Lemma interferent_YtoX_com : ~ noninterferent_com LXP <{ X := Y }>.
Proof.
  unfold noninterferent_com. intro Hc.
  set (s1 := (Y !-> 0)). set (s2 := (Y !-> 1)).
  set (s1' := (X !-> 0 ; s1)). set (s2' := (X !-> 1 ; s2)).
  assert (Heq : pub_equiv LXP s1 s2).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  assert (H1 : s1 =[ X := Y ]=> s1').
  { unfold s1'. apply E_Asgn. reflexivity. }
  assert (H2 : s2 =[ X := Y ]=> s2').
  { unfold s2'. apply E_Asgn. reflexivity. }
  specialize (Hc s1 s2 s1' s2' Heq H1 H2 X LXPX).
  unfold s1', s2' in Hc. repeat rewrite t_update_eq in Hc.
  discriminate Hc.
Qed.
```

### 终止不敏感：一个能泄露“是否终止”却仍满足 TINI 的程序

`termination_leak` 在秘密 `Y=0` 时死循环，否则立即结束。真实攻击者若能观察运行是否结束，就能推断 `Y` 是否为零，这就是**终止通道**。但 TINI 的前提已经给出两个终态及两份终止推导，所以秘密为零的那次执行根本无法提供前提。所有可行的终止推导都走 `else`，最终状态不变，故公开 `X` 保持相等。

这段证明精确展示了“终止不敏感”的名字：它不是宣称终止通道不存在，而是定义中主动忽略没有终态的执行。下面的 TSNI 会补上这个缺口。

```coq
Definition termination_leak : com :=
  <{ if Y = 0 then while true do skip end else skip end }>.

Lemma tini_secure_termination_leak : noninterferent_com LXP termination_leak.
Proof.
  unfold noninterferent_com, termination_leak, pub_equiv.
  intros s1 s2 s1' s2' Heq H1 H2 x Hx.
  apply LXP_public in Hx. subst x. specialize (Heq X LXPX).
  inversion H1; subst.
  - match goal with
    | Hloop : _ =[ while true do skip end ]=> _ |- _ =>
        apply loop_never_stops in Hloop; contradiction
    end.
  - match goal with
    | Hskip : _ =[ skip ]=> _ |- _ => inversion Hskip; subst
    end.
    inversion H2; subst.
    + match goal with
      | Hloop : _ =[ while true do skip end ]=> _ |- _ =>
          apply loop_never_stops in Hloop; contradiction
      end.
    + match goal with
      | Hskip : _ =[ skip ]=> _ |- _ => inversion Hskip; subst
      end. exact Heq.
Qed.
```

### 带循环的关系版 SME

有循环时不能把两次执行写成一个总函数，所以 `sme_com` 是关系：必须存在公开运行终态 `ps` 和秘密运行终态 `ss`，且合并结果等于给定 `s'`。两个 `ceval` 前提都很重要：只要任一运行不终止，就没有 SME 终态。

标准练习 `sme_com_YtoX` 展示泄露程序 `X:=Y` 如何被改写行为。初态只有 `Y=5`。公开运行看到的是 `Y=0`，所以得到 `X=0`；秘密运行得到 `X=5`，但合并公开变量时只采用公开运行的值，最终为 `X=0,Y=5`。证明显式提供两个终态，两份 `E_Asgn` 推导后，用合并更新引理化简。

```coq
Definition sme_com (L : label_map) (c : com) (s s' : state) : Prop :=
  exists ps ss,
    split_state s L public =[ c ]=> ps /\
    s =[ c ]=> ss /\
    merge_states ps ss L = s'.

Lemma sme_com_YtoX :
  sme_com LXP <{ X := Y }> (Y !-> 5) (X !-> 0 ; Y !-> 5).
Proof.
  unfold sme_com.
  exists (X !-> 0 ; split_state (Y !-> 5) LXP public),
         (X !-> 5 ; Y !-> 5).
  split; [| split].
  - apply E_Asgn. reflexivity.
  - apply E_Asgn. reflexivity.
  - assert (HX : LXP X = public) by reflexivity.
    assert (Hpub : merge_states (X !-> 0 ; split_state (Y !-> 5) LXP public)
                                (X !-> 5 ; Y !-> 5) LXP =
                   (X !-> 0 ; merge_states (split_state (Y !-> 5) LXP public)
                                           (Y !-> 5) LXP)).
    { rewrite merge_states_update_pub_fst by exact HX.
      rewrite merge_states_update_pub_snd by exact HX. reflexivity. }
    rewrite Hpub. rewrite merge_state_pub_equiv.
    + reflexivity.
    + apply pub_equiv_split_state.
Qed.
```

### SME 保证 TINI

`noninterferent_com_R` 把同一个二执行定义推广到任意求值关系 `R`。对 `sme_com` 的证明先拆出两次 SME 各自的两份普通执行。初态公开等价意味着公开投影完全相同，因此两个公开运行有相同初态；`ceval_deterministic` 使 `ps1=ps2`。最后合并状态的公开部分只依赖这个共同结果。注意证明不需要假设原命令安全：SME 是对任意命令的强制机制。

```coq
Definition noninterferent_com_R (R : com -> state -> state -> Prop)
  (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2',
    pub_equiv L s1 s2 -> R c s1 s1' -> R c s2 s2' ->
    pub_equiv L s1' s2'.

Theorem noninterferent_com_sme : forall L c,
  noninterferent_com_R (sme_com L) L c.
Proof.
  unfold noninterferent_com_R, sme_com.
  intros L c s1 s2 s1' s2' Heq
    [ps1 [ss1 [H1p [H1s H1m]]]] [ps2 [ss2 [H2p [H2s H2m]]]].
  subst s1'. subst s2'.
  apply pub_equiv_split_iff in Heq. unfold pub_equiv_split in Heq.
  apply functional_extensionality in Heq. rewrite Heq in H1p.
  rewrite (ceval_deterministic _ _ _ _ H1p H2p).
  apply pub_equiv_merge_states.
Qed.
```

### 为什么暂时只有弱透明性

若原命令满足 TINI，且已经有一次 SME 执行，那么原秘密运行与公开运行的终态公开等价，合并结果就是秘密运行终态，所以可还原一条普通执行。这只是 `sme_com -> ceval` 方向。反向不一定成立：原状态上终止，不代表清零秘密后的状态上也终止；例如循环守卫可能因清零而永远为真。因此这里称为弱透明性，下一节用 TSNI 补足反向所需的公开运行。

```coq
Theorem somewhat_transparent_sme_com : forall L c,
  noninterferent_com L c ->
  forall s s', sme_com L c s s' -> s =[ c ]=> s'.
Proof.
  unfold noninterferent_com, sme_com.
  intros L c Hni s s' [ps [ss [Hp [Hs Hm]]]]. subst s'.
  assert (Heq : pub_equiv L s (split_state s L public)).
  { apply pub_equiv_sym. apply pub_equiv_split_state. }
  specialize (Hni s (split_state s L public) ss ps Heq Hs Hp).
  apply pub_equiv_sym in Hni. apply merge_state_pub_equiv in Hni.
  rewrite Hni. exact Hs.
Qed.
```

## 107.6 TSNI、与 TINI 的关系及 SME 全透明性

### 把“另一个运行也必须终止”写入定义

TSNI 只假设第一次执行终止。对任意与初态公开等价的 `s2`，它要求**构造**一个 `s2'`，使第二次执行也终止，并且两个终态公开等价。因此，若秘密变化能让第二次执行不终止，TSNI 直接失败。这正是终止敏感与终止不敏感的差别。

对 `X:=X+1`，第二次执行的终态显式取为 `X:=s2 X+1` 后的状态；公开等价由前面的 TINI 练习给出。

```coq
(* ---------- 107.6 TSNI、与 TINI 的关系及 SME 全透明性 ---------- *)

Definition tsni_com_R (R : com -> state -> state -> Prop)
  (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1',
    R c s1 s1' -> pub_equiv L s1 s2 ->
    exists s2', R c s2 s2' /\ pub_equiv L s1' s2'.

Lemma tsni_incX : tsni_com_R ceval LXP <{ X := X + 1 }>.
Proof.
  unfold tsni_com_R. intros s1 s2 s1' H1 Heq.
  exists (X !-> s2 X + 1 ; s2). split.
  - apply E_Asgn. reflexivity.
  - eapply noninterferent_incX.
    + exact Heq.
    + exact H1.
    + apply E_Asgn. reflexivity.
Qed.
```

对终止泄露程序，取 `Y=1` 的初态作为第一次运行，它走 `else` 并终止；再取公开等价的 `Y=0` 初态。若 TSNI 成立，就必须给出后者的终止推导。反演该推导：真分支包含不可能的 `loop` 终止，假分支又与 `Y=0` 的守卫计算矛盾。因此该程序满足 TINI 却不满足 TSNI，严格区分两种安全概念。

```coq
Lemma tsni_insecure_termination_leak :
  ~ tsni_com_R ceval LXP termination_leak.
Proof.
  unfold tsni_com_R, termination_leak. intros Hc.
  specialize (Hc (X !-> 0 ; Y !-> 1) (X !-> 0 ; Y !-> 0)
                 (X !-> 0 ; Y !-> 1)).
  assert (HH : (X !-> 0 ; Y !-> 1) =[
                   if Y = 0 then while true do skip end else skip end
               ]=> (X !-> 0 ; Y !-> 1)).
  { apply E_IfFalse; [reflexivity | apply E_Skip]. }
  specialize (Hc HH). clear HH.
  assert (Heq : pub_equiv LXP (X !-> 0 ; Y !-> 1) (X !-> 0 ; Y !-> 0)).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  specialize (Hc Heq). destruct Hc as [s2' [Hc _]].
  inversion Hc; subst.
  - apply loop_never_stops in H5. contradiction.
  - simpl in H4. discriminate.
Qed.
```

### TSNI 推出 TINI，反向需要全终止

TSNI 推出 TINI：给定 TINI 的两份终止推导，TSNI 从第一份构造另一份公开等价的终止推导；由 `ceval` 确定性，这个新终态就是 TINI 已给的 `s2'`，于是公开等价得证。`noninterferent_not_tsni` 用刚才的终止泄露程序证明反向普遍蕴含不成立。

若额外假设程序在**每个**初态上终止，则 TSNI 所需的 `s2'` 可由全终止假设直接取得，再用 TINI 得到公开等价。因此“全终止 + TINI ⇒ TSNI”。无循环程序的 `no_whiles_terminating` 正可提供这类前提。

```coq
Lemma tsni_noninterferent : forall L c,
  tsni_com_R ceval L c -> noninterferent_com_R ceval L c.
Proof.
  unfold noninterferent_com_R, tsni_com_R.
  intros L c Htsni s1 s2 s1' s2' Heq H1 H2.
  specialize (Htsni s1 s2 s1' H1 Heq).
  destruct Htsni as [s2'' [H2' Heq']].
  rewrite (ceval_deterministic _ _ _ _ H2 H2'). exact Heq'.
Qed.

Lemma noninterferent_not_tsni :
  ~ (forall L c, noninterferent_com_R ceval L c -> tsni_com_R ceval L c).
Proof.
  intros H. apply tsni_insecure_termination_leak.
  apply H. exact tini_secure_termination_leak.
Qed.

Lemma terminating_noninterferent_tsni : forall L c,
  (forall s, exists s', s =[ c ]=> s') ->
  noninterferent_com_R ceval L c -> tsni_com_R ceval L c.
Proof.
  unfold noninterferent_com_R, tsni_com_R.
  intros L c Hterm Hni s1 s2 s1' H1 Heq.
  destruct (Hterm s2) as [s2' H2]. exists s2'. split.
  - exact H2.
  - apply Hni with (s1 := s1) (s2 := s2); assumption.
Qed.
```

### TSNI 让 SME 完全透明

正向从普通执行到 SME：TSNI 把原状态与它的公开投影看作两个公开等价初态，于是由秘密运行的终止推出公开运行也终止且终态公开等价；二者合并还原原终态。反向从 SME 到普通执行：TSNI 给出另一条公开运行，确定性把它与 SME 已有公开运行统一，再由公开等价化简合并。于是 TSNI 程序的普通执行与 SME 执行具有完全相同的关系，不再有弱透明性的方向缺失。

```coq
Theorem tsni_transparent_sme_com : forall L c,
  tsni_com_R ceval L c ->
  forall s s', s =[ c ]=> s' <-> sme_com L c s s'.
Proof.
  unfold tsni_com_R, sme_com.
  intros L c Hni s s'.
  assert (Heq : pub_equiv L s (split_state s L public)).
  { apply pub_equiv_sym. apply pub_equiv_split_state. }
  split.
  - intros H. specialize (Hni s (split_state s L public) s' H Heq).
    destruct Hni as [ps [Hp Hpub]].
    exists ps, s'. split; [exact Hp |]. split; [exact H |].
    apply merge_state_pub_equiv. apply pub_equiv_sym. exact Hpub.
  - intros [ps [ss [Hp [Hs Hm]]]]. subst s'.
    specialize (Hni s (split_state s L public) ss Hs Heq).
    destruct Hni as [ps' [Hp' Hpub]].
    rewrite (ceval_deterministic _ _ _ _ Hp Hp').
    apply pub_equiv_sym in Hpub. apply merge_state_pub_equiv in Hpub.
    rewrite Hpub. exact Hs.
Qed.
```

## 107.7 反例：`sme_com` 仍不强制 TSNI

SME 保证的是公开终态的 TINI，并不自动保证 TSNI。反例命令先执行 `while Y=1 do skip end`，终止后再把 `X` 置为 `1`。两个初态 `s1`、`s2` 的公开 `X` 都为零，秘密 `Y` 分别为零和一：`s1` 不进入循环，`s2` 永远循环。

`counter_s2_loops` 先证明更一般的 `NSTOP`：只要状态中的 `Y=1`，该循环就没有终止推导。假守卫分支会把 `Y=1` 代入守卫并得到矛盾；真循环分支的循环体是 `skip`，状态不变，所以剩余推导仍满足归纳假设的条件。再反演顺序命令，就把整个 `counter` 的不终止归结为 `NSTOP`。结合 `s1` 的终止推导，立得原命令不满足 TSNI。

```coq
(* ---------- 107.7 反例：sme_com 仍不强制 TSNI ---------- *)

Section TSNICounter.

Definition counter : com := <{ while Y = 1 do skip end ; X := 1 }>.
Definition s1 : state := (X !-> 0 ; Y !-> 0).
Definition s2 : state := (X !-> 0 ; Y !-> 1).
Definition s1' : state := (X !-> 1 ; s1).

Lemma counter_s1_terminates_s1' : s1 =[ counter ]=> s1'.
Proof.
  unfold counter, s1, s1'. eapply E_Seq.
  - apply E_WhileFalse. reflexivity.
  - apply E_Asgn. reflexivity.
Qed.

Lemma counter_s2_loops : forall s2', ~ s2 =[ counter ]=> s2'.
Proof.
  unfold counter. intros s2' Hcontra.
  assert (NSTOP : forall s s', s Y = 1 ->
    s =[ while Y = 1 do skip end ]=> s' -> False).
  { clear. intros s s' HY Heval.
    remember <{ while Y = 1 do skip end }> as loopdef eqn:Heqloopdef.
    generalize dependent HY.
    induction Heval; try discriminate Heqloopdef.
    - intros HY. injection Heqloopdef as Hb Hc. subst b. subst c.
      simpl in H. rewrite HY in H. discriminate H.
    - intros HY. injection Heqloopdef as Hb Hc. subst b. subst c.
      inversion Heval1; subst. eapply IHHeval2; eauto. }
  inversion Hcontra; subst. eapply NSTOP in H1; eauto.
Qed.

Lemma initial_pub_equiv : pub_equiv LXP s1 s2.
Proof.
  unfold s1, s2, pub_equiv. intros x Hx.
  apply LXP_public in Hx. subst x. reflexivity.
Qed.

Lemma not_tsni_counter : ~ tsni_com_R ceval LXP counter.
Proof.
  intros Htsni. unfold tsni_com_R in Htsni.
  specialize (Htsni _ _ _ counter_s1_terminates_s1' initial_pub_equiv).
  destruct Htsni as [s2' [H _]]. eapply counter_s2_loops. eassumption.
Qed.
```

关键观察是 SME 也救不了这个终止差异。`s1` 的所有秘密变量本来已经是零，所以它的公开投影等于自身；公开运行和秘密运行都终止于 `s1'`，二者合并也是 `s1'`。相反，`sme_com` 的定义要求秘密运行也必须有终态，而 `s2` 的秘密运行就是原来不可能终止的运行，所以 SME 在 `s2` 上也没有终态。

于是，若 `sme_com` 满足 TSNI，它就会从 `s1` 的 SME 终止执行为公开等价的 `s2` 构造一个 SME 终态，与上一事实矛盾。这个反例说明：SME 隔离了公开**值**对秘密的依赖，却没有消除秘密对两次运行**是否同时产生终态**的影响。最后的 `End` 分别关闭反例 section 和全章模块。

```coq
Lemma sme_counter_s1_terminates_s1' : sme_com LXP counter s1 s1'.
Proof.
  unfold sme_com. exists s1', s1'. split; [| split].
  - assert (Hsplit : split_state s1 LXP public = s1).
    { apply functional_extensionality. intros x.
      destruct (LXP x) eqn:Hx.
      - apply split_state_public_id. exact Hx.
      - rewrite split_state_secret_zero by exact Hx.
        unfold s1. symmetry.
        destruct (String.eqb_spec X x).
        + subst x. apply t_update_eq.
        + rewrite t_update_neq by assumption.
          destruct (String.eqb_spec Y x).
          * subst x. apply t_update_eq.
          * rewrite t_update_neq by assumption. reflexivity. }
    rewrite Hsplit. apply counter_s1_terminates_s1'.
  - apply counter_s1_terminates_s1'.
  - apply functional_extensionality. intros x.
    unfold merge_states, LXP.
    destruct ((X !-> public ; __ !-> secret) x); reflexivity.
Qed.

Lemma sme_counter_s2_loops : forall s2', ~ sme_com LXP counter s2 s2'.
Proof.
  unfold sme_com. intros s2' [ps [ss [Hp [Hs Hm]]]].
  eapply counter_s2_loops. eassumption.
Qed.

Lemma not_tsni_sme_com : ~ tsni_com_R (sme_com LXP) LXP counter.
Proof.
  intros Htsni. unfold tsni_com_R in Htsni.
  specialize (Htsni _ _ _ sme_counter_s1_terminates_s1' initial_pub_equiv).
  destruct Htsni as [s2' [H _]]. eapply sme_counter_s2_loops. eassumption.
Qed.

End TSNICounter.

End Ex107ImpNoninterference.
```

至此得到完整的关系图：TSNI 总推出 TINI；TINI 只有在额外全终止条件下才推出 TSNI；SME 对任意命令保证 TINI，对 TINI 命令只有弱透明性，对 TSNI 命令则完全透明，但 SME 本身仍不保证 TSNI。
