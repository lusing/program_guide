(* ex45_categoricity.v —— 完备理论与范畴性：Vaught 测试与 Ax 定理（Marker ch5）
   机器件：F_3^2 换基排列（DAG「维数定同构」的有限影子）；
   x↦x^3 的有限域单/满射对账表（Ax 定理的鸽笼脚印）；
   n≤5 全图枚举的扩张公理频率（随机图 0-1 律的数值账）。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. F_p^2 上换基映射：维数定同构的有限影子 ---------- *)

Definition vaddp (a b : nat * nat) : nat * nat :=
  ((fst a + fst b) mod 3, (snd a + snd b) mod 3).
Definition smulp (k : nat) (v : nat * nat) : nat * nat :=
  ((k * fst v) mod 3, (k * snd v) mod 3).

(* v = a·e0 + b·e1 ↦ a·w0 + b·w1（标准基换成 w0=[1;0], w1=[1;1]） *)
Definition iso2p (w0 w1 v : nat * nat) : nat * nat :=
  vaddp (smulp (fst v) w0) (smulp (snd v) w1).

Definition Vs2 : list (nat * nat) := list_prod (seq 0 3) (seq 0 3).

Definition peqb (a b : nat * nat) : bool :=
  andb (Nat.eqb (fst a) (fst b)) (Nat.eqb (snd a) (snd b)).

Fixpoint memb2 (x : nat * nat) (l : list (nat * nat)) : bool :=
  match l with
  | [] => false
  | y :: t => orb (peqb x y) (memb2 x t)
  end.

Fixpoint nodupb2 (l : list (nat * nat)) : bool :=
  match l with
  | [] => true
  | x :: t => andb (negb (memb2 x t)) (nodupb2 t)
  end.

(* 换基映射是 F_3^2 的排列：NoDup + 长度守恒 = 双射（有限鸽笼） *)
Example iso2_perm :
  nodupb2 (map (iso2p (1,0) (1,1)) Vs2) = true.
Proof. reflexivity. Qed.

Example iso2_len :
  length (map (iso2p (1,0) (1,1)) Vs2) = 9.
Proof. reflexivity. Qed.

(* 负面对照：非基向量组 w0=w1=[1;0] 塌缩——不是排列 *)
Example iso2_bad_not_perm :
  negb (nodupb2 (map (iso2p (1,0) (1,0)) Vs2)) = true.
Proof. reflexivity. Qed.

(* ---------- 2. Ax 定理的有限域脚印：x ↦ x^3 ---------- *)

Definition cubic (p x : nat) : nat := (x * x * x) mod p.

(* 单射：F_p 上任何两不同点像不同 *)
Definition inj_cubic (p : nat) : bool :=
  forallb (fun x => forallb (fun y =>
    orb (Nat.eqb x y) (negb (Nat.eqb (cubic p x) (cubic p y)))) (seq 0 p)) (seq 0 p).

(* 满射：每个 z 有原像 *)
Definition surj_cubic (p : nat) : bool :=
  forallb (fun z => existsb (fun x => Nat.eqb (cubic p x) z) (seq 0 p)) (seq 0 p).

(* gcd(3,p-1)=1（p≡2 mod 3 或 p=3）时 x^3 是域自同构——单且满 *)
Example ax_f5_inj : inj_cubic 5 = true.
Proof. reflexivity. Qed.

Example ax_f5_surj : surj_cubic 5 = true.
Proof. reflexivity. Qed.

(* p=7：3 | 6，1^3 = 2^3 = 1——不单 *)
Example ax_f7_notinj : negb (inj_cubic 7) = true.
Proof. reflexivity. Qed.

(* p=7 连满射也失败：像 = 三次剩余子群（大小 3）——单射不成立时
   鸽笼蕴含（单 ⟹ 满）当然无话可说；蕴含本身在单射成立的 p 上配对 *)
Example ax_f7_notsurj : negb (surj_cubic 7) = true.
Proof. reflexivity. Qed.

(* p=11：gcd(3,10)=1——单且满（与 p=5 同型）；p=13：3|12——两皆不成立 *)
Example ax_f11_inj_surj : andb (inj_cubic 11) (surj_cubic 11) = true.
Proof. reflexivity. Qed.

Example ax_f13_both_fail : negb (orb (inj_cubic 13) (surj_cubic 13)) = true.
Proof. reflexivity. Qed.

(* 特征迁移表：单射性随 p 的算术起伏（3 | p-1 即失败） *)
Compute (map (fun p => (p, inj_cubic p)) (seq 2 18)).
(* (2,true)(3,true)(5,true)(7,false)(11,true)(13,false)(17,true)(19,false)… *)

(* 一条与 x^3 不同的映射：x ↦ x^2 永不单（p>2 时 1 与 p-1 同像） *)
Example sq_notinj_p5 :
  existsb (fun xy => andb (Nat.eqb ((fst xy * fst xy) mod 5) ((snd xy * snd xy) mod 5))
                         (negb (Nat.eqb (fst xy) (snd xy))))
    (list_prod (seq 0 5) (seq 0 5)) = true.
Proof. reflexivity. Qed.

(* ---------- 3. 随机图 0-1 律：n≤5 全图枚举 ---------- *)

Fixpoint bits (m : nat) : list (list bool) :=
  match m with
  | 0 => [[]]
  | S m' => map (cons false) (bits m') ++ map (cons true) (bits m')
  end.

(* n 点无序对表（i<j），边的位向量按下标对应 *)
Definition pairsn (n : nat) : list (nat * nat) :=
  flat_map (fun i => map (fun j => (i, j)) (filter (fun j => i <? j) (seq 0 n)))
    (seq 0 n).

Fixpoint posp (xy : nat * nat) (l : list (nat * nat)) : nat :=
  match l with
  | [] => 0
  | y :: t => if peqb xy y then 0 else S (posp xy t)
  end.

Definition edgesn (n : nat) (b : list bool) (i j : nat) : bool :=
  nth (posp (i, j) (pairsn n)) b false.

(* σ₁：无孤立点（扩张公理最简特例） *)
Definition no_isolated (n : nat) (b : list bool) : bool :=
  forallb (fun i => existsb (fun j => orb (edgesn n b i j) (edgesn n b j i))
                           (filter (fun j => negb (Nat.eqb i j)) (seq 0 n)))
    (seq 0 n).

Definition medges (n : nat) : nat := length (pairsn n).
Definition fracnum (n : nat) : nat :=
  length (filter (fun b => no_isolated n b) (bits (medges n))).

Compute (map (fun n => (n, medges n, fracnum n, length (bits (medges n))))
             [2;3;4;5]).
(* 先探后写：n=2:1/2, n=3:4/8, n=4:41/64, n=5:768/1024（递增趋 1） *)

Example frac_sigma1_table :
  map fracnum [2;3;4;5] = [1;4;41;768].
Proof. reflexivity. Qed.

(* 分母 2^m：1/2, 4/8, 41/64, 768/1024——σ₁（无孤立点）频率递增趋 1，
   与 0-1 律的预言一致；「存在孤立点」是其补，趋 0 *)

(* 「存在孤立点」频率 → 0 的补侧；「恰好 3 条边」这种局部句子 → 0 *)
Definition exactly3 (n : nat) (b : list bool) : bool :=
  Nat.eqb (length (filter id b)) 3.

Example exactly3_tends0 :
  map (fun n => length (filter (fun b => exactly3 n b) (bits (medges n))))
      [2;3;4;5] = [0;1;20;120].
Proof. reflexivity. Qed.
(* = C(m,3)，m=1,3,6,10；占全部分母 2^m → 0 *)

(* ---------- 4. 随机图理论完备（文档线） ---------- *)
(* 扩张公理 σ_{k,l} 全真 + 可数 back-and-forth（44 章 dup_wins 的无穷化身）
   ⟹ 随机图理论完备 ⟹ 每句极限概率 0/1。机器面止于频率证据，
   完备性的归纳骨架记文档级（docs/45-categoricity.md §四）。 *)

(* ---------- 冒烟 ---------- *)
Compute (map (fun p => (p, inj_cubic p, surj_cubic p)) [2;3;5;7;11;13]).
Compute (map (fun n => fracnum n) [2;3;4;5]).
Compute (length (bits 10)).   (* 1024 *)
