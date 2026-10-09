(* ex44 —— 递推、结构归纳与 Peano 算术（Jongsma §3.3-3.4）
   三条线：
     递推闭式 —— 书例 3.3.1/3.3.2 的裂项与回代直觉是文档级；
                  机器负责验证：aseq n = n^2+n+4、bseq n + 3 = 2^(n+2)；
     sumfib   —— Fibonacci 部分和 Σ F_i = F_{n+2} - 1（练习 3.3.6b）
                  的 nat 形态（+1 技巧）；
     结构归纳 —— 串=list 的 rev 双律与长度同态（书 Prop 3.3.1 镜像）；
                  wff 左括号数 = 连接词数（书例 3.3.6）；
                  唯一分解定理 = 构造子单射/互斥的免费礼物；
     sn PA    —— 自造后继结构：书的三条 FOL 公理里前两条
                  （S 非零、S 单射）在类型论里是 discriminate/injection
                  免费定理；加法按书定义（对第二参递归）证
                  0 单位元/1 交换/结合律/交换律/消去律（书 Prop 2-4 + 练习
                  11/12）；乘法分配律→1 单位→交换律（练习 16/18）；
                  <= 定义为 exists d, m+d=n（练习 20 起）：自反/传递/反对称
                  /完全性（练习 25/26）。归纳公理 = eliminator 的对照在 docs。 *)

From Stdlib Require Import List Arith Lia Psatz.
Import ListNotations.

(* ---------- 1. 递推闭式两例（机器验证） ---------- *)

Fixpoint pow2b (n : nat) : nat :=
  match n with
  | 0 => 1
  | S k => 2 * pow2b k
  end.

(* 书例 3.3.1：a0=4，a_k = a_{k-1} + 2k；裂项求和猜出 n^2+n+4 *)
Fixpoint aseq (n : nat) : nat :=
  match n with
  | 0 => 4
  | S k => aseq k + 2 * S k
  end.

Lemma aseq_closed : forall n, aseq n = n * n + n + 4.
Proof.
  induction n as [|k IH]; [reflexivity|].
  simpl.
  assert (E : S k * S k = k * k + 2 * k + 1) by ring.
  lia.
Qed.

(* 书例 3.3.2：a0=1，a_k = 2a_{k-1}+3；回代猜出 2^(n+2)-3，写成 +3 形态 *)
Fixpoint bseq (n : nat) : nat :=
  match n with
  | 0 => 1
  | S k => 2 * bseq k + 3
  end.

Lemma bseq_closed : forall n, bseq n + 3 = pow2b (n + 2).
Proof.
  induction n as [|k IH].
  - reflexivity.
  - simpl bseq.
    replace (S k + 2) with (S (k + 2)) by lia.
    simpl pow2b.
    lia.
Qed.

(* ---------- 2. Fibonacci 部分和（练习 3.3.6b） ---------- *)

Fixpoint fib (n : nat) : nat :=
  match n with
  | 0 => 0
  | S m => match m with
           | 0 => 1
           | S k => fib m + fib k
           end
  end.

Lemma fib_step2 : forall n, fib (n + 2) = fib (n + 1) + fib n.
Proof.
  intros n.
  replace (n + 2) with (S (S n)) by lia.
  replace (n + 1) with (S n) by lia.
  reflexivity.
Qed.

Lemma fib_stepS : forall n, fib (S (S n)) = fib (S n) + fib n.
Proof.
  intros n. reflexivity.
Qed.

Fixpoint sumfib (n : nat) : nat :=
  match n with
  | 0 => fib 0
  | S k => sumfib k + fib (S k)
  end.

(* 书写 Σ F_i = F_{n+2} - 1；nat 改写为 +1 形态 *)
Theorem sumfib_shift : forall n, sumfib n + 1 = fib (n + 2).
Proof.
  induction n as [|k IH].
  - reflexivity.
  - cbn [sumfib].
    replace (k + 2) with (S (S k)) in IH by lia.
    replace (S k + 2) with (S (S (S k))) by lia.
    rewrite fib_stepS.
    rewrite <- IH.
    lia.
Qed.

(* ---------- 3. 结构归纳：串=list ---------- *)

(* 书 Prop 3.3.1 的镜像：长度是拼接的同态 *)
Theorem app_len : forall s t : list nat,
  length (s ++ t) = length s + length t.
Proof.
  induction s as [|x s IH]; intros t; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

(* 结构归纳样板一：rev 与拼接的交换律 *)
Theorem rev_app_distr : forall s t : list nat,
  rev (s ++ t) = rev t ++ rev s.
Proof.
  induction s as [|x s IH]; intros t; simpl.
  - rewrite app_nil_r. reflexivity.
  - rewrite IH.
    (* rev t ++ (rev s ++ [x]) = (rev t ++ rev s) ++ [x] *)
    rewrite <- app_assoc. reflexivity.
Qed.

Theorem rev_invol : forall s : list nat, rev (rev s) = s.
Proof.
  induction s as [|x s IH]; simpl.
  - reflexivity.
  - rewrite rev_app_distr. simpl. rewrite IH. reflexivity.
Qed.

(* ---------- 4. 结构归纳：wff ---------- *)

(* 书 Def 3.3.4 的抽象骨架：变元为基，复合带括号 *)
Inductive wff : Type :=
| V : nat -> wff
| Neg : wff -> wff
| Conj : wff -> wff -> wff
| Imp : wff -> wff -> wff.

Fixpoint lp (f : wff) : nat :=
  match f with
  | V _ => 0
  | Neg g => S (lp g)
  | Conj g h => S (lp g + lp h)
  | Imp g h => S (lp g + lp h)
  end.

Fixpoint cn (f : wff) : nat :=
  match f with
  | V _ => 0
  | Neg g => S (cn g)
  | Conj g h => S (cn g + cn h)
  | Imp g h => S (cn g + cn h)
  end.

(* 书例 3.3.6：每个 wff 的左括号数 = 连接词数 *)
Theorem lp_cn : forall f, lp f = cn f.
Proof.
  induction f as [i|g IHg|g IHg h IHh|g IHg h IHh];
    simpl; lia.
Qed.

(* 唯一分解定理（书 Thm 3.3.2）的机器形态：
   构造子的单射与互斥在归纳类型里免费。 *)
Theorem conj_inj : forall a b c d : wff,
  Conj a b = Conj c d -> a = c /\ b = d.
Proof.
  intros a b c d H. injection H. auto.
Qed.

Theorem neg_conj_disj : forall a c d : wff,
  Neg a <> Conj c d.
Proof.
  intros a c d H. discriminate H.
Qed.

(* ---------- 5. Peano 算术：自造后继结构 ---------- *)

Inductive sn : Type :=
| z : sn
| s : sn -> sn.

(* 书公理 3.4.1（S 非零）与 3.4.2（S 单射）：
   PA 里是公理，归纳类型里是 discriminate/injection 免费定理 *)
Theorem s_nonzero : forall n, s n <> z.
Proof.
  intros n H. discriminate H.
Qed.

Theorem s_inj : forall m n, s m = s n -> m = n.
Proof.
  intros m n H. injection H. auto.
Qed.

(* 书 Def 3.4.1：加法对第二参递归——两条定义方程都是 rfl *)
Fixpoint sadd (a b : sn) : sn :=
  match b with
  | z => a
  | s k => s (sadd a k)
  end.

(* 书 Prop 3.4.2：0 是加法单位元（右单位是定义，左单位归纳） *)
Theorem sadd_0_l : forall n, sadd z n = n.
Proof.
  induction n as [|k IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

(* 书练习 3.4.4：m + k = k -> m = 0 *)
Theorem sadd_eq_right : forall k m, sadd m k = k -> m = z.
Proof.
  induction k as [|k IH]; intros m H; simpl in H.
  - exact H.
  - apply IH. apply s_inj. exact H.
Qed.

(* 书练习 3.4.12a：加法消去律 *)
Theorem sadd_cancel_r : forall n l m, sadd l n = sadd m n -> l = m.
Proof.
  induction n as [|k IH]; intros l m H; simpl in H.
  - exact H.
  - apply IH. apply s_inj. exact H.
Qed.

(* 加法零分解：m + d = 0 则两者皆 0 *)
Theorem sadd_zero : forall m d, sadd m d = z -> m = z /\ d = z.
Proof.
  intros m d H. destruct m as [|m'].
  - split; [reflexivity|].
    destruct d as [|d']; [reflexivity| simpl in H; discriminate H].
  - destruct d as [|d']; simpl in H; discriminate H.
Qed.

(* 书 Prop 3.4.3：1 与一切交换（为交换律铺路） *)
Lemma one_comm : forall n, sadd (s z) n = sadd n (s z).
Proof.
  induction n as [|k IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

(* 书 Prop 3.4.4：结合律 *)
Theorem sadd_assoc : forall n l m, sadd (sadd l m) n = sadd l (sadd m n).
Proof.
  induction n as [|k IH]; intros l m; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

(* 后继左移引理（练习 11 的关键子步） *)
Lemma sadd_succ_l : forall m k, sadd (s k) m = s (sadd k m).
Proof.
  induction m as [|k' IH]; intros k; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

(* 书练习 3.4.11：加法交换律 *)
Theorem sadd_comm : forall m n, sadd m n = sadd n m.
Proof.
  induction n as [|k IH]; simpl.
  - rewrite sadd_0_l. reflexivity.
  - rewrite IH. rewrite sadd_succ_l. reflexivity.
Qed.

(* 左消去：由交换律从右消去导出 *)
Theorem sadd_cancel_l : forall n l m, sadd n l = sadd n m -> l = m.
Proof.
  intros n l m H.
  apply (sadd_cancel_r n).
  rewrite (sadd_comm l n), (sadd_comm m n).
  exact H.
Qed.

(* 中间项交换：b+(c+d) = c+(b+d) *)
Lemma sadd_swap : forall b c d, sadd b (sadd c d) = sadd c (sadd b d).
Proof.
  intros b c d.
  rewrite <- sadd_assoc, <- sadd_assoc.
  rewrite (sadd_comm b c).
  reflexivity.
Qed.

(* (a+b)+(c+d) = (a+c)+(b+d)：分配律证明里的挪移 *)
Lemma sadd_shuffle : forall a b c d,
  sadd (sadd a b) (sadd c d) = sadd (sadd a c) (sadd b d).
Proof.
  intros a b c d.
  rewrite !sadd_assoc.
  rewrite (sadd_swap b c d).
  reflexivity.
Qed.

(* 书 Def 3.4.4：乘法对第二参递归 *)
Fixpoint smul (a b : sn) : sn :=
  match b with
  | z => z
  | s k => sadd (smul a k) a
  end.

Theorem smul_0_l : forall n, smul z n = z.
Proof.
  induction n as [|k IH]; simpl.
  - reflexivity.
  - exact IH.
Qed.

(* 书练习 3.4.16b：(l+m)·n = l·n + m·n *)
Theorem smul_add_distr_r : forall n l m,
  smul (sadd l m) n = sadd (smul l n) (smul m n).
Proof.
  induction n as [|k IH]; intros l m; simpl.
  - reflexivity.
  - rewrite IH. apply sadd_shuffle.
Qed.

Lemma one_mul : forall n, smul (s z) n = n.
Proof.
  induction n as [|k IH]; simpl.
  - reflexivity.
  - rewrite IH. simpl. reflexivity.
Qed.

Lemma smul_succ_l : forall m k, smul (s k) m = sadd (smul k m) m.
Proof.
  intros m k.
  replace (s k) with (sadd k (s z)) by reflexivity.
  rewrite smul_add_distr_r. rewrite one_mul. reflexivity.
Qed.

(* 书练习 3.4.18：乘法交换律 *)
Theorem smul_comm : forall m n, smul m n = smul n m.
Proof.
  induction n as [|k IH]; simpl.
  - rewrite smul_0_l. reflexivity.
  - rewrite IH. rewrite smul_succ_l. reflexivity.
Qed.

(* ---------- 6. <= 定义为 exists d, m + d = n（练习 3.4.20 起） ---------- *)

Definition sle (m n : sn) : Prop := exists d, sadd m d = n.

Theorem sle_refl : forall m, sle m m.
Proof.
  intros m. exists z. reflexivity.
Qed.

Theorem sle_trans : forall l m n, sle l m -> sle m n -> sle l n.
Proof.
  intros l m n [d1 Hd1] [d2 Hd2].
  exists (sadd d1 d2).
  rewrite <- sadd_assoc. rewrite Hd1. exact Hd2.
Qed.

(* 书练习 3.4.25：反对称 *)
Theorem sle_antisym : forall m n, sle m n -> sle n m -> m = n.
Proof.
  intros m n [d1 Hd1] [d2 Hd2].
  assert (Hk : sadd m (sadd d1 d2) = sadd m z).
  { rewrite <- sadd_assoc. rewrite Hd1. rewrite Hd2. reflexivity. }
  apply sadd_cancel_l in Hk.
  apply sadd_zero in Hk. destruct Hk as [Hd1z _].
  rewrite Hd1z in Hd1. simpl in Hd1. exact Hd1.
Qed.

(* 书练习 3.4.26：完全性（双重归纳） *)
Theorem sle_total : forall m n, sle m n \/ sle n m.
Proof.
  induction n as [|k IH].
  - right. exists m. apply sadd_0_l.
  - destruct IH as [Hmk | Hkm].
    + left. destruct Hmk as [d Hd]. exists (s d).
      simpl. rewrite Hd. reflexivity.
    + destruct Hkm as [d Hd].
      destruct d as [|d'].
      * left. exists (s z).
        simpl in Hd. simpl.
        rewrite Hd. reflexivity.
      * right. simpl in Hd.
        exists d'. rewrite sadd_succ_l. exact Hd.
Qed.

(* ---------- 7. 冒烟 ---------- *)

Compute (aseq 4, bseq 4).          (* 24, 61 —— 书例的数值表 *)
Compute (map fib (seq 0 8)).
Compute (sumfib 5 + 1, fib (5 + 2)).  (* 13 = F_7 *)
Compute (lp (Conj (V 1) (Neg (V 2))), cn (Conj (V 1) (Neg (V 2)))).

Print Assumptions sumfib_shift.
Print Assumptions lp_cn.
Print Assumptions sadd_comm.
Print Assumptions smul_comm.
Print Assumptions sle_antisym.
Print Assumptions sle_total.
