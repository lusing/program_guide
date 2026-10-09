(* ex85_identity.v —— 同一性与结构主义（Müller-Stach ch1/ch3/ch9）
   机器件：Leibniz 等词编码与内建 eq 的等价（零公理 iff）；Hume
   原理有限宇宙——子集按「存在双射」（=同基数）分块的等价类账
   （Caesar 问题现场记文档线）；ℕ 三化身对照（von Neumann/Zermelo
   编码+同构账）；Fermat 数素数无穷另证（恒等式+两两互素+F₅ 分解
   ——N 通道）；Z 的商构造（等价类+乘法公式良定义）；对偶数环
   （d²=0 与 Leibniz 乘法法则）。晨星暮星/Benacerraf/univalence
   桥记文档线。 *)

From Stdlib Require Import List Arith Lia NArith.
Import ListNotations.

(* ---------- 1. Leibniz 等值：替换即等式 ---------- *)

(* 书 p17 拉丁原句：Eadem sunt quorum unum potest substitui alteri
   salva veritate——「凡可在真值保持下互相替换者是同一的」 *)
Definition leib (a b : nat) : Prop :=
  forall P : nat -> Prop, P a -> P b.

(* Leibniz 等词 = 内建等词（零公理双向） *)
Theorem leib_eq : forall a b, leib a b <-> a = b.
Proof.
  intros a b. split.
  - intros H. apply (H (fun x => a = x)). reflexivity.
  - intros H P HP. rewrite <- H. exact HP.
Qed.
(* 方向 → 用 P := fun x => a = x 的对角化：从 P a（即 a=a，由
   reflexivity 免费）得到 P b（即 a=b）——「任何性质都传递」直接
   兑现为「等式性质也传递」。方向 ← 是替换本身。Id-elim（路径
   归纳）正是这条替换规则的类型论推广（书 p123 的原话）。 *)

(* ---------- 2. Hume 原理：等数 = 存在双射 ---------- *)

(* 书 p25-27：Frege 数概念的核心——「两概念等数 ⟺ 存在双射」。
   有限集上双射 = 同基数；{0,1,2} 的全部子集按基数分块 *)
Definition sub3 : list (list nat) :=
  [ []; [0]; [1]; [2]; [0;1]; [0;2]; [1;2]; [0;1;2] ].

Definition sameCard (u v : list nat) : bool :=
  Nat.eqb (length u) (length v).

Definition blockOf (x : list nat) : list (list nat) :=
  filter (sameCard x) sub3.

(* 基数等价类账：1、3、3、1——二项式系数（子集宇宙的完整分块） *)
Example hume_blocks :
  [ blockOf []
  ; blockOf [0]
  ; blockOf [0;1]
  ; blockOf [0;1;2] ]
  = [ [[]]
    ; [[0]; [1]; [2]]
    ; [[0;1]; [0;2]; [1;2]]
    ; [[0;1;2]] ].
Proof. reflexivity. Qed.
(* 每块是「与 x 等数」的全部子集——Number(F)={G|G≅F} 的机器面。
   Caesar 问题的现场（文档线）：等数抽象定义了数 3 这个等价类，
   但「3 是不是 Julius Caesar」需要额外原则排除——等数给不出
   元素级的身份。 *)

(* ---------- 3. ℕ 三化身：同一公理的多个集合实现 ---------- *)

(* von Neumann：0=∅，S x = x ∪ {x}（集合=全部前驱，降序表） *)
Fixpoint vn (n : nat) : list nat :=
  match n with
  | 0 => []
  | S k => k :: vn k
  end.

(* Zermelo：0=∅，S x = {x}（单层嵌套）。嵌套深度依赖值——扁平
   list 装不下（每层类型都不同），用树归纳类型忠实编码 *)
Inductive zset : Type :=
| zleaf                      (* ∅ *)
| znode (x : zset).          (* {x} *)

Fixpoint ze (n : nat) : zset :=
  match n with
  | 0 => zleaf
  | S k => znode (ze k)
  end.

Fixpoint zdepth (x : zset) : nat :=
  match x with
  | zleaf => 0
  | znode t => S (zdepth t)
  end.

(* von Neumann 侧的对照账：0=[],[1;0],[2;1;0],… *)
Example vn_faces :
  map vn (seq 0 4)
  = ([] :: [0] :: [1; 0] :: [2; 1; 0] :: nil).
Proof. reflexivity. Qed.

(* 同构账：两个实现按各自的「计数」读法逐位一致——vn 的元素数
   与 ze 的嵌套深度都恰为位置索引 *)
Example faces_agree :
  map (fun k => length (vn k)) (seq 0 6)
  = map (fun k => zdepth (ze k)) (seq 0 6).
Proof. reflexivity. Qed.
(* Benacerraf 两难的机器侧写：vn 3=[2;1;0] 与 ze 3=znode³(∅) 是
   两个完全不同的集合，却承载同一个数（都满足「3 次后继」）。
   「数是哪一个集合？」没有答案——数是结构位置，不是实体
   （结构主义出口）。Dedekind 的第三化身（二阶 (X,s,z) 链）与
   Henkin 语义记文档线。 *)

(* ---------- 4. Fermat 数：素数无穷另证（书 ch3 p44-45） ---------- *)

Fixpoint pow2n (n : nat) : nat :=
  match n with 0 => 1 | S k => 2 * pow2n k end.

Fixpoint fermat (m : nat) : nat :=
  match m with
  | 0 => 3
  | S k => let h := fermat k - 1 in h * h + 1   (* (F_k−1)²+1 *)
  end.
(* 平方递推：F_{k+1} = 2^{2^{k+1}}+1 = (2^{2^k})²+1 = (F_k−1)²+1 *)

(* 小表：F₀..F₄ = 3,5,17,257,65537（全素——Fermat 的猜测）。
   65537 的字面量在 rfl 下是 of_num_uint 抽象（unary kernel 拒绝
   展开 65k 层）——拆两账：小字面量表 + F₄ 与其构造式对账 *)
Example fermat_table :
  map fermat (seq 0 4) = [3; 5; 17; 257].
Proof. reflexivity. Qed.

Example fermat4_value :
  Nat.eqb (fermat 4) (256 * 256 + 1) = true.
Proof. reflexivity. Qed.

(* 恒等式 F₄ = F₀·F₁·F₂·F₃ + 2 *)
Example fermat_identity :
  Nat.eqb (3 * 5 * 17 * 257 + 2) (fermat 4) = true.
Proof. reflexivity. Qed.

(* 两两互素（数值 gcd 账，10 对全查） *)
Example fermat_pairwise_coprime :
  forallb (fun p => Nat.eqb (Nat.gcd (fermat (fst p)) (fermat (snd p))) 1)
          [ (0, 1); (0, 2); (0, 3); (0, 4); (1, 2); (1, 3);
            (1, 4); (2, 3); (2, 4); (3, 4) ]
  = true.
Proof. reflexivity. Qed.
(* 证明一瞥：d | F_i 与 d | F_j（i<j）⟹ d | F_j − (F₀…F_{j-1})
   = 2 ⟹ d ∈ {1,2}，而 Fermat 数全奇 ⟹ d=1。两两互素 ⟹ 每个
   F_m 带新素因子 ⟹ 素数无穷。与 74 章 Euclid 证法（n!+1）对照：
   同构的骨架，不同的尺。 *)

(* F₅ = 641·6700417（Euler 1732 的拆解）——42.9 亿走 N 通道
   （49 章同款：unary nat 装不下；scope 劫持三坑全数适用） *)
Open Scope N_scope.

Definition F5 : N := 4294967297.

Example euler_breaks_fermat :
  N.eqb (641 * 6700417) F5 = true.
Proof. reflexivity. Qed.
(* F₅ 是合数——「F_m 全素」的 Fermat 猜想被 Euler 一击毙命。
   素数无穷另证不受影响（它只要两两互素，不要素性）。 *)

Close Scope N_scope.

(* ---------- 5. Z 的商构造：负数作为等价类 ---------- *)

(* (a,b) 表示 a−b；(a,b) ~ (c,d) ⟺ a+d = b+c（书 ch3 p46-47） *)
Definition paireq (u v : nat * nat) : bool :=
  Nat.eqb (fst u + snd v) (snd u + fst v).

Example z_classes :
  [ paireq (2, 5) (7, 10)          (* 都表示 −3 *)
  ; paireq (0, 3) (5, 8)
  ; negb (paireq (2, 5) (0, 1)) ]  (* −3 ≠ −1 *)
  = [true; true; true].
Proof. reflexivity. Qed.

(* 乘法公式 (a,b)·(c,d) = (ac+bd, ad+bc)：代表元选取无关
   （良定义性）——同类对各自相乘仍同类 *)
Definition pairmul (u v : nat * nat) : nat * nat :=
  (fst u * fst v + snd u * snd v,
   fst u * snd v + snd u * fst v).

Example z_mul_welldefined :
  [ paireq (pairmul (2, 5) (3, 1)) (pairmul (7, 10) (3, 1))  (* −3·2 两写法 *)
  ; paireq (pairmul (2, 5) (3, 1)) (11, 17) ]                (* = −6 *)
  = [true; true].
Proof. reflexivity. Qed.
(* Grothendieck 群的构造骨架：交换幺半群 → 群 = 对 (a,b)（形式
   差）做商。整数的「负」不是新对象，是等价类——同一性再次让位
   于结构（文档线：数系塔的每一层都是商构造）。 *)

(* ---------- 6. 对偶数环：d²=0 与 Leibniz 乘法法则 ---------- *)

(* Z[d]/(d²)：元素 (a,b) 读作 a+bd；乘法 (a,b)(c,e)=(ac, ae+bc)
   ——d²=0 被焊进乘法表 *)
Definition dmul (u v : nat * nat) : nat * nat :=
  (fst u * fst v, fst u * snd v + snd u * fst v).

Example d_squared_zero : dmul (0, 1) (0, 1) = (0, 0).
Proof. reflexivity. Qed.

(* Leibniz 乘法法则：(f·g)' = f·g' + f'·g——从 d²=0 机械流出：
   (1+d)² = 1+2d（平方项被 d²=0 吞掉） *)
Example dual_leibniz :
  dmul (1, 1) (1, 1) = (1, 2).
Proof. reflexivity. Qed.
(* 书 ch3 p50-52「附加法两步」：第一步加自由变元（R[T]），第二
   步加关系（R[T]/(T²−2) 得 √2；Z[T]/(T²) 得 Leibniz 无穷小环
   ——微分的代数化：(f+df)(g+dg)−fg 展开，d² 项归零，剩
   f·dg+g·df。无穷小不再是极限的比喻，是商环的元素。 *)

(* 冒烟 *)
Compute (map vn (seq 0 4), map (fun k => zdepth (ze k)) (seq 0 4)).
