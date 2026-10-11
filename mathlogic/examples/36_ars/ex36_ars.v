(* ex36_ars.v —— 归约分解：抽象归约系统（Zimmermann 篇，书 ch11）
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
   零公理。坑位速记见 docs/36-ars.md。 *)

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

(* 可达掩码：reach 一次、配对查位——性能命脉（HR 穷举 512×512） *)
Definition reachMask (R x : nat) : nat :=
  fold_left (fun acc y => Nat.lor acc (Nat.shiftl 1 y)) (reach R x) 0.

Definition maskMeet (R y z : nat) : bool :=
  negb (Nat.eqb (Nat.land (reachMask R y) (reachMask R z)) 0).

Definition joinable (R y z : nat) : bool := maskMeet R y z.

Definition locallyConfluent (R : nat) : bool :=
  forallb (fun x =>
    forallb (fun p =>
      match p with
      | (y, z) => joinable R y z
      end)
      (flat_map (fun y => map (fun z => (y, z)) (succs R x)) (succs R x)))
    pts.

Definition confluent (R : nat) : bool :=
  (* 每层只算一次 reach（x/y/z 各自缓存到 let）——穷举 512×512 的
     性能命脉：朴素 pairwise joinable 会把 reach 重算 10^10 次。 *)
  forallb (fun x =>
    let rx := reach R x in
    forallb (fun y =>
      let ry := reach R y in
      forallb (fun z =>
        existsb (fun w => andb (inL w ry) (inL w (reach R z))) rx)
        rx)
      rx)
    pts.

Definition maskMeetR (Ra y Rb z : nat) : bool :=
  negb (Nat.eqb (Nat.land (reachMask Ra y) (reachMask Rb z)) 0).

Definition commutes (R1 R2 : nat) : bool :=
  forallb (fun x =>
    forallb (fun y =>
      forallb (fun z =>
        if andb (step R1 x y) (step R2 x z)
        then maskMeetR R2 y R1 z
        else true) pts) pts) pts.


(* ---------- 表驱动记忆化：512 个关系的可达掩码表 ----------
   HR 穷举 512×512 的唯一可行形状：每关系一次 reach 存掩码、
   查表用 nth（单轴 nat 的 eqb/find 是 512×511 步的暗雷）。 *)
Definition rmaskList : list (list nat) :=
  map (fun R => map (fun x => reachMask R x) pts) allRels.

Definition masksAt (R : nat) : list nat := nth R rmaskList [].
Definition mOf (ms : list nat) (x : nat) : nat := nth x ms 0.

Definition bit3 (m : nat) (x : nat) : bool := Nat.testbit m x.

Definition joinMask (m1 m2 : nat) : bool :=
  negb (Nat.eqb (Nat.land m1 m2) 0).

Definition stepMask (R x : nat) : nat :=
  (* x 的一步后继打包（位拼装，不查表） *)
  (if Nat.testbit R (3 * x + 0) then 1 else 0)
+ (if Nat.testbit R (3 * x + 1) then 2 else 0)
+ (if Nat.testbit R (3 * x + 2) then 4 else 0).

(* 纯位循环：x/y/z 各 3 拍，无 reach/succs 调用 *)
Definition locallyConfluentT (R : nat) : bool :=
  let ms := masksAt R in
  forallb (fun x =>
    forallb (fun y =>
      forallb (fun z =>
        if andb (bit3 (stepMask R x) y) (bit3 (stepMask R x) z)
        then joinMask (mOf ms y) (mOf ms z)
        else true) pts) pts) pts.

Definition confluentT (R : nat) : bool :=
  let ms := masksAt R in
  forallb (fun x =>
    forallb (fun y =>
      forallb (fun z =>
        if andb (bit3 (mOf ms x) y) (bit3 (mOf ms x) z)
        then joinMask (mOf ms y) (mOf ms z)
        else true) pts) pts) pts.

Definition commutesT (R1 R2 : nat) : bool :=
  let ms1 := masksAt R1 in let ms2 := masksAt R2 in
  forallb (fun x =>
    forallb (fun y =>
      forallb (fun z =>
        if andb (bit3 (stepMask R1 x) y) (bit3 (stepMask R2 x) z)
        then joinMask (mOf ms2 y) (mOf ms1 z)
        else true) pts) pts) pts.

Definition terminatingR (R : nat) : bool :=
  (* 无环=无自环 且 无 x→y 使 x 经非空路径回到（y 的可达去自身） *)
  let ms := masksAt R in
  let selfloop := existsb (fun x => bit3 (stepMask R x) x) pts in
  let backedge :=
    existsb (fun x =>
      existsb (fun y =>
        andb (bit3 (stepMask R x) y)
             (Nat.testbit (Nat.land (mOf ms y)
                          (Nat.lxor 7 (Nat.shiftl 1 y))) x))
      pts) pts in
  negb (orb selfloop backedge).

(* 交换（Hindley-Rosen）：x—R1→y 且 x—R2→z ⟹ ∃w: y—R2*→w 且 z—R1*→w *)
Definition unionR (R1 R2 : nat) : nat := Nat.lor R1 R2.

(* ---------- 2. 断言电池 ---------- *)

(* 电一：Newman 引理的穷举式机器证明（3 点全部 512 个关系） *)
Example newman_exhaustive :
  forallb (fun R => implb (andb (terminatingR R) (locallyConfluentT R))
                          (confluentT R)) allRels
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：|A|=3 的意外红利——LC ⇒ Conf 无条件成立
   （终止假设在 3 点多余；经典反例 a→b,a→c,b→a 型在 3 点内
   造不出「LC 但不合流」——至少要 4 点） *)
Example lc_implies_conf_3 :
  forallb (fun R => implb (locallyConfluentT R) (confluentT R)) allRels
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电三：Hindley-Rosen/合流转移（定理 5）的穷取式机器证明：
   全部 512×512 对：R1、R2 各自合流且交换 ⟹ 并合流 *)
Example hindley_rosen_exhaustive :
  forallb (fun p =>
    let R1 := fst p in let R2 := snd p in
    implb (andb (confluentT R1)
                (andb (confluentT R2) (commutesT R1 R2)))
          (confluentT (unionR R1 R2)))
    (flat_map (fun a => map (fun b => (a, b)) allRels) allRels)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电四：定理 5 假设必要性现场。R1={(0,1)} 掩码 bit0=1；R2={(0,2)}
   bit2=4：各自合流，但**不交换**；其并局部不合流也不合流。 *)
Definition R1a : nat := 2.    (* 0→1：bit(3·0+1)=2 *)
Definition R2a : nat := 4.    (* 0→2 *)
Definition Ra  : nat := 6.    (* 并：0→1, 0→2 *)

Example t5_hypothesis_necessary :
  andb (confluentT R1a)
       (andb (confluentT R2a)
             (andb (negb (commutesT R1a R2a))
                   (andb (negb (locallyConfluentT Ra))
                         (negb (confluentT Ra)))))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电五：正样本——R1={(0,1),(1,2)}、R2={(1,2),(2,?)} 取线性链：
   R1={(0,1),(1,2)} bit(0)=1,bit(4)=16 → 17；R2={(1,2),(2,0)}? 取
   交换 vacuous 的组合：R1=17（0→1→2），R2=32+?（1→2 已在）——
   直接取 R2={(2,1)} bit(7)=128：R1 合流 ✓ R2 合流 ✓ 交换：x 有
   R1 与 R2 双出边？x=2: R1 出边无；x=1: R1 1→2, R2 1→? 无。
   vacuous 交换 ✓；并 0→1→2→1 有圈但合流。 *)
Definition R1b : nat := 34.    (* 0→1, 1→2：bit1+bit5 *)
Definition R2b : nat := 128.   (* 2→1 *)
Definition Rb  : nat := 162.   (* 并：0→1,1→2,2→1 *)

Example t5_positive :
  andb (confluentT R1b)
       (andb (confluentT R2b)
             (andb (commutesT R1b R2b)
                   (confluentT Rb)))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (length allRels).
Compute (filter (fun R => andb (locallyConfluent R) (negb (confluent R))) allRels).
Compute (filter terminatingR (seq 0 16)).
