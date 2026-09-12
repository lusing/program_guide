// 基本类
class Person {
    var name: String = ""
    var age: Int = 0
}

// 构造函数
class Person(val name: String, var age: Int)

// 主构造函数与初始化块
class Person(
    val name: String,
    var age: Int,
    val city: String = "Unknown"
) {
    init {
        println("Person created: $name")
    }
}

// 次构造函数
class Person(val name: String) {
    var age: Int = 0

    constructor(name: String, age: Int) : this(name) {
        this.age = age
    }
}
