// ============================================================
// 17 - 打包：.app 的目录结构、Info.plist、资源与本地化目录
//
// 编译：
//   # XIB 先编成 nib
//   ibtool --compile AppWindow.nib AppWindow.xib
//   swiftc -O -sdk $SDK -target x86_64-apple-macos12.0 -module-name packaging \
//          main.swift -o 17_packaging -framework Foundation -framework AppKit
//   ./17_packaging
//
// 一个 .app 其实就是「一个目录 + 一套约定」：
//   MyApp.app/
//     Contents/
//       Info.plist          —— 系统的说明书（bundle id、可执行文件名、图标……）
//       MacOS/MyApp         —— 真正的可执行文件
//       Resources/          —— nib、图片、strings、asset catalog
//       Frameworks/         —— 内嵌的 dylib / framework
// Xcode 的「Archive」做的事就是造这个目录 + 签名 + 公证。本章手工造一遍，
// 好让你知道每一步在做什么 —— 出了问题才有地方下手。
// ============================================================

import AppKit
import Foundation

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

/// XIB 的 File's Owner，只为演示「nib 被放进 app 包之后还能正常加载」
final class PackagingOwner: NSObject {
    @IBOutlet var statusLabel: NSTextField?
}

let fm = FileManager.default

// 放在临时目录里，跑完删掉；路径本身不打印（每次都可能不同）
let appRoot = fm.temporaryDirectory.appendingPathComponent("macosdev-17/MacOSDevDemo.app")
try? fm.removeItem(at: appRoot)

// MARK: - 1) 造目录骨架

print("== 目录骨架 ==")
let contentsDir = appRoot.appendingPathComponent("Contents")
let macosDir = contentsDir.appendingPathComponent("MacOS")
let resourcesDir = contentsDir.appendingPathComponent("Resources")
let frameworksDir = contentsDir.appendingPathComponent("Frameworks")
let executableName = "MacOSDevDemo"

for dir in [macosDir, resourcesDir, frameworksDir] {
    try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
}
expect(fm.fileExists(atPath: macosDir.path), "Contents/MacOS 建好了")
expect(fm.fileExists(atPath: resourcesDir.path), "Contents/Resources 建好了")
expect(fm.fileExists(atPath: frameworksDir.path), "Contents/Frameworks 建好了")

// 可执行文件：真的 app 是 Mach-O，这里放一个可执行权限的文本文件代替。
// CFBundleExecutable 必须和文件名一致，否则双击打不开。
let execURL = macosDir.appendingPathComponent(executableName)
try! "#!/bin/sh\necho hello\n".write(to: execURL, atomically: true, encoding: .utf8)
try! fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: execURL.path)
expect(fm.isExecutableFile(atPath: execURL.path), "可执行文件带上了可执行权限")

// MARK: - 2) Info.plist

print("")
print("== Info.plist ==")
let info: [String: Any] = [
    "CFBundleName": "MacOSDevDemo",
    "CFBundleDisplayName": "macOS 开发示例",
    "CFBundleIdentifier": "dev.macosdev.demo",
    "CFBundleExecutable": executableName,
    "CFBundlePackageType": "APPL",           // APPL = 应用程序包
    "CFBundleSignature": "????",
    "CFBundleShortVersionString": "1.0",      // 对外显示的版本
    "CFBundleVersion": "100",                 // 内部构建号，提交时要递增
    "CFBundleDevelopmentRegion": "en",        // 没有匹配语言时的兜底
    "LSMinimumSystemVersion": "12.0",
    "LSApplicationCategoryType": "public.app-category.developer-tools",
    "NSHighResolutionCapable": true,          // 不勾这个，Retina 上会模糊
    "NSSupportsAutomaticTermination": true,   // 允许系统在无人使用时静默退出
    "NSSupportsSuddenTermination": false,
    "LSUIElement": false,                     // true = 不在 Dock 显示（菜单栏 app）
]
let infoData = try! PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
try! infoData.write(to: contentsDir.appendingPathComponent("Info.plist"))

// MARK: - 3) 资源：把编译好的 nib 放进去

print("")
print("== 资源 ==")
// 运行时的工作目录里已经有 ibtool 编好的 AppWindow.nib（脚本编的）
let builtNib = URL(fileURLWithPath: "AppWindow.nib")
expect(fm.fileExists(atPath: builtNib.path), "当前目录里有编好的 nib")
try! fm.copyItem(at: builtNib, to: resourcesDir.appendingPathComponent("AppWindow.nib"))
expect(fm.fileExists(atPath: resourcesDir.appendingPathComponent("AppWindow.nib").path),
       "nib 已经放进 Resources")

// 图片资源：asset catalog 编译后是 Assets.car，手写包就用普通文件
try! "placeholder".write(to: resourcesDir.appendingPathComponent("note.txt"),
                         atomically: true, encoding: .utf8)

// MARK: - 4) 本地化目录

print("")
print("== 本地化 ==")
// .lproj 目录：每种语言一个，里面放同名文件，系统按用户语言挑一个
let enDir = resourcesDir.appendingPathComponent("en.lproj", isDirectory: true)
try! fm.createDirectory(at: enDir, withIntermediateDirectories: true)
let strings: [String: String] = ["greeting": "Hello", "quit": "Quit"]
let stringsData = try! PropertyListSerialization.data(fromPropertyList: strings,
                                                      format: .xml, options: 0)
try! stringsData.write(to: enDir.appendingPathComponent("Localizable.strings"))

// MARK: - 5) 拿到 Bundle 对象
//
// 坑：CFBundle 会**缓存**包目录的内容清单，而且是按路径共享的。
// 也就是说「先建 Bundle、再往 Resources 里塞文件」的话，后面新加的资源
// 可能查不到（同一个路径拿到的还是那个带旧清单的实例）。
// 所以这里把目录彻底铺完之后才第一次碰 Bundle。

print("")
print("== 读这个包 ==")
let bundle = Bundle(url: appRoot)!
expect(bundle.bundleIdentifier == "dev.macosdev.demo", "读得到 bundle identifier")
expect(bundle.object(forInfoDictionaryKey: "CFBundleName") as? String == "MacOSDevDemo",
       "读得到 CFBundleName")
expect(bundle.object(forInfoDictionaryKey: "NSHighResolutionCapable") as? Bool == true,
       "布尔型 Info.plist 项也能读")
expect(bundle.executableURL?.lastPathComponent == executableName,
       "系统按 CFBundleExecutable 找到可执行文件")
expect(bundle.infoDictionary?["CFBundlePackageType"] as? String == "APPL", "包类型是 APPL")

// 坑：读 Info.plist 一律用 object(forInfoDictionaryKey:) 而不是直接翻
// infoDictionary —— 前者会做本地化变量替换（比如 ${PRODUCT_NAME}）。

expect(bundle.url(forResource: "AppWindow", withExtension: "nib") != nil,
       "Bundle 能定位到 nib 资源")
expect(bundle.url(forResource: "NoSuchThing", withExtension: "nib") == nil,
       "不存在的资源返回 nil")
expect(bundle.path(forResource: "note", ofType: "txt") != nil, "普通文件也能当资源读")
expect(bundle.localizations.contains("en"),
       "Bundle 认出了 en 这一种本地化（实际 \(bundle.localizations)）")

// strings 文件就是一个 plist，可以直接解析
let stringsURL = enDir.appendingPathComponent("Localizable.strings")
let parsedStrings = try! PropertyListSerialization.propertyList(
    from: Data(contentsOf: stringsURL), options: [], format: nil) as? [String: String]
expect(parsedStrings?["greeting"] == "Hello", "strings 文件本质上就是 plist")

// 坑：别在自测里依赖 localizedString(forKey:) 的返回值 ——
// 它取决于系统当前语言顺序，换台机器结果就不一样。
let localized = bundle.localizedString(forKey: "greeting", value: "fallback", table: nil)
print("  localizedString(\"greeting\") = \(localized)")
expect(localized.isEmpty == false, "至少能拿到一个非空字符串")

// MARK: - 6) 从打好的包里加载 nib

print("")
print("== 从包里加载 nib ==")
let owner = PackagingOwner()
var topLevel: NSArray? = nil
let ok = bundle.loadNibNamed("AppWindow", owner: owner, topLevelObjects: &topLevel)
print("  loaded = \(ok), 顶层对象数 = \(topLevel?.count ?? -1)")
expect(ok, "打进 .app 之后 nib 照样能加载")
expect(owner.statusLabel?.stringValue == "打包进 .app 的视图", "outlet 也照样连上了")
let rootView = (topLevel ?? []).compactMap { $0 as? NSView }.first
expect(rootView?.frame.width == 240, "视图尺寸来自 XIB（实际 \(rootView?.frame.width ?? -1)）")
expect(rootView?.subviews.count == 1, "XIB 里的子视图数量也对得上")

// MARK: - 7) 签名与公证（只讲概念，本章不真的签）

print("")
print("== 签名 ==")
// 真实流程是：codesign --sign "Developer ID Application: ..." --options runtime MyApp.app
// 再用 ditto 打 zip → xcrun notarytool submit → xcrun stapler staple
// 自测里不跑这些（要证书、要联网、要几分钟），只把「该检查什么」列出来：
let checklist = [
    "Info.plist 的 CFBundleExecutable 与 MacOS/ 下的文件名一致",
    "所有内嵌的 framework / dylib 都签了名（--deep 或逐个签）",
    "开了 Hardened Runtime（--options runtime）",
    "有 entitlements 文件声明需要的权限（沙箱、网络、麦克风……）",
]
for item in checklist { print("  - \(item)") }
expect(checklist.count == 4, "四条检查项")
// 沙箱相关的 key 也是 Info.plist 的一部分
expect(info["CFBundleIdentifier"] as? String == "dev.macosdev.demo",
       "bundle id 是签名的身份基础")

// 收尾
try? fm.removeItem(at: appRoot)
expect(fm.fileExists(atPath: appRoot.path) == false, "临时 .app 已删除")

print("==== 17 结束 ====")
exit(failures == 0 ? 0 : 1)
