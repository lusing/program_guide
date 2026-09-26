(* 20 决策过程 —— ring / lia / nia / field / lra / tauto / congruence *)

From Stdlib Require Import Arith ZArith Lia.
From Stdlib Require Import Reals Lra Classical.

Module Ex20Decision.

(* ---------- 20.1 ring：环等式的自动机 ---------- *)

(* 加乘展开、配方、移项——只要 + - * 和数字常量，交给 ring *)
Theorem ring_z : forall x y : Z,
  ((x + y) * (x + y) = x * x + 2 * x * y + y * y)%Z.
Proof. intros x y. ring. Qed.

(* nat 也行（半环：没有减法的环） *)
Theorem ring_nat : forall x y : nat,
  (x + y) * (x + y) = x * x + 2 * x * y + y * y.
Proof. intros x y. ring. Qed.

(* 实测坑 1：ring 无视上下文假设——H : x = 3 摆在那里它也不看，
   先 rewrite 把已知值代进去，ring 才能收 *)
Example ring_no_hyp : forall x : Z, ((x = 3 -> x * x = 9))%Z.
Proof. intros x H. rewrite H. ring. Qed.

(* 实测坑 2：ring 看不见定义——dbl 对它是原子，
   先 unfold 展开成多项式，ring 才认识 *)
Definition dbl (n : nat) := n + n.
Theorem ring_opaque : forall n m : nat, dbl (n + m) = dbl n + dbl m.
Proof. intros n m. unfold dbl. ring. Qed.

(* 版本演进（实测）：8.x 时代 ring 不认识 S n，教材里要用专门策略
   把 S n 改写成 n + 1 再 ring；9.1 的 ring 已能直接吃下 S n *)

(* ring_simplify：把等式两边规整成范式（只规整不收尾，通常跟一刀收） *)
Example ring_simplify_ex : forall n m : Z,
  (((n + m) * (n + m) - n * n = m * m + 2 * n * m))%Z.
Proof. intros n m. ring_simplify. ring. Qed.

(* ---------- 20.2 lia：线性整数算术的自动机 ---------- *)

(* lia 是「假设挖掘机」：上下文里的线性和非线性信息都拿去用，
   合取式自动拆解——下面 H 只是一条，lia 自己拆出 x <= y 和 y <= z *)
Theorem lia_mines_conj : forall x y z : Z,
  ((x <= y /\ y <= z -> x <= z))%Z.
Proof. intros x y z H. lia. Qed.

(* lia 的线性边界：把非线性子项当「黑盒原子」——
   x * x 整体记作 X，0 <= X 与 3 * X <= 2 * y 是关于 X、y 的线性约束 *)
Theorem lia_blackbox : forall x y : Z,
  ((0 <= x * x -> 3 * (x * x) <= 2 * y -> x * x <= y))%Z.
Proof. intros x y H0 H1. lia. Qed.

(* 黑盒只是「视而不见」，不是「会推理」：同一个 x*x，
   换个写法 (x*x)*1 就认不出来了——lia 在这里会失败，nia 能收
   （nia = nonlinear lia，对乘积做启发式推理） *)
Theorem nia_nonlinear : forall x y : Z,
  ((0 <= x -> 0 <= y -> (x + y) * (x + y) >= 0))%Z.
Proof. intros x y Hx Hy. nia. Qed.
(* 这类目标 lia 无能为力：展开后的 x * x 项需要非线性的符号推理 *)

(* ---------- 20.3 field 与 lra：实数上的两件套 ---------- *)

(* field：域上的 ring（多除法）。化简除法会挖出「除数非零」副目标 *)
Example field_ex : forall x y : R,
  ((y <> 0 -> (x + y) / y = 1 + x / y))%R.
Proof.
  intros x y H.
  field.        (* 主目标收掉，留下副目标：y <> 0 *)
  assumption.   (* 副目标正是手头的假设 H *)
Qed.

(* lra：实数线性算术（老教材的 fourier 策略 8.9 起弃用，现名 lra） *)
Example lra_ex : forall x y : R,
  (((x - y > 1 -> x - 2 * y < 0 -> y > 1)))%R.
Proof. intros x y H1 H2. lra. Qed.

(* ---------- 20.4 命题层决策：tauto / intuition / congruence ---------- *)

(* tauto：直觉主义命题逻辑的永真式判定器。
   auto 证不了下面这条（它不会拆假设里的合取），tauto 一击收 *)
Theorem tauto_ex : forall P Q : Prop, P /\ ~ P -> Q.
Proof. intros P Q H. tauto. Qed.

(* 但 tauto 也有天花板：~~P -> P 不是直觉主义定理，
   需要经典逻辑公理——Classical 里的 NNPP（见 25 章 Print Assumptions） *)
Theorem nnpp : forall P : Prop, ~ ~ P -> P.
Proof. intros P H. apply NNPP. exact H. Qed.

Print Assumptions nnpp.
(* Axioms:
     classic : forall P : Prop, P \/ ~ P
   ——它建立在排中律公理上，不是构造性证明 *)

(* intuition：先把命题结构自动拆解，再用给定策略收拾残余算术目标 *)
Theorem intuition_ex : forall n p q : nat,
  n <= p \/ n <= q -> n <= p \/ n <= S q.
Proof. intros n p q H. intuition lia. Qed.

(* congruence：等式与不等式的同余推理——
   x = y 时 f x = f y，构造子冲突它也看得出 *)
Theorem congruence_ex : forall (f : nat -> nat) x y, x = y -> f x = f y.
Proof. intros f x y H. congruence. Qed.

Theorem congruence_neq : forall x y : nat, S x = 0 -> y = x.
Proof. intros x y H. congruence. Qed.
(* 构造子冲突（S _ = O 不可能）被 congruence 识别，
   假设一废，目标里的 y 随便什么都能推出来 *)

End Ex20Decision.
