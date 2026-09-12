// 扩展函数是静态解析的
open class Animal
class Dog : Animal()

fun Animal.speak() = "Animal sound"
fun Dog.speak() = "Woof!"

fun makeAnimalSpeak(animal: Animal) {
    println(animal.speak())  // Animal sound，不是多态
}
