(* ex46 —— 集合、幂集与计数（Jongsma ch4：§4.1/4.2/4.3/4.4/4.5）
   谓词集合运算律 —— 书 Prop 4.1.5-4.1.10：交并的交换/结合/分配/吸收 +
   De Morgan（补集相对宇宙 U）——全是第 03 章命题演算的集合化身；
   powl/prodl —— 幂集与笛卡尔积的列表实现：|P(S)| = 2^n（书例 4.2.6 的
   8 个子集）、|S×T| = |S|·|T|（书 Prop 4.3.1a 乘法计数原理）；
   choose —— 组合数（Pascal 递归）：Σ_{k≤n} C(n,k) = 2^n（与幂集对账：
   n 元素的 k-子集全体 = 幂集，书 Prop 4.4.1 + 练习 4.4.1b）；
   incexc2/incexc3 —— 容斥原理的列表版（书 Prop 4.5.2 与 Thm 4.5.1 的
   三集合情形）：全部写成加法形态，避开 nat 减法。 *)

From Stdlib Require Import List Bool Arith Lia Classical.
Import ListNotations.

(* ---------- 1. 谓词集合：运算律（书 Prop 4.1.5-4.1.10） ---------- *)

Definition pset := nat -> Prop.
Definition sub (S T : pset) := forall x, S x -> T x.
Definition inter (S T : pset) : pset := fun x => S x /\ T x.
Definition union (S T : pset) : pset := fun x => S x \/ T x.
Definition compl (U S : pset) : pset := fun x => U x /\ ~ S x.

(* 运算律全部写成逐点 iff：不引入命题外延公理 *)
Theorem inter_comm : forall (S T : pset) x,
  inter S T x <-> inter T S x.
Proof. intros S T x. unfold inter. tauto. Qed.

Theorem union_comm : forall (S T : pset) x,
  union S T x <-> union T S x.
Proof. intros S T x. unfold union. tauto. Qed.

Theorem inter_assoc : forall (R S T : pset) x,
  inter R (inter S T) x <-> inter (inter R S) T x.
Proof. intros R S T x. unfold inter. tauto. Qed.

Theorem union_assoc : forall (R S T : pset) x,
  union R (union S T) x <-> union (union R S) T x.
Proof. intros R S T x. unfold union. tauto. Qed.

(* 分配律：∩ 对 ∪（书 Prop 4.1.8a） *)
Theorem inter_distrib : forall (R S T : pset) x,
  inter R (union S T) x <-> union (inter R S) (inter R T) x.
Proof. intros R S T x. unfold inter, union. tauto. Qed.

(* De Morgan：补（书 Prop 4.1.10）。
   注意：补(交) = 并(补) 的 -> 方向本质经典（¬(A∧B) ⊢ ¬A∨¬B 直觉主义不成立），
   书的证明正用经典 PL 的 DeM 替换规则；这里如实记账（Print Assumptions 见 classic）。 *)
Theorem demorgan_inter : forall (U S T : pset) x,
  compl U (inter S T) x <-> union (compl U S) (compl U T) x.
Proof.
  intros U S T x. unfold compl, inter, union.
  destruct (classic (S x)); destruct (classic (T x)); tauto.
Qed.

Theorem demorgan_union : forall (U S T : pset) x,
  compl U (union S T) x <-> inter (compl U S) (compl U T) x.
Proof. intros U S T x. unfold compl, inter, union. tauto. Qed.

(* 吸收律与序（书 Prop 4.1.9）：S∩T 是含于两者的最大者 *)
Theorem inter_max : forall R S T : pset,
  sub R S -> sub R T -> sub R (inter S T).
Proof. intros R S T H1 H2 x Hx. split; [apply H1|apply H2]; assumption. Qed.

(* 外延原理（书 Defn 4.1.1 + Prop 4.1.1）：互相包含即逐点等值 *)
Theorem ext_eq : forall S T : pset,
  sub S T -> sub T S -> forall x, S x <-> T x.
Proof.
  intros S T H1 H2 x. split; [apply H1|apply H2]; assumption.
Qed.

(* ---------- 2. 幂集与笛卡尔积的列表实现 ---------- *)

Fixpoint powl (l : list nat) : list (list nat) :=
  match l with
  | [] => [[]]
  | a :: t => map (fun x => a :: x) (powl t) ++ powl t
  end.

(* |P(S)| = 2^|S|（书例 4.2.6：{1,2,3} 的 8 个子集） *)
Theorem powl_len : forall l, length (powl l) = 2 ^ length l.
Proof.
  induction l as [|a t IH]; simpl.
  - reflexivity.
  - rewrite length_app, length_map, IH.
    simpl. lia.
Qed.

(* 幂集可靠性：列出的每个元素都是子列表 *)
Theorem powl_sound : forall l x, In x (powl l) -> forall e, In e x -> In e l.
Proof.
  induction l as [|a t IH]; intros x Hin e He.
  - destruct Hin as [Hx|[]]. subst x. simpl in He. contradiction.
  - simpl in Hin. apply in_app_or in Hin.
    destruct Hin as [Hin|Hin].
    + apply in_map_iff in Hin. destruct Hin as [y [Hy Hin]].
      subst x. destruct He as [He|He].
      * left. exact He.
      * right. apply (IH y Hin). assumption.
    + right. apply (IH x Hin). assumption.
Qed.

Fixpoint prodl (s t : list nat) : list (nat * nat) :=
  match s with
  | [] => []
  | a :: s' => map (fun b => (a, b)) t ++ prodl s' t
  end.

(* 乘法计数原理（书 Prop 4.3.1a）：|S×T| = |S|·|T| *)
Theorem prodl_len : forall s t, length (prodl s t) = length s * length t.
Proof.
  induction s as [|a s' IH]; intros t; simpl.
  - reflexivity.
  - rewrite length_app, length_map, IH. lia.
Qed.

Theorem prodl_in : forall s t p,
  In p (prodl s t) <-> In (fst p) s /\ In (snd p) t.
Proof.
  induction s as [|a s' IH]; intros t p.
  - simpl. tauto.
  - destruct p as [x y]. cbn [prodl]. split.
    + intro H. apply in_app_or in H.
      destruct H as [H|H].
      * apply in_map_iff in H. destruct H as [b [Hb Ht]].
        injection Hb as H1 H2. subst x. subst y.
        split. left. reflexivity. exact Ht.
      * specialize (IH t (x,y)) as Hif.
        apply (proj1 Hif) in H.
        destruct H as [H1 H2].
        split. right. exact H1. exact H2.
    + intros [Hx Hy].
      destruct Hx as [Ha|Hs].
      * subst a. apply in_or_app. left. apply in_map. assumption.
      * apply in_or_app. right.
        specialize (IH t (x,y)) as Hif.
        apply (proj2 Hif).
        split; assumption.
Qed.

(* ---------- 3. 组合数与 Σ C(n,k) = 2^n（书 Prop 4.4.1 系） ---------- *)

Fixpoint choose (n k : nat) : nat :=
  match n, k with
  | 0, 0 => 1
  | 0, S _ => 0
  | S n', 0 => 1
  | S n', S k' => choose n' k' + choose n' (S k')
  end.

Fixpoint sumchoose (n k : nat) : nat :=
  match k with
  | 0 => choose n 0
  | S k' => sumchoose n k' + choose n (S k')
  end.

(* 出界组合数为零：C(n,k) = 0 当 k > n *)
Lemma choose_gt : forall n k, n < k -> choose n k = 0.
Proof.
  induction n as [|n IHn]; intros k Hk.
  - destruct k as [|k']; [lia|reflexivity].
  - destruct k as [|k']; [lia|].
    cbn [choose].
    rewrite IHn by lia. rewrite IHn by lia. reflexivity.
Qed.

Lemma choose_n0 : forall n, choose n 0 = 1.
Proof. destruct n; reflexivity. Qed.

(* 平移引理：Σ_{j<=S m} C(S n, j) = Σ_{j<=m} C(n,j) + Σ_{j<=S m} C(n,j) *)
Lemma sumchoose_shift : forall n m,
  sumchoose (S n) (S m) = sumchoose n m + sumchoose n (S m).
Proof.
  intros n m. induction m as [|m IHm].
  - cbn [sumchoose choose]. rewrite !choose_n0. lia.
  - change (sumchoose (S n) (S (S m))) with (sumchoose (S n) (S m) + choose (S n) (S (S m))).
    change (sumchoose n (S (S m))) with (sumchoose n (S m) + choose n (S (S m))).
    change (sumchoose n (S m)) with (sumchoose n m + choose n (S m)) in *.
    rewrite IHm.
    cbn [choose].
    lia.
Qed.

(* Σ_{k<=n} C(n,k) = 2^n：k-子集个数按 k 求和 = 幂集大小（书例 4.2.6+Prop 4.4.1） *)
Theorem sumchoose_pow : forall n, sumchoose n n = 2 ^ n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - rewrite sumchoose_shift, IH.
    cbn [sumchoose].
    assert (Hz : choose n (S n) = 0) by (apply choose_gt; lia).
    rewrite Hz.
    assert (Hp : 2 ^ S n = 2 * 2 ^ n) by reflexivity.
    lia.
Qed.

(* C(n,k) 的阶乘公式：choose n k * k! * (n-k)! = n!（书 Prop 4.4.1）
   —— 这里证等价的乘积形态，factorial 自带 *)
Fixpoint nfact (n : nat) : nat :=
  match n with 0 => 1 | S m => S m * nfact m end.

(* C(n,k) 的阶乘公式 C(n,k)·k!·(n−k)! = n!（书 Prop 4.4.1）
   —— 双层归纳（对 n 外层、k 内层）在边界 j = n 处需要分类讨论，
   本教程按「诚实止步」记为文档级定理：证明思路在 docs 讲清，
   机器面由下面的 Compute 数值验证（C(12,5)·5!·7! = 12!）。 *)

(* ---------- 4. 容斥原理（书 Prop 4.5.2 与 Thm 4.5.1 三集合） ---------- *)

(* 二集合版：全部写成加法形态避开 nat 减法
   |p∪q| + |p∧q| = |p| + |q| *)
Theorem incexc2 : forall (P Q : nat -> bool) l,
  length (filter (fun x => P x || Q x) l)
  + length (filter (fun x => P x && Q x) l)
  = length (filter P l) + length (filter Q l).
Proof.
  intros P Q l. induction l as [|a l IH]; simpl.
  - reflexivity.
  - destruct (P a); destruct (Q a); cbn [filter length orb andb]; lia.
Qed.

(* 三集合容斥（加法形态）：
   |P∪Q∪R| + |P∧Q| + |P∧R| + |Q∧R| = |P| + |Q| + |R| + |P∧Q∧R| *)
Theorem incexc3 : forall (P Q R : nat -> bool) l,
  length (filter (fun x => (P x || Q x) || R x) l)
  + length (filter (fun x => P x && Q x) l)
  + length (filter (fun x => P x && R x) l)
  + length (filter (fun x => Q x && R x) l)
  = length (filter P l) + length (filter Q l) + length (filter R l)
    + length (filter (fun x => (P x && Q x) && R x) l).
Proof.
  intros P Q R l. induction l as [|a l IH]; simpl.
  - reflexivity.
  - destruct (P a); destruct (Q a); destruct (R a); cbn [filter length orb andb]; lia.
Qed.

(* ---------- 5. 冒烟与账本 ---------- *)

Compute (powl [1;2;3]).        (* 书例 4.2.6 的 8 个子集 *)
Compute (length (powl [1;2;3]), 2 ^ 3).
Compute (length (prodl [1;2;3;5] [1;3;4]), 4 * 3).  (* 书例 4.3.2a 的 12 点 *)
Compute (sumchoose 10 10, 2 ^ 10).
Compute (choose 12 5).         (* C(12,5) = 792；书例 4.3.6 的 95040 是 P(12,5) *)
Compute (choose 6 2 * nfact 2 * nfact 4, nfact 6).  (* 阶乘公式的数值验证：720 = 720 *)
(* 注意：Coq 的 nat 是一进制的，12! = 479001600 的直接 Compute 会栈溢出，
   所以数值验证用 C(6,2)·2!·4! = 6! 的小规模版本 *)

Print Assumptions powl_len.
Print Assumptions prodl_len.
Print Assumptions sumchoose_pow.
Print Assumptions incexc2.
Print Assumptions incexc3.
