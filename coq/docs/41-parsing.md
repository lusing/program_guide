# 41 · 词法与语法解析

对应示例：`../examples/41_parsing.v`（`Module Ex41Parsing`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

38 章我们**写**Imp 程序用 `<{ X := 1 }>`，但那是给 Coq 的记号系统看的。本章打通
最后一公里：**给一段真正的源文本字符串**——`"x := (1 + 2 * y)"`——造一台机器，把
它变成 38 章的 AST。整机分三层：

1. **词法分析**（41.2–41.5）：字符分类 → 正则匹配的归纳规格 → `tokenize`，把字符串
   切成 token 列表（`["x"; ":="; "("; "1"; ...]`）。
2. **解析基础设施**（41.6–41.8）：带错误信息的 `optionE`、`';;` 与 `TRY..OR` 两条
   记号、解析器组合子（`many`/`firstExpect`/`expect`）、标识符与数字两个原子解析器。
3. **语法分析**（41.9–41.11）：按优先级分层的互递归 Fixpoint——算术三级、布尔两级、
   命令两级——最后合成总入口 `parse`。

全程两个老朋友返场：**燃料**（39 章的 step-indexing 在这里管住互递归的终止性）和
**`<{}>` 记号**（41.1 的语言副本）。41.12 用两段完整源文本做整机验收——`reflexivity`
一声不响地确认解析器吐出的 AST 与手写的记号项**逐构造子相等**。

### 41.1 语言层的最小副本（同 38-40 章：只要语法，不要语义）

本章只需要语法（不要 aeval/ceval），副本比 38–40 章短一截：

```coq
(* 41 词法与语法解析 —— 从源文本字符串到 aexp/bexp/com：字符判定、tokenize、解析器组合子与 parse *)

From Stdlib Require Import Arith Bool List Strings.String Strings.Ascii Arith.Arith.
Import ListNotations.

Module Ex41Parsing.

(* ---------- 41.1 语言层的最小副本（同 38-40 章：只要语法，不要语义） ---------- *)

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.

Declare Custom Entry com.
Declare Scope com_scope.

Notation "<{ e }>" := e
  (e custom com, format "'[hv' <{ '/  ' '[v' e ']' '/' }> ']'") : com_scope.

Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).

Notation "f x .. y" := (.. (f x) .. y)
                  (in custom com at level 0, only parsing,
                  f constr at level 0, x constr at level 1,
                      y constr at level 1).

Notation "x + y"   := (APlus x y) (in custom com at level 50, left associativity).
Notation "x - y"   := (AMinus x y) (in custom com at level 50, left associativity).
Notation "x * y"   := (AMult x y) (in custom com at level 40, left associativity).

Notation "'true'"  := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).

Notation "x <= y"  := (BLe x y) (in custom com at level 70, no associativity).
Notation "x = y"   := (BEq x y) (in custom com at level 70, no associativity).
Notation "x && y"  := (BAnd x y) (in custom com at level 80, left associativity).
Notation "'~' b"   := (BNot b) (in custom com at level 75, right associativity).

Open Scope com_scope.

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'"  := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y"  := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85, no associativity,
    format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.
```

注意本章的 bexp 比 38 章**少**了 BNeq 和 BGt（`<>`/`>`）——token 表和布尔解析器
相应只处理 `=` 与 `<=`，少两个分支，正文更短。这是对原书内容的裁剪之一（原书
ImpParser 同样只走部分运算符），完整的运算符集是现成的扩展练习。

### 41.2 字符判定：ascii 码点上的布尔函数

一切从单个字符开始。`ascii` 是 8 位字符类型，`nat_of_ascii` 给出码点，四个判定
函数各管一类：

```coq
(* ---------- 41.2 字符判定：ascii 码点上的布尔函数 ---------- *)

Definition isWhite (c : ascii) : bool :=
  let n := nat_of_ascii c in
  orb (orb (n =? 32)   (* space *)
           (n =? 9))   (* tab *)
      (orb (n =? 10)   (* linefeed *)
           (n =? 13)). (* Carriage return. *)

Definition isLowerAlpha (c : ascii) : bool :=
  let n := nat_of_ascii c in
    andb (97 <=? n) (n <=? 122).

Definition isAlpha (c : ascii) : bool :=
  let n := nat_of_ascii c in
    orb (andb (65 <=? n) (n <=? 90))
        (andb (97 <=? n) (n <=? 122)).

Definition isDigit (c : ascii) : bool :=
  let n := nat_of_ascii c in
     andb (48 <=? n) (n <=? 57).
```

码点数字直接来自 ASCII 表：空白是 32/9/10/13，大写 A–Z 是 65–90，小写 a–z 是
97–122，数字 0–9 是 48–57。**`isLowerAlpha` 和 `isAlpha` 是两个不同的函数**——后面
`parseIdentifier` 用的是前者，这决定了本章语言的标识符**只许小写**（坑清单第 1 条
有它的实际后果）。归类成一个四值类型：

```coq
Inductive chartype := white | alpha | digit | other.

Definition classifyChar (c : ascii) : chartype :=
  if isWhite c then
    white
  else if isAlpha c then
    alpha
  else if isDigit c then
    digit
  else
    other.

Example classifyChar_ex :
  map classifyChar ["a"%char; " "%char; "9"%char; "("%char; "Z"%char]
  = [alpha; white; digit; other; alpha].
Proof. reflexivity. Qed.
```

`Example` 一行实测五个字符的归类（注意 `"a"%char` 的 `%char` 限定——不加的话
`"a"` 按 string 解析，类型对不上）。`(` 落进 `other`——后面 tokenize 对括号有
专门的特判分支。

### 41.3 字符串与 ascii 列表的互转

Coq 的 `string` 本质是 ascii 的链表（`String c s`），tokenize 在列表上做模式匹配
更顺手，所以先铺两条互转：

```coq
(* ---------- 41.3 字符串与 ascii 列表的互转 ---------- *)

Fixpoint list_of_string (s : string) : list ascii :=
  match s with
  | EmptyString => []
  | String c s => c :: (list_of_string s)
  end.

Definition string_of_list (xs : list ascii) : string :=
  fold_right String EmptyString xs.

Example list_of_string_ex :
  list_of_string "ab1" = ["a"%char; "b"%char; "1"%char].
Proof. reflexivity. Qed.

Example string_roundtrip :
  string_of_list (list_of_string "x:=1") = "x:=1"%string.
Proof. reflexivity. Qed.
```

`list_of_string` 逐字符拆开；`string_of_list` 用 `fold_right` 装回去。`roundtrip`
验证往返无损——tokenize 的输出 token 是"装回去的子串"，全靠这对函数。

### 41.4 正则表达式与 exp_match：词法的归纳规格

哪些字符串是合法 token？给一个**归纳定义的规格**——正则表达式与匹配关系：

```coq
(* ---------- 41.4 正则表达式与 exp_match：词法的归纳规格 ---------- *)

Reserved Notation "s =~ re" (at level 80).

Inductive reg_exp (T : Type) : Type :=
  | EmptySet
  | EmptyStr
  | Char (x : T)
  | App (re1 re2 : reg_exp T)
  | Union (re1 re2 : reg_exp T)
  | Star (re : reg_exp T).

Arguments EmptySet {T}.
Arguments EmptyStr {T}.
Arguments Char {T} _.
Arguments App {T} _ _.
Arguments Union {T} _ _.
Arguments Star {T} _.

Inductive exp_match {T} : list T -> reg_exp T -> Prop :=
  | MEmpty : [] =~ EmptyStr
  | MChar x : [x] =~ (Char x)
  | MApp s1 re1 s2 re2
             (H1 : s1 =~ re1)
             (H2 : s2 =~ re2)
           : (s1 ++ s2) =~ (App re1 re2)
  | MUnionL s1 re1 re2
                (H1 : s1 =~ re1)
              : s1 =~ (Union re1 re2)
  | MUnionR s2 re1 re2
                (H2 : s2 =~ re2)
              : s2 =~ (Union re1 re2)
  | MStar0 re : [] =~ (Star re)
  | MStarApp s1 s2 re
                 (H1 : s1 =~ re)
                 (H2 : s2 =~ (Star re))
               : (s1 ++ s2) =~ (Star re)

  where "s =~ re" := (exp_match s re).
```

`reg_exp` 六个构造子（空集/空串/单字符/拼接/并/星），参数化于元素类型 T。
`exp_match` 是**关系**（Prop！）而不是函数——本章用它当"什么是合法数字串"的
**规格说明**，推理工具是 `apply 构造子`。七条规则读法：空串匹配 EmptyStr；单元素
匹配 Char；拼接分段各自匹配；并取左右；星的零次与"一次 + 余下"。三个例子：

```coq
Example reg_exp_ex1 : [1] =~ Char 1.
Proof.
  apply MChar.
Qed.

Example reg_exp_ex2 : [1; 2] =~ App (Char 1) (Char 2).
Proof.
  apply (MApp [1]).
  - apply MChar.
  - apply MChar.
Qed.

Lemma MStar1 :
  forall T s (re : reg_exp T),
    s =~ re ->
    s =~ Star re.
Proof.
  intros T s re H.
  rewrite <- (app_nil_r s).
  apply MStarApp.
  - apply H.
  - apply MStar0.
Qed.

Example digits_ex :
  ["1"%char; "2"%char] =~ Star (Union (Char "1"%char) (Char "2"%char)).
Proof.
  apply (MStarApp ["1"%char]).
  - apply MUnionL. apply MChar.
  - apply (MStarApp ["2"%char]).
    + apply MUnionR. apply MChar.
    + apply MStar0.
Qed.
```

- `MApp [1]` 显式给**切分点**（和 38 章 `apply E_Seq with (中间状态)` 同一手法——
  归纳关系的构造子凡有"缝合处"都要人给）。
- `MStar1`："匹配一次即匹配星"——补一个空尾巴再套 `MStarApp`。这条原书留作练习，
  这里直接证掉，它说明星号的"至少一次"变体是免费的。
- `digits_ex`："12" 匹配 (1|2) 的星——手工铺两轮 MStarApp，正是 40 章 multi 手工链
  的既视感：**关系的构造子链就是运行轨迹**。

### 41.5 词法分析：tokenize

规格有了，实现是一台逐字符状态机：

```coq
(* ---------- 41.5 词法分析：tokenize ---------- *)

Definition token := string.

Fixpoint tokenize_helper (cls : chartype) (acc xs : list ascii)
                       : list (list ascii) :=
  let tk := match acc with [] => [] | _::_ => [rev acc] end in
  match xs with
  | [] => tk
  | (x::xs') =>
    match cls, classifyChar x, x with
    | _, _, "("      =>
      tk ++ ["("]::(tokenize_helper other [] xs')
    | _, _, ")"      =>
      tk ++ [")"]::(tokenize_helper other [] xs')
    | _, white, _    =>
      tk ++ (tokenize_helper white [] xs')
    | alpha,alpha,x  =>
      tokenize_helper alpha (x::acc) xs'
    | digit,digit,x  =>
      tokenize_helper digit (x::acc) xs'
    | other,other,x  =>
      tokenize_helper other (x::acc) xs'
    | _,tp,x         =>
      tk ++ (tokenize_helper tp [x] xs')
    end
  end %char.

Definition tokenize (s : string) : list string :=
  map string_of_list (tokenize_helper white [] (list_of_string s)).
```

读这台机器：`cls` 是**当前正在攒的 token 的类别**，`acc` 是攒到一半的字符（倒序，
收尾时 `rev`）。八个分支四类行为：

- 遇到括号：**先结算 acc**（`tk`），括号自己单成一个 token（`["("]`——单字符列表，
  稍后 `string_of_list` 装回 `"("`），类别重置 `other`。
- 遇到空白：结算 acc，**丢弃空白**，类别 `white`。
- 新字符与 acc **同类**（alpha/digit/other 三条）：继续攒（`x::acc`）。
- **换类**（兜底分支）：结算 acc，新字符自己开张。

`tokenize` 把源文本转 ascii 列表、机器跑完、每段 `string_of_list` 装回字符串。
注意 `%char` 限定让 match 里的 `"("` 按 ascii 解析。两个词表与四个实测：

```coq
Open Scope string_scope.

(* 本章 token 集：固定符号 + 关键字，都由 tokenize 切成单 token *)
Definition symbols : list token :=
  ["("; ")"; "+"; "-"; "*"; "="; "<="; "&&"; "~"; ":="; ";"].

Definition keywords : list token :=
  ["skip"; "if"; "then"; "else"; "end"; "while"; "do"; "true"; "false"].

Example symbols_tokenize :
  map tokenize symbols = map (fun t => [t]) symbols.
Proof. reflexivity. Qed.

Example keywords_tokenize :
  map tokenize keywords = map (fun t => [t]) keywords.
Proof. reflexivity. Qed.

Example tokenize_ex1 :
    tokenize "abc12=3  223*(3+(a+c))" %string
  = ["abc"; "12"; "="; "3"; "223";
       "*"; "("; "3"; "+"; "(";
       "a"; "+"; "c"; ")"; ")"]%string.
Proof. reflexivity. Qed.

Example tokenize_fuse :
  tokenize "+-"%string = ["+-"]%string.
Proof. reflexivity. Qed.
```

- 两个词表 Example：每个符号/关键字 token 化后都是**单元素列表**——tokenize 的切分
  与词表约定一致。
- `tokenize_ex1` 是整机实录：字母数字连缀成块（`abc12`、`223`）、空白消失、括号
  单列。
- `tokenize_fuse` 揭示一个**设计决定**：`+` 和 `-` 都是 `other` 类，相邻的 other 会
  **粘连**成一个 token `"+-"`。对单字符运算符的语言来说这是个已知瑕疵（LF 原书
  如此），解析层的 `firstExpect "+"` 遇到 `"+-"` 会报错——词法粘连交由上层拒绝。
  想修就在换类分支对 other 也逐字符切开（坑清单第 2 条）。

### 41.6 带错误信息的结果类型：optionE 与两条记号

解析要报告**错在哪**。`option` 的 `None` 不带信息，自造一个：

```coq
(* ---------- 41.6 带错误信息的结果类型：optionE 与两条记号 ---------- *)

Inductive optionE (X : Type) : Type :=
  | SomeE (x : X)
  | NoneE (s : string).

Arguments SomeE {X}.
Arguments NoneE {X}.

Notation "' p <- e1 ;; e2"
   := (match e1 with
       | SomeE p => e2
       | NoneE err => NoneE err
       end)
   (right associativity, p pattern, at level 60, e1 at next level).

Notation "'TRY' e1 'OR' e2"
   := (
    let result := e1 in
    match result with
       | SomeE _  => result
       | NoneE _ => e2
       end)
   (right associativity,
    at level 60, e1 at next level, e2 at next level).
```

两条记号是本章的语法重头：

- `' p <- e1 ;; e2`：**单子绑定**。p 是模式（`p pattern`——模式位置出现在记号定义
  里，和 39 章 `LETOPT` 同一技术），e1 成功则解构继续 e2，失败则**错误向左短路**。
  链式书写全靠 `right associativity`。
- `TRY e1 OR e2`：**回退**。e1 失败（无论什么错）就换 e2——解析器组合子的"备选
  语法"靠它。注意实现里 `let result := e1 in` 先求值绑定——避免 e1 被复制进两个
  match 分支（纯化 + 共享求值）。

repl 在这两条记号定义处打印 `Identifier 'OR' now a keyword` 等——`'` 和 `TRY`/`OR`
从此是保留字（和 39 章 `LETOPT`/`IN` 同族的代价）。

```coq
Fail Check [1] ++ [2].

Example optionE_chain :
  ' (n, rest) <- SomeE (41, ["x"]) ;;
  SomeE (n + 1, rest) = SomeE (42, ["x"]).
Proof. reflexivity. Qed.

Example optionE_shortcut :
  ' (n, rest) <- NoneE "no number" ;;
  SomeE (n + 1, rest)
  = (NoneE "no number" : optionE (nat * list token)).
Proof. reflexivity. Qed.

Example try_or_first :
  (TRY SomeE 3 OR SomeE 4) = (SomeE 3 : optionE nat).
Proof. reflexivity. Qed.

Example try_or_fallback :
  (TRY NoneE "first" OR SomeE 7) = (SomeE 7 : optionE nat).
Proof. reflexivity. Qed.
```

开头的 `Fail Check [1] ++ [2].` 是个**反例警告**：repl 实测报

```
The command has indeed failed with message:
The term "[1]" has type "list nat" while it is expected to have type
 "string".
```

`Open Scope string_scope` 之后 `++` 被 **string 拼接**抢走（list 的 `++` 失效）——
这正是 41.5 开 `string_scope` 的副作用，坑清单第 3 条。四个 Example 分别验证：绑定
链成功、失败短路（注意右侧的类型标注 `(NoneE ... : optionE ...)`——不带标注的话
NoneE 的类型参数悬空）、TRY 取先成者、TRY 回退。

### 41.7 解析器组合子：parser / many / firstExpect / expect

**解析器**是一个函数类型：吃剩余 token 流，产出"结果 + 剩余"或错误。

```coq
(* ---------- 41.7 解析器组合子：parser / many / firstExpect / expect ---------- *)

Definition parser (T : Type) :=
  list token -> optionE (T * list token).

Fail Fixpoint many_bad {T} (p : parser T) (xs : list token)
                       : optionE (list T * list token) :=
  match p xs with
  | NoneE _ => SomeE ([], xs)
  | SomeE (t, xs') =>
      ' (ts, rest) <- many_bad p xs' ;;
      SomeE (t :: ts, rest)
  end.
```

`many_bad` 是教学反例："尽量多地重复 p"直接写成对输入的递归——但输入 `xs` 并不
随递归**结构性地**变小（p 可以失败、可以原地踏步），`Fail` 抓住守卫检查的拒绝
（解析期错误的 Fail 文本要进 repl 才看得到，实测报 `Cannot guess decreasing
argument`——38.7 `ceval_fun_bad` 的翻版）。老答案还是**燃料**：

```coq
Fixpoint many_helper {T} (p : parser T) acc steps xs :=
  match steps, p xs with
  | 0, _ =>
      NoneE "Too many recursive calls"
  | _, NoneE _ =>
      SomeE ((rev acc), xs)
  | S steps', SomeE (t, xs') =>
      many_helper p (t :: acc) steps' xs'
  end.

Definition many {T} (p : parser T) (steps : nat) : parser (list T) :=
  many_helper p [] steps.

Definition firstExpect {T} (t : token) (p : parser T)
                     : parser T :=
  fun xs => match xs with
            | x::xs' =>
              if string_dec x t
              then p xs'
              else NoneE ("expected '" ++ t ++ "'.")
            | [] =>
              NoneE ("expected '" ++ t ++ "'.")
            end.

Definition expect (t : token) : parser unit :=
  firstExpect t (fun xs => SomeE (tt, xs)).

Example many_exhausted :
  many (expect "x") 1 ["x"; "x"] = NoneE "Too many recursive calls".
Proof. reflexivity. Qed.

Example many_two :
  many (expect "x") 3 ["x"; "x"] = SomeE ([tt; tt], []).
Proof. reflexivity. Qed.

Example many_zero :
  many (expect "x") 5 [] = SomeE ([], []).
Proof. reflexivity. Qed.
```

- `many_helper`：**steps 做结构递归**（39 章 `ceval_step` 的配方），顺手把已解析的
  结果攒在 `acc`（尾递归风格，收尾 `rev`）。燃料耗尽返回带文案的错误——
  `many_exhausted` 实测：给 1 格燃料喂两个 "x"，报 `"Too many recursive calls"`。
- `firstExpect`：吃掉指定 token 后**转入** p——语法引导词（`if`、`then`、`:=`）全靠
  它；词不对就报 `expected '...'`（错误文案里带期望值，这是 optionE 的意义）。
- `expect`：只吃一个 token、不带后续（返回 `unit`）。
- `many_zero`：空输入直接成功空列表——`many` 允许零次。

### 41.8 标识符与数字：最底层的两个原子解析器

```coq
(* ---------- 41.8 标识符与数字：最底层的两个原子解析器 ---------- *)

Definition parseIdentifier (xs : list token)
                         : optionE (string * list token) :=
match xs with
| [] => NoneE "Expected identifier"
| x::xs' =>
    if forallb isLowerAlpha (list_of_string x) then
      SomeE (x, xs')
    else
      NoneE ("Illegal identifier:'" ++ x ++ "'")
end.

Definition parseNumber (xs : list token)
                     : optionE (nat * list token) :=
match xs with
| [] => NoneE "Expected number"
| x::xs' =>
    if forallb isDigit (list_of_string x) then
      SomeE (fold_left
               (fun n d =>
                  10 * n + (nat_of_ascii d -
                            nat_of_ascii "0"%char))
               (list_of_string x)
               0,
             xs')
    else
      NoneE "Expected number"
end.

Example parseIdentifier_ok :
  parseIdentifier ["abc"; "+"] = SomeE ("abc", ["+"]).
Proof. reflexivity. Qed.

Example parseIdentifier_bad :
  parseIdentifier ["X"; ":="] = NoneE "Illegal identifier:'X'".
Proof. reflexivity. Qed.

Example parseNumber_ok :
  parseNumber ["314"; ")"] = SomeE (314, [")"]).
Proof. reflexivity. Qed.
```

- `parseIdentifier`：token 全由小写字母组成（`forallb isLowerAlpha`——41.2 埋的
  伏笔），合法则整个 token 就是标识符。`parseIdentifier_bad` 实测：大写 `X` 被拒。
- `parseNumber`：全数字则把十进制字面量**折算成 nat**——`fold_left` 逐位
  `10*n + (d - '0')`，`parseNumber_ok` 实测 `"314"` 变成 `314`。**token 流里不再有
  数字字符串，AST 里是真正的 nat**——词法到语法完成了数据的升级。

### 41.9 算术表达式：初级/乘法/加法三级互递归

优先级语法的标准结构：每层一个函数，**底层收紧、上层放松**：

```coq
(* ---------- 41.9 算术表达式：初级/乘法/加法三级互递归 ---------- *)

Fixpoint parsePrimaryExp (steps : nat)
                         (xs : list token)
                       : optionE (aexp * list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
      TRY ' (i, rest) <- parseIdentifier xs ;;
          SomeE (AId i, rest)
      OR
      TRY ' (n, rest) <- parseNumber xs ;;
          SomeE (ANum n, rest)
      OR
      ' (e, rest) <- firstExpect "(" (parseSumExp steps') xs ;;
      ' (u, rest') <- expect ")" rest ;;
      SomeE (e, rest')
  end

with parseProductExp (steps : nat)
                     (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (e, rest) <- parsePrimaryExp steps' xs ;;
    ' (es, rest') <- many (firstExpect "*" (parsePrimaryExp steps'))
                          steps' rest ;;
    SomeE (fold_left AMult es e, rest')
  end

with parseSumExp (steps : nat) (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (e, rest) <- parseProductExp steps' xs ;;
    ' (es, rest') <-
        many (fun xs =>
                TRY ' (e, rest') <-
                    firstExpect "+"
                                (parseProductExp steps') xs ;;
                    SomeE ( (true, e), rest')
                OR
                ' (e, rest') <-
                    firstExpect "-"
                                (parseProductExp steps') xs ;;
                    SomeE ( (false, e), rest'))
        steps' rest ;;
      SomeE (fold_left (fun e0 term =>
                          match term with
                          | (true,  e) => APlus e0 e
                          | (false, e) => AMinus e0 e
                          end)
                       es e,
             rest')
  end.
```

三级 `Fixpoint ... with ... with` **互递归**（Coq 允许，只要每个入口都有结构递减的
参数——三个函数都以 `steps` 递减）：

- **primary（最紧）**：标识符 / 数字 / 括号包住的整个 sum。三种可能用 `TRY..OR`
  依次尝试；第三支里 `(parseSumExp steps')` 递归回顶层——**括号重置优先级**，
  steps' 保证每进一层燃料减一。
- **product（次紧）**：primary 开头，后面 `many` 个 `"*" primary`；`fold_left AMult
  es e` 把结果列表**左折**成嵌套 AMult——左结合由此免费获得。
- **sum（最松）**：product 开头，`many` 个 `("+"|"-") product`；many 的解析器对每个
  后缀先试 `+` 再试 `-`，产出 `(bool * aexp)` 标记加还是减，外层 `fold_left` 按
  标记选构造子——加减的左结合与混合运算一次成型。

燃料贯穿三级（全部用 `steps'`），总入口与三组实测：

```coq
Definition parseAExp := parseSumExp.

Definition testParsing {X : Type}
           (p : nat -> list token -> optionE (X * list token))
           (s : string) :=
  let t := tokenize s in
  p 100 t.

Example parseAExp_ex :
  testParsing parseAExp "1+2*y" = SomeE (<{1 + 2 * "y"}>, []).
Proof. reflexivity. Qed.

Example parseAExp_leftassoc :
  testParsing parseAExp "x-y-z" = SomeE (<{"x" - "y" - "z"}>, []).
Proof. reflexivity. Qed.

Example parseAExp_fuel_short :
  parseAExp 2 (tokenize "1+2") = NoneE "Too many recursive calls".
Proof. reflexivity. Qed.
```

- `parseAExp_ex`：`"1+2*y"` 解析成 `1 + 2*y` 而不是 `(1+2)*y`——**优先级由分层
  结构硬编码**，不是靠查表。
- `parseAExp_leftassoc`：`x-y-z` 左折成 `(x-y)-z`。
- `parseAExp_fuel_short`：燃料 2 解析 `"1+2"` 不够（sum→product→primary→（数字后
  回 sum 层）→……），报燃料错误——**燃料的账要实测**（39 章坑 13 的同款提醒）。

### 41.10 布尔表达式：原子与合取两级互递归

同一配方再搭两层：布尔原子（含算术比较）与 `&&` 合取：

```coq
(* ---------- 41.10 布尔表达式：原子与合取两级互递归 ---------- *)

Fixpoint parseAtomicExp (steps : nat)
                        (xs : list token) :=
match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
     TRY ' (u, rest) <- expect "true" xs ;;
         SomeE (BTrue, rest)
     OR
     TRY ' (u, rest) <- expect "false" xs ;;
         SomeE (BFalse, rest)
     OR
     TRY ' (e, rest) <- firstExpect "~"
                                   (parseAtomicExp steps')
                                   xs ;;
         SomeE (BNot e, rest)
     OR
     TRY ' (e, rest) <- firstExpect "("
                                   (parseConjunctionExp steps')
                                   xs ;;
         ' (u, rest') <- expect ")" rest ;;
         SomeE (e, rest')
     OR
     ' (e, rest) <- parseProductExp steps' xs ;;
     TRY ' (e', rest') <- firstExpect "="
                                  (parseAExp steps') rest ;;
         SomeE (BEq e e', rest')
     OR
     TRY ' (e', rest') <- firstExpect "<="
                                      (parseAExp steps') rest ;;
         SomeE (BLe e e', rest')
     OR
     NoneE "Expected '=' or '<=' after arithmetic expression"
end

with parseConjunctionExp (steps : nat)
                         (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (e, rest) <- parseAtomicExp steps' xs ;;
    ' (es, rest') <- many (firstExpect "&&"
               (parseAtomicExp steps'))
            steps' rest ;;
    SomeE (fold_left BAnd es e, rest')
  end.

Definition parseBExp := parseConjunctionExp.

Example parseBExp_ex :
  testParsing parseBExp "~(x=x&&x*x<=2)"
  = SomeE (<{~ ("x" = "x" && "x" * "x" <= 2)}>, []).
Proof. reflexivity. Qed.
```

`parseAtomicExp` 五个 OR 备选 + 一个兜底报错：true / false / `~ 原子`（**一元运算
递归调自己**，右结合）/ 括号合取 / **算术后跟比较**。最后一支先跑 41.9 的
`parseProductExp`——算术原子优先被吃掉，再 TRY `=` 与 `<=` 两种比较；两个都失败
时给出明确的兜底文案（裸算术式不是布尔式）。`parseConjunctionExp` 又是
"开头 + many"模板，`&&` 左折。`parseBExp_ex` 整机实测：`~(x=x&&x*x<=2)` 一次成型，
括号、比较、合取、否定各就各位。

### 41.11 命令与总入口 parse

最后两级互递归——简单命令与序列——然后收口：

```coq
(* ---------- 41.11 命令与总入口 parse ---------- *)

Fixpoint parseSimpleCommand (steps : nat)
                            (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    TRY ' (u, rest) <- expect "skip" xs ;;
        SomeE (<{skip}>, rest)
    OR
    TRY ' (e, rest) <-
            firstExpect "if"
                        (parseBExp steps') xs ;;
        ' (c, rest') <-
            firstExpect "then"
                        (parseSequencedCommand steps') rest ;;
        ' (c', rest'') <-
            firstExpect "else"
                        (parseSequencedCommand steps') rest' ;;
        ' (tt, rest''') <-
            expect "end" rest'' ;;
       SomeE (<{if e then c else c' end}>, rest''')
    OR
    TRY ' (e, rest) <-
            firstExpect "while"
                        (parseBExp steps') xs ;;
        ' (c, rest') <-
            firstExpect "do"
                        (parseSequencedCommand steps') rest ;;
        ' (u, rest'') <-
            expect "end" rest' ;;
        SomeE (<{while e do c end}>, rest'')
    OR
    TRY ' (i, rest) <- parseIdentifier xs ;;
        ' (e, rest') <- firstExpect ":=" (parseAExp steps') rest ;;
        SomeE (<{i := e}>, rest')
    OR
        NoneE "Expecting a command"
end

with parseSequencedCommand (steps : nat)
                           (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    ' (c, rest) <- parseSimpleCommand steps' xs ;;
    TRY ' (c', rest') <-
            firstExpect ";"
                        (parseSequencedCommand steps') rest ;;
        SomeE (<{c ; c'}>, rest')
    OR
    SomeE (c, rest)
  end.
```

四个备选命令形态（skip / if-then-else-end / while-do-end / 赋值）依次 TRY。
两个结构点：

- if 与 while 的**分支体用 `parseSequencedCommand`**（不是 simple）——所以
  `if b then x:=1; y:=2 else ...` 的 then 分支能吃下整段序列，`end`/`else` 才被
  `firstExpect` 命中。**引导词当括号用**，这是不用花括号的语言的标准做法。
- 序列层**右递归**：`c ; (后续整个序列)`——与 `;` 的右结合记号（38 章 level 90
  right associativity）精确对齐。

总入口：

```coq
Definition bignumber := 1000.

Definition parse (str : string) : optionE com :=
  let tokens := tokenize str in
  match parseSequencedCommand bignumber tokens with
  | SomeE (c, []) => SomeE c
  | SomeE (_, t::_) => NoneE ("Trailing tokens remaining: " ++ t)
  | NoneE err => NoneE err
  end.

Compute parse "x := 1".

Compute parse "x := (1 + 2".

Example parse_trailing :
  parse "x := 1 y := 2" = NoneE "Trailing tokens remaining: y".
Proof. reflexivity. Qed.
```

`parse` 三分支收口：解析成功且 token **吃净**才算数；剩了 token 报"尾巴"（哪个
token 没被消化）；深层失败透传错误。两个 `Compute` 是整机演示（repl 实测输出）：

```
     = SomeE <{"x" := 1}>
     : optionE com

     = NoneE "Expecting a command"
     : optionE com
```

第一条：`"x := 1"` 成功，AST 就是 38 章那个赋值。第二条：`"x := (1 + 2"` 括号
不闭合——深处的 `expected ')'` 错误被 `TRY..OR` 一层层**吞掉换文案**，最后冒出来
的是命令层的兜底 `"Expecting a command"`。这是 `TRY..OR` 设计的固有弱点：回退
机制丢上下文（坑清单第 4 条；要精确报错得用带回溯错误位置的组合子，或把 TRY 改成
"错误优先级"比较）。

### 41.12 实测：两段完整源文本变成 AST

验收：两段真实源文本，`cbv` 全力求值后与手写记号项**逐构造子相等**：

```coq
(* ---------- 41.12 实测：两段完整源文本变成 AST ---------- *)

Example eg1 : parse "
  if x = y + 1 + 2 - y * 6 + 3 then
    x := x * 1;
    y := 0
  else
    skip
  end  "
=
  SomeE <{
      if ("x" = ("y" + 1 + 2 - "y" * 6 + 3)) then
        "x" := "x" * 1;
        "y" := 0
      else
        skip
      end }>.
Proof. cbv. reflexivity. Qed.

Example eg2 : parse "
  skip;
  z:=x*y*(x*x);
  while x=x do
    if (z <= z*z) && ~(x = 2) then
      x := z;
      y := z
    else
      skip
    end;
    skip
  end;
  x:=z  "
=
  SomeE <{
      skip;
      "z" := "x" * "y" * ("x" * "x");
      while ("x" = "x") do
        if ("z" <= "z" * "z") && ~("x" = 2) then
          "x" := "z";
          "y" := "z"
        else
          skip
        end;
        skip
      end;
      "x" := "z" }>.
Proof. cbv. reflexivity. Qed.

End Ex41Parsing.
```

`eg1` 单个 if：比较、混合加减乘、两分支、skip。`eg2` 是全语法大检阅：序列、嵌套
赋值、while、if、合取、否定、比较、多层乘法、循环体内再嵌序列——整台机器
（tokenize → 三级算术 → 两级布尔 → 两级命令 → 收口）一次跑通，AST 与右边手写的
`<{ }>` 项完全一致。`cbv` 强制全量求值（`reflexivity` 默认的转换检查有时偷懒走
较弱的规约策略，`cbv` 前置最稳——坑清单第 5 条）。

至此闭环完成：38 章手写 AST、39 章给它跑燃料、40 章小步执行、42 章霍尔推理——
而本章之后，**写源文本就够了**。

### 41.13 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **标识符只许小写**（41.2/41.8）：`parseIdentifier` 用 `isLowerAlpha`（97–122），
   大写字母被拒（`parseIdentifier ["X"; ...] = NoneE "Illegal identifier:'X'"`
   实测）。本文件的第一版 `Compute parse "X := 1"` 正是栽在这里——大写 X 直接
   `"Expecting a command"`；改小写后 `SomeE <{"x" := 1}>`。**演示程序先过词法关**。
2. **other 类 token 粘连**（41.5）：`tokenize "+-" = ["+-"]`——相邻的 other 字符
   （所有单字符运算符）会粘成一个 token，解析层 `firstExpect "+"` 对 `"+-"` 报错。
   要逐字符切分，改 tokenize 的换类分支即可（本章按 LF 原样保留该瑕疵）。
3. **`Open Scope string_scope` 抢走 `++`**（41.5/41.6）：`Fail Check [1] ++ [2].`
   实测报 `The term "[1]" has type "list nat" while it is expected to have type
   "string"`——开 string_scope 后 `++` 是字符串拼接，列表拼接要 `app`/限定作用域。
   与 40 章 `%type` 坑同族：作用域开关是全局性的。
4. **`TRY..OR` 吞掉深层错误**（41.11）：`parse "x := (1 + 2"` 的真实错误是缺 `)`，
   但实测输出是命令层的 `"Expecting a command"`——回退链每层 OR 都把前一个错误
   丢弃。要精确报错需要"错误合并/优先级"机制（原书把改进留作练习）。
5. **验收大例子用 `cbv` 前置**（41.12）：`Proof. cbv. reflexivity. Qed.`——直接
   `reflexivity` 走的转换策略对深递归解析有时不够激进（慢或失败），`cbv` 强制全量
   求值一次定型。
6. **互递归 Fixpoint 的守卫参数**（41.9）：三级互递归能通过守卫检查是因为每个
   入口都以 `steps` 做结构递减；直接对输入列表递归的 `many_bad` 被 `Fail` 抓住
   （`Cannot guess decreasing argument`）。**互递归 + 燃料是解析器的标准姿势**。
7. **`' p <- e1 ;; e2` 的 p 是模式**（41.6）：记号定义里 `p pattern` 允许写
   `' (i, rest) <- ...` 这样的**元组模式绑定**——模式位置出现在记号里是稀罕用法，
   39 章 LETOPT 的 `st' <==` 是同款。`'` 和 `TRY`/`OR` 因此成为保留字。
8. **NoneE 的类型标注**（41.6）：`Example` 里比较 NoneE 时要写
   `(NoneE "..." : optionE (...))`——NoneE 的类型参数 X 不出现在参数里，不标注
   则整个等式的类型悬空。
9. **燃料账要实测**（41.9）：`parseAExp 2 (tokenize "1+2")` 实测燃料不足；同一
   输入 `testParsing`（100 格）通过。互递归每降一层烧一格（primary→product→sum
   回环烧得更多），上界取 `bignumber := 1000` 是工程缓冲。

---
上一章：[40 · 小步语义：执行即关系](40-smallstep.md) ｜ 下一章：[42 · Hoare 逻辑](42-hoare.md) ｜ 返回：[README](../README.md)
