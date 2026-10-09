(* ex51_complexity.v —— 复杂度：P 与 NP（Müller-Stach ch5）
   机器件：CNF 证书验证器 vs 蛮力求解的步数双账（NP=多项式可验证的
   live 现场）；SAT→3SAT 归约组合子（长子句链式填充新变元）+可满足
   性双向对账表；3SAT→CLIQUE 归约（文字图找团=找赋值）+团-赋值
   witnessing 对账；归约复合传递（SAT→3SAT→CLIQUE 全链一致）。
   Cook–Levin、P=NP 千禧问题与 Grzegorczyk 层谱记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. CNF 语义与证书验证 ---------- *)

(* 文字 (v,true)=正、(v,false)=负；赋值=按变元号取位 *)
Definition lit : Type := (nat * bool)%type.
Definition clause : Type := list lit.
Definition cnf : Type := list clause.

Definition asgGet (a : list bool) (v : nat) : bool := nth v a false.

Definition litSat (a : list bool) (l : lit) : bool :=
  match l with (v, true) => asgGet a v | (v, false) => negb (asgGet a v) end.

Definition clauseSat (a : list bool) (c : clause) : bool :=
  existsb (litSat a) c.

Definition cnfSat (a : list bool) (F : cnf) : bool :=
  forallb (clauseSat a) F.

(* 步数账：验证一个证书 = 逐文字一步（线性于公式规模） *)
Fixpoint litCount (F : cnf) : nat :=
  match F with
  | [] => 0
  | c :: cs => length c + litCount cs
  end.

Fixpoint pow2 (n : nat) : nat :=
  match n with 0 => 1 | S n' => 2 * pow2 n' end.

(* 蛮力求解 = 枚举全部 2^n 赋值、每个都做一次线性验证 *)
Fixpoint allAsg (n : nat) : list (list bool) :=
  match n with
  | 0 => [[]]
  | S n' => map (cons false) (allAsg n') ++ map (cons true) (allAsg n')
  end.

Definition satBrute (n : nat) (F : cnf) : bool :=
  existsb (fun a => cnfSat a F) (allAsg n).

Definition bruteSteps (n : nat) (F : cnf) : nat :=
  pow2 n * litCount F.

(* 样本公式族（n 变元链式蕴含，唯一满足）与双账：
   验证步数线性长个位数 vs 蛮力 2^n 倍——每加一元翻一倍 *)
Definition fam (n : nat) : cnf :=
  [(0, true)] ::
  map (fun k => [(S k, false); (S (S k), true)]) (seq 0 (n - 1)).

Example verify_vs_brute_ledger :
  map (fun n => (litCount (fam n), bruteSteps n (fam n))) (seq 3 6)
  = [(5, 40); (7, 112); (9, 288); (11, 704); (13, 1664); (15, 3840)].
Proof. reflexivity. Qed.

(* 蛮力求解器找到的赋值确实过验证器（求解↔验证的一致性） *)
Example brute_finds_witness :
  forallb (fun n => existsb (fun a => cnfSat a (fam n)) (allAsg n)) (seq 3 6)
  = true.
Proof. reflexivity. Qed.

(* ---------- 2. SAT → 3SAT 归约组合子 ---------- *)

(* 短子句填充到恰 3（重复文字不改子句语义） *)
Definition pad3 (c : clause) : clause :=
  match c with
  | [] => [(0, true); (0, true); (0, true)]
  | [l] => [l; l; l]
  | [l1; l2] => [l1; l2; l2]
  | c' => c'
  end.

(* 长子句链式拆分（新变元从 base 起编号）：
   (l1..lk) ↦ (l1∨l2∨z)(¬z∨l3∨z')(¬z'∨l4∨z'')…(¬z''∨l_{k-1}∨lk) *)
Fixpoint chain (base : nat) (l1 l2 : lit) (r : clause) : cnf :=
  match r with
  | [] => [[l1; l2]]
  | [l3] => [[l1; l2; l3]]
  | l3 :: r' => [l1; l2; (base, true)]
                :: chain (S base) (base, false) l3 r'
  end.

Definition clause3 (base : nat) (c : clause) : cnf :=
  match c with
  | [] | [_] | [_; _] => [pad3 c]
  | l1 :: l2 :: l3 :: r => chain base l1 l2 (l3 :: r)
  end.

(* F 用到的变元上界：新变元从这之后编号，绝不与旧变元相撞 *)
Fixpoint maxVar (F : cnf) : nat :=
  match F with
  | [] => 0
  | c :: cs => fold_left (fun m l => Nat.max m (S (fst l))) c (maxVar cs)
  end.

Fixpoint sat3OfBase (base : nat) (F : cnf) : cnf :=
  match F with
  | [] => []
  | c :: cs => clause3 base c ++ sat3OfBase (base + S (length c)) cs
  end.

Definition sat3Of (F : cnf) : cnf := sat3OfBase (maxVar F) F.

(* 归约的两个方向（文档线讲清，机器面用表对账）：
   complete：F 的满足赋值可扩展——链上 z 取「左侧已满足」位；
   sound：sat3Of 的满足赋值截回旧变元仍满足 F——z 只是中继，
   不承载原公式信息（¬z 与 z 恰好一真，链尾必落回真文字）。 *)

Definition sampleF : list cnf :=
  [ [[(0, true); (1, true); (0, false); (1, false)]]              (* 恒真长子句 4 *)
  ; [[(0, true); (1, true); (0, false); (1, false); (0, true)]]   (* 恒真长子句 5 *)
  ; [[(0, true)]; [(0, false)]]                                   (* x0 ∧ ¬x0 不可满足 *)
  ; [[(0, true); (1, true); (2, true)]; [(0, false); (1, false)]] (* 混合 *)
  ; [[(0, true); (1, true); (2, true); (0, false); (1, false)]]   (* 长短混合 *)
  ].

(* 归约产物形状：每子句恰 3 个文字 *)
Example sat3of_shape :
  forallb (fun F => forallb (fun c => Nat.eqb (length c) 3) (sat3Of F)) sampleF
  = true.
Proof. reflexivity. Qed.

(* 可满足性双向保持：sat F = sat (sat3Of F)（两侧蛮力全枚举对账） *)
Example sat3_equiv_table :
  map (fun F => Bool.eqb (satBrute 3 F) (satBrute 6 (sat3Of F))) sampleF
  = [true; true; true; true; true].
Proof. reflexivity. Qed.

(* ---------- 3. 3SAT → CLIQUE ---------- *)

(* 顶点 (子句号 i, 文字位 j)；边 = 不同子句 且 文字不互补 *)
Definition litAt (F : cnf) (p : nat * nat) : lit :=
  nth (snd p) (nth (fst p) F []) (0, true).

Definition complements (l1 l2 : lit) : bool :=
  andb (Nat.eqb (fst l1) (fst l2)) (negb (Bool.eqb (snd l1) (snd l2))).

Definition edgeOK (F : cnf) (p q : nat * nat) : bool :=
  andb (negb (Nat.eqb (fst p) (fst q)))
       (negb (complements (litAt F p) (litAt F q))).

Fixpoint cartProd (ls : list (list (nat * nat))) : list (list (nat * nat)) :=
  match ls with
  | [] => [[]]
  | l :: rest => flat_map (fun x => map (cons x) (cartProd rest)) l
  end.

Definition clauseVerts (F : cnf) : list (list (nat * nat)) :=
  map (fun i => map (fun j => (i, j)) (seq 0 (length (nth i F []))))
      (seq 0 (length F)).

Fixpoint pairwiseOK (F : cnf) (l : list (nat * nat)) : bool :=
  match l with
  | [] | [_] => true
  | p :: t => andb (forallb (fun q => edgeOK F p q) t) (pairwiseOK F t)
  end.

Definition hasClique (F : cnf) : bool :=
  existsb (pairwiseOK F) (cartProd (clauseVerts F)).

(* 团 → 赋值：团中每个文字设其位（团内不互补 ⟹ 文字可同真） *)
Fixpoint asgSet (a : list bool) (v : nat) (p : bool) : list bool :=
  match a with
  | [] => []
  | x :: t => match v with
              | 0 => p :: t
              | S v' => x :: asgSet t v' p
              end
  end.

Definition cliqueToAsg (F : cnf) (n : nat) (comb : list (nat * nat)) : list bool :=
  fold_left (fun a p => asgSet a (fst (litAt F p)) (snd (litAt F p)))
            comb (repeat false n).

(* witnessing：可满足的 3CNF 有团，且团的文字赋值回代满足 F *)
Definition sample3 : list cnf :=
  [ [[(0, true); (1, true); (2, true)]; [(0, false); (1, false); (2, false)]]
  ; [pad3 [(0, true)]; pad3 [(0, false)]]      (* x0 ∧ ¬x0（填充后不可满足） *)
  ].

Example clique_equiv_table :
  map (fun F => Bool.eqb (satBrute 3 F) (hasClique F)) sample3
  = [true; true].
Proof. reflexivity. Qed.

Example clique_witness_check :
  map (fun F => existsb (fun comb =>
            andb (pairwiseOK F comb) (cnfSat (cliqueToAsg F 3 comb) F))
          (cartProd (clauseVerts F))) sample3
  = [true; false].
Proof. reflexivity. Qed.
(* 第二行为 false 恰是重点：不可满足公式无团——归约把「无赋值」
   忠实翻译成「无团」，这正是 NP 完全性的归约方向要求。 *)

(* ---------- 4. 归约复合传递 ---------- *)

(* SAT→3SAT→CLIQUE 全链一致：原始公式的可满足性 = 最终图的有团性 *)
Example red_trans :
  map (fun F => Bool.eqb (satBrute 3 F) (hasClique (sat3Of F))) sampleF
  = [true; true; true; true; true].
Proof. reflexivity. Qed.

(* 冒烟 *)
Compute (map sat3Of sampleF).
Compute (map hasClique (map sat3Of sampleF)).
