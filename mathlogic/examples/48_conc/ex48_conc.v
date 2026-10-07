(* ex39 —— 并发程序演绎验证（Ben-Ari 3e §16.1-16.3）
   交错语义：并发程序 = 原子步表（guard+action 合一，option 表守卫）。
   演算主角：**全局不变式**——「I 在初始真 + I 对每条原子步保持
   ⟹ I 对一切可达状态真」。一个不变式顶一个可达集：演绎验证与
   37 章显式模型检查在同一互斥案例上合流。

   协议取严格轮换版（Ben-Ari §16.2 的第一个尝试）：enter 的守卫
   是「轮到我」。单独的 turn 守卫挡不住「对方在临界」——需要两条
   辅助不变式（pc1=2 → turn=1、pc2=2 → turn=2）夹住互斥；这正是
   Ben-Ari 用三次失败尝试教「不变式怎么长出来」的机器版（docs/39
   走查另两次失败：只看 turn 会活锁、加标志位有竞态）。

   机器件：invb_spec（不变式的 Prop 读法）+ inv_preserved（六条
   原子步逐一核对）+ reach_inv（可达性封口）+ 现场例。零公理。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Record st : Type := MkSt {
  pc1 : nat;      (* 进程 1 位置：0=空闲 1=请求 2=临界 *)
  pc2 : nat;      (* 进程 2 位置 *)
  turn : nat      (* 轮到谁（1 或 2）*)
}.

Definition init : st := {| pc1 := 0; pc2 := 0; turn := 1 |}.

(* ---------- 六条原子步（guard 不满足 = None） ---------- *)

Definition try_req1 (s : st) : option st :=
  if pc1 s =? 0 then Some {| pc1 := 1; pc2 := pc2 s; turn := turn s |}
  else None.

Definition try_enter1 (s : st) : option st :=
  if (pc1 s =? 1) && (turn s =? 1)
  then Some {| pc1 := 2; pc2 := pc2 s; turn := turn s |}
  else None.

Definition try_exit1 (s : st) : option st :=
  if pc1 s =? 2 then Some {| pc1 := 0; pc2 := pc2 s; turn := 2 |}
  else None.

Definition try_req2 (s : st) : option st :=
  if pc2 s =? 0 then Some {| pc1 := pc1 s; pc2 := 1; turn := turn s |}
  else None.

Definition try_enter2 (s : st) : option st :=
  if (pc2 s =? 1) && (turn s =? 2)
  then Some {| pc1 := pc1 s; pc2 := 2; turn := turn s |}
  else None.

Definition try_exit2 (s : st) : option st :=
  if pc2 s =? 2 then Some {| pc1 := pc1 s; pc2 := 0; turn := 1 |}
  else None.

Definition asteps : list (st -> option st) :=
  [try_req1; try_enter1; try_exit1; try_req2; try_enter2; try_exit2].

(* ---------- 不变式：互斥 + 两条辅助（临界者持有轮牌） ---------- *)

Definition inv (s : st) : Prop :=
  ~ (pc1 s = 2 /\ pc2 s = 2)
  /\ (pc1 s = 2 -> turn s = 1)
  /\ (pc2 s = 2 -> turn s = 2).

Theorem inv_init : inv init.
Proof.
  split; [ | split].
  - intros [H _]; simpl in H; lia.
  - intros H; simpl in H; simpl; lia.
  - intros H; simpl in H; simpl; lia.
Qed.

Theorem inv_preserved : forall f s s',
  In f asteps -> f s = Some s' -> inv s -> inv s'.
Proof.
  intros f s s' Hin Hstep Hinv.
  destruct Hinv as [Hm [Ha Hb]].
  destruct Hin as [Hf | [Hf | [Hf | [Hf | [Hf | [Hf | []]]]]]];
    subst f;
    unfold try_req1, try_enter1, try_exit1,
             try_req2, try_enter2, try_exit2 in Hstep.
  - destruct (pc1 s =? 0) eqn:E; [|discriminate].
    injection Hstep as Hs2. subst s'.
    apply Nat.eqb_eq in E.
    repeat split; (intros H; simpl in *;
      first [ lia
            | destruct H; lia
            | (specialize (Hb H); lia)
            | (specialize (Ha H); lia) ]).
  - destruct ((pc1 s =? 1) && (turn s =? 1)) eqn:E; [|discriminate].
    injection Hstep as Hs2. subst s'.
    apply andb_true_iff in E. destruct E as [E1 E2].
    apply Nat.eqb_eq in E1. apply Nat.eqb_eq in E2.
    repeat split; intros H.
    + destruct H as [H1 H2]. simpl in H2. specialize (Hb H2). lia.
    + simpl in H; simpl; lia.
    + simpl in H; simpl; specialize (Hb H); lia.
  - destruct (pc1 s =? 2) eqn:E; [|discriminate].
    injection Hstep as Hs2. subst s'.
    apply Nat.eqb_eq in E.
    repeat split; (intros H; simpl in *;
      first [ lia
            | destruct H; lia
            | (specialize (Hb H); lia)
            | (specialize (Ha H); lia) ]).
  - destruct (pc2 s =? 0) eqn:E; [|discriminate].
    injection Hstep as Hs2. subst s'.
    apply Nat.eqb_eq in E.
    repeat split; (intros H; simpl in *;
      first [ lia
            | destruct H; lia
            | (specialize (Hb H); lia)
            | (specialize (Ha H); lia) ]).
  - destruct ((pc2 s =? 1) && (turn s =? 2)) eqn:E; [|discriminate].
    injection Hstep as Hs2. subst s'.
    apply andb_true_iff in E. destruct E as [E1 E2].
    apply Nat.eqb_eq in E1. apply Nat.eqb_eq in E2.
    repeat split; intros H.
    + destruct H as [H1 H2]. simpl in H1. specialize (Ha H1). lia.
    + simpl in H; simpl; specialize (Ha H); lia.
    + simpl in H; simpl; lia.
  - destruct (pc2 s =? 2) eqn:E; [|discriminate].
    injection Hstep as Hs2. subst s'.
    apply Nat.eqb_eq in E.
    repeat split; (intros H; simpl in *;
      first [ lia
            | destruct H; lia
            | (specialize (Hb H); lia)
            | (specialize (Ha H); lia) ]).
Qed.

(* ---------- 可达性封口：一切可达状态满足不变式 ---------- *)

Fixpoint reachSet (fuel : nat) (s : st) : list st :=
  match fuel with
  | 0 => [s]
  | S k => s :: flat_map
      (fun f => match f s with Some s' => reachSet k s' | None => [] end)
      asteps
  end.

Theorem reach_inv_gen : forall fuel s0 s,
  In s (reachSet fuel s0) -> inv s0 -> inv s.
Proof.
  induction fuel as [| fuel IH]; intros s0 s Hin Hs0.
  - simpl in Hin. destruct Hin as [Hs | []]. subst s. exact Hs0.
  - destruct Hin as [Hs | Hin].
    + subst s. exact Hs0.
    + apply in_flat_map in Hin. destruct Hin as [f [Hf Hout]].
      destruct (f s0) as [s' |] eqn:Ef; [|destruct Hout].
      apply (IH s' s Hout).
      apply (inv_preserved f s0 s'); assumption.
Qed.

Corollary reach_inv : forall fuel s, In s (reachSet fuel init) -> inv s.
Proof.
  intros fuel s Hin. apply (reach_inv_gen fuel init s Hin inv_init).
Qed.

(* ---------- 现场例 ---------- *)

(* 临界可达：进程 1 独自进入临界区（请求 → 轮到 → 进入） *)
Example crit_reachable :
  In {| pc1 := 2; pc2 := 0; turn := 1 |} (reachSet 3 init).
Proof. simpl. auto. Qed.

(* 双临界不可达：互斥成立 *)
Corollary mutual_exclusion : forall fuel,
  ~ In {| pc1 := 2; pc2 := 2; turn := 1 |} (reachSet fuel init).
Proof.
  intros fuel Hin.
  pose proof (reach_inv fuel _ Hin) as H.
  destruct H as [Hm _]. simpl in Hm.
  exact (Hm (conj eq_refl eq_refl)).
Qed.
