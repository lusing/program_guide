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

        // -------------------------------------------------- 1) 消息发送
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

        // -------------------------------------------------- 2) 属性与点语法
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

        // -------------------------------------------------- 3) id / SEL / 动态派发
        line(@"");
        line(@"== id / SEL / 动态性 ==");
        id obj = p;                        // id = 「任意对象指针」，无需星号
        expect([obj isKindOfClass:[Person class]], @"isKindOfClass: 运行时判类型");
        SEL sel = @selector(greeting);     // SEL = 方法名的运行时表示
        expect([p respondsToSelector:sel], @"respondsToSelector: 问对象会不会这个方法");
        // performSelector: 在 ARC 下会报 -Warc-performSelector-leaks：编译器不知道
        // 这个动态 selector 返回的对象该不该 release，怕泄漏。这是 OC 真实的坑，
        // 标准做法是用 pragma 局部静音（并在心里清楚风险）。详见文档 4.3 节。
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

        // -------------------------------------------------- 4) 协议（多态）
        line(@"");
        line(@"== 协议 protocol ==");
        id<Speaker> s = p;                 // 面向协议编程：只认 Speaker，不认 Person
        NSString *said = [s speakTimes:2];
        expect([said containsString:@"Ada"], @"通过协议调用 required 方法");
        expect([[said componentsSeparatedByString:@" / "] count] == 2, @"speakTimes:2 说了两遍");

        // -------------------------------------------------- 5) 分类
        line(@"");
        line(@"== 分类 category ==");
        expect([[p vipGreeting] hasPrefix:@"[VIP]"], @"分类方法已合并进 Person");
        expect([p isKindOfClass:[Person class]], @"分类不改变类型，运行时同一张方法表");

        // -------------------------------------------------- 6) block（闭包）
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

        // -------------------------------------------------- 7) NSError 二级指针
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

        // -------------------------------------------------- 8) description / %@
        line(@"");
        line(@"== description 与 %@ ==");
        NSString *desc = [NSString stringWithFormat:@"%@", p];   // %@ 走 description
        expect([desc containsString:@"Alan"], @"%@ 打印的是重写后的 description");
        expect([desc hasPrefix:@"<Person"], @"description 格式符合自定义");

        // -------------------------------------------------- 9) OC 里的 UIKit 一瞥
        line(@"");
        line(@"== OC 调 UIKit ==");
        UILabel *label = [[UILabel alloc] init];
        label.text = [p greeting];
        [label sizeToFit];
        expect(label.text.length > 0, @"OC 一样能构造 UIKit 控件");
        UIColor *c = [UIColor systemBlueColor];
        expect(c != nil, @"OC 调 UIKit 类方法（systemBlueColor）");

        line(@"");
        if (gFailures == 0) { line(@"全部断言通过。"); }
        else { line([NSString stringWithFormat:@"有 %d 条断言失败。", gFailures]); }
        printf("==== 04 结束 ====\n");
    }
    return gFailures == 0 ? 0 : 1;
}
