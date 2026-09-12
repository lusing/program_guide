// 扩展属性 (不能有字段，只能用 getter/setter)
val String.lastIndex: Int
    get() = this.length - 1

val List<Int>.sum: Int
    get() = this.reduce { acc, v -> acc + v }
