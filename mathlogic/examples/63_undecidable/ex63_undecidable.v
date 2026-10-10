(* ex63_undecidable.v —— 通用性与不可判定性（Marker ch10）
   机器件：程序表编号的机器宇宙（真实 Gödel 编码=cp 链在 unary
   表示下随程序长度指数爆炸——机器宇宙采用「程序表索引」这一
   合法的有限编号片段，完整编码定理记文档线）；通用机 urun
   （「演算作为数据」的化身）；停机集的有限阶段 K_s；停机对角
   现场（两个全「判定器」各自翻车）；Rice 影子（语法不同、语义
   相同的两程序不可分）；s-m-n 影子（参数特化+逐点对账）。
   Kleene 递归定理按书 Th 10.12 的装配讲清，记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 0. RM（60 章同款五指令） ---------- *)

Inductive inst : Type :=
| radd (r a : nat)
| rdel (r a : nat)
| rife (r l1 l2 : nat)
| rprint
| rhalt.

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

(* 停机=抵达 rhalt（含越界默认 rhalt）——「pc 不动」≠停机：
   自环跳转 rife r k k 的 pc 恒定但程序在转 *)
Definition halted (p : prog) (c : cfg) : bool :=
  match nth (pc c) p rhalt with rhalt => true | _ => false end.

Definition step (p : prog) (c : cfg) : cfg :=
  match nth (pc c) p rhalt with
  | radd r a => mkc (S (pc c)) (setn (regs c) r (nthd 0 (regs c) r + a)) (out c)
  | rdel r a => mkc (S (pc c)) (setn (regs c) r (nthd 0 (regs c) r - a)) (out c)
  | rife r l1 l2 =>
      if Nat.eqb (nthd 0 (regs c) r) 0
      then mkc l1 (regs c) (out c)
      else mkc l2 (regs c) (out c)
  | rprint => mkc (S (pc c)) (regs c) (out c ++ [nthd 0 (regs c) 0])
  | rhalt => c
  end.

Fixpoint run (p : prog) (c : cfg) (fuel : nat) : option cfg :=
  match fuel with
  | O => None
  | S fuel' =>
      if halted p c then Some c else run p (step p c) fuel'
  end.

(* ---------- 1. 程序表宇宙：编号=表位置 ---------- *)

Definition U : list prog :=
  [ [radd 0 1; rhalt]                    (* 0: 恒等+1 *)
  ; [radd 0 2; rhalt]                    (* 1: +2 *)
  ; [radd 0 0; rhalt]                    (* 2: 恒等 Pid1 *)
  ; [radd 0 1; rdel 0 1; rhalt]          (* 3: 恒等 Pid2（语法不同） *)
  ; [radd 0 1; rife 0 0 1]               (* 4: 自转不停 Ploop *)
  ; [rhalt]                              (* 5: 立即停 *)
  ; [radd 0 3; radd 0 3; rhalt]          (* 6: +6 specF3 *)
  ; [rdel 0 1; rife 0 5 0]               (* 7: x=0 则停否则自减自转 *)
  ; [rife 1 9 9]                         (* 8: 跳自身=自转 *)
  ; [rprint; rhalt]                      (* 9: 打印 R0 后停 *)
  ; [radd 0 1; radd 0 1; radd 0 1; rhalt] (* 10: +3 *)
  ; [radd 1 1; rhalt]                    (* 11: 动 R1 *)
  ; [rdel 0 1; rhalt]                    (* 12: −1 *)
  ; [rife 0 14 14]                       (* 13: R0=0 跳自身（停不下来） *)
  ; [radd 0 0; rprint; rhalt]            (* 14: 打印后停 *)
  ; [radd 0 5; rhalt]                    (* 15: +5 *)
  ; [rdel 0 5; rhalt]                    (* 16: −5 截断 *)
  ; [radd 0 1; radd 0 1; rhalt]          (* 17: +2（与 1 号同语义） *)
  ; [rife 0 19 20; rhalt]                (* 18: R0=0 跳 19=停，否则 20 *)
  ; [rhalt]                              (* 19: 停 *)
  ; [radd 0 1; rdel 0 2; rhalt]          (* 20: x−1（截断） *)
  ; [rprint; rprint; rhalt]              (* 21: 打印两次 *)
  ; [radd 0 9; rhalt]                    (* 22: +9 *)
  ; [rife 1 5 5]                         (* 23: R1=0 跳 5=停 *)
  ].

Definition decP (e : nat) : prog := nth e U [rhalt].

(* ---------- 2. 通用机 ---------- *)

Definition urun (e : nat) (x : nat) (fuel : nat) : option cfg :=
  run (decP e) (mkc 0 [x;0;0] []) fuel.

(* 通用机=直接解释（表即数据：编号进、指令表出） *)
Example urun_agrees :
  forallb (fun x =>
    match urun 0 x 30, run (nth 0 U [rhalt]) (mkc 0 [x;0;0] []) 30 with
    | Some c1, Some c2 => Nat.eqb (nthd 0 (regs c1) 0) (nthd 0 (regs c2) 0)
    | None, None => true
    | _, _ => false
    end) (seq 0 10) = true.
Proof. reflexivity. Qed.

(* 停机集的有限阶段：K_s = {e < 24 : urun e e s 停} *)
Definition Kstage (s : nat) : list nat :=
  filter (fun e => match urun e e s with Some _ => true | None => false end)
    (seq 0 24).

Compute (Kstage 30).   (* 账本：见 docs/63-undecidable.md §三 *)

(* K 的对角元素：e=4（Ploop）对自身不停 *)
Example k_diag_loop :
  forallb (fun s => match urun 4 4 s with Some _ => false | None => true end)
    (seq 0 60) = true.
Proof. reflexivity. Qed.

(* K 单调：燃料加倍的阶段只会更大 *)
Example k_monotone :
  forallb (fun e => implb (match urun e e 20 with Some _ => true | None => false end)
                        (match urun e e 40 with Some _ => true | None => false end))
    (seq 0 24) = true.
Proof. reflexivity. Qed.

(* ---------- 3. 停机对角现场 ---------- *)

(* 「声称全部停机」h≡true：d=4 号自转——h 在 (4,4) 翻车 *)
Example diag_true_diverges :
  forallb (fun s => match urun 4 7 s with Some _ => false | None => true end)
    (seq 0 60) = true.
Proof. reflexivity. Qed.

(* 「声称全不停」h≡false：d=5 号立即停——h 在 (5,5) 翻车 *)
Example diag_false_halts :
  match urun 5 5 10 with Some _ => true | None => false end = true.
Proof. reflexivity. Qed.
(* 一般定理（没有全可计算 h 判停机）由这两个现场起手做归纳：
   任何候选 h 的对角程序 D_h :=「h(e,e)=1 则转，否则停」的编码
   d 使 h(d,d) 两头错——装配细节记文档线。 *)

(* ---------- 4. Rice 影子 ---------- *)

(* 2 号与 3 号：恒等的两种写法——语法不同、语义相同 *)
Example rice_same_behavior :
  forallb (fun x =>
    match urun 2 x 30, urun 3 x 30 with
    | Some c1, Some c2 => Nat.eqb (nthd 0 (regs c1) 0) (nthd 0 (regs c2) 0)
    | None, None => true
    | _, _ => false
    end) (seq 0 12) = true.
Proof. reflexivity. Qed.

(* 1 号与 17 号：+2 的两种写法——同样不可分 *)
Example rice_same_behavior2 :
  forallb (fun x =>
    match urun 1 x 30, urun 17 x 30 with
    | Some c1, Some c2 => Nat.eqb (nthd 0 (regs c1) 0) (nthd 0 (regs c2) 0)
    | None, None => true
    | _, _ => false
    end) (seq 0 12) = true.
Proof. reflexivity. Qed.
(* 行为谓词（index set）只看语义：同语义的两码必须同答。Rice
   定理（可计算 index set 只有 ∅/ℕ）的 s-m-n 对角装配记文档线。 *)

(* ---------- 5. s-m-n 影子：参数特化 ---------- *)

(* F(x,y) = 2x+y；特化 x=3 得 +6 程序（6 号） *)
Definition Fspec (x y : nat) : nat := 2 * x + y.

Example smn_shadow :
  forallb (fun y =>
    match urun 6 y 30 with
    | Some c => Nat.eqb (nthd 0 (regs c) 0) (Fspec 3 y)
    | None => false
    end) (seq 0 12) = true.
Proof. reflexivity. Qed.
(* 参数化引理 s11 的数值面：特化程序与原函数逐点一致；一般构造
   （从 F 的码编译出 x-特化程序码的全可计算函数）与递归定理
   （φ_e = φ_{f(e)} 的不动点见证：h(w) := U(f(U(w,w)),·) 两段装配）
   见 docs/63-undecidable.md §五——机器面到此为界（诚实记账）。 *)

(* 冒烟 *)
Compute (map (fun e => match urun e 0 40 with
                       | Some c => nthd 0 (regs c) 0 | None => 999
                       end) (seq 0 24)).
