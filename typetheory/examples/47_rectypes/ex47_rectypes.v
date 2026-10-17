(* ============================================================ *)
(* 41 递归类型 —— Coq：余归纳、互模拟与 μ 展开（书 ch.20/21）  *)
(*   甲·CoInductive 流：无限数据的第一公民——cofix 的构造、     *)
(*      双展开原则（bisim 的两条腿）                             *)
(*   乙·互模拟 ⇒ 相等：map f (map f s) 型守恒律的余归纳证明      *)
(*      ——书 21.1「归纳=最小不动点、余归纳=最大不动点」的机器版  *)
(*   丙·μ 类型的等式递归读法：μX.T 的展开/折叠作为定义等式      *)
(*      （书 20.2 的 equi-recursive 立场；同构递归的 fold/unfold *)
(*       版本见正文与 Prolog 件）                                *)
(* ============================================================ *)

Require Import List.
Import ListNotations.

(* ---- 甲·余归纳流：无限数据的第一公民 ---- *)
Set Implicit Arguments.
CoInductive Stream (A : Type) : Type :=
| SCons : forall (x : A) (r : Stream A), Stream A.

(* 构造无限流必须用 cofix：递归调用受「卫式」约束——
   每个递归出现必须多消费至少一个构造子（Coq 的卫式条件，
   对应书 21.1 余归纳证明规则里「展开至少一层」） *)
CoFixpoint zeros : Stream nat := SCons 0 zeros.

CoFixpoint from (n : nat) : Stream nat := SCons n (from (S n)).

(* 观察者：头与前缀 *)
Definition hd (s : Stream nat) : nat :=
  match s with SCons x _ => x end.
Definition tl (s : Stream nat) : Stream nat :=
  match s with SCons _ r => r end.

(* map 也是 cofix（在结果构造子之下递归——卫式） *)
CoFixpoint smap (f : nat -> nat) (s : Stream nat) : Stream nat :=
  match s with SCons x r => SCons (f x) (smap f r) end.

(* ---- 乙·互模拟：余归纳的相等 ---- *)
CoInductive bisim : Stream nat -> Stream nat -> Prop :=
| bisim_intro : forall s1 s2,
    hd s1 = hd s2 -> bisim (tl s1) (tl s2) -> bisim s1 s2.

(* 互模拟的互推：两条腿各展开一层 *)
Lemma bisim_hd : forall s1 s2, bisim s1 s2 -> hd s1 = hd s2.
Proof. intros s1 s2 H. inversion H. assumption. Qed.

Lemma bisim_tl : forall s1 s2, bisim s1 s2 -> bisim (tl s1) (tl s2).
Proof. intros s1 s2 H. inversion H. assumption. Qed.

(* 余归纳证明：证 bisim s1 s2，允许假设「同一目标」（更大不动点） *)
Theorem zeros_map_id : bisim (smap (fun x => x) zeros) zeros.
Proof.
  cofix CH.
  apply bisim_intro.
  - reflexivity.
  - exact CH.                       (* 尾巴回到同一目标——余归纳环 *)
Qed.

(* 双 map 合成律的余归纳证明（21.2 互模拟等价传递性的样本） *)
Theorem smap_comp : forall f g s,
  bisim (smap f (smap g s)) (smap (fun x => f (g x)) s).
Proof.
  intros f g. cofix CH. intros [x r].
  apply bisim_intro.
  - reflexivity.
  - simpl. apply CH.
Qed.

(* 前缀观察：互模拟蕴含任意有限前缀相等（归纳 × 余归纳的协作） *)
Fixpoint prefix (n : nat) (s : Stream nat) : list nat :=
  match n with
  | O => []
  | S k => hd s :: prefix k (tl s)
  end.

Theorem bisim_prefix : forall n s1 s2,
  bisim s1 s2 -> prefix n s1 = prefix n s2.
Proof.
  induction n as [ | n IH]; intros s1 s2 H; simpl.
  - reflexivity.
  - rewrite (bisim_hd H). f_equal.
    apply IH. apply (bisim_tl H).
Qed.

(* ---- 丙·μ 的等式读法：μX.T ≡ T[μX.T/X] ---- *)
(* 书 20.2 的 equi-recursive 视角：μ 不引入构造子，fold/unfold
   是定义等式（与同构递归对照——那里的 fold/unfold 是有方向
   的普通函数）。机器面在 Prolog 件：按需展开 + 深度限界的
   子类型检查（21.5 的成员检查算法雏形）。                    *)

Example from_prefix : prefix 3 (from 0) = [0; 1; 2].
Proof. reflexivity. Qed.

Example zeros_prefix : prefix 3 zeros = [0; 0; 0].
Proof. reflexivity. Qed.
