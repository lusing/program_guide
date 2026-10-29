(* 72 可检查性质与收缩 —— Checker 结果类型与 Checkable 类、
   CheckerPlayground 四步渐进、forAll / forAllShrink / forAllProof、
   Shrink 实例与贪心收缩、TernaryTree 综合案例、collect / tag 统计、
   whenFail / expectFailure / conjoin / disjoin、Args 调参与默认参数 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick. Import QcNotation.
From Stdlib Require Import Arith Bool List ZArith. Import ListNotations.
Require Export ExtLib.Structures.Monads.
Export MonadNotation. Open Scope monad_scope.
From Stdlib Require Import String. Local Open Scope string.

Module Ex72Checkers.

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
  {| show := let fix aux t :=
       match t with
         | Leaf => "Leaf"
         | Node x l r =>
             "Node (" ++ show x ++ ") ("
                      ++ aux l ++ ") ("
                      ++ aux r ++ ")"
       end
     in aux
  |}.

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

#[export] Instance eq_dec_tree (t1 t2 : Tree nat) : Dec (t1 = t2).
Proof. constructor; dec_eq. Defined.

Definition mirrorP (t : Tree nat) := (mirror (mirror t)) = t?.

Definition faultyMirrorP (t : Tree nat) := (mirror t) = t ?.

(* ---------- 72.2 CheckerPlayground1：Checker = G Result ---------- *)

(* 原书第一间"游乐场"：自己动手造一个迷你版 QuickChick。
   核心观察：测试结果是"关于随机性的程序"，所以 Checker 就是
   G Result —— 一个产出 Result 的随机程序。 *)

Module CheckerPlayground1.

Inductive Result := Success | Failure.

#[export] Instance showResult : Show Result :=
  {
    show r := match r with Success => "Success" | Failure => "Failure" end
  }.

Definition Checker := G Result.

(* Checkable 类型类：把"可检查的东西"统一抽象成 Checker。
   这里的 unit 实例在最终库里被淘汰了（库中 unit 表示放弃本测试点），
   bool 实例则与库中一致。 *)

Class Checkable (A : Type) : Type :=
  { checker : A -> Checker }.

#[export] Instance checkableBool : Checkable bool :=
  {
    checker b := if b then ret Success else ret Failure
  }.

End CheckerPlayground1.

(* ---------- 72.3 CheckerPlayground2：Prop 也可检查 ---------- *)

(* 第二间游乐场：借助可判定性实例 Dec（见第 69 章），
   任何命题 P 只要有 Dec P 就能变成 Checker。 *)

Module CheckerPlayground2.

Export CheckerPlayground1.

#[export] Instance checkableDec `{P : Prop} `{Dec P} : Checkable P :=
  {
    checker p := if P? then ret Success else ret Failure
  }.

(* 两个"猜想"：用 Conjecture 假设命题成立，QuickChick 来验算。
   Prop 在提取时被擦除，所以 checker c1 运行的是判定过程 0 = 42?，
   而不是去评估公理本身 —— 提取是安全的。 *)

Conjecture c1 : 0 = 42.

Conjecture c2 : 41 + 1 = 42.

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

End CheckerPlayground3.

(* ---------- 72.5 CheckerPlayground4：失败时打印反例 ---------- *)

(* 第三间游乐场的失败只报 Failure，不知道输在哪。
   第四间让 Failure 携带反例本身：Failure 变成依赖构造子，
   打包"任意可打印的值"。bool / Dec 检查器没有有用信息可记，
   就拿 unit 的唯一居民 tt 当"失败原因"占位。 *)

Module CheckerPlayground4.

Export CheckerPlayground2.

Inductive Result :=
  | Success : Result
  | Failure : forall {A} `{Show A}, A -> Result.

#[export] Instance showResult : Show Result :=
  {
    show r := match r with
                Success => "Success"
              | Failure a => "Failure: " ++ show a
              end
  }.

Definition Checker := G Result.

Class Checkable (A : Type) : Type :=
  { checker : A -> Checker }.

#[export] Instance showUnit : Show unit :=
  {
    show u := "tt"
  }.

#[export] Instance checkableBool : Checkable bool :=
  {
    checker b := if b then ret Success else ret (Failure tt)
  }.

#[export] Instance checkableDec `{P : Prop} `{Dec P} : Checkable P :=
  {
    checker p := if P? then ret Success else ret (Failure tt)
  }.

(* 关键改动在 forAll：先采样 a、再检查 f a 得到 r，
   失败时不是丢掉 a，而是把 (a, b) 打包进新的 Failure ——
   a 是让性质失败的输入，b 是失败原因。多个 forAll 连用时，
   反例会累积成嵌套的元组，一层都不丢。 *)

Definition forAll {A B : Type} `{Show A} `{Checkable B}
                  (g : G A) (f : A -> B) : Checker :=
  a <- g ;;
  r <- checker (f a) ;;
  match r with
    Success => ret Success
  | Failure b => ret (Failure (a,b))
  end.

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

Definition faultyForAllP : Checker :=
  forAll (genTreeSized' 3 (choose (0, 3))) faultyMirrorP.

(* unit 的 Checkable 实例表示"放弃本测试点"（discard 的另一入口），
   连续 20000 次（默认 maxDiscard）都放弃后，QuickChick 认输。 *)

Definition giveUpP : Checker :=
  forAll (ret 0) (fun _ : nat => tt).

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

Fixpoint shrinkTreeAux {A}
              (s : A -> list A) (t : Tree A)
            : list (Tree A) :=
  match t with
    | Leaf => []
    | Node x l r => [l] ++ [r] ++
                    map (fun x' => Node x' l r) (s x) ++
                    map (fun l' => Node x l' r) (shrinkTreeAux s l) ++
                    map (fun r' => Node x l r') (shrinkTreeAux s r)
  end.

#[export] Instance shrinkTree {A} `{Shrink A} : Shrink (Tree A) :=
  {| shrink x := shrinkTreeAux shrink x |}.

(* forAllShrink 的完整循环：生成、发现失败、收缩到局部极小反例。 *)

Definition faultyShrinkP : Checker :=
  forAllShrink (genTreeSized' 5 (choose (0, 5))) shrink faultyMirrorP.

(* 有了 Gen + Shrink 两个实例，ArbitraryOfGenShrink 桥接出 Arbitrary，
   于是 faultyMirrorP 这种 nat -> Tree nat -> ... 形式的性质
   可以直接交给 QuickChick（testFun 实例内部就是 forAllShrink）。 *)

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.

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
  {| show := let fix aux t :=
       match t with
         | TLeaf => "TLeaf"
         | TNode x l m r =>
             ("TNode (" ++ show x ++ ") ("
                      ++ aux l ++ ") ("
                      ++ aux m ++ ") ("
                      ++ aux r ++ ")")%string
       end
     in aux
  |}.

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

(* 收缩三叉树：先砍成三棵子树之一，再收缩载荷与三棵子树。 *)

Fixpoint shrinkTernTreeAux {A}
              (s : A -> list A) (t : TernaryTree A)
            : list (TernaryTree A) :=
  match t with
    | TLeaf => []
    | TNode x l m r => [l] ++ [m] ++ [r] ++
                    map (fun x' => TNode x' l m r) (s x) ++
                    map (fun l' => TNode x l' m r) (shrinkTernTreeAux s l) ++
                    map (fun m' => TNode x l m' r) (shrinkTernTreeAux s m) ++
                    map (fun r' => TNode x l m r') (shrinkTernTreeAux s r)
  end.

#[export] Instance shrinkTernTree {A} `{Shrink A} : Shrink (TernaryTree A) :=
  {| shrink x := shrinkTernTreeAux shrink x |}.

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

Definition traverse_node {A} (t : direction) (l m r : TernaryTree A) :=
  match t with
  | Left => l
  | Middle => m
  | Right => r
  end.

Fixpoint traverse_path {A} (p : path) (t : TernaryTree A) :=
  match t with
  | TLeaf =>
    TLeaf
  | TNode x l m r =>
    match p with
    | h :: tl => traverse_path tl (traverse_node h l m r)
    | [] => t
    end
  end.

Definition path_mirror := map (fun t => match t with
                                     | Left => Right
                                     | Right => Left
                                     | _ => t
                                     end).

(* 判定三叉树相等：与 eq_dec_tree 一样走 Dec 实例 + dec_eq。 *)

#[export] Instance eq_dec_tern_tree (t1 t2 : TernaryTree nat) : Dec (t1 = t2).
Proof. constructor; dec_eq. Defined.

Definition tern_mirror_path_flip (t : TernaryTree nat) (p : path) :=
  (  traverse_path p t
   = tern_mirror (traverse_path (path_mirror p) (tern_mirror t))) ?.

(* 手写的生成 + 收缩链路，看最小反例长什么样。 *)

Definition bug_finding_tern_tree : Checker :=
  forAllShrink (@genTernTreeSized nat 5 (choose (0, 10))) shrink
    (fun t =>
       forAllShrink (listOf genDirection) shrink
         (fun p => tern_mirror_path_flip t p)).

(* 修复：给中子树也套上 tern_mirror。 *)

Fixpoint tern_mirror_fixed {A} (t : TernaryTree A) : TernaryTree A :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r =>
      TNode x (tern_mirror_fixed r) (tern_mirror_fixed m)
              (tern_mirror_fixed l)
  end.

Definition tern_mirror_path_flip_fixed (t : TernaryTree nat) (p : path) :=
  (  traverse_path p t
   = tern_mirror_fixed (traverse_path (path_mirror p) (tern_mirror_fixed t))) ?.

Definition tern_tree_fixed_test : Checker :=
  forAllShrink (@genTernTreeSized nat 5 (choose (0, 10))) shrink
    (fun t =>
       forAllShrink (listOf genDirection) shrink
         (fun p => tern_mirror_path_flip_fixed t p)).

(* 注册类型类实例后，性质里的两个参数都能自动走
   "生成 + 收缩"的标准链路，一行 QuickChick 即可。 *)

#[export] Instance genTernTree {A} `{Gen A} : GenSized (TernaryTree A) :=
  {| arbitrarySized n := genTernTreeSized n arbitrary |}.

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

(* 练习 genTreeSized''（原书 2 星）：让空树更少。思路：只要还有
   燃料（sz >= 1），根部就强制为 Node，空树率降到 0；子树退回
   genTreeSized' 保持形状随机（子树仍可随机终止为 Leaf）。 *)

Fixpoint genTreeSized'' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
  | O => ret Leaf
  | S sz' =>
      liftM3 Node g (genTreeSized' sz' g) (genTreeSized' sz' g)
  end.

(* ---------- 72.10 五个常用 Checker 组合子 ---------- *)

(* whenFail：失败时打印一条消息（横幅式的自解释）。 *)

Definition whenFailDemo : Checker :=
  whenFail "every color is Red?!" (forAll genColor isRed).

(* expectFailure：预期失败 —— 找到反例反而算通过；
   如果全部通过则以 "*** Failed! Passed N tests (expected Failure)" 报错。 *)

Definition expectFailureDemo : Checker :=
  expectFailure (forAll genColor isRed).

Definition expectFailureAllPass : Checker :=
  expectFailure (forAll genColor (fun _ => true)).

(* conjoin：所有 Checker 都成功才算成功（各自独立生成数据）。 *)

Definition conjoinDemo : Checker :=
  conjoin [ forAll (choose (0, 10)) (fun n => (n <=? 10)%nat) ;
            forAll (choose (0, 10)) (fun n => (n <? 10)%nat) ].

(* disjoin：至少一个成功就算成功（第一个失败后才跑第二个）。 *)

Definition disjoinDemo : Checker :=
  disjoin [ forAll (choose (0, 10)) (fun n => (n <? 0)%nat) ;
            forAll (choose (0, 10)) (fun n => (0 <=? n)%nat) ].

(* tag 与 collect 类似，但标签是手写的字符串而非 show 出来的值；
   适合把数据按"类别"分桶。下面这个例子把 nat 分成三桶：
   等于 3、大于 2、其余。 *)

Definition tag_prop (x : nat) : Checker :=
  collect x (if (x =? 3)%nat then tag "3" false
             else if (2 <? x)%nat then tag "more than 2" false
             else checker true).

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

(* 测试命令统一放在模块外：QuickChick / Sample 经 OCaml 抽取执行，
   而抽取在 Module 内通常不工作（原书在 CheckerPlayground1 结尾
   专门注明了这一点），会报 Unbound value quickchick。命令放到
   模块外、引用模块内容则一切正常。

   但游乐场的 Sample 仍然只能保持注释（与原书一致）：Sample 命令
   只认库里的 Show / 生成器体系，对游乐场自定义的 Checker /
   Checkable 抽取时会触发 Rocq 编译器异常（evar in typeops）——
   教学玩具就停留在"读"的层面，真跑测试用下面的库版命令。 *)

Import Ex72Checkers.

(* 游乐场 1：随机种子不影响常生成器，(checker true) 每次都打印
   11 个 Success，(checker false) 每次都打印 11 个 Failure。 *)
(* Sample (CheckerPlayground1.checker true). *)
(* 形如：
   [Success, Success, Success, Success, Success, Success, Success,
    Success, Success, Success, Success] *)
(* Sample (CheckerPlayground1.checker false). *)
(* 形如：
   [Failure, Failure, Failure, Failure, Failure, Failure, Failure,
    Failure, Failure, Failure, Failure] *)

(* 游乐场 2：两个"猜想"的可判定检查。 *)
(* Sample (CheckerPlayground2.checker CheckerPlayground2.c1). *)
(* 形如：11 个 Failure *)
(* Sample (CheckerPlayground2.checker CheckerPlayground2.c2). *)
(* 形如：11 个 Success *)

(* 游乐场 3：forAll 把生成器与性质粘在一起。 *)
(* Sample (CheckerPlayground3.forAll genColor isRed). *)
(* 形如（红黄蓝绿等概率出现，isRed 只在 Red 上为真）：
   [Failure, Failure, Failure, Failure, Failure, Success, Failure,
    Failure, Success, Failure, Failure] *)

(* Sample (CheckerPlayground3.forAll (genTreeSized 3 (choose (0, 3))) mirrorP). *)
(* 形如：11 个 Success（镜像两次必复原） *)

(* Sample (CheckerPlayground3.forAll (genTreeSized 3 (choose (0, 3))) faultyMirrorP). *)
(* 形如（Success 与 Failure 混杂，只有对称树通过）：
   [Success, Failure, Success, Failure, Success, Failure, Success,
    Success, Success, Success, Failure] *)

(* 游乐场 4：失败携带反例本身。 *)
(* Sample (CheckerPlayground4.forAll genColor isRed). *)
(* 形如：失败项里直接带着反例颜色
   [Failure: (Blue, tt), Failure: (Yellow, tt), Success, …] *)

(* Sample (CheckerPlayground4.forAll (genTreeSized 3 (choose (0, 3))) faultyMirrorP). *)
(* 形如（反例树被打印出来）：
   [Failure: (Node (2) (Node (3) (Node (2) (Leaf) (Leaf)) (Leaf))
                    (Node (0) (Node (2) (Leaf) (Leaf)) (Leaf)), tt),
    Success, …] *)

(* 库版命令。 *)
QuickChick treesMirrorP.
(* 形如：
   +++ Passed 10000 tests (0 discards) *)

QuickChick faultyForAllP.
(* 形如（不做收缩时反例可能很大，一次实测）：
   Node (2) (Node (3) (Leaf) (Node (2) (Leaf) (Leaf))) (Node (3) (Leaf) (Node (0) (Leaf) (Leaf)))
   *** Failed after 3 tests and 0 shrinks. (0 discards) *)

QuickChick giveUpP.
(* 形如：
   *** Gave up! Passed only 0 tests
   Discarded: 20000 *)

QuickChick faultyShrinkP.
(* 形如（一次实测）：
   Node (0) (Leaf) (Node (0) (Leaf) (Leaf))
   *** Failed after 1 tests and 5 shrinks. (0 discards)
   5 步收缩把一棵大树砍成最小的非对称树。 *)

QuickChick faultyMirrorP.
(* 形如（一次实测，Automatic 实例链自动走生成+收缩）：
   Node (0) (Leaf) (Node (0) (Leaf) (Leaf))
   *** Failed after 1 tests and 3 shrinks. (0 discards) *)

Sample (@genTernTreeSized nat 3 (choose (0, 10))).
(* 形如：11 棵随机三叉树，深度受 sz=3 限制 *)

QuickChick bug_finding_tern_tree.
(* 形如（一次实测）：
   TNode (0) (TLeaf) (TNode (0) (TLeaf) (TLeaf) (TNode (3) (TLeaf) (TLeaf) (TLeaf))) (TNode (1) (TLeaf) (TLeaf) (TLeaf))
   [Middle]
   *** Failed after 3 tests and 12 shrinks. (0 discards)
   路径 [Middle] 把测试引到中子树，而 tern_mirror 没有镜像它，
   两边的子树不再对应。 *)

QuickChick tern_tree_fixed_test.
(* 形如：
   +++ Passed 10000 tests (0 discards) *)

QuickChick tern_mirror_path_flip.
(* 形如（一次实测；实例链自动生成树与路径）：
   TNode (0) (TLeaf) (TNode (3) (TLeaf) (TLeaf) (TNode (0) (TLeaf) (TLeaf) (TLeaf))) (TNode (3) (TLeaf) (TNode (0) (TLeaf) (TLeaf) (TLeaf)) (TNode (2) (TLeaf) (TLeaf) (TLeaf)))
   [Middle]
   *** Failed after 1 tests and 0 shrinks. (0 discards) *)

QuickChick (treeProp genTreeSized 5).
(* 形如（QuickChick 2.2 的 collect 报告格式是"次数 : 标签"；
   oneOf 各半，约一半测试点直接是 Leaf，一次实测）：
   5007 : 0
   1259 : 1
    627 : 2
    472 : 5
    ……
   +++ Passed 10000 tests (0 discards) *)

QuickChick (treeProp genTreeSized' 5).
(* 形如（freq 偏向 Node，空树从约一半降到零头，一次实测）：
   1657 : 0
    601 : 12
    600 : 11
    580 : 13
    ……
   +++ Passed 10000 tests (0 discards) *)

QuickChick (treeProp genTreeSized'' 5).
(* 形如：分布中完全没有 "N : 0" 这一行（空树率 0）
   +++ Passed 10000 tests (0 discards) *)

QuickChick whenFailDemo.
(* 形如（一次实测）：
   every color is Red?!
   Yellow
   *** Failed after 1 tests and 0 shrinks. (0 discards) *)

QuickChick expectFailureDemo.
(* 形如：
   +++ Failed (as expected) after 1 tests and 0 shrinks. (0 discards) *)

QuickChick expectFailureAllPass.
(* 形如：
   *** Failed! Passed 10000 tests (expected Failure) *)

QuickChick conjoinDemo.
(* 形如：第一个恒真、第二个在 n=10 处失败
   *** Failed after … tests …
   10 *)

QuickChick disjoinDemo.
(* 形如：
   +++ Passed … *)

QuickChick tag_prop.
(* 形如（一次实测；tag 的分布行带 Tag 前缀）：
   4
   4 : 0
   1 : 2
   Tag: more than 2
   *** Failed after 6 tests and 0 shrinks. (0 discards) *)
