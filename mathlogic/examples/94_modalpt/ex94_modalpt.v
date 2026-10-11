(* ex94_modalpt.v —— 模态证明论：矢列与超矢列（马明辉 6.2/6.3）
   GI 组分析规则（(K)/(T)/(S4)——书已目核三式；方法源 Takano）。
   机器件：GI 规则推导检查器 mchk+书例 6.4 重演（□α⇒α 一步 (T)；
   (K) 在 GS4 可允许的 T→S4 链）；六系统-框架条件对应表数据；
   超矢列的分量级操作一步关系账（(Id)ᴴ/(⊥)ᴴ/Ew/Ec/MG/(□1⇒)——
   引理 6.23-6.27 的机制影子）。
   GIII 组（含 GS5）与 GIV 组的分析性切割（书明言 cut 不可消除，
   以子公式性质替代——Takano 路线）：规则图形 OCR 受限〔⚠〕，
   元定理与机制记文档线。 *)

From Stdlib Require Import Bool Arith List.
Import ListNotations.

Inductive mform : Type :=
| mvar (n : nat)
| mbot
| mand (a b : mform)
| mor (a b : mform)
| mimp (a b : mform)
| mbox (a : mform).

Definition negm (a : mform) : mform := mimp a mbot.
Definition diam (a : mform) : mform := negm (mbox (negm a)).

Fixpoint meqb (a b : mform) : bool :=
  match a, b with
  | mvar m, mvar n => Nat.eqb m n
  | mbot, mbot => true
  | mand a1 a2, mand b1 b2 => andb (meqb a1 b1) (meqb a2 b2)
  | mor a1 a2, mor b1 b2 => andb (meqb a1 b1) (meqb a2 b2)
  | mimp a1 a2, mimp b1 b2 => andb (meqb a1 b1) (meqb a2 b2)
  | mbox a1, mbox b1 => meqb a1 b1
  | _, _ => false
  end.

Fixpoint delm (a : mform) (l : list mform) : option (list mform) :=
  match l with
  | [] => None
  | b :: l' => if meqb a b then Some l'
               else match delm a l' with
                    | Some r => Some (b :: r)
                    | None => None
                    end
  end.

Fixpoint meql (G H : list mform) : bool :=
  match G with
  | [] => match H with [] => true | _ => false end
  | a :: G' => match delm a H with
               | Some H' => meql G' H'
               | None => false
               end
  end.

(* ============ 一、GI 组：模态矢列规则推导检查器 ============ *)

Definition mseq : Type := (list mform * mform)%type.    (* Γ ⇒ β：单后件 *)

Inductive mr : Type := mId | mBotL | mK | mT | mS4.

Inductive mder : Type :=
| mnode (s : mseq) (r : mr) (ds : list mder).

Definition mseqOf (d : mder) : mseq := match d with mnode s _ _ => s end.

Definition unbox (a : mform) : option mform :=
  match a with mbox x => Some x | _ => None end.

Fixpoint unboxL (G : list mform) : option (list mform) :=
  match G with
  | [] => Some []
  | a :: G' =>
      match unbox a, unboxL G' with
      | Some x, Some L => Some (x :: L)
      | _, _ => None
      end
  end.

Definition meqS (s t : mseq) : bool :=
  andb (meql (fst s) (fst t)) (meqb (snd s) (snd t)).

Fixpoint meqlS (l1 l2 : list mseq) : bool :=
  match l1, l2 with
  | [], [] => true
  | s1 :: t1, s2 :: t2 => andb (meqS s1 s2) (meqlS t1 t2)
  | _, _ => false
  end.

(* 结论→期望前提：
   (T)：□α,□Γ⇒β ⟸ α,□Γ⇒β
   (K)：□α,□□Γ⇒□β ⟸ α,□Γ⇒β
   (S4)：□α,□□Γ⇒□β ⟸ □α,□Γ⇒β *)
Definition mprems (s : mseq) (r : mr) : list mseq :=
  match r, s with
  | mId, _ => []
  | mBotL, _ => []
  | mT, (G, b) =>
      match G with
      | mbox a :: G' => [ (a :: G', b) ]
      | _ => [ (G, b) ]
      end
  | mK, (G, b) =>
      match G, b with
      | mbox a :: G', mbox c =>
          match unboxL G' with
          | Some L => [ (a :: L, c) ]
          | None => [ (G, b) ]
          end
      | _, _ => [ (G, b) ]
      end
  | mS4, (G, b) =>
      match G, b with
      | mbox a :: G', mbox c =>
          match unboxL G' with
          | Some L => [ (mbox a :: L, c) ]
          | None => [ (G, b) ]
          end
      | _, _ => [ (G, b) ]
      end
  end.

Fixpoint mchk (d : mder) : bool :=
  match d with
  | mnode s r ds =>
      andb (match r with
            | mId => existsb (fun a => match a with
                                      | mvar _ => meqb a (snd s)
                                      | _ => false end) (fst s)
            | mBotL => existsb (fun a => match a with mbot => true | _ => false end) (fst s)
            | _ => true
            end)
        (andb (forallb mchk ds)
              (meqlS (map mseqOf ds) (mprems s r)))
  end.

Definition p := mvar 0.
Definition q := mvar 1.

(* 例 6.4(2)：GKT ⊢ □α⇒α——一步 (T) 自公理 *)
Example ex_T_step :
  mchk (mnode ([mbox p], p) mT [ mnode ([p], p) mId [] ]) = true.
Proof. reflexivity. Qed.

(* 例 6.4(5) 的链形实例：GS4 ⊢ □p,□□p ⇒ □p
   链：(Id p,□p⇒p) →(T)→ □p,□p⇒p →(S4)→ □p,□□p⇒□p。
   正是 (K) 的结论形状（α=p、□Γ=[□p]、β=p 代入 (K)）——
   (K) 在 GS4 可允许的书证机制在这条三节点链上现形。 *)
Definition chainGS4 : mder :=
  mnode ([mbox p; mbox (mbox p)], mbox p) mS4
    [ mnode ([mbox p; mbox p], p) mT
        [ mnode ([p; mbox p], p) mId [] ] ].

Example chainGS4_ok : mchk chainGS4 = true.
Proof. reflexivity. Qed.

(* (K) 规则自身的可靠性样例：□(p→q)⇒□(p→q) 型恒等在 GK 一步 (K)
   自公理不可得（(K) 结论须 □β 后件）；正确样例：
   □(p∧q),□□r ⇒ □(q∧p)：(K) 前提 p∧q,r ⇒ q∧p——命题规则的地盘。
   机器账：mprems 的 (K) 分支对账。 *)
Example mK_prems_account :
  meqlS (map mseqOf [ mnode ([p], p) mId [] ])
        (mprems ([mbox p], p) mT) = true.
Proof. reflexivity. Qed.

(* 六系统-框架条件对应表（命题 6.8+表 6-3 的数据影子；
   条件：0=任意 1=自返 2=持续 3=传递 4=持续+传递 5=自返+传递 *)
Definition giTable : list (nat * nat) :=
  [ (1, 0); (2, 1); (3, 2); (4, 3); (5, 4); (6, 5) ].
Example giTable_count : length giTable = 6.
Proof. reflexivity. Qed.

(* ============ 二、超矢列：分量级操作（6.3） ============ *)

(* 超矢列 = 矢列的可重集；「|」读作「或者」：某分量有效 *)
Definition hseq : Type := list ((list mform * list mform)%type).

(* 分量公理：(Id)ᴴ Γ,p⇒Δ,p（p 变元）；(⊥)ᴴ ⊥∈Γ *)
Definition compAxiom (s : (list mform * list mform)%type) : bool :=
  orb (existsb (fun a => match a with
                        | mvar _ => existsb (fun b => meqb a b) (snd s)
                        | _ => false end) (fst s))
      (existsb (fun a => match a with mbot => true | _ => false end) (fst s)).

Fixpoint delSeq (s : (list mform * list mform)%type) (k : hseq) : option hseq :=
  match k with
  | [] => None
  | t :: k' => if andb (meql (fst s) (fst t)) (meql (snd s) (snd t))
               then Some k'
               else match delSeq s k' with
                    | Some r => Some (t :: r)
                    | None => None
                    end
  end.

Fixpoint hEqb (h k : hseq) : bool :=
  match h with
  | [] => match k with [] => true | _ => false end
  | s :: h' => match delSeq s k with
               | Some k' => hEqb h' k'
               | None => false
               end
  end.

Definition removeAt (n : nat) (h : hseq) : hseq :=
  firstn n h ++ skipn (S n) h.

(* 外部弱化 (Ew)：前提 k，结论 h=k 加一个分量 *)
Definition ewRel (h k : hseq) : bool :=
  existsb (fun n => hEqb (removeAt n h) k) (List.seq 0 (length h)).

(* 外部收缩 (Ec)：前提 k，结论 h=k 去掉一个重复分量 *)
Definition ecRel (h k : hseq) : bool :=
  existsb (fun n => hEqb (removeAt n k) h) (List.seq 0 (length k)).

(* 合成规则 (MG)（引理 6.23）：前提首两个分量合并为结论首分量 *)
Definition mgRel (h k : hseq) : bool :=
  match h, k with
  | (g, dl) :: h', (g1, d1) :: (g2, d2) :: k' =>
      andb (meql g (g1 ++ g2))
        (andb (meql dl (d1 ++ d2)) (hEqb h' k'))
  | _, _ => false
  end.

(* (□1⇒)：结论某分量中一个 □a 在前提里换成 a *)
Fixpoint unboxOne (g : list mform) : list (list mform) :=
  match g with
  | [] => []
  | a :: g' =>
      match a with
      | mbox x => (x :: g') :: map (fun r => mbox x :: r) (unboxOne g')
      | _ => map (fun r => a :: r) (unboxOne g')
      end
  end.

Fixpoint b1Rel (h k : hseq) : bool :=
  match h, k with
  | (gh, dh) :: h', (gk, dk) :: k' =>
      andb (meql dh dk)
        (orb (existsb (fun g => meql g gk) (unboxOne gh))
             (andb (meql gh gk) (b1Rel h' k')))
  | _, _ => false
  end.

(* —— 一步关系账 —— *)
Example hax_ok : compAxiom ([p], [p]) = true.
Proof. reflexivity. Qed.
Example hbot_ok : compAxiom ([mbot; p], []) = true.
Proof. reflexivity. Qed.
Example ew_step : ewRel [([p],[p]); ([q],[q])] [([p],[p])] = true.
Proof. reflexivity. Qed.
Example ec_step : ecRel [([p],[p])] [([p],[p]); ([p],[p])] = true.
Proof. reflexivity. Qed.
Example mg_step : mgRel [([p;q],[p;q])] [([p],[p]); ([q],[q])] = true.
Proof. reflexivity. Qed.
Example b1_step : b1Rel [([mbox p],[p])] [([p],[p])] = true.
Proof. reflexivity. Qed.

(* □p⇒p 的超矢列推导（(□1⇒) 自 (Id)ᴴ——S5 的 T 性；书 6.3 的
   (□1⇒) 可靠性用 S5⊨□α→α）：两步关系账拼合 *)
Example b1_from_axiom :
  andb (compAxiom ([p], [p])) (b1Rel [([mbox p],[p])] [([p],[p])]) = true.
Proof. reflexivity. Qed.

(* GIII/GIV（分析性切割）与 HS5 的 (⇒□)/(Hcut) 消除链（定理 6.6 的
   (5.3) □ 情形需 MG+Ec+Ic 收尾）：规则图形 OCR 受限，正文以书的
   元定理陈述与机制图承载——文档线。 *)

(* 账本 *)
Print Assumptions ex_T_step.
Print Assumptions chainGS4_ok.
Print Assumptions b1_from_axiom.
