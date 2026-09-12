// reified 允许在运行时访问类型
inline fun <reified T> isInstance(obj: Any): Boolean {
    return obj is T
}

inline fun <reified T> parseJSON(json: String): T {
    return ObjectMapper().readValue(json, T::class.java)
}

isInstance<String>("Hello")  // true
isInstance<String>(123)      // false
