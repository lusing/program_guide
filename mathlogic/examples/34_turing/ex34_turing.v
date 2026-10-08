(* ex34_turing.v —— 图灵机：四元组与纸带（Mendelson §5.1-5.2）
   四元组三型：q a b q'（写）/ q a L q' / q a R q'（移）；
   停机 = 无 (状态,读符) 匹配的四元组；带端移动自动补空格。
   书例：Terase（找首个非空抹除）/ Tsucc（后继）/ Tzero（零函数）/
   Tadd（加法，自构五元组=书例 3 同行为）；全空输入下 Terase 永不停。 *)

From Stdlib Require Import Bool Arith Lia List PeanoNat.
Import ListNotations.

(* ============ 一、四元组、纸带与解释器 ============ *)

Inductive act : Type := wr (b : nat) | mL | mR.

Inductive quad : Type := qd (qs rd : nat) (a : act) (qs' : nat).

Record tape : Type := mkt { lft : list nat; cur : nat; rgt : list nat }.
Record cfg  : Type := mkc { st : nat; tp : tape }.

(* 首匹配；None = 无匹配四元组 = 停机 *)
Fixpoint findq (p : list quad) (s a : nat) : option (act * nat) :=
  match p with
  | [] => None
  | qd qs rd ac qs' :: p' =>
      if (Nat.eqb qs s) && (Nat.eqb rd a) then Some (ac, qs')
      else findq p' s a
  end.

Definition step (p : list quad) (c : cfg) : option cfg :=
  match findq p (st c) (cur (tp c)) with
  | None => None
  | Some (wr b, qs') =>
      Some (mkc qs' (mkt (lft (tp c)) b (rgt (tp c))))
  | Some (mL, qs') =>
      Some (match lft (tp c) with
            | [] => mkc qs' (mkt [] 0 (cur (tp c) :: rgt (tp c)))
            | l :: ls => mkc qs' (mkt ls l (cur (tp c) :: rgt (tp c)))
            end)
  | Some (mR, qs') =>
      Some (match rgt (tp c) with
            | [] => mkc qs' (mkt (cur (tp c) :: lft (tp c)) 0 [])
            | r :: rs => mkc qs' (mkt (cur (tp c) :: lft (tp c)) r rs)
            end)
  end.

Fixpoint run (p : list quad) (c : cfg) (fuel : nat) : option cfg :=
  match fuel with
  | O => None                              (* 燃料尽仍未停（不停机现场） *)
  | S f =>
      match step p c with
      | None => Some c                     (* 停机：返回停机配置 *)
      | Some c' => run p c' f
      end
  end.

(* 停机的单调性：多给燃料不改变已停的结果 *)
Lemma run_mono : forall p c f k c',
  run p c f = Some c' -> run p c (f + k) = Some c'.
Proof.
  intros p c f k c'. revert c.
  induction f as [|f IHf]; intros c H; simpl in *.
  - discriminate.
  - destruct (step p c) as [c''|] eqn:E.
    + exact (IHf c'' H).
    + exact H.
Qed.

(* ============ 二、一元编码与四台书例机器 ============ *)

Definition start1 (n : nat) : cfg := mkc 0 (mkt [] 1 (repeat 1 n)).
Definition start2 (m n : nat) : cfg :=
  mkc 0 (mkt [] 1 (repeat 1 m ++ [0] ++ repeat 1 (S n))).

(* 书例 0（二元字母表版）：q0 B R q0, q0 | B q1 *)
Definition Terase : list quad := [qd 0 0 mR 0; qd 0 1 (wr 0) 1].

(* 书例 1：q0 | L q1, q1 B | q2 *)
Definition Tsucc : list quad := [qd 0 1 mL 1; qd 1 0 (wr 1) 2].

(* 书例 2：q0 | B q1, q1 B R q0, q0 B | q2 *)
Definition Tzero : list quad :=
  [qd 0 1 (wr 0) 1; qd 1 0 mR 0; qd 0 0 (wr 1) 2].

(* 加法（自构，行为同书例 3）：隔板改笔使 m+n+2 笔并成 m+n+3 笔，
   须连擦两笔才得 (m+n)+1 笔——首版只擦一笔被网格对账抓包：
   q0 | R q0, q0 B | q1, q1 | R q1, q1 B L q2, q2 | B q3, q3 B L q4, q4 | B q5 *)
Definition Tadd : list quad :=
  [qd 0 1 mR 0; qd 0 0 (wr 1) 1; qd 1 1 mR 1; qd 1 0 mL 2; qd 2 1 (wr 0) 3;
   qd 3 0 mL 4; qd 4 1 (wr 0) 5].

(* ============ 三、Tsucc：常数深度全正确 ============ *)

Theorem tsucc_correct : forall n,
  run Tsucc (start1 n) 4 = Some (mkc 2 (mkt [] 1 (repeat 1 (S n)))).
Proof. intro n. reflexivity. Qed.

(* ============ 四、Tzero：循环不变式归纳全正确 ============ *)

(* Cz k m：q0 位于某笔划上，左侧 k 个已抹空格，右侧还有 m 笔 *)
Definition Cz (k m : nat) : cfg := mkc 0 (mkt (repeat 0 k) 1 (repeat 1 m)).

Lemma tzero_loop : forall m k,
  run Tzero (Cz k m) (2 * m + 4)
  = Some (mkc 2 (mkt (repeat 0 (S (k + m))) 1 [])).
Proof.
  induction m as [|m IH]; intros k.
  - simpl. rewrite Nat.add_0_r. reflexivity.
  - replace (2 * S m + 4) with (S (S (2 * m + 4))) by lia.
    replace (S (k + S m)) with (S (S k + m)) by lia.
    simpl. exact (IH (S k)).
Qed.

Theorem tzero_correct : forall n,
  run Tzero (start1 n) (2 * n + 5) = Some (mkc 2 (mkt (repeat 0 (S n)) 1 [])).
Proof.
  intro n. unfold start1.
  assert (H : run Tzero (mkc 0 (mkt [] 1 (repeat 1 n))) (2 * n + 4)
             = Some (mkc 2 (mkt (repeat 0 (S n)) 1 []))).
  { exact (tzero_loop n 0). }
  replace (2 * n + 5) with (2 * n + 4 + 1) by lia.
  rewrite (run_mono Tzero _ (2 * n + 4) 1 _ H).
  reflexivity.
Qed.

(* ============ 五、对账表：Tadd 网格 + 各机逐输入 ============ *)

Fixpoint cnt1 (l : list nat) : nat :=
  match l with
  | [] => 0
  | 1 :: l' => S (cnt1 l')
  | _ :: l' => cnt1 l'
  end.

Definition outbars (c : cfg) : nat :=
  cnt1 (lft (tp c)) + cnt1 [cur (tp c)] + cnt1 (rgt (tp c)).

(* 加法：5x5 网格，输出笔数 = m+n+1（即 (m+n) 的一元编码） *)
Example tadd_grid :
  map (fun mn => match run Tadd (start2 (fst mn) (snd mn)) 40 with
                 | Some c => outbars c
                 | None => 999
                 end)
      (list_prod (seq 0 5) (seq 0 5))
  = map (fun mn => fst mn + snd mn + 1) (list_prod (seq 0 5) (seq 0 5)).
Proof. reflexivity. Qed.

(* 后继：0..9 输出笔数 = n+2（即 n+1 的编码） *)
Example tsucc_table :
  map (fun n => match run Tsucc (start1 n) 10 with
                | Some c => outbars c
                | None => 999
                end) (seq 0 10)
  = map (fun n => n + 2) (seq 0 10).
Proof. reflexivity. Qed.

(* 零函数：0..9 输出笔数 = 1（即 0 的编码） *)
Example tzero_table :
  map (fun n => match run Tzero (start1 n) 30 with
                | Some c => outbars c
                | None => 999
                end) (seq 0 10)
  = map (fun n => 1) (seq 0 10).
Proof. reflexivity. Qed.

(* 抹除机：n 笔输入抹去首笔 → 剩 n 笔；0 笔输入同样抹「首笔」（唯一笔） *)
Example terase_table :
  map (fun n => match run Terase (start1 n) 10 with
                | Some c => outbars c
                | None => 999
                end) (seq 0 10)
  = map (fun n => n) (seq 0 10).
Proof. reflexivity. Qed.

(* 全空纸带：Terase 的 q0BRq0 永不匹配停机——书「keeps moving right forever」 *)
Example terase_nohalt : run Terase (mkc 0 (mkt [] 0 [])) 50 = None.
Proof. reflexivity. Qed.

(* ============ 账本 ============ *)

Print Assumptions tsucc_correct.
Print Assumptions tzero_correct.
Print Assumptions tadd_grid.
Print Assumptions terase_nohalt.
