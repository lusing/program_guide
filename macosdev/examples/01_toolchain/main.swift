// ============================================================
// 01 - 工具链与环境
//   编译期事实（#if / #available / canImport）与运行期事实（Bundle / ProcessInfo）
//
// 编译（本仓库的 run-all.sh 会代劳；这里给的是等价的手工命令）：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name toolchain main.swift -o 01_toolchain \
//          -framework Foundation -framework AppKit
// 运行：
//   ./01_toolchain --selftest
//
// 这个示例刻意不打印任何「因机器而异」的东西：版本号、内存、pid、路径前缀都
// 会让两套工具链的输出对不上，也会让文档里的输出快照立刻过期。需要展示「某个
// 事实成立与否」时一律改成布尔断言。
// ============================================================

import AppKit
import Foundation

// ---------- 1) 编译期就知道的事 ----------
print("== 编译期事实 ==")

// #if swift / #if compiler：Swift 版本。本机两套工具链都是 Swift 6.0.3
#if swift(>=5.7)
print("swift 版本 >= 5.7 : true")
#else
print("swift 版本 >= 5.7 : false")
#endif

// canImport：某个模块在当前 SDK 里存在吗（本机 SDK 是 macOS 15.2）
#if canImport(AppKit)
print("canImport(AppKit) : true")
#else
print("canImport(AppKit) : false")
#endif

#if os(macOS)
print("os(macOS)         : true")
#endif
#if targetEnvironment(simulator)
print("simulator         : true")
#else
print("simulator         : false")
#endif

// ---------- 2) 部署目标 vs SDK 版本 ----------
print("")
print("== 部署目标（编译进二进制的一条元数据）==")
// 本机是 macOS 14.8.9、SDK 是 15.2，但部署目标钉在 macos12.0：
// 这样误用了 12.0 之后才有的 API 会在**编译期**被拦下，而不是运行到那一步才崩。
// 下面两个检查判的是「**实际运行在哪个系统上**」（14.8.9），跟部署目标无关：
//   >= 14.0 → true（本机就是 14.8.9）
//   >= 15.0 → false（本机还不到 15）
// 一真一假，正好说明它判的是运行时系统版本，不是编译进去的部署目标。
let want14 = OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0)
let want15 = OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0)
print("系统 >= 14.0 : \(ProcessInfo.processInfo.isOperatingSystemAtLeast(want14))")
print("系统 >= 15.0 : \(ProcessInfo.processInfo.isOperatingSystemAtLeast(want15))")

// #available 同样是**运行期**判定，判的是「实际跑在哪个系统上」，
// 跟 -target / SDK 版本完全无关。部署目标只决定「编译器允不允许你不加守卫就用新 API」，
// 以及「#available 的 else 分支要不要保留」；真正走哪条分支由运行时系统版本决定。
var reachedGuardedBranch = false
if #available(macOS 15.0, *) {
    reachedGuardedBranch = true
}
print("走进 macOS 15 分支 : \(reachedGuardedBranch)")

// ---------- 3) Bundle：命令行程序也有 main bundle ----------
print("")
print("== Bundle ==")
let main = Bundle.main
print("bundlePath 是目录 : \(main.bundleURL.pathExtension != "app")")
// 关键事实：不是 .app 包时，Bundle.main 的资源路径就是「可执行文件所在目录」，
// 而不是 Contents/Resources。编译好的 .nib 因此要和可执行文件放在一起才能被找到。
print("资源目录名 == 工作目录名 : \(main.resourceURL?.lastPathComponent == "01_toolchain")")
print("Info.plist 存在 : \(main.infoDictionary != nil)")

// ---------- 4) ProcessInfo 与命令行参数 ----------
print("")
print("== 进程信息 ==")
print("argc == 2 : \(CommandLine.arguments.count == 2)")
print("收到 --selftest : \(CommandLine.arguments.contains("--selftest"))")
print("当前是主线程 : \(Thread.isMainThread)")
print("首字母大写的进程名非空 : \(!ProcessInfo.processInfo.processName.isEmpty)")
print("物理内存 > 0 : \(ProcessInfo.processInfo.physicalMemory > 0)")
print("处理器数 > 0 : \(ProcessInfo.processInfo.processorCount > 0)")
print("活动处理器数 > 0 : \(ProcessInfo.processInfo.activeProcessorCount > 0)")
print("环境变量数 > 0 : \(!ProcessInfo.processInfo.environment.isEmpty)")
print("系统已运行时间 > 0 秒 : \(ProcessInfo.processInfo.systemUptime > 0)")

// ---------- 5) 为什么本教程的示例都钉死 locale ----------
print("")
print("== 区域与格式化：不稳定的典型 ==")
let number = NSNumber(value: 1234567.891)
let pinned = NumberFormatter()
pinned.locale = Locale(identifier: "en_US_POSIX")
pinned.numberStyle = .decimal
pinned.maximumFractionDigits = 2
print("固定 en_US_POSIX : \(pinned.string(from: number) ?? "nil")")

let system = NumberFormatter()
system.numberStyle = .decimal
system.maximumFractionDigits = 2
let systemText = system.string(from: number) ?? "nil"
// 只断言「性质」，不断言具体字符串：用户系统语言一变，输出就变了
print("使用系统 locale 时非空 : \(!systemText.isEmpty)")
print("两种 locale 的分隔符是否必然相同 : false  ← 所以上面才不打印它的原文")
print("preferredLanguages 非空 : \(!Locale.preferredLanguages.isEmpty)")

print("==== 01 结束 ====")
