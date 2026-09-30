// m02 的实现：只有主线 hud_record 的「去掉那三行防护」的版本。
// 唯一的区别就是少了一句 `?:` —— 数组照旧是 NSMutableArray，addObject: 照旧收 nil 不了。
#import "m02_addobject_nil.h"

static NSMutableArray *arr = nil;

@implementation HistoryNoGuard

+ (void)record:(NSString *)text {
    if (arr == nil) { arr = [NSMutableArray array]; }
    // 主线在这里写的是 `NSString *safe = text ?: @"(nil)"; [slot addObject:safe];`
    // 这一支照直把参数递进去，看运行时会发生什么。
    [arr addObject:text];
}

+ (NSArray *)history { return [arr copy] ?: @[]; }

@end
