# 11 · SwiftUI 列表与导航：List / ForEach / Section / NavigationStack

> 示例：`examples/11_list_navigation/main.swift`
> 实测输出见 `build/11_list_navigation/stdout.debug.txt`

列表 + 导航是绝大多数 App 的骨架：一屏列表，点一行进详情。SwiftUI 把这套做得非常
声明式，但**正确性全靠 `Identifiable` 的稳定 id**。本章讲清列表、分组、过滤、以及
`NavigationStack` 的类型安全路由。

> 部署目标 iOS 15：`NavigationView` 在 iOS 16 已**弃用**（用了会产生弃用告警，违反
> 本教程「零告警」硬约束）。所以导航部分放在 `if #available(iOS 16.0, *)` 里用
> `NavigationStack`；模拟器是 iOS 18，运行时真的会走进去。

## 1) Identifiable：列表正确性的地基

```swift
struct Contact: Identifiable, Equatable {
    let id = UUID()          // 稳定唯一 id
    let name: String
    let group: String
}
```

`List` / `ForEach` 靠每一行的 `id` 做 **diff**：哪些行是新增、哪些删除、哪些只是移动。
id 稳定且唯一，行才能被正确复用，增删动画才不会乱跳。

```
-- Identifiable：每行有稳定唯一的 id --
  ok   四个联系人有四个不同的 id（无碰撞）
  ok   同一个对象的 id 稳定不变
```

> **坑**：如果用**数组下标**当 id（`ForEach(0..<arr.count, id: \.self)`），一旦中间
> 插入/删除一行，后面所有行的「id」全变了，SwiftUI 会误判成「所有行都变了」，动画和
> 选中态全乱。**永远给数据一个稳定的业务 id**（`Identifiable` 或 `id:` 指定真实主键）。

## 2) ForEach：把数据数组映射成一组视图

```swift
ForEach(contacts) { c in          // Contact: Identifiable，无需手写 id:
    Text(c.name)
}
```

实测类型 `ForEach<Array<Contact>, UUID, Text>`——三个泛型参数分别是**数据类型**、
**id 类型**、**行视图类型**。`ForEach` 本身就是一个 `View`，而且它的 `data` 成员是
公开的：

```
-- ForEach：把数据映射成视图 --
  ForEach 类型 = ForEach<Array<Contact>, UUID, Text>
  ok   ForEach 是一个视图，内部持有数据与行构造闭包
  ok   ForEach 持有全部 4 条数据
```

`ForEach` 与 `List` 的关系：`List` 是一个自带滚动、分隔线、行样式的容器；里面可以直接
放 `ForEach`，也可以放 `Section { ForEach }`。要在**非 List** 的滚动里放很多行，用
`ScrollView { LazyVStack { ForEach … } }`。

## 3) LazyVStack vs VStack：懒加载

```swift
LazyVStack { Text("a"); Text("b") }   // 只构建可见行
VStack     { Text("a"); Text("b") }   // 一次性构建全部
```

```
-- LazyVStack：只构建可见行（长列表用）--
  LazyVStack 类型 = LazyVStack<TupleView<(Text, Text)>>
  VStack     类型 = VStack<TupleView<(Text, Text)>>
  ok   LazyVStack 是独立类型（滚动时才逐行构建）
  ok   普通 VStack 会一次性构建全部子视图
```

两者类型名只差一个 `Lazy` 前缀，行为差别却很大：

- **`VStack`**：立即构建**所有**子视图。10000 行就一次性建 10000 个视图，卡死。
- **`LazyVStack`**：只在子视图**即将进入可见区域**时才构建，滚出去的可以回收。
  长列表必须用它（或直接用 `List`，`List` 内部就是懒的）。

> **代价**：`LazyVStack` 在没滚动到之前不知道每行多高，某些依赖「总高度」的布局
> （比如把它放进另一个会问子视图理想尺寸的容器）会算不准。短列表用 `VStack` 更简单。

## 4) Section：分组

真实的分组 `List` 这样写：

```swift
List {
    ForEach(groupNames, id: \.self) { group in
        Section(header: Text(group)) {
            ForEach(grouped[group]!) { c in Text(c.name) }
        }
    }
}
```

分组本身是**纯 Swift 逻辑**，可以脱离 UI 单独测：

```swift
var grouped: [String: [Contact]] = [:]
for c in contacts { grouped[c.group, default: []].append(c) }
```

```
-- Section：按 group 分组 --
  分组结果 = 同事(2), 家人(1), 朋友(1)
  ok   分成三组：同事/家人/朋友
  ok   同事组 2 人
  ok   家人组 1 人
  ok   Section 是一个视图（带 header 与内容）
```

`Section` 也是个 `View`，能带 `header:` / `footer:`。把「分组算法」和「Section 视图」
分开，是让 UI 代码可测的关键——算法用纯数据断言，视图只验证能构造。

## 5) 搜索过滤：一个纯函数

`.searchable(text: $query)` 背后就是一个过滤函数。把它写成纯函数，确定可测：

```swift
func filter(_ all: [Contact], by query: String) -> [Contact] {
    guard !query.isEmpty else { return all }
    return all.filter { $0.name.contains(query) }
}
```

```
-- 搜索过滤：纯函数，确定可测 --
  ok   空查询返回全部
  ok   查「张」命中张三
  ok   查不到的字返回空数组（不是 nil、不崩）
```

空查询返回全部、查不到返回空数组（不是 `nil`、不崩溃）——这些都是能稳稳断言的性质。

## 6) NavigationStack：类型安全的导航（iOS 16+）

iOS 16 起，导航从 `NavigationView`（已弃用）换成 `NavigationStack`。核心是
**基于值的路由**：`NavigationLink(value:)` 压入一个**值**，`.navigationDestination(for:)`
声明「遇到这种类型的值，跳这个页面」。

```swift
NavigationStack {
    List(contacts) { c in
        NavigationLink(value: c.name) { Text(c.name) }   // 压入一个 String 值
    }
    .navigationDestination(for: String.self) { name in   // String → 详情页
        Text("详情：\(name)")
    }
}
```

```
-- NavigationStack：一叠页面 + 路由 --
  NavigationStack 类型 = NavigationStack<NavigationPath, ModifiedContent<List<…>, NavigationDestinationModifier<String, Text>>>
  ok   NavigationStack 可构造（iOS 16+）
  ok   NavigationLink 是一个视图
  ok   新建的 NavigationPath 是空栈（count==0）
```

三个要点：

**（a）value + destination = 类型安全路由。** 压栈的是**数据**（`c.name`），不是**视图**。
目的地由 `.navigationDestination(for: String.self)` 统一声明。好处：解耦（列表不必知道
详情页长什么样）、可对多种类型分别路由。

**（b）`NavigationPath` 让你程序化控制导航栈。**

```swift
@State var path = NavigationPath()
NavigationStack(path: $path) { … }
// path.append(x)  → 压一页
// path.removeLast() → 弹一页
// path = NavigationPath() → 回到根
```

`NavigationPath()` 新建时是空栈（`count == 0`）。想「点通知直接跳到某个详情页」，
就往 `path` 里 append 对应的值。`NavigationPath` 是**类型异构**的（能装不同类型的值）；
如果要类型同构、可 Codable 持久化，用 `[String]` 之类具体数组当 path。

**（c）`NavigationLink` 就是普通视图**，可以自定义外观（label 是任意 View）。

> **iOS 15 怎么办？** 用 `NavigationView` + `NavigationLink(isActive:)` 或
> `navigationTitle`。但新代码一律上 `NavigationStack`——`NavigationView` 已弃用，
> 且在 iPad 上默认是分栏（split）行为，常要 `.navigationViewStyle(.stack)` 强制单栏。

## 心智模型小结

```
List/ForEach 靠 Identifiable.id 做 diff：稳定 id 才能正确复用行、跑增删动画
长列表用 LazyVStack/List（懒），别用 VStack（一次性全建）
Section 分组；.searchable 背后就是一个过滤纯函数
NavigationStack（iOS16+）用 value + navigationDestination 做类型安全路由
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 增删行动画乱跳、选中态错位 | 用了下标当 id；换成稳定的 `Identifiable.id` |
| 长列表卡顿 | 用了 `VStack`（全量构建）；换 `LazyVStack` 或 `List` |
| `NavigationView` 编译有弃用告警 | iOS 16 起改用 `NavigationStack` |
| iPad 上列表莫名变分栏 | `NavigationView` 默认 split；用 `NavigationStack` 或 `.navigationViewStyle(.stack)` |
| 想代码里控制「返回根/跳到某页」 | 用 `NavigationStack(path:)` + 改 `NavigationPath` |
| `navigationDestination` 不生效 | value 的类型和 `for:` 声明的类型对不上 |

## 小结

- `Identifiable` 的稳定 id 是列表 diff、行复用、增删动画的地基——别用下标当 id。
- `ForEach<Data, ID, Content>` 把数据映射成一组视图；`List` 是自带滚动/样式的容器。
- 长列表用 `LazyVStack`（懒构建），短列表用 `VStack`。
- 分组、过滤写成**纯函数**，与 `Section`/`.searchable` 视图分离，才可测。
- iOS 16+ 用 `NavigationStack`：`NavigationLink(value:)` 压值，
  `.navigationDestination(for:)` 类型安全路由，`NavigationPath` 程序化控栈。
- 下一章讲**绘制与动画**。
