------------------------------------------------------------------------
-- 第 50 章配套示例：Huffman 编码与解码（原书第 8 章案例研究移植）
--
-- 全章一条主线：把「词表 → 频次 → Huffman 树 → 码表 → 比特串」这条
-- 编码流水线，和「码表 → 码树 → 逐位下行 → 词表」这条解码流水线，
-- 全部写成无副作用的纯函数；只在原书要求的地方做依赖类型验证
-- （队非空、合并频次进类型），最后用 refl 验收往返。
--
-- 移植说明（原书 Agda 2.6.3 + Iowa Agda Library + gratr → 本机 2.9.0 + stdlib 3.0）：
--  * gratr 是外部 OCaml 工具（原书第 6 章），其 SVN 源已失效 → 本章把
--    语法里的两类字面量（词表、比特串）改写成手写数据类型与解析函数；
--  * IO 那部分（原书 8.3.5 末尾的 io.agda）不移植：本机 agda --compile
--    需要 ghc，PATH 上没有（见 44 章），且往返验证不需要打印；
--  * braun-tree.agda 用 19 章已建好的 Braun 模块（Ex19_braun_lists.Braun），
--    本章只实例化、不重复它的证明；
--  * 原书 8.3.2 明说「可以把频次做成索引，但风险小所以没做」——本章把
--    这一步补上（HTree : ℕ → Set）。
--
-- 类型检查：cd agda && ./build.sh Ex50_huffman
--
-- 本文件的小节编号与 docs/50-huffman.md 的同编号小节一一对应（50.11、50.12
-- 是纯文字的收束与坑位清单，没有代码，故此处不出现）。
------------------------------------------------------------------------

{-# OPTIONS --safe #-}

module Ex50_huffman where

-- 50.1 进口清单
open import Data.Bool using (Bool; true; false; not; if_then_else_)
open import Data.Char using (Char)
open import Data.List using (List; []; _∷_; length; map; foldr; reverse)
  renaming (_++_ to _++ₗ_)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.Nat using (ℕ; zero; suc; _+_; _≡ᵇ_; _<ᵇ_)
import Data.Nat.Show as Nat
open import Data.Product using (Σ; _×_; _,_)
open import Data.String using (String; _==_; words; _++_; concat)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 50.2 词频表：把外部解析器的 words 规则换成 stdlib 的 Data.String.words
------------------------------------------------------------------------

-- 频次表：词 → 出现次数。原书用 trie 加速查找（8.3.1 图 8.3），
-- 这里用关联表——算法骨架一模一样，多写一个 trie 只会挤掉本章主线。
Freq : Set
Freq = List (String × ℕ)

bump-frequency : String → Freq → Freq
bump-frequency w [] = ( w , 1) ∷ []
bump-frequency w (( v , n) ∷ fs) with w == v
bump-frequency w (( v , n) ∷ fs) | true = ( v , suc n) ∷ fs
bump-frequency w (( v , n) ∷ fs) | false = ( v , n) ∷ bump-frequency w fs

compute-frequencies : List String → Freq
compute-frequencies = foldr bump-frequency []

-- 原书图 8.4 的两条引理：输入非空 ⟹ 频次表非空。
-- 它不是装饰——50.5 的 process-huffman-pq 要拿它喂荒谬模式。
-- 「非空」这里写成 Bool 值的谓词（原书的 n =N 0 ≡ ff），因为
-- 只有 Bool 版才能靠计算就归约成 refl。
NonEmpty : ℕ → Set
NonEmpty n = (n ≡ᵇ 0) ≡ false

bump-nonempty : ∀ (w : String) (fs : Freq) → NonEmpty (length (bump-frequency w fs))
bump-nonempty w [] = refl
bump-nonempty w (( v , n) ∷ fs) with w == v
bump-nonempty w (( v , n) ∷ fs) | true = refl
bump-nonempty w (( v , n) ∷ fs) | false = refl

compute-frequencies-nonempty :
  ∀ (w : String) (ws : List String) → NonEmpty (length (compute-frequencies (w ∷ ws)))
compute-frequencies-nonempty w ws = bump-nonempty w (compute-frequencies ws)

------------------------------------------------------------------------
-- 50.3 Huffman 树：原书「可以索引但没做」的那一步补上
------------------------------------------------------------------------

data HTree : ℕ → Set where
  leaf : (w : String) (f : ℕ) → HTree f
  node : ∀ {f₁ f₂} → HTree f₁ → HTree f₂ → HTree (f₁ + f₂)

-- 队列里放的元素：「某个频次 + 该频次下的树」。Σ 把频次藏进类型，
-- 比较函数才拿得到它。
Tree : Set
Tree = Σ ℕ HTree

pattern _ᵀ_ f t = ( f , t )

mk-leaf : String → ℕ → Tree
mk-leaf w f = f , leaf w f

merge : Tree → Tree → Tree
merge (f₁ ᵀ t₁) (f₂ ᵀ t₂) = f₁ + f₂ , node t₁ t₂

ht-compare : Tree → Tree → Bool
ht-compare (f₁ ᵀ _) (f₂ ᵀ _) = f₁ <ᵇ f₂

------------------------------------------------------------------------
-- 50.4 优先队列：19 章的 Braun 模块，实例化到 Tree
------------------------------------------------------------------------

import Ex19_braun_lists as Ex19
open Ex19.Braun Tree ht-compare

PQ : ℕ → Set
PQ = braun

pq-insert : ∀ {n} → Tree → PQ n → PQ (suc n)
pq-insert = insert

pq-remove-min : ∀ {p} → PQ (suc p) → Tree × PQ p
pq-remove-min = remove-min

build-huffman-pq : (fs : Freq) → PQ (length fs)
build-huffman-pq [] = empty
build-huffman-pq (( w , f) ∷ fs) = pq-insert (mk-leaf w f) (build-huffman-pq fs)

------------------------------------------------------------------------
-- 50.5 折叠队列：把 n 棵树压成 1 棵，非空证明在这里变成荒谬模式
------------------------------------------------------------------------

process-huffman-pq : ∀ {n} → NonEmpty n → PQ n → Tree
process-huffman-pq {zero} () _
process-huffman-pq {suc zero} _ t with pq-remove-min t
... | h , _ = h
process-huffman-pq {suc (suc n)} _ t with pq-remove-min t
... | h , t′ with pq-remove-min t′
process-huffman-pq {suc (suc n)} _ _ | h , t′ | h′ , t″ =
  process-huffman-pq {suc n} refl (pq-insert (merge h h′) t″)

-- 顶层：调用者只需证明「词表非空」；频次表非空由上面那条引理在内部转换。
huffman-tree : (ws : List String) → NonEmpty (length ws) → Tree
huffman-tree [] ()
huffman-tree (w ∷ ws) _ =
  process-huffman-pq (compute-frequencies-nonempty w ws)
    (build-huffman-pq (compute-frequencies (w ∷ ws)))

------------------------------------------------------------------------
-- 50.6 码表：把树上的路径读成「词 → 码」
------------------------------------------------------------------------

data Bit : Set where
  b0 b1 : Bit

Code : Set
Code = List Bit

Mapping : Set
Mapping = List (String × Code)

-- 下行时把当前位记在最前，所以手里拿的是反路径，到叶子再 reverse
-- （19 章的 reverse 在这里第二次上岗）。左子记 0、右子记 1。
build-mapping-h : ∀ {f} → Code → HTree f → Mapping → Mapping
build-mapping-h p (leaf w _) m = ( w , reverse p ) ∷ m
build-mapping-h p (node l r) m =
  build-mapping-h (b1 ∷ p) r (build-mapping-h (b0 ∷ p) l m)

build-mapping : Tree → Mapping
build-mapping ( _ , t ) = build-mapping-h [] t []

-- 查码：关联表上的线性查找。查不到返回 nothing——原书 8.3.5 坦白
-- 「没证明码表覆盖所有输入词，所以必须处理查不到的情形」，它用字符串
-- "error" 兜底；本章把失败放进 Maybe，让调用方无法假装没看见。
lookup-code : String → Mapping → Maybe Code
lookup-code w [] = nothing
lookup-code w (( v , c) ∷ m) with w == v
lookup-code w (( v , c) ∷ m) | true = just c
lookup-code w (( v , c) ∷ m) | false = lookup-code w m

encode-h : Mapping → List String → Maybe Code
encode-h m [] = just []
encode-h m (w ∷ ws) with lookup-code w m | encode-h m ws
encode-h m (w ∷ ws) | just c | just cs = just (c ++ₗ cs)
encode-h m (w ∷ ws) | _ | _ = nothing

encode : Mapping → String → Maybe Code
encode m s = encode-h m (words s)

------------------------------------------------------------------------
-- 50.7 码树：解码用的前缀树
------------------------------------------------------------------------

data CTree : Set where
  cempty : CTree
  cleaf : String → CTree
  cnode : CTree → CTree → CTree

flip-bit : Bit → Bit
flip-bit b0 = b1
flip-bit b1 = b0

sub-ct : Bit → CTree → CTree
sub-ct b cempty = cempty
sub-ct b (cleaf _) = cempty
sub-ct b0 (cnode l _) = l
sub-ct b1 (cnode _ r) = r

ct-node-bit : Bit → CTree → CTree → CTree
ct-node-bit b0 l r = cnode l r
ct-node-bit b1 l r = cnode r l

-- 插入一条码：沿 b 那一侧下行去放叶子，另一侧整段从旧树搬过来。
ct-insert : CTree → String → Code → CTree
ct-insert t w [] = cleaf w
ct-insert t w (b ∷ bs) =
  ct-node-bit b (ct-insert (sub-ct b t) w bs) (sub-ct (flip-bit b) t)

make-code-tree : Mapping → CTree
make-code-tree [] = cempty
make-code-tree (( w , c) ∷ m) = ct-insert (make-code-tree m) w c

-- 非空比特串：末位单独一个构造子，于是「最后一位必须落在叶子上」在
-- 模式匹配里看得见（原书的 bvlit 用两个构造子干同一件事）。
data Bitvec : Set where
  alone : (b : Bit) → Bitvec
  _⊙_ : (b : Bit) → (v : Bitvec) → Bitvec

to-bitvec : (b : Bit) (bs : List Bit) → Bitvec
to-bitvec b [] = alone b
to-bitvec b (c ∷ cs) = b ⊙ to-bitvec c cs

emit : String → Maybe (List String) → Maybe (List String)
emit w (just ws) = just ( w ∷ ws)
emit w nothing = nothing

decode-h : CTree → CTree → Bitvec → Maybe (List String)
decode-h orig cur (alone b) with sub-ct b cur
decode-h orig cur (alone b) | cleaf w = just ( w ∷ [])
decode-h orig cur (alone b) | _ = nothing
decode-h orig cur (b ⊙ v) with sub-ct b cur
decode-h orig cur (b ⊙ v) | cleaf w = emit w (decode-h orig orig v)
decode-h orig cur (b ⊙ v) | cnode l r = decode-h orig (cnode l r) v
decode-h orig cur (b ⊙ v) | cempty = nothing

decode : CTree → Code → Maybe (List String)
decode _ [] = just []
decode t (b ∷ bs) = decode-h t t (to-bitvec b bs)

------------------------------------------------------------------------
-- 50.8 手写解析：顶掉外部解析器生成器的两条字面量规则
------------------------------------------------------------------------

parse-bit : Char → Maybe Bit
parse-bit '0' = just b0
parse-bit '1' = just b1
parse-bit _ = nothing

parse-bits-h : List Char → Maybe Code
parse-bits-h [] = just []
parse-bits-h (c ∷ cs) with parse-bit c | parse-bits-h cs
parse-bits-h (c ∷ cs) | just b | just bs = just ( b ∷ bs)
parse-bits-h (c ∷ cs) | _ | _ = nothing

parse-bits : String → Maybe Code
parse-bits s = parse-bits-h (Data.String.toList s)

-- 下游（50.10 的 bits 速记）全靠这个函数，所以先把「逐位翻译」本身钉成 refl。
parse-bits-ok : parse-bits "0101" ≡ just (b0 ∷ b1 ∷ b0 ∷ b1 ∷ [])
parse-bits-ok = refl

parse-bits-bad : parse-bits "0x1" ≡ nothing
parse-bits-bad = refl

------------------------------------------------------------------------
-- 50.9 无 IO 的打印：把结果渲染成 String，等式由 refl 验收
------------------------------------------------------------------------

show-bit : Bit → String
show-bit b0 = "0"
show-bit b1 = "1"

show-code : Code → String
show-code cs = concat (map show-bit cs)

show-freq : Freq → String
show-freq [] = ""
show-freq (( w , f) ∷ fs) = w ++ " ↦ " ++ Nat.show f ++ "; " ++ show-freq fs

show-words : List String → String
show-words ws = concat (map (λ w → w ++ " ") ws)

show-mapping : Mapping → String
show-mapping [] = ""
show-mapping (( w , c) ∷ m) = w ++ " ↦ " ++ show-code c ++ "; " ++ show-mapping m

------------------------------------------------------------------------
-- 50.10 整条流水线跑在样例文本上：每一步都是编译期的 refl 检查
------------------------------------------------------------------------

-- 测试写作用：把比特表写成字符串字面量。非法输入返回空表——本章只用它喂
-- 自己写死的合法串，逐位翻译本身由 50.8 的 parse-bits-ok 钉住。
bits : String → Code
bits s with parse-bits s
... | just bs = bs
... | nothing = []

text : String
text = "hi hi bye hello hi hi bye hello hi hi bye hello"

freqs : Freq
freqs = compute-frequencies (words text)

freqs-is : freqs ≡ ( "hello" , 3) ∷ ( "bye" , 3) ∷ ( "hi" , 6) ∷ []
freqs-is = refl

freqs-printed : show-freq freqs ≡ "hello ↦ 3; bye ↦ 3; hi ↦ 6; "
freqs-printed = refl

tree : Tree
tree = huffman-tree (words text) refl

tree-is : tree ≡ ( 12 , node (leaf "hi" 6) (node (leaf "bye" 3) (leaf "hello" 3)))
tree-is = refl

mapping : Mapping
mapping = build-mapping tree

mapping-is :
  mapping ≡ ( "hello" , bits "11") ∷ ( "bye" , bits "10") ∷ ( "hi" , bits "0") ∷ []
mapping-is = refl

mapping-printed : show-mapping mapping ≡ "hello ↦ 11; bye ↦ 10; hi ↦ 0; "
mapping-printed = refl

encoded : Maybe Code
encoded = encode mapping text

encoded-is : encoded ≡ just (bits "001011001011001011")
encoded-is = refl

decoded : Maybe (List String)
decoded with encoded
... | nothing = nothing
... | just bs = decode (make-code-tree mapping) bs

round-trip : decoded ≡ just (words text)
round-trip = refl

decoded-printed : String
decoded-printed with decoded
... | just ws = show-words ws
... | nothing = "解码失败"

decoded-printed-is :
  decoded-printed ≡ "hi hi bye hello hi hi bye hello hi hi bye hello "
decoded-printed-is = refl

-- 三条边界：截断的串、查不到的词、码表只有一个词。
truncated : decode (make-code-tree mapping) (bits "00101100101100101") ≡ nothing
truncated = refl

encode-miss : encode mapping "hi zzz" ≡ nothing
encode-miss = refl

single-tree : Tree
single-tree = huffman-tree (words "hi hi hi") refl

single-decode : decode (make-code-tree (build-mapping single-tree)) (bits "0") ≡ nothing
single-decode = refl

-- 空文本不进入 Huffman（频次表会空，码也建不出来）；decode 只负责「无位可走」
-- 这一侧：返回空词表。
empty-input : decode (make-code-tree mapping) [] ≡ just []
empty-input = refl

-- 原书开头那串 001110001110001110：用我们算出的码树去解，得到的是另一段文本。
-- 码不唯一（tie-break 不同 → 树不同），跨码树解别人的串不会报错，只会串位。
book-decoded : Maybe (List String)
book-decoded = decode (make-code-tree mapping) (bits "001110001110001110")

book-decoded-is :
  book-decoded ≡ just (words "hi hi hello bye hi hi hello bye hi hi hello bye")
book-decoded-is = refl


