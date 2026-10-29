# 100 · 最弱前条件：语义、结构规则与 Texan 三元组

对应示例：`../examples/100_slf_wpsem.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

97 章用 `triple t H Q` 定义程序规格，98 章建立了三元组形式的推理规则，99 章又
引入了魔法杖。本章（对应原书 WPsem 章）换一个等价但更适合自动化的视角：
不总把「前条件」和「程序能运行」分开陈述，而是直接定义一个堆谓词
**`wp t Q`**，它描述「当前堆足以保证执行 `t` 后满足 `Q`」。

这里的 **wp** 是 *weakest precondition*（最弱前条件）。它有两个同等重要的
用途：

1. 把三元组 `triple t H Q` 改写成一条普通堆谓词蕴含 `H ==> wp t Q`，从而复用
   96、99 章的 `xchange`、`xsimpl` 等工具；
2. 把函数规格写成不指定具体前条件的 **Texan 三元组**，调用者只需提供「结果
   资源如何接回目标后条件」的魔法杖。这为 101 章的最弱前条件生成器 `wpgen`
   以及 102 章的可靠性证明做准备。

本章仍使用 `LibSepReference` 中的语言、语义与分离逻辑算子；`Implicit Types`
只是省去重复的类别标注：

```coq
(* 100 最弱前条件：wp 的语义定义、wp 式结构规则与构件规则 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 WPsem 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types v w : val.
Implicit Types p : loc.
Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
```

## 100.1 最弱前条件的定义

对固定程序 `t` 和后条件 `Q`，一个前条件 `H` 合法，当且仅当
`triple t H Q` 成立。所有合法前条件的「并集」应当仍是一个合法前条件，而且
比其他合法前条件都弱；这个谓词就是 `wp t Q`。因此，它首先应满足下面的
**特征等价**：

```text
H ==> wp t Q    <->    triple t H Q
```

97 章的定义是 `triple t H Q := forall s, H s -> eval s t Q`。把 `H s` 移到
蕴含左边，立即看出右侧正是 `H ==> (fun s => eval s t Q)`。所以可以直接把
`wp` 定义为语义判断 `eval` 的柯里化形式：

```coq
(* ---------- 100.1 最弱前条件的定义 ---------- *)

(* wp t Q 是这样的堆谓词：H ==> wp t Q 当且仅当 triple t H Q。
   对照 triple 的定义可知 wp t Q 就是 fun s => eval s t Q。 *)

Definition wp (t : trm) (Q : val->hprop) : hprop :=
  fun s => eval s t Q.
```

定义之后先证明特征等价。两个方向都只是把 `H s` 与 `H ==> wp t Q` 按定义
互相改写：`iff M` 拆分等价；`introv Hs` 同时引入堆及堆谓词证据；`applys M Hs`
用当前堆的证据完成另一个方向。

```coq
Lemma wp_equiv : forall t H Q,
  (H ==> wp t Q) <-> (triple t H Q).
Proof using.
  iff M. { introv Hs. applys M Hs. } { introv Hs. applys M Hs. }
Qed.
```

`wp_equiv` 不是只为改写方便，它还同时给出「最弱前条件」的两个刻画。第一，
`wp t Q` 自己就是一个合法前条件：取 `H := wp t Q`，等价左边变成自反蕴含。

```coq
(* wp t Q 是合法前条件…… *)

Lemma wp_pre : forall t Q,
  triple t (wp t Q) Q.
Proof using. intros. rewrite <- wp_equiv. applys himpl_refl. Qed.
```

第二，任何合法前条件 `H` 都蕴含 `wp t Q`，即 `wp t Q` 不比任何合法前条件
更强。证明只是使用 `wp_equiv` 的另一个方向：

```coq
(* ……而且是"最弱的"：一切合法前条件都蕴含它。 *)

Lemma wp_weakest : forall t H Q,
  triple t H Q ->
  H ==> wp t Q.
Proof using. introv M. rewrite wp_equiv. applys M. Qed.
```

因此，阅读 `H ==> wp t Q` 时可以始终把它理解成 `{H} t {Q}`；区别只是前者
已经把三元组编码成了分离逻辑内部的一条蕴含。

## 100.2 结构规则的 wp 版

### 框架与后果

97 章的框架规则允许保留一块程序不触碰的资源 `H`。wp 形式尤其紧凑：左边
的 `wp t Q` 与 `H` 分管两块不相交的堆，执行后结果为 `Q \*+ H`。这里
`Q \*+ H` 是后条件层面的分离合取，即 `fun v => Q v \* H`。

```coq
(* ---------- 100.2 结构规则的 wp 版 ---------- *)

(* 框架规则：拿着 H，且在另一块状态上执行 t 能产出 Q，
   则执行 t 能同时产出 Q 与 H。直接用 eval_frame 证。 *)

Lemma wp_frame : forall t H Q,
  (wp t Q) \* H ==> wp t (Q \*+ H).
Proof using.
  intros. unfold wp. intros h HF.
  lets (h1&h2&M1&M2&MD&MU): hstar_inv HF.
  subst. applys eval_conseq.
  { applys eval_frame M1 MD. }
  { xsimpl. intros h' ->. applys M2. }
Qed.
```

证明比陈述更能说明框架的含义。`hstar_inv` 把输入堆拆成 `h1`、`h2`：
`M1` 给出 `eval h1 t Q`，`M2` 给出 `H h2`，`MD` 是不相交性，`MU` 说明
原堆为二者之并。`eval_frame M1 MD` 把执行扩大到 `h1 \u h2`；最后还要把
框架产生的结果调整为 `Q \*+ H`，所以外层使用 `eval_conseq`。后条件分支中，
`xsimpl` 处理分离合取，`intros h' ->` 代入结果堆的等式，`M2` 证明框架部分
仍满足 `H`。

反方向一般不成立：扩大后的 wp 可能通过程序自身分配资源，满足原本不存在的
框架部分，不能反推出执行前就已有一块独立的 `H`。

```coq
(* 反方向不成立：t = let p = ref 1 in 0 产出悬挂单元 \exists p, p ~~> 1，
   空堆满足 wp t (Q \*+ H)，但 (wp t Q) \* H 需要凭空造出一格。 *)
```

实用中通常已有一条前条件蕴含 `H1 ==> wp t Q`。先改写左边，再应用
`wp_frame`，就得到带前提的版本：

```coq
(* 与 triple_frame 的对应：把 triple t H Q 换成 H ==> wp t Q，
   再用传递性消去 H1，就得到 wp_frame。 *)

Lemma wp_frame_trans : forall t H1 Q H,
  H1 ==> wp t Q ->
  (H1 \* H) ==> wp t (Q \*+ H).
Proof using. introv M. xchange M. applys* wp_frame. Qed.
```

后果规则表达 `wp` 对后条件的**协变性**：若 `Q1 ===> Q2`，则以 `Q2` 为
目标不会比以 `Q1` 为目标更需要资源。展开 `wp` 后，这正是 `eval_conseq`。

```coq
(* 后果规则：wp t Q 对 Q 协变。 *)

Lemma wp_conseq : forall t Q1 Q2,
  Q1 ===> Q2 ->
  wp t Q1 ==> wp t Q2.
Proof using. unfold wp. introv M. intros s Hs. applys* eval_conseq. Qed.
```

与 `wp_frame_trans` 类似，把「加强前条件」和「弱化后条件」串在一条规则里，
得到常用的传递版：

```coq
Lemma wp_conseq_trans : forall t H1 H2 Q1 Q2,
  H1 ==> wp t Q1 ->
  H2 ==> H1 ->
  Q1 ===> Q2 ->
  H2 ==> wp t Q2.
Proof using.
  introv M WH WQ. xchange WH. xchange M. applys wp_conseq WQ.
Qed.
```

两次 `xchange` 分别把 `H2` 加强为 `H1`、再换成 `wp t Q1`；最后由 `WQ`
把后条件换成 `Q2`。这正是 97 章三元组后果规则的 wp 镜像。

### 抽取与后果-框架组合

三元组形式需要专门的纯事实抽取规则；wp 形式不需要另建一套，因为
`(\[P] \* H) ==> wp t Q` 已经只是普通的分离逻辑蕴含。下面的
`triple_hpure_with_wp` 虽然保留 `triple_` 前缀以便与原书对照，实际证明直接
使用 `himpl_hstar_hpure_l`：在 `P` 成立的假设下证明剩余蕴含即可。

```coq
(* 抽取规则在 wp 风格下没有对应物：它们恰好就是蕴含的抽取规则。
   triple_hpure 换写成 wp 蕴含后只是 himpl_hstar_hpure_l 的特例。 *)

Lemma triple_hpure_with_wp : forall t H Q (P:Prop),
  (P -> (H ==> wp t Q)) ->
  (\[P] \* H) ==> wp t Q.
Proof using. introv M. applys himpl_hstar_hpure_l M. Qed.
```

把框架与后果组合，可以先执行 `wp_frame` 得到 `wp t (Q1 \*+ H)`，再用
`wp_conseq` 把后条件改为 `Q2`。这里先用 `applys himpl_trans` 明确指定中间
谓词，避免让自动推断同时猜测多个参数：

```coq
(* 组合规则的无 H 版本（更简洁）。

   练习（2 星，标准，必做）：用 wp_frame 与 wp_conseq 拼装。 *)

Lemma wp_conseq_frame : forall t H Q1 Q2,
  Q1 \*+ H ===> Q2 ->
  (wp t Q1) \* H ==> (wp t Q2).
Proof using.
  introv M. applys himpl_trans (wp t (Q1 \*+ H)).
  { applys wp_frame. }
  { applys wp_conseq M. }
Qed.
```

下面是完整的前提传递版。`WH` 把当前资源拆成「执行所需部分 `H1`」和
「框架 `H2`」，`M` 把 `H1` 换成 wp，`WQ` 再把结果与框架接成 `Q`。

```coq
(* 组合的后果-框架规则（两条蕴含版本）。

   练习（2 星，标准，必做）。 *)

Lemma wp_conseq_frame_trans : forall t H H1 H2 Q1 Q,
  H1 ==> wp t Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q ->
  H ==> wp t Q.
Proof using.
  introv M WH WQ. xchange WH. xchange M.
  applys wp_conseq_frame WQ.
Qed.
```

示例文件有意先证明不带传递前提的 `wp_conseq_frame`，再证明本引理。若顺序
反过来并直接对多个尚未确定的参数使用 `applys wp_conseq_trans`，Rocq 可能
留下带 evar 的搁置目标；先建立简洁组合规则，证明链会更稳定。

### 分支框架规则

99 章的分支框架规则用 `Q1 \--* Q2` 代替显式的框架谓词。其 wp 版本为：
拥有执行 `t` 得到 `Q1` 的资源，再拥有「把任意 `Q1` 结果补成 `Q2`」的
魔法杖，就足以得到 `wp t Q2`。

```coq
(* 分支框架规则：99 章 triple_ramified_frame 的 wp 版，
   一条规则涵盖全部结构规则。 *)

Lemma wp_ramified : forall t Q1 Q2,
  (wp t Q1) \* (Q1 \--* Q2) ==> (wp t Q2).
Proof using. intros. applys wp_conseq_frame. applys qwand_cancel. Qed.
```

证明刚好揭示两种规则的关系：把 `Q1 \--* Q2` 当作 `wp_conseq_frame` 的
`H`，剩下的后条件蕴含正是 `qwand_cancel`。带任意前条件的版本只需先 `xchange`：

```coq
Lemma wp_ramified_trans : forall t H Q1 Q2,
  H ==> (wp t Q1) \* (Q1 \--* Q2) ->
  H ==> (wp t Q2).
Proof using. introv M. xchange M. applys wp_ramified. Qed.
```

**练习解答：由分支框架规则导出后果规则。** 要提供一根从 `Q1` 到 `Q2`
的后条件魔法杖；`xsimpl` 把目标归一到后条件蕴含，`M` 收尾。这里用
`applys (>> ...)` 显式实例化 `t`、前条件和两个后条件，避免留下无法求解的
evar。

```coq
(* 练习（3 星，标准，必做）：wp_conseq 可由 wp_ramified 导出。 *)

Lemma wp_conseq_of_wp_ramified : forall t Q1 Q2,
  Q1 ===> Q2 ->
  wp t Q1 ==> wp t Q2.
Proof using.
  introv M. applys (>> wp_ramified_trans t (wp t Q1) Q1 Q2).
  xsimpl. applys M.
Qed.
```

**练习解答：由分支框架规则导出框架规则。** 关键是证明普通框架 `H` 可以
换成魔法杖 `Q \--* (Q \*+ H)`：`himpl_qwand_r` 把问题改成
`Q \*+ H ===> Q \*+ H`，由 `qimpl_refl` 完成。随后用 `W` 改写并应用
`wp_ramified`。

```coq
(* 练习（2 星，标准，必做）：wp_frame 也可由 wp_ramified 导出。 *)

Lemma wp_frame_of_wp_ramified : forall t H Q,
  (wp t Q) \* H ==> wp t (Q \*+ H).
Proof using.
  intros.
  asserts W: (H ==> (Q \--* (Q \*+ H))).
  { applys himpl_qwand_r. applys qimpl_refl. }
  xchange W. applys wp_ramified.
Qed.
```

两道练习说明：`wp_ramified` 并不增加逻辑表达力，却把后果与框架统一成一次
「资源加续体」的组合，因此特别适合自动化战术调用。

## 100.3 构件规则的 wp 版

98 章每条构件规则都是从对应的 `eval_*` 规则导出的。wp 版更加直接：展开
`wp` 后，目标与语义规则几乎逐字相同。值的规则表示，只要当前资源已经满足
`Q v`，就足以执行一个立即返回值 `v` 的程序。

```coq
(* ---------- 100.3 构件规则的 wp 版 ---------- *)

(* 值：拿着 Q v 就等于拿着"求值 v 产出 Q"。 *)

Lemma wp_val : forall v Q,
  Q v ==> wp (trm_val v) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_val. Qed.
```

序列规则的中间后条件是 `fun v => wp t2 Q`：第一段执行结束后，结果值虽然不
再使用，但剩余堆必须足以继续执行 `t2`。let 规则还把结果值 `v1` 代入续体
`subst x v1 t2`，与 98 章完全相同。

```coq
(* 序列：先产出"能接着跑 t2"的状态，就是能跑整个序列。 *)

Lemma wp_seq : forall t1 t2 Q,
  wp t1 (fun v => wp t2 Q) ==> wp (trm_seq t1 t2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_seq. Qed.

Lemma wp_let : forall x t1 t2 Q,
  wp t1 (fun v1 => wp (subst x v1 t2) Q) ==> wp (trm_let x t1 t2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_let. Qed.
```

函数与递归函数在当前语言中都是值，因此其规则与 `wp_val` 同形：闭包构造不
执行函数体，只把闭包值交给后条件。

```coq
Lemma wp_fun : forall x t Q,
  Q (val_fun x t) ==> wp (trm_fun x t) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_fun. Qed.

Lemma wp_fix : forall f x t Q,
  Q (val_fix f x t) ==> wp (trm_fix f x t) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_fix. Qed.
```

条件规则先按布尔值选出源语言分支，再对该分支求 wp：

```coq
Lemma wp_if : forall b t1 t2 Q,
  wp (if b then t1 else t2) Q ==> wp (trm_if (val_bool b) t1 t2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_if. Qed.
```

**练习解答：分支外置形式。** 也可以让 Rocq 的 `if` 选择 `wp t1 Q` 或
`wp t2 Q`。证明先 `destruct b`；裸用 `applys wp_if` 无法从蕴含左侧反推出
应传入的布尔见证，所以两个分支分别显式写 `true`、`false`。

```coq
(* 练习（1 星，标准，选做）：if 也可套在两个 wp 外面。 *)

Lemma wp_if' : forall b t1 t2 Q,
  (if b then (wp t1 Q) else (wp t2 Q)) ==> wp (trm_if b t1 t2) Q.
Proof using. intros. destruct b.
  { applys wp_if true. }
  { applys wp_if false. }
Qed.
```

普通函数应用只需代入形参；递归函数应用还要把函数名 `f` 替换成整个递归闭包
`v1`，以支持函数体内的递归调用。两个等式前提用于确认被调用值确实具有相应
的闭包形状。

```coq
Lemma wp_app_fun : forall x v1 v2 t1 Q,
  v1 = val_fun x t1 ->
  wp (subst x v2 t1) Q ==> wp (trm_app v1 v2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_app_fun. Qed.

Lemma wp_app_fix : forall f x v1 v2 t1 Q,
  v1 = val_fix f x t1 ->
  wp (subst x v2 (subst f v1 t1)) Q ==> wp (trm_app v1 v2) Q.
Proof using. unfold wp. intros. intros h K. applys* eval_app_fix. Qed.
```

这一组规则是 101 章定义按语法递归的 `wpgen` 的直接蓝本：每个程序构件对应
一个把「后续计算」包进后条件的 wp 表达式。

## 100.4 wp 的其他定义与唯一性

### 定义一：存在某个合法三元组前条件

`wp` 的语义定义很简洁，却不是唯一可能的定义。第一种替代定义说：当前堆可以
拆成某个前条件 `H` 的资源与一个空堆上的纯事实，且该纯事实保证
`triple t H Q`。存在量词遍历所有合法前条件，因此它正好把它们汇集起来。

```coq
(* ---------- 100.4 wp 的其他定义与唯一性 ---------- *)

(* 定义一：wp_1 用 triple 定义——"任何"合法前条件 H 的存在性刻画。 *)

Module WpFromTriple.

Definition wp_1 (t:trm) (Q:val->hprop) : hprop :=
  \exists (H:hprop), H \* \[triple t H Q].
```

**练习解答：`wp_1` 满足特征等价。** 正向从 `M s Hs` 得到见证 `H0`、两块
堆 `h0` 和 `h1` 以及 `triple t H0 Q` 的纯事实。`hpure_inv` 还给出
`h1 = Fmap.empty`；代入并用 `Fmap.union_empty_r` 化简，可知原堆 `s` 就是
`h0`，于是直接应用该三元组。反向则以当前 `H` 本身作为存在量词见证，
`hstar_hpure_l` 要求提供 `triple t H Q`，恰由假设 `M` 给出。

```coq
(* 练习（3 星，标准，必做）：wp_1 也满足特征等价。
   → 方向拆出见证 H0，其纯事实说明 H0 是合法前条件，
   而 \[...] 的堆为空表明原堆就是 H0 的堆。 *)

Lemma wp_equiv_1 : forall t H Q,
  (H ==> wp_1 t Q) <-> (triple t H Q).
Proof using.
  intros. iff M.
  { intros s Hs. lets (H0&h0&h1&K0&K1&D&U): M s Hs.
    lets (Ktriple&E1): hpure_inv (rm K1). subst h1.
    rewrite Fmap.union_empty_r in U. subst s.
    applys Ktriple h0 K0. }
  { intros h Hh. exists H. rewrite hstar_comm, hstar_hpure_l. splits*. }
Qed.

End WpFromTriple.
```

### 定义二：给当前堆命名

第二种定义更直接：`wp_2 t Q` 在堆 `h` 上成立，指以「只包含 `h` 的单点堆
谓词」为前条件的三元组成立。谓词 `fun h' => h' = h` 不给堆附加任何其他资源，
只是给当前堆起了名字。

```coq
(* 定义二：wp_2 直接以堆为参数——"恰在此堆上执行 t 产出 Q"。 *)

Module WpFromTriple2.

Definition wp_2 (t:trm) (Q:val->hprop) : hprop :=
  fun (h:heap) => triple t (fun h' => (h' = h)) Q.
```

**练习解答：`wp_2` 满足特征等价。** 正向使用 97 章的
`triple_named_heap`：要证 `triple t H Q`，可对任意满足 `H` 的命名堆 `h`
证明同一目标，而 `M h Hh` 正是所需事实。反向给定 `H h` 后，用三元组后果
规则把前条件 `H` 换成单点谓词；由于当前堆名为 `h`，这一加强显然成立。

```coq
(* 练习（4 星，标准，选做）：wp_2 也满足特征等价。
   用 97 章练习 triple_named_heap（给堆命名的规则）。 *)

Lemma wp_equiv_2 : forall t H Q,
  (H ==> wp_2 t Q) <-> (triple t H Q).
Proof using.
  intros. iff M.
  { applys triple_named_heap. intros h Hh. applys M h Hh. }
  { intros h Hh. applys triple_conseq M.
    { intros h' E. subst h'. auto. }
    { applys qimpl_refl. } }
Qed.

End WpFromTriple2.
```

### 唯一性与两种刻画

既然三个定义都满足同一特征等价，它们必然相等。更一般地，任何两个满足该
等价的算子 `wp1`、`wp2` 都相等。证明先用函数外延性把算子相等化为固定
`t Q` 后的堆谓词相等，再用蕴含反对称性；每个方向都借助「两个等价共享同一个
`triple t H Q`」完成改写。

```coq
(* 特征等价唯一确定 wp：任何两个满足它的算子相等。 *)

Lemma wp_unique : forall wp1 wp2,
  (forall t H Q, (triple t H Q) <-> (H ==> wp1 t Q)) ->
  (forall t H Q, (triple t H Q) <-> (H ==> wp2 t Q)) ->
  wp1 = wp2.
Proof using.
  introv M1 M2. applys fun_ext_2. intros t Q. applys himpl_antisym.
  { rewrite <- M2. rewrite M1. auto. }
  { rewrite <- M1. rewrite M2. auto. }
Qed.
```

**练习解答：合法性与最弱性合起来也唯一刻画 wp。** 从 `wp_pre` 和
`wp_weakest` 推出特征等价时，正向用后果规则把前条件 `wp' t Q` 加强为 `H`，
反向直接用最弱性。反方向中，`wp_pre` 通过把特征等价用于 `H := wp' t Q`
并证明自反蕴含得到；`wp_weakest` 则使用等价的另一方向。

```coq
(* 练习（2 星，标准，必做）："合法前条件 + 最弱性" 与特征等价等价。 *)

Lemma wp_equiv_iff_wp_pre_and_wp_weakest : forall wp',
  (   (forall t Q, triple t (wp' t Q) Q) (* [wp_pre] *)
   /\ (forall t H Q, triple t H Q -> H ==> wp' t Q)) (* [wp_weakest] *)
  <->
  (forall t H Q, H ==> wp' t Q <-> triple t H Q). (* [wp_equiv] *)
Proof using.
  intros. iff M.
  { destruct M as (M1&M2). intros t H Q. iff E.
    { applys triple_conseq (M1 t Q). { applys E. } { applys qimpl_refl. } }
    { applys M2 E. } }
  { split.
    { intros t Q. applys (proj1 (M t (wp' t Q) Q)). applys himpl_refl. }
    { introv K. applys (proj2 (M t H Q)). applys K. } }
Qed.
```

所以无论把 wp 理解为「语义上足以运行的堆」「所有合法前条件的汇集」还是
「当前命名堆上的三元组」，最终都是同一个算子。

## 100.5 Texan 三元组：用 wp 写函数规格

普通三元组把函数规格固定为一组具体前后条件。例如 `ref v` 的规格是：从空堆
出发，返回一个新地址 `p`，并产生 `p ~~> v`。`funloc p => ...` 是后条件记法，
表示返回值必为某个 `val_loc p`，同时给出该地址的资源。

```coq
(* ---------- 100.5 Texan 三元组：用 wp 写函数规格 ---------- *)

Module TexanTriples.

(* 以 ref 为例：三元组规格逐步改写成 wp 风格（前条件留空位）。 *)

Parameter triple_ref : forall v,
  triple (val_ref v)
    \[]
    (funloc p => p ~~> v).
```

先用 `wp_equiv` 改写，得到第 0 步：

```coq
Lemma wp_ref_0 : forall v,
  \[] ==> wp (val_ref v) (funloc p => p ~~> v).
Proof using. intros. rewrite wp_equiv. applys triple_ref. Qed.
```

第 1 步引入任意目标后条件 `Q`。调用者提供
`(funloc p => p ~~> v) \--* Q`，表示「一旦拿到新单元，就能接成 `Q`」；
`wp_ramified` 将具体结果与这根续体杖组合起来。

```coq
(* 给定抽象后条件 Q，用杖把具体后条件换成 Q： *)

Lemma wp_ref_1 : forall Q v,
  ((funloc p => p ~~> v) \--* Q) ==> wp (val_ref v) Q.
Proof using. intros. xchange (wp_ref_0 v). applys wp_ramified. Qed.
```

第 2 步展开后条件魔法杖：先量化任意返回值 `r`，若 `r` 是位置 `p` 且拥有
`p ~~> v`，就必须能证明 `Q r`。`xsimpl` 自动完成 `funloc`、存在量词和杖
之间的等价整理。

```coq
(* 展开 qwand，对结果值 r 显式量化： *)

Lemma wp_ref_2 : forall Q v,
  (\forall r,     (\exists p, \[r = val_loc p] \* p ~~> v) \-* Q r)
              ==> wp (val_ref v) Q.
Proof using. intros. applys himpl_trans wp_ref_1. xsimpl. Qed.
```

第 3 步消去中间返回值 `r`，直接量化新地址 `p`。`xsimpl` 后出现的
`intros ? p ->` 代入返回位置等式；`hforall_specialize p` 从左侧全称量词中
取出当前地址对应的杖。这就是最终的 Texan 风格规格。

```coq
(* r 恰为 val_loc p，代入后得到最终的 Texan 风格规格： *)

Lemma wp_ref_3 : forall Q v,
  (\forall p, (p ~~> v) \-* Q (val_loc p)) ==> wp (val_ref v) Q.
Proof using.
  intros. applys himpl_trans_r wp_ref_2. xsimpl. intros ? p ->.
  xchange (hforall_specialize p).
Qed.
```

一般地，若一个操作的普通规格返回 `vof x` 并产生资源 `Hof`，Texan 形式就把
「返回什么、产生什么」移到前条件右侧的一根全称魔法杖中。调用者不再先猜一个
中间后条件，而是直接提供从操作结果到最终后条件的接续方式。下面的等价证明
正向用 `wp_ramified_trans`，反向把目标后条件特化为操作原本的后条件，因此
`xsimpl~` 能自行提供合适的魔法杖。

```coq
(* 一般模式：triple t H (fun r => \exists x, \[r = vof x] \* Hof r x)
   等价于 Texan 三元组 forall Q, H \* (\forall x, Hof (vof x) x \-* Q (vof x)) ==> wp t Q。 *)

Lemma texan_triple_equiv : forall t H A (Hof:val->A->hprop) (vof:A->val),
      (triple t H (fun r => \exists x, \[r = vof x] \* Hof r x))
  <-> (forall Q, H \* (\forall x, Hof (vof x) x \-* Q (vof x)) ==> wp t Q).
Proof using.
  intros. rewrite <- wp_equiv. iff M.
  { intros Q. xchange M. applys wp_ramified_trans.
    xsimpl. intros r x ->.
    xchange (hforall_specialize x). }
  { applys himpl_trans_r M. xsimpl~. }
Qed.
```

### 引用操作的 Texan 规格

读取 `p` 时，调用者既提供原单元 `p ~~> v`，又提供续体
`p ~~> v \-* Q v`：读取不会改变单元，所以续体拿回同一资源，并知道返回值
为 `v`。证明把 wp 目标改回三元组，再以续体杖作为框架应用
`triple_conseq_frame`；最后的 `xsimpl` 与返回值等式完成接续。

```coq
(* get/set/free 的 wp 规格： *)

Section WpSpecRef.

Lemma wp_get : forall v p Q,
  (p ~~> v) \* (p ~~> v \-* Q v) ==> wp (val_get p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_get. } { applys himpl_refl. } { xsimpl. intros ? ->. auto. }
Qed.
```

写入允许返回任意值，所以使用 `\forall r`；真正重要的信息是写后资源变为
`p ~~> w`。证明中对每个结果 `r` 特化全称杖即可。

```coq
Lemma wp_set : forall v w p Q,
  (p ~~> v) \* (\forall r, p ~~> w \-* Q r) ==> wp (val_set p w) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_set. } { applys himpl_refl. }
  { intros r. xchange (hforall_specialize r). xsimpl. }
Qed.
```

释放操作消耗 `p ~~> v`，不产生新的堆资源，因此续体只需对任意返回值 `r`
给出 `Q r`。最后一条 `xchange` 已能利用蕴含自反性关闭目标，不需要多余的
`xsimpl`。

```coq
Lemma wp_free : forall v p Q,
  (p ~~> v) \* (\forall r, Q r) ==> wp (val_free p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_free. } { applys himpl_refl. }
  { intros r. xchange (hforall_specialize r). }
Qed.
```

库里也提供明确返回 `val_unit` 的写、释放规格。返回值确定后，写操作的续体
不再需要对一切 `r` 量化，只需处理 `Q val_unit`：

```coq
(* 也可声明返回值为 unit： *)

Parameter triple_set' : forall w p v,
  triple (val_set p w)
    (p ~~> v)
    (fun r => \[r = val_unit] \* p ~~> w).

Lemma wp_set' : forall v w p Q,
  (p ~~> v) \* (p ~~> w \-* Q val_unit) ==> wp (val_set p w) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_set'. }
  { applys himpl_refl. }
  { xsimpl. intros ? ->. auto. }
Qed.
```

释放规格同样可以把返回值固定为 `unit`。由于释放后没有任何单元资源，Texan
前条件中只需星接 `Q val_unit`：

```coq
Parameter triple_free' : forall p v,
  triple (val_free p)
    (p ~~> v)
    (fun r => \[r = val_unit]).

Lemma wp_free' : forall v w p Q,
  (p ~~> v) \* (Q val_unit) ==> wp (val_free p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_free'. }
  { applys himpl_refl. }
  { xsimpl. intros ? ->. auto. }
Qed.

End WpSpecRef.
```

**练习解答：为 `incr` 写出 Texan 三元组。** 普通规格说明 `incr p` 消耗
`p ~~> n`、返回 `unit` 并留下 `p ~~> (n+1)`。相应的 wp 规格要求调用者提供
一根从更新后单元到 `Q val_unit` 的杖。证明模式与 `wp_set'` 完全一致：
`triple_conseq_frame` 的三个分支分别是原操作规格、前条件自反蕴含以及结果
接续。

```coq
(* 练习（3 星，标准，必做）：为 incr 陈述并证明 Texan 三元组。 *)

Parameter incr : val.

Parameter triple_incr : forall (p:loc) (n:int),
  triple (incr p)
    (p ~~> n)
    (fun v => \[v = val_unit] \* (p ~~> (n+1))).

Lemma wp_incr : forall (p:loc) (n:int) Q,
  (p ~~> n) \* (p ~~> (n+1) \-* Q val_unit) ==> wp (incr p) Q.
Proof using.
  intros. rewrite wp_equiv. applys triple_conseq_frame.
  { applys triple_incr. }
  { applys himpl_refl. }
  { xsimpl. intros ? ->. auto. }
Qed.

End TexanTriples.
```

Texan 形式的代价是规格中多了一层后条件魔法杖，直接阅读不如普通三元组直观；
收益是调用规则无需猜测中间框架与后条件，特别适合由 `xapp` 等自动化战术
机械应用。

## 100.6 小结

```coq
(* ---------- 100.6 小结 ----------
   1) wp t Q = fun s => eval s t Q；H ==> wp t Q 与 triple t H Q 互相等价，
      wp 既是合法前条件又是最弱前条件，且被特征等价唯一确定；
   2) 结构规则在 wp 下大幅坍缩：后果=对 Q 协变、框架=一条蕴含，
      抽取规则退化为蕴含的抽取规则，分支框架规则一条全覆盖；
   3) 构件规则的 wp 版全是 eval 构件规则的一行镜像；
   4) Texan 三元组把函数规格写成 H \* (\forall x, H' \-* Q v) ==> wp t Q，
      简化 xapp 实现但可读性略降。 *)
```

本章最关键的心理模型是：**`wp t Q` 不是另一个程序逻辑，而是把三元组折叠成
一个堆谓词。** 结构规则随之变成蕴含代数，构件规则变成 `eval` 规则的镜像，
函数规格则变成「当前资源星接一个结果续体」。101 章将沿程序语法递归组合这些
构件，自动生成这样的 wp。
