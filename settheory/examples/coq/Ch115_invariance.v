(* 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——对称保真、
   双点不变证书、博雷尔包裹的 mod-I 同余（引理 3.23(3)/定理
   3.26-3.27 的机制核；本体留在正文 docs/115-invariance.md）。 *)
Require Import List Arith Lia Bool FunctionalExtensionality.
Import ListNotations.

(* ── 一、三点底集上的对换 τ ── *)
Definition tau (i : nat) : nat := if Nat.eqb i 0 then 1
                                  else if Nat.eqb i 1 then 0 else 2.

Lemma nat3_cases : forall i, i < 3 -> i = 0 \/ i = 1 \/ i = 2.
Proof. intros i hi; lia. Qed.

Lemma tau_tau : forall i, i < 3 -> tau (tau i) = i.
Proof.
  intros i hi.
  destruct (nat3_cases i hi) as [E | [E | E]]; subst i; reflexivity.
Qed.

(* ── 二、子集与布尔值模型 ──
   子集 = 点到 Bool 的函数；τ 的作用 (τ·b)(τ i) = b(i)。 *)
Definition subset := nat -> bool.

Definition tb (b : subset) : subset := fun i => b (tau i).
Definition cpl (b : subset) : subset := fun i => negb (b i).
Definition itr (a b : subset) : subset := fun i => andb (a i) (b i).
Definition uno (a b : subset) : subset := fun i => orb (a i) (b i).

(* 命题公式与布尔值。 *)
Inductive formula : Type :=
  | var : nat -> formula
  | neg : formula -> formula
  | conj : formula -> formula -> formula
  | disj : formula -> formula -> formula.

Fixpoint bval (f : formula) (v : nat -> subset) : subset :=
  match f with
  | var n => v n
  | neg g => cpl (bval g v)
  | conj g h => itr (bval g v) (bval h v)
  | disj g h => uno (bval g v) (bval h v)
  end.

Definition tv (v : nat -> subset) : nat -> subset := fun n => tb (v n).

(* ── 三、件 E：对称保真——布尔值与公式同步变换 ── *)
Lemma bval_perm : forall f v, bval f (tv v) = tb (bval f v).
Proof.
  induction f as [n | f IH | f IH1 h IH2 | f IH1 h IH2]; intros v.
  - reflexivity.
  - cbn [bval]. rewrite IH. apply functional_extensionality; intros i.
    unfold tb, cpl. destruct (bval f v (tau i)); reflexivity.
  - cbn [bval]. rewrite IH1, IH2. apply functional_extensionality; intros i.
    unfold tb, itr. destruct (bval f v (tau i)), (bval h v (tau i));
    reflexivity.
  - cbn [bval]. rewrite IH1, IH2. apply functional_extensionality; intros i.
    unfold tb, uno. destruct (bval f v (tau i)), (bval h v (tau i));
    reflexivity.
Qed.

(* ── 四、件 A：滤子共轭与双点不变证书 ── *)
Lemma F_conj : forall i b, i < 3 -> tb b (tau i) = b i.
Proof.
  intros i b hi. unfold tb. rewrite tau_tau by exact hi. reflexivity.
Qed.

(* 主超滤 F_i 的成员资格即「点 i 在集合中」。 *)
Definition memF (i : nat) (b : subset) : Prop := b i = true.

Theorem tau_inv_eval : forall f v,
  tb (bval f v) = bval f v ->
  (memF 0 (bval f v) <-> memF 1 (bval f v)).
Proof.
  intros f v hinv.
  assert (e1 : tb (bval f v) 1 = bval f v 0).
  { pose proof (F_conj 0 (bval f v) (ltac:(lia))) as h.
    unfold tau in h; simpl in h; exact h. }
  assert (e2 : tb (bval f v) 0 = bval f v 1).
  { pose proof (F_conj 1 (bval f v) (ltac:(lia))) as h.
    unfold tau in h; simpl in h; exact h. }
  unfold memF. split; intros h.
  - rewrite <- hinv in h. rewrite e2 in h. exact h.
  - rewrite <- hinv in h. rewrite e1 in h. exact h.
Qed.

(* 非不变布尔值在双点上翻车——不变性必须限定公式（边界反例）。 *)
Definition pt0 : subset := fun i => Nat.eqb i 0.

Lemma noninv_counter :
  pt0 0 = true /\ pt0 1 = false.
Proof. unfold pt0; simpl; split; reflexivity. Qed.

(* ── 五、件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制） ── *)
Definition odefP (k x : nat) : Prop :=
  x mod 8 = k mod 8 \/ x mod 8 = (k + 3) mod 8 \/ x mod 8 = (k + 5) mod 8.

Definition inS (x : nat) : Prop := x mod 2 = 0.
Definition inX (x : nat) : Prop := odefP 0 x.
Definition inA1 (x : nat) : Prop := inX x /\ inS x.

Theorem modI_eq : forall x, inS x -> (inX x <-> inA1 x).
Proof.
  intros x hx. split; intros h.
  - split; assumption.
  - destruct h; assumption.
Qed.

Theorem modI_ideal : forall x,
  (inX x /\ ~ inA1 x) \/ (~ inX x /\ inA1 x) -> ~ inS x.
Proof.
  intros x [h | h]; unfold inA1 in *.
  - destruct h as [hx hn]. intros hs. apply hn. split; assumption.
  - destruct h as [hx [hx' hs]]. intros _. exact (hx hx').
Qed.

(* 样本：星形 {0,3,5}（mod 8）的命中（与 Julia/Python 同账）。 *)
Example star_samples :
  inX 0 /\ inX 3 /\ inX 5 /\ ~ inX 1.
Proof.
  unfold inX, odefP.
  repeat split; simpl; lia.
Qed.
