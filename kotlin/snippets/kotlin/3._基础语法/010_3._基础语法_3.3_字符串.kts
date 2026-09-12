// 字符串模板
val name = "Alice"
val age = 25
println("Name: $name, Age: $age")

// 表达式模板
println("Next year: ${age + 1}")

// 原始字符串 (multiline strings)
val html = """
    <html>
        <body>
            <p>Hello!</p>
        </body>
    </html>
"""

// trimIndent 去除缩进
val indent = """
    |line 1
    |line 2
    |line 3
""".trimMargin()

// 字符串操作
val str = "Hello Kotlin"
str.length       // 长度
str[0]           // 索引
str.substring(0, 5)
str.uppercase()
str.lowercase()
str.contains("Hello")
