# 08 · SwiftUI 基础：View、body、修饰符的值语义

> 示例：`examples/08_swiftui_basics/main.swift`
> 实测输出见 `build/08_swiftui_basics/stdout.debug.txt`

从本章进入 **SwiftUI 主线**（08–13）。SwiftUI 是**声明式** UI：你描述「界面长什么样」
（一棵 `View` 树），系统负责把它渲染出来、并在数据变化时自动更新。这与 UIKit 的
**命令式**（你亲手 `addSubview`、`setFrame`、`setNeedsLayout`）是两种完全不同的心智模型。

本章讲清四个基础事实：`View` 协议、`body`、`some View`、以及**修饰符的值语义**——
最后这条是理解 SwiftUI 的钥匙。

## 1) View 是个协议，只要求一个 body

```swift
struct Badge: View {
    var body: some View {          // opaque 返回类型
        Text("NEW")
    }
}
```

`View` 协议只有一个要求：一个 `associatedtype Body: View` 和 `var body: Body`。
你写的 `body` 返回「另一个 View」。整个界面就是这样一层套一层组合出来的。

实测里 `Badge.body` 的具体类型就是 `Text`：

```
-- View 协议与 body --
  Badge.body 具体类型 = Text
  ok   最简 body 返回一个 Text
  ok   body 可求值，视图树合法
```

> **`body` 什么时候被调用？** 你几乎从不手动调它。SwiftUI 在需要渲染、或视图依赖的
> 状态变化时，**替你**求值 `body` 拿到最新的视图树，再 diff、再更新屏幕。所以 `body`
> 必须**快、无副作用、可重复调用**——别在里面做网络请求、改全局状态、写文件。

## 2) some View：opaque 返回类型

`body` 的返回类型写成 `some View`，这叫 **opaque type（不透明类型）**：编译器知道
确切的具体类型，但对你隐藏了。为什么不用它？因为具体类型会**又长又吓人**。看实测：

```
Text.padding()       = ModifiedContent<Text, _PaddingLayout>
.padding().padding() = ModifiedContent<ModifiedContent<Text, _PaddingLayout>, _PaddingLayout>
```

要是每写一个 `body` 都得把这种嵌套泛型全写出来，代码根本没法读。`some View` 让你
只承诺「返回某个符合 `View` 的东西」，具体是什么交给编译器。

> **坑**：`some View` 是**单一具体类型**。所以 `body` 里不能一会儿 `return Text`、
> 一会儿 `return Image`（两个分支类型不同）——要么用 `@ViewBuilder`（`if/else` 会被
> 包成 `_ConditionalContent`），要么用 `AnyView` 擦除类型（有性能代价，能不用就不用）。

## 3) 修饰符的值语义：返回**新**视图，不改原视图

这是 SwiftUI 最反直觉、也最重要的一点。**View 是 `struct`（值类型）**，修饰符
（`.padding()`、`.font()`、`.background()`…）不会修改原视图，而是**把它包一层、
返回一个全新的视图**：

```swift
let plain  = Text("Hello")
let padded = plain.padding()            // 不改 plain，返回 ModifiedContent<Text, _PaddingLayout>
let styled = plain.padding().padding()  // 再包一层
```

实测：

```
-- 修饰符返回新视图（值语义）--
  Text                = Text
  Text.padding()      = ModifiedContent<Text, _PaddingLayout>
  .padding().padding()= ModifiedContent<ModifiedContent<Text, _PaddingLayout>, _PaddingLayout>
  ok   裸 Text 的类型就是 Text
  ok   修饰符把原视图包成 ModifiedContent
  ok   修饰后是一个**新**类型，不是原地修改
  ok   链式修饰逐层向外包裹
  ok   值语义：原视图 plain 未被改变
```

两个推论：

**（a）修饰符有顺序，因为它是「一层层往外包」。** `.padding().background(.red)` 是
「先加内边距，再给（含内边距的）整体上红底」；`.background(.red).padding()` 是
「先上红底，再整体往外推内边距」——红底不会盖住 padding 区域。顺序不同，结果不同。

**（b）`Text` 上的一批「修饰符」其实返回 `Text` 本身，不是 `ModifiedContent`。**
比如 `.font()`、`.bold()`、`.foregroundColor()` 作用在 `Text` 上时返回的还是 `Text`
（`Text` 内部累积了这些属性）。所以上面第二版示例特意用 `.padding().padding()` 而不是
`.font().padding()` 来演示「逐层包裹」——`Text.font(_:)` 返回 `Text`，看不到嵌套。

## 4) 布局栈：VStack / HStack / ZStack

三个基础容器，把子视图按方向排：

```swift
VStack(spacing: 8) { Text("a"); Text("b") }          // 垂直
HStack { Text("x"); Text("y"); Text("z") }           // 水平
ZStack { Text("底"); Text("顶") }                     // 层叠（后者盖前者）
```

实测类型：

```
-- 布局栈：VStack / HStack / ZStack --
  VStack 类型 = VStack<TupleView<(Text, Text)>>
  ok   VStack 是垂直栈
  ok   HStack 是水平栈
  ok   ZStack 是层叠栈
  ok   带 alignment/spacing 仍是 VStack
```

注意 `VStack<TupleView<(Text, Text)>>` 这个类型：`@ViewBuilder` 把大括号里的两个
`Text` 打包成了一个 `TupleView<(Text, Text)>`。这就是「多个子视图」在类型层面的样子
——一个元组视图。`alignment` / `spacing` 只是初始化参数，不改变「它是个 VStack」。

> **`@ViewBuilder`** 是那段 `{ ... }` 能被塞进多个视图、还能写 `if/else`/`ForEach`
> 的原因。它是一个「结果构造器」，把大括号里的多条语句合成一个 View（多个 → `TupleView`，
> 分支 → `_ConditionalContent`）。第 10 章布局、第 11 章列表会反复用到。

## 5) 视图组合：把子树抽成独立 View

SwiftUI 鼓励**用小视图拼大视图**，而不是写一个巨大的 `body`：

```swift
struct Row: View {
    let title: String
    var body: some View {
        HStack { Text(title); Spacer(); Text("›") }
    }
}
struct ProfileCard: View {
    var body: some View {
        VStack {
            Row(title: "名字")     // 组合：Row 是另一个 View
            Row(title: "邮箱")
        }
    }
}
```

实测：

```
-- 视图组合：把子树抽成独立 View --
  ok   组合视图的 body 仍是普通视图树
  ok   抽出来的 Row 独立可求值
```

抽子视图是**零成本**的（`View` 是 struct，编译期内联），却让代码可读、可复用、
可单独预览。这跟 UIKit 里「抽一个自定义 UIView 子类」的成本完全不是一个量级——
所以 SwiftUI 里**大胆拆**。

## 6) SwiftUI 底层仍是 UIKit：UIHostingController

SwiftUI 不是另起炉灶。在 iOS 上，它最终把视图树**渲染进一个 UIKit 宿主视图**，
这个桥就是 `UIHostingController`：

```swift
let host = UIHostingController(rootView: ContentView())
host.loadViewIfNeeded()
String(describing: type(of: host.view!))   // _UIHostingView<ContentView>
```

实测：

```
-- UIHostingController：SwiftUI 渲染进 UIKit --
  ok   UIHostingController 创建了宿主 view
  宿主 view 类型 = _UIHostingView<ContentView>
  ok   宿主 view 是 SwiftUI 的 Hosting 容器（底层仍是 UIView）
  ok   rootView 就是我们塞进去的 ContentView
```

`host.view` 的类型是 `_UIHostingView<ContentView>`——一个 `UIView` 子类。这说明：

- SwiftUI 视图最终落在真实的 `UIView` 层级里，走的是同一套 Core Animation 渲染。
- 你可以在一个纯 UIKit 的 App 里，用 `UIHostingController` 把一块 SwiftUI 视图塞进
  现有的 `UIViewController` 层级；反过来也能用 `UIViewRepresentable` 把 UIKit 视图
  塞进 SwiftUI（第 13 章互操作）。

> **headless 注意**：本示例不挂窗口、不跑渲染循环，所以宿主 view 的**子视图层级还是
> 空的**（`subviews.count == 0`）——真正的内容要等挂进 `UIWindow`、跑完一次渲染才落地。
> 因此自测只断言「宿主 view 是 `_UIHostingView`、rootView 可读回」这两个**确定性**事实，
> 不去判 `subviews.count`。这正是本教程「只断言性质、不断言环境相关数字」的纪律。

## 心智模型小结

```
View 是 struct（值类型）；body: some View 描述界面，不命令式绘制
修饰符 = 包一层返回新视图；顺序影响结果（.padding().background() ≠ 反过来）
some View = opaque 类型：编译器知道具体类型，你无需写出
SwiftUI 底层仍是 UIKit：渲染进 UIHostingController.view（_UIHostingView）
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| `body` 里 `if/else` 两个分支编译不过 | 两分支类型不同；靠 `@ViewBuilder` 包成 `_ConditionalContent`，或统一结构 |
| 修饰符顺序换了，效果不一样 | 修饰符是「逐层向外包」，顺序即嵌套顺序 |
| `Text.font()` 后类型还是 `Text` | `Text` 上的字体/颜色类修饰符返回 `Text` 本身，不是 `ModifiedContent` |
| `UIHostingController.view.subviews` 是空的 | 没挂窗口、没跑渲染循环；内容在渲染阶段才落地 |
| 想用 `AnyView` 到处擦类型 | 能不用就不用：它关掉编译期类型信息，有 diff/性能代价 |

## 小结

- `View` 协议只要求一个 `body: some View`；`body` 由 SwiftUI 替你求值，必须快且无副作用。
- `some View` 是 opaque 类型，替你隐藏 `ModifiedContent<...>` 这种又长又深的具体类型。
- **修饰符是值语义**：不改原视图，而是包一层返回新视图——所以顺序有意义。
- `VStack`/`HStack`/`ZStack` 靠 `@ViewBuilder` 把多个子视图打成 `TupleView`。
- 视图组合零成本，大胆把子树抽成独立 `View`。
- SwiftUI 底层仍是 UIKit：渲染进 `UIHostingController` 的 `_UIHostingView`。下一章讲
  **状态与数据流**（`@State`/`@Binding`/`@Observable`），那才是 SwiftUI「自动刷新」的来源。
