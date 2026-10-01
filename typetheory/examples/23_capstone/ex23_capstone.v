(* ============================================================ *)
(* 23 综合：圆周 S¹ 上的环路代数 —— 自包含 mini-HoTT（五）       *)
(* 任务：iterate (m + n) == iterate m · iterate n 完整证明       *)
(* （环路「绕 m+n 圈 = 先绕 m 圈再绕 n 圈」——π₁(S¹) 的加法前身）*)
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

Definition inverse {A : Type} {x y : A} (p : x == y) : y == x :=
  match p in paths _ y' return y' == x with idpath => idpath end.
Notation "! p" := (inverse p) (at level 65).

Definition ap {A B : Type} (f : A -> B) {x y : A} (p : x == y)
  : f x == f y :=
  match p in paths _ y' return f x == f y' with
  | idpath => idpath
  end.

(* ---- 圆 S¹（公理化 HIT，同 22 章） ---- *)

Axiom circle : Type.
Axiom base : circle.
Axiom loop : base == base.

(* ---- 环路代数：绕 n 圈 ---- *)

Fixpoint iterate (n : nat) : base == base :=
  match n with
  | 0 => idpath
  | S m => loop · iterate m
  end.

(* 预备：结合律（对 p 归纳，idpath 情形两侧都折叠） *)
Definition concat_assoc {A : Type} {x y z w : A}
  (p : x == y) (q : y == z) (r : z == w)
  : (p · q) · r == p · (q · r) :=
  match p as p0 in paths _ y' return forall (q0 : y' == z),
    (p0 · q0) · r == p0 · (q0 · r) with
  | idpath => fun q0 => idpath
  end q.

(* 主定理：绕 m+n 圈 = 绕 m 圈接绕 n 圈 *)
Theorem iterate_add (m n : nat)
  : iterate (m + n) == (iterate m) · (iterate n).
Proof.
  induction m as [| m IH]; simpl.
  - (* iterate n == idpath · iterate n：左侧定义折叠，直接 refl *)
    exact idpath.
  - (* iterate (S m + n) == (loop · iterate m) · iterate n
       = loop · iterate (m+n)  ─ap─▶  loop · (iterate m · iterate n)
       ─assoc⁻¹─▶ (loop · iterate m) · iterate n               *)
    refine (ap (fun X => loop · X) IH · _).
    exact (inverse (concat_assoc loop (iterate m) (iterate n))).
Defined.

(* 推论一：环路的「圈数」对加法保持——π₁(S¹) 里 ℤ 的加法结构前身 *)
Corollary iterate_2_3 : iterate (2 + 3) == (iterate 2) · (iterate 3).
Proof. apply iterate_add. Defined.

(* 推论二（表述留给正文练习）：! iterate n == iterate (0 - n)
   完整证明需要 (p·q)⁻¹ == q⁻¹·p⁻¹（同样是单步 J 的引理）——
   组装方式与 iterate_add 同构，此处不机器化。 *)

(* ---- 记账 ---- *)
Print Assumptions iterate_add.
(* loop（S¹ 的公理化构造子）是唯一依赖——本章没有别的公理 *)

(* ---- 23 章正文的两个「未在此机器化」的陈述（诚实清单） ---- *)
(* 1. loop ≠ idpath：需要 encode-decode（Ω(S¹) ≃ ℤ），
      完整机器版见本仓库 coq-hott 教程 13 章（官方 HoTT 库实现）。
   2. funext-from-interval：区间 HIT 的消去子在常值族上的
      条件 transport_const seg u == u 是 J-定理（19 章已证形态），
      但把它组装成 funext 需要 eta/计算规则的配合，
      本迷你库不展开（HoTT 书 4.9/6.3 讨论）。 *)
