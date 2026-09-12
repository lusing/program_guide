enum class DayOfWeek {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
}

enum class Operation(val symbol: String, val function: (Double, Double) -> Double) {
    ADD("+") { a, b -> a + b },
    SUBTRACT("-") { a, b -> a - b },
    MULTIPLY("*") { a, b -> a * b },
    DIVIDE("/") { a, b -> a / b }
}

// 使用
Operation.ADD.function(10.0, 5.0)  // 15.0
