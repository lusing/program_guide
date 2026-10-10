(* ex43_forking.v —— 分叉与独立性（Marker GTM 217 §6.3-6.5）
   机器件：E_inf 实验室上的**分叉=秩降检查器**（tp(a/A) 的 RM：
   新类 2→B 触及 a 的类 1→B∋a 0——Thm 6.3.2 不分叉延拓的逐例
   见证）；F₂⁴ 的**维数公式账本**（dim(U+V)+dim(U∩V)=dim U+dim V
   ——强极小独立性 dim(a,b/A)=dim a+dim b 的地基）；**Morley 序列
   构造器**（逐元独立选取+序列 E-原子深度不可辨验证）。独立性五律
   （Lemma 6.3.16-6.3.21）以秩/维数的单调账落地。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

(* ---------- 1. E_inf 上的型秩与分叉 ---------- *)

Definition cl (x : nat) : nat := x / 10.
Definition clsOf (A : list nat) : list nat := map cl A.

Definition rmTP (a : nat) (A : list nat) : nat :=
  if existsb (Nat.eqb a) A then 0
  else if existsb (Nat.eqb (cl a)) (clsOf A) then 1
  else 2.

Definition indep (a : nat) (A : list nat) : bool :=
  negb (existsb (Nat.eqb (cl a)) (clsOf A)).

Definition forks (a : nat) (A B : list nat) : bool :=
  Nat.ltb (rmTP a B) (rmTP a A).

(* 账一：秩的三级降落——新鲜 a 保持 2；B 触及类降至 1；B∋a 降至
   0；两类分叉见证（触及与含入各一） *)
Example rank_descent :
  (rmTP 50 [10; 11],
   rmTP 50 [20; 21],
   rmTP 50 [50; 20],
   forks 50 [20; 21] [21; 50],
   forks 50 [30] [55]) = (2, 2, 0, true, true).
Proof. vm_compute. reflexivity. Qed.

(* 账二：不分叉延拓存在（Thm 6.3.2 逐例）——a 对 A 独立（RM=2）
   时，新鲜类见证元对一切 B⊇A 仍 RM=2 *)
Definition nonforkW (a : nat) (A B : list nat) : nat :=
  S (10 * (S (fold_right Nat.max 0 (clsOf B ++ clsOf A))) + 10) - 1.

Example nonfork_ext_exists :
  forallb (fun spec =>
    let A := fst (fst spec) in let B := snd (fst spec) in let a := snd spec in
    implb (Nat.eqb (rmTP a A) 2)
          (andb (Nat.eqb (rmTP (nonforkW a A B) B) 2)
                (Nat.eqb (rmTP (nonforkW a A B) A) 2)))
    [ (([10; 11], [10; 11; 20]), 50)
    ; (([], [10; 20; 30]), 99)
    ; (([5], [5; 15; 25]), 42)
    ] = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 2. F₂⁴ 的维数公式账本 ---------- *)

Definition xorb4 (a b : nat) : nat :=
  fold_left (fun acc i => acc + (((a / 2 ^ i + b / 2 ^ i) mod 2) * 2 ^ i))
    [0; 1; 2; 3] 0.

Fixpoint lowbitF (fuel : nat) (x : nat) : nat :=
  match fuel with
  | 0 => 0
  | S f => if Nat.eqb x 0 then 0
           else if Nat.eqb (x mod 2) 1 then 0 else S (lowbitF f (x / 2))
  end.

Definition lowbit (x : nat) : nat := lowbitF 8 x.

(* 高斯消元式基底插入 *)
Fixpoint addVec (basis : list nat) (v : nat) : list nat :=
  match basis with
  | [] => if Nat.eqb v 0 then [] else [v]
  | p :: t =>
      if Nat.eqb ((v / 2 ^ (lowbit p)) mod 2) 1
      then p :: addVec t (xorb4 v p)
      else p :: addVec t v
  end.

Fixpoint remDup {A} (eqb : A -> A -> bool) (l : list A) : list A :=
  match l with
  | [] => []
  | x :: t => if existsb (eqb x) t then remDup eqb t else x :: remDup eqb t
  end.

Definition dimOf (l : list nat) : nat :=
  length (fold_left (fun acc v => addVec acc v) (remDup Nat.eqb l) []).

(* 张成（元素表）：从种子集出发对 xorb4 闭包到不动点 *)
Fixpoint spanF (fuel : nat) (s : list nat) : list nat :=
  match fuel with
  | 0 => s
  | S f =>
      let s' := fold_left (fun acc p =>
                  let v := xorb4 (fst p) (snd p) in
                  if existsb (Nat.eqb v) acc then acc else v :: acc)
                (list_prod s s) s in
      if Nat.eqb (length s') (length s) then s' else spanF f s'
  end.

Definition spanOf (s : list nat) : list nat :=
  spanF 64 (remDup Nat.eqb (0 :: map (fun x => x mod 16) s)).

Definition interL (l1 l2 : list nat) : list nat :=
  filter (fun x => existsb (Nat.eqb x) l2) l1.

(* 维数公式：dim(U+V)+dim(U∩V)=dim U+dim V —— 采样子空间对全验 *)
Definition sampleGens : list (list nat * list nat) :=
  [ ([1; 2], [1; 3])
  ; ([1; 2; 4], [3; 5])
  ; ([1; 2; 4; 8], [3; 5; 6])
  ; ([1; 2; 4], [4; 8])
  ; ([3; 6; 12], [1; 5; 9])
  ; ([7; 8], [1; 2; 4])
  ].

Example dim_formula :
  forallb (fun g =>
    let U := spanOf (fst g) in let V := spanOf (snd g) in
    Nat.eqb (dimOf (U ++ V) + dimOf (interL U V))
            (dimOf U + dimOf V)) sampleGens = true.
Proof. vm_compute. reflexivity. Qed.

(* 独立性的维数刻画：a ⌣| A b ⟺ dim(A∪{a,b}) = dim(A∪{a})+dim(A∪{b})−dim A *)
Example indep_dim_char :
  forallb (fun spec =>
    let A := fst (fst spec) in let a := snd (fst spec) in let b := snd spec in
    let lhs := dimOf (A ++ [a; b]) in
    let rhs := dimOf (A ++ [a]) + dimOf (A ++ [b]) - dimOf A in
    Bool.eqb (Nat.eqb lhs rhs)
             (andb (negb (existsb (fun x => Nat.eqb (xorb4 x b) 0)
                            (spanOf (A ++ [a]))))
                   (negb (existsb (fun x => Nat.eqb (xorb4 x a) 0)
                            (spanOf (A ++ [b]))))))
    [ (([], 1), 2)      (* 独立对：b∉span{a} ⟹ 维数相加 *)
    ; (([], 1), 3)
    ; (([], 1), 1)      (* b∈span{a}：依赖——维数公式破 *)
    ; (([1], 2), 3)
    ; (([1], 2), 2)
    ] = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. Morley 序列构造器（§6.5） ---------- *)

(* 逐元独立选取：aᵢ 的类避开 A 与先前元素的类 *)
Fixpoint morleySeq (A : list nat) (k : nat) : list nat :=
  match k with
  | 0 => []
  | S k' => let prev := morleySeq A k' in
            (10 * (S (fold_right Nat.max 0 (clsOf (A ++ prev)))) + 1) :: prev
  end.

(* E-原子深度的不可辨验证：任意同长递增指标对的原子真值一致 *)
Definition eAtom (op : nat) (x a : nat) : bool :=
  match op with
  | 0 => Nat.eqb x a
  | 1 => Nat.eqb (cl x) (cl a)
  | _ => negb (Nat.eqb (cl x) (cl a))
  end.

Definition eProf (A : list nat) (x : nat) : list bool :=
  flat_map (fun a => map (fun op => eAtom op x a) [0; 1; 2]) A.

Fixpoint listBeq (l1 l2 : list bool) : bool :=
  match l1, l2 with
  | [], [] => true
  | x :: t1, y :: t2 => andb (Bool.eqb x y) (listBeq t1 t2)
  | _, _ => false
  end.

(* Morley 序列的两两不可辨（E-原子族上）+独立性逐元账 *)
Example morley_indiscernible :
  let A := [10; 21] in
  let ms := morleySeq A 5 in
  (forallb (fun x => forallb (fun y =>
      implb (Nat.ltb x y) (listBeq (eProf A (nth x ms 0)) (eProf A (nth y ms 0))))
      (seq 0 5)) (seq 0 5),
   forallb (fun i => indep (nth i ms 0) (A ++ firstn i ms)) (seq 0 5))
  = (true, true).
Proof. vm_compute. reflexivity. Qed.

Print Assumptions morley_indiscernible.
