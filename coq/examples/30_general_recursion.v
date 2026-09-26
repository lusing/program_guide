(* 30 一般递归 —— 燃料、良基递归与 Program Fixpoint *)

From Stdlib Require Import Arith Lia.
From Stdlib Require Import Wf_nat Program.Wf.

Module Ex30GeneralRecursion.

(* ---------- 30.1 问题：结构递归不是万能的 ---------- *)

(* 除 2 取整的 log2：递归参数 n/2 不是 n 的结构子项——守卫检查拒绝 *)
Fail Fixpoint log2_bad (n : nat) : nat :=
  match n with
  | 0 => 0
  | 1 => 0
  | _ => S (log2_bad (Nat.div n 2))
  end.
(* 报错：Recursive call to log2_bad has principal argument
   equal to "n / 2" instead of a subterm of "n"
   ——Coq 只认「在子项上递归」这一种机械判据 *)

(* ---------- 30.2 方法一：有界递归（加燃料） ---------- *)

(* 附加一个每步严格减小的 nat 参数，递归改成对它结构递归。
   燃料烧完返回默认值 0——只要燃料给够（>= n），默认值不会出场 *)
Fixpoint half_fuel (fuel n : nat) : nat :=
  match fuel with
  | 0 => 0
  | S f => match n with
           | 0 => 0
           | 1 => 0
           | S (S m) => S (half_fuel f m)
           end
  end.

(* 正确性：燃料够时结果与标准库 Nat.div2 一致 *)
Lemma half_fuel_ok : forall f n, n <= f -> half_fuel f n = Nat.div2 n.
Proof.
  induction f as [| f IH]; intros n Hn.
  - assert (n = 0) by lia. subst. reflexivity.
  - destruct n as [|[|m]].
    + reflexivity.
    + reflexivity.
    + simpl. rewrite IH. reflexivity. simpl in Hn. lia.
Qed.

Compute (half_fuel 100 41).   (* = 20 = 41/2 *)
(* 代价：每次调用前要算/传一个界；抽取出的代码背着燃料参数跑 *)

(* ---------- 30.3 方法二：良基递归 ---------- *)

Print Acc.
(* Inductive Acc (A : Type) (R : A -> A -> Prop) (x : A) : Prop :=
     Acc_intro : (forall y : A, R y x -> Acc R y) -> Acc R x
   ——x 可达 = 它的所有 R-前驱都可达。
   良基关系：所有元素都可达（没有无穷 R-下降链） *)

Check lt_wf.
(* well_founded lt——标准库已证好自然数上 < 良基 *)

(* 注意（实测坑）：well_founded_ind 是 Prop 版归纳原理
   （P : A -> Prop）；定义函数要用 Set 版递归子
   well_founded_induction（P : A -> Set）——书里正是这对名字 *)

(* 用连续减法做欧氏除法（书 15.2.6 的精简版）：
   递归调用发生在 m - n 上，靠 m - n < m 的良基性保证终止 *)
Definition wf_div : forall m n : nat, 0 < n ->
  {q : nat & {r : nat | m = q * n + r /\ r < n}}.
Proof.
  induction m as [m IH] using (well_founded_induction lt_wf).
  intros n Hn.
  destruct (le_gt_dec n m) as [Hle | Hgt].
  - assert (Hlt : m - n < m) by lia.
    destruct (IH (m - n) Hlt n Hn) as [q [r [H1 H2]]].
    exists (S q). exists r. split.
    + simpl. lia.   (* m - n = q*n + r 与 n <= m 拼出 m = S q * n + r；
                       lia 把 q*n 当原子，纯线性推理 *)
    + exact H2.
  - exists 0. exists m. split.
    + lia.
    + exact Hgt.
Defined.
(* 取值用 projT1：{q : nat & _} 是 sigT（第 26 章 {x | P} 的 Type 版兄弟） *)
Compute (projT1 (wf_div 2000 31 (Nat.lt_0_succ 30))).   (* = 64 *)

(* ---------- 30.4 方法三：Program Fixpoint（现代利器） ---------- *)

(* {measure n}：声明「按度量 n 递减」，Coq 生成终止性义务
   （obligation），Next Obligation 逐个还债。
   这是良基递归的自动化包装——递归参数随便写，度量为王 *)
Program Fixpoint plog2 (n : nat) {measure n} : nat :=
  match le_gt_dec 2 n with
  | left _ => S (plog2 (Nat.div2 n))
  | right _ => 0
  end.
Next Obligation.
  apply Nat.lt_div2. lia.
Qed.
(* 义务：n >= 2 时 Nat.div2 n < n——Nat.lt_div2 给出主结论，
   副条件 0 < n 由 lia 从 2 <= n 收走
   实测坑：定义里用 if Nat.leb 2 n 会把义务变成布尔等式，
   lia 读不懂——用 le_gt_dec 让前提直接是 Prop *)

Compute (plog2 1000).   (* = 9：2^9 = 512 <= 1000 < 1024 *)

(* ---------- 30.5 三种方法怎么选 ---------- *)
(* 燃料       ：最朴素，证明容易，但调用背着界、抽取代码不干净；
                自反证明（第 31 章）反而喜欢它——计算可完全归约
   良基递归   ：代码干净贴近算法本意，但直接推理难——
                证明常用不动点方程路线（书 15.3）绕行
   Program    ：日常首选；measure/relation 都支持，
                义务还完即得良规定义，配合 Equations 插件更顺 *)

End Ex30GeneralRecursion.
