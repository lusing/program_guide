# 17 · 模块系统进阶

### 17.1 open 的遮蔽规则

当你 `open` 一个模块时，它的名字会被引入当前作用域。如果当前作用域已经有同名的东西了呢？

答案是：**后打开的会遮蔽先打开的**。

```ocaml
let x = 1

module M = struct
  let x = 2
end

open M

let _ = print_int x   (* 输出 2，M.x 遮蔽了外层的 x *)
```

同样，如果打开两个模块，它们有同名的值，后打开的会遮蔽先打开的：

```ocaml
module A = struct let x = 1 end
module B = struct let x = 2 end

open A
open B

let _ = print_int x   (* 输出 2，B.x 遮蔽了 A.x *)
```

这就是为什么要谨慎使用全局 `open`——打开的模块多了，你可能意外地遮蔽了一些名字，导致难以调试的 bug。

**最佳实践**：
1. 尽量少用全局 `open`，多用局部 open
2. 如果你确实需要全局 open，先打开大的、通用的模块（比如 `Stdlib`），再打开小的、专用的模块
3. 对于只用到一两个名字的模块，直接写模块前缀，不要 open

### 17.2 include 在签名和结构中的使用

我们之前见过 `include` 在结构（`struct ... end`）中的使用，它也可以用在签名（`sig ... end`）中。

**在结构中使用 include**：

```ocaml
module Base = struct
  type t = int
  let zero = 0
  let add x y = x + y
end

module Extended = struct
  include Base
  let one = 1
  let mul x y = x * y
end
```

`Extended` 包含了 `Base` 的所有内容，再加上自己的 `one` 和 `mul`。

**在签名中使用 include**：

```ocaml
module type BASE = sig
  type t
  val zero : t
  val add : t -> t -> t
end

module type EXTENDED = sig
  include BASE
  val one : t
  val mul : t -> t -> t
end
```

`EXTENDED` 签名包含了 `BASE` 的所有声明，再加上 `one` 和 `mul`。

**include 和 open 的区别**：
- `open` 只是名字空间上的便捷——不改变模块的内容
- `include` 是真正的「复制粘贴」——被包含的内容成为当前模块/签名的一部分

**什么时候用 include？**
- 当你想扩展一个已有的模块或签名时
- 当你想混入（mixin）一组功能时
- 当多个模块共享一些公共定义时

但不要滥用 include。如果包含的东西太多，模块的内容来源就不清晰了，反而降低可读性。

### 17.3 module type of 的用法

有时候你想让一个模块的签名和另一个模块相同，但又不想手动写一遍签名。这时候可以用 `module type of`。

```ocaml
module M = struct
  type t = int
  let x = 42
  let f y = y + 1
end

(* 让 N 和 M 有相同的签名 *)
module type M_SIG = module type of M

module N : M_SIG = struct
  type t = int
  let x = 100
  let f y = y * 2
end
```

`module type of M` 会自动推断出 `M` 的签名，然后你可以把它用在别的地方。

这在几个场景下很有用：
- 你想给一个已有模块做一个替代实现，但保持相同的接口
- 你想让 functor 的返回签名和某个参考模块一致
- 你不想手动写冗长的签名

但要注意：`module type of` 推断出来的签名是「完全透明」的——所有类型定义都会暴露出来。如果你想要抽象类型，还是得手写签名。

### 17.4 私有类型别名（private type）

私有类型（private type）是介于「透明」和「不透明」之间的一种类型约束。

- 透明类型：外部可以直接构造、解构、模式匹配
- 不透明类型：外部完全不知道内部是什么，只能通过接口操作
- 私有类型：外部可以**读取**（模式匹配、解构），但不能**构造**

语法：`type t = private ...`

来看一个例子：

```ocaml
module type POSITIVE = sig
  type t = private int    (* 私有类型：底层是 int，但不能直接构造 *)
  val create : int -> t
  val value : t -> int
end

module Positive : POSITIVE = struct
  type t = int
  let create n =
    if n > 0 then n
    else failwith "Positive.create: must be positive"
  let value n = n
end
```

因为是 `private int`，外部可以：
- 用模式匹配解构：`let (Positive x) = p`（注：实际语法略有不同）
- 用 `:>` 强制转换回 `int`：`(p :> int)`

但外部不能：
- 直接构造：`(5 : Positive.t)` 不行
- 直接修改：只能通过 `create` 得到新值

私有类型的好处是：你可以享受模式匹配的便利，同时保持构造的控制权（保证不变量）。

不过私有类型在实际 OCaml 代码中用得不算多——大多数时候，要么完全透明（简单的类型别名），要么完全不透明（需要强封装）。私有类型处于中间地带，适用场景有限。

### 17.5 模块别名（module alias）

模块别名就是给一个已有的模块起另一个名字。

```ocaml
module S = String

let _ = S.length "hello"   (* 等价于 String.length *)
```

这看起来和 `let s = "hello"` 类似，但模块别名是在模块层面的。

模块别名有一个重要的性质：**类型共享**。如果 `S` 是 `String` 的别名，那么 `S.t` 和 `String.t` 是同一个类型。

```ocaml
module S = String
let s : S.t = "hello"
let _ : String.t = s   (* 没问题，S.t = String.t *)
```

模块别名的用途：
- 缩短长模块名：`module L = ListLabels`
- 重导出模块：在你的库模块中重新导出依赖的模块
- 版本切换：通过别名切换不同的实现模块

### 17.6 First-class Modules（一等模块）简介

普通的模块是「编译期的」——你在编译时定义模块、应用 functor，模块不能作为运行时的值来传递。

但 OCaml 也支持**一等模块**（first-class modules）——你可以把模块包装成一个值，在运行时传递、存储在列表中、作为函数参数等。

把模块包装成一等模块的语法是 `(module M : SIG)`：

```ocaml
module type SHOW = sig
  type t
  val show : t -> string
end

module IntShow = struct
  type t = int
  let show = string_of_int
end

(* 包装成一等模块 *)
let int_show : (module SHOW with type t = int) = (module IntShow : SHOW with type t = int)
```

解包一等模块用 `let module M = (module val x : SIG) in ...` 或者在模式匹配中：

```ocaml
let show_it (type a) (module S : SHOW with type t = a) (x : a) =
  S.show x

let _ = show_it (module IntShow) 42   (* "42" *)
```

> **实测坑**：package type（`module ... : SIG with type ...` 里的
> 类型方程部分）**不支持参数化类型方程**——`(module S : SET with
> type 'a t = 'a S.t)` 直接语法错（"invalid package type:
> parametrized types are not supported"）。想要“元素类型可约束的
> 首类模块”，把元素类型拆成独立的 `elt`（标准库 Set/Map 的设计），
> 再用简单的 `with type elt = a` 方程——示例 12 第 7 节就是这么改的。

一等模块让你可以在运行时动态选择模块实现。比如你可以写一个函数，根据配置返回不同的模块实现：

```ocaml
let get_set_impl use_tree =
  if use_tree then
    (module TreeSet : SET)
  else
    (module ListSet : SET)
```

不过一等模块是比较高级的特性，日常编程中用得不多。大多数时候，普通的模块和 functor 就足够了。一等模块主要用于需要运行时动态性的场景。

### 17.7 模块系统的设计哲学

OCaml 的模块系统设计有几个核心思想：

**1. 模块是独立的语言层级**

模块不是类型系统的附属品，而是一个独立的、有自己类型系统的层级。模块有自己的类型（签名），有自己的函数（functor），有自己的抽象机制（不透明约束）。

这种设计的好处是：模块层和核心语言层解耦。你可以用模块做大规模的架构设计，而不影响核心语言的简洁性。

**2. 生成性与抽象性**

Functor 是生成式的（generative）——每次应用都产生新的抽象类型。这确保了不同用途的相同表示不会混淆。

比如 `Set.Make(String)` 得到的集合类型，和另一个 `Set.Make(struct type t = string ... end)` 得到的集合类型是不同的，即使它们内部都是字符串的集合。这防止了意外混用。

**3. 显式优于隐式**

模块系统倾向于显式。你需要显式地 open、显式地包含、显式地应用 functor。这和 Haskell 的类型类（type class）的隐式解析形成对比。

显式的好处是可预测——你看代码就知道名字从哪来、模块怎么组合的。代价是可能稍微啰嗦一点。

**4. 编译期零开销**

模块系统的所有操作（定义、约束、functor 应用）都在编译期完成。运行时没有模块的概念，也没有任何开销。这和 C++ 的模板类似——都是编译期生成代码。

### 17.8 本章小结

- `open` 会引入名字，后打开的遮蔽先打开的
- `include` 可以用在结构和签名中，是真正的内容复制
- `module type of` 可以获取一个模块的签名类型
- 私有类型（private）介于透明和不透明之间：可读不可构造
- 模块别名给模块起别名，类型是共享的
- 一等模块可以把模块作为运行时值传递
- 模块系统是独立的语言层级，编译期零开销
- Functor 是生成式的，确保不同实例的类型不混淆

---

---
上一章：[16 · 不透明约束与抽象数据类型](abstraction.md) ｜ 下一章：[18 · 可变状态](mutable.md) ｜ 返回：[README](../README.md)
