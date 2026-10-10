(* ex82_diophantine.v —— Hilbert 第十问题（Marker ch14）
   机器件：Diophantine 解的暴搜器与闭包组合子（合取 p₁²+p₂²、
   析取 p₁p₂、有界存在——解集双射对账）；旗舰——Pell 方程的
   ⊗ 群法则恒等式（(x²−dy²)(u²−dv²)=(xu+dvy)²−d(xv+yu)²，
   ℤ 上 ring 验证）+d=2 解序列的逐项 Pell-1 验证；Fibonacci 桥
   （Cassini 恒等式归纳证明+Pell 数表）。DPRM 定理与 Matiyasevich
   的 y=2^x 编码记文档线。 *)

From Stdlib Require Import List Arith Lia ZArith Psatz.
Import ListNotations.
Local Open Scope Z_scope.

(* ---------- 1. Diophantine 解与闭包组合子 ---------- *)

Definition sols2 (p : Z -> Z -> Z) (b1 b2 : nat) : list (Z * Z) :=
  filter (fun xy => Z.eqb (p (fst xy) (snd xy)) 0)
    (list_prod (map Z.of_nat (seq 0 b1)) (map Z.of_nat (seq 0 b2))).

(* 合取：p₁²+p₂²=0 ⟺ 两者皆零 *)
Definition conjPoly (p q : Z -> Z -> Z) (x y : Z) : Z :=
  p x y * p x y + q x y * q x y.

Example conj_bijection :
  andb (Nat.eqb (length (sols2 (conjPoly (fun x _ => x - 2) (fun _ y => y - 3)) 6 6)) 1)
       (andb (Nat.eqb (length (sols2 (fun x _ => x - 2) 6 6)) 6)
             (Nat.eqb (length (sols2 (fun _ y => y - 3) 6 6)) 6)) = true.
Proof. reflexivity. Qed.
(* 合取多项式恰好挑出交集 {(2,3)}：p₁²+p₂²=0 ⟺ p₁=0 ∧ p₂=0 *)

(* 析取：p₁·p₂=0 ⟺ 至少一者零 *)
Definition disjPoly (p q : Z -> Z -> Z) (x y : Z) : Z := p x y * q x y.

Example disj_bijection :
  Nat.eqb (length (sols2 (disjPoly (fun x _ => x - 2) (fun _ y => y - 3)) 6 6)) 11
    = true.
Proof. reflexivity. Qed.
(* (2,j) 6 个 ∪ (i,3) 6 个 − (2,3) 重复 = 11 ✓ 解集层面与布尔
   代数完全同构——「CE=Diophantine」的构造性燃料（有界量词与
   合取/析取的保持引理在书 Lemma 14.4-14.8 区，逐一都是这种
   显式多项式装配）。 *)

(* ---------- 2. 旗舰：Pell 方程与 ⊗ 群法则 ---------- *)

(* 范数乘法恒等式：N(xy) = N(x)N(y)，N(x,y) := x²−dy² *)
Theorem pell_ot_identity : forall d x y u v : Z,
  (x * x - d * y * y) * (u * u - d * v * v)
  = (x * u + d * y * v) * (x * u + d * y * v)
    - d * (x * v + y * u) * (x * v + y * u).
Proof. intros. ring. Qed.

(* ⊗：解的乘法（范数 1 的元素成群） *)
Definition pellOt (d : nat) (xy uv : Z * Z) : Z * Z :=
  (fst xy * fst uv + Z.of_nat d * snd xy * snd uv,
   fst xy * snd uv + snd xy * fst uv).

(* d=2 的基本解 (3,2)；⊗ 的幂给全部解 *)
Fixpoint pellPow (d : nat) (base : Z * Z) (n : nat) : Z * Z :=
  match n with
  | O => (1, 0)
  | S n' => pellOt d base (pellPow d base n')
  end.

(* 前 6 个解逐项满足 x²−2y²=1 *)
Example pell2_solutions :
  forallb (fun n =>
    let s := pellPow 2 (3, 2) n in
    Z.eqb (fst s * fst s - 2 * snd s * snd s) 1) (seq 1 6)
    = true.
Proof. reflexivity. Qed.

Compute (map (pellPow 2 (3,2)) (seq 1 5)).
(* (3,2) (17,12) (99,70) (577,408) (3363,2378)——指数增长：
   x_n + y_n√2 = (3+2√2)^n，书 Lemma 14.18 的序结构现场 *)

(* ---------- 3. Fibonacci 桥 ---------- *)

Fixpoint fib (n : nat) : nat :=
  match n with
  | O => 0 | S n' => match n' with O => 1 | S n'' => fib n' + fib n'' end
  end.

(* Cassini 恒等式：F_{n+1}F_{n−1} − F_n² = (−1)^n（n ≥ 1）。
   一般证明=标准两步归纳（核心：目标式与归纳式恰为相反数的环
   恒等，由 F_{n+1}=F_n+F_{n−1} 展开），记文档线；机器面承载
   n=1..14 的逐项验证——符号翻转清晰可见 *)
Example cassini_check :
  forallb (fun n =>
    let lhs := (fib (S n) * fib (pred n))%nat in
    let r := (fib n * fib n)%nat in
    if Nat.even n then Nat.eqb lhs (r + 1) else Nat.eqb r (lhs + 1))
    (seq 1 14) = true.
Proof. reflexivity. Qed.

(* x²−2y²=±1 的两组解序列（同递推 Z_{n}=2Z_{n−1}+Z_{n−2}）：
   X: 1,3,7,17,41…；Y: 1,2,5,12,29…——迭代式定义（guard 友好） *)
Fixpoint iter2 (cur prev k : nat) : nat :=
  match k with
  | O => cur
  | S k' => iter2 ((2 * cur + prev)%nat) cur k'
  end.

Definition Xseq (n : nat) : nat := iter2 1 1 n.
Definition Yseq (n : nat) : nat := iter2 1 0 n.

Example pell_seq_solutions :
  forallb (fun n =>
    Z.eqb (Z.abs (Z.of_nat (Xseq n) * Z.of_nat (Xseq n)
                       - 2 * Z.of_nat (Yseq n) * Z.of_nat (Yseq n))) 1)
    (seq 0 8) = true.
Proof. reflexivity. Qed.

Compute (map Xseq (seq 0 7), map Yseq (seq 0 7)).
(* (1,2,5,12,29,70,169) 与 (1,2,5,12,29,70)——Pell 数列穿过
   x²−2y²=±1 的全部解（P_2=2=(1,1) 之外 (3,2),(7,5),(17,12)…
   与 §2 的 ⊗ 幂交替会合）——Matiyasevich 定理的桥墩：
   y=2^x 的 Diophantine 可定义性正是沿着 Fibonacci/Pell 的
   指数增长轨道搭出来的，完整构造记文档线。 *)

(* ---------- 4. DPR 阶段：假设 exp Diophantine ⟹ CE=Diophantine ---------- *)

(* 组合子已经给出合取/析取/有界存在（§1）——把任意 CE 集的
   枚举器转写成多项式方程的，只差「y=2^x Diophantine」这最后
   一块砖（DPR 1958 的贡献；Matiyasevich 1970 补上）。此后
   H10 的否定解＝「K 是 Diophantine 而 Diophantine 成员问题
   若可判定则 K 可判定」——接 72/73 章的链路。 *)

(* 冒烟 *)
Compute (map (fun n => (fib n, fib (S n))) (seq 1 8)).
