# 97 · 三元组：语义、定义与结构规则

对应示例：`../examples/97_slf_triples.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

93–96 章搭好了分离逻辑的「材料」：堆谓词 `hprop`、五大组合子、蕴含关系
`==>`/`===>`，以及 `xsimpl` 这台化简机器。但到目前为止，`triple t H Q` 一直
是库里的黑盒——本章（对应原书 Triples 章）把它彻底拆开：**自己定义语言的语
法、自己定义语义、自己定义 triple，再亲手证明全部结构规则**。读完本章你会知
道 `xapp` 背后那台机器的「物理原理」。

本章有个重要的工程转折：从 95/96 章的「自制透明定义」切换到库
`LibSepReference`。95/96 章里 `hstar`、`hpure` 都是裸定义，`destruct` 一把
就摊开；而 `LibSepReference` 要求**只用引理**（`hstar_intro`、`hstar_inv`、
`hempty_inv`……）来操作这些组合子，不靠展开定义。这强制了证明的抽象性——证
明不依赖 `\[]` 内部是 `fun h => h = empty` 还是 `\exists (p:P), \[]` 这类实
现选择。本章及之后所有章节都 `Import LibSepReference`。

全章路线图：

1. **语法**（97.1–97.2）：值/项的区分、替换函数 `subst`、一组让语义规则好看
   的 coercion；
2. **语义**（97.3–97.4）：标准 big-step `big` 为何不够用，以及本章的主角
   ——omni-big-step 语义 `eval`；
3. **triple 定义与结构规则**（97.5–97.10）：框架、后果、抽取规则的完整证明；
4. **与小步语义的关系**（97.11–97.13）：`step`/`steps`、`seval`、可靠性定理
   `soundness_small_step`；
5. **另一条路**（97.14）：对准确定性语言，用「内嵌框架规则」从标准 Hoare 三
   元组直接造出满足框架性质的三元组。

文件头与此前各章相同，多了一句 `Import`（不再需要 93/94 章的
`ProgramSyntax`/`DemoPrograms`，本章不写具体程序）：

```coq
(* 97 三元组：语言语法、omni-big-step 语义、triple 定义与结构规则 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Triples 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
```

## 97.1 语法：值与项

语法用抽象语法树给出，并把**闭值**（`val`，不含自由变量）和**项**（`trm`，
可以含自由变量）分成两个类型。这么做的红利在替换函数上：值永远是闭的，替换
函数永远不必钻进值内部。值的文法包含单元值、布尔、整数、位置、函数、递归函
数，以及一小组原语操作（`ref/get/set/free` 管可变状态，`add` 是纯运算代表，
`div` 是部分函数代表，`rand` 是非确定性代表）：

```coq
(* ---------- 97.1 语法：值与项 ---------- *)

Module Syntax.

(* 值是闭项：单元、布尔、整数、位置、函数、递归函数与若干原语操作。 *)

Inductive val : Type :=
  | val_unit : val
  | val_bool : bool -> val
  | val_int : int -> val
  | val_loc : loc -> val
  | val_fun : var -> trm -> val
  | val_fix : var -> var -> trm -> val
  | val_ref : val
  | val_get : val
  | val_set : val
  | val_free : val
  | val_add : val
  | val_div : val
  | val_rand : val

(* 项可以含自由变量：值、变量、函数、递归函数、应用、序列、let 与条件。 *)

with trm : Type :=
  | trm_val : val -> trm
  | trm_var : var -> trm
  | trm_fun : var -> trm -> trm
  | trm_fix : var -> var -> trm -> trm
  | trm_app : trm -> trm -> trm
  | trm_seq : trm -> trm -> trm
  | trm_let : var -> trm -> trm -> trm
  | trm_if : trm -> trm -> trm -> trm.
```

注意 `val` 与 `trm` 是**互归纳**定义的（`with`）：`val_fun x t` 的函数体 `t`
是项。两者的关键区别：`trm_fun x t1` 里的 `t1` 可以引用 `x` 之外的自由变量，
而 `val_fun x t1` 里的 `t1` 唯一可能的自由变量就是 `x`——闭值相当于「项 + 它
是闭项的证明」揉在一起。求值规则会让 `trm_fun x t1`（在空环境下）归约成
`val_fun x t1`，即「闭化」。

多参数函数用柯里化编码：`fun x1 x2 x3 => t` 写成
`val_fun x1 (trm_fun x2 (trm_fun x3 t))`——最外层断言整个函数是闭值，内层是
项，`t` 可以引用 `x1`、`x2`。递归版 `val_fix f x1 (trm_fun x2 ...)` 同理，只
有最外层递归。

> 顺带说明：本章在 `Module Syntax` 里复刻这套文法纯粹是为了**当教材讲**。库
> `LibSepReference` 里有一套几乎相同但更全的定义（原语操作抽成独立的 `prim`
> 类型，多了 `val_uninit`/`val_error` 等）。模块关闭后我们自动回到库定义——
> 后文证明用的都是库的 `val`/`trm`/`subst`，与上面的定义逐条对应。

## 97.2 状态、替换与语法糖

状态就是 95 章的老朋友：`fmap loc val`。`Inhab` 实例是为了让有限映射库在读
状态时能取默认值（`Fmap.read` 的类型依赖值类型非空），一行带过：

```coq
(* ---------- 97.2 状态、替换与语法糖 ---------- *)

Definition heap : Type := fmap loc val.

Global Instance Inhab_val : Inhab val.
Proof using. apply (Inhab_of_val val_unit). Qed.
```

函数应用的语义靠**替换**描述：`subst y w t` 把项 `t` 里变量 `y` 的出现换成
值 `w`。三条设计原则都体现在代码里：值分支原样返回（值是闭的，无需下钻）；
到达变量时用 `var_eq` 比较；穿过绑定者（`fun x`、`fix f x`、`let x`）时若绑
定名恰为 `y` 就**不再下钻**——避免变量捕获。辅助函数 `if_y_eq` 把这些比较
统一起来：

```coq
(* subst y w t 把项 t 中变量 y 的出现替换为值 w；值恒为闭项故无需下钻，
   遇到与 y 同名的绑定者则不再下钻以避免变量捕获。 *)

Fixpoint subst (y:var) (w:val) (t:trm) : trm :=
  let aux t := subst y w t in
  let if_y_eq x t1 t2 := if var_eq x y then t1 else t2 in
  match t with
  | trm_val v => trm_val v
  | trm_var x => if_y_eq x (trm_val w) t
  | trm_fun x t1 => trm_fun x (if_y_eq x t1 (aux t1))
  | trm_fix f x t1 => trm_fix f x (if_y_eq f t1 (if_y_eq x t1 (aux t1)))
  | trm_app t1 t2 => trm_app (aux t1) (aux t2)
  | trm_seq t1 t2 => trm_seq  (aux t1) (aux t2)
  | trm_let x t1 t2 => trm_let x (aux t1) (if_y_eq x t2 (aux t2))
  | trm_if t0 t1 t2 => trm_if (aux t0) (aux t1) (aux t2)
  end.
```

例如 `subst y w (trm_let x t1 t2)` 的结果是
`trm_let x (subst y w t1) (if var_eq x y then t2 else subst y w t2)`：`t1` 在
`x` 的作用域外必须替换；`t2` 在作用域内，仅当 `x` 与 `y` 不同名时才替换。

最后一组「语法糖」是 Rocq 的隐式类型与 coercion。声明之后，位置 `p` 可直接
写在需要值的地方（自动 `val_loc p`）、布尔/整数同理；值 `v` 可直接写在需要
项的地方（自动 `trm_val v`）；**最妙的是 `trm_app` 注册成了 `Funclass`
coercion**——项 `t1` 后面跟个参数就自动解析成应用，于是 `t1 t2 t3` 就是
`trm_app (trm_app t1 t2) t3`，语义规则读起来像伪代码：

```coq
Implicit Types b : bool.
Implicit Types v r : val.
Implicit Types t : trm.

Coercion val_loc : loc >-> val.
Coercion val_bool : bool >-> val.
Coercion val_int : Z >-> val.

Coercion trm_val : val >-> trm.

Coercion trm_app : trm >-> Funclass.

End Syntax.

(* 后文回到 LibSepReference 的同名定义（与上面 Syntax 模块中的完全一致）。 *)

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types p : loc.
Implicit Types n : int.
Implicit Types v w r : val.
Implicit Types t : trm.
Implicit Types h s : heap.
Implicit Types H : hprop.
```

（这些 coercion 在 `LibSepReference` 里早已声明，这里是教程语境下的重述；隐
式类型声明让后文陈述里的 `s`/`t`/`Q` 等名字自动带上正确类型。）

## 97.3 标准 big-step 语义：为什么它不够

第一个语义用最常见的**大步**判断 `big s t s' v`：从状态 `s` 出发，`t` 的**某
一次**执行终止于 `s'`、产出 `v`。假设程序已写成「A-范式」：应用和条件的参
数位置只出现变量或值（`if t0 then ...` 总能用 `let x = t0 in if x then ...`
改写，不损失表达力），这让规则干净很多：

```coq
(* ---------- 97.3 标准 big-step 语义 big ---------- *)

(* big s t s' v：从状态 s 出发，项 t 的一种执行终止于状态 s'、结果值 v。 *)

Inductive big : heap -> trm -> heap -> val -> Prop :=

  (* 1. 值与函数定义：值即为自身；项函数/递归函数求值为对应的闭值。 *)

  | big_val : forall s v,
      big s (trm_val v) s v
  | big_fun : forall s x t1,
      big s (trm_fun x t1) s (val_fun x t1)
  | big_fix : forall s f x t1,
      big s (trm_fix f x t1) s (val_fix f x t1)

  (* 2. 函数应用：beta 规约（递归函数把自身也代入）。 *)

  | big_app_fun : forall s1 s2 v1 v2 x t1 v,
      v1 = val_fun x t1 ->
      big s1 (subst x v2 t1) s2 v ->
      big s1 (trm_app v1 v2) s2 v
  | big_app_fix : forall s1 s2 v1 v2 f x t1 v,
      v1 = val_fix f x t1 ->
      big s1 (subst x v2 (subst f v1 t1)) s2 v ->
      big s1 (trm_app v1 v2) s2 v
```

应用规则的形状值得停一下：`(val_fun x t1) v2` 的行为就是 `subst x v2 t1` 的
行为；递归函数 `(val_fix f x t1) v2` 则先做**双重代入**——把函数自身 `v1`
代入 `f`、把实参代入 `x`——这正是 93/94 章里 `xapp` 处理 `let rec f x = ...`
时的语义内核。注意这里用了 coercion：`v1`、`v2` 是值，出现在项的位置自动包
上 `trm_val`，`trm_app v1 v2` 就是「把闭函数作用到闭实参」。

结构构件与条件：

```coq
  (* 3. 结构构件：序列丢弃 t1 的结果；let 把结果代入 t2。 *)

  | big_seq : forall s1 s2 s3 t1 t2 v1 v,
      big s1 t1 s2 v1 ->
      big s2 t2 s3 v ->
      big s1 (trm_seq t1 t2) s3 v
  | big_let : forall s1 s2 s3 x t1 t2 v1 r,
      big s1 t1 s2 v1 ->
      big s2 (subst x v1 t2) s3 r ->
      big s1 (trm_let x t1 t2) s3 r

  (* 4. 条件：设 A-范式，条件表达式已求值为布尔。 *)

  | big_if : forall s1 s2 b v t1 t2,
      big s1 (if b then t1 else t2) s2 v ->
      big s1 (trm_if (val_bool b) t1 t2) s2 v
```

`big_if` 借用 Rocq 自己的 `if` 把真假两个分支合并成一条规则；条件不是布尔值
就没有规则可用——**求值卡死**。原语操作把三种「麻烦」一次展示全：

```coq
  (* 5. 无状态原语：加法；部分函数除法（除零则卡死）；非确定的 rand。 *)

  | big_add : forall s n1 n2,
      big s (val_add (val_int n1) (val_int n2)) s (val_int (n1 + n2))
  | big_div : forall s n1 n2,
      n2 <> 0 ->
      big s (val_div (val_int n1) (val_int n2)) s (val_int (Z.quot n1 n2))
  | big_rand : forall s n n1,
      0 <= n1 < n ->
      big s (val_rand (val_int n)) s (val_int n1)

  (* 6. 状态原语：ref 分配新鲜单元；get/set/free 要求位置已绑定。 *)

  | big_ref : forall s v p,
      ~ Fmap.indom s p ->
      big s (val_ref v) (Fmap.update s p v) (val_loc p)
  | big_get : forall s p,
      Fmap.indom s p ->
      big s (val_get (val_loc p)) s (Fmap.read s p)
  | big_set : forall s p v,
      Fmap.indom s p ->
      big s (val_set (val_loc p) v) (Fmap.update s p v) val_unit
  | big_free : forall s p,
      Fmap.indom s p ->
      big s (val_free (val_loc p)) (Fmap.remove s p) val_unit.
```

- `big_div` 带前提 `n2 <> 0`：除零程序**无法**用 `big` 判断描述——它没有任何
  执行能「成功」，这正确捕捉了部分性；
- `big_rand` 对每个满足 `0 <= n1 < n` 的结果各给一条规则——**非确定性**：同
  一程序有多条互斥的推导；
- `big_ref` 对每个新鲜位置 `p` 各给一条规则——分配也是非确定的（选哪个地址
  由运行时决定）。

`big` 的问题正在于此：它描述的是**单次**执行。拿它定义 triple（比如
`hoare t H Q := forall s, H s -> exists s' v, big s t s' v /\ Q v s'`）只能得到
「存在一次好的执行」，推不出「**所有**执行都终止且正确」——`rand 10` 后接一
个只对偶数正确的续体，用 `exists` 版定义照样「可证」。97.14 节会再回到这个
对照。

## 97.4 omni-big-step 语义 eval

解法是把大步判断的「结果」从单个 `(s', v)` 换成**终格局的集合** `Q : val ->
heap -> Prop`（读法：值 × 状态的对）。`eval s t Q` 断言：从 `(s,t)` 出发的
**一切可能执行**都安全终止，且终格局落在 `Q` 里。从 `big` 到 `eval` 的改写
有固定套路，逐条看：

```coq
(* ---------- 97.4 omni-big-step 语义 eval ---------- *)

(* eval s t Q：从 (s,t) 出发的所有执行都安全终止，且终格局满足后条件 Q。
   Q 是 (值, 状态) 对的集合（后条件的集合语义）。 *)

Implicit Types Q : val->heap->Prop.

Inductive eval : heap -> trm -> (val->heap->Prop) -> Prop :=

  (* 1. 值与函数定义。 *)

  | eval_val : forall s v Q,
      Q v s ->
      eval s (trm_val v) Q
  | eval_fun : forall s x t1 Q,
      Q (val_fun x t1) s ->
      eval s (trm_fun x t1) Q
  | eval_fix : forall s f x t1 Q,
      Q (val_fix f x t1) s ->
      eval s (trm_fix f x t1) Q
```

值规则从「值是自己」变成「`(s, v)` 必须已在 `Q` 中」——集合语义下，没有执
行步骤的格局直接以自身为终格局。应用规则照搬 beta 规约，后条件原样传递：

```coq
  (* 2. 函数应用：先代换再继续，后条件原样传递。 *)

  | eval_app_fun : forall s1 v1 v2 x t1 Q,
      v1 = val_fun x t1 ->
      eval s1 (subst x v2 t1) Q ->
      eval s1 (trm_app v1 v2) Q
  | eval_app_fix : forall s v1 v2 f x t1 Q,
      v1 = val_fix f x t1 ->
      eval s (subst x v2 (subst f v1 t1)) Q ->
      eval s (trm_app v1 v2) Q
```

真正的「omni 味道」出现在序列：要证 `t1; t2` 全部执行都好，得先选一个**中
间后条件 `Q1`** 概括 `t1` 的一切可能结果，再对 `Q1` 里的**每个** `(v1, s2)`
证明 `t2` 接得住：

```coq
  (* 3. 序列与 let：选一个中间后条件 Q1 概括第一步的全部可能结果。 *)

  | eval_seq : forall Q1 s t1 t2 Q,
      eval s t1 Q1 ->
      (forall v1 s2, Q1 v1 s2 -> eval s2 t2 Q) ->
      eval s (trm_seq t1 t2) Q
  | eval_let : forall Q1 s x t1 t2 Q,
      eval s t1 Q1 ->
      (forall v1 s2, Q1 v1 s2 -> eval s2 (subst x v1 t2) Q) ->
      eval s (trm_let x t1 t2) Q

  (* 4. 条件。 *)

  | eval_if : forall s (b:bool) t1 t2 Q,
      eval s (if b then t1 else t2) Q ->
      eval s (trm_if (val_bool b) t1 t2) Q
```

这个 `Q1` 就是 93 章 `xlet` 战术让你「现场发明」的那个后条件——现在你看到
它的语义出身了。原语操作里，`add/div` 把结果塞进 `Q` 即可；`rand` 要求
`n > 0` 且**对一切**可能结果 `n1` 都有 `Q n1 s`；`ref` 要求**对一切**新鲜位
置 `p` 都有 `Q (val_loc p) (update s p v)`——非确定性全部被「全称」吃掉：

```coq
  (* 5. 无状态原语：rand 要求 n>0 且对一切可能结果 n1 都满足 Q。 *)

  | eval_add : forall s n1 n2 Q,
      Q (val_int (n1 + n2)) s ->
      eval s (val_add (val_int n1) (val_int n2)) Q
  | eval_div : forall s n1 n2 Q,
      n2 <> 0 ->
      Q (val_int (Z.quot n1 n2)) s ->
      eval s (val_div (val_int n1) (val_int n2)) Q
  | eval_rand : forall s n Q,
      n > 0 ->
      (forall n1, 0 <= n1 < n -> Q n1 s) ->
      eval s (val_rand (val_int n)) Q

  (* 6. 状态原语：ref 对一切新鲜位置 p 都要求 Q 成立（非确定性在此处理）。 *)

  | eval_ref : forall s v Q,
      (forall p, ~ Fmap.indom s p ->
          Q (val_loc p) (Fmap.update s p v)) ->
      eval s (val_ref v) Q
  | eval_get : forall s p Q,
      Fmap.indom s p ->
      Q (Fmap.read s p) s ->
      eval s (val_get (val_loc p)) Q
  | eval_set : forall s p v Q,
      Fmap.indom s p ->
      Q val_unit (Fmap.update s p v) ->
      eval s (val_set (val_loc p) v) Q
  | eval_free : forall s p Q,
      Fmap.indom s p ->
      Q val_unit (Fmap.remove s p) ->
      eval s (val_free (val_loc p)) Q.
```

两点注记。第一，`eval s t Q` 里的 `Q` 只须是可达终格局集合的**过近似**——
想造一个「恰好等于可达集」的归纳定义反而自找麻烦。第二，`eval` 是
`Inductive`：它强迫**所有**执行终止（比如 `let n = rand 10 in f n` 要过
`eval_let` 的第二前提，就必须让 `f` 对 0–9 每个数都终止）。若改成
`CoInductive`，无穷执行会被放行，得到的将是「部分正确性」三元组（每个执行
要么安全终止要么发散）。学界主流研究集中在部分正确性；而只要不考虑并发，
omni-big-step 让**全**正确性的处理出奇地顺——这正是本课程选它的原因。

## 97.5 triple 的定义

全课程最重要的定义只有两行：

```coq
(* ---------- 97.5 triple 的定义 ---------- *)

(* triple t H Q：任何满足前条件 H 的初始状态 s，(s,t) 的一切执行
   都终止且终格局满足后条件 Q（全正确性）。 *)

Definition triple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall s, H s -> eval s t Q.
```

「对一切满足 `H` 的初始状态，一切执行都终止于满足 `Q` 的终格局」——因为
`eval` 捕捉终止，`triple` 是**全正确性**三元组；93 章以来你证明的每一条
`triple ...`，背后都是这句话。

## 97.6 结构规则：先陈述，后证明

结构规则是与具体语言构件无关的推理规则，共四条，先用 `Parameter` 陈述（先
当公理用，97.7–97.9 逐条兑现）。**框架规则**是分离逻辑的心脏：任意堆谓词可
以同时框到前、后条件上——程序只动自己声明的那块内存，其余原封不动：

```coq
(* ---------- 97.6 结构规则：先陈述后证明 ---------- *)

Module StructuralRules.

Parameter triple_frame : forall t H Q H',
  triple t H Q ->
  triple t (H \* H') (Q \*+ H').

Parameter triple_conseq : forall t H' Q' H Q,
  triple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  triple t H Q.

Parameter triple_hpure : forall t (P:Prop) H Q,
  (P -> triple t H Q) ->
  triple t (\[P] \* H) Q.

Parameter triple_hexists : forall t (A:Type) (J:A->hprop) Q,
  (forall x, triple t (J x) Q) ->
  triple t (\exists x, J x) Q.
```

**后果规则**与 Hoare 逻辑同名规则一致：前条件可以加强、后条件可以削弱。
**两条抽取规则**把纯事实/存在量词从前条件里抽出来——它们正是 96 章
`himpl_hstar_hpure_l`/`himpl_hexists_l` 在 triple 上的镜像，也是 `xpull` 的
理论基础。

框架规则很少能「直接」用：目标的前条件若写成 `H' \* H`（顺序反了）就不匹配
`H \* H'` 的形状。把框架与后果**合并**成一条无形状限制的规则才好用：

**练习（1 星）triple_conseq_frame**——合并的后果-框架规则。证法一气呵成：
先用两条蕴含喂饱后果规则，剩下一个 `triple t H1 Q1` 恰是框架规则的输入：

```coq
(* 练习（1 星，标准，必做）：后果-框架规则。 *)

Lemma triple_conseq_frame : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  triple t H Q.
Proof using.
  introv M WH WQ. applys triple_conseq WH WQ. applys triple_frame M.
Qed.
```

`applys triple_conseq WH WQ` 把 `WH : H ==> H1 \* H2`、`WQ : Q1 \*+ H2 ===>
Q` 按「首匹配」填进后果规则的两个蕴含前提，剩下 `triple t H1 Q1`，再
`applys triple_frame M` 用 `M` 收尾。93 章 `xapp` 的三段式（规格 + 两条蕴含）
就是这条规则的战术化。

**练习（1 星）triple_hpure'**——纯事实抽取的不带星号变体：前条件只有
`\[P]` 时规则照样成立。思路：把 `\[]` 补成 `\[P] \* \[]` 用 `triple_hpure`，
再用后果规则把多出来的空堆消掉：

```coq
(* 练习（1 星，标准，选做）：纯前条件不带星号的变体。 *)

Lemma triple_hpure' : forall t (P:Prop) Q,
  (P -> triple t \[] Q) ->
  triple t \[P] Q.
Proof using.
  introv M. applys triple_conseq (triple_hpure M).
  { xsimpl. auto. }
  { applys qimpl_refl. }
Qed.
```

两个子目标分别是 `\[P] ==> \[P] \* \[]`（`xsimpl` 归一化后剩 `P -> P`，需要
`auto` 收尾）和 `Q ===> Q`（`qimpl_refl` 直接关）。

```coq
End StructuralRules.
```

## 97.7 后果规则的证明

后果规则的核心是：`eval` 对后条件的**包含关系单调**——`Q1` 是 `(s,t)` 可达
终格局的过近似，`Q1 ⊆ Q2` 时 `Q2` 当然也是过近似。对 `eval` 的推导归纳即
可，且**全部情形**被一行 `constructors*` 扫光：

```coq
(* ---------- 97.7 后果规则的证明 ---------- *)

(* 关键：eval 对后条件 weakening 单调（Q1 ⊆ Q2）。 *)

Lemma eval_conseq : forall s t Q1 Q2,
  eval s t Q1 ->
  Q1 ===> Q2 ->
  eval s t Q2.
Proof using.
  introv M W.
  asserts W': (forall v h, Q1 v h -> Q2 v h). { auto. } clear W.
  induction M; try solve [ constructors* ].
Qed.
```

为什么一行就够？以 `eval_seq` 情形为例：目标是 `eval s (trm_seq t1 t2) Q2`，
`constructors` 选中 `eval_seq` 并留下两个前提——第一个 `eval s t1 ?Q1'` 由
**原有前提** `M : eval s t1 Q1` 直接给出（`?Q1' := Q1`），第二个
`forall v1 s2, Q1 v1 s2 -> eval s2 t2 Q2` 恰是**归纳假设**的形状。其余构造
子的模式相同，eauto 都能对上号。`triple_conseq` 随之三行兑现：

```coq
Lemma triple_conseq : forall t H' Q' H Q,
  triple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  triple t H Q.
Proof using. unfolds triple. introv M MH MQ HF. applys* eval_conseq. Qed.
```

## 97.8 框架规则的证明

框架规则的核心引理是 `eval` 的**框架性质**：把一块与执行无关的不相交堆
`h2` 并进初始状态，执行照常进行，且 `h2` 原封不动地留到最后——后条件里的
`Q \*+ (= h2)` 用「恰为 `h2`」谓词把这块框架记录在案：

```coq
(* ---------- 97.8 框架规则的证明 ---------- *)

(* 核心：eval 在并入一块不相交的堆后保持（后条件带上 (= h2) 记录"框架"部分）。 *)

Lemma eval_frame : forall h1 h2 t Q,
  eval h1 t Q ->
  Fmap.disjoint h1 h2 ->
  eval (h1 \u h2) t (Q \*+ (= h2)).
Proof using.
  introv M HD. gen h2. induction M; intros;
    try solve [ hint hstar_intro; constructors* ].
  { rename M into M1, H into M2, IHM into IH1, H0 into IH2.
    specializes IH1 HD. applys eval_seq IH1. introv HK.
    lets (h1'&h2'&K1'&K2'&KD&KU): hstar_inv HK. subst. applys* IH2. }
  { rename M into M1, H into M2, IHM into IH1, H0 into IH2.
    specializes IH1 HD. applys eval_let IH1. introv HK.
    lets (h1'&h2'&K1'&K2'&KD&KU): hstar_inv HK. subst. applys* IH2. }
```

骨架：`gen h2` 把 `h2` 连同不相交假设一起一般化，再对 `eval` 推导归纳。大
多数构造子（值、函数、应用、算术等）被 `hint hstar_intro; constructors*` 一
行解决——`hint` 先给 `hstar_intro` 挂上提示，eauto 用它把「`Q v (h1 \u h2)`
且框架为 `h2`」拆装回去。真正要手写的只有六个情情：两个结构构件（seq/let，
上面两块）和四个状态原语。

`eval_seq` 情形值得细读：归纳假设 `IH1 : eval (h1 \u h2) t1 (Q1 \*+ (= h2))`
（`specializes IH1 HD` 把不相交性喂给它），于是序列第一步得到「结果 +
框架」；第二步的前提拿到 `Q1 v1 s2' \* (= h2) h2'`，用 `hstar_inv` 拆开——
这保证 `v1`、`s2'` 只描述 `h1` 那一半，框架 `h2` 干净地传给 `IH2`。这正是
93 章反复念叨的「星号两边各管各的」在语义层的体现。

**分配是全章最有趣的情形**：

```coq
  { (* 分配是关键情形：新鲜位置的约束从 h1 收紧到 h1 \u h2。 *)
    rename H into M. applys eval_ref. intros p Hp.
    rewrite Fmap.indom_union_eq in Hp. rew_logic in Hp.
    destruct Hp as [Hp1 Hp2].
    rewrite* Fmap.update_union_not_r. applys hstar_intro.
    { applys* M. } { auto. } { applys* Fmap.disjoint_update_not_r. } }
```

方向想清楚：要证的是「对一切 `h1 \u h2` 的新鲜 `p`，……」，而已知「对一切
`h1` 的新鲜 `p`，……」。`p` 对**更大的**堆新鲜蕴含它对 `h1` 新鲜（且不在
`h2` 里）——前提的约束比目标**强**，所以结论成立；同时新单元 `update s p v`
落在并堆的左半边（`update_union_not_r`），与 `h2` 的不相交性保持（
`disjoint_update_not_r`）。直观：框架堆挡住了一部分地址，但可分配的地址无穷
多，分配总能避开框架。get/set/free 三个情形是「堆运算四则」的练习：
`indom_union_eq` 拆「在并堆中」、`read_union_l`/`update_union_l` 在左半边操
作、`remove_disjoint_union_l`/`disjoint_remove_l` 处理释放：

```coq
  { applys eval_get. { rewrite* Fmap.indom_union_eq. }
    { rewrite* Fmap.read_union_l. applys* hstar_intro. } }
  { applys eval_set. { rewrite* Fmap.indom_union_eq. }
    { rewrite* Fmap.update_union_l. applys hstar_intro.
      { auto. } { auto. } { applys* Fmap.disjoint_update_l. } } }
  { applys eval_free. { rewrite* Fmap.indom_union_eq. }
    { rewrite* Fmap.remove_disjoint_union_l. applys hstar_intro.
      { auto. } { auto. } { applys* Fmap.disjoint_remove_l. } } }
Qed.
```

`triple_frame` 则是把 `eval_frame` 与 `eval_conseq` 缝起来：初始堆按星号拆
成 `h1`（程序的）和 `h2`（框架的），程序按 `eval_frame` 跑，最后把
`Q \*+ (= h2)` 弱化成 `Q \*+ H2`（`h2` 只是 `H2` 的一个见证）：

```coq
Lemma triple_frame : forall t H Q H',
  triple t H Q ->
  triple t (H \* H') (Q \*+ H').
Proof.
  introv M. intros h HF. lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. specializes M M1. applys eval_conseq.
  { applys eval_frame M MD. } { xsimpl. intros h' ->. applys M2. }
Qed.
```

注意最后一个子目标：`(Q \*+ (= h2)) ===> (Q \*+ H')`——`xsimpl` 归一化后剩
`h2 = h2 -> H' h2` 之类，`intros h' ->` 把 `=` 的方向理顺，`M2 : H' h2` 收
尾。93 章每次 `xapp` 自动「带上剩余资源」，幕后就是这条定理。

## 97.9 抽取规则的证明

抽取规则的证明模式：展开 `triple`，对「初始状态满足前条件」做反演。纯事实
版：

```coq
(* ---------- 97.9 抽取规则的证明 ---------- *)

Lemma triple_hpure : forall t (P:Prop) H Q,
  (P -> triple t H Q) ->
  triple t (\[P] \* H) Q.
Proof using.
  introv M. intros h (h1&h2&M1&M2&D&U). destruct M1 as (M1&HP).
  lets E: hempty_inv HP. subst. rewrite Fmap.union_empty_l. applys~ M.
Qed.
```

逐步读：`intros h (h1&h2&M1&M2&D&U)` 用 intro 模式把
`(\[P] \* H) h` 拆成两块堆；`destruct M1 as (M1&HP)` 处理 `\[P] h1`——回忆
库里 `hpure P := \exists (p:P), \[]`，拆出来的 `M1 : P` 是纯事实本体、
`HP : \[] h1` 说这块堆是空的；`hempty_inv` 把它变成 `h1 = Fmap.empty`，
`subst` 后并堆退化（`union_empty_l`），`M1` 与 `M2` 一起喂给 `M`。这就是
`xpull` 在 triple 侧的原型。

**练习（1 星）triple_hexists**——存在量词版两行搞定：

```coq
(* 练习（1 星，标准，必做）：存在量词抽取规则。 *)

Lemma triple_hexists : forall t (A:Type) (J:A->hprop) Q,
  (forall (x:A), triple t (J x) Q) ->
  triple t (hexists J) Q.
Proof using. introv M. intros h (x&Hh). applys M Hh. Qed.
```

`intros h (x&Hh)` 把见证 `x` 抽到上下文（「存在变任意」——洛绎推理），
`applys M Hh` 让 unification 自己找到该用 `M` 的哪个实例。

**练习（1 星）triple_named_heap**——给堆命名的规则：证明 `triple t H Q` 时
可以把「当前那个具体的堆」`h` 请出来当变量（后条件不依赖它，但技术上做得到；
100 章证 `wp_equiv_2` 时会用到）：

```coq
(* 练习（1 星，标准，选做）：给堆命名的规则。 *)

Lemma triple_named_heap : forall t H Q,
  (forall h, H h -> triple t (= h) Q) ->
  triple t H Q.
Proof using. introv M Hs. applys M Hs. auto. Qed.
```

`(= h)` 是只接受「恰好等于 `h`」的堆的谓词（96 章 `hexists_named_eq` 已打过
交道）；`applys M Hs` 之后剩 `(= s) s`，即 `s = s`，`auto` 收尾。

## 97.10 存在量词规则的另一种形式（两条规则等价）

传统分离逻辑论文里的存在规则前后条件**都**带存在量词，形式是
`triple_hexists2`。有了后果规则，它与 97.9 的 `triple_hexists` 等价——两个
方向都顺手证掉，之后就能放心用更简洁的版本：

**练习（2 星）triple_hexists2**：

```coq
(* ---------- 97.10 存在量词规则的另一种形式（二者等价） ---------- *)

Module AlternativeExistentialRule.

(* 练习（2 星，标准，必做）：传统文献中前后条件都带存在量词的版本。 *)

Lemma triple_hexists2 : forall A (Hof:A->hprop) (Qof:A->val->hprop) t,
  (forall x, triple t (Hof x) (Qof x)) ->
  triple t (\exists x, Hof x) (fun v => \exists x, Qof x v).
Proof using.
  introv M. applys triple_hexists. intros x.
  applys triple_conseq (M x).
  { xsimpl. }
  { intros v. xsimpl x. }
Qed.
```

先用 `triple_hexists` 吃掉前条件里的存在量词，再对每个 `x` 用后果规则强化后
条件：`Qof x ===> fun v => \exists x', Qof x' v`——右边造个存在量词、见证就
选当前的 `x`（`xsimpl x` 按位填入见证）。

**练习（2 星）反方向**（题目要求不许用 `triple_hexists`）：对
`triple_hexists2` 取**常量后条件族** `Qof := fun _ => Q`，它的结论就是
`triple t (\exists x, Hof x) (fun v => \exists x, Q v)`，再把后条件的存在量
词用 `himpl_hexists_l` 抽掉即可：

```coq
(* 练习（2 星，标准，必做）：反方向（不许用 triple_hexists）。 *)

Lemma triple_hexists_of_triple_hexists2 : forall t (A:Type) (Hof:A->hprop) Q,
  (forall x, triple t (Hof x) Q) ->
  triple t (\exists x, Hof x) Q.
Proof using.
  introv M.
  applys triple_conseq (triple_hexists2 Hof (fun (x:A) => Q) M).
  { xsimpl. }
  { intros v. applys himpl_hexists_l. intros x. applys himpl_refl. }
Qed.
```

```coq
End AlternativeExistentialRule.
```

## 97.11 小步语义

到这里，`triple` 的可靠性是**相对于 `eval` 自己**说的（`triple` 就是按
`eval` 定义的）。但如果一门语言的规范语义是**小步**的怎么办？本章余下部
分回答两件事：(1) 把 omni-big-step 与小步语义形式化地接起来；(2) 也试试直接
在小步语义上定义 triple。先看小步判断 `step s t s' t'`：格局 `(s,t)` 归约
一步到 `(s',t')`。规则分三层——两条上下文规则（seq/let 的左侧子项可步进则
整体可步进）、七条归约规则（与 `big` 的 beta 规约一一对应）、七条原语操作
（与 `big` 的原语一致）：

```coq
(* ---------- 97.11 小步语义 ---------- *)

(* step s t s' t'：格局 (s,t) 可以一步归约到 (s',t')。 *)

Inductive step : heap -> trm -> heap -> trm -> Prop :=

(* 上下文规则 *)
| step_seq_ctx : forall s1 s2 t1 t1' t2,
    step s1 t1 s2 t1' ->
    step s1 (trm_seq t1 t2) s2 (trm_seq t1' t2)
| step_let_ctx : forall s1 s2 x t1 t1' t2,
    step s1 t1 s2 t1' ->
    step s1 (trm_let x t1 t2) s2 (trm_let x t1' t2)

(* 归约规则 *)
| step_fun : forall s x t1,
    step s (trm_fun x t1) s (val_fun x t1)
| step_fix : forall s f x t1,
    step s (trm_fix f x t1) s (val_fix f x t1)
| step_app_fun : forall s v1 v2 x t1,
    v1 = val_fun x t1 ->
    step s (trm_app v1 v2) s (subst x v2 t1)
| step_app_fix : forall s v1 v2 f x t1,
    v1 = val_fix f x t1 ->
    step s (trm_app v1 v2) s (subst x v2 (subst f v1 t1))
| step_if : forall s b t1 t2,
    step s (trm_if (val_bool b) t1 t2) s (if b then t1 else t2)
| step_seq : forall s t2 v1,
    step s (trm_seq v1 t2) s t2
| step_let : forall s x t2 v1,
    step s (trm_let x v1 t2) s (subst x v1 t2)

(* 原语操作 *)
| step_add : forall s n1 n2,
    step s (val_add (val_int n1) (val_int n2)) s (val_int (n1 + n2))
| step_div : forall s n1 n2,
    n2 <> 0 ->
    step s (val_div (val_int n1) (val_int n2)) s (Z.quot n1 n2)
| step_rand : forall s n n1,
    0 <= n1 < n ->
    step s (val_rand (val_int n)) s (val_int n1)
| step_ref : forall s v p,
    ~ Fmap.indom s p ->
    step s (val_ref v) (Fmap.update s p v) (val_loc p)
| step_get : forall s p,
    Fmap.indom s p ->
    step s (val_get (val_loc p)) s (Fmap.read s p)
| step_set : forall s p v,
    Fmap.indom s p ->
    step s (val_set (val_loc p) v) (Fmap.update s p v) val_unit
| step_free : forall s p,
    Fmap.indom s p ->
    step s (val_free (val_loc p)) (Fmap.remove s p) val_unit.
```

配套定义一望即知：`steps` 是自反传递闭包；`trm_is_val` 判断值；**不能步进的
非值格局**称为卡死（stuck），`reducible`/`notstuck` 把这两种状态说清楚。值
不可步进（`reducibleible_val_inv`，反演一步规则即得——没有任何 `step` 规则
的左手边是值）：

```coq
(* steps 是 step 的自反传递闭包。 *)

Inductive steps : heap -> trm -> heap -> trm -> Prop :=
  | steps_refl : forall s t,
      steps s t s t
  | steps_step : forall s1 s2 s3 t1 t2 t3,
      step s1 t1 s2 t2 ->
      steps s2 t2 s3 t3 ->
      steps s1 t1 s3 t3.

Lemma steps_of_step : forall s1 s2 t1 t2,
  step s1 t1 s2 t2 ->
  steps s1 t1 s2 t2.
Proof using. introv M. applys steps_step M. applys steps_refl. Qed.

Lemma steps_trans : forall s1 s2 s3 t1 t2 t3,
  steps s1 t1 s2 t2 ->
  steps s2 t2 s3 t3 ->
  steps s1 t1 s3 t3.
Proof using.
  introv M1. induction M1; introv M2. { auto. } { constructors*. }
Qed.

Definition trm_is_val (t:trm) : Prop :=
  match t with trm_val v => True | _ => False end.

(* 不能步进的非值格局称为卡死（stuck）。 *)

Definition reducible (s:heap) (t:trm) : Prop :=
  exists s' t', step s t s' t'.

Lemma reducible_val_inv : forall s v,
  ~ reducible s v.
Proof using. introv (s'&t'&M). inverts M. Qed.

Definition notstuck (s:heap) (t:trm) : Prop :=
  trm_is_val t \/ reducible s t.
```

## 97.12 seval：小步式的全正确性

「全正确性」拆成三个小步式性质：**终止**（`terminates`：一切执行有限长，
注意到达值后无法步进、天然算终止）、**安全**（`safe`：一切可达格局要么是值
要么可步进——永不卡死）、**正确**（`correct`：一切到达值的执行满足后条件）。
前两者合起来是部分正确性，三者合起来是全正确性：

```coq
(* ---------- 97.12 seval：小步式全正确性与可靠性 ---------- *)

Inductive terminates : heap->trm->Prop :=
  | terminates_step : forall s t,
      (forall s' t', step s t s' t' -> terminates s' t') ->
      terminates s t.

Definition safe (s:heap) (t:trm) : Prop :=
  forall s' t', steps s t s' t' -> notstuck s' t'.

Definition correct (s:heap) (t:trm) (Q:val->hprop) : Prop :=
  forall s' v, steps s t s' v -> Q v s'.
```

直接拿三条性质做归纳会互相缠绕，标准做法是先引入一个把它们打包的归纳判断
`seval`——**值情形**直接要求 `Q v s`；**步进情形**要求当前格局可归约、且一
切一步后继都 `seval`。它是「`safe` + `correct` + `terminates`」的小步式合
体，也是 `eval` 在小步世界的对应物：

```coq
(* seval s t Q：值情形直接要求 Q；步进情形要求可归约且一切后继都 seval。 *)

Inductive seval : heap->trm->(val->hprop)->Prop :=
  | seval_val : forall s v Q,
      Q v s ->
      seval s v Q
  | seval_step : forall s t Q,
      reducible s t -> (* (exists s' t', step s t s' t') *)
      (forall s' t', step s t s' t' -> seval s' t' Q) ->
      seval s t Q.
```

**练习（2 星）seval_val_inv**——热身反演：`seval` 落在值上时只能是值情形。
`inverts M` 给出两个情形，第二个（步进情形）里 `reducible s v` 与
「值不可步进」矛盾，拆开 `reducible` 再反演 `step` 即灭：

```coq
(* 练习（2 星，标准，选做）：热身——值情形的反演。 *)

Lemma seval_val_inv : forall s v Q,
  seval s v Q ->
  Q v s.
Proof using.
  introv M. inverts M.
  { auto. }
  { destruct H as (s'&t'&R). inverts R. }
Qed.
```

**练习（2 星）seval_terminates**——`seval` 蕴含终止。对 `seval` 推导归纳，
两个情形都用 `terminates_step` 展开：值情形反演 `step`（值无步可进，前提空
真）；步进情形的结论与归纳假设逐字相同：

```coq
(* 练习（2 星，标准，必做）：seval 蕴含终止性。 *)

Lemma seval_terminates : forall s t Q,
  seval s t Q ->
  terminates s t.
Proof using.
  introv M. induction M; constructors; introv R.
  { inverts R. }
  { eauto. }
Qed.
```

**练习（3 星）seval_safe**——安全性。这里有个漂亮的换轴：**不归纳 `seval`
而归纳 `steps`**（`gen Q` 让 `seval` 的后条件可以随行）。反射情形（零步）反
演 `seval`：值情形给「左」（`trm_is_val` 归一化后即 `True`，`hnfs*` 处理），
步进情形的 `reducible` 给「右」；多步情形反演 `seval`——值情形与「值不可步
进」矛盾（`inverts S` 自灭），步进情形把后继交给 `IHR`：

```coq
(* 练习（3 星，标准，必做）：seval 蕴含安全性（归纳于 steps）。 *)

Lemma seval_safe : forall s t Q,
  seval s t Q ->
  safe s t.
Proof using.
  introv M R. gen Q. induction R; intros.
  { inverts M. { left. hnfs*. } { right*. } }
  { rename H into S. inverts M. { inverts S. } { applys* IHR. } }
Qed.
```

**练习（3 星）seval_correct**——正确性。这次归纳 `seval`：值情形反演
`steps`，反射情形结论就是 `Q v s`（auto），多步情形「值不能步进」矛盾；步
进情形反演 `steps`，反射情形说明 `t` 本身是值——与 `reducible` 矛盾（拆开
`reducible`、反演那个不可能的 `step`），多步情形用归纳假设接力：

```coq
(* 练习（3 星，标准，必做）：seval 蕴含正确性。 *)

Lemma seval_correct : forall s t Q,
  seval s t Q ->
  correct s t Q.
Proof using.
  introv M. induction M; introv R.
  { inverts R as. { auto. } { introv S. inverts S. } }
  { rename H1 into IH. inverts R. { lets (?&?&R): H. inverts R. } applys* IH. }
Qed.
```

三条性质合起来就是 `seval` 的可靠性：

```coq
Lemma seval_sound : forall s t Q,
  seval s t Q ->
  terminates s t /\ safe s t /\ correct s t Q.
Proof using.
  introv M. splits.
  { applys* seval_terminates. }
  { applys* seval_safe. }
  { applys* seval_correct. }
Qed.
```

接下来要把 `eval` 搬到 `seval`。直接归纳会卡在「`seval` 是小步式、`eval`
是大步式」的形状错配上，所以先给 `seval` 装上一套**大步式求值规则**——每条
`eval` 规则在 `seval` 里的镜像。函数与递归函数定义先来（一步到值，唯一后继
用 `seval_val` 收）：

```coq
(* 为证 eval ⊆ seval，先为 seval 建立一套"大步式"求值规则。 *)

Lemma seval_fun : forall s x t1 Q,
  Q (val_fun x t1) s ->
  seval s (trm_fun x t1) Q.
Proof using.
  introv M. applys seval_step.
  { do 2 esplit. constructor. }
  { introv R. inverts R. { applys seval_val. applys M. } }
Qed.

Lemma seval_fix : forall s f x t1 Q,
  Q (val_fix f x t1) s ->
  seval s (trm_fix f x t1) Q.
Proof using.
  introv M. applys seval_step.
  { do 2 esplit. constructor. }
  { introv R. inverts R. { applys seval_val. applys M. } }
Qed.
```

`do 2 esplit` 是给 `reducible` 的两个存在量词各开一个洞，`constructor` 填上
对应的一步规则。函数应用的镜像规则稍麻烦：一步 beta 之后要把「等式前提」反
演掉才能用上传入的 `seval`：

```coq
Lemma seval_app_fun : forall s x v1 v2 t1 Q,
  v1 = val_fun x t1 ->
  seval s (subst x v2 t1) Q ->
  seval s (trm_app v1 v2) Q.
Proof using.
  introv E M. applys seval_step.
  { do 2 esplit. applys* step_app_fun. }
  { introv R. invert R; try solve [intros; false | introv R; inverts R].
    introv -> -> -> -> -> R. inverts E. applys M. }
Qed.

Lemma seval_app_fix : forall s f x v1 v2 t1 Q,
  v1 = val_fix f x t1 ->
  seval s (subst x v2 (subst f v1 t1)) Q ->
  seval s (trm_app v1 v2) Q.
Proof using.
  introv E M. applys seval_step.
  { do 2 esplit. applys* step_app_fix. }
  { introv R. invert R; try solve [intros; false | introv R; inverts R].
    introv -> -> -> -> -> R. inverts E. applys M. }
Qed.
```

**练习（5 星）seval_seq**——本章最难的练习之一，序列的大步式 `seval` 规
则。难点：`seval_step` 的第二前提要求「对**一切**一步后继」成立，而序列的后
继有两类（左侧子项步进、左侧已是值则跳过），必须逐类讨论。技巧是
`gen_eq Q1': Q1`——把中间后条件抽象成带等式的变量再归纳，使归纳假设可以换
后条件：

```coq
(* 练习（5 星，标准，必做）：seval 的序列规则——本章最难的练习之一。 *)

Lemma seval_seq : forall s t1 t2 Q1 Q,
  seval s t1 Q1 ->
  (forall s1 v1, Q1 v1 s1 -> seval s1 t2 Q) ->
  seval s (trm_seq t1 t2) Q.
Proof using.
  introv M1 M2. gen_eq Q1': Q1.
  induction M1; intros; subst.
  { apply seval_step.
    { do 2 esplit. applys step_seq. }
    { introv R. inverts R as R'. { inverts R'. } applys* M2. } }
  { rename t into t1, H1 into IH.
    destruct H as (s'&t'&RE). applys seval_step.
    { do 2 esplit. constructors. applys RE. }
    { introv R. inverts R as R'.
      { applys* IH R' M2. }
      { false. inverts RE. } } }
Qed.
```

逐块读。**情形一（`t1` 是值）**：`t1; t2` 一步跳到 `t2`（`step_seq`）；至于
「一切后继」，反演一步规则 `R`——若是上下文规则（值还能再步进？不可能，
`inverts R'` 自灭），若是 `step_seq` 则后继恰是 `t2`，用 `M2` 加上值情形的
`Q1 v s` 前提接力。**情形二（`t1` 可步进）**：先从 `reducible` 里取一条真实
步 `RE`，用上下文规则把它抬成整个序列的一步；「一切后继」反演 `R`——上下
文情形的后继仍是「序列」，交给归纳假设 `IH`（`IH R' M2`：`R'` 是 `t1` 的步
进、`M2` 是续体）；`step_seq` 情形则强制 `t1` 是值，与 `RE : step s t1 ...`
矛盾（值不可步进），`false` 后反演 `RE` 自灭。

**练习（5 星）seval_let**——let 版本，逐字符同构（把 `step_seq` 换成
`step_let`、后继多一层 `subst`）：

```coq
(* 练习（5 星，标准，选做）：let 版本，证明同上。 *)

Lemma seval_let : forall s x t1 t2 Q1 Q,
  seval s t1 Q1 ->
  (forall s1 v1, Q1 v1 s1 -> seval s1 (subst x v1 t2) Q) ->
  seval s (trm_let x t1 t2) Q.
Proof using.
  introv M1 M2. gen_eq Q1': Q1.
  induction M1; intros; subst.
  { apply seval_step.
    { do 2 esplit. applys step_let. }
    { introv R. inverts R as R'. { inverts R'. } applys* M2. } }
  { rename t into t1, H1 into IH.
    destruct H as (s'&t'&RE). applys seval_step.
    { do 2 esplit. constructors. applys RE. }
    { introv R. inverts R as R'.
      { applys* IH R' M2. }
      { false. inverts RE. } } }
Qed.
```

条件的镜像规则一行带过（一步展开 `if`，唯一后继交给 `M`）：

```coq
Lemma seval_if : forall s b t1 t2 Q,
  seval s (if b then t1 else t2) Q ->
  seval s (trm_if b t1 t2) Q.
Proof using.
  introv M. applys seval_step.
  { do 2 esplit. constructors*. }
  { introv R. inverts R; tryfalse. { applys M. } }
Qed.
```

**主定理 `seval_of_eval`**：对 `eval` 推导归纳，每个构造子用对应的镜像规
则。前八个情形（值/函数/应用/结构/条件）直接 `applys*`；原语操作情形则回到
小步本质——`do 2 esplit` 造出那一步，再反演「一切后继」。几个细节：
`step_rand 0` 取 `0` 当见证（前提 `0 <= 0 < n` 由 `n > 0` 用 `math` 关）；
`ref` 用有限映射库的 `exists_fresh` 造一个确实新鲜的地址；其余三个状态原语
的前提在上下文里现成：

```coq
(* 主定理：omni-big-step 蕴含小步式全正确性。 *)

Lemma seval_of_eval : forall s t Q,
  eval s t Q ->
  seval s t Q.
Proof using.
  introv M. induction M.
  { applys* seval_val. }
  { applys* seval_fun. }
  { applys* seval_fix. }
  { applys* seval_app_fun. }
  { applys* seval_app_fix. }
  { applys* seval_seq. }
  { applys* seval_let. }
  { applys* seval_if. }
  { applys seval_step.
    { do 2 esplit. applys* step_add. }
    { introv K. inverts K. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_div. }
    { introv K. inverts K. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_rand 0. math. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { forwards~ (p&D&N): (exists_fresh null s).
      do 2 esplit. applys* step_ref. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_get. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_set. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
  { applys seval_step.
    { do 2 esplit. applys* step_free. }
    { introv K. inverts K; tryfalse. applys* seval_val. } }
Qed.
```

三件套拼装完毕，**分离逻辑相对于小步语义的可靠性定理**就是三行：

```coq
(* 分离逻辑相对于小步语义的可靠性定理。 *)

Lemma soundness_small_step : forall t H Q,
  triple t H Q ->
  forall s, H s -> terminates s t /\ safe s t /\ correct s t Q.
Proof using.
  unfold triple. introv M Hs. specializes M Hs.
  lets R: seval_of_eval M. applys seval_sound R.
Qed.
```

## 97.13 直接基于 seval 的三元组

第二条路线：跳过 `eval`，直接把 triple 定义在 `seval` 上（记作 `striple`）。
可靠性是白送的（`seval_sound` 现成）：

```coq
(* ---------- 97.13 直接基于 seval 的三元组 ---------- *)

Definition striple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall (s:heap), H s -> seval s t Q.

Lemma striple_sound : forall t H Q,
  striple t H Q ->
  forall s, H s -> terminates s t /\ safe s t /\ correct s t Q.
Proof using. introv M Hs. specializes M Hs. applys seval_sound M. Qed.
```

但推理规则得从头证。后果规则的 `seval` 版仍是对推导归纳（值情形用
`WQ` 传后条件、步进情形用归纳假设传续体）：

```coq
Lemma seval_conseq : forall s t Q Q',
  seval s t Q' ->
  Q' ===> Q ->
  seval s t Q.
Proof using.
  introv M WQ. induction M.
  { applys seval_val. applys* WQ. }
  { rename H1 into IH.
    applys seval_step.
    { auto. }
    { introv HR. applys* IH. } }
Qed.

Lemma striple_conseq : forall t H' Q' H Q,
  striple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  striple t H Q.
Proof using.
  introv M MH MQ HF. applys seval_conseq M MQ. applys* MH.
Qed.
```

框架性质的 `seval` 版是全章最重的证明：小步执行与堆并入纠缠得深，得**双层
归纳**——外层对 `seval`（两个情形），内层在步进证明与后继上各再来一次。第
一块要证「抬起来的一步确实存在」：把 `reducible` 拆出一条 `step`，对这条
`step` 归纳；大多数构造子被 `constructors*` 原地抬起，例外是两条上下文规则
（用内层归纳假设 `IHR` 把子项的一步抬上来）、`ref`（框架堆并入后得重新选一
个对**整个**并堆新鲜的地址，`exists_fresh` 出场）与 get/set/free（
`indom_union_l` 证「在左半边」）：

```coq
Section stepsFrame.
#[local] Hint Constructors step.

Lemma seval_frame : forall h1 h2 t Q,
  seval h1 t Q ->
  Fmap.disjoint h1 h2 ->
  seval (h1 \u h2) t (Q \*+ (= h2)).
Proof using.
  introv M HD. gen h2. induction M; intros.
  { applys seval_val. applys* hstar_intro. }
  { rename H into M1, H0 into M2, H1 into IH2.
    applys seval_step.
    { unfolds reducible. clear M2 IH2. destruct M1 as (s'&t'&R).
      induction R; tryfalse; try solve [ do 2 esplit; constructors* ].
      { forwards* (s'&t'&R'): IHR. }
      { forwards* (s'&t'&R'): IHR. }
      { lets (p'&F&_): exists_fresh null (Fmap.union s h2). do 2 esplit.
        applys step_ref v p'. eauto. }
      { do 2 esplit. applys step_get. applys* Fmap.indom_union_l. }
      { do 2 esplit. applys step_set. applys* Fmap.indom_union_l. }
      { do 2 esplit. applys step_free. applys* Fmap.indom_union_l. } }
```

第二块是「抬起来的一步**走得干净**」：对并堆上任意一步 `R`，先 `cuts` 出
关键引理——这一步必形如 `s \u h2 → s1' \u h2`，即**程序只动左半边、框架原
样保留**（`gen_eq su: (s \u h2)` 把并堆命名后归纳）。六个手工情形与第一块
一一对应：两条上下文规则用内层归纳假设；`ref` 情形里「新地址不在并堆中」拆
成「不在左半边 ∪ 不在右半边」，新单元仍落左半边（`update_union_not_r`）；
get/set/free 又是那四则运算。证完交给 `IH2` 接力：

```coq
    { introv R. cuts (s1'&E'&D'&R'):
        (exists s1', s' = s1' \u h2 /\ Fmap.disjoint s1' h2 /\ step s t s1' t').
      { subst. applys* IH2. }
      clear M2 IH2.
      gen_eq su: (s \u h2). gen s.
      unfolds reducible. induction R; intros; subst; eauto.
      { destruct M1 as (s0&t0&R0).
        rename R into R1. forwards* (s1'&E&D&R1'): IHR s.
        { inverts R0. { eauto. } { inverts R1. } } }
      { destruct M1 as (s0&t0&R0).
        rename R into R1. forwards* (s1'&E&D&R1'): IHR s.
        { inverts R0. { eauto. } { inverts R1. } } }
      { rename H into D. rewrite Fmap.indom_union_eq in D. rew_logic in D.
        destruct D as (D1&D2). esplit. splits.
        { rewrite* Fmap.update_union_not_r. }
        { applys* Fmap.disjoint_update_not_r. }
        { eauto. } }
      { destruct M1 as (se&te&Re). inverts Re; tryfalse.
        rewrite* Fmap.read_union_l. }
      { destruct M1 as (se&te&Re). inverts Re; tryfalse. esplit. splits.
        { rewrite* Fmap.update_union_l. }
        { applys* Fmap.disjoint_update_l. }
        { eauto. } }
      { destruct M1 as (se&te&Re). inverts Re; tryfalse. esplit. splits.
        { rewrite* remove_disjoint_union_l. }
        { applys* Fmap.disjoint_remove_l. }
        { eauto. } } } }
Qed.

End stepsFrame.
```

`striple` 的框架规则随之与 97.8 的 `triple_frame` 完全同形：

```coq
Lemma striple_frame : forall t H Q H',
  striple t H Q ->
  striple t (H \* H') (Q \*+ H').
Proof.
  introv M. intros h HF. lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. specializes M M1. applys seval_conseq.
  { applys seval_frame M MD. } { xsimpl. intros h' ->. applys M2. }
Qed.
```

其余规则（如 let）还得照 97.12 那样为 `seval` 建大步式镜像。结论：这条路
**可行**但省不了多少力气——框架性质、大步式规则一样要证。omni-big-step 的
价值在于：它们只需证一次，且 `eval` 的规则形状与大步语义天然对齐。

## 97.14 准确定性语言与「内嵌框架规则」

最后一种情形：语言除分配外**完全确定**（本语言的 `step` 除去 `ref/rand` 外
都是确定的——若去掉 `rand`，`ref` 的地址选择是仅有的不确定）。此时标准大步
判断 `beval s t s' v`（作为 `Parameter` 抽象给出）配标准 Hoare 三元组就能用
——但**框架规则不成立**：

```coq
(* ---------- 97.14 准确定性语言与"内嵌框架规则" ---------- *)

Module BakedInFrame.

(* 设除分配外语言是确定性的：beval s t s' v 是标准 big-step 判断。 *)

Parameter beval : heap -> trm -> heap -> val -> Prop.

(* 标准 Hoare 三元组不满足框架规则（分配位置的选择会"吃掉"框架堆）。 *)

Definition hoare (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall (s:heap), H s ->
  exists (s':heap) (v:val), beval s t s' v /\ Q v s'.
```

反例直觉：`hoare (val_ref v) (p ~~> 1) (fun r => \exists q, r = val_loc q \*
q ~~> v)` 在「整堆只有一格」时可证；但加上框架 `p' ~~> 1` 后，语义允许把新
单元分配在 `p'` 上——存在量词只顾自己活下来，框架却被执行「吃掉」了。存在
量词太弱，管不住非确定的分配。

补救方案（Birkedal–Torp-Smith–Yang 2006，此后大量形式化沿用）：把框架规则
**烤进定义**——`btriple` 要求「带**任意**框架 `H'` 的 Hoare 三元组」都成
立：

```coq
(* 把框架规则"烤进"三元组的定义。 *)

Definition btriple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall (H':hprop), hoare t (H \* H') (Q \*+ H').
```

**练习（2 星）hoare_conseq**——先热身，Hoare 三元组的后果规则照旧成立（毕
竟它不涉及非确定性）：展开定义，用 `MH` 换前条件、`MQ` 换后条件。注意
`MH : H ==> H'` 用起来要喂**两个**参数（堆 `s` 与成员关系 `Hs`）：

```coq
(* 练习（2 星，标准，必做）：Hoare 三元组的后果规则。 *)

Lemma hoare_conseq : forall t H Q H' Q',
  hoare t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  hoare t H Q.
Proof using.
  introv M MH MQ. unfolds hoare. introv Hs.
  forwards (s'&v&HR&HQ): M s (MH s Hs).
  exists s' v. split. { exact HR. } { applys (MQ v) HQ. }
Qed.
```

**练习（3 星）btriple_frame**——`btriple` 天然满足框架规则，证明只用到星号
结合律：要证带框架 `H'` 的 `btriple`，对任意 `K` 需要
`hoare t ((H \* H') \* K) ((Q \*+ H') \*+ K)`；把原始 `btriple` 实例化成
`H' \* K` 的框架，再用后果规则把 `H \* (H' \* K)` 与
`(H \* H') \* K`（以及后条件侧的同款重排）对齐——两处都是 `xsimpl` 的拿手
戏：

```coq
(* 练习（3 星，标准，必做）：btriple 天然满足框架规则（用到星号结合律）。 *)

Lemma btriple_frame : forall t H Q H',
  btriple t H Q ->
  btriple t (H \* H') (Q \*+ H').
Proof using.
  introv M. intros K. unfolds btriple.
  applys hoare_conseq (M (H' \* K)).
  { xsimpl. }
  { intros v. xsimpl. }
Qed.
```

`btriple` 还有一个不提 `H'` 量词、直接用堆并与不相交性表述的**低层刻画**：
程序在「`h1` 满足前条件 + 不相交的 `h2`」上跑，结果必能拆成「程序那一半
`h1'` + 原样的 `h2`」。两者等价，证明就是星号的拆装：

```coq
(* btriple 的低层刻画：直接用堆并与不相交性表述。 *)

Definition btriple_lowlevel (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall h1 h2,
  Fmap.disjoint h1 h2 ->
  H h1 ->
  exists h1' v,
       Fmap.disjoint h1' h2
    /\ beval (h1 \u h2) t (h1' \u h2) v
    /\ Q v h1'.

Lemma btriple_iff_btriple_lowlevel : forall t H Q,
  btriple t H Q <-> btriple_lowlevel t H Q.
Proof using.
  unfold triple, btriple_lowlevel, hoare. iff M.
  { introv D P1.
    forwards (h'&v&HR&HQ): M (=h2) (h1 \u h2). { applys* hstar_intro. }
    destruct HQ as (h1'&h2'&N0&N1&N2&N3). subst.
    exists h1' v. auto. }
  { intros H' h. introv (h1&h2&N1&N2&D&U).
    forwards (h1'&v&D'&HR&HQ): M h1 h2; auto. subst.
    exists (h1' \u h2) v. split. { eauto. } { applys* hstar_intro. } }
Qed.
```

正向：取 `H' := (= h2)`、初始堆取 `h1 \u h2`（`hstar_intro` 见证它满足
`H \* (= h2)`），把结果的星号拆开即是低层陈述。反向照搬。低层版本对形式化
分离逻辑的某些扩展（如并发）更好用。

最后看推理规则怎么落在这套定义上。设 `beval` 的 let 规则（作为 `Parameter`
给出）：

```coq
Parameter beval_let : forall s1 s2 s3 v1 v2 x t1 t2,
  beval s1 t1 s2 v1 ->
  beval s2 (subst x v1 t2) s3 v2 ->
  beval s1 (trm_let x t1 t2) s3 v2.
```

**练习（3 星）hoare_let**——Hoare 版 let 规则：两次「存在结果」接力，再拼
`beval_let`：

```coq
(* 练习（3 星，标准，必做）：Hoare 三元组的 let 规则。 *)

Lemma hoare_let : forall x t1 t2 H Q Q1,
  hoare t1 H Q1 ->
  (forall v, hoare (subst x v t2) (Q1 v) Q) ->
  hoare (trm_let x t1 t2) H Q.
Proof using.
  introv M1 M2. unfolds hoare. introv Hs.
  forwards (s2&v1&HR1&HQ1): M1 s Hs.
  forwards (s3&v2&HR2&HQ2): (M2 v1) s2 HQ1.
  exists s3 v2. split. { applys beval_let HR1 HR2. } { exact HQ2. }
Qed.
```

**练习（3 星）btriple_let**——`btriple` 版 let 规则，把前两条拼装：对任意
框架 `K`，`M1 K` 给出第一步的 `hoare`（中间后条件取常量族 `Q1 \*+ K`），
每个结果 `v` 的续体由 `M2 v K` 给出，缺口只是
`(Q1 \*+ K) v ==> Q1 v \* K`——按记法展开二者**定义相等**，`himpl_refl` 即
关：

```coq
(* 练习（3 星，标准，必做）：btriple 的 let 规则——把上面两条拼起来。 *)

Lemma btriple_let : forall x t1 t2 Q1 H Q,
  btriple t1 H Q1 ->
  (forall v1, btriple (subst x v1 t2) (Q1 v1) Q) ->
  btriple (trm_let x t1 t2) H Q.
Proof using.
  introv M1 M2. intros K. unfolds btriple.
  applys hoare_let (M1 K).
  { intros v. applys hoare_conseq ((M2 v) K).
    { applys himpl_refl. }
    { applys qimpl_refl. } }
Qed.

End BakedInFrame.
```

对照之下更能体会 omni-big-step 的好处：`eval` 的 let 规则是**定义的一部分**
（`eval_let`），`btriple` 的 let 规则却要在定义之外重新推导——「内嵌框架」
把复杂度从语义挪到了规则证明里。

## 97.15 小结

```coq
(* ---------- 97.15 小结 ----------
   1) triple 定义在 omni-big-step 语义 eval 上，天然表达非确定性语言的全正确性；
   2) 结构规则（框架/后果/抽取）都可由 eval 的逐条性质导出，框架规则的
      关键在于分配规则对"新鲜位置"的约束随堆增大而收紧；
   3) eval ⊆ seval 给出相对于小步语义的可靠性（终止+安全+正确）；
   4) 对准确定性语言，可用"内嵌框架规则"从标准 Hoare 三元组定义 triple。 *)
```

把全章串成一句话：**`triple` = 对一切初始状态满足 `H` 的 `s`，`eval s t
Q`**；而 `eval` 用「后条件当集合」把非确定性的「一切执行」编码进归纳规则，
于是框架规则的核心变成一句「新鲜位置的约束随堆增大而收紧」，可靠性定理
`soundness_small_step` 也不过是把 `eval` 逐构造子翻译成小步世界。

### 实测坑位（rocq 9.1.1 实编译经验）

- **`xsimpl` 的收尾边界**：`xsimpl` 把蕴含目标归一化后，若剩的是**纯 Prop**
  （如 `P -> P`）不会自动收尾，需补 `auto`；剩下的仍是堆谓词蕴含（两侧相同）
  才会自动关闭。`{ xsimpl. }` 报 "This proof is focused, but cannot be
  unfocused this way" 多半是这个原因。
- **蕴含要用满两个参数**：`MH : H ==> H'` 是 `forall h, H h -> H' h`，喂成员
  关系时写 `MH s Hs` 而不是 `MH Hs`（后者把 `Hs : H s` 往堆的位置上塞，报
  "expected heap"）。
- **`applys L (定理 参数)` 的显式参数顺序**：`Set Implicit Arguments` 下类型
  参数（如 `A`）自动隐去，显式参数从第一个非类型参数数起——
  `triple_hexists2 Hof (fun (x:A) => Q) M` 里 `Hof` 在 `Qof` 前，漏写会得到
  "expected hprop" 一类的类型错位。
- **`inverts R as R'`** 给反演出的第一条假设命名，方便后续 `inverts R'` 处
  理「值不能步进」的矛盾分支；`invert R; try solve [intros; false | ...]`
  （注意 `invert` 非 `inverts`）是 `seval_app_fun` 里处理五重等式前提的官方
  写法。
- **`gen_eq Q1': Q1`** 是 `seval_seq` 的钥匙：直接 `induction M1` 会让归纳假
  设钉死在 `Q1` 上用不了；带上等式一般化后 `intros; subst` 恢复，归纳假设
  才能对任意中间后条件复用。
- 本章在模块外**遮蔽**（shadowing）了库里的 `eval`/`triple`/`step`/`seval`
  等名字（教程自包含复刻原书定义，与库中定义逐条相同）——这是原书自己的做
  法，合法且不影响库战术（它们按全名引用库对象）。

下一章（98）继续用这套 `triple` 定义，证明与语言构件相关的**推理规则**
（let、if、应用、原语操作的规格），把 93 章里「黑盒规格表」的每一行都变成
定理。
