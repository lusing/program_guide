#ifndef Speaker_h
#define Speaker_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 协议里的 @optional 才是 Cocoa delegate 的常态：
/// AppKit 里绝大多数 delegate 方法（NSApplicationDelegate、NSTableViewDelegate…）
/// 全是可选的，调用前必须先 respondsToSelector。
@protocol Speaker <NSObject>

@required
- (NSString *)speakTimes:(NSInteger)times;

@optional
- (void)startSpeaking;

@end

NS_ASSUME_NONNULL_END

#endif /* Speaker_h */
