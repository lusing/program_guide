// 抽象类
abstract class Shape {
    abstract fun area(): Double
    fun description() = "I am a shape"
}

class Circle(val radius: Double) : Shape() {
    override fun area() = Math.PI * radius * radius
}

// 接口
interface Flyable {
    fun fly()
    fun land() { println("Landing") }  // 默认实现
}

class Bird : Flyable {
    override fun fly() = println("Flying")
}

// 多重继承
class SuperBird : Animal("Bird"), Flyable {
    override fun makeSound() = println("Squawk")
    override fun fly() = println("Flying high")
}
