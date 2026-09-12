// 非空类型
var name: String = "Kotlin"
name = null  // 编译错误

// 可空类型
var nullableName: String? = null
nullableName = "Kotlin"

// 安全调用操作符
val length = nullableName?.length

// Elvis 操作符
val len = nullableName?.length ?: 0

// 不为空断言
val len2 = nullableName!!.length  // 为 null 时抛出异常

// 安全转换
val num: Int? = "123" as? Int
