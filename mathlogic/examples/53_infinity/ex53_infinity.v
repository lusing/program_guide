(* ex47 —— 无穷集合与停机问题（Jongsma ch5）
   Galileo —— n↦2n 是 nat 到偶数的双射（书例 5.1.1：真子集与全集等势）；
   pair_inj —— ℕ×ℕ ↪ ℕ：2^a·3^b 单射（书 §5.1.8 有理数可数的引理骨架；
              Schröder-Bernstein 书 Thm 5.1.1 也未证——如实记文档级）；
   cantor_prop/cantor_bool —— Cantor 对角线（书 Thm 5.2.1 的谓词版与
              位串版：nat 无法枚举全部谓词/全部布尔函数）；
   cantor_general —— |P(S)| > |S|（书 Thm 5.2.3）：任意类型 A 上
              无满射 A → (A → Prop)；
   russell —— Russell 悖论构造版（书 Thm 5.3.1）：参数化任意成员关系，
              说明它是纯 FOL 事实（书 §5.3.2 的观点）；
   no_halting —— 停机问题（书 §5.3.13，informal）：四条显式公理
              （判定器规范+对角程序存在）+ 矛盾 = 不可判定。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 1. Galileo：偶数与自然数等势（书例 5.1.1） ---------- *)

(* 单射：2x = 2y → x = y；满到偶数：偶 y 有原像 y/2 *)
Fixpoint halfE (y : nat) : nat :=
  match y with
  | 0 => 0
  | S 0 => 0
  | S (S y') => S (halfE y')
  end.

Lemma cancel_mul_l : forall p a b, p <> 0 -> p * a = p * b -> a = b.
Proof.
  intros p a b Hp H.
  exact (proj1 (Nat.mul_cancel_l a b p Hp) H).
Qed.

Lemma cancel_mul_r : forall p a b, p <> 0 -> a * p = b * p -> a = b.
Proof.
  intros p a b Hp H.
  exact (proj1 (Nat.mul_cancel_r a b p Hp) H).
Qed.

Definition isEven (n : nat) : Prop := exists k, n = 2 * k.

Lemma galileo_inj : forall x y, 2 * x = 2 * y -> x = y.
Proof.
  intros x y H.
  exact (cancel_mul_l 2 x y ltac:(lia) H).
Qed.

Lemma halfE_eq : forall k, halfE (2 * k) = k.
Proof.
  induction k as [|k IH].
  - reflexivity.
  - replace (2 * S k) with (S (S (2 * k))) by lia.
    simpl halfE. rewrite Nat.add_0_r.
    replace (k + k) with (2 * k) by lia.
    rewrite IH. reflexivity.
Qed.

Lemma galileo_surj : forall y, isEven y -> 2 * halfE y = y.
Proof.
  intros y [k Hk]. subst y.
  rewrite halfE_eq. reflexivity.
Qed.

(* 结论：存在 nat → 偶数的双射（书例 5.1.1 的机器化） *)
Theorem galileo : exists f : nat -> nat,
  (forall x y, f x = f y -> x = y) /\ (forall y, isEven y -> exists x, f x = y).
Proof.
  exists (fun n => 2 * n). split.
  - intros x y H. apply galileo_inj. assumption.
  - intros y Hy. exists (halfE y). apply galileo_surj. assumption.
Qed.

(* ---------- 2. ℕ×ℕ ↪ ℕ：2^a·3^b 单射 ---------- *)

Fixpoint pow (b e : nat) : nat :=
  match e with
  | 0 => 1
  | S e' => b * pow b e'
  end.

Lemma pow2_pos : forall e, 1 <= pow 2 e.
Proof. induction e as [|e IH]; simpl; lia. Qed.

Lemma pow3_pos : forall e, 1 <= pow 3 e.
Proof. induction e as [|e IH]; simpl; lia. Qed.

Lemma pow3_odd : forall e, exists o, pow 3 e = 2 * o + 1.
Proof.
  induction e as [|e [o Ho]].
  - exists 0. reflexivity.
  - simpl. exists (3 * o + 1). lia.
Qed.

Lemma pow2_even_pos : forall e, 1 <= e -> exists o, pow 2 e = 2 * o /\ 1 <= o.
Proof.
  intros e He. destruct e as [|e'].
  - lia.
  - simpl. exists (pow 2 e'). split; [reflexivity|apply pow2_pos].
Qed.

(* 奇偶守恒：2^a·3^b = 2^c·3^d → a = c *)
(* 最干净的路线：显式构造 2 的幂差，完全绕开减法 *)
Lemma pow2_add : forall x y, pow 2 (x + y) = pow 2 x * pow 2 y.
Proof.
  induction x as [|x IH]; intros y.
  - simpl. lia.
  - replace (S x + y) with (S (x + y)) by lia.
    cbn [pow]. rewrite IH. ring.
Qed.

Lemma pow3_add : forall x y, pow 3 (x + y) = pow 3 x * pow 3 y.
Proof.
  induction x as [|x IH]; intros y.
  - simpl. lia.
  - replace (S x + y) with (S (x + y)) by lia.
    cbn [pow]. rewrite IH. ring.
Qed.

Lemma pow2_inj : forall x y, pow 2 x = pow 2 y -> x = y.
Proof.
  intros x y H.
  assert (Hp : 1 <= pow 2 x) by apply pow2_pos.
  assert (Hp' : 1 <= pow 2 y) by apply pow2_pos.
  destruct (lt_eq_lt_dec x y) as [[Hlt|Heq]|Hgt].
  - exfalso.
    assert (Hd : exists j, y = x + S j) by (exists (y - x - 1); lia).
    destruct Hd as [j Hj]. subst y.
    rewrite pow2_add in H.
    simpl (pow 2 (S j)) in H.
    (* pow 2 x = pow 2 x * (2 * pow 2 j)，两侧消去 pow 2 x *)
    assert (Hc : 1 = 2 * pow 2 j).
    { apply (cancel_mul_l (pow 2 x)); [lia|].
      rewrite Nat.mul_1_r. assumption. }
    lia.
  - assumption.
  - exfalso.
    assert (Hd : exists j, x = y + S j) by (exists (x - y - 1); lia).
    destruct Hd as [j Hj]. subst x.
    rewrite pow2_add in H.
    simpl (pow 2 (S j)) in H.
    assert (Hc : 2 * pow 2 j = 1).
    { apply (cancel_mul_l (pow 2 y)); [lia|].
      rewrite Nat.mul_1_r. assumption. }
    lia.
Qed.

Lemma pow3_inj : forall x y, pow 3 x = pow 3 y -> x = y.
Proof.
  intros x y H.
  assert (Hp : 1 <= pow 3 x) by apply pow3_pos.
  assert (Hp' : 1 <= pow 3 y) by apply pow3_pos.
  destruct (lt_eq_lt_dec x y) as [[Hlt|Heq]|Hgt].
  - exfalso.
    assert (Hd : exists j, y = x + S j) by (exists (y - x - 1); lia).
    destruct Hd as [j Hj]. subst y.
    rewrite pow3_add in H.
    simpl (pow 3 (S j)) in H.
    destruct (pow3_odd j) as [o Ho].
    rewrite Ho in H.
    (* pow 3 x = pow 3 x * (3 * (2*o+1))，消去后 3*(2o+1) = 1 荒谬 *)
    assert (Hc : 1 = 3 * (2 * o + 1)).
    { apply (cancel_mul_l (pow 3 x)); [lia|].
      rewrite Nat.mul_1_r. assumption. }
    lia.
  - assumption.
  - exfalso.
    assert (Hd : exists j, x = y + S j) by (exists (x - y - 1); lia).
    destruct Hd as [j Hj]. subst x.
    rewrite pow3_add in H.
    simpl (pow 3 (S j)) in H.
    destruct (pow3_odd j) as [o Ho].
    rewrite Ho in H.
    assert (Hc : 3 * (2 * o + 1) = 1).
    { apply (cancel_mul_l (pow 3 y)); [lia|].
      rewrite Nat.mul_1_r. assumption. }
    lia.
Qed.

Theorem pair_inj : forall a b c d,
  pow 2 a * pow 3 b = pow 2 c * pow 3 d -> a = c /\ b = d.
Proof.
  intros a b c d H.
  assert (Hac : a = c).
  { assert (Hpa : 1 <= pow 2 a) by apply pow2_pos.
    assert (Hpc : 1 <= pow 2 c) by apply pow2_pos.
    destruct (lt_eq_lt_dec a c) as [[Hlt|Heq]|Hgt]; [ | assumption | ].
    - exfalso.
      assert (Hd : exists j, c = a + S j) by (exists (c - a - 1); lia).
      destruct Hd as [j Hj]. subst c.
      rewrite pow2_add in H.
      cbn [pow] in H.
      destruct (pow3_odd b) as [o1 Ho1].
      destruct (pow3_odd d) as [o2 Ho2].
      rewrite Ho1, Ho2 in H.
      (* 消去 pow 2 a：左边奇，右边偶 *)
      assert (Hc : 2 * o1 + 1 = (2 * pow 2 j) * (2 * o2 + 1)).
      { apply (cancel_mul_l (pow 2 a)); [intro Hz; lia|].
        replace (pow 2 a * (2 * pow 2 j * (2 * o2 + 1)))
          with (pow 2 a * (2 * pow 2 j) * (2 * o2 + 1)) in * by ring.
        exact H. }
      assert (Hr : (2 * pow 2 j) * (2 * o2 + 1) = 2 * (pow 2 j * (2 * o2 + 1)))
        by ring.
      lia.
    - exfalso.
      assert (Hd : exists j, a = c + S j) by (exists (a - c - 1); lia).
      destruct Hd as [j Hj]. subst a.
      rewrite pow2_add in H.
      cbn [pow] in H.
      destruct (pow3_odd b) as [o1 Ho1].
      destruct (pow3_odd d) as [o2 Ho2].
      rewrite Ho1, Ho2 in H.
      assert (Hc : (2 * pow 2 j) * (2 * o1 + 1) = 2 * o2 + 1).
      { apply (cancel_mul_l (pow 2 c)); [intro Hz; lia|].
        replace (pow 2 c * (2 * pow 2 j * (2 * o1 + 1)))
          with (pow 2 c * (2 * pow 2 j) * (2 * o1 + 1)) in * by ring.
        exact H. }
      assert (Hr : (2 * pow 2 j) * (2 * o1 + 1) = 2 * (pow 2 j * (2 * o1 + 1)))
        by ring.
      lia. }
  subst c.
  assert (Hc : pow 3 b = pow 3 d).
  { apply (cancel_mul_l (pow 2 a)); [intro Hz; assert (Hpp := pow2_pos a); lia|assumption]. }
  split; [reflexivity|].
  apply pow3_inj. assumption.
Qed.

(* ---------- 3. Cantor 对角线（书 Thm 5.2.1 的两个化身） ---------- *)

(* 谓词版：nat 无法枚举 nat 的全部谓词 *)
Theorem cantor_prop : ~ exists (e : nat -> nat -> Prop),
  forall P, exists n, forall x, e n x <-> P x.
Proof.
  intros [e H].
  destruct (H (fun x => ~ e x x)) as [n Hn].
  specialize (Hn n).
  tauto.
Qed.

(* 位串版：nat 无法枚举 nat -> bool 的全部函数（点态陈述避开 funext） *)
Theorem cantor_bool : ~ exists (e : nat -> nat -> bool),
  forall g, exists n, forall x, e n x = g x.
Proof.
  intros [e H].
  destruct (H (fun x => negb (e x x))) as [n Hn].
  specialize (Hn n).
  simpl in Hn.
  destruct (e n n) eqn:E; simpl in Hn; discriminate.
Qed.

(* ---------- 4. 一般 Cantor：|P(S)| > |S|（书 Thm 5.2.3） ---------- *)

Theorem cantor_general : forall (A : Type) (F : A -> A -> Prop),
  ~ (forall P : A -> Prop, exists a, forall x, F a x <-> P x).
Proof.
  intros A F H.
  destruct (H (fun x => ~ F x x)) as [a Ha].
  specialize (Ha a).
  tauto.
Qed.

(* ---------- 5. Russell 悖论构造版（书 Thm 5.3.1） ---------- *)

(* 参数化任意「成员」关系：结论是纯 FOL 事实，与集合论无关 *)
Theorem russell : forall (A : Type) (R : A -> A -> Prop),
  ~ exists N, forall x, R x N <-> ~ R x x.
Proof.
  intros A R [N H].
  specialize (H N).
  tauto.
Qed.

(* ---------- 6. 停机问题（书 §5.3.13） ---------- *)

(* 书的论证是 informal 的：「程序」与「编码」未形式化。
   机器版把两个构造作为显式公理记账（规范式陈述）：
   - H 是全停机判定器（对任何程序 p、输入 i，H p i 正确报告停机与否）；
   - D 是由 H 构造出的对角程序（i 上停机 ⟺ H 报告 i 在 i 上不停）。
   定理：这组假设不相容——不存在这样的判定器。 *)

Axiom prog : Type.
Axiom halts_on : prog -> prog -> Prop.
Axiom H : prog -> prog -> bool.
Axiom H_sound_true : forall p i, H p i = true -> halts_on p i.
Axiom H_sound_false : forall p i, H p i = false -> ~ halts_on p i.
Axiom D : prog.
Axiom D_spec : forall i, halts_on D i <-> (H i i = false).

Theorem no_halting_checker : False.
Proof.
  destruct (H D D) eqn:Eq.
  - (* H 报告 D 停 → D 确实停 → 由 D_spec，H D D = false —— 与 Eq 矛盾 *)
    assert (Ht : halts_on D D) by (apply H_sound_true; assumption).
    apply D_spec in Ht.
    rewrite Eq in Ht. discriminate.
  - (* H 报告 D 不停 → D 确实不停；但 D_spec 反向给出 D 停 —— 矛盾 *)
    assert (Hf : ~ halts_on D D) by (apply H_sound_false; assumption).
    assert (Hd : halts_on D D) by (apply D_spec; assumption).
    apply Hf. assumption.
Qed.

(* ---------- 7. 冒烟与账本 ---------- *)

Compute (pow 2 3 * pow 3 2).   (* 2^3·3^2 = 72 *)
Compute (pow 2 5 * pow 3 0).   (* 32 *)

Print Assumptions galileo.
Print Assumptions pair_inj.
Print Assumptions cantor_prop.
Print Assumptions cantor_bool.
Print Assumptions cantor_general.
Print Assumptions russell.
Print Assumptions no_halting_checker.
