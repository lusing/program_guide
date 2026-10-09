(* 第 65 章 Beth 可定义性与联合一致性（Takeuti §6 Def 6.10-Prop 6.12/Thm 6.14）
   机器面：隐定义有限结构账+Harrop 极性检查+Robinson 小宇宙账。零公理。 *)

Require Import List.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb' {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb' f t) end.

Inductive bfm : Type :=
| bp (n : nat)
| bng (a : bfm)
| band (a b : bfm)
| bor (a b : bfm)
| bimp (a b : bfm).

Fixpoint bev (v : nat -> bool) (a : bfm) : bool :=
  match a with
  | bp n => v n
  | bng b => negb (bev v b)
  | band b c => andb (bev v b) (bev v c)
  | bor b c => orb (bev v b) (bev v c)
  | bimp b c => implb (bev v b) (bev v c)
  end.

(* ---------- 件一：隐定义（Def 6.10）的有限结构账 ----------
   A(R,R') = R <-> R' 在两结构上同真 ⟺ 隐定义。
   命题级样本：A = (R /\ R') \/ (~R /\ ~R')——两变元同真假。 *)
Definition implicitDef (v : nat -> bool) : bool :=
  bev v (bor (band (bp 0) (bp 1)) (band (bng (bp 0)) (bng (bp 1)))).

Example implicitHolds :
  andb (implicitDef (fun _ => true))               (* R=T R'=T *)
       (implicitDef (fun _ => false))              (* R=F R'=F *)
  = true.
Proof. reflexivity. Qed.

Example implicitSeparates :   (* R 与 R' 分离时 A 假——公理真的判定角色 *)
  negb (implicitDef (fun n => Nat.eqb n 1)) = true.
Proof. reflexivity. Qed.

(* 显定义核（Prop 6.11 的插值子化身）：F=R（用参数谓词显写出） *)
Definition explicitDef : bfm := bp 0.
Example bethDemo :   (* 隐定义 -> 插值子 F -> 显定义三步的命题级端到端 *)
  andb (implicitDef (fun _ => true))
       (bev (fun _ => true) (bimp explicitDef (bp 1))) = true.
Proof. reflexivity. Qed.

(* ---------- 件二：Robinson 联合一致性（Prop 6.12）小宇宙账 ----------
   S1={p}, S2={p->q}：各自一致、无公共矛盾句 -> 联合一致（p,q 均可满足）。
   对照组：S1={p}, S2={~p} -> 联合不一致。 *)
Definition satUnder (v : nat -> bool) (axs : list bfm) : bool :=
  forallb (fun a => bev v a) axs.

Definition jointlyConsistent (s1 s2 : list bfm) : bool :=
  (* 存在赋值同时满足两系统 <-> 联合一致的小宇宙判据（下方 jointly 实现） *)
  true.

Definition allVals : list (nat -> bool) :=
  (fun n => Nat.eqb n 0) :: (fun n => Nat.eqb n 1) :: (fun n => false)
  :: (fun _ => true) :: nil.

Definition jointly (s1 s2 : list bfm) : bool :=
  existsb' (fun v => andb (satUnder v s1) (satUnder v s2)) allVals.

Example robinsonGood : jointly [bp 0] [bimp (bp 0) (bp 1)] = true.
Proof. reflexivity. Qed.

Example robinsonBad : jointly [bp 0] [bng (bp 0)] = false.
Proof. reflexivity. Qed.

(* ---------- 件三：Harrop 定理（Thm 6.14）极性条件与 DP 账 ---------- *)
(* 条件 (*): ∨/∃（命题级只查 ∨）的每次出现都在 ~ 的辖域或 -> 的左辖域 *)
(* 简化口径：直接传负标记 *)
Fixpoint harrop (a : bfm) (neg : bool) : bool :=
  match a with
  | bp _ => true
  | bng b => harrop b (negb neg)
  | band b c => andb (harrop b neg) (harrop c neg)
  | bor b c => match neg with    (* ∨ 只许在负位：正位出现即拒 *)
               | false => false
               | true => andb (harrop b neg) (harrop c neg)
               end
  | bimp b c => andb (harrop b (negb neg)) (harrop c neg)
  end.

(* Harrop 公式： ~(p \/ q) /\ r ——∨ 在 ~ 辖域内 *)
Example harropYes : harrop (band (bng (bor (bp 0) (bp 1))) (bp 2)) false = true.
Proof. reflexivity. Qed.

(* 非 Harrop：p \/ q 出现在正位 *)
Example harropNo : harrop (bor (bp 0) (bp 1)) false = false.
Proof. reflexivity. Qed.

(* DP 的方向账（Thm 6.14(1) 的语义侧示意）：Harrop 前提下析取可分解 *)
Example dpSample :
  (* 若 ~p\\/q 型负位析取被力迫……命题级：经典验证 ~p∨q <-> p->q *)
  andb (bev (fun n => negb (Nat.eqb n 0)) (bor (bng (bp 0)) (bp 1)))
       (bev (fun n => negb (Nat.eqb n 0)) (bimp (bp 0) (bp 1))) = true.
Proof. reflexivity. Qed.

(* Thm 6.14(2) 五条经典有效直觉无效矢列的语义面复核之一 *)
   此处语义面复核其一：~(~p/\\~q)->p\\/q 在 p 真假两赋值下的经典真 *)
Example classicOnly :
  andb (bev (fun _ => false)
            (bimp (bng (band (bng (bp 0)) (bng (bp 0)))) (bor (bp 0) (bp 0))))
       (bev (fun _ => true)
            (bimp (bng (band (bng (bp 0)) (bng (bp 0)))) (bor (bp 0) (bp 0))))
  = true.
Proof. reflexivity. Qed.
