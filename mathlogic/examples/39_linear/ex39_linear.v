(* ex39_linear.v —— 线性逻辑的自然演绎与范畴语义（de Paiva 篇 +
   Zimmermann 篇的 ILL 应用面，书 ch9/ch11）
   机器件：ILL {⊗,−∘,∧(加性&),!} 的**资源纪律证明搜索器**——
   (1) 语境=公式多重集；每条规则的多重集算术就是线性约束：
       ⊗I 分裂、⊗E 展开两假设、−∘I 恰耗一束、−∘E 分裂、
       &I **同一语境用两次**（加性！）、!I 全 banged 提升、
       !E 三口：弱化/收缩(预算)/降 bang；
   (2) 分裂枚举=语境位掩码（|ctx|≤5）；
   (3) 电池（全为多重集算术的直接结论）：
       - 可导：A⊢A、A,B⊢A⊗B、A⊗B⊢B⊗A（交换）、A−∘B,A⊢B、
         !A⊢A⊗A（收缩+降 bang）、A⊢A∧A（**加性复制——与 ⊗ 的
         线性复制对照**！）、A∧B⊢A、!A⊢!A；
       - 不可导（机器反例）：A⊬A⊗A（无线性复制）、A,B⊬A−∘B
         （**资源不能闲置**——A 必须被用掉）、A⊬B−∘A（直觉逻辑
         的 K 公理在线性世界失效）；
   (4) 范畴语义阶梯（对称幺半闭→*-自守→线性范畴(Lafont)→Seely）
       与「方程=推导等式」的对应、Zimmermann 对 ILL 的严格局部合流
       ——文档线（de Paiva 的裁决：线性范畴语法↔语义最紧）。
   零公理。坑位速记见 docs/39-linear.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

Inductive lf : Type :=
| la (n : nat)
| ltens (a b : lf)        (* A ⊗ B *)
| llolli (a b : lf)       (* A −∘ B *)
| lwith (a b : lf)        (* A & B（加性合取） *)
| lbang (a : lf).         (* ! A *)

Fixpoint lfEq (a b : lf) : bool :=
  match a, b with
  | la n, la m => Nat.eqb n m
  | ltens x1 y1, ltens x2 y2 => andb (lfEq x1 x2) (lfEq y1 y2)
  | llolli x1 y1, llolli x2 y2 => andb (lfEq x1 x2) (lfEq y1 y2)
  | lwith x1 y1, lwith x2 y2 => andb (lfEq x1 x2) (lfEq y1 y2)
  | lbang x, lbang y => lfEq x y
  | _, _ => false
  end.

Definition isBang (a : lf) : bool :=
  match a with lbang _ => true | _ => false end.

(* ---------- 多重集运算 ---------- *)

Fixpoint rmv1 (a : lf) (G : list lf) : list lf :=
  match G with
  | [] => []
  | x :: t => if lfEq x a then t else x :: rmv1 a t
  end.

Fixpoint filteri (G : list lf) (i mask : nat) : list lf :=
  match G with
  | [] => []
  | x :: t =>
      if Nat.testbit mask i
      then x :: filteri t (S i) mask
      else filteri t (S i) mask
  end.

Fixpoint filteriDiff (G : list lf) (i mask : nat) : list lf :=
  match G with
  | [] => []
  | x :: t =>
      if Nat.testbit mask i
      then filteriDiff t (S i) mask
      else x :: filteriDiff t (S i) mask
  end.

Definition subOf (mask : nat) (G : list lf) : list lf := filteri G 0 mask.
Definition diffMask (mask : nat) (G : list lf) : list lf :=
  filteriDiff G 0 mask.

Definition allMasks (n : nat) : list nat := seq 0 (2 ^ n).

Definition lengthG (G : list lf) : nat := length G.

(* ---------- 证明搜索器 ---------- *)

Definition identity (G : list lf) (c : lf) : bool :=
  (* 公理：语境恰为单目标——多重集相等即线性恒等 *)
  match G with
  | [x] => lfEq x c
  | _ => false
  end.

Fixpoint der (fuel budget : nat) (G : list lf) (c : lf)
              {struct fuel} : bool :=
  match fuel with
  | 0 => false
  | S k =>
      orb (identity G c)
          (orb (rightRules k budget G c)
               (leftRules k budget G c))
  end
with rightRules (fuel budget : nat) (G : list lf) (c : lf)
                {struct fuel} : bool :=
  match fuel with
  | 0 => false
  | S k =>
      match c with
      | ltens a b =>
          (* ⊗I：分裂语境（位掩码枚举全部 2^n 种） *)
          existsb (fun mask =>
            andb (der k budget (subOf mask G) a)
                 (der k budget (diffMask mask G) b))
                  (allMasks (lengthG G))
      | llolli a b =>
          (* −∘I：恰耗一束 a *)
          der k budget (a :: G) b
      | lwith a b =>
          (* &I：**同一语境用两次**（加性复制） *)
          andb (der k budget G a) (der k budget G b)
      | lbang a =>
          (* !I：提升——语境全 banged *)
          andb (forallb isBang G) (der k budget G a)
      | _ => false
      end
  end
with leftRules (fuel budget : nat) (G : list lf) (c : lf)
               {struct fuel} : bool :=
  match fuel with
  | 0 => false
  | S k =>
      (* 对语境中每个复合式尝试左规则 *)
      existsb (fun x =>
        match x with
        | ltens a b =>
            der k budget (a :: b :: rmv1 x G) c
        | llolli a b =>
            (* −∘E：分裂余语境，一半造 a、一半带 b 续推 *)
            let rest := rmv1 x G in
            existsb (fun mask =>
              andb (der k budget (subOf mask rest) a)
                   (der k budget (b :: diffMask mask rest) c))
                    (allMasks (lengthG rest))
        | lwith a b =>
            (* &E：加性投影——只取一支，另一支**丢弃不计账** *)
            orb (der k budget (a :: rmv1 x G) c)
                (der k budget (b :: rmv1 x G) c)
        | lbang a =>
            if budget =? 0 then false
            else orb (der k budget (a :: rmv1 x G) c)      (* 降 bang *)
                 (orb (der k (budget - 1) (x :: x :: rmv1 x G) c)  (* 收缩 *)
                      (der k budget (rmv1 x G) c))           (* 弱化 *)
        | _ => false
        end) G
  end.

Definition derOK (G : list lf) (c : lf) : bool := der 14 2 G c.

(* ---------- 断言电池 ---------- *)

Notation A := (la 0).
Notation B := (la 1).

(* 电一：可导组 *)
Example der_id : derOK [A] A = true.
Proof. vm_compute. reflexivity. Qed.

Example der_tensor_intro : derOK [A; B] (ltens A B) = true.
Proof. vm_compute. reflexivity. Qed.

Example der_swap : derOK [ltens A B] (ltens B A) = true.
Proof. vm_compute. reflexivity. Qed.

Example der_lolli_elim : derOK [llolli A B; A] B = true.
Proof. vm_compute. reflexivity. Qed.

Example der_bang_dup : derOK [lbang A] (ltens A A) = true.
Proof. vm_compute. reflexivity. Qed.

(* 加性复制：A ⊢ A & A——**同一语境用两次**是 & 的语义，
   与 ⊗ 的「一份资源劈两半」对照 *)
Example der_with_dup : derOK [A] (lwith A A) = true.
Proof. vm_compute. reflexivity. Qed.

Example der_with_proj : derOK [lwith A B] A = true.
Proof. vm_compute. reflexivity. Qed.

Example der_promote : derOK [lbang A] (lbang A) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：不可导组——线性纪律的机器反例 *)
Example nder_tensor_dup : derOK [A] (ltens A A) = false.
Proof. vm_compute. reflexivity. Qed.

(* A,B ⊬ A−∘B：资源不能闲置——A 必须被消耗，但 B 已在目标处
   「白拿」，没有任何规则能丢弃 A（弱化要 !） *)
Example nder_idle_resource : derOK [A; B] (llolli A B) = false.
Proof. vm_compute. reflexivity. Qed.

(* A ⊬ B−∘A：直觉逻辑的 K 公理（φ→ψ→φ）线性失效——B 在
   A−∘B−? 消耗路径上无处安放 *)
Example nder_k : derOK [A] (llolli B A) = false.
Proof. vm_compute. reflexivity. Qed.

(* 对照：!A ⊢ !B−∘!A 成立（提升要求语境全 banged——可丢弃的
   资源须先「存进」!，B 也以 !B 的身份进场） *)
Example der_bang_k : derOK [lbang A] (llolli (lbang B) (lbang A)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (derOK [A;B] (llolli A B), derOK [lbang A] (ltens A A)).
