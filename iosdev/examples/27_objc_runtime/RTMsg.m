// ============================================================
// 27 章 OC 侧 · 第一部分：选择器、nil 返回值、消息发送路径、隐藏参数、类型编码
// ============================================================
#import "RTRuntime.h"
#import "RTCommon.h"
#import "RTForward.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreGraphics/CoreGraphics.h>

@implementation RTL
+ (NSMutableArray *)bucket {
    static NSMutableArray *b;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ b = [NSMutableArray new]; });
    return b;
}
+ (void)begin { [[self bucket] removeAllObjects]; }
+ (void)add:(NSString *)line { [[self bucket] addObject:line]; }
+ (NSArray<NSString *> *)end { return [[self bucket] copy]; }
+ (NSUInteger)count { return [[self bucket] count]; }
+ (NSMutableArray *)recordBoard {
    static NSMutableArray *r;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ r = [NSMutableArray new]; });
    return r;
}
+ (void)record:(NSString *)line { [[self recordBoard] addObject:line]; }
+ (NSArray<NSString *> *)records { return [[self recordBoard] copy]; }
@end

// ---------------------------------------------------------------- 给 §1~§4 用的类
struct RTPair { float x, y; };
struct RTQuad { double a, b, c, d; };

@interface RTGreeter : NSObject
- (NSString *)greet:(NSString *)who;
- (int)number;
- (long long)bigNumber;
- (unsigned long long)unsignedBig;
- (short)smallInt;
- (char)byte;
- (BOOL)flag;
- (float)floatNum;
- (double)doubleNum;
- (long double)longDoubleNum;
- (unichar)twoByteChar;
- (void)nothing;
- (id)object;
- (Class)aClass;
- (SEL)aSelector;
- (CGRect)rectValue;
- (CGPoint)pointValue;
- (CGSize)sizeValue;
- (NSRange)rangeValue;
- (CGVector)vectorValue;
- (CGAffineTransform)xformValue;
- (struct RTQuad)quadValue;      // 32 字节：非寄存器结构体
- (struct RTPair)pairValue;      // 8 字节：寄存器结构体
- (NSDictionary *)dictValue;
- (NSString *)describeSelf;
@end

// 声明了但**故意不实现**的方法：只能另开一个分类声明它们，
// 否则 clang 会对主 @implementation 报 -Wincomplete-implementation（判定 1 不允许任何告警）。
@interface RTGreeter (OnlyDeclared)
- (void)neverImplemented;
- (NSString *)alsoNeverImplemented;
@end

@implementation RTGreeter
- (NSString *)greet:(NSString *)who { return [@"你好，" stringByAppendingString:who]; }
- (int)number { return 424242; }
- (long long)bigNumber { return 1234567890123LL; }
- (unsigned long long)unsignedBig { return 9876543210987ULL; }
- (short)smallInt { return 33; }
- (char)byte { return 'A'; }
- (BOOL)flag { return YES; }
- (float)floatNum { return 1.5f; }
- (double)doubleNum { return 2.25; }
- (long double)longDoubleNum { return 3.125L; }
- (unichar)twoByteChar { return 0x4e2d; }
- (void)nothing {}
- (id)object { return @"一个对象"; }
- (Class)aClass { return [RTGreeter class]; }
- (SEL)aSelector { return @selector(number); }
- (CGRect)rectValue { return CGRectMake(1.5, 2.5, 3.5, 4.5); }
- (CGPoint)pointValue { return CGPointMake(5.5, 6.5); }
- (CGSize)sizeValue { return CGSizeMake(7.5, 8.5); }
- (NSRange)rangeValue { return NSMakeRange(9, 10); }
- (CGVector)vectorValue { return CGVectorMake(11.5, 12.5); }
- (CGAffineTransform)xformValue { return CGAffineTransformMake(13, 14, 15, 16, 17, 18); }
- (struct RTQuad)quadValue { struct RTQuad q; q.a = 21; q.b = 22; q.c = 23; q.d = 24; return q; }
- (struct RTPair)pairValue { struct RTPair p; p.x = 31; p.y = 32; return p; }
- (NSDictionary *)dictValue { return @{@"k": @1}; }
- (NSString *)describeSelf { return NSStringFromClass([self class]); }
@end

/// §4 用：同一个 IMP 挂到两个选标上，靠 _cmd 分辨
@interface RTAlias : NSObject
- (NSString *)whichOneA;
- (NSString *)whichOneB;
@end
@implementation RTAlias
- (NSString *)whichOneA { return [@"同一个实现看到 _cmd=" stringByAppendingString:NSStringFromSelector(_cmd)]; }
- (NSString *)whichOneB { return [@"同一个实现看到 _cmd=" stringByAppendingString:NSStringFromSelector(_cmd)]; }
@end

/// §3 用：显式走 super 的 objc_msgSendSuper
@interface RTSuperBase : NSObject
- (NSString *)tag;
@end
@implementation RTSuperBase
- (NSString *)tag { return @"基类的 tag"; }
@end

@interface RTSuperSub : RTSuperBase
- (NSString *)tag;
- (NSString *)viaSelf;
- (NSString *)viaSuper;
- (NSString *)viaRuntimeSuper;
@end
@implementation RTSuperSub
- (NSString *)tag { return [@"子类的 tag ← " stringByAppendingString:[super tag]]; }
- (NSString *)viaSelf { return [self tag]; }
- (NSString *)viaSuper { return [super tag]; }
- (NSString *)viaRuntimeSuper {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    NSString *(*fn)(struct objc_super *, SEL) = (NSString *(*)(struct objc_super *, SEL))objc_msgSendSuper;
    return fn(&sup, @selector(tag));
}
@end

// ---------------------------------------------------------------- §1 选择器
NSArray<NSString *> *RTLinesSelectors(void) {
    [RTL begin];
    SEL s1 = @selector(greet:);
    SEL s2 = sel_registerName("greet:");
    [RTL add:[NSString stringWithFormat:@"@selector(greet:) 的字符串=%s", sel_getName(s1)]];
    [RTL add:[NSString stringWithFormat:@"同一个字符串走 sel_registerName 得到的 SEL 与 @selector 相等=%d（SEL 是全局唯一化后的指针）", s1 == s2]];
    [RTL add:[NSString stringWithFormat:@"NSSelectorFromString(@\"greet:\") 也相等=%d", NSSelectorFromString(@"greet:") == s1]];
    [RTL add:[NSString stringWithFormat:@"SEL 的指针值相等性可直接用 ==，也可用 sel_isEqual=%d", sel_isEqual(s1, s2)]];

    SEL a = @selector(number);
    SEL b = @selector(neverImplemented);
    [RTL add:[NSString stringWithFormat:@"两个无参方法的 SEL 不同=%d；它们的字符串分别是 %s / %s", a != b, sel_getName(a), sel_getName(b)]];
    [RTL add:@"选择器字符串只含关键字标签，不含类型：setAge:(int) 与 setAge:(NSString *) 是同一个 SEL，见下"];
    SEL p1 = sel_registerName("setValue:forKey:");
    [RTL add:[NSString stringWithFormat:@"setValue:forKey: 的字符串=%s（每个参数一个冒号，标签文字进选择器）", sel_getName(p1)]];
    [RTL add:[NSString stringWithFormat:@"零参方法的选择器不带冒号：number 的字符串=%s；把名字改成带冒号的 number: 就是另一个 SEL，两者不相等=%d",
              sel_getName(a), sel_isEqual(a, sel_registerName("number:")) ? 0 : 1]];
    SEL bogus = NSSelectorFromString(@"noSuchMethodAtAll");
    [RTL add:@"@selector 的参数写错会连编译都过不了，但运行时用字符串构造就没人拦："];
    [RTL add:[NSString stringWithFormat:@"    NSSelectorFromString(@\"noSuchMethodAtAll\") -> %@（照样得到一个合法 SEL：runtime 只登记名字，不查有没有实现）",
              NSStringFromSelector(bogus)]];
    SEL cnSel = NSSelectorFromString(@"中文选择器名");
    [RTL add:[NSString stringWithFormat:@"    名字甚至可以不是 ASCII：sel_registerName(\"中文选择器名\") 与它相等=%d，UTF-8 字节数=%lu —— SEL 认的是「唯一化后的名字」，字符集不设限",
              cnSel == sel_registerName("中文选择器名") ? 1 : 0,
              (unsigned long)strlen(sel_getName(cnSel))]];
    [RTL add:@"    同一段字节要先用 NSStringFromSelector 包成 NSString、再走 %@ 才打得正常："
                @"把 sel_getName 的结果直接交给 stringWithFormat 的 %s，中文会变成一串乱码（%s 不按 UTF-8 解 C 字符串）—— "
                @"这就是本章所有中文一律走前者的原因"];
    return [RTL end];
}

// ---------------------------------------------------------------- §2 nil 返回值
NSArray<NSString *> *RTLinesNilReturns(void) {
    [RTL begin];
    RTGreeter *g = [RTGreeter new];
    RTGreeter *nilG = nil;
    id nilObj = nil;

    [RTL add:[NSString stringWithFormat:@"int：真值=%d nil=%d", [g number], [nilG number]]];
    [RTL add:[NSString stringWithFormat:@"long long：真值=%lld nil=%lld", [g bigNumber], [nilG bigNumber]]];
    [RTL add:[NSString stringWithFormat:@"unsigned long long：真值=%llu nil=%llu", [g unsignedBig], [nilG unsignedBig]]];
    [RTL add:[NSString stringWithFormat:@"short=%d/%d  char=%d/%d（char 打出来是整数 65 而不是字母：65 是 'A' 的码点，这一行统一按整数打才看得清 0 从哪来 —— nil 一律给 0）",
              [g smallInt], [nilG smallInt], [g byte], [nilG byte]]];
    [RTL add:[NSString stringWithFormat:@"BOOL：真值=%d nil=%d（0 就是 NO）", [g flag], [nilG flag]]];
    [RTL add:[NSString stringWithFormat:@"float=%f nil=%f；double=%f nil=%f", [g floatNum], [nilG floatNum], [g doubleNum], [nilG doubleNum]]];
    [RTL add:[NSString stringWithFormat:@"long double=%Lf nil=%Lf", [g longDoubleNum], [nilG longDoubleNum]]];
    [RTL add:[NSString stringWithFormat:@"unichar=0x%04X nil=0x%04X", [g twoByteChar], [nilG twoByteChar]]];
    [RTL add:[NSString stringWithFormat:@"id：真值=%@ nil=%@", [g object], [nilG object]]];
    [RTL add:[NSString stringWithFormat:@"Class：真值=%@ nil=%@", NSStringFromClass([g aClass]), NSStringFromClass([nilG aClass])]];
    [RTL add:[NSString stringWithFormat:@"SEL：真值=%s nil=%s", sel_getName([g aSelector]), [nilG aSelector] ? sel_getName([nilG aSelector]) : "(null)"]];
    [g nothing];
    [RTL add:@"void 方法发给 nil：什么都不发生，程序继续跑"];

    CGRect r = [nilG rectValue];
    CGPoint pt = [nilG pointValue];
    CGSize sz = [nilG sizeValue];
    NSRange rn = [nilG rangeValue];
    CGVector vc = [nilG vectorValue];
    CGAffineTransform xf = [nilG xformValue];
    [RTL add:[NSString stringWithFormat:@"CGRect nil=(%.1f %.1f %.1f %.1f)（真值=(1.5 2.5 3.5 4.5)）", r.origin.x, r.origin.y, r.size.width, r.size.height]];
    [RTL add:[NSString stringWithFormat:@"CGPoint nil=(%.1f %.1f)  CGSize nil=(%.1f %.1f)", pt.x, pt.y, sz.width, sz.height]];
    [RTL add:[NSString stringWithFormat:@"NSRange nil={%lu %lu}（注意 location 也是 0，不是 NSNotFound）", (unsigned long)rn.location, (unsigned long)rn.length]];
    [RTL add:[NSString stringWithFormat:@"CGVector nil=(%.1f %.1f)  CGAffineTransform nil=(%.1f %.1f %.1f %.1f %.1f %.1f)", vc.dx, vc.dy, xf.a, xf.b, xf.c, xf.d, xf.tx, xf.ty]];
    [RTL add:[NSString stringWithFormat:@"CGAffineTransform 不是单位矩阵！单位矩阵是 (1 0 0 1 0 0)，nil 给你的是全 0 —— 拿它去乘坐标会把图形压成一点"]];
    struct RTQuad q = [nilG quadValue];
    struct RTPair p = [nilG pairValue];
    [RTL add:[NSString stringWithFormat:@"32 字节结构体（走隐藏指针返回）nil=(%.1f %.1f %.1f %.1f)", q.a, q.b, q.c, q.d]];
    [RTL add:[NSString stringWithFormat:@"8 字节结构体（走寄存器返回）nil=(%.1f %.1f)", p.x, p.y]];
    NSString *nilStr = nil;
    [RTL add:[NSString stringWithFormat:@"nil 的 length=%lu、count=%lu、isEqual nil=%d、class=%@",
              (unsigned long)[nilStr length], (unsigned long)[[nilG dictValue] count],
              [nilObj isEqual:nil] ? 1 : 0, [nilObj class] ? @"非 nil" : @"nil"]];
    [RTL add:@"链式调用一路 nil 到底也不崩：[[nilG dictValue] objectForKey:@\"k\"] 返回 nil"];
    [RTL add:[NSString stringWithFormat:@"    实测=%@", [[nilG dictValue] objectForKey:@"k"]]];
    return [RTL end];
}

// ---------------------------------------------------------------- §3 消息发送路径
NSArray<NSString *> *RTLinesMsgSend(void) {
    [RTL begin];
    RTGreeter *g = [RTGreeter new];

    typedef int (*IntFn)(id, SEL);
    typedef NSString *(*GreetFn)(id, SEL, NSString *);
    IntFn direct = (IntFn)[g methodForSelector:@selector(number)];
    [RTL add:[NSString stringWithFormat:@"[g number]=%d", [g number]]];
    [RTL add:[NSString stringWithFormat:@"methodForSelector: 拿到 IMP 后直接调=%d（必须自己补 self 和 _cmd）", direct(g, @selector(number))]];
    IMP fromClass = class_getMethodImplementation([RTGreeter class], @selector(number));
    [RTL add:[NSString stringWithFormat:@"class_getMethodImplementation 拿到的是同一个 IMP=%d", fromClass == (IMP)direct]];
    [RTL add:[NSString stringWithFormat:@"((IntFn)objc_msgSend)(g, @selector(number))=%d", ((IntFn)objc_msgSend)(g, @selector(number))]];
    GreetFn greet = (GreetFn)objc_msgSend;
    [RTL add:[NSString stringWithFormat:@"带对象参数的：objc_msgSend(g, greet:, @\"runtime\")=%@", greet(g, @selector(greet:), @"runtime")]];

    typedef struct RTPair (*PairFn)(id, SEL);
    struct RTPair p = ((PairFn)objc_msgSend)(g, @selector(pairValue));
    [RTL add:[NSString stringWithFormat:@"8 字节结构体用普通 objc_msgSend 取回=(%.1f %.1f) —— 对，寄存器返回时不需要特殊函数", p.x, p.y]];
    typedef double (*DblFn)(id, SEL);
    [RTL add:[NSString stringWithFormat:@"double 用普通 objc_msgSend=%f（和直接 [g doubleNum] 相等=%d）",
              ((DblFn)objc_msgSend)(g, @selector(doubleNum)),
              ((DblFn)objc_msgSend)(g, @selector(doubleNum)) == [g doubleNum]]];
#if defined(__x86_64__)
    CGRect viaStret = CGRectZero;
    ((void (*)(void *, id, SEL))objc_msgSend_stret)(&viaStret, g, @selector(rectValue));
    [RTL add:[NSString stringWithFormat:@"x86_64 上 32 字节的 CGRect 必须用 objc_msgSend_stret，且**返回地址是第一个参数**：取到=(%.1f %.1f %.1f %.1f)",
              viaStret.origin.x, viaStret.origin.y, viaStret.size.width, viaStret.size.height]];
    [RTL add:[NSString stringWithFormat:@"它与消息发送的结果相等=%d", CGRectEqualToRect(viaStret, [g rectValue])]];
    [RTL add:@"探针记录：把 stret 方法的返回值按 CGRect(*)(id,SEL) 从普通 objc_msgSend 里取，不是拿到脏数据，而是当场 SIGSEGV（见本章诚实边界）。"];
#else
    [RTL add:@"本机不是 x86_64：arm64 的 ABI 没有结构体返回专用变体，objc_msgSend_stret 在这个架构上根本不存在。"];
#endif
    typedef double (*DblFn2)(id, SEL);
    typedef float (*FltFn2)(id, SEL);
    typedef long double (*LdFn2)(id, SEL);
#if defined(__x86_64__)
    double viaNormal = ((DblFn2)objc_msgSend)(g, @selector(doubleNum));
    double viaFpret = ((DblFn2)objc_msgSend_fpret)(g, @selector(doubleNum));
    float fNormal = ((FltFn2)objc_msgSend)(g, @selector(floatNum));
    float fFpret = ((FltFn2)objc_msgSend_fpret)(g, @selector(floatNum));
    long double ldNormal = ((LdFn2)objc_msgSend)(g, @selector(longDoubleNum));
    long double ldFpret = ((LdFn2)objc_msgSend_fpret)(g, @selector(longDoubleNum));
    [RTL add:[NSString stringWithFormat:@"浮点返回值的两个通道（每组前一个是 objc_msgSend，后一个是 objc_msgSend_fpret）："
                @"double %f vs %f（相等=%d）；float %f vs %f（相等=%d）；long double %.6Lf vs %.6Lf（相等=%d）",
              viaNormal, viaFpret, viaNormal == viaFpret ? 1 : 0,
              fNormal, fFpret, fNormal == fFpret ? 1 : 0,
              ldNormal, ldFpret, ldNormal == ldFpret ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    诚实结论：本机（x86_64 模拟器）上三种浮点返回类型走哪个通道都取到同一个值，"
                @"连 sizeof(long double)=%lu 的这个「最像会变坏」的类型也没变坏 —— "
                @"所以这一章不能声称「用普通 objc_msgSend 读浮点返回值一定读到脏的」。"
                @"两个通道并存说明的是 ABI 里浮点寄存器与整数寄存器分家（stret 那条就是分家的代价），"
                @"至于哪个通道才算「正规」，Apple 把 fpret 单独列出来本身就是在给答案。",
              (unsigned long)sizeof(long double)]];
#endif
    [RTL add:[NSString stringWithFormat:@"找不到的选标：class_getMethodImplementation 返回一个**内部桩**而不是 NULL，"
                @"所以「IMP 非空」不代表方法存在（见 §8 的 doesNotRecognizeSelector）=%d",
              class_getMethodImplementation([RTGreeter class], NSSelectorFromString(@"根本没有这个方法")) != NULL ? 1 : 0]];
    RTSuperSub *ss = [RTSuperSub new];
    [RTL add:[NSString stringWithFormat:@"self 走子类=[ss tag] -> %@", [ss tag]]];
    [RTL add:[NSString stringWithFormat:@"super 走父类=[ss viaSuper] -> %@", [ss viaSuper]]];
    struct objc_super sup = { ss, class_getSuperclass(object_getClass(ss)) };
    NSString *(*superFn)(struct objc_super *, SEL) = (NSString *(*)(struct objc_super *, SEL))objc_msgSendSuper;
    [RTL add:[NSString stringWithFormat:@"objc_msgSendSuper 手工版 -> %@", superFn(&sup, @selector(tag))]];
    [RTL add:[NSString stringWithFormat:@"[ss viaRuntimeSuper]（方法内部自己构造 objc_super）-> %@", [ss viaRuntimeSuper]]];
    [RTL add:@"注意：super 不是对象，它是「从父类开始查方法表」的编译期记号；[super m] 的接收者依然是 self"];
    return [RTL end];
}

// ---------------------------------------------------------------- §4 隐藏参数
NSArray<NSString *> *RTLinesHiddenArgs(void) {
    [RTL begin];
    RTAlias *a = [RTAlias new];
    [RTL add:[NSString stringWithFormat:@"两个方法的实现文字一模一样，但 _cmd 不同：[a whichOneA]=%@；[a whichOneB]=%@",
              [a whichOneA], [a whichOneB]]];
    Method ma = class_getInstanceMethod([RTAlias class], @selector(whichOneA));
    Method mb = class_getInstanceMethod([RTAlias class], @selector(whichOneB));
    [RTL add:[NSString stringWithFormat:@"两个不同的 IMP（编译器不会替你去重）=%d",
              method_getImplementation(ma) == method_getImplementation(mb) ? 0 : 1]];
    IMP shared = method_getImplementation(ma);
    method_setImplementation(mb, shared);
    [RTL add:[NSString stringWithFormat:@"把 A 的 IMP 装到 B 上之后，两者共用一份实现；靠 _cmd 仍然分得清：[a whichOneB]=%@", [a whichOneB]]];
    [RTL add:@"这就是「一份实现 + 多个选标」的做法，系统的 initWithCoder:/copyWithZone: 之类都靠 self/_cmd 拿到上下文"];
    return [RTL end];
}

// ---------------------------------------------------------------- §5 类型编码
NSArray<NSString *> *RTLinesEncoding(void) {
    [RTL begin];
    [RTL add:[NSString stringWithFormat:@"整型：char=%s short=%s int=%s long=%s long long=%s",
              @encode(char), @encode(short), @encode(int), @encode(long), @encode(long long)]];
    [RTL add:[NSString stringWithFormat:@"无符号：uchar=%s ushort=%s uint=%s ulong=%s ullong=%s",
              @encode(unsigned char), @encode(unsigned short), @encode(unsigned), @encode(unsigned long), @encode(unsigned long long)]];
    [RTL add:[NSString stringWithFormat:@"浮点与布尔：float=%s double=%s long double=%s _Bool=%s BOOL=%s C++ bool=%s void=%s",
              @encode(float), @encode(double), @encode(long double), @encode(_Bool), @encode(BOOL), @encode(bool), @encode(void)]];
    [RTL add:[NSString stringWithFormat:@"整数宽度：NSInteger=%s NSUInteger=%s CGFloat=%s unichar=%s ptrdiff_t=%s size_t=%s",
              @encode(NSInteger), @encode(NSUInteger), @encode(CGFloat), @encode(unichar), @encode(ptrdiff_t), @encode(size_t)]];
    [RTL add:[NSString stringWithFormat:@"指针与字符数组：void*=%s char*=%s const char*=%s 函数指针=%s",
              @encode(void *), @encode(char *), @encode(const char *), @encode(int (*)(void))]];
    [RTL add:[NSString stringWithFormat:@"ObjC 专有：id=%s Class=%s SEL=%s 对象指针=%s block=%s",
              @encode(id), @encode(Class), @encode(SEL), @encode(RTGreeter *), @encode(void (^)(int))]];
    [RTL add:[NSString stringWithFormat:@"    block 的编码 %s 与 C 函数指针的编码 %s 不是一回事：block 是 ObjC 对象，函数指针不是",
              @encode(void (^)(int)), @encode(int (*)(void))]];
    [RTL add:[NSString stringWithFormat:@"CoreFoundation 桥：CFStringRef=%s（不透明结构体指针）NSNumber=%s NSDate=%s",
              @encode(CFStringRef), @encode(NSNumber *), @encode(NSDate *)]];
    [RTL add:[NSString stringWithFormat:@"结构体：CGRect=%s", @encode(CGRect)]];
    [RTL add:[NSString stringWithFormat:@"          CGPoint=%s  CGSize=%s", @encode(CGPoint), @encode(CGSize)]];
    [RTL add:[NSString stringWithFormat:@"          NSRange=%s  CGVector=%s  CGAffineTransform=%s",
              @encode(NSRange), @encode(CGVector), @encode(CGAffineTransform)]];
    [RTL add:[NSString stringWithFormat:@"自定义结构体：RTPair(2 个 float)=%s  RTQuad(4 个 double)=%s",
              @encode(struct RTPair), @encode(struct RTQuad)]];
    [RTL add:[NSString stringWithFormat:@"数组与枚举：int[4]=%s  double[2]=%s  enum NSComparisonResult=%s",
              @encode(int [4]), @encode(double [2]), @encode(enum NSComparisonResult)]];
    [RTL add:[NSString stringWithFormat:@"sizeof：char=%zu short=%zu int=%zu long=%zu long long=%zu 指针=%zu float=%zu double=%zu long double=%zu BOOL=%zu",
              sizeof(char), sizeof(short), sizeof(int), sizeof(long), sizeof(long long), sizeof(void *), sizeof(float), sizeof(double), sizeof(long double), sizeof(BOOL)]];
    [RTL add:[NSString stringWithFormat:@"long double 在本机是 %zu 字节，而 @encode 给的字母仍是 '%s'；CGFloat(%zu)=double，NSInteger(%zu)=long",
              sizeof(long double), @encode(long double), sizeof(CGFloat), sizeof(NSInteger)]];

    Method mNumber = class_getInstanceMethod([RTGreeter class], @selector(number));
    Method mSetRect = class_getInstanceMethod([RTGreeter class], @selector(greet:));
    [RTL add:[NSString stringWithFormat:@"方法类型编码里带**字节偏移**：number -> %s", method_getTypeEncoding(mNumber)]];
    [RTL add:[NSString stringWithFormat:@"                        greet: -> %s", method_getTypeEncoding(mSetRect)]];
    [RTL add:@"拆解：'i16@0:8' = 返回 int；16 是帧上参数总大小；'@0' self 在第 0 字节；':'8 _cmd 在第 8 字节；'i16' 第一个显式参数在第 16 字节"];
    Method mRect = class_getInstanceMethod([RTGreeter class], @selector(rectValue));
    Method mPair = class_getInstanceMethod([RTGreeter class], @selector(pairValue));
    [RTL add:[NSString stringWithFormat:@"结构体返回值直接写在最前面：rectValue -> %s", method_getTypeEncoding(mRect)]];
    [RTL add:[NSString stringWithFormat:@"                        pairValue -> %s", method_getTypeEncoding(mPair)]];
    NSMethodSignature *sig = [RTGreeter instanceMethodSignatureForSelector:@selector(greet:)];
    [RTL add:[NSString stringWithFormat:@"NSMethodSignature 把同一份编码拆成可用零件：greet: 返回类型=%s 参数个数=%lu（含 self、_cmd）",
              sig.methodReturnType, (unsigned long)sig.numberOfArguments]];
    NSMutableString *parts = [NSMutableString string];
    for (NSUInteger i = 0; i < sig.numberOfArguments; i++) {
        [parts appendFormat:@"[%lu]=%s ", (unsigned long)i, [sig getArgumentTypeAtIndex:i]];
    }
    [RTL add:[NSString stringWithFormat:@"    逐个参数类型：%s", parts.UTF8String]];
    NSMethodSignature *sigNone = [RTGreeter instanceMethodSignatureForSelector:@selector(neverImplemented)];
    [RTL add:[NSString stringWithFormat:@"声明了却没实现的方法问签名（neverImplemented）-> %@",
              sigNone ? [NSString stringWithFormat:@"%@ 个参数", @(sigNone.numberOfArguments)] : @"nil（签名来自方法表，不来自声明）"]];
    [RTL add:@"    签名拿不到 => 完整转发也建立不起 NSInvocation => 直接 doesNotRecognizeSelector:，这是 §8 最后一级台阶的成因"];
    return [RTL end];
}
