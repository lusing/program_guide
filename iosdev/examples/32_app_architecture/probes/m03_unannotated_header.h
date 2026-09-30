// m03 的那份头文件：**整份都不标** nullability —— 一个 _Nullable、一个 NS_ASSUME_NONNULL 都没有。
//
// 这一支要量的不是类型映射（那一半和 m01 的 HUDLoose 一样：NSString * → String!），
// 而是 clang 那条 -Wnullability-completeness **到底什么时候不响**：
// m01 给的形状是「同一份头文件里标了一半」（loose 不标 + 紧着一个 NS_ASSUME_NONNULL 的 strict），
// 于是 loose 那两行的每个裸指针都被逐条点出来。这一支把 strict 那一半整个去掉，
// 期望的结果是 **swiftc 日志为空** —— 也就是「什么都不标」反而是安静的。
//
// 为什么这件事值得单独一支：书 7.12 那句「黄色叹号……并不会影响应用程序的功能」容易被读成
// 「没标就会告警」。真相是告警只惩罚**同一份文件里标了一半**的那种写法 ——
// 三种态度各自成文（整份不标 / 全套 NS_ASSUME_NONNULL / 逐指针手着标 _Null_unspecified）
// 都能编出空日志，而本仓库的判定 1 要的正是空日志。
//
// 跑法：bash probes/run.sh m03（期望：swiftc 退出码 0 且日志为空，程序跑通）
#import <Foundation/Foundation.h>

@interface NothingAnnotated : NSObject
+ (void)record:(NSString *)text;
+ (NSArray *)history;
@end
