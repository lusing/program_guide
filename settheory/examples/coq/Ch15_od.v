(* 第 15 章 OD/HOD：Berry 悖论的逻辑骨架（习题 15.17） *)

Require Import Arith Lia.

(* ---------- 一、最小反例原理（第 02 章 strong_induction 回响） ---------- *)

Lemma strong_induction :
  forall P : nat -> Prop,
    (forall n, (forall m, m < n -> P m) -> P n) -> forall n, P n.
Proof.
  intros P H n.
  assert (Hall : forall m, m <= n -> P m).
  { induction n as [|n IH]; intros m Hm.
    - apply H. intros k Hk. lia.
    - apply H. intros k Hk. apply IH. lia. }
  apply Hall. lia.
Qed.

(* ---------- 二、Berry 悖论的骨架 ----------
   若"可定义"谓词 Def 在对象语言可表达，则取最小不可定义数 d
   （强归纳给最小反例）。但"d 是最小不可定义数"是 d 的定义
   ——与 ~Def d 矛盾。一致性结论：Def 不可表达（Tarski 分层）。
   机器化：下面展示最小反例的构造引擎，悖论的最后一步
   （自指命名）是元语言动作，不在对象语言内形式化——
   这正是"分层"的证明结构。 *)

(* Berry 悖论的机器化边界：最小反例引擎即 strong_induction
   （上方完整证明）；"自指命名"是元语言动作，不在对象语言内
   形式化——分层的证明结构本身。 *)

Print Assumptions strong_induction.
