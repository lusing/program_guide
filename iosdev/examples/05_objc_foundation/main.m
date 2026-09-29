// ============================================================
// 05 - Foundation（Objective-C 篇）：字符串、集合、数据、日期、JSON
//
// 书本第 8 章「Foundation 框架基础」的完整落地：数字 / 字符串 / 日期 / 数组 /
// 字典 / 集合，外加 OC 侧离不开的 NSData、plist 与 NSJSONSerialization。
// 这一章的原则和 04 章一样：**每一条结论都是跑出来的**，不是背出来的。
// 凡是「书上说会崩/会乱」的，先用独立探针量一遍，再把原文记进 §16；
// 能在断言之安全跑的部分，才放进正文。
//
// 纯 OC，clang 编译；输出用 printf（不用 NSLog，保持 stderr 为空）。
// 桥接侧（Swift 的 String/Data/Array 另一副面孔）见第 06 章。
// ============================================================

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>          // §6 的 NSValue 几何分类在 UIKit 里（不是 Foundation）

static int gFailures = 0;
static void expect(BOOL condition, NSString *desc) {
    printf("  %s %s\n", condition ? "ok  " : "FAIL", [desc UTF8String]);
    if (!condition) { gFailures += 1; }
}
static void line(NSString *s) { printf("%s\n", [s UTF8String]); }
// 类名不是地址，可以安全打印；但它是**私有实现**，只能当证据看，不能当身份判断用。
static NSString *MXCls(id obj) { return NSStringFromClass([obj class]); }

// —— 供 §8 makeObjectsPerformSelector: 计数用的类（把「调了几次」变成数字）——
static NSInteger gHelloCount = 0;
@interface MXGreeter : NSObject
@property (nonatomic, copy) NSString *name;
- (instancetype)initWithName:(NSString *)n;
- (void)sayHello;
@end
@implementation MXGreeter
- (instancetype)initWithName:(NSString *)n {
    self = [super init];
    if (self) { _name = [n copy]; }
    return self;
}
- (void)sayHello { gHelloCount += 1; }
@end

// —— 供 §12 的哈希契约实验：只重写 isEqual:，故意不重写 hash ——
@interface MXUser : NSObject <NSCopying>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pass;
- (instancetype)initWithName:(NSString *)n pass:(NSString *)p;
@end
@implementation MXUser
- (instancetype)initWithName:(NSString *)n pass:(NSString *)p {
    self = [super init];
    if (self) { _name = [n copy]; _pass = [p copy]; }
    return self;
}
- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MXUser class]]) return NO;
    MXUser *o = object;
    return [self.name isEqualToString:o.name] && [self.pass isEqualToString:o.pass];
}
- (id)copyWithZone:(NSZone *)zone { return [[MXUser alloc] initWithName:self.name pass:self.pass]; }
@end
// 补上 hash 的同一套判等 —— §12 用它证明「少写一个方法，集合就当没看见」
@interface MXHashedUser : MXUser
@end
@implementation MXHashedUser
- (NSUInteger)hash { return self.name.hash ^ self.pass.hash; }
@end

// —— §9 的 C 比较函数（sortedArrayUsingFunction:context: 要的就是这个形状）——
static NSComparisonResult MXCompareString(id a, id b, void *context) {
    (void)context;
    return [(NSString *)a compare:(NSString *)b];
}

int main(void) {
    @autoreleasepool {

        line(@"== 05 Foundation（Objective-C 篇）==");

        // -------------------------------------------------- 1) NSString 的创建
        line(@"");
        line(@"== 1) NSString 的创建：同一串内容的四条路 ==");
        NSString *lit = @"Cocoa";                                  // 编译期常量
        NSString *copied = [NSString stringWithString:lit];        // 类方法便利构造
        NSString *fromC = [NSString stringWithUTF8String:"Cocoa"]; // 从 C 字符串转
        NSString *made = [[NSString alloc] initWithFormat:@"%@%@", @"Co", @"coa"];
        line([NSString stringWithFormat:@"  四条路 = %@ | %@ | %@ | %@", lit, copied, fromC, made]);
        expect([lit isEqualToString:copied] && [copied isEqualToString:fromC] && [fromC isEqualToString:made],
               @"四条路造出的串**内容**全等：isEqualToString: 比内容，不看怎么造出来的");
        expect(lit == copied,
               @"字面量与 stringWithString: 是同一个对象（常量池里那份）：stringWithString: 遇到不可变串就返回自己");
        expect(lit != made,
               @"initWithFormat: 走的是运行时拼接，一定是新对象：内容一样不等于同一个");
        expect([lit isKindOfClass:[NSString class]] && [fromC isKindOfClass:[NSString class]],
               @"四条路的返回值都是 NSString —— 但**具体是哪一个 NSString 私有子类**见 04 章 §数据类型（四）");

        // 用 UTF-16 码元数组直接造串：这是「length 是码元数」这句话的物理来源
        unichar units[] = { 'A', 'B', 0xD83D, 0xDE00 };   // 0xD83D/0xDE00 = 😀 的代理对
        NSString *fromUnits = [NSString stringWithCharacters:units length:4];
        line([NSString stringWithFormat:@"  码元数组造的串 = %@（length=%lu）",
              fromUnits, (unsigned long)fromUnits.length]);
        expect(fromUnits.length == 4, @"stringWithCharacters: 收的是 UTF-16 码元，4 个码元就是 length 4");
        expect([fromUnits hasPrefix:@"AB"], @"前两个码元是 'A' 'B'");
        expect([[fromUnits substringFromIndex:2] isEqualToString:@"😀"],
               @"后两个码元（一个代理对）合起来才是一个 emoji：拆开半个就是乱码");

        // -------------------------------------------------- 2) 格式说明符（printf 家族）
        line(@"");
        line(@"== 2) 格式说明符：stringWithFormat 底层就是 printf ==");
        NSInteger signedCount = -7;
        NSUInteger unsignedCount = 5;
        double ratio = 3.14159;
        int plainInt = 42;
        unichar ch = 'x';
        const char *cstr = "C-style";
        NSString *spec = [NSString stringWithFormat:
                          @"对象=%@ int=%d NSInteger=%ld NSUInteger=%lu zd=%ld tu=%lu "
                          @"float=%f 定点=%.2f 带宽度=%8.3f g=%g 指数=%e 字符=%c C串=%s 十六=%x 大写十六=%X 八进制=%o 补零=%05d 左对齐=[%-4d|] 百分号=100%%",
                          lit, plainInt, (long)signedCount, (unsigned long)unsignedCount,
                          (long)signedCount, (unsigned long)unsignedCount,
                          ratio, ratio, ratio, ratio, ratio, (int)ch, cstr,
                          plainInt, plainInt, plainInt, 42, plainInt];
        line([NSString stringWithFormat:@"  %@", spec]);
        expect([spec containsString:@"对象=Cocoa"], @"%@ 打对象走 -description（§12）");
        expect([spec containsString:@"NSInteger=-7"] && [spec containsString:@"NSUInteger=5"],
               @"NSInteger 用 %ld+(long)、NSUInteger 用 %lu+(unsigned long)：这是 64 位上唯一不折腾的写法");
        expect([spec containsString:@"zd=-7"] && [spec containsString:@"tu=5"],
               @"%ld 的等价写法是 %zd（C99 的 ssize_t），%tu 对应 ptrdiff_t —— 但 Apple 代码里九成还是 %ld+(long)");
        expect([spec containsString:@"定点=3.14"] && [spec containsString:@"带宽度=   3.142"],
               @"%.2f 管小数位、%8.3f 里的 8 是**总宽**（含小数点），不足就在左边补空格");
        expect([spec containsString:@"左对齐=[42  |]"], @"负号是「左对齐」：%-4d 把 42 推到左边");
        expect([spec containsString:@"补零=00042"], @"%05d 用 0 补齐到 5 位：写日期/序号定宽时靠它");
        expect([spec containsString:@"十六=2a"] && [spec containsString:@"大写十六=2A"] &&
               [spec containsString:@"八进制=52"], @"%x 小写十六、%X 大写、%o 八进制：42 的三种写法");
        expect([spec containsString:@"C串=C-style"] && [spec containsString:@"字符=x"],
               @"%s 收 char*（不是 NSString*！），%c 收 int（这里从 unichar 显式降下来）");

        // %d 只看低 32 位：这条不用探针也能测，因为截断动作自己写在 (int) 里
        NSUInteger big = (NSUInteger)0x100000001ULL;
        line([NSString stringWithFormat:@"  同一个值：%lu 当 int 读就是 %d",
              (unsigned long)big, (int)big]);
        expect((int)big == 1,
               @"64 位的 NSUInteger 塞进 %d（或先转 int）只会留低 32 位：2^32+1 变成 1 —— 编译器不会拦你，探针里那条 -Wformat 才是它唯一的提示");
        expect([NSString stringWithFormat:@"%.*f", 3, ratio].length == 5,
               @"%.*f 的精度由**参数**给（不是写在格式串里）：这是把宽度做成变量的唯一合法办法");

        // -------------------------------------------------- 3) 长度、遍历与编码
        line(@"");
        line(@"== 3) 长度、遍历与编码：length 不是字符数 ==");
        NSString *zh = @"你好 iOS";
        line([NSString stringWithFormat:@"  %@: length=%lu UTF-8字节=%lu 码元数组直读前2=%C %C",
              zh, (unsigned long)zh.length,
              (unsigned long)[zh lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              [zh characterAtIndex:0], [zh characterAtIndex:1]]);
        expect(zh.length == 6, @"length 是 UTF-16 码元数：两个汉字各 1 个码元 + 空格 + iOS 三个 = 6");
        expect([zh lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 10,
               @"同一串的 UTF-8 是 10 字节（汉字 3 字节 ×2 + 空格 + iOS 三个字母）：**length 数码元、lengthOfBytes 数字节，永远是两回事**");
        expect([zh characterAtIndex:0] == 0x4F60,
               @"characterAtIndex: 给的是 unichar（UTF-16 码元），不是字符 —— 汉字在 BMP 里刚好一个码元，所以看起来对");
        unichar pulled[7] = {0};
        [zh getCharacters:pulled range:NSMakeRange(0, 6)];
        expect(pulled[3] == 'i', @"getCharacters:range: 批量取码元，第 4 个是 'i'");
        // 代理对：一个 emoji 是两个「不是字符的半个字符」
        NSString *grin = @"😀";
        expect(grin.length == 2 && [grin characterAtIndex:0] == 0xD83D &&
               [grin characterAtIndex:1] == 0xDE00,
               @"😀 在 UTF-16 里是**两个**码元（0xD83D 0xDE00）：characterAtIndex: 拿到的是残缺的一半，这就是「别用 characterAtIndex: 遍历」的原因");
        NSMutableArray *clusters = [NSMutableArray array];
        [grin enumerateSubstringsInRange:NSMakeRange(0, grin.length)
                                 options:NSStringEnumerationByComposedCharacterSequences
                              usingBlock:^(NSString *sub, NSRange r1, NSRange r2, BOOL *stop) {
            [clusters addObject:sub];
        }];
        expect(clusters.count == 1,
               @"enumerateSubstrings:ByComposedCharacterSequences 才按「用户看到的字符」切：一个 emoji = 一段");
        NSString *combo = @"a👍🏽b";
        __block NSUInteger clusterCount = 0;
        [combo enumerateSubstringsInRange:NSMakeRange(0, combo.length)
                                  options:NSStringEnumerationByComposedCharacterSequences
                               usingBlock:^(NSString *sub, NSRange r1, NSRange r2, BOOL *stop) {
            clusterCount += 1;
        }];
        line([NSString stringWithFormat:@"  %@: length=%lu UTF-8=%lu 用户字符=%lu",
              combo, (unsigned long)combo.length,
              (unsigned long)[combo lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              (unsigned long)clusterCount]);
        expect(combo.length == 6 && clusterCount == 3,
               @"👍🏽 的 length 是 4（拇指代理对 + 肤色修饰符代理对），但它是**一个**用户字符：6 个码元 / 3 个字符 / 10 个 UTF-8 字节");

        // Unicode 规范化（书里没写，但这是「两个看起来一样的串不相等」的唯一解）
        NSString *precomposed = @"café";          // é 一个码位
        NSString *decomposed  = @"cafe\u0301";    // e + 组合重音符
        line([NSString stringWithFormat:@"  预组合 length=%lu / 分解 length=%lu",
              (unsigned long)precomposed.length, (unsigned long)decomposed.length]);
        expect(precomposed.length == 4 && decomposed.length == 5,
               @"两种合法写法：预组合 4 个码元、分解 5 个码元");
        expect([precomposed isEqualToString:decomposed] == NO,
               @"看起来一模一样，isEqualToString: 说是**不相等**：它逐码元比，不懂 Unicode 规范化");
        expect([[precomposed precomposedStringWithCanonicalMapping]
                isEqualToString:[decomposed precomposedStringWithCanonicalMapping]],
               @"precomposedStringWithCanonicalMapping 归一之后才相等 —— 拿外部数据当 key/去重之前必须先做这一步");

        // 编码转换：NSString ↔ C 字符串 ↔ NSData
        NSData *utf8 = [zh dataUsingEncoding:NSUTF8StringEncoding];
        NSString *backFromData = [[NSString alloc] initWithData:utf8 encoding:NSUTF8StringEncoding];
        expect([backFromData isEqualToString:zh], @"NSString → NSData(UTF-8) → NSString 往返无损");
        expect([zh cStringUsingEncoding:NSUTF8StringEncoding] != NULL,
               @"cStringUsingEncoding: 给的是**临时**的 const char*：出了这条语句就可能失效，要留存就自己拷");
        const uint8_t broken[] = { 0xFF, 0xFE, 0x41 };
        NSString *brokenString = [[NSString alloc]
            initWithData:[NSData dataWithBytes:broken length:sizeof(broken)]
                encoding:NSUTF8StringEncoding];
        expect(brokenString == nil,
               @"非法 UTF-8 解码**返回 nil**（不是崩溃、不是异常、也不是替换字符）：读外部字节流必须判 nil");

        // -------------------------------------------------- 4) 比较、排序与大小写
        line(@"");
        line(@"== 4) 比较、排序与大小写 ==");
        line([NSString stringWithFormat:@"  NSOrderedAscending=%ld Same=%ld Descending=%ld",
              (long)NSOrderedAscending, (long)NSOrderedSame, (long)NSOrderedDescending]);
        expect(NSOrderedAscending == -1 && NSOrderedSame == 0 && NSOrderedDescending == 1,
               @"三个比较结果是 -1/0/1：这就是 sort 用的比较器返回值，别自己发明第四种");
        expect([@"a" compare:@"b"] == NSOrderedAscending &&
               [@"b" compare:@"b"] == NSOrderedSame &&
               [@"b" compare:@"a"] == NSOrderedDescending,
               @"compare: 按**码位**顺序比：a<b 同向");
        expect([@"甲" compare:@"乙"] == NSOrderedDescending,
               @"中文按码位比：甲 U+7532 > 乙 U+4E59，所以「甲」排在后面 —— 想按拼音排不是 compare: 的活");
        expect([@"ABC" caseInsensitiveCompare:@"abc"] == NSOrderedSame,
               @"caseInsensitiveCompare: 忽略大小写");
        expect([@"cafe" compare:@"café" options:NSDiacriticInsensitiveSearch] == NSOrderedSame,
               @"compare:options: 的 NSDiacriticInsensitiveSearch 忽略音标：cafe 与 café 视为相等");
        NSArray *files = @[@"section10", @"section9", @"section2"];
        NSArray *byCode = [files sortedArrayUsingSelector:@selector(compare:)];
        NSArray *byNatural = [files sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        line([NSString stringWithFormat:@"  compare: → %@", [byCode componentsJoinedByString:@", "]]);
        line([NSString stringWithFormat:@"  localizedStandardCompare: → %@",
              [byNatural componentsJoinedByString:@", "]]);
        expect([byCode[0] isEqualToString:@"section10"],
               @"compare: 排出来 section10 在 section2 前面：逐字符比，'1' < '2'，它不懂数字");
        NSString *naturalText = [byNatural componentsJoinedByString:@", "];
        expect([naturalText isEqualToString:@"section2, section9, section10"],
               @"localizedStandardCompare: 是「Finder 排序」那套（数字按大小、忽略音标标点）：文件名列表要用它，别用 compare:");
        expect([@"Cocoa.h" hasPrefix:@"Co"] && [@"Cocoa.h" hasSuffix:@".h"],
               @"hasPrefix:/hasSuffix: 判头判尾：扩展名、scheme、前缀路由全靠它");
        expect(![@"Cocoa" isEqualToString:@"cocoa"], @"isEqualToString: 区分大小写，和 compare: 是两条路");
        expect([@"hello world".capitalizedString isEqualToString:@"Hello World"] &&
               [@"FILE".lowercaseString isEqualToString:@"file"] &&
               [@"file".uppercaseString isEqualToString:@"FILE"],
               @"三个变形都返回**新串**（stringBy… 那一族在 OC 里也叫 xxxString，都不改原件）");
        NSString *dotted = @"  Cocoa, ObjC \n";
        NSArray *tokens = [dotted componentsSeparatedByCharactersInSet:
                           [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
        line([NSString stringWithFormat:@"  切完 = [%@]（%lu 段，含空段）",
              [tokens componentsJoinedByString:@"|"], (unsigned long)tokens.count]);
        expect(tokens.count == 7 && [tokens[2] isEqualToString:@"Cocoa"] && [tokens[4] isEqualToString:@"ObjC"],
               @"componentsSeparatedByCharactersInSet: + invertedSet = 「按所有非字母数字切开」，比手写循环稳 —— 但**连续两个分隔符之间会切出一个空串**，开头的空白也算：所以「  Cocoa, ObjC」出来 7 段而不是 2 段，段数别当成有效词数");
        NSString *trimmed = [dotted stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        expect(trimmed.length == 11 && [trimmed isEqualToString:@"Cocoa, ObjC"],
               @"去首尾空白用 stringByTrimmingCharactersInSet:（首尾的空格、逗号后的都不算「首尾」）—— 它**不碰中间的字符**，所以剩下 Cocoa、逗号、空格、ObjC 共 11 个码元");

        // -------------------------------------------------- 5) 替换、删除与 NSMutableString
        line(@"");
        line(@"== 5) 替换、删除与 NSMutableString ==");
        NSString *src = @"This is string A";
        NSString *replaced = [src stringByReplacingOccurrencesOfString:@"This is" withString:@"An example of"];
        expect([replaced isEqualToString:@"An example of string A"] &&
               [src isEqualToString:@"This is string A"],
               @"不可变串的 stringByReplacing… 返回新串，原件一个字没动：这就是「不可变版返回新对象」。注意替换的是**能匹配上的那一段**（This is → An example of），后面的 string A 原样留着");
        NSMutableString *mstr = [NSMutableString stringWithString:src];
        [mstr replaceOccurrencesOfString:@"is" withString:@"IS"
                                 options:0 range:NSMakeRange(0, mstr.length)];
        expect([mstr isEqualToString:@"ThIS IS string A"],
               @"replaceOccurrencesOfString:withString:options:range: 就地改，且**返回换了几次**（这里两次）");
        expect([@"aaa" stringByReplacingOccurrencesOfString:@"a" withString:@"aa"]
               .length == 6, @"不可变版的替换是「一次全换」：aaa → aaaaaa");
        NSMutableString *ops = [NSMutableString stringWithString:@"Cocoa"];
        [ops insertString:@"iOS " atIndex:0];
        [ops appendString:@" / UIKit"];
        [ops deleteCharactersInRange:NSMakeRange(3, 1)];      // 删掉下标 3 那个空格
        line([NSString stringWithFormat:@"  增删之后 = %@", ops]);
        expect([ops isEqualToString:@"iOSCocoa / UIKit"],
               @"insertString:atIndex: / appendString: / deleteCharactersInRange: 三个动作都在**同一块内存**上改：下标是 UTF-16 码元，删错长度就是另一种串");
        NSMutableString *cap = [NSMutableString stringWithCapacity:1];
        [cap appendString:@"超过容量的串也照收"];
        expect(cap.length == 9,
               @"stringWithCapacity: 只是**预留**，不是上限：它不影响正确性，只影响重分配次数");
        NSString *deleted = [@"a,b,c" stringByReplacingOccurrencesOfString:@"," withString:@""];
        expect([deleted isEqualToString:@"abc"],
               @"替换成空串 = 删除：把分隔符换成空串确实能删掉它们，但正式做法是 deleteCharactersInRange:");

        // -------------------------------------------------- 6) NSNumber / NSValue / NSNull
        line(@"");
        line(@"== 6) NSNumber：装箱与 objCType 全表 ==");
        NSNumber *nChar = [NSNumber numberWithChar:'A'];
        NSNumber *nInt = @42, *nLong = @42L, *nLL = @42LL;
        NSNumber *nF = @3.5f, *nD = @3.5, *nB = @YES, *nU = @42u;
        line([NSString stringWithFormat:@"  objCType: char=%s int=%s long=%s longlong=%s float=%s double=%s bool=%s uint=%s",
              nChar.objCType, nInt.objCType, nLong.objCType, nLL.objCType,
              nF.objCType, nD.objCType, nB.objCType, nU.objCType]);
        expect(strcmp(nChar.objCType, "c") == 0 && strcmp(nInt.objCType, "i") == 0,
               @"numberWithChar 的编码是 \"c\"（signed char）、@42 是 \"i\"（int）：这就是 28 章 §3 的 @encode 字符");
        expect(strcmp(nLong.objCType, "q") == 0 && strcmp(nLL.objCType, "q") == 0,
               @"long 和 long long 在 64 位上**编码相同**（都是 \"q\"）：装箱之后再也分不出这两者");
        expect(strcmp(nB.objCType, "c") == 0 && strcmp(nChar.objCType, "c") == 0,
               @"BOOL 的编码也是 \"c\"：NSNumber 里 YES 和一个 char 是同一编码的不同值 —— objCType 分不出布尔，这就是为什么取布尔必须用 boolValue");
        expect(strcmp(nF.objCType, "f") == 0 && strcmp(nD.objCType, "d") == 0,
               @"@3.5f 是 \"f\"、@3.5 是 \"d\"：浮点字面量的默认类型（04 章 §数据类型（二））一路带进装箱结果");
        NSNumber *viaAlloc = [[NSNumber alloc] initWithInteger:42];
        expect([nInt isEqualToNumber:viaAlloc] && nInt != viaAlloc,
               @"isEqualToNumber: 按数值相等，两个却是不同对象：数值相等 ≠ 同一个对象（04 章 §运算符（三）的同一课）");
        expect([@42 isEqualToNumber:@42.0] && [@(42.0) compare:@42] == NSOrderedSame,
               @"@42 和 @42.0 数值相等、compare: 也判平：NSNumber 的比较看**值**不看编码");
        expect([nD intValue] == 3 && [nInt doubleValue] == 42.0 && [nB boolValue] == YES,
               @"取值随你挑，但**转换会砍**：@3.5 的 intValue 是 3（向零截断，不是四舍五入）、@42 的 doubleValue 是 42.0、@YES 的 boolValue 是真：装箱类型不是取值的门槛，也不替你保住精度");
        expect([nInt stringValue] != nil && [nD stringValue].length > 0,
               @"stringValue 给的是「按格式渲染后」的串：拼日志方便，但别拿它当持久化格式");
        expect([@"12abc" intValue] == 12 && [@"abc" intValue] == 0 && [@"  7" intValue] == 7 &&
               [@"-3.9" intValue] == -3,
               @"NSString 的 intValue 是「从头读能读的部分」：读到非数字就停，读不出就 0 —— 它不报错，所以脏数据会安静变成 0");
        expect([@"0x10" intValue] == 0,
               @"intValue 不认十六进制：@\"0x10\" 是 0，不是 16 —— 要按进制解析得用 NSNumberFormatter 或 strtol（28 章）");
        NSValue *rangeValue = [NSValue valueWithRange:NSMakeRange(3, 7)];
        expect(rangeValue.rangeValue.length == 7, @"NSValue 能装 NSRange（结构体不是对象，装箱才能进集合）");
        NSValue *pointValue = [NSValue valueWithCGPoint:CGPointMake(1.5, 2.5)];
        expect(pointValue.CGPointValue.x == 1.5,
               @"valueWithCGPoint: 这类**几何便利方法不在 Foundation 里，在 UIKit**：只 import Foundation 编译期就没有这个方法（探针记录见 §16）");
        struct { int a; double b; } pair = {7, 1.25}, outPair;
        NSValue *manual = [NSValue valueWithBytes:&pair objCType:"{FDPair=id}"];
        [manual getValue:&outPair];
        expect(outPair.a == 7 && outPair.b == 1.25,
               @"通用做法是 valueWithBytes:objCType: + getValue:：整块 memcpy，尺寸由你保证 —— 装错了不会报错，只会读出垃圾");
        NSArray *withHole = @[@"a", [NSNull null], @"c"];
        expect(withHole.count == 3 && withHole[1] == [NSNull null],
               @"集合里的「空位」是 NSNull 单例，可以比指针：它不是 nil，是个真实存在的对象（04 章 §数据类型（三））");

        // -------------------------------------------------- 7) NSArray 的创建与取值
        line(@"");
        line(@"== 7) NSArray：创建、取值与不可变语义 ==");
        NSArray<NSString *> *langs = @[@"Swift", @"Objective-C", @"C"];
        NSArray *byObjects = [[NSArray alloc] initWithObjects:@"Swift", @"Objective-C", @"C", nil];
        expect([langs isEqualToArray:byObjects],
               @"字面量与 initWithObjects:…nil 造的数组内容相等：末尾那个 nil 只是**结束哨兵**，不占位置");
        expect(langs.count == 3 && [langs[1] isEqualToString:@"Objective-C"],
               @"下标 langs[i] 就是 objectAtIndexedSubscript:，越界是异常不是 nil（§10 实测）");
        expect([@[] firstObject] == nil && [@[] lastObject] == nil && langs.firstObject != nil,
               @"空数组的 firstObject/lastObject 是 nil（**不崩**）：这是判空的捷径，但拿 nil 当「没有」时要小心它也可能是「有个 nil 元素」");
        NSMutableArray *grown = [NSMutableArray arrayWithCapacity:2];
        [grown addObject:@"Swift"];
        [grown addObjectsFromArray:@[@"Objective-C", @"C"]];
        [grown insertObject:@"Rust" atIndex:0];
        [grown removeObject:@"C"];
        [grown removeObjectAtIndex:0];
        [grown replaceObjectAtIndex:0 withObject:@"C++"];
        expect(grown.count == 2 && [grown[0] isEqualToString:@"C++"],
               @"addObject:/addObjectsFromArray:/insertObject:atIndex:/removeObject:/removeObjectAtIndex:/replaceObjectAtIndex:withObject: —— 可变数组的六个动作，书名全是 add/remove/replace/insert 开头");
        NSArray *added = [langs arrayByAddingObject:@"C++"];
        expect(langs.count == 3 && added.count == 4,
               @"arrayByAddingObject: 是**不可变版**的「追加」：返回新数组，原件还是 3 个");
        expect([langs indexOfObject:@"Rust"] == NSNotFound,
               @"indexOfObject: 找不到给 NSNotFound（= NSUIntegerMax），不是 -1：判它只能 == NSNotFound");
        NSString *built1 = [[NSString alloc] initWithFormat:@"%@%@", @"Objective", @"-C"];
        NSString *built2 = [[NSString alloc] initWithFormat:@"%@%@", @"Objective", @"-C"];
        expect((built1 == built2) == 0 && [langs containsObject:built2] &&
               [langs indexOfObjectIdenticalTo:built2] == NSNotFound,
               @"containsObject: 走 isEqual:（找到），indexOfObjectIdenticalTo: 走指针（找不到）：**两个方法的差别就是内容相等与身份相等的差别**");
        NSArray *slice = [langs subarrayWithRange:NSMakeRange(1, 2)];
        NSIndexSet *pick = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
        expect(slice.count == 2 && [[langs objectsAtIndexes:pick] isEqualToArray:slice],
               @"subarrayWithRange: 与 objectsAtIndexes: 是一对：前者给连续区间，后者给任意下标集合（NSIndexSet）");
        id counted[3];
        counted[0] = @"a"; counted[1] = nil; counted[2] = @"c";
        @try {
            NSArray *madeNil = [NSArray arrayWithObjects:counted count:3];
            expect(madeNil.count == 3,
                   [NSString stringWithFormat:@"arrayWithObjects:count: 允许 nil 元素（实测 count=%lu）",
                    (unsigned long)madeNil.count]);
        } @catch (NSException *e) {
            expect([e.name isEqualToString:@"NSInvalidArgumentException"] &&
                   [e.reason hasPrefix:@"*** -[__NSPlaceholderArray initWithObjects:count:]: attempt to insert nil"],
                   @"arrayWithObjects:count: **不收 nil**（数着 count 个槽读，读到 nil 就抛）：字面量 @[] 走的正是这条路，所以 @[@\"a\", nil] 里那个洞必须拿 NSNull 填（异常原文见下面 §10）");
        }

        // -------------------------------------------------- 8) 遍历家族
        line(@"");
        line(@"== 8) 遍历家族：同一个数组的五种走法 ==");
        NSArray<NSNumber *> *nums = @[@1, @2, @3, @4];
        NSUInteger byIndex = 0;
        for (NSUInteger i = 0; i < nums.count; i++) { byIndex += [nums[i] unsignedIntegerValue]; }
        NSUInteger byForIn = 0;
        for (NSNumber *n in nums) { byForIn += n.unsignedIntegerValue; }
        NSUInteger byEnumerator = 0;
        for (NSNumber *n in nums.objectEnumerator) { byEnumerator += n.unsignedIntegerValue; }
        NSUInteger byReversed = 0;
        for (NSNumber *n in nums.reverseObjectEnumerator) { byReversed += n.unsignedIntegerValue; }
        expect(byIndex == 10 && byForIn == 10 && byEnumerator == 10 && byReversed == 10,
               @"索引 / for-in / objectEnumerator / reverseObjectEnumerator 四种走法加出同一个 10：NSEnumerator 只有 nextObject 和 allObjects 两个方法，for-in 就是它的语法糖（批次大小见 04 章 §控制语句（二））");
        NSMutableArray *order = [NSMutableArray array];
        for (NSNumber *n in nums.reverseObjectEnumerator) { [order addObject:n]; }
        expect([[order componentsJoinedByString:@","] isEqualToString:@"4,3,2,1"],
               @"reverseObjectEnumerator 是真逆序：想倒着拼串不用自己写反向循环");
        __block NSUInteger blockCalls = 0, blockSum = 0;
        [nums enumerateObjectsUsingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) {
            blockCalls += 1; blockSum += n.unsignedIntegerValue;
        }];
        expect(blockCalls == 4 && blockSum == 10,
               @"enumerateObjectsUsingBlock: 的 block 固定收三个参数：元素、下标、**stop 指针**（*stop = YES 才中止）");
        NSMutableArray *stopped = [NSMutableArray array];
        [nums enumerateObjectsUsingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) {
            [stopped addObject:n];
            if (idx >= 2) { *stop = YES; }
        }];
        expect(stopped.count == 3,
               @"下标到 2 就 *stop = YES：回调停在第 3 个元素（idx 是**进 block 就给的 0/1/2**，不是自己数的次数）");
        NSMutableArray *revOrder = [NSMutableArray array];
        [nums enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) {
            [revOrder addObject:[NSString stringWithFormat:@"%lu:%lu", (unsigned long)idx,
                                 n.unsignedIntegerValue]];
        }];
        expect([[revOrder componentsJoinedByString:@","] isEqualToString:@"3:4,2:3,1:2,0:1"],
               @"NSEnumerationReverse 倒着走，但**下标仍是原数组的下标**：倒序里 idx 也跟着倒数，这是最容易记错的一条");
        NSMutableArray *pickedUp = [NSMutableArray array];
        [nums enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]
                                options:0
                             usingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) {
            [pickedUp addObject:n];
        }];
        expect(pickedUp.count == 2 && [pickedUp[0] integerValue] == 2,
               @"enumerateObjectsAtIndexes:options:usingBlock: 只跑指定的下标集合：中间那一段不用自己判区间");
        gHelloCount = 0;
        NSArray<MXGreeter *> *greeters = @[ [[MXGreeter alloc] initWithName:@"a"],
                                            [[MXGreeter alloc] initWithName:@"b"],
                                            [[MXGreeter alloc] initWithName:@"c"] ];
        [greeters makeObjectsPerformSelector:@selector(sayHello)];
        expect(gHelloCount == 3,
               @"makeObjectsPerformSelector: 给每个元素发同一条消息：它把「遍历 + 调用」压成一行，代价是编译期不查这个方法存不存在");
        expect([[greeters valueForKey:@"name"] count] == 3,
               @"NSArray 的 valueForKey: 有**广播**语义：对每个元素取 name，返回一个数组 —— 这是 KVC 集合操作的第一半");
        id sumValue = [@[@1, @2, @3] valueForKeyPath:@"@sum.self"];
        id avgValue = [@[@1, @2, @3] valueForKeyPath:@"@avg.self"];
        id maxValue = [@[@1, @2, @3] valueForKeyPath:@"@max.self"];
        expect([sumValue integerValue] == 6 && [avgValue doubleValue] == 2.0 &&
               [maxValue integerValue] == 3,
               [NSString stringWithFormat:@"集合运算符（@sum/@avg/@min/@max）必须走 **valueForKeyPath:**（不是 valueForKey:，后者会抛 NSUnknownKeyException）：@sum.self 得 %@（类名 %@，注意是 NSDecimalNumber 不是 NSNumber）、@avg 得 %@、@max 还是普通 %@",
                sumValue, MXCls(sumValue), avgValue, maxValue]);
        expect([[greeters valueForKey:@"@count"] integerValue] == 3,
               @"@count 是唯一在 valueForKey: 下也能用的运算符（28 章 §3 的 KVC 键名规则在这里生效）");

        // -------------------------------------------------- 9) 排序家族
        line(@"");
        line(@"== 9) 排序家族：selector / 函数 / 代码块 / 描述符 ==");
        NSArray *shuffled = @[@"b", @"c", @"a"];
        expect([[[shuffled sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","]
                isEqualToString:@"a,b,c"],
               @"sortedArrayUsingSelector: 让元素**自己**比（元素必须实现这个方法）：NSString 有 compare:，所以能这么排");
        expect([[[shuffled sortedArrayUsingFunction:MXCompareString context:NULL] componentsJoinedByString:@","]
                isEqualToString:@"a,b,c"],
               @"sortedArrayUsingFunction:context: 收一个 C 函数指针：三个参数（两个对象 + 一个 void* 上下文），返回三个 NSOrdered* 之一");
        expect([[[shuffled sortedArrayUsingComparator:^NSComparisonResult(NSString *x, NSString *y) {
                    return [y compare:x];
                }] componentsJoinedByString:@","] isEqualToString:@"c,b,a"],
               @"sortedArrayUsingComparator: 就是 block 版比较器，反过来比就倒序 —— 后两种本质是一回事，只是 C 函数在 ARC 下要自己管上下文");
        NSMutableArray *inPlace = [shuffled mutableCopy];
        [inPlace sortUsingSelector:@selector(compare:)];
        expect([[inPlace componentsJoinedByString:@","] isEqualToString:@"a,b,c"],
               @"sortUsingSelector:/sortUsingComparator: 是**可变数组就地排**（没有返回新数组的 sorted… 版本）：书上的命名对称在这里");
        NSArray *byLength = [@[@"ccc", @"a", @"bb"] sortedArrayUsingComparator:^NSComparisonResult(NSString *x, NSString *y) {
            return x.length == y.length ? NSOrderedSame : (x.length < y.length ? NSOrderedAscending : NSOrderedDescending);
        }];
        line([NSString stringWithFormat:@"  按长度排 = %@", [byLength componentsJoinedByString:@","]]);
        expect([[byLength componentsJoinedByString:@","] isEqualToString:@"a,bb,ccc"],
               @"比较器随你定规则（这里按长度，完全不看字母序）：**元素本身可不可比都无所谓**，只要规则说得出 -1/0/1");
        NSArray<MXUser *> *users = @[ [[MXUser alloc] initWithName:@"Carol" pass:@"1"],
                                      [[MXUser alloc] initWithName:@"alice" pass:@"2"] ];
        NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES
                                                             selector:@selector(caseInsensitiveCompare:)];
        NSArray<NSString *> *userNames = [[users sortedArrayUsingDescriptors:@[sd]] valueForKey:@"name"];
        line([NSString stringWithFormat:@"  描述符排序 = %@", [userNames componentsJoinedByString:@","]]);
        expect([userNames[0] isEqualToString:@"alice"],
               @"sortedArrayUsingDescriptors: 按 **keypath** 排（内部就是 KVC + 指定 selector）：caseInsensitiveCompare: 让 alice 排在 Carol 前面，而 compare: 会把大写 C 排前面（ASCII 序）。表格视图/集合视图的多字段排序靠它，ascending:NO 就是倒序");
        NSArray<NSString *> *userNamesByCode = [[users sortedArrayUsingDescriptors:
                                                @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES
                                                                    selector:@selector(compare:)]]] valueForKey:@"name"];
        expect([userNamesByCode[0] isEqualToString:@"Carol"],
               @"同一个数组换 selector 就换结果：compare: 排出来 Carol 在前（大写码位 67 < 小写 97）—— 用户看到的「字母序」几乎总是需要 caseInsensitiveCompare:");
        expect([[[shuffled sortedArrayUsingComparator:^NSComparisonResult(NSString *x, NSString *y) {
                    return [x compare:y];
                }] sortedArrayUsingComparator:^NSComparisonResult(NSString *x, NSString *y) {
                    return [x compare:y];
                }] count] == 3,
               @"排好的数组还能再排一次，Foundation 不保证「稳定排序」：**同键元素**的相对次序别依赖（这一条只能记，量不出来 —— 相同键的顺序要稳，就自己在比较器里加下标兜底）");

        // -------------------------------------------------- 10) 多维数组与集合异常
        line(@"");
        line(@"== 10) 多维数组，以及集合的三种异常 ==");
        NSArray<NSArray<NSString *> *> *grid = @[ @[@"(0,0)", @"(0,1)", @"(0,2)"],
                                                  @[@"(1,0)", @"(1,1)", @"(1,2)"],
                                                  @[@"(2,0)", @"(2,1)", @"(2,2)"] ];
        NSUInteger cells = 0;
        for (NSArray<NSString *> *row in grid) {
            for (NSString *cell in row) { (void)cell; cells += 1; }
        }
        expect(cells == 9 && [grid[1][2] isEqualToString:@"(1,2)"],
               @"数组的数组 = 二维：grid[i][j] 就是两层 objectAtIndexedSubscript:；三维同理，只是每层类型换成 NSArray");
        NSMutableArray *students = [NSMutableArray array];
        for (NSArray *one in @[@[@"刘东海", @"26 岁"], @[@"沐浴神", @"24 岁"]]) {
            [students addObject:[one mutableCopy]];
        }
        expect([[students[1][1] stringByAppendingString:@"!"] containsString:@"24 岁!"],
               @"NSMutableArray 装 NSMutableArray = 书上的「学生表」写法：每行还能各自增删，代价是**没有任何类型保护**");
        @try {
            id oob = langs[5];
            expect(oob != nil, @"越界取到了东西（不应该发生）");
        } @catch (NSException *e) {
            line([NSString stringWithFormat:@"  越界：%@ —— %@", e.name, e.reason]);
            expect([e.name isEqualToString:@"NSRangeException"] &&
                   [e.reason containsString:@"beyond bounds"],
                   @"下标越界抛 NSRangeException，**不是返回 nil**：reason 里带 [0 .. 2] 这种合法区间（这条比 04 章的 nil 消息更危险，因为它会崩）");
        }
        @try {
            NSMutableArray *selfMutation = [@[ @1, @2, @3 ] mutableCopy];
            for (id x in selfMutation) { [selfMutation removeObject:x]; }
            expect(NO, @"遍历中删元素居然没抛（不应该发生）");
        } @catch (NSException *e) {
            expect([e.name isEqualToString:@"NSGenericException"] &&
                   [e.reason containsString:@"mutated while being enumerated"],
                   @"for-in 遍历途中改集合抛 NSGenericException：reason 里带那个集合的地址，所以这里只断言、不打印（要删就倒序删或先收集再删）");
        }
        @try {
            NSMutableArray *nilPush = [NSMutableArray array];
            id nothing = nil;
            [nilPush addObject:nothing];
            expect(NO, @"addObject:nil 居然没抛（不应该发生）");
        } @catch (NSException *e) {
            line([NSString stringWithFormat:@"  塞 nil：%@ —— %@", e.name, e.reason]);
            expect([e.name isEqualToString:@"NSInvalidArgumentException"] &&
                   [e.reason containsString:@"object cannot be nil"],
                   @"往集合里塞 nil 抛 NSInvalidArgumentException（reason 原文 object cannot be nil）：04 章说「集合不收 nil」，崩的现场就在这儿。注意它和 §7 那条 initWithObjects: 的 reason（attempt to insert nil object from objects[1]）不是同一句话 —— 同一个约束，两个入口各有各的措辞");
        }

        // -------------------------------------------------- 11) NSDictionary
        line(@"");
        line(@"== 11) NSDictionary：键值对与三个字典专属坑 ==");
        NSDictionary *byPairs = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @36, @"Ada", @45, @"Grace", nil];
        expect([byPairs[@"Ada"] intValue] == 36 && [byPairs[@"Grace"] intValue] == 45,
               @"dictionaryWithObjectsAndKeys: 是**先值后键**，和字面量 @{key: value} 的顺序正好相反：这是 OC 最经典的笔误（编译器一个字都不提醒）");
        NSDictionary<NSString *, NSNumber *> *ages = @{@"Ada": @36, @"Grace": @45, @"Alan": @41};
        expect(ages.count == 3 && [ages[@"Grace"] intValue] == 45, @"字面量字典：下标取值");
        expect(ages[@"Nobody"] == nil, @"不存在的 key 取到 nil（**不是异常**）：和数组越界正好相反");
        expect([ages objectForKey:@"Grace"] == ages[@"Grace"],
               @"obj[key] 就是 objectForKeyedSubscript:，和 objectForKey: 同一个方法");
        NSDictionary *untypedAges = ages;
        expect(untypedAges[@1] == nil,
               @"拿错类型的 key（这里用 NSNumber 查字符串键）只是查不到，不会崩：字典不检查 key 的类型，只检查 hash/isEqual:");
        NSArray<NSString *> *sortedKeys = [ages.allKeys sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray<NSString *> *pairs = [NSMutableArray array];
        for (NSString *k in sortedKeys) { [pairs addObject:[NSString stringWithFormat:@"%@=%@", k, ages[k]]]; }
        line([NSString stringWithFormat:@"  ages = %@", [pairs componentsJoinedByString:@" "]]);
        expect([sortedKeys[0] isEqualToString:@"Ada"] && pairs.count == 3,
               @"allKeys / allValues / for-in 的顺序**未定义**：想要稳定输出必须自己排序（本教程反复出现的那条规则）");
        NSDictionary *fromArrays = [NSDictionary dictionaryWithObjects:@[@1, @2] forKeys:@[@"a", @"b"]];
        expect([fromArrays[@"b"] intValue] == 2,
               @"dictionaryWithObjects:forKeys: 两个平行数组（**对象在前、键在后**）：批量造字典比一个个 setObject: 快，也更不容易写反");
        @try {
            NSDictionary *mismatch = [NSDictionary dictionaryWithObjects:@[@"a"] forKeys:@[@"k1", @"k2"]];
            expect(mismatch == nil, [NSString stringWithFormat:@"数量不匹配居然返回了（count=%lu）", (unsigned long)mismatch.count]);
        } @catch (NSException *e) {
            line([NSString stringWithFormat:@"  数量不匹配：%@ —— %@", e.name, e.reason]);
            expect([e.name isEqualToString:@"NSInvalidArgumentException"] &&
                   [e.reason containsString:@"differs from count of keys"],
                   @"objects/forKeys 数量不等抛异常，reason 把两个数都写出来了：这是平行数组写反之后的现场");
        }
        @try {
            NSMutableDictionary *nilKey = [NSMutableDictionary dictionary];
            id nothing = nil;
            nilKey[nothing] = @"v";
            expect(NO, @"nil 当 key 居然没抛（不应该发生）");
        } @catch (NSException *e) {
            expect([e.name isEqualToString:@"NSInvalidArgumentException"] &&
                   [e.reason containsString:@"key cannot be nil"],
                   @"nil 不能当 key（value 也不能是 nil，要放空位用 NSNull）：reason 短且稳定，可以直接断言");
        }
        NSMutableDictionary<NSString *, id> *settings = [@{@"theme": @"dark"} mutableCopy];
        settings[@"theme"] = @"light";
        settings[@"autoSave"] = @YES;
        [settings removeObjectForKey:@"notThere"];
        expect(settings.count == 2 && [settings[@"theme"] isEqualToString:@"light"],
               @"可变字典：同一个下标语法既能改也能加；removeObjectForKey: 对不存在的键**静默无副作用**");
        settings[@"temp"] = @"now";
        expect(settings.count == 3 && settings[@"temp"] != nil, @"新键插进去");
        settings[@"temp"] = nil;      // 赋 nil = 删除，编译器不拦（探针里 setObject:forKey: 那条反而有 -Wnonnull，见 §16）
        expect(settings[@"temp"] == nil && settings.count == 2,
               @"给已有键赋 nil 是**删除**（setObject:forKeyedSubscript: 的 nil 分支就是 removeObjectForKey:）：想放个「空值」得用 NSNull，不然这条赋值悄悄删了整条记录");
        __block NSUInteger enumVisits = 0;
        [ages enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSNumber *v, BOOL *stop) {
            enumVisits += 1;
        }];
        expect(enumVisits == 3, @"enumerateKeysAndObjectsUsingBlock: 一次拿到键和值：比 keyEnumerator + objectForKey: 少一半消息");
        NSSet<NSString *> *bigKeys = [ages keysOfEntriesPassingTest:^BOOL(NSString *k, NSNumber *v, BOOL *stop) {
            return v.integerValue > 40;
        }];
        expect(bigKeys.count == 2 && [bigKeys isKindOfClass:[NSSet class]],
               [NSString stringWithFormat:@"keysOfEntriesPassingTest: 返回的是 **%@**（不是数组）：过滤出来的是集合，要稳定顺序还得自己 sortedArrayUsingSelector:", MXCls(bigKeys)]);
        NSArray<NSString *> *byValue = [ages keysSortedByValueUsingSelector:@selector(compare:)];
        expect([byValue[0] isEqualToString:@"Ada"],
               @"keysSortedByValueUsingSelector: **按值排、返回键**：图例、排行榜全靠它（还有 Comparator 版）");
        NSArray<NSString *> *byNameLength = [ages keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *v1, NSNumber *v2) {
            NSUInteger l1 = [v1 stringValue].length, l2 = [v2 stringValue].length;
            return l1 == l2 ? NSOrderedSame : (l1 < l2 ? NSOrderedAscending : NSOrderedDescending);
        }];
        expect(byNameLength.count == 3, @"键排序可以按任意规则（这里按值的字符串长度）：书里「值越长算越大」的那个例子");
        NSMutableString *mutableKey = [NSMutableString stringWithString:@"k"];
        NSMutableDictionary *copiedKey = [NSMutableDictionary dictionary];
        copiedKey[mutableKey] = @"v";
        NSString *storedKey = copiedKey.allKeys.firstObject;
        expect(storedKey != mutableKey && [storedKey isEqualToString:@"k"],
               @"字典**把 key 拷贝一份**再存：存进去的是那个串的不可变副本（类名 NSTaggedPointerString，见 04 章），不是手里这个可变对象 —— 所以「可变对象当 key 一定失效」这句书上常见说法其实是错的");
        [mutableKey appendString:@"X"];
        expect([copiedKey[@"k"] isEqualToString:@"v"] && copiedKey[@"kX"] == nil,
               @"改原始那个可变串，查表一切照旧（因为存的是副本）：**真正的坑在浅拷贝** —— key 换成 NSMutableArray，里面再装一个 NSMutableString，改里面的对象会改变外层副本的 hash，查不查得到就成运气了（探针记录见 §16）");
        expect([NSMutableString stringWithString:@"k"] != nil,
               @"key 必须能响应 NSCopying：塞一个不遵守协议的进去，运行时就是一句 doesNotConformToSelector @\"copyWithZone:\"（这条留在 §16 的探针记录里，这里只把规则写全）");

        // -------------------------------------------------- 12) NSSet / NSCountedSet / NSOrderedSet
        line(@"");
        line(@"== 12) 集合族：NSSet / NSCountedSet / NSOrderedSet ==");
        NSSet<NSString *> *tags = [NSSet setWithObjects:@"iOS", @"UIKit", @"iOS", nil];
        expect(tags.count == 2, @"NSSet 自动去重：两个 iOS 只留一个 —— 去重靠 hash + isEqual:，两个都要对");
        expect([tags containsObject:@"iOS"] && [[tags setByAddingObject:@"SF"] count] == 3 && tags.count == 2,
               @"setByAddingObject: 返回**新集合**（不可变版的老规矩），原件还是 2 个");
        MXUser *u1 = [[MXUser alloc] initWithName:@"a" pass:@"x"];
        MXUser *u2 = [[MXUser alloc] initWithName:@"a" pass:@"x"];
        expect([u1 isEqual:u2] && u1.hash != u2.hash,
               @"MXUser 重写了 isEqual: 但**没重写 hash**：两个对象内容相等，hash 却还是各一个（NSObject 默认按身份给）");
        expect([NSSet setWithObjects:u1, u2, nil].count == 2,
               @"于是集合里留下了两个「相等」的元素：**isEqual: 说相等但 hash 不同 = 去重失效**，这是自定义对象进 NSSet/字典 key 的头号 bug");
        MXHashedUser *h1 = [[MXHashedUser alloc] initWithName:@"a" pass:@"x"];
        MXHashedUser *h2 = [[MXHashedUser alloc] initWithName:@"a" pass:@"x"];
        expect(h1.hash == h2.hash && [NSSet setWithObjects:h1, h2, nil].count == 1,
               @"补上 hash（和 isEqual: 用同一批字段）之后，同一个内容只留一个：契约是「isEqual: 相等 ⇒ hash 必须相等」，反过来不要求");
        expect([NSSet setWithArray:@[@"x", @"x", @"y"]].count == 2 &&
               [[NSSet setWithArray:@[@"x", @"x"]] anyObject] != nil,
               @"setWithArray: 是「数组去重」的标准写法；anyObject 保证返回**某个**元素，但不保证哪个、也不保证随机（所以只能判空、不能打值）");
        NSSet *small = [NSSet setWithObjects:@"iOS", nil];
        NSSet *bigSet = [NSSet setWithObjects:@"iOS", @"UIKit", nil];
        expect([small isSubsetOfSet:bigSet] && [bigSet intersectsSet:small] &&
               ![bigSet isEqualToSet:small],
               @"三个集合关系：isSubsetOfSet: / intersectsSet: / isEqualToSet: 都是按 isEqual: 比元素");
        expect([[small setByAddingObjectsFromSet:bigSet] count] == 2 &&
               [[small setByAddingObjectsFromArray:@[@"a"]] count] == 2,
               @"setByAddingObjectsFromSet: / …FromArray: 也都是返回新集合：集合的并集在不可变版只能这么算");
        NSSet *filtered = [bigSet objectsPassingTest:^BOOL(NSString *s, BOOL *stop) {
            return s.length == 3;
        }];
        expect(filtered.count == 1, @"objectsPassingTest: 过滤出新集合（还有 objectsWithOptions:passingTest: 可以倒着走）");
        NSMutableSet *ms = [NSMutableSet setWithObjects:@"iOS", @"UIKit", nil];
        NSMutableSet *other = [NSMutableSet setWithObjects:@"UIKit", @"SwiftUI", nil];
        NSMutableSet *unionSet = [ms mutableCopy]; [unionSet unionSet:other];
        NSMutableSet *minusSet = [ms mutableCopy]; [minusSet minusSet:other];
        NSMutableSet *interSet = [ms mutableCopy]; [interSet intersectSet:other];
        expect(unionSet.count == 3 && minusSet.count == 1 && interSet.count == 1,
               @"unionSet: / minusSet: / intersectSet: 就地改：三个集合运算都是「把自己变成结果」，没有返回值");
        NSMutableSet *removed = [ms mutableCopy];
        [removed removeObject:@"nobody"];
        expect(removed.count == 2, @"removeObject: 对不在集合里的元素同样静默无副作用（和字典的 removeObjectForKey: 一致）");
        NSCountedSet *counter = [NSCountedSet setWithArray:@[@"iOS", @"iOS", @"iOS", @"x"]];
        expect([counter countForObject:@"iOS"] == 3 && counter.count == 2,
               @"NSCountedSet 是「集合 + 每个元素的次数」：count 数的是**不同元素**的个数，不是总次数");
        [counter removeObject:@"iOS"];
        expect([counter countForObject:@"iOS"] == 2 && counter.count == 2 && [counter containsObject:@"iOS"],
               @"removeObject: 只把次数减 1，元素还在：书上「删除一次后次数变 2」这条是真的，容易记成「删了就没了」");
        [counter removeObject:@"iOS"]; [counter removeObject:@"iOS"];
        expect([counter countForObject:@"iOS"] == 0 && counter.count == 1 &&
               ![counter containsObject:@"iOS"],
               @"减到 0 才真的离开集合：三次加、三次减之后只剩 x —— 计数语义和引用计数（04 章 ARC）没关系，只是同一套「加减到零」的直觉");
        NSOrderedSet *ordered = [NSOrderedSet orderedSetWithObjects:@"x", @"y", @"x", nil];
        expect(ordered.count == 2 && [ordered[1] isEqualToString:@"y"] &&
               [ordered indexOfObject:@"y"] == 1,
               @"NSOrderedSet = 集合的去重 + 数组的下标：三个元素里那个重复的 x 被吃掉，剩下 x、y 还能按 index 取");
        NSMutableOrderedSet *mos = [ordered mutableCopy];
        [mos removeObjectAtIndex:0];
        expect(mos.count == 1 && [mos[0] isEqualToString:@"y"],
               @"可变版把 NSArray/NSMutableSet 的动作合在一起：insert/remove/replace/exchange 都有，还能 unionSet: 之类做集合运算");

        // -------------------------------------------------- 13) NSData 与文件/plist
        line(@"");
        line(@"== 13) NSData：字节、base64 与落盘 ==");
        NSData *data = [@"Cocoa" dataUsingEncoding:NSUTF8StringEncoding];
        expect(data.length == 5, @"NSData 按**字节**计长度：Cocoa 是 5 个字节");
        NSString *b64 = [data base64EncodedStringWithOptions:0];
        expect(b64 != nil &&
               [[[NSData alloc] initWithBase64EncodedString:b64 options:0] isEqualToData:data],
               @"base64 往返一致（写用 base64EncodedStringWithOptions:，读用 initWithBase64EncodedString:options:）：这是把二进制塞进 JSON / URL / 邮件头的唯一常用手段");
        expect([[NSData alloc] initWithBase64EncodedString:@"!!!不是 base64!!!" options:0] == nil,
               @"解不出来的 base64 返回 **nil**（不崩、不返回半成品）：和 §3 的非法 UTF-8 同一个脾气");
        NSMutableData *growing = [NSMutableData data];
        [growing appendData:data];
        [growing appendBytes:"!" length:1];
        expect(growing.length == 6 && memcmp(growing.bytes, "Cocoa!", 6) == 0,
               @"NSMutableData：appendData: 追加对象、appendBytes:length: 追加裸字节；.bytes 是 const void*，要 memcmp 或强转才能看内容");
        NSData *tail = [data subdataWithRange:NSMakeRange(2, 3)];
        expect([[NSString alloc] initWithData:tail encoding:NSUTF8StringEncoding].length == 3,
               @"subdataWithRange: 切的是**字节**区间：切在多字节字符中间就会得到解不开的半截（和 §3 的码元陷阱同源）");
        NSString *tmpDir = NSTemporaryDirectory();
        NSString *filePath = [tmpDir stringByAppendingPathComponent:@"iosdev-05.txt"];
        NSError *fileError = nil;
        BOOL wrote = [@"中文\nsecond" writeToFile:filePath atomically:YES
                                         encoding:NSUTF8StringEncoding error:&fileError];
        NSString *readBack = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&fileError];
        expect(wrote && [readBack isEqualToString:@"中文\nsecond"],
               @"字符串直接 writeToFile:atomically:encoding:error: 落盘、stringWithContentsOfFile: 读回：往返无损（路径不外打）");
        expect([readBack componentsSeparatedByString:@"\n"].count == 2,
               @"读回来还能按行切：这是最土的配置文件读写，第 18 章展开");
        NSError *missingError = nil;
        NSString *missing = [NSString stringWithContentsOfFile:[tmpDir stringByAppendingPathComponent:@"iosdev-05-none.txt"]
                                                     encoding:NSUTF8StringEncoding error:&missingError];
        expect(missing == nil && missingError != nil &&
               [missingError.domain isEqualToString:NSCocoaErrorDomain] && missingError.code == 260,
               [NSString stringWithFormat:@"文件不存在：返回 nil 并填 error（domain=%@ code=%ld = NSFileReadNoSuchFileError）—— **不抛异常**，所以每一条都得判返回值", missingError.domain, (long)missingError.code]);
        [NSFileManager.defaultManager removeItemAtPath:filePath error:NULL];
        NSDictionary *config = @{@"on": @YES, @"n": @3, @"s": @"x", @"list": @[@1, @2]};
        NSString *plistPath = [tmpDir stringByAppendingPathComponent:@"iosdev-05.plist"];
        BOOL plistWritten = [config writeToFile:plistPath atomically:YES];
        NSDictionary *plistBack = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        expect(plistWritten && [plistBack isEqual:config],
               @"字典/数组可以直接 writeToFile: 成 plist（默认二进制），dictionaryWithContentsOfFile: 读回来整块相等：这就是第 18 章「设置文件」的原型");
        NSData *xmlPlist = [NSPropertyListSerialization dataWithPropertyList:config
                        format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
        NSString *xmlText = [[NSString alloc] initWithData:xmlPlist encoding:NSUTF8StringEncoding];
        expect([xmlText containsString:@"<dict>"] && [xmlText containsString:@"<true/>"] &&
               [xmlText containsString:@"<key>on</key>"],
               @"NSPropertyListSerialization 能指定格式：XML 版就是书上贴出来的那个 <dict>/<key>/<true/> 形状（人可读、能进版本库）");
        [NSFileManager.defaultManager removeItemAtPath:plistPath error:NULL];
        NSDictionary *notAPropertyList = @{@"obj": [MXGreeter new]};
        expect([NSPropertyListSerialization propertyList:config
                                        isValidForFormat:NSPropertyListXMLFormat_v1_0] &&
               ![NSPropertyListSerialization propertyList:notAPropertyList
                                         isValidForFormat:NSPropertyListXMLFormat_v1_0],
               @"能查「这个图能不能写成 plist」：propertyList:isValidForFormat: —— 只有字符串/数字/日期/数据/数组/字典（以及它们套它们）算合法，塞一个自定义对象进去就是 NO");
        expect(![notAPropertyList writeToFile:[tmpDir stringByAppendingPathComponent:@"iosdev-05-bad.plist"]
                                 atomically:YES],
               @"写不出去时 writeToFile:atomically: 返回 **NO**（不抛异常、也不打印任何东西）：不判返回值的话，你会以为文件写好了");
        NSError *plistError = nil;
        NSData *xmlFail = [NSPropertyListSerialization dataWithPropertyList:notAPropertyList
                                                                    format:NSPropertyListXMLFormat_v1_0
                                                                   options:0 error:&plistError];
        expect(xmlFail == nil && plistError != nil &&
               [plistError.domain isEqualToString:NSCocoaErrorDomain] && plistError.code == 3851,
               [NSString stringWithFormat:@"序列化版同样返回 nil + error（domain=%@ code=%ld）：错误码 3851 在头文件里没有名字，只能靠 code 认", plistError.domain, (long)plistError.code]);

        // -------------------------------------------------- 14) 日期三件套
        line(@"");
        line(@"== 14) NSDate / NSCalendar / NSDateFormatter ==");
        NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:1700000000];
        expect(epoch.timeIntervalSince1970 == 1700000000,
               @"NSDate 就是一个时间点：给个 1970 纪元的秒数就能造出来（内部其实按 2001 参考日期存，见下面 description）");
        expect(fabs([epoch timeIntervalSinceReferenceDate] - (1700000000 - 978307200)) < 1e-6,
               @"timeIntervalSinceReferenceDate 是相对 2001-01-01 的秒数：两套纪元差 978307200 秒，写死它不如直接用 1970 那套 API");
        NSDate *later = [epoch dateByAddingTimeInterval:3600];
        expect([epoch compare:later] == NSOrderedAscending &&
               [[epoch earlierDate:later] isEqualToDate:epoch] &&
               [[later laterDate:epoch] isEqualToDate:later],
               @"比较用 compare:/earlierDate:/laterDate:/isEqualToDate:：后两个返回的是**参数里的那个对象**，不是布尔");
        line([NSString stringWithFormat:@"  description = %@（hasPrefix 2023-11-14 22:13 = %d）",
              epoch, [epoch.description hasPrefix:@"2023-11-14 22:13"]]);
        expect([epoch.description hasPrefix:@"2023-11-14 22:13"],
               @"NSDate 的 description **永远是 UTC**（尾巴上的 +0000 就是它）：和设备时区无关，这是「NSDate 不含时区」最直观的证据");
        NSCalendar *utc = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        utc.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        NSDateComponents *c = [utc components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                            | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday
                                     fromDate:epoch];
        line([NSString stringWithFormat:@"  UTC 分解 = %04ld-%02ld-%02ld %02ld:%02ld weekday=%ld",
              (long)c.year, (long)c.month, (long)c.day, (long)c.hour, (long)c.minute, (long)c.weekday]);
        expect(c.year == 2023 && c.month == 11 && c.day == 14 && c.hour == 22 && c.minute == 13,
               @"同一个时间戳，UTC 下是 11 月 14 日 22:13：components 出来的年月日**取决于你给哪个日历哪个时区**");
        expect(c.weekday == 3,
               @"weekday 是 1..7 且 **1 = 星期日**（不是 0，也不是「1 = 星期一」）：2023-11-14 是周二，所以是 3 —— 这档事最常记错");
        NSCalendar *beijing = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        beijing.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
        NSDateComponents *cb = [beijing components:NSCalendarUnitDay | NSCalendarUnitHour fromDate:epoch];
        expect(cb.hour == 6 && cb.day == 15,
               @"东八区同一个戳跨到 15 号早上 6 点：**日历差一天不是 bug，是没指定时区**");
        NSDateComponents *back = [[NSDateComponents alloc] init];
        back.year = 2024; back.month = 1; back.day = 31; back.hour = 12;
        NSDate *jan31 = [utc dateFromComponents:back];
        expect([utc components:NSCalendarUnitDay fromDate:jan31].day == 31,
               @"dateFromComponents: 是 components:fromDate: 的反向：没指定的字段按 0 处理（时、分、秒全 0 就是当地零点）");
        NSDateComponents *plusMonth = [[NSDateComponents alloc] init];
        plusMonth.month = 1;
        NSDate *afterMonth = [utc dateByAddingComponents:plusMonth toDate:jan31 options:0];
        NSDateComponents *am = [utc components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                      fromDate:afterMonth];
        expect(am.month == 2 && am.day == 29,
               [NSString stringWithFormat:@"2024-01-31 加 1 个月 = %04ld-%02ld-%02ld：**夹紧**到 2 月最后一天（2024 是闰年，所以 29），不是滚到 3 月 2 日",
                (long)am.year, (long)am.month, (long)am.day]);
        NSDateComponents *plusDay = [[NSDateComponents alloc] init];
        plusDay.day = 1;
        NSDateComponents *nd = [utc components:NSCalendarUnitMonth | NSCalendarUnitDay
                                      fromDate:[utc dateByAddingComponents:plusDay toDate:jan31 options:0]];
        expect(nd.month == 2 && nd.day == 1,
               @"加 1 **天**就是 2 月 1 日：dateByAddingComponents: 走日历（会跨月、会尊重月末），dateByAddingTimeInterval: 走秒（不管这些）");
        NSDateComponents *dc2 = [[NSDateComponents alloc] init];
        dc2.year = 2024; dc2.month = 2; dc2.day = 15;
        NSDate *feb15 = [utc dateFromComponents:dc2];
        NSDateComponents *dc3 = [[NSDateComponents alloc] init];
        dc3.year = 2024; dc3.month = 3; dc3.day = 15;
        NSDate *mar15 = [utc dateFromComponents:dc3];
        NSDateComponents *dcNoon = [[NSDateComponents alloc] init];
        dcNoon.year = 2024; dcNoon.month = 1; dcNoon.day = 31; dcNoon.hour = 12;
        NSDate *jan31Noon = [utc dateFromComponents:dcNoon];
        NSDateComponents *gap = [utc components:NSCalendarUnitMonth | NSCalendarUnitDay
                                       fromDate:jan31 toDate:mar15 options:0];
        line([NSString stringWithFormat:@"  1/31 中午 → 3/15 零点：日历口径 %ld 个月 %ld 天 / 物理口径 %.1f 天",
              (long)gap.month, (long)gap.day, [mar15 timeIntervalSinceDate:jan31] / 86400.0]);
        expect(gap.month == 1 && gap.day == 14 &&
               [mar15 timeIntervalSinceDate:jan31] == 43.5 * 86400,
               @"jan31 是**中午 12 点**造的（上面 dateFromComponents: 那条），所以到 3/15 零点只有 43.5 天：日历口径给 1 个月 **14 天**，不足一天的那半天直接被丢掉 —— 时间差算「几天」之前先把两边对齐到零点，否则 43.5 和 44 会给你两个不同的答案");
        NSDateComponents *gapMid = [utc components:NSCalendarUnitMonth | NSCalendarUnitDay
                                        fromDate:jan31Noon toDate:mar15 options:0];
        NSDateComponents *dcMid = [[NSDateComponents alloc] init];
        dcMid.year = 2024; dcMid.month = 1; dcMid.day = 31;
        NSDate *jan31Mid = [utc dateFromComponents:dcMid];
        NSDateComponents *gapClean = [utc components:NSCalendarUnitMonth | NSCalendarUnitDay
                                           fromDate:jan31Mid toDate:mar15 options:0];
        expect(gapClean.month == 1 && gapClean.day == 15 && gapMid.month == 1 && gapMid.day == 14,
               [NSString stringWithFormat:@"同一对日期，起点是零点还是中午直接影响结果：零点起算给 %ld 个月 %ld 天，中午起算给 %ld 个月 %ld 天（**整月的判定是「加上去不能超过终点」**，1/31 加一整月要落到 2/29）",
                (long)gapClean.month, (long)gapClean.day, (long)gapMid.month, (long)gapMid.day]);
        NSDateComponents *gapFeb = [utc components:NSCalendarUnitMonth | NSCalendarUnitDay
                                         fromDate:jan31Mid toDate:feb15 options:0];
        expect(gapFeb.month == 0 && gapFeb.day == 15,
               @"1/31 → 2/15 算得出 **0 个月** 15 天（不是「差半个月」）：months 只数**完整的月**，凑不满一个月就是 0 —— 写「注册了 N 个月」这类文案时，用 month 单独取还是 month+day 一起看，差别就在这");
        NSDate *startOfWeek = nil;
        BOOL gotRange = [utc rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&startOfWeek
                                interval:NULL forDate:jan31];
        NSDateComponents *sw = [utc components:NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:startOfWeek];
        expect(gotRange && sw.day == 28 && sw.weekday == 1,
               [NSString stringWithFormat:@"rangeOfUnit:startDate:interval:forDate: 反推「这一周从哪天开始」：firstWeekday=%lu 时 1/31 那周从 1 月 %ld 号（星期%ld）起，算周报表头就靠它",
                (unsigned long)utc.firstWeekday, (long)sw.day, (long)sw.weekday]);
        NSRange daysInMonth = [utc rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:jan31];
        expect(daysInMonth.location == 1 && daysInMonth.length == 31,
               [NSString stringWithFormat:@"rangeOfUnit:inUnit:forDate: 量的是「一天在这个月里排第几到第几」：%lu..%lu —— 拿 length 就是该月天数，写日期选择器要用",
                (unsigned long)daysInMonth.location, (unsigned long)daysInMonth.length]);
        NSTimeZone *newYork = [NSTimeZone timeZoneWithName:@"America/New_York"];
        NSDate *summer = [NSDate dateWithTimeIntervalSince1970:1720000000];
        NSDate *winter = [NSDate dateWithTimeIntervalSince1970:1735000000];
        expect(newYork.secondsFromGMT == -5 * 3600 || newYork.secondsFromGMT == -4 * 3600,
               [NSString stringWithFormat:@"命名时区 timeZoneWithName:@\"America/New_York\"（名字来自系统的 tz database，拼错就是 nil），secondsFromGMT = %ld", (long)newYork.secondsFromGMT]);
        expect([newYork secondsFromGMTForDate:summer] - [newYork secondsFromGMTForDate:winter] == 3600,
               @"同一个命名时区，夏天和冬天差整整 3600 秒：**夏令时**就在这一格里 —— 算「两个时刻差多久」要用 NSDate 的秒，算「当地人看到几点」必须给日期问时区");

        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm";
        expect([[fmt stringFromDate:epoch] isEqualToString:@"2023-11-14 22:13"],
               @"固定模板 + en_US_POSIX + 固定时区 = 输出可写死进断言：这是「机器读写」的日期格式三件套");
        fmt.dateFormat = @"yyyy-MM-dd hh:mm a";
        expect([[fmt stringFromDate:epoch] isEqualToString:@"2023-11-14 10:13 PM"],
               @"HH 是 0-23（22 点），hh 是 1-12 配 a（10:13 PM）：**只写 hh 不写 a 就丢了半天**，这是日期解析失败的头号原因");
        fmt.dateFormat = @"yyyy-MM-dd";
        NSDate *parsed = [fmt dateFromString:@"2023-11-14"];
        expect(parsed != nil && [[fmt stringFromDate:parsed] isEqualToString:@"2023-11-14"],
               @"dateFromString: 是反向解析：模板对不上就返回 **nil**（不抛、不猜）");
        expect([fmt dateFromString:@"2023-14-99 99:99"] == nil,
               @"越界的日期串同样返回 nil：它不做「智能纠正」，所以脏数据安静变 nil，判空不能省");
        fmt.dateFormat = @"yyyy-MM-dd";
        NSDateComponents *xmasEve = [[NSDateComponents alloc] init];
        xmasEve.year = 2024; xmasEve.month = 12; xmasEve.day = 30;
        NSDate *weekYearDate = [utc dateFromComponents:xmasEve];
        fmt.dateFormat = @"YYYY-MM-dd";
        NSString *weekYearText = [fmt stringFromDate:weekYearDate];
        fmt.dateFormat = @"yyyy-MM-dd";
        expect([weekYearText isEqualToString:@"2025-12-30"] &&
               [[fmt stringFromDate:weekYearDate] isEqualToString:@"2024-12-30"],
               [NSString stringWithFormat:@"同一个 2024-12-30：小写 yyyy 给 %@，大写 **YYYY 是「周所属的年」**（那一周归 2025），给 %@ —— 跨年的那一周日志/报表日期会整条错一年，这是 OC/Swift 共同的坑",
                [fmt stringFromDate:weekYearDate], weekYearText]);
        fmt.dateFormat = @"yyyy-MM-dd EEE";
        expect([[fmt stringFromDate:epoch] hasSuffix:@"Tue"],
               @"EEE 是星期缩写（配 locale 才可变中英文）：模板里的字母全是「同一个字母不同大小写 = 不同字段」，所以只能背 + 只能测");
        fmt.dateFormat = @"yyyy-DDD";
        expect([[fmt stringFromDate:weekYearDate] isEqualToString:@"2024-365"],
               @"大写 DDD 是**当年第几天**（12-30 是第 365 天），小写 dd 才是当月第几天：两个字母差一个大小写，查日历表时最容易写错");
        NSArray<NSNumber *> *styles = @[ @(NSDateFormatterNoStyle), @(NSDateFormatterShortStyle),
                                         @(NSDateFormatterMediumStyle), @(NSDateFormatterLongStyle),
                                         @(NSDateFormatterFullStyle) ];
        NSMutableArray<NSString *> *styleTexts = [NSMutableArray array];
        for (NSNumber *st in styles) {
            NSDateFormatter *sf = [[NSDateFormatter alloc] init];
            sf.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            sf.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            sf.dateStyle = st.integerValue; sf.timeStyle = st.integerValue;
            [styleTexts addObject:[sf stringFromDate:epoch]];
        }
        line([NSString stringWithFormat:@"  五档 style：%@", [styleTexts componentsJoinedByString:@" | "]]);
        expect([styleTexts[0] isEqualToString:@""] && styleTexts[4].length > styleTexts[1].length,
               @"dateStyle/timeStyle 五档（No/Short/Medium/Long/Full）就是书上那张枚举表：NoStyle 两个都给的话输出**空串**，Full 会给完整历法名（ICU 数据变了字符串就会变，所以这里只断言相对长度和那一条空串）");
        if (@available(iOS 10.0, *)) {
            NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
            expect([[iso stringFromDate:epoch] isEqualToString:@"2023-11-14T22:13:20Z"],
                   @"NSISO8601DateFormatter 默认 UTC + 秒，产出 RFC3339/ISO8601 串：跨语言交换日期就该用它，不用自己拼模板");
        }

        // -------------------------------------------------- 15) JSON
        line(@"");
        line(@"== 15) NSJSONSerialization ==");
        NSDictionary *payload = @{@"name": @"iOS", @"version": @18, @"tags": @[@"ui", @"mobile"]};
        NSError *jsonError = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingSortedKeys
                                                         error:&jsonError];
        NSString *jsonText = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        line([NSString stringWithFormat:@"  json = %@", jsonText]);
        expect(jsonError == nil && json != nil, @"序列化没出错（写不出去时它其实是**抛异常**，见下面）");
        expect([jsonText isEqualToString:@"{\"name\":\"iOS\",\"tags\":[\"ui\",\"mobile\"],\"version\":18}"],
               @"NSJSONWritingSortedKeys 让键按字典序输出：不加它键序随机，diff/缓存/断言全废（这条在 debug 和 release 两份输出里也必须逐字节一致）");
        id parsedJson = [NSJSONSerialization JSONObjectWithData:json options:0 error:&jsonError];
        expect([parsedJson isKindOfClass:[NSDictionary class]],
               @"解析回来是 id：必须先 isKindOfClass: 再当字典用（JSON 顶层也可能是数组）");
        expect([parsedJson[@"name"] isEqualToString:@"iOS"] && [parsedJson[@"version"] integerValue] == 18,
               @"取出来逐个再判类型：JSON 的字符串/数字/布尔在 OC 里分别是 NSString/NSNumber/NSNumber");
        NSString *withNulls = @"{\"a\":null,\"b\":1,\"c\":[1,2],\"d\":2.5,\"e\":true}";
        id nullJson = [NSJSONSerialization JSONObjectWithData:[withNulls dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:0 error:NULL];
        expect(nullJson[@"a"] == [NSNull null] && [nullJson[@"b"] isKindOfClass:[NSNumber class]] &&
               [nullJson[@"c"] isKindOfClass:[NSArray class]],
               [NSString stringWithFormat:@"JSON 的 null 解析成 **[NSNull null]（类名 %@）**、数字成 %@、数组成 %@：**没有一个 JSON 数字是「不知道类型的」**，全按 NSNumber 装箱",
                MXCls(nullJson[@"a"]), MXCls(nullJson[@"b"]), MXCls(nullJson[@"c"])]);
        expect([nullJson[@"e"] boolValue] == YES,
               @"true 也是 NSNumber（__NSCFBoolean），取 boolValue 才对：直接当 NSNumber 拿去写进 UILabel 会打出 1");
        id mutableJson = [NSJSONSerialization JSONObjectWithData:json
                                                        options:NSJSONReadingMutableContainers error:NULL];
        expect(MXCls(mutableJson) != nil && [mutableJson isKindOfClass:[NSMutableDictionary class]] &&
               [mutableJson[@"tags"] isKindOfClass:[NSMutableArray class]],
               [NSString stringWithFormat:@"NSJSONReadingMutableContainers 把**每一层**都做成可变容器（外层 %@、里层 %@）：想改完再写回去就加它，否则改字典里那个数组要先整块取出来改再塞回去",
                MXCls(mutableJson), MXCls(mutableJson[@"tags"])]);
        id fragment = [NSJSONSerialization JSONObjectWithData:[@"\"bare\"" dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:NSJSONReadingAllowFragments error:NULL];
        expect([fragment isKindOfClass:[NSString class]],
               [NSString stringWithFormat:@"一个裸串不是合法 JSON（顶层只收对象/数组）：加 NSJSONReadingAllowFragments 才解得出来（类名 %@）", MXCls(fragment)]);
        NSError *badError = nil;
        id badJson = [NSJSONSerialization JSONObjectWithData:[@"{not json}" dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:0 error:&badError];
        expect(badJson == nil && badError != nil && [badError.domain isEqualToString:NSCocoaErrorDomain],
               [NSString stringWithFormat:@"读坏数据：返回 nil + 填 error（domain=%@ code=%ld），**不抛**：网络层永远要判 nil", badError.domain, (long)badError.code]);
        @try {
            NSData *bareOut = [NSJSONSerialization dataWithJSONObject:@"just a string" options:0 error:NULL];
            expect(bareOut == nil, [NSString stringWithFormat:@"顶层写裸串居然成功了（%lu 字节）", (unsigned long)bareOut.length]);
        } @catch (NSException *e) {
            line([NSString stringWithFormat:@"  写坏 JSON：%@ —— %@", e.name, e.reason]);
            expect([e.name isEqualToString:@"NSInvalidArgumentException"] &&
                   [e.reason containsString:@"Invalid top-level type in JSON write"],
                   @"**写**不出去时是抛异常（reason 固定一句 Invalid top-level type in JSON write），**读**坏数据才返回 nil：读写两边的错处理不对称，这是本章最后一条坑");
        }

        // -------------------------------------------------- 16) 边界
        line(@"");
        line(@"== 16) 本章的边界：只能靠探针量、或者根本不能进示例的 ==");
        line([NSString stringWithFormat:@"  1. 编译器拦住的格式符：warning: values of type 'NSUInteger' should not be used as format arguments; add an explicit cast to 'unsigned long' instead [-Wformat] —— 判定 1 要求日志全空，所以这条只能记在这里；它正是 §2 里那两个强转存在的原因"]);
        line(@"  2. warning: format specifies type 'double' but the argument has type 'int' [-Wformat]：把 %f 配 int，跑出来是 nan；反过来 %d 配 double 跑出一个和原值无关的大数（本次探针给 1390411937，换机器/换优化等级会变）。整数走通用寄存器、浮点走 SSE 寄存器，两边根本不在同一条流水线上");
        line(@"  3. warning: format specifies type 'id' but the argument has type 'const char *' [-Wformat]：用 %@ 打一个 char* —— 探针直接 signal 11 段错误退出（exit 139），连之前那句 printf 都没来得及落盘（stdout 全在缓冲区里）。%@ 是给对象的，它会对参数发 description 消息");
        line(@"  4. error: no known class method for selector 'valueWithCGPoint:'：只 import Foundation + CoreGraphics 就没有这个方法，它在 UIKit 的 NSValue 几何分类里（§6 已改成 import UIKit）。更阴的是：光链接 Foundation 的裸可执行文件里这个方法**编得过、跑起来抛 unrecognized selector**，因为那个分类在 UIKit 镜像加载时才注册进 NSValue");
        line(@"  5. warning: null passed to a callee that requires a non-null argument [-Wnonnull]：setObject:nil forKey: 在 NS_ASSUME_NONNULL 的头文件前会被编译器当场拦住 —— 而 §11 的下标写法 settings[@\"temp\"] = nil 却不报（它走 keyedSubscript，nil 是合法的「删除」）。同语义两条路，一条有诊断一条没有");
        line(@"  6. KVC 集合运算符（@sum/@avg/@max）用 valueForKey: 调会抛：error 原文 NSUnknownKeyException / this class is not key value coding-compliant for the key sum.self. —— 运算符只在 **valueForKeyPath:** 里解析（§8 已按这个写法实测），@count 是唯一例外");
        line(@"  7. 拿不遵守 NSCopying 的对象当字典 key，运行时的话术是「attempt to insert an object of class X with id Y as a key ... but it does not respond to copyWithZone:」：reason 里带对象地址，所以 §11 只把规则写全、不在这条上打印原文");
        line([NSString stringWithFormat:@"  8. 浅拷贝那个坑，探针实测是「还能查到」（8 个垫料键 + 数组套可变串当 key，改完里面的串之后用同一 key、新建同内容 key 都命中）—— 但命中是运气：hash 已经和桶位不一致，Foundation 不承诺任何行为。所以规则只有一条：**key 用不可变对象**"]);
        line(@"  9. 字典/集合的 description、NSSet 的 anyObject、NSDateFormatter 的 style 全文都不打值或只做相对断言：前者顺序与内容随实现变，后者随 ICU 数据版本变。本章能写死的断言，只有 §14 那种钉死 locale + 时区 + 模板的输出");
        line(@"  10. 换机器会变的东西：NSString/NSNumber 的私有类名、tagged pointer 的指针巧合（04 章 §运算符（三））、plist 字节数、tz database 的时区名、ICU 的日期 style 全文、任何渲染相关的量");

        line(@"");
        if (gFailures == 0) { line(@"全部断言通过。"); }
        else { line([NSString stringWithFormat:@"有 %d 条断言失败。", gFailures]); }
        printf("==== 05 结束 ====\n");
    }
    return gFailures == 0 ? 0 : 1;
}
