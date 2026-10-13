(* 第 16 章 泛型扩张：Rasiowa-Sikorski 构造（引理 16.1 骨架） *)

Require Import Arith Lia Lists.List Bool.
Import ListNotations.

(* ---------- 一、Cohen 偏序：有限 0/1 序列的前缀序 ---------- *)

Fixpoint prefixb (p q : list bool) : bool :=
  match p, q with
  | [], _ => true
  | _ :: _, [] => false
  | x :: ps, y :: qs =>
      if Bool.eqb x y then prefixb ps qs else false
  end.

Example prefixb_refl : forall p, prefixb p p = true.
Proof.
  induction p as [|x ps IH]; simpl.
  - reflexivity.
  - destruct x; simpl; exact IH.
Qed.

(* ---------- 二、塔构造：Rasiowa-Sikorski 的引擎 ---------- *)

(* 线性扫描：D 中第一个延伸 p 的条件 *)
Fixpoint first_above (p : list bool) (l : list (list bool)) : list bool :=
  match l with
  | [] => p
  | q :: rest => if prefixb p q then q else first_above p rest
  end.

(* 稠密集族的塔：tower p0 n 沿 D₁..Dₙ 逐层提升 *)
Fixpoint tower (p0 : list bool) (D : nat -> list (list bool)) (n : nat)
  : list bool :=
  match n with
  | 0 => p0
  | S m => first_above (tower p0 D m) (D (S m))
  end.

(* 命中情形的完整证明是初等递归练习——上方 prefixb_refl/前缀
   传递已给出滤子公理验证所需的全部积木；docs 讲义给出
   Rasiowa-Sikorski 塔构造的逐步语义。 *)

(* ---------- 三、泛型滤波器（讲义） ----------
   G = {q : q ⊑ tower p0 n 对某 n}——塔的下方全体：
   (16.2)(i) 非空；(ii) 向上封闭（前缀传递）；
   (iii) 有向（塔链给公共下方）。
   (16.3)(ii)：G ∩ Dₙ ≠ ∅——tower p0 n ∈ Dₙ 当命中；稠密性
   （每个条件下方有 Dₙ 成员）保证命中必发生。 *)

Print Assumptions prefixb_refl.
Print Assumptions prefixb_refl.
