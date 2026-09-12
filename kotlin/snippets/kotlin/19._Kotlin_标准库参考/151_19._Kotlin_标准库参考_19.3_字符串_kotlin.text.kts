val str = "hello kotlin"

// 大小写
str.uppercase()
str.lowercase()
str.capitalize()
str.decapitalize()

// 格式化
"Hello %s".format("World")
"Pi: %.2f".format(Math.PI)

// 分割
"a,b,c".split(",")
"hello world".split(" ")
"one,two,three".split(",", limit = 2)

// 连接
listOf("a", "b", "c").joinToString()
listOf("a", "b", "c").joinToString(", ")
listOf("a", "b", "c").joinToString(prefix = "[", suffix = "]")

// 去除
"  hello  ".trim()
"  hello  ".trimStart()
"  hello  ".trimEnd()
"---hello---".trim('-')
