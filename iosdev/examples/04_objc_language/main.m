// ============================================================
// 04 - Objective-C 语言基础（iOS  flavored）
//
// iOS 的新代码几乎都是 Swift，但**存量代码、系统框架的底层、大量第三方库**
// 仍是 Objective-C。看不懂 OC，就读不懂报错、用不了没桥接好的库、也理解不了
// Swift 那些「@objc / NSObject 子类」的限制从哪来。本章用 OC 把语言核心讲透。
//
// 编译（纯 OC，clang）：
//   clang -fobjc-arc -fmodules -Wall -Wextra -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
//         -target x86_64-apple-ios15.0-simulator Person.m main.m -o 04 \
//         -framework Foundation -framework UIKit
// 运行：xcrun simctl spawn <UDID> ./04 --selftest
//
// 输出用 printf（不用 NSLog —— NSLog 写 stderr，会破坏「stderr 必须为空」的判定）。
// ============================================================

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Person.h"
#import "Speaker.h"

static int gFailures = 0;

static void expect(BOOL condition, NSString *desc) {
    printf("  %s %s\n", condition ? "ok  " : "FAIL", [desc UTF8String]);
    if (!condition) { gFailures += 1; }
}
static void line(NSString *s) { printf("%s\n", [s UTF8String]); }
static NSString *MXYesNo(BOOL b) { return b ? @"对" : @"错"; }

// ---------------------------------------------------------------- 度量用小类
// 本章要把几件「看不见的事」变成可断言的数字：对象到底解没释放、for-in 到底调了谁、
// block 有没有把 self 拖住。手段都是同一个：在 -dealloc 里改一个文件级计数。
// 计数只在主线程单线程里读写，没有并发问题。

static NSInteger gAlive = 0;      // 当前活着的 MXCounted 个数
static NSInteger gTotal = 0;      // 一共造过几个（只增不减）

@interface MXCounted : NSObject
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) BOOL flag;   // 用来量「把一个整数赋给 BOOL 属性」会发生什么
// 两个同类对象互相引用：strong 那一档会锁死彼此，weak 那一档不会。
@property (nonatomic, strong) MXCounted *strongFriend;
@property (nonatomic, weak) MXCounted *weakFriend;
+ (BOOL)boolFromInt:(int)n;
@end

@implementation MXCounted
// 故意写成 return n：让「整数 -> BOOL」的转换在这里隐式发生（显式强转另有一条路）。
+ (BOOL)boolFromInt:(int)n { return n; }
- (instancetype)initWithTag:(NSInteger)tag {
    self = [super init];
    if (self != nil) {
        _tag = tag;
        gAlive += 1;
        gTotal += 1;
    }
    return self;
}
- (void)dealloc { gAlive -= 1; }
@end

// 一个故意把 setter 改写得「不老实」的子类：用来证明 init 里为什么必须写 ivar。
@interface MXSetterTwists : Person
@end
@implementation MXSetterTwists
- (void)setAge:(NSInteger)age {
    super.age = age * 2;      // 走 super 的 setter，别写成 self.age = …（那是无限递归）
}
@end

// 分类最常见的真实用途：给已有类贴一个工具方法，不改它的源码、也不建子类。
@interface NSString (MXHelper)
- (NSString *)mx_shout;
@end
@implementation NSString (MXHelper)
- (NSString *)mx_shout {
    return [[self stringByAppendingString:@"！！！"] uppercaseString];
}
@end

// 持有一个 block 的对象。block 里捕获谁，就决定了这个对象解不解得掉 —— 交给 onRelease 报信。
@interface MXBlockOwner : NSObject
@property (nonatomic, copy) void (^onRelease)(void);
@end
@implementation MXBlockOwner
- (void)dealloc {
    void (^block)(void) = self.onRelease;
    if (block != nil) { block(); }
}
@end
static NSInteger gOwnerReleased = 0;

// 自己实现 NSFastEnumeration 的容器：一次只交 2 个元素，好让 for-in 真的多轮几次。
// 每次系统回调它都记一笔，于是「for-in 其实是 countByEnumeratingWithState: 的语法糖」
// 这句话就有了数字。
#define MXT_BATCH 2
@interface MXTapioca : NSObject <NSFastEnumeration>
@property (nonatomic, readonly) NSInteger calls;       // 被回调了几次
@property (nonatomic, readonly) NSInteger items;       // 一共几个元素
@property (nonatomic, readonly) NSArray<NSNumber *> *batchSizes;   // 每次交出去几个
@end
@implementation MXTapioca {
    NSInteger _calls;
    NSInteger _items;
    NSMutableArray<NSNumber *> *_batchSizes;
}
- (instancetype)initWithItems:(NSInteger)items {
    self = [super init];
    if (self != nil) {
        _items = items;
        _batchSizes = [NSMutableArray array];
    }
    return self;
}
- (NSInteger)calls { return _calls; }
- (NSInteger)items { return _items; }
- (NSArray<NSNumber *> *)batchSizes { return [_batchSizes copy]; }
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len {
    _calls += 1;
    NSUInteger done = (NSUInteger)state->state;
    if (done >= (NSUInteger)_items) {
        [_batchSizes addObject:@0];
        return 0;
    }
    NSUInteger batch = (NSUInteger)MXT_BATCH;
    if (batch > (NSUInteger)(len < 1 ? 1 : len)) { batch = (NSUInteger)(len < 1 ? 1 : len); }
    NSUInteger rest = (NSUInteger)_items - done;
    if (batch > rest) { batch = rest; }
    for (NSUInteger i = 0; i < batch; i++) {
        buffer[i] = @(done + (NSInteger)i + 1);     // 元素就是 1,2,3,...
    }
    [_batchSizes addObject:@(batch)];
    state->state = (unsigned long)(done + batch);
    state->itemsPtr = buffer;
    state->mutationsPtr = (unsigned long *)&_items;
    return batch;
}
@end

// ---------------------------------------------------------------- 枚举与协议（给第 1、4 节用）
// 裸 enum：底类型由编译器挑（28 章 §9 量过怎么把它测出来）。
typedef enum { MXRed = 1, MXGreen = 2, MXBlue = 4 } MXPlainColor;
// NS_ENUM：底类型写死成 NSInteger，Swift 才会翻成真正的 enum。
typedef NS_ENUM(NSInteger, MXLevel) {
    MXLevelLow = 1,
    MXLevelMid = 5,
    MXLevelHigh = 9,
};
// NS_OPTIONS：位标志，配合按位与来问「开没开」。
typedef NS_OPTIONS(NSUInteger, MXFeature) {
    MXFeatureNone     = 0,
    MXFeatureDark     = 1 << 0,
    MXFeatureNetwork  = 1 << 1,
    MXFeatureLocation = 1 << 2,
};

// ---------------------------------------------------------------- 分类（category）
// 不给 Person 加子类、不改它的源码，就能给它「贴」上新方法。
// 这就是 OC 的分类：运行时把方法合并进原类。Swift 的 extension 与此神似。
@interface Person (Vip)
- (NSString *)vipGreeting;
@end

@implementation Person (Vip)
- (NSString *)vipGreeting {
    return [NSString stringWithFormat:@"[VIP] %@", [self greeting]];
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        line(@"== 04 Objective-C 语言基础 ==");

        // -------------------------------------------------- 1) 数据类型
        // OC 是 C 的超集，所以「标量」这一层完全就是 C 的那套（28 章 §1 逐项量过）。
        // 本节量的是 OC 加在这一层之上的东西：NSInteger/BOOL 到底是什么、
        // 字面量的默认类型、四种写法不同的「空」、@() 装箱出来的类。
        line(@"");
        line(@"== 数据类型（一）：标量宽度是量出来的 ==");
        line([NSString stringWithFormat:@"这台机器上的宽度：char=%zu short=%zu int=%zu long=%zu long long=%zu "
                @"float=%zu double=%zu BOOL=%zu void *=%zu",
                sizeof(char), sizeof(short), sizeof(int), sizeof(long), sizeof(long long),
                sizeof(float), sizeof(double), sizeof(BOOL), sizeof(void *)]);
        expect(sizeof(NSInteger) == sizeof(long) && sizeof(NSInteger) == 8,
               [NSString stringWithFormat:@"NSInteger 就是 long 的别名（本机 sizeof=%zu）：写 OC 时凡是「计数、下标、长度」都用它，别用 int",
                sizeof(NSInteger)]);
        expect(sizeof(NSUInteger) == sizeof(NSInteger) && sizeof(CGFloat) == sizeof(double),
               [NSString stringWithFormat:@"NSUInteger 与 NSInteger 同宽（%zu）；64 位上 CGFloat 就是 double（%zu）—— 所以 .length 用 %%lu + (unsigned long)，%%d 是错的",
                sizeof(NSUInteger), sizeof(CGFloat)]);
        expect(sizeof(NSInteger) != sizeof(int),
               [NSString stringWithFormat:@"NSInteger(%zu) != int(%zu)：这就是 28 章 §18 里 C 的 int 进 Swift 变 Int32、而 Swift 的 Int 对应 long 的同一个 lp64 数据模型",
                sizeof(NSInteger), sizeof(int)]);
        expect(sizeof(BOOL) == 1,
               [NSString stringWithFormat:@"BOOL 的 sizeof = %zu：它是 signed char，不是一个 bit，也不是 C99 的 _Bool", sizeof(BOOL)]);
        // BOOL 只占 1 个字节，所以「一个整数怎么变成一个合法的 BOOL」是有讲究的：
        // 老教材（包括这本书的第 2 章）都写着 count=256 会被截成 0。今天还成立吗？
        // 三种写法各测一遍：显式强制转换、方法里 return 一个 int、赋给 BOOL 属性。
        volatile int bigCount = 256;
        BOOL castTruthy = (BOOL)bigCount;
        BOOL returnedTruthy = [MXCounted boolFromInt:bigCount];
        MXCounted *flagProbe = [[MXCounted alloc] initWithTag:0];
        flagProbe.flag = bigCount;
        volatile int negativeOne = -1;
        line([NSString stringWithFormat:@"整数变 BOOL 的三条路，输入都是 256：显式 (BOOL)count = %d、方法 return count = %d、赋给 BOOL 属性再读回 = %d；输入 -1 时显式转换 = %d",
             (int)castTruthy, (int)returnedTruthy, (int)flagProbe.flag, (int)(BOOL)negativeOne]);
        expect(castTruthy == YES && returnedTruthy == YES && flagProbe.flag == YES,
               @"书上那条「count=256 转成 BOOL 会变成 0」的老 bug，在这台 clang/ARC 上量不出来了：三条路都把非零规整成了 1（编译器插了一次 !=0 归一化）");
        expect((BOOL)negativeOne == YES,
               @"-1 也是真：ARC 下的 BOOL 转换是「非零即 1」，不是「取低 8 位」");
        expect(flagProbe.tag == 0 && sizeof(BOOL) == 1,
               @"但结论别用反：BOOL 仍然只有 1 字节宽，转换规整是**编译器行为**、不是语言保证（C 侧的 _Bool 才有「非零变 1」的正规说法）。把 count 直接当 BOOL 返回仍然是坏写法 —— 正确的写法永远是下面这条");
        expect(bigCount != 0 && (BOOL)(bigCount != 0) == YES,
               @"(BOOL)(count != 0)：先比较再返回，任何工具链上都稳定");

        line(@"");
        line(@"== 数据类型（二）：字面量的默认类型与三种进制 ==");
        line([NSString stringWithFormat:@"sizeof(56)=%zu（装得进 int 就是 int）、sizeof(9999999999999)=%zu（十进制大常数一路往上找：int->long->long long）、"
                @"sizeof(0xFFFFFFFF)=%zu（十六进制允许 unsigned，所以停在 unsigned int）、sizeof(56u)=%zu、sizeof(56L)=%zu",
                sizeof(56), sizeof(9999999999999), sizeof(0xFFFFFFFF), sizeof(56u), sizeof(56L)]);
        expect(sizeof(9999999999999) == 8, @"大整数字面量默认是 64 位：赋给 int 会静默截断（编译器诊断见本章末尾的探针记录）");
        expect(sizeof(1.5) == 8 && sizeof(1.5f) == 4,
               @"浮点字面量默认是 double：1.5 占 8 字节，写 1.5f 才是 float —— CGFloat 属性上写 1.5 没事，写成 float 变量就要吃一次隐式窄化");
        // 窄化到什么程度，量一下：0.1 这个字面量在 double 里就不是精确的 0.1，落到 float 又掉一层。
        float narrowed = 0.1;
        volatile double literalValue = 0.1;      // volatile 挡住折叠，也避开 clang 的 -Wliteral-range（它说「字面量在 float 里表示不精确」本身就是那条警告）
        expect((double)narrowed != literalValue,
               [NSString stringWithFormat:@"`float f = 0.1;` 一声不响（-Wall -Wextra 零诊断，见本章末尾探针），但值已经变了：float 读回 double 是 %.17g，字面量本身是 %.17g —— 差在第 8 位有效数字上，单精度只有 6~7 位可靠",
                (double)narrowed, 0.1]);
        line([NSString stringWithFormat:@"050 是八进制 = %d（不是 50！）、0177 是八进制 = %d、0xFF 是十六进制 = %d；同一个十进制 40 的五种打法：%%d=%d %%o=%o %%#o=%#o %%x=%x %%#x=%#x",
             050, 0177, 0xFF, 40, 40, 40, 40, 40]);
        expect(050 == 40 && 0177 == 127 && 0xFF == 255,
               @"前导 0 就是八进制：`050` 是 40 不是 50 —— 这是 OC/C 里最难查的笔误之一（`0xFF` 才是十六进制）");
        expect(0b1010 == 10, @"0b 开头的二进制字面量是 clang 扩展，标准 C11 没有（写进跨编译器头文件时要小心）");

        line(@"");
        line(@"== 数据类型（三）：nil / Nil / NULL / NSNull 是两回事 ==");
        expect(nil == NULL && (id)Nil == NULL,
               @"nil、Nil、NULL 是同一个值 ((void *)0) 的三个拼写：nil 给对象指针、Nil 给类对象、NULL 给 C 指针");
        NSString *noString = nil;
        expect(noString.length == 0,
               @"给 nil 发消息不执行也不崩，NSString *.length 得到 0（这是 OC 省掉满屏判空的原因，返回值全表见 27 章 §2）");
        expect([NSNull null] != nil,
               @"[NSNull null] 是一个真实存在的对象，跟 nil 不是一回事：它专门用来填进集合里代表「这里有个位置，但没有值」");
        NSArray *withNull = @[ @"a", [NSNull null], @"c" ];
        expect(withNull.count == 3 && [withNull[1] isKindOfClass:[NSNull class]],
               [NSString stringWithFormat:@"数组里放 NSNull：count=%lu，第二格取出来是 %@ 这个类（不是 nil）—— 因为集合根本不收 nil：往 NSMutableArray 里 addObject:nil 会抛异常（下面 §3 的 @try 里接住了一次，原文打进输出）",
                (unsigned long)withNull.count, NSStringFromClass([withNull[1] class])]);
        expect(YES, @"字面量 @[@1, nil] 连编译都过不去（诊断见本章末尾），运行时抛的是 addObject: 那一条：nil 洞只能拿 NSNull 填");

        line(@"");
        line(@"== 数据类型（四）：@() 装箱出来的类，和常量的字符串 ==");
        NSNumber *boxed = @42;
        NSNumber *boxedPlain = [NSNumber numberWithInt:42];
        NSNumber *boxedDouble = @(3.5);
        NSNumber *boxedBool = @(YES);
        expect(boxed.intValue == 42 && boxedDouble.doubleValue == 3.5 && boxedBool.boolValue == YES,
               [NSString stringWithFormat:@"@(...) 就是 NSNumber 字面量：@42 -> %@（类名 %@）、@(3.5).doubleValue=3.5、@(YES).boolValue=真",
                @(42).stringValue, NSStringFromClass([boxed class])]);
        line([NSString stringWithFormat:@"同为 NSNumber，四种造法的类名全不一样：@42=%@、[NSNumber numberWithInt:42]=%@、@(3.5)=%@、@(YES)=%@",
             NSStringFromClass([boxed class]), NSStringFromClass([boxedPlain class]),
             NSStringFromClass([boxedDouble class]), NSStringFromClass([boxedBool class])]);
        expect(boxed != boxedPlain && [boxed isEqual:boxedPlain],
               @"同样是 42，@42 和 [NSNumber numberWithInt:] 是两个不同的对象（!=），但内容相等（isEqual:）：类名不同 + 对象不同，都在提醒一件事 —— 类的真身是私有实现，只能问 isKindOfClass:，绝不能拿 [x class] == [Y class] 当身份判断");
        expect([boxed isKindOfClass:[NSNumber class]] && [boxedPlain isKindOfClass:[NSNumber class]],
               @"不管类名叫什么，isKindOfClass:[NSNumber class] 都为真：这才是该用的判断");
        expect([@[ @1 ] isKindOfClass:[NSArray class]] && [@{ @"k": @1 } isKindOfClass:[NSDictionary class]] &&
               [@[ @1 ] mutableCopy] != nil,
               @"容器字面量 @[] / @{} / @() 全是 Foundation 对象的语法糖，没有新类型：@[@1] 就是一个 NSArray");
        NSString *literalName = NSStringFromClass([@"abc" class]);
        NSString *built = [NSString stringWithFormat:@"ab%@", @"c"];
        NSString *builtName = NSStringFromClass([built class]);
        NSString *longBuilt = [NSString stringWithFormat:@"ab%@", @"cdefghijklmnopqrstuvwxyz"];
        NSString *longBuiltName = NSStringFromClass([longBuilt class]);
        line([NSString stringWithFormat:@"同一个内容三个类：@\"abc\" 是 %@，拼出来的短串 \"abc\" 是 %@，拼出来的长串是 %@",
             literalName, builtName, longBuiltName]);
        expect([@"abc" isEqualToString:built], @"内容相等（isEqual: 这条路径）");
        expect(![literalName isEqualToString:builtName] && ![builtName isEqualToString:longBuiltName],
               [NSString stringWithFormat:@"字面量在编译期落进常量池（%@），运行时拼出来的短串走 %@（指针本身就编码了内容，见下面 §2 的 `==`），长串才是堆上的 %@ —— 内容一样的字符串有三个不同的类",
                literalName, builtName, longBuiltName]);

        line(@"");
        line(@"== 数据类型（五）：枚举与结构体 ==");
        line([NSString stringWithFormat:@"裸 enum MXPlainColor{{1,2,4}} 的 sizeof = %zu；NS_ENUM(NSInteger, MXLevel) 的 sizeof = %zu；NS_OPTIONS(NSUInteger, MXFeature) 的 sizeof = %zu",
             sizeof(MXPlainColor), sizeof(MXLevel), sizeof(MXFeature)]);
        expect(sizeof(MXLevel) == sizeof(NSInteger),
               [NSString stringWithFormat:@"NS_ENUM 把底类型写死成 NSInteger（本机 %zu 字节）—— 28 章 §9 量了「裸 enum 的底类型编译器自己挑」，NS_ENUM/NS_OPTIONS 就是为了不再让它挑", sizeof(MXLevel)]);
        MXFeature features = MXFeatureDark | MXFeatureLocation;
        expect((features & MXFeatureDark) != 0 && (features & MXFeatureNetwork) == 0,
               @"NS_OPTIONS 是位标志：用 | 合起来、用 & 问开没开；拿 == 问「等于这一组」会漏掉组合，C 枚举不检查组合是否合法（28 章 §9 实测）");
        expect(MXLevelMid == 5 && MXLevelHigh > MXLevelLow, @"NS_ENUM 的值就是整数，可以显式给也可以顺延");
        NSRange range = NSMakeRange(1, 2);
        NSRange copyOfRange = range;
        copyOfRange.location = 99;
        expect(range.location == 1 && copyOfRange.location == 99 && sizeof(NSRange) == 16,
               [NSString stringWithFormat:@"结构体赋值是整块拷贝（sizeof(NSRange)=%zu）：改了副本，原件不动 —— 和对象赋值（只拷指针，见 §5）正好相反，这是 OC 里唯一已有的值语义", sizeof(NSRange)]);

        // -------------------------------------------------- 2) 运算符
        line(@"");
        line(@"== 运算符（一）：算术、自增、优先级、位运算 ==");
        expect(7 / 2 == 3 && 7 % 2 == 1, @"整数除法是「截断」不是「四舍五入」：7/2=3、7%2=1");
        expect(-7 / 2 == -3 && -7 % 2 == -1,
               @"负数除法向零取整、余数跟着被除数的符号：-7/2=-3、-7%2=-1（28 章 §1 在 C 里量过同一条，Swift 的 / 和 % 也一样 —— 向下取整那套是 Python）");
        expect((double)7 / 2 == 3.5 && 7 / 2.0 == 3.5, @"两边只要有一个是浮点就走浮点除法：先 (double) 再除，或者把一边写成 2.0");
        expect(7 / 2 * 2 == 6 && (double)(7 / 2) * 2 == 6.0,
               @"先除后乘会把 7 变成 6：`count / pageSize * pageSize` 这种「算回去」的写法一定丢精度，顺序换成先乘后除");
        int i = 5;
        int post = i++;
        int pre = ++i;
        expect(post == 5 && pre == 7 && i == 7,
               [NSString stringWithFormat:@"i++ 交的是旧值（%d）、++i 交的是新值（%d）：两个都写在一行里就是自伤，表达式里只用 ++i 或直接分成两句", post, pre]);
        expect(3 + 4 * 2 == 11 && (3 + 4) * 2 == 14, @"* 比 + 先绑定：括号不要省");
        expect((4 | (2 & 1)) == 4 && ((4 | 2) & 1) == 0,
               [NSString stringWithFormat:@"位运算的优先级反直觉：& 比 | 紧，所以 4|2&1 其实是 4|(2&1)=%d（想要「先合再掩」的那个数是 %d）", (4 | (2 & 1)), ((4 | 2) & 1)]);
        expect(((1 + 2) << 2) == 12 && (1 << (2 + 2)) == 16,
               [NSString stringWithFormat:@"移位的优先级比 + 还低：1+2<<2 其实是 (1+2)<<2=%d，不是 1+(2<<2)=%d", ((1 + 2) << 2), (1 + (2 << 2))]);
        line(@"      上面两条「不写括号」的原式 clang 都会警告（-Wbitwise-op-parentheses / -Wshift-op-parentheses），所以这里必须带括号写；诊断原文见本章末尾的探针记录");
        expect((1u << 31) == 2147483648u && ((int)0x80000000u) == -2147483648,
               @"1u << 31 = 2147483648（无符号才安全），同一个位模式当 int 读就是 -2147483648：标志位一律用无符号底");
        volatile int negative = -8;
        expect((negative >> 1) == -4,
               @"负数右移这台机器上是算术移位（-8>>1=-4，符号位复制）：标准只说「实现定义」，可移植的代码先转无符号再移");
        expect(sizeof(int) * CHAR_BIT == 32, [NSString stringWithFormat:@"CHAR_BIT=%d，sizeof(int)*CHAR_BIT = %d 位：范围是 2^31-1 = %d", CHAR_BIT, (int)(sizeof(int) * CHAR_BIT), INT_MAX]);

        line(@"");
        line(@"== 运算符（二）：三目与短路，用副作用次数证明 ==");
        __block NSInteger sideEffects = 0;   // 块内要改的外部变量必须标 __block，否则编译不过（诊断见本章末尾）
        NSInteger (^bump)(NSString *) = ^NSInteger(NSString *tag) {
            sideEffects += 1;
            line([NSString stringWithFormat:@"      求值了 %@", tag]);
            return 1;
        };
        line([NSString stringWithFormat:@"    && 短路：左半边为假时右半边根本不跑（下面只有一行日志）"]);
        BOOL andResult = (bump(@"&& 的左边（假）") == 0) && (bump(@"&& 的右边") == 1);
        expect(andResult == NO && sideEffects == 1,
               [NSString stringWithFormat:@"&& 只求了 1 次边（实测 sideEffects=%ld）：左边已经假了，右边连求值都不会发生", (long)sideEffects]);
        sideEffects = 0;
        line(@"    || 短路：左半边为真时右半边根本不跑");
        BOOL orResult = (bump(@"|| 的左边（真）") == 1) || (bump(@"|| 的右边") == 1);
        expect(orResult == YES && sideEffects == 1,
               [NSString stringWithFormat:@"|| 只求了 1 次边（实测 sideEffects=%ld）：把便宜的条件放左边、贵的放右边，短路就是免费的性能", (long)sideEffects]);
        sideEffects = 0;
        BOOL bitwiseAndResult = (BOOL)((int)(bump(@"&（不是 &&）的左边（假）") == 0) & (int)(bump(@"& 的右边") == 1));
        expect(bitwiseAndResult == NO && sideEffects == 2,
               [NSString stringWithFormat:@"单个 & 不短路：两边都求了值（实测 sideEffects=%ld）—— 布尔逻辑用 &&，& 只留给位运算", (long)sideEffects]);
        NSString *ternary = (i > 0) ? @"正" : @"非正";
        expect([ternary isEqualToString:@"正"], @"三目 ?: 也是表达式，能直接返回字符串对象；别写成嵌套 if 再声明一个 __block 变量");
        NSInteger nested = (i > 10) ? 100 : (i > 0) ? 10 : 0;
        expect(nested == 10, @"三目可以嵌套但两层就到头了：第三层开始就该写 if/else（可读性问题，不是语法问题）");

        line(@"");
        line(@"== 运算符（三）：对象不能用 == 比内容，可 `==` 又常常是对的 ==");
        NSString *lit1 = @"abc";
        NSString *lit2 = @"abc";
        NSString *builtA = [NSString stringWithFormat:@"ab%@", @"c"];                      // 3 个字符
        NSString *builtB = [NSString stringWithFormat:@"ab%@", @"c"];
        NSString *longA = [NSString stringWithFormat:@"ab%@", @"cdefghijklmnopqrstuvwxyz"];   // 26 个字符
        NSString *longB = [NSString stringWithFormat:@"ab%@", @"cdefghijklmnopqrstuvwxyz"];
        NSString *litLong = @"abcdefghijklmnopqrstuvwxyz";
        line([NSString stringWithFormat:@"五组「内容相同」的字符串，左边是 `==`（比指针），右边是 `isEqual:`（比内容）："]);
        line([NSString stringWithFormat:@"      字面量 vs 字面量        ：== %@、isEqual: %@", MXYesNo(lit1 == lit2), MXYesNo([lit1 isEqual:lit2])]);
        line([NSString stringWithFormat:@"      字面量 vs 拼出的短串    ：== %@、isEqual: %@", MXYesNo(lit1 == builtA), MXYesNo([lit1 isEqual:builtA])]);
        line([NSString stringWithFormat:@"      拼出的短串 vs 拼出的短串：== %@、isEqual: %@", MXYesNo(builtA == builtB), MXYesNo([builtA isEqual:builtB])]);
        line([NSString stringWithFormat:@"      拼出的长串 vs 拼出的长串：== %@、isEqual: %@", MXYesNo(longA == longB), MXYesNo([longA isEqual:longB])]);
        line([NSString stringWithFormat:@"      长字面量 vs 拼出的长串  ：== %@、isEqual: %@", MXYesNo(litLong == longA), MXYesNo([litLong isEqual:longA])]);
        expect(lit1 == lit2 && lit1 != builtA && builtA == builtB && longA != longB && litLong != longA,
               @"这就是 `==` 比内容最危险的地方：它不是永远错，而是**看长度和存储方式碰运气** —— 字面量在常量池里被合并（对），短 ASCII 串走 tagged pointer、指针本身就编码了内容（也对），长串在堆上是两个对象（错）");
        expect([lit1 isEqual:lit2] && [lit1 isEqual:builtA] && [builtA isEqual:builtB] && [longA isEqual:longB] && [litLong isEqual:longA],
               @"isEqual: 五组全对：它比的是内容，跟对象怎么存、存在哪无关。字符串用 isEqualToString:，其它对象用 isEqual:");
        expect([builtA hash] == [lit1 hash],
               @"isEqual: 成立的对象 hash 必须相等（反过来不要求）：NSSet / NSDictionary 的键就是靠 hash + isEqual: 两步找到的，所以拿可变对象当键会出事（05 章实测）");
        NSMutableString *mstr = [builtA mutableCopy];
        expect([mstr isEqual:builtA] && [mstr isKindOfClass:[NSString class]] && [mstr class] != [builtA class],
               [NSString stringWithFormat:@"%@ 和 %@ 都 isKindOfClass:NSString（可变与不可变是同一个类簇的两个分支），所以类型问不出「它可不可变」—— 想挡住外部改动只有一条路：属性写 copy（§5 实测）",
                NSStringFromClass([mstr class]), NSStringFromClass([builtA class])]);
        expect([@(42) isEqual:@(42)] && [@(42) compare:@(43)] == NSOrderedAscending,
               @"NSNumber 比内容用 isEqual: / 比大小用 compare:，不是 ==：`@1 + @2` 更是根本编译不过（编译器诊断见本章末尾）");
        expect([@[ @1, @2 ] isEqual:@[ @1, @2 ]] && ![@[ @1, @2 ] isEqual:@[ @2, @1 ]],
               @"集合的 isEqual: 是逐个元素比：NSArray 看顺序（反过来就不等），NSSet 不看顺序");

        // -------------------------------------------------- 3) 控制语句
        line(@"");
        line(@"== 控制语句（一）：分支 ==");
        NSInteger score = 74;
        NSString *grade = nil;
        if (score >= 90) { grade = @"A"; }
        else if (score >= 70) { grade = @"B"; }
        else if (score >= 60) { grade = @"C"; }
        else { grade = @"D"; }
        expect([grade isEqualToString:@"B"], @"if / else if 链从上往下第一个成立的就走它，后面的判断根本不发生：条件顺序就是优先级");
        NSString *ternaryGrade = score >= 60 ? @"及格" : @"不及格";
        expect([ternaryGrade isEqualToString:@"及格"], @"一层判断用三目，别写四行 if/else");
        switch (MXLevelHigh) {
            case MXLevelLow:
                grade = @"低";
                break;
            case MXLevelMid:
                grade = @"中";
                break;
            case MXLevelHigh:
                grade = @"高";
                break;
            default:
                grade = @"未知";
                break;
        }
        expect([grade isEqualToString:@"高"], @"switch 只能分支整型（枚举底层就是整型，见 §1）：case 值必须是编译期常量");
        NSInteger switchFalls = 0;
        switch (0) {
            case 0:
                switchFalls += 1;
                __attribute__((fallthrough));
            case 1:
                switchFalls += 10;
                break;
        }
        expect(switchFalls == 11,
               @"少写一个 break 就顺着掉下去：28 章 §2 量过这台机器的 clang 只认 __attribute__((fallthrough))，五种「// fall through」注释写法都还会警告");

        line(@"");
        line(@"== 控制语句（二）：循环，与 for-in 的真面目 ==");
        NSInteger forSum = 0;
        for (NSInteger k = 0; k < 5; k++) { forSum += k; }
        NSInteger whileSum = 0;
        NSInteger w = 0;
        while (w < 5) { whileSum += w; w += 1; }
        NSInteger doSum = 0;
        NSInteger d = 0;
        do { doSum += d; d += 1; } while (d < 5);
        expect(forSum == 10 && whileSum == 10 && doSum == 10,
               [NSString stringWithFormat:@"for / while / do-while 三种写法算出同一个和（%ld）：OC 的循环完全继承 C 的那套（逐条对照见 28 章 §2），唯一的区别是 do-while 无条件先跑一次", (long)forSum]);
        NSInteger doOnce = 0;
        do { doOnce += 1; } while (NO);
        expect(doOnce == 1, @"do{...}while(NO) 也跑了一次：条件是「跑完再看」");
        MXTapioca *tapioca = [[MXTapioca alloc] initWithItems:5];
        NSInteger seen = 0;
        NSInteger sumOfSeen = 0;
        for (NSNumber *n in tapioca) {
            seen += 1;
            sumOfSeen += n.integerValue;
        }
        line([NSString stringWithFormat:@"      每批交付的个数记下来是 %@（共回调 %ld 次）",
             [tapioca.batchSizes componentsJoinedByString:@"、"], (long)tapioca.calls]);
        expect(seen == 5 && sumOfSeen == 15 && tapioca.calls == 4,
               [NSString stringWithFormat:@"for-in 遍历自造容器：拿到 %ld 个元素、和=%ld，协议方法被回调 %ld 次 —— 5 个元素按每批 2 个交付就是 2、2、1，之后再被问一次、交 0 个表示结束。for-in 就是 countByEnumeratingWithState:objects:count: 的语法糖，一次一批不是一次一个",
                (long)seen, (long)sumOfSeen, (long)tapioca.calls]);
        NSArray *names = @[ @"Ada", @"Grace", @"Alan" ];
        __block NSInteger viaBlock = 0;
        NSMutableArray<NSString *> *joined = [NSMutableArray array];
        [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            viaBlock += 1;
            [joined addObject:[NSString stringWithFormat:@"%lu:%@", (unsigned long)idx, name]];
        }];
        expect(viaBlock == 3 && [joined[2] hasPrefix:@"2:"],
               @"enumerateObjectsUsingBlock: 给到 index 和一个 *stop 开关；把 *stop 置 YES 就中断，等效于 break");
        const NSUInteger namesCount = names.count;
        __block BOOL brokeEarly = NO;
        [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            if (idx == 1) { *stop = YES; brokeEarly = YES; }
        }];
        expect(brokeEarly && namesCount == 3, @"*stop 只是让这一轮枚举提前收尾，容器本身没动过");
        NSDictionary<NSString *, NSNumber *> *ages = @{ @"Ada": @36, @"Grace": @45, @"Alan": @38 };
        NSInteger ageSum = 0;
        for (NSString *key in ages) { ageSum += [ages[key] integerValue]; }
        expect(ageSum == 119, [NSString stringWithFormat:@"for-in 遍历 NSDictionary 拿到的是键（%lu 个），值要自己取：和=%ld", (unsigned long)ages.count, (long)ageSum]);
        NSMutableArray<NSString *> *keysSeen = [NSMutableArray array];
        for (NSString *key in ages) { [keysSeen addObject:key]; }
        expect([NSSet setWithArray:keysSeen].count == 3, @"字典的遍历顺序不保证：只能断言「集合相同」，绝不能断言「第一个是谁」—— 依赖顺序的写法会在下一次系统升级里坏掉");
        MXTapioca *empty = [[MXTapioca alloc] initWithItems:0];
        NSInteger nilLoop = 0;
        id nothing = nil;                       // 写成 id 而不是直接用 nil：nil 本身是 void *，编译器不肯拿它当可枚举对象（这条诊断见本章末尾）
        for (NSNumber *n in nothing) { nilLoop += 1; (void)n; }
        NSInteger emptyLoop = 0;
        for (NSNumber *n in empty) { emptyLoop += 1; (void)n; }
        expect(nilLoop == 0 && emptyLoop == 0, @"对 nil 做 for-in 不崩、一次都不进（nil 的 countByEnumerating... 消息落到 nil 上返回 0）：省掉判空");

        line(@"");
        line(@"== 控制语句（三）：@autoreleasepool 与 @try / @catch / @finally ==");
        // 这两样是 OC 在 C 的控制语句之外自己加的关键字。@autoreleasepool 的内存语义在 §10 量，
        // 这里先看它的「块」形状；@try 则是 OC 唯一像异常处理的语法。
        NSMutableArray<NSString *> *trail = [NSMutableArray array];
        @autoreleasepool {
            [trail addObject:@"池内：进块"];
        }
        [trail addObject:@"池外：块已结束"];
        expect([trail count] == 2, @"@autoreleasepool { } 就是一个作用域块，顺序执行，没有别的魔法");
        [trail removeAllObjects];
        @try {
            [trail addObject:@"try"];
            @throw [NSException exceptionWithName:@"MXDemo" reason:@"故意抛一个" userInfo:nil];
            [trail addObject:@"抛出去之后的语句永远不会被执行"];
        } @catch (NSException *e) {
            [trail addObject:[NSString stringWithFormat:@"catch：name=%@ reason=%@", e.name, e.reason]];
        } @finally {
            [trail addObject:@"finally"];
        }
        expect([trail count] == 3 && [trail[0] isEqualToString:@"try"] &&
               [trail[1] hasPrefix:@"catch"] && [trail.lastObject isEqualToString:@"finally"],
               @"@throw 之后同一个块里剩下的语句全部跳过：@catch 接手（拿到的是那个 NSException 对象），@finally 无论如何都跑，然后从 @try 之后继续往下走");
        line([NSString stringWithFormat:@"      实际接到的那一条：%@", trail[1]]);
        line(@"      对照一条量不得的：整数除零（10/0）不是 NSException，它是硬件陷阱，@catch 接不住，进程当场就没（探针记录见本章末尾）");
        [trail removeAllObjects];
        NSString *nilTarget = nil;
        @try {
            NSMutableArray *box = [NSMutableArray array];
            [box addObject:nilTarget];          // 集合不收 nil
            [trail addObject:@"没抛（不可能到这）"];
        } @catch (NSException *e) {
            [trail addObject:[NSString stringWithFormat:@"addObject:nil 被拦下：%@", e.name]];
        } @finally {
            [trail addObject:@"finally"];
        }
        expect([trail[0] hasPrefix:@"addObject"] && [trail.lastObject isEqualToString:@"finally"],
               @"这一条就是 §1 那个 NSNull 的存在理由：数组放不下 nil，只能放一个「代表没有」的对象");
        [trail removeAllObjects];
        @try {
            @try {
                [trail addObject:@"内层 try"];
                @throw [NSException exceptionWithName:@"MXInner" reason:@"内层抛的" userInfo:nil];
            } @catch (NSException *e) {
                [trail addObject:[NSString stringWithFormat:@"内层 catch %@", e.name]];
                @throw;                          // 原样再抛出去
            } @finally {
                [trail addObject:@"内层 finally"];
            }
            [trail addObject:@"不该到这"];
        } @catch (NSException *e) {
            [trail addObject:[NSString stringWithFormat:@"外层 catch %@", e.name]];
        }
        expect([trail[1] isEqualToString:@"内层 catch MXInner"] && [trail[3] isEqualToString:@"外层 catch MXInner"],
               @"裸写 `@throw;` 是「原样重抛当前这个异常」，不再新建对象：外层接到的还是同一个 NSException（name 一点没变）。异常匹配规则（谁写得具体谁先接）细节在 27 章 §17");
        line([NSString stringWithFormat:@"      抛与接的顺序记录：%@", [trail componentsJoinedByString:@" -> "]]);
        line(@"      但工程规则是：日常不用 @try 挡错误。可预期的失败走 NSError **（§11），不可恢复的才让它崩；OC 的异常不保证在 ARC 下不泄漏中间对象，所以第三方库里通常只用来兜底");

        // -------------------------------------------------- 4) 消息发送
        // [接收者 方法名:参数] 就是「给对象发消息」。它不是函数调用，而是运行时
        // 用 objc_msgSend 按 selector 查方法表。所以「给 nil 发消息」不会崩，
        // 只是什么都不发生（返回 0/nil）。
        line(@"");
        line(@"== 消息发送 与 nil ==");
        Person *p = [[Person alloc] initWithName:@"Ada" age:36];
        expect([[p greeting] isEqualToString:@"你好，我是Ada，36 岁"], @"实例方法返回正确字符串");
        expect([p doubleAge] == 72, @"doubleAge 返回 72");

        // 给 nil 发消息：返回标量得 0，返回对象得 nil，都不崩。
        Person *nobody = nil;
        expect([nobody doubleAge] == 0, @"给 nil 发返回标量的消息得到 0（不崩）");
        expect([nobody greeting] == nil, @"给 nil 发返回对象的消息得到 nil（不崩）");
        expect([nobody lengthOfName] == 0, @"readonly 属性给 nil 也是 0");
        // 但返回**结构体**时，nil 消息给的是「未定义值」—— 别依赖它。
        NSRange r = [nobody ageRange];
        line([NSString stringWithFormat:@"  nil 返回结构体：location=%lu（未定义，别用）", (unsigned long)r.location]);
        expect(YES, @"知道「nil 返回结构体不可靠」这条规则本身");

        // -------------------------------------------------- 5) 属性与点语法
        line(@"");
        line(@"== 属性 / 点语法 ==");
        p.age = 40;                       // 点语法 setter，等价于 [p setAge:40]
        expect(p.age == 40, @"点语法写属性生效");
        expect([p age] == 40, @"点语法读 = getter 方法调用");
        expect(p.lengthOfName == 3, @"readonly 计算属性 lengthOfName = 3");

        // copy 语义：给一个 NSMutableString，属性会 copy 成不可变副本，
        // 之后改那个可变串，属性值**不受影响**。这就是 NSString 属性用 copy 的原因。
        NSMutableString *mutable = [NSMutableString stringWithString:@"Grace"];
        Person *q = [[Person alloc] initWithName:mutable age:45];
        [mutable appendString:@"!!!"];     // 改原始可变串
        expect([q.name isEqualToString:@"Grace"], @"copy 属性不受原可变串后续修改影响");
        // readonly 属性只生成 getter —— 用 respondsToSelector: 问一下就知道了。
        expect([q respondsToSelector:@selector(age)] && [q respondsToSelector:@selector(setAge:)],
               @"@property 在运行时其实就是三条东西：一个 ivar、一个 getter、一个 setter（方法表细节见 27 章 §6）");
        expect(![q respondsToSelector:@selector(setLengthOfName:)],
               @"readonly 属性根本没有 setter：`q.lengthOfName = 3` 编译不过，但 `[q setLengthOfName:]` 在 id 上调用编译期不报错、运行时崩（探针记录见本章末尾）");
        // 对象赋值只拷指针（和 §1 里结构体的整块拷贝正相反）。
        Person *sameAsQ = q;
        sameAsQ.age = 60;
        expect(q.age == 60 && sameAsQ == q,
               @"对象赋值拷的是指针：改 sameAsQ 就是改 q 本身。结构体赋值拷的是整块内存（§1），两者完全不同 —— Swift 里「值类型 vs 引用类型」这条分界，OC 早就有了，只是藏在类型系统外面");
        // 上面那句 init 里写 _age 而不是 self.age = ，这里用子类的坏 setter 证明它不是洁癖。
        MXSetterTwists *twist = [[MXSetterTwists alloc] initWithName:@"Ada" age:36];
        NSInteger afterInit = twist.age;
        twist.age = 36;
        expect(afterInit == 36 && twist.age == 72,
               [NSString stringWithFormat:@"同一个 init、同一个 36：走 ivar（init 里）得到 %ld，走 setter（外部赋值）得到 %ld —— 「init 里必须写 _ivar」不是风格问题，是因为子类随时可能重写 setter",
                (long)afterInit, (long)twist.age]);

        // -------------------------------------------------- 6) id / SEL / 动态派发
        line(@"");
        line(@"== id / SEL / 动态性 ==");
        id obj = p;                        // id = 「任意对象指针」，无需星号
        expect([obj isKindOfClass:[Person class]], @"isKindOfClass: 运行时判类型");
        SEL sel = @selector(greeting);     // SEL = 方法名的运行时表示
        expect([p respondsToSelector:sel], @"respondsToSelector: 问对象会不会这个方法");
        // performSelector: 在 ARC 下会报 -Warc-performSelector-leaks：编译器不知道
        // 这个动态 selector 返回的对象该不该 release，怕泄漏。这是 OC 真实的坑，
        // 标准做法是用 pragma 局部静音（并在心里清楚风险）。详见下面 §6 正文与本章末尾的探针记录。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id dynResult = [p performSelector:sel];
#pragma clang diagnostic pop
        expect(dynResult != nil, @"performSelector: 动态调用（pragma 局部静音泄漏告警）");
        // @optional 协议方法：调之前必须先问。
        id<Speaker> speaker = p;
        if ([speaker respondsToSelector:@selector(whisper)]) {
            line([NSString stringWithFormat:@"  whisper = %@", [speaker whisper]]);
            expect(YES, @"@optional 方法先 respondsToSelector: 再调");
        }

        // -------------------------------------------------- 7) 协议（多态）
        line(@"");
        line(@"== 协议 protocol ==");
        id<Speaker> s = p;                 // 面向协议编程：只认 Speaker，不认 Person
        NSString *said = [s speakTimes:2];
        expect([said containsString:@"Ada"], @"通过协议调用 required 方法");
        expect([[said componentsSeparatedByString:@" / "] count] == 2, @"speakTimes:2 说了两遍");
        expect([p conformsToProtocol:@protocol(Speaker)],
               @"conformsToProtocol: 运行时问「你声明过遵循这个协议吗」：面向协议解耦的那一半靠它兜底");
        expect([Person instancesRespondToSelector:@selector(speakTimes:)] &&
               ![Person instancesRespondToSelector:@selector(notDeclaredAnywhere)],
               @"instancesRespondToSelector: 问的是「这个类的实例会不会」，不用先造对象 —— 协议里的 @required 有没有真被实现，问一句就知道（编译器只在「显式声明遵循却没实现」时警告，见本章末尾探针记录）");
        expect([s respondsToSelector:@selector(whisper)] && [@"x" respondsToSelector:@selector(whisper)] == NO,
               @"同一个 selector 问两种对象，一个会一个不会：这就是 delegate 只认 id<Protocol>、调用前先问一遍的原因");

        // -------------------------------------------------- 8) 分类
        line(@"");
        line(@"== 分类 category ==");
        expect([[p vipGreeting] hasPrefix:@"[VIP]"], @"分类方法已合并进 Person");
        expect([p isKindOfClass:[Person class]], @"分类不改变类型，运行时同一张方法表");
        expect([[@"hi" mx_shout] isEqualToString:@"HI！！！"],
               @"分类最常见的用途就是这个：给 NSString / NSDate 这类已有类贴工具方法，不改源码、不建子类");
        id anything = @"hi";
        expect([[anything mx_shout] isEqualToString:@"HI！！！"],
               @"分类方法在 `id` 上一样能调：编译期根本不查它是哪个类的方法表 —— 灵活的另一面是「两个分类实现同名方法时，结果由加载顺序决定」，那一条在 27 章 §10 量过");

        // -------------------------------------------------- 9) block（闭包）
        line(@"");
        line(@"== block ==");
        // block 是 OC 的闭包。语法：返回类型 (^名字)(参数)。
        NSInteger (^add)(NSInteger, NSInteger) = ^NSInteger(NSInteger a, NSInteger b) {
            return a + b;
        };
        expect(add(2, 3) == 5, @"block 可像函数一样调用");
        // 数组按 block 排序（对应 Swift 的 sorted(by:)）。
        NSArray<NSNumber *> *nums = @[@5, @2, @8, @1];
        NSArray *sorted = [nums sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
            return [a compare:b];
        }];
        expect([sorted.firstObject intValue] == 1, @"block 作为排序比较器");
        expect([sorted.lastObject intValue] == 8, @"排序结果末位是 8");
        // block 捕获的是「值」：外面那个变量之后再改，块里看到的还是捕获那一刻的副本。
        NSInteger capturedPlain = 1;
        __block NSInteger capturedBlock = 1;
        NSInteger (^readBoth)(void) = ^NSInteger { return capturedPlain + capturedBlock; };
        capturedPlain = 100;
        capturedBlock = 100;
        expect(readBoth() == 101,
               @"没标 __block 的捕获是「按值拷贝进块」（读到旧的 1），标了 __block 才是引用同一个变量（读到新的 100）：1 + 100 = 101 就是这两种捕获的差");
        // block 存进属性必须写 copy（把块从栈搬到堆）；下面是 §10 循环引用实验的道具。
        __block NSInteger blockCalls = 0;
        void (^reusable)(void) = ^{ blockCalls += 1; };
        reusable();
        reusable();
        expect(blockCalls == 2, @"block 就是个对象，可以存起来反复调（次数是数出来的）");

        // -------------------------------------------------- 10) ARC 与内存管理
        line(@"");
        line(@"== ARC：strong / weak / 循环引用 / @autoreleasepool ==");
        // 这一节的度量全靠 MXCounted 的 -dealloc 改计数：对象解没解掉，第一次变成可看见的数字。
        line([NSString stringWithFormat:@"    起点：进程里 MXCounted 还活着 %ld 个（本章到这里造过 %ld 个）", (long)gAlive, (long)gTotal]);
        NSInteger baseline = gAlive;
        @autoreleasepool {
            MXCounted *kept = [[MXCounted alloc] initWithTag:1];
            (void)kept;
            expect(gAlive == baseline + 1, @"alloc/init 之后：活的个数 +1");
            kept = nil;                        // 唯一的强引用断开
            expect(gAlive == baseline, @"把唯一的 strong 置 nil，ARC 当场就发了 release：对象立刻释放（不用等池子）");
        }
        @autoreleasepool {
            __autoreleasing MXCounted *autoreleased = [[MXCounted alloc] initWithTag:2];
            expect(gAlive == baseline + 1 && autoreleased.tag == 2, @"登记进池子的对象活着");
            autoreleased = nil;                // 断开局部引用：ARC 对 __autoreleasing 变量不发 release
            expect(gAlive == baseline + 1,
                   @"autorelease 语义：即使把引用置 nil 对象**也还活着**，它只是被记在当前池的账上，等池子排空才释放");
        }
        expect(gAlive == baseline,
               @"出了 @autoreleasepool 那一层，登记过的对象才真的 dealloc —— 这就是「池子排空」的确切含义（上面那条 strong 置 nil 立刻释放，对比的就是这一条）");
        // 嵌套池：大循环里每轮一个小池，临时对象一轮一清，不会堆到循环结束。
        NSInteger highWaterInsideLoop = 0;
        for (NSInteger k = 0; k < 50; k++) {
            @autoreleasepool {
                MXCounted *tmp = [[MXCounted alloc] initWithTag:k];
                (void)tmp;
                tmp = nil;
                if (gAlive > highWaterInsideLoop) { highWaterInsideLoop = gAlive; }
            }
        }
        expect(highWaterInsideLoop == baseline && gAlive == baseline,
               [NSString stringWithFormat:@"50 轮循环 + 每轮一个内层池：循环内最高水位 = %ld（就是起点值），循环外也回到 %ld —— 大循环里造临时对象要包池，这是 06 章 Swift 侧同一条规则的 OC 版", (long)highWaterInsideLoop, (long)gAlive]);
        // weak：不持有，而且对象一没就自动变 nil。
        __weak MXCounted *watcher = nil;
        @autoreleasepool {
            MXCounted *target = [[MXCounted alloc] initWithTag:3];
            watcher = target;
            expect(watcher == target && watcher.tag == 3, @"weak 引用正常读，但它不持有对象（活的个数没因它 +1）");
        }
        expect(watcher == nil,
               @"出了作用域对象释放，weak 自动变 nil：这就是 delegate 一律写 weak 的原因 —— 它既不会把宿主拖住，也不会变成野指针");
        // 循环引用：两个对象互相 strong，外面的引用全断开也解不掉。
        NSInteger beforeCycle = gAlive;
        @autoreleasepool {
            MXCounted *x = [[MXCounted alloc] initWithTag:4];
            MXCounted *y = [[MXCounted alloc] initWithTag:5];
            x.strongFriend = y;
            y.strongFriend = x;
            expect(gAlive == beforeCycle + 2, @"配对造好：活的个数 +2");
        }
        expect(gAlive == beforeCycle + 2,
               [NSString stringWithFormat:@"离开作用域、局部强引用全断了，活的个数却还是 %ld（该是 %ld）：x 持有 y、y 持有 x，谁先到 0 都轮不到 —— 这 2 个对象漏了，且永远不会被发现在进程里",
                (long)gAlive, (long)beforeCycle]);
        NSInteger beforeWeakCycle = gAlive;
        @autoreleasepool {
            MXCounted *x = [[MXCounted alloc] initWithTag:6];
            MXCounted *y = [[MXCounted alloc] initWithTag:7];
            x.weakFriend = y;
            y.strongFriend = x;          // 单向持有 + 一条弱边
        }
        expect(gAlive == beforeWeakCycle,
               @"把其中一条改成 weak：这一对正常释放，个数回到起点 —— 「打破循环」就是把父子/宿主与 delegate 之间那一条边变弱");
        // block 捕获 self 的循环引用：同一个道具，两种写法，两种结果。
        gOwnerReleased = 0;
        @autoreleasepool {
            MXBlockOwner *owner = [[MXBlockOwner alloc] init];
            owner.onRelease = ^{ gOwnerReleased += 1; };
            expect(gOwnerReleased == 0, @"block 还没跑：对象仍在手里");
        }
        expect(gOwnerReleased == 1,
               @"strong/copy 属性 + 一个不捕获任何东西的 block：对象正常释放，dealloc 里的 block 跑了 1 次（这是对照组）");
        gOwnerReleased = 0;
        @autoreleasepool {
            MXBlockOwner *owner = [[MXBlockOwner alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
            // 这一行 clang 自己就会警告「capturing 'owner' strongly in this block is likely to lead to a retain cycle」，
            // 原文抄在本章末尾的探针记录里。这里静音只是为了让编译日志保持干净。
            owner.onRelease = ^{ gOwnerReleased += 1; [owner hash]; };   // 块里用了 owner 自己
#pragma clang diagnostic pop
        }
        expect(gOwnerReleased == 0,
               @"block 里引用了 owner：copy 属性强引用 block、block 强引用 owner —— 循环成立，对象永远不释放，dealloc 里那个报信 block 一次都没跑。这就是 OC 的头号内存坑（clang 甚至会在编译期就警告它，诊断见本章末尾）");
        gOwnerReleased = 0;
        @autoreleasepool {
            MXBlockOwner *owner = [[MXBlockOwner alloc] init];
            __weak MXBlockOwner *weakSelf = owner;
            owner.onRelease = ^{
                MXBlockOwner *strongSelf = weakSelf;      // weak-strong dance
                gOwnerReleased += 1;
                [strongSelf hash];
            };
        }
        expect(gOwnerReleased == 1,
               [NSString stringWithFormat:@"换成 weak-strong dance（块外 weak、块内再临时转 strong）：对象正常释放，block 跑了 %ld 次 —— 和上面那条唯一的区别就是捕获的是 weak 还是 self", (long)gOwnerReleased]);

        // -------------------------------------------------- 11) NSError 二级指针
        line(@"");
        line(@"== 错误处理 NSError ==");
        NSError *err = nil;
        BOOL ok = [p renameTo:@"" error:&err];   // 传 &err（二级指针）
        expect(ok == NO, @"空名字改名失败返回 NO");
        expect(err != nil, @"错误经二级指针传出，err 被填充");
        expect(err.code == 1001, @"错误码 1001");
        expect([err.domain isEqualToString:@"MXRenameErrorDomain"], @"自定义错误域");
        expect([err.localizedDescription isEqualToString:@"名字不能为空"], @"userInfo 里的本地化描述");
        // 成功路径：err 保持 nil。
        NSError *err2 = nil;
        BOOL ok2 = [p renameTo:@"Alan" error:&err2];
        expect(ok2 == YES && err2 == nil, @"成功时返回 YES 且 err 不被填");
        expect([p.name isEqualToString:@"Alan"], @"改名成功");

        // -------------------------------------------------- 12) description / %@
        line(@"");
        line(@"== description 与 %@ ==");
        NSString *desc = [NSString stringWithFormat:@"%@", p];   // %@ 走 description
        expect([desc containsString:@"Alan"], @"%@ 打印的是重写后的 description");
        expect([desc hasPrefix:@"<Person"], @"description 格式符合自定义");

        // -------------------------------------------------- 13) OC 里的 UIKit 一瞥
        line(@"");
        line(@"== OC 调 UIKit ==");
        UILabel *label = [[UILabel alloc] init];
        label.text = [p greeting];
        [label sizeToFit];
        expect(label.text.length > 0, @"OC 一样能构造 UIKit 控件");
        UIColor *c = [UIColor systemBlueColor];
        expect(c != nil, @"OC 调 UIKit 类方法（systemBlueColor）");
        CGFloat widthBefore = label.frame.size.width;
        label.font = [UIFont systemFontOfSize:28.0];     // 换大一号字体，再让控件自己量
        [label sizeToFit];
        expect(label.frame.size.width > widthBefore && label.frame.size.height > 0,
               @"同一段文字、更大的字号：sizeToFit 把 frame 改大了（具体数字取决于字体渲染，所以只断言「变大且非零」）。关键是单位 —— UIKit 的几何值全是 point，不是像素");
        CGFloat scale = label.traitCollection.displayScale;
        expect(scale > 0 && scale == (CGFloat)(NSInteger)scale,
               @"UIKit 的所有几何值单位都是 point，屏幕自己有一个 displayScale（这台设备上是整数倍，1pt = scale 个像素）：换算细节在 10/14 章展开，本章只把「frame 不是像素」这件事钉住");

        // -------------------------------------------------- 14) 本章的边界
        line(@"");
        line(@"== 本章的边界：哪些是量出来的、哪些只能记、哪些留给下一章 ==");
        line(@"  量出来的（上面每一条 ok 都来自这次运行，换优化级别结果一致）：");
        line(@"    标量宽度表、NSInteger/CGFloat/BOOL 的真实宽度、整数变 BOOL 的三条路（都是 1，不是书上说的截成 0）、");
        line(@"    字面量默认类型、八进制/十六进制、五种进制打法、float 窄化后的真实值、");
        line(@"    nil/Nil/NULL/NSNull 的四种含义、@() 与 @\"\" 的四个真实类名、tagged pointer 让 `==` 时灵时不灵的五组结果、");
        line(@"    短路的确切求值次数（&&、|| 各 1 次，单个 & 是 2 次）、for-in 的批次序列（2、2、1、0 共 4 次回调）、");
        line(@"    strong 置 nil 立刻释放 vs __autoreleasing 等池子排空、循环引用扣住 2 个对象不放、weak-strong dance 放行、");
        line(@"    子类重写 setter 之后 init 里 _ivar 与 self.xxx 的两种结果（36 vs 72）。");
        line(@"  只记不跑的（示例里一行都没执行，全部来自独立探针，正文以「探针记录」引用编译器/运行时原文）：");
        line(@"    不带括号的 4|2&1 与 1+2<<2、(a==0)&(b==1) 三个优先级警告；int big = 9999999999999 的 -Wconstant-conversion；");
        line(@"    switch 一个对象指针、@1 + @2、readonly 属性赋值、block 改无 __block 的外层变量、for-in nil、");
        line(@"    @[@1, nil]、@(nil) 七个编译错误；分类里 @property 不实现、声明遵循协议却不实现两个警告；");
        line(@"    整数除零的硬件陷阱、给对象发一个它没有的 selector（unrecognized selector）。");
        line(@"  探针记录：下面每条都是独立小程序在同一套工具链（Apple clang 16 / iPhoneSimulator18.2.sdk /");
        line(@"    x86_64-apple-ios15.0-simulator / 同一台模拟器）上真跑出来的原文，示例本身一行都没执行它们。");
        line(@"    文件名都是探针自己起的，行号是探针里的行号；地址一律按本章规矩抹成 0x…。");
        line(@"    1) 优先级三兄弟。源码：int a=4,b=2,c=1; return (a | b & c) + (1 + 2 << 2);");
        line(@"       p1.m:2:57: warning: '&' within '|' [-Wbitwise-op-parentheses]");
        line(@"       p1.m:2:57: note: place parentheses around the '&' expression to silence this warning");
        line(@"       p1.m:2:67: warning: operator '<<' has lower precedence than '+'; '+' will be evaluated first [-Wshift-op-parentheses]");
        line(@"       再来一条布尔的：`(x==0) & (y==1)` 报 warning: use of bitwise '&' with boolean operands [-Wbitwise-instead-of-logical]");
        line(@"       三条都是 -Wall -Wextra 默认就响的，所以本章正文里那两条式子必须带括号写。");
        line(@"    2) 大常数塞进 int。源码：int big = 9999999999999;");
        line(@"       w_int.m:1:28: warning: implicit conversion from 'long' to 'int' changes value from 9999999999999 to 1316134911 [-Wconstant-conversion]");
        line(@"       「数据会丢」这句话书里只写在正文里，clang 直接把丢完的结果打给你看。");
        line(@"    3) switch 一个对象。源码：NSString *s=@\"a\"; switch (s) {…}");
        line(@"       e_switch.m:2:38: error: statement requires expression of integer type ('NSString *__strong' invalid)");
        line(@"    4) NSNumber 相加。源码：NSNumber *n = @1 + @2;");
        line(@"       e_numadd.m:2:35: error: invalid operands to binary expression ('NSNumber *' and 'NSNumber *')");
        line(@"    5) 给 readonly 属性赋值。源码：q.lengthOfName = 3;");
        line(@"       e_roset.m:2:87: error: assignment to readonly property");
        line(@"    6) block 改外层变量。源码：int x=1; void(^b)(void)=^{ x=2; };");
        line(@"       e_blockcap.m:2:52: error: variable is not assignable (missing __block type specifier)");
        line(@"    7) 对 nil 做 for-in。源码：for (NSNumber *n in nil) {…}");
        line(@"       main.m:400:9: error: the type 'void *' is not a pointer to a fast-enumerable object");
        line(@"       —— 编译器不许拿 nil 当容器；本章正文改成 `id nothing = nil;` 才过，运行时那次「不进循环」是量出来的。");
        line(@"    8) 集合字面量里放 nil。源码：NSArray *a = @[ @1, nil ];");
        line(@"       e_arrnil.m:2:38: error: collection element of type 'void *' is not an Objective-C object");
        line(@"    9) 装箱 nil。源码：id x = nil; NSNumber *n = @(x);");
        line(@"       e_atnil.m:2:44: error: illegal type 'id' used in a boxed expression");
        line(@"   10) 分类里写 @property。源码：@interface NSString (MX) @property (nonatomic,copy) NSString *mx_tag; @end");
        line(@"       w_catprop.m:5:17: warning: property 'mx_tag' requires method 'mx_tag' to be defined - use @dynamic or provide a method implementation in this category [-Wobjc-property-implementation]");
        line(@"       w_catprop.m:5:17: warning: property 'mx_tag' requires method 'setMx_tag:' to be defined …（getter/setter 各一条）");
        line(@"       分类不能自动合成 ivar，这两条警告就是它的官方说法；硬要存只能上关联对象（27 章 §7）。");
        line(@"   11) 声明遵循协议却不实现。源码：@interface MXNoImpl : NSObject <MXS> @end，MXS 有 @required -speak");
        line(@"       w_protodecl.m:8:17: warning: method 'speak' in protocol 'MXS' not implemented [-Wprotocol]");
        line(@"   12) 故意留的循环引用。源码：owner.onRelease = ^{ [owner hash]; };");
        line(@"       main.m:739:56: warning: capturing 'owner' strongly in this block is likely to lead to a retain cycle [-Warc-retain-cycles]");
        line(@"       main.m:739:13: note: block will be retained by the captured object");
        line(@"       —— 循环引用是编译器真能看出来的那一类，正文用 pragma 局部静音才让它跑起来。");
        line(@"   13) float 窄化一声不响。源码：float f = 0.1;（-Wall -Wextra 零诊断）");
        line(@"       但一旦拿它和 double 字面量比，就冒出：warning: floating-point comparison is always true; constant cannot be represented exactly in type 'float' [-Wliteral-range]");
        line(@"   14) 整数除零。源码：volatile int zero=0; int bad = ten / zero;");
        line(@"       xcrun simctl spawn … 的原文：Child process terminated with signal 8: Floating point exception（退出码 136）");
        line(@"       前面那句 NSLog 一行都没打：它不是 NSException，@catch 接不住，进程当场就没。");
        line(@"   15) 给对象发一个它没有的 selector。源码：[(@[@1]) performSelector:NSSelectorFromString(@\"thisOneDoesNotExistAtAll\")];");
        line(@"       *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason:");
        line(@"           '-[NSConstantArray thisOneDoesNotExistAtAll]: unrecognized selector sent to instance 0x…'");
        line(@"       顺带三个信息量很大的细节：这次是「uncaught exception」（@try 能接住它，但接住就等于把 bug 藏了）；");
        line(@"       调用栈里有 ___forwarding___（27 章 §8 那四级台阶就是从这里开始的）；而打出来的类名是 NSConstantArray，");
        line(@"       不是 NSArray —— §1 那句「别拿 [x class] 当身份」再一次被运行时亲自证明。");
        line(@"  还有一条是这次改示例时撞上的：`__autoreleasing MXCounted *a = [[MXCounted alloc] init];` 如果后面一行都不读它，");
        line(@"    clang 报 warning: variable 'a' set but not used [-Wunused-but-set-variable]，并且在 -O2 下真的把这次分配消掉了 ——");
        line(@"    那一版「池子排空前还活着」的断言直接 FAIL。读一下 a.tag 之后才恢复。度量必须被观测，这句话在编译器这一层也成立。");

        line(@"  留给别的章的：SEL 唯一化 / IMP 交换 / 消息转发四级台阶 / @encode / KVC / KVO / 方法表合并顺序 -> 27 章；");
        line(@"    C 那一层的 sizeof、对齐、可变参数、malloc、宏 -> 28 章；NSString / 集合 / 数据 / JSON -> 05 章；Swift 侧的对应写法 -> 06、07 章。");
        line(@"  换一台机器（arm64 真机）会变的东西：所有 sizeof 数字里 long/NSInteger/CGFloat/指针那一列本来就是 8，不变；");
        line(@"    会变的是 tagged pointer 那套类名（NSTaggedPointerString 的具体存在与长度阈值）和 NSString 私有类名 —— 所以本章从不拿类名做判断，只打印出来给你认日志。");

        line(@"");
        if (gFailures == 0) { line(@"全部断言通过。"); }
        else { line([NSString stringWithFormat:@"有 %d 条断言失败。", gFailures]); }
        printf("==== 04 结束 ====\n");
    }
    return gFailures == 0 ? 0 : 1;
}
