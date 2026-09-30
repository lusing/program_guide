// 探针 m01：那条「黄色叹号警告」的原文，以及它在 Swift 侧留下的两种类型
//
// 这一支的**结论在编译日志里**，不在 stdout —— stdout 只是证明「带着这条告警，
// 程序照样跑得通」，也就是书 7.12 那句「它们并不会影响应用程序的功能」确实是对的。
// 而在本仓库的工程流程里，它同时是**硬失败**（判定 1 要求编译日志为空）：
// 这两句话不矛盾，差的正是构建脚本里那一行判定。
//
// stdout 上还有第二条要抄的东西：同一个 OC 方法，在没标的类上 Swift 看到参数是
// `String!`（打出来是 Optional<String>），在标了的类上是 `String`。
// 这就是 §30 那条「头文件决定桥这一侧拿到什么类型」的最短证据。
//
// 跑法：bash probes/run.sh m01
import Foundation

setvbuf(stdout, nil, _IONBF, 0)

// 两个类各记一笔，唯一的差别是头文件里那两行宏。
HUDLoose.record("来自 Swift 的一行")
HUDStrict.record("来自 Swift 的一行")

print("HUDLoose.record 的 Swift 类型：\(type(of: HUDLoose.record))")
print("HUDStrict.record 的 Swift 类型：\(type(of: HUDStrict.record))")
print("loose history：\(HUDLoose.history() as NSArray)")
print("strict history：\(HUDStrict.history())")
print("==== m01 结束 ====")
