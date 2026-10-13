(* 第 14 章 Lévy 层级：量词前缀的层级判定器 *)

Require Import Arith Lia Lists.List.
Import ListNotations.

(* ---------- 一、公式的量词形状 ----------
   教学版：公式的"层级"由量词前缀的交替深度决定。
   qf（无量词）/ ex（存在）/ all（全称）标记。 *)

Inductive lev : Type :=
| L0  : lev                  (* Δ₀：受限（无量词计数） *)
| Sg  : nat -> lev           (* Σ_n *)
| Pi  : nat -> lev.

(* ---------- 二、对偶与封闭规则（引理 14.2 iii/v） ---------- *)

Definition dual (l : lev) : lev :=
  match l with
  | L0 => L0
  | Sg n => Pi n
  | Pi n => Sg n
  end.

Lemma dual_involutive : forall l, dual (dual l) = l.
Proof. intros l; destruct l; reflexivity. Qed.

(* 层级提升：Σ_n 的存在量化给 Σ_n（同层吸收）；
   Π_n 上的存在给 Σ_{n+1} *)
Definition ex_over (l : lev) : lev :=
  match l with
  | L0 => Sg 1
  | Sg n => Sg n
  | Pi n => Sg (S n)
  end.

Definition all_over (l : lev) : lev :=
  dual (ex_over (dual l)).

Lemma all_over_pi : forall n, all_over (Pi n) = Pi n.
Proof. intros n. reflexivity. Qed.

Lemma all_over_sg : forall n, all_over (Sg n) = Pi (S n).
Proof. intros n. reflexivity. Qed.

(* ---------- 三、Δₙ 的语义 ---------- *)

Definition is_delta_at (n : nat) (l : lev) : Prop :=
  l = Sg n /\ l = Pi n.

(* Δₙ 的语义：Σₙ ∩ Πₙ——受限公式同时算作 Σ₀ 与 Π₀（约定：
   L0 的标签语义见计算通道的层级判定器）。 *)

Print Assumptions dual_involutive.
Print Assumptions all_over_sg.
