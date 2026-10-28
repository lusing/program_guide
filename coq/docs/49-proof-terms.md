# 49 · 证明即项：Curry–Howard 落地

对应示例：`../examples/49_proof_terms.v`

前 48 章里，「写程序」和「证定理」看起来是两套动作：程序用 `Definition`/`Fixpoint`，定理用 `Theorem ... Proof ... Qed`。本章把它们焊死：**命题就是类型，证明就是程序**。tactic 脚本只是脚手架，`Qed` 时刻落进环境的是一个普通项，内核像检查任何项一样检查它。素材取自 Software Foundations 的《ProofObjects》一章，全部结论按本机 rocq 9.3.0 实测重跑，无需翻阅原书。

文件开头四行是全章的地基：

```coq
(* 34 证明即项：Curry–Howard 落地 —— 命题是类型，证明是程序 *)

From Stdlib Require Import Arith List.
From Stdlib Require Import FunctionalExtensionality ProofIrrelevance.
Import ListNotations.

Module Ex49ProofTerms.
```

第二条 `Require` 比往常早：49.10 要用标准库的公理模块做实测，`Require` 写在这里就是提醒读者——**公理从导入那一刻就进了环境**，后面每个 `Print Assumptions` 都会看到它们。全文件包在 `Module Ex49ProofTerms.` 里，与前面各章同规格。

### 49.1 证据是数据

用 15 章的老朋友 `ev`（这里改用 SF 的命名）：

```coq
(* ---------- 49.1 ev：证据是数据 ---------- *)

Inductive ev : nat -> Prop :=
  | ev_0 : ev 0
  | ev_SS (n : nat) (H : ev n) : ev (S (S n)).
```

盯住第二行构造子的类型看：`ev_SS` 吃一个数 `n` 和一份 `ev n` 的证据，吐出一份 `ev (S (S n))` 的证据——这就是一个**函数的签名**。`ev_0` 是零参函数（常量）。`: ` 在这里有两种读法：「`ev_0` 有类型 `ev 0`」，或者「`ev_0` 是 `ev 0` 的证明」。这个双关就是 Curry–Howard 对应：

```text
命题（propositions） ~ 类型（types）
证明（proofs）       ~ 程序（programs）
```

证一个命题，就是**构造一个属于该类型的项**。先照 15 章的方式用 tactic 证 `ev 4`，然后 `Print` 看Qed留下了什么：

```coq
Theorem ev_4 : ev 4.
Proof.
  apply ev_SS. apply ev_SS. apply ev_0.
Qed.

Print ev_4.
```

9.3 实测输出：

```text
ev_4 = ev_SS 2 (ev_SS 0 ev_0)
     : ev 4
```

不是战术记录，是一个**项**：`ev_SS 2 (ev_SS 0 ev_0)`——「2 是偶数」的证据套两层 `ev_SS` 得到「4 是偶数」的证据，树的最底下是 `ev_0`。既然项可以直接写，tactic 就不是必需品——手工构造同一个项：

```coq
Check (ev_SS 2 (ev_SS 0 ev_0) : ev 4).
```

实测输出 `ev_SS 2 (ev_SS 0 ev_0) : ev 4`（第二行 `: ev 4` 是它所在的类型层）。同一句话，`:` 既读「有类型」也读「是证明」：**命题 = 类型，证明 = 该类型的一个项**，落地成了可以 `Check` 的代码。

### 49.2 Proof/Qed 内部在干什么

`Proof ... Qed` 期间，内核其实在**逐步填一个带洞的项**。`Show Proof.` 把中途状态打出来：

```coq
(* ---------- 49.2 Proof/Qed 内部：填洞 ---------- *)

Theorem ev_4s : ev 4.
Proof.
  Show Proof.
  apply ev_SS.
  Show Proof.
  apply ev_SS.
  Show Proof.
  apply ev_0.
  Show Proof.
Qed.
```

四次 `Show Proof.` 的实测输出（依次）：

```text
?Goal
(ev_SS 2 ?Goal)
(ev_SS 2 (ev_SS 0 ?Goal))
(ev_SS 2 (ev_SS 0 ev_0))
```

一开始只有一个洞 `?Goal`；`apply ev_SS` 把洞换成 `ev_SS 2 ?Goal`——**每个子目标对应一个洞**，洞里还带着待填的元变量（参数 `n` 先猜成 2）。每步 tactic 都在改写这棵带洞的树；`Qed` 的充要条件是洞全部消失，此时项被保存、内核从头做类型检查。

四种写法殊途同归——tactic 分步、`apply` 一整坨项、干脆用 `Definition :=`：

```coq
Theorem ev_4a : ev 4.
Proof.
  apply (ev_SS 2 (ev_SS 0 ev_0)).
Qed.

Definition ev_4d : ev 4 := ev_SS 2 (ev_SS 0 ev_0).

Print ev_4s.
Print ev_4a.
Print ev_4d.
```

三个 `Print` 实测全部输出等号右边一样的项：

```text
ev_4s = ev_SS 2 (ev_SS 0 ev_0)
     : ev 4
ev_4a = ev_SS 2 (ev_SS 0 ev_0)
     : ev 4
ev_4d = ev_SS 2 (ev_SS 0 ev_0)
     : ev 4
```

环境里存的是**项**，不是脚本。反过来，项拼错了会被当场拒绝——拿一个类型不对的证据喂 `ev_SS`：

```coq
Fail Check (ev_SS 2 ev_0 : ev 4).
```

剥掉 `Fail` 实测（方法：/tmp 副本上直接 `rocq compile`），9.3 的真实报错：

```text
The term "ev_0" has type "ev 0" while it is expected to have type
"ev 2".
```

`ev_SS 2` 索要的是 `ev 2` 的证据，`ev_0` 只能证明 `ev 0`——内核只看项的形状与类型，不问你从哪抄来的。

### 49.3 forall 与 -> 就是函数

箭头和量词在证据世界里的身份同样是函数。先 tactic 版：

```coq
(* ---------- 49.3 forall 与 -> 就是函数 ---------- *)

Theorem ev_plus4 : forall n, ev n -> ev (4 + n).
Proof.
  intros n H. simpl.
  apply ev_SS. apply ev_SS. apply H.
Qed.

Print ev_plus4.
```

`Print` 实测输出（末尾 `Arguments` 行是参数作用域信息，不是报错）：

```text
ev_plus4 =
fun (n : nat) (H : ev n) => ev_SS (S (S n)) (ev_SS n H) : ev (4 + n)
     : forall n : nat, ev n -> ev (4 + n)

Arguments ev_plus4 n%_nat_scope _
```

证出的「定理」本体是一个**两参数函数**：给一个数 `n` 和一份 `ev n` 的证据，返回一份 `ev (4 + n)` 的证据。手写同款（`simpl` 那步直接把 `4 + n` 写成 `S (S (S (S n)))` 的形状）：

```coq
Definition ev_plus4' : forall n, ev n -> ev (4 + n) :=
  fun n => fun (H : ev n) => ev_SS (S (S n)) (ev_SS n H).

Definition ev_plus4'' (n : nat) (H : ev n) : ev (4 + n) :=
  ev_SS (S (S n)) (ev_SS n H).

Check (ev_plus4'' : forall n : nat, ev n -> ev (4 + n)).
```

`ev_plus4''` 把两个参数提到冒号前——声明完参数，结论类型 `ev (4 + n)` 里可以回看它们；`Check` 实测确认它的类型就是 `forall n : nat, ev n -> ev (4 + n)`。函数视角下有个值得停下的点：**第二个参数的类型 `ev n` 里带着第一个参数的值 `n`**。普通语言里参数类型不能依赖另一个参数的值，这里可以——这就是 26 章反复出现的**依赖类型**；你写 `ev n -> ev (4 + n)` 时早就在用过了。

`forall` 和 `->` 其实是同一个东西的两副面孔。把同一命题写三遍：

```coq
Definition ev_plus2 : Prop := forall n, forall (E : ev n), ev (n + 2).
Definition ev_plus2' : Prop := forall n, forall (_ : ev n), ev (n + 2).
Definition ev_plus2'' : Prop := forall n, ev n -> ev (n + 2).
```

三条完全等价：参数名后面用不到就换 `_`，连 `_` 都嫌烦就塌缩成 `->`。一句话：**`P -> Q` 是 `forall (_ : P), Q` 的语法糖**——非依赖的 forall。蕴含和量词在证明里都是函数，`intros` 就是「开始写 fun」，`apply` 就是函数调用。

### 49.4 用策略写程序

既然证明项可以由 tactic 攒出来，普通程序也可以。注意末尾是 `.` 不是 `:=`——冒号后面不给定义体，就进入证明模式，让策略把「 nat -> nat 这个类型的项」造出来：

```coq
(* ---------- 49.4 用策略写程序 ---------- *)

Definition add2 : nat -> nat.
Proof.
  intros n.
  Show Proof.
  apply S.
  apply S.
  exact n.
Defined.

Print add2.
Compute (add2 2).
```

`Show Proof.` 实测打出 `(fun n : nat => ?Goal)`；收尾后：

```text
add2 = fun n : nat => S (S n)
     : nat -> nat

Arguments add2 _%_nat_scope
     = 4
     : nat
```

（最后两行是 `Compute (add2 2).` 的输出。）关键在 `Defined.`：它让定义**透明**，`Compute` 能展开。换个收尾方式试试：

```coq
Definition add2o : nat -> nat.
Proof.
  intros n. apply S. apply S. exact n.
Qed.

Compute (add2o 2).
Fail Check (eq_refl 4 : add2o 2 = 4).
```

`Compute (add2o 2).` 实测输出 `= add2o 2`——**展不开了**：`Qed` 把定义封成黑盒（opaque），计算时不许掀盖。连等式自检都过不了，`Fail Check` 那行剥掉 Fail 实测报错：

```text
The term "eq_refl" has type "4 = 4" while it is expected to have type
"add2o 2 = 4".
```

`eq_refl` 靠可转换性（convertibility，就是 `Compute` 那套化简规则）判定 `4` 和 `add2o 2` 相同，而 opaque 的 `add2o` 化不开。这正是 26 章「证定理用 Qed，造函数用 Defined」的机理版：**Qed/Defined 的区别不在逻辑，在计算时能否展开**。用策略造程序的场合主要是类型复杂到手写项费劲的依赖类型函数——本章只是证明这条路通。

### 49.5 逻辑连接词都是归纳类型

`Prod` 先行：元组大家熟（6 章），看看它的真身：

```coq
(* ---------- 49.5 连接词是归纳类型 ---------- *)

Print prod.
```

实测输出：

```text
Inductive prod (A B : Type) : Type :=  pair : A -> B -> A * B.

Arguments prod (A B)%_type_scope
Arguments pair {A B}%_type_scope _ _
```

逻辑连接词不过是把 `Type` 换成 `Prop` 的同款归纳定义。亲手写一份（照 SF 的做法放进子模块，只演示形状，不动标准库记号）：

```coq
Module MyProps.

Inductive and (P Q : Prop) : Prop :=
  | conj : P -> Q -> and P Q.

Inductive or (P Q : Prop) : Prop :=
  | or_introl : P -> or P Q
  | or_intror : Q -> or P Q.

Inductive ex {A : Type} (P : A -> Prop) : Prop :=
  | ex_intro : forall x : A, P x -> ex P.

Inductive True : Prop := I : True.

Inductive False : Prop := .

End MyProps.
```

并排看数据版与命题版：

| 命题版（Prop） | 构造子 | 数据版（Type） | 关系 |
|---|---|---|---|
| `and P Q`（`/\`） | `conj` | `prod A B`（`*`、`pair`） | 形状全同，参数住 Prop |
| `or P Q`（`\/`） | `or_introl` / `or_intror` | `sum A B`（`+`、`inl`/`inr`） | 二选一打包 |
| `ex P`（`exists`） | `ex_intro`（证人+证据） | `sig`/依赖对（26 章） | 依赖版打包 |
| `True` | 单构造子 `I` | 单元类型（`tt`） | 只有一份证据 |
| `False` | **无构造子** | 空类型（7 章的 Empty_set） | 证不出来 |

`ex` 那条要多看一眼：`P` 是「从证人到命题」的**函数**，`ex_intro` 把证人 `x` 和证据打包——`exists` 就是依赖版 `sig` 住在 Prop 里。注意一点实测行为：在 `MyProps` 里重写 `and`/`or` 后，`/\`、`\/` 这些**记号仍指向标准库**（记号绑定时已写死全名），所以子模块只作解剖标本，下面的项式证明照常使用标准构造子。这些定义解释了第 14 章表格里每个策略的真身：`destruct`/`split`/`left`/`right`/`exists` 全是 match 与构造子的包装。项式重写几条经典：

```coq
Definition proj1'' P Q (HPQ : P /\ Q) : P :=
  match HPQ with
  | conj HP HQ => HP
  end.

Definition and_comm'_aux P Q (H : P /\ Q) : Q /\ P :=
  match H with
  | conj HP HQ => conj HQ HP
  end.

Definition and_comm' P Q : P /\ Q <-> Q /\ P :=
  conj (and_comm'_aux P Q) (and_comm'_aux Q P).

Definition inj_l : forall (P Q : Prop), P -> P \/ Q :=
  fun P Q HP => or_introl HP.

Definition or_elim : forall (P Q R : Prop), (P \/ Q) -> (P -> R) -> (Q -> R) -> R :=
  fun P Q R HPQ HPR HQR =>
    match HPQ with
    | or_introl HP => HPR HP
    | or_intror HQ => HQR HQ
    end.

Definition some_nat_is_even : exists n : nat, ev n :=
  ex_intro ev 4 (ev_SS 2 (ev_SS 0 ev_0)).

Definition dist_exists_or_term (X : Type) (P Q : X -> Prop) :
  (exists x : X, P x \/ Q x) -> (exists x : X, P x) \/ (exists x : X, Q x) :=
  fun H => match H with
           | ex_intro _ x Hx =>
               match Hx with
               | or_introl HPx => or_introl (ex_intro _ x HPx)
               | or_intror HQx => or_intror (ex_intro _ x HQx)
               end
           end.
```

逐个读：`proj1''` 对 `conj` 做 match——`destruct` 拆合取的本体；`and_comm'` 连 tactic 都不用，`<->` 本就是双向合取，`conj` 把两个方向的函数打包（`and_comm'_aux` 就是交换的 match 版）；`inj_l` 是 `left` 的裸形；`or_elim` 是「分情况证明」的函数形态——对 `or` 证据做双分支 match，每支把子证据喂给对应的方向；`some_nat_is_even` 把证人 `4` 和 49.1 那棵证据树一起塞进 `ex_intro`；`dist_exists_or_term` 是嵌套 match：外层 `ex_intro _ x Hx` 拆出证人与性质证据，内层对 `Hx : P x \/ Q x` 分情况，再把证人重新打包进对应一侧。

### 49.6 True、False 与爆炸原理

`MyProps` 里最后两行才是主角：`Inductive True : Prop := I : True.` 一个构造子——所有证据长得一样，拿到 `True` 的证据等于没拿到信息；`Inductive False : Prop := .` 零个构造子——**没有任何途径**造出它的项。所以想直接交付 `False` 纯属做梦，实测：

```coq
(* ---------- 49.6 True、False 与爆炸原理 ---------- *)

Fail Definition contra : False := 42.
```

剥掉 Fail 的真实报错：

```text
The term "42" has type "nat" while it is expected to have type "False".
```

但反过来，**拆** `False` 毫无阻力：它没有构造子，match 就不需要任何分支——空 match 天然穷尽，因而可以拥有任意类型：

```coq
Definition false_implies_zero_eq_one : False -> 0 = 1 :=
  fun contra => match contra with end.

Definition ex_falso_quodlibet' : forall P : Prop, False -> P :=
  fun P contra => match contra with end.
```

「0 = 1」也好、任意命题 `P` 也好，一个空 match 全接住。看起来危险，其实安全得很：这个 match **永远不会被求值**——没人能造出 `False` 的项来喂它，除非你上下文里本来就有矛盾。这就是爆炸原理（ex falso quodlibet）的项式真身：13 章 `discriminate`、14 章 `contradiction` 关掉的目标，内核层面都是把 `False` 证据递进空 match。

### 49.7 等号也是归纳出来的

等号连标准库都不算原件，是归纳类型。自造一份玩（SF 同款，进子模块避免动真身）：

```coq
(* ---------- 49.7 等号也是归纳出来的 ---------- *)

Module EqPlay.

Inductive eq {X : Type} : X -> X -> Prop :=
  | eq_refl : forall x, eq x x.

Notation "x == y" := (eq x y)
  (at level 70, no associativity) : type_scope.
```

读法：给定类型 `X`，`==` 是「以 X 的元素对为指标」的命题族；造证据只有一条路——`eq_refl`，它只能证「x 和自己相等」。那么 `2 + 2 == 1 + 3` 这种「不是长得一样」的等式呢？

```coq
Lemma four : 2 + 2 == 1 + 3.
Proof.
  apply eq_refl.
Qed.

Print four.

Definition four' : 2 + 2 == 1 + 3 := eq_refl 4.
```

`apply eq_refl` 过了！`Print four.` 实测输出：

```text
four = eq_refl (1 + 3)
     : 2 + 2 == 1 + 3
```

因为内核比较类型时先**归一化**：`2 + 2` 和 `1 + 3` 都算成 `4`，对内核而言是同一个东西。这套规则叫**可转换性**，就是 `Compute` 用的那套（函数求值、定义展开、match 化简）。所以 `3 + 1 = 4` 型命题的 `reflexivity`（13 章）从来不是取巧：它就是在 `apply eq_refl`。手写版 `four'` 用 `eq_refl 4`——和 tactic 生成的 `eq_refl (1 + 3)` 是两个 syntactically 不同的项，类型相同，这合法也很常见（坑位清单见 49.12）。列表拼接同理，算出来一样就是一样的证据：

```coq
Definition singleton : forall (X : Type) (x : X), [] ++ [x] == x :: [] :=
  fun (X : Type) (x : X) => eq_refl [x].
```

`[] ++ [x]` 归一化后就是 `x :: []`，一份 `eq_refl [x]` 通吃。证据还能**拆开用**——对等式证据做 match，两个边被同时解出：

```coq
Definition eq_add : forall (n1 n2 : nat), n1 == n2 -> S n1 == S n2 :=
  fun n1 n2 Heq =>
    match Heq with
    | eq_refl n => eq_refl (S n)
    end.
```

`Heq : n1 == n2` 只可能是 `eq_refl n` 造出来的，match 到它等于宣布 `n1`、`n2` 都是同一个 `n`，目标自动变成 `S n == S n`。这套动作 tactic 版一样能做，但**换记号就翻车**——这是本章最重要的坑之一，实测：

```coq
Theorem eq_add_s : forall (n1 n2 : nat), n1 == n2 -> S n1 == S n2.
Proof.
  intros n1 n2 Heq.
  Fail rewrite Heq.
  destruct Heq as [n].
  Fail reflexivity.
  apply eq_refl.
Qed.
```

`Fail rewrite Heq.` 剥掉 Fail 后的真实报错（9.3 实测，后面还拖着十几行未解元变量 dump）：

```text
setoid rewrite failed: UNDEFINED EVARS:
 ?X91==[n1 n2 Heq |- Relation_Definitions.relation nat]
 ...
```

`Fail reflexivity.` 的报错干脆得多：

```text
The relation eq is not a declared reflexive relation. Maybe you need to
require the Corelib.Classes.RelationClasses library
```

原因：`rewrite`/`reflexivity` 走 **setoid 关系登记表**，表里只认识标准 `=`（还有 `iff` 等几位常客），不认识新注册的 `==`。出路不是先去注册同余关系，而是回到原始动作：`destruct Heq as [n]` 拆证据（`n1`、`n2` 当场被 `n` 替换），`apply eq_refl` 收尾。**策略是便利贴，项才是本体**——这句话的又一个证据。

等号的两种哲学观在此汇合。归纳等号蕴含 **Leibniz 等号**（「x = y」意即「任何性质对 x 成立则对 y 成立」），tactic 版顺手，项式版要一点语法功夫：

```coq
Lemma equality__leibniz_equality : forall (X : Type) (x y : X),
  x == y -> forall (P : X -> Prop), P x -> P y.
Proof.
  intros X x y Heq P Hp.
  destruct Heq as [z]. exact Hp.
Qed.

Definition equality__leibniz_equality_term : forall (X : Type) (x y : X),
  x == y -> forall P : X -> Prop, P x -> P y :=
  fun X x y Heq P =>
    match Heq in u == v return P u -> P v with
    | eq_refl _ => fun Hp => Hp
    end.
```

反直觉的地方：一开始我们写 `match Heq with eq_refl _ => Hp end`，**实测编译不过**，报错点名「incompatible with x」——被 lambda 绑定的 `x` 不肯就范（详见 49.12 坑 4）。必须用 `match ... in ... return` 语法把 `==` 的**两个指标都抽象出来**（`in u == v`），再声明「给 `P u` 就能还 `P v`」，分支里 `u`、`v` 合一为同一个 `n`，恒等函数交差。标准库的 `=` 之所以常见 `in _ = z` 就够，是因为它的左边其实是**参数**不是指标——实测结构不同的归纳类型，match 语法就是不同。反向也成立：Leibniz 蕴含归纳等号，诀窍是挑一个聪明的性质——取 `P := fun z => x == z`：

```coq
Lemma leibniz_equality__equality : forall (X : Type) (x y : X),
  (forall P : X -> Prop, P x -> P y) -> x == y.
Proof.
  intros X x y H.
  exact (H (fun z => x == z) (eq_refl x)).
Qed.

End EqPlay.
```

`P x` 化为 `x == x`（`eq_refl x` 可证），`P y` 化为 `x == y`——正是目标。两种等号定义在命题层面等价，但本章后续（以及全部 tactic 生态）用的都是归纳版。

### 49.8 inversion 到底做了什么

14 章、15 章用 `inversion` 拆过 `ev`、等式、构造子互斥。现在证据=项、命题=归纳类型，`inversion` 的真身可以摊牌。对一条类型为归纳命题 `P` 的假设 `H`，`inversion H` 做的事是：

1. **对 `P` 的每个构造子各出一个子目标**，假定 `H` 由该构造子生成；
2. 把构造子的**参数与前提**加进子目标上下文；
3. 把构造子的**结论**与 `H` 的实际类型做**模式匹配**，解出一组必须成立的等式，加进上下文（并顺手回写进目标）；
4. 等式当场矛盾的（如 `S n = 0`），该子目标**直接关闭**；
5. 证据里的等式信息可被 `as`/`subst` 类模式进一步使用。

三条最小实测样本，分别对应「无等式」「前提入上下文」「解出等式」：

```coq
(* ---------- 49.8 inversion 到底做了什么 ---------- *)

Theorem inv_or_demo : forall (P Q : Prop), P \/ Q -> Q \/ P.
Proof.
  intros P Q H. inversion H as [HP | HQ].
  - right. exact HP.
  - left. exact HQ.
Qed.

Theorem inv_and_demo : forall (P Q : Prop), P /\ Q -> Q /\ P.
Proof.
  intros P Q H. inversion H as [HP HQ]. split.
  - exact HQ.
  - exact HP.
Qed.

Theorem inv_eq_demo : forall (n m : nat), S n = S m -> n = m.
Proof.
  intros n m H. inversion H. reflexivity.
Qed.
```

`inv_or_demo`：两个构造子两个子目标，`or_introl`/`or_intror` 的结论 `P \/ Q` 不约束 P、Q 的形状，所以**没有额外等式**，只有 `HP`、`HQ` 进来——与 49.5 的 `or_elim` 双分支 match 完全同形。`inv_and_demo`：单构造子单子目标，两个前提 `HP`、`HQ` 入上下文——`inversion` 在 `and` 上退化成 `destruct`。`inv_eq_demo`：`=` 只有 `eq_refl`，它的结论强迫两个边相同，于是解出 `n = m` 写回上下文，目标化简后用 `reflexivity` 收。第四例演示规则 4——等式无解时子目标当场消失：

```coq
Theorem inv_Sn_O : forall n : nat, S n = 0 -> False.
Proof.
  intros n H. inversion H.
Qed.
```

`eq_refl` 造不出 `S n = 0`（构造子不匹配），唯一子目标被矛盾等式自动关闭，`Qed` 直接过——13 章 `discriminate H` 干的活，`inversion` 内建了。回头看 15 章 `induction H` 与本章一切：**对证据归纳、对证据 match、inversion，是同一件事的三个粗细档位**。

### 49.9 内核只检查三件事

为什么 Coq 的证明可信？因为归根到底只有一台**极小的类型检查器**（TCB，可信计算基，1 章伏笔在此收口）在把关，它只查三件事：

1. **类型匹配**：函数应用的实参类型、构造子的参数，逐一对得上（49.1、49.2 的 `Fail` 全是它拦的）；
2. **match 穷尽性**：分支必须覆盖全部构造子；
3. **递归终止**：`Fixpoint` 必须结构递归。

后两条不是洁癖，是**逻辑soundness的闸门**。漏分支的「证明」：

```coq
(* ---------- 49.9 内核只检查三件事 ---------- *)

Fail Definition or_bogus : forall P Q, P \/ Q -> P :=
  fun (P Q : Prop) (A : P \/ Q) =>
    match A with
    | or_introl H => H
    end.
```

每个在案分支类型都对，但 `or_intror` 一侧凭空蒸发——若放行，`P \/ Q` 就能当 `P` 用，假定理立成。实测报错（剥 Fail）：

```text
Non exhaustive pattern-matching: no clause found for pattern
or_intror _
```

不终止的「证明」更阴险——返回任意类型 `X` 的死循环等于凭空造出任何命题的证据：

```coq
Fail Fixpoint infinite_loop {X : Type} (n : nat) {struct n} : X :=
  infinite_loop n.

Fail Definition falso : False := infinite_loop 0.
```

`{struct n}` 明说「按 n 做结构递归」，照样拦下，实测报错：

```text
Recursive definition of infinite_loop is ill-formed.
In environment
infinite_loop : forall X : Type, nat -> X
X : Type
n : nat
Recursive call to infinite_loop has principal argument equal to "n"
instead of a subterm of "n".
Recursive definition is: "fun (X : Type) (n : nat) => infinite_loop X n".
```

关键一句：`principal argument equal to "n" instead of a subterm of "n"`——递归调用必须打在参数的**真子项**上，`n` 本身不行。于是第二行 `falso` 的 Fail 实测报的是「`The reference infinite_loop was not found in the current environment.`」——上一行被拒后名字根本不存在。两道闸门各就各位：守卫检查杀了 `infinite_loop`，引用检查顺带杀了 `falso`。

这构成了 1 章 de Bruijn 判据的完整闭环：**策略可以带 bug**——哪怕某个 tactic 给你拼了个非法项，`Qed` 时内核把整个证明项**从头**类型检查一遍，不合格的定理根本进不了环境，后面再也引用不到。可信的是「通过类型检查的项」，不是「跑过的一串策略」。

### 49.10 证明无关性与命题外延：要公理

Curry–Howard 的最后一块拼图问题：同一个命题可以有多份**形状不同**的证据（49.7 里 `eq_refl 4` 和 `eq_refl (1 + 3)` 就是例子）。想要「证据都相等」乃至「等价命题相等」，得看两条原则——先把它们写成 Prop：

```coq
(* ---------- 49.10 证明无关性要请出公理 ---------- *)

Module PEPI.

Definition propositional_extensionality : Prop :=
  forall (P Q : Prop), (P <-> Q) -> P = Q.

Definition proof_irrelevance_prop : Prop :=
  forall (P : Prop) (pf1 pf2 : P), pf1 = pf2.

End PEPI.
```

**命题外延**（`P <-> Q` 则 `P = Q`）与**证明无关性**（同一命题两份证据相等）都不是 Rocq 内建定理。标准库把它们作为**公理模块**提供——文件开头第二条 `Require` 请来的 `FunctionalExtensionality` 与 `ProofIrrelevance` 就是。25 章的照妖镜 `Print Assumptions` 一查便知出身：

```coq
Print Assumptions functional_extensionality.
Print Assumptions proof_irrelevance.
```

9.3 实测输出：

```text
Axioms:
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
  (forall x : A, f x = g x) -> f = g
Axioms:
proof_irrelevance : forall (P : Prop) (p1 p2 : P), p1 = p2
```

两条 `Axioms:` 名单写得明明白白：函数外延定理挂在公理 `functional_extensionality_dep` 上，`proof_irrelevance` 干脆**本身就是公理**。不信邪，硬用可转换性「证明」命题外延，当场穿帮：

```coq
Fail Definition pe_attempt : PEPI.propositional_extensionality :=
  fun (P Q : Prop) (H : P <-> Q) => eq_refl (P <-> Q).
```

真实报错（剥 Fail）：

```text
In environment
P : Prop
Q : Prop
H : P <-> Q
The term "eq_refl" has type "(P <-> Q) = (P <-> Q)"
while it is expected to have type "P = Q".
```

`eq_refl` 只认得「算完之后相同」，而 `P <-> Q` 给不出这种相同。公理身份还有第三枚指纹：

```coq
Print proof_irrelevance.
```

实测输出 `*** [ proof_irrelevance : forall (P : Prop) (p1 p2 : P), p1 = p2 ]`（外加一行 Arguments 信息）——`***` 表示**无定义体**，与 `Axioms:` 名单双重盖章。顺带一提，公理化之后命题外延与证明无关性互有蕴含（SF 练习链：外延 ⇒ 任意命题等于 True ⇒ 证据全相等），本章不展开。工程纪律不变，且因命题层证据而更锋利：**只要 `Print Assumptions` 里不是 `Closed under the global context`，你的定理就背着公理活着**——用还是不用，是每次都要做的设计决策。

### 49.11 项式证明小练：tactic 版对照表

14 章用 tactic 证过的命题，现在全裸重写。先把「翻译词典」立起来：

| tactic | 项式 |
|---|---|
| `intros x` | `fun x =>` |
| `apply C` / `exact e` | `C e` / `e` |
| `destruct H as [...]` | `match H with ... end` |
| `split` | `conj` |
| `left` / `right` | `or_introl` / `or_intror` |
| `reflexivity` | `eq_refl` |

练三条（`and_assoc'` 对应 14 章 `and_assoc`；`curry'`/`uncurry'` 是柯里化双向；`de_morgan_not_or'` 对应 14 章非摩根一侧）：

```coq
(* ---------- 49.11 项式证明小练 ---------- *)

Definition and_assoc' : forall P Q R : Prop,
  P /\ (Q /\ R) -> (P /\ Q) /\ R :=
  fun P Q R H =>
    match H with
    | conj HP (conj HQ HR) => conj (conj HP HQ) HR
    end.

Definition curry' : forall P Q R : Prop, ((P /\ Q) -> R) -> P -> Q -> R :=
  fun P Q R f HP HQ => f (conj HP HQ).

Definition uncurry' : forall P Q R : Prop, (P -> Q -> R) -> (P /\ Q) -> R :=
  fun P Q R f HPQ =>
    match HPQ with
    | conj HP HQ => f HP HQ
    end.

Definition de_morgan_not_or' : forall P Q : Prop, ~ (P \/ Q) -> ~ P /\ ~ Q :=
  fun P Q H =>
    conj (fun HP => H (or_introl HP)) (fun HQ => H (or_intror HQ)).

End Ex49ProofTerms.
```

末尾 `End` 与开头的 `Module` 收口，示例文件到此为止。逐项读：`and_assoc'` 的分支模式 `conj HP (conj HQ HR)` 一次拆两层，重新打包 `(P /\ Q) /\ R`——tactic 版里三行 `destruct` 加两行 `split` 的活。`curry'` 一行：把两个证据 `conj` 成对再喂给 `f`；`uncurry'` 反向拆对再应用——这就是 5 章/16 章函数柯里化的证明版，`R` 是命题时它同时是「curry 保真」的逻辑定理。`de_morgan_not_or'` 里 `~ P` 就是 `P -> False`（14 章的定义），所以 `conj` 收的两个分量是两个「把 P（Q）证据变成矛盾」的函数：`H` 吃不下 `or_introl HP`，只好把 `HP` 转手喂出 `False`。对照 tactic 版写一遍项式版，值得作为肌肉记忆训练：**intros 即 fun，destruct 即 match，split 即 conj**。

### 49.12 本章坑位清单（实测）

1. ** Qed 封黑盒，计算展不开**（49.4）：`Definition add2o ... Qed.` 后 `Compute (add2o 2)` 输出停在 `add2o 2`，连 `eq_refl` 都过不了类型检查（报 `has type "4 = 4" while ... "add2o 2 = 4"`）——用策略造的程序必须 `Defined.` 收尾；
2. **tactic 不产生「最简项」**（49.1、49.7）：`Print four.` 实测是 `eq_refl (1 + 3)`，手写是 `eq_refl 4`——同一命题，tactic 项与手搓项形状经常不同，都合法；调试时别拿 `Print` 的形状当对错标准，认类型；
3. **自造等号进不了 setoid 白名单**（49.7）：`Fail rewrite Heq.` 报 `setoid rewrite failed: UNDEFINED EVARS:` 加一堆元变量 dump，`Fail reflexivity.` 报 `The relation eq is not a declared reflexive relation...`——`==` 上请用 `destruct Heq as [n]. apply eq_refl.`；
4. **对指标型等式证据 match 必须 `in`/`return` 抽出全部指标**（49.7）：`match Heq with eq_refl _ => Hp end` 在自造 `eq {X} : X -> X -> Prop` 上实测编译失败（报 `incompatible with "x"`），要写成 `match Heq in u == v return P u -> P v with`；标准 `=` 左边是参数所以 `in _ = z` 就够——两种声明看着像，match 语法不同；
5. **被 `Fail` 拒的定义不存在**（49.9）：`Fail Fixpoint infinite_loop ...` 之后，`Fail Definition falso : False := infinite_loop 0.` 的实测报错是「引用不存在」而非守卫检查——演示归演示，连坐效应要知道；
6. **PI/命题外延是公理不是定理**（49.10）：标准库 `ProofIrrelevance` 的 `proof_irrelevance` `Print` 出 `*** [ ... ]`（无定义体）、`Print Assumptions` 把它列进 `Axioms:`——一旦 Require 这些模块，依赖它们的定理就永远 `Closed` 不了；审查用 25 章的 `Print Assumptions`；
7. **子模块里重写 `and`/`or` 不改变记号指向**（49.5）：`MyProps` 里再定义 `Inductive and`，`/\` 仍展开到标准库那个（记号绑定全名）——解剖标本用 match 手搓，实战证据用标准构造子，别在两套之间接线。

---
上一章：[48 · 映射：把函数当数据结构](48-maps.md) ｜ 下一章：[50 · 归纳原则解剖](50-induction-principles.md) ｜ 返回：[README](../README.md)
