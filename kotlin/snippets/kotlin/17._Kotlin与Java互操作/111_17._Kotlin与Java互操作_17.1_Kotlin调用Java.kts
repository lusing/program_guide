import java.util.ArrayList
import java.util.HashMap

// 使用 Java 集合
val list = ArrayList<String>()
list.add("A")
list.add("B")

val map = HashMap<String, Int>()
map["one"] = 1
map["two"] = 2

// Java 集合与 Kotlin 集合转换
val kotlinList = list.toList()  // 转为 Kotlin 只读列表
val mutableKotlinList = list.toMutableList()

// 注意：Java 集合在 Kotlin 中是可变的
list.add("C")  // 允许修改
