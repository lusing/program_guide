# 104. 数组分离逻辑：区间、聚焦与快速排序

对应示例：`../examples/104_slf_arrays.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

取材 Software Foundations 卷六 *Separation Logic Foundations*（v1.0）的 *Arrays* 章。原书 6 个练习均在本章示例中完整证明，无 `Admitted`。

---

## 104.0 为什么数组需要两种足迹

此前验证引用时，一个堆谓词通常只描述一个内存单元。数组则是一块连续内存：创建数组要取得整块资源，读取长度只访问头单元，而读取或修改某个元素只访问一个元素单元。如果所有操作都以整个数组为前条件，虽然安全，却无法直接表达“两个不相交区间可以分别处理”。

本章从三层视角组织数组推理：

1. **大足迹**：`harray L p` 拥有地址 `p` 处的完整数组，列表 `L` 是它的逻辑内容；
2. **小足迹**：`hheader n p` 只拥有保存长度的头单元，`hcell v p i` 只拥有下标 `i` 对应的元素单元；
3. **区间**：`hseg L p j` 拥有从绝对下标 `j` 开始的连续元素，列表 `L` 的相对下标 `k` 对应绝对下标 `j+k`。

分离合取保证这些资源描述的是不相交的堆片段。于是，快速排序可以把枢轴左侧和右侧分别交给两次递归调用，而枢轴单元及数组以外的资源由框架规则自动保留。

示例将大、小足迹先作为抽象接口，最后再用具体的单单元堆谓词实现它们。`Parameter` 在这里表示数组操作的规格接口，不是未完成的练习。

```coq
(* 104 数组分离逻辑：大足迹、小足迹、区间聚焦与快速排序 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Arrays 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference LibSepTLCbuffer.
#[global] Hint Rewrite conseq_cons' : rew_listx.
Open Scope wp_scope.

Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
Implicit Types p q : loc.
Implicit Types k : nat.
Implicit Types i n : int.
Implicit Types v : val.

Module Arrays.
```

---

## 104.1 大足迹规格：把整个数组作为一份资源

`harray L p` 把堆中的数组与数学列表 `L` 联系起来。创建长度为 `n`、元素均为 `v` 的数组，返回新地址 `p`，并得到 `harray (LibList.make (abs n) v) p`。这里 `abs n` 把非负整数转换成列表库使用的自然数长度。

`triple_array_make'` 给出等价而更方便消去的后条件：存在列表 `L`，其长度为 `n`，且界内每个元素都等于 `v`。`length` 和 `get` 不消耗数组，后条件保留原谓词；`set` 则用 `LibList.update` 描述内容更新。越界访问不在规格保证范围内，所以 `get`、`set` 都有 `0 <= i < length L` 前提。

```coq
(* ---------- 104.1 数组操作的大足迹规格 ---------- *)

(* harray L p 拥有地址 p 处的整个数组，逻辑内容由列表 L 描述。 *)

Parameter harray : forall (L:list val) (p:loc), hprop.

Parameter val_array_make : val.
Parameter val_array_length : val.
Parameter val_array_get : val.
Parameter val_array_set : val.

Parameter triple_array_make : forall n v,
  n >= 0 ->
  triple (val_array_make n v)
    \[]
    (funloc p => harray (LibList.make (abs n) v) p).

Parameter triple_array_make' : forall n v,
  n >= 0 ->
  triple (val_array_make n v)
    \[]
    (funloc p => \exists L, harray L p
                 \* \[n = length L]
                 \* \[forall i, 0 <= i < n -> LibList.nth (abs i) L = v]).

Parameter triple_array_length : forall L p,
  triple (val_array_length p)
    (harray L p)
    (fun r => \[r = length L] \* harray L p).

Parameter triple_array_get : forall L p i,
  0 <= i < length L ->
  triple (val_array_get p i)
    (harray L p)
    (fun r => \[r = LibList.nth (abs i) L] \* harray L p).

Parameter triple_array_set : forall L p i v,
  0 <= i < length L ->
  triple (val_array_set p i v)
    (harray L p)
    (fun _ => harray (LibList.update (abs i) v L) p).

#[local] Hint Resolve triple_array_get triple_array_set
                       triple_array_make triple_array_length : triple.
```

这些规格足以验证“把数组当作不可拆分对象”的客户端，却不足以验证快速排序：递归调用不应要求拥有整个数组，否则左右递归会重复索要同一份资源。下一节引入更精细的所有权。

---

## 104.2 小足迹规格：头单元与元素单元

头单元保存长度，元素单元保存数组元素。`triple_array_length_hheader` 只要求头单元；`triple_array_get_hcell` 和 `triple_array_set_hcell` 只要求目标元素单元。分离逻辑框架会自动把数组其余部分保留在后条件中，因此这些小规格特别适合局部推理。

注意 `hcell` 使用绝对下标 `i`。稍后 `hseg L p j` 会为列表中的相对位置加上区间起点 `j`。

```coq
(* ---------- 104.2 头部与单元格的小足迹规格 ---------- *)

(* hheader n p 只拥有保存长度的头单元；hcell v p i 只拥有第 i 个元素。 *)

Parameter hcell : forall (v:val) (p:loc) (i:int), hprop.
Parameter hheader : forall (n:int) (p:loc), hprop.

Parameter triple_array_length_hheader : forall n p,
  triple (val_array_length p)
    (hheader n p)
    (fun r => \[r = (n:int)] \* hheader n p).

Parameter triple_array_get_hcell : forall p i v,
  triple (val_array_get p i)
    (hcell v p i)
    (fun r => \[r = v] \* hcell v p i).

Parameter triple_array_set_hcell : forall p i v w,
  triple (val_array_set p i v)
    (hcell w p i)
    (fun _ => hcell v p i).
```

---

## 104.3 区间谓词与拆分、合并规则

`hseg` 对列表递归：空列表不拥有元素单元；非空列表把首元素放在下标 `j`，余下元素从下标 `j+1` 开始。由此得到

\[
\operatorname{hseg}(L_1++L_2,p,j)
=\operatorname{hseg}(L_1,p,j)*
\operatorname{hseg}(L_2,p,j+|L_1|).
\]

这条 `hseg_app` 是区间推理的核心。`hseg_cons`、`hseg_last` 分别隔离首、尾单元；带 `_r` 的三条引理是反方向的蕴含形式，下标只需满足算术等式，不必在语法上已经相同。它们很适合 `xchange <-`：验证完局部代码后，把借出的单元重新合并为区间。

区间上的 `get`、`set` 使用相对下标 `i-j`，因此边界条件是 `0 <= i-j < length L`。`make` 则同时返回头单元和从下标零开始的完整区间。

```coq
(* ---------- 104.3 数组区间 hseg ---------- *)

Fixpoint hseg (L:list val) (p:loc) (j:int) : hprop :=
  match L with
  | nil => \[]
  | x::L' => (hcell x p j) \* (hseg L' p (j+1))
  end.

Lemma hseg_nil : forall p j,
  hseg nil p j = \[].
Proof using. auto. Qed.

Lemma hseg_one : forall v p j,
  hseg (v::nil) p j = hcell v p j.
Proof using. intros. simpl. xsimpl*. Qed.

Parameter hseg_app : forall p j L1 L2,
    hseg (L1 ++ L2) p j
  = hseg L1 p j \* hseg L2 p (j + length L1).

Lemma hseg_cons : forall v p j L,
  hseg (v::L) p j = hcell v p j \* hseg L p (j+1).
Proof using. auto. Qed.

Lemma hseg_last : forall v p j L,
  hseg (L&v) p j = hseg L p j \* hcell v p (j+length L).
Proof using. intros. rewrite hseg_app. rewrite hseg_cons, hseg_nil. xsimpl. Qed.

Lemma hseg_cons_r : forall L v p j1 j2,
  j2 = j1 + 1 ->
  hcell v p j1 \* hseg L p j2 ==> hseg (v::L) p j1.
Proof using. intros. subst. rewrite* hseg_cons. Qed.

Lemma hseg_app_r : forall p L1 L2 j1 j2,
  j2 = j1 + length L1 ->
  hseg L1 p j1 \* hseg L2 p j2 ==> hseg (L1 ++ L2) p j1.
Proof using. intros. subst. rewrite* hseg_app. Qed.

Lemma hseg_last_r : forall v p j L j',
  j' = (j+length L) ->
  hseg L p j \* hcell v p j' ==> hseg (L&v) p j.
Proof using. intros. subst. rewrite* hseg_last. Qed.

Parameter triple_array_make_hseg : forall n v,
  n >= 0 ->
  triple (val_array_make n v)
    \[]
    (funloc p => hheader (abs n) p \* hseg (LibList.make (abs n) v) p 0).

Parameter triple_array_get_hseg : forall L p i j,
  0 <= i - j < length L ->
  triple (val_array_get p i)
    (hseg L p j)
    (fun r => \[r = LibList.nth (abs (i-j)) L] \* hseg L p j).

Parameter triple_array_set_hseg : forall L p i j v,
  0 <= i - j < length L ->
  triple (val_array_set p i v)
    (hseg L p j)
    (fun _ => hseg (LibList.update (abs (i-j)) v L) p j).
```

---

## 104.4 原书练习一：快速排序的安全性

`pivot p i n` 重排长度至少为一的区间，返回枢轴最终下标 `j`。安全性规格只承诺：区间长度不变，新内容可写成 `L1 ++ val_int x :: L2`，且枢轴左侧长度恰为 `j-i`。它不承诺有序，也不承诺排列。

快速排序先划分，再递归处理 `[i,j)` 与 `[j+1,i+n)`。证明对 `n` 使用 `downto 0` 良基归纳：左递归长度为 `j-i < n`，右递归长度为 `n-(j-i)-1 < n`，且两者都非负。

堆推理与递归结构一一对应：

1. 用 `hseg_app` 和 `hseg_cons` 把划分后的资源拆成左区间、枢轴单元、右区间；
2. 第一次 `xapp (>> IH L1)` 只消耗左区间；
3. 中间三个 `xapp` 计算右区间起点和长度；
4. 第二次递归只消耗右区间；
5. 反向合并区间，给出长度不变的最终列表。

`unfold downto in IH` 让递归测度侧条件显式变成算术不等式；显式交换两个分离合取项，则让 `hseg_app_r` 看到它所期望的“左区间 * 右区间”顺序。

```coq
(* ---------- 104.4 快速排序的安全性 ---------- *)

Module QuickSort.
Export NotationForVariables.

Parameter val_pivot : val.

Parameter triple_pivot_safety : forall p i n L,
  n = length L ->
  n >= 1 ->
  triple (val_pivot p i n)
    (hseg L p i)
    (fun r => \exists (j:int), \[r = val_int j] \*
              \exists (x:int) (L' L1 L2:list val), hseg L' p i \* \[
                  length L' = length L
               /\ L' = L1 ++ val_int x :: L2
               /\ j - i = length L1 ]).

Definition val_quicksort : val :=
  <{ fix 'f 'p 'i 'n =>
       let 'b = 'n > 1 in
       if 'b then
         let 'j = val_pivot 'p 'i 'n in
         let 'n1 = 'j - 'i in
         'f 'p 'i 'n1;
         let 'i2 = 'j + 1 in
         let 'n3 = 'n - 'n1 in
         let 'n2 = 'n3 - 1 in
         'f 'p 'i2 'n2
       end }>.

(* 原书练习（4 星）：递归调用只拥有各自区间，枢轴单元与区间外资源均被框架保留。 *)

Lemma triple_quicksort_safety : forall p i n L,
  n = length L ->
  i >= 0 ->
  triple (val_quicksort p i n)
    (hseg L p i)
    (fun _ => \exists L', \[length L' = length L] \* hseg L' p i).
Proof using.
  introv Hn Hi. gen i L. induction_wf IH: (downto 0) n. unfold downto in IH. intros.
  xwp. xapp. xif; intros C.
  { xapp triple_pivot_safety; try math.
    intros j x L' L1 L2 (HL'&->&Hj). rew_list in *. xapp.
    xchange hseg_app. xchange hseg_cons.
    math_rewrite (i + length L1 = j).
    xapp (>> IH L1); rew_list*; try math.
    intros L1' HL1'. xapp. xapp. xapp.
    xapp (>> IH L2); rew_list*; try math.
    intros L2' HL2'. xchange <- hseg_cons.
    rewrite (hstar_comm (hseg (val_int x::L2') p j) (hseg L1' p i)).
    xchange (>> hseg_app_r p L1' (val_int x::L2') i j). { math. } xsimpl*.
    rew_list in *. math. }
  { xval. xsimpl*. }
Qed.
```

当 `n <= 1` 时函数直接返回，原列表已经满足长度不变的后条件。至此证明的是内存安全与终止性，还没有证明输出确实是有序排列。

---

## 104.5 排列与有序列表

功能正确性需要两个纯逻辑概念。

`permut L L'` 表示两个列表只差元素顺序。构造子 `permut_mid` 允许交换任意两个连续区块，`permut_trans` 允许组合多次交换。由这两条规则可以证明自反性、对称性、长度不变，以及排列在列表拼接、`cons`、末尾追加下的同余性。`permut_Forall` 说明排列不会改变元素集合所满足的全称性质，后面用它把“左半部分不大于枢轴”“右半部分大于枢轴”传递到递归排序后的列表。

`sorted` 用相邻元素关系归纳定义非递减列表。`list_of_le x L1` 与 `list_of_gt x L2` 分别描述枢轴左右性质。`sorted_app_le` 把三份事实组合成 `sorted (L1 ++ x :: L2)`：左列表有序且元素不大于 `x`，右列表在 `x` 后有序且元素大于 `x`。

源语言堆中的元素类型是 `val`，逻辑排序关系却定义在 `int` 上，所以 `vals_int` 逐项应用 `val_int`。相应重写引理让 `rew_list` 能把映射与 `nil`、`cons`、拼接、末尾追加和长度计算交换。

```coq
(* ---------- 104.5 排列与有序列表 ---------- *)

Inductive permut (A:Type) : list A -> list A -> Prop :=
  | permut_mid : forall L1 L2 L3 L4,
      permut (L1 ++ L2 ++ L3 ++ L4) (L1 ++ L3 ++ L2 ++ L4)
  | permut_trans : forall L3 L1 L2,
      permut L1 L2 ->
      permut L2 L3 ->
      permut L1 L3.

Lemma permut_refl : forall A (L:list A),
  permut L L.
Proof using. intros. applys permut_mid (@nil A) (@nil A) (@nil A) L. Qed.

Lemma permut_sym : forall A (L1 L2: list A),
  permut L1 L2 ->
  permut L2 L1.
Proof using.
  introv M. induction M.
  { applys* permut_mid. }
  { applys* permut_trans IHM2. }
Qed.

#[local] Hint Resolve permut_refl.

Lemma permut_length : forall A (L L':list A),
  permut L L' ->
  length L = length L'.
Proof using. introv M. induction M; rew_list in *; try math. Qed.

Lemma permut_app : forall A (L1 L2 L1' L2':list A),
  permut L1 L1' ->
  permut L2 L2' ->
  permut (L1 ++ L2) (L1' ++ L2').
Proof using.
  introv M1 M2. applys permut_trans (L1' ++ L2).
  { clear M2. induction M1.
    { rew_list. applys permut_mid. }
    { applys* permut_trans IHM1_2. } }
  { clear M1. induction M2.
    { repeat rewrite <- (app_assoc L1'). applys permut_mid. }
    { applys* permut_trans IHM2_2. } }
Qed.

Lemma permut_cons : forall A (x:A) L1 L1',
  permut L1 L1' ->
  permut (x :: L1) (x :: L1').
Proof using. intros. applys* permut_app (x::nil) L1 (x::nil) L1'. Qed.

Lemma permut_last : forall A (x:A) L1 L1',
  permut L1 L1' ->
  permut (L1 & x) (L1' & x).
Proof using. intros. applys* permut_app L1 (x::nil) L1' (x::nil). Qed.

Lemma permut_swap_first_two : forall A (x y : A) (L:list A),
  permut (x :: y :: L) (y :: x :: L).
Proof using. intros. applys permut_mid (@nil A) (x::nil) (y::nil) L. Qed.

Lemma permut_swap_first_last : forall A (x : A) (L:list A),
  permut (x::L) (L&x).
Proof using.
  intros. applys_eq (>> permut_mid (@nil A) (x::nil) L (@nil A)). rew_list*.
Qed.

Lemma permut_Forall : forall A (P:A->Prop) L L',
  Forall P L ->
  permut L L' ->
  Forall P L'.
Proof using.
  introv N M. gen N. induction M; intros; auto.
  { repeat rewrite Forall_app_eq in *. autos*. }
Qed.

Inductive sorted : list int -> Prop :=
  | sorted_nil : sorted nil
  | sorted_one : forall x, sorted (x :: nil)
  | sorted_cons : forall x y L,
      x <= y ->
      sorted (y :: L) ->
      sorted (x :: y :: L).

Definition list_of_gt (x:int) (L:list int) : Prop :=
  Forall (fun y => y > x) L.

Definition list_of_le (x:int) (L:list int) : Prop :=
  Forall (fun y => y <= x) L.

Lemma sorted_cons_gt : forall x L,
  list_of_gt x L ->
  sorted L ->
  sorted (x :: L).
Proof using.
  introv N M. destruct L as [|].
  { applys sorted_one. }
  { lets (Hv&_): Forall_cons_inv N. applys* sorted_cons. math. }
Qed.

Lemma sorted_app_le : forall x L1 L2,
  list_of_le x L1 ->
  sorted L1 ->
  sorted (x :: L2) ->
  sorted (L1 ++ x :: L2).
Proof using.
  introv N M1 M2. induction M1; rew_list in *. { auto. }
  { lets (Hv&_): Forall_cons_inv N. applys* sorted_cons. }
  { lets (_&N'): Forall_cons_inv N. applys* sorted_cons. }
Qed.

(* vals_int 把整数逻辑列表映射为源语言值列表。 *)

Definition vals_int (L:list int) : list val :=
  LibList.map val_int L.

Lemma vals_int_nil : vals_int nil = nil.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma vals_int_cons : forall x L,
  vals_int (x :: L) = val_int x :: vals_int L.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma vals_int_app : forall L1 L2,
  vals_int (L1 ++ L2) = vals_int L1 ++ vals_int L2.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma vals_int_last : forall x L,
  vals_int (L & x) = vals_int L & val_int x.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

Lemma length_vals_int : forall L,
  length (vals_int L) = length L.
Proof using. intros. unfold vals_int. rew_listx*. Qed.

#[local] Hint Rewrite vals_int_nil vals_int_cons vals_int_app
    vals_int_last length_vals_int : rew_list.
#[local] Hint Rewrite vals_int_nil vals_int_cons vals_int_app
    vals_int_last length_vals_int : rew_listx.
```

---

## 104.6 原书练习二、三：功能正确性与整数组排序

加强后的 `triple_pivot` 同时给出四份逻辑信息：新列表是原列表的排列；它能拆成 `L1 ++ x :: L2`；枢轴下标由 `length L1` 决定；左右元素分别满足 `list_of_le` 与 `list_of_gt`。

### 104.6.1 递归区间的功能正确性

`triple_quicksort` 的堆证明与安全性证明相同，但每个递归调用还返回排列和有序性事实。设左右递归结果为 `L1'`、`L2'`，最终见证必须取 `L1' ++ x :: L2'`：

- 排列性由 `HP`、`HP1`、`HP2` 经 `permut_trans`、`permut_app`、`permut_cons` 组合；
- 左侧的 `list_of_le` 经 `permut_Forall HP1` 传递给 `L1'`；
- 右侧的 `list_of_gt` 经 `permut_Forall HP2` 传递给 `L2'`；
- `sorted_app_le` 与 `sorted_cons_gt` 完成有序性证明。

这里显式写 `xsimpl (L1' ++ x :: L2')` 很关键。如果让自动化提前实例化存在量词，它可能把结果列表错定为枢轴刚结束时尚未递归排序的列表，后续排列和有序性目标就会失去所需归纳假设。

基础分支只有空列表和单元素列表两种可能，因为条件分支已经排除 `n > 1`，而 `n = length L`。两者都直接取原列表为见证。

```coq
(* ---------- 104.6 快速排序的功能正确性 ---------- *)

Parameter triple_pivot : forall n p i L,
  n = length L ->
  n >= 1 ->
  triple (val_pivot p i n)
    (hseg (vals_int L) p i)
    (fun r => \exists j, \[r = val_int j] \*
              \exists x L' L1 L2, hseg (vals_int L') p i \* \[
                  permut L L'
               /\ L' = L1 ++ x :: L2
               /\ j - i = length L1
               /\ list_of_le x L1
               /\ list_of_gt x L2 ]).

(* 原书练习（5 星，可选）：在安全性证明上增加排列与有序性不变式。 *)

Lemma triple_quicksort : forall p i n L,
  n = length L ->
  i >= 0 ->
  triple (val_quicksort p i n)
    (hseg (vals_int L) p i)
    (fun _ => \exists L', \[permut L L' /\ sorted L']
                          \* hseg (vals_int L') p i).
Proof using.
  introv Hn Hi. gen i L. induction_wf IH: (downto 0) n. unfold downto in IH. intros.
  xwp. xapp. xif; intros C.
  { xapp triple_pivot; try math.
    intros j x L' L1 L2 (HP&->&Hj&Hle&Hgt).
    lets HL': permut_length HP. rew_list in *. xapp.
    rew_listx. xchange hseg_app. xchange hseg_cons. rew_listx.
    math_rewrite (i + length L1 = j).
    xapp (>> IH L1); rew_list*; try math.
    intros L1' (HP1&HS1). xapp. xapp. xapp.
    xapp (>> IH L2); rew_list*; try math.
    intros L2' (HP2&HS2). xchange <- hseg_cons.
    lets E1: permut_length HP1.
    rewrite (hstar_comm (hseg (val_int x::vals_int L2') p j)
                        (hseg (vals_int L1') p i)).
    xchange (>> hseg_app_r p (vals_int L1') (val_int x::vals_int L2') i j).
    { rew_list. math. } xsimpl (L1' ++ x :: L2').
    { splits.
      { applys permut_trans HP. applys permut_app HP1. applys permut_cons HP2. }
      { applys sorted_app_le.
        { unfold list_of_le in *. eapply permut_Forall; [exact Hle | exact HP1]. }
        { auto. }
        { applys sorted_cons_gt.
          { unfold list_of_gt in *. eapply permut_Forall; [exact Hgt | exact HP2]. }
          { auto. } } } }
    { rew_list*. } }
  { xval. destruct L as [|x [|]]; rew_list in *; try (false; math).
    { xsimpl (@nil int). splits. applys permut_refl. applys sorted_nil. }
    { xsimpl (x::nil). splits. applys permut_refl. applys sorted_one. } }
Qed.
```

### 104.6.2 从完整数组进入区间证明

`val_quicksort_full` 先读取数组长度，再从下标零排序整个数组。`harray_eq` 把大足迹展开为“存在长度 `n` 的头单元 * 完整区间”。证明先读取头单元，再调用区间规格。返回时用排列保持长度这一事实重建 `harray`，所以最终后条件仍然只暴露完整数组，不暴露内部区间。

```coq
Definition val_quicksort_full : val :=
  <{ fun 'p =>
       let 'n = val_array_length 'p in
       val_quicksort 'p 0 'n }>.

Parameter harray_eq : forall p L,
  harray L p = \exists n, \[n = length L] \* hheader n p \* hseg L p 0.

(* 原书练习（2 星，可选）：把整数组规格转换为头单元加完整区间。 *)

Lemma triple_quicksort_full : forall p L,
  triple (val_quicksort_full p)
    (harray (vals_int L) p)
    (fun _ => \exists L', \[permut L L' /\ sorted L']
              \* harray (vals_int L') p).
Proof using.
  intros. xwp. xchange harray_eq. xpull. intros n Hn. rew_list in Hn. subst n.
  xapp triple_array_length_hheader. xapp triple_quicksort; rew_list*; try math.
  intros L' (HP&HS). lets E: permut_length HP.
  xchange <- harray_eq. { rew_list. math. } xsimpl*.
Qed.

End QuickSort.
```

---

## 104.7 原书练习四：具体堆表示与区间拆分

前面的数组谓词都是抽象的。`Realization` 模块现在给出一种符合 ML 风格布局的实现：长度为 `n` 的数组占用 `n+1` 个连续单元，地址 `p` 的头单元保存 `n`，第 `i` 个元素位于地址 `p+1+i`。

`hcell` 还包含纯事实 `i >= 0`，防止把负数下标经 `abs` 错当成合法元素。`hcell_nonneg` 展示如何复制这份纯事实：堆资源仍只出现一次，而命题可以任意使用。

在这个实现中，`harray` 就是头单元与完整元素区间的分离合取。`hseg_start_eq` 把区间起点等式转换成蕴含，并注册为提示，使 `xsimpl` 能借助算术证明对齐语法不同的下标。

### 104.7.1 归纳证明 `hseg_app`

原书第四个练习要求证明区间追加等式。对 `L1` 归纳：

- 空列表时，左边就是 `hseg L2 p j`，右边的空区间化为空堆，且 `j+0=j`；
- `x::L1'` 时，先展开首单元，再使用归纳假设，最后用分离合取结合律和 `S (length L1') = length L1' + 1` 对齐右区间起点。

这里直接证明堆谓词等式，比把它转成两条蕴含更清楚。`rewrite <- Nat.add_1_r` 先把自然数后继改成加法，剩余的整数下标等式由 `math` 完成。

```coq
(* ---------- 104.7 头部、单元格与整数组的具体表示 ---------- *)

Module Realization.

Definition hheader (n:int) (p:loc) : hprop :=
  p ~~> (val_int n).

Lemma hheader_eq : forall p n,
  (hheader n p) = (p ~~> (val_int n)).
Proof using. auto. Qed.

Definition hcell (v:val) (p:loc) (i:int) : hprop :=
  ((p + 1 + abs i)%nat ~~> v) \* \[i >= 0].

Lemma hcell_eq : forall v p i,
  (hcell v p i) = ((p + 1 + abs i)%nat ~~> v) \* \[i >= 0].
Proof using. auto. Qed.

Lemma hcell_nonneg : forall v p i,
  hcell v p i ==> hcell v p i \* \[i >= 0].
Proof using. unfold hcell. xsimpl*. Qed.

Fixpoint hseg (L:list val) (p:loc) (j:int) : hprop :=
  match L with
  | nil => \[]
  | x::L' => (hcell x p j) \* (hseg L' p (j+1))
  end.

Definition harray (L:list val) (p:loc) : hprop :=
  hheader (length L) p \* hseg L p 0.

Lemma harray_eq : forall p L,
  harray L p = \exists n, \[n = length L] \* hheader n p \* hseg L p 0.
Proof using. unfold harray. xsimpl*. { intros; subst*. } Qed.

Lemma hseg_start_eq : forall L p j1 j2,
  j1 = j2 ->
  hseg L p j1 ==> hseg L p j2.
Proof using. intros. subst*. Qed.

#[local] Hint Extern 1 (hseg ?L ?p ?j1 ==> hseg ?L ?p ?j2) =>
  apply hseg_start_eq; math.

Lemma hseg_nil : forall p j,
  hseg nil p j = \[].
Proof using. auto. Qed.

Lemma hseg_one : forall v p j,
  hseg (v::nil) p j = hcell v p j.
Proof using. intros. simpl. xsimpl*. Qed.

Lemma hseg_cons : forall v p j L,
  hseg (v::L) p j = hcell v p j \* hseg L p (j+1).
Proof using. intros. simpl. xsimpl*. Qed.

(* 原书练习（3 星）：对 L1 归纳，利用分离合取的结合律和长度算术。 *)

Lemma hseg_app : forall L1 L2 p j,
    hseg (L1 ++ L2) p j
  = hseg L1 p j \* hseg L2 p (j + length L1).
Proof using.
  intros L1. induction L1 as [|x L1']; intros; rew_list.
  { simpl. rewrite hstar_hempty_l. fequals_rec. math. }
  { simpl. rewrite IHL1'. rewrite <- Nat.add_1_r. rewrite hstar_assoc.
    replace (j + (length L1' + 1)%nat) with (j + 1 + length L1') by math.
    reflexivity. }
Qed.
```

---

## 104.8 原书练习五、六：聚焦与归还魔杖

数组读取的小足迹规格只要求一个 `hcell`，但客户端可能开始时拥有整个 `hseg` 或 `harray`。聚焦规则连接两种视角：从大资源中借出目标单元，并保留一个魔杖，说明归还单元后如何恢复更新后的大资源。

### 104.8.1 相对下标聚焦

对合法的相对下标 `k`，`list_middle_inv` 把列表分解为 `L1 ++ v :: L2`，并给出 `length L1 = k`。于是：

- `hseg_app` 分出前缀 `L1`；
- `hseg_cons` 分出中间单元 `v` 与后缀 `L2`；
- `hcell v p (j+k)` 可以立即借出；
- 对任意新值 `w`，归还 `hcell w p (j+k)` 后，列表库给出 `update k w (L1++v::L2) = L1 ++ w :: L2`，反向应用拆分规则便恢复新区间。

魔杖前的 `\forall w` 很重要：调用者可以把借出的单元修改为任意值，而不必归还原来的 `v`。证明中的 `subst k` 统一下标表达式；`typeclass` 和 `auto` 分别关闭列表更新引理的类型类与长度侧条件。

```coq
(* ---------- 104.8 聚焦：借出一个单元并保留归还魔杖 ---------- *)

(* 原书练习（4 星）：把列表分成 L1 ++ v :: L2，再聚焦中间单元。 *)

Lemma hseg_focus_relative : forall (k:nat) L p j,
  0 <= k < length L ->
      hseg L p j
  ==> let v := LibList.nth k L in
         hcell v p (j+k)
      \* (\forall w, hcell w p (j+k) \-* hseg (LibList.update k w L) p j).
Proof using.
  introv Hk. lets (L1&v&L2&->&HL1): LibList.list_middle_inv k L. { math. }
  subst k. rewrite LibList.nth_middle; [|auto]. rewrite hseg_app. simpl.
  xsimpl. intros w. rewrite LibList.update_middle.
  { rew_list. rewrite hseg_app. simpl. xsimpl*. }
  { typeclass. }
  { auto. }
Qed.

Arguments hseg_focus_relative : clear implicits.
```

### 104.8.2 绝对下标与完整数组聚焦

绝对下标版本只需令 `k = abs (i-j)`。合法边界给出 `j + abs (i-j) = i`，所以相对规则中的单元地址恰好是绝对下标 `i`。

完整数组版本在头单元之外应用区间聚焦。归还更新后的单元时，`length_update` 保证列表长度不变，因此原头单元仍然正确，可以重建 `harray`。

```coq
Lemma hseg_focus : forall i L p j,
  0 <= i-j < length L ->
      hseg L p j
  ==> let v := LibList.nth (abs (i-j)) L in
         hcell v p i
      \* (\forall w, hcell w p i \-* hseg (LibList.update (abs (i-j)) w L) p j).
Proof using.
  introv Hk. xchange (hseg_focus_relative (abs (i-j))). { math. }
  math_rewrite (j + abs (i - j) = i). xsimpl.
Qed.

Arguments hseg_focus : clear implicits.

Lemma harray_focus : forall i L p,
  0 <= i < length L ->
      harray L p
  ==> let v := LibList.nth (abs i) L in
         hcell v p i
      \* (\forall w, hcell w p i \-* harray (LibList.update (abs i) w L) p).
Proof using.
  introv Hi. unfold harray. xchange (hseg_focus i). { math. }
  math_rewrite (i - 0 = i). xsimpl. intros w.
  xchange (hforall_specialize w). xsimpl.
  rewrite* LibList.length_update.
Qed.

Arguments harray_focus : clear implicits.
```

### 104.8.3 只读聚焦

只读访问不修改单元，因此归还的仍是原值 `nth (abs i) L`。把可写聚焦中的全称量词特化为这个值，再使用 `update_nth_same`：用原值更新原位置不会改变列表。得到的魔杖直接恢复原来的 `harray L p`，不再需要 `update`。

这正是只读小足迹规格所需的形状：先借出 `hcell v p i`，读取后把同一单元归还，整个数组内容保持不变。

```coq
(* 原书练习（3 星，可选）：把可写聚焦中的 w 实例化为原值。 *)

Lemma harray_focus_read : forall i L p,
  0 <= i < length L ->
      harray L p
  ==> let v := LibList.nth (abs i) L in
      hcell v p i \* (hcell v p i \-* harray L p).
Proof using.
  introv Hi. xchange (harray_focus i). { math. }
  xsimpl. xchange (hforall_specialize (LibList.nth (abs i) L)).
  rewrite LibList.update_nth_same.
  { xsimpl*. }
  { math. }
Qed.

Arguments harray_focus_read : clear implicits.

End Realization.

End Arrays.
```

---

## 104.9 本章练习与验收

| 原书练习 | 本章结论 | 证明要点 |
|---|---|---|
| `triple_quicksort_safety` | 快速排序安全且终止 | `downto 0` 良基归纳、左右区间分离、区间合并 |
| `triple_quicksort` | 输出是原输入的有序排列 | 排列同余、`Forall` 传递、有序拼接、显式存在见证 |
| `triple_quicksort_full` | 完整数组排序规格 | 大足迹与“头单元 * 完整区间”互换 |
| `hseg_app` | 连续列表对应可拆分区间的堆 | 列表归纳、分离合取结合律、下标算术 |
| `hseg_focus_relative` | 借出任意相对位置并保留更新魔杖 | 列表中段分解、区间拆分与逆向合并 |
| `harray_focus_read` | 只读借出后恢复原数组 | 特化原值、`update_nth_same` |

本章体现的核心方法是：**规格按实际访问的足迹陈述，证明按需要拆分资源，再用魔杖或区间等式恢复抽象资源。** 这样既避免重复拥有数组，也让递归和局部读写都能使用最简洁的前条件。

可在 `coq` 目录执行：

```bash
./build.sh -File 104_slf_arrays.v
python3 tools/check_docs_coverage.py 104 --mutate
```

第一条命令检查所有定义和六个练习均可由 rocq 9.1.1 编译；第二条命令检查示例的每一行非空内容（包括中文注释）都出现在本文的 Coq 代码块中，并通过删除行变异测试确认覆盖检查确实有效。

