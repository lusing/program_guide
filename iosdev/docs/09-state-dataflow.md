# 09 · SwiftUI 状态与数据流：@State / @Binding / @Published / @Environment

> 示例：`examples/09_state_dataflow/main.swift`
> 实测输出见 `build/09_state_dataflow/stdout.debug.txt`

第 08 章说「`body` 由 SwiftUI 替你求值」。那它**什么时候**重新求值？答案是：当
`body` 依赖的**状态**变化时。谁拥有状态、谁能改状态、改了怎么通知视图——这一整套
就是「数据流」。它是 SwiftUI「自动刷新界面」的全部秘密。

> 部署目标是 iOS 15，本章主用 `ObservableObject`（iOS 13+）。iOS 17 引入的
> `@Observable` 宏 + `@Bindable` 是更简洁的替代，但它需要 iOS 17，本章末尾单独提，
> 不在示例里编译。

## 五种状态包装器：一张表先记住

| 包装器 | 谁拥有 | 用于 | 值/引用 |
| --- | --- | --- | --- |
| `@State` | **视图自己** | 视图私有的简单值（开关、输入框文本） | 值类型 |
| `@Binding` | 别处 | 子视图**借用**父视图的状态，可读写 | 值的引用通道 |
| `@StateObject` | **视图自己** | 视图创建并拥有的模型 | 引用类型（`ObservableObject`） |
| `@ObservedObject` | 外部 | 视图**借用**外部传进来的模型 | 引用类型 |
| `@EnvironmentObject` | 祖先注入 | 跨多层拿同一个模型，免逐层传参 | 引用类型 |
| `@Environment` | 系统/祖先 | 读环境值（`colorScheme`、自定义 key） | 值 |

**一句话规则**：**源头（拥有者）用 `@State`/`@StateObject`；下游（借用者）用
`@Binding`/`@ObservedObject`。** 拿错方向，界面要么不刷新，要么每次重建都丢状态。

## 1) ObservableObject + @Published：状态的源头

「模型」是一个引用类型（`class`），实现 `ObservableObject`，把要驱动界面的属性标上
`@Published`：

```swift
final class CounterModel: ObservableObject {
    @Published var count = 0            // 一改就触发 objectWillChange
    @Published var label = "初始"
    func increment() { count += 1 }
}
```

`@Published` 的作用：属性**将变**时，通过对象的 `objectWillChange`（一个 Combine
`ObservableObjectPublisher`）广播一次。观察这个模型的视图收到广播，就重新求值 `body`。

实测里我们用 Combine 的 `sink` 订阅了 `objectWillChange`，数它广播了几次：

```swift
var changeCount = 0
model.objectWillChange.sink { _ in changeCount += 1 }.store(in: &cancellables)
model.increment()      // count 0→1，广播 1 次
model.increment()      // count 1→2，广播 1 次
model.label = "改了"    // 另一个 @Published，广播 1 次
```

```
-- ObservableObject / @Published：状态的「源头」 --
  count = 2，objectWillChange 触发次数 = 3
  ok   @Published 属性确实被改到了 2
  ok   三次赋值（两次 count + 一次 label）各广播一次 objectWillChange
  ok   第二个 @Published 属性独立生效
```

三个要点：

- **每一次 `@Published` 赋值都广播一次**，不管改的是哪个属性（`count` 和 `label`
  共享同一个 `objectWillChange`）。
- 广播发生在**变化之前**（`objectWillChange`，不是 `objectDidChange`）。SwiftUI 收到
  后安排一次异步的 `body` 重算，那时值已经改好了。
- 没标 `@Published` 的属性变了**不会**广播，界面不会刷新——这是新手最常见的「为什么
  不更新」的原因。

## 2) @Binding：借用别处的状态

子视图通常**不拥有**状态，只是「读写父视图给的那份」。这就是 `@Binding`。它的本质是
**一对 get/set 闭包**，指向真正的源头（source of truth）：

```swift
final class Store { var value = 10 }
let store = Store()
let binding = Binding<Int>(
    get: { store.value },
    set: { store.value = $0 }
)
binding.wrappedValue         // 读：10
binding.wrappedValue = 42    // 写：store.value 变成 42
```

```
-- @Binding：不拥有，只读写 --
  ok   Binding 读：拿到源头的当前值
  ok   Binding 写：改的就是源头那个值（不是副本）
  ok   传下去的 Binding 仍指向同一个源头
```

关键：**通过 `Binding` 写，改的就是源头那个值，不是副本**。把这个 `Binding` 再传给
更下游的子视图，它仍然指向同一个源头。这就是「单一数据源（single source of truth）」：
无论多少层视图，状态只有一份，谁改都改的是它。

真实写法里你不会手工造 `Binding`——父视图有个 `@State var on`，把 `$on`（读法见下节）
传给子视图的 `@Binding var on`，SwiftUI 就替你接好了 get/set。

## 3) `$` 前缀：projectedValue

在属性包装器前加 `$`，拿到的是它的 **projectedValue**——对 `@State` 来说就是一个
`Binding`：

```swift
struct StatefulView: View {
    @State var on = false
    var body: some View { Text(on ? "开" : "关") }
}
// $on 的类型
String(describing: type(of: sv.$on))   // Binding<Bool>
```

```
-- $ 前缀：projectedValue 的类型 --
  @State 的 $ 类型 = Binding<Bool>
  ok   @State 的 projectedValue 是 Binding<Bool>
  @ObservedObject 的 $ 类型 = Wrapper
  ok   @ObservedObject 的 $ 是 Wrapper（$model.count 可当 Binding 传给子视图）
```

- `@State var on` → 读 `on` 是值本身（`Bool`）；读 `$on` 是 `Binding<Bool>`，可以
  传给需要 `@Binding` 的子视图。
- `@ObservedObject var model` → `$model` 是一个 `Wrapper`，支持**动态成员**：
  `$model.count` 直接得到 `Binding<Int>`，把模型里的某个 `@Published` 属性当绑定传下去。

> 这就是为什么传状态给子控件写 `$text`、`$isOn`（带 `$`）而不是 `text`、`isOn`。
> `Toggle("开关", isOn: $on)` 要的是 `Binding<Bool>`，不是 `Bool`。

## 4) @StateObject vs @ObservedObject：所有权决定用哪个

两者都观察一个 `ObservableObject`，区别只在**谁拥有它**：

```
@StateObject   ：视图创建并**拥有**模型，视图重建时模型不被重置
@ObservedObject：模型由**外部**拥有并传进来，视图只是观察它
```

- 在**创建模型的那个视图**里用 `@StateObject`。SwiftUI 保证：即使这个视图的 `body`
  被重算很多次，`@StateObject` 里的模型**只初始化一次**，不会被反复重建。
- 在**接收模型的子视图**里用 `@ObservedObject`。模型的生命周期归外部管。

> **坑**：在子视图里对一个每次传进来的模型用 `@StateObject`，或在拥有者那里用
> `@ObservedObject`，都会导致状态被意外重置或重复创建。记牢「拥有 → StateObject，
> 借用 → ObservedObject」。

跨很多层传同一个模型时，逐层写 `@ObservedObject` 很烦——用 `@EnvironmentObject`：
祖先用 `.environmentObject(model)` 注入，任意后代直接 `@EnvironmentObject var model`
读，中间层不用管。（注意：注入缺失会在**运行时**崩溃，不是编译错。）

## 5) @Environment：自上而下传值

「环境」是一套自上而下流动的值：系统内置的（`colorScheme`、`locale`、`dismiss`…），
以及你自定义的。视图用 `@Environment` 读，不用逐层传参。

自定义环境值三步：

```swift
// 1) 定义 key + 默认值
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = "浅色"
}
// 2) 扩展 EnvironmentValues，给它一个名字
extension EnvironmentValues {
    var theme: String {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
// 3) 视图里读
struct EnvReader: View {
    @Environment(\.theme) var theme
    var body: some View { Text(theme) }
}
```

祖先用 `.environment(\.theme, "深色")` 覆盖；没人覆盖时读到 `defaultValue`。

```
-- @Environment / 自定义 EnvironmentKey --
  默认 environment.theme = 浅色
  ok   自定义 EnvironmentKey 的默认值可读
  EnvironmentValues().colorScheme 默认 = light
  ok   内置环境值也能读到默认（无需真实渲染环境）
```

内置环境值同理：`EnvironmentValues().colorScheme` 在没有真实渲染环境时也能读到默认
（这里是 `light`）。这就是为什么本示例能 headless 验证——`@Environment` 未安装时
回落到 key 的 `defaultValue`，不崩溃。

## iOS 17 的变化：@Observable / @Bindable（了解）

iOS 17 起有了 Observation 框架，写法更简洁（**需要 iOS 17，本教程 target 15 不编**）：

```swift
import Observation

@Observable                       // 宏，替代 ObservableObject + @Published
final class CounterModel {
    var count = 0                 // 不用标 @Published，自动被观察
    var label = "初始"
}

struct SomeView: View {
    @State var model = CounterModel()   // 拥有：用 @State（不再是 @StateObject）
    var body: some View {
        // 需要把某个属性当 Binding 传下去时，用 @Bindable 包一层
        let bindable = Bindable(model)
        TextField("标签", text: $bindable.label)
    }
}
```

区别记忆：

- `@Observable` 宏 → 不再需要 `ObservableObject` 协议和 `@Published`；**只有真正被
  `body` 读到的属性**变化才触发刷新（比 `objectWillChange` 全量广播更精准）。
- 拥有 `@Observable` 模型用 `@State`（不是 `@StateObject`）；借用直接当普通属性传。
- 要 `Binding` 时用 `Bindable(model)` 或 `@Bindable var model`。

## headless 验证的边界

本示例**没有跑真实的视图渲染循环**，所以 `@State`/`@Binding` 在真实视图里的「改了
自动刷新」这条**动态行为**没被端到端验证——那需要一个挂进窗口、跑 run loop 的宿主
（第 20 章打包成真 App 后才能完整跑）。这里验证的是**确定性最强**的部分：
`ObservableObject` 的广播次数、手工 `Binding` 的 get/set 语义、projectedValue 的
**类型**、自定义 `EnvironmentKey` 的默认值。它们不依赖渲染时机，能稳稳被六条判定卡住。

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 改了模型属性，界面不刷新 | 属性没标 `@Published`；或模型不是 `ObservableObject` |
| 子视图每次刷新状态都丢 | 拥有者该用 `@StateObject` 却用了 `@ObservedObject` |
| `Toggle(isOn: on)` 编译不过 | 要传 `Binding`，得写 `$on`（带 `$`） |
| `@EnvironmentObject` 运行时崩溃 | 祖先忘了 `.environmentObject(...)` 注入 |
| 想跨很多层传模型，逐层写 `@ObservedObject` 太烦 | 用 `@EnvironmentObject`（或 iOS 17 的 `@Environment(Model.self)`） |
| 自定义 `@Environment` 读到默认值而非设定值 | 祖先没用 `.environment(\.yourKey, ...)` 覆盖 |

## 小结

- SwiftUI 靠**状态**驱动刷新：`body` 依赖的状态一变，视图重算。
- 拥有状态用 `@State`（值）/`@StateObject`（模型）；借用用 `@Binding`（值）/
  `@ObservedObject`（模型）；跨层用 `@EnvironmentObject`；读环境用 `@Environment`。
- `@Published` 让属性变化通过 `objectWillChange` 广播；每次赋值广播一次，变化前广播。
- `$` 拿 projectedValue：`@State` 的 `$` 是 `Binding`，`@ObservedObject` 的 `$` 是
  支持动态成员的 `Wrapper`。
- 单一数据源：状态只有一份，`Binding` 是通往它的读写通道。
- iOS 17 的 `@Observable`/`@Bindable` 更简洁精准，但需要 iOS 17。下一章讲**布局**。
