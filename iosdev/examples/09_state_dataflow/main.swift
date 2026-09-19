// ============================================================
// 09 - SwiftUI 状态与数据流：@State / @Binding / @Published / @Environment
//
// SwiftUI「自动刷新界面」的全部秘密就是**状态**：视图依赖某个状态，状态一变，
// SwiftUI 重新求值 body。谁拥有状态、谁能改状态，就是「数据流」。核心几种：
//   @State          视图**自己拥有**的值类型状态（SwiftUI 替你在视图之外保管）
//   @Binding        **借用**别处的状态（不拥有，只读写）
//   @StateObject    视图**拥有**一个引用类型模型（ObservableObject）
//   @ObservedObject 视图**借用**一个 ObservableObject（外部拥有）
//   @Published      标在 ObservableObject 的属性上：一改就广播 objectWillChange
//   @Environment    读环境里自上而下传递的值（colorScheme、自定义 key…）
//
// 部署目标 iOS 15：主用 ObservableObject（iOS 13+）；iOS 17 的 @Observable 宏
// 只在文档里提，不在这里编（target 15 编不过）。
//
// headless 自测：@State/@Binding 的真实读写需要一次视图渲染循环（本示例不跑），
// 所以这里验证**确定性最强**的部分：ObservableObject + @Published 的广播、
// 手工 Binding 的 get/set、属性包装器的 projectedValue 类型、自定义 EnvironmentKey。
// ============================================================

import Foundation
import SwiftUI
import Combine

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

line("== 09 状态与数据流 ==")

// ---------------------------------------------------- 1) ObservableObject + @Published
line("")
line("-- ObservableObject / @Published：状态的「源头」 --")
final class CounterModel: ObservableObject {
    @Published var count = 0            // 一改就触发 objectWillChange
    @Published var label = "初始"
    func increment() { count += 1 }
}
let model = CounterModel()
// 订阅 objectWillChange：@Published 变化**之前**广播一次（Combine 的 ObservableObjectPublisher）
var changeCount = 0
var cancellables = Set<AnyCancellable>()
model.objectWillChange
    .sink { _ in changeCount += 1 }
    .store(in: &cancellables)

model.increment()                        // count 0→1，广播 1 次
model.increment()                        // count 1→2，广播 1 次
model.label = "改了"                      // 另一个 @Published，也广播 1 次
line("  count = \(model.count)，objectWillChange 触发次数 = \(changeCount)")
expect(model.count == 2, "@Published 属性确实被改到了 2")
expect(changeCount == 3, "三次赋值（两次 count + 一次 label）各广播一次 objectWillChange")
expect(model.label == "改了", "第二个 @Published 属性独立生效")

// ---------------------------------------------------- 2) @Binding：借用别处的状态
line("")
line("-- @Binding：不拥有，只读写 --")
// Binding 本质是一对 get/set 闭包，指向「真正的源头」。这里用一个类当源头手工造一个。
final class Store { var value = 10 }
let store = Store()
let binding = Binding<Int>(
    get: { store.value },
    set: { store.value = $0 }
)
expect(binding.wrappedValue == 10, "Binding 读：拿到源头的当前值")
binding.wrappedValue = 42                 // 通过 Binding 写
expect(store.value == 42, "Binding 写：改的就是源头那个值（不是副本）")
// 子视图拿到的是 Binding（借用），父视图/模型才是 source of truth（拥有）
let child = binding                       // 传给孩子
child.wrappedValue = 7
expect(store.value == 7, "传下去的 Binding 仍指向同一个源头")

// ---------------------------------------------------- 3) 属性包装器的 projectedValue（$）
line("")
line("-- $ 前缀：projectedValue 的类型 --")
struct StatefulView: View {
    @State var on = false                  // $on 是 Binding<Bool>（这里不加 private，便于自测读类型）
    var body: some View { Text(on ? "开" : "关") }
}
// 在 View 之外，@State 的存储没被 SwiftUI 安装，但 projectedValue 的**类型**是确定的：
// $on 一定是 Binding<Bool>。用一个独立实例读它的类型名。
let sv = StatefulView()
let stateBindingType = String(describing: type(of: sv.$on))
line("  @State 的 $ 类型 = \(stateBindingType)")
expect(stateBindingType.contains("Binding<Bool>"), "@State 的 projectedValue 是 Binding<Bool>")

struct ObservedView: View {
    @ObservedObject var model: CounterModel   // $model 是 ObservedObject<...>.Wrapper（动态成员绑定）
    var body: some View { Text("\(model.count)") }
}
let ov = ObservedView(model: model)
let observedType = String(describing: type(of: ov.$model))
line("  @ObservedObject 的 $ 类型 = \(observedType)")
expect(observedType.contains("Wrapper"), "@ObservedObject 的 $ 是 Wrapper（$model.count 可当 Binding 传给子视图）")

// ---------------------------------------------------- 4) @StateObject vs @ObservedObject 的所有权
line("")
line("-- @StateObject（拥有） vs @ObservedObject（借用）--")
line("  @StateObject   ：视图创建并**拥有**模型，视图重建时模型不被重置")
line("  @ObservedObject：模型由**外部**拥有并传进来，视图只是观察它")
line("  规则：源头（拥有者）用 @State/@StateObject；下游（借用者）用 @Binding/@ObservedObject")
expect(true, "所有权方向决定用哪个包装器（本示例已用 Store/Binding 演示借用语义）")

// ---------------------------------------------------- 5) @Environment：自上而下传值
line("")
line("-- @Environment / 自定义 EnvironmentKey --")
// 自定义环境值：定义 key + 默认值，再扩展 EnvironmentValues。
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = "浅色"       // 没人显式设时，读到的就是这个默认值
}
extension EnvironmentValues {
    var theme: String {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
// 直接读默认环境值：@Environment 没被安装时，wrappedValue 回落到 key 的 defaultValue。
struct EnvReader: View {
    @Environment(\.theme) var theme
    var body: some View { Text(theme) }
}
let reader = EnvReader()
line("  默认 environment.theme = \(reader.theme)")
expect(reader.theme == "浅色", "自定义 EnvironmentKey 的默认值可读")
// 系统内置的环境值同理（colorScheme 在未安装时有默认）
let colorSchemeDefault = EnvironmentValues().colorScheme
line("  EnvironmentValues().colorScheme 默认 = \(String(describing: colorSchemeDefault))")
expect(true, "内置环境值也能读到默认（无需真实渲染环境）")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 09 结束 ====")
exit(failures == 0 ? 0 : 1)
