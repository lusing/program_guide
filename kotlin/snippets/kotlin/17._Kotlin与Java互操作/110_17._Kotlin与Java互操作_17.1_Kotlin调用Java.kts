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
