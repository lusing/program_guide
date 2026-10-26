# 39 · 燃料求值器：把关系变回函数

对应示例：`../examples/39_fuel_evaluation.v`（`Module Ex39FuelEvaluation`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

38 章我们学了一个**只能纸面推理、不能真跑**的 `ceval`：它是归纳定义的**关系**，
告诉你"存在一棵合法推导树"，但没有给你算法。想用它测试一段程序，只能靠人（或
`apply`）现场构造推导。可是写编译器、写静态分析、写快速原型时，我们真正想要的
是一个**函数** `state -> com -> state`。

本章把这条裂缝补上，办法是**燃料**（fuel，学术名叫 step-indexing）：求值函数
多接一个自然数参数 `i`，每递归一层就烧掉 1 个燃料，烧光了就返回 `None`。这样
递归在语法上是**结构递归**（`i` 逐层变小），`Fixpoint` 接受；语义上它变成一台
"最多跑 i 步"的解释器。然后我们证明两件事：

- **可靠性**（39.8）：只要 `ceval_step st c i = Some st'`，就有 `st =[ c ]=> st'`。
  燃料求值器**不会编造**结果。
- **完备性**（39.10）：只要 `st =[ c ]=> st'`，就**存在**某个 `i` 让 `ceval_step st c i = Some st'`。
  燃料给够，它就**不会漏掉**结果。

两条合起来（39.11）说明：燃料求值器和 `ceval` 关系刻画的是**同一个偏函数**。
这个技巧在后面反复出现——40 章的小步语义求值、47 章 λ 演算的规范化，都要靠它把
"可能不终止"的关系改造成 Coq 里能写的函数。

### 39.1 复用 38 章的语法层与 ceval（自包含副本）

本章示例是自包含的，所以先把 38 章的语言层原样搬过来。文件头：

```coq
(* 39 燃料求值器：把关系变回函数 —— ceval_step 与它和 ceval 的等价性 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex39FuelEvaluation.

(* ---------- 39.1 复用 38 章的语法层与 ceval（自包含副本） ---------- *)
```

注意 `Require` 里比 38 章多了 **`Lia`**：本章的单调性定理（39.9）要处理
`i1 <= i2` 这类算术事实，38 章不需要，这里必须有。原因见坑清单第 11 条。

状态部分与 38 章逐字相同——`total_map`、`t_empty`、`t_update`、两条 `!->` 记号、
`t_update_eq`、`state`：

```coq
Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Definition state := total_map nat.
```

这里值得停一下：`state = string -> nat` 是一个**函数**，不是表格。39.6 里燃料
求值器输出的"最终状态"会因此变得很难比较——这是本章一个真实的技术障碍，见
坑清单第 6 条。

表达式语法与三样抬进机制（`Coercion`、`Declare Custom Entry`、`com_scope`）也
原样保留：

```coq
Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BNeq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BGt (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.

Declare Custom Entry com.
Declare Scope com_scope.
```

`W` 在本章只用来占位（38 章讲过它是"未被任何命令写过的变量"惯例），`X Y Z`
承担实际测试。

自定义条目 `com` 的三条抬进记号 + 表达式记号，照抄 38.3：

```coq
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
Notation "x > y"   := (BGt x y) (in custom com at level 70, no associativity).
Notation "x = y"   := (BEq x y) (in custom com at level 70, no associativity).
Notation "x <> y"  := (BNeq x y) (in custom com at level 70, no associativity).
Notation "x && y"  := (BAnd x y) (in custom com at level 80, left associativity).
Notation "'~' b"   := (BNot b) (in custom com at level 75, right associativity).
```

38 章实测的两条 `'true' / 'false'` 冗余全局记号在这里**继续省略**（rocq 9.3 不
需要它们，见 38.14 坑清单第 1 条）。

接下来一处**顺序上的硬要求**：`Open Scope com_scope.` 必须出现在第一次使用
`<{ }>` 之前。本例把它放在表达式记号之后、`aeval` 之前：

```coq
Open Scope com_scope.

Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | <{a1 + a2}> => (aeval st a1) + (aeval st a2)
  | <{a1 - a2}> => (aeval st a1) - (aeval st a2)
  | <{a1 * a2}> => (aeval st a1) * (aeval st a2)
  end.

Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | <{true}>      => true
  | <{false}>     => false
  | <{a1 = a2}>   => (aeval st a1) =? (aeval st a2)
  | <{a1 <> a2}>  => negb ((aeval st a1) =? (aeval st a2))
  | <{a1 <= a2}>  => (aeval st a1) <=? (aeval st a2)
  | <{a1 > a2}>   => negb ((aeval st a1) <=? (aeval st a2))
  | <{~ b1}>      => negb (beval st b1)
  | <{b1 && b2}>  => andb (beval st b1) (beval st b2)
  end.
```

为什么强调顺序？我第一版把 `Open Scope com_scope.` 写在命令记号之后（也就是
`aeval` 之后），编译立刻失败：

```
File "./ex_39_fuel_evaluation.v", line 90, characters 4-15:
Error: Unknown interpretation for notation "<{ _ }>".
This notation is available in com_scope.
```

报错指向 `aeval` 里的 `<{a1 + a2}>`——记号已经**定义**在 `com_scope` 里，但作用域
没打开，解析器就找不到解释。这条记进了坑清单第 1 条。

状态常量、单键记号、命令语法与五条命令记号也照 38 章：

```coq
Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).

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

`loop` 是本章的反面角色——一个**没有任何燃料能跑完**的程序，39.4 和 39.7 都会
用到它：

```coq
Definition loop : com :=
  <{ while true do
       skip
     end }>.
```

最后是 38 章的大步语义关系，`Reserved Notation` + `Inductive ceval` 七条规则，
它是本章两个等价性定理的右边：

```coq
Reserved Notation
  "st0 '=[' c ']=>' st1"
  (at level 40, c custom com at level 99,
   st0 constr, st1 constr at next level,
   format "'[hv' st0  =[ '/  ' '[' c ']' '/' ]=>  st1 ']'").

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      st =[ skip ]=> st
  | E_Asgn : forall st a n x,
      aeval st a = n ->
      st =[ x := a ]=> (x !-> n ; st)
  | E_Seq : forall c1 c2 st st' st'',
      st  =[ c1 ]=> st'  ->
      st' =[ c2 ]=> st'' ->
      st  =[ c1 ; c2 ]=> st''
  | E_IfTrue : forall st st' b c1 c2,
      beval st b = true ->
      st =[ c1 ]=> st' ->
      st =[ if b then c1 else c2 end ]=> st'
  | E_IfFalse : forall st st' b c1 c2,
      beval st b = false ->
      st =[ c2 ]=> st' ->
      st =[ if b then c1 else c2 end ]=> st'
  | E_WhileFalse : forall b st c,
      beval st b = false ->
      st =[ while b do c end ]=> st
  | E_WhileTrue : forall st st' st'' b c,
      beval st b = true ->
      st  =[ c ]=> st' ->
      st' =[ while b do c end ]=> st'' ->
      st  =[ while b do c end ]=> st''

  where "st0 =[ c ]=> st1" := (ceval c st0 st1).
```

在 repl 里定义这段会多打出两行：

```
ceval is defined
ceval_ind is defined
ceval_sind is defined
```

`ceval_ind` 是**结构归纳**原则（对推导树的构造子归纳，39.8 之外我们 38 章的
`ceval_deterministic` 用的就是它），`ceval_sind` 是 Coq 自动生成的**语义归纳**
原则。`induction H` 时 Coq 选哪个，取决于它能否为每个构造子生成足够的 IH；如果
你怀疑选错，可以显式 `induction H using ceval_sind.`。这条进了坑清单第 10 条。

### 39.2 不终止的代价：一个灾难性的伪证明

在写燃料之前，先看看"不写燃料"会发生什么最坏的事。Coq 的一致性建立在"每个
`Fixpoint` 都终止"上，所以它**不允许**你写出非终止的递归——但允许你写出
"看起来像递归、其实 principal argument 没变小"的东西，只要它拒绝接受。试试
用 `nat` 当燃料但不做结构递归：

```coq
(* ---------- 39.2 不终止的代价：一个灾难性的伪证明 ---------- *)

Fail Fixpoint loop_false (n : nat) : False := loop_false n.
```

`rocq compile -q` 对 `Fail` 完全静默；在 repl 里跑 `full39.v` 才拿得到真实报错：

```
The command has indeed failed with message:
Recursive definition of loop_false is ill-formed.
In environment
loop_false : nat -> False
n : nat
Recursive call to loop_false has principal argument equal to 
"n" instead of a subterm of "n".
Recursive definition is: "fun n : nat => loop_false n".
```

关键词是 **subterm（子项）**：`loop_false n` 的参数是 `n` 本身，不是 `n` 的子项
（`S n'` 里的 `n'` 才是）。所以 Coq 看不出递减。这个报错文本是本章最有用的一
课——**燃料必须真的变小**。下面每一版 `ceval_step*` 都靠"把 `S i'` 拆出来的
`i'` 传给递归调用"来通过检查，而不是靠 `i - 1` 这种写法。

（顺带：如果真写成 `loop_false (n - 1)`，Coq 会接受吗？不会——`nat` 减法的结果
不是 `n` 的 syntactic 子项，guardedness 检查是纯语法判断。这条见坑清单第 9 条。）

### 39.3 没有燃料的第一版：ceval_step1

38.7 的 `ceval_fun_no_while` 是"把 while 直接当 skip"。这里换个写法，把结论
说清楚：**结构性递归是照命令语法树的递归**，所以 repl 报的守护参数是**第 2 个
参数**（`c`），跟燃料无关：

```coq
(* ---------- 39.3 没有燃料的第一版 ---------- *)

Fixpoint ceval_step1 (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ l := a1 }> => (l !-> aeval st a1 ; st)
  | <{ c1 ; c2 }> =>
      let st' := ceval_step1 st c1 in
      ceval_step1 st' c2
  | <{ if b then c1 else c2 end }> =>
      if (beval st b)
        then ceval_step1 st c1
        else ceval_step1 st c2
  | <{ while b1 do c1 end }> => st
  end.
```

repl 输出：

```
ceval_step1 is defined
ceval_step1 is recursively defined (guarded on 2nd argument)
```

三点读法：

- `l := a1` 里的 `l` 不是笔误。38 章的构造子是 `CAsgn (x : string) (a : aexp)`，
  但抬进记号 `"x" := x (in custom com at level 0, x constr at level 0)` 会让模式里
  的 `x` 与 `Coercion` 打架，LF 原文一律用 `l`、`a1`、`b1` 这类避开 `x` 的名字。
  这是 LF 代码风格的真实原因之一，坑清单第 8 条。
- `while` 分支返回 `st`：它把"循环可能不结束"和"循环一次都不执行"**合并**成同
  一种行为。这就是 38 章 `ceval_fun_no_while_bogus` 那个荒谬 Example 的来源。
- `;` 分支写成 `let st' := ... in ...`，是为了让下一版的燃料分配意图清楚。

### 39.4 第一版燃料：跑光就退回空状态

给 `ceval_step1` 加一个自然数参数，最直觉的做法是"没燃料就当空状态"：

```coq
(* ---------- 39.4 第一版燃料：跑光就退回空状态 ---------- *)

Fixpoint ceval_step2 (st : state) (c : com) (i : nat) : state :=
  match i with
  | O => empty_st
  | S i' =>
    match c with
    | <{ skip }> => st
    | <{ l := a1 }> => (l !-> aeval st a1 ; st)
    | <{ c1 ; c2 }> =>
        let st' := ceval_step2 st c1 i' in
        ceval_step2 st' c2 i'
    | <{ if b then c1 else c2 end }> =>
        if (beval st b)
          then ceval_step2 st c1 i'
          else ceval_step2 st c2 i'
    | <{ while b1 do c1 end }> =>
        if (beval st b1)
        then let st' := ceval_step2 st c1 i' in
             ceval_step2 st' c i'
        else st
    end
  end.
```

现在递归**同时**看两个参数：repl 报

```
ceval_step2 is defined
ceval_step2 is recursively defined (guarded on 3rd argument)
```

也就是说 Coq 选了 `i` 作为守护参数（`match i with O => ... | S i' => ...` 是最外层
的 match，且所有递归调用都传 `i'`）。`c` 不再需要递减——**这就是燃料的全部魔力**：
即使 `ceval_step2 st' c i'` 里的 `c` 就是整个 `while`（比原来还大），只要 `i` 变小，
`Fixpoint` 就接受。

`while` 分支里那句 `ceval_step2 st' c i'` 的 `c` 指的是 `ceval_step2` 自己的命令
参数（因为我们在 `while` 分支里，它恰好等于 `CWhile b1 c1`）。这个"名字复用"
读起来别扭，但是 LF 的写法，它让递归调用的目标和 39.8 的 `E_WhileTrue` 一一对应。

三个反例说明这版为什么不能用：

```coq
Example step2_zero_fuel :
  ceval_step2 (X !-> 5) <{ skip }> 0 = empty_st.
Proof. reflexivity. Qed.

Example step2_loop_zero :
  ceval_step2 empty_st loop 0 X = 0.
Proof. reflexivity. Qed.

Example step2_loop_ignores_fuel :
  ceval_step2 (X !-> 5) loop 3 = ceval_step2 (X !-> 5) loop 4.
Proof. reflexivity. Qed.
```

- `step2_zero_fuel`：`skip` 明明是可以立即完成的命令，燃料 0 却把它变成 `empty_st`。
  **燃料耗尽的默认值和"成功"混在一起了。**
- `step2_loop_zero`：想看得更清楚一点——初始 `X` 是 5，跑完读回来是 0。信息被
  静默丢弃。
- `step2_loop_ignores_fuel`：给 3 格燃料和给 4 格燃料，`loop` 的"结果"完全相同
  （都是 `empty_st`）。也就是说这版函数**无法区分"跑不完"和"跑完了"**——它总是
  给你一个像成功一样的答案。这是最危险的失败模式：静态地看，你无法知道返回值
  是不是编的。

### 39.5 用 option 区分正常与异常终止

修法是把返回类型换成 `option state`：`None` 表示"燃料不够"，`Some st'` 表示
"在 i 步内确定它终止于 `st'`"。

```coq
(* ---------- 39.5 用 option 区分正常与异常终止 ---------- *)

Fixpoint ceval_step3 (st : state) (c : com) (i : nat)
                    : option state :=
  match i with
  | O => None
  | S i' =>
    match c with
    | <{ skip }> => Some st
    | <{ l := a1 }> => Some (l !-> aeval st a1 ; st)
    | <{ c1 ; c2 }> =>
        match (ceval_step3 st c1 i') with
        | Some st' => ceval_step3 st' c2 i'
        | None => None
        end
    | <{ if b then c1 else c2 end }> =>
        if (beval st b)
          then ceval_step3 st c1 i'
          else ceval_step3 st c2 i'
    | <{ while b1 do c1 end }> =>
        if (beval st b1)
        then match (ceval_step3 st c1 i') with
             | Some st' => ceval_step3 st' c i'
             | None => None
             end
        else Some st
    end
  end.
```

对照 39.4，三处语义变好了：

- `O => None`：不再伪造状态，直接承认"我算不出来"。
- `;` 分支：`c1` 跑光燃料，整条序列就是 `None`——**失败沿结构向外传播**，这正是
  `option` monad 的行为。
- `while` 分支的 `else Some st`：条件为假时循环正常结束，返回原状态，与
  `E_WhileFalse` 对齐。

repl 仍报 `ceval_step3 is recursively defined (guarded on 3rd argument)`。

`match ... with Some st' => ... | None => None end` 这个模式在 `;` 和 `while` 里
各出现一次，加上缩进很难读。下一节把它做成记号。

### 39.6 LETOPT 记号与最终版 ceval_step

```coq
(* ---------- 39.6 LETOPT 记号与最终版 ceval_step ---------- *)

Notation "'LETOPT' x <== e1 'IN' e2"
   := (match e1 with
         | Some x => e2
         | None => None
       end)
   (right associativity, at level 60).
```

逐条拆解：

- 展开体是 `match e1 with Some x => e2 | None => None end`：`x` 是**模式里的绑定
  变量**，所以 `LETOPT st' <== e1 IN e2` 里的 `st'` 只在 `e2` 中生效。记号定义允许
  在 RHS 的模式位置放变量，这是它和普通 `Notation "a := b"` 的最大区别。
- `right associativity`：`LETOPT a <== e1 IN LETOPT b <== e2 IN e3` 自然右折。
- `at level 60`：落在 38 章那个 level 阶梯的"比较 70 / 加减 50"之间，正好是语句级
  绑定的位置。
- 引号包住的 `'LETOPT'`、`'IN'` 变成保留词。repl 明确打印：

```
Identifier 'LETOPT' now a keyword
Identifier 'IN' now a keyword
```

`IN` 是个常用词（`List.In`、`setoid` 里都有），把它变成关键字会影响后续加载的库
或记号，这是 LF 这段代码在现代 Coq 项目里要格外小心的地方，坑清单第 7 条。

最终版求值器：

```coq
Fixpoint ceval_step (st : state) (c : com) (i : nat)
                    : option state :=
  match i with
  | O => None
  | S i' =>
    match c with
    | <{ skip }> => Some st
    | <{ l := a1 }> => Some (l !-> aeval st a1 ; st)
    | <{ c1 ; c2 }> =>
        LETOPT st' <== ceval_step st c1 i' IN
        ceval_step st' c2 i'
    | <{ if b then c1 else c2 end }> =>
        if (beval st b)
          then ceval_step st c1 i'
          else ceval_step st c2 i'
    | <{ while b1 do c1 end }> =>
        if (beval st b1)
        then LETOPT st' <== ceval_step st c1 i' IN
             ceval_step st' c i'
        else Some st
    end
  end.
```

现在读它，最好的方式是一路对照 38 章的七条规则：

| `ceval_step` 分支 | 对应 `ceval` 构造子 | 燃料花在哪 |
|---|---|---|
| `skip => Some st` | `E_Skip` | 1（只为了进 `S i'` 分支） |
| `l := a1 => Some (...)` | `E_Asgn` | 1 |
| `c1 ; c2` | `E_Seq` | `c1` 和 `c2` 各 `i'` |
| `if ... then ... else ...` | `E_IfTrue` / `E_IfFalse` | 选中的那支 `i'` |
| `while` 且条件假 | `E_WhileFalse` | 1 |
| `while` 且条件真 | `E_WhileTrue` | 体 `i'` + 整个 while `i'` |

关键观察：**赋值和 skip 不消耗递归燃料**，它们只需要 `i >= 1`。而 `while` 每迭代
一轮，可用燃料减 1。所以 `fuel k` 的 while 最多跑 `k - 1` 轮。

四个实测例子（数字全部是 `reflexivity` 过的，不是我推出来的）：

```coq
Example fuel_seq_short :
  ceval_step empty_st <{ X := 1 ; Y := 2 ; Z := 3 }> 2 = None.
Proof. reflexivity. Qed.

Example fuel_seq_enough :
  ceval_step empty_st <{ X := 1 ; Y := 2 ; Z := 3 }> 3
  = Some (Z !-> 3 ; Y !-> 2 ; X !-> 1).
Proof. reflexivity. Qed.

Example fuel_while_short :
  ceval_step (X !-> 3) <{ while X <> 0 do X := X - 1 end }> 3 = None.
Proof. reflexivity. Qed.

Example fuel_while_enough :
  ceval_step (X !-> 3) <{ while X <> 0 do X := X - 1 end }> 4
  = Some (X !-> 0 ; X !-> 1 ; X !-> 2 ; X !-> 3).
Proof. reflexivity. Qed.
```

`fuel_seq_*`：三条命令的序列，`ceval_step` 处理 `;` 时把 `i'` 分给左右两边（不是
`i'-1` 再减），所以 `X:=1 ; Y:=2 ; Z:=3` 需要 `S (S (S 0)) = 3` 格燃料，给 2 格就
`None`。

`fuel_while_*`：`X` 从 3 递减到 0 要 3 轮，每轮耗 1 格（第 4 轮进入时条件为假，
也要 1 格才能"看到"条件为假），所以恰好 4 格。给 3 格 → `None`。

**为什么右边不是 `Some (X !-> 0)`？** 因为 `state` 是函数，赋值是**在旧函数外面
再包一层 `t_update`**，历史不会消失。真实结果是 4 层 `t_update`：最外层 `X !-> 0`，
往里依次是 `X !-> 1`、`X !-> 2`、`X !-> 3`。我一开始写 `= Some (X !-> 0)`，编译器
直接拒绝：

```
Error: Unable to unify "Some (X !-> 0)" with
 "ceval_step (X !-> 3) <{while X <> 0 do
                           X := X - 1
                         end}> 4".
```

`X !-> 0` 展开是 `t_update empty_st X 0`，`X !-> 0 ; X !-> 1 ; X !-> 2 ; X !-> 3` 展开
是四层嵌套。两个函数**外延相等**（对任意键返回相同 nat），但 `reflexivity` 只做
**转换检查**（conversion），不会用函数外延公理。这解释了 39.7 里 LF 为什么要把结果
投影成元组。

### 39.7 test_ceval：把结果折成人能看的三元组

```coq
(* ---------- 39.7 test_ceval：把结果折成人能看的三元组 ---------- *)

Definition test_ceval (st : state) (c : com) :=
  match ceval_step st c 500 with
  | None    => None
  | Some st' => Some (st' X, st' Y, st' Z)
  end.
```

两件事同时解决了：给定一个"足够大"的燃料 `500`（写死的经验值），再把不可比较的
`state` 折叠成可比较的 `nat * nat * nat`——只读 `X, Y, Z` 三个键。注意 `Some st'`
这个名字：不要复用 `st` 当模式变量，那会把外层参数 `st` 遮掉，读起来像 bug（我
第一版就这么写的，虽然能过编译，坑清单第 12 条）。

```coq
Example example_test_ceval :
  test_ceval empty_st
    <{ X := 2;
       if (X <= 1)
       then Y := 3
       else Z := 4
       end }>
  = Some (2, 0, 4).
Proof. reflexivity. Qed.

Example test_ceval_diverges :
  test_ceval empty_st loop = None.
Proof. reflexivity. Qed.
```

第一个正是 38.10 里手推 `ceval_example1` 的那段程序：当时我们要写
`apply E_Seq with (X !-> 2)` 之类的中间状态，现在一行 `reflexivity` 就验证完。这
就是燃料求值器的实用价值——**它把证明降级成计算**。

第二个说明 `loop` 真的跑不完：500 格燃料下 `ceval_step` 返回 `None`，而不是某个
假状态。对比 39.4 的 `step2_loop_ignores_fuel`，这是质的改进。

一个稍长的循环：

```coq
Definition pup_to_n : com :=
  <{ while X <> 0 do
       Y := Y + X;
       X := X - 1
     end }>.

Example pup_to_n_1 :
  test_ceval (X !-> 5) pup_to_n = Some (0, 15, 0).
Proof. reflexivity. Qed.

Example pup_to_n_0 :
  test_ceval (X !-> 0) pup_to_n = Some (0, 0, 0).
Proof. reflexivity. Qed.
```

`pup_to_n` 每轮先做两条赋值（`Y := Y + X` 和 `X := X - 1`），再回到 while 头。
`X=5` 时 `Y = 5+4+3+2+1 = 15`。`pup_to_n_0` 是边界：条件一开始就假，一次都不进
循环体，三个变量全 0——它验证的是 `E_WhileFalse` 这条路。

（原书把这个 `pup_to_n` 留作练习，让你先写 `ceval` 推导、再用 `test_ceval` 验证。
这里我们直接用它当"能跑通的例子"，因为本章的重点是 39.8–39.10 的三个定理。）

### 39.8 可靠性：燃料求值能推出的，关系也能推出

```coq
(* ---------- 39.8 可靠性：燃料求值能推出的，关系也能推出 ---------- *)

Theorem ceval_step__ceval : forall c st st',
  (exists i, ceval_step st c i = Some st') ->
  st =[ c ]=> st'.
Proof.
  intros c st st' H.
  inversion H as [i E].
  clear H.
```

`inversion H as [i E]`：`H : exists i, ...`，inversion 直接把见证 `i` 和等式
`E : ceval_step st c i = Some st'` 拿出来。`clear H` 之后，`i` 是唯一的归纳对象。

```coq
  generalize dependent st'.
  generalize dependent st.
  generalize dependent c.
  induction i as [| i'].
```

三次 `generalize dependent` 的顺序很有讲究，正好是归纳目标的**反方向**阅读：
最后 generalize 的 `c` 出现在 `forall c st st', ...` 最左边。为什么必须 generalize？
因为 `st`、`st'` 都由 `c` 和 `i` 决定，如果它们留在上下文里被固定住，IH 就弱得
没法用（`ceval_step st' c i' = Some st''` 里的 `st'` 在 while 分支必须能变）。
38 章讲 `generalize dependent` 时的口诀在这里再次生效：**"IH 里需要自由的东西，
归纳前必须先 revert。"**

```coq
  - (* i = 0 -- 矛盾：ceval_step 在 O 上返回 None *)
    intros c st st' H. discriminate H.
```

零燃料分支：`ceval_step st c 0` 按定义就是 `None`，而 `H : None = Some st'`，
`discriminate` 一步解决。这里 `H` 是重新 `intros` 出来的、针对零燃料形状的那个
假设，不是外层那个存在性假设（后者已经 `clear`）。

```coq
  - (* i = S i' *)
    intros c st st' H.
    destruct c;
           simpl in H; inversion H; subst; clear H.
```

这一行是整章最密的战术串。`destruct c` 把命令的 5 个构造子分开；对每一支，
`simpl in H` 把 `ceval_step st c (S i')` 展开到构造子对应的那个 `match` 上，
`inversion H; subst` 读出 `st'` 的真实形状并把等式代入。

注意 `destruct c` 之后**没有用 `;` 分派 bullet**——`destruct c; tac` 让 5 支各自
被 `simpl/inversion/subst/clear` 收拾干净，然后才允许写 bullet。这个写法和 LF
原文一致，也保证了每支的假设名可以统一用 `c1`、`b`、`st'`。

```coq
    + (* skip *)
      apply E_Skip.
    + (* := *)
      apply E_Asgn. reflexivity.
```

`apply E_Asgn.` 留下一个子目标 `aeval st a = n`——注意这里 `n` 是 `inversion`
从 `Some (l !-> aeval st a1 ; st)` 里读出来的那个中间值，`reflexivity` 直接通过。

```coq
    + (* ; *)
      destruct (ceval_step st c1 i') eqn:Heqr1.
      * (* c1 正常结束 *)
        apply E_Seq with s.
          apply IHi'. rewrite Heqr1. reflexivity.
          apply IHi'. assumption.
      * (* c1 跑光燃料：与 H 矛盾 *)
        discriminate H1.
```

`destruct ... eqn:Heqr1` 是对"第一段的结果"做案例分析：

- `Some s` 情形：`Heqr1 : ceval_step st c1 i' = Some s`，同时 `H`（已被 inversion
  变成 `Some s 的继续计算 = Some st'` 的形状）给出 `ceval_step s c2 i' = Some st'`。
  `apply E_Seq with s.` 显式提供**中间状态** `s`——这是 `ceval` 关系证明里最常用的
  战术，38.10 已经用过。剩下两个子目标分别用 `IHi'` 加 `Heqr1`、`IHi'` 加 `H1`。
- `None` 情形：`H1 : ceval_step st c1 i' = None`（`eqn:` 生成的），而 `H` 化简后
  是 `None = Some st'`，`discriminate H1`… 实际上真正被 discriminate 的是 `H`
  那条不可能等式，`H1` 只是同一环境的产物；LF 原文就这么写，编译通过。

这里必须说清 **bullet 的层级**：本层从 `-`（`i = S i'`）进到 `+`（`destruct c` 的
5 支）再进到 `*`（`destruct ... eqn:` 的 2 支）。在 `*` 内部**不能**再回头用 `+`
去标 `E_Seq` 的两个子目标——我第一次改写时正是这么干的，编译直接报错：

```
Error: [Focus] Wrong bullet +: Current bullet * is not finished.
```

正确的做法是不加 bullet，靠 Coq 的**自动聚焦**：`apply E_Seq with s.` 产生两个
子目标，第一个被 `apply IHi'. rewrite Heqr1. reflexivity.` 三连关闭后焦点自动跳到
第二个，于是 `apply IHi'. assumption.` 收拾它。前提是每支都写到"完全关闭"。
这条记进坑清单第 2 条。

```coq
    + (* if *)
      destruct (beval st b) eqn:Heqr.
      * (* 条件为真 *)
        apply E_IfTrue. rewrite Heqr. reflexivity.
        apply IHi'. assumption.
      * (* 条件为假 *)
        apply E_IfFalse. rewrite Heqr. reflexivity.
        apply IHi'. assumption.
```

`beval st b` 只有 `true/false` 两种，`eqn:Heqr` 记下等式。`apply E_IfTrue.` 产生
两个子目标：`beval st b = true` 和 `st =[ c1 ]=> st'`。第一个用
`rewrite Heqr. reflexivity.` 把 `beval st b` 换成 `true`（注意方向：`Heqr` 是
`beval st b = <分析出的那个构造>`，rewrite 之后目标是字面量，reflexivity 过）。
第二个用 `IHi'` 加 `assumption`。这一支的两行连写同 39.8 的 `;` 支，是自动聚焦。

```coq
    + (* while *)
      destruct (beval st b) eqn:Heqr.
      * (* 条件为真：跑一遍体，再跑整个 while *)
        destruct (ceval_step st c i') eqn:Heqr1.
        { (* 体正常结束 *)
          apply E_WhileTrue with s. rewrite Heqr.
          reflexivity.
          apply IHi'. rewrite Heqr1. reflexivity.
          apply IHi'. assumption. }
        { (* 体跑光燃料：与 H 矛盾 *)
          discriminate H1. }
      * (* 条件为假：原地结束 *)
        injection H1 as H2. rewrite <- H2.
        apply E_WhileFalse. apply Heqr.
```

`while` 分支是本章最难的：这里 `ceval_step` 递归调用时用的命令参数**还是整个
while**（`ceval_step st' c i'`），所以两个子目标都要用同一个 `IHi'`——一个用于体，
一个用于递归的整个循环。`E_WhileTrue with s` 给出三个子目标：条件真、体的推导、
剩余循环的推导；顺序就是 `rewrite Heqr. reflexivity.` / `apply IHi'. rewrite Heqr1.
reflexivity.` / `apply IHi'. assumption.`。

我用 `{ ... }` 而不是 `-- ... -- ...` 来分 `destruct (ceval_step ...)` 的两支，因为
此处已经在 `*` 层，再深一层写 `--` 也行，但 `{}` 与外层 bullet 系统解耦，更不容易
踩到上一个坑。

条件为假的最后一支用了两个新战术：

- `injection H1 as H2`：`H1 : Some st = Some st'`（inversion 后残留的形状），
  `injection` 抽出参数相等 `st = st'`，命名为 `H2`。
- `rewrite <- H2`：**从右往左**重写，把目标里的 `st'` 换成 `st`，目标变成
  `st =[ while b do c end ]=> st`，正好是 `E_WhileFalse`。
- `apply E_WhileFalse. apply Heqr.`：最后一个子目标 `beval st b = false`，
  `Heqr` 就是这个等式本身，所以 `apply`（等价于 `exact`）关闭。

```coq
Qed.
```

结论：只要某个燃料值给出了 `Some st'`，`ceval` 里就有一棵真推导树。燃料器
**不会把没发生的事情算成发生了**。

### 39.9 单调性：燃料只多不少

完备性需要"多给燃料不会改变已有结果"。这条看起来显然，但它是本章**唯一需要
算术**的地方，所以 39.1 要 `Require Lia`。

```coq
(* ---------- 39.9 单调性：燃料只多不少 ---------- *)

Theorem ceval_step_more : forall i1 i2 st st' c,
  i1 <= i2 ->
  ceval_step st c i1 = Some st' ->
  ceval_step st c i2 = Some st'.
Proof.
  induction i1 as [|i1']; intros i2 st st' c Hle Hceval.
```

注意顺序：`induction i1` 在 `intros` **之前**。因为量词是 `forall i1 i2 st st' c`，
`i2` 依赖 `i1` 吗？不依赖，但如果先 `intros` 全部再 `induction i1`，`i2 st st' c`
会被固化，IH 就成了 `ceval_step st c i1' = Some st' -> ceval_step st c i2 = Some st'`
——`i2` 被钉死，而 we需要它对任意 `i2` 成立。所以**先归纳、后 intro**，IH 自动是
`forall i2 st st' c, ...`，正好能用 `IHi1' i2'`  instantiate。这是
`generalize dependent` 那套纪律的另一种写法，坑清单第 3 条。

```coq
  - (* i1 = 0 *)
    simpl in Hceval. discriminate Hceval.
  - (* i1 = S i1' *)
    destruct i2 as [|i2']. inversion Hle.
    assert (Hle' : i1' <= i2') by lia.
```

`i1 = 0` 分支：`ceval_step st c 0 = Some st'` 化简为 `None = Some st'`，矛盾。
`i1 = S i1'` 分支先 case 分析 `i2`：`i2 = 0` 时 `Hle : S i1' <= 0`，`inversion Hle`
直接关闭这一支；剩下 `i2 = S i2'`，用 `lia` 从 `S i1' <= S i2'` 得到
`Hle' : i1' <= i2'`——这就是 IH 需要的燃料前提。

`assert ... by lia.` 是 `assert (H : P) : ... Proof. lia. Qed.` 的紧凑写法；没有
`Require Lia` 时这里会报 `Unknown procedure: lia`。

```coq
    destruct c.
    + (* skip *)
      simpl in Hceval. inversion Hceval. reflexivity.
    + (* := *)
      simpl in Hceval. inversion Hceval. reflexivity.
```

`skip` 与赋值两支的**共同点**：结果与燃料无关（只要 ≥1），所以两边都直接
化简到同一个 `Some (...)`，`reflexivity` 就能过。`inversion Hceval` 在这里的作用
是把 `st'` 的形状对齐。

```coq
    + (* ; *)
      simpl in Hceval. simpl.
      destruct (ceval_step st c1 i1') eqn:Heqst1'o.
      * (* c1 正常结束 *)
        apply (IHi1' i2') in Heqst1'o; try assumption.
        rewrite Heqst1'o.
        apply (IHi1' i2') in Hceval; try assumption.
      * (* c1 跑光燃料 *)
        discriminate Hceval.
```

`apply (IHi1' i2') in Heqst1'o` 是**反向使用** IH：把 IH 当成"能把等式升级"的规则
作用在假设上。`IHi1' i2' : forall st st' c, i1' <= i2' -> ceval_step st c i1' = Some st' ->
ceval_step st c i2' = Some st'`，`apply ... in` 会统一结论部分，把
`Heqst1'o : ceval_step st c1 i1' = Some s` 改写成 `ceval_step st c1 (i1' + ... )`?
不——它改写成 `ceval_step st c1 i2' = Some s`。统一过程中留下的两个前提
（`i1' <= i2'` 和原等式）变成新目标，用 `; try assumption` 就地消掉：`Hle'` 和
`Heqst1'o` 自己都在上下文里。这个 `apply ... in ... ; try assumption.` 组合是
LF 这段证明的核心手法。

`if` 支最紧凑：

```coq
    + (* if *)
      simpl in Hceval. simpl.
      destruct (beval st b); apply (IHi1' i2') in Hceval;
        assumption.
```

`destruct` 的两支目标形状相同（只是 `c1`/`c2` 不同），所以用 `;` 把同一串战术
打到两支上。

```coq
    + (* while *)
      simpl in Hceval. simpl.
      destruct (beval st b); try assumption.
      destruct (ceval_step st c i1') eqn:Heqst1'o.
      * (* 体正常结束 *)
        apply (IHi1' i2') in Heqst1'o; try assumption.
        rewrite Heqst1'o.
        apply (IHi1' i2') in Hceval; try assumption.
      * (* 体跑光燃料 *)
        discriminate Hceval.
```

`destruct (beval st b); try assumption.`：条件为假那一支，两边都返回 `Some st`，
`try assumption` 直接解决；为真那一支没有假设可用，`try` 静默失败，继续往下走。
用 `try` 而不是直接 `assumption`，就是为了"一支能解、另一支不报错"。

后面的两次 `apply (IHi1' i2') in ...` 用法和 `;` 支**完全对称**：一次给循环体
升级燃料，一次把整个循环的递归结果升级——注意后者的命令参数是 `c`，而这里 `c`
正是 `ceval_step st c i1` 里那个 `CWhile b c_body`。同一个 `c`，所以 IH 适用。

```coq
Qed.
```

### 39.10 完备性：关系能推出的，足够燃料也能推出

原书把这一定理留作练习（`ceval__ceval_step`），这里给出完整证明。思路是**对推导
树归纳**——每读到一条 `ceval` 规则，就构造出足以完成它的燃料量：

```coq
(* ---------- 39.10 完备性：关系能推出的，足够燃料也能推出 ---------- *)

Theorem ceval__ceval_step : forall c st st',
  st =[ c ]=> st' ->
  exists i, ceval_step st c i = Some st'.
Proof.
  intros c st st' Hce.
  induction Hce.
  - (* E_Skip *)
    exists 1. reflexivity.
  - (* E_Asgn *)
    exists 1. rewrite <- H. reflexivity.
```

`induction Hce` 是对归纳命题 `ceval` 的推导做归纳，7 条规则给 7 个子目标，IH 名字
自动是 `IHHce`（单个前提）或 `IHHce1 / IHHce2`（多个前提）。

`E_Skip` 给 1 格燃料就够。`E_Asgn` 也只需 1 格，但这里有个真实的坑：`reflexivity`
单独用**过不了**，报错是

```
Error: Unable to unify "Some (x !-> n; st)" with "ceval_step st <{x := a}> 1".
```

因为 `ceval_step st <{x := a}> 1` 算出来是 `Some (x !-> aeval st a ; st)`，而
`aeval st a` 是个**表达式**，`n` 是它的**值**——两者只在有假设
`H : aeval st a = n` 时才相等，`reflexivity` 不会自己去用假设。所以要先
`rewrite <- H`：把 `aeval st a` 替换成 `n`（方向是 `<-`，因为 `H` 写成
`aeval st a = n`，从右往左rewrite 才是把表达式换成值）。这条记进坑清单第 4 条。

```coq
  - (* E_Seq *)
    destruct IHHce1 as [i1 Hi1].
    destruct IHHce2 as [i2 Hi2].
    exists (S (i1 + i2)).
    simpl.
    rewrite (ceval_step_more i1 (i1 + i2) st st' c1
                             (Nat.le_add_r i1 i2) Hi1).
    rewrite (ceval_step_more i2 (i1 + i2) st' st'' c2
                             (Nat.le_add_l i2 i1) Hi2).
    reflexivity.
```

这是全章信息量最大的一段。四个要点：

1. **燃料取 `S (i1 + i2)`**。`ceval_step` 处理 `c1 ; c2` 时，把 `S i` 的 `i'` 同时给
   `c1` 和 `c2`（看 39.6 的定义：两次递归都传 `i'`）。所以要两段都能跑完，得让
   `i' >= i1` 且 `i' >= i2`，取 `i' = i1 + i2` 即可（LF 就是取 `S (i1 + i2)`，
   `max i1 i2` 也行，只是要多两条引理）。
2. **`simpl` 必须在 `rewrite` 之前**。目标一开始是
   `ceval_step st <{c1; c2}> (S (i1 + i2)) = Some st''`，里面**没有**
   `ceval_step st c1 (i1 + i2)` 这个子项。`simpl` 展开一层，把 `S (i1+i2)` 的
   `i'` 绑定解析出来，子项才出现。我第一版按"先 rewrite 再 simpl"的顺序写，
   编译器立刻：

```
Error: Found no subterm matching "ceval_step st c1 (i1 + i2)"
in the current goal.
```

   坑清单第 5 条。
3. **`rewrite (ceval_step_more ... )` 用定理当重写规则**。`ceval_step_more` 的结论
   是等式，所以可以直接 `rewrite`；前提 `i1 <= i1 + i2` 由
   `Nat.le_add_r : n <= n + m` 提供，`i2 <= i1 + i2` 由 `Nat.le_add_l : n <= m + n`
   提供——注意两条引理的**参数顺序**不同：`le_add_r` 是"自己+别人"，`le_add_l`
   是"别人+自己"，所以第二个 rewrite 写的是 `(Nat.le_add_l i2 i1)`（`i2 <= i1 + i2`）。
   写成 `Nat.le_add_l i1 i2` 会得到 `i1 <= i2 + i1`，类型不匹配。
4. `reflexivity` 收尾。两次 rewrite 之后左边已经是
   `match Some st' with Some s => Some st'' | None => None end` 这种形态，`reflexivity`
   做完整转换检查，`match` 的 ι-规约和 `if` 的规约它都会跑。

```coq
  - (* E_IfTrue *)
    destruct IHHce as [i Hi].
    exists (S i).
    simpl. rewrite H.
    apply Hi.
  - (* E_IfFalse *)
    destruct IHHce as [i Hi].
    exists (S i).
    simpl. rewrite H.
    apply Hi.
```

`if` 两支同形：`S i` 是因为进入分支本身消耗 1 格；`simpl` 后目标里有
`if beval st b then ceval_step st c1 i else ...`，`rewrite H`（`H : beval st b = true`）
把条件换成 `true`；`apply Hi` 关闭剩下的等式目标（`Hi` 的类型正好就是目标）。

```coq
  - (* E_WhileFalse *)
    exists 1.
    simpl. rewrite H. reflexivity.
```

条件为假时**不需要循环体的燃料**，1 格足够：`simpl` 得
`if beval st b then ... else Some st`，`rewrite H`（`H : beval st b = false`）
让 `reflexivity` 通过——此时 `if false then ? else Some st` 与 `Some st` 转换相等。

```coq
  - (* E_WhileTrue *)
    destruct IHHce1 as [i1 Hi1].
    destruct IHHce2 as [i2 Hi2].
    exists (S (i1 + i2)).
    simpl. rewrite H.
    rewrite (ceval_step_more i1 (i1 + i2) st st' c
                             (Nat.le_add_r i1 i2) Hi1).
    rewrite (ceval_step_more i2 (i1 + i2) st' st'' (CWhile b c)
                             (Nat.le_add_l i2 i1) Hi2).
    reflexivity.
Qed.
```

和 `E_Seq` 同构，两点差别：

- 先 `rewrite H`（条件为真），再升级两段燃料。
- 第二个 rewrite 的命令参数必须写成 **`CWhile b c`**（整个循环），因为
  `ceval_step` 的 while 分支递归调用的对象是循环本身，而不是体 `c`。
  这里显式写出构造子名而不是用 `<{ while b do c end }>` 记号，是刻意的：
  在 goal 里 `simpl` 之后的项就是 `CWhile b c`，写记号需要作用域匹配，
  写构造子最稳。

结论：`ceval` 里的每一棵推导树，都能算出一个"燃料上界"。

### 39.11 两个方向合起来：偏函数的另一种刻画

```coq
(* ---------- 39.11 两个方向合起来：偏函数的另一种刻画 ---------- *)

Theorem ceval_and_ceval_step_coincide : forall c st st',
  st =[ c ]=> st'
  <-> exists i, ceval_step st c i = Some st'.
Proof.
  intros c st st'.
  split.
  - apply ceval__ceval_step.
  - apply ceval_step__ceval.
Qed.
```

读法：`st =[ c ]=> st'` 这个命题**等价于**"存在某个燃料值让解释器给出 `Some st'`"。
这就是"偏函数"的两种刻画：归纳关系版（可证明、可推理）和燃料函数版（可计算、
可 `reflexivity`）。注意 `exists i` 的存在性——它不是"对任意足够大的 i"，因为
`i = 0` 或燃料不足时会返回 `None`；`None` 里没有 `st'`。

### 39.12 确定性的第二种证明：搬到函数上去

38.11 用推导归纳 + `inversion` 证了 `ceval` 的确定性，十几个子目标。既然
求值器和关系等价，确定性可以直接从"函数不会返回两个值"搬过来：

```coq
(* ---------- 39.12 确定性的第二种证明：搬到函数上去 ---------- *)

Theorem ceval_deterministic' : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 He1 He2.
  apply ceval__ceval_step in He1.
  apply ceval__ceval_step in He2.
  inversion He1 as [i1 E1].
  inversion He2 as [i2 E2].
  apply ceval_step_more with (i2 := i1 + i2) in E1.
  apply ceval_step_more with (i2 := i1 + i2) in E2.
  rewrite E1 in E2. inversion E2. reflexivity.
  - lia.
  - lia.
Qed.
```

八行战术，逻辑链条是：

1. 两个推导换成两个燃料见证 `i1`、`i2`。
2. `ceval_step st c i1 = Some st1` 和 `ceval_step st c i2 = Some st2` 各自升级到
   公共燃料 `i1 + i2`（`apply ... with (i2 := ...) in ...`：只命名要统一的那个
   隐式参数，剩下的做统一；产生的前提 `i1 <= i1 + i2`、`i2 <= i1 + i2` 变成两个
   子目标，各由 `lia` 关闭）。
3. 于是 `ceval_step st c (i1+i2)` 同时等于 `Some st1` 和 `Some st2`：
   `rewrite E1 in E2` 把 `E2` 左边的项换成 `Some st1`，`inversion E2` 抽出
   `st1 = st2`，`reflexivity` 收尾。

这就是"把难点搬到函数上"的红利：函数单值性是**计算性质**，比推导树的
case 分析省掉一整层归纳。

```coq
Print Assumptions ceval_deterministic'.
```

repl 里打印：

```
Closed under the global context
```

和 38.11 一样，没有依赖任何公理（`funext`、`propext`、`ClassicalChoice` 一个都没用）。

```coq
End Ex39FuelEvaluation.
```

### 39.13 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或真实观测到。

1. **`Open Scope com_scope.` 的位置**（39.1）：必须在第一次写 `<{ ... }>` 之前。
   放到 `aeval` 之后会得到
   `Unknown interpretation for notation "<{ _ }>". This notation is available in com_scope.`，
   报错指向 fixpoint 内部的 `<{a1 + a2}>`，很像"记号没定义"，实际是作用域没开。
2. **bullet 不能回退层级**（39.8）：`-` → `+` → `*` 只能变深。在 `*` 里写 `+` 会报
   `[Focus] Wrong bullet +: Current bullet * is not finished.`。多子目标想省 bullet，
   就让每个子目标的战术**写到完全关闭**，靠自动聚焦跳转（LF 的
   `apply E_Seq with s.` 后面两段无 bullet 战术就是这个写法）。
3. **`induction i1` 要在 `intros` 之前**（39.9）：`ceval_step_more` 的量词顺序是
   `forall i1 i2 st st' c`。先 `intros` 再归纳会把 `i2 st st' c` 钉死，IH 太弱；
   先归纳，IH 自动是 `forall i2 st st' c, ...`，才有 `IHi1' i2'` 可用。
4. **`reflexivity` 不会用假设**（39.10 `E_Asgn`）：`ceval_step st <{x := a}> 1`
   给出 `Some (x !-> aeval st a ; st)`，目标是 `Some (x !-> n ; st)`。要
   `rewrite <- H`（`H : aeval st a = n`）把**表达式换成值**，方向写反就找不到子项。
5. **`rewrite` 之前先 `simpl`**（39.10 `E_Seq`）：目标里 `ceval_step st <{c1;c2}> (S (i1+i2))`
   是**未展开**的，`ceval_step st c1 (i1+i2)` 不作为子项存在，直接 rewrite 报
   `Found no subterm matching ...`。
6. **最终状态是"层层覆盖的函数"，不是干净映射**（39.6）：`= Some (X !-> 0)` 编译
   失败（`Unable to unify "Some (X !-> 0)" with ...`），得写成完整历史
   `Some (X !-> 0 ; X !-> 1 ; X !-> 2 ; X !-> 3)`，或者像 `test_ceval` 那样投影成元组。
   `reflexivity` 只有转换检查，**不会**用函数外延。
7. **`LETOPT ... IN ...` 会把 `LETOPT` 和 `IN` 变成关键字**（39.6）：repl 打印
   `Identifier 'IN' now a keyword`。`IN` 撞 `List.In` 等常用词，别在同一个全局作用域
   里随手复制这段记号。
8. **模式变量避开 `x`**（39.3 起）：LF 一律写 `<{ l := a1 }>`。原因是
   `Coercion AId : string >-> aexp` + 抬进记号 `"x" := x (in custom com ...)` 叠加时，
   用 `x` 作模式变量容易触发解析歧义。抄 LF 代码时不要"顺手改名"成 `x`。
9. **guardedness 是纯语法判断**（39.2）：`loop_false n` 被拒是因为参数不是 `n` 的
   子项；写 `n - 1` 同样不会通过，因为 `nat` 减法的结果不是 syntactic subterm。
   燃料要生效，必须走 `match i with O => ... | S i' => ...` 并把 `i'` 传下去。
10. **`Inductive ceval` 顺带生成 `ceval_ind` 和 `ceval_sind`**（39.1）：repl 三行输出
    `ceval is defined / ceval_ind is defined / ceval_sind is defined`。`induction H`
    默认挑结构归纳；怀疑挑错时显式 `induction H using ceval_sind.`。
11. **本章比 38 章多 `Require Lia`**（39.1 / 39.9）：`assert (Hle' : i1' <= i2') by lia.`
    和结尾两个 `lia.` 都需要它。直接从 38 章复制 `Require` 行会在这里挂掉。
12. **模式变量别遮蔽函数参数**（39.7）：`test_ceval (st : state) (c : com) := match ... with
    | Some st => Some (st X, st Y, st Z)` 能编译，但外层 `st` 被遮住了。改名
    `Some st'` 之后逻辑一眼可读。这类"能过但误导"的写法在教程代码里要避免。
13. **燃料的账要实测，别靠推**（39.6）：`while X <> 0 do X := X - 1 end` 从 3 减到 0，
    直觉"3 轮 = 3 格"是错的：实测 `fuel 3 = None`、`fuel 4 = Some ...`。经验法则是
    `fuel k` 的 while 最多 `k-1` 轮，且每轮体里的序列还要额外格数——写例子时先
    `Compute` 一遍再落进 `Example`。
14. **`Fail` 的报错只在 repl 里可见**（39.2）：`rocq compile -q` 对 `Fail Fixpoint ...`
    静默通过。要看真实报错文本，把编译产物丢进 `rocq repl -q < ex_39_fuel_evaluation.v`。
15. **`O => empty_st` 和 `O => None` 的差别是"能否自检"**（39.4 vs 39.5）：前者把
    失败伪装成成功（`step2_loop_ignores_fuel` 里 3 格和 4 格结果相同），后者让调用方
    至少能判断"这次结果不可信"。造解释器时，**默认值不要落在成功类型里**。

---
上一章：[38 · Imp：状态、命令与大步语义](38-imp-semantics.md) ｜ 下一章：[40 · 小步语义：执行即关系](40-smallstep.md) ｜ 返回：[README](../README.md)
