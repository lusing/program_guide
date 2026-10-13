(* 第 11 章 传递模型：Mostowski 坍缩的有限版 *)

Require Import Arith Lia Lists.List.
Import ListNotations.

(* 嵌套列表作为集合编码（HF 形态） *)
Inductive HFL : Type :=
| hfl : list HFL -> HFL.

(* ---------- 一、坍缩：良基图（ext 函数）→ 集合编码 ----------
   π(x) = {π(z) : z ∈ ext(x)}，对深度归纳（fuel 界保证终止）。 *)

Section Collapse.

Variable ext : nat -> list nat.

Fixpoint collapse (x : nat) (fuel : nat) : HFL :=
  match fuel with
  | 0 => hfl []
  | S f =>
      hfl (map (fun z => collapse z f) (ext x))
  end.

End Collapse.

(* ---------- 二、von Neumann 链的坍缩验证 ---------- *)

Definition ext_vn (x : nat) : list nat :=
  match x with
  | 0 => []
  | 1 => [0]
  | 2 => [0; 1]
  | _ => [0; 1; 2]
  end.

(* π(0) = ∅ *)
Example collapse_vn_0 : collapse ext_vn 0 1 = hfl [].
Proof. reflexivity. Qed.

(* π(1) = {∅} *)
Example collapse_vn_1 : collapse ext_vn 1 2 = hfl [hfl []].
Proof. reflexivity. Qed.

(* π(2) = {∅, {∅}} *)
Example collapse_vn_2 : collapse ext_vn 2 3 = hfl [hfl []; hfl [hfl []]].
Proof. reflexivity. Qed.

(* ---------- 三、外延性与单射性（讲义） ----------
   π 单射 ⟺ E 外延（定理 28 的 (11.7) 方向）：若 ext(x) 与
   ext(y) 的坍缩像相同，则 π(x) = π(y)——外延性回推 x = y。
   注意坍缩依赖 ext 在**传递闭包**上的取值（非单点）——
   单射性的完整验证由计算通道（Julia is_extensional 的
   规范化对比）承载。 *)

Print Assumptions collapse_vn_2.
