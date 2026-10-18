(* ex13 —— 合流余极限（Simmons 4.7）
   三书对位：Simmons 4.7.1 /《高级范畴论》3.5 / 贺伟 2.3。

   V 形合流模板 0 -> 2 <- 1：两个源都送进公共后继 2。
   块集 = A2 的像（范式编码：每块取公共后继处的代表），
   R-作用按分量继承；中介映射用典范代表定义，
   重叠点 (false,false) 的一致性恰用余锥条件。
   全部在 bool 上穷尽验证。 *)

Require Import Bool.

(* ---------- 模板与图 ---------- *)

Definition A2 : Set := (bool * bool)%type.

Definition h0 (x : bool) : A2 := (x, false).      (* 0 -> 2 *)
Definition h1 (y : bool) : A2 := (false, y).      (* 1 -> 2 *)

(* R := bool 幺半（&& 为作用，1 := true）；A2 上的分量作用 *)
Definition act2 (z : A2) (r : bool) : A2 := (fst z && r, snd z && r).

(* 连接箭头保作用：先送后作用 = 先作用后送——两侧定义性相等。
   这就是 4.7.1 良定义性三步链的机器版（(x|r)·r = (x·r)|r）。 *)
Lemma h0_mor : forall x r, h0 (x && r) = act2 (h0 x) r.
Proof. intros. reflexivity. Qed.

Lemma h1_mor : forall y r, h1 (y && r) = act2 (h1 y) r.
Proof. intros. reflexivity. Qed.

(* ---------- 块集 = 像 ---------- *)

Definition Blk (z : A2) : Prop :=
  (exists x, h0 x = z) \/ (exists y, h1 y = z).

(* 像对作用封闭：范式编码能继承作用的前提 *)
Lemma blk_act_closed : forall z r, Blk z -> Blk (act2 z r).
Proof.
  intros z r [[x Hx]|[y Hy]]; simpl.
  - left. exists (x && r). rewrite h0_mor, Hx. reflexivity.
  - right. exists (y && r). rewrite h1_mor, Hy. reflexivity.
Qed.

(* ---------- 中介映射：典范代表 ---------- *)

(* 余锥：M 上的两个 β，公共后继处一致（重叠只在 (false,false)） *)
Definition beta0 (x : bool) : bool := x.
Definition beta1 (y : bool) : bool := false.

Lemma cocone_law : forall x y, h0 x = h1 y -> beta0 x = beta1 y.
Proof.
  intros x y H. destruct x, y; simpl in H.
  - inversion H.          (* (true,false) = (false,true)：矛盾 *)
  - inversion H.          (* (true,false) = (false,false)：矛盾 *)
  - inversion H.          (* (false,false) = (false,true)：矛盾 *)
  - reflexivity.         (* (false,false)：beta0 false = beta1 false *)
Qed.

(* 典范中介：像上的函数；重叠点两式给出同值（余锥条件） *)
Definition med (z : A2) : bool :=
  match z with
  | (b, false) => b           (* 来自 h0 *)
  | (false, _) => false       (* 来自 h1：beta1 恒 false *)
  | _ => false                (* (true,true) 不在像里 *)
  end.

Lemma med_h0 : forall x, med (h0 x) = beta0 x.
Proof. intros x. destruct x; reflexivity. Qed.

Lemma med_h1 : forall y, med (h1 y) = beta1 y.
Proof. intros y. destruct y; reflexivity. Qed.

(* ---------- 唯一性：中介被余锥腿钉死 ---------- *)

(* 任何满足 med-law 的函数都在像上与 med 逐点一致：
   像的每个点都是某个 h0/h1 的像，值被 beta 钉死 *)
Lemma med_unique : forall (u : A2 -> bool),
  (forall x, u (h0 x) = beta0 x) -> (forall y, u (h1 y) = beta1 y) ->
  forall z, Blk z -> u z = med z.
Proof.
  intros u H0 H1 z [[x Hx]|[y Hy]]; subst z.
  - rewrite med_h0, H0. reflexivity.
  - rewrite med_h1, H1. reflexivity.
Qed.

Print Assumptions blk_act_closed.
Print Assumptions med_unique.

(* 坑位速记：
   1. 范式编码（块 = 公共后继处的像）把「商集良定义性」吃进
      编码，但像的封闭性（blk_act_closed）必须显式证——否则
      作用继承悬空。
   2. med 的重叠分支 (false,false)：h0 与 h1 都盖到它，两式
      一致性就是 cocone_law——重叠点是余锥条件唯一的用武之地。
   3. 唯一性证明按「像的见证」分案，逐案换用 H0/H1——
      存在见证的 Case 分析比全枚举更贴近抽象证明的形状。 *)
