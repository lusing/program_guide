# 21 · 文本处理

从这一章开始进入 19–24 的工程专题。前两章（19 monad、20 IO）解决了"怎么
把计算组合起来、怎么落地成真实程序"，本章解决落地之后马上要撞上的问题：
**程序怎么和文本打交道**。读一行 stdin 进来是 `String`，要转成 `ℕ` 就得
解析；输出一个数得 `show`；切单词、按行拆分——这些在 Haskell/Python 里
一行搞定的事，在 Agda 里要过三道关卡：其一，`String` 是**原语类型**，不是
`List Char`，不能模式匹配内部结构；其二，字符串等式不能靠 `refl` 判定，
要走 `_≟_` 决策过程；其三，stdlib 和 Haskell 同名模块**行为有出入**（比如
`unlines` 不加尾换行），照 Haskell 直觉写会翻车。本章把三关全部趟平。

对应示例：`../examples/Ex21_strings.agda`

本章代码片段与示例文件一致（个别报错探针以文字标注）；所有 `refl` 等式
都经 Agda 2.8.0 + stdlib 2.3 类型检查通过——refl 能关掉就等于"类型检查器
实测算出了两边相同"，即本教程反复利用的**真值机技巧**（03 章引入）。

## 21.1 原语层：String/Char 是 postulate 来的黑盒子

Agda 的 `String` 定义在编译器的内置前置库（prelude）里，本机
`/usr/share/libghc-agda-dev/lib/prim/Agda/Builtin/String.agda`，全文
值得完整看一眼：

```agda
postulate String : Set
{-# BUILTIN STRING String #-}

primitive
  primStringUncons   : String → Maybe (Σ Char (λ _ → String))
  primStringToList   : String → List Char
  primStringFromList : List Char → String
  primStringAppend   : String → String → String
  primStringEquality : String → String → Bool
  primShowChar       : Char → String
  primShowString     : String → String
  primShowNat        : Nat → String
```

三个要点：

1. **`String` 没有构造子**。它和 `ℕ`（`zero`/`suc`）、`Bool`
   （`true`/`false`）不一样，是 `postulate` 出来的原子类型，8 个
   `primitive` 是外界（GHC/JS 运行时）伸进来的可信函数。你不能对一个
   `String` 做 `case s of [] → …; c ∷ cs → …` 式的解构——它没有这个形状。
2. **和 Haskell 的本质区别**：Haskell 里 `type String = [Char]`，字符串
   就是懒链表，`head`/模式匹配都是链表操作，代价是每字符一个 cons 单元。
   Agda 反过来：`String` 是不透明的紧凑表示，**进出链表必须显式走
   `toList`/`fromList`**——而这两个函数在类型检查器里对字面量真的会计算
   （见下面的 refl 实测），"转链表再处理"没有证明层的额外成本。
3. **primitive 在类型检查器里可算**。`primStringAppend`/`primStringToList`
   等对**字面量**参与归约，所以开串小操作全部 `refl` 可关。示例 §1
   钉的就是这三件事：

```agda
open import Data.String.Base as S
  using (String; _++_; toList; fromList; length; …)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

app : ("a" S.++ "b") ≡ "ab"; app = refl  -- primStringAppend 真的会化简
tl : toList "abc" ≡ 'a' ∷ 'b' ∷ 'c' ∷ []; tl = refl  -- primStringToList 可算
rt : fromList (toList "abc") ≡ "abc"; rt = refl  -- 互逆在闭项上成立
```

注意 `_++_` 上挂着 `S.` 限定名：示例从 `Data.String.Base` 只导入要的名字并用
`as S` 留限定前缀，避免和 `Data.List` 的 `_++_`（08 章老朋友）撞名。
`Data.String.Base` 里 `_++_` 就是 `primStringAppend` 的别名，源码注释特意
说明"不直接重新导出 primitive"是为了自己控制记号与优先级。

`Char` 同理（`Agda/Builtin/Char.agda`）：`postulate Char : Set`，配
`primIsDigit`/`primToLower`/`primCharToNat` 等原语——**全部返回 `Bool`，
不返回命题**，这决定了 21.3 的用法。还有一条实测好消息：**字符串字面量
可以出现在模式里**——探针 `f "abc" = 1; f _ = 0` 实测通过（编译器经
`primStringEquality` 生成判定），能"整串匹配"，但仍然不能"拆开"：没有
按字符/前缀解构的模式。

## 21.2 Data.String 全家：切分、复制、填充、访问

`Data.String.Base`（经 `Data.String` 公开再导出）的 API 形状上和
Haskell 几乎逐字对应，但**每个函数的行为都要单独确认**——示例 §2 用
refl 把关键行为钉了一遍：

```agda
-- words 折叠连续空白,lines 保留空行(stdlib 源码自带的实测例):
w  : words " abc  b   " ≡ "abc" ∷ "b" ∷ []; w = refl
ln : lines "a\n\nb" ≡ "a" ∷ "" ∷ "b" ∷ []; ln = refl
```

- `words` 按空白切 token：连续空白折叠成一个分隔符、首尾空白丢弃，切出来
  **没有**空串元素；
- `lines` 按 `\n` 硬切：中间空行保留为 `""`。两者"宽容度"不对称是刻意
  的：一个面向 token 化，一个面向逐行处理。

逆操作 `unwords`/`unlines` 是"用连接符 join"，**不是**严格双逆：

```agda
uw : unwords ("a" ∷ "b" ∷ []) ≡ "a b"; uw = refl
ul : unlines ("a" ∷ "b" ∷ []) ≡ "a\nb"; ul = refl
```

敲黑板：`unlines ["a","b"]` 的结果**结尾没有换行**——探针实测写
`≡ "a\nb\n"` 会报 `"a\nb" != "a\nb\n" of type String`。这**和 Haskell
相反**：Haskell 的 `unlines` 给每一行都补 `\n`，Agda 选的是
`intercalate` 式 join 语义。于是 `lines`/`unlines` 的往返只对"不以换行
结尾的串"是恒等；写行协议/文件时尾换行必须自己决定（20 章
`readFiniteFile` 不剥换行的坑在这里会再咬一次）。同理，`words`/`unwords`
的往返只在"规范格式"（单词间恰好一个空格、首尾无空白）上成立：

```agda
-- 往返只对"规范格式"成立:
roundtrip : unwords (words "  hello   world ") ≡ "hello world"; roundtrip = refl
```

原始空白信息在 `words` 一步就被蒸发了：做格式转换是_feature_，做还原是坑。

§2 其余成员都是可算的普通函数，示例逐条 refl：

```agda
rep : replicate 3 'a' ≡ "aaa"; rep = refl
pad : padLeft '0' 5 "42" ≡ "00042"; pad = refl

-- map 逐字符作用(内部 toList → List.map → fromList):
ml : map toLower "HeLLo" ≡ "hello"; ml = refl
-- 列表式访问器返回 Maybe/String,不是部分函数:
hd  : head "abc"    ≡ just 'a'; hd  = refl
tl2 : tail "abc"    ≡ just "bc"; tl2 = refl
uc  : uncons "abc" ≡ just ('a' , "bc"); uc  = refl
fc  : fromChar '中' ≡ "中";      fc  = refl
```

`replicate`/`padLeft` 对应 Haskell 的 `replicate`/`pad` 家族
（`padLeft c n s` 把 `s` 左侧补 `c` 到宽 `n`，排版报表好用）。`head`/
`tail`/`uncons` 都返回 `Maybe`——Agda 没有部分函数，空串情形给
`nothing`，编译器**强制**你在类型层面交代它，比 Haskell `head []` 的
运行时异常诚实。`uncons` 返回 `Maybe (Char × String)` 一次拿头+尾，是
手写递归处理的正规入口；`fromChar` 是单字符构造器。

## 21.3 Data.Char：Bool 谓词 + T? 桥接

`Data.Char.Base` 出售的分类谓词全部是原语薄皮，返回 `Bool`：
`isDigit`/`isAlpha`/`isSpace`/`isAscii`/`isHexDigit`/`toLower`/`toUpper`/
`toℕ`（示例 import 的就是这一串）。具体判定全可算：

```agda
d1 : isDigit '7' ≡ true; d1 = refl
d2 : isDigit 'x' ≡ false; d2 = refl
a1 : isAlpha 'x' ≡ true; a1 = refl
```

要在**证明/依赖分支**里用它们，先过 15 章的桥：
`T? : (b : Bool) → Dec ⌊ b ⌋` 把 `Bool` 升格成 `Dec`，匹配 `yes`/`no`
时类型精化（06 章）才把信息带进分支——这正是 21.4 解析器的骨架。

Unicode 三件事（示例 §3 实测）：

```agda
-- 中文字符:非 ASCII,但 toℕ 给码位,可参与比较与算术:
cn1 : isAscii '中' ≡ false; cn1 = refl
cn2 : toℕ '中' ≡ 20013; cn2 = refl
-- 单引号写的是"一个码位",哪怕它显示宽度为 2:
cn3 : length "中文" ≡ 2; cn3 = refl
```

`Char` 就是一个 Unicode 码位（scalar），`toℕ` 给码点（`'中'` = 20013
恰在 CJK 区），因此字符可以做算术、可排序，`Data.Char` 的
`_≟_`/`_<?_` 都建在这上面。`length "中文" ≡ 2` 同时说明 `String` 按
**码位**计数：既不是 UTF-8 字节数（"中文" 6 字节），也不是显示宽度/
字素簇（`"e"` 加组合符会算 2）。§1 的 `length "Hello, 世界" ≡ 9`
（7 个 ASCII + 2 汉字）钉的是同一条规则。

## 21.4 实战：parseNat，String → Maybe ℕ

20 章坑位第 7 条说过：stdlib 2.3 **没有**现成的 `String → ℕ`，当时留了
手写作业，现在交卷。设计决策先摆出来：字符级判定用 `isDigit`（Bool）→
`T?` 升 `Dec`；串级处理先 `toList` 转链表再 `foldr`（08 章）；失败语义
用 `Maybe`（12 章），不携带原因，够用且好组合。

第一段，单字符转数值：

```agda
-- 单个数字字符 → 数值。isDigit 是 Bool 原语,T? 把它升格成 Dec,
-- 匹配 yes/no 时类型精化(06 章)才允许减 '0'。
digit : Char → Maybe ℕ
digit c with T? (isDigit c)
...       | yes _  = just (toℕ c ∸ toℕ '0')
...       | no  _  = nothing
```

`toℕ c ∸ toℕ '0'` 即"码点减 48"（截断减 `∸`，07 章）。这里敢用 `∸` 不
配 `48 ≤ toℕ c` 的引理，是因为结果本来就要落回 `ℕ`：只在 `yes` 分支
调用，语义上触不到截断。

第二段：右折累加。十进制解析的难点是**权值**：最右一位乘 1、往左依次乘
10。`foldr` 从右往左吃，天然适合"带着当前权值走"的累加器形状；Agda
终止检查要求全函数结构递归，所以累加器形状一次定对：

```agda
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
```

读法：累加器 `Maybe (ℕ × ℕ)`——`nothing` 表示"已见过坏字符，整体短路"；
`just (v , p)` 表示"低位合计 `v`，当前位权 `p`"。初值 `(0 , 1)`；每吃
一个数字字符 `d`：`v' = d * p + v`、`p' = 10 * p`。折完取 `proj₁`。
三个 `with` 分支覆盖"当前字符坏"与"下方已坏"两种失败，模式是 06 章的
多重匹配。顶层把工序串起来，并在两个层次都堵住空串（防御性冗余）：

```agda
parseNat : String → Maybe ℕ
parseNat s with toList s
...          | [] = nothing
...          | cs = digits cs
```

行为实测（示例 §4 四条 refl）：

```agda
pn1 : parseNat "12345" ≡ just 12345; pn1 = refl
pn2 : parseNat ""      ≡ nothing; pn2 = refl
pn3 : parseNat "12a45" ≡ nothing; pn3 = refl
pn4 : parseNat "007"   ≡ just 7; pn4 = refl
```

"007" → `just 7`：前导零被权值算术自然吸收；要严格格式（禁前导零、禁
空白）再叠一层谓词过滤。组合子一枚，`with` 双判定：

```agda
-- 组合使用:两个数字串求和
parseAdd : String → String → Maybe ℕ
parseAdd x y with parseNat x | parseNat y
...            | just m | just n = just (m + n)
...            | _      | _      = nothing
pa : parseAdd "21" "21" ≡ just 42; pa = refl
```

这就是 20 章 `main` 里读文件后 `parseNat` 的完整版：有规格、有实例证明。

## 21.5 Data.Nat.Show：格式化与官方解析器，往返律

`Data.Nat.Show`（20 章已露面的 `show`）给出官方"数 → 文本"，外加带基数
的 `showInBase` 和官方"文本 → 数" `readMaybe`。示例 §5 实测：

```agda
-- show 没有 base 参数(十进制专用);带 base 的是 showInBase/readMaybe。
sh  : show 42 ≡ "42"; sh  = refl
shx : showInBase 16 255 ≡ "ff"; shx = refl
shb : showInBase 2 10 ≡ "1010"; shb = refl
```

`readMaybe` 的签名是本章第一个"类型级把戏"现场——stdlib 源码
（`Data/Nat/Show.agda`）：

```agda
readMaybe : ∀ base {base≤16 : True (base ≤? 16)} → String → Maybe ℕ
```

`base` 是显式参数，`base≤16` 是**隐式的 `True` 证明**（15 章
`True : Dec A → Set`：`True (yes p) = ⊤`，`True (no ¬p) = ⊥`）。调用点
看不见它；越界会卡住——但卡的方式值得实测清楚，这里藏着三个坑
（对应 21.8 清单第 6 条）：

1. **上界违反**报的是 `UnsolvedMetaVariables`（探针
   `p : Maybe ℕ; p = readMaybe 17 "11"` 报
   `Unsolved metas at the following locations: …:7.5-17`），不是直观的
   "base 太大"；
2. **这个报错会被同文件更早的错误吞掉**：探针把 `readMaybe 17` 混在一条
   失败等式之后时，只见 `UnequalTerms`、unsolved-meta 根本没机会跑。
   **别用"没报错"证明"没问题"**；
3. **下界 `2 ≤ base` 在 `readMaybe` 上根本不存在**！只有 `showInBase`
   带双约束 `{base≥2}{base≤16}`。低基数**静默通过**并算出怪结果（探针
   三条全部 refl 成立）：`readMaybe 1 "1" ≡ nothing`、
   `readMaybe 1 "0" ≡ just 0`、`readMaybe 0 "0" ≡ nothing`。语义上
   "数字必须 < base"自洽，但这说明**类型约束只挡它声明要挡的东西**，
   写校验类 API 别把"没报错"当"被检查过"。

官方解析器与手写 `parseNat` 的行为对照：`readMaybe 10 "12345" ≡
just 12345`、`readMaybe 16 "ff" ≡ just 255`、`readMaybe 10 "" ≡
nothing` 全部 refl 通过（示例 §5）。`readMaybe 10 "007"` 与手写版同款
给 `just 7`；它也不接受 `+`/`-`/空白。

最后是往返律。方向一 `parseNat ∘ show`：一般定律
`∀ n → parseNat (show n) ≡ just n` 需要"十进制数码表（`Data.Digit` 的
`toNatDigits 10`）与 `digit`/权值算术咬合"的一串引理——证法本身是
13 章归纳 + 14 章推理框架的好题目；示例先钉三个实例：

```agda
rt0     : parseNat (show 0)     ≡ just 0; rt0 = refl
rt42    : parseNat (show 42)    ≡ just 42; rt42 = refl
rt12345 : parseNat (show 12345) ≡ just 12345; rt12345 = refl
```

闭项上的 refl 已把"两边计算到同一个值"验证过；推广成 ∀ 是对 `n` 按
`show` 的实现结构归纳，核心引理是 `show` 不产前导零。方向二
`show ∘ readMaybe` 在 `just n` 时同样恒等，但输入串须"规范"——"007"
解析成 7 再 show 是 "7"，**文本→数→文本不恢复原文**：所有"解析即规范
化"管道的共同宿命，`words`/`unwords` 段已见过一次。

## 21.6 字符串等式：refl 判不了，走 _≟_

`≡`（11 章）只有 `refl` 一个构造子：要证 `x ≡ y`，两边必须在类型检查器
的可见计算下合流。对闭串没问题——原语会算，`app`/`tl`/`rt` 是证据。但
对**开串**（含变量）不行：`s : String` 时 `s ≡ "abc"` 没有可归纳的结构
（String 是黑盒、无构造子，让你对 s 做 case 都做不到），`refl` 两手
空空。这时要走 15 章的判定性，`Data.String` 出售：

```agda
_≟_  : DecidableEquality String     -- (x y : String) → Dec (x ≡ y)
_==_ : String → String → Bool
```

`_≟_` 不是糊弄的 postulate：`Data.String.Properties` 里
`x ≟ y = map′ ≈⇒≡ ≈-reflexive $ x ≈? y`，`≈?` 是对 `toList` 后的逐字符
`Char._≟_` 决策，`yes` 分支携带真正的 `x ≡ y` 证明。所以闭项上连证明
对象本身都算到 `refl`，示例 §6 钉得住：

```agda
dec-yes : (("a" S.++ "b") ≟S "ab") ≡ yes refl
dec-yes = refl
```

（示例把 `Data.String` 的 `_≟_`/`_==_` 改名 `_≟S_`/`_==S_` 导入，避免
和 15 章熟面孔 `Data.Nat` 的 `_≟_` 撞名。）Bool 版喂 `if_then_else_`：

```agda
b1 : ("42" ==S "42") ≡ true; b1 = refl
b2 : ("42" ==S "43") ≡ false; b2 = refl
```

但真正的主战场是依赖分支：`with s ≟S "abc"` 之后，`yes` 分支里精化出
`≡` 证明可用：

```agda
-- 用 ≟S 做依赖分支:匹配 yes 时精化出 s ≡ "abc",函数体里可信可用
classify : (s : String) → Maybe String
classify s with s ≟S "abc"
...          | yes _  = just s
...          | no  _  = nothing
cl1 : classify "abc" ≡ just "abc"; cl1 = refl
cl2 : classify "xyz" ≡ nothing; cl2 = refl
```

心法一句话：**要值用 `==`（Bool），要证明用 `≟`（Dec），两者都要在
依赖类型里汇合时经 `T?` 桥**。细节一枚：`_==_` 并非 `primStringEquality`
直穿，stdlib 定义为 `s₁ == s₂ = isYes (s₁ ≟ s₂)`，源码注释解释：经
`_≟_` 的定义"有时能改善类型推断"（文件里附了 private 单元测试，换成
原语就过不了）。

## 21.7 和 Haskell 的速查对照

| 操作 | Haskell | Agda（stdlib 2.3 实测） |
|---|---|---|
| 类型本质 | `String = [Char]`（懒链表） | `postulate String`，黑盒原语 |
| 转链表 | 不需要 | `toList`/`fromList`（闭项上可算、互逆） |
| 结构解构 | `c ∷ cs` 模式 | 不行；整串字面量匹配可以，拆分走 `uncons` |
| `unlines` | 每行都补 `\n` | join 式，**不**补尾换行 |
| `words` | 折叠空白（同） | 折叠空白（同），`isSpace` 为 ASCII 谓词 |
| 字符谓词 | `isDigit :: Char -> Bool` | 同款 Bool + `T?` 升格才有命题 |
| 数→文本 | `show`/`showHex`（Typeclass） | `show`/`showInBase`（无类，单类型） |
| 文本→数 | `read`（运行时炸）/`readMaybe` | `readMaybe`（base 有上界约束、无下界约束） |
| 等式判定 | 随便 `==` | 证明层走 `_≟_`，`refl` 只吃可判定的 |

## 21.8 坑位清单（本章实测）

1. **`_≟_`/`_==_` 不在 `Data.String.Base` 里**：从 Base `using (_≟_)`
   导入，实测先吃警告 `The module Data.String.Base doesn't export the
   following: _≟_`，用到时再 `NotInScope`。判定等式住在 `Data.String`
   （再导出自 `Data.String.Properties`）——Base/API 拆分（27 章主题）在
   字符串上也咬人。
2. **`unlines` 不加尾换行，和 Haskell 直觉相反**：
   `unlines ("a" ∷ "b" ∷ []) ≡ "a\nb"` 成立，写成 `≡ "a\nb\n"` 实测报
   `"a\nb" != "a\nb\n" of type String`。行协议要尾换行得自己 `++ "\n"`。
3. **`words`/`unwords`、`lines`/`unlines` 都不是双逆**：往返只对规范格式
   成立（`roundtrip` 的 refl 恰好演示"非规范进、规范出"）；拿它做
   "原文保持"处理会悄悄丢信息。
4. **`length` 按码位不按字节/字素**：`length "中文" ≡ 2`；含组合附加符的
   串一个"肉眼字符"算多个。按显示宽度对齐要自己写宽度函数。
5. **开串的等式 refl 关不掉**：`s : String` 时你对 `s` 没有任何 case
   分析能力（无构造子），等式分支只能 `_≟_`/`T?` 桥接——这是 String 为
   原语的结构性代价，不是 stdlib 偷懒。
6. **`readMaybe` 的 base 只有上界约束**（`True (base ≤? 16)`），
   `readMaybe 1 "0" ≡ just 0` 实测**静默通过**；下界只存在于
   `showInBase`。上界违反报 `UnsolvedMetaVariables` 而非优雅报错，且
   **同文件更早的类型错误会把它吞掉**——排错别被报错顺序骗了。
7. **20 章旧坑在本章闭环**：stdlib 2.3 没有 `String → ℕ`，`parseNat`
   必须手写（§4 给了完整可证明版本）；`getLine`/`readFiniteFile` 带回
   车的串要先剥换行或让解析层容错，否则 `parseNat "42\n"` → `nothing`。
8. **字符串字面量模式"可整串匹配、不可拆"**：`f "abc" = …` 实测合法，但
   逐字符处理一律 `uncons`（Maybe 版）或 `toList` 进链表——别对 String
   指望 List 的模式匹配肌肉记忆。

---
上一章：[20 · IO 与真实程序](20-io.md) ｜ 下一章：[22 · 余归纳与无限流](22-codata.md) ｜ 返回：[README](../README.md)
