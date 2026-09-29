// ============================================================
// 27 章 OC 侧 · 第三部分：消息转发、换实现、KVC、KVO、内省、对象通信
// 这一部分回答的是「消息没被立刻接住会发生什么」和「怎么在运行时改行为」。
// ============================================================
#import "RTRuntime.h"
#import "RTCommon.h"
#import "RTForward.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSMutableArray *RTNewLog(void) { return [NSMutableArray new]; }
static void RTLog(NSMutableArray *log, NSString *line) { if (log) { [log addObject:line]; } }
/// 把日志并排成一串：直接打印 NSArray 的 description 会带来缩进和 \U 转义，逐字比对很不友好
static NSString *RTJoin(NSArray<NSString *> *log) { return [log componentsJoinedByString:@" | "]; }

/// 只列这个类**自己**方法表里的选标名（按字典序排好，方法表原始顺序不保证稳定）。
/// 判断「有没有覆盖」必须用它：class_getInstanceMethod 会沿继承链往上找，
/// 父类本来就有这个方法时永远返回真，拿它证明覆盖是假证据。
static NSArray<NSString *> *RTOwnMethodNames(Class cls) {
    unsigned n = 0;
    Method *ms = class_copyMethodList(cls, &n);
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (unsigned i = 0; i < n; i++) { [names addObject:NSStringFromSelector(method_getName(ms[i]))]; }
    free((void *)ms);
    [names sortUsingSelector:@selector(compare:)];
    return names;
}
static BOOL RTClassOwnsMethod(Class cls, SEL sel) {
    return [RTOwnMethodNames(cls) containsObject:NSStringFromSelector(sel)];
}

static NSMutableArray *gTrace;   // 当前小节的日志板，各处 RTLog(gTrace, ...)

// ---------------------------------------------------------------- §8 四级转发

/// 第 1 级：resolveInstanceMethod: —— 方法在运行时现造
@interface RTResolver : NSObject
@end
@implementation RTResolver
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    RTLog(gTrace, [NSString stringWithFormat:@"①resolve(%@)", NSStringFromSelector(sel)]);
    if (sel == @selector(magicGreet)) {
        IMP imp = imp_implementationWithBlock(^NSString *(id self) {
            RTLog(gTrace, @"block 版实现被调到");
            return @"这是运行时才造出来的方法";
        });
        // 类型编码要和 block 的真实形状一致；写错了编译器不管，脏数据到下一次真访问才炸
        BOOL ok = class_addMethod(self, sel, imp, "@@:");
        RTLog(gTrace, [NSString stringWithFormat:@"class_addMethod=%d", ok]);
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
@end

/// 第 2 级：forwardingTargetForSelector: —— 换个对象来接
@interface RTRealHandler : NSObject
- (NSString *)askName;
@end
@implementation RTRealHandler
- (NSString *)askName { RTLog(gTrace, @"替身的 askName 被调"); return @"替身对象接住了"; }
@end

@interface RTFastForwarder : NSObject
@end
@implementation RTFastForwarder
- (id)forwardingTargetForSelector:(SEL)sel {
    RTLog(gTrace, [NSString stringWithFormat:@"②forwardingTarget(%@)", NSStringFromSelector(sel)]);
    return [RTRealHandler new];
}
@end

/// 第 3 级：签名 + NSInvocation —— 唯一能改参数和返回值的一级
@interface RTSlowForwarder : NSObject
@end
@implementation RTSlowForwarder
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    RTLog(gTrace, [NSString stringWithFormat:@"③a 签名(%@)", NSStringFromSelector(sel)]);
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    RTLog(gTrace, [NSString stringWithFormat:@"③b 转发(%@) 原返回类型=%s 参数数=%lu",
                  NSStringFromSelector(invocation.selector),
                  invocation.methodSignature.methodReturnType,
                  (unsigned long)invocation.methodSignature.numberOfArguments]);
    NSString *result = @"慢速转发造出来的返回值";
    NSString *hold = result;                 // setReturnValue 要一个能活到调用方取值的地址
    [invocation setReturnValue:(void *)&hold];
}
@end

/// 主动放弃前两级，只留第三级
@interface RTChain : NSObject
@end
@implementation RTChain
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    RTLog(gTrace, @"链:①resolve 故意返回 NO");
    return NO;
}
- (id)forwardingTargetForSelector:(SEL)sel {
    RTLog(gTrace, @"链:②forwardingTarget 返回 nil");
    return nil;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    RTLog(gTrace, @"链:③a 只好给签名");
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}
- (void)forwardInvocation:(NSInvocation *)inv {
    RTLog(gTrace, @"链:③b forwardInvocation 自己处理");
    NSString *r = @"前两级都不肯让，最后一级谈成了";
    NSString *hold = r;
    [inv setReturnValue:(void *)&hold];
}
@end

NSArray<NSString *> *RTLinesForwarding(void) {
    [RTL begin];

    gTrace = RTNewLog();
    RTResolver *r = [RTResolver new];
    BOOL knowsFirst = [r respondsToSelector:@selector(magicGreet)];
    NSUInteger atAsk = gTrace.count;
    NSString *logAfterAsk = RTJoin(gTrace);
    id first = [r performSelector:@selector(magicGreet)];
    NSString *logAfterFirst = RTJoin(gTrace);
    id second = [r performSelector:@selector(magicGreet)];
    NSUInteger resolveRuns = 0;
    for (NSString *one in gTrace) { if ([one hasPrefix:@"①resolve"]) resolveRuns += 1; }
    [RTL add:[NSString stringWithFormat:@"第 1 级 resolveInstanceMethod:：类里从没声明过 magicGreet，先问一次 respondsToSelector -> %d，"
                                        @"可日志已经长了 %lu 条（%@）—— 这一问不是被动查询：runtime 先给类一次「你要不要现在补方法」的机会，"
                                        @"补上了就回答 1",
              knowsFirst ? 1 : 0, (unsigned long)atAsk, logAfterAsk]];
    [RTL add:[NSString stringWithFormat:@"    紧接着第一次调用 -> %@；日志=%@", first, logAfterFirst]];
    [RTL add:[NSString stringWithFormat:@"    第二次调用 -> %@；整份日志里 ①resolve 只出现过 %lu 次 —— 方法进了缓存，解析只跑一次，"
                                        @"被重复的只有实现本身（%@）",
              second, (unsigned long)resolveRuns, RTJoin(gTrace)]];
    [RTL add:[NSString stringWithFormat:@"    解析成功后再问 respondsToSelector -> %d（runtime 把新加的方法当真的）",
              [r respondsToSelector:@selector(magicGreet)] ? 1 : 0]];

    gTrace = RTNewLog();
    RTFastForwarder *f = [RTFastForwarder new];
    id fastResult = [f performSelector:@selector(askName)];
    [RTL add:[NSString stringWithFormat:@"第 2 级 forwardingTargetForSelector:：替身接住 -> %@；顺序=%@；"
                                        @"原对象自己 respondsToSelector(askName)=%d（快转发不会让它「声称会」）",
              fastResult, RTJoin(gTrace), [f respondsToSelector:@selector(askName)] ? 1 : 0]];

    gTrace = RTNewLog();
    RTSlowForwarder *s = [RTSlowForwarder new];
    id slowResult = [s performSelector:@selector(anythingAtAll)];
    [RTL add:[NSString stringWithFormat:@"第 3 级 methodSignature + forwardInvocation:：连方法名都不存在 -> %@；顺序=%@",
              slowResult, RTJoin(gTrace)]];

    gTrace = RTNewLog();
    RTChain *c = [RTChain new];
    id chainResult = [c performSelector:@selector(nobodyHasThis)];
    [RTL add:[NSString stringWithFormat:@"把前两级主动放弃、只留第三级：-> %@；完整顺序=%@", chainResult, RTJoin(gTrace)]];

    gTrace = RTNewLog();
    RTChain *c2 = [RTChain new];
    id chainAgain = [c2 performSelector:@selector(nobodyHasThis)];
    [RTL add:[NSString stringWithFormat:@"同一个选标、换一个实例再问一次：-> %@；日志又走满 %lu 条（转发没有跨实例的缓存，每级都要重问）",
              chainAgain, (unsigned long)gTrace.count]];

    [RTL add:@"探针记录（只能记，不能跑）："];
    [RTL add:@"    ① 四级全放弃时 doesNotRecognizeSelector: 抛 NSInvalidArgumentException，stderr 是 "
                @"“*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[T noSuchMethodAtAll]: "
                @"unrecognized selector sent to instance 0x…'”，随后 SIGABRT；"];
    [RTL add:@"    ② 这个异常能被普通的 @try/@catch(NSException*) 接住（§17 同一套机制），所以“线上偶尔能看到 unrecognized selector 被 catch”不是幻觉；"];
    [RTL add:@"    ③ 第 1 级里 class_addMethod 的编码写成 @\"@\" 而 block 实际返回 NSString：编译无警告，调用方按 id 取值当场就是脏指针，"
                @"retain 时 SIGSEGV —— 编码串是唯一没人检查的部分。"];
    return [RTL end];
}

// ---------------------------------------------------------------- §9 换实现
@interface RTSwap : NSObject
- (void)doWork;
- (NSString *)label;
@end
@implementation RTSwap
- (void)doWork { RTLog(gTrace, @"doWork 本体"); }
- (NSString *)label { return @"label 本体"; }
@end

static IMP gOldLabelIMP = NULL;
static NSString *RTLabelHook(id self, SEL _cmd) {
    RTLog(gTrace, @"钩子:前");
    NSString *(*orig)(id, SEL) = (NSString *(*)(id, SEL))gOldLabelIMP;
    NSString *r = orig(self, _cmd);
    RTLog(gTrace, @"钩子:后");
    return [r stringByAppendingString:@"+钩子"];
}

NSArray<NSString *> *RTLinesSwizzle(void) {
    [RTL begin];
    Class cls = [RTSwap class];
    Method mDo = class_getInstanceMethod(cls, @selector(doWork));
    Method mLabel = class_getInstanceMethod(cls, @selector(label));
    IMP originalDo = method_getImplementation(mDo);
    IMP originalLabel = method_getImplementation(mLabel);
    [RTL add:[NSString stringWithFormat:@"动手前：doWork 编码=%s（首字母 v=返回 void，16=帧大小，@0 self 在第 0 字节、:8 _cmd 在第 8 字节）label 编码=%s（首字母 @=返回对象）",
              method_getTypeEncoding(mDo), method_getTypeEncoding(mLabel)]];
    [RTL add:[NSString stringWithFormat:@"    两个实现是两个不同的指针（只能比相等，不能打印值）：不相等=%d",
              originalDo != originalLabel ? 1 : 0]];

    gTrace = RTNewLog();
    RTSwap *t = [RTSwap new];
    [t doWork];
    [RTL add:[NSString stringWithFormat:@"① 交换前调 doWork：日志=%@", RTJoin(gTrace)]];

    method_exchangeImplementations(mDo, mLabel);
    gTrace = RTNewLog();
    [t doWork];                       // 名字还是 doWork，跑的是 label 的实现（它只返回字符串，不改日志板）
    [RTL add:[NSString stringWithFormat:@"    method_exchangeImplementations 之后调 doWork：日志=%@（空 —— 实际跑到了 label 的实现里）",
              RTJoin(gTrace)]];
    [RTL add:[NSString stringWithFormat:@"    编码挂在方法记录上、实现挂在 IMP 上：交换之后 doWork 的编码仍是 %s，label 仍是 %s"
                                        @"（换的只是实现指针，名字/签名/调用约定都不动）",
              method_getTypeEncoding(class_getInstanceMethod(cls, @selector(doWork))),
              method_getTypeEncoding(class_getInstanceMethod(cls, @selector(label)))]];
    [RTL add:@"    所以「拿 void 方法的返回值当对象用」这一步本章不敢跑：探针里那次它拿到的寄存器残留恰好还是个能 retain 的活对象，"
                @"连 hash 都跑通了（见 §9 末的探针记录）—— 不每次都崩才是最坏的情况。"];

    method_exchangeImplementations(class_getInstanceMethod(cls, @selector(doWork)),
                                   class_getInstanceMethod(cls, @selector(label)));
    gTrace = RTNewLog();
    [t doWork];
    [RTL add:[NSString stringWithFormat:@"    再交换一次就还原：调 doWork 的日志=%@", RTJoin(gTrace)]];

    gTrace = RTNewLog();
    Method labelNow = class_getInstanceMethod(cls, @selector(label));
    gOldLabelIMP = method_getImplementation(labelNow);
    method_setImplementation(labelNow, (IMP)RTLabelHook);
    NSString *hooked = [t label];
    [RTL add:[NSString stringWithFormat:@"② method_setImplementation（只换不交换）：调 label -> 「%@」，日志=%@",
              hooked, RTJoin(gTrace)]];
    [RTL add:@"    钩子里必须把旧 IMP 存下来直接调。探针记录：如果钩子里改写成了 [self label]，那就是自己调自己 —— "
                @"无限递归直到 SIGSEGV（栈溢出），而不是「先跑一遍原实现」。"];

    [RTL add:[NSString stringWithFormat:@"    钩子是**类级别**的：换实现之后再调 doWork 不产生任何钩子日志（条数=%lu），"
                                        @"但换一个新建的实例调 label 也一样被钩", (unsigned long)gTrace.count]];
    NSString *freshHooked = [[RTSwap new] label];
    [RTL add:[NSString stringWithFormat:@"    新实例的 label -> 「%@」（%@）", freshHooked,
              [freshHooked hasSuffix:@"+钩子"] ? @"确认：老IMP 返回的字符串 + 钩子后缀" : @"没生效"]];

    method_setImplementation(class_getInstanceMethod(cls, @selector(label)), originalLabel);
    gTrace = RTNewLog();
    NSString *restored = [[RTSwap new] label];
    [RTL add:[NSString stringWithFormat:@"    用存下来的 originalLabel 还原：label -> 「%@」，钩子日志条数=%lu",
              restored, (unsigned long)gTrace.count]];
    [RTL add:[NSString stringWithFormat:@"    最后确认 doWork 的 IMP 也还是原封不动的那个（相等=%d）—— 本节没留下任何改动给后面的小节",
              method_getImplementation(class_getInstanceMethod(cls, @selector(doWork))) == originalDo ? 1 : 0]];
    [RTL add:@"探针记录（交换签名不一致的那次调用，只能单独跑）："];
    [RTL add:@"    把 doWork/label 交换之后，用 __unsafe_unretained 接 [t label] 的返回值，再交给 ARC 并调 hash："];
    [RTL add:@"    after swap: doWork enc=v16@0:8 label enc=@16@0:8"];
    [RTL add:@"    unsafe_unretained 接到 void 实现的返回值：isNil=0"];
    [RTL add:@"    交给 ARC 之后还活着：140704254635504"];
    [RTL add:@"    —— 那次没崩，是因为寄存器里残留的正是一个还活着的对象；换一个时机它就是野指针，retain 时 SIGSEGV。"
                @"结论：交换只用在同签名方法之间（打补丁的惯用法就是「同名同签名的一进一出」），别拿它换返回类型。"];
    return [RTL end];
}

// ---------------------------------------------------------------- §12 KVC
@interface RTKVGetters : NSObject
- (NSString *)getName;
- (NSString *)name;
- (NSString *)isName;
@end
@implementation RTKVGetters
- (NSString *)getName { return @"方法 getName"; }
- (NSString *)name { return @"方法 name"; }
- (NSString *)isName { return @"方法 isName"; }
@end

@interface RTKVIvars : NSObject {
    NSString *_name;
    NSString *name;
    NSString *isName;
    NSString *_isName;
}
+ (instancetype)filled;
@end
@implementation RTKVIvars
+ (instancetype)filled {
    RTKVIvars *o = [self new];
    o->_name = @"下划线 ivar _name";
    o->name = @"裸 ivar name";
    o->isName = @"ivar isName";
    o->_isName = @"ivar _isName";
    return o;
}
@end

@interface RTKVCamel : NSObject { NSString *_theName; }
+ (instancetype)filled;
@end
@implementation RTKVCamel
+ (instancetype)filled {
    RTKVCamel *o = [self new];
    o->_theName = @"驼峰键也能命中下划线 ivar";
    return o;
}
@end

/// 和 RTKVIvars 内容一样，但拒绝「直接访问 ivar」
@interface RTKVNoIvarAccess : NSObject { NSString *_name; }
+ (instancetype)filled;
+ (BOOL)accessInstanceVariablesDirectly;
@end
@implementation RTKVNoIvarAccess
+ (instancetype)filled {
    RTKVNoIvarAccess *o = [self new];
    o->_name = @"只有 ivar";
    return o;
}
+ (BOOL)accessInstanceVariablesDirectly { return NO; }
@end

/// 下面四组用来「量」候选顺序：每次把上一轮的赢家拿掉，剩下的里谁赢就是下一个名次
@interface RTKVGettersNoGet : NSObject
- (NSString *)name;
- (NSString *)isName;
@end
@implementation RTKVGettersNoGet
- (NSString *)name { return @"方法 name"; }
- (NSString *)isName { return @"方法 isName"; }
@end
@interface RTKVGettersIsOnly : NSObject
- (NSString *)isName;
@end
@implementation RTKVGettersIsOnly
- (NSString *)isName { return @"方法 isName"; }
@end

@interface RTKVIvarsNoUnder : NSObject { NSString *name; NSString *isName; NSString *_isName; }
@end
@implementation RTKVIvarsNoUnder
@end
@interface RTKVIvarsNoIsUnder : NSObject { NSString *name; NSString *isName; }
@end
@implementation RTKVIvarsNoIsUnder
@end
@interface RTKVIvarsIsOnly : NSObject { NSString *isName; }
@end
@implementation RTKVIvarsIsOnly
@end

/// 用 runtime 自己按 ivar 名字填值，省得四个类各写一遍 init
static id RTNewIvars(Class cls, NSArray<NSString *> *names, NSArray<NSString *> *values) {
    id obj = [cls new];
    for (NSUInteger i = 0; i < names.count; i++) {
        Ivar iv = class_getInstanceVariable(cls, names[i].UTF8String);
        if (iv) object_setIvar(obj, iv, values[i]);
    }
    return obj;
}

/// 写值的候选：set<Key>: 与 _set<Key>: 同时存在，看谁被调到
@interface RTKVSetOrder : NSObject
@property (nonatomic, copy) NSString *hit;
- (void)setTag:(NSString *)x;
- (void)_setTag:(NSString *)x;
@end
@implementation RTKVSetOrder
- (void)setTag:(NSString *)x { _hit = @"set<Key>:"; }
- (void)_setTag:(NSString *)x { _hit = @"_set<Key>:"; }
@end
@interface RTKVSetOrderUnderOnly : NSObject
@property (nonatomic, copy) NSString *hit;
- (void)_setTag:(NSString *)x;
@end
@implementation RTKVSetOrderUnderOnly
- (void)_setTag:(NSString *)x { _hit = @"_set<Key>:"; }
@end
/// 一个 setter 都没有、只有 ivar：写值能不能落到 ivar
@interface RTKVWriteIvar : NSObject { NSString *_title; }
@end
@implementation RTKVWriteIvar
@end

@interface RTKVPerson : NSObject
@property (nonatomic, copy) NSString *nick;
@end
@implementation RTKVPerson
@end

NSArray<NSString *> *RTLinesKVC(void) {
    [RTL begin];
    [RTL add:@"读值时的候选顺序（先方法后 ivar，全部按名字猜）。量法：把上一轮的赢家拿掉，剩下的里谁赢就是下一个名次："];
    [RTL add:[NSString stringWithFormat:@"    三个候选方法都在 -> %@", [[RTKVGetters new] valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    拿掉 getName 只剩两个 -> %@", [[RTKVGettersNoGet new] valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    再拿掉 name 只剩 isName -> %@", [[RTKVGettersIsOnly new] valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    方法一个都没有，四个候选 ivar 都在 -> %@", [[RTKVIvars filled] valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    拿掉 _name（还剩裸 name / isName / _isName）-> %@",
              [RTNewIvars([RTKVIvarsNoUnder class],
                          @[ @"name", @"isName", @"_isName" ],
                          @[ @"裸 ivar name", @"ivar isName", @"ivar _isName" ]) valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    再拿掉 _isName（只剩裸 name 与 isName）-> %@",
              [RTNewIvars([RTKVIvarsNoIsUnder class],
                          @[ @"name", @"isName" ],
                          @[ @"裸 ivar name", @"ivar isName" ]) valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    最后只剩 isName -> %@",
              [RTNewIvars([RTKVIvarsIsOnly class], @[ @"isName" ], @[ @"ivar isName" ]) valueForKey:@"name"]]];
    [RTL add:[NSString stringWithFormat:@"    驼峰键 theName 命中 _theName -> %@", [[RTKVCamel filled] valueForKey:@"theName"]]];

    NSString *blocked = nil;
    @try {
        blocked = [[RTKVNoIvarAccess filled] valueForKey:@"name"];
    } @catch (NSException *e) {
        blocked = [NSString stringWithFormat:@"抛了 %@（关掉 accessInstanceVariablesDirectly 之后不再退到 ivar）", e.name];
    }
    [RTL add:[NSString stringWithFormat:@"    同样只有 ivar，但 +accessInstanceVariablesDirectly 返回 NO：读 name -> %@（对照组上面那条能读到）",
              blocked ?: @"(nil)"]];

    RTKVPerson *p = [RTKVPerson new];
    [p setValue:@"KVC 写进来的" forKey:@"nick"];
    [RTL add:[NSString stringWithFormat:@"写值：setValue:forKey: 实际调的就是 setNick: —— 点语法读到 %@；"
                                        @"key 是字符串，编译器一个字都不检查", p.nick]];
    RTKVSetOrder *so = [RTKVSetOrder new];
    [so setValue:@"两个 setter 都在" forKey:@"tag"];
    RTKVSetOrderUnderOnly *so2 = [RTKVSetOrderUnderOnly new];
    [so2 setValue:@"只剩带下划线的那个" forKey:@"tag"];
    [RTL add:[NSString stringWithFormat:@"    写值也是按名字猜：set<Key>: 与 _set<Key>: 同时存在 -> 调到的是 %@",
              so.hit]];
    [RTL add:[NSString stringWithFormat:@"    拿掉 set<Key>:、只剩 _set<Key>: -> 调到的还是 %@（第二个候选名真的会被查到）",
              so2.hit]];
    RTKVWriteIvar *wi = [RTKVWriteIvar new];
    NSString *writeFallback = @"(读不到)";
    @try {
        [wi setValue:@"没有 setter，直接写 ivar" forKey:@"title"];
        Ivar titleIvar = class_getInstanceVariable([RTKVWriteIvar class], "_title");
        writeFallback = object_getIvar(wi, titleIvar) ?: @"(nil)";
    } @catch (NSException *e) {
        writeFallback = [NSString stringWithFormat:@"抛了 %@", e.name];
    }
    [RTL add:[NSString stringWithFormat:@"    一个 setter 都没有、只有 ivar _title：写完之后用 object_getIvar 读回=%@（写值也会退到 ivar，和读值是同一套候选）",
              writeFallback]];
    [RTL add:[NSString stringWithFormat:@"字典也能被 KVC：@{@\"nick\":@\"字典里的\"} 的 valueForKey:@\"nick\" -> %@（走 objectForKey:，不是找属性）",
              [@{ @"nick": @"字典里的" } valueForKey:@"nick"]]];

    [RTL add:@"集合运算符（只有 valueForKeyPath: 认 @ 前缀）："];
    NSArray<NSNumber *> *nums = @[@3, @7, @1];
    id sum = [nums valueForKeyPath:@"@sum.integerValue"];
    [RTL add:[NSString stringWithFormat:@"    @sum.integerValue -> %@，实际类是 %@（不是普通 NSNumber，别拿它做 ==）",
              sum, NSStringFromClass([sum class])]];
    [RTL add:[NSString stringWithFormat:@"    @avg.floatValue=%@ @min.floatValue=%@ @max.floatValue=%@ @count=%@",
              [[nums valueForKeyPath:@"@avg.floatValue"] description],
              [[nums valueForKeyPath:@"@min.floatValue"] description],
              [[nums valueForKeyPath:@"@max.floatValue"] description],
              [[nums valueForKeyPath:@"@count"] description]]];
    [RTL add:@"    运算符后面那段（@sum.floatValue 里的 floatValue）是「对每个元素再取一次键」，写成 .self 就取元素本身。"];
    // 结果一律用 componentsJoinedByString 拼成一行：NSArray/NSSet 的 description 会打多行，「一行一条证据」就没了
    NSArray *distinctArr = [@[@"a", @"b", @"a"] valueForKeyPath:@"@distinctUnionOfObjects.self"];
    NSArray *unionArr = [@[@"a", @"b", @"a"] valueForKeyPath:@"@unionOfObjects.self"];
    NSArray *arraysArr = [@[@[@"a", @"b"], @[@"c"]] valueForKeyPath:@"@unionOfArrays.self"];
    [RTL add:[NSString stringWithFormat:@"    @distinctUnionOfObjects.self 去重：a,b,a -> %@；@unionOfObjects.self 不去重 -> %@",
              [distinctArr componentsJoinedByString:@" | "], [unionArr componentsJoinedByString:@" | "]]];
    [RTL add:[NSString stringWithFormat:@"    元素本身还是集合时要用 @unionOfArrays.self：[[a,b],[c]] -> %@",
              [arraysArr componentsJoinedByString:@" | "]]];
    id emptySum = [@[] valueForKeyPath:@"@sum.floatValue"];
    id emptyAvg = [@[] valueForKeyPath:@"@avg.floatValue"];
    id emptyMin = [@[] valueForKeyPath:@"@min.floatValue"];
    id emptyCount = [@[] valueForKeyPath:@"@count"];
    [RTL add:[NSString stringWithFormat:@"    空数组：@sum=%@ @count=%@（这俩给 0），@avg=%@ @min=%@（这俩直接是 nil）—— "
                                        @"「取个值塞进 NSInteger」就会在这里静默变成 0",
              emptySum ?: @"(nil)", emptyCount ?: @"(nil)", emptyAvg ? [emptyAvg description] : @"(nil)",
              emptyMin ? [emptyMin description] : @"(nil)"]];

    [RTL add:@"to-many 集合上的 KVC 会广播："];
    RTKVPerson *a = [RTKVPerson new];
    RTKVPerson *b = [RTKVPerson new];
    a.nick = @"甲";
    b.nick = @"乙";
    NSArray *people = @[a, b];
    NSArray *plucked = [people valueForKey:@"nick"];
    [RTL add:[NSString stringWithFormat:@"    [people valueForKey:@\"nick\"] -> %@（pluck 出一个新数组，顺序跟 people 一致；元素自己不会响应 nick，靠广播）",
              [plucked componentsJoinedByString:@" | "]]];
    [people setValue:@"批量写入" forKey:@"nick"];
    [RTL add:[NSString stringWithFormat:@"    [people setValue:forKey:@\"nick\"] 之后：a.nick=%@ b.nick=%@（两个都被写）", a.nick, b.nick]];
    NSSet *set = [NSSet setWithArray:@[a, b]];
    id setPluckedRaw = [set valueForKey:@"nick"];
    NSArray *setPlucked = [[setPluckedRaw allObjects] sortedArrayUsingSelector:@selector(compare:)];
    [RTL add:[NSString stringWithFormat:@"    NSSet 上同样能广播，读回来的类型是 %@（%lu 个元素；两个人现在值一样，集合并成了 1 个 —— 集合不保证顺序，所以排序后才打：%@）",
              NSStringFromClass([setPluckedRaw class]), (unsigned long)setPlucked.count,
              [setPlucked componentsJoinedByString:@" | "]]];
    NSMutableArray *empty = [NSMutableArray new];
    NSString *emptyResult = @"没抛";
    @try {
        [empty setValue:@"没人可广播" forKey:@"nick"];
    } @catch (NSException *e) {
        emptyResult = [NSString stringWithFormat:@"抛了 %@", e.name];
    }
    [RTL add:[NSString stringWithFormat:@"    空数组上广播：count=%lu，结果=%@（一个元素都没有，等于什么都没做，也不报错）",
              (unsigned long)empty.count, emptyResult]];

    [RTL add:@"    探针记录：@first / @last 这两个「文档里列了」的运算符在 iOS 18 的 Foundation 上根本没实现，"
                @"[nums valueForKeyPath:@\"@first.floatValue\"] 直接抛 NSInvalidArgumentException："
                @"“[<NSConstantArray 0x…> valueForKeyPath:]: this class does not implement the first operation.”（@last 同一条，把 first 换成 last）—— "
                @"想拿首尾元素就老实写 firstObject / lastObject。"];
    [RTL add:@"    ① [obj valueForKey:@\"没这个键\"] -> NSUnknownKeyException，reason 是 "
                @"“[<类名 0x…> valueForUndefinedKey:]: this class is not key value coding-compliant for the key 没这个键.”；"];
    [RTL add:@"    ② [obj setValue:nil forKey:@\"一个 int 属性\"] -> NSInvalidArgumentException，reason 是 "
                @"“[<类名 0x…> setNilValueForKey]: could not set nil as the value for the key ….” —— 给标量键传 nil 一定要先挡掉；"];
    [RTL add:@"    ③ 这两条正是「字典转模型遇到多余字段就崩」「xib 连线连到已删掉的属性上就崩」的底层原因：KVC 的键是字符串，编译期无人把关。"];
    return [RTL end];
}

// ---------------------------------------------------------------- §13 KVO
@interface RTKVOSubject : NSObject
@property (nonatomic, assign) int counter;
@property (nonatomic, copy) NSString *title;
@end
@implementation RTKVOSubject
@end

@interface RTKVOObserver : NSObject
@end
@implementation RTKVOObserver
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    NSMutableArray *keys = [[change allKeys] mutableCopy];
    [keys sortUsingSelector:@selector(compare:)];
    RTLog(gTrace, [NSString stringWithFormat:@"%@ kind=%@ keys=%@ ctx=%@",
                   keyPath, change[NSKeyValueChangeKindKey],
                   [keys componentsJoinedByString:@","],
                   context == (void *)0x1 ? @"1" : (context ? @"其它" : @"NULL")]);
}
@end

/// 自己发 willChange/didChange 的「手动 KVO」属性
@interface RTKVOManual : NSObject { int _value; }
@property (nonatomic, assign) int value;
@end
@implementation RTKVOManual
- (void)setValue:(int)value {
    [self willChangeValueForKey:@"value"];
    _value = value;
    [self didChangeValueForKey:@"value"];
}
@end

NSArray<NSString *> *RTLinesKVO(void) {
    [RTL begin];
    RTKVOSubject *obj = [RTKVOSubject new];
    RTKVOObserver *obs = [RTKVOObserver new];

    [RTL add:[NSString stringWithFormat:@"加观察之前：object_getClass(obj)=%s，[obj class]=%s（两个一样）",
              class_getName(object_getClass(obj)), class_getName([obj class])]];
    gTrace = RTNewLog();
    [obj addObserver:obs forKeyPath:@"counter"
             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
             context:(void *)0x1];
    [RTL add:[NSString stringWithFormat:@"加完观察：object_getClass(obj)=%s，而 [obj class] 仍是 %s —— "
                                        @"KVO 把 isa 换成一个偷偷生成的子类，但重写 -class 让你看不出来",
              class_getName(object_getClass(obj)), class_getName([obj class])]];
    Class isa = object_getClass(obj);
    unsigned propCount = 0;
    free((void *)class_copyPropertyList(isa, &propCount));
    NSArray<NSString *> *kvoOwn = RTOwnMethodNames(isa);
    [RTL add:[NSString stringWithFormat:@"    这个动态子类的父类=%s；它自己列出的属性数=%u；它**自己**的方法表（已排序）=%@ —— "
                                        @"里面只有这几条：覆盖 setter 来发通知、覆盖 -class 把换脸藏住、覆盖 -dealloc 做收尾，外加一个 _isKVOA 标记；"
                                        @"注意表里并没有 isMemberOfClass:（它怎么还能答对，见 §14）",
              class_getName(class_getSuperclass(isa)), propCount,
              [kvoOwn componentsJoinedByString:@" "]]];

    [RTL add:@"    同一件事用 class_getInstanceMethod 问也返回非空，所以那个 API 证明不了覆盖 —— "
                @"它沿继承链往上找，父类本来就有 setCounter:（上面那段用的是 class_copyMethodList，只看这一层）"];


    [RTL add:[NSString stringWithFormat:@"    options 里有 Initial，所以注册当场就通知一次：%@", RTJoin(gTrace)]];

    gTrace = RTNewLog();
    obj.counter = 5;
    [RTL add:[NSString stringWithFormat:@"走 setter（obj.counter = 5）-> %@", RTJoin(gTrace)]];
    gTrace = RTNewLog();
    obj.counter = 5;
    [RTL add:[NSString stringWithFormat:@"    再赋一次同样的值 5 -> 日志条数=%lu（NSNumber 属性也照发，KVO 不做「值变了才通知」的判断）",
              (unsigned long)gTrace.count]];

    gTrace = RTNewLog();
    Ivar backing = class_getInstanceVariable([RTKVOSubject class], "_counter");
    int *slot = (int *)((char *)(__bridge void *)obj + ivar_getOffset(backing));
    *slot = 42;
    [RTL add:[NSString stringWithFormat:@"绕过 setter、按 ivar 偏移直写 _counter（属性读到=%d）-> 日志条数=%lu —— KVO 挂在 setter 上，不轮询内存",
              obj.counter, (unsigned long)gTrace.count]];
    gTrace = RTNewLog();
    [obj willChangeValueForKey:@"counter"];
    NSUInteger mid = gTrace.count;
    [obj didChangeValueForKey:@"counter"];
    [RTL add:[NSString stringWithFormat:@"手动 willChange 单独一次：通知条数=%lu；补上 didChange 之后总数=%lu —— "
                                        @"通知是在 didChange 时发的（ %@）",
              (unsigned long)mid, (unsigned long)gTrace.count, RTJoin(gTrace)]];

    gTrace = RTNewLog();
    obj.title = @"换个没被观察的键";
    [RTL add:[NSString stringWithFormat:@"改一个没观察的属性 title -> 日志条数=%lu（挂钩是按 keyPath 分别建立的）", (unsigned long)gTrace.count]];

    gTrace = RTNewLog();
    [obj addObserver:obs forKeyPath:@"counterTypo" options:0 context:NULL];
    obj.counter = 8;
    [RTL add:[NSString stringWithFormat:@"拼错的键路径不会当场报错：注册 @\"counterTypo\" 成功（isa=%s），但改 counter 的日志条数=%lu —— "
                                        @"静默失效，比崩溃更难查",
              class_getName(object_getClass(obj)), (unsigned long)gTrace.count]];
    [obj removeObserver:obs forKeyPath:@"counterTypo" context:NULL];

    gTrace = RTNewLog();
    [obj removeObserver:obs forKeyPath:@"counter" context:(void *)0x1];
    obj.counter = 9;
    [RTL add:[NSString stringWithFormat:@"按 context 精确取消之后：isa 恢复成 %s，再改 counter 的日志条数=%lu",
              class_getName(object_getClass(obj)), (unsigned long)gTrace.count]];
    gTrace = RTNewLog();
    obj.counter = 10;
    [RTL add:[NSString stringWithFormat:@"    再确认一次已经彻底摘干净：日志条数=%lu", (unsigned long)gTrace.count]];

    RTKVOManual *m = [RTKVOManual new];
    RTKVOObserver *obs2 = [RTKVOObserver new];
    gTrace = RTNewLog();
    [m addObserver:obs2 forKeyPath:@"value" options:0 context:NULL];
    m.value = 3;
    [RTL add:[NSString stringWithFormat:@"自定义 setter + 手动 willChange/didChange 也能被观察：%@", RTJoin(gTrace)]];
    [m removeObserver:obs2 forKeyPath:@"value" context:NULL];

    [RTL add:@"探针记录（KVO 的四条只能记不跑）："];
    [RTL add:@"    ① iOS 上根本没有两参数版的 -addObserver:forKeyPath:（那是 macOS 的旧接口），写出来编译报 "
                @"error: no visible @interface for 'X' declares the selector 'addObserver:forKeyPath:' —— 必须用四参数 options:context:；"];
    [RTL add:@"    ② 观察者没实现 observeValueForKeyPath:ofObject:change:context:（也没转给 super）时抛 NSInternalInconsistencyException："
                @"“<观察者>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.” 然后 SIGABRT；"];
    [RTL add:@"    ③ 取消一个并不存在的观察抛 NSRangeException：“Cannot remove an observer <A 0x…> for the key path \"k\" from <B 0x…> "
                @"because it is not registered as an observer.” —— 探针里把观察者搞反时，报错打出来的地址看着像被观察对象，很容易认错人；"];
    [RTL add:@"    ④ 同一观察者对同一路径注册两次不报错（探针：两次 add 都成功），但一次 remove 只消一层，剩下那层会在对象释放后继续通知 —— "
                @"KVO 的经典崩溃就这么来的；要么配 context 精确移除，要么用 block 版封装保证只注册一次。"];
    return [RTL end];
}

// ---------------------------------------------------------------- §14 内省
@interface RTIntBase : NSObject
- (void)onlyOnBase;
@end
@implementation RTIntBase
- (void)onlyOnBase {}
@end

@interface RTIntSub : RTIntBase <NSCopying>
- (void)onlyOnSub;
+ (void)subClassOnly;
@end
@implementation RTIntSub
- (void)onlyOnSub {}
+ (void)subClassOnly {}
- (id)copyWithZone:(NSZone *)zone { return [[RTIntSub allocWithZone:zone] init]; }
@end

NSArray<NSString *> *RTLinesIntrospection(void) {
    [RTL begin];
    RTIntSub *sub = [RTIntSub new];
    RTIntBase *base = [RTIntBase new];
    NSString *str = @"我不是 RTIntSub";

    [RTL add:@"四个最容易混的内省问题："];
    [RTL add:[NSString stringWithFormat:@"    [sub isKindOfClass:RTIntBase]=%d（含祖先）vs [sub isMemberOfClass:RTIntBase]=%d（只看自己）",
              [sub isKindOfClass:[RTIntBase class]] ? 1 : 0, [sub isMemberOfClass:[RTIntBase class]] ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    [sub isMemberOfClass:RTIntSub]=%d（自己当然是）；[base isKindOfClass:RTIntSub]=%d（父类不是子类）",
              [sub isMemberOfClass:[RTIntSub class]] ? 1 : 0, [base isKindOfClass:[RTIntSub class]] ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    [str isKindOfClass:RTIntSub]=%d；[nil isKindOfClass:任何类]=%d（nil 接收者返回 NO，不崩，所以 `if (![x isKindOfClass:]) return;` 对 nil 也安全）",
              [str isKindOfClass:[RTIntSub class]] ? 1 : 0, [(id)nil isKindOfClass:[RTIntSub class]] ? 1 : 0]];

    [RTL add:@"    最后一组给「判类型该用哪个」定实测边界：拿 §13 那个会被 KVO 换脸的对象再问一遍："];
    RTKVOSubject *kv = [RTKVOSubject new];
    RTKVOObserver *kvObs = [RTKVOObserver new];
    [RTL add:[NSString stringWithFormat:@"        没人观察它的时候：isKindOfClass=%d，isMemberOfClass=%d，object_getClass=%s",
              [kv isKindOfClass:[RTKVOSubject class]] ? 1 : 0,
              [kv isMemberOfClass:[RTKVOSubject class]] ? 1 : 0,
              class_getName(object_getClass(kv))]];
    [kv addObserver:kvObs forKeyPath:@"counter" options:0 context:NULL];
    [RTL add:[NSString stringWithFormat:@"        换脸期间：isKindOfClass=%d，isMemberOfClass=%d，[kv class]=%@ —— 三个答案和上面一模一样，"
                @"「KVO 会让 isMemberOfClass: 翻脸」这个流行说法在这里被实测否定",
              [kv isKindOfClass:[RTKVOSubject class]] ? 1 : 0,
              [kv isMemberOfClass:[RTKVOSubject class]] ? 1 : 0,
              NSStringFromClass([kv class])]];
    [RTL add:[NSString stringWithFormat:@"        为什么没覆盖也能答对：动态子类自己的方法表里 isMemberOfClass: 查得到=%d（§13 那张表里没有它），"
                @"可答案仍然是「是这个类的成员」—— 只能说明 NSObject 的 -isMemberOfClass: 内部是拿 [self class] 去比对的，"
                @"而 -class 被 KVO 覆盖了，所以它跟着一起被带偏（这条是从两个实测结果推出来的，不是背来的）",
              RTClassOwnsMethod(object_getClass(kv), @selector(isMemberOfClass:)) ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"        唯一的破绽在 runtime 那条路上：object_getClass=%s —— 内省四问没有一个能告发 KVO",
              class_getName(object_getClass(kv))]];

    [kv removeObserver:kvObs forKeyPath:@"counter" context:NULL];
    [RTL add:[NSString stringWithFormat:@"        摘掉观察者：object_getClass 恢复成 %s（对照 §13 的 isa 换回来），四问的答案从头到尾就没变过",
              class_getName(object_getClass(kv))]];

    [RTL add:[NSString stringWithFormat:@"类与元类：object_getClass(实例)=%s；object_getClass(RTIntSub 这个类)=%s；"
                                        @"class_isMetaClass(RTIntSub)=%d，class_isMetaClass(它的元类)=%d",
              class_getName(object_getClass(sub)), class_getName(object_getClass([RTIntSub class])),
              class_isMetaClass([RTIntSub class]) ? 1 : 0,
              class_isMetaClass(object_getClass([RTIntSub class])) ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    元类的父类=%s（NSObject 是根，它的元类的 superclass 就是 NSObject）；"
                                        @"[sub class] 和 object_getClass(sub) 相等=%d（没被 KVO 换 isa 时两者一样）",
              class_getName(class_getSuperclass(object_getClass([RTIntSub class]))),
              [sub class] == object_getClass(sub) ? 1 : 0]];

    unsigned ownMethods = 0;
    Method *ms = class_copyMethodList([RTIntSub class], &ownMethods);
    NSMutableArray<NSString *> *ownList = [NSMutableArray array];
    for (unsigned i = 0; i < ownMethods; i++) {
        [ownList addObject:NSStringFromSelector(method_getName(ms[i]))];
    }
    free((void *)ms);
    [RTL add:[NSString stringWithFormat:@"方法从哪里来：class_copyMethodList(RTIntSub) 只列本类的 %u 个（%@，已排序），"
                                        @"但 class_getInstanceMethod(RTIntSub, onlyOnBase) 也找得到=%d —— 后者会沿继承链往上找",
              ownMethods, [[ownList sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@" "],
              class_getInstanceMethod([RTIntSub class], @selector(onlyOnBase)) ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    实例方法版：[sub respondsToSelector:onlyOnBase]=%d，"
                                        @"[RTIntSub instancesRespondToSelector:onlyOnBase]=%d（问的是「这个类的实例会不会」，不用造对象）",
              [sub respondsToSelector:@selector(onlyOnBase)] ? 1 : 0,
              [RTIntSub instancesRespondToSelector:@selector(onlyOnBase)] ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    类方法版：[RTIntSub respondsToSelector:subClassOnly]=%d，"
                                        @"[RTIntBase respondsToSelector:subClassOnly]=%d（类方法也继承，但只在子类这层加的方法父类问不到）",
              [RTIntSub respondsToSelector:@selector(subClassOnly)] ? 1 : 0,
              [RTIntBase respondsToSelector:@selector(subClassOnly)] ? 1 : 0]];
    [RTL add:[NSString stringWithFormat:@"    问一个没实现的选标：[sub respondsToSelector:绝不存在]=%d（返回 NO，不崩）",
              [sub respondsToSelector:NSSelectorFromString(@"绝不存在")] ? 1 : 0]];

    unsigned adoptedCount = 0;
    free((void *)class_copyProtocolList([RTIntSub class], &adoptedCount));
    [RTL add:[NSString stringWithFormat:@"协议采纳：[RTIntSub conformsToProtocol:NSCopying]=%d，[RTIntBase 同样的问题]=%d，"
                                        @"实例也能问 [sub conformsToProtocol:NSCopying]=%d；class_copyProtocolList(RTIntSub)=%u 个（它自己写的 <NSCopying>）",
              [RTIntSub conformsToProtocol:@protocol(NSCopying)] ? 1 : 0,
              [RTIntBase conformsToProtocol:@protocol(NSCopying)] ? 1 : 0,
              [sub conformsToProtocol:@protocol(NSCopying)] ? 1 : 0,
              adoptedCount]];

    [RTL add:[NSString stringWithFormat:@"按名字找类：objc_getClass(\"RTIntSub\")=%s；NSClassFromString(@\"RTIntSub\")=%s；"
                                        @"查一个没有的名字 -> %@",
              class_getName(objc_getClass("RTIntSub")), class_getName(NSClassFromString(@"RTIntSub")),
              objc_getClass("绝没有这个类") ? @"居然找到了" : @"NULL（不崩）"]];

    Class built = objc_allocateClassPair([NSObject class], "RTBuilt", 0);
    NSString *builtResult = @"(分配失败)";
    if (built) {
        IMP imp = imp_implementationWithBlock(^NSString *(id self) { return @"动态注册出来的类的方法"; });
        if (class_addMethod(built, @selector(hey), imp, "@@:")) {
            objc_registerClassPair(built);
            id instance = [[NSClassFromString(@"RTBuilt") alloc] init];
            builtResult = [instance performSelector:@selector(hey)];
        }
    }
    [RTL add:[NSString stringWithFormat:@"运行时造一个类：objc_allocateClassPair + class_addMethod + objc_registerClassPair，"
                                        @"之后用 NSClassFromString(@\"RTBuilt\") 实例化并调 hey -> %@", builtResult]];
    Class again = objc_getClass("RTBuilt");
    [RTL add:[NSString stringWithFormat:@"    拿同一个名字再分配一次：objc_allocateClassPair 返回 %@（重复分配得到 nil，不崩；"
                                        @"进程内注册的类总数是随系统变化的大数，不能拿来断言）",
              objc_allocateClassPair([NSObject class], "RTBuilt", 0) ? @"非 nil" : @"nil"]];
    (void)again;
    return [RTL end];
}

// ---------------------------------------------------------------- §15 对象通信
@protocol RTCommDelegate <NSObject>
@optional
- (BOOL)sourceShouldFire:(id)source;
@end

@interface RTCommSink : NSObject { NSInteger _hits; }
@property (nonatomic, readonly) NSInteger hits;
- (void)onTap;
- (void)onTapFrom:(id)sender;
@end
@implementation RTCommSink
- (NSInteger)hits { return _hits; }
- (void)onTap { _hits += 1; }
- (void)onTapFrom:(id)sender { _hits += (sender ? 10 : 1); }
@end

@interface RTCommSource : NSObject
@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, strong) id<RTCommDelegate> delegate;
- (NSInteger)fire;
- (NSInteger)fireWithSender:(id)sender;
@end

@implementation RTCommSource
- (NSInteger)fire {
    if ([self.delegate respondsToSelector:@selector(sourceShouldFire:)] &&
        ![self.delegate sourceShouldFire:self]) {
        return -1;                       // 被 delegate 一票否决
    }
    id t = self.target;
    if (t && [t respondsToSelector:self.action]) {
        ((void (*)(id, SEL))objc_msgSend)(t, self.action);
        return [(RTCommSink *)self.target hits];
    }
    return -2;                           // 没人接，静默失败
}
- (NSInteger)fireWithSender:(id)sender {
    id t = self.target;
    if (t && [t respondsToSelector:self.action]) {
        ((void (*)(id, SEL, id))objc_msgSend)(t, self.action, sender);
        return [(RTCommSink *)self.target hits];
    }
    return -2;
}
@end

@interface RTCommGate : NSObject <RTCommDelegate>
@end
@implementation RTCommGate
- (BOOL)sourceShouldFire:(id)source { return NO; }
@end

NSArray<NSString *> *RTLinesCommunication(void) {
    [RTL begin];
    RTCommSource *src = [RTCommSource new];
    RTCommSink *sink = [RTCommSink new];
    src.target = sink;
    src.action = @selector(onTap);
    [src fire];
    [src fire];
    [RTL add:[NSString stringWithFormat:@"目标-动作：SEL 当数据存着、target 当对象存着，运行时才 objc_msgSend —— 触发两次后 sink.hits=%ld "
                                        @"（这就是 UIControl 那套东西的最小模型：发送方编译期完全不认识接收方）",
              (long)sink.hits]];
    src.action = @selector(onTapFrom:);
    [src fireWithSender:src];
    [RTL add:[NSString stringWithFormat:@"    换成带 sender 的动作：hits 从 2 跳到 %ld（一次 +10）—— sender 就是这么传过去的",
              (long)sink.hits]];
    src.target = nil;
    NSInteger quiet = [src fireWithSender:src];
    [RTL add:[NSString stringWithFormat:@"    target 置 nil 再触发：返回 %ld、hits 仍是 %ld（整个调用无声消失 —— 控件「点了没反应」多半就是这个）",
              (long)quiet, (long)sink.hits]];
    src.target = sink;
    src.action = @selector(压根没有这个方法);
    NSInteger missing = [src fireWithSender:src];
    [RTL add:[NSString stringWithFormat:@"    action 写成不存在的选标：@selector 编译得过，但 respondsToSelector 拦下了，返回 %ld"
                                        @"（少了这句判断，就是 §8 结尾那条 unrecognized selector 崩溃）", (long)missing]];

    src.action = @selector(onTap);
    src.delegate = [RTCommGate new];
    NSInteger vetoed = [src fire];
    [RTL add:[NSString stringWithFormat:@"委托（delegate）：@optional 的方法必须先 respondsToSelector 再问，这次 gate 说不给发 -> 返回 %ld、hits=%ld"
                                        @"（一对一、由被通知的一方决定；数据源是它「只负责供数据」的特例）",
              (long)vetoed, (long)sink.hits]];
    src.delegate = nil;
    [src fire];
    [RTL add:[NSString stringWithFormat:@"    不设 delegate 时那段判断直接跳过：hits=%ld（委托为 nil 是常态，不是错误）", (long)sink.hits]];

    [RTL add:@"通告（NSNotificationCenter）：一对多、按名字广播，发送方不知道谁在听 —— 实际收发在 Swift 侧跑（见 §21）："];
    [RTL add:@"    两条容易记反的规则（§21 实测）：block 版 addObserver(forName:object:queue:using:) **不会**自动解绑，"
                @"忘了 removeObserver 就是「对象都释放了还被叫起来干活」；selector 版 addObserver:selector:object:queue: 反而会自动解绑；"];
    [RTL add:@"    中心是全局的：名字拼错 = 永远收不到（编译器不管），所以通知名一律用常量，别散着写字符串。"];
    [RTL add:@"    目标-动作 / 委托 / 通知三者怎么选：一个控件对一个处理者用 target-action；一个对象问另一个对象「能不能」用 delegate；"
                @"多处想知道同一件事才用 notification。绑定（KVO 之外 macOS 的 Cocoa Bindings）iOS 上没有。"];
    return [RTL end];
}
