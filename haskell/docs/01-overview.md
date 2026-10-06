# 01 · Haskell 全景

> 对应示例：无（本章是地图）。
> 本章对应原书第 1 章〈何谓函数式程序设计〉：1.3 节的应用记号、1.4 节的复合与高频词管线
> 提炼自书 1.1–1.3；书 1.5 的 Haskell Platform 已成历史，1.6 节按 2026 年现实改写。

## 1.1 Haskell 是什么

Haskell 是一门**纯函数式、强静态类型、惰性求值**的语言。三个定语各拆一句：

- **纯函数**：函数像数学函数——同样的输入永远给同样的输出，没有副作用。`x + 1` 就是 `x + 1`，不会顺手改全局变量、写日志、发网络请求。副作用（打印、读文件）被类型系统圈进 `IO` 单子，看类型签名就知道哪里"不纯"。
- **强静态类型**：编译期抓类型错误，且几乎不用写类型——**类型推断**替你算。签名是文档，也是编译器给你的免费测试。
- **惰性求值**：值按需计算。可以定义无穷列表 `[1..]`，取多少算多少（12 章专讲，包括它的坑）。

与你会的语言对照：

| 你熟悉的 | Haskell 的不同 |
|---|---|
| C++/Java 的类与继承 | 没有类——**类型类**（type class，08 章）按行为组织类型 |
| Python 的 list/dict | 列表是递归定义的代数数据类型（07/09 章），Map/Set 是库 |
| 循环 `for`/`while` | 没有语句、没有循环——**递归与折叠**是唯一的"迭代"（04/09 章） |
| `null` | 没有 null——`Maybe a` 显式表达"可能没有"（07 章） |
| 异常满天飞 | 纯错误用 `Either`（20 章），异常只管真正意外的 IO |
| 多线程锁 | STM 内存事务（29 章），`atomically` 一把梭 |

## 1.2 血统与生态

Haskell 1990 年发布，得名于逻辑学家 Haskell Curry，是 λ 演算的直系后代。社区梗"Haskell 避开了成功陷阱"——它更像**编程语言思想的试验田**：类型类、单子、STM 都从这里走向主流（Rust 的 trait、Java 的 Optional、async/await 的单子本质，都有它的影子）。

生态三件套：

- **GHC**：唯一主流编译器（本教程用 9.14.1）。语言核心之上叠了几百个**语言扩展**（`{-# LANGUAGE ... #-}`），按需逐个开——这是 Haskell 的特色也是争议点。
- **Cabal / Stack**：包管理与构建（27 章）。本教程主线用 **stack**（配清华镜像，stackage.org 系在国内被墙是实测现实）。
- **Hackage / Stackage**：包仓库（前者全量、后者策划过的版本组合即 snapshot/LTS）。

其他：HLS（语言服务器，IDE 体验）、ormolu/fourmolu（格式化）、hlint（提示）、QuickCheck（性质测试鼻祖）。

## 1.3 函数与类型：先学会读记号

原书第 1 章用三句话定义函数式程序设计：**强调函数及其应用而非命令；用简单的数学语言描述问题；
数学基础简单到可以对程序性质做推理**。这三句是全教程的纲领。先把"数学语言"最基础的三块记号学
会——应用、类型、复合——你就能读懂任何 Haskell 签名。

**函数类型用 `::` 连接两端**。`f :: X -> Y` 读作"f 是一个函数，吃 `X` 类型的参数，返回 `Y`
类型的结果"。例如：

```haskell
sin      :: Float -> Float        -- 浮点正弦
age      :: Person -> Int         -- 从人取年龄
logBase  :: Float -> (Float -> Float)   -- 注意：返回的是一个函数！
```

**函数应用就是一个空格**，不用括号。`sin 3.14`、`sin(3.14)` 都合法；多字母函数名与参数之间
必须留空格——`latex` 是一个名字，`late x` 才是"函数 `late` 应用于 `x`"。二元对数要写
`logBase 2 10`（以 2 为底 10 的对数）：它的类型说明一切——`logBase` 吃一个底数，**返回一个
函数**，这个函数再吃真数。所以 `logBase 2` 恰好就是数学里的 log₂，这叫**部分应用**，是柯里化
的第一印象（05 章展开）。

两条运算规则，从第一条起就刻进肌肉：

1. **应用左结合**：`f x y` 是 `(f x) y`——先算左边的应用。
2. **应用优先级最高**：`double 3 + 4` 是 `(double 3) + 4`；三角恒等式 sin 2θ = 2·sinθ·cosθ
   写成 Haskell 是 `sin (2*theta) = 2 * sin theta * cos theta`——乘法要写 `*`，括号只围住
   `2*theta` 一处，因为 `sin theta` 自己会先结合。

## 1.4 函数复合：第一个思维工具

有了应用，第二个工具是**复合**。`f :: Y -> Z` 与 `g :: X -> Y` 复合成：

```haskell
f . g :: X -> Z
```

它先把 `g` 应用于 `X`，再把 `f` 应用于结果。恒等式是 `(f . g) x = f (g x)`。复合**从右往左**
执行——因为我们习惯把函数写在参数左边。复合是可结合的（`(f . g) . h = f . (g . h)`），
单位元是恒等函数 `id :: a -> a; id x = x`——这两条律以后证明程序性质时反复出现（11 章）。

为什么说复合是"思维工具"而不只是语法糖？看下一个例子。

## 1.5 第一个完整管线：高频词统计

问题：*《战争与和平》里出现最多的 100 个词是哪些？*——原书用这个问题演示函数式的解题姿势。
先写类型（**确定类型是找到合适定义的第一步**）：

```haskell
commonWords :: Int -> String -> String
--          n     文本    "词: 次数" 逐行排列的结果
```

怎么从"一串字符"到"高频词报表"？把问题**按类型分解**成一串小函数，每个小函数的类型两头一接，
像水管一样串起来：

| 环节 | 类型 | 职责 |
|---|---|---|
| `map toLower` | `String -> String` | 全部转小写（"The"与"the"算一个词） |
| `words` | `String -> [String]` | 按空白切分成词的列表（Prelude 自带） |
| `sortWords` | `[String] -> [String]` | 按字典序排序——**重复词就此相邻** |
| `countRuns` | `[String] -> [(Int, String)]` | 数出每段连续重复的长度：`[(2,"be"),(1,"not")…]` |
| `sortRuns` | `[(Int, String)] -> [(Int, String)]` | 按次数**递减**排序 |
| `take n` | `[(Int, String)] -> [(Int, String)]` | 取前 n 个 |
| `map showRun` | `[(Int, String)] -> [String]` | 每行做成 `"be: 2\n"` |
| `concat` | `[String] -> String` | 拼回一整个字符串 |

全部用 `.` 串起来，主定义一行：

```haskell
import Data.Char (toLower)
import Data.List (sort, sortOn, group)

commonWords :: Int -> String -> String
commonWords n = concat . map showRun . take n . sortRuns
              . countRuns . sortWords . words . map toLower
  where
    sortWords = sort                                -- 排序让重复词相邻
    countRuns  = map (\ws -> (length ws, firstOf ws)) . group
    firstOf    = foldr (\x _ -> x) ""               -- 全函数版 head（9.12 起 head 有警告）
    sortRuns   = sortOn (negate . fst)              -- 按次数递减 = 按次数相反数递增
    showRun (k, w) = w ++ ": " ++ show k ++ "\n"
```

在 GHCi 里跑（本教程全部代码 GHC 9.14.1 实测）：

```
ghci> putStr (commonWords 5 "to be or not to be; To BE, or not to BE")
to: 4
be: 2
not: 2
or: 2
be,: 1
```

逐行读这个结果能学到三件事：

1. **管线思维**：8 个环节各管一步，`commonWords` 的定义就是问题本身的叙述——"小写化、切词、
   排序、计数、按频排序、截取、格式化、拼接"。没有循环变量，没有中间状态。
2. **排序是信息提取器**：人工统计时没人先排序，但"排序使重复相邻"是把计数问题化归为
   `group + length` 的关键一步——这是算法设计里被低估的思想。
3. **定义即规范**：输出里 `be,` 带着逗号——我们的"词 = 空白分隔的字符序列"这一定义允许标点
   混进来。想改行为就改 `words` 那一环（如先过滤标点），其余环节不动。函数管线每一环都
   可以独立替换，这是 09 章折叠与 11 章融合律的伏笔。

## 1.6 从 Haskell Platform 到现代工具链

原书 1.5 节教你下载 **Haskell Platform**——一个捆绑 GHC + 一堆库的"全家桶"。这是 2015 年的
主流方案，**如今已成历史**：Platform 于 2010 年代末停止更新，官方早已不推荐。现代安装三选一：

| 方案 | 命令 | 适合 |
|---|---|---|
| **GHCup**（官方推荐） | 官网脚本一键装 | 管理多版本 GHC/cabal/HLS，全平台 |
| **scoop**（Windows） | `scoop install haskell` | 本教程路线：装完即得 `ghc`/`ghci`/`ghc-pkg` |
| **stack 自带** | `stack setup` | 让 stack 全权管理 GHC（本教程不用，见 27 章） |

书中-era 的另一个化石是 `WinGHCi`（GHCi 的图形窗口），也已消失——今天的 GHCi 就是终端程序，
但书里教的用法全部健在且仍是日常：`3 - 5` 当超级计算器、`import Data.Char` 后提示符变化、
`:set prompt "ghci> "` 改提示符、`:load "脚本名"` 加载脚本。

## 1.7 本机工具链（实测速览）

| 项 | 本教程实测（Windows 11 + scoop） |
|---|---|
| GHC | 9.14.1 @ `G:\scoop\apps\haskell\current`（scoop main 的 `haskell` 包） |
| stack | 3.11.1（scoop main） |
| 镜像 | stackage 被墙 → 清华 TUNA（27 章给三行配置） |
| boot 库 | mtl/stm/parsec/text/bytestring/containers/exceptions 随 GHC 发行——**本教程主线零外部依赖** |
| 假包警示 | scoop extras 的 `cabal` 8.0.0 是**同名 Electron 聊天应用**，不是 cabal-install（实测踩过） |

验证环境：

```
ghc --version           # The Glorious Glasgow Haskell Compilation System, version 9.14.1
stack --version         # Version 3.11.1
ghc-pkg list | head     # 看随 GHC 发行 boot 库清单
```

## 1.8 三种运行方式（02 章实操）

| 方式 | 命令 | 用途 | 实测耗时 |
|---|---|---|---|
| 编译执行 | `ghc -o app main.hs && ./app` | 正式产物 | 冷启动 ~19s（首初始化），warm ~1.2s |
| 脚本直跑 | `runghc main.hs` | 快速试 | **~41s**（GHCi 链接器在 Windows 的老毛病） |
| 交互 | `ghci` | 边写边试 | 进入 ~2s |

结论（本机实测）：验证/CI 一律走编译执行；`runghc` 只在正文演示里出现。

## 1.9 学习方法

1. **GHCi 先行**：`:t expr` 看类型、`:i Type` 看类型类、`:r` 重载——REPL 是第一工具。
2. **类型驱动**：写不出实现？先写签名。签名对了，实现常常"只剩一种写法"（1.5 节已演示）。
3. **读错误**：GHC 错误消息长但信息密度高——`Couldn't match type` 是 90% 的日常。
4. **别怕单子**：它只是"带上下文的组合"（16 章从零手写一个），不是玄学。
5. **坑位意识**：本教程每章末有实测坑位清单——Windows 编码、惰性泄漏、默认警告……都踩过、验过。

## 1.10 全书地图（六篇 31 章）

```
一 语言基础      01 全景            02 第一个程序      03 数值
                04 控制流          05 函数            06 模式匹配⭐
                07 代数数据类型⭐   08 类型类⭐
二 列表与推理    09 列表与折叠⭐     10 数独解题器⭐     11 证明与归纳⭐
                12 惰性求值⭐       13 无穷列表⭐       14 容器
                15 字符串⭐
三 单子与结构    16 函子·应用·单子⭐ 17 单子变换器⭐     18 State 与 ST⭐
                19 文件            20 错误处理
四 解析与实战    21 手写解析器⭐     22 parsec⭐        23 交互式计算器⭐
五 工程与性能    24 编译期魔法⭐     25 性能⭐          26 优美打印⭐
                27 Stack 工程⭐     28 测试            29 并发与 STM⭐
                30 FFI
六 收官          31 实战：MiniLang 迷你解释器⭐
```

⭐ 为重点章。第 2/3/9 篇的主干与第 10/11/13/18/21/23/26 章直接取材原书；每章对应
`examples/NN_topic/`，`main.hs` 是演示、`runtests.hs` 是断言套件，全部可在本机复现
（`pwsh ./build.ps1 -All`）。

## 1.11 练习（选自原书第 1 章习题）

**练习 1.1（应用与优先级）**：`double x = 2 * x`。求值 `map double [1,4,4,3]` 与
`map (double . double) [1,4,4,3]`；下列哪些是 sin²θ 的 Haskell 写法——`sin theta ^ 2`、
`sin ^ 2 theta`、`(sin theta) ^ 2`？sin 2θ / 2π 呢？

**练习 1.2（复合律）**：设 `sum :: [Integer] -> Integer`。下列等式哪些成立？为什么？
`sum . map double = double . sum`；`sum . map sum = sum . concat`；`sum . sort = sum`。
（提示：前两条分别依赖乘法分配律与加法结合律；第三条依赖加法交换律。11 章将给出证明。）

**练习 1.3（换一种管线）**：高频词一例中我们"先小写、后切词"（`words . map toLower`）。
请写出"先切词、后把每个词内的字母小写"的等价管线，并说明两条管线为何相等。
（答案：`map (map toLower) . words`——对词的列表逐词做 `map toLower`，两层 `map` 嵌套。）

**练习 1.4（数字转词）**：设计 `convert :: Int -> String`（0 ≤ n < 1000000），如
`convert 308000 = "three hundred and eight thousand"`。原书的策略是**先解更简单的问题**：
`convert1`（0–9，查表 `units !! n`）→ `convert2`（0–99，用 `div/mod` 拆两位、按十位是
0/1/≥2 分情况）→ `convert3`（0–999，`convert3` 复用 `convert2`）→ `convert6`
（0–999999，`convert6` 复用 `convert3` 与连接词 `link`）。请完成 `convert3` 与 `convert6`，
注意 `where (h, t) = (n \`div\` 100, n \`mod\` 100)` 的局部绑定写法。

---

下一章：[02 第一个程序](02-hello.md) ｜ 返回：[README](../README.md)
