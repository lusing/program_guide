(* ex47_recfn.v —— 递归函数与部分递归（Mendelson §3.3 + §5.3/5.4 文档线）
   初始函数 Z/N/U + 复合(IV) + 原始递归(V) = PR；+限制 μ(VI) = 递归。
   求值器：itup（闭包参数化嵌套递归）+ 逐函数步进方程（rfl）是证明的钥匙。
   书例函数族（命题 3.16）：add/mul/pred/monus/sg/exp/fact 全部构造子组装；
   Ackermann 可定义但非 PR（对角论证文档线）；μ 有界搜索给部分递归语义。 *)

From Stdlib Require Import Bool Arith Lia List PeanoNat.
Import ListNotations.

(* ============ 一、PR 语法与求值器 ============ *)

Inductive prf : Type :=
| pz : prf                        (* 零函数 Z *)
| ps : prf                        (* 后继 N *)
| prj (n i : nat) : prf           (* 投影 U_i^n *)
| comp1 (g h : prf)               (* 一元复合 g(h(x))——(IV) 的代表 *)
| comp2 (g h1 h2 : prf)           (* 二元复合 g(h1(x),h2(x))——(IV) 的代表 *)
| prec (g h : prf).               (* 原始递归 (V) *)

(* 嵌套迭代：f(0)=基值，f(S m)=step m (f m)——闭包参数化绕开嵌套递归 guard *)
Fixpoint itup (step : nat -> nat -> nat) (k : nat) (r : nat) : nat :=
  match k with
  | O => r
  | S m => step m (itup step m r)
  end.

Fixpoint peval (f : prf) (args : list nat) {struct f} : nat :=
  match f with
  | pz => 0
  | ps => match args with [] => 0 | a :: _ => S a end
  | prj n i => nth i args 0
  | comp1 g h => peval g [peval h args]
  | comp2 g h1 h2 => peval g [peval h1 args; peval h2 args]
  | prec g h =>
      match args with
      | [] => 0
      | a :: xs => itup (fun m r => peval h (m :: r :: xs)) a (peval g xs)
      end
  end.

(* 原始递归的展开方程（通用版，转换检查即可） *)
Lemma prec_unfold : forall g h x xs,
  peval (prec g h) (S x :: xs) = peval h (x :: peval (prec g h) (x :: xs) :: xs).
Proof. reflexivity. Qed.

(* ============ 二、书例函数族（命题 3.16）============ *)

Definition pr_add : prf := prec (prj 1 0) (comp1 ps (prj 3 1)).
Definition pr_mul : prf := prec pz (comp2 pr_add (prj 3 1) (prj 3 2)).
Definition pr_pred : prf := prec pz (prj 2 0).
(* 注意约定：本章求值器对首变元递归，故 pr_monus [x;y] = y ∸ x *)
Definition pr_monus : prf := prec (prj 1 0) (comp1 pr_pred (prj 3 1)).
Definition pr_sg : prf := comp2 pr_monus pr_pred (prj 1 0).
Definition pr_exp : prf := prec (comp1 ps pz) (comp2 pr_mul (prj 3 1) (prj 3 2)).
Definition pr_fact : prf :=
  prec (comp1 ps pz) (comp2 pr_mul (prj 3 1) (comp1 ps (prj 3 0))).

(* 逐函数步进方程——整条链都是定义方程的转换检查 *)
Lemma pr_add_S : forall x y, peval pr_add [S x; y] = S (peval pr_add [x; y]).
Proof. reflexivity. Qed.

Lemma pr_mul_S : forall x y,
  peval pr_mul [S x; y] = peval pr_add [peval pr_mul [x; y]; y].
Proof. reflexivity. Qed.

Lemma pr_pred_S : forall x, peval pr_pred [S x] = x.
Proof. reflexivity. Qed.

Lemma pr_monus_S : forall x y,
  peval pr_monus [S x; y] = peval pr_pred [peval pr_monus [x; y]].
Proof. reflexivity. Qed.

Lemma pr_exp_S : forall x y,
  peval pr_exp [S x; y] = peval pr_mul [peval pr_exp [x; y]; y].
Proof. reflexivity. Qed.

Lemma pr_fact_S : forall x,
  peval pr_fact [S x] = peval pr_mul [peval pr_fact [x]; S x].
Proof. reflexivity. Qed.

Theorem pr_add_is_add : forall x y, peval pr_add [x; y] = x + y.
Proof.
  intro x. induction x as [|x IH]; intro y.
  - reflexivity.
  - rewrite pr_add_S, IH. reflexivity.
Qed.

Theorem pr_mul_is_mul : forall x y, peval pr_mul [x; y] = x * y.
Proof.
  intro x. induction x as [|x IH]; intro y.
  - reflexivity.
  - rewrite pr_mul_S, pr_add_is_add, IH.
    rewrite Nat.mul_succ_l. lia.
Qed.

Theorem pr_pred_is_pred : forall x, peval pr_pred [x] = Nat.pred x.
Proof.
  intro x. destruct x as [|x].
  - reflexivity.
  - rewrite pr_pred_S. reflexivity.
Qed.

Theorem pr_monus_is_sub : forall x y, peval pr_monus [x; y] = y - x.
Proof.
  intro x. induction x as [|x IH]; intro y.
  - simpl. lia.
  - rewrite pr_monus_S, pr_pred_is_pred, IH. lia.
Qed.

Theorem pr_exp_is_pow : forall x y, peval pr_exp [x; y] = y ^ x.
Proof.
  intro x. induction x as [|x IH]; intro y.
  - reflexivity.
  - rewrite pr_exp_S, pr_mul_is_mul, IH.
    rewrite Nat.pow_succ_r'. lia.
Qed.

Fixpoint fact (x : nat) : nat :=
  match x with O => 1 | S x' => S x' * fact x' end.

Theorem pr_fact_is_fact : forall x, peval pr_fact [x] = fact x.
Proof.
  intro x. induction x as [|x IH].
  - reflexivity.
  - rewrite pr_fact_S, pr_mul_is_mul, IH, Nat.mul_comm. reflexivity.
Qed.

(* ============ 三、对账表 ============ *)

Example table_add :
  map (fun p => peval pr_add [fst p; snd p]) (list_prod (seq 0 6) (seq 0 6))
  = map (fun p => fst p + snd p) (list_prod (seq 0 6) (seq 0 6)).
Proof. reflexivity. Qed.

Example table_pred_monus_sg :
  map (fun x => (peval pr_pred [x], peval pr_monus [3; x], peval pr_sg [x]))
      (seq 0 8)
  = [(0, 0, 0); (0, 0, 1); (1, 0, 1); (2, 0, 1); (3, 1, 1);
     (4, 2, 1); (5, 3, 1); (6, 4, 1)].
Proof. reflexivity. Qed.

Example table_exp_fact :
  map (fun x => (peval pr_exp [x; 2], peval pr_fact [x])) (seq 0 6)
  = [(1, 1); (2, 1); (4, 2); (8, 6); (16, 24); (32, 120)].
Proof. reflexivity. Qed.

(* ============ 四、Ackermann：可定义但非 PR ============ *)

(* 双层递归：外层对 m 结构归纳，内层局部 fix 对 k——EFT 五撞同款手法 *)
Fixpoint ack (m : nat) : nat -> nat :=
  match m with
  | O => fun n => S n
  | S m' => fun n =>
      (fix inner (k : nat) : nat :=
         match k with
         | O => ack m' 1
         | S k' => ack m' (inner k')
         end) n
  end.

Theorem ack_1n : forall n, ack 1 n = n + 2.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - change (ack 1 (S n)) with (S (ack 1 n)). rewrite IH. lia.
Qed.

Theorem ack_2n : forall n, ack 2 n = 2 * n + 3.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - change (ack 2 (S n)) with (ack 1 (ack 2 n)). rewrite IH, ack_1n. lia.
Qed.

(* 增长对账：ack 3 n = 2^(n+3) - 3（非 PR 的增长证据；对角论证见 docs） *)
Example table_ack3 : map (ack 3) (seq 0 6) = [5; 13; 29; 61; 125; 253].
Proof. reflexivity. Qed.

Example table_ack23 : (map (ack 2) (seq 0 6), map (ack 3) (seq 0 4))
  = ([3; 5; 7; 9; 11; 13], [5; 13; 29; 61]).
Proof. reflexivity. Qed.

(* ============ 五、限制 μ-算子：有界最小化 ============ *)

(* 从 0 起找最小零点（限制版书 §3.3 规则 VI：保证存在零点；
   无界时的部分性=燃料尽 None，即部分递归函数的未定义值） *)
Fixpoint muleast (g : nat -> nat) (b : nat) : option nat :=
  match b with
  | O => if Nat.eqb (g O) 0 then Some O else None
  | S b' => match muleast g b' with
            | Some y => Some y
            | None => if Nat.eqb (g (S b')) 0 then Some (S b') else None
            end
  end.

Example mu_abs2 :
  muleast (fun y => Nat.sub (2 * y) 4 + Nat.sub 4 (2 * y)) 10 = Some 2.
Proof. reflexivity. Qed.

Example mu_none : muleast (fun y => S y) 10 = None.
Proof. reflexivity. Qed.

(* μ 出 PR：sqrt 的最小化在现场可用（g 非负、有零点），但一般 μ-最小化
   的函数（如 Ackermann 之外的分片定义）超出 PR——对角论证 d(n)=φₙ(n)+1
   见 docs 文档线。 *)

(* ============ 账本 ============ *)

Print Assumptions pr_add_is_add.
Print Assumptions pr_mul_is_mul.
Print Assumptions pr_monus_is_sub.
Print Assumptions ack_2n.
Print Assumptions table_ack3.
