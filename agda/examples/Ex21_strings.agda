------------------------------------------------------------------------
-- Ex21 · 文本处理
--
-- String/Char 原语层、Data.String/Data.Char 全家桶的实测行为、
-- 手写 parseNat(String → Maybe ℕ)与 Data.Nat.Show 的互转验证。
-- 所有等式都经 agda 2.8.0 类型检查(refl 即真值机)。
------------------------------------------------------------------------

module Ex21_strings where

-- 基础导入:字符串原语层经 Data.String.Base 改名后出售
open import Data.Bool.Base using (Bool; true; false; if_then_else_)
open import Data.Char.Base as C
  using (Char; isDigit; isAlpha; isSpace; isAscii; isHexDigit;
         toLower; toUpper; toℕ)
open import Data.List.Base as L using (List; []; _∷_; foldr)
open import Data.Maybe.Base as Maybe using (Maybe; just; nothing)
open import Data.Nat.Base using (ℕ; zero; suc; _+_; _*_; _∸_)
open import Data.Nat.Show using (show; showInBase; readMaybe)
open import Data.Product using (_,_; proj₁; proj₂; _×_)
open import Data.String.Base as S
  using (String; _++_; toList; fromList; length; words; lines;
         unwords; unlines; replicate; map; head; tail; uncons;
         fromChar; padLeft)
open import Data.String using () renaming (_≟_ to _≟S_; _==_ to _==S_)
open import Function.Base using (_∘′_; case_of_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Nullary.Decidable using (T?)

------------------------------------------------------------------------
-- §1 原语层的日常操作全部可算(refl 能关掉具体实例)

-- primStringAppend 在类型检查器里真的会化简:
app : ("a" S.++ "b") ≡ "ab"
app = refl

-- primStringToList / primStringFromList 同样可算,互逆在闭项上成立:
tl : toList "abc" ≡ 'a' ∷ 'b' ∷ 'c' ∷ []
tl = refl

rt : fromList (toList "abc") ≡ "abc"
rt = refl

-- length 是 toList 之后数构造子:
len : length "Hello, 世界" ≡ 9
len = refl

------------------------------------------------------------------------
-- §2 Data.String 全家:切分、复制、填充

-- words 折叠连续空白,lines 保留空行(stdlib 源码自带的实测例):
w : words " abc  b   " ≡ "abc" ∷ "b" ∷ []
w = refl

ln : lines "a\n\nb" ≡ "a" ∷ "" ∷ "b" ∷ []
ln = refl

-- 逆操作按自己的规则拼回去(注意尾换行的不对称!):
uw : unwords ("a" ∷ "b" ∷ []) ≡ "a b"
uw = refl

ul : unlines ("a" ∷ "b" ∷ []) ≡ "a\nb"
ul = refl

-- 往返只对"规范格式"成立:
roundtrip : unwords (words "  hello   world ") ≡ "hello world"
roundtrip = refl

-- 复制与填充:
rep : replicate 3 'a' ≡ "aaa"
rep = refl

pad : padLeft '0' 5 "42" ≡ "00042"
pad = refl

-- map 逐字符作用(内部 toList → List.map → fromList):
ml : map toLower "HeLLo" ≡ "hello"
ml = refl

-- 列表式访问器返回 Maybe/String,不是部分函数:
hd : head "abc" ≡ just 'a'
hd = refl

tl2 : tail "abc" ≡ just "bc"
tl2 = refl

uc : uncons "abc" ≡ just ('a' , "bc")
uc = refl

fc : fromChar '中' ≡ "中"
fc = refl

------------------------------------------------------------------------
-- §3 Data.Char:分类谓词是 Bool 原语,谓词逻辑靠 T? 桥接(15 章)

-- 具体判定全都能算:
d1 : isDigit '7' ≡ true
d1 = refl

d2 : isDigit 'x' ≡ false
d2 = refl

a1 : isAlpha 'x' ≡ true
a1 = refl

-- 中文字符:非 ASCII,但 toℕ 给码位,可参与比较与算术:
cn1 : isAscii '中' ≡ false
cn1 = refl

cn2 : toℕ '中' ≡ 20013
cn2 = refl

-- 单引号写的是"一个码位",哪怕它显示宽度为 2:
cn3 : length "中文" ≡ 2
cn3 = refl

------------------------------------------------------------------------
-- §4 实战:parseNat,String → Maybe ℕ(08 章 foldr + 15 章判定)

-- 单个数字字符 → 数值。isDigit 是 Bool 原语,T? 把它升格成 Dec,
-- 匹配 yes/no 时类型精化(06 章)才允许减 '0'。
digit : Char → Maybe ℕ
digit c with T? (isDigit c)
...       | yes _  = just (toℕ c ∸ toℕ '0')
...       | no  _  = nothing

-- 右折累加:代数值 v 配当前位权 p(1, 10, 100, …)。
-- 空表返回 nothing —— "空串不是合法数字"是刻意的设计决定。
digits : List Char → Maybe ℕ
digits []       = nothing
digits cs       = Maybe.map proj₁ (foldr step (just (0 , 1)) cs)
  where
  step : Char → Maybe (ℕ × ℕ) → Maybe (ℕ × ℕ)
  step c acc with digit c | acc
  ...          | just d   | just (v , p) = just (d * p + v , 10 * p)
  ...          | nothing  | _            = nothing
  ...          | _        | nothing      = nothing

parseNat : String → Maybe ℕ
parseNat s with toList s
...          | [] = nothing
...          | cs = digits cs

-- 行为实测:
pn1 : parseNat "12345" ≡ just 12345
pn1 = refl

pn2 : parseNat "" ≡ nothing
pn2 = refl

pn3 : parseNat "12a45" ≡ nothing
pn3 = refl

pn4 : parseNat "007" ≡ just 7
pn4 = refl

-- 组合使用:两个数字串求和
parseAdd : String → String → Maybe ℕ
parseAdd x y with parseNat x | parseNat y
...            | just m | just n = just (m + n)
...            | _      | _      = nothing

pa : parseAdd "21" "21" ≡ just 42
pa = refl

------------------------------------------------------------------------
-- §5 与 Data.Nat.Show 的往返:格式化/解析(20 章的老熟人)

-- show 没有 base 参数(十进制专用);带 base 的是 showInBase/readMaybe。
sh : show 42 ≡ "42"
sh = refl

shx : showInBase 16 255 ≡ "ff"
shx = refl

shb : showInBase 2 10 ≡ "1010"
shb = refl

-- readMaybe 的 base 是显式参数,隐式的是 True 证明(15 章),
-- 调用点看不见但 2 ≤ base ≤ 16 之外直接类型报错。
rd : readMaybe 10 "12345" ≡ just 12345
rd = refl

rdx : readMaybe 16 "ff" ≡ just 255
rdx = refl

rd0 : readMaybe 10 "" ≡ nothing
rd0 = refl

-- 往返律的具体实例:parseNat ∘ show ≡ just
-- 一般定律 ∀ n → parseNat (show n) ≡ just n 需要数码引理,见正文 §5;
-- 这里先把三个实例钉死。
rt0 : parseNat (show 0) ≡ just 0
rt0 = refl

rt42 : parseNat (show 42) ≡ just 42
rt42 = refl

rt12345 : parseNat (show 12345) ≡ just 12345
rt12345 = refl

------------------------------------------------------------------------
-- §6 字符串等式:_≟_ 给判定,_==_ 给 Bool

dec-yes : (("a" S.++ "b") ≟S "ab") ≡ yes refl
dec-yes = refl

-- 决策过程可以直接喂 if(case 拿 Bool 版更顺手):
b1 : ("42" ==S "42") ≡ true
b1 = refl

b2 : ("42" ==S "43") ≡ false
b2 = refl

-- 用 ≟S 做依赖分支:匹配 yes 时精化出 s ≡ "abc",函数体里可信可用
classify : (s : String) → Maybe String
classify s with s ≟S "abc"
...          | yes _  = just s
...          | no  _  = nothing

cl1 : classify "abc" ≡ just "abc"
cl1 = refl

cl2 : classify "xyz" ≡ nothing
cl2 = refl
