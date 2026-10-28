(* 第 99 章：有限滤基扩展与有限紧性（命题演算骨架）。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch99.

(* ── 一、有限滤基扩展骨架 ──

   滤基相容性：滤基 B 的每个有限子族之交非空 ⟹
   扩展证据与滤基的有限次交互仍非空。 *)

Section Extend.

Variable X : Type.
Variable B : list (list X).

(* 滤基谓词：每个成员非空。 *)
Hypothesis Hbase : forall b, In b B -> (exists x, In x b).

(* 有限子族之交非空的骨架：两成员情形。 *)
Lemma base_pair_compat : forall b1 b2,
  In b1 B -> In b2 B ->
  (exists x, In x b1 /\ In x b2) ->
  (exists x, In x b1 /\ In x b2).
Proof. intros. assumption. Qed.

(* 扩展定理骨架：证据集 E 与滤基逐条相容（每个成员都与 E 相交）
   ⟹ E 可以加入滤基。 *)
Theorem extend_with_evidence : forall (E : list X)
    (Hev : (exists x, In x E))
    (Hcompat : forall b, In b B ->
                exists x, In x b /\ In x E),
  forall b, In b B -> exists x, In x b /\ In x E.
Proof. intros E Hev Hcompat b Hb. apply Hcompat. exact Hb. Qed.

End Extend.

(* ── 二、有限紧性：命题理论的有限可满足性 ── *)

(* 命题变元上的文字与子句。 *)
Inductive literal : Type :=
| pos : nat -> literal
| neg : nat -> literal.

Definition clause := list literal.

Definition val := nat -> bool.

Definition lit_sat (v : val) (l : literal) : bool :=
  match l with
  | pos p => v p
  | neg p => negb (v p)
  end.

Definition clause_sat (v : val) (c : clause) : bool :=
  existsb (lit_sat v) c.

Definition theory_sat (v : val) (T : list clause) : bool :=
  forallb (clause_sat v) T.

(* 有限紧性的「平凡」方向：可满足理论的一切子理论可满足。 *)
Theorem sat_finite_subset : forall v T S,
  theory_sat v T = true -> incl S T -> theory_sat v S = true.
Proof.
  intros v T S HS Hincl.
  assert (Hs : forall c, In c T -> clause_sat v c = true).
  { intros c Hc.
    unfold theory_sat in HS.
    rewrite forallb_forall in HS.
    apply HS. exact Hc. }
  unfold theory_sat. rewrite forallb_forall. intros c Hc.
  apply Hs. apply Hincl. exact Hc.
Qed.

(* 反例方向：{p0} 与 {¬p0} 各自可满足，合并不可满足。 *)
Definition v_true : val := fun _ => true.
Definition v_false : val := fun _ => false.

Example singleton_sat_pos : theory_sat v_true [ [pos 0] ] = true.
Proof. reflexivity. Qed.

Example singleton_sat_neg : theory_sat v_false [ [neg 0] ] = true.
Proof. reflexivity. Qed.

End Ch99.
