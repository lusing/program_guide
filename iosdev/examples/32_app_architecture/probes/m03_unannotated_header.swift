// 探针 m03：**整份**头文件都不标 nullability 时，clang 到底说不说话
//
// m01 给的形状是「同一份头文件里标了一半」（什么都不标的 HUDLoose 并排一个
// NS_ASSUME_NONNULL 包起来的 HUDStrict），于是 loose 那两行的每个裸指针都被逐条点出来。
// 这一支把「标了的那一半」整个去掉，要量的读数很具体：**swiftc 日志为空**。
//
// 为什么值得单独一支：书 7.12 那句「黄色叹号……并不会影响应用程序的功能」容易被读成
// 「没标就会告警」。实测的触发条件是**同一份文件里标了一半**，而本仓库的判定 1 要的只是
// 「日志为空」—— 所以三种态度各自成文（整份不标 / 全套 NS_ASSUME_NONNULL /
// 逐指针手着标 _Null_unspecified）都能编过去，响的是把它们混在一起的那种。
// 主线 §30 用的是第三种（见 ProgressHUD.h 那三个 `_Null_unspecified`）：
// Swift 侧类型和这一支一样，日志也一样干净。
//
// 第二小段不是凑数：整份不标时那个参数在 Swift 侧是隐式解析可选，`record(nil)` 编译期
// 没人拦截 —— 这正是主线 §30 那条「nil 能不能进来由另一侧有没有防决定」的干净版
// （这一支的 .m 里有一句 `?:` 兜住了它；没兜的那一支是 m02）。
//
// 跑法：bash probes/run.sh m03（期望：swiftc 退出码 0、日志为空，程序跑通）
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

NothingAnnotated.record("来自 Swift 的一行")
print("record 的 Swift 类型：\(type(of: NothingAnnotated.record))")
let first = NothingAnnotated.history()
print("history 的 Swift 类型：\(type(of: first ?? [Any]()))")
print("收下 \(first?.count ?? -1) 条，第一条：\((first?.first ?? "nil") as Any)")

print("下面这一句递的是 nil（整份都没标，编译期无人拦截）：")
NothingAnnotated.record(nil)
let after = (NothingAnnotated.history() ?? []).compactMap { $0 as? String }
print("仍然收下 \(after.count) 条，最后一条：\(after.last ?? "nil")")
print("==== m03 结束 ====")
