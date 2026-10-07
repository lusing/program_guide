/- ex50 —— Boole 代数与逻辑电路（Jongsma ch7 §7.3-7.6）Lean 镜像
   B={0,1} 十公理+推论律+门动物园+半加器/全加器/两位行波+minterm 定理。
   QMC 在 Prolog 通道 ex56_boole.pl。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. B={0,1}：十公理验证（书 §7.3.3 例 7.3.3） ----------

theorem b_comm_or : ∀ x y : Bool, (x || y) = (y || x) := by
  intro x y; cases x <;> cases y <;> rfl

theorem b_comm_and : ∀ x y : Bool, (x && y) = (y && x) := by
  intro x y; cases x <;> cases y <;> rfl

theorem b_assoc_or : ∀ x y z : Bool,
    ((x || y) || z) = (x || (y || z)) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl

theorem b_assoc_and : ∀ x y z : Bool,
    ((x && y) && z) = (x && (y && z)) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl

-- 第二分配律：+ 对 · 也分配——普通算术没有（1+2*3=7 ≠ 12）
theorem b_dist_and : ∀ x y z : Bool,
    (x && (y || z)) = ((x && y) || (x && z)) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl

theorem b_dist_or : ∀ x y z : Bool,
    (x || (y && z)) = ((x || y) && (x || z)) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl

theorem b_ident_or : ∀ x : Bool, (x || false) = x := by
  intro x; cases x <;> rfl

theorem b_ident_and : ∀ x : Bool, (x && true) = x := by
  intro x; cases x <;> rfl

theorem b_compl_or : ∀ x : Bool, (x || !x) = true := by
  intro x; cases x <;> rfl

theorem b_compl_and : ∀ x : Bool, (x && !x) = false := by
  intro x; cases x <;> rfl

-- ---------- 2. 公理的推论（书 Prop 7.3.1-7.3.9 精选） ----------

theorem b_idem_or : ∀ x : Bool, (x || x) = x := by
  intro x; cases x <;> rfl

theorem b_idem_and : ∀ x : Bool, (x && x) = x := by
  intro x; cases x <;> rfl

-- 湮灭律（书 Prop 7.3.4ab）
theorem b_annih_and : ∀ x : Bool, (x && false) = false := by
  intro x; cases x <;> rfl

theorem b_annih_or : ∀ x : Bool, (x || true) = true := by
  intro x; cases x <;> rfl

-- 吸收律（书 Prop 7.3.4cd）
theorem b_absorb_and : ∀ x y : Bool, (x && (x || y)) = x := by
  intro x y; cases x <;> cases y <;> rfl

theorem b_absorb_or : ∀ x y : Bool, (x || (x && y)) = x := by
  intro x y; cases x <;> cases y <;> rfl

-- 补元律（书 Prop 7.3.2）
theorem b_not_not : ∀ x : Bool, !(!x) = x := by
  intro x; cases x <;> rfl

-- De Morgan（书 Prop 7.3.5）
theorem b_demorgan_and : ∀ x y : Bool,
    !(x && y) = (!x || !y) := by
  intro x y; cases x <;> cases y <;> rfl

theorem b_demorgan_or : ∀ x y : Bool,
    !(x || y) = (!x && !y) := by
  intro x y; cases x <;> cases y <;> rfl

-- 运算联动律（书 Prop 7.3.6）：普遍双条件——三分支按情形手拼
theorem b_linkage : ∀ x y : Bool, (x && y) = x ↔ (x || y) = y := by
  intro x y
  match x, y with
  | true, true => exact ⟨fun h => h, fun h => h⟩
  | true, false => exact ⟨fun h => Bool.noConfusion h,
                           fun h => Bool.noConfusion h⟩
  | false, _ => exact ⟨fun _ => rfl, fun _ => rfl⟩

-- 冗余律（书 Prop 7.3.7：x(x̅+y)=xy、x+x̅y=x+y——PDF 文本层丢上杠）
theorem b_redund_and : ∀ x y : Bool,
    (x && (!x || y)) = (x && y) := by
  intro x y; cases x <;> cases y <;> rfl

theorem b_redund_or : ∀ x y : Bool,
    (x || (!x && y)) = (x || y) := by
  intro x y; cases x <;> cases y <;> rfl

-- 共识律（书 Prop 7.3.8a：xy + x̄z + yz = xy + x̄z——同坑，中间项须带补）
theorem b_consensus : ∀ x y z : Bool,
    (((x && y) || (!x && z)) || (y && z)) = ((x && y) || (!x && z)) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl

-- 消去律（书 Prop 7.3.9）：x=0 靠 + 等式，x=1 靠 · 等式
-- （false || y 与 true && y 对 y 是 defeq——exact 直接交假设）
theorem b_cancel : ∀ x y z : Bool,
    (x && y) = (x && z) → (x || y) = (x || z) → y = z := by
  intro x y z h1 h2
  cases x with
  | false => exact h2
  | true => exact h1

-- ---------- 3. 门动物园（书 Table 7.1） ----------

def nand (x y : Bool) : Bool := !(x && y)
def nor (x y : Bool) : Bool := !(x || y)
def xnor (x y : Bool) : Bool := !(xor x y)

theorem nand_form : ∀ x y : Bool, nand x y = (!x || !y) := by
  intro x y; cases x <;> cases y <;> rfl

theorem nor_form : ∀ x y : Bool, nor x y = (!x && !y) := by
  intro x y; cases x <;> cases y <;> rfl

-- xor 的积之和形：可接受串恰为 01 与 10
theorem xor_form : ∀ x y : Bool,
    xor x y = ((x && !y) || (!x && y)) := by
  intro x y; cases x <;> cases y <;> rfl

-- xnor 可接受 00 与 11——等值门
theorem xnor_accept : ∀ x y : Bool, xnor x y = true ↔ x = y := by
  intro x y; cases x <;> cases y <;> simp [xnor]

-- ---------- 4. 加法器：布尔电路做算术（书例 7.4.9/7.4.10） ----------

def bval (b : Bool) : Nat := match b with | true => 1 | false => 0

-- 半加器：和位=xor、进位=and（书例 7.4.9b）
def ha (x y : Bool) : Bool × Bool := (xor x y, x && y)

theorem ha_correct : ∀ x y : Bool,
    bval (ha x y).1 + 2 * bval (ha x y).2 = bval x + bval y := by
  intro x y; cases x <;> cases y <;> rfl

-- 全加器：两个半加器拼装（书例 7.4.10 / Ex 7.4.43）
def fa (w x y : Bool) : Bool × Bool :=
  ((ha w (ha x y).1).1, (ha x y).2 || (ha w (ha x y).1).2)

theorem fa_correct : ∀ w x y : Bool,
    bval (fa w x y).1 + 2 * bval (fa w x y).2
    = bval w + bval x + bval y := by
  intro w x y; cases w <;> cases x <;> cases y <;> rfl

-- 两位行波进位：低位半加器出进位，高位全加器吃进位
def add2 (a1 a0 b1 b0 : Bool) : Bool × Bool × Bool :=
  ((fa a1 b1 (ha a0 b0).2).2, (fa a1 b1 (ha a0 b0).2).1, (ha a0 b0).1)

theorem add2_correct : ∀ a1 a0 b1 b0 : Bool,
    bval (add2 a1 a0 b1 b0).2.2
    + 2 * bval (add2 a1 a0 b1 b0).2.1
    + 4 * bval (add2 a1 a0 b1 b0).1
    = (2 * bval a1 + bval a0) + (2 * bval b1 + bval b0) := by
  intro a1 a0 b1 b0
  cases a1 <;> cases a0 <;> cases b1 <;> cases b0 <;> rfl

-- ---------- 5. minterm 表示定理（书 Thm 7.5.1 的机器版） ----------

-- 文字：s=1 取正文字 x，s=0 取反文字 x̅
def lit (s x : Bool) : Bool := match s with | true => x | false => !x

-- 单个 minterm 恰接受一个输入串（书 Prop 7.5.2 的核心）
theorem minterm_accept : ∀ s1 s2 x1 x2 : Bool,
    (lit s1 x1 && lit s2 x2) = true ↔ (x1 = s1 ∧ x2 = s2) := by
  intro s1 s2 x1 x2
  cases s1 <;> cases x1 <;> cases s2 <;> cases x2 <;> simp [lit]

/- n=2 一般定理：任意 f 都等于其接受行 minterm 之和（书 Thm 7.5.1）。
   系数写在 minterm 右侧（&& 从左匹配字面量，cases 后死项先归 false）；
   幸存项若不在链尾，or 链在 f 的不透明应用处卡住——由外向内
   Bool.or_false 逐层剥掉右侧的 false 尾巴 -/
theorem dnf2 (f : Bool → Bool → Bool) : ∀ x y : Bool,
    f x y =
      ((lit true x && lit true y) && f true true)
      || ((lit true x && lit false y) && f true false)
      || ((lit false x && lit true y) && f false true)
      || ((lit false x && lit false y) && f false false) := by
  intro x y
  cases x <;> cases y <;> simp [lit]

-- 三元多数函数（书例 7.5.5/7.5.6）：简化形 = minterm 展开
def maj (x y z : Bool) : Bool := (x && y) || ((x && z) || (y && z))

theorem maj_dnf : ∀ x y z : Bool,
    maj x y z =
      ((x && y) && z)
      || ((x && y) && !z)
      || ((x && !y) && z)
      || ((!x && y) && z) := by
  intro x y z; cases x <;> cases y <;> cases z <;> rfl

-- ---------- 6. 冒烟与账本 ----------

#eval maj true false true          -- true：两票即可
#eval (ha true true).1             -- false：1+1=10，和位 0
#eval (fa true true true).2        -- true：1+1+1=11，进位 1
#eval add2 true false false true   -- (false, true, true)：10+01=11

#print axioms b_dist_or
#print axioms b_consensus
#print axioms b_cancel
#print axioms ha_correct
#print axioms fa_correct
#print axioms add2_correct
#print axioms dnf2
#print axioms maj_dnf
