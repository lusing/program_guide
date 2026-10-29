(* 70 列表段 —— lseg：部分链表的分离逻辑谓词与 append 的原地验证 *)

Require Import VST.floyd.proofauto.
Require Import VC.append.

#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.

(* 70.1 listrep：从上一章（链表反转）继承的建模范式 *)

Definition t_list := Tstruct _list noattr.

Fixpoint listrep (sigma: list val) (p: val) : mpred :=
 match sigma with
 | h::hs =>
    EX y:val,
      data_at Tsh t_list (h,y) p  *  listrep hs y
 | nil =>
    !! (p = nullval) && emp
 end.

Arguments listrep sigma p : simpl never.

(* 70.2 append 的函数规格 *)

Definition append_spec :=
 DECLARE _append
  WITH x: val, y: val, s1: list val, s2: list val
  PRE [ tptr t_list , tptr t_list]
     PROP()
     PARAMS (x; y)
     SEP (listrep s1 x; listrep s2 y)
  POST [ tptr t_list ]
    EX r: val,
     PROP()
     RETURN(r)
     SEP (listrep (s1++s2) r).

(* 70.3 lseg：描述从 x 到 z 的「部分链表」 *)

Fixpoint lseg (contents: list val) (x z: val) : mpred :=
  match contents with
  | nil => !! (x = z) && emp
  | h::hs => EX y:val, data_at Tsh t_list (h, y) x * lseg hs y z
  end.

Arguments lseg contents x z : simpl never.

Lemma singleton_lseg: forall (a: val) (x y: val),
  data_at Tsh t_list (a, y) x |-- lseg [a] x y.
Proof.
  intros.
  unfold lseg.
  Exists y.
  entailer!.
Qed.

Lemma lseg_maybe_loop: forall (a b x y: val),
  data_at Tsh t_list (a, y) x * data_at Tsh t_list (b, y) y
  |-- lseg [a; b] x y.
Proof.
  intros.
  unfold lseg.
  Exists y.
  Exists y.
  entailer!.
Qed.

Lemma loopy_lseg_not_bad: forall (a b c x y: val),
  data_at Tsh t_list (a, y) x * data_at Tsh t_list (b, y) y * listrep [c] y
    |-- FF.
Proof.
  intros.
  unfold listrep.
  Intros u.
  subst.
  sep_apply (data_at_conflict Tsh t_list (c, nullval)).
  + auto.
  + entailer!.
Qed.

Lemma lseg_lseg: forall (s1 s2: list val) (x y z: val),
  lseg s1 x y * lseg s2 y z |-- lseg (s1 ++ s2) x z.
Proof.
  intros s1 s2 x y z.
  revert x.
  induction s1 as [|a s1' IH]; intros.
  - unfold lseg.
    entailer!.
    apply derives_refl.
  - unfold lseg; fold lseg.
    Intros u.
    Exists u.
    sep_apply IH.
    entailer!.
    apply derives_refl.
Qed.

Lemma lseg_list: forall (s1 s2: list val) (x y: val),
  lseg s1 x y * listrep s2 y |-- listrep (s1 ++ s2) x.
Proof.
  intros s1 s2 x y.
  revert x.
  induction s1 as [|a s1' IH]; intros.
  - unfold lseg.
    entailer!.
    apply derives_refl.
  - unfold lseg; fold lseg.
    Intros u.
    Exists u.
    sep_apply IH.
    entailer!.
    apply derives_refl.
Qed.

Lemma listrep_local_facts:
  forall sigma p,
   listrep sigma p |--
   !! (is_pointer_or_null p /\ (p=nullval <-> sigma=nil)).
Proof.
  intros [|h hs] p.
  - unfold listrep.
    entailer!.
    split; auto.
  - unfold listrep; fold listrep.
    Intros y.
    entailer!.
    split; intros Hx; try discriminate.
    subst p. eapply field_compatible_nullval; eauto.
Qed.

#[export] Hint Resolve listrep_local_facts : saturate_local.

Lemma listrep_valid_pointer:
  forall sigma p,
   listrep sigma p |-- valid_pointer p.
Proof.
  intros [|h hs] p.
  - unfold listrep.
    entailer!.
  - unfold listrep; fold listrep.
    Intros y.
    entailer!.
Qed.

#[export] Hint Resolve listrep_valid_pointer : valid_pointer.

Lemma listrep_null: forall contents x,
  x = nullval ->
  listrep contents x = !! (contents=nil) && emp.
Proof.
  intros [|h hs] x Hx; apply pred_ext.
  - unfold listrep. entailer!.
  - unfold listrep. entailer!.
  - apply (derives_trans _ FF); [| entailer!].
    unfold listrep; fold listrep.
    Intros y. entailer!.
    exfalso. eapply field_compatible_nullval; eauto.
  - unfold listrep.
    entailer!.
    discriminate.
Qed.

Lemma listrep_nonnull: forall contents x,
  x <> nullval ->
  listrep contents x =
    EX h: val, EX hs: list val, EX y:val,
      !! (contents = h :: hs) && data_at Tsh t_list (h, y) x * listrep hs y.
Proof.
  intros [|h hs] x Hx; apply pred_ext.
  - unfold listrep.
    entailer!.
  - entailer!.
    discriminate.
  - unfold listrep.
    Intros y.
    Exists h hs y.
    entailer!.
  - Intros h0 hs0 y0.
    injection H as Heq1 Heq2.
    subst h0 hs0.
    unfold listrep.
    Exists y0.
    entailer!.
Qed.

Definition Gprog : funspecs := [ append_spec ].

(* 70.4 body_append：主证明 *)

Lemma body_append: semax_body Vprog Gprog f_append append_spec.
Proof.
start_function.
forward_if. (* if (x == NULL) *)
- (* If-then *)
  rewrite (listrep_null _ x) by auto.
  normalize.
  forward. (* return y; *)
  Exists y.
  entailer!.
  apply derives_refl.
- (* If-else *)
  rewrite (listrep_nonnull _ x) by auto.
  Intros h r u.
  forward. (* t = x; *)
  forward. (* u = t -> tail; *)
  forward_while
      ( EX s1a: list val, EX b: val, EX s1c: list val, EX t: val, EX u: val,
        PROP (s1 = s1a ++ b :: s1c)
        LOCAL (temp _x x; temp _t t; temp _u u; temp _y y)
        SEP (lseg s1a x t;
             data_at Tsh t_list (b, u) t;
             listrep s1c u;
             listrep s2 y))%assert.
 + (* current assertion implies loop invariant *)
      Exists (@nil val) h r x u.
      subst s1. entailer!. unfold lseg; entailer!.
 + (* loop test is safe to execute *)
      entailer!.
 +  (* loop body preserves invariant *)
    clear h r u H0; rename u0 into u.
    rewrite (listrep_nonnull _ u) by auto.
    Intros c s1d z.
    forward. (* t = u; *)
    forward. (* u = t -> tail; *)
    Exists ((s1a ++ b :: nil),c,s1d,u,z). unfold fst, snd.
    entailer!.
    * (* PROP *)
      apply (app_assoc s1a [b] (c :: s1d)).
    * (* SEP *)
      sep_apply singleton_lseg.
      rewrite (sepcon_comm (lseg [b] t u) (lseg s1a x t)).
      apply lseg_lseg.
 + (* after the loop *)
  clear h r u H0; rename u0 into u.
  rewrite (listrep_null s1c) by auto.
  Intros.
  subst s1c.
  forward. (* t -> tail = y; *)
  forward. (* return x; *)
  Exists x.
  entailer!.
  sep_apply singleton_lseg.
  rewrite <- sepcon_assoc.
  rewrite (sepcon_comm (lseg [b] t y) (lseg s1a x t)).
  sep_apply lseg_lseg.
  sep_apply lseg_list.
  entailer!.
Qed.

Print Assumptions body_append.
