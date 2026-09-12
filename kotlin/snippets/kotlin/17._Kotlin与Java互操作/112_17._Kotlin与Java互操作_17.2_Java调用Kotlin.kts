// Kotlin 类
class KotlinClass(val name: String) {
    fun greet(): String = "Hello, $name"
    
    companion object {
        const val VERSION = "1.0"
        
        @JvmStatic
        fun create(name: String) = KotlinClass(name)
    }
}
