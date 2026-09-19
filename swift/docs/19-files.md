# 19 · 文件与 IO

> 对应示例：`examples/19_files/`

## 19.1 Foundation：Swift 的"电池"

纯 Swift 标准库只有语言核心（集合、字符串、Optional……）；**文件、网络、日期、JSON
全部住在 Foundation**。Windows/Linux 上 Foundation 是 swift-toolchain 自带的跨平台
实现（*Essentials/Internationalization/Networking 分层），不再依赖 Apple 专有框架——
`import Foundation` 即可用。本章用到的家族：

| 类别 | API | 备注 |
|---|---|---|
| 路径 | `URL`、`FileManager` | URL 是路径的强类型形态 |
| 文本 | `String.write/contentsOf` | UTF-8 直达 |
| 字节 | `Data` | 字节袋，读写二进制 |
| 目录 | `FileManager.createDirectory/contentsOfDirectory/removeItem` | 递归建/遍/删 |

## 19.2 URL：不是字符串，是"解析好的路径"

```swift
let scratch = FileManager.default.temporaryDirectory
    .appendingPathComponent("swift-guide-19", isDirectory: true)
let file = scratch.appendingPathComponent("笔记.txt")

file.lastPathComponent   // "笔记.txt"
file.pathExtension        // "txt"
file.isFileURL            // true
```

`URL` 记住了 scheme/host/路径的分解，`appendingPathComponent` 处理拼接与分隔符——
**手拼字符串路径是错误的开端**（见 19.5 的 Windows 坑）。`URL(fileURLWithPath:)`
造文件 URL；`URL(string:)` 造网络 URL（可选，因为可能非法）。

## 19.3 文本与二进制读写

```swift
try text.write(to: file, atomically: true, encoding: .utf8)   // 原子写：先写临时文件再改名
let loaded = try String(contentsOf: file, encoding: .utf8)

try Data(bytes).write(to: binFile)        // 二进制写
let data = try Data(contentsOf: binFile)  // 二进制读
```

- `atomically: true`：防"写到一半崩溃留半个文件"——重要数据一律原子写。
- `Data` 是字节序列：`Data("Hello".utf8)`、`data.count`、`String(data:encoding:)`
  互转；大文件用 `URL.appendingPathComponent` + `Data(contentsOf:options:)` 的
  分块 API（进阶）。
- 这些调用都 **throws**——磁盘满、权限、路径不存在是业务错误（12 章分层）。

## 19.4 目录：创建、遍历、清理

```swift
try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)  // 递归建

let urls = try FileManager.default.contentsOfDirectory(at: scratch, includingPropertiesForKeys: nil)

try FileManager.default.removeItem(at: scratch)   // 递归删（目录整个移除）
```

- `withIntermediateDirectories: true` = `mkdir -p`（父目录不存在就一路建）。
- `contentsOfDirectory` **不递归**（一层）；要深层遍历用
  `enumerator(at:)`（24 章实战用它递归搜文件）。
- 遍历结果**顺序不保证**——排序后再打印/断言（示例 `listFiles` 的 `.sorted()`）。
- **教学纪律**：示例在临时目录做实验、结束 `removeItem` 清场——不留垃圾是 IO 示例
  的基本教养（也是 CI 可重复的前提）。

## 19.5 Windows 路径坑（实测）

```swift
let manual = ["C:", "Users", "文档"].joined(separator: "/")   // "C:/Users/文档"
// 在 Windows 上这不是合法路径（应为反斜杠），而且 C: 后的 / 语义还会被当相对路径

URL(fileURLWithPath: "C:\\Users").appendingPathComponent("文档").path
// "C:\Users\文档" —— 分隔符、盘符、前导 \\ 全部正确
```

三条纪律：

1. **路径拼接永远走 URL**（`appendingPathComponent` 自动用平台分隔符）；
2. **展示给用户**用 `url.path`（原生分隔符）；**跨平台存储**考虑标准化；
3. `FileManager.default.temporaryDirectory` 给系统临时目录——Windows 上是
   `%TEMP%`，示例的 scratch 目录模式可复制。

## 19.6 大文件与流式处理一瞥

`String(contentsOf:)` 把整个文件读进内存——配置、小文本没问题；日志分析、大 JSON
要流式（`FileHandle` 分块读、`AsyncSequence` 逐行、24 章实战的逐文件处理）。原则：
**先写对的简单版，数据量上来了再换流式**。

## 19.7 坑位清单（含实测）

1. **手拼路径在 Windows 必翻车**（实测）：`joined(separator: "/")` 不处理盘符与
   反斜杠——`appendingPathComponent` 是唯一正解。
2. **`contentsOfDirectory` 无序**：断言/输出前 `.sorted()`（13 章字典遍历同款纪律）。
3. **`split(omittingEmptySubsequences: false)` 对空串返回 `[""]`**（实测反直觉）：
   `countLines("") == 1`——行计数语义自己定义清楚。
4. **`try? createDirectory` 静默吞错**：scratch 目录模式里"已存在"是预期所以 try?
   无妨；但严肃代码用 do-catch 区分"已存在"与"权限拒绝"。
5. **URL 的 `path` 与 `absoluteString` 不同**：`path` 是文件系统路径（无 `file://`），
   `absoluteString` 带 scheme——打印路径用前者。
6. **中文文件名在 Windows 完全可用**（示例全程中文文件名实测），但控制台显示要
   UTF-8（chcp 65001，脚本已代设）。

上一章：[18 · 并发 II](18-actors.md) ｜ 下一章：[20 · Codable](20-codable.md) ｜ 返回：[README](../README.md)
