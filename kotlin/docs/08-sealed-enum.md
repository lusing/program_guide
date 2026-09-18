# 08 · 密封类、枚举与 when ⭐

> 对应示例：`examples/08_sealed_enum/`
>
> "值的固定集合"（enum）与"类型的固定集合"（sealed）+ 穷尽 when——
> 三者合起来是 Kotlin 的代数数据类型（ADT）体系，Rust 的 enum 满血版。

## 8.1 枚举：带数据的常量族

```kotlin
enum class Planet(val gravity: Double) {          // 构造参数 → 每个常量携带数据
    MERCURY(3.7), EARTH(9.81), MARS(3.71), JUPITER(24.79);

    fun weightOn(earthKg: Double): Double = earthKg * gravity
    override fun toString(): String = "$name(g=$gravity)"
}
```

枚举常量还能各自实现抽象方法：

```kotlin
enum class Ops {
    ADD { override fun apply(a: Int, b: Int) = a + b },
    SUB { override fun apply(a: Int, b: Int) = a - b };
    abstract fun apply(a: Int, b: Int): Int        // 每个常量一个匿名子类
}
```

遍历用 **`Planet.entries`**（1.9+ 稳定，惰性、类型安全）替代老的 `values()`（每次调用拷贝数组）。

## 8.2 when 的穷尽性：编译器替你查漏

```kotlin
fun describe(n: Int) = when (n) {          // 有 else 就不穷尽检查
    0 -> "零"; 1, 2, 3 -> "小"; in 4..9 -> "中"; else -> "大"
}
```

对**枚举和密封类型**作 when 表达式时，可以（也应该）**不写 else**——漏掉任何一个分支都是编译错"when must be exhaustive"。这不是风格建议，是重构安全网：**新增枚举值/子类型时，所有遗漏的 when 立刻红给你看**。

守卫条件（2.1+）让分支带上谓词：

```kotlin
when (n) {
    in 1..100 if n % 2 == 0 -> "小偶数"
    in 1..100 -> "小奇数"
    else -> "范围外"
}
```

## 8.3 密封继承：类型的固定集合

```kotlin
sealed interface Expr {
    data class Num(val v: Double) : Expr
    data class Add(val l: Expr, val r: Expr) : Expr
    data class Mul(val l: Expr, val r: Expr) : Expr
    data class Neg(val e: Expr) : Expr
    data object Zero : Expr               // 2.2+：无状态单例的 data 形态
}

fun eval(e: Expr): Double = when (e) {    // 无 else —— 编译器保证穷尽
    is Expr.Num -> e.v                    // is 分支自动智能转换
    is Expr.Add -> eval(e.l) + eval(e.r)
    is Expr.Mul -> eval(e.l) * eval(e.r)
    is Expr.Neg -> -eval(e.e)
    Expr.Zero -> 0.0                      // object 不需要 is
}
```

密封 = "子类型**全部**定义在本文件/本模块的继承层级"。效果：

1. **穷尽 when 不需要 else**——加 `Expr.Pow` 时上面这段直接编译错，指你去补分支。
2. 子类型**可以携带数据、可以有多个实例**——这是与枚举的本质差异。
3. 层级是编译期封闭的， outsiders 不能再加子类（sealed 的"封条"语义）。

这就是 Rust `enum Option<T> { Some(T), None }` 的 Kotlin 形态——**ADT：固定形状的数据 + 穷尽处理**。第 16 章会用密封异常做错误分类，22 章 Either，24 章的 Json AST 与 CLI Command 全是它。

`data object` vs `object`：前者生成漂亮的 toString（打印名字而非 `Expr$Zero@1f2a`）且可 equals——when 分支/日志场景用 data object。

## 8.4 状态机：密封类型的甜区

```kotlin
sealed interface OrderState {
    data object Created : OrderState
    data class Paid(val amount: Int) : OrderState
    data class Shipped(val tracking: String) : OrderState
    data object Done : OrderState
}

fun nextAction(s: OrderState): String = when (s) {
    OrderState.Created -> "等待支付"
    is OrderState.Paid -> "已收款 ${s.amount}，安排发货"      // 带数据分支
    is OrderState.Shipped -> "运输中（${s.tracking}），等签收"
    OrderState.Done -> "订单完成，可归档"
}
```

对照 Java 实现：常量类 + instanceof 链 + 手写 switch + 漏分支静默通过——每个环节 Kotlin 都收走了出错权。

## 8.5 枚举 vs 密封：选型表

| 维度 | enum | sealed |
|---|---|---|
| 常量携带数据 | ✓（构造参数，全常量同构） | ✓（各子类型任意字段，异构） |
| 实例数 | 每常量一个（单例） | 子类可多次实例化 |
| 定义位置 | 一个 enum 声明 | 本文件/模块多处（2.5 前同文件；本教程同文件写法） |
| when 穷尽 | ✓ | ✓ |
| 适用 | 状态码、方向、级别等**同构常量** | 表达式、事件、状态机等**异构数据** |

经验法则：**同一形状选 enum，不同形状选 sealed**。混合体（部分带负载）也是 sealed。

## 8.6 坑位清单

1. **穷尽 when 别习惯性写 else**——写了 else 编译器就不查漏了，安全网直接失效。新增分支想全量标红，删掉 else。
2. `values()` 每次分配新数组；用 `entries`。
3. 枚举构造参数不能引用静态成员（初始化顺序：常量先于 companion）。
4. 密封子类必须在**同一模块**（2.5 之前要求同一文件，且**同一包**）——跨模块想开放扩展用普通 interface，代价是失去穷尽检查。
5. `data object` 分支在 when 里写名字即可（`Expr.Zero ->`），写 `is Expr.Zero ->` 也行但多余。
6. when 作**表达式**时穷尽是硬错误；作语句时非穷尽只是 warning——本教程 `-Werror` 把它升级为错误，普通工程里别靠默认设置兜底，尽量让 when 表达式化。
