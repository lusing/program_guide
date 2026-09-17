#ifndef NSString_Extras_h
#define NSString_Extras_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 分类的作用之一：给不能改源码的类（这里是 Foundation 的 NSString）加方法。
/// 方法名必须加前缀 —— 系统自己也可能有同名私有方法，冲突时谁被调到是不确定的。
@interface NSString (MXExtras)

/// 返回倒序字符串（按字符逐个倒，不用 enumerateSubstrings，
/// 所以 emoji 组合序列会被拆坏 —— 这条注释本身就是个提醒）
- (NSString *)mx_reversedString;

@end

NS_ASSUME_NONNULL_END

#endif /* NSString_Extras_h */
