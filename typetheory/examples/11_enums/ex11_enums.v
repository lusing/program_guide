(* ============================================================ *)
(* 11 Π 与枚举集合 —— Coq 侧（与 Lean 版同构）                    *)
(* ============================================================ *)

(* ---- 空集合：无构造子 ---- *)
Inductive Empty2 : Set := .

(* 消去子：爆炸原理的原型 *)
Definition absurdE (A : Type) : Empty2 -> A :=
  fun e => match e with end.

Definition Not2 (A : Type) : Type := A -> Empty2.

(* ---- 单元素集合 ---- *)
Inductive Unit2 : Type := star2.

Definition unitElim (A : Type) (a : A) : Unit2 -> A :=
  fun _ => a.

(* ---- Bool ---- *)
Inductive Bool2 : Type := true2 | false2.

Definition if2 (A : Type) (b : Bool2) (t e : A) : A :=
  match b with true2 => t | false2 => e end.

Definition not2 (b : Bool2) : Bool2 := if2 Bool2 b false2 true2.
Definition and2 (a b : Bool2) : Bool2 := if2 Bool2 a b false2.
Definition or2  (a b : Bool2) : Bool2 := if2 Bool2 a true2 b.

Example and_tt : and2 true2 false2 = false2 := eq_refl.
Example demorgan : forall a b, not2 (and2 a b) = or2 (not2 a) (not2 b).
Proof. intros a b. destruct a, b; reflexivity. Qed.

(* ---- 构造子互斥：discriminate ---- *)
Theorem true_ne_false : true2 <> false2.
Proof. discriminate. Qed.

(* 手工版：沿等式搬运「真假性」 *)
Definition bool2True : Bool2 -> Prop :=
  fun b => match b with true2 => True | false2 => False end.

Theorem true_ne_false' : true2 = false2 -> False.
Proof.
  intro H. change (bool2True false2). rewrite <- H. exact I.
Qed.

(* ---- Π on Bool：依赖函数 = 按构造子给分量的表 ---- *)
Definition bothCases (P : Bool2 -> Type) (pt : P true2) (pf : P false2)
  : forall b, P b :=
  fun b => match b with true2 => pt | false2 => pf end.

(* Bool2 上的归纳原理（自动生成，打印欣赏） *)
Print Bool2_ind.
(* forall P : Bool2 -> Prop, P true2 -> P false2 -> forall b, P b
   —— 依赖版本的 case：命题族上「两行填表」 *)

