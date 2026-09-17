#ifndef Person_h
#define Person_h

#import <Foundation/Foundation.h>
#import "Speaker.h"

NS_ASSUME_NONNULL_BEGIN

/// 一个最小的 Objective-C 类：属性 + 指定初始化器 + 协议遵循。
/// 注意 NS_ASSUME_NONNULL_BEGIN/END：它把区域内所有指针默认设为 nonnull，
/// 这是让 Swift 端看到可选择类型（而不是隐式解包）的唯一办法。
@interface Person : NSObject <Speaker>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 返回一个 greeting —— 「 lining」演示 protocol + 实例方法
- (NSString *)greeting;

/// Objective-C 的经典错误处理约定：方法返回 BOOL，错误通过二级指针传出。
/// Swift 会自动把这种签名翻译成 throws。
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error;

/// 名字长度（给 nil 消息演示用：返回 NSInteger，所以 nil 会给出 0）
- (NSInteger)lengthOfName;

/// 返回一个结构体：给 nil 消息演示「结构体返回值是未定义值」用
- (NSRange)ageRange;

@end

NS_ASSUME_NONNULL_END

#endif /* Person_h */
