// 同门面的第二个文件：@file:JvmName 相同 + 双方都标 @file:JvmMultifileClass → 顶层函数合并进同一个 StrKit
@file:JvmName("StrKit")
@file:JvmMultifileClass

/** 没有它，两个文件同名门面类会"platform declaration clash"；有它，Java 侧一个 StrKit 全收 */
fun reverseShout(s: String): String = s.reversed().uppercase() + "!"
