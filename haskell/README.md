# Haskell 教程（GHC 9.12.1）

纯函数式 · 强静态类型 · 惰性求值——从零教到能写解释器的程度。
定位：**会编程（C++/Python 背景最佳）、初学 Haskell**；所有示例在 Windows 11 + GHC 9.12.1
（scoop）+ stack 3.11.1（清华镜像）实测通过。主线只用 GHC 自带 boot 库（mtl/parsec/text/
stm/containers…），离线可验证。

## 目录结构

```
haskell/
  docs/        24 章正文（01 全景 → 24 实战 MiniLang 解释器）
  examples/    23 个示例目录（章号 = 目录号）
  build.ps1    验证脚本（pwsh 7；-All / -Example NN_topic / -Clean）
  run-all.sh   bash 版双入口
  CHEATSheet.md 语法速查 + 32 条实测坑位索引
```

每个示例目录（02–23）：`ChNN.hs`（库模块）+ `main.hs`（演示 + 自检 + 结束标记）+
`runtests.hs`（断言套件）——"库 + 双 Main"是 20 章 stack 工程的最小形态。
20/24 为完整 stack 工程（库 + 可执行 + 测试三件套）。

## 章节索引

| # | 主题 | ⭐ |
|---|---|---|
| 01 | 全景：定位、血统、生态、本机工具链 | |
| 02 | 第一个程序：三态运行、编码坑、getArgs | |
| 03 | 数值与类型类层次 | |
| 04 | 控制流：表达式化、guard、递归与累加器 | |
| 05 | 函数：柯里化、组合、sections | |
| 06 | 模式匹配 | ⭐ |
| 07 | 代数数据类型 | ⭐ |
| 08 | 类型类与 deriving | ⭐ |
| 09 | 列表与折叠 | ⭐ |
| 10 | 惰性求值与严格性 | ⭐ |
| 11 | 容器：Map/Set/Foldable | |
| 12 | 字符串三件套 | ⭐ |
| 13 | 函子·应用·单子（含手写 State） | ⭐ |
| 14 | 单子变换器与 mtl（含手写 xorshift） | ⭐ |
| 15 | 解析器组合子 parsec | ⭐ |
| 16 | 文件与目录 | |
| 17 | 错误处理 | |
| 18 | Template Haskell 与 Generics | ⭐ |
| 19 | 性能 | ⭐ |
| 20 | Stack 工程与生态（镜像链路实测） | ⭐ |
| 21 | 测试（自制框架 + mini-QuickCheck） | |
| 22 | 并发与 STM | ⭐ |
| 23 | FFI：调 msvcrt/kernel32 | |
| 24 | 实战：MiniLang 迷你解释器 | ⭐ |

## 工具链（本机实测）

| 项 | 值 |
|---|---|
| GHC | 9.12.1 @ G:\scoop\apps\haskell\current |
| stack | 3.11.1 + 清华 TUNA 镜像（stackage 域被墙，配置见 20 章） |
| 编码 | 示例开头一律 `hSetEncoding stdout/stderr utf8`（Windows 默认 GBK） |
| 依赖 | 主线纯 boot 库；hackage 生态只作介绍 |

## 验证

```bash
pwsh ./build.ps1 -All                 # 全量：23 示例 × 运行层+测试层
pwsh ./build.ps1 -Example 15_parsec   # 单个示例
bash run-all.sh                       # bash 入口
```

判定六条：编译 0 / 运行 0 / stderr 空 / stdout 非空无控制字符 / 结束标记 / 无 GHC 诊断字样。

## 相关教程

同仓库：[cpp20](../cpp20/)、[rust](../rust/)、[julia](../julia/)、[swift](../swift/) 等
（同一结构标准：24 章分章 + 章号=示例号 + 坑位清单 + 多层验证）。
