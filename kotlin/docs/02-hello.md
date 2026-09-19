# 02 · 第一个程序

> 对应示例：`examples/02_hello/`
>
> 本章把"从源码到运行"的全流程走一遍：编译器在哪、产物是什么、怎么跑、
> 顺带记住三个语法常量——`fun main()`、字符串模板、单表达式函数。

## 2.1 Hello, World

```kotlin
fun main() {
    println("Hello, Kotlin!")
}
```

就这么多。没有 class、没有 static、没有分号、没有 `String[] args`（不需要参数时可以不写）。Kotlin 的顶层函数直接编译成「文件类 + 静态方法」，`main` 就是程序入口。

## 2.2 用 kotlinc 手工编译一次（理解 Gradle 之前先懂底层）

```bash
# 编译成自带运行库的独立 jar（慢，~10s，教学用）
kotlinc-jvm hello.kt -include-runtime -d hello.jar
java -jar hello.jar

# 快的方式：只编出 .class，用 kotlin-stdlib 做 classpath
kotlinc-jvm -Werror -d out hello.kt
# classpath 分隔符：Windows ';' / macOS、Linux ':'
java -cp "out:/opt/local/share/java/kotlin/lib/kotlin-stdlib.jar" HelloKt     # macOS
java -cp "out;G:\scoop\apps\kotlin\current\lib\kotlin-stdlib.jar" HelloKt     # Windows
```

要点：

1. `hello.kt` 里的顶层 `main` 编译到 **`HelloKt`** 类（文件名 + Kt 后缀）——`java` 直跑时要写这个类名，不是 `hello`。
2. `-include-runtime` 把 stdlib 塞进 jar，产物 ~5MB、可独立运行；不带它就得自己挂 classpath。
3. 两个入口脚本（run-all.sh / build.ps1）用的是方式二（快），并给 java 统一加了 `-Dstdout.encoding=UTF-8`（Windows 控制台中文的关键，JDK 19+ 才有这个开关；macOS/Linux 上 JDK 18+ 默认就是 UTF-8，加上无害）。

## 2.3 字符串模板：`$` 的两种形态

```kotlin
val a = 1
val b = 2
println("$a + $b = ${a + b}")        // 1 + 2 = 3
println("${"kotlin".uppercase()}")   // 花括号里可以是任意表达式
```

`$变量` 直接嵌；`${表达式}` 带花括号。这是日常代码的一半体积来源——Java 的 `String.format`/`+` 拼接可以退休了。

## 2.4 函数的两种身体

```kotlin
fun greet(name: String): String {
    return "你好, $name!"          // 块体：显式 return
}
fun repeatGreet(word: String, times: Int): String = word.repeat(times)   // 单表达式体：=
```

单表达式函数用 `=` 连接，返回类型通常可省略（公共 API 建议写明，读者和编译器都省事）。

## 2.5 命令行参数

```kotlin
fun main(args: Array<String>) {          // 需要时才声明这个参数
    println("参数个数: ${args.size}")
}
```

示例 `02_hello` 把参数处理抽成了纯函数 `renderArgs(args)`——**main 只做组装，逻辑进可测试的函数**。这是全书反复出现的结构：

```kotlin
fun renderArgs(args: Array<String>): String = buildString {
    appendLine("参数个数: ${args.size}")
    for ((i, a) in args.withIndex()) appendLine("参数[$i]: $a")
}
```

`buildString { }` 是标准库的字符串构建器（接收者 lambda，12 章细讲），`appendLine` 追加换行——注意它追加的是 **`\n`，不是 Windows 的 `\r\n`**（10 章测试里踩过这个坑，比对输出时必须统一换行符）。

## 2.6 三种"立即跑"的形态

```kotlin
// 1. 脚本文件 hello.kts：顶层语句直接执行（不带 main）
println("脚本里直接写语句")

// 2. REPL
kotlinc-jvm          // 进入交互式，:quit 退出

// 3. 单文件直跑（kotlin 命令 = 编译+运行一步）
kotlin hello.kt
```

`.kts` 脚本适合当"更严谨的 bash"；REPL 适合试 API；真实工程用 Gradle（17 章）。

## 2.7 示例与验证

```
examples/02_hello/
├── src/Main.kt        # 演示输出（分节打印）
├── test/Tests.kt      # kotlin.test 断言 + 极简 main 入口
└── expected.txt       # 运行输出的"黄金快照"
```

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello
# [L1] kotlinc -Werror 编译 → [L2] TestsKt 测试 → [L3] MainKt 运行 → [L4] 与 expected.txt 比对
```

**测试入口的写法**（全书 22 个 kotlinc 示例统一）：kotlin.test 的断言 + 手写 main 逐个调用测试函数——没有 JUnit runner 也能获得断言与清晰报错；17 章会展示 Gradle 工程里正统的 JUnit5 形态。

```kotlin
import kotlin.test.assertEquals

fun testGreet() {
    assertEquals("你好, Kotlin!", greet("Kotlin"))
}

fun main() {
    testGreet()
    println("02_hello 全部测试通过")     // 走到这行 = 前面断言全过
}
```

## 2.8 坑位清单

1. **`HelloKt` 不是 `hello`**：顶层 main 的类名 = 文件名去扩展名 + `Kt`。想自定义用 `@file:JvmName("Main")`（18 章）。
2. **Windows 控制台中文乱码**：`java -Dstdout.encoding=UTF-8` + PowerShell `[Console]::OutputEncoding = UTF8`，两个都要。
3. **PATH 上的 java 8**：本机默认 java 太老，先 `JAVA_HOME` 指到 JDK 17+。
4. `println` 用平台换行（Windows 是 `\r\n`），`appendLine` 固定 `\n`——拼字符串比对时统一成 `\n`。
5. `kotlinc-jvm.bat` 走批处理传参：含空格/分号的路径会被拆，命令行复杂时用 `@argsfile`（build.ps1 的做法）。
