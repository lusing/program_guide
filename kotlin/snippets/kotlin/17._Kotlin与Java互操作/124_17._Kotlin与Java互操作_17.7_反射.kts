// 获取 Java Class 对象
val javaClass = String::class.java
val javaClass2 = "Hello".javaClass

// 调用 Java 反射
val method = javaClass.getMethod("substring", Int::class.java, Int::class.java)
val result = method.invoke("Hello", 1, 3)  // "el"
