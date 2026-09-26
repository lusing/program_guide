// 纯 Java 侧的消费者：调用上面 Kotlin 编译出的 Api（javac -cp classes + kotlin-stdlib）
// 用返回值而不是直接打印，方便 Kotlin 侧做断言（单一事实源）
public class Caller {

    public static String demo() {
        StringBuilder sb = new StringBuilder();
        // @JvmStatic：直接静态调用，不用 MathKit.INSTANCE.square(...)
        sb.append("Java→Kotlin MathKit.square(7) = ").append(MathKit.square(7)).append('\n');
        // @JvmOverloads：默认参数生成了重载，Java 可以只传一个参数
        sb.append("Java→Kotlin MathKit.scale(5) = ").append(MathKit.scale(5)).append('\n');
        sb.append("Java→Kotlin MathKit.scale(5, 10) = ").append(MathKit.scale(5, 10)).append('\n');
        // @JvmField：像字段一样直接访问，没有 getValue/setValue
        Meter m = new Meter(3);
        m.value = 9;
        sb.append("Java→Kotlin Meter.value = ").append(m.value).append('\n');
        // 默认参数方法 + @JvmOverloads 之外：普通默认参数在 Java 侧必须全量传参
        sb.append("Java→Kotlin Meter.show(\"cm\") = ").append(m.show("cm")).append('\n');
        // 顶层函数：门面类名来自 @file:JvmName("StrKit")，方法名来自 @JvmName("shout")
        sb.append("Java→Kotlin StrKit.shout(\"hey\") = ").append(StrKit.shout("hey")).append('\n');
        // @file:JvmMultifileClass：More.kt 的顶层函数也进了同一个 StrKit 门面
        sb.append("Java→Kotlin StrKit.reverseShout(\"abc\") = ").append(StrKit.reverseShout("abc")).append('\n');
        // 可空参数：Java 随便传 null，Kotlin 的 ?. 在边界兜底
        sb.append("Java→Kotlin safeLen(null) = ").append(StrKit.safeLen(null)).append('\n');
        // @Throws：Java 侧能捕获 Kotlin 抛的异常
        try {
            Meter bad = new Meter(-1);
            bad.requirePositive();
        } catch (IllegalArgumentException e) {
            sb.append("Java 捕获 Kotlin 异常: ").append(e.getMessage()).append('\n');
        }
        // 反方向：Kotlin lambda 自动转 Java 的 SAM 接口
        sb.append("Kotlin→Java Lib.runOp(6, x -> x * 3) = ").append(Lib.runOp(6, x -> x * 3)).append('\n');
        // 静态字段/属性映射：base 是字段，base2 是 getter/setter 对 → 都像属性
        Lib.base = 7;
        Lib.setBase2(11);
        sb.append("Lib.base=").append(Lib.base)
          .append(", Lib.base2=").append(Lib.getBase2()).append('\n');
        return sb.toString();
    }
}
