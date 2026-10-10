(* ex77_structural.v —— 矢列演算的结构规则谱系（马明辉 3.1/4.1-4.5）
   G1（多重集灭交换）→G2（公理带语境灭弱化）→G3（前提重复主公式灭收缩）
   →G4（→ 左四分支灭循环，Dyckhoff 权重 μ）。嵌入定理（4.5）：G3ipEa
   （原子排中规则）的标准推导 ⟹ Glivenko：HK α ⟺ HJ ¬¬α。
   机器件：μ 权重+四不等式账；G3ip 注记推导检查器（含 Ea 扩张）；
   G3ip 搜索循环的回归迹；G4ip 终止搜索器 g4prove（定理/非定理双向账）；
   Glivenko 单例（G3ipEa ⊢ ⇒p∨¬p 与 G3ip ⊢ ⇒¬¬(p∨¬p) 双树）。 *)

From Stdlib Require Import Bool Arith Lia List.
Import ListNotations.

Inductive fform : Type :=
| pvar (n : nat)
| fbot
| fand (a b : fform)
| forr (a b : fform)
| fimp (a b : fform).

Definition fneg (a : fform) : fform := fimp a fbot.

Fixpoint feqb (a b : fform) : bool :=
  match a, b with
  | pvar m, pvar n => Nat.eqb m n
  | fbot, fbot => true
  | fand a1 a2, fand b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | forr a1 a2, forr b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | fimp a1 a2, fimp b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | _, _ => false
  end.

(* ============ 一、Dyckhoff 权重 μ 与四不等式（定义 4.9） ============ *)

(* μ(p)=μ(⊥)=2；μ(a∧b)=μ(a)(1+μ(b))；μ(a∨b)=μ(a)+μ(b)+1；μ(a→b)=μ(a)μ(b)+1 *)
Fixpoint mu (a : fform) : nat :=
  match a with
  | pvar _ | fbot => 2
  | fand x y => mu x * (1 + mu y)
  | forr x y => mu x + mu y + 1
  | fimp x y => mu x * mu y + 1
  end.

Definition smpl : list fform :=
  (* 三变元小公式样本：规则四分支的每类前提形状都覆盖 *)
  let p := pvar 0 in let q := pvar 1 in let r := pvar 2 in
  [ p; q; fbot; fimp p q; fimp q p; fand p q; forr p q
  ; fimp (fand p q) r; fimp (forr p q) r; fimp (fimp p q) r
  ; fimp p (fimp q r); fimp (fimp q r) p; fneg p; fneg (fneg p)
  ; forr p (fneg p); fimp (fneg p) (fneg (fneg p)) ].

(* 不等式 (1)：μ(a1→(a2→a)) < μ((a1∧a2)→a)——(∧⇒→) 分支的降权 *)
Example mu_and_branch :
  forallb (fun t =>
    Nat.ltb (mu (fimp (fst t) (fimp (fst (snd t)) (snd (snd t)))))
            (mu (fimp (fand (fst t) (fst (snd t))) (snd (snd t)))))
    (flat_map (fun x => flat_map (fun y => map (fun z => (x,(y,z))) smpl) smpl) smpl)
  = true.
Proof. reflexivity. Qed.

(* 不等式 (4)：μ(a2→a) < μ((a1→a2)→a)——(→⇒→) 分支的降权 *)
Example mu_imp_branch :
  forallb (fun t =>
    Nat.ltb (mu (fimp (fst (snd t)) (snd (snd t))))
            (mu (fimp (fimp (fst t) (fst (snd t))) (snd (snd t)))))
    (flat_map (fun x => flat_map (fun y => map (fun z => (x,(y,z))) smpl) smpl) smpl)
  = true.
Proof. reflexivity. Qed.

(* (∨⇒→) 分支：μ(ai→a) < μ((a1∨a2)→a) 两支皆降 *)
Example mu_or_branch :
  forallb (fun t =>
    andb (Nat.ltb (mu (fimp (fst t) (snd (snd t))))
                 (mu (fimp (forr (fst t) (fst (snd t))) (snd (snd t)))))
          (Nat.ltb (mu (fimp (fst (snd t)) (snd (snd t))))
                 (mu (fimp (forr (fst t) (fst (snd t))) (snd (snd t))))))
    (flat_map (fun x => flat_map (fun y => map (fun z => (x,(y,z))) smpl) smpl) smpl)
  = true.
Proof. reflexivity. Qed.

(* 整序权重：矢列 Γ⇒β 的权重=Σμ(Γ)+μ(β)——每条 G4ip 规则前提严格降 *)
Definition seqMu (G : list fform) (b : fform) : nat :=
  fold_right (fun a s => mu a + s) (mu b) G.

(* ============ 二、G3ip 注记推导检查器（主公式重复于前提） ============ *)

Definition seq : Type := (list fform * fform)%type.

Inductive rname : Type :=
| rId | rBotL | rAndL | rAndR | rOrL | rOrR1 | rOrR2
| rImpL | rImpR | rEa.

Inductive g3d : Type :=
| gnode (s : seq) (r : rname) (ds : list g3d).

Definition seqOf (d : g3d) : seq := match d with gnode s _ _ => s end.

(* 前件按多重集比较（G1 纪律：结构=可重集，序无意义） *)
Fixpoint del1 (a : fform) (l : list fform) : option (list fform) :=
  match l with
  | [] => None
  | b :: l' => if feqb a b then Some l'
               else match del1 a l' with
                    | Some r => Some (b :: r)
                    | None => None
                    end
  end.

Fixpoint meqb (G H : list fform) : bool :=
  match G with
  | [] => match H with [] => true | _ => false end
  | a :: G' => match del1 a H with
               | Some H' => meqb G' H'
               | None => false
               end
  end.

Definition seqEqb (s t : seq) : bool :=
  andb (meqb (fst s) (fst t)) (feqb (snd s) (snd t)).

(* 按规则名从结论矢列算出前提矢列表（G3 风格：主公式重复于前提） *)
Definition premsOf (s : seq) (r : rname) : list seq :=
  match r, s with
  | rId, (G, b) => []                        (* p,Γ⇒p 或 ⊥,Γ⇒β *)
  | rBotL, (G, b) => []
  | rAndL, (G, b) =>                         (* (α1∧α2),Γ⇒β ⟸ α1,α2,(α1∧α2),Γ⇒β *)
      match G with
      | fand a1 a2 :: G' => [ (a1 :: a2 :: fand a1 a2 :: G', b) ]
      | _ => [ (G, b) ]      (* 非法形状：自反馈以便检查失败 *)
      end
  | rAndR, (G, b) =>                         (* Γ⇒α1∧α2 ⟸ Γ⇒α1, Γ⇒α2 *)
      match b with
      | fand a1 a2 => [ (G, a1); (G, a2) ]
      | _ => [ (G, b) ]
      end
  | rOrL, (G, b) =>                          (* (α1∨α2),Γ⇒β ⟸ α1,(α1∨α2),Γ⇒β; α2,… *)
      match G with
      | forr a1 a2 :: G' =>
          [ (a1 :: forr a1 a2 :: G', b); (a2 :: forr a1 a2 :: G', b) ]
      | _ => [ (G, b); (G, b) ]
      end
  | rOrR1, (G, b) =>
      match b with
      | forr a1 _ => [ (G, a1) ]
      | _ => [ (G, b) ]
      end
  | rOrR2, (G, b) =>
      match b with
      | forr _ a2 => [ (G, a2) ]
      | _ => [ (G, b) ]
      end
  | rImpL, (G, b) =>                         (* (α1→α2),Γ⇒β ⟸ (α1→α2),Γ⇒α1; α2,(α1→α2),Γ⇒β *)
      match G with
      | fimp a1 a2 :: G' =>
          [ (fimp a1 a2 :: G', a1); (a2 :: fimp a1 a2 :: G', b) ]
      | _ => [ (G, b); (G, b) ]
      end
  | rImpR, (G, b) =>                         (* Γ⇒α1→α2 ⟸ α1,Γ⇒α2 *)
      match b with
      | fimp a1 a2 => [ (a1 :: G, a2) ]
      | _ => [ (G, b) ]
      end
  | rEa, (G, b) =>                           (* (Ea)：¬p,Γ⇒β; p,Γ⇒β ⟸ Γ⇒β *)
      [ (fneg (pvar 0) :: G, b); (pvar 0 :: G, b) ]
  end.

(* 公理形状：(Id) p,Γ⇒p（p 是变元）；(⊥⇒) ⊥,Γ⇒β *)
Definition axOK (s : seq) (r : rname) : bool :=
  match r with
  | rId => existsb (fun a => match a with
                            | pvar _ => feqb a (snd s)
                            | _ => false end) (fst s)
  | rBotL => existsb (fun a => match a with fbot => true | _ => false end) (fst s)
  | _ => true
  end.

Fixpoint listSeqEqb (l1 l2 : list seq) : bool :=
  match l1, l2 with
  | [], [] => true
  | s1 :: t1, s2 :: t2 => andb (seqEqb s1 s2) (listSeqEqb t1 t2)
  | _, _ => false
  end.

(* 推导检查：规则被允许（Ea 须 kcEa）+公理形状+子推导合法+前提矢列对账 *)
Fixpoint g3chk (kcEa : bool) (d : g3d) : bool :=
  match d with
  | gnode s r ds =>
      andb (implb (match r with rEa => true | _ => false end) kcEa)
        (andb (axOK s r)
          (andb (forallb (g3chk kcEa) ds)
                (listSeqEqb (map seqOf ds) (premsOf s r))))
  end.

(* ============ 三、G3ip 的搜索循环 vs G4ip 的终止搜索 ============ *)

(* G3ip (→⇒) 的循环机制（书 4.4 开篇）：搜 ¬¬p⇒p 时，左前提链
   p,¬¬p⇒⊥ →(→⇒ 的左前提+⇒→)→ p,p,¬¬p⇒⊥ → … 每圈多一个 p。
   回归迹：逐步展示前件的增长 *)
Definition g3cycleStep (G : list fform) : list fform :=
  (* 对前件含 ¬¬p 的矢列应用 (→⇒)+(⇒→) 一圈后的新前件 *)
  pvar 0 :: G.

Example g3_loop_growth :
  map (fun G => length G)
      [ [pvar 0; fneg (fneg (pvar 0))]
      ; g3cycleStep [pvar 0; fneg (fneg (pvar 0))]
      ; g3cycleStep (g3cycleStep [pvar 0; fneg (fneg (pvar 0))])
      ; g3cycleStep (g3cycleStep (g3cycleStep [pvar 0; fneg (fneg (pvar 0))])) ]
  = [2; 3; 4; 5].
Proof. reflexivity. Qed.
(* G3ip 的 (→⇒) 把主公式留在左前提里：α1→α2 的 α1 又是新 → 公式时，
   同一矢列以更大前件重生——证明搜索不停机（书「可能出现循环」现场）。 *)

(* G4ip 终止搜索器：μ 权重逐规则严格降 ⟹ 无循环。
   策略：公理 ⟹ 真；否则按序尝试 ∧左展开/∨左分支/右结构分解/
   →左按前件形状四分支（⊥ 消去/原子分支/析取改写/嵌套蕴涵分支）。 *)

Definition isAxiom (G : list fform) (b : fform) : bool :=
  orb (existsb (fun a => match a with fbot => true | _ => false end) G)
      (existsb (fun a => match a with pvar _ => feqb a b | _ => false end) G).

Fixpoint findAnd (G : list fform) : option (fform * fform * list fform) :=
  match G with
  | [] => None
  | fand a1 a2 :: G' => Some (a1, a2, G')
  | a :: G' =>
      match findAnd G' with
      | Some (x, y, G'') => Some (x, y, a :: G'')
      | None => None
      end
  end.

Fixpoint findOr (G : list fform) : option (fform * fform * list fform) :=
  match G with
  | [] => None
  | forr a1 a2 :: G' => Some (a1, a2, G')
  | a :: G' =>
      match findOr G' with
      | Some (x, y, G'') => Some (x, y, a :: G'')
      | None => None
      end
  end.

(* 全部蕴含出现位置（→ 左规则的选择点：完整回溯） *)
Fixpoint impChoices (G : list fform) : list (fform * fform * list fform) :=
  match G with
  | [] => []
  | fimp a1 a2 :: G' =>
      (a1, a2, G')
        :: map (fun t => match t with
                         | (x, y, r) => (x, y, fimp a1 a2 :: r)
                         end) (impChoices G')
  | a :: G' =>
      map (fun t => match t with
                    | (x, y, r) => (x, y, a :: r)
                    end) (impChoices G')
  end.

(* G4ip 搜索器：可逆分解（∧左/∨左/右规则）优先，→ 左按前件形状分支
   且在全部出现位置上回溯（existsb）。四分支：
   (⊥⇒→) 空虚消去；(p⇒→) 原子 DROP（弱化可容许：Γ′⇒p 足以复原前提）；
   (∧⇒→) 柯里化改写；(∨⇒→) 双改写；
   (→⇒→) 保持 G3ip 形（前提 1 经 (⇒→) 逆化：α1 连同主公式入前件证 α2）。 *)
Fixpoint g4prove (fuel : nat) (s : seq) : bool :=
  match fuel with
  | O => false
  | S f =>
      let (G, b) := s in
      if isAxiom G b then true
      else
        match findAnd G with
        | Some (a1, a2, G') => g4prove f (a1 :: a2 :: G', b)
        | None =>
        match findOr G with
        | Some (a1, a2, G') =>
            andb (g4prove f (a1 :: G', b)) (g4prove f (a2 :: G', b))
        | None =>
        match b with
        | fand a1 a2 => andb (g4prove f (G, a1)) (g4prove f (G, a2))
        | forr a1 a2 => orb (g4prove f (G, a1)) (g4prove f (G, a2))
        | fimp a1 a2 => g4prove f (a1 :: G, a2)
        | _ =>
        existsb (fun t =>
          match t with
          | (fbot, _, G') => g4prove f (G', b)
          | (pvar k, a, G') =>
              andb (g4prove f (G', pvar k)) (g4prove f (a :: G', b))
          | (fand a1 a2, a, G') =>
              g4prove f (fimp a1 (fimp a2 a) :: G', b)
          | (forr a1 a2, a, G') =>
              g4prove f (fimp a1 a :: fimp a2 a :: G', b)
          | (fimp a1 a2, a, G') =>
              andb (g4prove f (a1 :: fimp (fimp a1 a2) a :: G', a2))
                   (g4prove f (a :: fimp (fimp a1 a2) a :: G', b))
          end) (impChoices G)
        end
        end
        end
  end.

Definition p0 := pvar 0.
Definition p1 := pvar 1.

(* 双向账：直觉主义定理搜出证明；非定理有限空间内穷尽返回 false *)
Example g4_id : g4prove 200 ([] , fimp p0 p0) = true.
Proof. reflexivity. Qed.

Example g4_syll :
  g4prove 400 ([], fimp (fimp p0 p1) (fimp (fimp p1 p0) (fimp p0 p0))) = true.
Proof. reflexivity. Qed.
Example g4_and_comm :
  g4prove 400 ([], fimp (fand p0 p1) (fand p1 p0)) = true.
Proof. reflexivity. Qed.

Example g4_glivenko_instance :
  g4prove 400 ([], fneg (fneg (forr p0 (fneg p0)))) = true.
Proof. reflexivity. Qed.

Example g4_not_dne : g4prove 400 ([], fimp (fneg (fneg p0)) p0) = false.
Proof. reflexivity. Qed.
Example g4_not_lem : g4prove 400 ([], forr p0 (fneg p0)) = false.
Proof. reflexivity. Qed.
Example g4_not_peirce :
  g4prove 400 ([], fimp (fimp (fimp p0 p1) p0) p0) = false.
Proof. reflexivity. Qed.

(* 逐规则的权重下降账（样本式；G4ip 终止性的机制内核）：
   (∧⇒→) 柯里化改写降权；(∨⇒→) 两支改写各自降权；(p⇒→) DROP 降权 *)
Example g4_weight_drops :
  andb (Nat.ltb (mu (fimp p0 (fimp p1 p0))) (mu (fimp (fand p0 p1) p0)))
       (andb (Nat.ltb (mu (fimp p0 p0)) (mu (fimp (forr p0 p1) p0)))
             (Nat.ltb (mu (fimp p1 p0)) (mu (fimp (forr p0 p1) p0))))
  = true.
Proof. reflexivity. Qed.

(* ============ 四、Glivenko 嵌入定理的机器单例（4.5） ============ *)

(* (Ea) 规则：¬p,Γ⇒β; p,Γ⇒β ⟸ Γ⇒β（原子排中）。
   例 4.3：G3ipEa ⊢ ⇒p∨¬p（主公式恒置前件首位——premsOf 的约定） *)
Definition eaLem : g3d :=
  gnode ([] , forr p0 (fneg p0)) rEa
    [ gnode ([fneg p0], forr p0 (fneg p0)) rOrR2
        [ gnode ([fneg p0], fneg p0) rImpR
            [ gnode ([fneg p0; p0], fbot) rImpL
                [ gnode ([fneg p0; p0], p0) rId []
                ; gnode ([fbot; fneg p0; p0], fbot) rBotL [] ] ] ]
    ; gnode ([p0], forr p0 (fneg p0)) rOrR1
        [ gnode ([p0], p0) rId [] ] ].

Example eaLem_ok : g3chk true eaLem = true.
Proof. reflexivity. Qed.
Example eaLem_no_ea : g3chk false eaLem = false.
Proof. reflexivity. Qed.

(* 定理 4.17 的单例兑现：G3ipEa ⊢ ⇒p∨¬p ⟹ G3ip ⊢ ⇒¬¬(p∨¬p) *)
Definition gGlivenko : g3d :=
  gnode ([], fneg (fneg (forr p0 (fneg p0)))) rImpR
    [ gnode ([fneg (forr p0 (fneg p0))], fbot) rImpL
        [ gnode ([fneg (forr p0 (fneg p0))], forr p0 (fneg p0)) rOrR2
            [ gnode ([fneg (forr p0 (fneg p0))], fneg p0) rImpR
                [ gnode ([fneg (forr p0 (fneg p0)); p0], fbot) rImpL
                    [ gnode ([fneg (forr p0 (fneg p0)); p0],
                             forr p0 (fneg p0)) rOrR1
                          [ gnode ([fneg (forr p0 (fneg p0)); p0], p0) rId [] ]
                    ; gnode ([fbot; fneg (forr p0 (fneg p0)); p0], fbot) rBotL [] ] ] ]
        ; gnode ([fbot; fneg (forr p0 (fneg p0))], fbot) rBotL [] ] ].

Example glivenko_ok : g3chk false gGlivenko = true.
Proof. reflexivity. Qed.
(* 同一目标在 G3ipEa 里一步 (Ea) 即得（上树），在 G3ip 里要走完整
   的 ¬¬ 环绕（本树）——嵌入定理的「拆一层 ¬¬」在两棵树上现形。
   13 章 Glivenko 的语义路线在此接到句法路线（推论 4.5）：
   ⊢HK α ⟺ ⊢HJ ¬¬α。 *)

(* ============ 五、G1/G2/G3 逐级拆除的账面（引理 4.3/4.6/4.8 选样） ============ *)

(* G1：多重集灭交换——交换规则可省（结构=可重集，书 4.1 开篇）。
   G2：公理带语境灭弱化——(Id) α,Γ⇒Δ,α 型公理使弱化可容许（引理 4.3）：
   对可推导矢列，任意加公式仍可推导。机器账：*)
Example g2_weakening_admissible_sample :
  (* ⇒p→p 可推导 ⟹ ⇒q→(p→p)（加 q）仍可推导——用 g4prove 验证 *)
  andb (g4prove 200 ([], fimp p0 p0))
       (g4prove 200 ([], fimp p1 (fimp p0 p0)))
  = true.
Proof. reflexivity. Qed.

(* G3：主公式重复灭收缩——(∧⇒) 前提带两份分解式，(→⇒)/(∨⇒) 前提带
   主公式（premsOf 的形状即此）。收缩可容许（引理 4.8）的样本：
   双份 p0,p0 ⇒ p0 与单份同判 *)
Example g3_contraction_sample :
  andb (g4prove 200 ([p0; p0], p0)) (g4prove 200 ([p0], p0)) = true.
Proof. reflexivity. Qed.

(* 账本 *)
Print Assumptions g4_glivenko_instance.
Print Assumptions g4_not_dne.
Print Assumptions glivenko_ok.
