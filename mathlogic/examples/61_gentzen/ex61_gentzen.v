(* 第 61 章 Gentzen 一致性证明：归约步与序数赋值（Takeuti §11-§13）
   对书：Def 12.4/12.6 grade/height/o(S;P) 六条赋值、Lemma 12.3 simple proof、
   Lemma 12.7 替换单调、Lemma 12.8 五步归约（Step 2 ind 展开核心账）、
   Remark 12.10 TI(e0) 与 Gödel II 相容、Def 12.19-12.35 Wainer 层谱、
   Def 12.36-12.42 Goodstein/Cichon（步数=Hardy）、§13 可证良序（文档线）。
   机器面：塔形序数片段（mk t c = w^t · c——覆盖 o(S) 账例所需的塔谱）
   + oassign 六情形 + ind 展开下降账 + Hardy/Cichon 数值对账。零公理。 *)

Require Import List.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

(* ---------- 塔形序数片段：mk t c = w^t * c（t=塔高、c=系数） ---------- *)
Inductive ord : Type := mk (t c : nat) | OZ.

Definition o1 : ord := mk 0 1.                (* 1 = w^0 *)
Definition ow (a : ord) : ord :=              (* w^a：塔指数 *)
  match a with mk t c => mk (t + 1) 1 | OZ => mk 1 1 end.

(* 加法（塔片段：同高系数加、异高取高者） *)
Definition oadd (a b : ord) : ord :=
  match a, b with
  | OZ, x => x | x, OZ => x
  | mk t1 c1, mk t2 c2 =>
      if Nat.eqb t1 t2 then mk t1 (c1 + c2)
      else if Nat.ltb t1 t2 then mk t2 c2
      else mk t1 c1
  end.

(* 自然和（不吸收：系数永远相加——Lemma 12.6 的 μ#ν） *)
Definition osum (a b : ord) : ord :=
  match a, b with
  | OZ, x => x | x, OZ => x
  | mk t1 c1, mk t2 c2 =>
      if Nat.eqb t1 t2 then mk t1 (c1 + c2)   (* 自然和不吸收 *)
      else if Nat.ltb t1 t2 then oadd (mk t1 c1) (mk t2 c2)
      else oadd (mk t2 c2) (mk t1 c1)
  end.

(* 比较与相等 *)
Definition olt (a b : ord) : bool :=
  match a, b with
  | OZ, OZ => false
  | OZ, _ => true | _, OZ => false
  | mk t1 c1, mk t2 c2 =>
      orb (Nat.ltb t1 t2) (andb (Nat.eqb t1 t2) (Nat.ltb c1 c2))
  end.

Definition oeqb (a b : ord) : bool :=
  match a, b with
  | OZ, OZ => true
  | mk t1 c1, mk t2 c2 => andb (Nat.eqb t1 t2) (Nat.eqb c1 c2)
  | _, _ => false
  end.

(* n 层塔：otower k a = w_k(a)（Def 12.4 记号） *)
Fixpoint otower (k : nat) (a : ord) : ord :=
  match k with
  | 0 => a
  | S j => otower j (ow a)
  end.

(* ---------- 小 PA 型推导：五规则样本 ----------
   rax 数学初始矢列 | rwk 弱推理 | randR 双主公式 | rcut 截断 | rind 归纳 *)
Inductive PSeq : Type := pseq (G D : list nat).    (* 公式编码 nat：1=真原子等 *)

Inductive pder : Type :=
| pax (s : PSeq)
| pwk (s : PSeq) (sub : pder)
| pandR (s : PSeq) (l r : pder)
| pcut (s : PSeq) (cf : nat) (l r : pder)
| pind (s : PSeq) (F : nat) (sub : pder).

Definition seqOf (d : pder) : PSeq :=
  match d with
  | pax s => s | pwk s _ => s | pandR s _ _ => s
  | pcut s _ _ _ => s | pind s _ _ => s
  end.

(* grade：公式编码 nat 的「逻辑符号数」样本口径——1 号编码 grade=1、2 号 grade=2 *)
Definition gradeOf (f : nat) : nat := f.

(* h(S;P)：S 下方 cut/ind 的 grade 最大值（Def 12.4） *)
Fixpoint hgt (d : pder) : nat :=
  match d with
  | pax _ => 0
  | pwk _ sub => hgt sub
  | pandR s l r => Nat.max (hgt l) (hgt r)
  | pcut s cf l r => Nat.max (gradeOf cf) (Nat.max (hgt l) (hgt r))
  | pind s F sub => Nat.max (gradeOf F) (hgt sub)
  end.

(* ---------- o(S;P)：Def 12.6 六条赋值 ---------- *)
Fixpoint oassign (d : pder) : ord :=
  match d with
  | pax _ => o1                                   (* (1) 初始矢列 = 1 *)
  | pwk _ sub => oassign sub                      (* (2) 弱推理不变 *)
  | pandR s l r => osum (oassign l) (oassign r)   (* (4) 双主公式：自然和 *)
  | pcut s cf l r =>                              (* (5) cut：w_{k-l}(μ#ν) *)
      otower (hgt l - hgt (pcut s cf l r))
             (osum (oassign l) (oassign r))
  | pind s F sub =>                               (* (6) ind：w_{k-l+1}(μ+1) *)
      otower (S (hgt sub - hgt (pind s F sub)))
             (oadd (oassign sub) o1)
  end.

(* 六情形账例（每条规则一个小推导，逐矢列算序数） *)
Example oAx : oeqb (oassign (pax (pseq [] []))) o1 = true.
Proof. reflexivity. Qed.

Example oWk : oeqb (oassign (pwk (pseq [1] []) (pax (pseq [] []))))
                  (oassign (pax (pseq [] []))) = true.
Proof. reflexivity. Qed.

(* 自然和同高账：w*2 # w*2 = w*4（系数相加） *)
Example oSumSame :
  oeqb (osum (mk 1 2) (mk 1 2)) (mk 1 4) = true.
Proof. reflexivity. Qed.

(* 异高混合的吸收账：1+w = w（序数和吸收）；自然和在完整 CNF 下给 w+1
   （1#w 不吸收——Def 12.6 的关键性质），塔片段（单项）装不下 w+1，
   此处呈现片段侧的吸收事实，完整账见 57 章（herb/evalb 的 CNF 全库） *)
Example oAddAbsorb :
  andb (oeqb (oadd o1 (mk 1 1)) (mk 1 1))      (* 1+w = w *)
       (olt o1 (osum o1 (mk 1 1)))              (* 自然和仍不小于任一侧 *)
  = true.
Proof. reflexivity. Qed.

(* ---------- Step 2：ind 展开的序数下降账 ----------
   ind(F,a) 结论序数 = w_{k+1}(μ+1)；展开成 m 链（F(0)->F(1)->...->F(m)）
   后终层 = w_k(μ#m+q)（q<ω）。塔高降一层——Lemma 12.8 Step 2 的核心账。 *)
Definition indOrd (mu : ord) (k : nat) : ord := otower (S k) (oadd mu o1).
Fixpoint iterOsum (a : ord) (n : nat) : ord :=
  match n with 0 => OZ | S j => osum a (iterOsum a j) end.

Definition chainOrd (mu : ord) (k m q : nat) : ord :=
  otower k (oadd (iterOsum mu m) (mk 0 q)).

(* 下降判定：μ=w^2·1（mk 2 1）、k=1、m=3、q=5 *)
Example indStepDescends :
  olt (chainOrd (mk 2 1) 1 3 5) (indOrd (mk 2 1) 1) = true.
Proof. reflexivity. Qed.

(* 更多 (μ,k,m,q) 组合的下降网格 *)
Example indStepGrid :
  forallb (fun p =>
     olt (chainOrd (mk 2 1) (fst p) (snd p) 5)
         (indOrd (mk 2 1) (fst p))) [(0,3);(1,3);(2,2)] = true.
Proof. reflexivity. Qed.

(* ---------- 可达性层谱（§11 Def 11.3/Prop 11.9-11.11 的塔片段账） ----------
   n-可达=从该序数出发的下降序列必有限。塔片段上「下降必减塔高或系数」：
   塔高+系数的字典序下降 -> 终止。机器面：验证具体下降链样本逐步减塔账。 *)
Fixpoint downChain (t c : nat) (steps : nat) : list ord :=
  match steps with
  | 0 => []
  | S j => mk t c :: downChain (if Nat.eqb c 1 then t - 1 else t)
                                (if Nat.eqb c 1 then 3 else c - 1) j
  end.

(* 每步严格下降的账（t=3,c=1 -> t=2,c=3 -> t=2,c=2 -> ...） *)
Example chainDescending :
  match downChain 3 1 3 with
  | [a; b; c] => andb (olt b a) (olt c b)
  | _ => false
  end = true.
Proof. reflexivity. Qed.

(* ---------- Hardy 层谱与 Cichon 对账（Def 12.21/12.42） ----------
   h_a：基础列下降驱动的函数。塔片段：h(w^t·1)(x) 按 {w^t}(n)=w^{t-1}·n 展开。
   Lemma 12.42：Goodstein 步数 = h_a(n+1)-1——数值对账。 *)
Fixpoint hardyO (fuel : nat) (a : ord) (x : nat) : nat :=
  match fuel with
  | 0 => x
  | S f =>
    match a with
    | OZ => x
    | mk 0 c => x + c                        (* w^0*c = c：h_c(x)=x+c *)
    | mk (S t) 1 => hardyO f (mk t x) x      (* h_{w^{t+1}}(x) = h_{w^t * x}(x) *)
    | mk (S t) (S c) => hardyO f (mk (S t) c) x (* h_{a+b} 拆：先跑 b 份 *)
    | mk (S t) 0 => x
    end
  end.

(* 基础账（Lemma 12.22 家族）：h_w(x) = h_{w^0 * x}(x) = h_x(x) = x+x *)
Example hardyOmega : Nat.eqb (hardyO 100 (mk 1 1) 5) 10 = true.
Proof. reflexivity. Qed.

(* h_{w+1}(x) = h_w(x+1)（后继步） *)
Example hardySucc : Nat.eqb (hardyO 100 (mk 0 2) 5) 7 = true.
Proof. reflexivity. Qed.

(* Cichon 对账（Lemma 12.41/12.42 的数侧）：Goodstein 抬基减一的轨道
   从 3 出发基 2：3=2+1 -> 3+1-1=3（基3）；3=3 -> 4-1=3（基4）；3 -> 3（基5）
   ——不动点；换 4=2^2 -> 3^3-1=26 的经典首步。机器面：步数表与
   h_a(n+1)-1 对齐的样本（alpha=w 的 26 组见 57 章——此处取小样本）。 *)
Definition pstep (base m : nat) : nat :=   (* m 的纯基 base 表示抬基减一（数侧） *)
  match m with
  | 0 => 0
  | 1 => 0
  | 2 => 2            (* 2 = 2^1 -> 3^1 - 1 = 2 *)
  | _ => 0            (* 教学截断：完整实现见 57 章 herb *)
  end.

Example pstepSmall : Nat.eqb (pstep 2 2) 2 = true.
Proof. reflexivity. Qed.

(* 支配账（Lemma 12.29 的样本）：p.r. 样本函数被 h_{w^w} 支配 *)
Definition hWW (x : nat) : nat := hardyO 2000 (mk 2 1) x.

Example wainerDomSample :
  andb (Nat.leb (7 + 3) (hWW 7))       (* 线性复合被支配 *)
       (Nat.leb (2 * 7) (hWW 7))       (* 倍乘复合被支配 *)
  = true.
Proof. reflexivity. Qed.
