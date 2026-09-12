// lazy 延迟初始化
val lazyValue: String by lazy {
    println("Computed!")
    "Hello"
}

// lateinit 延迟初始化 (可变属性)
lateinit var lateValue: String
lateValue = "Assigned"

// Delegates.observable
var name: String by Delegates.observable("Default") { prop, old, new ->
    println("$old -> $new")
}

// Delegates.vetoable
var age: Int by Delegates.vetoable(0) { prop, old, new ->
    new >= 0  // 只接受非负数
}
