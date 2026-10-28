# 41 · 红黑树
对应示例：`../examples/41_redblack.v`（`Module Ex41Redblack`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

VFA 篇（33–47 章）走到这里，数据结构一线已经铺好了两级台阶：第 28 章在实战里写过裸 BST 的 `lookup/insert`，第 39 章给 BST 配上 `ForallT/BST` 不变量并把 `insert/lookup/elements` 三条正确性全部证完，第 40 章又把验证过的代码抽取到 OCaml。但第 39 章的 BST 有个抹不掉的软肋——**它不保证平衡**：顺序插入 1,2,3,…,N 会把它退化成一条链，`lookup` 从 O(log N) 滑向 O(N)。本章（VFA《Redblack》章）补上最后一块：**红黑树 = BST + 两条颜色平衡不变量**——

- **局部不变量**：任何红结点的孩子都不是红的（「红节点不共子」）；
- **全局不变量**：从根到每个叶子的路径上黑结点数目相同（**等黑高**）。

两条合起来保证没有一片叶子比另一片深过一倍（「近似平衡」），操作复杂度回到 O(log N)。算法取 Okasaki 的纯函数式版本（也是 Coq 标准库 `MSetRBT` 的底子）；在实现层，全部巧思集中在**平衡修正 `balance`**——它是红黑树的心脏：`ins` 沿搜索路径下行（与 BST 插入几乎相同），`balance` 在回程逐结点检查「红根带红孩子」并做旋转修正。而证明层的主线是**不变量保持**：`empty_tree_BST → balance_BST → insP/ins_BST → insert_BST`，一路把「插入后仍是 BST」从平衡修正的几十个情形里扛出来。本章示例对原书做了两处适配：键用 `nat` 与 `<?`（原书用 Extract 章公理化的 `int` 并按 `Abs` 比较，验证主线不变），原书的 `bdestruct/inv` 全部换成标准战术 `destruct/discriminate/inversion`。颜色不变量（原书 `RB/ins_RB/insert_RB` 的黑高论证）与 lookup 三方程不在本章示例内——41.2 节会实测说明：**BST 证明甚至不区分 balance 的五种情形**，把五种情形钉死的是颜色不变量那一侧。

### 41.1 表示：颜色、树与 lookup

文件头与树的表示：

```coq
(* 41 红黑树 —— 插入、平衡不变量与正确性 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex41Redblack.

(* ---------- 41.1 表示：颜色、树与 lookup ---------- *)

(* 键取 nat（原书用 Extract 章公理化的 int 并按 Abs 比较，这里换成 nat
   直接用 <?，验证主线完全不变）。 *)
Definition key := nat.

Inductive color := Red | Black.

Inductive tree (V : Type) : Type :=
| E : tree V
| T : color -> tree V -> key -> V -> tree V -> tree V.

Arguments E {V}.
Arguments T {V}.

Definition empty_tree (V : Type) : tree V :=
  E.

(* lookup 与第 28 章 BST 完全同构，只是 T 结点多带一个被忽略的 color。 *)
Fixpoint lookup {V : Type} (d : V) (x : key) (t : tree V) : V :=
  match t with
  | E => d
  | T _ tl k v tr =>
    if x <? k then lookup d x tl
    else if k <? x then lookup d x tr
    else v
  end.
```

与第 39 章的 `tree` 相比只有一个差别：`T` 构造子**多带一个 `color`**（放在最前），`E` 仍是无内容的空树。`Arguments E {V}. / Arguments T {V}.` 把类型参数 `V` 声明为隐式——这两行不是装饰：实测删掉 `Arguments E {V}.` 后，`Definition empty_tree (V : Type) : tree V := E.` 直接编译失败（`The term "E" has type "forall V : Type, tree V" while it is expected to have type "tree V"`，见 41.6 坑 1）。`lookup` 与第 28 章逐字同构：模式 `T _ tl k v tr` 的下划线**吃掉颜色**——查询永远不看颜色，红黑树首先是第 39 章那棵 BST，颜色只为平衡服务。`empty_tree` 是黑高为零的空树 `E`。

### 41.2 插入：balance 的五种情形与 ins

红黑树的全部机关在插入。先看心脏 `balance`：

```coq
(* ---------- 41.2 插入：balance 的五种情形与 ins ---------- *)

(* ins 沿搜索路径下行（与 BST 插入几乎相同），balance 在回程重平衡。
   balance 的 match 一共覆盖五种情形：c = Red 时原样返回（情形 0）；
   c = Black 时看 t1/t2 里有没有「红结点带红孩子」——左左、左右、
   右左、右右四种旋转（情形 1-4），都没有则染黑原样返回。 *)
Definition balance
           {V : Type} (c : color) (t1 : tree V) (k : key) (vk : V)
           (t2 : tree V) : tree V :=
  match c with
  | Red => T Red t1 k vk t2
  | _ => match t1 with
        | T Red (T Red a x vx b) y vy c =>
            T Red (T Black a x vx b) y vy (T Black c k vk t2)
        | T Red a x vx (T Red b y vy c) =>
            T Red (T Black a x vx b) y vy (T Black c k vk t2)
        | _ => match t2 with
              | T Red (T Red b y vy c) z vz d =>
                  T Red (T Black t1 k vk b) y vy (T Black c z vz d)
              | T Red b y vy (T Red c z vz d) =>
                  T Red (T Black t1 k vk b) y vy (T Black c z vz d)
              | _ => T Black t1 k vk t2
              end
        end
  end.
```

`balance c t1 k vk t2` 是「用部件搭一个结点」的智能构造子，五种情形按外层 match 逐个读：

- **情形 0（`c = Red`）**：原样搭 `T Red t1 k vk t2`，连看都不看 t1/t2。为什么父亲是红时反而无事可做——这属于颜色不变量一侧的论证（原书 `ins_RB`：父为红时 `ins` 的返回已是合格红黑树），本章的 BST 证明不需要它。
- **情形 1 左左（LL）**：`t1 = T Red (T Red a x vx b) y vy c`——左孩子红、**左孩子的左孩子**也红。修正为 `T Red (T Black a x vx b) y vy (T Black c k vk t2)`：孙键 `y` 提升为新红根，`x` 子树与「`c` + 当前键 `k`」各染黑挂在两边。
- **情形 2 左右（LR）**：`t1 = T Red a x vx (T Red b y vy c)`——左孩子红、左孩子的**右**孩子红。产出形状与 LL 完全相同，仍是 `y` 做红根。
- **情形 3 右左（RL）/ 情形 4 右右（RR）**：镜像，检查 `t2` 的两个孙位，产出 `T Red (T Black t1 k vk b) y vy (T Black c z vz d)`。
- **情形 5（兜底 `_`）**：没有红红违例，`T Black t1 k vk t2` 染黑原样。

四种旋转的共同形状是「**红根 + 两个黑孩子**」，且只重排不改中序——`a、x、b < y < c、k、…` 这套大小关系原样搬进新树，这正是 41.4 的 `balance_BST` 要机器验证的东西。黑色高度为什么不变，同样属于颜色侧论证，本章从略。一个值得玩味的实测：把情形 4（RR）整个分支删掉，**本章全部证明照样编译通过**——兜底 `_` 会吞掉 RR 情形（`T Black t1 k vk t2`），而 BST 性质对「怎么转」毫不敏感；真正把五种情形钉死的是颜色不变量。反过来，删掉的是兜底分支才会被编译器拦下（`Non exhaustive pattern-matching`，见 41.6 坑 2）。

搭好了心脏，插入就是「下行找位 + 回程过 balance」：

```coq
Fixpoint ins {V : Type} (x : key) (vx : V) (t : tree V) : tree V :=
  match t with
  | E => T Red E x vx E
  | T c a y vy b =>
    if x <? y then balance c (ins x vx a) y vy b
    else if y <? x then balance c a y vy (ins x vx b)
    else T c a x vx b
  end.

(* ins 可能把根染红；根的红父亲不存在，但为了局部不变量统一把根染黑。 *)
Definition make_black {V : Type} (t : tree V) : tree V :=
  match t with
  | E => E
  | T _ a x vx b => T Black a x vx b
  end.

Definition insert {V : Type} (x : key) (vx : V) (t : tree V) :=
  make_black (ins x vx t).
```

`ins` 的骨架就是第 28/39 章的 BST 插入：空树处造新结点 `T Red E x vx E`（**新结点染红**——红结点不计入路径黑数，插入才可能不打乱等黑高；这句同样是颜色侧的读法），非空时三分支——`x < y` 左行、`y < x` 右行、相等则原地换值 `T c a x vx b`。差别全在回程：递归结果在每一步都经过 `balance c … y vy …` 再搭回树上，违例当场修掉。`ins` 可能把整棵树的根染红，`make_black` 统一把根拍回黑色——根没有父亲，「红根」并不违反局部不变量，但根为黑让全局叙述（黑高从根数起）干净，VFA 的 `RB` 谓词正是以「假想父颜色 + 应有黑高」参数化的。对外接口 `insert = make_black ∘ ins`。

最后是 `elements`——把树摊平成键值表，与第 39 章逐字一致（`T _ l k v r` 的下划线照旧吃掉颜色），配一个现场计算的例子：

```coq
Fixpoint elements_aux {V : Type} (t : tree V) (acc : list (key * V))
  : list (key * V) :=
  match t with
  | E => acc
  | T _ l k v r => elements_aux l ((k, v) :: elements_aux r acc)
  end.

Definition elements {V : Type} (t : tree V) : list (key * V) :=
  elements_aux t [].

Example elements_example :
  elements (insert 3 30 (insert 1 10 (insert 2 20
            (insert 5 50 (insert 4 40 (empty_tree nat))))))
  = [(1, 10); (2, 20); (3, 30); (4, 40); (5, 50)].
Proof. reflexivity. Qed.
```

`elements_aux` 是带累加器的中序遍历：左子树先走，当前键拼在右子树结果前。`elements_example` 乱序插入 3,1,2,5,4，`reflexivity` 实测一步算出**升序**表——注意输出顺序是中序（按键排序），不是插入顺序，把它当成插入序写期望值会得到 `Unable to unify`（41.6 坑 9）。

### 41.3 情形分析自动化：ins_not_E

验证前先热身，练一件后面要反复用的兵器——**情形分析自动化**：

```coq
(* ---------- 41.3 情形分析自动化：ins_not_E ---------- *)

(* 热身：任何 insert 的中间结果 ins 都不是空树。原书在这里用
   bdestruct/inv，本章全部换成标准战术：destruct 撕布尔与构造子、
   discriminate 关构造子等式。match goal 找到「目标是对 color 或
   tree 的 match」就 destruct，见到 T <> E 就 discriminate。 *)
Lemma ins_not_E : forall (V : Type) (x : key) (vx : V) (t : tree V),
    ins x vx t <> E.
Proof.
  intros V x vx t. destruct t as [ | c t1 k v t2]; simpl.
  - discriminate.
  - unfold balance.
    repeat
      match goal with
      | |- (if ?b then _ else _) <> _ => destruct b
      | |- match ?c with Red => _ | Black => _ end <> _ => destruct c
      | |- match ?t with E => _ | T _ _ _ _ _ => _ end <> _ => destruct t
      | |- T _ _ _ _ _ <> E => discriminate
      end.
Qed.
```

命题本身平凡：`ins` 要么造新结点要么复制结点，结果永远是 `T`。手工做会很快陷入泥潭：`destruct t` 后，`simpl` 把 `ins (T c t1 k v t2)` 展开成 `(if x <? k then balance c (ins x vx t1) k v t2 else …) <> E`——目标是**对布尔、color、tree 的三层嵌套 match**，每层都要手动 destruct。`repeat match goal` 把这三层交给四条模式：目标是 `if` 就撕布尔、目标是 `match c` 就 destruct color、目标是 `match t` 就 destruct tree、目标已是 `T _ <> E` 就 `discriminate` 关掉。`repeat` 反复推进直到四条模式都匹配不上（所有目标都被 discriminate 消灭）。

有个前置动作不能省：`unfold balance`。`balance` 是 `Definition`，`simpl` 对它纹丝不动（simpl 只自动展开 Fixpoint 对构造子的应用）；不 unfold，剩下 `balance c (ins x vx t1) k v t2 <> E` 这样的目标，四条模式一条都够不着，`discriminate` 实测报 `No primitive equality found`，最后 `Qed` 报 `Attempt to save an incomplete proof`（41.6 坑 3）。原书在这里用的是 `bdestruct`（撕布尔并顺手给出 `x < k` 或 `x >= k` 的命题形式）和 `inv`（inversion+subst+clear 三合一，VFA 的 SfLib 提供）；本章全部换成标准战术——效果等价，且不依赖自定义库（实测裸写 `inv H` 在 stdlib 环境直接报 `The reference inv was not found`，41.6 坑 7）。

### 41.4 BST 不变量：ForallT、balance_BST 与 insert_BST

现在进入正题。红黑树的正确性分两层：**功能层**——它得是一棵正确的搜索树（BST：左小右大，`lookup/elements` 因此可信）；**结构层**——它得真的平衡（颜色不变量）。本章证明主线在功能层：只要 `balance` 不打乱中序、`ins` 走对方向，BST 性质就在插入中幸存。不变量从第 39 章原样搬来，唯一改动是 `T` 多了颜色维度：

```coq
(* ---------- 41.4 BST 不变量：ForallT、balance_BST 与 insert_BST ---------- *)

(* ForallT P t：树上每个结点 (k,v) 都满足 P k v。 *)
Fixpoint ForallT {V : Type} (P : key -> V -> Prop) (t : tree V) : Prop :=
  match t with
  | E => True
  | T _ l k v r => P k v /\ ForallT P l /\ ForallT P r
  end.

Inductive BST {V : Type} : tree V -> Prop :=
| ST_E : BST E
| ST_T : forall (c : color) (l : tree V) (k : key) (v : V) (r : tree V),
    ForallT (fun k' _ => k' < k) l ->
    ForallT (fun k' _ => k' > k) r ->
    BST l ->
    BST r ->
    BST (T c l k v r).

Lemma empty_tree_BST : forall (V : Type), BST (@empty_tree V).
Proof. unfold empty_tree. constructor. Qed.
```

`ForallT P t` 是「逐结点谓词」：每个结点的 `(k,v)` 都满足 `P k v`。`BST` 与 39 章的版本逐字同构（构造子改名 `ST_E/ST_T`），`ST_T` 只多量化了一个 `c : color` 且前提里完全不看它——**颜色对 BST 无关紧要**，这句话就是本章证明分层的根。`empty_tree_BST` 一行构造。

下面三条是 `balance_BST` 自动化要用的「单调性」弹药，先是蕴涵提升：

```coq
Lemma ForallT_imp : forall (V : Type) (P Q : key -> V -> Prop) t,
    ForallT P t ->
    (forall k v, P k v -> Q k v) ->
    ForallT Q t.
Proof.
  intros V P Q t. induction t as [ | c l k v r IHl IHr]; intros HP Himp.
  - exact I.
  - destruct HP as [Hk [Hl Hr]].
    repeat split; auto.
Qed.
```

对树归纳：结点处把 `ForallT P` 拆三份，根用 `Himp`、两棵子树分别交给 IH。真正上膛的是两条接力引理：

```coq
(* 两条单调性小引理：整棵子树的键都 > k（或 < k），而 k 又 > k0
   （或 < k0），则子树全部键都 > k0（或 < k0）。供 balance_BST 的
   自动化收尾用。 *)
Lemma ForallT_greater : forall (V : Type) (t : tree V) (k k0 : key),
    ForallT (fun k' _ => k' > k) t ->
    k > k0 ->
    ForallT (fun k' _ => k' > k0) t.
Proof.
  intros V t k k0 H Hk.
  eapply ForallT_imp.
  - exact H.
  - intros k' v Hkv. simpl in Hkv. lia.
Qed.

Lemma ForallT_less : forall (V : Type) (t : tree V) (k k0 : key),
    ForallT (fun k' _ => k' < k) t ->
    k < k0 ->
    ForallT (fun k' _ => k' < k0) t.
Proof.
  intros V t k k0 H Hk.
  eapply ForallT_imp.
  - exact H.
  - intros k' v Hkv. simpl in Hkv. lia.
Qed.
```

「子树全部键 > k 且 k > k0 ⇒ 子树全部键 > k0」——纯传递性，但必须以 `ForallT` 整体的形式备用，因为 41.4 的自动化最后剩的目标全是这种形状。注意 `simpl in Hkv` 这半行：`ForallT_imp` 兑出来的 `Hkv` 是个 β-红衣 `(fun k' _ => k' > k) k' v`，直接 `lia` 实测报 `Tactic failure: Cannot find witness.`（41.6 坑 4）——先 simpl 把它规约成 `k' > k` 才是 lia 认识的算术命题。

主角登场——`balance` 保 BST：

```coq
(* balance 保 BST：手工展开后约 41 类情形。自动化按四条规则推进：
   假设里见到 ForallT _ (T ...) 就拆成根/左/右三份；假设里见到
   BST (T ...) 就 inversion 出孙辈的界；目标里见到 T 就 constructor；
   目标是 ForallT/其余算术不等式就 split + auto + lia。 *)
Lemma balance_BST : forall (V : Type) (c : color) (l : tree V) (k : key)
                      (v : V) (r : tree V),
    ForallT (fun k' _ => k' < k) l ->
    ForallT (fun k' _ => k' > k) r ->
    BST l ->
    BST r ->
    BST (balance c l k v r).
Proof.
  intros V c l k v r PL PR BL BR. unfold balance.
  repeat
    match goal with
    | H : ForallT _ (T _ _ _ _ _) |- _ => destruct H as [? [? ?] ]
    | H : BST (T _ _ _ _ _) |- _ => inversion H; subst; clear H
    | |- BST (T _ _ _ _ _) => constructor
    | |- BST (match ?c with Red => _ | Black => _ end) => destruct c
    | |- BST (match ?t with E => _ | T _ _ _ _ _ => _ end) => destruct t
    | |- ForallT _ (T _ _ _ _ _) => repeat split
    end;
    auto; try lia.
  (* 剩下的都是「子树全部键 <(>) 某个中间键」的目标，交给两条
     单调性引理接力。 *)
  all: try eapply ForallT_greater; try eapply ForallT_less; eauto; try lia.
Qed.
```

这是本章最重的一块证明，思路是**把 `balance` 的情形分析整个交给自动化**。`unfold balance` 后目标是嵌套 match，六条 `match goal` 规则分两组：

- **拆假设**：`H : ForallT _ (T _ _ _ _ _)` 就 `destruct H as [? [? ?] ]`——把「整棵子树满足」拆成根/左/右三份（`?` 让 Coq 自己起名）；`H : BST (T _ _ _ _ _)` 就 `inversion H; subst; clear H`——inversion 出「孙辈键相对根的界」并代入、清场。**`clear H` 千万不能省**：不 clear 的话 `repeat` 会对同一条假设无限重复 inversion，编译器不报错、只是永远卡死（实测基线 7.7 秒编完的文件，去掉 `clear H` 后 25 秒仍无输出，只能 kill，41.6 坑 6）。
- **推目标**：目标是 `BST (T …)` 就 `constructor`（拆成四个子目标，交给后面的 `auto` 用假设喂饱）；目标是 `match c / match t` 就 destruct 情形；目标是 `ForallT _ (T …)` 就 `repeat split` 拆三份。

每轮迭代后缀 `; auto; try lia` 把已经能关的目标当场关掉。跑完 `repeat`，实测**恰好剩 41 个目标**（用 `Show 41` 探针验证成功、`Show 42` 报 `No such goal`，与原书 "41 cases remain" 一致）——清一色是「某棵子树的全部键 `<`（或 `>`）某个中间键」，例如 `ForallT (fun k' _ => k' < k1) l2`，手里的弹药是 `H1 : ForallT (fun k' _ => k' < k) l2` 与 `H2 : k1 > k`——正好 `ForallT_less` 一趟接力。收尾的 `all:` 行对每个剩余目标依次尝试两条单调性引理加 `eauto; try lia`。手工做这 41 个情形（原书第一版尝试就是这么 Abort 的）正是本章要用自动化的原因。

接着三块小料，把 `balance` 的「逐结点保持」和 `ins` 的两件套补齐：

```coq
(* balance 保留任意逐结点谓词 P。 *)
Lemma balanceP : forall (V : Type) (P : key -> V -> Prop) (c : color)
                   (l r : tree V) (k : key) (v : V),
    ForallT P l ->
    ForallT P r ->
    P k v ->
    ForallT P (balance c l k v r).
Proof.
  intros V P c l r k v Hl Hr Hk. unfold balance.
  repeat
    match goal with
    | H : ForallT _ (T _ _ _ _ _) |- _ => destruct H as [? [? ?] ]
    | |- ForallT _ (match ?c with Red => _ | Black => _ end) => destruct c
    | |- ForallT _ (match ?t with E => _ | T _ _ _ _ _ => _ end) => destruct t
    | |- ForallT _ (T _ _ _ _ _) => repeat split
    end;
    auto.
Qed.
```

`balanceP` 说 balance 不增不减结点内容：任意谓词 P 只要先前对 l、r、根成立，转完仍对整树成立。自动化结构与 `balance_BST` 同款但更简——不需要 inversion（没有界的推理），`auto` 就能收尾。它是 `ins_BST` 的关键弹药：**新插的键值对要能「穿过」balance 出现在结果里**。

```coq
(* ins 保留任意逐结点谓词 P。对 t 归纳，无需情形自动化。 *)
Lemma insP : forall (V : Type) (P : key -> V -> Prop) (t : tree V)
               (k : key) (v : V),
    ForallT P t ->
    P k v ->
    ForallT P (ins k v t).
Proof.
  intros V P t. induction t as [ | c l IHl k' v' r IHr]; intros k v H HP.
  - simpl. repeat split; auto.
  - simpl in H. destruct H as [Hk [Hl Hr]]. simpl.
    destruct (Nat.ltb k k') eqn:E1.
    + apply balanceP; [apply IHl; auto | auto | auto].
    + destruct (Nat.ltb k' k) eqn:E2.
      * apply balanceP; [auto | apply IHr; auto | auto].
      * repeat split; auto.
Qed.
```

`insP` 开始出现本章的**归纳结构**样板：`intros` 只领到 `t` 为止（`k v` 留着），`induction t` 之后在每个分支里再 `intros k v H HP`——这样 IH 对任意待插的 `k v` 都可用。E 基例造红结点，`repeat split; auto` 用 `HP` 喂根、`True` 喂两侧；T 分支把 `ForallT` 拆三份、`destruct (Nat.ltb …) eqn:E1` 撕开布尔三分：左路 `balanceP` + IHl（新结点在左子树里）、右路对称、等键路原地换值。注意这里**不需要**情形自动化——`balance` 的所有情形都被 `balanceP` 一个引理打包了。

```coq
Lemma ins_BST : forall (V : Type) (t : tree V) (k : key) (v : V),
    BST t ->
    BST (ins k v t).
Proof.
  intros V t. induction t as [ | c l IHl k' v' r IHr]; intros k v H.
  - simpl. repeat constructor.
  - inversion H; subst. simpl.
    destruct (Nat.ltb k k') eqn:E1.
    + apply Nat.ltb_lt in E1.
      apply balance_BST.
      * apply insP; assumption.
      * assumption.
      * apply IHl; assumption.
      * assumption.
    + destruct (Nat.ltb k' k) eqn:E2.
      * apply Nat.ltb_lt in E2.
        apply balance_BST.
        -- assumption.
        -- apply insP; assumption.
        -- assumption.
        -- apply IHr; assumption.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkk : k = k') by lia. subst k'.
        constructor; assumption.
Qed.
```

`ins_BST` 是 `insP` 与 `balance_BST` 的会师，归纳结构同款（intros 到 `t`，induction 后每分支再 `intros k v H`）。T 分支先 `inversion H; subst` 把 `BST (T c l k' v' r)` 拆成四件套（左右界 + 左右 BST），然后三路：左行时 `Nat.ltb_lt` 把布尔兑成 `k < k'`，交给 `balance_BST` 的四个子目标——**新左树的界用 `insP` 造**（P 取 `fun k' _ => k' < y`，旧左树的界与 IH 拼起来）、右界原样 `assumption`、左右 BST 由 IHl 与原假设供给；右路对称；等键路 `Nat.ltb_ge` 两次兑出 `k >= k'` 与 `k' >= k`，`lia` 证出 `k = k'`、`subst` 之后 `constructor; assumption` 一行收。那个 `assert … by lia. subst` 不能省：不把 `k` 与 `k'` 划上等号，constructor 生成的子目标（关于 `k`）与手里的旧界（关于 `k'`）对不上号，实测 `assumption` 报 `No such assumption`（41.6 坑 5）。

最后收口——`insert` 保 BST，无需归纳：

```coq
Theorem insert_BST : forall (V : Type) (t : tree V) (v : V) (k : key),
    BST t ->
    BST (insert k v t).
Proof.
  intros V t v k H. unfold insert.
  assert (Hins : BST (ins k v t)) by (apply ins_BST; assumption).
  destruct (ins k v t) as [ | c' l' k' v' r'] eqn:Ei.
  - exfalso. exact (ins_not_E V k v t Ei).
  - inversion Hins; subst. constructor; assumption.
Qed.

Print Assumptions insert_BST.

End Ex41Redblack.
```

三板斧：`assert Hins` 先把 `ins` 的 BST 拿下（`ins_BST` 一行）；`destruct (ins k v t) eqn:Ei` 对 `make_black` 的 scrutinee 做情形分析；E 分支用 41.3 的热身引理 `ins_not_E` 直接矛盾关掉（`Ei : ins k v t = E` 正是它要反驳的等式）；T 分支 `inversion Hins` 拆出四个前提，`make_black` 只改颜色，`constructor; assumption` 按原样重建。顺带一提：E 分支实测换成 `constructor` 也能过（`make_black E` 被统一器归约到 `E`，`ST_E` 直接适用）——本章沿用原书写法，一是兑现热身引理，二是「ins 产非空树」这条事实本身在原书后续（lookup 方程）里还要再用。

### 41.5 本章小结

红黑树在第 39 章的 BST 骨架上加了一个 `color` 与一个智能构造子：**`balance` 是红黑树的心脏**——五种情形（红父原样 + LL/LR/RL/RR 四种旋转 + 兜底染黑）在回程修掉「红根带红孩子」，`insert = make_black ∘ ins` 把根拍回黑色。本章证明走的是**不变量保持**主线：`ForallT/BST` 从 39 章搬来（颜色维度全程被忽略），`balance_BST` 用 `repeat match goal` 把 `balance` 手工展开后的 41 个情形（实测数字）压成六条规则，剩下一色的「子树全键 <(>) 中间键」目标交给两条 `ForallT` 单调性引理接力；`insP` 打包「新结点穿过 balance」，`ins_BST` 以「intros 到归纳变量为止」的标准结构会师二者，`insert_BST` 用 `ins_not_E` + 情形分析收口。两点分层认识值得带走：其一，BST 证明对「怎么转」不敏感（实测删掉一个旋转分支照样全过），把五种情形钉死的是颜色不变量（局部红不共子 + 全局等黑高），那是原书 `RB/ins_RB` 一线的战场，也是「红黑树为什么平衡」的真正证明；其二，本章的 `balance_BST` 自动化（拆 ForallT、inversion 出界、constructor、destruct match、单调性收尾）与 41.3 的情形分析自动化是通用的情形管理工具，第 42 章将把这些已验证的结构（连同 BST）装进 `Module Type` 接口，让红黑树式的实现可以与关联表实现互换。

### 41.6 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到（做法：故意改错一行、`rocq compile` 看报错、改回来）。

1. **漏写 `Arguments E {V}.`**（41.1）：构造子的类型参数默认显式，`Definition empty_tree (V : Type) : tree V := E.` 实测报 `The term "E" has type "forall V : Type, tree V" while it is expected to have type "tree V"`——`E` 是个等着 `V` 的函数，不声明隐式就喂不进树的位置。
2. **`balance` 的 match 删分支，报错与否取决于删哪支**（41.2）：删掉兜底 `| _ => T Black t1 k vk t2` 实测报 `Error: Non exhaustive pattern-matching: no clause found for pattern E`；但删掉四个具名旋转分支之一（如 RR）**不报错**——兜底 `_` 会吞掉该情形，且本章全部 BST 证明照样编译通过。编译器只管穷尽，证明只管 BST；颜色不变量才区分五种情形。
3. **`ins_not_E` 忘了 `unfold balance`**（41.3）：`balance` 是 `Definition`，`simpl` 不展开，剩下的目标 `balance c (ins x vx t1) k v t2 <> E` 四条 match 模式全够不着；对它硬上 `discriminate` 实测报 `Error: No primitive equality found.`，硬上 `Qed.` 报 `Error:  (in proof ins_not_E): Attempt to save an incomplete proof (there are remaining open goals).`。
4. **`lia` 不认 β-红衣假设**（41.4）：`ForallT_greater` 的 `Hkv : (fun k' _ => k' > k) k' v` 不先 `simpl in Hkv`，实测报 `Error: Tactic failure:  Cannot find witness.`——谓词套用出来的假设必须先规约成裸的算术不等式再喂 `lia`。
5. **`ins_BST` 等键分支不把 `k = k'` 划等**（41.4）：删掉 `assert (Hkk : k = k') by lia. subst k'.` 后 `constructor; assumption` 实测报 `Error: No such assumption.`——constructor 造出的新界是关于插入键 `k` 的，手里的旧界却是关于树键 `k'` 的，不 subst 就永远差一个名字。
6. **`balance_BST` 的 `inversion H; subst` 少了 `clear H` 会无限循环**（41.4）：不 clear 的话 `repeat match goal` 里 `H : BST (T _ _ _ _ _)` 这条模式对同一条假设反复成立，inversion 永不失败、repeat 永不停止——实测无任何报错，编译器静默卡死（基线全文件 7.7 秒编完；去掉 `clear H` 后 25 秒仍无输出只能 kill）。自动化里凡是「消费假设」的规则，务必把假设清掉。
7. **`inv` 不是标准战术**（41.4）：照抄 VFA 原书写 `inv H` 实测报 `Error: The reference inv was not found in the current environment. Did you mean ins, inr or inl?`——`inv`/`bdestruct` 都是 VFA 的 SfLib 自定义，脱离原书环境要换回 `inversion H; subst; clear H` 与 `destruct … eqn:…`。
8. **`elements` 的输出不是插入序**（41.2）：把 `elements_example` 的期望值写成插入顺序 `[(3, 30); (1, 10); …]` 实测报 `Error: Unable to unify "[(3, 30); (1, 10); (2, 20); (5, 50); (4, 40)]" with "elements (insert 3 30 (insert 1 10 …))"`——elements 是中序遍历，输出永远按键升序。
9. **`match goal` 的模式要与 simpl/unfold 之后的形状对齐**（41.3/41.4）：`| |- (if ?b then _ else _) <> _ => destruct b` 匹配的是**语法上**的 if；scrutinee 还裹在未展开的定义里（如坑 3 的 `balance`）时整条规则沉默失配，`repeat` 提前收兵、残局留到 `Qed` 才爆。写情形自动化前先 `Show` 一眼目标的真实形状。

---
上一章：[40 · 抽取：把验证代码变成 OCaml](40-extract.md) ｜ 下一章：[42 · 抽象数据类型](42-adt.md) ｜ 返回：[README](../README.md)
