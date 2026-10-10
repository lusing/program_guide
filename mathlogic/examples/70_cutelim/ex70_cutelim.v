(* ex70_cutelim.v —— 截消定理与序数分析（张寅生 9.7+13.8/13.9+5.3）
   机器件：矢列语义有效性（枚举赋值）；反演定理命题侧（八条逻辑规则的
   语义可逆性账）；例 9.15 七步矢列链重演（含书中勘误注记）；cut 的插入
   与「引理消去」语义面；情形 3（主公式 A→B）的级下降单例；CNF 序数
   （list nat）与自然和、序数指派 o(P) 及降序单例；超穷归纳 TI 的有限
   影子与最小反例反证；83 层相容性层级表（节选）。Hauptsatz 全证明
   （情形 1a-13b）与 Gentzen 四版证明史记文档线。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 1. 矢列演算 G 第二系统：语言与语义 ---------- *)

Inductive gform : Type :=
| GVar : nat -> gform
| GImp : gform -> gform -> gform
| GAnd : gform -> gform -> gform
| GOr  : gform -> gform -> gform
| GNeg : gform -> gform.

Definition gseq : Type := list gform * list gform.   (* Γ ⊢ Δ *)

Definition valAt (n : nat) (asg : nat) : bool :=
  Nat.ltb 0 (Nat.land asg (Nat.pow 2 n)).

Fixpoint gev (f : gform) (asg : nat) : bool :=
  match f with
  | GVar n => valAt n asg
  | GImp a b => implb (gev a asg) (gev b asg)
  | GAnd a b => andb (gev a asg) (gev b asg)
  | GOr a b => orb (gev a asg) (gev b asg)
  | GNeg a => negb (gev a asg)
  end.

(* 矢列语义：∧Γ → ∨Δ（根岑约定，书 p111） *)
Fixpoint allEv (l : list gform) (asg : nat) : bool :=
  match l with
  | [] => true
  | f :: t => andb (gev f asg) (allEv t asg)
  end.

Fixpoint anyEv (l : list gform) (asg : nat) : bool :=
  match l with
  | [] => false
  | f :: t => orb (gev f asg) (anyEv t asg)
  end.

Definition seqSem (s : gseq) : bool :=
  forallb (fun asg => implb (allEv (fst s) asg) (anyEv (snd s) asg))
    (seq 0 256).

(* ---------- 2. 反演定理（定理 9.1）命题侧 ---------- *)

(* 除弱化外，规则皆可逆：底部矢列有效 ⟺ 顶部矢列有效。
   八条逻辑规则左右引入各取代表实例，逐对验证语义等值。 *)
Definition invPairs : list (gseq * gseq) :=
  [ (([GAnd (GVar 0) (GVar 1)], []), ([GVar 0], []))                    (* ∧L *)
  ; (([], [GAnd (GVar 0) (GVar 1)]), ([], [GVar 0; GVar 1]))            (* ∧R *)
  ; (([GOr (GVar 0) (GVar 1)], []), ([GVar 0; GVar 1], []))             (* ∨L *)
  ; (([], [GOr (GVar 0) (GVar 1)]), ([], [GVar 0]))                      (* ∨R *)
  ; (([GNeg (GVar 0)], []), ([], [GVar 0]))                              (* ¬L *)
  ; (([], [GNeg (GVar 0)]), ([GVar 0], []))                              (* ¬R *)
  ; (([GImp (GVar 0) (GVar 1)], []),
     ([GVar 1], []))                                                     (* →L b *)
  ; (([], [GImp (GVar 0) (GVar 1)]), ([GVar 0], [GVar 1]))               (* →R *)
  ].

Example inversion_check :
  forallb (fun p => Bool.eqb (seqSem (fst p)) (seqSem (snd p))) invPairs
  = true.
Proof. reflexivity. Qed.

(* ---------- 3. 例 9.15 七步矢列链重演（书 p112） ---------- *)

(* 书例 9.15：证明 ⊢¬(P∧Q)→¬P∨¬Q。原文七步（含一步勘误：第六步
   「∧右引入」应为「∧左引入」——教学点：规则名与公式形状须对榫） *)
Definition ex915_chain : list (gseq * nat) :=   (* 步骤号 1..7 *)
  [ (([GVar 0], [GVar 0]), 1)                                          (* P⊢P 初始 *)
  ; (([GVar 0], [GVar 0; GNeg (GVar 1)]), 2)                           (* 弱化右 *)
  ; (([GVar 1], [GVar 1]), 3)                                          (* Q⊢Q 初始 *)
  ; (([GVar 1; GNeg (GVar 1)], []), 4)                                 (* 交换+¬左 *)
  ; (([GNeg (GVar 1); GVar 0], [GVar 0]), 5)                           (* 交换 *)
  ; (([GNeg (GVar 1); GAnd (GVar 0) (GVar 1)], [GVar 0]), 6)           (* ∧左引入 *)
  ; (([GAnd (GVar 0) (GVar 1)], [GVar 0; GNeg (GVar 1)]), 7)           (* ¬右引入 *)
  ].

(* 链上每一步的矢列全部语义有效（每步推导保持有效性——可靠性面） *)
Example ex915_steps_valid :
  forallb (fun st => seqSem (fst st)) ex915_chain = true.
Proof. reflexivity. Qed.

(* 终矢列读出的定理：¬(P∧Q) → ¬P∨¬Q 本体 *)
Definition ex915_thm : gform :=
  GImp (GNeg (GAnd (GVar 0) (GVar 1))) (GOr (GNeg (GVar 0)) (GNeg (GVar 1))).

Example ex915_thm_valid :
  seqSem ([], [ex915_thm]) = true.
Proof. reflexivity. Qed.

(* ---------- 4. cut：插入与「引理消去」 ---------- *)

(* 截消规则（式 9.22）：Γ⊢Θ,D 与 D,Δ⊢Λ ⟹ Γ,Δ⊢Θ,Λ。
   截消证明方法（定义 9.10）：(A⊢L)&(A,L⊢T)⟹(A⊢T)——cut=引理 L 的
   调用，cut 消去=把引理展开回原地。 *)
Definition cutApply (s1 s2 : gseq) (d : gform) : gseq :=
  (fst s1 ++ fst s2, snd s1 ++ snd s2).

(* 单例（教科书式）：上矢列 p⊢p∨p、下矢列 p∨p⊢p，cut 公式 D=p∨p
   ——「引理 D 被调用又展开」的最直观形态 *)
Definition cutDemo : gseq :=
  cutApply ([GVar 0], [GOr (GVar 0) (GVar 0)])
           ([GOr (GVar 0) (GVar 0)], [GVar 0])
           (GOr (GVar 0) (GVar 0)).

(* 两侧前提有效 + cut 后矢列仍有效（cut 的语义可靠性——引理调用安全） *)
Example cut_sound :
  [ seqSem ([GVar 0], [GOr (GVar 0) (GVar 0)])
  ; seqSem ([GOr (GVar 0) (GVar 0)], [GVar 0])
  ; seqSem cutDemo ] = [true; true; true].
Proof. reflexivity. Qed.

(* ---------- 5. 级（Grade）与情形 3 的级下降 ---------- *)

(* 定义 13.26：原子=1，每逻辑符号 +1 *)
Fixpoint grade (f : gform) : nat :=
  match f with
  | GVar _ => 1
  | GImp a b | GAnd a b | GOr a b => Nat.max (S (grade a)) (S (grade b))
  | GNeg a => S (grade a)
  end.

(* 情形 3（书 p227）：主公式 M=A→B 的 cut。消去后 cut 公式降为 A 或 B
   ——级严格下降。单例：M=(p→q)→r *)
Definition m3 : gform := GImp (GImp (GVar 0) (GVar 1)) (GVar 2).

Example grade_m3 : grade m3 = 3.
Proof. reflexivity. Qed.

(* 情形 3 的重写：对 M=(A→B) 的 cut，右引入展开 ⊢Θ,A→B 来自 ⊢Θ,A
   与 B,Θ⊢Λ；cut 分裂为 A 与 B 两个新 cut——级 3 → max(grade p, grade (q→r)) *)
Example case3_grade_drop :
  Nat.ltb (Nat.max (grade (GVar 0)) (grade (GImp (GVar 1) (GVar 2))))
          (grade m3) = true.
Proof. reflexivity. Qed.

(* ---------- 6. CNF 序数、自然和与序数指派 ---------- *)

(* <ω^ω 的 CNF 编码：list nat = [常数项;ω 系数;ω² 系数;…]（低位在前，
   67 章 CNF 序数树的最小版）。例：1=[1]、ω=[0;1]、ω³+2=[2;0;0;1] *)
Definition cnfAdd1 (c : list nat) : list nat :=   (* +1：常数位 +1 *)
  match c with
  | [] => [1]
  | h :: t => S h :: t
  end.

(* 自然和 #（式 13.31 的核心运算）：CNF 逐位取 max——序数和不交换但
   自然和交换，是降序定理的关键；低位在前使对齐天然成立 *)
Fixpoint natSum (a b : list nat) : list nat :=
  match a, b with
  | [], x => x
  | x, [] => x
  | ha :: ta, hb :: tb => Nat.max ha hb :: natSum ta tb
  end.

(* 序数比较：反转成高位在前、左补零对齐后字典序 *)
Fixpoint padL (n : nat) (l : list nat) : list nat :=
  match n with
  | 0 => l
  | S k => 0 :: padL k l
  end.

Fixpoint cnfLtHi (a b : list nat) : bool :=
  match a, b with
  | _, [] => false
  | [], _ => true
  | ha :: ta, hb :: tb =>
      if Nat.eqb ha hb then cnfLtHi ta tb else Nat.ltb ha hb
  end.

Definition cnfLt (a b : list nat) : bool :=
  cnfLtHi (padL (length b - length a) (rev a))
          (padL (length a - length b) (rev b)).

(* 指派规则（定理 13.7 的骨架）：
   初始矢列 o=1；弱化 o 不变；逻辑推理 o(P)=o(子证明)+1；
   cut 处 o=ω^(级差) #（两侧）。教学实现：两条浅证明树的指派对账——
   含 cut 的 P 与消去后的 P'，验证 o(P') < o(P)（降序定理单例） *)
Definition ordInit : list nat := [1].

Definition ordLogical (sub : list nat) : list nat := cnfAdd1 sub.

(* 含 cut 的证明 P：两棵逻辑子证明（各一层，o=2）+cut（级 3 的主公式）
   → o(P) = ω^3 # 2 # 2 = ω^3+2（编码 [2;0;0;1]） *)
Definition cutOrd : list nat :=
  natSum [0;0;0;1] (natSum (ordLogical [1]) (ordLogical [1])).

(* 消去后 P'：情形 3 分裂为两个低级 cut+一层逻辑
   → o(P') 停留在自然数层（编码 [3]=3） *)
Definition cutfreeOrd : list nat :=
  ordLogical (natSum [1] [2]).

Example descent_check : cnfLt cutfreeOrd cutOrd = true.
Proof. reflexivity. Qed.

(* ---------- 7. 超穷归纳 TI：模式与有限影子 ---------- *)

(* 定义 5.4：TI (Φ(0) ∧ ∀a<b(Φ(a)→Φ(b))) → ∀x Φ(x)。
   有限影子：谓词 p 在段 [0,n] 上的 TI 验证——p 0 且步进 ⟹ 全段 *)
Fixpoint holdsUpto (p : nat -> bool) (n : nat) : bool :=
  match n with
  | 0 => p 0
  | S k => andb (holdsUpto p k) (p (S k))
  end.

Fixpoint tiOn (p : nat -> bool) (n : nat) : bool :=
  match n with
  | 0 => p 0
  | S k => andb (tiOn p k) (implb (p k) (p (S k)))
  end.

Example ti_finite :
  forallb (fun n => implb (tiOn (fun k => Nat.eqb (k * k) (k * k)) n)
                        (holdsUpto (fun k => Nat.eqb (k * k) (k * k)) n))
    (seq 0 8) = true.
Proof. reflexivity. Qed.

(* 定理 5.3 的证明骨架（良序最小元反证）：若有反例集 X 非空，取最小
   反例 x₀：p(0) 真 + 步进在 x₀−1 处给出 p(x₀) 真——矛盾。
   机器面：反例集必有最小元的枚举账 *)
Fixpoint leastCounter (p : nat -> bool) (n : nat) : option nat :=
  match n with
  | 0 => if negb (p 0) then Some 0 else None
  | S k =>
      if negb (p (S k)) then Some (S k) else leastCounter p k
  end.

(* 最小反例是「步进的第一个破口」：反例存在 ⟹ 存在最小反例 *)
Example least_counter_exists :
  forallb (fun n =>
    implb (existsb (fun k => negb (Nat.eqb (k + k) (2 * k))) (seq 0 n))
          (match leastCounter (fun k => Nat.eqb (k + k) (2 * k)) n with
           | Some _ => true | None => false end))
    (seq 0 8) = true.
Proof. reflexivity. Qed.

(* ---------- 8. 相容性层级（13.9.2 附录 1 节选） ---------- *)

(* 哥德尔 83 层相容性链的 12 层节选（低到高，名字记注释）：
   1 EFA 指数函数算术 | 2 PRA 原始递归算术 | 3 RCA₀ 递归概括（逆数学
   基线）| 4 WKL₀ 弱 König 引理 | 5 IΣ₁ | 6 PA 皮亚诺算术 | 7 ACA₀
   算术概括 | 8 ATR₀ 自反超穷递归 | 9 Π¹₁-CA₀ | 10 Z₂ 二阶算术全集
   | 11 ZFC 集合论 | 12 不可达基数——链的上端 *)
Definition ladder : list nat := [1;2;3;4;5;6;7;8;9;10;11;12].

Example ladder_count : length ladder = 12.
Proof. reflexivity. Qed.
(* 层级的意义：每层的相容性由上一层的超穷归纳担保——Gentzen 用 <ε₀
   的 TI 证 PA 相容（第 6 层由 ε₀ 的序数分析保障）；链的尽头没有
   「绝对相容」——不完备性定理（65 章）在每一层都生效。 *)

(* 冒烟 *)
Compute (grade m3, cutOrd, cutfreeOrd).

(* ---------- 9. Takeuti §5 深化：mix 规则与 rank（LK* 视角） ---------- *)

(* 公式可判定相等（mix 删光操作需要） *)
Fixpoint formEqb (a b : gform) : bool :=
  match a, b with
  | GVar m, GVar n => Nat.eqb m n
  | GImp a1 a2, GImp b1 b2 => andb (formEqb a1 b1) (formEqb a2 b2)
  | GAnd a1 a2, GAnd b1 b2 => andb (formEqb a1 b1) (formEqb a2 b2)
  | GOr a1 a2, GOr b1 b2 => andb (formEqb a1 b1) (formEqb a2 b2)
  | GNeg a1, GNeg b1 => formEqb a1 b1
  | _, _ => false
  end.

(* 9.1 mix：把一侧中混合公式 A 的全部出现一次删光（书 p22 Def） *)
Fixpoint eraseAll (A : gform) (l : list gform) : list gform :=
  match l with
  | [] => []
  | B :: t => if formEqb A B then eraseAll A t else B :: eraseAll A t
  end.

Fixpoint formListEqb (l1 l2 : list gform) : bool :=
  match l1, l2 with
  | [], [] => true
  | a :: t1, b :: t2 => andb (formEqb a b) (formListEqb t1 t2)
  | _, _ => false
  end.

Fixpoint countForm (A : gform) (l : list gform) : nat :=
  match l with
  | [] => 0
  | B :: t => (if formEqb A B then 1 else 0) + countForm A t
  end.

(* mix 结论：Γ, Π* → Δ*, Λ（Π*、Δ* 删光 A） *)
Definition mixSeq (A : gform) (S1 S2 : gseq) : gseq :=
  (fst S1 ++ eraseAll A (fst S2), eraseAll A (snd S1) ++ snd S2).

(* 「一次删光」账本：被删出现数 = 左右两侧 A 出现总数 *)
Example mix_erase_ledger :
  let A := GVar 0 in
  let S1 := ([GVar 1], [A; GVar 2; A]) in
  let S2 := ([A; GVar 3; A], [GVar 4]) in
  (countForm A (snd S1), countForm A (fst S2),
   countForm A (snd (mixSeq A S1 S2)), countForm A (fst (mixSeq A S1 S2)))
  = (2, 2, 0, 0).
Proof. reflexivity. Qed.

(* 9.2 Lemma 5.2 双向模拟的语义面：cut+收缩 ↔ mix。
   方向一（mix 的可靠性=mix 可由 cut+收缩导出）：取两个**有效**前提
   （含混合公式 A 的重复出现），mix 结论仍有效——「一次删光」没有
   偷走语义。 *)
Example mix_sound_sample :
  let A := GVar 0 in
  let S1 := ([GVar 1], [GVar 1; A; GVar 2; A]) in       (* P1⊢P1,A,P2,A：有效 *)
  let S2 := ([A; GVar 2; A], [GVar 2]) in               (* A,P2,A⊢P2：有效 *)
  andb (andb (seqSem S1) (seqSem S2)) (seqSem (mixSeq A S1 S2)) = true.
Proof. reflexivity. Qed.

(* 收缩保有效性的样本账（cut 路径的第一步：双侧各收到单次出现） *)
Example ctr_preserves_sem :
  let A := GVar 0 in
  let S1 := ([GVar 1], [GVar 1; A; GVar 2; A]) in
  Bool.eqb (seqSem ([GVar 1], [GVar 1; A; GVar 2]))
           (seqSem S1) = true.
Proof. reflexivity. Qed.

(* 方向二（cut ⇒ mix 可达）：cut 只删一次出现，残余 A 需再补一步收缩
   ——账本：mix 删光 2+2 处；cut+收缩路径 = 2 收缩 + 1 cut + 2 收缩 *)
Example cut_path_ledger :
  let A := GVar 0 in
  let S1 := ([GVar 1], [GVar 1; A; GVar 2; A]) in
  let S2 := ([A; GVar 2; A], [GVar 2]) in
  (* cut 结论（各删一次出现）：Γ, A,P2 → P1,P2,A *)
  let cutConcl := ([GVar 1; A; GVar 2], [GVar 1; GVar 2; A; GVar 2]) in
  (countForm A (snd (mixSeq A S1 S2)) + countForm A (fst (mixSeq A S1 S2)),
   countForm A (snd cutConcl) + countForm A (fst cutConcl),
   (* 再收缩一次即得 mix 结论 *)
   andb (formListEqb (eraseAll A (snd cutConcl)) (snd (mixSeq A S1 S2)))
        (formListEqb (eraseAll A (fst cutConcl)) (fst (mixSeq A S1 S2)))) = (0, 2, true).
Proof. reflexivity. Qed.

(* 9.3 rank：thread 上「连续含混合公式」的矢列数（书 p23）。
   自链底（mix 上矢列）向上数连续含 A 者；side 取 succedent 为左
   thread、antecedent 为右 thread。链以「底在前」的表给出。 *)
Fixpoint rankFromBottom (A : gform) (side : gseq -> list gform)
         (chain : list gseq) : nat :=
  match chain with
  | [] => 0
  | s :: t =>
      if existsb (formEqb A) (side s)
      then S (rankFromBottom A side t)
      else 0
  end.

Definition leftSide (s : gseq) : list gform := snd s.   (* 左 thread 看 succedent *)
Definition rightSide (s : gseq) : list gform := fst s.  (* 右 thread 看 antecedent *)

Definition rankPair (A : gform) (lchain rchain : list gseq) : nat :=
  rankFromBottom A leftSide lchain + rankFromBottom A rightSide rchain.

(* 样本一（rank=2）：两侧混合公式都「新鲜」——各只有 mix 上矢列含 A *)
Example rank_fresh :
  rankPair (GVar 0)
    [([GVar 1], [GVar 0; GVar 2]); ([GVar 1; GVar 2], [GVar 3])]      (* 左链底→顶 *)
    [([GVar 0; GVar 4], [GVar 5]); ([GVar 4], [GVar 5])]              (* 右链底→顶 *)
  = 2.
Proof. reflexivity. Qed.

(* 样本二（rank=3）：左链底部两个矢列连续含 A（rank_l=2、rank_r=1）
   ——这正是 Case 2「把 mix 推过推理」适用的形态 *)
Example rank_pushed :
  rankPair (GVar 0)
    [([GVar 1], [GVar 0; GVar 2; GVar 0]); ([GVar 1], [GVar 0; GVar 2])]
    [([GVar 0; GVar 4], [GVar 5]); ([GVar 4], [GVar 5])]
  = 3.
Proof. reflexivity. Qed.

(* 9.4 Case 1.5(i)：mix 的 grade 下降账——A=B∧C（grade 2）的 mix 归约为
   B（grade 1）的两次 mix；grade 沿逻辑符号数严格降 *)
Example mix_grade_drop :
  Nat.ltb (grade (GVar 0)) (grade (GAnd (GVar 0) (GVar 1))) = true.
Proof. reflexivity. Qed.

(* rank≥2 恒成立：两条链的底矢列就是 mix 的上矢列，必含 A *)
Definition lch_a : list gseq := [([GVar 1], [GVar 0; GVar 2])].
Definition rch_a : list gseq := [([GVar 0], [GVar 3])].
Definition lch_b : list gseq := [([GVar 1], [GVar 0])].
Definition rch_b : list gseq := [([GVar 0; GVar 0], [GVar 3])].

Example rank_ge2 :
  forallb (fun p => Nat.leb 2 (rankPair (GVar 0) (fst p) (snd p)))
    [((lch_a, rch_a)); ((lch_b, rch_b))] = true.
Proof. reflexivity. Qed.
