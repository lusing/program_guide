enum class Color(val rgb: Int) {
    RED(0xFF0000),
    GREEN(0x00FF00),
    BLUE(0x0000FF)
}

// 使用
val color = Color.RED
println(color.rgb)  // 16711680

// 枚举函数
Color.values()           // 所有枚举值
Color.valueOf("RED")     // 通过名称获取
Color.RED.ordinal        // 索引位置
Color.RED.name           // 名称

// 自定义函数
enum class Operation {
    ADD { override fun eval(a: Int, b: Int) = a + b },
    SUB { override fun eval(a: Int, b: Int) = a - b };

    abstract fun eval(a: Int, b: Int): Int
}
