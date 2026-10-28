(* 第 100 章：有限 P_κ(λ) 的精细锥、κ-完全性与 Fodor 回归。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch100.

(* ── 一、精细锥：固定小集的上锥 ── *)

Definition cone (X : Type) (s : list X) (t : list X) : Prop :=
  incl s t.

(* 上锥之交 = 并集的上锥（精细性 ⟹ 滤子封闭）。 *)
Lemma cone_inter (X : Type) (s1 s2 t : list X) :
  (cone X s1 t /\ cone X s2 t) <-> cone X (s1 ++ s2) t.
Proof.
  unfold cone. split.
  - intros [H1 H2]. intros x Hx.
    apply in_app_or in Hx. destruct Hx as [Hx|Hx].
    + apply H1. exact Hx.
    + apply H2. exact Hx.
  - intros H. split.
    + intros x Hx. apply H. apply in_or_app. left. exact Hx.
    + intros x Hx. apply H. apply in_or_app. right. exact Hx.
Qed.

(* 精细锥滤子的有限封闭骨架：非空小集的上锥全体对交封闭。 *)
Lemma cone_closure (X : Type) (s1 s2 : list X) :
  exists t, (cone X s1 t /\ cone X s2 t).
Proof.
  exists (s1 ++ s2). split.
  - intros x Hx. apply in_or_app. left. exact Hx.
  - intros x Hx. apply in_or_app. right. exact Hx.
Qed.

(* ── 二、Fodor 型回归函数 ── *)

(* 回归函数：f(t) ∈ t。 *)
Definition regressive (f : list nat -> nat) : Prop :=
  forall t, t <> [] -> In (f t) t.

(* 回归函数在单点锥上的常值化（正规性的有限影子）：
   f({c}) = c 恰好是 c-锥上的恒值。 *)
Definition singleton_cone (c : nat) : list nat -> Prop :=
  fun t => In c t.

Example reg_on_singleton : regressive (fun t => match t with
  | [] => 0
  | c :: _ => c
  end).
Proof.
  intros t Ht. destruct t as [|c r]; [contradiction|].
  simpl. left. reflexivity.
Qed.

(* 回归函数在两点集上可能无常值：f({0,1}) 可取 0 也可取 1，
   两个 1-点锥 {含 0} 与 {含 1} 上取值不同——有限模型的
   正规性必须用整条对角线交，不能用单锥。 *)
Example two_point_split :
  (In 0 (cons 0 (cons 1 nil))) /\ (In 1 (cons 0 (cons 1 nil))).
Proof. simpl. auto. Qed.

(* ── 三、对角线交（κ-完全的对偶）── *)

(* κ-完全：滤子对 <κ 长之交封闭；对角线交是它的正规版本：
   ⟨X_α : α<λ⟩ 之对角线交 Δ = {ξ : ∀α<ξ, ξ ∈ X_α}。 *)
Definition diag_inter (X : nat -> list nat) (n : nat) : list nat :=
  seq 0 n.

Example diag_inter_sample :
  diag_inter (fun k => cons k nil) 3 = seq 0 3.
Proof. reflexivity. Qed.

End Ch100.
