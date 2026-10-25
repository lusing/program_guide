(* 第 92 章 · 布尔值模型（冯琦第二卷 §3.5）。
   四件样品：幂集代数 2^2 的 Ba1-Ba6 机器面；布尔值算法与基本布尔值
   不等式（定理 3.23 的 (1)(2)，点态陈述避开函子外延）；逻辑公理的
   布尔值为 1（引理 3.70 影子）；柱超滤子上的 Łoś 换算（引理 3.72 原子）
   与 V^B 有限两层的度量账（定义 3.56 + 引理 3.75(1) 的最小影子）。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

(* ---------- 一、幂集代数 B = 2^2（定义 3.38 的机器面） ---------- *)

Definition B4 : Type := (bool * bool)%type.

Definition bjoin (a b : B4) : B4 := (orb (fst a) (fst b), orb (snd a) (snd b)).
Definition bmeet (a b : B4) : B4 := (andb (fst a) (fst b), andb (snd a) (snd b)).
Definition bcompl (a : B4) : B4 := (negb (fst a), negb (snd a)).
Definition btop : B4 := (true, true).
Definition bbot : B4 := (false, false).
Definition bimp (a b : B4) : B4 := bjoin (bcompl a) b.

(* Ba5 互补律：a 与 ¬a 的交是 0、并是 1 *)
Lemma ba5_meet : forall a : B4, bmeet a (bcompl a) = bbot.
Proof. intros [x y]; unfold bmeet, bcompl, bbot.
  destruct x, y; reflexivity. Qed.

Lemma ba5_join : forall a : B4, bjoin a (bcompl a) = btop.
Proof. intros [x y]; unfold bjoin, bcompl, btop.
  destruct x, y; reflexivity. Qed.

(* Ba1 交换律与 Ba2 结合律抽查 *)
Lemma ba1_join_comm : forall a b : B4, bjoin a b = bjoin b a.
Proof. intros [x1 y1] [x2 y2]; unfold bjoin.
  destruct x1, y1, x2, y2; reflexivity. Qed.

Lemma ba2_meet_assoc : forall a b c : B4,
  bmeet a (bmeet b c) = bmeet (bmeet a b) c.
Proof. intros [x1 y1] [x2 y2] [x3 y3]; unfold bmeet.
  destruct x1, y1, x2, y2, x3, y3; reflexivity. Qed.

(* ---------- 二、布尔值算法与基本布尔值不等式（定义 3.51 / 定理 3.23） ---------- *)

Inductive Fm : Type :=
| TT : Fm | FF : Fm
| Atom : Fm
| Not : Fm -> Fm
| And : Fm -> Fm -> Fm
| Or : Fm -> Fm -> Fm
| Imp : Fm -> Fm -> Fm
| Iff : Fm -> Fm -> Fm.

Fixpoint bval (f : Fm) (v : B4) : B4 :=
  match f with
  | TT => btop
  | FF => bbot
  | Atom => v
  | Not g => bcompl (bval g v)
  | And g h => bmeet (bval g v) (bval h v)
  | Or g h => bjoin (bval g v) (bval h v)
  | Imp g h => bimp (bval g v) (bval h v)
  | Iff g h => bmeet (bimp (bval g v) (bval h v)) (bimp (bval h v) (bval g v))
  end.

(* 定理 3.23(1) 的点态形态：⟦φ⟧ ∧ ⟦¬φ⟧ 每坐标为 false *)
Lemma bval_not_self : forall (f : Fm) (v : B4) (c : bool),
  match c with
  | true => fst (bmeet (bval f v) (bval (Not f) v)) = false
  | false => snd (bmeet (bval f v) (bval (Not f) v)) = false
  end.
Proof.
  intros f v c.
  assert (key : forall b : bool, andb b (negb b) = false).
  { intros []; reflexivity. }
  induction f; simpl in *;
    repeat match goal with
    | [ |- context[match ?x with true => _ | false => _ end] ] =>
        destruct x
    end; try reflexivity; try apply key; simpl; try reflexivity.
Qed.

(* 定理 3.23(2) 的点态形态：⟦φ⟧ 与 ⟦¬φ⟧ 必有一侧含住第一坐标的 1，
   即任何条件都被判定到一侧 *)
Lemma bval_decides : forall (f : Fm) (v : B4),
  (fst (bval f v) = true) \/ (fst (bcompl (bval f v)) = true).
Proof.
  intros f v.
  destruct (bval f v) as [x y] eqn:E.
  destruct x eqn:Ex.
  - left; reflexivity.
  - right; reflexivity.
Qed.

(* ---------- 三、逻辑公理的布尔值为 1（引理 3.70 影子） ---------- *)

(* 同一律 φ -> φ 的布尔值为 1 *)
Lemma bval_identity : forall (f : Fm) (v : B4), bimp (bval f v) (bval f v) = btop.
Proof.
  intros f v. unfold bimp.
  rewrite (ba1_join_comm (bcompl (bval f v)) (bval f v)), ba5_join.
  reflexivity.
Qed.

(* ---------- 四、柱超滤子上的 Łoś 换算（引理 3.71/3.72 的原子） ---------- *)

Definition U0 (a : B4) : Prop := fst a = true.

Lemma U0_meet : forall a b : B4, U0 (bmeet a b) <-> U0 a /\ U0 b.
Proof.
  intros a b. unfold U0, bmeet. simpl fst. simpl snd.
  split.
  - intro H. apply andb_true_iff in H. exact H.
  - intros [H1 H2]. rewrite H1, H2. reflexivity.
Qed.

Lemma U0_compl : forall a : B4, U0 (bcompl a) <-> ~ U0 a.
Proof. intros [x y]; unfold U0, bcompl; simpl.
  split; intros H.
  - intros Hc; rewrite Hc in H; simpl in H; discriminate.
  - destruct x; [contradiction (H eq_refl) | reflexivity].
Qed.

Lemma U0_imp : forall a b : B4, U0 a -> (U0 (bimp a b) <-> U0 b).
Proof.
  intros [x1 y1] [x2 y2] H.
  unfold U0, bimp, bjoin, bcompl in *. simpl fst. simpl snd.
  destruct x1.
  - split.
    + intros H2. destruct x2; [exact H2 | discriminate H2].
    + intros Hc. destruct x2; [reflexivity | discriminate Hc].
  - discriminate H.
Qed.

(* ---------- V^B 有限两层的度量账（定义 3.56 + 引理 3.75(1) 影子） ---------- *)

(* 一层名字：原子坐标上的 B 值函数（dom = 出现的坐标）。
   原子层的相等与隶属：⟦x = y⟧ = 1（V_0 只有空集），⟦x ∈ σ⟧ = σ(x)。 *)
Definition name1 (assign : nat -> B4) : nat -> B4 := assign.

Definition mem1 (x : nat) (s : nat -> B4) : B4 := s x.

(* 检查名账（引理 3.79 原子形态）：对有限 dom 的名字，
   ⟦∀t(t ∈ a -> t ∈ b)⟧ 的单步账为逐坐标 ⊑ *)
Definition sub1 (a b : nat -> B4) : B4 :=
  bmeet (bimp (a 0) (b 0)) (bimp (a 1) (b 1)).

(* 泛型名字的最小影子（定义 3.58 / 引理 3.75(1)）：
   Ġ = 对角赋值，⟦ǔ ∈ Ġ⟧ = u——按定义逐坐标计算即得 *)
Definition gen_diag (u : B4) : nat -> B4 := fun _ => u.

(* ---------- 演示 ---------- *)

Definition p0 : B4 := (true, false).

Compute (bmeet p0 (bcompl p0), bjoin p0 (bcompl p0)).
(* Ba5：(false,false), (true,true) *)

Compute (bval (Iff (Not Atom) (Not Atom)) p0).
(* 引理 3.70：重言式的值为 1 = (true,true) *)

Compute (bval (Imp (And Atom (Not Atom)) FF) p0).
(* 矛盾推出任何结论：值为 (true,true)——爆炸律的布尔值为 1 *)

(* ⟦ǔ ∈ Ġ⟧ = u 的账：对角名字在第 u 坐标的隶属值恰为 u *)
Compute (mem1 0 (gen_diag p0)).
(* = (true,false) = p0：引理 3.75(1) 的最小影子 *)

Compute (sub1 (gen_diag p0) (gen_diag btop)).
(* = (true,true)：ǔ ⊆ 1 的值为 1 *)
