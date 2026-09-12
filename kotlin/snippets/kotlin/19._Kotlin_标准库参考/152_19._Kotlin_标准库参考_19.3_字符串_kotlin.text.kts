import kotlin.text.Regex

// 基本使用
val regex = Regex("\\d+")
regex.matches("123")
regex.find("abc123def")
regex.findAll("abc123def456")

// 替换
"abc123def".replace(Regex("\\d+"), "#")
"hello world".replace("l", "L", ignoreCase = true)

// 提取
val match = Regex("(\\d+)-(\\d+)-(\\d+)").find("2024-01-15")
val year = match?.groupValues[1]
