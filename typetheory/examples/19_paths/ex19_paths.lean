/- ============================================================
   19 恒等类型的同伦解读 —— Lean 侧
   Lean 的 Eq 住在 Prop：本文件把 Coq 版四条群律镜像一遍，
   并实测「Prop 层等式的天花板」——UIP（K）可证
   ============================================================ -/

/-- 组合（= Eq.trans 的手写镜像） -/
def pconcat {α : Sort u} {x y z : α} : x = y → y = z → x = z
  | rfl, q => q

/-- 逆转 -/
def pinv {α : Sort u} {x y : α} : x = y → y = x
  | rfl => rfl

/-- ap（= congrArg） -/
def pap {α β : Sort u} (f : α → β) {x y : α} : x = y → f x = f y
  | rfl => rfl

/-- transport -/
def ptransport {α : Sort u} (P : α → Sort v) {x y : α} : x = y → P x → P y
  | rfl, u => u

/- ---------- 群律（Coq 版镜像） ---------- -/

theorem pconcat_p1 {α : Sort u} {x y : α} (p : x = y)
    : pconcat p rfl = p := by cases p; rfl

theorem pconcat_pV {α : Sort u} {x y : α} (p : x = y)
    : pconcat p (pinv p) = rfl := by cases p; rfl

theorem pconcat_Vp {α : Sort u} {x y : α} (p : x = y)
    : pconcat (pinv p) p = rfl := by cases p; rfl

theorem pinv_pp {α : Sort u} {x y : α} (p : x = y)
    : pinv (pinv p) = p := by cases p; rfl

/- ---------- Prop 层的天花板：UIP 可证 ----------
   同一点上的所有相等证明相等——「无高维结构」是 Prop 的设计。
   HoTT 要的是 Type 层的 paths（Coq 版自造的原因）。      -/

theorem uip {α : Sort u} {x : α} (p q : x = x) : p = q := by
  cases p
  cases q
  rfl

#check @uip

/- ---------- 数值搬运 ---------- -/

def P (n : Nat) : Type := if n = 0 then Bool else Nat

-- 搬运演示用常值族（P 3 的 if 分支不是语法上的 Nat，数字标注失明）
example : ptransport (fun _ => Nat) (rfl : 3 = 3) 3 = 3 := rfl

/- ---------- 三家住层对照（正文 19.4 的机器注脚） ----------
   Coq eq   : Prop（高维要自造 paths——ex19_paths.v 的 Unset
              Automatic Proposition Inductives）
   Lean Eq  : Prop（UIP 定理如上；泛等不可加——与 K 冲突）
   Agda _≡_ : Set（Type 层，J 可关 --without-K）          -/
