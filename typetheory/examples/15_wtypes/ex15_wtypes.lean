/- ============================================================
   15 W 类型与良序（Nordström ch.15–16）—— Lean 侧
   W α β：一般归纳树。一个构造子包打天下：
     sup : (a : α) → (β a → W α β) → W α β
   「标签 a + 按 a 定型的孩子们」。ℕ、二叉树、任意归纳定义
   都是 W 的特例——本章实测两个编码
   ============================================================ -/

inductive Wt (α : Type) (β : α → Type) : Type where
  | sup : (a : α) → (β a → Wt α β) → Wt α β

/- ---------- 编码一：叶/单孩子/双孩子 三种标签的树 ---------- -/

inductive Tag where
  | leaf | unary | binary

/-- 标签的「元数」：叶 0 个孩子（PEmpty）、单 1 个（PUnit）、双 2 个（Bool） -/
def arity : Tag → Type
  | .leaf => PEmpty
  | .unary => PUnit
  | .binary => Bool

def Tree : Type := Wt Tag arity

def leaf : Tree := .sup .leaf (fun e => PEmpty.elim e)
def node1 (t : Tree) : Tree := .sup .unary (fun _ => t)
def node2 (l r : Tree) : Tree := .sup .binary
  (fun b => match b with | true => l | false => r)

/-- W 递归的书写形态：对 sup 匹配，孩子们通过 f 喂给递归调用。
    归纳假设的打包版（rec 自动生成的 ih : ∀ x, motive (f x)）
    在内核里可用；可执行版走 WF 递归（本写法）。 -/
def size : Tree → Nat
  | .sup a f =>
      match a with
      | .leaf => 1                        -- f : PEmpty → Tree：零个孩子
      | .unary => 1 + size (f PUnit.unit) -- 一个孩子
      | .binary => 1 + size (f true) + size (f false)

example : size leaf = 1 := by rfl
example : size (node2 leaf leaf) = 3 := by rfl
example : size (node1 (node2 leaf (node1 leaf))) = 5 := by rfl

#eval size (node1 (node1 (node2 leaf leaf)))     -- 5

/- ---------- 编码二：ℕ 就是 W 的特例 ----------
   取标签 Bool：false = 零（0 个孩子），true = 后继（1 个孩子）。
   Nordström ch.15：任何归纳定义的集合都是某个良序的影子      -/

def arityN : Bool → Type
  | false => PEmpty
  | true => PUnit

def NatW : Type := Wt Bool arityN

def zw : NatW := .sup false (fun e => PEmpty.elim e)
def sw (n : NatW) : NatW := .sup true (fun _ => n)

def toNat : NatW → Nat
  | .sup false _ => 0
  | .sup true f => 1 + toNat (f PUnit.unit)

example : toNat zw = 0 := by rfl
example : toNat (sw (sw (sw zw))) = 3 := by rfl

/-- 在 W-ℕ 上做加法：把 m 的后继链改接到 n 尾上 -/
def addW : NatW → NatW → NatW
  | .sup false _, n => n
  | .sup true f, n => .sup true (fun u => addW (f u) n)

example : toNat (addW (sw (sw zw)) (sw (sw (sw zw)))) = 5 := by rfl

/- ---------- W 的表达力注记 ----------
   - List A ≅ W Bool（false→Empty，true→A×Unit）：标签还能带【负载】
     ——β 依赖 a 的值携带数据（A 分量）；
   - 一般树的标签集 = 构造子集，元数函数 = 每个构造子的参数数。
     「归纳定义 = 给一组 (标签， 元数)」——Nordström ch.16
     「一般树集合构造子」的现代读法（归纳族的祖先）。
   - W 的递归原理 = 良序归纳（Noetherian induction）的语法化身，
     它是 MLTT 里「任意归纳定义」合法性的根基（Dybjer 的
     internal induction-recursion 视角见正文）。 -/
