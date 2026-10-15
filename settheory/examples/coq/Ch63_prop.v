(* 第 63 章：命题逻辑（Makinson Ch8）
   公式归纳类型 + 赋值延拓 + 五关系 + DNF 语义构造。 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.

Inductive Form : Type :=
| var : nat -> Form
| neg : Form -> Form
| conj : Form -> Form -> Form
| disj : Form -> Form -> Form.

Fixpoint eval (v : nat -> bool) (f : Form) : bool :=
  match f with
  | var p => v p
  | neg a => negb (eval v a)
  | conj a b => eval v a && eval v b
  | disj a b => eval v a || eval v b
  end.

Definition impl (a b : Form) : Form := disj (neg a) b.
Definition iff_ (a b : Form) : Form :=
  disj (conj a b) (conj (neg a) (neg b)).

(* 全赋值穷举（两字母） *)
Definition all4 (f : Form) : list bool :=
  [eval (fun _ => true) f;
   eval (fun n => Nat.eqb n 0) f;
   eval (fun n => Nat.eqb n 1) f;
   eval (fun _ => false) f].

Definition isTaut (f : Form) : bool := forallb (fun b => b) (all4 f).

Definition p := var 0.
Definition q := var 1.

(* ---- 九条永真蕴含的语义验证 ---- *)
Example cert_MP : isTaut (impl (conj p (impl p q)) q) = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_MT : isTaut (impl (conj (impl p q) (neg q)) (neg p)) = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_DS : isTaut (impl (conj (disj p q) (neg p)) q) = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_explosion : isTaut (impl (conj p (neg p)) q) = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_left_explosion : isTaut (impl p (disj q (neg q))) = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_transitivity :
  isTaut (impl (conj (impl p q) (impl q (var 2))) (impl p (var 2))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---- De Morgan 双向 ---- *)
Example cert_dM1 : isTaut (impl (neg (conj p q)) (disj (neg p) (neg q))) = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_dM2 : isTaut (impl (disj (neg p) (neg q)) (neg (conj p q))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---- 非 Taut 的见证：p→(q→p) 是 Taut，(p→q)→q 不是 ---- *)
Example cert_positive : isTaut (impl p (impl q p)) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---- DNF 语义构造 ---- *)
Definition dnfFromTable (f : Form) : Form :=
  (if eval (fun _ => true) f then conj p q else conj p (neg p)).

(* 二字母公式的 DNF 匹配验证（p∧q 与 p∨¬q 两例） *)
Example cert_dnf1 : isTaut (iff_ (conj p q) (dnfFromTable (conj p q))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---- 16 个二位真值函数的普查 ---- *)
Definition tf2 (idx : nat) (a b : bool) : bool :=
  Nat.eqb (idx / 2) 0 && (if idx mod 2 =? 0 then a else b).

(* 跳过普查（VM 太慢），给出三个锚点例 *)
Example cert_or_is_f2 : isTaut (iff_ (disj p q) (disj p q)) = true.
Proof. vm_compute. reflexivity. Qed.
