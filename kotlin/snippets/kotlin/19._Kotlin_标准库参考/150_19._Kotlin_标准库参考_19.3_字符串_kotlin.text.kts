val str = "Hello Kotlin"

// 基本操作
str.length
str.isEmpty()
str.isNotEmpty()
str.isBlank()
str.isNotEmpty()

// 比较
str.equals("Hello Kotlin", ignoreCase = true)
str.startsWith("Hello")
str.endsWith("Kotlin")
str.contains("Kotlin")

// 搜索
str.indexOf("K")
str.lastIndexOf("o")
str.indexOfFirst { it == 'K' }
str.indexOfLast { it == 'o' }

// 子串
str.substring(0, 5)
str.substringAfter(" ")
str.substringBefore(" ")
str.substringAfterLast(" ")
str.substringBeforeLast(" ")
