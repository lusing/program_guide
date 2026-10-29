# 101. 最弱前条件生成器：wpgen 与 x-tactics

对应示例：`../examples/101_slf_wpgen.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

取材 Software Foundations 卷六 *Separation Logic Foundations*（v1.0）的 *WPgen* 章。

---

## 101.0 本章要解决什么问题

第 100 章我们引入了最弱前条件 `wp t Q`：它把"证明三元组 `triple t H Q`"归结为"证明蕴含 `H ==> wp t Q`"。但 `wp` 是用操作语义 `eval` 直接定义的语义对象，它本身不能计算——面对一个具体程序，我们仍然要靠手工套用推理规则（如第 98 章 `triple_incr` 那样一步步 `applys triple_let`）来消解程序结构。

本章构造一个**按项的语法结构递归定义的函数 `wpgen`**，使得：

```
H ==> wpgen nil t Q    蕴含    triple t H Q
```

`wpgen` 逐个构造子地展开程序：遇到 `let` 就产生 let 形状的公式，遇到函数调用就产生一个"待解的三元组"占位。由于公式形状与源代码一一对应，我们就能写出一族 **x-tactics**（`xwp`、`xapp`、`xlet`、`xfun`……），每条战术恰好剥掉公式的一层语法外壳。这正是第 93、94 章一直在用的 `xwp. xapp. xsimpl.` 背后的机器——本章把这台机器完整地造出来。

围绕这个目标，原书把构造分成四步，本章示例也按同样的脉络展开：

1. 先给出**不带 `mkstruct` 的可执行生成器**，并证明它满足后果规则与框架规则（练习 `wpgen_conseq`、`wpgen_frame`）；
2. 引入 `formula` 类型与一族辅助定义（`wpgen_val`、`wpgen_let` 等）改善输出可读性，再在生成器外面包一层 `mkstruct`，把结构规则"焊死"在公式里；同时给出**完整的可靠性证明**——原书此处置为公理，证明留到下一章，本章复用 SLF 库中已证明的叶结点引理提前补全；
3. 实现全部 x-lemmas 与 x-tactics，并处理**局部函数**的两种验证风格（内联 `xletval`/`xappfun` 与模块化 `xfun`）；
4. 升级生成器使其**递归进入局部函数体**（`wpgen_fun`/`wpgen_fix`），并完成压轴练习 `triple_forloop`——用局部递归函数编码 for 循环。

示例文件整体结构如下（三个模块分别对应上面第 1、2–4 步中的教学版生成器与最终形态）：

```coq
(* 101 最弱前条件生成器：延迟替换、特征公式、结构规则与 x-tactics *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 WPgen 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax DemoPrograms.

Implicit Types n m i a b : int.
Implicit Types p : loc.
Implicit Types v : val.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
```

---

## 101.1 替换上下文：让 wpgen 成为结构递归函数

### 101.1.1 问题：朴素定义不是结构递归

对每个语法构造子，我们希望 `wpgen` 的行为与 `wp` 的推理规则（第 100 章）一一对应：

- 值：`wp` 规则是 `Q v ==> wp (trm_val v) Q`，所以定义 `wpgen (trm_val v) Q := Q v`；
- 序列：规则是 `wp t1 (fun v => wp t2 Q) ==> wp (t1; t2) Q`，所以定义 `wpgen (trm_seq t1 t2) Q := wpgen t1 (fun v => wpgen t2 Q)`；
- let：规则涉及代入，朴素定义是 `wpgen t1 (fun v => wpgen (subst x v t2) Q)`。

问题出在 let 分支：递归调用发生在 `subst x v t2` 上，而它**不是 `t` 的子项**——Rocq 拒绝这个定义（不满足结构递归）。

### 101.1.2 解法：把替换推迟到叶结点

做法是给 `wpgen` 增加一个**替换上下文** `E : ctx`，约定：

> `wpgen E t` 解释为 "`isubst E t` 的最弱前条件"。

其中 `isubst E t` 表示把 `E` 中所有绑定**同时**代入 `t`。这些定义由 SLF 库（`LibSepReference`）提供，其形状如下（讲解用，非示例代码）：

```coq
Definition ctx : Type := list (var * val).

Fixpoint lookup (x:var) (E:ctx) : option val :=
  match E with
  | nil => None
  | (y,v)::E1 => if var_eq x y then Some v else lookup x E1
  end.

Fixpoint rem (x:var) (E:ctx) : ctx := ...   (* 从 E 中删去关于 x 的绑定 *)

Fixpoint isubst (E:ctx) (t:trm) : trm :=
  match t with
  | trm_var x => match lookup x E with None => t | Some v => v end
  | trm_fun x t1 => trm_fun x (isubst (rem x E) t1)
  | trm_let x t1 t2 => trm_let x (isubst E t1) (isubst (rem x E) t2)
  ... end.
```

三个要点：

- **变量**：到达变量时才查表。查到 `Some v` 就返回该值的前条件；查不到说明遇到了悬空自由变量——源程序本就非法——返回 `\[False]`（任何状态都不满足，对应"永假的前条件"）。这也解释了为什么可以为 `trm_var` 分支给出合法（但无用）的规则：`wp_var : \[False] ==> wp (trm_var x) Q`。
- **遮蔽**：穿过绑定 `x` 时必须先 `rem x E`，否则外层同名绑定会错误地穿透进去。
- **let 不再代入**：`wpgen E (trm_let x t1 t2) Q := wpgen E t1 (fun v => wpgen ((x,v)::E) t2 Q)`——把绑定**记进上下文**而非立刻替换。递归调用发生在真正的子项 `t1`、`t2` 上，结构递归成立。

### 101.1.3 不带 mkstruct 的可执行生成器

下面是第一版完整定义。注意两个"叶结点"：

- **函数调用** `trm_app`：一般的被调函数值来自规格（`triple`），不一定形如 `val_fun x t1`，所以公式直接**存在量化一个前条件 H**，要求 `triple (isubst E t) H Q` 成立——把"这个调用该怎么验证"原样交给用户；
- **条件** `trm_if`：运行时条件可能是任意值 `v0`，规则只对布尔值有效，于是公式存在量化布尔 `b`，要求条件项确实等于 `val_bool b`，再按 `b` 的真假二选一。

```coq
(* ---------- 101.1 不带 mkstruct 的可执行生成器 ---------- *)

Module SimpleGenerator.

(* wpgen E t Q 表示 isubst E t 的一个充分前条件。let 不立即做 subst，
   而把绑定加入 E；变量、应用与闭包在叶结点读取或应用整个 E。 *)

Fixpoint wpgen (E:ctx) (t:trm) (Q:val->hprop) : hprop :=
  match t with
  | trm_val v => Q v
  | trm_fun x t1 => Q (val_fun x (isubst (rem x E) t1))
  | trm_fix f x t1 => Q (val_fix f x (isubst (rem x (rem f E)) t1))
  | trm_seq t1 t2 => wpgen E t1 (fun v => wpgen E t2 Q)
  | trm_let x t1 t2 => wpgen E t1 (fun v => wpgen ((x,v)::E) t2 Q)
  | trm_var x =>
       match lookup x E with
       | Some v => Q v
       | None => \[False]
       end
  | trm_app v1 v2 => \exists H, H \* \[triple (isubst E t) H Q]
  | trm_if t0 t1 t2 =>
      \exists (b:bool), \[t0 = trm_val (val_bool b)]
        \* (if b then (wpgen E t1) Q else (wpgen E t2) Q)
  end.
```

函数定义分支（`trm_fun`/`trm_fix`）此版本**不**递归进入函数体，而是像值一样处理：直接把"代入后的闭包"作为结果值交给后条件 `Q`。101.5 节会升级这一点。

### 101.1.4 练习（3 星，标准，特别有用）：wpgen_conseq

> **题目**：证明 `wpgen E t` 与 `wp t` 一样对后条件满足后果规则：
> `Q1 ===> Q2 -> wpgen E t Q1 ==> wpgen E t Q2`。
> 提示：`intros t. induction t.`

这个练习是理解生成器的最好方式：它强迫你逐个构造子检查公式的形状。完整解答：

```coq
(* 练习（3 星）：生成公式对后条件满足后果规则。应用叶结点把归纳
   转化为 triple_conseq；序列和 let 则把两段归纳假设接起来。 *)

Lemma wpgen_conseq : forall t E Q1 Q2,
  Q1 ===> Q2 ->
  wpgen E t Q1 ==> wpgen E t Q2.
Proof using.
  intros t. induction t; intros E Q1 Q2 WQ; simpl.
  { applys WQ. }
  { destruct (lookup v E).
    { applys WQ. }
    { xsimpl. } }
  { applys WQ. }
  { applys WQ. }
  { xpull. intros H M. xsimpl. applys triple_conseq M WQ. xsimpl. }
  { applys IHt1. intros r. applys IHt2. applys WQ. }
  { applys IHt1. intros r. applys IHt2. applys WQ. }
  { xpull. intros b Eb. xsimpl b. { auto. }
    case_if.
    { applys IHt2. applys WQ. }
    { applys IHt3. applys WQ. } }
Qed.
```

逐分支讲解（`induction t` 产生的 8 个分支按构造子顺序排列）：

- **值 / 函数 / 递归函数**（第 1、3、4 分支）：公式就是 `Q1 v ==> Q2 v`，直接用 `applys WQ`。
- **变量**（第 2 分支）：按 `lookup` 结果分情况。查到 `Some v` 时同上；查不到时两边都是 `\[False]`，`xsimpl` 关闭。
- **应用**（第 5 分支）：`xpull` 抽出存在量化的 `H` 与三元组假设 `M : triple (isubst E t) H Q1`；再 `xsimpl` 重新提供 `H`，新三元组由**后果规则** `triple_conseq M WQ` 从 `M` 弱化得到。注意最后的 `xsimpl` 把"剩余目标 `H ==> H`"收掉。
- **序列与 let**（第 6、7 分支）：形状完全一致——对第一段用归纳假设 `IHt1`，对续体中的每个结果值 `r` 用 `IHt2` 与 `WQ`。
- **条件**（第 8 分支）：抽出布尔见证 `b` 与等式 `Eb`；`xsimpl b` 重新提供见证（`{ auto. }` 用 `Eb` 证明纯等式），随后 `case_if` 按 `b` 分派给两个归纳假设。

### 101.1.5 练习（4 星，标准，特别有用）：wpgen_frame

> **题目**：证明 `wpgen E t` 与 `wp t` 一样满足框架规则：
> `(wpgen E t Q) \* H ==> wpgen E t (Q \*+ H)`。序列情形不容易。

```coq
(* 练习（4 星）：生成公式满足框架规则。序列与 let 的关键是
   先对第一段使用框架归纳假设，再用 wpgen_conseq 调整后条件。 *)

Lemma wpgen_frame : forall t E H Q,
  (wpgen E t Q) \* H ==> wpgen E t (Q \*+ H).
Proof using.
  intros t. induction t; intros E H Q; simpl.
  { xsimpl. }
  { destruct (lookup v E); xsimpl. }
  { xsimpl. }
  { xsimpl. }
  { xpull. intros H1 M. xsimpl (H1 \* H). applys triple_frame M. }
  { applys himpl_trans (IHt1 E H (fun v => wpgen E t2 Q)).
    applys wpgen_conseq. intros r. applys IHt2. }
  { applys himpl_trans (IHt1 E H (fun r => wpgen ((v,r)::E) t2 Q)).
    applys wpgen_conseq. intros r. applys IHt2. }
  { xpull. intros b Eb. xsimpl b. { auto. } case_if.
    { applys IHt2. }
    { applys IHt3. } }
Qed.
```

逐分支讲解：

- **值 / 变量 / 函数 / 递归函数**（第 1–4 分支）：公式两侧都是"某个后条件作用于固定值"，`\* H` 在分离合取上滑动即可，`xsimpl` 全自动。
- **应用**（第 5 分支）：这是框架规则在叶结点的落点——从 `M : triple t H1 Q` 用 `triple_frame` 得到 `triple t (H1 \* H) (Q \*+ H)`，新公式里存在量化的前条件取 `H1 \* H`（`xsimpl (H1 \* H)` 显式提供见证）。
- **序列与 let**（第 6、7 分支，本题难点）：目标两侧的"公式骨架"不同——左边第一段的后条件是 `fun _ => wpgen E t2 Q`（不带框架），右边是 `fun _ => wpgen E t2 (Q \*+ H)`（带框架）。不能直接用 `IHt1` 完事，需要两步：
  1. 先对第一段用**它自己后条件形态**下的归纳假设，即 `IHt1 E H (fun v => wpgen E t2 Q)`，把 `H` 框架进第一段，得到
     `(wpgen E t1 (fun v => wpgen E t2 Q)) \* H ==> wpgen E t1 (fun v => wpgen E t2 Q \*+ H)`；
  2. 再用上一小节证明的 **`wpgen_conseq`** 把第一段的后条件从 `fun v => wpgen E t2 Q \*+ H` 弱化为 `fun v => wpgen E t2 (Q \*+ H)`——后者对每个 `r` 恰好是 `IHt2`。两步用 `himpl_trans` 串接。

  这正是"`wpgen_conseq` 先行"的典型用法：框架与后果规则在组合语言构造时互相配合。
- **条件**（第 8 分支）：与 `wpgen_conseq` 同样抽见证、`case_if` 后分别用 `IHt2`/`IHt3`；由于框架 `H` 在两个分支外侧对称分布，这里无需再调整后条件。

```coq
End SimpleGenerator.
```

---

## 101.2 特征公式：可读性、mkstruct 与可靠性

### 101.2.1 formula 类型与辅助定义

第一版 `wpgen` 的输出虽然正确但难以阅读。原书做了三步改造：把 `fun Q => ...` 下沉到 `match` 的每个分支；为每个分支起一个名字（`wpgen_val`、`wpgen_seq`……）；再为每个名字配一条记法（`Val v`、`Seq F1; F2`……）。这些定义都在 SLF 库中（第 102 章将逐条证明其性质），形状如下（讲解用）：

```coq
Definition formula : Type := (val->hprop)->hprop.

Definition wpgen_val (v:val) : formula := fun Q => Q v.
Definition wpgen_fail : formula := fun Q => \[False].
Definition wpgen_var (E:ctx) (x:var) : formula :=
  match lookup x E with None => wpgen_fail | Some v => wpgen_val v end.
Definition wpgen_app (t:trm) : formula := fun Q => \exists H, H \* \[triple t H Q].
Definition wpgen_seq (F1 F2:formula) : formula := fun Q => F1 (fun v => F2 Q).
Definition wpgen_let (F1:formula) (F2of:val->formula) : formula := fun Q =>
  F1 (fun v => F2of v Q).
Definition wpgen_if (t:trm) (F1 F2:formula) : formula := fun Q =>
  \exists (b:bool), \[t = trm_val (val_bool b)] \* (if b then F1 Q else F2 Q).
```

`formula` 就是"吃后条件、吐堆谓词"的谓词转换器类型。改造后，`wpgen` 在 `incr` 的函数体上算出的公式显示为：

```
Let n := App val_get p in
Let m := App (val_add n) 1 in
App (val_set p) m
```

与源代码几乎逐字对应——这就是**特征公式**（characteristic formula）这一名字的由来：它只由程序语法决定，与规格、不变式完全无关。

### 101.2.2 mkstruct：把结构规则焊进公式

`wpgen_conseq` 与 `wpgen_frame` 说明生成公式"支持"结构规则，但在验证中途公式已经被 `simpl` 展开，再想套用这两条引理很不方便。解决办法是在 `wpgen` 递归的**每一层**都包一个谓词转换器 `mkstruct`：

```text
mkstruct F Q  :=  \Exists Q1, F Q1 \* (Q1 \--* Q)
```

直觉：`mkstruct F` 描述的程序先以某个更精细的后条件 `Q1` 满足 `F`，再用魔法杖把"剩余状态"接到目标后条件 `Q` 上——一次到位地编码了框架规则 + 后果规则（对比第 100 章的 `wp_ramified`）。它需要四条性质，证明只用到第 99 章的魔法杖工具：

```coq
(* ---------- 101.2 带 mkstruct、但不递归进入函数体的生成器 ---------- *)

Module NonRecursive.

(* mkstruct F Q = exists Q1, F Q1 * (Q1 --* Q)。它把框架与后果规则
   打包进公式；以下四个性质只使用分离蕴含与魔法杖即可证明。 *)

Lemma mkstruct_frame' : forall F H Q,
  (mkstruct F Q) \* H ==> mkstruct F (Q \*+ H).
Proof using. intros. unfold mkstruct. xpull. intros Q'. xsimpl*. Qed.

Lemma mkstruct_conseq' : forall F Q1 Q2,
  Q1 ===> Q2 ->
  mkstruct F Q1 ==> mkstruct F Q2.
Proof using. introv WQ. unfold mkstruct. xpull. intros Q'. xsimpl*. Qed.

Lemma mkstruct_erase' : forall F Q,
  F Q ==> mkstruct F Q.
Proof using. intros. unfold mkstruct. xsimpl. Qed.

Lemma mkstruct_monotone' : forall F1 F2 Q,
  (forall Q, F1 Q ==> F2 Q) ->
  mkstruct F1 Q ==> mkstruct F2 Q.
Proof using. introv WF. unfolds mkstruct. xpull. intros Q'. xchanges WF. Qed.
```

讲解（对应原书对 `mkstruct` 的要求）：

- **`mkstruct_frame'`**（框架）：从 `F Q' \* (Q' \--* Q) \* H` 出发，取新的中间后条件 `Q' \*+ H`：`F` 的部分原样保留，魔法杖 `(Q' \--* Q)` 与 `H` 合并成 `Q' \*+ H \--* Q \*+ H`。`xsimpl*` 自动完成"重组 + 关闭"。
- **`mkstruct_conseq'`**（后果）：从 `Q' \--* Q1` 与 `Q1 ===> Q2` 得 `Q' \--* Q2`（魔法杖对右操作数单调）。
- **`mkstruct_erase'`**（擦除）：不需要结构规则时应当能丢掉 `mkstruct` 外壳。取 `Q1 := Q`，魔法杖退化为恒等（`Q \--* Q` 被空堆满足），这正是 `xsimpl` 干的事。
- **`mkstruct_monotone'`**（协变）：证明可靠性时需要它把"内层公式可靠"升级为"包壳后仍可靠"。

### 101.2.3 第二版生成器与它的可靠性

现在给出带 `mkstruct`、但仍不递归进入函数体的生成器：

```coq
Fixpoint wpgen (E:ctx) (t:trm) : formula :=
  mkstruct (match t with
  | trm_val v => wpgen_val v
  | trm_var x => wpgen_var E x
  | trm_fun x t1 => wpgen_val (val_fun x (isubst (rem x E) t1))
  | trm_fix f x t1 => wpgen_val (val_fix f x (isubst (rem x (rem f E)) t1))
  | trm_app t1 t2 => wpgen_app (isubst E t)
  | trm_seq t1 t2 => wpgen_seq (wpgen E t1) (wpgen E t2)
  | trm_let x t1 t2 => wpgen_let (wpgen E t1) (fun v => wpgen ((x,v)::E) t2)
  | trm_if t0 t1 t2 => wpgen_if (isubst E t0) (wpgen E t1) (wpgen E t2)
  end).
```

原书在此处写 `Parameter wpgen_sound : ...` 把可靠性公理化，推迟到下一章。本教程不愿让示例携带任何未证明假设，于是提前给出完整证明——方法是把下一章 `formula_sound` 的归纳骨架搬过来，复用 SLF 库中**已经证明**的各叶结点可靠性引理（`wpgen_val_sound`、`wpgen_seq_sound` 等），只为"把闭包当值"的两个分支补两条专属引理：

```coq
(* 本章不把可靠性留作公理。复用库中各叶结点的可靠性引理，
   对这个教学版生成器作结构归纳，即得完整证明。
   函数定义分支把闭包当作值处理，需要下面两条专属引理：
   它们只是 wp_fun / wp_fix 换了个包装。 *)

Lemma wpgen_fun_val_sound : forall x t1,
  formula_sound (trm_fun x t1) (wpgen_val (val_fun x t1)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fun. Qed.

Lemma wpgen_fix_val_sound : forall f x t1,
  formula_sound (trm_fix f x t1) (wpgen_val (val_fix f x t1)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fix. Qed.
```

其中 `formula_sound t F` 定义为 `forall Q, F Q ==> wp t Q`（"F 是 t 的可靠公式"）。两条引理一行即证：`wpgen_val v Q` 就是 `Q v`，而 `wp_fun`/`wp_fix`（第 100 章）恰说 `Q (val_fun x t1) ==> wp (trm_fun x t1) Q`。

主归纳：

```coq
Lemma wpgen_sound_induct : forall E t,
  formula_sound (isubst E t) (wpgen E t).
Proof using.
  intros. gen E. induction t; intros; simpl; applys mkstruct_sound.
  { applys wpgen_val_sound. }
  { rename v into x. unfold wpgen_var. case_eq (lookup x E).
    { intros v EQ. applys wpgen_val_sound. }
    { intros N. applys wpgen_fail_sound. } }
  { applys wpgen_fun_val_sound. }
  { applys wpgen_fix_val_sound. }
  { applys wpgen_app_sound. }
  { applys wpgen_seq_sound. { applys IHt1. } { applys IHt2. } }
  { rename v into x. applys wpgen_let_sound.
    { applys IHt1. }
    { intros v. rewrite <- isubst_rem. applys IHt2. } }
  { applys wpgen_if_sound. { applys IHt2. } { applys IHt3. } }
Qed.
```

证明结构（下一章将逐个展开库引理的内部证明）：

- 每个分支先统一 `applys mkstruct_sound`：若内层公式可靠，包上 `mkstruct` 仍可靠（它只增加可用规则，不改变语义）；其内部用到 `mkstruct_wp`——`mkstruct (wp t) = wp t`，因为 `wp` 天然满足全部结构规则。
- **变量**分支按 `lookup` 结果分派到 `wpgen_val_sound` 或 `wpgen_fail_sound`（后者一行：`\[False]` 蕴含一切）。
- **let** 分支的续体归纳假设需要对每个 `v` 成立，中间用库引理 `isubst_rem : isubst E (subst x v t) = isubst ((x,v)::rem x E) t`… 把 `IHt2` 的前提整理成 `wpgen_let_sound` 要求的形状。
- **条件**分支注意归纳变量编号：`t0` 没有归纳假设（它只被 `isubst` 求值后出现在纯等式里），两个分支对应 `IHt2`/`IHt3`。

由它立刻得到 `xwp` 的核心引理——把"函数调用的三元组"转成"函数体的 `wpgen` 证明义务"：

```coq
Lemma triple_app_fun_from_wpgen : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv M1 M2. applys triple_app_fun M1.
  rewrite subst_eq_isubst_one. rewrite <- wp_equiv.
  xchange M2. applys wpgen_sound_induct.
Qed.
```

讲解：`triple_app_fun`（第 98 章）要求证 `triple (subst x v2 t1) H Q`；用 `wp_equiv` 转成 `H ==> wp (subst x v2 t1) Q`，再用库引理 `subst_eq_isubst_one : subst x v t = isubst ((x,v)::nil) t` 把目标里的项换成 `isubst` 形态——`wpgen_sound_induct` 恰好终结证明。这条引理就是 `xwp` 战术的全部数学内容。

### 101.2.4 x-lemmas：每条引理剥一层壳

对每个公式构造子配一条"消去引理"，统称 x-lemmas：

```coq
(* 每条 x-lemma 消去公式的一层语法外壳。这里的 xapp_lemma 采用
   三分支形式，便于看清规格、前条件划分和后条件拼接。 *)

Lemma xstruct_lemma' : forall F H Q,
  H ==> F Q ->
  H ==> mkstruct F Q.
Proof using. introv M. xchange M. applys mkstruct_erase. Qed.

Lemma xval_lemma' : forall v H Q,
  H ==> Q v ->
  H ==> wpgen_val v Q.
Proof using. introv M. applys M. Qed.

Lemma xlet_lemma' : forall H F1 F2of Q,
  H ==> F1 (fun v => F2of v Q) ->
  H ==> wpgen_let F1 F2of Q.
Proof using. introv M. xchange M. Qed.

Lemma xseq_lemma' : forall H F1 F2 Q,
  H ==> F1 (fun v => F2 Q) ->
  H ==> wpgen_seq F1 F2 Q.
Proof using. introv M. xchange M. Qed.

Lemma xapp_lemma' : forall t Q1 H1 H2 H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  H ==> wpgen_app t Q.
Proof using.
  introv M WH WQ. unfold wpgen_app. xsimpl. applys* triple_conseq_frame M.
Qed.

Lemma xwp_lemma : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using. introv M1 M2. applys* triple_app_fun_from_wpgen. Qed.
```

讲解：

- `xstruct_lemma'` 是 `mkstruct_erase'` 的改述：公式不需要结构规则时直接脱壳。其余三条 val/let/seq 引理只是定义的展开（`xchange` 完成重写），列出来是为了给战术一个统一的"apply 目标"。
- **`xapp_lemma'` 是最常用的一条**，三个前提各司其职：
  1. `triple t H1 Q1`——被调函数的规格；
  2. `H ==> H1 \* H2`——把当前状态切成"规格要的 H1"与"留下不动的 H2"（框架规则的分离）；
  3. `Q1 \*+ H2 ===> Q`——规格后条件拼回框架后得到目标后条件（后果规则）。

  三者合起来正是第 98 章 `triple_conseq_frame`（后果-框架合并规则）的应用。证明中 `unfold wpgen_app. xsimpl.` 负责"提供存在量化的 H := H1 \* H2 并展开纯命题"。
- `xwp_lemma` 就是上节的 `triple_app_fun_from_wpgen` 换名，供 `xwp` 调用。

### 101.2.5 从引理到战术

把 x-lemmas 包装成战术，机器人式的簿记（剥 `mkstruct`、处理 seq/let 外壳、从规格数据库检索）全部自动化。由于库中的 `xwp`/`xapp` 等名字绑定在**库版生成器**上，教学版生成器需要一套平行的战术（加 `_nr` 后缀）：

```coq
Tactic Notation "xwp_nr" :=
  intros; applys xwp_lemma;
  [ first [ reflexivity | eassumption ]
  | simpl; unfold wpgen_var; simpl ].

Tactic Notation "xstruct_nr" :=
  applys xstruct_lemma'.

Tactic Notation "xstruct_nr_if_needed" :=
  try match goal with |- ?H ==> mkstruct ?F ?Q => xstruct_nr end.

Tactic Notation "xval_nr" :=
  xstruct_nr_if_needed; applys xval_lemma'.

Tactic Notation "xlet_nr" :=
  xstruct_nr_if_needed; applys xlet_lemma'.

Tactic Notation "xseq_nr" :=
  xstruct_nr_if_needed; applys xseq_lemma'.

Tactic Notation "xseq_xlet_nr_if_needed" :=
  try match goal with |- ?H ==> mkstruct ?F ?Q =>
  match F with
  | wpgen_seq ?F1 ?F2 => xseq_nr
  | wpgen_let ?F1 ?F2of => xlet_nr
  end end.

Tactic Notation "xapp_nr" constr(E) :=
  xseq_xlet_nr_if_needed; xstruct_nr_if_needed;
  applys xapp_lemma' E; [ xsimpl | xpull ].

Tactic Notation "xapp_nr" :=
  xseq_xlet_nr_if_needed; xstruct_nr_if_needed;
  applys xapp_lemma'; [ solve [ eauto with triple ] | xsimpl | xpull ].
```

讲解：

- `xwp_nr` 先处理"被调函数确为已知闭包"的等式证明（`reflexivity` 或从上下文假设），再 `simpl` 让 `wpgen` 真正**算出**函数体的公式。技术细节：`simpl` 之后还需 `unfold wpgen_var` 再 `simpl`，否则上下文查找卡在 `wpgen_var` 的 `match` 上不化简。
- `xstruct_nr_if_needed` / `xseq_xlet_nr_if_needed` 用 `try match goal` 按**当前公式头部的形状**选择动作——这是 x-tactics "由程序结构驱动证明"的机制核心：公式长什么样，战术就做什么。
- 带参 `xapp_nr E` 显式给规格；无参 `xapp_nr` 用 `eauto with triple` 从第 98 章建立的规格数据库里检索（`triple_get`、`triple_add` 等都注册在内）。两种形态都内置 `xsimpl`（切分状态）与 `xpull`（抽出规格后条件里的存在量词与纯事实）。

### 101.2.6 用 x-lemmas 手工验证 incr

下面把 `incr`（来自 `DemoPrograms`，即第 98 章的 `fun p -> let n = !p in let m = n+1 in p := m`）的验证一步步展开。对照第 98 章手工版：每条 `applys xstruct_lemma'`/`xlet_lemma'`/`xapp_lemma'` 恰好对应源代码的一个构造子，`?Q1` 型后条件不再是证明负担：

```coq
(* incr 的完整 x-lemmas 证明：每一步对应源代码的一个构造。 *)

Lemma triple_incr_with_xlemmas : forall (p:loc) (n:int),
  triple (trm_app incr p)
    (p ~~> n)
    (fun _ => p ~~> (n+1)).
Proof using.
  intros. applys xwp_lemma. { reflexivity. }
  simpl. unfold wpgen_var. simpl.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_get. } { xsimpl. }
  xpull; intros ? ->.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_add. } { xsimpl. }
  xpull; intros ? ->.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_set. } { xsimpl. }
  xsimpl.
Qed.

#[global] Hint Resolve triple_incr_with_xlemmas : triple.
```

讲解：`applys xwp_lemma` 后目标变为 `p ~~> n ==> wpgen (("p",p)::nil) 函数体 Q`；`simpl` 算出公式（三个嵌套的 `Let`，每层带 `mkstruct`）。之后的三组 `xlet_lemma' + xapp_lemma'` 分别消解 `!p`、`n+1`、`p := m` 三次调用；每次 `xpull; intros ? ->` 把规格后条件 `\[r = ...]` 中的结果值代入后续公式。最后的 `xsimpl` 处理算术（`n+1` 的自反性）。把该引理注册进 `triple` 数据库，供后续 `xapp_nr` 自动检索。

### 101.2.7 练习（2 星，标准，特别有用）：succ_using_incr 的 x-lemmas 版

> **题目**：仅用 x-lemmas 简化第 98 章练习 `triple_succ_using_incr` 的证明。

```coq
Definition succ_using_incr : val :=
  <{ fun 'n =>
       let 'r = val_ref 'n in
       incr 'r;
       let 'x = ! 'r in
       val_free 'r;
       'x }>.

(* 练习（2 星）：只用 x-lemmas 验证 succ_using_incr。 *)

Lemma triple_succ_using_incr_with_xlemmas : forall (n:int),
  triple (trm_app succ_using_incr n)
    \[]
    (fun v => \[v = n+1]).
Proof using.
  intros. applys xwp_lemma. { reflexivity. }
  simpl. unfold wpgen_var. simpl.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_ref. } { xsimpl. }
  xpull; intros r p ->.
  applys xstruct_lemma'. applys xseq_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_incr_with_xlemmas. } { xsimpl. }
  xpull; intros u.
  applys xstruct_lemma'. applys xlet_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_get. } { xsimpl. }
  xpull; intros ? ->.
  applys xstruct_lemma'. applys xseq_lemma'.
  applys xstruct_lemma'. applys xapp_lemma'.
  { apply triple_free. } { xsimpl. }
  xpull; intros u'.
  applys xstruct_lemma'. applys xval_lemma'.
  xsimpl. auto.
Qed.
```

讲解：与 `triple_incr_with_xlemmas` 完全同构，只是程序更长。两处值得注意：

- `xpull; intros r p ->`：`triple_ref` 的后条件是 `funloc p => p ~~> v`（即 `\exists p, \[r = val_loc p] \* ...`），`intros r p ->` 一次引入返回值 `r`、新单元地址 `p`，并把 `r` 替换为 `val_loc p`。
- `xpull; intros u.` / `intros u'.`：`incr` 与 `free` 的后条件不携带值等式，只需消耗其单位值；**不要**再多 `intros`——目标此时是 `H ==> F Q` 形的蕴含，多余的 `intros` 会把堆变量引进来打断后续战术。末尾 `xval_lemma'` 处理返回值 `'x`，剩 `\[x = n+1]` 的一元纯命题由 `auto` 关闭。

### 101.2.8 练习（2 星，标准，特别有用）：x-tactics 版

> **题目**：改用 x-tactics 重写上面的证明。

```coq
(* 练习（2 星）：同一证明改用 x-tactics，程序结构仍决定每步 tactic。 *)

Lemma triple_succ_using_incr_with_xtactics : forall (n:int),
  triple (trm_app succ_using_incr n)
    \[]
    (fun v => \[v = n+1]).
Proof using.
  xwp_nr.
  xapp_nr triple_ref. intros r p ->.
  xapp_nr triple_incr_with_xlemmas.
  xapp_nr triple_get. intros ? ->.
  xapp_nr triple_free.
  xval_nr. xsimpl. auto.
Qed.
```

讲解：五行 `xapp_nr` 一一对应五个调用（`ref`、`incr`、`!r`、`free`、返回值前的收尾）。与 101.2.7 对比，`xstruct/xlet/xseq` 的手工簿记全部消失；带参形态用于给有前提的规格（`triple_ref`）或非数据库成员指定引理。这就是第 93 章以来 `xwp. xapp. ...` 风格的全部来源。

---

## 101.3 局部函数：内联验证与模块化验证

### 101.3.1 示例程序 incrtwice

```coq
(* ---------- 101.3 局部函数：内联验证与模块化验证 ---------- *)

Definition incrtwice : val :=
  <{ fun 'p =>
       let 'f = (fun_ 'u => incr 'p) in
       'f ();
       'f () }>.
```

程序定义局部函数 `f = fun () -> incr p` 并调用两次。教学版生成器把 `let f = ...` 当作普通 let：`wpgen` 对 `fun_` 分支只产生 `Q (闭包值)`，公式里不会展开函数体。验证有两条路：**内联**（每次调用展开一次函数体）与**模块化**（先证一次规格，两处调用复用）。

### 101.3.2 xletval 与 xappfun：内联路径

朴素地 `xlet_nr + xval_nr` 会把闭包**语法值复制**进公式，`f` 出现几次就复制几次，公式迅速膨胀。`xletval` 的改进是引入一个**等式假设**而非代入语法值：

```coq
(* xletval 把 let x = v1 变为 forall x, x = v1 -> ...；
   因而调用点仍可借等式展开局部函数，而不必复制其语法值。 *)

Lemma xletval_lemma : forall H v1 F2of Q,
  (forall x, x = v1 -> H ==> F2of x Q) ->
  H ==> wpgen_let (mkstruct (wpgen_val v1)) F2of Q.
Proof using.
  introv M. applys xlet_lemma'. apply xstruct_lemma'.
  apply xval_lemma'. applys* M.
Qed.

Tactic Notation "xletval" :=
  xstruct_nr_if_needed; applys xletval_lemma.
```

讲解：引理把 `let x = v1 in ...` 的证明义务改成"对任意 `x`，在 `x = v1` 假设下验证续体"——`x` 成为一个**抽象值**，等式 `Hf : f = <{fun u => incr p}>` 存在上下文里，仅在需要展开时使用。

调用点用 `xappfun` 处理：它把 `f ()` 的三元组义务交给 `xwp`，而 `xwp` 恰好能消费那个等式假设：

```coq
Lemma xappfun_lemma : forall t H Q,
  triple t H Q ->
  H ==> wpgen_app t Q.
Proof using. introv M. unfold wpgen_app. xsimpl*. Qed.

Tactic Notation "xappfun" :=
  xseq_xlet_nr_if_needed; xstruct_nr_if_needed;
  applys xappfun_lemma; xwp_nr.
```

`xappfun_lemma` 就是"应用叶结点的存在量化前条件取 `H` 本身"；随后的 `xwp_nr` 用等式 `Hf` 展开函数体。组合效果：

```coq
Lemma triple_incrtwice_using_xletval : forall (p:loc) (n:int),
  triple (incrtwice p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp_nr. xletval. intros f Hf.
  xappfun. xapp_nr triple_incr_with_xlemmas.
  xappfun. xapp_nr triple_incr_with_xlemmas.
  xsimpl. math.
Qed.
```

讲解：`intros f Hf` 引入抽象函数值与等式；每个 `xappfun` 展开一次 `f ()`，紧跟的 `xapp_nr triple_incr_with_xlemmas` 验证展开后的 `incr p` 调用——**函数体验证了两遍**，这是内联路径的代价。末尾 `math` 处理 `n+1+1 = n+2`。

### 101.3.3 xfun：模块化路径

更好的做法：拿到等式 `Hf` 后**立刻**为 `f` 证一条规格，然后丢掉 `Hf`，此后把 `f` 当顶层函数对待。教学版 `xfun_nr` 把这个模式做成引理：

```coq
(* xfun 的教学版把局部函数规格 Sof 作为参数：先证 Sof v1，
   再在任意满足 Sof x 的抽象 x 下验证后续代码。 *)

Lemma xfun_lemma : forall (Sof:val->Prop) H v1 F2of Q,
  Sof v1 ->
  (forall x, Sof x -> H ==> F2of x Q) ->
  H ==> wpgen_let (mkstruct (wpgen_val v1)) F2of Q.
Proof using. introv Sf M. applys xletval_lemma. intros ? ->. applys* M. Qed.

Tactic Notation "xfun_nr" constr(Sof) :=
  xstruct_nr_if_needed; applys (@xfun_lemma Sof).
```

讲解：两个前提分别是"实际闭包满足规格 `Sof`"（函数体只验证这一次）与"任一满足规格的抽象值都让续体成立"（后续代码只依赖规格）。证明经 `xletval_lemma` 落地。

```coq
Lemma triple_incrtwice_with_xfun : forall (p:loc) (n:int),
  triple (incrtwice p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp_nr.
  xfun_nr (fun (f:val) => forall (m:int),
    triple <{ f () }> (p ~~> m) (fun _ => p ~~> (m+1))).
  { xwp_nr. xapp_nr triple_incr_with_xlemmas. xsimpl. }
  intros f Sf.
  xapp_nr Sf.
  xapp_nr Sf.
  xsimpl. math.
Qed.
```

讲解：`xfun_nr` 的参数就是想要的规格——"对任意 `m`，`f ()` 把 `p ~~> m` 变成 `p ~~> (m+1)`"。花括号子目标里一次 `xwp_nr + xapp_nr` 完成函数体验证；主线两个 `xapp_nr Sf` 与调用顶层函数毫无区别。对比 101.3.2：函数体只验证一次，两个调用点共享规格——这就是模块化。

### 101.3.4 练习（2 星，标准，选做）：succtwice 的两种验证

程序：`fun n -> let f = (fun m -> m+1) in let a = f n in f a`。

```coq
Definition succtwice : val :=
  <{ fun 'n =>
       let 'f = (fun_ 'm => 'm + 1) in
       let 'a = 'f 'n in
       'f 'a }>.
```

> **题目一**：用 `xletval` 与 `xappfun`（不用 `xfun`）验证。

```coq
(* 练习（2 星）：用 xletval 与 xappfun 内联验证局部函数两次。 *)

Lemma triple_succtwice_using_xletval : forall (n:int),
  triple (succtwice n)
    \[]
    (fun r => \[r = n + 2]).
Proof using.
  xwp_nr. xletval. intros f Hf.
  xappfun. xapp_nr triple_add. intros ? ->.
  xappfun. xapp_nr triple_add. intros ? ->.
  xsimpl. math.
Qed.
```

讲解：与 `incrtwice` 的内联证明同构。`xappfun` 展开调用 `f n`，展开后是 `n + 1` 的原语应用，`xapp_nr triple_add` 验证之，`intros ? ->` 把结果 `n+1` 代入；第二次调用同理得到 `n+2`。

> **题目二**：用 `xfun` 验证同一程序。

```coq
(* 练习（2 星）：用 xfun 给局部函数一次规格，两个调用点复用它。 *)

Lemma triple_succtwice_using_xfun : forall (n:int),
  triple (succtwice n)
    \[]
    (fun r => \[r = n + 2]).
Proof using.
  xwp_nr.
  xfun_nr (fun (f:val) => forall (m:int),
    triple <{ f m }> \[] (fun r => \[r = m+1])).
  { xwp_nr. xapp_nr triple_add. intros ? ->. xsimpl. auto. }
  intros f Sf.
  xapp_nr Sf. intros ? ->.
  xapp_nr Sf. intros ? ->.
  xsimpl. math.
Qed.
```

讲解：规格取"后继函数"的最简形式 `triple (f m) \[] (fun r => \[r = m+1])`。函数体一次验证；两个调用点各自 `xapp_nr Sf` 并代入 `n+1`、`n+2`。注意规格里 `\[]` 前条件足够——加法不需要内存。

```text
小结：内联路径适合"只出现一次"的局部函数（如传给高阶迭代器的临场函数）；
规格路径适合多次调用或需要抽象的场景。两者在最终版生成器（101.5）下由
xfun 的无参形态统一。
```

---

## 101.4 结构规则战术：xconseq 与 xframe

### 101.4.1 练习（1 星，标准，选做）：xconseq_lemma

> **题目**：证明后果规则的战术引理：从 `H ==> mkstruct F Q1` 与 `Q1 ===> Q2` 得 `H ==> mkstruct F Q2`。

```coq
(* ---------- 101.4 结构规则对应的 x-lemmas ---------- *)

(* 练习（1 星）：在 mkstruct 外层组合后果规则。 *)

Lemma xconseq_lemma : forall Q1 Q2 H F,
  H ==> mkstruct F Q1 ->
  Q1 ===> Q2 ->
  H ==> mkstruct F Q2.
Proof using.
  introv M WQ. xchange M. applys mkstruct_conseq. applys WQ.
Qed.
```

讲解：先用 `xchange` 把前提 `M` 消进目标（`H ==> mkstruct F Q1` 变 `mkstruct F Q1 ==> mkstruct F Q2`），剩下就是 `mkstruct_conseq`（库版，即 101.2.2 的 `mkstruct_conseq'`）加后条件单调性 `WQ`。战术 `xconseq`（或 `xconseq Q`）允许用户在验证中途显式换一个更强的后条件。

### 101.4.2 练习（2 星，标准，选做）：xframe_lemma

> **题目**：证明框架规则的战术引理（下述三前提形式）。要求只利用 `mkstruct` 的性质，不要展开 `mkstruct` 的定义。

```coq
(* 练习（2 星）：先把 H 分成 H1 与 H2，在 H1 上验证，再拼回 H2。
   证明只用 mkstruct_frame 与 mkstruct_conseq，不展开其定义。 *)

Lemma xframe_lemma : forall H1 H2 H Q Q1 F,
  H ==> H1 \* H2 ->
  H1 ==> mkstruct F Q1 ->
  Q1 \*+ H2 ===> Q ->
  H ==> mkstruct F Q.
Proof using.
  introv WH M WQ. xchange WH. xchange M.
  xchange (@mkstruct_frame F H2 Q1). applys mkstruct_conseq. applys WQ.
Qed.
```

讲解：三步分别对应三前提——`xchange WH` 把 `H` 分解成 `H1 \* H2`；`xchange M` 把 `H1` 换成 `mkstruct F Q1`；接着对 `mkstruct F Q1 \* H2` 用框架性质得 `mkstruct F (Q1 \*+ H2)`，最后 `mkstruct_conseq` + `WQ` 弱化到 `Q`。全程未触碰 `mkstruct` 的魔法杖内部。

一个工程细节：库中 `mkstruct_frame` 的三个参数都是**隐式**的（它只以结论形式存在），因此 `xchange` 里必须用 `@mkstruct_frame F H2 Q1` 显式实例化，否则 Rocq 会把 `F` 错放到堆变量的位置。

### 101.4.3 xframe 实战：带旁观单元的 incr

```coq
Tactic Notation "xframe_nr" constr(H) :=
  eapply (@xframe_lemma H); [ xsimpl | | ].

Lemma triple_incr_frame : forall (p q:loc) (n m:int),
  triple (trm_app incr p)
    (p ~~> n \* q ~~> m)
    (fun _ => (p ~~> (n+1)) \* (q ~~> m)).
Proof using.
  xwp_nr. xframe_nr (p ~~> n).
  xapp_nr triple_get. intros ? ->.
  xapp_nr triple_add. intros ? ->.
  xapp_nr triple_set. xsimpl.
Qed.
```

讲解：验证 `incr p` 时把无关单元 `q ~~> m` 先"框出去"（`xframe_nr (p ~~> n)` 声明保留的部分），于是三步 `xapp_nr` 全部工作在只含 `p` 的小状态上；结尾 `xsimpl` 把 `q ~~> m` 拼回并核对后条件。对比不框的版本：每一步的 `xsimpl` 都要拖着一堆无关谓词。

```coq
End NonRecursive.
```

---

## 101.5 递归进入局部函数体：最终形态

### 101.5.1 动机与 wpgen_fun

教学版生成器把 `fun x -> t1` 当作纯值，用户每次都得（经 `xwp`/`xappfun`）手工展开函数体。最终版让 `wpgen` **递归进入函数体**：公式对函数值给出的不再是"语法闭包"，而是一条**通用规格**。其核心谓词转换器是库中的

```text
wpgen_fun Fof Q  :=  \forall vf, \[forall vx Q', Fof vx Q' ==> wp (trm_app vf vx) Q'] \-* Q vf
```

读法：对任意"声称自己是这个函数"的值 `vf`，只要"任给实参 `vx` 与后条件 `Q'`，函数体的公式 `Fof vx Q'` 蕴含 `wp (vf vx) Q'`"，就能推出 `Q vf`。为了理解它，先看等价的三元组形式：

```coq
(* ---------- 101.5 递归处理局部函数体 ---------- *)

Module RecursiveFunctions.

Implicit Types vx vf : val.

(* 递归版不再返回一个语法闭包，而是对任意 vf 提供其函数体的
   最弱前条件规格。wpgen_fun' 是更易读的三元组形式。 *)

Definition wpgen_fun' (Fof:val->formula) : formula := fun Q =>
  \forall vf, \[forall vx H' Q',
                  H' ==> Fof vx Q' ->
                  triple (trm_app vf vx) H' Q']
              \-* Q vf.
```

`wpgen_fun'` 把 `wp` 换成 `triple` 并显式携带前条件 `H'`，语义一目了然：`vf` 是一个"行为由 `Fof` 描述"的函数值。

### 101.5.2 练习（2 星，标准，选做）：wpgen_fun_eq

> **题目**：证明 `wpgen_fun = wpgen_fun'`。

```coq
(* 练习（2 星）：wp 与 triple 的等价性允许消去 H'，
   因而 wpgen_fun 与 wpgen_fun' 定义相等。 *)

Lemma wpgen_fun_eq :
  wpgen_fun = wpgen_fun'.
Proof using.
  unfold wpgen_fun, wpgen_fun'. applys fun_ext_2.
  intros Fof Q. applys himpl_antisym.
  { applys himpl_hforall_r. intros vf. xchange (hforall_specialize vf).
    xsimpl. intros M. rewrite hwand_hpure_l. xsimpl.
    introv. rewrite wp_equiv. applys M. xsimpl. }
  { applys himpl_hforall_r. intros vf. xchange (hforall_specialize vf).
    xsimpl. intros M. rewrite hwand_hpure_l. xsimpl.
    intros vx H' Q' K. rewrite <- wp_equiv.
    applys himpl_trans K. applys M. }
Qed.
```

讲解（两个方向互为对偶）：

- 先用 `fun_ext_2` 把函数等式降为逐点等式，再 `himpl_antisym` 分两个蕴含方向。
- 每个方向的骨架相同：`himpl_hforall_r` 消去全称量词 `vf`；`hforall_specialize` 特化假设；`hwand_hpure_l` 把"纯命题魔法杖" `\[P] \-* Q'` 拆成 `P -> Q'`（第 99 章）。差异只在最后一步：
  - **方向一**（wp 版假设 ⇒ triple 版目标）：目标 `triple (vf vx) H' Q'` 经 `wp_equiv` 换成 `H' ==> wp (vf vx) Q'`，把假设 `M vx H'`（`H' ==> Fof vx Q'`）与 `M vx Q'`（`Fof vx Q' ==> wp ...`）串起来；收尾 `xsimpl` 关掉自反的 `H' ==> H'`。
  - **方向二**（triple 版假设 ⇒ wp 版目标）：对每个 `vx Q'`，用 `rewrite <- wp_equiv` 把 `H' ==> wp (vf vx) Q'` 换回三元组，`applys M` 消耗前提 `K : H' ==> Fof vx Q'`。
- 本质：`wp` 与 `triple` 的等价（第 100 章 `wp_equiv`）允许在后条件里**隐藏前条件**，这正是 `wpgen_fun` 比 `wpgen_fun'` 简洁的原因。

### 101.5.3 最终生成器

```coq
(* 库中的最终生成器在函数与递归函数分支递归处理函数体；
   上下文分别增加参数绑定，以及“自身 + 参数”两个绑定。 *)

Fixpoint wpgen_rec (E:ctx) (t:trm) : formula :=
  mkstruct match t with
  | trm_val v => wpgen_val v
  | trm_var x => wpgen_var E x
  | trm_fun x t1 => wpgen_fun (fun v => wpgen_rec ((x,v)::E) t1)
  | trm_fix f x t1 => wpgen_fix (fun vf v => wpgen_rec ((f,vf)::(x,v)::E) t1)
  | trm_app t1 t2 => wpgen_app (isubst E t)
  | trm_seq t1 t2 => wpgen_seq (wpgen_rec E t1) (wpgen_rec E t2)
  | trm_let x t1 t2 => wpgen_let (wpgen_rec E t1) (fun v => wpgen_rec ((x,v)::E) t2)
  | trm_if t0 t1 t2 => wpgen_if (isubst E t0) (wpgen_rec E t1) (wpgen_rec E t2)
  end.
```

与库中真正的 `wpgen`（本示例之后所有证明实际使用的版本）定义一致，两点变化：

- `trm_fun x t1`：对每个实参值 `v` 递归生成**函数体**在上下文 `(x,v)::E` 下的公式；
- `trm_fix f x t1`：递归上下文同时绑定函数自身 `f := vf` 与实参 `x := v`——`wpgen_fix` 的 `Fof` 接受两个值参数正是为此。

配套的 `xfun` 战术（库版）由 `xfun_spec_lemma`（带规格，产生"证规格 / 用规格"两个子目标）与 `xfun_nospec_lemma`（无规格，把通用规格直接交给用户，效果等同内联）实现；它们能自动处理 `wpgen_fun`/`wpgen_fix` 两种头部。这正是 101.3 的教学版 `xfun_nr` 的工业化版本。

### 101.5.4 练习（4 星，标准，特别有用）：triple_forloop

> **题目**：验证用局部递归函数实现的 for 循环。提示：把 `g` 的规格交给 `xfun`；
> 归纳用 `intros i. induction_wf IH: (upto b) i. intros Hi.`；
> 某处 `math_rewrite` 会帮上忙。

```coq
Definition forloop : val :=
  <{ fun 'a 'b 'f =>
       let 'g = (fix_ 'g 'i =>
          let 'c = 'i < 'b in
          if 'c then
            'f 'i ;
            let 'j = 'i + 1 in
            'g 'j
          end) in
       'g 'a }>.
```

规格用不变式 `I : int->hprop` 表述：循环体 `f i` 把 `I i` 推进到 `I (i+1)`，整个循环从 `I a` 走到 `I b`（只给 `a <= b` 的情形）：

```coq
(* 练习（4 星）：对 g 使用带规格的 xfun。g i 的规格以 upto b i
   为良基度量：循环体把 I i 变为 I(i+1)，递归调用继续到 I b。 *)

Lemma triple_forloop : forall (I:int->hprop) (a b:int) (f:val),
  a <= b ->
  (forall i, a <= i <= b ->
    triple (f i)
      (I i)
      (fun u => I (i+1))) ->
  triple (forloop a b f)
    (I a)
    (fun r => I b).
Proof using.
  introv Hab Hf. xwp.
  xfun (fun (g:val) => forall i, a <= i <= b ->
    triple (g i) (I i) (fun r => I b)); intros g Hg.
  { intros i. induction_wf IH: (upto b) i. intros Hi.
    applys Hg. clear Hg.
    xapp. xif; intros C.
    { xseq. xapp Hf. { math. }
      xapp.
      asserts Sg1: (triple (g (i+1)) (I (i+1)) (fun r => I b)).
      { applys IH. math. math. }
      xapp Sg1. xsimpl. }
    { xval. math_rewrite (i = b). xsimpl. } }
  xapp Hg. math. xsimpl.
Qed.
```

这是本章压轴证明，逐段讲解：

- **`xwp` 与 `xfun`**：`xwp` 展开外层函数后，公式头部是（库版生成器对 `fix_` 产生的）`mkstruct (wpgen_fix ...)`。`xfun` 携带想要的 `g` 规格——"对界内任意 `i`，`g i` 从 `I i` 直达 `I b`"——产生两个子目标，`; intros g Hg` 同时为两者引入 `g` 与对应假设（第一子目标的 `Hg` 是**通用规格**：任给 `vx H' Q'`，`H' ==> 函数体公式 vx Q'` 蕴含 `triple (g vx) H' Q'`；第二子目标的 `Hg` 就是刚声明的 `S g`）。
- **归纳骨架**：花括号内证 `S g`。对 `i` 作良基归纳，度量取 `upto b`（即"还差多少到 `b`"）。`applys Hg. clear Hg.` 把目标 `triple (g i) (I i) (fun r => I b)` 换成 `I i ==> wpgen ((参数绑定)) 函数体 (fun r => I b)`——`xwp` 的工作由通用规格一步完成，此后 `Hg` 不再需要。
- **条件与真分支**：`xapp` 验证 `i < b`；`xif; intros C` 分派。真分支是序列 `f i; (let j = i+1 in g j)`：
  - `xseq` 聚焦第一段，`xapp Hf` 用循环体规格，其界内前提 `{ math. }` 由 `Hi` 关闭；
  - `xapp` 验证 `i + 1`（`triple_add` 自动检索）；
  - 递归调用 `g (i+1)` 的规格由**归纳假设**提供：`asserts Sg1` 中两个 `math` 分别证良基前提（`i < b` 蕴含 `b - (i+1) < b - i`）与界内前提（`a <= i <= b` 蕴含 `a <= i+1 <= b`）；`xapp Sg1` 消费它；
  - `xsimpl` 收尾：`I (i+1)` 恰是递归调用的前条件。
- **假分支**：`~(i < b)` 与 `Hi : a <= i <= b` 联立得 `i = b`。这里正是原书提示的 `math_rewrite` 用点——`math_rewrite (i = b)` 把目标 `I i ==> I b` 中的 `i` 全部改写为 `b`，退化为 `I b ==> I b`，`xsimpl` 自反关闭。（若不改写，`xsimpl` 无法把抽象谓词 `I i` 与 `I b` 认作相同。）
- **主线**：`xapp Hg` 以 `Hg : S g` 验证初始调用 `g a`，`math` 证 `a <= a <= b`，`xsimpl` 关闭 `I a` 与 `I a` 的匹配。

```coq
End RecursiveFunctions.
```

---

## 101.6 小结

- **替换上下文** `E` 让 `wpgen` 成为结构递归函数：替换被推迟到变量叶结点（`lookup`/`rem`/`isubst`），let 只需扩展上下文。
- **特征公式**只由程序语法决定，形状与源代码一一对应；`wpgen_conseq` 与 `wpgen_frame` 表明它继承全部结构规则。
- **`mkstruct`** 用 `\Exists Q1, F Q1 \* (Q1 \--* Q)` 把框架与后果规则"焊"进每一层公式，四条性质（frame/conseq/erase/monotone）各一行魔法杖证明。
- 本章没有沿袭原书"可靠性暂为公理"的做法，而是复用库中已证明的叶结点引理，对教学版生成器给出**完整的** `wpgen_sound_induct`；下一章将打开这些库引理的内部，从零建立整套可靠性证明（含 `mkstruct_idempotent` 等练习）。
- **x-lemmas/x-tactics** 按公式头部形状自动消解程序结构，验证脚本退化为 `xwp. xapp. xapp. xsimpl.`；局部函数有内联（`xletval`/`xappfun`）与模块化（`xfun`）两条路径，最终版生成器递归进入函数体后由 `xfun` 统一。
- `triple_forloop` 展示了完整武器库：`xfun` + 良基归纳 + `math_rewrite`，足以验证以局部递归函数编码的循环。

下一章（WPsound）将证明本章使用的每一条库引理，把 `wpgen` 的可靠性建立在不依赖任何公理（语义直接归纳）的基础之上。
