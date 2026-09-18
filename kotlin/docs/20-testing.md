# 20 · 测试 ⭐

> 对应示例：`examples/20_testing/`（断言画廊、表驱动、边界、可复现随机、假实现）
>
> 本教程各章用"自写 main + kotlin.test 断言"（无 runner 依赖）；
> 真实工程用 JUnit5（17 章的 Gradle 工程已展示）。本章讲两种形态 + 测试方法论。

## 20.1 kotlin.test 断言全家

```kotlin
import kotlin.test.*

assertEquals(4, 2 + 2, "带失败消息")
assertNotEquals(3, 2 + 2)
assertTrue(list.isEmpty()); assertFalse(list.isEmpty())
assertNull(x); assertNotNull(x)
assertContains(listOf(1, 2, 3), 2)          // 集合、字符串、范围都行
assertContains("hello", "ell")
assertFailsWith<IllegalArgumentException> { grade(101) }   // 异常断言
assertEquals(0.1 + 0.2, 0.3, 1e-9)          // 浮点：误差容限（绝对值）
```

**浮点永远用容限重载**——`assertEquals(0.3, 0.1 + 0.2)` 会红（二进制浮点表示误差）。

## 20.2 本教程形态：main + 断言（为什么不装 JUnit）

kotlinc 单机环境没有 JUnit runner；教程要的是"零配置可复现"。于是：

```kotlin
fun testGreet() { assertEquals("你好", greet("世界")) }
fun testRender() { ... }

fun main() {
    testGreet()
    testRender()
    println("20_testing 全部测试通过")     // 走到这行 = 全部断言通过
}
```

失败行为：断言抛 AssertionError → main 非零退出 → build.ps1 L2 层变红。**缺点**：第一个失败就停（没有"继续跑完再汇总"）——教学场景反而好（修复一进一退）。

## 20.3 JUnit5 形态（Gradle 工程）

```kotlin
class GreetingTest {
    @Test
    fun `greeting inserts name`() {              // 反引号还能写带空格的测试名！
        assertEquals("Hello, Kotlin!", greeting("Kotlin"))
    }
    @Test
    fun wordFreq() { assertEquals(listOf("a" to 2, "b" to 1), wordFreq("a b a")) }
}
```

`@Test` 注解 + 框架反射调度：失败隔离（一个红不影响别的）、生命周期（@BeforeEach）、参数化、并发。**17_gradle 工程的 lib/app 测试就是这套**。命令：`gradle test`。

## 20.4 表驱动：一表胜十函数

```kotlin
val table = listOf(1 to "1", 3 to "Fizz", 5 to "Buzz", 15 to "FizzBuzz")
for ((input, want) in table) {
    assertEquals(want, fizzbuzz(input), "fizzbuzz($input)")     // 消息带上输入定位
}
```

新增用例 = 加一行表。失败消息写清**哪个输入**错——`fizzbuzz(15)` 比 "expected equal" 可查一百倍。

## 20.5 边界值分析

分段逻辑（如 grade 的 0-59/60-79/80-89/90-100）测**分界点两侧**：

```kotlin
for ((s, g) in listOf(0 to 'D', 59 to 'D', 60 to 'C', 79 to 'C', 80 to 'B', 89 to 'B', 90 to 'A', 100 to 'A')) ...
```

每个等价类取代表 + 每个边界取两侧——八个用例覆盖全部分支。加上越界（-1/101）断言异常，行为就钉死了。

## 20.6 可复现的"随机"

```kotlin
val rng = Random(42)
val rolls = List(5) { rollDie(rng) }       // [6, 1, 6, 3, 2] —— 每次运行必相同
assertEquals(rolls, List(5) { rollDie(Random(42)) })   // 同种子 → 同序列
```

涉及随机的测试**注入 `Random(seed)`**（依赖注入）：失败可复现、CI 稳定。同种子的两个实例产生相同序列——这个性质本身也值得断言。

## 20.7 假实现（fake）：测试替身的最轻形态

```kotlin
interface TaskStore { fun add(title: String): Int; fun all(): List<Task2> }

class InMemoryStore : TaskStore { ... }        // 内存假实现：不碰磁盘/网络
```

- **fake**（本教程用的）：可用的轻量实现（内存库）——快，行为近似真实。
- mock（MockK 等库）：录制调用、返回桩值——验证"交互"（被调几次、参数对不对）。
- 依赖倒置的真谛：**领域逻辑依赖接口（TaskStore），生产注入文件/DB 实现，测试注入 fake**——24 章的存储层就是这么分层的。

## 20.8 测试该测什么（启发式清单）

1. 正常路径（happy path）。
2. 空输入 / 零 / 空串 / 空列表。
3. 边界两侧（20.5）。
4. 非法输入：该抛的抛（assertFailsWith），该回 null/Result 失败的回。
5. 幂等与往返：save → load 出来 equals 原值（24 章存储测试）。
6. 不变量：排序后仍含全部元素、编码再解码相等。

命名法：`test<被测><场景>`（本教程）或反引号句子（JUnit5：`fun `add then complete marks done`()`）。团队统一即可。

## 20.9 协程怎么测

最朴素：`runBlocking { ... }` 直接断言（14/15 章测试就是这么写的）。进阶用 kotlinx-coroutines-test 的 `runTest`（虚拟时间：`delay` 直接跳过不真等）——本教程场景小，runBlocking 足够讲清语义，工程里换 runTest 只是换一个入口函数。

## 20.10 坑位清单

1. **浮点相等**不带容限必翻车（0.1+0.2 ≠ 0.3）。
2. `assertFailsWith` 的块**必须真的抛**——重构后忘了会导致"测试静默通过但业务变了"（红色测试比假绿安全）。
3. 测试里别用 `Thread.sleep` 等异步——慢且脆；runTest/虚拟时钟（22 章 FakeClock）才是正解。
4. 共享可变状态的测试顺序依赖：测试函数之间共享的 object（如 09 章 Registry）会被上个测试改脏——测试要么自建实例要么重置。
5. 随机不注种子的测试 = CI 定期抽风——`Random(42)` 一次解决。
6. 断言消息别写"应该相等"——写**输入与期望**（`fizzbuzz($input) 期望 $want`）。
