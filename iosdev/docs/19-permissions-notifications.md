# 19 · 权限 / 通知 / 设备能力

> 示例：`examples/19_permissions_notifications/main.swift`（`Frameworks` 文件声明额外链接的框架）
> 实测输出见 `build/19_permissions_notifications/stdout.debug.txt`

iOS 上大多数能力受 **TCC（Transparency, Consent, and Control）** 保护：相机、相册、通讯录、
定位、通知、跨 App 跟踪……用之前必须「**先查状态 → 未决定才请求 → 按结果放行或降级**」。
本章讲设备能力、权限模型、本地通知三件事，并把 headless 的**两条硬边界**如实讲清楚。

> **两条硬边界**（本示例不伪造绿灯）：
> 1. **请求**权限会弹出系统对话框（UI），headless **绝不调用** `request*`；只调
>    `authorizationStatus`（纯查询、无副作用、不弹框），并断言它**幂等**。
> 2. `UNUserNotificationCenter.current()`（通知**调度器**）要求进程有真实 `.app` 包，
>    裸 `spawn` 调用它会崩（`bundleProxyForCurrentProcess is nil`）。所以只构造通知的
>    **内容对象**（不碰 center）。

## 1) 设备能力：我在什么设备上跑

`UIDevice` / `UIScreen` / `ProcessInfo` / `Locale` 是**纯读取**，不需要任何权限，随时可查：

```swift
let device = UIDevice.current      // model / systemVersion / userInterfaceIdiom / identifierForVendor
let screen = UIScreen.main         // bounds / scale
let proc   = ProcessInfo.processInfo   // operatingSystemVersion / processorCount
let locale = Locale.current.identifier
```

```
-- 设备能力：UIDevice / UIScreen / ProcessInfo --
  model=iPhone  systemVersion=18.3.1  idiom=0
  screen bounds=(0.0, 0.0, 402.0, 874.0)  scale=3.0
  osVersion=18.3  cores=8
  locale=zh_CN
  ok   UIDevice.model 非空
  ok   iPhone 模拟器上 idiom == .phone
  ok   scale 是 1/2/3 之一（Retina 倍率）
  ok   屏幕 bounds 非空
  ok   iOS 主版本 >= 15（部署目标）
  ...
  ok   identifierForVendor 是一个非空 UUID
```

> **断言不变量，不断言具体数字**：`cores=8`、`bounds=402×874`、`systemVersion=18.3.1` 这些
> 是**环境相关**的具体值，只打印、**不断言**（换设备/模拟器就变）。断言的是**任何 iPhone 都
> 成立**的不变量：`idiom == .phone`、`scale ∈ {1,2,3}`、`bounds` 非空、`osMajor >= 15`、
> `cores >= 1`。这与全教程「只断言性质、不断言环境数字」的纪律一致。

`identifierForVendor`（IDFV）是**同一厂商**的 App 在同一设备上的稳定标识（用户卸载该厂商全部
App 后重置），常用于设备维度去重。裸 spawn 无厂商归属，但模拟器仍给值；真机签名 App 里才有
稳定语义。

## 2) 权限模型：只查状态，绝不弹框

统一套路——**check → request → handle**：

```swift
switch AVCaptureDevice.authorizationStatus(for: .video) {
case .notDetermined:
    // 只有「还没问过」时才请求 —— request 会弹系统框（UI）
    AVCaptureDevice.requestAccess(for: .video) { granted in /* 放行 or 降级 */ }
case .authorized:
    break                              // 已授权，直接用
case .denied, .restricted:
    break                              // 引导用户去「设置」里手动开
@unknown default: break
}
```

本示例**只走第一步的查询**（纯函数），断言「查两次结果一致」来证明查询无副作用、不弹框：

```swift
let a = query(); let b = query()
expect(a == b, "连查两次一致（不弹框）")
expect((0...4).contains(a), "状态码是合法枚举值")
```

```
-- 权限：authorizationStatus（纯查询，不弹框）--
  相机 AVCapture → denied（用户拒绝）
  ok   相机 AVCapture：连查两次状态一致（查询无副作用、不弹框）
  ok   相机 AVCapture：状态码是合法枚举值
  相册 PHPhotoLibrary → denied（用户拒绝）
  通讯录 CNContactStore → notDetermined（还没问过）
  跟踪 ATTracking → notDetermined（还没问过）
  定位 CLLocation → notDetermined（还没问过）
  （其余四条同样各断言「幂等 + 状态码合法」，实测输出里逐条列出，此处从略）
```

> **为什么相机/相册是 denied，其余是 notDetermined？** 裸 spawn 没有 bundle 归属：
> 相机/相册在这种不受信、且模拟器无摄像头的语境下报 `denied`；通讯录/跟踪/定位因为
> 「没有 bundle id 就没处记录用户的决定」而停在 `notDetermined`。**具体值随环境变**，所以
> 示例只断言「幂等 + 合法枚举」，不断言到底是哪一个。

⚠️ **各框架的状态码枚举不完全一致**，别混用。尤其定位：

| 框架 | 0 | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- | --- |
| `AVAuthorizationStatus` | notDetermined | restricted | denied | authorized | — |
| `PHAuthorizationStatus` | notDetermined | restricted | denied | authorized | limited |
| `CNAuthorizationStatus` / `ATTrackingManager` | notDetermined | restricted | denied | authorized | — |
| `CLAuthorizationStatus` | notDetermined | restricted | denied | authorized**Always** | authorized**WhenInUse** |

## 3) Info.plist 用途说明：漏了就崩

请求某权限前，`Info.plist` **必须**声明对应的 `NSxxxUsageDescription` 字符串——它就是系统弹框
里给用户看的那句解释。**没声明就请求 → 运行时直接崩**（不是返回 denied，是 crash）。

```
<key>NSCameraUsageDescription</key>            <string>用于扫描二维码</string>
<key>NSPhotoLibraryUsageDescription</key>      <string>用于选择要上传的照片</string>
<key>NSContactsUsageDescription</key>          <string>用于查找通讯录里的好友</string>
<key>NSLocationWhenInUseUsageDescription</key> <string>用于显示附近的门店</string>
<key>NSUserTrackingUsageDescription</key>      <string>用于个性化广告</string>
```

```
-- Info.plist 用途说明（NSxxxUsageDescription）--
  Bundle.main.bundleIdentifier = nil（裸 spawn 无包名）
  NSCameraUsageDescription = <未声明>
  ...
  ok   裸 spawn 无 bundleIdentifier（真 App 才有）
```

裸 spawn 的 `Bundle.main` 没有真实 `Info.plist`（`bundleIdentifier` 都为 nil），所以读到「未声明」
是**预期**的；重点是记住这条规则。真实 `Info.plist` 的构造与打包在第 20 章演示。

## 4) 本地通知：Content + Trigger = Request

本地通知由三块**纯数据对象**组成——它们不需要 `.app` 包，headless 可构造可断言：

```swift
let content = UNMutableNotificationContent()
content.title = "该喝水了"; content.body = "起来活动一下"
content.sound = .default; content.badge = 1

// 触发器三选一：时间间隔 / 日历时间 / 地理围栏
let timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
let calTrigger  = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

let request = UNNotificationRequest(identifier: "drink-water", content: content, trigger: timeTrigger)
```

```
-- 本地通知：Content / Trigger / Request（纯数据对象）--
  ok   content.title 设置后可读回
  ok   content.badge == 1
  ok   UNTimeIntervalNotificationTrigger：60 秒后触发
  ok   UNCalendarNotificationTrigger：每天 9:00 重复
  ok   UNNotificationRequest 带着唯一 identifier
  ok   request.content 就是我们构造的那份内容
  边界：UNUserNotificationCenter.current() 需真实 .app 包，裸 spawn 调用会崩，故不调用
```

真正**调度**通知要：

```swift
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in }
UNUserNotificationCenter.current().add(request) { error in }
```

> **为什么这里不调用 `.current()`？** 它要求进程有真实 `.app` 包，裸 `spawn` 调用会抛
> `NSInternalInconsistencyException`（`bundleProxyForCurrentProcess is nil`）**而崩溃**。
> 这与第 18 章 Keychain（无 entitlement 被拒）、第 16 章 target-action（需真实事件系统）是
> 同一种诚实处理：**完整写出正确 API 用法，标注 headless 边界，绝不伪造成功**。签名 `.app`
> （第 20 章）里这些调用完全正常。

**推送通知**（remote）则还需要：`UIApplicationDelegate` 里注册
`registerForRemoteNotifications()`、拿到 device token 交给你的服务器、服务器经 APNs 下发；
`Info.plist` 配 `aps-environment` entitlement。这属于需要真实签名与后端的部分，不在 headless 示例内。

## 心智模型小结

```
设备能力（UIDevice/UIScreen/ProcessInfo）：纯读取，不需权限，随时可查
权限三步：查 authorizationStatus → notDetermined 才 request（弹框）→ 放行/降级
Info.plist 必须有对应 NSxxxUsageDescription，否则请求即崩（不是 denied）
各框架状态码枚举不一致，定位尤其特殊（always / whenInUse）
本地通知：Content + Trigger = Request（纯数据）；调度靠 UNUserNotificationCenter（需 .app 包）
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 一请求权限 App 就崩 | `Info.plist` 缺对应的 `NSxxxUsageDescription` |
| 权限框只弹一次，之后再也不弹 | 用户已决定过；`request*` 不会再弹，得引导去「设置」 |
| 把定位的 `authorized` 当 3 | `CLAuthorizationStatus` 里 3=Always、4=WhenInUse，与别的框架不同 |
| headless 里调 `request*` 卡住/弹框 | 请求是 UI；自测只查 `authorizationStatus` |
| 裸进程调 `UNUserNotificationCenter.current()` 崩 | 需真实 `.app` 包；调度 API 只能在签名 App 里跑 |
| 断言 `processorCount==8`/具体 bounds 换个设备就挂 | 环境相关值不该断言；改断言不变量（`>=1`、`非空`、`∈{1,2,3}`） |

## 小结

- **设备能力**：`UIDevice`/`UIScreen`/`ProcessInfo`/`Locale` 纯读取、免权限；断言不变量而非具体数字。
- **权限**：check→request→handle；本示例**只查状态**并断言幂等（证明不弹框）；各框架枚举不一致，
  `Info.plist` 的 `UsageDescription` 缺了就崩。
- **本地通知**：`Content`+`Trigger`=`Request` 是纯数据，headless 可验证；调度器
  `UNUserNotificationCenter.current()` 需真实 `.app` 包，裸 spawn 调用会崩——如实标注边界。
- 下一章（本教程最后一章）把这些串起来：**打包 / 签名 / 上架**——构造一个真正的 `.app` 包，
  签名、装进模拟器、启动它。
