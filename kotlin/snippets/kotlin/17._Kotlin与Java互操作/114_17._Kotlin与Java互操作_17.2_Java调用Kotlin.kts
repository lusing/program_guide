class MyClass {
    companion object {
        const val CONSTANT = "constant"  // 真正的常量
        
        @JvmField
        val field = "field"  // 暴露为静态字段
        
        @JvmStatic
        fun staticMethod() = "static"  // 暴露为静态方法
        
        fun normalMethod() = "normal"  // 需要通过 Companion 调用
    }
}
