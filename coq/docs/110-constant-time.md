# 110. 密码学常时：分支、地址与观察语义

对应示例：`../examples/110_constant_time.v`。本章只依赖 Rocq 标准库，不导入 SECF，也不依赖本项目的其他章节；示例中的定义、练习与证明均可独立编译。

## 110.0 为什么用“观察”而不是秒数

密码学常时（cryptographic constant-time，CCT）要防止秘密通过执行时间泄露。直接给每条指令标注秒数看似直观，实际上会把缓存命中、流水线、微架构、编译器调度和具体处理器型号全部卷入模型。即使算出某个抽象秒数，也未必对应真实硬件。

本章采用更适合程序证明的**泄露模型**：攻击者能看到

1. 每次命令分支选择的是真还是假；
2. 每次数组读写的数组名与下标，也就是访问地址；
3. 执行轨迹上这些观察的先后顺序。

于是，常时安全不再说“两次运行耗时完全相同”，而说：只要两份初始输入的公开部分相同，两次运行产生的观察序列就必须完全相同。分支路径和缓存地址若依赖秘密，观察序列就会不同，攻击者便可能据此区分秘密输入。这个模型有意抽象掉秒数，却保留了常时编程最关键的两条纪律：**不以秘密控制分支，不以秘密计算地址**。

数组让第二条纪律变得非平凡。只有标量变量时，变量可类比固定寄存器，变量名对应的地址在程序写好时已经固定；即使变量里存的是秘密，读取这个固定位置也不会暴露秘密值。数组下标却在运行时计算，`AP[W]` 的实际地址可以是 `AP` 的任意元素，因此秘密 `W` 会进入地址与缓存轨迹。反之，常时条件表达式 `ACTIf` 只是在表达式层选择一个自然数，不是命令分支，也不访问数组，所以不产生任何观察；它可以安全地把秘密影响限制在数据流中。

本章的实现路线是：全映射与表达式 → 数组命令与观察语义 → 公开等价和安全定义 → CCT 类型系统与检查器 → 表达式、状态、内存非干扰 → 观察安全主定理 → 安全反例与程序修复。

---

## 110.1 自包含全映射

示例开头的注释说明主题与来源。标准库导入提供自然数运算、布尔值、列表、`lia` 算术证明和字符串；`ListNotations` 使 `[a0;a1]` 等列表记号可用。所有定义放入模块，避免名称污染。

```coq
(* 110 密码学常时：分支、地址与观察语义 *)
(* 取材 Software Foundations 卷七 SpecCT 的密码学常时部分；全部定义自包含。 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex110ConstantTime.

(* ---------- 110.1 自包含全映射 ---------- *)
```

全映射就是从字符串到值的全函数。`t_empty v` 给每个键都返回默认值 `v`；`t_update m x v` 只改变键 `x` 的结果。记号 `__ !-> v` 表示空映射，`x !-> v ; m` 表示在 `m` 上更新 `x`。状态和后面的数组内存都复用这一结构。

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
```

三条映射定律都是定义展开后的直接结论：空映射查询得到默认值；更新后查询同一个键得到新值；查询不同键保持旧值。不同键情形用 `String.eqb_spec` 同时获得布尔判断与相等/不等命题，不需要额外公理。

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

Lemma t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.
```

---

## 110.2 表达式与常时条件表达式

`binop` 把算术、比较和布尔连接词统一为一个枚举。自然数同时承担 C 风格布尔值：零为假，非零为真。`not_zero` 保留所有非零表示，`bool_to_nat` 则把 Coq 布尔值规范化成 `1` 或 `0`。减法采用自然数的截断减法；蕴含按“非前提或结论”计算。

```coq
(* ---------- 110.2 表达式与常时条件表达式 ---------- *)

Inductive binop : Type :=
  | BinPlus | BinMinus | BinMult | BinEq | BinLe | BinAnd | BinImpl.

Definition not_zero (n : nat) : bool := negb (n =? 0).
Definition bool_to_nat (b : bool) : nat := if b then 1 else 0.

Definition eval_binop (o : binop) (n1 n2 : nat) : nat :=
  match o with
  | BinPlus => n1 + n2
  | BinMinus => n1 - n2
  | BinMult => n1 * n2
  | BinEq => bool_to_nat (n1 =? n2)
  | BinLe => bool_to_nat (n1 <=? n2)
  | BinAnd => bool_to_nat (not_zero n1 && not_zero n2)
  | BinImpl => bool_to_nat (negb (not_zero n1) || not_zero n2)
  end.
```

表达式有常数、变量、二元运算和 `ACTIf b e1 e2`。最后一项对应 `b ? e1 : e2`：它表达的是值选择，而不是命令控制流。把布尔表达式编码成自然数表达式后，无需让算术表达式和布尔表达式互相递归定义。

```coq
Inductive exp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | ABin (o : binop) (e1 e2 : exp)
  | ACTIf (b : exp) (e1 e2 : exp).
```

这些缩写恢复常见的运算名称。`BNot b` 是 `b` 蕴含假；`BOr`、不等、大于和小于也都由已有运算定义。变量名和数组名只是字符串常量：`W` 将在反例中保存秘密下标，`AP` 是公开数组，`AS` 默认是秘密数组。两个 `Coercion` 允许在需要表达式的地方直接写字符串或自然数。

```coq
Definition APlus := ABin BinPlus.
Definition AMinus := ABin BinMinus.
Definition AMult := ABin BinMult.
Definition BTrue := ANum 1.
Definition BFalse := ANum 0.
Definition BAnd := ABin BinAnd.
Definition BImpl := ABin BinImpl.
Definition BNot b := BImpl b BFalse.
Definition BOr e1 e2 := BImpl (BNot e1) e2.
Definition BEq := ABin BinEq.
Definition BNeq e1 e2 := BNot (BEq e1 e2).
Definition BLe := ABin BinLe.
Definition BGt e1 e2 := BNot (BLe e1 e2).
Definition BLt e1 e2 := BGt e2 e1.

Definition U : string := "U".
Definition V : string := "V".
Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".
Definition AP : string := "AP".
Definition AS : string := "AS".

Coercion AId : string >-> exp.
Coercion ANum : nat >-> exp.
```

---

## 110.3 数组命令、求值与更新

命令语言包含空命令、赋值、顺序、条件和循环，并新增 `ALoad x a i` 与 `AStore a i e`。前者从数组 `a` 的下标 `i` 读入变量 `x`，后者把表达式 `e` 的值写入数组。`state` 把变量映射到自然数；`mem` 把数组名映射到自然数列表，列表下标就是内存地址偏移。

```coq
(* ---------- 110.3 数组命令、表达式求值与数组更新 ---------- *)

Inductive com : Type :=
  | Skip
  | Asgn (x : string) (e : exp)
  | Seq (c1 c2 : com)
  | If (be : exp) (c1 c2 : com)
  | While (be : exp) (c : com)
  | ALoad (x : string) (a : string) (i : exp)
  | AStore (a : string) (i : exp) (e : exp).

Definition state := total_map nat.
Definition mem := total_map (list nat).
```

`eval` 是纯函数，不返回观察列表。特别是 `ACTIf` 只计算一个自然数结果，没有 `OBranch` 可以附加。这里利用表达式无副作用的事实选择所要求值的分支；实际编译时可对应条件传送。关键不是 Coq 的 `if` 长什么样，而是该表达式求值不会进入命令语义的分支观察规则。

```coq
Fixpoint eval (s : state) (e : exp) : nat :=
  match e with
  | ANum n => n
  | AId x => s x
  | ABin b e1 e2 => eval_binop b (eval s e1) (eval s e2)
  | ACTIf b e1 e2 =>
      if not_zero (eval s b) then eval s e1 else eval s e2
  end.
```

两条辅助引理把求值结果为零或后继数转化成布尔判断。`upd` 递归替换列表第 `i` 项；空列表保持不变。语义规则另用边界检查保证读写发生在已有元素上。

```coq
Lemma not_zero_eval_S : forall b n s,
  eval s b = S n ->
  not_zero (eval s b) = true.
Proof. intros b n s H. rewrite H. reflexivity. Qed.

Lemma not_zero_eval_O : forall b s,
  eval s b = 0 ->
  not_zero (eval s b) = false.
Proof. intros b s H. rewrite H. reflexivity. Qed.

Fixpoint upd (i : nat) (ns : list nat) (n : nat) : list nat :=
  match i, ns with
  | 0, _ :: ns' => n :: ns'
  | S i', n' :: ns' => n' :: upd i' ns' n
  | _, [] => ns
  end.
```

---

## 110.4 带观察的大步语义

观察类型精确对应泄露模型：`OBranch b` 暴露命令分支布尔值，`OALoad a i` 和 `OAStore a i` 暴露数组名与下标。观察轨迹是按执行顺序排列的列表。

```coq
(* ---------- 110.4 带观察的大步语义 ---------- *)

Inductive observation : Type :=
  | OBranch (b : bool)
  | OALoad (a : string) (i : nat)
  | OAStore (a : string) (i : nat).

Definition obs := list observation.
```

`cteval c s m s' m' os` 表示：命令 `c` 从状态 `s`、内存 `m` 执行到 `s'`、`m'`，并产生观察 `os`。逐条规则如下。

- `CTE_Skip`：不改变任何内容，观察为空。
- `CTE_Asgn`：先纯求值，再更新变量；不观察变量访问，也不观察 `ACTIf` 的条件，所以观察仍为空。
- `CTE_Seq`：第二段从第一段的结果继续，观察用 `os1 ++ os2` 串接。
- `CTE_If`：根据 `not_zero (eval s be)` 选择分支，把分支观察放在所选分支轨迹之前。只用一条归纳规则配合元语言 `let`，避免重复真/假两套形式。
- `CTE_While`：把循环展开为“若条件成立则执行循环体后再循环，否则跳过”。循环的每次条件判断都由 `If` 规则记录。
- `CTE_ALoad`：要求下标在界内，将 `nth i (m a) 0` 写入变量，产生单元素观察 `[OALoad a i]`。
- `CTE_AStore`：分别求出值和下标并检查边界，更新列表对应元素，产生 `[OAStore a i]`。越界读写没有大步语义，安全定理因此量化所有实际存在的终止执行。

最后的提示注册只帮助构造证明，不改变语义。

```coq
Inductive cteval : com -> state -> mem -> state -> mem -> obs -> Prop :=
  | CTE_Skip : forall s m,
      cteval Skip s m s m []
  | CTE_Asgn : forall s m e n x,
      eval s e = n ->
      cteval (Asgn x e) s m (x !-> n ; s) m []
  | CTE_Seq : forall c1 c2 s m s' m' s'' m'' os1 os2,
      cteval c1 s m s' m' os1 ->
      cteval c2 s' m' s'' m'' os2 ->
      cteval (Seq c1 c2) s m s'' m'' (os1 ++ os2)
  | CTE_If : forall s m s' m' be c1 c2 os1,
      let c := if not_zero (eval s be) then c1 else c2 in
      cteval c s m s' m' os1 ->
      cteval (If be c1 c2) s m s' m'
        (OBranch (not_zero (eval s be)) :: os1)
  | CTE_While : forall b s m s' m' os c,
      cteval (If b (Seq c (While b c)) Skip) s m s' m' os ->
      cteval (While b c) s m s' m' os
  | CTE_ALoad : forall s m x a ie i,
      eval s ie = i ->
      i < List.length (m a) ->
      cteval (ALoad x a ie) s m (x !-> nth i (m a) 0 ; s) m
        [OALoad a i]
  | CTE_AStore : forall s m a ie i e n,
      eval s e = n ->
      eval s ie = i ->
      i < List.length (m a) ->
      cteval (AStore a ie e) s m s (a !-> upd i (m a) n ; m)
        [OAStore a i].

Hint Constructors cteval : core.
```

这里也再次看出 `ACTIf` 与 `If` 的区别：`ACTIf` 出现在 `eval` 中，赋值规则给它配的观察是 `[]`；`If` 出现在 `cteval` 中，每条执行都额外记录 `OBranch`。所以“秘密值影响 ACTIf 的结果”不等于“秘密值进入观察”。

---

## 110.5 标签、公开等价与 CCT 安全

安全标签只有 `public` 与 `secret`。`label_map` 给变量或数组指定固定标签。布尔相等函数及四条引理连接计算世界与命题世界：`label_eqb_eq` 用于从 `true` 得到相等，`label_eqb_neq` 用于从 `false` 得到不等，`reflect` 版本把两种情况一次包装起来。

```coq
(* ---------- 110.5 标签、公开等价与 CCT 安全 ---------- *)

Inductive label : Type :=
  | public
  | secret.

Definition label_map := total_map label.

Definition label_eqb (l1 l2 : label) : bool :=
  match l1, l2 with
  | public, public | secret, secret => true
  | _, _ => false
  end.

Lemma label_eqb_refl : forall l, label_eqb l l = true.
Proof. intros [|]; reflexivity. Qed.

Lemma label_eqb_eq : forall l1 l2,
  label_eqb l1 l2 = true <-> l1 = l2.
Proof.
  intros [|] [|]; split; intros H; try reflexivity; discriminate H.
Qed.

Lemma label_eqb_spec : forall l1 l2,
  reflect (l1 = l2) (label_eqb l1 l2).
Proof.
  intros [|] [|]; constructor; (reflexivity || discriminate).
Qed.

Lemma label_eqb_neq : forall l1 l2,
  label_eqb l1 l2 = false <-> l1 <> l2.
Proof.
  intros l1 l2. destruct (label_eqb_spec l1 l2) as [Heq | Hneq].
  - split.
    + intros H. discriminate H.
    + intros H. exfalso. apply H. apply Heq.
  - split.
    + intros _. apply Hneq.
    + intros _. reflexivity.
Qed.
```

`pub_equiv L s1 s2` 只要求公开键上的值相等，秘密键可以任意不同。定义对元素类型 `X` 泛化，因此同一个概念既用于自然数状态，也用于列表内存。自反、对称、传递说明它确实是按公开部分定义的等价关系。

```coq
Definition pub_equiv (L : total_map label) {X : Type}
    (s1 s2 : total_map X) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall (X : Type) (L : total_map label)
    (s : total_map X),
  pub_equiv L s s.
Proof. intros X L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall (X : Type) (L : total_map label)
    (s1 s2 : total_map X),
  pub_equiv L s1 s2 ->
  pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros X L s1 s2 H x Px.
  rewrite H; auto.
Qed.

Lemma pub_equiv_trans : forall (X : Type) (L : total_map label)
    (s1 s2 s3 : total_map X),
  pub_equiv L s1 s2 ->
  pub_equiv L s2 s3 ->
  pub_equiv L s1 s3.
Proof.
  unfold pub_equiv. intros X L s1 s2 s3 H12 H23 x Px.
  rewrite H12; try rewrite H23; auto.
Qed.
```

更新引理是非干扰证明的基本工具。若更新的键是秘密键，两边可写不同值，因为公开等价从不询问该键；若两边写入相同值，则无论键的标签是什么都保持公开等价。证明按查询键是否等于更新键分情况，分别使用映射更新定律。

```coq
Lemma pub_equiv_update_secret : forall (X : Type) (L : total_map label)
    (s1 s2 : total_map X) (x : string) (e1 e2 : X),
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Pe y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - rewrite Pe in Py. discriminate.
  - repeat rewrite t_update_neq; auto.
Qed.

Lemma pub_equiv_update_public : forall (X : Type) (L : total_map label)
    (s1 s2 : total_map X) (x : string) (e1 e2 : X),
  pub_equiv L s1 s2 ->
  e1 = e2 ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Eq y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - repeat rewrite t_update_eq; auto.
  - repeat rewrite t_update_neq; auto.
Qed.
```

`cct_secure L LA c` 是比较两次执行的性质。`L` 标记变量，`LA` 标记数组。任意两份公开等价的状态和内存，只要各自能终止执行，观察列表就必须逐元素相同。定义不要求最终秘密值相同，也不要求公开值以外的一切相同；它只约束攻击者可见的轨迹。

```coq
Definition cct_secure (L LA : label_map) (c : com) :=
  forall s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
    pub_equiv L s1 s2 ->
    pub_equiv LA m1 m2 ->
    cteval c s1 m1 s1' m1' os1 ->
    cteval c s2 m2 s2' m2' os2 ->
    os1 = os2.
```

---

## 110.6 安全反例：秘密下标泄露地址

示例标签中 `X`、`Y`、`Z` 公开，其余变量（包括 `V`、`W`）秘密；数组 `AP` 公开，其余数组（包括 `AS`）秘密。两个反例都没有命令分支，却都不安全：`ALoad V AP W` 把秘密下标放进读观察，`AStore AS W 42` 把秘密下标放进写观察。第二个反例尤其说明，**向秘密数组写入并不隐藏地址**；内容标签和地址观察是两个维度。

```coq
(* ---------- 110.6 安全反例：秘密下标泄露地址 ---------- *)

Definition LXYZpub : label_map :=
  (X !-> public ; Y !-> public ; Z !-> public ; __ !-> secret).

Definition LAPpub : label_map :=
  (AP !-> public ; __ !-> secret).

Definition cct_insecure_load : com := ALoad V AP (AId W).
Definition cct_insecure_store : com := AStore AS (AId W) (ANum 42).
```

反证构造两份只在秘密 `W` 上不同的状态：一边下标为 `1`，另一边为 `2`，公开数组完全相同。若程序安全，两条观察 `[OALoad AP 1]` 与 `[OALoad AP 2]` 必须相等，构造子参数不同使 `discriminate` 直接推出矛盾。`pub_equiv_update_secret` 证明初态确实公开等价，`pub_equiv_refl` 证明内存公开等价。

```coq
Example cct_insecure_load_is_not_cct_secure :
  ~ cct_secure LXYZpub LAPpub cct_insecure_load.
Proof.
  unfold cct_secure, cct_insecure_load. intros CTSEC.
  remember (W !-> 1 ; __ !-> 0) as s1.
  remember (W !-> 2 ; __ !-> 0) as s2.
  remember (AP !-> [1 ; 2 ; 3] ; __ !-> []) as m.
  specialize (CTSEC s1 s2 m m).
  assert (Contra : [OALoad AP 1] = [OALoad AP 2]).
  { eapply CTSEC; subst.
    - apply pub_equiv_update_secret; auto.
      apply pub_equiv_refl.
    - apply pub_equiv_refl.
    - eapply CTE_ALoad; simpl; auto.
    - eapply CTE_ALoad; simpl; auto. }
  discriminate.
Qed.
```

存储反例使用同样的两个秘密下标和同一份秘密数组。安全假设会强迫 `[OAStore AS 1] = [OAStore AS 2]`，同样矛盾。这就完整解答了“即使写入秘密数组，为什么仍泄露”的标准练习。

```coq
Example cct_insecure_store_is_not_cct_secure :
  ~ cct_secure LXYZpub LAPpub cct_insecure_store.
Proof.
  unfold cct_secure, cct_insecure_store. intros CTSEC.
  remember (W !-> 1 ; __ !-> 0) as s1.
  remember (W !-> 2 ; __ !-> 0) as s2.
  remember (AS !-> [1 ; 2 ; 3] ; __ !-> []) as m.
  specialize (CTSEC s1 s2 m m).
  assert (Contra : [OAStore AS 1] = [OAStore AS 2]).
  { eapply CTSEC; subst.
    - apply pub_equiv_update_secret; auto.
      apply pub_equiv_refl.
    - apply pub_equiv_refl.
    - eapply CTE_AStore; simpl; auto.
    - eapply CTE_AStore; simpl; auto. }
  discriminate.
Qed.
```

---

## 110.7 表达式与命令的 CCT 类型系统

`join` 是标签上确界：只要一个输入为秘密，结果就是秘密。`join_public` 把“结果为公开”拆成两个公开前提。`can_flow l1 l2` 禁止且只禁止 `secret → public`，允许公开流向任何地方，也允许秘密流向秘密。其两条引理分别提供后续证明需要的目标标签秘密形式和逻辑刻画。

```coq
(* ---------- 110.7 表达式与命令的 CCT 类型系统 ---------- *)

Definition join (l1 l2 : label) : label :=
  match l1 with
  | public => l2
  | secret => secret
  end.

Lemma join_public : forall l1 l2,
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros [|] [|] H; try discriminate H; auto. Qed.

Lemma join_public_l : forall l, join public l = l.
Proof. reflexivity. Qed.

Definition can_flow (l1 l2 : label) : bool :=
  match l1, l2 with
  | secret, public => false
  | _, _ => true
  end.

Lemma can_flow_secret_l : forall l,
  can_flow secret l = true -> l = secret.
Proof.
  intros l H. destruct l.
  - discriminate H.
  - reflexivity.
Qed.

Lemma can_flow_true_iff : forall l1 l2,
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2.
      * discriminate H.
      * reflexivity.
  - intros [H | H]; subst.
    + reflexivity.
    + destruct l1; reflexivity.
Qed.
```

表达式标签规则是：

- 常数公开；变量继承 `L x`；
- 二元运算结果连接两个子表达式的标签；
- `ACTIf` 的结果连接条件与两个分支的标签。

`ACTIf` 不产生观察，所以它的**条件不必公开**；但秘密条件可以影响结果，因此结果必须带秘密标签。换言之，类型系统允许秘密数据流，不允许它随后进入公开变量、命令条件或数组下标。

```coq
Inductive exp_has_label (L : label_map) : exp -> label -> Prop :=
  | T_Num : forall n,
      exp_has_label L (ANum n) public
  | T_Id : forall x,
      exp_has_label L (AId x) (L x)
  | T_Bin : forall op e1 l1 e2 l2,
      exp_has_label L e1 l1 ->
      exp_has_label L e2 l2 ->
      exp_has_label L (ABin op e1 e2) (join l1 l2)
  | T_CTIf : forall be l e1 l1 e2 l2,
      exp_has_label L be l ->
      exp_has_label L e1 l1 ->
      exp_has_label L e2 l2 ->
      exp_has_label L (ACTIf be e1 e2) (join l (join l1 l2)).

Hint Constructors exp_has_label : core.
```

表达式非干扰定理说：公开标签表达式在公开等价状态下求值相同。证明对类型推导归纳。常数直接相等；变量由公开等价得到；二元运算和 `ACTIf` 先用 `join_public` 把所有组成标签拆成公开，再分别使用归纳假设重写。`remember public as l` 保留“最终标签为公开”这一可归纳使用的等式。

```coq
Theorem noninterferent_exp : forall {L s1 s2 e},
  pub_equiv L s1 s2 ->
  exp_has_label L e public ->
  eval s1 e = eval s2 e.
Proof.
  intros L s1 s2 e Heq Ht. remember public as l.
  generalize dependent Heql.
  induction Ht; simpl; intros.
  - reflexivity.
  - eapply Heq; auto.
  - eapply join_public in Heql.
    destruct Heql as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2; reflexivity.
  - eapply join_public in Heql.
    destruct Heql as [HP HP']. subst.
    eapply join_public in HP'.
    destruct HP' as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2, IHHt3; reflexivity.
Qed.
```

命令规则把数据流限制与观察限制分开：

- `Skip` 总良类型；`Seq` 要求两段都良类型。
- 赋值要求表达式标签可以流向目标变量标签。
- `If`、`While` 的条件必须为公开，因为每次判断都产生观察；分支体或循环体继续检查。
- 数组加载的下标必须公开，同时数组内容标签必须能流向目标变量。
- 数组存储的下标必须公开，同时待写值必须能流向数组内容标签。

注意，从公开数组加载公开下标仍可能把值送入秘密变量；从秘密数组加载则只能送入秘密变量。地址与内容分别受到约束。

```coq
Inductive cct_well_typed (L LA : label_map) : com -> Prop :=
  | CCT_Skip :
      cct_well_typed L LA Skip
  | CCT_Asgn : forall x e l,
      exp_has_label L e l ->
      can_flow l (L x) = true ->
      cct_well_typed L LA (Asgn x e)
  | CCT_Seq : forall c1 c2,
      cct_well_typed L LA c1 ->
      cct_well_typed L LA c2 ->
      cct_well_typed L LA (Seq c1 c2)
  | CCT_If : forall b c1 c2,
      exp_has_label L b public ->
      cct_well_typed L LA c1 ->
      cct_well_typed L LA c2 ->
      cct_well_typed L LA (If b c1 c2)
  | CCT_While : forall b c1,
      exp_has_label L b public ->
      cct_well_typed L LA c1 ->
      cct_well_typed L LA (While b c1)
  | CCT_ALoad : forall x a i,
      exp_has_label L i public ->
      can_flow (LA a) (L x) = true ->
      cct_well_typed L LA (ALoad x a i)
  | CCT_AStore : forall a i e l,
      exp_has_label L i public ->
      exp_has_label L e l ->
      can_flow l (LA a) = true ->
      cct_well_typed L LA (AStore a i e).

Hint Constructors cct_well_typed : core.
```

---

## 110.8 可执行检查器及其可靠性与完备性

`label_of_exp` 直接按表达式语法计算标签。可靠性引理说明计算出的标签确实可由类型规则推出；唯一性引理说明任何可推导标签都等于这个计算结果。后者用于检查器的反向论证：不存在另一套更宽松推导绕过布尔检查。

```coq
(* ---------- 110.8 可执行检查器及其可靠性与完备性 ---------- *)

Fixpoint label_of_exp (L : label_map) (e : exp) : label :=
  match e with
  | ANum n => public
  | AId x => L x
  | ABin _ e1 e2 => join (label_of_exp L e1) (label_of_exp L e2)
  | ACTIf be e1 e2 =>
      join (label_of_exp L be)
        (join (label_of_exp L e1) (label_of_exp L e2))
  end.

Lemma label_of_exp_sound : forall L e,
  exp_has_label L e (label_of_exp L e).
Proof. intros L e. induction e; constructor; eauto. Qed.

Lemma label_of_exp_unique : forall L e l,
  exp_has_label L e l ->
  l = label_of_exp L e.
Proof.
  intros L e l H.
  induction H; simpl in *; subst; auto.
Qed.
```

命令检查器逐条翻译类型规则。`&&` 表示所有前提都必须通过；公开条件或公开下标通过 `label_eqb ... public` 检查；赋值、加载、存储用 `can_flow` 检查内容流。由于表达式标签和命令语法都是有限结构，这个函数总能计算。

```coq
Fixpoint cct_typechecker (L LA : label_map) (c : com) : bool :=
  match c with
  | Skip => true
  | Asgn x e => can_flow (label_of_exp L e) (L x)
  | Seq c1 c2 => cct_typechecker L LA c1 && cct_typechecker L LA c2
  | If b c1 c2 =>
      label_eqb (label_of_exp L b) public &&
      cct_typechecker L LA c1 && cct_typechecker L LA c2
  | While b c1 =>
      label_eqb (label_of_exp L b) public && cct_typechecker L LA c1
  | ALoad x a i =>
      label_eqb (label_of_exp L i) public && can_flow (LA a) (L x)
  | AStore a i e =>
      label_eqb (label_of_exp L i) public &&
      can_flow (label_of_exp L e) (LA a)
  end.
```

可靠性证明对命令结构归纳，用 `andb_true_iff` 拆分合取，再将布尔标签相等变成命题相等，最后应用对应构造子和 `label_of_exp_sound`。完备性采用逆否形式：若检查器返回 `false`，假设存在类型推导，对推导归纳，`andb_false_iff` 给出失败子项，标签唯一性与归纳假设导致矛盾。因此这里的 `complete` 是“拒绝即不可类型化”，与可靠性合起来说明布尔结果精确对应类型系统。

```coq
Theorem cct_typechecker_sound : forall L LA c,
  cct_typechecker L LA c = true ->
  cct_well_typed L LA c.
Proof.
  intros L LA c. induction c; simpl in *; econstructor;
    try rewrite andb_true_iff in *; try tauto;
    eauto using label_of_exp_sound.
  - destruct H as [H1 H2].
    rewrite andb_true_iff in H1; try tauto.
    destruct H1 as [H11 H12]. apply label_eqb_eq in H11.
    rewrite <- H11. apply label_of_exp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; tauto.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. apply label_of_exp_sound.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. eapply label_of_exp_sound.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. eapply label_of_exp_sound.
  - destruct H as [H1 H2]. auto.
Qed.

Theorem cct_typechecker_complete : forall L LA c,
  cct_typechecker L LA c = false ->
  ~ cct_well_typed L LA c.
Proof.
  intros L LA c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *;
    try tauto; try congruence.
  - apply label_of_exp_unique in H0.
    subst. congruence.
  - destruct H; eauto. rewrite andb_false_iff in H.
    destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_exp_unique in H0. congruence.
  - destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_exp_unique in H0. congruence.
  - destruct H; eauto; try congruence.
    rewrite label_eqb_neq in H.
    apply label_of_exp_unique in H0. congruence.
  - destruct H; eauto.
    + rewrite label_eqb_neq in H.
      apply label_of_exp_unique in H0. congruence.
    + apply label_of_exp_unique in H1.
      subst. congruence.
Qed.
```

两个秘密下标程序都能由计算直接判定为不可类型化：它们的 `W` 标签为秘密，而下标检查要求公开。这与前面的语义反例相互印证：不仅能举出攻击输入，静态检查器也确实会拒绝。

```coq
Theorem cct_insecure_load_ill_typed :
  ~ cct_well_typed LXYZpub LAPpub cct_insecure_load.
Proof. apply cct_typechecker_complete. reflexivity. Qed.

Theorem cct_insecure_store_ill_typed :
  ~ cct_well_typed LXYZpub LAPpub cct_insecure_store.
Proof. apply cct_typechecker_complete. reflexivity. Qed.
```

---

## 110.9 状态与内存非干扰

主安全证明还需要一个独立不变量：良类型程序从公开等价输入出发，终止后的公开状态和公开内存仍等价。这个引理不比较观察，而是保证程序内部公开数据不会被秘密污染。

证明对左侧执行归纳，同时反演右侧执行和类型推导。各情形形成如下链条：

1. 空命令保持两个公开等价假设。
2. 公开表达式在两边求值相同，用 `pub_equiv_update_public`；秘密表达式只能写入秘密目标，用 `pub_equiv_update_secret`。
3. 顺序命令先把第一段归纳假设得到的中间状态/内存公开等价，喂给第二段归纳假设。
4. 公开分支条件经 `noninterferent_exp` 求值相同，所以两边进入同一分支，再使用执行归纳假设；循环展开复用同一论证。
5. 加载的公开下标相同。公开数组在两份内存中内容相同，因此读出值相同；秘密数组只能写秘密目标，允许读出值不同。
6. 存储的公开下标相同。写公开数组时，值表达式必为公开且数组原本公开等价；写秘密数组时用秘密更新引理，其他公开数组不受影响。

```coq
(* ---------- 110.9 状态与内存非干扰 ---------- *)

Lemma cct_well_typed_noninterferent :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
  cct_well_typed L LA c ->
  pub_equiv L s1 s2 ->
  pub_equiv LA m1 m2 ->
  cteval c s1 m1 s1' m1' os1 ->
  cteval c s2 m2 s2' m2' os2 ->
  pub_equiv L s1' s2' /\ pub_equiv LA m1' m2'.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Hwt Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1;
    intros os2' m2 Haeq m2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - split; auto.
  - split; auto. destruct l.
    + rewrite (noninterferent_exp Heq H10).
      eapply pub_equiv_update_public; auto.
    + apply can_flow_secret_l in H11.
      eapply pub_equiv_update_secret; auto.
  - edestruct IHHeval1_2; eauto.
    + eapply IHHeval1_1; eauto.
    + eapply IHHeval1_1; eauto.
  - eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4.
      rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - split; eauto.
    erewrite noninterferent_exp; eauto.
    destruct (LA a) eqn:LAa.
    + eapply pub_equiv_update_public; auto.
      eapply Haeq in LAa. rewrite LAa. reflexivity.
    + apply can_flow_secret_l in H15.
      eapply pub_equiv_update_secret; auto.
  - split; eauto.
    destruct (LA a) eqn:LAa; simpl in *.
    + eapply Haeq in LAa. rewrite LAa.
      destruct l; [| discriminate].
      eapply pub_equiv_update_public; auto.
      repeat erewrite (noninterferent_exp Heq); auto.
    + eapply pub_equiv_update_secret; auto.
Qed.
```

---

## 110.10 主定理：良类型程序观察不依赖秘密

`cct_well_typed_secure` 把类型规则、表达式非干扰和状态/内存非干扰组合成最终的 CCT 安全。证明同样对左侧执行归纳，并反演右侧执行与类型推导：

- 空命令与赋值观察均为空，直接相等。
- 顺序执行先用第一段归纳假设得到 `os1` 相等，再用第一段的状态/内存非干扰建立第二段所需的公开等价，最后由第二段归纳假设得到 `os2` 相等。
- 条件命令的公开条件求值相同，因此首个 `OBranch` 相同且进入同一分支；尾部由归纳假设相等。循环通过展开归结到这一情形。
- 加载和存储的数组名来自同一程序，公开下标经表达式非干扰相同，所以单个地址观察相同。

因此完整证明链是：**公开表达式求值一致 → 公开状态与内存保持一致 → 分支选择和地址一致 → 整段观察轨迹一致**。

```coq
(* ---------- 110.10 主定理：良类型程序观察不依赖秘密 ---------- *)

Theorem cct_well_typed_secure : forall L LA c,
  cct_well_typed L LA c ->
  cct_secure L LA c.
Proof.
  unfold cct_secure.
  intros L LA c Hwt s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1; intros os2' a2 Haeq a2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - erewrite IHHeval1_2; [erewrite IHHeval1_1 | | | |];
      try reflexivity; try eassumption.
    + eapply cct_well_typed_noninterferent with (c := c1); eauto.
    + eapply cct_well_typed_noninterferent with (c := c1); eauto.
  - rewrite (noninterferent_exp Heq H11).
    f_equal; auto. eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4.
      rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
Qed.
```

---

## 110.11 标准练习：修复秘密分支

反例根据秘密 `W=0` 决定把 `42` 还是原值写入 `V`。空分支写成 `Asgn V (AId V)`，它与原书的 `skip` 在输入输出功能上相同，同时让两条路径都产生相同的函数式状态更新形状；这样后面的“同一最终状态”结论不需要函数外延公理。反例仍产生依赖秘密的 `OBranch`，所以检查器拒绝。

修复程序只有一次赋值：`ACTIf` 在表达式内部选择 `42` 或 `V` 的旧值。秘密条件使结果标签为秘密，而 `V` 恰好是秘密变量，因此赋值合法；整个命令没有 `If`，观察为空。

```coq
(* ---------- 110.11 标准练习：修复秘密分支 ---------- *)

Definition cct_insecure_branch : com :=
  If (BEq (AId W) (ANum 0)) (Asgn V (ANum 42)) (Asgn V (AId V)).

Definition cct_fixed_branch : com :=
  Asgn V (ACTIf (BEq (AId W) (ANum 0)) (ANum 42) (AId V)).

Theorem cct_insecure_branch_ill_typed :
  ~ cct_well_typed LXYZpub LAPpub cct_insecure_branch.
Proof. apply cct_typechecker_complete. reflexivity. Qed.

Lemma cct_fixed_branch_well_typed :
  cct_typechecker LXYZpub LAPpub cct_fixed_branch = true.
Proof. reflexivity. Qed.
```

安全性不重新手工证明：检查器计算为 `true`，可靠性给出类型推导，主定理立即给出 `cct_secure`。这正是类型系统的复用价值。

```coq
Corollary cct_fixed_branch_secure :
  cct_secure LXYZpub LAPpub cct_fixed_branch.
Proof.
  apply cct_well_typed_secure. apply cct_typechecker_sound.
  apply cct_fixed_branch_well_typed.
Qed.
```

正确性也不能只看“通过检查”。`cct_fixed_branch_equiv` 反演原命令，按秘密条件的值分两种情况：零时两边都写 `42`，非零时两边都写旧的 `V`，最终状态与内存相同，只有观察允许不同。最后的 `spec` 将“检查器接受”和“功能等价”合并，防止把一个安全但算错结果的程序当成修复。

```coq
Lemma cct_fixed_branch_equiv : forall s m s' m' os,
  cteval cct_insecure_branch s m s' m' os ->
  exists os', cteval cct_fixed_branch s m s' m' os'.
Proof.
  intros s m s' m' os H.
  inversion H; subst.
  destruct (eval s (BEq (AId W) (ANum 0))) eqn:Hw; simpl in *;
    match goal with
    | Hbody : cteval _ _ _ _ _ _ |- _ => inversion Hbody; subst
    end;
    eexists; eapply CTE_Asgn; simpl; rewrite Hw; reflexivity.
Qed.

Lemma cct_fixed_branch_spec :
  cct_typechecker LXYZpub LAPpub cct_fixed_branch = true /\
  (forall s m s' m' os,
    cteval cct_insecure_branch s m s' m' os ->
    exists os', cteval cct_fixed_branch s m s' m' os').
Proof.
  split.
  - apply cct_fixed_branch_well_typed.
  - apply cct_fixed_branch_equiv.
Qed.
```

---

## 110.12 标准练习：公开扫描修复秘密加载

仅假设 `AP` 长度为二时，可以先以公开常量下标读取 `AP[0]`、`AP[1]` 到公开临时变量 `X`、`Y`，再用秘密 `W=0` 的 `ACTIf` 选择目标值写入秘密变量 `V`。观察固定为加载地址 `0`、加载地址 `1`，不再包含 `W`。内存不变，临时变量允许改变。

```coq
(* ---------- 110.12 标准练习：公开扫描修复秘密加载 ---------- *)

Definition cct_fixed_load : com :=
  Seq (ALoad X AP (ANum 0))
    (Seq (ALoad Y AP (ANum 1))
      (Asgn V (ACTIf (BEq (AId W) (ANum 0)) (AId X) (AId Y)))).

Lemma cct_fixed_load_well_typed :
  cct_typechecker LXYZpub LAPpub cct_fixed_load = true.
Proof. reflexivity. Qed.
```

与分支修复相同，安全性由“检查器可靠 + 主定理”得到。固定地址序列与秘密无关，但修复是否算出原加载的值仍需单独证明。

```coq
Corollary cct_fixed_load_secure :
  cct_secure LXYZpub LAPpub cct_fixed_load.
Proof.
  apply cct_well_typed_secure. apply cct_typechecker_sound.
  apply cct_fixed_load_well_typed.
Qed.
```

正确性证明先反演秘密加载，并用 `m AP=[a0;a1]` 把界内条件变成 `s W < 2`。自然数分情况只有 `0`、`1` 和至少为 `2` 三类；最后一类由 `lia` 排除。前两类各构造三段执行：显式指定加载下标避免自动化留下不确定项，用长度假设证明边界，再由赋值规则执行 `ACTIf`。最后重写秘密下标和数组内容，左边分别得到 `a0` 或 `a1`，与原加载的 `V` 值一致。

```coq
Lemma cct_fixed_load_correct : forall s m a0 a1 s' os,
  m AP = [a0 ; a1] ->
  cteval cct_insecure_load s m s' m os ->
  exists s'' os',
    cteval cct_fixed_load s m s'' m os' /\
    s'' V = s' V.
Proof.
  intros s m a0 a1 s' os Hm H.
  inversion H; subst. rewrite Hm in *. simpl in *.
  destruct (s W) as [| [| i]] eqn:Hw; simpl in *; try lia.
  - eexists. eexists. split.
    + eapply CTE_Seq.
      * eapply CTE_ALoad with (i := 0); simpl; auto; rewrite Hm; simpl; lia.
      * eapply CTE_Seq.
        -- eapply CTE_ALoad with (i := 1); simpl; auto; rewrite Hm; simpl; lia.
        -- eapply CTE_Asgn. simpl. reflexivity.
    + unfold t_update. simpl. rewrite Hw. simpl. rewrite Hm. reflexivity.
  - eexists. eexists. split.
    + eapply CTE_Seq.
      * eapply CTE_ALoad with (i := 0); simpl; auto; rewrite Hm; simpl; lia.
      * eapply CTE_Seq.
        -- eapply CTE_ALoad with (i := 1); simpl; auto; rewrite Hm; simpl; lia.
        -- eapply CTE_Asgn. simpl. reflexivity.
    + unfold t_update. simpl. rewrite Hw. simpl. rewrite Hm. reflexivity.
Qed.
```

最终练习规格再次把静态接受和功能正确性合取。扫描展示了常时数组查询的基本思想，但成本随数组长度增长；大型 S 盒等实际实现通常还需要向量化、位切片或避免秘密下标访问，而不是盲目复制这个二元素示例。

```coq
Lemma cct_fixed_load_spec :
  cct_typechecker LXYZpub LAPpub cct_fixed_load = true /\
  (forall s m a0 a1 s' os,
    m AP = [a0 ; a1] ->
    cteval cct_insecure_load s m s' m os ->
    exists s'' os',
      cteval cct_fixed_load s m s'' m os' /\
      s'' V = s' V).
Proof.
  split.
  - apply cct_fixed_load_well_typed.
  - apply cct_fixed_load_correct.
Qed.

End Ex110ConstantTime.
```

## 小结：常时不是“常量秒数”，而是秘密不进入观察

本章的形式化结论有意精确而克制。它证明的是：在本章分支与数组地址泄露模型下，良类型程序对公开等价输入产生相同观察。它没有声称所有真实处理器指令都固定延迟，也没有建模缓存大小或推测执行。若加入可变时延除法，可同样增加携带两个操作数的观察，并在类型规则中要求两个操作数公开；安全证明会复用 `noninterferent_exp`。核心方法不变：先明确攻击者观察什么，再用类型规则阻止秘密流入这些观察点。
