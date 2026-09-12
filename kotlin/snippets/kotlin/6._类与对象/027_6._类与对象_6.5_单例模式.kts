// object 声明单例
object Singleton {
    fun doSomething() = println("Done")
}

Singleton.doSomething()

// 伴生对象
class MyClass {
    companion object {
        const val VERSION = "1.0"
        fun create() = MyClass()
    }
}

MyClass.VERSION
MyClass.create()
