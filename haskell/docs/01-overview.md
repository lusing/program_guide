# 01 · Haskell 全景

> 对应示例：无（本章是地图）

## 1.1 Haskell 是什么

Haskell 是一门**纯函数式、强静态类型、惰性求值**的语言。三个定语各拆一句：

- **纯函数**：函数像数学函数——同样的输入永远给同样的输出，没有副作用。`x + 1` 就是 `x + 1`，不会顺手改全局变量、写日志、发网络请求。副作用（打印、读文件）被类型系统圈进 `IO` 单子，看类型签名就知道哪里"不纯"。
- **强静态类型**：编译期抓类型错误，且几乎不用写类型——**类型推断**替你算。签名是文档，也是编译器给你的免费测试。
- **惰性求值**：值按需计算。可以定义无穷列表 `[1..]`，取多少算多少（10 章专讲，包括它的坑）。

与你会的语言对照：

| 你熟悉的 | Haskell 的不同 |
|---|---|
| C++/Java 的类与继承 | 没有类——**类型类**（type class，08 章）按行为组织类型 |
| Python 的 list/dict | 列表是递归定义的代数数据类型（07/09 章），Map/Set 是库 |
| 循环 `for`/`while` | 没有语句、没有循环——**递归与折叠**是唯一的"迭代"（04/09 章） |
| `null` | 没有 null——`Maybe a` 显式表达"可能没有"（07 章） |
| 异常满天飞 | 纯错误用 `Either`（17 章），异常只管真正意外的 IO |
| 多线程锁 | STM 内存事务（22 章），`atomically` 一把梭 |

## 1.2 血统与生态

Haskell 1990 年发布，得名于逻辑学家 Haskell Curry，是 λ 演算的直系后代。社区梗"Haskell 避开了成功陷阱"——它更像**编程语言思想的试验田**：类型类、单子、STM 都从这里走向主流（Rust 的 trait、Java 的 Optional、async/await 的单子本质，都有它的影子）。

生态三件套：

- **GHC**：唯一主流编译器（本教程用 9.12.1）。语言核心之上叠了几百个**语言扩展**（`{-# LANGUAGE ... #-}`），按需逐个开——这是 Haskell 的特色也是争议点。
- **Cabal / Stack**：包管理与构建（20 章）。本教程主线用 **stack**（配清华镜像，stackage.org 系在国内被墙是实测现实）。
- **Hackage / Stackage**：包仓库（前者全量、后者策划过的版本组合即 snapshot/LTS）。

其他：HLS（语言服务器，IDE 体验）、ormolu/fourmolu（格式化）、hlint（提示）、QuickCheck（性质测试鼻祖）。

## 1.3 本机工具链（实测速览）

| 项 | 本教程实测（Windows 11 + scoop） |
|---|---|
| GHC | 9.12.1 @ `G:\scoop\apps\haskell\current`（scoop main 的 `haskell` 包） |
| stack | 3.11.1（scoop main） |
| 镜像 | stackage 被墙 → 清华 TUNA（20 章给三行配置） |
| boot 库 | mtl/stm/parsec/text/bytestring/containers/exceptions 随 GHC 发行——**本教程主线零外部依赖** |
| 假包警示 | scoop extras 的 `cabal` 8.0.0 是**同名 Electron 聊天应用**，不是 cabal-install（实测踩过） |

验证环境：

```
ghc --version           # The Glorious Glasgow Haskell Compilation System, version 9.12.1
stack --version         # Version 3.11.1
ghc-pkg list | head     # 看随 GHC 发行 boot 库清单
```

## 1.4 三种运行方式（02 章实操）

| 方式 | 命令 | 用途 | 实测耗时 |
|---|---|---|---|
| 编译执行 | `ghc -o app main.hs && ./app` | 正式产物 | 冷启动 ~19s（首初始化），warm ~1.2s |
| 脚本直跑 | `runghc main.hs` | 快速试 | **~41s**（GHCi 链接器在 Windows 的老毛病） |
| 交互 | `ghci` | 边写边试 | 进入 ~2s |

结论（本机实测）：验证/CI 一律走编译执行；`runghc` 只在正文演示里出现。

## 1.5 学习方法

1. **GHCi 先行**：`:t expr` 看类型、`:i Type` 看类型类、`:r` 重载——REPL 是第一工具。
2. **类型驱动**：写不出实现？先写签名。签名对了，实现常常"只剩一种写法"。
3. **读错误**：GHC 错误消息长但信息密度高——`Couldn't match type` 是 90% 的日常。
4. **别怕单子**：它只是"带上下文的组合"（13 章从零手写一个），不是玄学。
5. **坑位意识**：本教程每章末有实测坑位清单——Windows 编码、惰性泄漏、默认警告……都踩过、验过。

## 1.6 全书地图

```
02 入门工具链   03 数值          04 控制流       05 函数
06 模式匹配⭐   07 代数数据类型⭐ 08 类型类⭐
09 列表与折叠⭐ 10 惰性求值⭐     11 容器
12 字符串⭐     13 函子·应用·单子⭐ 14 单子变换器⭐
15 解析器组合子⭐ 16 文件        17 错误处理
18 编译期魔法⭐ 19 性能⭐        20 Stack 工程⭐
21 测试        22 并发与 STM⭐   23 FFI
24 实战：MiniLang 迷你解释器⭐
```

⭐ 为 Haskell 特色重点章。每章对应 `examples/NN_topic/`，`main.hs` 是演示、`runtests.hs` 是断言套件，
全部可在本机复现（`pwsh ./build.ps1 -All`）。
