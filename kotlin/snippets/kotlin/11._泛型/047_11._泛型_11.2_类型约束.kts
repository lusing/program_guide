// 上限约束
fun <T : Number> sumOfSquares(list: List<T>): Double {
    return list.map { it.toDouble() * it.toDouble() }.sum()
}

// 多重约束
fun <T> parsePair(
    pair: Pair<String, String>
): T where T : Number, T : Comparable<T> {
    return pair.first.toInt() as T
}
