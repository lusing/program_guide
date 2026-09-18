# 06 · 类与属性 ⭐

> 对应示例：`examples/06_classes/`
>
> Kotlin 的 class 和 Java 最深的两条分歧：**属性（property）是语言级概念**，
> 以及 **data class 一行拿走 equals/hashCode/toString/copy/解构**。
> 另外运算符重载靠 operator 约定，不靠魔法。

## 6.1 主构造：声明即属性

```kotlin
class Rect(val width: Double, val height: Double) {
    val area: Double get() = width * height        // 无字段属性：每次现算
    val isSquare: Boolean get() = width == height
}
```

主构造跟在类名后；`val`/`var` 的参数直接成为**属性**。`area` 这种没有 backing field 的属性也是一等公民——调用方无感（`r.area` 看起来都一样），这是"统一访问原则"的语言级实现（C# 同款，Java 做不到）。

## 6.2 init 块与参数校验

```kotlin
class Price(var value: Int) {
    init {
        require(value >= 0) { "价格不能为负: $value" }   // 校验失败抛 IllegalArgumentException
    }
}
```

`init {}` 在实例化时执行（与属性初始化器按出现顺序交错执行）。主构造不能放语句——init 就是它的"函数体"。`require/check/error` 是校验三件套（16 章细讲）。

## 6.3 自定义 getter/setter 与 backing field

```kotlin
class Price(var value: Int) {
    var currency: String = "CNY"
        set(v) { field = v.uppercase() }       // field = 真正的存储槽
    var discount: Double = 0.0
        set(v) { field = v.coerceIn(0.0, 1.0) }   // setter 里做钳制
    val finalPrice: Double get() = value * (1 - discount)
}
```

`field` 标识符只在访问器里存在，指向背后的存储。没有 `field` 的访问器（如 `finalPrice`）就没有存储——**属性 ≠ 字段**，这是 Kotlin 与 Java 的根本差异之一：公开 API 全是属性，内部怎么存是自由。

## 6.4 次构造函数：必须委托主构造

```kotlin
class Employee(val name: String) {
    var dept: String
    init { dept = "未分配" }                       // 先跑
    constructor(name: String, dept: String) : this(name) {   // 委托主构造
        this.dept = dept
    }
}
```

次构造用 `: this(...)` 委托，主构造先执行。多数场景**默认参数 + 工厂函数**（companion，09 章）比次构造更 Kotlin 味。

## 6.5 data class：一行换五件套

```kotlin
data class Point(val x: Int, val y: Int)
```

编译器生成：

| 成员 | 语义 |
|---|---|
| `equals` / `hashCode` | 基于**主构造的全部属性**（`val a = Point(1,2); a == Point(1,2)` 为 true） |
| `toString` | `Point(x=1, y=2)` |
| `copy` | 选择性改字段的克隆：`a.copy(y = 99)` |
| `componentN` | 解构声明：`val (x, y) = a` |

```kotlin
val a = Point(1, 2); val b = Point(1, 2)
a == b                       // true（值相等）
a.hashCode() == b.hashCode() // true
val c = a.copy(y = 99)       // Point(1,99)，a 原封不动
val (x, y) = a               // x=1, y=2 —— component1/component2
```

**copy 是"不可变更新"的基石**（22 章函数式的核心手法）。

注意：data class 限定——主构造至少一个参数、参数全 val/var、不能 abstract/open/sealed/inner。equals/hashCode 只看主构造属性，类体里声明的属性不参与（这是常见翻车点）。

## 6.6 运算符重载：operator 约定

```kotlin
data class Vec2(val x: Double, val y: Double) {
    operator fun plus(o: Vec2) = Vec2(x + o.x, y + o.y)
    operator fun times(k: Double) = Vec2(x * k, y * k)     // 数乘
    operator fun unaryMinus() = Vec2(-x, -y)
    operator fun get(i: Int): Double = when (i) {
        0 -> x; 1 -> y
        else -> throw IndexOutOfBoundsException("i=$i")
    }
}

val v = Vec2(1.0, 2.0) + Vec2(10.0, 20.0) * 2.0    // Vec2(21.0, 42.0)
-v; v[0]; v[1]                                      // -、下标都行
```

函数名固定（`plus/minus/times/div/rem/unaryMinus/get/set/contains/compareTo/...`）+ `operator` 修饰 + 参数签名匹配 → 对应符号可用。**没有任意符号自定义**（不像 C++/Scala）——限制换来可读性。`in`、区间、`for..in`、`+=` 全走这套约定。

## 6.7 可见性入门

默认 **public**。四档：`public`（任意）/ `internal`（同模块）/ `protected`（子类）/ `private`（本类/本文件）。默认 public + 默认 final（07 章）是 Kotlin "少惊喜"哲学的两面。

## 6.8 与 Java class 的对照表

| Java | Kotlin |
|---|---|
| `private int x; getX(); setX(v)` | `var x: Int = 0`（一行） |
| 只读 getter | `val x: Int` |
| 字段不暴露、算出来的值 | 无 backing field 属性 `val area get() = ...` |
| 重载构造器链 | 默认参数（+ 次构造兜底） |
| Lombok @Data / record | `data class` |
| `Objects.equals(a, b)` | `a == b` |
| `a == b`（引用） | `a === b` |

## 6.9 坑位清单

1. **data class 的 equals 不看类体属性**——只看主构造参数。往类体加 `var extra` 会出现"两个相等的对象 extra 不同"。
2. **主构造里 `val x` 与类体 `val x = ...` 撞名**：直接编译错，不是覆盖。
3. `copy` 是浅拷贝——属性是 MutableList 时，副本共享同一个列表；要深拷贝自己写。
4. 自定义 setter 里**读自己的值会递归**：`set(v) { currency = ... }` 死循环，必须用 `field`。
5. 属性初始化顺序 = 声明顺序（与 init 块交错）：在早声明的属性初始化器里引用晚声明的属性会拿到默认值或直接错——依赖顺序的逻辑放 init。
6. `operator fun get` 参数可以任意类型/数量（`m["key", 1]` 合法）——但可读性优先，别炫技。
