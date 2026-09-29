// ============================================================
// 27 章 OC 侧 · 第二部分：属性、ivar 与关联对象、分类、协议、可变性、异常
// ============================================================
#import "RTRuntime.h"
#import "RTCommon.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreGraphics/CoreGraphics.h>

// ---------------------------------------------------------------- §6 属性
@interface RTProps : NSObject {
    int _manualBacking;
}
/// 一个属性在 runtime 里其实是三样东西：访存方法 + ivar + 一条属性记录
@property (nonatomic, assign) int plain;
@property (nonatomic, assign) int manual;
@property (nonatomic, strong) NSString *strStrong;
@property (nonatomic, copy) NSString *strCopy;
@property (nonatomic, weak) RTProps *weakRef;
@property (nonatomic, readonly) int roValue;
@property (nonatomic, getter=customGet) int customGetter;
@property (nonatomic, setter=mySet:) int customSetter;
@property (nonatomic) CGRect rect;
@property (nonatomic) void (^blockProp)(int);
@property (nonatomic) Class classProp;
@property (nonatomic) id anything;
@property (nonatomic) NSObject *typedObj;
@property (nonatomic) NSArray<NSString *> *genericArr;
@property (nonatomic) BOOL boolProp;
@property (nonatomic) const char *cString;
@property (nonatomic) long double longDoubleProp;
@property (nonatomic) NSInteger integerProp;
- (void)writeManualBacking:(int)v;
@end

@implementation RTProps
@synthesize manual = _manualBacking;   // 显式绑到已存在的 ivar，不再自动生成 _manual
- (void)writeManualBacking:(int)v { _manualBacking = v; }
@end

/// 分类只能加方法，加不了 ivar（探针记录编译错误）；关联对象是唯一替代品
static const void *kRTKeyA = &kRTKeyA;
static const void *kRTKeyB = &kRTKeyB;

@interface RTProps (Assoc)
@property (nonatomic, strong) NSString *assocViaCategory;
@end
@implementation RTProps (Assoc)
- (void)setAssocViaCategory:(NSString *)v { objc_setAssociatedObject(self, kRTKeyA, v, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
- (NSString *)assocViaCategory { return objc_getAssociatedObject(self, kRTKeyA); }
@end

/// §10 分类：给没有该方法的类补方法
@interface RTBaseThing : NSObject
- (NSString *)fromPrimary;
@end
@implementation RTBaseThing
- (NSString *)fromPrimary { return @"主实现"; }
@end
@interface RTBaseThing (Extra)
- (NSString *)fromCategory;
@end
@implementation RTBaseThing (Extra)
- (NSString *)fromCategory { return @"分类补的方法"; }
@end
/// 分类里也能定义类方法 +load；顺序见 §10
@interface RTLoadOrder1 : NSObject
@end
@implementation RTLoadOrder1
+ (void)load { [RTL record:@"+load RTLoadOrder1（父类自己）"]; }
+ (void)initialize { [RTL record:@"+initialize RTLoadOrder1（第一次收到消息时）"]; }
- (void)ping { [RTL record:@"ping 调用了继承来的实例方法"]; }
@end
@interface RTLoadOrder2 : RTLoadOrder1
@end
@implementation RTLoadOrder2
+ (void)load { [RTL record:@"+load RTLoadOrder2（子类）"]; }
+ (void)initialize { [RTL record:@"+initialize RTLoadOrder2（子类自己）"]; }
@end
@interface RTLoadOrder1 (Late)
@end
@implementation RTLoadOrder1 (Late)
+ (void)load { [RTL record:@"+load RTLoadOrder1(Late) 分类"]; }
@end

/// §11 协议
@protocol RTBase1 <NSObject>
- (void)baseRequired;
@end
@protocol RTDerived1 <RTBase1>
@optional
- (void)derivedOptional;
@property (nonatomic, copy) NSString *protoProp;
+ (NSInteger)derivedClassMethod;
@end
@interface RTProtoUser : NSObject <RTDerived1>
@end
@implementation RTProtoUser
- (void)baseRequired {}
@end
/// 非正式协议：只在 NSObject 的分类里声明，不实现
@interface NSObject (RTInformal)
- (NSString *)informalNeverImplemented;
@end

/// §16 可变性
@interface RTDeepThing : NSObject <NSCopying>
@property (nonatomic, strong) NSMutableArray *kids;
- (instancetype)initWithKids:(NSArray *)kids;
@end
@implementation RTDeepThing
- (instancetype)initWithKids:(NSArray *)kids { if ((self = [super init])) { _kids = [kids mutableCopy]; } return self; }
- (id)copyWithZone:(NSZone *)zone {
    RTDeepThing *c = [[RTDeepThing allocWithZone:zone] initWithKids:_kids];
    return c;
}
@end

/// §17 异常
@interface RTHotTea : NSException
@end
@implementation RTHotTea
@end

NSArray<NSString *> *RTLinesProperties(void) {
    [RTL begin];
    unsigned n = 0;
    objc_property_t *ps = class_copyPropertyList([RTProps class], &n);
    [RTL add:[NSString stringWithFormat:@"class_copyPropertyList(RTProps) 报出 %u 个属性 —— 只算本类，不含继承自 NSObject 的", n]];
    for (unsigned i = 0; i < n; i++) {
        [RTL add:[NSString stringWithFormat:@"    %s => %s", property_getName(ps[i]), property_getAttributes(ps[i]) ?: "(nil)"]];
    }
    free((void *)ps);
    unsigned pn = 0;
    free((void *)class_copyPropertyList([RTBaseThing class], &pn));
    [RTL add:[NSString stringWithFormat:@"对照组：只写了实例方法的 RTBaseThing 属性数=%u（所以 0 个属性是「没写 @property」的正常表现）", pn]];

    objc_property_t one = class_getProperty([RTProps class], "plain");
    unsigned avn = 0;
    objc_property_attribute_t *avs = property_copyAttributeList(one, &avn);
    NSMutableString *dump = [NSMutableString string];
    for (unsigned i = 0; i < avn; i++) {
        [dump appendFormat:@"{%s,%s} ", avs[i].name, avs[i].value];
    }
    free((void *)avs);
    [RTL add:[NSString stringWithFormat:@"把编码串拆成结构化零件（property_copyAttributeList）：plain -> %s", dump.UTF8String]];
    objc_property_t wp = class_getProperty([RTProps class], "weakRef");
    objc_property_t cp = class_getProperty([RTProps class], "strCopy");
    objc_property_t rp = class_getProperty([RTProps class], "roValue");
    objc_property_t bp = class_getProperty([RTProps class], "blockProp");
    [RTL add:[NSString stringWithFormat:@"单个字母的含义（实测编码串里出现过的）：'&'=strong 'C'=copy 'W'=weak 'N'=nonatomic 'R'=readonly 'G='自定义 getter 'S='自定义 setter 'V'=背后的 ivar 名"]];
    [RTL add:[NSString stringWithFormat:@"    weakRef=%s  strCopy=%s", property_getAttributes(wp), property_getAttributes(cp)]];
    [RTL add:[NSString stringWithFormat:@"    roValue=%s（没有 S，因为只读）", property_getAttributes(rp)]];
    [RTL add:[NSString stringWithFormat:@"    blockProp=%s —— block 属性被自动加上 'C'（copy），这是 ARC 时代 block 语义的默认值", property_getAttributes(bp)]];
    [RTL add:[NSString stringWithFormat:@"    只读属性的 getter 也在方法表里：instanceMethodSignatureForSelector(roValue) 参数数=%lu，而 setRoValue: 问不到=%@",
              (unsigned long)[[RTProps instanceMethodSignatureForSelector:@selector(roValue)] numberOfArguments],
              [RTProps instanceMethodSignatureForSelector:NSSelectorFromString(@"setRoValue:")] ? @"有" : @"nil"]];

    RTProps *p = [RTProps new];
    p.plain = 7;
    unsigned mn = 0;
    Method *ms = class_copyMethodList([RTProps class], &mn);
    // 方法表的顺序在 -Onone / -O 下会变，输出前排序才能得到「两次编译逐字节相同」的证据
    NSMutableArray<NSString *> *msPicked = [NSMutableArray array];
    for (unsigned i = 0; i < mn; i++) {
        NSString *name = NSStringFromSelector(method_getName(ms[i]));
        if ([name hasPrefix:@"plain"] || [name hasPrefix:@"roValue"] || [name hasPrefix:@"customGet"]) {
            [msPicked addObject:name];
        }
    }
    free((void *)ms);
    NSArray<NSString *> *msSorted = [msPicked sortedArrayUsingSelector:@selector(compare:)];
    [RTL add:[NSString stringWithFormat:@"一个 @property 实际生成的方法（挑出来的，已按字典序排好）： %@（RTProps 实例方法总数=%u）",
              [msSorted componentsJoinedByString:@" "], mn]];
    [RTL add:[NSString stringWithFormat:@"自动合成的 ivar：_plain 存在=%d；@synthesize 显式绑到 _manualBacking 的那条也在 ivar 表里（见 §7）",
              class_getInstanceVariable([RTProps class], "_plain") ? 1 : 0]];

    [RTL add:@"strong / copy 的差别只有在「装进去的对象后来被改了」才看得见："];
    NSMutableString *src = [@"原始内容" mutableCopy];
    RTProps *q = [RTProps new];
    q.strStrong = src;
    q.strCopy = src;
    [src appendString:@"，后来被改了"];
    [RTL add:[NSString stringWithFormat:@"    源对象改成 %@ 之后：strong 读到=%@（同一个对象，跟着变）；copy 读到=%@（当时拷了一份，不变）",
              src, q.strStrong, q.strCopy]];
    [RTL add:[NSString stringWithFormat:@"    两者的实际类别：strong 那份=%@  copy 那份=%@",
              NSStringFromClass([q.strStrong class]), NSStringFromClass([q.strCopy class])]];
    __weak RTProps *weakHolder;
    @autoreleasepool {
        RTProps *tmp = [RTProps new];
        weakHolder = tmp;
        RTProps *inner = [RTProps new];
        tmp.weakRef = inner;
        [RTL add:[NSString stringWithFormat:@"    池内：weakRef 指得到=%@  宿主被 weak 看到=%d", tmp.weakRef ? @"是" : @"否", weakHolder != nil]];
    }
    [RTL add:[NSString stringWithFormat:@"池一结束：宿主对象消失（weak 看到 %@），它身上的 weak 属性也随之变成 nil；strong 属性则把内容一起拖到释放",
              weakHolder ? @"还活着" : @"nil"]];
    return [RTL end];
}

NSArray<NSString *> *RTLinesIvarsAndAssoc(void) {
    [RTL begin];
    unsigned n = 0;
    Ivar *ivs = class_copyIvarList([RTProps class], &n);
    [RTL add:[NSString stringWithFormat:@"class_copyIvarList(RTProps)=%u 个 ivar；@property 只是造 ivar 的最常见方式，不是唯一方式", n]];
    for (unsigned i = 0; i < n; i++) {
        [RTL add:[NSString stringWithFormat:@"    %s  类型编码=%s  偏移=%td", ivar_getName(ivs[i]), ivar_getTypeEncoding(ivs[i]) ?: "(nil)", ivar_getOffset(ivs[i])]];
    }
    free((void *)ivs);
    RTProps *p = [RTProps new];
    p.plain = 4321;
    Ivar plain = class_getInstanceVariable([RTProps class], "_plain");
    [RTL add:@"探针记录：object_getIvar 去读一个 int 型 ivar 会当场 SIGSEGV —— 它把 4321 这个整数当对象指针解引用并 retain。"
                @"这对函数只能用于对象类型的 ivar（本章不执行）。"];
    int *slot = (int *)((char *)(__bridge void *)p + ivar_getOffset(plain));
    int rawBefore = *slot;
    *slot = 999;
    int propAfter = p.plain;
    [RTL add:[NSString stringWithFormat:@"读标量 ivar 要用 C 的方式：char* 基址 + ivar_getOffset(%td) 强转 int* -> %d；写回一个 999 之后属性读到 %d",
              ivar_getOffset(plain), rawBefore, propAfter]];
    Ivar objIvar = class_getInstanceVariable([RTProps class], "_strStrong");
    p.strStrong = @"用 object_setIvar 放进去的";
    [RTL add:[NSString stringWithFormat:@"对象型 ivar（_strStrong）object_getIvar -> %@；偏移=%td",
              object_getIvar(p, objIvar), ivar_getOffset(objIvar)]];
    Ivar none = class_getInstanceVariable([RTProps class], "_根本没有这个 ivar");
    [RTL add:[NSString stringWithFormat:@"问一个不存在的 ivar：class_getInstanceVariable -> %@（返回 NULL，不抛异常）",
              none ? @"非空" : @"NULL"]];
    n = 0;
    Ivar *metaIvs = class_copyIvarList(object_getClass([RTProps class]), &n);
    [RTL add:[NSString stringWithFormat:@"元类的 ivar 表是空的（%u 个）——「类变量」在 ObjC 里没有对应物，只能用 static 全局模拟；"
                @"实例大小 RTProps=%zu，NSObject 本身占 %zu（一个 isa 指针）",
              n, class_getInstanceSize([RTProps class]), class_getInstanceSize([NSObject class])]];
    free((void *)metaIvs);

    [RTL add:@"分类不能加 ivar（探针诊断原文：error: instance variables may not be placed in categories），关联对象是官方替代："];
    RTProps *host = [RTProps new];
    [RTL add:[NSString stringWithFormat:@"    用分类属性 assocViaCategory 写一次 -> 读回=%@", host.assocViaCategory]];
    host.assocViaCategory = @"存进关联表";
    [RTL add:[NSString stringWithFormat:@"    再读=%@；另一个实例读同一个 key=%@（关联表按「宿主对象 + key」两维存）",
              host.assocViaCategory, [RTProps new].assocViaCategory]];
    [RTL add:[NSString stringWithFormat:@"    policy 原始值：ASSIGN=%tu COPY=%tu RETAIN=%tu COPY_NONATOMIC=%tu RETAIN_NONATOMIC=%tu",
              OBJC_ASSOCIATION_ASSIGN, OBJC_ASSOCIATION_COPY, OBJC_ASSOCIATION_RETAIN, OBJC_ASSOCIATION_COPY_NONATOMIC, OBJC_ASSOCIATION_RETAIN_NONATOMIC]];
    objc_setAssociatedObject(host, kRTKeyB, @"第二个 key 的值", OBJC_ASSOCIATION_COPY_NONATOMIC);
    [RTL add:[NSString stringWithFormat:@"    设成 nil 等价于移除：remove 之后=%@", ({ objc_setAssociatedObject(host, kRTKeyB, nil, OBJC_ASSOCIATION_COPY_NONATOMIC); objc_getAssociatedObject(host, kRTKeyB); })]];
    [RTL add:@"    关联对象的生命周期完全跟着宿主：宿主 dealloc 时它的整张关联表被 objc_removeAssociatedObjects 清掉（探针：拿一个 weak 指针跟宿主，"
                @"宿主释放后 weak 变 nil，同时另一个仍活着的实例读同一个 key 得到 nil —— 值不会串到别的对象上，也不会比宿主活得久）"];
    return [RTL end];
}

// ---------------------------------------------------------------- §10 分类与 +load
NSArray<NSString *> *RTLinesCategories(void) {
    [RTL begin];
    RTBaseThing *t = [RTBaseThing new];
    [RTL add:[NSString stringWithFormat:@"分类给已有类补方法：[t fromCategory]=%@（t 的源码里从没写过这个方法）", [t fromCategory]]];
    unsigned n = 0;
    Method *ms = class_copyMethodList([RTBaseThing class], &n);
    NSMutableArray<NSString *> *picked = [NSMutableArray array];
    for (unsigned i = 0; i < n; i++) { [picked addObject:NSStringFromSelector(method_getName(ms[i]))]; }
    free((void *)ms);
    [RTL add:[NSString stringWithFormat:@"分类方法是**合并进原类的方法表**的：class_copyMethodList(RTBaseThing)=%@（分类与主实现不分家；顺序已排序，方法表本身的顺序不保证稳定）",
              [[picked sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@" "]]];
    n = 0;
    free((void *)class_copyIvarList([RTBaseThing class], &n));
    [RTL add:[NSString stringWithFormat:@"分类给类加的是方法，不是 ivar：RTBaseThing 的 ivar 数=%u（一个都没有）", n]];
    [RTL add:@"探针记录：在分类里写 { int addedIvar; } 的编译诊断是 error: instance variables may not be placed in categories —— 所以才有 §7 的关联对象。"];
    [RTL add:@"探针记录：分类里重写主类已有的方法，clang 给 warning: category is implementing a method which will also be implemented by its primary class，"
                @"而运行期确实是分类的实现盖住主实现（链接顺序决定谁赢，别依赖）。"];

    [RTL add:@"+load / +initialize 的时机（前两条发生在 main 之前，是 +record 记下来的）："];
    for (NSString *one in [RTL records]) { [RTL add:[@"    " stringByAppendingString:one]]; }
    RTLoadOrder1 *o2 = [RTLoadOrder2 new];
    [RTL add:[NSString stringWithFormat:@"    alloc 子类实例之后，日志=%u 条（父类 initialize 先于子类）", (unsigned)[RTL records].count]];
    [o2 ping];
    [RTLoadOrder1 new];
    [RTL add:[NSString stringWithFormat:@"    再 alloc 一个父类实例，日志仍然是 %u 条：父类的 +initialize 只在第一次收到消息时跑，不会重复", (unsigned)[RTL records].count]];
    return [RTL end];
}

// ---------------------------------------------------------------- §11 协议
NSArray<NSString *> *RTLinesProtocols(void) {
    [RTL begin];
    Protocol *d = @protocol(RTDerived1);
    [RTL add:[NSString stringWithFormat:@"@protocol(RTDerived1) 的名字=%s；它等于 NSProtocolFromString(@\"RTDerived1\") 吗=%d",
              protocol_getName(d), d == NSProtocolFromString(@"RTDerived1") ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"查一个不存在的协议名：NSProtocolFromString(@\"没定义过的协议\")=%@",
              NSProtocolFromString(@"没定义过的协议") ? @"非 nil" : @"nil"]];
    [RTL add:[NSString stringWithFormat:@"protocol_isEqual(@protocol(RTDerived1), @protocol(RTBase1))=%d（派生协议不等于父协议）",
              protocol_isEqual(d, @protocol(RTBase1)) ? 1 : 0]];
    unsigned n = 0;
    Protocol *const *inherited = protocol_copyProtocolList(d, &n);
    [RTL add:[NSString stringWithFormat:@"RTDerived1 继承了 %u 个协议：%s", n, n ? protocol_getName(inherited[0]) : "-"]];
    free((void *)inherited);

    n = 0;
    struct objc_method_description *all = protocol_copyMethodDescriptionList(d, NO, YES, &n);
    [RTL add:[NSString stringWithFormat:@"协议里的实例方法（含 optional）%u 个：", n]];
    for (unsigned i = 0; i < n; i++) {
        [RTL add:[NSString stringWithFormat:@"    %@  类型编码=%s", NSStringFromSelector(all[i].name), all[i].types ?: "?"]];
    }
    free((void *)all);
    n = 0;
    struct objc_method_description *req = protocol_copyMethodDescriptionList(d, YES, YES, &n);
    [RTL add:[NSString stringWithFormat:@"    其中 @required 的实例方法 %u 个：%s", n, n ? NSStringFromSelector(req[0].name).UTF8String : "-"]];
    free((void *)req);
    n = 0;
    struct objc_method_description *clsMd = protocol_copyMethodDescriptionList(d, NO, NO, &n);
    [RTL add:[NSString stringWithFormat:@"    协议里的类方法 %u 个：%s", n, n ? NSStringFromSelector(clsMd[0].name).UTF8String : "-"]];
    free((void *)clsMd);
    objc_property_t *pp = protocol_copyPropertyList(d, &n);
    NSMutableString *propNames = [NSMutableString string];
    for (unsigned i = 0; i < n; i++) { [propNames appendFormat:@"%s ", property_getName(pp[i])]; }
    free((void *)pp);
    [RTL add:[NSString stringWithFormat:@"协议里的属性 %u 个：%s（属性也会被拆成 getter/setter 两个方法描述，上面方法数里就能看到）", n, propNames.UTF8String]];
    struct objc_method_description one = protocol_getMethodDescription(d, @selector(derivedOptional), NO, YES);
    [RTL add:[NSString stringWithFormat:@"protocol_getMethodDescription 查单个可选方法：name=%@ types=%@",
              one.name ? NSStringFromSelector(one.name) : @"(nil)",
              one.types ? [NSString stringWithUTF8String:one.types] : @"(nil)"]];
    struct objc_method_description miss = protocol_getMethodDescription(d, @selector(baseRequired), NO, YES);
    [RTL add:[NSString stringWithFormat:@"    同一个方法但只问 optional 段（baseRequired 是 @required）：name=%@ —— 按 required/optional 分开查会查空",
              miss.name ? NSStringFromSelector(miss.name) : @"(nil)"]];

    RTProtoUser *u = [RTProtoUser new];
    Class c = [RTProtoUser class];
    [RTL add:[NSString stringWithFormat:@"采纳关系：[类 conformsToProtocol:RTDerived1]=%d 父协议 RTBase1=%d NSObject=%d 无关的 NSCopying=%d",
              [c conformsToProtocol:@protocol(RTDerived1)] ? 1 : 0,
              [c conformsToProtocol:@protocol(RTBase1)] ? 1 : 0,
              [c conformsToProtocol:@protocol(NSObject)] ? 1 : 0,
              [c conformsToProtocol:@protocol(NSCopying)] ? 1 : 0]];
    n = 0;
    Protocol *const *adopted = class_copyProtocolList(c, &n);
    [RTL add:[NSString stringWithFormat:@"class_copyProtocolList(RTProtoUser)=%u 个：%s（只列**直接**采纳的，父协议要靠 conformsToProtocol: 问）",
              n, n ? protocol_getName(adopted[0]) : "-"]];
    free((void *)adopted);
    [RTL add:[NSString stringWithFormat:@"只实现了必需的 baseRequired：respondsToSelector(baseRequired)=%d respondsToSelector(derivedOptional)=%d（optional 没实现也不报错，调用前必须自己问）",
              [u respondsToSelector:@selector(baseRequired)] ? 1 : 0,
              [u respondsToSelector:@selector(derivedOptional)] ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"非正式协议（只在 NSObject 分类里声明、从不实现）：[NSObject instancesRespondToSelector:informalNeverImplemented]=%d；"
                @"[NSString instancesRespondToSelector:]=%d",
              [NSObject instancesRespondToSelector:@selector(informalNeverImplemented)] ? 1 : 0,
              [NSString instancesRespondToSelector:@selector(informalNeverImplemented)] ? 1 : 0]];
    [RTL add:@"    也就是说：光声明一个 NSObject 分类方法，所有对象都「编译得过、运行时不响应」—— 这就是历史上非正式协议的写法，今天用 @optional 正式协议替代"];
    return [RTL end];
}

// ---------------------------------------------------------------- §16 可变性
NSArray<NSString *> *RTLinesMutability(void) {
    [RTL begin];
    [RTL add:[NSString stringWithFormat:@"可变类的**父类**就是不可变那个：NSMutableString->%@  NSMutableArray->%@  NSMutableDictionary->%@  NSMutableSet->%@",
              NSStringFromClass(class_getSuperclass([NSMutableString class])),
              NSStringFromClass(class_getSuperclass([NSMutableArray class])),
              NSStringFromClass(class_getSuperclass([NSMutableDictionary class])),
              NSStringFromClass(class_getSuperclass([NSMutableSet class]))]];
    NSMutableArray *ma = [@[ @"a", @"b" ] mutableCopy];
    NSArray *shallow = [ma copy];
    NSArray *deep = [ma mutableCopy];
    [RTL add:[NSString stringWithFormat:@"可变对象 copy 出来的实际类=%@（不可变）；mutableCopy 出来的=%@（可变）",
              NSStringFromClass([shallow class]), NSStringFromClass([deep class])]];
    [ma addObject:@"c"];
    [RTL add:[NSString stringWithFormat:@"    之后再改源：copy 的那份 count=%lu（不受影响），mutableCopy 的那份 count=%lu（也不受影响，两者都是各自的一份容器）",
              (unsigned long)shallow.count, (unsigned long)deep.count]];
    RTDeepThing *orig = [[RTDeepThing alloc] initWithKids:@[[[NSMutableArray alloc] initWithObjects:@"内层1", nil]]];
    RTDeepThing *copied = [orig copy];
    [(NSMutableArray *)orig.kids[0] addObject:@"内层2"];
    [RTL add:[NSString stringWithFormat:@"copy 是**浅拷贝**：外层容器新建了，内层对象还是同一个 —— 改 orig 的内层数组，副本看到 count=%lu",
              (unsigned long)[(NSMutableArray *)copied.kids[0] count]]];
    [RTL add:[NSString stringWithFormat:@"    内外层是同一个对象=%d", (orig.kids[0] == copied.kids[0])]];
    NSError *err = nil;
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithObject:[@"x" mutableCopy] forKey:@"k"];
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:md format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
    id back = [NSPropertyListSerialization propertyListWithData:plist options:0 format:NULL error:&err];
    [RTL add:[NSString stringWithFormat:@"plist 往返之后**逐层**问类：源字典=%@ 回来=%@（外层竟然还是可变的），"
                                        @"但里层的 NSMutableString 回来=%@（成了不可变的 tagged pointer）",
              NSStringFromClass([md class]), NSStringFromClass([back class]),
              NSStringFromClass([[back objectForKey:@"k"] class])]];
    [RTL add:@"    结论：「走一遍序列化就全都不可变」是想当然 —— 容器每一层的实际类要各自问，别拿顶层那层推断整棵树；"
                @"里层之所以丢可变性，是因为 plist 格式里只有字符串这一种类型，没有「可变字符串」这档"];
    return [RTL end];
}

// ---------------------------------------------------------------- §17 异常
NSArray<NSString *> *RTLinesExceptions(void) {
    [RTL begin];
    NSMutableString *trace = [NSMutableString string];
    @try {
        [trace appendString:@"try 开始；"];
        @throw [NSException exceptionWithName:@"RTPlain" reason:@"普通异常" userInfo:@{ @"code": @1 }];
    } @catch (RTHotTea *e) {
        [trace appendString:@"被 RTHotTea 块抓住（不该发生）；"];
    } @catch (NSException *e) {
        [trace appendFormat:@"被 NSException 块抓住：name=%@ reason=%@ userInfo 有 %@；", e.name, e.reason, e.userInfo[@"code"]];
    } @finally {
        [trace appendString:@"finally 一定执行；"];
    }
    [RTL add:[NSString stringWithFormat:@"① 抛 NSException，两个 @catch 按「具体优先」匹配 -> %@", trace]];

    trace = [NSMutableString string];
    @try {
        @try {
            @throw [[RTHotTea alloc] initWithName:@"RTHotTea" reason:@"太烫" userInfo:nil];
        } @catch (NSException *outer) {
            [trace appendString:@"内层只写了 NSException，子类异常被它抓住；"];
        }
        @throw [[RTHotTea alloc] initWithName:@"RTHotTea" reason:@"太烫" userInfo:nil];
    } @catch (RTHotTea *specific) {
        [trace appendFormat:@"外层写了 RTHotTea，就轮到它：%@\uff1b", specific.reason];
    } @finally {
        [trace appendString:@"finally；"];
    }
    [RTL add:[NSString stringWithFormat:@"② 自定义 NSException 子类：谁写得具体谁先接 -> %@", trace]];

    trace = [NSMutableString string];
    @try {
        @throw @"我根本不是 NSException，就是个 NSString";
    } @catch (NSString *s) {
        [trace appendFormat:@"@throw 可以抛任意对象，@catch(id) 之外还能按类接：接到 %@；", s];
    } @catch (id any) {
        [trace appendString:@"这条不该走到；"];
    }
    [RTL add:[NSString stringWithFormat:@"③ 抛非异常对象 -> %@", trace]];

    trace = [NSMutableString string];
    @try {
        NSArray *arr = @[@"只有两个"];
        [arr objectAtIndex:99];
        [trace appendString:@"没抛？；"];
    } @catch (NSException *e) {
        NSString *head = @"*** -[__NSArrayI";
        BOOL looksLikeArray = [e.reason hasPrefix:head];
        [trace appendFormat:@"%@：%@；", e.name,
         looksLikeArray ? @"reason 以接收者类名开头" : @"reason 是越界信息"];
    }
    [RTL add:[NSString stringWithFormat:@"④ 系统抛的异常能被同样的 @try 接住（越界是 NSRangeException）： %@", trace]];

    trace = [NSMutableString string];
    @try {
        @try {
            [NSException raise:@"RTInner" format:@"内层抛出"];
        } @catch (NSException *e) {
            [trace appendString:@"接住内层后再抛一次；"];
            @throw e;
        } @finally {
            [trace appendString:@"内层 finally（即使正在往外抛也先跑完）；"];
        }
    } @catch (NSException *e) {
        [trace appendFormat:@"外层再接：%@；", e.name];
    }
    [RTL add:[NSString stringWithFormat:@"⑤ 嵌套 @try 与「@catch 里再 @throw」-> %@", trace]];
    [RTL add:@"⑥ 探针记录：本章之外还有两条只能记不能跑 —— 没人接的 NSException 会让进程 SIGABRT（stderr 打整段 reason 与调用栈）；Swift 侧的 do/catch 抓不到 ObjC 的 @throw（不是同一种错误通道）。"];
    return [RTL end];
}

NSString *RTCallThroughObjC(id target, NSString *selectorName) {
    SEL sel = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:sel]) { return @"(不响应)"; }
    id (*fn)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
    id r = fn(target, sel);
    return [r description] ?: @"(返回 nil)";
}

Class _Nullable RTIsaOf(id obj) { return object_getClass(obj); }

