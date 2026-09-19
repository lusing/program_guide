# Haskell 教程设计（2026-09-20）

## 1. 背景与问题

`guide` 仓库已有 20+ 门语言教程（cpp20/zig/go/julia/swift 等均为 docs/ 24 章分章 + 章号=示例目录号
+ 递进讲解 + 坑位清单 + 多层验证的标准结构），`haskell/` 目录**尚不存在**。本任务从零新建 Haskell
教程，规格完全对齐 Julia 教程（2026-09-18 重写版）。

Haskell 特色内容（纯函数、惰性求值、类型类、代数数据类型、单子、解析器组合子、STM）值得按
Julia 的"语言核心 → 特色深潜 → 生态工程 → 实战"弧线讲深。

## 2. 目标与非目标

**目标**：24 章独立文档（每章 150–250 行，特色章不压缩）、章号 = 示例目录号（02–24 共 23 个示例）；
定位"会编程（C++/Python 背景最佳）、初学 Haskell，从零教到 GHC 9.12 现代写法"；全部示例在
GHC 9.12.1 实测多层验证通过；第 24 章实战项目为**迷你解释器 MiniLang**（stack 工程：词法-语法-语义
三层管线，ADT×模式匹配×单子集大成）。

**非目标**：
- 不做 GHC 各版本迁移指南（坑位清单点到即止）
- 不引第三方 hackage 包作主线（纯 boot 库：mtl/stm/parsec/text/bytestring/containers/exceptions
  均随 GHC 9.12.1 发行，离线可验证）；HUnit/tasty/QuickCheck/vector/aeson/async 只作生态介绍
- 不教 lens/optics 深水区（18 章 TH/GHC.Generics 一瞥为止）
- 不教 GHC API/Rules/PLUGIN 深水区
- 类型级编程（TypeFamilies/GADTs）只给最小可运行示例，不展开
- 不教 web/数据库生态

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 24 章完整版（对齐 cpp20/zig/julia）；24 = 实战迷你解释器 |
| 读者定位 | 会编程（C++/Python 背景最佳）、初学 Haskell，GHC 9.12 现代写法为主线 |
| 实战项目 | 第 24 章迷你解释器 MiniLang（词法→parsec 解析→AST→求值器→REPL；stack 工程） |
| 依赖策略 | **纯 boot 库**（用户已确认）：主线零外部依赖、离线可验证；测试章手写 mini 框架 |
| 工具链 | GHC 9.12.1 @ G:\scoop\apps\haskell\current（scoop）；stack 3.11.1（scoop）+ 清华镜像 |
| 示例形态 | 每章一个目录 `examples/NN_topic/`（含 `main.hs` + `runtests.hs`；20/24 为 stack 工程），章号=目录号 |
| 验证策略 | 两层 + 特判：运行层（ghc --make 编译 exit 0 + exe 运行 exit 0 + 结束标记）→ 测试层（runtests.hs exit 0）→ 特判层（20/24 stack 工程、22 加 -threaded -N4、23 FFI 链接实测） |
| 旧文件 | 无（全新目录 `haskell/`） |
| 新增 | `docs/` 24 章、`examples/` 23 目录、`build.ps1`、`run-all.sh`、`CHEATSheet.md`、`README.md` |
| 编码策略 | 每例开头 `hSetEncoding stdout/stderr utf8`（Windows 默认 GBK，实测唯一可靠修复） |

## 4. 环境实测结论（2026-09-20，GHC 9.12.1 + stack 3.11.1 @ G:\scoop）

| 项 | 结果 |
|---|---|
| GHC | 9.12.1；boot 库含 mtl-2.3.1/stm-2.5.3/parsec-3.1.17/text-2.1.2/bytestring-0.12.2/containers-0.7/exceptions-0.10.9/Win32-2.14（无 random/QuickCheck/HUnit/vector/aeson） |
| **坑** | **stdout 默认走 ANSI 代码页（GBK）**：源文件 UTF-8 读入正常，但 `putStrLn "中文"` 输出 GBK 字节；`GHC_CHARENC=UTF-8` 环境变量实测**不生效**；唯一可靠修复是代码内 `hSetEncoding stdout utf8`（每例固定开场） |
| **坑** | `runghc` 恒 ~41s（GHCi 链接器 Windows 老毛病，CPU 近零纯等待）——验证层**不用 runghc**，用 `ghc -v0 -O0 --make`（warm 1.2s）+ 运行 exe（0.04s）；runghc/GHCi 留给交互教学 |
| **坑** | 首次 ghc 编译冷启动 ~19s（包数据库初始化），之后 warm 1.2s |
| stack | 3.11.1；**stackage.org 系域名被墙**（raw.stackage.org 000、stackage-haddock 超时），hackage.haskell.org 可达（200） |
| 镜像 | **清华 TUNA 镜像已配置**：`%APPDATA%\stack\config.yaml` 加 setup-info-locations/urls/snapshot-location-base 三段 + `pantry/global-hints-cache.yaml` 手动下载（fpco/stackage-content 路径，**不是** commercialhaskell） |
| **坑** | lts 最新 = lts-24.59（GHC 9.10.3）、nightly-2026-09-18（GHC 9.12.4），**均不匹配系统 9.12.1** → stack.yaml 用 `resolver: lts-24.59` + **`compiler: ghc-9.12.1` 覆盖** + `system-ghc: true` + `install-ghc: false`，实测可编译 |
| **坑** | `G:\scoop\shims\strip.exe` 是指向已卸载 `E:\scoop\apps\binutils` 的**坏 shim**；Cabal 惯例从 ghc 同目录解析 strip（stack 把 ghc 解析为 shims 目录），PATH 顺序救不了 → `stack build` 的 copy 阶段必挂（exe 实际已生成）。修复：用户删 shim（`scoop shim rm strip`）+ build.ps1 兜底（PATH 前置能跑通的 strip 目录） |
| **坑** | scoop 的 `cabal` 8.0.0（extras bucket）是**同名 Electron 聊天应用**，不是 cabal-install——教程须警示；GHC bindist 也不带 cabal.exe |
| msys2 | stack 自动从镜像下载 msys2-20240727（构建 configure 类包用）；纯 boot 库项目用不到，"not using Stack-supplied MSYS2" 警告无害 |
| 输出 | `hSetEncoding utf8` 后中文 UTF-8 经 pwsh 管道正常；`putStrLn` 输出 CRLF（Windows 文本模式），判定层容忍 CR/LF/TAB |

其余坑位（半群/单子定律推导错误、foldl 惰性泄漏、记录字段冲突、parsec 报错格式等）实施中边写边实测累积。

## 5. 章节结构（docs/，24 章，⭐ = 特色重点细讲）

| # | 文件 | 主题 | 示例 |
|---|---|---|---|
| 01 | `01-overview.md` | 全景：定位（纯函数式 + 强静态类型 + 惰性）、λ演算/Curry 血统、GHC 与生态（stack/cabal/HLS）、9.12 现状、版本演进、学习方法 | — |
| 02 | `02-hello.md` | 第一个程序：GHCi/runghc/ghc 三态、`main :: IO ()`、putStrLn/print、getArgs、**Windows 编码坑（hSetEncoding）**、:r/:t/:i REPL 惯用法 | `02_hello` |
| 03 | `03-numbers.md` | 数值：Int/Integer/Word/Double/Rational、Num→Fractional→Integral 类型类层次、fromIntegral 陷阱、show/read、数值坑（除法截断/字面量多态） | `03_numbers` |
| 04 | `04-control.md` | 控制流：if/then/else、guard、case、let/where、递归替代循环、累加器与尾递归 | `04_control` |
| 05 | `05-functions.md` | 函数：柯里化/部分应用、组合 `.`/`$`、sections、lambda、eta 缩约、点自由风格、运算符自定义一瞥 | `05_functions` |
| 06 | `06-patterns.md` ⭐ | 模式匹配：构造子模式、卫兵、`@` 绑定、列表/元组模式、惰性匹配 (~)、case 穷尽性、视图模式一瞥 | `06_patterns` |
| 07 | `07-adt.md` ⭐ | 代数数据类型：data/记录语法/newtype/Maybe/Either/递归数据（List/Tree）、deriving、严格字段 `!` 一瞥、不可变值语义 | `07_adt` |
| 08 | `08-typeclasses.md` ⭐ | 类型类：class/instance、层次体系（Eq→Ord、Functor 族、Num 族）、约束多态、deriving 深入（stock/newtype/any）、orphan 规则、Kind 一瞥 | `08_typeclasses` |
| 09 | `09-lists.md` ⭐ | 列表与折叠：`(:)` 递归结构、map/filter/foldr/foldl'/scanl/unfoldr/zip 族、列表推导、建造塔、融合一瞥 | `09_lists` |
| 10 | `10-laziness.md` ⭐ | 惰性求值：thunk、无穷列表、自我引用数据（fix 一瞥）、seq/deepseq、bang patterns、空间泄漏与复现 | `10_laziness` |
| 11 | `11-containers.md` | 容器：Data.Map/Set/IntMap、元组、Foldable/Traversable 遍历族、严格/惰性容器选择 | `11_containers` |
| 12 | `12-strings.md` ⭐ | 字符串三件套：String/[Char]/Text/ByteString、转换表、OverloadedStrings、UTF-8 遍历坑、性能选型 | `12_strings` |
| 13 | `13-fam.md` ⭐ | 函子·应用·单子：三部曲推导、Maybe/Either/IO/State、do 记法脱糖、三定律、失败回退 Alternative 一瞥 | `13_fam` |
| 14 | `14-mtl.md` ⭐ | 单子变换器与 mtl：State/Reader/Writer/Except、lift、transformers vs mtl、**纯随机（手写 xorshift PRNG）** | `14_mtl` |
| 15 | `15-parsec.md` ⭐ | 解析器组合子：parsec 基本组合子（<|>/many/try）、报错格式、Token/语言定义、buildExpressionParser（生态招牌章） | `15_parsec` |
| 16 | `16-files.md` | 文件与序列化：readFile/writeFile、惰性读坑（句柄提前关闭）、严格读、目录遍历、临时文件、二进制读写 | `16_files` |
| 17 | `17-errors.md` | 错误处理：Either 模式、Maybe vs Either vs 异常、exceptions 库、SomeException、bracket 资源管理、纯代码 throw 编译坑 | `17_errors` |
| 18 | `18-th.md` ⭐ | 编译期魔法：Template Haskell（引号语法 [||]/''T、Q、lift、reify）、GHC.Generics 泛型一瞥、deriving 机制对照 | `18_th` |
| 19 | `19-performance.md` ⭐ | 性能：严格性分析（-ddump-strictness）、foldl 惰性泄漏复现、-O2、RTS `-s` 统计、空间泄漏 profiling 一瞥、criterion 生态介绍 | `19_performance` |
| 20 | `20-stack.md` ⭐ | Stack 工程与生态：resolver/snapshot、**TUNA 镜像配置（实测坑）**、compiler 覆盖、stack.yaml vs *.cabal、build/test/run/haddock、HLS/ormolu/生态地图 | `20_stackenv`（工程） |
| 21 | `21-testing.md` | 测试：自制断言框架、性质测试思想（手写 mini-QuickCheck：生成器+收缩）、HUnit/tasty/QuickCheck 生态介绍、stack test 集成 | `21_testing` |
| 22 | `22-concurrency.md` ⭐ | 并发：forkIO/MVar/Chan、STM（TVar/atomically/retry）、竞争演示与修复、-threaded -N、async 生态一瞥 | `22_concurrency`（`-threaded "-with-rtsopts=-N4"`） |
| 23 | `23-ffi.md` | FFI：foreign import ccall、msvcrt/kernel32 实测、Ptr/编组三招、funPtr 回调、ByteString 透传 | `23_ffi` |
| 24 | `24-capstone.md` | 实战：迷你解释器 MiniLang（stack 工程：词法→parsec 解析→AST→求值器（StateT 环境+Either 错误、闭包/递归/内建函数）→REPL；解析/求值/错误路径三层测试） | `24_capstone`（工程） |

## 6. 示例与验证

- 每个示例目录含 `main.hs`（函数定义 + 演示输出 + 自制 `check` 断言自检 + 末行 `==== NN 结束 ====`）
  与 `runtests.hs`（自制迷你测试框架：check/expectEq 收集失败，失败 `exitFailure`）。
- `main.hs` 用 `-- ═══ N.M 标题` 分节注释，与正文小节号一致。
- 每例开头固定：
  ```haskell
  import System.IO (hSetEncoding, stderr, stdout, utf8)
  main :: IO ()
  main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    ...
  ```
- `build.ps1`（pwsh 7，UTF-8 无 BOM，参数 `-All/-Example NN_topic/-Clean/-ShowOutput`）两层验证：
  1. 运行层：`ghc -v0 -O0 --make main.hs -o build\NN.exe` exit 0 → 运行 exe exit 0 + stdout 含结束标记
  2. 测试层：编译运行 `runtests.hs` → exit 0 + 标记
  3. 特判：02（传演示参数）；20/24（stack 工程：strip PATH 兜底 + `stack build && stack test` +
     `stack run` 或 exe 运行查标记）；22（编译加 `-threaded -rtsopts "-with-rtsopts=-N4"`）
- 判定标准六条（同 Julia）：exit 0 / stderr 空 / stdout 非空 / 无控制字符（TAB/LF/CR 除外）/
  含结束标记 / 无 GHC 诊断字样（Warning/Error/error:）。
- `run-all.sh`（bash 版，对齐 Julia 双入口）。

## 7. 交付物清单

1. `haskell/docs/01-overview.md` … `24-capstone.md`（24 章）
2. `haskell/examples/02_hello/` … `24_capstone/`（23 个示例目录）
3. `haskell/build.ps1` + `haskell/run-all.sh`
4. `haskell/CHEATSheet.md`（语法速查 + 实测坑位索引）
5. `haskell/README.md`（定位、目录结构、章节索引表、构建工具链、验证命令、相关教程）
6. 根 `README.md` 加 haskell 条目
7. 记忆文件：`haskell-tutorial-build.md`（9.12 实测坑位 + 结构）

## 8. 风险与对策

| 风险 | 对策 |
|---|---|
| GHC 9.12 与网上旧资料（9.6/9.8 时代）API 不一致 | 所有 API 先实测再定稿；坑位即素材（GHC_CHARENC 失效、Cabal 3.14 行为） |
| 中文输出编码（GBK 代码页） | 每例 hSetEncoding stdout/stderr utf8；build.ps1 读输出按 UTF-8 |
| runghc/GHCi 慢（41s） | 验证层全部走编译+运行；GHCi 交互另教（用户手敲不受影响） |
| stack copy 阶段被坏 strip shim 卡死 | 请用户执行 `scoop shim rm strip` 删除残留 shim（实施前完成）；build.ps1 对 20/24 另做兜底（探测可用 strip 前置 PATH） |
| lts 与系统 GHC 版本错位 | stack.yaml 固定 `resolver: lts-24.59` + `compiler: ghc-9.12.1` + `system-ghc: true`；正文把版本错位写成教学点 |
| 镜像依赖（TUNA 可用性） | 主线纯 boot 库不碰网络；20 章首次 stack build 需镜像（已在配置层解决）；文档写明离线兜底（resolver 解析一次后 pantry 有缓存） |
| 每示例双文件 ×23 ×两层验证的耗时 | 批次验证（每 4 个示例跑一次 build.ps1 -Example）；单例编译 ~1.2s、全量预计 ~3–5 分钟 |
| 惰性求值演示的不确定性（空间/时间随版本变化） | 断言只断性质不断字节数；泄漏演示用确定性规模 |
| GHC 编译警告走 stderr 破坏"stderr 空"判定 | 示例代码自律 -Wall 主流告警干净；build.ps1 编译不加 -Wall（正文教学时再开） |
