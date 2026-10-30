# 111. Spectre、推测常时与选择性 SLH

对应示例：`../examples/111_speculative_ct.v`。本章只依赖 Rocq 标准库，不导入 SECF，也不依赖其他章节。读完本文即可理解示例中的语言、攻击模型、全部安全定义和证明组合方式，无需回查原书或另外阅读源码。

本章先自包含地重建密码学常时（CCT）基础，再建立 Spectre v1 的推测语义。随后给出两个具体的秘密泄露执行，定义选择性推测负载硬化（selective SLH），并用“理想语义安全 + 反向编译正确性”证明转换后程序的推测常时安全。原书此处的三个练习——推测位单调性、顺序执行安全迁移、store-then-load 程序的显式转换——都在示例中给出了完整答案。

## 111.0 安全问题与证明路线

顺序 CCT 的泄露模型不是具体秒数，而是分支方向以及数组读写的名字和下标。若两个公开输入等价的运行产生不同观察，攻击者就可能区分秘密。Spectre v1 增加了攻击者控制的误推测：即使程序先检查了数组边界，处理器也可能暂时沿错误分支执行，并在回滚前留下可观察的缓存轨迹。

本章的形式化路线如下：

1. 用 `cteval` 定义顺序执行及观察，用 CCT 类型系统排除秘密分支和秘密地址；
2. 用 `direction` 与 `spec_eval` 加入误推测、越界 load 重定向和越界 store 重定向；
3. 证明无推测时新语义与旧语义等价，同时用显式反例证明 CCT 本身不足以阻止 Spectre；
4. 用 `msf` 和公开 load 掩码定义 `sel_slh`；
5. 用直接在语义中掩码的 `ideal_eval` 证明理想安全；
6. 用反向编译正确性把硬化程序的实际执行还原为源程序的理想执行，最后组合出 `sel_slh_spec_ct_secure`。

原书后半的单子解释器只用于自动构造某些攻击执行见证，本章省略它。这里的两个攻击反例都手工给出了完整推导，最终主定理也只依赖上述两条证明链，因此省略解释器不影响任何安全结论。

## 111.1 自包含映射、表达式与数组命令

示例开头导入自然数、布尔值、列表、算术自动化、字符串、函数外延性和自然数度量归纳。`ListNotations` 提供列表字面量；所有定义置于模块中。`invert` 只是统一的反演 tactic，不是额外公理。

```coq
(* 111 Spectre、推测常时与选择性 SLH *)
(* 取材 Software Foundations 卷七 SpecCT.v 1525--3627；仅依赖 Stdlib。 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
From Stdlib Require Import Logic.FunctionalExtensionality Arith.PeanoNat.
Import ListNotations.
Set Warnings "-notation-overridden,-parsing,-deprecated-hint-without-locality".
Set Default Goal Selector "!".
Ltac invert H := inversion H; subst; clear H.

Module Ex111SpeculativeCT.

(* ---------- 111.1 自包含映射、表达式与数组命令 ---------- *)
```

全映射把每个字符串都映射到一个值。`t_empty` 是常量映射，`t_update` 是单点更新。前三条引理分别说明默认查询、同键更新和异键更新；后三条说明覆盖、无操作更新和不同键更新可交换。函数外延性把映射相等化为逐键相等，`String.eqb_spec` 同时提供布尔测试和对应命题，所以这些证明没有使用未证明假设。

```coq
Definition total_map (A : Type) := string -> A.
Definition t_empty {A : Type} (v : A) : total_map A := fun _ => v.
Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).
Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_apply_empty : forall (A : Type) (x : string) (v : A),
  (__ !-> v) x = v.
Proof. reflexivity. Qed.

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Lemma t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 -> (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Lemma t_update_shadow : forall (A : Type) (m : total_map A) x v1 v2,
  (x !-> v2 ; x !-> v1 ; m) = (x !-> v2 ; m).
Proof.
  intros A m x v1 v2. extensionality y. unfold t_update.
  destruct (String.eqb x y); reflexivity.
Qed.

Theorem t_update_same : forall (A : Type) (m : total_map A) x,
  (x !-> m x ; m) = m.
Proof.
  intros A m x. extensionality y. unfold t_update.
  destruct (String.eqb_spec x y); subst; reflexivity.
Qed.

Theorem t_update_permute : forall (A : Type) (m : total_map A) v1 v2 x1 x2,
  x2 <> x1 ->
  (x1 !-> v1 ; x2 !-> v2 ; m) = (x2 !-> v2 ; x1 !-> v1 ; m).
Proof.
  intros A m v1 v2 x1 x2 Hneq. extensionality y. unfold t_update.
  destruct (String.eqb_spec x1 y) as [Hxy1 | Hxy1];
    destruct (String.eqb_spec x2 y) as [Hxy2 | Hxy2]; subst.
  - contradiction.
  - reflexivity.
  - reflexivity.
  - reflexivity.
Qed.
```

表达式统一使用自然数：零表示假，非零表示真。`ACTIf` 是表达式层的条件选择，不产生命令分支观察，后面可安全地维护 `msf` 和掩码。`eval_binop` 定义算术、比较、合取和蕴含；减法是自然数截断减法。常用布尔形式都由这些基本运算定义。`AP`、`AS` 分别作为后文的公开数组和秘密数组名字。

```coq
Inductive binop : Type :=
  | BinPlus | BinMinus | BinMult | BinEq | BinLe | BinAnd | BinImpl.

Definition not_zero (n : nat) : bool := negb (n =? 0).
Definition bool_to_nat (b : bool) : nat := if b then 1 else 0.

Definition eval_binop (o : binop) (n1 n2 : nat) : nat :=
  match o with
  | BinPlus => n1 + n2
  | BinMinus => n1 - n2
  | BinMult => n1 * n2
  | BinEq => bool_to_nat (n1 =? n2)
  | BinLe => bool_to_nat (n1 <=? n2)
  | BinAnd => bool_to_nat (not_zero n1 && not_zero n2)
  | BinImpl => bool_to_nat (negb (not_zero n1) || not_zero n2)
  end.

Inductive exp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | ABin (o : binop) (e1 e2 : exp)
  | ACTIf (b : exp) (e1 e2 : exp).

Definition APlus := ABin BinPlus.
Definition AMinus := ABin BinMinus.
Definition AMult := ABin BinMult.
Definition BTrue := ANum 1.
Definition BFalse := ANum 0.
Definition BAnd := ABin BinAnd.
Definition BImpl := ABin BinImpl.
Definition BNot b := BImpl b BFalse.
Definition BOr e1 e2 := BImpl (BNot e1) e2.
Definition BEq := ABin BinEq.
Definition BNeq e1 e2 := BNot (BEq e1 e2).
Definition BLe := ABin BinLe.
Definition BGt e1 e2 := BNot (BLe e1 e2).
Definition BLt e1 e2 := BGt e2 e1.

Definition U : string := "U".
Definition V : string := "V".
Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".
Definition AP : string := "AP".
Definition AS : string := "AS".

Coercion AId : string >-> exp.
Coercion ANum : nat >-> exp.
```

自定义命令记号让表达式和命令接近常见伪代码。`com` 除赋值、顺序、条件和循环外，还有 `ALoad x a i` 与 `AStore a i e`。状态把变量映射为自然数，内存把数组名映射为自然数列表。`eval` 对表达式求值；`upd` 更新列表下标，越界更新保持列表不变，而语义规则会单独要求正常访问必须在界内。

```coq
Declare Custom Entry com.
Declare Scope com_scope.
Notation "<{ e }>" := e (at level 0, e custom com at level 99) : com_scope.
Notation "( x )" := x (in custom com, x at level 99) : com_scope.
Notation "x" := x (in custom com at level 0, x constr at level 0) : com_scope.
Notation "f x .. y" := (.. (f x) .. y)
  (in custom com at level 0, only parsing,
   f constr at level 0, x constr at level 9, y constr at level 9) : com_scope.
Notation "x + y" := (APlus x y)
  (in custom com at level 50, left associativity).
Notation "x - y" := (AMinus x y)
  (in custom com at level 50, left associativity).
Notation "x * y" := (AMult x y)
  (in custom com at level 40, left associativity).
Notation "'true'" := true (at level 1).
Notation "'true'" := BTrue (in custom com at level 0).
Notation "'false'" := false (at level 1).
Notation "'false'" := BFalse (in custom com at level 0).
Notation "x <= y" := (BLe x y)
  (in custom com at level 70, no associativity).
Notation "x > y" := (BGt x y)
  (in custom com at level 70, no associativity).
Notation "x < y" := (BLt x y)
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
Notation "be '?' e1 ':' e2" := (ACTIf be e1 e2)
  (in custom com at level 85, no associativity).

Inductive com : Type :=
  | Skip
  | Asgn (x : string) (e : exp)
  | Seq (c1 c2 : com)
  | If (be : exp) (c1 c2 : com)
  | While (be : exp) (c : com)
  | ALoad (x : string) (a : string) (i : exp)
  | AStore (a : string) (i : exp) (e : exp).

Notation "<{{ e }}>" := e (at level 0, e custom com at level 99) : com_scope.
Notation "'skip'" := Skip (in custom com at level 0) : com_scope.
Notation "x := y" := (Asgn x y)
  (in custom com at level 0, x constr at level 0,
   y custom com at level 85, no associativity) : com_scope.
Notation "x ; y" := (Seq x y)
  (in custom com at level 90, right associativity) : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (If x y z)
  (in custom com at level 89, x custom com at level 99,
   y at level 99, z at level 99) : com_scope.
Notation "'while' x 'do' y 'end'" := (While x y)
  (in custom com at level 89, x custom com at level 99,
   y at level 99) : com_scope.
Notation "x '<-' a '[' i ']'" := (ALoad x a i)
  (in custom com at level 0, x constr at level 0, a constr at level 0,
   i custom com at level 85, no associativity) : com_scope.
Notation "a '[' i ']' '<-' e" := (AStore a i e)
  (in custom com at level 0, a constr at level 0,
   i custom com at level 85, e custom com at level 85,
   no associativity) : com_scope.

Definition state := total_map nat.
Definition mem := total_map (list nat).

Fixpoint eval (s : state) (e : exp) : nat :=
  match e with
  | ANum n => n
  | AId x => s x
  | ABin b e1 e2 => eval_binop b (eval s e1) (eval s e2)
  | <{b ? e1 : e2}> =>
      if not_zero (eval s b) then eval s e1 else eval s e2
  end.

Lemma not_zero_eval_S : forall b n s,
  eval s b = S n -> not_zero (eval s b) = true.
Proof. intros b n s H. rewrite H. reflexivity. Qed.

Lemma not_zero_eval_O : forall b s,
  eval s b = 0 -> not_zero (eval s b) = false.
Proof. intros b s H. rewrite H. reflexivity. Qed.

Fixpoint upd (i : nat) (ns : list nat) (n : nat) : list nat :=
  match i, ns with
  | 0, _ :: ns' => n :: ns'
  | S i', n' :: ns' => n' :: upd i' ns' n
  | _, [] => ns
  end.

Notation "ns '.[' i ']'" := (nth i ns 0)
  (at level 2, left associativity, format "ns .[ i ]").
Notation "ns '.[' i '<-' n ']'" := (upd i ns n)
  (at level 2, left associativity, format "ns .[ i <- n ]").
```

顺序观察包括 `OBranch`、数组 load 地址和数组 store 地址。`cteval` 是大步语义：顺序组合连接观察，条件把真实分支方向放到观察头部，循环通过展开一次来定义。正常数组访问必须满足 `i < List.length (m a)`。因此，仅看顺序语义时，越界访问根本无法执行，更无法表达 Spectre 的“先误推测越界、再回滚”。

```coq
Inductive observation : Type :=
  | OBranch (b : bool)
  | OALoad (a : string) (i : nat)
  | OAStore (a : string) (i : nat).
Definition obs := list observation.

Reserved Notation
  "'<(' s , m ')>' '=[' c ']=>' '<(' s' , m' , os ')>'"
  (at level 40, c custom com at level 99,
   s constr, m constr, s' constr, m' constr at next level).

Inductive cteval : com -> state -> mem -> state -> mem -> obs -> Prop :=
  | CTE_Skip : forall s m,
      <(s, m)> =[ skip ]=> <(s, m, [])>
  | CTE_Asgn : forall s m e n x,
      eval s e = n ->
      <(s, m)> =[ x := e ]=> <(x !-> n ; s, m, [])>
  | CTE_Seq : forall c1 c2 s m s' m' s'' m'' os1 os2,
      <(s, m)> =[ c1 ]=> <(s', m', os1)> ->
      <(s', m')> =[ c2 ]=> <(s'', m'', os2)> ->
      <(s, m)> =[ c1 ; c2 ]=> <(s'', m'', os1 ++ os2)>
  | CTE_If : forall s m s' m' be c1 c2 os1,
      let c := if not_zero (eval s be) then c1 else c2 in
      <(s, m)> =[ c ]=> <(s', m', os1)> ->
      <(s, m)> =[ if be then c1 else c2 end ]=>
      <(s', m', [OBranch (not_zero (eval s be))] ++ os1)>
  | CTE_While : forall b s m s' m' os c,
      <(s, m)> =[ if b then (c ; while b do c end) else skip end ]=>
      <(s', m', os)> ->
      <(s, m)> =[ while b do c end ]=> <(s', m', os)>
  | CTE_ALoad : forall s m x a ie i,
      eval s ie = i -> i < List.length (m a) ->
      <(s, m)> =[ x <- a[ie] ]=>
      <(x !-> (m a).[i] ; s, m, [OALoad a i])>
  | CTE_AStore : forall s m a ie i e n,
      eval s e = n -> eval s ie = i -> i < List.length (m a) ->
      <(s, m)> =[ a[ie] <- e ]=>
      <(s, a !-> (m a).[i <- n] ; m, [OAStore a i])>
  where "<( s , m )> =[ c ]=> <( s' , m' , os )>" :=
    (cteval c s m s' m' os).
Hint Constructors cteval : core.
```

## 111.2 标签、公开等价与 CCT 类型系统

变量和数组各有 `public`/`secret` 标签。`pub_equiv L s1 s2` 只要求公开位置相同，秘密位置可以任意不同。更新公开位置时，两边必须写入相同值；更新秘密位置则没有此要求。`LXYZpub` 只公开 `X/Y/Z`，`LAPpub` 只公开 `AP`，所以示例中的 `W` 与 `AS` 默认秘密。`cct_secure` 要求任意两次公开等价的顺序执行产生相同观察。

```coq
(* ---------- 111.2 标签、公开等价与 CCT 类型系统 ---------- *)

Inductive label : Type := public | secret.
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

Definition pub_equiv (L : total_map label) {X : Type}
    (s1 s2 : total_map X) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall {X : Type} (L : total_map label) (s : total_map X),
  pub_equiv L s s.
Proof. intros X L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall {X : Type} (L : total_map label)
    (s1 s2 : total_map X),
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros X L s1 s2 H x Px.
  rewrite H; auto.
Qed.

Lemma pub_equiv_update_secret : forall {X : Type} (L : total_map label)
    (s1 s2 : total_map X) (x : string) (e1 e2 : X),
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Px y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - rewrite Px in Py. discriminate.
  - repeat rewrite t_update_neq; auto.
Qed.

Lemma pub_equiv_update_public : forall {X : Type} (L : total_map label)
    (s1 s2 : total_map X) (x : string) {e1 e2 : X},
  pub_equiv L s1 s2 -> e1 = e2 ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Eq y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - repeat rewrite t_update_eq; auto.
  - repeat rewrite t_update_neq; auto.
Qed.

Definition LXYZpub : label_map :=
  (X !-> public ; Y !-> public ; Z !-> public ; __ !-> secret).
Definition LAPpub : label_map := (AP !-> public ; __ !-> secret).

Definition cct_secure (L LA : label_map) (c : com) :=
  forall s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
    pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
    <(s1, m1)> =[ c ]=> <(s1', m1', os1)> ->
    <(s2, m2)> =[ c ]=> <(s2', m2', os2)> -> os1 = os2.
```

`join` 只要有一个秘密输入就得到秘密；`can_flow l1 l2` 禁止秘密流向公开。表达式标签由子表达式标签合成，`noninterferent_exp` 说明公开表达式的值只依赖公开状态。命令类型规则进一步要求条件为公开、load/store 下标为公开，并检查赋值和数组值的数据流。`cct_typechecker` 是这些规则的可计算版本，其 soundness 把布尔检查转成类型推导。

```coq
Definition join (l1 l2 : label) : label :=
  match l1 with public => l2 | secret => secret end.

Lemma join_public : forall {l1 l2},
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros [|] [|] H; try discriminate H; auto. Qed.

Definition can_flow (l1 l2 : label) : bool :=
  match l1, l2 with secret, public => false | _, _ => true end.

Lemma can_flow_secret_l : forall {l},
  can_flow secret l = true -> l = secret.
Proof. intros l H. destruct l; [discriminate H | reflexivity]. Qed.

Lemma can_flow_true_iff : forall {l1 l2},
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2; [discriminate H | reflexivity].
  - intros [H | H]; subst; [reflexivity | destruct l1; reflexivity].
Qed.

Reserved Notation "L '|-' a \in l" (at level 40).
Inductive exp_has_label (L : label_map) : exp -> label -> Prop :=
  | T_Num : forall n, L |- (ANum n) \in public
  | T_Id : forall x, L |- (AId x) \in (L x)
  | T_Bin : forall op e1 l1 e2 l2,
      L |- e1 \in l1 -> L |- e2 \in l2 ->
      L |- (ABin op e1 e2) \in (join l1 l2)
  | T_CTIf : forall be l e1 l1 e2 l2,
      L |- be \in l -> L |- e1 \in l1 -> L |- e2 \in l2 ->
      L |- <{be ? e1 : e2}> \in (join l (join l1 l2))
  where "L '|-' e '\in' l" := (exp_has_label L e l).
Hint Constructors exp_has_label : core.

Theorem noninterferent_exp : forall {L s1 s2 e},
  pub_equiv L s1 s2 -> L |- e \in public -> eval s1 e = eval s2 e.
Proof.
  intros L s1 s2 e Heq Ht. remember public as l.
  generalize dependent Heql. induction Ht; simpl; intros.
  - reflexivity.
  - eapply Heq; auto.
  - eapply join_public in Heql. destruct Heql as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2; reflexivity.
  - eapply join_public in Heql. destruct Heql as [HP HP']. subst.
    eapply join_public in HP'. destruct HP' as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2, IHHt3; reflexivity.
Qed.

Reserved Notation "L ';;' LA '|-ct-' c" (at level 40).
Inductive cct_well_typed (L LA : label_map) : com -> Prop :=
  | CCT_Skip : L ;; LA |-ct- <{{skip}}>
  | CCT_Asgn : forall x e l,
      L |- e \in l -> can_flow l (L x) = true ->
      L ;; LA |-ct- <{{x := e}}>
  | CCT_Seq : forall c1 c2,
      L ;; LA |-ct- c1 -> L ;; LA |-ct- c2 ->
      L ;; LA |-ct- <{{c1 ; c2}}>
  | CCT_If : forall b c1 c2,
      L |- b \in public -> L ;; LA |-ct- c1 -> L ;; LA |-ct- c2 ->
      L ;; LA |-ct- <{{if b then c1 else c2 end}}>
  | CCT_While : forall b c1,
      L |- b \in public -> L ;; LA |-ct- c1 ->
      L ;; LA |-ct- <{{while b do c1 end}}>
  | CCT_ALoad : forall x a i,
      L |- i \in public -> can_flow (LA a) (L x) = true ->
      L ;; LA |-ct- <{{x <- a[i]}}>
  | CCT_AStore : forall a i e l,
      L |- i \in public -> L |- e \in l -> can_flow l (LA a) = true ->
      L ;; LA |-ct- <{{a[i] <- e}}>
  where "L ;; LA '|-ct-' c" := (cct_well_typed L LA c).
Hint Constructors cct_well_typed : core.

Fixpoint label_of_exp (L : label_map) (e : exp) : label :=
  match e with
  | ANum n => public
  | AId x => L x
  | ABin _ e1 e2 => join (label_of_exp L e1) (label_of_exp L e2)
  | <{be ? e1 : e2}> =>
      join (label_of_exp L be) (join (label_of_exp L e1) (label_of_exp L e2))
  end.

Lemma label_of_exp_sound : forall L e, L |- e \in label_of_exp L e.
Proof. intros L e. induction e; constructor; eauto. Qed.

Fixpoint cct_typechecker (L LA : label_map) (c : com) : bool :=
  match c with
  | <{{skip}}> => true
  | <{{x := e}}> => can_flow (label_of_exp L e) (L x)
  | <{{c1 ; c2}}> => cct_typechecker L LA c1 && cct_typechecker L LA c2
  | <{{if b then c1 else c2 end}}> =>
      (label_of_exp L b =? public) &&
      cct_typechecker L LA c1 && cct_typechecker L LA c2
  | <{{while b do c1 end}}> =>
      (label_of_exp L b =? public) && cct_typechecker L LA c1
  | <{{x <- a[i]}}> =>
      (label_of_exp L i =? public) && can_flow (LA a) (L x)
  | <{{a[i] <- e}}> =>
      (label_of_exp L i =? public) && can_flow (label_of_exp L e) (LA a)
  end.

Theorem cct_typechecker_sound : forall L LA c,
  cct_typechecker L LA c = true -> L ;; LA |-ct- c.
Proof.
  intros L LA c. induction c; simpl in *; econstructor;
    try rewrite andb_true_iff in *; try tauto;
    eauto using label_of_exp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; try tauto.
    destruct H1 as [H11 H12]. apply label_eqb_eq in H11.
    rewrite <- H11. apply label_of_exp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; tauto.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. apply label_of_exp_sound.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. eapply label_of_exp_sound.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. eapply label_of_exp_sound.
  - destruct H as [H1 H2]. auto.
Qed.
```

顺序 CCT 有两个互补结果。`cct_well_typed_noninterferent` 保持最终状态和公开内存的公开等价，供顺序组合把第二段执行接起来；`cct_well_typed_secure` 则证明观察相同。赋值按公开/秘密分类，条件用公开表达式非干扰保证两边走同一分支，load/store 的下标同理。这里的关键限制是：所有推导都针对真实顺序路径，尚未考虑攻击者强迫走错误路径。

```coq
Lemma cct_well_typed_noninterferent :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
  L ;; LA |-ct- c -> pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
  <(s1, m1)> =[ c ]=> <(s1', m1', os1)> ->
  <(s2, m2)> =[ c ]=> <(s2', m2', os2)> ->
  pub_equiv L s1' s2' /\ pub_equiv LA m1' m2'.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Hwt Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1; intros os2' m2 Haeq m2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - split; auto.
  - split; auto. destruct l.
    + rewrite (noninterferent_exp Heq H10).
      eapply pub_equiv_update_public; auto.
    + apply can_flow_secret_l in H11. eapply pub_equiv_update_secret; auto.
  - edestruct IHHeval1_2; eauto.
    + eapply IHHeval1_1; eauto.
    + eapply IHHeval1_1; eauto.
  - eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4. rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - split; eauto. erewrite noninterferent_exp; eauto.
    destruct (LA a) eqn:LAa.
    + eapply pub_equiv_update_public; auto.
      eapply Haeq in LAa. rewrite LAa. reflexivity.
    + apply can_flow_secret_l in H15. eapply pub_equiv_update_secret; auto.
  - split; eauto. destruct (LA a) eqn:LAa; simpl in *.
    + eapply Haeq in LAa. rewrite LAa. destruct l; [| discriminate].
      eapply pub_equiv_update_public; auto.
      repeat erewrite (noninterferent_exp Heq); auto.
    + eapply pub_equiv_update_secret; auto.
Qed.

Theorem cct_well_typed_secure : forall L LA c,
  L ;; LA |-ct- c -> cct_secure L LA c.
Proof.
  unfold cct_secure.
  intros L LA c Hwt s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1; intros os2' a2 Haeq a2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - erewrite IHHeval1_2; [erewrite IHHeval1_1 | | | |];
      try reflexivity; try eassumption.
    + eapply cct_well_typed_noninterferent with (c := c1); eauto.
    + eapply cct_well_typed_noninterferent with (c := c1); eauto.
  - rewrite (noninterferent_exp Heq H11). f_equal; auto.
    eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4. rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
Qed.
```

## 111.3 Spectre 攻击与推测语义

先看一个能通过顺序 CCT 检查、却存在经典 Spectre v1 风险的程序。公开变量 `Y` 是下标，`AP` 是公开数组。真实顺序执行只有在 `Y < 3` 时才读取 `AP[Y]`，所以数组访问在界内；但误推测可能进入本应跳过的分支。第二个程序把三次公开数组合并后再分支，同样通过类型检查。两个 `Example` 都由可计算类型检查器和 soundness 定理直接证明。

```coq
(* ---------- 111.3 Spectre 攻击与推测语义 ---------- *)

Definition spec_insecure_prog :=
  <{{ if Y < 3 then
        X <- AP[Y];
        if X <= 5 then X := 5 else skip end
      else skip end }}>.

Example spec_insecure_prog_is_ct_well_typed :
  LXYZpub ;; LAPpub |-ct- spec_insecure_prog.
Proof. apply cct_typechecker_sound. reflexivity. Qed.

Definition spec_insecure_prog_2 :=
  <{{ X := 0;
      Y := 0;
      while Y < 3 do
        Z <- AP[Y];
        X := X + Z;
        Y := Y + 1
      end;
      if X <= 5 then X := 5 else skip end }}>.

Example spec_insecure_prog_2_is_ct_well_typed :
  LXYZpub ;; LAPpub |-ct- spec_insecure_prog_2.
Proof. apply cct_typechecker_sound. reflexivity. Qed.
```

推测执行由一条方向列表 `ds` 驱动，每个原子步骤消费列表前部相应的方向：

- `DStep` 表示按真实语义执行一步，例如走真实分支或进行界内数组访问；
- `DForce` 表示在条件处强制选择错误分支，并把推测位 `b` 置为 `true`。观察仍记录真实条件值，因为这里建模的是分支指令本身的可见方向，而不是误推测路径伪造一个不同的条件求值；
- `DLoad a' i'` 只在推测位已经为 `true` 且源代码中的访问越界时可用，把实际读取重定向到另一个界内位置 `a'[i']`。观察仍给出源指令的数组名和越界下标；
- `DStore a' i'` 与上一条类似，在误推测越界 store 时把实际写入重定向到界内位置。

`DForce` 只负责开始误推测，`DLoad`/`DStore` 负责描述随后微架构访问的实际目标。最后一个攻击程序先误推测 store，再从被改写的位置 load，用来展示只考虑越界读取还不够。

```coq
Inductive direction :=
  | DStep
  | DForce
  | DLoad (a : string) (i : nat)
  | DStore (a : string) (i : nat).

Definition dirs := list direction.

Definition spec_insecure_store_then_load :=
  <{{ if Y < 2 then
        AS[Y] <- W;
        X <- AP[0];
        if X <= 5 then X := 5 else skip end
      else skip end }}>.
```

`spec_eval` 在 `cteval` 的状态上增加推测位和方向列表。`Spec_If` 消费 `DStep` 并走真实分支；`Spec_If_F` 消费 `DForce`，走相反分支且之后一直处于误推测状态。顺序组合把方向列表和观察分别拼接。`Spec_ALoad_U` 与 `Spec_AStore_U` 是两条重定向规则，它们要求原下标越界、重定向目标在界内，并要求当前推测位为 `true`。这保证“越界”不是顺序程序凭空获得的能力，而只能发生在 `DForce` 已经开始的误推测中。

```coq
Reserved Notation
  "'<(' s , m , b , ds ')>' '=[' c ']=>' '<(' s' , m' , bb , os ')>'"
  (at level 40, c custom com at level 99,
   s constr, m constr, s' constr, m' constr at next level).

Inductive spec_eval : com -> state -> mem -> bool -> dirs ->
    state -> mem -> bool -> obs -> Prop :=
  | Spec_Skip : forall s m b,
      <(s, m, b, [])> =[ skip ]=> <(s, m, b, [])>
  | Spec_Asgn : forall s m b e n x,
      eval s e = n ->
      <(s, m, b, [])> =[ x := e ]=> <(x !-> n ; s, m, b, [])>
  | Spec_Seq : forall c1 c2 s m b s' m' b' s'' m'' b'' os1 os2 ds1 ds2,
      <(s, m, b, ds1)> =[ c1 ]=> <(s', m', b', os1)> ->
      <(s', m', b', ds2)> =[ c2 ]=> <(s'', m'', b'', os2)> ->
      <(s, m, b, ds1 ++ ds2)> =[ c1 ; c2 ]=>
      <(s'', m'', b'', os1 ++ os2)>
  | Spec_If : forall s m b s' m' b' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c1 else c2 in
      <(s, m, b, ds)> =[ c ]=> <(s', m', b', os1)> ->
      <(s, m, b, DStep :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', b', [OBranch (not_zero (eval s be))] ++ os1)>
  | Spec_If_F : forall s m b s' m' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c2 else c1 in
      <(s, m, true, ds)> =[ c ]=> <(s', m', true, os1)> ->
      <(s, m, b, DForce :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', true, [OBranch (not_zero (eval s be))] ++ os1)>
  | Spec_While : forall be s m b ds s' m' b' os c,
      <(s, m, b, ds)> =[ if be then (c ; while be do c end) else skip end ]=>
      <(s', m', b', os)> ->
      <(s, m, b, ds)> =[ while be do c end ]=> <(s', m', b', os)>
  | Spec_ALoad : forall s m b x a ie i,
      eval s ie = i -> i < List.length (m a) ->
      <(s, m, b, [DStep])> =[ x <- a[ie] ]=>
      <(x !-> (m a).[i] ; s, m, b, [OALoad a i])>
  | Spec_ALoad_U : forall s m x a ie i a' i',
      eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      <(s, m, true, [DLoad a' i'])> =[ x <- a[ie] ]=>
      <(x !-> (m a').[i'] ; s, m, true, [OALoad a i])>
  | Spec_AStore : forall s m b a ie i e n,
      eval s e = n -> eval s ie = i -> i < List.length (m a) ->
      <(s, m, b, [DStep])> =[ a[ie] <- e ]=>
      <(s, a !-> (m a).[i <- n] ; m, b, [OAStore a i])>
  | Spec_AStore_U : forall s m a ie i e n a' i',
      eval s e = n -> eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      <(s, m, true, [DStore a' i'])> =[ a[ie] <- e ]=>
      <(s, a' !-> (m a').[i' <- n] ; m, true, [OAStore a i])>
  where "<( s , m , b , ds )> =[ c ]=> <( s' , m' , bb , os )>" :=
    (spec_eval c s m b ds s' m' bb os).
Hint Constructors spec_eval : core.
```

第一个练习 `speculation_bit_monotonic` 的答案是：推测位一旦为 `true` 就不会重新变成 `false`。对执行推导直接归纳即可，因为只有 `Spec_If_F` 改变它，而它恰好改为 `true`。`speculation_needs_force` 进一步说明，从 `false` 到 `true` 的执行必定在方向列表中消费过 `DForce`；顺序情形用 `in_or_app` 判断它来自哪一段。这两个事实解释了为什么后面的 `msf` 只需记录“是否曾进入误推测”，不需要模拟回滚。

```coq
Lemma speculation_bit_monotonic :
  forall c s a b ds s' a' b' os,
  <(s, a, b, ds)> =[ c ]=> <(s', a', b', os)> ->
  b = true -> b' = true.
Proof.
  intros c s a b ds s' a' b' os Heval.
  induction Heval; intros Hb; subst; eauto.
Qed.

Lemma speculation_needs_force :
  forall c s a b ds s' a' b' os,
  <(s, a, b, ds)> =[ c ]=> <(s', a', b', os)> ->
  b = false -> b' = true -> In DForce ds.
Proof.
  intros c s a b ds s' a' b' os Heval Hb Hb'.
  induction Heval; subst; simpl; eauto; try discriminate.
  apply in_or_app. destruct b'; eauto.
Qed.
```

`seq_spec_eval` 把“没有误推测”定义为：从 `false` 开始、到 `false` 结束，并且方向列表中每个元素都是 `DStep`。`cteval_equiv_seq_spec_eval` 给出它与顺序语义的精确等价。正向归纳排除 `DForce`、`DLoad`、`DStore`；反向把每条 `cteval` 推导翻译成只含 `DStep` 的推导。第二个练习的答案是先把两个 `seq_spec_eval` 假设转成 `cteval`，再调用已证明的 `cct_well_typed_secure`。这同时说明：新语义确实是旧语义的保守扩展，顺序 CCT 的失败完全来自新增的误推测方向。

```coq
Definition seq_spec_eval (c : com) (s : state) (m : mem)
    (s' : state) (m' : mem) (os : obs) : Prop :=
  exists ds, (forall d, In d ds -> d = DStep) /\
    <(s, m, false, ds)> =[ c ]=> <(s', m', false, os)>.

Lemma cteval_equiv_seq_spec_eval : forall c s m s' m' os,
  seq_spec_eval c s m s' m' os <-> <(s, m)> =[ c ]=> <(s', m', os)>.
Proof.
  intros c s m s' m' os. unfold seq_spec_eval. split; intros H.
  - destruct H as [ds [Hstep Heval]].
    induction Heval; try (now econstructor; eauto).
    + eapply CTE_Seq.
      * eapply IHHeval1. intros d HdIn.
        assert (L : In d ds1 \/ In d ds2) by (left; assumption).
        eapply in_or_app in L. eapply Hstep in L. assumption.
      * eapply IHHeval2. intros d HdIn.
        assert (L : In d ds1 \/ In d ds2) by (right; assumption).
        eapply in_or_app in L. eapply Hstep in L. assumption.
    + eapply CTE_If. destruct (eval s be) eqn:Eqbe.
      * eapply IHHeval. intros d HdIn.
        apply (in_cons DStep d) in HdIn. apply Hstep in HdIn. assumption.
      * eapply IHHeval. intros d HdIn.
        apply (in_cons DStep d) in HdIn. apply Hstep in HdIn. assumption.
    + exfalso. assert (L : DForce <> DStep) by discriminate.
      apply L. apply (Hstep DForce). apply in_eq.
    + exfalso. assert (L : DLoad a' i' <> DStep) by discriminate.
      apply L. apply (Hstep (DLoad a' i')). apply in_eq.
    + exfalso. assert (L : DStore a' i' <> DStep) by discriminate.
      apply L. apply (Hstep (DStore a' i')). apply in_eq.
  - induction H.
    + exists []; split; [| eapply Spec_Skip].
      simpl. intros d Contra; destruct Contra.
    + exists []; split; [| eapply Spec_Asgn; assumption].
      simpl. intros d Contra; destruct Contra.
    + destruct IHcteval1 as [ds1 [Hds1 Heval1]].
      destruct IHcteval2 as [ds2 [Hds2 Heval2]].
      exists (ds1 ++ ds2). split; [| eapply Spec_Seq; eassumption].
      intros d HdIn. apply in_app_or in HdIn.
      destruct HdIn as [Hin1 | Hin2].
      * apply Hds1 in Hin1. assumption.
      * apply Hds2 in Hin2. assumption.
    + destruct IHcteval as [ds [Hds Heval]].
      exists (DStep :: ds). split.
      * intros d HdIn. apply in_inv in HdIn.
        destruct HdIn as [Heq | HIn];
          [symmetry; assumption | apply Hds; assumption].
      * subst c. eapply Spec_If. eauto.
    + destruct IHcteval as [ds [Hds Heval]].
      exists ds. split; [assumption |]. eapply Spec_While; assumption.
    + exists [DStep]. split.
      * simpl. intros d HdIn.
        destruct HdIn as [Heq | Contra]; [| destruct Contra].
        symmetry. assumption.
      * eapply Spec_ALoad; assumption.
    + exists [DStep]. split.
      * simpl. intros d HdIn.
        destruct HdIn as [Heq | Contra]; [| destruct Contra].
        symmetry. assumption.
      * eapply Spec_AStore; assumption.
Qed.

Corollary ct_well_typed_seq_spec_eval_ct_secure :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
  L ;; LA |-ct- c -> pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
  seq_spec_eval c s1 m1 s1' m1' os1 ->
  seq_spec_eval c s2 m2 s2' m2' os2 -> os1 = os2.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Hwt Heq Haeq Hseq1 Hseq2.
  apply cteval_equiv_seq_spec_eval in Hseq1, Hseq2.
  eapply cct_well_typed_secure; eauto.
Qed.
```

## 111.4 推测常时安全与攻击见证

`spec_ct_secure` 与顺序安全的差别是：两个运行从推测位 `false` 开始，并消费**同一条**方向列表。固定方向列表表示攻击者选择同一种误推测控制，再比较所有公开等价的输入；结束状态和推测位不必相同，只要求观察列表相同。

```coq
(* ---------- 111.4 推测常时安全与攻击见证 ---------- *)

Definition spec_ct_secure L LA c :=
  forall s1 s2 m1 m2 s1' s2' m1' m2' b1' b2' os1 os2 ds,
    pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
    <(s1, m1, false, ds)> =[ c ]=> <(s1', m1', b1', os1)> ->
    <(s2, m2, false, ds)> =[ c ]=> <(s2', m2', b2', os2)> ->
    os1 = os2.
```

第一个反例令 `Y = 3`，所以真实条件为假，却用 `DForce` 进入 then 分支。源访问 `AP[3]` 越界，`DLoad AS 0` 把实际读取重定向到秘密数组 `AS[0]`。两次执行的 `AS[0]` 分别为 4 和 7，因此后面的公开条件 `X <= 5` 分别走向 true 和 false。两边公开输入完全相同：状态只有 `Y=3`，公开数组 `AP` 也相同；唯一差别在秘密 `AS`。但最终观察在第二个 `OBranch` 处不同，直接否定 `spec_ct_secure`。证明中的 `assert` 是两条完整的 `spec_eval` 推导，不依赖省略的单子解释器。

```coq
Example spec_insecure_prog_is_spec_insecure :
  ~(spec_ct_secure LXYZpub LAPpub spec_insecure_prog).
Proof.
  unfold spec_insecure_prog. intros Hcs.
  remember (Y !-> 3 ; __ !-> 0) as s.
  remember (AP !-> [0;1;2] ; AS !-> [4;1] ; __ !-> []) as m1.
  remember (AP !-> [0;1;2] ; AS !-> [7;1] ; __ !-> []) as m2.
  remember (DForce :: [DLoad AS 0] ++ [DStep]) as ds.
  assert (Heval1 :
    <(s, m1, false, ds)> =[ spec_insecure_prog ]=>
    <(X !-> 5 ; X !-> 4 ; s, m1, true,
      [OBranch false] ++ [OALoad AP 3] ++ [OBranch true] ++ [])>).
  { unfold spec_insecure_prog; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_ALoad_U; simpl; eauto.
    - eapply Spec_If; simpl; auto. }
  assert (Heval2 :
    <(s, m2, false, ds)> =[ spec_insecure_prog ]=>
    <(X !-> 7 ; s, m2, true,
      [OBranch false] ++ [OALoad AP 3] ++ [OBranch false] ++ [])>).
  { unfold spec_insecure_prog; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_ALoad_U; simpl; eauto.
    - eapply Spec_If; simpl; auto. }
  subst. eapply Hcs in Heval1.
  + eapply Heval1 in Heval2. discriminate.
  + eapply pub_equiv_refl.
  + apply pub_equiv_update_public; auto.
    apply pub_equiv_update_secret; auto. apply pub_equiv_refl.
Qed.
```

第二个反例展示 store-then-load。秘密 `W` 分别为 4 和 7，公开状态与公开内存相同。误推测进入分支后，`AS[2]` 越界，`DStore AP 0` 把实际写入重定向到公开的 `AP[0]`；随后正常 load 读回这个值，并产生不同的分支观察。这里的重点不是最终公开内存是否应回滚，而是同一路径中后续的 load 能把误推测写入的差异转成观察差异，所以硬化必须同时覆盖界内与越界 load。

```coq
Example spec_insecure_store_then_load_is_spec_insecure :
  ~(spec_ct_secure LXYZpub LAPpub spec_insecure_store_then_load).
Proof.
  unfold spec_insecure_store_then_load. intros Hcs.
  remember (W !-> 4 ; Y !-> 2 ; __ !-> 0) as s1.
  remember (W !-> 7 ; Y !-> 2 ; __ !-> 0) as s2.
  remember (AP !-> [0;1;2] ; AS !-> [4;1] ; __ !-> []) as m.
  remember (DForce :: [DStore AP 0] ++ [DStep] ++ [DStep]) as ds.
  assert (Heval1 :
    <(s1, m, false, ds)> =[ spec_insecure_store_then_load ]=>
    <(X !-> 5 ; X !-> 4 ; s1, AP !-> [4;1;2] ; m, true,
      [OBranch false] ++ [OAStore AS 2] ++ [OALoad AP 0]
        ++ [OBranch true] ++ [])>).
  { unfold spec_insecure_store_then_load; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_AStore_U; simpl; eauto.
    - eapply Spec_Seq.
      + eapply Spec_ALoad; simpl; eauto.
      + eapply Spec_If; simpl; auto. }
  assert (Heval2 :
    <(s2, m, false, ds)> =[ spec_insecure_store_then_load ]=>
    <(X !-> 7 ; s2, AP !-> [7;1;2] ; m, true,
      [OBranch false] ++ [OAStore AS 2] ++ [OALoad AP 0]
        ++ [OBranch false] ++ [])>).
  { unfold spec_insecure_store_then_load; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_AStore_U; simpl; eauto.
    - eapply Spec_Seq.
      + eapply Spec_ALoad; simpl; eauto.
      + eapply Spec_If; simpl; auto. }
  subst. eapply Hcs in Heval1.
  + eapply Heval1 in Heval2. discriminate.
  + apply pub_equiv_update_secret; auto. apply pub_equiv_refl.
  + apply pub_equiv_refl.
Qed.
```

## 111.5 选择性 SLH

选择性 SLH 引入保留变量 `msf`（mis-speculation flag），用自然数 0/1 镜像推测位。进入条件分支时，表达式 `(be ? msf : 1)` 表示：若真实条件为真而执行 then，保留原标志；若真实条件为假却进入 then，把标志置 1。else 分支使用 `(be ? 1 : msf)`，同理检测反向误推测。循环把相同的更新放在每次展开的分支之前，因此正常迭代保持标志，错误展开会置 1。

对 load 的选择性硬化是：只有目标变量 `x` 为公开时，才在 `x <- a[i]` 后执行 `x := (msf <> 0) ? 0 : x`。若未误推测，`msf=0`，保留原值；若已误推测，强制写 0。秘密目标变量不必掩码，因为 CCT 类型系统禁止它随后直接流向公开值、公开分支或公开地址。

**为什么只屏蔽 load，不屏蔽 store？** 在本章的观察模型中，store 的数组名和下标已由公开表达式类型规则保证不依赖秘密，store 本身不会把内存值送入后续公开控制流；真正造成第二个 `OBranch` 泄露的是后续 load 取回秘密相关的值。对所有写入公开变量的 load 在误推测期间归零，既覆盖直接越界 load，也覆盖 store-then-load 中“先写、后读”的间接泄露。因此不必额外屏蔽 store 的值，store 仍按推测语义执行，编译正确性会原样保留它。

```coq
(* ---------- 111.5 选择性 SLH ---------- *)

Definition msf : string := "msf".

Fixpoint sel_slh (L : label_map) (c : com) :=
  match c with
  | <{{if be then c1 else c2 end}}> =>
      <{{if be then msf := (be ? msf : 1);
                    sel_slh L c1
               else msf := (be ? 1 : msf);
                    sel_slh L c2 end}}>
  | <{{while be do c end}}> =>
      <{{while be do
           msf := (be ? msf : 1);
           sel_slh L c end;
         msf := (be ? 1 : msf)}}>
  | <{{x <- a[i]}}> =>
      if L x =? public
      then <{{x <- a[i]; x := (msf <> 0) ? 0 : x}}>
      else <{{x <- a[i]}}>
  | <{{c1; c2}}> => <{{sel_slh L c1; sel_slh L c2}}>
  | _ => c
  end.
```

下面把两个攻击程序的转换结果完全展开。可以看到 store 没有改动，公开变量 `X` 的 load 后都增加掩码，秘密数组或秘密目标本身并未被一律拖慢；每个真实命令分支只增加无分支观察的表达式赋值和标志更新。第三个练习要求写出 store-then-load 的转换，这里不仅给出定义，还用 `reflexivity` 证明它与递归转换函数逐字相等。

```coq
Definition sel_slh_spec_insecure_prog :=
  <{{ if Y < 3 then
        msf := ((Y < 3) ? msf : 1);
        (X <- AP[Y]; X := (msf <> 0) ? 0 : X);
        if X <= 5 then
          msf := ((X <= 5) ? msf : 1);
          X := 5
        else msf := ((X <= 5) ? 1 : msf); skip end
      else msf := ((Y < 3) ? 1 : msf); skip end }}>.

Lemma sel_slh_spec_insecure_prog_check :
  sel_slh LXYZpub spec_insecure_prog = sel_slh_spec_insecure_prog.
Proof. reflexivity. Qed.

Definition sel_slh_spec_insecure_store_then_load :=
  <{{ if Y < 2 then
        msf := ((Y < 2) ? msf : 1);
        AS[Y] <- W;
        (X <- AP[0]; X := (msf <> 0) ? 0 : X);
        if X <= 5 then
          msf := ((X <= 5) ? msf : 1);
          X := 5
        else msf := ((X <= 5) ? 1 : msf); skip end
      else msf := ((Y < 2) ? 1 : msf); skip end }}>.

Lemma sel_slh_spec_insecure_store_then_load_check :
  sel_slh LXYZpub spec_insecure_store_then_load
  = sel_slh_spec_insecure_store_then_load.
Proof. reflexivity. Qed.
```

## 111.6 理想语义

直接证明 `sel_slh` 的安全会在每个 load 处反复展开 `msf` 赋值。更清晰的办法是先定义理想语义 `ideal_eval`：它的分支、方向和 store 规则与 `spec_eval` 相同，也不出现 `msf`，但在 load 规则中直接计算掩码后的值。正常 load 在 `b && (L x =? public)` 为真时写 0；越界重定向 load 已经隐含 `b=true`，所以只要目标公开就写 0。秘密目标仍读原值，store 仍不掩码。

因此，理想语义把“推测标志”和“选择性负载掩码”变成了两条局部语义条件。后面先证明这个语义安全，再证明硬化程序的普通推测执行恰好对应源程序的理想执行。

```coq
(* ---------- 111.6 理想语义 ---------- *)

Reserved Notation
  "L '|-i' '<(' s , m , b , ds ')>' '=[' c ']=>' '<(' s' , m' , bb , os ')>'"
  (at level 40, c custom com at level 99,
   s constr, m constr, s' constr, m' constr at next level).

Inductive ideal_eval (L : label_map) :
    com -> state -> mem -> bool -> dirs ->
    state -> mem -> bool -> obs -> Prop :=
  | Ideal_Skip : forall s m b,
      L |-i <(s, m, b, [])> =[ skip ]=> <(s, m, b, [])>
  | Ideal_Asgn : forall s m b e n x,
      eval s e = n ->
      L |-i <(s, m, b, [])> =[ x := e ]=> <(x !-> n ; s, m, b, [])>
  | Ideal_Seq : forall c1 c2 s m b s' m' b' s'' m'' b'' os1 os2 ds1 ds2,
      L |-i <(s, m, b, ds1)> =[ c1 ]=> <(s', m', b', os1)> ->
      L |-i <(s', m', b', ds2)> =[ c2 ]=> <(s'', m'', b'', os2)> ->
      L |-i <(s, m, b, ds1 ++ ds2)> =[ c1 ; c2 ]=>
      <(s'', m'', b'', os1 ++ os2)>
  | Ideal_If : forall s m b s' m' b' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c1 else c2 in
      L |-i <(s, m, b, ds)> =[ c ]=> <(s', m', b', os1)> ->
      L |-i <(s, m, b, DStep :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', b', [OBranch (not_zero (eval s be))] ++ os1)>
  | Ideal_If_F : forall s m b s' m' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c2 else c1 in
      L |-i <(s, m, true, ds)> =[ c ]=> <(s', m', true, os1)> ->
      L |-i <(s, m, b, DForce :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', true, [OBranch (not_zero (eval s be))] ++ os1)>
  | Ideal_While : forall be s m b ds s' m' b' os c,
      L |-i <(s, m, b, ds)> =[ if be then (c ; while be do c end) else skip end ]=>
      <(s', m', b', os)> ->
      L |-i <(s, m, b, ds)> =[ while be do c end ]=> <(s', m', b', os)>
  | Ideal_ALoad : forall s m b x a ie i,
      eval s ie = i -> i < List.length (m a) ->
      let v := if b && (L x =? public) then 0 else (m a).[i] in
      L |-i <(s, m, b, [DStep])> =[ x <- a[ie] ]=>
      <(x !-> v ; s, m, b, [OALoad a i])>
  | Ideal_ALoad_U : forall s m x a ie i a' i',
      eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      let v := if L x =? public then 0 else (m a').[i'] in
      L |-i <(s, m, true, [DLoad a' i'])> =[ x <- a[ie] ]=>
      <(x !-> v ; s, m, true, [OALoad a i])>
  | Ideal_AStore : forall s m b a ie i e n,
      eval s e = n -> eval s ie = i -> i < List.length (m a) ->
      L |-i <(s, m, b, [DStep])> =[ a[ie] <- e ]=>
      <(s, a !-> (m a).[i <- n] ; m, b, [OAStore a i])>
  | Ideal_AStore_U : forall s m a ie i e n a' i',
      eval s e = n -> eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      L |-i <(s, m, true, [DStore a' i'])> =[ a[ie] <- e ]=>
      <(s, a' !-> (m a').[i' <- n] ; m, true, [OAStore a i])>
  where "L |-i <( s , m , b , ds )> =[ c ]=> <( s' , m' , bb , os )>" :=
    (ideal_eval L c s m b ds s' m' bb os).
Hint Constructors ideal_eval : core.
```

## 111.7 前缀引理与理想语义非干扰

理想安全证明需要比顺序证明更强的不变量。首先，误推测 store 可能让两个公开内存不再等价，所以只能在推测位为 `false` 时要求公开内存等价；一旦 `DForce` 把它置为 `true`，就暂时放弃这项保证。其次，在顺序组合中，两边执行同一总方向列表，但第一段消费的前缀划分尚未知道相同，因此先允许两条已消费方向列表互有前缀关系，最后把“消费方向相同”也作为结论证明。

`prefix xs ys` 表示存在后缀 `zs` 使 `xs ++ zs = ys`。下列引理分别处理自反、空前缀、非空列表的头尾、共同前缀向后传递、拼接列表前缀比较以及从拼接相等得到前缀关系。它们都是后续按执行推导对齐方向列表的列表基础设施。

```coq
(* ---------- 111.7 前缀引理与理想语义非干扰 ---------- *)

Definition prefix {X : Type} (xs ys : list X) : Prop :=
  exists zs, xs ++ zs = ys.

Lemma prefix_refl : forall {X : Type} {ds : list X}, prefix ds ds.
Proof. intros X ds. exists []. apply app_nil_r. Qed.

Lemma prefix_nil : forall {X : Type} (ds : list X), prefix [] ds.
Proof. intros X ds. unfold prefix. eexists. simpl. reflexivity. Qed.

Lemma prefix_heads_and_tails : forall {X : Type} (h1 h2 : X) (t1 t2 : list X),
  prefix (h1 :: t1) (h2 :: t2) -> h1 = h2 /\ prefix t1 t2.
Proof.
  intros X h1 h2 t1 t2. unfold prefix. intros Hpre.
  destruct Hpre as [zs Hpre]; simpl in Hpre.
  inversion Hpre; subst. eauto.
Qed.

Lemma prefix_heads : forall {X : Type} (h1 h2 : X) (t1 t2 : list X),
  prefix (h1 :: t1) (h2 :: t2) -> h1 = h2.
Proof.
  intros X h1 h2 t1 t2 H. apply prefix_heads_and_tails in H; tauto.
Qed.

Lemma prefix_or_heads : forall {X : Type} (x y : X) (xs ys : list X),
  prefix (x :: xs) (y :: ys) \/ prefix (y :: ys) (x :: xs) -> x = y.
Proof.
  intros X x y xs ys H.
  destruct H as [H | H]; apply prefix_heads in H; congruence.
Qed.

Lemma prefix_cons : forall {X : Type} (d : X) (ds1 ds2 : list X),
  prefix ds1 ds2 <-> prefix (d :: ds1) (d :: ds2).
Proof.
  intros X d ds1 ds2. split; [unfold prefix |]; intros H.
  - destruct H; subst. eexists; simpl; eauto.
  - apply prefix_heads_and_tails in H. destruct H as [_ H]. assumption.
Qed.

Lemma prefix_app : forall {X : Type} {ds1 ds2 ds0 ds3 : list X},
  prefix (ds1 ++ ds2) (ds0 ++ ds3) -> prefix ds1 ds0 \/ prefix ds0 ds1.
Proof.
  intros X ds1. induction ds1 as [| d1 ds1' IH]; intros ds2 ds0 ds3 H.
  - left. apply prefix_nil.
  - destruct ds0 as [| d0 ds0'] eqn:D0.
    + right. apply prefix_nil.
    + simpl in H; apply prefix_heads_and_tails in H.
      destruct H as [Heq Hpre]; subst.
      apply IH in Hpre; destruct Hpre; [left | right];
        apply prefix_cons; assumption.
Qed.

Lemma prefix_append_front : forall {X : Type} {ds1 ds2 ds3 : list X},
  prefix (ds1 ++ ds2) (ds1 ++ ds3) -> prefix ds2 ds3.
Proof.
  intros X ds1. induction ds1 as [| d1 ds1' IH]; intros ds2 ds3 H.
  - auto.
  - simpl in H; apply prefix_cons in H. apply IH in H. assumption.
Qed.

Lemma app_eq_prefix : forall {X : Type} {ds1 ds2 ds1' ds2' : list X},
  ds1 ++ ds2 = ds1' ++ ds2' -> prefix ds1 ds1' \/ prefix ds1' ds1.
Proof.
  intros X ds1. induction ds1 as [| h1 t1 IH]; intros ds2 ds1' ds2' H.
  - left. apply prefix_nil.
  - destruct ds1' as [| h1' t1'] eqn:D1'.
    + right. apply prefix_nil.
    + simpl in H; inversion H; subst.
      apply IH in H2. destruct H2 as [HL | HR];
        [left | right]; apply prefix_cons; auto.
Qed.

Ltac split4 := split; [| split; [| split]].
```

`ct_well_typed_ideal_noninterferent_general` 是核心不变量。对两条具有共同初始推测位、公开状态等价、且方向列表互有前缀的执行，结论有四项：最终公开状态等价；最终推测位相同；若最终推测位为 `false`，最终公开内存等价；两条执行消费的方向列表完全相同。

证明对第一条理想执行归纳并反演第二条执行和类型推导。赋值和 load 按目标公开/秘密分类；公开 load 在误推测时两边都写 0，非误推测时公开内存等价给出相同读取值。store 只在最终推测位为 `false` 的分支恢复内存等价。条件分支用公开表达式非干扰对齐真实条件，再用前缀引理对齐消费方向；`DStep` 与 `DForce` 等不兼容的头部组合由 `prefix_or_heads` 排除。顺序组合先对第一段得到方向相同，再消去共同前缀并对第二段使用归纳假设。

```coq
Lemma ct_well_typed_ideal_noninterferent_general : forall L LA c,
  forall s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds1 ds2,
    L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
    (b = false -> pub_equiv LA m1 m2) ->
    (prefix ds1 ds2 \/ prefix ds2 ds1) ->
    L |-i <(s1, m1, b, ds1)> =[ c ]=> <(s1', m1', b1', os1)> ->
    L |-i <(s2, m2, b, ds2)> =[ c ]=> <(s2', m2', b2', os2)> ->
    pub_equiv L s1' s2' /\ b1' = b2' /\
      (b1' = false -> pub_equiv LA m1' m2') /\ ds1 = ds2.
Proof.
  intros L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds1 ds2
    Hwt Heq Haeq Hds Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2. generalize dependent b2'.
  generalize dependent ds2.
  induction Heval1; intros ds2X Hds b2' os2' a2 Haeq a2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - auto.
  - split4; auto. destruct (L x) eqn:EqLx.
    + eapply pub_equiv_update_public; eauto.
      eapply noninterferent_exp; eauto.
      destruct l; [auto | simpl in H14; discriminate].
    + eapply pub_equiv_update_secret; eauto.
  - destruct Hds as [Hpre | Hpre]; apply prefix_app in Hpre as Hds1.
    + eapply IHHeval1_1 in Hds1; eauto.
      destruct Hds1 as [Hstates [Hbits [Hmates Hdirections]]]. subst.
      eapply prefix_append_front in Hpre as Hds2.
      eapply IHHeval1_2 in H14; eauto. firstorder. subst. reflexivity.
    + eapply IHHeval1_1 with (ds2 := ds0) in H13; eauto; [| tauto].
      destruct H13 as [Hstates [Hbits [Hmates Hdirections]]]. subst.
      eapply prefix_append_front in Hpre as Hds2.
      eapply IHHeval1_2 in H14; eauto. firstorder; subst; reflexivity.
  - remember (if not_zero (eval s be) then c1 else c2) as c5.
    assert (G : L ;; LA |-ct- c5).
    { subst c5. destruct (eval s be); assumption. }
    assert (Gds : prefix ds ds0 \/ prefix ds0 ds).
    { destruct Hds as [Hds | Hds]; apply prefix_cons in Hds; tauto. }
    subst c4 c5. erewrite noninterferent_exp in H10.
    + specialize (IHHeval1 G _ Gds _ _ _ Haeq _ _ Heq _ H10).
      firstorder; congruence.
    + apply pub_equiv_sym. eassumption.
    + eassumption.
  - apply prefix_or_heads in Hds; inversion Hds.
  - apply prefix_or_heads in Hds; inversion Hds.
  - remember (if not_zero (eval s be) then c2 else c1) as c5.
    assert (G : L ;; LA |-ct- c5).
    { subst c5. destruct (eval s be); assumption. }
    assert (Gds : prefix ds ds0 \/ prefix ds0 ds).
    { destruct Hds as [Hds | Hds]; apply prefix_cons in Hds; tauto. }
    subst c4 c5. erewrite noninterferent_exp in H10.
    + assert (GG : true = false -> pub_equiv LA m a2).
      { intro Hc. discriminate. }
      specialize (IHHeval1 G _ Gds _ _ _ GG _ _ Heq _ H10).
      firstorder; congruence.
    + apply pub_equiv_sym. eassumption.
    + eassumption.
  - eapply IHHeval1; try eassumption. repeat constructor; eassumption.
  - split4; eauto. destruct (L x) eqn:EqLx; simpl.
    + eapply pub_equiv_update_public; eauto.
      destruct b2' eqn:Eqb2'; simpl; [reflexivity |].
      apply can_flow_true_iff in H18.
      destruct H18 as [Hapub | Contra]; [| congruence].
      subst v v1 v2. eapply Haeq in Hapub; [| reflexivity]. rewrite Hapub.
      eapply noninterferent_exp in Heq; eauto. rewrite Heq. reflexivity.
    + eapply pub_equiv_update_secret; eauto.
  - split4; eauto.
    + destruct (L x) eqn:EqLx.
      * simpl. eapply pub_equiv_update_public; eauto.
      * eapply pub_equiv_update_secret; eauto.
    + apply prefix_or_heads in Hds. inversion Hds.
  - split4; eauto.
    + destruct (L x) eqn:EqLx.
      * eapply pub_equiv_update_public; eauto.
      * eapply pub_equiv_update_secret; eauto.
    + apply prefix_or_heads in Hds. inversion Hds.
  - split4; eauto.
    + destruct (L x) eqn:EqLx.
      * eapply pub_equiv_update_public; eauto.
      * eapply pub_equiv_update_secret; eauto.
    + apply prefix_or_heads in Hds. inversion Hds. reflexivity.
  - split4; eauto. intro Hb2'. destruct (LA a) eqn:EqLAa.
    + eapply pub_equiv_update_public; eauto.
      destruct l eqn:Eql.
      * eapply noninterferent_exp in H19, H20; eauto. rewrite H19, H20.
        apply Haeq in Hb2'. apply Hb2' in EqLAa. rewrite EqLAa. reflexivity.
      * simpl in H21. discriminate.
    + eapply pub_equiv_update_secret; eauto.
  - apply prefix_or_heads in Hds. inversion Hds.
  - apply prefix_or_heads in Hds. inversion Hds.
  - split4; eauto.
    + intro contra. discriminate contra.
    + apply prefix_or_heads in Hds. inversion Hds. reflexivity.
Qed.
```

把两条方向列表都取为同一个 `ds`，就得到较易使用的非干扰推论。`ct_well_typed_ideal_same_dirs` 处理顺序组合的另一半：如果两个总方向列表相同，即 `ds2 ++ ds2' = ds1 ++ ds1'`，核心引理先给出 `ds1=ds2`，再用 `app_inv_head` 得到剩余方向 `ds1'=ds2'`。

```coq
Corollary ct_well_typed_ideal_noninterferent :
  forall L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds,
    L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
    (b = false -> pub_equiv LA m1 m2) ->
    L |-i <(s1, m1, b, ds)> =[ c ]=> <(s1', m1', b1', os1)> ->
    L |-i <(s2, m2, b, ds)> =[ c ]=> <(s2', m2', b2', os2)> ->
    pub_equiv L s1' s2' /\ b1' = b2' /\
      (b1' = false -> pub_equiv LA m1' m2').
Proof.
  intros L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds
    Hwt Heq Haeq Heval1 Heval2.
  eapply ct_well_typed_ideal_noninterferent_general in Heval2; eauto; try tauto.
  left. apply prefix_refl.
Qed.

Corollary ct_well_typed_ideal_same_dirs :
  forall L LA s1 s2 m1 m2 b ds1 ds2 c s1' s2' m1' m2'
    b1 b2 os1 os2 ds1' ds2',
  ds2 ++ ds2' = ds1 ++ ds1' ->
  L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
  (b = false -> pub_equiv LA m1 m2) ->
  L |-i <(s1, m1, b, ds1)> =[ c ]=> <(s1', m1', b1, os1)> ->
  L |-i <(s2, m2, b, ds2)> =[ c ]=> <(s2', m2', b2, os2)> ->
  ds1 = ds2 /\ ds1' = ds2'.
Proof.
  intros L LA s1 s2 m1 m2 b ds1 ds2 c s1' s2' m1' m2' b1 b2 os1 os2 ds1' ds2'
    Hds Hwt Heq Haeq Heval1 Heval2.
  pose proof Hds as H. symmetry in H. apply app_eq_prefix in H.
  eapply ct_well_typed_ideal_noninterferent_general in H;
    [| | | | apply Heval1 | apply Heval2]; try eassumption.
  destruct H as [_ [_ [_ H]]]. subst. split; [reflexivity |].
  apply app_inv_head in Hds. congruence.
Qed.
```

最后按理想执行归纳证明观察相同。赋值没有观察；条件和数组访问的首个观察由公开表达式非干扰对齐。顺序情形不能直接把第二段方向拿来归纳，所以先用 `ct_well_typed_ideal_same_dirs` 对齐两段方向，再用 `ct_well_typed_ideal_noninterferent` 传递第一段后的公开状态、推测位以及必要的内存等价。分支中的递归调用同理使用这些不变量。最终 `ideal_spec_ct_secure` 允许任意共同初始推测位，主定理稍后将其特化为 `false`。

```coq
Theorem ideal_spec_ct_secure :
  forall L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds,
    L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
    (b = false -> pub_equiv LA m1 m2) ->
    L |-i <(s1, m1, b, ds)> =[ c ]=> <(s1', m1', b1', os1)> ->
    L |-i <(s2, m2, b, ds)> =[ c ]=> <(s2', m2', b2', os2)> ->
    os1 = os2.
Proof.
  intros L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds
    Hwt Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2. generalize dependent b2'.
  induction Heval1; intros b2' os2' m2 Haeq m2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - eapply ct_well_typed_ideal_same_dirs in H1;
      [| | | | apply Heval1_1 | apply H5]; eauto.
    destruct H1 as [H1 H1']. subst.
    assert (NI1 : pub_equiv L s' s'0 /\ b' = b'0 /\
      (b' = false -> pub_equiv LA m' m'0)).
    { eapply ct_well_typed_ideal_noninterferent;
        [| | | eassumption | eassumption]; eauto. }
    destruct NI1 as [NI1eq [NIb NIaeq]]. subst.
    erewrite IHHeval1_2; [erewrite IHHeval1_1 | | | |];
      try reflexivity; try eassumption.
  - f_equal.
    + f_equal. eapply noninterferent_exp in Heq; [| eassumption].
      rewrite Heq. reflexivity.
    + eapply IHHeval1; try eassumption; try (destruct (eval s be); eassumption).
      subst c c4. erewrite (noninterferent_exp Heq H14); eassumption.
  - f_equal.
    + f_equal. eapply noninterferent_exp in Heq; [| eassumption].
      rewrite Heq. reflexivity.
    + eapply IHHeval1; try eassumption; try (destruct (eval s be); eassumption).
      * intro contra. discriminate contra.
      * subst c c4. erewrite noninterferent_exp; eassumption.
  - eapply IHHeval1; eauto.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
Qed.
```

## 111.8 未使用变量与大小归纳

`msf` 是编译器保留变量，所以源程序必须满足 `unused msf c`。`e_unused x e` 表示表达式不读取 `x`；`unused x c` 递归表示命令不给 `x` 赋值、不把 `x` 作为 load 目标，并且所有表达式都不读取它。这个假设保证 `msf` 完全由插入的硬化代码管理，源程序不会把标志当普通数据覆盖，也不会让源程序结果依赖初始标志。最终安全定理中的 `unused` 不是多余技术条件，而是编译正确性所依赖的所有权约定。

```coq
(* ---------- 111.8 未使用变量与大小归纳 ---------- *)

Fixpoint e_unused (x : string) (e : exp) : Prop :=
  match e with
  | ANum n => True
  | AId y => y <> x
  | ABin _ e1 e2 => e_unused x e1 /\ e_unused x e2
  | <{b ? e1 : e2}> => e_unused x b /\ e_unused x e1 /\ e_unused x e2
  end.

Fixpoint unused (x : string) (c : com) : Prop :=
  match c with
  | <{{skip}}> => True
  | <{{y := e}}> => y <> x /\ e_unused x e
  | <{{c1; c2}}> => unused x c1 /\ unused x c2
  | <{{if be then c1 else c2 end}}> =>
      e_unused x be /\ unused x c1 /\ unused x c2
  | <{{while be do c end}}> => e_unused x be /\ unused x c
  | <{{y <- a[i]}}> => y <> x /\ e_unused x i
  | <{{a[i] <- e}}> => e_unused x i /\ e_unused x e
  end.
```

编译正确性不能只对命令结构归纳：循环展开后，递归执行仍是同一个 `while`，命令没有变小；但它的剩余方向列表变短了。因此取度量 `size c ds = com_size c + List.length ds`。条件分支选择 `max` 计算大小，保证任一被取分支都严格变小；循环体命令变小，循环尾递归则靠方向列表变短。`size_ind` 把 Stdlib 的 `Nat.measure_induction` 包装成对命令和方向列表同时归纳的形式，`size_decreasing` 与 `size_auto` 负责两类减小：命令严格变小而方向不增多，或命令不增大而方向严格变少。

```coq
Fixpoint com_size (c : com) : nat :=
  match c with
  | <{{c1; c2}}> => 1 + com_size c1 + com_size c2
  | <{{if be then ct else cf end}}> => 1 + max (com_size ct) (com_size cf)
  | <{{while be do cw end}}> => 1 + com_size cw
  | <{{skip}}> => 1
  | _ => 1
  end.

Definition size (c : com) (ds : dirs) : nat := com_size c + List.length ds.

Lemma size_ind : forall P : com -> dirs -> Prop,
  (forall c ds,
    (forall c' ds', size c' ds' < size c ds -> P c' ds') -> P c ds) ->
  forall c ds, P c ds.
Proof.
  intros P H c ds.
  remember (fun c_ds => P (fst c_ds) (snd c_ds)) as P'.
  replace (P c ds) with (P' (c, ds)) by now rewrite HeqP'.
  eapply Nat.measure_induction with (f := fun c_ds => size (fst c_ds) (snd c_ds)).
  intros x H0. rewrite HeqP'. apply H. intros c' ds' Hlt.
  remember (c', ds') as c_ds'.
  replace (P c' ds') with (P' c_ds') by now rewrite Heqc_ds', HeqP'.
  apply H0. now rewrite Heqc_ds'.
Qed.

Lemma size_decreasing : forall c1 ds1 c2 ds2,
  (com_size c1 < com_size c2 /\ List.length ds1 <= List.length ds2) \/
  (com_size c1 <= com_size c2 /\ List.length ds1 < List.length ds2) ->
  size c1 ds1 < size c2 ds2.
Proof.
  intros c1 ds1 c2 ds2 [[Hcom Hdir] | [Hcom Hdir]];
    unfold size; lia.
Qed.

Ltac size_auto :=
  try (apply size_decreasing; left; split; simpl;
       [| repeat rewrite length_app]; lia);
  try (apply size_decreasing; right; split; simpl;
       [| repeat rewrite length_app]; lia);
  try (apply size_decreasing; left; split; simpl;
       [auto | repeat rewrite length_app; lia]).
```

第一条关于转换的关键不变量是 `sel_slh_flag`：若源命令不使用 `msf`，且初始 `s msf` 恰为推测位的 0/1 编码，则硬化程序结束时 `s' msf` 仍恰为结束推测位的编码。特别地，最终定理从 `b=false` 开始，所以假设 `s msf=0` 不是随意限制，而是这个不变量的初始对齐条件；两个初态都为 0 也保证即使 `L msf=public`，两个理想执行的初始公开状态仍等价。

证明使用上述大小归纳。顺序执行把标志不变量从第一段传到第二段；普通分支保持标志，强制错误分支把 `msf` 置 1；循环分别处理正常展开、错误展开和退出；load 后的掩码赋值不再改变 `msf`，而 `unused` 用于排除源赋值覆盖它。

```coq
Definition sel_slh_flag_prop (c : com) (ds : dirs) : Prop :=
  forall L s m (b : bool) s' m' (b' : bool) os,
  unused msf c -> s msf = (if b then 1 else 0) ->
  <(s, m, b, ds)> =[ sel_slh L c ]=> <(s', m', b', os)> ->
  s' msf = (if b' then 1 else 0).

Lemma sel_slh_flag : forall c ds, sel_slh_flag_prop c ds.
Proof.
  eapply size_ind. unfold sel_slh_flag_prop.
  intros c ds IH L s m b s' m' b' os Hunused Hstb Heval.
  destruct c; simpl in *; try (now inversion Heval; subst; eauto).
  - inversion Heval; subst. rewrite t_update_neq; tauto.
  - invert Heval.
    apply IH in H1; try tauto.
    + apply IH in H10; try tauto. size_auto.
    + size_auto.
  - invert Heval.
    + destruct (eval s be) eqn:Eqnbe.
      * invert H10. invert H1.
        apply IH in H11; try tauto.
        { size_auto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. assumption. }
      * invert H10. invert H1.
        apply IH in H11.
        { auto. }
        { size_auto. }
        { tauto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. assumption. }
    + destruct (eval s be) eqn:Eqnbe.
      * invert H10. invert H1.
        apply IH in H11; try tauto.
        { size_auto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. simpl. reflexivity. }
      * invert H10. invert H1.
        apply IH in H11; try tauto.
        { size_auto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. simpl. reflexivity. }
  - invert Heval. invert H1. invert H11.
    + destruct (eval s be) eqn:Eqnbe.
      * invert H12. inversion H10; subst; simpl.
        rewrite t_update_eq, Eqnbe; simpl. assumption.
      * invert H12.
        assert (Hwhile : <(s'1, m'1, b'1, (ds0 ++ ds2)%list)>
          =[ sel_slh L <{{while be do c end}}> ]=>
          <(s', m', b', (os3 ++ os2)%list)>).
        { simpl. eapply Spec_Seq; eassumption. }
        apply IH in Hwhile; eauto.
        { size_auto. }
        { clear Hwhile; clear H11. invert H1. invert H2. simpl in H12.
          apply IH in H12; try tauto.
          - size_auto.
          - rewrite t_update_eq, Eqnbe; simpl. assumption. }
    + destruct (eval s be) eqn:Eqnbe.
      * invert H12.
        assert (Hwhile : <(s'1, m'1, b'0, (ds0 ++ ds2)%list)>
          =[ sel_slh L <{{while be do c end}}> ]=>
          <(s', m', b', (os3 ++ os2)%list)>).
        { simpl. eapply Spec_Seq; eassumption. }
        apply IH in Hwhile; eauto.
        { size_auto. }
        { clear Hwhile; clear H11. invert H1. invert H2. simpl in H12.
          apply IH in H12; try tauto.
          - size_auto.
          - rewrite t_update_eq, Eqnbe; simpl. reflexivity. }
      * invert H12. inversion H10; subst; simpl.
        rewrite t_update_eq, Eqnbe; simpl. reflexivity.
  - destruct (L x) eqn:Eqnbe.
    + invert Heval. invert H10.
      rewrite t_update_neq; [| tauto].
      inversion H1; subst;
        try (rewrite t_update_neq; [assumption | tauto]).
    + inversion Heval; subst;
        try (rewrite t_update_neq; [assumption | tauto]).
Qed.
```

反向编译还要在源程序理想执行中恢复或改写 `msf`，而不影响其他变量和观察。`eval_unused_update` 证明未使用变量的任意更新不改变表达式值。`ideal_unused_overwrite` 把这个性质提升到整条理想执行：若源命令不使用 `X`，则在初态把 `X` 改为 `n`，执行仍可进行，只在终态保留同样的覆盖。

后两条引理是覆盖操作的两个方向：`ideal_unused_update` 从一个人为设置 `X=n` 的执行还原到原初态，并把终态的 `X` 恢复为原来的 `s X`；`ideal_unused_update_rev` 则把恢复后的执行重新覆盖为任意 `n`。证明依赖更新覆盖、无操作更新和交换引理。这些引理使编译正确性可以消去硬化代码留下的 `msf`，而不改变源程序的理想语义。

```coq
Lemma eval_unused_update : forall X s n,
  forall ae, e_unused X ae -> eval (X !-> n ; s) ae = eval s ae.
Proof.
  intros X s n. induction ae; intros; simpl in *; try reflexivity.
  - rewrite t_update_neq; eauto.
  - destruct H. rewrite IHae1; [| tauto]. rewrite IHae2; [| tauto].
    reflexivity.
  - destruct H. destruct H0. rewrite IHae1, IHae2, IHae3; auto.
Qed.

Lemma ideal_unused_overwrite : forall L s m b ds c s' m' b' os X n,
  unused X c ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(s', m', b', os)> ->
  L |-i <(X !-> n ; s, m, b, ds)> =[ c ]=> <(X !-> n ; s', m', b', os)>.
Proof.
  intros L s m b ds c s' m' b' os X n Hu H. induction H; simpl in Hu.
  - econstructor.
  - rewrite t_update_permute; [| tauto]. econstructor.
    rewrite eval_unused_update; tauto.
  - econstructor.
    + apply IHideal_eval1; tauto.
    + apply IHideal_eval2; tauto.
  - rewrite <- eval_unused_update with (X := X) (n := n); [| tauto].
    econstructor. rewrite eval_unused_update; [| tauto].
    destruct (eval s be) eqn:D; apply IHideal_eval; tauto.
  - rewrite <- eval_unused_update with (X := X) (n := n); [| tauto].
    econstructor. rewrite eval_unused_update; [| tauto].
    destruct (eval s be) eqn:D; apply IHideal_eval; tauto.
  - econstructor. apply IHideal_eval. simpl; tauto.
  - rewrite t_update_permute; [| tauto]. econstructor; [| assumption].
    rewrite eval_unused_update; tauto.
  - rewrite t_update_permute; [| tauto]. econstructor; try assumption.
    rewrite eval_unused_update; tauto.
  - econstructor; try assumption.
    + rewrite eval_unused_update; tauto.
    + rewrite eval_unused_update; tauto.
  - econstructor; try assumption.
    + rewrite eval_unused_update; tauto.
    + rewrite eval_unused_update; tauto.
Qed.

Lemma ideal_unused_update : forall L s m b ds c s' m' b' os X n,
  unused X c ->
  L |-i <(X !-> n ; s, m, b, ds)> =[ c ]=> <(X !-> n ; s', m', b', os)> ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(X !-> s X ; s', m', b', os)>.
Proof.
  intros L s m b ds c s' m' b' os X n Hu Heval.
  eapply ideal_unused_overwrite with (X := X) (n := s X) in Heval; [| assumption].
  repeat rewrite t_update_shadow in Heval.
  rewrite t_update_same in Heval. assumption.
Qed.

Lemma ideal_unused_update_rev : forall L s m b ds c s' m' b' os X n,
  unused X c ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(X !-> s X ; s', m', b', os)> ->
  L |-i <(X !-> n ; s, m, b, ds)> =[ c ]=> <(X !-> n ; s', m', b', os)>.
Proof.
  intros L s m b ds c s' m' b' os X n Hu H.
  eapply ideal_unused_overwrite in H; [| eassumption].
  rewrite t_update_shadow in H. eassumption.
Qed.
```

## 111.9 反向编译正确性与最终安全定理

`sel_slh_compiler_correctness` 把两个语义连接起来：给定源命令不使用 `msf`、初始标志与推测位一致，以及硬化命令的一条 `spec_eval` 执行，可以构造源命令的一条 `ideal_eval` 执行。初态、内存、推测位、方向列表、终态内存、结束推测位和观察全部保持；唯一差别是理想执行的结束状态把 `msf` 恢复成初始 `s msf`，因为保留变量不属于源程序的可见语义。

这也是“反向”编译正确性：从转换后程序的实际运行反推出源程序的理想运行。证明仍按 `com_size + 方向长度` 归纳。顺序执行先用 `sel_slh_flag` 对齐中间标志，再用未使用变量引理恢复 `msf`；条件和循环把插入的标志更新与 `Ideal_If`/`Ideal_If_F` 对齐；公开 load 的两种执行经过布尔化简后恰好得到 `Ideal_ALoad` 或 `Ideal_ALoad_U` 的掩码值；秘密 load 与 store 直接复用原推导。

```coq
(* ---------- 111.9 反向编译正确性与最终安全定理 ---------- *)

Definition sel_slh_compiler_correctness_prop (c : com) (ds : dirs) : Prop :=
  forall L s m (b : bool) s' m' b' os,
  unused msf c -> s msf = (if b then 1 else 0) ->
  <(s, m, b, ds)> =[ sel_slh L c ]=> <(s', m', b', os)> ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(msf !-> s msf ; s', m', b', os)>.

Lemma sel_slh_compiler_correctness : forall c ds,
  sel_slh_compiler_correctness_prop c ds.
Proof.
  apply size_ind. unfold sel_slh_compiler_correctness_prop.
  intros c ds IH L s m b s' m' b' os Hunused Hstb Heval.
  destruct c; simpl in *; invert Heval;
    try (destruct (L x); discriminate).
  - rewrite t_update_same. apply Ideal_Skip.
  - rewrite t_update_permute; [| tauto]. rewrite t_update_same.
    constructor. reflexivity.
  - eapply Ideal_Seq.
    + apply IH in H1; try tauto.
      * eassumption.
      * size_auto.
    + apply sel_slh_flag in H1 as Hstb'0; try tauto.
      apply IH in H10; try tauto.
      * eapply ideal_unused_update_rev; try tauto.
      * size_auto.
  - destruct (eval s be) eqn:Eqnbe; invert H10; invert H1; simpl in *.
    + apply IH in H11; try tauto.
      * rewrite <- Eqnbe. apply Ideal_If. rewrite Eqnbe in *.
        rewrite t_update_same in H11. apply H11.
      * size_auto.
      * rewrite t_update_eq. rewrite Eqnbe. assumption.
    + apply IH in H11; try tauto.
      * rewrite <- Eqnbe. apply Ideal_If. rewrite Eqnbe in *.
        rewrite t_update_same in H11. apply H11.
      * size_auto.
      * rewrite t_update_eq. rewrite Eqnbe. assumption.
  - destruct (eval s be) eqn:Eqnbe; inversion H10; inversion H1;
      subst; simpl in *; clear H10; clear H1; rewrite Eqnbe in H11.
    + rewrite <- Eqnbe. apply Ideal_If_F. rewrite Eqnbe.
      apply IH in H11; try tauto.
      * rewrite t_update_eq in H11. apply ideal_unused_update in H11; try tauto.
      * size_auto.
    + rewrite <- Eqnbe. apply Ideal_If_F. rewrite Eqnbe.
      apply IH in H11; try tauto.
      * rewrite t_update_eq in H11. apply ideal_unused_update in H11; try tauto.
      * size_auto.
  - eapply Ideal_While. invert H1. invert H11; simpl in *.
    + assert (Lnil : os2 = [] /\ ds2 = []).
      { inversion H10; subst; eauto. }
      destruct Lnil; subst; simpl. apply Ideal_If.
      destruct (eval s be) eqn:Eqnbe.
      * invert H12. invert H10; simpl in *.
        rewrite Eqnbe. repeat rewrite t_update_same. apply Ideal_Skip.
      * invert H12. invert H1. invert H2; simpl in *.
        assert (Hwhile : <(s'1, m'1, b'1, ds2)>
          =[ sel_slh L <{{while be do c end}}> ]=> <(s', m', b', os2)>).
        { simpl. replace ds2 with (ds2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          replace os2 with (os2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          eapply Spec_Seq; eassumption. }
        repeat rewrite app_nil_r. eapply Ideal_Seq.
        { rewrite Eqnbe in H13. rewrite t_update_same in H13.
          apply IH in H13; try tauto.
          - eassumption.
          - size_auto. }
        { apply IH in Hwhile; auto.
          - eapply ideal_unused_update_rev; eauto.
          - size_auto.
          - apply sel_slh_flag in H13; try tauto.
            rewrite t_update_eq. rewrite Eqnbe. assumption. }
    + assert (Lnil : os2 = [] /\ ds2 = [] /\ b' = true).
      { inversion H10; subst; eauto. }
      destruct Lnil as [? [? ?]]; subst; simpl. apply Ideal_If_F.
      destruct (eval s be) eqn:Eqnbe.
      * invert H12. invert H1. invert H2; simpl in *.
        assert (Hwhile : <(s'1, m'1, b', ds2)>
          =[ sel_slh L <{{while be do c end}}> ]=> <(s', m', true, os2)>).
        { simpl. replace ds2 with (ds2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          replace os2 with (os2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          eapply Spec_Seq; eassumption. }
        repeat rewrite app_nil_r. eapply Ideal_Seq.
        { rewrite Eqnbe in H13. apply IH in H13; try tauto.
          - rewrite t_update_eq in H13.
            apply ideal_unused_update in H13; [| tauto]. eassumption.
          - size_auto. }
        { apply IH in Hwhile; auto.
          - rewrite Eqnbe in H13. apply IH in H13; try tauto.
            + apply ideal_unused_update_rev; eauto.
            + size_auto.
          - size_auto.
          - apply sel_slh_flag in H13; try tauto.
            rewrite Eqnbe. rewrite t_update_eq. reflexivity. }
      * invert H12. invert H10; simpl in *.
        rewrite Eqnbe. rewrite t_update_shadow. rewrite t_update_same.
        apply Ideal_Skip.
  - destruct (L x) eqn:Heq; try discriminate H.
    injection H; intros; subst; clear H.
    inversion H1; clear H1; subst. rewrite <- app_nil_r in *.
    inversion H0; clear H0; subst; simpl in *.
    * rewrite t_update_neq; [| tauto]. rewrite Hstb.
      rewrite t_update_shadow. rewrite t_update_permute; [| tauto].
      rewrite t_update_eq. simpl.
      rewrite <- Hstb at 1. rewrite t_update_same.
      replace (not_zero (bool_to_nat (negb (not_zero
        (bool_to_nat ((if b' then 1 else 0) =? 0)%nat)) || not_zero 0)))
        with (b' && (L x =? public))
        by (rewrite Heq; destruct b'; simpl; reflexivity).
      eapply Ideal_ALoad; eauto.
    * rewrite t_update_neq; [| tauto]. rewrite Hstb.
      rewrite t_update_shadow. rewrite t_update_permute; [| tauto].
      simpl. rewrite <- Hstb at 1. rewrite t_update_same.
      replace (x !-> 0 ; s)
        with (x !-> if L x =? public then 0 else (m' a').[i'] ; s)
        by (rewrite Heq; reflexivity).
      eapply Ideal_ALoad_U; eauto.
  - destruct (L x) eqn:Heq; try discriminate H.
    inversion H; clear H; subst.
    rewrite t_update_permute; [| tauto]. rewrite t_update_same.
    replace (x !-> (m' a).[eval s i] ; s)
      with (x !-> if b' && (L x =? public) then 0 else (m' a).[eval s i] ; s)
      by (rewrite Heq; destruct b'; reflexivity).
    eapply Ideal_ALoad; eauto.
  - destruct (L x) eqn:Heq; try discriminate H.
    inversion H; clear H; subst.
    rewrite t_update_permute; [| tauto]. rewrite t_update_same.
    replace (x !-> (m' a').[i'] ; s)
      with (x !-> if L x =? public then 0 else (m' a').[i'] ; s)
      by (rewrite Heq; reflexivity).
    eapply Ideal_ALoad_U; eauto.
  - rewrite t_update_same. apply Ideal_AStore; tauto.
  - rewrite t_update_same. apply Ideal_AStore_U; tauto.
Qed.
```

最终定理把完整证明链压缩成三次调用。假设源程序通过 CCT 类型检查、不使用 `msf`，两个初态的标志均为 0，公开状态和公开数组分别等价，并且两个硬化程序从 `false` 开始消费同一方向列表。

1. 对 `Heval1` 使用 `sel_slh_compiler_correctness`：`unused`、`s1 msf=0` 和 `false` 的标志编码恰好满足前提，得到第一条源程序理想执行；
2. 对 `Heval2` 同样处理，得到第二条源程序理想执行。两条执行仍有相同方向列表和观察 `os1`/`os2`；
3. 对这两条理想执行使用 `ideal_spec_ct_secure`。CCT 类型推导和公开等价是直接前提，初始 `b=false` 使内存等价前提化为已有 `pub_equiv LA m1 m2`，于是结论正是 `os1=os2`。

因此最终安全不是只对两个攻击实例成立，而是对任意满足类型与保留变量条件的源命令成立。整条链没有使用单子解释器，也没有把任何辅助结论留作未证明假设。最后的 `End` 关闭自包含模块。

```coq
Theorem sel_slh_spec_ct_secure :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' b1' b2' os1 os2 ds,
  L ;; LA |-ct- c -> unused msf c ->
  s1 msf = 0 -> s2 msf = 0 ->
  pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
  <(s1, m1, false, ds)> =[ sel_slh L c ]=> <(s1', m1', b1', os1)> ->
  <(s2, m2, false, ds)> =[ sel_slh L c ]=> <(s2', m2', b2', os2)> ->
  os1 = os2.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' b1' b2' os1 os2 ds
    Hwt Hunused Hs1b Hs2b Hequiv Haequiv Heval1 Heval2.
  eapply sel_slh_compiler_correctness in Heval1; try assumption.
  eapply sel_slh_compiler_correctness in Heval2; try assumption.
  eapply ideal_spec_ct_secure; eauto.
Qed.

End Ex111SpeculativeCT.
```

