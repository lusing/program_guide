// ============================================================
// 04 - Objective-C 语言基础（纯 Foundation，不碰界面）
//   类与属性 / 协议 / 分类 / block / ARC / SEL / NSError / nil 消息
//
// 编译（本目录有多个 .m，入口会一起编）：
//   clang -O2 -std=gnu11 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
//         -isysroot $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 -I . \
//         Person.m NSString+Extras.m main.m -o 04_objc_language \
//         -framework Foundation -framework AppKit
// 运行：
//   ./04_objc_language --selftest
//
// 本教程里所有 Objective-C 示例都用 printf 而不是 NSLog：
// NSLog 写的是系统日志（stderr），验证脚本要求「stderr 为空」，用它就全判失败。
// ============================================================

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Person.h"
#import "NSString+Extras.h"

static void line(void) { printf("--------------------------------------------------\n"); }

int main(void) {
    @autoreleasepool {
        line();
        printf("== 1) 消息发送与目标对象 ==\n");

        Person *person = [[Person alloc] initWithName:@"小明" age:30];
        printf("类         : %s\n", NSStringFromClass([person class]).UTF8String);
        printf("父类       : %s\n", NSStringFromClass([person superclass]).UTF8String);
        printf("是不是 Person : %s\n", [person isKindOfClass:[Person class]] ? "true" : "false");
        printf("是不是 NSString : %s\n", [person isKindOfClass:[NSString class]] ? "true" : "false");
        printf("greeting   : %s\n", [person greeting].UTF8String);
        printf("description: %s\n", person.description.UTF8String);

        line();
        printf("== 2) nil 消息：Objective-C 最省心也最容易误判的一条规则 ==\n");
        Person *nobody = nil;
        printf("发给 nil 的返回值 : %s\n", [nobody greeting] == nil ? "nil" : "有值");
        printf("向 nil 取值      : %ld\n", (long)[nobody lengthOfName]);
        // 注意：对 nil 取结构体返回值是「未定义」的（某些架构上返回未初始化的垃圾），
        // 所以这里只演示结论，不打印具体数值 —— 打印出来会随架构、随编译器变。
        printf("向 nil 取 struct : 未定义（不要依赖）\n");
        printf("多次发送安全      : %s\n", [[[nobody greeting] description] length] == 0 ? "true" : "false");

        line();
        printf("== 3) SEL 与动态性 ==\n");
        SEL greetingSel = @selector(greeting);
        printf("selector 名字 : %s\n", NSStringFromSelector(greetingSel).UTF8String);
        printf("有没有这个键 : %s\n", [person respondsToSelector:greetingSel] ? "true" : "false");
        printf("有没有这个键 : %s\n", [person respondsToSelector:@selector(flyToMoon)] ? "true" : "false");

        // ARC 下 performSelector 会报警告：编译器不知道这个 selector 的返回值该由谁持有。
        // 正确的现代写法是 NSInvocation 或者直接调用；这里为了演示保留它并显式关掉这条警告。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSString *viaPerform = [person performSelector:greetingSel];
#pragma clang diagnostic pop
        printf("performSelector: %s\n", viaPerform.UTF8String);
        printf("和直接调用一致 : %s\n", [viaPerform isEqualToString:[person greeting]] ? "true" : "false");

        Class cls = NSClassFromString(@"Person");
        printf("NSClassFromString(\"Person\") : %s\n", NSStringFromClass(cls).UTF8String);
        printf("NSClassFromString(\"NotExist\") : %s\n", NSClassFromString(@"NotExist") == Nil ? "Nil" : "有");

        line();
        printf("== 4) 协议与分类 ==\n");
        id<Speaker> speaker = person;
        printf("遵循 Speaker 协议 : %s\n", [person conformsToProtocol:@protocol(Speaker)] ? "true" : "false");
        printf("协议方法     : %s\n", [speaker speakTimes:2].UTF8String);
        printf("分类方法（字符串倒序）: %s\n", [@"abcdef" mx_reversedString].UTF8String);
        printf("分类方法（再倒一次）: %s\n", [[@"abcdef" mx_reversedString] mx_reversedString].UTF8String);

        line();
        printf("== 5) block ==\n");
        NSInteger (^doubler)(NSInteger) = ^NSInteger(NSInteger value) {
            return value * 2;
        };
        printf("block 调用 : %ld\n", (long)doubler(21));

        __block NSMutableString *trace = [NSMutableString string];
        void (^recorder)(NSString *) = ^(NSString *label) {
            // __block 让外部变量在 block 里可写；block 会自动 copy 捕获取的对象
            [trace appendFormat:@"%@ ", label];
        };
        recorder(@"一");
        recorder(@"二");
        recorder(@"三");
        printf("__block 累积 : %s\n", trace.UTF8String);

        NSArray *words = @[@"pear", @"apple", @"orange"];
        NSArray *sorted = [words sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
            if (a.length != b.length) {
                return a.length < b.length ? NSOrderedAscending : NSOrderedDescending;
            }
            return [a compare:b];
        }];
        printf("按长度排序 : %s\n", [sorted componentsJoinedByString:@","].UTF8String);

        line();
        printf("== 6) NSError：Objective-C 的「异常替代品」 ==\n");
        NSError *shortError = nil;
        BOOL shortOk = [person renameTo:@"" error:&shortError];
        printf("空名字是否成功 : %s\n", shortOk ? "true" : "false");
        printf("错误域     : %s\n", shortError.domain.UTF8String);
        printf("错误码     : %ld\n", (long)shortError.code);
        printf("本地化描述 : %s\n", shortError.localizedDescription.UTF8String);

        NSError *goodError = nil;
        BOOL goodOk = [person renameTo:@"小红" error:&goodError];
        printf("合法改名   : %s\n", goodOk ? "true" : "false");
        printf("成功后 error 必须被忽略 : %s\n", goodError == nil ? "nil（约定如此）" : "有值（约定破坏了）");
        printf("新名字     : %s\n", person.name.UTF8String);

        line();
        printf("== 7) Foundation 里的原生工厂与容错 ==\n");
        NSArray *maybe = [NSArray array];
        printf("空数组 firstObject : %s\n", maybe.firstObject == nil ? "nil" : "有值");
        printf("越界取值会抛异常，所以先数一遍 : %lu\n", (unsigned long)maybe.count);
        NSDictionary *dict = @{@"k": @"v"};
        printf("字面量字典 : %s\n", [dict[@"k"] UTF8String]);
        printf("查不存在键 : %s\n", dict[@"nope"] == nil ? "nil" : "有值");
        NSNumber *boxed = @(42);
        printf("装箱      : %s / objCType=%s\n", boxed.stringValue.UTF8String, boxed.objCType);
        NSValue *range = [NSValue valueWithRange:NSMakeRange(3, 4)];
        printf("NSValue range: location=%lu length=%lu\n",
               (unsigned long)range.rangeValue.location, (unsigned long)range.rangeValue.length);
        printf("NSStringFromRange : %s\n", NSStringFromRange(NSMakeRange(3, 4)).UTF8String);

        line();
        printf("== 8) @try/@catch：唯一适合处理 NSException 的用法 ==\n");
        BOOL caught = NO;
        @try {
            [words objectAtIndex:99];
        } @catch (NSException *exception) {
            caught = YES;
            printf("异常名     : %s\n", exception.name.UTF8String);
            printf("reason 非空 : %s\n", exception.reason.length > 0 ? "true" : "false");
        } @finally {
            printf("finally 执行 : true\n");
        }
        printf("捕获到异常 : %s\n", caught ? "true" : "false");

        line();
        printf("==== 04 结束 ====\n");
    }
    return 0;
}
