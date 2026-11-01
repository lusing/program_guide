Require Import Bool List Btauto Arith Lia.
Import ListNotations.

(* 第 122 章：AD^{L(R)} 的有限影子。
   有限博弈、尾等价代表、完美树密度界与参数编码；不证明无限 AD。 *)

Definition b2n (b : bool) : nat := if b then 1 else 0.

Definition i_wins (f : nat -> bool) (a0 z0 z1 : bool) : bool :=
  (f (b2n a0 + 4*b2n z0) && f (b2n a0 + 4*b2n z0 + 8)) &&
  (f (b2n a0 + 2 + 4*b2n z1) && f (b2n a0 + 2 + 4*b2n z1 + 8)).

Definition ii_wins (f : nat -> bool)
    (b00 b01 q000 q001 q100 q101 : bool) : bool :=
  negb (f (2*b2n b00 + 8*b2n q000)) &&
  negb (f (2*b2n b00 + 4 + 8*b2n q001)) &&
  negb (f (1 + 2*b2n b01 + 8*b2n q100)) &&
  negb (f (1 + 2*b2n b01 + 4 + 8*b2n q101)).

Definition triples : list (bool*bool*bool) :=
  [(false,false,false); (false,false,true);
   (false,true,false); (false,true,true);
   (true,false,false); (true,false,true);
   (true,true,false); (true,true,true)].

Definition sextuples : list (bool*bool*bool*bool*bool*bool) :=
  flat_map (fun b00 => flat_map (fun b01 =>
  flat_map (fun q000 => flat_map (fun q001 =>
  flat_map (fun q100 => map (fun q101 =>
    (b00,b01,q000,q001,q100,q101)) [false;true])
    [false;true]) [false;true]) [false;true]) [false;true])
    [false;true].

Definition i_any (f : nat -> bool) : bool :=
  existsb (fun s => i_wins f (fst (fst s)) (snd (fst s)) (snd s)) triples.

Definition ii_any (f : nat -> bool) : bool :=
  existsb (fun s => ii_wins f
    (fst (fst (fst (fst (fst s)))))
    (snd (fst (fst (fst (fst s)))))
    (snd (fst (fst (fst s))))
    (snd (fst (fst s)))
    (snd (fst s)) (snd s)) sextuples.

Definition even_pay (x : nat) : bool := Nat.even x.
Definition never_pay (_ : nat) : bool := false.

Theorem even_i_wins : i_wins even_pay false false false = true.
Proof. reflexivity. Qed.

Theorem even_i_any : i_any even_pay = true.
Proof. reflexivity. Qed.

Theorem even_ii_any : ii_any even_pay = false.
Proof. reflexivity. Qed.

Theorem never_i_any : i_any never_pay = false.
Proof. reflexivity. Qed.

Theorem never_ii_any : ii_any never_pay = true.
Proof. reflexivity. Qed.

Theorem exclusive_strategies_length4 :
  forall f a0 z0 z1 b00 b01 q000 q001 q100 q101,
    negb (i_wins f a0 z0 z1 &&
          ii_wins f b00 b01 q000 q001 q100 q101) = true.
Proof.
  intros f [] [] [] [] [] [] [] [] []; vm_compute; btauto.
Qed.

(* 尾等价代表：保留高两位，清除低两位。 *)
Definition tail_rep (x : nat) : nat := (x / 4) * 4.

Theorem tailrep_idempotent : forall x, x < 16 ->
  tail_rep (tail_rep x) = tail_rep x.
Proof. intros x H; do 16 (destruct x; [reflexivity|]); lia. Qed.

Theorem tailrep_same_class : forall x, x < 16 ->
  tail_rep x / 4 = x / 4.
Proof. intros x H; do 16 (destruct x; [reflexivity|]); lia. Qed.

Definition tail_payoff (x : nat) : bool := negb (Nat.eqb (x mod 4) 1).
Theorem tailset_size_12 :
  length (filter tail_payoff (seq 0 16)) = 12.
Proof. reflexivity. Qed.

(* 深度 d 完美树：某长度 4-d 柱的全部 2^d 叶点均属于 A。 *)
Definition has_perfect (f : nat -> bool) (d : nat) : bool :=
  existsb (fun s => forallb (fun t => f (s*2^d+t)) (seq 0 (2^d)))
    (seq 0 (2^(4-d))).

Definition tight_set (d : nat) (x : nat) : bool :=
  negb (Nat.eqb (x mod (2^d)) 0).

Theorem perfect_bound_tight :
  forall d, 1 <= d <= 4 ->
    has_perfect (tight_set d) d = false /\
    length (filter (tight_set d) (seq 0 16)) = 16 - 2^(4-d).
Proof.
  intros d [H1 H4].
  assert (d=1 \/ d=2 \/ d=3 \/ d=4) as E by lia.
  destruct E as [Hd | [Hd | [Hd | Hd]]]; subst d; split; reflexivity.
Qed.

(* 定义参数编码：p<8 为序数参数，a<16 为实数参数。 *)
Definition enc_param (p a : nat) : nat := p*16+a.
Definition dec_param (c : nat) : nat*nat := (c/16,c mod 16).
Theorem param_roundtrip : forall p a, p<8 -> a<16 ->
  dec_param (enc_param p a) = (p,a).
Proof.
  intros p a Hp Ha; unfold dec_param,enc_param; f_equal.
  - rewrite Nat.div_add_l by lia. rewrite (Nat.div_small a 16 Ha). lia.
  - rewrite Nat.add_comm, Nat.mod_add by lia. apply Nat.mod_small, Ha.
Qed.
