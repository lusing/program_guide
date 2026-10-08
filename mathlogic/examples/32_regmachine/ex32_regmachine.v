(* ex32_regmachine.v —— 寄存器机与可计算性（EFT ch X）
   机器件：五指令 RM（LET R±a / IF □ / PRINT / HALT）解释器+配置步进；
   书例 P_0 奇偶程序逐输入对账；加法程序；停机/不停机对。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 五指令与程序 ---------- *)

Inductive inst : Type :=
| radd (r : nat) (a : nat)                          (* L LET R_r = R_r + a *)
| rdel (r : nat) (a : nat)                          (* L LET R_r = R_r - a *)
| rife (r : nat) (l1 l2 : nat)                      (* L IF R_r = □ THEN l1 ELSE l2 *)
| rprint                                           (* L PRINT *)
| rhalt.                                           (* L HALT *)

Definition prog := list inst.   (* 指令 α_i 标号 i *)

(* 字：一元字母表上的 stroke 串 = nat *)
Definition word := nat.

(* 配置：pc + 寄存器表 + 输出 *)
Record cfg : Type := mkc { pc : nat; regs : list nat; out : list word }.

Definition nthd (d : nat) (l : list nat) (i : nat) : nat :=
  match nth i l d with 0 => 0 | n => n end.

Definition setn (l : list nat) (i v : nat) : list nat :=
  firstn i l ++ [v] ++ skipn (S i) l.

(* 首字母删：R_r - a 在一元字母表 = 若首字母为 a 则删之（减 n）；
   EFT 的一般字母表在一元下退化为「减去 a 个 stroke」 *)
Definition deln (n a : nat) : nat := n - a.

(* ---------- 2. 单步 ---------- *)

Definition step (p : prog) (c : cfg) : cfg :=
  match nth (pc c) p rhalt with
  | radd r a => mkc (S (pc c))
                   (setn (regs c) r (nthd 0 (regs c) r + a)) (out c)
  | rdel r a => mkc (S (pc c))
                   (setn (regs c) r (deln (nthd 0 (regs c) r) a)) (out c)
  | rife r l1 l2 =>
      if Nat.eqb (nthd 0 (regs c) r) 0
      then mkc l1 (regs c) (out c)
      else mkc l2 (regs c) (out c)
  | rprint => mkc (S (pc c)) (regs c) (out c ++ [nthd 0 (regs c) 0])
  | rhalt => c
  end.

(* ---------- 3. 燃料运行 ---------- *)

Fixpoint run (p : prog) (c : cfg) (fuel : nat) : option cfg :=
  match fuel with
  | O => None
  | S fuel' =>
      let c' := step p c in
      if Nat.eqb (pc c') (pc c) then Some c'   (* HALT：不动 *)
      else run p c' fuel'
  end.

Definition start (n : word) : cfg := mkc 0 [n;0;0] [].

(* ---------- 4. 书例 P_0：奇偶判定 ---------- *)

(* 0 IF R0 = □ THEN 6 ELSE 1
   1 LET R0 = R0 - |
   2 IF R0 = □ THEN 5 ELSE 3
   3 LET R0 = R0 - |
   4 IF R0 = □ THEN 6 ELSE 1
   5 LET R0 = R0 + |     （输出奇数标记——这里以 R0=1 表示）
   6 HALT *)
Definition P0 : prog :=
  [ rife 0 6 1 ;
    rdel 0 1 ;
    rife 0 5 3 ;
    rdel 0 1 ;
    rife 0 6 1 ;
    radd 0 1 ;
    rhalt ].

(* P0 的正确性：输出 R0 = n mod 2 *)
Definition p0_result (n : word) : nat :=
  match run P0 (start n) (3 * n + 20) with
  | Some c => nthd 0 (regs c) 0
  | None => 999
  end.

Example p0_correct :
  map p0_result (seq 0 10) = [0;1;0;1;0;1;0;1;0;1].
Proof. reflexivity. Qed.

(* ---------- 5. 加法程序 ----------

   0 IF R1 = □ THEN 5 ELSE 1
   1 LET R1 = R1 - |
   2 LET R0 = R0 + |
   3 IF R1 = □ THEN 5 ELSE 1?? —— 直接用循环标号 0
   重写：
   0 IF R1 = □ THEN 4 ELSE 1
   1 LET R1 = R1 - |
   2 LET R0 = R0 + |
   3 IF R1 = □ THEN 4 ELSE 1   —— 应跳回 0；改：
   0 IF R1 = □ THEN 5 ELSE 1
   1 LET R1 = R1 - |
   2 LET R0 = R0 + |
   3 IF R1 = □ THEN 5 ELSE 1   （保持简单：只在 R1 非空时循环）
   实际正确版（R1 清空即停）：
   0 IF R1 = □ THEN 4 ELSE 1
   1 LET R1 = R1 - |
   2 LET R0 = R0 + |
   3 (跳回 0)  rife 1 0 0 —— 用无条件跳：IF R1=□ THEN 0 ELSE 0
   4 HALT *)
Definition Padd : prog :=
  [ rife 1 4 1 ;
    rdel 1 1 ;
    radd 0 1 ;
    rife 1 0 0 ;
    rhalt ].

Definition add_result (x y : word) : nat :=
  match run Padd (mkc 0 [x;y] []) (3 * (x + y) + 20) with
  | Some c => nthd 0 (regs c) 0
  | None => 999
  end.

Example add_correct :
  map (fun p => add_result (fst p) (snd p))
    [(0,0);(1,0);(0,1);(2,3);(3,4);(5,5)] = [0;1;1;5;7;10].
Proof. reflexivity. Qed.

(* ---------- 6. 停机与不停机 ---------- *)

(* 不停机：0 LET R0 = R0 + | ; 1 IF R0 = □ THEN 1 ELSE 0（跳回 0） *)
Definition Ploop : prog :=
  [ radd 0 1 ;
    rife 0 1 0 ].

Example loop_never_halts :
  forallb (fun n => match run Ploop (start n) 50 with
                    | Some _ => false | None => true end) (seq 0 5) = true.
Proof. reflexivity. Qed.

(* 停机对角线的思想现场（文档级）：对角程序 D := 「若 Π(P,n) 停机
   则循环 else 停」——D 作用于自身产生矛盾。机器面以 Ploop 与
   P0 的对照给出「停机/不停机」两极；一般定理（Π_halt 不可判定）
   的证明链（dove-tailing 枚举+对角）记文档级。 *)

(* 冒烟 *)
Compute (map p0_result (seq 0 8)).     (* [0;1;0;1;0;1;0;1] *)
Compute (add_result 3 4).              (* 7 *)
