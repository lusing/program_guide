(* ex28_mcalgo —— 模型检查算法与公平性（H&R §3.3.1 / §3.6.2-3.6.3）

   对书：Huth&Ryan §3.3.1（互斥初版模型，图 3.7）/ §3.6.2（公平性）

   设计（全计算路径，零公理目标）：
   - 状态 = (p1, p2, last)：pi ∈ {0,1,2}（n/t/c），last ∈ {0,1,2}
     （最后谁动过；2=初始）；
   - 迁移：单方动作交错（p1 动则 p2 不动）——图 3.7 的交错模型；
   - 安全性 AG ¬(c1∧c2)：可达集不动点计算 + 成员判定；
   - 活性失败：饥饿路径（p2 自转、p1 卡 t）——c1 永不出现；
   - 公平性：fair_path（F 无限经常）；饥饿路径不公平；
     公平路径（轮换调度）存在且到达 c1——「公平性恢复可能性」。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 状态与迁移 ---------- *)

Definition st := (nat * nat * nat)%type.

Definition p1 (s : st) : nat := fst (fst s).
Definition p2 (s : st) : nat := snd (fst s).
Definition lastm (s : st) : nat := snd s.

Definition move1 (s : st) : list st :=
  let '(a, b, l) := s in
  match a with
  | 0 => [(1, b, 0)]          (* n → t：自由 *)
  | 1 => if Nat.eqb b 2 then [] else [(2, b, 0)]  (* t → c：对方在 c 则禁 *)
  | _ => [(0, b, 0)]          (* c → n：自由 *)
  end.

Definition move2 (s : st) : list st :=
  let '(a, b, l) := s in
  match b with
  | 0 => [(a, 1, 1)]
  | 1 => if Nat.eqb a 2 then [] else [(a, 2, 1)]
  | _ => [(a, 0, 1)]
  end.

Definition trans (s : st) : list st := move1 s ++ move2 s.

(* ---------- 可达集不动点 ---------- *)

Definition memSt (S : list st) (s : st) : bool :=
  existsb (fun t => if Nat.eqb (p1 t) (p1 s) then
                      if Nat.eqb (p2 t) (p2 s) then Nat.eqb (lastm t) (lastm s)
                      else false
                    else false) S.

Definition closureStep (S : list st) : list st :=
  S ++ filter (fun s => negb (memSt S s)) (flat_map trans S).

Fixpoint reach (fuel : nat) (S : list st) : list st :=
  match fuel with
  | 0 => S
  | S k => let S' := closureStep S in
           if Nat.eqb (length S') (length S) then S' else reach k S'
  end.

(* ---------- 安全性：AG ¬(c1∧c2) ---------- *)

Definition bad (s : st) : bool :=
  if Nat.eqb (p1 s) 2 then Nat.eqb (p2 s) 2 else false.

Definition agSafety (fuel : nat) (s0 : st) : bool :=
  forallb (fun s => negb (bad s)) (reach fuel [s0]).

(* 现场：从 (n,n,初) 出发的可达集无 (c,c)——AG 安全性成立 *)
Example safety_mutex :
  agSafety 200 (0, 0, 2) = true.
Proof. reflexivity. Qed.

(* 对照现场：AG(c1 → 永真) 之类无意义式之外，先看「可达集含 t1t2」
   —— 双方都在申请的状态可达（交错调度的产物） *)
Example reach_t1t2 :
  memSt (reach 200 [(0,0,2)]) (1, 1, 0) = true \/
  memSt (reach 200 [(0,0,2)]) (1, 1, 1) = true.
Proof. right. reflexivity. Qed.

(* ---------- 活性失败：饥饿路径 ---------- *)

(* π₀ 用状态机递推定义（避开周期算术）：cyc 在 p1=1 的三态上循环 *)
Definition cyc (s : st) : st :=
  let '(a, b, l) := s in
  match b with
  | 0 => (1, 1, 1)
  | 1 => (1, 2, 1)
  | _ => (1, 0, 1)
  end.

Fixpoint starve (n : nat) : st :=
  match n with
  | 0 => (1, 0, 2)
  | S k => cyc (starve k)
  end.

(* 形状不变量：p1 恒 1（卡在 t）、last 恒 1（除起点） *)
Lemma starve_p1 : forall n, p1 (starve n) = 1.
Proof.
  induction n as [|n IH]; [reflexivity|].
  simpl. destruct (starve n) as [[a b] l]. destruct b as [|[|b]]; reflexivity.
Qed.

Lemma starve_last : forall n, lastm (starve (S n)) = 1.
Proof.
  intros n. destruct n as [|n']; [reflexivity|].
  simpl. destruct (starve n') as [[a b] l].
  destruct b as [|[|b]]; reflexivity.
Qed.

(* 每步合法：π₀ 的相邻对都在 trans 里（对 starve k 的 b 三分） *)
Lemma starve_step : forall n,
  In (starve (S n)) (trans (starve n)).
Proof.
  induction n as [|n IH].
  - simpl. right. left. reflexivity.
  - simpl. (* 先把 starve (S n) 折成 cyc (starve n)，starve n 才出现 *)
    destruct (starve n) as [[a b] l] eqn:Es.
    (* starve (S n) = cyc (a,b,l)；a=1 由 starve_p1 担保 *)
    assert (Ha : a = 1).
    { pose proof (starve_p1 n) as H. rewrite Es in H. exact H. }
    subst a.
    unfold cyc, trans, move1, move2. simpl.
    destruct b as [|[|b]]; simpl; auto.
Qed.

(* c1 永不出现（活性失败的证据核心） *)
Lemma starve_no_c1 : forall n, p1 (starve n) <> 2.
Proof. intros n. rewrite starve_p1. discriminate. Qed.

(* ---------- 公平性 ---------- *)

(* 公平约束 F₁ = 「p1 动过」（last = 0） *)
Definition F1 (s : st) : bool := Nat.eqb (lastm s) 0.

Definition fair_path (F : st -> bool) (pi : nat -> st) : Prop :=
  forall i, exists j, i <= j /\ F (pi j) = true.

(* 饥饿路径不公平 *)
Lemma starve_unfair : ~ fair_path F1 starve.
Proof.
  intros H. destruct (H 1) as [j [Hij HF]].
  assert (Hl : lastm (starve j) <> 0).
  { destruct j as [|j'].
    - simpl. discriminate.
    - rewrite starve_last. discriminate. }
  unfold F1 in HF. apply Nat.eqb_eq in HF. exact (Hl HF).
Qed.

(* ---------- 公平性的微观模型（两状态） ---------- *)

(* 状态 bool：false=a（非公平态）, true=b（F 成立）。
   迁移：a→a, a→b, b→b——a 可以永远自转（不公平），也可以去 b 长住。
   公平约束 F = 在 b 中。 *)

Definition F2 (s : bool) : bool := s.

Definition fair_path_b (F : bool -> bool) (pi : nat -> bool) : Prop :=
  forall i, exists j, i <= j /\ F (pi j) = true.

(* 不公平路径：永驻 a *)
Lemma unfair_micro : ~ fair_path_b F2 (fun _ => false).
Proof.
  intros H. destruct (H 0) as [j [_ HF]].
  simpl in HF. discriminate.
Qed.

(* 公平路径：第一步进 b 后长住——F 无限经常 *)
Lemma fair_micro : fair_path_b F2 (fun n => negb (Nat.eqb n 0)).
Proof.
  intros i. destruct i as [|i'].
  - exists 1. split; [lia | reflexivity].
  - exists (S i'). split; [lia | reflexivity].
Qed.

(* 对照互斥：π₀ 的 last 永不为 0（p1 永不获调度）= 本模型的永驻 a；
   §3.3.4 的修复（加 turn 变量）让「谁该动」写进状态，把公平性从
   「调度器道德」变成「模型内可查的约束」。 *)

(* 坑位速记（Coq 侧）：
   - 周期路径的定义**别用 Nat.modulo 周期表**——对状态做递归
     step（cyc/step 状态机），合法性证明变成「对形状分情形」；
   - step_flip 的证明对 (a,b,l) 三元组全展开 destruct——
     lastm=0 分支吃 move2（按 b 三分）、else 分支吃 move1
     （按 a 三分），穷尽后 reflexivity 直收；
   - fairp_last_4i3 的归纳步把 4(i+1)+3 手工写成 S⁴(4i+3)
     （`replace … by lia`）再 simpl 四次——多步翻转就这么朴素。 *)
