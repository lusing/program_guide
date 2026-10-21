# 23 · 类型安全 DSL ⭐

> 对应示例：`examples/23_dsl/`——一个五脏俱全的 HTML builder（`src/Html.kt`），加三个 DSL 小件：
> 中缀断言 `should/eq`、可调用对象 `Router`、Gradle 风格的 `dependencies { }` 构建器；
> `src/Main.kt` 是演示驱动，本章所有输出引自 `expected.txt`。
>
> Gradle KTS、kotlinx.html、Compose——Kotlin 生态里最气派的 API 全是 DSL。
> 原料只有三种：**带接收者的 lambda、@DslMarker、命名约定**。
> 本章把三种原料逐一拆开讲透，再组装成两个能跑的 DSL。

DSL（Domain-Specific Language，领域特定语言）是"为某个狭窄领域定做的小语言"。
SQL 是数据库领域的 DSL，正则表达式是文本匹配的 DSL——它们不是通用语言，
但在自己的领域里比通用语言**好写得不像话**。
Kotlin 不发明新语法，而是用现有的语言特性把"调用 Kotlin 代码"伪装成"写一门小语言"，
这就是**内部 DSL**（internal DSL）。能做到这件事，靠的不是一个语法糖，
而是三个互相咬合的机制，本章一节拆一个。

## 23.1 DSL 长什么样

先看成品。下面这段代码引用自 `src/Main.kt`，它在**构建**一棵 HTML 树：

```kotlin
val page = html {
    attr("lang", "zh")
    body {
        h1 { text = "Kotlin DSL" }
        div {
            attr("class", "content")
            p { text = "带接收者的 lambda 造出层级结构" }
            p { text = "编译期就检查出结构错误——括号、闭合标签不存在写错的可能" }
        }
        div { /* 空块 */ }
    }
}
println(page.render())
```

注意这段代码的"不像 Kotlin"之处：没有分号当然不稀奇，关键是它读起来像**声明一份文档**，
而不是"调用一串函数"。`body { }` 嵌在 `html { }` 里，`p { }` 嵌在 `div { }` 里，
嵌套关系就是文档的树形关系。`render()` 把它序列化成字符串，输出（引自 `expected.txt` 第 2 行）：

```text
<html lang="zh"><body><h1>Kotlin DSL</h1><div class="content"><p>带接收者的 lambda 造出层级结构</p><p>编译期就检查出结构错误——括号、闭合标签不存在写错的可能</p></div><div/></body></html>
```

对照输入和输出，能看出三件值得注意的事：

1. **空块渲染成自闭合标签**——`div { /* 空块 */ }` 产出了 `<div/>` 而不是 `<div></div>`。
   这是渲染器的实现选择，后面看 `render()` 源码时会对上号。
2. **属性按插入顺序出现**——`lang="zh"` 出现在 `<html` 之后、子元素之前，
   说明属性容器保留了插入顺序（用的是 `linkedMapOf`，马上会看到）。
3. **没有引号地狱**——整段构建代码里没有一个 HTML 引号需要转义。

为什么费这个劲？对比两种传统写法就明白了：

- **字符串拼接**：`"<div class=\"content\">" + text + "</div>"`——标签打错成 `<dic>`、
  闭合标签漏写、属性忘引号，全都到**运行时**、甚至到浏览器里才暴露。
- **Java 式 Builder 方法链**：`new Html().body().h1("x").end().div().end()...`——
  每个 `end()` 对应一层回退，配对错了编译器照样放行；而且方法链是**线性**的，
  表达树形结构全靠缩进自觉。

类型安全 DSL 把结构校验挪到**编译期**：`p { }` 里塞不存在的函数、括号不配对、
层级写错，编译器直接拒绝。这叫**类型安全构建器**（type-safe builder）模式，
是 Kotlin DSL 的教科书形态。

## 23.2 原料一：带接收者的 lambda（12 章 5 节的进阶）

12 章学过 `T.() -> Unit` 这个类型，当时的说法是"lambda 带着一个 this 跑"。
现在把它当成**造 DSL 的机床**重新看一遍。`src/Html.kt` 的核心类 `Tag` 逐段引用：

```kotlin
@HtmlDsl
class Tag(val name: String) : Node {
    private val children = mutableListOf<Node>()
    private val attrs = linkedMapOf<String, String>()

    var text: String = ""
        set(v) { children += Node.Text(v) }        // 赋值即追加文本节点

    fun attr(k: String, v: String) { attrs[k] = v }
```

一个 `Tag` 实例代表一个 HTML 元素：`children` 装子节点（列表可增长），
`attrs` 装属性——注意用的是 `linkedMapOf`，所以 23.1 的输出里属性按插入顺序排列，
这不是巧合而是容器选择的结果。

`text` 是一个**有自定义 setter 的属性**：写 `text = "..."` 时并没有存字符串，
而是 `children += Node.Text(v)`——追加一个文本子节点。这是 DSL 设计里的一个惯用手法：
**把"看起来像赋值"的语法翻译成"实际上是追加"的行为**，于是 `h1 { text = "Kotlin DSL" }`
读起来是声明，跑起来是建树。顺带一提，这也意味着写两次 `text` 会追加两个文本节点，
而不是后者覆盖前者——DSL 使用者的直觉会被这个细节坑到，坑位清单里再谈。

往下是建树的关键方法：

```kotlin
    /** 嵌套标签：block 的接收者就是新建的子标签 */
    fun tag(name: String, block: Tag.() -> Unit = {}) {
        val t = Tag(name)
        t.block()
        children += t
    }

    fun body(block: Tag.() -> Unit) = tag("body", block)
    fun div(block: Tag.() -> Unit) = tag("div", block)
    fun p(block: Tag.() -> Unit) = tag("p", block)
    fun h1(block: Tag.() -> Unit) = tag("h1", block)
```

把 `tag` 的三行执行过程放慢：调用 `body { attr("class", "x") }` 时——

1. `val t = Tag(name)`：先造一个**新的** `Tag("body")`，此刻它还是空树。
2. `t.block()`：以 `t` 为接收者执行传进来的 lambda。
   `block` 的类型是 `Tag.() -> Unit`，所以这行等价于 `block.invoke(t)`——
   lambda 体里的 `attr("class", "x")` 没有前缀，解析到隐式 `this`，也就是 `t`。
   **"接收者"不是语法装饰，是 lambda 被调用时注入的那个 this 对象。**
3. `children += t`：block 跑完，`t` 已经装满自己的子树，挂到父节点的孩子列表里。

`body`/`div`/`p`/`h1` 四个入口只是把 `tag("body", ...)` 换个名字，
让调用方写 `body { }` 而不是 `tag("body") { }`——**方法名即标签名**，这是"像一门语言"的第一步。
给 `block` 参数默认值 `{ }` 是第二步：`div { }` 空块合法，于是 23.1 里的空 div 能编译。

渲染器 `render()` 和节点类型 `Node`：

```kotlin
    override fun render(): String = buildString {
        append("<$name")
        for ((k, v) in attrs) append(" $k=\"$v\"")
        if (children.isEmpty()) { append("/>") } else {
            append(">")
            for (c in children) append(c.render())
            append("</$name>")
        }
    }
}

sealed interface Node {
    fun render(): String
    data class Text(val value: String) : Node {
        override fun render(): String = value
    }
}
```

`render()` 是递归的：标签节点渲染自己的开标签、递归渲染每个孩子、渲染闭标签；
文本节点（`Node.Text`）渲染自己就是字面值。`children.isEmpty()` 时输出 `<name/>`——
23.1 输出末尾那个 `<div/>` 就是这一行产生的。
字符串拼装用的是标准库的
[`buildString`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/build-string.html)：
块内拿到一个 `StringBuilder` 接收者，`append` 都不带前缀——
看，**标准库自己就在用带接收者的 lambda**，这模式不是框架专利。

最后是顶层入口：

```kotlin
fun html(block: Tag.() -> Unit): Tag = Tag("html").apply(block)
```

一行做完三件事：造根节点、以它为接收者跑用户的 block、把根节点返回。
**每个 DSL 都有一个这样的顶层入口函数**，它是"语言"与"宿主 Kotlin"之间的海关。

回头看 23.1 的构建代码，现在每一行都能对号入座：`html { }` 调入口；
`attr("lang", "zh")` 调根节点的 `attr`；`body { }` 调 `Tag.body`，
内部走 `tag` 的三步；`h1 { text = "Kotlin DSL" }` 里 `text` 的隐式 `this` 是那个 `h1` 节点。
**嵌套 lambda 的接收者天然形成一个栈**：每一层块的 `this` 是各层的 `Tag`，
内层块的隐式接收者是内层 `Tag`——但外层的 `this` 还在词法作用域里"挂着"，
这就引出了下一种原料。

## 23.3 原料二：@DslMarker——封锁作用域泄漏

上一节说"内层块的隐式 this 是内层 Tag"，这句话只对了一半。真相是：
**内层 lambda 的词法作用域里，外层接收者依然隐式可达**。
成员解析的顺序是"最近接收者优先"，所以当内外层都有 `attr` 方法时，
`body { attr("x", "1") }` 碰巧解析到 body——靠优先级**碰对了**；
但如果写了一个只有外层才有的方法，或者优先级不如你意，就会在 `body` 块里
**悄悄改到 `html` 节点上**，编译器一声不吭。层级越深，这类"写到错的层"的 bug 越难查。

`Main.kt` 里对此的演示只是三行说明文字（这种 bug 无法在运行时演示——
加了标记后它根本无法编译）：

```kotlin
println("== 23.3 @DslMarker：作用域不泄漏 ==")
println("  没有 DslMarker 时，内层 lambda 里能隐式调到外层 this（body 里跳回 html）——嵌套写错编译器不管")
println("  加了 @HtmlDsl 后外层 this 被屏蔽，误用直接编译错：")
println("    html { body { attr(\"x\",\"1\") } }   ← attr 在 Tag 上都有，这里演示靠约定")
```

解法是把"约定"升级成"编译器规则"，这就是标准库注解
[@DslMarker](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-dsl-marker/index.html)
存在的原因。用法是两步（引自 `Html.kt` 开头）：

```kotlin
@DslMarker        // 作用域标记：外层接收者的隐式 this 不再"漏"进内层 lambda
annotation class HtmlDsl

@HtmlDsl
class Tag(val name: String) : Node {
```

第一步，定义一个**自己**的注解并用 `@DslMarker` 标注它——注意 `@DslMarker` 标注的是
注解类本身，它是一种"元注解"。第二步，把你定义的注解（这里是 `@HtmlDsl`）标到
DSL 的接收者类上。

效果规则一句话：**同一个标记注解管辖的多个隐式接收者，只有最近的一个可用**。
`html { body { ... } }` 里，`html` 节点和 `body` 节点都是 `@HtmlDsl` 标记的 `Tag`，
于是在 `body { }` 块内，`html` 节点的成员**不再能隐式调用**——
想用它必须显式拿到引用。误写直接变成编译错误，错误信息还会告诉你
这是 DslMarker 的作用域限制。一个注解，把"DSL 结构约定"从口头约定变成了类型系统的规则。

两个细节要心里有数：

- DslMarker 管的是**隐式**接收者。如果通过别的方式拿到了外层对象的显式引用
  （比如把外层 `Tag` 存进变量再传进内层），显式调用它编译器拦不住——它防的是"手滑"，
  不是"存心"。
- 标记按**注解类型**分组，不按类分组。两个不同的类只要标了同一个 `@HtmlDsl`，
  就互相屏蔽；标不同标记的接收者互不干扰——组合多个 DSL（比如 HTML 里嵌 SQL 构建器）
  时靠这个区分。

## 23.4 原料三：命名约定（infix / operator invoke）

第三种原料不是某个特性，而是一组**让调用点读起来像自然语言**的约定。
Kotlin 允许给特定名字的函数赋予特殊调用语法，DSL 作者最常用的是 `infix` 和 `operator fun invoke`。

**infix：把函数调用变成中缀表达式。** `Html.kt` 里定义了一个迷你断言 DSL：

```kotlin
infix fun <T> T.should(expected: T): T {
    check(this == expected) { "断言失败: 期望 $expected, 实际 $this" }
    return this
}

infix fun <T> T.eq(expected: T) = should(expected)
```

`infix` 修饰的**单参数**成员函数或扩展函数，调用时可以省掉点和括号：
`result should 42` 就是 `result.should(42)`。这是 kotest、mockk 等库里
`x shouldBe 3`、`a shouldContain b` 风格的全部秘密——没有任何编译器魔法，
只是一个中缀扩展函数。`should` 内部用标准库的
[`check`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/check.html)
做断言，失败抛 `IllegalStateException`；返回 `this` 是为了允许继续链式中缀。

`Main.kt` 里的演示：

```kotlin
val result = 40 + 2
result should 42
println("  42 should 42 ✓（失败会抛 IllegalStateException）")
try {
    1 + 1 eq 3
} catch (e: IllegalStateException) {
    println("  eq 失败: ${e.message}")
}
```

`40 + 2` 等于 42，第一句静默通过；`1 + 1 eq 3` 失败被 catch 住。输出（引自 `expected.txt`）：

```text
== 23.4 中缀 DSL：should / eq ==
  42 should 42 ✓（失败会抛 IllegalStateException）
  eq 失败: 断言失败: 期望 3, 实际 2
```

注意失败消息 "期望 3, 实际 2"——`check` 的 lazy message 只在失败时才求值，
成功路径零字符串开销。写自己的断言 DSL 时照抄这个习惯。

**operator invoke：让对象本身可调用。** 还是 `Html.kt`：

```kotlin
class Router {
    private val routes = mutableListOf<String>()
    operator fun invoke(path: String): String {
        routes += path
        return "已注册 $path（累计 ${routes.size} 条）"
    }
}
```

`operator fun invoke` 是一个命名约定：定义了它，实例就能**像函数一样被调用**——
`router("/home")` 编译成 `router.invoke("/home")`。`Main.kt` 的演示：

```kotlin
val router = Router()
println("  router(\"/home\") → ${router("/home")}")
println("  router(\"/about\") → ${router("/about")}")
```

输出：

```text
== 23.5 invoke 约定：对象当函数用 ==
  router("/home") → 已注册 /home（累计 1 条）
  router("/about") → 已注册 /about（累计 2 条）
```

两次调用共享同一个 `routes` 列表，所以累计数从 1 涨到 2——
这个细节恰好说明了 invoke 约定的本质：**`router` 是一个带着内部状态的对象，
只是调用语法伪装成了函数**。调用方分不清"这是函数还是可调用对象"，
这正是 DSL 想要的：路由表、配置求值器、构建器入口，凡"语义上就是个函数，
但又需要藏点状态"的东西，都适合 invoke。反过来，语义上不是函数的东西
硬上 invoke，就是给人惊喜而不是便利了（坑位清单第 5 条）。

## 23.5 实战：类型安全构建器（依赖声明）

三种原料凑齐，看一个贴近平时的例子——Gradle 的 `dependencies { }` 块。
`Html.kt` 末尾是它的微缩版：

```kotlin
class Deps {
    val list = mutableListOf<String>()
    fun implementation(id: String) { list += "implementation: $id" }
    fun testImplementation(id: String) { list += "test: $id" }
}
fun dependencies(block: Deps.() -> Unit): List<String> = Deps().apply(block).list
```

模式与 `html { }` 完全同构：`Deps` 是容器（动词只有 `implementation` 和
`testImplementation` 两个），`dependencies` 是顶层入口——造容器、
以它为接收者跑 block、取出产物。`Main.kt` 里的调用：

```kotlin
val deps = dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    implementation("com.squareup.okhttp3:okhttp:5.1.0")
    testImplementation("kotlin-test")
}
deps.forEach { println("  $it") }
```

输出：

```text
== 23.6 类型安全构建器 ==
  implementation: org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2
  implementation: com.squareup.okhttp3:okhttp:5.1.0
  test: kotlin-test
```

真实的 `build.gradle.kts` 里那个 `dependencies { }` 就是这个模式的工业级版本：
一个带接收者的配置块，容器上挂着一组动词，@DslMarker 遍布其中防止跨块误调。
看懂了这个 10 行的微缩版，Gradle 构建脚本就从"天书"变回"普通 Kotlin 代码"——
**这也是学 DSL 最大的现实收益：生态里一半的配置文件都是它**。

## 23.6 为什么 DSL 在 Kotlin 而不在 Java

| 能力 | Java | Kotlin |
|---|---|---|
| 带接收者的 lambda | ✘（this 不可注入） | ✓ 核心机制 |
| 顶层函数 + 扩展 | ✘ | ✓（入口函数一行搞定） |
| infix / invoke / get 约定 | ✘（只能方法链） | ✓ |
| @DslMarker | ✘ | ✓ |

四行表格背后是同一个事实：**Java 无法把 `this` 交给 lambda 的作者控制**。
Java 的 lambda 词法 `this` 永远是外围类实例，没有办法说"执行这个 lambda 时 this 换成那个对象"，
于是嵌套结构无从谈起，剩下的只有方法链。而方法链是线性的，
树形层级只能靠 `end()`/`build()` 手工回退，配对错了运行时才炸；
Kotlin 的嵌套 lambda 用**语法本身的嵌套**保证树形——括号都配不上时编译就过不去。

Compose 把这个思路推到极限：DSL 即语言，`@Composable` 函数配合编译器插件，
"界面长什么样"直接用 Kotlin 代码的嵌套结构描述。它仍是本章三种原料的延伸，
只是多了编译器参与。

## 23.7 设计自己的 DSL：检查表

把本章的机制反推成设计步骤，写一个自己的 DSL 时按这张表走：

1. **一个顶层入口函数**（`html { }`、`dependencies { }`）：造容器、`apply` 用户的块、返回产物。
   入口是 DSL 的全部"语法"，保持一行能写完。
2. **容器内只暴露该层的动词**（`div`/`p`/`attr`——`Deps` 只有 `implementation`/`testImplementation`）。
   方法不是塞得越多越好；动词表就是这门小语言的"关键字表"，越少越像语言。
3. **需要层级约束就上 @DslMarker**：只要块会嵌套、且内外层有同名或易混的成员，就定义
   自己的标记注解标到接收者类上。公开的 DSL 必标，私用的可以暂缓。
4. **叶子值用属性赋值**（`text = "..."`）而不是方法调用——读起来像声明。
   代价是 setter 里可以藏行为（追加而非覆盖），要在文档里写明。
5. **构建期可变、产物不可变**：`Tag` 的 `children` 随便改，`render()` 产出的字符串、
   `dependencies` 返回的 `List` 是快照。这与 10 章 `buildList` 的思路一致。

## 23.8 坑位清单

1. **不标 DslMarker 的嵌套 DSL = 约定型安全**。内外层成员撞名时靠"最近接收者优先"碰巧选对，
   撞不上时静默写错层；层级一深必然翻车，公开 DSL 必标。
2. **@DslMarker 只拦隐式接收者**。显式拿到的引用（外层对象存变量传进内层）拦不住——
   它防手滑不防存心，别把它当安全边界。
3. **`text =` 的 setter 是追加不是覆盖**。本章 `Tag.text` 每赋值一次就追加一个文本节点，
   写两次 `text` 得到两段文本——DSL 使用者的直觉是"后者覆盖前者"，
   要么在文档里写明，要么换成函数。
4. **infix 优先级是个坑**：中缀函数的优先级低于算术、高于比较和 `&&`/`||`，
   `1 + 1 eq 2` 能算对纯属分组幸运，DSL 表达式里混运算一律加括号（05 章坑 3 重申）。
5. **invoke 约定别滥用**。对象可调用是惊喜不是预期——只在"这东西语义上就是函数"
   （路由注册、配置求值）时用；给集合类、数据类加 invoke，读到调用点的人会愣住。
6. **嵌套超过四层，编译错误信息会很难读**。类型安全构建器的错误消息会带上完整的
   接收者类型链，层级一深就成了天书——这时把大 DSL 拆成几个小 DSL 组合，
   比硬撑着用一个强。

---

上一章：[22 函数式](22-functional.md) · 下一章：[24 ⭐实战：ktodo](24-todo.md)
