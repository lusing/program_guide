(* ex27_ltl —— LTL 线性时态逻辑（H&R §3.2）

   对书：Huth&Ryan §3.2.1-3.2.5（语法/语义/模式/等价/adequate sets）

   设计：
   - 路径 = nat -> (nat -> bool)（位置 i 的原子赋值）；后缀记法 π^i；
   - lsat 是**公式结构上的 Fixpoint**（递归在子公式上下降——U 的
     位置见证无界不妨碍公式递归；否定的正性问题随之消失）；
   - 等价族六件：F=⊤U、G 对偶（正向零公理/反向 classic 入账）、
     F∨ 分配、G∧ 分配、F 幂等、X 的否定交换——经典成分显式
     记账，与 03/04 章同一口径。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Inductive ltl : Type :=
| lAtom : nat -> ltl
| lTrue : ltl
| lNeg  : ltl -> ltl
| lAnd  : ltl -> ltl -> ltl
| lOr   : ltl -> ltl -> ltl
| lX    : ltl -> ltl                    (* 下一时刻 *)
| lF    : ltl -> ltl                    (* 终将 *)
| lG    : ltl -> ltl                    (* 总是 *)
| lU    : ltl -> ltl -> ltl.            (* 直到 *)

(* 路径：位置 -> 原子赋值 *)
Definition path := nat -> nat -> bool.

(* 满足关系：公式结构上的 Fixpoint（子公式严格变小） *)
Fixpoint lsat (p : path) (i : nat) (f : ltl) : Prop :=
  match f with
  | lAtom a => p i a = true
  | lTrue => True
  | lNeg a => ~ lsat p i a
  | lAnd a b => lsat p i a /\ lsat p i b
  | lOr a b => lsat p i a \/ lsat p i b
  | lX a => lsat p (S i) a
  | lF a => exists j, i <= j /\ lsat p j a
  | lG a => forall j, i <= j -> lsat p j a
  | lU a b => exists j, i <= j /\ lsat p j b /\
              (forall k, i <= k < j -> lsat p k a)
  end.

(* ---------- 等价族（H&R 式 3.3-3.6 一带） ---------- *)

(* F φ ≡ ⊤ U φ（零公理） *)
Theorem F_unfold : forall p i f,
  lsat p i (lF f) <-> lsat p i (lU lTrue f).
Proof.
  intros p i f. simpl. split.
  - intros [j [Hij Hf]]. exists j. split; [exact Hij|].
    split; [exact Hf|]. intros k _. exact I.
  - intros [j [Hij [Hj _]]]. exists j. split; assumption.
Qed.

(* G φ → ¬F ¬φ（对偶正向，零公理） *)
Theorem G_dual_fwd : forall p i f,
  lsat p i (lG f) -> lsat p i (lNeg (lF (lNeg f))).
Proof.
  intros p i f HG. simpl. intros [j [Hij Hnf]].
  apply Hnf. apply HG. exact Hij.
Qed.

(* ¬F ¬φ → G φ：反向是经典步骤（每位置的排中）——classic 入账公示 *)
From Stdlib Require Import Classical_Prop.

Theorem G_dual_bwd : forall p i f,
  lsat p i (lNeg (lF (lNeg f))) -> lsat p i (lG f).
Proof.
  intros p i f HN. simpl. intros j Hj.
  destruct (classic (lsat p j f)) as [Hf | Hnf].
  - exact Hf.
  - exfalso. apply HN. exists j. split; [exact Hj | exact Hnf].
Qed.

(* F 的析取分配：F(f ∨ g) ≡ F f ∨ F g（零公理） *)
Theorem F_or : forall p i f g,
  lsat p i (lF (lOr f g)) <-> lsat p i (lF f) \/ lsat p i (lF g).
Proof.
  intros p i f g. simpl. split.
  - intros [j [Hij [Hf | Hg]]].
    + left. exists j. split; assumption.
    + right. exists j. split; [exact Hij | exact Hg].
  - intros [Hf | Hg].
    + destruct Hf as [j [Hij Hf]]. exists j.
      split; [exact Hij | left; exact Hf].
    + destruct Hg as [j [Hij Hg]]. exists j.
      split; [exact Hij | right; exact Hg].
Qed.

(* G 的合取分配：G(f ∧ g) ≡ G f ∧ G g（零公理） *)
Theorem G_and : forall p i f g,
  lsat p i (lG (lAnd f g)) <-> (lsat p i (lG f) /\ lsat p i (lG g)).
Proof.
  intros p i f g. simpl. split.
  - intros H. split; intros j Hj; apply (H j Hj).
  - intros [Hf Hg] j Hj. split; [apply Hf | apply Hg]; exact Hj.
Qed.

(* F 的幂等：F F φ ≡ F φ（零公理） *)
Theorem F_idem : forall p i f,
  lsat p i (lF (lF f)) <-> lsat p i (lF f).
Proof.
  intros p i f. simpl. split.
  - intros [j [Hij [k [Hjk Hk]]]]. exists k. split; [lia | exact Hk].
  - intros [j [Hij Hj2]].
    exists j. split; [exact Hij |].
    exists j. split; [lia | exact Hj2].
Qed.

(* X 的否定交换：X ¬φ ≡ ¬ X φ（零公理） *)
Theorem X_neg : forall p i f,
  lsat p i (lX (lNeg f)) <-> lsat p i (lNeg (lX f)).
Proof.
  intros p i f. simpl. split; intro H; apply H.
Qed.

(* ---------- 现场：路径上的模式求值 ---------- *)

Definition ptrue : path := fun _ _ => true.

Example ptrue_G : forall i, lsat ptrue i (lG (lAtom 0)).
Proof. intros i j _. reflexivity. Qed.

Example ptrue_FU : forall i, lsat ptrue i (lU (lAtom 0) (lAtom 1)).
Proof.
  intros i. exists i. split; [lia|].
  split; [reflexivity | intros k _; reflexivity].
Qed.

(* 脉冲路径：原子 5 只在位置 3 为真——F 的见证与 X 的定位 *)
Definition ppulse : path := fun i a =>
  if Nat.eqb i 3 then Nat.eqb a 5 else false.

Example ppulse_F : forall i, i <= 3 -> lsat ppulse i (lF (lAtom 5)).
Proof.
  intros i Hi. exists 3. split; [exact Hi|]. reflexivity.
Qed.

Example ppulse_X : lsat ppulse 0 (lX (lX (lX (lAtom 5)))).
Proof. reflexivity. Qed.

Print Assumptions F_unfold.   (* Closed *)
Print Assumptions G_dual_fwd. (* Closed *)
Print Assumptions G_dual_bwd. (* classic——经典步骤，入账公示 *)
Print Assumptions F_or.       (* Closed *)
Print Assumptions G_and.      (* Closed *)
Print Assumptions F_idem.     (* Closed *)
Print Assumptions X_neg.      (* Closed *)
