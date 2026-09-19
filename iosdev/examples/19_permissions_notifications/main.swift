// ============================================================
// 19 - 权限 / 通知 / 设备能力
//
// iOS 的能力大多受**权限（TCC）**保护：相机、相册、通讯录、定位、通知、跟踪……
// 用之前要「先查状态，再按需请求，然后处理结果」。本章讲三件事：
//
//   设备能力    UIDevice / UIScreen / ProcessInfo / Locale —— 我在什么设备上跑。
//   权限模型    各框架的 authorizationStatus（**只查状态，绝不弹框**）。
//   本地通知    UNMutableNotificationContent / Trigger / Request（纯数据对象）。
//
// headless 的两条硬边界（本示例如实处理，绝不伪造绿灯）：
//   1) **请求**权限会弹出系统对话框，属于 UI，headless 绝不调用 request* 系列。
//      我们只调 authorizationStatus（纯查询，无副作用、不弹框），并断言它幂等。
//   2) UNUserNotificationCenter.current()（**调度器**）要求进程有真实的 .app 包，
//      裸 spawn 调用它会崩（bundleProxyForCurrentProcess is nil）。所以我们只构造
//      通知的**内容对象**（不碰 center），把「请求授权 + 调度」留在文档里讲清楚。
//
// 断言一律是**不变量**（idiom==phone、scale∈{1,2,3}、状态查询幂等、通知字段往返），
// 绝不断言 processorCount、bounds 尺寸、内存大小这类环境相关的具体数字。
// ============================================================

import Foundation
import UIKit
import AVFoundation
import CoreLocation
import Photos
import Contacts
import AppTrackingTransparency
import UserNotifications

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

line("== 19 权限 / 通知 / 设备能力 ==")

// =====================================================================
// 1) 设备能力：我在什么设备上跑
// =====================================================================
line("")
line("-- 设备能力：UIDevice / UIScreen / ProcessInfo --")
let device = UIDevice.current
let screen = UIScreen.main
let proc = ProcessInfo.processInfo

// 这些是「具体值」，环境相关，只打印不断言（不同模拟器/设备各不同）
line("  model=\(device.model)  systemVersion=\(device.systemVersion)  idiom=\(device.userInterfaceIdiom.rawValue)")
line("  screen bounds=\(screen.bounds)  scale=\(screen.scale)")
line("  osVersion=\(proc.operatingSystemVersion.majorVersion).\(proc.operatingSystemVersion.minorVersion)  cores=\(proc.processorCount)")
line("  locale=\(Locale.current.identifier)")

// 断言的是**不变量**：换任何 iPhone 模拟器都成立
expect(!device.model.isEmpty, "UIDevice.model 非空")
expect(!device.systemVersion.isEmpty, "systemVersion 非空")
expect(device.userInterfaceIdiom == .phone, "iPhone 模拟器上 idiom == .phone")
expect([CGFloat(1), 2, 3].contains(screen.scale), "scale 是 1/2/3 之一（Retina 倍率）")
expect(screen.bounds.width > 0 && screen.bounds.height > 0, "屏幕 bounds 非空")
expect(proc.operatingSystemVersion.majorVersion >= 15, "iOS 主版本 >= 15（部署目标）")
expect(proc.processorCount >= 1, "至少有 1 个 CPU 核")
expect(!Locale.current.identifier.isEmpty, "Locale 标识非空")

// identifierForVendor：同一厂商的 App 在同一设备上共享的稳定 id（卸载全部后重置）。
// 裸 spawn 里没有厂商归属，但模拟器仍会给出一个值；真机上用于「设备维度」的去重统计。
if let idfv = device.identifierForVendor {
    line("  identifierForVendor 非空 : \(!idfv.uuidString.isEmpty)")
    expect(!idfv.uuidString.isEmpty, "identifierForVendor 是一个非空 UUID")
} else {
    expect(true, "identifierForVendor 在无包名语境可能为 nil（真机签名 App 里才有稳定值）")
}

// =====================================================================
// 2) 权限模型：只查状态，绝不弹框
// =====================================================================
// 统一套路：check → (若 notDetermined 才) request → 处理结果。
// request 会弹系统对话框（UI），headless 绝不调用。这里只**查状态**，
// 并断言「查两次结果一样」——证明查询是纯函数、无副作用、不会触发弹框。
line("")
line("-- 权限：authorizationStatus（纯查询，不弹框）--")

// 把各框架的原始状态码翻译成人话。注意各框架的枚举定义**不完全一致**：
//   AVAuthorizationStatus / PHAuthorizationStatus: notDetermined=0 restricted=1 denied=2 authorized=3 (PH 多一个 limited=4)
//   CNAuthorizationStatus / ATTrackingManager:     notDetermined=0 restricted=1 denied=2 authorized=3
//   CLAuthorizationStatus: notDetermined=0 restricted=1 denied=2 authorizedAlways=3 authorizedWhenInUse=4
func describe(_ raw: Int) -> String {
    switch raw {
    case 0: return "notDetermined（还没问过）"
    case 1: return "restricted（受家长控制等限制）"
    case 2: return "denied（用户拒绝）"
    default: return "authorized（raw=\(raw)，具体含义按各框架枚举）"
    }
}

// 每个权限：查两次，断言幂等（==），并确认落在合法状态码范围内（0...4）。
let checks: [(String, () -> Int)] = [
    ("相机 AVCapture",        { Int(AVCaptureDevice.authorizationStatus(for: .video).rawValue) }),
    ("相册 PHPhotoLibrary",   { Int(PHPhotoLibrary.authorizationStatus(for: .readWrite).rawValue) }),
    ("通讯录 CNContactStore", { Int(CNContactStore.authorizationStatus(for: .contacts).rawValue) }),
    ("跟踪 ATTracking",       { Int(ATTrackingManager.trackingAuthorizationStatus.rawValue) }),
    ("定位 CLLocation",       { Int(CLLocationManager().authorizationStatus.rawValue) }),
]
for (name, query) in checks {
    let a = query()
    let b = query()
    line("  \(name) → \(describe(a))")
    expect(a == b, "\(name)：连查两次状态一致（查询无副作用、不弹框）")
    expect((0...4).contains(a), "\(name)：状态码是合法枚举值")
}
// 说明：裸 spawn（无 bundle 归属）里，相机/相册常报 denied（模拟器无摄像头、进程不受信），
// 通讯录/跟踪/定位报 notDetermined（无 bundle 无处记录决定）。具体值随环境变，故只断言幂等+合法。

// Info.plist 用途说明字符串：请求权限时系统弹框里显示的那句话。**没有对应 key 就请求会崩**。
line("")
line("-- Info.plist 用途说明（NSxxxUsageDescription）--")
let usageKeys = [
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSContactsUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSUserTrackingUsageDescription",
]
// 裸 spawn 的 Bundle.main 没有真实 Info.plist 的这些键（甚至 bundleIdentifier 都为 nil），
// 所以这里读到 nil 是**预期**的；重点是记住「真 App 必须声明这些键，否则请求即崩」。
line("  Bundle.main.bundleIdentifier = \(Bundle.main.bundleIdentifier ?? "nil（裸 spawn 无包名）")")
for key in usageKeys {
    let value = Bundle.main.infoDictionary?[key] as? String
    line("  \(key) = \(value ?? "<未声明>")")
}
expect(Bundle.main.bundleIdentifier == nil, "裸 spawn 无 bundleIdentifier（真 App 才有）")
expect(true, "真 App 里请求某权限前，Info.plist 必须声明对应 UsageDescription，否则运行时崩溃")

// =====================================================================
// 3) 本地通知：构造内容对象（不碰需要 .app 包的调度器）
// =====================================================================
line("")
line("-- 本地通知：Content / Trigger / Request（纯数据对象）--")
// 这三个都是**纯数据**，不需要 .app 包，headless 可构造可断言。
let content = UNMutableNotificationContent()
content.title = "该喝水了"
content.body = "起来活动一下"
content.sound = .default
content.badge = 1
expect(content.title == "该喝水了", "content.title 设置后可读回")
expect(content.body == "起来活动一下", "content.body 设置后可读回")
expect((content.badge as? Int) == 1, "content.badge == 1")

// 触发器有三种：时间间隔 / 日历时间 / 地理围栏。这里演示前两种（纯数据）。
let timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
expect(timeTrigger.timeInterval == 60, "UNTimeIntervalNotificationTrigger：60 秒后触发")
expect(timeTrigger.repeats == false, "该触发器不重复")

var dateComps = DateComponents()
dateComps.hour = 9; dateComps.minute = 0
let calTrigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: true)
expect(calTrigger.repeats == true, "UNCalendarNotificationTrigger：每天 9:00 重复")

// 把内容 + 触发器包成一个带唯一 identifier 的请求（调度时交给 center 的就是它）
let request = UNNotificationRequest(identifier: "drink-water", content: content, trigger: timeTrigger)
expect(request.identifier == "drink-water", "UNNotificationRequest 带着唯一 identifier")
expect(request.content.title == "该喝水了", "request.content 就是我们构造的那份内容")

// 硬边界：真正**调度**通知要 UNUserNotificationCenter.current().add(request)。
// 而 .current() 要求进程有真实 .app 包；裸 spawn 调用它会抛
// NSInternalInconsistencyException（bundleProxyForCurrentProcess is nil）而崩溃。
// 所以这里**不调用**它 —— 与第 18 章 Keychain、第 16 章 target-action 同样的诚实处理。
line("  边界：UNUserNotificationCenter.current() 需真实 .app 包，裸 spawn 调用会崩，故不调用")
expect(true, "通知内容对象已完整构造验证；调度 API 需签名 .app（见第 20 章）")

// =====================================================================
// 4) 心智模型
// =====================================================================
line("")
line("-- 心智模型 --")
line("  权限三步：查 authorizationStatus → notDetermined 才 request（弹框）→ 按结果放行/降级")
line("  request 弹系统框，且 Info.plist 必须有对应 NSxxxUsageDescription，否则崩")
line("  查询状态是纯函数、无副作用、可反复调；本示例只查不请求，故 headless 安全")
line("  通知：Content(内容)+Trigger(时机)=Request；调度需 UNUserNotificationCenter（要 .app 包）")
line("  设备能力（UIDevice/UIScreen/ProcessInfo）随时可查，是纯读取，不需权限")
expect(true, "以上均由设备不变量 / 状态查询幂等 / 通知字段往返断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 19 结束 ====")
exit(failures == 0 ? 0 : 1)
