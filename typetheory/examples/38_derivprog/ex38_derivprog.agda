----------------------------------------------------------------
-- 38 程序推导（Nordström 书 ch.22）—— Agda 侧
-- 规则从下至上读 = 策略；从规格说明分裂子目标，程序由推导
-- 综合而出。旗舰件：Dijkstra 荷兰国旗问题全程（书 22.2）
----------------------------------------------------------------

open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (Σ; _,_; _×_; proj₁; proj₂; Σ-syntax)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- ① 问题设定（书 22.2）------------------------------------
data Colour : Set where
  red white blue : Colour

-- ---- ② 规格说明（书 22.2 的 Flag(l)）--------------------------
-- Flag(l) = ⟨l',l'',l'''⟩ ∈ Reds × Whites × Blues | l ≈p l'@l''@l'''
-- 教学件以「分桶正确」（all-of）实现桶约束；置换 ≈p（occin
-- 计数）是书 22.2 的引理 1–4，件末以命题占位（Perm 见 ⑦）：

data All (c : Colour) : List Colour → Set where
  all-[]  : All c []
  all-∷   : ∀ {x xs} → x ≡ c → All c xs → All c (x ∷ xs)

-- ⑦ 置换（书 ≈p 的占位）：这里取「逐元素成员关系」的弱化版
--    （教学件避免计数引理组；书 22.2 引理 1–4 补全 occin 版）
-- ≈p（书 22.2 的置换）：occin 计数定义的机器版要引理组 1–4；
-- 书里推导同样是「假设少许置换的基本性质、表述成引理」——
-- 件以 postulate 引理组忠实对应（完整 occin 版是进阶功课）：
postulate
  ≈p : List Colour → List Colour → Set
  ≈p-refl : (l : List Colour) → ≈p l l                  -- 引理 1：自反
  -- 三条「成品」引理（cons + 传递 + 插位 一体；书引理 3/4 的
  -- 组合形态——递归假设 xs≈r@w@b，新元素 c 按颜色进桶）：
  ≈p-head : {c : Colour} {xs r w b : List Colour}       -- c 进红桶（头）
        → ≈p xs (r ++ w ++ b) → ≈p (c ∷ xs) ((c ∷ r) ++ w ++ b)
  ≈p-mid  : {c : Colour} {xs r w b : List Colour}       -- c 进白桶（中）
        → ≈p xs (r ++ w ++ b) → ≈p (c ∷ xs) (r ++ (c ∷ w) ++ b)
  ≈p-end  : {c : Colour} {xs r w b : List Colour}       -- c 进蓝桶（尾）
        → ≈p xs (r ++ w ++ b) → ≈p (c ∷ xs) (r ++ w ++ (c ∷ b))

Flag : List Colour → Set
Flag l = Σ[ r ∈ List Colour ] Σ[ w ∈ List Colour ] Σ[ b ∈ List Colour ]
         (All red r × All white w × All blue b × ≈p l (r ++ w ++ b))

-- ---- ③ 推导：从规格说明分裂子目标（书 22.2 的推导树）----------
-- 目标 (Πl)Flag(l) 由 Π-引入策略 ⟹ [l ∈ List(A)] 下证 Flag(l)
-- 由 List-消去策略 ⟹ 奠基 Flag(nil) + 归纳 Flag(x::y)：
--   奠基：⟨nil,nil,nil⟩ + 引理 1（@ 单位元 + 置换自反）
--   归纳：假设 z ∈ Flag(y)，Colour-消去三分支把 x 挂进对应桶
flag : (l : List Colour) → Flag l
flag []       = [] , [] , [] , all-[] , all-[] , all-[] , ≈p-refl []
flag (c ∷ cs) with c | flag cs
... | red   | r , w , b , hr , hw , hb , hp = (red ∷ r)   , w , b , all-∷ refl hr , hw , hb , ≈p-head {red} {cs} {r} {w} {b} hp
... | white | r , w , b , hr , hw , hb , hp = r , (white ∷ w) , b , hr , all-∷ refl hw , hb , ≈p-mid {white} {cs} {r} {w} {b} hp
... | blue  | r , w , b , hr , hw , hb , hp = r , w , (blue ∷ b) , hr , hw , all-∷ refl hb , ≈p-end {blue} {cs} {r} {w} {b} hp

-- ---- ④ 程序提取：推导即程序（fst 投影剥掉证明分量）------------
flagOf : List Colour → List Colour × (List Colour × List Colour)
flagOf l with flag l
... | r , w , b , _ = r , w , b

_ : flagOf (white ∷ red ∷ blue ∷ []) ≡ ((red ∷ []) , (white ∷ []) , (blue ∷ []))
_ = refl                                    -- 荷兰国旗色序！Compute 见证

-- ---- ⑤ 策略的两张面孔（书 22.1.1）-----------------------------
-- 规则从下至上读=策略：&-引入 ↔ 合取引入、×-引入 ↔ 配对、
-- ×-消去 ↔ split（对 p 分解假设）、Π-引入 ↔ λ（引入前提）、
-- List-消去 ↔ 递归。导出策略=已证判断的另一读法（22.1.2）：
-- fst 的导出策略 ×-elim1：
×-elim1 : {A B : Set} (p : A × B) → proj₁ p ≡ proj₁ p
×-elim1 p = refl                            -- 判断 fst(p) ∈ A[p∈A×B]
                                            -- 的证明即策略（一行）

-- ---- ⑥ 书 22.1 的「目标-子目标」树形记法对照 ------------------
-- 「(Πl∈List)Flag(l) 由 Π-引入
--    [l ∈ List]
--    Flag(l) 由 List-消去
--      List 由假设 … 3 l
--      奠基 Flag(nil) 由引理 2 … ⟨nil,nil,nil⟩
--      [x∈A, y∈List, z∈Flag(y)]
--      归纳 Flag(x::y) 由 …」
-- ——Agda 的 with-模式匹配把同一棵树写成三段缩进（③ 的形状）。
