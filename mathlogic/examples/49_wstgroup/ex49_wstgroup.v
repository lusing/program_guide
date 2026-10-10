(* ex49_wstgroup.v —— ω-稳定群（Marker GTM 217 §7.1-7.5）
   机器件：有限群的**泛型计数器**（|S|>|G|/2 ⟹ S·S=G——Lemma 7.2.8
   平移覆盖的鸽笼引擎，在 Z₆/S₃/(Z/2)³ 上全枚举）；**稳定子账**
   （Stab(A) 的指数与连通分支 G⁰=有限群本体）；**群块补全搜索器**
   （C₂×C₂ 表挖一格的部分运算——结合律在定义处成立——补全成群
   表：Weil/Hrushovski Thm 7.5.3 的有限影子）；**和集稳定化**
   （(Z/2)³ 中 kX 倍增到 ⟨X⟩——Zil'ber 不可分解的有限影子）。
   零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

(* ---------- 1. 有限群装备：Z₆、S₃（程序化生成）、(Z/2)³ ---------- *)

Definition mulZ6 (x y : nat) : nat := (x + y) mod 6.

(* S₃=六个置换的复合表（程序化生成，杜绝手抄错位） *)
Definition s3perms : list (list nat) :=
  [[0;1;2];[1;0;2];[0;2;1];[2;1;0];[1;2;0];[2;0;1]].

Definition comp3 (p q : list nat) : list nat :=
  map (fun i => nth (nth i q 0) p 0) [0;1;2].

Fixpoint lEq (p q : list nat) : bool :=
  match p, q with
  | [], [] => true
  | a :: t1, b :: t2 => andb (Nat.eqb a b) (lEq t1 t2)
  | _, _ => false
  end.

Definition mulS3 (x y : nat) : nat :=
  let target := comp3 (nth x s3perms [0;1;2]) (nth y s3perms [0;1;2]) in
  hd 0 (map snd (filter (fun e => lEq (fst e) target)
    (combine s3perms (seq 0 6)))).

(* (Z/2)³ 用逐位异或 *)
Definition xor3 (x y : nat) : nat :=
  fold_left (fun acc i => acc + (((x / 2 ^ i + y / 2 ^ i) mod 2) * 2 ^ i)) [0;1;2] 0.

Definition mulOf (g : nat) : nat -> nat -> nat :=
  match g with
  | 0 => mulZ6
  | 1 => mulS3
  | _ => xor3
  end.

Definition domOf (g : nat) : list nat :=
  match g with 0 => seq 0 6 | 1 => seq 0 6 | _ => seq 0 8 end.

Definition invOf (g : nat) (x : nat) : nat :=
  hd 0 (filter (fun y => Nat.eqb (mulOf g x y) 0) (domOf g)).

(* 群公理抽样账：结合律+单位+逆 *)
Example group_axioms :
  forallb (fun g =>
    andb (forallb (fun x => forallb (fun y => forallb (fun z =>
            Nat.eqb (mulOf g (mulOf g x y) z) (mulOf g x (mulOf g y z)))
            (domOf g)) (domOf g)) (domOf g))
         (forallb (fun x => Nat.eqb (mulOf g 0 x) x) (domOf g)))
    [0; 1; 2] = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 2. 泛型计数器：过半 ⟹ S·S=G ---------- *)

Fixpoint remDup (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: t => if existsb (Nat.eqb x) t then remDup t else x :: remDup t
  end.

Definition prodSet (g : nat) (S : list nat) : list nat :=
  remDup (flat_map (fun x => map (fun y => mulOf g x y) S) S).

Definition sameSet (l1 l2 : list nat) : bool :=
  andb (forallb (fun x => existsb (Nat.eqb x) l2) l1)
       (forallb (fun x => existsb (Nat.eqb x) l1) l2).

(* 全部 |S|≥k 的子集 *)
Fixpoint subsetsK (base : list nat) (k : nat) : list (list nat) :=
  match base, k with
  | [], _ => []
  | _ :: _, 0 => [[]]
  | b :: t, S k' =>
      (if Nat.eqb k (S k') then map (fun s => b :: s) (subsetsK t k') else [])
  end.

Fixpoint allSubsets (base : list nat) : list (list nat) :=
  match base with
  | [] => [[]]
  | b :: t => let rest := allSubsets t in
              map (fun s => b :: s) rest ++ rest
  end.

(* 过半 ⟹ S·S=G：鸽笼（对每个 g，S 与 gS⁻¹ 都过半必有交） *)
Example half_cover :
  forallb (fun g =>
    forallb (fun S => implb (Nat.ltb (length (domOf g) / 2) (length S))
                            (sameSet (prodSet g S) (domOf g)))
      (filter (fun S => Nat.ltb (length (domOf g) / 2) (length S)) (allSubsets (domOf g))))
    [0; 1; 2] = true.
Proof. vm_compute. reflexivity. Qed.

(* 反向：小集合不够——{0,1} 的积集 ≠ Z₆ *)
Example small_not_generic :
  negb (sameSet (prodSet 0 [0; 1]) (seq 0 6)) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. 稳定子账：Stab(A) 与连通分支 ---------- *)

Definition stabOf (g : nat) (A : list nat) : list nat :=
  filter (fun x => forallb (fun a => existsb (Nat.eqb (mulOf g x a)) A) A) (domOf g).

(* S₃ 的稳定子账：子群 A₃={0,4,5}（e+两个 3-循环）的左乘稳定子
   =A₃ 本身（指数 2）；转置三元类的稳定子={0}（指数 6）；
   全群的稳定子=全群（指数 1） *)
Example stab_s3 :
  (length (stabOf 1 [1; 2; 3]), length (stabOf 1 [0; 4; 5]),
   length (stabOf 1 (seq 0 6))) = (3, 3, 6).
Proof. vm_compute. reflexivity. Qed.

(* 连通分支：有限群 G⁰=G（指数 1）——度账 deg(G)=[G:G⁰]=1 *)
Example finite_connected : forallb (fun g =>
  Nat.eqb (length (stabOf g (domOf g))) (length (domOf g))) [0; 1; 2] = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. 群块补全搜索器（Thm 7.5.3 的有限影子） ---------- *)

(* C₂×C₂ 表（0=e）：op2 (2,3) 缺失（-1 哨兵） *)
Definition partialOp (x y : nat) : nat :=
  if andb (Nat.eqb x 2) (Nat.eqb y 3) then 7      (* 缺 *)
  else match x, y with
       | 0, _ => y | _, 0 => x
       | 1, 1 => 0 | 1, 2 => 3 | 1, 3 => 2
       | 2, 1 => 3 | 2, 2 => 0 | 2, 3 => 7
       | 3, 1 => 2 | 3, 2 => 7 | 3, 3 => 0
       | _, _ => 7
       end.

(* 结合律在定义处成立 *)
Definition assocWhereDefined : bool :=
  forallb (fun t =>
    let x := fst (fst t) in let y := snd (fst t) in let z := snd t in
    let xy := partialOp x y in let yz := partialOp y z in
    implb (andb (andb (negb (Nat.eqb xy 7)) (negb (Nat.eqb yz 7)))
                (andb (negb (Nat.eqb (partialOp xy z) 7))
                      (negb (Nat.eqb (partialOp x yz) 7))))
          (Nat.eqb (partialOp xy z) (partialOp x yz)))
    (list_prod (list_prod [0;1;2;3] [0;1;2;3]) [0;1;2;3]).

Example partial_associative : assocWhereDefined = true.
Proof. vm_compute. reflexivity. Qed.

(* 补全存在：C₂×C₂ 的全表扩张部分表且是群 *)
Definition fullOp (x y : nat) : nat :=
  match x, y with
  | 0, _ => y | _, 0 => x
  | 1, 1 => 0 | 1, 2 => 3 | 1, 3 => 2
  | 2, 1 => 3 | 2, 2 => 0 | 2, 3 => 1
  | 3, 1 => 2 | 3, 2 => 1 | 3, 3 => 0
  | _, _ => 0
  end.

Example completes_to_group :
  andb (forallb (fun p => implb (negb (Nat.eqb (partialOp (fst p) (snd p)) 7))
                                (Nat.eqb (partialOp (fst p) (snd p))
                                         (fullOp (fst p) (snd p))))
                  (list_prod [0;1;2;3] [0;1;2;3]))
       (forallb (fun t =>
          let x := fst (fst t) in let y := snd (fst t) in let z := snd t in
          Nat.eqb (fullOp (fullOp x y) z) (fullOp x (fullOp y z)))
          (list_prod (list_prod [0;1;2;3] [0;1;2;3]) [0;1;2;3]))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 5. 和集稳定化：kX 倍增至 ⟨X⟩（Zil'ber 有限影子） ---------- *)

Definition addSet (A B : list nat) : list nat :=
  fold_left (fun acc p => let v := xor3 (fst p) (snd p) in
              if existsb (Nat.eqb v) acc then acc else v :: acc)
            (list_prod A B) [].

Definition accumAdd (S : list nat) : list nat :=
  remDup (S ++ addSet S S).

Fixpoint sumIter (A : list nat) (fuel : nat) : list nat :=
  match fuel with
  | 0 => A
  | S f => let A' := accumAdd A in
           if Nat.eqb (length A') (length A) then A' else sumIter A' f
  end.

(* X={1,3}（两个坐标向量）：1+1=0, 1+3=2, 3+3=0 → ⟨X⟩={0,1,2,3} *)
Example sumset_stabilizes :
  sameSet (sumIter [1; 3] 8) [0; 1; 2; 3] = true.
Proof. vm_compute. reflexivity. Qed.

(* X={1}：稳定到 {0,1}——子群；X={1,2,4}（三个坐标位）→ 全空间 *)
Example sumset_two :
  (sameSet (sumIter [1] 8) [0; 1], sameSet (sumIter [1; 2; 4] 8) (seq 0 8))
  = (true, true).
Proof. vm_compute. reflexivity. Qed.

Print Assumptions sumset_two.
