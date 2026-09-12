# Kotlin 编程指南

## 目录

1. [简介](#1-简介)
2. [环境搭建](#2-环境搭建)
3. [基础语法](#3-基础语法)
4. [类型系统](#4-类型系统)
5. [函数](#5-函数)
6. [类与对象](#6-类与对象)
7. [集合](#7-集合)
8. [协程](#8-协程)
9. [扩展函数](#9-扩展函数)
10. [高阶函数与Lambda](#10-高阶函数与lambda)
11. [泛型](#11-泛型)
12. [委托](#12-委托)
13. [密封类与枚举](#13-密封类与枚举)
14. [图形界面编程](#14-图形界面编程)
15. [代码调试](#15-代码调试)
16. [多任务编程](#16-多任务编程)
17. [Kotlin与Java互操作](#17-kotlin与java互操作)
18. [Kotlin/JS - 编译成JavaScript](#18-kotlinjs---编译成javascript)
19. [Kotlin标准库参考](#19-kotlin-标准库参考)
20. [最佳实践](#20-最佳实践)

---

## 1. 简介

### 1.1 Kotlin 概述

Kotlin 是一种现代的静态类型编程语言，运行在 JVM 上，也可编译为 JavaScript 或原生代码。它由 JetBrains 开发，于 2017 年成为 Android 的官方支持语言。

**主要特性：**

- **简洁**：减少样板代码
- **安全**：空安全特性避免空指针异常
- **互操作**：100% 与 Java 互操作
- **函数式编程**：支持高阶函数和 Lambda
- **面向对象**：完整的 OOP 支持

### 1.2 第一个程序

```kotlin
fun main() {
    println("Hello, Kotlin!")
}
```

编译运行：
```bash
# 编译
kotlinc hello.kt -include-runtime -d hello.jar
# 运行
java -jar hello.jar
```

---

## 2. 环境搭建

### 2.1 安装 Kotlin

**Windows (Chocolatey)：**
```bash
choco install kotlin
```

**macOS (Homebrew)：**
```bash
brew install kotlin
```

**Linux (AUR)：**
```bash
yay -S kotlin
```

### 2.2 IntelliJ IDEA

1. 下载 [IntelliJ IDEA](https://www.jetbrains.com/idea/)
2. 选择 Community 或 Ultimate 版本
3. 创建新项目 → Kotlin → JVM

### 2.3 Gradle 配置

```kotlin
plugins {
    kotlin("jvm") version "1.9.24"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(kotlin("stdlib"))
}
```

### 2.4 Maven 配置

```xml
<properties>
    <kotlin.version>1.9.24</kotlin.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.jetbrains.kotlin</groupId>
        <artifactId>kotlin-stdlib</artifactId>
        <version>${kotlin.version}</version>
    </dependency>
</dependencies>
```

---

## 3. 基础语法

### 3.1 变量与常量

```kotlin
// 可变变量
var count: Int = 10
count = 20

// 不可变常量
val name: String = "Kotlin"
// name = "Java"  // 编译错误

// 类型推导
var age = 25  // 自动推导为 Int
```

### 3.2 基本数据类型

| 类型 | 描述 | 字节数 |
|------|------|--------|
| `Byte` | 8位整数 | 1 |
| `Short` | 16位整数 | 2 |
| `Int` | 32位整数 | 4 |
| `Long` | 64位整数 | 8 |
| `Float` | 32位浮点数 | 4 |
| `Double` | 64位浮点数 | 8 |
| `Char` | 字符 | 2 |
| `Boolean` | 布尔值 | 1 |
| `String` | 字符串 | - |

```kotlin
val maxInt: Int = Int.MAX_VALUE
val minLong: Long = Long.MIN_VALUE
```

### 3.3 字符串

```kotlin
// 字符串模板
val name = "Alice"
val age = 25
println("Name: $name, Age: $age")

// 表达式模板
println("Next year: ${age + 1}")

// 原始字符串 (multiline strings)
val html = """
    <html>
        <body>
            <p>Hello!</p>
        </body>
    </html>
"""

// trimIndent 去除缩进
val indent = """
    |line 1
    |line 2
    |line 3
""".trimMargin()

// 字符串操作
val str = "Hello Kotlin"
str.length       // 长度
str[0]           // 索引
str.substring(0, 5)
str.uppercase()
str.lowercase()
str.contains("Hello")
```

### 3.4 运算符

```kotlin
// 算术运算
val sum = 10 + 5
val diff = 10 - 5
val product = 10 * 5
val quotient = 10 / 5
val remainder = 10 % 3

// 比较运算
val equal = (a == b)
val notEqual = (a != b)
val greater = (a > b)
val less = (a < b)

// 逻辑运算
val andResult = true && false
val orResult = true || false
val notResult = !true

// 区间运算
val range = 1..10        // 1 到 10 (包含)
val halfRange = 1 until 10 // 1 到 9 (不包含)
val stepRange = 1..10 step 2 // 1, 3, 5, 7, 9
```

### 3.5 控制流

#### if 表达式

```kotlin
// if 是表达式，有返回值
val max = if (a > b) a else b

// 多条件
val result = when {
    a > b -> "a > b"
    a < b -> "a < b"
    else -> "a == b"
}
```

#### when 表达式

```kotlin
when (x) {
    1 -> println("x == 1")
    2 -> println("x == 2")
    3, 4 -> println("x is 3 or 4")
    in 5..10 -> println("x is 5-10")
    !in 20..30 -> println("x is not 20-30")
    is String -> println("x is a String")
    else -> println("default")
}

// 带参数的 when
when (x) {
    in 1..10 -> println("in range")
    !in 20..30 -> println("not in range")
}
```

#### for 循环

```kotlin
// 遍历数组
val arr = arrayOf(1, 2, 3)
for (item in arr) {
    println(item)
}

// 带索引
for ((index, value) in arr.withIndex()) {
    println("index: $index, value: $value")
}

// 遍历区间
for (i in 1..5) {
    println(i)
}

// 逆序遍历
for (i in 5 downTo 1) {
    println(i)
}

// 指定步长
for (i in 1..10 step 2) {
    println(i)
}
```

#### while 循环

```kotlin
var i = 0
while (i < 5) {
    println(i)
    i++
}

do {
    println(i)
    i++
} while (i < 10)
```

---

## 4. 类型系统

### 4.1 空安全

Kotlin 的类型系统核心是**空安全**。

```kotlin
// 非空类型
var name: String = "Kotlin"
name = null  // 编译错误

// 可空类型
var nullableName: String? = null
nullableName = "Kotlin"

// 安全调用操作符
val length = nullableName?.length

// Elvis 操作符
val len = nullableName?.length ?: 0

// 不为空断言
val len2 = nullableName!!.length  // 为 null 时抛出异常

// 安全转换
val num: Int? = "123" as? Int
```

### 4.2 类型检查与转换

```kotlin
// is 检查
fun process(obj: Any) {
    if (obj is String) {
        println(obj.uppercase())
    }
}

// 智能转换
fun process2(obj: Any) {
    if (obj is String) {
        // 自动转换为 String
        println(obj.length)
    } else if (obj is Int) {
        println(obj + 1)
    }
}

// as? 安全转换
val num: Int? = "123" as? Int
```

### 4.3 数组

```kotlin
// 创建数组
val arr1 = arrayOf(1, 2, 3, 4, 5)
val arr2 = Array(5) { i -> i * 2 }
val arr3 = intArrayOf(1, 2, 3)

// 访问元素
arr1[0] = 10
val first = arr1[0]

// 数组属性
arr1.size
arr1.isEmpty()
arr1.isNotEmpty()

// 遍历
arr1.forEach { println(it) }
arr1.forEachIndexed { index, value -> println("$index: $value") }

// 常用操作
val sum = arr1.sum()
val filtered = arr1.filter { it > 2 }
val mapped = arr1.map { it * 2 }
```

---

## 5. 函数

### 5.1 函数定义

```kotlin
// 基本函数
fun greet(name: String): String {
    return "Hello, $name"
}

// 单表达式函数
fun add(a: Int, b: Int) = a + b

// 默认参数
fun hello(name: String = "World") = "Hello, $name"

// 谰用
hello()           // Hello, World
hello("Alice")    // Hello, Alice

// 命名参数
fun createPerson(name: String, age: Int, city: String) { /* ... */ }
createPerson(age = 25, name = "Bob", city = "Beijing")

// 可变参数
fun varargs(vararg numbers: Int) {
    numbers.forEach { println(it) }
}
varargs(1, 2, 3, 4, 5)

// 广播操作符
val arr = intArrayOf(1, 2, 3)
varargs(*arr)
```

### 5.2 函数返回

```kotlin
// 显式返回
fun findMax(arr: IntArray): Int {
    var max = arr[0]
    for (num in arr) {
        if (num > max) max = num
    }
    return max
}

// 隐式返回 (最后一个表达式)
fun findMin(arr: IntArray) = arr.minOrNull() ?: 0

// 跳过迭代
fun printEven(arr: IntArray) {
    for (num in arr) {
        if (num % 2 != 0) continue
        println(num)
    }
}

// 早退
fun validate(input: String?): Boolean {
    if (input == null) return false
    if (input.isEmpty()) return false
    return true
}
```

### 5.3 内联函数

```kotlin
// inline 减少 Lambda 造成的对象分配
inline fun measureTime(block: () -> Unit) {
    val start = System.currentTimeMillis()
    block()
    println("Time: ${System.currentTimeMillis() - start}ms")
}

measureTime {
    // 你的代码
    Thread.sleep(100)
}
```

### 5.4 扩展函数

```kotlin
// 为现有类添加新功能
fun String.lastChar(): Char = this[this.length - 1]

"Hello".lastChar()  // 'o'

// 带接收者的函数字面量
val sum = { x: Int, y: Int -> x + y }
```

---

## 6. 类与对象

### 6.1 类定义

```kotlin
// 基本类
class Person {
    var name: String = ""
    var age: Int = 0
}

// 构造函数
class Person(val name: String, var age: Int)

// 主构造函数与初始化块
class Person(
    val name: String,
    var age: Int,
    val city: String = "Unknown"
) {
    init {
        println("Person created: $name")
    }
}

// 次构造函数
class Person(val name: String) {
    var age: Int = 0

    constructor(name: String, age: Int) : this(name) {
        this.age = age
    }
}
```

### 6.2 继承

```kotlin
// open 类可被继承
open class Animal(val name: String) {
    open fun makeSound() = println("Unknown sound")
}

class Dog(name: String) : Animal(name) {
    override fun makeSound() {
        println("Woof!")
    }
}

// super 调用
class Cat(name: String) : Animal(name) {
    override fun makeSound() {
        super.makeSound()
        println("Meow!")
    }
}
```

### 6.3 抽象类与接口

```kotlin
// 抽象类
abstract class Shape {
    abstract fun area(): Double
    fun description() = "I am a shape"
}

class Circle(val radius: Double) : Shape() {
    override fun area() = Math.PI * radius * radius
}

// 接口
interface Flyable {
    fun fly()
    fun land() { println("Landing") }  // 默认实现
}

class Bird : Flyable {
    override fun fly() = println("Flying")
}

// 多重继承
class SuperBird : Animal("Bird"), Flyable {
    override fun makeSound() = println("Squawk")
    override fun fly() = println("Flying high")
}
```

### 6.4 数据类

```kotlin
// 数据类自动生成 equals, hashCode, toString 等
data class User(val id: Int, val name: String, val email: String)

val user = User(1, "Alice", "alice@example.com")
println(user)  // User(id=1, name=Alice, email=alice@example.com)

// copy 方法
val user2 = user.copy(name = "Bob")

// 解构声明
val (id, name, email) = user
```

### 6.5 单例模式

```kotlin
// object 声明单例
object Singleton {
    fun doSomething() = println("Done")
}

Singleton.doSomething()

// 伴生对象
class MyClass {
    companion object {
        const val VERSION = "1.0"
        fun create() = MyClass()
    }
}

MyClass.VERSION
MyClass.create()
```

### 6.6 枚举类

```kotlin
enum class Color {
    RED, GREEN, BLUE
}

enum class Status(val code: Int, val description: String) {
    SUCCESS(200, "OK"),
    NOT_FOUND(404, "Not Found"),
    ERROR(500, "Server Error")
}

val status = Status.SUCCESS
println(status.code)  // 200
```

---

## 7. 集合

### 7.1 列表

```kotlin
// 不可变列表
val list: List<String> = listOf("A", "B", "C")
val emptyList = emptyList<Int>()

// 可变列表
val mutableList: MutableList<String> = mutableListOf("A", "B", "C")
mutableList.add("D")
mutableList.remove("B")
mutableList[0] = "X"

// 访问元素
list[0]              // 第一个元素
list.first()
list.last()
list.getOrNull(10)   // 安全访问
list.contains("A")

// 切片
list.subList(0, 2)
list.take(2)
list.drop(1)

// 转换
list.map { it.uppercase() }
list.filter { it.length > 1 }
list.sorted()
list.sortedDescending()
```

### 7.2 集合

```kotlin
// 不可变集合
val set: Set<String> = setOf("A", "B", "C")

// 可变集合
val mutableSet: MutableSet<String> = mutableSetOf("A", "B", "C")
mutableSet.add("D")
mutableSet.remove("A")

// 操作
set.contains("A")
set.union(setOf("X", "Y"))
set.intersect(setOf("A", "Z"))
set.minus(setOf("B"))
```

### 7.3 映射

```kotlin
// 不可变映射
val map: Map<String, Int> = mapOf("A" to 1, "B" to 2, "C" to 3)

// 可变映射
val mutableMap: MutableMap<String, Int> = mutableMapOf("A" to 1, "B" to 2)
mutableMap["C"] = 3
mutableMap.remove("A")
mutableMap["B"] = 10

// 访问
map["A"]
map.getOrNull("Z")
map.containsKey("A")
map.containsValue(1)

// 遍历
map.forEach { (key, value) -> println("$key: $value") }
map.keys
map.values
```

### 7.4 集合操作

```kotlin
val numbers = listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

// 过滤
val even = numbers.filter { it % 2 == 0 }
val filtered = numbers.filterNot { it > 5 }

// 映射
val squared = numbers.map { it * it }
val indexed = numbers.mapIndexed { i, v -> i to v }

// 分组
val grouped = numbers.groupBy { if (it % 2 == 0) "even" else "odd" }

// 归约
val sum = numbers.reduce { acc, v -> acc + v }
val sumWithInit = numbers.reduceIndexed { i, acc, v -> acc + v }

// 所有/任意
val allPositive = numbers.all { it > 0 }
val anyEven = numbers.any { it % 2 == 0 }
val noneNegative = numbers.none { it < 0 }

// 分割
val (even, odd) = numbers.partition { it % 2 == 0 }
```

---

## 8. 协程

### 8.1 基础概念

Kotlin 协程是轻量级的线程，用于异步编程。

**Gradle 依赖：**
```kotlin
dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

### 8.2 协程构建器

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    // launch: 启动新协程，不返回结果
    launch {
        delay(1000)
        println("Launch: Done")
    }

    // async: 启动新协程，返回结果
    val deferred = async {
        delay(1000)
        "Async: Result"
    }
    println(deferred.await())

    // runBlocking: 阻塞当前线程直到协程完成
    println("Before delay")
    delay(500)
    println("After delay")
}
```

### 8.3 协程上下文与调度器

```kotlin
// 使用不同调度器
GlobalScope.launch(Dispatchers.Default) {
    // CPU 密集任务
}

GlobalScope.launch(Dispatchers.IO) {
    // I/O 操作
}

GlobalScope.launch(Dispatchers.Unconfined) {
    // 不限制线程
}
```

### 8.4 协程取消与超时

```kotlin
fun main() = runBlocking {
    val job = launch {
        repeat(1000) { i ->
            delay(100)
            println("Job: $i")
        }
    }

    delay(500)
    job.cancel()

    // withTimeout
    try {
        withTimeout(1000) {
            delay(2000)
        }
    } catch (e: TimeoutException) {
        println("Timeout!")
    }

    // withTimeoutOrNull
    val result = withTimeoutOrNull(1000) {
        delay(500)
        "Done"
    }
    println(result)  // Done
}
```

### 8.5 协程通信

```kotlin
// Channel
fun main() = runBlocking {
    val channel = Channel<Int>()

    launch {
        for (x in 1..5) {
            channel.send(x * x)
        }
        channel.close()
    }

    for (y in channel) {
        println(y)
    }
}

// Flow
fun main() = runBlocking {
    flow {
        for (i in 1..5) {
            delay(100)
            emit(i)
        }
    }.collect { value ->
        println(value)
    }

    // 流操作
    flow {
        emit(1)
        emit(2)
        emit(3)
    }.map { it * it }.filter { it % 2 == 0 }.collect {
        println(it)
    }
}
```

---

## 9. 扩展函数

### 9.1 定义扩展函数

```kotlin
// 为 String 添加函数
fun String.lastChar(): Char = this[this.length - 1]

// 为 List 添加函数
fun <T> List<T>.second(): T = this[1]

// 使用
"Hello".lastChar()  // 'o'
listOf(1, 2, 3).second()  // 2
```

### 9.2 扩展属性

```kotlin
// 扩展属性 (不能有字段，只能用 getter/setter)
val String.lastIndex: Int
    get() = this.length - 1

val List<Int>.sum: Int
    get() = this.reduce { acc, v -> acc + v }
```

### 9.3 扩展函数的静态特性

```kotlin
// 扩展函数是静态解析的
open class Animal
class Dog : Animal()

fun Animal.speak() = "Animal sound"
fun Dog.speak() = "Woof!"

fun makeAnimalSpeak(animal: Animal) {
    println(animal.speak())  // Animal sound，不是多态
}
```

### 9.4 带接收者的函数字面量

```kotlin
// DSL 示例
html {
    head {
        title { +"My Page" }
    }
    body {
        h1 { +"Welcome" }
    }
}

// 定义
fun html(block: HTML.() -> Unit): HTML {
    val html = HTML()
    html.block()
    return html
}
```

---

## 10. 高阶函数与 Lambda

### 10.1 函数作为参数

```kotlin
// 高阶函数
fun operate(a: Int, b: Int, operation: (Int, Int) -> Int): Int {
    return operation(a, b)
}

val sum = operate(10, 5) { x, y -> x + y }
val diff = operate(10, 5) { x, y -> x - y }
```

### 10.2 Lambda 表达式

```kotlin
// 基本 Lambda
val add: (Int, Int) -> Int = { x, y -> x + y }

// 单参数 Lambda (it)
val squared = listOf(1, 2, 3, 4).map { it * it }

// with 与 run
val str = "Hello"
with(str) {
    println(length)
    println(uppercase())
}

val result = run {
    val x = 10
    val y = 20
    x + y
}
```

### 10.3 闭包

```kotlin
var counter = 0
val increment: () -> Int = {
    counter++
    counter
}

println(increment())  // 1
println(increment())  // 2
```

### 10.4 内联函数与 noinline

```kotlin
inline fun logger(block: () -> Unit) {
    println("Start")
    block()
    println("End")
}

// noinline 禁止内联
inline fun loggerWithCallback(
    block: () -> Unit,
    noinline callback: () -> Unit
) {
    block()
    callback()
}
```

---

## 11. 泛型

### 11.1 泛型基础

```kotlin
// 泛型类
class Box<T>(val value: T) {
    fun getValue(): T = value
}

val intBox = Box(123)
val stringBox = Box("Hello")

// 泛型函数
fun <T> wrap(value: T) = Box(value)
```

### 11.2 类型约束

```kotlin
// 上限约束
fun <T : Number> sumOfSquares(list: List<T>): Double {
    return list.map { it.toDouble() * it.toDouble() }.sum()
}

// 多重约束
fun <T> parsePair(
    pair: Pair<String, String>
): T where T : Number, T : Comparable<T> {
    return pair.first.toInt() as T
}
```

### 11.3 协变与逆变

```kotlin
// 协变 out (生产者)
interface Producer<out T> {
    fun produce(): T
}

// 逆变 in (消费者)
interface Consumer<in T> {
    fun consume(item: T)
}

// 不变
interface Container<T> {
    fun set(value: T)
    fun get(): T
}

// 星投影
val list: List<*> = listOf(1, 2, 3)
val first = list[0]  // 类型为 unknown
```

### 11.4 重新ified 泛型

```kotlin
// reified 允许在运行时访问类型
inline fun <reified T> isInstance(obj: Any): Boolean {
    return obj is T
}

inline fun <reified T> parseJSON(json: String): T {
    return ObjectMapper().readValue(json, T::class.java)
}

isInstance<String>("Hello")  // true
isInstance<String>(123)      // false
```

---

## 12. 委托

### 12.1 属性委托

```kotlin
// lazy 延迟初始化
val lazyValue: String by lazy {
    println("Computed!")
    "Hello"
}

// lateinit 延迟初始化 (可变属性)
lateinit var lateValue: String
lateValue = "Assigned"

// Delegates.observable
var name: String by Delegates.observable("Default") { prop, old, new ->
    println("$old -> $new")
}

// Delegates.vetoable
var age: Int by Delegates.vetoable(0) { prop, old, new ->
    new >= 0  // 只接受非负数
}
```

### 12.2 自定义委托

```kotlin
class Delegate {
    private var value: String? = null

    operator fun getValue(ref: Any?, prop: KProperty<*>): String {
        return value ?: "Default"
    }

    operator fun setValue(ref: Any?, prop: KProperty<*>, value: String) {
        this.value = value
    }
}

class MyClass {
    var prop: String by Delegate()
}
```

### 12.3 类委托

```kotlin
interface Shape {
    fun draw()
}

class Circle : Shape {
    override fun draw() = println("Circle")
}

// 类委托
class DecoratedShape(private val shape: Shape) : Shape by shape {
    fun decorate() = println("Decorated")
}

val circle = DecoratedShape(Circle())
circle.draw()  // 被委托
circle.decorate()
```

---

## 13. 密封类与枚举

### 13.1 密封类

```kotlin
// 密封类表示受限的类层次结构
sealed class Result {
    data class Success(val data: String) : Result()
    data class Error(val message: String) : Result()
    object Loading : Result()
}

fun process(result: Result) {
    when (result) {
        is Result.Success -> println("Success: ${result.data}")
        is Result.Error -> println("Error: ${result.message}")
        Result.Loading -> println("Loading...")
    }
}
```

### 13.2 枚举类

```kotlin
enum class DayOfWeek {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
}

enum class Operation(val symbol: String, val function: (Double, Double) -> Double) {
    ADD("+") { a, b -> a + b },
    SUBTRACT("-") { a, b -> a - b },
    MULTIPLY("*") { a, b -> a * b },
    DIVIDE("/") { a, b -> a / b }
}

// 使用
Operation.ADD.function(10.0, 5.0)  // 15.0
```

### 13.3 when 表达式强化

```kotlin
// when 必须 exhaustive
fun evaluate(expr: Any): String = when (expr) {
    is Int -> "Integer: $expr"
    is String -> "String: $expr"
    is List<*> -> "List with ${expr.size} elements"
    else -> "Unknown"
}

// 带条件的 when
fun describe(number: Int) = when {
    number < 0 -> "Negative"
    number == 0 -> "Zero"
    number % 2 == 0 -> "Even"
    else -> "Odd"
}
```

---

## 14. 图形界面编程

### 14.1 JavaFX 简介

Kotlin 可以通过 JavaFX 进行桌面 GUI 编程。JavaFX 是 Java 的现代 GUI 框架。

**Gradle 依赖：**
```kotlin
plugins {
    kotlin("jvm") version "1.9.24"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(kotlin("stdlib"))
    implementation("org.openjfx:javafx-controls:21:win")
    implementation("org.openjfx:javafx-fxml:21:win")
}

tasks.named<JavaExec>("run") {
    val jvmArgs = listOf(
        "--add-modules", "javafx.controls,javafx.graphics",
        "--add-opens", "javafx.graphics/javafx.scene=ALL-UNNAMED"
    )
    this.jvmArgs = jvmArgs
}
```

### 14.2 基本窗口

```kotlin
import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.control.Button
import javafx.scene.layout.StackPane
import javafx.stage.Stage

class Main: Application() {
    override fun start(stage: Stage) {
        val button = Button("Click Me")
        button.setOnAction {
            println("Button clicked!")
        }

        val root = StackPane(button)
        val scene = Scene(root, 300.0, 200.0)

        stage.title = "Kotlin JavaFX"
        stage.scene = scene
        stage.show()
    }
}

fun main() {
    Application.launch(Main::class.java)
}
```

### 14.3 布局容器

#### StackPane（层叠面板）

```kotlin
val root = StackPane()
root.style = "-fx-background-color: #f0f0f0"

val button1 = Button("Top")
val button2 = Button("Center")
val button3 = Button("Bottom")

StackPane.setAlignment(button1, Pos.TOP_CENTER)
StackPane.setAlignment(button2, Pos.CENTER)
StackPane.setAlignment(button3, Pos.BOTTOM_CENTER)

root.children.addAll(button1, button2, button3)
```

#### VBox（垂直布局）

```kotlin
import javafx.scene.layout.VBox
import javafx.geometry.Pos

val vbox = VBox(10.0)  // 10px 间距
vbox.alignment = Pos.CENTER
vbox.padding = Insets(20.0)

val label = Label("Hello")
val textField = TextField()
val button = Button("Submit")

vbox.children.addAll(label, textField, button)
```

#### HBox（水平布局）

```kotlin
import javafx.scene.layout.HBox

val hbox = HBox(20.0)  // 20px 间距
hbox.alignment = Pos.CENTER_LEFT

val btn1 = Button("OK")
val btn2 = Button("Cancel")
val btn3 = Button("Help")

hbox.children.addAll(btn1, btn2, btn3)
```

#### GridPane（网格布局）

```kotlin
import javafx.scene.layout.GridPane
import javafx.scene.control.Label
import javafx.scene.control.TextField
import javafx.scene.control.PasswordField

val grid = GridPane()
grid.hgap = 10.0
grid.vgap = 10.0
grid.padding = Insets(20.0)

grid.add(Label("Username:"), 0, 0)
val username = TextField()
grid.add(username, 1, 0)

grid.add(Label("Password:"), 0, 1)
val password = PasswordField()
grid.add(password, 1, 1)

val loginBtn = Button("Login")
GridPane.setHalignment(loginBtn, javafx.geometry.HPos.RIGHT)
grid.add(loginBtn, 1, 2)
```

#### BorderPane（边界布局）

```kotlin
import javafx.scene.layout.BorderPane

val border = BorderPane()

// 顶部
val topBar = HBox(Label("Header"))
BorderPane.setAlignment(topBar, Pos.CENTER)
border.top = topBar

// 底部
val statusBar = HBox(Label("Status: Ready"))
BorderPane.setAlignment(statusBar, Pos.CENTER_LEFT)
border.bottom = statusBar

// 中间
val center = StackPane(Label("Main Content"))
border.center = center
```

### 14.4 常用控件

#### Label 与 Text

```kotlin
val label = Label("Hello Kotlin")
label.style = "-fx-font-size: 16px; -fx-text-fill: #333;"

val text = Text("Welcome")
text.fontSize = 20.0
text.style = "-fx-font-weight: bold;"
```

#### Button

```kotlin
val button = Button("Click Me")
button.style = """
    -fx-background-color: #007bff;
    -fx-text-fill: white;
    -fx-padding: 10 20;
    -fx-border-radius: 5;
"""

button.onAction = EventHandler {
    println("Button pressed")
}

// 禁用按钮
button.isDisabled = true
```

#### TextField 与 TextArea

```kotlin
val textField = TextField()
textField.promptText = "Enter your name"
textField.prefColumnCount = 20

textField.textProperty().addListener { _, _, newValue ->
    println("Text changed: $newValue")
}

val textArea = TextArea()
textArea.prefRowCount = 5
textArea.wrapText = true
```

#### CheckBox 与 RadioButton

```kotlin
// CheckBox
val checkbox = CheckBox("Enable notifications")
checkbox.selected = true
checkbox.selectedProperty().addListener { _, _, newValue ->
    println("Checked: $newValue")
}

// RadioButton (单选)
val rb1 = RadioButton("Option 1")
val rb2 = RadioButton("Option 2")
val rb3 = RadioButton("Option 3")

val toggleGroup = ToggleGroup()
toggleGroup.buttons.addAll(rb1, rb2, rb3)

rb1.isSelected = true
```

#### ListView

```kotlin
import javafx.collections.FXCollections

val items = FXCollections.observableArrayList(
    "Apple", "Banana", "Cherry", "Date"
)

val listView = ListView(items)

listView.selectionModel.selectedItemProperty().addListener { _, _, newVal ->
    println("Selected: $newVal")
}

listView.setOnMouseClicked { event ->
    println("Clicked")
}
```

#### TableView

```kotlin
import javafx.scene.control.TableColumn
import javafx.scene.control.cell.PropertyValueFactory

data class Person(val name: String, val age: Int, val email: String)

val people = FXCollections.observableArrayList(
    Person("Alice", 25, "alice@example.com"),
    Person("Bob", 30, "bob@example.com"),
    Person("Charlie", 35, "charlie@example.com")
)

val table = TableView(people)

val nameCol = TableColumn<Person, String>("Name")
nameCol.cellValueFactory = PropertyValueFactory("name")
nameCol.prefWidth = 150.0

val ageCol = TableColumn<Person, Int>("Age")
ageCol.cellValueFactory = PropertyValueFactory("age")
ageCol.prefWidth = 80.0

val emailCol = TableColumn<Person, String>("Email")
emailCol.cellValueFactory = PropertyValueFactory("email")
emailCol.prefWidth = 200.0

table.columns.addAll(nameCol, ageCol, emailCol)
table.prefWidth = 430.0
```

#### ComboBox

```kotlin
val items = listOf("Java", "Kotlin", "Python", "JavaScript")
val comboBox = ComboBox(FXCollections.observableArrayList(*items.toArray()))

// 默认选中
comboBox.selectionModel.selectFirst()

// 监听选择
comboBox.setOnAction {
    println("Selected: ${comboBox.value}")
}
```

#### ProgressBar 与 ProgressIndicator

```kotlin
val progressBar = ProgressBar(0.0)
progressBar.prefWidth = 200.0

// 动画进度
val animate = Timeline(
    KeyFrame(Duration.seconds(0), KeyValue(progressBar.progressProperty(), 0.0)),
    KeyFrame(Duration.seconds(2), KeyValue(progressBar.progressProperty(), 1.0))
)
animate.cycleCount = Animation.INDEFINITE
animate.autoReverse = true
animate.play()

val progressIndicator = ProgressIndicator()
progressIndicator.progress = 0.5
progressIndicator.style = "-fx-scale-x: 2; -fx-scale-y: 2;"
```

#### Slider

```kotlin
val slider = Slider(0.0, 100.0, 50.0)
slider.showTickLabels = true
slider.showTickMarks = true
slider.majorTickUnit = 25.0
slider.minorTickCount = 4

slider.valueProperty().addListener { _, _, newValue ->
    println("Slider value: $newValue")
}
```

### 14.5 事件处理

```kotlin
// 鼠标事件
button.setOnMouseClicked { event ->
    println("Click at: ${event.x}, ${event.y}")
    if (event.clickCount == 2) {
        println("Double click!")
    }
}

// 键盘事件
textField.setOnKeyPressed { event ->
    when (event.code) {
        KeyCode.ENTER -> println("Enter pressed")
        KeyCode.ESCAPE -> println("Escape pressed")
        else -> println("Key: ${event.code}")
    }
}

// 拖放事件
val draggable = Label("Drag Me")
draggable.setOnDragDetected { event ->
    val db = draggable.startDragAndDrop(TransferMode.MOVE)
    db.setContent(DataFormat.PLAIN_TEXT to draggable.text)
    event.consume()
}
```

### 14.6 FXML 与 MVC

```xml
<!-- MainView.fxml -->
<?xml version="1.0" encoding="UTF-8"?>

<?import javafx.scene.control.*?>
<?import javafx.scene.layout.*?>

<BorderPane xmlns="http://javafx.com/javafx"
            xmlns:fx="http://javafx.com/fxml"
            fx:controller="com.example.MainViewController"
            prefWidth="600" prefHeight="400">

    <top>
        <MenuBar>
            <Menu text="File">
                <MenuItem text="Exit" onAction="#handleExit"/>
            </Menu>
        </MenuBar>
    </top>

    <center>
        <StackPane>
            <Label text="Main Content"/>
        </StackPane>
    </center>

    <bottom>
        <HBox alignment="BOTTOM_RIGHT" spacing="10">
            <Button text="OK" onAction="#handleOk"/>
            <Button text="Cancel" onAction="#handleCancel"/>
        </HBox>
    </bottom>
</BorderPane>
```

```kotlin
// MainViewController.kt
open class MainViewController {
    @javafx.fxml.FXML
    private lateinit var statusLabel: Label

    @javafx.fxml.FXML
    private fun initialize() {
        statusLabel.text = "Ready"
    }

    @javafx.fxml.FXML
    private fun handleOk() {
        statusLabel.text = "OK clicked"
    }

    @javafx.fxml.FXML
    private fun handleCancel() {
        statusLabel.text = "Cancel clicked"
    }

    @javafx.fxml.FXML
    private fun handleExit() {
        Platform.exit()
    }
}
```

```kotlin
// Main App
class App: Application() {
    override fun start(stage: Stage) {
        val loader = FXMLLoader(javaClass.getResource("/MainView.fxml"))
        val root = loader.load<Parent>()

        val scene = Scene(root, 600.0, 400.0)
        stage.scene = scene
        stage.show()
    }
}
```

### 14.7 CSS 样式

```kotlin
// 内联样式
button.style = """
    -fx-background-color: linear-gradient(to bottom, #1c6ba0, #145080);
    -fx-text-fill: white;
    -fx-font-size: 14px;
    -fx-padding: 8 16;
    -fx-border-radius: 4;
    -fx-background-radius: 4;
"""

button.hoverProperty().addListener { _, _, isHover ->
    if (isHover) {
        button.style = """
            -fx-background-color: linear-gradient(to bottom, #2a7cb5, #1d5f95);
        """
    } else {
        button.style = """
            -fx-background-color: linear-gradient(to bottom, #1c6ba0, #145080);
        """
    }
}
```

#### 外部 CSS 文件

```css
/* styles.css */
.root {
    -fx-background-color: #f5f5f5;
}

.button {
    -fx-background-color: #4caf50;
    -fx-text-fill: white;
    -fx-padding: 10 20;
}

.button:hover {
    -fx-background-color: #45a049;
}

.label {
    -fx-font-size: 16px;
    -fx-text-fill: #333;
}

.text-field {
    -fx-border-color: #ccc;
    -fx-padding: 8;
}
```

```kotlin
scene.stylesheets.add(javaClass.getResource("/styles.css").toExternalForm())
```

### 14.8 图形与绘图

```kotlin
import javafx.scene.shape.*
import javafx.scene.paint.*

// 矩形
val rect = Rectangle(50.0, 50.0, 100.0, 80.0)
rect.fill = Color.LIGHTBLUE
rect.stroke = Color.DARKBLUE
rect.arcHeight = 10.0  // 圆角
rect.arcWidth = 10.0

// 圆形
val circle = Circle(50.0, Color.RED)
circle.centerX = 100.0
circle.centerY = 100.0
circle.stroke = Color.BLACK
circle.strokeWidth = 2.0

// 线条
val line = Line(10.0, 10.0, 200.0, 100.0)
line.stroke = Color.BLUE
line.strokeWidth = 3.0

// 多边形
val polygon = Polygon(
    100.0, 20.0,
    140.0, 80.0,
    60.0, 80.0
)
polygon.fill = Color.CHARTREUSE
polygon.stroke = Color.DARKGREEN

// 路径
val path = Path(
    MoveTo(50.0, 150.0),
    LineTo(100.0, 100.0),
    LineTo(150.0, 150.0),
    LineTo(200.0, 100.0)
)
path.stroke = Color.PURPLE
path.fill = null
```

### 14.9 动画

```kotlin
import javafx.animation.*
import javafx.util.Duration

// 淡入动画
val fadeIn = FadeTransition(Duration.seconds(1), node)
fadeIn.fromValue = 0.0
fadeIn.toValue = 1.0
fadeIn.play()

// 缩放动画
val scale = ScaleTransition(Duration.seconds(0.5), node)
scale.fromX = 1.0
scale.fromY = 1.0
scale.toX = 1.2
scale.toY = 1.2
scale.autoReverse = true
scale.cycleCount = Animation.INDEFINITE
scale.play()

// 路径动画
val path = Path(
    MoveTo(0.0, 0.0),
    LineTo(100.0, 0.0),
    LineTo(100.0, 100.0)
)
val pathAnimation = PathTransition(Duration.seconds(2), path, circle)
pathAnimation.orientation = PathTransition.OrientationType.ORTHOGONAL_TO_TANGENT
pathAnimation.play()

// 逐帧动画
val frames = Timeline(
    KeyFrame(Duration.seconds(0), KeyValue(node.opacityProperty(), 0.0)),
    KeyFrame(Duration.seconds(0.5), KeyValue(node.opacityProperty(), 0.5)),
    KeyFrame(Duration.seconds(1), KeyValue(node.opacityProperty(), 1.0))
)
frames.play()
```

### 14.10 对话框

```kotlin
import javafx.scene.control.*

// Alert 对话框
val alert = Alert(Alert.AlertType.INFORMATION)
alert.title = "Information"
alert.headerText = "Header Text"
alert.contentText = "Content Text"
alert.showAndWait()

// 确认对话框
val confirm = Alert(Alert.AlertType.CONFIRMATION)
confirm.title = "Confirm"
confirm.contentText = "Are you sure?"
val result = confirm.showAndWait()
if (result.isPresent && result.get().buttonData == ButtonBar.ButtonData.OK_DONE) {
    println("Confirmed")
}

// 输入对话框
val input = Dialog<String>()
input.title = "Input"
input.headerText = "Enter your name"
input.contentText = "Name:"

val nameField = TextField()
input.dialogPane.content = nameField

val okButton = ButtonType("OK", ButtonBar.ButtonData.OK_DONE)
input.buttonTypes.addAll(okButton, ButtonType.CANCEL)

val result = input.showAndWait()
if (result.isPresent) {
    println("Name: ${nameField.text}")
}

// 自定义对话框
class ColorPickerDialog: Dialog<Color>() {
    init {
        title = "Pick a Color"
        headerText = "Select a color"

        val colorPicker = ColorPicker(Color.RED)
        dialogPane.content = colorPicker

        val okButton = ButtonType("OK", ButtonBar.ButtonData.OK_DONE)
        dialogPane.buttonTypes.addAll(okButton, ButtonType.CANCEL)

        setResultConverter { button ->
            if (button == okButton) colorPicker.value else null
        }
    }
}
```

### 14.11 实用示例

#### 计算器

```kotlin
class CalculatorApp: Application() {
    private val display = TextField("0").apply {
        isEditable = false
        promptText = "0"
        style = "-fx-font-size: 24px; -fx-alignment: CENTER_RIGHT;"
    }

    private var currentOperation: String? = null
    private var previousValue: Double? = null

    override fun start(stage: Stage) {
        val root = BorderPane()

        root.top = display
        root.center = createGrid()

        val scene = Scene(root, 320.0, 400.0)
        scene.stylesheets.add(javaClass.getResource("/calculator.css").toExternalForm())

        stage.title = "Calculator"
        stage.scene = scene
        stage.isResizable = false
        stage.show()
    }

    private fun createGrid(): GridPane {
        val grid = GridPane()
        grid.hgap = 10.0
        grid.vgap = 10.0

        val buttons = listOf(
            listOf("7", "8", "9", "/"),
            listOf("4", "5", "6", "*"),
            listOf("1", "2", "3", "-"),
            listOf("0", ".", "=", "+")
        )

        for (row in buttons.indices) {
            for (col in buttons[row].indices) {
                val btn = Button(buttons[row][col])
                btn.styleClass.add("calculator-btn")

                btn.onAction = EventHandler {
                    handleButtonPress(btn.text)
                }
                grid.add(btn, col, row)
            }
        }

        val clearBtn = Button("C")
        clearBtn.styleClass.add("calculator-btn")
        clearBtn.onAction = EventHandler { display.text = "0" }
        grid.add(clearBtn, 4, 0)

        return grid
    }

    private fun handleButtonPress(value: String) {
        when (value) {
            in "0".."9" -> {
                if (display.text == "0") display.text = value
                else display.text = display.text + value
            }
            "." -> {
                if (!display.text.contains(".")) display.text = display.text + "."
            }
            in listOf("+", "-", "*", "/") -> {
                currentOperation = value
                previousValue = display.text.toDouble()
                display.text = "0"
            }
            "=" -> {
                val currentValue = display.text.toDouble()
                val result = when (currentOperation) {
                    "+" -> previousValue!! + currentValue
                    "-" -> previousValue!! - currentValue
                    "*" -> previousValue!! * currentValue
                    "/" -> previousValue!! / currentValue
                    else -> currentValue
                }
                display.text = result.toString()
                currentOperation = null
                previousValue = null
            }
        }
    }
}
```

#### 简单绘图板

```kotlin
class DrawingApp: Application() {
    private val canvas = Canvas(600.0, 400.0)
    private val graphics = canvas.graphicsContext2D

    private var lastX = 0.0
    private var lastY = 0.0
    private var isDrawing = false

    override fun start(stage: Stage) {
        graphics.stroke = Color.BLACK
        graphics.lineWidth = 2.0

        canvas.setOnMousePressed { event ->
            isDrawing = true
            lastX = event.x
            lastY = event.y
        }

        canvas.setOnMouseDragged { event ->
            if (isDrawing) {
                graphics.stroke = Color.BLACK
                graphics.strokeLine(lastX, lastY, event.x, event.y)
                lastX = event.x
                lastY = event.y
            }
        }

        canvas.setOnMouseReleased { isDrawing = false }

        val toolbar = HBox(10.0).apply {
            padding = Insets(10.0)
            children.addAll(
                createColorButton(Color.RED, "Red"),
                createColorButton(Color.BLUE, "Blue"),
                createColorButton(Color.GREEN, "Green"),
                Button("Clear").apply {
                    setOnAction { graphics.clearRect(0.0, 0.0, 600.0, 400.0) }
                }
            )
        }

        val root = BorderPane().apply {
            center = canvas
            top = toolbar
        }

        val scene = Scene(root, 600.0, 480.0)
        stage.title = "Drawing App"
        stage.scene = scene
        stage.show()
    }

    private fun createColorButton(color: Color, name: String): Button {
        return Button(name).apply {
            style = "-fx-background-color: ${color.web}; -fx-text-fill: white;"
            setOnAction { graphics.stroke = color }
        }
    }
}
```

---

## 15. 代码调试

### 15.1 IntelliJ IDEA 调试

#### 15.1.1 调试配置

**运行/调试配置：**
1. 点击工具栏的下拉菜单 → `Edit Configurations`
2. 点击 `+` → 选择 `Kotlin` 或 `Application`
3. 配置主类和JVM参数

**JVM参数示例：**
```
-Xdebug -Xrunjdwp:transport=dt_socket,server=true,suspend=y,address=5005
```

#### 15.1.2 断点类型

```kotlin
// 行断点 - 在代码行上单击左侧
fun calculate() {
    val x = 10      // ← 断点
    val y = 20      // ← 断点
    val sum = x + y
}

// 条件断点 - 右键断点 → Breakpoint Properties
// 添加条件: x > 100
for (i in 1..1000) {
    processItem(i)  // ← 条件断点: i == 50
}

// 日志断点 - Log message to console
// ${"value = " + value}
```

#### 15.1.3 调试控制

| 按钮 | 快捷键 | 功能 |
|------|--------|------|
| F9 | Ctrl+F5 | 继续 (Resume) |
| F8 | Ctrl+F7 | 单步跳过 (Step Over) |
| Alt+F7 | Alt+F7 | 单步进入 (Step Into) |
| Shift+F8 | Shift+F7 | 单步跳出 (Step Out) |
| Alt+F9 | Alt+F9 | 运行到光标 (Run to Cursor) |
| F2 | F2 | 智能步入 (Smart Step Into) |

#### 15.1.4 观察变量

```kotlin
// 监视表达式
val data = listOf(1, 2, 3, 4, 5)
val filtered = data.filter { it > 2 }
val mapped = filtered.map { it * 2 }

// Watch expressions:
// filtered.size
// mapped.sum()
// data[0]

// 字符串模板调试
val name = "Alice"
val age = 25
println("Debug: name=$name, age=$age")  // 简单调试

// 使用 require
fun process(value: Int) {
    require(value > 0) { "Value must be positive, but was $value" }
    // ...
}

// 使用 check
fun getItem(index: Int): String {
    check(index in 0..list.size) { "Index: $index, size: ${list.size}" }
    return list[index]
}
```

### 15.2 日志调试

#### 15.2.1 简单打印

```kotlin
// println 调试
fun complexCalculation(a: Int, b: Int): Int {
    println("Input: a=$a, b=$b")
    val result = a * b + 10
    println("Result: $result")
    return result
}

// 使用格式化输出
val pi = 3.14159265359
printf("Pi = %.2f\n", pi)  // Pi = 3.14
format("Name: %s, Age: %d", "Alice", 25)
```

#### 15.2.2 分类日志

```kotlin
// 使用 print 和 printStackTrace
fun processData() {
    try {
        // ... 代码
    } catch (e: Exception) {
        println("Error in processData: ${e.message}")
        e.printStackTrace()
    }
}

// 分层调试输出
fun debugTree(depth: Int = 0) {
    val indent = "  ".repeat(depth)
    println("${indent}Processing...")

    // 递归调用
    if (depth < 3) {
        debugTree(depth + 1)
    }

    println("${indent}Done")
}
```

### 15.3 协程调试

#### 15.3.1 协程调试配置

```kotlin
import kotlinx.coroutines.*
import kotlin.coroutines.*

// 启用协程调试
fun main() {
    System.setProperty("kotlinx.coroutines.debug", "on")

    runBlocking {
        launch {
            delay(1000)
            println("Job 1 done")
        }

        launch {
            delay(2000)
            println("Job 2 done")
        }
    }
}

// 自定义 CoroutineContext
val debugContext = SupervisorJob() + Dispatchers.Default +
    CoroutineName("MainDispatcher")

fun debugScope() = coroutineScope {
    launch(debugContext + CoroutineName("worker-1")) {
        delay(1000)
        println("Worker 1 completed")
    }
}

// 获取协程信息
fun showCoroutineInfo() {
    val job = Job()
    val scope = CoroutineScope(debugContext + job)

    println("Job: ${job.parentJob}")
    println("Parent: ${job.parent}")
}
```

#### 15.3.2 协程调试技巧

```kotlin
// 调试协程延迟
suspend fun processWithDelays() {
    println("Step 1 started")
    delay(100)
    println("Step 1 completed")

    println("Step 2 started")
    delay(200)
    println("Step 2 completed")
}

// 使用 suspendCoroutine 捕获调用栈
import kotlin.coroutines.resume

fun <T> debugSuspend(block: suspend () -> T): suspend () -> T {
    return {
        println("Starting debug for: ${Thread.currentThread().stackTrace.size} frames")
        block()
    }
}

// 协程状态监控
class DebuggableScope : CoroutineScope {
    override val coroutineContext = SupervisorJob() + Dispatchers.Default

    fun <T> launchDebug(
        block: suspend CoroutineScope.() -> T
    ): Job {
        return launch {
            println("[COROUTINE] Started")
            try {
                val result = block()
                println("[COROUTINE] Completed with: $result")
            } catch (e: Exception) {
                println("[COROUTINE] Failed: ${e.message}")
                e.printStackTrace()
            }
        }
    }
}
```

#### 15.3.3 Flow 调试

```kotlin
import kotlinx.coroutines.flow.*

// 使用 tap 操作符调试
flow {
    emit(1)
    emit(2)
    emit(3)
}.transform { value ->
    println("Emitted: $value")
    emit(value * 2)
}.collect {
    println("Collected: $it")
}

// 使用 onEach 调试
val debugFlow = flow {
    for (i in 1..10) {
        emit(i)
    }
}.onEach { value ->
    println("[Debug] Value: $value")
}.flowOn(Dispatchers.Default)

// 使用 also 调试
val numbers = flowOf(1, 2, 3, 4, 5)
    .also { println("Flow created") }
    .map { it * 2 }
    .also { println("After map") }
    .collect { println(it) }

// フローステートデバッグ
fun debugFlow(name: String) = flow {
    println("[$name] Emission started")
    emit(name.length)
    println("[$name] Emission completed")
}

// 收集时的异常处理
flow {
    emit(1)
    emit(2)
    throw RuntimeException("Error in flow")
}.catch { e ->
    println("Caught exception: ${e.message}")
}.collect { println(it) }
```

### 15.4 单元测试调试

#### 15.4.1 KotlinTest / JUnit 5 配置

```kotlin
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.*

class CalculatorTest : FunSpec({
    test("addition should work") {
        val result = Calculator().add(2, 3)
        result shouldBe 5
    }

    test("division by zero should throw") {
        intercept<ArithmeticException> {
            Calculator().divide(10, 0)
        }
    }
})

// JUnit 5
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class MathTest {
    @Test
    fun testMathOperations() {
        val a = 10
        val b = 5
        assertEquals(15, a + b)
        assertEquals(5, a - b)
        assertEquals(50, a * b)
        assertEquals(2, a / b)
    }

    @Test
    fun `test with description`() {
        val result = calculate()
        assertTrue(result > 0)
        assertNotNull(result)
    }
}
```

#### 15.4.2 测试调试技巧

```kotlin
// 使用 assertWithMessage
fun testComplicatedCalculation() {
    val result = complexFunction()
    assert(result > 0) { "Result should be positive, but was $result" }
    assert(result < 1000) { "Result should be less than 1000, but was $result" }
}

// 测试异常
fun testException() {
    val exception = assertThrows<IllegalArgumentException> {
        validateAge(-1)
    }
    assertEquals("Age cannot be negative", exception.message)
}

// 使用 tempdir (KotlinTest)
import io.kotest.core.tempdir

class FileTest : FunSpec({
    test("write to temp file") {
        val dir = tempdir()
        val file = dir.resolve("test.txt")
        file.writeText("Hello")
        file.exists() shouldBe true
    }
})

// 本地测试配置
fun main() {
    val config = object : AbstractProjectSpec() {
        override fun isolationMode() = IsolationMode.InstancePerLeaf
    }
    io.kotest.core.config.Configuration.registerProjectConfiguration(config)
}
```

#### 15.4.3 测试覆盖

```kotlin
// 测试覆盖率配置
// Run → Edit Configurations →.coverage

// 测试所有分支
data class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error<T>(val message: String) : Result<T>()
}

fun handleResult(result: Result<String>) = when (result) {
    is Result.Success -> "Success: ${result.data}"
    is Result.Error -> "Error: ${result.message}"
}

// 测试
@Test
fun testSuccessResult() {
    val result = Result.Success("Hello")
    val output = handleResult(result)
    assertEquals("Success: Hello", output)
}

@Test
fun testErrorResult() {
    val result = Result.Error("Something went wrong")
    val output = handleResult(result)
    assertEquals("Error: Something went wrong", output)
}
```

### 15.5 性能调试

#### 15.5.1 微基准测试

```kotlin
import java.time.Duration
import java.time.Instant

// 简单性能测试
fun measureTimeMillis(block: () -> Unit): Long {
    val start = System.currentTimeMillis()
    block()
    return System.currentTimeMillis() - start
}

fun measureTime(block: () -> Unit): Duration {
    val start = Instant.now()
    block()
    return Duration.between(start, Instant.now())
}

// 使用示例
fun testPerformance() {
    val list = (1..10000).toList()

    val mapTime = measureTime { list.map { it * 2 } }
    val forEachTime = measureTime {
        val result = mutableListOf<Int>()
        for (i in list) {
            result.add(i * 2)
        }
    }

    println("Map: ${mapTime.toMillis()}ms")
    println("ForEach: ${forEachTime.toMillis()}ms")
}

// 性能测试工具类
object PerformanceTest {
    fun run(
        name: String,
        iterations: Int = 1000,
        block: () -> Unit
    ): Long {
        var total = 0L
        repeat(iterations) {
            val start = System.nanoTime()
            block()
            total += System.nanoTime() - start
        }
        val avg = total / iterations
        println("$name: ${avg}ns (avg)")
        return avg
    }
}

// 使用
fun performanceTest() {
    PerformanceTest.run("List map", 1000) {
        (1..100).toList().map { it * 2 }
    }
    PerformanceTest.run("For loop", 1000) {
        val result = mutableListOf<Int>()
        for (i in 1..100) {
            result.add(i * 2)
        }
    }
}
```

#### 15.5.2 内存分析

```kotlin
// 获取内存使用情况
fun printMemoryInfo() {
    val runtime = Runtime.getRuntime()
    val usedMemory = runtime.totalMemory() - runtime.freeMemory()
    val maxMemory = runtime.maxMemory()

    println("Used Memory: ${usedMemory / 1024 / 1024}MB")
    println("Max Memory: ${maxMemory / 1024 / 1024}MB")
    println("Free Memory: ${runtime.freeMemory() / 1024 / 1024}MB")
}

// 对象分配分析
fun analyzeObjectAllocation() {
    printMemoryInfo()

    val largeList = mutableListOf<List<Int>>()
    repeat(1000) {
        largeList.add((1..1000).toList())
    }

    printMemoryInfo()
}

// 使用 finalize 诊断泄露
class LeakedObject {
    override fun finalize() {
        println("LeakedObject was garbage collected")
    }
}
```

### 15.6 常见调试场景

#### 15.6.1 空指针调试

```kotlin
// Stacktrace 分析
/*
Exception in thread "main" java.lang.NullPointerException
    at StringKt.main(string.kt:10)
    at StringKt.main(string.kt:1)
*/

// 定位空指针
data class User(val name: String, val address: Address?)
data class Address(val city: String)

fun printUserCity(user: User?) {
    // 可能的空指针
    // println(user!!.address!!.city)

    // 安全调用
    user?.address?.city?.let { println(it) }

    // 使用 require 或 check
    fun processUser(user: User?) {
        val validUser = user ?: throw IllegalArgumentException("User cannot be null")
        val city = validUser.address?.city
            ?: throw IllegalStateException("Address city is missing")
        println(city)
    }
}
```

#### 15.6.2 协程异常调试

```kotlin
import kotlinx.coroutines.*

// 全局异常处理器
val handler = CoroutineExceptionHandler { context, exception ->
    println("GlobalExceptionHandler: $exception")
    println("Context: $context")
}

fun main() = runBlocking {
    // 方式1: 使用 CoroutineExceptionHandler
    val job = launch(handler) {
        throw RuntimeException("Test exception")
    }

    // 方式2: 使用 coroutineScope 捕获
    try {
        coroutineScope {
            launch {
                delay(100)
                throw IllegalStateException("Scope exception")
            }
        }
    } catch (e: Exception) {
        println("Caught in scope: $e")
    }

    // 方式3: 使用 async + await
    val deferred = async(handler) {
        delay(100)
        throw ArithmeticException("Division by zero")
    }

    try {
        deferred.await()
    } catch (e: Exception) {
        println("Async exception: ${e.message}")
    }
}

// 协程调试工具函数
fun <T> safeLaunch(
    scope: CoroutineScope,
    block: suspend () -> T
): Job {
    return scope.launch {
        try {
            block()
        } catch (e: Exception) {
            println("Launch failed: ${e.message}")
            e.printStackTrace()
        }
    }
}
```

#### 15.6.3 调试技巧总结

```kotlin
// 使用PEEK操作符
fun debugChain() {
    listOf(1, 2, 3, 4, 5)
        .map { it * 2 }
        .also { println("After map: $it") }
        .filter { it > 5 }
        .also { println("After filter: $it") }
        .forEach { println("Item: $it") }
}

// 在 when 中调试
fun debugWhen(value: Any) = when (value) {
    is String -> {
        println("Debug: String with length ${value.length}")
        value.uppercase()
    }
    is Int -> {
        println("Debug: Int value $value")
        value * 2
    }
    else -> {
        println("Debug: Unknown type ${value.javaClass}")
        value.toString()
    }
}

// 使用反射调试
fun debugProperties(obj: Any) {
    println("Debugging properties of ${obj.javaClass.simpleName}")
    obj.javaClass.declaredFields.forEach { field ->
        field.isAccessible = true
        val value = field.get(obj)
        println("  ${field.name} = $value")
    }
}

// 使用 spy (模拟测试)
fun debugWithSpy() {
    val list = mutableListOf<String>()

    // 观察变化
    val observingList = object : MutableList<String> by list {
        override fun add(element: String): Boolean {
            println("Adding: $element")
            return super.add(element)
        }

        override fun remove(element: String): Boolean {
            println(" removing: $element")
            return super.remove(element)
        }
    }
}
```

---

## 16. 多任务编程

### 16.1 线程基础

#### 16.1.1 创建线程

```kotlin
import java.lang.Thread

// 方式1: 继承 Thread 类
class WorkerThread : Thread() {
    override fun run() {
        println("Thread running: ${Thread.currentThread().name}")
    }
}

val thread1 = WorkerThread()
thread1.start()

// 方式2: 使用 Thread 构造函数
val thread2 = Thread {
    println("Hello from thread: ${Thread.currentThread().name}")
}
thread2.start()

// 方式3: kotlin.concurrent.thread
import kotlin.concurrent.thread

val thread3 = thread(start = true) {
    println("Thread from kotlin.concurrent")
}

val namedThread = thread(name = "BackgroundWorker", isDaemon = true) {
    // 后台工作
}
```

#### 16.1.2 线程同步

```kotlin
// synchronized 关键字
class Counter {
    private var count = 0

    fun increment() {
        synchronized(this) {
            count++
        }
    }

    @Synchronized
    fun increment2() {
        count++
    }
}

// Lock 接口
import java.util.concurrent.locks.ReentrantLock

class LockCounter {
    private var count = 0
    private val lock = ReentrantLock()

    fun increment() {
        lock.lock()
        try {
            count++
        } finally {
            lock.unlock()
        }
    }
}
```

#### 16.1.3 线程通信

```kotlin
class Buffer {
    private val queue = mutableListOf<Int>()
    private val lock = Any()

    fun produce(item: Int) {
        synchronized(lock) {
            queue.add(item)
            lock.notifyAll()
        }
    }

    fun consume(): Int {
        synchronized(lock) {
            while (queue.isEmpty()) {
                lock.wait()
            }
            return queue.removeAt(0)
        }
    }
}
```

### 16.2 Executor 框架

```kotlin
import java.util.concurrent.*

// 创建线程池
val executor = Executors.newFixedThreadPool(4)
val cachedExecutor = Executors.newCachedThreadPool()

// 提交任务
val future: Future<Int> = executor.submit {
    Thread.sleep(1000)
    42
}

// 批量执行
val tasks = listOf(
    Callable { "Task 1" },
    Callable { "Task 2" }
)
val results: List<Future<String>> = executor.invokeAll(tasks)

// 关闭线程池
executor.shutdown()
executor.awaitTermination(5, TimeUnit.SECONDS)
```

### 16.3 并发集合

```kotlin
import java.util.concurrent.*

// 并发队列
val boundedQueue = ArrayBlockingQueue<String>(3)
val unboundedQueue = LinkedBlockingQueue<String>()
val clq = ConcurrentLinkedQueue<Int>()

// 并发集合
val concurrentSet = ConcurrentHashMap.newKeySet<String>()
val skipListMap = ConcurrentSkipListMap<String, Int>()
```

### 16.4 同步工具类

```kotlin
import java.util.concurrent.*

// CountDownLatch
val latch = CountDownLatch(3)
repeat(3) {
    thread {
        latch.countDown()
    }
}
latch.await()

// CyclicBarrier
val barrier = CyclicBarrier(3)
repeat(3) { thread { barrier.await() } }

// Semaphore
val semaphore = Semaphore(2)
semaphore.acquire()
semaphore.release()
```

### 16.5 原子变量

```kotlin
import java.util.concurrent.atomic.*

val atomicInt = AtomicInteger(0)
atomicInt.incrementAndGet()
atomicInt.compareAndSet(1, 10)

val atomicRef = AtomicReference<String>()
val atomicBool = AtomicBoolean(false)

val atomicArray = AtomicIntegerArray(intArrayOf(1, 2, 3))
```

### 16.6 并发模式

```kotlin
// 生产者-消费者
class ProducerConsumer {
    private val queue = ArrayBlockingQueue<Int>(10)

    fun produce() {
        for (i in 1..100) {
            queue.put(i)
            println("Produced: $i")
        }
    }

    fun consume() {
        repeat(100) {
            val item = queue.take()
            println("Consumed: $item")
        }
    }
}

// 读写锁
import java.util.concurrent.locks.ReentrantReadWriteLock

class ReaderWriter {
    private var data = mutableMapOf<String, String>()
    private val lock = ReentrantReadWriteLock()

    fun write(key: String, value: String) {
        lock.writeLock().lock()
        try { data[key] = value } finally { lock.writeLock().unlock() }
    }

    fun read(key: String): String? {
        lock.readLock().lock()
        try { return data[key] } finally { lock.readLock().unlock() }
    }
}
```

---

## 17. Kotlin与Java互操作

Kotlin 与 Java 具有 100% 的互操作性，这意味着 Kotlin 代码可以直接调用 Java 代码，反之亦然。

### 17.1 Kotlin调用Java

#### 17.1.1 基本调用

```kotlin
// Java 类
public class JavaClass {
    public String getName() {
        return "Java";
    }
    
    public static int add(int a, int b) {
        return a + b;
    }
}

// Kotlin 调用
val javaObj = JavaClass()
println(javaObj.name)  // 使用属性语法访问 getter

// 调用静态方法
val sum = JavaClass.add(10, 5)
```

#### 17.1.2 Getter与Setter

Kotlin 自动将 Java 的 getter/setter 转换为属性：

```kotlin
// Java 类
public class Person {
    private String name;
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public boolean isActive() { return true; }
}

// Kotlin 使用
val person = Person()
person.name = "Alice"  // 调用 setName
println(person.name)   // 调用 getName
println(person.active) // 调用 isActive (is 前缀转为属性)
```

#### 17.1.3 空安全与平台类型

Java 中的引用可能为 null，Kotlin 将其视为**平台类型**：

```kotlin
// Java 类
public class JavaUtil {
    public String getNullable() { return null; }
    public String getNonNull() { return "Hello"; }
}

// Kotlin 使用
val util = JavaUtil()

// 平台类型，需要自己判断是否为空
val nullable: String? = util.nullable  // 显式声明可空
val nonNull: String = util.nonNull     // 假设非空

// 安全调用
val length = util.nullable?.length
```

#### 17.1.4 调用Java集合

```kotlin
import java.util.ArrayList
import java.util.HashMap

// 使用 Java 集合
val list = ArrayList<String>()
list.add("A")
list.add("B")

val map = HashMap<String, Int>()
map["one"] = 1
map["two"] = 2

// Java 集合与 Kotlin 集合转换
val kotlinList = list.toList()  // 转为 Kotlin 只读列表
val mutableKotlinList = list.toMutableList()

// 注意：Java 集合在 Kotlin 中是可变的
list.add("C")  // 允许修改
```

### 17.2 Java调用Kotlin

#### 17.2.1 调用Kotlin类

```kotlin
// Kotlin 类
class KotlinClass(val name: String) {
    fun greet(): String = "Hello, $name"
    
    companion object {
        const val VERSION = "1.0"
        
        @JvmStatic
        fun create(name: String) = KotlinClass(name)
    }
}
```

```java
// Java 调用
KotlinClass obj = new KotlinClass("World");
System.out.println(obj.getName());  // 属性生成 getter
System.out.println(obj.greet());

// 访问伴生对象
System.out.println(KotlinClass.VERSION);
KotlinClass.Companion.create("Test");  // 默认方式
KotlinClass.create("Test");            // 使用 @JvmStatic
```

#### 17.2.2 @JvmStatic 与 @JvmField

```kotlin
class MyClass {
    companion object {
        const val CONSTANT = "constant"  // 真正的常量
        
        @JvmField
        val field = "field"  // 暴露为静态字段
        
        @JvmStatic
        fun staticMethod() = "static"  // 暴露为静态方法
        
        fun normalMethod() = "normal"  // 需要通过 Companion 调用
    }
}
```

```java
// Java 调用
System.out.println(MyClass.CONSTANT);     // 直接访问
System.out.println(MyClass.field);        // 直接访问
System.out.println(MyClass.staticMethod()); // 直接调用
System.out.println(MyClass.Companion.normalMethod()); // 通过 Companion
```

#### 17.2.3 @JvmName

为 Kotlin 函数指定 Java 调用时的名称：

```kotlin
// Kotlin 文件: Utils.kt

// 顶层函数
@JvmName("joinToStringCustom")
fun join(list: List<String>, separator: String): String {
    return list.joinToString(separator)
}

// 扩展函数
@JvmName("capitalizeFirst")
fun String.capitalizeFirstChar(): String {
    return replaceFirstChar { it.uppercase() }
}
```

```java
// Java 调用
UtilsKt.joinToStringCustom(list, ", ");
UtilsKt.capitalizeFirstChar("hello");
```

### 17.3 类型映射

| Kotlin 类型 | Java 类型 |
|-------------|-----------|
| kotlin.Int | int / Integer |
| kotlin.Long | long / Long |
| kotlin.Double | double / Double |
| kotlin.Boolean | boolean / Boolean |
| kotlin.String | java.lang.String |
| kotlin.collections.List | java.util.List |
| kotlin.collections.Map | java.util.Map |
| kotlin.Unit | void |
| kotlin.Any | java.lang.Object |

### 17.4 SAM转换

Kotlin 支持自动将 Lambda 转换为 Java 的 SAM（Single Abstract Method）接口：

```kotlin
// Java 接口
public interface ClickListener {
    void onClick(String id);
}

// Java 类
public class Button {
    public void setClickListener(ClickListener listener) { ... }
}
```

```kotlin
// Kotlin 使用 SAM 转换
val button = Button()

// 方式1：Lambda（自动 SAM 转换）
button.setClickListener { id ->
    println("Clicked: $id")
}

// 方式2：显式创建对象
button.setClickListener(object : ClickListener {
    override fun onClick(id: String) {
        println("Clicked: $id")
    }
})
```

### 17.5 可变参数

```kotlin
// Java 方法
public class JavaUtil {
    public static void printAll(String... args) {
        for (String arg : args) {
            System.out.println(arg);
        }
    }
}
```

```kotlin
// Kotlin 调用
JavaUtil.printAll("A", "B", "C")  // 直接传递多个参数

// 传递数组
val arr = arrayOf("X", "Y", "Z")
JavaUtil.printAll(*arr)  // 使用展开运算符
```

### 17.6 异常处理

Kotlin 不检查受检异常，但调用 Java 时需要处理：

```kotlin
// Java 方法抛出 IOException
public String readFile(String path) throws IOException {
    // ...
}
```

```kotlin
// Kotlin 调用 - 可以不处理异常
val content = readFile("/path/to/file")

// 或显式处理
try {
    val content = readFile("/path/to/file")
} catch (e: IOException) {
    println("Error: ${e.message}")
}
```

### 17.7 反射

```kotlin
// 获取 Java Class 对象
val javaClass = String::class.java
val javaClass2 = "Hello".javaClass

// 调用 Java 反射
val method = javaClass.getMethod("substring", Int::class.java, Int::class.java)
val result = method.invoke("Hello", 1, 3)  // "el"
```

### 17.8 互操作最佳实践

1. **空安全**：调用 Java 代码时始终考虑空安全
2. **使用注解**：善用 `@JvmStatic`、`@JvmField`、`@JvmName` 等
3. **集合转换**：注意 Java 集合与 Kotlin 集合的差异
4. **命名冲突**：使用反引号处理 Kotlin 关键字与 Java 标识符冲突

```kotlin
// Java 方法名为 Kotlin 关键字
val obj = JavaClass()
obj.`is`()  // 方法名为 "is"
obj.`fun`() // 方法名为 "fun"
```

---

## 18. Kotlin/JS - 编译成JavaScript

Kotlin 可以编译成 JavaScript，允许你在浏览器或 Node.js 环境中使用 Kotlin 开发前端应用。

### 18.1 环境配置

#### 18.1.1 Gradle 配置

```kotlin
plugins {
    kotlin("js") version "1.9.24"
}

kotlin {
    js {
        browser {
            commonWebpackConfig {
                cssSupport {
                    enabled = true
                }
            }
        }
        binaries.executable()
    }
}

dependencies {
    implementation(kotlin("stdlib-js"))
    // React 依赖（可选）
    implementation("org.jetbrains.kotlin-wrappers:kotlin-react:18.2.0-pre.610")
    implementation("org.jetbrains.kotlin-wrappers:kotlin-react-dom:18.2.0-pre.610")
}
```

#### 18.1.2 npm 依赖配置

```kotlin
kotlin {
    js {
        sourceSets {
            val main by getting {
                dependencies {
                    implementation(npm("react", "18.2.0"))
                    implementation(npm("react-dom", "18.2.0"))
                }
            }
        }
    }
}
```

### 18.2 基础项目结构

```
src/
├── main/
│   ├── kotlin/
│   │   └── Main.kt
│   └── resources/
│       └── index.html
└── test/
    └── kotlin/
```

#### index.html

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Kotlin/JS App</title>
</head>
<body>
    <div id="root"></div>
    <script src="kotlin-js-app.js"></script>
</body>
</html>
```

### 18.3 JavaScript 互操作

#### 18.3.1 Kotlin 调用 JavaScript

```kotlin
import kotlin.js.Json

// 动态类型
external fun console.log(message: Any?)

external interface Window {
    val innerWidth: Int
    fun alert(message: String)
}

external val window: Window

fun main() {
    console.log("Hello from Kotlin!")
    window.alert("Kotlin says hello!")
}
```

#### 18.3.2 @JsName 注解

```kotlin
@JsName("doSomething")
fun myFunction() {
    println("Called from JavaScript")
}

// JavaScript 中调用
// doSomething();
```

#### 18.3.3 使用 dynamic 类型

```kotlin
val json: dynamic = JSON.parse("""{"name": "Alice", "age": 25}""")

// 动态访问属性
println(json.name)  // Alice
println(json.age)   // 25

// 动态调用方法
json.sayHello()
```

### 18.4 DOM 操作

#### 18.4.1 基本 DOM 操作

```kotlin
import org.w3c.dom.*
import kotlinx.browser.document
import kotlinx.browser.window

fun main() {
    // 创建元素
    val div = document.createElement("div") as HTMLDivElement
    div.textContent = "Hello Kotlin/JS!"
    div.style.color = "blue"
    
    // 添加到页面
    document.body?.appendChild(div)
    
    // 事件监听
    val button = document.createElement("button") as HTMLButtonElement
    button.textContent = "Click me"
    button.addEventListener("click", {
        window.alert("Button clicked!")
    })
    
    document.body?.appendChild(button)
}
```

#### 18.4.2 获取和修改元素

```kotlin
// 通过 ID 获取
val element = document.getElementById("my-id") as? HTMLElement

// 通过类名获取
val elements = document.getElementsByClassName("my-class")

// 修改属性
element?.style?.backgroundColor = "#f0f0f0"
element?.setAttribute("data-value", "123")

// 修改内容
element?.innerHTML = "<b>Bold text</b>"
element?.textContent = "Plain text"
```

### 18.5 React 开发

#### 18.5.1 简单组件

```kotlin
import react.*
import react.dom.html.*
import react.dom.html.ReactHTML.*
import web.cssom.*

val app = FC {
    var count by useState(0)
    
    div {
        h1 {
            +"Counter: $count"
        }
        button {
            onClick = { count++ }
            +"Increment"
        }
    }
}

fun main() {
    val root = createRoot(document.getElementById("root")!!)
    root.render(app.create())
}
```

#### 18.5.2 Props 和 State

```kotlin
external interface User {
    var name: String
    var age: Int
}

val userCard = FC<User> { props ->
    div {
        style {
            border = "1px solid #ccc"
            padding = 16.px
            margin = 8.px
        }
        h3 { +props.name }
        p { +"Age: ${props.age}" }
    }
}

val userList = FC {
    val users = listOf(
        jsObject<User> { name = "Alice"; age = 25 },
        jsObject<User> { name = "Bob"; age = 30 }
    )
    
    div {
        users.forEach { user ->
            userCard {
                name = user.name
                age = user.age
            }
        }
    }
}
```

### 18.6 异步操作

#### 18.6.1 Promise 支持

```kotlin
import kotlinx.coroutines.*
import kotlin.js.Promise

// Kotlin 协程与 JS Promise 互操作
suspend fun fetchUserData(): User {
    return Promise { resolve, reject ->
        // 模拟异步请求
        setTimeout({
            resolve(jsObject<User> {
                name = "Alice"
                age = 25
            })
        }, 1000)
    }.await()
}

// 使用 async
fun main() = runBlocking {
    val user = fetchUserData()
    console.log(user)
}
```

#### 18.6.2 Fetch API

```kotlin
import kotlinx.coroutines.await
import kotlin.js.json

suspend fun fetchJson(url: String): dynamic {
    val response = window.fetch(url).await()
    return response.json().await()
}

suspend fun postData(url: String, data: dynamic): dynamic {
    val response = window.fetch(url, json(
        "method" to "POST",
        "headers" to json(
            "Content-Type" to "application/json"
        ),
        "body" to JSON.stringify(data)
    )).await()
    return response.json().await()
}
```

### 18.7 Node.js 开发

#### 18.7.1 Node.js 配置

```kotlin
plugins {
    kotlin("js") version "1.9.24"
}

kotlin {
    js {
        nodejs {
            binaries.executable()
        }
    }
}

dependencies {
    implementation(kotlin("stdlib-js"))
}
```

#### 18.7.2 简单的 Node.js 应用

```kotlin
import node.process.process
import node.fs.*

external fun require(module: String): dynamic
val fs = require("fs")

fun main() {
    console.log("Hello from Node.js!")
    
    // 读取文件
    val content = fs.readFileSync("input.txt", "utf8") as String
    console.log("File content: $content")
    
    // 写入文件
    fs.writeFileSync("output.txt", "Hello from Kotlin!")
    console.log("File written")
    
    // 命令行参数
    console.log("Arguments: ${process.argv}")
}
```

### 18.8 类型安全的外部声明

#### 18.8.1 外部接口

```kotlin
// 声明外部 JavaScript 库的类型
external interface JQuery {
    fun click(handler: (dynamic) -> Unit): JQuery
    fun text(): String
    fun text(value: String): JQuery
}

external fun jQuery(selector: String): JQuery
external val `$`: (String) -> JQuery

// 使用
fun main() {
    `$`("#button").click {
        console.log("Button clicked!")
    }
}
```

#### 18.8.2 使用 Dukat 生成声明

Dukat 可以从 TypeScript 声明文件（.d.ts）生成 Kotlin 外部声明：

```bash
# 安装 Dukat
npm install -g dukat

# 生成声明
dukat react.d.ts
```

### 18.9 构建和部署

#### 18.9.1 Gradle 任务

```kotlin
tasks {
    // 开发构建
    named("browserDevelopmentWebpack") {
        doLast {
            println("Development build complete!")
        }
    }
    
    // 生产构建
    named("browserProductionWebpack") {
        doLast {
            println("Production build complete!")
        }
    }
    
    // 开发服务器
    named("browserDevelopmentRun") {
        doFirst {
            println("Starting dev server at http://localhost:8080")
        }
    }
}
```

#### 18.9.2 常用命令

```bash
# 开发构建
./gradlew browserDevelopmentWebpack

# 生产构建
./gradlew browserProductionWebpack

# 启动开发服务器
./gradlew browserDevelopmentRun --continuous

# 运行 Node.js 应用
./gradlew nodeRun
```

### 18.10 最佳实践

1. **使用类型安全**：尽量避免使用 `dynamic`，优先使用外部接口
2. **代码分割**：使用 `@JsModule` 和 `@JsNonModule` 管理模块
3. **协程优先**：在 Kotlin/JS 中优先使用协程而非 Promise
4. **类型声明**：为 JavaScript 库创建类型安全的声明
5. **测试**：使用 Kotlin/JS 测试框架测试代码

```kotlin
// 代码分割示例
@JsModule("lodash")
external fun capitalize(str: String): String

@JsNonModule
@JsName("globalFunction")
external fun globalFunction(): Unit
```

---

## 19. Kotlin 标准库参考

### 19.1 公共库 (kotlin.collections)

#### 19.1.1 List 操作

```kotlin
// 创建列表
val list = listOf(1, 2, 3, 4, 5)
val mutableList = mutableListOf(1, 2, 3)

// 访问元素
list[0]           // 第一个元素
list.first()      // 首元素
list.last()       // 尾元素
list.getOrNull(10) // 安全访问

// 查询
list.contains(3)
list.indexOf(3)
list.lastIndexOf(3)
list.isEmpty()
list.isNotEmpty()
list.size

// 转换
list.map { it * 2 }           // 映射
list.filter { it > 2 }        // 过滤
list.flatMap { listOf(it, it) } // 平铺
list.distinct()               // 去重
list.take(3)                  // 取前N个
list.drop(2)                  // 跳过前N个
list.takeWhile { it < 4 }     // 连续满足条件
list.dropWhile { it < 4 }     // 跳过连续满足条件
list.partition { it % 2 == 0 } // 分区

// 归约
list.sum()                    // 求和
list.average()                // 平均值
list.minOrNull()              // 最小值
list.maxOrNull()              // 最大值
list.reduce { acc, v -> acc + v }  // 归约
list.fold(0) { acc, v -> acc + v } // 带初始值归约

// 排序
list.sorted()                 // 升序
list.sortedDescending()       // 降序
list.sortWith(compareBy { it }) // 自定义比较
list.shuffled()               // 随机打乱

// 聚合
list.groupBy { if (it % 2 == 0) "even" else "odd" }
list.associateBy { "key_$it" }
list.foldIndexed(0) { i, acc, v -> acc + i + v }
```

#### 19.1.2 Set 操作

```kotlin
val set = setOf(1, 2, 3, 4, 5)

// 基本操作
set.contains(3)
set.isEmpty()
set.size

// 集合运算
set.union(setOf(4, 5, 6))     // 并集
set.intersect(setOf(3, 4, 5)) // 交集
set.minus(setOf(1, 2))        // 差集
set.subtract(setOf(1, 2))     // 减法

// 转换
set.map { it * 2 }
set.filter { it > 2 }
set.associate { it to it * 2 }
```

#### 19.1.3 Map 操作

```kotlin
val map = mapOf("a" to 1, "b" to 2, "c" to 3)

// 访问
map["a"]
map.getOrDefault("d", 0)
map.contains("a")
map.containsKey("a")
map.containsValue(1)
map.isEmpty()
map.size

// 遍历
map.forEach { (k, v) -> println("$k: $v") }
map.keys
map.values

// 转换
map.mapKeys { (k, v) -> k.uppercase() }
map.mapValues { (k, v) -> v * 2 }
map.filter { (k, v) -> v > 1 }
map.toMap()

// 合并
map + ("d" to 4)
map.minus("a")
map.merge("a", 10) { old, new -> old + new }
```

### 19.2 序列 (kotlin.sequences)

```kotlin
// 创建序列
val seq = listOf(1, 2, 3, 4, 5).asSequence()

// 操作 (延迟执行)
val result = seq
    .map { it * 2 }
    .filter { it > 5 }
    .toList()

// 序列生成
val infinite = generateSequence(1) { it + 1 }
val fibonacci = generateSequence(1 to 1) { (a, b) -> b to a + b }

// 常用函数
seq.any { it > 3 }
seq.all { it > 0 }
seq.none { it < 0 }
seq.count { it > 2 }
seq.firstOrNull { it > 2 }
seq.find { it % 2 == 0 }
seq.elementAtOrNull(10)
```

### 19.3 字符串 (kotlin.text)

#### 19.3.1 字符串函数

```kotlin
val str = "Hello Kotlin"

// 基本操作
str.length
str.isEmpty()
str.isNotEmpty()
str.isBlank()
str.isNotEmpty()

// 比较
str.equals("Hello Kotlin", ignoreCase = true)
str.startsWith("Hello")
str.endsWith("Kotlin")
str.contains("Kotlin")

// 搜索
str.indexOf("K")
str.lastIndexOf("o")
str.indexOfFirst { it == 'K' }
str.indexOfLast { it == 'o' }

// 子串
str.substring(0, 5)
str.substringAfter(" ")
str.substringBefore(" ")
str.substringAfterLast(" ")
str.substringBeforeLast(" ")
```

#### 19.3.2 字符串转换

```kotlin
val str = "hello kotlin"

// 大小写
str.uppercase()
str.lowercase()
str.capitalize()
str.decapitalize()

// 格式化
"Hello %s".format("World")
"Pi: %.2f".format(Math.PI)

// 分割
"a,b,c".split(",")
"hello world".split(" ")
"one,two,three".split(",", limit = 2)

// 连接
listOf("a", "b", "c").joinToString()
listOf("a", "b", "c").joinToString(", ")
listOf("a", "b", "c").joinToString(prefix = "[", suffix = "]")

// 去除
"  hello  ".trim()
"  hello  ".trimStart()
"  hello  ".trimEnd()
"---hello---".trim('-')
```

#### 19.3.3 正则表达式

```kotlin
import kotlin.text.Regex

// 基本使用
val regex = Regex("\\d+")
regex.matches("123")
regex.find("abc123def")
regex.findAll("abc123def456")

// 替换
"abc123def".replace(Regex("\\d+"), "#")
"hello world".replace("l", "L", ignoreCase = true)

// 提取
val match = Regex("(\\d+)-(\\d+)-(\\d+)").find("2024-01-15")
val year = match?.groupValues[1]
```

### 19.4 数值 (kotlin)

#### 19.4.1 数值转换

```kotlin
val num: Int = 42

// 转换
num.toLong()
num.toFloat()
num.toDouble()
num.toByte()
num.toShort()
num.toChar()

// 辅助函数
num.inc()       // ++
num.dec()       // --
num.unaryMinus()
num.unaryPlus()
```

#### 19.4.2 数值范围

```kotlin
// 创建范围
val range = 1..10
val halfOpen = 1 until 10
val stepped = 1..10 step 2

// 检查
range.contains(5)
5 in range

// 范围操作
range.start
range.endInclusive
range.step

// 迭代
for (i in 1..5) { println(i) }
for (i in 5 downTo 1) { println(i) }
for (i in 1..10 step 2) { println(i) }
```

#### 19.4.3 数学函数

```kotlin
import kotlin.math.*

// 基本函数
abs(-5)
max(10, 20)
min(10, 20)
sign(-5)  // -1, 0, or 1

// 三角函数
sin(Math.PI / 2)
cos(0.0)
tan(Math.PI / 4)
asin(1.0)

// 指数和对数
exp(1.0)
log(Math.E)
log10(100.0)
pow(2.0, 3.0)
sqrt(16.0)

// 四舍五入
round(3.14)    // 3.0
round(3.5)     // 4.0
floor(3.7)     // 3.0
ceil(3.2)      // 4.0
trunc(3.7)     // 3.0

// 随机
val random = Random()
random.nextInt()
random.nextInt(10)        // 0-9
random.nextDouble()
random.nextBoolean()
```

### 19.5 延迟初始化 (kotlin.properties)

```kotlin
import kotlin.properties.Delegates

// lazy 延迟初始化
val lazyValue: String by lazy {
    println("Computed!")
    "Hello"
}

// 懒加载模式
val lazyWithLock = lazy(LazyThreadSafetyMode.SYNCHRONIZED) {
    expensiveComputation()
}

val lazyWithPermission = lazy(LazyThreadSafetyMode.PUBLICATION) {
    expensiveComputation()
}

// observable
var observableValue: String by Delegates.observable("default") {
    prop, old, new ->
    println("$old -> $new")
}

// vetoable
var vetoableValue: Int by Delegates.vetoable(0) {
    prop, old, new ->
    new >= 0
}

// notNull
var notNullValue: String by Delegates.notNull()

// 自定义委托
class EnumProperty<E : Enum<E>>(private val enumClass: Class<E>) {
    private var value: E? = null

    operator fun getValue(thisRef: Any?, property: KProperty<*>): E {
        return value ?: error("Value not initialized")
    }

    operator fun setValue(thisRef: Any?, property: KProperty<*>, value: E) {
        this.value = value
    }
}
```

### 19.6 应用/运行 (kotlin.apply)

```kotlin
data class Person(var name: String = "", var age: Int = 0)

// apply
val person = Person().apply {
    name = "Alice"
    age = 25
}

// with
val builder = StringBuilder().apply {
    append("Hello")
    append(" ")
    append("World")
}

// run
val result = run {
    val x = 10
    val y = 20
    x + y
}

// let
val input: String? = "Hello"
input?.let {
    println("Length: ${it.length}")
}

// also
val list = mutableListOf(1, 2, 3)
    .also { println("Original: $it") }
    .add(4)
    .also { println("After add: $it") }

// use
bufferedReader().use { reader ->
    reader.forEachLine { println(it) }
}
```

### 19.7 前置条件 (kotlin.require)

```kotlin
// require - 用于参数验证
fun divide(a: Int, b: Int): Int {
    require(b != 0) { "Divisor cannot be zero" }
    return a / b
}

// check - 用于状态验证
fun getElement(list: List<Int>, index: Int): Int {
    check(index in list.indices) { "Index out of bounds: $index" }
    return list[index]
}

// requireNotNull - 非空检查
fun process(name: String?) {
    val validName = requireNotNull(name) { "Name cannot be null" }
    println(validName)
}

// checkNotNull
fun process2(name: String?) {
    val validName = checkNotNull(name) { "Name cannot be null" }
    println(validName)
}

// assert - 调试断言
fun process3(value: Int) {
    assert(value > 0) { "Value must be positive" }
    // ...
}
```

### 19.8 枚举 (kotlin.enums)

```kotlin
enum class Color(val rgb: Int) {
    RED(0xFF0000),
    GREEN(0x00FF00),
    BLUE(0x0000FF)
}

// 使用
val color = Color.RED
println(color.rgb)  // 16711680

// 枚举函数
Color.values()           // 所有枚举值
Color.valueOf("RED")     // 通过名称获取
Color.RED.ordinal        // 索引位置
Color.RED.name           // 名称

// 自定义函数
enum class Operation {
    ADD { override fun eval(a: Int, b: Int) = a + b },
    SUB { override fun eval(a: Int, b: Int) = a - b };

    abstract fun eval(a: Int, b: Int): Int
}
```

### 19.9 密封类 (kotlin.sealed)

```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error<T>(val message: String) : Result<T>()
    object Loading : Result<Nothing>()
}

// 使用
fun handleResult(result: Result<String>) = when (result) {
    is Result.Success -> "Success: ${result.data}"
    is Result.Error -> "Error: ${result.message}"
    Result.Loading -> "Loading..."
}

// 递归密封类
sealed class Tree<out T> {
    data class Node<T>(
        val value: T,
        val left: Tree<T>? = null,
        val right: Tree<T>? = null
    ) : Tree<T>()

    data class Leaf<T>(val value: T) : Tree<T>()
}
```

### 19.10 线程相关 (kotlin.concurrent)

```kotlin
import kotlin.concurrent.thread

// 创建线程
val t = thread(start = true) {
    println("Thread running")
}

// named thread
val worker = thread(name = "WorkerThread", isDaemon = true) {
    // work
}

// 使用 Thread
val thread = object : Thread() {
    override fun run() {
        println("Running")
    }
}
thread.start()
```

### 19.11 协程标准库 (kotlinx.coroutines)

```kotlin
import kotlinx.coroutines.*

// 协程构建器
runBlocking { }
launch { }
async { }

// 协程控制
delay(1000)         // 延迟
yield()             // 让步
withTimeout(1000) { } // 超时
withTimeoutOrNull(1000) { } // 可空超时

// 协程上下文
Dispatchers.Default
Dispatchers.IO
Dispatchers.Main
Dispatchers.Unconfined

// 流
flow { emit(1) }.collect { }
channel.receive()   // Channel
mutex.withLock { }  // Mutex
```

### 19.12 反射 (kotlin.reflect)

```kotlin
import kotlin.reflect.full.*
import kotlin.reflect.jvm.*

// 类引用
val cls: KClass<*> = String::class
val kType: KType = String::class.createType()

// 构造函数
val constructor = cls.primaryConstructor
val instance = constructor?.call()

// 属性
val nameProperty = cls.declaredMembers.filterIsInstance<KProperty<*>>()
val property = cls.declaredMembers.find { it.name == "length" } as? KProperty1<String, *>
val value = property?.getter?.call("Hello")

// 函数
val func = cls.declaredMembers.find { it.name == "substring" } as? KFunction<*>
val result = func?.call("Hello", 1, 4)

// 类型检查
"Hello" is String
String::class.isInstance("Hello")
```

---

## 20. 最佳实践

### 20.1 编码规范

```kotlin
// 命名约定
val camelCase = "variable"
const val CONSTANT = "constant"
fun functionName() {}
class ClassName {}
enum class EnumName {}

// PID 风格
val myVariable = "value"
var _cachedValue: String? = null
val cachedValue: String
    get() = _cachedValue ?: run {
        val value = computeValue()
        _cachedValue = value
        value
    }
```

### 20.2 空安全实践

```kotlin
// 避免使用 !! 操作符
val length = name?.length ?: 0

// 使用 let 处理可空值
name?.let {
    println("Length: ${it.length}")
}

// use 处理可关闭的资源
bufferedReader().use { reader ->
    reader.forEachLine { println(it) }
}
```

### 20.3 函数式编程

```kotlin
// 链式调用
val result = listOf(1, 2, 3, 4, 5)
    .filter { it % 2 == 0 }
    .map { it * it }
    .sum()

// 使用 apply 初始化对象
val person = Person().apply {
    name = "Alice"
    age = 25
    city = "Beijing"
}

// 使用 with 复用接收者
with(StringBuilder()) {
    append("Hello")
    append(" ")
    append("World")
    println(toString())
}
```

### 20.4 DSL 构建

```kotlin
// 简单的 DSL 示例
fun buildString(block: StringBuilder.() -> Unit): String {
    return StringBuilder().apply(block).toString()
}

val str = buildString {
    append("Hello")
    append(" ")
    append("World")
}

// HTML DSL
fun html(block: HTML.() -> Unit): HTML = HTML().apply(block)

class HTML {
    private val children = mutableListOf<Tag>()

    fun body(block: Body.() -> Unit) {
        children.add(Body().apply(block))
    }
}

class Body : Tag() {
    fun h1(block: Heading.() -> Unit) {
        children.add(Heading().apply(block))
    }
}

open class Tag {
    private val children = mutableListOf<Tag>()

    fun childrenString(): String =
        children.joinToString("\n") { it.render() }

    open fun render(): String =
        "<${this::class.simpleName}>${childrenString()}</${this::class.simpleName}>"
}

class Heading : Tag() {
    operator fun String.unaryPlus() {
        children.add(Text(this@Heading, this))
    }
}

class Text(private val parent: Tag, private val text: String) : Tag() {
    override fun render(): String = text
}
```

### 20.5 协程最佳实践

```kotlin
// 使用 coroutineScope
suspend fun fetchData(): String = coroutineScope {
    val deferred1 = async { api.call1() }
    val deferred2 = async { api.call2() }

    val result1 = deferred1.await()
    val result2 = deferred2.await()

    "$result1 $result2"
}

// 使用 withContext 切换调度器
suspend fun loadData(): Data = withContext(Dispatchers.IO) {
    // I/O 操作
    database.query()
}

// キャンセル可能
class ViewModel : CoroutineScope by MainScope() {
    fun stop() {
        cancel()
    }
}
```

### 20.6 性能优化

```kotlin
// 使用预分配容量
val list = mutableListOf<Int>().apply { ensureCapacity(1000) }

// 避免不必要的对象创建
fun isNullOrBlank(str: String?) = str == null || str.isBlank()

// 使用数组代替 List (原生类型)
val intArray = IntArray(1000)
val arrayList = ArrayList<Int>()

// 懒加载
val expensive by lazy { computeExpensive() }

// 内联函数
inline fun measure(block: () -> Unit) {
    val start = System.currentTimeMillis()
    block()
    println(System.currentTimeMillis() - start)
}
```

### 20.7 参考资源

- [Kotlin 官方文档](https://kotlinlang.org/docs/home.html)
- [Kotlin 标准库文档](https://kotlinlang.org/api/latest/jvm/stdlib/)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html)
- [Kotlin Concurrency Guide](https://kotlinlang.org/docs/concurrency.html)
- [Kotlin GitHub](https://github.com/JetBrains/kotlin)

---

*最后更新: 2026-03-07*