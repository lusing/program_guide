(* ex87_alglogic.v —— 代数逻辑：后承演算与德摩根代数（马明辉 7 章）
   把「后承」当原始：无「有效公式」概念的逻辑（格/分配格/德摩根代数）
   自己长出矢列演算（L/BL/DL/GDL/DM/GDM，定义 7.8/7.11-7.15）。
   机器件：五点菱形 M3 上分配不等式的分方向账（≤ 方向全格有效、
   ≥ 方向 M3 反例——推论 7.4 的语义侧）；三元 Kleene 链 DM3 上
   DM1-3+DN 等式账+排中律失败现场（德摩根/Boole 分界）；权重 w
   与 GDM 可判定性（定理 7.15）降权样本。
   L/GDL 推导检查器受书规则图形 OCR 限制〔⚠〕记文档线。 *)

From Stdlib Require Import Bool Arith List.
Import ListNotations.

Inductive term : Type :=
| tv (n : nat)
| tand (a b : term)
| tor (a b : term)
| tneg (a : term).

Fixpoint teqb (a b : term) : bool :=
  match a, b with
  | tv m, tv n => Nat.eqb m n
  | tand a1 a2, tand b1 b2 => andb (teqb a1 b1) (teqb a2 b2)
  | tor a1 a2, tor b1 b2 => andb (teqb a1 b1) (teqb a2 b2)
  | tneg a1, tneg b1 => teqb a1 b1
  | _, _ => false
  end.

(* ============ 一、五点菱形 M3：格序的分方向账 ============ *)

(* 后承 α⊢β 读作 ≤（定义 7.6：M⊨α⊢β ⟺ θ(α)≤θ(β)）。
   M3={0..4}：0 底、4 顶、1,2,3 三个互不可比中点——最小非分配格。
   「分配律不可推导」（推论 7.4）的方向拆解：
   ≤ 方向 (p∧q)∨(p∧r) ≤ p∧(q∨r)：全格有效（对偶半分配，命题 7.4(7)）；
   ≥ 方向 p∧(q∨r) ≤ (p∧q)∨(p∧r)：M3 反例（p,q,r=三个中点时
   左=中点、右=底）——格演算推不出的正是这一侧。 *)
Definition m3met (x y : nat) : nat :=
  if Nat.eqb x 0 then 0 else
  if Nat.eqb y 0 then 0 else
  if Nat.eqb x 4 then y else
  if Nat.eqb y 4 then x else
  if Nat.eqb x y then x else 0.

Definition m3jn (x y : nat) : nat :=
  if Nat.eqb x 4 then 4 else
  if Nat.eqb y 4 then 4 else
  if Nat.eqb x y then x else
  if Nat.eqb x 0 then y else
  if Nat.eqb y 0 then x else 4.

Fixpoint m3e (v : nat -> nat) (a : term) : nat :=
  match a with
  | tv n => match v n with 0 => 0 | 1 => 1 | 2 => 2 | 3 => 3 | _ => 4 end
  | tand x y => m3met (m3e v x) (m3e v y)
  | tor x y => m3jn (m3e v x) (m3e v y)
  | tneg x => m3e v x        (* M3 无 ~：本节只用 ∧∨ 片段 *)
  end.

Definition le3 (x y : nat) : bool :=
  Nat.eqb (m3jn x y) y.      (* x≤y ⟺ join(x,y)=y *)

Definition allA3 (f : (nat -> nat) -> bool) : bool :=
  forallb (fun a =>
    forallb (fun b =>
      forallb (fun c =>
        f (fun n => match n with 0 => a | 1 => b | _ => c end))
        [0;1;2;3;4]) [0;1;2;3;4]) [0;1;2;3;4].

(* ≤ 方向：全 M3 赋值有效（125 组全枚举） *)
Example semiDistr_holds :
  allA3 (fun v =>
    le3 (m3e v (tor (tand (tv 0) (tv 1)) (tand (tv 0) (tv 2))))
        (m3e v (tand (tv 0) (tor (tv 1) (tv 2))))) = true.
Proof. reflexivity. Qed.

(* ≥ 方向：p=1,q=2,r=3 时 左=1（中点）、右=0（底）——反例现场 *)
Example distr_fails :
  le3 (m3e (fun n => match n with 0 => 1 | 1 => 2 | _ => 3 end)
           (tand (tv 0) (tor (tv 1) (tv 2))))
      (m3e (fun n => match n with 0 => 1 | 1 => 2 | _ => 3 end)
           (tor (tand (tv 0) (tv 1)) (tand (tv 0) (tv 2))))
  = false.
Proof. reflexivity. Qed.
(* 教学点：不可推导性的证据在语义侧（一个反例足矣），可推导性的
   证据在句法侧（GDL 推导，书例 7.2-7.3）——L/GDL 推导检查器受
   规则图形 OCR 限制〔⚠〕记文档线；两侧对账由定理 7.2（L 完全）
   兜底。 *)

(* ============ 二、权重 w 与可判定性（定理 7.15） ============ *)

Fixpoint w (a : term) : nat :=
  match a with
  | tv _ => 0
  | tand x y | tor x y => S (w x + w y)
  | tneg x => S (w x)
  end.

Example weight_sample :
  andb (Nat.ltb (w (tv 0) + w (tneg (tv 1)))
                (w (tneg (tand (tv 0) (tneg (tv 1))))))
       (Nat.ltb (w (tv 0)) (w (tand (tv 0) (tv 1))))
  = true.
Proof. reflexivity. Qed.

(* ============ 三、三元 Kleene 链 DM3：德摩根代数的标准模型 ============ *)

(* DM3={0,1,2}（0=假,1=不定,2=真）：链 0<1<2；min/max 为 meet/join；
   ~ 交换 0↔2、固定 1——德摩根代数定义 7.13 的最小非 Boole 模型 *)
Definition m3meet (x y : nat) : nat := Nat.min x y.
Definition m3join (x y : nat) : nat := Nat.max x y.
Definition m3neg (x : nat) : nat := match x with 0 => 2 | 2 => 0 | _ => 1 end.

Fixpoint m3eval (v : nat -> nat) (a : term) : nat :=
  match a with
  | tv n => match v n with 0 => 0 | 1 => 1 | _ => 2 end
  | tand x y => m3meet (m3eval v x) (m3eval v y)
  | tor x y => m3join (m3eval v x) (m3eval v y)
  | tneg x => m3neg (m3eval v x)
  end.

Definition allAss2 (f : (nat -> nat) -> bool) : bool :=
  forallb (fun x =>
    forallb (fun y =>
      f (fun n => match n with 0 => x | 1 => y | _ => 0 end)) [0;1;2]) [0;1;2].

(* DM1：~(α∧β) = ~α∨~β——16 组赋值逐对验证 *)
Example dm1_holds :
  allAss2 (fun v =>
    Nat.eqb (m3eval v (tneg (tand (tv 0) (tv 1))))
            (m3eval v (tor (tneg (tv 0)) (tneg (tv 1))))) = true.
Proof. reflexivity. Qed.

(* DM2：~(α∨β) = ~α∧~β *)
Example dm2_holds :
  allAss2 (fun v =>
    Nat.eqb (m3eval v (tneg (tor (tv 0) (tv 1))))
            (m3eval v (tand (tneg (tv 0)) (tneg (tv 1))))) = true.
Proof. reflexivity. Qed.

(* DN：~~α = α *)
Example dn_holds :
  allAss2 (fun v =>
    Nat.eqb (m3eval v (tneg (tneg (tv 0)))) (m3eval v (tv 0))) = true.
Proof. reflexivity. Qed.

(* DM3 的 1 点：p∨~p ≠ ⊤（排中律失败——不定值的句法侧现场；
   对照 84 章 Boole 代数 p∨~p=1 恒真：德摩根与 Boole 的分界线） *)
Example lem_fails_at_n :
  Nat.eqb (m3join 1 (m3neg 1)) 2 = false.
Proof. reflexivity. Qed.

(* GDM 推导的语义抽查：~~p ⊢ p 在 DM3 全赋值下有效（≤ 读法） *)
Example dn_sequent_valid :
  allAss2 (fun v =>
    Nat.eqb (m3join (m3eval v (tneg (tneg (tv 0)))) (m3eval v (tv 0)))
            (m3eval v (tv 0))) = true.
Proof. reflexivity. Qed.

(* 账本 *)
Print Assumptions semiDistr_holds.
Print Assumptions distr_fails.
Print Assumptions dm1_holds.
Print Assumptions lem_fails_at_n.
