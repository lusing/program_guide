(* ex41_ars.v —— 归约分解：抽象归约系统（Zimmermann 篇，书 ch11）
   机器件：有限 ARS 实验室——3 点关系（9 位掩码、512 个全枚举）——
   (1) 检查器五件：终止（无环=无 x→⁺x）、局部合流（一步分叉可联
       接）、合流（→* 对全可联接）、交换（R 一步与 S 一步经闭包可
       换——Hindley-Rosen 意义）；
   (2) **Newman 引理的穷举式机器证明（|A|=3）**：
       512 个关系逐个核验「终止 ∧ 局部合流 ⇒ 合流」零反例；
   (3) **|A|=3 的意外红利**：局部合流 ⇒ 合流在 3 点上无条件成立
       （终止假设在 3 点是多余的——反例至少要 4 点）；
   (4) **Hindley-Rosen/合流转移（书定理 5）的穷举式机器证明**：
       全部 512×512 对 (R1,R2)：R1、R2 各自合流且交换 ⟹ 并合流；
   (5) 定理 5 的假设必要性现场：R1={(0,1)}、R2={(0,2)} 各自合流但
       **不交换**，其并 0→1,0→2 局部不合流也不合流——缺一不可；
   (6) 定理 6（终止转移）与 IL/ILL 的严格局部合流——文档线。
   零公理。坑位速记见 docs/41-ars.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

(* ---------- 1. ARS 表示与检查器 ---------- *)

Definition step (R x y : nat) : bool := Nat.testbit R (3 * x + y).
Definition allRels : list nat := seq 0 512.
Definition pts : list nat := [0;1;2].

Definition succs (R x : nat) : list nat :=
  filter (step R x) pts.

(* →* ：可达闭包（不动点迭代，3 点上 3 轮即饱和） *)
Fixpoint reachAux (fuel : nat) (R x : nat) : list nat :=
  match fuel with
  | 0 => [x]
  | S k =>
      let prev := reachAux k R x in
      fold_left (fun acc y => acc ++ succs R y) prev prev
  end.

Fixpoint remove_dup (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: t => if existsb (Nat.eqb x) t then remove_dup t
              else x :: remove_dup t
  end.

Definition reach (R x : nat) : list nat :=
  remove_dup (reachAux 4 R x).

Definition inL (x : nat) (l : list nat) : bool := existsb (Nat.eqb x) l.

Definition joinable (R y z : nat) : bool :=
  existsb (fun w => andb (inL w (reach R y)) (inL w (reach R z))) pts.

Definition locallyConfluent (R : nat) : bool :=
  forallb (fun x =>
    forallb (fun p =>
      match p with
      | (y, z) => joinable R y z
      end)
      (flat_map (fun y => map (fun z => (y, z)) (succs R x)) (succs R x)))
    pts.

Definition confluent (R : nat) : bool :=
  forallb (fun x =>
    forallb (fun p =>
      match p with
      | (y, z) => joinable R y z
      end)
      (flat_map (fun y => map (fun z => (y, z)) (reach R x)) (reach R x)))
    pts.

Definition reachNoSelf (R y : nat) : list nat :=
  (* y 的可达集去掉 y 自身（x→y 后经非空路径回 x 即成圈） *)
  filter (fun w => negb (Nat.eqb w y)) (reach R y).

Definition terminatingR (R : nat) : bool :=
  negb (existsb (fun x =>
          existsb (fun y =>
            andb (step R x y)
                 (existsb (Nat.eqb x) (reachNoSelf R y)))
          pts) pts).

(* 交换（Hindley-Rosen）：x—R1→y 且 x—R2→z ⟹ ∃w: y—R2*→w 且 z—R1*→w *)
Definition commutes (R1 R2 : nat) : bool :=
  forallb (fun x =>
    forallb (fun y =>
      forallb (fun z =>
        if andb (step R1 x y) (step R2 x z)
        then existsb (fun w => andb (inL w (reach R2 y))
                                    (inL w (reach R1 z))) pts
        else true) pts) pts) pts.

Definition unionR (R1 R2 : nat) : nat := Nat.lor R1 R2.

(* ---------- 2. 断言电池 ---------- *)

(* 电一：Newman 引理的穷举式机器证明（3 点全部 512 个关系） *)
Example newman_exhaustive :
  forallb (fun R => implb (andb (terminatingR R) (locallyConfluent R))
                          (confluent R)) allRels
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：|A|=3 的意外红利——LC ⇒ Conf 无条件成立
   （终止假设在 3 点多余；经典反例 a→b,a→c,b→a 型在 3 点内
   造不出「LC 但不合流」——至少要 4 点） *)
Example lc_implies_conf_3 :
  forallb (fun R => implb (locallyConfluent R) (confluent R)) allRels
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电三：Hindley-Rosen/合流转移（定理 5）的穷取式机器证明：
   全部 512×512 对：R1、R2 各自合流且交换 ⟹ 并合流 *)
Example hindley_rosen_exhaustive :
  forallb (fun p =>
    let R1 := fst p in let R2 := snd p in
    implb (andb (confluent R1)
                (andb (confluent R2) (commutes R1 R2)))
          (confluent (unionR R1 R2)))
    (flat_map (fun a => map (fun b => (a, b)) allRels) allRels)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电四：定理 5 假设必要性现场。R1={(0,1)} 掩码 bit0=1；R2={(0,2)}
   bit2=4：各自合流，但**不交换**；其并局部不合流也不合流。 *)
Definition R1a : nat := 1.    (* 0→1 *)
Definition R2a : nat := 4.    (* 0→2 *)
Definition Ra  : nat := 5.    (* 并：0→1, 0→2 *)

Example t5_hypothesis_necessary :
  andb (confluent R1a)
       (andb (confluent R2a)
             (andb (negb (commutes R1a R2a))
                   (andb (negb (locallyConfluent Ra))
                         (negb (confluent Ra)))))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电五：正样本——R1={(0,1),(1,2)}、R2={(1,2),(2,?)} 取线性链：
   R1={(0,1),(1,2)} bit(0)=1,bit(4)=16 → 17；R2={(1,2),(2,0)}? 取
   交换 vacuous 的组合：R1=17（0→1→2），R2=32+?（1→2 已在）——
   直接取 R2={(2,1)} bit(7)=128：R1 合流 ✓ R2 合流 ✓ 交换：x 有
   R1 与 R2 双出边？x=2: R1 出边无；x=1: R1 1→2, R2 1→? 无。
   vacuous 交换 ✓；并 0→1→2→1 有圈但合流。 *)
Definition R1b : nat := 17.    (* 0→1, 1→2 *)
Definition R2b : nat := 128.   (* 2→1 *)
Definition Rb  : nat := 145.   (* 并：0→1,1→2,2→1 *)

Example t5_positive :
  andb (confluent R1b)
       (andb (confluent R2b)
             (andb (commutes R1b R2b)
                   (confluent Rb)))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (length allRels).
Compute (filter (fun R => andb (locallyConfluent R) (negb (confluent R))) allRels).
Compute (filter terminatingR (seq 0 16)).
