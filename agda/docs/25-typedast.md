# 25 · 实战：类型良好表达式解释器

前面 24 章的工具终于凑齐一副牌：`Fin n` 当证据（10 章）、依赖记录与
异构表（9/16 章）、等式推理与归纳（11/13/14 章）、可判定比较（15 章）。
本章用一门小语言把它们全部打出去——一个表达式解释器，走「四段进化」：
先写 coq/lean 教程同款的朴素 AST，亲眼看 `true + 1` 如何大摇大摆通过
检查、在求值器里被私吞；升级「良 scoped」版（变量是 `Fin n`，越界不可
构造）；再升级「良 typed」版（上下文是类型表，`bool` 想进 `plus` 的
槽位在**类型检查期**撞车）；最后加一个常量折叠 pass，证一把
`eval (optimize t) ≡ eval t`——这一步类型帮不上忙，得请出 13 章的
归纳法。这一章是「构造即正确」的验收现场，剧透结论：**依赖类型买断的
是「结构非法」，「语义等价」仍然要自己付钱**。同题材的 coq 教程 19 章
走事后证明路线（`../coq/docs/19-ast.md`），文中两处点名对照。

对应示例：`../examples/Ex25_typedast.agda`（全部报错为 Agda 2.8.0 +
stdlib 2.3 实测输出）

## 25.1 朴素版：什么都能写，坏案子运行期才炸

coq/lean 教程的 AST 长这样——数、布林、加法、判零、条件全混在**同一
条数据定义**里：

```agda
data Exp : Set where
  nnum : ℕ → Exp
  nbool : Bool → Exp
  nplus : Exp → Exp → Exp
  niszero : Exp → Exp
  ncond : Exp → Exp → Exp → Exp      -- 条件、then、else
```

注意 `nplus : Exp → Exp → Exp`：它不收「nat 型表达式」，收的是**任意
表达式**。于是 `true + 1` 是合法项，构造毫无门槛，求值前先造一个把数
和布林塞在一起的「值宇宙」：`data V : Set where` 分支 `vℕ : ℕ → V`
与 `vB : Bool → V`。

灾难从这里开始。求值器必须处理**所有**输入，包括类型上压根不该出现
的组合，唯一办法是私吞；而且因为类型没收住，覆盖率检查还**强迫**你为
永远到不了的分支写代码——`eval♮ (ncond c a b)` 对条件值 `with` 展开，
数制值分支 `... | vℕ n = vℕ n` 不可达也得留着：

```agda
plusV : V → V → V
plusV (vℕ m) (vℕ n) = vℕ (m + n)
plusV _ _ = vℕ zero                  -- true + 1 = 0？没人规定过，编的

isZeroV : V → V
isZeroV (vℕ m) with m ≟ zero
... | yes _ = vB true
... | no _ = vB false
isZeroV _ = vB false                 -- iszero true？又编一个
```

最可怕的还不是「算错」，而是**它能算完**（示例里的
`bad₁ = nplus (nbool true) (nnum 1)`）：

```agda
_ : eval♮ bad₁ ≡ vℕ zero             -- true + 1 = 0，静默吞 bug
_ = refl
```

`refl` 通过，说明求值器老老实实把垃圾式子约到了 `vℕ zero`——没有报错、
没有 `nothing`、没有任何痕迹；类型系统的失守最后都变成运行期代码里的
赘肉。coq 教程 19 章的药方是：求值返回 `option`，或全函数 + 事后正确
性定理兜底。Agda 的路线更激进：升级**语法本身**，让坏式子不可构造。
下一节先治一半——变量作用域。

## 25.2 升级一：良 scoped——变量是 `Fin n`（10 章回收）

10 章说过 `Fin n` 是「小于 n 的证明」，现在兑现伏笔——把「表达式里有
几个自由变量」写进类型：

```agda
data Tm : ℕ → Set where
  var : ∀ {n} → Fin n → Tm n
  num : ∀ {n} → ℕ → Tm n
  plus : ∀ {n} → Tm n → Tm n → Tm n
```

`Tm n` 读作「最多引用 n 个变量的项」，下标 0 = 最内层绑定（de Bruijn
风格）。求值器接收的环境是 16 章的 `Vec ℕ n`：

```agda
eval₀ : ∀ {n} → Tm n → Vec ℕ n → ℕ
eval₀ (var i) ρ = lookupV ρ i
eval₀ (num m) ρ = m
eval₀ (plus a b) ρ = eval₀ a ρ + eval₀ b ρ
```

三行，**没有 `Maybe`、没有错误分支**——`Fin 0` 没有居民，`n = 0` 的
`var` 分支不存在，覆盖率检查认可它不可能被调用。「忘绑定就引用」整族
bug 不可表达。空作用域里能写什么？`closed : Tm zero` 只剩
`plus (num 1) (num 2)` 可挑。硬要越界？实测报错（在空上下文构造
`var fzero`）：

```
error: [UnequalTerms]
Agda.Builtin.Nat.Nat.suc _n_1 != Agda.Builtin.Nat.Nat.zero of type
Agda.Builtin.Nat.Nat
when checking that the expression fzero has type Fin 0
```

看不懂报错里的内部名不要慌，抓最后一句「`fzero` has type `Fin 0`」。
良 scoped 版还白送两件真正编译器的日常工具：闭包扩大 `weaken :
∀ {n} → Tm n → Tm (suc n)`（var 分支一行 `var (fsuc i)`，其余逐层递归）
与代换 `sub : ∀ {n} → Tm (suc n) → Tm n → Tm n`——var 的两个分支
`sub (var fzero) t = t`、`sub (var (fsuc i)) t = var i` 由构造子模式
自动完成「是不是被代换的那个变量」的判定，**模式匹配即决策**，没有
运行期查表（对比 coq 教程的字符串名 + `update` 写法）。两条配套定律
是本章第一顿免费午餐：`weaken-lemma`（`eval₀ (weaken t) (x ∷ ρ) ≡
eval₀ t ρ`）与 `sub-lemma`（`eval₀ (sub t u) ρ ≡ eval₀ t (eval₀ u ρ ∷
ρ)`），示例里各四行，var/num 分支全 `refl`、plus 分支一次 `cong₂`——
13 章「对称归纳假设」的甜头：归纳陈述里类型与下标同步推进，两边在
同一处化简。数值小例子（`t₂ = plus (var fzero) (var (fsuc fzero)) :
Tm 2`）：三条全 `refl`——`eval₀ t₂ (10 ∷ 20 ∷ []) ≡ 30`、
`eval₀ (sub t₂ (num 7)) (20 ∷ []) ≡ 27`、
`eval₀ (sub (sub t₂ (num 7)) (num 8)) [] ≡ 15`。

但这一版还留着 25.1 的老病：`Tm n` 里**所有项都是 nat 表达式**——
想加布尔就得把 bool 塞进同一条 `Tm`，值宇宙和垃圾分支卷土重来。

## 25.3 升级二：良 typed——上下文是类型表（16 章回收）

语法升级为依赖家族 `TExp Γ τ`：「在上下文 Γ 中，此式类型为 τ」。先
备料：类型宇宙、按类型取值的 `Val`、以及「τ 在 Γ 中出现」的证据：

```agda
data Ty : Set where
  bool nat : Ty

Val : Ty → Set
Val bool = Bool
Val nat = ℕ

infix 4 _∈_
data _∈_ : Ty → List Ty → Set where
  here : ∀ {τ Γ} → τ ∈ τ ∷ Γ
  there : ∀ {τ σ Γ} → τ ∈ Γ → τ ∈ σ ∷ Γ
```

`_∈_` 是 de Bruijn 版的 `Fin`，但它**自带内容**：`here` 是一枚
「头部的类型正是 τ」的证据。上下文实例化——环境按类型表逐项配值，
`Vec` 同一套路的异构表（9 章积 × 16 章索引化的合体）：

```agda
Inst : List Ty → Set
Inst [] = ⊤
Inst (τ ∷ Γ) = Val τ × Inst Γ
```

查表 `lookupInst : ∀ {Γ τ} → τ ∈ Γ → Inst Γ → Val τ` 两行
（here 取头、there 剥一层递归），示例 25.3。语法本体，三处手术刀：

```agda
data TExp : (Γ : List Ty) → Ty → Set where
  var : ∀ {Γ τ} → τ ∈ Γ → TExp Γ τ
  num : ∀ {Γ} → (n : ℕ) → TExp Γ nat
  bval : ∀ {Γ} → (b : Bool) → TExp Γ bool
  plus : ∀ {Γ} → TExp Γ nat → TExp Γ nat → TExp Γ nat
  iszero : ∀ {Γ} → TExp Γ nat → TExp Γ bool
  if_then_else_ : ∀ {Γ τ} → TExp Γ bool → TExp Γ τ → TExp Γ τ → TExp Γ τ
```

三处手术刀：`plus`/`iszero` 的参数与结果类型焊死（nat 进 nat 出 /
nat 进 bool 出）；`if` 的条件必须是 `TExp Γ bool`，then/else 共享
同一结果索引 τ；`var` 的返回类型由 `_∈_` 证据决定——查得到才有类型。
求值器是全章高光（`isz : ℕ → Bool` 两行定义见示例）：

```agda
eval : ∀ {Γ τ} → TExp Γ τ → Inst Γ → Val τ
eval (var p) ρ = lookupInst p ρ
eval (num n) ρ = n
eval (bval b) ρ = b
eval (plus a b) ρ = eval a ρ + eval b ρ
eval (iszero e) ρ = isz (eval e ρ)
eval (if c then a else b) ρ = Data.Bool.if_then_else_ (eval c ρ) (eval a ρ) (eval b ρ)
```

返回类型是 `Val τ`，**不是** `Maybe (Val τ)`：良类型源项的求值永不
失败，一个错误分支都不需要。对照 25.1 的第三条分支——垃圾分支删不掉
是因为类型没分家；现在垃圾进不了定义域，函数反而变短了。

那 `true + 1` 呢？它现在连**占位符都填不进**。实测（`bad₁ =
plus (bval true) (num 1)`，要求 `TExp [] nat`）：

```
/home/xulun/code/programming/agda/examples/Tmp25err.agda:36.14-23: error: [UnequalTerms]
bool != nat of type Ty
when checking that the inferred type of an application
  TExp [] bool
matches the expected type
  TExp [] nat
```

`bval true` 唯一可能的类型是 `TExp Γ bool`，`plus` 的第一参数槽要
`TExp Γ nat`——索引在**类型检查期**硬碰硬。这正是与 coq 教程 19 章的
世界观分歧：Coq 的 `aexp` 是单层归纳类型，「良类型」是求值之后用命题
**事后**圈出来的；Agda 把类型信息前置成索引，非法项在**构造时**就被
拒。小语言前验便宜，大语言（类型推导、子类型）前验写不动，各取所需。

上下文加宽 `extend : ∀ {Γ τ σ} → TExp Γ τ → TExp (σ ∷ Γ) τ` 是良
scoped 版 `weaken` 的类型镜像——var 分支一行 `var (there p)`，其余
逐层递归（示例 25.3）。`Inst Γ` 也能换成函数表形式，回收 16 章
`Data.Vec.Functional`（`Vector A n = Fin n → A`）的思路，依赖版就是
把常数 `A` 换成「按位置算类型」：

```agda
InstΠ : List Ty → Set
InstΠ Γ = (i : Fin (length Γ)) → Val (lookupL Γ i)
```

示例里给了互转 `toΠ`/`fromΠ` 与一条样例往返
`fromΠ {Γ = nat ∷ []} (λ { fzero → 3 }) ≡ (3 , tt)`（`refl`）。
`InstΠ` 路线可行但处处要 `length`/`lookup` 索引换算；本书主路线选
`_∈_` + `×`，把换算税降到最低，两者求值器等价。两个小程序类型全对、
求值全通：

```agda
demo₁ : TExp (nat ∷ bool ∷ []) bool
demo₁ = if iszero (var here) then var (there here) else bval false

-- x ≟ 0 真则取 bool 变量，假则 false：(0,true) → true；(5,…) → false
_ : eval demo₁ (0 , true , tt) ≡ true
_ = refl

_ : eval demo₁ (5 , true , tt) ≡ false
_ = refl
```

`there here : bool ∈ nat ∷ bool ∷ []`——证据链完整；写错成 `var here`
想取 bool？索引当场撞车，报错同上。

## 25.4 优化 pass：常量折叠——类型保形免费，语义等价要证

最后一关：加一个优化器（0+x 折叠、常数加法预计算、死分支删除），并
回答「优化不改语义」。设计沿用 coq 教程 19 章的 **smart constructor**：
折叠规则放进构造侧小函数，`optimize` 保持纯结构递归。反面教材是把
嵌套模式直接写进 `optimize`——证明时子项是变量、match 卡住，得穷举
全部构造子做模式体操（coq 19.3 的实测教训）。

```agda
optPlus : ∀ {Γ} → TExp Γ nat → TExp Γ nat → TExp Γ nat
optPlus (num m) (num n) = num (m + n)
optPlus (num zero) b = b
optPlus a b = plus a b

optimize : ∀ {Γ τ} → TExp Γ τ → TExp Γ τ
optimize (var p) = var p
optimize (num n) = num n
optimize (bval b) = bval b
optimize (plus a b) = optPlus (optimize a) (optimize b)
optimize (iszero e) = optIszero (optimize e)
optimize (if c then a else b) = optIf (optimize c) (optimize a) (optimize b)
```

`optIszero`（`iszero 0 ↦ bval true`、`iszero (suc _) ↦ bval false`）
与 `optIf`（死分支删除）在示例里同配方。两个设计点。其一，
`optimize` 的签名 `TExp Γ τ → TExp Γ τ`：**折叠不可能把 nat 项变成
bool 项**——不是证出来的，是类型签名白送的。其二，为什么不折
`e + 0 ↦ e`？`_+_` 只按左参数化简（16 章坑位 4），`m + zero ≡ m` 要
用 `+-identityʳ` 还得 `sym` 过来，引理的 case 分析翻倍——16.4 章的
索引算术在这里继续收税。折叠先算给你看（`refl`）：

```agda
demo₂ : TExp (nat ∷ []) bool
demo₂ = if iszero (plus (num zero) (var here))
        then bval true
        else bval false

_ : optimize demo₂ ≡ if iszero (var here) then bval true else bval false
_ = refl
```

（`e₁ : TExp [] nat` 取 `plus (num 2) (num 3)` 则 `optimize e₁ ≡
num 5`。注意 `e₁` 要先用注解绑定再喂给 `optimize`——
`optimize (…) {Γ = []}` 这种「对非函数应用隐式参数」的写法实测
`CannotApply`。）

然后是账单大头：证明。三个智能构造子各有一条局部正确性引理。以
`optPlus` 为例，理想写法当然是一条：

```agda
optPlus-correct (num zero) b ρ = refl     -- 想当然版，实测不过
```

实测报错：

```
/home/xulun/code/programming/agda/examples/Tmp25err.agda:49.32-36: error: [UnequalTerms]
optPlus (num zero) b != plus (num zero) b of type TExp Γ nat
when checking that the expression refl has type
optPlus (num zero) b ≡ plus (num zero) b
```

第二参数是**变量**时，`optPlus (num zero) b` 走第二条还是第三条子句
不确定，归约卡死。解法是把 b 拆成构造子形态——而拆的时候又撞上第二条
实测：想给 `b : TExp Γ nat` 写一条 `iszero e` 子句（bool 型构造子塞
nat 位置），编译器直接判：

```
/home/xulun/code/programming/agda/examples/Tmp25err.agda:49.29-37: error: [ImpossibleConstructor.UnifyConflict]
The case for the constructor iszero is impossible
because unification ended with a conflicting equation
  bool ≟ nat
Possible solution: remove the clause, or use an absurd pattern ().
when checking that the pattern iszero e has type TExp Γ nat
```

——**类型索引连枚举都要管**，nat 位置根本不可能站着 `iszero`。最终
`optPlus-correct` 收 10 个子句、全部 `refl`（`optIszero-correct` 5 条、
`optIf-correct` 5 条同配方，见示例）：

```agda
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
```

体力活，但正是「定义计算」付的税。主定理 `opt-eval` 就藏不住了——
钻到子项必须请出归纳假设：

```agda
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
```

14 章 `≡-Reasoning` 标准剧本：首步局部引理剥 smart constructor，中段
两条归纳假设 `cong₂` 抬进加法，收尾纯定义展开。`iszero` 分支同构
（`cong isz`）；`if` 分支稍作变奏——条件换值、分支换值各一次
`cong`/`cong₂`，中间用 lambda 把「若 v 则…」固定成一张契约（示例
25.4 有完整三条链）。**refl 从第 4 个分支开始就不够用了**——这就是
「类型管结构、归纳管语义」的分工线。

算账收尾。免费拿到的：`eval` 永不失败（返回类型没有 `Maybe`）；
`true + 1`、未绑定变量、越界下标不可构造（25.2/25.3 两条实测报错）；
`optimize` 类型保形；`weaken`/`extend` 两条代换定律与全部 `refl` 级
数值示例。必须自己挣的：`eval (optimize t) ρ ≡ eval t ρ`——语义等价
没有免费的，25.4 的等式链和 20 条子句就是账单；一切「换表示」类等价
（`toΠ`/`fromΠ` 完全往返律）同样要自己做 `Fin` 引理。一句话：**依赖
类型吃的是「结构非法」的免费午餐，「语义等价」得自己付钱。**

## 25.5 本章小结

`Exp`（单 Set 混值）挡住零个 bug、静默吞一切；`Tm n`（索引 = 作用域
大小）挡住越界与未绑定；`TExp Γ τ`（索引 = 上下文 + 类型）挡住类型
错配——三版都挡不住「语义等价」。「构造即正确」的边界就此摸清：类型
检查器替你把关的永远是**可判定的结构性质**；问题一旦变成「这两个程序
等价吗」，就回到 13/14 章的归纳与等式链。下一章换一块战场：把同一套
思想用在算法上——可验证插入排序。

## 25.6 坑位清单（本章实测）

1. **导入与同名分派三连**：① `using (lookup) renaming (lookup to
   lookupV)` 实测 `RepeatedNamesInImportDirective`——改名就别在
   `using` 里再列原名；② 自定义构造子 `if_then_else_` 与 `Data.Bool`
   函数重名，实测 `ClashingDefinition`——别 open，需要 Bool 那份写全名
   `Data.Bool.if_then_else_`；③ 环境用 `Vec ℕ n` 时必须从 `Data.Vec`
   导入 `[]`/`_∷_`，否则 `∷` 被判成 List 的那一个（16 章坑位 1 再现）。
2. **变量参数让 smart constructor 归约卡住**：引理里第二参数写成变量
   `b` 时 `optPlus (num zero) b` 不知道走哪条子句，`refl` 实测
   `UnequalTerms: optPlus (num zero) b != plus (num zero) b`——必须
   枚举构造子形态（25.4）。
3. **枚举别超出类型索引的可能**：给 `TExp Γ nat` 的位置写 `iszero e`
   子句，实测 `ImpossibleConstructor.UnifyConflict: bool ≟ nat`，
   提示「use an absurd pattern ()」反而说明编译器早就算过这笔账。
4. **`≡-Reasoning` 续行必须缩进**：`≡⟨ … ⟩` 和 `∎` 顶格写会被判成新
   子句，实测布局连环爆错——每行前留一个空格，比 `begin` 起始列齐平
   或更浅都不行。
5. **模式里写中缀构造子要还原全形态**：`optimize (if c c₁ c₂)` 实测
   `NoParseForLHS`——声明过的 `if_then_else_` 在 LHS 必须写全
   `if c then c₁ else c₂`。
6. **隐式参数不能「事后补」**：`optimize (plus …) {Γ = []}` 实测
   `CannotApply`（`optimize` 的结果不是函数）；想要具体上下文就先把
   项注解好再绑定（示例里的 `e₁ : TExp [] nat`）。

---
上一章：[24 · 立方类型论初步](24-cubical.md) ｜ 下一章：[26 · 实战：可验证插入排序](26-sorting.md) ｜ 返回：[README](../README.md)
