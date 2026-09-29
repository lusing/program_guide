// 27 章 OC 侧的公共小工具：一个「当前证据行」收集器。
//
// 为什么要有它：本章十几节都要「先做一串动作、再把过程按顺序念出来」。
// 用全局数组当黑板，谁执行谁往上写一行，最后整块交给 Swift 打印 —— 这样
// 断言的顺序就是真实执行顺序，不需要靠打印时机猜。
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTL : NSObject
/// 换一块黑板（一节开始前调用），返回旧的
+ (void)begin;
/// 往当前黑板写一行
+ (void)add:(NSString *)line;
/// 取走当前黑板内容
+ (NSArray<NSString *> *)end;
/// 只取数量，避免把整块黑板搬进字符串数组里
+ (NSUInteger)count;
/// 往「永久记录板」写一行：+load 这类早于 main 的时刻要用它，否则 begin 一清就没了
+ (void)record:(NSString *)line;
+ (NSArray<NSString *> *)records;
@end

/// 四个参数一样的宏：少写点样板
#define RTFMT(...) [NSString stringWithFormat:__VA_ARGS__]

NS_ASSUME_NONNULL_END
