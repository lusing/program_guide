/- ============================================================
   25 λD 中的数学：等式、序与描述子 —— Lean 主场（TTAFP ch.12–13）
     · Leibniz 等式是【描述式定义】不是公理：
       eq(S,x,y) := ∀P:S→Prop. P x ⇒ P y（Remark 12.2.1 的单向版）
     · refl/sym/trans/substitutivity（等换等）从定义免费推出
     · ∃¹ 三件套（∃≥1/∃≤1/∃¹）与描述子 ι——与 17 章 Farmer 的
       I 算子在同一处握手：λD 用原始定义+引理，Coq/Lean 用古典
       选择+唯一性钉死
     · 子集即谓词（ch.13）：ε 即应用；∩∪c 与 De Morgan；
       映射 = 泛关系（∀x ∃¹y）
   ============================================================ -/

-- ============================================================
-- 一、Leibniz 等式（书 12.2 Figure 12.2）
-- ============================================================

/-- x =S y := ∀P:S→Prop. P x ⇒ P y ——不可分辨者同一（单向版够用） -/
def EqL {S : Type} (x y : S) : Prop := ∀ P : S → Prop, P x → P y

/-- eq-refl（Figure 12.2 行 (3)）：λP.λu.u -/
theorem eqRefl {S : Type} (x : S) : EqL x x :=
  fun _ u => u

/-- 对称性：把 P 染成「P z ⇒ P x」施于 x 自身——Leibniz 芭蕾 -/
theorem eqSymm {S : Type} {x y : S} (h : EqL x y) : EqL y x :=
  fun P hy => h (fun z => P z → P x) (fun hx => hx) hy

/-- 传递性 -/
theorem eqTrans {S : Type} {x y z : S} (h1 : EqL x y) (h2 : EqL y z) : EqL x z :=
  fun P hx => h2 P (h1 P hx)

/-- 替换性（Figure 12.4）：等换等——P x 与 x=y 给 P y（就是定义！） -/
theorem eqSubst {S : Type} {x y : S} (P : S → Prop) (h : EqL x y) :
    P x → P y :=
  h P

/-- 同余性（书 12.3）：函数保等——x=y ⇒ f x = f y -/
theorem eqCongr {S T : Type} (f : S → T) {x y : S} (h : EqL x y) :
    EqL (f x) (f y) :=
  fun P hx => h (fun z => P (f z)) hx

/-- 原生等式到 Leibniz 等式的桥（证明项层免费） -/
theorem eqL_of_eq {S : Type} {a b : S} (h : a = b) : EqL a b := by
  subst h
  exact eqRefl a

-- ============================================================
-- 二、序与最小元的唯一性（书 12.4–12.6，Lemma 12.1.2）
-- ============================================================

section Order
variable {S : Type} (le : S → S → Prop)

/-- Least(S,≤,m) := ∀n:S. m ≤ n（Figure 12.13） -/
def IsLeast (m : S) : Prop := ∀ n : S, le m n

/-- Lemma 12.1.2：最小元若存在则唯一——反对称性作为语境假设
    （书 12.4 的 po 旗；variable 只在签名被提及时绑定，故显式传） -/
theorem leastUnique (antisym : ∀ a b : S, le a b → le b a → EqL a b)
    (m₁ m₂ : S) (h₁ : IsLeast le m₁) (h₂ : IsLeast le m₂) : EqL m₁ m₂ :=
  antisym m₁ m₂ (h₁ m₂) (h₂ m₁)

end Order

-- ============================================================
-- 三、∃¹ 三件套与描述子 ι（书 12.6–12.7）
-- ============================================================

/-- ∃≥1 := ∃（21 章 Ex2 的原生版） -/
def ExG1 {S : Type} (P : S → Prop) : Prop := ∃ x : S, P x

/-- ∃≤1 := ∀y z. P y ⇒ P z ⇒ y = z（Figure 12.14 行 (3)） -/
def ExL1 {S : Type} (P : S → Prop) : Prop :=
  ∀ y z : S, P y → P z → EqL y z

/-- ∃¹ := ∃≥1 ∧ ∃≤1（Figure 12.14 行 (4)） -/
def Ex1 {S : Type} (P : S → Prop) : Prop := ExG1 P ∧ ExL1 P

/- 描述子 ι：书 12.7 把它立为【原始定义】（公理），配引理
   iota-prop：∃¹ ⇒ ∀z. P z ⇒ z = ι。Lean 侧的对应物 =
   Classical.choose + 唯一性钉死（与 17 章 Farmer 的 I 算子
   同构——那边 V6 给语义条款，这边公理记账）。 -/

noncomputable def iotaL {S : Type} {P : S → Prop} (h : Ex1 P) : S :=
  Classical.choose h.1

/-- iota-prop（Lemma 12.7.1 机器版）：满足者必等于 ι -/
theorem iotaProp {S : Type} {P : S → Prop} (h : Ex1 P) (z : S)
    (pz : P z) : EqL z (iotaL h) :=
  h.2 z (iotaL h) pz (Classical.choose_spec h.1)

/-- ι 自己满足 P——「描述子的第一承诺」 -/
theorem iotaSat {S : Type} {P : S → Prop} (h : Ex1 P) : P (iotaL h) :=
  Classical.choose_spec h.1

-- 账本：ι 的全部便利记在古典选择头上（对照 17 章 Print Assumptions）
#print axioms iotaProp   -- Classical.choice, propext, Quot.sound

-- ============================================================
-- 四、子集即谓词（书 13.1–13.3）
-- ============================================================

/-- 子集 V := S → Prop（书 13.1：subset-as-predicate） -/
def PSet (S : Type) : Type := S → Prop

/-- x ε V := V x（ε 即应用——Figure 13.1） -/
def Mem {S : Type} (x : S) (V : PSet S) : Prop := V x

/-- 交（Figure 13.2）：点态 ∧ -/
def Cap {S : Type} (V W : PSet S) : PSet S := fun x => Mem x V ∧ Mem x W

/-- 并 -/
def Cup {S : Type} (V W : PSet S) : PSet S := fun x => Mem x V ∨ Mem x W

/-- 补 -/
def Compl {S : Type} (V : PSet S) : PSet S := fun x => ¬ Mem x V

/-- 单元素集 {x}（Figure 13.3 的 singleton——用 Leibniz 等式造） -/
def Single {S : Type} (x : S) : PSet S := fun y => EqL y x

-- 点态集合律三连
theorem deMorgan {S : Type} (V W : PSet S) (x : S) :
    Mem x (Compl (Cap V W)) ↔ Mem x (Cup (Compl V) (Compl W)) := by
  constructor
  · intro h
    by_cases hv : Mem x V
    · exact Or.inr (fun hw => h ⟨hv, hw⟩)
    · exact Or.inl hv
  · intro h ⟨hv, hw⟩
    cases h with
    | inl h1 => exact h1 hv
    | inr h2 => exact h2 hw

theorem interComm {S : Type} (V W : PSet S) (x : S) :
    Mem x (Cap V W) ↔ Mem x (Cap W V) :=
  ⟨fun h => ⟨h.2, h.1⟩, fun h => ⟨h.2, h.1⟩⟩

/-- 单元素集恰含自己（ε 与 EqL 的对齐） -/
theorem memSingleSelf {S : Type} (x : S) : Mem x (Single x) :=
  eqRefl x

/-- 等价类的成员：z ε [x]_R := R x z（书 13.4 的 [x]_R） -/
def InClass {S : Type} (R : S → S → Prop) (x z : S) : Prop := R x z

-- ============================================================
-- 五、映射 = 泛关系（书 13.5）
-- ============================================================

/-- F 是 S→T 的映射：∀x ∃¹y. F x y（Figure 13.13 的 functional） -/
def IsMap {S T : Type} (F : S → T → Prop) : Prop :=
  ∀ x : S, Ex1 (F x)

/-- 单射：同像 ⇒ 同原像（像点 a 同时被 x、y 关联则 x=y） -/
def Inj {S T : Type} (F : S → T → Prop) : Prop :=
  ∀ x y : S, ∀ a : T, F x a → F y a → EqL x y

/-- 满射 -/
def Surj {S T : Type} (F : S → T → Prop) : Prop :=
  ∀ y : T, ∃ x : S, F x y

/-- 双射 = 单 + 满 -/
def Bij {S T : Type} (F : S → T → Prop) : Prop := Inj F ∧ Surj F

/-- 样本：后继关系是泛关系（映射的存在性半边） -/
theorem succMap : IsMap (fun n m : Nat => m = n + 1) := by
  intro n
  refine ⟨⟨n + 1, rfl⟩, ?_⟩
  intro y z hy hz
  exact eqL_of_eq (hy.trans hz.symm)

/-- 后继关系单：像点同则原像同（Nat.succ 的单射性收尾） -/
theorem succInj : Inj (fun n m : Nat => m = n + 1) := by
  intro x y a hxa hya
  -- hxa : a = x + 1；hya : a = y + 1 ⇒ Nat.succ x = Nat.succ y
  exact eqL_of_eq (Nat.succ.inj (hxa.symm.trans hya))
