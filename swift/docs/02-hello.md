# 02 · 第一个程序

> 对应示例：`examples/02_hello/`

## 2.1 三种运行形态：REPL、脚本、编译

Swift 的入门体验比 C 系语言友好得多——同一个文件，三种玩法：

```bash
# ① REPL：交互式解释器，敲一行算一行
swift repl
1> let greeting = "你好"
greeting: String = "你好"

# ② 脚本模式：直接"运行"源文件（内部编译后执行，首跑稍慢）
swift examples/02_hello/Sources/02_hello/main.swift

# ③ 编译模式：先出可执行文件再运行（SPM 工程的标准路径）
swift run Ch02Hello
```

本教程统一走第 ③ 种：每个示例是 SPM 根包里的一个可执行目标（见 2.5），改完代码
`swift run Ch02Hello` 立即看效果——这就是"每章标准学法"。

> ⚠️ Windows 实测：REPL 在 scoop 布局 + junction 下有已知问题（scoop 官方 issue #6159），
> 想玩 REPL 请用真实版本路径启动。教程不依赖 REPL。

## 2.2 print 与字符串插值

```swift
func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

print("你好，Swift！")
print("add(2, 3) = \(add(2, 3))，即插值里可以调用函数")
```

- `print(_:)` 输出到 **stdout**，自带换行；`print(x, terminator: "")` 可去掉换行，
  `print(a, b, separator: "、")` 控制分隔符。
- 插值语法 `\(表达式)`——括号里可以放任意表达式（函数调用、可选解包、三元都行）。
  对比 C 的 `printf("%d", x)`：Swift 按类型**静态分派** `description`，没有格式串与
  实参对不上这种事故；要控制浮点精度再回 `String(format:)`（Foundation，03 章示例
  `hexByte` 用过）。
- 不需要 `import` 就能 `print`：print 属于 Swift 核心库（隐式可见）。`import Foundation`
  是为了用后面的高级 API（URL/FileManager 等），纯语言示例可以不 import。

## 2.3 多行字符串字面量

```swift
func farewell(_ name: String) -> String {
    """
    再见，\(name)。
    欢迎回来。
    """
}
```

三个双引号包裹，**换行与缩进原样保留**，但结尾 `"""` 的缩进会作为基准从每行裁掉——
想让字符串内容顶格、代码里又想缩进对齐，把结尾引号写在哪一行，缩进基准就在哪。
多行字符串里插值照常工作，双引号无需转义。

## 2.4 顶层代码与 main.swift 的特殊性

示例文件叫 `main.swift` 不是随意的：**只有名为 main.swift 的文件允许写顶层语句**
（如 `print(...)`、`let counter = 0`），其他文件只能有声明。编译器把 main.swift 的
顶层语句当作程序入口——传统 C 的 `main` 函数被"顶层代码"取代了。

```swift
// main.swift 里可以：
let goldenRatio = 1.618        // 顶层常量
print(" ratio = \(goldenRatio)")  // 顶层语句

// 非 main.swift 的源文件里，上面第二行直接编译错误：
// error: expressions are not allowed at the top level
```

配套惯例（本教程全程遵守）：

- **能测的逻辑写成函数**（如 `add`/`greet`），顶层只做"组装 + 打印"——因为 Tests
  目录会 `@testable import` 本模块，顶层语句没法被测试引用。
- 注释两种：`//` 单行、`/* ... */` 块注释（可嵌套，这点与 C 不同）；文档注释 `///`
  生成 API 文档（23 章讲 docc）。
- `precondition(条件, "消息")`：条件不成立立即终止程序——教学代码用它做"输出即断言"，
  比 print 完再人眼检查可靠得多（本教程每章示例的关键路径都有）。

## 2.5 本教程的工程结构：一个根包，22 个可执行目标

打开 `swift/Package.swift` 看：

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-guide",
    targets: [
        .executableTarget(
            name: "Ch02Hello",                        // 目标名必须合法标识符
            path: "examples/02_hello/Sources/02_hello"),  // 但目录可以数字开头
        .testTarget(
            name: "Ch02HelloTests",
            dependencies: ["Ch02Hello"],
            path: "examples/02_hello/Tests/02_helloTests"),
        // …每章一组，到第 23 章
    ]
)
```

三个设计决策，后面 22 章都吃这碗饭：

1. **目标名 `Ch02Hello` 而非 `02_hello`**：SPM 目标名会成为模块名，模块名必须是
   合法标识符（不能数字开头）。目录保持 `02_hello`（章号 = 目录号的排序约定），
   用 `path:` 参数映射过去。
2. **测试与示例同目录**：`examples/NN_name/Tests/` 里是 swift-testing 测试（21 章专讲），
   `@testable import Ch02Hello` 能引用 main.swift 里定义的函数——"示例即被测代码"。
3. **单根包**：22 个目标共享一份 `.build/` 增量缓存，`swift build --target Ch03Basics`
   只编自己，`swift test --filter Ch03BasicsTests` 只跑本章测试——验证快。

`swift run Ch02Hello` 做了三件事：增量编译 → 链接 → 设置好运行环境后执行。最后一步
在 Windows 上有讲究——

## 2.6 Windows 运行时 DLL：为什么"裸跑 exe"会崩

用 `swiftc main.swift -o hello.exe` 直接编译的产物，双击或裸跑会报：

```text
hello.exe: error while loading shared libraries: swiftCore.dll: cannot open shared object file
```

Swift 在 Windows 上默认**动态链接**运行时（swiftCore.dll、Foundation.dll 等），它们住在
`<安装根>\Runtimes\usr\bin`，这个目录默认不在 PATH。`swift run` 会自动配好；脱离 SPM
运行产物要么把该目录加进 PATH，要么用 `-static-stdlib` 静态链接（23 章实操）。

> 教训来自本教程的实测：scoop 的 6.4.0 包**整个 Runtimes 目录缺失**，任何动态产物
> 一跑就 0xC0000135（STATUS_DLL_NOT_FOUND）——所以教程钉死 6.3.3。详见 01 章与
> build.ps1 顶部注释。

## 2.7 坑位清单

1. **顶层语句只能写在 main.swift**——别的文件里写 `print` 直接编译错误；想复用逻辑，
   写成函数放进任何文件都行（main.swift 里的函数同样可被测试导入）。
2. **`swift test --filter` 会构建整个包的全部测试目标**——任何一个示例的测试编译不过，
   其他示例的 `--filter` 也跑不了。修错时看报错文件名定位到具体章。
3. **swift-format 无配置时默认 2 空格缩进**（Apple 官方风格反而是 4 空格）——本仓库
   `.swift-format` 已显式配 4 空格；自己建工程时记得带上，否则 lint 全军覆没。
4. **`swift format format --in-place` 是自动修复版**（类似 `zig fmt`）：lint 报的
   Spacing/AddLines 类问题都能一键修，改完代码先 format 再 lint 是标准节奏。
5. **Windows 控制台中文乱码**：跑前 `chcp 65001`（build.ps1 已代设）；Git Bash 天然
   UTF-8 无此问题。
6. **源码文件用 UTF-8 无 BOM**：带 BOM 的 .swift 文件编译器可能把首个声明啃掉一截
   （全仓库纪律，Visual Studio 建的文件尤其注意）。

上一章：[01 · 全景](01-overview.md) ｜ 下一章：[03 · 基础类型](03-basics.md) ｜ 返回：[README](../README.md)
