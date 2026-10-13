(* 第 13 章 AC 与 GCH 在 L：<_L 的构造序骨架 *)

Require Import Arith Lia Lists.List.
Import ListNotations.

(* ---------- 一、出生证：层号函数 ----------
   birth(x) = x 首次进入 L 层级的层号。<_L 的第一坐标。 *)

(* 集合编码：嵌套列表 *)
Inductive HFL : Type :=
| hfl : list HFL -> HFL.

(* 构造：从已有集合生成新集合（配对为代表运算） *)
Definition g_pair (x y : HFL) : HFL := hfl [x; y].

(* birth 的上界版：可构造层号的测定。嵌套 list 的 guard
   限制（09 章同款坑）用燃料解。 *)
Fixpoint maxl (f : HFL -> nat) (l : list HFL) : nat :=
  match l with
  | [] => 0
  | y :: rest => Nat.max (f y) (maxl f rest)
  end.

Fixpoint birth_bound (fuel : nat) (x : HFL) : nat :=
  match fuel with
  | 0 => 0
  | S f =>
      match x with
      | hfl [] => 0
      | hfl l => S (maxl (birth_bound f) l)
      end
  end.

(* 配对运算使层号恰 +1（Gödel 运算的层控制，精确版） *)
Lemma birth_pair :
  forall x y f,
    birth_bound (S f) (g_pair x y)
      = S (Nat.max (birth_bound f x) (birth_bound f y)).
Proof.
  intros x y f. simpl.
  rewrite Nat.max_0_r. reflexivity.
Qed.

(* ---------- 二、<_L 的骨架（字典序） ----------
   x <_L y ⟺ (birth x, 分解序, 分解分量) 字典序 < y 的对应。
   教学版只实现第一坐标（层号）。 *)

Definition lt_L_first (fuel : nat) (x y : HFL) : Prop :=
  birth_bound fuel x < birth_bound fuel y.

(* 层号严格下降于成员（构造性的层控制；燃料同步） *)
Lemma birth_mem :
  forall m rest f,
    S (birth_bound f m) <= birth_bound (S f) (hfl (m :: rest)).
Proof.
  intros m rest f. simpl. lia.
Qed.

Print Assumptions birth_mem.
