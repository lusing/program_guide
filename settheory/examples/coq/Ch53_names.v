(** 第 53 章：V^B 有限 toy——钻石代数上的名字宇宙 *)

Require Import Bool Arith List Lia.
Import ListNotations.

Inductive dia : Type := d0 | du | dv | d1.

Definition dmeet (a b : dia) : dia :=
  match a, b with
  | d0, _ => d0 | _, d0 => d0
  | du, du => du | dv, dv => dv
  | d1, x => x | x, d1 => x
  | _, _ => d0
  end.

Definition djoin (a b : dia) : dia :=
  match a, b with
  | d1, _ => d1 | _, d1 => d1
  | d0, x => x | x, d0 => x
  | du, du => du | dv, dv => dv
  | _, _ => d1
  end.

Definition dnot (a : dia) : dia :=
  match a with d0 => d1 | du => dv | dv => du | d1 => d0 end.

(** 布尔等价 a ↔ b *)
Definition iffd (a b : dia) : dia :=
  djoin (dmeet a b) (dmeet (dnot a) (dnot b)).

(** 名字：结构递归（子名 × 标签）的有限表 *)
Inductive name : Type :=
| nempty : name
| ncons : name -> dia -> name -> name.

(** 单元素容器：挂在唯一标签 b 上的名字 *)
Definition tagged (b : dia) : name :=
  ncons nempty b nempty.

(** ⟦τ = σ⟧ 的层 1 版（Def 7.1.25 的单标签直译） *)
Definition eq1 (t s : name) : dia :=
  match t, s with
  | ncons _ b1 _, ncons _ b2 _ => iffd b1 b2
  | _, _ => d1
  end.

(** ⟦τ ∈ σ⟧ 的层 1 版：⋁_{ξ∈dom σ} (σ(ξ) ∧ ⟦τ = ξ⟧) *)
Definition in1 (t s : name) : dia :=
  match s with
  | ncons _ b2 _ => dmeet b2 (eq1 t (tagged b2))
  | _ => d0
  end.

(* ---- 断言（vm_compute 决定性） ---- *)

(** 同标签的相等真值 = 1 *)
Lemma eq1_self : forall b, eq1 (tagged b) (tagged b) = d1.
Proof. intros b. destruct b; reflexivity. Qed.

(** 不同标签 du vs dv：iffd du dv = 0 *)
Lemma eq1_uv : eq1 (tagged du) (tagged dv) = d0.
Proof. reflexivity. Qed.

(** ∈ 自反样例：tagged du ∈ tagged du 当 du ∧ 1 = du *)
Lemma in1_self_du : in1 (tagged du) (tagged du) = du.
Proof. reflexivity. Qed.

(** check 名复原：∅ 的名字（无标签）在一切 G 下读出 ∅ *)
Fixpoint val0 (t : name) (G : dia -> bool) {struct t} : list dia :=
  match t with
  | ncons _ b r => if G b then b :: val0 r G else val0 r G
  | nempty => nil
  end.

Lemma check_empty : forall G, val0 nempty G = nil.
Proof. intros G. reflexivity. Qed.

(* G 作为函数须在 d1 上取 true——固定 G := fun b => match b with d1 | du => true | _ => false end *)
Definition Gup (b : dia) : bool :=
  match b with d1 => true | du => true | _ => false end.

Lemma check_singleton : val0 (tagged d1) Gup = d1 :: nil.
Proof. reflexivity. Qed.

Lemma check_du : val0 (tagged du) Gup = du :: nil.
Proof. reflexivity. Qed.
