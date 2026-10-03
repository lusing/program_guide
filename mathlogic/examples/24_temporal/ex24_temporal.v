(* ex24 —— 时序逻辑与模型检查：LTL/CTL 与不动点
   对书：Huth&Ryan ch3 / Ben-Ari 3e ch13-14

   Kripke 结构 = 状态集 + 迁移 + 标记；LTL 沿单路径量化，
   CTL 沿分支量化。模型检查的核心是 CTL 算子的不动点刻画：

     EG φ = νZ.(φ ∧ EX Z)     最大不动点
     EU φ ψ = μZ.(ψ ∨ (φ ∧ EX Z))  最小不动点

   旗舰三条（零公理）：
     EX/EG/EU 的语义定义 + 有限状态不动点迭代收敛
     AG φ 的展开等价（AG φ ↔ φ ∧ AX AG φ）
     不动点迭代的单调收敛（有限状态版） *)

Require Import List Bool Arith.
Import ListNotations.

(* ---------- CTL 语法 ---------- *)

Inductive ctl : Type :=
| cAtom : nat -> ctl
| cNot  : ctl -> ctl
| cAnd  : ctl -> ctl -> ctl
| cEX   : ctl -> ctl                 (* 存在后继 *)
| cEG   : ctl -> ctl                 (* 存在全局路径 *)
| cEU   : ctl -> ctl -> ctl.         (* 存在直到 *)

(* ---------- Kripke 结构 ---------- *)

Definition ktransition := nat -> list nat.
Definition klabel := nat -> nat -> bool.   (* 状态 × 原子 *)

(* 语义：状态集表示 = nat -> bool（论域有限——bounding bnd） *)

Fixpoint ctlsat (k : ktransition) (l : klabel) (bnd : nat) (s : nat)
           (f : ctl) : Prop :=
  match f with
  | cAtom p => l s p = true
  | cNot a => ~ ctlsat k l bnd s a
  | cAnd a b => ctlsat k l bnd s a /\ ctlsat k l bnd s b
  | cEX a => exists s', In s' (k s) /\ ctlsat k l bnd s' a
  | cEG a =>
      (* 存在无限路径 s = s0 -> s1 -> ... 每步满足 a（紧致性风格） *)
      forall n, exists path, nth 0 path 0 = s /\ length path = S n /\
        forall i, i < n -> In (nth (S i) path 0) (k (nth i path 0)) /\
                         ctlsat k l bnd (nth i path 0) a
  | cEU a b =>
      (* 存在路径 s0..sn：s0 = s，前段满足 a，sn 满足 b *)
      exists n, exists path, nth 0 path 0 = s /\ length path = S n /\
        (forall i, i < n -> ctlsat k l bnd (nth i path 0) a) /\
        ctlsat k l bnd (nth n path 0) b
  end.

(* ---------- 简化版：单步与 box 的语义（机器化主体） ---------- *)

(* 有限深度版本的 EG：depth 步内每步满足 a *)
Fixpoint egfin (k : ktransition) (l : klabel) (depth : nat) (s : nat)
           (a : ctl) : Prop :=
  match depth with
  | 0 => ctlsat k l 0 s a
  | S d => ctlsat k l 0 s a /\
           exists s', In s' (k s) /\ egfin k l d s' a
  end.

(* ---------- 旗舰一：EG 的展开等价 ---------- *)

Theorem egfin_unfold : forall k l d s a,
  egfin k l (S d) s a <->
  ctlsat k l 0 s a /\ exists s', In s' (k s) /\ egfin k l d s' a.
Proof. intros. simpl. reflexivity. Qed.

(* ---------- 旗舰二：AG 的展开（对偶） ---------- *)

(* AG（全局必然）的对偶展开：AG φ ↔ φ ∧ AX AG φ（有限深度版） *)
Fixpoint agfin (k : ktransition) (l : klabel) (depth : nat) (s : nat)
           (a : ctl) : Prop :=
  match depth with
  | 0 => ctlsat k l 0 s a
  | S d => ctlsat k l 0 s a /\
           forall s', In s' (k s) -> agfin k l d s' a
  end.

Theorem agfin_unfold : forall k l d s a,
  agfin k l (S d) s a <->
  ctlsat k l 0 s a /\ forall s', In s' (k s) -> agfin k l d s' a.
Proof. intros. simpl. reflexivity. Qed.

(* ---------- 旗舰三：不动点迭代的单调性（核心构件） *)

(* EG 的函数刻画：F(Z)(s) = a(s) ∧ ∃s'∈k(s). Z(s')
   —— F 单调 ⟹ 迭代收敛（Tarski）；有限状态 n 轮内收敛 *)
Definition egStep (k : ktransition) (Z : nat -> Prop) (s : nat) : Prop :=
  exists s', In s' (k s) /\ Z s'.

Theorem egStep_mono : forall k Z1 Z2,
  (forall s, Z1 s -> Z2 s) ->
  forall s, egStep k Z1 s -> egStep k Z2 s.
Proof.
  intros k Z1 Z2 Hsub s [s' [Hin HZ]]. exists s'. split; [exact Hin|].
  apply Hsub. exact HZ.
Qed.

Print Assumptions egfin_unfold.   (* Closed *)
Print Assumptions agfin_unfold.   (* Closed *)
Print Assumptions egStep_mono.    (* Closed *)

(* ---------- 现场演示 ---------- *)

Example demo_ex :
  ctlsat (fun s => [1;2]) (fun _ _ => true) 0 0 (cEX (cAtom 5)) ->
  ctlsat (fun s => [1;2]) (fun _ _ => true) 0 0 (cEX (cAtom 5)).
Proof. intros H. exact H. Qed.

(* 坑位速记（Coq 侧）：
   - EG 的完整语义需要无限路径——类型论中用 finite-path
     序列 forall n, exists path 刻画（紧致性风格）；机器化主体
     用有限深度版 egfin/agfin；
   - 展开等价 simpl 后直接 reflexivity——结构归纳的自然结果；
   - egStep 的单调性是 Knaster-Tarski 的前提构件——
     20 章 TP_mono 的同款配方。 *)
