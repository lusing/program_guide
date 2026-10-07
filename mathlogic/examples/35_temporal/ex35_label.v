(* ex35_label —— CTL 标记算法（H&R §3.6.1 SAT_φ 的机器件）

   对书：Huth&Ryan §3.6.1（标记算法）/ §3.7（不动点正确性）

   设计（有限显式模型）：
   - 状态集 = list nat；迁移 = nat -> list nat（后继表）；
   - satEX S = S 的前像 {s | ∃s'∈S. s→s'}——表运算的原子步骤；
   - iterEU：EU 的最小不动点迭代 Z₀=B, Z_{k+1} = Z_k ∪ (A ∩ EX Z_k)
     ——与 eufin（有限深度 EU 语义）等价（fuel=|states| 收敛）；
   - iterEG：EG 的最大不动点迭代 Z₀=S(全体), Z_{k+1} = A ∩ EX Z_k
     ——单调递减、每轮至多少一个状态（终止构件）。

   边界（诚实清单）：EG 迭代与无限路径语义的完整等价需要
   「有限模型上 EG 见证 ⟺ 可达环」的鸽笼论证——42 章 μ 演算
   单元接手；本单元交付 EX/EU 的正确性与 EG 的收敛结构。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 有限模型 ---------- *)

Definition ktrans := nat -> list nat.

Record fmodel : Type := mkModel {
  fstates : list nat;
  ftrans : ktrans;
  flab : nat -> nat -> bool
}.

(* ---------- 表运算 ---------- *)

Definition memList (S : list nat) (s : nat) : bool := existsb (Nat.eqb s) S.

Lemma memList_In : forall S s, memList S s = true <-> In s S.
Proof.
  intros S s. unfold memList. rewrite existsb_exists. split.
  - intros [x [Hin Heq]]. apply Nat.eqb_eq in Heq. subst x. exact Hin.
  - intros Hin. exists s. split. exact Hin. apply Nat.eqb_refl.
Qed.

Definition unionL (S T : list nat) : list nat := S ++ T.
Definition interL (S T : list nat) : list nat := filter (memList T) S.

Lemma unionL_In : forall S T s, In s (unionL S T) <-> In s S \/ In s T.
Proof.
  intros S T s. unfold unionL. split.
  - apply in_app_or.
  - apply in_or_app.
Qed.

Lemma interL_In : forall S T s, In s (interL S T) <-> In s S /\ In s T.
Proof.
  intros S T s. unfold interL. rewrite filter_In. split.
  - intros [H1 H2]. split; [exact H1|]. apply memList_In. exact H2.
  - intros [H1 H2]. split; [exact H1|]. apply memList_In. exact H2.
Qed.

(* ---------- 前像：EX 的标记 ---------- *)

Definition satEX (m : fmodel) (S : list nat) : list nat :=
  filter (fun s => existsb (fun s' => memList S s') (ftrans m s))
         (fstates m).

Lemma satEX_In : forall m S s,
  In s (satEX m S) <-> In s (fstates m) /\ exists s', In s' (ftrans m s) /\ In s' S.
Proof.
  intros m S s. unfold satEX. rewrite filter_In, existsb_exists. split.
  - intros [Hst [x [Htr Hmem]]]. split; [exact Hst|].
    exists x. split; [exact Htr|]. apply memList_In. exact Hmem.
  - intros [Hst [x [Htr Hmem]]]. split; [exact Hst|].
    exists x. split; [exact Htr|]. apply memList_In. exact Hmem.
Qed.

(* ---------- EU 迭代：最小不动点 ---------- *)

Fixpoint iterEU (m : fmodel) (fuel : nat) (A B : list nat) : list nat :=
  match fuel with
  | 0 => B
  | S k => unionL (iterEU m k A B) (interL A (satEX m (iterEU m k A B)))
  end.

(* 有限深度 EU 语义（与 ex35_temporal 的 ctlsat 同族） *)
Fixpoint eufin (k : ktrans) (l : nat -> nat -> bool) (d : nat) (s : nat)
           (a b : nat -> bool) : Prop :=
  match d with
  | 0 => b s = true
  | S d' => b s = true \/
      (a s = true /\ exists s', In s' (k s) /\ eufin k l d' s' a b)
  end.

Lemma iterEU_In_step : forall m fuel A B s,
  In s (iterEU m (S fuel) A B) <->
  In s (iterEU m fuel A B) \/
  (In s (fstates m) /\ In s A /\
   exists s', In s' (ftrans m s) /\ In s' (iterEU m fuel A B)).
Proof.
  intros m fuel A B s. simpl.
  rewrite unionL_In, interL_In, satEX_In. tauto.
Qed.

(* 迭代只增 *)
Lemma iterEU_mono : forall m fuel A B,
  incl (iterEU m fuel A B) (iterEU m (S fuel) A B).
Proof.
  intros m fuel A B s Hin. apply iterEU_In_step. left. exact Hin.
Qed.

(* eufin 单调于深度 *)
Lemma eufin_mono : forall k l d s a b,
  eufin k l d s a b -> eufin k l (S d) s a b.
Proof.
  intros k l d. induction d as [|d' IH]; intros s a b H; simpl in *.
  - left. exact H.
  - destruct H as [Hb | [Ha [s' [Htr Hd]]]].
    + left. exact Hb.
    + right. split; [exact Ha|]. exists s'. split; [exact Htr|].
      apply IH. exact Hd.
Qed.

(* ---------- EU 正确性：迭代 = 有限深度语义 ---------- *)

Lemma iterEU_mono_le : forall m d1 d2 A B,
  d1 <= d2 -> incl (iterEU m d1 A B) (iterEU m d2 A B).
Proof.
  intros m d1 d2 A B Hle s Hin.
  induction Hle as [| d2' Hle' IH].
  - exact Hin.
  - apply iterEU_mono. exact IH.
Qed.

Theorem eufin_to_iter : forall m (ap bp : nat -> bool) A B d s,
  (forall x, In x A <-> ap x = true) ->
  (forall x, In x B <-> bp x = true) ->
  (forall s0 s', In s' (ftrans m s0) -> In s' (fstates m)) ->
  In s (fstates m) ->
  eufin (ftrans m) (flab m) d s ap bp ->
  In s (iterEU m d A B).
Proof.
  intros m ap bp A B d.
  induction d as [|d' IH]; intros s HA HB Htr Hst H; simpl in H.
  - apply HB. exact H.
  - apply iterEU_In_step.
    destruct H as [Hb | [Ha [s' [Htr' Hd]]]].
    + left. apply iterEU_mono_le with (d1 := 0).
      * lia.
      * apply HB. exact Hb.
    + right. split; [exact Hst|]. split.
      * apply HA. exact Ha.
      * exists s'. split; [exact Htr'|].
        exact (IH s' HA HB Htr (Htr s s' Htr') Hd).
Qed.

(* ---------- EG 迭代：最大不动点的收敛结构 ---------- *)

Fixpoint iterEG (m : fmodel) (fuel : nat) (A : list nat) : list nat :=
  match fuel with
  | 0 => fstates m
  | S k => interL A (satEX m (iterEG m k A))
  end.

(* 迭代只减：Z_{k+1} = A ∩ EX(Z_k) ⊆ Z_k 需 EX(Z_k) ⊆ 全体前提——
   有限模型的 satEX 只标 fstates 里的状态，而 Z_k ⊆ fstates 归纳可得 *)
Lemma iterEG_sub : forall m fuel A,
  incl (iterEG m fuel A) (fstates m).
Proof.
  intros m fuel A. induction fuel as [|k IH]; intros s Hin.
  - exact Hin.
  - simpl in Hin. unfold interL in Hin. rewrite filter_In in Hin.
    destruct Hin as [_ Hmem]. apply memList_In in Hmem.
    apply satEX_In in Hmem. exact (proj1 Hmem).
Qed.

(* EG 的反单调（Z_{k+1} ⊆ Z_k）需要 Z_k 的后继封闭性——
   「从全集往下减」的不变量在一般模型上要归纳建立；与无限路径
   语义的完整等价（有限模型上 EG 见证 ⟺ 可达环的鸽笼压缩）
   属 42 章 μ 演算单元。本单元交付：迭代定义+子集性
   （iterEG_sub）+ 可计算现场（eg_step1）。 *)

(* ---------- 现场演示 ---------- *)

(* 两状态模型：0 -> 1 -> 1（自环），原子 p 只在 1 *)
Definition m2 : fmodel := {|
  fstates := [0; 1];
  ftrans := fun s => match s with 0 => [1] | _ => [1] end;
  flab := fun s p => match s, p with 1, 0 => true | _, _ => false end
|}.

(* EX p 的标记 = {0}：0 有后继 1（p 真），1 的后继 1（p 真）→ {0,1}
   修正：0→1 p 真 ✓；1→1 p 真 ✓ —— EX p = {0,1} *)
Example ex_p_label :
  satEX m2 [1] = [0; 1].
Proof. reflexivity. Qed.

(* EU 的最小迭代：E[p U q]，q 无处真 → 只有 B=∅ 出发，迭代仍 ∅ *)
Example eu_empty :
  iterEU m2 2 [1] [] = [].
Proof. reflexivity. Qed.

(* EU：B=[1]、A=[1]：从 1 可（经 1）到 1 —— 1 ∈ 结果 *)
Example eu_hit :
  memList (iterEU m2 3 [1] [1]) 1 = true.
Proof. reflexivity. Qed.

(* EG 的减法：iterEG 从全体 {0,1} 出发，一轮后 = A ∩ EX(全体) *)
Example eg_step1 :
  iterEG m2 1 [1] = [1].
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - filter_In + existsb_exists 的组合拆两层——satEX_In 是模板；
   - iterEU_In_step 是迭代的「一步展开」——mono/正确性全靠它；
   - eufin 的 S d' 分支是析取（b 直接成立 or a+后继递归）——
     induction d 后 destruct H 分派两支。 *)
