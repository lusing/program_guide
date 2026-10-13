(* 第 18 章 布尔值模型 V^B：(18.11)-(18.14) 的定义骨架 *)
Require Import Arith Lia Lists.List.
Import ListNotations.

(* V^B 的元素用抽象类型表示；其"值函数"由接口提供 *)
Section VB.
Variable B : Type.                  (* 完备布尔代数 *)
Variable VB : Type.                 (* V^B 的元素 *)
Variable dom_list : VB -> list VB.  (* dom(y) 的有限枚举 *)
Variable yval : VB -> VB -> B.      (* y(t)：y 在 t 处的布尔值 *)
Variable eq_val : VB -> VB -> B.    (* ‖x = t‖ *)
Variable mem_val : VB -> VB -> B.   (* ‖t ∈ y‖ *)
Variable bjoin : list B -> B.
Variable bmeet : list B -> B.
Variable bimp : B -> B -> B.
Variable bmul : B -> B -> B.

(* ‖x ∈ y‖ = ⋁_{t ∈ dom(y)} (‖x = t‖ ⇒ y(t))  (18.11) *)
Definition bVal_mem (x y : VB) : B :=
  bjoin (map (fun t => bimp (eq_val x t) (yval y t)) (dom_list y)).

(* ‖x ⊆ y‖ = ⋀_{t ∈ dom(x)} (x(t) ⇒ ‖t ∈ y‖)  (18.12) *)
Definition bVal_sub (x y : VB) : B :=
  bmeet (map (fun t => bimp (yval x t) (mem_val t y)) (dom_list x)).

(* ‖x = y‖ = ‖x ⊆ y‖ · ‖y ⊆ x‖  (18.14) *)
Definition bVal_eq (x y : VB) : B :=
  bmul (bVal_sub x y) (bVal_sub y x).

End VB.

Print Assumptions bVal_eq.
