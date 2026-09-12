class Delegate {
    private var value: String? = null

    operator fun getValue(ref: Any?, prop: KProperty<*>): String {
        return value ?: "Default"
    }

    operator fun setValue(ref: Any?, prop: KProperty<*>, value: String) {
        this.value = value
    }
}

class MyClass {
    var prop: String by Delegate()
}
