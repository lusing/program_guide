(* ============================================================ *)
(* 16 子集类型与强制子类型 —— Coq 侧                              *)
(* sig 是子集类型；Coercion 是 Luo 强制子类型的工程化身           *)
(* ============================================================ *)

Require Import Arith Lia List.
Import ListNotations.

(* ---- 一、子集类型：{n : nat | n > 0} ---- *)

Definition Pos : Type := {n : nat | n > 0}.

Definition pone : Pos.
Proof. exists 1. lia. Defined.

Definition doublePos (p : Pos) : Pos.
Proof. destruct p as [n H]. exists (2 * n). simpl in *. lia. Defined.

(* 值与证据成对出行；proj1_sig 取值、proj2_sig 取证 *)
Compute proj1_sig (doublePos pone).      (* 2 *)

(* 安全除法：分母非零写在【类型】里 *)
Definition safeDiv (n : nat) (d : {d : nat | d > 0}) : nat :=
  n / proj1_sig d.

Lemma three_pos : 3 > 0.
Proof. lia. Qed.

Compute safeDiv 7 (exist _ 3 three_pos).   (* 2 *)

(* ---- 二、Coercion：强制子类型的工程面 ---- *)

Record Boxed : Type := mkBoxed { unbox : nat }.

(* 注册强制：Boxed 出现在 nat 位时自动 unbox *)
Coercion unbox : Boxed >-> nat.

Definition boxed3 : Boxed := mkBoxed 3.

Compute boxed3 + 1.           (* 4：+ 需要 nat，Coercion 自动解箱 *)

(* 强制的组合：Boxed >-> nat 之后，一切「nat 可去之处」Boxed 都能去 *)
Compute S boxed3.             (* 4 *)

Print Coercions.   (* 全表：unbox 与 px 两条强制都在 *)

(* ---- 三、记录的字段也能当强制（投影强制） ---- *)

Record Point3 : Type := mkPoint { px : nat; py : nat; pz : nat }.

Coercion px : Point3 >-> nat.

Definition origin : Point3 := mkPoint 0 0 0.
Compute origin + 100.         (* 100：只看 x 分量 *)

(* ---- 四、Luo 强制子类型的理论定位（正文细讲） ---- *)
(* 包含式子类型 (⊆) 与强制 (⇒) 的区别：
   前者改变语义（集合包含），后者只是【记法便利】——
   Coq 的 Coercion 明确属于后者：不改变类型论本体，
   只在 elaboration 时插入 unbox。这与「类型检查后无痕」的
   设计承诺一致（Wang/Luo 的 coercive subtyping 框架） *)



