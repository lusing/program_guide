(* 第 73 章：快速增长数论函数层次（冯琦 §1.8.4）——Coq 通道 *)
(* F_α 层次的有限段：迭代定义 + F₁ n = 2n、F₂ n = n·2ⁿ 的完整归纳证明； *)
(* HB 遗传展开（燃料法绕开嵌套递归 guard 坑——e<m、r<m 的测度论证 *)
(* 留给燃料充裕性，vm_compute 对拍书载例 1.29/1.30）；古德斯坦一步与   *)
(* G(3) 全程五步的影子下降链以 hb_lt 字典序逐环验证（定理 1.82 的有限 *)
(* 截面）。 *)
From Coq Require Import Arith Lia List Bool.

Module Ch73.

(* ---------- 迭代与 F 层次（定义 1.84） ---------- *)
Fixpoint iterate (f : nat -> nat) (k : nat) (x : nat) : nat :=
  match k with 0 => x | S k' => iterate f k' (f x) end.

Definition F0 (n : nat) : nat := S n.
Definition F1 (n : nat) : nat := iterate F0 n n.
Definition F2 (n : nat) : nat := iterate F1 n n.
Definition F3 (n : nat) : nat := iterate F2 n n.

(* F_k：可变层数（F_ω(n) = F_n(n) 的有限段定义） *)
Fixpoint Fk (k : nat) : nat -> nat :=
  match k with
  | 0 => F0
  | S k' => fun n => iterate (Fk k') n n
  end.
Definition Fomega (n : nat) : nat := Fk n n.

(* 迭代引理：F₀ 迭代 = 加 k；F₁ 迭代 = 乘 2^k *)
Lemma iterate_F0 : forall k x, iterate F0 k x = x + k.
Proof.
  induction k; intros x; simpl.
  - lia.
  - rewrite IHk. unfold F0. lia.
Qed.

Lemma iterate_F1 : forall k x, iterate F1 k x = x * 2^k.
Proof.
  induction k; intros x; simpl.
  - lia.
  - rewrite IHk.
    assert (HF: F1 x = x * 2) by (unfold F1; rewrite iterate_F0; lia).
    rewrite HF. simpl. ring.
Qed.

(* 定理 1.81(2) 的解析式见证：F₁、F₂ 的闭式 *)
Theorem F1_closed : forall n, F1 n = 2 * n.
Proof. intros n. unfold F1. rewrite iterate_F0. lia. Qed.

Theorem F2_closed : forall n, F2 n = n * 2^n.
Proof.
  intros n. unfold F2. rewrite iterate_F1.
  rewrite Nat.mul_comm. reflexivity.
Qed.

(* F₁ 也是 Fk 1：两层定义一致性 *)
Lemma Fk1_eq_F1 : forall n, Fk 1 n = F1 n.
Proof. intros n. reflexivity. Qed.

(* 计算验证（定义 1.84 的样例）：F₃(2) = 2048、F_ω(1)=2、F_ω(2)=8 *)
Example F3_2 : F3 2 = 2048. Proof. reflexivity. Qed.
Example Fomega_1 : Fomega 1 = 2. Proof. reflexivity. Qed.
Example Fomega_2 : Fomega 2 = 8. Proof. reflexivity. Qed.
(* F₂(24) = 402653184：闭式改写后两端同形，避免一元 nat 展开 4 亿个 *)
(* S 构造子（vm_compute 对一元 nat 的大数物理不可行——只改写不求值） *)
Example F2_24 : F2 24 = 24 * 2^24.
Proof. rewrite F2_closed. reflexivity. Qed.
(* F_ω(3) = F₃(3) = F₂(F₂(F₂(3)))：最外层自变量 402653184， *)
(* 值 = 402653184·2^402653184——任何求值器都物理不可行，只记账： *)
Example Fomega_3_first : F2 3 = 24. Proof. reflexivity. Qed.

(* <* 见证（定义 1.85 / 定理 1.81(2)(3) 的有限截面） *)
Example dom_01 : forall n, 2 <= n -> F0 n < F1 n.
Proof. intros n H. rewrite F1_closed. unfold F0. lia. Qed.
Example dom_12 : forall n, 5 <= n -> F1 n < F2 n.
Proof. intros n H. rewrite F1_closed, F2_closed.
  replace (2 * n) with (n * 2) by lia.
  apply Nat.mul_lt_mono_pos_l; [lia|].
  (* 2 < 2^n for n >= 5 *)
  assert (H2: 2^5 <= 2^n) by (apply Nat.pow_le_mono_r; lia).
  simpl in H2. lia.
Qed.
Example dom_poly : forall n, 7 <= n -> n*n*n + n < F2 n.
Proof.
  intros n H. rewrite F2_closed.
  (* n³+n < n·2^n for n >= 7：先归纳出 n²+2 <= 2^n *)
  assert (Hp: forall m, 7 <= m -> m^2 + 2 <= 2^m).
  { induction m; intros Hm.
    - lia.
    - destruct (m =? 6) eqn:E.
      + apply Nat.eqb_eq in E. subst m. rewrite <- Nat.leb_le. reflexivity.
      + apply Nat.eqb_neq in E. assert (H0: 7 <= m) by lia.
        specialize (IHm H0). rewrite Nat.pow_2_r in *.
        assert (H7: 7 * m <= m * m).
        { apply Nat.mul_le_mono_r. exact H0. }
        replace (2 ^ S m) with (2 * 2^m) by reflexivity.
        nia. }
  specialize (Hp n H). rewrite Nat.pow_2_r in Hp.
  assert (Hmul: n * (n*n + 2) <= n * 2^n).
  { apply Nat.mul_le_mono_l. exact Hp. }
  nia.
Qed.

(* ---------- HB 遗传展开（定义 1.86；树里不存基） ---------- *)
Inductive HB : Set :=
| HN : HB                       (* 0 / 原子指数 0 *)
| HC : HB -> nat -> HB -> HB.   (* b^e·k + rest（0<k<b，rest 指数更小） *)

(* 燃料法（嵌套递归 e<m、r<m 避开 guard 检查——老坑，燃料 = S m 足够） *)
Fixpoint mmax (fuel b m p e : nat) : nat * nat :=
  (* 返回 (e, p)：p = b^e ≤ m 的最大幂（调用时 p = b^e） *)
  match fuel with
  | 0 => (e, p)
  | S f => if p * b <=? m then mmax f b m (p * b) (S e) else (e, p)
  end.

Fixpoint hb_of_f (fuel b m : nat) : HB :=
  match fuel with
  | 0 => HN
  | S f =>
    if m =? 0 then HN
    else if m <? b then HC HN m HN          (* 原子常数：<b，不换基 *)
    else match mmax m b m b 1 with
         | (e, p) => HC (hb_of_f f b e) (m / p) (hb_of_f f b (m mod p))
         end
  end.
Definition hb_of (b m : nat) : HB := hb_of_f (S m) b m.

Fixpoint eval_hb (b : nat) (t : HB) : nat :=
  match t with
  | HN => 0
  | HC e k r => b ^ (eval_hb b e) * k + eval_hb b r
  end.

(* 字典序三态比较（影子序数的序：首项指数、系数、余项递归—— *)
(* 单 struct 参数版：交换位置的递归调用会被 guard 拒绝，老坑） *)
Fixpoint hb_cmp (s t : HB) {struct s} : comparison :=
  match s with
  | HN => match t with
          | HN => Eq
          | HC _ _ _ => Lt
          end
  | HC e1 k1 r1 =>
    match t with
    | HN => Gt
    | HC e2 k2 r2 =>
      match hb_cmp e1 e2 with
      | Lt => Lt
      | Gt => Gt
      | Eq => match Nat.compare k1 k2 with
              | Lt => Lt
              | Gt => Gt
              | Eq => hb_cmp r1 r2
              end
      end
    end
  end.
Definition hb_lt (s t : HB) : bool :=
  match hb_cmp s t with Lt => true | _ => false end.

(* 例 1.29：T₂(37) = 2^{2²+1}+2²+1 *)
Example T2_37_value : eval_hb 2 (hb_of 2 37) = 37.
Proof. reflexivity. Qed.
(* 树形：37 = 2^5·1 + 5，其中 5 = 2^{2^1}·1 + 1——指数 5 与余项 5 同树 *)
Example T2_37_shape :
  hb_of 2 37 =
    HC (HC (HC (HC HN 1 HN) 1 HN) 1 (HC HN 1 HN)) 1
       (HC (HC (HC HN 1 HN) 1 HN) 1 (HC HN 1 HN)).
Proof. reflexivity. Qed.
(* 换基只换读法：同一棵树换基 3 重读。T₂(37)@3 = 3^28+28 超出一元 nat *)
(* 的物理可行域，改用 T₂(11) = 2^{2+1}+2+1 做小型见证：@3 = 3^4+4 = 85 *)
Example T2_11_bump :
  eval_hb 2 (hb_of 2 11) = 11 /\ eval_hb 3 (hb_of 2 11) = 85.
Proof. split; reflexivity. Qed.

(* ---------- 古德斯坦（定义 1.87 / 定理 1.82） ---------- *)
Definition gstep (b m : nat) : nat := eval_hb (S b) (hb_of b m) - 1.

(* G(3) 全程：3,3,3,2,1,0（书载机制的 vm_compute 重演） *)
Example g3_chain :
  gstep 2 3 = 3 /\ gstep 3 3 = 3 /\ gstep 4 3 = 2 /\
  gstep 5 2 = 1 /\ gstep 6 1 = 0.
Proof. repeat split; reflexivity. Qed.

(* 影子下降链：同一棵树读成 HB 后逐环 hb_lt（基 2 起 G(3) 全链） *)
Definition shadow (b m : nat) : HB := hb_of b m.
Example g3_shadows_decrease :
  hb_lt (shadow 3 3) (shadow 2 3) = true /\
  hb_lt (shadow 4 3) (shadow 3 3) = true /\
  hb_lt (shadow 5 2) (shadow 4 3) = true /\
  hb_lt (shadow 6 1) (shadow 5 2) = true /\
  hb_lt HN (shadow 6 1) = true.
Proof. repeat split; reflexivity. Qed.

(* G(4) 书载前四步（例 1.30 的微型重演） *)
Example g4_chain : gstep 2 4 = 26 /\ gstep 3 26 = 41 /\ gstep 4 41 = 60.
Proof. repeat split; reflexivity. Qed.
(* 起点影子 = ω^ω：4 = 2^{2^1}——树形恰为 HC (HC (HC HN 1 HN) 1 HN) 1 HN *)
Example g4_shadow0 : shadow 2 4 = HC (HC (HC HN 1 HN) 1 HN) 1 HN.
Proof. reflexivity. Qed.
Example g4_shadow1 :
  hb_lt (shadow 3 26) (shadow 2 4) = true.
Proof. reflexivity. Qed.

End Ch73.
