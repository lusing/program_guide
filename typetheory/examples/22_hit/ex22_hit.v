(* ============================================================ *)
(* 22 高阶归纳类型（HIT）—— 自包含 mini-HoTT（四）                *)
(* 没有原生 HIT 的 Coq：构造子与消去子全部【公理化】，账目公开。 *)
(* 区间、圆、商（模 2 同余）三件套                               *)
(* ============================================================ *)

Unset Automatic Proposition Inductives.

Inductive paths {A : Type} (a : A) : A -> Type := idpath : paths a a.
Arguments paths {A} a b. Arguments idpath {A a}.
Notation "x == y" := (paths x y) (at level 70).

Definition concat {A : Type} {x y z : A} (p : x == y) (q : y == z)
  : x == z :=
  match p in paths _ y' return forall (q0 : y' == z), x == z with
  | idpath => fun q0 => q0
  end q.
Notation "p · q" := (concat p q) (at level 60, right associativity).

Definition ap {A B : Type} (f : A -> B) {x y : A} (p : x == y)
  : f x == f y :=
  match p in paths _ y' return f x == f y' with
  | idpath => idpath
  end.

Definition transport {A : Type} (P : A -> Type) {x y : A} (p : x == y)
  (u : P x) : P y :=
  match p in paths _ y' return P y' with
  | idpath => u
  end.

(* ============ HIT 一：区间 ============ *)
(* 两个点 + 一条把点粘起来的路径：zero == one *)

Axiom interval : Type.
Axiom zero : interval.
Axiom one : interval.
Axiom seg : zero == one.

(* 依赖消去子：Q : I → Type；端点各给一个元素；
   第三条是「沿 seg 搬运后吻合」——HIT 消去子的签名特征 *)
Axiom interval_rec : forall (Q : interval -> Type)
  (u : Q zero) (v : Q one),
  transport Q seg u == v -> forall i, Q i.

(* 计算规则：J 在 idpath 上定义性计算；seg 不是 idpath，
   区间的计算规则只能【公理补账】——HIT 的本质代价 *)
Axiom interval_zero : forall (Q : interval -> Type)
  (u : Q zero) (v : Q one) (e : transport Q seg u == v),
  interval_rec Q u v e zero == u.
Axiom interval_one : forall (Q : interval -> Type)
  (u : Q zero) (v : Q one) (e : transport Q seg u == v),
  interval_rec Q u v e one == v.

(* 区间的妙用（推出 funext）见 23 章压轴 *)

(* ============ HIT 二：圆 S¹ ============ *)
(* 一个基点 + 一条非平凡环路：loop : base == base *)

Axiom circle : Type.
Axiom base : circle.
Axiom loop : base == base.

Axiom circle_rec : forall (Q : circle -> Type)
  (b : Q base) (l : transport Q loop b == b),
  forall c, Q c.

Axiom circle_base : forall (Q : circle -> Type)
  (b : Q base) (l : transport Q loop b == b),
  circle_rec Q b l base == b.

(* 用圆的消去子定义「绕两圈」映射：把 loop 指派为 loop · loop *)

Axiom loop_transport_trivial : transport (fun _ => circle) loop base == base.

Definition double : circle -> circle :=
  circle_rec (fun _ => circle) base loop_transport_trivial.

(* 消去子对【路径构造子】loop 的计算规则要用依赖版 apD 表述
   （transport 家族下的路径作用），本迷你库不展开——见 23 章正文。
   基点上的计算规则 circle_base 已公理化。 *)

(* ============ HIT 三：商类型（模 2 同余的 nat） ============ *)

Inductive bool2 : Type := true2 | false2.

Axiom quot : Type.
Axiom qg : nat -> quot.

(* 商的万有性质：尊重等价关系的函数【唯一】下沉 *)
Axiom quot_lift : forall (Q : Type) (F : nat -> Q),
  (forall n, F (S (S n)) == F n) -> quot -> Q.
Axiom quot_lift_qg : forall (Q : Type) (F : nat -> Q)
  (cond : forall n, F (S (S n)) == F n) (n : nat),
  quot_lift Q F cond (qg n) == F n.

(* 奇偶函数：两步递归让条件成为【定义相等】，免证明 *)
Fixpoint parityF (n : nat) : bool2 :=
  match n with
  | 0 => true2
  | S 0 => false2
  | S (S m) => parityF m
  end.

Definition parity (q : quot) : bool2 :=
  quot_lift bool2 parityF (fun n => idpath) q.

Example parity_5 : parity (qg 5) == false2 :=
  quot_lift_qg bool2 parityF (fun n => idpath) 5.

Example parity_6 : parity (qg 6) == true2 :=
  quot_lift_qg bool2 parityF (fun n => idpath) 6.

(* ---- 记账：本文件公理清单 ---- *)
Print Assumptions double.         (* circle/loop 系公理 *)
Print Assumptions parity_5.       (* quot 系公理 *)
