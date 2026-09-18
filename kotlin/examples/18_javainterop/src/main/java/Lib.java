// 纯 Java 侧的库：Kotlin 会调用它（javac 先编译，kotlinc -cp 引用）
// 编译：javac -encoding UTF-8 -cp annotations-13.0.jar -d classes Lib.java
import org.jetbrains.annotations.Nullable;   // JetBrains 注解：kotlinc 内建识别，收紧为可空类型

public class Lib {

    /** 普通静态方法：Kotlin 里当函数调用 */
    public static String nick(String name) {
        return "[" + name + "]";
    }

    /** 返回值可能为 null：@Nullable 让 Kotlin 看到的是 String? 而不是平台类型 */
    @Nullable
    public static String firstNonEmpty(String a, @Nullable String b) {
        return a.isEmpty() ? b : a;
    }

    /** SAM 接口：Kotlin lambda 可以自动转换 */
    public interface Op {
        int apply(int x);
    }

    /** 接受 SAM 的方法：Kotlin 里直接传 lambda */
    public static int runOp(int x, Op op) {
        return op.apply(x);
    }

    /** 静态字段：Kotlin 里像属性一样读写 */
    public static int base = 100;

    /** getter/setter 命名对：Kotlin 里自动变成属性 base2
     *  注意：这里私有字段改叫 base2Value 而不是 base2——若同名，Kotlin 的合成属性
     *  会优先撞上私有字段而报"it is private"（真实的互操作坑，见 docs/18-javainterop.md） */
    private static int base2Value = 5;
    public static int getBase2() { return base2Value; }
    public static void setBase2(int v) { base2Value = v; }
}
