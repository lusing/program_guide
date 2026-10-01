(* ============================================================ *)
(* 13 归纳类型族（Nordström ch.9–13）—— Coq 侧                    *)
(* 与 Lean 版同构：自造 N / add_comm / 列表 / Σ / 不交和          *)
(* ============================================================ *)

(* ---- 自然数 ---- *)

Inductive N : Set :=
| Nz : N
| Ns : N -> N.

Fixpoint add (n m : N) : N :=
  match n with
  | Nz => m
  | Ns n' => Ns (add n' m)
  end.

Lemma add_z : forall n, add n Nz = n.
Proof.
  induction n as [| n IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma add_s : forall n m, add n (Ns m) = Ns (add n m).
Proof.
  induction n as [| n IH]; intros m; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Theorem add_comm : forall n m, add n m = add m n.
Proof.
  induction n as [| n IH]; intros m; simpl.
  - rewrite add_z. reflexivity.
  - rewrite add_s, IH. reflexivity.
Qed.

(* ---- 列表 ---- *)

Inductive Lst (A : Type) : Type :=
| lnil : Lst A
| lcons : A -> Lst A -> Lst A.

Arguments lnil {A}.
Arguments lcons {A} x xs.

Fixpoint app {A} (xs ys : Lst A) : Lst A :=
  match xs with
  | lnil => ys
  | lcons x xs' => lcons x (app xs' ys)
  end.

Lemma app_nil_r : forall (A : Type) (xs : Lst A), app xs lnil = xs.
Proof.
  intros A xs. induction xs as [| x xs IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Theorem app_assoc : forall (A : Type) (xs ys zs : Lst A),
  app (app xs ys) zs = app xs (app ys zs).
Proof.
  intros A xs ys zs. induction xs as [| x xs IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

(* ---- Σ：依赖对（Lst 化的教学版 sig） ---- *)

Record Sig2 (A : Type) (B : A -> Type) : Type := mkSig
{ sfst : A; ssnd : B sfst }.

Definition sigEx : Sig2 N (fun _ => Lst N) :=
  mkSig N (fun _ => Lst N) (Ns Nz) (lcons Nz lnil).

Compute sfst N (fun _ => Lst N) sigEx.    (* Ns Nz *)

(* 逻辑读法：存在量词 *)
Definition exN (B : N -> Type) : Type := Sig2 N B.

(* ---- 不交和 ---- *)

Inductive Sum2 (A B : Type) : Type :=
| inl : A -> Sum2 A B
| inr : B -> Sum2 A B.

Arguments inl {A B} a.
Arguments inr {A B} b.

Definition elim2 {A B : Type} (P : Sum2 A B -> Type)
  (l : forall a, P (inl a)) (r : forall b, P (inr b))
  (s : Sum2 A B) : P s :=
  match s with
  | inl a => l a
  | inr b => r b
  end.

Definition decEx (s : Sum2 N (Lst N)) : N :=
  match s with inl n => n | inr _ => Nz end.

(* 消去子的自动生成版：N_ind / N_rect 打印欣赏 *)
Print N_ind.
Print N_rect.
(* _rect 是 Type 版（大消去）；_ind 是 Prop 版——归纳原理的双报 *)
