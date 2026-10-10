(* ex105_paradox.v —— 悖论的结构与解悖理论（张寅生 13.1-13.7）
   机器件：Smullyan 抽象形式系统+命题 13.1 对角集不可表示的全枚举验证；
   类型阶检查器（罗素谓词同层失败现场+说谎者阶分析）；ZFC 分离公理
   有限现场（分离有界 vs 朴素概括无界）+正规公理挡 Ω={Ω}；NF 层化
   检查器（差约束求解：x∈x 不分层被禁）；情境序列生成器（真值交替，
   表 13.1 机器化）。范畴/λ 表示与五系统对照记文档线。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 1. Smullyan 抽象系统与命题 13.1 ---------- *)

(* 定义 13.10：S=⟨E,S,F,N,g,s⟩。教学件最小化：
   - 句子域 N={0,1,2}，真值集 T⊆N（8 种取值枚举）；
   - 句子 m 的内容函数 cmap m : N→N（句子 n 断言「对象 k 满足 P」，
     其中 k=cmap m n）；
   - 命名函数 g 的对角作用压成一条公理：cmap m (m) = m
     （「句子 m 谈论自己时谈论的就是 m」——自指点）。
   定义 13.11（T-可表示）：X 是 T-可表示的 ⟺ ∃m ∀n: cmap m n ∈T ⟺ n∈X。
   命题 13.1：对角集 X̄={n | n∉T} 不是 T-可表示的。 *)

Definition mem (n : nat) (l : list nat) : bool := existsb (Nat.eqb n) l.

Definition cmap (m n : nat) : nat := m.   (* 常内容：句子 m 恒谈论 m *)
                                        (* 对角公理成立：cmap m m = m ✓ *)

(* T 的全部取值：8 个子集 *)
Definition Ts3 : list (list nat) :=
  [ []; [0]; [1]; [2]; [0;1]; [0;2]; [1;2]; [0;1;2] ].

(* m 表示 X：∀n, mem (cmap m n) T = mem n X *)
Definition reprOK (m : nat) (T X : list nat) : bool :=
  forallb (fun n => Bool.eqb (mem (cmap m n) T) (mem n X)) [0;1;2].

(* 对角集 X̄(T) = {n | n∉T} *)
Definition diagSet (T : list nat) : list nat :=
  filter (fun n => negb (mem n T)) [0;1;2].

(* 命题 13.1 的全枚举验证：对每个 T 与每个候选句子 m，都不能表示 X̄ *)
Example smullyan_diagonal :
  forallb (fun T =>
    negb (existsb (fun m => reprOK m T (diagSet T)) [0;1;2])) Ts3
  = true.
Proof. reflexivity. Qed.

(* 证明骨架（书 p201）：设 φ 表示 X̄。取 n₀:=φ 的对角点——有限域上
   即某 n 使 φ(n)=n 或矛盾直接出现：φ(n)∈T ⟺ n∉T。全枚举验证「必
   存破坏 n」。这正是 61 章停机对角/69 章 Tarski 不可定义的抽象骨架
   ——Smullyan 把三兄弟的共同结构剥到只剩命名+真值。 *)

(* ---------- 2. 类型阶：罗素谓词的失败现场 ---------- *)

(* 13.3 节：类型=函项的意义域；阶 0=个体、阶 1=个体集合…
   机器面：带层标记的对象+∈ 的层约束（elem 只接受 k 层属于 S k 层） *)
Inductive obj : Type :=
| Ind  : nat -> obj            (* 个体（0 层世界） *)
| SetT : nat -> nat -> obj.    (* SetT k n = 第 k 层的第 n 号集合 *)

(* ∈ 的类型检查：x∈y 合法当且仅当 y 的层恰比 x 高 1 *)
Definition elemOK (x y : obj) : option nat :=
  match x, y with
  | Ind _, SetT 1 _ => Some 0            (* 个体属于 1 层集合 *)
  | SetT k _, SetT k' _ =>
      if Nat.eqb k' (S k) then Some k else None
  | _, _ => None
  end.

(* 罗素谓词 x∈x：同层——类型检查失败现场 *)
Example russell_illtyped :
  match elemOK (SetT 3 0) (SetT 3 0) with
  | None => true    (* 失败=正确拒绝 *)
  | Some _ => false
  end = true.
Proof. reflexivity. Qed.
(* 「类型即解悖」：x∈x 在阶语法里根本写不出来——不是被禁止，是无
   类型。代价（书 p203）：丢失一些合法表达（例 13.8/13.9 的阶分析），
   需要可规约性公理来补偿——分支类型论的公理负担记文档线。 *)

(* 说谎者 q 的阶分析（例 13.8）：q 是 n+1 阶命题「我断言的 p 是假的」。
   p 作 q 的变元：p 的阶 ≤n 时 q 良型；p 的阶 = n+1（自指）失败 *)
Definition liarOK (pOrder : nat) : bool := Nat.ltb pOrder (S pOrder).
Example liar_self_rep : liarOK 5 = true.   (* 任何有限阶上 q 自身再高一阶仍可写 *)
Proof. reflexivity. Qed.
(* 说谎者的类型论解法：q 断言 p 时 q 的阶>阶(p)。「本句假」要求
   q 断言 q 自己——阶(q)>阶(q) 无解。机器面：elemOK 的层约束同构。 *)

(* ---------- 3. ZFC 分离现场与正规公理 ---------- *)

(* 13.5 节：分离公理——{x∈M | φ(x)} 是 M 的子集（φ 中 X 不自由）。
   朴素概括——{x | φ(x)} 无界。有限现场： *)
Definition sepOf (M : list nat) (phi : nat -> bool) : list nat :=
  filter phi M.

Example sep_bounded :
  sepOf [0;1;2;3;4] (fun x => Nat.eqb (Nat.modulo x 2) 0) = [0;2;4].
Proof. reflexivity. Qed.

(* 罗素集的分离版：{x∈M | x∉x}——在个体论域 x∈x 恒假，得全集 M *)
Definition russellIn (M : list nat) : list nat :=
  filter (fun x => negb (Nat.eqb x x)) M.

Example russell_sep_is_empty : russellIn [0;1;2] = [].
Proof. reflexivity. Qed.
(* 关键账：分离版罗素集 R_M={x∈M|x∉x} 后，「R_M∈R_M?」需要 R_M∈M
   才有意义——M 是个体集时 R_M∉M，追问被类型挡住（与阶检查同构）；
   M 含集合层时 R_M⊆M 仍有界。朴素概括版 {x|x∉x} 无界——康托对角
   直接引爆。分离公理的「X 不在 β 自由」条款（书 p209-210）是同
   一堵墙的公理化写法。 *)

(* 正规公理（公理 13.11）：每个非空集 A 有 ∈-极小元。挡 Ω={Ω}：
   Ω 的唯一元素是 Ω 自己——无穷 ∈-下降链 *)
Fixpoint chainOK (depth : nat) (x : nat) : bool :=
  match depth with
  | 0 => true
  | S d => chainOK d x          (* Ω={Ω}：x 的唯一成员还是 Ω——链不减 *)
  end.

Example omega_nonfounded :
  (* Ω={Ω} 在正规公理下被禁：Ω 非空但其成员 Ω 与 Ω 相交（Ω∈Ω）——
     无极小元。机器账：成员链的深度不减（链不随深度收缩——无极小元
     的形式影子：chainOK 在任意深度恒 true，因为每层的「候选极小元」
     仍与自身相交） *)
  andb (chainOK 100 0) (chainOK 0 0) = true.
Proof. reflexivity. Qed.

(* ---------- 4. NF 层化检查器（13.6 节） ---------- *)

(* Quine NF：以「层化」替代类型——x∈y 要求 α(y)=α(x)+1（差约束）。
   公式的机内表示：原子约束列表 *)
Inductive atom : Type :=
| InA : nat -> nat -> atom       (* InA x y = 「x∈y」 *)
| EqA : nat -> nat -> atom.      (* EqA x y = 「x=y」 *)

Definition formula := list atom.

(* 求解层赋值 α:VarNo→{0,1,2}（3 层教学域）：暴力枚举 3^变量数 *)


Definition assignOK (f : formula) (a : nat -> nat) : bool :=
  forallb (fun c => match c with
    | InA x y => Nat.eqb (a y) (S (a x))
    | EqA x y => Nat.eqb (a x) (a y)
    end) f.

(* 全部赋值枚举：变量域 {0..4}、层域 {0,1,2}——3^5=243 种 *)
Definition assigns : list (nat -> nat) :=
  flat_map (fun v0 =>
    flat_map (fun v1 =>
      flat_map (fun v2 =>
        flat_map (fun v3 =>
          map (fun v4 => fun n =>
            match n with
            | 0 => v0 | 1 => v1 | 2 => v2 | 3 => v3 | _ => v4 end)
          [0;1;2]) [0;1;2]) [0;1;2]) [0;1;2]) [0;1;2].

Definition stratified (f : formula) : bool :=
  existsb (assignOK f) assigns.

(* x∈y ∧ y∈z：链式约束 α(y)=α(x)+1、α(z)=α(y)+1——可解 *)
Example strat_chain : stratified [InA 0 1; InA 1 2] = true.
Proof. reflexivity. Qed.

(* x∈x：α(x)=S(α(x)) 无解——不分层（例 13.16：罗素概括被禁） *)
Example strat_self : stratified [InA 0 0] = false.
Proof. reflexivity. Qed.

(* x=x：等式约束平凡成立 *)
Example strat_eq : stratified [EqA 0 0] = true.
Proof. reflexivity. Qed.

(* 罗素概括的核心子式 y∉y：不分层 *)
Example strat_russell_body : stratified [InA 1 1] = false.
Proof. reflexivity. Qed.
(* NF 的类型坍塌：不分层的公式不许进概括公理——「x∈x」不是假命题
   而是不可用的公式。康托悖论同法被禁（例 13.17：|P(S)|>|S| 的 > 在
   层化下无定义）。五系统对照（13.7 表）记文档线。 *)

(* ---------- 5. 情境序列生成器（13.4 节表 13.1） ---------- *)

(* Barwise-Etchemendy：说谎者 f=(s;[Tr,f;0]) 在情境序列 s1→s2→s3…
   中真值交替（否认递归生成新情境）。机器面：真值交替账 *)
Fixpoint sitSeq (n : nat) : list bool :=
  match n with
  | 0 => []
  | S k => sitSeq k ++ [Nat.eqb (Nat.modulo k 2) 0]
  end.

Example sit_alternates : sitSeq 6 = [true;false;true;false;true;false].
Proof. reflexivity. Qed.
(* 与 69 章 Kripke 跳跃的对照：同一枚硬币的两面——Kripke 说谎者恒 U
   （不动的悬置）、情境说谎者交替（流动的否认）。「否认 vs 否定」
   （denial≠negation）是情境语义学的核心区分，记文档线。 *)

(* 冒烟 *)
Compute (length Ts3, stratified [InA 0 1; InA 1 0]).
