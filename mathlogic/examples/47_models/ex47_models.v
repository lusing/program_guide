(* ex47_models.v —— 算术的模型（Marker ch16）
   机器件：{c>n̄} 的有限可满足检查（非标准模型存在的紧致性现场）；
   M_K=[0..K]∪{∞} 上的 overspill 有限影子；R(3,3)=6 的双方账本
   （K5 有三角无关染色、K6 全有）；[m]^2 的 min-homogeneous 检查
   与 PH(2,2) 分离账。MacDowell–Specker 与 Ketonen–Solovay 记
   文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 非标准模型存在的紧致性现场 ---------- *)

(* 句子族 {c > n̄}：每个有限子集在 ℕ 有见证（c:=K+1），
   整体在 ℕ 无模型——紧致性给出含无限元素 c 的初等扩张 *)
Example fsat_finite_witness :
  forallb (fun K => Nat.ltb K (S K)) (seq 0 20) = true.
Proof. reflexivity. Qed.

(* ---------- 2. overspill 有限影子 ---------- *)

Definition Inf : nat := 999.   (* ∞ 的编码；饱和语义 S(∞)=∞ *)

(* 无参数公式编码：0=「x=x」 1=「x≠x」 2/3/4=「x=k̄」 8/9/10=「x≠k̄」
   （x=k̄ 在 ∞ 处假——标准数才等于标准数；其余在 ∞ 处真） *)
Definition evalF (f x : nat) : bool :=
  match f with
  | 0 => true
  | 1 => false
  | 2 => match x with 999 => false | _ => Nat.eqb x 0 end
  | 3 => match x with 999 => false | _ => Nat.eqb x 1 end
  | 4 => match x with 999 => false | _ => Nat.eqb x 2 end
  | 8 => negb (match x with 999 => false | _ => Nat.eqb x 0 end)
  | 9 => negb (match x with 999 => false | _ => Nat.eqb x 1 end)
  | 10 => negb (match x with 999 => false | _ => Nat.eqb x 2 end)
  | _ => true
  end.

(* 凡含全部标准点 [0..15] 的可定义集都含 ∞ *)
Example overspill_shadow :
  forallb (fun f =>
    implb (forallb (fun x => evalF f x) (seq 0 16))
          (evalF f Inf)) [0; 8; 9; 10] = true.
Proof. reflexivity. Qed.
(* 真实 overspill：可定义集含全部标准数 ⟹ 含非标准数；有限
   影子展示机制（「x=k̄」根本不含全段，有效公式在饱和语义下
   自动含 ∞），完整定理记文档线。 *)

(* ---------- 3. R(3,3)=6 双方账本 ---------- *)

Fixpoint bits (m : nat) : list (list bool) :=
  match m with
  | 0 => [[]]
  | S m' => map (cons false) (bits m') ++ map (cons true) (bits m')
  end.

Definition edge (m : nat) : list (nat * nat) :=
  flat_map (fun i => map (fun j => (j, i))
              (filter (fun j => j <? i) (seq 0 m))) (seq 0 m).

Fixpoint pos2 (p : nat * nat) (l : list (nat * nat)) : nat :=
  match l with
  | [] => 0
  | h :: r =>
      if andb (Nat.eqb (fst p) (fst h)) (Nat.eqb (snd p) (snd h))
      then 0 else S (pos2 p r)
  end.

Definition colorE (m : nat) (b : list bool) (i j : nat) : bool :=
  nth (pos2 (Nat.min i j, Nat.max i j) (edge m)) b false.

Definition hasTri (m : nat) (b : list bool) : bool :=
  existsb (fun tri : nat * (nat * nat) =>
    andb (Bool.eqb (colorE m b (fst tri) (fst (snd tri)))
                  (colorE m b (fst tri) (snd (snd tri))))
         (Bool.eqb (colorE m b (fst tri) (fst (snd tri)))
                  (colorE m b (fst (snd tri)) (snd (snd tri)))))
    (flat_map (fun i =>
       flat_map (fun j => map (fun k => (i, (j, k)))
                     (filter (fun k => k <? j) (seq 0 m)))
         (filter (fun j => j <? i) (seq 0 m))) (seq 0 m)).

(* K5（10 边、1024 色）：存在三角无关染色 *)
Example k5_avoids :
  existsb (fun b => negb (hasTri 5 b)) (bits 10) = true.
Proof. reflexivity. Qed.

(* K6（15 边、32768 色）：一切染色都有单色三角 *)
Example k6_always :
  forallb (fun b => hasTri 6 b) (bits 15) = true.
Proof. reflexivity. Qed.

(* ---------- 4. [m]^2 的 min-homogeneous：PH(2,2) ---------- *)

Fixpoint subsetsL (l : list nat) : list (list nat) :=
  match l with
  | [] => [[]]
  | a :: t => subsetsL t ++ map (cons a) (subsetsL t)
  end.

Fixpoint pairsOf (l : list nat) : list (nat * nat) :=
  match l with
  | [] | [_] => []
  | a :: t => map (fun x => (a, x)) t ++ pairsOf t
  end.

(* X 齐色：所有对的边同色 *)
Definition homPairs (m : nat) (b : list bool) (X : list nat) : bool :=
  forallb (fun p => Bool.eqb (colorE m b (fst p) (snd p))
                             (colorE m b (hd 0 X) (nth 1 X 0)))
    (pairsOf X).

(* X min-homogeneous：齐色且 |X| > min X *)
Definition minhom2 (m : nat) (b : list bool) (X : list nat) : bool :=
  andb (homPairs m b X)
       (Nat.ltb (hd 0 X) (length X)).

Definition phHolds (m : nat) : bool :=
  forallb (fun b => existsb (minhom2 m b)
                     (filter (fun X => match X with
                                 | [] | [_] => false
                                 | _ => true end)
                             (subsetsL (seq 0 m))))
    (bits (length (edge m))).

(* 账本（先探后写）：m=3,4,5 全部 [true;true;true]——[m]^2 的
   PH(2,2) 在极小 m 就成立（含 0 的齐色对即满足 |X|>min X）；
   k=3 的情形增长才开始爆炸（Prolog 面与文档线）。 *)
Compute (map phHolds [3;4;5]).

(* 冒烟 *)
Compute (length (edge 5), length (edge 6), length (bits 15)).
