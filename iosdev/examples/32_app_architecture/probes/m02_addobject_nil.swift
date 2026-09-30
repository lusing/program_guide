// 探针 m02：Swift 递过去一个 nil，OC 那侧没防 —— 崩溃现场在 Objective-C 里
//
// 主线 §30 的那一句 `ProgressHUD.showError(nil)` 跑通了，因为 .m 里有一句 `?:` 兜住。
// 这一支把那句去掉（头文件仍然只写 `_Null_unspecified`，Swift 侧类型一个字没变），
// 于是同一条调用链走到 [NSMutableArray addObject:nil]。
//
// 这一支最值得看的是**责任落在哪一侧**：Swift 的编译期检查到这里为止
// （它只知道参数是 `String!`，而 nil 对这个类型合法），
// 报错的是运行时的 NSMutableArray，报的还是 Objective-C 的异常格式
// —— 崩溃信息里连 Swift 的类型名都没有。这就是混编工程里「查错查过界」的那种现场。
//
// 跑法：bash probes/run.sh m02（期望：退出码 134 = signal 6（SIGABRT，未捕获的 Objective-C 异常），stderr 里是异常原文）
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

HistoryNoGuard.record("第一行：合法调用")
print("history 现在有 \(HistoryNoGuard.history().count) 条")

let nothing: String? = nil
print("Swift 侧 record 的参数类型：\(type(of: HistoryNoGuard.record))")
print("下面这一句要递的是 nil（编译期无人拦截）：")
HistoryNoGuard.record(nothing)
print("跑不到这一行：\(HistoryNoGuard.history().count)")
