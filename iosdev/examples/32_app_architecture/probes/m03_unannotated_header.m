// m03 的实现：一份**什么都不标**的头文件对应的那一侧。
//
// 和 m01 的区别只有一处：这里没有 NS_ASSUME_NONNULL 那半份，
// 所以 clang 没有理由开口 —— 这一支要的就是「swiftc 日志为空」这个读数。
//
// 跑法：bash probes/run.sh m03
#import "m03_unannotated_header.h"

static NSMutableArray *slot = nil;

@implementation NothingAnnotated

+ (void)record:(NSString *)text {
    if (slot == nil) { slot = [NSMutableArray array]; }
    [slot addObject:(text ?: @"(nil)")];
}

+ (NSArray *)history { return [slot copy] ?: @[]; }

@end
