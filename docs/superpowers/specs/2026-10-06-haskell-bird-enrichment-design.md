# Haskell 教程 Bird 书扩充设计（24 → 31 章）

日期：2026-10-06
参考书：《Haskell函数式程序设计》（Richard Bird, *Thinking Functionally with Haskell* 中译本，机械工业出版社 2016，纯扫描 PDF 241 页，无文本层）

## 1. 目标

1. 把原书 12 章的核心内容**全部**提炼进教程，自包含——读者不翻原书；
2. 教程而非代码罗列：讲解为主、代码为辅，每段代码前有"为什么"、后有"在做什么"，新写/深改章每章 ≥200 行且文字多于代码；
3. 书中过时的工具（Haskell Platform、GHC 7.x 时代写法）升级为本机实测的现代版（GHC 9.14.1 / stack 3.11.1）；
4. 导航样式对齐 Ada/Zig 标准：每章页脚 `上一章 ｜ 下一章 ｜ 返回 README`，README 章节索引表按篇分组，01→31 严格顺序阅读。

## 2. 结构：31 章六篇（重编号）

| 篇 | 章 | 来源 |
|---|---|---|
| 一 语言基础 | 01–08 | 01←书1(轻改)、02←书2(中改)、03←书3(中改)；04–08 原有不动 |
| 二 列表与推理 | 09–15 | 09←书4(大改)；**10 数独←书5★**、**11 证明与归纳←书6★**、12 惰性(原10)、**13 无穷列表←书9★**、14 容器(原11)、15 字符串(原12) |
| 三 单子与结构 | 16–20 | 16 FAM(原13)、17 mtl(原14)、**18 命令式函数式：ST←书10★**、19 文件(原16)、20 错误处理(原17) |
| 四 解析与实战 | 21–23 | **21 手写解析器组合子←书11★**、22 parsec(原15)、**23 交互式计算器←书12★** |
| 五 工程与性能 | 24–30 | 24 TH(原18)、25 性能←书7(大改，原19)、**26 优美打印←书8★**、27 Stack(原20)、28 测试(原21)、29 并发(原22)、30 FFI(原23) |
| 六 收官 | 31 | 31 MiniLang(原24) |

★ = 新章（7 个）；深改 5 章 = 01/02/03/09/25；其余 19 章只做重编号 + 导航 + 交叉引用修正。

**重编号映射**（旧→新，docs 与 examples 同步；ChNN 模块名同步改）：
10_laziness→12、11_containers→14、12_strings→15、13_fam→16、14_mtl→17、15_parsec→22、16_files→19、17_errors→20、18_th→24、19_performance→25、20_stackenv→27、21_testing→28、22_concurrency→29、23_ffi→30、24_capstone→31。
新目录：10_sudoku、11_proofs、13_infinite、18_st、21_miniparser、23_calculator、26_pretty。
移动须两段式（先移临时名再落位）避免 10↔12↔15 类碰撞；改完后全库 grep `\d\d 章` 审计交叉引用（cpp20 四类漏网形态教训）。

## 3. 新章内容（按书提炼，代码全部重写为 GHC 9.14 实测版）

- **10 数独**：矩阵=列表的列表建模、rows/cols/boxs/group、nodups 有效性、solve by choices、矩阵剪枝 prune（书 5.4 的指数级加速对比）。
- **11 证明与归纳**：等式推理推导链、自然数/列表归纳、map 融合、foldr 融合律、foldl/foldr/scanl 定律；示例用随机样本性质断言 + 推导对照双轨验证。
- **13 无穷列表**：ones=1:ones 的循环列表、iterate 流、函数式素数筛、石头剪刀布策略对局（策略=无穷流转换）、流式交互。
- **18 命令式函数式（State/ST）**：State 计算模型回顾、ST 单子、STRef、STArray（可变数组排序/洗牌）、runST 的 rank-2 纯度保证、与 IORef/IOArray 对照。
- **21 手写解析器组合子**：`newtype Parser a = Parser (String -> [(a,String)])` 从零实现，基本组合子、Monad/MonadPlus 实例、many/some、表达式文法阶梯；结尾与 parsec 对照（parsec = 同设计 + 位置/错误/流）。
- **23 交互式计算器**：表达式文法（表达式/项/因子/原子）、变量与赋值、State 管变量表、错误处理、脚本化回放的 REPL（不依赖交互 stdin）。
- **26 优美打印**：自由文本布局问题、Doc 代数（nil/text/line/<>/nest/group）、朴素 render 的 O(n²)、按书推进到高效表示；直接版 vs 优化版输出逐字节对账 + 计时。

## 4. 深改章

- **01**（书1）：补"计算即代入"心智模型、函数应用记号；Haskell Platform 一段按现实改写（已废弃 → GHCup/stack/cabal）。
- **02**（书2）：并入 GHCi 会话系统性内容（it、:type/:info/:set、多行 :{ :}）、打印值与 show 转义、模块与 import。
- **03**（书3）：Num 类族、取整家族（含银行家舍入）、自然数 Nat 归纳类型与互转、浮点实况。
- **09**（书4）：按书重组——列表语法糖与归纳定义、concat/map/filter/zip 全家、经典定义族（inits/tails/segs/perms…）、融合预备。
- **25 性能**（书7）：以书为主轴重排——惰性的代价、空间耗费、时间测量、累积参数（reverse O(n²)→O(n)）、元组化（fib 树形→线性）、归并排序；保留现有 profiling/RTS/编译选项部分。

书映射章顶部加 `> 本章对应原书第 N 章…` 标注；12 个书映射章末尾加精选练习（取自原书 100 题，附提示/答案，答案区 PDF 233–241 页）。

## 5. 工具链升级

- GHC 9.12.1 → **9.14.1**（scoop current 已是）：先跑现有 23 例基线全量构建，修复回归（新警告/行为差异）。
- 两个 stack 工程（27_stackenv、31_capstone）`compiler: ghc-9.14.1` + 匹配 resolver；global-hints 经 TUNA（fpco 路径）手动拉取。
- README 工具链表、CHEATSheet、各章涉及版本号处同步。

## 6. OCR 流水线

pdftoppm 200dpi 渲染 → rapidocr-onnxruntime 1.2.3（CUDA，cudnn 9.24 在 PATH）→ 按 PDF 页写 UTF-8 文本（避开 GBK 控制台，直接落盘）→ 按书章合并为 `haskell/materials/book/chNN.txt`（PDF 页 = 书页 + 8 偏移；书 1–12 章 + 习题答案）。OCR 只作内容导航与取材；**一切代码以 GHC 9.14 编译通过为准**，OCR 失真不进入教程。

## 7. 验证协议

- 现有 `pwsh ./build.ps1 -All` 六条判定（编译 0 / 运行 0 / stderr 空 / stdout 无控制字符 / 结束标记 / 无诊断），run-all.sh 同；
- 每新章/深改章：写完即 `-Example NN_topic` 单验；全部完成 `-All`（23 旧 + 7 新 = 30 例，27/31 走 stack 分支）；
- 导航完整性脚本：每章页脚 prev/next 链接目标存在、README 表内链接有效、无断链；
- docs ≥200 行（新写/深改 12 章）、文字行多于代码行。

## 8. 批次

1. 批次一：OCR materials 落盘 + 基线构建（9.14.1）修回归；
2. 批次二：重编号（docs/examples/模块名/交叉引用/导航页脚全套 + README 六篇索引 + CHEATSheet）→ `-All` 全绿后提交；
3. 批次三~N：逐章写作（每章 docs + 示例 + 单验 + 提交），顺序：10 数独 → 11 证明 → 13 无穷 → 18 ST → 21 手写解析 → 23 计算器 → 26 优美打印（新章），穿插 01/02/03/09/25 深改；
4. 收官：README 定稿、CHEATSheet 增补新坑位、全量 `-All` + 导航审计。

## 9. 风险

- 9.14.1 回归：新警告（如 -Wx-partial 式断代）在基线批先暴露先修；
- stack resolver 与 9.14.1 的匹配：主线纯 boot 库可 compiler 覆盖，global-hints 拉取失败则按 20 章既有手册处理；
- 重编号漏网：两段式移动 + grep 审计 + 全量构建对账；
- OCR 代码失真：GHC 编译是唯一事实源，存疑页对照渲染 PNG 人工校读。
