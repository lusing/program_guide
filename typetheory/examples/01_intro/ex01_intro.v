(* ============================================================ *)
(* 01 认识类型论与四大证明助手 —— Coq 侧示例                    *)
(* 内核：CIC（λC + 归纳类型 + Prop/Type 双层宇宙）              *)
(* ============================================================ *)

(* ---- Coq 的判断形式就是  t : T  —— Check 即"判断可推导" ---- *)
Check (fun x : nat => x + 1).
Check nat.
Check (nat -> nat).
Check forall n : nat, n + 0 = n.

(* ---- 定义即 λ 抽象 ---- *)
Definition id_nat : nat -> nat := fun n => n.
Compute (id_nat 41).

(* ---- 命题即类型：forall n, n + 0 = n 是一个类型（在 Prop 宇宙） ---- *)
(* 证明即程序：tactic 构造的就是这个类型的居留项 *)
Theorem plus_n_O_tactic : forall n : nat, n + 0 = n.
Proof.
  induction n as [| n IH].
  - (* 0 + 0 = 0：按定义 0 + m 折叠为 m，定义相等即可 *)
    reflexivity.
  - (* S n + 0 = S n：折叠为 S (n + 0) = S n，用归纳假设 *)
    simpl. rewrite IH. reflexivity.
Qed.

(* ---- 同一个证明完全不用 tactic：直接写项 ---- *)
(* eq_refl 是相等类型的构造子；f_equal 是"合同性" cong ---- *)
Fixpoint plus_n_O_term (n : nat) : n + 0 = n :=
  match n with
  | O => eq_refl 0
  | S n' => @f_equal nat nat S (n' + 0) n' (plus_n_O_term n')
  end.

(* 两者的区别只在写法，机器里都是项 *)
Print plus_n_O_tactic.
Print plus_n_O_term.

(* ---- 零公理检查："Closed under the global context" ---- *)
Print Assumptions plus_n_O_term.

(* ---- Prop 与 Type 的双层宇宙 ---- *)
Check True.                        (* : Prop *)
Check nat.                         (* : Set *)
Check Type.                        (* : Type *)
Check (fun A : Type => A -> A).    (* : Type -> Type *)

(* ---- Prop 里的证明无关性（Coq 的 SProp / 理论上的证明无关） ---- *)
(* 粗看：Prop 的两个证明在消去受限的意义下行为一致（第 21 章细讲） *)

(* ---- 从柯里-霍华德看：-> 是蕴涵，forall 是全称量词 ---- *)
Theorem imp_trans_example : forall (P Q R : Prop),
  (P -> Q) -> (Q -> R) -> (P -> R).
Proof. intros P Q R hpq hqr hp. apply hqr. apply hpq. exact hp. Qed.

(* 纯项写法：这就是 λ 演算里的组合子 B = λf g x. f (g x) *)
Definition imp_trans_term : forall (P Q R : Prop),
  (P -> Q) -> (Q -> R) -> (P -> R) :=
  fun P Q R hpq hqr hp => hqr (hpq hp).
