# 13 · 异常与错误处理

> 对应示例：[`examples/13_exceptions/13_exceptions.io`](../examples/13_exceptions/13_exceptions.io)

> ⚠️ 本章有一个观察文件（不是示例，不参与逐字节比对，由回归脚本单独判定）：
> [`observe_13_uncaught.io`](../examples/13_exceptions/observe_13_uncaught.io)
> —— 它把「未捕获异常会中断脚本、退出码却仍然是 0」做成可验证的观察项。
> 这件事是本仓库回归脚本必须用「结束标记」而不是退出码来判定的**根本原因**。

Io 只有一套错误机制：**异常**。没有错误码，没有返回值哨兵（`nil` 就只是 `nil`），
也没有 `throw`/`raise` 关键字——`raise` 是 `Exception` 上的一个普通方法。
异常本身是对象，所以「自定义异常类型」就是 `Exception clone`。

## 13.1 try 是唯一的捕获入口

先看它到底返回什么：

```text
-- 13.1 try 是唯一的捕获入口
try(1 + 1) 正常返回 = nil
try(1 + nil) 的 type = Exception
e error = argument 0 to method '+' must be a Number, not a 'nil'
try(42) 的值 = nil
try(正常但值就是 nil) 也一样 = nil
Object try 的类型 = Block
实现代码行数 = 7
实现里新建了协程 = true
实现里只回「异常或 nil」 = true
```

```io
show("try(1 + 1) 正常返回", try(1 + 1))
e := try(1 + nil)
show("try(1 + nil) 的 type", e type)
show("e error", e error)
show("try(42) 的值", try(42))
show("try(正常但值就是 nil) 也一样", try(nil))
tryCode := Object getSlot("try") code
show("Object try 的类型", Object getSlot("try") type)
show("实现代码行数", tryCode split("\n") size)
show("实现里新建了协程", tryCode containsSeq("Coroutine clone"))
show("实现里只回「异常或 nil」", tryCode containsSeq("if(coro exception, coro exception, nil)"))
```

结论：**`try` 拿不到成功值**。`try(1 + 1)` 给 `nil`，`try(42)` 也给 `nil`——
「算出 `nil`」和「什么都没发生」在这里是同一件事。

上面那几行不是猜的：`Object getSlot("try") code` 把 `try` 自己的实现打了出来，
它是 `Object` 上的一个普通方法，骨架只有 7 行：

```io
try := method(
    coro := Coroutine clone
    coro setSlot("parentCoroutine", Scheduler currentCoroutine)
    coro setSlot("runTarget", call sender)
    coro setSlot("runLocals", call sender)
    coro setSlot("runMessage", call argAt(0))
    coro run
    if(coro exception, coro exception, nil)
)
```

参数消息被丢进**一个新建的协程**去跑，最后只问那个协程「你有没有异常」。
所以 `try` 的返回值域只有两个：异常对象，或者 `nil`。

> **为什么重要**：`try` 是「有没有炸」的探针，不是「拿结果」的工具。
> 要拿结果就把结果写到外层槽里：`try(result := 危险的表达式)`，
> 然后判断 `e == nil` 再看 `result`。Io 标准库自己就是这么写的——
> `CLI.io` 里是 `executionError := try(result := context doMessage(lineAsMessage))`。

## 13.2 异常是个普通对象，槽位就是它的全部信息

```text
-- 13.2 异常是个普通对象，槽位就是它的全部信息
e coroutine type = Coroutine
e nestedException = nil
e originalCall = nil
Exception slotNames sort = list("_Resumption", "_findHandler", "catch", "caughtMessage", "coroutine", "error", "nestedException", "originalCall", "pass", "raise", "raiseFrom", "setCaughtMessage", "setCoroutine", "setError", "setNestedException", "setOriginalCall", "showStack", "signal", "type")
e hasSlot("showStack") = true
e hasSlot("pass") = true
e hasSlot("catch") = true
```

```io
show("e coroutine type", e coroutine type)
show("e nestedException", e nestedException)
show("e originalCall", e originalCall)
// 异常的**全部能力**就是它的槽位清单，没有隐藏的私有状态。
// 注意这里打的是排序后的结果，不然顺序取决于哈希表布局，不是确定性输出。
show("Exception slotNames sort", Exception slotNames sort)
show("e hasSlot(\"showStack\")", e hasSlot("showStack"))
show("e hasSlot(\"pass\")", e hasSlot("pass"))
show("e hasSlot(\"catch\")", e hasSlot("catch"))
```

`Exception` 的槽位清单（`Exception slotNames sort`）就是它的全部能力——
没有隐藏的私有状态，异常就是一个装了这些槽的普通对象。为了下面好讲，
这里把那一行**折开**排列（示例里是完整的一行）：

```text
list("_Resumption", "_findHandler", "catch", "caughtMessage", "coroutine", "error",
     "nestedException", "originalCall", "pass", "raise", "raiseFrom", "setCaughtMessage",
     "setCoroutine", "setError", "setNestedException", "setOriginalCall", "showStack",
     "signal", "type")
```

数一下：19 个槽，可以分成五组——

| 组 | 槽 | 干什么 |
|---|---|---|
| 错误信息 | `error`、`caughtMessage`、`nestedException` | 消息正文、`catch` 时改写的消息、嵌套的上一个异常 |
| 挂载点 | `coroutine`、`originalCall` | 异常挂在哪条协程上、原始调用（多数情况是 `nil`） |
| 捕获 | `catch`、`_findHandler`、`_Resumption` | 在异常对象上接住它；下划线开头的是内部实现 |
| 抛出 | `raise`、`raiseFrom`、`signal` | 抛出；`signal` 是**可恢复**的那一种 |
| 内省 | `showStack`、`type`、各 `set*` | 打印栈、查类型、改上面那些槽 |

> **为什么重要**：`slotNames` 是 Io 里最好用的一把「这玩意儿到底能干什么」的尺子。
> 任何对象——包括异常、`System`、`File`——把 `slotNames sort` 打出来，
> 它的全部公开能力就一目了然，不需要查文档。

要点：

- **`error` 是消息字符串**，不是异常对象；判定类型要用 `type` + `isKindOf`。
- **`coroutine` 是「异常发生在哪个协程里」**，不是「谁抛的」。
- **`originalCall` 通常就是 `nil`**：普通的运算错误走的是 Python 那种
  「VM 直接构造异常」的路径，没有原始调用信息；只有 `raiseFrom` 才填它。
  别指望靠它做堆栈回溯，回溯要走 `coroutine showStack`。
- `showStack` 是方法，调用它会**打一堆带地址和源文件行的东西**——
  所以本书的示例一律不打印它（回归脚本要求输出逐字节可复现）。

> **为什么重要**：异常不是「信号」而是「数据结构」。
> 这意味着你可以把它存进 `List`、传给别人、延时处理；
> 也意味着「异常对象当成值传出去」之后它就不再是异常了（见 13.6）。

## 13.3 未捕获异常：横幅打到 stdout、脚本中断、退出码却是 0

本节要验的是一个**行为**，而不是一个返回值。因为本章自己必须活到最后
（要打印结束标记），所以做法是：把「会死的脚本」写进临时文件、交给子进程跑，
再把子进程的退出码和 stdout 拿回来做布尔断言。

```text
-- 13.3 未捕获异常：横幅打到 stdout、脚本中断、退出码却是 0
找到可用解释器 = true
子进程退出码 = 0
子进程 stderr 长度 = 0
stdout 里有未捕获异常横幅 = true
异常之后那一行没被执行 = true
```

```io
// 解释器路径按「环境变量 → 安装前缀 → PATH」三级回落，且不打印路径本身
resolveIo := method(
    hit := nil
    list(System getEnvironmentVariable("IO_BIN"),
         System installPrefix .. "/bin/io_static",
         System installPrefix .. "/bin/io",
         "io_static",
         "io") foreach(c,
        if(hit == nil and c != nil,
            if(c containsSeq("/"),
                if(File with(c) exists, hit = c)
                ,
                hit = c
            )
        )
    )
    hit
)
childLines := list(
    "writeln(\"child: before\")",
    "Object clone boom",
    "writeln(\"AFTER-MARKER\")"
)
childPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch13_child.io")
childFile := File with(childPath)
childFile remove
childFile setContents(childLines join("\n") asUTF8)
cr := System runCommand(ioBin .. " " .. childPath)
show("子进程退出码", cr exitStatus)
show("子进程 stderr 长度", cr stderr size)
show("stdout 里有未捕获异常横幅", cr stdout containsSeq("Object does not respond to 'boom'"))
show("异常之后那一行没被执行", cr stdout containsSeq("AFTER-MARKER") not)
```

结论三条，缺一不可：

1. **横幅走 stdout**，`stderr` 是空的（`子进程 stderr 长度 = 0`）。
2. **脚本被中断**：`AFTER-MARKER` 那一行永远打不出来。
3. **退出码仍然是 0**。这一点最反直觉，也最危险。

> **为什么重要**：`rc == 0` 在 Io 里**不代表脚本跑完了**。
> 任何「靠退出码判断成败」的 CI 配置，在 Io 上都会把「跑到一半就死了」判成成功。
> 本书的回归脚本因此必须要求示例自己打印 `==== NN 结束 ====`，
> 并用「标记齐 + 区间非空 + 区间无横幅」来做判定，退出码只是其中一条。
> 观察文件 `observe_13_uncaught.io` 就是这条规则的**活证据**：
> 它用 `System runCommand` 起子进程、把横幅原文搬回来、再断言那三件事。

## 13.4 自定义异常类型：Exception clone，类型就是身份

```text
-- 13.4 自定义异常类型：Exception clone，类型就是身份
SubErr raise 出来的是什么类型 = SubErr
isKindOf(SubErr) = true
isKindOf(MyErr) = true
isKindOf(Exception) = true
raise 可以直接带消息 = 自定义消息
```

```io
MyErr := Exception clone
SubErr := MyErr clone
sub := try(SubErr raise("子类型出事"))
show("SubErr raise 出来的是什么类型", sub type)
show("isKindOf(SubErr)", sub isKindOf(SubErr))
show("isKindOf(MyErr)", sub isKindOf(MyErr))
show("isKindOf(Exception)", sub isKindOf(Exception))
show("raise 可以直接带消息", (try(MyErr raise("自定义消息"))) error)
```

`raise` 的实现只有三行：把 `self` **clone** 一份、`setError`、`setCoroutine`，
然后交给当前协程抛。所以：

- 「异常的类」= 你调用的那个原型。`SubErr raise(...)` 出来的是 `SubErr` 实例。
- 它**不是** `Exception` 实例，但 `isKindOf(Exception)` 为 `true`（proto 链）。
- 由于是 clone 出来的，**给异常类型加槽不会污染原型**：
  `Custom := Exception clone do(kind := "网络")` 之后，
  `try(Custom raise("超时")) kind` 就是 `"网络"`。

> **为什么重要**：`catch` 匹配用的是 `isKindOf`（见下一节），
> 所以「子类型能被父类型的 handler 接住、父类型不会被子类型的 handler 接住」。
> 这让异常类型层级可以像 Smalltalk 那样当成控制流来设计。

## 13.5 catch：在异常对象上调用，handler 是副作用，返回的是「没接住的异常」

这一节的三个点全都反直觉，先看输出：

```text
-- 13.5 catch：在异常对象上调用，handler 是副作用，返回的是「没接住的异常」
catch 命中时返回 = nil
catch 没命中时返回的类型 = Exception
类型不匹配，handler 没跑（sideEffect） = 0
类型匹配，handler 跑了（sideEffect） = 123
```

```io
caught := try(Exception raise("要接住的"))
matched := caught catch(Exception, "这一行只是被求值，不是返回值")
unmatched := try(Exception raise("要接住的")) catch(Error, "这一行不会跑")
show("catch 命中时返回", matched)
show("catch 没命中时返回的类型", unmatched type)

sideEffect := 0
probe := try(Exception raise("副作用探测"))
probe catch(MyErr, sideEffect = 99)
afterMismatch := sideEffect
probe2 := try(Exception raise("副作用探测"))
probe2 catch(Exception, sideEffect = 123)
afterMatch := sideEffect
show("类型不匹配，handler 没跑（sideEffect）", afterMismatch)
show("类型匹配，handler 跑了（sideEffect）", afterMatch)
```

`catch` 的实现也只有一行：

```io
catch := method(exceptionProto,
    if (self isKindOf(exceptionProto), call evalArgAt(1); nil, self)
)
```

于是三个反直觉点都能解释：

1. **`catch` 是发给异常对象的**，不是发给 `try` 的返回值链。
   正确姿势是 `e := try(...)` 然后 `e catch(类型, 处理)`。
   写成 `try(...) catch(类型, 处理)` 也能跑，只是因为 `try` 的返回值本身就是异常。
2. **handler 按「副作用」求值**：`call evalArgAt(1)` 求完值就被丢掉，
   整个 `catch` 命中时返回 `nil`。所以 handler 里要写真正的动作
   （`writeln(...)`、`errors append(e)`），不能指望它的返回值。
3. **没命中时把异常原样还回来**（`unmatched type` = `Exception`），
   所以可以链式接：`e catch(NetworkErr, ...) catch(TimeoutErr, ...) catch(Exception, ...)`。
   一旦某个 handler 命中，链就断在 `nil` 上。

类型匹配用的是 `isKindOf`，因此父类型能接住子类型、反向不行：

```io
parentCatch := try(SubErr raise("子类型")) catch(MyErr, "父类型接住了")
childCatch  := try(MyErr raise("父类型")) catch(SubErr, "子类型接不住父类型")
```

> **为什么重要**：`catch` 返回值的语义是「还剩下来的异常」，
> 所以「异常被处理掉了」这件事在类型层面表现为 **`nil`**。
> 把 `catch` 的结果存下来并且判空，是 Io 里判断「我处理过了吗」的唯一手段。

## 13.6 pass：接不住就往上扔

```text
-- 13.6 pass：接不住就往上扔
pass 之后再 try 一次拿到的消息 = 往上扔
连扔两层之后拿到的消息 = 两层
没接住又不 pass，异常就变成普通值了 = nil
```

```io
inner := try(Exception raise("往上扔") pass)
show("pass 之后再 try 一次拿到的消息", inner error)
outer := try(try(Exception raise("两层") pass) pass)
show("连扔两层之后拿到的消息", outer error)
swallowed := try(try(MyErr raise("内层炸了")) catch(Error, "类型不对，没接住"))
show("没接住又不 pass，异常就变成普通值了", swallowed)
```

`pass` 就是 `Scheduler currentCoroutine raiseException(self)`：把**同一个**异常对象
重新抛出去，交给外层。消息一个字都不改（`两层` 连着穿过两层）。

第三行是这一节真正的坑：`catch` 没命中时返回的是**异常对象本身**，
但它现在只是一个「值」。外面那层 `try` 求值这个值时并没有发生异常，
于是 `try` 按规矩回 `nil`——**异常就这样被静默吞掉了**。

> **为什么重要**：`pass` 是「我不处理，但我要告诉上面发生过」；
> 忘了 `pass`，异常就会在 `catch` 返回值里悄悄变成普通数据。
> 写多级异常分派时，最后一条 `catch(Exception, ...)` 是兜底，
> 中间那些「认得出来但处理不了」的分支要显式 `e pass`。

## 13.7 嵌套异常：一个原因套一个原因

```text
-- 13.7 嵌套异常：一个原因套一个原因
nested error = 外层原因
nested nestedException error = 内层原因
nestedException 也有自己的 type = Exception
```

```io
nested := try(Exception raise("外层原因", Exception clone setError("内层原因")))
show("nested error", nested error)
show("nested nestedException error", nested nestedException error)
show("nestedException 也有自己的 type", nested nestedException type)
```

`raise` 的第二个参数（或 `setNestedException`）挂一个「起因」上去，
形成一条因果链。注意**链是单向的**：外层拿得到内层，内层不知道外层。

这段代码里有两个相邻的陷阱，都值得说清。

**坑一：把 `raise` 写成消息链。**

```io
// 这样写 nestedException 永远是 nil
try(Exception raise("外层") setNestedException(Exception clone setError("内层")))
```

因为 `raise` 是「一去不回」的——它当场把控制权交出去了，
后面那个 `setNestedException` **根本没轮到执行**。

**坑二：以为「先组装好再 raise」可行。**

```io
// 这样写也不行：raise 会拿自己的实参把 error / nestedException 覆盖掉
Cause := Exception clone setError("内层原因")
try(Exception clone setError("外层原因") setNestedException(Cause) raise)
```

`raise` 的实现是
`self clone setError(error) setCoroutine(coro) setNestedException(nestedException)`——
它**总是**用自己收到的参数（这里两个都是 `nil`）去覆盖那两个槽。
无参 `raise` 出来的异常，`error` 就是 `nil`。

所以**唯一的正路是 `raise` 的第二个参数**：

```io
Cause := Exception clone setError("内层原因")
nested := try(Exception raise("外层原因", Cause))
```

只有自定义的**额外**槽能靠「clone 后再 raise」保住——
因为那些槽不在 `raise` 的覆写名单里（13.4 里 `Custom := Exception clone do(kind := "网络")`
就是这么用的，`raise` 之后 `kind` 还在）。

> **为什么重要**：`raise` 不是构造函数而是「离场指令」，
> 一切「先组装异常再 raise」或「先 raise 再修饰异常」的写法都是无效代码。
> 异常对象的全部构造都必须在 `raise` 的实参里一次给完。

## 13.8 Error 与 Exception 是两家人

```text
-- 13.8 Error 与 Exception 是两家人
Lobby 有 Error = true
Error 有 raise = false
Error isKindOf(Exception) = false
Exception 有 raise = true
拿 Error 当异常用会得到 = Error does not respond to 'raise'
```

```io
show("Lobby 有 Error", Lobby hasSlot("Error"))
show("Error 有 raise", Error hasSlot("raise"))
show("Error isKindOf(Exception)", Error isKindOf(Exception))
show("Exception 有 raise", Exception hasSlot("raise"))
err := try(Error raise("想用它当异常"))
show("拿 Error 当异常用会得到", err error)
```

`Error` 存在、也在 `Lobby` 上，但它**不在 `Exception` 家族里**，也没有 `raise`。
拿它当异常用，得到的是另一条异常：「`Error does not respond to 'raise'`」——
也就是「错误处理本身出了错」，这条消息非常容易把人误导到错误的方向。

`Error` 是给 VM 内部用的另一个原型，日常写代码只会碰到 `Exception`。

> **为什么重要**：看到 `Error` 出现在自己的报错里，基本可以断定是「用法不对」，
> 而不是「业务逻辑抛错了」。自定义异常**永远从 `Exception clone` 出发**。

## 13.9 signal + withHandler：可恢复异常

`raise` 是「一去不回」；`signal` 是「问一句还能不能继续」：

```text
-- 13.9 signal + withHandler：可恢复异常
主体里 signal 表达式的值 = 42
处理器看到了什么 = list("轻微问题")
没有处理器时 signal 的归宿 = MyErr
退化后的消息 = 没人接的就退化成 raise
主体没出事时的返回值 = 主体正常结束
处理器有没有被误触发 = list()
block  造的处理器：结果 = 42
block  造的处理器：看到的消息 = list("轻微问题")
method 造的处理器：报错 = Number does not respond to 'call'
method 造的处理器：让 probeLog 长到了几条 = 2
```

```io
seen := List clone
v := withHandler(MyErr,
    block(exc, resume,
        seen append(exc error)
        42
    ),
    MyErr signal("轻微问题")
)
show("主体里 signal 表达式的值", v)
show("处理器看到了什么", seen)

fallback := try(MyErr signal("没人接的就退化成 raise"))
show("没有处理器时 signal 的归宿", fallback type)
show("退化后的消息", fallback error)

quiet := List clone
normal := withHandler(MyErr, block(exc, resume, quiet append("不该跑")), "主体正常结束")
show("主体没出事时的返回值", normal)
show("处理器有没有被误触发", quiet)
```

机制（`Exception.io` 里的实现）：

- `withHandler(类型, 处理器, 主体)` 往**当前协程**的 `handlerStack` 上压一条
  `list(类型, 处理器)`，跑完主体再弹掉。
- 主体里 `signal` 出来的异常会去找栈上第一个 `isKindOf` 命中的处理器，
  处理器收到 `(exception, resume)`。
- 处理器**返回什么，`signal` 那个表达式就得到什么**——所以 `v` 是 `42`，
  执行在 `signal` 处**继续往下走**，而不是像 `raise` 那样跳出去。
- 没有处理器时，`signal` 退化成 `raise`（`fallback type` = `MyErr`，能被 `try` 接住）。
- 主体正常结束时处理器一次都不会被调用（`quiet` 是空表）。

`resume` 参数还在（文档说是为 API 兼容保留的 `_Resumption`，`invoke(v)` 原样返回 `v`），
本构建里「处理器返回一个值」就等价于 `resume invoke(那个值)`。

**⚠️ 处理器必须用 `block(...)` 造，不能用 `method(...)`。** 这是 11.3.1 那条规律
在这里的具体后果：库内部 `_findHandler` 会把处理器取出来存进
`entry := list(类型, 处理器)`，再交给 `handler call(exception, _Resumption)`——
中间要经过形参，而形参就是槽。`method(...)` 造的块 `isActivatable` 是 `true`，
一进槽就被**零参调用**，异常对象压根传不进去。

看实测。两边的处理器体里都往同一个 `probeLog` 里记一笔：

```text
block  造的处理器：结果 = 42
block  造的处理器：看到的消息 = list("轻微问题")            ← 只有一条，处理器跑了一次
method 造的处理器：报错 = Number does not respond to 'call'
method 造的处理器：让 probeLog 长到了几条 = 2                ← 多出来的那条是它提前跑的证据
```

`probeLog` 从 1 条变成 2 条，而**主体还没 signal 之前那条就已经写进去了**——
处理器在作为实参传进去的那一刻被零参调用了，返回的 `42` 又被当成「处理器」
去 `42 call(exc, resume)`，于是报 `Number does not respond to 'call'`。
如果处理器体恰好返回一个字符串，报错就变成 `Sequence does not respond to 'call'`——
**错误消息跟着处理器的返回值变**，这是它最难认的地方。

> **为什么重要**：`signal` 是自己写「解析器/迭代器」这类代码时唯一能用的
> 可恢复错误机制：遇到畸形的输入时报告一下，然后带着处理器的修正值继续解析，
> 而不是把整个解析过程炸掉。日常业务代码用 `raise` + `try` 就够了。
> 但要用它，**处理器一律 `block(...)`**。

## 13.10 坑位清单

1. **以为 `try(expr)` 会返回表达式的值** → 它只回「异常对象或 `nil`」，成功值拿不到；要值就 `try(result := expr)`。
2. **以为未捕获异常会让退出码非零** → 横幅打 stdout、脚本中断、`rc` 仍是 0；判定必须靠结束标记。
3. **`catch` 的返回值和调用位置搞错** → handler 按**副作用**求值：命中时 `catch` 返回 `nil`、没命中把异常**原样返回**（链式分派就靠这条）；语法是先 `e := try(...)`，再 `e catch(类型, 动作)`，不是把 `catch` 写进 `try`。
4. **忘了 `pass`** → 没接住的异常会变成一个普通值被外层静默吞掉，`try` 只给你 `nil`。
5. **`raise(...) setNestedException(...)` 或者「先组装异常再 `raise`」** → `raise` 是立刻离场的，链在它后面的语句永不执行；而且 `raise` 总用自己的实参覆盖 `error`/`nestedException`。嵌套原因只能走 `raise` 的第二个参数。
6. **自定义异常从 `Error clone` 出发** → `Error` 不在 `Exception` 家族、没有 `raise`，会得到「`Error does not respond to 'raise'`」这种误导性报错。
7. **指望 `e originalCall` 做堆栈回溯** → 普通运算错误里它是 `nil`；回溯要用 `e coroutine showStack`，而它带地址，不能进回归输出。
8. **把 `e showStack` 打进示例输出** → 里面有地址和源文件行号，逐字节比对必挂；要取证就断言 `hasSlot("showStack")`。
9. **`try` 里跑会挂死的代码** → `try` 只接异常、不接「不返回」，挂死的代码在 `try` 里照样挂死，必须用子进程 + 超时兜住。
10. **用 `method(...)` 造 `withHandler` 的处理器** → `method` 造的块 `isActivatable = true`，一进形参（形参就是槽）就被**零参调用**，异常对象传不进去，报错还跟着处理器返回值变（返回 `42` 就报 `Number does not respond to 'call'`）；处理器一律用 `block(exc, resume, …)`（11.3.1）。

---

上一章：[12 · 迭代与集合遍历](12-iteration.md) · 下一章：[14 · 文件与目录](14-files.md)
