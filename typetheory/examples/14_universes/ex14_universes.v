(* ============================================================ *)
(* 14 全域与层级 —— Coq 侧：Type@{i} 与 Prop 两条线               *)
(* ============================================================ *)

Check Type.            (* Type@{Set+1} 之类：Type 有层级 *)
Check nat.             (* nat : Set（Type 的第 0 层） *)
Check (nat -> Set).    (* : Type *)

(* ---- 塔式上楼 ---- *)
Check (Set : Type).          (* Set 本身是 Type 的居留 *)
Check (Type : Type).         (* elaborates 成 Type@{i} : Type@{i+1} *)

(* Type : Type 直接写死会怎样？——层级统一失败： *)
(* Fail Definition bad : Type := Type.  见下方实测 *)

Fail Definition bad1 : Set := Type.

(* ---- 宇宙多态 ---- *)
Definition myId@{u} {A : Type@{u}} (a : A) : A := a.

Check (myId 3).
Check (myId True).
Check (myId nat).      (* A := nat : Set，u := 0 *)
Check (myId Type).     (* A := Type@{i}，更高的 u *)

(* ---- Prop：另一条宇宙线 ---- *)
Check (Prop : Type).
(* Prop : Type，但 Prop 内部是「证明无关」的世界（21 章细讲）；
   Coq 的 Set/Type 是直谓与否取决于旗标（-impredicative-set），
   默认 Set 直谓、Prop 非直谓 *)

(* ---- 类型宇宙的实践：装下「类型 + 居留项」 ---- *)
Record TyAndTerm : Type := mkTT
  { ttA : Type; ttVal : ttA }.

Definition natEx : TyAndTerm := mkTT nat 3.
Check (ttVal natEx).            (* : ttA natEx，一个被藏起来的 nat *)
Compute (ttVal natEx).          (* 3 *)

(* ---- Cumulativity：小层自动进大层 ---- *)
Check (nat : Type).          (* Set ⊂ Type *)
Check ((nat -> nat) : Type).

Print myId.
(* 观察宇宙变量 u 的出现——层级是定义的一部分 *)
