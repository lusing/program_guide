// 遍历数组
val arr = arrayOf(1, 2, 3)
for (item in arr) {
    println(item)
}

// 带索引
for ((index, value) in arr.withIndex()) {
    println("index: $index, value: $value")
}

// 遍历区间
for (i in 1..5) {
    println(i)
}

// 逆序遍历
for (i in 5 downTo 1) {
    println(i)
}

// 指定步长
for (i in 1..10 step 2) {
    println(i)
}
