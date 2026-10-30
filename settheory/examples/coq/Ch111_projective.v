(* 第 111 章：有限树良基判定与秩递归——余解析集树表示的影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch111.

(* ── 一、树与树枝（定义 3.2 的有限替身） ── *)

(* 全长树枝 = 长度 D 的路径。 *)
Definition has_branch (T : list (list nat)) (D : nat) : Prop :=
  exists b, length b = D /\ forall k, k <= D -> In (firstn k b) T.

(* 有树枝 ⟹ 树中有全长节点。 *)
Lemma branch_imp : forall T D,
    has_branch T D -> exists s, In s T /\ length s = D.
Proof.
  intros T D [b [hb hmem]].
  exists (firstn D b). split.
  - apply hmem; lia.
  - rewrite length_firstn, hb, Nat.min_id. reflexivity.
Qed.

(* ── 二、赋秩函数（燃料递归：叶 0、内部点 = 子最大 + 1） ── *)

Fixpoint rho (T : list (list nat)) (f : nat) (s : list nat) : nat :=
  match f with
  | 0 => 0
  | S f' =>
      if orb (if in_dec (list_eq_dec Nat.eq_dec) (s ++ [0]) T
              then true else false)
             (if in_dec (list_eq_dec Nat.eq_dec) (s ++ [1]) T
              then true else false)
      then S (max (rho T f' (s ++ [0])) (rho T f' (s ++ [1])))
      else 0
  end.

(* 秩不超过燃料（引理 3.5「秩有界」的机制件）。 *)
Lemma rho_le : forall T f s, rho T f s <= f.
Proof.
  intros T f. induction f as [|f ih]; intros s.
  - reflexivity.
  - simpl. destruct (orb _ _).
    + assert (h0 := ih (s ++ [0])). assert (h1 := ih (s ++ [1])).
      lia.
    + lia.
Qed.

(* 双子皆不在树中 ⟹ 秩为 0（叶判定的数值面）。 *)
Lemma not_in_child : forall T f s,
    ~ In (s ++ [0]) T -> ~ In (s ++ [1]) T -> rho T (S f) s = 0.
Proof.
  intros T f s H0 H1. simpl.
  destruct (in_dec (list_eq_dec Nat.eq_dec) (s ++ [0]) T) as [Hi|Ni0];
  destruct (in_dec (list_eq_dec Nat.eq_dec) (s ++ [1]) T) as [Hj|Ni1];
  try reflexivity.
  - exfalso; exact (H0 Hi).
  - exfalso; exact (H0 Hi).
  - exfalso; exact (H1 Hj).
Qed.

(* ── 三、样本账（决定性核查） ── *)

Definition T0 : list (list nat) := [[]; [0]; [1]].
Definition T1 : list (list nat) := [[]; [0]; [1]; [0; 0]].
Definition T2 : list (list nat) := [[]; [0]; [1]; [0; 0]; [0; 1]].

(* T0 无长度 2 的树枝（有秩树）。 *)
Example no_branch_T0 : ~ has_branch T0 2.
Proof.
  intros H. apply branch_imp in H. destruct H as [s [Hs Hlen]].
  simpl in Hs. destruct Hs as [Heq|[Heq|[Heq|[]]]];
    subst s; simpl in Hlen; discriminate.
Qed.

(* T1 有全长树枝（无秩树）。 *)
Example branch_T1 : has_branch T1 2.
Proof.
  exists [0; 0]. split; [reflexivity|].
  intros k Hk. destruct k as [|[|[|k]]]; simpl; auto.
Qed.

(* 秩账：有秩 T0 根秩 1；无秩 T1 根秩 2（= 深度）。 *)
Example rho_T0 : rho T0 2 [] = 1.
Proof. reflexivity. Qed.

Example rho_T1 : rho T1 2 [] = 2.
Proof. reflexivity. Qed.

(* T2 的秩表：根 2、中层 1、叶 0。 *)
Example rho_T2 : rho T2 3 [] = 2 /\ rho T2 3 [0] = 1 /\ rho T2 3 [0;0] = 0.
Proof. repeat split; reflexivity. Qed.

End Ch111.
