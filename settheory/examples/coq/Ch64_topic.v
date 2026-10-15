(* 第 64 章：量词逻辑（Makinson Ch9）
   量词互换在有限论域上的验证 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.

Definition dom3 : list nat := [0;1;2].

Definition allP (P : nat -> bool) : bool := forallb P dom3.
Definition exP (P : nat -> bool) : bool := existsb P dom3.

(* 量词互换：在恒假谓词上验证 ¬∀ ≡ ∃¬ *)
Example quant_int_concrete :
    negb (allP (fun _ => false)) = exP (fun _ => negb false).
Proof. vm_compute. reflexivity. Qed.

(* 分配：在具体谓词上验证 *)
Example quant_dist_concrete :
    allP (fun x => andb (Nat.even x) true)
    = andb (allP Nat.even) (allP (fun _ => true)).
Proof. vm_compute. reflexivity. Qed.

(* ∃(a∨b) ≡ ∃a ∨ ∃b *)
Example quant_ex_dist :
    exP (fun x => orb (Nat.even x) (Nat.odd x))
    = orb (exP Nat.even) (exP Nat.odd).
Proof. vm_compute. reflexivity. Qed.
