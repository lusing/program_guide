(* 72 可检查性质与收缩 —— Checker 结果类型与 Checkable 类、
   CheckerPlayground 四步渐进、forAll / forAllShrink / forAllProof、
   Shrink 实例与贪心收缩、TernaryTree 综合案例、collect / tag 统计、
   whenFail / expectFailure / conjoin / disjoin、Args 调参与默认参数 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List. Import ListNotations.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Import QcNotation.

Module Ex72Checkers.

Open Scope qc_scope.
Open Scope monad_scope.
Local Open Scope string.

(* ---------- 72.1 舞台素材：沿用 71 章的树与小性质 ---------- *)

Inductive color := Red | Green | Blue | Yellow.

#[export] Instance show_color : Show color :=
{| show c :=
     match c with
     | Red => "Red"
     | Green => "Green"
     | Blue => "Blue"
     | Yellow => "Yellow"
     end |}.

Definition genColor : G color := elems [ Red ; Green ; Blue ; Yellow ].

Inductive Tree A :=
| Leaf : Tree A
| Node : A -> Tree A -> Tree A -> Tree A.

Arguments Leaf {A}.
Arguments Node {A} _ _ _.

#[export] Instance showTree {A} `{_ : Show A} : Show (Tree A) :=
{| show := showTreeAux |}
where showTreeAux := fix aux (t : Tree A) : string :=
  match t with
  | Leaf => "Leaf"
  | Node x l r => "Node (" ++ show x ++ ") (" ++ aux l ++ ") (" ++ aux r ++ ")"
  end.

Fixpoint genTreeSized {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => ret Leaf
  | S sz' =>
      oneOf [ ret Leaf ;
              liftM3 Node g (genTreeSized sz' g) (genTreeSized sz' g) ]
  end.

Fixpoint genTreeSized' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => ret Leaf
  | S sz' =>
      freq [ (1,  ret Leaf) ;
             (sz, liftM3 Node g (genTreeSized' sz' g) (genTreeSized' sz' g)) ]
  end.

Fixpoint mirror {A : Type} (t : Tree A) : Tree A :=
  match t with
  | Leaf => Leaf
  | Node x l r => Node x (mirror r) (mirror l)
  end.

Fixpoint eq_dec_tree (t1 t2 : Tree nat) : {t1 = t2} + {t1 <> t2} :=
  match t1, t2 with
  | Leaf, Leaf => left eq_refl
  | Node x1 l1 r1, Node x2 l2 r2 =>
      if eq_dec x1 x2
      then if eq_dec_tree l1 l2
           then if eq_dec_tree r1 r2 then left _ else right _
           else right _
      else right _
  | _, _ => right _
  end.

Definition mirrorP {A} `{_ : Dec_Eq A} (t : Tree A) :=
  mirror (mirror t) = t?.

Definition faultyMirrorP (t: Tree nat) :=
  mirror t = t?.

(* ---------- 72.2 CheckerPlayground1：Checker = G Result ---------- *)

(* 原书第一间"游乐场"：自己动手造一个迷你版 QuickChick。
   核心观察：测试结果是"关于随机性的程序"，所以 Checker 就是
   G Result —— 一个产出 Result 的随机程序。 *)

Module CheckerPlayground1.

Inductive Result := Success | Failure.

#[export] Instance showResult : Show Result :=
{| show r := match r with Success => "Success" | Failure => "Failure" end |}.

Definition Checker := G Result.

(* Checkable 类型类：把"可检查的东西"统一抽象成 Checker。
   这里的 unit 实例在最终库里被淘汰了（库中 unit 表示放弃本测试点），
   bool 实例则与库中一致。 *)

Class Checkable (A : Type) : Type :=
  { checker : A -> Checker }.

#[export] Instance checkableBool : Checkable bool :=
  {| checker b := if b then ret Success else ret Failure |}.

(* Sample 抽取运行这个迷你 Checker：随机种子不影响常生成器，
   所以 (checker true) 每次都打印 11 个 Success，
   (checker false) 每次都打印 11 个 Failure。 *)
Sample (checker true).
(* 形如：
   [Success, Success, Success, Success, Success, Success, Success,
    Success, Success, Success, Success] *)
Sample (checker false).
(* 形如：
   [Failure, Failure, Failure, Failure, Failure, Failure, Failure,
    Failure, Failure, Failure, Failure] *)

End CheckerPlayground1.

(* ---------- 72.3 CheckerPlayground2：Prop 也可检查 ---------- *)

(* 第二间游乐场：借助可判定性实例 Dec（见第 69 章），
   任何命题 P 只要有 Dec P 就能变成 Checker。 *)

Module CheckerPlayground2.

Export CheckerPlayground1.

#[export] Instance checkableDec `{P : Prop} `{Dec P} : Checkable P :=
  {| checker p := if P? then ret Success else ret Failure |}.

(* 两个"猜想"：用 Conjecture 假设命题成立，QuickChick 来验算。
   Prop 在提取时被擦除，所以 checker c1 运行的是判定过程 0 = 42?，
   而不是去评估公理本身 —— 提取是安全的。 *)

Conjecture c1 : 0 = 42.
Conjecture c2 : 41 + 1 = 42.

Sample (checker c1).
(* 形如：
   [Failure, Failure, Failure, Failure, Failure, Failure, Failure,
    Failure, Failure, Failure, Failure] *)
Sample (checker c2).
(* 形如：
   [Success, Success, Success, Success, Success, Success, Success,
    Success, Success, Success, Success] *)

End CheckerPlayground2.

(* ---------- 72.4 CheckerPlayground3：forAll 的雏形 ---------- *)

Definition isRed (c : color) :=
  match c with
  | Red => true
  | _ => false
  end.

Module CheckerPlayground3.

Import CheckerPlayground2.

(* forAll 把生成器和性质粘在一起：
   从 g 采样一个 a，再把 f a 交给 checker。
   注意类型类参数 `{Checkable B}：被检查侧可以是 bool、Prop 等
   任何可检查的类型。 *)

Definition forAll {A B : Type} `{Checkable B} (g : G A) (f : A -> B)
    : Checker :=
  a <- g ;;
  checker (f a).

Sample (forAll genColor isRed).
(* 形如（红黄蓝绿等概率出现，isRed 只在 Red 上为真）：
   [Failure, Failure, Failure, Failure, Failure, Success, Failure,
    Failure, Success, Failure, Failure] *)

Sample (forAll (genTreeSized 3 (choose (0, 3))) mirrorP).
(* 形如：11 个 Success（镜像两次必复原） *)

Sample (forAll (genTreeSized 3 (choose (0, 3))) faultyMirrorP).
(* 形如（Success 与 Failure 混杂，只有对称树通过）：
   [Success, Failure, Success, Failure, Success, Failure, Success,
    Success, Success, Success, Failure] *)

End CheckerPlayground3.

(* ---------- 72.5 CheckerPlayground4：失败时打印反例 ---------- *)

(* 第三间游乐场的失败只报 Failure，不知道输在哪。
   第四间让 Failure 携带反例的字符串表示：
   这需要生成侧的 A 有 Show 实例，但 Show 只用于打印，
   提取后生成的 OCaml 代码不会用到被测性质里的 Show 信息。 *)

Module CheckerPlayground4.

Export CheckerPlayground2.

Inductive Result :=
| Success : Result
| Failure : forall {A} `{Show A}, A -> Result.

#[export] Instance showResult : Show Result :=
{| show r := match r with Success => "Success" | Failure _ _ a => show a end |}.

Definition Checker := G Result.

Class Checkable (A : Type) : Type :=
  { checker : A -> Checker }.

#[export] Instance checkableBool : Checkable bool :=
{| checker b := if b then ret Success else ret Failure |}.

#[export] Instance checkableDec `{P : Prop} `{Dec P} : Checkable P :=
{| checker p := if P? then ret Success else ret Failure |}.

#[export] Instance showUnit : Show unit :=
{| show u := "tt" |}.

(* 关键技巧：采样 a 后，把 (a, tt) 打包再包一层 checker。
   成功时无妨（showUnit 打印 tt），失败时 Failure 携带的就是
   反例 a 本身 —— pair 的 Show 实例会把 a 打印出来。 *)

Definition forAll {A B : Type} `{Show A} `{Checkable B}
                  (g : G A) (f : A -> B) : Checker :=
  a <- g ;;
  checker (f a, tt).

Sample (forAll genColor isRed).
(* 形如：失败项里直接带着反例颜色
   [Failure (Blue, tt), Failure (Red? 不一定) …… 实为
    Failure (Blue, tt), Failure (Yellow, tt), Success, Failure (Green, tt), …] *)

Sample (forAll (genTreeSized 3 (choose (0, 3))) faultyMirrorP).
(* 形如（反例树被打印出来）：
   [Failure (Node (1) (Leaf) (Leaf), tt),
    Failure (Node (0) (Node (2) (Leaf) (Leaf)) (Leaf), tt),
    Success, Success,
    Failure (Node (2) (Node (2) (Leaf) (Leaf)) (Leaf), tt), …] *)

(* 真正的 QuickChick 命令驱动这套迷你 Checker：
   库中的 QuickChick 命令只认库里的 Checker / Checkable，
   这里的游乐场定义与库并不兼容，所以原书此处也是注释掉的。
   若把同名定义放到库语境下运行，输出形如：
   *** Failed after 1 tests and 0 shrinks. (0 discards) *)
(* QuickChick (forAll (genTreeSized 5 (choose (0,5))) faultyMirrorP). *)

End CheckerPlayground4.

(* ---------- 72.6 库里真正的 Checker 与 forAll ---------- *)

(* 库中的真货与游乐场的差别有三：
   - Result 不只是 Success / Failure，而是携带一堆字段的记录：
     ok（成功/失败/放弃三态）、reason（失败原因字符串）、
     stamp（collect 收集的分布标签）、callbacks（whenFail 打印）等；
   - Checkable 的实例多得多：bool、unit（放弃）、Dec、Prop、
     G QProp、Checker 本身、option，乃至函数（testFun 即 forAllShrink）；
   - 这些实例组成一条"实例链"：嵌套的 forAll 之所以能工作，
     是因为每层 bind 后 Checker 自己仍可被 checker 接受。 *)

Check @forAll.
(*
     : forall A prop : Type,
       Producer G A ->
       Checkable prop -> G A -> (A -> prop) -> Checker
*)

Check @forAllShrink.
(*
     : forall A prop : Type,
       Producer G A ->
       Checkable prop ->
       G A -> (A -> list A) -> (A -> prop) -> Checker
*)

Check @forAllProof.
(*
     : forall (A : Type) (prop : A -> Prop),
       Checkable (forall x : A, prop x) ->
       Producer G A ->
       (forall x : A, Producer G (semProd G gen x)) -> ...
       即 forAllProof gen pf 要求对任意 x 提供"gen 能产生 x"的证据，
       返回性质 forall x, semProd gen x -> prop x —— 把随机测试
       提升成关于生成器覆盖范围的定理。实践中多为内部工具，很少手写。
*)

(* 库版 forAll 失败时会打印反例（Show A 的责任在生成侧，
   性质侧只需 Checkable）： *)

Definition treesMirrorP :=
  forAll (genTreeSized' 3 (choose (0, 3))) mirrorP.

QuickChick treesMirrorP.
(* 形如：
   +++ Passed 10000 tests (0 discards) *)

QuickChick (forAll (genTreeSized' 3 (choose (0, 3))) faultyMirrorP).
(* 形如（不做收缩时反例可能很大）：
   *** Failed after 1 tests and 0 shrinks. (0 discards)
   Node (2) (Node (2) (Leaf) (Node (1) (Leaf) (Leaf))) (Leaf) *)

(* unit 的 Checkable 实例表示"放弃本测试点"（discard 的另一入口）： *)
QuickChick (forAll (ret 0) (fun _ : nat => tt)).
(* 形如：
   *** Gave up! Passed only 0 tests
   Discarded: 20000
   连续 20000 次（默认 maxDiscard）都放弃后，QuickChick 认输。 *)

(* ---------- 72.7 Shrinking：收缩实例与收缩语义 ---------- *)

(* Shrink 类只有一个方法 shrink : A -> list A，
   要求返回的候选都比原值"更小"。收缩是保持失败前提下的
   贪心局部搜索：每次跳到第一个仍让性质失败的候选，直到
   没有更小的失败候选为止。 *)

#[export] Instance shrinkColor : Shrink color :=
{| shrink c :=
     match c with
     | Red => []
     | Green => [Red]
     | Blue => [Red; Green]
     | Yellow => [Red; Green; Blue]
     end |}.

(* 库自带实例：shrink nat 每次折半（对数级），
   shrink list 先收缩尾再收缩头（shrinkListAux），
   shrink pair 先收缩第一个分量再收缩第二个。 *)

Eval vm_compute in (shrink 42).
(*
     = [21; 10; 5; 2; 1; 0]
     : list nat
*)

Eval vm_compute in (shrink (1, [2; 3])).
(*
     = [(0, [2; 3]); (1, [3]); (1, [2]); (1, [2; 1]); (1, [2; 0]);
        (1, [1; 3]); (1, [0; 3])]
     : list (nat * list nat)
*)

Print shrinkList.
(* 可看到 shrink list 直接复用 shrinkListAux，
   而 shrinkListAux 是"交替收缩元素、收缩结构"的递归。 *)

(* 对树定义收缩：先砍成子树，再收缩节点载荷，再递归收缩子树。
   注意 Open Scope list 让 ++ 走 list_scope。 *)

Open Scope list.

#[export, program] Instance shrinkTreeAux {A} `{Shrink A} : Shrink (Tree A) :=
  {| shrinkAux t :=
       match t with
       | Leaf => []
       | Node x l r =>
           [l] ++ [r]
                ++ map (fun x' => Node x' l r) (shrink x)
                ++ map (fun l' => Node x l' r) (shrink l)
                ++ map (fun r' => Node x l r') (shrink r)
       end |}.

#[export] Instance shrinkTree {A} `{Shrink A} : Shrink (Tree A) :=
  {| shrink x := shrinkAux x |}.

(* forAllShrink 的完整循环：生成、发现失败、收缩到局部极小反例。 *)

QuickChick (forAllShrink (genTreeSized' 5 (choose (0, 5))) shrink faultyMirrorP).
(* 形如：
   *** Failed after 1 tests and 8 shrinks. (0 discards)
   Node (0) (Leaf) (Node (0) (Leaf) (Leaf))
   8 步收缩把一棵大树砍成最小的非对称树。 *)

(* 有了 Gen + Shrink 两个实例，ArbitraryOfGenShrink 桥接出 Arbitrary，
   于是 faultyMirrorP 这种 nat -> Tree nat -> ... 形式的性质
   可以直接交给 QuickChick（testFun 实例内部就是 forAllShrink）。 *)

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.

QuickChick faultyMirrorP.
(* 形如：
   *** Failed after 1 tests and 4 shrinks. (0 discards)
   Node (0) (Node (0) (Leaf) (Leaf)) (Leaf) *)

(* ---------- 72.8 TernaryTree 案例：生成 + 收缩 + 修复 ---------- *)

Inductive TernaryTree A :=
| TLeaf : TernaryTree A
| TNode : A -> TernaryTree A -> TernaryTree A -> TernaryTree A
          -> TernaryTree A.

Arguments TLeaf {A}.
Arguments TNode {A} _ _ _ _.

(* 故意写错的镜像：中子树忘了镜像。 *)

Fixpoint tern_mirror {A} (t : TernaryTree A) : TernaryTree A :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r => TNode x (tern_mirror r) m (tern_mirror l)
  end.

#[export] Instance showTernTree {A} `{Show A} : Show (TernaryTree A) :=
{| show := showTernTreeAux |}
where showTernTreeAux := fix aux (t : TernaryTree A) : string :=
  match t with
  | TLeaf => "TLeaf"
  | TNode x l m r =>
      ("TNode (" ++ show x ++ ") (" ++ aux l ++ ") ("
                 ++ aux m ++ ") (" ++ aux r ++ ")")%string
  end.

(* 三叉树生成器：没有 liftM4，嵌套 bind 即可。 *)

Fixpoint genTernTreeSized {A} (sz : nat) (g : G A) : G (TernaryTree A) :=
  match sz with
  | O => ret TLeaf
  | S sz' =>
      freq [ (1,  ret TLeaf) ;
             (sz, x <- g ;;
                  l <- genTernTreeSized sz' g ;;
                  m <- genTernTreeSized sz' g ;;
                  r <- genTernTreeSized sz' g ;;
                  ret (TNode x l m r)) ]
  end.

Sample (@genTernTreeSized nat 3 (choose (0, 10))).
(* 形如：11 棵随机三叉树，深度受 sz=3 限制 *)

(* 收缩三叉树：先砍成三棵子树之一，再收缩载荷与三棵子树。 *)

#[export, program] Instance shrinkTernTreeAux {A} `{Shrink A}
    : Shrink (TernaryTree A) :=
  {| shrinkAux t :=
       match t with
       | TLeaf => []
       | TNode x l m r =>
           [l] ++ [m] ++ [r]
                ++ map (fun x' => TNode x' l m r) (shrink x)
                ++ map (fun l' => TNode x l' m r) (shrink l)
                ++ map (fun m' => TNode x l m' r) (shrink m)
                ++ map (fun r' => TNode x l m r') (shrink r)
       end |}.

#[export] Instance shrinkTernTree {A} `{Shrink A} : Shrink (TernaryTree A) :=
  {| shrink x := shrinkAux x |}.

Inductive direction := Left | Middle | Right.

#[export] Instance showDirection : Show direction :=
{| show d :=
     match d with
     | Left => "Left"
     | Middle => "Middle"
     | Right => "Right"
     end |}.

Definition genDirection : G direction := elems [Left; Middle; Right].

#[export] Instance shrinkDirection : Shrink direction :=
{| shrink d :=
     match d with
     | Left => []
     | Middle => [Left]
     | Right => [Left]
     end |}.

(* 沿路径下潜：只在中子树里才可能暴露 tern_mirror 的 bug。 *)

Definition path := list direction.

#[export] Instance showPath : Show path := showList.

#[export] Instance genPath : Gen path := { arbitrary := listOf genDirection }.

#[export] Instance shrinkPath : Shrink path := shrinkList.

Fixpoint traverse_node (t : TernaryTree nat) (d : direction)
    : option (TernaryTree nat) :=
  match t, d with
  | TLeaf, _ => None
  | TNode _ l _ _, Left => Some l
  | TNode _ _ m _, Middle => Some m
  | TNode _ _ _ r, Right => Some r
  end.

Fixpoint traverse_path (t : TernaryTree nat) (p : path)
    : option (TernaryTree nat) :=
  match p with
  | [] => Some t
  | d :: p' =>
      match traverse_node t d with
      | Some t' => traverse_path t' p'
      | None => None
      end
  end.

Definition path_mirror (t : TernaryTree nat) (p : path)
    : option (TernaryTree nat) * option (TernaryTree nat) :=
  (traverse_path t p, traverse_path (tern_mirror t) p).

Fixpoint eq_dec_tern_tree (t1 t2 : TernaryTree nat)
    : {t1 = t2} + {t1 <> t2}.
(* 判定树相等：逐节点比较载荷并递归比较三棵子树；
   省略的实现细节与 eq_dec_tree 完全同构，此处用书上的略写占位。 *)
Admitted.

Definition tern_mirror_path_flip (t : TernaryTree nat) (p : path) :=
  let (l, r) := path_mirror t p in
  match (l, r) with
  | (Some l', Some r') =>
      if eq_dec_tern_tree l' (tern_mirror r') then true else false
  | (None, None) => true
  | _ => false
  end.

(* 手写的生成 + 收缩链路，看最小反例长什么样。 *)

Definition bug_finding_tern_tree : Checker :=
  forAllShrink (@genTernTreeSized nat 5 (choose (0, 10))) shrink
    (fun t =>
       forAllShrink (listOf genDirection) shrink
         (fun p => tern_mirror_path_flip t p)).

QuickChick bug_finding_tern_tree.
(* 形如：
   *** Failed after N tests and M shrinks. (0 discards)
   TNode 0 (TNode 0 TLeaf TLeaf TLeaf) TLeaf TLeaf
   [Middle]
   路径 [Middle] 把测试引到中子树，而 tern_mirror 没有镜像它，
   于是 l' 与 tern_mirror r' 不等。 *)

(* 修复：给中子树也套上 tern_mirror。 *)

Fixpoint tern_mirror_fixed {A} (t : TernaryTree A) : TernaryTree A :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r =>
      TNode x (tern_mirror_fixed r) (tern_mirror_fixed m)
              (tern_mirror_fixed l)
  end.

Definition path_mirror_fixed (t : TernaryTree nat) (p : path)
    : option (TernaryTree nat) * option (TernaryTree nat) :=
  (traverse_path t p, traverse_path (tern_mirror_fixed t) p).

Definition tern_mirror_path_flip_fixed (t : TernaryTree nat) (p : path) :=
  let (l, r) := path_mirror_fixed t p in
  match (l, r) with
  | (Some l', Some r') =>
      if eq_dec_tern_tree l' (tern_mirror_fixed r') then true else false
  | (None, None) => true
  | _ => false
  end.

Definition tern_tree_fixed_test : Checker :=
  forAllShrink (@genTernTreeSized nat 5 (choose (0, 10))) shrink
    (fun t =>
       forAllShrink (listOf genDirection) shrink
         (fun p => tern_mirror_path_flip_fixed t p)).

QuickChick tern_tree_fixed_test.
(* 形如：
   +++ Passed 10000 tests (0 discards) *)

(* 注册类型类实例后，性质里的两个参数都能自动走
   "生成 + 收缩"的标准链路，一行 QuickChick 即可。 *)

#[export] Instance genTernTree {A} `{Gen A} : GenSized (TernaryTree A) :=
  {| arbitrarySized n := genTernTreeSized n arbitrary |}.

QuickChick tern_mirror_path_flip.
(* 形如：
   *** Failed after N tests and M shrinks. (0 discards)
   TNode 0 TLeaf TLeaf (TNode 0 TLeaf TLeaf TLeaf)  ……之类的极小反例 *)

(* ---------- 72.9 collect：观察测试数据分布 ---------- *)

Check @collect.
(*
     : forall A prop : Type, Show A -> Checkable prop -> A -> prop -> Checker
   把 show x 作为标签贴到本次测试的结果上，报告按标签聚合计数。
*)

Fixpoint size {A} (t : Tree A) : nat :=
  match t with
  | Leaf => 0
  | Node _ l r => 1 + size l + size r
  end.

Definition treeProp (g : nat -> G nat -> G (Tree nat)) n :=
  forAll (g n (choose (0, n))) (fun t => collect (size t) true).

QuickChick (treeProp genTreeSized 5).
(* 形如（oneOf 各半，约一半测试点直接是 Leaf）：
   4947x: 0
   1258x: 1
    673x: 2
    464x: 6
    ……
   +++ Passed 10000 tests (0 discards) *)

QuickChick (treeProp genTreeSized' 5).
(* 形如（freq 偏向 Node，空树只占零头）：
   1624x: 0
   ……
    571x: 10
    564x: 8
    562x: 9
   +++ Passed 10000 tests (0 discards) *)

(* 练习 genTreeSized''：彻底消灭空树 —— sz=0 时也给一棵
   "载荷随机、子树全空"的最小 Node。 *)

Fixpoint genTreeSized'' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => liftM3 Node g (ret Leaf) (ret Leaf)
  | S sz' =>
      freq [ (1,  ret Leaf) ;
             (sz, liftM3 Node g (genTreeSized'' sz' g)
                               (genTreeSized'' sz' g)) ]
  end.

QuickChick (treeProp genTreeSized'' 5).
(* 形如：分布中完全没有 "Nx: 0" 这一行
   +++ Passed 10000 tests (0 discards) *)

(* ---------- 72.10 五个常用 Checker 组合子 ---------- *)

(* whenFail：失败时打印一条消息（横幅式的自解释）。 *)

Definition whenFailDemo : Checker :=
  whenFail "every color is Red?!" (forAll genColor isRed).

QuickChick whenFailDemo.
(* 形如：
   *** Failed after 1 tests and 0 shrinks. (0 discards)
   every color is Red?!
   Green *)

(* expectFailure：预期失败 —— 找到反例反而算通过；
   如果全部通过则以 "*** Failed! Passed N tests (expected Failure)" 报错。 *)

Definition expectFailureDemo : Checker :=
  expectFailure (forAll genColor isRed).

QuickChick expectFailureDemo.
(* 形如：
   +++ Failed (as expected) after 1 tests and 0 shrinks. (0 discards) *)

Definition expectFailureAllPass : Checker :=
  expectFailure (forAll genColor (fun _ => true)).

QuickChick expectFailureAllPass.
(* 形如：
   *** Failed! Passed 10000 tests (expected Failure) *)

(* conjoin：所有 Checker 都成功才算成功（各自独立生成数据）。 *)

Definition conjoinDemo : Checker :=
  conjoin [ forAll (choose (0, 10)) (fun n => n <=? 10) ;
            forAll (choose (0, 10)) (fun n => n <? 10) ].

QuickChick conjoinDemo.
(* 形如：第一个恒真、第二个在 n=10 处失败
   *** Failed after … tests …
   10 *)

(* disjoin：至少一个成功就算成功（第一个失败后才跑第二个）。 *)

Definition disjoinDemo : Checker :=
  disjoin [ forAll (choose (0, 10)) (fun n => n <? 0) ;
            forAll (choose (0, 10)) (fun n => 0 <=? n) ].

QuickChick disjoinDemo.
(* 形如：
   +++ Passed … *)

(* tag 与 collect 类似，但标签是手写的字符串而非 show 出来的值；
   适合把数据按"类别"分桶。下面这个例子把 nat 分成三桶：
   等于 3、大于 2、其余。 *)

Definition tag_prop (x : nat) : Checker :=
  collect x (if x = 3 ? then tag "3" false
             else if 2 <? x then tag "more than 2" false
             else checker true).

QuickChick tag_prop.
(* 形如（tag "3" 的失败行带 Tag 前缀）：
   *** Failed after … tests …
   Tag: 3
   3 *)

(* ---------- 72.11 Args 调参与默认参数 ---------- *)

(* QuickChick 命令背后用的是 Args 记录：
     Record Args := MkArgs
       { replay     : option (RandomSeed * nat)  (* 回放种子与大小 *)
       ; maxSuccess : nat                        (* 目标成功数 *)
       ; maxDiscard : nat                        (* 允许放弃数 *)
       ; maxShrinks : nat                        (* 最大收缩步数 *)
       ; maxSize    : nat                        (* 尺寸上限 *)
       ; chatty     : bool                       (* 是否打印进度 *)
       ; analysis   : bool                       (* 2.2 新增：分布分析 *)
       }.
   默认值由四个可提取常量给出：
     Axiom defNumTests    : nat. Extract Constant defNumTests    => "10000".
     Axiom defNumDiscards : nat. Extract Constant defNumDiscards => "20000".
     Axiom defNumShrinks  : nat. Extract Constant defNumShrinks  => "1000".
     Axiom defSize        : nat. Extract Constant defSize        => "10".
   想全局改默认值，就在导入 QuickChick 之后、任何 QuickChick 命令之前
   写下自己的 Extract Constant（例如把 defNumTests 改成 100）。 *)

Check stdArgs.
(*
     : Args
   stdArgs = MkArgs None defNumTests defNumDiscards defNumShrinks
                     defSize true doAnalysis（doAnalysis 默认 false）。 *)

(* 单次调参用 QuickChickWith（见 73 章）：
   QuickChickWith (updMaxSuccess stdArgs 100) myProp.
   updMaxSize / updMaxSuccess / updAnalysis 三个更新函数可用。 *)

End Ex72Checkers.
