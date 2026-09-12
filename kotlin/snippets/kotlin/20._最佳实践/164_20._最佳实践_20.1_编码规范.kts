// 命名约定
val camelCase = "variable"
const val CONSTANT = "constant"
fun functionName() {}
class ClassName {}
enum class EnumName {}

// PID 风格
val myVariable = "value"
var _cachedValue: String? = null
val cachedValue: String
    get() = _cachedValue ?: run {
        val value = computeValue()
        _cachedValue = value
        value
    }
