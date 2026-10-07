(* ex42 —— 程序合成与形式语义（Ben-Ari 3e §15.4-15.5）
   25/30 章正向用霍尔规则（验证给定程序）；本章反向用（合成走查
   见 docs/42：不变式从规约里长出来），并给 while 配**小步操作
   语义**——程序=状态机（39 章原子步的单进程版），霍尔规则与
   语义在机器里握手：
     step/steps —— 小步语义与大步包装（fuel 化）
     countdown_correct / mul_correct —— 读出式语义正确性（对输入
       归纳、状态泛化——合成走查的机器收口）
   相对完备性（Cook：证明需枚举算术，演绎系统不可能完全——与
   22 章不完备同根）文档级走查。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Definition state := nat -> nat.

Definition upd (x v : nat) (s : state) : state :=
  fun y => if Nat.eqb y x then v else s y.

Lemma upd_eq : forall x v s, (upd x v s) x = v.
Proof. intros. unfold upd. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma upd_neq : forall x y v s, x <> y -> (upd x v s) y = s y.
Proof.
  intros x y v s H. unfold upd.
  destruct (Nat.eqb_spec y x) as [Heq | Hne]; [exfalso; apply H; exact (eq_sym Heq) | reflexivity].
Qed.

Inductive cmd : Type :=
| CSkip : cmd
| CAssn : (state -> state) -> cmd          (* x := f(s) *)
| CSeq : cmd -> cmd -> cmd
| CWhile : (state -> bool) -> cmd -> cmd.

(* ---------- 小步操作语义 ---------- *)

Fixpoint step (c : cmd) (s : state) : option (cmd * state) :=
  match c with
  | CSkip => None                             (* 终止：无步可走 *)
  | CAssn f => Some (CSkip, f s)
  | CSeq c1 c2 =>
      match c1 with
      | CSkip => Some (c2, s)
      | _ => match step c1 s with
             | Some (c1', s') => Some (CSeq c1' c2, s')
             | None => None
             end
      end
  | CWhile b c =>
      if b s then Some (CSeq c (CWhile b c), s)
      else Some (CSkip, s)
  end.

Fixpoint steps (fuel : nat) (c : cmd) (s : state) : option state :=
  match fuel with
  | 0 => None
  | S k => match step c s with
           | None => match c with
                     | CSkip => Some s    (* 终止于 skip *)
                     | _ => None          (* 燃料断在中途 *)
                     end
           | Some (c', s') => steps k c' s'
           end
  end.

(* ---------- 现场一：倒数程序 ---------- *)

Definition countdown : cmd :=
  CWhile (fun s => 0 <? s 0) (CAssn (fun s => upd 0 (s 0 - 1) s)).

Theorem countdown_correct : forall n s, s 0 = n ->
  match steps (3 * n + 2) countdown s with
  | Some s' => s' 0 = 0
  | None => False
  end.
Proof.
  induction n as [| n IH]; intros s Hs.
  - simpl. rewrite Hs. simpl. exact Hs.
  - replace (3 * S n + 2) with (S (S (S (3 * n + 2)))) by lia.
    unfold countdown. simpl. rewrite Hs. simpl.
    assert (Hm : (upd 0 (s 0 - 1) s) 0 = n)
      by (rewrite upd_eq; rewrite Hs; simpl; lia).
    exact (IH (upd 0 (s 0 - 1) s) Hm).
Qed.

(* ---------- 现场二：合成出的乘法器 ---------- *)
(* 规约：{y=b ∧ z=c} mul {x = b*c ∧ y = 0}
   合成走查（docs/42 全程）：终值 x = b*c 分解为「b 次加 c」，
   不变式 I = (x = (b-y)*c ∧ y ≤ b) 从两端点插值长出来；
   机器收口 = 下面的读出式归纳。 *)

Definition mulBody : cmd :=
  CSeq (CAssn (fun s => upd 0 (s 0 + s 2) s))   (* x := x + z *)
       (CAssn (fun s => upd 1 (s 1 - 1) s)).    (* y := y - 1 *)

Definition mul : cmd :=
  CSeq (CAssn (fun s => upd 0 0 s))              (* x := 0 *)
       (CWhile (fun s => 0 <? s 1) mulBody).

Lemma mulW : forall b c s, s 1 = b -> s 2 = c ->
  exists s', steps (5 * b + 2) (CWhile (fun s => 0 <? s 1) mulBody) s = Some s'
            /\ s' 0 = s 0 + b * c /\ s' 1 = 0.
Proof.
  induction b as [| b IH]; intros c s H1 H2.
  - unfold mulBody. simpl. rewrite H1. simpl.
    exists s. split; [reflexivity | split; [lia | exact H1]].
  - replace (5 * S b + 2) with (S (S (S (S (S (5 * b + 2)))))) by lia.
    unfold mulBody. simpl. rewrite H1. simpl.
    assert (Ha : (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) 1 = b)
      by (rewrite upd_eq; rewrite H1; simpl; lia).
    assert (Hb : (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) 2 = s 2)
      by (rewrite upd_neq by lia; rewrite upd_neq by lia; reflexivity).
    destruct (IH c (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) Ha (eq_trans Hb H2))
      as [s'' [Hrun [Hx Hy]]].
    exists s''. split; [exact Hrun | split].
    + assert (Hc : (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) 0 = s 0 + s 2)
        by (rewrite upd_neq by lia; rewrite upd_eq; reflexivity).
      rewrite Hc in Hx. rewrite H2 in Hx. lia.
    + exact Hy.
Qed.

Theorem mul_correct : forall b c s, s 1 = b -> s 2 = c ->
  exists s', steps (5 * b + 4) mul s = Some s'
            /\ s' 0 = b * c /\ s' 1 = 0.
Proof.
  intros b c s H1 H2.
  replace (5 * b + 4) with (S (S (5 * b + 2))) by lia.
  unfold mul. simpl.
  assert (Ha : (upd 0 0 s) 1 = b) by (simpl; exact H1).
  assert (Hb : (upd 0 0 s) 2 = c) by (simpl; exact H2).
  destruct (mulW b c (upd 0 0 s) Ha Hb) as [s'' [Hrun [Hx Hy]]].
  exists s''. split; [exact Hrun | split].
  - rewrite (upd_eq 0 0 s) in Hx. lia.
  - exact Hy.
Qed.

(* 语义现场：3 × 4 经 16 步小步语义得 12 *)
Example mul_3_4 :
  match steps 21 mul (upd 1 3 (upd 2 4 (fun _ => 0))) with
  | Some s' => (s' 0, s' 1) | None => (999, 999) end = (12, 0).
Proof. reflexivity. Qed.
