(* 74 QCDerive 自动派生 —— Show / GenSized / Shrink / EnumSized / Arbitrary 一键派生、
   派生代码工作原理（freq 权重分支、尺寸燃料、收缩的构造子逆向分解）、
   依赖类型派生：DecOpt / ArbitrarySizedSuchThat / EnumSizedSuchThat 与 genST 记号 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List. Import ListNotations.

Module Ex74Deriving.

(* ---------- 74.1 简单类型的派生：Show / GenSized / Shrink / EnumSized / Arbitrary ---------- *)

(* QuickChick 2.2 起派生命令由 Derive 更名为 QCDerive
   （避免与 Rocq 核心及 Equations 的 Derive 撞名），语法与功能不变。 *)

Inductive Tree A :=
| Leaf : Tree A
| Node : A -> Tree A -> Tree A -> Tree A.
Arguments Leaf {A}.
Arguments Node {A} _ _ _.

(* 逐个派生四个简单类；派生出的实例命名规则为「类名前缀 + 类型名」。 *)

QCDerive Show for Tree.
(* ==> ShowTree is defined *)

QCDerive GenSized for Tree.
(* ==> GenSizedTree is defined *)

QCDerive Shrink for Tree.
(* ==> ShrinkTree is defined *)

QCDerive EnumSized for Tree.
(* ==> EnumSizedTree is defined *)

(* 不必再单独派生 Arbitrary：Arbitrary 是带 Gen、Shrink 两个 superclass
   约束的空类；全局实例 ArbitraryOfGenShrink 会把任意 Gen + Shrink 自动
   合成 Arbitrary，而 GenOfGenSized 又把 GenSized 升格为 Gen
   （arbitrary := sized arbitrarySized）。所以此刻 Tree 的
   arbitrary / shrink / show 已全部可用。 *)

Definition genTreeNat : G (Tree nat) := arbitrary.

Sample genTreeNat.
(* 形如 [Leaf, Node 2 Leaf (Node 5 Leaf Leaf), Leaf, ...]
   —— 尺寸由 QuickChick 的 size 参数控制 *)

(* 测试含等式的性质还需布尔相等：Dec_Eq 实例用库提供的 dec_eq 策略
   一行构造（注意用 Defined 而非 Qed 收尾，实例需要可计算）。 *)

#[global] Instance Dec_Eq_Tree {A} `{Dec_Eq A} : Dec_Eq (Tree A).
Proof. dec_eq. Defined.

Fixpoint mirror {A : Type} (t : Tree A) : Tree A :=
  match t with
  | Leaf => Leaf
  | Node x l r => Node x (mirror r) (mirror l)
  end.

(* 一条 faulty 性质：并非每棵树都是自镜像的。 *)

Definition faulty_mirrorP (t : Tree nat) :=
  mirror t = t?.

QuickChick faulty_mirrorP.
(* *** Failed after 若干次测试与收缩，反例为左右不对称的小树，
   形如 Node 0 (Node 0 Leaf Leaf) Leaf —— 派生的 ShrinkTree 会把
   反例自动收缩到接近最小。 *)

(* Arbitrary 也可一步派生（= GenSized + Shrink 两条命令的合体）。
   注意：对同一类型不要既分别派生 GenSized/Shrink 又派生 Arbitrary，
   否则同名实例重复定义会报错——Tree 上面已分别派生过，
   故这里换一个小类型演示。 *)

Inductive shape := Point | Seg | Tri.

QCDerive Arbitrary for shape.
(* ==> GenSizedshape is defined
   ==> Shrinkshape is defined *)

Sample (arbitrary : G shape).
(* 形如 [Seg, Point, Tri, Point, ...] *)

(* ---------- 74.2 派生代码的工作原理 ---------- *)

(* GenSizedTree 的函数体本质上是 71 章手写 genTreeSized' 的机械化：

     Fixpoint arbitrarySized (sz : nat) : G (Tree A) :=
       match sz with
       | O    => oneOf [ ret Leaf ]
       | S sz' =>
           freq [ (1,     ret Leaf) ;
                  (S sz', liftM3 Node arbitrary
                                     (arbitrarySized sz')
                                     (arbitrarySized sz')) ]
       end.

   合成规则（见源码 plugin/arbitrarySized.ml 与 weightmap.mlg.cppo）：
   - 每个构造子一个分支；燃料归零时只保留 base 构造子（无递归字段者）；
   - 权重默认 base = 1、递归 = S sz'（当前剩余燃料）——正是手写版
     freq [ (1, ret Leaf) ; (sz, ...) ] 的配比；
   - 非递归字段（此处的 A）调用 arbitrary，递归字段递归调用自身；
   - 派生前可用 QuickChickWeights [(Leaf, 1); (Node, 4)] 覆盖默认权重
     （benchmarks/BST/BST.v 即以此调校 between 的生成器）。 *)

(* ShrinkTree 则把每个构造子「逆向分解」：Node x l r 的收缩候选为
   - 两个子树本身 [l; r]（递归字段直接给出）；
   - 收缩单个字段后重建整体，如
     List.map (fun shrunk => Node shrunk l r) (shrink x)；
   零元构造子无处可缩： *)

Eval compute in (shrink (@Leaf nat)).
(* ==> [] : list (Tree nat) *)

(* ---------- 74.3 依赖类型派生（一）：balanced 关系 ---------- *)

(* 对带全称量化参数的归纳关系，QCDerive 可派生检查器与生成器。
   以「高度恰为 n、且每层左右同高」的平衡树为例
   （逐字改编自官方教程 tutorials/Automation.v）： *)

Inductive balanced {A} : nat -> Tree A -> Prop :=
| B0 : balanced 0 Leaf
| B1 : balanced 1 Leaf
| BS : forall n x l r,
    balanced n l -> balanced n r ->
    balanced (S n) (Node x l r).

(* 检查器：DecOpt 类提供 decOpt : nat -> option bool，nat 是 fuel。
   QCDerive Checker for ... 是 QCDerive DecOpt for ... 的别名。 *)

QCDerive DecOpt for (balanced n t).
(* ==> DecOptbalanced is defined *)

Check DecOptbalanced.
(* ===> DecOptbalanced
          : forall (n_ : nat) (t_ : Tree ?A), DecOpt (balanced n_ t_) *)

(* 派生出的 DecOpt 实例满足：单调（fuel 更大时结论不变）、sound
   （Some true 蕴含关系成立，Some false 蕴含不成立）、部分完备
   （关系成立则存在足够大的 fuel 使其返回 Some true）。 *)

Eval compute in (balanced 1 (Node 42 Leaf Leaf) ?? 10).
(* ==> Some true *)

Eval compute in (balanced 2 Leaf ?? 10).
(* ==> Some false *)

Eval compute in (balanced 3 (Node 42 (Node 10 Leaf Leaf) (Node 10 Leaf Leaf)) ?? 1).
(* ==> None —— fuel 不足时拒绝定论 *)

(* 生成器：GenSizedSuchThat 类提供 arbitrarySizeST : nat -> G (option A)，
   生成失败返回 None。for 后的匿名函数指明「要生成哪个参数」，
   其余名字（此处的 n）视为全称量化的外围参数。
   QCDerive Generator for ... 是 ArbitrarySizedSuchThat 的别名。 *)

QCDerive ArbitrarySizedSuchThat for (fun t => balanced n t).
(* ==> GenSizedSuchThatbalanced is defined *)

Check GenSizedSuchThatbalanced.
(* ===> GenSizedSuchThatbalanced
          : forall n_ : nat,
            GenSizedSuchThat (Tree ?A) (fun t_ : Tree ?A => balanced n_ t_) *)

(* 两个记号：genSizedST P fuel 直接调用 arbitrarySizeST；
   genST P 调用 arbitraryST（GenSuchThat 类）——全局实例
   GenSuchThatOfBounded 会用 sized arbitrarySizeST 自动合成后者。 *)

Sample (genST (fun t => balanced 1 t)).
(* 形如 [Some Leaf; Some (Node 5 Leaf Leaf); Some (Node 0 Leaf Leaf); ...]
   —— Leaf 与单节点树都满足 balanced 1 *)

(* 健全性自检：对随机 n，派生生成的树都应通过派生检查器；
   forAllMaybe 把生成失败的 None 记为一次丢弃而非失败。 *)

Definition prop_gen_balanced_is_balanced :=
  let fuel := 10 in
  forAll (choose (0,5)) (fun (n : nat) =>
  forAllMaybe (genSizedST (fun t => balanced n t) fuel) (fun (t : Tree nat) =>
    balanced n t ?? fuel)).

QuickChick prop_gen_balanced_is_balanced.
(* ==> +++ Passed 10000 tests (0 discards) *)

(* 同一关系还可派生枚举器：EnumSizedSuchThat 提供
   enumSizeST : nat -> E (option A)，系统枚举而非随机采样。 *)

QCDerive EnumSizedSuchThat for (fun t => balanced n t).
(* ==> EnumSizedSuchThatbalanced is defined *)

(* ---------- 74.4 依赖类型派生（二）：sorted 列表（含外部前提） ---------- *)

(* sortedI 的第三条构造子含前提 le x y——它不是递归前提。
   派生驱动通过类型类搜索解决外部前提，因此需先备好
   le 的检查器与「给定下界生成上界数」的生成器实例
   （benchmarks/BST/BST.v 的同款做法）： *)

QCDerive DecOpt for (le x y).
(* ==> DecOptle is defined *)

QCDerive ArbitrarySizedSuchThat for (fun x => le y x).
(* ==> GenSizedSuchThatle is defined *)

Inductive sortedI : list nat -> Prop :=
  | sorted_nil : sortedI []
  | sorted_one : forall x, sortedI [x]
  | sorted_cons : forall x y l,
      le x y ->
      sortedI (y :: l) ->
      sortedI (x :: y :: l).

QCDerive DecOpt for (sortedI l).
(* ==> DecOptsortedI is defined *)

Eval compute in (sortedI [1; 3; 3; 7] ?? 10).
(* ==> Some true *)

Eval compute in (sortedI [3; 1] ?? 10).
(* ==> Some false *)

QCDerive ArbitrarySizedSuchThat for (fun l => sortedI l).
(* ==> GenSizedSuchThatsortedI is defined *)

Sample (genST (fun l => sortedI l)).
(* 形如 [Some []; Some [4]; Some [1; 1; 6; 9]; ...]
   —— 每个 Some 里都是有序列表 *)

(* 73 章用 ==> 测「insert 保持有序」时，随机列表几乎全无序，
   前提恒假导致大面积丢弃。现在让派生生成器直接产出满足前提的输入： *)

Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y :: t => if x <=? y then x :: l else y :: insert x t
  end.

Definition prop_insert_keeps_sorted (x : nat) :=
  let fuel := 10 in
  forAllMaybe (genSizedST (fun l => sortedI l) fuel) (fun l =>
    sortedI (insert x l) ?? fuel).

QuickChick prop_insert_keeps_sorted.
(* ==> +++ Passed 10000 tests (0 discards) *)

(* ---------- 74.5 练习解答：三叉树镜像 bug（原书 QC.v 练习的派生版） ---------- *)

(* 练习 tern_tree_typeclasses（2 星）：
   为下面的类型备齐类型类实例，使镜像-路径性质可以直接 QuickChick。
   原书要求手写；有了 QCDerive，两条命令即可——顺带演示
   QCDerive (类1, 类2) for T. 的一次多派。 *)

Inductive TernaryTree : Type :=
  | TLeaf : TernaryTree
  | TNode : nat -> TernaryTree -> TernaryTree -> TernaryTree -> TernaryTree.

QCDerive (Arbitrary, Show) for TernaryTree.
(* ==> GenSizedTernaryTree is defined
   ==> ShrinkTernaryTree is defined
   ==> ShowTernaryTree is defined *)

Inductive direction := Left | Middle | Right.

QCDerive (Arbitrary, Show) for direction.
(* ==> GenSizeddirection is defined
   ==> Shrinkdirection is defined
   ==> Showdirection is defined *)

(* 多类合派只对简单类开放；DecOpt / SuchThat 等依赖类必须逐个派生。 *)

#[global] Instance Dec_Eq_TernaryTree : Dec_Eq TernaryTree.
Proof. dec_eq. Defined.

Definition flip (d : direction) : direction :=
  match d with
  | Left => Right
  | Middle => Middle
  | Right => Left
  end.

Fixpoint traverse_node (d : direction) (l m r : TernaryTree) : TernaryTree :=
  match d with
  | Left => l
  | Middle => m
  | Right => r
  end.

Fixpoint traverse_path (p : list direction) (t : TernaryTree) : TernaryTree :=
  match p with
  | [] => t
  | d :: p' =>
      match t with
      | TLeaf => TLeaf
      | TNode _ l m r => traverse_path p' (traverse_node d l m r)
      end
  end.

(* 练习 bug_finding_tern_tree（4 星）：下面这个镜像函数藏着 bug——
   中间子树 m 忘了递归镜像（应写成 tern_mirror m）。 *)

Fixpoint tern_mirror (t : TernaryTree) : TernaryTree :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r => TNode x (tern_mirror r) m (tern_mirror l)
  end.

(* 性质：沿翻转后的路径（Left/Right 互换）走到镜像树中的子树，
   等于先取子树再镜像。 *)

Definition tern_mirror_path_flip (t : TernaryTree) (p : list direction) :=
  traverse_path (map flip p) (tern_mirror t) = tern_mirror (traverse_path p t)?.

QuickChick tern_mirror_path_flip.
(* *** Failed —— 反例必含 Middle：只有路径走进中间子树时 bug 才显形。
   注意派生的 Shrinkdirection 对零元构造子一律给 []（见 74.2），
   收缩不会把 Middle 换成 Left——方向上的收缩想更聪明需手写 Shrink。 *)

(* 修复：中间子树也递归镜像，回归测试通过。 *)

Fixpoint tern_mirror_fixed (t : TernaryTree) : TernaryTree :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r =>
      TNode x (tern_mirror_fixed r) (tern_mirror_fixed m) (tern_mirror_fixed l)
  end.

Definition tern_mirror_path_flip_fixed (t : TernaryTree) (p : list direction) :=
  traverse_path (map flip p) (tern_mirror_fixed t)
  = tern_mirror_fixed (traverse_path p t)?.

QuickChick tern_mirror_path_flip_fixed.
(* ==> +++ Passed 10000 tests (0 discards) *)

End Ex74Deriving.
