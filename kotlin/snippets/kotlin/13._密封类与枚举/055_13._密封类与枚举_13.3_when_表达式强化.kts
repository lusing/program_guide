// when 必须 exhaustive
fun evaluate(expr: Any): String = when (expr) {
    is Int -> "Integer: $expr"
    is String -> "String: $expr"
    is List<*> -> "List with ${expr.size} elements"
    else -> "Unknown"
}

// 带条件的 when
fun describe(number: Int) = when {
    number < 0 -> "Negative"
    number == 0 -> "Zero"
    number % 2 == 0 -> "Even"
    else -> "Odd"
}
