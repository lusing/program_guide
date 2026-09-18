# 23 · 类型安全 DSL ⭐

> 对应示例：`examples/23_dsl/`（HTML builder + @DslMarker + 中缀断言 DSL + invoke 约定）
>
> Gradle KTS、kotlinx.html、Compose——Kotlin 生态最气派的 API 全是 DSL。
> 原料只有三种：带接收者的 lambda、@DslMarker、命名约定。

## 23.1 DSL 长什么样

```kotlin
val page = html {
    attr("lang", "zh")
    body {
        h1 { text = "Kotlin DSL" }
        div {
            attr("class", "content")
            p { text = "带接收者的 lambda 造出层级结构" }
        }
    }
}
page.render()     // <html lang="zh"><body><h1>Kotlin DSL</h1>...
```

没有引号、没有闭合标签、结构错误（括号不配、p 里塞 h1）**编译期**就报——对比字符串拼 HTML（运行时才发现 `<dic>` 打错）。这就是"类型安全构建器"。

## 23.2 原料一：带接收者的 lambda（12 章 5 节的进阶）

```kotlin
class Tag(val name: String) : Node {
    private val children = mutableListOf<Node>()
    fun tag(name: String, block: Tag.() -> Unit = {}) {   // block 的接收者 = 新建的子标签
        val t = Tag(name)
        t.block()                                          // 执行时 this = t
        children += t
    }
    fun body(block: Tag.() -> Unit) = tag("body", block)   // 每种标签一个入口
    fun div(block: Tag.() -> Unit) = tag("div", block)

    var text: String = ""
        set(v) { children += Node.Text(v) }                // 赋值即追加文本节点
}

fun html(block: Tag.() -> Unit): Tag = Tag("html").apply(block)   // 顶层入口
```

机制：`t.block()` 在执行 lambda 的每一行时，隐式接收者 `this` 都是 `t`——所以块里写 `p { ... }`、`text = "..."` 不需要任何前缀。**嵌套 lambda 的接收者天然成栈**：内层块看不到外层的 this（除非被 DslMarker 之外的原因遮蔽——见下）。

## 23.3 原料二：@DslMarker——封锁作用域泄漏

```kotlin
@DslMarker
annotation class HtmlDsl

@HtmlDsl
class Tag(val name: String) : Node { ... }
```

没有 DslMarker 的隐患：

```kotlin
html {
    body {
        attr("x", "1")      // 这行调的是【body 的】attr 还是【html 的】？——隐式 this 二义
    }
}
```

内层 lambda 里**裸调用**会解析到最近的接收者，但外层 this 依然**隐式可达**——`body { html 层的方法() }` 编译器不管，结构写错静默通过。

加了 `@HtmlDsl` 后：**同标记的接收者只有最近一个可用**，外层的隐式调用直接编译错——想用外层就必须显式。这是把"DSL 结构约定"升级为"编译器规则"的一个注解。

## 23.4 原料三：命名约定（infix / operator invoke / get）

```kotlin
// infix：断言 DSL
infix fun <T> T.should(expected: T): T {
    check(this == expected) { "断言失败: 期望 $expected, 实际 $this" }
    return this
}
infix fun <T> T.eq(expected: T) = should(expected)

42 should 42            // 读起来是句子
1 + 1 eq 2

// operator invoke：对象当函数调用
class Router {
    private val routes = mutableListOf<String>()
    operator fun invoke(path: String): String { routes += path; return "已注册 $path" }
}
val router = Router()
router("/home")         // Router 实例直接调用！
```

`invoke` 约定的妙处：调用方分不清"这是函数还是可调用对象"——配置对象、路由表、构建器入口都能伪装成函数。

## 23.5 实战：类型安全构建器（依赖声明）

```kotlin
class Deps {
    val list = mutableListOf<String>()
    fun implementation(id: String) { list += "implementation: $id" }
    fun testImplementation(id: String) { list += "test: $id" }
}
fun dependencies(block: Deps.() -> Unit): List<String> = Deps().apply(block).list
```

```kotlin
dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    testImplementation("kotlin-test")
}
```

Gradle 的 `dependencies { }` 块就是这个模式的工业级版本（ReceiverScope + DslMarker 遍布 build.gradle.kts）。

## 23.6 为什么 DSL 在 Kotlin 而不在 Java

| 能力 | Java | Kotlin |
|---|---|---|
| 带接收者的 lambda | ✘（this 不可注入） | ✓ 核心机制 |
| 顶层函数 + 扩展 | ✘ | ✓（23.5 的入口一行） |
| infix / invoke / get 约定 | ✘（只能方法链） | ✓ |
| @DslMarker | ✘ | ✓ |

Java 的极限是 Builder 方法链（`new Html().body().p("x").end()...`）——`end()` 配对错误运行时才炸；Kotlin 的结构由**嵌套语法本身**保证。Compose 更进一步：DSL 即语言（@Composable 函数 + 编译器插件）。

## 23.7 设计自己的 DSL：检查表

1. **一个入口函数**（`html { }` / `dependencies { }`）：apply 一个容器对象。
2. **容器内只暴露该层的动词**（div/p/attr——方法不是塞越多越好）。
3. **需要层级约束就上 @DslMarker**（同层标记类，防跨层调用）。
4. **叶子用属性赋值**（`text = "..."`）而不是方法调用——读起来像声明。
5. 产物不可变（render 输出 / toList 快照），构建期随便可变（buildList 同思路，10 章）。

## 23.8 坑位清单

1. **不标 DslMarker 的 DSL = 约定型安全**——跨层调用编译器不管，写复杂结构迟早翻车；公开 DSL 必标。
2. @DslMarker 只拦**隐式**外层接收者——显式拿到的引用（把外层 Tag 存变量传进去）拦不住。
3. DSL 函数返回值要克制：块内语句的返回值没人接（`p { text = "x" }` 返回 Unit 惯例），别让块内 API 鼓励返回值链。
4. infix 优先级介于比较与算术之间——DSL 表达式里混算术要加括号（05 章坑 3 重申）。
5. **invoke 约定别滥用**：对象可调用是惊喜不是预期——只在"这东西语义上就是函数"（路由、配置求值）时用。
6. DSL 层级太深（>4 层）时编译错误信息会很难读——考虑拆成多个小 DSL 组合。
