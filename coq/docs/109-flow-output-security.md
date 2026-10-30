# 超越终态：控制流轨迹与公开输出安全

本章在一个只依赖 Rocq 标准库的微型 Imp 语言中，分别形式化三种“秘密不影响公开观察”的性质：

| 性质 | 两次执行的公开观察 | 本章定义 |
| --- | --- | --- |
| 终止不敏感非干扰（终态 NI） | 终止后的公开变量 | `noninterferent`、`output_noninterferent` |
| 控制流安全 | 每次 `if`/`while` 判断产生的布尔轨迹 | `cf_secure` |
| 输出安全 | `output` 产生的自然数序列 | `output_secure` |

三次比较都从**公开等价**的初态出发，并只对给定的两次终止执行作结论。因此，这里的终态 NI 是终止不敏感的：它不讨论一方不终止、另一方终止的情形。三种性质也不能互相替代。本章会构造“终态 NI 成立但控制流不安全”“控制流安全但终态 NI 不成立”“终态 NI 成立但输出不安全”的完整反例。

随后给出两类静态检查：`cf_well_typed` 直接禁止秘密条件，同时保证终态 NI 与控制流安全；`oni_well_typed` 用程序上下文标签 `pc` 跟踪隐式流，同时保证终态 NI 与输出安全。所有定义和证明都包含在下文，不需要查阅其他章节。

## 1. 基础语言与状态

只导入标准库的字符串、列表、算术、布尔和线性算术模块。`Set Default Goal Selector "!"` 要求 tactic 明确聚焦目标，避免复杂证明中误改其他子目标。

```coq
From Stdlib Require Import Strings.String.
From Stdlib Require Import Lists.List.
From Stdlib Require Import Arith.Arith.
From Stdlib Require Import Bool.Bool.
From Stdlib Require Import Lia.
Import ListNotations.
Open Scope string_scope.
Set Warnings "-notation-overridden,-parsing".
Set Default Goal Selector "!".
```

状态是从变量名到自然数的函数，空状态把每个变量映射为 `0`。`t_update` 是函数式更新；两个引理分别说明读取刚更新的变量得到新值，读取不同变量保持原值。第二个证明把 `x <> y` 转成 `String.eqb x y = false` 后化简。

```coq
Definition state := string -> nat.
Definition empty_state : state := fun _ => 0.
Definition t_update (st : state) (x : string) (v : nat) : state :=
  fun y => if String.eqb x y then v else st y.
Lemma t_update_eq : forall st x v,
  t_update st x v x = v.
Proof.
  intros. unfold t_update. rewrite String.eqb_refl. reflexivity.
Qed.
Lemma t_update_neq : forall st x v y,
  x <> y -> t_update st x v y = st y.
Proof.
  intros. unfold t_update. apply String.eqb_neq in H. rewrite H. reflexivity.
Qed.

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".
```

本章约定 `X` 是公开变量，`Y`、`Z` 在示例标签表中通常是秘密变量。算术表达式支持常量、变量、加、截断减和乘；布尔表达式支持常量、比较、否定和合取。两个求值函数完全由当前状态决定。

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
Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | APlus a1 a2 => aeval st a1 + aeval st a2
  | AMinus a1 a2 => aeval st a1 - aeval st a2
  | AMult a1 a2 => aeval st a1 * aeval st a2
  end.
Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | BTrue => true
  | BFalse => false
  | BEq a1 a2 => Nat.eqb (aeval st a1) (aeval st a2)
  | BNeq a1 a2 => negb (Nat.eqb (aeval st a1) (aeval st a2))
  | BLe a1 a2 => Nat.leb (aeval st a1) (aeval st a2)
  | BGt a1 a2 => negb (Nat.leb (aeval st a1) (aeval st a2))
  | BNot b => negb (beval st b)
  | BAnd b1 b2 => andb (beval st b1) (beval st b2)
  end.
```

普通命令语法和 `ceval` 大步语义是标准的：赋值直接更新为表达式值；顺序组合经过中间状态；条件命令选择求值所指示的分支；循环规则分别对应退出和“执行一次循环体后继续循环”。这些规则只描述终态，还不记录分支或输出。

```coq
Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).
Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      ceval CSkip st st
  | E_Asgn : forall st a x,
      ceval (CAsgn x a) st (t_update st x (aeval st a))
  | E_Seq : forall c1 c2 st st' st'',
      ceval c1 st st' -> ceval c2 st' st'' ->
      ceval (CSeq c1 c2) st st''
  | E_IfTrue : forall st st' b c1 c2,
      beval st b = true -> ceval c1 st st' ->
      ceval (CIf b c1 c2) st st'
  | E_IfFalse : forall st st' b c1 c2,
      beval st b = false -> ceval c2 st st' ->
      ceval (CIf b c1 c2) st st'
  | E_WhileFalse : forall b st c,
      beval st b = false -> ceval (CWhile b c) st st
  | E_WhileTrue : forall st st' st'' b c,
      beval st b = true -> ceval c st st' ->
      ceval (CWhile b c) st' st'' -> ceval (CWhile b c) st st''.
```

## 2. 标签、公开等价与允许流

只有 `public` 和 `secret` 两级。标签表把变量名映射到级别；`LXP` 仅把 `X` 标为公开。`LXP_public` 是其反向刻画：若在 `LXP` 下公开，变量就只能是 `X`，证明按字符串比较结果分类。

```coq
Inductive label : Type := public | secret.
Definition label_map := string -> label.
Definition LXP : label_map :=
  fun x => if String.eqb x X then public else secret.
Lemma LXPX : LXP X = public.
Proof. reflexivity. Qed.
Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  intros x H. unfold LXP in H. destruct (String.eqb x X) eqn:E.
  - apply String.eqb_eq. exact E.
  - discriminate.
Qed.
```

`pub_equiv L s1 s2` 表示两个状态在所有公开变量上相等，秘密变量可以任意不同。它显然是自反、对称、传递的；这三个引理在拼接两段执行以及处理“两侧运行不同秘密分支”时反复使用。

```coq
Definition pub_equiv (L : label_map) (s1 s2 : state) : Prop :=
  forall x, L x = public -> s1 x = s2 x.
Lemma pub_equiv_refl : forall L s, pub_equiv L s s.
Proof. intros L s x H. reflexivity. Qed.
Lemma pub_equiv_sym : forall L s1 s2,
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof. intros L s1 s2 H x Hx. symmetry. apply H. exact Hx. Qed.
Lemma pub_equiv_trans : forall L s1 s2 s3,
  pub_equiv L s1 s2 -> pub_equiv L s2 s3 -> pub_equiv L s1 s3.
Proof.
  intros L s1 s2 s3 H12 H23 x Hx.
  rewrite (H12 x Hx). apply H23. exact Hx.
Qed.
```

`join` 取较高级别，只要一个输入为 `secret`，结果就是 `secret`。`can_flow la lx` 只禁止 `secret` 流向 `public`，其余三种组合都允许。两个刻画引理把布尔检查转成便于逻辑证明的命题：允许流等价于“源公开或目标秘密”；若源是秘密且仍允许流，目标必为秘密。

```coq
Definition join (l1 l2 : label) : label :=
  match l1 with public => l2 | secret => secret end.
Lemma join_public : forall l1 l2,
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros [|] [|] H; simpl in H; auto; discriminate. Qed.
Lemma join_secret_l : forall l, join secret l = secret.
Proof. reflexivity. Qed.
Lemma join_secret_r : forall l, join l secret = secret.
Proof. intros [|]; reflexivity. Qed.
Definition can_flow (la lx : label) : bool :=
  match la, lx with secret, public => false | _, _ => true end.
Lemma can_flow_true_iff : forall l1 l2,
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2; [discriminate | reflexivity].
  - intros [H | H]; subst.
    + destruct l2; reflexivity.
    + destruct l1; reflexivity.
Qed.
Lemma can_flow_secret_l : forall l,
  can_flow secret l = true -> l = secret.
Proof. intros [|] H; [discriminate | reflexivity]. Qed.
```

## 3. 表达式标签与表达式非干扰

常量的标签为公开，变量读取其标签，复合表达式取子表达式的 `join`。归纳关系 `aexp_has_label` 适合证明，递归函数 `label_of_aexp` 适合计算。`label_of_aexp_sound` 说明计算结果确实可推导，`label_of_aexp_unique` 说明推导出的标签就是这个计算结果，因此关系与算法没有分歧。

```coq
Inductive aexp_has_label (L : label_map) : aexp -> label -> Prop :=
  | T_Num : forall n, aexp_has_label L (ANum n) public
  | T_Id : forall x, aexp_has_label L (AId x) (L x)
  | T_Plus : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      aexp_has_label L (APlus a1 a2) (join l1 l2)
  | T_Minus : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      aexp_has_label L (AMinus a1 a2) (join l1 l2)
  | T_Mult : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      aexp_has_label L (AMult a1 a2) (join l1 l2).
Fixpoint label_of_aexp (L : label_map) (a : aexp) : label :=
  match a with
  | ANum _ => public
  | AId x => L x
  | APlus a1 a2 | AMinus a1 a2 | AMult a1 a2 =>
      join (label_of_aexp L a1) (label_of_aexp L a2)
  end.
Lemma label_of_aexp_sound : forall L a,
  aexp_has_label L a (label_of_aexp L a).
Proof. intros L a. induction a; simpl; constructor; assumption. Qed.
Lemma label_of_aexp_unique : forall L a l,
  aexp_has_label L a l -> l = label_of_aexp L a.
Proof.
  intros L a l H. induction H; simpl; subst; reflexivity.
Qed.
```

第一个关键事实：公开表达式在公开等价状态下求值相同。证明对标签推导作归纳；`remember public as l` 保留“总标签为公开”这一等式。复合表达式若为公开，`join_public` 把两个子表达式都降为公开，于是可用归纳假设重写两侧求值。

```coq
Theorem noninterferent_aexp : forall L s1 s2 a,
  pub_equiv L s1 s2 -> aexp_has_label L a public ->
  aeval s1 a = aeval s2 a.
Proof.
  intros L s1 s2 a Heq Ht. remember public as l eqn:Hl.
  induction Ht; simpl.
  - reflexivity.
  - apply Heq. exact Hl.
  - destruct (join_public _ _ Hl) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public _ _ Hl) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public _ _ Hl) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
Qed.
```

布尔表达式采用同一模式。比较运算合并算术子表达式的标签，否定不改变标签，合取取 `join`。对应的计算函数同样具有可靠性和唯一性。

```coq
Inductive bexp_has_label (L : label_map) : bexp -> label -> Prop :=
  | T_True : bexp_has_label L BTrue public
  | T_False : bexp_has_label L BFalse public
  | T_Eq : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BEq a1 a2) (join l1 l2)
  | T_Neq : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BNeq a1 a2) (join l1 l2)
  | T_Le : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BLe a1 a2) (join l1 l2)
  | T_Gt : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BGt a1 a2) (join l1 l2)
  | T_Not : forall b l,
      bexp_has_label L b l -> bexp_has_label L (BNot b) l
  | T_And : forall b1 l1 b2 l2,
      bexp_has_label L b1 l1 -> bexp_has_label L b2 l2 ->
      bexp_has_label L (BAnd b1 b2) (join l1 l2).
Fixpoint label_of_bexp (L : label_map) (b : bexp) : label :=
  match b with
  | BTrue | BFalse => public
  | BEq a1 a2 | BNeq a1 a2 | BLe a1 a2 | BGt a1 a2 =>
      join (label_of_aexp L a1) (label_of_aexp L a2)
  | BNot b => label_of_bexp L b
  | BAnd b1 b2 => join (label_of_bexp L b1) (label_of_bexp L b2)
  end.
Lemma label_of_bexp_sound : forall L b,
  bexp_has_label L b (label_of_bexp L b).
Proof.
  intros L b. induction b; simpl; constructor;
    auto using label_of_aexp_sound.
Qed.
Lemma label_of_bexp_unique : forall L b l,
  bexp_has_label L b l -> l = label_of_bexp L b.
Proof.
  intros L b l H. induction H; simpl;
    try apply label_of_aexp_unique in H;
    try apply label_of_aexp_unique in H0; subst; reflexivity.
Qed.
```

公开布尔表达式的求值也不受秘密影响。四个比较分支归结为刚才的算术表达式定理；否定和合取分支使用归纳假设。这个定理之后既用于排除公开条件下的“两侧走向不同分支”，也用于保证循环测试一致。

```coq
Theorem noninterferent_bexp : forall L s1 s2 b,
  pub_equiv L s1 s2 -> bexp_has_label L b public ->
  beval s1 b = beval s2 b.
Proof.
  intros L s1 s2 b Heq Ht. remember public as l eqn:Hl.
  induction Ht; simpl; try reflexivity;
    try (destruct (join_public _ _ Hl) as [H1 H2];
         rewrite H1 in *; rewrite H2 in *).
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (IHHt Hl). reflexivity.
  - rewrite (IHHt1 eq_refl). rewrite (IHHt2 eq_refl). reflexivity.
Qed.
```

## 4. 状态更新与终态 NI

更新引理把赋值对公开等价的影响分类：两边写入相同值可保持等价；只在一侧更新秘密变量也保持等价；两侧分别向秘密变量写不同值仍保持等价。秘密更新证明中，公开变量 `y` 不可能等于秘密变量 `x`，所以使用 `t_update_neq`。

```coq
Lemma pub_equiv_update_same : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  pub_equiv L (t_update s1 x v) (t_update s2 x v).
Proof.
  intros L s1 s2 x v Heq y Hy. unfold t_update.
  destruct (String.eqb x y); [reflexivity | apply Heq; exact Hy].
Qed.
Lemma pub_equiv_update_secret_l : forall L s1 s2 x v,
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L (t_update s1 x v) s2.
Proof.
  intros L s1 s2 x v Heq Hx y Hy.
  assert (x <> y) by (intro E; subst; rewrite Hy in Hx; discriminate).
  rewrite (t_update_neq _ _ _ _ H). apply Heq. exact Hy.
Qed.
Lemma pub_equiv_update_secret_r : forall L s1 s2 x v,
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L s1 (t_update s2 x v).
Proof.
  intros L s1 s2 x v Heq Hx. apply pub_equiv_sym.
  apply pub_equiv_update_secret_l.
  - apply pub_equiv_sym. exact Heq.
  - exact Hx.
Qed.
Lemma pub_equiv_update_secret : forall L s1 s2 x v1 v2,
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L (t_update s1 x v1) (t_update s2 x v2).
Proof.
  intros. apply pub_equiv_update_secret_l.
  - apply pub_equiv_update_secret_r; assumption.
  - assumption.
Qed.
Definition noninterferent (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2', pub_equiv L s1 s2 ->
  ceval c s1 s1' -> ceval c s2 s2' -> pub_equiv L s1' s2'.
```

`noninterferent` 只比较终态。它不查看中间赋值，不记录条件走向，也没有输出可比较；后两节会把这些观察分别加入语义。

## 5. 控制流类型系统及其终态 NI

`cf_well_typed` 采用较保守的规则：赋值只允许表达式标签流向变量标签；`if` 和 `while` 的条件必须为公开。这样既能阻止显式流 `X := Y`，也能阻止秘密决定分支。

```coq
Inductive cf_well_typed (L : label_map) : com -> Prop :=
  | CFWT_Skip : cf_well_typed L CSkip
  | CFWT_Asgn : forall x a la,
      aexp_has_label L a la -> can_flow la (L x) = true ->
      cf_well_typed L (CAsgn x a)
  | CFWT_Seq : forall c1 c2,
      cf_well_typed L c1 -> cf_well_typed L c2 ->
      cf_well_typed L (CSeq c1 c2)
  | CFWT_If : forall b c1 c2,
      bexp_has_label L b public -> cf_well_typed L c1 ->
      cf_well_typed L c2 -> cf_well_typed L (CIf b c1 c2)
  | CFWT_While : forall b c,
      bexp_has_label L b public -> cf_well_typed L c ->
      cf_well_typed L (CWhile b c).
```

终态 NI 的证明对第一次执行归纳，并反演第二次执行和类型推导。赋值时，若源标签为公开，两次写入相同值；若目标为秘密，值可以不同。顺序组合先用第一段归纳假设获得中间状态的公开等价，再用于第二段。公开条件保证两次测试值一致，所以看似不同的真假分支组合会产生矛盾。

```coq
Theorem cf_well_typed_noninterferent : forall L c,
  cf_well_typed L c -> noninterferent L c.
Proof.
  intros L c Hwt s1 s2 s1' s2' Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  induction Heval1; intros s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - assumption.
  - match goal with Hf : can_flow _ _ = true |- _ =>
      apply can_flow_true_iff in Hf; destruct Hf as [Hla | Hx] end.
    + match goal with Ha : aexp_has_label _ _ _ |- _ =>
        rewrite Hla in Ha;
        rewrite (noninterferent_aexp _ _ _ _ Heq Ha) end.
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
  - eapply IHHeval1; eassumption.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H10) in H.
    rewrite H in H5. discriminate.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H10) in H.
    rewrite H in H5. discriminate.
  - eapply IHHeval1; eassumption.
  - assumption.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H9) in H.
    rewrite H in H2. discriminate.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H7) in H.
    rewrite H in H4. discriminate.
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
Qed.
```

## 6. 带分支轨迹的语义与控制流安全

`branches` 是布尔列表。`cf_ceval` 与普通 `ceval` 的终态规则一致，但 `if` 把本次判断的 `true` 或 `false` 加到轨迹前端，顺序组合按执行顺序拼接轨迹。循环用一次展开

`while b do c`  ⇝  `if b then (c; while b do c) else skip`

来复用条件规则，因此每一次循环测试也恰好记录一个布尔值。空赋值、空跳转不产生轨迹元素。

```coq
Definition branches := list bool.
Inductive cf_ceval : com -> state -> state -> branches -> Prop :=
  | CFE_Skip : forall st, cf_ceval CSkip st st []
  | CFE_Asgn : forall st a x,
      cf_ceval (CAsgn x a) st (t_update st x (aeval st a)) []
  | CFE_Seq : forall c1 c2 st st' st'' bs1 bs2,
      cf_ceval c1 st st' bs1 -> cf_ceval c2 st' st'' bs2 ->
      cf_ceval (CSeq c1 c2) st st'' (List.app bs1 bs2)
  | CFE_IfTrue : forall st st' b c1 c2 bs,
      beval st b = true -> cf_ceval c1 st st' bs ->
      cf_ceval (CIf b c1 c2) st st' (true :: bs)
  | CFE_IfFalse : forall st st' b c1 c2 bs,
      beval st b = false -> cf_ceval c2 st st' bs ->
      cf_ceval (CIf b c1 c2) st st' (false :: bs)
  | CFE_While : forall b st st' bs c,
      cf_ceval (CIf b (CSeq c (CWhile b c)) CSkip) st st' bs ->
      cf_ceval (CWhile b c) st st' bs.
```

上面若去掉轨迹，应能恢复普通语义。`cf_ceval_ceval` 正是这个遗忘定理：大多数分支直接重建普通执行；循环分支先对展开后的普通执行反演，再按测试真假恢复 `E_WhileTrue` 或 `E_WhileFalse`。

```coq
Lemma cf_ceval_ceval : forall c st st' bs,
  cf_ceval c st st' bs -> ceval c st st'.
Proof.
  intros c st st' bs H. induction H; try (econstructor; eassumption).
  inversion IHcf_ceval; subst.
  - inversion H6; subst. eapply E_WhileTrue; eauto.
  - inversion H6; subst. apply E_WhileFalse. assumption.
Qed.
Definition cf_secure (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2' bs1 bs2, pub_equiv L s1 s2 ->
  cf_ceval c s1 s1' bs1 -> cf_ceval c s2 s2' bs2 -> bs1 = bs2.
```

`cf_secure` 要求两条轨迹**完全相等**，不仅是长度相等，也不要求公开终态相同。其主定理按第一次带轨迹执行归纳。顺序组合有一个值得注意的细节：第二段要以公开等价的中间状态为前提，所以先用第一段控制流安全对齐轨迹，再借 `cf_ceval_ceval` 和终态 NI 定理得到中间状态公开等价。条件和循环的公开测试则直接由 `noninterferent_bexp` 对齐。

```coq
Theorem cf_well_typed_cf_secure : forall L c,
  cf_well_typed L c -> cf_secure L c.
Proof.
  intros L c Hwt s1 s2 s1' s2' bs1 bs2 Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent bs2.
  induction Heval1; intros bs2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - destruct (IHHeval1_1 H8 _ _ Heq _ H1).
    assert (Heq' : pub_equiv L st' st'0).
    { apply cf_ceval_ceval in Heval1_1. apply cf_ceval_ceval in H1.
      eapply cf_well_typed_noninterferent with (c := c1); eauto. }
    erewrite IHHeval1_2; eauto.
  - f_equal. eapply IHHeval1; eassumption.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H11) in H.
    rewrite H in H6. discriminate.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H11) in H.
    rewrite H in H6. discriminate.
  - f_equal. eapply IHHeval1; eassumption.
  - eapply IHHeval1; try eassumption. repeat constructor; eassumption.
Qed.
```

## 7. 反例一：终态 NI 与控制流安全互相独立

程序 `secret_branch_ni` 根据秘密 `Y` 是否为 `0`，决定给秘密 `Z` 赋 `0` 还是跳过。由于 `Z` 秘密，两侧终态始终公开等价。证明反演两次执行及其子执行，四种分支组合分别使用秘密更新引理或原公开等价。

```coq
Definition secret_branch_ni : com :=
  CIf (BEq (AId Y) (ANum 0)) (CAsgn Z (ANum 0)) CSkip.
Lemma secret_branch_ni_noninterferent : noninterferent LXP secret_branch_ni.
Proof.
  unfold noninterferent, secret_branch_ni.
  intros s1 s2 s1' s2' H H1 H2. inversion H1; inversion H2;
    repeat match goal with
    | Hc : ceval (CAsgn _ _) _ _ |- _ => inversion Hc; clear Hc
    | Hc : ceval CSkip _ _ |- _ => inversion Hc; clear Hc
    end; subst.
  - apply pub_equiv_update_secret; [exact H | reflexivity].
  - apply pub_equiv_update_secret_l; [exact H | reflexivity].
  - apply pub_equiv_update_secret_r; [exact H | reflexivity].
  - exact H.
Qed.
```

但取初态 `Y=0` 和 `Y=1`：二者公开等价，轨迹却分别为 `[true]` 与 `[false]`。把这两次具体执行代入 `cf_secure` 后，得到 `[true] = [false]`，`discriminate` 直接发现矛盾。这就是“终态没有公开泄露，但分支轨迹已经泄露一个秘密比特”。

```coq
Lemma secret_branch_ni_not_cf_secure : ~ cf_secure LXP secret_branch_ni.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    (t_update empty_state Z 0) (t_update empty_state Y 1) [true] [false]).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (cf_ceval secret_branch_ni empty_state
    (t_update empty_state Z 0) [true]).
  { apply CFE_IfTrue; [reflexivity | constructor]. }
  assert (cf_ceval secret_branch_ni (t_update empty_state Y 1)
    (t_update empty_state Y 1) [false]).
  { apply CFE_IfFalse; [reflexivity | constructor]. }
  specialize (H H1 H2). discriminate.
Qed.
```

反方向的反例是 `X := Y`。赋值没有条件测试，所以两次轨迹都为 `[]`，控制流安全平凡成立；但初态分别取 `Y=0` 与 `Y=1` 时，公开终态的 `X` 分别为 `0` 与 `1`，终态 NI 失败。可见“轨迹一致”并不蕴含“公开终态一致”。

```coq
Definition explicit_leak_cf : com := CAsgn X (AId Y).
Lemma explicit_leak_cf_secure : cf_secure LXP explicit_leak_cf.
Proof.
  intros s1 s2 s1' s2' bs1 bs2 Heq H1 H2.
  inversion H1; inversion H2; subst. reflexivity.
Qed.
Lemma explicit_leak_not_noninterferent : ~ noninterferent LXP explicit_leak_cf.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    (t_update empty_state X 0) (t_update (t_update empty_state Y 1) X 1)).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (ceval explicit_leak_cf empty_state (t_update empty_state X 0))
    by constructor.
  assert (ceval explicit_leak_cf (t_update empty_state Y 1)
    (t_update (t_update empty_state Y 1) X 1)) by constructor.
  specialize (H H1 H2 X LXPX). simpl in H. discriminate.
Qed.
```

## 8. 输出命令、输出安全及两个反例

为了不改变前面的普通 Imp，输出语言另用 `ocom`。`oceval` 在终态之外返回自然数列表：只有 `OOutput a` 产生单元素列表 `[aeval st a]`，顺序组合拼接输出。条件和循环仍用统一条件规则与一次展开规则，简化后续归纳。

```coq
Inductive ocom : Type :=
  | OSkip
  | OAsgn (x : string) (a : aexp)
  | OSeq (c1 c2 : ocom)
  | OIf (b : bexp) (c1 c2 : ocom)
  | OWhile (b : bexp) (c : ocom)
  | OOutput (a : aexp).
Definition outputs := list nat.
Inductive oceval : ocom -> state -> state -> outputs -> Prop :=
  | OE_Skip : forall st, oceval OSkip st st []
  | OE_Asgn : forall st a x,
      oceval (OAsgn x a) st (t_update st x (aeval st a)) []
  | OE_Seq : forall c1 c2 st st' st'' os1 os2,
      oceval c1 st st' os1 -> oceval c2 st' st'' os2 ->
      oceval (OSeq c1 c2) st st'' (List.app os1 os2)
  | OE_If : forall st st' b c1 c2 os,
      let c := if beval st b then c1 else c2 in
      oceval c st st' os -> oceval (OIf b c1 c2) st st' os
  | OE_While : forall b st st' os c,
      oceval (OIf b (OSeq c (OWhile b c)) OSkip) st st' os ->
      oceval (OWhile b c) st st' os
  | OE_Output : forall st a,
      oceval (OOutput a) st st [aeval st a].
Definition output_noninterferent (L : label_map) (c : ocom) : Prop :=
  forall s1 s2 s1' os1 s2' os2, pub_equiv L s1 s2 ->
  oceval c s1 s1' os1 -> oceval c s2 s2' os2 -> pub_equiv L s1' s2'.
Definition output_secure (L : label_map) (c : ocom) : Prop :=
  forall s1 s2 s1' os1 s2' os2, pub_equiv L s1 s2 ->
  oceval c s1 s1' os1 -> oceval c s2 s2' os2 -> os1 = os2.
```

`output_noninterferent` 仍只看终态，而 `output_secure` 只看输出列表。`output Y` 不改变状态，因此满足前者；它却直接把秘密值放进输出，所以不满足后者。

```coq
Definition output_secret : ocom := OOutput (AId Y).
Definition output_under_secret : ocom :=
  OIf (BEq (AId Y) (ANum 0)) (OOutput (ANum 1)) OSkip.
Lemma output_secret_noninterferent : output_noninterferent LXP output_secret.
Proof.
  intros s1 s2 s1' os1 s2' os2 Heq H1 H2.
  inversion H1; inversion H2; subst. exact Heq.
Qed.
Lemma output_secret_not_secure : ~ output_secure LXP output_secret.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    empty_state [0] (t_update empty_state Y 1) [1]).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (oceval output_secret empty_state empty_state [0]) by constructor.
  assert (oceval output_secret (t_update empty_state Y 1)
    (t_update empty_state Y 1) [1]) by constructor.
  specialize (H H1 H2). discriminate.
Qed.
```

第二个程序输出的常数永远是 `1`，但秘密决定是否执行输出。初态 `Y=0` 时输出 `[1]`，`Y=1` 时输出 `[]`，状态均不改变。这说明输出安全不仅限制输出**值**，也限制输出**是否发生以及发生次数**；否则秘密可通过输出的有无和长度泄露。

```coq
Lemma output_under_secret_noninterferent :
  output_noninterferent LXP output_under_secret.
Proof.
  intros s1 s2 s1' os1 s2' os2 Heq H1 H2.
  inversion H1; inversion H2; subst; simpl in *; subst c c4.
  destruct (s1 Y), (s2 Y); simpl in *; subst;
    repeat match goal with
    | Hc : oceval OSkip _ _ _ |- _ => inversion Hc; clear Hc
    | Hc : oceval (OOutput _) _ _ _ |- _ => inversion Hc; clear Hc
    end; subst; exact Heq.
Qed.
Lemma output_under_secret_not_secure : ~ output_secure LXP output_under_secret.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    empty_state [1] (t_update empty_state Y 1) []).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (oceval output_under_secret empty_state empty_state [1]).
  { apply OE_If. simpl. constructor. }
  assert (oceval output_under_secret (t_update empty_state Y 1)
    (t_update empty_state Y 1) []).
  { apply OE_If. simpl. constructor. }
  specialize (H H1 H2). discriminate.
Qed.
```

## 9. 跟踪隐式流的输出安全类型系统

`oni_well_typed L pc c` 中的 `pc` 表示“当前代码是否处于秘密控制之下”。赋值检查 `join pc la` 到目标变量的流，因此秘密上下文中的赋值不能修改公开变量。进入条件或循环体时，把条件标签并入 `pc`。输出规则要求 `join pc la` 能流向 `public`，这只有 `pc=public` 且表达式标签为 `public` 时才可能成立：既不能直接输出秘密，也不能在秘密分支中输出公开常量。

```coq
Inductive oni_well_typed (L : label_map) : label -> ocom -> Prop :=
  | ONIWT_Skip : forall pc, oni_well_typed L pc OSkip
  | ONIWT_Asgn : forall pc x a la,
      aexp_has_label L a la -> can_flow (join pc la) (L x) = true ->
      oni_well_typed L pc (OAsgn x a)
  | ONIWT_Seq : forall pc c1 c2,
      oni_well_typed L pc c1 -> oni_well_typed L pc c2 ->
      oni_well_typed L pc (OSeq c1 c2)
  | ONIWT_If : forall pc b l c1 c2,
      bexp_has_label L b l -> oni_well_typed L (join pc l) c1 ->
      oni_well_typed L (join pc l) c2 -> oni_well_typed L pc (OIf b c1 c2)
  | ONIWT_While : forall pc b l c,
      bexp_has_label L b l -> oni_well_typed L (join pc l) c ->
      oni_well_typed L pc (OWhile b c)
  | ONIWT_Output : forall pc a la,
      aexp_has_label L a la -> can_flow (join pc la) public = true ->
      oni_well_typed L pc (OOutput a).
```

循环语义使用展开形式，所以证明也需要把循环类型推导提升为展开程序的类型推导。关键等式是 `join (join pc l) l = join pc l`，对两个标签分别分类即可证明；它保证递归出现的循环体能复用原循环体推导。

```coq
Lemma oni_well_typed_while_expansion : forall L pc b c,
  oni_well_typed L pc (OWhile b c) ->
  oni_well_typed L pc (OIf b (OSeq c (OWhile b c)) OSkip).
Proof.
  intros L pc b c Hwt. inversion Hwt; subst.
  apply ONIWT_If with (l := l); [assumption | | constructor].
  apply ONIWT_Seq; [assumption |].
  apply ONIWT_While with (l := l); [assumption |].
  replace (join (join pc l) l) with (join pc l)
    by (destruct pc, l; reflexivity).
  assumption.
Qed.
```

`oni_type_checker` 把归纳规则变成布尔递归函数，表达式标签由前面的计算函数给出。可靠性定理从 `true` 构造类型推导；完备性定理说明若算法返回 `false`，就不可能存在类型推导。后者对假设中的类型推导归纳，并用标签唯一性把任意推导中的标签对齐到计算结果。两个拒绝示例于是都能由计算直接完成。

```coq
Fixpoint oni_type_checker (L : label_map) (pc : label) (c : ocom) : bool :=
  match c with
  | OSkip => true
  | OAsgn x a => can_flow (join pc (label_of_aexp L a)) (L x)
  | OSeq c1 c2 => oni_type_checker L pc c1 && oni_type_checker L pc c2
  | OIf b c1 c2 =>
      oni_type_checker L (join pc (label_of_bexp L b)) c1 &&
      oni_type_checker L (join pc (label_of_bexp L b)) c2
  | OWhile b c => oni_type_checker L (join pc (label_of_bexp L b)) c
  | OOutput a => can_flow (join pc (label_of_aexp L a)) public
  end.
Lemma oni_type_checker_sound : forall L pc c,
  oni_type_checker L pc c = true -> oni_well_typed L pc c.
Proof.
  intros L pc c. generalize dependent pc.
  induction c; intros pc H; simpl in *; try econstructor;
    try repeat rewrite andb_true_iff in *;
    try destruct H; try tauto;
    eauto using label_of_aexp_sound, label_of_bexp_sound.
Qed.
Lemma oni_type_checker_complete : forall L pc c,
  oni_type_checker L pc c = false -> ~ oni_well_typed L pc c.
Proof.
  intros L pc c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *; try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
  - apply label_of_bexp_unique in H0. subst. auto.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
Qed.
Example not_ni_wt_output_secret : ~ oni_well_typed LXP public output_secret.
Proof. apply oni_type_checker_complete. reflexivity. Qed.
Example not_ni_wt_output_under_secret :
  ~ oni_well_typed LXP public output_under_secret.
Proof. apply oni_type_checker_complete. reflexivity. Qed.
```

## 10. 秘密上下文中的两个核心引理

`secret_run` 说明：若整个程序在 `pc=secret` 下良类型，则执行前后的状态公开等价。赋值规则迫使目标变量为秘密；顺序、条件和循环靠归纳假设拼接。直观地说，秘密控制下的代码不能公开写状态。

`different_code` 进一步处理两侧执行不同代码的情形：若两段代码都处于秘密上下文，则第一段只改变秘密状态，第二段也只改变秘密状态。用 `pub_equiv_trans` 经过两个初态，即可得到两个终态公开等价，即使两段代码语法不同。

```coq
Lemma secret_run : forall L c s s' os,
  oni_well_typed L secret c -> oceval c s s' os -> pub_equiv L s s'.
Proof.
  intros L c s s' os Hwt Heval. induction Heval; inversion Hwt;
    subst; eauto using pub_equiv_trans, pub_equiv_refl.
  - apply pub_equiv_update_secret_r.
    + apply pub_equiv_refl.
    + match goal with Hf : can_flow _ _ = true |- _ =>
        rewrite join_secret_l in Hf; apply can_flow_secret_l; exact Hf end.
  - simpl in *. destruct (beval st b); eapply IHHeval; eauto.
  - rewrite join_secret_l in H3.
    eapply IHHeval. econstructor; eauto; simpl; econstructor; eauto.
Qed.
Corollary different_code : forall L c1 c2 s1 s2 s1' s2' os1 os2,
  oni_well_typed L secret c1 -> oni_well_typed L secret c2 ->
  pub_equiv L s1 s2 -> oceval c1 s1 s1' os1 -> oceval c2 s2 s2' os2 ->
  pub_equiv L s1' s2'.
Proof.
  intros L c1 c2 s1 s2 s1' s2' os1 os2 Hwt1 Hwt2 Hequiv Heval1 Heval2.
  eapply secret_run in Hwt1; [| eassumption].
  eapply secret_run in Hwt2; [| eassumption].
  apply pub_equiv_sym in Hwt1.
  eapply pub_equiv_trans; try eassumption.
  eapply pub_equiv_trans; eassumption.
Qed.
```

## 11. 输出语言上的终态 NI 主定理

这个定理仍对第一次执行归纳。赋值和顺序组合与普通语言相同；条件命令新增“公开条件”和“秘密条件”两种处理：

* 公开条件下，两次测试必然一致，不同分支组合是矛盾；
* 秘密条件下，两侧可以执行不同分支，但两个分支都在 `pc=secret` 下良类型，所以用 `different_code` 得到终态公开等价。

循环按展开后的条件执行归纳。条件相同的组合使用归纳假设；条件不同且条件为秘密时，一侧执行 `OSeq c (OWhile b c)`，另一侧执行 `OSkip`，再次由 `different_code` 拼接。证明中的 `subst c0 c5` 展开条件规则选择的局部命令，随后用两侧的测试等式把它们化为上述具体程序。

```coq
Theorem oni_well_typed_noninterferent : forall L pc c,
  oni_well_typed L pc c -> output_noninterferent L c.
Proof.
  intros L pc c Hwt s1 s2 s1' os1 s2' os2 Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent os2.
  generalize dependent s2. generalize dependent pc.
  induction Heval1; intros pc Hwt s2 Heq os2' s2' Heval2;
    inversion Heval2; subst; auto.
  - inversion Hwt; subst.
    match goal with Hf : can_flow _ _ = true |- _ =>
      apply can_flow_true_iff in Hf; destruct Hf as [Hla | Hx] end.
    + apply join_public in Hla. destruct Hla as [_ Hla]. subst.
      match goal with Ha : aexp_has_label _ _ _ |- _ =>
        rewrite (noninterferent_aexp _ _ _ _ Heq Ha) end.
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - inversion Hwt; subst. eapply IHHeval1_2; try eassumption.
    eapply IHHeval1_1; eassumption.
  - simpl in *. destruct (beval st b) eqn:Hb;
      destruct (beval s2 b) eqn:Hb2; subst;
      inversion Hwt; subst.
    + eapply IHHeval1; eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code with (c1 := c1) (c2 := c2); eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code with (c1 := c2) (c2 := c1); eassumption.
    + eapply IHHeval1; eassumption.
  - simpl in *. inversion Hwt; subst.
    destruct (beval st b) eqn:Hb; destruct (beval s2 b) eqn:Hb2; subst;
      repeat match goal with Hi : oceval (OIf _ _ _) _ _ _ |- _ =>
        inversion Hi; clear Hi end; subst; simpl in *.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code with
          (c1 := OSeq c (OWhile b c)) (c2 := OSkip).
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- constructor.
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code with
          (c1 := OSkip) (c2 := OSeq c (OWhile b c)).
        -- constructor.
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
Qed.
```

## 12. 秘密上下文无输出与输出安全主定理

输出安全需要另一个秘密上下文引理：`secret_run_no_output` 证明秘密上下文中的执行输出必为 `[]`。顺序组合把两段空输出拼接；条件与循环由归纳假设处理；输出分支不可能发生，因为其类型检查会要求 `secret` 流向 `public`。因此，两段处于秘密上下文的不同代码不仅保持公开状态，也都无输出，`different_code_no_output` 直接得出输出列表相等。

```coq
Lemma secret_run_no_output : forall L c s s' os,
  oni_well_typed L secret c -> oceval c s s' os -> os = [].
Proof.
  intros L c s s' os Hwt Heval. induction Heval; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - rewrite (IHHeval1 H2), (IHHeval2 H3). reflexivity.
  - simpl in *. destruct (beval st b); eapply IHHeval; eauto.
  - rewrite join_secret_l in H3. eapply IHHeval.
    econstructor; eauto; simpl; econstructor; eauto.
  - match goal with Hf : can_flow _ _ = true |- _ =>
      rewrite join_secret_l in Hf; discriminate end.
Qed.
Corollary different_code_no_output : forall L c1 c2 s1 s2 s1' s2' os1 os2,
  oni_well_typed L secret c1 -> oni_well_typed L secret c2 ->
  pub_equiv L s1 s2 -> oceval c1 s1 s1' os1 -> oceval c2 s2 s2' os2 ->
  os1 = os2.
Proof.
  intros L c1 c2 s1 s2 s1' s2' os1 os2 Hwt1 Hwt2 Hequiv Heval1 Heval2.
  eapply secret_run_no_output in Hwt1; [| eassumption].
  eapply secret_run_no_output in Hwt2; [| eassumption].
  subst. reflexivity.
Qed.
```

输出安全主定理的结构与终态 NI 类似，但顺序组合多一步：先用第一段的输出安全把输出前缀对齐，再用已经证明的 `oni_well_typed_noninterferent` 得到中间状态公开等价，最后应用第二段归纳假设。秘密条件下的不同分支由 `different_code_no_output` 处理。输出命令分支中，允许流排除了目标为 `secret` 的荒唐情况，并迫使 `pc` 和表达式标签都为公开；于是 `noninterferent_aexp` 给出两个输出值相等。

```coq
Theorem oni_well_typed_output_secure : forall L pc c,
  oni_well_typed L pc c -> output_secure L c.
Proof.
  intros L pc c Hwt s1 s2 s1' os1 s2' os2 Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent os2.
  generalize dependent s2. generalize dependent pc.
  induction Heval1; intros pc Hwt s2 Heq os2' s2' Heval2;
    inversion Heval2; subst; auto.
  - inversion Hwt; subst.
    destruct (IHHeval1_1 _ H3 _ Heq _ _ H1). f_equal.
    eapply IHHeval1_2; try eassumption.
    eapply oni_well_typed_noninterferent with (c := c1); eauto.
  - simpl in *. destruct (beval st b) eqn:Hb;
      destruct (beval s2 b) eqn:Hb2; subst; inversion Hwt; subst.
    + eapply IHHeval1; eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code_no_output with (c1 := c1) (c2 := c2); eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code_no_output with (c1 := c2) (c2 := c1); eassumption.
    + eapply IHHeval1; eassumption.
  - simpl in *. inversion Hwt; subst.
    destruct (beval st b) eqn:Hb; destruct (beval s2 b) eqn:Hb2; subst;
      repeat match goal with Hi : oceval (OIf _ _ _) _ _ _ |- _ =>
        inversion Hi; clear Hi end; subst; simpl in *.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code_no_output with
          (c1 := OSeq c (OWhile b c)) (c2 := OSkip).
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- constructor.
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code_no_output with
          (c1 := OSkip) (c2 := OSeq c (OWhile b c)).
        -- constructor.
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
  - inversion Hwt; subst.
    match goal with Hf : can_flow _ _ = true |- _ =>
      apply can_flow_true_iff in Hf; destruct Hf as [Hla | Hcontra] end;
      [| discriminate].
    apply join_public in Hla. destruct Hla as [_ Hla]. subst.
    match goal with Ha : aexp_has_label _ _ _ |- _ =>
      rewrite (noninterferent_aexp _ _ _ _ Heq Ha) end.
    reflexivity.
Qed.
```

## 13. 一个被类型系统接受的完整程序

最后，秘密条件只允许给秘密变量 `Z` 赋值或跳过，随后输出公开变量 `X`。虽然秘密可以控制秘密状态的更新，它既不能改变公开状态，也不能控制输出；输出值只依赖公开等价的 `X`。检查器计算出程序良类型，输出安全主定理再把类型推导提升为对所有公开等价初态和终止执行的安全结论。

```coq
Definition secure_output_program : ocom :=
  OSeq (OIf (BEq (AId Y) (ANum 0)) (OAsgn Z (AId Y)) OSkip)
    (OOutput (AId X)).
Example secure_output_program_typed :
  oni_well_typed LXP public secure_output_program.
Proof. apply oni_type_checker_sound. reflexivity. Qed.
Example secure_output_program_secure : output_secure LXP secure_output_program.
Proof.
  apply oni_well_typed_output_secure with (pc := public).
  exact secure_output_program_typed.
Qed.
```

## 14. 结论与边界

本章的三组反例把观察通道区分清楚：终态 NI 不会自动覆盖分支轨迹或输出，轨迹一致也不会自动保证公开终态一致。相应地，`cf_well_typed_cf_secure` 和 `oni_well_typed_output_secure` 并不是同一个定理换了名字：前者比较布尔控制流轨迹，后者比较公开输出序列；顺序组合的证明还都借助终态 NI 来连接中间状态。

这些结果都是**终止不敏感**的关系性安全定理，前提是给定的两次执行都存在。本章没有声称秘密条件绝不可能通过执行次数或终止行为泄露信息，也没有实现可选的 split/merge 程序划分。所有出现的引理、定理和示例均以 `Qed` 结束，没有借助额外公理或未完成证明。

