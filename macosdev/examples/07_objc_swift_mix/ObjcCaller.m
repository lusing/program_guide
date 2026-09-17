// ObjcCaller.m —— 从 Objective-C 这一侧调用 Swift
//
// 编译这个文件需要能找到 Swift 生成的头文件，脚本已经把 -I build/<示例>/
// 加上了，所以这里直接 #import "SwiftBridge-Swift.h" 即可。

#import "ObjcCaller.h"
#import "SwiftBridge-Swift.h"

@implementation ObjcCaller

- (NSInteger)askSwiftForCount {
    SwiftCounter *counter = [[SwiftCounter alloc] init];
    // 坑：Swift 的 increment(by:) 到 OC 里叫 incrementBy:。
    // Swift 的方法名会按「第一个参数并入方法名」的规则翻译成 selector：
    //   greet(who:)        -> greetWithWho:     （因为第一个参数没有外部名）
    //   increment(by:)     -> incrementBy:
    [counter incrementBy:5];
    [counter incrementBy:2];
    return counter.count;
}

- (NSString *)describeThemeWithRawValue:(NSInteger)rawValue {
    DisplayTheme theme = (DisplayTheme)rawValue;
    switch (theme) {
        case DisplayThemeLight: return @"light";
        case DisplayThemeDark:  return @"dark";
    }
    return @"unknown";
}

@end
