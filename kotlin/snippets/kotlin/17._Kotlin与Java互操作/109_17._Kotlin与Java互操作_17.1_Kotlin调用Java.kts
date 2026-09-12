// Java 类
public class Person {
    private String name;
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public boolean isActive() { return true; }
}

// Kotlin 使用
val person = Person()
person.name = "Alice"  // 调用 setName
println(person.name)   // 调用 getName
println(person.active) // 调用 isActive (is 前缀转为属性)
