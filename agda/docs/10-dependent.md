# 10 · 依赖类型入门：Fin

05 章我们说过「类型可以依赖值」，但至今写的程序里类型都是死的：`ℕ → ℕ`
不带任何信息。本章开始兑现这句话——用依赖类型语言里最经典的入门例子
`Fin n`：**恰好有 n 个元素的类型**，即「小于 n 的自然数」。它是 16 章
Vec（长度索引的列表）、25 章类型良好 AST（作用域索引的变量）的浓缩原型：
一个值同时活在「数据」和「类型」两个层面，索引对了程序就合法，索引越界
**连表达式都写不出来**。本章三件事：讲透「索引 vs 参数」到底差在哪；
给出 Fin 的两种等价定义并互相换算；然后用依赖消除做几件 Haskell 里
「只能靠约定」、这里「靠类型判生死」的事——包括用荒谬模式（`()`）
当场消灭根本不可能出现的分支，那是本章的震撼时刻。

对应示例：`../examples/Ex10_dependent.agda`

报错文本均为 Agda 2.8.0 + stdlib 2.3 实测原样粘贴，代码片段与示例一致。

## 10.1 索引 vs 参数：一字之差，天壤之别

看两行声明，差别只在括号的位置：

```agda
data Wrap (A : Set) : Set where
  wrap : A → Wrap A

data FinOld : ℕ → Set where
  fz    : ∀ {n} → FinOld (suc n)
  lsuc  : ∀ {n} → FinOld n → FinOld (suc n)
```

`Wrap` 的 `A` 是**参数**：写在 `Wrap` 名字左边（`data Wrap (A : Set) : Set`），
所有构造子里它原样出现、永远同一个值——`wrap` 存进去的 `A` 和取出来的
`Wrap A` 是同一个 `A`。`FinOld` 的 `n` 是**索引**：写在冒号右边
（`FinOld : ℕ → Set`，先有数后有型），构造子的职责就是**把索引算出来**：

- `fz`：不要任何输入，**产出**索引 `suc n` 的一个值——「第 0 号」对任何
  正数容量都成立；
- `lsuc`：吃一个索引为 `n` 的值，**产出**索引为 `suc n` 的值——
  「若 i < n，则 i+1 < n+1」。

这就是「构造子类型里索引变化的意义」：每个构造子是一条**类型层的算术公理**。
把 `FinOld n` 读作「还剩 n 格可用的计数器」，`fz` 是「就用这一格」，
`lsuc` 是「跳过一格、余量少一格」。于是 `FinOld 3` 的可构造值**恰好**三个：
`fz`、`lsuc fz`、`lsuc (lsuc fz)`——想构造第四个 `lsuc (lsuc (lsuc fz))`，
最外层要求参数类型 `FinOld 0`，而它没有任何构造方式。**越界不是运行错误，
是类型无解**。

一个历史包袱要当面拆掉：**stdlib 2.3 的 `Fin` 构造子不叫 `fz/lsuc`，
就叫 `zero` 和 `suc`**（`Data.Fin.Base` 里 `data Fin : ℕ → Set where
zero : Fin (suc n); suc : (i : Fin n) → Fin (suc n)`）——和 `ℕ` 的构造子
完全同名。老名字 `fz/lsuc` 只存在于旧版教程。本章示例为讲解概念保留了一组
自定义的 `FinOld`（就用经典名 `fz/lsuc`），与标准库 Fin 建立双射：

```agda
toFin : ∀ {n} → FinOld n → Fin n
toFin fz = fzero
toFin (lsuc i) = fsuc (toFin i)

fromFin : ∀ {n} → Fin n → FinOld n
fromFin fzero = fz
fromFin (fsuc i) = lsuc (fromFin i)
```

（`fzero/fsuc` 是 import 时 `renaming (zero to fzero; suc to fsuc)` 改的名。）
两个方向复合都是恒等，证明只是对构造子归纳两行：

```agda
rt₁ : ∀ {n} (i : Fin n) → toFin (fromFin i) ≡ i
rt₁ fzero = refl
rt₁ (fsuc i) = cong fsuc (rt₁ i)
```

右边按索引归纳、每步规约到 `refl`——13 章的「归纳剧本」在这已露雏形。

## 10.2 同名构造子共存：实测的惊喜与陷阱

`zero/suc` 与 `ℕ` 撞名，Agda 竟然允许两家同时 import——构造子按
**期望类型**分派（stdlib 自己就同时开着 `Data.Nat.Base` 和 `Data.Fin.Base`
的 `zero/suc`）：

```agda
open import Data.Nat using (ℕ; zero; suc)
open import Data.Fin using (Fin; zero; suc)

x : Fin (suc zero)
x = zero        -- 期望类型 Fin 1，分派给 Fin 的 zero ✓

y : ℕ
y = suc zero    -- 期望类型 ℕ，分派给 ℕ 的 suc ✓
```

实测编译通过，这是惊喜。陷阱在后面：**在 Fin 里 `suc zero` 不是「1」**。
`Fin` 的 `suc` 改变的是索引，不是数值：

```agda
one : Fin 1
one = suc zero
```

```text
/home/xulun/code/programming/agda/examples/TmpE2.agda:8.11-15: error: [UnequalTerms]
(suc _n_2) != zero of type ℕ
when checking that the expression zero has type Fin 0
```

为什么？`one : Fin 1` 即 `Fin (suc zero)`，`suc` 分支要求参数类型
`Fin zero`——里面根本没有 `zero` 可用（`fz` 只能造 `Fin (suc n)`，造不出
`Fin 0`）。**`Fin 1` 的唯一居民是「数字 0」**；写 `suc zero` 等于要求
「在容量 1 里跳到下一格再取」，越界。心智模型必须掰过来：Fin 的构造子
`zero/suc` 记的是**数数的方式**（从第 0 格起连续跳几步），不是数值运算。
想要数值入口，请用下一节的换算函数。

## 10.3 第二种定义：数值 + 证明，和「双向换算」工具箱

直觉版 `Fin n` 其实是「带界证明的自然数」。09 章的 Σ 正好装它：

```agda
FinNum : ℕ → Set
FinNum n = Σ[ v ∈ ℕ ] v < n

fin→num : ∀ {n} → (i : Fin n) → FinNum n
fin→num i = toℕ i , toℕ<n i          -- toℕ<n 是 stdlib 现成的界证明

num→fin : ∀ {n} → (p : FinNum n) → Fin n
num→fin (v , v<n) = fromℕ< {v} v<n
```

`toℕ : Fin n → ℕ` 是 Forget-the-bound（丢界，保持单射）；`fromℕ<` 反过来
要求你先交出 `v < n` 的证据才发货。两种定义在「逻辑上等价」的意义上等价
（互相可写），但在「计算上」互补：数数版构造便宜、模式匹配自然；数值版
读写直觉、但每次进 Fin 都被迫**当场交不等式证明**。示例里验证具体数值
双向都算得动：

```agda
p2<3 : 2 < 3
p2<3 = s≤s (s≤s (s≤s z≤n))

_ : toℕ (num→fin (2 , p2<3)) ≡ 2
_ = refl
```

手写 `p2<3` 撞到的坑：`2 < 3` 展开是 `suc 2 ≤ 3`（即 `3 ≤ 3`），`s≤s`
每剥一层左右各减一，**要剥三层**。少写一层，报错精确指出账对不上：

```text
/home/xulun/code/programming/agda/examples/Ex10_dependent.agda:108.17-20: error: [UnequalTerms]
0 != 1 of type ℕ
when checking that the expression z≤n has type 1 ≤ 1
```

（`m < n` 定义成 `suc m ≤ n` 的「差一」在这里咬人——15 章起请用判定
过程 `m <? n` + `True`/`toWitness` 自动化，别再手数。）

数值入口家族（实测都在 `Data.Fin.Base`，`#_` 在 `Data.Fin`）：

```agda
i0 i1 i2 : Fin 3
i0 = fzero                    -- 构造子视角
i1 = fsuc fzero
i2 = fsuc (fsuc fzero)

top : Fin 3
top = fromℕ 2                 -- fromℕ : (k : ℕ) → Fin (suc k)，只有 k=2 落在 Fin 3

k0 k2 : Fin 3
k0 = # 0                      -- 带自动越界检查的字面量（决策过程解 0 < 3）
k2 = # 2

_ : toℕ i1 ≡ 1
_ = refl

_ : toℕ top ≡ 2
_ = refl
```

注意 `fromℕ` 的签名 `(k : ℕ) → Fin (suc k)`：它永远只能落在 `Fin (k+1)`，
**天生防越界**（想要 `Fin 5` 里的 2 得请 `inject≤`）。而 `# 2` 最接近
日常写法：字面量 + 类型里已有的界，类型检查期用可判定性自动裁决——
`# 3 : Fin 3` 会当场报错，实测：

```text
/home/xulun/code/programming/agda/examples/TmpE6.agda:7.7-10: error: [UnsolvedMetaVariables]
Unsolved metas at the following locations:
  /home/xulun/code/programming/agda/examples/TmpE6.agda:7.7-10
```

（越界证明的 `True (2 <? 3)` 解不出来，约束悬空——报错形式是
Unsolved metas 而不是「越界了」，读报错要会翻译。）

「第 n 种取值有限」的具象化：`allFin n : Vec (Fin n) n` 恰好列出全部
元素，一条 `refl` 对平账目：

```agda
all3 : Vec (Fin 3) 3
all3 = allFin 3

_ : allFin zero ≡ []              -- Fin 0 的元素个数：0 个，账目对平
_ = refl
```

## 10.4 依赖消除与荒谬模式：不可能状态不可构造

先造一个「对 Fin 分支、返回类型随索引而变」的函数。`safeHead` 是招牌：

```agda
safeHead : ∀ {A : Set} {n : ℕ} → Vec A (suc n) → A
safeHead (x ∷ xs) = x
```

**只有一行。**`[]` 分支呢？`[] : Vec A zero`，配不上参数类型
`Vec A (suc n)`——它*不存在*，所以*不用写*。覆盖率检查器认账：不合法的
输入形状不产生「缺失分支」义务。stdlib 的 `head` 几乎逐字相同
（`Data/Vec/Base.agda` 第 53 行，只是把「非空」写成 `1 + n`）：

```agda
_ : head (10 ∷ 20 ∷ []) ≡ 10
_ = refl
```

反过来，如果你**硬要**给不可能的分支写东西，就要请出荒谬模式 `()`，
声明「这个变量驻留的类型没有任何构造子，此分支不可达」：

```agda
noFin₀ : Fin zero → ⊥
noFin₀ ()

anyFromNothing : ∀ {A : Set} → Fin zero → A
anyFromNothing ()
```

`Fin 0` 是空类型，所以 `()` 一行就是「从假推出一切」（12 章的
`⊥-elim`，你先已经在用它的裸版）。最震撼的一例是 `belowZero`：对
`Fin 1` 分派，`fsuc` 分支**里层的 i 住在 `Fin 0`**——

```agda
belowZero : ∀ {A : Set} → Fin (suc zero) → A → A → A
belowZero fzero x _ = x
belowZero (fsuc ()) _ y
```

`fz` 对 `zero` 索引造不出值、`lsuc` 递归下去撞 `Fin 0`：两条「不可能
索引」的路被一个 `()` 同时堵死。注意第二行**没有 `= y`**——实测规则：
左端一出现 `()`，整个右端必须省略，否则吃警告（且退出码仍是 0，别漏看）：

```text
warning: -W[no]AbsurdPatternRequiresAbsentRHS
The right-hand side must be omitted if there is an absurd pattern,
() or {}, in the left-hand side.
when checking that the clause belowZero (fsuc ()) _ y = y has type
Fin 1 → A → A → A
```

构造子之间互斥同样用 `()` 证：「`fzero` 不等于任何 `fsuc i`」——
它俩类型索引就不兼容，等式本身不可构造：

```agda
fzero≠fsuc : ∀ {n} (i : Fin n) → _≢_ {A = Fin (suc n)} fzero (fsuc i)
fzero≠fsuc i ()
```

这里有个实测小坑：不能把左侧写成 `(fzero : Fin (suc n)) ≢ …`——给
**构造子**加项层类型标注不合法，直接 ParseError（在 `≢` 处炸）。要么
显式 `_≢_ {A = …}` 具名应用，要么让字面量先绑定到 `i0 : Fin 3` 这类
变量再比：

```agda
i0≢i1 : i0 ≢ i1
i0≢i1 ()
```

覆盖率检查是这一切的执法者。写全函数偷懒漏一枝，立刻被点名（实测：
对 `isZero : Fin 2 → Bool` 只写 `isZero fzero = true` 一枝）：

```text
error: [CoverageIssue]
Incomplete pattern matching for isZero. Missing cases:
  isZero (fsuc x)
when checking the definition of isZero
```

`choose2 : A → A → Fin 2 → A` 两枝写满即全函数——在 Fin 上，「分支穷举」
是编译器帮你数出来的，不是靠约定俗成。

## 10.5 index : Fin n → Vector：越界在类型层被拒收

16 章的主角 `Vec A n`（长度钉死在类型里的列表）本章先试手。stdlib 的
`lookup : Vec A n → Fin n → A` 是「安全的下标访问」：

```agda
at : ∀ {A : Set} {n : ℕ} → Fin n → Vec A n → A
at i xs = lookup xs i

v4 : Vec ℕ 4
v4 = 10 ∷ 20 ∷ 30 ∷ 40 ∷ []

i3 : Fin 4
i3 = # 3                          -- 类型检查时自动裁决 3 < 4，通不过就报错

_ : at i3 v4 ≡ 40
_ = refl
```

想要 `Vec A n → Fin n → A`（stdlib 原序）还是反过来先索引？实测发现
**依赖参数的顺序会左右报错形态**：`at` 先吃 `Fin n`，n 立刻被索引钉死，
向量长度必须吻合。把 `i2 : Fin 3` 配 `v4 : Vec ℕ 4`：

```text
/home/xulun/code/programming/agda/examples/TmpD2.agda:17.11-13: error: [UnequalTerms]
4 != 3 of type ℕ
when checking that the expression v4 has type Vec ℕ 3
```

「索引 3 想进长度 4 的向量」——在 Haskell 里这是合法表达式加越界运气，
在 Agda 里这是**类型方程 4 = 3 不成立**。「不可能的状态无法构造」从口号
变成了报错行。

## 10.6 一个模块名引发的血案：natToFinBound 已经没了

搜到的老教程常写 `open import Data.Fin using (natToFinBound)`。2.3 实测：
**这个名字已不存在**，对应功能拆成了 `fromℕ`（`k → Fin (suc k)`）、
`fromℕ<`（带证进 Fin）、`inject≤`（沿 `m ≤ n` 垫宽索引）：

```agda
_ : toℕ (inject≤ {n = 5} i2 (s≤s (s≤s (s≤s z≤n)))) ≡ 2
_ = refl
```

更要命的是 import 阶段的报错形态——**只是 warning，退出码 0**：

```text
warning: -W[no]ModuleDoesntExport
The module Data.Fin doesn't export the following:
  natToFinBound
```

CI 只看退出码会一路绿灯，直到你**使用**这个名字才 `NotInScope` 炸雷。
所以本项目反复强调：import 清单一律以编译通过为准，不背旧名字。

练习路线（亲手做一遍，胜过读十遍）：

1. 只用 `fzero/fsuc` 构造 `Fin 4` 的四个元素，各配一条 `toℕ` 验证 refl；
2. 证 `¬Fin₀ : (x : Fin zero) → x ≡ x → ⊥`——答案仍是一行 `()`；
3. 仿 `rt₁` 再证 `rt₂ : ∀ {n} (i : FinOld n) → fromFin (toFin i) ≡ i`
   （示例已给），体会「对索引归纳」和普通结构归纳在此时还分不太清——
   13 章它会露出獠牙。

## 10.7 坑位清单（本项目实测）

1. **stdlib 2.3 的 Fin 构造子叫 `zero/suc`，`fz/lsuc` 未导出**；与
   `Data.Nat` 同名构造子可共存、按期望类型分派，但建议 import 时
   `renaming (zero to fzero; suc to fsuc)` 保命。
2. **`suc zero : Fin 1` 编译失败**（实测 UnequalTerms，见 10.2）：Fin 的
   `suc` 是「换到更大的索引」不是「数值加一」；`Fin 1` 只有值 `zero`（数 0）。
3. **`natToFinBound` 在 2.3 已删除，且 using 不存在的名字只给 warning、
   退出码仍为 0**——真正炸点是使用处 `NotInScope`。用 `fromℕ / fromℕ< /
   inject≤` 组合替代。
4. **左端出现 `()` 时右端必须整个省略**（`AbsurdPatternRequiresAbsentRHS`
   警告；同样注意：警告不改退出码）。
5. **构造子不能带项层类型标注**：`(fzero : Fin (suc n)) ≢ …` 是
   ParseError；改 `_≢_ {A = Fin (suc n)} fzero (fsuc i)`，或先绑成变量。
6. **`# k` 越界的报错长得很间接**：不是「越界」二字而是
   `UnsolvedMetaVariables`（界证明约束解不出来）。
7. **`fromℕ k : Fin (suc k)`**：想要 `Fin n`（n 更大）里的 k，必须再过一道
   `inject≤`，别忘了它。
8. **手写 `s≤s/z≤n` 层数极易差一**（`2 < 3` 是 `3 ≤ 3` 要剥三层，实测
   报错 `0 != 1`）；工程上换 15 章的 `_<?_` + `toWitness`。
9. **依赖参数顺序 = 统一顺序**：`at : Fin n → Vec A n → A` 里 n 被先到的
   索引钉死，向量长度不配就 `4 != 3`；stdlib 的 `lookup` 先吃向量就没这烦恼。

---
上一章：[09 · 记录与 Σ 类型](09-records.md) ｜ 下一章：[11 · 命题等式](11-equality.md) ｜ 返回：[README](../README.md)
