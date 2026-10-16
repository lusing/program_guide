/- ============================================================
   21 λC 中的逻辑编码 —— Lean 主场（TTAFP ch.7）
     · 连接词的二阶编码即程序：⊥ ¬ ∧ ∨ ∃ 全部写成 Prop 上的
       定义，intro/elim 是它们的居留项——「可推导」不再是引理
       而是几行 λ 抽象
     · 图 7.1 的重言式 (A∨B)⇒(¬A⇒B)：书上的证明项原样搬运
     · ET ↔ DN 互推（7.4）：古典公理的相对定理——
       零公理地证明「排中与双否等价」
     · 一阶编码的单向落差：Or2→(¬A→B) 构造性成立，
       反方向必须请出 ET——分界线机器可验
   ============================================================ -/

-- ============================================================
-- 一、二阶编码全家福（TTAFP 7.1/7.2/7.5）
-- ============================================================

/-- ⊥ := ∀α:Prop. α——「若 ⊥ 居留则一切命题居留」的化身 -/
def Bot : Prop := ∀ p : Prop, p

/-- ¬A := A → ⊥ -/
def Not2 (A : Prop) : Prop := A → Bot

/-- A ∧ B := ∀C. (A → B → C) → C ——二阶编码（7.2 I） -/
def And2 (A B : Prop) : Prop := ∀ C : Prop, (A → B → C) → C

/-- A ∨ B := ∀C. (A → C) → (B → C) → C ——二阶编码（7.2 II） -/
def Or2 (A B : Prop) : Prop := ∀ C : Prop, (A → C) → (B → C) → C

/-- ∃x:S. P x := ∀C. (∀x:S. P x → C) → C ——二阶编码（7.5） -/
def Ex2 {S : Type} (P : S → Prop) : Prop := ∀ C : Prop, (∀ x : S, P x → C) → C

-- ============================================================
-- 二、⊥-elim 免费 + 连接词的 intro/elim 全部可推导
-- ============================================================

/-- ⊥-elim（ex falso）就是一次应用——Remark 7.1.1 的机器版 -/
theorem bot_elim (h : Bot) (A : Prop) : A := h A

/-- ∧-intro：λC 里是 λz:A→B→C. z x y（书 7.2 的推导 (4)） -/
theorem and2_intro {A B : Prop} (a : A) (b : B) : And2 A B :=
  fun _ z => z a b

/-- ∧-elim-left：把 C 实例化为 A（书练习 7.4 的答案） -/
theorem and2_left {A B : Prop} (h : And2 A B) : A :=
  h A (fun a _ => a)

/-- ∧-elim-right -/
theorem and2_right {A B : Prop} (h : And2 A B) : B :=
  h B (fun _ b => b)

/-- ∨-intro-left -/
theorem or2_intro_left {A B : Prop} (a : A) : Or2 A B :=
  fun _ h1 _ => h1 a

/-- ∨-intro-right -/
theorem or2_intro_right {A B : Prop} (b : B) : Or2 A B :=
  fun _ _ h2 => h2 b

/-- ∨-elim：三分支——就是编码本身的应用 -/
theorem or2_elim {A B C : Prop} (h : Or2 A B) (h1 : A → C) (h2 : B → C) : C :=
  h C h1 h2

/-- ∃-intro：见证 a + 证据 u（书 7.5 的 ? ≡ λα.λw. w a u） -/
theorem ex2_intro {S : Type} {P : S → Prop} (a : S) (u : P a) : Ex2 P :=
  fun _ w => w a u

/-- ∃-elim：边条件 x∉FV(A) 由类型结构天然强制（Remark 7.5.2） -/
theorem ex2_elim {S : Type} {P : S → Prop} {A : Prop}
    (h : Ex2 P) (w : ∀ x : S, P x → A) : A :=
  h A w

-- ============================================================
-- 三、图 7.1：重言式 (A ∨ B) ⇒ (¬A ⇒ B) 的原样搬运
-- ============================================================

/-- 书 Figure 7.1 第 (10) 行的证明项——一个 λ 表达式，
    其中「灵光一现」是把 x 应用到命题 B 上 -/
theorem or_implies_or {A B : Prop} : Or2 A B → Not2 A → B :=
  fun x y => x B (fun u => (y u) B) (fun v => v)

/- 读法：x : Or2 A B 编码展开是 ∀C. (A→C)→(B→C)→C；
   把 C 取作 B 得 (A→B)→(B→B)→B；
   · A→B 的居留项：λu:A. (y u) B ——先用 y u : Bot，
     再 Bot-elim（就是应用）得 B（书第 (2)(3) 行）
   · B→B 的居留项：恒等（书第 (7) 行）
   两次 appl 后收尾——正是书上行 (1)–(10) 的机器镜像。 -/

-- ============================================================
-- 四、古典升级：ET ↔ DN 互推（TTAFP 7.4）
-- ============================================================

-- ET 当假设（书：iET : Πα:*. α ∨ ¬α 放在语境最前端）——
-- 注意：Lean 的 variable 只在【签名】里被提及时自动绑定，
-- 正文里用不算，所以这里显式作参数

/-- 书 7.4 的推导：ET ⊢ DN——证明项逐行对应
    iET β β (λy:β.y) (λz:¬β. x z β) -/
theorem dn_from_et (et : ∀ p : Prop, Or2 p (Not2 p)) {β : Prop}
    (x : Not2 (Not2 β)) : β :=
  et β β (fun y => y) (fun z => (x z) β)

/-- ¬¬(p ∨ ¬p) 是构造性定理（不需要任何古典公理）——
    DN 路线的引擎 -/
theorem nn_or_nn (p : Prop) : Not2 (Not2 (Or2 p (Not2 p))) :=
  fun n => n (or2_intro_right (fun pp => n (or2_intro_left pp)))

/-- 反方向：DN ⊢ ET——用 dn 消掉那层构造性可得的 ¬¬ -/
theorem et_from_dn (dn : ∀ p : Prop, Not2 (Not2 p) → p) (p : Prop) :
    Or2 p (Not2 p) :=
  dn (Or2 p (Not2 p)) (nn_or_nn p)

-- 两台机器的互推都是【相对定理】：
#print axioms dn_from_et   -- 不依赖任何公理
#print axioms et_from_dn   -- 同上——古典公理之间的等价性是构造性事实

-- 对照：Lean core 把 ET 当公理直接发货
#print axioms Classical.em -- '[Classical.choice, propext, Quot.sound]'

-- ============================================================
-- 五、一阶编码的单向落差（7.2/7.8）
-- ============================================================

-- 「∨ 的一阶编码」¬A → B：
--   正向 Or2 A B → (¬A → B) 构造性成立——
theorem or2_to_cls {A B : Prop} : Or2 A B → Not2 A → B :=
  fun h na => h B (fun a => bot_elim (na a) B) (fun b => b)

--   反向 (¬A → B) → Or2 A B 构造性不可得，必须 ET：
theorem cls_to_or2 (et : ∀ p : Prop, Or2 p (Not2 p)) {A B : Prop} :
    (Not2 A → B) → Or2 A B :=
  fun h =>
    or2_elim (et A) (fun a => or2_intro_left a) (fun na => or2_intro_right (h na))

/- 书 7.2 的话：「一阶编码只在古典逻辑里工作」——机器上
   表现为半边可证、半边要借 ET。∧ 的 ¬(¬A ∨ ¬B)、∃ 的
   ¬∀¬ 同理（见正文）。 -/

-- ============================================================
-- 六、与原生连接词的同构对照
-- ============================================================

/-- 二阶编码与 Lean 原生 And 完全同构 -/
theorem and2_iff (A B : Prop) : And2 A B ↔ (A ∧ B) :=
  ⟨fun h => ⟨and2_left h, and2_right h⟩,
   fun h => and2_intro h.1 h.2⟩

theorem or2_iff (A B : Prop) : Or2 A B ↔ (A ∨ B) :=
  ⟨fun h => or2_elim h Or.inl Or.inr,
   fun h => h.elim or2_intro_left or2_intro_right⟩

theorem ex2_iff {S : Type} (P : S → Prop) : Ex2 P ↔ ∃ x, P x :=
  ⟨fun h => ex2_elim h (fun x px => ⟨x, px⟩),
   fun h => Exists.elim h (fun x px => ex2_intro x px)⟩

/-- 谓词逻辑样本（书 7.6）：¬∃ ⇒ ∀¬ ——证明项即书第 (5) 行 -/
theorem not_ex_all_not {S : Type} (P : S → Prop) :
    Not2 (Ex2 P) → ∀ y : S, Not2 (P y) :=
  fun u y v => u (ex2_intro y v)
