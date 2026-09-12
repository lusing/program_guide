// Kotlin 使用 SAM 转换
val button = Button()

// 方式1：Lambda（自动 SAM 转换）
button.setClickListener { id ->
    println("Clicked: $id")
}

// 方式2：显式创建对象
button.setClickListener(object : ClickListener {
    override fun onClick(id: String) {
        println("Clicked: $id")
    }
})
