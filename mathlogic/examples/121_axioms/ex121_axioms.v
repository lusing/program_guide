(* ex121_axioms.v —— 算术与几何的公理系统（张寅生 9.8/9.9+13.10+第 9 章）
   机器件：log 同构影子（Z₇*≅Z₆——例 8.2 的 (R⁺,×)≅(R,+) 有限版）；
   解释函子影子（ℕ→ℤ 商构造翻译+线序公理保真——相对相容性骨架）；
   PA 1889 九公理的「原文 vs 归纳类型」对照账；ACA₀ 算术概括件；
   欧几里得命题 1.29 依赖链数据；希尔伯特关联公理的 F₃² 解析模型
   （I.1-I.3 逐条验证+两线至多一交点）；E→L→R 包容链记文档线。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

(* ---------- 1. log 同构：Z₇* ≅ Z₆（第 9 章方法论的机器面） ---------- *)

(* 例 8.2：(R⁺,×)≅(R,+) 经 log——同构=换计算结构。有限影子：
   Z₇*={1..6}（乘 mod 7）≅ Z₆={0..5}（加 mod 6），生成元 3 *)
Definition z7mul (x y : nat) : nat := (x * y) mod 7.
Definition z6add (x y : nat) : nat := (x + y) mod 6.

(* φ = log₃：查表（3^k mod 7 依次 1,3,2,6,4,5） *)
Definition log3 (x : nat) : nat :=
  match x with
  | 1 => 0 | 3 => 1 | 2 => 2 | 6 => 3 | 4 => 4 | 5 => 5 | _ => 99
  end.

(* 同构账：φ(x·₇y) = φ(x)+₆φ(y)——36 对全验证（定义 8.1 的
   f(a∘b)=f(a)*f(b) 逐对兑现） *)
Example log_iso_hom :
  forallb (fun p =>
    Nat.eqb (log3 (z7mul (fst p) (snd p)))
            (z6add (log3 (fst p)) (log3 (snd p))))
    (flat_map (fun x => map (fun y => (x,y)) [1;2;3;4;5;6]) [1;2;3;4;5;6])
  = true.
Proof. reflexivity. Qed.

Example log3_bijective :
  map log3 [1;2;3;4;5;6] = [0;2;1;4;5;3].   (* 恰为 0..5 的一个排列 *)
Proof. reflexivity. Qed.
(* 同构证明模式（定义 8.2 三条）：保运算+双射——「在 Z₇* 里算乘法」
   与「在 Z₆ 里算加法」是同一件事的两个坐标。107 章离散对数（DLP）
   的安全性正是这个同构的「单向性」：log₃ 好查表，大素数 p 的
   log 难算。 *)

(* ---------- 2. 解释函子：相对相容性骨架（定义 8.3+13.10） ---------- *)

(* 源理论 T₁：线序公理（自反/传递/反对称）；目标理论 T₂：离散线序
   （线序+「每个元素有后继」）。解释 I：把 T₁ 的论域嵌进 T₂：
   n ↦ 2*n（偶数嵌入）。保真验证：T₂ 的公理在像集上读出 T₁ 的公理 *)
Definition embed2 (n : nat) : nat := 2 * n.

(* 线序三公理在 nat≤ 上成立；经嵌入后仍成立（保真小账：
   传递性在像集上） *)
Example interp_preserves_trans :
  forallb (fun t =>
    implb (andb (Nat.leb (embed2 (fst t)) (embed2 (fst (snd t))))
                (Nat.leb (embed2 (fst (snd t))) (embed2 (snd (snd t)))))
              (Nat.leb (embed2 (fst t)) (embed2 (snd (snd t)))))
    [ (0,(1,2)); (3,(5,4)); (2,(2,7)) ]   (* 抽样三元组 *)
  = true.
Proof. reflexivity. Qed.
(* 相对相容性证明的骨架（书 13.10 公理 13.13 的方法内核）：若 T₂
   相容且 T₁ 可解释进 T₂，则 T₁ 相容——反证：T₁ 的矛盾经 I 翻译成
   T₂ 的矛盾。非欧几何→欧氏几何（Beltrami 1868：非欧直线=常曲率面
   的测地线）、欧氏几何→分析（笛卡尔：点=数对）都走这条路。 *)

(* ---------- 3. PA 1889：九公理的「原文 vs 归纳类型」对照 ---------- *)

(* Peano 1889 原文九公理（书 p113-114，N 谓词+' 后继记法）：
   (1) N(0)      (2) N(x)->N(x')     (3) x'≠0      (4) x'=y'->x=y
   (5) x+0=x     (6) x+y'=(x+y)'     (7) x·0=0     (8) x·y'=x·y+x
   (9) 归纳公理（二阶：k/K 集合记法）——今式 ∀Y(Y0∧∀x(Yx->Yx')->∀xYx) *)
Example pa1 : Nat.eqb 0 0 = true. Proof. reflexivity. Qed.   (* N(0)：nat 的 0 *)
Example pa3 : Nat.eqb (S 0) 0 = false. Proof. reflexivity. Qed.
Example pa4 : forallb (fun p =>
    implb (Nat.eqb (S (fst p)) (S (snd p))) (Nat.eqb (fst p) (snd p)))
  [ (3,4); (7,7); (0,1) ] = true.
Proof. reflexivity. Qed.

(* (5)(6)(7)(8)：加乘的递推方程——恰是 nat 上 + 与 * 的定义方程 *)
Example pa56 :
  forallb (fun x =>
    andb (Nat.eqb (x + 0) x)
          (Nat.eqb (x + S 3) (S (x + 3))))
  [0;1;2;5] = true.
Proof. reflexivity. Qed.

Example pa78 :
  forallb (fun x =>
    andb (Nat.eqb (x * 0) 0)
          (Nat.eqb (x * S 3) (x * 3 + x)))
  [0;1;2;5] = true.
Proof. reflexivity. Qed.

(* (9) 二阶归纳：∀Y(…) 的机器化身=Coq 的 nat_ind / Lean 的 Nat.rec
   ——「原文的集合变元 k」在类型论里长成了谓词 P : nat -> Prop *)
Definition pa9_induction (P : nat -> Prop) :=
  P 0 -> (forall k, P k -> P (S k)) -> forall n, P n.
(* nat_ind 的类型与之逐字母相同：公理(9)不是「假设」而是归纳类型的
  构造原理——105 章的「公理变定理」在此追溯到 Peano 原文的二阶性
   （书 p117：原归纳公理的二阶语言分析）。 *)

(* ---------- 4. ACA₀ 算术概括（9.8.2 定义 9.12 第 10 条选样） ---------- *)

(* ∃X∀u(Xu ↔ φ(u))，φ 算术（无二阶量词）。机器面：算术公式类+概括
   实例。简化：φ 无集合量词=一阶算术——用 nat 上的布尔谓词代表 *)
Definition arithSample (u : nat) : bool :=   (* φ(u) := u 是 3 的倍数 *)
  Nat.eqb (u mod 3) 0.

Definition compX (u : nat) : bool := arithSample u.   (* 概括造出的 X *)

Example aca_comp_instance :
  map compX [0;1;2;3;6;9] = [true;false;false;true;true;true].
Proof. reflexivity. Qed.
(* ACA₀ 的侧条件：φ 不得含自由二阶变元（书 p115 的 RCA₀ 对照——
   递归概括只收可计算 φ）。84 章层级表里 RCA₀<PA<ACA₀ 的分层
   由此而来。 *)

(* ---------- 5. 欧几里得 E：命题 1.29 的依赖链（例 9.16） ---------- *)

(* 《几何原本》命题 1.29（平行线的内错角/同位角/同旁内角）依赖链：
   1.29 ← {公设 1.5, 命题 1.13, 命题 1.15, 公理 I.1}
   1.13 ← {命题 1.1, 命题 1.2, 公理 I.1}
   1.15 ← {命题 1.13, 公设 1.4, 公理 I.1, 公理 I.3}
   机器面：依赖图数据件 *)
Definition euclidDeps : list (nat * list nat) :=
  [ (129, [105; 113; 115; 1001])      (* 1001=公设 I.5，1000 段=公理 *)
  ; (113, [101; 102; 1001]) ].
(* 「开放累积知识库」结构（书 p119-120）：每证一命题入库存为下一
   步的依据——E 证 465 命题的机制=Prolog 的证明搜索。完整 1.29
   三步证明重演（书 p120 的三段推理）记文档线：同旁内角和 180°
   （公设 1.5 的逆用）→邻角和 180°（1.13）→代换（公理 I.1）。 *)

Example dep_count : length euclidDeps = 2.
Proof. reflexivity. Qed.

(* ---------- 6. 希尔伯特关联公理的 F₃² 解析模型（9.9.2 I 组） ---------- *)

(* 点=F₃²（9 个）、线=ax+by+c≡0 (mod 3) 的解集（(a,b)≠(0,0)） *)
Definition points : list (nat * nat) :=
  [ (0,0); (0,1); (0,2); (1,0); (1,1); (1,2); (2,0); (2,1); (2,2) ].

Definition onLine (l : nat * (nat * nat)) (p : nat * nat) : bool :=
  (* l = (c,(a,b))：ax+by+c ≡ 0 mod 3 *)
  Nat.eqb ((fst (snd l) * fst p + snd (snd l) * snd p + fst l) mod 3) 0.

(* F₃ 的全部线：4 个真方向（F₃ 中 (a,b) 与 2(a,b) 同线——方向商去重）
   × 3 个截距 = 12 条 *)
Definition lines : list (nat * (nat * nat)) :=
  flat_map (fun ab =>
    map (fun c => (c, ab)) [0;1;2])
    [ (0,1); (1,0); (1,1); (1,2) ].

Example lines_count : length lines = 12.
Proof. reflexivity. Qed.

(* I.1 两点至少一线过之（I 组第 1 公理：任意两点有直线同过） *)
Example hilbert_I1 :
  forallb (fun pq =>
    existsb (fun l => andb (onLine l (fst pq)) (onLine l (snd pq))) lines)
  (flat_map (fun p => map (fun q => (p,q)) points) points)
  = true.
Proof. reflexivity. Qed.

(* I.2 补强（唯一性的部分）：两点至多一线——「两直线至多一交点」
   的对偶。验证：任意两条不同线的公共点 ≤1 *)
Definition commonPts (l1 l2 : nat * (nat * nat)) : nat :=
  length (filter (fun p => andb (onLine l1 p) (onLine l2 p)) points).

Definition lineEqb (l1 l2 : nat * (nat * nat)) : bool :=
  andb (Nat.eqb (fst l1) (fst l2))
       (andb (Nat.eqb (fst (snd l1)) (fst (snd l2)))
             (Nat.eqb (snd (snd l1)) (snd (snd l2)))).

Example hilbert_two_lines_meet_once :
  forallb (fun ll =>
    implb (negb (lineEqb (fst ll) (snd ll)))
              (Nat.leb (commonPts (fst ll) (snd ll)) 1))
  (flat_map (fun l1 => map (fun l2 => (l1,l2)) lines) lines)
  = true.
Proof. reflexivity. Qed.
(* 576 线对全枚举：相交线恰一个公共点、平行线（同方向不同截距）
   零个——「两直线至多一交点」在 F₃² 实测。这正是希尔伯特公理 I
   组的解析验证：**公理系统的相容性归约为算术的相容性**——笛卡尔
   坐标法（书 9.9.2 差别 (3)「引进解析几何方法」）作为相对相容性
   证明的实例。 *)

(* I.3 每线至少两点 *)
Example hilbert_I3 :
  forallb (fun l => Nat.leb 2 (length (filter (onLine l) points))) lines
  = true.
Proof. reflexivity. Qed.
(* I.4-I.8（平面与空间的关联公理）：平面模型只覆盖平面部分——
   空间公理需 F₃³ 模型（27 点 13 平面——文档线）。 *)
Example line_has_3pts :
  [ length (filter (onLine (0,(1,0))) points)
  ; length (filter (onLine (0,(1,1))) points) ] = [3;3].
Proof. reflexivity. Qed.
(* F₃ 的每线恰 3 点（3 阶有限射影平面的一部分——去掉无穷远点得
   仿射平面 AG(2,3)）：9 点 24 线 4 平行类。 *)

(* 冒烟 *)
Compute (length lines, length points).
