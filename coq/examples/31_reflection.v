(* 31 自反证明 —— 用计算代替推理，证明项不随数据长大 *)

From Stdlib Require Import Arith Lia.
From Stdlib Require Import Wf_nat.

Module Ex31Reflection.

(* ---------- 31.1 思想：把推理步骤换成计算步骤 ---------- *)

(* 最朴素的自反证明一直在用：reflexivity 的本质是
   「两边都能归约到同一个项」——0 + m = m 从没手写过归纳，
   是转换（conversion）检查替我们算的。
   自反证明把这个思路放大：写一个布尔判定函数 + 一条
   「函数说真则命题成立」的桥定理，之后所有具体实例
   都是 apply + reflexivity——证明项大小与数据规模无关 *)

(* ---------- 31.2 第一类：直接计算证明（可判定谓词） ---------- *)

Fixpoint evenb (n : nat) : bool :=
  match n with
  | 0 => true
  | 1 => false
  | S (S m) => evenb m
  end.

Inductive even_ : nat -> Prop :=
| even_O : even_ 0
| even_SS : forall n, even_ n -> even_ (S (S n)).

(* 桥定理：函数正确性只证这一次 *)
Lemma evenb_true : forall n, evenb n = true -> even_ n.
Proof.
  intros n. induction n as [n IH] using (well_founded_ind lt_wf).
  intros H. destruct n as [|[|m]].
  - apply even_O.
  - simpl in H. discriminate.
  - simpl in H. apply even_SS. apply IH. lia. exact H.
Qed.

(* 之后的每个偶数实例：一行。
   对比朴素路线——apply even_SS 要重复 512 次 *)
Example even_1024 : even_ 1024.
Proof. apply evenb_true. reflexivity. Qed.

(* （第 30 章的伏笔：判定函数必须是纯结构递归，
     归约机制才能把它一路算到底——燃料法在此反而常客） *)

(* ---------- 31.3 第二类：符号计算证明（模结合律的等式） ---------- *)

(* 任务：只靠加法结合律证 x+((y+z)+w) = (x+y)+(z+w)。
   朴素做法 repeat rewrite plus_assoc——证明项随表达式变大；
   自反做法：把表达式抽象成二叉树 bin，
   写一个「忘掉括号」的规格化函数 flatten，
   证一条「变形不改值」的定理，之后每个等式都是计算 *)

Inductive bin : Type :=
| node : bin -> bin -> bin
| leaf : nat -> bin.

(* 右结合化：所有加法都推到右端 *)
Fixpoint flatten_aux (t fin : bin) : bin :=
  match t with
  | node t1 t2 => flatten_aux t1 (flatten_aux t2 fin)
  | leaf _ => node t fin
  end.

Fixpoint flatten (t : bin) : bin :=
  match t with
  | node t1 t2 => flatten_aux t1 (flatten t2)
  | leaf _ => t
  end.

(* 解释函数：树 → nat 语义 *)
Fixpoint bin_nat (t : bin) : nat :=
  match t with
  | node t1 t2 => bin_nat t1 + bin_nat t2
  | leaf n => n
  end.

Compute (flatten (node (leaf 1) (node (node (leaf 2) (leaf 3)) (leaf 4)))).
(* = node (leaf 1) (node (leaf 2) (node (leaf 3) (leaf 4)))
   ——括号全部右移 *)

(* 变形不改值（证明里结合律出场——这正是它该出场的地方） *)
Theorem flatten_aux_valid : forall t t' : bin,
  bin_nat t + bin_nat t' = bin_nat (flatten_aux t t').
Proof.
  induction t as [t1 IH1 t2 IH2 | n]; intros t'; simpl.
  - rewrite <- (IH1 (flatten_aux t2 t')). rewrite <- (IH2 t'). lia.
  - reflexivity.
Qed.

Theorem flatten_valid : forall t : bin, bin_nat t = bin_nat (flatten t).
Proof.
  induction t as [t1 IH1 t2 IH2 | n]; simpl.
  - rewrite IH2. rewrite <- (flatten_aux_valid t1 (flatten t2)). reflexivity.
  - reflexivity.
Qed.

Theorem flatten_valid_2 : forall t t' : bin,
  bin_nat (flatten t) = bin_nat (flatten t') ->
  bin_nat t = bin_nat t'.
Proof.
  intros t t' H. rewrite (flatten_valid t), (flatten_valid t'). exact H.
Qed.

(* ---------- 31.4 打包成一击必杀的策略 ---------- *)

(* model：把 nat 表达式「倒模」成 bin 树（Ltac 构造项用 constr:(...)） *)
Ltac model v :=
  match v with
  | ?X1 + ?X2 =>
      let r1 := model X1 with r2 := model X2 in
      constr:(node r1 r2)
  | ?X1 => constr:(leaf X1)
  end.

Ltac assoc_eq_nat :=
  match goal with
  | [ |- ?X1 = ?X2 ] =>
      let t1 := model X1 with t2 := model X2 in
      (change (bin_nat t1 = bin_nat t2);
       apply flatten_valid_2;
       reflexivity)
  end.
(* 最后的 reflexivity 触发完整计算：
   flatten t1 与 flatten t2 各自归约成同一棵右结合树，
   转换检查放行——重写一步没做，等式已证 *)

Theorem reflection_test : forall x y z t u : nat,
  x + (y + z + (t + u)) = x + y + (z + (t + u)).
Proof. intros. assoc_eq_nat. Qed.

Theorem reflection_test2 : forall a b c d : nat,
  (a + b) + (c + d) = ((a + b + c) + d).
Proof. intros. assoc_eq_nat. Qed.

End Ex31Reflection.
