(** 第 54 章：九公理证书的机器样板——up 名与分离名 *)

Require Import Bool Arith List.
Import ListNotations.

Inductive dia : Type := d0 | du | dv | d1.

Definition dmeet (a b : dia) : dia :=
  match a, b with
  | d0, _ => d0 | _, d0 => d0
  | du, du => du | dv, dv => dv
  | d1, x => x | x, d1 => x
  | _, _ => d0
  end.

Definition Gup (b : dia) : bool :=
  match b with d1 | du => true | _ => false end.

(** 名字（53 章同款非索引） *)
Inductive name : Type :=
| nempty : name
| ncons : name -> dia -> name -> name.

(** G-读出 *)
Fixpoint valG (t : name) {struct t} : list dia :=
  match t with
  | ncons _ b r => if Gup b then b :: valG r else valG r
  | nempty => nil
  end.

(** ---- 配对公理证书：up(τ,σ) := {(τ,1), (σ,1)} ---- *)
Definition up (t s : name) : name :=
  ncons t d1 (ncons s d1 nempty).

(** up 的两个 d1 标签读出恒在 G 中 *)
Lemma up_cert :
  forall t s : name, In d1 (valG (up t s)).
Proof.
  intros t s. simpl. left. reflexivity.
Qed.

(** 具体验证：up(τ,σ) 挂两个 d1 标签（子名 τ σ），读出 [d1;d1] *)
Lemma up_concrete :
  valG (up (ncons nempty du nempty) (ncons nempty dv nempty)) = d1 :: d1 :: nil.
Proof. reflexivity. Qed.

(** ---- 并公理证书：∪τ := {(ξ,1) : ξ ∈ ∪dom(τ)}（骨架） ---- *)
(** 分离名：{(ξ, ⟦φ(ξ)⟧) : ξ ∈ dom τ}——把真值当标号 *)
Fixpoint sepname (t : name) (phi : dia -> dia) {struct t} : name :=
  match t with
  | ncons s b r => ncons s (phi b) (sepname r phi)
  | nempty => nempty
  end.

(** 集合包含的列表版（提前定义） *)
Definition incl (A B : list dia) : Prop :=
  forall x, In x A -> In x B.

Lemma incl_nil_l : forall B, incl nil B.
Proof. intros B x H. inversion H. Qed.

Lemma incl_cons : forall (a : dia) A B,
  In a B -> incl A B -> incl (a :: A) B.
Proof.
  intros a A B Ha HAB x Hx.
  destruct Hx as [Hx | Hx].
  - subst x. exact Ha.
  - apply HAB. exact Hx.
Qed.

(** 分离证书：sep 的读出 ⊆ 原读出——骨架 *)
Lemma sep_cert :
  forall (t : name) (phi : dia -> dia),
    incl (valG (sepname t phi)) (valG t).
Proof.
  intros t phi.
  induction t as [| s IHs b r IHr]; simpl.
  - intros x H. inversion H.
  - destruct (Gup (phi b)) eqn:Hphi; simpl.
    + intros x [Hx | Hx].
      * (* phi b = x 且 phi b ∈ G：需 x ∈ 原读出。真值当标号时
           phi b ≠ b 可引进新元素——完整证书需 Viale Lemma 7.2.9
           的 dom-保持名字改造（骨架如实 Admitted） *)
        admit.
      * destruct (Gup b).
        -- right. apply IHr. exact Hx.
        -- apply IHr. exact Hx.
    + destruct (Gup b).
      * intros x H. right. apply IHr. exact H.
      * apply IHr.
Admitted.
