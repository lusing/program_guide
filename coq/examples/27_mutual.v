(* 27 互归纳：树与森林 —— Scheme 与手工归纳原理 *)

From Stdlib Require Import Arith List Lia.
Import ListNotations.

Module Ex27Mutual.

(* ---------- 27.1 互引归纳类型：树与森林 ---------- *)

(* 树的节点带一片森林（树的列表）——两个类型互相引用，用 with 连接 *)
Inductive ntree (A : Type) : Type :=
| nnode : A -> nforest A -> ntree A
with nforest (A : Type) : Type :=
| nnil : nforest A
| ncons : ntree A -> nforest A -> nforest A.

Arguments nnode {A} a l.
Arguments nnil {A}.
Arguments ncons {A} t l.

(* ---------- 27.2 互引 Fixpoint ---------- *)

Fixpoint size {A} (t : ntree A) : nat :=
  match t with
  | nnode a l => S (size_f l)
  end
with size_f {A} (l : nforest A) : nat :=
  match l with
  | nnil => 0
  | ncons t l' => size t + size_f l'
  end.

Compute (size (nnode 1 (ncons (nnode 2 nnil) nnil))).   (* = 2 *)

(* ---------- 27.3 默认归纳原理：不能用 ---------- *)

Check ntree_ind.
(* forall (A : Type) (P : ntree A -> Prop),
     (forall (a : A) (n : nforest A), P (nnode a n)) ->
     forall n : ntree A, P n
   看清楚：nnode 的前提里没有「森林里的树满足 P」——
   归纳假设被整个吞掉了，这个原理证不了任何与子树有关的性质 *)

(* ---------- 27.4 Scheme：生成互归纳原理 ---------- *)

Scheme ntree_mutind := Induction for ntree Sort Prop
with nforest_mutind := Induction for nforest Sort Prop.

Check ntree_mutind.
(* 两个谓词 P（树）、P0（森林）一起证：
     (forall a n, P0 n -> P (nnode a n)) ->
     P0 nnil ->
     (forall n, P n -> forall n0, P0 n0 -> P0 (ncons n n0)) ->
     forall n, P n
   ——每个构造子一个前提，跨类型的 IH 都在场 *)

(* ---------- 27.5 互归纳证明实战 ---------- *)

Fixpoint flatten {A} (t : ntree A) : list A :=
  match t with
  | nnode a l => a :: flatten_f l
  end
with flatten_f {A} (l : nforest A) : list A :=
  match l with
  | nnil => []
  | ncons t l' => flatten t ++ flatten_f l'
  end.

(* 注意：length_app 在 8.20 前叫 app_length——抄旧代码先 Check（实测坑） *)
Check length_app.
(* forall (A : Type) (l l' : list A),
     length (l ++ l') = length l + length l' *)

(* 树的大小 = 拍平后的长度。树的命题与森林的命题互为对偶，
   用 ntree_mutind 一次证明，P0 显式给出森林版命题 *)
Theorem size_length : forall (A : Type) (t : ntree A),
  size t = length (flatten t).
Proof.
  intros A t.
  induction t as [a l IHl | | t IHt l IHl] using ntree_mutind with
    (P0 := fun l => size_f l = length (flatten_f l)).
  - (* nnode：size = S (size_f l)，flatten = a :: flatten_f l *)
    simpl. rewrite IHl. lia.
  - (* nnil：0 = length [] *)
    simpl. reflexivity.
  - (* ncons：两个 IH 接力，++ 的长度可加 *)
    simpl. rewrite IHt, IHl. rewrite length_app. lia.
Qed.

(* ---------- 27.6 嵌套归纳：树与树列表 ---------- *)

(* 换个思路：子节点直接用标准库的 list 装树，不再自造森林类型 *)
Inductive ltree (A : Type) : Type :=
| lnode : A -> list (ltree A) -> ltree A.

Arguments lnode {A} a l.

Check ltree_ind.
(* 又是没用的原理：列表里的子树不产生 IH *)

(* 数节点也要新招：互 Fixpoint 跨 list 类型会被守卫检查拒绝
   （实测报 Recursive call to lcount has principal argument equal
   to "t" instead of "l'"）——解法是书 14.3.3 的「内部不动点」：
   在树上的递归里嵌一个列表上的匿名 fix *)
Fixpoint lcount {A} (t : ltree A) : nat :=
  match t with
  | lnode a l => S ((fix lsum' (l' : list (ltree A)) : nat :=
      match l' with
      | [] => 0
      | t1 :: tl => lcount t1 + lsum' tl
      end) l)
  end.

Compute (lcount (lnode 1 [lnode 2 []; lnode 3 [lnode 4 []]])).
(* = 4 —— 递归穿透了「树的列表」这层嵌套 *)

(* 归纳原理同样要手工造：Scheme 帮不了嵌套归纳，
   嵌套 fix 的归纳原理得自己写（书 14.3.3 的原版技术） *)
Section LTreeInd.
  Variables (A : Type) (P : ltree A -> Prop) (Q : list (ltree A) -> Prop).
  Hypotheses
    (H : forall (a : A) (l : list (ltree A)), Q l -> P (lnode a l))
    (H0 : Q nil)
    (H1 : forall (t : ltree A) (l : list (ltree A)),
            P t -> Q l -> Q (cons t l)).

  Fixpoint ltree_ind2 (t : ltree A) : P t :=
    match t as x return P x with
    | lnode a l =>
        H a l ((fix l_ind (l' : list (ltree A)) : Q l' :=
            match l' as y return Q y with
            | nil => H0
            | cons t1 tl => H1 t1 tl (ltree_ind2 t1) (l_ind tl)
            end) l)
    end.
End LTreeInd.

(* 用法与 Scheme 版一样：induction ... using，Q 显式给实例 *)
Theorem lcount_pos : forall (A : Type) (t : ltree A), 1 <= lcount t.
Proof.
  intros A t.
  induction t as [a l IHl | | t IHt l IHl] using ltree_ind2 with
    (Q := fun _ => True).
  - simpl. lia.
  - exact I.
  - exact I.
Qed.
(* 这里 Q 取恒真——节点数至少为 1 与子树列表整体无关；
   换成「列表里每棵子树都有性质 P」之类的实例，
   H1 的 IH 才会真正干活（练习：给 lcount 加一个 flatten 版对偶命题） *)

(* ---------- 27.7 正性约束：不是什么归纳都能定义 ---------- *)

(* 构造子的参数里让被定义类型出现在「负位置」（T -> T 的左侧）
   会被拒——否则可以造出不停机的项，逻辑一致性就没了 *)
Fail Inductive T_bad : Type := bad : (T_bad -> T_bad) -> T_bad.

(* 反过来，(nat -> T_bad) -> T_bad 是合法的——
   T_bad 只出现在箭头右边（严格正位置） *)

End Ex27Mutual.
