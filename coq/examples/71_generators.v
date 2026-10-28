(* 71 随机生成器：G 单子与按尺寸生成 —— G 类型直觉、returnGen/bindGen 与单子记号、choose、
   listOf/vectorOf、elems/oneOf/freq、backtrack、sized/resize、GenSized/Gen 类型类 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick. Import QcDefaultNotation.
From Stdlib Require Import List ZArith String. Import ListNotations.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Open Scope qc_scope. Open Scope monad_scope.

Module Ex71Generators.

Local Open Scope string.

(* ---------- 71.1 G 类型：尺寸参数与随机种子 ---------- *)

Module DefineG.

Inductive G (A:Type) : Type :=
| MkG : (nat -> RandomSeed -> A) -> G A.
Arguments MkG {A}.

End DefineG.

(* 真实的 G A 就是库里的 GenType A：一个 nat -> RandomSeed -> A 的函数。
   nat 是「当前尺寸上限」，RandomSeed 是伪随机序列的起点；
   Sample 用 0 到 10 递增的尺寸配上新种子各跑一遍。 *)

(* ---------- 71.2 Monad 接口：returnGen 与 bindGen ---------- *)

Check returnGen.
(* ===> returnGen : ?A -> G ?A *)

Sample (returnGen 42).
(* 形如 [42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42] —— 常生成器无视尺寸与种子 *)

Check bindGen.
(* ===> bindGen : G ?A -> (?A -> G ?B) -> G ?B
   实现要点：先用 randomSplit 把种子劈成两个，两段生成各拿一个。 *)

Section GMonadDef.

Instance GMonad : `{Monad G} | 3 :=
  {
    ret := @returnGen;
    bind := @bindGen
  }.

End GMonadDef.

(* ---------- 71.3 choose：从区间中随机选择 ---------- *)

Check @choose.
(* ===> @choose : forall A : Type, ChoosableFromInterval A -> A * A -> G A
   （省去了 Producer 与序关系 le 两个隐式参数；nat 用 ChooseNat、Z 用 ChooseZ 实例） *)

Sample (choose (0,10)).
(* 形如 [1, 2, 1, 9, 8, 10, 3, 6, 0, 1, 8] —— 两端点都含在内 *)

Sample (choose (-5, 5)%Z).
(* ChooseZ 实例：形如 [-3, 5, 0, -1, 4, 2, -5, ...] *)

(* 练习 cfi（1 星）：打印 ChoosableFromInterval 并读懂它 *)

Print ChoosableFromInterval.
(* 2.2 中该类对类型 A 与序 le 有四个字段：
     randomR        : A * A -> RandomSeed -> A * RandomSeed   区间随机函数
     randomRCorrect : 区间内每个元素都能被 randomR 取到（完备性证明义务）
     enumR          : A * A -> LazyList A                     枚举版（供列举器复用）
     enumRCorrect   : enumR 恰好列出区间内全部元素 *)

(* ---------- 71.4 单子记号：把两段随机性串起来 ---------- *)

Definition genPairNat : G (nat * nat) :=
  bindGen (choose (0, 3)) (fun x =>
  bindGen (choose (0, 3)) (fun y =>
  returnGen (x, y))).

Definition genPairNat' : G (nat * nat) :=
  x <- choose (0, 3);;
  y <- choose (0, 3);;
  ret (x, y).

Sample genPairNat'.
(* 形如 [(1, 2), (0, 0), (3, 1), ...] —— 与 genPairNat 同分布 *)

(* ---------- 71.5 列表生成器：listOf 与 vectorOf ---------- *)

Check listOf.
(* ===> listOf : G ?A -> G (list ?A) *)

Sample (listOf (choose (0,4))).
(* 形如 [[0, 3, 2, 0], [1, 3, 4, 1, 0], [], [4, 2, 3], ...] —— 长度随机、受尺寸约束 *)

Check vectorOf.
(* ===> vectorOf : nat -> G ?A -> G (list ?A) *)

Sample (vectorOf 3 (choose (0,4))).
(* 形如 [[0, 1, 4], [1, 1, 0], [3, 3, 3], ...] —— 长度恒为 3 *)

(* ---------- 71.6 自定义类型：elems / oneOf / freq ---------- *)

Inductive color := Red | Green | Blue | Yellow.

#[export] Instance show_color : Show color :=
  {| show c :=
       match c with
         | Red    => "Red"
         | Green  => "Green"
         | Blue   => "Blue"
         | Yellow => "Yellow"
       end
  |}.

Check elems_.
(* ===> elems_ : ?A -> list ?A -> G ?A
   第一个参数是默认值：列表为空时用它兜底，保证函数的完全性。 *)

Definition genColor' : G color :=
  elems_ Red [ Red ; Green ; Blue ; Yellow ].

Sample genColor'.
(* 形如 [Red, Green, Blue, Blue, Red, Yellow, Blue, ...] *)

(* QcDefaultNotation 模块把默认值藏进记号（表头元素兼任默认值）：
     " 'elems' [ x ] "              := elems_ x (cons x nil)
     " 'elems' [ x ; y ; .. ; z ] " := elems_ x (cons x (cons y .. (cons z nil) ..))
   oneOf / freq 记号同理。 *)

Definition genColor : G color :=
  elems [ Red ; Green ; Blue ; Yellow ].

Sample genColor.

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

Check oneOf_.
(* ===> oneOf_ : G ?A -> list (G ?A) -> G ?A
   从生成器列表中均匀挑一个；列表为空时退回默认生成器。 *)

(* 「显然」的递归生成器会被终止性检查拦下：

     Fixpoint genTree {A} (g : G A) : G (Tree A) :=
        oneOf [ ret Leaf ;;
                liftM3 Node g (genTree g) (genTree g) ].

   即使放行也是错的：每选一次 Node 都分裂出两棵待终止的子树，
   可以证明生成树的期望尺寸是无穷的。 *)

Fixpoint genTreeSized {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
    | O => ret Leaf
    | S sz' =>
        oneOf [
          ret Leaf ;
          liftM3 Node g (genTreeSized sz' g) (genTreeSized sz' g)
        ]
  end.

Sample (genTreeSized 3 (choose(0,3))).
(* 形如 [Leaf, Leaf, Node (3) (Node (0) (Leaf) (Leaf)) (...), Leaf, ...]
   —— 每层一半概率立即 Leaf，树普遍偏小 *)

Check freq_.
(* ===> freq_ : G ?A -> list (nat * G ?A) -> G ?A
   每个生成器带一个 nat 权重，按权重比例选择。 *)

Fixpoint genTreeSized' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
    | O => ret Leaf
    | S sz' =>
        freq [ (1,  ret Leaf) ;
               (sz, liftM3 Node g (genTreeSized' sz' g)
                                  (genTreeSized' sz' g))
             ]
  end.

Sample (genTreeSized' 3 (choose(0,3))).
(* Leaf 概率降为 1/(sz+1)：形如 [Node (...) (...) (...), Leaf, Node (...), ...] *)

(* ---------- 71.7 backtrack：可失败的生成器与重试 ---------- *)

Definition genSmallMaybe : G (option nat) :=
  n <- choose (0, 10) ;;
  ret (if n <? 3 then Some n else None).

Definition genSmallOr42 : G (option nat) :=
  backtrack [ (3, genSmallMaybe) ; (1, ret (Some 42)) ].

Sample genSmallOr42.
(* 形如 [Some 42, Some 1, Some 42, Some 0, Some 42, ...]
   —— 约两成落在 Some 0/1/2，失败则按权重换下一个，最后兜底 42 *)

(* ---------- 71.8 sized 与 resize：读取与改写尺寸参数 ---------- *)

Module DefineSized.
Import DefineG.

Definition sized {A : Type} (f : nat -> G A) : G A :=
  MkG
      (fun n r =>
         match f n with
           MkG g => g n r
         end).

End DefineSized.

Definition genTreeAuto : G (Tree nat) :=
  sized (fun n => genTreeSized' n (choose (0,3))).

Sample genTreeAuto.
(* 尺寸由 0 渐增：样本从 Leaf 起步，逐渐出现多层 Node *)

Check @resize.
(* ===> resize : nat -> G ?A -> G ?A —— 无视当前尺寸，强行钉成指定值 *)

Sample (resize 1 (listOf (choose (0,9)))).
(* 尺寸钉死为 1：形如 [[7], [], [2], [], [4], ...]，列表长度至多 1 *)

(* ---------- 71.9 GenSized 与 Gen 类型类 ---------- *)

Module DefineGen.

Class Gen (A : Type) :=
  {
    arbitrary : G A
  }.

End DefineGen.

Module DefineGenSized.

Class GenSized (A : Type) :=
  {
    arbitrarySized : nat -> G A
  }.

#[export] Instance GenOfGenSized {A} `{GenSized A} : Gen A :=
  {
    arbitrary := sized arbitrarySized
  }.

End DefineGenSized.

#[export] Instance gen_color : Gen color :=
  {
    arbitrary := genColor
  }.

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.

Sample (arbitrary : G color).

Sample (arbitrary : G (Tree nat)).
(* Gen (Tree nat) 由桥接实例 GenOfGenSized 从 genTree 自动合成 *)

(* ---------- 71.10 练习解答 ---------- *)

(* 练习 genListSized（2 星）：仿 genTreeSized' 写按尺寸的列表生成器。
   命名为 genListSized' 以避免与库自带的 genListSized 实例重名。 *)

Fixpoint genListSized' {A} (sz : nat) (g : G A) : G (list A) :=
  match sz with
    | O => ret []
    | S sz' =>
        freq [ (1, ret []) ;
               (sz, liftM2 cons g (genListSized' sz' g))
             ]
  end.

Sample (genListSized' 3 (choose (0,3))).
(* 形如 [[2, 0], [], [3, 1, 2], [], [1], ...] *)

(* 练习 genColorOption（3 星）：None 约占 1/10，Some Red 是其余颜色各自的 3 倍。
   权重和取 20：None 占 2（1/10）；Some 共 18，其中 Red 9、其余三色各 3。 *)

Definition genColorOption : G (option color) :=
  freq [ (2,  ret None) ;
         (9,  ret (Some Red)) ;
         (3,  ret (Some Green)) ;
         (3,  ret (Some Blue)) ;
         (3,  ret (Some Yellow)) ].

Sample genColorOption.
(* 形如 [Some Red, None, Some Red, Some Blue, Some Red, Some Red, ...] *)

End Ex71Generators.
