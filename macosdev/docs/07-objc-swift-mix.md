# 07 · Objective-C 与 Swift 混编

> 示例：`examples/07_objc_swift_mix/`（`Greeter.h/.m`、`ObjcCaller.h/.m`、`SwiftCounter.swift`、`Bridging.h`、`main.swift`）
> 实测输出见 `build/07_objc_swift_mix/stdout.clt.txt`

混编在两个方向上都要走通：

- **Swift → OC**：靠 **bridging header**（桥接头文件）
- **OC → Swift**：靠 **自动生成的 `<Module>-Swift.h`**

Xcode 帮你配好了这两样，命令行要自己拼。本章讲清楚拼法，
以及「加不加 nullability 注解」带来的巨大差别。

## 目录里的文件分工

```
Greeter.h / Greeter.m        纯 OC 类，被 Swift 调用
LegacyNote（在 Greeter.h 里） 故意不加 nullability 注解的反面教材
ObjcCaller.h / ObjcCaller.m  纯 OC 类，调用 Swift
SwiftCounter.swift           被 OC 调用的 Swift 类（@objc final class）
Bridging.h                   Swift → OC 的桥接头
main.swift                   入口，两个方向各演示一遍
Needs-Swift-Header           标记文件：告诉构建脚本本例要生成 Swift 头文件
```

## 方向一：Swift 调用 Objective-C

### 桥接头文件

```objc
// Bridging.h
#import "Greeter.h"
```

编译时给 swiftc 一个参数：

```bash
swiftc -c -import-objc-header Bridging.h ...
```

桥接头里 `#import` 的所有 OC 头文件，对这个 Swift 模块**全部可见**，
不用再 `import`。

> **坑**：同一个 Swift 模块里的所有文件**共享同一个桥接头**。
> 如果多个 Swift 文件都需要不同的 import，全塞进这一个文件里。

### nullability 注解：决定你在 Swift 里看到什么

```objc
NS_ASSUME_NONNULL_BEGIN

@interface Greeter : NSObject
@property (nonatomic, copy) NSString *name;                 // Swift: String
- (NSString *)greet:(NSString *)who;                        // Swift: greet(_ who: String) -> String
@property (nonatomic, readonly) NSArray<NSString *> *names; // Swift: [String]
- (BOOL)loadNamesFrom:(NSString *)text error:(NSError **)error;  // Swift: throws
- (void)forEachName:(void (^)(NSString *name, NSUInteger index))block;  // Swift: 闭包
@end

NS_ASSUME_NONNULL_END
```

`NS_ASSUME_NONNULL_BEGIN/END` 之间，**所有未显式标注的指针默认 `nonnull`**。

| OC 声明 | Swift 里看到 |
| --- | --- |
| `NSString *`（有注解） | `String` |
| `NSString *`（无注解） | `String!`（隐式解包可选） |
| `nullable NSString *` | `String?` |
| `NSArray<NSString *> *` | `[String]` |
| `NSError **` | `throws` |
| block | 闭包 |

**不加注解的后果**（示例里的 `LegacyNote`）：

```objc
@interface LegacyNote : NSObject
- (NSString *)text;      // 什么都没标
@end
```

```swift
let legacy = LegacyNote()
let legacyText: String = legacy.text()   // String! —— 编译器不报错
let safeText: String? = legacy.text()    // 显式声明成可选才安全
```

实测：

```
== nullability 的影响 ==
  legacy = 来自 OC 的老字符串
  ok   没有注解的 API 也能用，但类型是 String!
  ok   显式声明成 String? 就能安全判空
```

`String!` 是**定时炸弹**：编译器放行，运行时一 nil 就崩。
给自己的 OC 头文件**一律加** `NS_ASSUME_NONNULL_BEGIN/END`。

### 方法名的自动改写

OC 的 `- (NSString *)greet:(NSString *)who` 在 Swift 里是
`greet(_ who: String)` —— 第一个参数标签被去掉了（OC 的 selector 风格）。

想控制 Swift 侧的名字，用 `NS_SWIFT_NAME`：

```objc
- (NSString *)greet:(NSString *)who NS_SWIFT_NAME(greet(to:));
```

## 方向二：Objective-C 调用 Swift

### 生成的头文件

```bash
swiftc -c -emit-objc-header-path SwiftBridge-Swift.h ...
```

OC 侧 `#import` 它：

```objc
#import "SwiftBridge-Swift.h"
```

只有**标了 `@objc`**（或继承自 `NSObject`）的 Swift 声明才会出现在里面。

### 能被 OC 看到的 Swift

```swift
@objc final class SwiftCounter: NSObject {
    @objc var count: Int = 0
    @objc func incrementBy(_ delta: Int) { count += delta }
}

@objc enum Theme: Int {
    case light
    case dark
}
```

限制：

- `struct`、泛型、`enum` 带关联值 → **OC 看不到**
- 只有继承自 `NSObject` 的类能被 OC 继承
- `@objc enum` 必须是**整型 raw value**（OC 里变成 `NS_ENUM`）
- Swift 的 `String` / `Array` / `Dictionary` 会自动桥接成 `NSString` / `NSArray` / `NSDictionary`

实测：

```
== Objective-C 调用 Swift ==
  OC 侧拿到的计数 = 7
  ok   OC 里两次 incrementBy 累加成 7（5 + 2）
  OC 侧描述 dark = dark
  ok   Swift 的 @objc enum 在 OC 里是 NS_ENUM
  ok   light 分支也正确
  ok   Swift 侧自增 3
  ok   describe() 正确
```

## 手工混编的完整命令

```bash
SDK=$(xcrun --show-sdk-path)
TARGET=x86_64-apple-macos12.0

# 1) Swift → .o（顺带生成 Swift 头文件供 OC 用）
swiftc -c -sdk "$SDK" -target $TARGET -module-name objc_swift_mix \
       -import-objc-header Bridging.h \
       -emit-objc-header-path build/SwiftBridge-Swift.h \
       SwiftCounter.swift main.swift

# 2) OC → .o（要能找到上一步生成的头文件）
clang -c -fobjc-arc -fmodules -isysroot "$SDK" -target $TARGET \
      -I . -I build Greeter.m ObjcCaller.m -o Greeter.o

# 3) 链接
swiftc SwiftCounter.o main.o Greeter.o ObjcCaller.o -o demo \
       -framework Foundation -framework AppKit
```

> **坑**：`swiftc -c` 多个源文件时，`.o` 写在**当前工作目录**，不是 `-o` 指定的地方。
> 想让产物落在 build/ 里，必须 `cd` 进去再编。
>
> **坑**：模块名决定生成头文件的名字。
> `-module-name objc_swift_mix` → `objc_swift_mix-Swift.h`。名字不对 OC 侧就 import 不到。

## 轻量泛型：让 OC 的集合在 Swift 里带类型

```objc
@property (nonatomic, readonly) NSArray<NSString *> *names;   // Swift: [String]
@property (nonatomic, readonly) NSArray *names;               // Swift: [Any] —— 全是 Any
```

写 OC 头文件时**一定要加轻量泛型**。否则 Swift 侧拿到 `[Any]`，
每个元素都要自己 `as? String`，代码里全是问号。

同样适用于 `NSDictionary<NSString *, NSNumber *>`（Swift: `[String: NSNumber]`）、
`NSSet<NSString *>`。

## 其他常见注解

| 注解 | 作用 |
| --- | --- |
| `NS_ASSUME_NONNULL_BEGIN/END` | 区域内默认 nonnull |
| `nullable` / `nonnull` | 单个声明 |
| `NS_SWIFT_NAME(x)` | 指定 Swift 侧的名字 |
| `NS_SWIFT_UNAVAILABLE("...")` | 对 Swift 隐藏这个 API |
| `NS_DESIGNATED_INITIALIZER` | 指定构造器（影响 Swift 的 `init` 继承） |
| `NS_ENUM` / `NS_OPTIONS` | Swift 里变成 `enum` / `OptionSet` |
| `NS_EXTENSION_UNAVAILABLE` | App 扩展里不可用 |

## 坑清单

| 现象 | 原因 |
| --- | --- |
| Swift 里满屏 `String!` | OC 头文件没加 `NS_ASSUME_NONNULL_*` |
| OC 里 `#import "...-Swift.h"` 找不到文件 | 没加 `-emit-objc-header-path`，或 `-I` 没指到它所在目录 |
| OC 看不到某个 Swift 类 | 没标 `@objc`，或不是 `NSObject` 子类 |
| `@objc enum` 编译不过 | raw value 不是整型（String enum 不行） |
| Swift 拿到 `[Any]` 而不是 `[String]` | OC 头文件没写轻量泛型 |
| main.o 散落在仓库根目录 | `swiftc -c` 把 .o 写在 cwd，没有 cd 进 build 目录 |
| 链接报 duplicate symbol | 同一个 .m 被编进两个 target（或被同时传给 clang 两次） |

## 小结

- Swift → OC 用 bridging header；OC → Swift 用生成的 `<Module>-Swift.h`。
- **nullability 注解是混编体验的分水岭**：加了是 `String`，不加是 `String!`。
- OC 头文件要写轻量泛型，否则 Swift 侧集合全是 `Any`。
- 只有 `@objc` + `NSObject` 子类能暴露给 OC；`@objc enum` 必须整型 raw value。
- 命令行混编要自己给 `-import-objc-header` 和 `-emit-objc-header-path`。
