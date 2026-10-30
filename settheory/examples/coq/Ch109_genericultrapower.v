(* 第 109 章：理想力迫的序、商关系与真值集——泛型超幂的有限影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch109.

(* ── 一、理想力迫的序：C ≤ D ⟺ C − D ∈ I（正测集代数） ── *)

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

Lemma diffL_id : forall C, diffL C C = [].
Proof.
  intros C.
  assert (hnil : forall x, ~ In x (diffL C C)).
  { intros x Hx. apply in_diffL in Hx. destruct Hx as [H1 H2]. contradiction. }
  destruct (diffL C C) as [|b L] eqn:E.
  - reflexivity.
  - exfalso. apply (hnil b). left. reflexivity.
Qed.

Definition forces (I : list (list nat)) (C D : list nat) : Prop :=
  In (diffL C D) I.

Lemma forces_refl : forall I C,
  In ([] : list nat) I -> forces I C C.
Proof.
  intros I C h0. unfold forces.
  rewrite diffL_id. exact h0.
Qed.

Lemma forces_trans : forall I C D E,
  (forall X Y, In X I -> In Y I -> In (X ++ Y) I) ->
  (forall X Y, In X I -> incl Y X -> In Y I) ->
  forces I C D -> forces I D E -> forces I C E.
Proof.
  intros I C D E hun hdown h1 h2. unfold forces in *.
  apply (hdown (diffL C D ++ diffL D E)).
  - apply hun; assumption.
  - intros x hx. apply in_diffL in hx. destruct hx as [H1 H2].
    apply in_or_app.
    destruct (in_dec Nat.eq_dec x D) as [Hin|Hnin].
    + right. apply in_diffL. split; assumption.
    + left. apply in_diffL. split; assumption.
Qed.

(* ── 二、商关系：X ≡ Y（mod I）⟺ X△Y ∈ I ── *)

Definition eqv (I : list (list nat)) (X Y : list nat) : Prop :=
  In (diffL X Y ++ diffL Y X) I.

Lemma eqv_refl : forall I X, In ([] : list nat) I -> eqv I X X.
Proof.
  intros I X h0. unfold eqv.
  rewrite diffL_id. rewrite app_nil_l. exact h0.
Qed.

Lemma eqv_trans : forall I X Y Z,
  (forall X Y, In X I -> In Y I -> In (X ++ Y) I) ->
  (forall X Y, In X I -> incl Y X -> In Y I) ->
  eqv I X Y -> eqv I Y Z -> eqv I X Z.
Proof.
  intros I X Y Z hun hdown hxy hyz. unfold eqv in *.
  apply (hdown (diffL X Y ++ diffL Y X ++ (diffL Y Z ++ diffL Z Y))).
  - rewrite app_assoc. apply hun; assumption.
  - intros x hx. apply in_app_or in hx. destruct hx as [hx|hx].
    + (* hx : In x (diffL X Z)：x ∈ X ∧ x ∉ Z *)
      apply in_diffL in hx. destruct hx as [H1 H2].
      apply in_or_app.
      destruct (in_dec Nat.eq_dec x Y) as [Hin|Hnin].
      * right. apply in_or_app. right. apply in_or_app. left.
        apply in_diffL. split; assumption.
      * left. apply in_diffL. split; assumption.
    + (* hx : In x (diffL Z X)：x ∈ Z ∧ x ∉ X *)
      apply in_diffL in hx. destruct hx as [H1 H2].
      apply in_or_app. right. apply in_or_app.
      destruct (in_dec Nat.eq_dec x Y) as [Hin|Hnin].
      * left. apply in_diffL. split; assumption.
      * right. apply in_or_app. right. apply in_diffL. split; assumption.
Qed.

(* ── 三、样本理想与真值集（决定性核查） ── *)

Definition U0 : list nat := [0; 1; 2].
Definition I0 : list (list nat) := [[]; [0]].

(* 序样本：{1} ≤ {0,1}（差 ∅），U0 ≰ {0,1}（差 [2] 为正）。 *)
Example forces_sample1 : forces I0 [1] [0; 1].
Proof. vm_compute. auto. Qed.

Example forces_sample2 : ~ forces I0 U0 [0; 1].
Proof.
  unfold forces.
  assert (hd : diffL U0 [0; 1] = [2]) by reflexivity.
  rewrite hd. simpl. intros [H|[H|H]]; [discriminate | discriminate | contradiction].
Qed.

(* 商关系样本：U0 ≡ {1,2}（对称差 [0] ∈ I0）。 *)
Example eqv_sample : eqv I0 U0 [1; 2].
Proof. vm_compute. auto. Qed.

(* 主滤子 G1（在 1 处）的样本。 *)
Definition G1 (X : list nat) : Prop := In 1 X /\ incl X U0.

(* 样本函数（U0 → ℕ 的表）。 *)
Definition f1 (a : nat) : nat := match a with 0 => 3 | 1 => 1 | _ => 4 end.
Definition g1 (a : nat) : nat := match a with 0 => 2 | 1 => 2 | _ => 0 end.

(* 真值集：{a | f1 a < g1 a} = [1]——在 G1 下裁决为真。 *)
Example truth_set : filter (fun a => f1 a <? g1 a) U0 = [1].
Proof. reflexivity. Qed.

Example los_sample : G1 (filter (fun a => f1 a <? g1 a) U0).
Proof.
  assert (hf : filter (fun a => f1 a <? g1 a) U0 = [1]) by reflexivity.
  rewrite hf. split.
  - left. reflexivity.
  - intros x [Hx|[]]. subst x. right. left. reflexivity.
Qed.

(* 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。 *)
Example id_sample : G1 (filter (fun a => a =? 1) U0).
Proof.
  assert (hf : filter (fun a => a =? 1) U0 = [1]) by reflexivity.
  rewrite hf. split.
  - left. reflexivity.
  - intros x [Hx|[]]. subst x. right. left. reflexivity.
Qed.

End Ch109.
