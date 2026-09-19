#ifndef Speaker_h
#define Speaker_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 协议（protocol）≈ Swift 的 protocol / C++ 的纯虚接口。
/// @required 里的方法遵循者**必须**实现；@optional 里的可实现可不实现，
/// 调用前要用 respondsToSelector: 问一下。
@protocol Speaker <NSObject>

@required
- (NSString *)speakTimes:(NSInteger)times;

@optional
- (NSString *)whisper;

@end

NS_ASSUME_NONNULL_END

#endif /* Speaker_h */
