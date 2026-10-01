(* ============================================================ *)
(* 17 四大助手对照 —— Coq 版：reverse (reverse xs) = xs           *)
(* ============================================================ *)

Require Import List Arith.
Import ListNotations.

Fixpoint rev {A : Type} (xs : list A) : list A :=
  match xs with
  | [] => []
  | x :: xs' => rev xs' ++ [x]
  end.

Compute rev [1; 2; 3].                       (* [3; 2; 1] *)

(* 关键引理：战术排布最见功力的一步 *)
Lemma rev_append : forall (A : Type) (xs ys : list A),
  rev (xs ++ ys) = rev ys ++ rev xs.
Proof.
  intros A xs ys.
  induction xs as [| x xs IH]; simpl.
  - rewrite app_nil_r. reflexivity.
  - rewrite IH. rewrite app_assoc. reflexivity.
Qed.

Theorem rev_rev : forall (A : Type) (xs : list A), rev (rev xs) = xs.
Proof.
  intros A xs.
  induction xs as [| x xs IH]; simpl.
  - reflexivity.
  - rewrite rev_append, IH. reflexivity.
Qed.

(* 例化检查 *)
Example rev_rev_123 : rev (rev [1; 2; 3]) = [1; 2; 3].
Proof. apply rev_rev. Qed.

(* 与另两家的差异速记：
   ① 战术排布要「手排」：app_nil_r / app_assoc 的次序是排出来的；
   ② simpl 的展开时机影响 rewrite 的可匹配性（12/13 章的 iota 教训）；
   ③ induction ... as [| x xs IH] 显式命名——Coq 的老派严谨。 *)
