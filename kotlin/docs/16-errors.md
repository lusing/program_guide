# 16 · 异常与错误处理

> 对应示例：`examples/16_errors/`
>
> try/throw 都是表达式、Nothing 类型、require/check 校验三件套、
> runCatching/Result 链、以及"异常 vs 值"的双轨策略。

## 16.1 try 是表达式

```kotlin
val a = try { "42".toInt() } catch (e: NumberFormatException) { null }   // 42
val b = try { "x".toInt() } catch (e: NumberFormatException) { null }    // null
```

try 直接产出值——"解析 + 失败兜底"一行化。（更地道的解析用 `toIntOrNull()`，04 章。）

## 16.2 throw 也是表达式：类型是 Nothing

```kotlin
fun boom(): Nothing = throw AppError.Invalid("必炸")

val first = list.firstOrNull() ?: boom()     // elvis 右侧 Nothing → first: Int
```

`Nothing` 是**所有类型的子类型**——"永不返回"的表达式可以出现在任何需要值的位置。它的三个高频出场：`throw`、`TODO()`、`error()`。elvis 右侧放 `boom()/error("...")` 是"取不到值就终止"的标准写法。

## 16.3 自定义异常：密封层级

```kotlin
sealed class AppError(message: String) : Exception(message) {
    class NotFound(val key: String) : AppError("找不到: $key")
    class Invalid(val why: String) : AppError("非法输入: $why")
}

try {
    s1.get("zzz")
} catch (e: AppError.NotFound) {          // 精确子类
} catch (e: AppError) {                    // sealed 根：一个分支收全
}
```

密封异常（08 章的 ADT 思想）让 catch 分支也"有穷尽感"——加新错误类型时，IDE 能列出全部兄弟类。

## 16.4 require / check / error：校验三件套

```kotlin
fun shrink(s: String, n: Int): String {
    require(n >= 0) { "n 不能为负: $n" }        // 参数校验 → IllegalArgumentException
    check(s.length >= n) { "串太短" }           // 状态校验 → IllegalStateException
    return s.take(n)
}
```

| 函数 | 语义 | 抛出 | 用途 |
|---|---|---|---|
| `require(cond) { msg }` | 调用方契约 | IllegalArgumentException | 公开 API 的参数防线 |
| `check(cond) { msg }` | 自身状态 | IllegalStateException | "到这不该为假"的断言 |
| `error(msg)` | 直接抛 | IllegalStateException | 不可达分支/elvis 兜底 |

比手写 `if (!cond) throw ...` 省一半行数，且 msg 是**惰性 lambda**（不触发就不拼字符串）。

## 16.5 runCatching 与 Result

```kotlin
val r1 = runCatching { "42".toInt() }             // Result<Int>.Success
val r2 = runCatching { "x".toInt() }              // Result<Int>.Failure

r1.getOrNull()                // 42 / null
r2.getOrElse { -1 }           // -1
r1.map { it * 2 }             // Result<Int>：成功才变换
r2.recoverCatching { 0 }      // 失败才计算默认
r1.fold({ ok -> ... }, { err -> ... })   // 两分支消费
runCatching { "8" }.mapCatching { it.toInt() }.mapCatching { it * 100 }   // 链式变换
```

`Result` 是标准库内置的"成功或失败"盒子：**异常在边界转成值，之后用函数式管道传递**——调用方被迫处理失败（编译器盯着）。`fold` 是终极消费，`map/mapCatching/recover` 是链式加工。

注意：`Result` 不能直接当返回类型用会得到警告（设计如此——它定位是内部管线，公开 API 的错误建模用 sealed 类型或直接异常，见 16.7）。

## 16.6 use：自动关闭

```kotlin
"第一行\n第二行".reader().use { r ->
    println(r.readText())        // use 块结束自动 close（哪怕抛异常）
}
File("a.txt").bufferedReader().use { it.forEachLine { } }   // IO 标配
```

等价 Java try-with-resources。任何 `AutoCloseable` 都能用。

## 16.7 策略：什么时候 throw，什么时候返回值

| 场景 | 选择 | 理由 |
|---|---|---|
| 调用方 bug（传了非法参数） | `require`/throw | 快速失败，栈就是文档 |
| 程序员自己的不变量被打破 | `check`/throw | 同上 |
| **可预期的业务失败**（文件不存在、网络超时、解析失败） | `Result` / sealed 返回值 / `xxxOrNull` | 调用方必须处理，编译器强制 |
| 边界适配（库抛异常，你的 API 是值风格） | `runCatching` | 异常→值的翻译器 |
| 跨越协程/线程的失败 | 异常（沿作用域树传播）+ 边界转 Result | 14 章的传播模型 |

双轨示例（16 章示例代码里的 Store1/Store2）：

```kotlin
class Store1 { fun get(k: String): Int = data[k] ?: throw AppError.NotFound(k) }   // 抛
class Store2 { fun get(k: String): Result<Int> = ... }                             // 值
```

**内部层 throw（快死）+ 边界层转 Result（好处理）**是服务端的常见组合。

## 16.8 与 Java checked exception 对照

Kotlin 没有 checked exception——不强制 catch/声明。哲学：异常签名强制带来的是吞异常的样板（`catch (e) { }`），不是安全。替代防线：空安全消灭了最大的异常源；可预期失败鼓励走值通道。调用 Java 抛受检异常的 API 时，Kotlin 侧随便（不写 throws 也行）；反向给 Java 看见要 `@Throws`（18 章）。

## 16.9 坑位清单

1. **catch 后别吞**——空 catch 块比崩溃更难查；至少 log 或 rethrow。
2. `runCatching` 会捕获**所有** Throwable（包括 CancellationException）——协程代码里别用它包住含挂起点的块，会把"取消"误当失败（用 `coroutineScope` + 特定异常捕获）。
3. `Result.getOrThrow()`/`getOrNull()` 忘了兜底 = 回到异常世界；管道末端记得 `fold/getOrElse`。
4. `finally` 里的 return 会吃掉 try 里的异常（JVM 老坑，Kotlin 同样）——finally 只做清理。
5. 密封异常的 `catch (e: AppError)` 分支顺序：子类在前、根在后（先具体后宽泛，与 Java 相同）。
6. `error()`/`TODO()` 返回 Nothing——用它初始化的 val 编译过但运行必炸，别当占位值留在生产代码。
