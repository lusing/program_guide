# 01 · 认识 Standard ML

## 1.1 一份「有标准」的函数式语言

SML 是 1990 年定稿、1997 年修订（SML'97）的函数式语言。它和 Haskell 常被一起提起，但路线完全不同：

| | Standard ML | Haskell |
|---|---|---|
| 求值 | **严格求值**（eager） | 惰性求值 |
| 副作用 | 显式（`ref`、`Array`、I/O） | 用 monad 隔离 |
| 纯度 | 不强制 | 语言层面强制 |
| 类型系统 | Hindley–Milner + 值限制 | HM + 类型类 |
| 模块系统 | **一等公民**：`signature`/`structure`/`functor` | 无模块系统，靠类型类与包管理 |
| 标准 | 有正式 Definition，有 Basis 标准库 | 有 Report，但生态偏 GHC |

SML 最有分量、也最被其他语言借鉴的东西是**模块系统**。OCaml 的模块、Rust 的 trait 约束、乃至各种语言的「泛型接口」，都能看到它的影子。但直接实现那套理论的，还是 SML 自己：

```sml
signature COUNTER = sig
    type t
    val zero : t
    val bump : t -> t
    val value : t -> int
end

structure FastCounter : COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 2
    fun value n = n div 2
end
```

`signature` 是一份接口契约，`structure` 是一组绑定的打包，`: COUNTER` 是「按这份契约约束它」。这三样加上 `functor`（从 structure 到 structure 的编译期函数），构成了一套完整的抽象机制 —— 而且**这一切都在编译期解决，运行时零开销**。

## 1.2 严格求值意味着什么

SML 的参数在进入函数体之前就被求值完。这让代码的行为好推理：不会有意外的求值顺序，不会有惰性求值那套 thunk 堆积。代价是你得自己写短路逻辑 —— 而 SML 给了 `andalso` / `orelse` 两个**语法级**的短路运算符：

```sml
(* andalso / orelse 是语法形式，右操作数真的不会被求值 *)
fun safeDiv (a, b) = b <> 0 andalso a div b > 0
```

注意 `andalso` / `orelse` 不是函数，是语法结构。它们是 SML 里唯一的「懒惰」角落。

## 1.3 类型推断不是「省略类型」

Hindley–Milner 推断能推出最一般的类型，所以 SML 代码里很少写类型标注。但推断有个硬边界：**值限制（value restriction）**。只有语法上是「值」的表达式才会被泛化：

```sml
val revEmpty = rev []          (* 'a list，是值，可以泛化 *)
val badPoly = (fn x => x) []   (* 不是语法值，不会被泛化 —— 会退化成弱类型变量 *)
```

实践中这很少咬人，但一旦咬人，报错信息会带 `?.X1` 这种类型变量名。第 4 章会讲到怎么处理。

## 1.4 三种「半标准」

ECMA 在 1990 年代把 SML 标准化成了两个事实上的分支：

- **SML'97（Standard ML '97）**：现在说的「SML」基本就是它。SML/NJ、MLton 走这条线。
- **SML/NJ 的扩展**：`SMLofNJ` 结构、柯里化 functor 语法（`functor F (A:S1) (B:S2)`）等。**这些 Poly/ML 和 MLton 都不认**，第 15 章有实测。
- **Poly/ML 的扩展**：`PolyML` 结构、自己的并发/FFI 接口。

幸运的是，**Basis（标准库）本身是标准的**。所以只要不碰实现私有的扩展，同一份源码在三套实现上都能跑 —— 本书 29 个示例就是这么做的，87 次执行全部通过；而且在 Windows/WSL（Arch）与 macOS 两套环境下各跑过一遍，结果一致（27 个示例三通道逐字节相同，另 2 个是登记在案的已知差异）。

## 1.5 为什么值得学

- **练「用类型表达意图」**：`datatype` + 模式匹配让「状态机」变成类型检查能验证的东西。
- **练抽象**：`signature`/`:>` 提供的是**编译期可验证的封装**，比「靠约定不碰内部字段」硬得多。
- **换一个脑子写代码**：SML 里没有 `for` 循环、没有可变变量（除非显式 `ref`）、没有空指针。写一阵子会发现自己在别的语言里也开始先问「数据结构长什么样」。

## 1.6 走之前先记住三件事

1. **中文只能出现在注释里**，字符串字面量一律 ASCII —— Poly/ML 和 MLton 都会拒绝原始 UTF-8 字节。要输出中文用 `\ddd` 转义。第 2 章详述。
2. **别假设 `int` 是 64 位**：MLton 默认 32 位，另两家 63 位。第 3、33 章有实测。
3. **别用 `Real.toString` 打印浮点数**：整值实数是否带 `.0` 三家不一致。用 `Real.fmt`。

---
