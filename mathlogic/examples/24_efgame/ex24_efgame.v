(* ex24_efgame.v —— EF 博弈与 Fraïssé 定理（EFT ch XII）
   机器件：部分同构检查 pi_ok + n 轮 duplicator 赢策略求解器 dup_wins
   （minimax 的布尔对偶）+ (Z_n,<) 分离定理现场 + 空关系/全关系结构对
   + 与 23 章 eeq 的秩-轮对齐。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 有限结构：论域大小 + 一个二元关系 ---------- *)

Record fstruct : Type := mk {
  size : nat;
  rel : nat -> nat -> bool
}.

Definition domain (A : fstruct) : list nat := seq 0 (size A).

(* 线序 Z_n：<；空关系；全关系 *)
Definition Zord (n : nat) : fstruct := mk n (fun a b => a <? b).
Definition Zempty (n : nat) : fstruct := mk n (fun a b => false).
Definition Zfull (n : nat) : fstruct := mk n (fun a b => true).

(* ---------- 2. 部分同构检查 ---------- *)

(* 已选点对表 ps：诱导子结构上的部分同构 =
   两投影都单射 + 关系在两结构上一致 *)
Definition inj_by (proj : nat*nat -> nat) (ps : list (nat*nat)) : bool :=
  forallb (fun p => forallb (fun q =>
    negb (andb (Nat.eqb (proj p) (proj q))
               (negb (andb (Nat.eqb (fst p) (fst q))
                           (Nat.eqb (snd p) (snd q)))))) ps) ps.

Definition rel_match (A B : fstruct) (ps : list (nat*nat)) : bool :=
  forallb (fun p => forallb (fun q =>
    Bool.eqb (rel A (fst p) (fst q)) (rel B (snd p) (snd q))) ps) ps.

Definition pi_ok (A B : fstruct) (ps : list (nat*nat)) : bool :=
  andb (andb (inj_by fst ps) (inj_by snd ps)) (rel_match A B ps).

(* ---------- 3. n 轮 duplicator 赢策略（minimax 布尔对偶） ---------- *)

(* dup 赢 m 轮（当前已选 ps）：
   m = 0：ps 已是部分同构；
   m+1：spoiler 从 A 挑 a 则 dup 能应 b；从 B 挑 b 则 dup 能应 a *)
Fixpoint dup_wins (m : nat) (A B : fstruct) (ps : list (nat*nat)) : bool :=
  match m with
  | O => pi_ok A B ps
  | S m' =>
      andb (forallb (fun a => existsb (fun b =>
               dup_wins m' A B ((a, b) :: ps)) (domain B)) (domain A))
           (forallb (fun b => existsb (fun a =>
               dup_wins m' A B ((a, b) :: ps)) (domain A)) (domain B))
  end.

(* ---------- 4. 现场一：(Z_n,<) 的分离定理 ---------- *)

(* 经典结论（书 XII 例）：线序对上 dup 赢 k 轮当且仅当两侧都
   「足够长」（≥ 2^k - 1 的邻域）。机器面：小表全算。 *)
(* 单点对二点：3 轮必输（spoiler 在二点侧挑相隔对） *)
Example Z1_Z2_loses3 : negb (dup_wins 3 (Zord 1) (Zord 2) []) = true.
Proof. reflexivity. Qed.

(* 同构对：任意轮数 dup 全赢 *)
Example Z5_Z5_wins : forallb (fun m => dup_wins m (Zord 5) (Zord 5) [])
  (seq 0 4) = true.
Proof. reflexivity. Qed.

(* 大对大：Z_7 vs Z_8，三轮 dup 仍赢（两侧都 ≥ 2^3-1=7） *)
Example Z7_Z8_wins3 : dup_wins 3 (Zord 7) (Zord 8) [] = true.
Proof. reflexivity. Qed.

(* Z_3 vs Z_4：三轮 dup 输（3 < 7——分离定理方向） *)
Example Z3_Z4_loses3 : negb (dup_wins 3 (Zord 3) (Zord 4) []) = true.
Proof. reflexivity. Qed.

(* 两轮下 Z_3 vs Z_4 赢（3 ≥ 2^2-1）——轮数-规模的交界 *)
Example Z3_Z4_wins2 : dup_wins 2 (Zord 3) (Zord 4) [] = true.
Proof. reflexivity. Qed.

(* ---------- 5. 现场二：空/全关系结构（无关元数的同构类） ---------- *)

(* 空关系下结构只由大小决定；同大小全赢 *)
Example empty_pair : forallb (fun m => dup_wins m (Zempty 3) (Zempty 3) [])
  (seq 0 4) = true.
Proof. reflexivity. Qed.

(* 大小不同：一轮就分（spoiler 挑两点逼出单射失守）…… 实际上
   一轮只选一点：pi_ok 单点恒真——两轮起才分 *)
Example empty_size2 : dup_wins 2 (Zempty 2) (Zempty 3) [] = true.
Proof. reflexivity. Qed.

Example empty_size2_3rounds : negb (dup_wins 3 (Zempty 2) (Zempty 3) []) = true.
Proof. reflexivity. Qed.

(* 全关系镜像 *)
Example full_size2_3rounds : negb (dup_wins 3 (Zfull 2) (Zfull 3) []) = true.
Proof. reflexivity. Qed.

(* ---------- 6. 与 23 章的秩-轮对齐 ---------- *)

(* σ₂ 区分 Z_1/Z_2（23 章实测）；EF 博弈：2 轮分、1 轮不分 *)
Example align_1 : andb (negb (dup_wins 2 (Zord 1) (Zord 2) []))
                       (dup_wins 1 (Zord 1) (Zord 2) []) = true.
Proof. reflexivity. Qed.

(* σ₃ 区分 Z_2/Z_3；EF：2 轮已分（序的「相邻性」比「元数」更早暴露
   差异——对照空/全关系要到 3 轮才分）、1 轮不分 *)
Example align_2 : andb (negb (dup_wins 2 (Zord 2) (Zord 3) []))
                       (dup_wins 1 (Zord 2) (Zord 3) []) = true.
Proof. reflexivity. Qed.

(* dup 赢 k 轮 ⟺ 秩 k 内初等等价（Fraïssé/XII.3）：机器面在
   23 章 eeq_rank 的抽样上一致——对齐表见冒烟输出 *)

(* ---------- 7. 冒烟 ---------- *)

Compute (map (fun m => dup_wins m (Zord 2) (Zord 3) []) (seq 0 4)).
   (* [true; true; false; false]：2 对 3 在 2 轮被分（相邻性暴露） *)
Compute (map (fun m => dup_wins m (Zord 4) (Zord 5) []) (seq 0 4)).
   (* [true; true; true; false]：4 对 5 在 3 轮被分（4 < 2^3-1=7） *)
Compute (map (fun m => dup_wins m (Zempty 2) (Zempty 3) []) (seq 0 4)).
   (* [true; true; true; false]：空关系要到 3 轮（元数才分） *)
