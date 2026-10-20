# 18 · 与 Java 互操作 ⭐

> 对应示例：`examples/18_javainterop/`——一个**真·混合编译**工程：`src/main/java/Lib.java`（纯 Java 库，Kotlin 调它）、`src/main/kotlin/Api.kt` + `More.kt`（Kotlin API，Java 调它）、`src/main/java/Caller.java`（Java 消费者）、`src/main/kotlin/Main.kt`（入口）、`test/Tests.kt`（测试）。构建用 **javac → kotlinc → javac → kotlinc 两遍法**手工解开编译环。
>
> Kotlin 当年敢杀入 JVM 生态，底牌就是"100% 与 Java 互操作"：Java 三十年的库（Spring、OkHttp、JDK 本身）一行不改直接用，存量 Java 工程可以一个文件一个文件地迁。但"能互调"和"调得舒服"是两回事——本章讲清两侧的映射规则、平台类型这个空安全的"灰色地带"，以及让 Java 侧调用体验对齐 Java 习惯的 `@Jvm*` 注解家族。
>
> 说明：本章与 19 章的部分原始素材来自几本 Kotlin 1.x 时代的老书（《Kotlin语言实例精解(2019)》《Kotlin从入门到进阶实战(2018)》等）。思想不过时，但当时的写法（Groovy DSL、Java 8 API）已全部升级为现代 Kotlin 2.4.21 + JDK 21 表述。

## 18.1 混合编译的"鸡生蛋"问题：两遍法

互调意味着依赖成环。看示例里的依赖关系：

- `Lib.java` 是纯 Java，**不依赖任何 Kotlin 代码**（Kotlin 的 `Main.kt` 要调它）；
- `Api.kt`/`More.kt` 是纯 Kotlin（Java 的 `Caller.java` 要调它）；
- `Caller.java` 依赖 Kotlin 编出的类；
- `Main.kt`/`Tests.kt` 又依赖 `Caller`（Kotlin 测试要断言 Java 消费者的输出）。

单个编译器一遍走不完：先编 Kotlin 吧，`Main.kt` 引用 `Caller.class`，还没有；先编 Java 吧，`Caller.java` 引用 Kotlin 的 `StrKit`，也还没有。标准解法是**两遍法**——按"不依赖对方的先编"原则排序，示例构建脚本实际执行的四步：

```
1. javac  Lib.java        -cp annotations-13.0.jar        # 纯 Java 库，最先编
2. kotlinc Api.kt More.kt -cp classes + annotations       # Kotlin API，此刻 Lib.class 已在 classpath
3. javac  Caller.java     -cp classes + kotlin-stdlib.jar # Java 消费者，此刻 Kotlin 类已在 classpath
4. kotlinc Main.kt Tests.kt -cp classes + annotations     # 入口与测试，此刻 Caller.class 已就位
```

第 3 步的 classpath 里为什么有 `kotlin-stdlib.jar`：Java 编译 `Caller.java` 时引用的是 Kotlin 编译产物（比如 `StrKit`），这些 class 的方法签名里可能出现 stdlib 类型，javac 解析符号时需要 stdlib 在场。运行期同理——**Java 调 Kotlin 的程序，classpath 必须带 kotlin-stdlib**，这是混合工程部署时最容易漏的一个 jar。

真实工程不用手工排这个序：Gradle 的 `kotlin("jvm")` 插件做**联合编译**（kotlinc 与 javac 协同，互相看得见对方的源码与产物），`src/main/java` 和 `src/main/kotlin` 混放即可。但手工流值得走一遍——理解了环的存在，Gradle 配置出错时（比如把 java 文件放进了错误的源集）才知道它在替你解决什么。

## 18.2 Kotlin 调 Java：无缝，但有三处要记

先看 Java 库的全貌（`Lib.java` 全文）：

```java
// 纯 Java 侧的库：Kotlin 会调用它（javac 先编译，kotlinc -cp 引用）
// 编译：javac -encoding UTF-8 -cp annotations-13.0.jar -d classes Lib.java
import org.jetbrains.annotations.Nullable;   // JetBrains 注解：kotlinc 内建识别，收紧为可空类型

public class Lib {

    /** 普通静态方法：Kotlin 里当函数调用 */
    public static String nick(String name) {
        return "[" + name + "]";
    }

    /** 返回值可能为 null：@Nullable 让 Kotlin 看到的是 String? 而不是平台类型 */
    @Nullable
    public static String firstNonEmpty(String a, @Nullable String b) {
        return a.isEmpty() ? b : a;
    }

    /** SAM 接口：Kotlin lambda 可以自动转换 */
    public interface Op {
        int apply(int x);
    }

    /** 接受 SAM 的方法：Kotlin 里直接传 lambda */
    public static int runOp(int x, Op op) {
        return op.apply(x);
    }

    /** 静态字段：Kotlin 里像属性一样读写 */
    public static int base = 100;

    /** getter/setter 命名对：Kotlin 里自动变成属性 base2
     *  注意：这里私有字段改叫 base2Value 而不是 base2——若同名，Kotlin 的合成属性
     *  会优先撞上私有字段而报"it is private"（真实的互操作坑，见 docs/18-javainterop.md） */
    private static int base2Value = 5;
    public static int getBase2() { return base2Value; }
    public static void setBase2(int v) { base2Value = v; }
}
```

Kotlin 侧的调用（`Main.kt` 全文）：

```kotlin
// 18 · 与 Java 互操作：平台类型、@Jvm* 注解、SAM 转换、属性映射

fun main() {
    println("== 18.2 Kotlin 调 Java ==")
    println("Lib.nick(\"kt\") = ${Lib.nick("kt")}")
    // @Nullable 注解 + -Xjsr305=strict：返回值直接是 String?，不经过平台类型
    val n1: String? = Lib.firstNonEmpty("", "备用")
    val n2: String? = Lib.firstNonEmpty("", null)
    println("firstNonEmpty(\"\", \"备用\") = $n1")
    println("firstNonEmpty(\"\", null) = $n2（类型系统知道它可能为 null）")
    // SAM 转换：lambda 直接当 Java 接口实现传
    println("Lib.runOp(5) { it * 10 } = ${Lib.runOp(5) { it * 10 }}")
    // 静态字段 ↔ 属性语法；静态 getter/setter 对不合成属性，要显式调用（对比实例方法）
    Lib.base = 42
    println("Lib.base = ${Lib.base}")
    Lib.setBase2(20)
    println("Lib.getBase2() = ${Lib.getBase2()}   ← 静态 get/set 不合成属性")

    println("== 18.3 Java 调 Kotlin（Caller.demo）==")
    print(Caller.demo())
}
```

三种调用形态，对应三条映射规则：

**① 静态成员直接调。** `Lib.nick("kt")` 与 Java 写法一致，无需任何适配——Java 静态方法在 Kotlin 里就是"类名限定"的普通调用。

**② SAM 转换：lambda 自动当接口实现。** `Lib.runOp(5) { it * 10 }` 里，`{ it * 10 }` 是个 Kotlin lambda，参数位置要的却是 Java 接口 `Op`——编译器自动生成匿名实现。这条规则**只对 Java 接口自动生效**；Kotlin 自己的接口想用同等待遇，必须声明为 `fun interface`（12 章讲过）。Java 侧反过来也行，`Caller.java` 里就有 `Lib.runOp(6, x -> x * 3)`——Java 8 的 lambda 喂给同一个方法，两向对称。

**③ 字段与 getter/setter 的属性化——静态和实例规则不同。** 这是最高频的意外点：

- `public static int base` 是**公开静态字段** → Kotlin 直接当可变属性用：`Lib.base = 42`。
- `getBase2()/setBase2()` 是**静态**方法对 → Kotlin **不**合成属性，必须显式调 `Lib.setBase2(20)`、`Lib.getBase2()`。
- 对比：**实例**的 `getX()/setX(v)` 方法对会合成属性 `x`（JavaBean 约定）。所以"方法对合成属性"只对实例成立，静态方法对不享受。

`Lib.java` 注释里还埋了一个真实踩坑记录：私有字段故意叫 `base2Value` 而不是 `base2`——如果私有字段与合成属性同名（`private static int base2`），Kotlin 解析 `Lib.base2` 时会先撞上那个私有字段，报"it is private"错误。给 Java 库的私有字段起个与 getter 不同的名字，是写"对 Kotlin 友好的 Java API"的小纪律。

## 18.3 平台类型：Java 边界的"薛定谔 null"

`firstNonEmpty` 这个方法是理解**平台类型（platform type）**的最佳标本。Java 的引用类型不带空性信息：`String` 可能是 null 也可能不是，Java 编译器不管。这样的类型进入 Kotlin，类型系统既不敢当 `String`（万一 null 呢）也不敢当 `String?`（万一调用方嫌烦呢），于是发明了一个中间态——**平台类型**，IDE 里显示为 `String!`：

- 调用点**不强制判空**：赋给 `String` 编译器放行，运行时才可能 NPE；
- 也**不禁止当可空用**：赋给 `String?` 同样合法。

也就是说，**Kotlin 引以为傲的空安全在 Java 边界上降级为"靠约定"**。这是互操作的固有代价：编译器没有信息，只能信任你。

治理手段是给 Java 代码**加可空性注解**，把信息补回来。`Lib.java` 用了 [JetBrains 注解库](https://github.com/JetBrains/java-annotations)的 `@Nullable`（kotlinc 对它**内建识别**，无需任何编译参数；JSR-305 的 `javax.annotation.Nullable` 则需要 `-Xjsr305=strict` 才生效，本例用的不是它）：

- 返回值标 `@Nullable` → Kotlin 看到的就是货真价实的 `String?`，`val n2: String? = Lib.firstNonEmpty("", null)` 编译通过且类型系统全程盯着你判空；
- 参数标 `@Nullable` → Kotlin 允许传 `null` 进去；
- 标 `@NotNull` → 反过来收紧，传可空值直接编译错误。

`Main.kt` 里 `n1`、`n2` 都声明为 `String?`——**防御性纪律：从 Java 边界进来的值，一律先当 `T?` 处理**，在边界上用 `?.`、`?:` 收敛掉 null，再往 Kotlin 腹地传非空类型。这样 NPE 即使发生，也炸在边界上、炸在你可以一把抓住的地方。

## 18.4 Java 调 Kotlin：默认形态与 @Jvm* 注解家族

方向反过来，问题换了个性质：Kotlin 语法比 Java 表达力强（顶层函数、扩展函数、object 单例、默认参数、属性），编译成字节码时这些概念要"降维"成 Java 能理解的类与方法。**默认降维结果对 Java 调用方很不友好**，`@Jvm*` 注解家族就是逐个修正这些降维痕迹的工具。

先看 Kotlin API 的完整声明（`Api.kt` 全文）：

```kotlin
// Kotlin 侧的 API：Java 会调用它（kotlinc 编译后，javac -cp 引用）
// @file:JvmMultifileClass：允许 More.kt 等其他文件的同名门面类合并进 StrKit（两份文件都要标）
@file:JvmName("StrKit")
@file:JvmMultifileClass

/** @JvmStatic：让 companion/object 里的函数以真正的静态方法暴露给 Java */
object MathKit {
    @JvmStatic
    fun square(x: Int): Int = x * x

    @JvmStatic
    @JvmOverloads                       // 为默认参数生成全部重载：f(a), f(a, b)
    fun scale(x: Int, k: Int = 2): Int = x * k
}

/** @JvmField：把属性编译成真字段（没有 getter/setter） */
class Meter(@JvmField var value: Int) {
    /** 默认参数方法：Java 侧必须全量传参，除非标 @JvmOverloads */
    fun show(unit: String = "m") = "$value$unit"

    /** @Throws：让 Java 调用方在签名里看到受检异常（Kotlin 没有 checked exception） */
    @Throws(IllegalArgumentException::class)
    fun requirePositive() {
        if (value < 0) throw IllegalArgumentException("负数: $value")
    }
}

/** @JvmName（函数级）：改 JVM 方法名，常用于扩展函数（否则编译名是 upperShout 加尾巴） */
@JvmName("shout")
fun String.upperShout(): String = uppercase() + "!"

/** 可空参数：Java 的 null 可以传进来，Kotlin 在边界上守住 */
fun safeLen(s: String?): Int = s?.length ?: 0
```

以及第二个门面文件（`More.kt` 全文）：

```kotlin
// 同门面的第二个文件：@file:JvmName 相同 + 双方都标 @file:JvmMultifileClass → 顶层函数合并进同一个 StrKit
@file:JvmName("StrKit")
@file:JvmMultifileClass

/** 没有它，两个文件同名门面类会"platform declaration clash"；有它，Java 侧一个 StrKit 全收 */
fun reverseShout(s: String): String = s.reversed().uppercase() + "!"
```

Java 消费者的完整调用（`Caller.java` 的 `demo()` 方法，它刻意返回字符串而不打印——让 Kotlin 测试能对输出做断言，单一事实源）：

```java
public static String demo() {
    StringBuilder sb = new StringBuilder();
    // @JvmStatic：直接静态调用，不用 MathKit.INSTANCE.square(...)
    sb.append("Java→Kotlin MathKit.square(7) = ").append(MathKit.square(7)).append('\n');
    // @JvmOverloads：默认参数生成了重载，Java 可以只传一个参数
    sb.append("Java→Kotlin MathKit.scale(5) = ").append(MathKit.scale(5)).append('\n');
    sb.append("Java→Kotlin MathKit.scale(5, 10) = ").append(MathKit.scale(5, 10)).append('\n');
    // @JvmField：像字段一样直接访问，没有 getValue/setValue
    Meter m = new Meter(3);
    m.value = 9;
    sb.append("Java→Kotlin Meter.value = ").append(m.value).append('\n');
    // 默认参数方法 + @JvmOverloads 之外：普通默认参数在 Java 侧必须全量传参
    sb.append("Java→Kotlin Meter.show(\"cm\") = ").append(m.show("cm")).append('\n');
    // 顶层函数：门面类名来自 @file:JvmName("StrKit")，方法名来自 @JvmName("shout")
    sb.append("Java→Kotlin StrKit.shout(\"hey\") = ").append(StrKit.shout("hey")).append('\n');
    // @file:JvmMultifileClass：More.kt 的顶层函数也进了同一个 StrKit 门面
    sb.append("Java→Kotlin StrKit.reverseShout(\"abc\") = ").append(StrKit.reverseShout("abc")).append('\n');
    // 可空参数：Java 随便传 null，Kotlin 的 ?. 在边界兜底
    sb.append("Java→Kotlin safeLen(null) = ").append(StrKit.safeLen(null)).append('\n');
    // @Throws：Java 侧能捕获 Kotlin 抛的异常
    try {
        Meter bad = new Meter(-1);
        bad.requirePositive();
    } catch (IllegalArgumentException e) {
        sb.append("Java 捕获 Kotlin 异常: ").append(e.getMessage()).append('\n');
    }
    // 反方向：Kotlin lambda 自动转 Java 的 SAM 接口
    sb.append("Kotlin→Java Lib.runOp(6, x -> x * 3) = ").append(Lib.runOp(6, x -> x * 3)).append('\n');
    // 静态字段/属性映射：base 是字段，base2 是 getter/setter 对 → 都像属性
    Lib.base = 7;
    Lib.setBase2(11);
    sb.append("Lib.base=").append(Lib.base)
      .append(", Lib.base2=").append(Lib.getBase2()).append('\n');
    return sb.toString();
}
```

逐条对照，每个注解修正一个"降维痕迹"：

**[@JvmStatic](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-jvm-static/index.html)——object 成员变成真静态。** Kotlin 的 `object MathKit` 是单例，默认编译成一个带 `INSTANCE` 静态字段的类，Java 要写成 `MathKit.INSTANCE.square(7)`——别扭且暴露实现细节。`@JvmStatic` 让编译器**额外**生成静态转发方法，Java 侧 `MathKit.square(7)` 直调。companion object 成员同理。

**[@JvmOverloads](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-jvm-overloads/index.html)——默认参数的翻译器。** Kotlin 的 `fun scale(x: Int, k: Int = 2)` 在字节码里只有一个全参方法加一个合成桥方法，**默认参数值对 Java 完全不可见**——Java 调 `scale(5)` 编译错误，必须 `scale(5, 2)` 全量传参。`@JvmOverloads` 让编译器从后往前逐个砍掉带默认值的参数、生成全部重载：`scale(int)` 和 `scale(int, int)` 都有了（`Caller.java` 里 `MathKit.scale(5)` = 10 用的就是单参重载）。**凡是要给 Java 用的、带默认参数的 API，必加。** 对照组是 `Meter.show(unit: String = "m")`——它没标 `@JvmOverloads`，所以 `Caller.java` 里只能 `m.show("cm")` 全参调用。

**[@JvmField](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-jvm-field/index.html)——属性变真字段。** Kotlin 的 `var value` 默认编译成"私有字段 + `getValue()`/`setValue()`"。`class Meter(@JvmField var value: Int)` 让构造参数直接成为公开字段，Java 侧 `m.value = 9` 像操作普通 Java 字段——对 DTO/数据载体类，这是 Java 用户期待的形态。

**[@JvmName](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-jvm-name/index.html)（函数级 + 文件级）——命名权收回来。** Kotlin 顶层函数默认编译进"文件名 + Kt"的类：`Api.kt` → `ApiKt`。两个修正：`@file:JvmName("StrKit")` 把门面类改名（Java 侧 `StrKit.safeLen(null)`，语义化）；函数级 `@JvmName("shout")` 把扩展函数 `String.upperShout()` 的 JVM 方法名改成 `shout`——扩展函数本质是"接收者变第一个参数的静态方法"，Java 侧调用本是 `StrKit.upperShout("hey")` 这种带着 Kotlin 味的名字，改名后 `StrKit.shout("hey")` 就是个普通 Java 静态方法的样子。

**[@file:JvmMultifileClass](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-jvm-multifile-class/index.html)——多文件合并门面。** `Api.kt` 和 `More.kt` 都想要 `StrKit` 这个门面类名——默认会编译冲突（platform declaration clash）。两个文件**都**标上相同的 `@file:JvmName("StrKit")` 加 `@file:JvmMultifileClass`，编译器就把两个文件的顶层函数合并进同一个门面（内部实现是各自的 `StrKit__ApiKt`、`StrKit__MoreKt` 分部类 + 一个总转发类）。于是 `More.kt` 里的 `reverseShout` 在 Java 侧也是 `StrKit.reverseShout("abc")`。

**[@Throws](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-throws/index.html)——受检异常的桥。** Kotlin 没有 checked exception，`throw IllegalArgumentException(...)` 在字节码的方法签名上**不会**声明 `throws`。Java 编译器因此不知道要 catch——`bad.requirePositive()` 抛了异常，Java 代码不写 try/catch 也能编译，运行时才炸。`@Throws(IllegalArgumentException::class)` 在签名里补上声明，Java 侧立刻获得编译期的强制处理要求（`Caller.java` 的 try/catch 才能捕获并输出 `Java 捕获 Kotlin 异常: 负数: -1`）。

**可空参数反向流动。** `safeLen(s: String?)` 声明了可空参数，Java 侧 `StrKit.safeLen(null)` 随便传 null——Kotlin 的类型声明在字节码里没有强制力，空安全是 Kotlin 侧编译期的事。防线在 Kotlin 函数体内部：`s?.length ?: 0` 在边界上就把 null 消化掉了（输出 `safeLen(null) = 0`）。这是 18.3 节防御性纪律的镜像：**Java 可能传 null 进来的参数，声明成可空类型并在函数体第一行收敛。**

## 18.5 运行输出：expected.txt 逐行核对

程序输出（与 `expected.txt` 一致）：

```
== 18.2 Kotlin 调 Java ==
Lib.nick("kt") = [kt]
firstNonEmpty("", "备用") = 备用
firstNonEmpty("", null) = null（类型系统知道它可能为 null）
Lib.runOp(5) { it * 10 } = 50
Lib.base = 42
Lib.getBase2() = 20   ← 静态 get/set 不合成属性
== 18.3 Java 调 Kotlin（Caller.demo）==
Java→Kotlin MathKit.square(7) = 49
Java→Kotlin MathKit.scale(5) = 10
Java→Kotlin MathKit.scale(5, 10) = 50
Java→Kotlin Meter.value = 9
Java→Kotlin Meter.show("cm") = 9cm
Java→Kotlin StrKit.shout("hey") = HEY!
Java→Kotlin StrKit.reverseShout("abc") = CBA!
Java→Kotlin safeLen(null) = 0
Java 捕获 Kotlin 异常: 负数: -1
Kotlin→Java Lib.runOp(6, x -> x * 3) = 18
Lib.base=7, Lib.base2=11
```

前半段是 `Main.kt` 的 Kotlin→Java 方向：`[kt]` 是静态方法直调；`备用`/`null` 展示 `@Nullable` 让返回值以 `String?` 呈现（null 能安全打印，因为类型系统知道它可空）；`50` 是 SAM 转换（5 × 10）；`42` 和 `20` 对比"静态字段属性化"与"静态 get/set 不属性化"。

后半段是 `Caller.demo()` 的 Java→Kotlin 方向，每一行对应一个注解的生效证据：`49`（@JvmStatic）、`10` 与 `50`（@JvmOverloads 两个重载）、`9`（@JvmField 字段直写）、`9cm`（默认参数方法全参调用）、`HEY!`（@JvmName × 2：`StrKit` 门面 + `shout` 方法名，`uppercase() + "!"` 的效果）、`CBA!`（@file:JvmMultifileClass 让 `More.kt` 的函数同处一个门面；`"abc"` 经 [reversed](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/reversed.html) → `"cba"` 再 [uppercase](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/uppercase.html) 加 `!`）、`0`（可空参数兜底）、`负数: -1`（@Throws 让 Java catch 到）、`18`（Java lambda 喂 Java SAM，反方向闭环）、`Lib.base=7, Lib.base2=11`（Java 侧同样享受字段/方法对映射）。

## 18.6 测试：双向断言

`test/Tests.kt` 全文：

```kotlin
// 18 的测试：双向互操作行为
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun testKotlinCallsJava() {
    assertEquals("[kt]", Lib.nick("kt"))
    assertEquals("备用", Lib.firstNonEmpty("", "备用"))
    assertEquals("主", Lib.firstNonEmpty("主", "备"))
    assertNull(Lib.firstNonEmpty("", null))
    assertEquals(50, Lib.runOp(5) { it * 10 })
    Lib.base = 7
    assertEquals(7, Lib.base)
    Lib.setBase2(3)                                  // 静态 get/set 不合成属性
    assertEquals(3, Lib.getBase2())
}

fun testJavaCallsKotlin() {
    val out = Caller.demo()
    assertTrue("MathKit.square(7) = 49" in out, out)
    assertTrue("MathKit.scale(5) = 10" in out)          // @JvmOverloads 默认参数
    assertTrue("Meter.value = 9" in out)                 // @JvmField
    assertTrue("StrKit.shout(\"hey\") = HEY!" in out)    // @JvmName ×2
    assertTrue("safeLen(null) = 0" in out)
    assertTrue("负数: -1" in out)                         // @Throws
    assertTrue("Lib.runOp(6, x -> x * 3) = 18" in out)
    assertTrue("Lib.base=7, Lib.base2=11" in out)
}

fun testJvmStatics() {
    // @JvmStatic 的效果：不用 MathKit.INSTANCE.square 也能从 Java 调（Caller 已验证）；
    // Kotlin 侧调用形式不变
    assertEquals(49, MathKit.square(7))
    assertEquals(10, MathKit.scale(5))
    assertEquals(50, MathKit.scale(5, 10))
}

fun main() {
    testKotlinCallsJava()
    testJavaCallsKotlin()
    testJvmStatics()
    assertNotNull(Lib.firstNonEmpty("x", null))
    println("18_javainterop 全部测试通过")
}
```

测试分三组，结构与前文严格对应：`testKotlinCallsJava` 守 Kotlin→Java 方向（[assertNull](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-null.html) 专门验证 `@Nullable` 返回值真的可以安心判空）；`testJavaCallsKotlin` 的策略值得学——**让 Java 侧把行为汇总成字符串返回，Kotlin 测试做断言**，这样断言工具（kotlin.test）只有一套，Java 消费者的行为变化（比如某个注解失效导致编译失败之外的行为漂移）也能被测试网住；`testJvmStatics` 验证 `@JvmStatic` 不影响 Kotlin 侧自己的调用形式。最后的 [assertNotNull](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-not-null.html) 兜一句：`firstNonEmpty("x", null)` 第一个参数非空时必返回 `"x"`。

## 18.7 集合与类型的映射速览

Java 类型进入 Kotlin 时的映射规则（泛型参数一律带平台类型的"!"）：

| Java | Kotlin 视角 |
|---|---|
| `java.util.List<String>` | `MutableList<String!>!` |
| `Map<String, String>` | `MutableMap`——Kotlin 的只读 `List`/`Map` 只是接口视图，字节码里就是同一个 `java.util.List` |
| `int[]` / `Integer[]` | `IntArray` / `Array<Int>`（前者不装箱，差一个数量级的内存） |
| `void` | `Unit`；泛型位置的 `Void` = `Void?` |
| `Object` | `Any`（非空位置）/ `Any?` |

两条纪律：Java 集合进来**按"可变 + 元素可空"的最坏假设处理**，需要长期持有就拷贝落地（`toList()`）；反过来把 Kotlin 的 `List` 传给 Java，对方拿到的是**同一个对象**，可以 cast 成 `MutableList` 改坏它——只读是 Kotlin 视角，不是字节码事实，跨边界交付防御性拷贝。

## 18.8 互操作检查表（写库的人必背）

1. 公开 API 的**可空性全标注**（JetBrains `@Nullable`/`@NotNull`）——下游 Kotlin 用户的空安全系于你。
2. 对外属性该 `@JvmField`/`@JvmStatic` 的就加；带默认参数的方法必加 `@JvmOverloads`。
3. 扩展函数想给 Java 用：`@file:JvmName` 起个正常门面名 + `@JvmName` 改方法名。
4. 异常想让 Java 强制处理：`@Throws`。
5. 返回 `MutableList` 会被 Java 调用方随手改坏——对外返回只读拷贝。
6. `object` 单例直接给 Java 用要走 `INSTANCE`；给 Java 用户加 `@JvmStatic`，体验好一档。
7. Java 私有字段名避开 getter 推导出的属性名（`base2Value` vs `base2` 的教训）。

## 18.9 坑位清单

1. **静态 get/set 不合成属性**：静态字段可以 `Lib.base`，静态方法对必须 `Lib.getBase2()`——和实例方法对的规则不同，别记混。
2. **平台类型绕过空安全**：Java 返回 null + Kotlin 当 `String` 用 = NPE 在 Kotlin 代码深处炸。边界处先 `?:` 兜底。
3. **Java 同名私有字段挡住合成属性**：`private static int base2` + `getBase2()` 会让 Kotlin 的 `Lib.base2` 解析撞上私有字段直接报错——私有字段改名（示例 `Lib.java` 的 `base2Value` 就是这么来的）。
4. **混合工程的编译环**：两遍法（18.1）或交给 Gradle 联合编译；单遍 kotlinc 编不了互相引用的 Java/Kotlin。
5. **运行 classpath 漏 kotlin-stdlib.jar**：Java 调 Kotlin 的程序，部署时只带业务 jar 会 `NoClassDefFoundError: kotlin/jvm/internal/...`。
6. **默认参数对 Java 不可见**：没加 `@JvmOverloads` 的方法，Java 侧必须全量传参（`Meter.show("cm")`）；Kotlin 侧改动默认值后，Java 调用方行为不会跟着变。
7. Kotlin 的只读 `List` 传给 Java 后可被对方强转修改——跨边界要防御性拷贝。

---

上一章：[17 工程化与 Gradle](17-gradle.md) · 下一章：[19 文件与文本](19-files.md)
