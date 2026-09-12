// 避免使用 !! 操作符
val length = name?.length ?: 0

// 使用 let 处理可空值
name?.let {
    println("Length: ${it.length}")
}

// use 处理可关闭的资源
bufferedReader().use { reader ->
    reader.forEachLine { println(it) }
}
