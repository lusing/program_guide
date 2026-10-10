(* ex106_nbg.v —— 公理集合论 NBG 与序数（Mendelson §4.1-4.6）
   有限集合项代数上的四组机器件：
   1) Kuratowski 序对与命题 4.3 特征性质（vn-典范世界，结构相等=外延相等）
   2) von Neumann 序数：传递性的真定理 + 反例现场
   3) 有限选择公理 fin_ac——构造性、零公理（账本亮点）
   4) 类存在公理的成员表算子现场（B1-B5，有限论域+点式验证定理）
   真类/Russell 化身、Hartogs、AC 等价族、MK/ZF/ST/NF 对照为文档线。 *)

From Stdlib Require Import Bool Arith Lia List PeanoNat.
Import ListNotations.

(* ============ 一、有限集合项代数与 von Neumann 典范世界 ============ *)

Inductive fset : Type :=
| atom (n : nat)            (* 原子 *)
| br (xs : list fset).      (* 分支：元素的有限罗列 *)

Definition fmembP (x y : fset) : Prop :=
  match y with
  | atom _ => False
  | br ys => In x ys
  end.

(* von Neumann 数：vn n = {vn 0, …, vn (n-1)}——典范形：结构相等=外延相等
   （map vn 的未应用递归被 guard 拒（itup 同族），改追加式定义） *)
Fixpoint vn (n : nat) : fset :=
  match n with
  | O => br []
  | S k =>
      match vn k with
      | br l => br (l ++ [vn k])
      | atom _ => br []
      end
  end.

Definition els (x : fset) : list fset :=
  match x with br l => l | atom _ => [] end.

Lemma vn_br : forall k, exists l, vn k = br l.
Proof.
  induction k as [|k [l IH]].
  - exists []. reflexivity.
  - exists (l ++ [br l]). simpl. rewrite IH. reflexivity.
Qed.

Lemma els_vn_S : forall k, els (vn (S k)) = els (vn k) ++ [vn k].
Proof.
  intro k. destruct (vn_br k) as [l Hl]. rewrite Hl. simpl.
  rewrite Hl. reflexivity.
Qed.

Definition vlen (x : fset) : nat :=
  match x with br l => length l | atom _ => 0 end.

Lemma vn_len : forall n, vlen (vn n) = n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - simpl (vn (S n)). destruct (vn_br n) as [l Hl].
    rewrite Hl in IH. simpl in IH.
    rewrite Hl. simpl. rewrite length_app. simpl. lia.
Qed.

Lemma vn_inj : forall a b, vn a = vn b -> a = b.
Proof.
  intros a b H.
  assert (Hl : vlen (vn a) = vlen (vn b)) by (rewrite H; reflexivity).
  rewrite !vn_len in Hl. exact Hl.
Qed.

(* 成员刻画：vn j ∈ vn k ⟺ j < k *)
Lemma vn_memb_lt : forall j k, In (vn j) (els (vn k)) -> j < k.
Proof.
  intros j k. revert j. induction k as [|k IH]; intros j Hin.
  - destruct Hin.
  - rewrite els_vn_S in Hin. apply in_app_or in Hin.
    destruct Hin as [Hl | Hr].
    + specialize (IH j Hl). lia.
    + simpl in Hr. destruct Hr as [Heq | []].
      apply vn_inj in Heq. lia.
Qed.

Lemma vn_lt_memb : forall j k, j < k -> In (vn j) (els (vn k)).
Proof.
  intros j k. revert j. induction k as [|k IH]; intros j Hlt.
  - lia.
  - rewrite els_vn_S. apply in_or_app.
    destruct (Nat.eq_dec j k) as [-> | Hne].
    + right. left. reflexivity.
    + left. apply IH. lia.
Qed.

(* ============ 二点五、Kuratowski 序对：命题 4.3 特征性质 ============ *)

Definition kur (x y : fset) : fset := br [br [x]; br [x; y]].

Theorem kur_char : forall a b c d,
  kur (vn a) (vn b) = kur (vn c) (vn d) -> a = c /\ b = d.
Proof.
  intros a b c d H. unfold kur in H.
  injection H. intros E1 E2 E3.
  apply vn_inj in E1. apply vn_inj in E2.
  split; assumption.
Qed.

(* ============ 三、von Neumann 序数：传递性真定理与反例 ============ *)

Definition transP (x : fset) : Prop :=
  match x with
  | atom _ => True
  | br ys => forall u, In u ys -> forall w, In w (els u) -> In w ys
  end.

(* els 的元素刻画：vn k 的元素恰是更小的 vn j *)
Lemma vn_els_ex : forall k u, In u (els (vn k)) -> exists j, j < k /\ u = vn j.
Proof.
  induction k as [|k IH]; intros u Hin.
  - destruct Hin.
  - rewrite els_vn_S in Hin. apply in_app_or in Hin.
    destruct Hin as [Hl | [Heq | []]].
    + destruct (IH u Hl) as [j [Hj Huj]]. exists j. split; [lia | exact Huj].
    + exists k. split; [lia | symmetry; exact Heq].
Qed.

Theorem vn_trans : forall n, transP (vn n).
Proof.
  intro n. induction n as [|n IH].
  - intros u Hu. destruct (vn_els_ex 0 u Hu) as [j [Hj _]]. lia.
  - destruct (vn_br (S n)) as [l Hl]. rewrite Hl. simpl.
    assert (Hl2 : els (vn (S n)) = els (vn n) ++ [vn n]) by exact (els_vn_S n).
    rewrite Hl in Hl2. simpl in Hl2. rewrite Hl2.
    intros u Hu. apply in_app_or in Hu.
    destruct Hu as [Hu | [Heq | []]].
    + destruct (vn_els_ex n u Hu) as [j [Hj ->]].
      intros w Hw. apply in_or_app. left.
      destruct (vn_els_ex _ w Hw) as [i [Hi ->]].
      apply vn_lt_memb. lia.
    + subst u. intros w Hw. apply in_or_app.
      destruct (vn_els_ex _ w Hw) as [i [Hi ->]].
      left. apply vn_lt_memb. lia.
Qed.

(* 反例：{1,2}（={vn1,vn2}）不传递——vn0 ∈ vn1 但 vn0 ∉ {vn1,vn2} *)
Example not_trans_ex : ~ transP (br [vn 1; vn 2]).
Proof.
  intro H. simpl in H.
  assert (H1 : In (vn 1) [vn 1; vn 2]) by (left; reflexivity).
  specialize (H _ H1).
  assert (Heq0 : els (vn 0) = []) by reflexivity.
  assert (H0 : In (vn 0) (els (vn 1))).
  { rewrite els_vn_S, Heq0. simpl. left. reflexivity. }
  specialize (H _ H0).
  simpl in H. destruct H as [H | [H | []]]; congruence.
Qed.

(* ============ 四、有限选择公理：构造性、零公理 ============ *)

Theorem fin_ac : forall (L : list (list fset)),
  (forall x, In x L -> exists a, In a x) ->
  exists c, length c = length L /\
    forall i, i < length L -> In (nth i c (atom 0)) (nth i L []).
Proof.
  induction L as [|x L IH]; intros Hne.
  - exists []. simpl. split; [reflexivity | intros i Hi; lia].
  - assert (Hx : exists a, In a x) by (apply Hne; left; reflexivity).
    destruct Hx as [a Ha].
    destruct (IH (fun y Hy => Hne y (or_intror Hy))) as [c [Hlen Hc]].
    exists (a :: c). simpl. split.
    + f_equal. exact Hlen.
    + intro i. destruct i as [|i]; simpl.
      * intro Hi. exact Ha.
      * intro Hi. apply Hc. simpl in Hi. lia.
Qed.

(* ============ 五、类存在公理的成员表算子现场（B1-B5）============ *)

(* 有限论域 {0..K-1}：一元类=成员表 nat->bool；二元类=双参表。
   NBG 的类存在公理组在这里是「构造算子」：每条公理配一个算子+点式定理。 *)

Definition Erel (K : nat) : nat -> nat -> bool :=
  fun u v => (u <? K) && (v <? K) && (u <? v).            (* B1 ∈-关系（von Neumann 表） *)
Definition opInter (X Y : nat -> bool) : nat -> bool :=
  fun u => X u && Y u.                                    (* B2 交 *)
Definition opCompl (X : nat -> bool) : nat -> bool :=
  fun u => negb (X u).                                    (* B3 补 *)
Definition opDom (R : nat -> nat -> bool) (K : nat) : nat -> bool :=
  fun u => existsb (fun v => R u v) (seq 0 K).            (* B4 域 *)
Definition opCross (X : nat -> bool) (K : nat) : nat -> nat -> bool :=
  fun u v => X u && (v <? K).                             (* B5 X×V *)
Definition opSwap (R : nat -> nat -> bool) : nat -> nat -> bool :=
  fun u v => R v u.                                       (* B6/B7 轮换/对换的二元化身 *)

Theorem opInter_ok : forall X Y u,
  opInter X Y u = true <-> (X u = true /\ Y u = true).
Proof.
  intros X Y u. unfold opInter. split.
  - intro H. apply andb_true_iff in H. exact H.
  - intros [H1 H2]. apply andb_true_iff. split; assumption.
Qed.

Theorem opCompl_ok : forall X u,
  opCompl X u = true <-> X u = false.
Proof.
  intros X u. unfold opCompl. split.
  - intro H. apply negb_true_iff in H. exact H.
  - intro H. apply negb_true_iff. exact H.
Qed.

Theorem opDom_ok : forall R K u,
  opDom R K u = true <-> exists v, v < K /\ R u v = true.
Proof.
  intros R K u. unfold opDom. split.
  - intro H. apply existsb_exists in H.
    destruct H as [v [Hin Hv]]. apply in_seq in Hin.
    exists v. split; [lia | exact Hv].
  - intros [v [Hlt Hv]]. apply existsb_exists.
    exists v. split; [apply in_seq; lia | exact Hv].
Qed.

Theorem opCross_ok : forall X K u v,
  opCross X K u v = true <-> (X u = true /\ v < K).
Proof.
  intros X K u v. unfold opCross. split.
  - intro H. apply andb_true_iff in H. destruct H as [H1 H2].
    apply Nat.ltb_lt in H2. split; assumption.
  - intros [H1 H2]. apply andb_true_iff. split.
    + exact H1.
    + apply Nat.ltb_lt. exact H2.
Qed.

Theorem opSwap_ok : forall R u v,
  opSwap R u v = true <-> R v u = true.
Proof.
  intros R u v. unfold opSwap. split; intro H; exact H.
Qed.

(* 现场对账：K=4 论域上 ∈-表驱动的一串算子计算 *)
Example cls_ops_table :
  (map (fun u => opInter (fun v => v <? 3) (fun v => 1 <=? v) u) (seq 0 5),
   map (fun u => opDom (Erel 4) 4 u) (seq 0 4),
   map (fun u => opCompl (fun v => v <? 2) u) (seq 0 3))
  = ([false; true; true; false; false],
     [true; true; true; false],
     [false; false; true]).
Proof. reflexivity. Qed.

(* ============ 账本 ============ *)

Print Assumptions vn_trans.
Print Assumptions kur_char.
Print Assumptions fin_ac.
Print Assumptions opDom_ok.
