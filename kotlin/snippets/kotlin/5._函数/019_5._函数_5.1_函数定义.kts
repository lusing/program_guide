// 基本函数
fun greet(name: String): String {
    return "Hello, $name"
}

// 单表达式函数
fun add(a: Int, b: Int) = a + b

// 默认参数
fun hello(name: String = "World") = "Hello, $name"

// 谰用
hello()           // Hello, World
hello("Alice")    // Hello, Alice

// 命名参数
fun createPerson(name: String, age: Int, city: String) { /* ... */ }
createPerson(age = 25, name = "Bob", city = "Beijing")

// 可变参数
fun varargs(vararg numbers: Int) {
    numbers.forEach { println(it) }
}
varargs(1, 2, 3, 4, 5)

// 广播操作符
val arr = intArrayOf(1, 2, 3)
varargs(*arr)
