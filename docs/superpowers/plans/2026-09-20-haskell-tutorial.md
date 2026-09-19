# Haskell 教程实施计划（2026-09-20）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从零新建 `haskell/` 教程——24 章分章 + 章号=示例目录号 + 递进讲解 + 坑位清单 + 两层验证 +
实战迷你解释器 stack 工程，规格对齐 Julia 教程标准。

**Architecture:** 先建 build.ps1 验证骨架与示例模板（编码开场 + 自制断言/测试框架范式），再按批次写
23 个示例（每目录 main.hs + runtests.hs，`-- ═══ N.M` 分节注释），示例过验后撰写对应章节正文，
最后 CHEATSheet/README/根 README/全量终验/提交/记忆。

**Tech Stack:** GHC 9.12.1（`G:\scoop\apps\haskell\current`，scoop）、stack 3.11.1（+清华镜像）、
PowerShell 7（pwsh）、git。纯 boot 库（mtl/stm/parsec/text/bytestring/containers/exceptions）。

**Spec:** `docs/superpowers/specs/2026-09-20-haskell-tutorial-design.md`（环境实测结论与章节表以 spec 为准）

## Global Constraints（实施遵守）

- GHC 固定 `G:\scoop\apps\haskell\current`（9.12.1）；所有代码实测通过后才写正文。
- 每例 main.hs 开头固定编码开场：`import System.IO (hSetEncoding, stderr, stdout, utf8)`，main
  首两行 `hSetEncoding stdout utf8` / `hSetEncoding stderr utf8`（Windows 默认 GBK，实测唯一可靠修复）。
- 两层验证：运行层（`ghc -v0 -O0 --make main.hs -o build\NN.exe` exit 0 + exe 运行 exit 0 + stdout 含
  `==== NN 结束 ====`）→ 测试层（runtests.hs 同法）→ 特判（02 传参、20/24 stack 工程、22 `-threaded
  -rtsopts "-with-rtsopts=-N4"`、23 FFI 链接）。
- 禁用 runghc 做验证（恒 ~41s）；GHCi/runghc 只在正文教学层出现。
- 主线只用 boot 库；hackage 包只作生态介绍（不 install）。每目录一个 LanguageExtensions 头注释
  说明所用扩展（主线默认 Haskell2010，扩展逐章引入）。
- 章号 = 示例目录号；正文 150–250 行（⭐ 章不压缩）；坑位清单 3–6 条/章。
- build.ps1 / run-all.sh 一律 UTF-8 **无 BOM**、LF；pwsh 7 运行。
- 源码文件 UTF-8 无 BOM；示例代码零编译警告（GHC 默认级别）。
- stack 工程（20/24）stack.yaml 固定四行：`resolver: lts-24.59` / `compiler: ghc-9.12.1` /
  `system-ghc: true` / `install-ghc: false`。
- 提交带 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## 自制断言/测试框架范式（Task 1 在 02/03 确立，后续沿用）

main.hs 内自检（失败即错、exit 非 0）：

```haskell
check :: (Eq a, Show a) => String -> a -> a -> IO ()   -- check 说明 实际 期望
check label actual expected
  | actual == expected = return ()
  | otherwise = error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
```

runtests.hs 迷你框架（收集统计、失败 exitFailure，末行同样打印 `==== NN 结束 ====`）：

```haskell
data Result = Result Int Int   -- 通过数 / 失败数
runSuite :: String -> [(String, Bool)] -> IO ()      -- 组名 + [(用例名, 布尔)]
runSuite group cases = do
  let fails = [n | (n, ok) <- cases, not ok]
  putStrLn (group ++ ": " ++ show (length cases - length fails) ++ "/" ++ show (length cases))
  ... 失败时 putStrLn 用例名；汇总失败则 exitFailure
```

（精确签名以 Task 1 实测为准；runtests.hs 通过 `import` 复用 main.hs 中可测纯函数——main 的 IO
演示不复用，纯逻辑全部提出为顶层函数。）

---

### Task 1: 基础设施——build.ps1 + run-all.sh + 示例模板

**Files:**
- Create: `haskell/build.ps1`（仿 `julia/build.ps1`：六条判定 + `.NET ProcessStartInfo` 起进程 +
  `-All/-Example NN_topic/-Clean/-ShowOutput`；差异点见下）
- Create: `haskell/run-all.sh`（bash 版双入口，对齐 julia/run-all.sh）
- Create: `haskell/examples/02_hello/`（作为模板首例，Task 2 完成内容）

**build.ps1 与 Julia 版差异（关键设计）:**
- 工具定位：`-Ghc` 参数 → `GHC` 环境变量 → PATH 上 ghc → `G:\scoop\apps\haskell\current\bin\ghc.exe`。
- 运行层两步：`ghc -v0 -O0 --make <dir>/main.hs -o build/<name>.exe`（cwd=示例目录，`-outputdir
  build/<name>_obj` 集中对象文件）→ 运行 exe 判六条。测试层同法编 runtests.hs。
- 特判表（switch $name）：02 传 `("Haskell", "9.12")` 演示参数；22 编译旗标追加 `-threaded -rtsopts
  "-with-rtsopts=-N4"`；20/24 走 stack 分支——先探测可用 strip 前置 PATH（`Get-Command strip` 逐个
  `--version` 试跑，失败则跳过该目录；防止残留坏 shim 再现），再 `stack build` + `stack test` +
  `stack run <args>` 按六条判定 stack run 的 stdout/exit。
- GHC 诊断字样判定：`Warning|error:|Error|Exception`。
- 编码：`[Console]::OutputEncoding = UTF8`；读输出文件按 UTF-8（源端 hSetEncoding 保证）。

- [ ] Step 1: 写 `haskell/build.ps1`（上述结构）
- [ ] Step 2: 写 `haskell/run-all.sh`（等价判定：exit 0 / stderr 空 / stdout 非空 / 结束标记 / 无诊断字样）
- [ ] Step 3: 建目录骨架 `haskell/{docs,examples}`；02_hello 写通首例（见 Task 2 规格）后
  `pwsh ./build.ps1 -Example 02_hello` 全绿，模板定型
- [ ] Step 4: Commit `feat(haskell): build.ps1/run-all.sh 验证骨架与 02 示例模板`

### Task 2: 批次 A——02_hello / 03_numbers / 04_control / 05_functions

**Files:** Create `examples/02_hello/`, `03_numbers/`, `04_control/`, `05_functions/`（各含 main.hs + runtests.hs）

**02_hello（编码与入口章）:** GHCi 三态（ghc 编译 / runghc 脚本 / ghci 交互，正文给实测耗时对照表：
编译 warm 1.2s、runghc ~41s 坑）；putStrLn/print/show；getArgs + 空参容忍（`case args of [] -> 演示路径`）；
hSetEncoding 开场；CRLF 说明。runtests 断言 getArgs 分派纯逻辑（提为 `greet :: [String] -> String`）。
**03_numbers:** Int/Integer（溢出对照）/Word/Double/Rational；类型类层次 `Num → (Fractional|Integral)`；
`/` 需 Fractional、div/mod 与 quot/rem 负数差异、fromIntegral 必须性（length→Double 实测类型错）；
read 部分函数坑（用 readMaybe?——Text.Read 是 boot ✓）；字面量 defaulting 规则；show/showEFloat 一瞥。
**04_control:** if 必有 else；guard + otherwise 必需；case；let…in vs where；递归替代循环（sum/fact/fib
朴素 vs 累加器）；尾递归与栈（朴素 fib 30 计时 vs 累加器即时）。
**05_functions:** 柯里化（`add x y` 与部分应用）；`.`/`$` 优先级对照；sections（`(subtract)` 与负数字面量
`(-1)` 陷阱：`(- 3)` 非法）；flip；匿名函数；eta 缩约；自定义中缀运算子（`+++` 优先级）；点自由重构示例。
每例 8–12 个 `# ═══ N.M` 分节；断言 10+ 条。

- [ ] Step 1: 四目录 main.hs + runtests.hs 全部写完
- [ ] Step 2: `pwsh ./build.ps1 -Example 02_hello`（及 03/04/05）逐个全绿；`-All` 跑通当前 4 例
- [ ] Step 3: Commit `feat(haskell): 批次 A——02 hello/03 numbers/04 control/05 functions`

### Task 3: 批次 B——06_patterns / 07_adt / 08_typeclasses

**06_patterns ⭐:** 函数参数模式；卫兵；`@` 绑定；列表模式（首:尾、@整表）；元组模式；字面量模式；
case 穷尽性警告演示（非穷尽编译警告 + 运行异常）；惰性模式 `~`（无限元组安全解构）；视图模式一瞥
（`-XViewPatterns`，一个例子即止）。示例：简易表达式简化器/键值解析。
**07_adt ⭐:** data 定义（形状=和×积）；记录语法 + update 语法；deriving (Show, Eq, Ord)（Ord 派生顺序
= 构造子声明顺序坑）；newtype 零成本 + 区别（模式匹配严格性）；Maybe/Either 用法；递归数据 IntList/
Tree + insert/size/height/showTree；严格字段 `!` 一瞥（对照 10 章）；不可变值语义（update 是拷贝）。
**08_typeclasses ⭐:** class/instance 定义（Shape 面积族）；superclass（Num→Real 等）；minimal 注解；
约束多态（`show Twice`）；deriving 深入：stock/newtype/any 三态（9.12 语法 `deriving newtype (Num)`）；
orphan instance 规则与规避；Kind 一瞥（`*`→`Type`、Functor 是 `Type -> Type`）；instance 头不能是
类型同义词等小坑。

- [ ] Step 1: 三目录写完（⭐ 章 main.hs 12–16 分节，断言 15+）
- [ ] Step 2: build.ps1 逐例全绿
- [ ] Step 3: Commit `feat(haskell): 批次 B——06 patterns/07 adt/08 typeclasses`

### Task 4: 批次 C——09_lists / 10_laziness / 11_containers

**09_lists ⭐:** `(:)` 右递归结构与模式匹配；map/filter/zip/zipWith；foldr（短路与 `and`）/foldl/
**foldl'**（Data.List，引入"必须严格折叠"）；scanl/scanr（前缀和）；iterate/take/drop/repeat/cycle；
unfoldr（斐波那契/展开生成器）；列表推导（含守卫与并行 zip 系 `-XParallelListComp` 只提一句）；
建造塔素数筛（无穷 + filter 组合）；length/isPrefixOf 等速查。
**10_laziness ⭐:** thunk 图解（文字版）；无穷列表 take 安全性；自我引用（`xs = 1 : map (+1) xs`）；
fix 一瞥（Data.Function.fix）；seq 语义与坑（seq x x' 不保证内层）；deepseq（Control.DeepSeq boot ✓）；
bang patterns（`-XBangPatterns`）；**空间泄漏复现**：foldl (+) 0 大列表（RTS -s 内存对照 foldl'），
断言只断结果值不断内存数字；where 绑定共享 vs 函数体重复求值。
**11_containers:** Data.Map（fromList/insert/lookup/alter/delete/union/elems/keys/toAscList；严格
Map.Strict 一句）；Data.Set（成员/交并差）；Data.IntMap 一句；元组族（fst/snd/swap）；Foldable 概念
（mapM_/toList 对 Map/Set 通用）；Traversable（mapM/sequenceA 一瞥）。

- [ ] Step 1: 三目录写完
- [ ] Step 2: build.ps1 逐例全绿（10 章泄漏演示注意运行时长 <5s）
- [ ] Step 3: Commit `feat(haskell): 批次 C——09 lists/10 laziness/11 containers`

### Task 5: 批次 D——12_strings / 13_fam / 14_mtl

**12_strings ⭐:** String=[Char] 真相与代价；Data.Text（pack/unpack/length/words/lines/toUpper/
splitOn——splitOn 在 text ✓）；Data.ByteString（Word8 语义）；ByteString↔Text↔String 转换表；
OverloadedStrings 扩展（字面量多态）；**codepoint vs 字节**：T.length 数的是 Char（码点），中文 1、emoji
家族可 >1（实测 `T.length "🇨🇳"`=2——代理对合并 vs 组合）；Data.Text.Encoding decodeUtf8'（ Either
返回）vs decodeUtf8（抛）；性能选型表（短→String/长→Text/网络→ByteString）。
**13_fam ⭐:** Functor（fmap/<$>；Law: id）；Applicative（pure/<*>；Maybe 的短路、列表的笛卡尔；
Law 一览）；Monad（>>=；do 记法脱糖逐行对照）；手写 State newtype（runState/sget/sput——为 14 铺路）；
Maybe/Either/IO 三单子对照（同一"查找-链式"任务三种写法）；Alternative 一瞥（empty/<|>，Maybe 首个
Just）；三大定律各配"反例断言"（定律即测试）。
**14_mtl ⭐:** transformers 直用（Control.Monad.Trans.State 的 state/runStateT/evalStateT；ExceptT；
ReaderT；lift）；mtl 风格（MonadState/MonadError 类型类约束函数：`foo :: MonadState Env m => m ()`，
同一段逻辑跑 StateT Identity 与 IO 两种单子）；**手写 xorshift64\* PRNG**（Word64 位运算、纯函数
`next :: Word64 -> (Double, Word64)`、种子确定性断言、State 化 `random :: State Word64 Double`、
蒙特卡洛 π 一瞥）；Writer 一瞥（tell + DList 思想，性能注记）。

- [ ] Step 1: 三目录写完（⭐ 章 12–16 分节）
- [ ] Step 2: build.ps1 逐例全绿
- [ ] Step 3: Commit `feat(haskell): 批次 D——12 strings/13 fam/14 mtl`

### Task 6: 批次 E——15_parsec / 16_files / 17_errors

**15_parsec ⭐:** Text.Parsec.String Parser；string/char/many1/many/optional/<|> 与回溯边界（try 的
必要性实测：前缀共享分支）；choice；sepBy/sepEndBy；notFollowedBy 一瞥；parse 返回 Either ParseError
（错误消息格式实测）；小计算器（词法跳空格 → buildExpressionParser 四级优先级 + 括号 + 整数）；
与 24 章 MiniLang 的关系埋点。
**16_files:** writeFile/appendFile；readFile **惰性坑**（内容未消费完句柄已关的场景 + readFile 严格读
法：hSetBuffering 或 Data.ByteString.readFile 然后 decode）；withFile；目录操作（directory boot：
listDirectory/createDirectory/doesFileExist/copyFile/removeFile；**listDirectory 不含 "." ".." 且顺序
不定——断言前先 sort**）；递归遍历手写；临时文件（openBinaryTempFile? 实测 base System.IO 的
openTempFile 可用性，不可用则用 `getTemporaryDirectory` + pid+counter 命名——以实测为准写进坑位）；
二进制读写（ByteString）。
**17_errors:** Maybe vs Either 选型；自定义错误 ADT + `either`/`maybe` 组合子；Control.Exception：
`try :: Exception e => IO a -> IO (Either e a)`（选定具体异常类型——SomeException 过宽的坑）；
IOException 捕获（读不存在文件）；throw vs throwIO（纯 throw 惰性：不 force 不触发——实测）；
evaluate 强制；bracket/finally/onException（资源三段式）；自定义异常类型（Exception 实例 +
displayException）；纯代码里的 error/undefined 定位（只该在"不可能分支"）。

- [ ] Step 1: 三目录写完
- [ ] Step 2: build.ps1 逐例全绿（16 章操作限 build/ 下临时目录，自清理）
- [ ] Step 3: Commit `feat(haskell): 批次 E——15 parsec/16 files/17 errors`

### Task 7: 批次 F——18_th / 19_performance / 21_testing

**18_th ⭐:** -XTemplateHaskell；表达式引号 `[| ... |]`、类型引号 `''Maybe`；Q Monad + runQ 只在
GHCi 演示（正文提示）；`$( ... )` 拼接（编译期生成记录访问器族/常量表）；lift；typed TH 一瞥
`[|| ... ||]`（9.12 稳定）；reify（查 Maybe 的构造子信息——元编程自省）；**TH 坑**：引号内不能引用
局部变量、阶段限制（一个模块的 TH 不能看同模块定义——两文件拆分实测）；GHC.Generics 一瞥
（deriving Generic + Rep 结构 + 泛型"字段计数/构造子名"函数）；deriving 机制对照（stock vs TH vs
Generics 各自适用）。
**19_performance ⭐:** 基线：`getCPUTime`/`getMonotonicTime`（GHC.Clock boot ✓）计时三件套；
-O0 vs -O2 实测对照（同一纯计算）；foldl 堆泄漏复现（RTS +RTS -s 的 alloc 总量对比写进正文，断言
只断值）；-ddump-strictness 看严格性分析（正文演示，验证层不开）；String 拼接 O(n²) vs Text.builder
（Data.Text.Lazy.Builder? text boot 含 ✓）实测；空间泄漏三板斧（foldl'/deepseq/bang）；criterion/
ghc-prof 生态介绍表（不安装）；RTS 选项速查（-N/-H/-s/-K）。
**21_testing:** 自制框架正文化（Task 1 范式升格：分组/统计/失败明细/exitFailure）；**手写
mini-QuickCheck**：Generate 类型类（Bool/Int/Double/[a]）、withSeed（14 章 xorshift）、shrinking
（整数减半向 0、列表取前半）、`forAll :: (Show a) => Gen a -> (a -> Bool) -> Property`、跑 100 例
性质（排序幂等/最大值上界/字符串往返 pack-unpack）；HUnit/tasty/QuickCheck 生态对照表；与 20 章
stack test 的衔接埋点。

- [ ] Step 1: 三目录写完
- [ ] Step 2: build.ps1 逐例全绿
- [ ] Step 3: Commit `feat(haskell): 批次 F——18 th/19 performance/21 testing`

### Task 8: 批次 G——20_stackenv（stack 工程）/ 22_concurrency / 23_ffi

**20_stackenv ⭐（stack 工程）:** 目录：`20_stackenv/`（stack.yaml 四行 + `stackenv.cabal` + `app/
Main.hs` + `src/Lib.hs` + `test/Spec.hs`）。内容：库模块（纯函数若干 + 自检）；exe 演示（调用库 +
输出标记）；test-suite（自制框架 + exitFailure）；正文讲清 stack.yaml 逐键、snapshot/resolver 概念、
**TUNA 镜像三行配置 + global-hints 手动下载（fpco 路径）**、`compiler: ghc-9.12.1` 覆盖与 system-ghc、
坏 strip shim 实测案例（copy 阶段挂/exe 已生成/Cabal 从 ghc 同目录找 strip）、`stack build/test/run/
exec/ghci` 全命令、`stack ls snapshots`、scoop `cabal` 假包警示、HLS/ormolu/hlint 生态地图。
验证：build.ps1 stack 分支（strip 探测前置 + build + test + run 六条判定）。
**22_concurrency ⭐:** forkIO + threadDelay（**微秒**坑）；主线程不等子线程就退（MVar join 或
`threadDelay` 对照实测）；MVar（空满两态：take 阻塞/put 阻塞、生产者-消费者 1 槽、4 槽改 Chan）；
Chan（无限队列流水线 3 级）；**IORef 竞争**：1000 次 `readIORef (+1) writeIORef` 丢更新实测（-N4 下
非确定性——断言"可能小于"，用两次对照：非原子 vs atomicModifyIORef' 恒等）；STM：TVar/atomically/
retry（阻塞重试语义：两账户转账余额守恒断言）/orElse 一瞥；-threaded -N 与单线程运行时对照；
async 库生态一瞥。
**23_ffi:** `foreign import ccall "msvcrt strlen" c_strlen :: CString -> IO CSize`（实测 Windows 链接
msvcrt ✓）；C 类型映射表（CInt/CDouble/CSize/CString）；withCString/peekCString；alloca + peek/poke
（CDouble 写读往返）；纯化包装；kernel32 一例（`GetTickCount`? 实测选一个稳定的——Sleep 毫秒级验证
或 GetSystemTime；以实测为准）；funPtr 回调（`foreign import ccall "wrapper"` 包装 Haskell 闭包——
选 msvcrt qsort 或自建 C 可调目标；若 Windows 实测繁琐则正文以 wrapper 原理 + 最小例为准，坑位记录）；
ByteString useAsCString 透传。

- [ ] Step 1: 三目录写完（20/22 特判先手工跑通：stack build/test/run；-threaded 编译）
- [ ] Step 2: build.ps1 逐例全绿（22 的竞争断言写"非原子可能丢/原子必不丢"两分支）
- [ ] Step 3: Commit `feat(haskell): 批次 G——20 stack 工程/22 concurrency/23 ffi`

### Task 9: 批次 H——24_capstone（MiniLang 迷你解释器，stack 工程）

**Files:** Create `examples/24_capstone/`：stack.yaml（同 20 四行）+ `minilang.cabal`（library +
executable + test-suite）+ `src/{Lexer.hs,Parser.hs,Ast.hs,Eval.hs,Repl.hs,Prims.hs}` + `app/Main.hs`
+ `test/Spec.hs`

**语言特性（够用即止）:** 整数/布尔/字符串字面量；算术比较布尔运算；let 绑定（含递归绑定时 fixpoint
语义：环境自引用）；lambda 与闭包；if/then/else；调用；内建 print/abs/min/max/strlen。
**架构管线:** 词法（手写 tokenizer：关键字/标识符/整数/字符串/运算符 → Token ADT）→ 解析（parsec
逐 Token 解析 → Expr ADT）→ 求值（`type Eval a = ExceptT EvalError (StateT Env Identity) a`——
mtl 风格；闭包 = 函数值携带定义环境；递归 let 用环境回填）→ REPL（stdin 逐行、:quit/:env 命令、
hSetEncoding + hFlush stdout 无缓冲坑）。
**app/Main.hs:** 参数分派——文件模式（读文件→解析→求值，错误打印行列号）vs 无参 REPL；空参容忍；
末行 `==== 24 结束 ====`（REPL 模式喂脚本 via stdin 管道自检）。
**test/Spec.hs:** 三层测试——解析层（字符串→AST 断言 10+）、求值层（程序→值断言 20+：闭包捕获/
递归 fib/高阶/错误路径类型）、性质层（21 章 mini-QuickCheck 复用：随机表达式生成→求值不崩溃即
Either 有值）。stack test exit 0。

- [ ] Step 1: 六源文件 + cabal + Main.hs 写完，`stack build` 过
- [ ] Step 2: `stack test` 全绿；`stack run` 文件模式/REPL 管道模式手工验证
- [ ] Step 3: build.ps1 -Example 24_capstone 全绿
- [ ] Step 4: Commit `feat(haskell): 24 压轴——MiniLang 迷你解释器 stack 工程`

### Task 10: docs/ 24 章正文

**Files:** Create `haskell/docs/01-overview.md` … `24-capstone.md`（24 个文件；每章头部 `> 对应示例：
examples/NN_topic/`；小节号与示例 `# ═══ N.M` 一致；每章末"坑位清单"3–6 条）

**01-overview（无示例）:** 定位（纯函数式+强静态+惰性；与 C++/Python/Julia 一句话对照）；λ演算与
Haskell 血统一段；GHC 是什么/9.12 现状/语言扩展体系一段；生态地图（stack/cabal/HLS/hackage/
stackage）；本机工具链实测速览（含镜像配置指引指向 20 章）；学习方法论（REPL 先行、类型驱动、
"读错误消息"）。
**02–23 章:** 按 Task 2–8 各章规格成文：示例代码块 + 行为解释 + 与 C++/Python 惯用法对照 + 坑位。
**24-capstone:** 管线架构图（文字版）、三件套逐文件讲解、REPL 演示实录、扩展练习列表（浮点/列表
类型/模式匹配语法糖/尾调用优化）。

- [ ] Step 1: 01 + 02–05 章（批次 A 对应）
- [ ] Step 2: 06–08 / 09–11 / 12–14 章（批次 B/C/D 对应）
- [ ] Step 3: 15–17 / 18–21 / 22–23 章
- [ ] Step 4: 24 章；通读交叉引用（章节互指/速查表指向）
- [ ] Step 5: Commit `docs(haskell): 24 章正文`

### Task 11: 收官——CHEATSheet / README / 根 README / 全量终验 / 记忆

**Files:**
- Create: `haskell/CHEATSheet.md`（语法速查大表 + 实测坑位索引：编码/runghc 慢/stack 镜像/compiler
  覆盖/strip shim/cabal 假包/CRLF 等，与 Julia CHEATSheet 同风格）
- Create: `haskell/README.md`（定位、目录结构、章节索引表、工具链与镜像配置、验证命令、相关教程）
- Modify: 根 `README.md`（语言列表加 haskell 条目，含一句定位）
- Create 记忆: `G:\xulun\.claude\projects\G--code-guide\memory\haskell-tutorial-build.md` + 更新
  `MEMORY.md` 索引

- [ ] Step 1: CHEATSheet + README + 根 README
- [ ] Step 2: `pwsh ./build.ps1 -All` 全量终验（23 目录 × 2 层全绿）+ `bash run-all.sh` 抽查
- [ ] Step 3: 记忆文件写入；全部提交 `docs(haskell): 收官——CHEATSheet/README/全量终验`

## Self-Review 结论

- 规格覆盖：spec §5 章节表 24 章全部落入 Task 2–9；§6 验证设计 = Task 1；§7 交付物 = Task 1–11
  （根 README、记忆、run-all.sh 均有）；环境坑位（编码/strip/镜像/compiler 覆盖）分别落在 02/20 章
  正文与 build.ps1。
- 无占位符：所有"以实测为准"处均为**正文教学决策点**（如 23 章选哪个 kernel32 函数），代码骨架与
  断言规格均已给出；实施中实测翻新属教程系列惯例（执行勘误累积制）。
- 命名一致性：示例目录名与 docs 文件名 = spec §5 表逐一对应；结束标记 `==== NN 结束 ====` 全文统一。
