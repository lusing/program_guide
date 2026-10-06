(* ex06 —— 矢列演算 G（Ben-Ari 3e §3.2）：规则、经典性、可靠性
   对书：Ben-Ari 3e §3.2 / EFT IV / Mints §8（LJ 对照）

   矢列 Γ ⊢ Δ 读作「Γ 全真 ⟹ Δ 至少一真」。G 的九条规则
   在引入联结词时保持这个读法——可靠性定理对推导归纳。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语言与语义 ---------- *)

Inductive sform : Type :=
| SVar : nat -> sform
| SAnd : sform -> sform -> sform
| SOr  : sform -> sform -> sform
| SImp : sform -> sform -> sform
| SNeg : sform -> sform.

Fixpoint seval (e : nat -> bool) (f : sform) : bool :=
  match f with
  | SVar n   => e n
  | SAnd a b => andb (seval e a) (seval e b)
  | SOr a b  => orb (seval e a) (seval e b)
  | SImp a b => implb (seval e a) (seval e b)
  | SNeg a   => negb (seval e a)
  end.

Definition allTrue (G : list sform) (e : nat -> bool) : Prop :=
  forall f, In f G -> seval e f = true.

Definition someTrue (D : list sform) (e : nat -> bool) : Prop :=
  exists f, In f D /\ seval e f = true.

Definition seqValid (G D : list sform) : Prop :=
  forall e, allTrue G e -> someTrue D e.

(* ---------- 演算 G：九条规则 ---------- *)

Inductive gProv : list sform -> list sform -> Prop :=
| gAx    : forall G D p, In p G -> In p D -> gProv G D
| gLNeg  : forall G D p, gProv G (p :: D) -> gProv (SNeg p :: G) D
| gRNeg  : forall G D p, gProv (p :: G) D -> gProv G (SNeg p :: D)
| gLAnd  : forall G D a b, gProv (a :: b :: G) D -> gProv (SAnd a b :: G) D
| gRAnd  : forall G D a b,
    gProv G (a :: D) -> gProv G (b :: D) -> gProv G (SAnd a b :: D)
| gLOr   : forall G D a b,
    gProv (a :: G) D -> gProv (b :: G) D -> gProv (SOr a b :: G) D
| gROr   : forall G D a b, gProv G (a :: b :: D) -> gProv G (SOr a b :: D)
| gLImp  : forall G D a b,
    gProv G (a :: D) -> gProv (b :: G) D -> gProv (SImp a b :: G) D
| gRImp  : forall G D a b, gProv (a :: G) (b :: D) -> gProv G (SImp a b :: D).

(* ---------- 现场：G 天生经典 ----------
   ⊢ ¬p ∨ p 三步：ROr → RNeg → Ax。
   顺序注记：规则只在表头引入，所以先出来的是 ¬p ∨ p
   （p ∨ ¬p 要等后件交换性这条导出规则）。 *)

Theorem g_lem_var : forall n, gProv [] [SOr (SNeg (SVar n)) (SVar n)].
Proof.
  intros n.
  apply gROr with (a := SNeg (SVar n)) (b := SVar n).
  apply gRNeg with (p := SVar n).
  apply gAx with (p := SVar n).
  - left; reflexivity.
  - left; reflexivity.
Qed.

(* ---------- 可靠性：对推导归纳 ---------- *)

Lemma implb_sem : forall e a b,
  implb (seval e a) (seval e b) = true -> seval e a = false \/ seval e b = true.
Proof.
  intros e a b H.
  (* 坑：apply (proj1 (implb_true_iff …)) in H 会把前提目标 shelve——
     改用 destruct-iff + pose proof 的明写法 *)
  destruct (implb_true_iff (seval e a) (seval e b)) as [Fwd _].
  pose proof (Fwd H) as H2.
  assert (E : seval e a = true \/ seval e a = false)
    by (destruct (seval e a); auto).
  destruct E as [Ea | Ea].
  - right. exact (H2 Ea).
  - left. exact Ea.
Qed.

Theorem gProv_sound : forall G D, gProv G D -> seqValid G D.
Proof.
  intros G D H. induction H as
    [G D p HinG HinD
    |G D p H IH
    |G D p H IH
    |G D a b H IH
    |G D a b H1 IH1 H2 IH2
    |G D a b H1 IH1 H2 IH2
    |G D a b H IH
    |G D a b H1 IH1 H2 IH2
    |G D a b H IH ].
  - (* Ax *)
    intros e Hall. exists p. split; [exact HinD|].
    apply Hall. exact HinG.
  - (* LNeg *)
    intros e Hall.
    assert (Hpn : seval e p = false).
    { specialize (Hall (SNeg p) (or_introl eq_refl)).
      apply negb_true_iff in Hall. assumption. }
    destruct (IH e) as [f [HinD Hval]].
    { intros f0 Hin. apply Hall. right. exact Hin. }
    destruct HinD as [Heq | HinD'].
    + inversion Heq; subst f. rewrite Hpn in Hval. discriminate.
    + exists f. split; assumption.
  - (* RNeg *)
    intros e Hall.
    destruct (seval e p) eqn:Ep.
    + destruct (IH e) as [f [HinD Hval]].
      { intros f0 Hin. destruct Hin as [Heq | Hin'].
        - inversion Heq; subst f0. exact Ep.
        - apply Hall. exact Hin'. }
      exists f. split; [right; exact HinD | exact Hval].
    + exists (SNeg p). split; [left; reflexivity|].
      simpl. rewrite Ep. reflexivity.
  - (* LAnd *)
    intros e Hall.
    assert (Hab : seval e a = true /\ seval e b = true).
    { specialize (Hall (SAnd a b) (or_introl eq_refl)).
      apply andb_true_iff in Hall. exact Hall. }
    destruct Hab as [Ha Hb].
    assert (HG : allTrue G e).
    { intros f0 Hin. apply Hall. right. exact Hin. }
    apply IH. intros f0 Hin.
    destruct Hin as [Heq | [Heq2 | Hin']].
    + inversion Heq; subst f0. exact Ha.
    + inversion Heq2; subst f0. exact Hb.
    + apply HG. exact Hin'.
  - (* RAnd *)
    intros e Hall.
    destruct (IH1 e Hall) as [f [HinD Hval]].
    destruct HinD as [Heq | HinD'].
    + inversion Heq; subst f.
      destruct (IH2 e Hall) as [f2 [Hin2 Hv2]].
      destruct Hin2 as [Heq2 | Hin2'].
      * inversion Heq2; subst f2.
        exists (SAnd a b). split; [left; reflexivity|].
        simpl. rewrite Hval, Hv2. reflexivity.
      * exists f2. split; [right; exact Hin2' | exact Hv2].
    + exists f. split; [right; exact HinD' | exact Hval].
  - (* LOr *)
    intros e Hall.
    assert (Hab : seval e a = true \/ seval e b = true).
    { specialize (Hall (SOr a b) (or_introl eq_refl)).
      apply orb_true_iff in Hall. exact Hall. }
    assert (HG : allTrue G e).
    { intros f0 Hin. apply Hall. right. exact Hin. }
    destruct Hab as [Ha | Hb].
    + apply IH1. intros f0 Hin. destruct Hin as [Heq | Hin'].
      * inversion Heq; subst f0. exact Ha.
      * apply HG. exact Hin'.
    + apply IH2. intros f0 Hin. destruct Hin as [Heq | Hin'].
      * inversion Heq; subst f0. exact Hb.
      * apply HG. exact Hin'.
  - (* ROr *)
    intros e Hall.
    destruct (IH e Hall) as [f [Hin Hval]].
    destruct Hin as [Heq | [Heq2 | Hin']].
    + inversion Heq; subst f.
      exists (SOr a b). split; [left; reflexivity|].
      simpl. rewrite Hval, orb_true_l. reflexivity.
    + inversion Heq2; subst f.
      exists (SOr a b). split; [left; reflexivity|].
      simpl. rewrite Hval, orb_true_r. reflexivity.
    + exists f. split; [right; exact Hin' | exact Hval].
  - (* LImp *)
    intros e Hall.
    assert (Hab : seval e a = false \/ seval e b = true).
    { specialize (Hall (SImp a b) (or_introl eq_refl)).
      simpl in Hall. apply implb_sem in Hall. exact Hall. }
    destruct Hab as [Ha | Hb].
    + destruct (IH1 e) as [f [Hin Hval]].
      { intros f0 Hin0. apply Hall. right. exact Hin0. }
      destruct Hin as [Heq | Hin'].
      * inversion Heq; subst f. rewrite Ha in Hval. discriminate.
      * exists f. split; assumption.
    + apply IH2. intros f0 Hin. destruct Hin as [Heq | Hin'].
      * inversion Heq; subst f0. exact Hb.
      * apply Hall. right. exact Hin'.
  - (* RImp *)
    intros e Hall.
    destruct (seval e a) eqn:Ea.
    + destruct (IH e) as [f [Hin Hval]].
      { intros f0 Hin0. destruct Hin0 as [Heq | Hin0'].
        - inversion Heq; subst f0. exact Ea.
        - apply Hall. exact Hin0'. }
      destruct Hin as [Heq | Hin'].
      * inversion Heq; subst f.
        exists (SImp a b). split; [left; reflexivity|].
        simpl. rewrite Ea, Hval. reflexivity.
      * exists f. split; [right; exact Hin' | exact Hval].
    + exists (SImp a b). split; [left; reflexivity|].
      simpl. rewrite Ea. reflexivity.
Qed.

Print Assumptions gProv_sound.  (* Closed：可靠性零公理 *)

(* 坑位速记（Coq 侧）：
   - inversion Heq; subst f 把 In f (p :: D) 的 f 统一到 p——
     witness 提取的标准步；
   - andb/orb/implb 的 _true_iff 三件套是语义分支的分解器；
   - 空后件 = 「假」由 RNeg/LNeg 的组合免费送出——G 的经典性
     长在双向矢列上（对照 03 章 NJp 只在 ⊥ 上「单向」）。 *)
