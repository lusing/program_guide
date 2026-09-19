# 02 · 第一个程序

> 对应示例：`examples/02_hello/`（Ch02.hs + main.hs + runtests.hs）

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

这就是 20 章 stack 工程的雏形：库 + 可执行 + 测试三件套。

## 2.2 main 与编码开场

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

**Windows 编码坑（本机实测，GHC 9.12.1）**：stdout 默认走 ANSI 代码页（本机 GBK）。源文件是
UTF-8、读入也正常，但 `putStrLn "中文"` 输出的是 GBK 字节——重定向到文件即乱码。

- `GHC_CHARENC=UTF-8` 环境变量**实测不生效**（官方文档暗示可用，9.12.1 Windows 上无效）。
- 唯一可靠修复就是代码里那两行 `hSetEncoding`。**本教程每个示例的第一件事都是它。**

## 2.3 putStrLn 与 print

```haskell
putStrLn :: String -> IO ()     -- 原样输出 + 换行
print     :: Show a => a -> IO ()   -- 先 show 再输出
```

`print` 走 `show`——**show 输出的是"源码字面量"**，非 ASCII 字符转十进制转义（实测）：

```haskell
putStrLn "中文"    -- 中文
print "中文"       -- "\20013\25991"   ← show 的坑
print (42 :: Int)  -- 42
print 3.14         -- 3.14
```

## 2.4 命令行参数

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

## 2.5 示例的固定形态

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

## 2.6 GHCi 速查

```
:t foldr          -- 看类型  :: (a -> b -> b) -> b -> [a] -> b
:i Maybe          -- 看类型/类型类的构造子与实例清单
:module +Data.Map -- 追加导入
:r                -- 重载当前文件
:q                -- 退出
```

## 2.7 坑位清单

1. **stdout 默认 GBK**（Windows）：必须 `hSetEncoding stdout utf8`；`GHC_CHARENC` 不生效（2.2）。
2. **show 转义非 ASCII**：`print "中文"` 输出十进制转义——给人看的输出用 `putStrLn`（2.3）。
3. **runghc ~41s**（本机实测）：GHCi 链接器加载包慢，脚本验证走编译执行（1.4、01 章实测表）。
4. **未捕获异常的消息按代码页输出**：`error "中文"` 的 stderr 是 GBK 字节（hSetEncoding stderr
   也拦不住——顶层异常处理器绕过 Handle 编码；要控制输出就自己 catch 后打印，17 章）。
5. **putStrLn 输出 CRLF**：Windows 文本模式把 `\n` 翻成 `\r\n`——读回来时记得归一化（16 章）。
