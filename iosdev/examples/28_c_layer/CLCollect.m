// ============================================================
// 28 章 · ObjC 侧的证据收集器（把 C 量到的数字排成可打印的行）
//
// C 文件一行都打印不出来（它没有 Foundation；而 NSLog 走 stderr，判定 3 会直接失败），
// 所以「量」在 .c 里，「说」在这里，「印」在 main.swift 里。
// 这个分工本身就是本章要教的东西：C 层管内存，ObjC/Swift 层管字符串与打印。
// ============================================================
#import "CLCollect.h"
#import "CLTypes.h"
#import "CLMacros.h"

#pragma mark - 行收集器

static NSMutableArray<NSString *> *gCLLines = nil;

static void CLLBegin(void) { gCLLines = [NSMutableArray array]; }
static void CLLAdd(NSString *s) { [gCLLines addObject:s]; }
static NSArray<NSString *> *CLLResult(void) {
    NSArray<NSString *> *r = [gCLLines copy];
    gCLLines = nil;
    return r;
}
static NSString *CLBool(BOOL v) { return v ? @"是" : @"否"; }
/// 整数数组拼成一行「1, 2, 3」（不能直接打 NSArray，它的 description 会换行）
static NSString *CLJoin6(const int v[6]) {
    return [NSString stringWithFormat:@"%d, %d, %d, %d, %d, %d", v[0], v[1], v[2], v[3], v[4], v[5]];
}

#pragma mark - §17 用的 ObjC 侧类型

/// C 结构体直接做 ObjC 的属性类型：它是「值」，存在 ivar 里，不是对象，
/// 所以不能塞进 NSArray / NSDictionary —— 那才是跨界最常撞的一堵墙。
@interface CLStructHolder : NSObject
@property (nonatomic) struct CLPackB point;
@end
@implementation CLStructHolder
@end

// 声明在 CLCollect.h 里（Swift 那边也要看得见），这里只写实现
@implementation CLCStyleAPI
+ (BOOL)readSeedOfHandle:(CLOpaqueRef)handle
                      seed:(out int * _Nullable)outSeed
                     error:(out NSError * _Nullable __autoreleasing * _Nullable)outError {
    if (outError != NULL) { *outError = nil; }          // 先清掉，不然调用方读到脏指针
    int seed = CLOpaqueSeed(handle);                    // 真正的活儿还是那个 C 函数
    if (seed < 0) {                                     // C 只会给 -1，这里翻成 NSError
        if (outError != NULL) {
            *outError = [NSError errorWithDomain:@"CLCStyleAPI"
                                            code:17
                                        userInfo:@{NSLocalizedDescriptionKey: @"C 侧返回了 -1（句柄无效）"}];
        }
        return NO;
    }
    if (outSeed != NULL) { *outSeed = seed; }
    return YES;
}
@end

/// §17 的回调：C 侧的函数指针表和「捕获了上下文的 block」并排放
static int CLSquareOfSixViaPointer(int v) { return v * v; }

#pragma mark - §1 数据类型

NSArray<NSString *> *CLLinesTypes(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"sizeof（单位是字节，目标 x86_64-apple-ios15.0-simulator）："
            "char=%zu, short=%zu, int=%zu, long=%zu, long long=%zu, float=%zu, double=%zu",
            CLSizeofChar(), CLSizeofShort(), CLSizeofInt(), CLSizeofLong(),
            CLSizeofLongLong(), CLSizeofFloat(), CLSizeofDouble()]);
    CLLAdd([NSString stringWithFormat:@"指针家族：int *=%zu, size_t=%zu, ptrdiff_t=%zu —— "
            "size_t 是「sizeof 的类型」，ptrdiff_t 是「两指针相减的类型」，宽度都跟指针一致",
            CLSizeofIntPtr(), CLSizeofSizeT(), CLSizeofPtrDiff()]);
    CLLAdd([NSString stringWithFormat:@"对齐：_Alignof(int)=%zu, _Alignof(double)=%zu（结构体的对齐由最宽成员决定，见 §7）",
            CLAlignmentOfInt(), CLAlignmentOfDouble()]);
    CLLAdd(@"long 在这台机器上是 8 而不是 4：这是 LP64（Apple 全线）；Windows 的 LLP64 上 long 是 4、long long 才是 8。"
           "所以「要固定宽度」的地方该写 int32_t / int64_t，别赌 long");
    CLLAdd([NSString stringWithFormat:@"裸 char 有没有符号：%@（SCHAR_MIN=%ld, SCHAR_MAX=%ld）。"
            "「char」的符号是实现定义、不是标准规定的，要当数值用就必须显式写 unsigned char —— §4 那两个字节就是后果",
            CLBool(CLCharIsSigned()), CLMinSignedChar(), CLMaxSignedChar()]);
    CLLAdd([NSString stringWithFormat:@"范围与溢出：INT_MAX=%ld；无符号 +1 = %ld。"
            "无符号回绕是**有定义**的（模 2^n），有符号溢出是**未定义**的，所以本章一次都不量后者",
            CLMaxInt(), CLUnsignedWrapAfterMax()]);
    CLLAdd([NSString stringWithFormat:@"整型除法向 0 取整：7/2=%d，-7/2=%d（不是 -4）；"
            "余数符号跟被除数：7%%2=%d，-7%%2=%d", CLIntDivTrunc(), CLIntDivNegativeTrunc(),
            CLModPositive(), CLModNegative()]);
    CLLAdd(@"这条是 C99 明确保证的恒等式：(a/b)*b + a%b == a。取整方向定了，余数就得跟着变 —— "
           "「向下取整 + 余数非负」是另一套规则，Python 走那一套（-7//2 = -4、-7%2 = 1）；"
           "Swift 和 C 这套完全一致，§1 末尾两边各算一遍。跨语言写取模哈希时最容易翻车的就是这一点");
    CLLAdd([NSString stringWithFormat:@"整型提升：两个 char 相加，结果类型是 int（sizeof=%zu，不是 1）—— "
            "C 里小整型的运算其实都在 int 上做，只有存回去那一刻才截断", CLPromotionResultSizeof()]);
    CLLAdd([NSString stringWithFormat:@"浮点转整数一律向 0 截断：(int)3.9=%d，(int)-3.9=%d（不是 -4）",
            CLFloatToIntTrunc(), CLNegativeFloatToIntTrunc()]);
    long sumBits = CLDoubleToLongBits();
    long threeBits = CLDoubleBitsOfPointThree();
    CLLAdd([NSString stringWithFormat:@"0.1 + 0.2 == 0.3 ？ %@。两条 double 的位模式：%ld 和 %ld，差 %ld —— "
            "正好 1 个 ULP（最后一位）。浮点比较要么留容差，要么换整数/十进制",
            CLBool(CLDoubleSumEqualsPointThree() == 1), sumBits, threeBits, sumBits - threeBits]);
    CLLAdd([NSString stringWithFormat:@"float 只有 24 位有效尾数：(float)16777217 == (float)16777216 ？ %@ —— "
            "超过 2^24 的整数别塞进 float", CLBool(CLFloatCannotHold2To24Plus1() == 1)]);
    return CLLResult();
}

#pragma mark - §2 运算符与控制语句

/// switch 的 default 写在最前面也照样是兜底，单独包一层好让 §2 的行数固定
static int CLDefaultFirstResult(void) {
    int v = 2;
    switch (v) {
        default: return 999;
        case 1: return 11;
        case 2: return 22;
    }
}

NSArray<NSString *> *CLLinesOperators(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"自增：i=5 时 a=i++ 让 a=%d，紧接着 b=++i 让 b=%d —— "
            "后缀先交旧值再自增，前缀先自增再交新值", CLPrefixPostfixFirst(), CLPrefixPostfixSecond()]);
    CLLAdd([NSString stringWithFormat:@"优先级：2 + 3 * 4 = %d；三目那条 a>b ? a : b+1（a=3,b=4）= %d —— "
            "?: 的优先级比 + 低，所以加的是 b 那一支", CLPrecedenceSum(), CLTernaryPrecedence()]);
    CLLAdd([NSString stringWithFormat:@"位运算（12=1100, 10=1010）：&=%d, |=%d, ^=%d, ~0=%d（取反连符号位一起翻，所以是 -1）",
            CLBitwiseAnd(), CLBitwiseOr(), CLBitwiseXor(), CLBitwiseNotZero()]);
    CLLAdd([NSString stringWithFormat:@"移位：1u<<31 = %ld，转成 int 就是 %d；-8>>1 = %d（有符号右移补符号位）；"
            "(unsigned)-8 右移一位再转回 int = %d（高位补 0，得到一个很大的正数）",
            CLShiftLeftOne31Unsigned(), CLShiftLeftOne31(), CLArithmeticShiftRight(), CLLogicalShiftRight()]);
    CLLAdd(@"注意 1<<31 直接对有符号 int 写是未定义行为（结果超出 int 范围），所以这里从无符号出发再显式转回来。"
           "位标志一律用无符号类型");
    CLLAdd([NSString stringWithFormat:@"短路：0 && f() 让 f 跑了 %d 次，1 || f() 跑了 %d 次，1 && f() 跑了 %d 次 —— "
            "右边执行与否只看左边够不够定结论，这就是把昂贵判断放在 && 右边的理由",
            CLShortCircuitAndCalls(), CLShortCircuitOrCalls(), CLShortCircuitAndRunsCalls()]);
    CLLAdd([NSString stringWithFormat:@"循环：for 0..9 求和 = %ld；while 计到 %d；"
            "条件一开始就为假的 do-while 仍跑 %d 次（它先执行再判断）；for 里 continue 计到 %d 个奇数",
            CLForLoopSum0To9(), CLWhileLoopCount(), CLDoWhileRunsOnce(), CLContinueCount()]);
    CLLAdd([NSString stringWithFormat:@"break 只出最内层：5x5 双层、靠 done 标志停外层的那段走了 %d 步 —— "
            "C 没有「跳出外层」的语法，只能标志位或者 goto", CLNestedLoopFlagBreakCount()]);
    CLLAdd([NSString stringWithFormat:@"switch 少写一个 break：case 0 会连着执行 case 1，循环 0..2 累加出来 = %d"
            "（1+10，再 10，再 100）。少写 break 不报错，只会静默地把下一支也跑了；"
            "clang 有 -Wimplicit-fallthrough 专管这件事，但本机量下来和教科书说法不一样：",
            CLSwitchFallthroughAdds()]);
    CLLAdd([NSString stringWithFormat:@"  这条警告不在 -Wall -Wextra 里（本章的编译参数就是这个组合，"
            "少写 break 的那个版本一个诊断都没有），必须显式点名才响；"
            "点名之后，「// fall through」一类的注释在这台 Apple clang 16 上一种都压不住警告，"
            "只有 __attribute__((fallthrough))（以及 C23 的 [[fallthrough]];）行 —— 五种注释写法的原文见 §23 探针记录。"
            "所以本节这段用的是属性而不是注释"]);
    CLLAdd([NSString stringWithFormat:@"default 写在最前面也一样是兜底：case 2 命中 -> %d（位置不影响匹配，只看有没有别的 case 对上）",
            CLDefaultFirstResult()]);
    CLLAdd([NSString stringWithFormat:@"C 没有异常，出错就一路 goto 到清理段：顺利那条返回 %d。"
            "顺带一条：free(NULL) 是合法的，所以清理段里的 free 可以无条件写", CLGotoCleanupValue()]);
    return CLLResult();
}

#pragma mark - §3 数组

NSArray<NSString *> *CLLinesArrays(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"5 个 int 的数组：sizeof = %ld 字节；元素数 = sizeof(a)/sizeof(a[0]) = %ld —— "
            "这个除法是 C 里数组长度的唯一算法，而且只在数组还没退化的地方成立", CLSizeofInt5(), CLIntArrayCount()]);
    CLLAdd([NSString stringWithFormat:@"&a[3] - &a[0] = %ld（单位是「元素」）；先转成 char * 再相减 = %ld 字节。"
            "指针相减的结果永远是元素数，这是最容易记错的一条", CLGapInElements(), CLGapInBytes()]);
    CLLAdd([NSString stringWithFormat:@"二维数组 int m[2][3] 是行主序连续存放：换行的字节跨度 = %ld（正好一行 3 个 int），"
            "m[1][2] = %d（值没被搬走）", CLRowGapInBytes(), CLAtRowCol()]);
    CLLAdd([NSString stringWithFormat:@"数组名还没退化时，&a 的类型是「指向整个数组的指针」int(*)[5]，"
            "它加一跳过整块 = %ld 字节，不是 4", CLWholeArrayPlusOneGap()]);
    CLLAdd([NSString stringWithFormat:@"纯指针算术求和 *(a+i) = %ld —— 和 a[0]+…+a[4] 是同一个数，"
            "a[i] 本来就是 *(a+i) 的语法糖", CLSumViaPointer()]);
    CLLAdd([NSString stringWithFormat:@"退化实测：本地数组 sizeof = %ld；同一个数组传进函数之后 sizeof = %ld。"
            "传进去的已经不是数组，只是一个地址，长度信息彻底没了", CLSizeofRealArray(), CLArrayDecaySizeof()]);
    CLLAdd(@"所以 C 的数组参数必须另外带一个 count：memcpy(dst, src, n)、objc_copyClassList(&count)、"
           "sqlite3_prepare_v2(..., nByte) 里那个「多出来的长度参数」全是同一个原因");
    return CLLResult();
}

#pragma mark - §4 字符数组与 C 字符串

NSArray<NSString *> *CLLinesStrings(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"字面量 \"中文\"：sizeof = %zu 字节，strlen = %ld 字节 —— 差的 1 是结尾的 '\\0'。"
            "C 字符串没有长度字段，长度是「数到 0」", CLSizeofChineseLiteral(), CLUtf8LengthOfChinese()]);
    CLLAdd([NSString stringWithFormat:@"源文件是 UTF-8，一个中文字占 3 个字节，所以 \"中文\" 的 strlen = %ld；"
            "ASCII 的 \"iOS\" 才是 %ld。C 层根本没有「字符」这个概念，只有字节",
            CLUtf8LengthOfChinese(), CLAsciiByteLen()]);
    CLLAdd([NSString stringWithFormat:@"char s[] = \"abc\" 的 sizeof = %ld（把字面量连结尾 0 一起复制进栈）；"
            "而 const char *s = \"abc\" 的 sizeof 是指针宽度 —— 同一个名字，两种东西", CLCharArraySizeof()]);
    CLLAdd([NSString stringWithFormat:@"手动把 s[2] 写成 '\\0'，strlen 立刻变 %ld —— 「长度」完全由第一个 0 决定，"
            "写坏一个字节就当场截断", CLTruncateToTwo()]);
    CLLAdd([NSString stringWithFormat:@"同一个字节（\"中\" 的首字节 0xE4）：按 char 取到 %d，按 unsigned char 取到 %d。"
            "字节没变，是「char 有没有符号」把它解释成了两个数 —— 拿 char 存像素、存二进制就会出这种事",
            CLFirstByteAsChar(), CLFirstByteAsUChar()]);
    CLLAdd([NSString stringWithFormat:@"同一个 .c 里两处 \"merged-check\"：编译器把相同字面量合并成同一份了吗？%@ "
            "（只打布尔；地址每次运行都不同，绝不进输出）", CLBool(CLStringLiteralsMerged() == 1)]);
    CLLAdd([NSString stringWithFormat:@"strcmp 比的是内容不是地址：字面量 \"iOS\" 和一份 memcpy 出来的副本（两块不同的内存）"
            "strcmp 返回 0 吗？%@（0 才是相等）；\"abc\" 对 \"abd\" 的返回值归一化之后是 %d（前小后大）。"
            "只有符号是可靠的，别断言它等于 -1",
            CLBool(CLStrcmpEqual() == 1), CLStrcmpSignOfAbcAbd()]);
    return CLLResult();
}

#pragma mark - §5 指针运算

NSArray<NSString *> *CLLinesPointers(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"指针加一前进多少字节 = sizeof(指向的类型)：char*=%ld, int*=%ld, long*=%ld, double*=%ld",
            CLCharPtrStepBytes(), CLIntPtrStepBytes(), CLLongPtrStepBytes(), CLDoublePtrStepBytes()]);
    CLLAdd([NSString stringWithFormat:@"对照 sizeof：int* 那一步 %ld == sizeof(int)=%zu；"
            "double* 那一步 %ld == sizeof(double)=%zu —— 一条规则同时解释了两件事",
            CLIntPtrStepBytes(), CLSizeofInt(), CLDoublePtrStepBytes(), CLSizeofDouble()]);
    CLLAdd([NSString stringWithFormat:@"void* 加一：%d 字节。void 没有大小，所以标准 C 根本没有定义这条运算"
            "（C 规范把它列为约束违规）—— 但 clang 默许它，按 GNU 扩展当成 1 字节：换成 -std=c11 照样编过，"
            "只有加 -pedantic 才出一句 warning（原文见 §23 探针记录）。编译器不拦不等于标准允许：这一行没有任何标准保证它可用",
            CLVoidPtrStepBytes()]);
    CLLAdd(@"所以跨平台的 C 代码别写 void* + 1：先转成 char */uint8_t *，或者用下标");
    return CLLResult();
}

#pragma mark - §6 出参与二级指针

NSArray<NSString *> *CLLinesOutParams(void) {
    CLLBegin();
    int a = 0, b = 0, c = 0;
    CLOutThreeInts(&a, &b, &c);
    CLLAdd([NSString stringWithFormat:@"三个出参一次填满：%d, %d, %d —— C 函数只有一个返回值，"
            "要往外带多个结果就靠指针", a, b, c]);
    CLLAdd([NSString stringWithFormat:@"二级指针取值 **pp = %d（pp 指向「那个指针」，p 指向那个 int）",
            CLReadThroughDoublePointer()]);
    int good = 0;
    int r1 = CLCallWithNullOut(&good);
    int r2 = CLCallWithNullOut(NULL);
    CLLAdd([NSString stringWithFormat:@"传地址进去：返回码 = %d、出参被写成 %d；传 NULL 进去：返回码 = %d，函数没崩 —— "
            "C 不会替你检查 NULL，检查是函数自己该做的事", r1, good, r2]);
    CLLAdd(@"这就是 CoreFoundation 的签名形状（OSStatus/返回码 + 出参），也正是 ObjC 把它包成"
           "「返回 BOOL + NSError ** 出参」的原因 —— §17 有并排对照");
    CLLAdd(@"顺带一条：OC 属性/参数上那个 `out` 关键字是给 Swift 的所有权提示（决定桥接成 inout 还是只读），对 C 本身没有任何作用");
    return CLLResult();
}

#pragma mark - §7 结构体布局与对齐

NSArray<NSString *> *CLLinesStructs(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"同样三个字段、三种书写顺序：{char,int,char}=%zu 字节，"
            "{int,char,char}=%zu 字节，{char,char,int}=%zu 字节 —— 最大最小差 %zu",
            CLSizeofPackA(), CLSizeofPackB(), CLSizeofPackC(), CLSizeofPackA() - CLSizeofPackB()]);
    CLLAdd([NSString stringWithFormat:@"差在哪：A 里 i 前面挤了两个 1 字节，而 int 要按 4 对齐，"
            "于是中间填了 3 个、尾部又补了 3 个：offsetof(i)=%zu, offsetof(d)=%zu；"
            "B 把同类挤一起：offsetof(i)=%zu（就在开头）",
            CLOffsetIInA(), CLOffsetDInA(), CLOffsetIInB()]);
    CLLAdd([NSString stringWithFormat:@"B 和 C 一样大（%zu vs %zu）：字节排好之后，c/d 谁在前不影响尺寸",
            CLSizeofPackB(), CLSizeofPackC()]);
    CLLAdd([NSString stringWithFormat:@"嵌套：struct{ CLPackB origin; int extra; } 的 sizeof = %zu，"
            "offsetof(extra) = %zu —— 内层结构体的对齐会向外传染", CLSizeofRectLike(), CLOffsetExtraInRect()]);
    CLLAdd([NSString stringWithFormat:@"_Alignof(struct CLPackA) = %zu：结构体的对齐等于它最宽成员的对齐，不是它自己的尺寸",
            CLAlignmentOfPackA()]);
    CLLAdd(@"这条规则在工程里是真能省内存的：字段按宽度从大到小排，结构体就可能小一档；交错着写就白填一堆 padding。"
           "反过来「靠 padding 对齐到 2 的幂」也是故意做的 —— 看 offsetof 就能分清哪种是哪种");
    return CLLResult();
}

#pragma mark - §8 联合体与浮点位模式

NSArray<NSString *> *CLLinesUnions(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"union { float f; uint32_t bits; } 的 sizeof = %zu —— "
            "所有成员都从同一块内存的 0 偏移开始，谁大谁定总尺寸", CLSizeofFloatBits()]);
    uint32_t oneBits = CLBitsOf(1.0f);
    uint32_t twoBits = CLBitsOf(2.0f);
    uint32_t negBits = CLBitsOf(-1.0f);
    CLLAdd([NSString stringWithFormat:@"位模式：1.0f = %u（0x%08X），2.0f = %u，-1.0f = %u",
            oneBits, oneBits, twoBits, negBits]);
    CLLAdd([NSString stringWithFormat:@"拆出来看 1.0f：符号位 %u、指数段 %u（偏置 127，真指数 %ld）、尾数段 %u；"
            "2.0f 的指数段 = %u（正好大一档）；-1.0f 的符号位 = %u",
            (unsigned)CLSignOfBits(oneBits), (unsigned)CLExponentField(oneBits), (long)CLExponentField(oneBits) - 127L,
            (unsigned)CLMantissaField(oneBits), (unsigned)CLExponentField(twoBits), (unsigned)CLSignOfBits(negBits)]);
    CLLAdd([NSString stringWithFormat:@"0.0f 的位模式 = 0x%08X，-0.0f = 0x%08X：只差最高那一位；"
            "可它们 == 比较的结果是 %@。算术里它会露出来：1.0f / -0.0f 是负无穷吗 %@，"
            "atan2f 把 -0.0 与 +0.0 分在 -pi / +pi 两侧吗 %@ —— "
            "符号位单独占一位，所以「负零」在内存里真的存在，只是 == 把它抹平了",
            CLBitsOf(0.0f), CLBitsOf(-0.0f),
            CLFloatZeroEqualsNegativeZero() ? @"相等" : @"不等",
            CLReciprocalOfNegativeZeroIsNegInf() ? @"是" : @"否",
            CLAtan2DistinguishesZeros() ? @"是" : @"否"]);
    CLLAdd(@"这就是 IEEE 754 单精度：1 位符号 + 8 位指数 + 23 位尾数，§1 那个「24 位有效尾数」的上限就是这么来的。"
           "union 是「同一块内存换种解释」的合法手段；Swift 没有 union，对应写法是 Float.bitPattern 或 withUnsafeBytes（§18）");
    return CLLResult();
}

#pragma mark - §9 枚举

NSArray<NSString *> *CLLinesEnums(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"enum CLColor{RED=1,GREEN=2,BLUE=4,BIG=100000} 的 sizeof = %zu —— "
            "编译器挑了一个和 int 同样宽的整型，不是「按最大值的位数算」；至于它有没有符号，下一段有办法量出来",
            CLSizeofColorEnum()]);
    CLLAdd([NSString stringWithFormat:@"枚举值就是整数：RED=%ld, BLUE=%ld, BIG=%ld；把 RED|BLUE 当枚举传进去再打出来 = %ld —— "
            "编译器完全不检查位标志组合是不是一个合法的 case",
            CLColorValue(CL_RED), CLColorValue(CL_BLUE), CLColorValue(CL_BIG),
            CLColorValue((enum CLColor)(CL_RED | CL_BLUE))]);
    CLLAdd([NSString stringWithFormat:@"底类型有没有符号，sizeof 是看不出来的（两个枚举都是 %zu 字节）。换一种问法：拿小的减大的，"
            "再把结果当回枚举本身。enum CLColor{1,2,4,100000} 算 RED-BLUE 得 %ld —— 回绕成了一个巨大的正数，"
            "所以 clang 给它的底类型是 **unsigned int**；enum CLSigned{-7,7} 算 NEG-POS 得 %ld —— 还是负数，"
            "底类型是 **int**。一个枚举有没有负数，就足以让编译器换掉它的底类型",
            CLSizeofColorEnum(), CLColorSubtractWrapped(), CLSignedSubtractWrapped()]);
    CLLAdd([NSString stringWithFormat:@"带负数的枚举 {NEG=-7,POS=7} 的 sizeof = %zu：尺寸没变，变的是符号性 —— "
            "这一条也正是 §18 里 Swift 那边 CLColor.rawValue 是 UInt32、CLSigned.rawValue 是 Int32 的原因",
            CLSizeofSignedEnum()]);
    CLLAdd(@"对照 ObjC：NS_ENUM / NS_OPTIONS 的用处就是把底类型写死，这样 Swift 才敢把它翻成 enum / OptionSet（§22 实测）");
    return CLLResult();
}

#pragma mark - §10 不透明句柄

NSArray<NSString *> *CLLinesHandles(void) {
    CLLBegin();
    long alive0 = CLOpaqueAliveObjects();
    CLOpaqueRef h = CLOpaqueCreate(2026);
    CLLAdd([NSString stringWithFormat:@"Create 之后：引用计数 = %ld，getter 读到 seed = %d，进程内本章造的还活着 %ld 个 —— "
            "外面拿到的是 CLOpaqueRef（一个指针），字段看不见也构造不出来",
            CLOpaqueRefCount(h), CLOpaqueSeed(h), CLOpaqueAliveObjects()]);
    CLOpaqueRetain(h);
    CLOpaqueRetain(h);
    CLLAdd([NSString stringWithFormat:@"Retain 两次 -> 计数 = %ld：结构体的定义只在那个 .c 里，"
            "所以「计数加一」必须由库自己提供函数", CLOpaqueRefCount(h)]);
    CLOpaqueRelease(h);
    CLOpaqueRelease(h);
    CLLAdd([NSString stringWithFormat:@"Release 两次 -> 计数 = %ld，还活着 %ld 个", CLOpaqueRefCount(h), CLOpaqueAliveObjects()]);
    CLOpaqueRelease(h);
    CLLAdd([NSString stringWithFormat:@"再 Release 一次 -> 计数归零、真 free：还活着 %ld 个，回到起点的 %ld 个。"
            "此刻那个指针已经是野指针，读它就是 UB —— C 不会替你发现", CLOpaqueAliveObjects(), alive0]);
    CLLAdd([NSString stringWithFormat:@"给 Retain/Release 传 NULL：不崩（函数自己挡），"
            "CLOpaqueRefCount(NULL) = %ld（用 -1 表示无效句柄，而不是返回 0，好和「已释放」区分）",
            CLOpaqueRefCount(NULL)]);
    CLLAdd(@"CoreFoundation 全系列（CFStringRef、CGContextRef、SecKeyRef…）都是这个形状。"
           "在 ARC 下用它们就得自己配平 Create/Copy 与 Release —— 这是桥接里最容易漏的一段");
    return CLLResult();
}

#pragma mark - §11 函数、值传递与递归

NSArray<NSString *> *CLLinesFunctions(void) {
    CLLBegin();
    int x = 1, y = 2;
    CLTrySwap(x, y);
    CLLAdd([NSString stringWithFormat:@"值传递：函数里换完再出来，x=%d, y=%d —— 一点没变，换的是两份拷贝。"
            "想真的换就得给地址（§6），C 没有「引用传递」这个语言特性", x, y]);
    CLLAdd([NSString stringWithFormat:@"递归：Fibonacci(0)=%d, (1)=%d, (10)=%d, (20)=%d —— "
            "fib(20) 展开了两万多次调用；递归的问题从来不是「能不能写」，是「有没有记忆化」",
            CLFibonacci(0), CLFibonacci(1), CLFibonacci(10), CLFibonacci(20)]);
    CLLAdd([NSString stringWithFormat:@"两个同签名的普通函数：CLAddFunc(3,4)=%d, CLMulFunc(3,4)=%d —— 它们是 §13 那张回调表的原料",
            CLAddFunc(3, 4), CLMulFunc(3, 4)]);
    return CLLResult();
}

#pragma mark - §12 可变参数

NSArray<NSString *> *CLLinesVarargs(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"va_arg 靠 count 决定读几次：CLSumVarargs(5, 1,2,3,4,5) = %d，"
            "CLSumVarargs(0) = %d，CLSumVarargs(3, 10,20,30) = %d",
            CLSumVarargs(5, 1, 2, 3, 4, 5), CLSumVarargs(0), CLSumVarargs(3, 10, 20, 30)]);
    CLLAdd([NSString stringWithFormat:@"CLMaxOfVarargs(5, 3,9,2,9,1) = %d；只给 1 个 -> %d",
            CLMaxOfVarargs(5, 3, 9, 2, 9, 1), CLMaxOfVarargs(1, 42)]);
    CLLAdd(@"这个 count 是唯一的护栏：说少了漏读，说多了读过头（都是 UB，探针记录见 §23）。"
           "所以 C 库里更常见的形态是「以哨兵结尾」（execl(\"prog\", ..., NULL)）或者干脆传数组 + 长度");
    CLLAdd(@"另一条只有这里讲得下：va_arg(ap, float) 永远是错的 —— 可变参数里 float 已被提升成 double，"
           "必须 va_arg(ap, double)。printf 的 %f 背后就是这个提升");
    return CLLResult();
}

#pragma mark - §13 函数指针与回调表

NSArray<NSString *> *CLLinesFuncPointers(void) {
    CLLBegin();
    int tableSize = (int)CLTableSize();
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (int i = 0; i < tableSize; i++) {
        [items addObject:[NSString stringWithFormat:@"[%d] %@ -> %d", i,
                          [NSString stringWithUTF8String:CLMapNameAt(i)], CLApplyTable(i, 5)]];
    }
    CLLAdd([NSString stringWithFormat:@"表里有 %d 项，按下标取出名字并各调一次（同一个入参 5）：%@",
            tableSize, [items componentsJoinedByString:@"  "]]);
    CLLAdd([NSString stringWithFormat:@"越界：CLApplyTable(99, 5) = %d —— CLMapAt 返回 NULL，"
            "调用方必须自己挡；C 里函数指针可以是 NULL，而调用 NULL 就是跳飞", CLApplyTable(99, 5)]);
    CLLAdd(@"这张表和 27 章的 selector / target-action 是同一件事的低配版：按名字找实现。"
           "区别是 C 的表要自己维护，名字拼错了编译器不查");
    int arr[6] = { 5, 3, 9, 1, 7, 7 };
    CLSortInts(arr, 6);
    CLLAdd([NSString stringWithFormat:@"qsort 的比较函数签名必须写成 int(const void *, const void *)："
            "5,3,9,1,7,7 排完是 %@（比较函数里第一件事就是转回 int）", CLJoin6(arr)]);
    CLLAdd([NSString stringWithFormat:@"bsearch 找到给那个元素、找不到给 NULL：查 9 -> %d，查 4 -> %d",
            CLSearchSorted(arr, 6, 9), CLSearchSorted(arr, 6, 4)]);
    CLLAdd(@"所以「传一个比较函数」在 C 里必然伴随 const void * 和一次强制转换；"
           "Swift 的 sorted(by:) 用泛型把这一整套收走了（§20 对照）");
    return CLLResult();
}

#pragma mark - §14 memcpy / memmove

NSArray<NSString *> *CLLinesMemoryBlocks(void) {
    CLLBegin();
    char src[8];
    CLFillBuffer(src, 8);
    char dst[8];
    CLFillBuffer(dst, 8);
    for (int i = 0; i < 8; i++) { dst[i] = '-'; }      // 先把目的涂成可见的脏值
    dst[7] = '\0';
    CLCopyNonOverlap(dst, src);
    CLLAdd([NSString stringWithFormat:@"两块不重叠的内存：目的先是 \"-----\"，memcpy(dst, src, 5) 之后 = \"%@\"",
            [NSString stringWithUTF8String:dst]]);
    char ov[8];
    CLFillBuffer(ov, 8);
    CLCopyOverlapWithMemmove(ov);
    CLLAdd([NSString stringWithFormat:@"源和目的重叠（把 buf[0..2] 搬到 buf[2..4]）：memmove 之后 = \"%@\" —— "
            "它自己判断方向，搬过去的是**原来的**那三个字节",
            [NSString stringWithUTF8String:ov]]);
    CLLAdd(@"探针记录：同一段重叠交给 memcpy，本机 -O0 得到 \"ababafg\"、-O2 得到 \"ababcfg\"（memmove 两版都是 \"ababcfg\"）；"
           "开 -fsanitize=address 直接报 \"AddressSanitizer: memcpy-param-overlap: memory ranges [0x…] and [0x…] overlap\"。"
           "同一段代码、两个答案，这就是 UB 的样子：memcpy 只保证不重叠，重叠之后没有「正确结果」可言，所以本章不给它下断言");
    CLLAdd(@"记一条就够：可能交叠 -> memmove；确认不交叠 -> memcpy（更快，能上 SIMD）");
    return CLLResult();
}

#pragma mark - §15 malloc 家族

// 第四版探针：分配在 CLMemory.c（CLMallocRaw），判空写在这个编译单元里。
// 跨了编译单元，编译器就看不穿那次调用，也就删不掉它 —— 这一版量到的才是分配器说的话。
// 返回 1 表示返回了 NULL；否则往那块内存写一个常数再读回来，值交给 *readBack。
static int CLMallocProbe(size_t n, long *readBack) {
    long *p = (long *)CLMallocRaw(n);
    if (p == NULL) { if (readBack) { *readBack = -1; } return 1; }
    *p = 12345;
    if (readBack) { *readBack = *p; }
    CLFreeRaw(p);
    return 0;
}

NSArray<NSString *> *CLLinesMalloc(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"calloc 保证全 0：calloc(4, sizeof(int)) 之后第一个元素 = %ld（malloc 不保证，"
            "拿到的是上一手留下的脏内存）", CLCallocZeroed()]);
    // 前三版：分配和判空写在同一个 C 函数里
    CLLAdd([NSString stringWithFormat:@"同一个「大到不可能」的尺寸先问三遍：尺寸写死在源码里的那版答 返回 NULL？%@；"
            "尺寸换成形参的那版答 返回 NULL？%@；第三版还往那块内存写了个数再读回来，它答 返回 NULL？%@。"
            "三版全说「不是 NULL」",
            CLBool(CLMallocHugeIsNull() == 1), CLBool(CLMallocIsNullForSize((size_t)-1) == 1),
            CLBool(CLMallocUsedIsNull((size_t)-1, NULL) == 1)]);
    CLLAdd(@"这三版量到的都不是分配器，而是编译器。「分配 + 判空 + 立刻 free」写在同一个函数里就没有可观测的副作用，"
           "-O2 于是把 malloc 连同那句判空一起删掉，整个函数编成一句 return 0；连第三版「写进去再读回来」都被折成 "
           "「把编译器自己写的那个常数交给出参」（两版的汇编原文见 §23 探针记录）。它依赖的假设是：这次分配要么成功、"
           "要么根本不需要真的发生。尺寸是不是常量、内存有没有被写过，都不影响这个结论。");
    // 第四版：分配在另一个编译单元（CLMemory.c 的 CLMallocRaw），判空写在这里
    long rbHuge = 0, rb62 = 0, rb40 = 0, rb64 = 0;
    int hugeIsNull = CLMallocProbe((size_t)-1, &rbHuge);
    int b62IsNull = CLMallocProbe((size_t)1 << 62, &rb62);
    int b40IsNull = CLMallocProbe((size_t)1 << 40, &rb40);
    int b64IsNull = CLMallocProbe(64, &rb64);
    CLLAdd([NSString stringWithFormat:@"把分配挪到另一个编译单元（CLMemory.c 里一个只 return malloc(n) 的函数），"
            "判空写在本文件，第四版终于量到了真答案：malloc((size_t)-1) 返回 NULL？%@；malloc(1<<62) 返回 NULL？%@；"
            "malloc(1<<40) 返回 NULL？%@；malloc(64) 返回 NULL？%@。四格里前两个是 NULL，后两个不是",
            CLBool(hugeIsNull == 1), CLBool(b62IsNull == 1), CLBool(b40IsNull == 1), CLBool(b64IsNull == 1)]);
    CLLAdd([NSString stringWithFormat:@"同一台机器、同一次运行里，「不可能的大小」确实给 NULL（所以 malloc 之后必须查），"
            "而 1TB 的 malloc(1<<40) 居然成功：往里写 %ld 读回来还是 %ld。差别就在 64 位虚拟地址空间够大 —— "
            "malloc 只是在账本上划了一段地址，返回非空并不等于这块内存真的可用，写入才见分晓", rb40, rb40]);
    CLLAdd(@"所以这一节真正的结论有两条：其一，分配失败是**返回 NULL**，不抛异常、不 abort，每一次 malloc 后面都必须查；"
           "其二，「读源码推断优化器会留下什么」是不可靠的 —— 同一个判空写在不同的编译单元里，一个会被删干净、一个不会。"
           "涉及分配器、溢出、内存重叠这类边界行为时，只有把反汇编摊开看、或者换编译单元再跑一遍才算数");
    CLLAdd(@"三件套的分工：malloc 只要一块（内容不定）、calloc 要清零的、realloc 要变大的。"
           "realloc 可能原地扩也可能搬家，所以必须把返回值接回同一个变量：写成 realloc(p, n) 而不看返回值，"
           "搬家之后就是一枚悬垂指针（探针记录见 §23）");
    CLLAdd(@"free 之后再读就是 UB。C 没有任何机制帮你发现这件事 —— ARC 换来的正是这一条");
    return CLLResult();
}

#pragma mark - §16 宏

NSArray<NSString *> *CLLinesMacros(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"不带括号：#define SQR(x) x*x，传 SQR(3+1) 展开成 3 + 1 * 3 + 1 = %d；"
            "全括号的版本 = %d（正确值 16）", CLMacroSqrOfSum(3), CLMacroSafeSqrOfSum(3)]);
    CLLAdd([NSString stringWithFormat:@"参数被展开两次：CL_TWICE(x) 定义为 ((x)+(x))，"
            "传一个「每调一次就返回下一个 10 倍」的函数 —— 宏版得到 %d（10 + 20），函数版得到 %d（10 + 10）；"
            "副作用次数分别是 %d 和 %d",
            CLMacroTwiceValue(), CLFuncTwiceValue(), CLMacroTwiceSideEffects(), CLFuncTwiceSideEffects()]);
    CLLAdd(@"上面这一条就是「宏不是函数」的全部证据：同一个表达式，宏多跑了一次，还多算了一次值。"
           "工程里的写法是：复杂逻辑一律写成 inline 函数，只有必须发生在编译期的事（拼名字、字符串化、条件编译）才用宏");
    CLLAdd([NSString stringWithFormat:@"多语句宏包进 do{...}while(0)：跑两轮计到 %d。"
            "不包的话，if (x) MACRO(); else ... 会被拆成「第一条语句归 if，第二条谁都不归」",
            CLMacroDoWhileCount(1)]);
    CLLAdd([NSString stringWithFormat:@"# 把参数变字符串：CL_STRINGIFY(CL_Paste_Target) = \"%@\" —— 日志宏的原料",
            [NSString stringWithUTF8String:CLStringifyName()]]);
    CLLAdd([NSString stringWithFormat:@"## 拼标识符：CL_PASTE(CL_, answer) 拼出 CL_answer = %d —— "
            "拼完才去找宏，所以嵌套一深就容易拼出一个不存在的东西", CLPastedInto()]);
    CLLAdd([NSString stringWithFormat:@"__func__ 展开成当前函数名（一串字符，不是地址）：\"%@\"",
            [NSString stringWithUTF8String:CLCurrentFuncName()]]);
    CLLAdd([NSString stringWithFormat:@"条件编译走的哪一支：编号 = %ld（个位 1 = __LP64__ 成立；十位 1 = 探到了 <stdint.h>）。"
            "#if 在编译期就定死，编进去之后另一支根本不存在，运行时改不了", CLConditionBranchId()]);
    CLLAdd([NSString stringWithFormat:@"Swift 能不能看见这些宏？只有对象式的简单常量能（CL_answer = %d 那类），"
            "带参数的都看不见 —— 实测见 §22", CLPastedInto()]);
    return CLLResult();
}

#pragma mark - §17 C 与 Objective-C 的边界

NSArray<NSString *> *CLLinesInterop(void) {
    CLLBegin();
    CLLAdd([NSString stringWithFormat:@"同一个 C 函数从 ObjC 里调：CLIntArrayCount() = %ld，"
            "和 C 文件自己量的一致 —— .m 只是 include 了同一份 CLTypes.h，链接的是同一份实现，不存在两份代码",
            CLIntArrayCount()]);
    CLLAdd([NSString stringWithFormat:@"@encode 眼里的 C 类型：int=\"%s\", double=\"%s\", float=\"%s\", char=\"%s\", "
            "int *=\"%s\", 结构体 CLPackA=\"%s\", 结构体 CLPackB=\"%s\"",
            @encode(int), @encode(double), @encode(float), @encode(char), @encode(int *),
            @encode(struct CLPackA), @encode(struct CLPackB)]);
    CLLAdd(@"结构体的编码把字段名和 padding 都写进去了（'x' 就是补的字节），所以 §7 那个「字段顺序影响尺寸」"
           "在 @encode 的字符串上直接看得见。这就是 NSValue 的 valueWithBytes:objCType:、"
           "以及 KVC 装箱、归档所使用的类型描述");
    struct CLPackB made = CLMakePackB();
    CLLAdd([NSString stringWithFormat:@"C 按值返回结构体，ObjC 直接接住：i=%d, c=%d, d=%d；再交回 C 求和 = %d",
            made.i, made.c, made.d, CLSumPackB(&made)]);
    CLStructHolder *holder = [CLStructHolder new];
    holder.point = made;                       // 结构体能整体赋值，但它不是对象
    CLLAdd([NSString stringWithFormat:@"结构体做 ObjC 属性：写进去再读回来 i=%d, c=%d, d=%d —— 它是 ivar 里的一段值，"
            "没有 retain，也不能直接装进 NSArray（那要包成 NSValue）", holder.point.i, holder.point.c, holder.point.d]);
    struct CLPackB filled;
    filled.i = 0; filled.c = 0; filled.d = 0;
    CLFillPackB(&filled);
    CLLAdd([NSString stringWithFormat:@"C 往调用方的结构体里写：%d, %d, %d（out 参数在结构体上的形态）",
            filled.i, filled.c, filled.d]);
    const char *cs = CLStaticCString();
    NSString *oc = [NSString stringWithUTF8String:cs];
    // 正确的回程：UTF8String 出来的那串字节再用 stringWithUTF8String 包回去
    NSString *roundTrip = [NSString stringWithUTF8String:[oc UTF8String]];
    // 反面教材：同一个 char * 直接交给 %s，它不按 UTF-8 解，于是一串乱码
    NSString *viaPercentS = [NSString stringWithFormat:@"%s", [oc UTF8String]];
    CLLAdd([NSString stringWithFormat:@"C 字符串 -> NSString：\"%@\"；再走 UTF8String + stringWithUTF8String 回到 NSString，"
            "内容一字不差吗？%@；NSString 侧数到 %lu 个 UTF-8 字节 —— NSString 是对象（自带编码和长度），"
            "char * 只是一段还没被解释的字节，两个方向都得显式写转换",
            oc, [roundTrip isEqualToString:oc] ? @"是" : @"否",
            (unsigned long)[oc lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]);
    CLLAdd([NSString stringWithFormat:@"同一段字节的两种打印法：先包成 NSString 再交给 %%@ 得到 \"%@\"，"
            "直接把 char * 交给 %%s 得到 \"%@\" —— stringWithFormat 里的 %%s 只按逐字节取字符，不认 UTF-8，"
            "两串相等吗？%@。这就是 27 章那条「中文一律走 %%@」在 C 层的另一半原因",
            oc, viaPercentS, [viaPercentS isEqualToString:oc] ? @"相等" : @"不等"]);
    CLOpaqueRef h2 = CLOpaqueCreate(31415);
    int seedOut = 0;
    NSError *err1 = nil;
    BOOL ok1 = [CLCStyleAPI readSeedOfHandle:h2 seed:&seedOut error:&err1];
    int seedOut2 = 0;
    NSError *err2 = nil;
    BOOL ok2 = [CLCStyleAPI readSeedOfHandle:NULL seed:&seedOut2 error:&err2];
    CLLAdd([NSString stringWithFormat:@"失败约定的两套：C 那边是「返回码 + 出参」（§6）；ObjC 把它包成"
            "「返回 %@ + NSError ** 出参」。有效句柄 -> %@, seed=%d, error=%@；"
            "NULL 句柄 -> %@, seed 仍是 %d, error 的 domain=%@ code=%ld desc=\"%@\"",
            CLBool(ok1), CLBool(ok1), seedOut, err1 == nil ? @"nil" : @"非 nil",
            CLBool(ok2), seedOut2, err2.domain, (long)err2.code, err2.localizedDescription]);
    CLLAdd(@"注意 NSError ** 那条的三步：先把出参清成 nil、再判调用方有没有传地址进来、成功路径绝不写它 —— "
           "这三步在 §6 的 C 函数里同样存在，只是 C 用返回码表达。Swift 的 throws 是同一套约定的自动版（§22）");
    CLIntMap fn = CLMapAt(1);
    int viaPointer = fn ? fn(6) : -1;
    CLLAdd([NSString stringWithFormat:@"ObjC 里存一个 C 函数指针：CLMapAt(1) 拿到的是表里的 square-it，"
            "调用它算 6 -> %d；和 CLApplyTable(1, 6) = %d 一致。本地定义的 C 函数也能当函数指针用（CLSquareOfSixViaPointer 算 6 = %d）",
            viaPointer, CLApplyTable(1, 6), CLSquareOfSixViaPointer(6)]);
    __block int captured = 100;
    int (^block)(int) = ^(int v) { return v + captured; };
    captured = 7;
    CLLAdd([NSString stringWithFormat:@"block 与函数指针的分水岭：block 能捕获上下文 —— 这个 block 算 6 得到 %d"
            "（captured 后来被改成 7，block 读到的跟着变），而函数指针只能读全局变量。"
            "反过来，把一个 block 交给「要函数指针」的 C 接口，必须靠一个不带任何捕获的 trampoline（§20 在 Swift 里演一遍）",
            block(6)]);
    CLLAdd([NSString stringWithFormat:@"同一条对照的另一半：C 表里的 square-it 是纯函数，调两次结果一样（%d, %d）；"
            "block 那次的结果依赖 captured，换个人再调就可能是另一个数",
            fn ? fn(6) : -1, CLSquareOfSixViaPointer(6)]);
    CLOpaqueRelease(h2);
    CLLAdd([NSString stringWithFormat:@"本节收尾：句柄已经 Release，本章造的还活着 %ld 个 —— "
            "§10 和 §17 各造各还，谁也没给后面的小节留脏计数", CLOpaqueAliveObjects()]);
    return CLLResult();
}
