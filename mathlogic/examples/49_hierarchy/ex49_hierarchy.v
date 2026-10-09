(* ex49_hierarchy.v —— 可枚举集与算术层级（Marker ch11）
   机器件：K/ Tot/ Fin 的层级归属见证（Σ₁/Π₂/Σ₂ 前束形态的逐点
   对账）；多一归约的样本现场（偶性 ≤ₘ K）；层级分离的有限影子
   （K 的补在阶段账本上永不兑现）；Kolmogorov 复杂度的表宇宙版
   （短描述比串少——随机数存在的鸽笼账）。Chaitin 不完备现象与
   完全集（K Σ₁-完全、Tot Π₂-完全）记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 0. 机器宇宙（48 章同款，独立成册） ---------- *)

Inductive inst : Type :=
| radd (r a : nat) | rdel (r a : nat) | rife (r l1 l2 : nat)
| rprint | rhalt.

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

Definition step (p : prog) (c : cfg) : cfg :=
  match nth (pc c) p rhalt with
  | radd r a => mkc (S (pc c)) (setn (regs c) r (nthd 0 (regs c) r + a)) (out c)
  | rdel r a => mkc (S (pc c)) (setn (regs c) r (nthd 0 (regs c) r - a)) (out c)
  | rife r l1 l2 =>
      if Nat.eqb (nthd 0 (regs c) r) 0
      then mkc l1 (regs c) (out c) else mkc l2 (regs c) (out c)
  | rprint => mkc (S (pc c)) (regs c) (out c ++ [nthd 0 (regs c) 0])
  | rhalt => c
  end.

Fixpoint run (p : prog) (c : cfg) (fuel : nat) : option cfg :=
  match fuel with
  | O => None
  | S fuel' => if halted p c then Some c else run p (step p c) fuel'
  end.

Definition U : list prog :=
  [ [radd 0 1; rhalt]                    (* 0: +1 *)
  ; [radd 0 2; rhalt]                    (* 1: +2 *)
  ; [radd 0 0; rhalt]                    (* 2: 恒等 *)
  ; [radd 0 1; rdel 0 1; rhalt]          (* 3: 恒等（异写） *)
  ; [radd 0 1; rife 0 0 1]               (* 4: 自转 *)
  ; [rhalt]                              (* 5: 立即停 *)
  ; [radd 0 3; radd 0 3; rhalt]          (* 6: +6 *)
  ; [rdel 0 1; rife 0 5 0]               (* 7: x=0 停 *)
  ; [rife 1 9 9]                         (* 8: 自转 *)
  ; [rprint; rhalt]                      (* 9: 打印停 *)
  ; [radd 0 1; radd 0 1; radd 0 1; rhalt] (* 10: +3 *)
  ; [radd 1 1; rhalt]                    (* 11 *)
  ; [rdel 0 1; rhalt]                    (* 12: −1 *)
  ; [rife 0 14 14]                       (* 13 *)
  ; [radd 0 0; rprint; rhalt]            (* 14: 打印停 *)
  ; [radd 0 5; rhalt]                    (* 15: +5 *)
  ; [rdel 0 5; rhalt]                    (* 16: −5 *)
  ; [radd 0 1; radd 0 1; rhalt]          (* 17: +2（1 的异写） *)
  ; [rife 0 19 20; rhalt]                (* 18 *)
  ; [rhalt]                              (* 19 *)
  ; [radd 0 1; rdel 0 2; rhalt]          (* 20: x−1 *)
  ; [rprint; rprint; rhalt]              (* 21: 双打印 *)
  ; [radd 0 9; rhalt]                    (* 22: +9 *)
  ; [rife 1 5 5]                         (* 23 *)
  ].

Definition urun (e x fuel : nat) : option cfg :=
  run (nth e U [rhalt]) (mkc 0 [x;0;0] []) fuel.

(* 输出集截段：W_{e,s} = 程序 e 在 s 步内打印的全部值 *)
Definition Wout (e s : nat) : list nat :=
  match urun e 0 s with
  | Some c => out c
  | None => []
  end.

(* ---------- 1. 层级归属见证 ---------- *)

Definition kStage (e s : nat) : bool :=
  match urun e e s with Some _ => true | None => false end.

(* K = {e : ∃s kStage e s}——Σ₁ 形；机器面：阶段枚举与成员一致 *)
Example k_sigma1 :
  forallb (fun e => Bool.eqb
    (existsb (fun s => kStage e s) (seq 0 40))
    (match urun e e 40 with Some _ => true | None => false end))
    (seq 0 24) = true.
Proof. reflexivity. Qed.

(* Tot = {e : ∀n ∃s urun e n s 停}——Π₂ 形的逐点对账 *)
Definition totWit (e n s : nat) : bool :=
  match urun e n s with Some _ => true | None => false end.

(* 0 号（+1）全停；4 号（自转）全不停——两个方向的样本 *)
Example tot_sample :
  andb (forallb (fun n => existsb (fun s => totWit 0 n s) (seq 0 40)) (seq 0 10))
       (forallb (fun n => negb (existsb (fun s => totWit 4 n s) (seq 0 40)))
                (seq 0 10)) = true.
Proof. reflexivity. Qed.

(* Fin = {e : W_e 有限}——Σ₂ 形：∃m ∀x>m ∀s x ∉ W_{e,s}
   机器面：打印型程序（9/14/21 号）输出集即时封顶 *)
Definition finWit (e x s : nat) : bool := negb (existsb (Nat.eqb x) (Wout e s)).

Example fin_print_programs :
  forallb (fun e => existsb (fun m =>
              forallb (fun x => forallb (fun s => finWit e x s) (seq 0 40))
                      (seq (S m) 20))
            [0;1])
    [9;14;21] = true.
Proof. reflexivity. Qed.

(* ---------- 2. 多一归约样本：偶性 ≤ₘ K ---------- *)

(* f(x) := 偶→5（停）/ 奇→4（自转）——x 偶 ⟺ f(x) ∈ K *)
Definition redEven (x : nat) : nat :=
  if Nat.even x then 5 else 4.

Example even_le_m_K :
  forallb (fun x => Bool.eqb (Nat.even x)
                        (match urun (redEven x) (redEven x) 40 with
                         | Some _ => true | None => false end))
    (seq 0 16) = true.
Proof. reflexivity. Qed.
(* K 是 Σ₁-完全的：每个 CE 集都这样折进 K——一般构造（从 A 的
   枚举器造「入 A 则停」的程序并取码）记文档线。 *)

(* ---------- 3. 层级分离的有限影子 ---------- *)

(* K 的补不是 CE：若 K̄ 有枚举器，K 可判定——阶段账本上看得见
   「永不兑现」：对每个 s，K_s ∪ K̄_s ⊊ 全域（4 号两边都不在） *)
Example separation_shadow :
  forallb (fun s =>
    andb (negb (existsb (fun e => andb (Nat.eqb e 4) (kStage e s)) (seq 0 24)))
         (match urun 4 4 s with Some _ => false | None => true end))
    (seq 0 40) = true.
Proof. reflexivity. Qed.
(* 有限影子只展示「一个点永远悬置」；完整的对角论证（若 K̄=W_c
   则问 c∈W_c?）记文档线——Σ₁ ≠ Π₁ 的分层严格性。 *)

(* ---------- 4. Kolmogorov 复杂度：表宇宙版 ---------- *)

(* 描述 = 表程序码；K_U(x) := 输出 x 的最小编码（无则 ∞=24） *)
Definition outputOf (e : nat) : nat :=
  match urun e 0 40 with
  | Some c => nthd 0 (regs c) 0
  | None => 999
  end.

Definition kOf (x : nat) : nat :=
  match filter (fun e => Nat.eqb (outputOf e) x) (seq 0 24) with
  | e :: _ => e
  | [] => 24    (* 无描述——「无限复杂」的账面值 *)
  end.

(* 短描述比串少：码 < 8（3 位）的程序只有 7 个，其中可用的更少
   ——长度 4 的串（8..15）里必然有 K_U ≥ 4 的随机数 *)
Example randoms_exist :
  existsb (fun x => andb (Nat.leb 8 x) (andb (Nat.leb (kOf x) 23) (Nat.leb 4 (kOf x))))
          (seq 8 8) = true.
Proof. reflexivity. Qed.

Compute (map kOf (seq 0 16)).
(* 账本：能看到哪些数有短描述、哪些「随机」（24=无描述）。
   |x| := 二进制长度：kOf x ≥ |x| 即随机。Chaitin 现象（「kOf(x) ≥ m
   的第一个 x」构成 Π₁ 集却不可计算——一致性强的理论证不出足够
   多的随机性）接 54 章不完备性，记文档线。 *)

(* 冒烟 *)
Compute (Wout 21 40, Wout 14 40).
Compute (map outputOf (seq 0 24)).
