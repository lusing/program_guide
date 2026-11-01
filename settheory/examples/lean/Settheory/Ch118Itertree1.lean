/- 第 118 章：交错链的有限迭代树骨架。
   节点、张子所属模型与外部作用目标都是有限标签；不模拟真实 ZFC 模型。 -/
inductive Node where
  | n0 | n1 | n2 | n3 | n4 | n5 | n6
  deriving DecidableEq, Repr

inductive Ext where
  | e0 | e1 | e2 | e3 | e4 | e5
  deriving DecidableEq, Repr

open Node Ext

def parent : Node → Node
  | .n0 => .n0 | .n1 => .n0 | .n2 => .n0 | .n3 => .n1
  | .n4 => .n2 | .n5 => .n3 | .n6 => .n4

def source : Ext → Node
  | .e0 => .n0 | .e1 => .n1 | .e2 => .n2
  | .e3 => .n3 | .e4 => .n4 | .e5 => .n5

def target : Ext → Node
  | .e0 => .n0 | .e1 => .n0 | .e2 => .n1
  | .e3 => .n2 | .e4 => .n3 | .e5 => .n4

def child : Ext → Node
  | .e0 => .n1 | .e1 => .n2 | .e2 => .n3
  | .e3 => .n4 | .e4 => .n5 | .e5 => .n6

abbrev LegalApplication (e : Ext) : Prop :=
  parent (child e) = target e ∧ child e ≠ target e

theorem legal_e0 : LegalApplication e0 := by decide
theorem legal_e1 : LegalApplication e1 := by decide
theorem legal_e2 : LegalApplication e2 := by decide
theorem legal_e3 : LegalApplication e3 := by decide
theorem legal_e4 : LegalApplication e4 := by decide
theorem legal_e5 : LegalApplication e5 := by decide

theorem external_e1 : source e1 = n1 ∧ target e1 = n0 := by exact ⟨rfl, rfl⟩
theorem external_e3 : source e3 = n3 ∧ target e3 = n2 := by exact ⟨rfl, rfl⟩
theorem cross_branch_incomparable : parent n3 = n1 ∧ parent n4 = n2 := by exact ⟨rfl, rfl⟩

def crit : Ext → Nat
  | .e0 => 1 | .e1 => 2 | .e2 => 3
  | .e3 => 4 | .e4 => 5 | .e5 => 6

def strength (e : Ext) : Nat := crit e + 2

def toyEmbed (e : Ext) (x : Nat) : Nat :=
  if x < crit e then x else x + 1

theorem agreement (e : Ext) : crit e + 1 ≤ strength e := by
  simp [strength]

theorem toy_below_critical : toyEmbed e2 1 = 1 := by decide
theorem toy_moves_critical : toyEmbed e2 3 = 4 := by decide

def rootPath : Node → List Node
  | .n0 => [.n0]
  | .n1 => [.n0, .n1]
  | .n2 => [.n0, .n2]
  | .n3 => [.n0, .n1, .n3]
  | .n4 => [.n0, .n2, .n4]
  | .n5 => [.n0, .n1, .n3, .n5]
  | .n6 => [.n0, .n2, .n4, .n6]

theorem two_real_branch_prefixes :
    rootPath n6 = [n0, n2, n4, n6] ∧
    rootPath n5 = [n0, n1, n3, n5] := by exact ⟨rfl, rfl⟩
