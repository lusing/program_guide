import kotlin.properties.Delegates

// lazy 延迟初始化
val lazyValue: String by lazy {
    println("Computed!")
    "Hello"
}

// 懒加载模式
val lazyWithLock = lazy(LazyThreadSafetyMode.SYNCHRONIZED) {
    expensiveComputation()
}

val lazyWithPermission = lazy(LazyThreadSafetyMode.PUBLICATION) {
    expensiveComputation()
}

// observable
var observableValue: String by Delegates.observable("default") {
    prop, old, new ->
    println("$old -> $new")
}

// vetoable
var vetoableValue: Int by Delegates.vetoable(0) {
    prop, old, new ->
    new >= 0
}

// notNull
var notNullValue: String by Delegates.notNull()

// 自定义委托
class EnumProperty<E : Enum<E>>(private val enumClass: Class<E>) {
    private var value: E? = null

    operator fun getValue(thisRef: Any?, property: KProperty<*>): E {
        return value ?: error("Value not initialized")
    }

    operator fun setValue(thisRef: Any?, property: KProperty<*>, value: E) {
        this.value = value
    }
}
