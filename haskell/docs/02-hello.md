# 02 · 第一个程序

> 对应示例：`examples/02_hello/`（Ch02.hs + main.hs + runtests.hs）。
> 本章对应原书第 2 章〈表达式、类型和值〉：2.2 节的 GHCi 读错误与 bottom、2.5 节的 show/read
> 取自书 2.1/2.6，模块与版面两节提炼自书 2.7/2.8；求值顺序的完整讨论在 12 章。

## 2.1 三态运行与工程结构

```bash
ghci                            # 交互：:t 1+1 看类型，:r 重载，:q 退出
ghc -v0 -o hello main.hs        # 编译：-v0 关掉 GHC 自己的进度输出
runghc main.hs                  # 脚本直跑（本机实测 ~41s，仅适合小试）
```

示例目录采用**库 + 双 Main**结构（Haskell 没有 include，模块是唯一复用单位）：

```
02_hello/
  Ch02.hs      库模块：本章全部纯函数（main 与 runtests 共同复用）
  main.hs      演示入口（module Main）
  runtests.hs  测试入口（module Main，断言失败 exitFailure）
```

这就是 27 章 stack 工程的雏形：库 + 可执行 + 测试三件套。

## 2.2 合式三关：学会读 GHCi 的"不行"

原书第 2 章开宗明义：每个**合式**（well-formed）表达式既有合式的类型、也有值。GHCi 对一个
表达式做三件事——**语法检查 → 类型检查 → 求值**——每关失败的样子都该认得。下面这组会话
（GHC 9.14.1 实录，错误信息有删节）覆盖了三关的典型报错：

```
ghci> 3 + 4)
<interactive>:1:5: error: [GHC-58481] parse error on input `)'
```

第一关：语法。第 1 行第 5 列多了一个右括号——**parse error** 是语法层拒绝，还轮不到类型。

```
ghci> :type if 1 == 0 then 'a' else "a"
error: • Couldn't match type ‘Char’ with ‘[Char]’
```

第二关：类型。`if` 的两个分支必须同型——字符 `'a'` 不是字符串 `"a"`。语法对、类型错，
GHC 报 **Couldn't match type**（日常错误的 90%）。

```
ghci> sin sin 0.5
error: • No instance for (Floating (a0 -> a0)) arising from a use of ‘sin’
```

还是类型关：应用左结合把式子解析成 `sin (sin 0.5)`？不——是 `(sin sin) 0.5`，`sin` 想吃
一个函数。补上括号 `sin (sin 0.5)` 即得 `0.4612695550331807`。

```
ghci> map
error: • No instance for (Show (a0 -> b0)) arising from a use of ‘print’
```

第三关：求值成功，但**值不可打印**——函数类型没有 `Show` 实例。想看它就 `:t map`。

**bottom：每个类型都有第三个值。** 看这两行：

```
ghci> 1 `div` 0
*** Exception: divide by zero
ghci> :type undefined
undefined :: a
```

`1 div 0` 类型正确（合式），但求值**发散**——这个"值"记作 ⊥（bottom），读作 bottom。 Prelude
给了它名字 `undefined :: a`——注意类型是万能的 `a`，所以**每个类型都包含 ⊥**（`Bool` 有三个
值：`False`、`True`、`undefined :: Bool`）。这解释了后面许多"为什么"：为什么 `head []` 危险、
为什么严格/非严格是函数的性质（12 章）、为什么证明要讨论终止（11 章）。

两个会话小知识：

- **`it` 变量**：GHCi 把上一个表达式的值绑定到 `it`——`3*7` 之后 `it + 1` 得 22。
- **`where` 不是表达式**：`x*x where x = 3` 直接 parse error；`where` 只能挂在定义等号右边
  的整体上。表达式里用 `let x = 3 in x*x`。

## 2.3 GHCi 会话工具箱

```
:t foldr            -- 看类型   :: (a -> b -> b) -> b -> [a] -> b
:i Maybe            -- 看类型/类型类的构造子与实例清单
:module +Data.Map   -- 追加导入（提示符会变长，可用下行改掉）
:set prompt "ghci> "
:set +m             -- 之后空行结尾的表达式自动进入续行（多行输入）
:{  … :}            -- 显式多行块（粘贴代码用）
:r                  -- 重载当前文件
:q                  -- 退出
```

`:set +m` 与 `:{ :}` 是 GHCi 时代（书里没有）的补法：书用 `.lhs` 文学脚本让整章即程序，
今天的多行定义在 GHCi 里靠这两条。

## 2.4 main 与编码开场

Haskell 程序的入口是 `main :: IO ()`——"一个不返回值的 IO 动作"：

```haskell
module Main (main) where

import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    putStrLn "Hello, Haskell!"
```

**Windows 编码坑（本机实测，9.12–9.14）**：stdout 默认走 ANSI 代码页（本机 GBK）。源文件是
UTF-8、读入也正常，但 `putStrLn "中文"` 输出的是 GBK 字节——重定向到文件即乱码。

- `GHC_CHARENC=UTF-8` 环境变量**实测不生效**（官方文档暗示可用，Windows 上无效）。
- 唯一可靠修复就是代码里那两行 `hSetEncoding`。**本教程每个示例的第一件事都是它。**

## 2.5 打印值：putStrLn、print 与 show/read 对偶

三个输出原语一张表：

| 函数 | 类型 | 行为 |
|---|---|---|
| `putStr` | `String -> IO ()` | 原样输出，不换行 |
| `putStrLn` | `String -> IO ()` | 原样输出 + 换行 |
| `print` | `Show a => a -> IO ()` | `putStrLn . show`——**先序列化再输出** |

`show` 输出的是"**源码字面量**"——字符串加引号、非 ASCII 字符转十进制转义（实测）：

```haskell
putStrLn "中文"    -- 中文
print "中文"       -- "\20013\25991"   ← show 的坑：给人看的输出别用 print
print (42 :: Int)  -- 42
print 3.14         -- 3.14
```

`read` 是 `show` 的对偶（类族 `Read` 对 `Show`），**吃字符串、产任意 Read 类型的值**——所以
必须让 GHC 知道要产什么类型，用类型注释：

```haskell
read "123" :: Int     -- 123
read "123" :: Double  -- 123.0
getDigit :: Char -> Int
getDigit c = read [c]         -- 把数字字符变成数：read 一个单元素字符串
```

不带注释的裸 `read "123"` 会报 `Ambiguous type`——类型是 read 的"第二参数"。

## 2.6 命令行参数

```haskell
import System.Environment (getArgs)

main = do
    args <- getArgs           -- args :: [String]，可能为空
    putStrLn (greet args)

greet :: [String] -> String
greet []    = "你好，GHC！"
greet names = "你好，" ++ intercalate "、" names ++ "！"
```

`getArgs` 返回 `[]` 是常态（REPL/管道场景），**入口必须容忍空参数**——示例把分派逻辑提成
`greet :: [String] -> String` 纯函数，顺便让它可测试。

## 2.7 模块与 import

想把有用的函数（比如 01 章的 `commonWords`）给别的脚本用？把它做成**模块**（原书 2.7）：

```haskell
module CommonWords (commonWords) where   -- 括号里是出口（export）清单
import Data.Char (toLower)
import Data.List (sort, sortOn, group)

commonWords :: Int -> String -> String
commonWords = ...
```

四条规则：

1. **模块名大写开头**，且必须与文件名一致（`CommonWords.hs`），GHC 才找得到。
2. **出口列表是"公共面"**：不在括号里的定义对外不可见——模块天然是封装单位。
3. 省略出口列表 = 全部导出（小脚本方便，库工程别这么干）。
4. 使用方 `import CommonWords (commonWords)` 只导入列出的名字（**明列表**）；
   `import CommonWords`（暗列表）全导；冲突时 `import qualified Data.Map as M`
   （限定名，`M.insert`）。本教程示例统一用明列表。

模块化还有一个实际红利（书里点到）：GHC 是**编译器**（产物是机器码，快），GHCi 是**解释器**
（求值接近源语言，适合交互）——这就是"开发在 GHCi、验证走 ghc 编译"的原因（2.1 三态表）。

## 2.8 版面：越位规则

Haskell 用**缩进**代替花括号分号。触发点是 `where`/`do`/`let` 等关键字后的开括号被省略时，
**越位规则**（offside rule）生效：关键字后第一个式子的列位置被记下，之后每一行——

- **缩进更深** = 上一式的延续；
- **列位相同** = 同层新定义开始；
- **缩进更浅** = 本块结束。

```haskell
roots (a, b, c)
  | disc < 0     = error "complex roots"
  | otherwise    = ((-b - r) / e, (-b + r) / e)
  where disc = b*b - 4*a*c      -- 三个局部绑定同一列：同层
        r    = sqrt disc
        e    = 2*a
```

同一定义也能写成**显式版面**——花括号加分号，规则退场：`where { disc = ...; r = ...; e = ... }`。
`do` 块里偶尔值得这么干（尤其 GHCi 单行粘贴）。书里的忠告照抄：**对缩进存疑时，用括号/分号
当安全带**；反过来，看到 "possibly incorrect indentation" 的 parse error，先检查列对齐。

## 2.9 示例的固定形态

每个 `main.hs` 末尾都有自检与结束标记：

```haskell
check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise = error ("自检失败: " ++ label ++ ...)

-- 最后一行：
putStrLn "==== 02 结束 ===="
```

`check` 失败抛异常 → 进程退出非 0。验证脚本（build.ps1）按六条判定：退出码 / stderr 空 /
stdout 非空 / 无控制字符 / 有结束标记 / 无 GHC 诊断字样。

## 2.10 坑位清单

1. **stdout 默认 GBK**（Windows）：必须 `hSetEncoding stdout utf8`；`GHC_CHARENC` 不生效（2.4）。
2. **show 转义非 ASCII**：`print "中文"` 输出十进制转义——给人看的输出用 `putStrLn`（2.5）。
3. **runghc ~41s**（本机实测）：GHCi 链接器加载包慢，脚本验证走编译执行（1.8、01 章实测表）。
4. **未捕获异常的消息按代码页输出**：`error "中文"` 的 stderr 是 GBK 字节（hSetEncoding stderr
   也拦不住——顶层异常处理器绕过 Handle 编码；要控制输出就自己 catch 后打印，20 章）。
5. **putStrLn 输出 CRLF**：Windows 文本模式把 `\n` 翻成 `\r\n`——读回来时记得归一化（19 章）。
6. **裸 `read` 有歧义**：不带类型注释的 `read s` 编译报 Ambiguous——read 的结果类型必须可知（2.5）。

## 2.11 练习（选自原书第 2 章习题）

**练习 2.1（优先级谜题）**："2 加 2 的一半等于 2 还是等于 3？"——先给出 Haskell 的两种写法
（`2 + 2 / 2` 与 `(2 + 2) / 2`），再说明为什么两个答案都对。
（答案：应用/除法优先级高于加法，`2 + 2/2` 得 3；加括号 `(2+2)/2` 得 2。）

**练习 2.2（合式判定）**：设 `double :: Int -> Int`。下列表达式各卡在哪一关——语法、类型还是
打印？（提示：`double -3` 是"函数减数"，报 `No instance for (Num (Int -> Int))`；
`double (-3)` 得 -6；`double double 0` 类型错（`double` 不吃函数）；`[(+), (-)]` 是合式的
列表但**不可打印**——函数没有 Show 实例。）

**练习 2.3（modernise）**：设计 `modernise :: String -> String`，把论文标题每个词首字母大写。
提示三个小问：`Data.Char` 里与 `toLower` 相对的函数叫什么？`unwords :: [Word] -> String` 与
`words` 满足 `words . unwords = id` 还是 `unwords . words = id`？（后者——标点/多空格信息
在 words 时已丢。）由首元素 `x` 与尾 `xs` 怎么构造回原列表？（`x : xs`。）

**练习 2.4（CIN 验证码）**：信用卡号前 8 位任意、末 2 位是前 8 位数字之和。写
`addSum :: CIN -> CIN` 与 `valid :: CIN -> Bool`（`type CIN = String`）。用到 `take`、`show`、
2.5 节的 `getDigit`。注意类型同义词管不住"字符必须是数字"——那是运行时约定。

---

上一章：[01 全景](01-overview.md) ｜ 下一章：[03 数值](03-numbers.md) ｜ 返回：[README](../README.md)
