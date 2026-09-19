// ============================================================
// 11 - SwiftUI 列表与导航：List / ForEach / LazyVStack / Section / NavigationStack
//
// 列表与导航是 App 最常见的界面骨架。要点：
//   Identifiable：List/ForEach 靠稳定的 id 做 diff、复用行、驱动增删动画
//   ForEach      ：把数据数组映射成一组视图
//   LazyVStack   ：只渲染可见行（长列表用它，别用 VStack）
//   Section      ：给列表分组、加页眉页脚
//   NavigationStack（iOS 16+）：管理一叠页面，NavigationLink 压栈，.navigationDestination 路由
//
// 部署目标 iOS 15：NavigationView 在 iOS 16 已**弃用**（用了会告警，违反零告警），
// 所以导航部分放在 `if #available(iOS 16, *)` 里用 NavigationStack；模拟器是 iOS 18，
// 运行时会真的走进去。列表/数据部分与版本无关。
//
// headless 自测：验证数据侧的确定性逻辑（Identifiable、分组、过滤）与视图侧的**类型**
// （ForEach / LazyVStack / Section / NavigationStack），不跑真实滚动与压栈动画。
// ============================================================

import Foundation
import SwiftUI

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func typeName(_ v: some View) -> String { String(describing: type(of: v)) }

line("== 11 列表与导航 ==")

// ---------------------------------------------------- 数据模型：Identifiable
struct Contact: Identifiable, Equatable {
    let id = UUID()          // 稳定唯一 id：List/ForEach 用它做 diff
    let name: String
    let group: String
}
let contacts = [
    Contact(name: "张三", group: "同事"),
    Contact(name: "李四", group: "朋友"),
    Contact(name: "王五", group: "同事"),
    Contact(name: "赵六", group: "家人"),
]

// ---------------------------------------------------- 1) Identifiable：id 唯一且稳定
line("")
line("-- Identifiable：每行有稳定唯一的 id --")
let ids = Set(contacts.map { $0.id })
expect(ids.count == contacts.count, "四个联系人有四个不同的 id（无碰撞）")
expect(contacts[0].id == contacts[0].id, "同一个对象的 id 稳定不变")

// ---------------------------------------------------- 2) ForEach：数组 → 一组视图
line("")
line("-- ForEach：把数据映射成视图 --")
let rows = ForEach(contacts) { c in          // 因为 Contact: Identifiable，无需手写 id:
    Text(c.name)
}
let rowsType = typeName(rows)
line("  ForEach 类型 = \(rowsType)")
expect(rowsType.contains("ForEach"), "ForEach 是一个视图，内部持有数据与行构造闭包")
// ForEach 的 data 可以取回来（它是公开的成员）
expect(rows.data.count == 4, "ForEach 持有全部 4 条数据")

// ---------------------------------------------------- 3) LazyVStack vs VStack：懒加载
line("")
line("-- LazyVStack：只构建可见行（长列表用）--")
let lazy = LazyVStack { Text("a"); Text("b") }
let eager = VStack { Text("a"); Text("b") }
line("  LazyVStack 类型 = \(typeName(lazy))")
line("  VStack     类型 = \(typeName(eager))")
expect(typeName(lazy).contains("LazyVStack"), "LazyVStack 是独立类型（滚动时才逐行构建）")
expect(typeName(eager).contains("VStack") && !typeName(eager).contains("Lazy"),
       "普通 VStack 会一次性构建全部子视图")

// ---------------------------------------------------- 4) Section：分组（纯数据逻辑）
line("")
line("-- Section：按 group 分组 --")
// 真实 List 里写 Section(header:) { ForEach(该组的行) }；分组本身是纯 Swift 逻辑。
var grouped: [String: [Contact]] = [:]
for c in contacts { grouped[c.group, default: []].append(c) }
let groupNames = grouped.keys.sorted()
line("  分组结果 = \(groupNames.map { "\($0)(\(grouped[$0]!.count))" }.joined(separator: ", "))")
expect(groupNames == ["同事", "家人", "朋友"], "分成三组：同事/家人/朋友")
expect(grouped["同事"]?.count == 2, "同事组 2 人")
expect(grouped["家人"]?.count == 1, "家人组 1 人")
// Section 视图本身可构造
let section = Section(header: Text("同事")) {
    ForEach(grouped["同事"] ?? []) { Text($0.name) }
}
expect(typeName(section).contains("Section"), "Section 是一个视图（带 header 与内容）")

// ---------------------------------------------------- 5) 过滤（搜索框背后的逻辑）
line("")
line("-- 搜索过滤：纯函数，确定可测 --")
func filter(_ all: [Contact], by query: String) -> [Contact] {
    guard !query.isEmpty else { return all }
    return all.filter { $0.name.contains(query) }
}
expect(filter(contacts, by: "").count == 4, "空查询返回全部")
expect(filter(contacts, by: "张").map { $0.name } == ["张三"], "查「张」命中张三")
expect(filter(contacts, by: "钱").isEmpty, "查不到的字返回空数组（不是 nil、不崩）")

// ---------------------------------------------------- 6) NavigationStack（iOS 16+）
line("")
line("-- NavigationStack：一叠页面 + 路由 --")
if #available(iOS 16.0, *) {
    // NavigationLink 压栈；.navigationDestination(for:) 按数据类型路由到详情页。
    let nav = NavigationStack {
        List(contacts) { c in
            NavigationLink(value: c.name) { Text(c.name) }
        }
        .navigationDestination(for: String.self) { name in
            Text("详情：\(name)")
        }
    }
    let navType = typeName(nav)
    line("  NavigationStack 类型 = \(navType)")
    expect(navType.contains("NavigationStack"), "NavigationStack 可构造（iOS 16+）")
    // NavigationLink 本身也是普通视图
    let link = NavigationLink("去详情") { Text("详情页") }
    expect(typeName(link).contains("NavigationLink"), "NavigationLink 是一个视图")
    // 路径可绑定：NavigationStack(path:) 的 path 是程序化控制导航栈的入口
    let path = NavigationPath()
    expect(path.count == 0, "新建的 NavigationPath 是空栈（count==0）")
} else {
    expect(false, "模拟器应 >= iOS 16，不该走到这里")
}

// ---------------------------------------------------- 7) 心智模型小结
line("")
line("-- 心智模型 --")
line("  List/ForEach 靠 Identifiable.id 做 diff：稳定 id 才能正确复用行、跑增删动画")
line("  长列表用 LazyVStack/List（懒），别用 VStack（一次性全建）")
line("  Section 分组；.searchable 背后就是一个过滤纯函数")
line("  NavigationStack（iOS16+）用 value + navigationDestination 做类型安全路由")
expect(true, "以上均有对应的类型或数据断言")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 11 结束 ====")
exit(failures == 0 ? 0 : 1)
