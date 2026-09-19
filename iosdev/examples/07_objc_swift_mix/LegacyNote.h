#ifndef LegacyNote_h
#define LegacyNote_h

#import <Foundation/Foundation.h>

/// 反面教材：整个文件**没有任何** nullability 注解（也没有 NS_ASSUME_NONNULL）。
/// -Wnullability-completeness 只对「同一文件里混用了注解与未注解」的情况报警，
/// 所以把这个老类单独放在一个纯未注解的头文件里，既保留 String! 的教学点，又零告警。
/// Swift 端看到的是 String!（隐式解包可选，定时炸弹）。
@interface LegacyNote : NSObject
- (NSString *)text;
@end

#endif /* LegacyNote_h */
