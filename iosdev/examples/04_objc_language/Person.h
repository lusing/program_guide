#ifndef Person_h
#define Person_h

#import <Foundation/Foundation.h>
#import "Speaker.h"

NS_ASSUME_NONNULL_BEGIN

/// 一个最小的 Objective-C 类：属性 + 指定初始化器 + 协议遵循。
/// NS_ASSUME_NONNULL_BEGIN/END 把区域内所有指针默认设为 nonnull ——
/// 这是让 Swift 端看到「非可选」而不是隐式解包可选的唯一办法（见第 07 章）。
@interface Person : NSObject <Speaker>

// copy：NSString 有可变子类 NSMutableString，不 copy 的话外部改了你手里的值也会变。
// assign：NSInteger 是标量，没有引用计数，用 assign。
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, readonly) NSInteger lengthOfName;   // 只读：只生成 getter

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;   // 强制走上面那个指定初始化器

- (NSString *)greeting;

/// OC 经典错误处理约定：返回 BOOL，错误经二级指针传出。
/// Swift 会自动把这种签名翻译成 throws（第 07 章）。
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error;

/// 给「nil 消息」演示用：返回标量，给 nil 发这条消息会得到 0。
- (NSInteger)doubleAge;

/// 给「nil 消息返回结构体是未定义值」演示用。
- (NSRange)ageRange;

@end

NS_ASSUME_NONNULL_END

#endif /* Person_h */
