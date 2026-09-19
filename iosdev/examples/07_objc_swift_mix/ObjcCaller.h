#ifndef ObjcCaller_h
#define ObjcCaller_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 纯 OC 类，反过来调用 Swift（走生成的 <Module>-Swift.h）。
@interface ObjcCaller : NSObject
/// 内部 new 一个 Swift 的 SwiftCounter，累加后返回计数。
- (NSInteger)runCounterWithFirst:(NSInteger)a second:(NSInteger)b;
/// 把整数当成 Swift 的 @objc enum Theme 来解释。
- (NSString *)describeTheme:(NSInteger)raw;
@end

NS_ASSUME_NONNULL_END

#endif /* ObjcCaller_h */
