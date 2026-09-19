# 03 · App 生命周期与场景（Scene）

> 示例：`examples/03_lifecycle/main.swift`
> 实测输出见 `build/03_lifecycle/stdout.debug.txt`

一个 iOS App 从被点开、到退到后台、再回来、最后被系统回收，中间系统会**按固定顺序**
调用一连串回调。搞懂这个顺序，你才知道「数据该在哪一刻保存」「动画该在哪一刻暂停」
「为什么我 `applicationWillTerminate` 里的代码根本没跑」。

## 1) 两层生命周期：进程级 与 场景级

iOS 13 之前，生命周期全挂在 `AppDelegate` 上。iOS 13 引入**多窗口**（iPad 上一个 App
可以开好几个窗口）之后，苹果把它拆成两层：

| 层 | 谁负责 | 管什么 | 有几份 |
|---|---|---|---|
| **进程级** | `AppDelegate` | App 进程的启动、终止、全局初始化 | 整个进程**一份** |
| **场景级** | `SceneDelegate` | 每个窗口的前台/后台/挂起/断开 | 每个场景**一份**（iPad 多窗口时多份） |

关键推论：**「界面进后台了」是场景级事件，不是进程级事件。**
用户在 iPad 上把你的一个窗口划走，那个场景进后台了，但**进程还活着**，
另一个窗口还在前台。所以「保存当前界面的状态」要写在场景级回调里。

## 2) 一次完整的生命周期顺序

下图是一次典型的「冷启动 → 用一会儿 → 退后台 → 又回来 → 场景被回收 → 进程终止」：

```
进程启动
  └─ app: didFinishLaunchingWithOptions        [AppDelegate]  一次性初始化
场景创建
  └─ scene: willConnectTo                       [SceneDelegate] 建窗口、设根控制器
进入前台
  ├─ scene: willEnterForeground                 [SceneDelegate]
  └─ scene: didBecomeActive                     [SceneDelegate] 现在可交互
用户按 Home / 上滑回桌面
  ├─ scene: willResignActive                    [SceneDelegate] 失去焦点（不再响应输入）
  └─ scene: didEnterBackground                  [SceneDelegate] ★ 在这里保存数据
用户又点开 App
  ├─ scene: willEnterForeground
  └─ scene: didBecomeActive
系统回收这个场景（多窗口下关掉一个窗口 / 内存吃紧）
  └─ scene: didDisconnect                       [SceneDelegate] 释放该场景资源
进程即将终止
  └─ app: applicationWillTerminate              [AppDelegate]  ⚠ 不保证被调用
```

示例 03 用一个「记录器」把上面这串顺序**原样模拟**出来并断言（真实回调只有在打包成
`.app` 被系统启动时才会触发，见第 20 章；headless 下我们验证的是**顺序契约**本身）：

```swift
func driveUIKitLifecycle(_ rec: LifecycleRecorder) {
    rec.record("app:didFinishLaunching")
    rec.record("scene:willConnect")
    rec.record("scene:willEnterForeground")
    rec.record("scene:didBecomeActive")
    rec.record("scene:willResignActive")     // 退后台前必先失去焦点
    rec.record("scene:didEnterBackground")
    rec.record("scene:willEnterForeground")  // 又回来
    rec.record("scene:didBecomeActive")
    rec.record("scene:didDisconnect")
    rec.record("app:willTerminate")
}
```

实测输出：

```
-- UIKit：进程级 + 场景级回调顺序 --
  记录到的事件数 = 10
  ok   UIKit：生命周期回调顺序与文档一致
  ok   进程级事件只在启动/终止各出现一次
  ok   场景级事件随前后台切换可多次发生
  ok   退后台前必先失去焦点（resignActive→enterBackground）
```

从这串断言能读出三条**性质**（比死记顺序更有用）：

- **进程级事件各只出现一次**（启动一次、终止一次）；
- **场景级事件会随前后台切换反复出现**（`didBecomeActive` 出现了 2 次）；
- **退后台前必先 `willResignActive` 再 `didEnterBackground`**，不会直接跳到后台。

## 3) 每个回调该做什么（实战建议）

| 回调 | 典型用途 |
|---|---|
| `didFinishLaunchingWithOptions` | 一次性初始化：配置 SDK、建持久化容器、注册推送 |
| `scene(_:willConnectTo:)` | 建 `UIWindow`、设 `rootViewController`、恢复该场景的状态 |
| `sceneDidBecomeActive` | 恢复：开始动画、恢复暂停的游戏/视频、刷新数据 |
| `sceneWillResignActive` | 暂停：遮隐私、停正在进行的交互（来电/下拉通知中心时也会触发） |
| `sceneDidEnterBackground` | ★ **保存数据**、释放可重建的资源、注销网络 |
| `sceneDidDisconnect` | 释放**该场景**独有的资源（多窗口时别的窗口还在） |
| `applicationWillTerminate` | ⚠ 最后兜底，但**不保证被调用**，别把关键保存只放这里 |

> **为什么 `applicationWillTerminate` 不可靠**：App 退到后台后，系统随时可能因为
> 内存压力直接把它**挂起（suspend）甚至杀掉**，这时根本不会再给你 terminate 回调。
> 所以「保存」的正确位置是 **`sceneDidEnterBackground`**（或更早的 `willResignActive`），
> 而不是 terminate。这是 iOS 新手最常踩的坑之一。

## 4) SwiftUI：把两层收敛成一个 `scenePhase`

SwiftUI 里没有 AppDelegate/SceneDelegate 的样板代码。生命周期被收敛成**一个环境值**
`@Environment(\.scenePhase)`，它在三个状态间切换：

```swift
import SwiftUI

@main
struct HelloApp: App {
    @Environment(\.scenePhase) private var scenePhase   // .active / .inactive / .background

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:     break   // 可交互：恢复动画、刷新
            case .inactive:   break   // 过渡态：来电 / 上拉多任务预览
            case .background: break   // ★ 后台：保存数据、释放资源
            }
        }
    }
}
```

三态与 UIKit 回调的对应关系：

| SwiftUI `scenePhase` | 大致对应 UIKit |
|---|---|
| `.active` | `didBecomeActive` |
| `.inactive` | `willResignActive`（以及启动/回前台的过渡瞬间） |
| `.background` | `didEnterBackground` |

示例 03 用一个 `PhaseHandler` 状态机模拟 `onChange(of: scenePhase)`，断言切换顺序：

```
-- SwiftUI：scenePhase 三态 --
  ok   SwiftUI：scenePhase 依次经过 active→inactive→background→active
  ok   scenePhase 三态可用 rawValue 互转（便于持久化/日志）
```

> SwiftUI 的 `scenePhase` **只覆盖场景级**。进程级的「启动完成 / 即将终止」在纯
> SwiftUI App 里没有直接对应物 —— 需要时用 `@UIApplicationDelegateAdaptor`
> 把一个 `AppDelegate` 接回 SwiftUI App（第 20 章会用到）。

## 5) 场景是怎么被「配置」出来的

UIKit App 要在 `Info.plist` 里声明「我用场景」，并指明场景的 delegate 类：

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key><true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneDelegateClassName</key><string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

或者用代码返回配置（示例 02 的 AppDelegate 里就是这种写法）：

```swift
func application(_ application: UIApplication,
                 configurationForConnecting session: UISceneSession,
                 options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: nil, sessionRole: session.role)
    config.delegateClass = SceneDelegate.self
    return config
}
```

- `UIApplicationSupportsMultipleScenes = true` → iPad 上允许开多个窗口；
  iPhone 上即使设了 true 也基本只有一个场景。
- **状态恢复**：系统在 `didDisconnect` 时可以把场景的状态存进 `UISceneSession.stateRestorationActivity`，
  下次 `willConnectTo` 时读回来，实现「App 被杀后重开，回到原来那一屏」。

## 6) 概念对照小结

```
-- 谁负责什么 --
  AppDelegate   ：进程生命周期（启动、终止）——全局仅一份
  SceneDelegate ：每个窗口的前台/后台/挂起——iPad 多窗口时有多份
  SwiftUI       ：把上面两层收敛成 @Environment(\.scenePhase) 一个值
```

## 小结

- 生命周期分**进程级（AppDelegate）**和**场景级（SceneDelegate）**两层；
  iOS 13 引入多窗口后，「界面前后台」属于场景级。
- 顺序：`didFinishLaunching → willConnect → willEnterForeground → didBecomeActive`，
  退后台是 `willResignActive → didEnterBackground`，可反复。
- **保存数据放 `didEnterBackground`**，别指望 `willTerminate`（系统可能直接杀进程）。
- SwiftUI 用一个 `@Environment(\.scenePhase)`（active/inactive/background）+
  `onChange` 收敛了场景级；进程级要用 `@UIApplicationDelegateAdaptor` 接回来。
- 多窗口靠 `Info.plist` 的 Scene Manifest 或 `configurationForConnecting` 配置；
  状态恢复走 `stateRestorationActivity`。

下一章进入第二篇：`04-objc-language.md` —— Objective-C 语言基础（iOS 存量代码绕不开它）。
