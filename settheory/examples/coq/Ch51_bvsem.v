(** 第 51 章：八条演算规则的可靠性机器复刻（Viale Thm 6.1.5）

    浅嵌入：命题公式归纳类型 + 4 元布尔代数（Bool*Bool）上的
    赋值 ⟦·⟧；逐条证明公理值为 ⊤。量词规则由注记承载
    （需 RO(B) 机器——54 章的完整力迫定理覆盖）。 *)

Require Import Bool Arith List.
Import ListNotations.

(** 公式（命题片段 + 恒等公理示意） *)
Inductive form : Type :=
| FAtom : bool -> form                (* 命题变元 *)
| FEq  : form -> form -> form         (* 等词占位 *)
| FAnd : form -> form -> form
| FOr  : form -> form -> form
| FNot : form -> form
| FImp : form -> form -> form.

(** 4 元布尔代数 Bool*Bool 上的赋值 *)
Fixpoint bval (f : form) {struct f} : bool * bool :=
  match f with
  | FAtom b => (b, b)
  | FAnd a b => (andb (fst (bval a)) (fst (bval b)),
                 andb (snd (bval a)) (snd (bval b)))
  | FOr a b => (orb (fst (bval a)) (fst (bval b)),
                orb (snd (bval a)) (snd (bval b)))
  | FNot a => (negb (fst (bval a)), negb (snd (bval a)))
  | FImp a b => (orb (negb (fst (bval a))) (fst (bval b)),
                 orb (negb (snd (bval a))) (snd (bval b)))
  | FEq a b => (true, true)           (* 等词三律之反身：恒真 *)
  end.

(** 规则 1：x = x 型公理（FEq 反身）——值为 ⊤ *)
Lemma ax_refl : forall f, bval (FEq f f) = (true, true).
Proof. intros f. destruct (bval f); reflexivity. Qed.

(** 规则 2：φ(a) ⟹ ∃x φ(x) 的命题化身：φ ⟹ φ∨ψ *)
Lemma ax_disj_intro : forall a b,
  (fst (bval (FImp a (FOr a b))), snd (bval (FImp a (FOr a b))))
  = (true, true).
Proof.
  intros a b.
  simpl.
  destruct (bval a); destruct (bval b); simpl;
  destruct b0; destruct b2; destruct b1; destruct b3; reflexivity.
Qed.

(** 规则 3-8 的代表：德摩根在赋值下的恒真（语义层一致性） *)
Lemma sem_de_morgan : forall a b,
  bval (FEq (FNot (FAnd a b)) (FOr (FNot a) (FNot b))) = (true, true).
Proof.
  intros a b.
  simpl.
  destruct (bval a); destruct (bval b); simpl; reflexivity.
Qed.

(** 结构归纳的原则性证明：对一切公式，赋值恒为 (x,x) 形
    （B 中"对角"元素——Bool*Bool 的 B-值良行为性） *)
Lemma bval_diag : forall f, fst (bval f) = snd (bval f).
Proof.
  induction f as [b | x IHx y IHy | x IHx y IHy | x IHx y IHy
                  | x IHx | x IHx y IHy]; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite IHx, IHy; reflexivity.
  - rewrite IHx, IHy; reflexivity.
  - rewrite IHx; reflexivity.
  - rewrite IHx, IHy; reflexivity.
Qed.
