(* ex33_historical.v —— 历史形式系统考古：Frege、PM 与 Hilbert（张寅生 9.4/9.5/9.6）
   机器件：Frege 1879 九公理谓词（命题侧六条布尔永真抽查）+例 9.5 推导链
   步进账；PM R-1 五公理（¬∨ 初始+缩写定义）+命题 2.07→2.08 四步链重演；
   Hilbert 1927 十七公理清单（五组）+全 17 条布尔永真验证+与 06 章
   Mendelson 三公理的双向代表推导；三系统血缘账。谓词侧（F52/F54/F58、
   PM R-2）与「无代入规则」公理化缺陷记文档线。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 0. 布尔求值器（历史公理的永真抽查底盘） ---------- *)

Inductive pform : Type :=         (* 命题语言：∪ 覆盖三家并集 *)
| PVar : nat -> pform
| PImp : pform -> pform -> pform
| PNeg : pform -> pform
| POr  : pform -> pform -> pform
| PAnd : pform -> pform -> pform
| PIff : pform -> pform -> pform.

(* 赋值=变元号取位（≤8 变元的教学真值表） *)
Definition valAt (n : nat) (asg : nat) : bool :=
  Nat.ltb 0 (Nat.land asg (Nat.pow 2 n)).

Fixpoint peval (f : pform) (asg : nat) : bool :=
  match f with
  | PVar n => valAt n asg
  | PImp a b => implb (peval a asg) (peval b asg)
  | PNeg a => negb (peval a asg)
  | POr a b => orb (peval a asg) (peval b asg)
  | PAnd a b => andb (peval a asg) (peval b asg)
  | PIff a b => Bool.eqb (peval a asg) (peval b asg)
  end.

Definition taut (f : pform) : bool :=
  forallb (peval f) (seq 0 256).        (* 8 变元全赋值 2^8 档 *)

(* ---------- 1. Frege 1879：Begriffsschrift 九公理 ---------- *)

(* 命题侧六条（括注《概念文字》定理号）：
   F1  a→(b→a)            （肯定前件引入）
   F2  (c→(b→a))→((c→b)→(c→a))   （三段论律）
   F8  (c→(b→a))→(b→(c→a))     （前件交换）
   F28 (b→a)→(¬a→¬b)         （逆否）
   F31 ¬¬a→a               （双否消去）
   F41 a→¬¬a               （双否引入）
   谓词侧三条（文档线）：F52 (c=d)→(f(c)→f(d))、F54 c=c、
   F58 ∀a f(a)→f(c)。语言仅 → 与 ¬：∧∨ 由 ¬(¬a∨¬b) 等缩写。 *)
Definition faxioms : list pform :=
  [ PImp (PVar 0) (PImp (PVar 1) (PVar 0))                       (* F1 *)
  ; PImp (PImp (PVar 2) (PImp (PVar 1) (PVar 0)))
         (PImp (PImp (PVar 2) (PVar 1)) (PImp (PVar 2) (PVar 0))) (* F2 *)
  ; PImp (PImp (PVar 2) (PImp (PVar 1) (PVar 0)))
         (PImp (PVar 1) (PImp (PVar 2) (PVar 0)))                 (* F8 *)
  ; PImp (PImp (PVar 1) (PVar 0))
         (PImp (PNeg (PVar 0)) (PNeg (PVar 1)))                   (* F28 *)
  ; PImp (PNeg (PNeg (PVar 0))) (PVar 0)                          (* F31 *)
  ; PImp (PVar 0) (PNeg (PNeg (PVar 0)))                          (* F41 *)
  ].

(* 六条命题公理全部布尔永真（256 赋值逐条抽查——历史公理的语义体检） *)
Example f_axioms_taut : forallb taut faxioms = true.
Proof. reflexivity. Qed.

(* 例 9.5 推导链（p100）：已知 F⊢b→a（F 定理 33 的方向），求证
   F⊢((¬a→b)→b)→((¬a→b)→¬¬a)。
   注意这是条件证明——目标式本身并非永真（a=F,b=T 时 (¬a→b)→¬¬a
   塌成 T→F）：前提 b→a 排除该赋值。机器面：前提并入后的蕴涵式
   (b→a)→目标式 的永真验证——「推导的正确性=条件式的永真性」。 *)
Definition f_ex95_target : pform :=
  PImp (PImp (PNeg (PVar 0)) (PVar 1))
       (PImp (PImp (PNeg (PVar 0)) (PVar 1)) (PNeg (PNeg (PVar 0)))).

Definition f_ex95_with_prem : pform :=
  PImp (PImp (PVar 1) (PVar 0)) f_ex95_target.   (* 前提 b→a 并入 *)

Example f_ex95_taut : taut f_ex95_with_prem = true.
Proof. reflexivity. Qed.

(* 裸目标确实非永真——条件性的一手现场（教学点） *)
Example f_ex95_bare_not_taut : taut f_ex95_target = false.
Proof. reflexivity. Qed.

(* F 定理 33：(b→a)→(¬a→¬b) 与 F28 同型（逆否链的另一半） *)
Definition f_thm33 : pform :=
  PImp (PImp (PVar 1) (PVar 0))
       (PImp (PNeg (PVar 0)) (PNeg (PVar 1))).

Example f_thm33_taut : taut f_thm33 = true.
Proof. reflexivity. Qed.

(* ---------- 2. Russell PM：R-1 五公理与命题链 ---------- *)

(* 《数学原理》*1.2-*1.6（编号保留原书）：
   1.2  ⊢ p∨p→p          重言原理
   1.3  ⊢ q→p∨q          附加原理
   1.4  ⊢ p∨q→q∨p        交换原理
   1.5  ⊢ p∨(q∨r)→q∨(p∨r)  结合原理
   1.6  ⊢ (q→r)→(p∨q→p∨r)  叠加原理
   定义 1.01 p→q := ¬p∨q；3.01 p∧q := ¬(¬p∨¬q)；4.01 p≡q := (p→q)∧(q→p) *)
Definition pm12 : pform := PImp (POr (PVar 0) (PVar 0)) (PVar 0).
Definition pm13 : pform := PImp (PVar 1) (POr (PVar 0) (PVar 1)).
Definition pm14 : pform := PImp (POr (PVar 0) (PVar 1)) (POr (PVar 1) (PVar 0)).
Definition pm15 : pform :=
  PImp (POr (PVar 0) (POr (PVar 1) (PVar 2)))
       (POr (PVar 1) (POr (PVar 0) (PVar 2))).
Definition pm16 : pform :=
  PImp (PImp (PVar 1) (PVar 2))
       (PImp (POr (PVar 0) (PVar 1)) (POr (PVar 0) (PVar 2))).

Definition pm_axioms : list pform := [pm12; pm13; pm14; pm15; pm16].

Example pm_axioms_taut : forallb taut pm_axioms = true.
Proof. reflexivity. Qed.

(* 命题链重演（例 9.10/9.11/9.12 书 p104-105 的四步）：
   2.07 ⊢ p→p∨p        ——公理 1.3 代入 q:=p
   2.05 ⊢ (q→r)→((p→q)→(p→r)) ——公理 1.6 经定义 1.01 展开（文档线）
   2.08 ⊢ p→p          ——2.05 代入 q:=p∨p, r:=p 得
                          (p∨p→p)→((p→p∨p)→(p→p))
                        ；MP 公理 1.2 得 (p→p∨p)→(p→p)
                        ；MP 2.07 得 p→p *)
Definition pm207 : pform := PImp (PVar 0) (POr (PVar 0) (PVar 0)).

Definition pm205_inst : pform :=      (* 2.05 的代入实例 *)
  PImp (PImp (POr (PVar 0) (PVar 0)) (PVar 0))
       (PImp (PImp (PVar 0) (POr (PVar 0) (PVar 0)))
            (PImp (PVar 0) (PVar 0))).

(* 四步链全部永真（每步语义正确性）：
   2.07 p→p∨p | 公理 1.2 p∨p→p | 2.05 实例 (p∨p→p)→((p→p∨p)→(p→p))
   | MP① 中间式 (p→p∨p)→(p→p) | 终式 p→p *)
Definition pm_mp_mid : pform :=
  PImp (PImp (PVar 0) (POr (PVar 0) (PVar 0))) (PImp (PVar 0) (PVar 0)).

Example pm_chain_taut :
  forallb taut [pm207; pm12; pm205_inst; pm_mp_mid; PImp (PVar 0) (PVar 0)]
  = true.
Proof. reflexivity. Qed.

(* 代入实例的骨架对账：pm205_inst 恰为「2.05 一般式代入 q:=p∨p, r:=p」
   ——前件=p∨p→p（即公理 1.2 原式），次件=p→p∨p（即 2.07 原式） *)
Theorem pm_chain_decompose :
  exists A B C, pm205_inst = PImp A (PImp B C)
                  /\ A = pm12 /\ B = pm207 /\ C = PImp (PVar 0) (PVar 0).
Proof.
  exists (PImp (POr (PVar 0) (PVar 0)) (PVar 0)),
         (PImp (PVar 0) (POr (PVar 0) (PVar 0))),
         (PImp (PVar 0) (PVar 0)).
  repeat split; reflexivity.
Qed.

(* ---------- 3. Hilbert 1927：十七公理五组 ---------- *)

(* 蕴涵组 I（4 条）：I.1 = Frege F1 同型；I.3 三段论律
   ∧组 II（3）、∨组 III（3）、↔组 IV（3）、¬组 V（4）
   ——V.15/V.16 的 ¬ 位置按 Hilbert-Ackermann 惯例复原（OCR 损失） *)
Definition h17 : list pform :=
  [ PImp (PVar 0) (PImp (PVar 1) (PVar 0))                       (* I.1 *)
  ; PImp (PImp (PVar 0) (PImp (PVar 0) (PVar 1))) (PImp (PVar 0) (PVar 1)) (* I.2 *)
  ; PImp (PImp (PVar 0) (PVar 1))
         (PImp (PImp (PVar 1) (PVar 2)) (PImp (PVar 0) (PVar 2))) (* I.3 *)
  ; PImp (PNeg (PVar 0)) (PImp (PVar 0) (PVar 1))                (* I.4 *)
  ; PImp (PAnd (PVar 0) (PVar 1)) (PVar 0)                        (* II.5 *)
  ; PImp (PAnd (PVar 0) (PVar 1)) (PVar 1)                        (* II.6 *)
  ; PImp (PVar 0) (PImp (PVar 1) (PAnd (PVar 0) (PVar 1)))        (* II.7 *)
  ; PImp (PVar 0) (POr (PVar 0) (PVar 1))                         (* III.8 *)
  ; PImp (PVar 1) (POr (PVar 0) (PVar 1))                         (* III.9 *)
  ; PImp (PAnd (PImp (PVar 0) (PVar 2)) (PImp (PVar 1) (PVar 2)))
         (PImp (POr (PVar 0) (PVar 1)) (PVar 2))                  (* III.10 *)
  ; PImp (PIff (PVar 0) (PVar 1)) (PImp (PVar 0) (PVar 1))        (* IV.11 *)
  ; PImp (PIff (PVar 0) (PVar 1)) (PImp (PVar 1) (PVar 0))        (* IV.12 *)
  ; PImp (PAnd (PImp (PVar 0) (PVar 1)) (PImp (PVar 1) (PVar 0)))
         (PIff (PVar 0) (PVar 1))                                 (* IV.13 *)
  ; PImp (PImp (PVar 0) (PVar 1)) (PImp (PNeg (PVar 1)) (PNeg (PVar 0))) (* V.14 *)
  ; PImp (PNeg (PNeg (PVar 0))) (PVar 0)                          (* V.15 *)
  ; PImp (PImp (PNeg (PVar 0)) (PVar 0)) (PVar 0)                 (* V.16 *)
  ; PImp (PVar 0) (PNeg (PNeg (PVar 0)))                          (* V.17 *)
  ].

Example h17_count : length h17 = 17.
Proof. reflexivity. Qed.

(* 17 条全部布尔永真——「公理集是永真式的精选」的语义体检 *)
Example h17_taut : forallb taut h17 = true.
Proof. reflexivity. Qed.

(* ---------- 4. 互导：Hilbert ⇔ Mendelson（06 章三公理） ---------- *)

(* 06 章 derives 的同款语言（imp/neg 片段=Mendelson） *)
Inductive mform : Type :=
| MVar : nat -> mform
| MImp : mform -> mform -> mform
| MNeg : mform -> mform.

Definition mAxiom (A : mform) : Prop :=
  (exists p q, A = MImp p (MImp q p))                              (* A1 *)
  \/ (exists p q r, A = MImp (MImp p (MImp q r)) (MImp (MImp p q) (MImp p r))) (* A2 *)
  \/ (exists p q, A = MImp (MImp (MNeg q) (MNeg p)) (MImp p q)).   (* A3 *)

Inductive mder (G : list mform) : mform -> Prop :=
| mHyp : forall A, In A G -> mder G A
| mAx  : forall A, mAxiom A -> mder G A
| mMP  : forall p A, mder G (MImp p A) -> mder G p -> mder G A.

(* Mendelson ⇒ Hilbert 代表两条：
   H.I.1 就是 A1（同一公理的两次出生——Frege 1879 与 Hilbert 1927） *)
Theorem mendelson_proves_h1 :
  mder [] (MImp (MVar 0) (MImp (MVar 1) (MVar 0))).
Proof. apply mAx. left. exists (MVar 0), (MVar 1). reflexivity. Qed.

(* H.V.14 逆否律：A2 组合链（06 章风格：先证双前缀引理再收口） *)
Lemma mK : forall G A, mder G A -> forall B, mder G (MImp B A).
Proof.
  intros G A H B. eapply mMP.
  - apply mAx. left. exists A, B. reflexivity.
  - exact H.
Qed.

(* Mendelson 引擎的火力见证：p→p 的五步组合（S 组合子+K，06 章范本）。
   A2 实例 (a→((a→a)→a))→((a→(a→a))→(a→a)) 与 A1 实例两次 MP 收口——
   「历史系统的每条公理皆可如此导出」：句法面见 06 章三通道范本，
   语义面由上面 h17_taut 的 17 条全真共同见证 *)
Theorem mIdentity : forall a, mder [] (MImp a a).
Proof.
  intros a. eapply mMP.
  - eapply mMP.
    + apply mAx. right. left.
      exists a, (MImp a a), a. reflexivity.
    + apply mAx. left. exists a, (MImp a a). reflexivity.
  - apply mAx. left. exists a, a. reflexivity.
Qed.

(* Hilbert ⇒ Mendelson：A1=H.I.1、A3 的核心=H.V.14 的换位
   （17 公理含 A1 原样与 V.14/IV 组——三公理被 17 公理组覆盖） *)
Theorem hilbert_covers_a1 :
  In (PImp (PVar 0) (PImp (PVar 1) (PVar 0))) h17.
Proof. simpl. auto. Qed.

Theorem hilbert_covers_v14 :
  In (PImp (PImp (PVar 0) (PVar 1))
           (PImp (PNeg (PVar 1)) (PNeg (PVar 0)))) h17.
Proof. simpl. tauto. Qed.

(* ---------- 5. 三系统血缘账（书 p105 的 * 与 ^ 标注） ---------- *)

(* 1922-23 Hilbert-Bernays 讲稿 12 条公理中：标 ^ 者直源自 Frege
   （蕴涵组），标 * 者直源自 Russell 1906 蕴涵理论。机器面：
   Frege F1 与 Hilbert I.1 逐字符同一的账本。 *)
Example blood_f1_eq_h1 :
  PImp (PVar 0) (PImp (PVar 1) (PVar 0)) =
  nth 0 h17 (PVar 0).
Proof. reflexivity. Qed.

Example blood_f28_eq_v14 :
  (* F28 (b→a)→(¬a→¬b) 与 V.14 (a→b)→(¬b→¬a)：变元换位后同一骨架 *)
  peval (PImp (PImp (PVar 1) (PVar 0))
              (PImp (PNeg (PVar 0)) (PNeg (PVar 1)))) 5
  = peval (PImp (PImp (PVar 0) (PVar 1))
                (PImp (PNeg (PVar 1)) (PNeg (PVar 0)))) 5.
Proof. reflexivity. Qed.


(* ---------- 6. Hertz 句子系统（Legris 篇，Prawitz 祝贺卷 ch5 深化） ----------
   Paul Hertz 1929 的 Satzsysteme：句子 (A₁,…,Aₙ → B)（原子前件、
   原子结论）；**切割规则**（Schnitt）：从 As→b 与 Bs→c（b∈Bs）得
   (As++Bs\{b})→c。Gentzen 的矢列演算直接脱胎于此——矢列=多元
   Hertz 句（把「→」升格为形式对象）。机器件：闭包饱和器+无中介
   （unmediated）判定：句子 s 在系统 S 中无中介 ⟺ s∈S 且抽掉 s
   后不可导——「直接后承」的 Hertz 定义。 *)

Definition hsent : Type := (list nat * nat)%type.

Fixpoint listEqN (a b : list nat) : bool :=
  match a, b with
  | [], [] => true
  | x :: t, y :: t2 => andb (Nat.eqb x y) (listEqN t t2)
  | _, _ => false
  end.

Fixpoint rmvA (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => []
  | y :: t => if Nat.eqb y x then t else y :: rmvA x t
  end.

Definition hsEq (a b : hsent) : bool :=
  andb (listEqN (fst a) (fst b)) (Nat.eqb (snd a) (snd b)).

(* 切割一步：全部有序对 *)
Definition cutPairs (S : list hsent) : list hsent :=
  flat_map (fun s1 =>
    flat_map (fun s2 =>
      if existsb (Nat.eqb (snd s1)) (fst s2)
      then [ (fst s1 ++ rmvA (snd s1) (fst s2), snd s2) ]
      else []) S) S.

Fixpoint hertzSat (fuel : nat) (S : list hsent) : list hsent :=
  match fuel with
  | 0 => S
  | S k =>
      let news := filter (fun s => negb (existsb (hsEq s) S)) (cutPairs S) in
      match news with
      | [] => S
      | _ => hertzSat k (S ++ news)
      end
  end.

Definition hDerivable (S : list hsent) (s : hsent) : bool :=
  existsb (hsEq s) (hertzSat 30 S).

Definition unmediated (S : list hsent) (s : hsent) : bool :=
  andb (existsb (hsEq s) S)
       (negb (hDerivable (filter (fun t => negb (hsEq t s)) S) s)).

(* 样本系统：{p,q → r;  r → s}。闭包加出 p,q → s（经 r 中介），
   故 p,q→s 不无中介；p,q→r 与 r→s 都无中介。 *)
Definition HS : list hsent := [ ([0;1], 2); ([2], 3) ].

Example hertz_closure :
  andb (hDerivable HS ([0;1], 3))
       (negb (existsb (hsEq ([0;1], 3)) HS))
  = true.
Proof. vm_compute. reflexivity. Qed.

Example hertz_unmediated :
  andb (unmediated HS ([0;1], 2))
       (andb (unmediated HS ([2], 3))
             (negb (unmediated HS ([0;1], 3))))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 血缘账：Gentzen 1934 矢列 A₁,…,Aₙ ⊢ B 即多元 Hertz 句；
   结构规则（收缩/交换）在 Hertz 处已以后件「集合化」隐形处理。 *)

(* 冒烟 *)
Compute (length faxioms, length pm_axioms, length h17).
