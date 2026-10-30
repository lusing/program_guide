# 106 · 非干扰与安全多执行：从两次执行到状态划分

对应示例：`../examples/106_noninterference.v`。

## 攻击者能看到什么，又不能看到什么

本章讨论**信息流安全**。把一个计算抽象成函数 `f pi si = (po, so)`：`pi`
是公开输入（public input），`si` 是秘密输入（secret input），`po` 是公开
输出，`so` 是秘密输出。攻击者知道程序本身，能选择或观察公开输入，也能观察
公开输出，但不能直接读取秘密输入和秘密输出。我们的目标不是让秘密完全不影响
计算，而是保证：**固定公开输入时，仅改变秘密输入，攻击者看到的公开输出不变**。
这个性质叫非干扰（noninterference）。

所以，公开输出依赖公开输入完全合法，秘密输出依赖秘密输入也合法；真正禁止的是
秘密信息经公开输出泄露。两次执行比较正好表达这个攻击者模型：两次执行使用同一个
`pi`，却分别使用 `si1`、`si2`，若它们的公开输出总相同，攻击者就无法仅凭公开
输出区分秘密。

一个看似合理的单执行条件是“公开输出不等于秘密输入”。它既会误拒安全程序，也会
误收不安全程序。例如公开输出恒为 `si+1` 明显泄露秘密，却永远不等于 `si`；而
公开输出恒为 `pi+1` 本来安全，却可能在某次执行中恰好等于 `si`。安全是比较所有
相关执行的全称性质，不是某一次执行里的一个算术不等式。本章先形式化这个反例，
再给出正确定义，最后把同样的思想推广到带公开/秘密标签的状态转换器。

示例只依赖 Rocq 标准库，并自带全映射定义，不需要导入原书 `SECF` 开发环境：

```coq
(* 106 非干扰与安全多执行：从两次执行到状态划分 *)
(* 取材 Software Foundations 卷七 Security Foundations 的 Noninterference 章。 *)

From Stdlib Require Import Arith.Arith.
From Stdlib Require Import Bool.Bool.
From Stdlib Require Import Lia.
From Stdlib Require Import Strings.String.
From Stdlib Require Import FunctionalExtensionality.

Open Scope string_scope.
```

`Arith` 和 `Lia` 用于自然数运算与反例证明，`String` 提供变量名和字符串布尔相等，
`FunctionalExtensionality` 用于证明两个逐点相同的全映射相等。打开 `string_scope`
后，`"X"`、`"Y"` 可直接作为状态中的变量名。

## 106.1 自包含的全映射与更新记号

状态是从变量名到值的全映射。与有限关联表不同，全映射对任意名字都有值，因此读取
不需要处理“未定义”。`t_empty v` 把所有名字映到 `v`；`t_update m x v` 只改变 `x`
处的值。两个记号分别便于书写常量映射和更新后的映射：

```coq
(* ---------- 106.1 自包含的全映射与更新记号 ---------- *)

Definition total_map (A : Type) : Type := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A)
                    (x : string) (v : A) : total_map A :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).
```

`t_update` 的参数顺序在记号和定义中看起来相反：定义先收映射 `m`，而表达式
`x !-> v ; m` 把新绑定写在前面。这是为了得到常见的“更新；旧状态”书写顺序。
接下来四条小引理是后续状态证明的全部基础。

```coq
Lemma t_apply_empty : forall (A : Type) (x : string) (v : A),
  (__ !-> v) x = v.
Proof. reflexivity. Qed.

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.
```

常量映射读取由定义直接成立。读取刚更新的同一个键时，展开定义后用
`String.eqb_refl` 把条件化简为真即可。不同键的情况需要把布尔比较反射成命题：
`String.eqb_spec` 的两个分支分别携带 `x1 = x2` 和 `x1 <> x2`；相等分支与前提
矛盾，不等分支则由定义化简。

```coq
Lemma t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Lemma t_update_same : forall (A : Type) (m : total_map A) x,
  (x !-> m x ; m) = m.
Proof.
  intros A m x. apply functional_extensionality. intro x'.
  unfold t_update. destruct (String.eqb_spec x x').
  - subst x'. reflexivity.
  - reflexivity.
Qed.
```

`t_update_same` 说“把 `x` 更新成它原有的值”不改变映射。两个映射是函数，所以先用
函数外延性把映射等式化成任意键 `x'` 上的值等式，再按 `x = x'` 与否分情况。最后
约定两个变量名和自然数状态：

```coq
Definition X : string := "X".
Definition Y : string := "Y".
Definition state := total_map nat.
```

## 106.2 为什么单执行定义失败

`secure_f` 的公开输出是 `pi+1`，与秘密输入无关；秘密输出则允许同时依赖两者。
`broken_sec_def` 是开头提到的单执行候选定义：它只要求每次公开输出都不等于当次
秘密输入。

```coq
(* ---------- 106.2 为什么单执行定义失败 ---------- *)

Definition secure_f (pi si : nat) : nat * nat :=
  (pi + 1, pi + si * 2).

Definition broken_sec_def (f : nat -> nat -> nat * nat) :=
  forall pi si, fst (f pi si) <> si.

Example example_secure_f : secure_f 7 8 = (8, 23).
Proof. reflexivity. Qed.
```

代入 `pi=7`、`si=8` 得公开输出 `8` 和秘密输出 `23`，计算由 `reflexivity` 完成。
这组输入恰好让公开输出等于秘密输入，所以错误定义会拒绝安全函数：假设它满足
`broken_sec_def`，把假设实例化到 `(7,8)`，就得到 `8 <> 8`，再由自反等式推出矛盾。

```coq
Lemma broken_sec_def_rejects_secure_f : ~ broken_sec_def secure_f.
Proof. intros Hc. apply (Hc 7 8). reflexivity. Qed.

Definition insecure_f (pi si : nat) : nat * nat :=
  (si + 1, pi + si * 2).

Lemma broken_sec_def_accepts_insecure_f : broken_sec_def insecure_f.
Proof.
  unfold broken_sec_def, insecure_f. intros pi si. simpl. lia.
Qed.
```

相反，`insecure_f` 把公开输出设为 `si+1`，每一位秘密都直接影响公开结果，却满足
“输出不等于输入”。展开定义后目标是 `si+1 <> si`，`lia` 证明自然数不可能等于
自己的后继加一。两个方向合起来说明：单执行的数值巧合既不能保证安全，也不是安全
的必要条件；必须比较不同秘密输入下的执行。

## 106.3 纯函数的非干扰

### 正确定义与三个例子

下面给出本章的核心定义。注意量词结构：公开输入 `pi` 在两次执行中共享，秘密输入
`si1`、`si2` 独立变化，只比较 `fst`，不限制秘密输出。

```coq
(* ---------- 106.3 纯函数的非干扰 ---------- *)

Definition noninterferent {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  forall (pi : PI) (si1 si2 : SI),
    fst (f pi si1) = fst (f pi si2).
```

`secure_f` 的两次公开输出都化简成 `pi+1`，所以直接自反。要否定 `insecure_f` 的
非干扰性，只需选择一个公开输入和两个秘密输入：`si=3` 时公开输出为 `4`，`si=7`
时为 `8`。假设非干扰会把 `4=8` 交给 `discriminate`，从而构造矛盾。

```coq
Lemma noninterferent_secure_f : noninterferent secure_f.
Proof. unfold noninterferent, secure_f. simpl. reflexivity. Qed.

Lemma interferent_insecure_f : ~ noninterferent insecure_f.
Proof.
  unfold noninterferent. intros contra.
  specialize (contra 42 3 7). simpl in contra. discriminate contra.
Qed.
```

以下三个函数说明不能只看表达式中是否出现 `si`，而要看它是否真的影响公开输出。
`less_obvious_f1` 的公开输出虽写为 `si*0`，乘零后恒为 `0`，因此安全。

```coq
Definition less_obvious_f1 (pi si : nat) : nat * nat :=
  (si * 0, pi + si).

Lemma noninterferent_less_obvious_f1 : noninterferent less_obvious_f1.
Proof.
  unfold noninterferent, less_obvious_f1. intros pi si1 si2. simpl.
  rewrite Nat.mul_0_r. rewrite Nat.mul_0_r. reflexivity.
Qed.
```

`less_obvious_f2` 在 `si=1` 时返回 `si*pi`，否则返回 `pi`。表面上公开输出依赖
`si`，但真分支中 `1*pi=pi`，两个分支结果相同。辅助引理先按 `Nat.eqb si 1`
分支，并用 `Nat.eqb_eq` 把真分支的布尔等式转为 `si=1`；主证明随后对两次执行都
重写这个辅助等式。

```coq
Definition less_obvious_f2 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 1 then si * pi else pi, pi + si).

Lemma po_equal_pi_f2 : forall si pi,
  (if Nat.eqb si 1 then si * pi else pi) = pi.
Proof.
  intros si pi. destruct (Nat.eqb si 1) eqn:Eq.
  - apply Nat.eqb_eq in Eq. subst si. rewrite Nat.mul_1_l. reflexivity.
  - reflexivity.
Qed.

Lemma noninterferent_less_obvious_f2 : noninterferent less_obvious_f2.
Proof.
  unfold noninterferent, less_obvious_f2. intros pi si1 si2.
  rewrite po_equal_pi_f2. rewrite po_equal_pi_f2. reflexivity.
Qed.
```

`less_obvious_f3` 则确实泄露秘密的一位信息：公开输出揭示 `si` 是否为零。取
`si1=0`、`si2=10`，公开输出分别为 `1`、`0`，直接反驳非干扰。

```coq
Definition less_obvious_f3 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then 1 else 0, pi + si).

Lemma interferent_less_obvious_f3 : ~ noninterferent less_obvious_f3.
Proof.
  unfold noninterferent, less_obvious_f3. intros contra.
  specialize (contra 42 0 10). simpl in contra. discriminate contra.
Qed.
```

### 六个“证明或反驳”练习的完整答案

六个练习都写成析取 `noninterferent f \/ ~ noninterferent f`。选择 `left` 必须给出
对所有输入的安全证明；选择 `right` 则给出一组具体反例。这样既练习识别信息流，
也练习区分全称证明与存在反例。

```coq
(* 标准练习：六个函数分别给出构造性证明或具体反例。 *)

Definition obvious_f1 (pi si : nat) : nat * nat := (0, 0).

Lemma prove_or_disprove_obvious_f1 :
  noninterferent obvious_f1 \/ ~ noninterferent obvious_f1.
Proof.
  left. unfold noninterferent, obvious_f1. reflexivity.
Qed.
```

**答案 1：安全。** 公开输出永远是 `0`，与两个输入都无关。

```coq
Definition obvious_f2 (pi si : nat) : nat * nat :=
  (pi + 2 * si, 2 * pi + si).

Lemma prove_or_disprove_obvious_f2 :
  noninterferent obvious_f2 \/ ~ noninterferent obvious_f2.
Proof.
  right. unfold noninterferent, obvious_f2. intros contra.
  specialize (contra 0 0 1). simpl in contra. discriminate contra.
Qed.
```

**答案 2：不安全。** 固定 `pi=0`，秘密从 `0` 改为 `1` 时，公开输出从 `0`
变为 `2`，因此攻击者能观察到秘密变化。

```coq
Definition less_obvious_f4 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then si * pi else pi, pi + si).

Lemma prove_or_disprove_less_obvious_f4 :
  noninterferent less_obvious_f4 \/ ~ noninterferent less_obvious_f4.
Proof.
  right. unfold noninterferent, less_obvious_f4. intros contra.
  specialize (contra 2 0 1). simpl in contra. discriminate contra.
Qed.
```

**答案 4：不安全。** 真分支的乘积 `si*pi` 在 `si=0` 时必为 `0`，假分支则为
`pi`。若 `pi=0` 两边恰好相同，但这不代表安全；取 `pi=2`，`si=0`、`1`，公开
输出分别为 `0`、`2`。反例必须让公开输入避开使两个分支巧合相等的值。

```coq
Definition less_obvious_f5 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then si + pi else pi, pi + si).

Lemma prove_or_disprove_less_obvious_f5 :
  noninterferent less_obvious_f5 \/ ~ noninterferent less_obvious_f5.
Proof.
  left. unfold noninterferent, less_obvious_f5.
  intros pi [| si1] [| si2]; reflexivity.
Qed.
```

**答案 5：安全。** `si=0` 时真分支为 `0+pi`，化简后也是 `pi`，其余情况本来
就是 `pi`。证明对两个秘密输入分别作 `0`/后继析构，四种组合都由计算自反完成。
这里也解释了为何不需要额外的 `Nat.eqb` 反射：自然数析构已直接决定条件结果。

```coq
Definition less_obvious_f6 (pi si : nat) : nat * nat :=
  (if Nat.ltb si pi then 0 else pi, pi + si).

Lemma prove_or_disprove_less_obvious_f6 :
  noninterferent less_obvious_f6 \/ ~ noninterferent less_obvious_f6.
Proof.
  right. unfold noninterferent, less_obvious_f6. intros contra.
  specialize (contra 1 0 1). simpl in contra. discriminate contra.
Qed.
```

**答案 6：不安全。** 条件 `si<pi` 本身由秘密决定，并让公开输出在 `0` 与 `pi`
之间切换。取 `pi=1`，`si=0` 时输出 `0`，`si=1` 时输出 `1`。六个答案依次是：
`f1` 安全、`f2` 不安全、`f4` 不安全、`f5` 安全、`f6` 不安全，加上前面的
`f3` 不安全；关键始终是公开输出的函数依赖，而不是秘密变量有没有在语法上出现。

### 只在秘密不同时作要求是否更弱

`noninterferent_diff_si` 多了前提 `si1<>si2`，看似比原定义弱。其实原定义在
`si1=si2` 时要求的是自反等式，自动成立，所以两种定义等价。

```coq
Definition noninterferent_diff_si {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  forall (pi : PI) (si1 si2 : SI),
    si1 <> si2 -> fst (f pi si1) = fst (f pi si2).

Lemma noninterferent_diff_si_same : forall (f : nat -> nat -> nat * nat),
  noninterferent_diff_si f <-> noninterferent f.
Proof.
  intros f. split.
  - intros H pi si1 si2. destruct (Nat.eq_dec si1 si2) as [Heq | Hneq].
    + subst si2. reflexivity.
    + apply H. exact Hneq.
  - intros H pi si1 si2 _. apply H.
Qed.
```

正向用自然数可判定相等 `Nat.eq_dec` 分情况：相等时代入后自反，不等时应用 `H`。
反向则忽略新增的不等前提，直接使用原非干扰假设。这个等价说明“两次执行”自然
包括相同秘密的退化情形，但不会增加实质约束。

## 106.4 过强定义与可划分性

修正单执行定义时也不能走到另一个极端：若要求任意公开输入、任意秘密输入的公开
输出都相同，就连“公开输出正常依赖公开输入”也不允许了。

```coq
(* ---------- 106.4 过强定义与可划分性 ---------- *)

Definition too_strong_sec_def {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  forall (pi1 pi2 : PI) (si1 si2 : SI),
    fst (f pi1 si1) = fst (f pi2 si2).

Lemma secure_f_rejected_again : ~ too_strong_sec_def secure_f.
Proof.
  unfold too_strong_sec_def, secure_f. intros contra.
  specialize (contra 0 1 0 0). discriminate contra.
Qed.
```

反例取 `pi1=0`、`pi2=1`，于是安全函数 `secure_f` 的公开输出分别为 `1`、`2`。
正确非干扰必须固定 `pi`，既不能逐次孤立检查，也不能把所有输入混成一个全称等式。

非干扰还有一个结构性刻画：函数可划分为公开部分 `pf : PI -> PO` 与秘密部分
`sf : PI -> SI -> SO`。秘密输入只允许进入第二分量。

```coq
Definition splittable {PI SI PO SO : Type}
    (f : PI -> SI -> PO * SO) :=
  exists (pf : PI -> PO) (sf : PI -> SI -> SO),
    forall pi si, f pi si = (pf pi, sf pi si).

Theorem splittable_noninterferent : forall (PI SI PO SO : Type)
    (f : PI -> SI -> PO * SO),
  splittable f -> noninterferent f.
Proof.
  unfold splittable, noninterferent.
  intros PI SI PO SO f [pf [sf H]] pi si1 si2.
  rewrite H. rewrite H. simpl. reflexivity.
Qed.
```

从可划分到非干扰很直接：两次执行都按见证 `pf`、`sf` 重写，取第一分量后都是
`pf pi`。反方向需要一个默认秘密 `some_si` 来构造公开部分。这个要求并非技术累赘：
若 `SI` 是空类型，就不存在可供选择的秘密值，而当前定义又要对任意类型给出实际
函数 `pf`。

```coq
Theorem noninterferent_splittable : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO),
  noninterferent f -> splittable f.
Proof.
  unfold splittable, noninterferent.
  intros PI SI PO SO some_si f NI.
  exists (fun pi => fst (f pi some_si)).
  exists (fun pi si => snd (f pi si)).
  intros pi si. rewrite (NI _ _ si).
  destruct (f pi si) as [po so]. reflexivity.
Qed.
```

构造取 `pf pi := fst (f pi some_si)`，`sf pi si := snd (f pi si)`。非干扰保证任意
`si` 的公开输出都等于默认秘密下的公开输出，所以原函数确实等于这两个部分的配对。
最后 `destruct` 配对，让第一分量等式与第二分量自反等式同时显现。两条定理合起来
说明：非干扰不是额外的实现技巧，而正是“公开结果可从公开输入单独计算”。

## 106.5 安全多执行：安全性与透明性

### 构造、两条保证及练习答案

**安全多执行**（secure multi-execution，SME）的思路是：公开输出用一次固定的默认
秘密运行来计算，秘密输出仍用调用者提供的真实秘密运行来计算。即使原函数泄露秘密，
改造后的公开分量也只知道 `some_si`。

```coq
(* ---------- 106.5 安全多执行：安全性与透明性 ---------- *)

Definition sme {PI SI PO SO : Type} (some_si : SI)
    (f : PI -> SI -> PO * SO) : PI -> SI -> PO * SO :=
  fun pi si => (fst (f pi some_si), snd (f pi si)).

Theorem noninterferent_sme : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO),
  noninterferent (sme some_si f).
Proof. intros PI SI PO SO some_si f pi si1 si2. reflexivity. Qed.
```

安全性是无条件的：无论 `f` 是否安全，`sme some_si f` 的公开输出都与参数 `si`
无关，展开后自反即证。透明性则说，如果原函数本来就非干扰，SME 不改变任何结果。
证明与 `noninterferent_splittable` 相同：用非干扰把默认秘密的公开输出换成真实秘密
下的公开输出，秘密输出保持不动。

```coq
Theorem transparent_sme : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO),
  noninterferent f -> forall pi si, f pi si = sme some_si f pi si.
Proof.
  unfold noninterferent, sme. intros PI SI PO SO some_si f NI.
  intros pi si. rewrite (NI _ _ si).
  destruct (f pi si) as [po so]. reflexivity.
Qed.
```

对不安全的 `insecure_f`，取默认秘密 `0` 后公开输出恒为 `1`。示例中真实秘密为
`7`，秘密输出仍是 `1+7*2=15`，所以最终得到 `(1,15)`。这也说明 SME 是强制安全
改造，而不是保持所有程序行为的优化：不安全程序的公开结果会被改变。

```coq
Example example_sme_insecure_f : sme 0 insecure_f 1 7 = (1, 15).
Proof. reflexivity. Qed.

Lemma constant_sme_insecure_f : forall pi si,
  fst (sme 0 insecure_f pi si) = 1.
Proof. unfold sme, insecure_f. reflexivity. Qed.
```

下一组是 SME 练习的完整答案。`another_insecure_f2` 在秘密为零时输出 `2*pi`，
否则输出 `pi`。SME 固定用 `si=0` 计算公开部分，所以总是选择真分支。

```coq
Definition another_insecure_f2 (pi si : nat) : nat * nat :=
  (if Nat.eqb si 0 then 2 * pi else pi, pi + si).

Lemma sme_another_insecure_f2 : forall pi si,
  sme 0 another_insecure_f2 pi si = (2 * pi, pi + si).
Proof. intros pi si. reflexivity. Qed.
```

**练习答案：** `sme 0 another_insecure_f2` 的公开输出为 `2*pi`，秘密输出仍为
`pi+si`，整条等式由计算成立。原函数在 `si<>0` 时的公开输出从 `pi` 被改为
`2*pi`，这正是对原有泄露的修复。

`another_insecure_f3` 的条件是 `si=pi`。默认秘密固定为 `0`，因此默认公开运行只在
`pi=0` 时进入真分支；该分支输出 `0*0=0`，假分支则输出 `pi`。证明把 `pi` 析构
为零和后继，两个分支都能直接计算。

```coq
Definition another_insecure_f3 (pi si : nat) : nat * nat :=
  (if Nat.eqb si pi then si * pi else pi, pi + si).

Lemma sme_another_insecure_f3 : forall pi si,
  sme 0 another_insecure_f3 pi si = (pi, pi + si).
Proof. intros [| pi] si; reflexivity. Qed.
```

**练习答案：** 默认运行使公开输出恰好回到 `pi`，但真实秘密输出仍是 `pi+si`。
最后一个练习检查 SME 是否正确处理秘密输出。答案是肯定的：第二分量逐字保留原函数
在真实 `si` 下的结果。

```coq
Lemma sme_correct_so : forall (PI SI PO SO : Type)
    (some_si : SI) (f : PI -> SI -> PO * SO) (pi : PI) (si : SI),
  snd (f pi si) = snd (sme some_si f pi si).
Proof. reflexivity. Qed.
```

因此 SME 的两面必须同时记住：`noninterferent_sme` 保证任何函数都被改造安全，
`transparent_sme` 只对原本安全的函数保证行为不变，`sme_correct_so` 则始终保证
秘密输出不变。

## 106.6 标签、公开等价与状态转换器

### 标签、标签相等与公开等价

纯函数模型现在推广为 `state -> state`。每个变量由标签映射标为 `public` 或
`secret`。攻击者能观察所有公开变量的最终值，秘密变量的值则不可见。

```coq
(* ---------- 106.6 标签、公开等价与状态转换器 ---------- *)

Inductive label : Type :=
  | public
  | secret.

Definition label_map := total_map label.

Definition label_eqb (l1 l2 : label) : bool :=
  match l1, l2 with
  | public, public | secret, secret => true
  | _, _ => false
  end.

Declare Scope label_scope.
Infix "=?" := label_eqb : label_scope.
Delimit Scope label_scope with label.
Open Scope label_scope.
```

这里特意定义标签自己的 `=?` 并放入 `label_scope`，避免与自然数或字符串的布尔
相等混淆。`label_eqb_spec` 把计算结果与命题相等连接起来，四种标签组合分别通过
自反或构造子不等完成。

```coq
Lemma label_eqb_spec : forall l1 l2 : label,
  reflect (l1 = l2) (l1 =? l2).
Proof.
  intros [|] [|]; constructor; (reflexivity || discriminate).
Qed.

Definition pub_equiv (L : label_map) (s1 s2 : state) :=
  forall x : string, L x = public -> s1 x = s2 x.
```

`pub_equiv L s1 s2` 表示两个状态在攻击者看来不可区分：它们在所有公开变量上相等，
秘密变量可任意不同。它就是状态版的“两次执行具有相同公开输入”。公开等价显然是
自反、对称、传递的；证明逐点使用普通等式对应性质即可。

```coq
Lemma pub_equiv_refl : forall (L : label_map) (s : state),
  pub_equiv L s s.
Proof. intros L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall (L : label_map) (s1 s2 : state),
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros L s1 s2 H x Px. symmetry. apply H. exact Px.
Qed.

Lemma pub_equiv_trans : forall (L : label_map) (s1 s2 s3 : state),
  pub_equiv L s1 s2 -> pub_equiv L s2 s3 -> pub_equiv L s1 s3.
Proof.
  unfold pub_equiv. intros L s1 s2 s3 H12 H23 x Px.
  rewrite H12 by exact Px. apply H23. exact Px.
Qed.
```

### 状态非干扰与安全、危险转换

状态转换器非干扰要求：若输入状态公开等价，输出状态也必须公开等价。秘密输入可以
影响秘密输出，但不能使任何公开变量在两次执行中产生差异。

```coq
Definition noninterferent_state (L : label_map) (f : state -> state) :=
  forall s1 s2,
    pub_equiv L s1 s2 -> pub_equiv L (f s1) (f s2).

Definition tid (s : state) : state := s.

Lemma noninterferent_tid : forall L : label_map,
  noninterferent_state L tid.
Proof.
  unfold noninterferent_state, tid. intros L s1 s2 PEq. exact PEq.
Qed.
```

恒等转换原样保留公开等价，证明就是返回前提。下面令 `LXP` 中只有 `X` 公开，其余
变量默认秘密。辅助引理 `LXP_public` 把“某变量公开”收紧为“该变量就是 `X`”：
若字符串相等则结束，否则更新规则说明读取的是默认标签 `secret`，与 `public`
矛盾。

```coq
Definition tconstX (c : nat) (s : state) : state := (X !-> c ; s).

Definition LXP : label_map := (X !-> public ; __ !-> secret).

Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  unfold LXP. intros x Hx.
  destruct (String.eqb_spec x X).
  - subst x. reflexivity.
  - rewrite t_update_neq in Hx.
    + rewrite t_apply_empty in Hx. discriminate Hx.
    + intro contra. subst x. contradiction.
Qed.
```

给公开的 `X` 赋常量安全，因为两个执行写入相同的 `c`。证明利用 `LXP_public`
把待检查的任意公开变量化成 `X`，再两次使用更新同键引理。

```coq
Lemma noninterferent_tconstX : forall c,
  noninterferent_state LXP (tconstX c).
Proof.
  unfold noninterferent_state, tconstX. intros c s1 s2 PEq x Px.
  apply LXP_public in Px. subst x.
  repeat rewrite t_update_eq. reflexivity.
Qed.
```

`X := X+1` 也安全：两个输入状态公开等价，所以原 `X` 相同，加一并写回后仍相同。
`f_equal` 把自然数加一的等式化为加数的等式。

```coq
Definition tincX (s : state) : state := (X !-> s X + 1 ; s).

Lemma noninterferent_tincX : noninterferent_state LXP tincX.
Proof.
  unfold noninterferent_state, tincX. intros s1 s2 PEq x Px.
  apply LXP_public in Px. subst x. repeat rewrite t_update_eq.
  f_equal. apply PEq. reflexivity.
Qed.
```

`Y := Y+1` 修改秘密变量，同样安全。公开输出只检查 `X`，而更新 `Y` 不会改变
`X`；两次用 `t_update_neq` 消去更新，最后应用原状态的公开等价。

```coq
Definition tincY (s : state) : state := (Y !-> s Y + 1 ; s).

Lemma noninterferent_tincY : noninterferent_state LXP tincY.
Proof.
  unfold noninterferent_state, tincY. intros s1 s2 PEq x Px.
  apply LXP_public in Px. subst x.
  rewrite t_update_neq by discriminate.
  rewrite t_update_neq by discriminate.
  apply PEq. reflexivity.
Qed.
```

真正危险的是从秘密到公开的显式流 `X := Y`。构造两个状态，它们的 `Y` 分别为
`0`、`1`，其他值均为零；因唯一公开变量 `X` 在两个状态中相同，输入公开等价。
执行后 `X` 分别变成 `0`、`1`，否定输出公开等价。

```coq
Definition tYtoX (s : state) : state := (X !-> s Y ; s).

Lemma LXPX : LXP X = public.
Proof. reflexivity. Qed.

Lemma interferent_YtoX : ~ noninterferent_state LXP tYtoX.
Proof.
  unfold noninterferent_state, tYtoX. intros Hc.
  set (s1 := Y !-> 0 ; __ !-> 0).
  set (s2 := Y !-> 1 ; __ !-> 0).
  assert (Peq : pub_equiv LXP s1 s2).
  { clear Hc. intros x H. apply LXP_public in H. subst x. reflexivity. }
  specialize (Hc s1 s2 Peq X LXPX). vm_compute in Hc. discriminate Hc.
Qed.
```

这里 `set` 固定反例状态，`Peq` 证明攻击者事前无法区分它们，`vm_compute` 则把
更新、字符串比较和状态读取全部算出，留下 `0=1` 的矛盾。隐式流也一样：即使公开
输出还依赖原公开 `X`，只要秘密 `Y` 能改变结果，就不安全。乘法示例取两个状态的
`X` 都为 `1`、`Y` 分别为 `0`、`1`，执行后公开 `X` 分别为 `0`、`1`。

```coq
Definition tXtimesYtoX (s : state) : state := (X !-> s X * s Y ; s).

Lemma interferent_tXtimesYtoX : ~ noninterferent_state LXP tXtimesYtoX.
Proof.
  unfold noninterferent_state, tXtimesYtoX. intros Hc.
  set (s1 := X !-> 1 ; Y !-> 0 ; __ !-> 0).
  set (s2 := X !-> 1 ; Y !-> 1 ; __ !-> 0).
  assert (Peq : pub_equiv LXP s1 s2).
  { clear Hc. intros x H. apply LXP_public in H. subst x. reflexivity. }
  specialize (Hc s1 s2 Peq X LXPX). vm_compute in Hc. discriminate Hc.
Qed.
```

这组例子给出状态信息流的判别法：公开到公开、秘密到秘密、公开到秘密都可以；
秘密到公开则必须证明秘密影响被消去，否则可用两个仅秘密不同的状态构造反例。

## 106.7 状态划分、合并与两种非干扰的等价

### 划分、合并及公开等价的另一表示

`split_state s L l` 只保留标签为 `l` 的变量，其他位置填零；`merge_states ps ss L`
则从 `ps` 取公开变量、从 `ss` 取秘密变量。这样，一个状态可拆成公开状态和秘密
状态，也可把两部分重新合并。

```coq
(* ---------- 106.7 状态划分、合并与两种非干扰的等价 ---------- *)

Definition split_state (s : state) (L : label_map) (l : label) : state :=
  fun x : string => if L x =? l then s x else 0.

Definition merge_states (ps ss : state) (L : label_map) : state :=
  fun x : string => if L x =? public then ps x else ss x.
```

对任意状态转换器 `mf`，`split_state_fun` 构造一个纯函数版本：公开状态 `ps` 是
公开输入，秘密状态 `ss` 是秘密输入；先合并并运行 `mf`，再把输出拆成公开、秘密
两个状态。这正好匹配 106.3 的 `PI -> SI -> PO * SO`。

```coq
Definition split_state_fun (L : label_map) (mf : state -> state) :=
  fun ps ss : state =>
    let ms := mf (merge_states ps ss L) in
    (split_state ms L public, split_state ms L secret).
```

公开等价也可直接表述为两个状态的公开划分相同。`pub_equiv_split` 逐点比较
`split_state ... public`；下面的等价定理证明它与 `pub_equiv` 完全等价。

```coq
Definition pub_equiv_split (L : label_map) (s1 s2 : state) :=
  forall x : string,
    split_state s1 L public x = split_state s2 L public x.

Theorem pub_equiv_split_iff : forall L s1 s2,
  pub_equiv L s1 s2 <-> pub_equiv_split L s1 s2.
Proof.
  unfold pub_equiv, pub_equiv_split, split_state. intros L s1 s2. split.
  - intros H x. destruct (label_eqb_spec (L x) public).
    + apply H. exact e.
    + reflexivity.
  - intros H x Hx. specialize (H x).
    destruct (label_eqb_spec (L x) public).
    + exact H.
    + contradiction.
Qed.
```

正向在公开位置使用原公开等价，在非公开位置两边都为零。反向已知变量公开，所以
标签相等分支中的划分值就是原状态值；另一分支与前提 `L x=public` 矛盾。这个
等价是后续证明中在“逐公开变量推理”和“整份公开状态推理”之间切换的桥梁。

固定公开部分 `ps` 而改变秘密部分时，两个合并状态天然公开等价，因为公开位置都只
读取 `ps`。证明在公开标签处重写 `Hx`，把条件化为真。

```coq
Theorem pub_equiv_merge_states : forall L ps ss1 ss2,
  pub_equiv L (merge_states ps ss1 L) (merge_states ps ss2 L).
Proof.
  unfold pub_equiv, merge_states. intros L ps ss1 ss2 x Hx.
  rewrite Hx. reflexivity.
Qed.
```

反之，把同一状态的公开划分与秘密划分合起来，会恢复原状态。函数外延性把目标化为
逐变量等式，再按 `L x` 是公开还是秘密计算两侧即可。

```coq
Theorem merge_states_split_state : forall s L,
  merge_states (split_state s L public) (split_state s L secret) L = s.
Proof.
  unfold merge_states, split_state. intros s L.
  apply functional_extensionality. intro x.
  destruct (L x); reflexivity.
Qed.
```

### 核心等价：状态非干扰就是划分后的纯函数非干扰

这是本章连接两种模型的主定理。左侧说相同公开输入状态经 `f` 后仍公开等价；右侧
说 `split_state_fun L f` 的公开输出状态不依赖秘密输入状态。二者其实完全相同。

```coq
Theorem noninterferent_state_ni : forall L f,
  noninterferent_state L f <-> noninterferent (split_state_fun L f).
Proof.
  unfold noninterferent_state, noninterferent, split_state_fun.
  intros L f. split.
  - intros H ps ss1 ss2. simpl.
    assert (H' : pub_equiv L (merge_states ps ss1 L)
                             (merge_states ps ss2 L)).
    { apply pub_equiv_merge_states. }
    apply H in H'. rewrite pub_equiv_split_iff in H'.
    unfold pub_equiv_split in H'.
    apply functional_extensionality. apply H'.
  - intros H s1 s2 Hequiv. simpl in H.
    rewrite pub_equiv_split_iff in *. unfold pub_equiv_split in *.
    intro x.
    specialize (H (split_state s1 L public)
                  (split_state s1 L secret)
                  (split_state s2 L secret)).
    rewrite merge_states_split_state in H.
    apply functional_extensionality in Hequiv. rewrite Hequiv in H.
    rewrite merge_states_split_state in H.
    rewrite H. reflexivity.
Qed.
```

**正向。** 固定 `ps`，任取 `ss1`、`ss2`。`pub_equiv_merge_states` 给出两个输入
状态的公开等价，状态非干扰假设 `H` 把它传到输出。再用 `pub_equiv_split_iff` 把
输出公开等价改写成公开划分逐点相等，最后以函数外延性得到两个公开输出状态相等。

**反向。** 给定 `s1`、`s2` 公开等价，取共同公开输入 `split_state s1 L public`，
秘密输入分别取两个状态的秘密划分。合并后最初分别还原为 `s1`、`s2`。纯函数非干扰
假设 `H` 因而给出两次运行后的公开划分相等。公开等价 `Hequiv` 经函数外延性变成
函数等式，用来把第一个输入的公开划分换成第二个，保证第二次合并也能用
`merge_states_split_state` 还原。最终把 `H` 的等式重写进目标，得到输出的公开
划分逐点相等。证明中的 `rewrite ... in *` 同时转换假设与目标，避免只改一边。

## 106.8 状态转换器的安全多执行

### 状态 SME 的安全性与透明性

纯函数 SME 用默认秘密运行产生公开输出。状态版没有默认秘密状态，而是从真实状态
`s` 提取公开划分，并把秘密位置清零，得到 `split_state s L public`。第一次运行
`f` 只拿这份公开状态，负责提供公开输出；第二次运行 `f s` 拿完整真实状态，负责
提供秘密输出；最后按标签合并。

```coq
(* ---------- 106.8 状态转换器的安全多执行 ---------- *)

Definition sme_state (f : state -> state) (L : label_map) : state -> state :=
  fun s => merge_states (f (split_state s L public)) (f s) L.

Theorem noninterferent_sme_state : forall L f,
  noninterferent_state L (sme_state f L).
Proof.
  unfold noninterferent_state, sme_state. intros L f s1 s2 Hequiv.
  rewrite pub_equiv_split_iff in Hequiv. unfold pub_equiv_split in Hequiv.
  apply functional_extensionality in Hequiv. rewrite Hequiv.
  apply pub_equiv_merge_states.
Qed.
```

安全性证明不假设 `f` 安全。两个输入公开等价，意味着它们的公开划分完全相同；因此
负责公开输出的第一次运行在两边完全相同。将公开划分等式转为函数等式并重写后，
两个 SME 结果具有同一个公开源状态，只是秘密源状态可能不同，
`pub_equiv_merge_states` 立即给出输出公开等价。

透明性需要两个小引理。第一，公开划分与原状态公开等价：公开位置划分保留原值，
秘密位置不受 `pub_equiv` 约束。第二，如果 `ps`、`ss` 已公开等价，那么合并时公开
位置选 `ps` 或 `ss` 都一样，秘密位置又总选 `ss`，所以合并结果就是 `ss`。

```coq
Lemma pub_equiv_split_state : forall (L : label_map) s,
  pub_equiv L (split_state s L public) s.
Proof.
  unfold pub_equiv, split_state. intros L s x Hx.
  destruct (label_eqb_spec (L x) public).
  - reflexivity.
  - contradiction.
Qed.

Lemma merge_state_pub_equiv : forall L ss ps,
  pub_equiv L ps ss -> merge_states ps ss L = ss.
Proof.
  unfold pub_equiv, merge_states. intros L ss ps H.
  apply functional_extensionality. intros x. destruct (L x) eqn:Heq.
  - rewrite H by exact Heq. reflexivity.
  - reflexivity.
Qed.
```

若 `f` 本来非干扰，公开划分与真实状态公开等价会推出两次 `f` 运行公开等价。
于是合并公开运行与真实运行的结果就等于真实运行 `f s`，即 SME 不改变安全程序。

```coq
Theorem transparent_sme_state : forall f L,
  noninterferent_state L f -> forall s, f s = sme_state f L s.
Proof.
  intros f L Hni s. unfold sme_state. symmetry.
  apply merge_state_pub_equiv. apply Hni. apply pub_equiv_split_state.
Qed.
```

这里的证明链值得单独记忆：`pub_equiv_split_state` 提供输入公开等价，`Hni`
把它变为输出公开等价，`merge_state_pub_equiv` 再把输出公开等价比作合并等式。
它与纯函数 `transparent_sme` 完全同构。

### 公开更新如何穿过 SME

后面的具体例子需要两条计算事实：公开位置上，公开划分保留原值；秘密位置上，公开
划分为零。

```coq
Lemma split_state_public_id : forall s L x,
  L x = public -> split_state s L public x = s x.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.

Lemma split_state_secret_zero : forall s L x,
  L x = secret -> split_state s L public x = 0.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.
```

若更新的是公开变量 `x`，那么它同时发生在 SME 的两次运行里。第一条合并引理说明，
公开源状态上的更新会留在合并结果中；第二条说明，秘密源状态上对公开变量的更新会
被合并操作丢弃，因为公开位置始终取第一参数。两条证明都先函数外延性，再按查询键
是否等于 `x` 使用更新引理。

```coq
Lemma merge_states_update_pub_fst : forall (L : label_map) x v s1 s2,
  L x = public ->
  merge_states (x !-> v ; s1) s2 L = (x !-> v ; merge_states s1 s2 L).
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. repeat rewrite t_update_eq. reflexivity.
  - repeat rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_pub_snd : forall (L : label_map) x v s1 s2,
  L x = public ->
  merge_states s1 (x !-> v ; s2) L = merge_states s1 s2 L.
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. reflexivity.
  - rewrite t_update_neq by assumption. reflexivity.
Qed.
```

把这两条引理与透明性中的合并消去结合，就得到公开赋值 `x := e` 的 SME 简化规则：
最终公开值中的表达式 `e` 在公开划分状态上求值，其余状态等同于原 `s`。

```coq
Lemma sme_state_update_pub : forall (x : string) (e : state -> nat) L s,
  L x = public ->
  sme_state (fun s => (x !-> e s ; s)) L s
    = (x !-> e (split_state s L public) ; s).
Proof.
  intros x e L s Hx. unfold sme_state.
  rewrite merge_states_update_pub_fst by assumption.
  rewrite merge_states_update_pub_snd by assumption.
  rewrite merge_state_pub_equiv.
  - reflexivity.
  - apply pub_equiv_split_state.
Qed.
```

这条规则精确显示秘密如何被切断：求 `e` 时看到的公开变量保持原值，看到的秘密
变量全是零。于是 `X := Y` 经 SME 后变成 `X := 0`，即整个转换器等于
`tconstX 0`。证明用 `HX`、`HY` 提供更新和划分引理需要的标签事实。

```coq
Lemma sme_state_tYtoX : sme_state tYtoX LXP = tconstX 0.
Proof.
  apply functional_extensionality. intros s. unfold tYtoX, tconstX.
  assert (HX : LXP X = public). { reflexivity. }
  assert (HY : LXP Y = secret). { reflexivity. }
  rewrite sme_state_update_pub by assumption.
  rewrite split_state_secret_zero by assumption. reflexivity.
Qed.
```

最后看 `X := X+Y`。公开 `X` 在公开划分中不变，秘密 `Y` 被替换为零，所以表达式
变成 `s X + 0`，即 `s X`。把 `X` 更新成它原有的值不会改变状态，因此整个 SME
结果等于恒等转换 `tid`。

```coq
Definition tXplusYtoX (s : state) : state := (X !-> s X + s Y ; s).

Lemma sme_state_tXplusYtoX : sme_state tXplusYtoX LXP = tid.
Proof.
  apply functional_extensionality. intros s. unfold tXplusYtoX, tid.
  assert (HX : LXP X = public). { reflexivity. }
  assert (HY : LXP Y = secret). { reflexivity. }
  rewrite sme_state_update_pub by assumption.
  rewrite split_state_public_id by assumption.
  rewrite split_state_secret_zero by assumption.
  rewrite Nat.add_0_r. apply t_update_same.
Qed.
```

## 本章小结

非干扰的核心不是“单次输出不暴露整个秘密”，而是“固定公开输入后，任何秘密变化
都不能改变攻击者可见的结果”。对纯函数，这等价于公开部分与秘密部分可划分；对
标签状态，这等价于划分所得纯函数的非干扰。SME 用独立公开运行强制切断秘密到公开
的流，并无条件获得安全性；只有原程序已经非干扰时，透明性才保证改造前后行为一致。
示例中的所有安全证明、反例与练习答案均由 Rocq 检查，无需额外公理或未证假设。
