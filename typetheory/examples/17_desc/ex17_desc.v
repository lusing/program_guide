(* ============================================================
   17 描述算子、选择与引用 —— Coq 侧（Farmer ch.14）
   ClassicalDescription 的 iota 就是确定描述算子 I 的古典实现：
     · iota + iota_spec ：唯一满足者可被「选出」并被证明满足
     · epsilon + epsilon_spec ：不定描述 ε——有满足者即选一个
     · Prop 14.1 机器版：I 可由 ε 定义（双方向等值）
     · ClassicalChoice ：选择公理的函数版——AC 在古典世界里是定理
     · 引用：深度嵌入的语法树 + quote/eval 往返定理（V8/V9 的样本）
   ============================================================ *)

From Coq Require Import ClassicalDescription ClassicalEpsilon ClassicalChoice.
From Coq Require Import Arith Lia.

(* ---- I 算子的古典样本：唯一 n 使 n*n = 4（Nat 上只有 2） ---- *)

Definition square4 (n : nat) : Prop := n * n = 4.

Lemma square4_eq2 : forall n, square4 n -> n = 2.
Proof.
  intros n H. unfold square4 in H.
  destruct (le_lt_dec n 2) as [Hle | Hgt].
  - destruct n as [|[|n]]; simpl in *; try reflexivity; lia.
  - exfalso.
    assert (H9 : 3 * 3 <= n * n) by (apply Nat.mul_le_mono; lia).
    simpl in H9. lia.
Qed.

Lemma square4_unique : exists! n, square4 n.
Proof.
  exists 2. split.
  - reflexivity.
  - intros a Ha. symmetry. apply (square4_eq2 a Ha).
Qed.

Definition nat_inh : inhabited nat := inhabits 0.
Definition two_by_iota : nat := iota 0 square4.

Theorem iota_two : two_by_iota = 2.
Proof.
  unfold two_by_iota.
  apply square4_eq2.
  apply iota_spec. exact square4_unique.
Qed.

(* ---- ε：不定描述——有满足者即选一个（无需唯一） ---- *)

Definition some_even : nat := epsilon nat_inh (fun n => Nat.even n = true).

(* ε 的承诺是「存在即满足」；具体选谁由实现决定 *)
Theorem some_even_is_even :
  (exists n, Nat.even n = true) -> Nat.even some_even = true.
Proof.
  intros H. unfold some_even. apply (epsilon_spec nat_inh). exact H.
Qed.

(* ---- Prop 14.1 机器版：I 可由 ε 定义 ---- *)

Definition iota_via_eps (P : nat -> Prop) : nat :=
  epsilon nat_inh (fun x => P x /\ exists! y, P y).

(* Prop 14.1：唯一性下 I 与「ε 定义版」给出同一个见证 *)
Theorem iota_eps_agree (P : nat -> Prop) :
  (exists! x, P x) -> iota_via_eps P = iota 0 P.
Proof.
  intros [x [Hx Huni]].
  assert (Hex : exists y, P y /\ exists! z, P z).
  { exists x. split.
    - exact Hx.
    - exists x. split.
      + exact Hx.
      + intros y Hy. exact (Huni y Hy). }
  assert (Heps : P (iota_via_eps P)).
  { unfold iota_via_eps.
    apply (epsilon_spec nat_inh (fun y => P y /\ exists! z, P z) Hex). }
  assert (Hiota : P (iota 0 P)).
  { apply iota_spec. exists x. split.
    - exact Hx.
    - intros y Hy. exact (Huni y Hy). }
  transitivity x.
  - symmetry. apply Huni. exact Heps.
  - apply Huni. exact Hiota.
Qed.

(* ---- 选择公理：AC 在古典逻辑里是定理 ---- *)

(* 点对 (x, 2*x) 的关系；选择函数一次性给出 *)
Theorem ac_pointwise :
  exists f : nat -> nat, forall x, f x = 2 * x.
Proof.
  apply (choice (fun x y => y = 2 * x)).
  intros x. exists (2 * x). reflexivity.
Qed.

(* ---- 记账：古典公理清单（mini-HoTT 的 Print Assumptions 传统） ---- *)

Print Assumptions iota_two.
(* -> classical_choice, dependent_unique_choice, propextensionality... *)

(* ============================================================
   引用与求值：深度嵌入的往返定理（AlonzoQE 的 V8/V9 样本）
   ============================================================ *)

(* 小表达式语言：数、加、乘 *)
Inductive exp : Type :=
  | Num : nat -> exp
  | Plus : exp -> exp -> exp
  | Mul : exp -> exp -> exp.

(* 语义（浅层） *)
Fixpoint sem (e : exp) : nat :=
  match e with
  | Num n => n
  | Plus a b => sem a + sem b
  | Mul a b => sem a * sem b
  end.

(* ε 型：语法本身当值——q_* 就是「构造子的逻辑常数版」（表 14.5） *)
Definition q_num (n : nat) : exp := Num n.
Definition q_plus (a b : exp) : exp := Plus a b.
Definition q_mul (a b : exp) : exp := Mul a b.

(* Ω：表达式到「构造」的映射——按 14.3.2 的递归逐构造子爬行 *)
Fixpoint omega (e : exp) : exp :=
  match e with
  | Num n => q_num n
  | Plus a b => q_plus (omega a) (omega b)
  | Mul a b => q_mul (omega a) (omega b)
  end.

(* ⌜·⌝：引用 = 把浅层数据提升为语法 *)
Definition quote_nat (n : nat) : exp := Num n.

(* 往返：Ω 是恒等（构造子与逻辑常数一一对应时引用不丢信息） *)
Theorem omega_id : forall e, omega e = e.
Proof.
  induction e as [n | a IHa b IHb | a IHa b IHb]; simpl;
    try reflexivity; rewrite IHa, IHb; reflexivity.
Qed.

(* 「求值引用」= 求值浅层语义 *)
Theorem eval_quote_sem : forall n, sem (quote_nat n) = n.
Proof.
  intros n. reflexivity.
Qed.

(* 复合往返：求值一个引用了表达式的语法树 *)
Theorem eval_of_quoted : forall e, sem (omega e) = sem e.
Proof.
  intros e. rewrite omega_id. reflexivity.
Qed.
