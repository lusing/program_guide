// ============================================================
// 28 - C 语言层与 Swift/ObjC 互操作
//
// 本章的证据分三处，各干一件只有它干得了的事：
//   *.c（CLBasic / CLMemory / CLLayout / CLBridge）—— 只负责「量」：sizeof、偏移、
//     回绕、截断、对齐、位模式、指针步长、宏展开次数。全返回整数，一个字符都打不出来。
//   CLCollect.m —— 负责「说」：把数字排成中文行，顺带把 C 约定翻成 ObjC 约定
//     （@encode、结构体属性、NSError **、block 与函数指针）。
//   本文件 —— 负责「印」，并且是本章的另一半主角：Swift 看见的 C 到底是什么类型。
//
// 为什么值得单开一章：《iOS开发从入门到精通》第 4 章整章在讲 C（数据类型、运算符、
// 控制语句、数组与指针、结构体联合体、宏），而今天 iOS 工程里 C 并不是「历史包袱」——
// UIGraphicsImageRenderer 底下是 CGContextRef，SQLite 是 C API，AVFoundation 的
// AudioBufferList 是 C 结构体，Swift 的 Int 和 C 的 int 根本不是一回事。
// 这一章把「C 层的规则」和「跨界时哪条规则会变」一起量出来。
//
// 六条判定带来的写法约束（和 27 章同一套）：
//   - .c 文件里没有 printf，.m 里没有 NSLog（NSLog 走 stderr，判定 3 直接失败）；
//   - 不打印任何指针值、地址、耗时、进程内总量。函数是否同一个、字面量是否合并，
//     一律只打「是/否」；
//   - 有符号溢出、memcpy 重叠、realloc 之后继续用旧指针、可变参数读过头、
//     Swift 带捕获闭包当函数指针传出去 —— 这些全在独立探针里量，正文以「探针记录」引用；
//   - §10 的不透明句柄每造一个就还一个，§17 收尾会打「本章造的还活着几个」，必须是 0；
//   - 所有 sizeof / 偏移 / 位模式的数值都来自这台 x86_64-apple-ios15.0-simulator，
//     换 arm64 真机重跑会有一批数值变化（long、char 符号、结构体对齐），见 §23。
// ============================================================

import Foundation

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func scope(_ body: () -> Void) { body() }

/// 打印 C 侧量到、OC 侧排好版的一节
func showC(_ index: Int, _ title: String, _ collected: [String]) {
    print("\n== §\(index) \(title) ==")
    for l in collected { print(l) }
}
/// 打印一个 Swift 值的类型名 —— §18 整节都在比这个
func typeName<T>(_ v: T) -> String { String(describing: type(of: v)) }
/// 32 位位模式补足 8 个十六进制位（0 也要打成 00000000，否则看不出它是一整块位）
func hex8(_ v: UInt32) -> String { String(repeating: "0", count: max(0, 8 - String(v, radix: 16).count)) + String(v, radix: 16) }
/// 整数数组的一行快照（只打值，不打指针）
func snap(_ a: [Int32]) -> String { a.map { String($0) }.joined(separator: ",") }

/// 交给 C 的 qsort 用的比较函数：必须是全局函数，因为 @convention(c) 不允许捕获
func clCompareInt32Asc(_ a: UnsafeRawPointer?, _ b: UnsafeRawPointer?) -> Int32 {
    guard let a, let b else { return 0 }        // qsort 的签名给的是可选指针
    let x = a.load(as: Int32.self)
    let y = b.load(as: Int32.self)
    return x < y ? -1 : (x > y ? 1 : 0)
}

// ============================================================
// §1–§17：C 量，ObjC 说
// ============================================================

showC(1, "数据类型：尺寸、范围与转换", CLLinesTypes())
expect(CLSizeofChar() == 1, "sizeof(char) == 1 是**标准规定**的，不是实测出来的：C 用「字节」定义 sizeof，而一个 char 就是一个字节")
expect(CLSizeofInt() == 4 && CLSizeofLongLong() == 8, "int=\(CLSizeofInt()), long long=\(CLSizeofLongLong())：只有 long long 到哪都是 8，long 不能赌")
expect(CLSizeofLong() == CLSizeofIntPtr(), "本机 sizeof(long) == sizeof(int *) == \(CLSizeofLong())（LP64）—— 所以 C 里 long 能装下指针，int 装不下")
expect(CLSizeofSizeT() == CLSizeofIntPtr() && CLSizeofPtrDiff() == CLSizeofIntPtr(), "size_t 与 ptrdiff_t 也和指针同宽（\(CLSizeofSizeT()) / \(CLSizeofPtrDiff())）")
expect(CLUnsignedWrapAfterMax() == 2147483648, "无符号回绕有定义：INT_MAX+1 = \(CLUnsignedWrapAfterMax())；有符号溢出是 UB，本章一次都没量")
expect(CLIntDivNegativeTrunc() == -3 && CLModNegative() == -1, "-7/2=\(CLIntDivNegativeTrunc())、-7%2=\(CLModNegative())：向 0 取整，余数跟着被除数")
expect(-7 / 2 == Int(CLIntDivNegativeTrunc()) && -7 % 2 == Int(CLModNegative()),
    "同一条表达式 Swift 自己算一遍：-7/2=\( -7 / 2)、-7%2=\( -7 % 2)，和 C 逐字一致 —— "
    + "「向 0 取整 + 余数跟被除数」这一套 Swift 原样继承了 C。另一套「向下取整 + 余数非负」是 Python 的规则（-7//2 = -4、-7%2 = 1），跨语言写取模哈希才是真会翻车的地方")
expect(CLIntDivTrunc() * 2 + CLModPositive() == 7, "恒等式 (a/b)*b + a%b == a 在 C99 之后成立：\(CLIntDivTrunc())*2+\(CLModPositive())=\(CLIntDivTrunc() * 2 + CLModPositive())")
expect(CLPromotionResultSizeof() == CLSizeofInt(), "整型提升：两个 char 相加的结果类型是 int（sizeof=\(CLPromotionResultSizeof())，不是 \(CLSizeofChar())）")
expect(CLNegativeFloatToIntTrunc() == -3, "(int)-3.9 = \(CLNegativeFloatToIntTrunc())：浮点转整数也是向 0 截断，不是向下取整")
expect(CLDoubleSumEqualsPointThree() == 0 && CLDoubleToLongBits() - CLDoubleBitsOfPointThree() == 1,
    "0.1+0.2 != 0.3，位模式差 \(CLDoubleToLongBits() - CLDoubleBitsOfPointThree())（1 个 ULP）：这就是「浮点别用 ==」的物证")
expect(CLFloatCannotHold2To24Plus1() == 1, "float 装不下 2^24+1：\(CLFloatCannotHold2To24Plus1() == 1 ? "被吸成了同一个数" : "居然分得开")")

showC(2, "运算符与控制语句", CLLinesOperators())
expect(CLPrefixPostfixFirst() == 5 && CLPrefixPostfixSecond() == 7, "i++ 交旧值（\(CLPrefixPostfixFirst())）、++i 交新值（\(CLPrefixPostfixSecond())）：差的就是那一次自增的时机")
expect(CLPrecedenceSum() == 14, "2 + 3 * 4 = \(CLPrecedenceSum())：乘除优先于加减，这条背不住就全部加括号")
expect(CLTernaryPrecedence() == 5, "a>b ? a : b+1（a=3,b=4）= \(CLTernaryPrecedence()) —— ?: 优先级低于 +，所以 b+1 整个是第三支；写括号才是正解")
expect(CLBitwiseAnd() == 8 && CLBitwiseOr() == 14 && CLBitwiseXor() == 6, "12&10=\(CLBitwiseAnd()), 12|10=\(CLBitwiseOr()), 12^10=\(CLBitwiseXor())：位标志、开关状态全靠这三个")
expect(CLBitwiseNotZero() == -1, "~0 = \(CLBitwiseNotZero())：取反连符号位一起翻，所以「0 变 -1」不是 bug")
expect(CLShiftLeftOne31Unsigned() == 2147483648 && CLShiftLeftOne31() == -2147483648,
    "1u<<31 = \(CLShiftLeftOne31Unsigned())，转成 int 变 \(CLShiftLeftOne31())：同一串位的两种解释，所以位标志必须一路用无符号")
expect(CLArithmeticShiftRight() == -4, "-8>>1 = \(CLArithmeticShiftRight())：有符号右移补符号位（实现定义，本机是算数右移），所以 >> 不能当「除以 2」用在负数上")
expect(CLShortCircuitAndCalls() == 0 && CLShortCircuitOrCalls() == 0 && CLShortCircuitAndRunsCalls() == 1,
    "短路实测：0&&f() 跑 \(CLShortCircuitAndCalls()) 次、1||f() 跑 \(CLShortCircuitOrCalls()) 次、1&&f() 跑 \(CLShortCircuitAndRunsCalls()) 次")
expect(CLDoWhileRunsOnce() == 1, "do-while 条件一开始就是假，仍跑了 \(CLDoWhileRunsOnce()) 次：它先执行再判断")
expect(CLSwitchFallthroughAdds() == 121, "少一个 break 的 switch 累加出来是 \(CLSwitchFallthroughAdds())（1+10, 再 10, 再 100）：静默往下跑。"
    + "本章的编译组合就是 -Wall -Wextra，一个诊断都没有 —— 这条警告不在里面，得显式点名（探针记录见 §23）")
expect(CLSwitchDefaultFirstValue() == 22, "default 写在最前面也还是兜底：case 2 命中拿到 \(CLSwitchDefaultFirstValue())")
expect(CLGotoCleanupValue() == 11, "goto 清理段那条顺利路径返回 \(CLGotoCleanupValue())：C 没有异常，出错就一路 goto —— iOS 底层代码全是这个形状，读得懂它才算读得懂 SDK")

showC(3, "数组就是连续内存", CLLinesArrays())
expect(CLSizeofInt5() == 20 && CLIntArrayCount() == 5, "sizeof(int[5]) = \(CLSizeofInt5())、元素数 = \(CLIntArrayCount())：这个除法只在数组没退化的地方有效")
expect(CLGapInElements() == 3 && CLGapInBytes() == 12, "&a[3]-&a[0] = \(CLGapInElements()) 个元素，转成 char* 再减 = \(CLGapInBytes()) 字节 —— 指针相减的单位永远是元素")
expect(CLRowGapInBytes() == 12 && CLAtRowCol() == 6, "行主序：换行跨 \(CLRowGapInBytes()) 字节，m[1][2] 仍是 \(CLAtRowCol())")
expect(CLWholeArrayPlusOneGap() == 20, "int(*)[5] 加一跳过整块 \(CLWholeArrayPlusOneGap()) 字节：&a 和 a 差的是类型，不是值")
expect(CLSizeofRealArray() == 20 && CLArrayDecaySizeof() == 8, "同一个数组：本地 sizeof = \(CLSizeofRealArray())，传进函数之后 = \(CLArrayDecaySizeof()) —— 退化掉了长度")

showC(4, "字符数组与 C 字符串", CLLinesStrings())
expect(CLSizeofChineseLiteral() == 7 && CLUtf8LengthOfChinese() == 6, "\"中文\"：sizeof=\(CLSizeofChineseLiteral())（含结尾 0），strlen=\(CLUtf8LengthOfChinese())（两个汉字 × 3 字节）")
expect(CLAsciiByteLen() == 3 && CLCharArraySizeof() == 4, "\"iOS\" 的 strlen=\(CLAsciiByteLen())，而 char s[]=\"abc\" 的 sizeof=\(CLCharArraySizeof())：C 字符串的长度里永远含那个 0")
expect(CLTruncateToTwo() == 2, "插一个 '\\0' 之后 strlen 变 \(CLTruncateToTwo())：写坏一个字节就等于截断")
expect(CLFirstByteAsUChar() == 228 && CLFirstByteAsChar() == -28, "同一个 0xE4 字节：char 读出 \(CLFirstByteAsChar())，unsigned char 读出 \(CLFirstByteAsUChar()) —— 存二进制/像素就必须写 unsigned")
expect(CLStrcmpEqual() == 1 && CLStrcmpSignOfAbcAbd() == -1, "strcmp 比内容：字面量和它的 memcpy 副本返回 0 吗 = "
    + "\(CLStrcmpEqual() == 1 ? "是（相等）" : "否")；\"abc\" vs \"abd\" 的符号归一成 \(CLStrcmpSignOfAbcAbd()) —— "
    + "只取符号，不认具体数值")

showC(5, "指针运算", CLLinesPointers())
expect(CLCharPtrStepBytes() == 1 && CLIntPtrStepBytes() == 4 && CLLongPtrStepBytes() == 8 && CLDoublePtrStepBytes() == 8,
    "加一步的字节数：char*=\(CLCharPtrStepBytes()), int*=\(CLIntPtrStepBytes()), long*=\(CLLongPtrStepBytes()), double*=\(CLDoublePtrStepBytes())")
expect(CLIntPtrStepBytes() == CLSizeofInt(), "指针加一 = sizeof(指向的类型)：int* 的 \(CLIntPtrStepBytes()) 步 == sizeof(int)=\(CLSizeofInt())，一条规则解释全部")
expect(CLVoidPtrStepBytes() == 1, "void* + 1 在 clang 这儿给 \(CLVoidPtrStepBytes()) 字节：标准 C 没定义这条运算，"
    + "可它连 -std=c11 都能编过，只有 -pedantic 会警告（探针记录见 §23）—— 「编译器不拦」和「标准允许」是两件事")

showC(6, "出参与二级指针", CLLinesOutParams())
scope {
    var a: Int32 = 0, b: Int32 = 0, c: Int32 = 0
    CLOutThreeInts(&a, &b, &c)
    expect(a == 11 && b == 22 && c == 33, "三个出参填满：\(a), \(b), \(c) —— C 只有一个返回值，多结果只能靠指针")
}
expect(CLReadThroughDoublePointer() == 42, "二级指针 **pp 读到 \(CLReadThroughDoublePointer())：先取那个指针，再取它指向的值")
scope {
    var out: Int32 = 0
    let ok = CLCallWithNullOut(&out)
    let bad = CLCallWithNullOut(nil)
    expect(ok == 0 && out == 7 && bad == -1, "传地址 -> 返回 \(ok) 且出参被写成 \(out)；传 NULL -> 返回 \(bad) 且没崩：C 函数必须自己挡 NULL")
}

showC(7, "结构体布局与对齐", CLLinesStructs())
expect(CLSizeofPackA() == 12 && CLSizeofPackB() == 8, "{char,int,char}=\(CLSizeofPackA()) 字节，{int,char,char}=\(CLSizeofPackB()) 字节：同样的字段，光改顺序就省 4 个字节")
expect(CLOffsetIInA() == 4 && CLOffsetDInA() == 8, "A 里 i 的偏移是 \(CLOffsetIInA())（前面补了 3 字节才对齐），d 在 \(CLOffsetDInA()) —— 尾部还要补到 12")
expect(CLSizeofPackB() == CLSizeofPackC(), "B 与 C 一样大（\(CLSizeofPackB()) == \(CLSizeofPackC())）：同类挤一起之后，谁先谁后无所谓")
expect(CLAlignmentOfPackA() == CLSizeofInt(), "_Alignof(struct CLPackA) = \(CLAlignmentOfPackA()) == sizeof(int)：结构体的对齐等于最宽成员")

showC(8, "联合体与浮点位模式", CLLinesUnions())
expect(CLSizeofFloatBits() == 4, "union{float;uint32_t} 的 sizeof = \(CLSizeofFloatBits())：成员共起点，谁大谁定尺寸")
expect(CLBitsOf(1.0) == 0x3F800000, "1.0f 的位模式 = 0x\(String(CLBitsOf(1.0), radix: 16))")
expect(CLSignOfBits(CLBitsOf(-1.0)) == 1 && CLSignOfBits(CLBitsOf(1.0)) == 0, "-1.0f 的符号位 = \(CLSignOfBits(CLBitsOf(-1.0)))，1.0f 是 \(CLSignOfBits(CLBitsOf(1.0)))：符号单独占一位")
expect(CLBitsOf(-0.0) == 0x80000000 && CLBitsOf(0.0) == 0 && CLFloatZeroEqualsNegativeZero() == 1
    && CLReciprocalOfNegativeZeroIsNegInf() == 1 && CLAtan2DistinguishesZeros() == 1,
    "正零 0x\(hex8(CLBitsOf(0.0)))、负零 0x\(hex8(CLBitsOf(-0.0)))：位模式差一位，可 C 在运行时比出来的 0.0f == -0.0f 是 "
    + "\(CLFloatZeroEqualsNegativeZero() == 1 ? "相等" : "不等")；而 1.0f / -0.0f 给出负无穷吗 \(CLReciprocalOfNegativeZeroIsNegInf() == 1 ? "是" : "否")、"
    + "atan2f 分得开这两个零吗 \(CLAtan2DistinguishesZeros() == 1 ? "是" : "否") —— 「== 相等」不等于「位模式相同」，浮点做键值或哈希时要按位比")
expect(CLExponentField(CLBitsOf(2.0)) - CLExponentField(CLBitsOf(1.0)) == 1, "2.0f 的指数段比 1.0f 大 \(CLExponentField(CLBitsOf(2.0)) - CLExponentField(CLBitsOf(1.0)))：值翻倍 = 指数 +1，尾数一个字都不动")
expect(CLExponentField(CLBitsOf(1.0)) == 127 && CLMantissaField(CLBitsOf(1.0)) == 0, "1.0f：指数段 \(CLExponentField(CLBitsOf(1.0)))（偏置 127 -> 真指数 0），尾数段 \(CLMantissaField(CLBitsOf(1.0)))")

showC(9, "枚举", CLLinesEnums())
expect(CLSizeofColorEnum() == 4, "enum CLColor 的 sizeof = \(CLSizeofColorEnum())：编译器给了个和 int 同宽的整型，不是按最大值算位数")
expect(CLColorValue(CL_RED) == 1 && CLColorValue(CL_BIG) == 100000, "RED=\(CLColorValue(CL_RED)), BIG=\(CLColorValue(CL_BIG))：枚举值就是个整数")
expect(CLColorValue((CLColor(rawValue: CL_RED.rawValue | CL_BLUE.rawValue))) == 5, "RED|BLUE = \(CLColorValue((CLColor(rawValue: CL_RED.rawValue | CL_BLUE.rawValue))))：C 枚举不检查这个组合是不是合法 case")

showC(10, "不透明句柄：手写的 Create/Retain/Release", CLLinesHandles())
scope {
    let alive0 = CLOpaqueAliveObjects()
    let h = CLOpaqueCreate(1)
    expect(CLOpaqueRefCount(h) == 1 && CLOpaqueSeed(h) == 1, "Swift 这边另造一个句柄（seed 传 1，和上面 ObjC 那个 2026 是两块内存）：Create 之后计数 = \(CLOpaqueRefCount(h))，seed 只能靠 getter 读回 \(CLOpaqueSeed(h))")
    CLOpaqueRetain(h)
    expect(CLOpaqueRefCount(h) == 2, "Retain -> \(CLOpaqueRefCount(h))")
    CLOpaqueRelease(h)
    CLOpaqueRelease(h)
    expect(CLOpaqueAliveObjects() == alive0, "两次 Release 之后本章还活着 \(CLOpaqueAliveObjects()) 个，和进节前的 \(alive0) 一致：计数配平了")
    expect(CLOpaqueRefCount(nil) == -1, "给 getter 传 NULL 拿到 \(CLOpaqueRefCount(nil))：句柄类 API 必须自己挡 NULL")
}

showC(11, "函数、值传递与递归", CLLinesFunctions())
scope {
    let x: Int32 = 1, y: Int32 = 2
    CLTrySwap(x, y)
    expect(x == 1 && y == 2, "值传递换不动：函数里换完了，外面还是 x=\(x), y=\(y)")
}
expect(CLFibonacci(10) == 55 && CLFibonacci(20) == 6765, "fib(10)=\(CLFibonacci(10)), fib(20)=\(CLFibonacci(20))：值不大，但 fib(20) 展开了两万次调用")

showC(12, "可变参数", CLLinesVarargs())
expect(CLTableSize() == 3, "本节的所有调用都在 ObjC 侧：Swift 连 CLSumVarargs 这个名字都拿不到 —— "
    + "它是可变参数函数，importer 直接标成 unavailable（编译器原文见 §23）")

showC(13, "函数指针与回调表", CLLinesFuncPointers())
expect(CLTableSize() == 3, "回调表里有 \(CLTableSize()) 项")
expect(CLApplyTable(0, 5) == 10 && CLApplyTable(1, 5) == 25 && CLApplyTable(2, 5) == -5,
    "按下标取函数各调一次：[0]=\(CLApplyTable(0, 5)), [1]=\(CLApplyTable(1, 5)), [2]=\(CLApplyTable(2, 5))")
expect(CLApplyTable(99, 5) == -9999, "越界下标 -> CLMapAt 给 NULL -> \(CLApplyTable(99, 5))：C 里函数指针可以是 NULL，调用前必须挡")
expect(CLSameFunctionPointer(CLDoubleOf, CLDoubleOf) == 1 && CLSameFunctionPointer(CLDoubleOf, CLSquareOf) == 0,
    "函数指针比的是实现不是名字：CLSameFunctionPointer(CLDoubleOf, CLDoubleOf) = \(CLSameFunctionPointer(CLDoubleOf, CLDoubleOf))、"
    + "换个人就是 \(CLSameFunctionPointer(CLDoubleOf, CLSquareOf))（只打 1/0，地址绝不进输出）")

showC(14, "memcpy 与 memmove", CLLinesMemoryBlocks())
scope {
    var src = [CChar](repeating: 0, count: 8)
    src.withUnsafeMutableBufferPointer { CLFillBuffer($0.baseAddress, 8) }
    var dst = [CChar](repeating: Int8(UInt8(ascii: "-")), count: 8)
    dst[7] = 0
    src.withUnsafeBufferPointer { s in
        dst.withUnsafeMutableBufferPointer { d in CLCopyNonOverlap(d.baseAddress, s.baseAddress) }
    }
    var ov = [CChar](repeating: 0, count: 8)
    ov.withUnsafeMutableBufferPointer { b in
        CLFillBuffer(b.baseAddress, 8)
        CLCopyOverlapWithMemmove(b.baseAddress)
    }
    let copied = String(cString: dst)
    let moved = String(cString: ov)
    expect(copied == "abcde", "Swift 自己准备两块缓冲、交给 C 的 memcpy 填：目的先是 \"-----\"，填完是 \"\(copied)\" —— "
        + "长度由那个 0 决定而不是由数组的 8 决定，CLCopyNonOverlap 在 dst[5] 补了 0，后面两个 '-' 就不见了")
    expect(moved == "ababcfg", "同一段重叠交给 memmove：\"\(moved)\"。搬之前 buf[2]、buf[3] 正是源区的前两个字节，"
        + "它仍然给出「搬动前的那三个」—— 方向判断在库里做完了。换 memcpy 就是探针记录里 -O0/-O2 两个答案，本节一次都不跑")
}

showC(15, "malloc 家族", CLLinesMalloc())
expect(CLCallocZeroed() == 0, "calloc 之后第一个元素 = \(CLCallocZeroed())：清零是 calloc 唯一的额外承诺")
// 第五版：分配在 CLMemory.c，判空写在 Swift —— 又跨了一个编译单元，所以同样折不掉。
// 这也是 Swift 侧唯一一种「让 C 的 NULL 变成一个真正的 Optional」的写法。
func swiftMallocProbe(_ n: Int) -> (isNull: Bool, readBack: Int) {
    guard let raw = CLMallocRaw(n) else { return (true, -1) }
    raw.storeBytes(of: Int(12345), as: Int.self)
    let back = raw.load(as: Int.self)
    CLFreeRaw(raw)
    return (false, back)
}
let probeHuge = swiftMallocProbe(-1)                 // Int 的 -1 交给 size_t 就是 SIZE_MAX
let probe1T = swiftMallocProbe(1 << 40)
line("  Swift 侧再问一遍：CLMallocRaw 的完整类型是 \(String(describing: type(of: CLMallocRaw))) —— "
    + "size_t 落成了 Int（所以传 -1 编译得过，到 C 那边就是 SIZE_MAX），void * 落成 Optional<UnsafeMutableRawPointer>，"
    + "也就是 C 的 NULL 在 Swift 里就是一个真的 nil")
expect(probeHuge.isNull && probeHuge.readBack == -1, "Swift 里传 -1：guard let 走进 nil 分支 = \(probeHuge.isNull)，"
    + "出参停在自定的记号 \(probeHuge.readBack)（-1 = 「没写过」）—— 这是 C 的 malloc 真的返回了 NULL")
expect(!probe1T.isNull && probe1T.readBack == 12345, "Swift 里传 1 << 40：\(probe1T.isNull ? "返回 nil" : "拿到了指针")，"
    + "用 raw 指针 store/load 写进去又读回来 \(probe1T.readBack) —— 1TB 的额度在虚拟内存上只是记一笔账")
expect(CLMallocIsNullForSize(-1) == 0 && probeHuge.isNull, "同一个尺寸、两个编译单元、两个答案："
    + "分配和判空写在 C 那个函数里的 CLMallocIsNullForSize(-1) 给 \(CLMallocIsNullForSize(-1))（意思是「不是 NULL」），"
    + "判空写在 Swift 这边的这版给「是 NULL」。前者是 -O2 折出来的常数（连 malloc 都没调），"
    + "后者才是分配器说的话 —— 汇编原文见 §15 与 §23")

showC(16, "宏", CLLinesMacros())
expect(CLMacroSqrOfSum(3) == 7 && CLMacroSafeSqrOfSum(3) == 16, "SQR(3+1)：不带括号 = \(CLMacroSqrOfSum(3))，带括号 = \(CLMacroSafeSqrOfSum(3))")
expect(CLMacroTwiceValue() == 30 && CLFuncTwiceValue() == 20, "同一个表达式：宏版 \(CLMacroTwiceValue())，函数版 \(CLFuncTwiceValue()) —— 参数被展开两次，值也跟着变")
expect(CLMacroTwiceSideEffects() == 2 && CLFuncTwiceSideEffects() == 1, "副作用次数：宏 \(CLMacroTwiceSideEffects()) 次，函数 \(CLFuncTwiceSideEffects()) 次")
expect(String(cString: CLStringifyName()) == "CL_Paste_Target", "# 号把宏参数原样变成字符串字面量：Swift 侧读回来也是 \"\(String(cString: CLStringifyName()))\"")

showC(17, "C 与 Objective-C 的边界", CLLinesInterop())
expect(CLOpaqueAliveObjects() == 0, "§17 用完的句柄也还干净了：本章造的还活着 \(CLOpaqueAliveObjects()) 个")

// ============================================================
// §18 Swift 看见的 C 类型
// ============================================================
line("\n== §18 Swift 看见的 C 类型：同名，不同宽 ==")
scope {
    line("  同一批 C 函数，Swift 侧拿到的类型名："
        + "sizeof(int) -> \(typeName(CLSizeofInt()))，数组元素数(long) -> \(typeName(CLIntArrayCount()))，"
        + "CLColorValue -> \(typeName(CLColorValue(CL_RED)))，CLBitsOf -> \(typeName(CLBitsOf(1.0)))，"
        + "CLAddFunc -> \(typeName(CLAddFunc(1, 2)))，void* 步长 -> \(typeName(CLVoidPtrStepBytes()))")
    expect(typeName(CLAddFunc(1, 2)) == "Int32", "C 的 int 进 Swift 变成 **Int32**，不是 Int：CLAddFunc(1,2) 的结果类型是 \(typeName(CLAddFunc(1, 2)))")
    expect(typeName(CLIntArrayCount()) == "Int", "C 的 long 进 Swift 变成 **Int**：CLIntArrayCount() 的类型是 \(typeName(CLIntArrayCount())) —— C 里两种不同宽的类型，在 Swift 里成了「大整型」和「小整型」")
    expect(typeName(CLSizeofInt()) == "Int" && typeName(CLSizeofSizeT()) == "Int" && typeName(CLSizeofPtrDiff()) == "Int",
        "size_t、ptrdiff_t 进 Swift 都是 Int（\(typeName(CLSizeofInt())) / \(typeName(CLSizeofSizeT())) / \(typeName(CLSizeofPtrDiff()))）—— "
        + "连同 long 在内，三个不同的 C 类型塌成了同一个 Swift 类型。这不是精度损失，是 Swift 有意把「长度/计数」统一成 Int；"
        + "代价是 C 那边「无符号」的语义没了：size_t 做减法在 Swift 侧不再是自动回绕，而是会 trap")
    expect(MemoryLayout<Int32>.size == Int(CLSizeofInt()), "两边各量一遍同一个类型：Swift 的 MemoryLayout<Int32>.size = \(MemoryLayout<Int32>.size)，C 的 sizeof(int) = \(CLSizeofInt()) —— 数值必须相同，否则桥接就是骗人的")
    expect(MemoryLayout<Int>.size == Int(CLSizeofLong()), "MemoryLayout<Int>.size = \(MemoryLayout<Int>.size) == C 的 sizeof(long) = \(CLSizeofLong())：Swift 的 Int 就是 C 的 long，所以它在这台机器上恒为 64 位")
    expect(MemoryLayout<Int>.size != MemoryLayout<Int32>.size, "而 Swift 的 Int（\(MemoryLayout<Int>.size) 字节）和 C 的 int（\(MemoryLayout<Int32>.size) 字节）不同宽 —— "
        + "「Swift 里传个 Int 给要 int 的 C 函数」这句直觉是错的，必须写 Int32；反过来 C 的 long 才对应 Swift 的 Int")
    expect(MemoryLayout<CLPackA>.size == Int(CLSizeofPackA()), "C 结构体进 Swift 还是那个结构体：MemoryLayout<CLPackA>.size = \(MemoryLayout<CLPackA>.size)，sizeof = \(CLSizeofPackA())")
    expect(MemoryLayout<CLPackA>.alignment == Int(CLAlignmentOfPackA()), "连对齐都一致：alignment = \(MemoryLayout<CLPackA>.alignment) == _Alignof = \(CLAlignmentOfPackA())")
    expect(MemoryLayout<CLPackB>.stride == MemoryLayout<CLPackB>.size, "CLPackB：size=\(MemoryLayout<CLPackB>.size)、stride=\(MemoryLayout<CLPackB>.stride) —— stride 是「数组里一个元素占几格」，正好等于补齐后的 sizeof")
    line("  C 枚举在 Swift 里不是 enum：CL_RED 的类型是 \(typeName(CL_RED))，rawValue = \(CL_RED.rawValue)，CL_BLUE.rawValue = \(CL_BLUE.rawValue)")
    expect(!(CL_RED == CL_BLUE), "CL_RED == CL_BLUE 给出 \(CL_RED == CL_BLUE)：它被 import 成一个 RawRepresentable 的结构体，能比、能取 rawValue，"
        + "但**不是** Swift 的 enum —— 没有 case、switch 也穷尽不了，所以从 C 枚举过来的一定要自己补一个 Swift enum（§22 那条「宏与常量要重述」是同一件事）")
    expect(CLColorValue(CLColor(rawValue: CL_RED.rawValue | CL_BLUE.rawValue)) == 5, "位标志得自己拼：CL_RED.rawValue|CL_BLUE.rawValue = \(CL_RED.rawValue | CL_BLUE.rawValue)，"
        + "塞回 CLColor 再交回 C -> \(CLColorValue(CLColor(rawValue: CL_RED.rawValue | CL_BLUE.rawValue)))。NS_OPTIONS 才能变成 Swift 的 OptionSet，裸 C 枚举不行")
    line("  两个枚举的 rawValue 类型不一样：CLColor 的是 \(typeName(CL_RED.rawValue))，CLSigned 的是 \(typeName(CL_NEG.rawValue))，"
        + "后者读到 \(CL_NEG.rawValue)。这不是 importer 随手挑的 —— 它跟着 §9 在 C 侧量出来的底类型符号性走："
        + "CLColor 全是非负数，clang 给它 unsigned int，于是 Swift 给 UInt32；CLSigned 里有一个 -7，底类型变成 int，Swift 就给 Int32")
    expect(typeName(CL_RED.rawValue) == "UInt32" && typeName(CL_NEG.rawValue) == "Int32",
        "rawValue 的符号性两边一致：C 侧 RED-BLUE 回绕成 \(CLColorSubtractWrapped())（正数 = 无符号底），"
            + "NEG-POS 是 \(CLSignedSubtractWrapped())（负数 = 有符号底）；Swift 侧则分别是 \(typeName(CL_RED.rawValue)) 和 \(typeName(CL_NEG.rawValue))")
    expect(MemoryLayout<CLColor>.size == Int(CLSizeofColorEnum()) && MemoryLayout<CLSigned>.size == Int(CLSizeofSignedEnum()),
        "尺寸仍然一致：Swift 的 MemoryLayout<CLColor>.size = \(MemoryLayout<CLColor>.size) == C 的 sizeof = \(CLSizeofColorEnum())，"
            + "CLSigned 也一样：\(MemoryLayout<CLSigned>.size) == \(CLSizeofSignedEnum()) —— 换的只是符号，不是宽度。"
            + "拿一个可能是无符号的 rawValue 去和 Int 比较之前，先看清它是哪一种（这也是 §1 那条「char 有没有符号是实现定义」的续集）")
    expect(Int32.max &+ 1 == Int32.min, "整数溢出的三种语言规则并排：C 的有符号溢出是 UB（§1 只敢用无符号回绕，本机 \(CLUnsignedWrapAfterMax())）；"
        + "Swift 的 &+ 是**定义好**的回绕（Int32.max &+ 1 = \(Int32.max &+ 1)）；Swift 的普通 + 溢出直接 trap（探针记录见 §23）")
}

// ============================================================
// §19 Swift 的指针与缓冲区
// ============================================================
line("\n== §19 Swift 的指针：withUnsafe 那一圈 ==")
scope {
    let arr: [Int32] = [3, 1, 4, 1, 5]
    let counted = arr.withUnsafeBufferPointer { buf in CLCountBelow(buf.baseAddress, Int32(buf.count), 4) }
    expect(counted == 3, "把 Swift 数组借给 C 只读扫一遍：CLCountBelow(< 4) = \(counted)（数组是 \(arr.map { String($0) }.joined(separator: ","))）—— "
        + "withUnsafeBufferPointer 给出的 baseAddress 就是那个 const int *")
    var mutable = arr
    mutable.withUnsafeMutableBufferPointer { buf in CLBumpEach(buf.baseAddress, Int32(buf.count)) }
    expect(mutable == [4, 2, 5, 2, 6], "CLBumpEach 就地改内存：之后变成 \(mutable.map { String($0) }.joined(separator: ",")) —— "
        + "C 函数不靠返回值也能改到外面，靠的就是这个地址")
    let still = mutable.withUnsafeBufferPointer { buf in CLCountBelow(buf.baseAddress, Int32(buf.count), 5) }
    expect(still == 3, "改完再数 <5 的：\(still) 个 —— 借出去的指针指向同一块内存，不是副本")
    line("  借用的边界：闭包一返回，那个指针就不许再留用。Swift 用这个作用域替「数组可能搬家」兜底 —— 把 baseAddress 存到外面是崩溃名单上的常客")

    var a = CLPackA()
    CLPreparePackA(&a, 2, 1, 3)             // 连 padding 一起清零再赋值，见 CLBridge.c 里那段注释
    // 必须是 withUnsafeBytes(of: &a)：不带 & 的那个重载会把结构体**拷一份**出来，
    // 而拷贝只搬三个字段、不搬 padding，于是 padding 又变成未定义内容 ——
    // 本章实测：写成 without & 时 debug 数出 3 个非零字节、release 数出 5 个，两个配置的输出现在不一致
    let dump = withUnsafeBytes(of: &a) { raw in raw.bindMemory(to: UInt8.self).map { String(format: "%02X", $0) } }
    let nonzero = dump.filter { $0 != "00" }.count
    line("  一个 CLPackA（c=2, i=1, d=3）的原始字节：\(dump.joined(separator: " "))")
    expect(dump.count == Int(CLSizeofPackA()), "整块 \(dump.count) 字节 == sizeof(struct CLPackA) = \(CLSizeofPackA())：Swift 的 withUnsafeBytes 量到的是和 C 同一块内存")
    expect(dump[0] == "02" && dump[4] == "01" && dump[8] == "03", "三个字段各落在 0/4/8 号位置（\(dump[0]) \(dump[4]) \(dump[8])）—— 和 §7 的 offsetof 完全对得上，"
        + "小端把 int 1 写成 01 00 00 00")
    expect(nonzero == 3, "非零字节只有 \(nonzero) 个，剩下 \(dump.count - nonzero) 个是 padding。padding 里的内容 C 不管，"
        + "所以「整个结构体 memcpy / 拿去当 key / 写进文件」都可能搬走一堆垃圾 —— 要比较或持久化就逐字段比，别 memcmp 整块")
    expect(CLSumPackB(nil) == -1, "给 C 传 nil：CLSumPackB(nil) = \(CLSumPackB(nil))。Swift 的 Optional 指针和 C 的 NULL 在这就是同一个值，"
        + "所以 §6 那句「函数自己挡 NULL」在 Swift 侧同样要成立")
}

// ============================================================
// §20 Swift 的函数指针：@convention(c)
// ============================================================
line("\n== §20 Swift 的函数指针：@convention(c) 与 qsort ==")
let sortTiebreak: Set<Int> = [2]
scope {
    let doubled = CLCallMap({ (v: Int32) -> Int32 in v * 2 }, 21)
    expect(doubled == 42, "Swift 闭包直接当 C 的函数指针用：CLCallMap({ $0 * 2 }, 21) = \(doubled)。"
        + "CLIntMap 在 Swift 里就是 @convention(c) (Int32) -> Int32，**不带捕获**的闭包才能这么交出去")
    let twice = CLApplyTwice({ (v: Int32) -> Int32 in v + 1 }, 10)
    expect(twice == 22, "CLApplyTwice 把同一个指针调了两次再相加：\(twice)（每次 10+1）。纯函数才敢这么用；"
        + "带状态的「函数」在 C 里只能靠全局变量，而那一页日志就再也复现不出来了（§17 那句话的另一半）")
    expect(CLSameFunctionPointer(CLDoubleOf, CLDoubleOf) == 1 && CLSameFunctionPointer(CLDoubleOf, CLSquareOf) == 0,
        "表里的函数和 Swift 里写的名字是同一个实现：同一个 -> \(CLSameFunctionPointer(CLDoubleOf, CLDoubleOf))，换另一个 -> \(CLSameFunctionPointer(CLDoubleOf, CLSquareOf))")
    let fromTable = CLMapAt(1).map { CLCallMap($0, 6) } ?? -1
    expect(fromTable == 36, "从表里取出的函数指针也能交给 Swift 闭包的位置：CLCallMap(CLMapAt(1), 6) = \(fromTable)（square-it）")

    let nums: [Int32] = [9, 2, 7, 2, 10, 1]
    var viaC = nums
    viaC.withUnsafeMutableBufferPointer { buf in CLSortInts(buf.baseAddress, Int32(buf.count)) }
    let viaSwift = nums.sorted(by: <)
    expect(viaC == viaSwift, "同一个数组两条路：C 的 qsort（\(snap(viaC))）与 Swift 的 sorted(by:)（\(snap(viaSwift))）一致 —— "
        + "但 qsort 只认那个不带捕获的 C 函数指针，sorted 的比较闭包什么都能带")
    let capturedOrder = nums.sorted { lhs, rhs in
        let kl = sortTiebreak.contains(Int(lhs)) ? Int(lhs) + 1000 : Int(lhs)
        let kr = sortTiebreak.contains(Int(rhs)) ? Int(rhs) + 1000 : Int(rhs)
        return kl < kr
    }
    expect(capturedOrder != viaSwift, "比较闭包里捕获了一个集合（把 2 排到最后）：结果变成 \(snap(capturedOrder)) —— 这一次两条路**故意**不一样。"
        + "同样的逻辑要交给 C 的 qsort，只能把那个集合变成全局变量，或者干脆做不到")
    var raw = nums
    raw.withUnsafeMutableBufferPointer { buf in
        qsort(buf.baseAddress, buf.count, MemoryLayout<Int32>.stride, clCompareInt32Asc)
    }
    expect(raw == viaSwift, "Swift 也能直接 callLibc 的 qsort：把全局函数 clCompareInt32Asc 交出去，排完是 \(snap(raw)) —— "
        + "代价就是这个比较函数必须写在全局（或无捕获闭包），签名还要变成 UnsafeRawPointer + load(as:)")
    line("  要真的把「带捕获的 Swift 闭包」交给 C，必须再配一个上下文指针 + trampoline —— block 干的正是这件事，只是它把这套藏起来了（§17 有对照）")
}

// ============================================================
// §21 Swift 侧的 C 字符串：字节与字符是两套计数
// ============================================================
line("\n== §21 Swift 侧的 C 字符串：字节与字符是两套计数 ==")
scope {
    let cstr = String(cString: CLStaticCString())
    let utf8Bytes = cstr.utf8.count
    let swiftChars = cstr.count
    let foundationBytes = cstr.lengthOfBytes(using: .utf8)
    line("  同一条字符串三套数法：String(cString: CLStaticCString()) = \"\(cstr)\"，"
        + "Swift 的 utf8 计数 = \(utf8Bytes)，Foundation 的 lengthOfBytes(using: .utf8) = \(foundationBytes)，Swift 的 characters 计数 = \(swiftChars)")
    expect(utf8Bytes == foundationBytes, "Swift 数 UTF-8 字节和 Foundation 数的一致（\(utf8Bytes) == \(foundationBytes)）：这两边都懂编码")
    expect(swiftChars != utf8Bytes, "而 characters 给出 \(swiftChars) —— 「几个字符」和「几个字节」是两套计数。"
        + "C 的 strlen（§4 那个 \(CLUtf8LengthOfChinese())）只会给你字节，所以按 strlen 去「截断中文」就会切出半个字，这是中文产品最常见的 C 层 bug")
    expect(CLSizeofChineseLiteral() == 7, "对照 C 侧：\"中文\" 的 sizeof = \(CLSizeofChineseLiteral())（含结尾 0），strlen = \(CLUtf8LengthOfChinese())（纯字节）")
    let roundTrip = cstr.withCString { String(cString: $0) }
    expect(roundTrip == cstr, "Swift -> C -> Swift 走一圈内容不变（\"\(roundTrip)\"）：withCString 借出的那个 char * 只在闭包里有效，出来就收回")
    expect(CLFirstByteAsUChar() == 228, "谁负责解释这串字节也要想清楚：C 只能取到第 0 个字节（\(CLFirstByteAsUChar())），"
        + "而 Swift 的 String 从一开始就带着 UTF-8 编码 —— 跨界时「传 char *」传的不是字符串，是一段还没解释的字节")
}

// ============================================================
// §22 Swift 看得见哪些宏、以及 NSError ** 变成了 throws
// ============================================================
line("\n== §22 宏的可见性，与 NSError ** -> throws ==")
scope {
    expect(CL_answer == 77, "对象式的简单宏能进 Swift：CL_answer = \(CL_answer)（CLMacros.h 里 #define 的那个 77，Swift 直接当常量看见）")
    expect(CL_answer == CLPastedInto(), "而且和 C 侧算出来的一致（\(CLPastedInto())）—— 但**函数式宏**看不见：CL_SQR_BAD(3)、CL_TWICE(x) 在 Swift 里根本不存在（探针记录有原文）")
    expect(CL_WORD_BRANCH == 1, "条件编译的结果也带过来了：CL_WORD_BRANCH = \(CL_WORD_BRANCH)（个位 1 = __LP64__ 那一支）—— 它是编译期就定死的常量，Swift 的 #if arch(...) 同理（下面这一行就是它自己那一支）")
    #if arch(x86_64)
    line("  Swift 侧的条件编译：这一行是 arch(x86_64) 那一支印出来的（C 那边 §16 用的是 __LP64__，两边各查各的）")
    #elseif arch(arm64)
    line("  Swift 侧的条件编译：这一行是 arch(arm64) 那一支印出来的")
    #else
    line("  Swift 侧的条件编译：两个都不匹配")
    #endif
    var seed: Int32 = 0
    scope {
        let h = CLOpaqueCreate(98765)
        do {
            try CLCStyleAPI.readSeed(ofHandle: h, seed: &seed)
            expect(seed == 98765, "成功路径：ObjC 那个 BOOL + NSError ** 的接口，在 Swift 里变成 throws —— 返回 YES 就走 do 分支，seed 被写成 \(seed)")
        } catch {
            expect(false, "成功路径不该抛：\(error.localizedDescription)")
        }
        CLOpaqueRelease(h)
    }
    scope {
        var untouched: Int32 = 0
        do {
            try CLCStyleAPI.readSeed(ofHandle: nil, seed: &untouched)
            expect(false, "失败路径没报错，本节作废")
        } catch let e as NSError {
            expect(e.domain == "CLCStyleAPI" && e.code == 17 && untouched == 0,
                "把 NULL 句柄传进去：Swift 侧收到一个 NSError（domain=\(e.domain), code=\(e.code)），而 out 参数没有被写（还是 \(untouched)）—— "
                + "§17 那条「先把出参清成 nil、失败路径绝不写它」的纪律，就是为了让 throws 这一侧读到干净的值")
        } catch {
            expect(false, "抛出来的不是 NSError")
        }
    }
    expect(CLOpaqueAliveObjects() == 0, "本节造的句柄也都还了：本章造的还活着 \(CLOpaqueAliveObjects()) 个")
}

// ============================================================
// §23 本章的边界
// ============================================================
line("\n== §23 本章的边界：哪些是量出来的、哪些只能记、哪些留给真机 ==")
line("  量出来并可断言的：整族类型的尺寸与对齐、char 的符号性、无符号回绕、除法与余数的取整方向、整型提升、")
line("            浮点截断与 1 个 ULP 的差异、2^24 上限、前后缀自增、优先级、位运算与移位、短路、")
line("            for/while/do-while/continue/break/switch(含 fallthrough)/goto 的计数、数组连续性与行主序、")
line("            sizeof 与 strlen 的差、UTF-8 字节数、字面量合并、strcmp 的符号、指针步长、退化后的 sizeof、")
line("            出参与 NULL 检查、结构体 padding 与 offsetof、union 位模式与 IEEE 754 三段、正零与负零的位模式和两处算术后果、枚举底类型尺寸、")
line("            引用计数与配平、值传递、递归、可变参数（OC 侧）、回调表与 qsort/bsearch、memcpy/memmove 的结果串、")
line("            calloc 清零、malloc 真失败的那次（跨编译单元才量得到）、编译器对分配的三种折叠、")
line("            宏的展开次数与副作用次数、@encode、结构体属性、NSString <-> char *、")
line("            以及 Swift 侧的类型映射、MemoryLayout、withUnsafe 系列、@convention(c)、throws、宏的可见性。")
line("  只记不跑的（示例一行都没执行，全部来自独立探针，正文以「探针记录」引用编译器/运行时的原文）：")
line("    有符号整数溢出、memcpy 重叠区、realloc 搬家后继续用旧指针、可变参数 count 撒谎、void* + 1 的标准化")
line("    程度、malloc 判空被折之后的汇编长什么样、Swift 把带捕获的闭包当 @convention(c) 传出去、Swift 调 C 可变参数")
line("    函数、Swift 用普通 + 触发溢出 trap、函数式宏在 Swift 里不存在、-Wimplicit-fallthrough 到底什么时候响。")
line("  探针记录：下面每条都是独立小程序在同一套工具链（clang 16 / iPhoneSimulator18.2.sdk / ")
line("    x86_64-apple-ios15.0-simulator / 同一个模拟器设备）上真跑出来的原文，示例本身一行都没执行它们。")
line("    1) memcpy 重叠。源码：char buf[8] = \"abcdefg\"; memcpy(buf + 2, buf, 3);")
line("       -O0 打 ababafg；-O2 打 ababcfg。一个字都没改，只换了优化级别，答案就变了。")
line("       同一行改用 memmove：-O0 与 -O2 都稳定打 ababcfg。")
line("       再加 -fsanitize=address，报的原文是（地址这节略去，本章规定指针不进输出）：")
line("         ERROR: AddressSanitizer: memcpy-param-overlap: memory ranges [0x…] and [0x…] overlap")
line("       它是直接 abort，不是返回错误码 —— sanitizer 也只能事后拦，拦不住「这次结果碰巧对」。")
line("    2) malloc 的判空被折成常数。示例里 CLMallocHugeIsNull 在 -O2 的汇编（缩进是这里重排的，指令一字未改；.cfi_* 略）：")
line("         _CLMallocHugeIsNull:                       ## @CLMallocHugeIsNull")
line("             pushq   %rbp")
line("             movq    %rsp, %rbp")
line("             xorl    %eax, %eax")
line("             popq    %rbp")
line("             retq")
line("       尺寸换成形参的那版（CLMallocIsNullForSize）汇编一字不差也是这六行。第三版（CLMallocUsedIsNull，")
line("       真往那块内存写了 12345 再读回来）被编成：")
line("             testq   %rsi, %rsi / je  LBB34_2 / pushq %rbp / movq %rsp, %rbp")
line("             movq    $12345, (%rsi) / popq %rbp / LBB34_2: xorl %eax, %eax / retq")
line("       —— 连那块假想的内存都不需要了，只剩「往出参写 12345，返回 0」。整份 CLMemory.c 的 -O2 汇编里")
line("       只剩一处 malloc 字样：CLMallocRaw 那句 jmp _malloc（尾调用），也就是唯一那个把指针交出去的函数。")
line("       顺带一条同样被折掉的：CLCallocZeroed 也是六行 return 0。但这两次折叠性质不同 ——")
line("       calloc 本来就承诺全 0，编译器是**知道答案**才折的；malloc 那三版折的是「你的分配一定成功」这个**假设**。")
line("       独立探针（判空之后又真往那块内存写了一个字节再打印）：-O0 打 returned_null=1，")
line("       -O2 打 returned_null=0 外加一行 wrote_ok。前者是分配器说的，后者是编译器折的。")
line("    3) 有符号溢出。源码：int x = 2147483647; int y = x + 1; 打印 y 和 x。")
line("       -O0 打 x+1=-2147483648  x=2147483647，-O2 一模一样，看着「挺正常」。")
line("       这正是它最骗人的地方：UB 不保证当场出错，只保证编译器不必为你的假设负责。")
line("       所以本章从头到尾只用无符号回绕做「溢出」的演示。")
line("    4) 可变参数 count 撒谎。源码：sum(10, 1, 2, 3) —— 说十个只给三个。")
line("       连跑三次分别打 855015054 / 1039683214 / 1022393998，一次都没崩；换 -O2 又是另一个数。")
line("       读过头不会立刻出事，它只是把栈上的邻居当成你的参数加了起来。")
line("    5) 数组退化。源码：long f(int arr[5]) { return (long)sizeof(arr); } 的编译器原文：")
line("         warning: sizeof on array function parameter will return size of 'int *' instead of 'int[5]' [-Wsizeof-array-argument]")
line("       本章的函数刻意写成 int *arr（§3），所以这条警告不会自己冒出来 —— 它是你「以为长度还在」时唯一的哨兵。")
line("    6) void* + 1 的标准化程度。同一行代码：")
line("         -std=c11 -Wall -Wextra            -> 编译通过，一个诊断都没有")
line("         -std=c11 -Wall -Wextra -pedantic  -> warning: arithmetic on a pointer to void is a GNU extension [-Wgnu-pointer-arith]")
line("       「标准 C 里这是编译错误」这句话在这台机器上量不出来：clang 连 -std=c11 都不拦，")
line("       只在 -pedantic 下提醒一句。约束违规是规范层面的措辞，编译器有权宽容。")
line("    7) realloc 搬家。8 字节 realloc 到 4096：moved=1（-O0 与 -O2 都是 1），")
line("       而旧指针 p 那四个字节已经不再是最初的 97 98 99 0 —— 被分配器的空闲链表元数据盖掉了。")
line("       那几个字节每次运行都不同，所以本章一次都没把它们打进输出。")
line("    8) Swift 侧的四条编译期原文：")
line("         调 C 可变参数函数：error: 'CLSumVarargs' is unavailable: Variadic function is unavailable")
line("             （紧跟一条 note：'CLSumVarargs' has been explicitly marked unavailable here）")
line("         带捕获的闭包当 C 函数指针：error: a C function pointer cannot be formed from a closure that captures context")
line("         函数式宏：error: cannot find 'CL_SQR_BAD' in scope（CL_TWICE、CL_STRINGIFY 各一条同样的）")
line("         ObjC 方法名被改写：error: 'readSeedOfHandle(_:seed:)' has been renamed to 'readSeed(ofHandle:seed:)'")
line("    9) Swift 的普通 + 溢出。源码：var x = Int32.max; x = x + 1。先打出 start，然后：")
line("         Child process terminated with signal 4: Illegal instruction（退出码 132）")
line("       值得注意的是 stderr 里只有模拟器这一句，Swift 自己的 fatal error 文案一个字都没进 stderr。")
line("       所以「崩是确定会崩」和「崩了能留下可读日志」是两件事。")
line("    10) -Wimplicit-fallthrough 的真实开关条件（§2 用它替代了教科书说法）。同一段 case 0 少写 break 的代码：")
line("         -Wall -Wextra                        -> 一个诊断都没有（本章编译用的就是这个组合）")
line("         -Wall -Wextra -Wimplicit-fallthrough -> warning: unannotated fall-through between switch labels [-Wimplicit-fallthrough]")
line("             外加两条 note：insert '__attribute__((fallthrough));' to silence this warning / insert 'break;' to avoid fall-through")
line("       开着这条警告，逐个试教科书里那些「写句注释就行」的写法，每个都仍然警告（各 1 条）：")
line("         // fall through、/* fall through */、/* fallthrough */、/* FALLTHRU */、/* falls through */、/* -FALL-THROUGH- */")
line("       换成 __attribute__((fallthrough)); 或 -std=c2x 下的 [[fallthrough]]; 才是 0 条。")
line("       另外 -Wimplicit-fallthrough=1..5 这种带级别的写法在这台 Apple clang 16 上直接是")
line("         warning: unknown warning option（它只收不带 =N 的形式），所以级别调不了。")
line("       结论：本章那段 fallthrough 演示用的是属性写法；「注释里写 fall through 就行」在这台工具链上量不出来。")
line("  本机才成立的数值：long=\(CLSizeofLong()) 与 char 有没有符号（\(CLCharIsSigned() == 1 ? "有" : "没有")）都随目标变。")
line("    换 arm64（真机）之后至少这几处会变：long 仍是 8 但 char 变成无符号（§4 那个 -28 变成 228）、")
line("    CLCharIsSigned() 反过来、Swift 侧 char 字段从 Int8 变成 UInt8（§19 的字段赋值要跟着改）、")
line("    x86_64 独有的 objc_msgSend_stret 一整套在 arm64 上不存在。结构体的 padding 与对齐规则本身不变，具体字节数会变。")
line("  刻意没讲的：C++ 名字修饰与 extern \"C\"、原子操作与内存序（那是并发章）、setjmp/longjmp、")
line("    可变长度数组 VLA、位域布局、函数指针在 arm 上的对齐要求、以及 dlopen/符号可见性。")
line("    另外本章不碰任何具体系统框架的 C API（CGContext、sqlite3、AudioQueue）—— 那些是 26/29 章的主题，")
line("    这里只把「C 层的规则」和「跨界时哪条会变」讲清楚，剩下的是同一套动作换个名字。")
line("  这本书（第 4 章）里今天需要改写的部分：把 int 当「机器字长」（今天是 fixed-width 类型）、")
line("    用 char* 存中文并靠 strlen 数「字数」、把 malloc 的返回值直接赋给对象指针、")
line("    以及用宏做所有常量（今天该用 enum/static const，Swift 侧再用 let 重述一遍 —— §22 那条可见性差异就是原因）。")

if failures > 0 {
    line("\n有 \(failures) 条断言失败")
} else {
    line("\n全部断言通过")
}
line("==== 28 结束 ====")
