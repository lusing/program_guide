# 34 · 插入排序与规格模式

对应示例：`../examples/34_sort.v`（`Module Ex34Sort`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

第 23 章已经证过一次插入排序：`le_all` 式的有序 + `Permutation` 重排，两路合击。本章重访同一个算法，但把镜头对准**规格本身**：同一个「有序」概念，可以写成归纳谓词、写下标全称、配默认值全称三种形态——它们数学上等价，但**证明难度天差地别**。这是 VFA 卷的方法论核心：程序对不对是一半功夫，规格写得好不好是另一半；规格无法证明自己「正确」（它对应的是心里的非形式需求），但把同一需求写成两种形式再证等价，是建立信心的标准手段。

三个问题串起全章：插入排序作为函数式程序长什么样、为什么天然没有越界与副作用（34.1）？「有序」的三种规格各有什么代价、总规格 `is_a_sorting_algorithm` 怎么组装（34.2–34.3）？怎么证明三种规格互相等价、等价之后又能兑换出什么（34.4–34.5）？

### 34.1 程序：insert 与 sort

文件头与算法：

```coq
(* 34 插入排序与规格模式 —— 同一算法、三种有序规格、规格的自证 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex34Sort.

(* ---------- 34.1 程序：insert 与 sort ---------- *)

Fixpoint insert (i : nat) (l : list nat) : list nat :=
  match l with
  | [] => [i]
  | h :: t => if i <=? h then i :: h :: t else h :: insert i t
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | h :: t => insert h (sort t)
  end.

Example sort_pi :
  sort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof. simpl. reflexivity. Qed.

Example insert_shared :
  insert 7 [1; 3; 4; 8; 12; 14; 18] = [1; 3; 4; 7; 8; 12; 14; 18].
Proof. reflexivity. Qed.
```

教科书上的插入排序是数组 + 原地交换；函数式的版本是**链表 + 插入**：`insert i l` 沿着有序表 `l` 找到 `i` 的位置插进去（比较用第 33 章 `leb_reflect` 同族的 `i <=? h`），`sort` 把每个新元素依次插入递归排好的尾部。`sort_pi` 用 π 的数字当测试数据，`simpl. reflexivity` 直接算出答案。

`insert_shared` 值得多看一眼，它演示函数式程序与命令式的本质差异：往 `[1;3;4;8;12;14;18]` 里插 7，**尾部 `12::14::18` 三个节点原封不动**——`insert` 只构造了前四个新节点，旧列表中被打穿的前三个节点交由垃圾回收。没有数组越界、没有别名、没有「排序完原数组被毁」的副作用问题；代价是每一次 `insert` 都要重建前缀。这一段讨论在原书里配有时间/空间的常量分析（时间 4X、空间 1Y），我们不展开形式化，但要记住：**验证对象是纯函数，「输出共享输入的尾巴」是特性不是 bug**。

### 34.2 「有序」的三种规格

现在到了本章的正题。同一个直观概念「列表有序」，至少有三种写法：

```coq
(* ---------- 34.2 「有序」的三种规格 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall x, sorted [x]
| sorted_cons : forall x y l,
    x <= y -> sorted (y :: l) -> sorted (x :: y :: l).

Definition sorted' (al : list nat) : Prop :=
  forall i j iv jv,
    i < j ->
    nth_error al i = Some iv ->
    nth_error al j = Some jv ->
    iv <= jv.

Definition sorted'' (al : list nat) : Prop :=
  forall i j, i < j < length al -> nth i al 0 <= nth j al 0.

Definition is_a_sorting_algorithm (f : list nat -> list nat) : Prop :=
  forall al, Permutation al (f al) /\ sorted (f al).
```

**`sorted`（归纳版）**：三条构造子直译「空表有序、单元素有序、相邻有序且尾部递归有序」。它与第 23 章 `le_all` 版（每个元素压住后面**全部**）说的是同一件事，但**相邻版**把「只看邻居」摆在定义里，「局部 ⇒ 全局」的代价转移到后续引理（34.4 的 `sorted_le_nth` 正是补这一课的）。归纳版最大的红利：证明可以**对有序证据做归纳**——第 33 章练过的「对证据归纳」姿势直接复用。

**`sorted'`（下标 + nth_error 版）**：任意下标 `i < j`，取到的元素 `iv ≤ jv`。下标合法性藏在 `nth_error` 的返回值里——取不到就是 `None`，假设自动失效，不用单独提 `length`。

**`sorted''`（下标 + nth + 默认值版）**：同上但用 `nth i al 0`——`nth` 是全函数，越界返回默认值 `0`，所以必须显式限制 `i < j < length al` 把下标框在界内。三版中它最啰嗦（要提 length），`sorted'` 次之，`sorted` 最简——**越靠近构造子，证明越顺**，这是 34.5 要兑现的预言。

**`is_a_sorting_algorithm`** 把排序的总体规格组装起来：输出是输入的 `Permutation` **且**输出 `sorted`。为什么必须合取？两个反例各自击破一半：

```coq
(* 两个反例：合取的两半缺一不可 *)

Example not_sorting_empty : ~ is_a_sorting_algorithm (fun _ => []).
Proof.
  unfold is_a_sorting_algorithm. intro H.
  destruct (H [2;1]) as [Hperm _].
  assert (Hin : In 2 []).
  { apply (Permutation_in 2 Hperm).
    apply in_eq. }
  simpl in Hin. exact Hin.
Qed.

Example not_sorting_id : ~ is_a_sorting_algorithm (fun l => l).
Proof.
  unfold is_a_sorting_algorithm. intro H.
  destruct (H [2;1]) as [_ Hsorted].
  inversion Hsorted; subst.
  lia.
Qed.
```

`not_sorting_empty`：恒返回 `[]` 的函数输出当然有序，但 `Permutation [2;1] []` 被「保元素」一票否决——`Permutation_in 2 Hperm` 把 `In 2 [2;1]` 搬到 `In 2 []`（调用形式注意：标准库 `Permutation_in` 只显式收元素与重排证据两个参数，`A` 和两个列表都是隐式的——这与第 33 章我们**自造的显式版**不同，那章里同型调用写的是 `Permutation_in nat 2 [1;2] [1;1] ...`，因为彼时我们用自己的定理遮蔽了库版）。`In 2 [2;1]` 用 `in_eq` 一步造出，`simpl in Hin` 得到 `False` 直接收官。`not_sorting_id` 反过来：恒等函数当然保重排，但 `sorted [2;1]` 不成立——`inversion Hsorted` 展开唯一可行的构造子 `sorted_cons`，吐出 `2 <= 1` 的前提，`lia` 撞死。**去掉任何一半合取，规格立即放行一个冒牌排序**——这就是规格设计的第一课。

### 34.3 正确性证明

规格定稿，开始证明。总目标拆成两半各自击破：`insert` 保有序、`insert` 保重排，然后归纳组装。

```coq
(* ---------- 34.3 正确性证明 ---------- *)

Lemma insert_sorted : forall a l, sorted l -> sorted (insert a l).
Proof.
  intros a l S. induction S as [ | x | x y l Hxy S0 IHS0]; simpl.
  - apply sorted_1.
  - destruct (Nat.leb a x) eqn:E.
    + apply Nat.leb_le in E. apply sorted_cons; [exact E | apply sorted_1].
    + apply Nat.leb_gt in E. apply sorted_cons; [lia | apply sorted_1].
  - destruct (Nat.leb a x) eqn:Ex.
    + apply Nat.leb_le in Ex.
      apply sorted_cons; [exact Ex | apply sorted_cons; [exact Hxy | exact S0]].
    + apply Nat.leb_gt in Ex.
      destruct (Nat.leb a y) eqn:Ey.
      * apply Nat.leb_le in Ey.
        apply sorted_cons; [lia | apply sorted_cons; [exact Ey | exact S0]].
      * simpl in IHS0. rewrite Ey in IHS0.
        apply sorted_cons; [exact Hxy | exact IHS0].
Qed.
```

`insert_sorted` 是全章技术上最密的证明，骨架是**对有序证据 `S` 归纳**（不是对列表归纳！）。三条构造子三个分支：

- `sorted_nil`：`insert a [] = [a]`，`sorted_1` 一步。
- `sorted_1 x`：往单元素表插入。`destruct (Nat.leb a x) eqn:E` 把布尔比较撕开（`eqn:` 留下等式），`Nat.leb_le / Nat.leb_gt` 把等式兑换成命题 `a <= x / x < a`（这正是第 33 章 `leb_reflect` 桥的两半，此处用「destruct + 兑换」的朴素写法），两个方向都构造 `sorted_cons` 收尾，`lia` 处理 `x < a → x <= a` 这种顺手活。
- `sorted_cons x y l Hxy S0`：往 `x :: y :: l` 插入， IH 是 `IHS0 : sorted (insert a (y :: l))`——**插入同一个 `a`**（`a` 在归纳前已固定，这是对证据归纳的关键优势）。比较 `a` 与 `x`：若 `a <= x`，`a` 插在最前，尾巴 `x::y::l` 的有序性直接用**手头的证据重建**——`sorted_cons` 两层叠进 `Hxy` 与 `S0`，根本不用 IH。若 `x < a`，目标变成 `sorted (x :: insert a (y::l))`，还得再看 `a` 与 `y`：`a <= y` 则目标为 `sorted (x::a::y::l)`，`x <= a` 由 `lia` 从 `x < a` 拿到；`y < a` 则 `insert a (y::l)` 归约成 `y :: insert a l`，目标 `sorted (x :: y :: insert a l)`——第一层 `x <= y` 就是 `Hxy`，第二层 `sorted (y :: insert a l)` **正是 IHS0**（`simpl in IHS0` 展开它内层的 `if a <=? y`，`rewrite Ey in IHS0` 选定 `false` 分支后与目标严丝合缝）。

值得咀嚼的细节：`destruct (Nat.leb a x) eqn:Ex` 会把**目标里**的 `a <=? x` 替换成 `true/false`，但 IHS0 里的 `if a <=? y` 不受影响（destruct 默认只改目标）——所以最后必须 `rewrite Ey in IHS0` 手动对齐。两个布尔各自撕开、四处组合归位，这是「无 reflect 桥」的朴素代价；对比第 33 章 `maybe_swap_idempotent` 用 `destruct (ltb_reflect b a) as [H|H]` 一把拿到命题，两种写法以后都在用。

```coq
Theorem sort_sorted : forall l, sorted (sort l).
Proof.
  induction l as [ | x t IH].
  - apply sorted_nil.
  - simpl. apply insert_sorted. exact IH.
Qed.

Lemma insert_perm : forall x l, Permutation (x :: l) (insert x l).
Proof.
  intros x l. induction l as [ | y t IH]; simpl.
  - apply Permutation_refl.
  - destruct (Nat.leb x y).
    + apply Permutation_refl.
    + apply perm_trans with (y :: x :: t).
      * apply perm_swap.
      * apply perm_skip. exact IH.
Qed.

Theorem sort_perm : forall l, Permutation l (sort l).
Proof.
  induction l as [ | x t IH].
  - apply perm_nil.
  - simpl. apply perm_trans with (x :: sort t).
    + apply perm_skip. exact IH.
    + apply insert_perm.
Qed.

Theorem insertion_sort_correct : is_a_sorting_algorithm sort.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply sort_perm.
  - apply sort_sorted.
Qed.

Print Assumptions insertion_sort_correct.
```

后半程全是第 23/33 章的旧胶水：`sort_sorted` 对列表归纳、每步 `insert_sorted`；`insert_perm` 对列表归纳——插空表是自反，插 `y::t` 而落位在 `y` 之后时，中转站 `(y::x::t)` 一步 `perm_swap` 加一步 `perm_skip IH`；`sort_perm` 同款中转站 `(x :: sort t)`。`insertion_sort_correct` 把两半合取组装起来，`Print Assumptions` 实测输出 `Closed under the global context`——全程无公理。

### 34.4 验证规格本身：三种有序两两等价

证明程序满足规格只回答了一半问题；**规格对不对**无法形式化证明（Perl is 格言：「无法用形式手段从非形式出发」），但可以**用两种写法互相印证**。本节证 `sorted ≡ sorted'`，再顺手兑换出 `sorted''`。难点全在方向一向（归纳版 → 下标版），需要一个「头部压制全尾」的辅助引理：

```coq
(* ---------- 34.4 验证规格本身：三种有序两两等价 ---------- *)

Lemma sorted_le_nth : forall L x,
  sorted (x :: L) ->
  forall j jv, nth_error L j = Some jv -> x <= jv.
Proof.
  induction L as [ | y L' IH]; intros x S j jv Hnth.
  - destruct j; simpl in Hnth; discriminate.
  - inversion S as [ | | x0 z l0 Hxz S0 Heq]; subst.
    destruct j as [ | j']; simpl in Hnth.
    + injection Hnth as Hnth. rewrite <- Hnth. exact Hxz.
    + assert (Hy : y <= jv).
      { apply (IH y S0 j' jv). exact Hnth. }
      lia.
Qed.
```

`sorted_le_nth` 补上相邻版欠的账：**头元素 `x` 压制尾部一切元素**（第 23 章 `le_all` 直接把它写进定义，相邻版必须现证）。对尾部 `L` 归纳：`L = []` 时 `nth_error [] j` 取不出东西，`discriminate` 收；`L = y :: L'` 时 `inversion S` 展开唯一的构造子 `sorted_cons`（注意 `as` 模式给了六个名字——三个元素变量、两条前提、一条索引等式 `Heq`，`subst` 用它把 `x0/z/l0` 换回 `x/y/L'`）。下标 `j` 拆两半：`j = 0` 取到的是 `y` 本人，`injection` 从 `Some jv = Some y` 抽出 `jv = y`，`Hxz : x <= y` 直接用；`j = S j'` 时 `simpl in Hnth` 把下标退一位得 `nth_error L' j' = Some jv`，喂给 IH（注意 IH 的头参数是**全称的**——`apply (IH y S0 j' jv)` 把「以 `y` 为头压制 `L'`」实例化）拿到 `y <= jv`，`x <= y <= jv` 交给 `lia` 串起来。

```coq
Lemma sorted_sorted' : forall al, sorted al -> sorted' al.
Proof.
  intros al S. unfold sorted'.
  induction S as [ | x | x y l Hxy S0 IHS0].
  - intros i j iv jv Hij Hiv Hjv.
    destruct i; inversion Hiv.
  - intros i j iv jv Hij Hiv Hjv.
    destruct i as [ | i'].
    + destruct j as [ | j'];
        [ inversion Hij | destruct j'; discriminate Hjv ].
    + destruct i'; inversion Hiv.
  - intros i j iv jv Hij Hiv Hjv.
    destruct i as [ | i'].
    + injection Hiv as Hiv. subst iv.
      destruct j as [ | j']; [ inversion Hij | ].
      simpl in Hjv.
      exact (sorted_le_nth (y :: l) x
               (sorted_cons x y l Hxy S0) j' jv Hjv).
    + destruct j as [ | j']; [ inversion Hij | ].
      simpl in Hiv. simpl in Hjv.
      apply (IHS0 i' j' iv jv); [ lia | exact Hiv | exact Hjv ].
Qed.
```

`sorted_sorted'` 依旧对证据归纳，但每个分支现在要处理**下标簿记**——这是「归纳版 → 下标版」的固有税率。空表：任何下标取不出东西，`destruct i; inversion Hiv`（`nth_error [] 0 = None` 与 `= Some iv` 矛盾）。单元素 `[x]`：`i = 0` 时 `j` 必须 `≥ 1`，而 `nth_error [x] (S j')` 是 `None`——注意这里要先 `destruct j'` 再 `discriminate`：`nth_error [] j'` 在 `j'` 是变量时**不归约**，直接 `inversion Hjv` 会留下半化的等式卡住（实测坑，见 34.6）；`i ≥ 1` 时 `Hiv` 自己就是 `None = Some iv`，同样先 destruct 再 inversion。两元素以上 `x :: y :: l`：`i = 0` 时 `iv` 就是 `x`（`injection ... subst`），`j = S j'` 时 `simpl in Hjv` 把下标退到 `y :: l` 上，**一行全参数应用**把 `sorted_le_nth`（以重建的 `sorted_cons` 证据为输入）变成了 `x <= jv`；`i = S i'` 时两个下标各退一位，`IHS0`（同款断言、小一号的表）加 `lia`（把 `S i' < S j'` 兑成 `i' < j'`）收官。

```coq
Lemma sorted'_sorted : forall al, sorted' al -> sorted al.
Proof.
  induction al as [ | x l IH]; intro H.
  - apply sorted_nil.
  - destruct l as [ | y l'].
    + apply sorted_1.
    + apply sorted_cons.
      * apply (H 0 1 x y); [ lia | reflexivity | reflexivity ].
      * apply IH. unfold sorted' in *.
        intros i j iv jv Hij Hiv Hjv.
        apply (H (S i) (S j) iv jv);
          [ lia | simpl; exact Hiv | simpl; exact Hjv ].
Qed.
```

反方向 `sorted'_sorted` 换成对列表归纳（`sorted'` 不是归纳谓词，没有证据可归纳）。空表/单元素直接构造；`x :: y :: l'` 要证相邻有序 `x <= y`——**专门取下标 0 和 1 实例化** `H`，两个 `nth_error` 都是 `reflexivity` 一眼可见；尾部的 `sorted'` 从 `H` **整体下移一位**得到（下标各加一 `S i / S j`，`simpl` 后正是 `Hiv/Hjv`），喂给 IH。方向二的簿记是机械的「下标平移」，与方向一的「证据重建」难度相比，肉眼可见地轻。

```coq
Check nth_error_nth' :
  forall (A : Type) (l : list A) (n : nat) (d : A),
    n < length l -> nth_error l n = Some (nth n l d).

Lemma sorted_sorted'' : forall al, sorted al -> sorted'' al.
Proof.
  intros al S. unfold sorted''.
  intros i j [Hij Hj].
  apply (sorted_sorted' al S i j (nth i al 0) (nth j al 0) Hij).
  - apply nth_error_nth'. lia.
  - apply nth_error_nth'. exact Hj.
Qed.
```

`sorted''` 不单独硬证——两条下标规格之间的差只是「`nth_error` 显式成功/`nth + 默认值` 配界检查」，标准库 `nth_error_nth'` 精确兑换两者（`Check` 的实测类型显示 `A` 显式在前，标注时别写漏）。`sorted_sorted''` 于是变成三行组合：拆开 `i < j < length` 的合取，实例化 `sorted_sorted'`，两个 `nth_error` 方程各由 `nth_error_nth'` 兑出（第一个的界 `i < length al` 由 `lia` 从 `i < j < length` 现场推出）。**规格等价性一旦建立，就成了可自由兑换的货币**——这正是「两种写法互相印证」的完整含义。

### 34.5 规格风格决定证明难度

```coq
(* ---------- 34.5 规格风格决定证明难度 ---------- *)

Theorem sort_sorted' : forall l, sorted' (sort l).
Proof.
  intros l. apply sorted_sorted'. apply sort_sorted.
Qed.

End Ex34Sort.
```

收官一问：如果客户指名要 `sorted'` 规格的验收证书呢？`sort_sorted'` 两行拿到——**先证归纳版、再用等价引理兑换**。原书在这里给出了强烈对比：直接对 `insert` 证 `insert_sorted'`（不借道 `sorted`）是全卷著名的 5 星难题，需要一个专门的 `nth_error_insert` 引理做逐下标追踪；而绕道等价性则几乎免费。教训只有一句：**同一需求的两种规格，证明代价可以差一个数量级；先把「好证」的那个证下来，等价性引理负责翻译**——这与第 31 章「规格化（normalize）再证明」是同一条哲学在规格层的回声。

对照第 23 章，可以看清两种「有序」定义的取舍：`le_all` 版把「头部压制全尾」烧进定义，`insert_sorted` 证明极短；相邻版 `sorted` 定义最贴近直觉、构造子最少，代价是 `sorted_le_nth` 这样的补账引理。没有免费的规格——**定义的每一分简洁，要么在证明里还，要么在引理库里还**。

### 34.6 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **标准库 `Permutation_in` 的隐式参数与第 33 章自造版不同**（34.2）：库版只显式收元素与重排证据（`Permutation_in 2 Hperm`），照搬 33 章的显式写法 `Permutation_in nat 2 [2;1] [] Hperm` 实测报 `The term "2" ... expected to have type "Permutation ?l ?l'"`——`nat` 被当成了元素。
2. **`inversion` 不会替你归约变量下标**（34.4）：`nth_error [x] (S j')` 与 `nth_error [] j'`（`j'` 是变量）都不归约到 `None`，直接 `inversion H` 留下半化等式卡住、子弹头报 `Current bullet + is not finished`。对策：先 `destruct j'` 再 `inversion`，或干脆 `destruct j'; discriminate H`。
3. **`;` 是对全部子目标并联，不是顺序**（34.3）：`apply sorted_cons; exact Hxy; exact S0` 里 `exact Hxy` 会同时打到**两个**子目标上，第二个（`sorted (y::l)`）类型不符报 `The term "Hxy" ... expected to have type "sorted (y :: l)"`。要各管各的就得写 `[exact Hxy | exact S0]`。
4. **`rewrite` 吃的是等式，兑换成命题后就没了**（34.3）：`apply Nat.leb_gt in Ey` 把 `Ey : Nat.leb a y = false` 换成了 `y < a`，紧接着 `rewrite Ey in IHS0` 实测报 `setoid rewrite failed: Could not find an instance ...`。顺序反过来：先 `rewrite Ey in IHS0` 用掉等式，再（若需要）兑换命题。
5. **`destruct (Nat.leb a x) eqn:Ex` 只改写目标，不动 IH**（34.3）：IH 里残留的 `if a <=? y` 必须另做一次 `destruct (Nat.leb a y) eqn:Ey` + `rewrite Ey in IHS0` 手动对齐，否则 `exact IHS0` 对不上语法。
6. **`inversion ... as` 的名字数量要数准**（34.4）：`sorted_cons` 通道实际生成 6 个假设（3 元素 + 2 前提 + 1 索引等式），写 8 个名字实测报 `Unexpected introduction patterns: Heqz and Heql`。懒得数就省略 `as`，让 Coq 自动命名后再 `subst`。
7. **引理参数「后置 ∀」会让部分应用卡在隐式推断**（34.4）：`sorted_le_nth` 的 `j jv` 量词在 sorted 前提**之后**，`apply (sorted_le_nth (y::l) x)` 实测报 `Unable to find an instance for the variable j`——结论里根本不出现 `j`。对策：全参数显式应用 `exact (sorted_le_nth (y::l) x (sorted_cons ...) j' jv Hjv)`。
8. **`Check 名字 : 类型` 的标注必须与真实类型逐参数对齐**（34.4）：`nth_error_nth'` 实测类型 `forall (A : Type) (l : list A) ...`，`A` 显式在前；标注写成 `forall (l : list nat) ...` 实测报 `cannot unify "list nat" and "Type"`。

---
上一章：[33 · 置换与排序推理](33-perm.md) ｜ 下一章：[35 · 选择排序：燃料与 measure](35-selection.md) ｜ 返回：[README](../README.md)
