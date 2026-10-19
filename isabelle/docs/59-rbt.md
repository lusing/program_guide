# 59 · 红黑树族：Tree、RBT_Impl、RBT、RBT_Set 与 RBT_Mapping

对应示例：`../examples/lib/T59_rbt.thy`（IsaTutLib 会话，依赖
`HOL-Library.Tree`、`HOL-Library.RBT_Set`、`HOL-Library.RBT_Mapping`）

本章把 Isabelle 库里整条「树 → 红黑树 → 集合/字典实现」的流水线
一次走完。五个理论各司其职：

- `Tree`：不带任何不变量的裸二叉树，所有树结构的公共底座；
- `RBT_Impl`：红黑树的**实现层**，原始构造子 + 不变量 +
  Okasaki 式插入/删除，作者明说「应用请用 RBT」；
- `RBT`：用 typedef 把满足不变量的树收进抽象类型，语义挂在
  偏函数 `lookup` 上；
- `RBT_Set`：给普通 `'a set` 安装红黑树代码实现；
- `RBT_Mapping`：第 57 章 Mapping 抽象字典的红黑树后端。

## 59.1 裸二叉树：Tree

`Tree` 的两个构造子是 `⟨⟩`（空叶）与 `⟨l, x, r⟩`（左子树、值、
右子树）——尖括号是 mixfix 语法，不是普通括号。它不带任何序或
平衡的假设，只提供递归度量与遍历：

```isabelle
definition t3 :: "nat tree" where
  "t3 = ⟨⟨⟨⟩, 1, ⟨⟩⟩, 2, ⟨⟨⟩, 3, ⟨⟩⟩⟩"

value "size t3"        (* 节点数 3 *)
value "size1 t3"       (* 叶子数 4 *)
value "height t3"      (* 高度 2 *)
value "inorder t3"     (* [1, 2, 3] *)
value "preorder t3"    (* [2, 1, 3] *)
value "postorder t3"   (* [1, 3, 2] *)
```

`size` 数内部节点、`size1` 数叶子，两者恒差 1（`size1_size`）。
三种遍历的元素集都是 `set_tree`（`set_inorder` 等），镜像
`mirror` 与中序遍历互为反转：

```isabelle
value "mirror t3"
value "inorder (mirror t3)"

lemma "inorder (mirror t3) = rev (inorder t3)"
  by (simp add: inorder_mirror)
```

求值输出：

```text
"⟨⟨⟨⟩, 3, ⟨⟩⟩, 2, ⟨⟨⟩, 1, ⟨⟩⟩⟩" :: "nat tree"
"[3, 2, 1]" :: "nat list"
```

谓词 `bst` 判定二叉搜索树性质（左子树全小于根、右子树全大于根，
递归定义），它与「中序遍历有序」互为表里
（`bst_iff_sorted_wrt_less`）；`complete` 判定「每层都满」：

```isabelle
value "bst t3"                                        (* True *)
value "bst ⟨⟨⟩, 2::nat, ⟨⟨⟩, 1, ⟨⟩⟩⟩"                 (* False *)
value "complete t3"                                   (* True *)
```

第二行是反例：根 2 的右子树里放了 1。完备树有精确关系
`size_if_complete: complete t ⟹ size t = 2 ^ height t - 1`；
一般树只有上界 `size1_height: size1 t ≤ 2 ^ height t`。这两条
说明一件事：**树越不平衡，同样节点数下高度越大**，而 BST 查找
的步数就是高度——这正是红黑树要维护的东西。

## 59.2 RBT_Impl：颜色、黑高与两条不变量

实现层的原始类型是

```isabelle
datatype color = R | B
datatype ('a, 'b) rbt = Empty | Branch color "('a, 'b) rbt" 'a 'b "('a, 'b) rbt"
```

红黑性质拆成四个谓词，合起来叫 `is_rbt`：

- `inv1`：没有相邻的红节点（红节点的两个子节点必须黑）；
- `inv2`：任意节点左右子树的**黑高**相等——黑高 `bheight`
  只数黑节点；
- 根必须为黑（`color_of t = B`，空树算黑）；
- `rbt_sorted`：搜索树性质（左 < 根 < 右，递归）。

用求值直接看两种违规（都是 `False`）：

```isabelle
value "RBT_Impl.inv1 (RBT_Impl.Branch RBT_Impl.R RBT_Impl.Empty (1::nat) ()
  (RBT_Impl.Branch RBT_Impl.R RBT_Impl.Empty 2 () RBT_Impl.Empty))"   (* 红带红孩子 *)
value "RBT_Impl.inv2 (RBT_Impl.Branch RBT_Impl.B
  (RBT_Impl.Branch RBT_Impl.B RBT_Impl.Empty (1::nat) () RBT_Impl.Empty)
  2 () RBT_Impl.Empty)"                                                (* 黑高 1 vs 0 *)
```

这两条不变量的经典推论：从根到叶的任何路径上红节点不超过黑节点，
且各路径黑节点数相同，所以最长路径至多是最短的两倍，高度是
O(log n)。注意本理论只证明每条操作**保持**不变量
（`rbt_insert_is_rbt` 等一组定理），并没有给出高度对数界的形式化
——那在 HOL-Data_Structures 会话里（本教程后续批次）。

## 59.3 Okasaki 插入：balance 与 paint

插入按 Okasaki 的函数式算法实现（源码注释自承）。核心是
`balance`：五条带红-红冲突的模式各做一次「旋转+换色」，其余
情况原样涂黑。看一次真实求值——左-左冲突（红节点的左孩子还是
红）：

```isabelle
value "RBT_Impl.balance
  (RBT_Impl.Branch RBT_Impl.R
    (RBT_Impl.Branch RBT_Impl.R RBT_Impl.Empty (1::nat) () RBT_Impl.Empty)
    2 () RBT_Impl.Empty)
  3 () RBT_Impl.Empty"
```

输出：

```text
"Branch color.R (Branch color.B rbt.Empty 1 () rbt.Empty) 2 ()
  (Branch color.B rbt.Empty 3 () rbt.Empty)"
```

红-红冲突被消解为「根红、两子皆黑」的局部完美形状。递归插入
`rbt_ins` 在黑节点处调 `balance`、在红节点处直接挂（红节点的
父亲必黑，冲突留给上层处理）；最后 `rbt_insert` 用 `paint` 把
根涂黑收尾——涂黑只会增加所有路径的黑高，不破坏任何不变量，
这就是「根必黑」条款容易维护的原因。删除复杂得多
（`rbt_baldL`/`rbt_baldR` 一族修补函数），但思想相同：局部
修复、向上传递。这一层的内容你只要**理解**，不要在自己的证明
里打开它（坑 10）。

## 59.4 RBT：typedef 抽象类型与 lookup 代数

`RBT` 用 typedef 把满足 `is_rbt` 的树收进抽象类型
`('a::linorder, 'b) rbt`——又是第 28/29 章那条
typedef + Lifting 流水线。从此**类型本身担保不变量**，用户
接触不到能破坏平衡的原始构造子。所有操作的语义都挂在偏函数
`RBT.lookup`（类型 `('a,'b) rbt ⇒ 'a ⇀ 'b`）上：

```isabelle
definition t4 :: "(nat, string) rbt" where
  "t4 = RBT.insert 1 ''a'' (RBT.insert 2 ''b'' (RBT.insert 3 ''c'' RBT.empty))"

value "RBT.lookup t4 2"                 (* "Some ''b''" *)
value "RBT.lookup t4 9"                 (* "None" *)
value "RBT.impl_of t4"
value "RBT_Impl.is_rbt (RBT.impl_of t4)"  (* True *)
value "RBT_Impl.bheight (RBT.impl_of t4)" (* 2 *)
```

第三行能看到三次插入后生成的具体形状——一棵全黑的三节点树：

```text
"Branch color.B (Branch color.B rbt.Empty 1 ''a'' rbt.Empty) 2 ''b''
  (Branch color.B rbt.Empty 3 ''c'' rbt.Empty)"
```

语义等式一族全是 simp 规则，把抽象操作逐键复述成偏函数代数：

```text
lookup RBT.empty             = Map.empty
lookup (insert k v t)        = (lookup t)(k ↦ v)
lookup (delete k t)          = (lookup t)(k := None)
lookup (bulkload xs)         = map_of xs
map_of (entries t)           = lookup t
lookup (map_entry k f t)     = (lookup t)(k := map_option f (lookup t k))
lookup (map f t) k           = map_option (f k) (lookup t k)
```

有了它们，具体表上的查找命题一行 simp：

```isabelle
lemma "RBT.lookup (RBT.insert 1 ''z'' t4) 1 = Some ''z''"
  by (simp add: t4_def)

lemma "RBT.lookup (RBT.delete 2 t4) 2 = None"
  by (simp add: t4_def)
```

批量构造 `bulkload` 接收无序表（内部排序后线性建树），
`keys`/`entries` 恒返回**按键升序**且无重复的列表——这是
`rbt_sorted` 不变量的直接红利，`sorted_keys`/`distinct_keys`
是 iff 规则：

```isabelle
value "RBT.keys (RBT.bulkload [(3::nat, ''c''), (1, ''a''), (2, ''b'')])"
  (* "[1, 2, 3]" *)
value "RBT.keys t4"      (* "[1, 2, 3]" *)
value "RBT.entries t4"   (* "[(1, ''a''), (2, ''b''), (3, ''c'')]" *)
```

「键表恒有序」是红黑树后端区别于第 57 章 AList 后端的卖点之一
（AList 保留插入序、可以有重复键的歧义）。

## 59.5 map、map_entry、fold、union、combine

改值类：`map_entry` 只改存在键，`map` 全表改值（键与结构不动）：

```isabelle
value "RBT.lookup (RBT.map_entry 1 (%s. s @ ''!'') t4) 1"   (* Some ''a!'' *)
value "RBT.entries (RBT.map (%k s. length s) t4)"           (* [(1,1),(2,1),(3,1)] *)
```

折叠：`fold` 按键序遍历所有键值对；`foldi` 多带一个继续条件，
可提前退出（下面第二个例子累加键，累加器到达 3 就停）：

```isabelle
value "RBT.fold (%k v acc. acc + k) t4 0"                    (* 6 *)
value "RBT.foldi (%acc. acc < 3) (%k v acc. acc + k) t4 0"   (* 3 *)
```

两表操作：`union` 是**右表优先**的并（语义
`lookup (union s t) = lookup s ++ lookup t`，与 `map_add`、
fmap 的 `++⇘f` 同向）；`combine` 用给定二元函数合并冲突键，
`combine_with_key` 的合并函数还能看键：

```isabelle
value "RBT.lookup (RBT.union t4 (RBT.insert (2::nat) ''z'' RBT.empty)) 2"  (* Some ''z'' *)
value "RBT.lookup (RBT.union (RBT.insert (2::nat) ''z'' RBT.empty) t4) 2"  (* Some ''b'' *)
value "RBT.lookup (RBT.combine (%v w. v + w)
  (RBT.insert (1::nat) (2::nat) RBT.empty)
  (RBT.insert 1 3 (RBT.insert 2 4 RBT.empty))) 1"                          (* Some 5 *)
```

前两行对照：交换两表，冲突键 2 上的结果互换——右偏一目了然。

## 59.6 RBT_Set：集合的红黑树实现

`RBT_Set` 走另一条路：不给集合立新类型，而是给**普通**
`'a set` 安装两个代码构造子 `code_datatype Set Coset`——
`RBT_Set.Set` 把一棵值域为 `unit` 的红黑树解释成它的键集，
`RBT_Set.Coset` 解释成补集。于是 Main 里一大批集合运算直接获得
红黑树实现：属于、并交差、过滤、`card`、`sum`、`Pow`、
`Min`/`Max`、`Inf`/`Sup`、`sorted_list_of_set`……各有 `[code]`
等式。

```isabelle
definition s1 :: "nat set" where
  "s1 = RBT_Set.Set (RBT.insert 1 () (RBT.insert 3 () (RBT.insert 2 () RBT.empty)))"

value "2 ∈ s1"                  (* True *)
value "4 ∈ s1"                  (* False *)
value "card s1"                 (* 3 *)
value "sorted_list_of_set s1"   (* [1, 2, 3] *)
```

`sorted_list_of_set` 的代码等式就是 `RBT.keys`——键表本来有序，
取有序列表免费（对比第 58 章 fset 要真的排序）。`s1 ∪ {4}`
也能求值，结果打印成 `RBT_Set.Set (RBT (Branch …))` 的内部
形状（新生成的节点 4 是红色——插入算法的真实痕迹）：

```text
"RBT_Set.Set
  (RBT (Branch color.B (Branch color.B rbt.Empty 1 () rbt.Empty) 2 ()
         (Branch color.B rbt.Empty 3 ()
           (Branch color.R rbt.Empty 4 () rbt.Empty))))"
```

补集表示让「有限集的全集」也可执行：

```isabelle
value "(1::nat) ∈ RBT_Set.Coset (RBT.insert 2 () RBT.empty)"   (* True *)
value "(2::nat) ∈ RBT_Set.Coset (RBT.insert 2 () RBT.empty)"   (* False *)
```

注意数字必须标注 `::nat`：不标时类型停留在多态数字，求值报
「free dictionaries」（坑 2 的姊妹坑）。另有一个全局副作用：
源码开头官方警告——导入本理论后，其它以**列表**实现集合的
代码等式被顶掉，整个项目的集合代码生成只剩红黑树这一路。

## 59.7 RBT_Mapping：Mapping 的对数后端

回到第 57 章的抽象字典接口。`RBT_Mapping` 用红黑树安装构造子
`Mapping`（键须 `linorder`），`Mapping.lookup`/`update`/`delete`
一族接口一个字不改，实现从线性表换成平衡树：

```isabelle
definition m4 :: "(nat, string) mapping" where
  "m4 = Mapping (RBT.insert 1 ''a'' (RBT.insert 2 ''b'' RBT.empty))"

value "Mapping.lookup m4 2"                          (* Some ''b'' *)
value "Mapping.lookup (Mapping.update 3 ''c'' m4) 3" (* Some ''c'' *)
value "Mapping.size m4"                              (* 2 *)
```

红黑树后端独有的红利是有序视图：`Mapping.ordered_keys` 与
`Mapping.ordered_entries` 的代码等式直接是 `RBT.keys`/
`RBT.entries`，升序输出、免排序：

```isabelle
value "Mapping.ordered_keys (Mapping.update 3 ''c'' m4)"     (* [1, 2, 3] *)
value "Mapping.ordered_entries (Mapping.update 3 ''c'' m4)"  (* [(1,''a''),(2,''b''),(3,''c'')] *)

lemma "Mapping.lookup (Mapping.update (1::nat) ''z'' m4) 1 = Some ''z''"
  by (simp add: m4_def)
```

选型对照（呼应 57.7）：写**数学**用 fmap（等式理论最丰富，
能出现在项里被 transfer 搬运）；写**可执行库接口**用 Mapping，
小规模乱序键选 AList_Mapping，大规模有序键选 RBT_Mapping。
另外 `RBT` 末尾注册了 `quickcheck_generator`，quickcheck 能
直接生成满足不变量的随机红黑树，做性质抽查零成本。

## 59.8 坑位清单（实测）

1. **全称限定。** `RBT` 结尾 `hide_const (open)` 隐藏了一批
   未限定名（lookup/insert/delete/keys/entries/…），引用必须
   写 `RBT.lookup` 等全称；实现层构造子是大写
   `RBT_Impl.Branch`/`RBT_Impl.Empty`，颜色是
   `RBT_Impl.R`/`RBT_Impl.B`。
2. **键须 `linorder`。** typedef 自带 `('a::linorder, 'b)`
   约束，`order` 不够；求值时数字键要标注 `::nat` 之类，
   否则多态数字报「free dictionaries」。
3. **尖括号是语法。** `⟨l, x, r⟩` 是 Tree 的 mixfix（源码层
   写作反斜杠命令 langle/rangle），空叶是 `⟨⟩`。
4. **`union` 右表优先**，与 `map_add`、fmap 的 `++⇘f` 同向；
   需要左偏就换 `combine` 显式给合并函数。
5. **一个理论一个 Mapping 后端。** `RBT_Mapping` 与
   `AList_Mapping` 都用 `code_datatype` 安装构造子
   `Mapping`，同导入互相覆盖（本教程因此放在 57/59 两个
   理论）。
6. **`RBT_Set` 是全局手术。** 导入后列表实现集合的 code 等式
   被顶掉（源码官方警告），整个项目的集合代码生成改走红
   黑树；跨项目复用时先想清楚。
7. **`RBT_Set.Set` 的值域必须是 `unit`**——它把
   `('a, unit) rbt` 当集合用；要键值对回 RBT/Mapping。
8. **`keys`/`entries` 恒有序无重复**（`sorted_keys`、
   `distinct_keys` 是 iff 规则），证明直接用，别重新归纳。
9. **O(log n) 来自不变量，不是本库的一条高度界定理。**
   RBT_Impl 只证不变量保持；复杂度界的完整形式化在
   HOL-Data_Structures（后续批次）。
10. **证明停留在 lookup 代数层。** 一律用 `lookup_insert` 一族
    simp 规则；不要 unfold `impl_of` 去跟 `balance` 的五个
    模式搏斗——那是库作者已经付过的代价。

## 59.9 与其他章的接口

- 第 28/29 章 typedef 与 Lifting：RBT 是又一个完整样本，
  且结尾的 `lifting_update`/`lifting_forget`/`hide_const`
  三件套展示了「封装完成、收回工具」的标准动作。
- 第 57 章 fmap/Mapping：Mapping 接口的两个后端分别在本章与
  57 章落地；fmap 的 `++⇘f` 与 `RBT.union` 同向。
- 第 58 章 FSet：fset 是「数学优先」的有限集，RBT_Set 是
  「代码优先」的集合实现；两者的有序列表接口
  （`sorted_list_of_fset`/`sorted_list_of_set`）在此交汇。
- 第 23 章偏序：`linorder` 约束贯穿全章；`Min`/`Max`/
  `Inf`/`Sup` 的红黑树实现是格运算的代码化。
