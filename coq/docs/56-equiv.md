# 56 · 行为等价：程序何时相同

对应示例：`../examples/56_equiv.v`（`Module Ex56Equiv`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

38–55 章给 Imp 配齐了三种语义，本章回到一个编译器人每天面对的问题：**两段程序
什么时候可以互相替换？** 优化器把 `1 + 2 * X` 改写成 `3 + X`、把恒假循环删成
`skip`、把循环展开一轮——每一步替换凭什么合法？答案必须**相对语义**定义：

- **表达式层**：两个 aexp（bexp）在任何状态下求值相同，就**行为等价**；
- **命令层**：两段命令对任何初态，要么**都不终止**、要么**终止在同一状态**，
  才等价。注意"都不终止"这半句——只比较终态会把死循环和"跑丢了"混为一谈。

本章三步走：先把等价定义好、攒够**等价律**（56.2–56.4，skip/if/while/序列/赋值
十余条）；再验证它确实是一座"代数"——既是**等价关系**又是**同余**（56.5–56.6，
意味着改一小块、整块等价，证明负担与改动大小成正比）；最后用这套代数证明一个
真正的编译优化——**常量折叠**——不改变程序行为（56.7）。57 章 Hoare 逻辑证
"程序满足规格"，本章证"程序变换保行为"，两者合起来就是验证编译器的左右手。

开工前的一个技术收获值得单记：本章第一版示例继承了一个赋值记号笔误
（`y constr at level 85`），导致 `Y := X - X` 里的 `-` 被主语法抢走解析成
`Nat.sub`——61 章坑清单里"根因未定位"的悬案在本次开工时**定位并修复**（两处
都已改回 `y at level 85`），见 56.8 坑清单第 1 条。

### 56.1 语言与大步语义的副本（同 38–58 章）

与 61 章相同的自包含副本（53 章详解），外加本章要用的第四条更新引理
`t_update_same`（"改回原值等于没改"——赋值等价律的钥匙）：

```coq
(* 41 行为等价：程序何时相同 —— aequiv/bequiv/cequiv、等价律、同余与常量折叠 *)

From Stdlib Require Import Arith Bool List Lia Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex56Equiv.

(* ---------- 56.1 语言与大步语义的副本（同 38–58 章） ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_update_eq : forall (A : Type) (m : total_map A) w v,
  (w !-> v ; m) w = v.
Proof.
  intros A m w v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Lemma t_update_neq : forall (A : Type) (m : total_map A) w1 w2 v,
  w1 <> w2 ->
  (w1 !-> v ; m) w2 = m w2.
Proof.
  intros A m w1 w2 v Hneq. unfold t_update.
  destruct (String.eqb_spec w1 w2).
  - contradiction.
  - reflexivity.
Qed.

Lemma t_update_same : forall (A : Type) (m : total_map A) w v,
  m w = v ->
  (w !-> v ; m) = m.
Proof.
  intros A m w v H.
  apply functional_extensionality. intros w'.
  unfold t_update.
  destruct (String.eqb_spec w w') as [Ew | Ew].
  - subst w'. rewrite H. reflexivity.
  - reflexivity.
Qed.

Definition state := total_map nat.
```

`t_update_same` 的陈述是**函数等式**（两张表相等），所以证明要过函数外延公理
（`functional_extensionality`）——先逐点化，再分"查同键/查别键"两路，同键路用
前提 `m w = v`，别键路两侧本就相同。它是 62 章 `update_shadow` 的"单层"版本；
本章它把"赋值等于没赋"这类等价从直觉变成定理。语言层与 ceval 七规则照抄：

```coq
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

### 56.2 三层等价：aequiv / bequiv / cequiv

```coq
(* ---------- 56.2 三层等价：aequiv / bequiv / cequiv ---------- *)

Definition aequiv (a1 a2 : aexp) : Prop :=
  forall (st : state),
    aeval st a1 = aeval st a2.

Definition bequiv (b1 b2 : bexp) : Prop :=
  forall (st : state),
    beval st b1 = beval st b2.

Theorem aequiv_example :
  aequiv <{ X - X }> <{ 0 }>.
Proof.
  intros st. simpl. lia.
Qed.

Theorem bequiv_example :
  bequiv <{ X - X = 0 }> <{ true }>.
Proof.
  intros st. unfold beval.
  rewrite aequiv_example. reflexivity.
Qed.

Definition cequiv (c1 c2 : com) : Prop :=
  forall (st st' : state),
    (st =[ c1 ]=> st') <-> (st =[ c2 ]=> st').
```

- **aequiv**：任何状态下两边求出同一个 nat。`X - X` 与 `0`（nat 截断减法救了
  这条：`x - x = 0` 恒真，`lia` 一步）。
- **bequiv**：任何状态下两边求出同一个 bool。例子直接复用上一条（比较的左边
  换成 0 后 `0 =? 0` 恒 true）。
- **cequiv**：命令层不能只比终态——**死循环没有终态**。定义写成双向蕴含：
  "c1 能到 st' ⟺ c2 能到 st'"。对任何 st' 都成立，则要么两边都到不了（都发散），
  要么都能到且到同一个——这正是我们要的。

先泼一盆冷水：等价**不是**平凡的，反例：

```coq
Example cequiv_not_trivial :
  ~ cequiv <{ X := 1 }> <{ X := 2 }>.
Proof.
  intros Hc.
  destruct (Hc empty_st (X !-> 1)) as [Hf _].
  assert (H2 : ceval <{ X := 2 }> empty_st (X !-> 1)).
  { apply Hf. apply E_Asgn. reflexivity. }
  inversion H2.
  apply (f_equal (fun m => m X)) in H4.
  rewrite !t_update_eq in H4.
  rewrite H4 in H3. simpl in H3. discriminate.
Qed.
```

证"不等价"的标准姿势：**取一个具体初态，让两边的终态分家**。从空状态出发，
`X := 1` 能到 `X !-> 1`；等价的定义逼着 `X := 2` 也能到——但 E_Asgn 说它只能到
`X !-> 2`。剩下的是把"两张表 X 处的值分别是 1 和 2"翻译成矛盾：`f_equal` 把表
等式投影到 X 处，`t_update_eq` 算出两边的值，`discriminate` 收尾。这个"反例驱动"
的写法在验证器实践中就是**差分测试**的形式化版。

### 56.3 命令等价律 I：skip 与 if

```coq
(* ---------- 56.3 命令等价律 I：skip 与 if ---------- *)

Theorem skip_left : forall c,
  cequiv <{ skip; c }> c.
Proof.
  intros c st st'.
  split; intros H.
  - inversion H. subst.
    inversion H2. subst.
    assumption.
  - apply E_Seq with st.
    + apply E_Skip.
    + assumption.
Qed.
```

第一条律：前置 skip 是无操作。-> 方向拆掉序列推导、再拆内层 skip 推导（E_Skip
强制中间状态 = 初态），剩的就是 c 的推导；<- 方向用 E_Seq + E_Skip 现场造一棵。
所有等价律都是这个"**双向拼推导**"的形状——`split` 之后每一边都是一棵推导树的
手术。

```coq
Theorem skip_right : forall c,
  cequiv <{ c; skip }> c.
Proof.
  intros c st st'.
  split; intros H.
  - inversion H; subst.
    match goal with
    | Hs : ceval CSkip _ _ |- _ => inversion Hs; subst
    end.
    assumption.
  - apply E_Seq with st'.
    + assumption.
    + apply E_Skip.
Qed.

Theorem if_true_simple : forall c1 c2,
  cequiv <{ if true then c1 else c2 end }> c1.
Proof.
  intros c1 c2 st st'.
  split; intros H.
  - inversion H; subst.
    + assumption.
    + discriminate.
  - apply E_IfTrue.
    + reflexivity.
    + assumption.
Qed.
```

后置 skip 同理（内层 skip 的推导按**形状**定位——`match goal with Hs : ceval
CSkip _ _`，反演产出的名字不可靠，55 章坑 4 的老规矩）。`if_true_simple`：
条件是**字面** true 时 if 直接消掉——反演出 E_IfFalse 分支时 `beval st true =
false` 自爆（discriminate）。

当然没人手写 `if true`——但编译器和宏展开天天产出这种东西。下一步把它升级成
**条件的等价**版本：

```coq
Theorem if_true : forall b c1 c2,
  bequiv b <{ true }> ->
  cequiv <{ if b then c1 else c2 end }> c1.
Proof.
  intros b c1 c2 Hb st st'.
  split; intros H.
  - inversion H; subst.
    + assumption.
    + exfalso. unfold bequiv in Hb. simpl in Hb.
      match goal with
      | Hf : beval _ b = false |- _ =>
          rewrite Hb in Hf; discriminate Hf
      end.
  - apply E_IfTrue.
    + unfold bequiv in Hb. simpl in Hb. apply Hb.
    + assumption.
Qed.

Theorem if_false : forall b c1 c2,
  bequiv b <{ false }> ->
  cequiv <{ if b then c1 else c2 end }> c2.
Proof.
  intros b c1 c2 Hb st st'.
  split; intros H.
  - inversion H; subst.
    + exfalso. unfold bequiv in Hb. simpl in Hb.
      match goal with
      | Ht : beval _ b = true |- _ =>
          rewrite Hb in Ht; discriminate Ht
      end.
    + assumption.
  - apply E_IfFalse.
    + unfold bequiv in Hb. simpl in Hb. apply Hb.
    + assumption.
Qed.

Theorem swap_if_branches : forall b c1 c2,
  cequiv
    <{ if b then c1 else c2 end }>
    <{ if ~ b then c2 else c1 end }>.
Proof.
  intros b c1 c2 st st'.
  split; intros H.
  - inversion H; subst.
    + apply E_IfFalse.
      * simpl. match goal with
                | Ht : beval _ b = true |- _ =>
                    rewrite Ht; reflexivity
                end.
      * assumption.
    + apply E_IfTrue.
      * simpl. match goal with
                | Hf : beval _ b = false |- _ =>
                    rewrite Hf; reflexivity
                end.
      * assumption.
  - inversion H; subst.
    + simpl in *.
      match goal with
      | Ht : negb (beval _ b) = true |- _ =>
          apply negb_true_iff in Ht;
          apply E_IfFalse; [exact Ht | assumption]
      end.
    + simpl in *.
      match goal with
      | Ht : negb (beval _ b) = false |- _ =>
          apply negb_false_iff in Ht;
          apply E_IfTrue; [exact Ht | assumption]
      end.
Qed.
```

- `if_true`/`if_false`：条件**等价于**字面布尔时，if 等价于对应分支。矛盾分支
  的处理是"bequiv 展开 + rewrite 进反演出的求值假设"——注意 `Hb` 展开后是
  `forall st, beval st b = true`，`rewrite Hb in Hf` 会自动实例化量词（rewrite
  的这个免费能力在 58 章见过）。
- `swap_if_branches`：**取反条件 + 交换分支**不改变语义——布尔代数 `b ≡ ~b 取反`
  的程序级化身。反方向要用 `negb_true_iff / negb_false_iff` 把"求反条件"的假设
  翻译回"求原条件"。

### 56.4 命令等价律 II：while、序列与赋值

```coq
(* ---------- 56.4 命令等价律 II：while、序列与赋值 ---------- *)

Theorem while_false : forall b c,
  bequiv b <{ false }> ->
  cequiv <{ while b do c end }> <{ skip }>.
Proof.
  intros b c Hb st st'.
  split; intros H.
  - inversion H; subst.
    + apply E_Skip.
    + exfalso. unfold bequiv in Hb. simpl in Hb.
      match goal with
      | Ht : beval _ b = true |- _ =>
          rewrite Hb in Ht; discriminate Ht
      end.
  - inversion H. subst.
    apply E_WhileFalse.
    unfold bequiv in Hb. simpl in Hb. apply Hb.
Qed.
```

恒假循环 ≈ skip：一次都不进。-> 方向 E_WhileTrue 分支与"b 恒假"矛盾；<- 方向
直接用 b 恒假走 E_WhileFalse。**恒真循环**有意思得多——它等价于什么？任何
**别的东西**都不行，除了另一个恒真循环：

```coq
Lemma while_true_nonterm : forall b c st st',
  bequiv b <{ true }> ->
  ~ (st =[ while b do c end ]=> st').
Proof.
  intros b c st st' Hb contra.
  remember <{ while b do c end }> as loopdef
           eqn:Heqloopdef.
  induction contra; inversion Heqloopdef; subst.
  - unfold bequiv in Hb. simpl in Hb.
    match goal with
    | Hf : beval _ b = false |- _ =>
        rewrite Hb in Hf; discriminate Hf
    end.
  - apply IHcontra2. reflexivity.
Qed.
```

**引理**：条件恒真的循环**永不终止**——没有任何 st' 能作为它的终态。证明是
53.12 `loop_never_stops` 的推广版：remember 冻结循环、对推导归纳，E_WhileFalse
分支与恒真矛盾，E_WhileTrue 分支由归纳假设接住。注意 `inversion Heqloopdef;
subst`——remember 之后的方程要**替换进归纳假设**（62 章 progress 的 eq_refl
还账手法在这里以 subst 的形式出现）。

```coq
Theorem while_true : forall b c,
  bequiv b <{ true }> ->
  cequiv <{ while b do c end }> <{ while true do skip end }>.
Proof.
  intros b c Hb st st'.
  split; intros H.
  - exfalso. eapply while_true_nonterm; eauto.
  - exfalso.
    eapply (while_true_nonterm <{ true }> <{ skip }> st st').
    + intros st0. reflexivity.
    + exact H.
Qed.
```

于是恒真循环 ≈ 任何恒真循环（右侧的 `while true do skip` 的条件字面为真，
`intros st0; reflexivity` 一行就是它的 bequiv 证明）——两个方向都靠"永不终止"
引理把求值假设变成荒谬。**等价类的视角**：所有发散程序互相等价、恒假循环与
skip 等价、恒真循环自成一类——56.5 的等价关系会把这件事正式化。

```coq
Theorem loop_unrolling : forall b c,
  cequiv
    <{ while b do c end }>
    <{ if b then c ; while b do c end else skip end }>.
Proof.
  intros b c st st'.
  split; intros Hce.
  - inversion Hce; subst.
    + apply E_IfFalse.
      * assumption.
      * apply E_Skip.
    + apply E_IfTrue.
      * assumption.
      * apply E_Seq with (st' := st'0).
        -- assumption.
        -- assumption.
  - inversion Hce; subst.
    + inversion H5; subst.
      apply E_WhileTrue with (st' := st'0).
      * assumption.
      * assumption.
      * assumption.
    + inversion H5; subst.
      apply E_WhileFalse.
      assumption.
Qed.
```

**循环展开**：while ≈ "if 条件 then（体; while）else skip"。这是真实编译器
的变换（减少跳转、暴露跨迭代的优化机会），正确性证明就是两边各拆一层。这里
inversion 产出的 `H5`（内层 if 的推导）这次**赌对了名字**——不稳定，但赌错
会立刻编译报错，编译循环会抓出来（56.8 坑 3 有总结）。

```coq
Theorem seq_assoc : forall c1 c2 c3,
  cequiv <{ (c1; c2); c3 }> <{ c1; (c2; c3) }>.
Proof.
  intros c1 c2 c3 st st'.
  split; intros H.
  - inversion H; subst.
    match goal with
    | Hs : ceval (CSeq _ _) _ _ |- _ => inversion Hs; subst
    end.
    eapply E_Seq; [ eassumption | eapply E_Seq; eassumption ].
  - inversion H; subst.
    match goal with
    | Hs : ceval (CSeq _ _) _ _ |- _ => inversion Hs; subst
    end.
    eapply E_Seq; [ eapply E_Seq; eassumption | eassumption ].
Qed.
```

序列结合律。中间状态全靠 `eapply` + `eassumption` 让统一器自己找——注意两个
方向括号的**嵌套顺序相反**，所以 eapply 的子目标顺序也要对调（第一分支先造
外层再内层，第二分支反着来）。写错顺序时目标对不上，`Show` 看一眼即可。

```coq
Theorem identity_assignment : forall w,
  cequiv <{ w := w }> <{ skip }>.
Proof.
  intros w st st'.
  split; intros H; inversion H; subst; clear H.
  - rewrite t_update_same.
    apply E_Skip.
    reflexivity.
  - assert (Hw : st' =[ w := w ]=> (w !-> st' w ; st')).
    { apply E_Asgn. reflexivity. }
    rewrite t_update_same in Hw.
    + apply Hw.
    + reflexivity.
Qed.
```

**自己赋给自己 ≈ 什么都不做**。这里 56.1 的 `t_update_same` 上场：`w !-> st' w;
st'` 与 `st'` 是**同一张表**（更新成了原值）。rewrite 带前提的版本（`rewrite
t_update_same in Hw` 之后 `+` 证前提 `st' w = st' w`）比先 assert 再 rewrite
省一行，两种写法本章各用一次。

```coq
Theorem assign_aequiv : forall (w : string) (a : aexp),
  aequiv <{ w }> a ->
  cequiv <{ skip }> <{ w := a }>.
Proof.
  intros w a Ha st st'.
  split; intros H.
  - inversion H; subst.
    assert (Heq : (w !-> aeval st' a ; st') = st').
    { apply t_update_same. rewrite <- Ha. simpl. reflexivity. }
    assert (Hd : st' =[ w := a ]=> (w !-> aeval st' a ; st')).
    { apply E_Asgn. reflexivity. }
    rewrite Heq in Hd. exact Hd.
  - inversion H; subst.
    assert (Heq : (w !-> aeval st a ; st) = st).
    { apply t_update_same. rewrite <- Ha. simpl. reflexivity. }
    rewrite Heq. apply E_Skip.
Qed.
```

推广：**w := a ≈ skip，当且仅当 a 求值恒等于 w 的当前值**。前提 `aequiv <{w}>
a` 展开是 `forall st, aeval st <{w}> = aeval st a`，即 `st w = aeval st a`——
`rewrite <- Ha` 把更新值换成 `st w`，`t_update_same` 完成表等式。注意 -> 方向
里初态变量在 inversion+subst 后被吃掉的是 st（保留 st'），<- 方向反过来——
两个分支用不同的变量名（56.8 坑 4）。

### 56.5 等价关系：自反、对称、传递

```coq
(* ---------- 56.5 等价关系：自反、对称、传递 ---------- *)

Lemma refl_aequiv : forall (a : aexp), aequiv a a.
Proof. intros a st. reflexivity. Qed.

Lemma sym_aequiv : forall a1 a2, aequiv a1 a2 -> aequiv a2 a1.
Proof. intros a1 a2 H st. symmetry. apply H. Qed.

Lemma trans_aequiv : forall a1 a2 a3,
  aequiv a1 a2 -> aequiv a2 a3 -> aequiv a1 a3.
Proof.
  unfold aequiv. intros a1 a2 a3 H12 H23 st.
  rewrite (H12 st). rewrite (H23 st). reflexivity.
Qed.

Lemma refl_bequiv : forall (b : bexp), bequiv b b.
Proof. intros b st. reflexivity. Qed.

Lemma sym_bequiv : forall b1 b2, bequiv b1 b2 -> bequiv b2 b1.
Proof. intros b1 b2 H st. symmetry. apply H. Qed.

Lemma trans_bequiv : forall b1 b2 b3,
  bequiv b1 b2 -> bequiv b2 b3 -> bequiv b1 b3.
Proof.
  unfold bequiv. intros b1 b2 b3 H12 H23 st.
  rewrite (H12 st). rewrite (H23 st). reflexivity.
Qed.

Lemma refl_cequiv : forall (c : com), cequiv c c.
Proof. intros c st st'. reflexivity. Qed.

Lemma sym_cequiv : forall c1 c2, cequiv c1 c2 -> cequiv c2 c1.
Proof.
  unfold cequiv. intros c1 c2 H st st'.
  split; intros Hc.
  - apply (proj2 (H st st')). exact Hc.
  - apply (proj1 (H st st')). exact Hc.
Qed.

Lemma trans_cequiv : forall c1 c2 c3,
  cequiv c1 c2 -> cequiv c2 c3 -> cequiv c1 c3.
Proof.
  unfold cequiv. intros c1 c2 c3 H12 H23 st st'.
  split; intros Hc.
  - apply (proj1 (H23 st st')). apply (proj1 (H12 st st')). exact Hc.
  - apply (proj2 (H12 st st')). apply (proj2 (H23 st st')). exact Hc.
Qed.
```

三层等价各配三条（51 章 `equivalence` 定义的实例化）。表达式层的六条一行一个
`reflexivity / symmetry / rewrite`。命令层的两条值得看写法：**对 iff 直接
`rewrite` 在 rocq 9.3 会触发 setoid 重写、抛 UNDEFINED EVARS**（实测，坑 5），
所以这里全部改用 `proj1 / proj2` 显式取双向蕴含的分量——`H st st' : A <-> B`
的 proj1 是 A→B、proj2 是 B→A，`split` 后各取所需再串接。三个等价（aequiv、
bequiv、cequiv）都是等价关系 ⇒ 它们各自把程序空间切成**等价类**——56.2 结尾
说"所有发散程序一类"说的就是这个。

### 56.6 同余：小等价拼成大等价

```coq
(* ---------- 56.6 同余：小等价拼成大等价 ---------- *)

Theorem CAsgn_congruence : forall w a a',
  aequiv a a' ->
  cequiv <{ w := a }> <{ w := a' }>.
Proof.
  intros w a a' Heqv st st'.
  split; intros Hceval.
  - inversion Hceval. subst. apply E_Asgn.
    rewrite Heqv. reflexivity.
  - inversion Hceval. subst. apply E_Asgn.
    rewrite Heqv. reflexivity.
Qed.
```

**同余**：子程序等价 ⇒ 含着它的整程序等价。赋值最简单——两个方向的手术完全
对称（反演出 E_Asgn、重装 E_Asgn），唯一的差别是 `rewrite Heqv` 把求值前提
里的 a 换成 a'。序列与条件：

```coq
Theorem CSeq_congruence : forall c1 c1' c2 c2',
  cequiv c1 c1' -> cequiv c2 c2' ->
  cequiv <{ c1; c2 }> <{ c1'; c2' }>.
Proof.
  intros c1 c1' c2 c2' H1 H2 st st'.
  split; intros H.
  - inversion H; subst.
    apply E_Seq with (st'0).
    + apply H1. assumption.
    + apply H2. assumption.
  - inversion H; subst.
    apply E_Seq with (st'0).
    + apply H1. assumption.
    + apply H2. assumption.
Qed.
```

（原文如此——序列同余两侧完全对称，中间状态 `st'0` 由反演给出、`with` 显式
点名，两个方向的四步一模一样。）

```coq
Theorem CIf_congruence : forall b b' c1 c1' c2 c2',
  bequiv b b' -> cequiv c1 c1' -> cequiv c2 c2' ->
  cequiv <{ if b then c1 else c2 end }>
         <{ if b' then c1' else c2' end }>.
Proof.
  intros b b' c1 c1' c2 c2' Hb H1 H2 st st'.
  split; intros H.
  - inversion H; subst.
    + apply E_IfTrue.
      * unfold bequiv in Hb.
        match goal with
        | Ht : beval _ b = true |- _ => rewrite <- (Hb st); exact Ht
        end.
      * apply H1. assumption.
    + apply E_IfFalse.
      * unfold bequiv in Hb.
        match goal with
        | Hf : beval _ b = false |- _ => rewrite <- (Hb st); exact Hf
        end.
      * apply H2. assumption.
  - inversion H; subst.
    + apply E_IfTrue.
      * unfold bequiv in Hb.
        match goal with
        | Ht : beval _ b' = true |- _ => rewrite (Hb st); exact Ht
        end.
      * apply H1. assumption.
    + apply E_IfFalse.
      * unfold bequiv in Hb.
        match goal with
        | Hf : beval _ b' = false |- _ => rewrite (Hb st); exact Hf
        end.
      * apply H2. assumption.
Qed.
```

条件的同余：条件与两个分支都换成等价的，if 整体等价。四个分支的"搬条件"步骤
各有方向——从 b 的求值推 b' 的用 `rewrite <- (Hb st)`（目标侧是 b'），反方向
`rewrite (Hb st)`。**写错 rewrite 方向是最常见的翻车点**（实测 `Found no
subterm matching`，坑 6）。

```coq
Theorem CWhile_congruence : forall b b' c c',
  bequiv b b' -> cequiv c c' ->
  cequiv <{ while b do c end }> <{ while b' do c' end }>.
Proof.
  assert (A : forall (b b' : bexp) (c c' : com) (st st' : state),
             bequiv b b' -> cequiv c c' ->
             st =[ while b do c end ]=> st' ->
             st =[ while b' do c' end ]=> st').
  { unfold bequiv, cequiv.
    intros b b' c c' st st' Hbe Hc1e Hce.
    remember <{ while b do c end }> as cwhile eqn:Heqcwhile.
    induction Hce; inversion Heqcwhile; subst.
    + apply E_WhileFalse. rewrite <- Hbe. apply H.
    + apply E_WhileTrue with (st' := st').
      * rewrite <- Hbe. apply H.
      * apply (Hc1e st st'). apply Hce1.
      * apply IHHce2. reflexivity. }
  intros b b' c c' Hb Hc.
  split.
  - apply A; assumption.
  - apply A.
    + apply sym_bequiv. assumption.
    + apply sym_cequiv. assumption.
Qed.
```

循环的同余要用**归纳**（序列长度无界）。结构是"证明一个方向、用对称性白拿
另一个方向"：内部 assert 先证 -> 方向（对求值推导归纳，remember 冻结循环——
56.4 `while_true_nonterm` 的同款阵型），外层 `split` 后 <- 方向直接换用
`sym_bequiv / sym_cequiv`。注意箭头**反变**在这里不涉及（那是子类型的事，
64 章见）。

```coq
Example congruence_example :
  cequiv
    <{ X := 0;
       if (X = 0) then Y := 0
       else Y := 42 end }>
    <{ X := 0;
       if (X = 0) then Y := X - X
       else Y := 42 end }>.
Proof.
  apply CSeq_congruence.
  - apply refl_cequiv.
  - apply CIf_congruence.
    + apply refl_bequiv.
    + apply CAsgn_congruence. unfold aequiv. simpl.
      intros st. lia.
    + apply refl_cequiv.
Qed.
```

实战：两段只差一个赋值右端的程序。证明树就是"哪里没变用 refl、哪里变了用对应
的同余规则 + 局部等价"——**证明负担与改动大小成正比**，这正是同余性的工程
意义（改 5% 的代码只需重证 5% 的等价）。局部等价 `X - X ≈ 0` 由 `lia` 收尾。
（这段例子里条件加了括号 `(X = 0)`——56.8 坑 1 的记号坑在复合表达式位置最稳
的做法。）

### 56.7 常量折叠：一个真实的优化 pass

```coq
(* ---------- 56.7 常量折叠：一个真实的优化 pass ---------- *)

Definition atrans_sound (atrans : aexp -> aexp) : Prop :=
  forall (a : aexp), aequiv a (atrans a).

Definition btrans_sound (btrans : bexp -> bexp) : Prop :=
  forall (b : bexp), bequiv b (btrans b).

Definition ctrans_sound (ctrans : com -> com) : Prop :=
  forall (c : com), cequiv c (ctrans c).
```

先把"**变换可靠**"参数化成三层定义——每个优化 pass 都要证自己那一层。然后是
本章的主角：

```coq
Fixpoint fold_constants_aexp (a : aexp) : aexp :=
  match a with
  | ANum n => ANum n
  | AId w => AId w
  | <{ a1 + a2 }> =>
    match (fold_constants_aexp a1,
           fold_constants_aexp a2)
    with
    | (ANum n1, ANum n2) => ANum (n1 + n2)
    | (a1', a2') => <{ a1' + a2' }>
    end
  | <{ a1 - a2 }> =>
    match (fold_constants_aexp a1,
           fold_constants_aexp a2)
    with
    | (ANum n1, ANum n2) => ANum (n1 - n2)
    | (a1', a2') => <{ a1' - a2' }>
    end
  | <{ a1 * a2 }> =>
    match (fold_constants_aexp a1,
           fold_constants_aexp a2)
    with
    | (ANum n1, ANum n2) => ANum (n1 * n2)
    | (a1', a2') => <{ a1' * a2' }>
    end
  end.

Example fold_aexp_ex1 :
  fold_constants_aexp <{ (1 + 2) * X }> = <{ 3 * X }>.
Proof. reflexivity. Qed.

Example fold_aexp_ex2 :
  fold_constants_aexp <{ X - ((0 * 6) + Y) }> = <{ X - (0 + Y) }>.
Proof. reflexivity. Qed.
```

**常量折叠**：子表达式两边都折叠成了字面量，就直接**在编译期把算术做掉**
（`1+2` 变 `3`；`0*6` 变 `0`——注意它**不会**再做 `0+Y → Y` 这类化简，一个
pass 只做一件事，原书如此，扩展是练习）。两个 `reflexivity` 实测输出正确。

```coq
Fixpoint fold_constants_bexp (b : bexp) : bexp :=
  match b with
  | <{ true }> => <{ true }>
  | <{ false }> => <{ false }>
  | <{ a1 = a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if n1 =? n2 then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' = a2' }>
      end
  | <{ a1 <> a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if negb (n1 =? n2) then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' <> a2' }>
      end
  | <{ a1 <= a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if n1 <=? n2 then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' <= a2' }>
      end
  | <{ a1 > a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if negb (n1 <=? n2) then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' > a2' }>
      end
  | <{ ~ b1 }> =>
      match fold_constants_bexp b1 with
      | <{ true }> => <{ false }>
      | <{ false }> => <{ true }>
      | b1' => <{ ~ b1' }>
      end
  | <{ b1 && b2 }> =>
      match (fold_constants_bexp b1,
             fold_constants_bexp b2) with
      | (<{ true }>, <{ true }>) => <{ true }>
      | (<{ true }>, <{ false }>) => <{ false }>
      | (<{ false }>, <{ true }>) => <{ false }>
      | (<{ false }>, <{ false }>) => <{ false }>
      | (b1', b2') => <{ b1' && b2' }>
      end
  end.

Example fold_bexp_ex1 :
  fold_constants_bexp <{ true && ~(1 + 1 = 3) }> = <{ true }>.
Proof. reflexivity. Qed.

Example fold_bexp_ex2 :
  fold_constants_bexp <{ X <= X + 0 }> = <{ X <= X + 0 }>.
Proof. reflexivity. Qed.
```

提升到布尔层：比较两侧都折成字面量就**编译期判定**（注意 `n1 =? n2` 是 Coq
的 nat 比较，`if` 后产出字面 true/false 项）；取反和合取也各有一张折叠表
（`&&` 的四行真值表）。`fold_bexp_ex2` 提醒边界：`X + 0` **不会**被认成常量
（X 是变量）——保守正确。

```coq
Theorem fold_constants_aexp_sound :
  atrans_sound fold_constants_aexp.
Proof.
  unfold atrans_sound. intros a. unfold aequiv. intros st.
  induction a; simpl;
    try reflexivity;
    try (destruct (fold_constants_aexp a1);
         destruct (fold_constants_aexp a2);
         rewrite IHa1; rewrite IHa2; reflexivity).
Qed.
```

算术层的可靠性是全章最优雅的证明：对 a 归纳；ANum/AId 平凡；三个双参数分支
`destruct` 两边的折叠结果——**当两边都是 ANum 时目标两侧的加/减/乘直接是
nat 的同一运算**（`rewrite IHa1, IHa2` 后 reflexivity 一网打尽），否则折叠
保持原构造子。五分支一气呵成。

```coq
Theorem fold_constants_bexp_sound :
  btrans_sound fold_constants_bexp.
Proof.
  unfold btrans_sound. intros b. unfold bequiv. intros st.
  induction b;
    try reflexivity.
  - (* BEq *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n =? n0); reflexivity.
  - (* BNeq *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n =? n0); reflexivity.
  - (* BLe *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n <=? n0); reflexivity.
  - (* BGt *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n <=? n0); reflexivity.
  - (* BNot *)
    simpl. remember (fold_constants_bexp b) as b' eqn:Heqb'.
    rewrite IHb.
    destruct b'; reflexivity.
  - (* BAnd *)
    simpl.
    remember (fold_constants_bexp b1) as b1' eqn:Heqb1'.
    remember (fold_constants_bexp b2) as b2' eqn:Heqb2'.
    rewrite IHb1. rewrite IHb2.
    destruct b1'; destruct b2'; reflexivity.
Qed.
```

布尔层的可靠性，四段比较分支共享一个骨架：**remember 折叠结果 → replace 把
原求值换成折叠后求值（可靠性反向用）→ destruct 两侧折叠形态**。BNot/BAnd 递归
用 IH。原书把 BLe/BGt 两支留作练习（`admit`），这里全部证完——BGt 的折叠定义
用 `negb (n1 <=? n2)`，所以它的证明与 BLe 同形。`replace ... by (...)` 的
`by` 子句当场还账，是最紧凑的"局部改写"写法。

```coq
Fixpoint fold_constants_com (c : com) : com :=
  match c with
  | <{ skip }> =>
      <{ skip }>
  | <{ w := a }> =>
      <{ w := (fold_constants_aexp a) }>
  | <{ c1 ; c2 }> =>
      <{ (fold_constants_com c1) ; (fold_constants_com c2) }>
  | <{ if b then c1 else c2 end }> =>
      match fold_constants_bexp b with
      | <{ true }> => fold_constants_com c1
      | <{ false }> => fold_constants_com c2
      | b' => <{ if b' then fold_constants_com c1
                       else fold_constants_com c2 end }>
      end
  | <{ while b do c end }> =>
      match fold_constants_bexp b with
      | <{ true }> => <{ while true do fold_constants_com c end }>
      | <{ false }> => <{ skip }>
      | b' => <{ while b' do fold_constants_com c end }>
      end
  end.

Example fold_com_ex1 :
  fold_constants_com
    <{ while X <= 100 do X := X + (2 + 3) end }>
  = <{ while X <= 100 do X := X + 5 end }>.
Proof. reflexivity. Qed.

Example fold_com_ex2 :
  fold_constants_com
    <{ if 1 + 2 <= 3 then X := 1 else X := 2 end }>
  = <{ X := 1 }>.
Proof. reflexivity. Qed.
```

命令层折叠是**威力全开**的一层：条件折成字面 true/false 时**整个 if 消失**
（`fold_com_ex2`：`1+2<=3` 折成 true，直接保留 then 分支）；while 的条件折成
false 时**整个循环变 skip**、折成 true 时保留为 `while true`（明确死循环——
比静默改掉诚实）。骨架分支（b' 形态）则递归折叠再重组。

```coq
Theorem fold_constants_com_sound :
  ctrans_sound fold_constants_com.
Proof.
  unfold ctrans_sound. intros c.
  induction c; simpl.
  - (* skip *) apply refl_cequiv.
  - (* := *) apply CAsgn_congruence.
              apply fold_constants_aexp_sound.
  - (* ; *) apply CSeq_congruence; assumption.
  - (* if *)
    assert (Hb : bequiv b (fold_constants_bexp b)).
    { apply fold_constants_bexp_sound. }
    destruct (fold_constants_bexp b) eqn:Heqb;
      try (apply CIf_congruence;
           [ exact Hb | exact IHc1 | exact IHc2 ]).
    + apply trans_cequiv with c1.
      * apply if_true. exact Hb.
      * exact IHc1.
    + apply trans_cequiv with c2.
      * apply if_false. exact Hb.
      * exact IHc2.
  - (* while *)
    assert (Hb : bequiv b (fold_constants_bexp b)).
    { apply fold_constants_bexp_sound. }
    destruct (fold_constants_bexp b) eqn:Heqb;
      try (apply CWhile_congruence; assumption).
    + (* 条件恒假：循环变 skip *)
      apply while_false. exact Hb.
Qed.
```

压轴定理的证明是**本章全部装备的合奏**——对 c 归纳，五个分支：

- skip：自反；
- 赋值：`CAsgn_congruence` + 算术层可靠性；
- 序列：`CSeq_congruence` + 两个 IH——**同余性在此兑现**：没有它，每个分支
  都得重推整个双向求值；
- **if**：`destruct (fold_constants_bexp b) eqn:Heqb` 按折叠结果分八种形态。
  六种"骨架"形态被 `try (apply CIf_congruence; [...])` 一次收掉（条件等价 Hb +
  两个 IH）；剩下 true/false 两种走 `trans_cequiv`：原 if ≈ 选中分支（if_true/
  if_false + Hb）≈ 折叠后的分支（IH）。
- **while**：同款 destruct；骨架形态由 `CWhile_congruence` 收（含**恒真**形态
  ——`while b do c` 与 `while true do fold c` 的等价由同余 + Hb 直接给出）；
  恒假形态走 `while_false`。原书把 while 分支留作练习，这里证完。

```coq
Print Assumptions fold_constants_com_sound.
```

repl 输出：

```
Closed under the global context
```

**零公理**——常量折叠的可靠性完全不依赖函数外延（`t_update_same` 引入了公理，
但折叠定理的证明链没有用到它；56.8 坑 7 说明这条公理只被哪些定理背走）。对比
62 章 preservation 的 `functional_extensionality_dep`——每个定理自己的公理
账本要自己查，`Print Assumptions` 是唯一的权威。

```coq
End Ex56Equiv.
```

### 56.8 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **赋值记号 RHS 槽位的 `constr` 限定是隐形炸弹**（56.1/56.6）：本章预览自
   61 章的副本带着 `y constr at level 85`，复合右端 `Y := X - X` 直接报
   `The term "X" has type "string" while it is expected to have type "nat"`
   ——`constr` 让右端回落主语法，`-` 变 `Nat.sub`。修复＝删掉 `constr`
   （53 章原版 `y at level 85` 在 com 条目内解析）。**61 章坑 9 的悬案就此
   了结**；if 条件位加括号（`(X = 0)`）是同族的稳健写法。抄记号工程时逐字符
   diff 原版。
2. **证"不等价"要自备具体状态**（56.2）：cequiv 的双向蕴含不能只 intro 一侧；
   正确姿势是取一个初态（`empty_st`）、让等价假设替你造出**矛盾的求值**
   （`X := 2` 到 `X !-> 1`），再反演。表等式的矛盾要 `f_equal` 投影到具体键
   （`fun m => m X`）才 discriminate 得动——函数等式直接 discriminate 不吃。
3. **反演产出的假设名时灵时不灵**（56.4）：loop_unrolling 里 `inversion H5`
   赌对了名字；更多时候（skip_right/seq_assoc）名字漂移，编译报 `No such
   hypothesis`。原则：能用 `match goal with Hs : ceval (CSeq _ _) _ _ |- _ =>
   ...` 按形状定位就别赌名字；赌错时编译器会立刻告诉你。
4. **inversion + subst 会吃掉哪个变量没有保证**（56.4 assign_aequiv）：-> 方向
   活下来的是 st'、<- 方向是 st——同名假设在两个分支要分别适配，写反报
   `The variable st was not found`。
5. **对 iff 直接 `rewrite` 在 9.3 触发 setoid 重写失败**（56.5）：`rewrite H`
   （H : cequiv 推出的 iff）报 `UNDEFINED EVARS`。改用 `proj1 (H st st') /
   proj2 (H st st')` 显式取分量——这也是 54 章 `ceval_and_ceval_step_coincide`
   风格证明在 9.3 下的正确写法。
6. **bequiv 的 rewrite 有方向**（56.6 CIf_congruence）：目标侧是 b' 时用
   `rewrite <- (Hb st)`（把目标里的 b' 换回 b、对上现有假设），反方向正向
   rewrite。方向写反报 `Found no subterm matching "beval ?M b"`。
7. **`t_update_same` 的公理账本要分清归属**（56.1/56.7）：它自身依赖
   `functional_extensionality`，identity_assignment/assign_aequiv 因此带公理；
   但 fold_constants_com_sound 的证明链不经过它——`Print Assumptions` 实测
   Closed。同一文件里定理的公理负担各查各的。
8. **`destruct (fold_constants_bexp b) eqn:Heqb` 会改写已有假设的类型**
   （56.7）：destruct 之后 assert 出来的 `Hb : bequiv b (fold b)` 被原地改写
   成 `bequiv b <{true}>`（八个形态各改各的）——后续引用 `Hb` 时按**改写后**
   的类型来，别再 `rewrite <- Heqb`（会找不到子项）。
9. **`trans_cequiv with c1` 的第二个子目标是 IH 不是 refl**（56.7）：折叠定理里
   链的中间命令是"原版"，目标是"折叠版"，所以第二段是 `exact IHc1`——
   `apply refl_cequiv` 报 `Unable to unify "fold_constants_com c1" with "c1"`。
   链式等价先想清楚两端各是谁。

---
上一章：[55 · 小步语义：执行即关系](55-smallstep.md) ｜ 下一章：[57 · 词法与语法解析](57-parsing.md) ｜ 返回：[README](../README.md)
