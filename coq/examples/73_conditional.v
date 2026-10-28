(* 73 条件性质与按规格生成 —— ==> 与 discard 风暴、maxDiscard 与 Gave up、
      collect 分布诊断、genSortedList 按规格生成、suchThatMaybe、BST 插入全流程 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List. Import ListNotations.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Import QcNotation.

Module Ex73Conditional.

Open Scope qc_scope.
Open Scope monad_scope.
Open Scope bool.
Open Scope nat.
Open Scope Checker_scope.

(* ---------- 73.1 条件性质：==> 与 discard ---------- *)

Fixpoint sorted (l : list nat) :=
  match l with
  | [] => true
  | x::xs => match xs with
             | [] => true
             | y :: ys => (x <=? y) && (sorted xs)
             end
  end.

Fixpoint insert (x : nat) (l : list nat) :=
  match l with
  | [] => [x]
  | y::ys => if x <=? y then x :: l
             else y :: insert x ys
  end.

Check implication.

(* 输出：
     implication : bool -> Checker -> Checker
   前提为 true 时检查结论；为 false 时丢弃（discard）当前测试用例。
   ==> 是它在 Checker_scope 里的记号（QcNotation 模块，level 55，右结合）。 *)

Definition insert_spec (x : nat) (l : list nat) :=
  sorted l ==> sorted (insert x l).

Definition test_insert_spec :=
  forAll (choose (0,10)) (fun x =>
  forAll (listOf (choose (0,10))) (fun l =>
  insert_spec x l)).

QuickChick test_insert_spec.

(* 一次实测输出（随机测试，具体数字每次运行都会变）：
     QuickChecking test_insert_spec
     +++ Passed 10000 tests (17325 discards)
   含义：10000 次前提成立的测试全部通过；另有 17325 个随机列表因不 sorted
   被丢弃——丢弃数约为有效测试数的 1.7 倍。 *)

(* ---------- 73.2 collect：看一眼被丢弃者的分布 ---------- *)

Definition insert_spec' (x : nat) (l : list nat) :=
  collect (List.length l) (insert_spec x l).

Definition test_insert_spec' :=
  forAll (choose (0,10)) (fun x =>
  forAll (listOf (choose (0,10))) (fun l =>
  insert_spec' x l)).

QuickChick test_insert_spec'.

(* 一次实测输出（数字随机，形态稳定）：
     QuickChecking test_insert_spec'
     3652 : (Discarded) 7
     3582 : 0
     3568 : (Discarded) 6
     3542 : 1
     3469 : (Discarded) 5
     3200 : (Discarded) 4
     2830 : (Discarded) 3
     1842 : 2
     1606 : (Discarded) 2
     716 : 3
     248 : 4
     61 : 5
     8 : 6
     1 : 7
     +++ Passed 10000 tests (18325 discards)
   含义：通过的测试里长度 0/1/2 的列表占去 3582 + 3542 + 1842 ≈ 90%；
   长度 >= 3 的几乎全部落在各 (Discarded) 行里——长列表几乎从不 sorted。 *)

(* ---------- 73.3 解法一（治标）：调大 maxDiscard ---------- *)

(* QuickChick 2.2 的运行参数记录（src/Test.v）：
     Record Args := MkArgs {
       replay     : option (RandomSeed * nat);
       maxSuccess : nat;   (* 目标通过数，默认 defNumTests    = 10000 *)
       maxDiscard : nat;   (* 丢弃配额，  默认 defNumDiscards = 2 * defNumTests *)
       maxShrinks : nat;   (* 收缩步数上限，默认 defNumShrinks = 1000 *)
       maxSize    : nat;   (* 生成尺寸上限，默认 defSize       = 7 *)
       chatty     : bool;
       analysis   : bool
     }.
   丢弃数超过 maxDiscard 就宣布 Gave up。库只提供 updMaxSize / updMaxSuccess /
   updAnalysis 三个更新函数，没有 updMaxDiscard——只能手工构造整个记录。
   坑：Coq 的 nat 字面量是一元的，别直接写 100000；写成 defNumDiscards 的
   倍数，抽取到 OCaml 后才是普通算术。 *)

Definition argsBigDiscard : Args :=
  MkArgs None defNumTests (defNumDiscards * 20) defNumShrinks defSize true doAnalysis.

(* 配套的 vernac 命令是 QuickChickWith（先参数、后性质）：
     QuickChickWith argsBigDiscard 某个性质.
   test_insert_spec 在默认配额下就能通过，这里用不上它；
   真正需要它的是 73.6 修复后的 BST 性质。 *)

(* ---------- 73.4 解法二（治本）：按规格生成 genSortedList ---------- *)

Fixpoint genSortedList (low high : nat) (size : nat)
             : G (list nat) :=
  match size with
  | O => ret []
  | S size' =>
    if high <? low then
      ret []
    else
      freq [ (1, ret []) ;
             (size, x <- choose (low, high);;
                    xs <- genSortedList x high size';;
                    ret (x :: xs)) ] end.

Sample (genSortedList 0 10 10).

(* 一次实测输出（20 个样本，每次不同；注意每个列表都 sorted）——形如：
     [ []; [0; 1; 4; 5; 7; 8; 9]; [3; 4]; [2]; ... ] *)

Definition insert_spec_sorted (x : nat) :=
  forAllShrink
    (genSortedList 0 10 10)
    shrink
    (fun l => insert_spec' x l).

QuickChick insert_spec_sorted.

(* 一次实测输出（数字随机，形态稳定）：
     QuickChecking insert_spec_sorted
     947 : 0
     946 : 4
     946 : 10
     938 : 6
     922 : 9
     916 : 2
     900 : 7
     899 : 3
     885 : 8
     854 : 5
     847 : 1
     +++ Passed 10000 tests (0 discards)
   含义：长度 0..10 各占约 900（分布均匀），且一次丢弃都没有。 *)

(* ---------- 73.5 生成器层面的过滤：suchThatMaybe ---------- *)

(* suchThatMaybe : G A -> (A -> bool) -> G (option A)（src/Generators.v）
   在生成器内部做过滤：反复重试（重试次数随当前 size 增长），仍采不到
   满足条件的值就返回 None。对照：==> 在检查器层面丢弃整个测试用例。 *)

Definition genSortedListNaive : G (option (list nat)) :=
  suchThatMaybe (listOf (choose (0,10))) sorted.

Sample genSortedListNaive.

(* 一次实测输出形如：
     [Some []; None; None; Some [1; 4; 9]; None; Some [0; 0]; ... ]
   None 占多数——「朴素生成 + 事后过滤」与 ==> 是同一场 discard 风暴，
   只是风暴从检查器搬进了生成器内部。 *)

(* ---------- 73.6 BST：前提三连、bug 现形、收缩、修复、再卡住 ---------- *)

(* 二叉树机器（与 28 章同一个数据结构；显示/生成/收缩实例搬自原书前文，
   QuickChick insertBST_spec 依赖它们自动供出随机树与收缩）。 *)

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

Fixpoint genTreeSized' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
    | O => ret Leaf
    | S sz' =>
        freq [ (1,  ret Leaf) ;
               (sz, liftM3 Node g (genTreeSized' sz' g)
                                  (genTreeSized' sz' g))
             ]
  end.

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.

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

Fixpoint isBST (low high: nat) (t : Tree nat) :=
  match t with
  | Leaf => true
  | Node x l r => (low <? x) && (x <? high)
                  && (isBST low x l) && (isBST x high r)
  end.

Fixpoint insertBST (x : nat) (t : Tree nat) :=
  match t with
  | Leaf => Node x Leaf Leaf
  | Node x' l r => if x <? x' then Node x' (insertBST x l) r
                   else Node x' l (insertBST x r)
  end.

Definition insertBST_spec (low high : nat) (x : nat) (t : Tree nat) :=
  (low <? x) ==>
  (x <? high) ==>
  (isBST low high t) ==>
  isBST low high (insertBST x t).

QuickChick insertBST_spec.

(* 一次实测输出（随机，反例每次可能不同）：
     QuickChecking insertBST_spec
     0
     5
     4
     Node (4) (Leaf) (Leaf)
     *** Failed after 85 tests and 1 shrinks. (1274 discards)
   含义：low=0, high=5, x=4, t=Node 4 Leaf Leaf——85 次有效测试抓到 bug，
   1 步收缩即得最小反例；途中 1274 个用例因前提不满足被丢弃。 *)

Fixpoint insertBST' (x : nat) (t : Tree nat) :=
  match t with
  | Leaf => Node x Leaf Leaf
  | Node x' l r => if x <? x' then Node x' (insertBST' x l) r
                   else if x' <? x then Node x' l (insertBST' x r)
                   else t
  end.

Definition insertBST_spec' (low high : nat) (x : nat) (t : Tree nat) :=
  (low <? x) ==> (x <? high) ==> (isBST low high t) ==>
  isBST low high (insertBST' x t).

QuickChick insertBST_spec'.

(* 一次实测输出（数字随机）：
     QuickChecking insertBST_spec'
     *** Gave up! Passed only 1281 tests
     Discarded: 20000
   含义：修复后性质应当为真，但随机树几乎都不是 BST——20000 次丢弃配额
   耗尽时只攒到 1281 次有效测试，QuickChick 只能宣布放弃。
   注意：Gave up 不是「性质为假」，是「前提太稀疏，测不动」。 *)

QuickChickWith argsBigDiscard insertBST_spec'.

(* 一次实测输出（数字随机；本章最贵的一条命令，约数秒）——形如：
     QuickChecking insertBST_spec'
     +++ Passed 10000 tests (约 16 万 discards)
   含义：丢弃配额放大 20 倍后终于攒够 10000 次有效测试——性质通过，
   但约 94% 的生成 effort 被白白扔掉。这就是「治标」。 *)

(* ---------- 73.7 练习 uniform_sorted（5 星，optional）：数字分布均匀吗 ---------- *)

(* 题目：用 collect 考察 genSortedList 0 5 生成的列表里各个数字出现的频率
   是否均匀；若不均匀，解释原因，并写一个更均匀的生成器（保持长度均匀）。
   第一步，统计：数一下每个列表里最小数字 0 与最大数字 5 各出现几次。 *)

Definition countElem (x : nat) (l : list nat) : nat :=
  List.length (filter (fun y => x =? y) l).

Definition dist_genSortedList :=
  forAll (genSortedList 0 5 5) (fun l =>
    collect (countElem 0 l, countElem 5 l) true).

QuickChick dist_genSortedList.

(* 一次实测输出（数字随机，形态稳定）——形如：
     4334 : (0, 0)
     1262 : (0, 1)
     1070 : (0, 2)
     971 : (0, 3)
     732 : (1, 0)
     621 : (0, 4)
     ...
     +++ Passed 10000 tests
   第二分量（5 的个数）常为 1、2、3、4，第一分量（0 的个数）几乎恒为 0：
   数字分布严重偏向大值。
   原因：递归调用 genSortedList x high size' 把下界从 low 抬成刚生成的 x——
   下界单调上升。0 只有在下界还是 0 时才有机会，一旦抽中任何非 0 数字
   它就永远出局；而 5 永远可达，且下界越抬、区间越小，抽中 5 的概率
   越大（每抽命中率为 1/(区间长度)）。 *)

(* 第二步，更均匀的生成器：先均匀挑长度 k，再让 k 个位置各自独立均匀地
   挑数字，最后用本章的 insert 做插入排序排成有序列表。插入排序的保序性
   正是 23 章证过的 insert_sorted 定理（那里是 Prop 版 sorted）的归纳推广。 *)

Fixpoint sortByInsert (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => insert x (sortByInsert xs)
  end.

Definition genSortedListUniform (low high size : nat) : G (list nat) :=
  k <- choose (0, size);;
  l <- vectorOf k (choose (low, high));;
  ret (sortByInsert l).

Definition dist_genSortedListUniform :=
  forAll (genSortedListUniform 0 5 5) (fun l =>
    collect (countElem 0 l, countElem 5 l) true).

QuickChick dist_genSortedListUniform.

(* 一次实测输出（数字随机，形态稳定）——形如：
     4567 : (0, 0)
     1621 : (1, 0)
     1558 : (0, 1)
     832 : (1, 1)
     418 : (2, 0)
     401 : (0, 2)
     ...
     +++ Passed 10000 tests
   两个分量的分布肉眼对称：0 和 5 的出现频率相当，均匀性达成；
   且长度 k 均匀取自 0..size，满足题目「保持长度均匀」的要求。 *)

Sample (genSortedListUniform 0 10 10).

(* 一次实测输出形如：
     [ []; [0; 2; 2; 6; 9]; [1; 3; 5; 5; 7; 8; 10]; ... ] *)

Definition insert_spec_sorted_uniform (x : nat) :=
  forAllShrink
    (genSortedListUniform 0 10 10)
    shrink
    (fun l => insert_spec x l).

QuickChick insert_spec_sorted_uniform.

(* 一次实测输出形如：
     QuickChecking insert_spec_sorted_uniform
     +++ Passed 10000 tests (0 discards) *)

(* ---------- 73.8 练习 gen_bst（4 星）：直接生成 BST ---------- *)

(* 题目：写一个直接生成 BST 的生成器，让修复后的插入性质跑出
   10000 tests / 0 discards。
   思路与 genSortedList 同构：把上下界沿递归传递——根 x 必须落在开区间
   (low, high) 内，左子树在 (low, x) 里递归，右子树在 (x, high) 里递归。 *)

Fixpoint genBST (low high : nat) (size : nat) : G (Tree nat) :=
  match size with
  | O => ret Leaf
  | S size' =>
    if high <=? low + 1 then
      ret Leaf
    else
      freq [ (1, ret Leaf) ;
             (size, x <- choose (low + 1, high - 1);;
                    l <- genBST low x size';;
                    r <- genBST x high size';;
                    ret (Node x l r)) ]
  end.

(* 边界检查：开区间 (low, high) 非空 当且仅当 low + 1 <= high - 1，
   即 ~(high <= low + 1)——恰好是上面 if 的条件。此时 choose (low + 1,
   high - 1) 两端点合法，nat 减法 high - 1 也不会截断（high >= low + 2）。 *)

Sample (genBST 0 10 10).

(* 一次实测输出形如：
     [Node (5) (Node (2) (Leaf) (Leaf)) (Node (8) (Leaf) (Leaf)); Leaf; ... ]
   ——全是满足 isBST 0 10 的树。 *)

(* 三个前提（low < x、x < high、isBST low high t）全部改由生成器保证：
   x 直接挑自 (0, 10) 的开区间即 1..9，t 直接生成成 BST——性质体里
   一个 ==> 都不用写。 *)

Definition insertBST_spec_gen :=
  forAll (choose (1,9)) (fun x =>
  forAllShrink (genBST 0 10 10) shrink (fun t =>
    isBST 0 10 (insertBST' x t))).

QuickChick insertBST_spec_gen.

(* 一次实测输出形如：
     QuickChecking insertBST_spec_gen
     +++ Passed 10000 tests (0 discards) *)

End Ex73Conditional.
