# 43 · 自动化工程：evar 搜索与 hint 数据库

对应示例：`../examples/43_automation.v`（`Module Ex43Automation`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

18 章见过 `auto`，19 章写过 Ltac。本章把自动化当成一项**工程**来解剖：搜索机怎么工作、
hint 怎么注册进数据库、evar 怎么参与统一，以及每一样东西的**边界**在哪里。四个主角：

1. **`auto`**：带回溯的深度优先搜索机。它只用 `core` hint 库 + 上下文假设 + `intros`
   化简，默认深度 5。
2. **`eauto` / `eapply` / `eexists`**：把 evar（存在变量，"欠条"）塞进同一台搜索机——
   中间状态不用手写，靠后面的步骤统一出来。
3. **hint 数据库**：`Hint Resolve / Unfold / Constructors / Extern`，注册到 `core` 还是
   自建库（`Create HintDb`），以及模块边界与 `Local` 的作用域规则。
4. **`congruence`**：等式关系的判定过程——不搜索，直接判定。

本章的实验场还是 Imp 的 `ceval`（43.1 的副本）：同一个定理
`ceval_deterministic`（38.11 手证过十几个目标）会被 `auto`、自写 Ltac、`congruence`
三种方式逐步压缩，最后 `eauto` + hint 把一个带存在量词的求证**整条吞掉**。43.9 用
`~~P -> P` 摸到自动化的硬边界：evar 搜索不越经典逻辑一步。

### 43.1 语言与大步语义的副本（同 38–42 章）

与前几章相同的自包含副本（细节全在 38 章，此处不重复讲解）。文件头——注意
**`Classical` 不在这里**，43.9 会解释为什么它必须"晚点进来"：

```coq
(* 43 自动化工程：evar 搜索与 hint 数据库 —— auto / eauto / Hint / congruence *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex43Automation.

(* ---------- 43.1 语言与大步语义的副本（同 38–42 章） ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Definition state := total_map nat.

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
  (in custom com at level 0, x constr at level 0, y constr at level 85, no associativity,
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

Example ceval_example1 :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  apply E_Seq with (X !-> 2).
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.
```

### 43.2 auto：一台带回溯的深度优先搜索机

先建立基线：手写与一键的对照。

```coq
(* ---------- 43.2 auto：一台带回溯的深度优先搜索机 ---------- *)

Example auto_example_1 : forall (P Q R : Prop),
  (P -> Q) -> (Q -> R) -> P -> R.
Proof.
  intros P Q R HPQ HQR HP.
  apply HQR. apply HPQ. assumption.
Qed.

Example auto_example_1' : forall (P Q R : Prop),
  (P -> Q) -> (Q -> R) -> P -> R.
Proof.
  auto.
Qed.
```

同一命题：第一个证明把三步写出来，第二个一行 `auto`。auto 的搜索循环大致是：
`intros` 化简 → 按深度优先尝试（上下文假设 / `core` 库里的 hint / `apply` 构造子）→
失败就回溯换下一条。它不知道任何"聪明"策略，但试得快。

搜索能力的两极：

```coq
Example auto_example_2 : forall P Q R S T U : Prop,
  (P -> Q) ->
  (P -> R) ->
  (T -> R) ->
  (S -> T -> U) ->
  ((P -> Q) -> (P -> S)) ->
  T ->
  P ->
  U.
Proof. auto. Qed.

Example auto_algorithm : forall (P Q R : Prop),
  (Q -> R) ->
  ((P -> P) -> R) ->
  R.
Proof. intros P Q R HQR HPPR. debug auto. Qed.
```

`auto_example_2` 一口气穿过五层假设——前提够多时 auto 靠穷举就够了。
`auto_algorithm` 是 LF 的经典反例：`HQR : Q -> R` 需要 Q，唯一造 Q 的路不存在，
auto 必须回溯尝试 `HPPR (fun P:Prop => P)`（用 `(P -> P)` 实例化 `(P -> P)`）——
`debug auto` 在 repl 里打印完整搜索轨迹，包括失败与回溯的分支。**读轨迹是理解
auto 的唯一可靠方式**。

深度的账：

```coq
Example auto_example_3 : forall (P Q R S T U : Prop),
  (P -> Q) ->
  (Q -> R) ->
  (R -> S) ->
  (S -> T) ->
  (T -> U) ->
  P ->
  U.
Proof.
  intros P Q R S T U HPQ HQR HRS HST HTU HP.
  auto.
  auto 6.
Qed.
```

五条链式前提：默认深度 5 的 `auto` 差一步（第一条 `auto` 留下目标），`auto 6` 提深
一格后成功。**深度是 auto 的第一资源**，卡住先想"是不是深度不够"。

构造子与等式：

```coq
Example auto_example_4 : forall P Q R : Prop,
  Q ->
  (Q -> R) ->
  P \/ (Q /\ R).
Proof. auto. Qed.

Example auto_example_4' : forall P Q R : Prop,
  Q ->
  (Q -> R) ->
  P \/ (Q /\ R).
Proof. info_auto. Qed.

Check or_intror : forall A B : Prop, B -> A \/ B.
Check conj : forall A B : Prop, A -> B -> A /\ B.

Example auto_example_5 : 2 = 2.
Proof. info_auto. Qed.

Check @eq_refl : forall (A : Type) (x : A), x = x.
```

`auto_example_4` 说明 `\/`、`/\` 的构造子在 auto 的能力圈内（`or_intror`/`conj`
都在 `core`）。`info_auto` 是安静版 auto 的**留痕运行**——repl 里打印它实际用的每
一步，例如 `auto_example_5` 的轨迹就一行 `simple apply eq_refl (in core)`：2 = 2
靠的是自反性 hint。**`info_*` 系列回答"auto 到底用了什么"**。

`using` 与一次性引理：

```coq
Lemma le_antisym : forall n m : nat, (n <= m /\ m <= n) -> n = m.
Proof. lia. Qed.

Example auto_example_6 : forall n m p q : nat,
  (p = q -> (n <= m /\ m <= n)) ->
  p = q ->
  n = m.
Proof.
  auto using le_antisym.
Qed.
```

`auto` 自己不认识 `le_antisym`（自证引理不在库里）；`auto using le_antisym` 把它
**一次性**地加进本轮搜索，证完即弃。

### 43.3 hint 数据库：Resolve / Unfold / Extern 与自有库

一次性 `using` 的对面是**永久注册**：

```coq
(* ---------- 43.3 hint 数据库：Resolve / Unfold / Extern 与自有库 ---------- *)

Hint Resolve le_antisym : core.

Example auto_example_6' : forall n m p q : nat,
  (p = q -> (n <= m /\ m <= n)) ->
  p = q ->
  n = m.
Proof.
  auto.
Qed.
```

注册进 `core` 后，`auto_example_6'` 不再需要 `using`。代价也立刻显现：**core 是
全局库**，从注册点到文件结束的**每一个** auto/eauto 都会背着这条 hint 搜索——
hint 不是免费的，注册越多多搜索越慢、误命中越多。

第二种：让 auto **展开定义**。

```coq
Definition is_fortytwo (x : nat) := (x = 42).

Example auto_example_7 : forall x : nat,
  (x <= 42 /\ 42 <= x) -> is_fortytwo x.
Proof.
  auto.
Abort.

Hint Unfold is_fortytwo : core.

Example auto_example_7' : forall x : nat,
  (x <= 42 /\ 42 <= x) -> is_fortytwo x.
Proof.
  info_auto.
Qed.
```

`is_fortytwo x` 对 auto 是个黑盒（不展开定义），第一次 `auto` 失败（`Abort` 收场）；
`Hint Unfold is_fortytwo : core.` 教会 auto 把它展开成 `x = 42`，再由 `lia` 风格的
等式 hint + `Nat.le_antisymm`…实际 `info_auto` 的轨迹是 `lia` 型决策外的普通
`Nat.leb`/等式推理。要点：**自定义谓词要进 auto 的世界，先 `Hint Unfold`**。

第三种：**Extern 模式 hint**——目标长什么样时执行什么策略：

```coq
Create HintDb cong.

Hint Extern 4 (_ = _) => congruence : cong.

Example eq_extern_example :
  forall (A B C : Type) (f : A -> B) (g : B -> C) (x : A) (y : B),
    y = f x -> g y = g (f x).
Proof.
  Fail (solve [auto]).
  info_auto with cong.
Qed.
```

三件事：

- `Create HintDb cong.` 开一个**自有库**（避免污染 core）。实测 9.2 起隐式创建
  hint 库会触发弃用警告，所以 `Create` 这行是必需的（45 章坑清单第 55 条的实战）。
- `Hint Extern 4 (_ = _) => congruence : cong.`：凡目标是**任意等式**（模式 `_ = _`），
  把 `congruence` 作为优先级 4 的候选塞进搜索。数字越小越优先。
- 裸 `auto` 找不到（repl 实测报 `No applicable tactic.`——这是 `solve [auto]` 失败
  的消息），`info_auto with cong.` 挂上自有库后一步命中。

`Fail (solve [auto])` 的写法值得注意：要断言"auto 不行"，得用 `solve [...]` 包住
再 `Fail`——直接 `Fail auto.` 在 auto 成功时会报 "The command has not failed!"
（坑清单第 5 条）。

### 43.4 Ltac 入门：把剧本打包成 rwd / find_rwd / find_eqn

自动化不止 auto。19 章的 Ltac 在这里收网：把 38.11 确定性证明里的重复剧本打包。

```coq
(* ---------- 43.4 Ltac 入门：把剧本打包成 rwd / find_rwd / find_eqn ---------- *)

Ltac rwd H1 H2 := rewrite H1 in H2; discriminate.

Example rwd_example : forall (b : bexp) (st : state),
  beval st b = true ->
  beval st b = false ->
  False.
Proof.
  intros b st H1 H2.
  rwd H1 H2.
Qed.

Ltac find_rwd :=
  match goal with
  | [ H1 : ?E = true, H2 : ?E = false |- _ ] => rwd H1 H2
  end.

Ltac find_eqn :=
  match goal with
  | [ H1 : forall x, ?P x -> ?L = ?R,
      H2 : ?P ?X |- _ ] => rewrite (H1 X H2) in *
  end.
```

`rwd H1 H2` 是两步剧本（rewrite + discriminate）的具名封装；`find_rwd` 用
`match goal` 按**形状**找"同一表达式一处 = true 一处 = false"的矛盾对；
`find_eqn` 找"全称等式前提恰好可实例化"的机会。三段式进化看同一个定理：

```coq
Theorem ceval_deterministic : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2; inversion E2; subst.
  - reflexivity.
  - reflexivity.
  - rewrite (IHE1_1 st'0 H1) in *.
    apply IHE1_2. assumption.
  - apply IHE1. assumption.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - apply IHE1. assumption.
  - reflexivity.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *.
    apply IHE1_2. assumption.
Qed.

Theorem ceval_deterministic_auto : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2;
    inversion E2; subst;
    auto.
  - rewrite (IHE1_1 st'0 H1) in *.
    auto.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *.
    auto.
Qed.

Theorem ceval_deterministic_find : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2;
  induction E1; intros st2 E2; inversion E2; subst;
    try find_rwd;
    try find_eqn;
    auto.
Qed.
```

第一个是 38.11 的原版（十一个手写目标）。第二个在每个分支后挂 `auto`：六个平凡
分支（`reflexivity`/`assumption` 级）被吃掉，只剩需要真工作的五个。第三个再挂
`try find_rwd; try find_eqn`：矛盾型分支（`rewrite H; discriminate`）被 find_rwd
按形状收割、IH 改写型被 find_eqn 收割——**整条证明压缩成一行骨架 + 三个 try**。
这是"Ltac 是用户侧自动化"的直观含义：不写搜索机，写**识别器**。

### 43.5 eapply 与 evar：先立欠条，后还账

`auto` 的世界没有欠条，`eauto` 的世界有。欠条就是 **evar**（存在变量 `?x`）。

```coq
(* ---------- 43.5 eapply 与 evar：先立欠条，后还账 ---------- *)

Example ceval_apply_fail :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  Fail apply E_Seq.
Abort.
```

为什么 `apply E_Seq` 失败？repl 实测报错：

```
The command has indeed failed with message:
Unable to find an instance for the variable st'.
```

`E_Seq` 的中间状态 `st'` 在目标里没有信息可统一，`apply` 要求**当场**定出所有
变量。38.10 的办法是 `apply E_Seq with (X !-> 2)` 手工给。evar 版本：

```coq
Example ceval'_example1 :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  eapply E_Seq.
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.

Example eexists_example : exists s',
  (Y !-> 1 ; X !-> 2) =[
    if (X <= Y)
      then Z := 0
      else Y := 3
    end
  ]=> s'.
Proof.
  eexists. eapply E_IfFalse.
  - reflexivity.
  - eapply E_Asgn. reflexivity.
Qed.

Example econstructor_example :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  econstructor.
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.
```

- `eapply E_Seq`：中间状态立成欠条 `?st'`，第一个分支的 `apply E_Asgn` 用
  `reflexivity` 把它**还**成 `X !-> 2`——38.10 里"人肉想出中间状态"的步骤消失。
- `eexists`：连**最终状态**都可以打欠条（`eauto_example` 前的手工预演）。
- `econstructor`：`eapply 构造子` 的"自动选构造子"版——不用说出 `E_Seq`，它按目标
  形状挑。

欠条要还清：如果 Qed 时还有未决 evar，报
`Attempt to save an incomplete proof (the proof term is not complete)`——本章坑清单
第 2 条记录了一个更隐蔽的变体。

### 43.6 eauto 与 Hint Constructors：把 evar 塞进搜索机

evar + 搜索机 = eauto。同一个"求出终态"的例子：

```coq
(* ---------- 43.6 eauto 与 Hint Constructors：把 evar 塞进搜索机 ---------- *)

Example eauto_example_no_hint : exists s',
  (Y !-> 1 ; X !-> 2) =[
    if (X <= Y)
      then Z := 0
      else Y := 3
    end
  ]=> s'.
Proof.
  Fail (solve [eauto]).
Abort.

Create HintDb ceval_db.

Hint Constructors ceval : ceval_db.
Hint Transparent state total_map : ceval_db.

Example eauto_example : exists s',
  (Y !-> 1 ; X !-> 2) =[
    if (X <= Y)
      then Z := 0
      else Y := 3
    end
  ]=> s'.
Proof.
  info_eauto with ceval_db.
Qed.
```

- 没有 hint 时 `eauto` 找不到路（实测同样 `No applicable tactic.`）：它不知道
  `ceval` 的构造子能怎么拼。
- `Hint Constructors ceval : ceval_db.` 把七条构造子全部注册进自有库；注册时 repl
  打印一条值得细读的警告：`The hint E_Seq will only be used by eauto, because
  applying E_Seq would leave... unresolved variables`——**带前提的构造子只在 eauto
  的世界里有效**（apply 会留变量，auto 不敢用），这条警告就是 auto/eauto 分野的
  机制本体。
- `Hint Transparent state total_map : ceval_db.` 允许搜索机展开这两个定义（默认
  opaque）。
- `info_eauto with ceval_db.` 一步吞掉整个求证，repl 轨迹（编译输出里同样可见）：

```
(* info eauto: *)
simple eapply ex_intro.
 simple apply E_IfFalse.
  simple apply eq_refl.
  simple apply E_Asgn.
   simple apply eq_refl.
```

  读法：`ex_intro` 开存在量词（欠条 ?s'）→ `E_IfFalse` 选分支（又立 beval 欠条）→
  `eq_refl` 还掉（beval 计算 2 <=? 1 = false）→ `E_Asgn` 造终态 → `eq_refl` 还掉
  `aeval st 3 = 3`。**整棵推导树是机器长出来的**。

evar 与上下文的配合（LF 的 silly 家族）：

```coq
Lemma silly1 : forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (forall x y : nat, P x y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. eapply HQ. apply HP. Unshelve. exact 0.
Qed.

Lemma silly2 :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. eapply HQ. destruct HP as [y HP'].
  Fail apply HP'.
Abort.

Lemma silly2_fixed :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. destruct HP as [y HP'].
  eapply HQ. apply HP'.
Qed.

Lemma silly2_eassumption :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. destruct HP as [y HP'].
  eapply HQ. eassumption.
Qed.

Lemma silly2_eauto :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. destruct HP as [y HP']. eauto.
Qed.
```

`Unshelve.` 是把搁置的欠条拉回目标列表手工处理（silly1 演示）。silly2 的
`Fail apply HP'` 值得看 repl 原文——apply 试图把 `HP' : P 42 y` 对到
`P 42 ?y`（?y 已被 eauto 欠条绑定方向卡死），报 `Unable to unify`。修法有二：
先 destruct 再 eapply（silly2_fixed），或 `eassumption`——**assumption 的 evar 版**，
允许统一时带欠条（silly2_eassumption）；最后 `eauto` 一个词包圆（silly2_eauto）。

### 43.7 congruence：等式关系的判定过程

```coq
(* ---------- 43.7 congruence：等式关系的判定过程 ---------- *)

Theorem eq_example1 :
  forall (A B C : Type) (f : A -> B) (g : B -> C) (x : A) (y : B),
    y = f x -> g y = g (f x).
Proof.
  intros. rewrite H. reflexivity.
Qed.

Theorem eq_example1' :
  forall (A B C : Type) (f : A -> B) (g : B -> C) (x : A) (y : B),
    y = f x -> g y = g (f x).
Proof.
  congruence.
Qed.

Theorem eq_example2 : forall n m o p : nat,
    (n, o) = (m, p) ->
    n = m.
Proof.
  congruence.
Qed.

Theorem eq_example3 : forall (X : Type) (h : X) (t : list X),
    nil <> h :: t.
Proof.
  congruence.
Qed.
```

`congruence` 不是搜索机，是**判定过程**：它处理（不含未解释函数的）等式与不等式
理论——自反/对称/传递、函数合同（eq_example1' 的 `g y = g (f x)` 一行收）、构造子
单射与不相交（eq_example2/3）。40.6 里它自动吃掉 beval 矛盾靠的也是这个。

把它挂回确定性证明：

```coq
Theorem ceval_deterministic_congruence : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2;
    inversion E2; subst;
    auto;
    try congruence.
  - rewrite (IHE1_1 st'0 H1) in *.
    auto.
  - rewrite (IHE1_1 st'0 H3) in *.
    auto.
Qed.
```

对比 43.4 的 `_find` 版：四个 discriminate 分支被 `try congruence` 收编，只剩两个
真正要用 IH 的分支。**矛盾检测交给判定过程，归纳结构留给人**。

### 43.8 hint 的作用域：模块内外与 Local

```coq
(* ---------- 43.8 hint 的作用域：模块内外与 Local ---------- *)

Module HintScope.

Definition is_id (x : nat) := (x = x).

Hint Unfold is_id : core.

Example in_scope : forall x : nat, is_id x.
Proof. auto. Qed.

End HintScope.

Example out_of_scope : forall x : nat, HintScope.is_id x.
Proof.
  auto.
Abort.

Import HintScope.

Example back_in_scope : forall x : nat, is_id x.
Proof. auto. Qed.

Module LocalHintScope.

Definition is_id2 (x : nat) := (x = x).

Local Hint Unfold is_id2 : core.

Example local_in_scope : forall x : nat, is_id2 x.
Proof. auto. Qed.

End LocalHintScope.

Import LocalHintScope.

Example local_not_exported : forall x : nat, is_id2 x.
Proof.
  auto.
Abort.
```

两条作用域规则（两个 `Abort` 就是两个反例）：

- **hint 跟着模块走**：`HintScope` 里注册的 hint，出了模块（用全名 `HintScope.is_id`）
  不生效；`Import HintScope` 把定义和 hint 一起带回来（back_in_scope 通过）。
- **`Local Hint` 连 Import 都不带**：`LocalHintScope` 里 `Local Hint` 注册的 hint
  是模块私有，Import 之后照样不生效（local_not_exported 失败）。写库给别人用时，
  想 export 的 hint 千万别加 `Local`。

### 43.9 直觉边界：evar 搜索不越经典线

最后摸硬边界：双否消去 `~~P -> P` 在直觉逻辑里不可证——搜索机再强也不该找到它：

```coq
(* ---------- 43.9 直觉边界：evar 搜索不越经典线 ---------- *)

Example dne_intuitionistic : forall P : Prop, ~~ P -> P.
Proof.
  Fail (solve [eauto]).
  Fail (solve [tauto]).
Abort.
```

repl 实测两条都报 `No applicable tactic.`——eauto（evar 搜索）和 tauto（直觉命题
的判定过程）都诚实地失败。**这一节必须放在 `Classical` 之前**：文件开头若
`Require Import Classical`，经典引理的 hint 会进入搜索库，这里的两个 `Fail` 直接
变成 "The command has not failed!"（实测踩过，坑清单第 1 条）。所以本章的 Classical
是**在这里**才引入的：

```coq
From Stdlib Require Import Classical.

Check classic : forall P : Prop, P \/ ~ P.
Check NNPP : forall P : Prop, ~~ P -> P.

Example dne_classical : forall P : Prop, ~~ P -> P.
Proof.
  intros P H. destruct (classic P) as [Hp | Hnp]; tauto.
Qed.

Print Assumptions dne_classical.
```

`classic`（排中律）作为**公理**引入后，`destruct (classic P)` 分情况、两支都
`tauto` 关闭。`Print Assumptions` 的 repl 输出白纸黑字：

```
Axioms:
classic : forall P : Prop, P \/ ~ P
```

自动化的强度边界由此划定：**搜索能穷举假设、能开欠条，但不会替你发明公理**——
要用经典逻辑，就得显式引入并接受公理依赖（和 14 章的结论闭环）。

```coq
End Ex43Automation.
```

### 43.10 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到（报错文本来自 repl）。

1. **`Require Import Classical` 会污染 core 搜索库**（43.9）：文件头引入 Classical 后，
   `Fail (solve [eauto])`（~~P -> P）报 `The command has not failed!`——经典引理的
   hint 进了库，"直觉上不可证"的演示全部失效。修法：把 Classical 挪到演示**之后**
   局部引入（本文件的最终形态）。凡是要演示"自动化做不到 X"的实验，先审计 Require 行。
2. **evar 搁置的暗坑**（本会话实测，未入正文）：目标 `exists n, n + 0 = n` 上
   `solve [eauto]` 能成功，但 `eauto. Qed.` 与 `info_eauto. Qed.` 都报
   `Attempt to save an incomplete proof (the proof term is not complete)`——目标被关
   但欠条没还清。这类 evar 型等式目标要么手工 `exists 0`，要么 `Unshelve` 后处理。
3. **带前提的构造子 hint 只进 eauto**（43.6）：`Hint Constructors ceval` 时 repl 警告
   `The hint E_Seq will only be used by eauto, because applying E_Seq would leave ...
   unresolved variables`。想让 auto 也用，得保证构造子 apply 后不剩变量（或接受
   只给 eauto 用）。
4. **9.2 起隐式建 hint 库触发弃用警告**（43.3）：`Hint ... : mydb` 前必须
   `Create HintDb mydb.`（否则 `implicit-create-hint-db` 警告，未来变错误）。
5. **断言"tactic 不行"要用 `Fail (solve [tac])`**（43.3/43.6/43.9）：`Fail auto.` 在
   auto 成功时报 `The command has not failed!`；`solve [...]` 把"关掉全部目标"变成
   单个可失败的动作，才是 Fail 的正确对象。
6. **`info_*` 与原版的输出差异**（43.2/43.6）：`info_auto`/`info_eauto`/`debug auto`
   的轨迹只在 repl/IDE 显示，`rocq compile` 下与安静版行为一致——但个别目标上
   info 版与原版在 evar 处理上有差异（见第 2 条），以实测为准。
7. **hint 的成本是全局的**（43.3）：`Hint ... : core` 从注册点影响之后所有证明；
   演示性/实验性 hint 用 `Create HintDb` + `with` 限定，或放进模块管好作用域（43.8）。
8. **`Local Hint` 不随 Import 导出**（43.8）：写库时想导出的 hint 别加 `Local`；
   反过来，模块内部用的 hint 加 `Local` 是礼貌（不污染 import 者的搜索）。
9. **复合右端赋值在 本章文件 解析异常**（43.5/43.6）：`if ... then Z := Y - X ...`
   在本章环境实测报 `The term "Y" has type "string" while it is expected to have type
   "nat"`（右端 `-` 回落主语法），而同样文本在 38–42 章环境正常——根因未定位，
   规避法：此类语句一律用字面量右端（`Z := 0` / `Y := 3`）。已如实记录，供后来者
   续查。
10. **`Fail apply E_Seq` 的报错位置很诚实**（43.5）：`Unable to find an instance for
    the variable st'.` 直接点名还不出的变量——看到它就该想到 `with` 或 `eapply`。

---
上一章：[42 · Hoare 逻辑](42-hoare.md) ｜ 下一章：[44 · 简单类型 λ 演算](44-stlc.md) ｜ 返回：[README](../README.md)
