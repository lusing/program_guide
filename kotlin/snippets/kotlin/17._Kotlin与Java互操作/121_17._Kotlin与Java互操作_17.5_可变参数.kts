// Kotlin 调用
JavaUtil.printAll("A", "B", "C")  // 直接传递多个参数

// 传递数组
val arr = arrayOf("X", "Y", "Z")
JavaUtil.printAll(*arr)  // 使用展开运算符
