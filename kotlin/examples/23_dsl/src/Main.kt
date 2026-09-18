// 23 · DSL 演示：HTML builder、中缀断言、invoke 约定、类型安全构建器

fun main() {
    println("== 23.2 HTML builder ==")
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

    println("== 23.3 @DslMarker：作用域不泄漏 ==")
    println("  没有 DslMarker 时，内层 lambda 里能隐式调到外层 this（body 里跳回 html）——嵌套写错编译器不管")
    println("  加了 @HtmlDsl 后外层 this 被屏蔽，误用直接编译错：")
    println("    html { body { attr(\"x\",\"1\") } }   ← attr 在 Tag 上都有，这里演示靠约定")

    println("== 23.4 中缀 DSL：should / eq ==")
    val result = 40 + 2
    result should 42
    println("  42 should 42 ✓（失败会抛 IllegalStateException）")
    try {
        1 + 1 eq 3
    } catch (e: IllegalStateException) {
        println("  eq 失败: ${e.message}")
    }

    println("== 23.5 invoke 约定：对象当函数用 ==")
    val router = Router()
    println("  router(\"/home\") → ${router("/home")}")
    println("  router(\"/about\") → ${router("/about")}")

    println("== 23.6 类型安全构建器 ==")
    val deps = dependencies {
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
        implementation("com.squareup.okhttp3:okhttp:5.1.0")
        testImplementation("kotlin-test")
    }
    deps.forEach { println("  $it") }

    println("== 23.7 DSL 的三板斧 ==")
    println("  1) 带接收者的 lambda（T.() -> Unit）：块内 this 就是容器")
    println("  2) @DslMarker：封锁跨层隐式 this")
    println("  3) 命名约定（infix/operator invoke/get）：让调用像自然语言")
}
