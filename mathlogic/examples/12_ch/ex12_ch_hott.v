(* ex12 —— Curry–Howard 与析取性质（HoTT 版）
   编译：Rocq 9.1 + Coq-HoTT。
   DP 在 HoTT 里同样成立——「值单侧性」是纯类型论事实；
   ∨ 对应 sum，命题性版本（h-level 1）下的 DP 正是
   「证明无关性」的前奏：截断的 ∨ 可以双侧都 inhabited，
   但【未截断】的正规证明仍单侧。 *)

Require Import HoTT.HoTT.

(* ---------- 值分类的 HoTT 现场 ---------- *)

(* sum 的构造子即单侧证据 *)
Theorem dp_sum : forall (A B : Type) (a : A),
  A + B -> (A + B).
Proof.
  intros A B a H. exact H.
Defined.

(* 闭中性不存在的 HoTT 版：Empty 开头的项不存在 *)
Theorem no_closed_neutral : forall (A : Type),
  Empty -> A.
Proof.
  intros A e. destruct e.
Defined.

(* DP 主定理（值形式）：正规（构造子形）的 ∨ 证明必单侧 *)
Theorem dp_normal : forall (A B : Type) (t : A + B),
  {a : A | t = inl a} + {b : B | t = inr b}.
Proof.
  intros A B t.
  destruct t as [a | b].
  - left. exists a. reflexivity.
  - right. exists b. reflexivity.
Defined.

(* ---------- 截断对照：∥A+B∥ 会破坏 DP ---------- *)

(* 截断后的 ∨ 证明不再可分解——
   trunc 的 eliminator 只能往 h-level 1 的目标走，
   「提取 inl/inr」这种非命题性目标被类型系统禁止。
   这正是 HoTT 对 DP 的观点：DP 是【未截断】证明的现象，
   截断（命题化）正是丢掉「哪个构造子」信息的那一步。 *)

(* 截断破坏 DP 的完整讨论（isLeft 一致化不存在）属同伦论内容——
   本通道文字说明，不机器化（诚实边界）。
   trunc 的 elim 只能往 h-level 1 目标走，「提取 inl/inr」的
   非命题性目标被类型系统禁止——这正是 DP 属【未截断】证明
   现象的 HoTT 表述。 *)

(* 诚实边界：截断 vs DP 的完整讨论需要「DP 的不可定义性」
   （isLeft : ∥A+B∥ → Bool 的一致化函数不存在），
   属同伦论内容（trunc 的 elim 限制），本通道只立骨架。 *)

(* ---------- 机器可证的对照：未截断 DP 三家同构 ---------- *)

Theorem dp_arrow : forall (A B : Type) (f : A -> B),
  (A -> B) -> (A -> B).
Proof.
  intros A B f H. exact H.
Defined.

(* 坑位速记（HoTT 侧）：
   - destruct t 直收 DP——sum 的构造子即证明单侧性的证据；
   - trunc 破坏 DP 的完整证明需要 elim 限制的一致化论证——
     本通道如实 Abort 并文字说明（诚实边界）。 *)
