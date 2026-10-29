# 98 · 推理规则：语言构件、原语规格与手工验证

对应示例：`../examples/98_slf_rules.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

97 章把 `triple` 的定义和结构规则（框架、后果、抽取）全部建立起来；本章
（对应原书 Rules 章）补齐另一半拼图——**与语言构件一一对应的推理规则**和
**原语操作的规格**，然后用这些「裸规则」手工验证 93 章证明过的程序。这样做
的目的不是倒退：`triple_incr` 的手工证明把 `xwp`/`xapp` 每一步背后的规则应
用摊开给你看——读完本章，x 战术对你就不再是魔法。

一个贯穿全章的提醒（97 章的定义）：

```text
triple t H Q  :=  forall s, H s -> eval s t Q
```

结构规则（`triple_conseq`、`triple_frame`、`triple_conseq_frame`、
`triple_hpure`、`triple_hexists`）直接用 `LibSepReference` 里的现成引理——
97 章已经亲手证过一遍。本章新证的规则名字与库里同名（遮蔽库版本），内容逐
条相同，证完即可与 93/94 章的经验无缝衔接。

文件头：本章开始要写具体程序，所以 `Import ProgramSyntax`（`<{ ... }>` 记
法）回来了：

```coq
(* 98 推理规则：语言构件与原语操作的规格、手工验证示例 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Rules 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax.

Implicit Types n : int.
Implicit Types t : trm.
Implicit Types r v : val.
Implicit Types p : loc.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
```

## 98.1 序列规则

序列规则与 Hoare 逻辑的同名规则一模一样——分离逻辑的「分离」全在结构规则
里，构件规则本身并无新意：

```text
      {H} t1 {fun _ => H1}     {H1} t2 {Q}
      ------------------------------------
              {H} (t1; t2) {Q}
```

下划线表示 `t1` 的结果值无关紧要。证明是 `eval_seq` 的直接应用——`applys*`
让 eauto 自动把 `M1 s Hs` 喂给第一前提、`M2` 喂给续体：

```coq
(* ---------- 98.1 序列规则 ---------- *)

(* {H} t1 {fun _ => H1}   {H1} t2 {Q}
   ----------------------------------
         {H} (t1; t2) {Q}                    *)

(* 练习（2 星，标准，必做）：序列规则。 *)

Lemma triple_seq : forall t1 t2 H Q H1,
  triple t1 H (fun _ => H1) ->
  triple t2 H1 Q ->
  triple (trm_seq t1 t2) H Q.
Proof using. introv M1 M2 Hs. applys* eval_seq. Qed.
```

## 98.2 let 规则

let 规则也是 Hoare 逻辑的老面孔，但陈述里藏着一个容易踩的坑：

```text
      {H} t1 {Q1}     (forall v, {Q1 v} (subst x v t2) {Q})
      -----------------------------------------------------
                {H} (let x = t1 in t2) {Q}
```

注意**程序变量 `x` 与 Rocq 值变量 `v1` 是两个世界的东西**：源程序里写的是
`let x = t1 in t2`，规则里续体却对「一切结果值 `v1`」陈述，且 `t2` 中的
`x` 已被替换成 `v1`（`subst x v1 t2`）。若是非正式地写成
`(forall x, {Q1 x} t2 {Q})`，两个 `x` 就混为一谈了。实践中应用这条规则后，
习惯动作是 `intros x`（给 `v1` 起回源码里的名字）再 `simpl`（让 `subst` 实
际算出来）——98.14 的 `triple_incr` 会完整演示：

```coq
(* ---------- 98.2 let 规则 ---------- *)

(* 注意区分程序变量 x 与 Rocq 值变量 v1：续体对一切结果值 v1 陈述，
   项 t2 里的程序变量 x 已被代换成 v1。 *)

Lemma triple_let : forall x t1 t2 Q1 H Q,
  triple t1 H Q1 ->
  (forall v1, triple (subst x v1 t2) (Q1 v1) Q) ->
  triple (trm_let x t1 t2) H Q.
Proof using. introv M1 M2 Hs. applys* eval_let. Qed.
```

## 98.3 条件规则

两分支版本（各带一个等式前提），用 `case_if` 对布尔做分类讨论：

```coq
(* ---------- 98.3 条件规则 ---------- *)

(* 练习（2 星，标准，必做）：两分支形式的条件规则。 *)

Lemma triple_if_case : forall b t1 t2 H Q,
  (b = true -> triple t1 H Q) ->
  (b = false -> triple t2 H Q) ->
  triple (trm_if (val_bool b) t1 t2) H Q.
Proof using.
  introv M1 M2 Hs. applys eval_if. case_if.
  { applys* M1. }
  { applys* M2. }
Qed.
```

`case_if` 把目标里的 `if b then t1 else t2` 拆成两个情形并把 `b` 替换成
`true`/`false`，于是 `M1` 的前提变成 `true = true`（`auto` 收）。两个前提
也可以像 `eval_if` 那样用 Rocq 自己的 `if` 合并成一条——这就是 `xif` 战术
用的版本：

```coq
(* 用 Rocq 自己的 if 把两个前提合并成一条。 *)

Lemma triple_if : forall (b:bool) t1 t2 H Q,
  triple (if b then t1 else t2) H Q ->
  triple (trm_if b t1 t2) H Q.
Proof using. introv M Hs. applys* eval_if. Qed.
```

## 98.4 值规则：两种形式互推

值 `v` 的行为极简版规格是「空前条件、结果就是 `v`」。但实用中更顺手的是
**任意前条件版**：只要 `H` 蕴含「结果为 `v`」：

```text
         H ==> Q v
      --------------
        {H} v {Q}
```

```coq
(* ---------- 98.4 值规则 ---------- *)

(* 实用形式：前条件蕴含"结果为 v"即可。
     H ==> Q v
   --------------
     {H} v {Q}                          *)

Lemma triple_val : forall v H Q,
  H ==> Q v ->
  triple (trm_val v) H Q.
Proof using. introv M Hs. applys* eval_val. Qed.
```

**练习（1 星）triple_val_minimal**——极简版一行导出（`xsimpl` 把
`\[] ==> \[v = v]` 归一化后剩 `v = v`，补 `auto`）：

```coq
(* 练习（1 星，标准，必做）：极简形式 {\[]} v {fun r => \[r = v]}。 *)

Lemma triple_val_minimal : forall v,
  triple (trm_val v) \[] (fun r => \[r = v]).
Proof using. intros v. applys triple_val. xsimpl. auto. Qed.
```

**练习（2 星）triple_val'**——更有意思的反方向：**不许展开 triple 的定
义**，只用 `triple_conseq_frame` + `triple_val_minimal` 推出实用版。思路：
把 `H` 当框架——极简版给出 `{\[]} v {\[r = v]}`，后果-框架规则把它抬到
`{H} v {Q}`：

```coq
(* 练习（2 星，标准，必做）：反向——不展开 triple 定义，
   用 triple_conseq_frame + triple_val_minimal 推出实用形式。 *)

Lemma triple_val' : forall v H Q,
  H ==> Q v ->
  triple (trm_val v) H Q.
Proof using.
  introv M. applys triple_conseq_frame.
  { applys triple_val_minimal. }
  { xsimpl. }
  { intros r. xpull. intros ->. applys M. }
Qed.
```

第三个子目标是 `(\[r = v] \* H) ===> Q`：`xpull` 抽出纯事实，`intros ->`
代入 `r := v`，剩 `H ==> Q v` 恰是 `M`。

**练习（4 星）triple_let_val**——自己**陈述并证明**一条规则：
`let x = v1 in t2` 中绑定的已是值。关键在于为第一步选后条件
`\[v = v1] \* H`——既把「结果恰是 `v1`」记录在案，又把调用者的整个前条件
`H` 原样转发给续体；续体里用 `triple_hpure` 抽出等式、`intros ->` 代入即化
归为假设 `M`：

```coq
(* 练习（4 星，标准，必做）：let 的参数已是值时的特设规则。 *)

Lemma triple_let_val : forall x v1 t2 H Q,
  triple (subst x v1 t2) H Q ->
  triple (trm_let x (trm_val v1) t2) H Q.
Proof using.
  introv M. applys triple_let (fun v => \[v = v1] \* H).
  { applys triple_val. xsimpl*. }
  { intros v. applys triple_hpure. intros ->. applys M. }
Qed.
```

（`applys triple_let (fun v => ...)` 显式提供中间后条件，避免让 evar 漫
游——这是手工证明里推荐的习惯。）

## 98.5 函数定义规则

97 章区分过 `trm_fun`（可能有自由变量的项）与 `val_fun`（闭值）。求值到
`trm_fun` 时自由变量都已被替换干净，`eval_fun` 把它「闭化」。逻辑规则照抄
值规则的形式——前条件蕴含「结果是那个闭值」即可：

```coq
(* ---------- 98.5 函数定义规则 ---------- *)

Lemma triple_fun : forall x t1 H Q,
  H ==> Q (val_fun x t1) ->
  triple (trm_fun x t1) H Q.
Proof using. introv M Hs. applys* eval_fun. Qed.

Lemma triple_fix : forall f x t1 H Q,
  H ==> Q (val_fix f x t1) ->
  triple (trm_fix f x t1) H Q.
Proof using. introv M Hs. applys* eval_fix. Qed.
```

## 98.6 函数调用规则

beta 规约的规格版。注意**被调函数必须是已知的具体值**（形如
`v1 = val_fun x t1` 的等式前提）：若 `v1` 还是个程序变量，说明它尚未被代
换；若 `v1` 是个没有等式约束的 Rocq 变量，说明你应该去用它先前后建立的规
格引理（93 章对 `triple_incr` 的引用正是这种情形），而不是硬套 beta：

```coq
(* ---------- 98.6 函数调用规则 ---------- *)

(* beta 规约的规格版：被调函数必须是已知的具体值。 *)

Lemma triple_app_fun : forall x v1 v2 t1 H Q,
  v1 = val_fun x t1 ->
  triple (subst x v2 t1) H Q ->
  triple (trm_app v1 v2) H Q.
Proof using. introv E M Hs. applys* eval_app_fun. Qed.

(* 递归函数的双重代入：先代入自身 f，再代入实参 x。 *)

Lemma triple_app_fix : forall v1 v2 f x t1 H Q,
  v1 = val_fix f x t1 ->
  triple (subst x v2 (subst f v1 t1)) H Q ->
  triple (trm_app v1 v2) H Q.
Proof using. introv E M Hs. applys* eval_app_fix. Qed.
```

递归版做**双重代入**：先把函数自身代入名字 `f`，再代入实参——这正是
`val_fix f x t1` 递归展开的语义。

## 98.7 加法的规格与「最小足迹」约定

93 章你把 `triple_add` 之类的规格当「公理表」用；现在自己证。加法不碰内
存：空前条件、状态不变、结果是 `val_int (n1+n2)`。证明模式值得背下来——
`introv Hs` 拿到初始堆、`hempty_inv` 把「堆为空」变成等式、`hpure_intro`
把纯事实装回 `\[\[]` 形状：

```coq
(* ---------- 98.7 加法的规格：最小足迹约定 ---------- *)

Lemma triple_add : forall n1 n2,
  triple (val_add n1 n2)
    \[]
    (fun r => \[r = val_int (n1 + n2)]).
Proof using.
  introv Hs. applys* eval_add. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.
```

> 库注记：`LibSepReference` 的 `eval` 把二元原语统一编码成
> `eval_binop`/`evalbinop_add` 等，同时**贴心地导出了** `eval_add`、
> `eval_div`、`eval_rand` 这三个专用引理（"to avoid the indirection via
> eval_unop and eval_binop in the course"）——原书本章把 `eval_add` 等公理
> 化，我们直接用库里证好的版本，形式完全一致。

加法当然也能写成 `triple_val` 风格（一条蕴含吃掉前后条件）：

```coq
(* 也可写成 triple_val 风格，但最小足迹版（前条件 \[]）才能配合框架规则
   灵活使用；函数规格一律按"前条件只覆盖必须访问的内存"来写。 *)

Lemma triple_add' : forall H Q n1 n2,
  H ==> Q (val_int (n1 + n2)) ->
  triple (val_add n1 n2) H Q.
Proof using.
  introv M. applys triple_conseq_frame.
  { applys triple_add. }
  { xsimpl. }
  { xpull. intros ? ->. auto. }
Qed.
```

但这种写法**不可推广**：带真实前条件的函数（如 `get` 要一格内存）没法塞进
一条蕴含里。所以约定是——**最小足迹规格（minimal footprint）**：前条件只
覆盖函数必须访问的内存。`add` 不碰内存 → 前条件 `\[]`；`get` 恰好读一格
→ `p ~~> v`；`mlist_length` 遍历整条链表 → `MList p L`。偶尔允许过近似
（比如「找链表中首个 `v` 的下标」仍以整条 `MList p L` 为前条件，而非「到
达该单元的最短前缀」），那是为避免无谓的复杂度。

## 98.8 除法的规格

除法多一个除零前提，形式照旧：

```coq
(* ---------- 98.8 除法的规格 ---------- *)

Lemma triple_div : forall n1 n2,
  n2 <> 0 ->
  triple (val_div n1 n2)
    \[]
    (fun r => \[r = val_int (Z.quot n1 n2)]).
Proof using.
  introv Hn2 Hs. applys* eval_div. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.
```

## 98.9 rand 的规格

`rand` 是第一个真正「omni」的规格：后条件只说**结果落在 `[0,n)` 中**——
因为 `eval_rand` 的第二前提已经替你处理了「对一切可能结果都要成立」的全称
量词，剩下的正是这个存在性的弱陈述。`introv Hn Hs` 后手动喂两个前提，第二
个里对每个 `n1` 用 `hpure_intro` 造出纯事实并选自己当见证：

```coq
(* ---------- 98.9 rand 的规格 ---------- *)

(* 练习（2 星，标准，必做）：非确定性原语的规格——
   后条件断言结果落在 [0,n) 内。 *)

Lemma triple_rand : forall n,
  n > 0 ->
  triple (val_rand n)
    \[]
    (fun r => \[exists n1, r = val_int n1 /\ 0 <= n1 < n]).
Proof using.
  introv Hn Hs. applys eval_rand.
  { math. }
  { intros n1 Hn1. lets ->: hempty_inv Hs.
    applys hpure_intro. exists n1. split. { reflexivity. } { math. } }
Qed.
```

## 98.10 分配的规格

`ref v` 分配一个新单元：结果值是**某个**新位置 `p`（后条件里存在量化），
新单元 `p ~~> v` 加入堆。证明涉及 97.10 式的堆运算：初始堆为空
（`hempty_inv`），更新空堆得到单格映射（`Fmap.update_empty`），最后
`hexists_intro` + `hstar_hpure_l` + `hsingle_intro` 把目标装配回去：

```coq
(* ---------- 98.10 分配的规格 ---------- *)

Lemma triple_ref : forall v,
  triple (val_ref v)
    \[]
    (fun r => \exists p, \[r = val_loc p] \* p ~~> v).
Proof using.
  intros. intros s1 K. applys eval_ref. intros p D.
  lets ->: hempty_inv K. rewrite Fmap.update_empty.
  applys hexists_intro p. rewrite hstar_hpure_l. split*.
  applys hsingle_intro.
Qed.
```

「结果是某个位置且那格内容是 v」这个模式太常用，库给了缩写：
`funloc p => H` 就是 `fun r => \exists p, \[r = val_loc p] \* H`：

```coq
(* funloc 记法：funloc p => H 即 fun r => \exists p, \[r = val_loc p] \* H。 *)

Lemma triple_ref' : forall v,
  triple (val_ref v)
    \[]
    (funloc p => p ~~> v).
Proof using. apply triple_ref. Qed.
```

## 98.11 释放的规格

**练习（2 星）triple_free'**——释放一格：前条件交出 `p ~~> v`，结束后堆为
空。`hsingle_inv` 把单格前提变成等式 `s = Fmap.single p v`，然后
`Fmap.indom_single`（位置在单格映射的域中）与 `Fmap.remove_single`（释放后
恰为空堆）两条有限映射引理收官：

```coq
(* ---------- 98.11 释放的规格 ---------- *)

(* 练习（2 星，标准，必做）：释放一个单格。 *)

Lemma triple_free' : forall p v,
  triple (val_free (val_loc p))
    (p ~~> v)
    (fun r => \[r = val_unit]).
Proof using.
  intros. intros s K. lets ->: hsingle_inv K. applys eval_free.
  { applys* Fmap.indom_single. }
  { rewrite* Fmap.remove_single. applys hpure_intro. auto. }
Qed.
```

「结果是 unit」这条信息几乎从没用处，实用版把后条件取成空：

```coq
(* 实用版：返回值信息无用，后条件取空。 *)

Lemma triple_free : forall p v,
  triple (val_free (val_loc p))
    (p ~~> v)
    (fun _ => \[]).
Proof using. intros. applys triple_conseq triple_free'; xsimpl*. Qed.
```

## 98.12 读的规格

读一格：状态不变、结果是原内容，**且格子还在**（`\[r = v] \* p ~~> v`——
读不是消耗性的）。`Fmap.read_single` 读出单格映射的内容：

```coq
(* ---------- 98.12 读的规格 ---------- *)

Lemma triple_get : forall v p,
  triple (val_get p)
    (p ~~> v)
    (fun r => \[r = v] \* (p ~~> v)).
Proof using.
  intros. intros s K. lets ->: hsingle_inv K. applys eval_get.
  { applys* Fmap.indom_single. }
  { rewrite hstar_hpure_l. split*. rewrite* Fmap.read_single. }
Qed.
```

## 98.13 写的规格

**练习（2 星）triple_set**——写一格：前条件交出旧值 `p ~~> w`，后条件收回
新值 `p ~~> v`。结构与 `triple_get` 完全平行，只是 `Fmap.update_single` 上
场：

```coq
(* ---------- 98.13 写的规格 ---------- *)

(* 练习（2 星，标准，必做）：写一个单格。 *)

Lemma triple_set : forall w p v,
  triple (val_set (val_loc p) v)
    (p ~~> w)
    (fun r => \[r = val_unit] \* (p ~~> v)).
Proof using.
  intros. intros s K. lets ->: hsingle_inv K. applys eval_set.
  { applys* Fmap.indom_single. }
  { rewrite hstar_hpure_l. split*.
    rewrite Fmap.update_single. applys hsingle_intro. }
Qed.
```

到这里，验证一门程序所需的全部规则就齐了。

## 98.14 手工验证示例：incr

93 章证明 `incr` 用了三行（`xwp. xapp. xapp. xapp. xsimpl.`）；现在用裸规
则重做，把 x 战术的工作摊开。程序（A-范式）：

```ocaml
let incr p =
  let n = !p in
  let m = n + 1 in
  p := m
```

裸构造子写法与记法写法逐字相同（`incr_eq_incr'` 用 `reflexivity` 见证），
后者才是人读的版本：

```coq
(* ---------- 98.14 示例程序：incr 的手工验证 ---------- *)

Module ExamplePrograms.
Export ProgramSyntax.

(* incr p = let n = !p in let m = n+1 in p := m，裸构造子写法： *)

Definition incr : val :=
  val_fun "p" (
    trm_let "n" (trm_app val_get (trm_var "p")) (
    trm_let "m" (trm_app (trm_app val_add
                             (trm_var "n")) (val_int 1)) (
    trm_app (trm_app val_set (trm_var "p")) (trm_var "m")))).

(* 同一程序的记法写法： *)

Definition incr' : val :=
  <{ fun 'p =>
       let 'n = ! 'p in
       let 'm = 'n + 1 in
       'p := 'm }>.

Lemma incr_eq_incr' :
  incr = incr'.
Proof using. reflexivity. Qed.
```

规格照旧（`p ~~> n` 进、`p ~~> (n+1)` 出）。下面这份**逐行注解的证明**是
全章的核心——注意 evar `?Q1`（中间后条件）如何被每一步所用的规格「顺便」
定值：

```coq
(* 93 章的三行战术 xwp/xapp 在幕后做的事，用基础规则手工展开如下。
   每一步都注明对应规则；evar ?Q1 由第一步的规格自动定值。 *)

Lemma triple_incr : forall (p:loc) (n:int),
  triple (trm_app incr p)
    (p ~~> n)
    (fun _ => p ~~> (n+1)).
Proof using.
  intros. applys triple_app_fun.
  { reflexivity. }
  simpl.
  applys triple_let.
  { apply triple_get. }
  intros n'. simpl.
  apply triple_hpure. intros ->.
  applys triple_let.
  { applys triple_conseq_frame.
    { applys triple_add. }
    { xsimpl. }
    { xsimpl. } }
  intros m'. simpl.
  apply triple_hpure. intros ->.
  applys triple_conseq_frame.
    { applys triple_set. }
    { xsimpl. }
    { xsimpl. }
Qed.
```

逐步解读（代码自上而下）：

1. `applys triple_app_fun`——函数调用规则：`incr` 是已知值，等式前提
   `incr = val_fun "p" ...` 由 `reflexivity` 关，`simpl` 算出
   `subst "p" p body`；
2. `applys triple_let` 处理 `let 'n = !'p in ...`；子目标用
   `triple_get`，**这步顺带把 evar `?Q1` 定值为
   `fun r => \[r = n] \* p ~~> n`**；
3. `intros n'. simpl.` 给结果值起回源码名并让代换落地；
   `apply triple_hpure. intros ->.` 抽出等式 `n' = n` 并代入，前条件剩
   `p ~~> n`；
4. 第二个 let：`n+1` 只需空堆，`applys triple_conseq_frame` 把
   `p ~~> n` 框出去（`triple_add` 在空堆上跑，两个 `xsimpl` 收边）；
5. 同法抽出 `m' = n+1`；最后 `applys triple_conseq_frame` + `triple_set`
   收回一格，`p ~~> w` 换成 `p ~~> (n+1)`。

对照着读战术版（93 章）：`xwp` ≈ 前两步（展开应用 + 代换）；每个 `xapp` ≈
一次「规格 + 后果-框架」组合——自动找适用的规格引理、自动把多余资源框出
去、自动解出 `?Q1`；`xsimpl` ≈ 最后的蕴含化简。手工版里最繁琐的是「给中
间结果命名 + simpl 算代换 + triple_hpure 抽等式」这套固定动作——后续章节
（Wand 的 ramified frame、WP 系列）正是要消灭它们。

## 98.15 手工验证练习：succ_using_incr

**练习（4 星）**——验证 93 章的 `succ_using_incr`：临时分配一个格子装
`n`，借 `incr` 加一，读回结果，释放，返回。这次要自己安排 `triple_seq`、
`triple_val` 与 `triple_ref'`/`triple_free` 的次序；`funloc` 后条件的存在
量词用 `triple_hexists` + `triple_hpure` 两步抽开：

```coq
(* ---------- 98.15 练习：succ_using_incr 的手工验证 ---------- *)

Definition succ_using_incr : val :=
  <{ fun 'n =>
       let 'r = val_ref 'n in
       incr 'r;
       let 'x = ! 'r in
       val_free 'r;
       'x }>.

(* 练习（4 星，标准，必做）：按 triple_incr 的模式手工验证。 *)

Lemma triple_succ_using_incr : forall (n:int),
  triple (trm_app succ_using_incr n)
    \[]
    (fun v => \[v = val_int (n+1)]).
Proof using.
  intros. applys triple_app_fun.
  { reflexivity. }
  simpl.
  applys triple_let.
  { applys triple_ref'. }
  intros r. simpl.
  applys triple_hexists. intros p. apply triple_hpure. intros ->.
  applys triple_seq.
  { applys triple_incr. }
  applys triple_let.
  { applys triple_get. }
  intros x. simpl.
  apply triple_hpure. intros ->.
  applys triple_seq.
  { applys triple_free. }
  { applys triple_val. xsimpl. auto. }
Qed.
```

两处细节：`applys triple_seq` 不带参数时中间后条件是 evar，由第一个子目标
的证明（`triple_incr`/`triple_free`）自动定值，续体的前条件随即确定；最
后的返回值 `x` 是个值项，用 `triple_val` + `xsimpl` 收尾（`\[]` 换
`\[x = val_int (n+1)]`，纯等式 `auto` 关）。

```coq
End ExamplePrograms.
```

## 98.16 语义相同的项满足相同的三元组

一条很通用却常被忽略的原理：若按语义 `t2` 的行为不多于 `t1`，则 `t2` 满足
`t1` 满足的一切三元组。把它定义成判断 `eval_like`（对一切 `s`、`Q`，`t1`
能到 `Q` 则 `t2` 也能到）：

```coq
(* ---------- 98.16 同语义的项满足相同的三元组 ---------- *)

Module ProofsSameSemantics.

(* eval_like t1 t2：t2 的行为不多于 t1（t1 能到哪，t2 就能到哪）。 *)

Definition eval_like (t1 t2:trm) : Prop :=
  forall s Q, eval s t1 Q -> eval s t2 Q.
```

**练习（1 星）triple_eval_like**——展开 `triple` 后一行：

```coq
(* 练习（1 星，标准，必做）：eval_like 传递三元组。 *)

Lemma triple_eval_like : forall t1 t2 H Q,
  eval_like t1 t2 ->
  triple t1 H Q ->
  triple t2 H Q.
Proof using.
  introv L M. unfolds triple. introv Hs.
  applys L. applys M Hs.
Qed.
```

**应用一：eta 收缩**。`let x = t in x` 与 `t` 语义相同——方向一是
`eval_like t (trm_let x t x)`（书正文给出）：`eval_let` 之后续体的
`subst x v (trm_var x)` 化简为 `trm_val v`，这里 `var_eq_spec` +
`case_if` 处理「变量与自己比较」：

```coq
(* 应用一：let x = t in x 与 t 有相同语义（eta 收缩方向）。 *)

Lemma eval_like_eta_reduction : forall (t:trm) (x:var),
  eval_like t (trm_let x t x).
Proof using.
  introv R. applys eval_let R.
  simpl. rewrite var_eq_spec. case_if.
  introv Hv. applys eval_val Hv.
Qed.
```

**练习（4 星）eta 扩张**——反方向难一些。诀窍：对 `eval` 推导做
`inverts`（只会有 `eval_let` 一个情形，因为构造子形状对不上），拿到
「`t` 以某个 `?Q1` 结束」与续体 `K`；目标里的后条件不同，用 `eval_conseq`
（97 章证过的单调性）换过去；对任意中间结果 `v`、`h`，`K v h` 给出
`eval h (subst x v (trm_var x)) Q`，`simpl` + `var_eq_spec` + `case_if in E`
把它化简成 `eval h (trm_val v) Q`，反演即得 `Q v h`：

```coq
(* 练习（4 星，标准，选做）：eta 扩张方向——对 eval 推导归纳，
   借 eval_conseq 换后条件，代换后的 trm_var x 用 case_if 化简。 *)

Lemma eval_like_eta_expansion : forall (t:trm) (x:var),
  eval_like (trm_let x t x) t.
Proof using.
  introv R. inverts R as M1 K.
  applys eval_conseq M1. introv HK.
  lets E: (K v h HK).
  simpl in E. rewrite var_eq_spec in E. case_if in E.
  inverts E. auto.
Qed.
```

**练习（2 星）eta_same_triples**——两个方向拼起来，`t` 与
`let x = t in x` 满足**完全相同**的三元组集（103 章证两个垃圾回收规则等价
时会用到这条）：

```coq
(* 练习（2 星，标准，必做）：两个方向合起来——eta 前后满足相同三元组。 *)

Lemma eta_same_triples : forall (t:trm) (x:var) H Q,
   triple t H Q <-> triple (trm_let x t x) H Q.
Proof using.
  iff M.
  { applys triple_eval_like M. applys eval_like_eta_reduction. }
  { applys triple_eval_like M. applys eval_like_eta_expansion. }
Qed.
```

**应用二：重看 `triple_app_fun`**——beta 规约前后语义相同，于是调用规则是
`eval_like` 的直接推论：

```coq
(* 应用二：用 eval_like 重看 triple_app_fun——
   beta 规约前后语义相同。 *)

Lemma triple_app_fun' : forall x v1 v2 t1 H Q,
  v1 = val_fun x t1 ->
  triple (subst x v2 t1) H Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv E M1. applys triple_eval_like M1.
  introv R. applys eval_app_fun E R.
Qed.
```

**应用三（练习，3 星）：序列的结合括号重排**——`t1; (t2; t3)` 满足
`(t1;t2); t3` 满足的一切三元组（比如想在 `t1;t2` 整体上套框架规则时用得
上）。先证辅助引理 `eval_seq_swap`：反演左嵌套序列，再用 `eval_seq` 两层
重组——第一步 `M1 : eval s t1 ?Q1` 直接当新序列的开头，其续体里对每个结果
`v1`、`s2`，把 `M2 v1 s2`（`t2` 的执行）与外层续体 `C` 拼成内层序列：

```coq
(* 应用三（练习，3 星，标准，选做）：改写序列的括号结构——
   t1;(t2;t3) 满足 (t1;t2);t3 满足的一切三元组。
   辅引理把左嵌套的序列拆开。 *)

Lemma eval_seq_swap : forall s t1 t2 Q1',
  eval s (trm_seq t1 t2) Q1' ->
  forall t3 Q, (forall v s', Q1' v s' -> eval s' t3 Q) ->
  eval s (trm_seq t1 (trm_seq t2 t3)) Q.
Proof using.
  introv M. inverts M as M1 M2. intros t3 Q C.
  applys eval_seq M1. intros v1 s2 Hv.
  applys eval_seq (M2 v1 s2 Hv). exact C.
Qed.

Lemma triple_trm_seq_assoc : forall t1 t2 t3 H Q,
  triple (trm_seq (trm_seq t1 t2) t3) H Q ->
  triple (trm_seq t1 (trm_seq t2 t3)) H Q.
Proof using.
  introv M. applys triple_eval_like M.
  introv R. inverts R as R1 K.
  applys eval_seq_swap R1 K.
Qed.
```

注意 `inverts R as R1 K` 给反演出的两个前提命名——比依赖自动名
（`H2`/`H4`）稳得多。

```coq
End ProofsSameSemantics.
```

## 98.17 组合的 let-框架规则

直觉：验证 `let x = t1 in t2` 时，`t1` 往往只需要前条件 `H` 的**一部分**。
把 let 规则与框架规则合并，就得到明确表达这点的规则——`H` 拆成 `H1`（归
`t1` 用）与 `H2`（原样传给续体）：

**练习（3 星）**。证明要点：给 `triple_let` 显式指定中间后条件
`Q1 \*+ H2`（第一步的结果带上框架）；第一个子目标用后果-框架规则从 `M` 抬
上来；第二个子目标里 `(Q1 \*+ H2) v1` 按 `\*+` 的定义就是 `Q1 v1 \* H2`，
与 `M2 v1` 定义相等，直接 `applys`：

```coq
(* ---------- 98.17 组合的 let-框架规则 ---------- *)

Module LetFrame.

(* 练习（3 星，标准，必做）：把 let 规则与框架规则合起来——
   第一步只需前条件中属于自己的那块 H1，框架 H2 原样留给续体。 *)

Lemma triple_let_frame : forall x t1 t2 Q1 H H1 H2 Q,
  triple t1 H1 Q1 ->
  H ==> H1 \* H2 ->
  (forall v1, triple (subst x v1 t2) (Q1 v1 \* H2) Q) ->
  triple (trm_let x t1 t2) H Q.
Proof using.
  introv M WH M2. applys triple_let (Q1 \*+ H2).
  { applys triple_conseq_frame M WH. xsimpl. }
  { intros v1. applys (M2 v1). }
Qed.

End LetFrame.
```

这条规则正是 `xapp` 处理「调用一个只动部分内存的函数」时的内部实现——
93 章你已经在 `push`/`pop` 等例子中反复受益于它。

## 98.18 纯前条件的另一种规格风格

除法的除零前提也可以从前提高挪进前条件里：`triple (val_div n1 n2)
\[n2 <> 0] (...)`。用 `triple_hpure'`（97 章的推论，98.20 会复刻证明）一
行导出：

```coq
(* ---------- 98.18 纯前条件的另一种规格风格 ---------- *)

Module DivSpec.

(* 除零前提也可以放进前条件 \[n2 <> 0]：两种风格等价。 *)

Lemma triple_div' : forall n1 n2,
  triple (val_div n1 n2)
    \[n2 <> 0]
    (fun r => \[r = val_int (Z.quot n1 n2)]).
Proof using.
  intros. applys triple_hpure'. applys triple_div.
Qed.
```

**练习（2 星）**——反方向：用后果-框架规则，把 `\[]` 抬到
`\[n2 <> 0] \* \[]`（纯事实由 `auto` 从上下文 `Hn` 提供），后条件侧两边相
同、`xsimpl` 归一化后 `auto` 收：

```coq
(* 练习（2 星，标准，必做）：反方向。 *)

Lemma triple_div_from_triple_div' : forall n1 n2,
  n2 <> 0 ->
  triple (val_div n1 n2)
    \[]
    (fun r => \[r = val_int (Z.quot n1 n2)]).
Proof using.
  introv Hn. applys triple_conseq_frame triple_div'.
  { xsimpl. auto. }
  { intros r. xsimpl. auto. }
Qed.

End DivSpec.
```

两种风格等价，但**约定采用前者**（纯事实放三元组外）：规格使用起来更顺——
应用规格时前提是普通的 Rocq 命题，不必先拆纯前条件。前条件里只留「堆上有
什么」。

## 98.19 结果值的另一种规格风格（对照）

`ref` 的后条件也可以用模式匹配而非存在量词写——但既难读又难用（`xsimpl`
不认识它），仅作对照：

```coq
(* ---------- 98.19 结果值的另一种规格风格（对照） ---------- *)

Module MatchStyle.

(* ref 的后条件也可用 match 而非存在量词来写，但可读性差、不便使用： *)

Parameter triple_ref'' : forall v,
  triple (val_ref v)
    \[]
    (fun r => match r with
              | val_loc p => (p ~~> v)
              | _ => \[False]
              end).

End MatchStyle.
```

## 98.20 递归示例：factorec 的手工验证

最后是本章压轴：手工验证递归函数（93 章用 `xapp (>> IH ...)` 三招解决的
`factorec`）。准备工作有三样。

其一，复刻 `triple_hpure'`（97 章证过；用库的 `triple_conseq`/
`triple_hpure`，两行）——注意它处理的是**纯前条件** `\[P]`（无星号），
与 `triple_hpure`（`\[P] \* H`）分工不同：

```coq
(* ---------- 98.20 递归示例：factorec 的手工验证 ---------- *)

Module ExamplePrograms2.
Export ProgramSyntax.

(* triple_hpure' 在 97 章证过，这里复刻（用库的 triple_conseq/triple_hpure）。 *)

Lemma triple_hpure' : forall t (P:Prop) Q,
  (P -> triple t \[] Q) ->
  triple t \[P] Q.
Proof using.
  introv M. applys triple_conseq (triple_hpure M).
  { xsimpl. auto. }
  { applys qimpl_refl. }
Qed.
```

其二，补齐 `<=`、`-`、`*` 三个原语的规格。库把二元原语统一编码成
`eval_binop` + `evalbinop_le/sub/mul`（各构造子给出结果值的刻画），照
`eval_add` 的模式各导出一条专用 eval 规则与一条 triple 规格——注意 `le`
的结果是布尔值 `val_bool (isTrue (n1 <= n2))`，这正是 93 章 `xif` 能对条件
做分类讨论的来源：

```coq
(* 库把二元原语统一编码成 eval_binop + evalbinop_*；
   这里按 eval_add 的模式导出三个专用规则。 *)

Lemma eval_le : forall s n1 n2 Q,
  Q (val_bool (isTrue (n1 <= n2))) s ->
  eval s (val_le (val_int n1) (val_int n2)) Q.
Proof using.
  intros. applys* eval_binop.
  { applys* evalbinop_le. }
  { intros ? ->. auto. }
Qed.

Lemma eval_sub : forall s n1 n2 Q,
  Q (val_int (n1 - n2)) s ->
  eval s (val_sub (val_int n1) (val_int n2)) Q.
Proof using.
  intros. applys* eval_binop.
  { applys* evalbinop_sub. }
  { intros ? ->. auto. }
Qed.

Lemma eval_mul : forall s n1 n2 Q,
  Q (val_int (n1 * n2)) s ->
  eval s (val_mul (val_int n1) (val_int n2)) Q.
Proof using.
  intros. applys* eval_binop.
  { applys* evalbinop_mul. }
  { intros ? ->. auto. }
Qed.

Lemma triple_le : forall n1 n2,
  triple (val_le n1 n2)
    \[]
    (fun r => \[r = val_bool (isTrue (n1 <= n2))]).
Proof using.
  introv Hs. applys* eval_le. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

Lemma triple_sub : forall n1 n2,
  triple (val_sub n1 n2)
    \[]
    (fun r => \[r = val_int (n1 - n2)]).
Proof using.
  introv Hs. applys* eval_sub. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

Lemma triple_mul : forall n1 n2,
  triple (val_mul n1 n2)
    \[]
    (fun r => \[r = val_int (n1 * n2)]).
Proof using.
  introv Hs. applys* eval_mul. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.
```

其三，`facto` 的公理化（与 93 章相同的三条），以及程序本身：

```coq
(* facto 的公理化（与 93 章一致）： *)

Module Facto.

Parameter facto : int -> int.

Parameter facto_init : forall n,
  0 <= n <= 1 ->
  facto n = 1.

Parameter facto_step : forall n,
  n >= 1 ->
  facto n = n * (facto (n-1)).

End Facto.

Import Facto.

Definition factorec : val :=
  <{ fix 'f 'n =>
       let 'b = ('n <= 1) in
       if 'b
         then 1
         else let 'x = 'n - 1 in
              let 'y = 'f 'x in
              'n * 'y }>.
```

**练习（4 星）triple_factorec**。骨架与 93 章相同：`induction_wf` 在
`downto 0` 上做良基归纳，归纳假设 `IH` 就是递归调用的规格。手工版的看点：

- `applys triple_app_fix` + `reflexivity` + `simpl` 处理双重代入；
- `triple_le` 的后条件是**纯**的 `\[b = ...]`，所以用 `triple_hpure'`（而非
  `triple_hpure`）抽出等式，`intros ->` 把 `b` 代换成布尔值后 `triple_if`
  才适用；
- `case_if as C. rew_bool_eq in *.` 把 `isTrue (n <= 1) = true/false` 翻译
  回纯算术事实 `C`；
- 真分支：`triple_val` + `facto_init`（`n <= 1` 与 `n >= 0` 合出
  `0 <= n <= 1`）；
- 假分支：`triple_sub` → 递归调用用 `IH`（两个算术义务：`0 <= n-1 < n` 与
  `n-1 >= 0`）→ `triple_mul` + 后果-框架，收尾用 `facto_step` 改写：

```coq
(* 练习（4 星，标准，必做）：手工验证递归函数——
   良基归纳提供递归调用规格，分支与代入按 triple_incr 的模式处理。 *)

Lemma triple_factorec : forall n,
  n >= 0 ->
  triple (factorec n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  intros n. induction_wf IH: (downto 0) n. unfold downto in IH.
  intros Hn.
  applys triple_app_fix.
  { reflexivity. }
  simpl.
  applys triple_let.
  { applys triple_le. }
  intros b. simpl.
  applys triple_hpure'. intros ->.
  applys triple_if. case_if as C. rew_bool_eq in *.
  { applys triple_val. xsimpl.
    asserts E: (facto n = 1). { applys facto_init. math. }
    rewrite E. auto. }
  { applys triple_let.
    { applys triple_sub. }
    intros x. simpl. applys triple_hpure'. intros ->.
    applys triple_let.
    { applys IH. math. math. }
    intros y. simpl. applys triple_hpure'. intros ->.
    applys triple_conseq_frame.
    { applys triple_mul. }
    { xsimpl. }
    { intros r. xsimpl. intros ->.
      asserts H1: (n >= 1). { math. }
      rewrite (@facto_step n H1). auto. } }
Qed.

End ExamplePrograms2.
```

对照 93 章的战术版：`xwp` ≈ `triple_app_fix` + `simpl`；`xif` ≈
`triple_if` + `case_if` + `rew_bool_eq`；`xapp (>> IH ...)` ≈ `applys IH` +
两个算术义务。手工版 30 行、战术版 10 行——节省的正是「命名中间值、算代
换、抽等式」这套流水线操作。

## 98.21 小结

```coq
(* ---------- 98.21 小结 ----------
   1) 语言构件规则（seq/let/if/val/fun/fix/app）全部由 97 章的 eval 规则
      一行导出；app 类规则要求被调函数是已知的具体值；
   2) 原语规格遵循"最小足迹"约定：前条件只覆盖必须访问的内存；
   3) triple_incr 的手工证明揭示了 x 战术的四大件：结构规则、构件规则、
      原语规格与 xsimpl；evar ?Q1 由所用规格自动定值；
   4) eval_like 原理：语义等价的项满足相同三元组（eta、括号重排等）；
   5) 后续章节将自动化框架规则的应用、消除程序变量与代换的手工操作。 *)
```

一句话：**97 章给出 `triple` 的语义地基，本章把每种语法构件的推理规则和每
个原语的规格在地基上盖起来**；`triple_incr`/`triple_factorec` 的手工证明表
明 x 战术没有任何魔法——只是把「规则选择 + 框架推理 + 代换化简 + 蕴含收
尾」四件事自动化了。接下来两章（99 Wand、100+ WP 系列）继续为这套自动化
补理论：先给堆谓词代数添上「魔法分离合取」，再进入最弱前条件的世界。

### 实测坑位（rocq 9.1.1 实编译经验）

- **`introv` 只给「末尾的假设」命名**：目标 `forall v1, triple ...`（变量
  非假设）用 `introv v1` 会报 "No matching clauses for match"，改用
  `intros v1`。`introv M1 M2 Hs` 里三者都是前提（假设），没问题。
- **`applys L 证明项` 会按首匹配填参**：若引理的结论还没对齐就喂证明，可能
  把它塞进错误的槽（如 `triple_div' n1 n2` 中 `n2` 被隐式化导致填错位）。
  稳妥做法：`applys L`（裸用，让结论统一目标）或 `applys triple_let (fun v
  => ...)`（显式给中间量）。
- **xsimpl 会给 evar 后条件「顺便」定值**：`triple_let_frame` 第一个子目标
  的 `xsimpl` 把 `?Q1` 定成了 `Q1 \*+ H2`，于是第二个子目标变成定义相等、
  一行 `applys (M2 v1)` 即可——显式写 `applys triple_let (Q1 \*+ H2)` 让这
  个意图可见。
- **纯后条件抽等式用 `triple_hpure'`**：`triple_le`/`triple_sub`/IH 的后条
  件是纯的 `\[r = ...]`（无星号），`apply triple_hpure` 会因形状
  `\[P] \* H` 对不上而失败。
- **`asserts`（TLC）而非 `assert`**：本库证明风格统一用 `asserts E: (P).`
  （自动带 intros），某些位置裸 `assert` 解析会失败。
- **`rewrite (@facto_step n H1)`**：`Set Implicit Arguments` 下引理参数常
  被隐式化，`rewrite (facto_step n H1)` 会把 `n` 喂进前提槽；用 `@` 全显
  式最稳。
- **良基归纳的 IH 可能带两个前提**：`unfold downto in IH` 后 `IH : forall
  y, 0 <= y < n -> y >= 0 -> ...`，`applys IH` 之后要准备两个 `math` 义
  务。
