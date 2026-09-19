// 23 · 工具链与互操作——C 互操作（WinSDK/ucrt）、格式化/静态分发、钉版心法

import Foundation
import WinSDK  // Windows SDK 的 Swift 覆盖层：全套 Win32 API（链接自动配好）
import ucrt  // C 运行时：sqrt/printf 家族

// ═══ 23.1 纯函数区（供测试）
func cSqrt(_ value: Double) -> Double {
    sqrt(value)  // ucrt 的 C 函数，直接当 Swift 函数用
}

func fixedPointFromC() -> (x: Double, y: Double) {
    (cSqrt(2), cSqrt(3))  // 确定性：数学常数不随运行变化
}

/// Win32 API：取系统目录（缓冲区往返的完整仪式）
func systemDirectory() -> String {
    var buffer = [WCHAR](repeating: 0, count: 260)  // MAX_PATH 的 WCHAR（UTF-16）数组
    let length = GetSystemDirectoryW(&buffer, 260)
    guard length > 0 else { return "?" }
    return String(decoding: buffer.prefix(Int(length)), as: UTF16.self)  // 有效长度内解码
}

/// C 定宽类型在 Swift 里的映射
func cTypeSizes() -> [String: Int] {
    [
        "CChar(Int8)": MemoryLayout<CChar>.size,
        "CInt(Int32)": MemoryLayout<CInt>.size,
        "CLongLong(Int64)": MemoryLayout<CLongLong>.size,
        "CFloat(Float32)": MemoryLayout<CFloat>.size,
        "WCHAR(UTF16)": MemoryLayout<WCHAR>.size,
    ]
}

// ═══ 23.2 ucrt：C 标准库直通
precondition(cSqrt(4) == 2)
precondition(abs(cSqrt(2) - 1.4142135623730951) < 1e-15)
print("① ucrt：sqrt(2) = \(cSqrt(2))，sqrt(4) = \(cSqrt(4))")

// ═══ 23.3 WinSDK：Win32 API 直通
let pid = GetCurrentProcessId()
print("② WinSDK：GetCurrentProcessId() = \(pid)（每次运行不同，只演示不断言）")
print("   系统目录：\(systemDirectory())")
precondition(systemDirectory().count > 1)

// ═══ 23.4 C 类型映射表
let sizes = cTypeSizes()
print(
    "③ C 类型映射：\(sizes.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)B" }.joined(separator: " "))"
)
precondition(sizes["CInt(Int32)"] == 4 && sizes["WCHAR(UTF16)"] == 2)

// ═══ 23.5 swift-format 与源码工具（本章正文详述命令行用法）
// 本仓库验证链第一层就是：swift format lint --configuration .swift-format --strict --recursive <dir>
// 自动修复：swift format format --configuration .swift-format --recursive --in-place <dir>
print("④ 格式化工具的用法见 docs/23-tooling.md 与 build.ps1 第 [1/4] 层")

// ═══ 23.6 静态链接分发（正文详述；此处打印链接形态说明）
print("⑤ 本示例动态链接运行时（swift run 自动配 PATH）；独立分发用 swiftc -static-stdlib")

print("==== 23 结束 ====")
