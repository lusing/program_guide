(* ============================================================ *)
(* 07 依赖类型（λP）—— Coq 侧                                    *)
(* 与 Lean 版同构：Vec 索引族 / 谓词即类型 / ∀ 即 Π               *)
(* ============================================================ *)

Require Import Arith Lia.

(* ---- ① 索引族 ---- *)

Inductive Vec (A : Type) : nat -> Type :=
| vnil : Vec A 0
| vcons : forall {n}, A -> Vec A n -> Vec A (S n).

Arguments vnil {A}.
Arguments vcons {A n} x xs.

Fixpoint vappend {A} {n m} (xs : Vec A n) (ys : Vec A m) : Vec A (n + m) :=
  match xs with
  | vnil => ys
  | vcons x xs' => vcons x (vappend xs' ys)
  end.

Check @vappend : forall (A : Type) (n m : nat), Vec A n -> Vec A m -> Vec A (n + m).

(* 头部只对非空向量开放：S n 索引即「非空证明」 *)
Definition vhead {A} {n} (v : Vec A (S n)) : A :=
  match v with vcons x _ => x end.

(* vhead vnil —— 无法类型检查：0 ≠ S ?n。非法调用无法表示。 *)

Fixpoint vreplicate {A} (n : nat) (a : A) : Vec A n :=
  match n with
  | 0 => vnil
  | S n' => vcons a (vreplicate n' a)
  end.

(* 类型检查器替我们算 2 + 3 = 5 *)
Example append_replicate :
  vappend (vreplicate 2 7) (vreplicate 3 7) = vreplicate 5 7.
Proof. reflexivity. Qed.

(* ---- ② 谓词即类型 ---- *)

Inductive Even : nat -> Prop :=
| even_z : Even 0
| even_ss : forall n, Even n -> Even (S (S n)).

Definition four_even : Even 4 := even_ss 2 (even_ss 0 even_z).

(* ---- ③ 全称量词即 Π ---- *)

Theorem ss_even : forall n, Even n -> Even (2 + n).    (* Coq 的 + 递归在第一参数：2 + n 折叠为 S (S n) *)
Proof. intros n H. apply even_ss. exact H. Qed.

(* 归纳 + lia 缝合 defeq 缝隙（Coq 的 + 在第一参数上递归，
   (S n) + (S n) 折叠为 S (n + S n)，与 S (S (n+n)) 数字相等
   定义不等地） *)
Theorem even_double : forall n, Even (n + n).
Proof.
  intro n. induction n as [| n IH].
  - apply even_z.
  - simpl.
    assert (key : n + S n = S (n + n)) by lia.
    rewrite key.
    apply even_ss. exact IH.
Qed.

(* ---- ④ λP 规则的日常化身 ---- *)

Check (fun (n : nat) (v : Vec nat n) => vappend v vnil).
(* forall n, Vec nat n -> Vec nat (n + 0) —— Π 的类型写进了参数 *)


