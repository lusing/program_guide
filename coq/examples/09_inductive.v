(* 09 归纳类型 —— 用 Inductive 自定义数据：枚举、重新发明 nat、二叉树 *)

Module Ex09Inductive.

(* ---------- 枚举：一周七天 ---------- *)

Inductive day : Type :=
  | monday    : day
  | tuesday   : day
  | wednesday : day
  | thursday  : day
  | friday    : day
  | saturday  : day
  | sunday    : day.

Definition next_workday (d : day) : day :=
  match d with
  | monday    => tuesday
  | tuesday   => wednesday
  | wednesday => thursday
  | thursday  => friday
  | friday    => monday
  | saturday  => monday
  | sunday    => monday
  end.

Compute (next_workday friday).   (* = monday *)
Example test_next :
  next_workday (next_workday saturday) = tuesday.
Proof. reflexivity. Qed.

(* ---------- 重新发明 bool 与 nat ---------- *)

(* bool 无非是两个构造子的枚举： *)
Inductive mybool : Type :=
  | mytrue  : mybool
  | myfalse : mybool.

Definition mynegb (b : mybool) : mybool :=
  match b with
  | mytrue => myfalse
  | myfalse => mytrue
  end.

Compute (mynegb mytrue).         (* = myfalse *)

(* nat 无非是「一个无参构造子 + 一个带参数构造子」： *)
Inductive mynat : Type :=
  | mzero  : mynat
  | msucc  : mynat -> mynat.    (* 构造子可以吃自己类型的值 —— 递归！ *)

Definition my_one : mynat := msucc mzero.
Definition my_two : mynat := msucc my_one.

Fixpoint mydouble (n : mynat) : mynat :=
  match n with
  | mzero => mzero
  | msucc k => msucc (msucc (mydouble k))
  end.

Example mydouble_two : mydouble my_two = msucc (msucc (msucc (msucc mzero))).
Proof. reflexivity. Qed.

(* ---------- 类型参数：多态二叉树 ---------- *)

Inductive btree (A : Type) : Type :=
  | leaf : btree A
  | node : btree A -> A -> btree A -> btree A.

(* 构造子的 A 参数默认是显式的；声明成隐式更好用 *)
Arguments leaf {A}.
Arguments node {A} l a r.

Definition t1 : btree nat := node (node leaf 1 leaf) 2 (node leaf 3 leaf).

Fixpoint mirror {A : Type} (t : btree A) : btree A :=
  match t with
  | leaf => leaf
  | node l a r => node (mirror r) a (mirror l)
  end.

Example mirror_ex :
  mirror t1 = node (node leaf 3 leaf) 2 (node leaf 1 leaf).
Proof. reflexivity. Qed.

(* 同一个 btree 装别的类型，类型检查全照常工作 *)
Check (node leaf true leaf).      (* : btree bool *)

(* ---------- Inductive 自动生成归纳原理（第 12 章的主角） ---------- *)

Check day_ind.
(* day_ind : forall P : day -> Prop,
              P monday -> P tuesday -> ... -> P sunday ->
              forall d : day, P d
   —— 要证「对每个 day 都成立」，只需对七个构造子各证一次 *)

Check btree_ind.
(* btree_ind : forall (A : Type) (P : btree A -> Prop),
   P leaf ->
   (forall b : btree A, P b -> forall (a : A) (b0 : btree A),
      P b0 -> P (node b a b0)) ->
   forall b : btree A, P b
   —— 树版的归纳原理：证叶子 + 「假设两棵子树成立则节点成立」 *)

(* ---------- 构造子的三大纪律 ---------- *)

(* 1. 不相交：不同的构造子造出的值永不相等。
   利用这一点可以从「monday = tuesday」推出任何结论： *)
Example day_absurd : monday = tuesday -> 1 = 2.
Proof.
  intros H.
  discriminate H.
Qed.
(* discriminate：从「不同构造子相等」这个矛盾前提直接关闭任意目标。
   第 13 章正式讲。 *)

End Ex09Inductive.
