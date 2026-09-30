// m01 的实现部分：两个类走同一套逻辑，差别只在头文件那两行宏。
// 这一支不量行为（§30 的 HUD 行为主线已经量过），只量「编译时 clang 说了什么」，
// 所以这里写得越短越好 —— 但必须**有**这个 .m，否则那条告警不会在链接阶段被触发。
#import "m01_nullability_warning.h"

static NSMutableArray *looseArr = nil;
static NSMutableArray *strictArr = nil;

@implementation HUDLoose
+ (void)record:(NSString *)text {
    if (!looseArr) looseArr = [NSMutableArray array];
    [looseArr addObject:(text ?: @"(nil)")];
}
+ (NSArray *)history { return [looseArr copy] ?: @[]; }
@end

@implementation HUDStrict
+ (void)record:(NSString *)text {
    if (!strictArr) strictArr = [NSMutableArray array];
    [strictArr addObject:text];
}
+ (NSArray<NSString *> *)history { return [strictArr copy] ?: @[]; }
@end
