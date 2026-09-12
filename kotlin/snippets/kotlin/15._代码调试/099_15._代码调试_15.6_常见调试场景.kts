// 使用PEEK操作符
fun debugChain() {
    listOf(1, 2, 3, 4, 5)
        .map { it * 2 }
        .also { println("After map: $it") }
        .filter { it > 5 }
        .also { println("After filter: $it") }
        .forEach { println("Item: $it") }
}

// 在 when 中调试
fun debugWhen(value: Any) = when (value) {
    is String -> {
        println("Debug: String with length ${value.length}")
        value.uppercase()
    }
    is Int -> {
        println("Debug: Int value $value")
        value * 2
    }
    else -> {
        println("Debug: Unknown type ${value.javaClass}")
        value.toString()
    }
}

// 使用反射调试
fun debugProperties(obj: Any) {
    println("Debugging properties of ${obj.javaClass.simpleName}")
    obj.javaClass.declaredFields.forEach { field ->
        field.isAccessible = true
        val value = field.get(obj)
        println("  ${field.name} = $value")
    }
}

// 使用 spy (模拟测试)
fun debugWithSpy() {
    val list = mutableListOf<String>()

    // 观察变化
    val observingList = object : MutableList<String> by list {
        override fun add(element: String): Boolean {
            println("Adding: $element")
            return super.add(element)
        }

        override fun remove(element: String): Boolean {
            println(" removing: $element")
            return super.remove(element)
        }
    }
}
