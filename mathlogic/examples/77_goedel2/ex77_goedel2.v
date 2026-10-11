(* ex77_goedel2.v —— Gödel 第二不完备与一致性扩张（Müller-Stach ch6）
   机器件：BACH↦8647201500 素数幂 Gödel 编码（书 p91 原例，二进制 N
   通道——unary nat 装不下 86 亿）；句子宇宙上的一致性扩张梯子
   （T0→T0+Con→+Con+Con 的 Gödel 句逐层逃逸账）；D1 可导性条件的
   机制账；扩张链的 soundness 影子（定理全真）。von Neumann 信史、
   Hilbert–Bernays D1-D3、Gödel–Lucas–Penrose 记文档线。 *)

From Stdlib Require Import List Arith Lia NArith.
Import ListNotations.
Open Scope N_scope.

(* ---------- 1. BACH ↦ 8647201500：素数幂 Gödel 编码 ---------- *)

(* 符号编号 A→1 … H→8（书 p91 符号表）；词（list N）[b1;…;bk] ↦
   2^{b1}·3^{b2}·5^{b3}·…（第 i 个素数的 b_i 次幂连乘） *)
Definition primes : list N := [2; 3; 5; 7; 11; 13; 17; 19].

Definition nthPrime (i : nat) : N := nth i primes 23.

Fixpoint encAt (i : nat) (l : list N) : N :=
  match l with
  | [] => 1
  | x :: t => (nthPrime i) ^ x * encAt (S i) t
  end.

Definition bachEncode (l : list N) : N := encAt 0 l.

(* B=2 A=1 C=3 H=8 ↦ 2²·3¹·5³·7⁸ = 8647201500（书原例） *)
Example bach_bach : bachEncode [2; 1; 3; 8] = 8647201500.
Proof. reflexivity. Qed.

(* 唯一分解解码：逐素数剥指数（peel 找最大 e 使 p^e | n） *)
Fixpoint peel (fuel : nat) (n p e : N) : N :=
  match fuel with
  | O => e
  | S f => if N.eqb (n mod (p * p ^ e)) 0
           then peel f n p (N.succ e)
           else e
  end.

Fixpoint decAt (fuel i : nat) (n : N) : list N :=
  match fuel with
  | O => []
  | S f =>
      if N.eqb n 1 then []
      else let p := nthPrime i in
           let e := peel 8 n p 0 in
           e :: decAt f (S i) (n / p ^ e)
  end.

Definition bachDecode (n : N) : list N := decAt 8 0 n.

Fixpoint leqb (u v : list N) : bool :=
  match u, v with
  | [], [] => true
  | x :: t, y :: t' => andb (N.eqb x y) (leqb t t')
  | _, _ => false
  end.

(* 编码-解码回环全表（8 字母宇宙样本） *)
Example bach_roundtrip_table :
  map (fun w => leqb (bachDecode (bachEncode w)) w)
      [ [1]; [8]; [1; 2; 3]; [2; 1; 3; 8];
        [8; 8; 7; 6; 5]; [4; 4; 4; 4]; [1;2;3;4;5;6;7;8] ]
  = [true; true; true; true; true; true; true].
Proof. reflexivity. Qed.
(* 与 75 章平方配对 cpe 的对照：素数幂编码靠唯一分解保证单射，
   平方配对靠二次式保证单射——两条通往 Gödel 编码的路。 *)

(* 编码件至此全部在 N 上（86 亿的二进制运算毫秒级）；下一节起
   句子宇宙回到 nat —— Open Scope nat_scope 优先于 N_scope，
   后续字面量恢复 nat 读法 *)
Open Scope nat_scope.

(* ---------- 2. 句子宇宙与 MP 规则表 ---------- *)

(* 句子编号语义（标准模型真值表）：
   0 = crash「0=1」（恒假）  1,2 = 基础真公理
   3 = Con(T0)「T0 一致」    4 = G(T0)（Gödel 句，真而 T0 不可证）
   5 = Con(T1)              6 = G(T1)
   7 = 「Con(T0)→G(T0)」    8 = 「Con(T1)→G(T1)」
   —— 7/8 是 Gödel I 重读的蕴含式（Hilbert–Bernays D 条件：
      弱理论已可证「一致 ⟹ Gödel 句」） *)
Definition TRUTH : list bool :=
  [ false; true; true; true; true; true; true; true; true ].

(* MP 实例表：(a,b,c) 意为 a=(b→c)：从 a,b 得 c *)
Definition mpTable : list (nat * (nat * nat)) :=
  [ (7, (3, 4));      (* Con(T0)→G(T0) 与 Con(T0) 得 G(T0) *)
    (8, (5, 6)) ].    (* Con(T1)→G(T1) 与 Con(T1) 得 G(T1) *)

Definition inN (x : nat) (l : list nat) : bool := existsb (Nat.eqb x) l.

Definition mpStep (seen : list nat) : list nat :=
  seen ++ filter (fun x => negb (inN x seen))
           (flat_map (fun r =>
              if andb (inN (fst r) seen) (inN (fst (snd r)) seen)
              then [snd (snd r)] else []) mpTable).

Fixpoint prov (d : nat) (ax : list nat) : list nat :=
  match d with
  | O => ax
  | S d' => mpStep (prov d' ax)
  end.

Definition provC (T : list nat) : list nat := prov 3 T.

(* ---------- 3. 一致性扩张梯子 ---------- *)

Definition T0 : list nat := [1; 2; 7; 8].    (* 基础公理 + 两条蕴含式 *)
Definition T1 : list nat := [3] ++ T0.       (* + Con(T0) *)
Definition T2 : list nat := [5; 3] ++ T0.    (* + Con(T1) + Con(T0) *)

Definition conOf (T : list nat) : bool := negb (inN 0 (provC T)).

(* 梯子账本：每级理论收编上一级的逃逸句，又造出自己的新逃逸句 *)
Example con_ladder :
  [ negb (inN 4 (provC T0))     (* G(T0) 逃出 T0 —— Gödel I *)
  ; inN 4 (provC T1)            (* T0+Con(T0) ⊢ G(T0)：蕴含式点火 *)
  ; negb (inN 6 (provC T1))     (* G(T1) 仍逃出 T1 —— Gödel II 再来 *)
  ; inN 6 (provC T2)            (* T1+Con(T1) ⊢ G(T1) *)
  ; conOf T0; conOf T1; conOf T2 ]  (* 三级全一致：加 Con 不塌 *)
  = [true; true; true; true; true; true; true].
Proof. reflexivity. Qed.

(* Con(T0) 本身逃出 T0 —— Gödel II 的直接陈述 *)
Example con_undeducible :
  negb (inN 3 (provC T0)) = true.
Proof. reflexivity. Qed.

(* ---------- 4. D1 可导性条件与 soundness 影子 ---------- *)

(* D1：φ 与 φ→ψ 都可证则 ψ 可证（可证谓词对 MP 封闭）。
   机制账：Con(T0)=3 与 7=「Con(T0)→G(T0)」都在 T1 定理集里，
   于是 G(T0)=4 自动在——闭包算子的定义即 D1 的兑现。 *)
Example d1_shadow :
  andb (andb (inN 3 (provC T1)) (inN 7 (provC T1))) (inN 4 (provC T1))
  = true.
Proof. reflexivity. Qed.

(* soundness 影子：三级理论的定理全部为真（0 假句不可证——
   这正是 Con 为真句的语义根据） *)
Example sound_shadow :
  forallb (fun i => nth i TRUTH false) (provC T2) = true.
Proof. reflexivity. Qed.

(* 冒烟 *)
Compute (provC T0, provC T1, provC T2).
Compute (bachEncode [2%N; 1%N; 3%N; 8%N]).
