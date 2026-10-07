(* ex51 —— 图论专题（Jongsma ch8）
   handshake —— 握手引理（书 Prop 8.1.1）：度数和 = 2×边数，
           对边表归纳的真证明；哥尼斯堡四奇点（书例 8.1.1：5,3,3,3）；
   inequal —— 平面性的算术面（书 §8.3）：K5 破坏边-顶点不等式
           E ≤ 3(V-2)（Thm 8.3.2），K3,3 破坏二部广义版
           E ≤ 2(V-2)（Thm 8.3.3）——边数都是 Compute 实数；
   ham —— Hamilton 圈检查器 isHamCyc（相邻皆边+每点恰一次+首尾
           相接），C5/K5 实例验证（书例 8.2.2）；不存在性
           （K3,3 / Petersen）由 Prolog 通道穷举；
   greedy —— 首适贪心着色（书 §8.4.6 / Ex 8.4.21）：合法性与
           「色号 ≤ 已着色邻居数」两定理——即 χ ≤ Δ+1 的机器核；
           Petersen 三色实例（χ=3，书例 8.4.4c）。
   搜索型结果（Euler 回路找迹 / Ham 圈穷举 / χ 精确值）在
   Prolog 通道 ex51_graphs.pl。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 1. 握手引理（书 Prop 8.1.1） ---------- *)

Definition lsum (l : list nat) : nat := fold_right Nat.add 0 l.

Lemma lsum_cons : forall x l, lsum (x :: l) = x + lsum l.
Proof. reflexivity. Qed.

(* 度数：边表递归（多重图标准口径——自环两端各计一次）。
   这样 vdeg_cons 成为定义方程，握手引理无需简单图假设 *)
Fixpoint vdeg (v : nat) (E : list (nat * nat)) : nat :=
  match E with
  | [] => 0
  | (a, b) :: E' => vdeg v E' + (if Nat.eqb v a then 1 else 0)
                              + (if Nat.eqb v b then 1 else 0)
  end.

Lemma vdeg_cons : forall v a b E,
    vdeg v ((a,b) :: E)
    = vdeg v E + (if Nat.eqb v a then 1 else 0) + (if Nat.eqb v b then 1 else 0).
Proof. reflexivity. Qed.

Lemma lsum_map_add3 : forall (f g h : nat -> nat) vs,
    lsum (map (fun v => f v + g v + h v) vs)
    = lsum (map f vs) + lsum (map g vs) + lsum (map h vs).
Proof.
  intros f g h vs; induction vs as [|x vs IH];
    unfold lsum in *; simpl in *; [reflexivity|]; lia.
Qed.

Lemma lsum_zero : forall (vs : list nat),
    lsum (map (fun v => vdeg v []) vs) = 0.
Proof.
  induction vs as [|x vs IH]; [reflexivity|].
  change (map (fun v => vdeg v []) (x :: vs))
    with (vdeg x [] :: map (fun v => vdeg v []) vs).
  rewrite lsum_cons.
  change (vdeg x []) with 0.
  rewrite IH. reflexivity.
Qed.

(* NoDup 保证顶点不重计：标记函数的和恰为 1 或 0。
   证明纪律：只用 cbn [map] 保持 lsum 折叠形——IH 才能改写命中 *)
Lemma sum_tag_zero : forall a vs, ~ In a vs ->
    lsum (map (fun v => if Nat.eqb v a then 1 else 0) vs) = 0.
Proof.
  intros a vs; induction vs as [|x vs IH]; intros Hnin.
  - reflexivity.
  - cbn [map]. destruct (Nat.eqb x a) eqn:E.
    + apply Nat.eqb_eq in E. subst x.
      exfalso; apply Hnin; left; reflexivity.
    + assert (Ht : ~ In a vs) by (intro Hc; apply Hnin; right; exact Hc).
      rewrite lsum_cons. rewrite IH by exact Ht. reflexivity.
Qed.

Lemma sum_tag_one : forall a vs, NoDup vs -> In a vs ->
    lsum (map (fun v => if Nat.eqb v a then 1 else 0) vs) = 1.
Proof.
  intros a vs; induction vs as [|x vs IH]; intros Hnd Hin.
  - contradiction.
  - inversion Hnd as [|? ? Hnin Hnd']; subst.
    cbn [map]. destruct Hin as [Ha | Hin].
    + subst x. rewrite lsum_cons, Nat.eqb_refl, (sum_tag_zero a vs Hnin).
      reflexivity.
    + destruct (Nat.eqb x a) eqn:E.
      * apply Nat.eqb_eq in E.
        subst x.
        exfalso.
        apply Hnin.
        assumption.
      * rewrite lsum_cons. rewrite IH by assumption. reflexivity.
Qed.

(* 握手引理：顶点覆盖所有边端 ⇒ Σdeg = 2·|E|（书 Prop 8.1.1） *)
Theorem handshake : forall E vs,
    NoDup vs -> (forall a b, In (a,b) E -> In a vs /\ In b vs) ->
    lsum (map (fun v => vdeg v E) vs) = 2 * length E.
Proof.
  induction E as [|[a b] E' IH]; intros vs Hnd Hcov.
  - rewrite lsum_zero. reflexivity.
  - assert (Hin : In a vs /\ In b vs) by (apply Hcov; left; reflexivity).
    destruct Hin as [Ha Hb].
    rewrite (map_ext_in (fun v => vdeg v ((a,b)::E'))
                        (fun v => vdeg v E'
                                 + (if Nat.eqb v a then 1 else 0)
                                 + (if Nat.eqb v b then 1 else 0)))
      by (intros v _; apply vdeg_cons).
    rewrite lsum_map_add3.
    rewrite (sum_tag_one a vs Hnd Ha).
    rewrite (sum_tag_one b vs Hnd Hb).
    assert (Hcov' : forall a0 b0, In (a0, b0) E' -> In a0 vs /\ In b0 vs)
      by (intros a0 b0 Hin0; apply Hcov; right; exact Hin0).
    rewrite (IH vs Hnd Hcov'). simpl. lia.
Qed.

(* ---------- 2. 现场一：哥尼斯堡七桥（书例 8.1.1/8.1.2） ---------- *)
(* A=0 B=1 C=2 D=3；两对平行桥如实入表（多重图的边表化身） *)
Definition KonE : list (nat * nat) :=
  [(0,1);(0,1);(0,2);(0,2);(0,3);(1,3);(2,3)].

Lemma Kon_degrees :
    map (fun v => vdeg v KonE) (seq 0 4) = [5;3;3;3].
Proof. reflexivity. Qed.

(* 四个奇点：Euler 回路的必要条件（每点偶度，书 §8.1.4）不满足 *)
Lemma Kon_four_odd :
    length (filter Nat.odd [5;3;3;3]) = 4.
Proof. reflexivity. Qed.

(* 握手引理的实例对账：20 = 2 × 10？——哥尼斯堡是 7 条边 *)
Lemma Kon_handshake :
    lsum (map (fun v => vdeg v KonE) (seq 0 4)) = 2 * 7.
Proof. reflexivity. Qed.

(* ---------- 3. 现场二：平面性的算术面（书 §8.3） ---------- *)

Definition K5E : list (nat * nat) :=
  [(0,1);(0,2);(0,3);(0,4);(1,2);(1,3);(1,4);(2,3);(2,4);(3,4)].

Definition K33E : list (nat * nat) :=
  [(0,3);(0,4);(0,5);(1,3);(1,4);(1,5);(2,3);(2,4);(2,5)].

(* K5：V=5 E=10，边-顶点不等式 E ≤ 3(V-2) 要求 10 ≤ 9 —— 破坏
   ⇒ 非平面（书 Thm 8.3.2 的用法，例 8.3.4a） *)
Lemma K5_beats_ineq : 3 * (5 - 2) < length K5E.
Proof. cbv. lia. Qed.

(* K3,3：V=6 E=9，二部（无三角形）广义不等式 E ≤ 2(V-2) 要求
   9 ≤ 8 —— 破坏 ⇒ 非平面（书 Thm 8.3.3，例 8.3.4b；
   Kuratowski 定理的两个障碍物在此会师，Thm 8.3.4） *)
Lemma K33_beats_bip : 2 * (6 - 2) < length K33E.
Proof. cbv. lia. Qed.

(* K5 满足握手引理：每点度 4，Σ = 20 = 2×10 *)
Lemma K5_handshake :
    lsum (map (fun v => vdeg v K5E) (seq 0 5)) = 2 * 10.
Proof. reflexivity. Qed.

(* ---------- 4. Hamilton 圈检查器（书例 8.2.2） ---------- *)

Definition adjb (E : list (nat * nat)) (u v : nat) : bool :=
  existsb (fun e => (Nat.eqb u (fst e) && Nat.eqb v (snd e))
                    || (Nat.eqb v (fst e) && Nat.eqb u (snd e))) E.

Fixpoint adjchain (adj : nat -> nat -> bool) (l : list nat) : bool :=
  match l with
  | [] => true
  | x :: t => match t with
              | [] => true
              | y :: _ => adj x y && adjchain adj t
              end
  end.

Fixpoint lastl (d : nat) (l : list nat) : nat :=
  match l with [] => d | x :: t => lastl x t end.

(* 合法 Hamilton 圈：长 n、无重复（nodup 等长）、链上相邻皆边、首尾相接 *)
Definition isHamCyc (adj : nat -> nat -> bool) (n : nat) (l : list nat) : bool :=
  (length l =? n)
  && (length (nodup Nat.eq_dec l) =? n)
  && adjchain adj l
  && adj (lastl 0 l) (hd 0 l).

Definition C5E : list (nat * nat) :=
  [(0,1);(1,2);(2,3);(3,4);(4,0)].

(* C5 的外圈就是自身的 Hamilton 圈；K5 同理（书例 8.2.2a） *)
Lemma C5_is_ham : isHamCyc (adjb C5E) 5 [0;1;2;3;4] = true.
Proof. reflexivity. Qed.

Lemma K5_is_ham : isHamCyc (adjb K5E) 5 [0;1;2;3;4] = true.
Proof. reflexivity. Qed.

(* 二部完全图的平衡判据（书 Ex 8.2.17）：K_m,n 有 Ham 圈 ⟺ m=n
   ——K3,3（3=3）有圈、K3,4（3≠4）无圈；不存在性穷举在 Prolog
   通道，此处给判据的算术面 *)
Lemma K33_unbalanced : 3 <> 4.
Proof. discriminate. Qed.

(* ---------- 5. 首适贪心着色（书 §8.4.6 / Ex 8.4.21） ---------- *)

(* 已着色邻居的色表：col 作用于 0..d-1 中 v 的邻居 *)
Definition nbcol (adj : nat -> nat -> bool) (col : nat -> nat)
                 (d v : nat) : list nat :=
  map col (filter (fun u => adj u v) (seq 0 d)).

(* 最小未用色：在 0..|L| 中取第一个不在 L 的颜色 *)
Definition pick (L : list nat) : nat :=
  hd 0 (filter (fun c => negb (existsb (Nat.eqb c) L))
               (seq 0 (S (length L)))).

Lemma pick_notin : forall L, ~ In (pick L) L.
Proof.
  intros L. unfold pick.
  destruct (filter (fun c => negb (existsb (Nat.eqb c) L))
                   (seq 0 (S (length L)))) as [|c tl] eqn:F.
  - exfalso.
    (* 滤空不可能：S|L| 个互异候选不可能全落在 |L| 元的表里 *)
    assert (Hincl : incl (seq 0 (S (length L))) L).
    { intros x Hx.
      destruct (existsb (Nat.eqb x) L) eqn:Hex.
      - apply existsb_exists in Hex.
        destruct Hex as [y [Hy Hye]].
        apply Nat.eqb_eq in Hye. subst y. exact Hy.
      - assert (HinF : In x (filter (fun c0 => negb (existsb (Nat.eqb c0) L))
                                    (seq 0 (S (length L))))).
        { apply filter_In. split; [exact Hx | rewrite Hex; reflexivity]. }
        rewrite F in HinF. contradiction. }
    assert (Hnd : NoDup (seq 0 (S (length L)))) by apply seq_NoDup.
    pose proof (NoDup_incl_length Hnd Hincl) as Hlen.
    rewrite length_seq in Hlen. lia.
  - simpl.
    assert (Hc1 : In c (filter (fun c0 => negb (existsb (Nat.eqb c0) L))
                               (seq 0 (S (length L)))))
      by (rewrite F; left; reflexivity).
    apply filter_In in Hc1. destruct Hc1 as [_ Htrue].
    intro Hc2.
    assert (Hex : existsb (Nat.eqb c) L = true).
    { apply (proj2 (existsb_exists (Nat.eqb c) L)).
      exists c. split; [assumption | apply Nat.eqb_refl]. }
    rewrite Hex in Htrue. discriminate.
Qed.

Lemma pick_le : forall L, pick L <= length L.
Proof.
  intros L. unfold pick.
  destruct (filter (fun c => negb (existsb (Nat.eqb c) L))
                   (seq 0 (S (length L)))) as [|c tl] eqn:F.
  - simpl. lia.
  - simpl.
    assert (Hc1 : In c (filter (fun c0 => negb (existsb (Nat.eqb c0) L))
                               (seq 0 (S (length L)))))
      by (rewrite F; left; reflexivity).
    apply filter_In in Hc1. destruct Hc1 as [Hin _].
    apply in_seq in Hin. lia.
Qed.

(* 贪心主定义：按顶点号 0,1,2,… 依次上色；col 为 0..d-1 的着色 *)
Fixpoint greedy (adj : nat -> nat -> bool) (d : nat) : nat -> nat :=
  match d with
  | 0 => fun v => 0
  | S d' => let col := greedy adj d' in
            fun v => if Nat.ltb v d' then col v
                     else pick (nbcol adj col d' v)
  end.

(* 步进引理：给当前层顶点上色 = 取其邻色表的最小未用色 *)
Lemma greedy_self : forall adj d',
    greedy adj (S d') d' = pick (nbcol adj (greedy adj d') d' d').
Proof.
  intros adj d'. cbn [greedy].
  destruct (Nat.ltb_spec d' d') as [Hlt | Hge]; [lia | reflexivity].
Qed.

(* 合法性：对称 + 无自环的邻接下，相邻两点异色 *)
Theorem greedy_valid : forall adj,
    (forall u v, adj u v = adj v u) ->
    (forall v, adj v v = false) ->
    forall d i j, i < d -> j < d -> adj i j = true ->
    greedy adj d i <> greedy adj d j.
Proof.
  intros adj Hsym Hirr. induction d as [|d' IH]; intros i j Hi Hj Haij.
  - lia.
  - set (col := greedy adj d').
    destruct (Nat.ltb_spec i d') as [Hi' | Hi']; destruct (Nat.ltb_spec j d') as [Hj' | Hj'].
    + (* 两点都已着色：归纳假设 *)
      change (greedy adj (S d') i) with (if Nat.ltb i d' then col i else pick (nbcol adj col d' i)).
      change (greedy adj (S d') j) with (if Nat.ltb j d' then col j else pick (nbcol adj col d' j)).
      rewrite (proj2 (Nat.ltb_lt i d') Hi'), (proj2 (Nat.ltb_lt j d') Hj').
      apply IH; assumption.
    + (* j = d' 刚上色：col i 在其邻色表里，pick 避开 *)
      assert (Hji : j = d') by lia. subst j.
      change (greedy adj (S d') i) with (if Nat.ltb i d' then col i else pick (nbcol adj col d' i)).
      rewrite (proj2 (Nat.ltb_lt i d') Hi').
      rewrite greedy_self.
      intro Heq.
      assert (Hni : ~ In (col i) (nbcol adj col d' d')).
      { intro Hin. rewrite Heq in Hin. exact (pick_notin _ Hin). }
      apply Hni. unfold nbcol.
      apply in_map. apply filter_In. split.
      * apply in_seq. lia.
      * exact Haij.
    + (* i = d'：对称，用邻接的对称性 *)
      assert (Hij : i = d') by lia. subst i.
      change (greedy adj (S d') j) with (if Nat.ltb j d' then col j else pick (nbcol adj col d' j)).
      rewrite (proj2 (Nat.ltb_lt j d') Hj').
      rewrite greedy_self.
      intro Heq.
      assert (Hnj : ~ In (col j) (nbcol adj col d' d')).
      { intro Hin. rewrite <- Heq in Hin. exact (pick_notin _ Hin). }
      apply Hnj. unfold nbcol.
      apply in_map. apply filter_In. split.
      * apply in_seq. lia.
      * rewrite Hsym. exact Haij.
    + (* i = j = d'：自环与无自环假设矛盾 *)
      assert (Hij : i = d') by lia. subst i.
      assert (Hjj : j = d') by lia. subst j.
      rewrite Hirr in Haij. discriminate.
Qed.

(* 色号上界：v 的色 ≤ v 的已着色邻居数 ≤ deg(v)——χ ≤ Δ+1 的机器核 *)
Definition vdegA (adj : nat -> nat -> bool) (d v : nat) : nat :=
  length (filter (fun u => adj u v) (seq 0 d)).

Theorem greedy_chroma : forall adj d v,
    v < d -> greedy adj d v <= vdegA adj d v.
Proof.
  intros adj. induction d as [|d' IH]; intros v Hv.
  - lia.
  - destruct (Nat.ltb_spec v d') as [Hv' | Hv'].
    + assert (Hle : vdegA adj d' v <= vdegA adj (S d') v).
      { unfold vdegA. rewrite seq_S, filter_app, length_app. lia. }
      change (greedy adj (S d') v) with (if Nat.ltb v d' then greedy adj d' v else pick (nbcol adj (greedy adj d') d' v)).
      rewrite (proj2 (Nat.ltb_lt v d') Hv').
      pose proof (IH v Hv'). lia.
    + assert (Hvq : v = d') by lia.
      rewrite Hvq.
      rewrite greedy_self.
      pose proof (pick_le (nbcol adj (greedy adj d') d' d')) as Hp.
      unfold nbcol in Hp.
      rewrite length_map in Hp.
      unfold nbcol, vdegA.
      rewrite seq_S, filter_app, length_app.
      set (P := pick (map (greedy adj d')
                     (filter (fun u : nat => adj u d') (seq 0 d')))) in *.
      set (A := length (filter (fun u : nat => adj u d') (seq 0 d'))) in *.
      set (B := length (filter (fun u : nat => adj u d') [d'])) in *.
      lia.
Qed.

(* ---------- 6. 现场三：Petersen 图（书例 8.4.4c：χ=3） ---------- *)
(* 外五边形 0-1-2-3-4；辐条 i-i+5；内五星 5-7,7-9,9-6,6-8,8-5 *)
Definition PetE : list (nat * nat) :=
  [(0,1);(1,2);(2,3);(3,4);(4,0);
   (0,5);(1,6);(2,7);(3,8);(4,9);
   (5,7);(7,9);(9,6);(6,8);(8,5)].

Lemma Pet_handshake :
    lsum (map (fun v => vdeg v PetE) (seq 0 10)) = 2 * 15.
Proof. reflexivity. Qed.

(* 首适贪心在顶点自然序下的 Petersen 着色：全表 ≤ 2（χ=3 的上界侧；
   下界侧——无 2 着色（含奇圈 C5）——由 Prolog 通道穷举） *)
Compute (map (greedy (adjb PetE) 10) (seq 0 10)).

(* 输出着色对每条边异色（合法性检查的数值面） *)
Compute (forallb (fun e => negb (Nat.eqb
           (greedy (adjb PetE) 10 (fst e))
           (greedy (adjb PetE) 10 (snd e))) ) PetE).

(* ---------- 7. 冒烟与账本 ---------- *)

Compute (map (fun v => vdeg v KonE) (seq 0 4)).  (* 5,3,3,3 *)
Compute (length K5E, length K33E).                (* 10, 9 *)
Compute (greedy (adjb K5E) 5 0).                  (* 0 —— K5 从 0 号起 *)

Print Assumptions handshake.
Print Assumptions greedy_valid.
Print Assumptions greedy_chroma.
Print Assumptions pick_notin.
Print Assumptions C5_is_ham.
