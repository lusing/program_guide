// println 调试
fun complexCalculation(a: Int, b: Int): Int {
    println("Input: a=$a, b=$b")
    val result = a * b + 10
    println("Result: $result")
    return result
}

// 使用格式化输出
val pi = 3.14159265359
printf("Pi = %.2f\n", pi)  // Pi = 3.14
format("Name: %s, Age: %d", "Alice", 25)
