import kotlin.reflect.full.*
import kotlin.reflect.jvm.*

// 类引用
val cls: KClass<*> = String::class
val kType: KType = String::class.createType()

// 构造函数
val constructor = cls.primaryConstructor
val instance = constructor?.call()

// 属性
val nameProperty = cls.declaredMembers.filterIsInstance<KProperty<*>>()
val property = cls.declaredMembers.find { it.name == "length" } as? KProperty1<String, *>
val value = property?.getter?.call("Hello")

// 函数
val func = cls.declaredMembers.find { it.name == "substring" } as? KFunction<*>
val result = func?.call("Hello", 1, 4)

// 类型检查
"Hello" is String
String::class.isInstance("Hello")
