// m02：「另一侧没防」的那一种 —— 主线 §30 那条 nil 调用的对照组
//
// 主线的 ProgressHUD.m 里，hud_record 有一句 `NSString *safe = text ?: @"(nil)";`
// 于是 Swift 递进来的 nil 被收下、history 里多出一行「error：(nil)」，进程活着。
// 这一支把那三行去掉：头文件仍然是「未声明」（`_Null_unspecified`，Swift 侧 String!），
// 也就是说 Swift 这一侧**照旧一个字都不说**，而运行到 [NSMutableArray addObject:nil] 时
// 抛的是 NSInvalidArgumentException。
//
// 这两支放在一起才是 §30 那句话的完整形状：
// **nil 能不能进来不是由类型决定的，是由另一侧有没有防决定的。**
//
// 跑法：bash probes/run.sh m02（期望：退出码 134 / SIGABRT，stderr 里是 Objective-C 异常原文）
#import <Foundation/Foundation.h>

@interface HistoryNoGuard : NSObject
/// 和主线 ProgressHUD 的 showError: 一样是「未声明 nullability」，Swift 侧看到 String!。
+ (void)record:(NSString *_Null_unspecified)text;
/// 这个返回值标了 _Nonnull —— 否则整个头文件就变成「标了一半」，
/// m02 的日志里会混进一条与本题无关的 -Wnullability-completeness（那是 m01 要量的）。
+ (NSArray *_Nonnull)history;
@end
