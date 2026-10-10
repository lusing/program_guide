# 05 · 函数与 Callable

> 对应示例：`examples/05_functions/`

## 5.1 示例全文

`examples/05_functions/main.gd`：

```gdscript
extends SceneTree

func add(a: int, b: int) -> int:
    return a + b

func apply_potion(target: String, amount := 10) -> String:
    return "%s 恢复了 %d HP" % [target, amount]

var square := func(x: int) -> int:
    return x * x

func factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)

func _initialize():
    print("7 + 5 = ", add(7, 5))
    print(apply_potion("Alice"))
    print(apply_potion("Bob", 25))
    print("6 的平方 = ", square.call(6))
    print("5! = ", factorial(5))

    var ops := [add, factorial]
    for op in ops:
        print("Callable 名：", op)
    quit()
```

实测输出：

```text
7 + 5 = 12
Alice 恢复了 10 HP
Bob 恢复了 25 HP
6 的平方 = 36
5! = 120
Callable 名：SceneTree(main.gd)::add
Callable 名：SceneTree(main.gd)::factorial
```

## 5.2 签名：参数注解、返回值注解、默认值

`func add(a: int, b: int) -> int:` —— 参数类型与返回类型都用注解锁死，传错、接错
都会在编译期被拦下；不写返回注解则默认可能返回任何东西（无 `return` 时返回 `null`）。

`apply_potion(target: String, amount := 10)` 演示默认参数：`amount` 由 `:= 10`
推断为 `int` 并带默认值，调用方 `apply_potion("Alice")` 省略它即得 10——输出第一行
就是证据。规则与其他语言一致：**默认参数必须排在必需参数之后**。

## 5.3 函数是一等值：Callable

`var ops := [add, factorial]` 把**函数本身**（不是调用结果）装进数组。裸函数名在
值语境下会生成 `Callable` 对象，打印它得到 `SceneTree(main.gd)::add`——`Callable`
的字符串形式是"所属实例::方法名"。调用方式三种：

```gdscript
add(7, 5)          # 直接写——最常见
add.call(7, 5)     # 显式 call——当 add 是变量/参数时推荐，意图清楚
add.callv([7, 5])  # 参数打包成数组传——动态转发用
```

这正是第 08 章信号订阅的参数类型：`signal.connect(callable)` 吃的就是 Callable。

## 5.4 lambda：匿名函数与捕获语义

示例里的 `square` 是一个 lambda 赋给成员变量：

```gdscript
var square := func(x: int) -> int:
    return x * x
```

调用写 `square.call(6)`（36 那一行输出）。lambda 的两大用途：一次性回调（信号订阅，
见 08 章）和把"一小段逻辑"当参数传递。**捕获语义必须实测清楚**（4.7.1）：lambda
按**值**捕获外围局部变量——经典的闭包计数器直接写会失效：

```gdscript
func make_counter():
    var count = 0
    return func():
        count += 1
        return count
# c.call() 三连发实测得到 1、1、1——每次的修改落在 count 的副本上，不跨调用累积
```

想要可变捕获，就套一层引用类型（Array/Dictionary/对象），复制引用后仍指向同一份数据：

```gdscript
func make_counter():
    var state := [0]      # Array 是引用语义
    return func():
        state[0] += 1
        return state[0]
# 实测三连发：1、2、3 ✓
```

另外注意接收侧：`make_counter()` 没有写返回注解，返回类型是 `Variant`，此时
`var c := make_counter()` 会**编译期报 "Cannot infer the type"**——动态返回值
配动态变量 `var c = make_counter()`，或者给函数补 `-> Callable` 注解。lambda 内
不适合写长逻辑——超过三行就该提成具名函数。

## 5.5 其他成员函数能力速览

- `static func util(x) -> int:`（4.1+）：不依赖实例，类级工具函数；
- 私有约定：下划线前缀 `_helper()` 表示"内部方法"，语言不强制；
- 多返回值：没有元组，惯用 `return [a, b]` 数组或 `return {"ok": true, "msg": …}`
  字典（第 06 章两种都会见到）；
- `func f(a, b)` 不写任何注解就是全动态——回调多态方便，但 IDE 补全失效，权衡使用。

## 5.6 坑位清单

1. **Callable ≠ 调用结果**：把 `add` 当值传（信号、数组、函数参数）时别手滑写成
   `add(...)`——传成 `null` 后报错点在很远的使用处。
2. **lambda 里的 `self`**：定义在节点脚本里的 lambda 捕获该节点；节点被 `queue_free`
   后 lambda 若还挂在信号上，调用会撞上"对象已释放"（08 章配合 `CONNECT_ONE_SHOT`
   与断连实践细讲）。
3. **无 return 分支默认回 `null`**：写了 `-> int` 注解却在某条路径漏 return，编译期
   直接报错——所以注解值得写。
4. **递归深度**：GDScript 递归栈保护在深递归时报 "Stack overflow"，游戏逻辑里的
   长链计算（寻路等）改用显式栈或引擎内置 API。

上一章：[04 · 控制流](04-control.md) ｜ 下一章：[06 · 集合：数组与字典](06-collections.md) ｜ 返回：[README](../README.md)
