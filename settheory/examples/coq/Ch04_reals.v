(* 第 04 章 实数：Dedekind 分割的定义骨架 + 对角线的 nat 版 *)

Require Import QArith Lia.

(* ---------- 一、Dedekind 分割：Jech 定理 12 的核心定义 ----------
   稠密无界线性序 P 的完备化由 Dedekind 分割给出。用 Q 上的
   "下割"单侧实现：割 = 非平凡、下封闭、无最大元的谓词。
   （完整构造与 √2 的割在 Julia 通道数值化、docs 正文化。） *)

Record is_cut (A : Q -> Prop) : Prop := BuildCut
  {
    cut_nontriv : (exists q, A q) /\ (exists r, ~ A r) ;
    cut_down : forall q r, (q < r)%Q -> A r -> A q ;
    cut_no_max : forall q, A q -> exists r, A r /\ (q < r)%Q
  }.

Definition cut_of_q (q : Q) : Q -> Prop := fun r => (r < q)%Q.

Definition cut_sqrt2 : Q -> Prop :=
  fun r => (0 <= r)%Q /\ (r * r < 2)%Q.

(* ---------- 二、对角线：Baire 空间不可数的骨架 ----------

   Jech 定理 10 的证明是嵌套区间版；其对角线本质在
   "函数空间的枚举总漏掉 g(n) = F(n)(n)+1"。nat 版完整给出：
   结构与 ω→ω 版完全同构（+1 保证严格不同）。 *)

Definition diagonal_g (F : nat -> nat -> nat) : nat -> nat :=
  fun n => S (F n n).

Lemma diagonal_differs :
  forall (F : nat -> nat -> nat) (n : nat),
    diagonal_g F n <> F n n.
Proof.
  intros F n.
  unfold diagonal_g.
  intros E.
  (* S k = k 不可能 *)
  lia.
Qed.

(* 由此外推：任何"可数名单" F : nat -> (nat -> nat) 都漏掉 g。
   函数级不等需要外延性叙事；点态不同（每个 n 处 g ≠ F(n)）
   已足以得出 g 不是名单中任何一个。 *)

Print Assumptions diagonal_differs.

(* ---------- 三、嵌套区间：定理 10 的收缩引擎（陈述） ----------

   Jech 的证明用逐次收缩 [a_n, b_n] ⊆ (c_k, b_n)（c_k 是名单中
   当前命中者）夹出逃逸点 a = sup a_n。完备性（每个有界集有
   上确界）是实数独有的性质——这正是定理 12 Dedekind 完备化
   所"补"的东西：Q 有稠密性但 a_n 的 sup 可能不在 Q 里
   （√2 的经典情形，见 cut_sqrt2）。 *)
