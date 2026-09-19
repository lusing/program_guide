#ifndef Greeter_h
#define Greeter_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 纯 OC 类，被 Swift 调用（走 bridging header）。
/// 加了 NS_ASSUME_NONNULL，Swift 端看到的就是非可选 String，而不是 String!。
@interface Greeter : NSObject

@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)greet:(NSString *)who;

/// 轻量泛型：Swift 端看到 [String] 而不是 [Any]。
@property (nonatomic, readonly) NSArray<NSString *> *names;

/// BOOL + NSError** → Swift 的 throws。
- (BOOL)loadNamesFrom:(NSString *)text error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

#endif /* Greeter_h */
