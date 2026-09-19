# 02 · 第一个 App：SwiftUI 与 UIKit 两条最小骨架

> 示例：`examples/02_hello_app/main.swift`
> 实测输出见 `build/02_hello_app/stdout.debug.txt`

上一章讲清了技术栈和工具链。这一章动手写「Hello iOS」—— 而且是**两套写法各写一遍**，
让你从第一天就建立起 SwiftUI 与 UIKit 的对照关系。

## 1) SwiftUI：一个 `@main` 的 App 就是全部入口

SwiftUI 的 App 没有 AppDelegate、没有 storyboard、没有 `Info.plist` 里那堆场景配置。
入口就是一个标了 `@main` 的 `App`：

```swift
import SwiftUI

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()          // ← 窗口里显示的第一个视图
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Hello")
                .font(.title)
            Text("iOS")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

三个概念，一次讲清：

- **`App`**：整个应用的入口。`@main` 告诉系统「从这里开始」。它的 `body` 返回
  一个 **`Scene`**（场景），而不是视图。
- **`Scene` / `WindowGroup`**：一个场景对应一个（或一组）窗口。`WindowGroup { … }`
  里的内容就是窗口的根视图。iPhone 上通常只有一个窗口；iPad 多窗口时，
  系统会为每个窗口复制一份 `WindowGroup` 的内容。
- **`View`**：一个 `struct`，`body` 描述界面**长什么样**。注意 `body` 的类型是
  `some View`（不透明类型）—— 你只承诺「它是某个 View」，具体是什么由编译器推断。

> **关键心智**：SwiftUI 的 `body` 是**声明式**的。你不是在「一步步搭界面」，
> 而是在「描述当状态是 X 时界面应该是什么样」。状态变了，SwiftUI 重新求值 `body`、
> 算出差异、只更新变化的部分。你永远不用手动去 `label.text = …`。

`VStack` 把两个 `Text` 垂直堆起来，`.font`/`.foregroundStyle`/`.padding` 是**修饰符**
（modifier）—— 每个修饰符都返回一个**新的** View，把原来的包起来。所以视图是一棵
层层包裹的树，修饰符的顺序会影响结果（第 10 章细讲）。

## 2) UIKit：三个角色 + 一个入口函数

UIKit 的 App 是**命令式**的，入口是 `UIApplicationMain`（Swift 里通常由
`@main` 标注在 `AppDelegate` 上自动生成）。它牵扯三个角色：

```swift
import UIKit

// ① 进程级生命周期
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true   // 进程启动完成，做一次性初始化
    }
    // 告诉 UIKit：本 App 用 SceneDelegate 管理窗口场景
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// ② 场景级生命周期：在这里建窗口、设根控制器
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootViewController()   // ← 第一个界面
        window.makeKeyAndVisible()
        self.window = window
    }
}

// ③ 一屏内容：一个 UIViewController
final class RootViewController: UIViewController {
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Hello iOS"
        label.tag = 100
        label.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: root.centerYAnchor),
        ])
        self.view = root
    }
}
```

对照 SwiftUI，UIKit 要你**亲手做**很多事：

- 自己建 `UIWindow`，自己把它和一个 `UIWindowScene` 绑定；
- 自己设 `rootViewController`，自己 `makeKeyAndVisible`；
- 自己 `addSubview`，自己写 `NSLayoutConstraint` 把 label 居中；
- 界面要变，自己找到那个 label、自己改它的 `text`。

> **`loadView` vs `viewDidLoad`**：`loadView` 负责**创建** `self.view`（要么纯代码搭，
> 要么从 xib/storyboard 载入）；`viewDidLoad` 在 view 创建**之后**调用，用来做
> 「基于已有 view 的初始化」。本例用 `loadView` 纯代码搭界面。用 storyboard 时
> 一般不重写 `loadView`，而是在 `viewDidLoad` 里配置已被载入的 view。

## 3) 本示例怎么 headless 验证这两套骨架

示例 02 **不真的启动** App（那需要打包成 `.app`，第 20 章才做），而是把两套骨架里
**可验证的部分**单独构造出来跑断言：

```swift
// SwiftUI：构造根视图，确认视图树能求值
let contentView = ContentView()
expect(!String(describing: type(of: contentView.body)).isEmpty, "ContentView 可构造，body 可求值")

// UIKit：构造根控制器，触发 loadView，验证界面搭出来了
let vc = RootViewController()
vc.loadViewIfNeeded()                                  // 触发 loadView()
let label = vc.view.viewWithTag(100) as? UILabel
expect(label?.text == "Hello iOS", "居中的 UILabel 文本正确")
expect(vc.view.constraints.count >= 2, "Auto Layout 约束已激活")

// UIKit：窗口持有根控制器这层关系（不 makeKeyAndVisible）
let window = UIWindow()
window.rootViewController = RootViewController()
expect(window.rootViewController != nil, "window.rootViewController 已设置")
```

实测输出：

```
== 02 第一个 App：两套骨架 ==

-- SwiftUI 根视图 --
  ContentView.body 具体类型非空 : true
  ok   SwiftUI：ContentView 可构造，body 可求值

-- UIKit 根控制器 --
  ok   UIKit：loadViewIfNeeded 之后 view 已创建
  ok   UIKit：居中的 UILabel 文本正确
  ok   UIKit：用 Auto Layout 时该标志必须为 false
  根视图上的约束条数 >= 2 : true
  ok   UIKit：Auto Layout 约束已激活

-- UIKit 窗口装配 --
  ok   UIKit：window.rootViewController 已设置
  ok   UIKit：通过窗口也能取到根控制器里的 label

-- 心智模型对照 --
  SwiftUI：@main App → body(some Scene) → WindowGroup { ContentView() }
  UIKit  ：UIApplicationMain → AppDelegate → SceneDelegate → window.rootViewController
  ok   两套骨架都能独立跑起来（本示例已分别构造验证）

全部断言通过。
==== 02 结束 ====
```

> **为什么 `translatesAutoresizingMaskIntoConstraints` 必须是 false**：
> 用代码 `addSubview` 加进去的视图，默认这个标志是 `true`（系统会按旧的 frame/弹簧
> 模型自动生成一套约束），会和你的 Auto Layout 约束打架。所以**凡是要用约束布局的
> 视图，先把它设成 false**。从 xib/storyboard 载入的视图默认已经是 false。

## 4) 两套骨架对照表

| | SwiftUI | UIKit |
|---|---|---|
| 入口 | `@main struct …: App` | `@main class AppDelegate` + `UIApplicationMain` |
| 入口 body 返回 | `some Scene` | 无（走回调方法） |
| 窗口 | `WindowGroup` 自动管 | 手动 `UIWindow(windowScene:)` + `makeKeyAndVisible` |
| 第一屏 | `ContentView()`（一个 View struct） | `window.rootViewController`（一个 UIViewController） |
| 布局 | 修饰符 + 容器（VStack 等） | frame 或 `NSLayoutConstraint` |
| 改界面 | 改状态，SwiftUI 自动重绘 | 手动改控件属性 |
| 代码量 | 极少 | 明显更多 |

同一个「居中的 Hello」，SwiftUI 三行，UIKit 要建窗口、建控制器、建 label、写约束。
但 UIKit 给你的**控制粒度**也细得多 —— 这就是为什么复杂/定制界面有时仍要落到 UIKit。

## 小结

- SwiftUI 入口 = `@main` 的 `App`，`body` 返回 `Scene`，`WindowGroup` 里放根 `View`。
- UIKit 入口 = `AppDelegate`（进程）+ `SceneDelegate`（窗口）+ `UIViewController`（一屏），
  窗口、根控制器、约束都要**手动**搭。
- SwiftUI 声明式（描述结果），UIKit 命令式（描述步骤）。
- 本教程 headless 验证：构造真实的 View / UIViewController / UIWindow 跑断言，
  不真的启动 App；真正的打包启动在第 20 章。

下一章：`03-lifecycle.md` —— App 从启动到退后台再回来，系统按什么顺序调用谁。
