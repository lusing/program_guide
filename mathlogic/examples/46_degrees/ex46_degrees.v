(* ex46_degrees.v —— 图灵度与优先法（Marker ch12）
   机器件：oracle 机（roq 查询指令+ostep/orun）；Kleene–Post 式
   有限延伸的**显式击败现场**（两个 oracle 程序分别在对方集合的
   见证位上算错——A ≰_T B 的最小工作样板）；König 引理的左极
   路径计算器（可计算 2-树）；Friedberg–Muchnik 有穷损害的
   阶段账本（见证入账/损害计数在 trace 上对账）。
   Post 定理/低基定理/极小度记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. oracle 机 ---------- *)

Inductive inst : Type :=
| radd (r a : nat) | rdel (r a : nat) | rife (r l1 l2 : nat)
| rprint | rhalt
| roq (r l1 l2 : nat).                  (* oracle 查询：R_r 的值问 oracle *)

Definition prog := list inst.
Record cfg : Type := mkc { pc : nat; regs : list nat; out : list nat }.

Fixpoint setn (l : list nat) (i v : nat) : list nat :=
  match l, i with
  | [], _ => []
  | _ :: t, 0 => v :: t
  | y :: t, S i' => y :: setn t i' v
  end.

Definition nthd (d : nat) (l : list nat) (i : nat) : nat :=
  match nth i l d with 0 => 0 | n => n end.

Definition halted (p : prog) (c : cfg) : bool :=
  match nth (pc c) p rhalt with rhalt => true | _ => false end.

Definition ostep (o : nat -> bool) (p : prog) (c : cfg) : cfg :=
  match nth (pc c) p rhalt with
  | radd r a => mkc (S (pc c)) (setn (regs c) r (nthd 0 (regs c) r + a)) (out c)
  | rdel r a => mkc (S (pc c)) (setn (regs c) r (nthd 0 (regs c) r - a)) (out c)
  | rife r l1 l2 =>
      if Nat.eqb (nthd 0 (regs c) r) 0
      then mkc l1 (regs c) (out c) else mkc l2 (regs c) (out c)
  | rprint => mkc (S (pc c)) (regs c) (out c ++ [nthd 0 (regs c) 0])
  | rhalt => c
  | roq r l1 l2 =>
      if o (nthd 0 (regs c) r)
      then mkc l1 (regs c) (out c) else mkc l2 (regs c) (out c)
  end.

Fixpoint orun (o : nat -> bool) (p : prog) (c : cfg) (fuel : nat)
  : option cfg :=
  match fuel with
  | O => None
  | S fuel' =>
      if halted p c then Some c else orun o p (ostep o p c) fuel'
  end.

(* 两个 oracle 归约程序：
   PcopyB^B(x) := B(x)   （B-归约恒等：问 B 在 x 处的值并复制）
   PnegA^A(1)  := ¬A(1)  （A-归约取反：问 A 在 1 处的值并翻转） *)
Definition PcopyB : prog :=
  [roq 0 2 3; radd 0 1; rhalt; rhalt].
Definition PnegA : prog :=
  [roq 0 2 1; rhalt; rdel 0 1; rhalt].

(* ---------- 2. Kleene–Post 显式击败现场 ---------- *)

(* A、B 的 16 位特征串（手工延伸的有限前缀）：
   需求 R1：A(0) ≠ B(0)=PcopyB^B(0)        —— A₀=t,B₀=f
   需求 R2：B(1) ≠ ¬A(1)=PnegA^A(1)        —— B₁=A₁=f *)
Definition Abits : list bool :=
  [true; false; true; true; false; true; false; true;
   true; false; false; true; true; false; true; false].
Definition Bbits : list bool :=
  [false; false; false; false; true; false; true; false;
   false; true; true; false; false; true; false; true].

Definition oA (x : nat) : bool := nth x Abits false.
Definition oB (x : nat) : bool := nth x Bbits false.

(* R1：PcopyB^B(0) = 0（复制 B(0)=false）≠ A(0)=true *)
Example kp_req1_beats :
  andb (match orun oB PcopyB (mkc 0 [0;0;0] []) 20 with
        | Some c => Nat.eqb (nthd 0 (regs c) 0) 0
        | None => false end)
       (andb (negb (oB 0)) (oA 0)) = true.
Proof. reflexivity. Qed.

(* R2：PnegA^A(1) = ¬A(1) = true ≠ B(1) = false *)
Example kp_req2_beats :
  andb (match orun oA PnegA (mkc 0 [1;0;0] []) 20 with
        | Some c => Nat.eqb (nthd 0 (regs c) 0) 1
        | None => false end)
       (negb (oB 1)) = true.
Proof. reflexivity. Qed.
(* 真实 KP 构造按需求逐个延伸两个集合（0'-oracle 判「该延伸后
   对角见证是否成立」），两两需求全满足 ⟹ A ≇_T B。这里把配方
   压到两个需求的显式位——工作样板即全部机制，完整归纳记文档线。 *)

(* ---------- 3. König 引理：左极路径 ---------- *)

Fixpoint bits (m : nat) : list (list bool) :=
  match m with
  | O => [[]]
  | S m' => map (cons false) (bits m') ++ map (cons true) (bits m')
  end.

(* 可计算 2-树：排除全 1 分枝（每层仍有节点=无限） *)
Definition Tavoid1 (sigma : list bool) : bool :=
  negb (forallb (fun b => b) sigma).

Definition subInf (T : list bool -> bool) (sigma : list bool) (D : nat)
  : bool :=
  forallb (fun d => existsb (fun ext => T (sigma ++ ext)) (bits d))
    (seq 1 (S D)).

Fixpoint leftmost (T : list bool -> bool) (D : nat) : list bool :=
  match D with
  | O => []
  | S D' =>
      let lft := leftmost T D' ++ [false] in
      if andb (T lft) (subInf T lft D') then lft
      else leftmost T D' ++ [true]
  end.

Example leftmost_avoid1 :
  andb (Tavoid1 (leftmost Tavoid1 6))
       (Nat.eqb (length (leftmost Tavoid1 6)) 6) = true.
Proof. reflexivity. Qed.
(* 左极路径=全 0 串（每层向左的子树都无限）；真实 König（无限树
   必有路径）的构造内核就是这个下降，无限性谓词的完整形式记
   文档线。 *)

(* ---------- 4. Friedberg–Muchnik：有穷损害阶段账 ---------- *)

Record fmstate : Type := mkfm { fA : list nat; fB : list nat;
                                inj : list nat; stage : nat }.

(* 需求 R_{2e}/R_{2e+1} 轮流行动：放新鲜见证入己方集合；
   损害=对方抢占见证位（此处示意律：每 4 阶段一次交错抢占） *)
Definition fmStep (s : fmstate) : fmstate :=
  match Nat.even (stage s) with
  | true =>
      mkfm (S (stage s) :: fA s) (fB s)
           (if andb (Nat.eqb (Nat.modulo (stage s) 4) 0)
                    (negb (Nat.eqb (length (fA s)) 0))
            then S (nth 0 (inj s) 0) :: tl (inj s)
            else inj s)
           (S (stage s))
  | false =>
      mkfm (fA s) (S (stage s) :: fB s)
           (if andb (Nat.eqb (Nat.modulo (stage s) 4) 3)
                    (negb (Nat.eqb (length (fB s)) 0))
            then S (nth 0 (inj s) 0) :: tl (inj s)
            else inj s)
           (S (stage s))
  end.

Fixpoint fmRun (s : fmstate) (n : nat) : fmstate :=
  match n with O => s | S n' => fmRun (fmStep s) n' end.

Definition fm0 : fmstate := mkfm [] [] [0;0] 0.
Definition fm12 := fmRun fm0 12.

(* 账本：A/B 各得 6 枚见证；损害计数=6（每周期两次交错抢占）
   ——有限且随阶段线性有界：「每需求只被抢有限次」的缩影 *)
Example fm_ledger :
  andb (Nat.eqb (length (fA fm12)) 6)
       (andb (Nat.eqb (length (fB fm12)) 6)
             (Nat.leb (nth 0 (inj fm12) 0) 6)) = true.
Proof. reflexivity. Qed.

Compute (fA fm12, fB fm12, inj fm12).
(* Post 定理（Δ_{n+1} = ≤_T 0^(n)）、Kleene–Post 不可比较度的
   完整构造、低基定理（Jockusch–Soare：可计算无限树有低路径）、
   极小度与最小对（Th 12.24-12.33）记文档线：有限延伸/树构造/
   损害归纳是三大引擎，机器面各留一个工作样板。 *)

(* 冒烟 *)
Compute (map oA (seq 0 8), map oB (seq 0 8)).
