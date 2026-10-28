(* 第 102 章：f-闭包点、见证依赖函数与 f-谢拉赫型条款的有限影子。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch102.

(* ── 一、f-闭包：∀ i<κ, f i<κ（定义 1.25(i) 影子）── *)

Definition closed (f : nat -> nat) (k : nat) : Prop :=
  forall i, i < k -> f i < k.

Definition fsucc (i : nat) : nat := if i <=? 3 then i + 1 else 5.

Lemma fsucc_gt : forall i, i < 5 -> i < fsucc i.
Proof.
  intros i Hi. unfold fsucc.
  destruct (Nat.leb_spec i 3) as [H3|H3].
  - assert (i < i + 1) by lia. lia.
  - lia.
Qed.

(* 后继函数在 [1,5] 内无闭包点：fsucc(κ-1) 落在 κ-1 与 κ 之间。 *)
Theorem fsucc_no_closed :
  forall k, 1 <= k -> k <= 5 -> ~ closed fsucc k.
Proof.
  intros k H1 H5 Hcl.
  assert (Hi : k - 1 < k) by lia.
  specialize (Hcl (k - 1) Hi).
  pose proof (fsucc_gt (k - 1) ltac:(lia)) as Hgt.
  lia.
Qed.

(* ── 二、见证依赖函数：c1 与 c13 的见证集分离 ── *)

Definition c1 (_ : nat) : nat := 1.
Definition c13 (i : nat) : nat := if i =? 1 then 3 else 1.

Lemma c1_closed : forall k, 2 <= k -> closed c1 k.
Proof. intros k Hk i Hi. unfold c1. lia. Qed.

(* c13 的最小闭包点是 4：[1,3] 内全部失败。 *)
Theorem c13_no_closed :
  forall k, 1 <= k -> k <= 3 -> ~ closed c13 k.
Proof.
  intros k H1 H3 Hcl.
  destruct (Nat.eq_dec k 1) as [E|NE].
  - subst k. assert (Hb : closed c13 1 -> False).
    { intro H. specialize (H 0 ltac:(lia)). unfold c13 in H.
      destruct (Nat.eqb_spec 0 1); simpl in H; lia. }
    apply Hb; exact Hcl.
  - assert (Hb : closed c13 k -> False).
    { intro H. specialize (H 1 ltac:(lia)). unfold c13 in H.
      destruct (Nat.eqb_spec 1 1); simpl in H; lia. }
    apply Hb; exact Hcl.
Qed.

Lemma c13_closed_4 : closed c13 4.
Proof.
  intros i Hi. unfold c13.
  destruct (Nat.eqb_spec i 1) as [E|NE].
  - subst i; lia.
  - lia.
Qed.

(* 见证必须随函数变化：单一 κ 无法同时服务两个函数。 *)
Corollary witnesses_depend :
  (forall k, 2 <= k -> k <= 4 -> closed c1 k) /\
  (forall k, 1 <= k -> k <= 3 -> ~ closed c13 k).
Proof.
  split.
  - intros k H2 _. apply c1_closed. exact H2.
  - exact c13_no_closed.
Qed.

(* ── 三、f-谢拉赫型条款（闭包 + j(f)(κ)>κ + 层捕获）── *)

Record FWit := mkFWit {kappa_ : nat; jfk : nat; cap : list nat}.

Definition fShelah (f : nat -> nat) (w : FWit) : Prop :=
  closed f (kappa_ w) /\ kappa_ w < jfk w /\ In (jfk w) (cap w).

Example c1_witness : fShelah c1 (mkFWit 2 3 [3]).
Proof.
  split; [|split].
  - simpl. apply (c1_closed 2). lia.
  - simpl. lia.
  - simpl. left; reflexivity.
Qed.

Example fsucc_not_witness : ~ fShelah fsucc (mkFWit 2 3 [3]).
Proof.
  intros [Hcl _]. simpl in Hcl.
  apply (fsucc_no_closed 2); [lia|lia|exact Hcl].
Qed.

(* ── 四、有限见证表：对 δ=4 上的全函数枚举闭包点 ── *)

Definition funcs4 : list (list nat) :=
  (* 四个小样本 + 一个共尾型（无闭包点） *)
  [[1;1;1;1]; [2;2;2;2]; [1;3;1;1]; [1;2;3;3]; [3;3;3;3]].

Definition nthf (l : list nat) (i : nat) : nat := nth i l 0.

Definition closedL (l : list nat) (k : nat) : Prop :=
  forall i, i < k -> nthf l i < k.

(* 表的前两行有闭包点（κ=2 与 κ=3），第三行 κ=4，
   第四五行（共尾型）在 [1,4) 内无闭包点。 *)
Example table_row1 : closedL [1;1;1;1] 2.
Proof. intros i Hi. unfold nthf.
  destruct i as [|[|[|[|i]]]]; simpl; lia. Qed.

Example table_row2 : closedL [2;2;2;2] 3.
Proof. intros i Hi. unfold nthf.
  destruct i as [|[|[|i]]]; simpl; lia. Qed.

Example table_row3 : closedL [1;3;1;1] 4.
Proof. intros i Hi. unfold nthf.
  destruct i as [|[|[|[|i]]]]; simpl; lia. Qed.

(* 共尾型 [1;2;3;3]：κ∈[1,4) 全部失败。 *)
Example table_row4_fail : forall k, 1 <= k -> k <= 3 -> ~ closedL [1;2;3;3] k.
Proof.
  intros k H1 H3 Hcl.
  destruct k as [|[|[|[|k]]]]; try lia.
  - specialize (Hcl 0 ltac:(lia)). unfold nthf in Hcl. simpl in Hcl. lia.
  - specialize (Hcl 1 ltac:(lia)). unfold nthf in Hcl. simpl in Hcl. lia.
  - specialize (Hcl 2 ltac:(lia)). unfold nthf in Hcl. simpl in Hcl. lia.
Qed.

End Ch102.
