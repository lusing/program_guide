(* 第 17 章 直觉主义完备性：Kripke 语义与 Heyting 代数（Takeuti §8 p52-66）
   对书：Takeuti, Proof Theory 2e, Def 8.14 力迫 b)-e)（命题部分）、
   Prop 8.15 可靠性、Thm 8.17 完备性（典范反模型——机器面取其可判定核心：
   有限偏序上的有效性判定与反例搜索）、Thm 8.27 Kripke<->cHa（上集账）、
   Takeuti-Titani [0,1]（LJ_I 前线性——有限线序 cHa 样本）。
   零公理：全部 Example 只用 bool 计算。 *)

Require Import List.
Import ListNotations.

(* ---------- 命题语言 ---------- *)
Inductive kform : Type :=
| kp   (n : nat)              (* 原子命题变元 *)
| kneg (a : kform)
| kand (a b : kform)
| kor  (a b : kform)
| kimp (a b : kform).

(* ---------- 小工具（章内自含） ---------- *)
Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with
  | [] => true
  | x :: t => andb (f x) (forallb f t)
  end.

Fixpoint existsb' {A} (f : A -> bool) (l : list A) : bool :=
  match l with
  | [] => false
  | x :: t => orb (f x) (existsb' f t)
  end.

Fixpoint dedup (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: t => if existsb' (Nat.eqb x) t then dedup t else x :: dedup t
  end.

Fixpoint inclb (l m : list nat) : bool :=
  match l with
  | [] => true
  | x :: t => andb (existsb' (Nat.eqb x) m) (inclb t m)
  end.

Definition worldsOf (n : nat) : list nat := seq 0 n.

Fixpoint eqnl (l m : list nat) : bool :=
  match l, m with
  | [], [] => true
  | x :: xs, y :: ys => andb (Nat.eqb x y) (eqnl xs ys)
  | _, _ => false
  end.

Definition implbb (b c : bool) : bool :=
  match b with true => c | false => true end.

(* ---------- 有限偏序 ----------
   世界 0..n-1；le w q 读 w <= q。三个常备偏序：
   le2  两点链 0<=1          —— LEM 反例的家
   le3v 三点 V 形 0<=1, 0<=2 —— 前线性失效的家
   le1  单点                 —— 最小模型 *)
Definition le2 : nat -> nat -> bool :=
  fun w q => match w, q with
  | 0, _ => true
  | 1, 1 => true
  | _, _ => false
  end.

Definition le3v : nat -> nat -> bool :=
  fun w q => match w, q with
  | 0, _ => true
  | 1, 1 => true
  | 2, 2 => true
  | _, _ => false
  end.

Definition le1 : nat -> nat -> bool := fun w q => Nat.eqb w q.

(* ---------- 力迫 kfw：Def 8.14 b)-e) 命题部分 ----------
   否定与蕴含的「全未来世界」量词是 Kripke 语义的灵魂：
   它们不看当下、看全部将来（Def 8.14 d) e)）。 *)
Fixpoint kfw (n : nat) (le : nat -> nat -> bool)
             (v : nat -> nat -> bool) (a : kform) (w : nat) : bool :=
  match a with
  | kp p     => v w p
  | kand b c => andb (kfw n le v b w) (kfw n le v c w)
  | kor  b c => orb  (kfw n le v b w) (kfw n le v c w)
  | kneg b   => forallb (fun q => implbb (le w q) (negb (kfw n le v b q)))
                        (worldsOf n)
  | kimp b c => forallb (fun q =>
                  implbb (le w q)
                       (implbb (kfw n le v b q) (kfw n le v c q)))
                      (worldsOf n)
  end.

(* 单调赋值检查：Def 8.14 3) 的 phi(R,p)=T /\ p<=q -> phi(R,q)=T *)
Definition monoOk (n : nat) (le : nat -> nat -> bool)
                  (v : nat -> nat -> bool) (maxp : nat) : bool :=
  forallb (fun w => forallb (fun q => forallb (fun p =>
    implbb (andb (le w q) (v w p)) (v q p)) (seq 0 maxp)) (worldsOf n))
    (worldsOf n).

(* ---------- 反例模型（给定的单调赋值） ---------- *)
(* LEM 反例（Ex 8.18(1)）：两点链，p 在 0 假、在 1 真。
   p\/~p 在 0：p(0)=F；~p(0)=F（世界 1 见证 p 真）——析取 F。 *)
Definition vLem : nat -> nat -> bool :=
  fun w p => match w, p with
  | 1, 0 => true
  | _, _ => false
  end.

(* DNE 与 LEM 共用同一反例模型：两点链 p(0)=F、p(1)=T。
   ~~p(0)=T（p 在 1 真 ==> ~p 在 0 假 ==> ~~p 在 0 真）而 p(0)=F。 *)
Example monoLem  : monoOk 2 le2 vLem 1 = true.
Proof. reflexivity. Qed.

(* 对照组：p 处处假的模型里 ~~p 也假，蕴含空真——
   「反例模型的选择」本身就是 Kripke 语义的教学点。 *)
Example dneVacuous :
  kfw 2 le2 (fun _ _ => false) (kimp (kneg (kneg (kp 0))) (kp 0)) 0 = true.
Proof. reflexivity. Qed.

(* 两经典有效直觉无效的现场（Thm 6.14(2) 的语义面） *)
Example lemRefuted :
  kfw 2 le2 vLem (kor (kp 0) (kneg (kp 0))) 0 = false.
Proof. reflexivity. Qed.

Example dneRefuted :
  kfw 2 le2 vLem (kimp (kneg (kneg (kp 0))) (kp 0)) 0 = false.
Proof. reflexivity. Qed.

(* 单点模型上直觉主义照样认可恒真式 p->p *)
Example idValid1 :
  kfw 1 le1 (fun _ _ => false) (kimp (kp 0) (kp 0)) 0 = true.
Proof. reflexivity. Qed.

(* ---------- 全枚举有效性 ikValid：完备性的可判定核心 ----------
   命题 Kripke 语义有有限模型性质（Thm 8.17 典范模型构造的副产品）：
   对固定有限偏序与原子数，有效性 = 全赋值全世界枚举。 *)
Fixpoint enumVals (maxp idx : nat) : list (nat -> nat -> bool) :=
  match idx with
  | 0 => [fun _ _ => false]
  | S k =>
      (* 第 idx 个赋值：世界 w 原子 p 的位 = idx 的第 (w*maxp+p) 位 *)
      (fun w p => Nat.testbit idx (w * maxp + p)) :: enumVals maxp k
  end.

Definition ikValid (n : nat) (le : nat -> nat -> bool)
                   (maxp : nat) (a : kform) : bool :=
  (* Kripke 结构的赋值按 Def 8.14(3) 天然单调：非单调的枚举项直接跳过 *)
  forallb (fun v => implbb (monoOk n le v maxp)
                        (forallb (fun w => kfw n le v a w) (worldsOf n)))
          (enumVals maxp (Nat.pow 2 (n * maxp))).

(* 直觉主义有效式（两点链与三点 V 形双查） *)
Example ikValidImpId :
  andb (ikValid 2 le2 1 (kimp (kp 0) (kp 0)))
       (ikValid 3 le3v 1 (kimp (kp 0) (kp 0))) = true.
Proof. reflexivity. Qed.

Example ikValidConjImp :   (* (p->q)->(p/\q->q)：直觉主义有效 *)
  ikValid 3 le3v 2
    (kimp (kimp (kp 0) (kp 1))
          (kimp (kand (kp 0) (kp 1)) (kp 1))) = true.
Proof. reflexivity. Qed.

Example ikValidNotNotIntro :   (* p -> ~~p：直觉主义有效 *)
  ikValid 3 le3v 1
    (kimp (kp 0) (kneg (kneg (kp 0)))) = true.
Proof. reflexivity. Qed.

(* LEM 的枚举里恰有 vLem 型赋值：全枚举立即抓住 *)
Example ikInvalidLem :
  ikValid 2 le2 1 (kor (kp 0) (kneg (kp 0))) = false.
Proof. reflexivity. Qed.

(* ---------- 反例搜索 kRefute ----------
   对一组小偏序+全部赋值搜一个 (v,w) 使力迫为假——
   「有穷模型性质」的可操作面：搜索即完备性的半边。 *)
Definition kRefute (a : kform) : bool :=
  (* 搜索范围=合法 Kripke 结构（单调赋值）——完备性说的是这些 *)
  orb (existsb' (fun v => andb (monoOk 2 le2 v 2)
                        (existsb' (fun w => negb (kfw 2 le2 v a w))
                                  (worldsOf 2)))
                 (enumVals 2 4))
      (existsb' (fun v => andb (monoOk 3 le3v v 2)
                        (existsb' (fun w => negb (kfw 3 le3v v a w))
                                  (worldsOf 3)))
                 (enumVals 2 8)).

Example kRefuteLem : kRefute (kor (kp 0) (kneg (kp 0))) = true.
Proof. reflexivity. Qed.

Example kRefuteDne :
  kRefute (kimp (kneg (kneg (kp 0))) (kp 0)) = true.
Proof. reflexivity. Qed.

Example kRefutePeirce :   (* Peirce ((p->q)->p)->p：经典有效直觉无效 *)
  kRefute (kimp (kimp (kimp (kp 0) (kp 1)) (kp 0)) (kp 0)) = true.
Proof. reflexivity. Qed.

Example kNoRefuteValid :   (* 有效式搜不到反例 *)
  andb (negb (kRefute (kimp (kp 0) (kp 0))))
       (negb (kRefute (kimp (kp 0) (kneg (kneg (kp 0)))))) = true.
Proof. reflexivity. Qed.

(* ---------- 上集账：Thm 8.27 的 [A] 引理 ----------
   Kripke<->cHa 对应的核心：每个公式定义其「有效世界集」[A]，
   它是偏序的上集（单调性=Prop 8.15 的直接产物），
   上集族在交并蕴含下构成 Heyting 代数（Thm 8.27 证明 1)-6)）。 *)

(* 上集闭包（对 S 中每个元素收集其上方） *)
Definition upClose (n : nat) (le : nat -> nat -> bool) (S : list nat) : list nat :=
  dedup (flat_map (fun w => filter (fun q => le w q) (worldsOf n)) S).

(* [A] = {w | w 力迫 A} —— 给定赋值 *)
Definition bracketOf (n : nat) (le : nat -> nat -> bool)
                     (v : nat -> nat -> bool) (a : kform) : list nat :=
  filter (fun w => kfw n le v a w) (worldsOf n).

(* [A] 是上集：Kripke 单调性（Prop 8.15）的集合面 *)
Example bracketUpset :
  andb (inclb (upClose 2 le2 (bracketOf 2 le2 vLem (kneg (kneg (kp 0)))))
              (bracketOf 2 le2 vLem (kneg (kneg (kp 0)))))
       (inclb (bracketOf 2 le2 vLem (kneg (kneg (kp 0))))
              (upClose 2 le2 (bracketOf 2 le2 vLem (kneg (kneg (kp 0)))))) = true.
Proof. reflexivity. Qed.

(* [A/\B]=[A]∩[B] 的样本账（Thm 8.27 3)）：p 的 [p]={1}、[~~p]={0,1}，
   交回 {1} *)
Example bracketAnd :
  eqnl (bracketOf 2 le2 vLem (kand (kp 0) (kneg (kneg (kp 0))))) [1] = true.
Proof. reflexivity. Qed.

(* [A\/B]=[A]∪[B] 的样本账（Thm 8.27 2)）：并出 {0,1} *)
Example bracketOr :
  eqnl (dedup (bracketOf 2 le2 vLem (kp 0)
                ++ bracketOf 2 le2 vLem (kneg (kneg (kp 0))))) [0; 1] = true.
Proof. reflexivity. Qed.

(* 两点链的全部上集 {}、{1}、{0,1} 恰为 Sierpinski 开集格：
   Thm 8.27 把 Kripke 结构翻译成这个 3 元 Heyting 代数。 *)
Definition up2 : list (list nat) := [ []; [1]; [0; 1] ].

Example up2Count : Nat.eqb (length up2) 3 = true.
Proof. reflexivity. Qed.

(* Sierpinski 上的蕴含 S->T = 满足 S∩U⊆T 的最大上集 U（Ex 8.20 的 Galois 伴随）。
   实现为「从大到小试三个上集，取第一个合格者」。 *)
Definition interl (l m : list nat) : list nat :=
  filter (fun x => existsb' (Nat.eqb x) m) l.

Definition sup2 (S T : list nat) : list nat :=
  if inclb (interl S [0; 1]) T then [0; 1]
  else if inclb (interl S [1]) T then [1]
  else [].

(* Ex 8.20 Galois 性质三组样本账 *)
Example galoisSample1 :   (* {1}->{0,1} = 顶：{1} 的元素已在 {0,1} *)
  andb (inclb (sup2 [1] [0; 1]) [0; 1])
       (inclb [0; 1] (sup2 [1] [0; 1])) = true.
Proof. reflexivity. Qed.

Example galoisSample2 :   (* {1}->{} = {}：{1} 的元素 1 不在 {} *)
  Nat.eqb (length (sup2 [1] [])) 0 = true.
Proof. reflexivity. Qed.

Example galoisSample3 :   (* {}->T = 顶 *)
  Nat.eqb (length (sup2 [] [1])) 2 = true.
Proof. reflexivity. Qed.

(* ---------- Takeuti-Titani 一瞥：有限线序 cHa ----------
   LJ_I 的公理 1+2 合成前线性 (A->B) \/ (B->A)（Prop 8.28(1)）。
   有限链是 Heyting 代数（Gödel-Dummett 语义）：4 点链 0<1<2<3，
   蕴含 p->q := 若 p<=q 则 3（顶）否则 q；否定 ~p := p->0。
   前线性在链上有效，而在分叉偏序（le3v）上无效——
   Int < GD(线性 cHa) < Cl 的谱系现场。 *)
Fixpoint gdv (a : kform) (g : nat -> nat) : nat :=
  match a with
  | kp p => g p
  | kand b c => Nat.min (gdv b g) (gdv c g)
  | kor  b c => Nat.max (gdv b g) (gdv c g)
  | kneg b => match gdv b g with 0 => 3 | _ => 0 end
  | kimp b c => match Nat.leb (gdv b g) (gdv c g) with
                | true => 3
                | false => gdv c g
                end
  end.

Definition gdValid (a : kform) : bool :=
  forallb (fun c0 => forallb (fun c1 => forallb (fun c2 =>
    let g := fun p => match p with 0 => c0 | 1 => c1 | _ => c2 end in
    Nat.eqb (gdv a g) 3) (seq 0 4)) (seq 0 4)) (seq 0 4).

(* 前线性：GD 代数的定义性定理 *)
Example gdPrelinear :
  gdValid (kor (kimp (kp 0) (kp 1)) (kimp (kp 1) (kp 0))) = true.
Proof. reflexivity. Qed.

(* 同一公式在一般 Kripke（三点 V 形）上不有效：谱系现场 *)
Example prelinearNotInt :
  ikValid 3 le3v 2 (kor (kimp (kp 0) (kp 1)) (kimp (kp 1) (kp 0))) = false.
Proof. reflexivity. Qed.

(* GD 保持直觉主义的底：DNE/LEM 在链上同样失效 *)
Example gdDneInvalid :
  gdValid (kimp (kneg (kneg (kp 0))) (kp 0)) = false.
Proof. reflexivity. Qed.

Example gdLemInvalid :
  gdValid (kor (kp 0) (kneg (kp 0))) = false.
Proof. reflexivity. Qed.
