(* ex11 —— 直觉主义与 Glivenko 现象（HoTT 版）
   编译：Rocq 9.1 + Coq-HoTT。
   HoTT 的命题即 h-level 1 截断类型——¬¬ 现象在纯构造内核
   （无经典公理）里与 Coq/Agda/Lean 三家同构。 *)

Require Import HoTT.HoTT.

(* ---------- 构件一：三重否定坍缩 ---------- *)

Theorem n3_hott : forall A : Type, ~ ~ ~ A -> ~ A.
Proof.
  intros A H HA. apply H. intros HA'. exact (HA' HA).
Defined.

(* ---------- 现象：经典原理的 ¬¬ 化 ---------- *)

Theorem nn_lem_hott : forall A : Type, ~ ~ (A + ~ A).
Proof.
  intros A H. apply H. right. intros HA.
  apply H. left. exact HA.
Defined.

Theorem nn_dne_hott : forall A : Type, ~ ~ (~ ~ A -> A).
Proof.
  intros A H. apply H. intros HDNE.
  assert (HnA : ~ A).
  { intros HA. apply H. intros _. exact HA. }
  set (he := HDNE HnA).
  destruct he.
Defined.

(* 现场注记：这三条在 HoTT 里是「h-level 无关」的纯构造事实——
   无需 IsHProp 截断；截断层级只在陈述 LEM 时才进入游戏（04 章）。 *)

(* 坑位速记（HoTT 侧）：
   - ~ A 定义为 A -> Empty；+ 是 sum——¬¬ 现象是纯类型论事实；
   - nn_dne 的 False_ind 等价物：HDNE HnA : Empty 之后
     用 exact 直收（目标是 A，Empty 消除在 -noinit 下照常）。 *)
