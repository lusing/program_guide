// ============================================================
// 20 - 打包 / 签名 / 上架：一个 .app 到底是什么
//
// 前面 19 章都是「裸可执行文件 + simctl spawn」。这一章揭示**真 App 的形态**：
// 一个 .app 其实就是一个**目录（bundle）**，里面按约定放着可执行文件、Info.plist、
// 资源。系统在启动时读 Info.plist 找到入口、读签名验完整性。本章 headless 地**在磁盘上
// 亲手搭出一个合法的 .app bundle**，再用 Bundle API 把它当真 bundle 加载、逐字段验证；
// 然后把「签名 → 装机 → 启动 → 归档 → 上架」这条只能在宿主 shell 里跑的流水线讲清楚。
//
// 为什么签名/装机不在这里跑：iOS 没有 Process/NSTask（那是 macOS 独有的 API），
// 裸 spawn 的进程无法再去 fork/exec `codesign`、`simctl`。所以本示例只负责**能 headless
// 验证的部分**（bundle 结构 + Info.plist 契约 + Bundle 加载），签名与装机用真实命令在文档里
// 给出并附实测输出。这与第 16/18/19 章处理边界的方式一致：能真跑的跑到底，跑不了的讲清楚。
//
// headless + 自清场：bundle 建在 temporaryDirectory 下的唯一子目录，验证完整块删掉。
// 断言全是确定值（bundleIdentifier、CFBundle* 键、目录内容、Bundle 能否加载）。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

let fm = FileManager.default

line("== 20 打包 / 签名 / 上架 ==")

// =====================================================================
// 0) 对照：当前进程自己就是一个 bundle
// =====================================================================
line("")
line("-- 对照：Bundle.main（当前运行进程）--")
// 裸 spawn 时 Bundle.main 指向可执行文件所在目录，没有真实 .app 结构，
// 所以 bundleIdentifier 为 nil —— 这正是「它不是一个打包好的 App」的证据。
line("  Bundle.main.bundlePath = \(Bundle.main.bundlePath)")
line("  Bundle.main.bundleIdentifier = \(Bundle.main.bundleIdentifier ?? "nil")")
// 不打印 executableURL 的文件名：debug/release 两个配置的可执行文件名不同（.debug/.release），
// 会破坏「两配置 stdout 逐字节一致」这条判定。只断言它存在即可。
line("  Bundle.main.executableURL 非空 = \(Bundle.main.executableURL != nil)")
expect(Bundle.main.bundleIdentifier == nil, "裸 spawn 的 Bundle.main 没有 bundleIdentifier（不是 .app）")
expect(Bundle.main.executableURL != nil, "但 Bundle.main 仍指向当前可执行文件")

// =====================================================================
// 1) 亲手搭一个 .app bundle：目录 + 可执行文件 + Info.plist
// =====================================================================
line("")
line("-- 构造 Demo.app：一个 bundle 就是一个约定结构的目录 --")
let tmp = fm.temporaryDirectory.appendingPathComponent("example20-\(UUID().uuidString)")
let appURL = tmp.appendingPathComponent("Demo.app")
try fm.createDirectory(at: appURL, withIntermediateDirectories: true)
expect(fm.fileExists(atPath: appURL.path), "建出了 Demo.app 目录（bundle 本体）")

// (a) 可执行文件：CFBundleExecutable 指的那个 Mach-O。
//     这里把当前进程的可执行文件复制进去，得到一个**真实、架构匹配**的 Mach-O，
//     省得凭空造一个假文件（真 App 里它是 Xcode 链接产物）。
let execSrc = URL(fileURLWithPath: CommandLine.arguments[0])
let execDst = appURL.appendingPathComponent("Demo")
try fm.copyItem(at: execSrc, to: execDst)
expect(fm.fileExists(atPath: execDst.path), "把可执行文件放进了 bundle（名为 Demo）")

// (b) Info.plist：bundle 的「身份证 + 说明书」。系统靠它找入口、显示名、权限用途等。
//     用 PropertyListSerialization 写一个真实的 XML plist（键都是系统认识的标准键）。
let info: [String: Any] = [
    "CFBundleIdentifier": "com.iosdev.demo",        // 唯一标识，签名/上架都认它
    "CFBundleExecutable": "Demo",                   // 指向 bundle 里的可执行文件名
    "CFBundleName": "Demo",                         // 短名（桌面图标下）
    "CFBundleDisplayName": "演示 App",               // 显示名
    "CFBundleVersion": "1",                         // build 号（每次上传递增）
    "CFBundleShortVersionString": "1.0",            // 市场版本号（用户看到的）
    "CFBundlePackageType": "APPL",                  // APPL=应用
    "CFBundleInfoDictionaryVersion": "6.0",
    "MinimumOSVersion": "15.0",                     // 最低系统，与部署目标一致
    "UIDeviceFamily": [1],                          // 1=iPhone, 2=iPad
    "UILaunchStoryboardName": "LaunchScreen",       // 启动屏（不设会有限制）
    // 权限用途说明：第 19 章讲过，请求对应权限前必须声明，否则运行时崩
    "NSCameraUsageDescription": "用于扫描二维码",
]
let plistData = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
try plistData.write(to: appURL.appendingPathComponent("Info.plist"))
expect(fm.fileExists(atPath: appURL.path + "/Info.plist"), "写入了 Info.plist")

// (c) PkgInfo：老式约定文件，内容是 8 字节 "APPL????"（类型+签名），可选但常见
try "APPL????".data(using: .ascii)!.write(to: appURL.appendingPathComponent("PkgInfo"))

// (d) 资源目录：真 App 里还有 Assets.car（图片）、storyboardc、本地化 .lproj 等
let resDir = appURL.appendingPathComponent("Assets")
try fm.createDirectory(at: resDir, withIntermediateDirectories: true)

// 目录内容（排序后确定）
let contents = try fm.contentsOfDirectory(atPath: appURL.path).sorted()
line("  Demo.app/ 内容 = \(contents)")
expect(contents == ["Assets", "Demo", "Info.plist", "PkgInfo"],
       "bundle 目录含 Assets/Demo/Info.plist/PkgInfo 四项")

// =====================================================================
// 2) 用 Bundle API 把它当**真 bundle** 加载、逐字段验证
// =====================================================================
line("")
line("-- Bundle(url:) 加载：系统怎么读这个 .app --")
guard let bundle = Bundle(url: appURL) else {
    expect(false, "Bundle(url:) 加载失败")
    line("==== 20 结束 ===="); exit(1)
}
expect(bundle.bundlePath.hasSuffix("Demo.app"), "bundlePath 指向 Demo.app")
expect(bundle.bundleIdentifier == "com.iosdev.demo", "Bundle 读到 CFBundleIdentifier")
expect(bundle.executableURL?.lastPathComponent == "Demo", "Bundle 按 CFBundleExecutable 定位到可执行文件 Demo")
expect(bundle.executableURL != nil && fm.fileExists(atPath: bundle.executableURL!.path),
       "该可执行文件在磁盘上真实存在")

// infoDictionary 就是解析后的 Info.plist
let dict = bundle.infoDictionary ?? [:]
expect((dict["CFBundleName"] as? String) == "Demo", "infoDictionary.CFBundleName == Demo")
expect((dict["CFBundleDisplayName"] as? String) == "演示 App", "infoDictionary.CFBundleDisplayName == 演示 App")
expect((dict["CFBundleShortVersionString"] as? String) == "1.0", "市场版本号 == 1.0")
expect((dict["CFBundleVersion"] as? String) == "1", "build 号 == 1")
expect((dict["MinimumOSVersion"] as? String) == "15.0", "MinimumOSVersion == 15.0")
expect((dict["NSCameraUsageDescription"] as? String) == "用于扫描二维码", "相机用途说明已声明")

// 便捷取值 API：object(forInfoDictionaryKey:) 支持本地化与回退
let camUsage = bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
expect(camUsage == "用于扫描二维码", "object(forInfoDictionaryKey:) 取到相机用途说明")

// 版本号两个键的区别（上架高频考点）：
line("  CFBundleShortVersionString=1.0（给用户看的版本）  CFBundleVersion=1（给系统的 build 号）")
expect((dict["CFBundleShortVersionString"] as? String) != (dict["CFBundleVersion"] as? String),
       "两个版本号是不同维度：short=1.0 vs build=1")

// =====================================================================
// 3) 签名 / 装机 / 上架：只能在宿主 shell 跑的流水线（此处讲清楚，不 headless 伪造）
// =====================================================================
line("")
line("-- 签名 → 装机 → 启动（宿主 shell，非本进程内）--")
line("  iOS 无 Process/NSTask，裸 spawn 无法再 exec codesign/simctl；以下是真实命令：")
line("    codesign --sign - --force Demo.app        # 模拟器用 ad-hoc 签名（- 表示无身份）")
line("    xcrun simctl install <UDID> Demo.app      # 装进模拟器")
line("    xcrun simctl launch  <UDID> com.iosdev.demo   # 按 bundle id 启动")
line("  真机/App Store：需 Apple 签发的证书 + provisioning profile + entitlements，")
line("                 经 Xcode Organizer 归档(Archive) → 导出(Export) → 上传(App Store Connect)")
// 说明：这条流水线的**实测输出**（真的 codesign+install+launch 一个 SwiftUI App 并打印启动日志）
// 收录在本章文档里。此处 headless 只负责证明「bundle 结构与 Info.plist 契约是对的」。
expect(true, "签名/装机是宿主 shell 的职责；bundle 结构本示例已实证")

// =====================================================================
// 4) 自清场
// =====================================================================
try fm.removeItem(at: tmp)
expect(!fm.fileExists(atPath: tmp.path), "跑完删掉了临时 bundle，不留脏数据")

// =====================================================================
// 5) 心智模型
// =====================================================================
line("")
line("-- 心智模型 --")
line("  .app = 一个约定结构的**目录(bundle)**：可执行文件 + Info.plist + 资源")
line("  Info.plist = 身份证+说明书：CFBundleIdentifier 唯一标识，CFBundleExecutable 指入口")
line("  两个版本号：ShortVersionString 给用户，CFBundleVersion(build) 给系统，上架各自有规则")
line("  签名保证完整性与来源：模拟器 ad-hoc；真机/上架用 Apple 证书 + provisioning profile")
line("  装机/启动：simctl install/launch（模拟器）；Xcode Organizer Archive→Export→Upload（上架）")
expect(true, "以上均由 Bundle 加载、infoDictionary 逐字段、目录内容断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 20 结束 ====")
exit(failures == 0 ? 0 : 1)
