(* 第 108 章：可数支撑迭代的有限影子——支撑限制、拼接协调与支撑并集。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch108.

(* 条件 = 坐标表（坐标 → 非平凡条件值）；支撑 = 坐标列表。
   可数支撑的有限影子：平凡坐标不上表，故支撑有限。 *)
Definition keys (q : list (nat*nat)) : list nat := map fst q.

(* 限制：前 k 个坐标（q ↾ k）。 *)
Definition restrict (k : nat) (q : list (nat*nat)) : list (nat*nat) :=
  firstn k q.

(* 拼接：先取 q 的全部坐标，再接 r 在 q 长度之外的部分。 *)
Definition glue (q r : list (nat*nat)) : list (nat*nat) :=
  q ++ skipn (length q) r.

(* ── 一、自建件：firstn/skipn 的成员来自原表 ── *)

Lemma in_firstn_full : forall (A:Type) (k:nat) (l:list A) (x:A),
  In x (firstn k l) -> In x l.
Proof.
  intros A k l. revert k.
  induction l as [|a l IH]; intros k x H; destruct k as [|k']; simpl in H.
  - destruct H; contradiction.
  - destruct H; auto.
  - destruct H; contradiction.
  - destruct H as [->|H]; [left; reflexivity | right; exact (IH k' x H)].
Qed.

Lemma in_skipn_full : forall (A:Type) (k:nat) (l:list A) (x:A),
  In x (skipn k l) -> In x l.
Proof.
  intros A k l. revert k.
  induction l as [|a l IH]; intros k x H; destruct k as [|k']; simpl in H.
  - exact H.
  - destruct H; contradiction.
  - exact H.
  - right; exact (IH k' x H).
Qed.

(* ── 二、支撑并集仍有限（Task 23 Step 2 指定件） ── *)

Lemma keys_app : forall q r i,
  In i (keys (q ++ r)) -> In i (keys q) \/ In i (keys r).
Proof.
  intros q r i H. unfold keys in H. rewrite in_map_iff in H.
  destruct H as [p [Hpi Hp]].
  apply in_app_or in Hp. destruct Hp as [Hp|Hp];
    apply (in_map fst) in Hp; rewrite Hpi in Hp.
  - left; exact Hp.
  - right; exact Hp.
Qed.

Lemma keys_glue : forall q r i,
  In i (keys (glue q r)) -> In i (keys q) \/ In i (keys r).
Proof.
  intros q r i H. apply (keys_app q (skipn (length q) r)) in H.
  destruct H as [H|H]; [left; exact H|].
  unfold keys in H. rewrite in_map_iff in H.
  destruct H as [p [Hpi Hp]].
  apply (in_skipn_full _ (length q)) in Hp.
  apply (in_map fst) in Hp. rewrite Hpi in Hp. right; exact Hp.
Qed.

(* ── 三、限制只缩不小支撑 ── *)

Lemma keys_firstn : forall k q i,
  In i (keys (firstn k q)) -> In i (keys q).
Proof.
  intros k q i H. unfold keys in H. rewrite in_map_iff in H.
  destruct H as [p [Hpi Hp]].
  apply (in_firstn_full _ k) in Hp.
  apply (in_map fst) in Hp. rewrite Hpi in Hp. exact Hp.
Qed.

(* ── 四、拼接协调：q_{n+1} ↾ αₙ = qₙ（引理 2.27 的协调条款） ── *)

Lemma firstn_len_app : forall (q r : list (nat*nat)),
  firstn (length q) (q ++ r) = q.
Proof.
  induction q as [|p q IH]; intros r; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma glue_coherence : forall q r,
  restrict (length q) (glue q r) = q.
Proof.
  intros q r. unfold restrict, glue. apply firstn_len_app.
Qed.

(* ── 五、样本账（决定性核查） ── *)

Definition qA : list (nat*nat) := [(2,1)].
Definition rB : list (nat*nat) := [(0,2); (4,1); (9,2)].

Example glue_sample : glue qA rB = [(2,1); (4,1); (9,2)].
Proof. reflexivity. Qed.

Example keys_glue_sample :
  incl (keys (glue qA rB)) (keys qA ++ keys rB).
Proof.
  intros i H. apply (keys_glue qA rB) in H.
  destruct H as [H|H]; apply in_or_app.
  - left; exact H.
  - right; exact H.
Qed.

Example coherence_sample : restrict 1 (glue qA rB) = qA.
Proof. reflexivity. Qed.

Example keys_restrict_sample :
  incl (keys (restrict 1 rB)) (keys rB).
Proof. intros i H. apply (keys_firstn 1) in H. exact H. Qed.

End Ch108.
