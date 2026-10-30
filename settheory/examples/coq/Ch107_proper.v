(* 第 107 章：主条件证书、准稠密与 (M,P)-泛型条件的有限影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch107.

(* 偏序数据：ext q = q 的延展（含自身）。样本宇宙：三点分叉。 *)
Definition extT (q : nat) : list nat :=
  match q with
  | 0 => [0; 1; 2]
  | 1 => [1]
  | 2 => [2]
  | _ => []
  end.

(* 相容：有公共延展。 *)
Definition Compat (ext : nat -> list nat) (r p : nat) : Prop :=
  exists s, In s (ext r) /\ In s (ext p).

(* 冲突子集：两两不相容。 *)
Definition Antichain (ext : nat -> list nat) (A : list nat) : Prop :=
  forall p, In p A -> forall q, In q A -> p <> q -> ~ Compat ext p q.

(* A 在 q 之下准稠密。 *)
Definition PredenseBelow (ext : nat -> list nat)
  (A : list nat) (q : nat) : Prop :=
  forall r, In r (ext q) -> exists p, In p A /\ Compat ext r p.

(* (M,P)-泛型条件证书。 *)
Definition GenericCond (ext : nat -> list nat)
  (As : list (list nat)) (q : nat) : Prop :=
  forall A, In A As -> PredenseBelow ext A q.

(* 更强的条件保持证书（条件复合保持证书）。 *)
Lemma generic_strengthen : forall ext As q q',
  incl (ext q') (ext q) ->
  GenericCond ext As q -> GenericCond ext As q'.
Proof.
  intros ext As q q' Hsub H A HA r Hr'.
  apply (H A HA r).
  apply Hsub. exact Hr'.
Qed.

(* {1,2} 是反链。 *)
Lemma not_compat_12 : ~ Compat extT 1 2.
Proof.
  intros [s [Hs Hs']].
  unfold extT in Hs, Hs'.
  simpl in Hs, Hs'.
  destruct Hs as [E1|[]]; destruct Hs' as [E2|[]].
  rewrite <- E1 in E2. discriminate.
Qed.

Lemma not_compat_21 : ~ Compat extT 2 1.
Proof.
  intros [s [Hs Hs']].
  unfold extT in Hs, Hs'.
  simpl in Hs, Hs'.
  destruct Hs as [E1|[]]; destruct Hs' as [E2|[]].
  rewrite <- E2 in E1. discriminate.
Qed.

Lemma antichain_12 : Antichain extT [1; 2].
Proof.
  intros p Hp q Hq Hne Hcp.
  simpl in Hp, Hq.
  destruct Hp as [Ep|[Ep|[]]]; destruct Hq as [Eq|[Eq|[]]]; subst.
  all: try (exfalso; apply Hne; reflexivity).
  - exact (not_compat_12 Hcp).
  - exact (not_compat_21 Hcp).
Qed.

(* {1,2} 在 q=0 之下准稠密。 *)
Lemma predense_12_0 : PredenseBelow extT [1; 2] 0.
Proof.
  intros r Hr. simpl in Hr.
  destruct Hr as [Er|[Er|[Er|[]]]]; subst r.
  - exists 1. split; [left; reflexivity|].
    exists 1. simpl. auto.
  - exists 1. split; [left; reflexivity|].
    exists 1. simpl. auto.
  - exists 2. split; [right; left; reflexivity|].
    exists 2. simpl. auto.
Qed.

(* 0 是 (M,P)-泛型条件。 *)
Lemma generic_0 : GenericCond extT [[1; 2]] 0.
Proof.
  intros A HA. destruct HA as [HA|[]]. subst A.
  apply predense_12_0.
Qed.

(* 证书下放：1 与 2 也泛型。 *)
Lemma extT_mono_10 : incl (extT 1) (extT 0).
Proof. intros x Hx. simpl in *. destruct Hx; auto. Qed.

Lemma extT_mono_20 : incl (extT 2) (extT 0).
Proof. intros x Hx. simpl in *. destruct Hx; auto. Qed.

Example generic_1 : GenericCond extT [[1; 2]] 1.
Proof. apply (generic_strengthen extT [[1;2]] 0 1 extT_mono_10 generic_0). Qed.

Example generic_2 : GenericCond extT [[1; 2]] 2.
Proof. apply (generic_strengthen extT [[1;2]] 0 2 extT_mono_20 generic_0). Qed.

End Ch107.
