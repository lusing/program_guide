(* ============================================================ *)
(* 18 程序即证明：提取与求值 —— Coq 侧                           *)
(* ① Compute：证明里的程序直接跑                                 *)
(* ② Extraction：Coq → OCaml（证明擦除后的可执行残骸）           *)
(* ③ 证明无关性：Prop 世界的两条证明不可分辨                      *)
(* ============================================================ *)

Require Import List Arith Lia.
Import ListNotations.

Fixpoint rev {A : Type} (xs : list A) : list A :=
  match xs with
  | [] => []
  | x :: xs' => rev xs' ++ [x]
  end.

Theorem rev_rev : forall (A : Type) (xs : list A), rev (rev xs) = xs.
Proof.
  intros A xs.
  assert (H : forall l1 l2 : list A, rev (l1 ++ l2) = rev l2 ++ rev l1).
  { intros l1 l2. induction l1 as [| x l1 IH]; simpl.
    - rewrite app_nil_r. reflexivity.
    - rewrite IH, app_assoc. reflexivity. }
  induction xs as [| x xs IH]; simpl.
  - reflexivity.
  - rewrite H, IH. reflexivity.
Qed.

(* ---- ① Compute：内核求值器就是运行器 ---- *)
Compute rev (rev [1; 2; 3; 4]).        (* = [1; 2; 3; 4] *)
Compute map (fun n => n * n) [1; 2; 3; 4; 5].   (* 平方表 *)

(* ---- ② Extraction：抽成 OCaml ---- *)
Require Import Extraction.

Extraction Language OCaml.
Extraction rev.
(* 输出（节选）：
   let rec rev = function
     | [] -> []
     | x :: xs' -> (rev xs') @ [x]
   ——注意类型 A 与证明 rev_rev【全被擦除】：提取的是纯程序 *)

Extraction rev_rev.
(* 输出：__          ——定理的「计算残骸」是哑元！
   证明只在类型层干活，运行时零负担（证明擦除的极端形态） *)

(* ---- ③ 证明无关性（现代类型论 3.5 的机器面） ---- *)

Require Import Coq.Logic.ProofIrrelevance.

(* Prop 里的证明相等是定理 *)
Check proof_irrelevance :
  forall (P : Prop) (p q : P), p = q.

(* 对具体命题实测 *)
Lemma pi_demo : (le_n 3) = (le_n 3 : 3 <= 3).
Proof. apply proof_irrelevance. Qed.

(* 但 Type 世界【不】无关：不同的 nat 构造是真不同的数据 *)
(* (1, 2) 与 (1, 3) 作为 nat * nat 的元素不可等同——
   证明无关性是 Prop 的特权，Type 里「证据即数据」 *)
Fail Check (eq_refl : (1, 2) = (1, 3)).

(* SProp：严格证明无关的层（比 Prop 更纯） *)
Generalizable All Variables.
Module SPropDemo.
  Inductive Seq : nat -> nat -> SProp := Srefl : forall n : nat, Seq n n.
  (* SProp 里一切证明自动相等：无需 proof_irrelevance *)
End SPropDemo.
