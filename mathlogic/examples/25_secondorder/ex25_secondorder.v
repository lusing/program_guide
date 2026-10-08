(* ex25_secondorder.v —— 二阶逻辑与弱二阶系统（EFT ch IX）
   机器件：有限结构二阶求值器 soev（关系变量跑有限幂表的枚举域）+
   偶数性的二阶定义（环后继上的交替着色）+ 图连通性的二阶定义
   （含边全等价关系）+ L_Q 在有限结构上的退化。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 二阶语法 ---------- *)

Inductive tm : Type :=
| var : nat -> tm
| fsym : nat -> list tm -> tm.

Inductive fm : Type :=
| rat : nat -> list tm -> fm          (* 一阶关系原子（含 E=0, S=1） *)
| relv : nat -> list tm -> fm         (* 二阶关系变量 X_k 施于项 *)
| eqf : tm -> tm -> fm
| neg : fm -> fm
| disj : fm -> fm -> fm
| conj : fm -> fm -> fm
| imp : fm -> fm -> fm
| exq : nat -> fm -> fm               (* 一阶 ∃ *)
| allq : nat -> fm -> fm              (* 一阶 ∀ *)
| soexq : nat -> nat -> fm -> fm.     (* ∃X^k：变量号+元数 *)

(* ---------- 2. 有限结构二阶求值器 ---------- *)

Definition interp_fn := nat -> list nat -> nat.
Definition interp_rel := nat -> list nat -> bool.

(* 关系环境：变量号 ↦ 关系（论域 k 元组表——有限幂枚举域的代表） *)
Definition relenv := nat -> list (list nat).

Fixpoint evt (f : interp_fn) (β : nat -> nat) (t : tm) : nat :=
  match t with
  | var n => β n
  | fsym s ts => f s (map (evt f β) ts)
  end.

Definition bump (β : nat -> nat) (x a : nat) : nat -> nat :=
  fun n => if n =? x then a else β n.

Definition bumpR (ρ : relenv) (k : nat) (R : list (list nat)) : relenv :=
  fun n => if n =? k then R else ρ n.

(* k 元组全枚举（幂表：关系的有限域） *)
Fixpoint tuples_k (D : list nat) (k : nat) : list (list nat) :=
  match k with
  | O => [[]]
  | S k' => flat_map (fun a => map (fun l => a :: l) (tuples_k D k')) D
  end.

(* 关系的幂枚举：全部子表（真幂集——有限结构上二阶量词的论域） *)
Fixpoint subsets {A} (l : list A) : list (list A) :=
  match l with
  | [] => [[]]
  | a :: l' => let S := subsets l' in
               map (fun s => a :: s) S ++ S
  end.

Definition pow_tuples (D : list nat) (k : nat) : list (list (list nat)) :=
  subsets (tuples_k D k).

(* 元组相等（布尔） *)
Fixpoint lseqb (l1 l2 : list nat) : bool :=
  match l1, l2 with
  | [], [] => true
  | a :: l1', b :: l2' => andb (a =? b) (lseqb l1' l2')
  | _, _ => false
  end.

Fixpoint soev (f : interp_fn) (r : interp_rel) (D : list nat)
    (β : nat -> nat) (ρ : relenv) (φ : fm) : bool :=
  match φ with
  | rat s ts => r s (map (evt f β) ts)
  | relv k ts =>
      existsb (fun tup => lseqb (map (evt f β) ts) tup) (ρ k)
  | eqf t1 t2 => Nat.eqb (evt f β t1) (evt f β t2)
  | neg ψ => negb (soev f r D β ρ ψ)
  | disj ψ χ => orb (soev f r D β ρ ψ) (soev f r D β ρ χ)
  | conj ψ χ => andb (soev f r D β ρ ψ) (soev f r D β ρ χ)
  | imp ψ χ => implb (soev f r D β ρ ψ) (soev f r D β ρ χ)
  | exq x ψ => existsb (fun a => soev f r D (bump β x a) ρ ψ) D
  | allq x ψ => forallb (fun a => soev f r D (bump β x a) ρ ψ) D
  | soexq xv k ψ =>
      existsb (fun R => soev f r D β (bumpR ρ xv R) ψ) (pow_tuples D k)
  end.


(* ---------- 3. 现场一：偶数性的二阶定义（环后继交替着色） ---------- *)

(* 结构 (Z_n, S)：S = 环后继（R1）；E=0 留给图。 *)
Definition succ_wrap (n a : nat) : nat := if a =? n - 1 then 0 else a + 1.

Definition succ_rel (n : nat) : interp_rel :=
  fun s args => match s, args with
  | 1, [a; b] => Nat.eqb (succ_wrap n a) b
  | _, _ => false end.

Definition fid : interp_fn := fun _ _ => 0.
Definition Dn (n : nat) : list nat := seq 0 n.

Definition sats (n : nat) (φ : fm) : bool :=
  soev fid (succ_rel n) (Dn n) (fun _ => 0) (fun _ => []) φ.

Fixpoint iff_b (φ ψ : fm) : fm := conj (imp φ ψ) (imp ψ φ).

(* EVEN_n := ∃X[ X(0) ∧ ∀x(X(x) ↔ ¬X(Sx)) ]——交替着色绕环相容
   ⟺ 环长为偶 *)
Definition Xv (t : tm) : fm := relv 0 [t].
Definition Sat (u v : tm) : fm := rat 1 [u; v].
Definition evenSO : fm :=
  soexq 0 1 (conj (Xv (var 0))
    (allq 1 (allq 2 (imp (Sat (var 1) (var 2))
                         (iff_b (Xv (var 1)) (neg (Xv (var 2)))))))).

Example even4 : sats 4 evenSO = true.
Proof. reflexivity. Qed.
Example odd5 : negb (sats 5 evenSO) = true.
Proof. reflexivity. Qed.
Example even6 : sats 6 evenSO = true.
Proof. reflexivity. Qed.
Example odd3 : negb (sats 3 evenSO) = true.
Proof. reflexivity. Qed.

(* ---------- 4. 现场二：图连通性的二阶定义 ---------- *)

(* 图：E = 0 号关系。连通 := ¬∃R[含 E 的等价关系且漏掉某对]——
   否定式排除全关系的平凡满足（一阶不可定义的经典二阶刻画） *)
Definition Rv (u v : tm) : fm := relv 1 [u; v].
Definition Ev (u v : tm) : fm := rat 0 [u; v].
Definition conn_inner : fm :=
    conj (allq 0 (Rv (var 0) (var 0)))
    (conj (allq 0 (allq 1 (imp (Rv (var 0) (var 1)) (Rv (var 1) (var 0)))))
    (conj (allq 0 (allq 1 (allq 2 (imp (conj (Rv (var 0) (var 1)) (Rv (var 1) (var 2)))
                                         (Rv (var 0) (var 2))))))
    (conj (allq 0 (allq 1 (imp (Ev (var 0) (var 1)) (Rv (var 0) (var 1)))))
          (neg (allq 0 (allq 1 (Rv (var 0) (var 1)))))))).
Definition connSO : fm := neg (soexq 1 2 conn_inner).

(* 连通 4 点链 0-1-2-3；非连通：链 0-1 + 岛 2,3 *)
Definition chain4 : interp_rel :=
  fun s args => match s, args with
  | 0, [a;b] => orb (orb (andb (a =? 0) (b =? 1)) (andb (a =? 1) (b =? 2)))
                     (andb (a =? 2) (b =? 3))
  | _, _ => false end.

Definition split4 : interp_rel :=
  fun s args => match s, args with
  | 0, [a;b] => andb (a =? 0) (b =? 1)
  | _, _ => false end.

Definition satg (r : interp_rel) (φ : fm) : bool :=
  soev fid r (Dn 4) (fun _ => 0) (fun _ => []) φ.

Example conn_chain : satg chain4 connSO = true.
Proof. reflexivity. Qed.
Example conn_split : negb (satg split4 connSO) = true.
Proof. reflexivity. Qed.

(* ---------- 5. L_Q 的退化与一阶天花板（文档级接口） ---------- *)

(* L_Q：Qx φ := 「满足 φ 的元素不可数多」。有限结构上恒假——数值面 *)
Definition Q_finite (n : nat) : bool := false.
Example LQ_degenerate : forallb (fun m => Q_finite m) (seq 0 8) = false.
Proof. reflexivity. Qed.

(* EVEN 一阶不可定义（EF 博弈：偶环与奇环高轮不分——24 章规则的
   推论）；二阶 PA 范畴性、L_ω1ω 可数合取、二阶有效性不可枚举
   （Church–Kleene via Trakhtenbrot 书 X.5）——均文档级。 *)

(* 冒烟 *)
Compute (map (fun n => sats n evenSO) (seq 1 8)).
   (* [f;t;f;t;f;t;f;t]——交替着色恰在偶环相容 *)
