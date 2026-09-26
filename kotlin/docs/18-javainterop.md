# 18 · 与 Java 互操作 ⭐

> 对应示例：`examples/18_javainterop/`（真·混合编译：javac → kotlinc → javac → kotlinc 两遍法）
>
> "100% 互操作"不是口号：Kotlin 调 Java、Java 调 Kotlin 都是一等公民。
> 本章讲两侧的映射规则和 `@Jvm*` 注解家族，以及平台类型这个"半空安全"地带。

## 18.1 编译顺序：混合工程的鸡生蛋

互调就有环：`Lib.java`（纯 Java）← Kotlin 用；`Api.kt`（Kotlin）← `Caller.java` 用。单编译器解不了，标准做法**两遍法**（示例 build.ps1 的实现）：

```
1. javac Lib.java                    （不依赖 Kotlin 的纯 Java 库）
2. kotlinc Api.kt  -cp Lib.class     （Kotlin API，可引用 Lib）
3. javac Caller.java -cp Api.class + kotlin-stdlib   （Java 消费者，可引用 Kotlin）
4. kotlinc Main.kt + Tests.kt -cp 全部（入口与测试此刻看得到 Caller）
```

真实工程里 Gradle 的 kotlin 插件自动处理这个环（联合编译）——kotlinc 手工流要知道原理。

## 18.2 Kotlin 调 Java

```kotlin
Lib.nick("kt")                          // 静态方法：直接调
Lib.runOp(5) { it * 10 }                // SAM 转换：lambda 直接当 Java 接口
Lib.base = 42                           // public static 字段像属性
Lib.setBase2(20); Lib.getBase2()        // 静态 getter/setter 对【不合成属性】
```

**getter/setter 映射**：实例方法对 `getX()/setX(v)` 合成为属性 `x`；但**静态** get/set 对不合成（要显式调 `Lib.getBase2()`）——高频意外点。

## 18.3 平台类型：Java 边界的"薛定谔 null"

Java 引用没有空性信息，Kotlin 类型系统里叫**平台类型**（`String!`）：

- 调用点**不强制**判空（编译器放行）——传给 `String` 也行，运行时可能是 null；
- 这就是互操作时代价：**空安全在 Java 边界降级为约定**。

治理手段——**注解 + 编译器识别**：

```java
import org.jetbrains.annotations.Nullable;
public static String firstNonEmpty(String a, @Nullable String b) { ... }
```

kotlinc 对 JetBrains 注解有**内建识别**（`@NotNull` 收紧、`@Nullable` 放宽），返回值直接呈现为 `String?`：

```kotlin
val n2: String? = Lib.firstNonEmpty("", null)    // 类型系统知道它可能为 null ✓
```

JSR-305（`javax.annotation.Nullable`）也支持，要开 `-Xjsr305=strict` 把警告升错误。**防御性纪律：Java 边界进来的值一律先当 `T?` 处理。**

## 18.4 Java 调 Kotlin：@Jvm* 注解家族

没有注解时，Java 看到的 Kotlin 默认形态：

```java
MathKit.INSTANCE.square(7);      // object 的成员要走 INSTANCE
new ApiKt(); ApiKt.upperShout...  // 顶层函数在 文件名Kt 类里，扩展函数名还带尾巴
new Meter(3); m.getValue()       // 属性变成 getter/setter
```

注解逐个修正：

| 注解 | 作用 | Java 侧变化 |
|---|---|---|
| `@JvmStatic` | object/companion 成员生成静态方法 | `MathKit.square(7)` |
| `@JvmField` | 属性暴露为公开字段 | `m.value = 9`（无 getter） |
| `@JvmOverloads` | 为默认参数生成全重载 | `scale(5)` 和 `scale(5, 10)` 都有 |
| `@JvmName("x")` | 改 JVM 方法/类名 | 扩展函数可读的静态名 |
| `@file:JvmName("StrKit")` | 顶层函数门面类改名 | `StrKit.safeLen(null)` |
| `@file:JvmMultifileClass` | 多文件同名门面合并（双方都要标） | `More.kt` 的函数也进 `StrKit` |
| `@get:ColumnName(...)` 等 | 使用处目标——注解挂到 getter/字段/构造参数 | 库按预期位置找到注解（详见 27 章） |
| `@Throws(X::class)` | 方法签名声明受检异常 | Java 编译器强制 catch |

```java
MathKit.square(7);                          // @JvmStatic
MathKit.scale(5);                           // @JvmOverloads：默认参数的重载
m.value = 9;                                // @JvmField
StrKit.shout("hey");                        // @file:JvmName + @JvmName
StrKit.reverseShout("abc");                 // @file:JvmMultifileClass：More.kt 同门面
try { bad.requirePositive(); } catch (IllegalArgumentException e) { }   // @Throws
```

**默认参数对 Java 不可见**（必须全量传参）——跨语言 API 一定加 `@JvmOverloads`。

## 18.5 SAM 转换（Kotlin 侧）

Java 的单抽象方法接口，Kotlin lambda 直接上：

```kotlin
Lib.runOp(5) { it * 10 }        // Op 接口的匿名实现 = 一行 lambda
```

只对 **Java 接口**自动生效；Kotlin 自己的接口要用 `fun interface` 声明才有同等待遇：

```kotlin
fun interface Op { fun apply(x: Int): Int }
val op = Op { it * 2 }          // fun interface 的 SAM 转换
```

## 18.6 集合与类型的映射

| Java | Kotlin 视角 |
|---|---|
| `java.util.List<String>` | `MutableList<String!>!`（平台类型） |
| 只读意图 | 传入时自己包 `listOf(...)` 或判空使用 |
| `Map<String, String>` | `MutableMap`——Kotlin 只读接口只是"视图" |
| `int[]` / `Integer[]` | `IntArray` / `Array<Int>`（注意装箱差异） |
| `void` | `Unit`；`Void`（泛型位置）= `Void?` |
| `Object` | `Any`（非空）/ `Any?` |

Java 集合进来**一律当可变 + 可空元素**处理（平台类型），拷贝落地：`list.mapNotNull { it }` 之类快速"Kotlin 化"。

## 18.7 互操作检查表（写库的人必背）

1. 公开 API 的**可空性全标注**（JetBrains/JSR-305）——下游 Kotlin 用户的空安全靠你。
2. 对外属性该 `@JvmField`/`@JvmStatic` 的就加；默认参数 `@JvmOverloads`。
3. 扩展函数想给 Java 用：`@JvmName` 起个不带 `$` 尾巴的名。
4. 异常想让 Java 强制处理：`@Throws`。
5. 返回 `MutableList` 会被 Java 调用方随手改坏——对外返回只读（`toList()`）。
6. `object` 单例直接给 Java 用没问题（INSTANCE），但伴生工厂加 `@JvmStatic` 体验好一档。

## 18.8 坑位清单

1. **静态 get/set 不合成属性**（`Lib.getBase2()`）——静态字段可以（`Lib.base`），方法对不行，别记混。
2. **平台类型绕过空安全**：Java 返回 null + Kotlin 当 `String` 用 = NPE 在 Kotlin 代码里炸——边界处先 `?:` 兜底。
3. **Java 同名私有字段挡住合成属性**：`private static int base2` + `getBase2()` 会让 Kotlin 的 `Lib.base2` 解析撞上私有字段直接报错——字段改名（示例 Lib.java 的 base2Value 就是这么来的）。
4. 扩展函数在 Java 里的全名是 `文件名Kt.方法$所在文件`——不加 `@file:JvmName`/`@JvmName`，Java 侧调用体验稀碎。
5. Kotlin 的 `List` 传给 Java：Java 那边拿到的是同一个对象，能 cast 成 MutableList 去改——只读是 Kotlin 视角，不是字节码事实。
6. 混合工程的**编译环**用两遍法（18.1）或交给 Gradle；单遍 kotlinc 编不了互相引用的 Java/Kotlin。
