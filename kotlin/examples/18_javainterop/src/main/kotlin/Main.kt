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
