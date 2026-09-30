// ============================================================
// ProgressHUD 的手写替身 —— 书 7.12 那三文件里的 ProgressHUD.m
//
// 原库这里画的是一个盖在全屏上的 UIView + UIActivityIndicatorView + UILabel，靠
// [UIApplication sharedApplication].keyWindow 加上去。本章的产物没有窗口，所以
// 「画」这一半换成两样读得回来的东西：
//   1) 一个类内静态数组 history —— 每次 show 记一行，Swift 侧读得到；
//   2) 一次对 Swift 的回调（[[HUDSink shared] note:]）—— 这就是书里没走的那半条桥：
//      OC 想用 Swift 的类，得 #import 编译器生成的 <Module>-Swift.h。
// 这两样让 §30 能问出原书问不出的问题：HUD「弹出来了」这句话，在没有屏幕的进程里
// 到底是什么意思。
//
// nil 的处理是**故意兜住**的（下面 record: 里那一行 ?: ）：头文件没声明 nonnull，
// Swift 侧传 nil 编译器不会拦，能不能活下来全看 OC 这一侧有没有写那三行。
// 不兜住的下场见探针 m02（NSMutableArray addObject: 那句原文）。
// ============================================================

#import "ProgressHUD.h"
// 这个头由 swiftc -emit-objc-header-path 生成（示例目录里那个 Needs-Swift-Header
// 标记文件就是让它生成的开关，见 run-all.sh 的混编段）。里面是 Swift 的 @objc 声明。
#import "SwiftBridge-Swift.h"

static NSMutableArray *looseHistory = nil;
static ProgressHUD *looseShared = nil;

static NSMutableArray *strictHistory = nil;
static ProgressHUDStrict *strictShared = nil;

/// 两个类共用一套逻辑，各自一份 history。text 可能是 nil（无 nullability 那条路）。
/// 那个 `__strong *` 不是风格：ARC 下把一个全局强指针的地址传给默认按
/// `__autoreleasing *` 解释的参数，报的是「passing address of non-local object to
/// __autoreleasing parameter for write-back」—— 书 7.12 那种「拖进来就能用」的库，
/// 只要在 .m 里写一个持有数组的辅助函数就会撞上这一条。
static void hud_record(NSMutableArray * __strong *slot, NSString *text, NSString *tag) {
    if (*slot == nil) {
        *slot = [NSMutableArray array];
    }
    NSString *safe = text ?: @"(nil)";
    NSString *line = [NSString stringWithFormat:@"%@：%@", tag, safe];
    [*slot addObject:line];
    // OC → Swift：这一步在书 7.12 里没有对应内容，它是混编的另一半方向。
    [[HUDSink shared] note:line];
}

@implementation ProgressHUD

+ (instancetype)shared {
    if (looseShared == nil) {
        // 原库在这里用的是 [[self alloc] initWithFrame:[UIScreen mainScreen].bounds]，
        // 尺寸这一件事本章要读回来，所以保留。
        looseShared = [[ProgressHUD alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return looseShared;
}

+ (void)show { hud_record(&looseHistory, @"", @"show"); }
+ (void)showSuccess:(NSString *)success { hud_record(&looseHistory, success, @"success"); }
+ (void)showError:(NSString *)error { hud_record(&looseHistory, error, @"error"); }
+ (void)dismiss { hud_record(&looseHistory, @"", @"dismiss"); }

+ (NSArray *)history { return [looseHistory copy] ?: @[]; }
+ (void)reset { [looseHistory removeAllObjects]; }

+ (BOOL)onScreen { return [self shared].window != nil; }

@end

#pragma mark - 同一个类，头文件里加了 NS_ASSUME_NONNULL

@implementation ProgressHUDStrict

+ (instancetype)shared {
    if (strictShared == nil) {
        strictShared = [[ProgressHUDStrict alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return strictShared;
}

+ (void)show { hud_record(&strictHistory, @"", @"show(严格)"); }
+ (void)showSuccess:(NSString *)success { hud_record(&strictHistory, success, @"success(严格)"); }
+ (void)showError:(NSString *)error { hud_record(&strictHistory, error, @"error(严格)"); }
+ (void)dismiss { hud_record(&strictHistory, @"", @"dismiss(严格)"); }

+ (NSArray *)history { return [strictHistory copy] ?: @[]; }
+ (void)reset { [strictHistory removeAllObjects]; }

+ (BOOL)onScreen { return [self shared].window != nil; }

@end
