(* 第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）。
   三件样品：层次单调性（引理 2.1(1)）、有限载体全可定义引擎
   （引理 2.1(3) 的 L_n = V_n）、深度受限可定义 < 幂集的对角线
   （L_{ω+1} ⊊ V_{ω+1} 的有限影子）。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

(* ---------- 一、可构造层次的单调性（引理 2.1(1)） ---------- *)

Section Hierarchy.
Variable A : Type.
Variable D : (A -> Prop) -> A -> Prop.
(* 引理 1.15(1)：M ⊆ 𝒟(M)。 *)
Hypothesis hexp : forall s x, s x -> D s x.

(* 定义 2.1 的有限影子：L_0 = ∅，L_{n+1} = 𝒟(L_n)。 *)
Fixpoint Lh (n : nat) : A -> Prop :=
  match n with
  | 0 => fun _ => False
  | S k => D (Lh k)
  end.

(* 引理 2.1(1)：扩张性单独保证层次单调（归纳在大端 n 上）。 *)
Lemma Lh_mono : forall n m, m <= n -> forall x, Lh m x -> Lh n x.
Proof.
  induction n as [|n IH]; intros m hle x hx.
  - assert (m = 0) by lia. subst m. exact hx.
  - destruct (Nat.eq_dec m (S n)) as [heq|hne].
    + subst m. exact hx.
    + assert (hm : m <= n) by lia.
      exact (hexp (Lh n) x (IH m hm x hx)).
Qed.
End Hierarchy.

(* ---------- 二、有限载体上的可定义性引擎（L_n = V_n） ---------- *)

(* 单自由变元、参数内嵌的公式：布尔骨架 + 等式原子 + 属于原子。 *)
Inductive Fm (A : Type) : Type :=
| ftt : Fm A
| fff : Fm A
| feq : A -> Fm A
| fmem : A -> Fm A
| fneg : Fm A -> Fm A
| for_ : Fm A -> Fm A -> Fm A.

Arguments ftt {A}.
Arguments fff {A}.
Arguments feq {A} _.
Arguments fmem {A} _.
Arguments fneg {A} _.
Arguments for_ {A} _ _.

(* 布尔语义：filter 直接给出可定义子集（ext）。 *)
Fixpoint satb {A} (eqb_ mem : A -> A -> bool) (p : Fm A) (x : A) : bool :=
  match p with
  | ftt => true
  | fff => false
  | feq q => eqb_ x q
  | fmem q => mem x q
  | fneg q => negb (satb eqb_ mem q x)
  | for_ q r => satb eqb_ mem q x || satb eqb_ mem r x
  end.

Definition ext {A} (eqb_ mem : A -> A -> bool) (L : list A) (p : Fm A)
  : list A := filter (satb eqb_ mem p) L.

(* 析取式：由参数表生成 x = a1 ∨ ... ∨ x = ak。 *)
Fixpoint disj {A} (l : list A) : Fm A :=
  match l with
  | [] => fff
  | a :: l' => for_ (feq a) (disj l')
  end.

Lemma satb_disj : forall (A : Type) (eqb_ mem : A -> A -> bool),
  (forall x y, eqb_ x y = true <-> x = y) ->
  (forall x, eqb_ x x = true) ->
  forall l x, satb eqb_ mem (disj l) x = true <-> In x l.
Proof.
  intros A eqb_ mem Hiff Hrefl l x.
  induction l as [|a l IH]; simpl.
  - split.
    + intros H; discriminate H.
    + intros H; destruct H.
  - split.
    + intros H. apply orb_true_iff in H as [H|H].
      * left. symmetry. exact (proj1 (Hiff x a) H).
      * right. exact (proj1 IH H).
    + intros [H|H].
      * subst x. rewrite Hrefl. reflexivity.
      * apply orb_true_iff. right. exact (proj2 IH H).
Qed.

(* 引理 2.1(3) 的引擎：有限载体的每个子表由一个带参数公式定义。
   这就是 L_n = V_n 的归纳步骤；ω+1 层的分歧见第三部分的对角线。 *)
Theorem finite_definable : forall (A : Type) (eqb_ mem : A -> A -> bool),
  (forall x y, eqb_ x y = true <-> x = y) ->
  (forall x, eqb_ x x = true) ->
  forall (B : list A), exists p, forall x, satb eqb_ mem p x = true <-> In x B.
Proof.
  intros A eqb_ mem Hiff Hrefl B.
  exists (disj B).
  apply satb_disj; assumption.
Qed.

(* ---------- 三、深度受限可定义 < 幂集：对角线（L_{ω+1} ⊊ V_{ω+1} 的影子） ---------- *)

(* 深度不超过 1、参数取自 0..3 的公式全体：
   原子（真/假/等式/属于）+ 原子否定 + 原子析取。 *)
Definition L4 : list nat := 0 :: 1 :: 2 :: 3 :: nil.
Definition memF : nat -> nat -> bool := fun x p => Nat.eqb (x * p) 3.

Definition atoms : list (Fm nat) :=
  ftt :: fff :: map feq L4 ++ map fmem L4.
Definition ors (l1 l2 : list (Fm nat)) : list (Fm nat) :=
  flat_map (fun p => map (fun q => for_ p q) l2) l1.
Definition Fs : list (Fm nat) :=
  atoms ++ map fneg atoms ++ ors atoms atoms.

(* 对角线集合：第 k 个位置上的元素 x 恰好躲开第 k 个公式的扩张。 *)
Definition D : list nat :=
  filter (fun x => negb (satb Nat.eqb memF (nth x Fs fff) x)) L4.

(* 有限世界的对角线定理：D 不等于任何被枚举公式的扩张。
   证明是纯逻辑：无论第 j 个公式在 j 处取真还是取假，
   D = ext(F_j) 都在 j 处自相矛盾——这是「公式可数、子集不可数」
   在有限尺度上的全部内容（塔尔斯基对角线的影子）。 *)
Theorem diagonal : forall j, In j L4 -> D <> ext Nat.eqb memF L4 (nth j Fs fff).
Proof.
  intros j Hj Heq.
  unfold D, ext in Heq.
  remember (satb Nat.eqb memF (nth j Fs fff) j) as b eqn:Hb.
  destruct b.
  - (* 公式在 j 处为真：j ∈ ext(F_j)，经 Heq 得 j ∈ D，即公式在 j 处为假 *)
    assert (Hin : In j (filter (satb Nat.eqb memF (nth j Fs fff)) L4)).
    { rewrite filter_In. split; [exact Hj | symmetry; exact Hb]. }
    rewrite <- Heq in Hin.
    apply filter_In in Hin as [_ Hnb].
    rewrite <- Hb in Hnb. simpl in Hnb. discriminate Hnb.
  - (* 公式在 j 处为假：j ∈ D，经 Heq 得 j ∈ ext(F_j)，即公式在 j 处为真 *)
    assert (Hin : In j (filter (fun x => negb (satb Nat.eqb memF (nth x Fs fff) x)) L4)).
    { rewrite filter_In. split; [exact Hj|]. rewrite <- Hb. reflexivity. }
    rewrite Heq in Hin.
    apply filter_In in Hin as [_ Hb2].
    rewrite <- Hb in Hb2. discriminate Hb2.
Qed.

(* 公式族规模：深度 ≤ 1 只有 120 个公式；4 元载体的子集共 16 个。
   深度放开后有限载体上终会覆盖全部子集（第二部分），
   但在无穷载体上「公式可数 vs 子集不可数」的缺口永远补不上——
   这正是 L_{ω+1} ⊊ V_{ω+1}、进而 GCH 在 L 中成立的组合根源。 *)
Compute length Fs.
Compute D.
Compute map (fun j => ext Nat.eqb memF L4 (nth j Fs fff)) L4.
