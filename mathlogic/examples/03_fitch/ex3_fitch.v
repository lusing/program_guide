(* ex3_fitch.v —— 费奇式自然演绎 FJ/FK（马明辉 2.1 定义 2.1）
   书写形式：左侧步骤编号，右侧标注依据（Pre/Hyp/Reit/规则名:引用行）；
   竖线标注子证明范围，每引入假设向右移一格（级别+1）。
   结构规则：Hyp 开框；Reit 只能引用同级之前+恰上一级（作用域纪律）。
   FK = FJ + ¬E（框式归谬：子证明由 Hyp ¬α 推出 ⊥ 得 α）。
   机器件：级别纪律+作用域可达性+依据逐行核的完整检查器；书例重演；
   FJ/FK 分隔（LEM 在 FK 可推；FJ 侧两点 Kripke 反例）。 *)

From Stdlib Require Import Bool Arith Lia List.
Import ListNotations.

(* ============ 一、公式与行 ============ *)

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

(* 依据：m/n 等为行号（1 起）；IIf a b = →I:a-b（框 a..b）；
   NEf a b = ¬E:a-b（FK 框式归谬）；OE m a b c d = ∨E:m,(a-b),(c-d) *)
Inductive just : Type :=
| Pre | Hyp
| Reit (m : nat)
| AI (m n : nat) | AEL (m : nat) | AER (m : nat)
| OI1 (m : nat) | OI2 (m : nat)
| OE (m a b c d : nat)
| IIf (a b : nat)
| IEf (m n : nat)
| BotE (m : nat)
| NEf (a b : nat).

Definition isHyp (j : just) : bool :=
  match j with Hyp => true | _ => false end.

Record fline : Type := mkfl { flv : nat; ffm : fform; fjt : just }.
Definition fitch : Type := list fline.

(* 1 起行号取行 *)
Definition getl (d : fitch) (m : nat) : option fline := nth_error d (pred m).
Definition getm (d : fitch) (m : nat) : option fform :=
  match getl d m with Some l => Some (ffm l) | None => None end.
Definition getv (d : fitch) (m : nat) : option nat :=
  match getl d m with Some l => Some (flv l) | None => None end.

(* ============ 二、作用域可达性 ============ *)

(* j..hi 中是否存在级别 lv 的 Hyp（同级别的框边界） *)
Fixpoint anyHypLv (d : fitch) (fuel j hi lv : nat) : bool :=
  match fuel with
  | O => false
  | S f => if Nat.ltb hi j then false
           else orb (match getl d j with
                     | Some l => andb (isHyp (fjt l)) (Nat.eqb (flv l) lv)
                     | None => false end)
                    (anyHypLv d f (S j) hi lv)
  end.

(* j..hi 中是否存在级别 < lv（lv 级框已闭合） *)
Fixpoint anyBelow (d : fitch) (fuel j hi lv : nat) : bool :=
  match fuel with
  | O => false
  | S f => if Nat.ltb hi j then false
           else orb (match getv d j with
                     | Some v => Nat.ltb v lv
                     | None => false end)
                    (anyBelow d f (S j) hi lv)
  end.

(* 同框可达：同级、之前、且中间无同级 Hyp 开新框（推理规则只准引同框行） *)
Definition accSame (d : fitch) (m i : nat) : bool :=
  match getv d m, getv d i with
  | Some vm, Some vi =>
      andb (Nat.eqb vm vi) (andb (Nat.ltb m i)
        (negb (anyHypLv d i (S m) i vm)))
  | _, _ => false
  end.

(* 上一级可达：级别恰差一、之前、且父框未闭合（Reit 专用——恰上一级） *)
Definition accUp (d : fitch) (m i : nat) : bool :=
  match getv d m, getv d i with
  | Some vm, Some vi =>
      andb (Nat.eqb vi (S vm)) (andb (Nat.ltb m i)
        (negb (anyBelow d i (S m) i vm)))
  | _, _ => false
  end.

(* ============ 三、级别纪律 ============ *)

Definition firstOK (l : fline) : bool :=
  match fjt l with
  | Pre => Nat.eqb (flv l) 0         (* 前提在最外层 *)
  | Hyp => Nat.eqb (flv l) 1         (* 首行假设开框 *)
  | _ => false
  end.

(* 相邻行 l1（早）→ l2（晚）的级别约束 *)
Definition stepOK (l1 l2 : fline) : bool :=
  andb (Nat.leb (flv l2) (S (flv l1)))                     (* 至多深一格 *)
    (andb (implb (Nat.eqb (flv l2) (S (flv l1))) (isHyp (fjt l2)))
                                                          (* 加深必是 Hyp *)
      (andb (implb (isHyp (fjt l2))
                   (andb (Nat.leb 1 (flv l2))
                         (orb (Nat.eqb (flv l2) (flv l1))
                              (Nat.eqb (flv l2) (S (flv l1))))))
                                                          (* Hyp=同框兄弟或加深 *)
            (implb (match fjt l2 with Pre => true | _ => false end)
                   (Nat.eqb (flv l2) 0)))).                (* 前提恒在最外层 *)

Fixpoint stepsOK (d : fitch) : bool :=
  match d with
  | [] => true
  | l :: d' =>
      match d' with
      | [] => true
      | l2 :: _ => andb (stepOK l l2) (stepsOK d')
      end
  end.

Definition levelsOK (d : fitch) : bool :=
  match d with
  | [] => true
  | l :: _ => andb (firstOK l) (stepsOK d)
  end.

(* ============ 四、依据逐行核 ============ *)

Definition check1 (d : fitch) (i kc : nat) (l : fline) : bool :=
  match fjt l with
  | Pre => Nat.eqb (flv l) 0
  | Hyp => true
  | Reit m =>
      match getl d m with
      | Some lm => andb (feqb (ffm l) (ffm lm))
                          (orb (accSame d m i) (accUp d m i))
      | None => false
      end
  | AI m n =>
      match getm d m, getm d n with
      | Some a, Some b => andb (feqb (ffm l) (fand a b))
                                (andb (accSame d m i) (accSame d n i))
      | _, _ => false
      end
  | AEL m =>
      match getm d m with
      | Some (fand a _) => andb (feqb (ffm l) a) (accSame d m i)
      | _ => false
      end
  | AER m =>
      match getm d m with
      | Some (fand _ b) => andb (feqb (ffm l) b) (accSame d m i)
      | _ => false
      end
  | OI1 m =>
      match getm d m, ffm l with
      | Some a, forr a' _ => andb (feqb a a') (accSame d m i)
      | _, _ => false
      end
  | OI2 m =>
      match getm d m, ffm l with
      | Some b, forr _ b' => andb (feqb b b') (accSame d m i)
      | _, _ => false
      end
  | BotE m =>
      match getm d m with
      | Some fbot => accSame d m i
      | _ => false
      end
  | IEf m n =>
      match getm d m, getm d n with
      | Some (fimp a b), Some a' =>
          andb (feqb a a') (andb (feqb (ffm l) b)
            (andb (accSame d m i) (accSame d n i)))
      | _, _ => false
      end
  | IIf a b =>
      andb (Nat.eqb (S b) i)                        (* 框止于紧邻上一行 *)
        (match getl d a, getl d b with
         | Some la, Some lb =>
             andb (Nat.eqb (flv la) (S (flv l)))
                  (andb (Nat.eqb (flv lb) (flv la))
                        (andb (isHyp (fjt la))
                              (feqb (ffm l) (fimp (ffm la) (ffm lb)))))
         | _, _ => false
         end)
  | NEf a b =>
      andb (Nat.eqb kc 1)                            (* ¬E 仅 FK *)
        (andb (Nat.eqb (S b) i)
          (match getl d a, getl d b with
           | Some la, Some lb =>
               andb (Nat.eqb (flv la) (S (flv l)))
                    (andb (Nat.eqb (flv lb) (flv la))
                          (andb (isHyp (fjt la))
                                (andb (feqb (ffm la) (fneg (ffm l)))
                                      (feqb (ffm lb) fbot))))
           | _, _ => false
           end))
  | OE m a b c e =>
      andb (Nat.eqb (S b) c)                          (* 两框相邻 *)
        (andb (Nat.eqb (S e) i)
          (andb (accSame d m i)
            (match getl d m, getl d a, getl d b, getl d c, getl d e with
             | Some lm, Some la, Some lb, Some lc, Some le =>
                 andb (Nat.eqb (flv la) (S (flv l)))
                      (andb (Nat.eqb (flv lc) (S (flv l)))
                            (andb (Nat.eqb (flv lb) (flv la))
                                  (andb (Nat.eqb (flv le) (flv lc))
                                        (andb (isHyp (fjt la))
                                              (andb (isHyp (fjt lc))
                                                    (match ffm lm with
                                                    | forr x y =>
                                                        andb (feqb x (ffm la))
                                                              (andb (feqb y (ffm lc))
                                                                    (andb (feqb (ffm lb) (ffm l))
                                                                          (feqb (ffm le) (ffm l))))
                                                    | _ => false
                                                    end))))))
             | _, _, _, _, _ => false
             end)))
  end.

Fixpoint checkAll (d : fitch) (kc : nat) (fuel i : nat) : bool :=
  match fuel with
  | O => true
  | S f =>
      match getl d i with
      | None => true
      | Some l => andb (check1 d i kc l) (checkAll d kc f (S i))
      end
  end.

(* kc=0 查 FJ；kc=1 查 FK *)
Definition fitchOK (kc : nat) (d : fitch) : bool :=
  andb (levelsOK d) (checkAll d kc (S (length d)) 1).

(* ============ 五、书例重演（马明辉 2.1） ============ *)

(* 记号：p0=α，p1=β，p2=γ（例中公式变元） *)
Definition p0 := pvar 0.
Definition p1 := pvar 1.

(* 引例：α, α→β, ¬β ⊢ ⊥（书 p26 五行证明：→E 两次） *)
Definition exIntro : fitch :=
  [ mkfl 0 p0 Pre
  ; mkfl 0 (fimp p0 p1) Pre
  ; mkfl 0 (fneg p1) Pre
  ; mkfl 0 p1 (IEf 2 1)
  ; mkfl 0 fbot (IEf 3 4) ].

Example exIntro_ok : fitchOK 1 exIntro = true.
Proof. reflexivity. Qed.

(* 引例：⊢ α→α（Hyp, Reit:1, →I:1-2） *)
Definition exId : fitch :=
  [ mkfl 1 p0 Hyp
  ; mkfl 1 p0 (Reit 1)
  ; mkfl 0 (fimp p0 p0) (IIf 1 2) ].

Example exId_ok : fitchOK 0 exId = true.
Proof. reflexivity. Qed.

(* 例 2.1(3)：⊢FK ¬¬α→α（Hyp ¬¬α … ¬E:2-4 … →I:1-5）
   跨级引用须先 Reit：¬¬α 在 1 级框，用前先搬进 2 级框 *)
Definition exDNE : fitch :=
  [ mkfl 1 (fneg (fneg p0)) Hyp                (* 1: ¬¬α *)
  ; mkfl 2 (fneg p0) Hyp                       (* 2: ¬α *)
  ; mkfl 2 (fneg (fneg p0)) (Reit 1)           (* 3: Reit 1（恰上一级） *)
  ; mkfl 2 fbot (IEf 3 2)                      (* 4: ⊥ *)
  ; mkfl 1 p0 (NEf 2 4)                        (* 5: α（¬E 归谬） *)
  ; mkfl 0 (fimp (fneg (fneg p0)) p0) (IIf 1 5) ].

Example exDNE_fk : fitchOK 1 exDNE = true.
Proof. reflexivity. Qed.
(* 同一推导在 FJ 被拒：第 5 行 ¬E 是 FK 独有规则 *)
Example exDNE_fj_rejects : fitchOK 0 exDNE = false.
Proof. reflexivity. Qed.

(* 引例：α∨β ⊢ β∨α（∨E:1, 2-3, 4-5——两个并列同级框） *)
Definition exComm : fitch :=
  [ mkfl 0 (forr p0 p1) Pre
  ; mkfl 1 p0 Hyp
  ; mkfl 1 (forr p1 p0) (OI2 2)
  ; mkfl 1 p1 Hyp
  ; mkfl 1 (forr p1 p0) (OI1 4)
  ; mkfl 0 (forr p1 p0) (OE 1 2 3 4 5) ].

Example exComm_ok : fitchOK 0 exComm = true.
Proof. reflexivity. Qed.

(* 引例：⊢ (α→β)→((β→γ)→(α→γ))——书 p27 十步链（四级证明的费奇版）；
   严格 Reit 纪律（恰上一级）要求级联搬运：1 级的 α→β 须经 2 级中转进 3 级 *)
Definition exSyll : fitch :=
  [ mkfl 1 (fimp p0 p1) Hyp                    (* 1 *)
  ; mkfl 2 (fimp p1 (pvar 2)) Hyp              (* 2 *)
  ; mkfl 2 (fimp p0 p1) (Reit 1)               (* 3: 搬进 2 级 *)
  ; mkfl 3 p0 Hyp                              (* 4 *)
  ; mkfl 3 (fimp p0 p1) (Reit 3)               (* 5: 再搬进 3 级 *)
  ; mkfl 3 p1 (IEf 5 4)                        (* 6 *)
  ; mkfl 3 (fimp p1 (pvar 2)) (Reit 2)         (* 7 *)
  ; mkfl 3 (pvar 2) (IEf 7 6)                  (* 8 *)
  ; mkfl 2 (fimp p0 (pvar 2)) (IIf 4 8)        (* 9 *)
  ; mkfl 1 (fimp (fimp p1 (pvar 2)) (fimp p0 (pvar 2))) (IIf 2 9)  (* 10 *)
  ; mkfl 0 (fimp (fimp p0 p1) (fimp (fimp p1 (pvar 2)) (fimp p0 (pvar 2))))
           (IIf 1 10) ].

Example exSyll_ok : fitchOK 0 exSyll = true.
Proof. reflexivity. Qed.

(* ============ 六、FK 的排中律；FJ 的反例 ============ *)

(* ⊢FK p∨¬p：假设 ¬(p∨¬p)，先由 p 得 ⊥（→I 得 ¬p），再用 ¬(p∨¬p) 自爆，
   ¬E 归谬出场——书「例 2.1(3) 同型」 *)
Definition exLem : fitch :=
  [ mkfl 1 (fneg (forr p0 (fneg p0))) Hyp      (* 1: ¬(p∨¬p) *)
  ; mkfl 2 p0 Hyp                              (* 2: p *)
  ; mkfl 2 (fneg (forr p0 (fneg p0))) (Reit 1) (* 3 *)
  ; mkfl 2 (forr p0 (fneg p0)) (OI1 2)         (* 4 *)
  ; mkfl 2 fbot (IEf 3 4)                      (* 5 *)
  ; mkfl 1 (fneg p0) (IIf 2 5)                 (* 6: ¬p *)
  ; mkfl 1 (forr p0 (fneg p0)) (OI2 6)         (* 7 *)
  ; mkfl 1 fbot (IEf 1 7)                      (* 8 *)
  ; mkfl 0 (forr p0 (fneg p0)) (NEf 1 8) ].    (* 9: ¬E 归谬 *)

Example exLem_fk : fitchOK 1 exLem = true.
Proof. reflexivity. Qed.
Example exLem_fj_rejects : fitchOK 0 exLem = false.
Proof. reflexivity. Qed.

(* FJ 侧没有 LEM：两点 Kripke 链 0R1、V(p)={1}——p∨¬p 在 0 点无真值 *)
Definition acc01 (w u : nat) : bool :=
  match w, u with
  | 0, 0 => true | 0, 1 => true
  | 1, 1 => true
  | _, _ => false
  end.

Fixpoint kforce (w : nat) (a : fform) : bool :=
  match a with
  | pvar n => andb (Nat.eqb n 0) (Nat.eqb w 1)   (* V(p0)={1}，其余变元恒假 *)
  | fbot => false
  | fand x y => andb (kforce w x) (kforce w y)
  | forr x y => orb (kforce w x) (kforce w y)
  | fimp x y =>
      forallb (fun u => implb (acc01 w u) (implb (kforce u x) (kforce u y))) [0;1]
  end.

Example lem_false_at_0 : kforce 0 (forr p0 (fneg p0)) = false.
Proof. reflexivity. Qed.
(* p 在 0 点不真也不假：直觉主义第三值的费奇侧现场（对照 14 章 Kripke） *)
Example p_neither_at_0 :
  andb (kforce 0 p0) (kforce 0 (fneg p0)) = false.
Proof. reflexivity. Qed.
(* 但 ¬¬(p∨¬p) 在两点都真——Glivenko 现象的费奇侧影子（13 章） *)
Example dne_lem_both :
  forallb (fun w => kforce w (fneg (fneg (forr p0 (fneg p0))))) [0;1] = true.
Proof. reflexivity. Qed.
(* FJ 可靠性的方向说明：FJ 每条规则保持 Kripke 强制（文档线）；
   反例 + 正例抽样即机器面证据。 *)
Example impid_both :
  forallb (fun w => kforce w (fimp p0 (fimp p1 p0))) [0;1] = true.
Proof. reflexivity. Qed.

(* ============ 七、检查器抓错现场 ============ *)

(* 跨级引用（漏 Reit）：1 级的 α→β 被 2 级行直接 →E 引用 *)
Definition badCross : fitch :=
  [ mkfl 1 (fimp p0 p1) Hyp
  ; mkfl 2 p0 Hyp
  ; mkfl 2 p1 (IEf 1 2)                         (* ✗ 须先 Reit *)
  ; mkfl 1 (fimp p0 p1) (IIf 2 3)
  ; mkfl 0 (fimp (fimp p0 p1) (fimp p0 p1)) (IIf 1 4) ].

Example badCross_rejected : fitchOK 1 badCross = false.
Proof. reflexivity. Qed.

(* 补上中转 Reit 即通过（⊢ (α→β)→(α→β)，内框先证 β→β 的重言内核） *)
Definition goodCross : fitch :=
  [ mkfl 1 (fimp p0 p1) Hyp
  ; mkfl 2 p0 Hyp
  ; mkfl 2 (fimp p0 p1) (Reit 1)
  ; mkfl 2 p1 (IEf 3 2)
  ; mkfl 1 (fimp p0 p1) (IIf 2 4)
  ; mkfl 0 (fimp (fimp p0 p1) (fimp p0 p1)) (IIf 1 5) ].

Example goodCross_ok : fitchOK 0 goodCross = true.
Proof. reflexivity. Qed.

(* 框未闭紧：→I 引用的框终点不在紧邻上一行 *)
Definition badBox : fitch :=
  [ mkfl 1 p0 Hyp
  ; mkfl 1 p0 (Reit 1)
  ; mkfl 1 (fimp p0 p0) (IIf 1 2)               (* ✗ 框应闭在 1 级（0 级结论） *)
  ].

Example badBox_rejected : fitchOK 0 badBox = false.
Proof. reflexivity. Qed.

(* 账本 *)
Print Assumptions exLem_fk.
Print Assumptions lem_false_at_0.
Print Assumptions exSyll_ok.
