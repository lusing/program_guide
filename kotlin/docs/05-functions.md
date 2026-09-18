# 05 · 函数

> 对应示例：`examples/05_functions/`
>
> Kotlin 的函数有六种"加分形态"：默认参数、具名参数、vararg、infix、
> tailrec、局部函数。它们共同消灭了 Java 的重载瀑布和工具类噪音。

## 5.1 基本形态

```kotlin
fun add(a: Int, b: Int): Int {          // 块体 + 显式返回类型
    return a + b
}
fun mul(a: Int, b: Int) = a * b         // 单表达式体（02 章讲过）
```

参数是 `val`（不可重新赋值）——想在函数里改，造个局部变量。

## 5.2 默认参数 + 具名参数：重载瀑布终结者

```kotlin
fun connect(
    host: String,
    port: Int = 8080,
    useTls: Boolean = false,
    timeoutMs: Long = 3000,
): String = "${if (useTls) "https" else "http"}://$host:$port (timeout=${timeoutMs}ms)"

connect("api.example.com")                                  // 全默认
connect("api.example.com", 443, true)                       // 位置参数
connect("db.example.com", port = 5432, timeoutMs = 10_000)  // 具名：随便跳过中间的
connect(timeoutMs = 500, host = "cdn.example.com")          // 全具名：顺序无关
```

Java 里这得写 4 个重载。规则：省略从后往前；具名参数一旦出现，后面全部具名（这条约束让调用点无歧义）。

## 5.3 vararg 与 spread 展开

```kotlin
fun sum(vararg nums: Int): Int {           // 函数内 nums 就是 IntArray
    var s = 0
    for (n in nums) s += n
    return s
}
sum(1, 2, 3)                    // 6
sum()                           // 0 个也行

val arr = intArrayOf(10, 20, 30)
sum(*arr, 5)                    // spread：数组展开混用 → 65
```

`*` 把数组拆成散参（Python 的 `*args` 同款）。vararg 之后还有参数的话，后面必须具名传。

## 5.4 infix：中缀调用

```kotlin
infix fun Int.pow(n: Int): Int {
    var r = 1
    repeat(n) { r *= this }
    return r
}
2 pow 10          // 1024 —— 省掉点和括号
2.pow(10)         // 等价
```

条件：成员或扩展、单参数。库里的 `to`（`1 to "a"` 造 Pair）、`until`、`downTo`、`step` 都是 infix——你天天在用。23 章会用它写测试 DSL（`result should eq 42`）。

## 5.5 tailrec：递归不怕栈

```kotlin
tailrec fun factorial(n: Long, acc: Long = 1L): Long =
    if (n <= 1) acc else factorial(n - 1, acc * n)   // 编译成循环，0 栈增长
```

`tailrec` 要求**递归调用必须是尾部操作**（返回值就是递归结果，不能再加工）。编译器验证并改写成循环——`factorial(100_000)` 不爆栈。写成 `n * factorial(n-1)` 就不是尾递归，编译器直接警告。

不符合尾递归形状的深递归：改循环，或用序列（22 章）。

## 5.6 局部函数：私有小工具就地声明

```kotlin
fun validateForm(name: String, email: String, age: Int): List<String> {
    fun err(field: String, why: String) = "$field 无效: $why"   // 闭包捕获外层参数
    val problems = mutableListOf<String>()
    if (name.isBlank()) problems += err("姓名", "为空")
    if (!email.contains('@')) problems += err("邮箱", "缺少 @")
    return problems
}
```

只被一个函数使用的小工具，就地声明还能直接用外层变量——比传一堆参数的 private 方法干净。

## 5.7 顶层函数：不需要类

```kotlin
// StringUtils.kt —— 直接写在文件里
fun slugify(s: String): String = ...
```

Kotlin 没有强制"万物皆类"。顶层函数编译成「文件类 + 静态方法」，Java 调用方看到 `StringUtilsKt.slugify(...)`（可用 `@file:JvmName` 改门面名，18 章）。`main` 本身就是顶层函数（02 章）。

## 5.8 泛型函数先行体验

```kotlin
fun <T : Comparable<T>> maxOf3(a: T, b: T, c: T): T = maxOf(a, maxOf(b, c))
maxOf3(3, 9, 7)          // Int
maxOf3("kotlin", "zig", "rust")   // String —— 同一函数
```

`<T : Comparable<T>>` 是上界约束。完整版（型变、reified、星投影）在 11 章。

## 5.9 函数类型一瞥

```kotlin
val square: (Int) -> Int = { x -> x * x }      // 函数是值
fun operate(a: Int, b: Int, op: (Int, Int) -> Int) = op(a, b)   // 函数是参数
```

这是 12 章的主菜——lambda、函数引用、接收者 lambda、作用域函数全部建立在函数类型上。

## 5.10 坑位清单

1. **默认参数的求值每次调用都发生**——`fun f(t: Long = System.currentTimeMillis())` 每次进函数都取新值；想要"构造时固定"，用 `lazy`（09 章）。
2. **Java 调 Kotlin 的默认参数看不到**——除非加 `@JvmOverloads` 让编译器生成重载（18 章实测）。
3. `infix` 优先级低于算术：`2 pow 10 + 1` 是 `2 pow (10+1)`？不——infix 优先级介于比较和算术之间，**含混时永远加括号**。
4. tailrec 不改语义只改实现；写错形状（非尾调用）时是 warning 不是 error，别忽视。
5. 位置参数 + 具名参数混用时，具名之后的不能再回位置式。
6. vararg 参数在函数里是**数组**（`IntArray`/`Array<T>`），想要 List 自己 `.toList()`。
