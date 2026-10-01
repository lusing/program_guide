(* ============================================================ *)
(* 05 Curry–Howard —— Coq 侧：蕴涵公式的「证明即程序」           *)
(* ① 直觉主义定理 = Prop 居留项，零公理                         *)
(* ② Peirce 律需要经典公理——Print Assumptions 全程盯梢         *)
(* ============================================================ *)

(* ---- ① 直觉主义：这些就是 λ→ 的居留项 ---- *)

(* I = λx.x : a → a *)
Lemma I : forall a : Prop, a -> a.
Proof. exact (fun a (x : a) => x). Qed.

(* K = λx y.x : a → b → a *)
Lemma K : forall a b : Prop, a -> b -> a.
Proof. exact (fun a b (x : a) (_ : b) => x). Qed.

(* S = λx y z. x z (y z) *)
Lemma S : forall a b c : Prop,
  (a -> b -> c) -> (a -> b) -> a -> c.
Proof. exact (fun a b c (x : a -> b -> c) (y : a -> b) (z : a) => x z (y z)). Qed.

(* B = λf g x. f (g x)：组合子代数里 B = S (K S) K，
   这里直接给出居留项 *)
Lemma B : forall a b c : Prop,
  (b -> c) -> (a -> b) -> a -> c.
Proof. exact (fun a b c (f : b -> c) (g : a -> b) (x : a) => f (g x)). Qed.

Print Assumptions I.   (* Closed under the global context *)
Print Assumptions K.
Print Assumptions S.
Print Assumptions B.

(* ---- ② Peirce 律：经典可证，公理入账 ---- *)

Require Import Classical.

Theorem peirce : forall a b : Prop, ((a -> b) -> a) -> a.
Proof.
  intros a b H.
  destruct (classic a) as [Ha | Hna].
  - exact Ha.
  - apply H. intros Ha. destruct (Hna Ha).       (* 从 a 与 ¬a 得 b（爆炸） *)
Qed.

Print Assumptions peirce.
(* 依赖 classic（排中律）。对比：I/K/S/B 一条公理都不欠 *)

(* ---- ③ 演绎定理的机械性：imp 的引入就是抽象 ---- *)

Section Deduction.
  Variables (P Q : Prop) (Hpq : P -> Q) (Hqp : Q -> P).

  Check (fun Hp : P => Hp).                  (* P -> P：假设的弱化 *)
  Check (fun Hp : P => Hpq Hp).              (* P -> Q：modus ponens 的闭包 *)

  Check (B P Q P Hqp Hpq : P -> P).          (* B 的应用就是推理复合 *)
End Deduction.
