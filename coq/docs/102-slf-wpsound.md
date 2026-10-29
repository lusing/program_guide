# 102. wpgen 的可靠性证明

对应示例：`../examples/102_slf_wpsound.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

取材 Software Foundations 卷六 *Separation Logic Foundations*（v1.0）的 *WPsound* 章。

---

## 102.0 从“会生成公式”到“生成公式一定正确”

第 101 章构造了特征公式生成器 `wpgen`，并用它实现了 `xwp`、`xapp` 等战术。但自动化战术能把证明目标变形，并不代表这种变形一定合法。本章要补上元理论保证：

> 对任意上下文 `E`、项 `t` 和后条件 `Q`，都有 `wpgen E t Q ==> wp (isubst E t) Q`。

这里 `==>` 的方向很重要。`wpgen` 给出的前条件可以比真正的最弱前条件更强，因此它足够用来验证程序；但它不能弱于 `wp`，否则可能接受本来不满足规格的程序。把 `E` 取为空列表后，就得到闭项版本 `wpgen nil t Q ==> wp t Q`，再通过 `wp_equiv` 转成 Hoare 三元组。

证明按 `t` 的语法结构归纳。每个分支都由两部分组成：

1. 一个针对语法构造的可靠性引理，例如 `wpgen_seq_sound`；
2. 一个统一处理外层 `mkstruct` 的引理 `mkstruct_sound`。

let、普通函数和递归函数分支还涉及上下文与替换的等式。因此示例先完整证明这些技术引理，再进入主归纳；阅读时也可以先看 102.2 的核心论证，再回来查看 102.1 的细节。

示例导入 SLF 参考库，但本章所有可靠性定理和替换引理都在 `WPsound` 模块中重新证明，没有把原书的练习或关键结论留作 `Parameter`、`Axiom` 或 `Admitted`。

```coq
(* 102 wpgen 的可靠性：结构公式、语法分支、替换性质与主归纳 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 WPsound 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types v : val.
Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

Module WPsound.

Open Scope liblist_scope.

Implicit Types E : ctx.
```

---

## 102.1 多重替换的技术引理

### 102.1.1 空替换与单点替换

`ctx` 是 `(var * val)` 的列表，`isubst E t` 按上下文 `E` 对 `t` 做多重替换。主定理最后要把 `isubst nil t` 化简为 `t`；这不只是 `simpl` 能完成的计算，因为 `isubst` 对项递归，而 `E` 虽为空，`t` 仍是任意项。因此对 `t` 作结构归纳，`fequals` 把各构造子的递归子目标交给归纳假设。

```coq
(* ---------- 102.1 多重替换的技术引理 ---------- *)

Module IsubstProp.

(* 空上下文不改变项；对项作结构归纳后，fequals 处理所有递归子项。 *)

Lemma isubst_nil : forall t,
  isubst nil t = t.
Proof using.
  intros t. induction t; simpl; fequals.
Qed.
```

普通替换 `subst x v t` 与上下文 `((x,v)::nil)` 的多重替换应当一致。证明仍按项归纳。变量分支比较待替换变量与当前变量；`fun`、`fix` 和 `let` 分支还要处理遮蔽：若绑定名就是 `x`，绑定体内不再执行这次替换。`case_var` 展开变量相等性测试，`case_var*` 同时尝试关闭显然分支。

```coq
(* 单次 subst 就是只含一个绑定的 isubst。函数、递归函数与 let
   的分支需要 case_var 分析绑定变量是否遮蔽本次替换。 *)

Lemma subst_eq_isubst_one : forall x v t,
  subst x v t = isubst ((x,v)::nil) t.
Proof using.
  intros. induction t; simpl.
  { fequals. }
  { case_var*. }
  { fequals. case_var*. { rewrite* isubst_nil. } }
  { fequals. case_var; try case_var; simpl; try case_var;
              try rewrite isubst_nil; auto. }
  { fequals*. }
  { fequals*. }
  { fequals*. case_var*. { rewrite* isubst_nil. } }
  { fequals*. }
Qed.
```

### 102.1.2 删除、查找与上下文拼接

`rem y E` 删除上下文中关于 `y` 的绑定。删除后查找 `x`：若 `x = y`，结果必为 `None`；否则结果与在原上下文中查找相同。证明对列表归纳，并反复分析变量相等性。

```coq
(* 从上下文删去 y 后，查找 x 的结果由 x 与 y 是否相等决定。 *)

Lemma lookup_rem : forall x y E,
  lookup x (rem y E) = if var_eq x y then None else lookup x E.
Proof using.
  intros. induction E as [|(z,v) E'].
  { simpl. case_var*. }
  { simpl. case_var*; simpl; case_var*. }
Qed.
```

删除操作也会分配到拼接的两段上。`rew_list` 化简列表拼接，归纳步骤只需处理当前绑定是否被删除。

```coq
(* rem 与上下文拼接交换。 *)

Lemma rem_app : forall x E1 E2,
  rem x (E1 ++ E2) = rem x E1 ++ rem x E2.
Proof using.
  intros. induction E1 as [|(y,w) E1']; rew_list; simpl. { auto. }
  { case_var*. { rew_list. fequals. } }
Qed.
```

### 102.1.3 上下文等价与定义域不相交

列表的物理排列并不是替换所关心的全部信息。真正影响 `isubst` 的是查找结果，因此定义 `ctx_equiv E1 E2`：每个变量在两个上下文中的 `lookup` 结果都相同。删除同一个变量保持这种等价。

```coq
(* 两个上下文等价，指每个变量在二者中的查找结果都相同。 *)

Definition ctx_equiv E1 E2 :=
  forall x, lookup x E1 = lookup x E2.

Lemma ctx_equiv_rem : forall x E1 E2,
  ctx_equiv E1 E2 ->
  ctx_equiv (rem x E1) (rem x E2).
Proof using.
  introv M. unfolds ctx_equiv. intros y.
  do 2 rewrite lookup_rem. case_var*.
Qed.
```

对项作结构归纳即可证明：等价上下文产生相同替换。函数和 let 等绑定构造会在递归调用前删除变量，所以把 `ctx_equiv_rem` 注册为提示，供自动化使用。变量分支直接重写等价假设 `EQ`。

```coq
(* isubst 只通过 lookup 读取上下文，因此等价上下文给出相同结果。 *)

Lemma isubst_ctx_equiv : forall t E1 E2,
  ctx_equiv E1 E2 ->
  isubst E1 t = isubst E2 t.
Proof using.
  hint ctx_equiv_rem.
  intros t. induction t; introv EQ; simpl; fequals*.
  { rewrite EQ. auto. }
Qed.
```

另一个所需关系是定义域不相交：同一个变量不可能在 `E1` 与 `E2` 中都查找成功。删除绑定只会缩小定义域，所以保持不相交。

```coq
(* 定义域不相交：不存在一个变量能在两个上下文中同时查找成功。 *)

Definition ctx_disjoint E1 E2 :=
  forall x v1 v2, lookup x E1 = Some v1 -> lookup x E2 = Some v2 -> False.

Lemma ctx_disjoint_rem : forall x E1 E2,
  ctx_disjoint E1 E2 ->
  ctx_disjoint (rem x E1) (rem x E2).
Proof using.
  introv D. intros y v1 v2 K1 K2. rewrite lookup_rem in *.
  case_var. applys* D K1 K2.
Qed.
```

### 102.1.4 拼接与依次替换

拼接列表的查找规则是“左侧优先”：在 `E1` 中找到就返回该值，否则才查 `E2`。

```coq
(* 拼接上下文的查找优先使用左侧绑定。 *)

Lemma lookup_app : forall x E1 E2,
  lookup x (E1 ++ E2) = match lookup x E1 with
                        | None => lookup x E2
                        | Some v => Some v
                        end.
Proof using.
  introv. induction E1 as [|(y,w) E1']; rew_list; simpl; intros.
  { auto. }
  { case_var*. }
Qed.
```

由此得到拼接与依次替换的关系。注意右侧顺序：先 `isubst E1`，再 `isubst E2`。变量分支分别讨论两次查找是否成功；绑定分支使用 `rem_app`，其他复合项分支直接使用归纳假设。

```coq
(* 拼接上下文对应依次替换；注意 isubst 从列表头部开始处理，
   所以等式右侧先执行 E1，再执行 E2。 *)

Lemma isubst_app : forall t E1 E2,
  isubst (E1 ++ E2) t = isubst E2 (isubst E1 t).
Proof using.
  hint ctx_disjoint_rem.
  intros t. induction t; simpl; intros.
  { fequals. }
  { rename v into x. rewrite* lookup_app.
    case_eq (lookup x E1); introv K1; case_eq (lookup x E2); introv K2; auto.
    { simpl. rewrite* K2. }
    { simpl. rewrite* K2. } }
  { fequals. rewrite* rem_app. }
  { fequals. do 2 rewrite* rem_app. }
  { fequals*. }
  { fequals*. }
  { fequals*. { rewrite* rem_app. } }
  { fequals*. }
Qed.
```

若两段定义域不相交，交换拼接顺序不会改变任何查找结果，因此也不会改变替换。库引理 `ctx_disjoint_equiv_app` 给出查找层面的交换性质，本例再用刚才证明的 `isubst_ctx_equiv` 提升到项替换层面。

```coq
(* 若定义域不相交，拼接顺序不影响替换结果。 *)

Lemma isubst_app_swap : forall t E1 E2,
  ctx_disjoint E1 E2 ->
  isubst (E1 ++ E2) t = isubst (E2 ++ E1) t.
Proof using.
  introv D. applys isubst_ctx_equiv. applys* ctx_disjoint_equiv_app.
Qed.
```

### 102.1.5 let 与递归函数所需的替换等式

let 的可靠性归纳会得到 `isubst ((x,v)::E) t2`，而 `wpgen_let_sound` 需要 `subst x v (isubst (rem x E) t2)`。二者相等的原因如下：

1. 用 `subst_eq_isubst_one` 把单点替换写成单元素上下文；
2. 用 `isubst_app` 把依次替换合并为列表拼接；
3. 单元素上下文与 `rem x E` 的定义域不相交，因此可以交换顺序；
4. 交换后的上下文与原上下文查找等价。

第二个证明分支正是定义域不相交：若变量等于 `x`，它在 `rem x E` 中不可能查找成功。

```coq
(* let 分支所需的关键等式：先删除旧绑定再添加新绑定，
   等价于先对删除旧绑定的上下文做多重替换，再做一次普通替换。 *)

Lemma isubst_rem : forall x v E t,
  isubst ((x, v)::E) t = subst x v (isubst (rem x E) t).
Proof using.
  intros. rewrite subst_eq_isubst_one. rewrite <- isubst_app.
  rewrite isubst_app_swap.
  { applys isubst_ctx_equiv. intros y. rew_list. simpl. case_var*.
    { rewrite lookup_rem. case_var*. } }
  { intros y v1 v2 K1 K2. simpls. case_var.
    { subst. rewrite lookup_rem in K1. case_var*. } }
Qed.
```

递归函数调用要同时代入递归函数名 `f` 和参数名 `x`。证明采用同样的拼接、交换与上下文等价论证，只是多了一层绑定与删除。

```coq
(* 递归函数分支需要同时处理函数名 f 与参数名 x。 *)

Lemma isubst_rem_2 : forall f x vf vx E t,
    isubst ((f,vf)::(x,vx)::E) t
  = subst x vx (subst f vf (isubst (rem x (rem f E)) t)).
Proof using.
  intros. do 2 rewrite subst_eq_isubst_one. do 2 rewrite <- isubst_app.
  rewrite isubst_app_swap.
  { applys isubst_ctx_equiv. intros y. rew_list. simpl.
    do 2 rewrite lookup_rem. case_var*. }
  { intros y v1 v2 K1 K2. rew_listx in *. simpls.
    do 2 rewrite lookup_rem in K1. case_var. }
Qed.

End IsubstProp.

Import IsubstProp.
```

---

## 102.2 各语法构造的可靠性

### 102.2.1 用 formula_sound 组织归纳假设

直接陈述 `F Q ==> wp t Q` 会在每个引理中重复量词与蕴含。定义 `formula_sound t F` 后，归纳假设更加清楚：公式 `F` 对项 `t` 可靠，就是对所有后条件 `Q` 都有 `F Q ==> wp t Q`。

```coq
(* ---------- 102.2 公式可靠性的谓词 ---------- *)

(* F 是项 t 的可靠公式，当且仅当对任意后条件 Q，
   F Q 都蕴含语义最弱前条件 wp t Q。 *)

Definition formula_sound (t:trm) (F:formula) : Prop :=
  forall Q, F Q ==> wp t Q.
```

### 102.2.2 序列：把两段可靠性接起来

回顾生成公式与语义规则：

- `wpgen_seq F1 F2 Q = F1 (fun _ => F2 Q)`；
- `wp_seq` 给出 `wp t1 (fun _ => wp t2 Q) ==> wp (trm_seq t1 t2) Q`。

若 `F1` 对 `t1` 可靠、`F2` 对 `t2` 可靠，就有蕴含链：

```text
F1 (fun _ => F2 Q)
==> wp t1 (fun _ => F2 Q)
==> wp t1 (fun _ => wp t2 Q)
==> wp (trm_seq t1 t2) Q.
```

第二步不是直接再次使用蕴含传递，而是在 `wp t1` 的后条件中使用 `wp_conseq`。这体现了“后条件中的下一段程序”也需要可靠性假设。

```coq
(* 序列分支把两个归纳假设接在 wp_seq 前面：
   先用 S1 处理第一段，再用 wp_conseq 与 S2 处理第二段。 *)

Lemma wpgen_seq_sound : forall t1' t2' F1 F2,
  formula_sound t1' F1 ->
  formula_sound t2' F2 ->
  formula_sound (trm_seq t1' t2') (wpgen_seq F1 F2).
Proof using.
  introv S1 S2. unfolds formula_sound. intros Q. unfolds wpgen_seq.
  applys himpl_trans.
  2:{ applys wp_seq. }
  { applys himpl_trans.
    { applys S1. }
    { applys wp_conseq. intros v. applys S2. } }
Qed.
```

### 102.2.3 值、let、条件、应用与失败

值分支最直接：`wpgen_val v Q` 就是 `Q v`，而 `wp_val` 正是 `Q v ==> wp (trm_val v) Q`。

```coq
(* 值、let、条件、应用与失败公式分别对应一个 wp 规则。 *)

Lemma wpgen_val_sound : forall v,
  formula_sound (trm_val v) (wpgen_val v).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_val. Qed.
```

let 与序列相似，但第二段的项是 `subst x v t2`，公式是 `F2of v`。第二个前提对任意值 `v` 给出可靠性，恰好能放进 `wp_let` 的后条件。证明先用 `wp_let` 处理最右端，再对第一段应用 `S1`，对后条件应用 `S2`。

```coq
Lemma wpgen_let_sound : forall F1 F2of x t1 t2,
  formula_sound t1 F1 ->
  (forall v, formula_sound (subst x v t2) (F2of v)) ->
  formula_sound (trm_let x t1 t2) (wpgen_let F1 F2of).
Proof using.
  introv S1 S2. intros Q. unfolds wpgen_let. applys himpl_trans_r wp_let.
  applys himpl_trans S1. applys wp_conseq. intros v. applys S2.
Qed.
```

条件公式先存在量化一个布尔值 `b`，并用纯事实保证条件项就是该布尔值。`xpull` 抽出 `b` 和等式，`intros b ->` 用等式替换条件项；随后 `case_if` 选择分支，分别使用两个可靠性假设。

```coq
Lemma wpgen_if_sound : forall F1 F2 t0 t1 t2,
  formula_sound t1 F1 ->
  formula_sound t2 F2 ->
  formula_sound (trm_if t0 t1 t2) (wpgen_if t0 F1 F2).
Proof using.
  introv S1 S2. intros Q. unfold wpgen_if. xpull. intros b ->.
  applys himpl_trans_r wp_if. case_if. { applys S1. } { applys S2. }
Qed.
```

一般应用公式 `wpgen_app t Q` 包含一个三元组 `triple t H Q`。抽出这个三元组后，`rewrite wp_equiv` 恰好把目标转成同一个三元组，因此假设 `M` 直接关闭目标。

```coq
Lemma wpgen_app_sound : forall t,
  formula_sound t (wpgen_app t).
Proof using.
  intros t Q. unfold wpgen_app. xpull. intros H M. rewrite wp_equiv. apply M.
Qed.
```

未绑定变量使用 `wpgen_fail`，即纯假公式。`\[False] \* ...` 不可能成立，所以它可以蕴含任何 `wp`；`xpull` 会从假设中得到矛盾并关闭目标。

```coq
Lemma wpgen_fail_sound : forall t,
  formula_sound t wpgen_fail.
Proof using. intros. intros Q. unfold wpgen_fail. xpull. Qed.
```

### 102.2.4 普通函数与递归函数

最终版 `wpgen` 会递归进入局部函数体。`wpgen_fun Fof` 不是简单返回 `Q (val_fun x t1)`，而是带有一个“当前闭包可如何调用”的规格。可靠性证明把全称量词实例化为当前闭包 `val_fun x t1`，再消去堆谓词中的纯事实魔法杖：

- 调用侧通过 `wp_app_fun` 归结为代入参数后的函数体；
- 函数体的公式由前提 `M vx` 保证可靠；
- 剩下的闭包值本身由 `wp_fun` 处理。

```coq
(* 函数公式包含一个对任意调用的规格。把全称量词实例化为当前闭包，
   再消去纯事实魔法杖，就分别得到 wp_app_fun 与 wp_app_fix 所需前提。 *)

Lemma wpgen_fun_sound : forall x t1 Fof,
  (forall vx, formula_sound (subst x vx t1) (Fof vx)) ->
  formula_sound (trm_fun x t1) (wpgen_fun Fof).
Proof using.
  introv M. intros Q. unfolds wpgen_fun. applys himpl_hforall_l (val_fun x t1).
  xchange hwand_hpure_l.
  { intros. applys himpl_trans_r. { applys* wp_app_fun. } { applys* M. } }
  { applys wp_fun. }
Qed.
```

递归函数的差别只是代入两次：先代入递归闭包 `vf`，再代入参数 `vx`。对应使用 `wp_app_fix` 与 `wp_fix`。

```coq
Lemma wpgen_fix_sound : forall f x t1 Fof,
  (forall vf vx, formula_sound (subst x vx (subst f vf t1)) (Fof vf vx)) ->
  formula_sound (trm_fix f x t1) (wpgen_fix Fof).
Proof using.
  introv M. intros Q. unfolds wpgen_fix.
  applys himpl_hforall_l (val_fix f x t1). xchange hwand_hpure_l.
  { intros. applys himpl_trans_r. { applys* wp_app_fix. } { applys* M. } }
  { applys wp_fix. }
Qed.
```

第 101 章还出现过不递归进入函数体的教学版生成器。那个版本把函数定义当作普通值，因此只需要下面两条更简单的可靠性引理；本章一并给出，以说明两种生成器设计各自的可靠性依据。

```coq
(* 第 101 章的教学版生成器不递归进入函数体；此时闭包直接按值处理。 *)

Lemma wpgen_fun_val_sound : forall x t,
  formula_sound (trm_fun x t) (wpgen_val (val_fun x t)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fun. Qed.

Lemma wpgen_fix_val_sound : forall f x t,
  formula_sound (trm_fix f x t) (wpgen_val (val_fix f x t)).
Proof using. intros. intros Q. unfolds wpgen_val. applys wp_fix. Qed.
```

---

## 102.3 为什么可以包一层 mkstruct

### 102.3.1 wp 已经吸收结构规则

`mkstruct` 把后果规则与框架规则加入任意公式：

```text
mkstruct F Q = ∃ Q₁, F Q₁ * (Q₁ --* Q).
```

但语义最弱前条件 `wp t` 本身已经满足这些结构规则，所以 `mkstruct (wp t)` 与 `wp t` 相等。证明两个方向：

- 左到右展开 `mkstruct`，得到 `wp t Q' * (Q' --* Q)`，用 `wp_conseq_frame` 合并为 `wp t Q`；
- 右到左使用 `mkstruct_erase`，即任何 `F Q` 都蕴含 `mkstruct F Q`。

由于这是公式的等式，先用函数外延性引入后条件 `Q`，再用分离蕴含的反对称性。

```coq
(* ---------- 102.3 mkstruct 保持可靠性 ---------- *)

(* wp 本身已吸收框架与后果规则，所以外面再包一层 mkstruct 不改变它。 *)

Lemma mkstruct_wp : forall t,
  mkstruct (wp t) = (wp t).
Proof using.
  intros. applys fun_ext_1. intros Q. applys himpl_antisym.
  { unfold mkstruct. xpull. intros H Q' M. applys wp_conseq_frame M. xsimpl. }
  { applys mkstruct_erase. }
Qed.
```

### 102.3.2 mkstruct_sound 的两种证明

若 `F` 对 `t` 可靠，则 `mkstruct F` 也可靠。第一种证明非常短：把目标中的 `wp t` 反向改写为 `mkstruct (wp t)`，再用 `mkstruct_monotone` 对内部公式应用可靠性假设。

```coq
Lemma mkstruct_sound : forall t F,
  formula_sound t F ->
  formula_sound t (mkstruct F).
Proof using.
  introv M. unfolds formula_sound. intros Q.
  rewrite <- mkstruct_wp. applys mkstruct_monotone. applys M.
Qed.
```

第二种证明展开所有定义。`mkstruct F Q` 给出某个中间后条件 `Q'`；对 `Q'` 使用 `M` 得到 `wp t Q'`，最后用 `wp_ramified` 同时消费框架和魔法杖。这种证明更直接地显示了 `mkstruct` 为什么恰好对应结构规则。

```coq
(* 同一结果的底层证明：展开 mkstruct，再直接使用 wp 的分支框架规则。 *)

Lemma mkstruct_sound' : forall t F,
  formula_sound t F ->
  formula_sound t (mkstruct F).
Proof using.
  introv M. unfolds formula_sound. intros Q. unfolds mkstruct.
  xsimpl. intros Q'. xchange (M Q'). applys wp_ramified.
Qed.
```

### 102.3.3 原书练习：mkstruct 幂等

幂等性说明重复添加结构规则不会增加公式能力：

```text
mkstruct (mkstruct F) = mkstruct F.
```

直观上，两层后果规则可以由后条件蕴含的传递性合并，两层框架也可以由分离合取的结合律合并。形式证明同样分两个方向：

1. 左到右展开两层 `mkstruct`，抽出两个中间后条件 `Q1`、`Q2`。`xsimpl` 选择真正到达 `F` 的那个后条件，并合并 `(Q2 --* Q1)` 与 `(Q1 --* Q)` 两段魔法杖。
2. 右到左不需要展开，直接把 `mkstruct_erase` 用于 `F := mkstruct F`。

这就是原书三星练习 `mkstruct_idempotent` 的完整解答，没有遗留证明洞。

```coq
(* 原书练习（3 星）：mkstruct 幂等。左到右把两层存在量词展开，
   xsimpl 合并两段后条件魔法杖；右到左就是 mkstruct_erase。 *)

Lemma mkstruct_idempotent : forall F,
  mkstruct (mkstruct F) = mkstruct F.
Proof using.
  intros. apply fun_ext_1. intros Q. applys himpl_antisym.
  { unfold mkstruct. xpull. intros Q1 Q2. xsimpl. }
  { applys mkstruct_erase. }
Qed.
```

---

## 102.4 主归纳：wpgen_sound_induct

现在所有零件都已就绪。主定理对任意上下文和项陈述：

```coq
(* ---------- 102.4 对项作结构归纳的主可靠性定理 ---------- *)

Lemma wpgen_sound_induct : forall E t,
  formula_sound (isubst E t) (wpgen E t).
```

证明先 `gen E`，把上下文广义化，再对 `t` 作结构归纳。这样每个归纳假设都对任意 `E` 成立，let 和函数分支才能换成扩展后的上下文。每个分支开头统一执行 `simpl; applys mkstruct_sound`，去掉生成器最外层的结构包装，随后处理各语法构造：

| 分支 | 使用的可靠性引理 | 额外工作 |
|---|---|---|
| 值 | `wpgen_val_sound` | 无 |
| 变量 | `wpgen_val_sound` 或 `wpgen_fail_sound` | 讨论 `lookup x E` |
| 普通函数 | `wpgen_fun_sound` | 用 `isubst_rem` 对齐参数替换 |
| 递归函数 | `wpgen_fix_sound` | 用 `isubst_rem_2` 对齐两次替换 |
| 应用 | `wpgen_app_sound` | 无 |
| 序列 | `wpgen_seq_sound` | 使用两个归纳假设 |
| let | `wpgen_let_sound` | 用 `isubst_rem` 对齐扩展上下文 |
| 条件 | `wpgen_if_sound` | 使用两个分支的归纳假设 |

完整证明如下。函数、let 中的 `rewrite <- isubst_rem` 看似改变了项的表示，实质上是在把“扩展上下文后做多重替换”转换成叶结点可靠性引理所要求的“先多重替换，再普通替换”。

```coq
Proof using.
  intros. gen E. induction t; intros; simpl; applys mkstruct_sound.
  { applys wpgen_val_sound. }
  { rename v into x. unfold wpgen_var. case_eq (lookup x E).
    { intros v EQ. applys wpgen_val_sound. }
    { intros N. applys wpgen_fail_sound. } }
  { applys wpgen_fun_sound.
    { intros vx. rewrite <- isubst_rem. applys IHt. } }
  { introv IH. applys wpgen_fix_sound IH.
    { intros vf vx. rewrite <- isubst_rem_2. applys IHt. } }
  { applys wpgen_app_sound. }
  { applys wpgen_seq_sound. { applys IHt1. } { applys IHt2. } }
  { rename v into x. applys wpgen_let_sound.
    { applys IHt1. }
    { intros v. rewrite <- isubst_rem. applys IHt2. } }
  { applys wpgen_if_sound. { applys IHt2. } { applys IHt3. } }
Qed.
```

至此，可靠性不再依赖于对 x-tactics 的信任，而是由对项的归纳、各 `wp` 规则以及替换等式共同保证。

---

## 102.5 闭项可靠性与 xwp 的理论基础

### 102.5.1 空上下文化简主定理

对闭项把 `E` 取为 `nil`。`wpgen_sound_induct nil t` 中的项为 `isubst nil t`，用 102.1 的 `isubst_nil` 化简后即得目标。

```coq
(* ---------- 102.5 闭项与函数调用的推论 ---------- *)

Lemma wpgen_sound : forall t Q,
  wpgen nil t Q ==> wp t Q.
Proof using.
  intros t Q. lets N: (wpgen_sound_induct nil t).
  rewrite isubst_nil in N. applys N.
Qed.
```

`triple_of_wpgen` 再向前一步：若当前堆谓词 `H` 蕴含生成公式，就能推出 Hoare 三元组。证明先由 `wp_equiv` 把三元组目标改为 `H ==> wp t Q`，再沿 `H ==> wpgen nil t Q ==> wp t Q` 传递。

```coq
Lemma triple_of_wpgen : forall t H Q,
  H ==> wpgen nil t Q ->
  triple t H Q.
Proof using.
  introv M. rewrite <- wp_equiv. xchange M. applys wpgen_sound.
Qed.
```

### 102.5.2 从普通函数调用进入 wpgen

`xwp` 面对的目标通常不是任意项，而是 `trm_app v1 v2`，其中 `v1 = val_fun x t1`。普通函数调用规则把验证调用归结为验证 `subst x v2 t1`。接下来：

1. 用 `isubst_rem` 和 `isubst_nil` 证明 `subst x v2 t1 = isubst ((x,v2)::nil) t1`；
2. 用 `wp_equiv` 把函数体三元组改成蕴含；
3. 用假设 `M2` 进入 `wpgen`；
4. 用主定理回到函数体的 `wp`。

这正是 `xwp` 展开函数体并产生公式目标的合法性证明。

```coq
(* xwp 的核心引理：函数调用规则把目标化为函数体的 triple，
   wp_equiv 与可靠性定理再把它化为生成公式的蕴含。 *)

Lemma triple_app_fun_from_wpgen : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv M1 M2. applys triple_app_fun M1.
  asserts_rewrite (subst x v2 t1 = isubst ((x,v2)::nil) t1).
  { rewrite isubst_rem. rewrite* isubst_nil. }
  rewrite <- wp_equiv. xchange M2. applys wpgen_sound_induct.
Qed.
```

递归函数调用完全类似，只是上下文依次绑定递归闭包 `(f,v1)` 与参数 `(x,v2)`，并使用 `triple_app_fix` 和 `isubst_rem_2`。

```coq
Lemma triple_app_fix_from_wpgen : forall v1 v2 f x t1 H Q,
  v1 = val_fix f x t1 ->
  H ==> wpgen ((f,v1)::(x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv M1 M2. applys triple_app_fix M1.
  asserts_rewrite (subst x v2 (subst f v1 t1)
                 = isubst ((f,v1)::(x,v2)::nil) t1).
  { rewrite isubst_rem_2. rewrite* isubst_nil. }
  rewrite <- wp_equiv. xchange M2. applys wpgen_sound_induct.
Qed.

End WPsound.
```

---

## 102.6 本章小结

本章完成了第 101 章生成器的可靠性闭环：

- `formula_sound` 把“公式蕴含语义最弱前条件”封装成适合归纳的谓词；
- 每种语法构造都有一条可靠性引理，序列和 let 通过 `wp_conseq` 把第二段证明嵌入后条件；
- `mkstruct_wp` 与 `mkstruct_sound` 说明结构包装不改变语义最弱前条件，并保持可靠性；
- 原书唯一练习 `mkstruct_idempotent` 已完整证明，核心是合并两层后条件魔法杖；
- `isubst_rem` 与 `isubst_rem_2` 连接延迟替换和普通替换，使 let、普通函数、递归函数的归纳分支能够闭合；
- 最终得到闭项定理 `wpgen_sound`、三元组推论 `triple_of_wpgen`，以及 `xwp` 所依赖的两个函数调用推论。

因此，使用 `wpgen` 和 x-tactics 完成的程序证明，最终都可以回到第 100 章定义的语义最弱前条件，再追溯到操作语义上的 Hoare 三元组。
