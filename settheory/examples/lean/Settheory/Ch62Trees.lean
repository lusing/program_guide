import Mathlib.Order.Basic
import Mathlib.Tactic

/-!
# 第 62 章 · 树：有根树、二叉树与生成树（Makinson Ch7）

自建二叉树与 BST 搜索/插入；n−1 条边的归纳证明；
树高与分支计数。
-/

namespace Settheory.Ch62

-- ---------- 二叉树：新根法递归的原生形态 ----------

inductive BTree where
  | leaf : BTree
  | node : BTree → Nat → BTree → BTree

-- 搜索：三分支递归的直译
def search (t : BTree) (x : Nat) : Bool :=
  match t with
  | .leaf => false
  | .node l a r =>
      if x = a then true
      else if x < a then search l x
      else search r x

-- 插入：搜索失败处挂新叶
def insert (t : BTree) (x : Nat) : BTree :=
  match t with
  | .leaf => .node .leaf x .leaf
  | .node l a r =>
      if x < a then .node (insert l x) a r
      else if x > a then .node l a (insert r x)
      else t

-- 书中 BST (d)：5,3,7,2,4,6,10,9 构造
def tD : BTree :=
  .node (.node (.node .leaf 2 .leaf) 3 (.node .leaf 4 .leaf)) 5
        (.node (.node .leaf 6 .leaf) 7
               (.node (.node .leaf 9 .leaf) 10 .leaf))

example : search tD 6 = true := by native_decide
example : search tD 8 = false := by native_decide
example : search tD 9 = true := by native_decide

-- 插入 8 后可搜到
example : search (insert tD 8) 8 = true := by native_decide

-- ---------- n − 1 条边（结构归纳） ----------

def nodes : BTree → Nat
  | .leaf => 0
  | .node l _ r => 1 + nodes l + nodes r

def edges : BTree → Nat
  | .leaf => 0
  | .node l _ r =>
      edges l + edges r
      + (if nodes l > 0 then 1 else 0) + (if nodes r > 0 then 1 else 0)

-- 通用形态：edges t = nodes t −（非空则 1 否则 0）
theorem edges_eq_gen (t : BTree) :
    edges t = nodes t - (if nodes t > 0 then 1 else 0) := by
  induction t with
  | leaf => simp [edges, nodes]
  | node l a r ihl ihr =>
      simp only [nodes, edges]
      by_cases hl : nodes l > 0 <;> by_cases hr : nodes r > 0 <;>
        simp_all <;> omega

-- 推论：非空树的边数 = 节点数 − 1（书 Exercise 7.2.2 的机器版）
theorem edges_eq (t : BTree) (h : nodes t > 0) : edges t = nodes t - 1 := by
  rw [edges_eq_gen]
  split <;> omega

-- ---------- 树高与叶计数 ----------

def height : BTree → Nat
  | .leaf => 0
  | .node l _ r => 1 + max (height l) (height r)

def leaves : BTree → Nat
  | .leaf => 1
  | .node .leaf _ .leaf => 1
  | .node l _ r => leaves l + leaves r

-- 书中第一棵树的骨架（a 的孩子 b,c；……）：分支数 = 叶数
def fig71 : BTree :=
  .node
    (.node .leaf 1                      -- b（单链 d 略）
      (.node (.node .leaf 1 .leaf) 1    -- d
             (.node .leaf 1 (.node .leaf 1 .leaf))))  -- k(n)
    0
    (.node (.node .leaf 1 .leaf) 1      -- c 的孩子 e,f,g 略为子树
           (.node .leaf 1 (.node .leaf 1 .leaf)))     -- h(l)

example : height tD = 4 := by native_decide
example : leaves tD = 5 := by native_decide

end Settheory.Ch62
