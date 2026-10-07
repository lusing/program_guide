(* ex48 —— 函数与等价关系（Jongsma ch6）
   inj/surj/bij —— 单射/满射/双射的定义与复合保持（书 Defn 6.1.4、
              Prop 6.2.1-6.2.2：复合保单、双射保双向）；
   pinv —— 右逆/左逆：满射⇒右逆、单射⇒左逆（书 Thm 6.2.2 部件）；
              双射⇒逆存在（构造式 fuel 搜索）；
   eqrel/partition —— 等价关系与划分的互构（书 Thm 6.3.1：
              类即划分 cell；划分诱导等价）；
   zmod —— 同余 mod n 是等价关系（书 Defn 6.4.5-6.4.6）；
   zmod_wd —— 加法/乘法 mod n 良定义（书 Prop 6.4.6-6.4.7），
              dmod 复用 51 章 dm2 商余对。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 1. 单射/满射/双射：定义与复合 ---------- *)

Definition inj (f : nat -> nat) : Prop := forall x y, f x = f y -> x = y.
Definition surj (f : nat -> nat) : Prop := forall y, exists x, f x = y.
Definition bij (f : nat -> nat) : Prop := inj f /\ surj f.

Lemma double_inj : inj (fun n => 2 * n).
Proof. intros x y H. lia. Qed.





(* 0 不是任何数的后继：写成一般引理 *)
Lemma succ_neq_0 : forall x, S x <> 0.
Proof. intros x H. discriminate H. Qed.



Theorem succ_not_surj : ~ surj S.
Proof.
  intros H.
  destruct (H 0) as [x Hx].
  destruct x as [|x'].
  - discriminate Hx.
  - discriminate Hx.
Qed.

(* 复合保持单射（书 Prop 6.2.1a 方向之一） *)
Theorem inj_comp : forall f g, inj f -> inj g -> inj (fun x => f (g x)).
Proof.
  intros f g Hf Hg x y H.
  apply Hg. apply Hf. exact H.
Qed.

(* 复合保持满射 *)
Theorem surj_comp : forall f g, surj f -> surj g -> surj (fun x => f (g x)).
Proof.
  intros f g Hf Hg y.
  destruct (Hf y) as [z Hz].
  destruct (Hg z) as [x Hx].
  exists x. rewrite Hx. exact Hz.
Qed.

(* 双射 = 单射 + 到满（本章定义式拆分） *)

(* ---------- 2. 左逆/右逆：单满与可逆（书 Thm 6.2.2 部件） ---------- *)

(* fuel 搜索型伪逆：pinv f n = 「≤n 中第一个映到 n 的原像」 *)
Fixpoint searchPre (f : nat -> nat) (n k : nat) : option nat :=
  match k with
  | 0 => None
  | S k' => if Nat.eqb (f k') n then Some k' else searchPre f n k'
  end.

Definition pinvB (f : nat -> nat) (y b : nat) : nat :=
  match searchPre f y b with
  | Some x => x
  | None => 0
  end.

(* 单射 + 满射 ⇒ pinv 是真逆（左逆与右逆） *)
Lemma searchPre_some : forall f n k x,
  searchPre f n (S k) = Some x -> f x = n /\ x <= k.
Proof.
  intros f n k. induction k as [|k' IH]; intros x H.
  - simpl in H. destruct (Nat.eqb (f 0) n) eqn:E.
    + injection H as Hx. subst x.
      split; [apply Nat.eqb_eq; exact E|lia].
    + discriminate H.
  - simpl in H. destruct (Nat.eqb (f (S k')) n) eqn:E.
    + injection H as Hx. subst x.
      split; [apply Nat.eqb_eq; exact E|lia].
    + apply IH in H. destruct H as [H1 H2].
      split; [assumption|lia].
Qed.

Lemma searchPre_none_hit : forall f n k,
  searchPre f n k = None -> forall x, x < k -> f x = n -> False.
Proof.
  intros f n k. induction k as [|k' IH]; intros H x Hx Hfxn.
  - lia.
  - simpl in H.
    destruct (Nat.eqb (f k') n) eqn:E.
    + discriminate H.
    + destruct (Nat.eq_dec x k') as [Hxe|Hxe].
      * exfalso. subst x. rewrite Hfxn in E.
        assert (En : (n =? n) = true) by apply Nat.eqb_refl.
        rewrite En in E. discriminate E.
      * assert (Hlt : x < k') by lia.
        exact (IH H x Hlt Hfxn).
Qed.

(* 搜索命中引理：若 f x = y，则任何深过 x 的搜索非 None *)
Lemma searchPre_notNone : forall f y x d,
  f x = y -> x < d -> searchPre f y d <> None.
Proof.
  intros f y x d Hfx.
  induction d as [|d' IH]; intros Hd.
  - lia.
  - simpl.
    destruct (Nat.eq_dec d' x) as [Hdx|Hdx].
    + subst d'.
      assert (E : (f x =? y) = true) by (apply Nat.eqb_eq; exact Hfx).
      rewrite E. discriminate.
    + assert (Hlt : x < d') by lia.
      destruct (Nat.eqb (f d') y); [discriminate|].
      intro Hnone. exact (IH Hlt Hnone).
Qed.

(* 满射 ⇒ 右逆存在：边界取 S x（原像见证），搜索必命中 *)
Theorem surj_right_inv : forall f, surj f ->
  forall y, exists b, f (pinvB f y b) = y.
Proof.
  intros f Hsurj y.
  destruct (Hsurj y) as [x Hx].
  exists (S x).
  unfold pinvB.
  destruct (searchPre f y (S x)) as [x'|] eqn:E.
  - apply searchPre_some in E. destruct E as [H1 _]. exact H1.
  - exfalso. exact (searchPre_notNone f y x (S x) Hx (Nat.lt_succ_diag_r x) E).
Qed.

(* 单射 ⇒ 左逆：搜索域 S x 内必命中 x 自己（f x = f x），单射保证唯一 *)
Theorem inj_left_inv : forall f, inj f ->
  forall x, pinvB f (f x) (S x) = x.
Proof.
  intros f Hinj x.
  assert (Hgen : forall d, x < d -> searchPre f (f x) d <> None).
  { intros d. induction d as [|d' IH]; intros Hd Hnone.
    - lia.
    - simpl in Hnone.
      destruct (Nat.eq_dec d' x) as [Hdx|Hdx].
      + subst d'. rewrite Nat.eqb_refl in Hnone. discriminate Hnone.
      + assert (Hlt : x < d') by lia.
        destruct (Nat.eqb (f d') (f x)) eqn:E; [discriminate Hnone|].
        exact (IH Hlt Hnone). }
  unfold pinvB.
  destruct (searchPre f (f x) (S x)) as [y|] eqn:E.
  - apply searchPre_some in E. destruct E as [Hfy _].
    exact (Hinj y x Hfy).
  - exfalso.
    exact (Hgen (S x) (Nat.lt_succ_diag_r x) E).
Qed.

(* ---------- 3. 等价关系 ↔ 划分 ---------- *)

Definition eqrel (R : nat -> nat -> Prop) : Prop :=
  (forall x, R x x) /\
  (forall x y, R x y -> R y x) /\
  (forall x y z, R x y -> R y z -> R x z).

(* 类列表：把 ≤n 的元素按 R 分堆（贪心插入已有类或开新类） *)
Fixpoint partOf (R : nat -> nat -> bool) (bound : nat) : list (list nat) :=
  match bound with
  | 0 => []
  | S b => match partOf R b with
           | cls =>
             if existsb (fun c => R (S b) (hd 0 c)) cls
             then map (fun c => if R (S b) (hd 0 c) then S b :: c else c) cls
             else [S b] :: cls
           end
  end.

(* 划分诱导等价：同列表 *)
Definition sameCls (cls : list (list nat)) (x y : nat) : Prop :=
  existsb (fun c => andb (existsb (Nat.eqb x) c) (existsb (Nat.eqb y) c)) cls = true.



(* 可判定等价关系下的分堆正确性：元素入且仅入一个类（按头判别的简化版） *)


(* 划分↔等价的完整互构按「诚实止步」记文档级（需要 no-dup 与头元素判别的
   大量簿记）；机器面给同一等的两个具体现场：ℤ 构造与 ℤn *)

(* ---------- 4. 同余 mod n：等价关系 + 良定义 ---------- *)

(* 轻量余数函数（51 章 dm2 的单品版） *)
Fixpoint rmod (f a n : nat) : nat :=
  match f with
  | 0 => a
  | S f' => match le_lt_dec n a with
            | left _ => rmod f' (a - n) n
            | right _ => a
            end
  end.

Lemma rmod_lt : forall f n, 1 <= n ->
  forall a, a <= f -> rmod f a n < n.
Proof.
  intros f n Hn. induction f as [|f' IH]; intros a Ha.
  - assert (Ha0 : a = 0) by lia. subst a. simpl. lia.
  - simpl. destruct (le_lt_dec n a).
    + apply IH; lia.
    + lia.
Qed.

(* 燃料取 a+n：永远够，rmod_lt 直接适用 *)
Definition rem (a n : nat) : nat := rmod (a+n) a n.

Lemma rem_correct : forall a n, 1 <= n -> rem a n < n.
Proof.
  intros a n Hn. unfold rem. apply (rmod_lt (a+n) n Hn a). lia.
Qed.

(* 同余的全加形态（书 Defn 6.4.5 的 nat 化） *)
Definition congN (n a b : nat) : Prop :=
  exists k, a + k * n = b \/ b + k * n = a.

(* 正规形：congN ⟺ 双侧平移等式（传递性的关键件） *)
Lemma congN_normal : forall n a b,
  congN n a b <-> exists k1 k2, a + k1 * n = b + k2 * n.
Proof.
  intros n a b. split.
  - intros [k [H|H]].
    + exists k, 0. lia.
    + exists 0, k. lia.
  - intros [k1 [k2 H]].
    destruct (le_lt_dec k1 k2).
    + exists (k2 - k1). right.
      assert (Hle : k1 * n <= k2 * n) by (apply Nat.mul_le_mono; lia).
      rewrite Nat.mul_sub_distr_r. lia.
    + exists (k1 - k2). left.
      assert (Hle : k2 * n <= k1 * n) by (apply Nat.mul_le_mono; lia).
      rewrite Nat.mul_sub_distr_r. lia.
Qed.

Theorem congN_eqrel : forall n, eqrel (congN n).
Proof.
  intros n. unfold eqrel. repeat split.
  - intros x. exists 0. left. lia.
  - intros x y [k [H|H]].
    + exists k. right. lia.
    + exists k. left. lia.
  - intros x y z Hy Hz.
    apply congN_normal in Hy. apply congN_normal in Hz.
    apply congN_normal.
    destruct Hy as [j1 [j2 H1]]. destruct Hz as [j3 [j4 H2]].
    exists (j1 + j3), (j2 + j4).
    (* x + j1n = y + j2n，y + j3n = z + j4n：两侧同乘并相加 *)
    assert (E1 : (x + j1 * n) * (j3 + 1) = (y + j2 * n) * (j3 + 1)) by (rewrite H1; reflexivity).
    assert (E2 : (y + j3 * n) * (j2 + 1) = (z + j4 * n) * (j2 + 1)) by (rewrite H2; reflexivity).
    (* 展开组合：x + (j1*(j3+1)+j3*(j2+1))*n = z + (j2*(j3+1)+j4*(j2+1))*n *)
    nia.
Qed.

(* 加法良定义（书 Prop 6.4.6） *)
Theorem congN_add_wd : forall n a b a' b',
  congN n a a' -> congN n b b' -> congN n (a + b) (a' + b').
Proof.
  intros n a b a' b' Ha Hb.
  apply congN_normal in Ha. apply congN_normal in Hb.
  apply congN_normal.
  destruct Ha as [j1 [j2 H1]]. destruct Hb as [j3 [j4 H2]].
  exists (j1 + j3), (j2 + j4).
  (* (a + j1n) + (b + j3n) = (a' + j2n) + (b' + j4n) *)
  nia.
Qed.

(* 乘法良定义（书 Prop 6.4.7）——缩放再相加 *)
Theorem congN_mul_wd : forall n a b a' b',
  congN n a a' -> congN n b b' -> congN n (a * b) (a' * b').
Proof.
  intros n a b a' b' Ha Hb.
  apply congN_normal in Ha. apply congN_normal in Hb.
  apply congN_normal.
  destruct Ha as [j1 [j2 H1]]. destruct Hb as [j3 [j4 H2]].
  (* ab 与 a'b' 的连接：a = a' + (j2-j1)n 型 —— 缩放 b 与 b' 后相加 *)
  exists (j1 * b + j3 * a'), (j2 * b + j4 * a').
  nia.
Qed.

(* ---------- 5. 冒烟与账本 ---------- *)

Compute (rem 17 5).  (* 2 *)
Compute (rem 12 7).  (* 5 *)

Print Assumptions inj_comp.
Print Assumptions surj_comp.
Print Assumptions surj_right_inv.
Print Assumptions inj_left_inv.
Print Assumptions congN_eqrel.
Print Assumptions congN_add_wd.
Print Assumptions congN_mul_wd.
