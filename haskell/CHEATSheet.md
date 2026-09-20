# Haskell 速查表（GHC 9.12.1 Win / 9.14.1 macOS 实测版）

## 运行与工具

```bash
ghc -v0 -O0 --make -o app main.hs && ./app   # 编译执行（验证/CI 走这条）
ghci                                          # 交互：:t 类型 / :i 实例 / :r 重载 / :kind
runghc main.hs                                # 脚本（Windows 实测 ~41s，仅小试）
stack build / test / run / exec / ghci        # 工程三连（20 章）
./app +RTS -s                                 # 运行时统计；+RTS -N4 多核（需 -threaded）
```

## 语法速查

```haskell
-- 函数（柯里化是常态）
add x y = x + y            inc = add 1            -- 部分应用
pipeline = negate . sq . (+ 1)                    -- 组合（右到左）
show $ sq $ sq 3                                  -- $ 省括号

-- 模式匹配与 guard
safeHead []    = Nothing ; safeHead (x:_) = Just x
classify n | n < 0 = "负" | otherwise = "非负"
firstAndRest whole@(x:_) = (x, whole)             -- @ 绑定

-- ADT 与类型类
data Shape = Circle Double | Rect Double Double deriving (Show, Eq, Ord)
newtype Count = Count Int deriving newtype (Num, Show)   -- 需 DerivingStrategies
class Describable a where describe :: a -> String        -- class/instance
scaleIt :: (Num a, Show a) => a -> String                -- 约束多态

-- 列表与折叠
map / filter / zipWith / take / drop / iterate / unfoldr
foldr (&&) True            -- 惰性短路
foldl' (+) 0               -- 严格折叠（Data.List；foldl 是坑）
[x*y | x <- [1..3], y <- [1..x]]                    -- 推导式

-- 单子三部曲
fmap / <$>        -- Functor
pure x <*> y      -- Applicative
m >>= \x -> …     -- Monad（do 记法的本体）
type Eval a = ExceptT String IO a                    -- 变换器叠加

-- Maybe/Either
case M.lookup k m of Just v -> …; Nothing -> …
either (const 0) id (parseAge s)                    -- 左右分流

-- 常用组合子
maybe def f m   either l r e   fromMaybe def   mapM_   traverse
```

## Windows/macOS 工具链实测坑位索引（按章）

| # | 坑 | 章 |
|---|---|---|
| 1 | stdout 默认 GBK；`GHC_CHARENC=UTF-8` 无效；`hSetEncoding stdout utf8` 唯一可靠 | 02 |
| 2 | `show`/`print` 转义非 ASCII（`"\20013\25991"`） | 02 |
| 3 | 未捕获异常消息按代码页输出（绕过 hSetEncoding） | 02/17 |
| 4 | `runghc` 恒 ~41s（Win，GHCi 链接器老毛病；macOS 快但仍走编译验证） | 01/02 |
| 5 | `Int` 21! 溢出；`/` 需 Fractional；divMod vs quotRem 负数分家 | 03 |
| 6 | **GHC 9.12 默认 -Wx-partial 警告**：head/last/tail/init（!! 除外）→ 全函数替代 | 06 等 |
| 7 | Ord 派生序 = 构造子声明序 | 07 |
| 8 | `deriving newtype` 需 DerivingStrategies 扩展 | 08 |
| 9 | foldl 堆 thunk；seq 只到 WHNF；计时须 deepseq | 09/10/19 |
| 10 | text 2.x：UnicodeException 搬到 `Data.Text.Encoding.Error` | 12 |
| 11 | 码点 ≠ 字节 ≠ 字素簇（T.length vs B.length） | 12 |
| 12 | `f . g x` 解析为 `f . (g x)`——组合链加括号（本教程踩 3 次） | 05/13/16 |
| 13 | execStateT 只给终态；runStateT 给 (结果, 终态) | 14 |
| 14 | Text.Parsec 不转出口 Expr 模块（buildExpressionParser 单独导） | 15/24 |
| 15 | **buildExpressionParser 表序先紧后松**（写反 else 吞语句） | 15/24 |
| 16 | 符号匹配须 try（`<=` 吃 `<` 不回退） | 15/24 |
| 17 | **writeFile 默认 GBK（Win）/ ASCII（macOS 无 locale）**——写文件显式 UTF-8 句柄或设 `LANG` | 16/17 |
| 18 | 惰性读句柄锁文件到 GC（写/删 permission denied；Linux 则静默清空） | 16 |
| 19 | 文本模式写 `\r\n`、二进制读看得见——归一化 | 16 |
| 20 | listDirectory 顺序不定——sort 后断言 | 16 |
| 21 | throw 是惰性的：`try (evaluate x)` 才能引爆；IO 里用 throwIO | 17 |
| 22 | `$$` 必须紧贴 `(`（9.12 parse error；`$` 无此限制） | 18 |
| 23 | TH 导出层级绕：Dec(DataD)/Info(TyConI)/lift 在 Syntax 子模块 | 18 |
| 24 | **stackage 被墙**：TUNA 三行 + global-hints（fpco 路径！） | 20 |
| 25 | LTS 与系统 GHC 错位：`compiler:` 覆盖 + system-ghc + 不另装 | 20 |
| 26 | scoop 残留坏 strip shim 卡 copy 阶段（Cabal 从 ghc 同目录找 strip） | 20 |
| 27 | scoop extras 的 `cabal` 是同名聊天应用（非 cabal-install） | 20 |
| 28 | 随机断言只断性质/收敛带（种子硬编码可复现） | 14/21 |
| 29 | 竞争演示：错误写法断 ≤n、正确写法断 ==n | 22 |
| 30 | threadDelay 是微秒 | 22 |
| 31 | FFI 跨平台：Win 直链 msvcrt/kernel32；macOS/Linux libc 符号无库名段 + nanosleep（POSIX 无毫秒 sleep） | 23 |
| 32 | mtl 2.3 不转出口 throwE → throwError；transformers 隐藏包须显式依赖 | 24 |

## 验证命令

```bash
cd haskell
pwsh ./build.ps1 -All                # 23 示例 × 两层（六条判定）
pwsh ./build.ps1 -Example 09_lists   # 单个示例
bash run-all.sh                      # bash 版双入口
pwsh ./build.ps1 -Clean              # 清理 build/
```

六条判定：编译退出码 0 / 运行退出码 0 / stderr 空 / stdout 非空且无控制字符 /
含 `==== NN 结束 ====` / 无 GHC 诊断字样。20/24 走 stack 分支（宽松判定 stack 噪音）。
