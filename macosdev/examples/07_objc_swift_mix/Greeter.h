// Greeter.h —— 一个纯 Objective-C 类，等着被 Swift 调用
//
// 关键点在 NS_ASSUME_NONNULL_BEGIN / END：圈起来的区域里所有指针默认 nonnull，
// Swift 侧看到的就都是 **非可选** 类型。不做这个注解，Swift 里拿到的是
// 隐式解包可选（String!），用起来满屏叹号，而且一传 nil 就崩。

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Greeter : NSObject

/// 有注解的属性 → Swift 里是 String（不是 String?）
@property (nonatomic, copy) NSString *name;

/// - (NSString *)greet:(NSString *)who → Swift 里是 greet(_ who: String) -> String
- (NSString *)greet:(NSString *)who;

/// 元素类型也一起带过去：Swift 里是 [String]
@property (nonatomic, readonly) NSArray<NSString *> *names;

/// NSError ** → Swift 里自动变成 throws
- (BOOL)loadNamesFrom:(NSString *)text error:(NSError **)error;

/// Objective-C block → Swift 闭包
- (void)forEachName:(void (^)(NSString *name, NSUInteger index))block;

@end

// 反面教材：故意**不**加 nullability 注解的 API。
// Swift 侧会把它当成隐式解包可选，编译器不报错，运行时一 nil 就炸。
@interface LegacyNote : NSObject

- (NSString *)text;

@end

NS_ASSUME_NONNULL_END
