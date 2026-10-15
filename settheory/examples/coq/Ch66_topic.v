(* 第 66 章：相关性：变量共享 + 爆炸律字母审计 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.


(* 变量共享条件 *)
Definition shares (la lb : list nat) : bool :=
  existsb (fun x => existsb (Nat.eqb x) lb) la.

(* (p∧¬p)→q 无字母共享 *)
Example no_share : shares [0] [1] = false.
Proof. vm_compute. reflexivity. Qed.

(* p→(q∨¬q) 无字母共享 *)
Example no_share2 : shares [0] [1] = false.
Proof. vm_compute. reflexivity. Qed.

(* Lewis 推导的语义验证：p∧¬p 恒假 *)
Example contradiction_false : forall p : bool, andb p (negb p) = false.
Proof. intros [|]; reflexivity. Qed.
