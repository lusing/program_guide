#import "ObjcCaller.h"
// 这个头文件由 swiftc -emit-objc-header-path 生成，里面是 Swift 的 @objc 声明。
// run-all.sh 把它生成到 build/07_objc_swift_mix/SwiftBridge-Swift.h，并用 -I 指到那里。
#import "SwiftBridge-Swift.h"

@implementation ObjcCaller

- (NSInteger)runCounterWithFirst:(NSInteger)a second:(NSInteger)b {
    SwiftCounter *counter = [[SwiftCounter alloc] init];
    [counter incrementBy:a];     // Swift 的 increment(by:) 在 OC 里是 incrementBy:
    [counter incrementBy:b];
    return counter.count;        // @objc private(set) var count 在 OC 里是只读属性
}

- (NSString *)describeTheme:(NSInteger)raw {
    Theme theme = (Theme)raw;    // Swift 的 @objc enum 在 OC 里是 NS_ENUM
    return theme == ThemeDark ? @"dark" : @"light";
}

@end
