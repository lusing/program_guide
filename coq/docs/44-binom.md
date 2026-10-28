# 44 · 二项式堆
对应示例：`../examples/44_binom.v`（`Module Ex44Binom`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

第 43 章给优先队列立了**抽象规格**——PRIQUEUE 签名里那十几条公理（`can_relate`、`abs_perm`、`empty_relate`、`insert_relate`、`delete_max_*_relate`、`merge_*`……），然后用最朴素的**无序表**实现交卷：empty/insert O(1)、delete_max/merge O(N)，代价是不变量 `priq` 恒为 `True`、抽象关系 `Abs` 就是 `p = al`，公理几乎全是白送的。本章换第二种表示——**二项式堆**（binomial queue）：empty 仍 O(1)，而 insert、delete_max、merge 全部 O(log N)。规格一字不改，改的是表示：`priq` 变成「第 i 个分量要么空、要么是一棵深 i 的 2 的幂堆」的**带位置结构不变量**，`Abs` 变成 `tree_elems`/`priqueue_elems` 两条**把置换编进构造子**的归纳关系——证明第一次要真刀真枪。

在 VFA 篇（33–47）的坐标系里：33–34 建立置换与排序规格，35–36 用燃料/measure 驯服两种排序，43 把「正确性」升级为「签名 + 表示不变量 + 抽象关系」三层结构，44（本章）是这套路数的收官一战；45 起转入 Trie、Bag、四色定理等独立专题。原书本章几乎全部留白（`smash_valid` 2 星、`carry_valid` 3 星、`carry_elems` 4 星、`delete_max_*` 5 星），且依赖 VFA 自定义的 `bdestruct`/`inv`。本章自包含地补全 **carry→insert 主线**的两层证明（不变量 + 抽象关系），原书的 `join_valid`、`delete_max_*_relate`（4–5 星）不在正文收录范围，44.3 与 44.7 交代缘由与套路。

### 44.1 程序：tree、priqueue 与 carry 链插入

```coq
(* 44 二项式堆 —— carry 链插入、pow2 堆不变量与元素同构 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex44Binom.

(* ---------- 44.1 程序：tree、priqueue 与 carry 链插入 ---------- *)

Definition key := nat.

Inductive tree : Type :=
| Node : key -> tree -> tree -> tree
| Leaf : tree.

Definition priqueue := list tree.

Definition empty : priqueue := nil.
```

键仍是 `nat`（比较是线性的，效率问题留给第 40 章的 Extract 路线）。树是三叉构造：`Node x t1 t2` 带键与两个孩子。**堆的形状约定**藏在后面的不变量里：一棵深 n 的「2 的幂堆」形如 `Node r t Leaf`——右孩子永远是 `Leaf`，真正的完全二叉树沿**左脊**串下去。优先队列 `priqueue` 是树的表：**第 i 个分量要么是 `Leaf`（该位空），要么是深 i 的 2 的幂堆（该位恰有 2^i 个结点）**。于是队列就是一棵棵按位长大的树排成的「二进制数」。

```coq
Definition smash (t u : tree) : tree :=
  match t, u with
  | Node x t1 Leaf, Node y u1 Leaf =>
      if y <? x then Node x (Node y u1 t1) Leaf
               else Node y (Node x t1 u1) Leaf
  | _, _ => Leaf (* bogus tree for ill-formed input *)
  end.

Fixpoint carry (q : list tree) (t : tree) : list tree :=
  match q, t with
  | nil, Leaf => nil
  | nil, _ => t :: nil
  | Leaf :: q', _ => t :: q'
  | u :: q', Leaf => u :: q'
  | u :: q', _ => Leaf :: carry q' (smash t u)
  end.

Definition insert (x : key) (q : priqueue) : priqueue :=
  carry q (Node x Leaf Leaf).
```

`smash` 是「同位相撞」：两棵深 n 的堆合成一棵深 n+1 的——**大者做根，小者连着自己的子树挂到大者脊上**（`Node y u1 t1`：输家的子树 `u1` 前置到赢家脊 `t1` 的头上）。堆序由比较 `y <? x` 保证；两个树形不符的输入返回 `Leaf`（后面 44.3 的不变量会证明这种输入根本不出现）。注意 rocq 9.3 里 `>?` 记号已不可用（实测报 `Syntax error: [term] expected after '>'`），本章一律写成 `y <? x`。

`carry` 是二进制**进位链**：往队列里塞一棵树 `t`——第 i 位是 `Leaf`（该位 0）就直接落位；第 i 位已有树 `u`（1 + 1 = 10₂）就把二者 `smash` 成深 i+1 的树**递归进到下一位**，本位清空写 `Leaf`。`insert x q` 就是「在末位加 1」：把单元素树 `Node x Leaf Leaf` 塞进 carry 链。

```coq
Example insert_pi :
  fold_left (fun q x => insert x q) [3;1;4;1;5;9;2;3;5] empty =
  [Node 5 Leaf Leaf; Leaf; Leaf;
   Node 9 (Node 4 (Node 3 (Node 1 Leaf Leaf) (Node 1 Leaf Leaf))
                  (Node 3 (Node 2 Leaf Leaf) (Node 5 Leaf Leaf))) Leaf].
Proof. reflexivity. Qed.
```

把 π 的九个数字逐个 insert，`reflexivity` 在 kernel 里把整个进位链算完。结果读作二进制：9 = 1001₂——前 8 个元素挤成第 3 位一棵 8 结点树（根 9），此时第 0 位恰好空着，最后插入的 5 直接落位成单元素树，中间两位 `Leaf` 空置。

### 44.2 join、unzip 与 delete_max

```coq
(* ---------- 44.2 join、unzip 与 delete_max ---------- *)

Fixpoint join (p q : priqueue) (c : tree) : priqueue :=
  match p, q, c with
  | [], _, _ => carry q c
  | _, [], _ => carry p c
  | Leaf :: p', Leaf :: q', _ => c :: join p' q' Leaf
  | Leaf :: p', q1 :: q', Leaf => q1 :: join p' q' Leaf
  | Leaf :: p', q1 :: q', Node _ _ _ => Leaf :: join p' q' (smash c q1)
  | p1 :: p', Leaf :: q', Leaf => p1 :: join p' q' Leaf
  | p1 :: p', Leaf :: q', Node _ _ _ => Leaf :: join p' q' (smash c p1)
  | p1 :: p', q1 :: q', _ => c :: join p' q' (smash p1 q1)
  end.
```

`join` 是**两个二进制数的全加器**：逐位相加 `p`、`q` 外加进位 `c`。把 `Leaf` 当 0、`Node` 当 1 读这八条子句：一串一零得零（`Leaf :: p', q1 :: q', Leaf`），一加一进位（`smash`），双零落进位——就是竖式加法。递归对 `p` 的尾做（`Fixpoint` 的递减参数），`q` 与 `c` 在归纳证明里要泛化（44.3 的套路）。

```coq
Fixpoint unzip (t : tree) (cont : priqueue -> priqueue) : priqueue :=
  match t with
  | Node x t1 t2 => unzip t2 (fun q => Node x t1 Leaf :: cont q)
  | Leaf => cont nil
  end.

Definition heap_delete_max (t : tree) : priqueue :=
  match t with
  | Node x t1 Leaf => unzip t1 (fun u => u)
  | _ => nil (* bogus value for ill-formed or empty trees *)
  end.
```

删除最大元素的准备工作：最大键必是某棵树的根；拆掉这棵树，它的子树们本来就是深 0、1、…、n−1 的一串 2 的幂堆，摊平就还原成一个队列。`unzip` 用**延续（CPS）**沿脊收集：每剥一层 `Node x t1 t2`，就把「`Node x t1 Leaf` 加入结果」这个动作追加到延续 `cont` 上，剥到 `Leaf` 才真正执行整串动作。

```coq
Fixpoint find_max' (current : key) (q : priqueue) : key :=
  match q with
  | [] => current
  | Leaf :: q' => find_max' current q'
  | Node x _ _ :: q' => find_max' (if current <? x then x else current) q'
  end.

Fixpoint find_max (q : priqueue) : option key :=
  match q with
  | [] => None
  | Leaf :: q' => find_max q'
  | Node x _ _ :: q' => Some (find_max' x q')
  end.

Fixpoint delete_max_aux (m : key) (p : priqueue) : priqueue * priqueue :=
  match p with
  | Leaf :: p' => let (j, k) := delete_max_aux m p' in (Leaf :: j, k)
  | Node x t1 Leaf :: p' =>
      if x <? m
      then (let (j, k) := delete_max_aux m p' in (Node x t1 Leaf :: j, k))
      else (Leaf :: p', heap_delete_max (Node x t1 Leaf))
  | _ => (nil, nil) (* bogus value *)
  end.

Definition delete_max (q : priqueue) : option (key * priqueue) :=
  match find_max q with
  | None => None
  | Some m => let (p', q') := delete_max_aux m q in Some (m, join p' q' Leaf)
  end.

Definition merge (p q : priqueue) := join p q Leaf.
```

`find_max`/`find_max'` 线性扫所有分量的根取最大（空堆返回 `None`）。`delete_max_aux m p` 把队列沿「根键达到最大值 m 的那棵树」劈成前后两段：遇到 `x <? m` 为真的树就原样搬进前段继续找，遇到根恰为 m 的树就停——它被 `heap_delete_max` 摊平成后段。最后 `delete_max` 用 `join` 把前段、后段重新加回去。`merge` 则是 `join` 裸调用——它就是本章存在的理由：第 43 章的表实现 merge 要 O(N)，这里 O(log N)。

```coq
Example delete_max_small :
  delete_max (insert 5 (insert 2 (insert 4 empty))) =
  Some (5, [Leaf; Node 4 (Node 2 Leaf Leaf) Leaf]).
Proof. reflexivity. Qed.
```

手算一遍便于对照：insert 4 得 `[N4]`；insert 2 相撞进位得 `[Leaf; N4(N2)]`；insert 5 落在空位 0 得 `[N5; N4(N2)]`。`delete_max`：最大键 5，第 0 位劈出去，其子树为空，前段空、后段 `[N4(N2)]`，join 拼回时 0 位补 `Leaf`——结果 `Some (5, [Leaf; N4(N2)])`，`reflexivity` 实测通过。

### 44.3 表示不变量：pow2heap 与 priq

程序读完了，现在给它配「形状说明书」。这一节是不变量层：**每个分量都是合法的 2 的幂堆**。

```coq
(* ---------- 44.3 表示不变量：pow2heap 与 priq ---------- *)

(* t 是深度 n 的满二叉树，且每个键 <= m *)
Fixpoint pow2heap' (n : nat) (m : key) (t : tree) : Prop :=
  match n, m, t with
  | 0, _, Leaf => True
  | 0, _, Node _ _ _ => False
  | S _, _, Leaf => False
  | S n', _, Node k l r => m >= k /\ pow2heap' n' k l /\ pow2heap' n' m r
  end.

(* t 是深度 n 的 2 的幂堆 *)
Definition pow2heap (n : nat) (t : tree) : Prop :=
  match t with
  | Node m t1 Leaf => pow2heap' n m t1
  | _ => False
  end.

(* q 的第 i 个分量要么是 Leaf、要么是深 i 的 2 的幂堆 *)
Fixpoint priq' (i : nat) (l : list tree) : Prop :=
  match l with
  | t :: l' => (t = Leaf \/ pow2heap i t) /\ priq' (S i) l'
  | nil => True
  end.

Definition priq (q : priqueue) : Prop := priq' 0 q.
```

三层谓词各管一段：`pow2heap' n m t` 说「t 是深 n 的满二叉树、所有键 ≤ m」——注意它**对 n 递归**且左孩子的上界收紧到自己的根（`pow2heap' n' k l`），这是堆序；`pow2heap n t` 加上「右孩子为 `Leaf`」的外壳约定；`priq' i l` 沿队列走、**索引 i 随位置递增**——这就是「带位置的不变量」。最后 `priq` 把索引钉在 0。

关键的设计信息在证明策略里：正因为 `priq'` 的索引随表递增，关于它的一切归纳证明都必须**把 n 一起泛化**（`forall q n, priq' n q -> ...`），否则归纳假设只认 `priq' 0`、够不着尾部的 `priq' (S i)`——这与第 28 章 BST 证明里「把比较方向泛化」是同一类动作。

```coq
Theorem empty_priq : priq empty.
Proof. unfold priq, empty. simpl. exact I. Qed.
```

空堆的证明一行：`priq' 0 nil` 化简为 `True`，用 `I` 关掉。

```coq
Theorem smash_valid :
  forall n t u, pow2heap n t -> pow2heap n u -> pow2heap (S n) (smash t u).
Proof.
  intros n [x t1 [k a b | ] | ] [y u1 [k' a' b' | ] | ] Ht Hu;
    unfold pow2heap in Ht, Hu; simpl in Ht, Hu;
    try contradiction.
  simpl. destruct (y <? x) eqn:E.
  - apply Nat.ltb_lt in E. simpl. split; [lia | split; assumption].
  - apply Nat.ltb_ge in E. simpl. split; [lia | split; assumption].
Qed.
```

原书 2 星练习。intro 模式一次把两棵树 destruct 到所有可能的形状：整棵 `Leaf`、右孩子不是 `Leaf`（`Node x t1 (Node k a b)`）都让 `pow2heap` 展开成 `False`，`contradiction` 清场；**唯一活下来的形状**是 `Node x t1 Leaf` 与 `Node y u1 Leaf`，此时两个假设已化简为 `pow2heap' n x t1`、`pow2heap' n y u1`。`destruct (y <? x) eqn:E` 撕开比较（必须先 `simpl` 让 `smash` 的 `if` 露头，见 44.8 坑位 3），两个分支同构：`Nat.ltb_lt`/`Nat.ltb_ge` 把布尔翻成算术，根的上界交给 `lia`，两个子树前提原样继承——**深 n 的堆相撞得深 n+1**。

```coq
Theorem carry_valid :
  forall q n, priq' n q ->
  forall t, (t = Leaf \/ pow2heap n t) -> priq' n (carry q t).
Proof.
  induction q as [ | u q' IH]; intros n Hq t Ht.
  - destruct t as [x t1 t2 | ]; simpl.
    + split; [exact Ht | exact I].
    + exact I.
  - simpl in Hq. destruct Hq as [Hu Hq'].
    destruct u as [y u1 u2 | ]; destruct t as [x t1 t2 | ].
    + (* u = Node, t = Node : 进位递归 *)
      destruct Hu as [Hul | Hup]; [discriminate Hul |].
      destruct Ht as [Htl | Htp]; [discriminate Htl |].
      cbn [priq' carry]. split; [left; reflexivity |].
      apply IH; [exact Hq' | right; apply smash_valid; assumption].
    + (* u = Node, t = Leaf : 原样保留 *)
      destruct Hu as [Hul | Hup]; [discriminate Hul |].
      cbn [priq' carry]. split; [right; exact Hup | exact Hq'].
    + (* u = Leaf, t = Node : 直接放行 *)
      cbn [priq' carry]. split; [exact Ht | exact Hq'].
    + (* u = Leaf, t = Leaf : 恒等 *)
      cbn [priq' carry]. split; [left; reflexivity | exact Hq'].
Qed.
```

原书 3 星练习，进位链的**不变量版本**。陈述把 `q` 放在 `n` 前面（`forall q n`）正是为了 `induction q` 时 `n` 留在 ∀ 里——递归调用发生在**尾部**（索引 `S n`），泛化的 IH 才接得住。四个 cons 分支与 `carry` 的四条子句一一对应：双 Node 相撞时本位写 `Leaf`、递归交给 IH（`smash_valid` 供弹药）；一 Node 一 Leaf 原样保留；双 Leaf 恒等。两个细节：析取假设 `u = Leaf \/ pow2heap n u` 里的等式分支用 `discriminate` 杀（`Node ... = Leaf` 不可判等）；化简一律用**白名单 `cbn [priq' carry]`** 而不是 `simpl`——`simpl` 会把 `smash` 抖开成嵌套 match，后续 `apply smash_valid` 对不上语法（实测见 44.8 坑位 4）。

```coq
Theorem insert_priq : forall x q, priq q -> priq (insert x q).
Proof.
  intros x q H. unfold insert, priq in *.
  apply (carry_valid q 0 H). right. simpl. exact I.
Qed.
```

insert 保持不变量是 carry_valid 的直接推论：单元素树是深 0 的幂堆（`pow2heap 0 (Node x Leaf Leaf)` 化简为 `pow2heap' 0 x Leaf` 即 `True`）。

原书接下来是 `join_valid`（3 星选做）与一行推论 `merge_priq`：对 `p` 归纳、把 `q/c/n` 全称量化，八个分支全是「smash_valid + 泛化 IH」的同款套路，只是篇幅翻倍；本教程按主线取舍未收录，44.7 小结里给出复原路线。

### 44.4 抽象关系：tree_elems 与 priqueue_elems

不变量只管「形状合法」，还要一条**抽象关系**回答「这个堆里到底有哪些元素」。技巧是第 33 章的「置换规格」归纳版：**把 Permutation 写进构造子**，让关系只认「键集的任意重排」、不认具体顺序。

```coq
(* ---------- 44.4 抽象关系：tree_elems 与 priqueue_elems ---------- *)

Inductive tree_elems : tree -> list key -> Prop :=
| tree_elems_leaf : tree_elems Leaf nil
| tree_elems_node : forall bl br v tl tr b,
    tree_elems tl bl ->
    tree_elems tr br ->
    Permutation b (v :: bl ++ br) ->
    tree_elems (Node v tl tr) b.
```

`tree_elems_node` 的第三个前提是灵魂：树 `Node v tl tr` 关联到表 `b`，当且仅当 `b` 是 `v :: 左子树的表 ++ 右子树的表` 的**某个置换**——左右子树各关联到任意重排，根的键塞进哪都行。这与「BST 关联到中序遍历」的确定性关系刻意不同：优先队列本来就不承诺顺序。

```coq
(* 原书练习 priqueue_elems：参照 tree_elems 的「任意置换」技巧补全 *)
Inductive priqueue_elems : list tree -> list key -> Prop :=
| priqueue_elems_nil : priqueue_elems nil nil
| priqueue_elems_cons : forall t b q l al,
    tree_elems t b ->
    priqueue_elems q l ->
    Permutation al (b ++ l) ->
    priqueue_elems (t :: q) al.

Definition Abs (p : priqueue) (al : list key) := priqueue_elems p al.
```

原书把 `priqueue_elems` 留成 3 星练习（「与 tree_elems 基本同款」），这里补全：两个构造子就够——`nil` 关联 `nil`；cons 分量 `t` 关联 `b`、尾部关联 `l`，则整队关联 `b ++ l` 的任意置换。**不需要**给 `Leaf` 单设构造子：`tree_elems Leaf b` 逼出 `b = nil`，而 `nil ++ l` 与 `l` 可转换，`priqueue_elems (Leaf :: q) l` 自动可推导。`Abs` 就是这条关系的别名，与第 43 章 `PRIQUEUE` 签名里的 `Abs` 对齐。

```coq
Theorem priqueue_elems_ext : forall q e1 e2,
  Permutation e1 e2 -> priqueue_elems q e1 -> priqueue_elems q e2.
Proof.
  intros q e1 e2 P H.
  inversion H as [ | t b q0 l al Ht Hp Hperm]; subst.
  - apply Permutation_nil in P. subst. constructor.
  - apply priqueue_elems_cons with (b := b) (l := l);
      [exact Ht | exact Hp |].
    apply Permutation_trans with e1;
      [apply Permutation_sym; exact P | exact Hperm].
Qed.
```

第一条 sanity：**外置换可搬运**——`q` 关联 `e1`、`e1 ~ e2`，则 `q` 关联 `e2`。inversion 拿到构造子的见证表 `b/l`，用**同一对见证**重建推导，只需把置换链 `e2 ~ e1 ~ b ++ l` 接上。注意 `apply priqueue_elems_cons with (b := b) (l := l)` 必须显式给 `b/l`：目标里的表是 `e2`，unifier 推不出见证（实测报 `Unable to find an instance for the variables b, l`，见 44.8 坑位 5）。这条引理是 44.5 的万能搬运工。

```coq
Theorem tree_perm : forall t e1 e2,
  tree_elems t e1 -> tree_elems t e2 -> Permutation e1 e2.
Proof.
  intros t e1 e2 H1. revert e2.
  induction H1 as [ | bl br v tl tr b Hbl IHl Hbr IHr Hperm]; intros e2 H2.
  - inversion H2; subst. apply Permutation_refl.
  - inversion H2 as [ | bl' br' v' tl' tr' b' Hbl' Hbr' Hperm']; subst.
    apply Permutation_trans with (v :: bl ++ br); [exact Hperm |].
    apply Permutation_trans with (v :: bl' ++ br').
    + apply perm_skip. apply Permutation_app;
        [exact (IHl bl' Hbl') | exact (IHr br' Hbr')].
    + apply Permutation_sym. exact Hperm'.
Qed.
```

第二条 sanity（原书 2 星）：**同一棵树的两个元素表必置换**。对第一份推导归纳、第二份 inversion，两边的见证都置换到「根 :: 左 ++ 右」的规范形，中段用 `Permutation_app`（分块各自置换 ⇒ 拼接置换）+ `perm_skip`，首尾对称接管。注意 `induction ... as` 的名字是**交错落位**的（前提1、IH1、前提2、IH2、前提3）——写错顺序名字会张冠李戴，先 `Check tree_elems_ind` 看真实参数序（实测见 44.8 坑位 6）。

```coq
Theorem abs_perm : forall p al bl,
  priq p -> Abs p al -> Abs p bl -> Permutation al bl.
Proof.
  intros p al bl _ HA1. revert bl.
  induction HA1 as [ | t b q l al Ht HA1 IH Hperm]; intros bl HA2.
  - inversion HA2; subst. apply Permutation_refl.
  - inversion HA2 as [ | t' b' q' l' al' Ht' HA2' Hperm']; subst.
    apply Permutation_trans with (b ++ l); [exact Hperm |].
    apply Permutation_trans with (b' ++ l').
    + apply Permutation_app;
        [exact (tree_perm t b b' Ht Ht') | exact (IH l' HA2')].
    + apply Permutation_sym. exact Hperm'.
Qed.
```

第三条 sanity：**同一队列的两个抽象表必置换**——抽象关系是「单值 up to 置换」，规格因此良定。证明是 tree_perm 的队列版：分量层用 `tree_perm`、尾部层用归纳假设，`Permutation_app` 把两块拼起来。两个战术细节：`intros ... _ HA1` 把用不到的 `priq p` 直接丢掉——留着的话 `induction` 会**自动把它泛化进归纳谓词**，IH 平白多出一个 `priq q ->` 前提、后续喂参错位（实测报 `The term "l'" has type "list key" while it is expected to have type "priq q"`，见 44.8 坑位 7）；`revert bl` 让第二份抽象表进入归纳谓词。

```coq
Theorem empty_relate : Abs empty nil.
Proof. unfold Abs, empty. constructor. Qed.
```

空堆关联空表：一个构造子的事。原书在这一节还有 `can_relate`（任意合法堆都**存在**抽象表）与 `tree_elems_ext`/`priqueue_elems_ext` 的孪生练习——`can_relate` 是「先对树、再对队列」的两步平凡归纳（构造 `tree_elems_node`/`priqueue_elems_cons` 时置换给 `Permutation_refl` 即可），本教程从简未收录，留作读者复原练习。

### 44.5 操作保持抽象关系

不变量层与抽象层各自的「操作保持」定理齐了骨架，现在补抽象层最硬的两块：`smash_elems`（原书 3 星，warning「证明相当长」）与 `carry_elems`（原书 4 星）。

```coq
(* ---------- 44.5 操作保持抽象关系 ---------- *)

Theorem smash_elems : forall n t u bt bu,
  pow2heap n t -> pow2heap n u ->
  tree_elems t bt -> tree_elems u bu ->
  tree_elems (smash t u) (bt ++ bu).
Proof.
  intros n [x t1 [k a b | ] | ] [y u1 [k' a' b' | ] | ] bt bu Ht Hu Hbt Hbu;
    unfold pow2heap in Ht, Hu; simpl in Ht, Hu;
    try contradiction.
  inversion Hbt as [ | b1 b2 x' t1' t2' bt' Hb1 Hb2 Pbt]; subst.
  inversion Hbu as [ | b1' b2' y' u1' u2' bu' Hb1' Hb2' Pbu]; subst.
  inversion Hb2; subst. inversion Hb2'; subst.
  rewrite app_nil_r in Pbt, Pbu. simpl.
  destruct (y <? x) eqn:E.
  - (* 大者做根，小者做次根 *)
    apply tree_elems_node with (bl := y :: b1' ++ b1) (br := nil);
      [ | constructor |].
    + apply tree_elems_node with (bl := b1') (br := b1);
        [exact Hb1' | exact Hb1 | apply Permutation_refl].
    + apply Permutation_trans with ((x :: b1) ++ (y :: b1'));
        [apply Permutation_app; assumption |].
      rewrite app_nil_r. apply perm_skip.
      apply Permutation_trans with (y :: b1 ++ b1');
        [apply Permutation_sym; apply Permutation_middle
         | apply perm_skip; apply Permutation_app_comm].
  - (* 对称分支 *)
    apply tree_elems_node with (bl := x :: b1 ++ b1') (br := nil);
      [ | constructor |].
    + apply tree_elems_node with (bl := b1) (br := b1');
        [exact Hb1 | exact Hb1' | apply Permutation_refl].
    + apply Permutation_trans with ((x :: b1) ++ (y :: b1'));
        [apply Permutation_app; assumption |].
      rewrite app_nil_r. simpl.
      apply Permutation_trans with (x :: y :: b1 ++ b1');
        [apply perm_skip; apply Permutation_sym; apply Permutation_middle
         | apply perm_swap].
Qed.
```

前四行与 `smash_valid` 同款：形状清场只剩 `Node x t1 Leaf`、`Node y u1 Leaf`。然后两次 inversion 把两份元素表拆到规范形：`bt ~ x :: b1`（右子树是 Leaf，其表 `b2` 被 inversion 逼成 `nil`，再用 `app_nil_r` 从置换里擦掉）、`bu ~ y :: b1'`。以真分支为例，目标树是 `Node x (Node y u1 t1) Leaf`，构造推导时**见证表选规范形** `bl := y :: b1' ++ b1`、`br := nil`——剩下的纯粹是置换账：

- `bt ++ bu ~ (x :: b1) ++ (y :: b1')`：`Permutation_app`（两块各自置换）；
- `(x :: b1) ++ (y :: b1') ~ x :: y :: (b1 ++ b1')`：定义性化简；
- `x :: y :: (b1 ++ b1') ~ x :: y :: (b1' ++ b1)`：两次 `perm_skip` 加 `Permutation_app_comm`（换位）。

假分支对称，收尾换成 `perm_swap`（根与其脊头互换）。注意 `apply tree_elems_node with (bl := ...) (br := ...)` 必须显式给见证（坑位 5），且 `br := nil` 会在目标里留下 `... ++ []`——不先 `rewrite app_nil_r` 的话，`perm_skip` 对不上（实测见 44.8 坑位 10）。

```coq
Theorem carry_elems :
  forall q n, priq' n q ->
  forall t, (t = Leaf \/ pow2heap n t) ->
  forall eq et, priqueue_elems q eq ->
  tree_elems t et ->
  priqueue_elems (carry q t) (eq ++ et).
Proof.
  induction q as [ | u q' IH]; intros n Hq t Ht eq et Heq Het.
  - (* q = nil *)
    inversion Heq; subst.
    destruct t as [x t1 t2 | ].
    + (* t = Node : 落在末位 *)
      simpl.
      apply priqueue_elems_ext with (et ++ []);
        [rewrite app_nil_r; apply Permutation_refl |].
      apply priqueue_elems_cons with (b := et) (l := []);
        [exact Het | constructor | apply Permutation_refl].
    + (* t = Leaf : 空堆进空树 *)
      inversion Het; subst. simpl. constructor.
  - (* q = u :: q' *)
    simpl in Hq. destruct Hq as [Hu Hq'].
    destruct u as [y u1 u2 | ]; destruct t as [x t1 t2 | ].
    + (* u = Node, t = Node : 相撞进位 *)
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      destruct Hu as [Hul | Hup]; [discriminate Hul |].
      destruct Ht as [Htl | Htp]; [discriminate Htl |].
      cbn [carry].
      apply priqueue_elems_ext with (l0 ++ (et ++ b0)).
      * rewrite app_assoc.
        apply Permutation_trans with (b0 ++ (l0 ++ et));
          [apply Permutation_app_comm |].
        rewrite app_assoc. apply Permutation_app_tail.
        apply Permutation_sym. exact P_eq.
      * apply priqueue_elems_cons with (b := nil) (l := l0 ++ (et ++ b0));
          [constructor | | apply Permutation_refl].
        assert (Hsm : pow2heap (S n) (smash (Node x t1 t2) (Node y u1 u2)))
          by (apply smash_valid; assumption).
        assert (Hse : tree_elems (smash (Node x t1 t2) (Node y u1 u2)) (et ++ b0))
          by (apply (smash_elems n (Node x t1 t2) (Node y u1 u2) et b0); assumption).
        exact (IH (S n) Hq' _ (or_intror Hsm) l0 (et ++ b0) Hl0 Hse).
    + (* u = Node, t = Leaf : 原样保留 *)
      inversion Het; subst. rewrite app_nil_r.
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      apply priqueue_elems_ext with (b0 ++ l0);
        [apply Permutation_sym; exact P_eq |].
      apply priqueue_elems_cons with (b := b0) (l := l0);
        [exact Ht0 | exact Hl0 | apply Permutation_refl].
    + (* u = Leaf, t = Node : 直接放行 *)
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      inversion Ht0; subst. simpl in P_eq.
      cbn [carry].
      apply priqueue_elems_ext with (et ++ l0).
      * apply Permutation_trans with (l0 ++ et);
          [apply Permutation_app_comm
           | apply Permutation_app_tail; apply Permutation_sym; exact P_eq].
      * apply priqueue_elems_cons with (b := et) (l := l0);
          [exact Het | exact Hl0 | apply Permutation_refl].
    + (* u = Leaf, t = Leaf *)
      inversion Heq as [ | t0 b0 q0 l0 al0 Ht0 Hl0 P_eq]; subst.
      inversion Ht0; subst. simpl in P_eq.
      inversion Het; subst. rewrite app_nil_r.
      apply priqueue_elems_ext with l0;
        [apply Permutation_sym; exact P_eq |].
      apply priqueue_elems_cons with (b := nil) (l := l0);
        [constructor | exact Hl0 | apply Permutation_refl].
Qed.
```

全章最难的一块（原书 4 星），骨架与 `carry_valid` 严格平行，但每个分支都多出一个**固定动作**：构造子的表索引是 `b ++ l`，而目标是 `eq ++ et`，二者只在置换意义下相等——unifier 不做置换，所以必须**先在规范表上构造推导、再用 `priqueue_elems_ext` 搬运到目标表**。这个「构造 + 搬运」两步走是本章与第 43 章（`Abs` 是句法等同、constructor 直击）最本质的证明差异。

四个分支的置换账各不相同：

- **(u=Node, t=Node) 相撞进位**：inversion `Heq` 得 `eq ~ b0 ++ l0`（位上的树表 `b0`、尾部表 `l0`）。规范结果表选 `l0 ++ (et ++ b0)`——尾部队列在前、新碰撞树（元素 `et ++ b0`，注意 `smash_elems` 的结论是 `bt ++ bu`、**t 的表在前**，方向搞反会 unify 失败，实测见 44.8 坑位 9）在后。搬运用的置换是三段轮换：`l0 ++ et ++ b0 ~ b0 ++ l0 ++ et ~ (b0 ++ l0) ++ et ~ eq ++ et`，分别由 `app_assoc`（改括号）、`Permutation_app_comm`（前两段换位）、`Permutation_app_tail`（后缀相同整体换）完成。IH 全参应用喂八个参数——`n`、不变量前提、树、`t = Leaf ∨ pow2heap` 证据、两个表、两个关系证据，缺一即报类型错（坑位 11）。
- **(u=Node, t=Leaf) 原样保留**：`et` 被 inversion 逼成 `nil`，`rewrite app_nil_r` 后目标表就是 `eq`，直接搬 `b0 ++ l0 ~ eq`。
- **(u=Leaf, t=Node) 直接放行**：`b0` 逼成 `nil`、`eq ~ l0`，结果表 `et ++ l0`，一次换位（`app_comm`）加一次后缀搬运。
- **(u=Leaf, t=Leaf)**：两边都空，目标表化简到 `l0` 的对称。

```coq
Theorem insert_relate :
  forall p al k, priq p -> Abs p al -> Abs (insert k p) (k :: al).
Proof.
  intros p al k Hp HA. unfold insert, priq, Abs in *.
  apply priqueue_elems_ext with (e1 := al ++ [k]).
  - apply Permutation_sym. apply Permutation_cons_append.
  - apply (carry_elems p 0 Hp).
    + right. simpl. exact I.
    + exact HA.
    + apply tree_elems_node with (bl := nil) (br := nil);
        [constructor | constructor | apply Permutation_refl].
Qed.
```

规格层的收获：`insert k p` 关联 `k :: al`——**新键确定出现在抽象表的头上**，这正是 PRIQUEUE 签名里 `insert_relate` 公理。三步：`carry_elems` 在索引 0 展开，拿到 `Abs (carry p (Node k Leaf Leaf)) (al ++ [k])`；标准库 `Permutation_cons_append`（`x :: l ~ l ++ [x]`）的对称把 `al ++ [k]` 搬到 `k :: al`；单元素树的推导由 `tree_elems_node` 双 `nil` 见证直接构造。第 43 章里这是一行 `constructor`，本章要动用整条 carry_elems 链——表示越精巧，规格越贵。

### 44.6 主定理：insert 的双重正确性

```coq
(* ---------- 44.6 主定理：insert 的双重正确性 ---------- *)

Theorem insert_correct :
  forall x q al, priq q -> Abs q al ->
  priq (insert x q) /\ Abs (insert x q) (x :: al).
Proof.
  intros x q al Hp HA. split.
  - apply insert_priq. exact Hp.
  - apply insert_relate; [exact Hp | exact HA].
Qed.

Print Assumptions insert_correct.

End Ex44Binom.
```

主定理把两层证明合拢：对合法输入，`insert` **既保持表示不变量、又保持抽象关系**——这正是第 43 章 PRIQUEUE 签名对 `insert` 的全部要求（`insert_priq` + `insert_relate` 两条公理）。`Print Assumptions` 实测输出 `Closed under the global context`：从进位链程序、pow2 堆不变量到置换同构，整条证据链无公理、无 Admitted。

### 44.7 本章小结

- **表示**：二项式堆是「树的二进制数」——第 i 位是深 i 的 2 的幂堆或 `Leaf`；`smash` 是同位相撞、`carry`/`join` 是带进位的竖式加法，insert/delete_max/merge 全部 O(log N)。
- **不变量层**：`priq'` 是**带位置索引**的归纳谓词，一切证明必须 `forall q n` 泛化索引；`smash_valid`/`carry_valid` 的分支结构与程序子句一一对应。
- **抽象层**：`tree_elems`/`priqueue_elems` 把「任意置换」编进构造子；配套三件套 sanity——`priqueue_elems_ext`（外置换搬运）、`tree_perm`（树内唯一性）、`abs_perm`（队列层唯一性）。
- **证明模式**：构造子见证必须显式 `with (b := ...)` 给出；目标表与规范表差一个置换时，先构造、后 `ext` 搬运——这与第 43 章「Abs 即等同」的直击法形成对照。
- **未收录的原书练习**：`join_valid`（3 星选做）= 44.3 套路对 `p` 归纳再走 8 个分支，`merge_priq` 是它的一行推论；`carry_elems` 之上的 `join_elems`/`merge_relate`（4 星）与 `delete_max_*`（5 星，先证 `find_max` 与 `delete_max_aux` 的交互）同法可复。原书的 `can_relate` 是两步平凡归纳。

### 44.8 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过。

1. **`>?` 记号已不存在**（44.1）：写 `x >? y` 实测报 `Error: Syntax error: [term] expected after '>' (in [term]).`。stdlib 9.x 只保留 `<?`/`<=?`，一律写成 `y <? x`，布尔引理相应用 `Nat.ltb_lt`（true ↔ <）与 `Nat.ltb_ge`（false ↔ ≥）。
2. **嵌套 intro 模式的分支顺序按构造子声明序**（44.3）：`intros n [x t1 [ | k a b] | ]` 实测报 `Error: Unexpected name (no introduction patterns were expected in the branch).`——`tree` 的 `Node` 声明在前（3 个参数）、`Leaf` 在后（0 个），嵌套槽位必须写成 `[x t1 [k a b | ] | ]`。
3. **`destruct` 布尔必须在 `simpl` 之后**（44.3）：`smash_valid` 里先 `destruct (y <? x)` 再 `simpl`，destruct 扑空（目标里还没有这个布尔）、后续 `split` 实测报 `Error: Not an inductive definition.`。顺序倒过来：`simpl. destruct (y <? x) eqn:E.`。
4. **`simpl` 会把 `smash`/`join` 抖开成嵌套 match**（44.3）：`join (p1 :: p') [] c` 被 `simpl` 化成对 `p1` 的卡壳平凡匹配，`apply carry_valid` 实测报 `Unable to unify ... "match p1 with | Node _ _ _ | _ => carry (p1 :: p') c end"`。对策：白名单化简 `cbn [join priq']` 只展开指定常量，`smash` 保持折叠；确实卡在 scrutinee 上时先 `destruct` 它。
5. **关系构造子的见证推不出来**（44.4/44.5）：对 `priqueue_elems (t :: q) al` 直接 `constructor` 实测报 `Error: Unable to find an instance for the variables b, l.`（`tree_elems_node` 同理报 `bl, br`）——构造子里的 `b`、`l` 只出现在前提里，unifier 无从确定。必须 `apply priqueue_elems_cons with (b := ...) (l := ...)` 显式给见证。
6. **`induction ... as` 的名字交错落位**（44.4）：`tree_elems_node` 的归纳原理参数序是「前提1、IH1、前提2、IH2、前提3」，`as [ | ... Hbl Hbr Hperm IHl IHr]` 会让 `Hbr` 拿到 IH、`Hperm` 拿到前提2，实测在 `exact Hperm` 处报 `The term "Hperm" has type "tree_elems tr br" while it is expected to have type "Permutation b (v :: bl ++ br)."`。动手前先 `Check tree_elems_ind` 看真实顺序。
7. **没用到的假设会被 induction 自动泛化**（44.4）：`abs_perm` 的 `priq p` 留在上下文里（签名要求它在），`induction HA1` 会把它卷进归纳谓词，IH 变成 `priq q -> forall bl, ...`，后续 `IH l' HA2'` 实测报 `The term "l'" has type "list key" while it is expected to have type "priq q".`。对策：`intros p al bl _ HA1` 或先 `clear Hp`。
8. **`destruct u; destruct t` 的目标序是 (Node,Node)、(Node,Leaf)、(Leaf,Node)、(Leaf,Leaf)**（44.5）：把「u=Leaf, t=Node」的脚本错放到第二个分支，实测在 `exact P_eq` 处报 `The term "P_eq" has type "Permutation eq (b0 ++ l0)" while it is expected to have type "Permutation eq l0".`——对 `tree_elems (Node ...) b0` 做 inversion 得到的是 `bl/br`，而不是想要的 `b0 = nil`。
9. **`smash_elems` 的结论是 `bt ++ bu`，t 的表在前**（44.5）：carry 进位分支若把规范表写成 `b0 ++ et`，`apply (smash_elems n ...)` 实测报 `Unable to unify "tree_elems (smash ...) (et ++ b0)" with "tree_elems (smash ...) (b0 ++ et)"`。参数按 `(n t u bt bu)` 传全即可对齐。
10. **构造子里的 `br := nil` 留下 `X ++ []` 挡住化简**（44.5）：`apply tree_elems_node with (br := nil)` 之后目标右侧带 `(... ++ [])`，`perm_skip` 实测报 `Unable to unify "Permutation (?x :: ?l) (?x :: ?l')" with "Permutation ((fix app ...) b1 (y :: b1')) ((y :: b1' ++ b1) ++ [])"`。先 `rewrite app_nil_r` 把尾巴擦掉再走置换链。
11. **IH 全参应用的参数位**（44.5）：`carry_elems` 的 IH 是 `forall n, priq' n q' -> forall t, (t = Leaf ∨ pow2heap n t) -> forall eq et, ...`，证据夹在量词中间。写成 `(IH (S n) Hq' (smash ...) l0 Hl0 (et ++ b0) Hse)` 实测报 `The term "Hl0" has type "priqueue_elems q' l0" while it is expected to have type "list key".`——八个位置按量词序排齐：`(IH (S n) Hq' _ (or_intror Hsm) l0 (et ++ b0) Hl0 Hse)`。

---

上一章：[43 · 优先队列](43-priqueue.md) ｜ 下一章：[45 · Trie：字符串键的映射](45-trie.md) ｜ 返回：[README](../README.md)
