# 43 · 优先队列

对应示例：`../examples/43_priqueue.v`（`Module Ex43Priqueue`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

VFA 篇（33–47）走到这里，验证对象经历了三次升级：排序三部曲（34–36）验证的是**函数**——输入输出都是具体表，规格直接写成 `Permutation + sorted`；BST（39）与红黑树（41）验证的是**数据结构 + 谓词**，但查找、插入的抽象意义仍是"一个键对应一个值"；第 42 章用 `Module Type` 把 ADT 的接口本身写成了类型。本章把这三条线合流：验证一个**抽象状态是多重集**的 ADT——优先队列。多重集没有"第几个元素"的说法，具体表示（一张无序表）与抽象状态（一堆 key）之间无法用一个函数来回翻译，只能用一条**关系** `Abs : priqueue -> list key -> Prop` 连接，再配上表示不变量 **ri**（本章叫 `priq`）守住"哪些具体值算是合法表示"。这套「ri 守门、Abs 架桥」的方法论是本章的正题：所有规格定理一律只通过 `Abs` 说话，实现侧的工作就是逐条证明这些表征条款。原书本章留了两个练习共六处 `Admitted`（select 三引理、delete_max/merge 的表征定理），本章全部补全；原书依赖的 VFA 自定义 Ltac（`bdestruct`/`inv`）一律换成第 35 章同款的标准战术（`destruct (Nat.leb _ _) eqn:E`、`inversion ...; subst`、`Nat.leb_le`/`Nat.leb_gt` 兑换）。

### 43.1 规格先行：Module Type PRIQUEUE

文件头与全书一致：一行 `From Stdlib Require Import` 拉进 Arith/Bool/Lia/List/Permutation 五件，再加列表记号，全部内容包在 `Module Ex43Priqueue` 里。

```coq
(* 43 优先队列 —— keylist 表示、ri 不变量与 PRIQUEUE 签名规格验证 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex43Priqueue.

(* ---------- 43.1 规格先行：Module Type PRIQUEUE ---------- *)

(* 优先队列 ADT 的签名：priqueue 是抽象类型，priq 是表示不变量 ri，
   Abs 把具体表示连接到抽象的 key 多重集（用 list key 的
   Permutation 等价类刻画）。签名里的 Axiom 都是规格条款：
   它们等待实现模块逐条证明，而不是被当作公理使用。 *)

Module Type PRIQUEUE.
  Parameter priqueue : Type.
  Definition key := nat.

  Parameter empty : priqueue.
  Parameter insert : key -> priqueue -> priqueue.
  Parameter delete_max : priqueue -> option (key * priqueue).
  Parameter peek_max : priqueue -> option key.
  Parameter merge : priqueue -> priqueue -> priqueue.

  Parameter priq : priqueue -> Prop.
  Parameter Abs : priqueue -> list key -> Prop.
  Axiom can_relate : forall p, priq p -> exists al, Abs p al.
  Axiom abs_perm : forall p al bl,
    priq p -> Abs p al -> Abs p bl -> Permutation al bl.
  Axiom empty_priq : priq empty.
  Axiom empty_relate : Abs empty nil.
  Axiom insert_priq : forall k p, priq p -> priq (insert k p).
  Axiom insert_relate :
    forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al).
  Axiom delete_max_None_relate :
    forall p, priq p -> (Abs p nil <-> delete_max p = None).
  Axiom delete_max_Some_priq :
    forall p q k, priq p -> delete_max p = Some (k, q) -> priq q.
  Axiom delete_max_Some_relate :
    forall (p q : priqueue) k (pl ql : list key), priq p ->
      Abs p pl ->
      delete_max p = Some (k, q) ->
      Abs q ql ->
      Permutation pl (k :: ql) /\ Forall (ge k) ql.
  Axiom peek_max_correct :
    forall p k q, priq p ->
      delete_max p = Some (k, q) -> peek_max p = Some k.
  Axiom merge_priq : forall p q, priq p -> priq q -> priq (merge p q).
  Axiom merge_relate :
    forall p q pl ql al,
      priq p -> priq q ->
      Abs p pl -> Abs q ql -> Abs (merge p q) al ->
      Permutation al (pl ++ ql).
End PRIQUEUE.
```

读这张签名要看出**三组条款**。第一组是类型与算子：`priqueue` 是抽象类型（`Parameter`，实现必须给出定义），`key` 定死为 `nat`；五个算子里 `delete_max` 返回 `option (key * priqueue)`——空队列删不出东西，`peek_max` 是只看不删的观察器（原书签名没有它，本章补上，配套 `peek_max_correct` 条款）。第二组是 ri 与 `Abs` 的**健全性**：`can_relate` 保证每个合法表示至少能抽象出一个多重集，`abs_perm` 承认 `Abs` 是"关系"不是"函数"——它说 `p` 含有元素表 `al`，也允许说 `p` 含有 `bl`，只要两者互为置换；这条的深层原因是多重集本身不记顺序，换一个表示（比如 44 章的堆）后 `Abs` 报告元素的顺序更无从约定。第三组是**每个操作两条**：一条讲 ri 保持（`*_priq`），一条讲抽象效果（`*_relate`）。最重的条款是 `delete_max_Some_relate` 的合取右半：`Forall (ge k) ql`——删出来的 `k` 真的**压得住**剩下的每个元素；没有它，一个"随便删一个"的假实现也能靠 `Permutation` 蒙混过关。签名里的 `Axiom` 只是规格插槽：`Module Type` 里的 `Parameter`/`Axiom` 语义是"实现必须交货"，43.6 的 `Print Assumptions` 会证实最终证明项一个公理都不含。

### 43.2 取最大元：select 与三条选择引理

无序表实现的 `delete_max` 就是"取表头当种子，在尾巴里选最大"——核心引擎是第 35 章选择排序里 `select` 的孪生兄弟，每次比较留下较大者。

```coq
(* ---------- 43.2 取最大元：select 与三条选择引理 ---------- *)

(* 第 35 章 select 的孪生兄弟：这次每次比较留下的是较大者。
   原书写 i >=? h，但 stdlib 9.2 已删掉 Nat.geb 与 >=? 记号，
   这里按同义改写成 h <=? i。 *)

Fixpoint select (i : nat) (l : list nat) : nat * list nat :=
  match l with
  | [] => (i, [])
  | h :: t =>
    if h <=? i
    then let (j, l') := select i t in (j, h :: l')
    else let (j, l') := select h t in (j, i :: l')
  end.

Example select_demo : select 3 [1; 4; 1; 5] = (5, [1; 3; 1; 4]).
Proof. reflexivity. Qed.
```

与 35 章 `select x l`（`x <=? h` 保留较小者）只差一个比较方向：`h <=? i` 为真时种子 `i` 仍是最大候选、`h` 留在剩余表里；为假时 `h` 接棒当种子、`i` 被留在剩余表里。`select_demo` 让内核实算一遍：种子 3 走到 5，路过的 `[3;1]` 依次留在表中，得到 `(5, [1;3;1;4])`。注意代码注释里的改写：原书写的 `i >=? h` 在 stdlib 9.2 里**不存在**（`Nat.geb` 与 `>=?` 记号已被删除），实测报错见 43.8 第 1 条，同义改写成 `h <=? i` 即可——这也是"只写实测复现过的结论"的一处现场证据。

原书把 `select` 的三条性质留作三星练习（`select_perm_and_friends`），并提示"从 Selection.v 抄证明、改一个字符"。这里逐条补全，`bdestruct` 换成标准套路。

```coq
(* 原书练习 select_perm：输出表恰是输入表的重排（原书用 VFA 自定义
   bdestruct，这里换成标准 destruct + Nat.leb_le / Nat.leb_gt 兑换）。 *)

Lemma select_perm : forall i l j r,
  select i l = (j, r) -> Permutation (i :: l) (j :: r).
Proof.
  intros i l. revert i.
  induction l as [ | h t IH]; intros i j r H.
  - simpl in H. injection H as Hj Hr. subst.
    apply perm_skip. apply perm_nil.
  - simpl in H. destruct (h <=? i) eqn:E.
    + destruct (select i t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hr. subst.
      apply perm_trans with (h :: i :: t).
      * apply perm_swap.
      * apply perm_trans with (h :: j :: r').
        -- apply perm_skip. apply (IH i j r'). exact Et.
        -- apply perm_swap.
    + destruct (select h t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hr. subst.
      apply perm_trans with (i :: j :: r').
      * apply perm_skip. apply (IH h j r'). exact Et.
      * apply perm_swap.
Qed.
```

证明骨架与 35 章 `select_perm` 完全同型：对 `l` 归纳（先把种子 `i` revert 出去，让 IH 对任意种子成立），cons 步 `destruct (h <=? i) eqn:E` 撕开布尔、`destruct (select ... t) as [j' r'] eqn:Et` 拆出递归调用的输出，`injection` 拆对、`subst` 代入，然后走「swap → skip(IH) → swap」的换乘线对齐两侧表头。两个分支唯一的差别是**谁当种子**：真分支递归调 `select i t`、`h` 留在两侧；假分支递归调 `select h t`、`i` 留在两侧。`Et` 喂给 IH 换回 `Permutation (种子 :: t) (j :: r')`。一个实测细节：`subst` 会把 destruct 出来的新名字 `j'` 消灭掉（见 43.8 第 2 条），所以 IH 应用处写的是代入之后的 `j` 与 `r'`。

```coq
(* 原书练习 select_biggest_aux：若输出表里所有元素都不超过 j，
   则 j 不小于传入的种子 i。 *)

Lemma select_biggest_aux :
  forall i al j bl,
    Forall (ge j) bl ->
    select i al = (j, bl) ->
    j >= i.
Proof.
  intros i al. revert i.
  induction al as [ | a t IH]; intros i j bl HF H.
  - simpl in H. injection H as Hj Hbl. subst.
    lia.
  - simpl in H. destruct (a <=? i) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select i t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (HF' := Forall_inv_tail HF).
      assert (Hji := IH i j r' HF' Et).
      lia.
    + destruct (select a t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (Hji := Forall_inv HF).
      lia.
Qed.
```

这条引理是"压得住"的一半伏笔：它从**结论倒着**用 `Forall`——已知输出表 `bl` 里所有元素 `<= j`，要证 `j >= i`（种子也超不过最大元）。cons 的两个分支一难一易：真分支（`a <= i`，种子不变）里 `i` **没有**留在输出表中，只能靠 IH：`Forall_inv_tail` 从 `HF : Forall (ge j) (a :: r')` 剥出尾部 `Forall (ge j) r'`，喂给 `IH i j r'` 得到 `j >= i`；假分支（`i < a`，种子换人）里 `i` **被留在了**输出表 `i :: r'` 的头上，`Forall_inv HF` 直接给出 `ge j i`，连 IH 都不用——这正是"select 把淘汰者留在表里"的语义红利。真分支里兑换出来的 `E : a <= i` 其实用不上（目标 `j >= i` 直接就是 IH 的结论），兑换行保留是为了两个分支的形状对称、读起来不突兀；`Nat.leb_le`/`Nat.leb_gt` 的兑换套路在 35 章已经练熟。

```coq
(* 原书练习 select_biggest：返回的最大元压得住整个剩余表。 *)

Theorem select_biggest : forall i al j bl,
  select i al = (j, bl) -> Forall (ge j) bl.
Proof.
  intros i al. revert i.
  induction al as [ | a t IH]; intros i j bl H.
  - simpl in H. injection H as Hj Hbl. subst.
    constructor.
  - simpl in H. destruct (a <=? i) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select i t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (HF := IH i j r' Et).
      constructor.
      * assert (Hji := select_biggest_aux i t j r' HF Et).
        lia.
      * exact HF.
    + apply Nat.leb_gt in E.
      destruct (select a t) as [j' r'] eqn:Et. simpl in H.
      injection H as Hj Hbl. subst.
      assert (HF := IH a j r' Et).
      constructor.
      * assert (Hja := select_biggest_aux a t j r' HF Et).
        lia.
      * exact HF.
Qed.
```

`select_biggest` 正面证"压得住"：对剩余表归纳，cons 步先 `assert (HF := IH ... Et)` 把"递归输出压得住更短的表"存下来，再 `constructor`（即 `Forall_cons`）拆成头、尾两个目标。头的目标 `ge j a`（或 `ge j i`）单靠 IH 不够——IH 只说 `j` 压得住**尾部**，压不压得住**被淘汰留在表头的那个**要请 `select_biggest_aux` 出场：它从 `HF` 反推出 `j >= 种子`，配合兑换出来的 `a <= i`（真分支）或 `i < a`（假分支），lia 一网打尽。兑换的意义是把布尔比较变成 lia 能读的算术假设：两个分支分别拿到弱版（`a <= i`，链条 `a <= i <= j`）与严格版（`i < a`，链条 `i < a <= j`），此处强弱都不挑剔；但方向不能搞反——给 `= true` 的假设配 `Nat.leb_gt` 实测直接报错（原文见 43.8 第 7 条）。

### 43.3 实现：keylist 表示与五个操作

表示选定**无序 keylist**（`priqueue := list key`）：`empty`/`insert` 常数时间，`delete_max` 线性时间，`merge` 线性时间。用 `Module ... <: PRIQUEUE` 挂上签名——`<:` 只**检查**不**密封**，实现内部仍是透明定义（43.6 会专门对比密封版）。

```coq
(* ---------- 43.3 实现：keylist 表示与五个操作 ---------- *)

(* 无序 keylist 实现：empty/insert 常数时间，delete_max 线性时间。 *)

Module List_Priqueue <: PRIQUEUE.

Definition key := nat.

Definition priqueue := list key.

Definition empty : priqueue := nil.
Definition insert (k : key) (p : priqueue) : priqueue := k :: p.
Definition delete_max (p : priqueue) : option (key * priqueue) :=
  match p with
  | i :: p' => Some (select i p')
  | nil => None
  end.
Definition peek_max (p : priqueue) : option key :=
  match delete_max p with
  | Some (k, _) => Some k
  | None => None
  end.
Definition merge (p q : priqueue) : priqueue := p ++ q.

Example pq_demo_1 :
  delete_max (insert 5 (insert 1 (insert 4 empty))) = Some (5, [1; 4]).
Proof. reflexivity. Qed.

Example pq_demo_2 :
  delete_max [3; 1; 4; 1; 5] = Some (5, [1; 3; 1; 4]).
Proof. reflexivity. Qed.

Example pq_demo_3 : peek_max [3; 1; 4; 1; 5] = Some 5.
Proof. reflexivity. Qed.
```

五个操作各一行到几行：`insert` 就是 cons；`delete_max` 把表头当种子交给 `select`，空表返回 `None`；`peek_max` 完全派生自 `delete_max`（拿走 key、丢掉剩余队列），所以它的正确性条款 `peek_max_correct` 在 43.5 里几乎是白送的；`merge` 就是表拼接——这正是无序表实现最大的卖点：经典二叉堆（原书开篇对比过）的 merge 要把一个队列拆散逐个插进另一个队列，代价 N·logN，而这里一次 `++` 完事。三个 demo 全部 `reflexivity` 过：内核把 `select` 的五步比较真的算完了。`pq_demo_1` 特意用 `insert` 链而不是表字面量构造输入，提醒读者"客户端视角"下队列只能这样搭。

### 43.4 ri 与 Abs：不变量与抽象关系

本章实现的无序表太老实，ri 与 `Abs` 都平凡——但**接口形状**必须保持与签名一致，将来 44 章的二项式堆换上非平凡的 `priq`（树的形状不变量）与非平凡的 `Abs`（多棵树元素的并集），签名与全部规格条款一个字都不用改。

```coq
(* ---------- 43.4 ri 与 Abs：不变量与抽象关系 ---------- *)

(* 无序表实现里 ri（priq）平凡到恒为 True，Abs 也只是"表就是它自己"；
   但两者的接口形状与第 44 章的二项式堆实现完全一致。 *)

Definition priq (p : priqueue) := True.

Inductive Abs' : priqueue -> list key -> Prop :=
Abs_intro : forall p, Abs' p p.

Definition Abs := Abs'.

Lemma can_relate : forall p, priq p -> exists al, Abs p al.
Proof.
  intros p Hp. exists p. constructor.
Qed.

Lemma abs_perm : forall p al bl,
  priq p -> Abs p al -> Abs p bl -> Permutation al bl.
Proof.
  intros p al bl Hp Hal Hbl.
  inversion Hal; subst. inversion Hbl; subst.
  apply Permutation_refl.
Qed.
```

`priq` 定义成 `True`：任何表都是合法表示（对无序表实现而言确实没有别的约束）。`Abs` 用单构造子的归纳关系 `Abs'` 定义——"表 `p` 的抽象内容就是它自己"，再套一层 `Definition Abs := Abs'`。套这一层的用意与 ri 相同：**把"抽象关系叫什么、怎么用"固定在接口层**，实现层随便换心脏。两条健全性引理各两行：`can_relate` 取 `al := p` 自己当见证；`abs_perm` 对两条 `Abs` 做 `inversion ...; subst`（原书的 `inv` 战术），两个列表都坍缩成 `p`，剩下的就是 `Permutation_refl`。`inversion` 能穿过 `Definition Abs := Abs'` 的包装直接打到归纳构造子上，这点与 28 章 BST 的谓词 inversion 是同一机制。

### 43.5 操作的表征定理：补全原书全部练习

现在逐条兑现签名。ri 保持类（`empty_priq`/`insert_priq`/`delete_max_Some_priq`/`merge_priq`）因为 `priq = True` 全是一行；看点全在 `*_relate`。

```coq
(* ---------- 43.5 操作的表征定理：补全原书全部练习 ---------- *)

Lemma empty_priq : priq empty.
Proof. constructor. Qed.

Lemma empty_relate : Abs empty nil.
Proof. constructor. Qed.

Lemma insert_priq : forall k p, priq p -> priq (insert k p).
Proof. intros. constructor. Qed.

Lemma insert_relate :
  forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al).
Proof.
  intros p al k Hp Hal. unfold insert. inversion Hal; subst.
  constructor.
Qed.

Lemma delete_max_Some_priq :
  forall p q k, priq p -> delete_max p = Some (k, q) -> priq q.
Proof. intros. constructor. Qed.

(* 原书练习 delete_max_None_relate：队列为空当且仅当删不出元素。 *)

Lemma delete_max_None_relate :
  forall p, priq p -> (Abs p nil <-> delete_max p = None).
Proof.
  intros p Hp. split.
  - intros Hal. inversion Hal; subst. reflexivity.
  - intros Hdel. destruct p as [ | i p'].
    + constructor.
    + simpl in Hdel. discriminate.
Qed.
```

`insert_relate` 的形状值得记住：`unfold insert` 把 `insert k p` 还原成 `k :: p`，`inversion Hal; subst` 把 `al` 坍缩成 `p`，目标变成 `Abs (k :: p) (k :: p)`，一个 `constructor`（`Abs_intro`）收工——**抽象效果"插入即 cons 抽象表"恰好对应表示层的 cons**，两层同构所以证明免费。`delete_max_None_relate` 是原书二星练习，`iff` 拆两个方向：向右，`Abs p nil` inversion 出 `p = nil`，`delete_max nil = None` 是定义；向左，对 `p` 分类，`nil` 时 `constructor` 造 `Abs nil nil`，`i :: p'` 时 `Hdel : Some (select i p') = None` 直接 `discriminate`。

```coq
(* 原书练习 delete_max_Some_relate：核心条款。
   43.2 的 select_perm 提供 Permutation，select_biggest 提供 Forall。 *)

Lemma delete_max_Some_relate :
  forall (p q : priqueue) k (pl ql : list key),
    priq p ->
    Abs p pl ->
    delete_max p = Some (k, q) ->
    Abs q ql ->
    Permutation pl (k :: ql) /\ Forall (ge k) ql.
Proof.
  intros p q k pl ql Hp Hpl Hdel Hql.
  destruct p as [ | i p'].
  - simpl in Hdel. discriminate.
  - simpl in Hdel.
    destruct (select i p') as [j r] eqn:E. simpl in Hdel.
    injection Hdel as Hk Hq. subst.
    inversion Hpl; subst. inversion Hql; subst.
    split.
    + apply (select_perm i p' k ql E).
    + apply (select_biggest i p' k ql E).
Qed.
```

全章的核心证明，前四行战术做完所有脏活：`destruct p` 排除空表（`Some ... = None` discriminate）；`destruct (select i p') as [j r] eqn:E` 冻结递归调用的输出并留下方程 `E`；`injection Hdel as Hk Hq. subst.` 把 `(j, r) = (k, q)` 拆开代入；最后两次 `inversion ...; subst`——第一次把 `pl` 坍缩成 `i :: p'`，第二次要小心：`Hql : Abs q ql` 的 inversion 产生等式 `q = ql`，`subst` 消灭的是 `q`、幸存的是 `ql`，所以接下来引用的是 `k ql` 而不是 `k q`（踩坑实录见 43.8 第 3 条）。收尾的合取两半正好是 43.2 的两件兵器：`select_perm` 给 `Permutation (i :: p') (k :: ql)`——删掉的元素连同剩余表恰是原表的重排；`select_biggest` 给 `Forall (ge k) ql`——删掉的真是最大元。规格与实现的全部缝隙都在这几行里被缝合。

```coq
Lemma peek_max_correct :
  forall p k q, priq p ->
    delete_max p = Some (k, q) -> peek_max p = Some k.
Proof.
  intros p k q Hp Hdel. unfold peek_max. rewrite Hdel.
  reflexivity.
Qed.

Lemma merge_priq :
  forall p q, priq p -> priq q -> priq (merge p q).
Proof. intros. constructor. Qed.

(* 原书练习 merge_relate：merge 的抽象效果就是两个多重集相加。 *)

Lemma merge_relate :
  forall p q pl ql al,
    priq p -> priq q ->
    Abs p pl -> Abs q ql -> Abs (merge p q) al ->
    Permutation al (pl ++ ql).
Proof.
  intros p q pl ql al Hp Hq Hpl Hql Hal.
  unfold merge.
  inversion Hpl; subst. inversion Hql; subst. inversion Hal; subst.
  apply Permutation_refl.
Qed.
```

`peek_max_correct` 三行：`unfold peek_max` 露出 `match delete_max p with ...`，`rewrite Hdel` 把 `delete_max p` 换成 `Some (k, q)`，match 随之归约到 `Some k`——派生操作的正确性被"定义即派生"一句吃干抹净。`merge_relate`（原书练习）与 `abs_perm` 同构：`unfold merge` 后三个 inversion 把 `pl/ql/al` 全部坍缩，目标 `Permutation (p ++ q) (p ++ q)` 自反。注意条款的形状：它只说 `Abs (merge p q) al` 里的 `al` 是 `pl ++ ql` 的重排——多重集相加本就不该承诺顺序，`pl ++ ql` 的拼接顺序只是"某个"合法答案。

### 43.6 规格总定理与封装

签名条款分散在十二条引理里，把它们打包成一个定理，作为"实现兑现了全部规格"的单一事实。

```coq
(* ---------- 43.6 规格总定理与封装 ---------- *)

(* 把签名里的全部条款打包成一个定理：实现兑现了规格的每一条。 *)

Theorem priqueue_correct :
  (forall p, priq p -> exists al, Abs p al) /\
  (forall p al bl, priq p -> Abs p al -> Abs p bl -> Permutation al bl) /\
  priq empty /\
  Abs empty nil /\
  (forall k p, priq p -> priq (insert k p)) /\
  (forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al)) /\
  (forall p, priq p -> (Abs p nil <-> delete_max p = None)) /\
  (forall p q k, priq p -> delete_max p = Some (k, q) -> priq q) /\
  (forall (p q : priqueue) k (pl ql : list key),
     priq p -> Abs p pl -> delete_max p = Some (k, q) ->
     Abs q ql -> Permutation pl (k :: ql) /\ Forall (ge k) ql) /\
  (forall p k q, priq p ->
     delete_max p = Some (k, q) -> peek_max p = Some k) /\
  (forall p q, priq p -> priq q -> priq (merge p q)) /\
  (forall p q pl ql al, priq p -> priq q ->
     Abs p pl -> Abs q ql -> Abs (merge p q) al ->
     Permutation al (pl ++ ql)).
Proof.
  repeat apply conj.
  - exact can_relate.
  - exact abs_perm.
  - exact empty_priq.
  - exact empty_relate.
  - exact insert_priq.
  - exact insert_relate.
  - exact delete_max_None_relate.
  - exact delete_max_Some_priq.
  - exact delete_max_Some_relate.
  - exact peek_max_correct.
  - exact merge_priq.
  - exact merge_relate.
Qed.

End List_Priqueue.
```

十二条合取支与签名条款一一对应，证明是十二个 `exact`。开头的 `repeat apply conj` 大有讲究：直觉写法 `repeat split` 实测会把 `priq empty`（whnf 后是 `True`）、`Abs empty nil`（单构造子）这类子目标**当场证掉**——`split` 就是 `constructor`——于是目标数量从十二变成七，子弹与目标错位（实测报错见 43.8 第 4 条）；`apply conj` 只认 `/\`、拆完即止，十二个目标一个不少。`End List_Priqueue.` 收模块时 Coq 用签名逐条核对，少交货会直接被拦下——实测给不完整模块收尾报 `Error: The field e is missing in ...`（字段名与模块名随缺的货变化），这就是"规格先行"在编译器层面的强制力。

```coq
(* 密封（用 : 而非 <:）把实现细节封死：priqueue 成为抽象类型，
   客户端无法再把 [3;1;4;1;5] 之类的具体表塞进去。 *)

Module Sealed_Priqueue : PRIQUEUE := List_Priqueue.

Fail Example sealed_compute :
  Sealed_Priqueue.delete_max [3; 1; 4; 1; 5] = Some (5, [1; 3; 1; 4]).

(* 透明视图（<: 不密封）下客户端仍可拿具体表直接计算。 *)

Example transparent_compute :
  List_Priqueue.delete_max [3; 1; 4; 1; 5] = Some (5, [1; 3; 1; 4]).
Proof. reflexivity. Qed.

(* 密封之后，客户端唯一能依赖的只剩签名条款本身。 *)

Example sealed_spec_use :
  forall p q k, Sealed_Priqueue.priq p ->
    Sealed_Priqueue.delete_max p = Some (k, q) ->
    Sealed_Priqueue.peek_max p = Some k.
Proof.
  intros p q k Hp Hdel.
  apply (Sealed_Priqueue.peek_max_correct p k q Hp Hdel).
Qed.

Print Assumptions List_Priqueue.priqueue_correct.

End Ex43Priqueue.
```

最后一段做封装实验。`Module Sealed_Priqueue : PRIQUEUE := List_Priqueue.` 用**密封**（`:` 而非 `<:`）把同一实现重新打包：从此 `Sealed_Priqueue.priqueue` 对外是不透明常量，`Fail Example` 实测如约失败——`[3;1;4;1;5] : list nat` 塞不进抽象类型（错误原文见 43.8 第 6 条）；而透明视图 `List_Priqueue.delete_max`（`<:`）下同一个计算照常 `reflexivity` 通过。两条路对比出 `<:`（检查）与 `:`（封装）的分界。`sealed_spec_use` 展示密封后的正确姿势：客户端拿 `Sealed_Priqueue.peek_max_correct` 这条**签名条款**推自己的小定理，全程不碰任何实现细节——将来换上 44 章的二项式堆实现，这个证明原封不动。收尾的 `Print Assumptions List_Priqueue.priqueue_correct.` 实测输出一行：

```
Closed under the global context
```

签名里那一排 `Axiom` 只是等着交货的规格插槽，最终证明项无任何公理依赖——"用公理写规格、用实现还账"在这行输出里闭环。

### 43.7 本章小结

- **方法论**：抽象状态为多重集的 ADT 无法用函数连接表示与抽象，改用关系——ri（`priq`）守住合法表示，`Abs` 把表示架到抽象表；所有规格定理只用 `Abs` 说话，`abs_perm` 承认 `Abs` 的多值性（置换等价类）。
- **签名即规格**：`Module Type PRIQUEUE` 里 `Parameter` 是"必须交货的定义"、`Axiom` 是"必须证明的条款"；`<:` 检查不密封，`:` 密封到连计算都被封死；客户端透过密封视图只能用条款推理（`sealed_spec_use`），实现可替换。
- **证明库存**：select 三引理（重排、最大元不小于种子、最大元压住剩余表）是 delete_max 正确性的全部弹药，其中 `select_biggest_aux` 的"倒用 Forall"与假分支"i 留在表头白送 `ge j i`"是两处值得回味的省力点。
- **原书练习清零**：`select_perm`、`select_biggest_aux`、`select_biggest`、`delete_max_None_relate`、`delete_max_Some_relate`、`merge_relate` 六处 `Admitted` 全部补成 `Qed`，VFA 自定义 Ltac 全部替换为标准战术。
- **效率预告**：无序表实现 `empty`/`insert` O(1)、`delete_max`/`merge` O(N)；下一章的二项式堆把三者全部压到 O(log N)，代价是 ri 与 `Abs` 不再平凡——本章搭好的签名与规格条款将原样复用。

### 43.8 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`>=?` 与 `Nat.geb` 在 stdlib 9.2 已不存在**（43.2）：照抄原书的 `if i >=? h` 实测直接语法报错 `Error: Syntax error: [term] expected after '>=' (in [term]).`；想手写 `Nat.geb` 也报 `The reference Nat.geb was not found in the current environment.` 加提示 `Did you mean Nat.leb, Nat.sub, Nat.ltb, Nat.le, Nat.gcd, Nat.eqb or Nat.eq?`。同义改写成 `h <=? i`（比较方向记得翻转）。
2. **`injection ... as ... ; subst` 会消灭 destruct 出来的新名字**（43.2）：`destruct (select i t) as [j' r']` 后 `subst` 把 `j'` 替换成既有的 `j`，再写 `j'` 实测报 `Error: The variable j' was not found in the current environment.`。脚本里引用的名字一律以 subst **之后**为准。
3. **inversion 抽象关系时的等式会吃掉外层变量**（43.5）：`Hql : Abs q ql` 做 `inversion Hql; subst` 产生的等式 `q = ql` 消灭的是 `q`，随后 `apply (select_perm i p' k q E)` 实测报 `Error: The variable q was not found in the current environment.`；必须改用幸存者 `ql`。多个 inversion 连发时，最好逐个看清每个变量死没死。
4. **`repeat split` 会顺手证掉非合取子目标**（43.6）：`priq empty`（whnf 为 `True`）与 `Abs empty nil`（单构造子）被 `split`（即 `constructor`）当场解决，十二个目标只剩七个，第三颗子弹实测错位报 `The term "empty_priq" has type "priq empty" while it is expected to have type "forall (p : priqueue) (al : list key) (k : key), priq p -> Abs p al -> Abs (insert k p) (k :: al)"`。只拆合取请用 `repeat apply conj`。
5. **`Fail` 只管到一个句号**（43.6）：`Fail Example ... .` 换行再写 `Proof. reflexivity. Qed.`，语句在第一个句号处就结束了（且 Fail 已吞掉类型错误、没有打开证明），孤立的 `Proof.` 实测报 `Error: Command not supported (No proof-editing in progress)`。被 Fail 的示例必须写成单个句子、不带续行证明体。
6. **密封模块真的封死计算**（43.6）：`Module Sealed_Priqueue : PRIQUEUE := List_Priqueue.` 之后拿具体表喂抽象算子，实测报
   ```
   The term "[3; 1; 4; 1; 5]" has type "list nat"
   while it is expected to have type "Sealed_Priqueue.priqueue".
   ```
   同一实现走 `<:` 透明视图则 `reflexivity` 照常通过——这是 `<:` 与 `:` 语义差异最直观的实验。
7. **布尔兑换引理的方向不能反**（43.2）：对 `E : (a <=? i) = true` 误用 `apply Nat.leb_gt in E`，实测报 `Error: Unable to apply lemma of type "forall x y : nat, (x <=? y) = false <-> y < x" on hypothesis of type "(a <=? i) = true".`——`Nat.leb_le` 配 `= true`、`Nat.leb_gt` 配 `= false`，一一对应。

---
上一章：[42 · 抽象数据类型](42-adt.md) ｜ 下一章：[44 · 二项式堆](44-binom.md) ｜ 返回：[README](../README.md)
