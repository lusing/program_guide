/-
  ============================================================
  47 实数 —— Lean 对照（HoTT 书 ch.11）
    · Cauchy 实数的骨架：抽象有序域 Q 上的 Cauchy 列 +
      极限等价 + Quot 商（26 章整数商的姊妹工程）
    · Dedekind 实数的骨架：切割 = 左右两个谓词（子集即谓词
      ——25/67 章策略第三次服役）
    · 两种实数的对照（11.4）：Cauchy ⊆ Dedekind 恒真；
      反向需要排中——「Cauchy 不足」的构造性真相
  ============================================================
-/

namespace Ex47

/- ---------- 〇、基座：抽象有序域 Q（公理化账目公示） ---------- -/

axiom Q : Type
axiom Qadd : Q → Q → Q
axiom Qmul : Q → Q → Q
axiom Qlt : Q → Q → Prop
axiom Qone : Q
@[simp] axiom Qadd_comm (a b : Q) : Qadd a b = Qadd b a
@[simp] axiom Qadd_assoc (a b c : Q) : Qadd (Qadd a b) c = Qadd a (Qadd b c)

/- ---------- 一、Cauchy 实数（书 11.3 的骨架） ---------- -/

/-- 「是 Cauchy 列」（公理化谓词——完整 ε-N 定义见 docs） -/
axiom isCauchy : (Nat → Q) → Prop

structure CSeq where
  seq : Nat → Q
  isC : isCauchy seq

/-- 极限等价（二元）：两列差趋零——商的等价关系 -/
axiom conv0 : (Nat → Q) → (Nat → Q) → Prop

@[simp] axiom conv0_refl (x : Nat → Q) : conv0 x x
@[simp] axiom conv0_symm {x y : Nat → Q} (h : conv0 x y) : conv0 y x
@[simp] axiom conv0_trans {x y z : Nat → Q} (h1 : conv0 x y) (h2 : conv0 y z) :
    conv0 x z

/-- Cauchy 实数 = Cauchy 列的商（26 章整数商的姊妹工程） -/
def ℝC : Type := Quot (fun (x y : CSeq) => conv0 x.seq y.seq)

/-- 逐点加法保持等价（等价相容公理） -/
axiom conv0_add : ∀ {x x' y y' : Nat → Q}, conv0 x x' → conv0 y y' →
    conv0 (fun n => Qadd (x n) (y n)) (fun n => Qadd (x' n) (y' n))

/-- 加法保持 Cauchy 性（公理账目：ε-N 三角不等式的打包） -/
axiom isCauchy_add : ∀ {x y : Nat → Q}, isCauchy x → isCauchy y →
    isCauchy (fun n => Qadd (x n) (y n))

noncomputable def addSeq (x y : CSeq) : CSeq :=
  ⟨fun n => Qadd (x.seq n) (y.seq n), isCauchy_add x.isC y.isC⟩

/-- 相容性：等价的列加出等价的列——商提升的「良定义」本体 -/
theorem addSeq_compat {x x' y y' : CSeq} (hx : conv0 x.seq x'.seq)
    (hy : conv0 y.seq y'.seq) : conv0 (addSeq x y).seq (addSeq x' y').seq :=
  conv0_add hx hy

/-- 商上的加法（Quot 双 lift 的标准装配——Lean core 无内置
    lift₂，26 章整数商有完整模板；以公理化账目呈现良定义性） -/
axiom ℝC_add : ℝC → ℝC → ℝC

/- ---------- 二、Dedekind 实数（书 11.2 的骨架） ---------- -/

/-- 子集即谓词（三代同款：25 章 λD → 67 章 Pow → 本章 Cut） -/
def Cut (Q' : Type) : Type := Q' → Prop

/-- Dedekind 切割：左集 L 右集 U，四公理（ inhabited、向下
    封闭、不相交、联合无洞——完整版含 locatedness） -/
structure Dedekind where
  L : Cut Q
  U : Cut Q
  Linh : ∃ q, L q
  Uinh : ∃ q, U q
  Ldown : ∀ q r, L q → Qlt r q → L r
  disjoint : ∀ q, ¬ (L q ∧ U q)

/- ---------- 三、两种实数的对照（书 11.4） ---------- -/

/-- Cauchy → Dedekind：构造性恒真（L q := 序列终将超过 q）。
    真实构造需要 Q 的完备与 conv0 的极限定理——骨架文件以
    公理化账目呈现（「翻译存在」是本章骨架的假设面）。 -/
axiom cauchy_to_dedekind : ℝC → Dedekind
/- 形状说明：L/U 的谓词对、四公理的排布见上方 Dedekind 结构；
   反向（Dedekind → Cauchy）在构造世界**需要排中**（书 11.4.1
   的诚实结论：两种实数不同构，除非加 LEM）——这不是缺陷
   而是分层：Cauchy 实数是「可计算的实数」，Dedekind 是
   「理想的实数」，经典数学把它们捏在一起。 -/

end Ex47
