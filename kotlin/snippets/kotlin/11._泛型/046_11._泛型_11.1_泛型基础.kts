// 泛型类
class Box<T>(val value: T) {
    fun getValue(): T = value
}

val intBox = Box(123)
val stringBox = Box("Hello")

// 泛型函数
fun <T> wrap(value: T) = Box(value)
