// Stacktrace 分析
/*
Exception in thread "main" java.lang.NullPointerException
    at StringKt.main(string.kt:10)
    at StringKt.main(string.kt:1)
*/

// 定位空指针
data class User(val name: String, val address: Address?)
data class Address(val city: String)

fun printUserCity(user: User?) {
    // 可能的空指针
    // println(user!!.address!!.city)

    // 安全调用
    user?.address?.city?.let { println(it) }

    // 使用 require 或 check
    fun processUser(user: User?) {
        val validUser = user ?: throw IllegalArgumentException("User cannot be null")
        val city = validUser.address?.city
            ?: throw IllegalStateException("Address city is missing")
        println(city)
    }
}
