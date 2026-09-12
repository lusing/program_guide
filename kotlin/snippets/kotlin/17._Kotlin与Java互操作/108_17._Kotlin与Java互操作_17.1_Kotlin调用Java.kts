// Java 类
public class JavaClass {
    public String getName() {
        return "Java";
    }
    
    public static int add(int a, int b) {
        return a + b;
    }
}

// Kotlin 调用
val javaObj = JavaClass()
println(javaObj.name)  // 使用属性语法访问 getter

// 调用静态方法
val sum = JavaClass.add(10, 5)
