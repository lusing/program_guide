# 47 · 四色定理

对应示例：`../examples/47_color.v`（`Module Ex47Color`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

四色定理（任何平面地图四种颜色足够）是数学史上第一例**计算机辅助证明**（Appel–Haken 1976：上千种构形的机器穷举），也是后来 Gonthier 等人 2005 年在 Coq 里完成**全形式化**验证（含证明检查器本身的正确性）的里程碑。VFA 的 Color 章取其中**可教学的核心**：不证四色定理本身，而是搭建它所依赖的**证明工程基础设施**——用标准库的 `FSets`/`FMaps`（`positive` 键的函数式集合与映射）表示图，写一个贪心 K-着色程序，并证明它产出的着色**永不冲突**。这一章因此是全卷的「工程收尾」：不再发明新算法，而是把 33–46 章的所有手法（表示不变量、代数规格、measure 递归、fold 推理）拉到标准库重武器库上打一场阵地战。

三段式主线：**库的驯化**（47.1–47.4——`Sorted`/`InA`/`equivlistA` 这套「带等价的列表推理」工具链，以及两条「删一个元素、基数严格变小」的关键引理）；**图与程序**（47.5–47.7——图表示、低度数选点、`Function measure` 的 select、贪心 color1）；**正确性与试跑**（47.8–47.9——`color_correct` 主定理 + 一张 7 边图三色全着上的 `Compute` 实测）。

### 47.1 表示图：positive 节点 + 函数式集合/映射

文件头与库的选型：

```coq
(* 47 四色定理 —— 图着色：用 FSets/FMaps 做证明工程 *)

From Stdlib Require Import List Setoid FSets FMaps PArith Arith Recdef.
Import ListNotations.

Module Ex47Color.

(* ---------- 47.1 表示图：positive 节点 + 函数式集合/映射 ---------- *)

Module E := PositiveOrderedTypeBits.
Module S <: FSetInterface.S := PositiveSet.
Module M <: FMapInterface.S := PositiveMap.
Module WF := WFacts_fun E M.
Module WP := WProperties_fun E M.

Lemma lt_strict : StrictOrder E.lt.
Proof. exact M.ME.MO.IsTO.lt_strorder. Qed.

Lemma lt_proper : Proper (eq ==> eq ==> iff) E.lt.
Proof. exact M.ME.MO.IsTO.lt_compat. Qed.

Definition Mdomain {A} (m : M.t A) : S.t :=
   M.fold (fun n _ s => S.add n s) m S.empty.

Definition example_map : M.t S.t :=
  (M.add 3%positive S.empty
   (M.add 9%positive S.empty
    (M.add 2%positive S.empty (M.empty S.t   )))).

Example domain_example_map :
    S.elements (Mdomain example_map) = [2;9;3]%positive.
Proof. compute. reflexivity. Qed.
```

图的节点用第 45 章手造过的 `positive`（这里直接取标准库实现）；边表用**函数式集合** `S`（`PositiveSet`：positive 上的集合）、邻接表用**函数式映射** `M`（`PositiveMap`）。`S`/`M` 都以 **`FSetInterface.S`/`FMapInterface.S` 签名**约束——第 42 章 Module Type 方法论的库级应用：证明只依赖接口、不依赖内部表示。`WF`/`WP` 是库配套的「事实集」与「性质集」（fold/find 的iff 包装），后面反复调用。

头两行引理是**驯化仪式**：库的列表工具全要求 `ltA` 同时是 `StrictOrder`（严格序）且 `Proper`（**对等价替换封闭**——setoid 推理的世界观），这两条从 `M` 内部的模块深路径里挖出来（`M.ME.MO.IsTO.lt_strorder`——`Print M.ME.MO` 可以看到这条路径的来历）。`Mdomain` 用 `M.fold` 把映射的键收集成集合；`example_map` 的域实测算出 `[2;9;3]`——注意 `%positive` 标注与**输出乱序**（fold 的顺序由库决定，47.2 就要驯服它）。

### 47.2 排序列表工具：Sorted / InA / equivlistA

```coq
(* ---------- 47.2 排序列表工具：Sorted / InA / equivlistA ---------- *)

Check SortA_equivlistA_eqlistA.
(*  : forall (A : Type) (eqA : A -> A -> Prop),
       Equivalence eqA ->
       forall ltA : A -> A -> Prop,
       StrictOrder ltA ->
       Proper (eqA ==> eqA ==> iff) ltA ->
       forall l l' : list A,
       Sorted ltA l ->
       Sorted ltA l' -> equivlistA eqA l l' -> eqlistA eqA l l' *)

Lemma eqlistA_Eeq_eq : forall al bl, eqlistA E.eq al bl <-> al = bl.
Proof.
split; intro H.
- induction H as [| x y l l' Hxy Hl IH]; simpl.
  + reflexivity.
  + unfold E.eq in Hxy. rewrite Hxy. f_equal. exact IH.
- subst. induction bl as [| b l IH].
  + constructor.
  + constructor; [reflexivity | exact IH].
Qed.

Lemma SortE_equivlistE_eqlistE :
 forall al bl, Sorted E.lt al ->
                   Sorted E.lt bl ->
                   equivlistA E.eq al bl -> eqlistA E.eq al bl.
Proof.
intros al bl H1 H2 H3.
apply SortA_equivlistA_eqlistA with (ltA := E.lt).
- apply eq_equivalence.
- apply lt_strict.
- apply lt_proper.
- assumption.
- assumption.
- assumption.
Qed.

Lemma filter_sortE : forall f l,
     Sorted E.lt l -> Sorted E.lt (List.filter f l).
Proof.
intros f l H.
apply filter_sort with (eqA := E.eq) (ltA := E.lt).
- apply eq_equivalence.
- apply lt_strict.
- apply lt_proper.
- exact H.
Qed.

Lemma InA_eq_In : forall (A : Type) (l : list A) (x : A),
  InA (@eq A) x l -> In x l.
Proof.
intros A l x H. apply InA_alt in H.
destruct H as [y [Hxy Hin]]. rewrite Hxy. exact Hin.
Qed.
```

库的 `Sorted`/`InA`/`equivlistA`/`eqlistA` 是普通 `sorted`/`In`/`Permutation`（33–37 章那套）的 **setoid 泛化版**：`InA eqA x l` 是「l 中存在与 x 等价的元素」、`equivlistA eqA l l'` 是「同元素集（按 eqA）」、`eqlistA eqA l l'` 是「逐元素等价」。核心库定理 `SortA_equivlistA_eqlistA`（`Check` 出的六前提形态）：**两张有序表只要元素集相同，就逐元素相同**——「有序 + 同集 ⇒ 唯一」，这是驯服 `S.elements` 乱序的总钥匙。四个引理是它的 instance 化流水线：`eqlistA_Eeq_eq` 把「E.eq 逐元素等价」兑换回普通的 `=`（E.eq 就是 positive 的库内等价，`unfold` 后就是 `eq`）；`SortE_equivlistE_eqlistE` 六个前提逐个上货（`eq_equivalence` 说 `eq` 是等价关系——连这个都要交代，setoid 世界不赊账）；`filter_sortE` 说 filter 保序；`InA_eq_In` 把 InA 兑回 In。**「泛化定义 ↔ 普通定义」的兑换所**开张，后面所有证明都要来这里换钱。

### 47.3 S.remove 与 S.elements

```coq
(* ---------- 47.3 S.remove 与 S.elements ---------- *)

Lemma Proper_eq_eq :
  forall f, Proper (E.eq ==> @eq bool) f.
Proof.
unfold Proper, respectful. intros f x y H.
unfold E.eq in H. rewrite H. reflexivity.
Qed.

Lemma Sremove_elements :  forall (i : E.t) (s : S.t),
  S.In i s ->
     S.elements (S.remove i s) =
         List.filter (fun x => if E.eq_dec x i then false else true) (S.elements s).
Proof.
intros i s H.
apply eqlistA_Eeq_eq.
apply SortE_equivlistE_eqlistE.
- apply S.elements_3.
- apply filter_sortE. apply S.elements_3.
- intro j. rewrite filter_InA; [ | apply Proper_eq_eq].
  destruct (E.eq_dec j i) as [Heq | Hne].
  + split; intro HH.
    * exfalso. apply S.elements_2 in HH.
      exact (S.remove_1 s (eq_sym Heq) HH).
    * destruct HH as [H1 H2]. simpl in H2. discriminate H2.
  + split; intro HH.
    * apply S.elements_2 in HH. split.
      -- apply S.elements_1. apply (S.remove_3 s i). exact HH.
      -- destruct (E.eq_dec j i); [contradiction | reflexivity].
    * destruct HH as [H1 H2]. destruct (E.eq_dec j i); [contradiction | idtac].
      apply S.elements_1. apply S.remove_2.
      -- apply not_eq_sym. exact Hne.
      -- apply S.elements_2. exact H1.
Qed.

Lemma filter_length_le : forall (A : Type) (f : A -> bool) (l : list A),
  length (List.filter f l) <= length l.
Proof.
induction l as [| a l IH]; simpl.
- apply Nat.le_refl.
- destruct (f a); simpl.
  + apply le_n_S. exact IH.
  + apply Nat.le_le_succ_r. exact IH.
Qed.

Lemma filter_InA_length_lt :
  forall (A : Type) (eqA : A -> A -> Prop) (f : A -> bool) (l : list A) (x : A),
    InA eqA x l -> Proper (eqA ==> @eq bool) f -> f x = false ->
    length (List.filter f l) < length l.
Proof.
intros A eqA f l x.
induction l as [| a l IH]; intros Hin Hprop Hfx; simpl in *.
- inversion Hin.
- inversion Hin as [l0 y Hxa | l0 y Hin0]; subst; simpl.
  + assert (Hfa : f a = false).
    { rewrite <- (Hprop x a Hxa). exact Hfx. }
    rewrite Hfa. simpl.
    apply Nat.le_lt_trans with (length l).
    * apply filter_length_le.
    * apply Nat.lt_succ_diag_r.
  + destruct (f a); simpl.
    * apply (proj1 (Nat.succ_lt_mono _ _)). apply IH; assumption.
    * apply Nat.lt_lt_succ_r. apply IH; assumption.
Qed.

Lemma Sremove_cardinal_less : forall i s,
        S.In i s ->    S.cardinal (S.remove i s) < S.cardinal s.
Proof.
intros i s H.
repeat rewrite S.cardinal_1.
rewrite (Sremove_elements i s H).
apply filter_InA_length_lt with (eqA := E.eq) (x := i).
- apply S.elements_1. exact H.
- apply Proper_eq_eq.
- destruct (E.eq_dec i i) as [_ | Hii]; [reflexivity | exfalso; apply Hii; reflexivity].
Qed.
```

本节的目标是一句话：**删掉一个在集合里的元素，基数严格变小**（`Sremove_cardinal_less`）。它为什么值一整节？因为 `S` 是抽象接口——`S.remove` 和 `S.cardinal` 都没有计算定义可展开，唯一的窗口是 `S.cardinal_1`（基数 = elements 长度）和 `S.elements_*` 一族（elements_1/2/3：In ↔ 在表里、表有序）。于是路线是：`Sremove_elements` 先证「remove 后的 elements = 原 elements 过滤掉 i」（两侧都有序，所以用 47.2 的总钥匙 `SortE_equivlistE_eqlistE` 把**等式**降为**同元素集**，再逐元素拆 InA——`filter_InA` 的**第二个括号参数**是 Proper 附带条件，喂 `Proper_eq_eq`）；然后两条纯列表引理：`filter_length_le`（过滤不长）与 `filter_InA_length_lt`（**被过滤掉的元素在表里 ⇒ 严格变短**——`f x = false` 在「x 等价于某个表头」时经 Proper 搬到头上）。三者拼装：`repeat rewrite S.cardinal_1` 把两侧基数都换成长度，`rewrite Sremove_elements` 换成 filter，`filter_InA_length_lt` 收官。**抽象接口上证明的通行套路：找到「接口里的 elements 定理」，把集合问题化成列表问题。**

### 47.4 M.remove 与 M.elements

```coq
(* ---------- 47.4 M.remove 与 M.elements ---------- *)

Lemma InA_map_fst_key :
 forall A j l,
 InA E.eq j (map (@fst M.E.t A) l) <-> exists e, InA (@M.eq_key_elt A) (j,e) l.
Proof.
intros A j l. split; intro H.
- apply InA_alt in H. destruct H as [k [Hjk Hin]].
  apply in_map_iff in Hin. destruct Hin as [[k' e] [Hfst Hpair]].
  simpl in Hfst. rewrite <- Hfst in Hjk.
  exists e. apply InA_alt. exists (k', e). split.
  + unfold M.eq_key_elt. simpl. split; [exact Hjk | reflexivity].
  + exact Hpair.
- destruct H as [e Hke]. apply InA_alt in Hke.
  destruct Hke as [[j' e'] [Hpair Hin]]. simpl in Hpair.
  destruct Hpair as [Hjj' Hee]. unfold E.eq in Hjj'.
  simpl in Hjj', Hee. rewrite <- Hjj', <- Hee in Hin.
  apply InA_alt. exists j. split.
  + unfold E.eq. reflexivity.
  + apply in_map_iff. exists (j, e). split; [reflexivity | exact Hin].
Qed.

Lemma Sorted_lt_key :
 forall A (al : list (positive*A)),
  Sorted (@M.lt_key A) al <->  Sorted E.lt (map (@fst positive A) al).
Proof.
intros A. induction al as [| [k e] rest IH]; simpl.
- split; intro; constructor.
- destruct rest as [| [k' e'] rest']; simpl in *.
  + split; intro; repeat constructor.
  + split; intro H.
    * apply Sorted_inv in H. destruct H as [Hs Hh].
      inversion Hh as [| b l Hlt]. simpl in Hlt.
      constructor.
      -- apply IH. exact Hs.
      -- constructor. exact Hlt.
    * apply Sorted_inv in H. destruct H as [Hs Hh].
      inversion Hh as [| b l Hlt].
      constructor.
      -- apply IH. exact Hs.
      -- constructor. simpl in *. exact Hlt.
Qed.

Lemma cardinal_map :  forall A B (f: A -> B) g,
     M.cardinal (M.map f g) = M.cardinal g.
Proof.
intros A B f g.
repeat rewrite M.cardinal_1.
replace (length (M.elements (M.map f g)))
   with (length (map (@fst M.E.t B) (M.elements (M.map f g))))
   by apply length_map.
replace (length (M.elements g))
   with (length (map (@fst M.E.t A) (M.elements g)))
   by apply length_map.
apply eqlistA_length with (eqA := E.eq).
apply SortE_equivlistE_eqlistE.
- rewrite <- Sorted_lt_key. apply M.elements_3.
- rewrite <- Sorted_lt_key. apply M.elements_3.
- intro j. rewrite !InA_map_fst_key. split; intro H.
  + destruct H as [e He]. apply M.elements_2 in He.
    apply WF.map_mapsto_iff in He. destruct He as [a [_ Ha]].
    exists a. apply M.elements_1. exact Ha.
  + destruct H as [a Ha]. apply M.elements_2 in Ha.
    exists (f a). apply M.elements_1.
    apply WF.map_mapsto_iff. exists a. split; [reflexivity | exact Ha].
Qed.

Lemma specialize_SortA_equivlistA_eqlistA:
 forall A al bl,
  Sorted (@M.lt_key A) al ->
  Sorted (@M.lt_key A) bl ->
  equivlistA (@M.eq_key_elt A) al bl ->
  eqlistA (@M.eq_key_elt A) al bl.
Proof.
intros.
apply SortA_equivlistA_eqlistA with (@M.lt_key A); auto.
apply M.eqke_equiv.
apply M.ltk_strorder.
clear.
repeat intro.
unfold M.lt_key, M.eq_key_elt in *.
destruct H, H0. rewrite H,H0. split; auto.
Qed.

Lemma Proper_eq_key_elt :
 forall A,
  Proper (@M.eq_key_elt A ==> @M.eq_key_elt A ==> iff)
               (fun x y : E.t * A => E.lt (fst x) (fst y)).
Proof.
 repeat intro. destruct H, H0. rewrite H,H0. split; auto.
Qed.

Lemma Proper_eq_dec_fst :
  forall A i,
  Proper (@M.eq_key_elt A ==> @eq bool)
         (fun x => if E.eq_dec (fst x) i then false else true).
Proof.
intros A i. unfold Proper, respectful, M.eq_key_elt.
intros [k1 k2] [j1 j2] [Hk Hj]. simpl in *. rewrite Hk. reflexivity.
Qed.

Lemma Mremove_elements:  forall A i s,
  M.In i s ->
     eqlistA (@M.eq_key_elt A) (M.elements (M.remove i s))
              (List.filter (fun x => if E.eq_dec (fst x) i then false else true) (M.elements s)).
Proof.
intros A i s H.
apply specialize_SortA_equivlistA_eqlistA.
- apply M.elements_3.
- apply filter_sort with (eqA := @M.eq_key_elt A) (ltA := @M.lt_key A).
  + apply M.eqke_equiv.
  + apply M.ltk_strorder.
  + apply Proper_eq_key_elt.
  + apply M.elements_3.
- intro x. rewrite filter_InA; [ | apply Proper_eq_dec_fst].
  destruct x as [x1 x2]. destruct (E.eq_dec x1 i) as [Heq | Hne].
  + split; intro HH.
    * exfalso. apply M.elements_2 in HH.
      exact (M.remove_1 s (eq_sym Heq) (ex_intro _ x2 HH)).
    * destruct HH as [H1 H2]. simpl in H2.
      destruct (E.eq_dec x1 i); [discriminate H2 | contradiction].
  + split; intro HH.
    * apply M.elements_2 in HH. split.
      -- apply M.elements_1. apply (M.remove_3 s i). exact HH.
      -- simpl. destruct (E.eq_dec x1 i); [contradiction | reflexivity].
    * destruct HH as [H1 H2]. simpl in H2.
      destruct (E.eq_dec x1 i); [contradiction | idtac].
      apply M.elements_1. apply M.remove_2.
      -- apply not_eq_sym. exact Hne.
      -- apply M.elements_2. exact H1.
Qed.
```

映射版把 47.3 的全套镜像到 `M` 上，多出来的麻烦是**键值对**：elements 是 `(key, A)` 的列表，等价关系从 `E.eq` 换成 `M.eq_key_elt`（键相等且值相等）、序从 `E.lt` 换成 `M.lt_key`（只看键）。`InA_map_fst_key` 打通「键列表的 InA ↔ 键值对列表的 InA」（`InA_alt` 把 InA 兑成存在式、`in_map_iff` 处理 map——47.2 兑换所的又一单生意）；`Sorted_lt_key` 说「键值对列表按 lt_key 有序 ↔ 键列表按 E.lt 有序」；`cardinal_map`（map 变换值不改变基数）是 remove_node 终止证明的必要零件——两侧长度各 `replace` 成键列表长度（`length_map` 旁证），有序性经 `Sorted_lt_key` 回租，元素集相等用 `WF.map_mapsto_iff` 把 `M.find` 语义翻译回 elements。`specialize_SortA_equivlistA_eqlistA` 把总钥匙特化到 `M.eq_key_elt/lt_key`——注意 `auto` 之后剩下的 Proper 附带条件用 `clear; repeat intro; destruct; rewrite; split` 一口气手撕。`Proper_eq_key_elt/Proper_eq_dec_fst` 是两个喂给 `filter_sort/filter_InA` 的 Proper 义务。

```coq
Lemma Mremove_cardinal_less : forall A i (s: M.t A), M.In i s ->
        M.cardinal (M.remove i s) < M.cardinal s.
Proof.
intros A i s H.
repeat rewrite M.cardinal_1.
assert (Hlen : length (M.elements (M.remove i s)) =
               length (List.filter (fun x => if E.eq_dec (fst x) i then false else true) (M.elements s))).
{ apply eqlistA_length with (eqA := @M.eq_key_elt A). apply Mremove_elements. exact H. }
rewrite Hlen.
destruct H as [e He].
apply filter_InA_length_lt with (eqA := @M.eq_key_elt A) (x := (i, e)).
- apply M.elements_1. exact He.
- apply Proper_eq_dec_fst.
- simpl. destruct (E.eq_dec i i) as [_ | Hii]; [reflexivity | exfalso; apply Hii; reflexivity].
Qed.
```

`Mremove_cardinal_less` 与集合版同构：基数换长度（`M.cardinal_1`）、`Mremove_elements` 换成 filter（这里 `eqlistA` 只保逐元素等价，长度等价用 `eqlistA_length` 再兑一层）、`filter_InA_length_lt` 收官——被删的键值对 `(i, e)` 由 `M.In` 的存在式拆出。**「删一点、映射严格变小」**到手，这就是 select 终止的燃料。

### 47.5 图：邻接集作为 positive 到集合的映射

```coq
(* ---------- 47.5 图：邻接集作为 positive 到集合的映射 ---------- *)

Definition node := E.t.
Definition nodeset := S.t.
Definition nodemap : Type -> Type := M.t.
Definition graph := nodemap nodeset.

Definition adj (g : graph) (i : node) : nodeset :=
  match M.find i g with Some a => a | None => S.empty end.

Definition undirected (g : graph) :=
   forall i j, S.In j (adj g i) -> S.In i (adj g j).

Definition no_selfloop (g : graph) := forall i, ~ S.In i (adj g i).

Definition nodes (g : graph) := Mdomain g.

Definition subset_nodes
                   (P : node -> nodeset -> bool)
                   (g : graph) :=
   M.fold (fun n adj s => if P n adj then S.add n s else s) g S.empty.

Definition low_deg (K : nat) (n : node) (adj : nodeset) : bool := S.cardinal adj <? K.

Definition remove_node (n : node) (g : graph) : graph :=
  M.map (S.remove n) (M.remove n g).
```

图 = **节点到邻接集的映射**（`nodemap nodeset`）。`adj` 取邻接集（查不到给空集——`M.find` 的 option 世界到 total 世界的标准垫片）；`undirected`（边对称）与 `no_selfloop` 是两条图公理——**作为前提**由后续定理使用（真实图要客户自己保证）；`nodes` 是节点全集（47.1 的 `Mdomain`）。三个操作：`subset_nodes P g` 用 `M.fold` 收集**满足布尔谓词 P** 的节点（这一章处处用 bool 谓词代替 Prop——要 fold 进程序里的判断必须是可计算的）；`low_deg K` 判「度数小于 K」（贪心着色的选点标准）；`remove_node` 删节点 = 先 `M.remove` 掉它自己的键、再对每个幸存者的邻接集 `S.remove` 掉它——**一行组合两个库操作，不写任何递归**。

### 47.6 终止性：每删一点，映射严格变小

```coq
(* ---------- 47.6 终止性：每删一点，映射严格变小 ---------- *)

Lemma Sin_domain : forall A n (g : M.t A), S.In n (Mdomain g) <-> M.In n g.
Proof.
intros A n g. unfold Mdomain.
apply (WP.fold_rec_bis (elt := A) (A := S.t)
        (P := fun m s => S.In n s <-> M.In n m)
        (f := fun k _ s => S.add k s) (i := S.empty)).
- intros m m' a Heq H. split; intro Hn.
  + destruct (proj1 H Hn) as [e He]. exists e.
    apply (proj2 (WF.find_mapsto_iff (elt := A) m' n e)).
    rewrite <- (Heq n).
    apply (proj1 (WF.find_mapsto_iff (elt := A) m n e)). exact He.
  + destruct Hn as [e He]. apply (proj2 H). exists e.
    apply (proj2 (WF.find_mapsto_iff (elt := A) m n e)).
    rewrite (Heq n).
    apply (proj1 (WF.find_mapsto_iff (elt := A) m' n e)). exact He.
- split; intro Hn.
  + destruct (S.empty_1 Hn).
  + destruct Hn as [e He]. destruct (M.empty_1 He).
- intros k e a m' Hke Hnk H. destruct (E.eq_dec n k) as [Hnk' | Hne].
  + split; intros _.
    * exists e. apply M.add_1. symmetry. exact Hnk'.
    * apply S.add_1. symmetry. exact Hnk'.
  + split; intro Hn.
    * assert (Hia : S.In n a).
      { apply S.add_3 with (x := k); [apply not_eq_sym; exact Hne | exact Hn]. }
      destruct (proj1 H Hia) as [e0 He0]. exists e0.
      apply M.add_2; [apply not_eq_sym; exact Hne | exact He0].
    * destruct Hn as [e0 He0]. apply S.add_2. apply (proj2 H).
      exists e0. apply M.add_3 with (x := k) (e' := e);
        [apply not_eq_sym; exact Hne | exact He0].
Qed.

Lemma subset_nodes_sub :  forall P g, S.Subset (subset_nodes P g) (nodes g).
Proof.
intros P g.
assert (Hfold : forall a, S.In a (subset_nodes P g) -> M.In a g).
{ unfold subset_nodes.
  apply (WP.fold_rec_bis (elt := nodeset) (A := S.t)
          (P := fun m s => forall a, S.In a s -> M.In a m)
          (f := fun n ad s => if P n ad then S.add n s else s)
          (i := S.empty)).
  - intros m m' a Heq H i Hin.
    destruct (H i Hin) as [e He]. exists e.
    apply (proj2 (WF.find_mapsto_iff m' i e)).
    rewrite <- (Heq i).
    apply (proj1 (WF.find_mapsto_iff m i e)). exact He.
  - intros i Hin. destruct (S.empty_1 Hin).
  - intros k e a m' Hke Hnk H i Hin.
    destruct (P k e) eqn:HP.
    + destruct (E.eq_dec i k) as [Hik | Hne].
      * rewrite Hik. exists e. apply M.add_1. reflexivity.
      * assert (Hia : S.In i a).
        { apply S.add_3 with (x := k); [apply not_eq_sym; exact Hne | exact Hin]. }
        destruct (H i Hia) as [e0 He0]. exists e0.
        apply M.add_2; [apply not_eq_sym; exact Hne | exact He0].
    + destruct (E.eq_dec i k) as [Hik | Hne].
      * rewrite Hik. exists e. apply M.add_1. reflexivity.
      * destruct (H i Hin) as [e0 He0]. exists e0.
        apply M.add_2; [apply not_eq_sym; exact Hne | exact He0]. }
unfold S.Subset, nodes. intros a Ha. apply Sin_domain. apply Hfold. exact Ha.
Qed.

Lemma select_terminates :
  forall (K : nat) (g : graph) (n : S.elt),
   S.choose (subset_nodes (low_deg K) g) = Some n ->
   M.cardinal (remove_node n g) < M.cardinal g.
Proof.
intros K g n H.
unfold remove_node, nodes.
rewrite cardinal_map.
apply Mremove_cardinal_less.
apply Sin_domain.
apply (subset_nodes_sub (low_deg K) g).
apply S.choose_1. exact H.
Qed.
```

`M.fold` 的推理要靠库的**fold 归纳原理** `WP.fold_rec_bis`：证「fold 出来的结果满足 P」，只需三个前提——加一个键值保持 P、空映射/空集合满足 P、fold 一步转移保持 P（f 的情形讨论）。`Sin_domain` 用它证「域集合 ↔ 映射隶属」（invariant 是个 iff）；`subset_nodes_sub` 用它证「筛出的节点 ⊆ 全体节点」（筛子只会丢不会捡）。两段证明的骨架相同：`WF.find_mapsto_iff` 把 `M.find` 的 option 世界与 `M.In` 的存在式世界随时互换（`find_mapsto_iff : M.find n m = Some e <-> M.In n m /\ ...`），`E.eq_dec` 在每个折叠步上分「正在处理的键就是目标键 / 不是」。最后 `select_terminates` 四行拼装：`remove_node` 展开成 `M.map (S.remove n) (M.remove n g)`，`cardinal_map` 消掉 `M.map`，47.4 的 `Mremove_cardinal_less` 收官，而「n 确实在图里」由 `S.choose_1`（choose 出来的必在集合里）经 `subset_nodes_sub` 传递。**终止义务备齐**。

### 47.7 着色程序：select 与 color

```coq
(* ---------- 47.7 着色程序：select 与 color ---------- *)

Function select (K : nat) (g : graph) {measure M.cardinal g} : list node :=
  match S.choose (subset_nodes (low_deg K) g) with
  | Some n => n :: select K (remove_node n g)
  | None => nil
  end.
Proof. apply select_terminates. Defined.

Definition coloring := M.t node.

Definition colors_of (f : coloring) (s : S.t) : S.t :=
   S.fold (fun n s => match M.find n f with Some c => S.add c s | None => s end) s S.empty.

Definition color1 (palette : S.t) (g : graph) (n : node) (f : coloring) : coloring :=
   match S.choose (S.diff palette (colors_of f (adj g n))) with
   | Some c => M.add n c f
   | None => f
   end.

Definition color (palette : S.t) (g : graph) : coloring :=
  fold_right (color1 palette g)  (M.empty _) (select (S.cardinal palette) g).
```

算法是**贪心 K-着色**（五色定理证明的核心程序结构）：`select` 反复挑出一个**当前度数 < K** 的节点（`S.choose` 从筛子集合里任取一个；取不到就停），把它从图里删掉——产出一个「从先删到后删」的删除序列；`color` 沿序列**反向** fold（`fold_right`），每步用 `color1` 给当前节点上色：从调色板 `palette` 里**任取一个邻居没用过的颜色**（`S.diff palette (colors_of f (adj g n))` 减去邻居已用的颜色集，再 `S.choose` 任取）。反向的直觉：最后删的节点删时邻居最少（≤ K-1 个），先上色最容易；先删的节点邻居最多，留到最后反而它的邻居们早已各就各位、避开即可。`Function ... {measure M.cardinal g}` + `Proof. apply select_terminates. Defined.`——第 35/36 章的 measure 递归第三次出场，义务证明就是 47.6 的成品（`Defined` 让 `select` 能被 `Compute` 真的跑）。

### 47.8 正确性：算法产出的着色永不冲突

```coq
(* ---------- 47.8 正确性：算法产出的着色永不冲突 ---------- *)

Definition coloring_ok (palette : S.t) (g : graph) (f : coloring) :=
 forall i j, S.In j (adj g i) ->
     (forall ci, M.find i f = Some ci -> S.In ci palette) /\
     (forall ci cj, M.find i f = Some ci -> M.find j f = Some cj -> ci<>cj).

Lemma find_empty : forall (A : Type) (n : node), M.find n (M.empty A) = None.
Proof.
intros A n.
destruct (M.find n (M.empty A)) as [c |] eqn:E.
- exfalso. exact (M.empty_1 (proj2 (WF.find_mapsto_iff (elt := A) (M.empty A) n c) E)).
- reflexivity.
Qed.

Lemma find_add_same : forall (A : Type) (f : M.t A) n c,
  M.find n (M.add n c f) = Some c.
Proof.
intros A f n c.
apply (proj1 (WF.find_mapsto_iff (elt := A) (M.add n c f) n c)).
apply M.add_1. reflexivity.
Qed.

Lemma find_add_other : forall (A : Type) (f : M.t A) n m c c0,
  m <> n -> M.find m (M.add n c f) = Some c0 -> M.find m f = Some c0.
Proof.
intros A f n m c c0 Hmn Hfind.
apply (proj1 (WF.find_mapsto_iff (elt := A) f m c0)).
apply M.add_3 with (x := n) (e' := c).
- apply not_eq_sym. exact Hmn.
- exact (proj2 (WF.find_mapsto_iff (elt := A) (M.add n c f) m c0) Hfind).
Qed.

Lemma in_fold_acc :
  forall (l : list node) (f : coloring) (s : S.t) (s0 : node),
    S.In s0 s ->
    S.In s0 (fold_left (fun s n => match M.find n f with
                                   | Some c => S.add c s
                                   | None => s end) l s).
Proof.
induction l as [| a l IH]; intros f s s0 H; simpl.
- exact H.
- destruct (M.find a f) as [ca |] eqn:Ea; simpl.
  + apply IH. apply S.add_2. exact H.
  + apply IH. exact H.
Qed.

Lemma in_colors_of_aux :
  forall (l : list node) (f : coloring) (s : S.t) (i : node) (c : node),
  In i l -> M.find i f = Some c ->
  S.In c (fold_left (fun s n => match M.find n f with
                                | Some c => S.add c s
                                | None => s end) l s).
Proof.
induction l as [| a l IH]; intros f s i c Hin Hfind; simpl.
- contradiction.
- destruct (M.find a f) as [ca |] eqn:Ea; simpl.
  + destruct Hin as [Hia | Hin].
    * rewrite <- Hia in Hfind. rewrite Hfind in Ea.
      injection Ea as Hca. rewrite <- Hca.
      apply in_fold_acc. apply S.add_1. reflexivity.
    * apply IH with (i := i); assumption.
  + destruct Hin as [Hia | Hin].
    * rewrite <- Hia in Hfind. rewrite Hfind in Ea. discriminate.
    * apply IH with (i := i); assumption.
Qed.

Lemma in_colors_of_1 :
  forall i s f c, S.In i s -> M.find i f = Some c -> S.In c (colors_of f s).
Proof.
intros i s f c Hin Hfind. unfold colors_of. rewrite S.fold_1.
apply (in_colors_of_aux (S.elements s) f S.empty i c).
- apply InA_eq_In. apply S.elements_1. exact Hin.
- exact Hfind.
Qed.

Definition partial_ok (palette : S.t) (g : graph) (f : coloring) : Prop :=
  (forall n c, M.find n f = Some c -> S.In c palette) /\
  (forall i j, S.In j (adj g i) ->
     forall ci cj, M.find i f = Some ci -> M.find j f = Some cj -> ci <> cj).

Lemma color1_partial_ok : forall palette g n f,
  no_selfloop g -> undirected g ->
  partial_ok palette g f ->
  partial_ok palette g (color1 palette g n f).
Proof.
intros palette g n f Hns Hun [Hpal Hdif].
unfold color1.
destruct (S.choose (S.diff palette (colors_of f (adj g n)))) as [c |] eqn:Hc.
- assert (Hcpal : S.In c palette).
  { apply S.diff_1 with (s' := colors_of f (adj g n)).
    apply S.choose_1. exact Hc. }
  assert (Hcout : ~ S.In c (colors_of f (adj g n))).
  { apply S.diff_2 with (s := palette). apply S.choose_1. exact Hc. }
  split.
  + intros m cm Hm. destruct (E.eq_dec m n) as [Hmn | Hmn].
    * rewrite Hmn in Hm. rewrite find_add_same in Hm.
      injection Hm as Hmc. rewrite <- Hmc. exact Hcpal.
    * apply Hpal with (n := m). exact (find_add_other node f n m c cm Hmn Hm).
  + intros i j Hij ci cj Hi Hj.
    destruct (E.eq_dec i n) as [Hin | Hni].
    * destruct (E.eq_dec j n) as [Hjn | Hnj].
      -- exfalso. rewrite Hin, Hjn in Hij. apply (Hns n). exact Hij.
      -- rewrite Hin in Hi, Hij. rewrite find_add_same in Hi.
         injection Hi as Hci.
         assert (Hcj : S.In cj (colors_of f (adj g n))).
         { apply (in_colors_of_1 j (adj g n) f cj); [exact Hij | ].
           exact (find_add_other node f n j c cj Hnj Hj). }
         assert (Hnc : c <> cj).
         { intro Heq. apply Hcout. rewrite Heq. exact Hcj. }
         intro Heqc. apply Hnc. rewrite Hci. exact Heqc.
    * destruct (E.eq_dec j n) as [Hjn | Hnj].
      -- rewrite Hjn in Hj, Hij.
         rewrite find_add_same in Hj. injection Hj as Hcj.
         assert (Hci : S.In ci (colors_of f (adj g n))).
         { apply (in_colors_of_1 i (adj g n) f ci).
           + apply (Hun i n). exact Hij.
           + exact (find_add_other node f n i c ci Hni Hi). }
         assert (Hnc : c <> ci).
         { intro Heq. apply Hcout. rewrite Heq. exact Hci. }
         intro Heqc. apply Hnc. rewrite Hcj. symmetry. exact Heqc.
      -- apply Hdif with (i := i) (j := j).
         ++ exact Hij.
         ++ exact (find_add_other node f n i c ci Hni Hi).
         ++ exact (find_add_other node f n j c cj Hnj Hj).
- exact (conj Hpal Hdif).
Qed.

Lemma fold_right_partial_ok : forall palette g l,
  no_selfloop g -> undirected g ->
  partial_ok palette g (fold_right (color1 palette g) (M.empty node) l).
Proof.
intros palette g l Hns Hun.
induction l as [| n l IH].
- split.
  + intros m cm Hm. rewrite find_empty in Hm. discriminate.
  + intros i j Hij ci cj Hi Hj. rewrite find_empty in Hi. discriminate.
- simpl. apply color1_partial_ok; assumption.
Qed.

Theorem color_correct :
  forall palette g,
       no_selfloop g ->
       undirected g ->
       coloring_ok palette g (color palette g).
Proof.
intros palette g Hns Hun.
unfold color, coloring_ok.
destruct (fold_right_partial_ok palette g (select (S.cardinal palette) g) Hns Hun)
  as [Hpal Hdif].
intros i j Hij. split.
- intros ci Hi. apply Hpal with (n := i). exact Hi.
- intros ci cj Hi Hj. apply Hdif with (i := i) (j := j);
  [exact Hij | exact Hi | exact Hj].
Qed.
```

规格 `coloring_ok`：对每条边 `(i,j)`，两端若有色则**色在调色板内**且**两端颜色不同**——「不冲突」的完整形式。证明的骨架是本书的老三样：**归纳不变量**（`partial_ok`——color1 一步步维护的中间性质，与最终规格同形）、**单步保持**（`color1_partial_ok`）、**归纳组装**（`fold_right_partial_ok` + `color_correct` 两行收口）。

`color1_partial_ok` 是全章最长的一段，读作一份「换色安检流程」：给节点 `n` 上了颜色 `c` 后，老的 `partial_ok` 还成立吗？三条 find 引理（`find_empty/add_same/add_other`——第 48 章 `t_update` 三定律的 FMap 版）把「查新旧着色」的每种情况接线；`in_colors_of_1`（经 `in_fold_acc`/`in_colors_of_aux` 两条 fold_left 归纳引理，把 `S.fold` 的语义展开到元素表）保证「**邻居 j 已有的颜色一定在 colors_of 里**」——这是挑色的依据。真正的安检分四格（`E.eq_dec` 对 i、j 各一次）：`i = j = n` 不可能（`no_selfloop` 用上了！自环的两端同色无法避免）；`i = n ≠ j`（新染的 vs 老的）：新色 c 不在邻居色集里（`S.diff_2` 的选择依据），邻居的色 cj 在色集里，两者必不同；`i ≠ n = j`：对称，**这里用到 `undirected`**——`j = n` 的邻居关系要反推 `i` 在 n 的邻接集里，无向性把边翻过来；双双不是 n：老性质原样（find_add_other 接线）。**图公理 undirected/no_selfloop 各司其职的位置，正是图论证明的形状**。`fold_right_partial_ok` 对删除序列归纳（空序列给空着色，两支 discriminate 收尾），主定理 `color_correct` 把 partial_ok 的合取拆给 coloring_ok 的两个半句——**证明的重量全在 color1 一步，fold 只是传送带**（第 39 章「证慢的、一层证扎实」的又一例）。

### 47.9 试跑：一张 7 边图，三色全部着上

```coq
(* ---------- 47.9 试跑：一张 7 边图，三色全部着上 ---------- *)

Local Open Scope positive.
(* 现在 1, 2, 3 等字面量按 positive 解释 *)

Definition palette : S.t := fold_right S.add S.empty [1; 2; 3].

Definition add_edge (e : (E.t*E.t)) (g : graph) : graph :=
 M.add (fst e) (S.add (snd e) (adj g (fst e)))
  (M.add (snd e) (S.add (fst e) (adj g (snd e))) g).

Definition mk_graph (el : list (E.t*E.t)) :=
  fold_right add_edge (M.empty _) el.

Definition G :=
    mk_graph [ (5,6); (6,2); (5,2); (1,5); (1,2); (2,4); (1,4)].

Compute (S.elements (Mdomain G)).
(* = [4; 2; 6; 1; 5] *)

Compute (M.elements (color palette G)).
(* = [(4, 1); (2, 3); (6, 2); (1, 2); (5, 1)] ：5 个节点全部着色，无一「溢出」 *)

Example G_all_colored : M.cardinal (color palette G) = M.cardinal G.
Proof. compute. reflexivity. Qed.

Print Assumptions color_correct.

End Ex47Color.
```

理论落地为**一次真实计算**：`palette` 是三色调色板（`Local Open Scope positive` 让 `1;2;3` 按 positive 解释）；`add_edge` 对称地写双向邻接（无向图的构造器）；`G` 是 5 个节点、7 条边的图。两个 `Compute` 实测：节点表 `[4;2;6;1;5]`，着色结果 `[(4,1);(2,3);(6,2);(1,2);(5,1)]`——五个节点各得一色，颜色都出自 {1,2;3}，**三色足够**。`G_all_colored` 用 `compute. reflexivity.` 机器复核「着色数 = 节点数」（没有一个节点被漏掉——贪心选点保证每个节点都轮到，但这一例用计算而非证明来验收）。`Print Assumptions color_correct` 实测输出 `Closed under the global context`：整条从 FSets 接口到贪心着色的证明链无公理。

收个尾。VFA 篇 33–47 到此收官。十五章走完一条完整的验证工程路线：**规格**从 Permutation（33）经三种有序定义（34）到多重集（37）、再到可判定规格（38）与代数/模型两种接口规格（42）；**算法**从三个排序（34–36）、BST（39）、红黑树（41）、优先队列与堆（43–44）到 trie（45）与图着色（47）；**方法论**集齐了燃料/measure/内嵌 fix 三件终止兵器（35–36）、表示不变量与抽象函数两大验证配方（39/42/45）、「证慢兑快」的性能兑换术（39），以及标准库接口上的 setoid 推理（47）。四色定理的全形式化是这条路的极限延伸——本章的贪心着色框架虽只是它的一小步，但用到的每一件兵器都是同款。下一章换卷：第 48 章起进入语言理论篇，从「把函数当数据结构」的映射出发，亲手造出 Imp 语言与它的全部语义。

### 47.10 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **positive 字面量要开 scope**（47.9）：`Local Open Scope positive` 之前裸写 `[1; 2; 3]` 实测报 `The term "[1; 2; 3]" has type "list nat" while it is expected to have type "list S.elt"`——数字默认落在 nat_scope，构造调色板必须先开 positive_scope（或逐处 `%positive`，如 47.1 的 `example_map`）。
2. **库引理的 setoid 前提一个都不能少**（47.2）：`filter_sort` 的前提序是「等价关系、StrictOrder、**Proper**、有序」，漏掉 `lt_proper` 后第三个子弹头错位，实测报 `The term "H" has type "Sorted E.lt l" while it is expected to have type "Proper (E.eq ==> E.eq ==> iff) E.lt"`——`apply ... with (eqA := ...) (ltA := ...)` 之后逐个清点前提。
3. **`filter_InA` 的 Proper 附带条件藏在第二括号里**（47.3/47.4）：`rewrite filter_InA; [ | apply Proper_eq_eq]` 的 `[ | ...]` 是改写产生的义务槽；漏写会残留 `Proper (eqA ==> @eq bool) f` 型目标，且 f 里带 `E.eq_dec` 时 unify 常对不上，要自备 `Proper_eq_dec_fst` 一类的专用引理。
4. **`M.fold` 的推理没有免费午餐**（47.6）：对 fold 出的结果证性质必须走 `WP.fold_rec_bis` 的三前提（等价转移、空基、单步保持），没有「fold 与列表 fold 等价」的现成桥；`M.find` 的 option 与 `M.In` 的存在式之间靠 `WF.find_mapsto_iff` 反复兑换。
5. **StrictOrder/Proper 要从库的深路径里挖**（47.1）：`M.ME.MO.IsTO.lt_strorder`、`M.ME.MO.IsTO.lt_compat` 这类路径没有顶层短名，`Search` 按形状搜（如 `Search StrictOrder E.lt`）比猜名字快。
6. **`Function select` 的义务证明必须 `Defined`**（47.7）：`Proof. apply select_terminates. Defined.` 换成 `Qed` 则 47.9 的 `Compute (M.elements (color palette G))` 卡死——不透明的终止证明挡住 select 的展开（35/36 章同款；本章因有真计算而必须）。
7. **color1 的安检要四格全查**（47.8）：`i = n` 与 `j = n` 是两格不同的证明（新染端分别在左/右），漏掉 `undirected` 的翻转（`Hun i n`）时 `i ≠ n = j` 格实测卡住——无向性不是装饰，是这一格的必需前提；`no_selfloop` 同理只在 `i = j = n` 格出场。

---
上一章：[46 · Bag 与置换的代数](46-bagperm.md) ｜ 下一章：[48 · 映射：把函数当数据结构](48-maps.md) ｜ 返回：[README](../README.md)
