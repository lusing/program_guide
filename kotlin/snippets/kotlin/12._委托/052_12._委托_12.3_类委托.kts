interface Shape {
    fun draw()
}

class Circle : Shape {
    override fun draw() = println("Circle")
}

// 类委托
class DecoratedShape(private val shape: Shape) : Shape by shape {
    fun decorate() = println("Decorated")
}

val circle = DecoratedShape(Circle())
circle.draw()  // 被委托
circle.decorate()
