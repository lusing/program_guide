(* ex33_realclosed.v —— 实闭域与 o-minimality（Marker ch8）
   机器件：IVT 二分求根（ℚ 上 √2，精确有理区间收缩）；
   半代数符号条件的区间结构（网格验证）；o-minimal 有限影子
   （{<} 可定义=区间 vs 野谓词可定义=任意集——Z 在 R 中不可定义
   的论证骨架）；旗舰——Motzkin 多项式 M=x⁴y²+x²y⁴−3x²y²+1：
   有理函数 SOS 分解的恒等式 ring 验证 + 半格对角 Gram（非多项式
   SOS 的核心账本）。 *)

From Stdlib Require Import List Arith Lia ZArith.
Import ListNotations.
Local Open Scope Z_scope.

(* ---------- 1. 旗舰：Motzkin 多项式的两条账本 ---------- *)

Definition mx (x y : Z) : Z := x*x*x*x * y*y + x*x * y*y*y*y - 3 * x*x * y*y + 1.

(* 账本①（非 SOS 的核心）：M = (x²y)² + (xy²)² − 3·(xy)² + 1 ——
   半格 {(2,1),(1,2),(1,1),(0,0)} 上的 Gram 被**强制对角**且出现
   负系数 −3（交叉项 x³y³、x³y、xy³ 在 M 中为零 ⟹ 交叉系数全零；
   文档线引 Reznick 半 Newton 多胞形定理：多项式 SOS 可整体搬到
   半格——于是 −3·(xy)² 无法写成平方和 ⟹ M 非多项式 SOS） *)
Example motzkin_diag :
  forall x y : Z,
    mx x y =
    (x*x*y)*(x*x*y) + (x*y*y)*(x*y*y) - 3*(x*y)*(x*y) + 1.
Proof. intros. unfold mx. ring. Qed.

(* 账本②（Hilbert 第 17 的正现场）：分母 x²y²+1 下的三项平方和
   M·(x²y²+1) = (x³y²−xy²)² + (x²y³−x²y)² + (x²y²−1)² *)
Example motzkin_sos :
  forall x y : Z,
    mx x y * (x*x * y*y + 1) =
    (x*x*x * y*y - x * y*y) * (x*x*x * y*y - x * y*y)
  + (x*x * y*y*y - x*x * y) * (x*x * y*y*y - x*x * y)
  + (x*x * y*y - 1) * (x*x * y*y - 1).
Proof. intros. unfold mx. ring. Qed.

(* 非负性（AM-GM：a+b+c ≥ 3(abc)^{1/3}，a=x⁴y²,b=x²y⁴,c=1）：
   分母恒正 + 三平方和 ⟹ M ≥ 0。网格抽样账： *)
Definition mgrid (bd : Z) : bool :=
  forallb (fun x =>
    forallb (fun y => 0 <=? mx (Z.of_nat x) (Z.of_nat y)) (seq 0 (Z.to_nat bd)))
    (seq 0 (Z.to_nat bd)).

Example motzkin_nonneg_grid : mgrid 12 = true.
Proof. reflexivity. Qed.

(* ---------- 2. IVT 二分求根（ℚ 上 √2 的精确收缩） ---------- *)

Close Scope Z_scope.
From Stdlib Require Import QArith Qring Qcanon.
Local Open Scope Q_scope.

Definition fq (q : Q) : Q := q * q - 2.

Fixpoint bisect (a b : Q) (n : nat) : Q * Q :=
  match n with
  | O => (a, b)
  | S n' =>
      let m := Qred (Qdiv (a + b) 2) in
      if Qle_bool (fq m * fq a) 0 then bisect a m n'
      else bisect m b n'
  end.

(* 20 层二分：区间 [1,2] 收缩——7/5 < √2 < 17/12 的精确夹逼 *)
Example bisect_sandwich :
  andb (Qle_bool (7#5) (fst (bisect 1 2 20)))
       (Qle_bool (snd (bisect 1 2 20)) (17#12)) = true.
Proof. reflexivity. Qed.

Example bisect_width :
  Qle_bool (snd (bisect 1 2 20) - fst (bisect 1 2 20)) (1 # 524288) = true.
Proof. reflexivity. Qed.   (* 2^-19 = 1/524288 *)

Example bisect_bracket :
  andb (Qle_bool (fq (fst (bisect 1 2 20))) 0)
       (Qle_bool 0 (fq (snd (bisect 1 2 20)))) = true.
Proof. reflexivity. Qed.

Compute (fst (bisect 1 2 20)).   (* ≈ 1.4142135…—— √2 的左逼近 *)

(* ---------- 3. 半代数符号条件：区间结构 ---------- *)

Close Scope Q_scope.

(* 网格上的符号表：f(x) = x³ − 3x + 1（三个实根的经典形状） *)
Definition fx3 (x : Z) : Z := x*x - 6*x + 5.   (* (x-1)(x-5) *)

Definition grid (n : nat) : list Z := map Z.of_nat (seq 0 n).

Definition zsign (z : Z) : Z :=
  match z with
  | Z0 => 0
  | Zpos _ => 1
  | Zneg _ => -1
  end.

Definition signTable (f : Z -> Z) (n : nat) : list Z :=
  map (fun x => zsign (f x)) (grid n).

Example sign_fx3 :
  signTable fx3 10 = [1%Z; 0%Z; (-1)%Z; (-1)%Z; (-1)%Z; 0%Z; 1%Z; 1%Z; 1%Z; 1%Z].
Proof. reflexivity. Qed.

(* 变号点分隔：{x : f(x) < 0} 在网格上是连续段 [2,4]——
   一维半代数集=有限区间并的网格影子（相邻段由变号点分隔） *)
Example negset_is_interval :
  map (fun x => Z.ltb (fx3 x) 0) (grid 10)
  = [false; false; true; true; true; false; false; false; false; false].
Proof. reflexivity. Qed.

(* ---------- 4. o-minimality 有限影子 ---------- *)

(* 线序语言 {<}：原子 x<k / x=k 的合取在有限链 [0,8) 上定义的
   集合全是区间——枚举验证（等式+不等合取=单点或区间） *)
Inductive oat : Type :=
| olt (k : nat)
| oeq (k : nat).

Definition oeval (a : oat) (x : nat) : bool :=
  match a with
  | olt k => x <? k
  | oeq k => Nat.eqb x k
  end.

Definition odef (as_ : list oat) (x : nat) : bool :=
  forallb (fun a => oeval a x) as_.

(* 区间性检查：真值段连续 *)
(* 单区间检查：剥掉前导 false，之后一旦出现 false 全 false *)
Fixpoint stripF (l : list bool) : list bool :=
  match l with
  | false :: t => stripF t
  | _ => l
  end.

Fixpoint tailF (l : list bool) : bool :=
  match l with
  | [] => true
  | true :: t => tailF t
  | false :: t => forallb (fun b => negb b) t
  end.

Definition isOneRun (l : list bool) : bool := tailF (stripF l).

(* 幂集 *)
Fixpoint subsets {A : Type} (l : list A) : list (list A) :=
  match l with
  | [] => [[]]
  | a :: t => subsets t ++ map (cons a) (subsets t)
  end.

(* 全部 2^4 个原子合取都给出连续段 *)
Definition atomPool : list oat :=
  [olt 3; olt 5; oeq 2; oeq 4].

Example order_definable_are_intervals :
  forallb (fun as_ => isOneRun (map (odef as_) (seq 0 8)))
    (subsets atomPool) = true.
Proof. reflexivity. Qed.

(* 加一个野谓词 P（棋盘式）：P(x) 可定义出交错集——非区间 *)
Definition Pwild (x : nat) : bool := Nat.odd x.

Example wild_definable_not_interval :
  negb (isOneRun (map Pwild (seq 0 8))) = true.
Proof. reflexivity. Qed.

(* 这就是「Z 在 R 中不可定义」的骨架（Cor 8.24）：RCF 量词消去 ⟹
   可定义集=半代数=有限区间并（o-minimal）；ℤ 是无限离散集，
   不是任何有限区间并——文档线讲清从有限影子到 R 的推理 *)
