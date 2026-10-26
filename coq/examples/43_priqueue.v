(* 43 优先队列 —— keylist 表示、ri 不变量与 PRIQUEUE 签名规格验证 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex43Priqueue.

(* ---------- 43.1 规格先行：Module Type PRIQUEUE ---------- *)

(* 优先队列 ADT 的签名：priqueue 是抽象类型，priq 是表示不变量 ri，
   Abs 把具体表示连接到抽象的 key 多重集（用 list key 的
   Permutation 等价类刻画）。签名里的 Axiom 都是规格条款：
   它们等待实现模块逐条证明，而不是被当作公理使用。 *)

Module Type PRIQUEUE.
  Parameter priqueue : Type.
  Definition key := nat.

  Parameter empty : priqueue.
  Parameter insert : key -> priqueue -> priqueue.
  Parameter delete_max : priqueue -> option (key * priqueue).
  Parameter peek_max : priqueue -> option key.
  Parameter merge : priqueue -> priqueue -> priqueue.

  Parameter priq : priqueue -> Prop.
  Parameter Abs : priqueue -> list key -> Prop.
  Axiom can_relate : forall p, priq p -> exists al, Abs p al.
  Axiom abs_perm : forall p al bl,
    priq p -> Abs p al -> Abs p bl -> Permutation al bl.
  Axiom empty_priq : priq empty.
  Axiom empty_relate : Abs empty nil.
  Axiom insert_priq : forall k p, priq p -> priq (insert k p).
  Axiom insert_relate :
    forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al).
  Axiom delete_max_None_relate :
    forall p, priq p -> (Abs p nil <-> delete_max p = None).
  Axiom delete_max_Some_priq :
    forall p q k, priq p -> delete_max p = Some (k, q) -> priq q.
  Axiom delete_max_Some_relate :
    forall (p q : priqueue) k (pl ql : list key), priq p ->
      Abs p pl ->
      delete_max p = Some (k, q) ->
      Abs q ql ->
      Permutation pl (k :: ql) /\ Forall (ge k) ql.
  Axiom peek_max_correct :
    forall p k q, priq p ->
      delete_max p = Some (k, q) -> peek_max p = Some k.
  Axiom merge_priq : forall p q, priq p -> priq q -> priq (merge p q).
  Axiom merge_relate :
    forall p q pl ql al,
      priq p -> priq q ->
      Abs p pl -> Abs q ql -> Abs (merge p q) al ->
      Permutation al (pl ++ ql).
End PRIQUEUE.

(* ---------- 43.2 取最大元：select 与三条选择引理 ---------- *)

(* 第 35 章 select 的孪生兄弟：这次每次比较留下的是较大者。
   原书写 i >=? h，但 stdlib 9.2 已删掉 Nat.geb 与 >=? 记号，
   这里按同义改写成 h <=? i。 *)

Fixpoint select (i : nat) (l : list nat) : nat * list nat :=
  match l with
  | [] => (i, [])
  | h :: t =>
    if h <=? i
    then let (j, l') := select i t in (j, h :: l')
    else let (j, l') := select h t in (j, i :: l')
  end.

Example select_demo : select 3 [1; 4; 1; 5] = (5, [1; 3; 1; 4]).
Proof. reflexivity. Qed.

(* 原书练习 select_perm：输出表恰是输入表的重排（原书用 VFA 自定义
   bdestruct，这里换成标准 destruct + Nat.leb_le / Nat.leb_gt 兑换）。 *)

Lemma select_perm : forall i l j r,
  select i l = (j, r) -> Permutation (i :: l) (j :: r).
Proof.
  intros i l. revert i.
  induction l as [ | h t IH]; intros i j r H.
  - simpl in H. injection H as Hj Hr. subst.
    apply perm_skip. apply perm_nil.
  - simpl in H. destruct (h <=? i) eqn:E.
    + destruct (select i t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hr. subst.
      apply perm_trans with (h :: i :: t).
      * apply perm_swap.
      * apply perm_trans with (h :: j :: r').
        -- apply perm_skip. apply (IH i j r'). exact Et.
        -- apply perm_swap.
    + destruct (select h t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hr. subst.
      apply perm_trans with (i :: j :: r').
      * apply perm_skip. apply (IH h j r'). exact Et.
      * apply perm_swap.
Qed.

(* 原书练习 select_biggest_aux：若输出表里所有元素都不超过 j，
   则 j 不小于传入的种子 i。 *)

Lemma select_biggest_aux :
  forall i al j bl,
    Forall (ge j) bl ->
    select i al = (j, bl) ->
    j >= i.
Proof.
  intros i al. revert i.
  induction al as [ | a t IH]; intros i j bl HF H.
  - simpl in H. injection H as Hj Hbl. subst.
    lia.
  - simpl in H. destruct (a <=? i) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select i t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (HF' := Forall_inv_tail HF).
      assert (Hji := IH i j r' HF' Et).
      lia.
    + destruct (select a t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (Hji := Forall_inv HF).
      lia.
Qed.

(* 原书练习 select_biggest：返回的最大元压得住整个剩余表。 *)

Theorem select_biggest : forall i al j bl,
  select i al = (j, bl) -> Forall (ge j) bl.
Proof.
  intros i al. revert i.
  induction al as [ | a t IH]; intros i j bl H.
  - simpl in H. injection H as Hj Hbl. subst.
    constructor.
  - simpl in H. destruct (a <=? i) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select i t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (HF := IH i j r' Et).
      constructor.
      * assert (Hji := select_biggest_aux i t j r' HF Et).
        lia.
      * exact HF.
    + apply Nat.leb_gt in E.
      destruct (select a t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (HF := IH a j r' Et).
      constructor.
      * assert (Hja := select_biggest_aux a t j r' HF Et).
        lia.
      * exact HF.
Qed.

(* ---------- 43.3 实现：keylist 表示与五个操作 ---------- *)

(* 无序 keylist 实现：empty/insert 常数时间，delete_max 线性时间。 *)

Module List_Priqueue <: PRIQUEUE.

Definition key := nat.

Definition priqueue := list key.

Definition empty : priqueue := nil.
Definition insert (k : key) (p : priqueue) : priqueue := k :: p.
Definition delete_max (p : priqueue) : option (key * priqueue) :=
  match p with
  | i :: p' => Some (select i p')
  | nil => None
  end.
Definition peek_max (p : priqueue) : option key :=
  match delete_max p with
  | Some (k, _) => Some k
  | None => None
  end.
Definition merge (p q : priqueue) : priqueue := p ++ q.

Example pq_demo_1 :
  delete_max (insert 5 (insert 1 (insert 4 empty))) = Some (5, [1; 4]).
Proof. reflexivity. Qed.

Example pq_demo_2 :
  delete_max [3; 1; 4; 1; 5] = Some (5, [1; 3; 1; 4]).
Proof. reflexivity. Qed.

Example pq_demo_3 : peek_max [3; 1; 4; 1; 5] = Some 5.
Proof. reflexivity. Qed.

(* ---------- 43.4 ri 与 Abs：不变量与抽象关系 ---------- *)

(* 无序表实现里 ri（priq）平凡到恒为 True，Abs 也只是"表就是它自己"；
   但两者的接口形状与第 44 章的二项式堆实现完全一致。 *)

Definition priq (p : priqueue) := True.

Inductive Abs' : priqueue -> list key -> Prop :=
Abs_intro : forall p, Abs' p p.

Definition Abs := Abs'.

Lemma can_relate : forall p, priq p -> exists al, Abs p al.
Proof.
  intros p Hp. exists p. constructor.
Qed.

Lemma abs_perm : forall p al bl,
  priq p -> Abs p al -> Abs p bl -> Permutation al bl.
Proof.
  intros p al bl Hp Hal Hbl.
  inversion Hal; subst. inversion Hbl; subst.
  apply Permutation_refl.
Qed.

(* ---------- 43.5 操作的表征定理：补全原书全部练习 ---------- *)

Lemma empty_priq : priq empty.
Proof. constructor. Qed.

Lemma empty_relate : Abs empty nil.
Proof. constructor. Qed.

Lemma insert_priq : forall k p, priq p -> priq (insert k p).
Proof. intros. constructor. Qed.

Lemma insert_relate :
  forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al).
Proof.
  intros p al k Hp Hal. unfold insert. inversion Hal; subst.
  constructor.
Qed.

Lemma delete_max_Some_priq :
  forall p q k, priq p -> delete_max p = Some (k, q) -> priq q.
Proof. intros. constructor. Qed.

(* 原书练习 delete_max_None_relate：队列为空当且仅当删不出元素。 *)

Lemma delete_max_None_relate :
  forall p, priq p -> (Abs p nil <-> delete_max p = None).
Proof.
  intros p Hp. split.
  - intros Hal. inversion Hal; subst. reflexivity.
  - intros Hdel. destruct p as [ | i p'].
    + constructor.
    + simpl in Hdel. discriminate.
Qed.

(* 原书练习 delete_max_Some_relate：核心条款。
   43.2 的 select_perm 提供 Permutation，select_biggest 提供 Forall。 *)

Lemma delete_max_Some_relate :
  forall (p q : priqueue) k (pl ql : list key),
    priq p ->
    Abs p pl ->
    delete_max p = Some (k, q) ->
    Abs q ql ->
    Permutation pl (k :: ql) /\ Forall (ge k) ql.
Proof.
  intros p q k pl ql Hp Hpl Hdel Hql.
  destruct p as [ | i p'].
  - simpl in Hdel. discriminate.
  - simpl in Hdel.
    destruct (select i p') as [j r] eqn:E. simpl in Hdel.
    injection Hdel as Hk Hq. subst.
    inversion Hpl; subst. inversion Hql; subst.
    split.
    + apply (select_perm i p' k ql E).
    + apply (select_biggest i p' k ql E).
Qed.

Lemma peek_max_correct :
  forall p k q, priq p ->
    delete_max p = Some (k, q) -> peek_max p = Some k.
Proof.
  intros p k q Hp Hdel. unfold peek_max. rewrite Hdel.
  reflexivity.
Qed.

Lemma merge_priq :
  forall p q, priq p -> priq q -> priq (merge p q).
Proof. intros. constructor. Qed.

(* 原书练习 merge_relate：merge 的抽象效果就是两个多重集相加。 *)

Lemma merge_relate :
  forall p q pl ql al,
    priq p -> priq q ->
    Abs p pl -> Abs q ql -> Abs (merge p q) al ->
    Permutation al (pl ++ ql).
Proof.
  intros p q pl ql al Hp Hq Hpl Hql Hal.
  unfold merge.
  inversion Hpl; subst. inversion Hql; subst. inversion Hal; subst.
  apply Permutation_refl.
Qed.

(* ---------- 43.6 规格总定理与封装 ---------- *)

(* 把签名里的全部条款打包成一个定理：实现兑现了规格的每一条。 *)

Theorem priqueue_correct :
  (forall p, priq p -> exists al, Abs p al) /\
  (forall p al bl, priq p -> Abs p al -> Abs p bl -> Permutation al bl) /\
  priq empty /\
  Abs empty nil /\
  (forall k p, priq p -> priq (insert k p)) /\
  (forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al)) /\
  (forall p, priq p -> (Abs p nil <-> delete_max p = None)) /\
  (forall p q k, priq p -> delete_max p = Some (k, q) -> priq q) /\
  (forall (p q : priqueue) k (pl ql : list key),
     priq p -> Abs p pl -> delete_max p = Some (k, q) ->
     Abs q ql -> Permutation pl (k :: ql) /\ Forall (ge k) ql) /\
  (forall p k q, priq p ->
     delete_max p = Some (k, q) -> peek_max p = Some k) /\
  (forall p q, priq p -> priq q -> priq (merge p q)) /\
  (forall p q pl ql al, priq p -> priq q ->
     Abs p pl -> Abs q ql -> Abs (merge p q) al ->
     Permutation al (pl ++ ql)).
Proof.
  repeat apply conj.
  - exact can_relate.
  - exact abs_perm.
  - exact empty_priq.
  - exact empty_relate.
  - exact insert_priq.
  - exact insert_relate.
  - exact delete_max_None_relate.
  - exact delete_max_Some_priq.
  - exact delete_max_Some_relate.
  - exact peek_max_correct.
  - exact merge_priq.
  - exact merge_relate.
Qed.

End List_Priqueue.

(* 密封（用 : 而非 <:）把实现细节封死：priqueue 成为抽象类型，
   客户端无法再把 [3;1;4;1;5] 之类的具体表塞进去。 *)

Module Sealed_Priqueue : PRIQUEUE := List_Priqueue.

Fail Example sealed_compute :
  Sealed_Priqueue.delete_max [3; 1; 4; 1; 5] = Some (5, [1; 3; 1; 4]).

(* 透明视图（<: 不密封）下客户端仍可拿具体表直接计算。 *)

Example transparent_compute :
  List_Priqueue.delete_max [3; 1; 4; 1; 5] = Some (5, [1; 3; 1; 4]).
Proof. reflexivity. Qed.

(* 密封之后，客户端唯一能依赖的只剩签名条款本身。 *)

Example sealed_spec_use :
  forall p q k, Sealed_Priqueue.priq p ->
    Sealed_Priqueue.delete_max p = Some (k, q) ->
    Sealed_Priqueue.peek_max p = Some k.
Proof.
  intros p q k Hp Hdel.
  apply (Sealed_Priqueue.peek_max_correct p k q Hp Hdel).
Qed.

Print Assumptions List_Priqueue.priqueue_correct.

End Ex43Priqueue.
