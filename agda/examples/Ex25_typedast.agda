------------------------------------------------------------------------
-- 第 25 章示例：类型良好表达式解释器——依赖 AST，构造即正确
--
-- 四段进化：朴素 Exp（坏式子能写、求值器私吞垃圾）→ 良 scoped Tm n
-- （变量是 Fin n，weaken/subst 及两条免费定律）→ 良 typed TExp Γ τ
-- （上下文是类型表，坏式子不可构造）→ 优化 pass（常量折叠，正确性
-- 仍要归纳）。收尾算账：哪些是免费午餐，哪些必须自己证。
--
-- 类型检查：cd agda && agda examples/Ex25_typedast.agda
------------------------------------------------------------------------

module Ex25_typedast where

open import Data.Bool using (Bool; true; false)
open import Data.Nat using (ℕ; zero; suc; _+_; _≟_)
open import Data.Fin using (Fin) renaming (zero to fzero; suc to fsuc)
open import Data.List using (List; []; _∷_; length)
open import Data.List.Base renaming (lookup to lookupL)
open import Data.Product using (_×_; _,_)
open import Data.Unit using (⊤; tt)
open import Data.Vec using (Vec; []; _∷_) renaming (lookup to lookupV)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; cong; cong₂; module ≡-Reasoning)

open ≡-Reasoning

------------------------------------------------------------------------
-- 25.1 朴素版：什么都能写，坏案子运行期才炸
------------------------------------------------------------------------

-- coq/lean 教程同款 AST：数、布林、加、判零、条件全混在一条语法里，
-- `true + 1` 这类坏式子是**合法项**，构造毫无门槛。
data Exp : Set where
  nnum : ℕ → Exp
  nbool : Bool → Exp
  nplus : Exp → Exp → Exp
  niszero : Exp → Exp
  ncond : Exp → Exp → Exp → Exp      -- 条件、then、else

-- 求值得先造一个「值宇宙」：数与布林塞进同一个类型
data V : Set where
  vℕ : ℕ → V
  vB : Bool → V

-- 坏案子的处理全靠「私吞」：没有任何类型约束阻止你写垃圾分支
plusV : V → V → V
plusV (vℕ m) (vℕ n) = vℕ (m + n)
plusV _ _ = vℕ zero                  -- true + 1 = 0？没人规定过，编的

isZeroV : V → V
isZeroV (vℕ m) with m ≟ zero
... | yes _ = vB true
... | no _ = vB false
isZeroV _ = vB false                 -- iszero true？又编一个

toBoolV : V → V
toBoolV (vB b) = vB b
toBoolV _ = vB true                  -- if 3 then… else…？条件默认 true

eval♮ : Exp → V
eval♮ (nnum n) = vℕ n
eval♮ (nbool b) = vB b
eval♮ (nplus a b) = plusV (eval♮ a) (eval♮ b)
eval♮ (niszero e) = isZeroV (eval♮ e)
eval♮ (ncond c a b) with toBoolV (eval♮ c)
... | vB true = eval♮ a
... | vB false = eval♮ b
... | vℕ n = vℕ n                    -- 到不了，但覆盖率检查要你把这条写完

-- 坏式子不但能写，还能「算出个结果」——这才是最可怕的：
bad₁ : Exp
bad₁ = nplus (nbool true) (nnum 1)

_ : eval♮ bad₁ ≡ vℕ zero             -- true + 1 = 0，静默吞 bug
_ = refl

-- 条件被劫持也能「算完」：if 3 then true else false 悄悄选了 then
_ : eval♮ (ncond (nnum 3) (nbool true) (nbool false)) ≡ vB true
_ = refl

-- 而且朴素求值器**必须**为不可达分支写代码（上面第三条 vℕ n）：
-- 类型没收住，垃圾分支就删不掉。coq 教程把这类分支交给
-- 「求值返回 option + 事后正确性定理」；Agda 的路线是继续升级语法，
-- 直接让坏式子**不可构造**。

------------------------------------------------------------------------
-- 25.2 升级一：良 scoped——变量是 Fin n（10 章回收）
------------------------------------------------------------------------

-- 先只治「变量越界/未绑定」这一种病：Tm n 的 n = 作用域大小，
-- 变量下标是 Fin n——而 Fin n 恰是「小于 n 的证明」，越界造不出来。
data Tm : ℕ → Set where
  var : ∀ {n} → Fin n → Tm n
  num : ∀ {n} → ℕ → Tm n
  plus : ∀ {n} → Tm n → Tm n → Tm n

-- 环境变量表：n 个 ℕ 排成 Vec（16 章），下标 0 = 最内层绑定。
-- 注意类型里没有 Maybe、没有错误分支：n = 0 时 var 分支**不存在**
-- （Fin 0 无居民，10 章荒谬模式），覆盖率检查认账。
eval₀ : ∀ {n} → Tm n → Vec ℕ n → ℕ
eval₀ (var i) ρ = lookupV ρ i
eval₀ (num m) ρ = m
eval₀ (plus a b) ρ = eval₀ a ρ + eval₀ b ρ

-- 闭包扩大：外面多套一层绑定，所有下标 fsuc 顶一格
weaken : ∀ {n} → Tm n → Tm (suc n)
weaken (var i) = var (fsuc i)
weaken (num m) = num m
weaken (plus a b) = plus (weaken a) (weaken b)

-- 代换（β 的味道）：0 号变量换成 t，其余下标降一格。
-- var 的下标是 Fin (suc n)，构造子模式 fzero/fsuc 自动做「判定」——
-- 模式匹配即决策，没有运行期查表。
sub : ∀ {n} → Tm (suc n) → Tm n → Tm n
sub (var fzero) t = t
sub (var (fsuc i)) t = var i
sub (num m) t = num m
sub (plus a b) t = plus (sub a t) (sub b t)

-- 空作用域里没有 var 可用——「忘绑定就引用」整类 bug 不可表达：
closed : Tm zero
closed = plus (num 1) (num 2)        -- 只剩 num/plus 可挑

-- 两条「免费午餐」定律：证起来全是 refl/cong（13 章剧本走个过场）
weaken-lemma : ∀ {n} (t : Tm n) (x : ℕ) (ρ : Vec ℕ n) →
               eval₀ (weaken t) (x ∷ ρ) ≡ eval₀ t ρ
weaken-lemma (var i) x ρ = refl      -- lookupV (x ∷ ρ) (fsuc i) 定义相等
weaken-lemma (num m) x ρ = refl
weaken-lemma (plus a b) x ρ = cong₂ _+_ (weaken-lemma a x ρ) (weaken-lemma b x ρ)

sub-lemma : ∀ {n} (t : Tm (suc n)) (u : Tm n) (ρ : Vec ℕ n) →
            eval₀ (sub t u) ρ ≡ eval₀ t (eval₀ u ρ ∷ ρ)
sub-lemma (var fzero) u ρ = refl
sub-lemma (var (fsuc i)) u ρ = refl
sub-lemma (num m) u ρ = refl
sub-lemma (plus a b) u ρ = cong₂ _+_ (sub-lemma a u ρ) (sub-lemma b u ρ)

-- 实例：下标 0/1 的二元加法，逐层实例化
t₂ : Tm 2
t₂ = plus (var fzero) (var (fsuc fzero))

_ : eval₀ t₂ (10 ∷ 20 ∷ []) ≡ 30
_ = refl

_ : eval₀ (sub t₂ (num 7)) (20 ∷ []) ≡ 27          -- 0 ↦ 7：7 + 20
_ = refl

_ : eval₀ (sub (sub t₂ (num 7)) (num 8)) [] ≡ 15   -- 再 1 ↦ 8：7 + 8
_ = refl

------------------------------------------------------------------------
-- 25.3 升级二：良 typed——上下文是类型表，坏式子不可构造（16 章回收）
------------------------------------------------------------------------

data Ty : Set where
  bool nat : Ty

Val : Ty → Set
Val bool = Bool
Val nat = ℕ

-- 变量在上下文中的位置：here/there 是「de Bruijn 版 Fin」——
-- 构造即携带「τ 确实属于 Γ」的证据。
infix 4 _∈_
data _∈_ : Ty → List Ty → Set where
  here : ∀ {τ Γ} → τ ∈ τ ∷ Γ
  there : ∀ {τ σ Γ} → τ ∈ Γ → τ ∈ σ ∷ Γ

-- 上下文实例化：Inst Γ 按类型表逐项配值——和 Vec A n 同一个套路的
-- 异构表，元素类型由 Γ 对应位置的 τ 算出来（Vec 的「λ 位置 → Set」
-- 一般化，即函数式 Vec/Π-Vec 思路）。
Inst : List Ty → Set
Inst [] = ⊤
Inst (τ ∷ Γ) = Val τ × Inst Γ

lookupInst : ∀ {Γ τ} → τ ∈ Γ → Inst Γ → Val τ
lookupInst here (v , ρ) = v
lookupInst (there p) (v , ρ) = lookupInst p ρ

-- 良 typed AST：索引 (Γ, τ) =「在上下文 Γ 中此式类型为 τ」。三处手术刀：
--   plus/iszero 的参数与结果类型焊死（nat/bool）；
--   条件必须是 bool 型，两分支共享同一结果类型 τ；
--   var 的返回类型由 _∈_ 证据决定——查得到才有类型。
data TExp : (Γ : List Ty) → Ty → Set where
  var : ∀ {Γ τ} → τ ∈ Γ → TExp Γ τ
  num : ∀ {Γ} → (n : ℕ) → TExp Γ nat
  bval : ∀ {Γ} → (b : Bool) → TExp Γ bool
  plus : ∀ {Γ} → TExp Γ nat → TExp Γ nat → TExp Γ nat
  iszero : ∀ {Γ} → TExp Γ nat → TExp Γ bool
  if_then_else_ : ∀ {Γ τ} → TExp Γ bool → TExp Γ τ → TExp Γ τ → TExp Γ τ

isz : ℕ → Bool
isz zero = true
isz (suc _) = false

-- 真·求值器：**良类型源项的求值永不失败**——返回类型是 Val τ 而非
-- Maybe (Val τ)，一个错误分支都不需要。coq 教程 19 章里「求值器
-- 输出正确」是事后定理；这里是前验类型，错的东西根本进不来。
eval : ∀ {Γ τ} → TExp Γ τ → Inst Γ → Val τ
eval (var p) ρ = lookupInst p ρ
eval (num n) ρ = n
eval (bval b) ρ = b
eval (plus a b) ρ = eval a ρ + eval b ρ
eval (iszero e) ρ = isz (eval e ρ)
eval (if c then a else b) ρ = Data.Bool.if_then_else_ (eval c ρ) (eval a ρ) (eval b ρ)

-- 上下文加宽：外层多绑一个 σ，旧变量全体 there——良 scoped 版
-- weaken 的类型镜像，免费。
extend : ∀ {Γ τ σ} → TExp Γ τ → TExp (σ ∷ Γ) τ
extend (var p) = var (there p)
extend (num n) = num n
extend (bval b) = bval b
extend (plus a b) = plus (extend a) (extend b)
extend (iszero e) = iszero (extend e)
extend (if c then a else b) = if extend c then extend a else extend b

-- Inst 与函数表形式互转：Π i → Val (lookupL Γ i) 是 16 章
-- Data.Vec.Functional 的 Vector（Fin 下标化）的依赖版。
InstΠ : List Ty → Set
InstΠ Γ = (i : Fin (length Γ)) → Val (lookupL Γ i)

toΠ : ∀ {Γ} → Inst Γ → InstΠ Γ
toΠ {Γ = []} tt ()
toΠ {Γ = τ ∷ Γ} (v , ρ) fzero = v
toΠ {Γ = τ ∷ Γ} (v , ρ) (fsuc i) = toΠ ρ i

fromΠ : ∀ {Γ} → InstΠ Γ → Inst Γ
fromΠ {Γ = []} ρ = tt
fromΠ {Γ = τ ∷ Γ} ρ = ρ fzero , fromΠ (λ i → ρ (fsuc i))

_ : fromΠ {Γ = nat ∷ []} (λ { fzero → 3 }) ≡ (3 , tt)
_ = refl

-- 两个小程序：类型全对，求值全通
demo₁ : TExp (nat ∷ bool ∷ []) bool
demo₁ = if iszero (var here) then var (there here) else bval false

-- x ≟ 0 真则取 bool 变量，假则 false：(0,true) → true；(5,…) → false
_ : eval demo₁ (0 , true , tt) ≡ true
_ = refl

_ : eval demo₁ (5 , true , tt) ≡ false
_ = refl

-- 手写 `true + 1`？换到良 typed 版它连**占位符都填不进**：
-- plus 只吃 TExp Γ nat，塞一个 bool 项进去，类型检查当场报
-- 「bool != nat of type Ty」（实录见文档 25.3）。

------------------------------------------------------------------------
-- 25.4 优化 pass：常量折叠——类型保形免费，语义等价要证
------------------------------------------------------------------------

-- 智能构造子（coq 教程同款设计）：折叠规则放进构造侧，optimize
-- 递归保持扁平——证明不用嵌套模式体操。
-- 为什么不折 e + 0 ↦ e？`_+_` 只按左参数化简（16 章坑位 4），
-- 它的正确性要请出 sym (+-identityʳ)（13 章债），case 分析还得
-- 翻倍——16.4 章的索引算术在这里继续收税。
optPlus : ∀ {Γ} → TExp Γ nat → TExp Γ nat → TExp Γ nat
optPlus (num m) (num n) = num (m + n)
optPlus (num zero) b = b
optPlus a b = plus a b

optIszero : ∀ {Γ} → TExp Γ nat → TExp Γ bool
optIszero (num zero) = bval true
optIszero (num (suc _)) = bval false
optIszero e = iszero e

optIf : ∀ {Γ τ} → TExp Γ bool → TExp Γ τ → TExp Γ τ → TExp Γ τ
optIf (bval true) a b = a
optIf (bval false) a b = b
optIf c a b = if c then a else b

optimize : ∀ {Γ τ} → TExp Γ τ → TExp Γ τ
optimize (var p) = var p
optimize (num n) = num n
optimize (bval b) = bval b
optimize (plus a b) = optPlus (optimize a) (optimize b)
optimize (iszero e) = optIszero (optimize e)
optimize (if c then a else b) = optIf (optimize c) (optimize a) (optimize b)

-- 折叠先算给你看（全 refl）：
e₁ : TExp [] nat
e₁ = plus (num 2) (num 3)

_ : optimize e₁ ≡ num 5
_ = refl

-- demo₁ 的条件 iszero (var here) 折不动（变量），但
-- 若换成 0 + x 就能折成 x：
demo₂ : TExp (nat ∷ []) bool
demo₂ = if iszero (plus (num zero) (var here))
        then bval true
        else bval false

_ : optimize demo₂ ≡ if iszero (var here) then bval true else bval false
_ = refl

_ : eval demo₂ (0 , tt) ≡ true
_ = refl

-- 智能构造子各自的正确性：注意「拆到多细」——optPlus 里 b 是变量时
-- 匹配不确定走哪个子句，归约卡住；必须把 b 拆成构造子形态
-- （var/plus/iszero/if），Agda 才肯化简。13 个子句全是 refl——
-- 体力活，但正是「定义计算」付的税。
optPlus-correct : ∀ {Γ} (a b : TExp Γ nat) (ρ : Inst Γ) →
                  eval (optPlus a b) ρ ≡ eval (plus a b) ρ
optPlus-correct (num m) (num n) ρ = refl
optPlus-correct (num zero) (var p) ρ = refl
optPlus-correct (num zero) (plus a b) ρ = refl
optPlus-correct (num zero) (if c then a else b) ρ = refl
optPlus-correct (num (suc m)) (var p) ρ = refl
optPlus-correct (num (suc m)) (plus a b) ρ = refl
optPlus-correct (num (suc m)) (if c then a else b) ρ = refl
optPlus-correct (var p) b ρ = refl
optPlus-correct (plus a b) b′ ρ = refl
optPlus-correct (if c then a else b) b′ ρ = refl

optIszero-correct : ∀ {Γ} (e : TExp Γ nat) (ρ : Inst Γ) →
                    eval (optIszero e) ρ ≡ eval (iszero e) ρ
optIszero-correct (num zero) ρ = refl
optIszero-correct (num (suc m)) ρ = refl
optIszero-correct (var p) ρ = refl
optIszero-correct (plus a b) ρ = refl
optIszero-correct (if c then a else b) ρ = refl

optIf-correct : ∀ {Γ τ} (c : TExp Γ bool) (a b : TExp Γ τ) (ρ : Inst Γ) →
                eval (optIf c a b) ρ ≡ eval (if c then a else b) ρ
optIf-correct (bval true) a b ρ = refl
optIf-correct (bval false) a b ρ = refl
optIf-correct (var p) a b ρ = refl
optIf-correct (iszero e) a b ρ = refl
optIf-correct (if c then c₁ else c₂) a b ρ = refl

-- 主定理：优化不改语义。**refl 不够用了**——折叠正确性是局部引理，
-- 钻到子项就得请出归纳假设 + cong/cong₂（13 章全套）。
-- 但注意：这仍是「前验」的——证一次，全体良类型输入通吃，
-- 不用测样例。
opt-eval : ∀ {Γ τ} (t : TExp Γ τ) (ρ : Inst Γ) →
           eval (optimize t) ρ ≡ eval t ρ
opt-eval (var p) ρ = refl
opt-eval (num n) ρ = refl
opt-eval (bval b) ρ = refl
opt-eval {τ = nat} (plus a b) ρ = begin
  eval (optPlus (optimize a) (optimize b)) ρ
 ≡⟨ optPlus-correct (optimize a) (optimize b) ρ ⟩
  eval (plus (optimize a) (optimize b)) ρ
 ≡⟨⟩
  eval (optimize a) ρ + eval (optimize b) ρ
 ≡⟨ cong₂ _+_ (opt-eval a ρ) (opt-eval b ρ) ⟩
  eval a ρ + eval b ρ
 ≡⟨⟩
  eval (plus a b) ρ
 ∎
opt-eval {τ = bool} (iszero e) ρ = begin
  eval (optIszero (optimize e)) ρ
 ≡⟨ optIszero-correct (optimize e) ρ ⟩
  eval (iszero (optimize e)) ρ
 ≡⟨⟩
  isz (eval (optimize e) ρ)
 ≡⟨ cong isz (opt-eval e ρ) ⟩
  isz (eval e ρ)
 ≡⟨⟩
  eval (iszero e) ρ
 ∎
opt-eval {τ = τ} (if c then a else b) ρ = begin
  eval (optIf (optimize c) (optimize a) (optimize b)) ρ
 ≡⟨ optIf-correct (optimize c) (optimize a) (optimize b) ρ ⟩
  eval (if optimize c then optimize a else optimize b) ρ
 ≡⟨⟩
  (λ v → Data.Bool.if_then_else_ v (eval (optimize a) ρ)
                     (eval (optimize b) ρ)) (eval (optimize c) ρ)
 ≡⟨ cong (λ v → Data.Bool.if_then_else_ v (eval (optimize a) ρ)
                      (eval (optimize b) ρ)) (opt-eval c ρ) ⟩
  (λ v → Data.Bool.if_then_else_ v (eval (optimize a) ρ)
                     (eval (optimize b) ρ)) (eval c ρ)
 ≡⟨ cong₂ (λ v w → Data.Bool.if_then_else_ (eval c ρ) v w)
         (opt-eval a ρ) (opt-eval b ρ) ⟩
  (λ v → Data.Bool.if_then_else_ v (eval a ρ) (eval b ρ)) (eval c ρ)
 ≡⟨⟩
  eval (if c then a else b) ρ
 ∎

-- 算账：
-- ① 免费：optimize 签名 TExp Γ τ → TExp Γ τ——折叠不可能把 nat 项
--    变 bool 项（类型保形由构造保证）；eval 永不失败；坏式子不可写。
-- ② 自证：eval (optimize t) ρ ≡ eval t ρ——语义等价没有免费的，
--    上面 30 行等式链就是账单。
-- 依赖类型吃的是**结构非法**的免费午餐，**语义等价**得自己付钱。
