(* 第 110 章：投影、核刻画、提升与鸽笼——饱和界与光影原理的有限影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch110.

(* ── 一、沿 109 章的装置 + 语义理想 ── *)

Fixpoint diffL (C D : list nat) : list nat :=
  match C with
  | [] => []
  | a :: C' => if in_dec Nat.eq_dec a D then diffL C' D else a :: diffL C' D
  end.

Lemma in_diffL : forall C D x, In x (diffL C D) <-> In x C /\ ~ In x D.
Proof.
  induction C as [|a C' IH]; intros D x; simpl.
  - split; [intros H; contradiction | intros [HC _]; contradiction].
  - destruct (in_dec Nat.eq_dec a D) as [Hin|Hnin]; simpl.
    + rewrite IH. split.
      * intros [H1 H2]. split; [right; exact H1 | exact H2].
      * intros [H1 H2]. split.
        -- destruct H1 as [Heq|H1].
           ++ subst x. exfalso. apply H2, Hin.
           ++ exact H1.
        -- exact H2.
    + rewrite IH. split.
      * intros [H | [H1 H2]].
        -- split; [left; exact H | subst x; exact Hnin].
        -- split; [right; exact H1 | exact H2].
      * intros [H1 H2]. destruct H1 as [Heq|H1].
        -- left; exact Heq.
        -- right. split; [exact H1 | exact H2].
Qed.

(* 语义理想：X ∈ I₀ ⟺ X ⊆ {0}（集合语义，免表重计）。 *)
Definition inI0 (X : list nat) : Prop := incl X [0].
Definition pos (X : list nat) : Prop := ~ inI0 X.

(* 投影：抹掉坐标 0——N ↦ N∩ω₁ 的影子。 *)
Definition projL (X : list nat) : list nat := diffL X [0].

(* ── 二、核刻画：理想 = 投影的核 ── *)

Lemma incl0_proj_nil : forall X, incl X [0] -> projL X = [].
Proof.
  intros X H.
  assert (hnil : forall x, ~ In x (projL X)).
  { intros x Hx. apply in_diffL in Hx. destruct Hx as [Hx1 H2].
    exfalso. apply H2. apply H. exact Hx1. }
  destruct (projL X) as [|b L] eqn:E.
  - reflexivity.
  - exfalso. apply (hnil b). left. reflexivity.
Qed.

Lemma proj_nil_incl0 : forall X, projL X = [] -> incl X [0].
Proof.
  intros X H x Hx.
  destruct (in_dec Nat.eq_dec x [0]) as [Hin|Hnin].
  - destruct Hin as [Heq|Hf]; [left; exact Heq | contradiction].
  - exfalso. assert (Hm : In x (projL X)).
    { apply in_diffL. split; [exact Hx | exact Hnin]. }
    rewrite H in Hm. contradiction.
Qed.

Theorem kernel : forall X, inI0 X <-> projL X = [].
Proof.
  intros X. split.
  - apply incl0_proj_nil.
  - apply proj_nil_incl0.
Qed.

(* ── 三、π 与交交换（成员刻画形式） ── *)

Fixpoint interL (X Y : list nat) : list nat :=
  match X with
  | [] => []
  | a :: X' => if in_dec Nat.eq_dec a Y then a :: interL X' Y else interL X' Y
  end.

Lemma in_interL : forall X Y x, In x (interL X Y) <-> In x X /\ In x Y.
Proof.
  induction X as [|a X' IH]; intros Y x; simpl.
  - split; [contradiction | intros [HC _]; contradiction].
  - destruct (in_dec Nat.eq_dec a Y) as [Hin|Hnin]; simpl.
    + rewrite IH. split.
      * intros [Heq | [H1 H2]].
        -- split; [left; exact Heq | rewrite Heq in Hin; exact Hin].
        -- split; [right; exact H1 | exact H2].
      * intros [[Heq | H1] H2].
        -- left. exact Heq.
        -- right. split; [exact H1 | exact H2].
    + rewrite IH. split.
      * intros [H1 H2]. split; [right; exact H1 | exact H2].
      * intros [[Heq | H1] H2].
        -- exfalso. apply Hnin. rewrite <- Heq in H2. exact H2.
        -- split; [exact H1 | exact H2].
Qed.

Theorem proj_inter_char : forall X Y a,
    In a (projL (interL X Y)) <-> In a (interL (projL X) (projL Y)).
Proof.
  intros X Y a. unfold projL.
  rewrite !in_diffL, !in_interL, !in_diffL.
  split.
  - intros [[HX HY] Hn]. split.
    + split; [exact HX | exact Hn].
    + split; [exact HY | exact Hn].
  - intros [[HX Hn] [HY Hn']]. split.
    + split; [exact HX | exact HY].
    + exact Hn.
Qed.

(* ── 四、不相容 ⟹ 投影不交 ── *)

Definition incompat (X Y : list nat) : Prop := inI0 (interL X Y).

Theorem incompat_proj_disjoint : forall X Y a,
    incompat X Y -> ~ In a (interL (projL X) (projL Y)).
Proof.
  intros X Y a Hab Ha.
  apply (proj_inter_char X Y a) in Ha.
  unfold projL in Ha. apply in_diffL in Ha. destruct Ha as [Hmem Hn].
  apply Hn. apply Hab. exact Hmem.
Qed.

(* ── 五、提升：非空楼下集有正测原像 ── *)

Lemma projL_keep : forall Y, (forall y, In y Y -> y <> 0) -> projL Y = Y.
Proof.
  induction Y as [|b Y' IH]; intros H.
  - reflexivity.
  - unfold projL in *.
    replace (diffL (b :: Y') [0]) with
      (if in_dec Nat.eq_dec b [0] then diffL Y' [0] else b :: diffL Y' [0])
      by reflexivity.
    destruct (in_dec Nat.eq_dec b [0]) as [Hin|Hnin].
    + exfalso. destruct Hin as [Heq|[]].
      apply (H b (or_introl eq_refl)). symmetry. exact Heq.
    + rewrite IH; [reflexivity |].
      intros y Hy. apply H. right. exact Hy.
Qed.

Theorem lifting : forall Y, incl Y [1;2] -> Y <> [] ->
    exists X, pos X /\ projL X = Y.
Proof.
  intros Y HY Hne.
  exists Y. split.
  - intro Hsub. destruct Y as [|b Y'].
    + exfalso. apply Hne. reflexivity.
    + assert (Hb : In b [1;2]) by (apply HY; left; reflexivity).
      assert (Hb0 : In b [0]) by (apply Hsub; left; reflexivity).
      destruct Hb0 as [H01|[]].
      assert (Hb0' : b = 0) by (symmetry; exact H01).
      destruct Hb as [H11|[H21|[]]].
      * rewrite Hb0' in H11. discriminate.
      * rewrite Hb0' in H21. discriminate.
  - apply projL_keep. intros y Hy.
    assert (Hy12 : In y [1;2]) by (apply HY; exact Hy).
    destruct Hy12 as [Heq|[Heq|[]]].
    + symmetry in Heq; lia.
    + symmetry in Heq; lia.
Qed.

(* ── 六、鸽笼：{1,2} 的两两不交非空子集至多 2 个 ── *)

Definition in12 (Y : list nat) : Prop := exists a, In a Y /\ (a = 1 \/ a = 2).

Lemma pick12 : forall Y, in12 Y -> exists a, In a Y /\ (a = 1 \/ a = 2).
Proof. exact (fun Y H => H). Qed.

Lemma share_hit : forall X Y v, In v X -> In v Y -> ~ In v (interL X Y) -> False.
Proof.
  intros X Y v HX HY H. apply H. apply in_interL. split; assumption.
Qed.

Theorem pigeonhole12 : forall A B C,
    in12 A -> in12 B -> in12 C ->
    (~ In 1 (interL A B) /\ ~ In 2 (interL A B) ->
     ~ In 1 (interL A C) /\ ~ In 2 (interL A C) ->
     ~ In 1 (interL B C) /\ ~ In 2 (interL B C) -> False).
Proof.
  intros A B C [a [Ha [Ha1|Ha2]]] [b [Hb [Hb1|Hb2]]] [c [Hc [Hc1|Hc2]]]
    HAB HAC HBC.
  - (* a=1,b=1,c=1 *) apply (share_hit A B 1);
      [rewrite <- Ha1; exact Ha | rewrite <- Hb1; exact Hb | apply (proj1 HAB)].
  - (* a=1,b=1,c=2 *) apply (share_hit A B 1);
      [rewrite <- Ha1; exact Ha | rewrite <- Hb1; exact Hb | apply (proj1 HAB)].
  - (* a=1,b=2,c=1 *) apply (share_hit A C 1);
      [rewrite <- Ha1; exact Ha | rewrite <- Hc1; exact Hc | apply (proj1 HAC)].
  - (* a=1,b=2,c=2 *) apply (share_hit B C 2);
      [rewrite <- Hb2; exact Hb | rewrite <- Hc2; exact Hc | apply (proj2 HBC)].
  - (* a=2,b=1,c=1 *) apply (share_hit B C 1);
      [rewrite <- Hb1; exact Hb | rewrite <- Hc1; exact Hc | apply (proj1 HBC)].
  - (* a=2,b=1,c=2 *) apply (share_hit A C 2);
      [rewrite <- Ha2; exact Ha | rewrite <- Hc2; exact Hc | apply (proj2 HAC)].
  - (* a=2,b=2,c=1 *) apply (share_hit A B 2);
      [rewrite <- Ha2; exact Ha | rewrite <- Hb2; exact Hb | apply (proj2 HAB)].
  - (* a=2,b=2,c=2 *) apply (share_hit A B 2);
      [rewrite <- Ha2; exact Ha | rewrite <- Hb2; exact Hb | apply (proj2 HAB)].
Qed.

(* ── 七、样本账（决定性核查） ── *)

Example proj_samples :
  projL [0;1;2] = [1;2] /\ projL [0;1] = [1] /\ projL [0] = [].
Proof. repeat split; reflexivity. Qed.

Example kernel_samples :
  inI0 [] /\ inI0 [0] /\ ~ inI0 [1] /\ ~ inI0 [1;2].
Proof.
  repeat split.
  - intros x [].
  - intros x Hx. destruct Hx as [->|[]]. left. reflexivity.
  - intro H. destruct (H 1 (or_introl eq_refl)) as [Heq|[]]. discriminate.
  - intro H. destruct (H 1 (or_introl eq_refl)) as [Heq|[]]. discriminate.
Qed.

Example incompat_sample : incompat [1] [2].
Proof.
  unfold incompat, inI0. compute. intros x Hx. destruct Hx.
Qed.

End Ch110.
