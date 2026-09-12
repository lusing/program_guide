// is 检查
fun process(obj: Any) {
    if (obj is String) {
        println(obj.uppercase())
    }
}

// 智能转换
fun process2(obj: Any) {
    if (obj is String) {
        // 自动转换为 String
        println(obj.length)
    } else if (obj is Int) {
        println(obj + 1)
    }
}

// as? 安全转换
val num: Int? = "123" as? Int
