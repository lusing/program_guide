(* ex37 —— 时态演绎系统 L（Ben-Ari 3e ch14）
   公理六条（14.1）+ 规则：MP + Gen□ + GenX（X-推广；Ben-Ari 列为
   导出规则，语义上与 Gen□ 同样显然：定理对一切起点成立，故可整体
   后移一步——docs/37 注记）：
     Dist  □(A→B) → (□A→□B)      分配
     DistX X(A→B) → (XA→XB)      分配
     Exp   □A → (A ∧ X□A)         展开（36 章表列 □ 规则的公理化）
     Ind   □(A→XA) → (A→□A)       归纳（不变式规则的理论形态）
     Lin   XA → ¬X¬A               线性
     Prop  命题模式（构造性片段：K1/K2 + ∧ 四式 + 传递/组装——
           Ben-Ari 的「全体命题重言」取其构造性子集，推导不受影响）
   机器件：lth 深嵌入 + 旗舰 lth_sound（对一切路径解释可靠；归纳
   公理的可靠性对距离归纳）+ Ben-Ari 14.2/14.4 两条原式推导。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Inductive lform : Type :=
| lAtom : nat -> lform
| lNot  : lform -> lform
| lAnd  : lform -> lform -> lform
| lImp  : lform -> lform -> lform
| lNext : lform -> lform        (* X *)
| lBox  : lform -> lform.       (* □ *)

(* ---------- 路径语义：解释 = 状态×原子 ↦ 真值；路径 = nat ---------- *)

Definition iass := nat -> nat -> bool.

Fixpoint lsat (I : iass) (k : nat) (f : lform) : Prop :=
  match f with
  | lAtom p => I k p = true
  | lNot a => ~ lsat I k a
  | lAnd a b => lsat I k a /\ lsat I k b
  | lImp a b => lsat I k a -> lsat I k b
  | lNext a => lsat I (S k) a
  | lBox a => forall j, k <= j -> lsat I j a
  end.

(* ---------- 系统 L ---------- *)

Inductive lth : lform -> Prop :=
(* 命题模式（构造性片段） *)
| pK1 : forall a b, lth (lImp a (lImp b a))
| pK2 : forall a b c,
    lth (lImp (lImp a (lImp b c)) (lImp (lImp a b) (lImp a c)))
| pAnd1 : forall a b, lth (lImp (lAnd a b) a)
| pAnd2 : forall a b, lth (lImp (lAnd a b) b)
| pAndI : forall a b, lth (lImp a (lImp b (lAnd a b)))
| pPair : forall c a b,
    lth (lImp (lImp c a) (lImp (lImp c b) (lImp c (lAnd a b))))
| pTrans : forall a b c,
    lth (lImp (lImp a b) (lImp (lImp b c) (lImp a c)))
(* 规则 *)
| lMP : forall a b, lth (lImp a b) -> lth a -> lth b
| lGen : forall a, lth a -> lth (lBox a)
| lGenX : forall a, lth a -> lth (lNext a)
(* 时态公理 *)
| lDist  : forall a b, lth (lImp (lBox (lImp a b)) (lImp (lBox a) (lBox b)))
| lDistX : forall a b, lth (lImp (lNext (lImp a b)) (lImp (lNext a) (lNext b)))
| lExp   : forall a, lth (lImp (lBox a) (lAnd a (lNext (lBox a))))
| lInd   : forall a, lth (lImp (lBox (lImp a (lNext a))) (lImp a (lBox a)))
| lLin   : forall a, lth (lImp (lNext a) (lNot (lNext (lNot a)))).

(* ---------- 旗舰：对一切路径解释可靠 ---------- *)

Theorem lth_sound : forall f, lth f -> forall (I : iass) k, lsat I k f.
Proof.
  intros f HT.
  induction HT as
    [a b | a b c | a b | a b | a b | c a b | a b c
    |a b Hp1 IH1 Hp2 IH2
    |a Hp IH | a Hp IH
    |a b | a b | a | a | a];
  intros I k.
  - (* pK1 *) intros Ha Hb. exact Ha.
  - (* pK2 *) intros H1 H2 Ha. exact (H1 Ha (H2 Ha)).
  - (* pAnd1 *) intros [Ha _]. exact Ha.
  - (* pAnd2 *) intros [_ Hb]. exact Hb.
  - (* pAndI *) intros Ha Hb. split; assumption.
  - (* pPair *) intros H1 H2 Hc. split; [apply H1 | apply H2]; exact Hc.
  - (* pTrans *) intros Hab Hbc Ha. apply Hbc. apply Hab. exact Ha.
  - (* MP *) apply (IH1 I k). apply (IH2 I k).
  - (* Gen□：定理对一切起点成立，整体加上 j ≥ k 的量词 *)
    intros j Hjk. apply (IH I j).
  - (* GenX *) apply (IH I (S k)).
  - (* Dist *) intros Hbox Ha j Hjk.
    specialize (Hbox j Hjk). apply Hbox. apply (Ha j Hjk).
  - (* DistX *) intros Hnx Ha. simpl in Hnx. simpl in Ha.
    apply Hnx. exact Ha.
  - (* Exp *) intros Hbox. split.
    + exact (Hbox k (Nat.le_refl k)).
    + change (forall j, S k <= j -> lsat I j a).
      intros j Hj.
      apply (Hbox j (Nat.le_trans k (S k) j (Nat.le_succ_diag_r k) Hj)).
  - (* Ind：对距离 j - k 归纳 *)
    intros Hstep Ha j Hjk.
    assert (Hchain : forall d, lsat I (k + d) a).
    { induction d as [| d IHd].
      - rewrite Nat.add_0_r. exact Ha.
      - rewrite Nat.add_succ_r.
        apply (Hstep (k + d) (Nat.le_add_r k d) IHd). }
    replace j with (k + (j - k)) by lia. exact (Hchain (j - k)).
  - (* Lin *) intros Hnx Hnn. exact (Hnn Hnx).
Qed.

(* ============ Ben-Ari 14.2 / 14.4 原式推导 ============ *)

(* 定理 14.2（前向）：X(p∧q) → (Xp ∧ Xq) *)
Theorem th142_fwd : forall a b,
  lth (lImp (lNext (lAnd a b)) (lAnd (lNext a) (lNext b))).
Proof.
  intros a b.
  assert (H1' : lth (lImp (lNext (lAnd a b)) (lNext a))).
  { apply (lMP _ _ (lDistX (lAnd a b) a)). apply lGenX. apply pAnd1. }
  assert (H2' : lth (lImp (lNext (lAnd a b)) (lNext b))).
  { apply (lMP _ _ (lDistX (lAnd a b) b)). apply lGenX. apply pAnd2. }
  exact (lMP _ _ (lMP _ _ (pPair (lNext (lAnd a b)) (lNext a) (lNext b)) H1') H2').
Qed.

(* 定理 14.4（收缩）：p ∧ X□p → □p
   Ben-Ari 的证明骨架：r→Xr（展开+X 分配）→ Gen →归纳得 r→□r
   → 与 r→p 复合（□ 单调）。不变式方法的演算化身。 *)
Theorem th144_contraction : forall a,
  lth (lImp (lAnd a (lNext (lBox a))) (lBox a)).
Proof.
  intros a.
  (* (1) X□a → X(a ∧ X□a)：展开公理经 GenX + DistX *)
  assert (Hxr : lth (lImp (lNext (lBox a)) (lNext (lAnd a (lNext (lBox a)))))).
  { apply (lMP _ _ (lDistX (lBox a) (lAnd a (lNext (lBox a))))).
    apply lGenX. apply lExp. }
  (* (2) r → Xr *)
  assert (Hrr : lth (lImp (lAnd a (lNext (lBox a)))
                          (lNext (lAnd a (lNext (lBox a)))))).
  { apply (lMP _ _ (lMP _ _
           (pTrans (lAnd a (lNext (lBox a))) (lNext (lBox a))
                   (lNext (lAnd a (lNext (lBox a)))))
           (pAnd2 a (lNext (lBox a)))) Hxr). }
  (* (3) 归纳：□(r→Xr) 与 r 给出 □r *)
  assert (Hgr : lth (lBox (lImp (lAnd a (lNext (lBox a)))
                                (lNext (lAnd a (lNext (lBox a))))))).
  { apply lGen. exact Hrr. }
  assert (Hind : lth (lImp (lAnd a (lNext (lBox a)))
                           (lBox (lAnd a (lNext (lBox a)))))).
  { apply (lMP _ _ (lInd (lAnd a (lNext (lBox a))))). exact Hgr. }
  (* (4) □r → □a *)
  assert (Hbra : lth (lImp (lBox (lAnd a (lNext (lBox a)))) (lBox a))).
  { apply (lMP _ _ (lDist (lAnd a (lNext (lBox a))) a)).
    apply lGen. apply pAnd1. }
  (* (5) 组装 *)
  exact (lMP _ _ (lMP _ _
           (pTrans (lAnd a (lNext (lBox a)))
                   (lBox (lAnd a (lNext (lBox a)))) (lBox a))
           Hind) Hbra).
Qed.
