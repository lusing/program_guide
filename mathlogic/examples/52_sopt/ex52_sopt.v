(* 第 52 章 二阶算术的证明论：comprehension 谱系与相对化（Takeuti Ch3 §15-§19）
   对书：Def 15.3 BC 基演算（二阶量词规则：左任意实例/右本征变元）、
   例 15.12「模式=代入像」、命题 16.7 有限实例化（文档线）、
   Def 17.1 相对化（量词挂闸门）、引理 17.5 搬运、定理 17.8 解释=一致性传递、
   Def 18.4/引理 18.5/命题 18.6-18.10/定理 18.13 分层真值定义。
   机器面：命题+一阶+二阶命题级三合一小语言；零公理。 *)

Require Import List.
Require Import String.
Open Scope string_scope.
Import ListNotations.

(* ---------- 语言：一阶原子 + 二阶命题变元 + 两层量词 ---------- *)
Inductive s2f : Type :=
| sat   (n v : nat)              (* 一阶原子 R_n(c_v)；v=0 为绑定变元位 *)
| pvar  (n : nat)                (* 二阶命题变元 P_n *)
| sneg  (a : s2f)
| sand  (a b : s2f)
| sor   (a b : s2f)
| simp  (a b : s2f)
| tall  (a : s2f)                (* !x a（x 以绑定位 0 出现） *)
| ttex  (a : s2f)
| pall  (n : nat) (a : s2f)      (* !P_n a *)
| pex   (n : nat) (a : s2f).

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb' {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb' f t) end.
Fixpoint feqb (a b : s2f) : bool :=
  match a, b with
  | sat n v, sat m w => andb (Nat.eqb n m) (Nat.eqb v w)
  | pvar n, pvar m => Nat.eqb n m
  | sneg a1, sneg b1 => feqb a1 b1
  | sand a1 a2, sand b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | sor a1 a2, sor b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | simp a1 a2, simp b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | tall a1, tall b1 => feqb a1 b1
  | ttex a1, ttex b1 => feqb a1 b1
  | pall n a1, pall m b1 => andb (Nat.eqb n m) (feqb a1 b1)
  | pex n a1, pex m b1 => andb (Nat.eqb n m) (feqb a1 b1)
  | _, _ => false
  end.

(* 代入：一阶绑定位 0 -> 常量 t；二阶变元 P_n -> 公式 V *)
Fixpoint substC (a : s2f) (t : nat) : s2f :=
  match a with
  | sat n w => if Nat.eqb w 0 then sat n t else sat n w
  | pvar _ => a
  | sneg b => sneg (substC b t)
  | sand b c => sand (substC b t) (substC c t)
  | sor b c => sor (substC b t) (substC c t)
  | simp b c => simp (substC b t) (substC c t)
  | tall b => tall (substC b t)
  | ttex b => ttex (substC b t)
  | pall n b => pall n (substC b t)
  | pex n b => pex n (substC b t)
  end.

Fixpoint substP (a : s2f) (n : nat) (V : s2f) : s2f :=
  match a with
  | sat _ _ => a
  | pvar m => if Nat.eqb m n then V else pvar m
  | sneg b => sneg (substP b n V)
  | sand b c => sand (substP b n V) (substP c n V)
  | sor b c => sor (substP b n V) (substP c n V)
  | simp b c => simp (substP b n V) (substP c n V)
  | tall b => tall (substP b n V)
  | ttex b => ttex (substP b n V)
  | pall m b => if Nat.eqb m n then pall m b  (* 同名量词遮蔽：不换 *)
                else pall m (substP b n V)
  | pex m b => if Nat.eqb m n then pex m b
               else pex m (substP b n V)
  end.

(* ---------- 语义：有限结构求值 ----------
   一阶谓词表 iext : nat -> nat -> bool（R_n(c_v)）；二阶赋值 g : nat -> bool。
   常量域 CD（教学固定 1..3）；二阶量词跑 {true,false}。 *)
Definition CD : list nat := [1; 2; 3].

(* cur：当前量词绑定常量（绑定位 0 的求值来源；量词深度 1 片段） *)
Fixpoint s2ev (iext : nat -> nat -> bool) (g : nat -> bool) (cur : nat)
              (a : s2f) : bool :=
  match a with
  | sat n 0 => iext n cur
  | sat n (S w) => iext n (S w)
  | pvar n => g n
  | sneg b => negb (s2ev iext g cur b)
  | sand b c => andb (s2ev iext g cur b) (s2ev iext g cur c)
  | sor b c => orb (s2ev iext g cur b) (s2ev iext g cur c)
  | simp b c => implb (s2ev iext g cur b) (s2ev iext g cur c)
  | tall b => forallb (fun t => s2ev iext g t b) CD
  | ttex b => existsb' (fun t => s2ev iext g t b) CD
  | pall n b => andb (s2ev iext (fun m => orb (Nat.eqb m n)
                                                (andb (negb (Nat.eqb m n)) (g m)))
                              cur b)
                      (s2ev iext g cur b)   (* P_n := true / false 两点全查 *)
  | pex n b => orb (s2ev iext (fun m => orb (Nat.eqb m n)
                                             (andb (negb (Nat.eqb m n)) (g m)))
                          cur b)
                   (s2ev iext g cur b)
  end.

(* ---------- 件一：BC 推导检查器 ----------
   规则：ax（D->D）/weak/二阶 !:left（实例化 V 任意）/二阶 !:right（本征 P_q 新）
   ——左任意实例 vs 右本征变元的对偶（Def 15.3 的灵魂）。 *)
Definition sqt := (list s2f * list s2f)%type.

Inductive bdr : Type :=
| bax (s : sqt)
| bwk (s : sqt) (sub : bdr)
| ballL2 (s : sqt) (n : nat) (V : s2f) (sub : bdr)   (* !P_n F 实例化为 F(V) *)
| ballR2 (s : sqt) (n q : nat) (sub : bdr)           (* F(P_q) 本征 q 不入下矢列 *)
| bsimpR (s : sqt) (sub : bdr)                        (* A->B 右引入 *)
| bcut (s : sqt) (a : s2f) (l r : bdr).

(* 前置：子列包含与二阶变元出现检查 *)
Fixpoint inclb (l m : list s2f) : bool :=
  match l with
  | [] => true
  | x :: t => andb (existsb' (feqb x) m) (inclb t m)
  end.

Fixpoint occ1 (a : s2f) (q : nat) : bool :=
  match a with
  | pvar m => Nat.eqb m q
  | sneg b => occ1 b q
  | sand b c => orb (occ1 b q) (occ1 c q)
  | sor b c => orb (occ1 b q) (occ1 c q)
  | simp b c => orb (occ1 b q) (occ1 c q)
  | tall b => occ1 b q
  | ttex b => occ1 b q
  | pall m b => if Nat.eqb m q then false else occ1 b q
  | pex m b => if Nat.eqb m q then false else occ1 b q
  | _ => false
  end.

Fixpoint occursP (l : list s2f) (q : nat) : bool :=
  match l with
  | [] => false
  | x :: t => orb (occ1 x q) (occursP t q)
  end.

Definition sqOf (d : bdr) : sqt :=
  match d with
  | bax s => s
  | bwk s _ => s
  | ballL2 s _ _ _ => s
  | ballR2 s _ _ _ => s
  | bsimpR s _ => s
  | bcut s _ _ _ => s
  end.

Fixpoint bchk (d : bdr) : bool :=
  match d with
  | bax (G, D) => existsb' (fun a => existsb' (feqb a) D) G
  | bwk s sub =>
      andb (bchk sub)
           (match s, sqOf sub with
            | (G, D), (G', D') => andb (inclb G' G) (inclb D' D)
            end)
  | ballL2 (G, D) n V sub =>
      andb (bchk sub)
           (match sqOf sub with
            | (G', D') =>
                existsb' (fun a => match a with
                           | pall m F =>
                               andb (Nat.eqb m n)
                                    (orb (andb (existsb' (feqb (substP F n V)) G')
                                               (existsb' (feqb a) G))
                                         (andb (existsb' (feqb (substP F n V)) D')
                                               (existsb' (feqb a) D)))
                           | _ => false end) (G ++ D)
            end)
  | ballR2 (G, D) n q sub =>
      andb (bchk sub)
           (andb (negb (occursP (G ++ D) q))
                (match sqOf sub with
                 | (G', D') =>
                     existsb' (fun a => match a with
                                | pall m F =>
                                    andb (Nat.eqb m n)
                                         (orb (existsb' (feqb (substP F n (pvar q))) G')
                                              (existsb' (feqb (substP F n (pvar q))) D'))
                                | _ => false end) (G ++ D)
                 end))
  | bsimpR (G, D) sub =>
      andb (bchk sub)
           (existsb' (fun a => match a with
                       | simp A B =>
                           match sqOf sub with
                           | (G', D') => andb (existsb' (feqb A) G')
                                              (existsb' (feqb B) D')
                           end
                       | _ => false end) D)
  | bcut (G, D) a l r =>
      andb (bchk l) (andb (bchk r)
        (match sqOf l, sqOf r with
         | (Gl, Dl), (Gr, Dr) =>
             andb (existsb' (feqb a) Dl) (existsb' (feqb a) Gr)
         end))
  end.

(* BC 账例一：=> !P_0 (P_0 -> P_0)——本征变元 P_1（异于量化变元、不入下矢列）：
   内层 ->:right（P_1 => P_1 公理升为 => P_1 -> P_1），外层二阶 !:right *)
Definition dAllR2 : bdr :=
  ballR2 ([], [pall 0 (simp (pvar 0) (pvar 0))]) 0 1
    (bsimpR ([], [simp (pvar 1) (pvar 1)])
      (bax ([pvar 1], [pvar 1]))).

Example bcAllR_ok : bchk dAllR2 = true.
Proof. reflexivity. Qed.

(* 反例：本征变元 P_1 已出现在下矢列——违规（Def 15.3 eigenvariable 条件） *)
Definition dAllR_bad : bdr :=
  ballR2 ([pvar 1], [pall 0 (simp (pvar 0) (pvar 0))]) 0 1
    (bax ([pvar 1], [pvar 1])).

Example bcAllR_bad : bchk dAllR_bad = false.
Proof. reflexivity. Qed.

(* 左规则：!P_0 P_0 实例化为 P_0 := sat 0 1（任意 V——comprehension 无约束侧） *)
Definition dAllL : bdr :=
  ballL2 ([pall 0 (pvar 0)], []) 0 (sat 0 1)
    (bax ([sat 0 1], [sat 0 1])).

Example bcAllL_ok : bchk dAllL = true.
Proof. reflexivity. Qed.

(* ---------- 件二：相对化翻译器（Def 17.1 量词挂闸门） ---------- *)
Fixpoint rel (r0 : s2f) (a : s2f) : s2f :=
  match a with
  | sat _ _ => a                         (* 原子直过 *)
  | pvar _ => a
  | sneg b => sneg (rel r0 b)
  | sand b c => sand (rel r0 b) (rel r0 c)
  | sor b c => sor (rel r0 b) (rel r0 c)
  | simp b c => simp (rel r0 b) (rel r0 c)
  | tall b => tall (simp r0 (rel r0 b))  (* !x b ↦ !x (D(x) -> b^r) *)
  | ttex b => ttex (sand r0 (rel r0 b))  (* ?x b ↦ ?x (D(x) /\ b^r) *)
  | pall n b => pall n (rel r0 b)        (* 二阶量词闸门：文档线 R^1 *)
  | pex n b => pex n (rel r0 b)
  end.

(* 闸门账例：!x R_0(x) ↦ !x (R_1(x) -> R_0(x)) *)
Example relGate :
  feqb (rel (sat 1 0) (tall (sat 0 0)))
       (tall (simp (sat 1 0) (sat 0 0))) = true.
Proof. reflexivity. Qed.

Example relGateEx :
  feqb (rel (sat 1 0) (ttex (sat 0 0)))
       (ttex (sand (sat 1 0) (sat 0 0))) = true.
Proof. reflexivity. Qed.

(* 语义对账（引理 17.5 的样本面）：全域真 <-> 限域上相对化真。
   结构：R_0 = {c1}，域谓词 D=R_1 = {c1,c2}（c3 在域外）。 *)
Definition iextA : nat -> nat -> bool :=
  fun n v => match n, v with
  | 0, 1 => true
  | 1, 1 | 1, 2 => true
  | _, _ => false
  end.

Example relSemAcct :
  (* ?x R_0(x) 在全域真（c1 见证）；相对化 ?x(D(x)/\R_0(x)) 在同结构真 *)
  andb (s2ev iextA (fun _ => false) 1 (ttex (sat 0 0)))
       (s2ev iextA (fun _ => false) 1
             (rel (sat 1 0) (ttex (sat 0 0)))) = true.
Proof. reflexivity. Qed.

Example relSemAcct2 :
  (* !x R_0(x) 全域假（c2,c3 反例）；相对化 !x(D(x)->R_0(x)) 亦假（c2 在域内反例） *)
  andb (negb (s2ev iextA (fun _ => false) 1 (tall (sat 0 0))))
       (negb (s2ev iextA (fun _ => false) 1
                (rel (sat 1 0) (tall (sat 0 0))))) = true.
Proof. reflexivity. Qed.

(* 域收缩的语义差：!x R_0(x) 与限域版 !x(D->R_0) 在「R_0 域外为假」时分离——
   一致性传递（定理 17.8）为什么无损：翻译把量词关进域内 *)
Definition iextB : nat -> nat -> bool :=   (* R_0 = {c1,c2}（含域外 c2） *)
  fun n v => match n, v with
  | 0, 1 | 0, 2 => true
  | 1, 1 | 1, 2 => true
  | _, _ => false
  end.

Example relSemSplit :
  andb (negb (s2ev iextB (fun _ => false) 1 (tall (sat 0 0))))   (* 全域仍假：c3 反例 *)
       (s2ev iextB (fun _ => false) 1                             (* 限域内真 *)
              (rel (sat 1 0) (tall (sat 0 0)))) = true.
Proof. reflexivity. Qed.

(* ---------- 件三：模式=代入像（例 15.12） ----------
   归纳公理模式 VJ = !P(P(0)/\P(0')->P -> ...) 的命题级化身：
   二阶单句 !P_n F(P) 代入抽象 V 得到每个一阶实例。 *)
Definition indSchema : s2f :=
  pall 0 (simp (sand (pvar 0) (pvar 0)) (pvar 0)).  (* 命题级示意 *)

Definition instOf (sch : s2f) (V : s2f) : s2f :=
  match sch with
  | pall n F => substP F n V
  | _ => sch
  end.

(* 「模式」：对一组 V 生成全部实例——K₁C 的有限实例化（命题 16.7）语义面 *)
Definition instancesOf (sch : s2f) (Vs : list s2f) : list s2f :=
  map (instOf sch) Vs.

Example indInstances :
  Nat.eqb (List.length (instancesOf indSchema
                    (sat 0 1 :: sat 0 2 :: sand (sat 0 1) (sat 0 2) :: nil))) 3 = true.
Proof. reflexivity. Qed.

(* 一阶归纳模式的真实形状（docs 讲解、机器面示意）：
   VJ = !P(P(0) /\ !x(P(x)->P(x')) -> !x P(x))
   ——二阶单句；VJ 实例化 P:={x|B(x)} 得全部一阶归纳公理。 *)

(* ---------- 件四：分层真值定义（Def 18.4/引理 18.5/定理 18.13） ----------
   F(a,n)：「a 是复杂度<=n 层的真值定义」；T = 逐层焊接后的总真值。
   机器面：句子编号 s（0..3 对应 R_0(c1)、R_1(c2)、其否定、其合取），
   alpha : nat->bool 是「句子->真假」表；layerOK 检查 alpha 在层 n 上
   按主联结词条款正确（F 的三条款）；extend 把 alpha 扩张一层（E 的 18.5(4)）。 *)
Definition sentenceValue (iext : nat -> nat -> bool) (s : nat) : bool :=
  (* 句子宇宙（固定四个）：0:R_0(c1) 1:R_1(c2) 2:~R_0(c1) 3:R_0(c1)/\R_1(c2) *)
  match s with
  | 0 => iext 0 1
  | 1 => iext 1 2
  | 2 => negb (iext 0 1)
  | 3 => andb (iext 0 1) (iext 1 2)
  | _ => false
  end.

(* F(alpha,n)：alpha 在 0..3 号句子上与 sentenceValue 一致——「真值定义」 *)
Definition layerOK (iext : nat -> nat -> bool) (alpha : nat -> bool) : bool :=
  forallb (fun s => Bool.eqb (alpha s) (sentenceValue iext s)) [0; 1; 2; 3].

(* E 扩张（引理 18.5(4)）：一层 patch——对第 4 号句子（新增的析取句）定义真值 *)
Definition extend (iext : nat -> nat -> bool) (alpha : nat -> bool)
  : nat -> bool :=
  fun s => match s with
           | 4 => orb (iext 0 1) (iext 1 2)   (* 新句子 R_0(c1)\/R_1(c2) *)
           | _ => alpha s
           end.

(* T 的对易条款（命题 18.8-18.10 的形状）：T(~A) <-> ~T(A) 等三条 *)
Definition truthDef (iext : nat -> nat -> bool) (alpha : nat -> bool) : bool :=
  andb (layerOK iext alpha)                       (* 层内正确 *)
       (andb (Bool.eqb (alpha 2) (negb (alpha 0)))      (* ¬ 条款 *)
             (Bool.eqb (alpha 3) (andb (alpha 0) (alpha 1)))). (* ∧ 条款 *)

(* 一致性：iextA 下 alpha=真实值——T('A') <-> A（定理 18.13 的样本） *)
Definition trueAlpha (iext : nat -> nat -> bool) : nat -> bool :=
  fun s => sentenceValue iext s.

Example tdHolds : truthDef iextA (trueAlpha iextA) = true.
Proof. reflexivity. Qed.

(* 扩张保持（E 的账）：旧层真值不变、新句子获得真值 *)
Example extPreserves :
  andb (truthDef iextA (extend iextA (trueAlpha iextA)))
       (Bool.eqb (extend iextA (trueAlpha iextA) 4)
                (orb (iextA 0 1) (iextA 1 2))) = true.
Proof. reflexivity. Qed.

(* ---------- 件五：S1/S2/S3 谱系表（§19 定义 19.1） ---------- *)
Definition hierarchy : list (nat * string * string) :=
  [ (1, "S1", "算术 comprehension + Pi11 归纳：分层真值 T 在此可定义 PA 的真（18.13）")
  ; (2, "S2", "算术 comprehension + 完全归纳：解释 I 的焊接（19.9）在此成立")
  ; (3, "S3", "Pi11 comprehension + Pi11 归纳：被算术集合内模型解释（19.16 Consis(S3) 在 S2）") ].

Example hierCount : Nat.eqb (List.length hierarchy) 3 = true.
Proof. reflexivity. Qed.
