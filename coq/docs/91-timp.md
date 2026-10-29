# 75 · 案例：带类型的 Imp 的程序生成

对应示例：`../examples/75_timp.v`（`Module Ex75Timp`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

随机生成一个语法正确的程序，不等于生成了一个**良类型**程序。若先随机造表达式，再用
`has_type` 把不合格者过滤掉，绝大多数测试时间会花在 discard（丢弃）上；表达式越大、
类型规则越多， discard 风暴越严重。本章把生成方向反过来：把目标类型和类型上下文交给
生成器，让它每一步只选择能够构造目标类型的规则，再用 `backtrack` 处理局部失败。

这是一条完整的属性测试流水线：按类型生成表达式与命令，生成与上下文一致的运行时状态，
检查生成和收缩是否保持类型，最后检查表达式与命令求值不会把良类型程序误判为 `Fail`。
文中所有练习均直接给出可运行解答。

## 75.0 文件头与导入

```coq
(* 75 案例：带类型的 Imp 的程序生成 —— 按类型生成、回溯、类型保持收缩与派生测试 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From Stdlib Require Import Bool Arith EqNat List. Import ListNotations.
From QuickChick Require Import QuickChick Tactics.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Import QcNotation QcDefaultNotation.
Open Scope qc_scope. Open Scope monad_scope. Open Scope Checker_scope.
Set Bullet Behavior "Strict Subproofs".

Module Ex75Timp.
```

逐行看，前两行只关闭本项目示例不关心的警告；标准库提供布尔、自然数与列表，
`QuickChick` 提供生成器、类型类、checker 和派生命令，`Tactics` 提供 `dec_eq` 等决策
过程。`QcNotation`、`QcDefaultNotation` 与 `BindOptNotation` 分别提供测试记号和
`G (option A)` 的绑定记号。示例没有使用额外的门面模块，也没有依赖外部章节的定义。

## 75.1 标识符、类型与列表映射

先生成有限的标识符，后面的随机上下文才能反复命中变量。`Map A` 是关联列表，靠近表头
的绑定优先，因此 `map_set` 只需把新绑定 cons 到前面。

```coq
(* ---------- 75.1 标识符、类型与列表映射 ---------- *)

Inductive id :=
| Id : nat -> id.

#[export] Instance eq_id_dec (x1 x2 : id) : Dec (x1 = x2).
Proof. dec_eq. Defined.

#[export] Instance show_id : Show id :=
  { show x := let '(Id n) := x in show n }.

Fixpoint max_elt (al : list id) : nat :=
  match al with
  | [] => 0
  | Id n' :: al' => max n' (max_elt al')
  end.

Definition fresh (al : list id) : id :=
  Id (S (max_elt al)).

Fixpoint get_fresh_ids n l :=
  match n with
  | 0 => l
  | S n' => get_fresh_ids n' (fresh l :: l)
  end.

(* 练习 genId：从一小段新鲜标识符中均匀选择，空列表时给出默认值。 *)
#[export] Instance genId : Gen id :=
  { arbitrary := elems_ (Id 0) (get_fresh_ids 5 []) }.

#[export] Instance shrinkId : Shrink id :=
  { shrink x := [] }.

#[export] Instance arbitraryId : Arbitrary id := {}.

Inductive ty := TBool | TNat.

QCDerive (Arbitrary, Show) for ty.

#[export] Instance eq_dec_ty (x y : ty) : Dec (x = y).
Proof. dec_eq. Defined.

Definition Map A := list (id * A).
Definition map_empty {A} : Map A := [].

Fixpoint map_get {A} (m : Map A) x : option A :=
  match m with
  | [] => None
  | (k, v) :: m' => if x = k ? then Some v else map_get m' x
  end.

Definition map_set {A} (m : Map A) (x : id) (v : A) : Map A :=
  (x, v) :: m.

Fixpoint map_dom {A} (m : Map A) : list id :=
  match m with
  | [] => []
  | (k, v) :: m' => k :: map_dom m'
  end.

Inductive bound_to {A} : Map A -> id -> A -> Prop :=
| Bind : forall x m a, map_get m x = Some a -> bound_to m x a.

Ltac solve_left := try solve [left; econstructor; eauto].

Ltac solve_right :=
  let Contra := fresh "Contra" in
  try solve [right; intro Contra; inversion Contra; subst;
             clear Contra; eauto; congruence].

Ltac solve_sum := solve_left; solve_right.

#[export] Instance dec_bound_to {A : Type} Gamma x (T : A)
         `{D : forall (x y : A), Dec (x = y)}
  : Dec (bound_to Gamma x T).
Proof.
  constructor. unfold ssrbool.decidable.
  destruct (map_get Gamma x) eqn:Get; solve_sum.
  destruct (D a T) as [[Eq | NEq]]; subst; solve_sum.
Defined.

Definition context := Map ty.

Definition gen_typed_id_from_context (Gamma : context) (T : ty)
  : G (option id) :=
  oneOf_ (ret None)
    (List.map (fun '(x, T') => ret (Some x))
      (List.filter (fun '(x, T') => T = T' ?) Gamma)).

Definition gen_context (n : nat) : G context :=
  let domain := get_fresh_ids n [] in
  range <- vectorOf n arbitrary ;;
  ret (List.combine domain range).
```

**练习 `genId` 解答。** `elems_ default xs` 从 `xs` 中等概率取元素，`default` 处理空表；
这里产生有限的新标识符而不是任意自然数，能显著增加变量命中概率。`shrinkId` 不缩标识符，
避免把变量名变化与真正的表达式错误混在一起；空的 `Arbitrary` 实例复用已有 `Gen` 和
`Shrink` 两个父类。

`bound_to` 把查表结果提升为命题，`dec_bound_to` 再把命题变成可计算决策。`Defined` 而非
`Qed` 很关键：checker 需要真正计算实例。`gen_typed_id_from_context` 先按目标类型过滤，
再生成变量，这就是「按类型生成」在变量规则上的最小体现。`gen_context` 则把互不相同的
标识符与随机类型逐项配对。

**坑：** 列表映射允许重复键，但查找采用首个命中；不要把它当成会自动覆盖所有旧绑定的
树或哈希表。也不要把 `Dec` 实例证明封装成不透明常量，否则 `Compute` 和 QuickChick 无法
正常执行。

## 75.2 表达式、类型关系与 discard 风暴

表达式语言同时含自然数和布尔运算。`EEq` 支持两种操作数类型，但结果始终是 `TBool`；
这一扩展会贯穿求值、生成和收缩，避免各组件对语言的认知不一致。

```coq
(* ---------- 75.2 表达式、类型关系与 discard 风暴 ---------- *)

Inductive exp : Type :=
| EVar : id -> exp
| ENum : nat -> exp
| EPlus : exp -> exp -> exp
| EMinus : exp -> exp -> exp
| EMult : exp -> exp -> exp
| ETrue : exp
| EFalse : exp
| EEq : exp -> exp -> exp
| ELe : exp -> exp -> exp
| ENot : exp -> exp
| EAnd : exp -> exp -> exp.

QCDerive Show for exp.

Reserved Notation "Gamma '||-' e '\IN' T" (at level 40).

Inductive has_type : context -> exp -> ty -> Prop :=
| Ty_Var : forall x T Gamma,
    bound_to Gamma x T -> Gamma ||- EVar x \IN T
| Ty_Num : forall Gamma n,
    Gamma ||- ENum n \IN TNat
| Ty_Plus : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EPlus e1 e2 \IN TNat
| Ty_Minus : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EMinus e1 e2 \IN TNat
| Ty_Mult : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EMult e1 e2 \IN TNat
| Ty_True : forall Gamma, Gamma ||- ETrue \IN TBool
| Ty_False : forall Gamma, Gamma ||- EFalse \IN TBool
| Ty_EqNat : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EEq e1 e2 \IN TBool
| Ty_EqBool : forall Gamma e1 e2,
    Gamma ||- e1 \IN TBool -> Gamma ||- e2 \IN TBool ->
    Gamma ||- EEq e1 e2 \IN TBool
| Ty_Le : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- ELe e1 e2 \IN TBool
| Ty_Not : forall Gamma e,
    Gamma ||- e \IN TBool -> Gamma ||- ENot e \IN TBool
| Ty_And : forall Gamma e1 e2,
    Gamma ||- e1 \IN TBool -> Gamma ||- e2 \IN TBool ->
    Gamma ||- EAnd e1 e2 \IN TBool

where "Gamma '||-' e '\IN' T" := (has_type Gamma e T).

Ltac solve_inductives Gamma :=
  repeat (match goal with
  | [ IH : forall _ _, _ |- _ ] =>
      let H1 := fresh "H1" in
      pose proof (IH TNat Gamma) as H1;
      let H2 := fresh "H2" in
      pose proof (IH TBool Gamma) as H2;
      clear IH;
      destruct H1; destruct H2; solve_sum
  end).

#[export] Instance dec_has_type (e : exp) (Gamma : context) (T : ty)
  : Dec (Gamma ||- e \IN T).
Proof with solve_sum.
  constructor.
  generalize dependent Gamma.
  generalize dependent T.
  induction e; intros T Gamma; unfold ssrbool.decidable;
    try solve [destruct T; solve_sum];
    try solve [destruct T; solve_inductives Gamma].
  destruct (dec_bound_to Gamma i T); destruct dec; solve_sum.
Defined.

(* 练习 arbitraryExp：默认生成器完全不看类型，再靠前提过滤。 *)
QCDerive Arbitrary for exp.

Definition random_exp_context : context :=
  [(Id 0, TNat); (Id 1, TBool); (Id 2, TNat)].

Definition cond_prop :=
  forAll arbitrary (fun e =>
    (has_type random_exp_context e TNat) ? ==> true).


(* 丢弃率随尺寸上升；更昂贵的统计保留为命令，避免每次编译耗时。 *)
(* QuickChickWith (updMaxSize stdArgs 8) cond_prop. *)
```

**练习 `arbitraryExp` 解答。** `QCDerive Arbitrary for exp` 自动组合随机语法树生成器与默认
收缩器。条件性质 `P ==> true` 在 `P` 为假时不算失败，而是丢弃该样本；因此它没有证明
「所有随机表达式都良类型」，恰好展示了生成后过滤的浪费。廉价测试把尺寸限制为 3、成功数
限制为 50；尺寸 8 的对照保留为注释，因为深层随机树会带来更多丢弃和更长运行时间。

`dec_has_type` 是按表达式结构递归的类型检查算法，而 `has_type` 是类型关系，两者不要混为
一谈。`solve_inductives` 对递归假设分别尝试 `TNat` 与 `TBool`，对应同一表达式构造子在不同
目标类型下的分支。

**坑：** 条件性质通过，只说明保留下的样本满足结论，不说明生成器高产。若测试报告显示大量
 discarded，应改生成器，而不是简单提高成功次数。类型关系可计算决策也不等于已有高效生成
算法；下一节才解决生成问题。

## 75.3 沿类型和尺寸生成表达式

生成器的返回类型是 `G (option exp)`：`None` 表示某条局部生成路径失败。`bindGenOpt` 把失败
向后传播，`backtrack` 则在加权候选之间重试。尺寸既是结构递归燃料，也是递归分支的权重。

```coq
(* ---------- 75.3 沿类型和尺寸生成表达式 ---------- *)

Definition bindGenOpt {A B : Type}
  (gma : G (option A)) (k : A -> G (option B)) : G (option B) :=
  ma <- gma ;;
  match ma with
  | Some a => k a
  | None => ret None
  end.

Import BindOptNotation.

Definition gen_typed_evar (Gamma : context) (T : ty) : G (option exp) :=
  x <-- gen_typed_id_from_context Gamma T ;;
  ret (Some (EVar x)).

Definition base (Gamma : context) (T : ty) : list (nat * G (option exp)) :=
  (2, gen_typed_evar Gamma T) ::
  match T with
  | TNat => [(2, n <- arbitrary ;; ret (Some (ENum n)))]
  | TBool => [(1, ret (Some ETrue)); (1, ret (Some EFalse))]
  end.

Fixpoint gen_exp_typed_sized
  (size : nat) (Gamma : context) (T : ty) : G (option exp) :=
  let base := base Gamma T in
  let recs size' :=
    match T with
    | TNat =>
        [(size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EPlus e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EMinus e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EMult e1 e2)))]
    | TBool =>
        [(size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EEq e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TBool ;;
                e2 <-- gen_exp_typed_sized size' Gamma TBool ;;
                ret (Some (EEq e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (ELe e1 e2)));
         (size, e <-- gen_exp_typed_sized size' Gamma TBool ;;
                ret (Some (ENot e)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TBool ;;
                e2 <-- gen_exp_typed_sized size' Gamma TBool ;;
                ret (Some (EAnd e1 e2)))]
    end in
  match size with
  | 0 => backtrack base
  | S size' => backtrack (base ++ recs size')
  end.

Definition sample_context : context :=
  [(Id 0, TNat); (Id 1, TBool); (Id 2, TNat)].


Definition gen_typed_has_type :=
  let num_vars := 4 in
  let top_level_size := 3 in
  forAll (gen_context num_vars) (fun Gamma =>
  forAll arbitrary (fun T =>
  forAll (gen_exp_typed_sized top_level_size Gamma T) (fun me =>
  match me with
  | Some e => (has_type Gamma e T) ?
  | None => false
  end))).

```

`base` 只含当前类型的叶子规则：变量、数字或布尔常量。尺寸为零时只能走这些规则；尺寸为
`S size'` 时加入递归规则，并把每个子表达式的尺寸降为 `size'`。目标为 `TNat` 时只构造算术
节点，目标为 `TBool` 时构造比较、等式、否定与合取，因此每个成功返回的语法树按构造就带有
对应类型推导。

`x <-- g ;; k` 是 `bindGenOpt` 的记号：只有 `g` 返回 `Some x` 才继续。`backtrack` 接收
`(权重, 生成器)` 列表，失败可换候选重试；它让「上下文中暂时没有该类型变量」不必变成整个
测试失败。`Sample` 会打印若干随机布尔表达式，用来观察叶子、变量与递归节点的形状；每次
随机种子不同，具体样本不必逐字相同。

第一条最终性质 `gen_typed_has_type` 随机生成上下文与目标类型，再对成功生成的表达式调用
`dec_has_type`。这里把 `None` 记为失败，除了检查类型保持，也防止生成器靠永远失败来虚假
通过。100 次成功是廉价冒烟配置，而非形式化证明。

**坑：** 若只把尺寸当权重而递归时仍传 `size`，Rocq 无法确认结构递归终止；若只减小尺寸
却不按目标类型约束子生成器，仍会产生病类型节点。`backtrack` 能回溯局部失败，但不能修复
所有分支都可能失败的坏生成器。

## 75.4 值、状态与表达式求值

类型上下文描述静态世界，`state` 描述运行时世界。`well_typed_state Gamma st` 要求二者逐
项同名、同类型；表达式可靠性则以这个一致性为前提。

```coq
(* ---------- 75.4 值、状态与表达式求值 ---------- *)

Inductive value := VNat : nat -> value | VBool : bool -> value.

QCDerive Show for value.

Inductive has_type_value : value -> ty -> Prop :=
| TyVNat : forall n, has_type_value (VNat n) TNat
| TyVBool : forall b, has_type_value (VBool b) TBool.

#[export] Instance dec_has_type_value v T : Dec (has_type_value v T).
Proof.
  constructor; unfold ssrbool.decidable.
  destruct v; destruct T; solve_sum.
Defined.

Definition gen_typed_value (T : ty) : G value :=
  match T with
  | TNat => n <- arbitrary ;; ret (VNat n)
  | TBool => b <- arbitrary ;; ret (VBool b)
  end.

Definition state := Map value.

Inductive well_typed_state : context -> state -> Prop :=
| TS_Empty : well_typed_state map_empty map_empty
| TS_Elem : forall x v T st Gamma,
    has_type_value v T -> well_typed_state Gamma st ->
    well_typed_state ((x, T) :: Gamma) ((x, v) :: st).

#[export] Instance dec_well_typed_state Gamma st
  : Dec (well_typed_state Gamma st).
Proof.
  constructor; unfold ssrbool.decidable.
  generalize dependent Gamma.
  induction st; intros; destruct Gamma; solve_sum.
  destruct a as [a v]; destruct p as [a' T].
  destruct (@dec (a = a') _); solve_sum.
  subst; specialize (IHst Gamma); destruct IHst; solve_sum.
  destruct (dec_has_type_value v T); destruct dec; solve_sum.
Defined.

Definition gen_well_typed_state (Gamma : context) : G state :=
  sequenceGen (List.map (fun '(x, T) =>
    v <- gen_typed_value T ;;
    ret (x, v)) Gamma).

Fixpoint eval (st : state) (e : exp) : option value :=
  match e with
  | EVar x => map_get st x
  | ENum n => Some (VNat n)
  | EPlus e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VNat (n1 + n2))
      | _, _ => None
      end
  | EMinus e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VNat (n1 - n2))
      | _, _ => None
      end
  | EMult e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VNat (n1 * n2))
      | _, _ => None
      end
  | ETrue => Some (VBool true)
  | EFalse => Some (VBool false)
  | EEq e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VBool (n1 =? n2))
      | Some (VBool b1), Some (VBool b2) => Some (VBool (Bool.eqb b1 b2))
      | _, _ => None
      end
  | ELe e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VBool (n1 <? n2))
      | _, _ => None
      end
  | ENot e =>
      match eval st e with
      | Some (VBool b) => Some (VBool (negb b))
      | _ => None
      end
  | EAnd e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VBool b1), Some (VBool b2) => Some (VBool (andb b1 b2))
      | _, _ => None
      end
  end.

Definition isNone {A : Type} (m : option A) :=
  match m with
  | None => true
  | Some _ => false
  end.

Conjecture expression_soundness : forall Gamma st e T,
  well_typed_state Gamma st -> Gamma ||- e \IN T ->
  isNone (eval st e) = false.
```

`eval` 用 `option value` 同时表示类型错误、未绑定变量等失败。自然数减法使用截断减法，
所以不会因负数引入新类型。`EEq` 的两个分支与 `Ty_EqNat`、`Ty_EqBool` 一一对应。
`gen_well_typed_state` 遍历上下文，为每个类型生成一个值，再用 `sequenceGen` 收集成状态。

最后的 `Conjecture` 明确写出要测试的数学命题：在良类型状态和良类型表达式前提下，求值
不会返回 `None`。本章用可执行 checker 对它做随机检验，而不是把猜想冒充为已证明定理。

**坑：** 只检查「表达式良类型」不够；若状态缺少变量或存入错误类型的值，求值仍会失败。
 preservation 与 progress 也不是这里一条可执行性质自动证明的定理，测试只是寻找反例。

## 75.5 类型保持收缩与最小反例

发现反例后，QuickChick 默认会收缩语法树；但默认收缩可能把良类型前提破坏掉，使后续测试
落在一个与原始错误无关的病类型输入上。`shrink_exp_typed` 接收上下文和表达式类型，只提出
仍保持该类型的候选。

```coq
(* ---------- 75.5 类型保持收缩与最小反例 ---------- *)

Fixpoint shrink_exp_typed (Gamma : context) (T : ty) (e : exp) : list exp :=
  match e with
  | EVar _ =>
      match T with
      | TNat => [ENum 0]
      | TBool => [ETrue; EFalse]
      end
  | ENum _ => []
  | ETrue => []
  | EFalse => [ETrue]
  | EPlus e1 e2 =>
      e1 :: e2 ::
      (List.map (fun e1' => EPlus e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => EPlus e1 e2') (shrink_exp_typed Gamma TNat e2))
  | EMinus e1 e2 =>
      e1 :: e2 :: EPlus e1 e2 ::
      (List.map (fun e1' => EMinus e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => EMinus e1 e2') (shrink_exp_typed Gamma TNat e2))
  | EMult e1 e2 =>
      e1 :: e2 :: EPlus e1 e2 ::
      (List.map (fun e1' => EMult e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => EMult e1 e2') (shrink_exp_typed Gamma TNat e2))
  | EEq e1 e2 =>
      ETrue :: EFalse ::
      if (has_type Gamma e1 TNat) ?
      then
        (List.map (fun e1' => EEq e1' e2) (shrink_exp_typed Gamma TNat e1))
        ++ (List.map (fun e2' => EEq e1 e2') (shrink_exp_typed Gamma TNat e2))
      else
        (List.map (fun e1' => EEq e1' e2) (shrink_exp_typed Gamma TBool e1))
        ++ (List.map (fun e2' => EEq e1 e2') (shrink_exp_typed Gamma TBool e2))
  | ELe e1 e2 =>
      ETrue :: EFalse :: EEq e1 e2 ::
      (List.map (fun e1' => ELe e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => ELe e1 e2') (shrink_exp_typed Gamma TNat e2))
  | ENot e =>
      ETrue :: EFalse :: e :: List.map ENot (shrink_exp_typed Gamma TBool e)
  | EAnd e1 e2 =>
      ETrue :: EFalse :: e1 :: e2 ::
      (List.map (fun e1' => EAnd e1' e2) (shrink_exp_typed Gamma TBool e1))
      ++ (List.map (fun e2' => EAnd e1 e2') (shrink_exp_typed Gamma TBool e2))
  end.

Definition shrink_typed_has_type :=
  let num_vars := 4 in
  let top_level_size := 3 in
  forAll (gen_context num_vars) (fun Gamma =>
  forAll arbitrary (fun T =>
  forAll (gen_exp_typed_sized top_level_size Gamma T) (fun me =>
  match me with
  | Some e =>
      List.forallb (fun e' => (has_type Gamma e' T) ?)
        (shrink_exp_typed Gamma T e)
  | None => false
  end))).


Definition lift_shrink {A}
  (shr : A -> list A) (m : option A) : list (option A) :=
  match m with
  | Some x => List.map Some (shr x)
  | None => []
  end.

(* 最小变异器：只让根节点 EAnd 在两个布尔操作数上卡死。 *)
Definition eval_buggy (st : state) (e : exp) : option value :=
  match e with
  | EAnd e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VBool _), Some (VBool _) => None
      | _, _ => eval st e
      end
  | _ => eval st e
  end.

Definition expression_soundness_exec_with
  (evaluator : state -> exp -> option value) :=
  let num_vars := 4 in
  let top_level_size := 3 in
  forAll (gen_context num_vars) (fun Gamma =>
  forAll (gen_well_typed_state Gamma) (fun st =>
  forAll arbitrary (fun T =>
  forAllShrink (gen_exp_typed_sized top_level_size Gamma T)
    (lift_shrink (shrink_exp_typed Gamma T)) (fun me =>
  match me with
  | Some e => negb (isNone (evaluator st e))
  | None => true
  end)))).

Definition expression_soundness_buggy_exec :=
  expression_soundness_exec_with eval_buggy.


Definition expression_soundness_exec :=
  expression_soundness_exec_with eval.


(* 默认收缩器会破坏前提；下面的昂贵对照只按需运行。 *)
(* QuickChick (forAllShrink (gen_exp_typed_sized 3 sample_context TBool) shrink
     (fun me => match me with
                | Some e => negb (isNone (eval_buggy [] e))
                | None => true
                end)). *)
```

收缩有三类方向：变量缩为同类型常量；整个节点缩为同类型子表达式或更简单的同类型节点；
保留根节点而递归收缩某个孩子。`EFalse` 只缩到 `ETrue`，没有反向规则，避免收缩环。
`EEq` 先用左操作数的类型决定递归收缩分支，保证两侧仍使用同一种类型。

`lift_shrink` 把 `A -> list A` 提升到 `option A`；`forAllShrink` 将生成器、类型保持收缩器
和性质组装起来。`expression_soundness_exec_with` 参数化求值器，使同一个 checker 可以测试
错误实现与正确实现，避免两份性质悄悄分叉。

变异器只在根节点为 `EAnd` 且两侧都成功求出布尔值时返回 `None`，所以 bug 性质应当报告
失败，并在收缩后给出较小的 `EAnd` 反例；紧接着对正确 `eval` 的同一测试应通过。这里的
「失败」是刻意植入的测试警报，不是编译错误。默认收缩器的对照运行更慢，也更容易被病类型
中间样本干扰，因此保留为注释。

**坑：** 若变异器只在良类型输入不可能到达的分支出错，测试会虚假通过；若错误只改变结果值
而不产生 `None`，「不卡死」性质也看不到它。变异测试必须让错误落在性质实际观察的范围里。

## 75.6 良类型命令的生成、收缩与求值

命令的类型规则不需要结果类型，只需在固定上下文中检查赋值两侧一致、条件为布尔、子命令
均良类型。生成器沿用表达式的「基本情况 + 递归情况 + 回溯」结构。

```coq
(* ---------- 75.6 良类型命令的生成、收缩与求值 ---------- *)

Inductive com : Type :=
| CSkip : com
| CAsgn : id -> exp -> com
| CSeq : com -> com -> com
| CIf : exp -> com -> com -> com
| CWhile : exp -> com -> com.

Notation "'SKIP'" := CSkip.
Notation "x '::=' a" := (CAsgn x a) (at level 60).
Notation "c1 ;;; c2" := (CSeq c1 c2) (at level 80, right associativity).
Notation "'WHILE' b 'DO' c 'END'" :=
  (CWhile b c) (at level 80, right associativity).
Notation "'TEST' c1 'THEN' c2 'ELSE' c3 'FI'" :=
  (CIf c1 c2 c3) (at level 80, right associativity).

QCDerive Show for com.

Inductive well_typed_com : context -> com -> Prop :=
| TSkip : forall Gamma, well_typed_com Gamma CSkip
| TAsgn : forall Gamma x e T,
    bound_to Gamma x T -> Gamma ||- e \IN T ->
    well_typed_com Gamma (CAsgn x e)
| TSeq : forall Gamma c1 c2,
    well_typed_com Gamma c1 -> well_typed_com Gamma c2 ->
    well_typed_com Gamma (CSeq c1 c2)
| TIf : forall Gamma b c1 c2,
    Gamma ||- b \IN TBool ->
    well_typed_com Gamma c1 -> well_typed_com Gamma c2 ->
    well_typed_com Gamma (CIf b c1 c2)
| TWhile : forall Gamma b c,
    Gamma ||- b \IN TBool -> well_typed_com Gamma c ->
    well_typed_com Gamma (CWhile b c).

Lemma bind_deterministic Gamma x (T1 T2 : ty) :
  bound_to Gamma x T1 -> bound_to Gamma x T2 -> T1 = T2.
Proof.
  destruct T1; destruct T2; intros H1 H2; eauto;
    inversion H1; inversion H2; congruence.
Qed.

Lemma has_type_deterministic Gamma e (T1 T2 : ty) :
  has_type Gamma e T1 -> has_type Gamma e T2 -> T1 = T2.
Proof.
  destruct T1; destruct T2; intros H1 H2; eauto;
    inversion H1; inversion H2; subst; eauto; try congruence;
    inversion H7; subst; eapply bind_deterministic; eauto.
Qed.

Ltac solve_det :=
  match goal with
  | [ H1 : bound_to _ _ ?T1, H2 : bound_to _ _ ?T2 |- _ ] =>
      assert (T1 = T2) by (eapply bind_deterministic; eauto)
  | [ H1 : has_type _ _ ?T1, H2 : has_type _ _ ?T2 |- _ ] =>
      assert (T1 = T2) by (eapply has_type_deterministic; eauto)
  end.

#[export] Instance dec_well_typed_com (Gamma : context) (c : com)
  : Dec (well_typed_com Gamma c).
Proof with eauto.
  constructor. unfold ssrbool.decidable.
  induction c; solve_sum.
  - destruct (dec_bound_to Gamma i TNat); destruct dec;
    destruct (dec_has_type e Gamma TNat); destruct dec;
    destruct (dec_bound_to Gamma i TBool); destruct dec;
    destruct (dec_has_type e Gamma TBool); destruct dec; solve_sum;
    try solve_det; try congruence;
    right; intro Contra; inversion Contra; subst; clear Contra;
    try solve_det; try congruence;
    destruct T; eauto.
  - destruct IHc1; destruct IHc2; subst; eauto; solve_sum.
  - destruct IHc1; destruct IHc2; subst; eauto; solve_sum.
    destruct (dec_has_type e Gamma TBool); destruct dec; solve_sum.
  - destruct IHc;
    destruct (dec_has_type e Gamma TBool); destruct dec; solve_sum.
Defined.

Definition gen_asgn_typed (Gamma : context) : G (option com) :=
  oneOf_ (ret None)
    (List.map (fun '(x, T) =>
      e <-- gen_exp_typed_sized 2 Gamma T ;;
      ret (Some (CAsgn x e))) Gamma).

Fixpoint gen_com_typed (size : nat) (Gamma : context) : G (option com) :=
  let base := [(1, ret (Some CSkip)); (2, gen_asgn_typed Gamma)] in
  match size with
  | 0 => backtrack base
  | S size' =>
      backtrack (base ++
        [(size, c1 <-- gen_com_typed size' Gamma ;;
                c2 <-- gen_com_typed size' Gamma ;;
                ret (Some (CSeq c1 c2)));
         (size, b <-- gen_exp_typed_sized 2 Gamma TBool ;;
                c1 <-- gen_com_typed size' Gamma ;;
                c2 <-- gen_com_typed size' Gamma ;;
                ret (Some (CIf b c1 c2)));
         (size, b <-- gen_exp_typed_sized 2 Gamma TBool ;;
                c <-- gen_com_typed size' Gamma ;;
                ret (Some (CWhile b c)))])
  end.

Fixpoint shrink_com_typed (Gamma : context) (c : com) : list com :=
  match c with
  | CSkip => []
  | CAsgn x e =>
      CSkip ::
      match map_get Gamma x with
      | Some T => List.map (CAsgn x) (shrink_exp_typed Gamma T e)
      | None => []
      end
  | CSeq c1 c2 =>
      CSkip :: c1 :: c2 ::
      (List.map (fun c1' => CSeq c1' c2) (shrink_com_typed Gamma c1))
      ++ (List.map (fun c2' => CSeq c1 c2') (shrink_com_typed Gamma c2))
  | CIf b c1 c2 =>
      CSkip :: c1 :: c2 ::
      (List.map (fun b' => CIf b' c1 c2) (shrink_exp_typed Gamma TBool b))
      ++ (List.map (fun c1' => CIf b c1' c2) (shrink_com_typed Gamma c1))
      ++ (List.map (fun c2' => CIf b c1 c2') (shrink_com_typed Gamma c2))
  | CWhile b c =>
      CSkip :: c ::
      (List.map (fun b' => CWhile b' c) (shrink_exp_typed Gamma TBool b))
      ++ (List.map (CWhile b) (shrink_com_typed Gamma c))
  end.

Definition gen_com_typed_has_type :=
  forAll (gen_context 4) (fun Gamma =>
  forAll (gen_com_typed 3 Gamma) (fun mc =>
  match mc with
  | Some c => (well_typed_com Gamma c) ?
  | None => false
  end)).


Definition shrink_com_typed_has_type :=
  forAll (gen_context 4) (fun Gamma =>
  forAll (gen_com_typed 3 Gamma) (fun mc =>
  match mc with
  | Some c =>
      List.forallb (fun c' => (well_typed_com Gamma c') ?)
        (shrink_com_typed Gamma c)
  | None => false
  end)).



Inductive result :=
| Success : state -> result
| Fail : result
| OutOfGas : result.

Fixpoint ceval (fuel : nat) (st : state) (c : com) : result :=
  match fuel with
  | 0 => OutOfGas
  | S fuel' =>
      match c with
      | SKIP => Success st
      | x ::= e =>
          match eval st e with
          | Some v => Success (map_set st x v)
          | None => Fail
          end
      | c1 ;;; c2 =>
          match ceval fuel' st c1 with
          | Success st' => ceval fuel' st' c2
          | Fail => Fail
          | OutOfGas => OutOfGas
          end
      | TEST b THEN c1 ELSE c2 FI =>
          match eval st b with
          | Some (VBool b') => ceval fuel' st (if b' then c1 else c2)
          | _ => Fail
          end
      | WHILE b DO c END =>
          match eval st b with
          | Some (VBool b') =>
              if b' then ceval fuel' st (c ;;; WHILE b DO c END)
              else Success st
          | _ => Fail
          end
      end
  end.

Definition isFail r :=
  match r with
  | Fail => true
  | _ => false
  end.

Conjecture well_typed_state_never_stuck :
  forall Gamma st, well_typed_state Gamma st ->
  forall c, well_typed_com Gamma c ->
  forall fuel, isFail (ceval fuel st c) = false.

(* 练习 well_typed_state_never_stuck：checker 与 OutOfGas 回归测试。 *)
Definition well_typed_state_never_stuck_exec :=
  forAll (gen_context 4) (fun Gamma =>
  forAll (gen_well_typed_state Gamma) (fun st =>
  forAllShrink (gen_com_typed 3 Gamma)
    (lift_shrink (shrink_com_typed Gamma)) (fun mc =>
  forAll (choose (0, 20)) (fun fuel =>
  match mc with
  | Some c => negb (isFail (ceval fuel st c))
  | None => true
  end)))).


Example out_of_gas_is_not_fail :
  isFail (ceval 1 [] (CSkip ;;; CWhile ETrue CSkip)) = false.
Proof. reflexivity. Qed.

(* 尺寸 8、10000 次成功的命令压力测试较慢，按需取消注释。 *)
(* QuickChickWith (updMaxSize stdArgs 8) well_typed_state_never_stuck_exec. *)
```

**练习 `arbitrary_well_typed_com` 解答。** `gen_asgn_typed` 从上下文中选变量，再按该变量的
类型生成右值；`gen_com_typed` 的叶子是 `CSkip` 与赋值，递归分支覆盖顺序、条件和循环。
`shrink_com_typed` 删除命令、缩到子命令，或分别收缩条件和子命令；赋值分支先查变量类型，
因此右值收缩仍保持赋值规则。两条 QuickChick 性质分别检查生成与收缩的类型保持，`Sample`
打印若干命令，具体随机树形每次可以不同。

`bind_deterministic` 与 `has_type_deterministic` 是类型唯一性引理，帮助命令决策过程排除
「同一种语法节点却换了一种类型推导」的情况。它们服务于可计算决策，不改变生成器本身。

**练习 `well_typed_state_never_stuck` 解答。** checker 联合生成上下文、良类型状态、良类型
命令和 0 到 20 的燃料，只把 `Fail` 视为反例。循环可能耗尽燃料，因此 `OutOfGas` 不是类型
错误；顺序执行必须原样传播 `OutOfGas`，不能错误地归并成 `Fail`。回归例子用极少燃料强制
覆盖这条路径。

正确实现下，廉价测试应当通过；尺寸 8 的压力测试会生成更深命令、运行更久，故保留为注释。
注释中提到的一万次成功配置适合人工加大 `updMaxSuccess` 后运行，不适合每次构建都执行。

**坑：** 「不会 `Fail`」不等于「循环一定终止」。燃料语义故意用第三个构造子区分运行资源
不足与语言层面的卡死，测试结论也必须保留这个区别。

## 75.7 布尔等式扩展的联动检查

新增一条类型规则并不够。下面三个小例子分别固定类型推导、求值结果和收缩列表，防止以后
只改一个组件而造成隐性不一致。

```coq
(* ---------- 75.7 布尔等式扩展的联动检查 ---------- *)

Example boolean_equality_has_type :
  sample_context ||- EEq ETrue (ENot EFalse) \IN TBool.
Proof. apply Ty_EqBool; repeat constructor. Qed.

Example boolean_equality_eval :
  eval [] (EEq ETrue (ENot EFalse)) = Some (VBool true).
Proof. reflexivity. Qed.

Example boolean_equality_shrinks :
  shrink_exp_typed sample_context TBool (EEq ETrue (ENot EFalse)) =
  [ETrue; EFalse; EEq ETrue ETrue; EEq ETrue EFalse;
   EEq ETrue EFalse; EEq ETrue (ENot ETrue)].
Proof. reflexivity. Qed.
```

`ENot EFalse` 求值为真，所以整个布尔等式为真。收缩时先给出 `ETrue`、`EFalse`，再保留
`EEq` 并收缩右操作数；列表中的重复候选来自不同收缩路径，当前实现没有去重。这个精确
例子还提醒读者：`ENot EFalse` 会先缩到 `ETrue`、`EFalse` 等更小候选，而不是保持不变。

**坑：** 为语言增加构造子或类型规则时，要同步检查决策过程、求值器、生成器、收缩器和精确
回归例子；只让 `has_type` 接受新程序并不会让测试流水线自动支持它。

## 75.8 `QCDerive ArbitrarySizedSuchThat` 与 `DecOpt` 实战

手写生成器适合本章这种复杂递归规格。对于 `has_type_value` 这样直接由归纳关系描述的简单
规格，可以让 QuickChick 2.2 自动派生按尺寸的条件生成器与可选决策器。

```coq
(* ---------- 75.8 QCDerive ArbitrarySizedSuchThat 与 DecOpt ---------- *)

QCDerive ArbitrarySizedSuchThat for (fun v => has_type_value v T).


QCDerive DecOpt for (has_type_value v T).

Compute ((has_type_value (VBool true) TBool) ?? 10).
Compute ((has_type_value (VNat 0) TBool) ?? 10).

Definition derived_value_sound :=
  forAll arbitrary (fun T =>
  forAll (genST (fun v => has_type_value v T)) (fun mv =>
  match mv with
  | Some v => (has_type_value v T) ?
  | None => false
  end)).


End Ex75Timp.
```

派生出的类方法是 `arbitrarySizeST`；通常使用便捷函数 `genSizedST P fuel` 显式给尺寸，或用
`genST P` 让 QuickChick 管理尺寸。两个 `Sample` 分别展示布尔值和自然数值的条件生成样本，
返回值为 `option`，因为派生生成器保留失败可能性。

`DecOpt` 的 `P ?? fuel` 返回可选决策结果：第一组类型匹配，第二组把自然数值放进布尔类型，
二者应得到不同结果；燃料限制搜索深度。最后的 `derived_value_sound` 随机选类型，再检查派生
生成器每次成功返回的值确实满足 `has_type_value`，与 75.3 的手写生成器性质形成对照。

**坑：** QuickChick 2.2 使用 `QCDerive`，不要照搬旧教程的 `Derive`。`genST` 与 `genSizedST`
用于条件生成，`??` 用于带燃料的命题决策，三者不要混写。派生成功也不等于生成器永远不会
返回 `None`，所以最终性质显式把 `None` 判为失败。

## 75.9 激活的廉价随机测试与真实输出

QuickChick 2.2 的测试命令会临时定义并提取一个名为 `quickchick` 的常量。在本机 Rocq 9.1.1
环境中，若命令位于 `Ex75Timp` 内，常量也被提取进同名 OCaml 模块，而插件追加的主程序却使用
未限定的 `quickchick`，从而报 `Unbound value quickchick`。因此定义仍全部留在模块内，测试驱动
则统一放在 `End Ex75Timp` 后；`Import Ex75Timp` 只把定义和实例重新引入当前作用域。

```coq
Import Ex75Timp.

(* ---------- 75.9 激活的廉价随机测试 ---------- *)

QuickChickWith (updMaxSize (updMaxSuccess stdArgs 50) 3) cond_prop.
Sample (gen_exp_typed_sized 3 sample_context TBool).
QuickChickWith (updMaxSuccess stdArgs 100) gen_typed_has_type.
QuickChickWith (updMaxSuccess stdArgs 100) shrink_typed_has_type.
QuickChickWith (updMaxSuccess stdArgs 100) expression_soundness_buggy_exec.
QuickChickWith (updMaxSuccess stdArgs 100) expression_soundness_exec.
QuickChickWith (updMaxSuccess stdArgs 100) gen_com_typed_has_type.
QuickChickWith (updMaxSuccess stdArgs 100) shrink_com_typed_has_type.
Sample (gen_com_typed 3 sample_context).
QuickChickWith (updMaxSuccess stdArgs 100) well_typed_state_never_stuck_exec.
Sample (genST (fun v => has_type_value v TBool)).
Sample (genSizedST (fun v => has_type_value v TNat) 3).
QuickChickWith (updMaxSuccess stdArgs 100) derived_value_sound.
```

这些命令全部实际运行。一次本机构建的关键输出节选如下；随机种子改变时，样本、discard 数和
发现反例所需的测试数也会改变。

```text
QuickChecking cond_prop
+++ Passed 50 tests (802 discards)

QuickChecking expression_soundness_buggy_exec
Some EAnd ETrue ETrue
*** Failed after 11 tests and 0 shrinks. (0 discards)

QuickChecking expression_soundness_exec
+++ Passed 100 tests (0 discards)
```

`cond_prop` 为得到 50 个有效样本丢弃了 802 个随机表达式，直接展示了生成后过滤的浪费。
变异器在第 11 次测试被发现；`EAnd ETrue ETrue` 仍有布尔叶子等收缩候选，但变异只影响根结点为 `EAnd` 的表达式，候选不再触发该失败，因此没有可接受的失败收缩，报告为 `0 shrinks`。
随后同一个性质改用正确的 `eval` 后通过，说明反例确实来自植入的 bug，而不是生成器或状态生成。

其余正确性 checker 的本次结果均为 `Passed 100 tests (0 discards)`：

| Checker | 检查内容 |
| --- | --- |
| `gen_typed_has_type` | 表达式生成保持目标类型，且不依靠返回 `None` 虚假通过 |
| `shrink_typed_has_type` | 表达式收缩候选保持类型 |
| `gen_com_typed_has_type` | 命令生成保持良类型 |
| `shrink_com_typed_has_type` | 命令收缩候选保持良类型 |
| `well_typed_state_never_stuck_exec` | 良类型状态和命令不会产生 `Fail` |
| `derived_value_sound` | 派生的条件值生成器满足类型规格 |

两个表达式与命令 `Sample` 分别打印出变量、布尔运算、赋值、条件和循环等随机语法树；派生值
样本形如 `[Some VBool false; Some VBool true; ...]` 与
`[Some VNat 10; Some VNat 9; ...]`。这与派生规格一致，而不是先任意生成值再过滤。
两组 `Compute` 的确定输出分别为：

```text
= Some true
: option bool
= Some false
: option bool
```

第一组证明决策器接受 `has_type_value (VBool true) TBool`，第二组拒绝把 `VNat 0` 当成布尔值。

**坑：** 变异 checker 的 `Failed` 是本章预期的测试输出，不是 Rocq 编译错误；完整示例构建仍以
退出码 0 结束。随机测试通过也不等于相应的 `Conjecture` 已成为证明定理。若把测试命令重新移回
模块内部，在上述插件版本中可能再次出现提取名未限定的问题。

## 总结：为什么按类型生成

先生成再过滤把类型知识只用于「事后拒绝」，按类型生成则把同一份类型知识用于「事前构造」。
后者减少 discard，让尺寸预算真正花在有效测试上；再配套良类型状态与类型保持收缩，反例的
生成、复现和最小化都始终处在性质前提之内。QuickChick 测试不能替代 preservation、progress
等形式化证明，但它能高效发现规则实现之间的偏差，尤其适合本章这种多组件联动案例。
