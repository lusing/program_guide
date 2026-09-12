// open 类可被继承
open class Animal(val name: String) {
    open fun makeSound() = println("Unknown sound")
}

class Dog(name: String) : Animal(name) {
    override fun makeSound() {
        println("Woof!")
    }
}

// super 调用
class Cat(name: String) : Animal(name) {
    override fun makeSound() {
        super.makeSound()
        println("Meow!")
    }
}
