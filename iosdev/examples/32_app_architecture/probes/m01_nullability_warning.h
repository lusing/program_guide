// 书 7.12 那句「黄色叹号警告」的原文就在这里 —— 这一份头文件是**故意**留了一半没标的。
//
// 主线 §30 那句「黄色叹号警告在本仓库是硬失败」的原文就在这里 —— 一支探针只抄一条
// 告警：-Wnullability-completeness，而它在 run-all.sh 的判定 1 那里是**硬失败**
// （判定 1 要求编译日志为空）。这一支就是把那条告警现跑现抄下来。
//
// 一个必须说清的机制：clang 的这条告警**不是**「头文件没写 nullability」就报的，
// 它要求这个头文件里**已经有**nullability 标注 —— 也就是「标了一半」。反过来那一半
// 由探针 m03 量：一份从头到尾不标的头文件编过去日志是空的、退出码 0。
// 这恰好就是书 7.12 的现场容易踩的原因：拖进来的第三方库整个没标并不响，
// 而工程里另一处（或后来补的 ProgressHUDStrict）标了，两边一撞，
// 每一个裸指针才被逐条点出来。
//
// 下面 HUDLoose 是「没标的那一半」，HUDStrict 是「标了的那一半」，两者只差宏。
// 真正的第三种答案（宏不写、每个指针手着标 `_Null_unspecified`）在主线那份
// ProgressHUD.h 里，它的凭据是主线的编译日志为空 —— Swift 侧类型与 HUDLoose 完全相同，
// 告警却闭了嘴。
//
// 跑法：bash probes/run.sh m01（期望：swiftc 日志里有那条 warning，程序仍然跑通）
#import <Foundation/Foundation.h>

@interface HUDLoose : NSObject
+ (void)record:(NSString *)text;
+ (NSArray *)history;
@end

NS_ASSUME_NONNULL_BEGIN
@interface HUDStrict : NSObject
+ (void)record:(NSString *)text;
+ (NSArray<NSString *> *)history;
@end
NS_ASSUME_NONNULL_END
