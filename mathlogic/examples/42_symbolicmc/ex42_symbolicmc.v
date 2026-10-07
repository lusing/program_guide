(* ex42_symbolicmc —— 符号模型检查与关系 μ 演算（H&R §6.3-6.4）

   对书：Huth&Ryan §6.3（符号模型检查）/ §6.4（关系 μ 演算）
   依赖：10 章 BDD 语义接口（restrict/exb 的对偶面 preE）、
         35 章 CTL 语义形态（自包含复制）

   设计（有限显式模型，状态集=list nat；教学版无 BDD 压缩——
   符号化=「集合运算而非逐状态」，BDD 是它的位级实现）：
   - preE S = {s | ∃s'∈S. s→s'}——前像（一步倒带）；
   - μ/ν = 泛函迭代的两种起跑：μ 从 ⊥（空集）涨、ν 从 ⊤（全体）
     压——有限载体上 Knaster–Tarski 的可计算形态；
   - CTL 编码：EG φ ↦ νZ.(φ ∩ preE Z)、E[φ U ψ] ↦ μZ.(ψ ∪ (φ ∩ preE Z))
     ——与 35 章 iterEG/iterEU 的**定义等价**（同一条迭代链）；
   - 正确性链：preE 的成员刻画（双向）+ 迭代步展开 + 编码等价。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- 有限模型（沿 35 章） ---------- *)

Record fmodel : Type := mkM {
  fstates : list nat;
  ftrans : nat -> list nat
}.

(* ---------- 状态集运算 ---------- *)

Definition memL (S : list nat) (s : nat) : bool := existsb (Nat.eqb s) S.

Lemma memL_In : forall S s, memL S s = true <-> In s S.
Proof.
  intros S s. unfold memL. rewrite existsb_exists. split.
  - intros [x [Hin Heq]]. apply Nat.eqb_eq in Heq. subst x. exact Hin.
  - intros Hin. exists s. split; [exact Hin | apply Nat.eqb_refl].
Qed.

Definition interL (S T : list nat) : list nat := filter (memL T) S.
Definition unionL (S T : list nat) : list nat := S ++ T.

Lemma interL_In : forall S T s,
  In s (interL S T) <-> In s S /\ In s T.
Proof.
  intros S T s. unfold interL. rewrite filter_In. split.
  - intros [H1 H2]. split; [exact H1 | apply memL_In; exact H2].
  - intros [H1 H2]. split; [exact H1 | apply memL_In; exact H2].
Qed.

Lemma unionL_In : forall S T s,
  In s (unionL S T) <-> In s S \/ In s T.
Proof.
  intros S T s. unfold unionL. split.
  - intros H. apply in_app_or. exact H.
  - intros [H | H]; apply in_or_app; [left; exact H | right; exact H].
Qed.

(* ---------- preE：前像（H&R §6.3.3 的 pre∃） ---------- *)

Definition preE (m : fmodel) (S : list nat) : list nat :=
  filter (fun s => existsb (fun s' => memL S s') (ftrans m s))
         (fstates m).

(* 旗舰一：preE 的成员刻画（双向） *)
Lemma preE_In : forall m S s,
  In s (preE m S) <->
  In s (fstates m) /\ exists s', In s' (ftrans m s) /\ In s' S.
Proof.
  intros m S s. unfold preE. rewrite filter_In, existsb_exists. split.
  - intros [Hst [x [Htr Hmem]]]. split; [exact Hst|].
    exists x. split; [exact Htr|]. apply memL_In. exact Hmem.
  - intros [Hst [x [Htr Hmem]]]. split; [exact Hst|].
    exists x. split; [exact Htr|]. apply memL_In. exact Hmem.
Qed.

(* preE 单调：集合变大前像变大（Knaster–Tarski 的前提） *)
Lemma preE_mono : forall m S T,
  (forall x, In x S -> In x T) ->
  forall x, In x (preE m S) -> In x (preE m T).
Proof.
  intros m S T Hsub x Hx. apply preE_In in Hx.
  destruct Hx as [Hst [s' [Htr Hmem]]].
  apply preE_In. split; [exact Hst|].
  exists s'. split; [exact Htr | apply Hsub; exact Hmem].
Qed.

(* ---------- μ/ν：泛函迭代的两种起跑（H&R §6.4.1） ---------- *)

Fixpoint iterF (fuel : nat) (F : list nat -> list nat)
    (seed : list nat) : list nat :=
  match fuel with
  | 0 => seed
  | S k => F (iterF k F seed)
  end.

Definition muFix (m : fmodel) (F : list nat -> list nat) : list nat :=
  iterF (S (length (fstates m))) F [].      (* μ：⊥ = 空集起涨 *)

Definition nuFix (m : fmodel) (F : list nat -> list nat) : list nat :=
  iterF (S (length (fstates m))) F (fstates m).  (* ν：⊤ = 全体起压 *)

(* ---------- CTL 的 μ 编码（H&R §6.4.2 表） ---------- *)

(* 35 章的直接迭代（自包含复制） *)
Fixpoint iterEG (m : fmodel) (fuel : nat) (A : list nat) : list nat :=
  match fuel with
  | 0 => fstates m
  | S k => interL A (preE m (iterEG m k A))
  end.

Fixpoint iterEU (m : fmodel) (fuel : nat) (A B : list nat) : list nat :=
  match fuel with
  | 0 => B
  | S k => unionL B (interL A (preE m (iterEU m k A B)))
  end.

(* EG φ ↦ νZ.(φ ∩ preE Z)：编码泛函 *)
Definition egFun (m : fmodel) (A : list nat) (Z : list nat) : list nat :=
  interL A (preE m Z).

(* 迭代同构引理：ν 的泛函迭代与 iterEG 逐轮相等 *)
Lemma iterF_is_iterEG : forall m fuel A,
  iterF fuel (fun Z => interL A (preE m Z)) (fstates m)
  = iterEG m fuel A.
Proof.
  intros m fuel. induction fuel as [|k IH]; intros A.
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* 旗舰二：ν 编码 = 直接迭代（同一条迭代链的机器账） *)
Theorem nu_eg_is_iterEG : forall m A,
  nuFix m (fun Z => egFun m A Z)
  = iterEG m (S (length (fstates m))) A.
Proof.
  intros m A. unfold nuFix, egFun. apply iterF_is_iterEG.
Qed.

(* EU 的编码泛函：Z ↦ B ∪ (A ∩ preE Z) *)
Definition euFun (m : fmodel) (A B : list nat) (Z : list nat) : list nat :=
  unionL B (interL A (preE m Z)).

(* preE ∅ = ∅：没有目标集就没有前像 *)
Lemma preE_empty : forall m, preE m [] = [].
Proof.
  intros m.
  destruct (preE m []) as [|x xs] eqn:E; [reflexivity|].
  assert (Hin : In x (preE m [])) by (rewrite E; left; reflexivity).
  apply preE_In in Hin. destruct Hin as [_ [s' [_ Hmem]]].
  apply memL_In in Hmem. simpl in Hmem. discriminate.
Qed.

Lemma interL_empty : forall S, interL S [] = [].
Proof.
  intros S. induction S as [|x xs IH]; [reflexivity|].
  simpl in *. unfold memL. simpl. rewrite IH. reflexivity.
Qed.

(* μ 的 ⊥-起跑与 EU 的 B-起跑恰差一轮：F(∅) = B *)
Lemma mu_seed_step : forall m A B,
  unionL B (interL A (preE m [])) = B.
Proof.
  intros m A B. unfold unionL. rewrite preE_empty, interL_empty, app_nil_r.
  reflexivity.
Qed.

Lemma iterF_is_iterEU : forall m fuel A B,
  iterF (S fuel) (fun Z => unionL B (interL A (preE m Z))) []
  = iterEU m fuel A B.
Proof.
  intros m fuel. induction fuel as [|k IH]; intros A B.
  - simpl. rewrite mu_seed_step. reflexivity.
  - simpl in *. rewrite IH. reflexivity.
Qed.

(* 旗舰三：μ 编码 = 直接迭代（⊥-起跑比 B-起跑恰多烧一轮） *)
Theorem mu_eu_is_iterEU : forall m A B,
  muFix m (fun Z => euFun m A B Z)
  = iterEU m (length (fstates m)) A B.
Proof.
  intros m A B. unfold muFix, euFun.
  exact (iterF_is_iterEU m (length (fstates m)) A B).
Qed.

(* ---------- 迭代步展开（算法层的正确性构件） ---------- *)

Theorem iterEG_step : forall m k A,
  iterEG m (S k) A = interL A (preE m (iterEG m k A)).
Proof. reflexivity. Qed.

Theorem iterEU_step : forall m k A B,
  iterEU m (S k) A B = unionL B (interL A (preE m (iterEU m k A B))).
Proof. reflexivity. Qed.

(* ---------- μ/ν 的对偶现场（H&R：νZ.F = μZ.F(¬Z) 的 ¬ 版） ---------- *)

(* 教学现场：两状态模型 0→1→1（自环），p 只在 1 *)
Definition m2 : fmodel := {|
  fstates := [0; 1];
  ftrans := fun s => [1] |}.

(* EG {1}：全体起压——一轮后 {1}∩preE({0,1}) = {1}∩{0,1} = {1}
   （0 的后继 1 ∈ 全体；1 的后继 1 ∈ 全体）——不动点 {1} *)
Example eg_mu_hit :
  memL (nuFix m2 (fun Z => egFun m2 [1] Z)) 1 = true.
Proof. reflexivity. Qed.

Example eg_mu_miss :
  memL (nuFix m2 (fun Z => egFun m2 [1] Z)) 0 = false.
Proof. reflexivity. Qed.

(* EU {1} {1}：空集起涨——
   轮 1：{1} ∪ ({1} ∩ preE{1}) = {1} ∪ ({1}∩{0,1}) = {1}
   ——不动点 {1} *)
(* （教学版 unionL 不去重——结果 [1;1]，成员口径断言） *)
Example eu_mu_hit :
  memL (muFix m2 (fun Z => euFun m2 [1] [1] Z)) 1 = true.
Proof. reflexivity. Qed.

Example eu_mu_miss :
  memL (muFix m2 (fun Z => euFun m2 [1] [1] Z)) 0 = false.
Proof. reflexivity. Qed.

(* 对照：EG ∅ 恒空（ν 压到不动点后 A=∅ 交出空） *)
Example eg_mu_empty :
  nuFix m2 (fun Z => egFun m2 [] Z) = [].
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - preE 是 10 章 restrict 的**对偶面**：restrict 钉变元（纵向），
     preE 换层（横向一步倒带）——BDD 版 = restrict(f[1/x]) ∨
     restrict(f[0/x]) 即 exb（10 章）再取前像；
   - μ/ν 的「同一条迭代链」结构：nuFix/μFix 就是 iterEG/iterEU
     换个名字——编码等价 = reflexivity 是**设计**而非巧合：
     35 章的算法本来就是按不动点语义写的（H&R §3.7 的工程回环）；
   - 泛函直接用 list nat -> list nat（不做带名器的语法）——
     教学版把 H&R 的侧条件（变元单调性）吸收进「单泛函」形态；
     带名器/嵌套 μν 登记边界（正规模语义需要 environment 传递）。 *)
