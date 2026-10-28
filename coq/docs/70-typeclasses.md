# 70 · 类型类机制

对应示例：`../examples/70_typeclasses.v`（`Module Ex70Typeclasses`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

第 69 章调用 `QuickChick` 时，`arbitrary`、`show`、`shrink` 等操作会随输入类型自动换实现：自然数有自然数的生成与打印方式，列表又能由元素的实例组装出自己的实例。本章拆开这套机制。核心只有一句话：**类型类是带自动证据搜索的记录接口**。`Class` 描述某类类型应当提供什么，`Instance` 给出一份具体实现，类型检查器根据目标类型在 hint 数据库里找出或递归组装这份实现。

这里的「类」不是面向对象语言里的类，也没有方法分派到对象这一层。更接近的图景是：把打印函数、相等测试、可判定性证明等装进记录，再把记录参数标记为隐式，让 Rocq 自动填写。自动填写很方便，也把普通的类型错误变成了搜索失败、搜索选错甚至搜索发散，所以本章前半讲接口，后半特别重视内部机制与调试。

### 70.0 文件头：导入、作用域与模块边界

```coq
(* 70 类型类机制 —— Class/Instance、`{...} 隐式推广、实例搜索与 hint 库、优先级与 defaulting、Monad、QuickChick 的类 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".
(* 适配：导入 ssreflect 后 rewrite 被接管为 ssr 版，rocq 9.3 会对它
   报 rewrite-rw 弃用警告（建议改名 rw）；本章证明沿用原书的标准
   rewrite 用法，屏蔽该警告保持输出干净。 *)
Set Warnings "-rewrite-rw".

From Stdlib Require Import Bool.
From Stdlib Require Import Strings.String.
From Stdlib Require Import Arith.
From Stdlib Require Import Lia.
From Stdlib Require Import List. Import ListNotations.
From Stdlib Require Import Relations.Relation_Definitions.
Require Import ssreflect ssrbool.
Require Export ExtLib.Structures.Monads.

Module Ex70Typeclasses.

Local Open Scope string.
```

- 第一行注释就是本章地图；两个 `Set Warnings` 分别屏蔽抽取、记号覆盖和解析告警。它们不改变项或证明的含义。
- `ssreflect` 会接管 `rewrite`，而本章沿用标准写法；第三个告警设置只让输出保持干净。真正需要记住的是：**导入库可能改变 tactic 与记号的解析**，不能只看表面代码猜行为。
- `Bool`、`Strings.String`、`Arith`、`Lia` 分别提供布尔运算、字符串、自然数运算和后面的线性算术证明。`List` 与 `ListNotations` 提供列表及 `[1; 2]` 记号；`Relation_Definitions` 提供 70.11 节的 `relation`。
- `ssreflect ssrbool` 提供 70.12 节使用的 `decidable`。它也会全局开启隐式参数，因此该节要额外修正 `dec` 的 `Arguments`。
- `Require Export ExtLib.Structures.Monads` 不仅导入 `Monad`，还把接口再导出给导入本模块的文件。69 章已经见过库 facade 的便利；71 章的 `G` 单子会继续使用这里的 `ret`、`bind` 与 `<- ... ;;` 记号。
- `Module Ex70Typeclasses` 给本章所有教学定义加命名空间，避免与后续章节的同名 `Show`、`Eq` 冲突；`Local Open Scope string` 只在当前模块内让 `++` 默认按字符串拼接解释。

**坑：** 本章故意不导入 QuickChick 本体，因为库也定义同名的 `Show`、`Dec` 和若干实例。70.17 节会解释如何阅读库中的对应接口；69、71–76 章则统一使用 QuickChick 自带版本。

### 70.1 Class 与 Instance：以 Show 为例

手写 `showBool`、`showNat`、`showList showNat` 当然可行，但每多一层结构都要手工传转换器。`Show` 把「类型 `A` 能被打印」抽象成一个接口，调用处只写 `show`，由类型决定选哪份实现。

```coq
(* ---------- 70.1 Class 与 Instance：以 Show 为例 ---------- *)

Class Show A : Type :=
  {
    show : A -> string
  }.

#[export] Instance showBool : Show bool :=
  {
    show := fun b:bool => if b then "true" else "false"
  }.

Compute (show true).

Inductive primary := Red | Green | Blue.

#[export] Instance showPrimary : Show primary :=
  {
    show :=
      fun c:primary =>
        match c with
        | Red => "Red"
        | Green => "Green"
        | Blue => "Blue"
        end
  }.

Compute (show Green).

Fixpoint string_of_nat_aux (time n : nat) (acc : string) : string :=
  let d := match n mod 10 with
           | 0 => "0" | 1 => "1" | 2 => "2" | 3 => "3" | 4 => "4" | 5 => "5"
           | 6 => "6" | 7 => "7" | 8 => "8" | _ => "9"
           end in
  let acc' := d ++ acc in
  match time with
    | 0 => acc'
    | S time' =>
      match n / 10 with
        | 0 => acc'
        | n' => string_of_nat_aux time' n' acc'
      end
  end.

Definition string_of_nat (n : nat) : string :=
  string_of_nat_aux n n "".

#[export] Instance showNat : Show nat :=
  {
    show := string_of_nat
  }.

Compute (show 42).

(* 练习 showNatBool：为「nat 与 bool 的序对」写 Show 实例 *)
#[export] Instance showNatBool : Show (nat * bool) :=
  {
    show p :=
      let (n, b) := p in
        "(" ++ show n ++ ", " ++ show b ++ ")"
  }.

Compute (show (42, true)).
```

逐层读这段定义：

1. `Class Show A : Type` 声明一个以类型 `A` 为参数的类。花括号内目前只有一个成员 `show : A -> string`，所以「有 `Show A` 证据」在操作层面就是「有一个 `A -> string` 函数」。70.8 节会看到它确实被展开成记录。
2. `Instance showBool : Show bool` 构造这份记录：`show` 字段收到一个布尔分支函数。`#[export]` 让模块被导入时该实例也进入可见的实例库；它不是可选的装饰，库设计时直接关系到别人能否自动解析到它。
3. `Compute (show true)` 没有写 `showBool`。参数 `true` 先把 `show` 的类型参数统一为 `bool`，随后实例搜索填入 `showBool`，结果是字符串 `"true"`。
4. `primary` 是新建的三构造子类型。`showPrimary` 用穷尽 `match` 给出三种打印；这强调实例并不限于标准库类型，用户类型一样能加入接口。
5. 自然数打印稍微复杂。`string_of_nat_aux` 先取 `n mod 10`，把余数映射为数字字符，再用 `d ++ acc` 把当前最低位放到已累计字符串的**左边**。随后检查商 `n / 10`：商为零就结束，否则带着 `time'`、商和新累积串递归。
6. `time` 是结构性递归需要的燃料参数，与数学上的十进制位数无关。`string_of_nat` 用 `n` 同时当初始值和燃料，对十进制转换足够；`showNat` 只负责把这个已定义函数装进接口。
7. 练习 `showNatBool` 的关键不是字符串格式，而是**复用重载操作**：解构 `(n, b)` 后，两个 `show` 分别解析为 `showNat` 和 `showBool`，无需手工传函数。序对实例里嵌套调用实例，正是下一节泛型组合的前奏。

**坑：** `show` 只是名称相同的重载入口，不意味着不同实例共享同样的格式或性质。另一个常见坑是把实例写成普通 `Definition`：项本身仍可能存在，但不会自动注册进搜索库。70.9 与 70.15 节分别讲注册和撤销注册。

### 70.2 类约束 `{Show A}`：泛型函数

只有具体类型上的实例还不够。泛型函数的参数类型是变量 `A`，必须明确声明「调用者会提供 `Show A`」，函数体里的 `show a` 才有证据可用。

```coq
(* ---------- 70.2 类约束 `{Show A}：泛型函数 ---------- *)

Definition showOne {A : Type} `{Show A} (a : A) : string :=
  "The value is " ++ show a.

Compute (showOne true).
Compute (showOne 42).

Definition showTwo {A B : Type}
           `{Show A} `{Show B} (a : A) (b : B) : string :=
  "First is " ++ show a ++ " and second is " ++ show b.

Compute (showTwo true 42).
Compute (showTwo Red Green).

(* 练习 missingConstraint：把 showOne 的 `{Show A} 约束删掉会怎样？
   答：定义当场报错——没有了约束，上下文里就没有 A 的 show 证据，
   实例搜索对抽象类型变量 A 无能为力： *)
Fail Definition showOneBroken {A : Type} (a : A) : string :=
  "The value is " ++ show a.
(* 实测报错（rocq 9.3）：
     Error:
     The following term contains unresolved implicit arguments:
       (fun (A : Type) (a : A) => "The value is " ++ show a)
     More precisely:
     - ?Show: Cannot infer the implicit parameter Show of show whose
       type is "Show A" (no type class instance found) in environment:
       A : Type
       a : A *)
```

`{A : Type}` 是普通隐式类型参数；`` `{Show A} `` 是**带隐式推广的类约束**。可以把 `showOne` 读成：对任意类型 `A`，再给一份 `Show A` 记录和一个 `a : A`，返回字符串。调用 `showOne true` 时，`A` 被确定为 `bool`，实例搜索补 `showBool`；调用 `showOne 42` 时补 `showNat`。

`showTwo` 有两个独立类型参数和两份记录。函数体第一次 `show a` 使用 `Show A`，第二次 `show b` 使用 `Show B`；即使将来 `A`、`B` 恰好实例化成同一类型，源语法上它们仍是两个约束。两次 `Compute` 分别演示异构组合 `(bool,nat)` 与 `(primary,primary)`。

练习 `missingConstraint` 的答案是定义期失败，而不是等到某次调用才失败。删掉约束后，环境只有 `A : Type` 和 `a : A`，目标却是 `Show A`。`A` 是抽象变量，不能统一成 `bool`、`nat` 或其他已有实例的头部，因此留下未解析隐式参数。`Fail` 告诉 Rocq「下一条命令必须失败」，使这个错误示例可以成为可编译教程的一部分；报错注释中的 `?Show` 就是待填的证据洞。

**坑：** 类约束不是对 `A` 做静态白名单检查，而是真的增加一个参数。也不要把 `{A : Type}` 的花括号与 `` `{Show A} `` 的反引号混为一谈：前者只控制隐式性，后者还触发 70.6 节的隐式推广。

### 70.3 Eq：可判定相等的类

命题相等 `x = y` 对任何类型都能书写，但「计算一个布尔值判断相等」并非任何类型都能做到。`Eq` 专门表示后一种能力，并为它定义统一记号。

```coq
(* ---------- 70.3 Eq：可判定相等的类 ---------- *)

Class Eq A :=
  {
    eqb: A -> A -> bool;
  }.

Notation "x =? y" := (eqb x y) (at level 70).

#[export] Instance eqBool : Eq bool :=
  {
    eqb := fun (b c : bool) =>
       match b, c with
         | true, true => true
         | true, false => false
         | false, true => false
         | false, false => true
       end
  }.

#[export] Instance eqNat : Eq nat :=
  {
    eqb := Nat.eqb
  }.

(* 练习 boolArrowBool：bool->bool 上只有两个输入，穷尽即可判定相等 *)
#[export] Instance eqBoolBool : Eq (bool -> bool) :=
  {
    eqb f g :=
      andb (f true =? g true) (f false =? g false)
  }.

Compute ((fun b : bool => b) =? (fun b : bool => b)).
Compute ((fun b : bool => b) =? negb).
```

`Eq A` 的唯一字段是二元布尔函数 `eqb`。`Notation` 把 `x =? y` 展开成 `eqb x y`，层级 70 与常见比较记号相容；在本模块中，这个入口现在指向类的投影，而不再专指自然数的 `Nat.eqb`。

`eqBool` 同时匹配两个布尔值，四种组合中同值返回 `true`；`eqNat` 直接复用标准库的 `Nat.eqb`。二者都说明实例字段可以是现成函数，也可以现场构造。

练习 `boolArrowBool` 利用了定义域只有 `true`、`false` 两个元素这一事实：两个函数若在两个输入上都相等，就在整个 `bool -> bool` 上外延相等。因此分别计算 `f true =? g true` 与 `f false =? g false`，用 `andb` 合取即可。最后两个 `Compute` 中，恒等函数与自身相等，与 `negb` 不等。

**坑：** 这个技巧不能推广到 `nat -> nat`：无穷定义域不能靠有限次采样判定函数相等。`Eq` 本身也只承诺「有个布尔函数」，尚未承诺该函数真的对应 `=`；70.10 节的 `EqDec` 会把正确性证明加入类中。

### 70.4 参数化实例：以旧实例造新实例

序对、列表、`option` 都不是单一具体类型，而是类型构造子。为它们写实例时，应当把元素类型的实例作为前提，让搜索器从旧证据递归构造新证据。

```coq
(* ---------- 70.4 参数化实例：以旧实例造新实例 ---------- *)

#[export] Instance showPair {A B : Type} `{Show A} `{Show B} : Show (A * B) :=
  {
    show p :=
      let (a,b) := p in
        "(" ++ show a ++ "," ++  show b ++ ")"
  }.

Compute (show (true,42)).

#[export] Instance eqPair {A B : Type} `{Eq A} `{Eq B} : Eq (A * B) :=
  {
    eqb p1 p2 :=
      let (p1a,p1b) := p1 in
      let (p2a,p2b) := p2 in
      andb (p1a =? p2a) (p1b =? p2b)
  }.

Fixpoint showListAux {A : Type} (s : A -> string) (l : list A) : string :=
  match l with
    | nil => ""
    | cons h nil => s h
    | cons h t => append (append (s h) ", ") (showListAux s t)
  end.

#[export] Instance showList {A : Type} `{Show A} : Show (list A) :=
  {
    show l := append "[" (append (showListAux show l) "]")
  }.

Compute (show [1; 2; 3]).

(* 练习 eqEx：list 的 Eq 实例、option 的 Show 与 Eq 实例 *)
Fixpoint eqListAux {A : Type} (eq : A -> A -> bool) (l1 l2 : list A) : bool :=
  match l1, l2 with
  | [], [] => true
  | h1 :: t1, h2 :: t2 => andb (eq h1 h2) (eqListAux eq t1 t2)
  | _, _ => false
  end.

#[export] Instance eqList {A : Type} `{Eq A} : Eq (list A) :=
  {
    eqb := eqListAux eqb
  }.

#[export] Instance showOpt {A : Type} `{Show A} : Show (option A) :=
  {
    show o :=
      match o with
      | Some x => "Some " ++ show x
      | None => "None"
      end
  }.

#[export] Instance eqOpt {A : Type} `{Eq A} : Eq (option A) :=
  {
    eqb o1 o2 :=
      match o1, o2 with
      | Some x, Some y => x =? y
      | None, None => true
      | _, _ => false
      end
  }.

Compute (show (Some (true, 42))).
Compute ([1; 2] =? [1; 2]).
Compute (Some 1 =? None).

(* 练习 boolArrowA：推广为 bool->A（A 自带 Eq），并对 bool->bool->nat 验证 *)
#[export] Instance eqBoolArrow {A : Type} `{Eq A} : Eq (bool -> A) :=
  {
    eqb f g :=
      andb (f true =? g true) (f false =? g false)
  }.

Definition f00 : bool -> bool -> nat := fun _ _ => 0.
Definition f01 : bool -> bool -> nat := fun _ b => if b then 1 else 0.

Compute (f00 =? f00).
Compute (f00 =? f01).
```

- `showPair` 的头部同时绑定 `A B`、要求 `Show A` 与 `Show B`，结论是 `Show (A * B)`。实例体解构一次，再分别调用两个分量的 `show`。求 `Show (bool * nat)` 时，搜索器由此生成 `Show bool`、`Show nat` 两个子目标。
- `eqPair` 同构：先拆两个序对，再逐分量比较并取合取。两个约束不能省，否则抽象分量上的 `=?` 没有证据。
- `showListAux` 把元素打印机 `s` 作为普通显式函数参数，便于写结构性递归。空表不打印内部内容，单元素表不附逗号，多元素分支在表头后加 `", "` 并递归。`showList` 将重载的 `show` 作为 `s` 传入，再补外侧方括号。
- 练习 `eqEx` 的列表解答也采用「辅助递归函数 + 一层实例包装」。`eqListAux` 同时按两列表匹配：都空为真；都非空则比较表头并递归；一空一非空落到通配分支为假。`eqList` 传入当前 `Eq A` 证据里的 `eqb`。
- `showOpt` 给 `Some x` 加前缀并递归打印 `x`，给 `None` 固定文本；`eqOpt` 只在构造子相同的时候可能为真，`Some` 分支继续用元素相等测试。三个 `Compute` 分别验证 `option` 与 `pair`、列表实例的递归组装，以及不等情形。
- 练习 `boolArrowA` 把 70.3 的特解中的结果类型推广成任意有 `Eq A` 的 `A`。对 `bool -> bool -> nat`，可把它读作 `bool -> (bool -> nat)`：外层由 `eqBoolArrow` 处理，内层结果类型仍是 `bool -> nat`，再次使用同一实例，最内层落到 `eqNat`。`f00` 与 `f01` 在第二个布尔输入上不同，所以两次计算分别为真、假。

**坑：** 参数化实例的约束是搜索的递归边，不是装饰。少写约束会在定义处失败；多注册语义不同的重叠实例则会让选择变复杂。这里的 `eqBoolBool` 与更一般的 `eqBoolArrow` 都能覆盖 `Eq (bool -> bool)`，是后面 defaulting 与优先级讨论的前兆。69 章的复合测试数据、71 章的复合生成器、74 章的自动派生，都依赖这种「按类型结构递归找实例」的模式。

### 70.5 类层次：Ord 以 Eq 为「超类」

有序类型既要比较大小，也往往要比较相等。若把两种操作重新塞进一个独立接口，就会得到两套互不相干的相等测试；更好的做法是让 `Ord` 依赖已有的 `Eq` 证据。

```coq
(* ---------- 70.5 类层次：Ord 以 Eq 为「超类」 ---------- *)

Class OrdBad A :=
  {
    eqbad : A -> A -> bool;
    lebad : A -> A -> bool
  }.

Definition lt {A: Type} `{Eq A} `{OrdBad A} (x y : A) : bool :=
  andb (lebad x y) (negb (eqbad x y)).

Class Ord A `{Eq A} : Type :=
  {
    le : A -> A -> bool
  }.

Notation "x <=? y" := (le x y) (at level 70).

Check Ord.
(* ==> Ord : forall A : Type, Eq A -> Type *)

#[export] Instance natOrd : Ord nat :=
  {
    le := Nat.leb
  }.

Definition max {A: Type} `{Eq A} `{Ord A} (x y : A) : A :=
  if le x y then y else x.

Compute (max 3 7).

(* 练习 missingConstraintAgain：max 删掉 `{Ord A} 会报错（le 没有证据）；
   删掉 `{Eq A} 却仍能编译——隐式推广会把 Ord 的超类参数 H : Eq A
   一并自动补绑出来，见 70.6 节 max1 的 Print 输出。 *)

(* 练习 ordMisc：option 与 pair 的 Ord 实例 *)
#[export] Instance ordOpt {A : Type} `{Ord A} : Ord (option A) :=
  {
    le o1 o2 :=
      match o1, o2 with
      | None, _ => true
      | Some _, None => false
      | Some x, Some y => le x y
      end
  }.

#[export] Instance ordPair {A B : Type} `{Ord A} `{Ord B} : Ord (A * B) :=
  {
    le p1 p2 :=
      let (a1, b1) := p1 in
      let (a2, b2) := p2 in
      if a1 =? a2 then le b1 b2 else le a1 a2
  }.

Compute (le (Some 3) None).
Compute (le (1, 2) (1, 3)).

(* 练习 ordList：list 的字典序 Ord 实例 *)
Fixpoint leList {A : Type} `{Ord A} (l1 l2 : list A) : bool :=
  match l1, l2 with
  | [], _ => true
  | _ :: _, [] => false
  | h1 :: t1, h2 :: t2 => if h1 =? h2 then leList t1 t2 else le h1 h2
  end.

#[export] Instance ordList {A : Type} `{Ord A} : Ord (list A) :=
  {
    le := leList
  }.

Compute (le [1; 2] [1; 3]).
Compute (le [1; 2] [1]).
```

`OrdBad` 是反例：它把 `eqbad`、`lebad` 并列放入新记录，导致已有 `Eq A` 与新接口脱节。`lt` 用 `lebad x y` 且否定 `eqbad x y` 来表示严格小于；头部却仍带着 `Eq A`，反而凸显重复约束与重复操作的问题。

`Class Ord A `{Eq A}` 把 `Eq A` 作为类的参数。于是 `Check Ord` 显示的不是简单 `Type -> Type`，而是 `forall A : Type, Eq A -> Type`：构造 `Ord A` 之前必须先有对应的相等证据。这里的「超类」只是接口依赖的简称，不涉及继承对象。

`natOrd` 只填 `le` 字段，`Eq nat` 参数由已有 `eqNat` 自动解决。`max` 按 `le x y` 选择 `y` 或 `x`；显式写出 `Eq A` 与 `Ord A` 两个约束，有助于初学时看清接口。练习 `missingConstraintAgain` 的不对称结果很重要：删 `Ord A` 后连 `le` 都无法解析；只删 `Eq A` 却仍可通过，因为 `Ord A` 自身需要 `Eq A`，隐式推广会把这个前置参数一并补上。

练习 `ordMisc` 采用两种常见顺序：

- `option` 把 `None` 当作最小值。因此 `None` 小于等于任何值，`Some _ <= None` 为假，两个 `Some` 则比较内部元素。
- 序对使用字典序。先比较 `a1 =? a2`：第一分量相等才比较第二分量，否则第一分量的 `le` 已决定结果。这里 `=?` 正是从 `Ord` 的 `Eq` 参数获得，解释了为什么层次设计优于 `OrdBad`。

练习 `ordList` 仍是字典序：空表最小；非空表不小于空表；表头相等时递归比较表尾，否则由表头决定。`ordList` 只是把带约束的递归函数包装为实例。最后两次计算分别显示「公共前缀后比较不同元素」与「短列表是长列表前缀」两条规则。

**坑：** `Ord` 只包含一个布尔函数，Rocq 不会自动证明自反性、反对称性或传递性，更不会检查它与 `eqb` 一致。需要这些定律时应像 70.10、70.11 节那样把证明字段或关系类纳入设计。另一个工程坑是同一类型出现多份不同的 `Eq` 证据：`Ord A` 依赖哪一份必须保持清晰。

### 70.6 隐式推广：`{...} 到底展开成什么

反引号不是 `Class` 专用语法，而是更一般的**隐式推广**机制。理解它如何自动插入绑定子，才能解释类约束为何能省略类型参数，也能避免少写反引号后的离奇错误。

```coq
(* ---------- 70.6 隐式推广：`{...} 到底展开成什么 ---------- *)

Generalizable Variables A.

Definition showOne1 `{Show A} (a : A) : string :=
  "The value is " ++ show a.

Print showOne1.
(* ==>（rocq 9.3 实测；隐式参数直接印在类型的花括号里）
    showOne1 =
    fun (A : Type) (H : Show A) (a : A) => "The value is " ++ show a
         : forall {A : Type}, Show A -> A -> string

    Arguments showOne1 {A}%_type_scope {H} a
*)

Definition showOne2 `{_ : Show A} (a : A) : string :=
  "The value is " ++ show a.

Definition showOne3 `{H : Show A} (a : A) : string :=
  "The value is " ++ show a.

Definition showOne4 `{Show} a : string :=
  "The value is " ++ show a.

Set Printing Implicit.
Print showOne.
Print showOne1.
Print showOne2.
Print showOne3.
Print showOne4.
(* ==> 五个定义的打印完全相同（rocq 9.3 实测）：
    showOne =
    fun (A : Type) (H : Show A) (a : A) => "The value is " ++ @show A H a
         : forall {A : Type}, Show A -> A -> string

    Arguments showOne {A}%_type_scope {H} a
*)
Unset Printing Implicit.

Definition max1 `{Ord A} (x y : A) :=
  if le x y then y else x.

Set Printing Implicit.
Print max1.
(* ==>（rocq 9.3 实测）注意第二个参数 H : Eq A 也是隐式推广
       自动补出来的：
     max1 =
     fun (A : Type) (H : Eq A) (H0 : @Ord A H) (x y : A) =>
     if x <=? y then y else x
          : forall {A : Type} {H : Eq A}, @Ord A H -> A -> A -> A

     Arguments max1 {A}%_type_scope {H H0} x y
*)

Check Ord.
(* ==> Ord : forall A : Type, Eq A -> Type *)

Unset Printing Implicit.

Generalizable Variables x y.

Lemma commutativity_property : `{x + y = y + x}.
Proof. intros. lia. Qed.

Check commutativity_property.
(* ==>（rocq 9.3 实测）未绑定的 x、y 显示为待推广的 evar：
     commutativity_property
          : ?x + ?y = ?y + ?x
     where
     ?x : [ |- nat]
     ?y : [ |- nat]
*)

Definition implicit_fun := `{x + y}.

Print implicit_fun.

(* 推广的参数是隐式且 maximally inserted 的，直接应用会报错： *)
(* Compute (implicit_fun 2 3). *)
(* ==>
    Error: Illegal application (Non-functional construction):
    The expression "implicit_fun" of type "nat"
    cannot be applied to the term
     "2" : "nat"
*)
Compute (@implicit_fun 2 3).

Definition implicit_fun1 := `(x + y).
Print implicit_fun1.
Compute (implicit_fun1 2 3).
```

先执行 `Generalizable Variables A`，才允许反引号绑定子中出现的自由 `A` 被自动推广。`showOne1` 省略了 70.2 节的 `{A : Type}`，但 `Print` 显示内部仍有 `A : Type` 与 `H : Show A` 两个参数。`Arguments` 行说明 `A`、`H` 是隐式且 maximally inserted：即使后面暂时没有显式参数，也会自动插入；写 `@showOne1` 可以关闭这种插入并手工给参。

接下来四种写法展示语法糖的不同层次：

- `showOne2` 用 `{_ : Show A}` 明确表示一份匿名证据；
- `showOne3` 把证据命名为 `H`，复杂定义中可借此显式引用或控制它；
- `showOne4` 连 `A` 和 `a` 的标注都省略，由 `Show`、`show a` 与结果类型共同推断；
- 打开 `Set Printing Implicit` 后，五种 `showOne` 定义的项与类型一致，区别只在表层写法。`@show A H a` 把平时藏起来的类型参数和记录参数暴露出来。检查后用 `Unset Printing Implicit` 恢复常用显示。

`max1` 是类层次中最有收益的例子。源码只写 `` `{Ord A} ``，打印结果却依次有 `A`、`H : Eq A`、`H0 : @Ord A H`。也就是说，推广不仅发现自由类型变量 `A`，还发现 `Ord A` 展开后需要的前置 `Eq A`。这正是上一道 `missingConstraintAgain` 练习的机制解释。

隐式推广也可完全不涉及类型类。`Generalizable Variables x y` 后，`commutativity_property` 可直接写加法交换律，`intros` 引入变量，`lia` 完成算术证明；注释中的 `?x`、`?y` 是显示层面的待推广 evar，61 章对 evar 与搜索有更系统的说明。`implicit_fun` 则推广出两个隐式且 maximally inserted 的函数参数，所以普通写法的 `implicit_fun` 已被视为应用完隐式参数后的自然数，直接再跟 `2 3` 会报「非函数构造」；`@implicit_fun 2 3` 才是显式应用。相对地，`` `(x + y) `` 使用圆括号，仍推广绑定子，但不把新绑定子设为隐式，因此 `implicit_fun1 2 3` 可直接计算。

**坑：** 不要为了少写声明而全局推广所有标识符；拼写错误也可能被吞成新参数。另一个坑是只看美化后的 `Print` 输出猜参数个数。调试时打开隐式参数、必要时用 `@`，比反复猜实例搜索更可靠。

### 70.7 记录即积：Record 语法糖

`Class` 的底层是记录，因此先单独熟悉 `Record`：构造子把各字段打包，投影把字段取出，记录语法只是让这两件事更易读写。

```coq
(* ---------- 70.7 记录即积：Record 语法糖 ---------- *)

Record Point :=
  Build_Point
    {
      px : nat;
      py : nat
    }.

Check (Build_Point 2 4).

Check {| px := 2; py := 4 |}.
Check {| py := 4; px := 2 |}.

Definition r : Point := {| px := 2; py := 4 |}.

Compute (r.(px) + r.(py)).

Record LabeledPoint (A : Type) :=
  Build_LabeledPoint
    {
      lx    : nat;
      ly    : nat;
      label : A
    }.

Check {| lx:=2; ly:=4; label:="hello" |}.
(* ==>
     {| lx := 2; ly := 4; label := "hello" |}
        : LabeledPoint string
*)

(* 练习 rcdParens：LabeledPoint 的参数 A 用圆括号（显式）而非花括号
   （隐式）绑定，为何更好？答：理论上 A 总能由 label 字段的值推出，
   隐式也能工作；但显式参数让「这个记录的元件类型是什么」成为语法
   上必须交代的事实——构造点、投影点、错误信息里都更可控。类型类
   场合则相反：实例参数正是为了「不写」而存在的，所以类约束一律
   用 `{...} 隐式推广。 *)
```

`Point` 声明等价于一个单构造子的积类型，`Build_Point` 依次接收 `px`、`py` 两个自然数。可以直接 `Build_Point 2 4`，也可以用 `{| ... |}` 按字段名构造；后一写法与字段书写顺序无关。`r.(px)`、`r.(py)` 是投影记号，分别取横纵坐标，因此计算结果为 `6`。

`LabeledPoint (A : Type)` 在记录层面参数化标签类型，三个字段中前两个仍为 `nat`，第三个为 `A`。示例中的字符串标签把 `A` 统一为 `string`，所以 `Check` 显示 `LabeledPoint string`。

练习 `rcdParens` 的重点是**显式性是一种接口选择**，不是能否推断的技术限制。这里的 `A` 确实能从 `label` 推出，隐式参数也能工作；但把 `A` 写成圆括号参数，让记录类型的实例化在语法上明确可见，构造、投影与错误信息更容易控制。类型类证据则相反：它的设计目标正是让常用调用省略样板参数，所以采用 `` `{...} ``。

**坑：** 不要把记录字段的 `:=` 与定义赋值、函数绑定混为一谈；`{| ... |}` 是构造记录值。字段投影也是全局常量，重名会增加解析与推断负担，所以这里 `Point` 与 `LabeledPoint` 使用不同字段名。

### 70.8 类型类即记录：脱下语法糖

现在把打印细节全部打开。`Class` 并没有引入一种神秘的对象系统；类、实例、重载操作分别对应记录类型、记录值与字段投影。

```coq
(* ---------- 70.8 类型类即记录：脱下语法糖 ---------- *)

Set Printing All.
Print Show.
(* ==>（rocq 9.3 实测）类就是一个单构造子记录：
    Record Show (A : Type) : Type := Build_Show { show : forall _ : A, string }.

    Arguments Show A%_type_scope
    Arguments Build_Show A%_type_scope show%_function_scope
    Arguments show {A}%_type_scope {Show} _
*)
Unset Printing All.

Print showNat.
(* ==>
    showNat = {| show := string_of_nat |}
       : Show nat
*)

Set Printing All.
Print show.
(* ==>（rocq 9.3 实测）投影就是对记录做一次 match：
    show =
    fun (A : Type) (Show : Show A) =>
    match Show return (forall _ : A, string) with
    | Build_Show _ show => show
    end
         : forall {A : Type} {_ : Show A} (_ : A), string

    show is a projection of Show
    Arguments show {A}%_type_scope {Show} _
*)
Unset Printing All.
```

`Print Show` 显示 `Build_Show` 构造子和唯一字段 `show`。最后一条 `Arguments` 最关键：投影 `show` 实际依次接收类型 `A`、记录 `Show A` 和值 `A`，前两个参数隐式。这解释了为什么源码只写 `show 42`，内部却需要解决两个额外参数。

`Print showNat` 显示实例就是 `{| show := string_of_nat |}`，类型为 `Show nat`。因此传递实例与传递普通记录没有本质差别；特殊之处只在实例被登记后，类型检查器会自动搜索它。

`Print show` 进一步显示投影的实现：接收一份名为 `Show` 的记录，对它做 `match`，在 `Build_Show _ show` 分支返回字段。所谓「重载函数」到这里就是一个普通的、依赖记录参数的函数。`Set Printing All` 与 `Unset Printing All` 只改变打印，不改变定义。

**坑：** 版本不同可能把单构造子记录显示为 `Record` 或 `Variant`，具体参数名也可能变化；应关注参数顺序和记录结构，不要死记美化输出。遇到「同一个 `show` 为什么在不同类型上行为不同」时，把它脑内展开成 `@show A instance a`，问题通常就清楚了。

### 70.9 实例推断：show 42 背后发生了什么

记录本身不会自动出现。真正的「特殊酱料」是：类型检查器遇到 `Show A` 证据洞时，会在 `typeclass_instances` hint 库里做定向搜索，必要时递归应用参数化实例。

```coq
(* ---------- 70.9 实例推断：show 42 背后发生了什么 ---------- *)

Definition eg42 := show 42.

Set Printing Implicit.
Print eg42.
Unset Printing Implicit.

(* 练习 HintDb：看看 typeclass_instances 这个 hint 库里有什么 *)
Print HintDb typeclass_instances.
(* 输出很长（本章导入了 ExtLib，库里还有 Monad 等类的实例）。
   搜 "For Show" 一节可以看到 showNat、showPair 等条目——
   每个 #[export] Instance 都往这个库里注册了一条 hint。 *)

Set Typeclasses Debug.
Check (show 42).
(* ==>（rocq 9.3 实测，省略 Calling ... flags 一行）
     Debug: 1: looking for (Show nat) without backtracking
     Debug: 1.1: exact showNat on (Show nat), 0 subgoal(s)
*)

Check (show (true,42)).
(* ==>（rocq 9.3 实测）递归组装：先试 showPair，再分别解决两个子目标
     Debug: 1: looking for (Show (bool * nat)) without backtracking
     Debug: 1.1: simple apply showPair on (Show (bool * nat)), 2 subgoal(s)
     Debug: 1.1-1 : (Show bool)
     Debug: 1.1-1: looking for (Show bool) without backtracking
     Debug: 1.1-1.1: exact showBool on (Show bool), 0 subgoal(s)
     Debug: 1.1-2 : (Show nat)
     Debug: 1.1-2: looking for (Show nat) without backtracking
     Debug: 1.1-2.1: exact showNat on (Show nat), 0 subgoal(s)      *)

Unset Typeclasses Debug.

(* 完整链条：
    show 42
       ===>   { 隐式参数 }
    @show _ _ 42
       ===>   { 类型检查 }
    @show (?A : Type) (?Show0 : Show ?A) 42
       ===>   { 统一 }
    @show nat (?Show0 : Show nat) 42
       ===>   { 对 Show nat 做证明搜索，命中 showNat }
    @show nat showNat 42
*)
```

`eg42` 固定了一个最小观察对象。打开隐式打印后可以看到，定义体中的证据已确定为 `showNat`，而不是每次计算字符串时才动态选择。这是** elaboration／类型检查期的搜索**，结果会保存在项里。

练习 `HintDb` 要求直接查看搜索使用的数据库。`Print HintDb typeclass_instances` 的输出按类分组；`showNat` 之类无前提实例可作为叶子，`showPair` 之类带约束实例则像可产生子目标的推理规则。导入的 ExtLib 也在同一库里注册了 Monad 相关实例，所以真实输出比本章源码长。

`Set Typeclasses Debug` 打开搜索轨迹。对 `Show nat`，日志显示直接 `exact showNat`，没有子目标。对 `Show (bool * nat)`，先 `simple apply showPair`，目标被拆为 `Show bool` 与 `Show nat`，二者再分别命中基础实例。这与 19、61 章的 hint/`eauto` 图景一致：按目标形状尝试规则、统一 evar、递归解决子目标，只是这里由类型类机制自动触发，并使用专用数据库。

末尾的完整链条把两种推断分开：先为隐式参数建立 `?A` 与 `?Show0`；参数 `42` 通过普通类型统一把 `?A` 钉为 `nat`；此时证据洞的类型变成 `Show nat`，实例搜索才给出 `showNat`。最后用 `Unset Typeclasses Debug` 关闭日志。

**坑：** 不要只凭最终报错判断缺的是哪条实例；先看 trace 中第一个偏离预期的步骤。还要区分「普通类型统一确定类型变量」和「实例搜索顺便统一类型变量」：后者可能把未定类型意外钉死，正是 70.14 节的 defaulting 陷阱。

### 70.10 带证明成员的类：EqDec

`Eq A` 只提供一个布尔函数，它甚至可能总是返回 `true`。若泛型证明需要依赖「布尔检查与命题相等一致」，就应把这条正确性证明作为类的字段。

```coq
(* ---------- 70.10 带证明成员的类：EqDec ---------- *)

Class EqDec (A : Type) {H : Eq A} :=
  {
    eqb_eq : forall x y, x =? y = true <-> x = y
  }.

#[export] Instance eqdecNat : EqDec nat :=
  {
    eqb_eq := Nat.eqb_eq
  }.

#[export] Instance eqdecBool' : EqDec bool.
Proof.
  constructor.
  intros x y. destruct x; destruct y; simpl; unfold iff; auto.
Defined.

Lemma eqb_fact `{EqDec A} : forall (x y z : A),
  x =? y = true -> y =? z = true -> x = z.
Proof.
  intros x y z Exy Eyz.
  rewrite eqb_eq in Exy.
  rewrite eqb_eq in Eyz.
  subst. reflexivity. Qed.
```

`EqDec (A : Type) {H : Eq A}` 以现有 `Eq A` 记录为参数，新增字段 `eqb_eq`。其类型是双向 iff：`eqb x y = true` 能推出 `x = y`，反向也成立。因此它不仅排除「恒真」的假实现，也保证相等时检查器不会漏报。

`eqdecNat` 直接复用标准库定理 `Nat.eqb_eq`。`eqdecBool'` 展示交互式构造实例：句点结尾的 `Instance` 进入证明模式；`constructor` 建立唯一记录构造子，留下字段目标；引入 `x y` 后分别 `destruct`，四种布尔组合经 `simpl` 化简，`unfold iff` 拆出双向命题，`auto` 全部收尾。`Defined` 保留证明体的透明性，适合可能需要计算或进一步依赖证明内容的实例。

`eqb_fact` 演示如何消费证明字段。`Exy`、`Eyz` 起初只是布尔等式；两次 `rewrite eqb_eq in ...` 将它们分别改成命题相等 `x = y` 与 `y = z`。`subst` 用等式替换变量，`reflexivity` 完成目标。这里的 `eqb_eq` 本身也是投影，泛型引理使用调用时传入的 `EqDec A` 证据。

**坑：** 不要把 `Eq` 与 `EqDec` 当成同义词：前者是操作，后者是操作加规格。若只需要计算，额外证明字段可能增加构造负担；若需要在证明中反射布尔结果，仅有 `Eq` 又不够。接口应按真实需求拆分，避免一个巨型类强迫所有实例证明用不到的性质。

### 70.11 子结构：类成员是另一个类

除了把 `Eq A` 作为 `Ord` 的参数，还可以让一份更大的记录包含其他类作为字段。数学结构常用这种方式组合自反性、传递性等独立接口。

```coq
(* ---------- 70.11 子结构：类成员是另一个类 ---------- *)

Class Reflexive (A : Type) (R : relation A) :=
  {
    reflexivity : forall x, R x x
  }.

Class Transitive (A : Type) (R : relation A) :=
  {
    transitivity : forall x y z, R x y -> R y z -> R x z
  }.

Generalizable Variables z w R.

Lemma trans3 : forall `{Transitive A R},
    `{R x y -> R y z -> R z w -> R x w}.
Proof.
  intros.
  apply (transitivity x z w). apply (transitivity x y z).
  assumption. assumption. assumption. Defined.

Class PreOrder (A : Type) (R : relation A) :=
  { PreOrder_Reflexive :: Reflexive A R ;
    PreOrder_Transitive :: Transitive A R }.

Lemma trans3_pre : forall `{PreOrder A R},
    `{R x y -> R y z -> R z w -> R x w}.
Proof. intros. eapply trans3; eassumption. Defined.
```

`relation A` 是 `A -> A -> Prop` 形态的关系。`Reflexive` 的字段给出任意 `x` 上的 `R x x`；`Transitive` 的字段给出三步关系拼接。它们都是只有证明成员的类，因此实例搜索在此是在搜索**证明项**，与搜索打印函数完全同构。

`Generalizable Variables z w R` 补充本段要推广的变量。`trans3` 的约束提供 `Transitive A R`，命题部分则说明三条边 `R x y`、`R y z`、`R z w` 可合成 `R x w`。证明先用 `transitivity x z w` 把目标拆成 `R x z` 与 `R z w`，再用 `transitivity x y z` 拆第一个目标；留下的 `R x y`、`R y z`、`R z w` 恰好由三个 `assumption` 解决。

`PreOrder` 把 `Reflexive A R` 与 `Transitive A R` 作为子结构字段。字段后的 `::` 是子结构／强制转换声明形式，使 `PreOrder` 的证据能经投影当作相应小接口的证据使用。于是 `trans3_pre` 不需要重证拼接：`eapply trans3` 留下 `Transitive A R` 等前提，`eassumption` 可利用上下文及其可解析的子结构证据完成。

**坑：** 「超类参数」与「子结构字段」是两种不同组织方式，不能只看都叫层次就互换。后者若从多条路径包含同一接口，还会产生证据是否一致的菱形问题；复杂数学库需要显式设计共享参数，避免两份看似相同却不同的记录。

### 70.12 Dec：可判定命题的类（ssreflect 风格）

属性测试和可执行程序经常要在命题世界与布尔世界之间往返。对可判定命题，可以统一包装 `{P} + {~P}` 证据，再用实例搜索自动沿逻辑连词和数据结构组装判定过程。

```coq
(* ---------- 70.12 Dec：可判定命题的类（ssreflect 风格） ---------- *)

Print decidable.
(* ==>
     decidable = fun P : Prop => {P} + {~ P}
          : Prop -> Set
*)

Class Dec (P : Prop) : Type :=
  {
    dec : decidable P
  }.

(* 适配说明：ssreflect 会全局开启 Set Implicit Arguments，把投影 dec
   的 Prop 参数也变成隐式，导致 dec (P a) 这类显式应用失败；
   下面这行恢复「P 显式、类实例参数隐式」的格局（QuickChick 同款）。 *)
Arguments dec _ {_}.

#[export] Instance EqDec__Dec {A} `{H : EqDec A} (x y : A) : Dec (x = y).
Proof.
  constructor.
  unfold decidable.
  destruct (x =? y) eqn:E.
  - left. rewrite <- eqb_eq. assumption.
  - right. intros C. rewrite <- eqb_eq in C. rewrite E in C. inversion C.
Defined.

#[export] Instance Dec_conj {P Q} {H : Dec P} {I : Dec Q} : Dec (P /\ Q).
Proof.
  constructor. unfold decidable.
  destruct H as [D]; destruct D;
    destruct I as [D]; destruct D; auto;
      right; intro; destruct H; contradiction.
Defined.

(* 练习 dec_neg_disj：~P 与 P\/Q 的 Dec 实例
   （解答与 QuickChick 2.2.0 源码 src/Decidability.v 中的
   Dec_neg / Dec_disj 逐字相同） *)
#[export] Instance Dec_neg {P} {H : Dec P} : Dec (~ P).
Proof.
  constructor. unfold decidable.
  destruct H as [D]; destruct D; auto.
Defined.

#[export] Instance Dec_disj {P Q} {H : Dec P} {I : Dec Q} : Dec (P \/ Q).
Proof.
  constructor. unfold decidable.
  destruct H as [D]; destruct D;
    destruct I as [D]; destruct D; auto;
      right; intro; destruct H; contradiction.
Defined.

(* 练习 Dec_All：All P l 的 Dec 实例（P 逐点可判定） *)
Fixpoint All {T : Type} (P : T -> Prop) (l : list T) : Prop :=
  match l with
  | [] => True
  | x :: l' => P x /\ All P l'
  end.

#[export] Instance Dec_All {T : Type} (P : T -> Prop)
         {H : forall a : T, Dec (P a)} (l : list T) : Dec (All P l).
Proof.
  constructor. unfold decidable.
  induction l as [| x l' IH]; simpl.
  - left. exact I.
  - destruct (H x) as [D]. destruct D as [Px | nPx].
    + destruct IH as [AllP | nAllP].
      * left. split; assumption.
      * right. intros [_ C]. contradiction.
    + right. intros [C _]. contradiction.
Defined.

Notation "P '?'" :=
  (match (@dec P _) with
   | left _ => true
   | right _ => false
   end)
  (at level 100).

Definition silly_fun1 (x y z : nat) :=
  if andb (x =? y) (andb (y =? z) (x =? z))
  then "all equal"
  else "not all equal".

Definition silly_fun2 (x y z : nat) :=
  if (x = y /\ y = z /\ x = z)?
  then "all equal"
  else "not all equal".

Compute (silly_fun2 1 1 1).
```

`decidable P` 是 `{P} + {~ P}`：位于 `Set` 的**有信息析取**，计算时可以检查究竟走到 `left` 还是 `right`。这比 `P \/ ~P` 的纯 `Prop` 证据更适合程序执行。`Dec P` 再给这份和类型证据套一层记录，投影 `dec` 取出它。

由于 `ssreflect` 的隐式参数设置，`Arguments dec _ {_}` 明确恢复为：命题 `P` 显式，后面的 `Dec P` 实例隐式。这样后面的 `dec (P a)` 与 `@dec P _` 都有稳定的参数格局。导入库后投影参数发生变化是常见兼容坑，应像这里一样用 `Check`/`About` 核实，而不是盲目改调用。

各实例的逻辑如下：

1. `EqDec__Dec` 把相等判断转成 `Dec (x = y)`。`destruct (x =? y) eqn:E` 保留检查结果等式。真分支选 `left`，借助 `eqb_eq` 与 `E` 证明 `x = y`；假分支选 `right`，假设矛盾证据 `C : x = y`，反射成 `x =? y = true` 后与 `E` 冲突，`inversion C` 收尾。
2. `Dec_conj` 分别拆开 `H : Dec P` 和 `I : Dec Q` 的记录及和类型。两边都成立时 `auto` 给出 `left` 的合取证明；其余分支选择 `right`，引入 `P /\ Q` 后拆解，与已有的 `~P` 或 `~Q` 矛盾。
3. 练习 `dec_neg_disj` 中，`Dec_neg` 只需拆 `Dec P`：有 `P` 时可证 `~ ~ P` 的否定方向，有 `~P` 时可证 `~P` 本身，`auto` 能处理这两个逻辑目标。`Dec_disj` 在任一分支成立时选 `left`；两者都否定时选 `right`，引入并拆解 `P \/ Q`，两路都 `contradiction`。
4. `All P l` 递归定义「列表每个元素满足 `P`」：空表为 `True`，非空表为 `P x /\ All P l'`。`Dec_All` 的前提不是单个 `Dec`，而是 `forall a, Dec (P a)`，因此每个元素都能取判定器。
5. `Dec_All` 的证明对 `l` 归纳。空表选 `left`，`exact I` 证明 `True`。非空时先拆 `H x` 得到 `Px` 或 `nPx`，再拆归纳假设 `IH`。`Px` 与 `AllP` 同时成立时构造合取；若表尾不可满足，就否定合取的第二分量；若表头不可满足，就否定第一分量。这实质上是把列表判定器写成证明脚本。

最后的 `P?` 记号把 `@dec P _` 的两个分支分别映射成 `true`、`false`。`silly_fun1` 手工串接三次布尔相等；`silly_fun2` 直接对命题合取加 `?`，实例搜索自动组合 `EqDec__Dec` 与 `Dec_conj`。两者计算含义相同，但后者让源码保持在更自然的命题层。`Compute` 验证三个 `1` 时返回 `"all equal"`。

**坑：** 并非所有 `Prop` 都可判定，不能给任意命题凭空造 `Dec` 实例；实例必须提供真正的计算证据。`P?` 也不是把经典排中律偷偷变成布尔函数，它只能使用已经注册且可构造的判定证据。69 章把性质交给 QuickChick、72 章讨论可检查性质时，这个「命题必须有可执行证据」的边界会反复出现。

### 70.13 Monad：ext-lib 的 Monad 类与 ret/bind 记号

类型类不只服务于运算符重载——**结构**也能抽象。QuickChick 的生成器 `G` 是一个
单子，而单子接口本身就是一个类型类（来自 QuickChick 的依赖 coq-ext-lib）：

```coq
(* ---------- 70.13 Monad：ext-lib 的 Monad 类与 ret/bind 记号 ---------- *)

Export MonadNotation.
Open Scope monad_scope.

(* ext-lib 的主定义（ExtLib.Structures.Monad，打印时带 Polymorphic
   的宇宙多态细节，此处按原书写出简化版）：
    Class Monad (M : Type -> Type) : Type :=
       {
         ret : forall {T : Type}, T -> M T ;
         bind : forall {T U : Type}, M T -> (T -> M U) -> M U
       }.
*)

#[export] Instance optionMonad : Monad option :=
  {
    ret T x :=
      Some x ;
    bind T U m f :=
      match m with
        None => None
      | Some x => f x
      end
  }.
```

`Export MonadNotation. Open Scope monad_scope.` 打开单子记号：`ret`（注入）与
`x <- m ;; n`（绑定）。`option` 是最朴素的单子：`ret` 就是 `Some`，`bind` 在
`None` 时短路。字段定义里的 `ret T x :=` 形式把类型参数 `T`、`U` 显式绑定出来——
record 字段的「参数绑定」语法（70.1 节 showPrimary 同款）。

单子记号的威力在链式调用里——安全取列表第 n 个元素的函数：

```coq
Fixpoint nth_opt {A : Type} (n : nat) (l : list A) : option A :=
  match l with
    [] => None
  | h::t => if n =? 0 then Some h else nth_opt (n-1) t
  end.

Definition sum3 (l : list nat) : option nat :=
  x0 <- nth_opt 0 l ;;
  x1 <- nth_opt 1 l ;;
  x2 <- nth_opt 2 l ;;
  ret (x0 + x1 + x2).

Compute (sum3 [1; 2; 3; 4]).
Compute (sum3 [1; 2]).
```

`x0 <- nth_opt 0 l ;; ...` 读作「从第一个元素取值，失败则整体失败」——三行取
三个元素，任何一步 `None` 整条链就 `None`。`Compute` 两次验证：四元素列表得
`Some 6`，两元素列表得 `None`。第 17 章手写 option `bind` 链的对照：记号让「安
全流水线」读起来像顺序程序。

经典_liftM_ 系列——把普通函数抬进单子：

```coq
Definition liftM
            {m : Type -> Type}
            {M : Monad m}
            {T U : Type} (f : T -> U)
          : m T -> m U :=
  fun x => bind x (fun x => ret (f x)).

Definition liftM2
            {m : Type -> Type}
            {M : Monad m}
            {T U V : Type} (f : T -> U -> V)
          : m T -> m U -> m V :=
    fun x y => bind x (fun x => liftM (f x) y).

Definition liftM3
            {m : Type -> Type}
            {M : Monad m}
            {T U V W : Type} (f : T -> U -> V -> W)
          : m T -> m U -> m V -> m W :=
  fun x y z => bind x (fun x => liftM2 (f x) y z).

Definition sum3opt (n1 n2 : option nat) :=
  x1 <- n1 ;;
  x2 <- n2 ;;
  ret (x1 + x2).

Definition sum3opt' (n1 n2 : option nat) :=
  liftM2 plus n1 n2.

Compute (sum3opt' (Some 1) (Some 2)).
```

`liftM` 把 `T -> U` 变成 `m T -> m U`；`liftM2`/`liftM3` 逐级用下一层组合——
注意 `{M : Monad m}` 约束让这些定义对**任何**单子成立（option、G、……）。同一
件事的两种写法：`sum3opt` 用记号展开、`sum3opt'` 用 `liftM2` 一行收束，语义完
全相同（`Compute` 返回 `Some 3`）。71 章写树生成器时会大量使用 `liftM3 Node`——
「三个子生成器各自采样，组装成 Node」正是 liftM3 的形状。

### 70.14 defaulting：解析到非预期实例的陷阱

实例搜索是**双向**的：不仅能补全你想要的实例，也可能把你没打算固定的类型变量
一并「钉死」。看这个 innocuous 的定义：

```coq
(* ---------- 70.14 defaulting：解析到非预期实例的陷阱 ---------- *)

Check @eqb.
(* ==>
     @eqb : forall A : Type, Eq A -> A -> A -> bool    *)

Definition foo x := if x =? x then "Of course" else "Impossible".

About foo.
(* ==> 定义当场就被钉死了：
     foo : (bool -> bool) -> string *)

Fail Check (foo true).
(* ==>（rocq 9.3 实测；与原书记载一致）
     Error:
     The term "true" has type "bool" while it is expected to have type
      "bool -> bool". *)
```

`x =? x` 需要为 `x` 的类型 `?A` 找 `Eq ?A` 实例。`?A` 还没定下来，实例搜索却
**不等待**——它在库里找到第一个能与 `Eq ?A` 统一的实例（`eqBoolBool : Eq
(bool->bool)`，因为库里恰好有它），把 `?A` 钉成 `bool -> bool`。于是 `foo` 的
类型成了 `(bool -> bool) -> string`，`foo true` 直接类型错误。`About foo` 与
`Fail Check` 把这个「定义时固化」拍在明面上。

```coq
(* 练习 debugDefaulting：Set Typeclasses Debug 后重放
   Definition foo，可以看到搜索 Eq ?A 时第一个命中的是
   eqBoolBool : Eq (bool->bool)——定义 foo 时 x 的类型是待定的
   evar ?A，实例搜索不管 ?A 还没定下来，直接拿库里第一个能统一
   的实例把 ?A 钉成 bool->bool，foo 的类型于是成了
   (bool->bool) -> string。教训：喂给实例搜索的问题的「形状」
   至关重要——泛型函数里用重载操作符时，务必先用 `{Eq A} 等约束
   或显式类型标注把类型变量绑住。 *)
```

练习的解答就是复现路径：`Set Typeclasses Debug.` 后重放 `Definition foo`，
debug 输出里能看到 `exact eqBoolBool on (Eq ?A)` 一行——罪证确凿。教训有两
条：其一，泛型函数里用重载操作符时**先声明类约束**（`` `{Eq A} ``），把 `?A`
挡在实例搜索之外；其二，看到「类型莫名其妙变成某个具体类型」时第一反应查
defaulting。

### 70.15 操控 hint 库：重叠实例与优先级

同一个类可以有多个匹配同一目标类型的实例——命中哪个？

```coq
(* ---------- 70.15 操控 hint 库：重叠实例与优先级 ---------- *)

Inductive baz := Baz : nat -> baz.

#[export] Instance baz1 : Show baz :=
  {
    show b :=
      match b with
        Baz n => "Baz: " ++ show n
      end
  }.

#[export] Instance baz2 : Show baz :=
  {
    show b :=
      match b with
        Baz n => "[" ++ show n ++ " is a Baz]"
      end
  }.

Compute (show (Baz 42)).
(* ==> 重叠实例命中哪个不可预料，此处恰好是后注册的先被试中
     = "[42 is a Baz]"
     : string   *)

#[export] Remove Hints baz1 baz2 : typeclass_instances.
#[export] Existing Instance baz1.
Compute (show (Baz 42)).
(* ==>
     = "Baz: 42"
     : string    *)

#[export] Remove Hints baz1 : typeclass_instances.

#[export] Instance baz3 : Show baz | 2 :=
  {
    show b :=
      match b with
        Baz n => "Use me first!  " ++ show n
      end
  }.

#[export] Instance baz4 : Show baz | 3 :=
  {
    show b :=
      match b with
        Baz n => "Use me second!  " ++ show n
      end
  }.

Compute (show (Baz 42)).
(* ==> 优先级数字小者先试用（0 最高）；不写优先级时默认为
       实例的绑定子个数（越特化的实例绑定子越少、越优先）
     = "Use me first!  42"
     : string  *)

#[export] Existing Instance baz1 | 0.
Compute (show (Baz 42)).
(* ==>
     = "Baz: 42"
     : string    *)
```

四步实验逐步看清 hint 库的运作：

1. `baz1`/`baz2` 都注册 `Show baz`——重叠。`Compute (show (Baz 42))` 命中
   `baz2`（后注册的先被试中），打印 `[42 is a Baz]`。**依赖注册顺序就是依赖
   实现细节**，换台机器、换个导入顺序结果可能翻转。
2. `Remove Hints baz1 baz2 : typeclass_instances.` 把两个实例从库里摘除，
   `Existing Instance baz1` 只放回 `baz1`——现在 `show (Baz 42)` 稳定返回
   `Baz: 42`。
3. `| 2` 与 `| 3` 是**显式优先级**：数字越小越先试用（0 最高）。baz3 优先级
   2 击败 baz4 的 3，`Use me first!  42`。
4. `Existing Instance baz1 | 0.` 以最高优先级重新注册——baz1 复辟。

不写优先级时，默认优先级是实例**绑定子的个数**——绑定子越少（实例越特化、
越具体）越优先。参数化实例（如 `showPair` 有 A、B、Show A、Show B 四个绑定
子）因此天然排在具体实例（`showNat` 零绑定子）之后。这解释了 70.4 节为什么
「先具体后参数化」自动成立：hint 库的默认排序帮你做了对的事。

**坑：** `Remove Hints` 与 `Existing Instance` 是操控 hint 库的正规手段，但
教程代码一般不该走到这一步——重叠实例本身就是设计味道，多半意味着两个实例
该合成一个，或其中一个该删。

### 70.16 调试：实例解析失败与发散

三个经典的失败现场，一个比一个隐蔽。

**现场一：缺口直指类型。**

```coq
(* ---------- 70.16 调试：实例解析失败与发散 ---------- *)

Inductive bar :=
  Bar : nat -> bar.

Fail Definition eqBar :=
  (Bar 42) =? (Bar 43).
(* ==> 没有 Eq bar 实例，报错直指缺口（rocq 9.3 实测）：
    Error:
    The following term contains unresolved implicit arguments:
      (Bar 42 =? Bar 43)
    More precisely:
    - ?Eq: Cannot infer the implicit parameter Eq of eqb whose type is
      "Eq bar" (no type class instance found). *)

Fail Definition ordBarList :=
  le [Bar 42] [Bar 43].
(* ==> 参数化实例尚未注册到 bar，搜索停在 list bar 一层（实测）：
    Error:
    The following term contains unresolved implicit arguments:
      ([Bar 42] <=? [Bar 43])
    More precisely:
    - ?H: Cannot infer the implicit parameter H of le whose type is
      "Eq (list bar)" (no type class instance found).
    - ?Ord: Cannot infer the implicit parameter Ord of le whose type is
      "Ord (list bar)" (no type class instance found). *)
```

第一个 `Fail`：没给 `bar` 写 `Eq` 实例，报错把缺口（`Eq bar`）写得明明白白。
第二个更有教学价值：`Ord (list A)` 实例存在（70.5 节 ordList），但它要求
`` `{Ord A} ``——`Ord bar` 不存在，于是整条链断在 `list bar` 这一层，报错同
时列出 `Eq (list bar)` 与 `Ord (list bar)` 两个未解决目标。**读实例报错的方
法：从最后一个 `no instance found` 往上找最具体的那个类型——那就是你要补写
实例的地方。**

**现场二：忘写反引号。**

```coq
Fail Definition max {A: Type} {Ord A} (x y : A) : A :=
  if le x y then y else x.
(* ==> 忘写反引号：`{Ord A} 变成 {Ord A}——Ord 被当成一个普通的
       隐式绑定子名字（与 A 共享一个待推断的类型 ?T），Rocq 在
       绑定子类型推断处就报错了（rocq 9.3 实测）：
    Error:
    The following term contains unresolved implicit arguments:
      (forall A : Type, ?T -> forall A0 : Type, A0 -> A0 -> A0)
    More precisely:
    - ?T: Cannot infer the type of Ord in environment:
      A : Type
    原书旧版此处报的是三个 UNDEFINED EVARS（?T/?H/?Ord 连环），
    病因相同：少了反引号，类约束根本没有生效。 *)
```

`` {Ord A} ``（无反引号）把 `Ord` 当成普通绑定子**名**字——一个类型待推断的
变量，与 70.6 节的隐式推广毫无关系。报错 `Cannot infer the type of Ord` 与
70.6 节 max1 的成功 `Print` 恰成对照：一字之差，语义两个世界。原书在旧版
Rocq 上此处报的是三个连环 evar，新版报一个——错误信息在改进，病因未变。

**现场三：搜索不终止。**

```coq
Class MyMap (A B : Type) : Type :=
  {
    mymap : A -> B
  }.

#[export] Instance MyMap1 : MyMap bool nat :=
  {
    mymap b := if b then 0 else 42
  }.

#[export] Instance MyMap2 : MyMap nat string :=
  {
    mymap := fun n : nat =>
      if le n 20 then "Pretty small" else "Pretty big"
  }.

Definition e1 := mymap true.
Compute e1.

Definition e2 := mymap 42.
Compute e2.

Fail Definition e3 : string := mymap false.
(* ==> 两个实例不会自动「接力」：没有从 bool 直达 string 的实例（实测）
    Error:
    The following term contains unresolved implicit arguments:
      (mymap false)
    More precisely:
    - ?MyMap: Cannot infer the implicit parameter MyMap of mymap whose
      type is "MyMap bool string" (no type class instance found). *)

#[export] Instance MyMap_trans {A B C : Type} `{MyMap A B} `{MyMap B C} : MyMap A C :=
  { mymap a := mymap (mymap a) }.

Definition e3 : string := mymap false.
Compute e3.

(* 练习 nonterm：为什么下面这行一旦放开就会发散？
   Definition e4 : list nat := mymap false.
   答：搜索 MyMap bool (list nat) 时先试 MyMap_trans，产生两个
   子目标 MyMap bool ?B 与 MyMap ?B (list nat)；其中 ?B 是自由
   evar，第二个子目标又可以再次匹配 MyMap_trans（?B 与任何头
   都能统一），于是搜索在 transitivtiy 式实例上无限递归——
   「传递」「对称」类实例是发散的头号嫌疑犯，必须限制或移除。
   保留注释，勿放开。 *)
(*
Definition e4 : list nat := mymap false.
*)
```

`MyMap` 是「任意两类型间的映射」类。`mymap true`（bool→nat 走 MyMap1）、
`mymap 42`（nat→string 走 MyMap2）都直连；`mymap false : string` 没有
bool→string 的直达实例，报错——**实例搜索不做自动接力**，两段路要手动焊：
`MyMap_trans` 声明「A→B 且 B→C 则 A→C」，加上它之后 `mymap false : string`
就能走 bool→nat→string 两跳（先 0/42 再 "Pretty small/big"，`Compute e3`
得 `"Pretty small"`）。

但 trans 实例是发散的种子（练习 nonterm，故保留注释不放开）：搜
`MyMap bool (list nat)` 时，trans 先命中，拆出 `MyMap bool ?B` 与
`MyMap ?B (list nat)`；后者里的 `?B` 是自由 evar，可以**再次**匹配 trans
（`?B` 与任何头都能统一），无限递归。这一段的教训：**传递闭包式的实例会把
实例搜索变成不终止的图搜索**——要么不给它通配形状（把 `?B` 限定为具体的中
间类型），要么干脆不写 trans 实例。

### 70.17 实战中的类型类：QuickChick 的四件套

收束本章——69 章用过的 QuickChick，其整个接口就建在本章的机制之上：

```coq
(* ---------- 70.17 实战中的类型类：QuickChick 的四件套 ---------- *)

(* 69 章用过的 QuickChick，其整个接口就建在本章机制之上。
   以下类定义逐字摘自 QuickChick 2.2.0 源码（本机未安装该库，
   仅作阅读；71 章起会在生成器里逐个用到）——

   src/Classes.v（生成与收缩的类层次）：
     Class GenSized (A : Type) :=
       { arbitrarySized : nat -> G A }.
     Class Gen (A : Type) := { arbitrary : G A }.
     Class Shrink (A : Type) :=
       { shrink : A -> list A }.
     Class Arbitrary (A : Type) `{Gen A} `{Shrink A}.
   注意 Arbitrary 的写法正是 70.5 节的「超类参数」模式：
   声明 Arbitrary A 实例前必须先有 Gen A 与 Shrink A。

   src/Show.v（与本章 70.1 节的教学版逐字相同）：
     Class Show (A : Type) : Type :=
     {
       show : A -> string
     }.

   src/Decidability.v（与 70.12 节的 Dec 逐字相同）：
     Class Dec (P : Prop) : Type := { dec : decidable P }.
     Class Dec_Eq (A : Type) :=
       {
         dec_eq : forall (x y : A), decidable (x = y)
       }.
   Dec_Eq 就是本章 EqDec 的「记录证据」版：不包装布尔检查器，
   直接给「任意 x y 可判定」的证据。QuickChick 还为常见类型
   备好了 Dec_eq_bool、Dec_eq_nat 等实例。

   src/Generators.v 里 G 单子注册为 ext-lib 的 Monad 实例：
     #[global] Instance MonadGen : Monad G := ...
   71 章写生成器时的 x <- g1 ;; g2 记号就来自这里。

   也正因为 QuickChick 自带同名的 Show / Dec 等类，本章示例
   全程不导入 QuickChick——两套同名类同处一个文件会撞车
   （类的常量名、showBool/showNat 等实例名都相同）。自本章
   起教程的取舍：本章自建类讲清机制，69、71–76 章统一使用
   QuickChick 库里的类。 *)

End Ex70Typeclasses.
```

对照清单：`Show` 与 70.1 节的教学版一字不差；`Dec`/`Dec_Eq` 是 70.12 节的
原样（`Dec_Eq` 对应 `EqDec` 的证据版）；`GenSized`/`Gen`/`Shrink`/`Arbitrary`
是 70.5 节「超类参数」模式的直接应用——想给自定义类型 `T` 装「可测试」四件套，
就按 71/72 章的手法提供 `GenSized T`（或 `Gen T`）与 `Shrink T` 实例，
`Arbitrary` 由合取实例自动组装；或者干脆 74 章 `QCDerive` 一行派生。

还有一个工程细节藏在本章的文件头里：**本章自建的类与 QuickChick 的类同名**
（`Show`、`Dec`、`showBool`……），所以 70_typeclasses.v 全程**不导入**
QuickChick——两套同名定义同处一个文件必然撞车。教程的取舍是：本章自建类讲
透机制，69、71–76 章统一用库版。你在自己的项目里做同样的事时，要么坚持只用
一套，要么把自己的类放进独立模块再用限定名引用。
