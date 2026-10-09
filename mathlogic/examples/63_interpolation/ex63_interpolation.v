(* ex63_interpolation.v —— Craig 插值定理（马明辉 3.4，定理 3.10/3.11）
   Maehara 方法：对无切割推导+划分逐情形构造插值子。
   机器件：划分注记推导树 mder；Maehara 组合表 interp（γ 传递/
   γ1∨γ2/γ1∧γ2/公理四格局 常值）；三条件的语义验证（真值表全枚举
   cond1/cond2 + 变元条件 cond3）。经典版（定理 3.10）；
   直觉主义版（定理 3.11 的 γ1→γ2 跨侧组合）记文档线。 *)

From Stdlib Require Import Bool Arith List.
Import ListNotations.

Inductive fform : Type :=
| pvar (n : nat)
| fbot
| fand (a b : fform)
| forr (a b : fform)
| fimp (a b : fform).

Definition fneg (a : fform) : fform := fimp a fbot.
Definition ftop : fform := fimp fbot fbot.

Fixpoint feqb (a b : fform) : bool :=
  match a, b with
  | pvar m, pvar n => Nat.eqb m n
  | fbot, fbot => true
  | fand a1 a2, fand b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | forr a1 a2, forr b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | fimp a1 a2, fimp b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | _, _ => false
  end.

(* ============ 一、划分注记推导树 ============

   每个节点携带其矢列的四分划分 (Γ₁,Δ₁,Γ₂,Δ₂)：Γ₁⊎Γ₂=前件，
   Δ₁⊎Δ₂=后件（多重集意义）。规则名 mrule：
   - Ax：公理 α⇒α，s1=左 α 落侧（true=Γ₁），s2=右 α 落侧（true=Δ₁）
   - AndL i：(∧⇒) 取第 i 支（单前提——γ 传递）
   - AndR s：(⇒∧) 主公式落侧（true=Δ₁）
   - OrL s / OrR1 s / OrR2 s / ImpL s / ImpR s 同理
   划分随规则自上而下继承（书定理 3.10 证明的机制）。 *)

Inductive mrule : Type :=
| Ax (a : fform) (s1 s2 : bool)
| AndL (i : bool)
| AndR (s : bool)
| OrL (s : bool)
| OrR1 (s : bool) | OrR2 (s : bool)
| ImpL (s : bool)
| ImpR (s : bool).

Inductive mder : Type :=
| mnode (g1 d1 g2 d2 : list fform) (r : mrule) (ds : list mder).

(* ============ 二、Maehara 组合表（定理 3.10 逐情形） ============ *)

Fixpoint interp (d : mder) : fform :=
  match d with
  | mnode _ _ _ _ (Ax a s1 s2) _ =>
      (* 公理四格局：左 α 与右 α 各落一侧 *)
      match s1, s2 with
      | true, false => a              (* α∈Γ₁,α∈Δ₂：γ=a *)
      | true, true => fbot            (* 双落 1 侧：γ=⊥（一致性流向 2 侧） *)
      | false, false => ftop          (* 双落 2 侧：γ=⊤（可满足性流向 1 侧） *)
      | false, true => fneg a         (* α∈Γ₂,α∈Δ₁：γ=¬a *)
      end
  | mnode _ _ _ _ (AndL _) ds =>
      (* (∧⇒) 单前提：γ 传递 *)
      match ds with [d] => interp d | _ => fbot end
  | mnode _ _ _ _ (AndR s) ds =>
      match ds with
      | [d1; d2] =>
          (* (⇒∧)：主公式在 Δ₁ → γ1∨γ2；在 Δ₂ → γ1∧γ2 *)
          if s then forr (interp d1) (interp d2)
               else fand (interp d1) (interp d2)
      | _ => fbot
      end
  | mnode _ _ _ _ (OrL s) ds =>
      match ds with
      | [d1; d2] =>
          (* (∨⇒)：主公式在 Γ₁ → γ1∨γ2；在 Γ₂ → γ1∧γ2 *)
          if s then forr (interp d1) (interp d2)
               else fand (interp d1) (interp d2)
      | _ => fbot
      end
  | mnode _ _ _ _ (OrR1 _) ds =>
      match ds with [d] => interp d | _ => fbot end
  | mnode _ _ _ _ (OrR2 _) ds =>
      match ds with [d] => interp d | _ => fbot end
  | mnode _ _ _ _ (ImpR _) ds =>
      (* (⇒→) 单前提：γ 传递 *)
      match ds with [d] => interp d | _ => fbot end
  | mnode _ _ _ _ (ImpL s) ds =>
      match ds with
      | [d1; d2] =>
          (* (→⇒)：主公式在 Γ₁ → γ1∨γ2；在 Γ₂ → γ1∧γ2 *)
          if s then forr (interp d1) (interp d2)
               else fand (interp d1) (interp d2)
      | _ => fbot
      end
  end.

(* ============ 三、语义验证器（三条件） ============ *)

Definition env := nat -> bool.

Fixpoint ev (e : env) (a : fform) : bool :=
  match a with
  | pvar n => e n
  | fbot => false
  | fand x y => andb (ev e x) (ev e y)
  | forr x y => orb (ev e x) (ev e y)
  | fimp x y => implb (ev e x) (ev e y)
  end.

Definition conjL (G : list fform) : fform := fold_right fand ftop G.
Definition disjL (D : list fform) : fform := fold_right forr fbot D.

(* 真值表全枚举（变元 ≤2：p0/p1） *)
Definition taut2 (a : fform) : bool :=
  forallb (fun b0 =>
    forallb (fun b1 =>
      ev (fun n => match n with
                   | 0 => b0 | 1 => b1 | _ => false
                   end) a)
      [true; false]) [true; false].

Fixpoint varsOf (a : fform) : list nat :=
  match a with
  | pvar n => [n]
  | fbot => []
  | fand x y | forr x y | fimp x y => varsOf x ++ varsOf y
  end.

Fixpoint mem (n : nat) (l : list nat) : bool :=
  match l with
  | [] => false
  | m :: l' => orb (Nat.eqb n m) (mem n l')
  end.

Definition varsIn (l : list nat) (f : fform) : bool :=
  forallb (fun n => mem n l) (varsOf f).

Fixpoint varsL (G : list fform) : list nat :=
  match G with
  | [] => []
  | a :: G' => varsOf a ++ varsL G'
  end.

(* 三条件：①Γ₁⇒Δ₁,γ 有效；②γ,Γ₂⇒Δ₂ 有效；③var(γ)⊆交 *)
Definition cond1 (d : mder) : bool :=
  match d with
  | mnode g1 d1 _ _ _ _ =>
      taut2 (fimp (conjL g1) (disjL (d1 ++ [interp d])))
  end.
Definition cond2 (d : mder) : bool :=
  match d with
  | mnode _ _ g2 d2 _ _ =>
      taut2 (fimp (fand (interp d) (conjL g2)) (disjL d2))
  end.
Definition cond3 (d : mder) : bool :=
  match d with
  | mnode g1 d1 g2 d2 _ _ =>
      varsIn (varsL g1 ++ varsL d1) (interp d)
      && varsIn (varsL g2 ++ varsL d2) (interp d)
  end.

(* ============ 四、账例 ============ *)

Definition p0 := pvar 0.
Definition p1 := pvar 1.

(* 例 1：(p∧q)∨(¬p∧q) ⇒ q，划分：整个前件归 1 侧、后件归 2 侧。
   插值子 = q∨q——「α 与 β 只共享 q」的信息全部压进 q *)
Definition exShare : mder :=
  mnode [forr (fand p0 p1) (fand (fneg p0) p1)] [] [] [p1]
    (OrL true)
    [ mnode [fand p0 p1] [] [] [p1] (AndL true)
        [ mnode [p1] [] [] [p1] (Ax p1 true false) [] ]
    ; mnode [fand (fneg p0) p1] [] [] [p1] (AndL true)
        [ mnode [p1] [] [] [p1] (Ax p1 true false) [] ] ].

Example exShare_interp : interp exShare = forr p1 p1.
Proof. reflexivity. Qed.
Example exShare_ok :
  andb (cond1 exShare) (andb (cond2 exShare) (cond3 exShare)) = true.
Proof. reflexivity. Qed.

(* 例 2：(p∧q) ⇒ (q∧p)，划分：前件归 1 侧、后件归 2 侧。
   (⇒∧) 主公式在 Δ₂ → γ1∧γ2 = q∧p（非平凡：两边各贡献一支） *)
Definition exSwap : mder :=
  mnode [fand p0 p1] [] [] [fand p1 p0]
    (AndR false)
    [ mnode [fand p0 p1] [] [] [p1] (AndL false)
        [ mnode [p1] [] [] [p1] (Ax p1 true false) [] ]
    ; mnode [fand p0 p1] [] [] [p0] (AndL false)
        [ mnode [p0] [] [] [p0] (Ax p0 true false) [] ] ].

Example exSwap_interp : interp exSwap = fand p1 p0.
Proof. reflexivity. Qed.
Example exSwap_ok :
  andb (cond1 exSwap) (andb (cond2 exSwap) (cond3 exSwap)) = true.
Proof. reflexivity. Qed.

(* 例 3（公理格局的常值流）：p ⇒ p，划分把两份 p 都归 1 侧
   （Γ₁=[p], Δ₁=[p], Γ₂=Δ₂=∅）。γ=⊥：1 侧把「不一致性」传给 2 侧 *)
Definition exConst : mder :=
  mnode [p0] [p0] [] [] (Ax p0 true true) [].

Example exConst_interp : interp exConst = fbot.
Proof. reflexivity. Qed.
Example exConst_ok :
  andb (cond1 exConst) (andb (cond2 exConst) (cond3 exConst)) = true.
Proof. reflexivity. Qed.
(* 对偶格局（双落 2 侧）给 γ=⊤——「可满足性」从 2 侧流向 1 侧；
   落 (Γ₂,Δ₁) 给 γ=¬α。四种格局的语义流向见 docs 表。 *)

(* 推论 3.6 的机器影子：⊢HK α→β 时取划分 (α:∅);(β:∅) 即得 Craig
   插值 α→γ→β。上三例的 cond1+cond2 合起来正是这两条有效性。 *)

(* 账本 *)
Print Assumptions exShare_ok.
Print Assumptions exSwap_ok.
Print Assumptions exConst_ok.
