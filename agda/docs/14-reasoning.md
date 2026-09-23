# 14 · 推理框架

上一章我们用 `rewrite` 将归纳证明写得像编译通过的脚本——但**作者
爽了，读者遭殃**：等式的中间项活在类型检查器的内存里，死在左端注释
的缺席中。本章引入 Agda 的答案：**≡-Reasoning 推理链**——把
`begin x ≡⟨ 理由 ⟩ y ≡⟨⟩ z ∎` 写成正文，每一步等式都是可核对的
一行代码。它不是语言特性，是标准库的一个模块（外加一堆 fixity
戏法），所以本章同时教你：怎么 import 才不被 `begin_` 二义性咬、
≤/</≡ 三味关系怎么混链、方向反了的引理怎么进链、以及**自己动手
造一个 calc**——造完你就明白 stdlib 那些链为什么长成这样。

对应示例：`../examples/Ex14_reasoning.agda`

示例直接复用 13 章 `Ex13_induction` 里已验证的引理（import 自家
examples 目录即可，`AgdaTutorial.agda-lib` 早就把它 include 了）。
报错文本均为 Agda 2.8.0 + stdlib 2.3 实测。

## 14.1 手算 rewrite 链之痛

一条人畜无害的换元定理 `a + (b + c) ≡ b + (a + c)`，rewrite 笔法
（示例 `shuffle-rew`）：

```agda
shuffle-rew a b c
  rewrite sym (+-assoc a b c) | cong (λ x → x + c) (+-comm a b)
          | +-assoc b a c = refl
```

能编译，但读者要在脑子里执行三遍替换：当前目标现在长什么样？下一刀
切在哪？第二刀的 `cong (λ x → x + c) …` 为什么非得套个匿名函数？
证明项笔法（`trans (cong suc …) (sym …)`）更糟：套娃从外读到内。
而数学家写这条定理是一行等式链。Agda 的对应物：

```agda
shuffle-≡ a b c = begin
  a + (b + c)
 ≡⟨ sym (+-assoc a b c) ⟩
  (a + b) + c
 ≡⟨ cong (λ x → x + c) (+-comm a b) ⟩
  (b + a) + c
 ≡⟨ +-assoc b a c ⟩
  b + (a + c)
 ∎
  where open ≡-Reasoning
```

每跳一行、理由一个括号、中间项全暴露——**和论文排版一致**。
本章剩下的事就是把这五行语法讲透讲穿。

## 14.2 ≡-Reasoning 解剖

**来源与 import**（路径必须实测，别背旧教程的）：模块
`≡-Reasoning` 定义在 `Relation.Binary.PropositionalEquality.Properties`
第 202 行，经 `Relation.Binary.PropositionalEquality` 公共重导出。
它是**命名模块**：import 的 `using` 清单里没有 `module ≡-Reasoning`
时，直接 `open ≡-Reasoning` 实测报错：

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:4.6-17: error: [NoSuchModule]
No module ≡-Reasoning in scope
when scope checking the declaration
  open ≡-Reasoning
```

必须先 `using (module ≡-Reasoning)` 把模块本体带进作用域再 open。标准姿势：

```agda
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; module ≡-Reasoning)
```

**五个构件**（fixity 摘自源码 `Reasoning/Syntax.agda`）：

| 记法 | 语义 | 类型（约） |
|---|---|---|
| `begin_` | 起链（infix 1 前缀） | `x → x ≡ x` 的视图锚点 |
| `x ≡⟨ p ⟩ rest` | 换一跳：`p : x ≡ y`，rest 从 y 续 | infixr 2 |
| `x ≡⟨⟩ rest` | 「算一步」：不给理由，纯规约 | 两端必须定义相等 |
| `x ≡⟨ p ⟨ rest` | 倒着换一跳：`p : y ≡ x` | 新式反向（v2.0 起） |
| `_∎` | 收尾（infix 3 后缀） | `x : x ≡ x` |

链的类型 = **首项 ≡ 末项**，每一跳独立类型检查——这是它相对
rewrite 的第二个优势：错误定位到具体一跳（见 14.4）。

**`≡⟨⟩` 不是免费的**：它要求相邻两项真的算得到彼此。拿
`n + zero ≡⟨⟩ n` 碰瓷（n 是变量，算不动），实测：

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:12.3-13.3: error: [UnequalTerms]
n != n + zero of type ℕ
when checking that the expression n ∎ has type n + zero ≡ n
```

报错指到「下一跳的项」`n ∎` 上而不是 `≡⟨⟩` 本行——链式报错的
跨度规则见 14.4。想合法用 `≡⟨⟩`，两端得像 `zero + n ≡⟨⟩ n`
那样有规约关系（示例 `+-comm-≡` 基例第一跳就是）。

**整链重写 13 章剧本**（示例 `+-comm-≡`）：

```agda
+-comm-≡ : (m n : ℕ) → m + n ≡ n + m
+-comm-≡ zero n = begin
  zero + n
 ≡⟨⟩
  n
 ≡⟨ sym (+-idʳ n) ⟩
  n + zero
 ∎
  where open ≡-Reasoning
```

注意基例里 `sym (+-idʳ n)`：链式对方向不如 rewrite 敏感——
每个括号就是一个显式等式项，反着用引理天然合法。

## 14.3 反向换跳：`_≡˂_` 不存在

先纠一个流传广的迷思：**stdlib 2.3 全库搜不到 `_≡˂_` 或
`≡˂⟨_⟩_`**（`grep ˂` 结果为零）。部分中文/英文教程里的这个记号
在现版 stdlib 无法编译（实测 Could not parse the application）。
真正的「倒着走」有两个正品 + 一个万能备胎：

```agda
-- ① 新式 v2.0：理由写在左括号，链往下「撑」
back-new m n = begin
  suc (m + suc n)
 ≡⟨ +-suc m (suc n) ⟨     -- 理由的陈述：末项 ≡ 本项
  m + suc (suc n)
 ∎
  where open ≡-Reasoning

-- ② 旧式（v2.0 废弃，但实测仍可编译）
back-old m n = begin
  suc (m + suc n)
 ≡˘⟨ +-suc m (suc n) ⟩
  m + suc (suc n)
 ∎
  where open ≡-Reasoning

-- ③ 万能备胎：sym 摆正 + 正向跳
back-sym m n = begin
  suc (m + suc n)
 ≡⟨ sym (+-suc m (suc n)) ⟩
  m + suc (suc n)
 ∎
  where open ≡-Reasoning
```

`≡˘⟨_⟩_` 的地位看源码注释（`Relation/Binary/Reasoning/Syntax.agda`
第 413–416 行，真实文本）：

```agda
step-≡˘ = step-≡-⟨
{-# WARNING_ON_USAGE step-≡˘
"Warning: step-≡˘ and _≡˘⟨_⟩_ was deprecated in v2.0.
Please use step-≡-⟨ and _≡⟨_⟨_ instead."
#-}
```

实测坑：这个 `WARNING_ON_USAGE` 在默认警告配置下**不打字、不改
退出码**——废弃记号静默可编译，迁移要靠人肉。新代码统一用
`≡⟨_⟩_`（正向）与 `≡⟨_⟨`（反向）成对，外加 `sym` 兜底。
**组合心法**：引理方向与链走向一致→ 正向跳；反了且只反一两跳→
`sym`；反了且整条链都是反的→ 倒序重写比满纸 sym 好读。

## 14.4 断链报错怎么读

链每跳一个约束，断在哪报错就盖住哪一段。故意把 `+-idʳ` 的结论
写歪（跳到 `n + suc zero`）：

```agda
broken : ∀ n → n + zero ≡ n
broken n = begin
  n + zero
 ≡⟨ +-idʳ n ⟩
  n + suc zero
 ∎
```

实测：

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:16.3-17.3: error: [UnequalTerms]
n + 1 != n of type ℕ
when checking that the expression n + suc zero ∎ has type n + 1 ≡ n
```

三条读法：①报错 span 是「出问题的项 + 它的续链」（16.3–17.3，
即第三项到 `∎`），不是你以为的理由括号；②期望类型里的首项被
normalize 成 `n + 1`（2.8 把 `suc zero` 打印成 `1`）——**报错
展示的是正规形，对照源码要会反向翻译**；③`!=` 左侧正是「你想
跳到但跳不到」的差值。找不到北时把链拆成两个短链，或退回
rewrite 二分定位。

## 14.5 ≤-Reasoning：三味混链

实测三件事：

1. **`≤-Reasoning` 是 `Data.Nat.Properties` 里的命名模块，且该文件
   末尾的 `open ≤-Reasoning` 不带 public**——所以它既不自动打开，
   `using (≤-Reasoning)` 也拿不到（那只是模块名不是成员）。
   正确 import：`using (module ≤-Reasoning)`。
2. **`_≤_`、`z≤n`、`s≤s` 不从 Properties 导出**（它们在 `Data.Nat`/`Data.Nat.Base`），
   想当然地写进 using 清单会吃实测警告（退出码仍是 0！）：

   ```text
   warning: -W[no]ModuleDoesntExport
   The module Data.Nat.Properties doesn't export the following:
     _≤_
     z≤n (did you mean 'z≤′n'?)
     s≤s (did you mean 's≤′s'?)
     ≤-Reasoning
     n≤1+m (did you mean 'n≤1+n'?)
     _≤⟨_⟩_
   ```
3. **一个链里可混 `≡`/`≤`/`<` 三种跳**。示例 `+-0-≤`：

```agda
+-0-≤ : (n m : ℕ) → n ≤ m → n + zero ≤ suc m
+-0-≤ n m n≤m = begin
  n + zero
 ≡⟨ +-idʳ n ⟩          -- ≡ 跳：引理是等式也行，链自动放宽到 ≤
  n
 ≤⟨ ≤-trans n≤m (n≤1+n m) ⟩
  suc m
 ∎
  where open ≤-Reasoning
```

`≡ 跳自动被接受`是 triple 型推理框架的看家功能（对照源码，
`Data/Nat/Properties.agda` 522–531 行）：

```agda
module ≤-Reasoning where
  open import Relation.Binary.Reasoning.Base.Triple
    ≤-isPreorder
    <-asym
    <-trans
    (resp₂ _<_)
    <⇒≤
    <-≤-trans
    ≤-<-trans
    public
    hiding (step-≈; step-≈˘; step-≈-⟩; step-≈-⟨)
```

`<⇒≤` 就是「< 也是 ≤」的嵌入，`Base.Triple` 靠它把三种步缝合。

**`begin` 还是 `begin-strict`**：`_<_` 在 ℕ 上是定义缩写
`m < n = suc m ≤ n`（`Data/Nat/Base.agda` 第 61 行）。目标写成
`n < suc m` 时，链会被锚到正规形 `suc n ≤ suc m` 上——起点写
`begin n` 直接翻车（实测，示例里换成 `begin-strict` 后通过）：

```text
/home/xulun/code/programming/agda/examples/Ex14_reasoning.agda:136.3-141.3: error: [UnequalTerms]
n != suc n of type ℕ
when checking that the inferred type of an application
  n IsRelatedTo _z_204
matches the expected type
  suc n IsRelatedTo suc m
```

规律：**两端点按目标关系原样写（≤ 链用 begin）；一旦目标头是 `<`
且起点项会被差一化（n vs suc n），用 `begin-strict`**——stdlib 的
`m<m*n`（`Data/Nat/Properties.agda` 1019 行）正是官方示范。示例
`<-trans-mix` 用 `begin-strict` 走 `n < m ≤ k ⊢ n < k`。

**命名坑（13 章老坑的续集）**：搬单调性引理时
`+-monoˡ-≤ c p : a + c ≤ b + c`（p : a ≤ b）——**ˡ 标记的是左操作数
被加的那个常数在哪一侧**……直觉刚好反的读法请一律以
`:Check +-monoˡ-≤` 为准。示例 `+-mono-≤` 用的是 `+-monoʳ-≤`
（c 加在左侧）。

## 14.6 自造推理框架

stdlib 的链不是魔法，每个「跳」就是一条带记法声明的传递引理。
最小仿写（示例 `≤-Calc`，实测通过）：

```agda
module ≤-Calc where
  infix 1 start_
  start_ : ∀ {m n : ℕ} → m ≤ n → m ≤ n
  start p = p

  infixr 2 _≤̃⟨_⟩_
  _≤̃⟨_⟩_ : (m : ℕ) {n o : ℕ} → m ≤ n → n ≤ o → m ≤ o
  m ≤̃⟨ m≤n ⟩ n≤o = ≤-trans m≤n n≤o

  infix 3 _∎̃
  _∎̃ : ∀ (m : ℕ) → m ≤ m
  m ∎̃ = ≤-refl
```

用法与 stdlib 手感一致：

```agda
mine-≤ : (n m : ℕ) → n ≤ m → n + zero ≤ suc m
mine-≤ n m n≤m = start
  n + zero
   ≤̃⟨ ≡⇒≤ (+-idʳ n) ⟩
  n
   ≤̃⟨ ≤-trans n≤m (n≤1+n m) ⟩
  suc m
 ∎̃
```

（`≡⇒≤ refl = ≤-refl` 是自备的 ≡→≤ 转换器——stdlib 里这活由
`<⇒≤`/`hiding` 那套 triple 参数代劳。）两个机制要点：

* **多洞运算符名**：`_≤̃⟨_⟩_` 名字里三个下划线对三个实参位
  （左项/括号理由/续链），Agda 解析器原生支持——不必写 syntax 宏。
  stdlib 则用二元函数 + `syntax` 声明重排实参
  （`syntax step-≤ x yRz x≤y = x ≤⟨ x≤y ⟩ yRz`），为的是
  forward/backward 复用同一个 step。
* **`start_` 与 `begin_` 的戏份**：把首项「钉」进视图，让隐式参数
  从首项解算、报错落在链上。stdlib 靠 `_IsRelatedTo_` 私有 data
  做得更讲究，玩具版直接返回等式也够用。

给任意（预）序造链不必亲自动手：
`Relation.Binary.Reasoning.Preorder`（及 `Setoid`/`PartialOrder`/
`StrictPartialOrder`）吃一个结构记录就吐一整套 `begin_/step/∎`；
`≤-Reasoning` 本体不过是 `Base.Triple` 喂上 `≤-isPreorder` 的实例。
读懂 14.5 那 10 行源码，这套框架就没有秘密了。

## 14.7 三方对比：Agda calc / Lean calc / Coq rewrite

| 维度 | Agda ≡-Reasoning | Lean 4 `calc` | Coq 主流 |
|---|---|---|---|
| 形态 | **库**（命名模块 + fixity 戏法） | **语言内建语法**（`:= proof` 尾挂每行） | 无内建 calc；`rewrite`/`transitivity` 战术 |
| 每跳理由 | 项模式：括号里放**证明项** | 每行 `:= by tac`，战术可写 | 无显式中间步（或 `assert` 小目标） |
| 关系混排 | 框架参数决定（triple 可 ≡/≤/< 混链） | 关系任意，需登记可传达性（`Trans` 实例） | `transitivity` 手拼 |
| 自定义新算子 | `syntax` 宏/多洞名，人人可造（14.6） | 宏 `calc` 步骤可扩展 | tactic 层重写规则 |
| 心智模型 | 等式链是**表达式**（有类型） | 等式链是**带证项的语句** | 等式链是**目标状态序列** |

Lean 版同一换元定理（外部语言代码，仅作对照）：

```lean
theorem shuffle (a b c : Nat) : a + (b + c) = b + (a + c) :=
  calc a + (b + c) = (a + b) + c := (Nat.add_assoc _ _ _).symm
     _             = (b + a) + c := congrArg (· + c) (Nat.add_comm a b)
     _             = b + (a + c) := Nat.add_assoc _ _ _
```

Agda 链与它几乎逐行同构——**calc 风格是项模式世界的通用语**；
Coq 用户则习惯「目标被 rewrite 连击」的战术叙事。三方共同教训：
等式推理的**中间项必须落在纸面上**，无论以证明项还是战术痕迹。

## 14.8 可读性策略：何时 rewrite，何时链

实测手感总结（也是 stdlib 源码自己的户型）：

1. **一跳直达或目标规约即 `refl` → `rewrite`**：如 `+-comm` 的
   步例 `rewrite +-comm m n | +-suc n m = refl`，硬套链只会
   把三个已经同形的项演化成三个 `refl` 跳。
2. **≥ 两跳、中间项有信息量、或要给人类看 → 链**：14.1 的对比图；
   stdlib 大定理（`reverse-++`、`*-comm` 之类）清一色链，
   如 `Data/List/Properties.agda` 1420–1428 行的
   `reverse-++ xs ys = begin reverse (xs ++ ys) ≡⟨⟩ (xs ++ ys) ʳ++ [] …`
   一路 `≡⟨⟩`/带理由跳交替，就是本章范文。
3. **混合场景：外链内 rewrite**——链负责骨架可读，单跳理由太长时
   在括号里放 `where` 辅助或 `begin-equality` 子链（13 章引用的
   `+-comm (suc m) n = begin-equality …` 即此招：链内开子链）。
4. **证明项（trans/cong 套娃）只配出现在一行结论里**：
   `+-comm-term` 那种两行 trans 的紧凑形适合收尾，超过两跳就该转链。

代价方面别自我吓唬：链只是**语法层**，展开后与 cong/trans 证明项
同构（`step-≡` 们就是 cong/trans 的马甲），类型检查成本同量级，
运行时更无任何残留（证明不参与计算）。

## 14.9 坑位清单（本项目实测）

1. **`≡-Reasoning` 不 import 就 open = NoSuchModule**：它是命名
   模块，必须 `using (module ≡-Reasoning)`；`using (_≡_; refl; …)`
   四件套带不出它（实测最早撞过）。
2. **`_≡˂_`/`≡˂⟨_⟩_` 在 2.3 不存在**：grep 全库无 `˂`；照老教程写
   直接 Could not parse。反向跳用 `≡⟨_⟨`（新）或 `sym`+`≡⟨_⟩_`。
3. **`≡˘⟨_⟩_` 已废弃但静默可编译**：源码挂着 `WARNING_ON_USAGE`
   （v2.0 起），默认配置不打字也不改退出码——迁移无提示，新代码
   禁用。
4. **全局同时 open `≡-Reasoning` 与 `≤-Reasoning` → `begin_`/`∎`
   AmbiguousName**（实测）：两个框架的构件同名。户型改成每证明
   `where open ≡-Reasoning`，与 stdlib 源码风格同步。
5. **目标头是 `<` 时 `begin n` 会按 `suc n ≤ …` 锚定翻车**
   （`n != suc n`，见 14.5）：`_<_` 是差一缩写。用 `begin-strict`
   或干脆把链端点全写成 ≤ 形状。
6. **`≡⟨⟩` 两端必须定义相等**：卡住的 `n + zero ≡⟨⟩ n` 报
   `n != n + zero`，且报错 span 盖在「下一项到 ∎」上——
   别只盯本行。
7. **`Data.Nat.Properties` 不导出 `_≤_`/`z≤n`/`s≤s`，且这类
   ModuleDoesntExport 只是 warning、退出码 0**：CI 只看退出码会
   一路绿灯到使用处才 NotInScope（10 章老坑在本章复现）。
8. **`+-monoˡ-≤` 的 ˡ/ʳ 与直觉相反**（实测 `n + 1 != suc n`）：
   用前 `:Check`，别赌。
9. **报错里的项是正规形**：`n + 1` 实为 `suc (n + zero)`、
   `0` 实为 `zero`——读报错要在脑内跑一遍 normalize。

---
上一章：[13 · 归纳证明](13-induction.md) ｜ 下一章：[15 · 可判定性质](15-decidable.md) ｜ 返回：[README](../README.md)
