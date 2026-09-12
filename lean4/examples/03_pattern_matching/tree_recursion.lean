/-
文件: 03_pattern_matching/tree_recursion.lean
描述: Lean 4 二叉树结构递归
编译: lake build Lean4Tutorial.Examples.PatternMatching.TreeRecursion
-/

namespace Lean4Tutorial.Examples.PatternMatching.TreeRecursion

/-! # 二叉树定义 -/

-- 二叉树的归纳类型定义
inductive BinTree (α : Type) : Type where
  | leaf : BinTree α                              -- 空叶子节点
  | node (value : α) (left : BinTree α) (right : BinTree α) : BinTree α
    -- 内部节点：包含一个值和左右子树
deriving Repr

open BinTree

/-! # 示例树 -/

--     3
--    / \
--   1   5
--    \   \
--     2   7
def example_tree : BinTree Nat :=
  node 3
    (node 1
      leaf
      (node 2 leaf leaf))
    (node 5
      leaf
      (node 7 leaf leaf))

-- 单节点树
def single_node : BinTree Nat := node 42 leaf leaf

-- 空树
def empty_tree : BinTree Nat := leaf

-- 左斜树
def left_skewed : BinTree Nat :=
  node 1
    (node 2
      (node 3 leaf leaf)
      leaf)
    leaf

/-! # 树的基本属性 -/

-- 树的大小（节点个数）
def size {α : Type} : BinTree α → Nat
  | leaf => 0
  | node _ l r => 1 + size l + size r

def size_example : Nat := size example_tree    -- 5
def size_leaf : Nat := size leaf               -- 0
def size_single : Nat := size single_node      -- 1

-- 树的高度（从根到最深叶子的路径上的节点数）
def height {α : Type} : BinTree α → Nat
  | leaf => 0
  | node _ l r => 1 + max (height l) (height r)

def height_example : Nat := height example_tree    -- 3
def height_leaf : Nat := height leaf               -- 0
def height_single : Nat := height single_node      -- 1

-- 判断是否为叶子节点
def isLeaf {α : Type} : BinTree α → Bool
  | leaf => true
  | node _ _ _ => false

def leaf_true : Bool := isLeaf leaf                 -- true
def leaf_false : Bool := isLeaf (node 1 leaf leaf)  -- false

/-! # 树的遍历 -/

-- 前序遍历：根 -> 左 -> 右
def preorder {α : Type} : BinTree α → List α
  | leaf => []
  | node v l r => v :: preorder l ++ preorder r

def preorder_example : List Nat := preorder example_tree
-- [3, 1, 2, 5, 7]

-- 中序遍历：左 -> 根 -> 右
def inorder {α : Type} : BinTree α → List α
  | leaf => []
  | node v l r => inorder l ++ [v] ++ inorder r

def inorder_example : List Nat := inorder example_tree
-- [1, 2, 3, 5, 7]

-- 后序遍历：左 -> 右 -> 根
def postorder {α : Type} : BinTree α → List α
  | leaf => []
  | node v l r => postorder l ++ postorder r ++ [v]

def postorder_example : List Nat := postorder example_tree
-- [2, 1, 7, 5, 3]

/-! # 树的映射 -/

-- 对树中每个节点的值应用函数
def treeMap {α β : Type} (f : α → β) : BinTree α → BinTree β
  | leaf => leaf
  | node v l r => node (f v) (treeMap f l) (treeMap f r)

def doubled_tree : BinTree Nat := treeMap (· * 2) example_tree
-- 所有节点值翻倍

def string_tree : BinTree String := treeMap toString example_tree
-- 所有节点值转为字符串

/-! # 树的折叠 -/

-- 树的右折叠（类似列表的 foldr）
def treeFold {α β : Type} (f : α → β → β → β) (init : β) : BinTree α → β
  | leaf => init
  | node v l r => f v (treeFold f init l) (treeFold f init r)

-- 求所有节点的和
def treeSum : BinTree Nat → Nat :=
  treeFold (fun v l r => v + l + r) 0

def sum_example : Nat := treeSum example_tree    -- 1 + 2 + 3 + 5 + 7 = 18

-- 求所有节点的乘积
def treeProduct : BinTree Nat → Nat :=
  treeFold (fun v l r => v * l * r) 1

def product_example : Nat := treeProduct example_tree    -- 1 * 2 * 3 * 5 * 7 = 210

-- 查找最大值
def treeMax? : BinTree Nat → Option Nat
  | leaf => none
  | node v l r =>
    match treeMax? l, treeMax? r with
    | none, none => some v
    | some lm, none => some (max v lm)
    | none, some rm => some (max v rm)
    | some lm, some rm => some (max v (max lm rm))

def max_example : Option Nat := treeMax? example_tree    -- some 7
def max_leaf : Option Nat := treeMax? leaf               -- none

/-! # 二叉搜索树（BST）-/

-- 向二叉搜索树中插入元素
def bstInsert : BinTree Nat → Nat → BinTree Nat
  | leaf, x => node x leaf leaf
  | node v l r, x =>
    if x < v then node v (bstInsert l x) r
    else if x > v then node v l (bstInsert r x)
    else node v l r  -- 相等则不插入

-- 从列表构建 BST
def bstFromList (l : List Nat) : BinTree Nat :=
  l.foldl bstInsert leaf

def bst_example : BinTree Nat := bstFromList [3, 1, 5, 2, 7]
-- 构建出的树与 example_tree 结构相同

-- 在 BST 中查找元素
def bstSearch : BinTree Nat → Nat → Bool
  | leaf, _ => false
  | node v l r, x =>
    if x = v then true
    else if x < v then bstSearch l x
    else bstSearch r x

def search_5 : Bool := bstSearch bst_example 5     -- true
def search_4 : Bool := bstSearch bst_example 4     -- false
def search_7 : Bool := bstSearch bst_example 7     -- true

-- BST 的最小值（最左节点）
def bstMin : BinTree Nat → Option Nat
  | leaf => none
  | node v leaf _ => some v
  | node _ l _ => bstMin l

def min_example : Option Nat := bstMin bst_example    -- some 1

-- BST 的最大值（最右节点）
def bstMax : BinTree Nat → Option Nat
  | leaf => none
  | node v _ leaf => some v
  | node _ _ r => bstMax r

def max_bst : Option Nat := bstMax bst_example    -- some 7

/-! # 判断是否为二叉搜索树 -/

-- 检查一棵树是否是 BST
-- 要求：对于每个节点，左子树所有节点 < 当前节点 < 右子树所有节点
def isBST (t : BinTree Nat) : Bool :=
  check t none none
where
  check : BinTree Nat → Option Nat → Option Nat → Bool
    | leaf, _, _ => true
    | node v l r, lower, upper =>
      (match lower with
        | some lo => lo < v
        | none => true) &&
      (match upper with
        | some hi => v < hi
        | none => true) &&
      check l lower (some v) &&
      check r (some v) upper

def bst_true : Bool := isBST bst_example          -- true
def bst_false : Bool := isBST (node 3 (node 5 leaf leaf) leaf)  -- false

/-! # 树的相等性 -/

-- 两棵树相等当且仅当结构相同且对应节点的值相同
-- deriving DecidableEq 可以自动生成

-- 手动定义树的相等性判断
def treeEq {α : Type} [DecidableEq α] : BinTree α → BinTree α → Bool
  | leaf, leaf => true
  | node v1 l1 r1, node v2 l2 r2 =>
    v1 = v2 && treeEq l1 l2 && treeEq r1 r2
  | _, _ => false

/-! # 树的镜像 -/

-- 生成树的镜像（左右翻转）
def mirror {α : Type} : BinTree α → BinTree α
  | leaf => leaf
  | node v l r => node v (mirror r) (mirror l)

def mirrored : BinTree Nat := mirror example_tree
--     3
--    / \
--   5   1
--  /   /
-- 7   2

-- 镜像的镜像等于原树
theorem mirror_mirror {α : Type} (t : BinTree α) :
  mirror (mirror t) = t := by
  induction t with
  | leaf => rfl
  | node v l r ih_l ih_r =>
    simp [mirror, ih_l, ih_r]
    <;> aesop

/-! # 判断是否为满二叉树 -/

-- 满二叉树：每个节点要么是叶子，要么有两个子节点
def isFull {α : Type} : BinTree α → Bool
  | leaf => true
  | node _ leaf leaf => true
  | node _ leaf (node _ _ _) => false
  | node _ (node _ _ _) leaf => false
  | node _ l r => isFull l && isFull r

-- 更简洁的写法
def isFull' {α : Type} : BinTree α → Bool
  | leaf => true
  | node _ l r =>
    (isLeaf l && isLeaf r) || (¬isLeaf l && ¬isLeaf r && isFull' l && isFull' r)

/-! # 判断是否为平衡二叉树 -/

-- 平衡二叉树：左右子树高度差不超过 1，且左右子树都是平衡的
def isBalanced {α : Type} : BinTree α → Bool
  | leaf => true
  | node _ l r =>
    isBalanced l && isBalanced r &&
    (height l - height r ≤ 1 && height r - height l ≤ 1)

-- 注意：上面的定义使用了自然数减法，需要小心处理
-- 更精确的定义使用 Int

/-! # 树的层数列表 -/

-- 获取树的第 n 层的所有节点
def level {α : Type} : Nat → BinTree α → List α
  | _, leaf => []
  | 0, node v _ _ => [v]
  | n + 1, node _ l r => level n l ++ level n r

def level_0 : List Nat := level 0 example_tree    -- [3]
def level_1 : List Nat := level 1 example_tree    -- [1, 5]
def level_2 : List Nat := level 2 example_tree    -- [2, 7]
def level_3 : List Nat := level 3 example_tree    -- []

-- 层序遍历（广度优先）
def levelOrder {α : Type} (t : BinTree α) : List α :=
  go 0
where
  go (n : Nat) : List α :=
    let current := level n t
    if current.isEmpty then []
    else current ++ go (n + 1)

def level_order : List Nat := levelOrder example_tree
-- [3, 1, 5, 2, 7]

/-! # 树的归纳证明示例 -/

-- 树的镜像的大小等于原树的大小
theorem size_mirror {α : Type} (t : BinTree α) :
  size (mirror t) = size t := by
  induction t with
  | leaf => rfl
  | node v l r ih_l ih_r =>
    simp [size, mirror, ih_l, ih_r]
    <;> ring

-- 前序遍历的镜像等于后序遍历的反转（近似）
-- 实际上：preorder (mirror t) = reverse (postorder t)
-- 后序遍历的镜像等于前序遍历的反转
theorem mirror_inorder {α : Type} (t : BinTree α) :
  inorder (mirror t) = (inorder t).reverse := by
  induction t with
  | leaf => rfl
  | node v l r ih_l ih_r =>
    simp [inorder, mirror, ih_l, ih_r, List.reverse_append]
    <;> ring

end Lean4Tutorial.Examples.PatternMatching.TreeRecursion
