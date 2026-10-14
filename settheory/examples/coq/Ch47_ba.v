(** 第 47 章：抽象布尔代数的补唯一律（公理记帐式证明）

    浅嵌入：Section 变量给出 (B, ⊓, ⊔, ¬, ⊤, ⊥) 与公理假设，
    只用等式重写完成 Prop 3.3.1 (ii)。哪些公理被用到，
    Hypothesis 名字一清二楚——这正是"公理显式记账"的教学点。 *)

Require Import List Arith Lia.
Import ListNotations.

Section BooleanAlgebra.

Variable B : Type.
Variables (bmeet bjoin : B -> B -> B) (bnot : B -> B).
Variables (btop bbot : B).

(* 公理（Viale Def 3.1.1 的等式部分；只列本证明用到的 + 全部十条中的其余项） *)
Hypothesis (meet_join_distr :
  forall a b c, bmeet a (bjoin b c) = bjoin (bmeet a b) (bmeet a c)).
Hypothesis (join_meet_distr :
  forall a b c, bjoin a (bmeet b c) = bmeet (bjoin a b) (bjoin a c)).
Hypothesis (meet_comm : forall a b, bmeet a b = bmeet b a).
Hypothesis (join_comm : forall a b, bjoin a b = bjoin b a).
Hypothesis (meet_top : forall a, bmeet a btop = a).
Hypothesis (join_bot : forall a, bjoin a bbot = a).
Hypothesis (meet_compl : forall a, bmeet a (bnot a) = bbot).
Hypothesis (join_compl : forall a, bjoin a (bnot a) = btop).

(** 补唯一律（Prop 3.3.1 (ii)）：
    b ⊓ a = ⊥ 且 b ⊔ a = ⊤ ⟹ b = ¬a

    纸笔路线（47.3 节）的三步：
    (1) b = b ⊓ ⊤ = b ⊓ (a ⊔ ¬a) = (b ⊓ a) ⊔ (b ⊓ ¬a) = b ⊓ ¬a
    (2) 对偶：b = b ⊔ ¬a（由 b ⊔ a = ⊤ 展开吸收）
    (3) 合并两式的"序两半"得 b = ¬a *)
Lemma compl_unique : forall a b,
  bmeet b a = bbot -> bjoin b a = btop -> b = bnot a.
Proof.
  intros a b H1 H2.
  (* (1) b = b ⊓ ¬a *)
  assert (hsub : b = bmeet b (bnot a)).
  { rewrite <- (meet_top b) at 1.
    rewrite <- (join_compl a).
    rewrite meet_join_distr, H1.
    rewrite (join_comm bbot (bmeet b (bnot a))).
    apply join_bot. }
  (* (3a) ¬a = ¬a ⊓ (b ⊔ a) = (¬a ⊓ b) ⊔ (¬a ⊓ a) = ¬a ⊓ b *)
  assert (hrev : bnot a = bmeet (bnot a) b).
  { rewrite <- (meet_top (bnot a)) at 1.
    rewrite <- H2.
    rewrite meet_join_distr.
    rewrite (meet_comm (bnot a) a), meet_compl.
    apply join_bot. }
  (* (3b) 合并：b = b ⊓ ¬a = ¬a ⊓ b = ¬a *)
  rewrite hsub, (meet_comm b (bnot a)).
  symmetry.
  exact hrev.
Qed.

End BooleanAlgebra.

(** 在 2 元具体模型上冒烟：验证公理假设在 Bool 上全部成立，
    从而 compl_unique 对 Bool 实例化可用（补唯一律的"落地"）。 *)
Require Import Bool.

Definition bm (a b : bool) := andb a b.
Definition bj (a b : bool) := orb a b.
Definition bn (a : bool) := negb a.

Lemma bool_axioms_ok :
  (forall a b c, bm a (bj b c) = bj (bm a b) (bm a c)) /\
  (forall a b c, bj a (bm b c) = bm (bj a b) (bj a c)) /\
  (forall a b, bm a b = bm b a) /\
  (forall a, bm a true = a) /\
  (forall a, bj a false = a) /\
  (forall a, bm a (bn a) = false) /\
  (forall a, bj a (bn a) = true).
Proof.
  split; [ intros a b c; destruct a, b, c; reflexivity | ].
  split; [ intros a b c; destruct a, b, c; reflexivity | ].
  split; [ intros a b; destruct a, b; reflexivity | ].
  split; [ intros a; destruct a; reflexivity | ].
  split; [ intros a; destruct a; reflexivity | ].
  split; [ intros a; destruct a; reflexivity | ].
  intros a; destruct a; reflexivity.
Qed.

(* compl_unique 的 Bool 实例（用公理 + 具体计算） *)
Example bool_compl_unique : forall a b : bool,
  bm b a = false -> bj b a = true -> b = bn a.
Proof.
  intros a b H1 H2.
  unfold bm, bj, bn in *.
  destruct a, b; simpl in *; try reflexivity;
    discriminate || reflexivity.
Qed.
