(* ex38_ctlstar —— CTL* 与 LTL/CTL 表达能力对照（H&R §3.5）

   对书：Huth&Ryan §3.5（两层语法/图 3.23 四角/反例分离）+ §3.5.1

   设计：
   - 两层语法：sform（状态公式）与 pform（路径公式）**互嵌归纳**——
     CTL* 的定义性特征；CTL 是路径公式被限成单算子形态的片段；
   - 语义沿 36 章 lsat 的「路径=位置函数」配方；A/E 量化模型路径；
   - 机器交付三组**分离现场**（具体模型上真值计算）：
     (a) AG EF p（图 3.23 ①，CTL 有 LTL 无）：M ⊨ / M' ⊭ 两模型对照；
     (b) E[G F p]（④，CTL* 独有）：M ⊨ / M' ⊭；
     (c) F G p ⊭ AF AG p（Remark 3.18）：自环模型双向。
   「不可表达」本身是元论证（路径子集/Emerson），文档交代边界；
   机器面 = 分离公式在分离模型上的具体真值 + 路径分类引理。 *)

From Stdlib Require Import List Bool Arith Lia Classical.
Import ListNotations.

(* ---------- 两层语法（互嵌归纳） ---------- *)

Inductive sform : Type :=
| sAtom : nat -> sform
| sNeg  : sform -> sform
| sAnd  : sform -> sform -> sform
| sA    : pform -> sform
| sE    : pform -> sform

with pform : Type :=
| pState : sform -> pform
| pNeg   : pform -> pform
| pAnd   : pform -> pform -> pform
| pX     : pform -> pform
| pG     : pform -> pform
| pF     : pform -> pform
| pU     : pform -> pform -> pform.

(* ---------- 模型与路径 ---------- *)

Definition lab := nat -> bool.
Definition stepf := nat -> list nat.
Record model : Type := mkM { mlab : lab; mstep : stepf }.

Definition pth := nat -> nat.

Definition ispath (m : model) (s : nat) (pi : pth) : Prop :=
  pi 0 = s /\ forall i, In (pi (S i)) (mstep m (pi i)).

(* ---------- 语义：互嵌 Fixpoint（公式结构递归） ---------- *)

Fixpoint sem (m : model) (pi : pth) (i : nat) (f : sform) : Prop :=
  match f with
  | sAtom p => mlab m (pi i) = true
  | sNeg a  => ~ sem m pi i a
  | sAnd a b => sem m pi i a /\ sem m pi i b
  | sA pf => forall pi', ispath m (pi i) pi' -> psem m pi' 0 pf
  | sE pf => exists pi', ispath m (pi i) pi' /\ psem m pi' 0 pf
  end

with psem (m : model) (pi : pth) (i : nat) (f : pform) : Prop :=
  match f with
  | pState sf => sem m pi i sf
  | pNeg a => ~ psem m pi i a
  | pAnd a b => psem m pi i a /\ psem m pi i b
  | pX a => psem m pi (S i) a
  | pG a => forall j, i <= j -> psem m pi j a
  | pF a => exists j, i <= j /\ psem m pi j a
  | pU a b => exists j, i <= j /\ psem m pi j b /\
              (forall k, i <= k < j -> psem m pi k a)
  end.

(* 现场公式记号 *)
Notation EFP := (sE (pF (pState (sAtom 0)))).
Notation AGEFP := (sA (pG (pState EFP))).
Notation EGFP := (sE (pG (pF (pState (sAtom 0))))).
Notation AGP := (sA (pG (pState (sAtom 0)))).
Notation AFAGP := (sA (pF (pState AGP))).
Notation FGP := (pF (pG (pState (sAtom 0)))).

(* ---------- 分离模型 ---------- *)

(* M（H&R 图 3.23 ①左图）：0 → {1(p 自环), 2}；2 → {2,1}
   —— 每个可达状态都能到 p（AG EF p ✓） *)
Definition M : model := {|
  mlab := fun s => match s with 1 => true | _ => false end;
  mstep := fun s => match s with 0 => [1;2] | 1 => [1] | _ => [2;1] end |}.

(* M'（右图）：0 → 2 只此一路；2 自环——路径是 M 的真子集 *)
Definition M' : model := {|
  mlab := fun s => match s with 1 => true | _ => false end;
  mstep := fun s => match s with 0 => [2] | _ => [2] end |}.

(* N（Remark 3.18）：0(p, 自环+出边) → 1(¬p) → 2(p 自环) *)
Definition N : model := {|
  mlab := fun s => match s with 0 => true | 1 => false | _ => true end;
  mstep := fun s => match s with 0 => [0;1] | 1 => [2] | _ => [2] end |}.

(* ---------- 见证路径与合法性 ---------- *)

Definition path01 : pth := fun i => match i with 0 => 0 | _ => 1 end.
Definition path11 : pth := fun _ => 1.
Definition path21 : pth := fun i => match i with 0 => 2 | _ => 1 end.
Definition path02 : pth := fun i => match i with 0 => 0 | _ => 2 end.
Definition path012 : pth := fun i => match i with 0 => 0 | 1 => 1 | _ => 2 end.
Definition path00 : pth := fun _ => 0.

Lemma ipM_01 : ispath M 0 path01.
Proof. split; [reflexivity|]. intros [|i]; simpl; auto. Qed.

Lemma ipM_11 : ispath M 1 path11.
Proof. split; [reflexivity|]. intros i; simpl; auto. Qed.

Lemma ipM_21 : ispath M 2 path21.
Proof. split; [reflexivity|]. intros [|i]; simpl; auto. Qed.

Lemma ipM'_02 : ispath M' 0 path02.
Proof. split; [reflexivity|]. intros [|i]; simpl; auto. Qed.

Lemma ipN_00 : ispath N 0 path00.
Proof. split; [reflexivity|]. intros i; simpl; auto. Qed.

Lemma ipN_012 : ispath N 0 path012.
Proof. split; [reflexivity|]. intros [|[|i]]; simpl; auto. Qed.

(* ---------- 路径分类引理 ---------- *)

(* M：从 0 出发的路径只经过 {0,1,2} *)
Lemma M_inv : forall pi, ispath M 0 pi -> forall i,
  pi i = 0 \/ pi i = 1 \/ pi i = 2.
Proof.
  intros pi [H0 Hs] i. generalize i as n. clear i.
  induction n as [|n IH].
  - rewrite H0. left. reflexivity.
  - specialize (Hs n). destruct IH as [E|[E|E]]; rewrite E in Hs;
      simpl in Hs; intuition.
Qed.

(* M'：从 2 出发的路径永驻 2 *)
Lemma M'_stay2 : forall pi, ispath M' 2 pi -> forall i, pi i = 2.
Proof.
  intros pi [H0 Hs] i.
  induction i as [|i IH].
  - exact H0.
  - specialize (Hs i). rewrite IH in Hs. simpl in Hs.
    destruct Hs as [E|[]]. symmetry. exact E.
Qed.

(* M'：从 0 出发的路径一步后永驻 2 *)
Lemma M'_paths : forall pi, ispath M' 0 pi -> forall i, pi (S i) = 2.
Proof.
  intros pi [H0 Hs].
  assert (H1 : pi 1 = 2).
  { specialize (Hs 0). rewrite H0 in Hs. simpl in Hs.
    destruct Hs as [E|[]]. symmetry. exact E. }
  intros i. induction i as [|i IH].
  - exact H1.
  - specialize (Hs (S i)). rewrite IH in Hs. simpl in Hs.
    destruct Hs as [E|[]]. symmetry. exact E.
Qed.

(* N：从 0 出发 = 永驻 0，或某时刻经 1 进 2 环 *)
Lemma N_paths : forall pi, ispath N 0 pi ->
  (forall i, pi i = 0) \/
  (exists n, pi n = 1 /\ forall k, n < k -> pi k = 2).
Proof.
  intros pi [H0 Hs].
  (* 首离引理：某位置非 0 ⟹ 更早曾到过 1 *)
  assert (Hfirst : forall i, pi i <> 0 -> exists n, n <= i /\ pi n = 1).
  { induction i as [|i IH]; intros Hne.
    - exfalso. apply Hne. exact H0.
    - destruct (Nat.eq_dec (pi i) 0) as [Ez | Ene].
      + assert (E1 : pi (S i) = 1).
        { specialize (Hs i). rewrite Ez in Hs. simpl in Hs.
          destruct Hs as [E0 | [E1 | []]].
          - exfalso. apply Hne. symmetry. exact E0.
          - symmetry. exact E1. }
        exists (S i). split; [lia | exact E1].
      + destruct (IH Ene) as [n' [Hle H1]]. exists n'. split; [lia | exact H1]. }
  destruct (classic (exists n, pi n = 1)) as [[n H1] | Hno].
  - right. exists n. split; [exact H1|].
    assert (Hk2 : pi (S n) = 2).
    { specialize (Hs n). rewrite H1 in Hs. simpl in Hs.
      destruct Hs as [E|[]]. symmetry. exact E. }
    intros k Hk.
    assert (Hgen : forall j, pi (S n + j) = 2).
    { intros j. induction j as [|j IHj].
      - replace (S n + 0) with (S n) by lia. exact Hk2.
      - specialize (Hs (S n + j)). rewrite IHj in Hs. simpl in Hs.
        destruct Hs as [E|[]].
        replace (S n + S j) with (S (S n + j)) by lia. symmetry. exact E. }
    replace k with (S n + (k - S n)) by lia. apply Hgen.
  - left. intros i.
    destruct (Nat.eq_dec (pi i) 0) as [Ez | Ene].
    + exact Ez.
    + exfalso. apply Hno. destruct (Hfirst i Ene) as [n' [_ H1']].
      exists n'. exact H1'.
Qed.

(* ---------- (a) AG EF p：M ⊨ ---------- *)

Theorem M_AGEFp : forall pi, ispath M 0 pi -> sem M pi 0 AGEFP.
Proof.
  intros pi Hip. destruct Hip as [H0 Hs].
  simpl. rewrite H0. intros pi' Hip' j _.
  destruct (M_inv pi' Hip' j) as [E|[E|E]]; rewrite E.
  - exists path01. split.
    + apply ipM_01.
    + exists 1. split; [lia|reflexivity].
  - exists path11. split.
    + apply ipM_11.
    + exists 0. split; [lia|reflexivity].
  - exists path21. split.
    + apply ipM_21.
    + exists 1. split; [lia|reflexivity].
Qed.

(* ---------- (a) M' ⊭ ---------- *)

Theorem M'_not_AGEFp : ~ sem M' path02 0 AGEFP.
Proof.
  intros Hall. simpl in Hall.
  specialize (Hall path02 ipM'_02).
  specialize (Hall 1 (Nat.le_succ_diag_r 0)).
  simpl in Hall. destruct Hall as [q [Hq HF]].
  pose proof (M'_stay2 q Hq) as Hq2.
  destruct HF as [j [_ Hj]]. rewrite Hq2 in Hj.
  simpl in Hj. discriminate Hj.
Qed.

(* ---------- (b) E[G F p]：M ⊨ / M' ⊭ ---------- *)

Theorem M_EGFp : sem M path01 0 EGFP.
Proof.
  simpl. exists path01. split; [apply ipM_01|].
  intros j _. destruct j as [|j'].
  - exists 1. split; [lia|reflexivity].
  - exists (S j'). split; [lia|reflexivity].
Qed.

Theorem M'_not_EGFp : ~ sem M' path02 0 EGFP.
Proof.
  intros Hall. simpl in Hall. destruct Hall as [q [Hq HG]].
  pose proof (M'_paths q Hq) as Hq2.
  specialize (HG 1 (Nat.le_succ_diag_r 0)). simpl in HG.
  destruct HG as [j [Hj1 Hj]].
  assert (Eq2 : q j = 2).
  { destruct j as [|j'].
    - destruct Hq as [Hq0 _]. rewrite Hq0. lia.
    - rewrite (Hq2 j'). reflexivity. }
  rewrite Eq2 in Hj. simpl in Hj. discriminate Hj.
Qed.

(* ---------- (c) F G p ⊨ 而 AF AG p ⊭（N 模型） ---------- *)

Theorem N_AFGp : forall pi, ispath N 0 pi -> psem N pi 0 FGP.
Proof.
  intros pi Hip. simpl.
  destruct (N_paths pi Hip) as [H0 | [n [H1 H2]]].
  - exists 0. split; [lia|]. intros j _. simpl. rewrite H0. reflexivity.
  - exists (S n). split; [lia|]. intros k Hk. simpl.
    assert (Ek : pi k = 2) by (apply H2; lia).
    rewrite Ek. reflexivity.
Qed.

Theorem N_not_AFAGp : ~ sem N path00 0 AFAGP.
Proof.
  intros Hall. simpl in Hall.
  specialize (Hall path00 ipN_00).
  destruct Hall as [j [_ Hj]]. simpl in Hj.
  specialize (Hj path012 ipN_012).
  specialize (Hj 1 (Nat.le_succ_diag_r 0)). simpl in Hj. discriminate Hj.
Qed.

(* ---------- 收口账本 ---------- *)

Check M_AGEFp.      (* M ⊨ AG EF p *)
Check M'_not_AGEFp. (* M' ⊭ AG EF p（M' 的路径 ⊆ M 的路径） *)
Check M_EGFp.       (* M ⊨ E[G F p] *)
Check M'_not_EGFp.  (* M' ⊭ E[G F p] *)
Check N_AFGp.       (* N 的所有路径 ⊨ F G p *)
Check N_not_AFAGp.  (* N ⊭ AF AG p —— F G p 与 AF AG p 分离现场 *)

(* 坑位速记（Coq 侧）：
   - 互嵌归纳 sform/pform 的 Fixpoint sem/psem 直接被接受（每个递归
     调用都在严格子公式上——与 36 章 lsat 同一合法性来源）；
   - Notation 定义的总公式（EFP 等）**不能 unfold**——「Cannot coerce
     to an evaluable reference」；全走 simpl（Fixpoint 的 match 直接收）；
   - 路径分类引理是全部工作量的七成：「永驻 X」型 = 一步引理 + 位置
     归纳；「或走或留」型（N_paths）先证**首离引理**（非 0 ⟹ 曾过 1，
     对位置归纳 + 前驱状态分类），再经典排中拆 ∃ 分两路收；
   - specialize 步前提**先于** rewrite（Hs 的 ∀ 界变量遮蔽外层同名）；
   - In 单元素表给出 `2 = x` 形方程（元素在左）——喂 equality 目标
     要 symmetry；不等式消灭用 exfalso + apply（0 ≠ 0 不是构造子
     歧义，discriminate 不收）；
   - 右支「n 之后全 2」别直接对 k 归纳（基例在 S n）——改证
     ∀j, π(S n + j) = 2（偏移归纳），加法换算 lia；
   - E 层组装直接 exists q + split（ispath 键 + F 见证 k ≥ 0）——
     simpl 已把 sE/pF 展到底，辅助引理反而挡 apply 的统一。 *)
