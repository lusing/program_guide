(* 第 101 章：有限秩层 V_n、层包含链、导出超滤子记账与见证条款。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch101.

(* ── 一、位编码有限累积层次 ──
   编码 x ∈ {0..15}，元素表 = 使第 i 位为 1 的 i 全体。
   level 0 = []，level (n+1) = {x | elems x ⊆ level n}。 *)

Definition universe := seq 0 16.

Definition elems (x : nat) : list nat :=
  filter (fun i => Nat.testbit x i) (seq 0 16).

Definition memb (x : nat) (l : list nat) : bool :=
  existsb (fun y => Nat.eqb y x) l.

Definition sublb (l1 l2 : list nat) : bool :=
  forallb (fun x => memb x l2) l1.

Fixpoint level (n : nat) : list nat :=
  match n with
  | 0 => []
  | S m => filter (fun x => sublb (elems x) (level m)) universe
  end.

(* 前四层的精确内容：∅；{∅}；{∅,{∅}}；四元；十六元满宇宙。
   注意 vm_compute：reflexivity 的内核转换对 level 4 的无共享
   重复展开会爆炸（level 3 在每个成员检查里重算），VM 求值瞬间。 *)
Example level_1 : level 1 = [0].
Proof. vm_compute. reflexivity. Qed.

Example level_2 : level 2 = [0; 1].
Proof. vm_compute. reflexivity. Qed.

Example level_3 : level 3 = [0; 1; 2; 3].
Proof. vm_compute. reflexivity. Qed.

Example level_4 : level 4 = universe.
Proof. vm_compute. reflexivity. Qed.

(* beth 尺寸链：1, 2, 4, 16。 *)
Example level_card_chain :
  length (level 1) = 1 /\ length (level 2) = 2 /\
  length (level 3) = 4 /\ length (level 4) = 16.
Proof. repeat split; vm_compute; reflexivity. Qed.

(* ── 二、反射引理与层包含链 V_n ⊆ V_{n+1} ── *)

Lemma memb_true_in : forall x l, memb x l = true -> In x l.
Proof.
  intros x l. induction l as [|a t IH]; simpl.
  - discriminate.
  - destruct (Nat.eqb_spec a x) as [E|NE].
    + intros _. left. exact E.
    + simpl. intros H. right. apply IH. exact H.
Qed.

Lemma in_memb_true : forall x l, In x l -> memb x l = true.
Proof.
  intros x l. induction l as [|a t IH]; simpl.
  - intros [].
  - intros [E|H].
    + subst. rewrite Nat.eqb_refl. reflexivity.
    + apply orb_true_intro. right. apply IH. exact H.
Qed.

(* 点级包含：布尔版为真 ⟹ 点级包含。 *)
Lemma sublb_subl : forall l1 l2, sublb l1 l2 = true ->
  forall x, In x l1 -> In x l2.
Proof.
  intros l1 l2 H x Hx. unfold sublb in H.
  rewrite forallb_forall in H. specialize (H x Hx).
  apply memb_true_in. exact H.
Qed.

(* 单层展开方程：避免 cbn [level] 多层展开触发 unify 指数爆炸。 *)
Lemma level_S : forall n,
  level (S n) = filter (fun x => sublb (elems x) (level n)) universe.
Proof. intros n. reflexivity. Qed.

(* 关键单调引理：x ∈ level n ⟹ x ∈ level (n+1)。 *)
Lemma level_mono_step : forall n x, In x (level n) -> In x (level (S n)).
Proof.
  induction n as [|n IH]; intros x H.
  - cbn [level] in H. destruct H.
  - rewrite level_S in H. apply filter_In in H. destruct H as [Hin Hsub].
    rewrite level_S. apply filter_In. split.
    + exact Hin.
    + unfold sublb. rewrite forallb_forall. intros i Hi.
      apply in_memb_true. apply IH.
      apply (sublb_subl (elems x) (level n) Hsub i Hi).
Qed.

(* 前四环包含链。 *)
Example level_chain :
  (forall x, In x (level 0) -> In x (level 1)) /\
  (forall x, In x (level 1) -> In x (level 2)) /\
  (forall x, In x (level 2) -> In x (level 3)) /\
  (forall x, In x (level 3) -> In x (level 4)).
Proof.
  repeat split; intros x Hx; eapply level_mono_step; eassumption.
Qed.

(* ── 三、导出超滤子记账：单射保交 ──
   张子公理 (a)：E_a = {X | a ∈ j``X} 对交封闭。
   「X∩Y」以 filter (memb · Y) X 表示。 *)

Lemma in_map_inter : forall (f : nat -> nat) (Hinj : forall u v, f u = f v -> u = v)
                         (X Y : list nat) (a : nat),
  In a (map f X) -> In a (map f Y) ->
  In a (map f (filter (fun z => memb z Y) X)).
Proof.
  intros f Hinj X Y a HX HY.
  apply in_map_iff in HX. destruct HX as [x [Hfx Hxin]].
  apply in_map_iff in HY. destruct HY as [y [Hfy Hyin]].
  assert (Hxy : x = y) by (apply Hinj; congruence).
  subst y. apply in_map_iff. exists x. split.
  - exact Hfx.
  - apply filter_In. split.
    + exact Hxin.
    + apply in_memb_true. exact Hyin.
Qed.

Example derived_inter_sample :
  forall (X Y : list nat),
  In 5 (map (fun z => z) X) -> In 5 (map (fun z => z) Y) ->
  In 5 (map (fun z => z) (filter (fun z => memb z Y) X)).
Proof. intros X Y HX HY. apply in_map_inter; auto. Qed.

(* ── 四、见证条款记账 ── *)

Record Wit := mkWit {crit : nat; jk : nat; captured : list nat}.

Definition lam_strong (w : Wit) (l : nat) : Prop :=
  crit w <= l /\ l < jk w /\ In l (captured w).

Definition superstrong (w : Wit) : Prop := In (jk w) (captured w).

Definition is_strong (w : Wit) : Prop :=
  forall l, crit w <= l -> lam_strong w l.

Definition maxl (l : list nat) : nat := fold_right Nat.max 0 l.

Lemma maxl_ge : forall l y, In y l -> y <= maxl l.
Proof.
  induction l as [|a t IH]; simpl; intros y Hy.
  - destruct Hy.
  - destruct Hy as [->|Hy].
    + apply Nat.le_max_l.
    + apply Nat.max_le_iff. right. apply IH. exact Hy.
Qed.

(* 有限捕获表不可能承载「对所有 λ 的见证」：
   取 L = crit + (maxl + 1) 超出表内一切元素。 *)
Theorem not_strong_finite : forall w : Wit, ~ is_strong w.
Proof.
  intros w H.
  assert (Hle : crit w <= crit w + S (maxl (captured w))) by lia.
  destruct (H (crit w + S (maxl (captured w))) Hle) as [_ [_ Hmem]].
  apply maxl_ge in Hmem. lia.
Qed.

(* 单 λ 见证样本与两个否定。 *)
Example wit_lam3 : lam_strong (mkWit 2 5 [3]) 3.
Proof. simpl. repeat split; simpl; lia. Qed.

Example wit_not_lam4 : ~ lam_strong (mkWit 2 5 [3]) 4.
Proof.
  intro H. destruct H as [_ [_ [E|F]]].
  - lia.
  - destruct F.
Qed.

Example wit_not_superstrong : ~ superstrong (mkWit 2 5 [3]).
Proof.
  intro H. simpl in H. destruct H as [E|F].
  - discriminate E.
  - destruct F.
Qed.

Example wit_superstrong : superstrong (mkWit 2 4 [4]).
Proof. simpl. left. reflexivity. Qed.

End Ch101.
