(* ex08 —— 范式：NNF 与 CNF
   对书：Huth&Ryan §1.5.2 / Ben-Ari 3e §4.1 / Mendelson §1.2 / EFT VIII.4

   NNF：否定压到原子（德摩根换联结词）；
   CNF：在 NNF 上把 ∨ 分配进 ∧。
   旗舰：eval e f = eval e (cnf (nnf f))——两次变换都保语义。
   dist 的 fuel=0 兜底返回未分配的 FOr——语义仍对，
   所以正确性证明完全不需要尺寸条件。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

Inductive form : Type :=
| FVar : nat -> form
| FAnd : form -> form -> form
| FOr  : form -> form -> form
| FNeg : form -> form
| FTop : form
| FBot : form.

Fixpoint eval (e : nat -> bool) (f : form) : bool :=
  match f with
  | FVar n   => e n
  | FAnd a b => andb (eval e a) (eval e b)
  | FOr a b  => orb (eval e a) (eval e b)
  | FNeg a   => negb (eval e a)
  | FTop     => true
  | FBot     => false
  end.

Fixpoint fsize (f : form) : nat :=
  match f with
  | FVar _   => 1
  | FAnd a b => 1 + fsize a + fsize b
  | FOr a b  => 1 + fsize a + fsize b
  | FNeg a   => 1 + fsize a
  | FTop | FBot => 1
  end.

(* ---------- NNF：互递归 nnf / nneg ---------- *)

Fixpoint nnf (f : form) : form :=
  match f with
  | FVar n   => FVar n
  | FAnd a b => FAnd (nnf a) (nnf b)
  | FOr a b  => FOr (nnf a) (nnf b)
  | FTop     => FTop
  | FBot     => FBot
  | FNeg a   => nneg a
  end
with nneg (a : form) : form :=
  match a with
  | FVar n   => FNeg (FVar n)
  | FAnd b c => FOr (nneg b) (nneg c)
  | FOr b c  => FAnd (nneg b) (nneg c)
  | FTop     => FBot
  | FBot     => FTop
  | FNeg b   => nnf b
  end.

Lemma nnf_nneg_correct : forall e f,
  eval e (nnf f) = eval e f /\ eval e (nneg f) = negb (eval e f).
Proof.
  intros e f. induction f as [n|f1 IH1 f2 IH2|f1 IH1 f2 IH2|f1 IH1| |];
    simpl in *.
  - split; reflexivity.
  - destruct IH1 as [A1 B1]. destruct IH2 as [A2 B2].
    split; [rewrite A1, A2; reflexivity
           |rewrite B1, B2;
            destruct (eval e f1), (eval e f2); reflexivity].
  - destruct IH1 as [A1 B1]. destruct IH2 as [A2 B2].
    split; [rewrite A1, A2; reflexivity
           |rewrite B1, B2;
            destruct (eval e f1), (eval e f2); reflexivity].
  - destruct IH1 as [A1 B1]. split; [exact B1|].
    rewrite A1. destruct (eval e f1); reflexivity.
  - split; reflexivity.
  - split; reflexivity.
Qed.

(* ---------- CNF：dist 的 fuel 化分配 ---------- *)

Fixpoint dist (fuel : nat) (p q : form) : form :=
  match fuel with
  | 0 => FOr p q
  | S k =>
    match p with
    | FAnd r s => FAnd (dist k r q) (dist k s q)
    | _ =>
      match q with
      | FAnd t u => FAnd (dist k p t) (dist k p u)
      | _ => FOr p q
      end
    end
  end.

Lemma dist_correct : forall fuel p q e,
  eval e (dist fuel p q) = orb (eval e p) (eval e q).
Proof.
  induction fuel as [|k IH]; intros p q e; simpl.
  - reflexivity.
  - destruct p as [n|r s|r s|r| |].
    + destruct q as [m|t u|t u|t| |]; simpl;
        try reflexivity;
        rewrite (IH (FVar n) t e), (IH (FVar n) u e); simpl;
        destruct (e n), (eval e t), (eval e u); reflexivity.
    + simpl. rewrite (IH r q e), (IH s q e).
      destruct (eval e r), (eval e s), (eval e q); reflexivity.
    + destruct q as [m|t u|t u|t| |]; simpl;
        try reflexivity;
        rewrite (IH (FOr r s) t e), (IH (FOr r s) u e);
        simpl; destruct (eval e r), (eval e s), (eval e t), (eval e u);
        reflexivity.
    + destruct q as [m|t u|t u|t| |]; simpl;
        try reflexivity;
        rewrite (IH (FNeg r) t e), (IH (FNeg r) u e); simpl;
        destruct (eval e r), (eval e t), (eval e u); reflexivity.
    + destruct q as [m|t u|t u|t| |]; simpl;
        try reflexivity;
        rewrite (IH FTop t e), (IH FTop u e); simpl;
        destruct (eval e t), (eval e u); reflexivity.
    + destruct q as [m|t u|t u|t| |]; simpl;
        try reflexivity;
        rewrite (IH FBot t e), (IH FBot u e); simpl;
        destruct (eval e t), (eval e u); reflexivity.
Qed.

Fixpoint cnf (f : form) : form :=
  match f with
  | FAnd a b => FAnd (cnf a) (cnf b)
  | FOr a b  => dist (fsize (cnf a) + fsize (cnf b)) (cnf a) (cnf b)
  | _ => f
  end.

Theorem cnf_correct : forall e f, eval e (cnf f) = eval e f.
Proof.
  intros e f. induction f as [n|f1 IH1 f2 IH2|f1 IH1 f2 IH2|f1 IH1| |];
    simpl.
  - reflexivity.
  - rewrite IH1, IH2. reflexivity.
  - rewrite (dist_correct _ _ _ e), IH1, IH2. reflexivity.
  - reflexivity.
  - reflexivity.
  - reflexivity.
Qed.

Theorem nnf_cnf_correct : forall e f, eval e (cnf (nnf f)) = eval e f.
Proof.
  intros e f. rewrite cnf_correct.
  destruct (nnf_nneg_correct e f) as [A _]. exact A.
Qed.

Print Assumptions nnf_cnf_correct.  (* Closed *)

(* ---------- 现场：分配可见 ---------- *)

Example cnf_demo :
  cnf (nnf (FOr (FVar 0) (FAnd (FVar 1) (FVar 2)))) =
    FAnd (FOr (FVar 0) (FVar 1)) (FOr (FVar 0) (FVar 2)).
Proof. reflexivity. Qed.

Example nnf_demo :
  nnf (FNeg (FAnd (FVar 0) (FVar 1))) = FOr (FNeg (FVar 0)) (FNeg (FVar 1)).
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - 互递归 nnf/nneg 的正确性并成一条合取引理、对 form 单归纳；
   - dist 的 fuel=0 兜底（FOr p q）语义即对——证明无尺寸负担；
   - 双联结词分支的布尔 bash：destruct 全体原子布尔 + reflexivity，
     最多 16 路，全部机械。 *)
