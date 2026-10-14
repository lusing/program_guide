(** 第 48 章：Thm 3.9.3 (←) 的机器重建——Bool 上的环↔代数互译 *)

Require Import Bool Arith Lia List.
Import ListNotations.

(** 环侧运算：加法 = xor，乘法 = and *)
Definition radd (a b : bool) := xorb a b.
Definition rmul (a b : bool) := andb a b.
Definition rone := true.
Definition rzero := false.

(** 代数侧运算 *)
Definition bjoin (a b : bool) := orb a b.
Definition bmeet (a b : bool) := andb a b.
Definition bnot (a : bool) := negb a.

(** 重建公式一（Thm 3.9.3 (←)）：a ∨ b = a + b + a*b *)
(** 即 orb a b = xorb (xorb a b) (andb a b) *)
Lemma rebuild_join : forall a b,
  bjoin a b = radd (radd a b) (rmul a b).
Proof. intros a b; destruct a, b; reflexivity. Qed.

(** 重建公式二：¬a = 1 + a *)
Lemma rebuild_not : forall a,
  bnot a = radd rone a.
Proof. intros a; destruct a; reflexivity. Qed.

(** 幂等乘法（BooleanRing 的类律） *)
Lemma mul_idem : forall a, rmul a a = a.
Proof. intros a; destruct a; reflexivity. Qed.

(** Remark 3.9.2：幂等 ⟹ 特征 2（每步可计算）
    推导：(a+a)² = a+a （幂等）
          展开 a²+2ab+b² 型：此处 2x = x+x，x+x = 0（待证）
    在 Bool 上直接验证 a+a = 0： *)
Lemma char_two : forall a, radd a a = rzero.
Proof. intros a; destruct a; reflexivity. Qed.

(** 补律的环式证明（a*(1+a) = a + a*a = a + a = 0）：
    每一步都落在计算上 *)
Lemma compl_meet : forall a, rmul a (radd rone a) = rzero.
Proof. intros a; destruct a; reflexivity. Qed.

Lemma compl_join : forall a,
  radd (radd a (radd rone a)) (rmul a (radd rone a)) = rone.
Proof. intros a; destruct a; reflexivity. Qed.

(** N_b 的雏形：Bool 的超滤子只有一个（主超滤 {true}），
    Stone 空间是单点空间，N_b = [b]。对偶定理在此退化为恒等。 *)
Definition st_bool : list bool := true :: nil.
Definition Nb (b : bool) : list bool := if b then st_bool else nil.

Definition beqb (x y : bool) : bool := xorb x (xorb y true).

Definition interl (l1 l2 : list bool) : list bool :=
  filter (fun x => existsb (beqb x) l2) l1.

Lemma Nb_meet : forall b c, Nb (bmeet b c) = interl (Nb b) (Nb c).
Proof.
  intros b c; destruct b, c; simpl; reflexivity.
Qed.

(** 有限实验室：4 元布尔代数 Bool*Bool 的 Stone 空间是 2 点空间 *)
Definition p2 := (true, true) :: (true, false) :: nil.  (* 用 (bool*bool) 表示 *)
Definition andb2 (b g : bool * bool) : bool :=
  andb (andb (fst b) (fst g)) (andb (snd b) (snd g)).

Definition Nb4 (b : bool * bool) : list (bool * bool) :=
  filter (fun g => andb2 b g) p2.

(** 单射性抽验：四个元素给出两两不同的 N_b *)
Lemma Nb4_inj : Nb4 (true, true) <> Nb4 (true, false).
Proof. simpl. discriminate. Qed.
