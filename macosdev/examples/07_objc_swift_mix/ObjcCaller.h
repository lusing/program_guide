// ObjcCaller.h —— 一个 Objective-C 类，它的实现会去调用 Swift 代码
//
// 方向正好和 Greeter 相反：Swift 调 OC 靠「桥接头」（Bridging.h），
// OC 调 Swift 靠自动生成的 <ModuleName>-Swift.h（Xcode 里是自动的，
// 命令行下要用 -emit-objc-header-path 自己生成一份）。
//
// 坑：这个头文件会被 Bridging.h 引进 Swift 里。所以它**不能**引用任何
// Swift 生成的类型（比如 Swift 的 @objc enum）—— 那是循环依赖。
// 需要引用 Swift 类型的声明，只允许出现在 .m 里。

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjcCaller : NSObject

/// 内部会新建一个 SwiftCounter（Swift 类），+1 之后把值带回来
- (NSInteger)askSwiftForCount;

/// Swift 的 @objc enum 在 OC 侧就是一个 NS_ENUM。
/// 参数写成 NSInteger 是为了不在这个头文件里引用 Swift 生成的类型。
- (NSString *)describeThemeWithRawValue:(NSInteger)rawValue;

@end

NS_ASSUME_NONNULL_END
