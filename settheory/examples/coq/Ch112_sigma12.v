(* 第 112 章：有限补集之交空、两层树的截面良基与秩——Σ¹₂ 的影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch112.

(* ── 一、两层树的截面与树枝（定义 3.8 的有限替身） ── *)

(* 截面：T(α) = {h | (α↾|h|, h) ∈ T}。 *)
Definition sec (T : list (list nat * list nat)) (a : list nat) : list (list nat) :=
  map snd (filter (fun p => if list_eq_dec Nat.eq_dec (fst p)
                                (firstn (length (snd p)) a)
                            then true else false) T).

(* 截面有全长树枝（序数值供给 {0,1}：四种组合枚举）。 *)
Definition sec_branch (T : list (list nat * list nat)) (a : list nat) : Prop :=
  (In [0] (sec T a) /\ In [0;0] (sec T a)) \/
  (In [0] (sec T a) /\ In [0;1] (sec T a)) \/
  (In [1] (sec T a) /\ In [1;0] (sec T a)) \/
  (In [1] (sec T a) /\ In [1;1] (sec T a)).

(* 截面良基 = 无全长树枝。 *)
Definition sec_wf (T : list (list nat * list nat)) (a : list nat) : Prop :=
  ~ sec_branch T a.

(* ── 二、补集之交空、并全（博雷尔代码补运算的核——引理 3.15） ── *)

(* 有限宇宙 U 上的补集：A^c = U \ A。 *)
Definition compl (U A : list nat) : list nat :=
  filter (fun x => if in_dec Nat.eq_dec x A then false else true) U.

Lemma compl_inter_empty : forall U A,
    (forall x, In x A -> In x U) ->
    forall x, ~ (In x A /\ In x (compl U A)).
Proof.
  intros U A Hsub x [HA Hc]. unfold compl in Hc.
  apply filter_In in Hc. destruct Hc as [_ Hn].
  destruct (in_dec Nat.eq_dec x A) as [Hin|Hnin].
  - discriminate Hn.
  - contradiction.
Qed.

Lemma compl_union_full : forall U A x,
    In x U -> (In x A \/ In x (compl U A)).
Proof.
  intros U A x HU. destruct (in_dec Nat.eq_dec x A) as [HA|HA].
  - left. exact HA.
  - right. unfold compl. apply filter_In. split; [exact HU|].
    destruct (in_dec Nat.eq_dec x A) as [H|H]; [contradiction|reflexivity].
Qed.

(* ── 三、秩机关（定理 3.7：良基 ⟹ 秩函数；秩 ≤ 深度） ── *)

Fixpoint rho2 (Tr : list (list nat)) (f : nat) (s : list nat) : nat :=
  match f with
  | 0 => 0
  | S f' =>
      if orb (if in_dec (list_eq_dec Nat.eq_dec) (s ++ [0]) Tr then true else false)
             (if in_dec (list_eq_dec Nat.eq_dec) (s ++ [1]) Tr then true else false)
      then S (max (rho2 Tr f' (s ++ [0])) (rho2 Tr f' (s ++ [1])))
      else 0
  end.

Lemma rho2_le : forall Tr f s, rho2 Tr f s <= f.
Proof.
  intros Tr f. induction f as [|f ih]; intros s.
  - reflexivity.
  - simpl. destruct (orb _ _).
    + assert (h0 := ih (s ++ [0])). assert (h1 := ih (s ++ [1])). lia.
    + lia.
Qed.

(* ── 四、样本账（决定性核算） ── *)

Definition Tb : list (list nat * list nat) :=
  [([], []); ([0], [0]); ([0], [1]); ([0;0], [0;0]); ([0;0], [1;0])].

(* T_b(00) 有树枝（00 ∈ p[T_b]）。 *)
Example branch_00 : sec_branch Tb [0;0].
Proof.
  left. split.
  - vm_compute. right. left. reflexivity.
  - vm_compute. right. right. right. left. reflexivity.
Qed.

(* T_b(01) 良基。 *)
Example wf_01 : sec_wf Tb [0;1].
Proof.
  intro H. vm_compute in H. intuition congruence.
Qed.

(* 截面账：T_b(01) 的截面 = {[],[0],[1]}，根秩 1。 *)
Example sec_01 : sec Tb [0;1] = [[]; [0]; [1]].
Proof. reflexivity. Qed.

Example rho_01 : rho2 (sec Tb [0;1]) 2 [] = 1.
Proof. reflexivity. Qed.

End Ch112.
