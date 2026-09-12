// 数据类自动生成 equals, hashCode, toString 等
data class User(val id: Int, val name: String, val email: String)

val user = User(1, "Alice", "alice@example.com")
println(user)  // User(id=1, name=Alice, email=alice@example.com)

// copy 方法
val user2 = user.copy(name = "Bob")

// 解构声明
val (id, name, email) = user
