# 28 · 坑清单与最佳实践

这是全书的「防雷手册」：**写代码前先查它**。前 27 章每章末尾都有实测坑位小节；
本章把它们去重、归类、汇总成总清单，并为本章另跑 16 项**重新实测**（标〔实测〕：
在 `examples/` 下临时建 `Probe28*.agda` 探针、用 agda 2.8.0 + stdlib 2.3 逐条跑出
真实报错后删除）。共 106 条，按主题分八节；每条给**坑名 → 报错/现象 → 正确姿势 →
涉及章节**。用法：新报错先按标签（如 `UnsolvedMetaVariables`）在本页搜；动手写
某类代码前把对应小节通读一遍。全部坑位的共同底纹是——

> **Agda 的退出码 0 只代表「没有 error」，不代表「没有事故」。**
> `ModuleDoesntExport`、`UnreachableClauses`、`RewritesNothing` 统统不拦 CI。

对应示例：无（本章为清单章；各条报错的复现代码见所引章节的示例与正文）。

## 28.1 工具链与库（1–12）

**1 · 一个目录只许一个 `.agda-lib`**
- 现象：多放一个，该目录下**所有**文件检查直接 `[LibraryError] may contain only one .agda-lib file`，显式 `-l` 也救不了。姿势：每个项目根只留一个库定义文件。→ [02 工具链](02-toolchain.md)

**2 · 大写 `DEPENDS:` 是哑字段**
- 现象：只报 `LibUnknownField` 警告就被**忽略**，依赖静默丢失，表现为「明明写了 depend 却 `FileNotFound`」。姿势：字段名小写 `depend:`（`include:` 同理全小写）。→ [02](02-toolchain.md)

**3 · `agda -l 库名` 不带当前目录**
- 现象：`-l standard-library-2.3 file.agda` 报 `[ModuleNameDoesntMatchFileName]`，报错方向和病因完全对不上。姿势：`-l` 必配 `-i.`；或像本项目一样用 `.agda-lib` 的 `include: examples` 一把搞定。→ [02](02-toolchain.md)

**4 · `--ignore-interfaces` 在 Debian 安装上炸权限**
- 现象：试图回写只读的 `/usr/share/agda-stdlib/_build`，permission denied，退出码 42。姿势：干净重检请删项目自己的 `_build/`（`./build.sh clean`），别碰这个选项。→ [02](02-toolchain.md)

**5 · `--emacs-mode=locate` 给假路径**
- 现象：打印 `/usr/share/libghc-agda-dev/emacs-mode/agda2.el`，此文件不存在。姿势：apt 装的 elpa 包真实在 `/usr/share/emacs/site-lisp/elpa-src/agda2-mode-2.8.0/`。→ [02](02-toolchain.md)

**6 · 交互选项已换代**
- 现象：`--interaction-mode` 直接 `Unrecognized option`；`--interaction` 拒绝文件参数（退出码 71，文件名只能出现在 `Cmd_load` 命令串里）。姿势：照 2.8 手册配编辑器，老教程的 `--interaction-mode` 一行删掉。→ [02](02-toolchain.md)

**7 · 带孔文件过不了命令行检查；缓存命中又全静默**
- 现象：留 `?` 的检查报 `[UnsolvedInteractionMetas]`；重复检查未改动的文件**零输出**退出 0。姿势：提交前清孔；「没输出」≠「没跑」，看有没有 `Checking ...` 行。→ [02](02-toolchain.md)

**8 · `--compile` 产物跟着源文件走**
- 现象：可执行文件生成在 `examples/ExNN_xxx`、中间 Haskell 在 `examples/MAlonzo/`，不在当前终端目录。姿势：脚本与 `.gitignore` 按实测位置写；要控制位置用 `--compile-dir=DIR`。→ [02](02-toolchain.md)

**9 ·〔实测〕`--compile` 没有 `main` 也「成功」**
- 现象：编译一路走完，只吐一条 GHC 警告 `No main function defined in Probe28e.`，**不生成可执行文件**（`ls` 才见真相），退出码不设防。姿势：编译后必须 `ls` 产物或跑一次冒烟。→ [20 IO](20-io.md)

**10 ·〔实测〕顶层重名是 `ClashingDefinition`**
- 现象：`Multiple definitions of x. Previous definition at …`，直接点名前一定义坐标。姿势：这是最好读的报错之一——但发生在 scope 阶段，先于一切类型检查。→ [03 第一个文件](03-basics.md)

**11 ·〔实测〕模块自引用/循环：`CyclicModuleDependency`**
- 现象：`cyclic module dependency: Probe28m importing Probe28m`（自己 import 自己、A↔B 互依都拦）。姿势：Agda 模块层没有 mutual；公共部分下沉到第三个模块。→ [02](02-toolchain.md)

**12 ·〔实测〕OPTIONS 拼错是硬错**
- 现象：`{-# OPTIONS --safee #-}` 报 `[OptionError] Unrecognized option: --safee (did you mean --safe ?)`。姿势：文件首行选项没有「静默忽略」这一档，改对为止；did you-mean 值得信。→ [02](02-toolchain.md)

## 28.2 语法与记号（13–29）

**13 · 模块名不能以数字开头**
- 现象：`module 01_intro` 直接 `[ParseError]`（数字前缀被当字面量）。姿势：全书用 `ExNN_name` 前缀。→ [01 认识 Agda](01-intro.md)

**14 · 顶层模块名必须等于文件名**
- 现象：`[ModuleNameDoesntMatchFileName]` 并甩一长串候选路径（include 里有标准库时更吓人）。姿势：复制模板文件时先改这两处再写内容。→ [01](01-intro.md)

**15 · 「下划线+关键字」标识符词法非法**
- 现象：`module Ex04_syntax` 报 `the part syntax is not valid because it is a keyword`；`module Ex22_codata` 同款（`codata` 也是关键字——下划线分段的**每一段**都不得是关键字）。姿势：撞关键字就换连字符（`Ex04-syntax`、`Ex22-codata`，stdlib 同款先例 `∃-syntax`）。→ [03](03-basics.md) [04 记号](04-syntax.md) [22 余归纳与无限流](22-codata.md)

**16 · 默认 fixity 是 infix 20 不可结合**
- 现象：忘声明 fixity 的中缀名连用两次就 `NoParseForApplication`，附一张「Operators used in the grammar」表。姿势：每个新中缀定义后紧跟 fixity 声明；读该表先看 level 再看坐标。→ [04](04-syntax.md)

**17 ·〔实测〕同算子两次 fixity 声明冲突**
- 现象：`infixl 6 _⊕_` 之后再来 `infixr 6 _⊕_`，报 `[MultipleFixityDecls] Multiple fixity or syntax declarations for _⊕_: infixl 6 infixr 6`。姿势：一处声明管全文，别在两节各写一份。→ [04](04-syntax.md)

**18 · 没有 `nonassoc`**
- 现象：`nonassoc 6 _⊘_` 被当普通函数名应用，报 `Missing type signature for left hand side`。姿势：要不可结合就写 `infix`。→ [04](04-syntax.md)

**19 · 同级别不同结合性不能相邻**
- 现象：infixl 7 与 infixr 7 同级连用直接无法解析。姿势：新记号先在 stdlib 级别地图占坑（≡/≤ᵇ 4、++ 5、+ 6、* 7、if_then_else_ 0）；低级别子式进高级别尾槽必加括号（中洞 `◃ ▹` 例外宽松）。→ [04](04-syntax.md)

**20 · 级别 0 是贪婪吞噬**
- 现象：`if b then 1 else 2 ≡ 2` 里 else 槽吞下整条等式，症状却是类型层 `Set !=< ℕ`。姿势：先补括号，再怀疑类型。→ [04](04-syntax.md)

**21 · `syntax` 左边只收无洞简单名**
- 现象：给 `_∋_` 这类带洞名或 `M.f` 限定名直接拒（stdlib 注释原话：syntax cannot contain underscores）。姿势：先包一个无洞别名再 syntax；优先级继承左名的 fixity。→ [04](04-syntax.md)

**22 · import ≠ open ≠ using；且 import 不早于用法**
- 现象：`import M` 后裸名仍 `[NotInScope]`；文件中途才 import，之前的用法全挂且报 NotInScope 而不是「位置不对」。姿势：import 一律置顶；限定访问 `M.f` 是 import 唯一的免费效果。→ [01](01-intro.md) [03](03-basics.md)

**23 · 顶层声明前向引用也报 NotInScope**
- 现象：顶层定义/签名引用**其后**才声明的名字，报 `Not in scope: k`——Agda 按声明顺序解析，不是「函数随便互相引用」。姿势：把被引用者前移，或跨顺序互引用显式包 `mutual` 块（模块层没有 mutual，见 11 条；这是定义层的事）。→ [22](22-codata.md)

**24 · import 指令三连坑**
- 现象：`using`+`hiding` 同表 → `UselessHiding` 且 hiding 被无视；`using (x) renaming (x to y)` → `RepeatedNamesInImportDirective` 硬错；`using` 列不存在的名字 → 只 `ModuleDoesntExport` **警告**、退出码照 0，炸点推迟到使用处。姿势：合法组合只有「using+renaming（不同名）」和裸 hiding。→ [04](04-syntax.md) [13 归纳证明](13-induction.md)

**25 · 同名歧义在「用」时爆**
- 现象：`AmbiguousName` 列出全部候选与来源；重排 import 行序没用。姿势：用 hiding/renaming 在声明处消歧；双 ⊤（`Data.Unit` vs `Data.Unit.Polymorphic`）是经典案发现场。→ [04](04-syntax.md) [20](20-io.md)

**26 · Emacs 输入表别背老教程**
- 现象：`\oo` 打出 ⊚ 而不是 ∞（`\inf` 才是 ∞）；`\bN`→ℕ、`\Gl`→λ 因版本而异。姿势：以本机 `agda-input.el` 与 `M-x customize-group agda-input` 为准；文档首现符号补 ASCII 说明。→ [04](04-syntax.md)

**27 ·〔实测〕Coq/Lean 习惯的 `∀ x . P` 在这里是病句**
- 现象：`bad : ∀ (n : ℕ) . (n ≡ n)` 报 `[ParseError] =<ERROR>`，点被当非法 token。姿势：Agda 的 Π 结束符是 `→`：`∀ (n : ℕ) → n ≡ n`；跨助手迁移先过 04 章记号表。→ [12 逻辑连接词](12-logic.md)

**28 ·〔实测〕where 块缩进错一格 = 全文崩塌**
- 现象：块内第二个定义比第一个多缩进，`=<ERROR> n` 指到无关 token；坐标用点分隔（`6.8`）。姿势：where/let/mutual 块内所有定义**同一列起步**；布局报错先整块重排缩进再找语义。→ [03](03-basics.md) [09 记录与 Σ](09-records.md)

**29 · 运算符名的下划线数就是名字本身**
- 现象：`_*` 与 `_*_` 一字之差、`_+_′` 这类「素号挂尾」的名字，using 清单与定义处稍有出入就连环 `ModuleDoesntExport`+`NotInScope`。姿势：下划线数量逐字符对。→ [08 列表](08-lists.md)

## 28.3 类型、宇宙与数据建模（30–45）

**30 · 宇宙不累积**
- 现象：`Bool : Set₂` 报 `Set != Set₂`——`Bool : Set₀` 不会「自动升上来」。姿势：跨层用显式宇宙多态或 `Lift`，别指望子类型。→ [05 类型系统与宇宙](05-universes.md)

**31 · `Setω` 有三张面孔**
- 现象：要 `import Agda.Primitive` 才有；只配给 datatype 当排序（`Set : Setω` 实测被拒）；它自己的类型还要高一格（`Setω : Setω` 报 `Setω₁ != Setω`）。姿势：日常代码根本不碰它，见到就当读库信号。→ [05](05-universes.md)

**32 · 构造子装不下高层参数**
- 现象：`data Vec : Set → ℕ → Set` 报 `[ConstructorDoesNotFitInData]`。姿势：把 `A` 提成参数或做宇宙多态；报错提示的 `--large-indices` 是逃生舱不是正门。→ [05](05-universes.md)

**33 · 裸写 `Set a` 前忘 `variable` 块**
- 现象：`[NotInScope] a`。姿势：层级自动泛化以 `variable a : Level` 声明为前提。→ [05](05-universes.md)

**34 · `open import Level` 全家桶截胡**
- 现象：它把 `lzero/lsuc` 改名导出成 `zero/suc`，和 `Data.Nat` 共开时数字构造子被宇宙层抢走。姿势：精确 `using`。→ [05](05-universes.md)

**35 · 隐式参数两条铁律**
- 现象：不出现在可见类型里的隐式参数解不出（`UnsolvedMetaVariables`）；候选不唯一的构造子（`[]`、`refl`）裸调用卡 `UnsolvedConstraints`。姿势：补标注 `{A = …}` 或换带索引的签名。→ [05](05-universes.md)

**36 · 没有项级类型标注 `(e : T)`**
- 现象：`pure (42 : ℕ)`、`([] : List ℕ)` 都是 `ParseError`。姿势：冒号只属于签名行；定隐式参数写 `pure {A = ℕ} 42`、`length {A = ℕ} []`，顶层签名标注救不了裸空表。→ [08](08-lists.md) [20](20-io.md)

**37 · `[1,2,3]` 字面量在 2.8 根本不存在**
- 现象：`Not in scope: [`；而 `[ 1 , 2 ]` 竟是「装了一个二元组的单元素表」——逗号来自 `Data.Product`，类型全对、语义全错。姿势：链式写 `1 ∷ 2 ∷ []`；方括号只有 `Data.List` 的**单元素** `[_]` 记法与 `fromList`。→ [08](08-lists.md)

**38 · 方括号/Σ 括号都是「具名记号」，不 import 就没有**
- 现象：`[ x ]` 记号须 `using ([_])`；`Σ[ x ∈ A ] B` 须 `using (Σ-syntax)`，漏了就是 NotInScope 而不是「括号打错」。姿势：见到想要的记法，先查它住在哪个模块、叫什么名字。→ [09](09-records.md) [13](13-induction.md)

**39 · 量词变量也要注域**
- 现象：`∀ n → n ≡ n` 报 `UnsolvedMetaVariables`（n 的域没处解，字面量类型也无从猜）。姿势：`∀ (n : ℕ) → n ≡ n`。→ [12](12-logic.md)

**40 ·〔实测〕数据类型要过正性检查**
- 现象：`data Bad : Set where bad : (Bad → Bad) → Bad` 报 `[NotStrictlyPositive] Bad is not strictly positive, because it occurs to the left of an arrow`。姿势：函数空间左侧出现自身类型即拒（不一致性来源）；真要这类结构去 22 章余归纳地盘。→ [05](05-universes.md) [06 模式匹配](06-patterns.md)

**41 ·〔实测〕数字字面量是实例驱动的**
- 现象：没有 ℕ 上下文时写 `1` 报 `[NoBindingForBuiltin] No binding for builtin ZERO, use {-# BUILTIN NATURAL name #-} …`。姿势：自定义类型吃字面量要配 `Number` 记录 + `fromNat` 字段（ℤ 正/负各一条实例）；纯结构类型老实写 `suc zero`。→ [03](03-basics.md)

**42 · record 的 `inherit` 在 2.8.0 已死**
- 现象：两种报错各堵一面墙（`NotValidBeforeField` / `MissingTypeSignature`），老教程的字段复用全废。姿势：改嵌套 record 或手工重声明字段。→ [09](09-records.md)

**43 · 点记法只认真字段，且投影要在作用域内**
- 现象：`p .posX` 没 `open Point` 先报 NotInScope；record 体内派生定义 `total` 被提升成收记录参数的函数，`ps .total` 报 `CannotApply`。姿势：只有真字段配点号，派生值写 `total ps`。→ [09](09-records.md)

**44 · 「缺东西」统一报 `UnsolvedMetaVariables`**
- 现象：record 表达式少写必填字段、`# k` 越界，都不直指病因，只甩一串坐标。姿势：把字段清单/索引账摊开逐列对，别在报错文本里找「缺」字。→ [09](09-records.md) [10 依赖类型入门](10-dependent.md)

**45 · Fin 的三课**
- 现象：stdlib 2.3 构造子改叫 `zero/suc`（fz/lsuc 不再导出）、`natToFinBound` 删除；`suc zero : Fin 1` 编译失败（索引语义不是数值加一）；`fromℕ k` 只到 `Fin (suc k)`，进更大的 `Fin n` 还差一道 `inject≤`。姿势：import 时 `renaming (zero to fzero; suc to fsuc)` 防截胡；界证明层数别心算，换 15 章 `_<?_` + `toWitness`。→ [10](10-dependent.md) [15 可判定性质](15-decidable.md)

## 28.4 模式匹配与终止（46–59）

**46 · 参数位置丢信息**
- 现象：该做索引的写成参数（`Bool → Set` 式扁平化），「分支消失」的红利全没了。姿势：建模先问「哪个组合根本不该存在」，会存在的进参数、要消失的进索引。→ [06](06-patterns.md)

**47 · 索引变化的字段是构造子隐式参数**
- 现象：硬写 `there n` 撞 `WrongNumberOfConstructorArguments`——构造子元数按「含隐式」计。姿势：模式里显式命名 `{n}` 再复用。→ [06](06-patterns.md)

**48 · 点模式是断言不是约束；forced 自动打点**
- 现象：两个无关联参数写 `j n .n` 照样报错（没有等式来源就没有点可打）；而真正 forced 的变量 Agda 会自动打点（`e b b (pr b)` 实测能过）。姿势：点模式只在类型层已有等式处使用，显式 `.b` 只有文档价值。→ [06](06-patterns.md)

**49 ·〔实测〕`()` 必须落在可证空集上**
- 现象：对还有构造子的类型写荒谬模式，报 `[ShouldBeEmpty] Two should be empty, but the following constructor patterns are valid: a b`。姿势：空必须**可判定**——构造子冲突秒过，依赖算术引理的空它不认。→ [06](06-patterns.md)

**50 · 字面量模式 = suc 展开，与实例无关**
- 现象：自定义 `Parity` 上写 `h 7` 被 `ConstructorPatternInWrongDatatype` 拒绝——它只认 ℕ 的 `suc` 链。姿势：非 ℕ 类型老老实实写构造子模式。→ [06](06-patterns.md)

**51 ·〔实测〕拼错的构造子模式 = 全捕捉变量，只留一行警告**
- 现象：本意匹配 `true` 却打了 `tt`，变量模式静默吞下一切，后续分支报 `-W[no]UnreachableClauses`，**退出码仍 0**、函数照编译。姿势：把警告当错误读；关键函数逐构造子穷举、不留兜底变量。→ [06](06-patterns.md)

**52 · 终止报错连坐整个 mutual 块**
- 现象："failed for the following functions" 一列一串名字。姿势：病灶看「Problematic calls」点名的自我调用，从调用位置回找「哪个参数没缩小」，别按名单逐个怀疑。→ [07 递归与终止](07-recursion.md)

**53 · `--termination-depth=2` 救不了 `f (f n)`**
- 现象：实测报错一字不变。姿势：它放宽的是增减计数不是嵌套调用；嵌套递归改结构（累加器/尾递归）或走 `Acc` 路线。→ [07](07-recursion.md)

**54 · `measured by` 不是语法，`...` 是旧风**
- 现象：2.8 报 `NotInScope: measured`；`... | x` 续行仍可用无告警但属旧风。姿势：度量递归用 `Data.Nat.Induction` 的 `<-wellFounded`/`<-rec`，with 子句重复完整左侧模式。→ [07](07-recursion.md)

**55 · `--partial-definitions` 已改名且命令行开关会传染**
- 现象：2.8 直接 `OptionError`；对应需求拆成 `--allow-unsolved-metas`/`--allow-incomplete-matches`，从**命令行**传入还会污染 stdlib 的 `--safe` 模块。姿势：一律文件级 `{-# OPTIONS … #-}`。→ [07](07-recursion.md)

**56 · `<-rec` 双坑**
- 现象：漏第一显式参数（motive `P`）报 `!=< Set`；把递归假设写成显式 `(m : ℕ) →` 报 `UnequalHiding`（真实类型是 `∀ {m} → m < n → P m`）。姿势：`<-rec P` 起步、隐式性照签名抄，`:Check` 一遍再落笔。→ [07](07-recursion.md)

**57 · `NON_TERMINATING` 能「证明」`⊥`**
- 现象：逃生门不带保险，一路绿灯。姿势：正经文件挂 `{-# OPTIONS --safe #-}` 体检（实测反手报 `SafeFlagNonTerminating`）；postulate 同理（见 73 条）。→ [07](07-recursion.md)

**58 ·〔实测〕`--without-K` 下拆 `refl` 卡住**
- 现象：对变元端点 `(x : ℕ) (p q : x ≡ x)` 同时 `refl refl` 报 `[SplitError.UnificationStuck] … Cannot eliminate reflexive equation x = x of type ℕ because K has been disabled`；闭端点 `1 ≡ 1` 则无事。姿势：K 是「两个等式同时拆」的代价；无 K 世界改用 `transport` 单拆，cubical 里 Path 本来就没有 K 可用。→ [11 命题等式](11-equality.md) [24 立方类型论](24-cubical.md)

**59 · 隐式参数不能夹在显式参数中间**
- 现象：LHS 写 `append′ {m = zero} [] {n} ys` 报 `WrongHidingInLHS: Unexpected implicit argument`；`headMaybe {zero} _` 会把 `zero` 绑到最前的隐式 `A`，报 `Cannot split on … non-datatype Set`。姿势：隐式全部前置，拆分点名 `{n = zero}`。→ [16 Vec](16-vectors.md)

## 28.5 等式与证明（60–73）

**60 · refl 查的是转换，「哪侧免费」由定义决定**
- 现象：`0 + n ≡ n` 一行过，`n + 0 ≡ n` 必报 `UnequalTerms`——`+` 在**第一个**参数上递归。姿势：含变量的等式走 13 章归纳；改写目标先想清楚规约方向。→ [03](03-basics.md) [11](11-equality.md)

**61 ·〔实测〕`rewrite` 只认等式**
- 现象：拿 `p : suc n ≤ suc n` 去 rewrite 报 `[CannotRewriteByNonEquation] Cannot rewrite by equation of type suc n ≤ suc n`。姿势：≤ 关系用 `trans`/`≤-step` 手工传递；rewrite 的主场是 `_≡_`。→ [11](11-equality.md) [14 推理框架](14-reasoning.md)

**62 · 项级 `rewrite e in x` 在 2.8 不存在**
- 现象：`ParseError`。姿势：rewrite 只有子句级形态；多条用 `|` 串接，且后刀作用于前刀改写后的目标——顺序有意义。→ [11](11-equality.md) [13](13-induction.md)

**63 · `RewritesNothing`：rewrite 空转只警告**
- 现象：多条 rewrite 时后条被前条「吃掉」目标，静默无事发生，退出码 0。姿势：每条 rewrite 后重新 `:Goal` 看一眼。→ [11](11-equality.md)

**64 · rewrite 只按左→右替换**
- 现象：拿 `n ≡ n + 0` 去 rewrite 把裸 `n` 全部膨胀成 `n + 0`。姿势：先 `sym` 摆正方向；证引理时就把「想消灭的模式」放左边。→ [13](13-induction.md)

**65 · rewrite 连上下文一起改**
- 现象：外层用 `rewrite sym (+-identityʳ n)` 凑签名，结果 `xs : Vec A n` 被连带改成 `Vec A (n + 0)`，报错冒出 `n + 0 + zero`。姿势：只想换值不动上下文用 `cast`。→ [16](16-vectors.md)

**66 · where 子句名进不了 rewrite 左端**
- 现象：where 的类型左端**可以**引用子句模式变量，但 `rewrite` 属于左端部分、先于 where 作用域解析，报 NotInScope。姿势：给 rewrite 用的引理提到顶层或 let。→ [13](13-induction.md)

**67 · J 的参数序和教科书不一样**
- 现象：stdlib 是 `J B p b`（票在前），常见讲义是 `J B b p`，照抄直接类型错。姿势：拿别的来源的证明骨架先对签名。→ [11](11-equality.md)

**68 · 复合方向与 `Irrelevant` 天书**
- 现象：`f ∘ g` 先 g 后 f；`1 ≢ 0` 要写 `0≢1 ∘ sym`，写反得到满屏 `Data.Irrelevant.Irrelevant Data.Empty.Empty` 的报错。姿势：¬A 就是 A → ⊥，方向乱了就 `sym`；见 Irrelevant 全名先想是不是反了。→ [11](11-equality.md) [12](12-logic.md)

**69 · Leibniz 等式与 UIP 的边界**
- 现象：Leibniz 等式量化谓词族住在 `Set₁`，`Leib⇒≡` 换实例方向得到的是 `y ≡ x`；UIP 只对闭端点（`1 ≡ 1`）可证，变元端点是 `Axiom.*` 公理地盘；`0 ≡ true` 这种不合式另走 `HeterogeneousEquality`。姿势：先 `_≡_` 后别的，跨类型别硬证。→ [11](11-equality.md)

**70 · 推理框架是「命名模块」，全局同开会打架**
- 现象：`≡-Reasoning` 不 `using (module ≡-Reasoning)` 带不出来；同开两套框架 `begin_`/`∎` 直接 `AmbiguousName`。姿势：每证明一个 `where open ≡-Reasoning`，与 stdlib 源码同风。→ [14](14-reasoning.md)

**71 · `begin` 会按正规形锚定**
- 现象：目标头是 `<` 时 `begin n` 拿 `suc n ≤ …` 去配，报 `n != suc n`（`_<_` 是差一缩写）。姿势：用 `begin-strict`，或把链端点统一写成 ≤ 形状。→ [14](14-reasoning.md)

**72 · 报错坐标与正规形的读法**
- 现象：`≡⟨⟩` 卡住时报错 span 盖在「下一项到 ∎」上；报错里 `n + 1` 实为 `suc (n + zero)`、`0` 实为 `zero`。姿势：读报错要在脑内跑一遍 normalize，span 指向下一项时病因在本项。→ [14](14-reasoning.md)

**73 ·〔实测〕postulate 会「传染」下游 safe 模块**
- 现象：A 模块里一个 postulate，让引用它的 `--safe` 模块 B 报 `[CoInfectiveImport] Importing module A not using the --safe flag from a module which does.`。姿势：postulate 在同模块内不报错不警告、只悄悄把「证明」挪到假设层，跨 safe 边界才当场爆炸；库审计第一步 `grep -rn postulate`。→ [01](01-intro.md) [12](12-logic.md)

## 28.6 stdlib 版本坑（74–86）

**74 · 模块搬家与 Base/API 拆分**
- 现象：本教程钉 stdlib 2.3；换版本最先撞的就是 import 路径失效（`Data.Nat` 拆出 `Data.Nat.Base`）。姿势：**禁止凭记忆猜 import 路径**——grep 真实库源码（`/usr/share/agda-stdlib/src`）或让 agda 报错告诉你；新代码优先引 `Base` 减依赖。→ [02](02-toolchain.md) [27 标准库阅读指南](27-stdlib-guide.md)

**75 · `Logic` 模块整体已死**
- 现象：老教程的 `open import Logic using (_↔_)` 直接 FileNotFound；`_↔_` 正品住址 `Function.Bundles`，⊎/×/∀ 的真实住址是 `Data.Sum.Base`、`Data.Product.Base`、`Relation.Nullary.*`。姿势：连接词从各家 Base 拿；`Function.Inverse` 是弃用不是删除，别再用。→ [12](12-logic.md) [17 函数世界](17-functions.md)

**76 · `Relation.Nullary.Reflect`（少 s）不存在**
- 现象：正名 `Reflects`；按旧路名 import 吃 ModuleDoesntExport 警告（退出码 0，使用处才炸）。同族：2.8 已删内建 Reflection 的 True/False 包装，别和 `Data.Bool` 的 `T : Bool → Set` 混层。姿势：大小写和单复数都进 grep 结果再下笔。→ [15](15-decidable.md)

**77 · `Dec` 是 record 不是和类型**
- 现象：真构造子是 `_because_`，`yes/no` 只是 pattern；合并成 `(b because q)` 一枝时 `⌊ b because q ⌋` 对变量 b **不**化简，refl 立刻对不上；`toWitness` 第一隐式参数是 Level（要点名 `{a? = …}`）；`1+n≢0` 自带隐式 n（写 `no (1+n≢0 n)` 会把 ℕ 当 `¬ (suc n ≡ 0)` 用）。姿势：分 `(true because q)`/`(false because q)` 两枝拆；过桥走 `_<?_` + `toWitness`。→ [15](15-decidable.md)

**78 · 该导出的不导出，不该想当然的想当然**
- 现象：`Data.Nat.Properties` 不导出 `_≤_`/`z≤n`/`s≤s`（在 `Data.Nat`）；`if_then_else_` 只在 `Data.Bool(.Base)`，写进 `Data.Nat` 的 using 清单只留警告。姿势：「哪个名字住哪个模块」以 grep + 编译通过为准（74 条的具体案例）。→ [14](14-reasoning.md) [15](15-decidable.md)

**79 · `Agda.Builtin.Bool` 没有 `not`**
- 现象：把示例钉在 builtin 层，`import Agda.Builtin.Bool using (not)` 只留 `ModuleDoesntExport` 警告，用到时 `NotInScope`。姿势：builtin 层是「够用就行」——`Sigma` 同理只有 `Σ/_,_/fst/snd`、无配套等式引理；逻辑运算从 `Data.Bool.Base` 拿或自定义（74 条的 grep 纪律在此同样适用）。→ [23 反射与元编程](23-reflection.md) [24](24-cubical.md)

**80 · `ret` 已死**
- 现象：stdlib 2.3 的 Effect 家族全库无 `ret` 字段，do 尾句写 `ret` 必 NotInScope。姿势：换 `pure`/`return`；≈1.x 时代的老教程要整体重校。→ [19 单子](19-monads.md)

**81 · 反向推理记号：一个不存在、一个静默废**
- 现象：`_≡˂_`/`≡˂⟨_⟩_` 在 2.3 根本不存在（grep 全库无 `˂`）；`≡˘⟨_⟩_` 还在但挂着 `WARNING_ON_USAGE`，默认配置**不打字也不改退出码**地通过。姿势：反向跳用 `≡⟨_⟨` 或 `sym` + `≡⟨_⟩_`；新代码禁 `≡˘⟨_⟩_`。→ [14](14-reasoning.md)

**82 · stdlib 2.3 没有 String→ℕ**
- 现象：`parseNat`/`digitToNat` 不存在（ModuleDoesntExport 警告 + NotInScope 二连）。姿势：文本基础设施自己铺（21 章示例手写 `digitToNat` 就是学费）；别按 Haskell `read`/Coq `Nat.of_string` 的直觉找现成。→ [21 文本处理](21-strings.md)

**83 · 外延公理全库无现货**
- 现象：`funExt` 全库 grep 零命中——不是藏得深，是真没有，stdlib 立场「佐料自备」。姿势：postulate 它（记得 73 条的传染账），或上 `--cubical` 拿 Path 版；cubical funExt 只认 Path 的 `_≡_`，且 Path 版不导出 refl（本地手写 `refl {x = x} i = x`）。→ [17](17-functions.md) [24](24-cubical.md)

**84 · 同构/逐点的细账不免费**
- 现象：`mk↔ₛ′` 第一定律名字带 ˡ 实为 `∀ y → to (from y) ≡ y`，写反得到两条缠死的类型不匹配；没有全局 `Relation.Binary.Pointwise`，各容器自带一家且构造子撞名（`refl ∷ refl ∷ []` 会解析成 List）；`mk↣`/`mk↩` 位置应用踩隐式参数（`WrongHidingInApplication`）。姿势：定律顺序用前 `:Check`；Pointwise 一律模块别名 `PW.` 圈住。→ [17](17-functions.md)

**85 · `+-monoˡ-≤` 的 ˡ/ʳ 与直觉相反**
- 现象：实测 `+-monoˡ-≤ c p : a + c ≤ b + c`，c 钉在**右侧**；赌方向先撞 `n + 1 != suc n`。姿势：命名规律拿不准就 `:Check`——`snoc` 索引是 `suc n` 不是 `n + 1`、`replicate` 个数在第一参数，同理别心算。→ [13](13-induction.md) [14](14-reasoning.md) [16](16-vectors.md)

**86 · Vec 的索引算术必须顺着定义方向**
- 现象：`_+_` 只按左参数化简，索引写 `n + suc m`/`n + 1` 卡在 `UnificationStuck`（变量在 `+` 左边化简不动），连 `head : Vec A (n + 1) → A` 拆 `x ∷ xs` 都过不了。姿势：索引写成 `suc m + n`、`1 + n` 或干脆 `suc n`；逆方向靠 `rewrite +-suc`/`+-identityʳ`；Vec↔List 往返定律改用 `…Equality.Cast` 的 `≈[ ]` 才有两行证明——普通 `≡` 版根本证不出来且报错零提示。→ [16](16-vectors.md)

## 28.7 IO / 单子 / 余归纳 / cubical 高级坑（87–101）

**87 · 用 IO/反射不挂 OPTIONS，第一行就还债**
- 现象：`[InfectiveImport] Importing module IO using the --guardedness flag from a module which does not.`——错误行号指 import 行，但修的是**文件第一行**。姿势：IO/反射等文件顶部 `{-# OPTIONS --guardedness #-}`（23 章反射另需 unsafe 系选项）。→ [02](02-toolchain.md) [20](20-io.md)

**88 ·〔实测〕余归纳也要 guardedness**
- 现象：`open import Codata.Musical.Stream` 不带选项就吃 `InfectiveImport`（报的正是 `using the --guardedness flag`）。姿势：22 章任何文件第一行先挂 `{-# OPTIONS --guardedness #-}` 再 import；`--safe` 与它可共存，和 73 条的 postulate 不是一回事。→ [22 余归纳与无限流](22-codata.md)

**89 · `♯` 里穿 `♭` 即 guardedness 泄漏**
- 现象：`bad = 1 ∷ ♯ (tail bad)` 看着有 `♯` 护体，仍报 `TerminationIssue`（Problematic calls 点名 `♯-0` 与 `bad`）——「先拆箱再喂」不算 guarded。姿势：`♯` 内只放裸递归调用；任何穿过 `♭` 的组合都要换结构或改成显式余构造子逐步产出。→ [22](22-codata.md)

**90 ·〔实测〕cubical 的传染是双份的**
- 现象：从普通模块 import 一个 `--cubical` 模块，先报 `Importing module … using the --cubical/--erased-cubical flag`，补上之后又报第二条 `using the --two-level flag`。姿势：接 cubical 世界的文件备好两个选项，或干脆整库统一方言，别混装。→ [24](24-cubical.md)

**91 · cubical 与 safe/guardedness 可共存，但 `--compile` 全面拒绝**
- 现象：`{-# OPTIONS --cubical --safe #-}` 照常通过检查（postulate 等仍被 safe 拒），但 `agda --compile` 一律报 `Compilation of code that uses --cubical is not supported.`。姿势：cubical 文件只做类型检查、别指望编译产物（24 章示例没有 main 就是这个原因）；需要可执行就换非 cubical 方言的模块承担 IO 层。→ [23](23-reflection.md) [24](24-cubical.md)

**92 · cubical 方言里 `≡` 要自带，`pathToEquiv` 只吃 λ 形式**
- 现象：`--cubical` 下 `≡` 不在自动作用域，直接 `Not in scope: ≡`（`i0`/`i1` 反而是自动的）；`pathToEquiv`/`primGlue` 传路径名（如 `boolPath`）报 `UnequalTerms (Bool ≡ B̂) !=< ((i : I) → Set …)`。姿势：`open import Agda.Builtin.Cubical.Path using (_≡_)` 补作用域；区间族一律写 λ 形式 `(λ i → B)` 而非路径名。→ [24](24-cubical.md)

**93 · `main : IO ⊤` 是类型错误**
- 现象：入口类型必须是 `Main`（原始 `Prim.IO ⊤`）。姿势：`main = run (putStrLn …)` 把 guarded IO 单子执行掉——这是本教程 20 章定死的写法。→ [20](20-io.md)

**94 · stdin/stdout 的 EOF 与尾换行没有童话**
- 现象：`IO.getLine` 到 EOF 是**崩溃**不是返回 nothing；`readFiniteFile` 返回原文，`"42\n"` 会把朴素 parseNat 判成失败。姿势：可能 EOF 的输入要么预先判定、要么别裸奔；文件格式自己写自己读（刻意不带尾换行）。→ [20](20-io.md) [21](21-strings.md)

**95 · `readMaybe` 的基数只是隐式上界约束**
- 现象：违例（如 base 超出 `True (base ≤? 16)`）不是优雅报错而是卡 `UnsolvedMetaVariables`，且**同文件更早的类型错误会把它吞掉**——排错被报错顺序骗了。姿势：读到一串「说不清」的 meta 报错时，从文件第一条错误往后逐段隔离复跑；对库函数里看不见的隐式约束（本条的基数上界）心里有账。→ [21](21-strings.md)

**96 · `unlines` 不加末尾换行，和 Haskell 直觉相反**
- 现象：`unlines ("a" ∷ "b" ∷ []) ≡ "a\nb\n"` 实测报 `"a\nb" != "a\nb\n" of type String`——Agda 版是 join 式的。姿势：需要行终止符自己补 `++ "\n"`；别把 Haskell `unlines`（每行都补 `\n`）的语义账平移到 stdlib `Data.String`。→ [21](21-strings.md)

**97 · `--compile` 流水线会留一地产物**
- 现象：编译 IO 程序 1–2 分钟、产物在源文件旁；build.sh 的 run 失败时清理不执行（`set -e` 在运行那行就断），仓库留下悬空二进制与 `MAlonzo/`。姿势：跑完即删或 `--compile-dir` 指到临时目录；CI 里编译与类型检查分开工。→ [20](20-io.md)

**98 · do 记号三则**
- 现象：`do { … ; … }` 花括号版被解析成隐式实参（`HiddenNotInArgumentPosition`）；尾句写裸绑定报 `DoNotationError`（脱糖器不补 return）；`_>>=_` 两候选歧义报错、单候选完全静默。姿势：多语句只认布局式；尾句必须是表达式；每个 do 用法圈进自己的小 module（MaybeDo/ListDo 模式），`open import M as L` 只留限定访问也是好抓手。→ [19](19-monads.md)

**99 · 单子实例的宇宙层级要手动钉**
- 现象：`RawFunctor Maybe` 不写 `{ℓ = 0ℓ} {ℓ′ = 0ℓ}` 时常卡 `UnsolvedMetaVariables`，指向 record 类型行的两个宇宙位。姿势：实例值不像 class 有默认单态化，该标就标。→ [19](19-monads.md)

**100 · 函记号的级别与住户**
- 现象：`_<$_` 的算符符号是 `<$`，`0 <$_ just 99` 直接 NoParse；`<$>`/`<*>`/`⊛` 全是 level 4、与 `_≡_` 平级，等式左边必须整体加括号；裸打 `join` NotInScope——它住 `module Join (M : RawMonad F)`，不是 record 字段；`Data.List` 的 `zip`（截断）与 applicative 的 `⊗`（叉积）同名异实。姿势：grep 源码时 `<*>` 与 `⊛` 两种写法都要搜；`Join.join maybeMonad` 点名用。→ [19](19-monads.md)

**101 · `case_of_` 不是关键字**
- 现象：`case x of` 依赖函数 `case_of_`，忘 `open import Function.Base` 报 `Not in scope: case`，与「内建语法」直觉相悖；双 ⊤ 冲突是它的搭档坑（IO 程序里标注 `⊤` 撞出 `Lift lzero ⊤ !=< ⊤`）。姿势：case 记得 import；一个文件内 ⊤ 只认一家。→ [11](11-equality.md) [20](20-io.md)

## 28.8 工程最佳实践（102–106）

**102 · 警告族当错误治**
- 现象：`ModuleDoesntExport`、`UnreachableClauses`、`RewritesNothing`、`UselessHiding`、`AbsurdPatternRequiresAbsentRHS` 全部不改退出码——CI 只看 `$?` 会一路绿灯到使用处。姿势：agda 输出里 grep `warning:` 和 `———— All done; warnings encountered ————`，出现即修。→ [04](04-syntax.md) [06](06-patterns.md)

**103 · 提交物不留孔**
- 现象：带 `?` 的文件命令行检查必失败（`UnsolvedInteractionMetas`）；`--allow-unsolved-metas` 调试可用、入库是事故。姿势：本教程示例文件从不留孔；探索期的孔靠 Emacs `C-u C-x \`` 逐个跳。→ [02](02-toolchain.md)

**104 · `--safe` 是日常体检**
- 现象：postulate、`NON_TERMINATING`、`--allow-*` 都能悄悄「证明」任何东西；同模块内沉默、跨 safe 边界才爆（73/57 条）。姿势：正经文件第一行 `{-# OPTIONS --safe #-}`；定期 `grep -rn 'postulate\|NON_TERMINATING\|UNSAFE' examples/`。→ [07](07-recursion.md) [12](12-logic.md)

**105 · 报错驱动学习回路**
- 现象：猜 import、猜记号、猜定律顺序三件事烧掉新手一半时间。姿势：报错三读（标签→坐标→脑内 normalize）+ 用前 `:Check`/`:type` + 改动后最小化复跑 `./build.sh ExNN`；`--only-scope-checking` 可先验作用域再谈类型。→ [02](02-toolchain.md) [14](14-reasoning.md)

**106 · 版本迁移以编译通过为准**
- 现象：Agda/stdlib 每版都在挪模块、杀语法（`inherit`、`ret`、`--partial-definitions`、`_≡˂_`……本页相当一部分条目是版本祭品）。姿势：教程/代码库钉死版本对（本教程 = Agda 2.8.0 + stdlib 2.3）；升级时按报错微调 import，把每处失效记进 27 章阅读指南。→ [27](27-stdlib-guide.md)

## 28.9 最佳实践十条（全教程收束）

1. **命名**：模块/文件名走合法标识符 + `Ex` 前缀（13/14/15 条）；撞关键字用连字符；一名一职责，重名即 `ClashingDefinition`（10 条）。
2. **模块组织**：一个主题一文件；会撞名的构件（推理框架、do 实例、Pointwise）圈进 `where`/小 module/`as` 别名（70/98/84 条）；公共定义下沉，杜绝循环依赖（11 条）。
3. **import 习惯**：置顶、精确 `using`、路径先 grep 库源码再写（22–24/74 条）；改名导入只写 `renaming`；把「哪个名字住哪家」当成 27 章的地图题来背。
4. **记号纪律**：新中缀立刻声明 fixity、级别进 stdlib 地图占坑（16–20 条）；拿不准先加括号——NoParse 与 `=<ERROR>` 类报错九成是记号账。
5. **终止与信任**：写递归前先定「哪个参数在变小」；逃生门（postulate / NON_TERMINATING / unsafe）必付 `--safe` 审计的利息（57/73/104 条）。
6. **等式与 rewrite**：动手前先判「哪侧规约免费」；rewrite 只走 ≡、只左→右、会伤上下文，三思改用 `sym`/`trans`/`cast`（60–65 条）。
7. **报错阅读法**：标签 → 坐标（点分隔）→ 正规形回译 → fixity 表，四步一循环；警告当错误读（28/72/102/105 条）。
8. **孔洞驱动开发**：签名先行 → `C-c C-l` → `C-u C-x \`` 跳孔 → refine/case → 目标收窄；但孔只活在交互期，入库前清零（103 条，流程详见 02 章）。
9. **求值即证明**：源文件里展示计算用 `_ : 2 + 3 ≡ 5; _ = refl`，交互命令 `Compute` 不进代码；能 refl 的实例先钉住，再归纳通式（03/11 章主线）。
10. **验证收口**：每章示例过 `agda` 退出码 0 才算数；`--compile` 产物要 `ls` 确认（9 条）；升级 Agda/stdlib 版本时，本页就是你的回归测试清单（106 条）。

---
上一章：[27 · 标准库阅读指南](27-stdlib-guide.md) ｜ 返回：[README](../README.md)
