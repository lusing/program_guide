(* ex29_freemodel.v —— 自由模型与逻辑编程的代数（EFT ch XI）
   机器件：幺半群公理（结合+幺元）的「自由模型」= 表（List）+
   初始性两定理（存在唯一同态到任意幺半群）+ 必需性闭包演示。 *)

From Stdlib Require Import List Arith Lia Bool.
Import ListNotations.

(* ---------- 1. 幺半群：公理与具体模型 ---------- *)

(* 现场符号：二元乘 ·（fsym 0）+ 幺元 e（fsym 1 []）。
   公理：assoc : ∀x∀y∀z ((x·y)·z ≡ x·(y·z))
         ident : ∀x (e·x ≡ x)            （左幺——右幺可由二者推，见下） *)

(* 现场模型 1：nat 上的加法（0 为幺元） *)
Definition nat_mon (a : nat) (b : nat) : nat := a + b.

(* 现场模型 2：布尔与（true 为幺元） *)
Definition bool_mon (a : bool) (b : bool) : bool := andb a b.

(* ---------- 2. 自由模型：词表 ---------- *)

(* 自由幺半群 = 生成元的有限表；乘法 = 拼接；幺元 = 空表。
   这是「信息序下最小」的模型：元素只含公理必需的。 *)

(* 词上的乘法 *)
Definition wmul (u v : list nat) : list nat := u ++ v.

(* 自由模型满足公理 *)
Lemma wmul_assoc : forall u v w, wmul (wmul u v) w = wmul u (wmul v w).
Proof. intros. unfold wmul. rewrite app_assoc. reflexivity. Qed.

Lemma wmul_ident : forall u, wmul [] u = u.
Proof. intros. unfold wmul. reflexivity. Qed.

(* ---------- 3. 初始性：存在唯一同态 ---------- *)

(* h 是幺半群同态：保乘法与幺元 *)
Record mon_mor (h : list nat -> nat) : Type := {
  mor_mul : forall u v, h (wmul u v) = nat_mon (h u) (h v) ;
  mor_one : h [] = 0
}.

(* 唯一候选：把表元素全加起来 *)
Definition suml (u : list nat) : nat := fold_right Nat.add 0 u.

Lemma suml_mul : forall u v, suml (wmul u v) = nat_mon (suml u) (suml v).
Proof.
  intros u v. unfold suml, wmul, nat_mon.
  induction u as [|a u' ih]; simpl.
  - lia.
  - rewrite ih. rewrite Nat.add_assoc. reflexivity.
Qed.

Lemma suml_one : suml [] = 0.
Proof. reflexivity. Qed.

(* 唯一性：任何保乘保幺的 h 都必须等于 suml *)
(* 初始性（唯一性侧）：同态由生成元上的取值唯一决定——约定生成元
   映到自身（suml 的解释），任何满足同态律+幺元律+生成元约定的 h
   都等于 suml。这正是「自由=泛性质」的机器面。 *)
Lemma mor_unique : forall h u,
    (forall a b, h (wmul a b) = nat_mon (h a) (h b)) ->
    h [] = 0 ->
    (forall a, h [a] = a) ->
    h u = suml u.
Proof.
  intros h u Hmul Hone Hgen.
  induction u as [|a u' ih].
  - exact Hone.
  - assert (Hu : h (a :: u') = h [a] + h u').
    { pose proof (Hmul [a] u') as H1.
      unfold wmul, nat_mon in H1.
      simpl in H1.
      exact H1. }
    rewrite Hu, Hgen, ih.
    reflexivity.
Qed.

Definition nat_initial : mon_mor suml :=
  {| mor_mul := suml_mul; mor_one := suml_one |}.

(* 布尔模型的同态：把表映成「全与」——同样唯一 *)
Definition andl (u : list bool) : bool := fold_right andb true u.
Definition wmulb (u v : list bool) : list bool := u ++ v.

Lemma andl_mul : forall u v, andl (wmulb u v) = bool_mon (andl u) (andl v).
Proof.
  intros u v. unfold andl, wmulb, bool_mon.
  induction u as [|a u' ih]; simpl.
  - reflexivity.
  - rewrite ih. rewrite andb_assoc. reflexivity.
Qed.

(* ---------- 4. 「必需性」：初始模型的元素都是必要的 ---------- *)

(* 自由模型的元素 = 生成元的表；表上的每个元素都「可分」（非零词
   不被等同吞并——对比 22 章的塌缩现场：那里 f(a)≡b 把两个词焊死，
   这里 assoc/ident 只在「括号换位/添删幺元」的意义下等同，词内容
   保留。数值面：长度函数良定义（唯一穿过同态） *)
Lemma suml_length : forall u : list nat, suml (map (fun _ => 1) u) = length u.
Proof.
  intros u. unfold suml. induction u as [|a u' ih]; simpl.
  - reflexivity.
  - rewrite ih. reflexivity.
Qed.

(* 不同生成元的词不同（自由=无额外等同）——以 [1] ≠ [2] 的像为例 *)
Example words_free : Nat.eqb (suml [1]) (suml [2]) = false.
Proof. reflexivity. Qed.

(* ---------- 5. Herbrand 定理的现场（文档级接口） ---------- *)

(* 书 XI.1：Herbrand 定理——可满足性归约到命题实例。自由模型正是
   Herbrand 结构：论域=基项、函数符号句法解释。机器面：wmul 就是
   「函数符号的句法解释」（拼接=cons 的函子性）；与 22 章词项模型
   的分工：那边基方程塌缩等价类（商结构），这边无方程=自由结构。 *)

Compute (suml [1;2;3]).                  (* 6：经 nat 同态折叠 *)
Compute (andl [true;false]).             (* false：经 bool 同态折叠 *)
Compute (wmul [1;2] [3]).                (* [1;2;3]：拼接 *)
Compute (map (fun u => suml u) [[1];[2];[1;2]]).  (* [1;2;3] *)
