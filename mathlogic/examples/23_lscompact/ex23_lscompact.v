(* ex23_lscompact.v —— L-S、紧致性与初等等价（EFT ch VI）
   机器件：DLO 无端点的「不可有限公理化」数值证词（每个有限子集有
   有限模型、全组无有限模型——紧致性推论「有限可满足⟹无限模型」的
   脚印）；量化秩分层的初等等价检查器（eeq_rank 抽样）；Skolem 闭包
   生成演示（向下 L-S 的可数初等子结构思想）。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 语法与有限结构求值器（21 章骨架） ---------- *)

Inductive tm : Type :=
| var : nat -> tm
| fsym : nat -> list tm -> tm.

Inductive fm : Type :=
| rat : nat -> list tm -> fm
| eqf : tm -> tm -> fm
| neg : fm -> fm
| disj : fm -> fm -> fm
| conj : fm -> fm -> fm
| imp : fm -> fm -> fm
| exq : nat -> fm -> fm
| allq : nat -> fm -> fm.

Definition interp_fn := nat -> list nat -> nat.
Definition interp_rel := nat -> list nat -> bool.

Fixpoint evt (f : interp_fn) (β : nat -> nat) (t : tm) : nat :=
  match t with
  | var n => β n
  | fsym s ts => f s (map (evt f β) ts)
  end.

Definition bump (β : nat -> nat) (x a : nat) : nat -> nat :=
  fun n => if n =? x then a else β n.

Fixpoint evf (f : interp_fn) (r : interp_rel) (D : list nat)
    (β : nat -> nat) (φ : fm) : bool :=
  match φ with
  | rat s ts => r s (map (evt f β) ts)
  | eqf t1 t2 => Nat.eqb (evt f β t1) (evt f β t2)
  | neg ψ => negb (evf f r D β ψ)
  | disj ψ χ => orb (evf f r D β ψ) (evf f r D β χ)
  | conj ψ χ => andb (evf f r D β ψ) (evf f r D β χ)
  | imp ψ χ => implb (evf f r D β ψ) (evf f r D β χ)
  | exq x ψ => existsb (fun a => evf f r D (bump β x a) ψ) D
  | allq x ψ => forallb (fun a => evf f r D (bump β x a) ψ) D
  end.

(* ---------- 2. 线序结构族 Z_n：论域 [0..n)，R0 = <，R1 = ≡ ---------- *)

Definition Zn (n : nat) : list nat := seq 0 n.
Definition lt_r : interp_rel :=
  fun s args => match s, args with
  | 0, [a;b] => a <? b
  | 1, [a;b] => a =? b
  | _, _ => false end.
Definition fid : interp_fn := fun _ _ => 0.

(* 闭句在 Z_n 上真 *)
Definition trueZn (n : nat) (φ : fm) : bool :=
  evf fid lt_r (Zn n) (fun _ => 0) φ.

(* ---------- 3. DLO 公理化与「不可有限公理化」证词 ---------- *)

Definition x : tm := var 0.
Definition y : tm := var 1.
Definition z : tm := var 2.
Definition w : tm := var 3.

Definition lt (u v : tm) : fm := rat 0 [u; v].

(* 线序三公理 *)
Definition ord_irrefl : fm := allq 0 (neg (lt x x)).
Definition ord_trans : fm :=
  allq 0 (allq 1 (allq 2 (imp (conj (lt x y) (lt y z)) (lt x z)))).
Definition ord_total : fm :=
  allq 0 (allq 1 (disj (lt x y) (disj (eqf x y) (lt y x)))).
(* 稠密 *)
Definition dense : fm :=
  allq 0 (allq 1 (imp (lt x y) (exq 2 (conj (lt x z) (lt z y))))).
(* 无端点（两侧） *)
Definition no_left : fm := allq 0 (exq 1 (conj (lt y x) (neg (eqf y x)))).
Definition no_right : fm := allq 0 (exq 1 (conj (lt x y) (neg (eqf y x)))).

Definition dlo_axioms : list fm :=
  [ord_irrefl; ord_trans; ord_total; dense; no_left; no_right].

(* (a) 线序三公理在 Z_3 上真；稠密在任何有限 Z_n 上假（相邻对无中介） *)
Example linord_finite_models :
  forallb (fun φ => trueZn 3 φ) [ord_irrefl; ord_trans; ord_total] = true.
Proof. reflexivity. Qed.

Example dense_never_finite :
  forallb (fun n => negb (trueZn (S n) dense)) (seq 1 7) = true.
Proof. reflexivity. Qed.

(* (b) 全组（六条）在任何有限 Z_n 上假——DLO 只有无限模型 *)
Example dlo_no_finite_model :
  forallb (fun n => negb (forallb (fun φ => trueZn (S n) φ) dlo_axioms))
    (seq 0 7) = true.
Proof. reflexivity. Qed.

(* (c) 紧致性证词的正形态：「有限性不可单句定义」——σₙ := 至少 n 个
   不同元素。每个有限子集在足够大的 Z_m 上真；若某句 σfin 定义有限类，
   则 {σfin} ∪ {σₙ} 有限可满足而整体不可满足，与紧致性矛盾。 *)
Definition sigma2 : fm := exq 0 (exq 1 (neg (eqf (var 0) (var 1)))).
Definition sigma3 : fm :=
  (exq 0 (exq 1 (exq 2 (conj (neg (eqf (var 0) (var 1))) (conj (neg (eqf (var 0) (var 2))) (neg (eqf (var 1) (var 2)))))))).
Definition sigma4 : fm :=
  (exq 0 (exq 1 (exq 2 (exq 3 (conj (neg (eqf (var 0) (var 1))) (conj (neg (eqf (var 0) (var 2))) (conj (neg (eqf (var 0) (var 3))) (conj (neg (eqf (var 1) (var 2))) (conj (neg (eqf (var 1) (var 3))) (neg (eqf (var 2) (var 3)))))))))))).

Example sigmas_satisfiable :
  andb (trueZn 2 sigma2) (andb (trueZn 3 sigma3) (trueZn 4 sigma4)) = true.
Proof. reflexivity. Qed.

Example sigma4_fails_small : negb (trueZn 3 sigma4) = true.
Proof. reflexivity. Qed.

Example finite_subset_ok :
  andb (trueZn 3 sigma2) (trueZn 3 sigma3) = true.
Proof. reflexivity. Qed.

(* 紧致性读法：{σₙ : n} 的每个有限子集有（有限）模型、整体只有无限
   模型——「有限可满足 ⟹ 有模型」的推论落在这里；「有限类不可单句
   定义」的反证骨架在注释与 docs 讲清。DLO 一侧同理：DLO 的每条
   公理与 σₙ 的有限联立在足够大的稠密预备结构（如 Q 的截段）上
   可满足、整体需要无限稠密无端点模型。数值面把 Z_n 段的两端算死。 *)

(* ---------- 4. 量化秩分层的初等等价检查器 ---------- *)

(* rank 0：无量词公式（原子布尔组合）；rank (m+1)：闭于 ¬∨ 并允许
   一层量词套 rank m。检查器：抽样句子空间在结构对上同值 *)
Definition samples_rank0 : list fm :=
  [ lt x x; lt x y; conj (lt x y) (neg (lt x y));
    disj (lt x y) (eqf x y); imp (lt x y) (lt x z) ].

Definition samples_rank1 : list fm :=
  [ exq 2 (conj (lt x z) (lt z y)); allq 2 (imp (lt x z) (lt z y));
    exq 3 (lt w x); allq 1 (disj (lt x y) (eqf x y)) ].

(* eeq 检查：两结构上同值 *)
Definition eeq_pair (n m : nat) (φ : fm) : bool :=
  Bool.eqb (trueZn n φ) (trueZn m φ).

Example eeq_r0_Z2Z3 :
  forallb (eeq_pair 2 3) samples_rank0 = true.
Proof. reflexivity. Qed.
(* 量词层失配的现场：σ₃（∃∃∃ 三元互异）在 Z_3 真、Z_2 假——
   量化秩升一层即可分离低秩同值的结构对 *)
Example rank1_separates :
  negb (eeq_pair 2 3 sigma3) = true.
Proof. reflexivity. Qed.

(* ---------- 5. Skolem 闭包：向下 L-S 的可数初等子结构思想 ---------- *)

(* 从种子 {0} 出发，对一元函数 f（fid0 := 后继环绕）闭包生成——
   「闭于函数」的子论域。在有限截断上演示。 *)
Definition succ_wrap (n : nat) (a : nat) : nat := if a =? n - 1 then 0 else a + 1.

Definition subsumeq (l1 l2 : list nat) : bool :=
  forallb (fun a => existsb (Nat.eqb a) l2) l1.
Definition nodup_eq (l : list nat) : list nat :=
  fold_right (fun a acc => if existsb (Nat.eqb a) acc then acc else a :: acc)
    [] l.

Fixpoint skclose (n : nat) (seed : list nat) (fuel : nat) : list nat :=
  match fuel with
  | O => seed
  | S fuel' =>
      let S' := seed ++ map (succ_wrap n) seed in
      if subsumeq S' seed then seed
      else skclose n (nodup_eq S') fuel'
  end.

(* 从 {1} 在 Z_5 里闭包：环绕后继下整个论域进入闭包 *)
Example sk_full : forallb (fun a => existsb (Nat.eqb a) (skclose 5 [1] 10))
  (seq 0 5) = true.
Proof. reflexivity. Qed.

(* 从 {0} 在 Z_6 里闭包（0 的轨道 = 全域） *)
Example sk_full6 : length (skclose 6 [0] 10) = 6.
Proof. reflexivity. Qed.

(* 冒烟 *)
Compute (map (fun n => forallb (fun φ => trueZn (S n) φ) dlo_axioms) (seq 0 6)).
   (* 全 false：DLO 无有限模型 *)
Compute (map (fun φ => (trueZn 3 φ, trueZn 4 φ))
  [dense; no_left; ord_trans]).
