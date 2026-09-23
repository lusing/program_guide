# 27 · 标准库阅读指南

到这里你已经写完了两个综合项目（25 表达式解释器、26 可验证插入排序）——
也大概率已经发现：**你要用的大多数零件，标准库里其实已经有现成的**，
问题只剩下"它在哪个模块、叫什么名字、从哪一层 import 才不会拿到一堆
红字"。stdlib 2.3 有 1153 个 `.agda` 模块，直接翻会迷路。本章给你一张
地图和一套检索手法：目录怎么分区、`Base`/`API`/`Properties`/`Reasoning`
四层各自放什么、`+-cancelˡ-≡` 这种"天书名"怎么读、怎么打开
`Data.Nat.Properties` 学它写证明的路数、以及用什么命令在本地把东西
**grep 出来**——不是凭记忆猜路径，本章所有路径都是
`/usr/share/agda-stdlib/src` 上实测存在的。

对应示例：`../examples/Ex27_stdlib.agda`

示例是一个"综合应用小厨房"：一个文件里拼进八个 stdlib 高级件
（Base/Properties 分层、两条 Reasoning 链、Dec 剥证据、List/Vec 的
zipWith、Fin 与不等式联动、官方归并排序），全部在 Agda 2.8.0 +
stdlib 2.3 下类型检查通过（退出码 0）。

## 27.1 顶层目录地图

`ls /usr/share/agda-stdlib/src/` 数出来的实测模块数（`find <目录> -name '*.agda' | wc -l`）：

| 目录 | 模块数 | 一句话定位 |
|---|---|---|
| `Data/` | 543 | 具体数据类型大全：Bool/Nat/List/Vec/Fin/Char/String/Maybe/Product/Sum/Rational/Integer/Graph/AVL……每型一族模块 |
| `Function/` | 62 | 函数本身的理论：组合与 `_ˢ_`、单射满射双射（`_↔_`）、外延性、Related 蕴含阶梯 |
| `Relation/` | 163 | 关系的理论：Nullary（判定性 `Dec`）、Unary（谓词 `All`/`Any`）、Binary（`≡`、`≤`、 preorder/equivalence 大产业） |
| `Algebra/` | 169 | 抽象代数：`Semigroup`/`Monoid`/`Ring` 等接口（Structures/Bundles）+ 可判定实例 + solver |
| `Codata/` | 59 | 余数据三流派：`Musical`（guardedness，22 章用过）、`Sized`（尺寸）、`Guarded`（混合） |
| `IO/` | 12 | `IO`、`StdIO`、文件与_exit_原语（20 章） |
| `Level/` | 1 | 只有 `Level.agda`：`Lift`、`Level` 算术（05 章） |
| `Reflection/` | 30 | 反射 API：`TCM`、`AST`、`AnnotatedAST`（23 章） |
| `Tactic/` | 19 | 策略：`Tactic.Cong`、`Tactic.RingSolver`、`Tactic.MonoidSolver`——写证明的自动机 |
| `Text/` | 19 | `Printf`、`Format`、`Pretty`、`Regex`、`Tabular`（21 章近亲） |
| `System/` | 15 | 进程、环境、时钟、FilePath、Random——真程序的后院 |

零散还有 `Effect/`（36 个，单子效应的操作对象层，19 章的 `State`/`Reader` 等）、
`Axiom/`（6 个，外延公理/排中律等**可选公理**，import 即声明你放弃计算性）、
`Foreign/`（6 个，Haskell FFI）、`Induction/`（3 个，归纳模式的再抽象）和
`Debug/`、`Test/`。注意两个**没有**的：`Cubical/`（1.x 时代在，2.3 已移去独立
仓库——24 章用的是 `--cubical` 语言原语而非库模块）和 `Experimental/`
（同样早已拆仓）。

## 27.2 Base / API / Properties / Reasoning 四层约定

拿 `Data.Nat` 一家四口实测：

- **`Data.Nat.Base`**（450 行）：**只有定义**——`ℕ`、`zero/suc`、`_+_`、
  `_≤_` 和构造子 `z≤n/s≤s`、`_≤ᵇ_`。它几乎不 import 别的东西，编译最快，
  适合"只想用数据不想讲理"的场合。
- **`Data.Nat.Properties`**（2441 行）：**定理仓库**——`+-comm`、`_≤?_`、
  `≤-decTotalOrder` 全在这。它自己 `open import Data.Nat.Base`，
  但注意：**它并不把 Base 的名字 public 再导出**。实测在只 import
  `Data.Nat.Properties using (_≤_)` 时报错：

  ```text
  Not in scope: ≤
    (did you mean 'Data.Nat.Base._≤_'?)
  ```

  这一条就纠正了最常见的想当然："我 import 了 Properties，定义自然也有了"
  ——**没有**，定义和定理是两个 import。
- **`Data.Nat`**（49 行，API 层）：`open import Data.Nat.Base public`
  再配一份**白名单**，从 Properties 里只挑判定函数
  （`_≟_`、`_≤?_`、`_<?_` 等 `using` 列出的十几个）。所以：

  ```agda
  open import Data.Nat using (ℕ; _+_; +-comm)   -- 实测警告：
  -- The module Data.Nat doesn't export the following: +-comm
  ```

  `+-comm` 请直连 `Data.Nat.Properties`。
- **Reasoning 层**：每个带序的数据类型在自己的 Properties 里再开一个
  嵌套 module（`Data.Nat.Properties` 第 522 行的 `module ≤-Reasoning`），
  把 14 章的推理链语法接到该关系上。

四层拆分的**为什么**：Base 薄，编译依赖图就浅（stdlib 全量编译要几
分钟，你只写 5 行示例时不该拖着 2441 行 Properties）；定理与定义分离
还让"只要代码不要证明"的程序（20 章 IO 类）可以只挂 Base。写自己
项目时照抄这个约定即可：`Foo/Bar/Base.agda` 放类型和函数、
`Bar/Properties.agda` 放定理、`Bar.agda` 做白名单门面。

一个可以偷懒的事实：**API 层的宽严并不统一**。`Data.Fin.agda` 只有
30 行，把 `Data.Fin.Base` 和 `Data.Fin.Properties` **整体 public 转发**
——所以 `open import Data.Fin using (toℕ; inject≤; ≤-decidable)` 一把梭
是合法的；而 `Data.List.agda`（21 行）只转发 `Data.List.Base` 和
`Data.List.Scans.Base`。拿不准就打开那个门面文件读它的 `open import ...
public using (...)` 名单——门面文件都很短，这正是拆层的红利。

## 27.3 命名风格词典：把"天书名"读回英文

stdlib 的名字是系统化编址的，认识变符（superscript）和后缀就能从名字
反推内容。以下每条都是 `grep -rn` 实测行号。

### 27.3.1 上标 ˡ / ʳ：左右对称对

`ˡ` = left、`ʳ` = right。凡是"每侧一条"的命题都成对出现
（`Data/Nat/Properties.agda`）：

```text
+-identityˡ : LeftIdentity 0 _+_      -- 0 + n ≡ n（定义直接 refl）
+-identityʳ : RightIdentity 0 _+_     -- n + 0 ≡ n（要归纳）
+-cancelˡ-≡ : LeftCancellative _≡_ _+_
+-cancelʳ-≡ : RightCancellative _≡_ _+_
+-distribˡ-* / *-distribʳ-+ ...
```

读法公式：`<主运算>-<性质><侧位>-<次运算或等式>`。`+-cancelˡ-≡` 就是
"加法、左消去、关于等式"。侧位还能省：`+-mono-≤`（713 行）是对称版本。

### 27.3.2 ⁻¹：逆方向/逆蕴含

`Data/Fin/Base.agda:115` 的真实源码：

```agda
inject≤ {n = suc _} (suc i) m≤n = suc (inject≤ i (ℕ.s≤s⁻¹ m≤n))
```

`ℕ.s≤s⁻¹ : suc m ≤ suc n → m ≤ n`——构造子的**反向**读取，
读作"s≤s 的逆"。凡 `X⁻¹` 都是"把 X 反过来用"。

### 27.3.3 ˢ / ᵇ / ˣ：小写后缀各有领地

- `ᵇ` = Boolean 版：`_≤ᵇ_`、`_≡ᵇ_`（`Data/Nat/Base.agda`，返回 `Bool`
  的暴力比较，对应有 `T?` 升回 `Dec`）；`countᵇ : (A → Bool) → Vec A n → ℕ`
  （`Data/Vec/Base.agda:237`）是 `count` 的 Bool 谓词版。
- `ˢ` 有两处：`Function.Base` 的 `_ˢ_` 是 S 组合子
  （`f ˢ g = λ x → f x (g x)`，93 行，注释点名 McBride 的
  "Outrageous but Meaningful Coincidences"）；`Data.List.Relation.Binary.
  Suffix.Heterogeneous` 的 `_++ˢ_` 用 ˢ 标 "Suffix"。
- `ˣ`/`ʸ` 常见于 `with ... in` 模式把判定结果起名的地方——
  `Data/List/Relation/Binary/Permutation/Propositional/Properties.agda:383`：

  ```agda
  filter-↭ P? (swap x y xs↭ys) with P? x in eqˣ | P? y in eqʸ
  ... | yes _ | yes _ rewrite eqˣ rewrite eqʸ = swap x y (filter-↭ P? xs↭ys)
  ```

### 27.3.4 后缀 -mono / -cancel / -cong / -injective / -irrelevant

- `-mono-<关系>`：单调性，`+-mono-≤`；
- `-cancel<侧>-<Eq或≤>`：消去律，`+-cancelˡ-≤`（671 行）；
- `-cong`：兼容性/同余，`map-cong : f ≗ g → map f ≗ map g`
  （`Data/List/Properties.agda:103`）；
- `-injective`：单射拆包，`∷-injective : x ∷ xs ≡ y ∷ ys → x ≡ y × xs ≡ ys`
  （`Data/List/Properties.agda:69`，构造子当函数用的逆）；
- `-irrelevant`：证明唯一性，`≤-irrelevant : Irrelevant (_≤_ {m} {n})`
  （`Data/Fin/Properties.agda:306`）、`≡-irrelevant`
  （`Relation/Binary/PropositionalEquality/WithK.agda:31`，需要 `--with-K`）。
  看到 `-irrelevant` 就该想起：这类值可以放心丢进 erasure。
- 箭头家族：`sort-↗`/`sort-↭`（见 27.6 件 8）——`↗` 读作"走向 Sorted"，
  `↭` 是置换关系本身的名字（2.3 起 `↭` = "is a permutation of"）。

### 27.3.5 关系符号家族与使用频度

对整个 `src/` 的 `grep -rhoE "_[⇒↔≼⊑∼≈≋]+_" | sort | uniq -c` 实测频度：

| 符号 | 次数 | 惯用含义 |
|---|---|---|
| `_≈_` | 2241 | setoid/代数结构里的"给定等式"，一切 `Rel` 的默认名 |
| `_∼_` | 363 | 通用"方程/related"，`Function.Related` 的无方向等价 |
| `_⇒_` | 168 | 两个关系间的逐点蕴含：`P ⇒ Q = ∀ {x y} → P x y → Q x y`（`Relation/Binary/Core.agda:47`） |
| `_≋_` | 166 | 深层/逐点相等：List/Vec 版 `Data.List.Relation.Binary.Equality.Setoid` |
| `_≼_` `_⊑_` | 95/38 | 抽象代数的"另一种序"占位名，如 `Monotonic₂ _≤_ _⊑_ _≼_ _∙_`（`Relation/Binary/Definitions.agda:166`）——三个符号是**三个不同的序**，不是花活 |
| `_↔_` | 91 | 双射/等价：`Function.Bundles` 记录，`A ↔ B` 即"有逆函数" （17 章） |

规律：**同一个字母加波浪/双波浪表示"更结构化/逐点版的相等"**。见到
`_≍_`、`_≎_` 也别慌，先看模块头部 `module ... where` 之前的参数列表，
符号总在那里被定义。

## 27.4 读源码学证明：以 `+-comm` 为标本

标准练习：想看库怎么证交换律，先 grep 定位再读上下文。实测命令与输出：

```console
$ grep -n "^+-comm" /usr/share/agda-stdlib/src/Data/Nat/Properties.agda
561:+-comm : Commutative _+_
562:+-comm zero    n = sym (+-identityʳ n)
563:+-comm (suc m) n = begin-equality
```

连同前置引理把 540–567 行读全（一字不差的库源码）：

```agda
+-suc : ∀ m n → m + suc n ≡ suc (m + n)
+-suc zero    n = refl
+-suc (suc m) n = cong suc (+-suc m n)

+-identityʳ : RightIdentity 0 _+_
+-identityʳ zero    = refl
+-identityʳ (suc n) = cong suc (+-identityʳ n)

+-comm : Commutative _+_
+-comm zero    n = sym (+-identityʳ n)
+-comm (suc m) n = begin-equality
  suc m + n   ≡⟨⟩
  suc (m + n) ≡⟨ cong suc (+-comm m n) ⟩
  suc (n + m) ≡⟨ sym (+-suc n m) ⟩
  n + suc m   ∎
```

四堂课一次上完：

1. **类型别名先展开**：`Commutative _+_` 是
   `Algebra.Definitions` 里的 `∀ x y → x + y ≡ y + x`——grep 不到定义就
   去追别名，这是读 stdlib 的日常。
2. **对第一个参数做 case**：`_+_` 按左侧递归定义，所以 `zero` 与 `suc m`
   分支各管一半。0 + n ≡ n 是 refl，n + 0 ≡ n 要归纳——**定义不对称，
   引理就要成对**，`+-suc`/`sym (+-identityʳ n)` 全是在补这个不对称。
   你在 13 章自己归纳过的剧本，库作者一字不差地演给你看。
3. **`begin-equality`**：这就是 14 章的 ≡-Reasoning，只是 Properties
   文件顶部 `open import Relation.Binary.PropositionalEquality` 后内部
   起了短名；2441 行的文件里有 25 处 `begin-equality`——库作者本人
   就爱写链，rewrite 派是少数。
4. **第一步 `≡⟨⟩`**：`suc m + n` 与 `suc (m + n)` 是定义相等，写成链
   的第一步是为了让**每一步都可读**，而不是把 refl 藏进类型检查器。

## 27.5 查库工作流：grep 是你真正的 IDE

Agda 没有 Hoogle（历史上的 library.search 已停维），可用的检索手段按
性价比排序：

**命令行 grep（本章所有行号皆由此而来）**。三大招式：

```console
# ① 按名字找定义（^ 锚定行首=定义处，缩进的多数是用例）
$ grep -rn "^zipWith :" src/Data/List/Base.agda src/Data/Vec/Base.agda
src/Data/List/Base.agda:83:zipWith : (A → B → C) → List A → List B → List C
src/Data/Vec/Base.agda:128:zipWith : (A → B → C) → Vec A n → Vec B n → Vec C n

# ② 按"我想干的事"猜名词横扫
$ grep -rln "zipWith" src/Data | wc -l
39

# ③ 找导出面：某个门面模块到底转发了什么
$ grep -n "public" src/Data/List.agda
18:open import Data.List.Base public
20:open import Data.List.Scans.Base public
```

**让编译器当搜索引擎**：import 错了 Agda 会给 `did you mean`
（27.2 那条 `_≤_` 报错即是）；`C-c C-l` 加载后在孔洞里按 `C-c C-space`
补全可浏览导出表；交互模式里那几个目标搜索/自动化工具（case-split、
helper 搜索）对 2000+ 行的 Properties 常常无功而返——**别依赖它们，
依赖 grep**。

**GitHub 代码搜索**：仓库 <https://github.com/agda/agda-stdlib> 的
`v2.3` tag 与本机 `/usr/share/agda-stdlib/src` 同源；每个数据模块顶部
的注释 `-- See README.Data.Nat for examples` 指向仓库里的 literate
用例集——**注意 Debian 包只装了 `src/`，那些 README 模块本地不存在**
（`find /usr/share/agda-stdlib -maxdepth 3 -name '*README*'` 实测零命
中），看用例得回 GitHub。

**最后的保险**：任何 import 路径与名字，以
`cd /home/xulun/code/programming/agda && agda examples/你的文件.agda`
退出码 0 为准。本章示例里每条 import 都是这么钉死的。

## 27.6 示例走读：八件厨房汇（`Ex27_stdlib.agda`）

示例按"件"组织，每份 import 只写该件用得上的名字——这本身就是模仿
stdlib 的 using 白名单纪律。八件速览：

1. **`Data.Nat.Base`**：只取 `ℕ zero suc _+_ _≤_ z≤n s≤s`，一个定理都不
   进口，演示分层的"定义侧"。
2. **`Data.Nat.Properties`**：`_≤?_`、`+-assoc`、`+-comm`、`+-mono-≤`、
   `≤-decTotalOrder`。`plus-monotone-demo : 1 + 2 ≤ 3 + 4` 直接
   `+-mono-≤ one≤3 two≤4`，零归纳。
3. **`PE.≡-Reasoning`**：`shuffle` 三行链，全部弹药来自件 2。
4. **`NP.≤-Reasoning`**：`mixed-chain` 把 `≡⟨⟩` 步与 `≤⟨⟩` 步混进一条链
   ——`Relation.Binary.Reasoning.Base.Triple` 给的 ≡/≤ 双轨语法。
5. **`Dec + ⌊_⌋ + if`**：`takeWhile≤` 用 `⌊ x ≤? k ⌋` 把判定结果剥成
   `Bool` 喂给 `if`，再用 refl 验证 `2 ∷ 3 ∷ 5 ∷ 1 ∷ []` 截到 `2 ∷ 3 ∷ []`。
6. **`List.zipWith` 与 `Vec.zipWith` 同框**：List 版截断
   （`zip-truncates`，短表多余元素直接蒸发）、Vec 版把"等长"写进类型
   （`vec-zip`）——两个 zipWith 同名，import 时必须一边限定或改名。
7. **`Vec.tabulate/lookup` + `Fin.inject≤`**：`lookup-tabulate` 要对着
   Fin 归纳（tabulate 是递归定义，不是免费 refl——先读 `Data.Vec.Base`
   第 250 行再动手写证明，这就是 27.4 的方法论）；`shift-up` 把
   `Fin n → Fin (suc (suc n))` 的实现外包给 `inject≤` 加一条长度不等式。
8. **`Data.List.Sort ≤-decTotalOrder`**：官方归并排序，随货附赠两条
   定理：

   ```agda
   sort-is-permutation : sort list-312 ↭ list-312
   sort-is-permutation = sort-↭ list-312

   sort-is-sorted : Sorted (sort list-312)
   sort-is-sorted = sort-↗ list-312
   ```

   26 章你花一整章证明的"重排 + 有序"，这里两行调包完事。想**算**出
   排序结果就用零件 `merge`：`merge-run : merge _≤?_ (1 ∷ 3 ∷ [])
   (2 ∷ 4 ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []` 是 refl。

## 27.7 版本配对矩阵：2.8.0 + 2.3 的实测偏差清单

Agda 与 stdlib 是**两条版本号**，每个 stdlib 发布在自己的 README 里声明
支持的 Agda 版本区间；本机
`agda --version` → `Agda version 2.8.0`，`standard-library.agda-lib`
头一行 `name: standard-library-2.3`。本章与前序章节实测撞到的、与
网络教程/旧书不同的偏差：

1. **`Fin` 构造子**：现名 `zero`/`suc`（`Data/Fin/Base.agda`）。
   网上旧例子的 `fz`/`lsuc`（1.x）与 `fzero`/`fsuc`（2.0）都已退役，
   与 `Nat` 同名靠类型区分。
2. **`Cubical` 目录不存在**：2.3 的 `src/` 顶层没有 `Cubical/`（`ls`
   实测 No such file）——1.x 时代它在这里。24 章体验路径是语言 flag
   `--cubical` + 独立 cubical library，别在 stdlib 里找。
3. **没有列表字面量**：Agda 2.8 取消了 `[ 1, 2, 3 ]` 内建解释，
   `[ x ]` 只是单元素语法（`Data.List.Literals` 的 `fromList` 另有一套
   方括号记法，需额外 import）。旧教程里满屏的 `[1,2,3]` 全部要手写 `∷`。
4. **`.agda-lib` 字段小写**：`depend:` 而非 `DEPENDS:`（大写被忽略，
   02 章实测）。
5. **`src/README` 用例目录未随 Debian 包安装**（27.5 实测），照抄报错
   信息里 "See README.X" 的路径会在本地扑空。

## 坑位清单

1. **`Data.Nat.Properties` 不导出 `_≤_` 等定义**——它自己 `open` Base 但不
   `public`。定义走 Base、定理走 Properties，**两条 import 都要写**；报错
   里的 `did you mean 'Data.Nat.Base._≤_'?` 就是路标。
2. **`Data.Nat`（API 层）是白名单门面**：`using (ℕ; _+_; +-comm)` 实测
   警告 `doesn't export: +-comm` 然后 NotInScope 连锁爆炸。别信"门面
   应该有全部"的直觉，读那 49 行的 using 名单。
3. **嵌套 module 进不了 `using()`**：`open import Data.Nat.Properties
   using (≤-Reasoning)` 报 `ModuleDoesntExport`（而且只是警告，错误要到
   下一行 `open ≤-Reasoning` 才爆）；`Relation.Binary.PropositionalEquality
   using (≡-Reasoning)` 同理。正解：`import M as P` 之后 `open P.≤-Reasoning`。
   （本章示例件 2/件 3 注释里有实测记录。）
4. **erased 证明参数不吃期望类型**：`inject≤ i .(m ≤ n)` 的行内证明
   `s≤s (s≤s (n≤1+n m))` 会留下无解 metavar——先写成带完整类型标注的
   引理（示例里的 `suc≤+1`）再传。同理 `z≤n` 的隐式上界是自由变量，
   `+-mono-≤ (s≤s z≤n) (s≤s (s≤s z≤n))` 这种行内写法会让
   `?m + ?o := 3` 类算术约束悬而不决（示例 `one≤3`/`two≤4` 的来历）。
5. **官方 `sort` 不配合 refl**：`sort (3 ∷ 1 ∷ 2 ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ []`
   实测报 `UnequalTerms`——MergeSort 的驱动是 `Data.Nat.Induction` 的
   well-founded 快速版，编译期不展开闭项。定理（`sort-↭`/`sort-↗`）照用，
   想算结果用结构递归的 `merge`。
6. **`zipWith`/`[]`/`∷` 全家同名**：List、Vec 两套 zipWith，List、Vec、
   Nat、Fin 四套 `[]`/构造子。多 import 混开后不报错，**用到的那一刻**
   才报歧义；对策是像示例一样 `import Data.Vec.Base as V` 限定，或
   `renaming` 错开。
7. **模块头部的 `-- See README.X` 是路牌不是路径**：apt 装的 stdlib 没有
   那个目录（27.5 第 3 条），去 GitHub 对应 tag 看。
8. **grep 定位用 `^` 锚行首**：定义永远顶格，缩进的命中全是用例/重导出，
   混在一起看会误判"这名字在哪定义的"。

---
上一章：[26 · 实战：可验证插入排序](26-sorting.md) ｜ 下一章：[28 · 坑清单与最佳实践](28-pitfalls.md) ｜ 返回：[README](../README.md)
