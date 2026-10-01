(* ============================================================ *)
(* 08 λC（构造演算）—— Coq 侧：顶点系统在过日子                  *)
(* Coq 内核 = λC + 归纳类型（CIC）。多态门、依赖门、类型算子门    *)
(* 同时全开，一个文件把三扇门各走一遍                            *)
(* ============================================================ *)

Require Import List Arith.
Import ListNotations.

(* ---- 门 1（多态规则 □ * *）：一份代码全类型 ---- *)
Definition pid {A : Type} (x : A) : A := x.
Check (pid 3, pid true, pid (fun x => x)).

(* 类型算子（(□,□,□)）：以类型为参数、产出【类型】 *)
Definition PairOf (A : Type) : Type := A * A.
Check (PairOf nat).          (* : Type *)
Check ((3, 4) : PairOf nat).

Definition Endo (A : Type) : Type := A -> A.
Check (fun n => n + 1) : Endo nat.

(* ---- 门 2（依赖规则 * □ □）：类型里住项 ---- *)
Definition Vec (A : Type) : nat -> Type :=
  fix vec (n : nat) : Type := match n with 0 => unit | S k => prod A (vec k) end.
Check (Vec nat 3).           (* nat*nat*nat*unit : Type *)
Check ((1, (2, (3, tt))) : Vec nat 3).

(* 谓词（项 → Prop）与全称量化（Π） ---- *)
Definition AllZero (l : list nat) : Prop :=
  fold_right (fun n acc => n = 0 /\ acc) True l.

Check (AllZero [0; 0]) : Prop.

(* ---- 门 3 合体：多态谓词（唯 λC 收的型） ---- *)
Definition Forall {A : Type} (P : A -> Prop) : list A -> Prop :=
  fix go l := match l with
  | [] => True
  | x :: xs => P x /\ go xs
  end.

Check @Forall : forall (A : Type), (A -> Prop) -> list A -> Prop.
(*  Π(A:Type). (A→Prop) → (list A → Prop)：三项能力缺一不可 *)

Example allZero_ok : Forall (fun n => n = 0) [0; 0].
Proof. simpl. auto. Qed.

(* 同一个 Forall 在另一个类型上——多态谓词一次定义处处用 *)
Example allTrue_ok : Forall (fun b => b = true) [true].
Proof. simpl. auto. Qed.

(* ---- Coq 的 Prop 与 Type：非直谓的顶点 ---- *)
(* λC 的逻辑对应是构造演算式的直觉主义高阶逻辑：
   Prop 本身 : Type，且 Prop 上可以再量化——非直谓。
   Girard 悖论被「Prop 的证明无关性 + 受限消去」挡在门外（21 章） *)
Check Prop.       (* : Type *)
Check (fun P : Prop => P -> P).   (* : Prop → Prop，且整体 : Type *)
