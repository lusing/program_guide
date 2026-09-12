/-
文件: 02_inductive_types/recursive_types.lean
描述: Lean 4 递归归纳类型（MyNat, 列表）
编译: lake build Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes
-/

namespace Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes

/-! # 自定义自然数 MyNat -/

-- 自然数的皮亚诺定义
-- 0 是自然数，如果 n 是自然数，那么 succ n 也是自然数
inductive MyNat where
  | zero : MyNat
  | succ (n : MyNat) : MyNat
deriving Repr, DecidableEq

open MyNat

-- 一些示例值
def my_zero : MyNat := zero
def my_one : MyNat := succ zero
def my_two : MyNat := succ (succ zero)
def my_three : MyNat := succ (succ (succ zero))

/-! # MyNat 上的递归函数 -/

-- 加法
def add (m n : MyNat) : MyNat :=
  match n with
  | zero => m
  | succ n' => succ (add m n')

-- 乘法
def mul (m n : MyNat) : MyNat :=
  match n with
  | zero => zero
  | succ n' => add m (mul m n')

-- 计算示例
def two_plus_three : MyNat := add my_two my_three
-- succ (succ (succ (succ (succ zero)))) 即 5

def two_times_three : MyNat := mul my_two my_three
-- succ (succ (succ (succ (succ (succ zero))))) 即 6

-- MyNat 转 Nat
def MyNat.toNat (n : MyNat) : Nat :=
  match n with
  | zero => 0
  | succ n' => 1 + n'.toNat

def three_to_nat : Nat := my_three.toNat   -- 3

-- Nat 转 MyNat
def MyNat.ofNat (n : Nat) : MyNat :=
  match n with
  | 0 => zero
  | n' + 1 => succ (ofNat n')

def five_of_nat : MyNat := MyNat.ofNat 5
-- succ^5 zero

/-! # 比较 MyNat -/

-- 小于等于
def leq (m n : MyNat) : Bool :=
  match m, n with
  | zero, _ => true
  | succ _, zero => false
  | succ m', succ n' => leq m' n'

def leq_example1 : Bool := leq my_one my_three    -- true
def leq_example2 : Bool := leq my_three my_one    -- false

-- 相等判断已经由 deriving DecidableEq 提供
def eq_example : Bool := my_two = my_two           -- true

/-! # 自定义列表类型 MyList -/

-- 列表是另一个常见的递归类型
-- 列表要么是空列表 nil，要么是一个元素加上另一个列表 cons
inductive MyList (α : Type) : Type where
  | nil : MyList α
  | cons (head : α) (tail : MyList α) : MyList α
deriving Repr

open MyList

-- 示例列表
def empty_list : MyList Nat := nil
def singleton : MyList Nat := cons 1 nil
def list123 : MyList Nat := cons 1 (cons 2 (cons 3 nil))

-- 使用 notation 让列表写法更简洁
-- (类似 Lean 标准库中的 [1, 2, 3])

/-! # MyList 上的递归函数 -/

-- 计算列表长度
def length {α : Type} (l : MyList α) : Nat :=
  match l with
  | nil => 0
  | cons _ rest => 1 + length rest

def len1 : Nat := length empty_list     -- 0
def len2 : Nat := length list123        -- 3

-- 列表拼接（append）
def append {α : Type} (l1 l2 : MyList α) : MyList α :=
  match l1 with
  | nil => l2
  | cons x rest => cons x (append rest l2)

def appended : MyList Nat := append (cons 1 nil) (cons 2 (cons 3 nil))
-- [1, 2, 3]

-- map：对列表中的每个元素应用函数
def map {α β : Type} (f : α → β) (l : MyList α) : MyList β :=
  match l with
  | nil => nil
  | cons x rest => cons (f x) (map f rest)

def doubled : MyList Nat := map (fun x => x * 2) list123
-- [2, 4, 6]

-- filter：保留满足条件的元素
def filter {α : Type} (p : α → Bool) (l : MyList α) : MyList α :=
  match l with
  | nil => nil
  | cons x rest =>
    if p x then cons x (filter p rest)
    else filter p rest

def evens : MyList Nat := filter (fun x => x % 2 = 0) list123
-- [2]

-- foldr：右折叠
def foldr {α β : Type} (f : α → β → β) (init : β) (l : MyList α) : β :=
  match l with
  | nil => init
  | cons x rest => f x (foldr f init rest)

def sum_list : Nat := foldr (· + ·) 0 list123    -- 6
def product_list : Nat := foldr (· * ·) 1 list123  -- 6

/-! # 标准库的 List -/

-- Lean 标准库已经定义了 List α
-- 使用 [] 表示空列表，:: 表示 cons
def std_list : List Nat := [1, 2, 3, 4, 5]
def std_empty : List Nat := []

-- 标准库列表的常用操作
def std_length : Nat := std_list.length         -- 5
def std_head? : Option Nat := std_list.head?    -- some 1
def std_tail : List Nat := std_list.tail!       -- [2, 3, 4, 5]

-- 列表连接
def std_append : List Nat := [1, 2] ++ [3, 4]   -- [1, 2, 3, 4]

-- map
def std_map : List Nat := List.map (· * 2) [1, 2, 3]  -- [2, 4, 6]

-- filter
def std_filter : List Nat := List.filter (· % 2 = 0) [1, 2, 3, 4]
-- [2, 4]

-- foldl / foldr
def std_sum : Nat := List.foldl (· + ·) 0 [1, 2, 3]   -- 6
def std_foldr : Nat := List.foldr (· + ·) 0 [1, 2, 3] -- 6

/-! # 二叉树类型 -/

-- 二叉树也是一个常见的递归类型
inductive BinTree (α : Type) : Type where
  | leaf : BinTree α
  | node (value : α) (left : BinTree α) (right : BinTree α) : BinTree α
deriving Repr

open BinTree

-- 示例树
--     3
--    / \
--   1   5
--    \
--     2
def example_tree : BinTree Nat :=
  node 3
    (node 1
      leaf
      (node 2 leaf leaf))
    (node 5 leaf leaf)

-- 树的大小（节点数）
def size {α : Type} (t : BinTree α) : Nat :=
  match t with
  | leaf => 0
  | node _ l r => 1 + size l + size r

def tree_size : Nat := size example_tree    -- 4

-- 树的高度
def height {α : Type} (t : BinTree α) : Nat :=
  match t with
  | leaf => 0
  | node _ l r => 1 + max (height l) (height r)

def tree_height : Nat := height example_tree   -- 3

-- 树的映射
def treeMap {α β : Type} (f : α → β) (t : BinTree α) : BinTree β :=
  match t with
  | leaf => leaf
  | node v l r => node (f v) (treeMap f l) (treeMap f r)

def tree_doubled : BinTree Nat := treeMap (· * 2) example_tree

-- 中序遍历
def inorder {α : Type} (t : BinTree α) : List α :=
  match t with
  | leaf => []
  | node v l r => inorder l ++ [v] ++ inorder r

def inorder_example : List Nat := inorder example_tree
-- [1, 2, 3, 5]

/-! # 表达式类型 -/

-- 算术表达式的递归类型
inductive AExpr where
  | num (n : Nat) : AExpr
  | add (e1 e2 : AExpr) : AExpr
  | mul (e1 e2 : AExpr) : AExpr
deriving Repr

open AExpr

-- 表达式：(3 + 4) * 5
def expr1 : AExpr := mul (add (num 3) (num 4)) (num 5)

-- 求值函数
def eval (e : AExpr) : Nat :=
  match e with
  | num n => n
  | add e1 e2 => eval e1 + eval e2
  | mul e1 e2 => eval e1 * eval e2

def eval1 : Nat := eval expr1    -- 35

-- 表达式的大小
def exprSize (e : AExpr) : Nat :=
  match e with
  | num _ => 1
  | add e1 e2 => 1 + exprSize e1 + exprSize e2
  | mul e1 e2 => 1 + exprSize e1 + exprSize e2

def size1 : Nat := exprSize expr1    -- 5

end Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes
