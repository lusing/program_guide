(* ============================================================ *)
(* 09 定义与证明工程（λD 精神）—— Coq 侧                        *)
(* TTAFP ch.8–11：定义是保守扩张 + δ-归约；工程上要管住三件事：  *)
(* ① 全局/局部；② 透明/不透明；③ 记法与 Section 的批量泛化       *)
(* ============================================================ *)

Require Import Arith List Lia.
Import ListNotations.

(* ---- ① 全局定义：透明的 δ ---- *)
Definition twice (f : nat -> nat) (n : nat) : nat := f (f n).

Print twice.                (* 展开式可见 *)
Compute twice (fun n => n + 3) 1.          (* 7：定义性求值畅通 *)

(* ---- ② 局部定义：Let ---- *)
Definition local_demo : nat :=
  let x := 2 in let y := 40 in x + y.
Compute local_demo.         (* 42 *)

(* ---- ③ 透明 vs 不透明：Qed 的墙 ---- *)

Lemma twice_succ_1 : twice S 1 = 3.
Proof. reflexivity. Qed.    (* reflexivity 要 δ 展开 twice + β——通明墙下畅通 *)

(* Qed 封装的引理默认不透明：simpl 不再展开 *)
Lemma twice_add_0 : forall n, twice (fun m => m + 0) n = n.
Proof.
  intro n. unfold twice.     (* 显式 δ：定义透明的部分仍可手工展开 *)
  induction n as [| n IH].
  - simpl. reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* 对比：如果把定理写成 Definition（透明），可以纯 rfl 直收。
   注意方向：Coq 的 + 递归在【第一】参数，0 + m 按定义折叠成 m *)
Definition twice_add_0' : forall n, twice (fun m => 0 + m) n = n :=
  fun n => eq_refl.          (* twice (0+·) n = 0 + (0 + n) ≡ n *)

(* ---- ④ Notation：语法的保守扩张 ---- *)
Notation "x ⨯ y" := (prod x y) (at level 40, left associativity).
Check (3, 4) : nat ⨯ nat.

(* ---- ⑤ Section：假设的批量管理与自动泛化 ---- *)
Section MonoidLike.
  Variable U : Type.                 (* Section 级变量 *)
  Variable op : U -> U -> U.
  Hypothesis op_assoc : forall x y z, op (op x y) z = op x (op y z).
  Variable e : U.
  Hypothesis e_left : forall x, op e x = x.

  (* 段内证明照常引用，不用带前提 *)
  Lemma op_e_left_twice : forall x, op e (op e x) = x.
  Proof.
    intro x.
    rewrite <- op_assoc.     (* op e (op e x) → op (op e e) x *)
    rewrite e_left, e_left.  (* op e e → e，再 op e x → x *)
    reflexivity.
  Qed.

  (* 段内再引理一次：用上两条假设 *)
  Lemma e_id_unique_l : forall x, op e x = op e e -> x = e.
  Proof.
    intros x H. rewrite e_left in H. rewrite e_left in H.
    exact H.
  Qed.
End MonoidLike.

(* 段一关：所有引理自动泛化了 Section 变量！ *)
Check op_e_left_twice.
(* : forall U op, (forall x y z, …) -> forall e, (forall x, op e x = x) -> … *)
(* 加法结合律的方向与段内声明相反，eq_sym 转向 *)
Check (op_e_left_twice nat Nat.add
         (fun x y z => eq_sym (Nat.add_assoc x y z)) 0 Nat.add_0_l
       : forall x, 0 + (0 + x) = x).

(* 复用：同一节定理换一套例化（表拼接）。隐式 A 用 @ 显式给；
   app_assoc 同样要转向 *)
Check (op_e_left_twice (list nat) (@app nat)
         (fun x y z => eq_sym (@app_assoc nat x y z)) nil (@app_nil_l nat)).

