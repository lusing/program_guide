// 显式返回
fun findMax(arr: IntArray): Int {
    var max = arr[0]
    for (num in arr) {
        if (num > max) max = num
    }
    return max
}

// 隐式返回 (最后一个表达式)
fun findMin(arr: IntArray) = arr.minOrNull() ?: 0

// 跳过迭代
fun printEven(arr: IntArray) {
    for (num in arr) {
        if (num % 2 != 0) continue
        println(num)
    }
}

// 早退
fun validate(input: String?): Boolean {
    if (input == null) return false
    if (input.isEmpty()) return false
    return true
}
